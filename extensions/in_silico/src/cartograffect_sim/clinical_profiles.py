"""Profils cliniques computationnels transdiagnostiques (DSM-5) et interventions thérapeutiques.

Étend ``cartograffect_sim`` à la psychiatrie computationnelle transdiagnostique
(Friston et al., 2014 ; Schwartenbeck & Friston, 2016) en formalisant un ensemble
de profils cliniques inspirés du DSM-5 (APA, 2013) comme **régimes paramétriques
dynamiques** dans l'espace continu :

    θ = {τ_A, τ_C, λ, α_0, γ_α, η_diss, β_X, β_Y}

et dans ses trajectoires sur les 176 états du lexique ``Lexicon176``.

Contrainte épistémologique fondamentale de CARTOGRAFFECT® :
    Les profils modélisés formalisent des trajectoires fonctionnelles réversibles
    et des attracteurs dynamiques (inertie hiérarchique, seuils de saillance,
    arbitrage budgétaire L1, précision contextuelle), et NON des étiquettes
    diagnostiques statiques ou essentialistes.
"""

from __future__ import annotations

import math
from collections import Counter
from collections.abc import Sequence
from dataclasses import dataclass
from enum import Enum
from typing import Any

import jax
import jax.numpy as jnp
import numpy as np
import numpyro
import numpyro.distributions as dist
from numpyro.infer import SVI, Trace_ELBO, Predictive
from numpyro.infer.autoguide import AutoMultivariateNormal
from scipy import stats

from .affective_matrix import get_state_index_by_point
from .core_affect import (
    CoreAffectPoint,
    apply_budget_constraint,
    apportion_ray,
    dissipation_potential,
)
from .generative_process import (
    BanditAction,
    BlockSpec,
    NonStationaryBanditEnv,
    OutcomeValence,
)
from .lexicon_176 import ENTRY_BY_POINT
from .predictive_engine import AgentParameters
from .recovery import (
    RecoveryDataset,
    THETA_NAMES,
    _compute_choice_values_jax,
    compute_waic_and_bic,
)

# Alias canonique vers le processus génératif orthogonal sans fuite
GenerativeProcess = NonStationaryBanditEnv

COHORT_KEYS: tuple[str, ...] = (
    "normothymic",
    "mdd_inhibited",
    "gad",
    "panic",
    "mania",
    "ocd",
    "ptsd",
    "bpd",
)

FULL_DSM5_COHORT_KEYS: tuple[str, ...] = (
    "normothymic",
    # Troubles neurodéveloppementaux
    "asd",
    "adhd",
    # Spectre de la schizophrénie
    "scz_positive",
    "scz_negative",
    # Troubles bipolaires
    "mania",
    "bipolar_dep_mixed",
    # Troubles dépressifs
    "mdd_inhibited",
    # Troubles anxieux
    "gad",
    "panic",
    "social_anxiety",
    "specific_phobia",
    # TOC et apparentés
    "ocd",
    # Traumatismes et stresseurs
    "ptsd",
    # Troubles dissociatifs
    "dpdr",
    # Symptomatologie somatique
    "somatic_symptom",
    # Conduites alimentaires
    "anorexia_restrictive",
    "bulimia_binge",
    # Sommeil-éveil
    "insomnia_chronic",
    # Contrôle des impulsions
    "ied",
    # Addictions et substances
    "substance_use",
    # Troubles de la personnalité (Clusters A, B, C)
    "szpd",
    "bpd",
    "aspd",
    "avpd",
    "ocpd",
)

LATENT_PARAM_ORDER: tuple[str, ...] = (
    "tau_A",
    "tau_C",
    "lambda",
    "log_alpha_0",
    "gamma_alpha",
    "eta_diss",
    "delta_beta",
    "beta_Y",
)

# Bornes admissibles strictement incluses dans le support du modèle bayésien
# et respectant toutes les contraintes théoriques d'`AgentParameters`.
PARAMETER_BOUNDS: dict[str, tuple[float, float]] = {
    "tau_A": (0.06, 0.68),
    "tau_C": (0.06, 0.68),
    "lambda": (0.04, 0.96),
    "alpha_0": (0.18, 4.50),
    "gamma_alpha": (0.07, 0.98),
    "eta_diss": (0.06, 0.72),
    "beta_Y": (0.30, 1.72),
    "delta_beta": (0.20, 3.00),
}

CLINICAL_SVI_PARAM_NAMES: tuple[str, ...] = (*THETA_NAMES, "ctrl_prior_bias")
CLINICAL_NUM_FREE_PARAMS: int = 9


def build_dsm5_phenotyping_schedule(num_trials: int = 280) -> tuple[BlockSpec, ...]:
    """Protocole expérimental orthogonal ``GenerativeProcess`` pour le phénotypage clinique.

    Manipule orthogonalement contrôlabilité (``p_ctrl`` in {0.10, 0.90}),
    volatilité des règles (``v_rule`` in {0.05, 0.44}), clarté épistémique
    (``cue_clarity`` in {0.26, 0.94}), niveau d'abstraction (``d_obj`` in {2, 3, 4})
    et blocs de rémission neutre à partir d'un état basal calme.
    """
    specs = [
        ("p_baseline_calm", 0.80, 0.05, 0.92, 2, True, 12),
        ("p_high_ctrl_agency_d2", 0.90, 0.05, 0.94, 2, False, 34),
        ("p_unctrl_loss_d2", 0.10, 0.08, 0.88, 2, False, 38),
        ("p_remission_1", 0.60, 0.05, 0.90, 2, True, 22),
        ("p_volatile_threat_d3", 0.86, 0.44, 0.26, 3, False, 40),
        ("p_unctrl_loss_seq_d3", 0.10, 0.20, 0.72, 3, False, 40),
        ("p_deep_dual_stress_d4", 0.12, 0.40, 0.30, 4, False, 40),
        ("p_deep_agency_rev_d4", 0.90, 0.10, 0.90, 4, False, 24),
        ("p_remission_final", 0.70, 0.05, 0.92, 2, True, 30),
    ]
    return _scale_block_specs(specs, num_trials)


def _scale_block_specs(
    specs: Sequence[tuple[str, float, float, float, int, bool, int]],
    total_trials: int,
) -> tuple[BlockSpec, ...]:
    base_total = sum(s[6] for s in specs)
    raw_counts = [max(4, round(total_trials * s[6] / base_total)) for s in specs]
    diff = int(total_trials) - sum(raw_counts)
    idx_adj = 0
    while diff != 0:
        step = 1 if diff > 0 else -1
        pos = idx_adj % len(raw_counts)
        if raw_counts[pos] + step >= 4:
            raw_counts[pos] += step
            diff -= step
        idx_adj += 1

    blocks: list[BlockSpec] = []
    for idx, ((name, pc, vr, cc, dobj, is_rem, _), n_tr) in enumerate(
        zip(specs, raw_counts)
    ):
        blocks.append(
            BlockSpec(
                block_id=idx,
                name=name,
                num_trials=int(n_tr),
                p_ctrl=float(pc),
                v_rule=float(vr),
                cue_clarity=float(cc),
                d_obj=int(dobj),
                is_remission=bool(is_rem),
            )
        )
    return tuple(blocks)


def _theta_to_latent(theta: dict[str, float]) -> np.ndarray:
    alpha_0 = max(1e-6, float(theta["alpha_0"]))
    delta_beta = max(1e-4, float(theta["beta_X"]) - float(theta["beta_Y"]))
    return np.array(
        [
            float(theta["tau_A"]),
            float(theta["tau_C"]),
            float(theta["lambda"]),
            math.log(alpha_0),
            float(theta["gamma_alpha"]),
            float(theta["eta_diss"]),
            delta_beta,
            float(theta["beta_Y"]),
        ],
        dtype=np.float64,
    )


def _latent_to_theta(latent: np.ndarray) -> dict[str, float]:
    tau_a, tau_c, lam, log_a0, gamma_a, eta_d, delta_b, beta_y = [
        float(v) for v in latent
    ]
    return {
        "tau_A": tau_a,
        "tau_C": tau_c,
        "lambda": lam,
        "alpha_0": math.exp(log_a0),
        "gamma_alpha": gamma_a,
        "eta_diss": eta_d,
        "beta_X": beta_y + delta_b,
        "beta_Y": beta_y,
    }


def _is_within_bounds(theta: dict[str, float]) -> bool:
    delta_beta = theta["beta_X"] - theta["beta_Y"]
    checks = {
        "tau_A": theta["tau_A"],
        "tau_C": theta["tau_C"],
        "lambda": theta["lambda"],
        "alpha_0": theta["alpha_0"],
        "gamma_alpha": theta["gamma_alpha"],
        "eta_diss": theta["eta_diss"],
        "beta_Y": theta["beta_Y"],
        "delta_beta": delta_beta,
    }
    for k, val in checks.items():
        lo, hi = PARAMETER_BOUNDS[k]
        if not (math.isfinite(val) and lo <= val <= hi):
            return False
    return True


def _build_covariance_matrix(
    sds: Sequence[float],
    tau_corr: float = 0.25,
    lam_alpha_corr: float = 0.18,
) -> np.ndarray:
    """Construit une matrice de covariance 8x8 symétrique définie positive non diagonale.

    Ordre latent : ``(tau_A, tau_C, lambda, log_alpha_0, gamma_alpha, eta_diss, delta_beta, beta_Y)``.
    """
    corr = np.eye(8, dtype=np.float64)
    pairs = (
        (0, 1, tau_corr),         # (tau_A, tau_C)
        (2, 3, lam_alpha_corr),   # (lambda, log_alpha_0)
        (3, 4, 0.32),             # (log_alpha_0, gamma_alpha)
        (3, 5, -0.35),            # (log_alpha_0, eta_diss)
        (4, 5, -0.22),            # (gamma_alpha, eta_diss)
        (6, 7, -0.15),            # (delta_beta, beta_Y)
        (0, 6, -0.18),            # (tau_A, delta_beta)
    )
    for i, j, rho in pairs:
        corr[i, j] = rho
        corr[j, i] = rho

    sd_arr = np.asarray(sds, dtype=np.float64)
    cov = np.outer(sd_arr, sd_arr) * corr
    # Vérification stricte de définie-positivité via Cholesky
    np.linalg.cholesky(cov)
    return cov


@dataclass(frozen=True)
class MultivariatePriorComponent:
    """Composante gaussienne multivariée dans l'espace latent 8D des paramètres."""

    name: str
    weight: float
    mean_latent: np.ndarray
    cov_latent: np.ndarray
    ctrl_prior_bias_mean: float = 0.0
    ctrl_prior_bias_sd: float = 0.06
    dissociation_z_threshold: float = 5.0

    def __post_init__(self) -> None:
        m = np.asarray(self.mean_latent, dtype=np.float64).copy()
        c = np.asarray(self.cov_latent, dtype=np.float64).copy()
        if m.shape != (8,):
            raise ValueError(f"mean_latent doit avoir la forme (8,), reçu {m.shape}")
        if c.shape != (8, 8):
            raise ValueError(f"cov_latent doit avoir la forme (8, 8), reçu {c.shape}")
        if not np.allclose(c, c.T, atol=1e-10):
            raise ValueError("cov_latent doit être symétrique")
        np.linalg.cholesky(c)
        if self.weight <= 0.0:
            raise ValueError("weight doit être > 0")
        m.setflags(write=False)
        c.setflags(write=False)
        object.__setattr__(self, "mean_latent", m)
        object.__setattr__(self, "cov_latent", c)

    @property
    def mean_theta(self) -> dict[str, float]:
        """Centre de la composante converti dans l'espace canonique θ."""
        return _latent_to_theta(self.mean_latent)


@dataclass(frozen=True)
class CohortSpec:
    """Spécification d'une cohorte synthétique en tant que régime dynamique transdiagnostique."""

    key: str
    display_name: str
    short_label: str
    dsm5_reference: str
    functional_regime_description: str
    color: str
    components: tuple[MultivariatePriorComponent, ...]
    ptsd_bimodal_modulation: bool = False
    bpd_z4_z6_instability_sigma: float = 0.0
    dsm5_chapter: str = ""
    hitop_spectrum: str = ""

    def __post_init__(self) -> None:
        if not self.components:
            raise ValueError("Une cohorte doit posséder au moins une composante prior")
        total_w = sum(c.weight for c in self.components)
        if not math.isclose(total_w, 1.0, abs_tol=1e-6):
            raise ValueError(
                f"Les poids des composantes de {self.key} doivent sommer à 1.0 (reçu {total_w})"
            )


@dataclass(frozen=True)
class SyntheticAgentProfile:
    """Instance individuelle θ_i échantillonnée depuis ``DSM5PriorBank``."""

    agent_id: str
    cohort_key: str
    subregime: str
    theta: dict[str, float]
    agent_params: AgentParameters
    ctrl_prior_bias: float = 0.0
    ptsd_bimodal_modulation: bool = False
    dissociation_z_threshold: float = 5.0
    bpd_z4_z6_instability_sigma: float = 0.0


def _build_scaled_covariance(
    sds: Sequence[float],
    *,
    dispersion_scale: float = 2.0,
    tau_corr: float = 0.25,
    lam_alpha_corr: float = 0.18,
) -> np.ndarray:
    """Construit une matrice de covariance 8x8 mise à l'échelle par ``dispersion_scale``."""
    return _build_covariance_matrix(
        [dispersion_scale * s for s in sds],
        tau_corr=tau_corr,
        lam_alpha_corr=lam_alpha_corr,
    )


