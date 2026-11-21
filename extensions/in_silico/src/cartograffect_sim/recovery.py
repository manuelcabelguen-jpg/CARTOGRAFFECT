"""Pipelines d'inférence bayésienne sous NumPyro & ArviZ (Parameter & Model Recovery).

Implémente en boucle fermée réelle sur ``NonStationaryBanditEnv`` (sans fuite de
variables environnementales latentes ``is_remission`` ou ``d_obj`` dans la
vraisemblance ni lors de la génération des réponses) :
    1. Quatre modèles génératifs et d'inférence candidats :
       - ``M1_CARTOGRAFFECT`` : modèle complet à 8 paramètres libres
         (τ_A, τ_C, λ, α_0, γ_α, η_diss, β_X, β_Y) ;
       - ``M2_NoBudget_Lam0`` : sans contrainte budgétaire L1 (λ ≡ 0, 7 params) ;
       - ``M3_NoThresholds`` : continu sans seuils de neutralité (τ_A = τ_C ≡ 0, 6 params) ;
       - ``M4_ScalarValence_1D`` : valence scalaire 1D avec seuil et bruit libres
         (α_v, τ_v, η_diss, β_scalar, σ_v, 5 params).
    2. Inversion par SVI vectorisée (``jax.vmap`` + ``AutoMultivariateNormal``) et
       MCMC NUTS vectorisé (``ArviZ`` R-hat / ESS) sous reparamétrisation centrée
       (``log_alpha_mid`` à ``z_ref = 3.0`` et ``beta_X = beta_Y + delta_beta``).
    3. Sélection bayésienne de modèles à effets aléatoires (``pxp`` via ``-0.5 * BIC``
       et ``-0.5 * WAIC`` ; Rigoux et al., 2014).
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Any

import arviz as az
import jax
import jax.numpy as jnp
import numpy as np
import numpyro
import numpyro.distributions as dist
from numpyro.infer import MCMC, NUTS, Predictive, SVI, Trace_ELBO
from numpyro.infer.autoguide import AutoMultivariateNormal
from scipy.special import gammaln, psi

from .core_affect import apply_budget_constraint
from .generative_process import (
    BanditAction,
    BlockSpec,
    NonStationaryBanditEnv,
    OutcomeValence,
)

MODEL_NAMES: tuple[str, ...] = (
    "M1_CARTOGRAFFECT",
    "M2_NoBudget_Lam0",
    "M3_NoThresholds",
    "M4_ScalarValence_1D",
)

THETA_NAMES: tuple[str, ...] = (
    "tau_A",
    "tau_C",
    "lambda",
    "alpha_0",
    "gamma_alpha",
    "eta_diss",
    "beta_X",
    "beta_Y",
)

MODEL_PARAM_COUNTS: dict[str, int] = {
    "M1_CARTOGRAFFECT": 8,
    "M2_NoBudget_Lam0": 7,
    "M3_NoThresholds": 6,
    "M4_ScalarValence_1D": 5,
}


def compute_sensory_calm_sequence(
    actions: np.ndarray,
    outcomes: np.ndarray,
) -> np.ndarray:
    """Détecte les pas calmes uniquement depuis les séquences observables ``(action, outcome)``.

    Exige deux issues neutres consécutives hors-``PROBE_CUE`` afin d'éviter les
    faux déclenchements lors des neutres isolés de ``d_obj in {3, 4}``. Aucune
    lecture de ``is_remission`` ni de ``d_obj``.
    """
    t_len = len(actions)
    obs_calm = np.zeros(t_len, dtype=np.float32)
    neutral_streak = 0
    for t in range(t_len):
        act_t = int(actions[t])
        out_t = int(outcomes[t])
        if out_t != int(OutcomeValence.NEUTRAL):
            neutral_streak = 0
            obs_calm[t] = 0.0
        else:
            if act_t != int(BanditAction.PROBE_CUE):
                neutral_streak += 1
            obs_calm[t] = 1.0 if neutral_streak >= 2 else 0.0
    return obs_calm


@dataclass(frozen=True)
class RecoveryDataset:
    """Jeu de données synthétique observable d'un participant (sans fuite de labels cachés)."""

    cues: np.ndarray          # int32 (T,) in {0, 1, 2}
    actions: np.ndarray       # int32 (T,) in {0, 1, 2}
    outcomes: np.ndarray      # int32 (T,) in {0=neutre, 1=pos, 2=neg}
    seq_err: np.ndarray       # float32 (T,) in [0, 1]
    eval_bad: np.ndarray      # float32 (T,) in [0, 1]
    obs_calm: np.ndarray      # float32 (T,) in {0.0, 1.0} (purement sensoriel)
    filter_a: np.ndarray      # float32 (T,) in {0.0, 1.0}
    filter_c: np.ndarray      # float32 (T,) in {0.0, 1.0}
    ema_x: np.ndarray         # float32 (T,) (observé si filter_a == 1)
    ema_y: np.ndarray         # float32 (T,) (observé si filter_c == 1)
    z_level: np.ndarray       # float32 (T,) (trace diagnostique interne de simulation)

    @property
    def num_active_scalar_obs(self) -> int:
        """Nombre exact d'observations scalaires actives (choix + 2 filtres + sondes actives)."""
        t_len = int(len(self.cues))
        return t_len + 2 * t_len + int(np.sum(self.filter_a > 0.5)) + int(np.sum(self.filter_c > 0.5))

    def to_jax_dict(self) -> dict[str, jax.Array]:
        return {
            "cues": jnp.asarray(self.cues, dtype=jnp.int32),
            "actions": jnp.asarray(self.actions, dtype=jnp.int32),
            "outcomes": jnp.asarray(self.outcomes, dtype=jnp.int32),
            "seq_err": jnp.asarray(self.seq_err, dtype=jnp.float32),
            "eval_bad": jnp.asarray(self.eval_bad, dtype=jnp.float32),
            "obs_calm": jnp.asarray(self.obs_calm, dtype=jnp.float32),
            "filter_a": jnp.asarray(self.filter_a, dtype=jnp.float32),
            "filter_c": jnp.asarray(self.filter_c, dtype=jnp.float32),
            "ema_x": jnp.asarray(self.ema_x, dtype=jnp.float32),
            "ema_y": jnp.asarray(self.ema_y, dtype=jnp.float32),
        }


def build_recovery_schedule(num_trials: int = 280) -> tuple[BlockSpec, ...]:
    """Protocole expérimental orthogonal identifiant séparément les 8 paramètres de θ."""
    specs = [
        ("r_high_ctrl_low_vol_d2", 0.88, 0.05, 0.90, 2, False, 30),
        ("r_low_ctrl_low_vol_d2", 0.12, 0.06, 0.88, 2, False, 34),
        ("r_remission_1", 0.55, 0.05, 0.90, 2, True, 16),
        ("r_high_ctrl_high_vol_d2", 0.85, 0.45, 0.22, 2, False, 36),
        ("r_dual_stress_d3", 0.12, 0.45, 0.20, 3, False, 38),
        ("r_remission_2", 0.55, 0.05, 0.90, 2, True, 16),
        ("r_dual_stress_deep_d4", 0.14, 0.42, 0.24, 4, False, 40),
        ("r_deep_reversal_d4", 0.88, 0.10, 0.88, 4, False, 34),
        ("r_remission_3", 0.60, 0.05, 0.92, 2, True, 18),
        ("r_recovery_probe_d3", 0.80, 0.35, 0.30, 3, False, 18),
    ]
    base_total = sum(s[6] for s in specs)
    raw_counts = [max(4, round(num_trials * s[6] / base_total)) for s in specs]
    diff = num_trials - sum(raw_counts)
    idx_adj = 0
    while diff != 0:
        step = 1 if diff > 0 else -1
        if raw_counts[idx_adj % len(raw_counts)] + step >= 4:
            raw_counts[idx_adj % len(raw_counts)] += step
            diff -= step
        idx_adj += 1

    blocks: list[BlockSpec] = []
    for idx, ((name, pc, vr, cc, dobj, is_rem, _), n_tr) in enumerate(zip(specs, raw_counts)):
        blocks.append(
            BlockSpec(
                block_id=idx,
                name=name,
                num_trials=int(n_tr),
                p_ctrl=pc,
                v_rule=vr,
                cue_clarity=cc,
                d_obj=dobj,
                is_remission=is_rem,
            )
        )
    return tuple(blocks)


