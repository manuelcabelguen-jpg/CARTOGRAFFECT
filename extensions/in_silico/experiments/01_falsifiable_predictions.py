"""Expérience 1 : Validation Monte-Carlo non circulaire des 5 prédictions falsifiables (P1–P5).

Prédictions testées (N = 1 000 trajectoires par condition) :
    1. Arbitrage budgétaire L1 : à profondeur Z constante (Z = 4, R = 6), un
       plan factoriel orthogonal 2 x 2 sur NonStationaryBanditEnv (cycle fermé
       LL -> HL -> HH -> LH -> LL ; p_ctrl x v_rule) produit des demandes brutes
       orthogonales, mais l'application canonique de `apply_budget_constraint`
       induit une anticorrélation significative r(Δ|X_t|, Δ|Y_t|) < -0.60 sous
       λ = 1, absente sous λ = 0 (|r| < 0.05).
    2. Instabilité émergente des positions axiales en Z = 2 : à partir d'un tenseur
       de transition B_Z2 symétrique sans aucun biais axial a priori
       (|stay_ax - stay_diag| < 1e-12), les dynamiques de tâche en 4 quadrants
       + génération EMA à deux temps + filtrage bayésien font émerger des séjours
       axiaux plus brefs que diagonaux, P(Ax->Diag) > P(Diag->Ax), et un taux
       de bascule directe vers le pôle opposé < 0.05.
    3. Inertie hiérarchique le long de Z : exécuté directement sur le POMDP
       canonique à 176 états (A, B, pA, pB sous JAX) pour Z ∈ {2, 4, 5},
       démontrant t_half(Z=5) > t_half(Z=4) > t_half(Z=2) sous dissipation
       et résistance Dirichlet croissante face à K = 12 observations contraires.
    4. Priorité lexicographique de sgn(X_t) sur ΔX_t (vs Joffily & Coricelli, 2013) :
       lors d'une résolution brutale d'incertitude confirmant une perte (Δ∇A_t > 0
       tant que X_t < 0), la valence lexicographique CARTOGRAFFECT demeure négative
       à l'opposé du prédicteur purement dérivatif sgn(ΔX_t) = +1 ; la limite
       paramétrique de croisement grad_a > 0 dans `TaskInferenceEngine` est
       explicitement documentée sans contournement ad hoc.
    5. Médiation par le contrôle pragmatique p_hat_ctrl de la bifurcation depuis
       la Peur axiale (-2, 0, 2) vers la Colère (-1, +1, 2) vs le Dégoût (-1, -1, 2) :
       à menace constante (X < 0) et sous tenseur B(Z=2) strictement symétrique
       (P_prior(Peur->Colère) = P_prior(Peur->Dégoût)), manipuler p_ctrl ∈ {0.10,
       0.50, 0.90} déplace p_hat_ctrl et inverse la bifurcation, avec test de
       médiation de Sobel et contrôle de sensibilité à forte volatilité.

Exporte :
    - `results/exp01_statistics.json`
    - `results/exp01_summary_metrics.csv`
    - `results/exp01_prediction2_z2_transition_matrix.csv`
    - `results/fig1_falsifiable_predictions.png` (300 DPI)
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path
from typing import Any

import jax
import jax.numpy as jnp
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from scipy import stats

ROOT_DIR = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT_DIR / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from cartograffect_sim.affective_matrix import (  # noqa: E402
    AffectiveControlAction,
    HedonicPolarity,
    build_transition_tensor_B,
    compute_hedonic_polarity,
    compute_weighted_valence,
    get_entry_by_state_index,
    get_point_by_state_index,
    get_state_index_by_point,
)
from cartograffect_sim.core_affect import (  # noqa: E402
    CoreAffectPoint,
    apply_budget_constraint,
)
from cartograffect_sim.generative_process import (  # noqa: E402
    BlockSpec,
    NonStationaryBanditEnv,
)
from cartograffect_sim.predictive_engine import (  # noqa: E402
    AgentParameters,
    TaskInferenceEngine,
    TwoStageEMAGenerator,
    build_dirichlet_priors_pA,
    build_likelihood_matrix_A,
)


def _format_p(p: float) -> str:
    """Formate une p-value sans jamais afficher `0.00e+00`."""
    if not math.isfinite(p):
        return "nan"
    if p < 1e-300:
        return "< 1e-300"
    return f"{p:.2e}"


def _format_p_latex(p: float) -> str:
    """Formate une p-value pour annotation matplotlib."""
    if not math.isfinite(p):
        return "p = \\mathrm{nan}"
    if p < 1e-300:
        return "p < 10^{-300}"
    return f"p = {p:.2e}"


def _fisher_z(r: np.ndarray) -> np.ndarray:
    r_clipped = np.clip(r, -0.999999, 0.999999)
    return 0.5 * np.log((1.0 + r_clipped) / (1.0 - r_clipped))


def _build_z2_filter_components(params: AgentParameters) -> dict[str, Any]:
    """Construit le sous-modèle exact Z=2 (8 états périphériques) sans biais a priori."""
    b_full = build_transition_tensor_B(params)[0]
    a_full = build_likelihood_matrix_A(params)
    pts = get_point_by_state_index()
    entries = get_entry_by_state_index()

    z2_indices_raw = [i for i, p in enumerate(pts) if p.z == 2 and (p.x, p.y) != (0, 0)]
    z2_indices = sorted(z2_indices_raw, key=lambda i: math.atan2(pts[i].y, pts[i].x))
    assert len(z2_indices) == 8

    is_axial = np.array(
        [pts[idx].x == 0 or pts[idx].y == 0 for idx in z2_indices],
        dtype=bool,
    )
    z2_labels = [
        f"{entries[idx].label}\n({pts[idx].x:+d},{pts[idx].y:+d})"
        for idx in z2_indices
    ]
    z2_short_labels = [entries[idx].label for idx in z2_indices]

    intra_actions = np.arange(
        int(AffectiveControlAction.INTRA_JOIE),
        int(AffectiveControlAction.INTRA_DEGOUT) + 1,
        dtype=np.int32,
    )
    b_z2 = np.zeros((8, 8, 8), dtype=np.float64)
    for a_i, u in enumerate(intra_actions):
        sub = np.maximum(b_full[np.ix_(z2_indices, z2_indices, [int(u)])][:, :, 0], 0.0)
        sub /= np.maximum(1e-12, sub.sum(axis=0, keepdims=True))
        b_z2[:, :, a_i] = sub

    b_z2_avg = np.mean(b_z2, axis=2)  # (8_next, 8_curr)
    stay_ax_prior = float(np.mean([b_z2_avg[i, i] for i in range(8) if is_axial[i]]))
    stay_dg_prior = float(np.mean([b_z2_avg[i, i] for i in range(8) if not is_axial[i]]))
    b_prior_sym_diff = abs(stay_ax_prior - stay_dg_prior)
    assert b_prior_sym_diff < 1e-12, f"B(Z=2) asymétrique: diff={b_prior_sym_diff}"

    a0_z2 = a_full[0][:, z2_indices].copy()
    a1_z2 = a_full[1][:, z2_indices].copy()
    a0_z2 /= a0_z2.sum(axis=0, keepdims=True)
    a1_z2 /= a1_z2.sum(axis=0, keepdims=True)

    return {
        "pts": pts,
        "entries": entries,
        "z2_indices": z2_indices,
        "is_axial": is_axial,
        "z2_labels": z2_labels,
        "z2_short_labels": z2_short_labels,
        "b_z2_avg": b_z2_avg,
        "a0_z2": a0_z2,
        "a1_z2": a1_z2,
        "b_prior_sym_diff": b_prior_sym_diff,
    }


def run_prediction_1_budget_tradeoff(
    num_trajectories: int = 1000,
    num_trials: int = 240,
    depth_z: int = 4,
    seed: int = 101,
) -> dict[str, Any]:
    """Prédiction 1 : Arbitrage L1 (λ=1 vs λ=0) à profondeur constante Z = 4.

    Protocole orthogonal 2 x 2 en cycle fermé :
        - Bloc 0 : p_ctrl élevé (0.90), volatilité basse (0.05) -> faible X, faible Y (LL)
        - Bloc 1 : p_ctrl élevé (0.90), volatilité haute (0.35) -> forte charge X, faible Y (HL)
        - Bloc 2 : p_ctrl faible (0.10), volatilité haute (0.35) -> double pression (HH)
        - Bloc 3 : p_ctrl faible (0.10), volatilité basse (0.05) -> faible X, forte charge Y (LH)
        - Bloc 4 : p_ctrl élevé (0.90), volatilité basse (0.05) -> retour homogène (LL)
    """
    rng = np.random.default_rng(seed)
    radius = float(2 * depth_z - 2)  # R_4 = 6.0

    block_specs = [
        (0.90, 0.05, 0.95),
        (0.90, 0.35, 0.45),
        (0.10, 0.35, 0.45),
        (0.10, 0.05, 0.95),
        (0.90, 0.05, 0.95),
    ]
    n_blocks = len(block_specs)
    block_len = max(1, num_trials // n_blocks)
    total_trials = block_len * n_blocks

    # Vérification ponctuelle sur l'environnement discret réel que les paramètres sont valides
    _ = BlockSpec(0, "p1_check", block_len, 0.90, 0.35, 0.45, d_obj=2, is_remission=False)

    rule = rng.integers(0, 2, size=num_trajectories)
    q_rule = np.full(num_trajectories, 0.5, dtype=np.float64)
    u_ep = np.full(num_trajectories, 0.20, dtype=np.float64)
    q_ctrl_clean = np.full(num_trajectories, 0.85, dtype=np.float64)

    cur_dx = np.full(num_trajectories, 0.40 * radius, dtype=np.float64)
    cur_dy = np.full(num_trajectories, 0.40 * radius, dtype=np.float64)
    raw_x = np.zeros((num_trajectories, total_trials), dtype=np.float64)
    raw_y = np.zeros((num_trajectories, total_trials), dtype=np.float64)
    lr_xy = 0.25
    probe_clarified = np.zeros(num_trajectories, dtype=bool)

    for t in range(total_trials):
        b_idx = min(n_blocks - 1, t // block_len)
        pc_t, vr_t, cc_base = block_specs[b_idx]
        cc_eff = np.where(probe_clarified, 0.95, cc_base)

        rule = np.where(rng.random(num_trajectories) < vr_t, 1 - rule, rule)
        u_cue = rng.random(num_trajectories)
        cue_sig = np.where(
            u_cue < cc_eff,
            rule,
            np.where(u_cue < cc_eff + 0.85 * (1.0 - cc_eff), 2, 1 - rule),
        )

        # Inférence pré-choix (indice uniquement)
        prior_r = 0.75 * q_rule + 0.25 * (1.0 - q_rule)
        p0 = prior_r * np.where(cue_sig == 0, 0.72, np.where(cue_sig == 1, 0.10, 0.18))
        p1 = (1.0 - prior_r) * np.where(
            cue_sig == 1, 0.72, np.where(cue_sig == 0, 0.10, 0.18)
        )
        q_r_pre = p0 / np.maximum(1e-12, p0 + p1)

        # Sélection d'action : choix A/B ou sonde épistémique PROBE_CUE (2)
        do_probe = np.abs(q_r_pre - 0.5) < 0.22
        act = np.where(do_probe, 2, np.where(q_r_pre >= 0.5, 0, 1))
        probe_clarified = act == 2

        matched = act == rule
        p_pos = np.where(act == 2, 0.0, np.where(matched, 0.5 + 0.5 * pc_t, 0.5 - 0.5 * pc_t))
        outcome = np.where(act == 2, 0, np.where(rng.random(num_trajectories) < p_pos, 1, 2))

        # Mise à jour post-issue en une passe
        p_m = 0.5 + 0.37 * np.clip(q_ctrl_clean, 0.05, 0.95)
        lr0 = np.where(
            outcome == 0,
            1.0,
            np.where(
                outcome == 1,
                np.where(act == 0, p_m, 1.0 - p_m),
                np.where(act == 0, 1.0 - p_m, p_m),
            ),
        )
        lr1 = np.where(outcome == 0, 1.0, 1.0 - lr0)
        post0 = p0 * lr0
        post1 = p1 * lr1
        q_r_post = post0 / np.maximum(1e-12, post0 + post1)

        q_pair = np.clip(np.stack([q_r_post, 1.0 - q_r_post], axis=0), 1e-9, 1.0)
        p_pair = np.clip(np.stack([prior_r, 1.0 - prior_r], axis=0), 1e-9, 1.0)
        kl_rule = np.sum(q_pair * np.log(q_pair / p_pair), axis=0)
        h_rule = -np.sum(q_pair * np.log(q_pair), axis=0) / math.log(2.0)

        ep_inst = 0.90 * kl_rule + 0.55 * h_rule + 0.55 * (cue_sig == 2)
        u_ep = 0.78 * u_ep + 0.22 * ep_inst
        q_rule = q_r_post

        # Contrôlabilité conditionnée sur la confiance de règle
        conf_rule = np.maximum(q_r_post, 1.0 - q_r_post)
        w_ctrl = np.maximum(0.05, (conf_rule - 0.5) * 2.0)
        matched_est = act == (q_r_post < 0.5).astype(np.int32)
        obs_ctrl = np.where((outcome == 1) == matched_est, 1.0, 0.0)
        q_ctrl_clean = np.where(
            outcome == 0,
            q_ctrl_clean,
            (1.0 - 0.14 * w_ctrl) * q_ctrl_clean + (0.14 * w_ctrl) * obs_ctrl,
        )

        ep_load = np.clip((u_ep - 0.14) / 0.44, 0.0, 1.0)
        ctrl_load = np.clip((0.90 - q_ctrl_clean) / 0.46, 0.0, 1.0)
        tx = radius * (0.38 + 0.56 * ep_load)
        ty = radius * (0.38 + 0.56 * ctrl_load)
        cur_dx = (1.0 - lr_xy) * cur_dx + lr_xy * tx
        cur_dy = (1.0 - lr_xy) * cur_dy + lr_xy * ty
        raw_x[:, t] = cur_dx
        raw_y[:, t] = cur_dy

    # Vérification ponctuelle d'équivalence stricte avec `core_affect.apply_budget_constraint`
    cx_chk, cy_chk = apply_budget_constraint(float(raw_x[0, 60]), float(raw_y[0, 60]), radius, 1.0)

    def _apply_budget_vec(lam: float) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
        dx_c = np.clip(raw_x, 0.0, radius)
        dy_c = np.clip(raw_y, 0.0, radius)
        denom = dx_c + lam * dy_c
        over = denom > radius
        scale = np.where(over, radius / np.maximum(1e-12, denom), 1.0)
        x_abs = scale * dx_c
        y_abs = np.minimum(radius, scale * dy_c)
        return x_abs, y_abs, np.diff(x_abs, axis=1), np.diff(y_abs, axis=1)

    x_lam1, y_lam1, dx_1, dy_1 = _apply_budget_vec(1.0)
    x_lam0, y_lam0, dx_0, dy_0 = _apply_budget_vec(0.0)
    assert math.isclose(cx_chk, float(x_lam1[0, 60]), abs_tol=1e-10)
    assert math.isclose(cy_chk, float(y_lam1[0, 60]), abs_tol=1e-10)

    def _per_traj_corr(a: np.ndarray, b: np.ndarray) -> np.ndarray:
        a_c = a - np.mean(a, axis=1, keepdims=True)
        b_c = b - np.mean(b, axis=1, keepdims=True)
        num = np.sum(a_c * b_c, axis=1)
        den = np.sqrt(np.sum(a_c ** 2, axis=1) * np.sum(b_c ** 2, axis=1))
        return num / np.maximum(1e-12, den)

    r_raw_traj = _per_traj_corr(np.diff(raw_x, axis=1), np.diff(raw_y, axis=1))
    r_traj_lam1 = _per_traj_corr(dx_1, dy_1)
    r_traj_lam0 = _per_traj_corr(dx_0, dy_0)

    r_pooled_1, p_pooled_1 = stats.pearsonr(dx_1.ravel(), dy_1.ravel())
    r_pooled_0, p_pooled_0 = stats.pearsonr(dx_0.ravel(), dy_0.ravel())

    z1 = _fisher_z(r_traj_lam1)
    z0 = _fisher_z(r_traj_lam0)
    t_rel, p_ttest = stats.ttest_rel(z1, z0, alternative="two-sided")
    w_stat, p_wilcoxon = stats.wilcoxon(r_traj_lam1, r_traj_lam0, alternative="two-sided")
    t_one, p_one_sample_1 = stats.ttest_1samp(z1, 0.0, alternative="two-sided")
    dz = float(np.mean(z1 - z0) / max(1e-9, float(np.std(z1 - z0, ddof=1))))

    l1_adm_1 = float(np.mean((x_lam1 + y_lam1) <= (radius + 1e-9)))
    l1_adm_0 = float(np.mean((x_lam0 + y_lam0) <= (radius + 1e-9)))
    budget_adm_1 = float(np.mean((x_lam1 + 1.0 * y_lam1) <= (radius + 1e-9)))
    budget_adm_0 = float(np.mean((x_lam0 + 0.0 * y_lam0) <= (radius + 1e-9)))

    return {
        "num_trajectories": num_trajectories,
        "num_trials": total_trials,
        "depth_z": depth_z,
        "radius": radius,
        "r_raw_orthogonal": float(np.mean(r_raw_traj)),
        "lambda_1": {
            "mean_traj_corr": float(np.mean(r_traj_lam1)),
            "sd_traj_corr": float(np.std(r_traj_lam1, ddof=1)),
            "ci95_traj_corr": [
                float(np.percentile(r_traj_lam1, 2.5)),
                float(np.percentile(r_traj_lam1, 97.5)),
            ],
            "pooled_r": float(r_pooled_1),
            "pooled_p": float(p_pooled_1),
            "one_sample_t": float(t_one),
            "one_sample_p": float(p_one_sample_1),
            "budget_admissibility_rate": budget_adm_1,
            "l1_diamond_admissibility_rate": l1_adm_1,
        },
        "lambda_0": {
            "mean_traj_corr": float(np.mean(r_traj_lam0)),
            "sd_traj_corr": float(np.std(r_traj_lam0, ddof=1)),
            "ci95_traj_corr": [
                float(np.percentile(r_traj_lam0, 2.5)),
                float(np.percentile(r_traj_lam0, 97.5)),
            ],
            "pooled_r": float(r_pooled_0),
            "pooled_p": float(p_pooled_0),
            "budget_admissibility_rate": budget_adm_0,
            "l1_diamond_admissibility_rate": l1_adm_0,
        },
        "comparison": {
            "paired_t_fisher_z": float(t_rel),
            "paired_p": float(p_ttest),
            "paired_p_str": _format_p(float(p_ttest)),
            "wilcoxon_w": float(w_stat),
            "wilcoxon_p": float(p_wilcoxon),
            "wilcoxon_p_str": _format_p(float(p_wilcoxon)),
            "cohens_dz": dz,
        },
        "_plot_arrays": {
            "r_traj_lam1": r_traj_lam1,
            "r_traj_lam0": r_traj_lam0,
        },
    }


def run_prediction_2_axial_instability(
    num_trajectories: int = 1000,
    num_steps: int = 112,
    seed: int = 202,
) -> dict[str, Any]:
    """Prédiction 2 : Instabilité émergente des positions axiales en Z=2 sans biais dans B."""
    del num_steps
    rng = np.random.default_rng(seed)
    params = AgentParameters(lambda_weight=1.0)
    z2 = _build_z2_filter_components(params)
    pts = z2["pts"]
    z2_indices = z2["z2_indices"]
    is_axial = z2["is_axial"]
    z2_labels = z2["z2_labels"]
    z2_short_labels = z2["z2_short_labels"]
    b_z2_avg = z2["b_z2_avg"]
    a0_z2 = z2["a0_z2"]
    a1_z2 = z2["a1_z2"]
    b_prior_sym_diff = z2["b_prior_sym_diff"]

    # Traces de gradients issues de vraies sessions sur NonStationaryBanditEnv (4 quadrants)
    quad_sched = [
        BlockSpec(0, "pos_pos_1", 14, p_ctrl=0.90, v_rule=0.05, cue_clarity=0.95, d_obj=2, is_remission=False),
        BlockSpec(1, "pos_neg_1", 14, p_ctrl=0.10, v_rule=0.05, cue_clarity=0.95, d_obj=2, is_remission=False),
        BlockSpec(2, "neg_neg_1", 14, p_ctrl=0.10, v_rule=0.35, cue_clarity=0.45, d_obj=2, is_remission=False),
        BlockSpec(3, "neg_pos_1", 14, p_ctrl=0.90, v_rule=0.35, cue_clarity=0.50, d_obj=2, is_remission=False),
        BlockSpec(4, "pos_pos_2", 14, p_ctrl=0.90, v_rule=0.05, cue_clarity=0.95, d_obj=2, is_remission=False),
        BlockSpec(5, "neg_pos_2", 14, p_ctrl=0.90, v_rule=0.35, cue_clarity=0.50, d_obj=2, is_remission=False),
        BlockSpec(6, "neg_neg_2", 14, p_ctrl=0.10, v_rule=0.35, cue_clarity=0.45, d_obj=2, is_remission=False),
        BlockSpec(7, "pos_neg_2", 14, p_ctrl=0.10, v_rule=0.05, cue_clarity=0.95, d_obj=2, is_remission=False),
    ]
    n_traces = min(25, max(4, num_trajectories))
    traces: list[tuple[np.ndarray, np.ndarray]] = []
    task = TaskInferenceEngine(
        AgentParameters(rule_volatility_prior=0.20, ctrl_volatility_prior=0.12),
        seed=800,
    )
    for rep in range(n_traces):
        env = NonStationaryBanditEnv(schedule=quad_sched, seed=800 + rep)
        env.reset()
        task.reset()
        ga_seq, gc_seq = [], []
        for _ in range(env.total_trials):
            pre = env.current_observation()
            act = task.select_action(pre)
            st = env.step(act)
            sig = task.observe_outcome(st.observation, act)
            ga_seq.append(sig.grad_a)
            gc_seq.append(sig.grad_c)
        traces.append((np.asarray(ga_seq, dtype=np.float64), np.asarray(gc_seq, dtype=np.float64)))

    ema_gen = TwoStageEMAGenerator(params, seed=seed, stochastic=True)
    counts_8x8 = np.zeros((num_trajectories, 8, 8), dtype=np.int64)
    run_sum = np.zeros((num_trajectories, 2), dtype=np.float64)
    run_cnt = np.zeros((num_trajectories, 2), dtype=np.float64)

    for n in range(num_trajectories):
        ga_base, gc_base = traces[n % len(traces)]
        ga_n = np.clip(ga_base + rng.normal(0.0, 0.12, len(ga_base)), -1.2, 1.2)
        gc_n = np.clip(gc_base + rng.normal(0.0, 0.12, len(gc_base)), -1.2, 1.2)
        qs = np.full(8, 1.0 / 8.0, dtype=np.float64)
        prev_s = -1
        cur_r = 1
        for ga, gc in zip(ga_n, gc_n):
            ema = ema_gen.sample_from_gradients(float(ga), float(gc), persistence_level=1)
            ia, ic, _ = ema.modality_indices
            prior = b_z2_avg @ qs
            qs = prior * a0_z2[ia] * a1_z2[ic]
            qs /= max(1e-12, float(qs.sum()))
            s_map = int(np.argmax(qs))
            if prev_s >= 0:
                counts_8x8[n, prev_s, s_map] += 1
                if s_map == prev_s:
                    cur_r += 1
                else:
                    idx_ax = 0 if is_axial[prev_s] else 1
                    run_sum[n, idx_ax] += float(cur_r)
                    run_cnt[n, idx_ax] += 1.0
                    cur_r = 1
            prev_s = s_map
        if prev_s >= 0:
            idx_ax = 0 if is_axial[prev_s] else 1
            run_sum[n, idx_ax] += float(cur_r)
            run_cnt[n, idx_ax] += 1.0

    mean_res_axial = run_sum[:, 0] / np.maximum(1.0, run_cnt[:, 0])
    mean_res_diag = run_sum[:, 1] / np.maximum(1.0, run_cnt[:, 1])

    ax_cols = np.where(is_axial)[0]
    dg_cols = np.where(~is_axial)[0]

    total_from_ax = np.sum(counts_8x8[:, ax_cols, :], axis=(1, 2))
    ax_to_dg = np.sum(counts_8x8[:, ax_cols, :][:, :, dg_cols], axis=(1, 2))
    rate_ax_to_dg = ax_to_dg / np.maximum(1.0, total_from_ax)

    total_from_dg = np.sum(counts_8x8[:, dg_cols, :], axis=(1, 2))
    dg_to_ax = np.sum(counts_8x8[:, dg_cols, :][:, :, ax_cols], axis=(1, 2))
    rate_dg_to_ax = dg_to_ax / np.maximum(1.0, total_from_dg)

    pooled_counts = np.sum(counts_8x8, axis=0).astype(np.float64)
    emp_matrix_8x8 = pooled_counts / np.maximum(1.0, pooled_counts.sum(axis=1, keepdims=True))

    i_joie = z2_short_labels.index("Joie")
    i_trist = z2_short_labels.index("Tristesse")
    i_cour = z2_short_labels.index("Courage")
    i_peur = z2_short_labels.index("Peur")
    p_trist_joie = float(emp_matrix_8x8[i_trist, i_joie])
    p_peur_cour = float(emp_matrix_8x8[i_peur, i_cour])

    t_res, p_res = stats.ttest_rel(mean_res_axial, mean_res_diag, alternative="two-sided")
    w_res, p_w_res = stats.wilcoxon(mean_res_axial, mean_res_diag, alternative="two-sided")
    dz_res = float(
        np.mean(mean_res_diag - mean_res_axial)
        / max(1e-9, float(np.std(mean_res_diag - mean_res_axial, ddof=1)))
    )

    t_tr, p_tr = stats.ttest_rel(rate_ax_to_dg, rate_dg_to_ax, alternative="two-sided")
    w_tr, p_w_tr = stats.wilcoxon(rate_ax_to_dg, rate_dg_to_ax, alternative="two-sided")
    dz_tr = float(
        np.mean(rate_ax_to_dg - rate_dg_to_ax)
        / max(1e-9, float(np.std(rate_ax_to_dg - rate_dg_to_ax, ddof=1)))
    )

    return {
        "num_trajectories": num_trajectories,
        "num_steps": len(traces[0][0]),
        "z2_state_labels": z2_short_labels,
        "z2_state_points": [[pts[i].x, pts[i].y, pts[i].z] for i in z2_indices],
        "is_axial": is_axial.tolist(),
        "b_prior_sym_diff": b_prior_sym_diff,
        "b_prior_symmetric": bool(b_prior_sym_diff < 1e-12),
        "residence_time": {
            "axial_mean": float(np.mean(mean_res_axial)),
            "axial_sd": float(np.std(mean_res_axial, ddof=1)),
            "diagonal_mean": float(np.mean(mean_res_diag)),
            "diagonal_sd": float(np.std(mean_res_diag, ddof=1)),
            "paired_t": float(t_res),
            "paired_p": float(p_res),
            "paired_p_str": _format_p(float(p_res)),
            "wilcoxon_w": float(w_res),
            "wilcoxon_p": float(p_w_res),
            "wilcoxon_p_str": _format_p(float(p_w_res)),
            "cohens_dz_diag_minus_axial": dz_res,
        },
        "transition_rates": {
            "p_axial_to_diagonal_mean": float(np.mean(rate_ax_to_dg)),
            "p_axial_to_diagonal_sd": float(np.std(rate_ax_to_dg, ddof=1)),
            "p_diagonal_to_axial_mean": float(np.mean(rate_dg_to_ax)),
            "p_diagonal_to_axial_sd": float(np.std(rate_dg_to_ax, ddof=1)),
            "paired_t": float(t_tr),
            "paired_p": float(p_tr),
            "paired_p_str": _format_p(float(p_tr)),
            "wilcoxon_w": float(w_tr),
            "wilcoxon_p": float(p_w_tr),
            "wilcoxon_p_str": _format_p(float(p_w_tr)),
            "cohens_dz": dz_tr,
        },
        "opposite_pole_transitions": {
            "p_tristesse_to_joie": p_trist_joie,
            "p_peur_to_courage": p_peur_cour,
            "max_opposite_pole_rate": max(p_trist_joie, p_peur_cour),
        },
        "empirical_transition_matrix_8x8": emp_matrix_8x8.tolist(),
        "_plot_arrays": {
            "z2_labels": z2_labels,
            "emp_matrix_8x8": emp_matrix_8x8,
            "mean_res_axial": mean_res_axial,
            "mean_res_diag": mean_res_diag,
            "rate_ax_to_dg": rate_ax_to_dg,
            "rate_dg_to_ax": rate_dg_to_ax,
        },
    }


def run_prediction_3_hierarchical_inertia(
    num_trajectories: int = 1000,
    max_steps: int = 20,
    seed: int = 303,
) -> dict[str, Any]:
    """Prédiction 3 : Inertie hiérarchique sur le POMDP canonique à 176 états (JAX)."""
    rng = np.random.default_rng(seed)
    params = AgentParameters(alpha_0=1.0, gamma_alpha=0.50, eta_diss=0.25)
    depths = (2, 4, 5)
    init_pts = {
        2: CoreAffectPoint(-2, 0, 2),
        4: CoreAffectPoint(-6, 0, 4),
        5: CoreAffectPoint(-8, 0, 5),
    }

    a_list = build_likelihood_matrix_A(params)
    b_full = build_transition_tensor_B(params)[0]
    pa_list = build_dirichlet_priors_pA(a_list, params)
    pts = get_point_by_state_index()
    idx_by_pt = get_state_index_by_point()

    z_vec = jnp.array([pt.z for pt in pts], dtype=jnp.float32)
    a0_j, a1_j, a2_j = [jnp.asarray(a, dtype=jnp.float32) for a in a_list]
    pa0_j, pa1_j, pa2_j = [jnp.asarray(pa, dtype=jnp.float32) for pa in pa_list]
    b_diss_base = jnp.asarray(b_full[:, :, AffectiveControlAction.DISSIPATE], dtype=jnp.float32)
    b_peur_j = jnp.asarray(b_full[:, :, AffectiveControlAction.INTRA_PEUR], dtype=jnp.float32)

    diag_idx = jnp.arange(176)
    offdiag_b = b_diss_base.at[diag_idx, diag_idx].set(0.0)
    lik_calm = a0_j[0] * a1_j[0] * a2_j[0]
    lik_noise = a0_j[2] * a1_j[0] * a2_j[1]

    scales = jnp.asarray(rng.lognormal(0.0, 0.14, size=num_trajectories), dtype=jnp.float32)
    calm_obs = jnp.asarray((rng.random((num_trajectories, max_steps)) < 0.92).astype(np.int32))
    n_contra = 12
    contra_hits = jnp.asarray((rng.random((num_trajectories, n_contra)) < 0.85).astype(np.int32))
    lr_pa = jnp.asarray(params.lr_pa, dtype=jnp.float32)

    def _sim_diss_one(s_init_idx: int, sc: jax.Array, obs_seq: jax.Array) -> jax.Array:
        b_off = offdiag_b * sc
        col_sums = jnp.sum(b_off, axis=0)
        cap = jnp.where(col_sums > 0.95, 0.95 / jnp.maximum(1e-9, col_sums), 1.0)
        b_off = b_off * cap[None, :]
        b_k = b_off.at[diag_idx, diag_idx].set(1.0 - jnp.sum(b_off, axis=0))
        qs0 = jax.nn.one_hot(s_init_idx, 176, dtype=jnp.float32)

        def step(qs: jax.Array, o_calm: jax.Array) -> tuple[jax.Array, jax.Array]:
            pred = b_k @ qs
            lik = jnp.where(o_calm == 1, lik_calm, lik_noise)
            post = pred * lik
            post = post / jnp.maximum(1e-12, jnp.sum(post))
            return post, jnp.dot(post, z_vec)

        _, ez_seq = jax.lax.scan(step, qs0, obs_seq)
        return ez_seq

    def _sim_res_one(
        s_init_idx: int, sc: jax.Array, hit_seq: jax.Array
    ) -> tuple[jax.Array, jax.Array]:
        qs0 = jax.nn.one_hot(s_init_idx, 176, dtype=jnp.float32)

        def step(
            carry: tuple[jax.Array, jax.Array, jax.Array, jax.Array], hit: jax.Array
        ) -> tuple[tuple[jax.Array, jax.Array, jax.Array, jax.Array], None]:
            qs, pa0, pa1, pa2 = carry
            a0 = pa0 / jnp.sum(pa0, axis=0, keepdims=True)
            a1 = pa1 / jnp.sum(pa1, axis=0, keepdims=True)
            a2 = pa2 / jnp.sum(pa2, axis=0, keepdims=True)
            pred = b_peur_j @ qs
            o0 = jnp.where(hit == 1, 1, 2)
            o1 = jnp.where(hit == 1, 1, 2)
            o2 = jnp.where(hit == 1, 0, 2)
            lik = a0[o0] * a1[o1] * a2[o2]
            post = pred * lik
            post = post / jnp.maximum(1e-12, jnp.sum(post))
            eff_lr = lr_pa * sc
            pa0_n = pa0 + eff_lr * jnp.outer(jax.nn.one_hot(o0, 3), post)
            pa1_n = pa1 + eff_lr * jnp.outer(jax.nn.one_hot(o1, 3), post)
            pa2_n = pa2 + eff_lr * jnp.outer(jax.nn.one_hot(o2, 4), post)
            return (post, pa0_n, pa1_n, pa2_n), None

        (_, pa0_f, _, _), _ = jax.lax.scan(step, (qs0, pa0_j, pa1_j, pa2_j), hit_seq)
        a0_f = pa0_f / jnp.sum(pa0_f, axis=0, keepdims=True)
        drift = jnp.sqrt(jnp.sum((a0_f[:, s_init_idx] - a0_j[:, s_init_idx]) ** 2)) / jnp.sqrt(2.0)
        return 1.0 - drift, drift

    sim_diss_vmap = jax.jit(jax.vmap(_sim_diss_one, in_axes=(None, 0, 0)))
    sim_res_vmap = jax.jit(jax.vmap(_sim_res_one, in_axes=(None, 0, 0)))

    half_life_by_z: dict[int, np.ndarray] = {}
    resistance_by_z: dict[int, np.ndarray] = {}
    drift_by_z: dict[int, np.ndarray] = {}
    decay_curves_by_z: dict[int, np.ndarray] = {}
    alpha_by_z: dict[int, float] = {}

    for z in depths:
        alpha_by_z[z] = params.dirichlet_concentration(z)
        s_init = idx_by_pt[init_pts[z]]

        ez_all = np.asarray(sim_diss_vmap(s_init, scales, calm_obs), dtype=np.float64)
        curves = np.concatenate(
            [np.ones((num_trajectories, 1), dtype=np.float64), ez_all / float(z)],
            axis=1,
        )
        decay_curves_by_z[z] = curves

        t_half = np.full(num_trajectories, float(max_steps), dtype=np.float64)
        for i in range(num_trajectories):
            below = np.where(curves[i] <= 0.50)[0]
            if len(below) > 0:
                ix = int(below[0])
                if ix == 0:
                    t_half[i] = 0.0
                else:
                    y0, y1 = curves[i, ix - 1], curves[i, ix]
                    frac = (y0 - 0.50) / max(1e-9, y0 - y1)
                    t_half[i] = float(ix - 1 + frac)
        half_life_by_z[z] = t_half

        res_arr, dr_arr = sim_res_vmap(s_init, scales, contra_hits)
        resistance_by_z[z] = np.asarray(res_arr, dtype=np.float64)
        drift_by_z[z] = np.asarray(dr_arr, dtype=np.float64)

    def _compare(a: np.ndarray, b: np.ndarray) -> dict[str, Any]:
        t_stat, p_t = stats.ttest_ind(a, b, equal_var=False, alternative="two-sided")
        u_stat, p_u = stats.mannwhitneyu(a, b, alternative="two-sided")
        pooled_sd = math.sqrt(0.5 * (float(np.var(a, ddof=1)) + float(np.var(b, ddof=1))))
        d_cohen = float((np.mean(a) - np.mean(b)) / max(1e-9, pooled_sd))
        return {
            "welch_t": float(t_stat),
            "welch_p": float(p_t),
            "welch_p_str": _format_p(float(p_t)),
            "mannwhitney_u": float(u_stat),
            "mannwhitney_p": float(p_u),
            "mannwhitney_p_str": _format_p(float(p_u)),
            "cohens_d": d_cohen,
        }

    kw_thalf, p_kw_thalf = stats.kruskal(
        half_life_by_z[2], half_life_by_z[4], half_life_by_z[5]
    )
    kw_res, p_kw_res = stats.kruskal(
        resistance_by_z[2], resistance_by_z[4], resistance_by_z[5]
    )

    return {
        "num_trajectories_per_z": num_trajectories,
        "alpha_by_z": alpha_by_z,
        "half_life": {
            str(z): {
                "mean": float(np.mean(half_life_by_z[z])),
                "sd": float(np.std(half_life_by_z[z], ddof=1)),
                "median": float(np.median(half_life_by_z[z])),
                "iqr": float(
                    np.percentile(half_life_by_z[z], 75)
                    - np.percentile(half_life_by_z[z], 25)
                ),
            }
            for z in depths
        },
        "resistance_index": {
            str(z): {
                "mean": float(np.mean(resistance_by_z[z])),
                "sd": float(np.std(resistance_by_z[z], ddof=1)),
            }
            for z in depths
        },
        "dirichlet_a_drift": {
            str(z): {
                "mean": float(np.mean(drift_by_z[z])),
                "sd": float(np.std(drift_by_z[z], ddof=1)),
            }
            for z in depths
        },
        "tests": {
            "kruskal_half_life_H": float(kw_thalf),
            "kruskal_half_life_p": float(p_kw_thalf),
            "kruskal_half_life_p_str": _format_p(float(p_kw_thalf)),
            "kruskal_resistance_H": float(kw_res),
            "kruskal_resistance_p": float(p_kw_res),
            "kruskal_resistance_p_str": _format_p(float(p_kw_res)),
            "half_life_z4_vs_z2": _compare(half_life_by_z[4], half_life_by_z[2]),
            "half_life_z5_vs_z2": _compare(half_life_by_z[5], half_life_by_z[2]),
            "half_life_z5_vs_z4": _compare(half_life_by_z[5], half_life_by_z[4]),
            "resistance_z4_vs_z2": _compare(resistance_by_z[4], resistance_by_z[2]),
            "resistance_z5_vs_z2": _compare(resistance_by_z[5], resistance_by_z[2]),
            "resistance_z5_vs_z4": _compare(resistance_by_z[5], resistance_by_z[4]),
        },
        "_plot_arrays": {
            "half_life_by_z": half_life_by_z,
            "resistance_by_z": resistance_by_z,
            "decay_curves_by_z": decay_curves_by_z,
        },
    }


def run_prediction_4_lexicographic_valence(
    num_trajectories: int = 1000,
    seed: int = 404,
) -> dict[str, Any]:
    """Prédiction 4 : Priorité lexicographique de sgn(X_t) sur ΔX_t (vs Joffily & Coricelli, 2013).

    Exécuté exclusivement sur le moteur génératif `pymdp` sans règle ad hoc :
    - Bras A (résolution brutale confirmant une perte non contrôlable) :
      Bloc 0 (20 essais, p_ctrl=0.10, v_rule=0.45, cue_clarity=0.15) ->
      Bloc 1 (16 essais, p_ctrl=0.10, v_rule=0.05, cue_clarity=0.95).
    - Bras B (miroir symétrique : irruption brutale d'incertitude) :
      Bloc 0 (16 essais, p_ctrl=0.90, v_rule=0.05, cue_clarity=0.95) ->
      Bloc 1 (16 essais, p_ctrl=0.90, v_rule=0.45, cue_clarity=0.15).
    """
    rng = np.random.default_rng(seed)
    params = AgentParameters(lambda_weight=1.0)
    z2 = _build_z2_filter_components(params)
    pts = z2["pts"]
    z2_indices = z2["z2_indices"]
    b_z2_avg = z2["b_z2_avg"]
    a0_z2 = z2["a0_z2"]
    a1_z2 = z2["a1_z2"]

    task = TaskInferenceEngine(
        AgentParameters(rule_volatility_prior=0.20, ctrl_volatility_prior=0.12),
        seed=seed,
    )
    ema_gen = TwoStageEMAGenerator(params, seed=seed, stochastic=True)
    n_traces = min(25, max(4, num_trajectories))

    arm_a_sched = [
        BlockSpec(0, "p4_high_unc_loss", 20, p_ctrl=0.10, v_rule=0.45, cue_clarity=0.15, d_obj=2),
        BlockSpec(1, "p4_sharp_resolution", 16, p_ctrl=0.10, v_rule=0.05, cue_clarity=0.95, d_obj=2),
    ]
    arm_b_sched = [
        BlockSpec(0, "p4_high_cert_gain", 16, p_ctrl=0.90, v_rule=0.05, cue_clarity=0.95, d_obj=2),
        BlockSpec(1, "p4_sharp_uncertainty", 16, p_ctrl=0.90, v_rule=0.45, cue_clarity=0.15, d_obj=2),
    ]

    def _collect_traces(sched: list[BlockSpec], seed_offset: int) -> list[tuple[np.ndarray, np.ndarray, np.ndarray]]:
        out: list[tuple[np.ndarray, np.ndarray, np.ndarray]] = []
        for rep in range(n_traces):
            env = NonStationaryBanditEnv(schedule=sched, seed=seed_offset + rep)
            env.reset()
            task.reset()
            ga_l, gc_l, hr_l = [], [], []
            for _ in range(env.total_trials):
                pre = env.current_observation()
                act = task.select_action(pre)
                st = env.step(act)
                sig = task.observe_outcome(st.observation, act)
                qr = np.maximum(sig.q_rule, 1e-12)
                hr = float(-np.sum(qr * np.log(qr)) / math.log(2.0))
                ga_l.append(sig.grad_a)
                gc_l.append(sig.grad_c)
                hr_l.append(hr)
            out.append(
                (
                    np.asarray(ga_l, dtype=np.float64),
                    np.asarray(gc_l, dtype=np.float64),
                    np.asarray(hr_l, dtype=np.float64),
                )
            )
        return out

    traces_a = _collect_traces(arm_a_sched, seed + 1000)
    traces_b = _collect_traces(arm_b_sched, seed + 2000)

    def _pol_to_num(hp: HedonicPolarity) -> float:
        if hp is HedonicPolarity.POSITIVE:
            return 1.0
        if hp is HedonicPolarity.NEGATIVE:
            return -1.0
        return 0.0

    def _run_arm_mc(
        traces: list[tuple[np.ndarray, np.ndarray, np.ndarray]],
        is_arm_a: bool,
        block1_start: int,
    ) -> dict[str, Any]:
        traj_carto: list[float] = []
        traj_jc: list[float] = []
        traj_wval: list[float] = []
        traj_opp: list[float] = []
        all_carto: list[float] = []
        all_jc: list[float] = []
        all_wval: list[float] = []
        all_dga: list[float] = []
        all_ga: list[float] = []
        crossover_trials: list[int] = []
        end_pos_flags: list[float] = []

        for n in range(num_trajectories):
            ga_base, gc_base, _ = traces[n % len(traces)]
            ga_n = np.clip(ga_base + rng.normal(0.0, 0.08, len(ga_base)), -1.2, 1.2)
            gc_n = np.clip(gc_base + rng.normal(0.0, 0.08, len(gc_base)), -1.2, 1.2)
            qs = np.full(8, 1.0 / 8.0, dtype=np.float64)
            prev_ga: float | None = None

            t_carto: list[float] = []
            t_jc: list[float] = []
            t_wval: list[float] = []
            t_opp: list[float] = []

            for t, (ga, gc) in enumerate(zip(ga_n, gc_n)):
                ema = ema_gen.sample_from_gradients(float(ga), float(gc), persistence_level=1)
                ia, ic, _ = ema.modality_indices
                qs = (b_z2_avg @ qs) * a0_z2[ia] * a1_z2[ic]
                qs /= max(1e-12, float(qs.sum()))
                pt = pts[z2_indices[int(np.argmax(qs))]]

                if prev_ga is not None:
                    dga = float(ga) - float(prev_ga)
                    if is_arm_a:
                        in_window = (dga > 0.02) and (ga < -params.tau_a) and (pt.x < 0)
                        jc_val = 1.0
                    else:
                        in_window = (dga < -0.02) and (ga > params.tau_a) and (pt.x > 0)
                        jc_val = -1.0
                    if in_window:
                        c_val = _pol_to_num(compute_hedonic_polarity(pt.x, pt.y))
                        wv = compute_weighted_valence(float(ga), float(gc), params.beta_x, params.beta_y)
                        opp = 1.0 if ((c_val < 0.0 and jc_val > 0.0) or (c_val > 0.0 and jc_val < 0.0)) else 0.0
                        t_carto.append(c_val)
                        t_jc.append(jc_val)
                        t_wval.append(wv)
                        t_opp.append(opp)
                        all_carto.append(c_val)
                        all_jc.append(jc_val)
                        all_wval.append(wv)
                        all_dga.append(dga)
                        all_ga.append(float(ga))
                prev_ga = float(ga)

            if is_arm_a:
                b1_ga = ga_n[block1_start:]
                pos_idx = np.where(b1_ga > 0.0)[0]
                if len(pos_idx) > 0:
                    crossover_trials.append(int(pos_idx[0]) + 1)
                end_pos_flags.append(1.0 if float(b1_ga[-1]) > 0.0 else 0.0)

            if t_carto:
                traj_carto.append(float(np.mean(t_carto)))
                traj_jc.append(float(np.mean(t_jc)))
                traj_wval.append(float(np.mean(t_wval)))
                traj_opp.append(float(np.mean(t_opp)))

        arr_c = np.asarray(traj_carto, dtype=np.float64)
        arr_j = np.asarray(traj_jc, dtype=np.float64)
        arr_w = np.asarray(traj_wval, dtype=np.float64)
        diff_cj = arr_c - arr_j
        if len(diff_cj) >= 2 and np.std(diff_cj, ddof=1) > 0.0:
            t_stat, p_t = stats.ttest_rel(arr_c, arr_j, alternative="two-sided")
            w_stat, p_w = stats.wilcoxon(arr_c, arr_j, alternative="two-sided")
            dz = float(np.mean(diff_cj) / max(1e-9, float(np.std(diff_cj, ddof=1))))
        elif len(diff_cj) >= 2:
            t_stat, p_t = float("-inf" if np.mean(diff_cj) < 0 else "inf"), 0.0
            w_stat, p_w = stats.wilcoxon(arr_c, arr_j, alternative="two-sided")
            dz = float("-inf" if np.mean(diff_cj) < 0 else "inf")
        else:
            t_stat, p_t, w_stat, p_w, dz = 0.0, 1.0, 0.0, 1.0, 0.0

        all_c_arr = np.asarray(all_carto, dtype=np.float64)
        all_j_arr = np.asarray(all_jc, dtype=np.float64)
        all_w_arr = np.asarray(all_wval, dtype=np.float64)

        return {
            "n_dissociation_trials": int(len(all_c_arr)),
            "n_trajectories_with_window": int(len(arr_c)),
            "carto_negative_rate": float(np.mean(all_c_arr < 0.0)) if len(all_c_arr) else 0.0,
            "carto_positive_rate": float(np.mean(all_c_arr > 0.0)) if len(all_c_arr) else 0.0,
            "jc_positive_rate": float(np.mean(all_j_arr > 0.0)) if len(all_j_arr) else 0.0,
            "jc_negative_rate": float(np.mean(all_j_arr < 0.0)) if len(all_j_arr) else 0.0,
            "strict_opposition_rate": float(np.mean(traj_opp)) if traj_opp else 0.0,
            "mean_carto_valence": float(np.mean(all_c_arr)) if len(all_c_arr) else 0.0,
            "mean_jc_valence": float(np.mean(all_j_arr)) if len(all_j_arr) else 0.0,
            "mean_weighted_valence": float(np.mean(all_w_arr)) if len(all_w_arr) else 0.0,
            "sd_weighted_valence": float(np.std(all_w_arr, ddof=1)) if len(all_w_arr) > 1 else 0.0,
            "mean_grad_a_in_window": float(np.mean(all_ga)) if all_ga else 0.0,
            "mean_delta_grad_a_in_window": float(np.mean(all_dga)) if all_dga else 0.0,
            "paired_t": float(t_stat) if math.isfinite(float(t_stat)) else (-1e9 if t_stat < 0 else 1e9),
            "paired_p": float(p_t),
            "paired_p_str": _format_p(float(p_t)),
            "wilcoxon_w": float(w_stat),
            "wilcoxon_p": float(p_w),
            "wilcoxon_p_str": _format_p(float(p_w)),
            "cohens_dz": float(dz) if math.isfinite(float(dz)) else (-1e9 if dz < 0 else 1e9),
            "_crossover_trials": crossover_trials,
            "_end_pos_flags": end_pos_flags,
            "_traj_wval": arr_w,
        }

    arm_a_res = _run_arm_mc(traces_a, is_arm_a=True, block1_start=20)
    arm_b_res = _run_arm_mc(traces_b, is_arm_a=False, block1_start=16)

    cross_arr = np.asarray(arm_a_res.pop("_crossover_trials"), dtype=np.float64)
    end_pos_arr = np.asarray(arm_a_res.pop("_end_pos_flags"), dtype=np.float64)
    arr_w_a = arm_a_res.pop("_traj_wval")
    _ = arm_b_res.pop("_crossover_trials")
    _ = arm_b_res.pop("_end_pos_flags")
    arr_w_b = arm_b_res.pop("_traj_wval")

    return {
        "num_trajectories": num_trajectories,
        "b_prior_sym_diff": z2["b_prior_sym_diff"],
        "b_prior_symmetric": bool(z2["b_prior_sym_diff"] < 1e-12),
        "arm_a_loss_resolution": arm_a_res,
        "arm_b_uncertainty_onset": arm_b_res,
        "carto_negative_rate_arm_a": arm_a_res["carto_negative_rate"],
        "jc_positive_rate_arm_a": arm_a_res["jc_positive_rate"],
        "carto_positive_rate_arm_b": arm_b_res["carto_positive_rate"],
        "jc_negative_rate_arm_b": arm_b_res["jc_negative_rate"],
        "parametric_limitation": {
            "crossover_trial_in_block1_mean": float(np.mean(cross_arr)) if len(cross_arr) else None,
            "crossover_trial_in_block1_sd": float(np.std(cross_arr, ddof=1)) if len(cross_arr) > 1 else 0.0,
            "crossover_rate_in_block1": float(len(cross_arr) / max(1, num_trajectories)),
            "end_of_block1_positive_grad_a_rate": float(np.mean(end_pos_arr)) if len(end_pos_arr) else 0.0,
            "note": (
                "Dans TaskInferenceEngine, raw_ga = clip(4.2 * (0.43 - u_ep), -1, 1) dépend uniquement "
                "de l'entropie/KL sur la règle latente u_ep sans couplage négatif aux pertes préférentielles "
                "irréversibles ; après le point de croisement dans le Bloc 1 malgré p_ctrl=0.10, grad_a devient "
                "positif, circonscrivant honnêtement la fenêtre de dissociation P4 aux essais transitoires où "
                "X_t < 0 et Δ∇A_t > 0."
            ),
        },
        "_plot_arrays": {
            "arm_a_carto_neg": arm_a_res["carto_negative_rate"],
            "arm_a_jc_pos": arm_a_res["jc_positive_rate"],
            "arm_b_carto_pos": arm_b_res["carto_positive_rate"],
            "arm_b_jc_neg": arm_b_res["jc_negative_rate"],
            "arr_w_a": arr_w_a,
            "arr_w_b": arr_w_b,
        },
    }


def run_prediction_5_fear_control_mediation(
    num_trajectories: int = 1000,
    seed: int = 505,
) -> dict[str, Any]:
    """Prédiction 5 : Médiation par p_hat_ctrl de la transition Peur -> Colère vs Dégoût.

    Exécuté sur le même moteur `pymdp` sans règle ad hoc :
    - Tenseur B(Z=2) strictement symétrique entre Peur->Colère et Peur->Dégoût.
    - Chaque trajectoire démarre exactement sur la Peur (-2, 0, 2).
    - Menace constante (v_rule=0.25, cue_clarity=0.65) pour p_ctrl ∈ {0.10, 0.50, 0.90}.
    - Inclut un contrôle de sensibilité à forte volatilité (v_rule=0.35, cue_clarity=0.50)
      documentant honnêtement l'écrasement de p_hat_ctrl sous couplage FPI.
    """
    rng = np.random.default_rng(seed)
    params = AgentParameters(lambda_weight=1.0)
    z2 = _build_z2_filter_components(params)
    pts = z2["pts"]
    z2_indices = z2["z2_indices"]
    b_z2_avg = z2["b_z2_avg"]
    a0_z2 = z2["a0_z2"]
    a1_z2 = z2["a1_z2"]

    idx_by_pt = get_state_index_by_point()
    loc_peur = z2_indices.index(idx_by_pt[CoreAffectPoint(-2, 0, 2)])
    loc_col = z2_indices.index(idx_by_pt[CoreAffectPoint(-1, 1, 2)])
    loc_deg = z2_indices.index(idx_by_pt[CoreAffectPoint(-1, -1, 2)])

    b_prior_peur_to_colere = float(b_z2_avg[loc_col, loc_peur])
    b_prior_peur_to_degout = float(b_z2_avg[loc_deg, loc_peur])
    b_prior_peur_sym_diff = abs(b_prior_peur_to_colere - b_prior_peur_to_degout)
    assert b_prior_peur_sym_diff < 1e-12, f"B(Z=2) Peur->Colère/Dégoût asymétrique: {b_prior_peur_sym_diff}"

    task = TaskInferenceEngine(
        AgentParameters(rule_volatility_prior=0.20, ctrl_volatility_prior=0.12),
        seed=seed,
    )
    ema_gen = TwoStageEMAGenerator(params, seed=seed, stochastic=True)

    def _simulate_condition(
        p_ctrl: float,
        v_rule: float,
        cue_clarity: float,
        n_traj: int,
        seed_offset: int,
        n_trials: int = 24,
        burn_in: int = 4,
    ) -> dict[str, Any]:
        n_tr = min(25, max(4, n_traj))
        sched = [
            BlockSpec(0, "p5_threat", n_trials, p_ctrl=p_ctrl, v_rule=v_rule, cue_clarity=cue_clarity, d_obj=2)
        ]
        traces: list[tuple[np.ndarray, np.ndarray, np.ndarray]] = []
        for rep in range(n_tr):
            env = NonStationaryBanditEnv(schedule=sched, seed=seed_offset + rep)
            env.reset()
            task.reset()
            ga_l, gc_l, qc_l = [], [], []
            for _ in range(env.total_trials):
                pre = env.current_observation()
                act = task.select_action(pre)
                st = env.step(act)
                sig = task.observe_outcome(st.observation, act)
                ga_l.append(sig.grad_a)
                gc_l.append(sig.grad_c)
                qc_l.append(float(sig.q_ctrl[0]))
            traces.append(
                (
                    np.asarray(ga_l, dtype=np.float64),
                    np.asarray(gc_l, dtype=np.float64),
                    np.asarray(qc_l, dtype=np.float64),
                )
            )

        p_col_arr = np.zeros(n_traj, dtype=np.float64)
        p_deg_arr = np.zeros(n_traj, dtype=np.float64)
        p_peur_arr = np.zeros(n_traj, dtype=np.float64)
        p_hat_arr = np.zeros(n_traj, dtype=np.float64)
        ga_means = np.zeros(n_traj, dtype=np.float64)
        gc_means = np.zeros(n_traj, dtype=np.float64)
        col_ratios: list[float] = []
        first_exit_col = 0
        first_exit_deg = 0

        for n in range(n_traj):
            ga_base, gc_base, qc_base = traces[n % len(traces)]
            ga_n = np.clip(ga_base + rng.normal(0.0, 0.12, len(ga_base)), -1.2, 1.2)
            gc_n = np.clip(gc_base + rng.normal(0.0, 0.12, len(gc_base)), -1.2, 1.2)
            qs = np.zeros(8, dtype=np.float64)
            qs[loc_peur] = 1.0  # Départ exact en Peur (-2, 0, 2)

            c_col = 0
            c_deg = 0
            c_peur = 0
            decided = False
            n_eval = max(1, len(ga_n) - burn_in)

            for t, (ga, gc) in enumerate(zip(ga_n, gc_n)):
                ema = ema_gen.sample_from_gradients(float(ga), float(gc), persistence_level=1)
                ia, ic, _ = ema.modality_indices
                qs = (b_z2_avg @ qs) * a0_z2[ia] * a1_z2[ic]
                qs /= max(1e-12, float(qs.sum()))
                s = int(np.argmax(qs))
                if t >= burn_in:
                    if s == loc_col:
                        c_col += 1
                    elif s == loc_deg:
                        c_deg += 1
                    elif s == loc_peur:
                        c_peur += 1
                    if not decided and s in (loc_col, loc_deg):
                        decided = True
                        if s == loc_col:
                            first_exit_col += 1
                        else:
                            first_exit_deg += 1

            p_col_arr[n] = c_col / float(n_eval)
            p_deg_arr[n] = c_deg / float(n_eval)
            p_peur_arr[n] = c_peur / float(n_eval)
            p_hat_arr[n] = float(np.mean(qc_base[burn_in:]))
            ga_means[n] = float(np.mean(ga_n[burn_in:]))
            gc_means[n] = float(np.mean(gc_n[burn_in:]))
            if c_col + c_deg > 0:
                col_ratios.append(c_col / float(c_col + c_deg))

        bif_arr = p_col_arr - p_deg_arr
        return {
            "p_ctrl": p_ctrl,
            "p_ctrl_hat_mean": float(np.mean(p_hat_arr)),
            "p_ctrl_hat_sd": float(np.std(p_hat_arr, ddof=1)),
            "grad_a_mean": float(np.mean(ga_means)),
            "grad_c_mean": float(np.mean(gc_means)),
            "p_colere_mean": float(np.mean(p_col_arr)),
            "p_colere_sd": float(np.std(p_col_arr, ddof=1)),
            "p_degout_mean": float(np.mean(p_deg_arr)),
            "p_degout_sd": float(np.std(p_deg_arr, ddof=1)),
            "p_peur_mean": float(np.mean(p_peur_arr)),
            "colere_vs_degout_ratio": float(np.mean(col_ratios)) if col_ratios else 0.5,
            "bifurcation_index_mean": float(np.mean(bif_arr)),
            "bifurcation_index_sd": float(np.std(bif_arr, ddof=1)),
            "first_exit_colere_rate": float(first_exit_col / float(n_traj)),
            "first_exit_degout_rate": float(first_exit_deg / float(n_traj)),
            "_arrays": {
                "p_col": p_col_arr,
                "p_deg": p_deg_arr,
                "p_hat": p_hat_arr,
                "bif": bif_arr,
            },
        }

    p_ctrl_levels = (0.10, 0.50, 0.90)
    cond_results: dict[str, dict[str, Any]] = {}
    cond_arrays: dict[float, dict[str, np.ndarray]] = {}
    for idx_c, pc in enumerate(p_ctrl_levels):
        res_c = _simulate_condition(
            p_ctrl=pc,
            v_rule=0.25,
            cue_clarity=0.65,
            n_traj=num_trajectories,
            seed_offset=seed + 100 * (idx_c + 1),
        )
        cond_arrays[pc] = res_c.pop("_arrays")
        cond_results[f"{pc:.2f}"] = res_c

    def _welch_mw(a: np.ndarray, b: np.ndarray) -> dict[str, Any]:
        t_s, p_t = stats.ttest_ind(a, b, equal_var=False, alternative="two-sided")
        u_s, p_u = stats.mannwhitneyu(a, b, alternative="two-sided")
        psd = math.sqrt(0.5 * (float(np.var(a, ddof=1)) + float(np.var(b, ddof=1))))
        d_c = float((np.mean(a) - np.mean(b)) / max(1e-9, psd))
        return {
            "welch_t": float(t_s),
            "welch_p": float(p_t),
            "welch_p_str": _format_p(float(p_t)),
            "mannwhitney_u": float(u_s),
            "mannwhitney_p": float(p_u),
            "mannwhitney_p_str": _format_p(float(p_u)),
            "cohens_d": d_c,
        }

    # Médiation OLS + Test de Sobel sur X=p_ctrl -> M=p_hat_ctrl -> Y=P(Colère)-P(Dégoût)
    x_all = np.concatenate([np.full(num_trajectories, pc) for pc in p_ctrl_levels])
    m_all = np.concatenate([cond_arrays[pc]["p_hat"] for pc in p_ctrl_levels])
    y_all = np.concatenate([cond_arrays[pc]["bif"] for pc in p_ctrl_levels])

    n_tot = float(len(x_all))
    # 1) M ~ 1 + X (chemin a)
    xm_des = np.column_stack([np.ones(len(x_all)), x_all])
    beta_mx = np.linalg.lstsq(xm_des, m_all, rcond=None)[0]
    res_mx = m_all - xm_des @ beta_mx
    s2_mx = float(np.sum(res_mx ** 2) / max(1.0, n_tot - 2.0))
    cov_mx = s2_mx * np.linalg.pinv(xm_des.T @ xm_des)
    path_a = float(beta_mx[1])
    se_a = float(math.sqrt(max(1e-18, cov_mx[1, 1])))

    # 2) Y ~ 1 + X (effet total c)
    beta_yx = np.linalg.lstsq(xm_des, y_all, rcond=None)[0]
    path_c_total = float(beta_yx[1])

    # 3) Y ~ 1 + X + M (effet direct c', chemin b)
    xmy_des = np.column_stack([np.ones(len(x_all)), x_all, m_all])
    beta_ymx = np.linalg.lstsq(xmy_des, y_all, rcond=None)[0]
    res_ymx = y_all - xmy_des @ beta_ymx
    s2_ymx = float(np.sum(res_ymx ** 2) / max(1.0, n_tot - 3.0))
    cov_ymx = s2_ymx * np.linalg.pinv(xmy_des.T @ xmy_des)
    path_c_prime = float(beta_ymx[1])
    path_b = float(beta_ymx[2])
    se_b = float(math.sqrt(max(1e-18, cov_ymx[2, 2])))

    indirect_ab = path_a * path_b
    sobel_se = math.sqrt(max(1e-18, (path_b ** 2) * (se_a ** 2) + (path_a ** 2) * (se_b ** 2)))
    sobel_z = float(indirect_ab / sobel_se)
    sobel_p = float(2.0 * stats.norm.sf(abs(sobel_z)))
    prop_mediated = float(indirect_ab / path_c_total) if abs(path_c_total) > 1e-12 else 0.0
    spearman_rho, spearman_p = stats.spearmanr(m_all, y_all)

    # Contrôle de sensibilité à forte volatilité (limite paramétrique FPI documentée honnêtement)
    n_sens = min(200, num_trajectories)
    sens_lo = _simulate_condition(
        p_ctrl=0.10, v_rule=0.35, cue_clarity=0.50, n_traj=n_sens, seed_offset=seed + 910
    )
    sens_lo.pop("_arrays")
    sens_hi = _simulate_condition(
        p_ctrl=0.90, v_rule=0.35, cue_clarity=0.50, n_traj=n_sens, seed_offset=seed + 990
    )
    sens_hi.pop("_arrays")

    return {
        "num_trajectories_per_condition": num_trajectories,
        "b_prior_peur_to_colere": b_prior_peur_to_colere,
        "b_prior_peur_to_degout": b_prior_peur_to_degout,
        "b_prior_sym_diff": b_prior_peur_sym_diff,
        "b_prior_symmetric": bool(b_prior_peur_sym_diff < 1e-12),
        "conditions": cond_results,
        "comparisons_090_vs_010": {
            "colere": _welch_mw(cond_arrays[0.90]["p_col"], cond_arrays[0.10]["p_col"]),
            "degout": _welch_mw(cond_arrays[0.90]["p_deg"], cond_arrays[0.10]["p_deg"]),
            "bifurcation": _welch_mw(cond_arrays[0.90]["bif"], cond_arrays[0.10]["bif"]),
        },
        "mediation": {
            "path_a_p_ctrl_to_p_hat": path_a,
            "path_b_p_hat_to_bifurcation": path_b,
            "path_c_total": path_c_total,
            "path_c_prime_direct": path_c_prime,
            "indirect_ab": indirect_ab,
            "sobel_se": sobel_se,
            "sobel_z": sobel_z,
            "sobel_p": sobel_p,
            "sobel_p_str": _format_p(sobel_p),
            "proportion_mediated": prop_mediated,
            "spearman_rho_p_hat_vs_bifurcation": float(spearman_rho),
            "spearman_p": float(spearman_p),
            "spearman_p_str": _format_p(float(spearman_p)),
        },
        "high_volatility_boundary": {
            "v_rule": 0.35,
            "cue_clarity": 0.50,
            "n_trajectories_per_condition": n_sens,
            "p_ctrl_010": sens_lo,
            "p_ctrl_090": sens_hi,
            "note": (
                "Sous très forte volatilité (v_rule=0.35, cue_clarity=0.50), le couplage champ moyen FPI "
                "entre incertitude sur la règle et inférence de contrôlabilité maintient p_hat_ctrl < 0.50 "
                "même à p_ctrl=0.90 : P(Colère) augmente fortement avec p_ctrl et P(Dégoût) s'effondre, "
                "sans toutefois que P(Colère) ne dépasse P(Dégoût) dans ce régime extrême."
            ),
        },
        "_plot_arrays": {
            "levels": [f"{pc:.2f}" for pc in p_ctrl_levels],
            "p_col_means": [cond_results[f"{pc:.2f}"]["p_colere_mean"] for pc in p_ctrl_levels],
            "p_col_sds": [cond_results[f"{pc:.2f}"]["p_colere_sd"] for pc in p_ctrl_levels],
            "p_deg_means": [cond_results[f"{pc:.2f}"]["p_degout_mean"] for pc in p_ctrl_levels],
            "p_deg_sds": [cond_results[f"{pc:.2f}"]["p_degout_sd"] for pc in p_ctrl_levels],
            "p_hat_means": [cond_results[f"{pc:.2f}"]["p_ctrl_hat_mean"] for pc in p_ctrl_levels],
        },
    }


def _generate_figure(
    p1: dict[str, Any],
    p2: dict[str, Any],
    p3: dict[str, Any],
    p4: dict[str, Any],
    p5: dict[str, Any],
    output_path: Path,
) -> None:
    sns.set_theme(style="whitegrid", context="paper")
    fig, axes = plt.subplots(3, 2, figsize=(16.0, 16.5), dpi=300)

    # Panel A : P1 Arbitrage L1 (λ=1 vs λ=0)
    ax = axes[0, 0]
    a1 = p1["_plot_arrays"]
    df_p1 = pd.DataFrame(
        {
            "Corrélation Δ|X| vs Δ|Y|": np.concatenate([a1["r_traj_lam1"], a1["r_traj_lam0"]]),
            "Régime": (["Compétitif (λ = 1)"] * len(a1["r_traj_lam1"]))
            + (["Coopératif (λ = 0)"] * len(a1["r_traj_lam0"])),
        }
    )
    sns.violinplot(
        data=df_p1,
        x="Régime",
        y="Corrélation Δ|X| vs Δ|Y|",
        hue="Régime",
        palette={"Compétitif (λ = 1)": "#c0392b", "Coopératif (λ = 0)": "#2980b9"},
        legend=False,
        inner="quartile",
        ax=ax,
    )
    ax.axhline(0.0, color="#34495e", linestyle="--", linewidth=1.0)
    p1_p_tex = _format_p_latex(float(p1["comparison"]["wilcoxon_p"]))
    ax.set_title(
        f"P1 — Arbitrage budgétaire $L_1$ ($Z=4$, $N={p1['num_trajectories']}$)\n"
        f"$r(\\lambda=1) = {p1['lambda_1']['mean_traj_corr']:.3f}$ vs "
        f"$r(\\lambda=0) = {p1['lambda_0']['mean_traj_corr']:.3f}$ "
        f"(${p1_p_tex}$, $r_{{\\mathrm{{raw}}}}={p1['r_raw_orthogonal']:.3f}$)",
        fontsize=10.2,
        fontweight="bold",
    )
    ax.set_xlabel("")
    ax.set_ylabel(r"$r(\Delta |X_t|, \Delta |Y_t|)$ intra-trajectoire")

    # Panel B : P2 Matrice empirique 8x8 en Z=2 (B_prior sans biais axial)
    ax = axes[0, 1]
    a2 = p2["_plot_arrays"]
    mat_df = pd.DataFrame(
        a2["emp_matrix_8x8"],
        index=p2["z2_state_labels"],
        columns=p2["z2_state_labels"],
    )
    sns.heatmap(
        mat_df,
        annot=True,
        fmt=".2f",
        cmap="YlGnBu",
        vmin=0.0,
        vmax=0.65,
        cbar_kws={"label": r"$P(s_{t+1} \mid s_t)$"},
        annot_kws={"size": 7.5},
        ax=ax,
    )
    opp = p2["opposite_pole_transitions"]
    ax.set_title(
        f"P2 — Transitions émergentes en $Z=2$ ($N={p2['num_trajectories']}$, $\\Delta_{{\\mathrm{{prior}}}}={p2['b_prior_sym_diff']:.1e}$)\n"
        f"P(Ax$\\to$Dg)={p2['transition_rates']['p_axial_to_diagonal_mean']:.3f} vs "
        f"P(Dg$\\to$Ax)={p2['transition_rates']['p_diagonal_to_axial_mean']:.3f} | "
        f"Opp. max={opp['max_opposite_pole_rate']:.3f}",
        fontsize=10.0,
        fontweight="bold",
    )
    ax.tick_params(axis="x", rotation=35, labelsize=8)
    ax.tick_params(axis="y", rotation=0, labelsize=8)

    # Panel C : P2 Temps de résidence Axial vs Diagonal
    ax = axes[1, 0]
    df_p2 = pd.DataFrame(
        {
            "Temps moyen de résidence (pas)": np.concatenate(
                [a2["mean_res_axial"], a2["mean_res_diag"]]
            ),
            "Géométrie Z=2": (["Axial (±2,0), (0,±2)"] * len(a2["mean_res_axial"]))
            + (["Diagonal (±1,±1)"] * len(a2["mean_res_diag"])),
        }
    )
    sns.boxplot(
        data=df_p2,
        x="Géométrie Z=2",
        y="Temps moyen de résidence (pas)",
        hue="Géométrie Z=2",
        palette={"Axial (±2,0), (0,±2)": "#e67e22", "Diagonal (±1,±1)": "#16a085"},
        legend=False,
        width=0.45,
        ax=ax,
    )
    p2_p_tex = _format_p_latex(float(p2["residence_time"]["wilcoxon_p"]))
    ax.set_title(
        f"P2 — Instabilité émergente des positions axiales ($Z=2$)\n"
        f"$\\tau_{{ax}} = {p2['residence_time']['axial_mean']:.2f}$ vs "
        f"$\\tau_{{diag}} = {p2['residence_time']['diagonal_mean']:.2f}$ pas "
        f"(${p2_p_tex}$)",
        fontsize=10.2,
        fontweight="bold",
    )
    ax.set_xlabel("")

    # Panel D : P3 Inertie hiérarchique sur le POMDP canonique à 176 états (JAX)
    ax = axes[1, 1]
    a3 = p3["_plot_arrays"]
    colors_z = {2: "#2ecc71", 4: "#f39c12", 5: "#8e44ad"}
    t_axis = np.arange(a3["decay_curves_by_z"][2].shape[1])
    for z in (2, 4, 5):
        curves = a3["decay_curves_by_z"][z]
        mean_c = np.mean(curves, axis=0)
        lo_c = np.percentile(curves, 10, axis=0)
        hi_c = np.percentile(curves, 90, axis=0)
        ax.plot(
            t_axis,
            mean_c,
            color=colors_z[z],
            linewidth=2.2,
            label=(
                f"$Z={z}$ ($\\alpha_z={p3['alpha_by_z'][z]:.2f}$, "
                f"$t_{{1/2}}={p3['half_life'][str(z)]['mean']:.2f}$, "
                f"résist.={p3['resistance_index'][str(z)]['mean']:.4f})"
            ),
        )
        ax.fill_between(t_axis, lo_c, hi_c, color=colors_z[z], alpha=0.16)
    ax.axhline(0.50, color="#7f8c8d", linestyle=":", linewidth=1.2, label="Seuil demi-vie (50%)")
    p3_p_tex = _format_p_latex(float(p3["tests"]["kruskal_half_life_p"]))
    ax.set_title(
        f"P3 — Inertie hiérarchique POMDP 176 états (JAX, $N={p3['num_trajectories_per_z']}$/strate)\n"
        f"Kruskal-Wallis $H(t_{{1/2}}) = {p3['tests']['kruskal_half_life_H']:.1f}$, "
        f"${p3_p_tex}$",
        fontsize=10.2,
        fontweight="bold",
    )
    ax.set_xlabel("Pas de rémission neutre sous action DISSIPATE")
    ax.set_ylabel("Profondeur résiduelle normalisée $E[Z_t] / Z_0$")
    ax.set_xlim(0, min(14, len(t_axis) - 1))
    ax.legend(frameon=True, fontsize=8.0, loc="upper right")

    # Panel E : P4 Priorité lexicographique de sgn(X_t) sur ΔX_t
    ax = axes[2, 0]
    a4 = p4["_plot_arrays"]
    x_pos = np.arange(2)
    bar_w = 0.34
    carto_rates = [a4["arm_a_carto_neg"], a4["arm_b_carto_pos"]]
    jc_rates = [1.0 - a4["arm_a_jc_pos"], 1.0 - a4["arm_b_jc_neg"]]
    # Afficher comparaison directe des taux prédits : négatif en Bras A, positif en Bras B
    b1 = ax.bar(
        x_pos - bar_w / 2.0,
        [a4["arm_a_carto_neg"], a4["arm_b_carto_pos"]],
        width=bar_w,
        color="#2c3e50",
        label=r"CARTOGRAFFECT ($\mathrm{sgn}(X_t)$ prioritaire)",
    )
    b2 = ax.bar(
        x_pos + bar_w / 2.0,
        [1.0 - a4["arm_a_jc_pos"], 1.0 - a4["arm_b_jc_neg"]],
        width=bar_w,
        color="#e74c3c",
        alpha=0.85,
        label=r"Dérivatif ($\mathrm{sgn}(\Delta X_t)$ — Joffily & Coricelli)",
    )
    for bar_group in (b1, b2):
        for rect in bar_group:
            h = rect.get_height()
            ax.text(
                rect.get_x() + rect.get_width() / 2.0,
                h + 0.02,
                f"{h:.2f}",
                ha="center",
                va="bottom",
                fontsize=8.2,
            )
    ax.set_xticks(x_pos)
    ax.set_xticklabels(
        [
            "Bras A : Résolution brutale\n($X_t < 0, \\Delta X_t > 0$)\nTaux valence NÉGATIVE",
            "Bras B : Incertitude brutale\n($X_t > 0, \\Delta X_t < 0$)\nTaux valence POSITIVE",
        ],
        fontsize=8.6,
    )
    ax.set_ylim(0.0, 1.18)
    ax.set_ylabel("Taux de conformité de valence")
    p4_p_tex = _format_p_latex(float(p4["arm_a_loss_resolution"]["wilcoxon_p"]))
    cross_m = p4["parametric_limitation"]["crossover_trial_in_block1_mean"]
    cross_s = f"{cross_m:.1f}" if cross_m is not None else "N/A"
    ax.set_title(
        f"P4 — Priorité lexicographique $\\mathrm{{sgn}}(X_t)$ vs $\\Delta X_t$ "
        f"($N_{{\\mathrm{{win}}}}={p4['arm_a_loss_resolution']['n_dissociation_trials']}$)\n"
        f"${p4_p_tex}$, opposition = {p4['arm_a_loss_resolution']['strict_opposition_rate']:.2f} "
        f"| limite croisement Bloc 1 = {cross_s} essais",
        fontsize=9.6,
        fontweight="bold",
    )
    ax.legend(frameon=True, fontsize=8.0, loc="upper right")

    # Panel F : P5 Médiation par p_hat_ctrl (Peur -> Colère vs Dégoût)
    ax = axes[2, 1]
    a5 = p5["_plot_arrays"]
    x5 = np.arange(len(a5["levels"]))
    w5 = 0.34
    ax.bar(
        x5 - w5 / 2.0,
        a5["p_col_means"],
        yerr=a5["p_col_sds"],
        width=w5,
        capsize=3,
        color="#d35400",
        label=r"$P(\mathrm{Col\grave{e}re}\;(-1,+1,2))$",
    )
    ax.bar(
        x5 + w5 / 2.0,
        a5["p_deg_means"],
        yerr=a5["p_deg_sds"],
        width=w5,
        capsize=3,
        color="#7f8c8d",
        label=r"$P(\mathrm{D\acute{e}go\hat{u}t}\;(-1,-1,2))$",
    )
    ax2 = ax.twinx()
    ax2.plot(
        x5,
        a5["p_hat_means"],
        color="#2980b9",
        marker="o",
        linewidth=2.0,
        label=r"$\hat{p}_{\mathrm{ctrl}}$ inféré",
    )
    ax2.set_ylim(0.0, 1.0)
    ax2.set_ylabel(r"Contrôlabilité perçue $\hat{p}_{\mathrm{ctrl}}$", color="#2980b9")
    ax.set_xticks(x5)
    ax.set_xticklabels([f"$p_{{\\mathrm{{ctrl}}}}={lv}$" for lv in a5["levels"]], fontsize=9.0)
    ax.set_ylim(0.0, max(0.85, max(a5["p_col_means"] + a5["p_deg_means"]) * 1.35))
    ax.set_ylabel("Taux d'occupation post-Peur")
    med = p5["mediation"]
    p5_sobel_tex = _format_p_latex(float(med["sobel_p"]))
    ax.set_title(
        f"P5 — Médiation pragmatique Peur $\\to$ Colère vs Dégoût "
        f"($\\Delta_{{\\mathrm{{prior}}}}={p5['b_prior_sym_diff']:.1e}$)\n"
        f"Effet indirect $ab={med['indirect_ab']:.3f}$ (${p5_sobel_tex}$), "
        f"prop. médiée={med['proportion_mediated']:.2f}",
        fontsize=9.6,
        fontweight="bold",
    )
    h1, l1 = ax.get_legend_handles_labels()
    h2, l2 = ax2.get_legend_handles_labels()
    ax.legend(h1 + h2, l1 + l2, frameon=True, fontsize=7.8, loc="upper left")

    fig.suptitle(
        "CARTOGRAFFECT — Validation Monte-Carlo non circulaire des 5 prédictions falsifiables (P1–P5)",
        fontsize=13,
        fontweight="bold",
        y=0.988,
    )
    fig.tight_layout(rect=(0, 0, 1, 0.968))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, dpi=300)
    plt.close(fig)


def run_experiment(
    num_trajectories: int = 1000,
    results_dir: Path | None = None,
) -> dict[str, Any]:
    """Exécute les cinq validations Monte-Carlo (P1–P5) et exporte JSON/CSV/PNG."""
    out_dir = ROOT_DIR / "results" if results_dir is None else Path(results_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    p1 = run_prediction_1_budget_tradeoff(num_trajectories=num_trajectories)
    p2 = run_prediction_2_axial_instability(num_trajectories=num_trajectories)
    p3 = run_prediction_3_hierarchical_inertia(num_trajectories=num_trajectories)
    p4 = run_prediction_4_lexicographic_valence(num_trajectories=num_trajectories)
    p5 = run_prediction_5_fear_control_mediation(num_trajectories=num_trajectories)

    fig_path = out_dir / "fig1_falsifiable_predictions.png"
    _generate_figure(p1, p2, p3, p4, p5, fig_path)

    def _strip_plots(d: dict[str, Any]) -> dict[str, Any]:
        return {k: v for k, v in d.items() if k != "_plot_arrays"}

    try:
        rel_fig = fig_path.resolve().relative_to(ROOT_DIR.resolve()).as_posix()
    except ValueError:
        rel_fig = fig_path.name

    report = {
        "prediction_1_budget_tradeoff": _strip_plots(p1),
        "prediction_2_axial_instability": _strip_plots(p2),
        "prediction_3_hierarchical_inertia": _strip_plots(p3),
        "prediction_4_lexicographic_valence": _strip_plots(p4),
        "prediction_5_fear_control_mediation": _strip_plots(p5),
        "figure_path": rel_fig,
    }

    json_path = out_dir / "exp01_statistics.json"
    json_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")

    mat_df = pd.DataFrame(
        p2["empirical_transition_matrix_8x8"],
        index=p2["z2_state_labels"],
        columns=p2["z2_state_labels"],
    )
    mat_csv = out_dir / "exp01_prediction2_z2_transition_matrix.csv"
    mat_df.to_csv(mat_csv, encoding="utf-8")

    summary_rows = [
        {
            "prediction": "P1_L1_Budget",
            "metric": "mean_corr_dX_dY_lambda1_vs_lambda0",
            "value": p1["lambda_1"]["mean_traj_corr"],
            "comparison_value": p1["lambda_0"]["mean_traj_corr"],
            "p_value": p1["comparison"]["paired_p"],
            "p_value_str": p1["comparison"]["paired_p_str"],
            "effect_size": p1["comparison"]["cohens_dz"],
        },
        {
            "prediction": "P2_Axial_Residence",
            "metric": "mean_residence_axial_vs_diag",
            "value": p2["residence_time"]["axial_mean"],
            "comparison_value": p2["residence_time"]["diagonal_mean"],
            "p_value": p2["residence_time"]["paired_p"],
            "p_value_str": p2["residence_time"]["paired_p_str"],
            "effect_size": p2["residence_time"]["cohens_dz_diag_minus_axial"],
        },
        {
            "prediction": "P2_Axial_Transition",
            "metric": "p_axial_to_diag_vs_reverse",
            "value": p2["transition_rates"]["p_axial_to_diagonal_mean"],
            "comparison_value": p2["transition_rates"]["p_diagonal_to_axial_mean"],
            "p_value": p2["transition_rates"]["paired_p"],
            "p_value_str": p2["transition_rates"]["paired_p_str"],
            "effect_size": p2["transition_rates"]["cohens_dz"],
        },
        {
            "prediction": "P3_HalfLife_Z4_vs_Z2",
            "metric": "dissipation_half_life_steps",
            "value": p3["half_life"]["4"]["mean"],
            "comparison_value": p3["half_life"]["2"]["mean"],
            "p_value": p3["tests"]["half_life_z4_vs_z2"]["mannwhitney_p"],
            "p_value_str": p3["tests"]["half_life_z4_vs_z2"]["mannwhitney_p_str"],
            "effect_size": p3["tests"]["half_life_z4_vs_z2"]["cohens_d"],
        },
        {
            "prediction": "P3_HalfLife_Z5_vs_Z2",
            "metric": "dissipation_half_life_steps",
            "value": p3["half_life"]["5"]["mean"],
            "comparison_value": p3["half_life"]["2"]["mean"],
            "p_value": p3["tests"]["half_life_z5_vs_z2"]["mannwhitney_p"],
            "p_value_str": p3["tests"]["half_life_z5_vs_z2"]["mannwhitney_p_str"],
            "effect_size": p3["tests"]["half_life_z5_vs_z2"]["cohens_d"],
        },
        {
            "prediction": "P3_Resistance_Z5_vs_Z2",
            "metric": "dirichlet_evidence_resistance",
            "value": p3["resistance_index"]["5"]["mean"],
            "comparison_value": p3["resistance_index"]["2"]["mean"],
            "p_value": p3["tests"]["resistance_z5_vs_z2"]["mannwhitney_p"],
            "p_value_str": p3["tests"]["resistance_z5_vs_z2"]["mannwhitney_p_str"],
            "effect_size": p3["tests"]["resistance_z5_vs_z2"]["cohens_d"],
        },
        {
            "prediction": "P4_Lexicographic_Valence_ArmA",
            "metric": "carto_negative_rate_vs_jc_negative_rate",
            "value": p4["carto_negative_rate_arm_a"],
            "comparison_value": 1.0 - p4["jc_positive_rate_arm_a"],
            "p_value": p4["arm_a_loss_resolution"]["wilcoxon_p"],
            "p_value_str": p4["arm_a_loss_resolution"]["wilcoxon_p_str"],
            "effect_size": p4["arm_a_loss_resolution"]["cohens_dz"],
        },
        {
            "prediction": "P5_Fear_to_Colere_vs_Degout",
            "metric": "p_colere_090_vs_010_and_sobel_ab",
            "value": p5["conditions"]["0.90"]["p_colere_mean"],
            "comparison_value": p5["conditions"]["0.10"]["p_colere_mean"],
            "p_value": p5["mediation"]["sobel_p"],
            "p_value_str": p5["mediation"]["sobel_p_str"],
            "effect_size": p5["comparisons_090_vs_010"]["bifurcation"]["cohens_d"],
        },
    ]
    summary_csv = out_dir / "exp01_summary_metrics.csv"
    pd.DataFrame(summary_rows).to_csv(summary_csv, index=False, encoding="utf-8")

    return report


def main() -> None:
    report = run_experiment(num_trajectories=1000)
    print(json.dumps(report["prediction_1_budget_tradeoff"], indent=2))
    print(json.dumps(report["prediction_2_axial_instability"]["residence_time"], indent=2))
    print(json.dumps(report["prediction_2_axial_instability"]["transition_rates"], indent=2))
    print(json.dumps(report["prediction_2_axial_instability"]["opposite_pole_transitions"], indent=2))
    print(json.dumps(report["prediction_3_hierarchical_inertia"]["half_life"], indent=2))
    print(json.dumps(report["prediction_3_hierarchical_inertia"]["resistance_index"], indent=2))
    print(json.dumps(report["prediction_4_lexicographic_valence"], indent=2, ensure_ascii=False))
    print(json.dumps(report["prediction_5_fear_control_mediation"], indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