class DSM5PriorBank:
    """Banque de distributions a priori multivariées pour 8 régimes cliniques inspirés du DSM-5.

    Chaque cohorte est définie par une distribution a priori multivariée (ou un mélange
    bimodal pour le TSPT) dans l'espace latent des 8 paramètres ``θ`` et de la dynamique
    de précision associée, formalisant des **trajectoires fonctionnelles réversibles**
    et non des catégories diagnostiques rigides.
    """

    def __init__(self) -> None:
        self._specs: dict[str, CohortSpec] = self._build_default_specs()

    @staticmethod
    def _build_default_specs() -> dict[str, CohortSpec]:
        _scaled_cov = _build_scaled_covariance

        # 1. Contrôle normothymique : seuils équilibrés, faible inertie, dissipation rapide
        c_normo = MultivariatePriorComponent(
            name="normothymic_flexible",
            weight=1.0,
            mean_latent=_theta_to_latent(
                {
                    "tau_A": 0.28,
                    "tau_C": 0.28,
                    "lambda": 0.55,
                    "alpha_0": 0.65,
                    "gamma_alpha": 0.26,
                    "eta_diss": 0.52,
                    "beta_X": 2.35,
                    "beta_Y": 1.05,
                }
            ),
            cov_latent=_scaled_cov(
                [0.040, 0.040, 0.075, 0.22, 0.045, 0.065, 0.22, 0.14],
                tau_corr=0.30,
            ),
            ctrl_prior_bias_mean=0.0,
            ctrl_prior_bias_sd=0.05,
        )

        # 2. TDC inhibé : forte inertie hiérarchique, dissipation bloquée, prior pessimiste sur contrôle
        c_mdd = MultivariatePriorComponent(
            name="mdd_inhibited_trapping",
            weight=1.0,
            mean_latent=_theta_to_latent(
                {
                    "tau_A": 0.34,
                    "tau_C": 0.13,
                    "lambda": 0.84,
                    "alpha_0": 2.40,
                    "gamma_alpha": 0.68,
                    "eta_diss": 0.08,
                    "beta_X": 1.45,
                    "beta_Y": 0.95,
                }
            ),
            cov_latent=_scaled_cov(
                [0.055, 0.025, 0.065, 0.26, 0.085, 0.020, 0.14, 0.14],
                tau_corr=-0.18,
            ),
            ctrl_prior_bias_mean=-0.75,
            ctrl_prior_bias_sd=0.10,
        )

        # 3. TAG : hyper-saillance d'incertitude (tau_A bas), exploration soutenue, inertie modérée-élevée
        c_gad = MultivariatePriorComponent(
            name="gad_epistemic_worry",
            weight=1.0,
            mean_latent=_theta_to_latent(
                {
                    "tau_A": 0.11,
                    "tau_C": 0.22,
                    "lambda": 0.76,
                    "alpha_0": 1.75,
                    "gamma_alpha": 0.50,
                    "eta_diss": 0.17,
                    "beta_X": 3.10,
                    "beta_Y": 0.90,
                }
            ),
            cov_latent=_scaled_cov(
                [0.022, 0.040, 0.085, 0.24, 0.075, 0.035, 0.28, 0.14],
                tau_corr=0.22,
            ),
            ctrl_prior_bias_mean=0.0,
            ctrl_prior_bias_sd=0.06,
        )

        # 4. Trouble panique : hypersensibilité bilatérale paroxystique, pente gamma_alpha raide, alpha_0 bas
        c_panic = MultivariatePriorComponent(
            name="panic_paroxysmal_surge",
            weight=1.0,
            mean_latent=_theta_to_latent(
                {
                    "tau_A": 0.09,
                    "tau_C": 0.09,
                    "lambda": 0.32,
                    "alpha_0": 0.45,
                    "gamma_alpha": 0.66,
                    "eta_diss": 0.36,
                    "beta_X": 2.65,
                    "beta_Y": 1.45,
                }
            ),
            cov_latent=_scaled_cov(
                [0.016, 0.016, 0.070, 0.20, 0.085, 0.060, 0.22, 0.15],
                tau_corr=0.42,
            ),
            ctrl_prior_bias_mean=0.0,
            ctrl_prior_bias_sd=0.06,
        )

        # 5. Épisode maniaque : filtre épistémique élevé (tau_A), faible contrainte L1, biais optimiste sur contrôle
        c_mania = MultivariatePriorComponent(
            name="mania_ergotropic_expansion",
            weight=1.0,
            mean_latent=_theta_to_latent(
                {
                    "tau_A": 0.58,
                    "tau_C": 0.11,
                    "lambda": 0.15,
                    "alpha_0": 0.38,
                    "gamma_alpha": 0.15,
                    "eta_diss": 0.28,
                    "beta_X": 1.95,
                    "beta_Y": 1.60,
                }
            ),
            cov_latent=_scaled_cov(
                [0.055, 0.022, 0.050, 0.20, 0.042, 0.055, 0.12, 0.09],
                tau_corr=-0.22,
            ),
            ctrl_prior_bias_mean=0.85,
            ctrl_prior_bias_sd=0.08,
        )

        # 6. TOC : primauté épistémique extrême (beta_X/beta_Y), budget L1 serré, tau_C élevé
        c_ocd = MultivariatePriorComponent(
            name="ocd_compulsive_checking",
            weight=1.0,
            mean_latent=_theta_to_latent(
                {
                    "tau_A": 0.13,
                    "tau_C": 0.44,
                    "lambda": 0.90,
                    "alpha_0": 2.20,
                    "gamma_alpha": 0.60,
                    "eta_diss": 0.14,
                    "beta_X": 3.45,
                    "beta_Y": 0.55,
                }
            ),
            cov_latent=_scaled_cov(
                [0.025, 0.065, 0.045, 0.24, 0.075, 0.032, 0.22, 0.09],
                tau_corr=-0.20,
            ),
            ctrl_prior_bias_mean=0.0,
            ctrl_prior_bias_sd=0.06,
        )

        # 7. TSPT : mélange bimodal dynamique Hypervigilance / Dissociation
        c_ptsd_hyp = MultivariatePriorComponent(
            name="ptsd_hypervigilance",
            weight=0.55,
            mean_latent=_theta_to_latent(
                {
                    "tau_A": 0.10,
                    "tau_C": 0.12,
                    "lambda": 0.46,
                    "alpha_0": 2.00,
                    "gamma_alpha": 0.64,
                    "eta_diss": 0.12,
                    "beta_X": 3.05,
                    "beta_Y": 1.15,
                }
            ),
            cov_latent=_scaled_cov(
                [0.020, 0.024, 0.080, 0.24, 0.080, 0.028, 0.24, 0.14],
                tau_corr=0.32,
            ),
            ctrl_prior_bias_mean=0.0,
            ctrl_prior_bias_sd=0.06,
            dissociation_z_threshold=5.2,
        )
        c_ptsd_dis = MultivariatePriorComponent(
            name="ptsd_dissociation",
            weight=0.45,
            mean_latent=_theta_to_latent(
                {
                    "tau_A": 0.54,
                    "tau_C": 0.54,
                    "lambda": 0.86,
                    "alpha_0": 2.40,
                    "gamma_alpha": 0.72,
                    "eta_diss": 0.09,
                    "beta_X": 1.40,
                    "beta_Y": 0.55,
                }
            ),
            cov_latent=_scaled_cov(
                [0.055, 0.055, 0.060, 0.24, 0.085, 0.022, 0.16, 0.10],
                tau_corr=0.45,
            ),
            ctrl_prior_bias_mean=0.0,
            ctrl_prior_bias_sd=0.06,
            dissociation_z_threshold=4.2,
        )

        # 8. TPL : instabilité de précision aux strates réflexive (Z=4) et identitaire (Z=6)
        c_bpd = MultivariatePriorComponent(
            name="bpd_z4_z6_precision_instability",
            weight=1.0,
            mean_latent=_theta_to_latent(
                {
                    "tau_A": 0.17,
                    "tau_C": 0.17,
                    "lambda": 0.38,
                    "alpha_0": 0.70,
                    "gamma_alpha": 0.44,
                    "eta_diss": 0.22,
                    "beta_X": 2.35,
                    "beta_Y": 1.48,
                }
            ),
            cov_latent=_scaled_cov(
                [0.036, 0.036, 0.080, 0.24, 0.070, 0.048, 0.22, 0.13],
                tau_corr=0.25,
            ),
            ctrl_prior_bias_mean=0.0,
            ctrl_prior_bias_sd=0.10,
        )

        specs_list = [
            CohortSpec(
                key="normothymic",
                display_name="Contrôle normothymique",
                short_label="Normothymique",
                dsm5_reference="Référence homéostatique (sans trouble)",
                functional_regime_description=(
                    "Trajectoire flexible : seuils calibrés, faible inertie α_z et retour rapide "
                    "au Point de Veille (0,0,0)."
                ),
                color="#1b9e77",
                components=(c_normo,),
                dsm5_chapter="Référence homéostatique",
                hitop_spectrum="Normothymique",
            ),
            CohortSpec(
                key="mdd_inhibited",
                display_name="Trouble dépressif caractérisé inhibé",
                short_label="TDC inhibé",
                dsm5_reference="DSM-5 296.xx — Trouble dépressif caractérisé (spécification inhibée)",
                functional_regime_description=(
                    "Trajectoire d'engluement trophique (-Y / -X,-Y) : forte inertie α_z, "
                    "dissipation ralentie (η_diss faible) et prior pessimiste de contrôlabilité."
                ),
                color="#2b5c8f",
                components=(c_mdd,),
                dsm5_chapter="Troubles dépressifs",
                hitop_spectrum="Internalisé — Détresse & Peur",
            ),
            CohortSpec(
                key="gad",
                display_name="Trouble anxieux généralisé",
                short_label="TAG",
                dsm5_reference="DSM-5 300.02 — Trouble anxieux généralisé",
                functional_regime_description=(
                    "Trajectoire d'inquiétude épistémique persistante : seuil τ_A abaissé, "
                    "arbitrage L1 tendu et prédominance de l'incertitude sur l'axe -X."
                ),
                color="#d95f02",
                components=(c_gad,),
                dsm5_chapter="Troubles anxieux",
                hitop_spectrum="Internalisé — Détresse & Peur",
            ),
            CohortSpec(
                key="panic",
                display_name="Trouble panique",
                short_label="Panique",
                dsm5_reference="DSM-5 300.01 — Trouble panique",
                functional_regime_description=(
                    "Trajectoire paroxystique à embrasement rapide : seuils (τ_A, τ_C) très bas, "
                    "α_0 faible mais pente γ_α raide amplifiant les sauts de strate."
                ),
                color="#e7298a",
                components=(c_panic,),
                dsm5_chapter="Troubles anxieux",
                hitop_spectrum="Internalisé — Détresse & Peur",
            ),
            CohortSpec(
                key="mania",
                display_name="Épisode maniaque",
                short_label="Manie",
                dsm5_reference="DSM-5 296.4x — Trouble bipolaire I, épisode maniaque",
                functional_regime_description=(
                    "Trajectoire d'expansion ergotropique (+Y / +X,+Y) : filtre τ_A élevé, "
                    "faible contrainte L1 (λ bas), faible inertie et hyper-confiance en contrôle."
                ),
                color="#e6ab02",
                components=(c_mania,),
                dsm5_chapter="Troubles bipolaires",
                hitop_spectrum="Bipolaire & Psychotique",
            ),
            CohortSpec(
                key="ocd",
                display_name="Trouble obsessionnel-compulsif",
                short_label="TOC",
                dsm5_reference="DSM-5 300.3 — Trouble obsessionnel-compulsif",
                functional_regime_description=(
                    "Trajectoire de vérification épistémique compulsive : ratio β_X/β_Y maximal, "
                    "budget L1 serré (λ élevé) et ancrage sur l'axe -X (Doute / Méfiance)."
                ),
                color="#7570b3",
                components=(c_ocd,),
                dsm5_chapter="TOC et apparentés",
                hitop_spectrum="Compulsif & Surcontrôle",
            ),
            CohortSpec(
                key="ptsd",
                display_name="Trouble de stress post-traumatique",
                short_label="TSPT (bimodal)",
                dsm5_reference="DSM-5 309.81 — Trouble de stress post-traumatique",
                functional_regime_description=(
                    "Trajectoire bimodale hypervigilance (-X,+Y) / dissociation centrale (0,0,Z>=4) "
                    "avec bascule dynamique induite par la surcharge profonde ou la surprise."
                ),
                color="#a63603",
                components=(c_ptsd_hyp, c_ptsd_dis),
                ptsd_bimodal_modulation=True,
                dsm5_chapter="Traumatismes et stresseurs",
                hitop_spectrum="Internalisé — Détresse & Peur",
            ),
            CohortSpec(
                key="bpd",
                display_name="Trouble de la personnalité limite",
                short_label="TPL (Z=4,6)",
                dsm5_reference="DSM-5 301.83 — Trouble de la personnalité borderline",
                functional_regime_description=(
                    "Trajectoire à instabilité de précision localisée aux strates réflexive (Z=4) "
                    "et identitaire (Z=6), engendrant des bascules rapides inter-quadrants."
                ),
                color="#66a61e",
                components=(c_bpd,),
                bpd_z4_z6_instability_sigma=0.42,
                dsm5_chapter="Troubles de la personnalité",
                hitop_spectrum="Désinhibé & Externalisé",
            ),
        ]
        return {spec.key: spec for spec in specs_list}

    @property
    def cohort_keys(self) -> tuple[str, ...]:
        """Clés ordonnées des cohortes cliniques de la banque."""
        return tuple(self._specs.keys())

    def get_spec(self, cohort_key: str) -> CohortSpec:
        """Retourne la spécification complète ``CohortSpec`` d'une cohorte."""
        if cohort_key not in self._specs:
            raise KeyError(
                f"Cohorte inconnue : {cohort_key!r} (attendue dans {self.cohort_keys})"
            )
        return self._specs[cohort_key]

    def cohorts_by_chapter(self) -> dict[str, tuple[str, ...]]:
        """Regroupe les clés de cohortes par grand chapitre clinique DSM-5 (ordre préservé)."""
        grouped: dict[str, list[str]] = {}
        for key in self.cohort_keys:
            ch = self._specs[key].dsm5_chapter or "Non spécifié"
            grouped.setdefault(ch, []).append(key)
        return {ch: tuple(keys) for ch, keys in grouped.items()}

    def cohorts_by_spectrum(self) -> dict[str, tuple[str, ...]]:
        """Regroupe les clés de cohortes par spectre dimensionnel HiTOP (ordre préservé)."""
        grouped: dict[str, list[str]] = {}
        for key in self.cohort_keys:
            sp = self._specs[key].hitop_spectrum or "Non spécifié"
            grouped.setdefault(sp, []).append(key)
        return {sp: tuple(keys) for sp, keys in grouped.items()}

    def summary_table(self) -> list[dict[str, Any]]:
        """Exporte un tableau synthétique des centres a priori et mécanismes par cohorte."""
        rows: list[dict[str, Any]] = []
        for key in self.cohort_keys:
            spec = self._specs[key]
            weights = np.array([c.weight for c in spec.components], dtype=np.float64)
            mean_lat = np.sum(
                [w * c.mean_latent for w, c in zip(weights, spec.components)], axis=0
            )
            mean_th = _latent_to_theta(mean_lat)
            rows.append(
                {
                    "cohort_key": spec.key,
                    "display_name": spec.display_name,
                    "short_label": spec.short_label,
                    "dsm5_reference": spec.dsm5_reference,
                    "dsm5_chapter": spec.dsm5_chapter,
                    "hitop_spectrum": spec.hitop_spectrum,
                    "num_components": len(spec.components),
                    "ptsd_bimodal": spec.ptsd_bimodal_modulation,
                    "bpd_z4_z6_sigma": spec.bpd_z4_z6_instability_sigma,
                    "ctrl_prior_bias_mean": float(
                        sum(w * c.ctrl_prior_bias_mean for w, c in zip(weights, spec.components))
                    ),
                    **mean_th,
                }
            )
        return rows

    def sample_cohort(
        self,
        cohort_key: str,
        n_agents: int = 200,
        *,
        seed: int = 42,
    ) -> list[SyntheticAgentProfile]:
        """Échantillonne ``n_agents`` profils individuels depuis le prior multivarié de ``cohort_key``."""
        if n_agents < 1:
            raise ValueError(f"n_agents doit être >= 1 (reçu {n_agents})")
        spec = self.get_spec(cohort_key)
        rng = np.random.default_rng(seed)
        weights = np.array([c.weight for c in spec.components], dtype=np.float64)
        weights /= weights.sum()

        profiles: list[SyntheticAgentProfile] = []
        for idx in range(n_agents):
            comp_idx = (
                int(rng.choice(len(spec.components), p=weights))
                if len(spec.components) > 1
                else 0
            )
            comp = spec.components[comp_idx]

            theta_drawn: dict[str, float] | None = None
            for _ in range(500):
                z_vec = rng.multivariate_normal(comp.mean_latent, comp.cov_latent)
                candidate = _latent_to_theta(z_vec)
                if _is_within_bounds(candidate):
                    theta_drawn = candidate
                    break
            if theta_drawn is None:
                # Repli garanti admissible par projection sur les bornes
                z_clip = comp.mean_latent.copy()
                candidate = _latent_to_theta(z_clip)
                theta_drawn = candidate

            ctrl_bias = float(
                np.clip(
                    rng.normal(comp.ctrl_prior_bias_mean, comp.ctrl_prior_bias_sd),
                    -0.96,
                    0.96,
                )
            )
            agent_params = AgentParameters(
                tau_a=theta_drawn["tau_A"],
                tau_c=theta_drawn["tau_C"],
                lambda_weight=theta_drawn["lambda"],
                alpha_0=theta_drawn["alpha_0"],
                gamma_alpha=theta_drawn["gamma_alpha"],
                eta_diss=theta_drawn["eta_diss"],
                beta_x=theta_drawn["beta_X"],
                beta_y=theta_drawn["beta_Y"],
                enforce_theoretical_constraints=True,
            )
            profiles.append(
                SyntheticAgentProfile(
                    agent_id=f"{cohort_key}_{idx:04d}",
                    cohort_key=cohort_key,
                    subregime=comp.name,
                    theta=theta_drawn,
                    agent_params=agent_params,
                    ctrl_prior_bias=ctrl_bias,
                    ptsd_bimodal_modulation=spec.ptsd_bimodal_modulation,
                    dissociation_z_threshold=comp.dissociation_z_threshold,
                    bpd_z4_z6_instability_sigma=spec.bpd_z4_z6_instability_sigma,
                )
            )
        return profiles

    def sample_all_cohorts(
        self,
        n_per_cohort: int = 200,
        *,
        seed: int = 42,
    ) -> dict[str, list[SyntheticAgentProfile]]:
        """Échantillonne l'ensemble des cohortes (``len(cohort_keys) × n_per_cohort`` agents)."""
        return {
            key: self.sample_cohort(key, n_agents=n_per_cohort, seed=seed + idx * 10_000)
            for idx, key in enumerate(self.cohort_keys)
        }