def sample_true_parameters(
    num_samples: int,
    seed: int = 42,
) -> list[dict[str, float]]:
    """Tire ``num_samples`` vecteurs ``θ_vrai`` théoriquement admissibles et découplés."""
    rng = np.random.default_rng(seed)
    out: list[dict[str, float]] = []
    for _ in range(num_samples):
        tau_a = float(rng.uniform(0.12, 0.52))
        tau_c = float(rng.uniform(0.12, 0.52))
        lam = float(rng.uniform(0.12, 0.95))
        alpha_0 = float(rng.uniform(0.35, 2.20))
        gamma_alpha = float(rng.uniform(0.12, 0.72))
        eta_diss = float(rng.uniform(0.10, 0.58))
        beta_y = float(rng.uniform(0.45, 1.55))
        delta_beta = float(rng.uniform(0.70, 2.80))
        beta_x = float(beta_y + delta_beta)
        out.append(
            {
                "tau_A": tau_a,
                "tau_C": tau_c,
                "lambda": lam,
                "alpha_0": alpha_0,
                "gamma_alpha": gamma_alpha,
                "eta_diss": eta_diss,
                "beta_X": beta_x,
                "beta_Y": beta_y,
            }
        )
    return out


def _compute_choice_values_jax(
    q_rule_pre: jax.Array,
    q_ctrl_high: jax.Array,
    cue_t: jax.Array,
) -> tuple[jax.Array, jax.Array]:
    """Calcule ``(V_epistemic, V_pragmatic)`` pour les 3 actions ``[A, B, PROBE]``."""
    p_r = jnp.clip(q_rule_pre, 1e-6, 1.0 - 1e-6)
    h_rule = -(p_r * jnp.log(p_r) + (1.0 - p_r) * jnp.log(1.0 - p_r)) / math.log(2.0)
    is_ambig = (cue_t == 2).astype(jnp.float32)
    ep_probe = 0.85 * h_rule + 0.35 * is_ambig
    ep_arm = 0.12 * h_rule * q_ctrl_high
    ep_vals = jnp.array([ep_arm, ep_arm, ep_probe], dtype=jnp.float32)

    pr_a = (2.0 * q_rule_pre - 1.0) * (0.25 + 0.75 * q_ctrl_high)
    pr_b = -pr_a
    pr_vals = jnp.array([pr_a, pr_b, jnp.asarray(0.0, dtype=jnp.float32)], dtype=jnp.float32)
    return ep_vals, pr_vals


def _step_task_filter_jax(
    q_rule: jax.Array,
    q_ctrl_high: jax.Array,
    u_ep: jax.Array,
    p_load: jax.Array,
    cue_t: jax.Array,
    action_t: jax.Array,
    outcome_t: jax.Array,
    seq_err_t: jax.Array,
    eval_bad_t: jax.Array,
    obs_calm_t: jax.Array,
    eta_diss: jax.Array,
) -> tuple[jax.Array, jax.Array, jax.Array, jax.Array, jax.Array, jax.Array]:
    """Met à jour le filtre bayésien des croyances de tâche à partir des seules observations."""
    prior_r = 0.85 * q_rule + 0.15 * (1.0 - q_rule)
    l_cue = jnp.where(
        cue_t == 0,
        jnp.array([0.72, 0.10], dtype=jnp.float32),
        jnp.where(
            cue_t == 1,
            jnp.array([0.10, 0.72], dtype=jnp.float32),
            jnp.array([0.18, 0.18], dtype=jnp.float32),
        ),
    )
    unnorm_pre = jnp.array([prior_r * l_cue[0], (1.0 - prior_r) * l_cue[1]])
    q_rule_pre = unnorm_pre[0] / jnp.maximum(1e-8, unnorm_pre[0] + unnorm_pre[1])

    is_probe = action_t == 2
    p_pos_match = 0.5 + 0.37 * q_ctrl_high
    l_r0 = jnp.where(
        is_probe | (outcome_t == 0),
        1.0,
        jnp.where(
            outcome_t == 1,
            jnp.where(action_t == 0, p_pos_match, 1.0 - p_pos_match),
            jnp.where(action_t == 0, 1.0 - p_pos_match, p_pos_match),
        ),
    )
    l_r1 = jnp.where(
        is_probe | (outcome_t == 0),
        1.0,
        jnp.where(
            outcome_t == 1,
            jnp.where(action_t == 1, p_pos_match, 1.0 - p_pos_match),
            jnp.where(action_t == 1, 1.0 - p_pos_match, p_pos_match),
        ),
    )
    u0 = unnorm_pre[0] * l_r0
    u1 = unnorm_pre[1] * l_r1
    q_rule_post = u0 / jnp.maximum(1e-8, u0 + u1)

    # Contrôlabilité : neutralités symétriques [0.05] sous HIGH_CTRL et LOW_CTRL
    prior_c = 0.95 * q_ctrl_high + 0.05 * (1.0 - q_ctrl_high)
    p_conf = jnp.where(action_t == 0, q_rule_pre, 1.0 - q_rule_pre)
    l_high = jnp.where(
        is_probe | (outcome_t == 0),
        1.0,
        jnp.where(outcome_t == 1, 0.08 + 0.79 * p_conf, 0.87 - 0.79 * p_conf),
    )
    l_low = jnp.where(
        is_probe | (outcome_t == 0),
        1.0,
        jnp.where(outcome_t == 1, 0.45 + 0.05 * p_conf, 0.50 - 0.05 * p_conf),
    )
    uc_h = prior_c * l_high
    uc_l = (1.0 - prior_c) * l_low
    q_ctrl_post = uc_h / jnp.maximum(1e-8, uc_h + uc_l)

    qr_c = jnp.clip(q_rule_post, 1e-6, 1.0 - 1e-6)
    pr_c = jnp.clip(prior_r, 1e-6, 1.0 - 1e-6)
    kl_rule = qr_c * jnp.log(qr_c / pr_c) + (1.0 - qr_c) * jnp.log(
        (1.0 - qr_c) / (1.0 - pr_c)
    )
    h_rule = -(qr_c * jnp.log(qr_c) + (1.0 - qr_c) * jnp.log(1.0 - qr_c)) / math.log(2.0)
    is_ambig = (cue_t == 2).astype(jnp.float32)

    ep_inst = 0.90 * kl_rule + 0.55 * h_rule + 0.55 * is_ambig
    u_ep_next = jnp.where(
        obs_calm_t > 0.5,
        0.78 * u_ep + 0.22 * 0.43,
        0.78 * u_ep + 0.22 * ep_inst,
    )
    raw_ga = jnp.clip(4.2 * (0.43 - u_ep_next), -1.0, 1.0)

    out_s = jnp.where(
        outcome_t == 1,
        0.45,
        jnp.where(outcome_t == 2, -0.55, 0.0),
    )
    raw_gc = jnp.clip(2.4 * (q_ctrl_post - 0.50) + out_s, -1.0, 1.0)

    # Charge de persistance uniquement à partir des signaux observables (découplée de η_diss en actif)
    is_neg = (outcome_t == 2).astype(jnp.float32)
    aversive_drive = (
        is_neg * (0.75 + 1.10 * seq_err_t)
        + jnp.where(kl_rule > 0.12, jnp.minimum(1.10, 1.80 * kl_rule), 0.0)
        + 0.55 * is_ambig
        + 1.60 * eval_bad_t
    )
    p_load_active = jnp.clip(0.88 * p_load + 0.55 * aversive_drive, 0.0, 5.0)
    p_load_next = jnp.where(
        obs_calm_t > 0.5,
        jnp.maximum(0.0, p_load * (1.0 - eta_diss)),
        p_load_active,
    )

    return q_rule_post, q_ctrl_post, u_ep_next, p_load_next, raw_ga, raw_gc


