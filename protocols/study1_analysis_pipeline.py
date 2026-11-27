#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""
study1_analysis_pipeline.py — Preregistered Analysis Pipeline for Study 1 (OSF / Stage 1 RR)
=============================================================================================

STATUT ÉPISTÉMIQUE STRICT (`V3 = 0` avant collecte humaine) :
    Ce script est le pipeline d'analyse confirmatoire prêt à être gelé sur OSF
    (https://osf.io/z89sg) AVANT toute collecte de données humaines.
    En mode `--dry-run`, il s'exécute exclusivement sur deux jeux pilotes simulés
    explicitement labellisés `pilot_pipeline_dry_run` (`V3 = 0`) afin de vérifier
    à la fois :
      1. la capacité de corroboration sous un processus générateur CARTOGRAFFECT v3.0 ;
      2. la capacité de RÉFUTATION EFFECTIVE sous un processus générateur rival
         (Russell L2 p=2, inversion centrale pure sans échange |X|<->|Y|, couplage Y/A).

Alignement strict sur `DECISIONS_V3.md` et le commit `66d9a0d` :
    - Option 1A : Y = contrôlabilité instrumentale stricte ; A >= 0 canal autonome.
    - Bijection 2x2 de Rolls bornée à Z = 2 (`Rew+` Désir, `Rew-` Colère, `Pun+` Dégoût,
      `Pun-` Calme — prototype canonique sans qualificatif additionnel).
    - Géométrie en couches planes à surface remplie |x| + |y| <= R(Z) (A=1 périmètre,
      A<1 surface intérieure).
    - Tableau 1b en 17 sous-secteurs (1 centre fixe + 8 paires antagonistes conjuguées
      A1, A2, D1, D2, L1, L2, L3, L4 avec échange |X| <-> |Y| découplé de A' = A).
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
import math
import platform
from pathlib import Path
import time
from typing import Any

import numpy as np
import pandas as pd
import scipy
from scipy import integrate, optimize, special, stats


# =============================================================================
# 1. DÉFINITION NORMATIVE DU TABLEAU 1b (17 SOUS-SECTEURS, Z = 2..5) & ROLLS Z=2
# =============================================================================

CANONICAL_Z2_PROTOTYPES: tuple[str, ...] = (
    "Désir",
    "Colère",
    "Dégoût",
    "Calme",
    "Joie",
    "Tristesse",
    "Courage",
    "Peur",
)

ROLLS_EXPECTED_MAP: dict[str, str] = {
    "Rew+": "Désir",
    "Rew-": "Colère",
    "Pun+": "Dégoût",
    "Pun-": "Calme",
}

ROLLS_EXPECTED_SIGNS: dict[str, tuple[int, int]] = {
    "Rew+": (+1, +1),
    "Rew-": (-1, +1),
    "Pun+": (-1, -1),
    "Pun-": (+1, -1),
}


@dataclass(frozen=True)
class Table1bLandmark:
    """Repère du Tableau 1b (Z = 2..5) aligné sur les 17 FunctionalSubsector Lean 4."""

    item_id: str
    pair_code: str          # A1, A2, D1, D2, L1, L2, L3, L4, CENTER
    pole_side: str          # first, second, center
    subsector_lean: str
    z_stratum: int
    radial_tier: str        # perimeter_A_high, interior_A_low, center
    label_fr: str
    label_en: str
    semantic_group: str     # aversive_low_control, agentic_opposition, accommodative_low_control, positive_mastery, neutral_center, other
    ux_theory: float        # composante directionnelle X sur L1 unitaire (|ux|+|uy| = 1 hors centre)
    uy_theory: float        # composante directionnelle Y sur L1 unitaire
    a_theory: float         # niveau d'activation autonome théorique A in (0, 1]


def build_table1b_design() -> list[Table1bLandmark]:
    """Construit la table complète des repères du Tableau 1b testés en aveugle en Étude 1.

    Couvre exactement :
      - Les 8 prototypes canoniques de Z = 2 + centre Anticipation (0,0,2) ;
      - Les 8 paires antagonistes conjuguées (Bloc A : A1, A2, D1, D2 ;
        Bloc B latérales : L1, L2, L3, L4) + centre fixe sur Z = 3, 4, 5,
        en distinguant explicitement Périmètre (A haut) et Surface intérieure (A bas).
    """
    items: list[Table1bLandmark] = [
        # --- Z = 2 : Fondation canonique (8 prototypes + centre) ---
        Table1bLandmark("Z2_A1_pos", "A1", "first", "axialExpectationPos", 2, "perimeter_A_high", "Courage", "Courage", "positive_mastery", +1.0, 0.0, 0.72),
        Table1bLandmark("Z2_A1_neg", "A1", "second", "axialExpectationNeg", 2, "perimeter_A_high", "Peur", "Fear", "aversive_low_control", -1.0, 0.0, 0.85),
        Table1bLandmark("Z2_A2_pos", "A2", "first", "axialControlPos", 2, "perimeter_A_high", "Joie", "Joy", "positive_mastery", 0.0, +1.0, 0.78),
        Table1bLandmark("Z2_A2_neg", "A2", "second", "axialControlNeg", 2, "perimeter_A_high", "Tristesse", "Sadness", "aversive_low_control", 0.0, -1.0, 0.55),
        Table1bLandmark("Z2_D1_pos", "D1", "first", "diagonalSynergyPos", 2, "perimeter_A_high", "Désir", "Desire", "positive_mastery", +0.5, +0.5, 0.80),
        Table1bLandmark("Z2_D1_neg", "D1", "second", "diagonalSynergyNeg", 2, "perimeter_A_high", "Dégoût", "Disgust", "aversive_low_control", -0.5, -0.5, 0.76),
        Table1bLandmark("Z2_D2_pos", "D2", "first", "diagonalAgenticConfront", 2, "perimeter_A_high", "Colère", "Anger", "agentic_opposition", -0.5, +0.5, 0.88),
        Table1bLandmark("Z2_D2_neg", "D2", "second", "diagonalAccommodation", 2, "interior_A_low", "Calme", "Calm", "accommodative_low_control", +0.5, -0.5, 0.25),
        Table1bLandmark("Z2_CENTER", "CENTER", "center", "centralOperator", 2, "center", "Anticipation", "Anticipation", "neutral_center", 0.0, 0.0, 0.20),

        # --- Z = 3 : Émotions (Périmètre A haut / Intérieur A bas) ---
        Table1bLandmark("Z3_A1_pos_hi", "A1", "first", "axialExpectationPos", 3, "perimeter_A_high", "Audace", "Boldness", "positive_mastery", +1.0, 0.0, 0.84),
        Table1bLandmark("Z3_A1_pos_lo", "A1", "first", "axialExpectationPos", 3, "interior_A_low", "Curiosité", "Curiosity", "positive_mastery", +1.0, 0.0, 0.36),
        Table1bLandmark("Z3_A1_neg_hi", "A1", "second", "axialExpectationNeg", 3, "perimeter_A_high", "Frayeur", "Fright", "aversive_low_control", -1.0, 0.0, 0.90),
        Table1bLandmark("Z3_A1_neg_lo", "A1", "second", "axialExpectationNeg", 3, "interior_A_low", "Inquiétude", "Worry", "aversive_low_control", -1.0, 0.0, 0.42),

        Table1bLandmark("Z3_D2_pos_hi", "D2", "first", "diagonalAgenticConfront", 3, "perimeter_A_high", "Exaspération", "Exasperation", "agentic_opposition", -0.5, +0.5, 0.86),
        Table1bLandmark("Z3_D2_pos_lo", "D2", "first", "diagonalAgenticConfront", 3, "interior_A_low", "Agacement", "Annoyance", "agentic_opposition", -0.5, +0.5, 0.38),
        Table1bLandmark("Z3_D2_neg_hi", "D2", "second", "diagonalAccommodation", 3, "perimeter_A_high", "Délivrance", "Deliverance", "accommodative_low_control", +0.5, -0.5, 0.72),
        Table1bLandmark("Z3_D2_neg_lo", "D2", "second", "diagonalAccommodation", 3, "interior_A_low", "Apaisement", "Soothing", "accommodative_low_control", +0.5, -0.5, 0.24),

        # --- Z = 4 : Sentiments — Bloc A + 4 Paires Latérales L1-L4 (échange exact |X| <-> |Y|) ---
        # D1 (Z=4)
        Table1bLandmark("Z4_D1_pos_hi", "D1", "first", "diagonalSynergyPos", 4, "perimeter_A_high", "Passion", "Passion", "positive_mastery", +0.5, +0.5, 0.88),
        Table1bLandmark("Z4_D1_pos_lo", "D1", "first", "diagonalSynergyPos", 4, "interior_A_low", "Affection", "Affection", "positive_mastery", +0.5, +0.5, 0.36),
        Table1bLandmark("Z4_D1_neg_hi", "D1", "second", "diagonalSynergyNeg", 4, "perimeter_A_high", "Aversion", "Aversion", "aversive_low_control", -0.5, -0.5, 0.82),
        Table1bLandmark("Z4_D1_neg_lo", "D1", "second", "diagonalSynergyNeg", 4, "interior_A_low", "Écœurement", "Loathing", "aversive_low_control", -0.5, -0.5, 0.38),

        # L1 : Q1 dom +X (+b, +a) <-> Q3 dom -Y (-a, -b)  [Fierté <-> Honte, iso-énergétique A haut]
        Table1bLandmark("Z4_L1_pos_hi", "L1", "first", "lateralEpistemicMastery", 4, "perimeter_A_high", "Fierté", "Pride", "positive_mastery", +0.72, +0.28, 0.82),
        Table1bLandmark("Z4_L1_pos_lo", "L1", "first", "lateralEpistemicMastery", 4, "interior_A_low", "Estime", "Esteem", "positive_mastery", +0.72, +0.28, 0.35),
        Table1bLandmark("Z4_L1_neg_hi", "L1", "second", "lateralAversiveDistress", 4, "perimeter_A_high", "Honte", "Shame", "aversive_low_control", -0.28, -0.72, 0.80),
        Table1bLandmark("Z4_L1_neg_lo", "L1", "second", "lateralAversiveDistress", 4, "interior_A_low", "Résignation", "Resignation", "aversive_low_control", -0.28, -0.72, 0.28),

        # L2 : Q1 dom +Y (+a, +b) <-> Q3 dom -X (-b, -a)  [Exaltation/Sérénité <-> Angoisse/Appréhension]
        Table1bLandmark("Z4_L2_pos_hi", "L2", "first", "lateralApproachSynergy", 4, "perimeter_A_high", "Exaltation", "Exaltation", "positive_mastery", +0.28, +0.72, 0.86),
        Table1bLandmark("Z4_L2_pos_lo", "L2", "first", "lateralApproachSynergy", 4, "interior_A_low", "Sérénité", "Serenity", "positive_mastery", +0.28, +0.72, 0.24),
        Table1bLandmark("Z4_L2_neg_hi", "L2", "second", "lateralEpistemicClosure", 4, "perimeter_A_high", "Angoisse", "Anguish", "aversive_low_control", -0.72, -0.28, 0.92),
        Table1bLandmark("Z4_L2_neg_lo", "L2", "second", "lateralEpistemicClosure", 4, "interior_A_low", "Appréhension diffuse", "Diffuse apprehension", "aversive_low_control", -0.72, -0.28, 0.42),

        # L3 : Q2 dom +Y (-a, +b) <-> Q4 dom +X (+b, -a)  [Hostilité <-> Endurance active / Patience]
        Table1bLandmark("Z4_L3_pos_hi", "L3", "first", "lateralAgenticConfront", 4, "perimeter_A_high", "Hostilité", "Hostility", "agentic_opposition", -0.28, +0.72, 0.88),
        Table1bLandmark("Z4_L3_pos_lo", "L3", "first", "lateralAgenticConfront", 4, "interior_A_low", "Ressentiment", "Resentment", "agentic_opposition", -0.28, +0.72, 0.40),
        Table1bLandmark("Z4_L3_neg_hi", "L3", "second", "lateralReceptiveAccomm", 4, "perimeter_A_high", "Endurance active", "Active endurance", "accommodative_low_control", +0.72, -0.28, 0.72),
        Table1bLandmark("Z4_L3_neg_lo", "L3", "second", "lateralReceptiveAccomm", 4, "interior_A_low", "Patience", "Patience", "accommodative_low_control", +0.72, -0.28, 0.28),

        # L4 : Q2 dom -X (-b, +a) <-> Q4 dom -Y (+a, -b)  [Indignation <-> Détachement / Lâcher-prise]
        Table1bLandmark("Z4_L4_pos_hi", "L4", "first", "lateralActiveContest", 4, "perimeter_A_high", "Indignation", "Indignation", "agentic_opposition", -0.72, +0.28, 0.84),
        Table1bLandmark("Z4_L4_pos_lo", "L4", "first", "lateralActiveContest", 4, "interior_A_low", "Mépris froid", "Cold contempt", "agentic_opposition", -0.72, +0.28, 0.36),
        Table1bLandmark("Z4_L4_neg_hi", "L4", "second", "lateralSecondaryAccomm", 4, "perimeter_A_high", "Détachement", "Detachment", "accommodative_low_control", +0.28, -0.72, 0.68),
        Table1bLandmark("Z4_L4_neg_lo", "L4", "second", "lateralSecondaryAccomm", 4, "interior_A_low", "Lâcher-prise", "Letting go", "accommodative_low_control", +0.28, -0.72, 0.24),

        # --- Z = 5 : Humeurs (repères L1, L2, L3, L4 clés) ---
        Table1bLandmark("Z5_L1_pos_hi", "L1", "first", "lateralEpistemicMastery", 5, "perimeter_A_high", "Optimisme actif", "Active optimism", "positive_mastery", +0.75, +0.25, 0.78),
        Table1bLandmark("Z5_L1_pos_lo", "L1", "first", "lateralEpistemicMastery", 5, "interior_A_low", "Espoir", "Hope", "positive_mastery", +0.75, +0.25, 0.36),
        Table1bLandmark("Z5_L1_neg_hi", "L1", "second", "lateralAversiveDistress", 5, "perimeter_A_high", "Désespoir", "Despair", "aversive_low_control", -0.25, -0.75, 0.82),
        Table1bLandmark("Z5_L1_neg_lo", "L1", "second", "lateralAversiveDistress", 5, "interior_A_low", "Apathie", "Apathy", "aversive_low_control", -0.25, -0.75, 0.20),

        Table1bLandmark("Z5_L2_pos_hi", "L2", "first", "lateralApproachSynergy", 5, "perimeter_A_high", "Plénitude", "Fulfillment", "positive_mastery", +0.25, +0.75, 0.70),
        Table1bLandmark("Z5_L2_pos_lo", "L2", "first", "lateralApproachSynergy", 5, "interior_A_low", "Sécurité", "Safety", "positive_mastery", +0.25, +0.75, 0.24),
        Table1bLandmark("Z5_L2_neg_hi", "L2", "second", "lateralEpistemicClosure", 5, "perimeter_A_high", "Terreur", "Terror", "aversive_low_control", -0.75, -0.25, 0.96),
        Table1bLandmark("Z5_L2_neg_lo", "L2", "second", "lateralEpistemicClosure", 5, "interior_A_low", "Tourment", "Torment", "aversive_low_control", -0.75, -0.25, 0.44),

        Table1bLandmark("Z5_L3_pos_hi", "L3", "first", "lateralAgenticConfront", 5, "perimeter_A_high", "Révolte", "Revolt", "agentic_opposition", -0.25, +0.75, 0.90),
        Table1bLandmark("Z5_L3_pos_lo", "L3", "first", "lateralAgenticConfront", 5, "interior_A_low", "Amertume", "Bitterness", "agentic_opposition", -0.25, +0.75, 0.36),
        Table1bLandmark("Z5_L3_neg_hi", "L3", "second", "lateralReceptiveAccomm", 5, "perimeter_A_high", "Stoïcisme", "Stoicism", "accommodative_low_control", +0.75, -0.25, 0.68),
        Table1bLandmark("Z5_L3_neg_lo", "L3", "second", "lateralReceptiveAccomm", 5, "interior_A_low", "Consentement lucide", "Lucid consent", "accommodative_low_control", +0.75, -0.25, 0.25),

        Table1bLandmark("Z5_CENTER", "CENTER", "center", "centralOperator", 5, "center", "Recul", "Stepping back", "neutral_center", 0.0, 0.0, 0.22),
    ]
    return items


# =============================================================================
# 2. UTILITAIRES BAYÉSIENS EXACTS (JZS BF, WAIC, LOO-CV, CORRÉLATION BAYÉSIENNE)
# =============================================================================

def jzs_paired_bf10(t_stat: float, n: int, r_scale: float = math.sqrt(0.5)) -> float:
    """Facteur de Bayes JZS exact (Rouder et al., 2009) pour un test apparié (df = n - 1)."""
    df = max(1, n - 1)
    t2 = float(t_stat) ** 2
    # Intégration numérique exacte en espace log-g pour éviter tout overflow
    log_num_0 = -0.5 * (df + 1.0) * math.log1p(t2 / df)

    def integrand(log_g: float) -> float:
        g = math.exp(log_g)
        ng = n * g
        log_term = (
            -0.5 * math.log1p(ng)
            - 0.5 * (df + 1.0) * math.log1p(t2 / ((1.0 + ng) * df))
            - 0.5 * math.log(2.0 * math.pi)
            - 1.5 * log_g
            + math.log(r_scale)
            - (r_scale * r_scale) / (2.0 * g)
            + log_g  # jacobien dg = g d(log_g)
        )
        return math.exp(max(-700.0, min(700.0, log_term - log_num_0)))

    val, _ = integrate.quad(integrand, -25.0, 25.0, limit=120)
    return float(max(1e-300, val))


def compute_loo_and_waic_from_pointwise_ll(log_lik_samples: np.ndarray) -> dict[str, Any]:
    """Calcule ELPD_WAIC, WAIC et ELPD_LOO (PSIS/importance tronquée) depuis (S, N) log-lik."""
    S, N = log_lik_samples.shape
    max_ll = np.max(log_lik_samples, axis=0, keepdims=True)
    lppd_i = max_ll.squeeze(0) + np.log(np.mean(np.exp(log_lik_samples - max_ll), axis=0))
    p_waic_i = np.var(log_lik_samples, axis=0, ddof=1 if S > 1 else 0)
    elpd_waic_i = lppd_i - p_waic_i

    # LOO-CV par importance sampling tronquée (Ionides 2008 / Vehtari et al. 2017)
    # log w_si = -log_lik_si ; troncature à sqrt(S) * mean(w) pour stabilité finie
    log_w = -log_lik_samples
    log_w -= np.max(log_w, axis=0, keepdims=True)
    w = np.exp(log_w)
    cap = math.sqrt(S) * np.mean(w, axis=0, keepdims=True)
    w_trunc = np.minimum(w, cap)
    w_norm = w_trunc / np.sum(w_trunc, axis=0, keepdims=True)
    # ELPD_LOO_i = log( sum_s w_norm_si * exp(ll_si) )
    max_s = np.max(log_lik_samples, axis=0, keepdims=True)
    elpd_loo_i = max_s.squeeze(0) + np.log(
        np.clip(np.sum(w_norm * np.exp(log_lik_samples - max_s), axis=0), 1e-300, None)
    )

    return {
        "elpd_loo": float(np.sum(elpd_loo_i)),
        "elpd_loo_se": float(math.sqrt(N) * np.std(elpd_loo_i, ddof=1)),
        "elpd_waic": float(np.sum(elpd_waic_i)),
        "waic": float(-2.0 * np.sum(elpd_waic_i)),
        "p_waic": float(np.sum(p_waic_i)),
        "elpd_loo_pointwise": elpd_loo_i,
    }


def compare_elpd(elpd_a: np.ndarray, elpd_b: np.ndarray) -> tuple[float, float, float]:
    """Retourne (diff = sum(A - B), SE(diff), z_ratio = diff / SE)."""
    diff_i = elpd_a - elpd_b
    n = len(diff_i)
    diff = float(np.sum(diff_i))
    se = float(math.sqrt(n) * np.std(diff_i, ddof=1)) if n > 1 else 0.0
    z_ratio = diff / se if se > 1e-12 else 0.0
    return diff, se, z_ratio


# =============================================================================
# 3. GÉNÉRATEUR DE DONNÉES PILOTES SIMULÉES (`pilot_pipeline_dry_run`, V3 = 0)
# =============================================================================

def simulate_pilot_dataset(
    *,
    scenario: str,
    n_participants: int = 600,
    seed: int = 20261127,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Génère un jeu pilote simulé (`pilot_pipeline_dry_run`, V3 = 0) pour tester le pipeline.

    Scénarios supportés :
      - ``cartograffect_v3`` : données pilotes cohérentes avec Option 1A, p = 1.05 (L1),
        bijection 2x2 de Rolls en Z=2 et échange contralatéral |X| <-> |Y| sur L1-L4.
      - ``rival_l2_central`` : données pilotes générées sous modèle rival (p = 2.00 euclidien,
        couplage Y/A = 0.80, inversion centrale pure (-X,-Y) sans échange |X|<->|Y|,
        confusion Rolls en 1D valence) pour vérifier que le pipeline RÉFUTE bien le modèle !
    """
    if scenario not in ("cartograffect_v3", "rival_l2_central"):
        raise ValueError(f"Scénario inconnu : {scenario}")

    rng = np.random.default_rng(seed)
    items = build_table1b_design()
    n_fr = n_participants // 2
    n_en = n_participants - n_fr
    cohorts = ["FR"] * n_fr + ["EN"] * n_en

    # 1. Table ratings_1b (plan incomplet équilibré réaliste : 20 items par participant
    #    tirés de manière stratifiée pour garantir la couverture de tous les sous-secteurs)
    #    Pour la reproductibilité rapide du dry-run : 16 items/participant couvrant tous les groupes.
    rng_item = np.random.default_rng(seed + 17)
    n_items = len(items)
    rows_1b: list[dict[str, Any]] = []

    # Paramètre vrai de l'exposant p selon le monde simulé
    p_true = 1.05 if scenario == "cartograffect_v3" else 2.00

    # Effets aléatoires par participant (réalistes)
    subj_p = np.clip(rng.normal(p_true, 0.12, size=n_participants), 0.70, 3.00)
    subj_bias_x = rng.normal(0.0, 0.08, size=n_participants)
    subj_bias_y = rng.normal(0.0, 0.08, size=n_participants)
    subj_bias_a = rng.normal(0.0, 0.07, size=n_participants)
    # 4 % d'échec aux contrôles d'attention simulés pour tester le filtre QC
    att_pass = (rng.random(n_participants) >= 0.04).astype(int)

    # Indice de tous les items pour échantillonnage stratifié (24 items/sujet -> ~14 400 obs)
    for s_idx in range(n_participants):
        pid = f"PILOT_{s_idx + 1:04d}"
        coh = cohorts[s_idx]
        p_s = float(subj_p[s_idx])
        chosen_indices = rng_item.choice(n_items, size=24, replace=False)

        for idx in chosen_indices:
            lm = items[int(idx)]
            ux_raw, uy_raw = lm.ux_theory, lm.uy_theory

            if scenario == "rival_l2_central":
                # Monde rival :
                # (a) Sur les paires L1-L4 côté "second", inversion centrale (-X,-Y) au lieu d'échange |X|<->|Y|
                if lm.pair_code in ("L1", "L2", "L3", "L4") and lm.pole_side == "second":
                    ux_raw, uy_raw = uy_raw, ux_raw  # annule l'échange |X| <-> |Y| -> pure inversion centrale !
                # (b) Pas de séparation aversive faible contrôle vs opposition agentique sur Y (hors L1-L4)
                elif lm.semantic_group == "aversive_low_control":
                    uy_raw = abs(uy_raw) * 0.45
                # (c) Canal A fortement colinéaire à |Y| / Y (efface la dissociation Option 1A)
                a_lat = float(np.clip(0.50 + 0.42 * uy_raw + subj_bias_a[s_idx], 0.05, 0.98))
            else:
                a_lat = float(np.clip(lm.a_theory + subj_bias_a[s_idx], 0.05, 0.98))

            # Projection sur la sphère unité L_p : |u_X|^p + |u_Y|^p = 1
            norm_p = (abs(ux_raw) ** p_s + abs(uy_raw) ** p_s) ** (1.0 / p_s)
            if norm_p > 1e-9:
                ux_p = ux_raw / norm_p
                uy_p = uy_raw / norm_p
            else:
                ux_p, uy_p = 0.0, 0.0

            # Surface remplie (x, y) / R(Z) = A_scale * (ux_p, uy_p)
            # Échelle VAS 0-100 (réduisant la troncature plafond aux pôles axiaux en Test 1B)
            # et note Likert 1-7 correspondante pour la comparabilité psychométrique
            rad_factor = 0.86 if lm.radial_tier == "perimeter_A_high" else (0.48 if lm.radial_tier == "interior_A_low" else 0.0)
            mu_x = rad_factor * ux_p + subj_bias_x[s_idx]
            mu_y = rad_factor * uy_p + subj_bias_y[s_idx]
            # Priorité hédonique P4 : X fixe la valence dès que X != 0, sinon Y
            mu_v = (0.75 * ux_p + 0.10 * uy_p) if abs(ux_raw) > 1e-6 else (0.65 * uy_p)

            # Bruit humain réaliste sur échelle continue VAS [-100, +100] / [0, 100] (sans artefact plafond Likert 7)
            # convertie proprement sur [1, 7] équivalent continu (résolution 0.01) pour compatibilité schéma
            rx = float(np.clip(4.0 + 3.0 * (mu_x + rng.normal(0.0, 0.24)), 1.0, 7.0))
            ry = float(np.clip(4.0 + 3.0 * (mu_y + rng.normal(0.0, 0.24)), 1.0, 7.0))
            ra = float(np.clip(1.0 + 6.0 * (a_lat + rng.normal(0.0, 0.14)), 1.0, 7.0))
            rv = float(np.clip(4.0 + 3.0 * (mu_v + rng.normal(0.0, 0.24)), 1.0, 7.0))

            rows_1b.append(
                {
                    "participant_id": pid,
                    "cohort": coh,
                    "item_id": lm.item_id,
                    "pair_code": lm.pair_code,
                    "pole_side": lm.pole_side,
                    "subsector_lean": lm.subsector_lean,
                    "z_stratum": lm.z_stratum,
                    "radial_tier": lm.radial_tier,
                    "label_fr": lm.label_fr,
                    "label_en": lm.label_en,
                    "semantic_group": lm.semantic_group,
                    "rating_X": rx,
                    "rating_Y": ry,
                    "rating_A": ra,
                    "rating_V": rv,
                    "attention_pass": int(att_pass[s_idx]),
                }
            )

    df_1b = pd.DataFrame(rows_1b)

    # 2. Table rolls_z2 : 4 scénarios de Rolls (Rew+, Rew-, Pun+, Pun-) par participant
    rows_rolls: list[dict[str, Any]] = []
    contingencies = ("Rew+", "Rew-", "Pun+", "Pun-")
    proto_list = list(CANONICAL_Z2_PROTOTYPES)
    for s_idx in range(n_participants):
        pid = f"PILOT_{s_idx + 1:04d}"
        coh = cohorts[s_idx]
        for cont in contingencies:
            sx, sy = ROLLS_EXPECTED_SIGNS[cont]
            if scenario == "cartograffect_v3":
                # Proba réaliste (~0.62) sur le prototype attendu, reste réparti sur voisins
                probs = np.full(8, 0.04, dtype=np.float64)
                tgt_idx = proto_list.index(ROLLS_EXPECTED_MAP[cont])
                probs[tgt_idx] = 0.62
                # Ajoute masse réaliste sur pôles axiaux adjacents
                probs += 0.10 / 8.0
                probs /= np.sum(probs)
                mx, my = 0.60 * sx, 0.60 * sy
                ma = 0.80 if cont == "Rew-" else (0.28 if cont == "Pun-" else 0.72)
            else:
                # Monde rival 1D valence : confond Rew+ avec Pun- (tous deux positifs)
                # et confond Rew- avec Pun+ (tous deux négatifs)
                probs = np.full(8, 0.04, dtype=np.float64)
                if sx > 0:
                    probs[proto_list.index("Joie")] = 0.40
                    probs[proto_list.index("Désir")] = 0.24
                    probs[proto_list.index("Calme")] = 0.14
                else:
                    probs[proto_list.index("Tristesse")] = 0.40
                    probs[proto_list.index("Dégoût")] = 0.24
                    probs[proto_list.index("Colère")] = 0.14
                probs /= np.sum(probs)
                mx, my = 0.60 * sx, 0.05 * sx  # pas de séparation instrumentale Y
                ma = 0.65

            chosen = proto_list[int(rng.choice(8, p=probs))]
            rx = int(np.clip(np.round(4.0 + 3.0 * (mx + rng.normal(0.0, 0.28))), 1, 7))
            ry = int(np.clip(np.round(4.0 + 3.0 * (my + rng.normal(0.0, 0.28))), 1, 7))
            ra = int(np.clip(np.round(1.0 + 6.0 * (ma + rng.normal(0.0, 0.16))), 1, 7))
            rv = int(np.clip(np.round(4.0 + 3.0 * (0.65 * sx + rng.normal(0.0, 0.25))), 1, 7))
            rows_rolls.append(
                {
                    "participant_id": pid,
                    "cohort": coh,
                    "contingency": cont,
                    "chosen_prototype": chosen,
                    "rating_X": rx,
                    "rating_Y": ry,
                    "rating_A": ra,
                    "rating_V": rv,
                    "attention_pass": int(att_pass[s_idx]),
                }
            )

    df_rolls = pd.DataFrame(rows_rolls)
    return df_1b, df_rolls


# =============================================================================
# 4. IMPLÉMENTATION DES 3 TESTS SÉVÈRES PRÉ-ENREGISTRÉS (1A, 1B, 1C)
# =============================================================================

def run_test_1a(df_1b: pd.DataFrame) -> dict[str, Any]:
    """Test 1A : Validité de construit de Y, orthogonalité de A et structure radiale Tableau 1b."""
    df = df_1b.copy()
    df["x"] = (df["rating_X"] - 4.0) / 3.0
    df["y"] = (df["rating_Y"] - 4.0) / 3.0
    df["a"] = (df["rating_A"] - 1.0) / 6.0
    df["v"] = (df["rating_V"] - 4.0) / 3.0

    # --- 1A-i : Séparation sur Y entre opposition agentique (Colère/Hostilité/Révolte)
    #            et états aversifs faible contrôle (Angoisse/Terreur/Honte/Désespoir) ---
    sub_y = df[df["semantic_group"].isin(["agentic_opposition", "aversive_low_control"])]
    piv_y = sub_y.pivot_table(index="participant_id", columns="semantic_group", values="y", aggfunc="mean").dropna()
    diff_y = (piv_y["agentic_opposition"] - piv_y["aversive_low_control"]).to_numpy(dtype=np.float64)
    n_y = len(diff_y)
    mean_dy = float(np.mean(diff_y))
    sd_dy = float(np.std(diff_y, ddof=1))
    dz_y = mean_dy / sd_dy if sd_dy > 1e-12 else 0.0
    t_y = mean_dy / (sd_dy / math.sqrt(n_y)) if sd_dy > 1e-12 else 0.0
    ci_y = (
        mean_dy - 1.96 * sd_dy / math.sqrt(n_y),
        mean_dy + 1.96 * sd_dy / math.sqrt(n_y),
    )
    bf10_y = jzs_paired_bf10(t_y, n_y) if mean_dy > 0 else 1.0 / max(1.0, jzs_paired_bf10(t_y, n_y))
    bf01_y = 1.0 / bf10_y
    refuted_1a_y = bool(dz_y < 0.30 or ci_y[0] <= 0.0 or bf01_y > 10.0)

    # --- 1A-ii : Séparation radiale Périmètre (A haut) vs Surface intérieure (A bas) ---
    sub_a = df[df["radial_tier"].isin(["perimeter_A_high", "interior_A_low"]) & (df["z_stratum"] >= 3)]
    piv_a = sub_a.pivot_table(index="participant_id", columns="radial_tier", values="a", aggfunc="mean").dropna()
    diff_a = (piv_a["perimeter_A_high"] - piv_a["interior_A_low"]).to_numpy(dtype=np.float64)
    n_a = len(diff_a)
    mean_da = float(np.mean(diff_a))
    sd_da = float(np.std(diff_a, ddof=1))
    dz_a = mean_da / sd_da if sd_da > 1e-12 else 0.0
    t_a = mean_da / (sd_da / math.sqrt(n_a)) if sd_da > 1e-12 else 0.0
    ci_a = (
        mean_da - 1.96 * sd_da / math.sqrt(n_a),
        mean_da + 1.96 * sd_da / math.sqrt(n_a),
    )
    bf10_a = jzs_paired_bf10(t_a, n_a) if mean_da > 0 else 1.0 / max(1.0, jzs_paired_bf10(t_a, n_a))
    bf01_a = 1.0 / bf10_a

    # LOO-CV / WAIC : modèle surface remplie (A dépend de radial_tier) vs anneau plat (A constant)
    a_obs = sub_a["a"].to_numpy(dtype=np.float64)
    is_perim = (sub_a["radial_tier"] == "perimeter_A_high").to_numpy(dtype=np.float64)
    rng_loo = np.random.default_rng(101)
    n_draws = 300
    # Modèle surface remplie : A ~ Normal(b0 + b1 * is_perim, sigma)
    X_full = np.column_stack([np.ones_like(is_perim), is_perim])
    beta_full, _, _, _ = np.linalg.lstsq(X_full, a_obs, rcond=None)
    res_full = a_obs - X_full @ beta_full
    sig_full = float(np.std(res_full, ddof=2))
    cov_full = (sig_full ** 2) * np.linalg.inv(X_full.T @ X_full)
    b_draws_full = rng_loo.multivariate_normal(beta_full, cov_full, size=n_draws)
    mu_full = b_draws_full @ X_full.T
    ll_full = stats.norm.logpdf(a_obs[None, :], loc=mu_full, scale=sig_full)

    # Modèle rival anneau plat : A ~ Normal(b0, sigma)
    mu0 = float(np.mean(a_obs))
    sig0 = float(np.std(a_obs, ddof=1))
    b0_draws = rng_loo.normal(mu0, sig0 / math.sqrt(len(a_obs)), size=(n_draws, 1))
    ll_flat = stats.norm.logpdf(a_obs[None, :], loc=b0_draws, scale=sig0)

    loo_full = compute_loo_and_waic_from_pointwise_ll(ll_full)
    loo_flat = compute_loo_and_waic_from_pointwise_ll(ll_flat)
    d_elpd_a, se_elpd_a, z_elpd_a = compare_elpd(
        loo_full["elpd_loo_pointwise"], loo_flat["elpd_loo_pointwise"]
    )
    refuted_1a_radial = bool(dz_a < 0.20 or bf01_a > 10.0 or (d_elpd_a < -2.0 * se_elpd_a))

    # --- 1A-iii : Orthogonalité stricte entre Y et A (|r(Y, A)| <= 0.70) ---
    r_ya = float(np.corrcoef(df["y"].to_numpy(), df["a"].to_numpy())[0, 1])
    # Corrélation au niveau des centroïdes d'items (élimine l'atténuation par bruit individuel)
    item_means = df.groupby("item_id")[["x", "y", "a", "v"]].mean()
    r_ya_items = float(np.corrcoef(item_means["y"], item_means["a"])[0, 1])
    refuted_1a_orth = bool(abs(r_ya) > 0.70 or abs(r_ya_items) > 0.70)

    # --- 1A-iv : Vérification de symétrie sémantique sur (X > 0, Y < 0) accommodation vs maîtrise ---
    sub_pos = df[df["semantic_group"].isin(["positive_mastery", "accommodative_low_control"])]
    piv_pos = sub_pos.pivot_table(index="participant_id", columns="semantic_group", values="y", aggfunc="mean").dropna()
    diff_pos_y = (piv_pos["positive_mastery"] - piv_pos["accommodative_low_control"]).to_numpy(dtype=np.float64)
    dz_pos_y = float(np.mean(diff_pos_y) / max(1e-12, np.std(diff_pos_y, ddof=1)))
    accomm_val_mean = float(df.loc[df["semantic_group"] == "accommodative_low_control", "v"].mean())

    overall_refuted = refuted_1a_y or refuted_1a_radial or refuted_1a_orth
    overall_corroborated = (
        not overall_refuted
        and dz_y >= 0.50
        and bf10_y > 10.0
        and dz_a >= 0.40
        and bf10_a > 10.0
        and abs(r_ya_items) <= 0.70
        and z_elpd_a > 2.0
    )

    return {
        "status": "REFUTED" if overall_refuted else ("CORROBORATED" if overall_corroborated else "INCONCLUSIVE"),
        "contrast_Y_agentic_vs_aversive": {
            "n_participants": n_y,
            "mean_diff_Y": round(mean_dy, 4),
            "ci95": [round(ci_y[0], 4), round(ci_y[1], 4)],
            "cohen_dz": round(dz_y, 4),
            "BF10": round(min(bf10_y, 1e12), 4),
            "BF01": round(min(bf01_y, 1e12), 6),
            "refuted": refuted_1a_y,
        },
        "contrast_A_perimeter_vs_interior": {
            "n_participants": n_a,
            "mean_diff_A": round(mean_da, 4),
            "ci95": [round(ci_a[0], 4), round(ci_a[1], 4)],
            "cohen_dz": round(dz_a, 4),
            "BF10": round(min(bf10_a, 1e12), 4),
            "BF01": round(min(bf01_a, 1e12), 6),
            "delta_elpd_loo_filled_vs_flat": round(d_elpd_a, 2),
            "delta_elpd_se": round(se_elpd_a, 2),
            "delta_waic_filled_vs_flat": round(loo_full["waic"] - loo_flat["waic"], 2),
            "refuted": refuted_1a_radial,
        },
        "orthogonality_Y_vs_A": {
            "r_YA_trial_level": round(r_ya, 4),
            "r_YA_item_centroids": round(r_ya_items, 4),
            "refutation_threshold_abs_r_gt": 0.70,
            "refuted": refuted_1a_orth,
        },
        "accommodation_symmetry_check": {
            "cohen_dz_mastery_vs_accomm_on_Y": round(dz_pos_y, 4),
            "mean_valence_accomm_Xpos_Yneg": round(accomm_val_mean, 4),
        },
    }


def run_test_1b(df_1b: pd.DataFrame) -> dict[str, Any]:
    """Test 1B : Estimation bayésienne libre de l'exposant p sur la frontière de capacité (A = 1).

    Compare explicitement :
      - M_L1 (CARTOGRAFFECT, p = 1) vs
      - M_L2 (Russell 1980, cercle euclidien p = 2) vs
      - M_free (allocation 2D libre sans contrainte budgétaire radiale).
    Critère d'abandon explicite de L1 : p_hat >= 1.70 OU victoire L2/M_free en LOO-CV OU BF_01 > 10.
    """
    perim = df_1b[df_1b["radial_tier"] == "perimeter_A_high"].copy()
    perim["x"] = (perim["rating_X"] - 4.0) / 3.0
    perim["y"] = (perim["rating_Y"] - 4.0) / 3.0

    # Agrégation au niveau des centroïdes (item x cohorte) ou par participant-item :
    # On travaille sur les centroïdes par item (par cohorte FR et EN -> points frontières précis)
    # ET sur les observations individuelles (pour LOO-CV hiérarchique).
    item_agg = (
        perim.groupby(["cohort", "item_id"])[["x", "y"]]
        .mean()
        .reset_index()
    )
    ax = np.abs(item_agg["x"].to_numpy(dtype=np.float64))
    ay = np.abs(item_agg["y"].to_numpy(dtype=np.float64))
    n_pts = len(ax)

    # Échelle radiale R_hat estimée proprement sur l'ensemble des points frontières
    # Modèle génératif de frontière Minkowski : r_p(x, y) = (|x|^p + |y|^p)^(1/p) ~ Normal(R, sigma)
    def fit_minkowski_fixed_p(p_val: float) -> tuple[float, float, np.ndarray]:
        rp = (ax ** p_val + ay ** p_val) ** (1.0 / p_val)
        r_hat = float(np.mean(rp))
        sig_hat = float(max(1e-4, np.std(rp, ddof=1)))
        # Jacobien exact pour comparer des densités sur les MÊMES observations (ax, ay) :
        # On exprime la prédiction radiale en coordonnées polaires (r_2, theta) :
        # r_2_pred(theta; p, R) = R / (|cos theta|^p + |sin theta|^p)^(1/p)
        # Ainsi M_L1, M_L2 et M_free prédisent TOUS la même variable observée r_2 = sqrt(x^2 + y^2) !
        r2_obs = np.sqrt(ax ** 2 + ay ** 2)
        theta = np.arctan2(ay, ax)
        geom_factor = (np.abs(np.cos(theta)) ** p_val + np.abs(np.sin(theta)) ** p_val) ** (1.0 / p_val)
        # MLE exact de R sur r2_obs = R / geom_factor + eps
        inv_g = 1.0 / geom_factor
        r_mle = float(np.dot(r2_obs, inv_g) / np.dot(inv_g, inv_g))
        pred = r_mle * inv_g
        resid = r2_obs - pred
        sig_mle = float(max(1e-4, np.sqrt(np.mean(resid ** 2))))
        return r_mle, sig_mle, resid

    r2_obs = np.sqrt(ax ** 2 + ay ** 2)
    theta = np.arctan2(ay, ax)

    # Grille bayésienne exacte sur p in [0.55, 3.20] avec prior faiblement informatif LogNormal(log 1.35, 0.45)
    p_grid = np.linspace(0.55, 3.20, 266)
    log_post_p = np.zeros_like(p_grid)
    r_grid = np.zeros_like(p_grid)
    sig_grid = np.zeros_like(p_grid)

    for k, pv in enumerate(p_grid):
        r_m, s_m, resid = fit_minkowski_fixed_p(float(pv))
        r_grid[k] = r_m
        sig_grid[k] = s_m
        ll_k = float(np.sum(stats.norm.logpdf(resid, loc=0.0, scale=s_m)))
        # Prior symétrique sur log(p) centré entre L1 et L2 (log(sqrt(2)) = 0.3466)
        lp_k = float(stats.norm.logpdf(math.log(pv), loc=math.log(math.sqrt(2.0)), scale=0.45) - math.log(pv))
        log_post_p[k] = ll_k + lp_k

    log_post_p -= np.max(log_post_p)
    post_w = np.exp(log_post_p)
    post_w /= np.sum(post_w)

    p_post_mean = float(np.sum(p_grid * post_w))
    p_post_sd = float(math.sqrt(np.sum(((p_grid - p_post_mean) ** 2) * post_w)))
    cdf_p = np.cumsum(post_w)
    p_ci_lo = float(np.interp(0.025, cdf_p, p_grid))
    p_ci_hi = float(np.interp(0.975, cdf_p, p_grid))

    # Comparaison directe de 3 modèles sur la MÊME variable cible r2_obs (LOO-CV / WAIC + BF) :
    #   1) M_L1 (p = 1 fixe)
    #   2) M_L2 (p = 2 fixe, Russell 1980)
    #   3) M_free (modèle sans contrainte budgétaire : r2 dépend librement sans contraction L1/L2,
    #      paramétré par moyenne globale + variance libre sur r2, ou modèle carré L_inf / constant)
    rng_m = np.random.default_rng(202)
    n_draws = 400

    def sample_model_ll_minkowski(p_fixed: float) -> tuple[dict[str, Any], float]:
        inv_g = 1.0 / ((np.abs(np.cos(theta)) ** p_fixed + np.abs(np.sin(theta)) ** p_fixed) ** (1.0 / p_fixed))
        r_mle = float(np.dot(r2_obs, inv_g) / np.dot(inv_g, inv_g))
        resid = r2_obs - r_mle * inv_g
        sig_mle = float(max(1e-4, np.std(resid, ddof=1)))
        se_r = sig_mle / math.sqrt(float(np.dot(inv_g, inv_g)))
        r_draws = rng_m.normal(r_mle, se_r, size=(n_draws, 1))
        mu_mat = r_draws * inv_g[None, :]
        ll_mat = stats.norm.logpdf(r2_obs[None, :], loc=mu_mat, scale=sig_mle)
        # Approximation BIC de la log-évidence marginale (2 paramètres : R, sigma)
        max_ll = float(np.sum(stats.norm.logpdf(resid, loc=0.0, scale=sig_mle)))
        log_ev = max_ll - 0.5 * 2.0 * math.log(n_pts)
        return compute_loo_and_waic_from_pointwise_ll(ll_mat), log_ev

    loo_l1, log_ev_l1 = sample_model_ll_minkowski(1.0)
    loo_l2, log_ev_l2 = sample_model_ll_minkowski(2.0)

    # Modèle M_free (sans contrainte budgétaire radiale / co-activation coopérative ou indépendante) :
    # Contrairement au goulot L1 (contraction vers la diagonale, pente < 0 sur sin(2*theta)),
    # l'absence de contrainte budgétaire prédit un rayon r2 non décroissant vers la diagonale :
    # r2(theta) = b0 + b1 * sin(2*theta) avec b1 >= 0 (incluant L2 à b1=0 et la boîte indépendante L_inf à b1>0).
    sin2t = np.sin(2.0 * theta)
    X_free = np.column_stack([np.ones(n_pts), sin2t])
    # Moindres carrés contraints (b1 >= 0 : absence de contrainte budgétaire négative)
    b_uncon, _, _, _ = np.linalg.lstsq(X_free, r2_obs, rcond=None)
    if b_uncon[1] < 0.0:
        b_free = np.array([float(np.mean(r2_obs)), 0.0], dtype=np.float64)
    else:
        b_free = b_uncon
    res_free = r2_obs - X_free @ b_free
    sig_free = float(max(1e-4, np.std(res_free, ddof=2)))
    cov_free = (sig_free ** 2) * np.linalg.pinv(X_free.T @ X_free)
    b_draws_free = rng_m.multivariate_normal(b_free, cov_free, size=n_draws)
    b_draws_free[:, 1] = np.maximum(0.0, b_draws_free[:, 1])
    ll_free = stats.norm.logpdf(r2_obs[None, :], loc=b_draws_free @ X_free.T, scale=sig_free)
    loo_free = compute_loo_and_waic_from_pointwise_ll(ll_free)
    log_ev_free = float(np.sum(stats.norm.logpdf(res_free, loc=0.0, scale=sig_free))) - 0.5 * 3.0 * math.log(n_pts)

    bf10_l1_vs_l2 = float(math.exp(max(-500.0, min(500.0, log_ev_l1 - log_ev_l2))))
    bf01_l2_vs_l1 = 1.0 / max(1e-300, bf10_l1_vs_l2)
    bf10_l1_vs_free = float(math.exp(max(-500.0, min(500.0, log_ev_l1 - log_ev_free))))
    bf01_free_vs_l1 = 1.0 / max(1e-300, bf10_l1_vs_free)

    d_elpd_l1_l2, se_l1_l2, z_l1_l2 = compare_elpd(
        loo_l1["elpd_loo_pointwise"], loo_l2["elpd_loo_pointwise"]
    )
    d_elpd_l1_free, se_l1_free, z_l1_free = compare_elpd(
        loo_l1["elpd_loo_pointwise"], loo_free["elpd_loo_pointwise"]
    )

    # Covariation empirique entre |X| et |Y| sur la frontière de capacité
    cov_abs_xy = float(np.corrcoef(ax, ay)[0, 1])

    # Critère d'abandon explicite de L1 (aucune clause d'immunisation)
    abandon_l1 = bool(
        p_post_mean >= 1.70
        or (d_elpd_l1_l2 < -2.0 * se_l1_l2)
        or (d_elpd_l1_free < -2.0 * se_l1_free)
        or (bf01_l2_vs_l1 > 10.0)
        or (bf01_free_vs_l1 > 10.0)
    )
    corroborated_l1 = bool(
        not abandon_l1
        and (0.80 <= p_post_mean <= 1.35)
        and (p_ci_hi < 1.70)
        and (bf10_l1_vs_l2 > 10.0)
        and (d_elpd_l1_l2 > 2.0 * se_l1_l2)
    )

    return {
        "status": "REFUTED" if abandon_l1 else ("CORROBORATED" if corroborated_l1 else "INCONCLUSIVE"),
        "abandon_L1_triggered": abandon_l1,
        "n_boundary_item_centroids": n_pts,
        "free_p_posterior": {
            "mean": round(p_post_mean, 4),
            "sd": round(p_post_sd, 4),
            "cri95": [round(p_ci_lo, 4), round(p_ci_hi, 4)],
        },
        "corr_absX_absY_boundary": round(cov_abs_xy, 4),
        "model_comparison_L1_vs_L2": {
            "elpd_loo_L1": round(loo_l1["elpd_loo"], 2),
            "elpd_loo_L2": round(loo_l2["elpd_loo"], 2),
            "delta_elpd_L1_minus_L2": round(d_elpd_l1_l2, 2),
            "delta_elpd_se": round(se_l1_l2, 2),
            "z_ratio": round(z_l1_l2, 3),
            "waic_L1": round(loo_l1["waic"], 2),
            "waic_L2": round(loo_l2["waic"], 2),
            "BF10_L1_vs_L2": round(min(bf10_l1_vs_l2, 1e12), 4),
            "BF01_L2_vs_L1": round(min(bf01_l2_vs_l1, 1e12), 6),
        },
        "model_comparison_L1_vs_Free": {
            "elpd_loo_Free": round(loo_free["elpd_loo"], 2),
            "delta_elpd_L1_minus_Free": round(d_elpd_l1_free, 2),
            "delta_elpd_se": round(se_l1_free, 2),
            "waic_Free": round(loo_free["waic"], 2),
            "BF10_L1_vs_Free": round(min(bf10_l1_vs_free, 1e12), 4),
            "BF01_Free_vs_L1": round(min(bf01_free_vs_l1, 1e12), 6),
        },
    }


def run_test_1c(df_1b: pd.DataFrame, df_rolls: pd.DataFrame) -> dict[str, Any]:
    """Test 1C : (i) Bijection 2x2 de Rolls sur Z = 2 ; (ii) Loi contralatérale L1-L4 (|X| <-> |Y|)."""
    # =========================================================================
    # Volet 1C-i : Bijection 2x2 de Rolls bornée à Z = 2 (Rew+/Rew-/Pun+/Pun-)
    # =========================================================================
    rolls_cells: dict[str, Any] = {}
    all_cells_top1 = True
    any_cell_refuted = False
    proto_list = list(CANONICAL_Z2_PROTOTYPES)

    for cont, expected_proto in ROLLS_EXPECTED_MAP.items():
        sub = df_rolls[df_rolls["contingency"] == cont]
        counts = sub["chosen_prototype"].value_counts().reindex(proto_list, fill_value=0)
        n_tot = int(counts.sum())
        c_exp = int(counts[expected_proto])
        others = counts.drop(index=expected_proto)
        runner_up_name = str(others.idxmax())
        c_run = int(others.max())
        acc = c_exp / max(1, n_tot)
        # Test bayésien exact Beta-Binomial : p_exp vs p_runner_up sur les cas {expected, runner_up}
        n_pair = c_exp + c_run
        # Log BF_10 : H1 (p ~ Uniform(0,1)) vs H0 (p = 0.5)
        log_ev_h0 = n_pair * math.log(0.5)
        log_ev_h1 = special.betaln(c_exp + 1, c_run + 1)
        bf_pair = math.exp(max(-500.0, min(500.0, log_ev_h1 - log_ev_h0)))
        bf10_cell = bf_pair if c_exp > c_run else 1.0 / max(1.0, bf_pair)
        bf01_cell = 1.0 / max(1e-300, bf10_cell)

        is_top1 = c_exp > c_run
        if not is_top1:
            all_cells_top1 = False
        if (not is_top1) or (bf01_cell > 10.0):
            any_cell_refuted = True

        rolls_cells[cont] = {
            "expected_prototype": expected_proto,
            "accuracy": round(acc, 4),
            "runner_up_prototype": runner_up_name,
            "runner_up_rate": round(c_run / max(1, n_tot), 4),
            "top1_match": is_top1,
            "BF10_vs_runner_up": round(min(bf10_cell, 1e12), 4),
            "BF01_vs_runner_up": round(min(bf01_cell, 1e12), 6),
        }

    # Comparaison LOO-CV / WAIC sur les choix Z=2 : Modèle Rolls 2x2 (4 cellules distinctes)
    # vs Modèle rival 1D Valence (fusionne Rew+/Pun- et Rew-/Pun+)
    rng_r = np.random.default_rng(303)
    n_draws = 300
    n_obs_r = len(df_rolls)
    y_idx = df_rolls["chosen_prototype"].map({p: i for i, p in enumerate(proto_list)}).to_numpy()
    cont_idx = df_rolls["contingency"].map({"Rew+": 0, "Rew-": 1, "Pun+": 2, "Pun-": 3}).to_numpy()
    val_grp = df_rolls["contingency"].map({"Rew+": 0, "Pun-": 0, "Rew-": 1, "Pun+": 1}).to_numpy()

    # Posterior Dirichlet conjugué exact par cellule (Rolls 2x2) vs par valence (1D)
    ll_rolls_2x2 = np.zeros((n_draws, n_obs_r), dtype=np.float64)
    for c_i in range(4):
        mask_c = cont_idx == c_i
        cnts = np.bincount(y_idx[mask_c], minlength=8).astype(np.float64)
        p_draws = rng_r.dirichlet(1.0 + cnts, size=n_draws)
        ll_rolls_2x2[:, mask_c] = np.log(np.clip(p_draws[:, y_idx[mask_c]], 1e-12, 1.0))

    ll_valence_1d = np.zeros((n_draws, n_obs_r), dtype=np.float64)
    for v_i in range(2):
        mask_v = val_grp == v_i
        cnts = np.bincount(y_idx[mask_v], minlength=8).astype(np.float64)
        p_draws = rng_r.dirichlet(1.0 + cnts, size=n_draws)
        ll_valence_1d[:, mask_v] = np.log(np.clip(p_draws[:, y_idx[mask_v]], 1e-12, 1.0))

    loo_rolls = compute_loo_and_waic_from_pointwise_ll(ll_rolls_2x2)
    loo_val1d = compute_loo_and_waic_from_pointwise_ll(ll_valence_1d)
    d_elpd_rolls, se_rolls, z_rolls = compare_elpd(
        loo_rolls["elpd_loo_pointwise"], loo_val1d["elpd_loo_pointwise"]
    )
    refuted_rolls = bool(any_cell_refuted or (d_elpd_rolls < -2.0 * se_rolls))

    # =========================================================================
    # Volet 1C-ii : Loi contralatérale des paires latérales L1-L4 (|X| <-> |Y|)
    #               découplée de A' = A
    # =========================================================================
    df = df_1b.copy()
    df["x"] = (df["rating_X"] - 4.0) / 3.0
    df["y"] = (df["rating_Y"] - 4.0) / 3.0
    df["a"] = (df["rating_A"] - 1.0) / 6.0

    lat = df[df["pair_code"].isin(["L1", "L2", "L3", "L4"])]
    # Centroïdes par (cohort, z_stratum, radial_tier, pair_code, pole_side)
    cent = (
        lat.groupby(["cohort", "z_stratum", "radial_tier", "pair_code", "pole_side"])[["x", "y", "a"]]
        .mean()
        .unstack("pole_side")
        .dropna()
    )
    x1 = cent[("x", "first")].to_numpy(dtype=np.float64)
    y1 = cent[("y", "first")].to_numpy(dtype=np.float64)
    a1 = cent[("a", "first")].to_numpy(dtype=np.float64)
    x2 = cent[("x", "second")].to_numpy(dtype=np.float64)
    y2 = cent[("y", "second")].to_numpy(dtype=np.float64)
    a2 = cent[("a", "second")].to_numpy(dtype=np.float64)

    # Indice de dominance d'axe : Delta_dom = |X| - |Y|
    # La loi contralatérale prédit Delta_dom(second) = -Delta_dom(first) (corrélation positive entre d1 et -d2)
    dom1 = np.abs(x1) - np.abs(y1)
    dom2 = np.abs(x2) - np.abs(y2)
    r_dom_swap = float(np.corrcoef(dom1, -dom2)[0, 1])

    # Prédiction contralatérale exacte : (-sgn(x1)*|y1|, -sgn(y1)*|x1|)
    pred_contra_x = -np.sign(x1) * np.abs(y1)
    pred_contra_y = -np.sign(y1) * np.abs(x1)
    err_contra = np.concatenate([x2 - pred_contra_x, y2 - pred_contra_y])
    rmse_contra = float(np.sqrt(np.mean(err_contra ** 2)))

    # Prédiction rivale : inversion centrale pure (-x1, -y1) sans échange |X| <-> |Y|
    pred_central_x = -x1
    pred_central_y = -y1
    err_central = np.concatenate([x2 - pred_central_x, y2 - pred_central_y])
    rmse_central = float(np.sqrt(np.mean(err_central ** 2)))

    # Comparaison bayésienne & LOO-CV sur les erreurs 2D (même nombre de paramètres : sigma seul)
    n_err = len(err_contra)
    sig_c = float(max(1e-4, np.sqrt(np.mean(err_contra ** 2))))
    sig_o = float(max(1e-4, np.sqrt(np.mean(err_central ** 2))))
    ll_c_draws = stats.norm.logpdf(
        err_contra[None, :],
        loc=0.0,
        scale=rng_r.normal(sig_c, sig_c / math.sqrt(2.0 * n_err), size=(n_draws, 1)).clip(1e-4, None),
    )
    ll_o_draws = stats.norm.logpdf(
        err_central[None, :],
        loc=0.0,
        scale=rng_r.normal(sig_o, sig_o / math.sqrt(2.0 * n_err), size=(n_draws, 1)).clip(1e-4, None),
    )
    loo_contra = compute_loo_and_waic_from_pointwise_ll(ll_c_draws)
    loo_central = compute_loo_and_waic_from_pointwise_ll(ll_o_draws)
    d_elpd_swap, se_swap, z_swap = compare_elpd(
        loo_contra["elpd_loo_pointwise"], loo_central["elpd_loo_pointwise"]
    )
    log_ev_c = float(np.sum(stats.norm.logpdf(err_contra, loc=0.0, scale=sig_c)))
    log_ev_o = float(np.sum(stats.norm.logpdf(err_central, loc=0.0, scale=sig_o)))
    bf10_swap = float(math.exp(max(-500.0, min(500.0, log_ev_c - log_ev_o))))
    bf01_swap = 1.0 / max(1e-300, bf10_swap)

    # Vérification explicite que A' = A n'est PAS exigé (ex. L2 Sérénité A bas vs Angoisse A haut)
    ser_a = float(df.loc[df["label_fr"] == "Sérénité", "a"].mean())
    ang_a = float(df.loc[df["label_fr"] == "Angoisse", "a"].mean())
    fierte_a = float(df.loc[df["label_fr"] == "Fierté", "a"].mean())
    honte_a = float(df.loc[df["label_fr"] == "Honte", "a"].mean())

    refuted_swap = bool(r_dom_swap <= 0.0 or (d_elpd_swap < -2.0 * se_swap) or (bf01_swap > 10.0))

    overall_refuted = refuted_rolls or refuted_swap
    overall_corroborated = (
        not overall_refuted
        and all_cells_top1
        and z_rolls > 2.0
        and r_dom_swap > 0.50
        and bf10_swap > 10.0
        and z_swap > 2.0
    )

    return {
        "status": "REFUTED" if overall_refuted else ("CORROBORATED" if overall_corroborated else "INCONCLUSIVE"),
        "rolls_2x2_z2": {
            "cells": rolls_cells,
            "all_4_cells_top1": all_cells_top1,
            "delta_elpd_loo_Rolls2x2_vs_Valence1D": round(d_elpd_rolls, 2),
            "delta_elpd_se": round(se_rolls, 2),
            "z_ratio": round(z_rolls, 3),
            "delta_waic_Rolls2x2_vs_Valence1D": round(loo_rolls["waic"] - loo_val1d["waic"], 2),
            "refuted": refuted_rolls,
        },
        "contralateral_swap_L1_L4": {
            "n_lateral_pair_centroids": len(x1),
            "dominance_swap_corr": round(r_dom_swap, 4),
            "rmse_contralateral_swap": round(rmse_contra, 4),
            "rmse_central_inversion_rival": round(rmse_central, 4),
            "delta_elpd_loo_contra_vs_central": round(d_elpd_swap, 2),
            "delta_elpd_se": round(se_swap, 2),
            "z_ratio": round(z_swap, 3),
            "BF10_contra_vs_central": round(min(bf10_swap, 1e12), 4),
            "BF01_central_vs_contra": round(min(bf01_swap, 1e12), 6),
            "arousal_decoupling_examples": {
                "iso_energetic_L1_Fierte_A": round(fierte_a, 3),
                "iso_energetic_L1_Honte_A": round(honte_a, 3),
                "asymmetric_L2_Serenite_A": round(ser_a, 3),
                "asymmetric_L2_Angoisse_A": round(ang_a, 3),
            },
            "refuted": refuted_swap,
        },
    }


def analyze_study1_tables(
    df_1b: pd.DataFrame,
    df_rolls: pd.DataFrame,
    *,
    run_label: str,
) -> dict[str, Any]:
    """Exécute le QC pré-enregistré et les 3 tests sévères 1A, 1B, 1C sur un jeu Study 1."""
    raw_ids = set(df_1b["participant_id"].unique())
    pass_ids = set(df_1b.loc[df_1b["attention_pass"] == 1, "participant_id"].unique())
    # Filtre anti-straight-lining (SD >= 0.15 sur rating_X ou rating_Y)
    stds = df_1b.groupby("participant_id")[["rating_X", "rating_Y"]].std()
    non_straight_ids = set(stds.index[(stds["rating_X"] >= 0.15) | (stds["rating_Y"] >= 0.15)])
    keep_ids = pass_ids & non_straight_ids

    clean_1b = df_1b[df_1b["participant_id"].isin(keep_ids)].copy()
    clean_rolls = df_rolls[df_rolls["participant_id"].isin(keep_ids)].copy()

    cohort_counts = (
        clean_1b[["participant_id", "cohort"]]
        .drop_duplicates()["cohort"]
        .value_counts()
        .to_dict()
    )

    res_1a = run_test_1a(clean_1b)
    res_1b = run_test_1b(clean_1b)
    res_1c = run_test_1c(clean_1b, clean_rolls)

    return {
        "run_label": run_label,
        "qc_summary": {
            "n_participants_raw": len(raw_ids),
            "n_participants_excluded": len(raw_ids) - len(keep_ids),
            "n_participants_analysed": len(keep_ids),
            "cohorts": {str(k): int(v) for k, v in cohort_counts.items()},
            "n_observations_table1b": int(len(clean_1b)),
            "n_observations_rolls_z2": int(len(clean_rolls)),
        },
        "test_1A_construct_Y_orthogonality_A_radial_1b": res_1a,
        "test_1B_minkowski_p_boundary": res_1b,
        "test_1C_rolls_z2_and_contralateral_swap": res_1c,
    }


def run_pilot_dry_run(n_participants: int = 600, seed: int = 20261127) -> dict[str, Any]:
    """Exécute le dry-run complet (`pilot_pipeline_dry_run`, V3 = 0) sous 2 mondes (v3 vs rival)."""
    t0 = time.perf_counter()

    # 1. Monde pilote CARTOGRAFFECT v3.0
    df_1b_v3, df_rolls_v3 = simulate_pilot_dataset(
        scenario="cartograffect_v3", n_participants=n_participants, seed=seed
    )
    res_v3 = analyze_study1_tables(
        df_1b_v3, df_rolls_v3, run_label="pilot_pipeline_dry_run_cartograffect_v3"
    )

    # 2. Monde pilote rival (Russell L2 p=2 + inversion centrale + couplage Y/A + valence 1D)
    df_1b_riv, df_rolls_riv = simulate_pilot_dataset(
        scenario="rival_l2_central", n_participants=n_participants, seed=seed + 1
    )
    res_riv = analyze_study1_tables(
        df_1b_riv, df_rolls_riv, run_label="pilot_pipeline_dry_run_rival_falsification_check"
    )

    # Vérifications bloquantes de bon fonctionnement du pipeline (capacité de corroboration ET de réfutation)
    for tkey in (
        "test_1A_construct_Y_orthogonality_A_radial_1b",
        "test_1B_minkowski_p_boundary",
        "test_1C_rolls_z2_and_contralateral_swap",
    ):
        if res_v3[tkey]["status"] != "CORROBORATED":
            raise AssertionError(
                f"Dry-run CARTOGRAFFECT v3 a échoué à corroborer {tkey} : {res_v3[tkey]['status']}"
            )
        if res_riv[tkey]["status"] != "REFUTED":
            raise AssertionError(
                f"Dry-run rival a échoué à RÉFUTER {tkey} (risque d'immunisation !) : {res_riv[tkey]['status']}"
            )

    return {
        "pipeline_mode": "pilot_pipeline_dry_run",
        "epistemic_status": "pilot_pipeline_dry_run",
        "epistemic_warning": (
            "PILOT PIPELINE DRY-RUN ON SIMULATED DATA ONLY (V3 = 0). "
            "Not human empirical data. Verifies both corroboration and severe refutation logic prior to OSF freeze."
        ),
        "V3_empirical_validation": 0,
        "environment": {
            "python_version": platform.python_version(),
            "numpy_version": np.__version__,
            "scipy_version": scipy.__version__,
            "pandas_version": pd.__version__,
            "runtime_seconds": round(time.perf_counter() - t0, 3),
        },
        "dry_run_cartograffect_v3_world": res_v3,
        "dry_run_rival_world_falsification_check": res_riv,
        "pipeline_integrity_verdict": "PASS_READY_FOR_OSF_FREEZE",
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="CARTOGRAFFECT Study 1 Preregistered Analysis Pipeline (OSF / Stage 1 RR)."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Exécute le test de bout en bout sur jeux pilotes simulés (`pilot_pipeline_dry_run`, V3=0).",
    )
    parser.add_argument(
        "--data-1b",
        type=Path,
        default=None,
        help="Chemin CSV des réponses Tableau 1b (collecte humaine réelle post-Stage 1).",
    )
    parser.add_argument(
        "--data-rolls",
        type=Path,
        default=None,
        help="Chemin CSV des réponses scénarios Rolls Z=2 (collecte humaine réelle post-Stage 1).",
    )
    parser.add_argument(
        "--n-pilot",
        type=int,
        default=640,
        help="Taille d'échantillon brut pour le dry-run simulé (défaut : 640 -> ~614 analysables >= 600).",
    )
    parser.add_argument("--seed", type=int, default=20261127, help="Graine PRNG fixée pour le dry-run.")
    args = parser.parse_args(argv)

    if args.data_1b is not None and args.data_rolls is not None:
        df_1b = pd.read_csv(args.data_1b)
        df_rolls = pd.read_csv(args.data_rolls)
        report = analyze_study1_tables(df_1b, df_rolls, run_label="empirical_study1_run")
        print(json.dumps(report, indent=2, ensure_ascii=False))
        return 0

    # Comportement par défaut ou --dry-run explicite : exécute `pilot_pipeline_dry_run`
    report = run_pilot_dry_run(n_participants=args.n_pilot, seed=args.seed)
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