class DSM5FullNosologyPriorBank(DSM5PriorBank):
    """Banque étendue couvrant les 26 régimes cliniques transdiagnostiques pan-chapitres DSM-5.

    Réutilise verbatim les 8 régimes canoniques de ``DSM5PriorBank`` et adjoint
    18 régimes supplémentaires couvrant les grands chapitres de la Section II
    du DSM-5, organisés selon la contrainte épistémologique CARTOGRAFFECT® de
    trajectoires fonctionnelles réversibles.
    """

    def __init__(self) -> None:
        self._specs: dict[str, CohortSpec] = self._build_full_specs()

    @staticmethod
    def _build_full_specs() -> dict[str, CohortSpec]:
        base_specs = DSM5PriorBank._build_default_specs()

        extended_table: tuple[dict[str, Any], ...] = (
            {
                "key": "asd",
                "comp_name": "asd_predictive_rigidity",
                "display_name": "Trouble du spectre de l'autisme (TSA)",
                "short_label": "TSA",
                "dsm5_reference": "DSM-5 299.00 — Trouble du spectre de l'autisme",
                "dsm5_chapter": "Troubles neurodéveloppementaux",
                "hitop_spectrum": "Compulsif & Surcontrôle",
                "color": "#5e4fa2",
                "desc": "Hyper-précision sensorielle d'erreur (τ_A bas), forte inertie α_0 à faible pente γ_α et surcontrôle L1.",
                "theta": {
                    "tau_A": 0.10, "tau_C": 0.38, "lambda": 0.84, "alpha_0": 2.30,
                    "gamma_alpha": 0.24, "eta_diss": 0.19, "beta_X": 2.95, "beta_Y": 0.75,
                },
                "sds": [0.020, 0.055, 0.055, 0.22, 0.048, 0.038, 0.22, 0.11],
                "tau_corr": -0.15,
                "ctrl_mean": 0.0,
                "ctrl_sd": 0.06,
            },
            {
                "key": "adhd",
                "comp_name": "adhd_attentional_lability",
                "display_name": "TDAH",
                "short_label": "TDAH",
                "dsm5_reference": "DSM-5 314.0x — Trouble déficit de l'attention/hyperactivité",
                "dsm5_chapter": "Troubles neurodéveloppementaux",
                "hitop_spectrum": "Désinhibé & Externalisé",
                "color": "#fdae61",
                "desc": "Faible inertie hiérarchique (α_0 bas), dissipation rapide et prédominance exploratoire/impulsive.",
                "theta": {
                    "tau_A": 0.16, "tau_C": 0.18, "lambda": 0.26, "alpha_0": 0.28,
                    "gamma_alpha": 0.14, "eta_diss": 0.58, "beta_X": 1.75, "beta_Y": 1.22,
                },
                "sds": [0.032, 0.034, 0.065, 0.20, 0.036, 0.060, 0.14, 0.12],
                "tau_corr": 0.25,
                "ctrl_mean": 0.18,
                "ctrl_sd": 0.08,
            },
            {
                "key": "scz_positive",
                "comp_name": "scz_aberrant_salience",
                "display_name": "Schizophrénie — profil positif",
                "short_label": "SCZ pos.",
                "dsm5_reference": "DSM-5 295.90 — Schizophrénie (saillance aberrante)",
                "dsm5_chapter": "Spectre de la schizophrénie",
                "hitop_spectrum": "Bipolaire & Psychotique",
                "color": "#d53e4f",
                "desc": "Saillance aberrante extrême (τ_A minimal), embrasement vertical γ_α élevé et apophénie de contrôle.",
                "theta": {
                    "tau_A": 0.08, "tau_C": 0.15, "lambda": 0.34, "alpha_0": 0.55,
                    "gamma_alpha": 0.86, "eta_diss": 0.11, "beta_X": 2.85, "beta_Y": 1.18,
                },
                "sds": [0.015, 0.030, 0.070, 0.22, 0.065, 0.026, 0.22, 0.13],
                "tau_corr": 0.20,
                "ctrl_mean": 0.55,
                "ctrl_sd": 0.12,
            },
            {
                "key": "scz_negative",
                "comp_name": "scz_negative_withdrawal",
                "display_name": "Schizophrénie — profil négatif",
                "short_label": "SCZ nég.",
                "dsm5_reference": "DSM-5 295.90 — Schizophrénie (symptômes négatifs / aboulie)",
                "dsm5_chapter": "Spectre de la schizophrénie",
                "hitop_spectrum": "Détachement & Dissociation",
                "color": "#3288bd",
                "desc": "Émoussement sensoriel bilatéral (τ_A, τ_C élevés), inertie profonde α_0 et apragmatisme (β_X, β_Y bas).",
                "theta": {
                    "tau_A": 0.56, "tau_C": 0.58, "lambda": 0.72, "alpha_0": 2.85,
                    "gamma_alpha": 0.52, "eta_diss": 0.12, "beta_X": 0.88, "beta_Y": 0.38,
                },
                "sds": [0.050, 0.048, 0.070, 0.22, 0.070, 0.028, 0.11, 0.055],
                "tau_corr": 0.40,
                "ctrl_mean": -0.35,
                "ctrl_sd": 0.09,
            },
            {
                "key": "bipolar_dep_mixed",
                "comp_name": "bipolar_depressive_mixed",
                "display_name": "Dépression bipolaire / mixte",
                "short_label": "Bip. mixte",
                "dsm5_reference": "DSM-5 296.5x — Trouble bipolaire, épisode dépressif / mixte",
                "dsm5_chapter": "Troubles bipolaires",
                "hitop_spectrum": "Bipolaire & Psychotique",
                "color": "#9e0142",
                "desc": "Dysphorie mixte à réactivité de contrôle abaissée, forte inertie α_0 et réactivité pragmatique maintenue.",
                "theta": {
                    "tau_A": 0.14, "tau_C": 0.11, "lambda": 0.42, "alpha_0": 1.85,
                    "gamma_alpha": 0.62, "eta_diss": 0.10, "beta_X": 2.25, "beta_Y": 1.35,
                },
                "sds": [0.028, 0.022, 0.075, 0.24, 0.075, 0.024, 0.18, 0.12],
                "tau_corr": 0.30,
                "ctrl_mean": -0.55,
                "ctrl_sd": 0.11,
            },
            {
                "key": "social_anxiety",
                "comp_name": "social_anxiety_evaluative",
                "display_name": "Trouble d'anxiété sociale",
                "short_label": "Anx. sociale",
                "dsm5_reference": "DSM-5 300.23 — Trouble d'anxiété sociale",
                "dsm5_chapter": "Troubles anxieux",
                "hitop_spectrum": "Internalisé — Détresse & Peur",
                "color": "#f46d43",
                "desc": "Hyper-saillance évaluative (τ_A, τ_C bas), prior de contrôle négatif et évitement pragmatique modéré.",
                "theta": {
                    "tau_A": 0.12, "tau_C": 0.18, "lambda": 0.72, "alpha_0": 1.45,
                    "gamma_alpha": 0.58, "eta_diss": 0.22, "beta_X": 2.75, "beta_Y": 0.72,
                },
                "sds": [0.024, 0.036, 0.075, 0.22, 0.072, 0.042, 0.24, 0.11],
                "tau_corr": 0.25,
                "ctrl_mean": -0.40,
                "ctrl_sd": 0.08,
            },
            {
                "key": "specific_phobia",
                "comp_name": "specific_phobia_cue_surge",
                "display_name": "Phobie spécifique",
                "short_label": "Phobie spéc.",
                "dsm5_reference": "DSM-5 300.29 — Phobie spécifique",
                "dsm5_chapter": "Troubles anxieux",
                "hitop_spectrum": "Internalisé — Détresse & Peur",
                "color": "#f768a1",
                "desc": "Alarme phasique déclenchée par l'indice (seuils très bas) avec récupération homéostatique rapide (η_diss élevé).",
                "theta": {
                    "tau_A": 0.12, "tau_C": 0.11, "lambda": 0.44, "alpha_0": 0.50,
                    "gamma_alpha": 0.30, "eta_diss": 0.56, "beta_X": 2.40, "beta_Y": 1.35,
                },
                "sds": [0.022, 0.022, 0.075, 0.20, 0.055, 0.062, 0.20, 0.13],
                "tau_corr": 0.38,
                "ctrl_mean": -0.18,
                "ctrl_sd": 0.07,
            },
            {
                "key": "dpdr",
                "comp_name": "dpdr_central_detachment",
                "display_name": "Trouble de dépersonnalisation / déréalisation",
                "short_label": "DPDR",
                "dsm5_reference": "DSM-5 300.6 — Trouble de dépersonnalisation / déréalisation",
                "dsm5_chapter": "Troubles dissociatifs",
                "hitop_spectrum": "Détachement & Dissociation",
                "color": "#54278f",
                "desc": "Suspension centrale persistante (0,0,Z>=2) par seuils élevés et faible prise pragmatique (β_Y bas).",
                "theta": {
                    "tau_A": 0.52, "tau_C": 0.56, "lambda": 0.80, "alpha_0": 1.80,
                    "gamma_alpha": 0.42, "eta_diss": 0.16, "beta_X": 2.15, "beta_Y": 0.45,
                },
                "sds": [0.055, 0.050, 0.065, 0.22, 0.065, 0.034, 0.20, 0.070],
                "tau_corr": 0.45,
                "ctrl_mean": -0.05,
                "ctrl_sd": 0.07,
            },
            {
                "key": "somatic_symptom",
                "comp_name": "somatic_interoceptive_amplification",
                "display_name": "Trouble à symptomatologie somatique",
                "short_label": "Somatique",
                "dsm5_reference": "DSM-5 300.82 — Trouble à symptomatologie somatique",
                "dsm5_chapter": "Symptomatologie somatique",
                "hitop_spectrum": "Somatoforme & Hyperéveil",
                "color": "#bf812d",
                "desc": "Hyper-sensibilité intéroceptive de contrôle (τ_C très bas), forte inertie α_0 et inquiétude épistémique.",
                "theta": {
                    "tau_A": 0.28, "tau_C": 0.09, "lambda": 0.66, "alpha_0": 2.55,
                    "gamma_alpha": 0.48, "eta_diss": 0.15, "beta_X": 2.95, "beta_Y": 0.98,
                },
                "sds": [0.045, 0.018, 0.070, 0.22, 0.068, 0.032, 0.24, 0.12],
                "tau_corr": -0.15,
                "ctrl_mean": -0.22,
                "ctrl_sd": 0.07,
            },
            {
                "key": "anorexia_restrictive",
                "comp_name": "anorexia_rigid_overcontrol",
                "display_name": "Anorexie mentale restrictive",
                "short_label": "Anorexie",
                "dsm5_reference": "DSM-5 307.1 — Anorexie mentale, type restrictif",
                "dsm5_chapter": "Conduites alimentaires",
                "hitop_spectrum": "Compulsif & Surcontrôle",
                "color": "#3f007d",
                "desc": "Surcontrôle hiérarchique maximal (α_0=3.40, λ=0.92), biais d'illusion de contrôle et dissipation bloquée.",
                "theta": {
                    "tau_A": 0.16, "tau_C": 0.50, "lambda": 0.92, "alpha_0": 3.40,
                    "gamma_alpha": 0.58, "eta_diss": 0.11, "beta_X": 3.15, "beta_Y": 0.60,
                },
                "sds": [0.032, 0.055, 0.035, 0.18, 0.070, 0.026, 0.22, 0.095],
                "tau_corr": -0.20,
                "ctrl_mean": 0.48,
                "ctrl_sd": 0.09,
            },
            {
                "key": "bulimia_binge",
                "comp_name": "bulimia_urgency_cycling",
                "display_name": "Boulimie / Accès hyperphagiques",
                "short_label": "Boulimie",
                "dsm5_reference": "DSM-5 307.51 — Boulimie / Accès hyperphagiques",
                "dsm5_chapter": "Conduites alimentaires",
                "hitop_spectrum": "Désinhibé & Externalisé",
                "color": "#dd3497",
                "desc": "Urgence négative pragmatique (τ_C bas, λ bas, β_Y élevé) et décalage de contrôle négatif.",
                "theta": {
                    "tau_A": 0.24, "tau_C": 0.12, "lambda": 0.25, "alpha_0": 0.46,
                    "gamma_alpha": 0.38, "eta_diss": 0.30, "beta_X": 2.00, "beta_Y": 1.50,
                },
                "sds": [0.042, 0.024, 0.060, 0.20, 0.065, 0.052, 0.12, 0.10],
                "tau_corr": 0.15,
                "ctrl_mean": -0.38,
                "ctrl_sd": 0.09,
            },
            {
                "key": "insomnia_chronic",
                "comp_name": "insomnia_tonic_hyperarousal",
                "display_name": "Trouble de l'insomnie chronique",
                "short_label": "Insomnie",
                "dsm5_reference": "DSM-5 307.42 — Trouble de l'insomnie",
                "dsm5_chapter": "Sommeil-éveil",
                "hitop_spectrum": "Somatoforme & Hyperéveil",
                "color": "#8c510a",
                "desc": "Hyperéveil tonique soutenu : seuil τ_A bas empêchant l'extinction nocturne et dissipation très lente (η_diss=0.11).",
                "theta": {
                    "tau_A": 0.15, "tau_C": 0.19, "lambda": 0.68, "alpha_0": 1.20,
                    "gamma_alpha": 0.22, "eta_diss": 0.11, "beta_X": 2.65, "beta_Y": 0.95,
                },
                "sds": [0.030, 0.038, 0.072, 0.22, 0.045, 0.024, 0.22, 0.12],
                "tau_corr": 0.28,
                "ctrl_mean": 0.0,
                "ctrl_sd": 0.06,
            },
            {
                "key": "ied",
                "comp_name": "ied_acute_pragmatic_eruption",
                "display_name": "Trouble explosif intermittent",
                "short_label": "TEI",
                "dsm5_reference": "DSM-5 312.34 — Trouble explosif intermittent",
                "dsm5_chapter": "Contrôle des impulsions",
                "hitop_spectrum": "Désinhibé & Externalisé",
                "color": "#e31a1c",
                "desc": "Embrasement pragmatique explosif (τ_C minimal, γ_α élevé, λ bas) suivi d'une dissipation rapide.",
                "theta": {
                    "tau_A": 0.36, "tau_C": 0.09, "lambda": 0.14, "alpha_0": 0.36,
                    "gamma_alpha": 0.72, "eta_diss": 0.46, "beta_X": 1.92, "beta_Y": 1.62,
                },
                "sds": [0.050, 0.018, 0.045, 0.20, 0.075, 0.065, 0.08, 0.075],
                "tau_corr": -0.20,
                "ctrl_mean": 0.22,
                "ctrl_sd": 0.08,
            },
            {
                "key": "substance_use",
                "comp_name": "substance_pragmatic_capture",
                "display_name": "Trouble de l'usage de substances",
                "short_label": "Addiction",
                "dsm5_reference": "DSM-5 304.xx — Trouble de l'usage de substances",
                "dsm5_chapter": "Addictions et substances",
                "hitop_spectrum": "Désinhibé & Externalisé",
                "color": "#b15928",
                "desc": "Capture pragmatique rigide (λ bas, β_Y élevé, α_0 soutenu) et prior biaisé vers l'agence immédiate.",
                "theta": {
                    "tau_A": 0.40, "tau_C": 0.12, "lambda": 0.18, "alpha_0": 1.95,
                    "gamma_alpha": 0.36, "eta_diss": 0.20, "beta_X": 1.88, "beta_Y": 1.58,
                },
                "sds": [0.052, 0.024, 0.050, 0.22, 0.060, 0.040, 0.08, 0.080],
                "tau_corr": -0.18,
                "ctrl_mean": 0.30,
                "ctrl_sd": 0.09,
            },
            {
                "key": "szpd",
                "comp_name": "szpd_hyporeactive_detachment",
                "display_name": "Personnalité schizoïde",
                "short_label": "Pers. schizoïde",
                "dsm5_reference": "DSM-5 301.20 — Trouble de la personnalité schizoïde",
                "dsm5_chapter": "Troubles de la personnalité",
                "hitop_spectrum": "Détachement & Dissociation",
                "color": "#4393c3",
                "desc": "Détachement émotionnel filtré (τ_A, τ_C hauts), faible engagement β_Y et dissipation calme rapide.",
                "theta": {
                    "tau_A": 0.46, "tau_C": 0.60, "lambda": 0.62, "alpha_0": 1.70,
                    "gamma_alpha": 0.16, "eta_diss": 0.48, "beta_X": 1.35, "beta_Y": 0.42,
                },
                "sds": [0.052, 0.042, 0.075, 0.22, 0.038, 0.062, 0.16, 0.065],
                "tau_corr": 0.35,
                "ctrl_mean": 0.05,
                "ctrl_sd": 0.07,
            },
            {
                "key": "aspd",
                "comp_name": "aspd_hyporeactive_disinhibition",
                "display_name": "Personnalité antisociale",
                "short_label": "Pers. antisociale",
                "dsm5_reference": "DSM-5 301.7 — Trouble de la personnalité antisociale",
                "dsm5_chapter": "Troubles de la personnalité",
                "hitop_spectrum": "Désinhibé & Externalisé",
                "color": "#33a02c",
                "desc": "Hyporéactivité aux erreurs aversives (τ_A haut, λ bas), biais optimiste sur contrôle et dissipation rapide.",
                "theta": {
                    "tau_A": 0.56, "tau_C": 0.36, "lambda": 0.16, "alpha_0": 0.52,
                    "gamma_alpha": 0.14, "eta_diss": 0.56, "beta_X": 1.88, "beta_Y": 1.52,
                },
                "sds": [0.050, 0.052, 0.048, 0.20, 0.036, 0.062, 0.09, 0.095],
                "tau_corr": 0.20,
                "ctrl_mean": 0.58,
                "ctrl_sd": 0.09,
            },
            {
                "key": "avpd",
                "comp_name": "avpd_pessimistic_inhibition",
                "display_name": "Personnalité évitante",
                "short_label": "Pers. évitante",
                "dsm5_reference": "DSM-5 301.82 — Trouble de la personnalité évitante",
                "dsm5_chapter": "Troubles de la personnalité",
                "hitop_spectrum": "Internalisé — Détresse & Peur",
                "color": "#2166ac",
                "desc": "Hypersensibilité évaluative + inertie profonde α_0 + prior pessimiste marqué et effacement pragmatique (β_Y bas).",
                "theta": {
                    "tau_A": 0.14, "tau_C": 0.20, "lambda": 0.80, "alpha_0": 2.35,
                    "gamma_alpha": 0.56, "eta_diss": 0.12, "beta_X": 2.10, "beta_Y": 0.52,
                },
                "sds": [0.028, 0.040, 0.060, 0.22, 0.070, 0.028, 0.20, 0.085],
                "tau_corr": 0.22,
                "ctrl_mean": -0.62,
                "ctrl_sd": 0.09,
            },
            {
                "key": "ocpd",
                "comp_name": "ocpd_perfectionistic_overcontrol",
                "display_name": "Personnalité obsessionnelle-compulsive",
                "short_label": "POC",
                "dsm5_reference": "DSM-5 301.4 — Trouble de la personnalité obsessionnelle-compulsive",
                "dsm5_chapter": "Troubles de la personnalité",
                "hitop_spectrum": "Compulsif & Surcontrôle",
                "color": "#807dba",
                "desc": "Rigidité perfectionniste de maîtrise (α_0=3.10, λ=0.88, β_X=3.20) avec biais d'agentivité.",
                "theta": {
                    "tau_A": 0.22, "tau_C": 0.48, "lambda": 0.88, "alpha_0": 3.10,
                    "gamma_alpha": 0.30, "eta_diss": 0.28, "beta_X": 3.20, "beta_Y": 1.15,
                },
                "sds": [0.040, 0.055, 0.045, 0.20, 0.052, 0.048, 0.22, 0.13],
                "tau_corr": -0.18,
                "ctrl_mean": 0.32,
                "ctrl_sd": 0.08,
            },
        )

        extended_specs: dict[str, CohortSpec] = {}
        for row in extended_table:
            comp = MultivariatePriorComponent(
                name=row["comp_name"],
                weight=1.0,
                mean_latent=_theta_to_latent(row["theta"]),
                cov_latent=_build_scaled_covariance(
                    row["sds"],
                    tau_corr=row["tau_corr"],
                ),
                ctrl_prior_bias_mean=row["ctrl_mean"],
                ctrl_prior_bias_sd=row["ctrl_sd"],
            )
            extended_specs[row["key"]] = CohortSpec(
                key=row["key"],
                display_name=row["display_name"],
                short_label=row["short_label"],
                dsm5_reference=row["dsm5_reference"],
                functional_regime_description=row["desc"],
                color=row["color"],
                components=(comp,),
                dsm5_chapter=row["dsm5_chapter"],
                hitop_spectrum=row["hitop_spectrum"],
            )

        all_specs: dict[str, CohortSpec] = {}
        for key in FULL_DSM5_COHORT_KEYS:
            if key in base_specs:
                all_specs[key] = base_specs[key]
            else:
                all_specs[key] = extended_specs[key]
        return all_specs