def _compute_log_likelihood_m123_jax(
    tau_a: jax.Array,
    tau_c: jax.Array,
    lam: jax.Array,
    alpha_0: jax.Array,
    gamma_alpha: jax.Array,
    eta_diss: jax.Array,
    beta_x: jax.Array,
    beta_y: jax.Array,
    data: dict[str, jax.Array],
    *,
    gamma_choice: float = 3.0,
    kappa_filter: float = 12.0,
    sigma_ema: float = 0.14,
) -> jax.Array:
    """Vraisemblance différentiable pas à pas pour ``M1``, ``M2`` (λ=0) et ``M3`` (τ=0)."""
    T = data["cues"].shape[0]
    init_carry = (
        jnp.asarray(0.5, dtype=jnp.float32),   # q_rule
        jnp.asarray(0.5, dtype=jnp.float32),   # q_ctrl_high
        jnp.asarray(0.43, dtype=jnp.float32),  # u_ep
        jnp.asarray(0.0, dtype=jnp.float32),   # p_load
        jnp.asarray(0.0, dtype=jnp.float32),   # g_a
        jnp.asarray(0.0, dtype=jnp.float32),   # g_c
        jnp.asarray(2.0, dtype=jnp.float32),   # depth_z continu latent
    )
    xs = (
        data["cues"],
        data["actions"],
        data["outcomes"],
        data["seq_err"],
        data["eval_bad"],
        data["obs_calm"],
        data["filter_a"],
        data["filter_c"],
        data["ema_x"],
        data["ema_y"],
    )

    def scan_fn(carry: tuple[jax.Array, ...], x: tuple[jax.Array, ...]):
        q_rule, q_ctrl, u_ep, p_load, g_a, g_c, z_curr = carry
        cue_t, act_t, out_t, seq_t, eval_t, calm_t, fa_t, fc_t, ex_t, ey_t = x

        # 1. Croyance pré-décision & choix comportemental sous G(π)
        prior_r = 0.85 * q_rule + 0.15 * (1.0 - q_rule)
        l_cue = jnp.where(
            cue_t == 0,
            jnp.array([0.72, 0.10], dtype=jnp.float32),
            jnp.where(
                cue_t == 1,
                jnp.array([0.10, 0.72], dtype=jnp.float32),
                jnp.array([0.18, 0.18], dtype=jnp.float32),
            ),
        )
        u_pre = jnp.array([prior_r * l_cue[0], (1.0 - prior_r) * l_cue[1]])
        q_rule_pre = u_pre[0] / jnp.maximum(1e-8, u_pre[0] + u_pre[1])

        ep_vals, pr_vals = _compute_choice_values_jax(q_rule_pre, q_ctrl, cue_t)
        logits_u = gamma_choice * (beta_x * ep_vals + beta_y * pr_vals)
        logp_u = jax.nn.log_softmax(logits_u)[act_t]

        # 2. Filtre bayésien de tâche & inertie α_z / dissipation effective η_eff(z)
        q_rule_post, q_ctrl_post, u_ep_next, p_load_next, raw_ga, raw_gc = _step_task_filter_jax(
            q_rule, q_ctrl, u_ep, p_load, cue_t, act_t, out_t, seq_t, eval_t, calm_t, eta_diss
        )
        alpha_z = jnp.clip(alpha_0 * jnp.exp(gamma_alpha * jnp.clip(z_curr, 0.0, 7.0)), 0.05, 500.0)
        plasticity = 1.0 / (1.0 + 0.35 * alpha_z)
        eta_eff = jnp.clip(eta_diss / (1.0 + 0.18 * alpha_z), 0.005, 1.0)

        g_a_next = jnp.where(
            calm_t > 0.5,
            (1.0 - eta_eff) * g_a,
            (1.0 - plasticity) * g_a + plasticity * raw_ga,
        )
        g_c_next = jnp.where(
            calm_t > 0.5,
            (1.0 - eta_eff) * g_c,
            (1.0 - plasticity) * g_c + plasticity * raw_gc,
        )
        target_z = jnp.clip(1.35 + 1.15 * p_load_next, 1.35, 6.60)
        z_next = jnp.where(
            calm_t > 0.5,
            (1.0 - eta_eff) * z_curr,
            jnp.clip(0.82 * z_curr + 0.18 * target_z, 1.0, 6.6),
        )

        # 3. Sondes EMA Stage-1 (seuils τ_A, τ_C) & Stage-2 (projection symétrique |X|+λ|Y|<=R)
        p_fa = jnp.clip(jax.nn.sigmoid(kappa_filter * (jnp.abs(g_a_next) - tau_a)), 1e-4, 1.0 - 1e-4)
        p_fc = jnp.clip(jax.nn.sigmoid(kappa_filter * (jnp.abs(g_c_next) - tau_c)), 1e-4, 1.0 - 1e-4)
        ll_fa = fa_t * jnp.log(p_fa) + (1.0 - fa_t) * jnp.log(1.0 - p_fa)
        ll_fc = fc_t * jnp.log(p_fc) + (1.0 - fc_t) * jnp.log(1.0 - p_fc)

        radius = jnp.maximum(2.0, 2.0 * z_next - 2.0)
        dx_raw = jnp.minimum(radius, 1.85 * jnp.abs(g_a_next) * radius)
        dy_raw = jnp.minimum(radius, 1.85 * jnp.abs(g_c_next) * radius)
        denom = dx_raw + lam * dy_raw
        scale = jnp.where(denom > radius, radius / jnp.maximum(1e-6, denom), 1.0)
        dx_b = scale * dx_raw
        dy_b = jnp.minimum(radius, scale * dy_raw)

        mu_ex = jnp.sign(g_a_next + 1e-6) * dx_b / radius
        mu_ey = jnp.sign(g_c_next + 1e-6) * dy_b / radius
        ll_ex = fa_t * (
            -0.5 * jnp.square((ex_t - mu_ex) / sigma_ema)
            - jnp.log(sigma_ema * math.sqrt(2.0 * math.pi))
        )
        ll_ey = fc_t * (
            -0.5 * jnp.square((ey_t - mu_ey) / sigma_ema)
            - jnp.log(sigma_ema * math.sqrt(2.0 * math.pi))
        )

        ll_t = logp_u + ll_fa + ll_fc + ll_ex + ll_ey
        next_carry = (q_rule_post, q_ctrl_post, u_ep_next, p_load_next, g_a_next, g_c_next, z_next)
        return next_carry, ll_t

    _, ll_seq = jax.lax.scan(scan_fn, init_carry, xs, length=T)
    return ll_seq


def _compute_log_likelihood_m4_jax(
    alpha_v: jax.Array,
    tau_v: jax.Array,
    eta_diss: jax.Array,
    beta_scalar: jax.Array,
    sigma_v: jax.Array,
    data: dict[str, jax.Array],
    *,
    gamma_choice: float = 3.0,
    kappa_filter: float = 12.0,
) -> jax.Array:
    """Vraisemblance différentiable équitable de ``M4`` (valence scalaire 1D ; Hesp et al., 2021)."""
    T = data["cues"].shape[0]
    init_carry = (
        jnp.asarray(0.5, dtype=jnp.float32),
        jnp.asarray(0.5, dtype=jnp.float32),
        jnp.asarray(0.43, dtype=jnp.float32),
        jnp.asarray(0.0, dtype=jnp.float32),
        jnp.asarray(0.0, dtype=jnp.float32),  # valence scalaire 1D v_t
    )
    xs = (
        data["cues"],
        data["actions"],
        data["outcomes"],
        data["seq_err"],
        data["eval_bad"],
        data["obs_calm"],
        data["filter_a"],
        data["filter_c"],
        data["ema_x"],
        data["ema_y"],
    )

    def scan_fn(carry: tuple[jax.Array, ...], x: tuple[jax.Array, ...]):
        q_rule, q_ctrl, u_ep, p_load, val = carry
        cue_t, act_t, out_t, seq_t, eval_t, calm_t, fa_t, fc_t, ex_t, ey_t = x

        prior_r = 0.85 * q_rule + 0.15 * (1.0 - q_rule)
        l_cue = jnp.where(
            cue_t == 0,
            jnp.array([0.72, 0.10], dtype=jnp.float32),
            jnp.where(
                cue_t == 1,
                jnp.array([0.10, 0.72], dtype=jnp.float32),
                jnp.array([0.18, 0.18], dtype=jnp.float32),
            ),
        )
        u_pre = jnp.array([prior_r * l_cue[0], (1.0 - prior_r) * l_cue[1]])
        q_rule_pre = u_pre[0] / jnp.maximum(1e-8, u_pre[0] + u_pre[1])

        _, pr_vals = _compute_choice_values_jax(q_rule_pre, q_ctrl, cue_t)
        logits_u = gamma_choice * (beta_scalar * pr_vals)
        logp_u = jax.nn.log_softmax(logits_u)[act_t]

        q_rule_post, q_ctrl_post, u_ep_next, p_load_next, raw_ga, raw_gc = _step_task_filter_jax(
            q_rule, q_ctrl, u_ep, p_load, cue_t, act_t, out_t, seq_t, eval_t, calm_t, eta_diss
        )
        scalar_drive = 0.5 * (raw_ga + raw_gc)
        w_v = 1.0 / (1.0 + alpha_v)
        val_next = jnp.where(
            calm_t > 0.5,
            (1.0 - eta_diss) * val,
            (1.0 - w_v) * val + w_v * scalar_drive,
        )

        p_f = jnp.clip(jax.nn.sigmoid(kappa_filter * (jnp.abs(val_next) - tau_v)), 1e-4, 1.0 - 1e-4)
        ll_fa = fa_t * jnp.log(p_f) + (1.0 - fa_t) * jnp.log(1.0 - p_f)
        ll_fc = fc_t * jnp.log(p_f) + (1.0 - fc_t) * jnp.log(1.0 - p_f)

        ll_ex = fa_t * (
            -0.5 * jnp.square((ex_t - val_next) / sigma_v)
            - jnp.log(sigma_v * math.sqrt(2.0 * math.pi))
        )
        ll_ey = fc_t * (
            -0.5 * jnp.square((ey_t - val_next) / sigma_v)
            - jnp.log(sigma_v * math.sqrt(2.0 * math.pi))
        )

        ll_t = logp_u + ll_fa + ll_fc + ll_ex + ll_ey
        return (q_rule_post, q_ctrl_post, u_ep_next, p_load_next, val_next), ll_t

    _, ll_seq = jax.lax.scan(scan_fn, init_carry, xs, length=T)
    return ll_seq