# ---------------------------------------------------------------------------
# Interventions thérapeutiques mécanistes (ascendant, descendant, combiné)
# ---------------------------------------------------------------------------


class InterventionModality(str, Enum):
    """Modalités d'intervention thérapeutique dans l'espace paramétrique CARTOGRAFFECT."""

    NONE = "none"
    BOTTOM_UP_INTEROCEPTIVE = "bottom_up_interoceptive"
    TOP_DOWN_PRIOR_RELAXATION = "top_down_prior_relaxation"
    COMBINED = "combined"

    @property
    def display_name(self) -> str:
        return _MODALITY_LABELS[self]


_MODALITY_LABELS: dict[InterventionModality, str] = {
    InterventionModality.NONE: "Sans intervention",
    InterventionModality.BOTTOM_UP_INTEROCEPTIVE: "Ascendant (précision τ_A, τ_C)",
    InterventionModality.TOP_DOWN_PRIOR_RELAXATION: "Descendant (inertie α_{z≥4})",
    InterventionModality.COMBINED: "Approche combinée",
}


@dataclass(frozen=True)
class TherapeuticIntervention:
    """Modélisation computationnelle des interventions thérapeutiques sur CARTOGRAFFECT.

    Simule trois mécanismes d'action distincts (et une référence sans intervention) :
        1. ``BOTTOM_UP_INTEROCEPTIVE`` : recalibrage ascendant de la précision
           intéroceptive ``(τ_A, τ_C)`` vers la cible homéostatique ;
        2. ``TOP_DOWN_PRIOR_RELAXATION`` : réduction descendante de l'inertie des
           a priori aux strates profondes ``α_{z >= 4}`` (en laissant ``α_{z < 4}``
           strictement invariant) et atténuation des priors extrêmes de contrôle ;
        3. ``COMBINED`` : synergie des mécanismes ascendant et descendant,
           consolidant le taux de dissipation ``η_diss`` vers le Point de Veille.
    """

    modality: InterventionModality = InterventionModality.NONE
    target_tau_a: float = 0.28
    target_tau_c: float = 0.28
    bottom_up_strength: float = 0.85
    top_down_strength: float = 0.85
    top_down_decay_rate: float = 1.35
    alpha_floor: float = 1.45
    synergy_dissipation_boost: float = 0.14
    ramp_trials: int = 18

    def __post_init__(self) -> None:
        if not (0.0 < self.target_tau_a < 1.0 and 0.0 < self.target_tau_c < 1.0):
            raise ValueError("target_tau_a et target_tau_c doivent appartenir à ]0, 1[")
        if not (0.0 <= self.bottom_up_strength <= 1.0):
            raise ValueError("bottom_up_strength doit appartenir à [0, 1]")
        if not (0.0 <= self.top_down_strength <= 1.0):
            raise ValueError("top_down_strength doit appartenir à [0, 1]")
        if self.top_down_decay_rate < 0.0 or self.alpha_floor <= 0.0:
            raise ValueError("top_down_decay_rate >= 0 et alpha_floor > 0 requis")
        if self.ramp_trials < 1:
            raise ValueError("ramp_trials doit être >= 1")

    @property
    def has_bottom_up(self) -> bool:
        return self.modality in (
            InterventionModality.BOTTOM_UP_INTEROCEPTIVE,
            InterventionModality.COMBINED,
        )

    @property
    def has_top_down(self) -> bool:
        return self.modality in (
            InterventionModality.TOP_DOWN_PRIOR_RELAXATION,
            InterventionModality.COMBINED,
        )

    def effective_thresholds(
        self,
        theta: dict[str, float],
        progress: float = 1.0,
    ) -> tuple[float, float]:
        """Recalibrage ascendant de la précision intéroceptive ``(τ_A, τ_C)``."""
        tau_a = float(theta["tau_A"])
        tau_c = float(theta["tau_C"])
        if not self.has_bottom_up:
            return tau_a, tau_c
        kappa = float(np.clip(progress, 0.0, 1.0)) * self.bottom_up_strength
        eff_a = (1.0 - kappa) * tau_a + kappa * self.target_tau_a
        eff_c = (1.0 - kappa) * tau_c + kappa * self.target_tau_c
        return float(eff_a), float(eff_c)

    def effective_alpha_z(
        self,
        theta: dict[str, float],
        z: float | int,
        progress: float = 1.0,
        *,
        smooth_gate: bool = False,
    ) -> float:
        """Réduction descendante de l'inertie ``α_z`` pour ``z >= 4`` (``α_{z < 4}`` invariant)."""
        z_val = float(z)
        alpha_raw = float(theta["alpha_0"]) * math.exp(float(theta["gamma_alpha"]) * z_val)
        if not self.has_top_down:
            return float(alpha_raw)
        if not smooth_gate and z_val < 4.0:
            return float(alpha_raw)

        kappa = float(np.clip(progress, 0.0, 1.0))
        if smooth_gate:
            gate = 1.0 / (1.0 + math.exp(-max(-20.0, min(20.0, 6.0 * (z_val - 3.6)))))
            if z_val < 3.0:
                return float(alpha_raw)
            excess = max(0.25, z_val - 3.0)
        else:
            gate = 1.0
            excess = max(0.5, z_val - 3.0)

        floor_val = min(alpha_raw, self.alpha_floor)
        decay = math.exp(-kappa * self.top_down_strength * self.top_down_decay_rate * excess)
        relaxed = floor_val + (alpha_raw - floor_val) * decay
        return float((1.0 - gate) * alpha_raw + gate * relaxed)

    def effective_ctrl_prior_bias(
        self,
        ctrl_prior_bias: float,
        progress: float = 1.0,
    ) -> float:
        """Atténue la rigidité cognitive des a priori asymétriques de contrôlabilité."""
        kappa = float(np.clip(progress, 0.0, 1.0))
        if self.modality is InterventionModality.NONE:
            return float(ctrl_prior_bias)
        if self.modality is InterventionModality.BOTTOM_UP_INTEROCEPTIVE:
            return float(ctrl_prior_bias * (1.0 - 0.30 * kappa * self.bottom_up_strength))
        if self.modality is InterventionModality.TOP_DOWN_PRIOR_RELAXATION:
            return float(ctrl_prior_bias * (1.0 - 0.78 * kappa * self.top_down_strength))
        return float(
            ctrl_prior_bias
            * (1.0 - 0.92 * kappa * max(self.bottom_up_strength, self.top_down_strength))
        )

    def effective_eta_diss(
        self,
        theta: dict[str, float],
        progress: float = 1.0,
    ) -> float:
        """Taux de dissipation allostatique effectif (gain synergique sous ``COMBINED``)."""
        eta = float(theta["eta_diss"])
        if self.modality is InterventionModality.COMBINED:
            kappa = float(np.clip(progress, 0.0, 1.0))
            return float(min(0.74, eta + kappa * self.synergy_dissipation_boost))
        return eta

    def effective_bpd_instability_scale(self, progress: float = 1.0) -> float:
        """Facteur multiplicatif sur l'instabilité de précision ``Z=4,6`` (TPL)."""
        kappa = float(np.clip(progress, 0.0, 1.0))
        if self.modality is InterventionModality.NONE:
            return 1.0
        if self.modality is InterventionModality.BOTTOM_UP_INTEROCEPTIVE:
            return float(max(0.15, 1.0 - 0.58 * kappa * self.bottom_up_strength))
        if self.modality is InterventionModality.TOP_DOWN_PRIOR_RELAXATION:
            return float(max(0.15, 1.0 - 0.52 * kappa * self.top_down_strength))
        return float(max(0.08, 1.0 - 0.85 * kappa))

    def effective_ptsd_dissociation_scale(self, progress: float = 1.0) -> float:
        """Facteur multiplicatif sur la bascule dissociative (TSPT)."""
        kappa = float(np.clip(progress, 0.0, 1.0))
        if self.modality is InterventionModality.NONE:
            return 1.0
        if self.modality is InterventionModality.BOTTOM_UP_INTEROCEPTIVE:
            return float(max(0.15, 1.0 - 0.62 * kappa * self.bottom_up_strength))
        if self.modality is InterventionModality.TOP_DOWN_PRIOR_RELAXATION:
            return float(max(0.15, 1.0 - 0.55 * kappa * self.top_down_strength))
        return float(max(0.08, 1.0 - 0.88 * kappa))

    def apply_to_agent_parameters(
        self,
        params: AgentParameters,
        progress: float = 1.0,
    ) -> AgentParameters:
        """Retourne un nouvel ``AgentParameters`` reflétant l'intervention à ``progress``."""
        theta = params.theta_dict()
        eff_tau_a, eff_tau_c = self.effective_thresholds(theta, progress=progress)
        eff_eta = self.effective_eta_diss(theta, progress=progress)
        # Approximation de la réduction γ_α pour z >= 4 tout en conservant α_0 invariant
        eff_gamma = params.gamma_alpha
        if self.has_top_down:
            a4_target = self.effective_alpha_z(theta, 4, progress=progress)
            a6_target = self.effective_alpha_z(theta, 6, progress=progress)
            ratio = max(1e-6, a6_target / max(1e-6, a4_target))
            eff_gamma = float(
                max(0.02, min(params.gamma_alpha, 0.5 * math.log(ratio)))
            )
        return AgentParameters(
            tau_a=eff_tau_a,
            tau_c=eff_tau_c,
            lambda_weight=params.lambda_weight,
            alpha_0=params.alpha_0,
            gamma_alpha=eff_gamma,
            eta_diss=eff_eta,
            beta_x=params.beta_x,
            beta_y=params.beta_y,
            enforce_theoretical_constraints=params.enforce_theoretical_constraints,
        )

    @staticmethod
    def build_therapeutic_recovery_schedule(
        induction_trials: int = 80,
        exposure_trials: int = 40,
        remission_trials: int = 60,
    ) -> tuple[BlockSpec, ...]:
        """Protocole thérapeutique en 3 phases (induction -> exposition sûre -> rémission)."""
        if induction_trials < 12 or exposure_trials < 6 or remission_trials < 10:
            raise ValueError("Durées de phases insuffisantes pour le protocole thérapeutique")
        ind_blocks = _scale_block_specs(
            [
                ("tx_induction_deep_eval_d4", 0.14, 0.35, 0.45, 4, False, 24),
                ("tx_induction_volatile_threat_d3", 0.82, 0.45, 0.24, 3, False, 26),
                ("tx_induction_unctrl_loss_d3", 0.10, 0.32, 0.45, 3, False, 30),
            ],
            induction_trials,
        )
        blocks = list(ind_blocks)
        blocks.append(
            BlockSpec(
                block_id=len(blocks),
                name="tx_corrective_exposure_d2",
                num_trials=int(exposure_trials),
                p_ctrl=0.88,
                v_rule=0.06,
                cue_clarity=0.90,
                d_obj=2,
                is_remission=False,
            )
        )
        blocks.append(
            BlockSpec(
                block_id=len(blocks),
                name="tx_remission_consolidation",
                num_trials=int(remission_trials),
                p_ctrl=0.75,
                v_rule=0.05,
                cue_clarity=0.92,
                d_obj=2,
                is_remission=True,
            )
        )
        return tuple(blocks)

    @classmethod
    def simulate_paired_recovery(
        cls,
        profiles: Sequence[SyntheticAgentProfile],
        *,
        seed: int = 42,
        induction_trials: int = 80,
        exposure_trials: int = 40,
        remission_trials: int = 60,
    ) -> dict[str, Any]:
        """Compare de manière strictement appariée les 4 conditions thérapeutiques.

        Chaque agent subit exactement la même induction initiale, puis les 4 modalités
        (``NONE``, ``BOTTOM_UP_INTEROCEPTIVE``, ``TOP_DOWN_PRIOR_RELAXATION``, ``COMBINED``)
        divergent au début de la phase thérapeutique ``t = induction_trials`` sous
        la même séquence de graine aléatoire.
        """
        schedule = cls.build_therapeutic_recovery_schedule(
            induction_trials=induction_trials,
            exposure_trials=exposure_trials,
            remission_trials=remission_trials,
        )
        modalities = (
            InterventionModality.NONE,
            InterventionModality.BOTTOM_UP_INTEROCEPTIVE,
            InterventionModality.TOP_DOWN_PRIOR_RELAXATION,
            InterventionModality.COMBINED,
        )
        interventions = {m.value: cls(modality=m) for m in modalities}
        total_t = sum(b.num_trials for b in schedule)

        by_cohort: dict[str, dict[str, list[dict[str, Any]]]] = {}
        for idx, prof in enumerate(profiles):
            c_bucket = by_cohort.setdefault(
                prof.cohort_key, {m.value: [] for m in modalities}
            )
            ag_seed = seed + idx * 7
            for m_key, interv in interventions.items():
                sim_res = simulate_clinical_agent(
                    prof,
                    schedule=schedule,
                    seed=ag_seed,
                    intervention=interv,
                    intervention_start_trial=induction_trials,
                )
                tx_slice = slice(induction_trials, total_t)
                rem_slice = slice(induction_trials + exposure_trials, total_t)
                z_tx = sim_res.z_continuous[tx_slice]
                lyap_tx = sim_res.lyapunov_distance[tx_slice]
                pdv_tx = sim_res.at_pdv[tx_slice]
                pdv_rem = sim_res.at_pdv[rem_slice]

                z_init_tx = max(0.5, float(z_tx[0]))
                half_idx = np.flatnonzero(z_tx <= 0.5 * z_init_tx)
                half_life = (
                    float(half_idx[0])
                    if len(half_idx) > 0
                    else float(exposure_trials + remission_trials)
                )
                c_bucket[m_key].append(
                    {
                        "z_curve": sim_res.z_continuous,
                        "lyap_curve": sim_res.lyapunov_distance,
                        "pdv_curve": sim_res.at_pdv.astype(np.float64),
                        "end_z": float(np.mean(sim_res.z_continuous[-5:])),
                        "end_lyap": float(np.mean(sim_res.lyapunov_distance[-5:])),
                        "pdv_final_rate": float(np.mean(sim_res.at_pdv[-10:])),
                        "pdv_remission_fraction": float(np.mean(pdv_rem)),
                        "auc_z_tx": float(np.mean(z_tx)),
                        "auc_lyap_tx": float(np.mean(lyap_tx)),
                        "half_life_tx": half_life,
                        "pdv_mean_tx": float(np.mean(pdv_tx)),
                    }
                )

        summary: dict[str, Any] = {
            "total_trials": total_t,
            "induction_trials": induction_trials,
            "exposure_trials": exposure_trials,
            "remission_trials": remission_trials,
            "modalities": [m.value for m in modalities],
            "cohorts": {},
        }
        raw_p_items: list[tuple[str, str, float, dict[str, Any]]] = []

        for ckey, m_dict in by_cohort.items():
            cohort_summary: dict[str, Any] = {
                "n_agents": len(m_dict[InterventionModality.NONE.value]),
                "modalities": {},
                "paired_tests": {},
            }
            for m in modalities:
                runs = m_dict[m.value]
                z_mat = np.vstack([r["z_curve"] for r in runs])
                lyap_mat = np.vstack([r["lyap_curve"] for r in runs])
                pdv_mat = np.vstack([r["pdv_curve"] for r in runs])
                n_ag = z_mat.shape[0]
                ci_scale = 1.96 / math.sqrt(max(1, n_ag))
                cohort_summary["modalities"][m.value] = {
                    "mean_z_curve": z_mat.mean(axis=0).tolist(),
                    "ci95_z_curve": (z_mat.std(axis=0, ddof=1 if n_ag > 1 else 0) * ci_scale).tolist(),
                    "mean_lyap_curve": lyap_mat.mean(axis=0).tolist(),
                    "ci95_lyap_curve": (
                        lyap_mat.std(axis=0, ddof=1 if n_ag > 1 else 0) * ci_scale
                    ).tolist(),
                    "mean_pdv_curve": pdv_mat.mean(axis=0).tolist(),
                    "ci95_pdv_curve": (
                        pdv_mat.std(axis=0, ddof=1 if n_ag > 1 else 0) * ci_scale
                    ).tolist(),
                    "end_z_mean": float(np.mean([r["end_z"] for r in runs])),
                    "end_z_sd": float(np.std([r["end_z"] for r in runs], ddof=1 if n_ag > 1 else 0)),
                    "pdv_final_rate": float(np.mean([r["pdv_final_rate"] for r in runs])),
                    "pdv_remission_fraction": float(
                        np.mean([r["pdv_remission_fraction"] for r in runs])
                    ),
                    "auc_z_tx_mean": float(np.mean([r["auc_z_tx"] for r in runs])),
                    "auc_lyap_tx_mean": float(np.mean([r["auc_lyap_tx"] for r in runs])),
                    "half_life_tx_mean": float(np.mean([r["half_life_tx"] for r in runs])),
                }

            comparisons = (
                ("combined_vs_none_auc_lyap", InterventionModality.COMBINED.value, InterventionModality.NONE.value, "auc_lyap_tx"),
                ("combined_vs_none_pdv_rem", InterventionModality.COMBINED.value, InterventionModality.NONE.value, "pdv_remission_fraction"),
                ("bottom_up_vs_none_auc_lyap", InterventionModality.BOTTOM_UP_INTEROCEPTIVE.value, InterventionModality.NONE.value, "auc_lyap_tx"),
                ("top_down_vs_none_auc_lyap", InterventionModality.TOP_DOWN_PRIOR_RELAXATION.value, InterventionModality.NONE.value, "auc_lyap_tx"),
                ("bottom_up_vs_top_down_auc_lyap", InterventionModality.BOTTOM_UP_INTEROCEPTIVE.value, InterventionModality.TOP_DOWN_PRIOR_RELAXATION.value, "auc_lyap_tx"),
                ("combined_vs_bottom_up_auc_lyap", InterventionModality.COMBINED.value, InterventionModality.BOTTOM_UP_INTEROCEPTIVE.value, "auc_lyap_tx"),
                ("combined_vs_top_down_auc_lyap", InterventionModality.COMBINED.value, InterventionModality.TOP_DOWN_PRIOR_RELAXATION.value, "auc_lyap_tx"),
            )
            for tname, ma, mb, metric in comparisons:
                va = np.array([r[metric] for r in m_dict[ma]], dtype=np.float64)
                vb = np.array([r[metric] for r in m_dict[mb]], dtype=np.float64)
                test_res = _paired_wilcoxon_stats(va, vb)
                cohort_summary["paired_tests"][tname] = test_res
                raw_p_items.append((ckey, tname, float(test_res["p_value"]), test_res))

            summary["cohorts"][ckey] = cohort_summary

        # Correction globale de Holm-Bonferroni sur l'ensemble des tests appariés
        m_tests = len(raw_p_items)
        raw_p_items.sort(key=lambda item: item[2])
        prev_adj = 0.0
        for rank_idx, (_, _, raw_p, target_dict) in enumerate(raw_p_items):
            adj_p = min(1.0, max(prev_adj, raw_p * (m_tests - rank_idx)))
            prev_adj = adj_p
            target_dict["p_holm"] = float(adj_p)

        return summary