def simulate_dataset_for_model(
    model_name: str,
    params: dict[str, float],
    *,
    num_trials: int = 280,
    seed: int = 42,
    schedule: tuple[BlockSpec, ...] | None = None,
) -> RecoveryDataset:
    """Simule en boucle fermée réelle sur ``NonStationaryBanditEnv`` (sans fuite de labels)."""
    if model_name not in MODEL_NAMES:
        raise ValueError(f"Modèle inconnu: {model_name} (attendu dans {MODEL_NAMES})")

    sched = build_recovery_schedule(num_trials) if schedule is None else schedule
    env = NonStationaryBanditEnv(schedule=sched, seed=seed)
    env.reset()
    rng = np.random.default_rng(seed + 991)
    T = env.total_trials

    tau_a = 0.0 if model_name == "M3_NoThresholds" else float(params.get("tau_A", 0.25))
    tau_c = 0.0 if model_name == "M3_NoThresholds" else float(params.get("tau_C", 0.25))
    tau_v = float(params.get("tau_v", 0.25))
    lam = 0.0 if model_name == "M2_NoBudget_Lam0" else float(params.get("lambda", 0.5))
    alpha_0 = float(params.get("alpha_0", 1.0))
    gamma_alpha = float(params.get("gamma_alpha", 0.4))
    eta_diss = float(params.get("eta_diss", 0.25))
    beta_y = float(params.get("beta_Y", 1.0))
    beta_x = float(params.get("beta_X", 2.0))
    beta_scalar = float(params.get("beta_scalar", beta_y))
    alpha_v = float(params.get("alpha_v", alpha_0))

    gamma_choice = 3.0
    kappa_filter = 12.0
    sigma_ema = 0.14

    q_rule = 0.5
    q_ctrl = 0.5
    u_ep = 0.43
    p_load = 0.0
    g_a = 0.0
    g_c = 0.0
    z_curr = 2.0
    val_1d = 0.0
    neutral_streak = 0

    cues = np.zeros(T, dtype=np.int32)
    actions = np.zeros(T, dtype=np.int32)
    outcomes = np.zeros(T, dtype=np.int32)
    seq_err_arr = np.zeros(T, dtype=np.float32)
    eval_bad_arr = np.zeros(T, dtype=np.float32)
    obs_calm_arr = np.zeros(T, dtype=np.float32)
    filter_a = np.zeros(T, dtype=np.float32)
    filter_c = np.zeros(T, dtype=np.float32)
    ema_x = np.zeros(T, dtype=np.float32)
    ema_y = np.zeros(T, dtype=np.float32)
    z_trace = np.zeros(T, dtype=np.float32)

    for t in range(T):
        pre_obs = env.current_observation()
        cue_t = int(pre_obs.sensory_payload()["cue"])
        cues[t] = cue_t

        # 1. Croyance pré-décision (indice uniquement)
        prior_r = 0.85 * q_rule + 0.15 * (1.0 - q_rule)
        if cue_t == 0:
            lc0, lc1 = 0.72, 0.10
        elif cue_t == 1:
            lc0, lc1 = 0.10, 0.72
        else:
            lc0, lc1 = 0.18, 0.18
        u0, u1 = prior_r * lc0, (1.0 - prior_r) * lc1
        q_rule_pre = u0 / max(1e-8, u0 + u1)

        p_rc = float(np.clip(q_rule_pre, 1e-6, 1.0 - 1e-6))
        h_rule_pre = -(p_rc * math.log(p_rc) + (1.0 - p_rc) * math.log(1.0 - p_rc)) / math.log(2.0)
        is_amb = 1.0 if cue_t == 2 else 0.0
        ep_vals = np.array(
            [0.12 * h_rule_pre * q_ctrl, 0.12 * h_rule_pre * q_ctrl, 0.85 * h_rule_pre + 0.35 * is_amb],
            dtype=np.float64,
        )
        pr_a = (2.0 * q_rule_pre - 1.0) * (0.25 + 0.75 * q_ctrl)
        pr_vals = np.array([pr_a, -pr_a, 0.0], dtype=np.float64)

        if model_name == "M4_ScalarValence_1D":
            logits = gamma_choice * (beta_scalar * pr_vals)
        else:
            logits = gamma_choice * (beta_x * ep_vals + beta_y * pr_vals)
        logits -= np.max(logits)
        probs_u = np.exp(logits)
        probs_u /= np.sum(probs_u)
        act_t = int(rng.choice(3, p=probs_u))
        actions[t] = act_t

        # 2. Interaction réelle en boucle fermée avec NonStationaryBanditEnv (PROBE clarifie cue_{t+1})
        step_res = env.step(BanditAction(act_t))
        payload = step_res.observation.sensory_payload()
        out_t = 1 if payload["outcome"] == OutcomeValence.POSITIVE else (
            2 if payload["outcome"] == OutcomeValence.NEGATIVE else 0
        )
        outcomes[t] = out_t

        seq_err_t = float(payload["sequence_failure_rate"])
        ev_score = payload["evaluative_score"]
        eval_bad_t = (
            (1.0 - float(ev_score))
            if (ev_score is not None and float(ev_score) < 0.70)
            else 0.0
        )
        seq_err_arr[t] = seq_err_t
        eval_bad_arr[t] = eval_bad_t

        # Détection purement sensorielle du calme (2 neutres hors-PROBE consécutifs)
        if out_t != 0:
            neutral_streak = 0
            calm_t = 0.0
        else:
            if act_t != 2:
                neutral_streak += 1
            calm_t = 1.0 if neutral_streak >= 2 else 0.0
        obs_calm_arr[t] = calm_t

        # 3. Mise à jour du filtre de tâche
        is_probe = act_t == 2
        p_pos_match = 0.5 + 0.37 * q_ctrl
        if is_probe or out_t == 0:
            lr0, lr1 = 1.0, 1.0
        elif out_t == 1:
            lr0 = p_pos_match if act_t == 0 else (1.0 - p_pos_match)
            lr1 = p_pos_match if act_t == 1 else (1.0 - p_pos_match)
        else:
            lr0 = (1.0 - p_pos_match) if act_t == 0 else p_pos_match
            lr1 = (1.0 - p_pos_match) if act_t == 1 else p_pos_match
        post0, post1 = u0 * lr0, u1 * lr1
        q_rule = post0 / max(1e-8, post0 + post1)

        prior_c = 0.95 * q_ctrl + 0.05 * (1.0 - q_ctrl)
        p_conf = q_rule_pre if act_t == 0 else (1.0 - q_rule_pre)
        if is_probe or out_t == 0:
            lh, ll_ctrl = 1.0, 1.0
        elif out_t == 1:
            lh, ll_ctrl = 0.08 + 0.79 * p_conf, 0.45 + 0.05 * p_conf
        else:
            lh, ll_ctrl = 0.87 - 0.79 * p_conf, 0.50 - 0.05 * p_conf
        uch, ucl = prior_c * lh, (1.0 - prior_c) * ll_ctrl
        q_ctrl = uch / max(1e-8, uch + ucl)

        qr_c = float(np.clip(q_rule, 1e-6, 1.0 - 1e-6))
        pr_c = float(np.clip(prior_r, 1e-6, 1.0 - 1e-6))
        kl_rule = qr_c * math.log(qr_c / pr_c) + (1.0 - qr_c) * math.log((1.0 - qr_c) / (1.0 - pr_c))
        h_rule = -(qr_c * math.log(qr_c) + (1.0 - qr_c) * math.log(1.0 - qr_c)) / math.log(2.0)

        ep_inst = 0.90 * kl_rule + 0.55 * h_rule + 0.55 * is_amb
        if calm_t > 0.5:
            u_ep = 0.78 * u_ep + 0.22 * 0.43
        else:
            u_ep = 0.78 * u_ep + 0.22 * ep_inst
        raw_ga = float(np.clip(4.2 * (0.43 - u_ep), -1.0, 1.0))

        out_s = 0.45 if out_t == 1 else (-0.55 if out_t == 2 else 0.0)
        raw_gc = float(np.clip(2.4 * (q_ctrl - 0.50) + out_s, -1.0, 1.0))

        aversive_drive = (
            (0.75 + 1.10 * seq_err_t if out_t == 2 else 0.0)
            + (min(1.10, 1.80 * kl_rule) if kl_rule > 0.12 else 0.0)
            + 0.55 * is_amb
            + 1.60 * eval_bad_t
        )
        if calm_t > 0.5:
            p_load = max(0.0, p_load * (1.0 - eta_diss))
        else:
            p_load = min(5.0, max(0.0, 0.88 * p_load + 0.55 * aversive_drive))

        # 4. Émission selon le modèle génératif candidat
        if model_name == "M4_ScalarValence_1D":
            w_v = 1.0 / (1.0 + alpha_v)
            s_drive = 0.5 * (raw_ga + raw_gc)
            val_1d = (1.0 - eta_diss) * val_1d if calm_t > 0.5 else (1.0 - w_v) * val_1d + w_v * s_drive
            target_z = min(6.60, max(1.35, 1.35 + 1.15 * p_load))
            z_curr = (1.0 - eta_diss) * z_curr if calm_t > 0.5 else min(6.6, max(1.0, 0.82 * z_curr + 0.18 * target_z))
            p_f = 1.0 / (1.0 + math.exp(-max(-30.0, min(30.0, kappa_filter * (abs(val_1d) - tau_v)))))
            fa = 1.0 if rng.random() < p_f else 0.0
            fc = 1.0 if rng.random() < p_f else 0.0
            ex = float(rng.normal(val_1d, sigma_ema)) if fa > 0.5 else 0.0
            ey = float(rng.normal(val_1d, sigma_ema)) if fc > 0.5 else 0.0
        else:
            alpha_z = min(500.0, max(0.05, alpha_0 * math.exp(gamma_alpha * min(7.0, max(0.0, z_curr)))))
            plasticity = 1.0 / (1.0 + 0.35 * alpha_z)
            eta_eff = float(np.clip(eta_diss / (1.0 + 0.18 * alpha_z), 0.005, 1.0))
            if calm_t > 0.5:
                g_a *= 1.0 - eta_eff
                g_c *= 1.0 - eta_eff
                z_curr *= 1.0 - eta_eff
            else:
                g_a = (1.0 - plasticity) * g_a + plasticity * raw_ga
                g_c = (1.0 - plasticity) * g_c + plasticity * raw_gc
                tgt_z = min(6.60, max(1.35, 1.35 + 1.15 * p_load))
                z_curr = min(6.6, max(1.0, 0.82 * z_curr + 0.18 * tgt_z))

            p_fa = 1.0 / (1.0 + math.exp(-max(-30.0, min(30.0, kappa_filter * (abs(g_a) - tau_a)))))
            p_fc = 1.0 / (1.0 + math.exp(-max(-30.0, min(30.0, kappa_filter * (abs(g_c) - tau_c)))))
            fa = 1.0 if rng.random() < p_fa else 0.0
            fc = 1.0 if rng.random() < p_fc else 0.0

            radius = max(2.0, 2.0 * z_curr - 2.0)
            dx_raw = min(radius, 1.85 * abs(g_a) * radius)
            dy_raw = min(radius, 1.85 * abs(g_c) * radius)
            dx_b, dy_b = apply_budget_constraint(dx_raw, dy_raw, radius, lam)
            mu_ex = math.copysign(dx_b / radius, g_a if g_a != 0.0 else 1.0)
            mu_ey = math.copysign(dy_b / radius, g_c if g_c != 0.0 else 1.0)
            ex = float(rng.normal(mu_ex, sigma_ema)) if fa > 0.5 else 0.0
            ey = float(rng.normal(mu_ey, sigma_ema)) if fc > 0.5 else 0.0

        filter_a[t] = fa
        filter_c[t] = fc
        ema_x[t] = ex
        ema_y[t] = ey
        z_trace[t] = z_curr

    return RecoveryDataset(
        cues=cues,
        actions=actions,
        outcomes=outcomes,
        seq_err=seq_err_arr,
        eval_bad=eval_bad_arr,
        obs_calm=obs_calm_arr,
        filter_a=filter_a,
        filter_c=filter_c,
        ema_x=ema_x,
        ema_y=ema_y,
        z_level=z_trace,
    )


def build_numpyro_model(model_name: str):
    """Construit le modèle probabiliste ``NumPyro`` reparamétré pour ``M1..M4``."""
    if model_name not in MODEL_NAMES:
        raise ValueError(f"Modèle inconnu: {model_name}")

    def numpyro_model(data: dict[str, jax.Array]) -> None:
        if model_name == "M4_ScalarValence_1D":
            alpha_v = numpyro.sample("alpha_v", dist.Uniform(0.10, 4.00))
            tau_v = numpyro.sample("tau_v", dist.Uniform(0.05, 0.70))
            eta_diss = numpyro.sample("eta_diss", dist.Uniform(0.05, 0.75))
            beta_scalar = numpyro.sample("beta_scalar", dist.Uniform(0.20, 4.00))
            sigma_v = numpyro.sample("sigma_v", dist.Uniform(0.06, 0.50))
            ll_seq = _compute_log_likelihood_m4_jax(
                alpha_v, tau_v, eta_diss, beta_scalar, sigma_v, data
            )
        else:
            if model_name == "M3_NoThresholds":
                tau_a = jnp.asarray(0.0, dtype=jnp.float32)
                tau_c = jnp.asarray(0.0, dtype=jnp.float32)
            else:
                tau_a = numpyro.sample("tau_A", dist.Uniform(0.05, 0.70))
                tau_c = numpyro.sample("tau_C", dist.Uniform(0.05, 0.70))

            if model_name == "M2_NoBudget_Lam0":
                lam = jnp.asarray(0.0, dtype=jnp.float32)
            else:
                lam = numpyro.sample("lambda", dist.Uniform(0.0, 1.0))

            # Reparamétrisation centrée à z_ref = 3.5 éliminant la colinéarité (α_0, γ_α)
            log_alpha_mid = numpyro.sample("log_alpha_mid", dist.Normal(1.3, 1.3))
            gamma_alpha = numpyro.sample("gamma_alpha", dist.Uniform(0.05, 1.05))
            alpha_0 = numpyro.deterministic(
                "alpha_0", jnp.exp(log_alpha_mid - 3.5 * gamma_alpha)
            )
            eta_diss = numpyro.sample("eta_diss", dist.Uniform(0.05, 0.75))

            # Reparamétrisation garantissant strictement β_X > β_Y sans biais caché
            beta_y = numpyro.sample("beta_Y", dist.Uniform(0.25, 1.80))
            delta_beta = numpyro.sample("delta_beta", dist.Uniform(0.15, 3.20))
            beta_x = numpyro.deterministic("beta_X", beta_y + delta_beta)

            ll_seq = _compute_log_likelihood_m123_jax(
                tau_a,
                tau_c,
                lam,
                alpha_0,
                gamma_alpha,
                eta_diss,
                beta_x,
                beta_y,
                data,
            )

        numpyro.deterministic("ll_pointwise", ll_seq)
        numpyro.factor("obs_ll", jnp.sum(ll_seq))

    return numpyro_model