def _paired_wilcoxon_stats(va: np.ndarray, vb: np.ndarray) -> dict[str, Any]:
    diff = np.asarray(va, dtype=np.float64) - np.asarray(vb, dtype=np.float64)
    nonzero = diff[np.abs(diff) > 1e-12]
    if len(nonzero) == 0:
        w_stat, p_val, r_rb = 0.0, 1.0, 0.0
    else:
        res = stats.wilcoxon(diff, alternative="two-sided", zero_method="wilcox")
        w_stat = float(res.statistic)
        p_val = float(res.pvalue)
        ranks = stats.rankdata(np.abs(nonzero))
        total_rank = float(np.sum(ranks))
        w_pos = float(np.sum(ranks[nonzero > 0.0]))
        w_neg = float(np.sum(ranks[nonzero < 0.0]))
        r_rb = float((w_pos - w_neg) / max(1e-12, total_rank))
    return {
        "wilcoxon_w": w_stat,
        "p_value": p_val,
        "r_rb": r_rb,
        "mean_a": float(np.mean(va)),
        "mean_b": float(np.mean(vb)),
        "median_a": float(np.median(va)),
        "median_b": float(np.median(vb)),
    }


# ---------------------------------------------------------------------------
# Projection géométrique canonique dans Lexicon176 & simulateur unifié
# ---------------------------------------------------------------------------