def compute_waic_and_bic(
    ll_draws: np.ndarray,
    num_params: int,
    n_obs: int | None = None,
) -> tuple[float, float, float]:
    """Calcule ``(WAIC, BIC, p_WAIC)`` en utilisant ``max(ll)`` (approx. MLE) pour le BIC."""
    arr = np.asarray(ll_draws, dtype=np.float64)
    n_draws, n_cols = arr.shape
    max_ll_t = np.max(arr, axis=0, keepdims=True)
    lppd_t = max_ll_t.squeeze(0) + np.log(np.mean(np.exp(arr - max_ll_t), axis=0))
    lppd = float(np.sum(lppd_t))
    p_waic = float(np.sum(np.var(arr, axis=0, ddof=1 if n_draws > 1 else 0)))
    waic = float(-2.0 * (lppd - p_waic))

    max_total_ll = float(np.max(np.sum(arr, axis=1)))
    n_eff = int(n_cols) if n_obs is None else int(n_obs)
    bic = float(-2.0 * max_total_ll + num_params * math.log(max(1, n_eff)))
    return waic, bic, p_waic


def compute_protected_exceedance_probability(
    log_evidences: np.ndarray,
    *,
    num_mc_samples: int = 200_000,
    seed: int = 42,
    max_iter: int = 500,
    tol: float = 1e-8,
) -> dict[str, Any]:
    """Bayesian Model Selection à effets aléatoires : ``pxp`` & BOR (Rigoux et al., 2014)."""
    L = np.asarray(log_evidences, dtype=np.float64)
    if L.ndim != 2:
        raise ValueError("log_evidences doit être une matrice 2D (N_datasets, K_models)")
    n_subj, n_models = L.shape
    alpha_0 = np.ones(n_models, dtype=np.float64)
    alpha = alpha_0.copy()
    g = np.full((n_subj, n_models), 1.0 / n_models, dtype=np.float64)

    for _ in range(max_iter):
        log_r = psi(alpha) - psi(np.sum(alpha))
        log_u = L + log_r[None, :]
        log_u -= np.max(log_u, axis=1, keepdims=True)
        u = np.exp(log_u)
        g = u / np.sum(u, axis=1, keepdims=True)
        alpha_new = alpha_0 + np.sum(g, axis=0)
        if np.max(np.abs(alpha_new - alpha)) < tol:
            alpha = alpha_new
            break
        alpha = alpha_new

    log_r = psi(alpha) - psi(np.sum(alpha))
    g_safe = np.maximum(g, 1e-300)
    f1 = float(
        np.sum(g * (L + log_r[None, :] - np.log(g_safe)))
        + gammaln(np.sum(alpha_0))
        - np.sum(gammaln(alpha_0))
        - gammaln(np.sum(alpha))
        + np.sum(gammaln(alpha))
        + np.sum((alpha_0 - alpha) * log_r)
    )
    max_l = np.max(L, axis=1, keepdims=True)
    log_mean_exp = max_l.squeeze(1) + np.log(np.mean(np.exp(L - max_l), axis=1))
    f0 = float(np.sum(log_mean_exp))

    bor = float(1.0 / (1.0 + math.exp(max(-500.0, min(500.0, f1 - f0)))))

    rng = np.random.default_rng(seed)
    draws = rng.dirichlet(alpha, size=num_mc_samples)
    winners = np.argmax(draws, axis=1)
    xp = np.bincount(winners, minlength=n_models).astype(np.float64) / float(num_mc_samples)
    pxp = (1.0 - bor) * xp + bor / float(n_models)

    return {
        "xp": xp,
        "pxp": pxp,
        "bor": bor,
        "alpha": alpha,
        "expected_frequencies": alpha / np.sum(alpha),
        "free_energy_h1": f1,
        "free_energy_h0": f0,
    }


def _extract_param_summary(
    posterior_samples: dict[str, np.ndarray],
    model_name: str,
) -> tuple[dict[str, float], dict[str, float], dict[str, tuple[float, float]]]:
    means: dict[str, float] = {}
    sds: dict[str, float] = {}
    ci95: dict[str, tuple[float, float]] = {}
    keys = (
        ("alpha_v", "tau_v", "eta_diss", "beta_scalar", "sigma_v")
        if model_name == "M4_ScalarValence_1D"
        else [
            k
            for k in THETA_NAMES
            if not (model_name == "M2_NoBudget_Lam0" and k == "lambda")
            and not (model_name == "M3_NoThresholds" and k in ("tau_A", "tau_C"))
        ]
    )
    for k in keys:
        vals = np.asarray(posterior_samples[k], dtype=np.float64).reshape(-1)
        means[k] = float(np.mean(vals))
        sds[k] = float(np.std(vals, ddof=1))
        lo, hi = np.percentile(vals, [2.5, 97.5])
        ci95[k] = (float(lo), float(hi))
    return means, sds, ci95


def invert_dataset_svi(
    model_name: str,
    dataset: RecoveryDataset,
    *,
    seed: int = 42,
    num_steps: int = 1000,
    num_posterior_samples: int = 200,
    lr: float = 0.02,
) -> dict[str, Any]:
    """Inverse un jeu de données par Inférence Variationnelle NumPyro (SVI + AutoMVN)."""
    model = build_numpyro_model(model_name)
    guide = AutoMultivariateNormal(model)
    svi = SVI(model, guide, numpyro.optim.Adam(step_size=lr), Trace_ELBO())
    data_jax = dataset.to_jax_dict()

    rng_key = jax.random.PRNGKey(seed)
    k_run, k_guide, k_model = jax.random.split(rng_key, 3)
    svi_res = svi.run(k_run, num_steps, data_jax, progress_bar=False)
    guide_samples = Predictive(
        guide,
        params=svi_res.params,
        num_samples=num_posterior_samples,
    )(k_guide, data_jax)
    model_samples = Predictive(
        model,
        posterior_samples=guide_samples,
    )(k_model, data_jax)
    samples = {**guide_samples, **model_samples}
    samples_np = {
        k: np.asarray(v) for k, v in samples.items() if not k.startswith("_")
    }

    ll_draws = samples_np["ll_pointwise"]
    waic, bic, p_waic = compute_waic_and_bic(
        ll_draws,
        MODEL_PARAM_COUNTS[model_name],
        n_obs=dataset.num_active_scalar_obs,
    )
    means, sds, ci95 = _extract_param_summary(samples_np, model_name)

    return {
        "model": model_name,
        "means": means,
        "sds": sds,
        "ci95": ci95,
        "waic": waic,
        "bic": bic,
        "p_waic": p_waic,
        "elbo_final": float(svi_res.losses[-1]),
    }


_SVI_BATCH_KERNEL_CACHE: dict[tuple[str, int, int, float], Any] = {}


def _get_svi_batch_kernel(
    model_name: str,
    num_steps: int,
    num_posterior_samples: int,
    lr: float,
):
    key = (model_name, int(num_steps), int(num_posterior_samples), float(lr))
    cached = _SVI_BATCH_KERNEL_CACHE.get(key)
    if cached is not None:
        return cached

    model = build_numpyro_model(model_name)
    guide = AutoMultivariateNormal(model)
    svi = SVI(model, guide, numpyro.optim.Adam(step_size=lr), Trace_ELBO())

    @jax.jit
    def _invert_batch(rng_keys: jax.Array, data_batch: dict[str, jax.Array]):
        def single(k: jax.Array, d: dict[str, jax.Array]):
            k_run, k_guide, k_model = jax.random.split(k, 3)
            svi_res = svi.run(k_run, num_steps, d, progress_bar=False)
            guide_samples = Predictive(
                guide,
                params=svi_res.params,
                num_samples=num_posterior_samples,
            )(k_guide, d)
            model_samples = Predictive(
                model,
                posterior_samples=guide_samples,
            )(k_model, d)
            combined = {**guide_samples, **model_samples}
            post_clean = {
                pname: pval
                for pname, pval in combined.items()
                if pname != "ll_pointwise" and not pname.startswith("_")
            }
            return post_clean, combined["ll_pointwise"], svi_res.losses[-1]

        return jax.vmap(single)(rng_keys, data_batch)

    _SVI_BATCH_KERNEL_CACHE[key] = _invert_batch
    return _invert_batch


def batch_invert_svi(
    model_name: str,
    datasets: list[RecoveryDataset],
    *,
    seed: int = 42,
    num_steps: int = 1000,
    num_posterior_samples: int = 200,
    lr: float = 0.02,
    batch_size: int = 50,
) -> list[dict[str, Any]]:
    """Inversion SVI vectorisée via ``jax.vmap`` par lots sur N jeux de données."""
    _invert_batch = _get_svi_batch_kernel(model_name, num_steps, num_posterior_samples, lr)

    results: list[dict[str, Any]] = []
    master_key = jax.random.PRNGKey(seed)
    n_total = len(datasets)

    for start in range(0, n_total, batch_size):
        chunk = datasets[start : min(n_total, start + batch_size)]
        stacked = {
            "cues": jnp.stack([jnp.asarray(d.cues, dtype=jnp.int32) for d in chunk]),
            "actions": jnp.stack([jnp.asarray(d.actions, dtype=jnp.int32) for d in chunk]),
            "outcomes": jnp.stack([jnp.asarray(d.outcomes, dtype=jnp.int32) for d in chunk]),
            "seq_err": jnp.stack([jnp.asarray(d.seq_err, dtype=jnp.float32) for d in chunk]),
            "eval_bad": jnp.stack([jnp.asarray(d.eval_bad, dtype=jnp.float32) for d in chunk]),
            "obs_calm": jnp.stack([jnp.asarray(d.obs_calm, dtype=jnp.float32) for d in chunk]),
            "filter_a": jnp.stack([jnp.asarray(d.filter_a, dtype=jnp.float32) for d in chunk]),
            "filter_c": jnp.stack([jnp.asarray(d.filter_c, dtype=jnp.float32) for d in chunk]),
            "ema_x": jnp.stack([jnp.asarray(d.ema_x, dtype=jnp.float32) for d in chunk]),
            "ema_y": jnp.stack([jnp.asarray(d.ema_y, dtype=jnp.float32) for d in chunk]),
        }
        master_key, subkey = jax.random.split(master_key)
        batch_keys = jax.random.split(subkey, len(chunk))
        post_b, ll_b, loss_b = _invert_batch(batch_keys, stacked)
        post_np = {k: np.asarray(v) for k, v in post_b.items()}
        ll_np = np.asarray(ll_b)
        loss_np = np.asarray(loss_b)

        for i in range(len(chunk)):
            sub_samples = {k: v[i] for k, v in post_np.items()}
            waic, bic, p_waic = compute_waic_and_bic(
                ll_np[i],
                MODEL_PARAM_COUNTS[model_name],
                n_obs=chunk[i].num_active_scalar_obs,
            )
            means, sds, ci95 = _extract_param_summary(sub_samples, model_name)
            results.append(
                {
                    "model": model_name,
                    "means": means,
                    "sds": sds,
                    "ci95": ci95,
                    "waic": waic,
                    "bic": bic,
                    "p_waic": p_waic,
                    "elbo_final": float(loss_np[i]),
                }
            )
    return results


def invert_dataset_nuts(
    dataset: RecoveryDataset,
    *,
    model_name: str = "M1_CARTOGRAFFECT",
    seed: int = 42,
    num_warmup: int = 600,
    num_samples: int = 900,
    num_chains: int = 2,
    chain_method: str = "vectorized",
) -> dict[str, Any]:
    """Inversion MCMC exacte via ``NumPyro NUTS`` et diagnostics ``ArviZ`` (R-hat, ESS)."""
    model = build_numpyro_model(model_name)
    kernel = NUTS(model, target_accept_prob=0.88)
    mcmc = MCMC(
        kernel,
        num_warmup=num_warmup,
        num_samples=num_samples,
        num_chains=num_chains,
        chain_method=chain_method,
        progress_bar=False,
    )
    data_jax = dataset.to_jax_dict()
    mcmc.run(jax.random.PRNGKey(seed), data_jax)
    idata = az.from_numpyro(mcmc)

    samples = {k: np.asarray(v) for k, v in mcmc.get_samples().items()}
    ll_draws = samples["ll_pointwise"]
    waic, bic, p_waic = compute_waic_and_bic(
        ll_draws,
        MODEL_PARAM_COUNTS[model_name],
        n_obs=dataset.num_active_scalar_obs,
    )
    means, sds, ci95 = _extract_param_summary(samples, model_name)

    param_keys = list(means.keys())
    rhat_dict: dict[str, float] = {}
    ess_dict: dict[str, float] = {}
    rhat_ds = az.rhat(idata, var_names=param_keys)
    ess_ds = az.ess(idata, var_names=param_keys)
    for k in param_keys:
        rhat_dict[k] = float(rhat_ds[k].to_numpy())
        ess_dict[k] = float(ess_ds[k].to_numpy())

    return {
        "model": model_name,
        "means": means,
        "sds": sds,
        "ci95": ci95,
        "waic": waic,
        "bic": bic,
        "p_waic": p_waic,
        "rhat": rhat_dict,
        "ess": ess_dict,
        "idata": idata,
    }


def run_parameter_recovery(
    num_datasets: int = 500,
    *,
    num_trials: int = 280,
    seed: int = 42,
    num_steps: int = 1000,
    num_posterior_samples: int = 200,
    lr: float = 0.02,
    batch_size: int = 50,
    nuts_check_count: int = 10,
    nuts_warmup: int = 600,
    nuts_samples: int = 900,
) -> dict[str, Any]:
    """Pipeline complet de Parameter Recovery sur ``M`` vecteurs ``θ_vrai``."""
    true_thetas = sample_true_parameters(num_datasets, seed=seed)
    datasets = [
        simulate_dataset_for_model(
            "M1_CARTOGRAFFECT",
            th,
            num_trials=num_trials,
            seed=seed + idx + 1,
        )
        for idx, th in enumerate(true_thetas)
    ]

    inversions = batch_invert_svi(
        "M1_CARTOGRAFFECT",
        datasets,
        seed=seed + 10_000,
        num_steps=num_steps,
        num_posterior_samples=num_posterior_samples,
        lr=lr,
        batch_size=batch_size,
    )

    true_mat = np.array(
        [[th[p] for p in THETA_NAMES] for th in true_thetas], dtype=np.float64
    )
    est_mat = np.array(
        [[inv["means"][p] for p in THETA_NAMES] for inv in inversions], dtype=np.float64
    )
    err_mat = est_mat - true_mat

    pearson_r: dict[str, float] = {}
    rmse: dict[str, float] = {}
    bias: dict[str, float] = {}
    coverage_95: dict[str, float] = {}
    corr_matrix = np.zeros((len(THETA_NAMES), len(THETA_NAMES)), dtype=np.float64)
    error_corr_matrix = np.zeros((len(THETA_NAMES), len(THETA_NAMES)), dtype=np.float64)

    for i, pi in enumerate(THETA_NAMES):
        t_col = true_mat[:, i]
        e_col = est_mat[:, i]
        pearson_r[pi] = float(np.corrcoef(t_col, e_col)[0, 1])
        rmse[pi] = float(np.sqrt(np.mean((e_col - t_col) ** 2)))
        bias[pi] = float(np.mean(e_col - t_col))
        covered = [
            inv["ci95"][pi][0] <= true_thetas[idx][pi] <= inv["ci95"][pi][1]
            for idx, inv in enumerate(inversions)
        ]
        coverage_95[pi] = float(np.mean(covered))
        for j in range(len(THETA_NAMES)):
            corr_matrix[i, j] = float(np.corrcoef(true_mat[:, i], est_mat[:, j])[0, 1])
            error_corr_matrix[i, j] = float(np.corrcoef(err_mat[:, i], err_mat[:, j])[0, 1])

    # Validation croisée MCMC NUTS + ArviZ étendue sur N_nuts jeux
    nuts_checks: list[dict[str, Any]] = []
    for idx in range(min(nuts_check_count, num_datasets)):
        nuts_res = invert_dataset_nuts(
            datasets[idx],
            seed=seed + 50_000 + idx,
            num_warmup=nuts_warmup,
            num_samples=nuts_samples,
            num_chains=2,
            chain_method="vectorized",
        )
        nuts_checks.append(
            {
                "dataset_index": idx,
                "true": true_thetas[idx],
                "nuts_means": nuts_res["means"],
                "svi_means": inversions[idx]["means"],
                "max_rhat": float(max(nuts_res["rhat"].values())),
                "min_ess": float(min(nuts_res["ess"].values())),
            }
        )

    return {
        "num_datasets": num_datasets,
        "num_trials": num_trials,
        "theta_names": THETA_NAMES,
        "true_thetas": true_mat,
        "est_thetas": est_mat,
        "corr_matrix": corr_matrix,
        "error_corr_matrix": error_corr_matrix,
        "pearson_r": pearson_r,
        "rmse": rmse,
        "bias": bias,
        "coverage_95": coverage_95,
        "nuts_checks": nuts_checks,
    }