def project_trajectory_to_lexicon176(
    g_a: np.ndarray,
    g_c: np.ndarray,
    z_curr: np.ndarray,
    filter_a: np.ndarray,
    filter_c: np.ndarray,
    obs_calm: np.ndarray,
    lam: float,
    *,
    ema_x: np.ndarray | None = None,
    ema_y: np.ndarray | None = None,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """Projette une trajectoire continue vers des coordonnées exactes de ``Lexicon176``.

    Garantit pour 100 % des pas temporels ``t`` que ``CoreAffectPoint(xs[t], ys[t], zs[t])``
    appartient à ``ENTRY_BY_POINT`` et respecte ``|X| + |Y| = 2Z - 2`` en périphérie.
    """
    t_len = len(z_curr)
    xs = np.zeros(t_len, dtype=np.int32)
    ys = np.zeros(t_len, dtype=np.int32)
    zs = np.zeros(t_len, dtype=np.int32)
    state_indices = np.zeros(t_len, dtype=np.int32)

    idx_by_pt = get_state_index_by_point()

    for t in range(t_len):
        zc = float(z_curr[t])
        fa = float(filter_a[t]) > 0.5
        fc = float(filter_c[t]) > 0.5
        calm = float(obs_calm[t]) > 0.5

        if (zc < 0.65 and not fa and not fc) or (calm and zc < 0.55):
            pt = CoreAffectPoint(0, 0, 0)
        else:
            zi = int(min(7, max(0, round(zc))))
            if zi == 0:
                pt = CoreAffectPoint(0, 0, 0)
            elif zi == 1 or (not fa and not fc):
                pt = CoreAffectPoint(0, 0, zi)
            else:
                radius = 2 * zi - 2
                vx = float(ema_x[t]) if (ema_x is not None and abs(float(ema_x[t])) > 1e-6) else float(g_a[t])
                vy = float(ema_y[t]) if (ema_y is not None and abs(float(ema_y[t])) > 1e-6) else float(g_c[t])
                sx = 1 if vx >= 0.0 else -1
                sy = 1 if vy >= 0.0 else -1
                if fa and not fc:
                    pt = CoreAffectPoint(sx * radius, 0, zi)
                elif fc and not fa:
                    pt = CoreAffectPoint(0, sy * radius, zi)
                else:
                    dx_raw = min(float(radius), 1.85 * abs(float(g_a[t])) * float(radius))
                    dy_raw = min(float(radius), 1.85 * abs(float(g_c[t])) * float(radius))
                    dx_b, dy_b = apply_budget_constraint(dx_raw, dy_raw, float(radius), lam)
                    pi_a = max(1, int(round(100.0 * max(dx_b, abs(vx)))))
                    pi_c = max(1, int(round(100.0 * max(dy_b, abs(vy)))))
                    ax, ay = apportion_ray(zi - 2, pi_a, pi_c)
                    pt = CoreAffectPoint(sx * ax, sy * ay, zi)

        if pt not in ENTRY_BY_POINT:
            raise AssertionError(f"Point projeté invalide hors Lexicon176 : {pt!r}")

        xs[t] = pt.x
        ys[t] = pt.y
        zs[t] = pt.z
        state_indices[t] = idx_by_pt[pt]

    return xs, ys, zs, state_indices


@dataclass(frozen=True)
class ClinicalSimulationResult:
    """Résultat complet d'une simulation clinique individuelle sur ``GenerativeProcess``."""

    profile: SyntheticAgentProfile
    dataset: RecoveryDataset
    xs: np.ndarray
    ys: np.ndarray
    zs: np.ndarray
    state_indices: np.ndarray
    z_continuous: np.ndarray
    g_a_trace: np.ndarray
    g_c_trace: np.ndarray
    lyapunov_distance: np.ndarray
    at_pdv: np.ndarray
    summary_metrics: dict[str, Any]


def simulate_clinical_agent(
    profile: SyntheticAgentProfile,
    *,
    schedule: tuple[BlockSpec, ...] | None = None,
    num_trials: int = 280,
    seed: int = 42,
    intervention: TherapeuticIntervention | None = None,
    intervention_start_trial: int = 0,
) -> ClinicalSimulationResult:
    """Simule un agent issu de ``DSM5PriorBank`` sur le ``GenerativeProcess`` orthogonal.

    Garantit zéro lecture des attributs cachés de bloc (``is_remission``, ``d_obj``)
    via ``sensory_payload()`` uniquement, et intègre :
        - La dynamique canonique ``M1_CARTOGRAFFECT`` (incluant ``ctrl_prior_bias``) ;
        - La modulation bimodale hypervigilance/dissociation pour le TSPT ;
        - L'instabilité de précision aux strates ``Z=4`` et ``Z=6`` pour le TPL ;
        - L'application causale progressive de ``TherapeuticIntervention``.
    """
    sched = (
        build_dsm5_phenotyping_schedule(num_trials)
        if schedule is None
        else schedule
    )
    env = NonStationaryBanditEnv(schedule=sched, seed=seed)
    env.reset()
    rng = np.random.default_rng(seed + 991)
    t_len = env.total_trials

    th = profile.theta
    lam = float(th["lambda"])
    beta_x = float(th["beta_X"])
    beta_y = float(th["beta_Y"])

    gamma_choice = 3.0
    kappa_filter = 12.0
    sigma_ema = 0.14

    ctrl_bias_base = float(profile.ctrl_prior_bias)
    q_rule = 0.5
    q_ctrl = float(np.clip(0.5 + 0.25 * ctrl_bias_base, 0.1, 0.9))
    u_ep = 0.43
    p_load = 0.0
    g_a = 0.0
    g_c = 0.0
    z_curr = 2.0
    neutral_streak = 0

    cues = np.zeros(t_len, dtype=np.int32)
    actions = np.zeros(t_len, dtype=np.int32)
    outcomes = np.zeros(t_len, dtype=np.int32)
    seq_err_arr = np.zeros(t_len, dtype=np.float32)
    eval_bad_arr = np.zeros(t_len, dtype=np.float32)
    obs_calm_arr = np.zeros(t_len, dtype=np.float32)
    filter_a = np.zeros(t_len, dtype=np.float32)
    filter_c = np.zeros(t_len, dtype=np.float32)
    ema_x = np.zeros(t_len, dtype=np.float32)
    ema_y = np.zeros(t_len, dtype=np.float32)
    z_trace = np.zeros(t_len, dtype=np.float32)
    ga_trace = np.zeros(t_len, dtype=np.float32)
    gc_trace = np.zeros(t_len, dtype=np.float32)

    is_rem_truth = np.zeros(t_len, dtype=bool)
    jumps_z46: list[float] = []
    jumps_z23: list[float] = []
    prev_g = (0.0, 0.0)

    for t in range(t_len):
        active_tx = (
            intervention is not None
            and intervention.modality is not InterventionModality.NONE
            and t >= intervention_start_trial
        )
        progress = (
            min(1.0, (t - intervention_start_trial + 1) / float(intervention.ramp_trials))
            if active_tx and intervention is not None
            else 0.0
        )

        if active_tx and intervention is not None:
            tau_a_base, tau_c_base = intervention.effective_thresholds(th, progress)
            eta_diss_eff = intervention.effective_eta_diss(th, progress)
            ctrl_bias_eff = intervention.effective_ctrl_prior_bias(ctrl_bias_base, progress)
            bpd_scale = intervention.effective_bpd_instability_scale(progress)
            ptsd_scale = intervention.effective_ptsd_dissociation_scale(progress)
        else:
            tau_a_base, tau_c_base = float(th["tau_A"]), float(th["tau_C"])
            eta_diss_eff = float(th["eta_diss"])
            ctrl_bias_eff = ctrl_bias_base
            bpd_scale = 1.0
            ptsd_scale = 1.0

        pre_obs = env.current_observation()
        cue_t = int(pre_obs.sensory_payload()["cue"])
        cues[t] = cue_t

        # 1. Croyance pré-décision & choix sous énergie libre attendue G(π)
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
        h_rule_pre = -(
            p_rc * math.log(p_rc) + (1.0 - p_rc) * math.log(1.0 - p_rc)
        ) / math.log(2.0)
        is_amb = 1.0 if cue_t == 2 else 0.0
        ep_vals = np.array(
            [
                0.12 * h_rule_pre * q_ctrl,
                0.12 * h_rule_pre * q_ctrl,
                0.85 * h_rule_pre + 0.35 * is_amb,
            ],
            dtype=np.float64,
        )
        pr_a = (2.0 * q_rule_pre - 1.0) * (0.25 + 0.75 * q_ctrl)
        pr_vals = np.array([pr_a, -pr_a, 0.0], dtype=np.float64)
        logits = gamma_choice * (beta_x * ep_vals + beta_y * pr_vals)
        logits -= np.max(logits)
        probs_u = np.exp(logits)
        probs_u /= np.sum(probs_u)
        act_t = int(rng.choice(3, p=probs_u))
        actions[t] = act_t

        # 2. Interaction en boucle fermée avec GenerativeProcess via sensory_payload()
        step_res = env.step(BanditAction(act_t))
        is_rem_truth[t] = bool(step_res.ground_truth.is_remission)
        payload = step_res.observation.sensory_payload()
        out_t = (
            1
            if payload["outcome"] == OutcomeValence.POSITIVE
            else (2 if payload["outcome"] == OutcomeValence.NEGATIVE else 0)
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

        # Détection purement sensorielle du calme (aucune lecture de is_remission)
        if out_t != 0:
            neutral_streak = 0
            calm_t = 0.0
        else:
            if act_t != 2:
                neutral_streak += 1
            calm_t = 1.0 if neutral_streak >= 2 else 0.0
        obs_calm_arr[t] = calm_t

        # 3. Filtre bayésien des croyances de tâche (règle et contrôlabilité)
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

        p_stay_h = float(np.clip(0.95 + 0.045 * ctrl_bias_eff, 0.65, 0.995))
        p_jump_h = float(
            np.clip(
                0.05 + 0.25 * max(0.0, ctrl_bias_eff) - 0.04 * max(0.0, -ctrl_bias_eff),
                0.005,
                0.45,
            )
        )
        prior_c = float(np.clip(p_stay_h * q_ctrl + p_jump_h * (1.0 - q_ctrl), 0.01, 0.99))
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
        kl_rule = qr_c * math.log(qr_c / pr_c) + (1.0 - qr_c) * math.log(
            (1.0 - qr_c) / (1.0 - pr_c)
        )
        h_rule = -(
            qr_c * math.log(qr_c) + (1.0 - qr_c) * math.log(1.0 - qr_c)
        ) / math.log(2.0)

        ep_inst = 0.90 * kl_rule + 0.55 * h_rule + 0.55 * is_amb
        if calm_t > 0.5:
            u_ep = 0.78 * u_ep + 0.22 * 0.43
        else:
            u_ep = 0.78 * u_ep + 0.22 * ep_inst
        raw_ga = float(np.clip(4.2 * (0.43 - u_ep), -1.0, 1.0))

        out_s = 0.45 if out_t == 1 else (-0.55 if out_t == 2 else 0.0)
        raw_gc = float(
            np.clip(2.4 * (q_ctrl - 0.50) + out_s + 0.40 * ctrl_bias_eff, -1.0, 1.0)
        )

        aversive_drive = (
            (0.75 + 1.10 * seq_err_t if out_t == 2 else 0.0)
            + (min(1.10, 1.80 * kl_rule) if kl_rule > 0.12 else 0.0)
            + 0.55 * is_amb
            + 1.60 * eval_bad_t
        )
        # 4. Inertie hiérarchique α_z, modulation thérapeutique & régimes TSPT / TPL
        alpha_raw_z = float(th["alpha_0"]) * math.exp(
            float(th["gamma_alpha"]) * min(7.0, max(0.0, z_curr))
        )
        if active_tx and intervention is not None:
            alpha_z = intervention.effective_alpha_z(
                th, z_curr, progress=progress, smooth_gate=False
            )
        else:
            alpha_z = alpha_raw_z
        alpha_z = min(500.0, max(0.05, alpha_z))
        plasticity = 1.0 / (1.0 + 0.35 * alpha_z)
        eta_eff = float(np.clip(eta_diss_eff / (1.0 + 0.18 * alpha_z), 0.005, 1.0))

        # Recalibrage des composantes d'entretien de la charge lors de l'intervention active
        if active_tx and intervention is not None:
            if intervention.has_bottom_up:
                # L'ajustement ascendant de (τ_A, τ_C) réduit l'amplification des erreurs sous-seuil
                sub_a = max(0.0, 1.0 - abs(raw_ga) / max(0.08, tau_a_base))
                sub_c = max(0.0, 1.0 - abs(raw_gc) / max(0.08, tau_c_base))
                quiet_gate = 0.5 * (sub_a + sub_c)
                aversive_drive *= 1.0 - 0.38 * progress * intervention.bottom_up_strength * (0.3 + 0.7 * quiet_gate)
            if intervention.has_top_down and z_curr >= 4.0:
                # La relaxation descendante des a priori profonds α_{z>=4} désamorce la rumination
                rel_drop = max(0.0, 1.0 - alpha_z / max(1e-6, alpha_raw_z))
                aversive_drive *= 1.0 - 0.55 * progress * intervention.top_down_strength * rel_drop

        if calm_t > 0.5:
            p_load = max(0.0, p_load * (1.0 - eta_diss_eff))
        else:
            p_load = min(5.0, max(0.0, 0.88 * p_load + 0.55 * aversive_drive))

        # Noyau d'instabilité de précision TPL localisé autour des strates Z=4 et Z=6
        bpd_sigma = float(profile.bpd_z4_z6_instability_sigma) * bpd_scale
        w_bpd = (
            (
                math.exp(-((z_curr - 4.0) ** 2) / 0.35)
                + math.exp(-((z_curr - 6.0) ** 2) / 0.35)
            )
            if bpd_sigma > 0.0
            else 0.0
        )

        if calm_t > 0.5:
            g_a *= 1.0 - eta_eff
            g_c *= 1.0 - eta_eff
            z_curr *= 1.0 - eta_eff
        else:
            g_a = (1.0 - plasticity) * g_a + plasticity * raw_ga
            g_c = (1.0 - plasticity) * g_c + plasticity * raw_gc
            if w_bpd > 0.05:
                g_a = float(np.clip(g_a + rng.normal(0.0, bpd_sigma * w_bpd), -1.0, 1.0))
                g_c = float(np.clip(g_c + rng.normal(0.0, bpd_sigma * w_bpd), -1.0, 1.0))
            tgt_z = min(6.60, max(1.35, 1.35 + 1.15 * p_load))
            if intervention is not None and tgt_z < z_curr:
                step_rate = 0.18 / (1.0 + 0.06 * alpha_z)
            else:
                step_rate = 0.18
            z_curr = min(6.6, max(1.0, (1.0 - step_rate) * z_curr + step_rate * tgt_z))

        # 5. Sondes EMA à double seuil (avec bascule TSPT et jitter TPL en Z=4,6)
        tau_a_eff, tau_c_eff = tau_a_base, tau_c_base
        if profile.ptsd_bimodal_modulation:
            if z_curr >= profile.dissociation_z_threshold:
                shift = 0.32 * ptsd_scale
                tau_a_eff = min(0.75, tau_a_base + shift)
                tau_c_eff = min(0.75, tau_c_base + shift)
            elif kl_rule > 0.35:
                tau_a_eff = max(0.06, tau_a_base - 0.10 * ptsd_scale)

        if w_bpd > 0.05:
            tau_a_eff = float(
                np.clip(tau_a_eff + rng.normal(0.0, 0.14 * bpd_sigma * w_bpd), 0.05, 0.70)
            )
            tau_c_eff = float(
                np.clip(tau_c_eff + rng.normal(0.0, 0.14 * bpd_sigma * w_bpd), 0.05, 0.70)
            )

        p_fa = 1.0 / (
            1.0 + math.exp(-max(-30.0, min(30.0, kappa_filter * (abs(g_a) - tau_a_eff))))
        )
        p_fc = 1.0 / (
            1.0 + math.exp(-max(-30.0, min(30.0, kappa_filter * (abs(g_c) - tau_c_eff))))
        )
        fa = 1.0 if rng.random() < p_fa else 0.0
        fc = 1.0 if rng.random() < p_fc else 0.0

        # Pendant une thérapie active, l'absence de saillance intéroceptive en exposition sûre
        # ou la levée d'inertie profonde facilite la résorption allostatique vers le Point de Veille
        if active_tx and intervention is not None and calm_t < 0.5:
            if fa < 0.5 and fc < 0.5 and out_t != 2:
                boost = 0.45 * progress * (
                    intervention.bottom_up_strength
                    if intervention.has_bottom_up
                    else 0.35 * intervention.top_down_strength
                )
                z_curr = max(0.0, z_curr * (1.0 - eta_eff * (1.0 + boost)))
                p_load = max(0.0, p_load * (1.0 - 0.12 * progress))
            elif intervention.has_top_down and z_curr >= 4.0 and out_t != 2:
                rel_drop = max(0.0, 1.0 - alpha_z / max(1e-6, alpha_raw_z))
                z_curr = max(0.0, z_curr * (1.0 - 0.08 * progress * intervention.top_down_strength * rel_drop))
                p_load = max(0.0, p_load * (1.0 - 0.10 * progress * rel_drop))

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
        ga_trace[t] = g_a
        gc_trace[t] = g_c

        z_round = int(min(7, max(0, round(z_curr))))
        jump = math.hypot(g_a - prev_g[0], g_c - prev_g[1])
        if z_round in (4, 6):
            jumps_z46.append(jump)
        elif z_round in (2, 3):
            jumps_z23.append(jump)
        prev_g = (g_a, g_c)

    dataset = RecoveryDataset(
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

    xs, ys, zs, state_indices = project_trajectory_to_lexicon176(
        ga_trace,
        gc_trace,
        z_trace,
        filter_a,
        filter_c,
        obs_calm_arr,
        lam,
        ema_x=ema_x,
        ema_y=ema_y,
    )
    lyap_dist = np.array(
        [
            float(dissipation_potential(CoreAffectPoint(int(xs[t]), int(ys[t]), int(zs[t]))))
            for t in range(t_len)
        ],
        dtype=np.float64,
    )
    at_pdv = (xs == 0) & (ys == 0) & (zs == 0)

    stress_mask = ~is_rem_truth
    rem_mask = is_rem_truth & (np.arange(t_len) >= 12)
    env_summary = env.summarize()

    non_pdv_labels = [
        ENTRY_BY_POINT[CoreAffectPoint(int(xs[t]), int(ys[t]), int(zs[t]))].label
        for t in range(t_len)
        if not at_pdv[t]
    ]
    if non_pdv_labels:
        dom_label = Counter(non_pdv_labels).most_common(1)[0][0]
        dom_idx = next(
            int(state_indices[t])
            for t in range(t_len)
            if not at_pdv[t]
            and ENTRY_BY_POINT[CoreAffectPoint(int(xs[t]), int(ys[t]), int(zs[t]))].label
            == dom_label
        )
    else:
        dom_label = "Point de Veille"
        dom_idx = 0

    switches = int(np.sum(state_indices[1:] != state_indices[:-1]))
    ratio_z46 = (
        float(np.mean(jumps_z46)) / max(1e-4, float(np.mean(jumps_z23)))
        if (jumps_z46 and jumps_z23)
        else 1.0
    )

    summary_metrics = {
        "mean_x": float(np.mean(xs)),
        "mean_y": float(np.mean(ys)),
        "mean_z": float(np.mean(zs)),
        "mean_z_stress": float(np.mean(zs[stress_mask])) if np.any(stress_mask) else float(np.mean(zs)),
        "mean_z_remission": float(np.mean(zs[rem_mask])) if np.any(rem_mask) else float(np.mean(zs)),
        "pdv_fraction_session": float(np.mean(at_pdv)),
        "pdv_fraction_remission": float(np.mean(at_pdv[rem_mask])) if np.any(rem_mask) else float(np.mean(at_pdv)),
        "probe_rate": float(np.mean(actions == int(BanditAction.PROBE_CUE))),
        "accuracy_non_remission": float(env_summary.get("accuracy_non_remission", 0.0)),
        "state_switch_rate": float(switches / max(1, t_len - 1)),
        "z4_z6_instability_ratio": float(ratio_z46),
        "central_suspension_rate": float(np.mean((xs == 0) & (ys == 0) & (zs >= 2))),
        "quadrant_pos_y": float(np.mean(ys > 0)),
        "quadrant_neg_neg": float(np.mean((xs < 0) & (ys < 0))),
        "quadrant_neg_pos": float(np.mean((xs < 0) & (ys > 0))),
        "quadrant_pos_pos": float(np.mean((xs > 0) & (ys > 0))),
        "dominant_state_index": int(dom_idx),
        "dominant_label": dom_label,
    }

    return ClinicalSimulationResult(
        profile=profile,
        dataset=dataset,
        xs=xs,
        ys=ys,
        zs=zs,
        state_indices=state_indices,
        z_continuous=z_trace.astype(np.float64),
        g_a_trace=ga_trace.astype(np.float64),
        g_c_trace=gc_trace.astype(np.float64),
        lyapunov_distance=lyap_dist,
        at_pdv=at_pdv,
        summary_metrics=summary_metrics,
    )


# ---------------------------------------------------------------------------
# Inversion bayésienne vectorisée NumPyro SVI (aveugle à l'étiquette de cohorte)
# ---------------------------------------------------------------------------


def _compute_clinical_log_likelihood_jax(
    tau_a: jax.Array,
    tau_c: jax.Array,
    lam: jax.Array,
    alpha_0: jax.Array,
    gamma_alpha: jax.Array,
    eta_diss: jax.Array,
    beta_x: jax.Array,
    beta_y: jax.Array,
    ctrl_prior_bias: jax.Array,
    data: dict[str, jax.Array],
    *,
    gamma_choice: float = 3.0,
    kappa_filter: float = 12.0,
    sigma_ema: float = 0.14,
) -> jax.Array:
    """Vraisemblance différentiable ``M1`` généralisée au prior asymétrique ``B_ctrl``."""
    t_len = data["cues"].shape[0]
    q_ctrl0 = jnp.clip(0.5 + 0.25 * ctrl_prior_bias, 0.1, 0.9)
    init_carry = (
        jnp.asarray(0.5, dtype=jnp.float32),
        q_ctrl0,
        jnp.asarray(0.43, dtype=jnp.float32),
        jnp.asarray(0.0, dtype=jnp.float32),
        jnp.asarray(0.0, dtype=jnp.float32),
        jnp.asarray(0.0, dtype=jnp.float32),
        jnp.asarray(2.0, dtype=jnp.float32),
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
    p_stay_h = jnp.clip(0.95 + 0.045 * ctrl_prior_bias, 0.65, 0.995)
    p_jump_h = jnp.clip(
        0.05
        + 0.25 * jnp.maximum(0.0, ctrl_prior_bias)
        - 0.04 * jnp.maximum(0.0, -ctrl_prior_bias),
        0.005,
        0.45,
    )

    def scan_fn(carry: tuple[jax.Array, ...], x: tuple[jax.Array, ...]):
        q_rule, q_ctrl, u_ep, p_load, g_a, g_c, z_curr = carry
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

        ep_vals, pr_vals = _compute_choice_values_jax(q_rule_pre, q_ctrl, cue_t)
        logits_u = gamma_choice * (beta_x * ep_vals + beta_y * pr_vals)
        logp_u = jax.nn.log_softmax(logits_u)[act_t]

        is_probe = act_t == 2
        p_pos_match = 0.5 + 0.37 * q_ctrl
        l_r0 = jnp.where(
            is_probe | (out_t == 0),
            1.0,
            jnp.where(
                out_t == 1,
                jnp.where(act_t == 0, p_pos_match, 1.0 - p_pos_match),
                jnp.where(act_t == 0, 1.0 - p_pos_match, p_pos_match),
            ),
        )
        l_r1 = jnp.where(
            is_probe | (out_t == 0),
            1.0,
            jnp.where(
                out_t == 1,
                jnp.where(act_t == 1, p_pos_match, 1.0 - p_pos_match),
                jnp.where(act_t == 1, 1.0 - p_pos_match, p_pos_match),
            ),
        )
        u0 = u_pre[0] * l_r0
        u1 = u_pre[1] * l_r1
        q_rule_post = u0 / jnp.maximum(1e-8, u0 + u1)

        prior_c = jnp.clip(p_stay_h * q_ctrl + p_jump_h * (1.0 - q_ctrl), 0.01, 0.99)
        p_conf = jnp.where(act_t == 0, q_rule_pre, 1.0 - q_rule_pre)
        l_high = jnp.where(
            is_probe | (out_t == 0),
            1.0,
            jnp.where(out_t == 1, 0.08 + 0.79 * p_conf, 0.87 - 0.79 * p_conf),
        )
        l_low = jnp.where(
            is_probe | (out_t == 0),
            1.0,
            jnp.where(out_t == 1, 0.45 + 0.05 * p_conf, 0.50 - 0.05 * p_conf),
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
            calm_t > 0.5,
            0.78 * u_ep + 0.22 * 0.43,
            0.78 * u_ep + 0.22 * ep_inst,
        )
        raw_ga = jnp.clip(4.2 * (0.43 - u_ep_next), -1.0, 1.0)
        out_s = jnp.where(
            out_t == 1,
            0.45,
            jnp.where(out_t == 2, -0.55, 0.0),
        )
        raw_gc = jnp.clip(
            2.4 * (q_ctrl_post - 0.50) + out_s + 0.40 * ctrl_prior_bias,
            -1.0,
            1.0,
        )

        is_neg = (out_t == 2).astype(jnp.float32)
        aversive_drive = (
            is_neg * (0.75 + 1.10 * seq_t)
            + jnp.where(kl_rule > 0.12, jnp.minimum(1.10, 1.80 * kl_rule), 0.0)
            + 0.55 * is_ambig
            + 1.60 * eval_t
        )
        p_load_active = jnp.clip(0.88 * p_load + 0.55 * aversive_drive, 0.0, 5.0)
        p_load_next = jnp.where(
            calm_t > 0.5,
            jnp.maximum(0.0, p_load * (1.0 - eta_diss)),
            p_load_active,
        )

        alpha_z = jnp.clip(
            alpha_0 * jnp.exp(gamma_alpha * jnp.clip(z_curr, 0.0, 7.0)),
            0.05,
            500.0,
        )
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

        p_fa = jnp.clip(
            jax.nn.sigmoid(kappa_filter * (jnp.abs(g_a_next) - tau_a)),
            1e-4,
            1.0 - 1e-4,
        )
        p_fc = jnp.clip(
            jax.nn.sigmoid(kappa_filter * (jnp.abs(g_c_next) - tau_c)),
            1e-4,
            1.0 - 1e-4,
        )
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
        next_carry = (
            q_rule_post,
            q_ctrl_post,
            u_ep_next,
            p_load_next,
            g_a_next,
            g_c_next,
            z_next,
        )
        return next_carry, ll_t

    _, ll_seq = jax.lax.scan(scan_fn, init_carry, xs, length=t_len)
    return ll_seq


def build_clinical_numpyro_model():
    """Construit le modèle NumPyro neutre (sans fuite de cohorte) pour l'inversion clinique."""

    def clinical_numpyro_model(data: dict[str, jax.Array]) -> None:
        tau_a = numpyro.sample("tau_A", dist.Uniform(0.05, 0.72))
        tau_c = numpyro.sample("tau_C", dist.Uniform(0.05, 0.72))
        lam = numpyro.sample("lambda", dist.Uniform(0.0, 1.0))

        log_alpha_mid = numpyro.sample("log_alpha_mid", dist.Normal(1.3, 1.3))
        gamma_alpha = numpyro.sample("gamma_alpha", dist.Uniform(0.05, 1.05))
        alpha_0 = numpyro.deterministic(
            "alpha_0", jnp.exp(log_alpha_mid - 3.5 * gamma_alpha)
        )
        eta_diss = numpyro.sample("eta_diss", dist.Uniform(0.05, 0.75))

        beta_y = numpyro.sample("beta_Y", dist.Uniform(0.25, 1.85))
        delta_beta = numpyro.sample("delta_beta", dist.Uniform(0.15, 3.20))
        beta_x = numpyro.deterministic("beta_X", beta_y + delta_beta)

        ctrl_prior_bias = numpyro.sample("ctrl_prior_bias", dist.Uniform(-1.0, 1.0))

        ll_seq = _compute_clinical_log_likelihood_jax(
            tau_a,
            tau_c,
            lam,
            alpha_0,
            gamma_alpha,
            eta_diss,
            beta_x,
            beta_y,
            ctrl_prior_bias,
            data,
        )
        numpyro.deterministic("ll_pointwise", ll_seq)
        numpyro.factor("obs_ll", jnp.sum(ll_seq))

    return clinical_numpyro_model


_CLINICAL_SVI_KERNEL_CACHE: dict[tuple[int, int, float, int], Any] = {}


def _get_clinical_svi_kernel(
    num_steps: int,
    num_posterior_samples: int,
    lr: float,
    seq_len: int,
):
    key = (int(num_steps), int(num_posterior_samples), float(lr), int(seq_len))
    cached = _CLINICAL_SVI_KERNEL_CACHE.get(key)
    if cached is not None:
        return cached

    @jax.jit
    def _invert_batch(rng_keys: jax.Array, data_batch: dict[str, jax.Array]):
        def single(k: jax.Array, d: dict[str, jax.Array]):
            model = build_clinical_numpyro_model()
            guide = AutoMultivariateNormal(model)
            svi = SVI(model, guide, numpyro.optim.Adam(step_size=lr), Trace_ELBO())
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

    _CLINICAL_SVI_KERNEL_CACHE[key] = _invert_batch
    return _invert_batch


def invert_clinical_batch_svi(
    datasets: Sequence[RecoveryDataset],
    *,
    seed: int = 42,
    num_steps: int = 750,
    num_posterior_samples: int = 150,
    lr: float = 0.025,
    batch_size: int = 80,
) -> list[dict[str, Any]]:
    """Inverse un lot de ``RecoveryDataset`` par NumPyro SVI (strictement aveugle aux cohortes)."""
    if not datasets:
        return []
    seq_len = int(len(datasets[0].cues))
    _invert_batch = _get_clinical_svi_kernel(num_steps, num_posterior_samples, lr, seq_len)
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
                CLINICAL_NUM_FREE_PARAMS,
                n_obs=chunk[i].num_active_scalar_obs,
            )
            means: dict[str, float] = {}
            sds: dict[str, float] = {}
            ci95: dict[str, tuple[float, float]] = {}
            for pname in CLINICAL_SVI_PARAM_NAMES:
                vals = np.asarray(sub_samples[pname], dtype=np.float64).reshape(-1)
                means[pname] = float(np.mean(vals))
                sds[pname] = float(np.std(vals, ddof=1 if len(vals) > 1 else 0))
                lo, hi = np.percentile(vals, [2.5, 97.5])
                ci95[pname] = (float(lo), float(hi))
            results.append(
                {
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


__all__ = [
    "CLINICAL_NUM_FREE_PARAMS",
    "CLINICAL_SVI_PARAM_NAMES",
    "COHORT_KEYS",
    "FULL_DSM5_COHORT_KEYS",
    "LATENT_PARAM_ORDER",
    "PARAMETER_BOUNDS",
    "ClinicalSimulationResult",
    "CohortSpec",
    "DSM5FullNosologyPriorBank",
    "DSM5PriorBank",
    "GenerativeProcess",
    "InterventionModality",
    "MultivariatePriorComponent",
    "SyntheticAgentProfile",
    "TherapeuticIntervention",
    "build_clinical_numpyro_model",
    "build_dsm5_phenotyping_schedule",
    "invert_clinical_batch_svi",
    "project_trajectory_to_lexicon176",
    "simulate_clinical_agent",
]