def _sample_model_params(model_name: str, rng: np.random.Generator) -> dict[str, float]:
    """Tire des paramètres générateurs sur le support complet et non tronqué pour ``M1..M4``."""
    if model_name == "M1_CARTOGRAFFECT":
        beta_y = float(rng.uniform(0.45, 1.55))
        return {
            "tau_A": float(rng.uniform(0.12, 0.52)),
            "tau_C": float(rng.uniform(0.12, 0.52)),
            "lambda": float(rng.uniform(0.15, 0.95)),
            "alpha_0": float(rng.uniform(0.35, 2.20)),
            "gamma_alpha": float(rng.uniform(0.12, 0.72)),
            "eta_diss": float(rng.uniform(0.10, 0.58)),
            "beta_Y": beta_y,
            "beta_X": float(beta_y + rng.uniform(0.70, 2.80)),
        }
    if model_name == "M2_NoBudget_Lam0":
        beta_y = float(rng.uniform(0.45, 1.55))
        return {
            "tau_A": float(rng.uniform(0.12, 0.52)),
            "tau_C": float(rng.uniform(0.12, 0.52)),
            "lambda": 0.0,
            "alpha_0": float(rng.uniform(0.35, 2.20)),
            "gamma_alpha": float(rng.uniform(0.12, 0.72)),
            "eta_diss": float(rng.uniform(0.10, 0.58)),
            "beta_Y": beta_y,
            "beta_X": float(beta_y + rng.uniform(0.70, 2.80)),
        }
    if model_name == "M3_NoThresholds":
        beta_y = float(rng.uniform(0.45, 1.55))
        return {
            "tau_A": 0.0,
            "tau_C": 0.0,
            "lambda": float(rng.uniform(0.15, 0.95)),
            "alpha_0": float(rng.uniform(0.35, 2.20)),
            "gamma_alpha": float(rng.uniform(0.12, 0.72)),
            "eta_diss": float(rng.uniform(0.10, 0.58)),
            "beta_Y": beta_y,
            "beta_X": float(beta_y + rng.uniform(0.70, 2.80)),
        }
    # M4_ScalarValence_1D
    return {
        "alpha_v": float(rng.uniform(0.4, 2.4)),
        "tau_v": float(rng.uniform(0.12, 0.50)),
        "eta_diss": float(rng.uniform(0.10, 0.55)),
        "beta_scalar": float(rng.uniform(0.6, 2.6)),
    }


def run_model_recovery(
    num_datasets_per_model: int = 100,
    *,
    num_trials: int = 280,
    seed: int = 123,
    num_steps: int = 800,
    num_posterior_samples: int = 160,
    lr: float = 0.025,
    batch_size: int = 50,
) -> dict[str, Any]:
    """Pipeline complet de Model Recovery (4x100 jeux de données, BIC/WAIC, pxp Rigoux 2014)."""
    rng = np.random.default_rng(seed)
    n_models = len(MODEL_NAMES)

    waic_confusion = np.zeros((n_models, n_models), dtype=np.float64)
    bic_confusion = np.zeros((n_models, n_models), dtype=np.float64)
    pxp_matrix = np.zeros((n_models, n_models), dtype=np.float64)
    pxp_waic = np.zeros((n_models, n_models), dtype=np.float64)
    bor_by_true_model: dict[str, float] = {}
    mean_waic_matrix = np.zeros((n_models, n_models), dtype=np.float64)
    mean_bic_matrix = np.zeros((n_models, n_models), dtype=np.float64)

    all_datasets_by_true: list[list[RecoveryDataset]] = []
    for true_idx, true_name in enumerate(MODEL_NAMES):
        ds_list = [
            simulate_dataset_for_model(
                true_name,
                _sample_model_params(true_name, rng),
                num_trials=num_trials,
                seed=seed + true_idx * 10_000 + i,
            )
            for i in range(num_datasets_per_model)
        ]
        all_datasets_by_true.append(ds_list)

    flat_datasets = [d for group in all_datasets_by_true for d in group]
    waic_all = np.zeros((len(flat_datasets), n_models), dtype=np.float64)
    bic_all = np.zeros((len(flat_datasets), n_models), dtype=np.float64)

    for fit_idx, fit_name in enumerate(MODEL_NAMES):
        fits = batch_invert_svi(
            fit_name,
            flat_datasets,
            seed=seed + 100_000 + fit_idx * 1000,
            num_steps=num_steps,
            num_posterior_samples=num_posterior_samples,
            lr=lr,
            batch_size=batch_size,
        )
        for g_i, f_res in enumerate(fits):
            waic_all[g_i, fit_idx] = f_res["waic"]
            bic_all[g_i, fit_idx] = f_res["bic"]

    for true_idx, true_name in enumerate(MODEL_NAMES):
        sl = slice(true_idx * num_datasets_per_model, (true_idx + 1) * num_datasets_per_model)
        waic_cols = waic_all[sl, :]
        bic_cols = bic_all[sl, :]

        mean_waic_matrix[true_idx, :] = np.mean(waic_cols, axis=0)
        mean_bic_matrix[true_idx, :] = np.mean(bic_cols, axis=0)

        win_w = np.argmin(waic_cols, axis=1)
        win_b = np.argmin(bic_cols, axis=1)
        for fit_idx in range(n_models):
            waic_confusion[true_idx, fit_idx] = float(np.mean(win_w == fit_idx))
            bic_confusion[true_idx, fit_idx] = float(np.mean(win_b == fit_idx))

        # Log-évidence principale basée sur -0.5 * BIC (et export complémentaire WAIC)
        bms_bic = compute_protected_exceedance_probability(
            -0.5 * bic_cols,
            seed=seed + 200_000 + true_idx,
        )
        bms_waic = compute_protected_exceedance_probability(
            -0.5 * waic_cols,
            seed=seed + 300_000 + true_idx,
        )
        pxp_matrix[true_idx, :] = bms_bic["pxp"]
        pxp_waic[true_idx, :] = bms_waic["pxp"]
        bor_by_true_model[true_name] = float(bms_bic["bor"])

    return {
        "model_names": MODEL_NAMES,
        "num_datasets_per_model": num_datasets_per_model,
        "num_trials": num_trials,
        "waic_confusion": waic_confusion,
        "bic_confusion": bic_confusion,
        "pxp_matrix": pxp_matrix,
        "pxp_waic": pxp_waic,
        "bor_by_true_model": bor_by_true_model,
        "mean_waic_matrix": mean_waic_matrix,
        "mean_bic_matrix": mean_bic_matrix,
    }


__all__ = [
    "MODEL_NAMES",
    "MODEL_PARAM_COUNTS",
    "RecoveryDataset",
    "THETA_NAMES",
    "batch_invert_svi",
    "build_numpyro_model",
    "build_recovery_schedule",
    "compute_protected_exceedance_probability",
    "compute_sensory_calm_sequence",
    "compute_waic_and_bic",
    "invert_dataset_nuts",
    "invert_dataset_svi",
    "run_model_recovery",
    "run_parameter_recovery",
    "sample_true_parameters",
    "simulate_dataset_for_model",
]
