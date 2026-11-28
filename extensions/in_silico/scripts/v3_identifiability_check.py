#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""
v3_identifiability_check.py — Synthetic Identifiability Check (CARTOGRAFFECT v3.0)
==================================================================================

STATUT ÉPISTÉMIQUE STRICT (`V3 = 0`) :
    Ce script exécute exclusivement un `synthetic_identifiability_check` sur agents
    synthétiques. Il ne constitue EN AUCUN CAS une validation empirique, une
    validation externe ni un résultat clinique sur sujets humains (`V3 = 0`).

Objet :
    1. Diagnostiquer la colinéarité paramétrique documentée dans le modèle v2 à
       8 paramètres (`extensions/in_silico/results/exp03_parameter_error_corr_matrix.csv` :
       `alpha_0 / gamma_alpha = -0.813` ; `beta_X / beta_Y = +0.667`).
    2. Définir et tester un modèle comportemental v3.0 parcimonieux et orthogonalisé
       à 5 paramètres libres `theta = (rho, p, gamma_A, chi, beta)` strictement aligné
       sur `DECISIONS_V3.md` et le commit `66d9a0d` :
         - Option 1A : `Y` = contrôlabilité instrumentale stricte ; canal autonome
           de mobilisation allostatique `A in (0, 1]` strictement orthogonal à `sgn(Y)`.
         - Géométrie en couches planes à surface remplie :
           `(x, y) = A * R(Z) * (u_X, u_Y)` avec `|u_X|^p + |u_Y|^p = 1`
           (`p = 1` losange L1 CARTOGRAFFECT vs `p = 2` cercle euclidien L2).
         - Option 2a : dynamique verticale pas-à-pas `Z in {2, 3, 4, 5}` (avec retour
           court-circuit `2 -> 0` hors surprise).
         - Option 3b : asymétrie dynamique Charge / Décharge — contagion inter-boucles
           `chi > 0` restreinte EXCLUSIVEMENT aux 2 pôles axiaux en Charge négative
           (`Peur`, `Tristesse`), nulle (`0`) sur les 2 pôles en Décharge (`Courage`, `Joie`).
    3. Simuler une tâche comportementale orthogonale 2x2 (Volatilité x Contrôlabilité)
       sous bruit humain réaliste :
         - Auto-évaluations ordinales discrétisées Likert 1-7 (modèle probit ordonné,
           bruit humain non réduit : sigma_XY = 0.25 sur [-1, 1], sigma_A = 0.14 sur [0, 1]) ;
         - 10 % de données manquantes MCAR appliquées indépendamment aux sondes Likert ;
         - Bruit décisionnel / moteur (taux de lapse moteur fixé à 5 % + softmax).
    4. Estimer `theta_hat` par maximum de vraisemblance pénalisée (MAP faiblement informatif,
       multi-start L-BFGS-B sous `scipy.optimize`) sur `N >= 60` agents synthétiques
       (graine fixée et documentée), exporter `extensions/in_silico/results/v3_identifiability_report.json`
       et faire échouer le script (`AssertionError`) si :
         - `min_r_recovery < 0.70`, OU
         - `max_abs_off_diag_error_corr >= 0.35`.
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
import json
import math
import platform
from pathlib import Path
import sys
import time
from typing import Any

import numpy as np
import scipy
from scipy.optimize import minimize
from scipy.special import erf, expit


# =============================================================================
# 1. PARAMÈTRES DU MODÈLE v3.0 PARCIMONIEUX ET ORTHOGONALISÉ (5 PARAMÈTRES)
# =============================================================================

PARAM_NAMES: tuple[str, ...] = ("rho", "p", "gamma_A", "chi", "beta")

# Plages de tirage larges et réalistes (aucun rétrécissement abusif)
PARAM_BOUNDS: dict[str, tuple[float, float]] = {
    "rho": (0.15, 0.85),       # Taux de mise à jour / révision centré (remplace alpha_0 / gamma_alpha)
    "p": (0.80, 2.40),         # Exposant géométrique de Minkowski libre (L1=1 vs L2=2)
    "gamma_A": (0.50, 3.50),   # Réactivité allostatique autonome A >= 0 (Option 1A)
    "chi": (0.10, 0.85),       # Contagion inter-boucles Option 3b (Peur/Tristesse uniquement)
    "beta": (0.80, 4.50),      # Précision décisionnelle unifiée (remplace beta_X / beta_Y)
}

# Constantes de mesure humaine réalistes (non optimisées pour masquer la colinéarité)
SIGMA_XY_LIKERT: float = 0.25    # ~0.88 point Likert sur échelle 1-7 couvrant [-1, 1]
SIGMA_A_LIKERT: float = 0.14     # ~0.98 point Likert sur échelle 1-7 couvrant [0, 1]
MISSING_MCAR_RATE: float = 0.10  # 10 % de données manquantes MCAR
MOTOR_LAPSE_RATE: float = 0.05   # 5 % de bruit moteur / lapses décisionnels
A_MIN_FLOOR: float = 0.15        # Plancher d'activation autonome en surface intérieure (A > 0)
DEPTH_INERTIA_SLOPE: float = 0.25  # Inertie hiérarchique fixe centrée à Z_ref = 2 (P3)
DISCHARGE_DISSIPATION: float = 0.72  # Relaxation vers Veille des pôles positifs (Option 3b)

# Seuils de discrétisation ordinale Likert 1..7 (6 seuils intérieurs)
CUTPOINTS_BIPOLAR: np.ndarray = np.array(
    [-5.0 / 6.0, -3.0 / 6.0, -1.0 / 6.0, 1.0 / 6.0, 3.0 / 6.0, 5.0 / 6.0],
    dtype=np.float64,
)
CUTPOINTS_UNIPOLAR: np.ndarray = np.array(
    [1.0 / 7.0, 2.0 / 7.0, 3.0 / 7.0, 4.0 / 7.0, 5.0 / 7.0, 6.0 / 7.0],
    dtype=np.float64,
)

# Critères bloquants d'identifiabilité (non négociables)
MIN_RECOVERY_R_THRESHOLD: float = 0.70
MAX_OFFDIAG_ERR_CORR_THRESHOLD: float = 0.35

SQRT2: float = math.sqrt(2.0)


def _norm_cdf(x: np.ndarray) -> np.ndarray:
    """Fonction de répartition normale standard vectorisée (rapide et exacte)."""
    return 0.5 * (1.0 + erf(x / SQRT2))


def _ordered_probit_loglik(
    ratings: np.ndarray,
    observed_mask: np.ndarray,
    mu: np.ndarray,
    sigma: float,
    cutpoints: np.ndarray,
) -> float:
    """Log-vraisemblance probit ordonnée exacte pour des réponses Likert 1..7 avec MCAR."""
    obs_idx = observed_mask
    if not np.any(obs_idx):
        return 0.0
    y = ratings[obs_idx]
    m = mu[obs_idx]
    # Seuils étendus [-inf, c_0, ..., c_5, +inf]
    hi_idx = y - 1  # 0..6 -> borne supérieure cutpoints[y-1] sauf pour y=7 (+inf)
    lo_idx = y - 2  # -1..5 -> borne inférieure cutpoints[y-2] sauf pour y=1 (-inf)

    p_hi = np.ones_like(m, dtype=np.float64)
    has_hi = y < 7
    if np.any(has_hi):
        p_hi[has_hi] = _norm_cdf((cutpoints[hi_idx[has_hi]] - m[has_hi]) / sigma)

    p_lo = np.zeros_like(m, dtype=np.float64)
    has_lo = y > 1
    if np.any(has_lo):
        p_lo[has_lo] = _norm_cdf((cutpoints[lo_idx[has_lo]] - m[has_lo]) / sigma)

    probs = np.clip(p_hi - p_lo, 1e-12, 1.0)
    return float(np.sum(np.log(probs)))


def _discretize_likert(
    latent_vals: np.ndarray,
    cutpoints: np.ndarray,
) -> np.ndarray:
    """Discrétise des valeurs latentes bruitées en scores entiers Likert 1..7."""
    return (np.digitize(latent_vals, cutpoints) + 1).astype(np.int32)


# =============================================================================
# 2. PROTOCOLE EXPÉRIMENTAL ORTHOGONAL 2x2 (VOLATILITÉ x CONTRÔLABILITÉ)
# =============================================================================

@dataclass(frozen=True)
class TaskSchedule:
    """Plan expérimental orthogonal 2x2 (Volatilité x Contrôlabilité) de T essais."""

    num_trials: int
    cell_id: np.ndarray            # 0=(LowV,HiC), 1=(HiV,HiC), 2=(HiV,LoC), 3=(LowV,LoC)
    volatility_high: np.ndarray    # 0 ou 1
    control_high: np.ndarray       # 0 ou 1
    depth_z: np.ndarray            # Z in {2, 3, 4, 5} (pas-à-pas Option 2a)
    trial_kind: np.ndarray         # 0=diagonal, 1=axial_step1, 2=axial_step2
    axial_pole: np.ndarray         # -1=none, 0=Peur, 1=Tristesse, 2=Courage, 3=Joie
    fb_x: np.ndarray               # Signal observable d'évidence épistémique (Attente)
    fb_y: np.ndarray               # Signal observable d'évidence instrumentale (Contrôle)
    urgency_u: np.ndarray          # Urgence allostatique centrée in [-1, 1], E[u]=0, orth. à Y
    sec_dir: np.ndarray            # Direction contextuelle secondaire {-1, +1} pour Step 2
    stim_cue: np.ndarray           # Indice comportemental {-1, +1} pour la tâche de choix


def build_orthogonal_2x2_schedule(seed: int = 20260301) -> TaskSchedule:
    """Construit un plan équilibré 2x2 (Volatilité x Contrôlabilité) sur T = 240 essais.

    Structure par cellule (4 cellules x 60 essais = 240 essais) :
      - 28 essais diagonaux (double saillance X et Y) incluant 2 inversions mono-axe
        (Volatilité ou Contrôlabilité) afin d'identifier `rho` par la cinétique
        transitoire et `p` par la contraction radiale |u_X|^p + |u_Y|^p = 1.
      - 16 épisodes axiaux en 2 pas (32 essais/cellule = 128 essais au total :
        32 Peur, 32 Tristesse, 32 Courage, 32 Joie) testant directement l'asymétrie
        Option 3b (contagion `chi > 0` sur Charge négative uniquement vs 0 sur Décharge).
      - Urgence allostatique `urgency_u in [-1, +1]` strictement équilibrée à moyenne 0
        dans chaque cellule et chaque régime (orthogonalité stricte `Corr(u, sgn(Y)) = 0`).
      - Profondeur `Z in {2, 3, 4, 5}` variant pas-à-pas (Option 2a : |Delta Z| <= 1).
    """
    rng = np.random.default_rng(seed)

    # 4 cellules 2x2 : (vol_high, ctrl_high, base_x, base_y)
    # base_x > 0 : faible volatilité (modèle révisable) ; base_x < 0 : forte volatilité (menace/contradiction)
    # base_y > 0 : fort contrôle instrumental ; base_y < 0 : faible contrôle instrumental
    cells = [
        (0, 0, 1, +0.90, +0.90),  # Cell 0: Q1 (+X, +Y) Désir / Maîtrise
        (1, 1, 1, -0.90, +0.90),  # Cell 1: Q2 (-X, +Y) Colère / Affrontement agentique
        (2, 1, 0, -0.90, -0.90),  # Cell 2: Q3 (-X, -Y) Dégoût / Aversif faible contrôle
        (3, 0, 0, +0.90, -0.90),  # Cell 3: Q4 (+X, -Y) Calme / Accommodation secondaire
    ]

    # Séquences de profondeur Z respectant strictement |Delta Z| <= 1 (Option 2a)
    z_patterns = [
        [2, 3, 3, 2],
        [2, 3, 4, 3],
        [3, 4, 5, 4],
        [4, 3, 2, 2],
    ]

    cell_id_list: list[int] = []
    vol_list: list[int] = []
    ctrl_list: list[int] = []
    z_list: list[int] = []
    kind_list: list[int] = []
    pole_list: list[int] = []
    fbx_list: list[float] = []
    fby_list: list[float] = []
    urg_list: list[float] = []
    sec_list: list[float] = []
    cue_list: list[float] = []

    # Niveaux d'urgence symétriques (moyenne exactement 0)
    urg_levels = np.array([-1.0, -0.5, +0.5, +1.0], dtype=np.float64)

    for c_idx, (cid, v_hi, c_hi, bx, by) in enumerate(cells):
        # --- Partie A : 28 essais diagonaux avec inversions mono-axe (identifie rho, p, beta) ---
        # Sous-blocs de 7 essais : stable -> inversion X seul -> retour -> inversion Y seul
        sub_targets = [
            (bx, by),
            (-bx, by),
            (bx, by),
            (bx, -by),
        ]
        z_seq = z_patterns[c_idx]
        for sub_i, (tx, ty) in enumerate(sub_targets):
            z_val = z_seq[sub_i]
            # Urgence équilibrée sur le sous-bloc
            u_sub = rng.permutation(np.array([-1.0, -0.5, -0.5, 0.0, 0.5, 0.5, 1.0]))
            for k in range(7):
                # Léger bruit d'évidence sensorielle du stimulus (observable par l'agent)
                fx = float(np.clip(tx + rng.normal(0.0, 0.10), -1.0, 1.0))
                fy = float(np.clip(ty + rng.normal(0.0, 0.10), -1.0, 1.0))
                cell_id_list.append(cid)
                vol_list.append(v_hi)
                ctrl_list.append(c_hi)
                z_list.append(z_val)
                kind_list.append(0)
                pole_list.append(-1)
                fbx_list.append(fx)
                fby_list.append(fy)
                urg_list.append(float(u_sub[k]))
                sec_list.append(0.0)
                cue_list.append(float(1.0 if ((sub_i * 7 + k) % 2 == 0) else -1.0))

        # --- Partie B : 16 épisodes axiaux en 2 pas = 32 essais (4 par pôle axial) ---
        # Pôles : 0=Peur (-X,0), 1=Tristesse (0,-Y), 2=Courage (+X,0), 3=Joie (0,+Y)
        poles_block = np.repeat([0, 1, 2, 3], 4)
        poles_block = rng.permutation(poles_block)
        # Urgences parfaitement équilibrées par pôle
        u_ep_step1 = np.tile(urg_levels, 4)
        u_ep_step2 = -u_ep_step1  # Somme exactement nulle sur chaque épisode
        sec_dirs = np.tile(np.array([-1.0, +1.0]), 8)
        rng.shuffle(sec_dirs)

        z_axial = 2  # Couronne canonique Z = 2 (fondation P2 Option 3b)
        for ep_i, pole in enumerate(poles_block):
            pole_int = int(pole)
            sd = float(sec_dirs[ep_i])
            u1 = float(u_ep_step1[ep_i])
            u2 = float(u_ep_step2[ep_i])

            # Step 1 : amorçage axial unilatéral (un seul axe saillant)
            if pole_int == 0:      # Peur (-X, 0)
                fx1, fy1 = -0.92, 0.0
            elif pole_int == 1:    # Tristesse (0, -Y)
                fx1, fy1 = 0.0, -0.92
            elif pole_int == 2:    # Courage (+X, 0)
                fx1, fy1 = +0.92, 0.0
            else:                  # Joie (0, +Y)
                fx1, fy1 = 0.0, +0.92

            # Step 1
            cell_id_list.append(cid)
            vol_list.append(v_hi)
            ctrl_list.append(c_hi)
            z_list.append(z_axial)
            kind_list.append(1)
            pole_list.append(pole_int)
            fbx_list.append(fx1)
            fby_list.append(fy1)
            urg_list.append(u1)
            sec_list.append(0.0)
            cue_list.append(1.0 if ep_i % 2 == 0 else -1.0)

            # Step 2 : suivi dynamique Option 3b (contagion sur Peur/Tristesse ; relaxation sur Courage/Joie)
            cell_id_list.append(cid)
            vol_list.append(v_hi)
            ctrl_list.append(c_hi)
            z_list.append(z_axial)
            kind_list.append(2)
            pole_list.append(pole_int)
            fbx_list.append(fx1)
            fby_list.append(fy1)
            urg_list.append(u2)
            sec_list.append(sd)
            cue_list.append(-1.0 if ep_i % 2 == 0 else 1.0)

    n_trials = len(cell_id_list)
    return TaskSchedule(
        num_trials=n_trials,
        cell_id=np.asarray(cell_id_list, dtype=np.int32),
        volatility_high=np.asarray(vol_list, dtype=np.int32),
        control_high=np.asarray(ctrl_list, dtype=np.int32),
        depth_z=np.asarray(z_list, dtype=np.int32),
        trial_kind=np.asarray(kind_list, dtype=np.int32),
        axial_pole=np.asarray(pole_list, dtype=np.int32),
        fb_x=np.asarray(fbx_list, dtype=np.float64),
        fb_y=np.asarray(fby_list, dtype=np.float64),
        urgency_u=np.asarray(urg_list, dtype=np.float64),
        sec_dir=np.asarray(sec_list, dtype=np.float64),
        stim_cue=np.asarray(cue_list, dtype=np.float64),
    )


# =============================================================================
# 3. TRAJECTOIRE LATENTE, GÉNÉRATION SYNTHÉTIQUE ET VRAISEMBLANCE EXACTE
# =============================================================================

@dataclass(frozen=True)
class SyntheticAgentData:
    """Observations comportementales réalistes d'un agent synthétique (Likert 1-7 + MCAR + choix)."""

    likert_x: np.ndarray        # int32 in {1..7} (valide si mask_x == True)
    likert_y: np.ndarray        # int32 in {1..7} (valide si mask_y == True)
    likert_a: np.ndarray        # int32 in {1..7} (valide si mask_a == True)
    mask_x: np.ndarray          # bool (90 % observé, 10 % MCAR manquant)
    mask_y: np.ndarray          # bool (90 % observé, 10 % MCAR manquant)
    mask_a: np.ndarray          # bool (90 % observé, 10 % MCAR manquant)
    actions: np.ndarray         # int32 in {0, 1, 2} (choix avec bruit moteur 5 %)
    axial_to_diag_obs: np.ndarray  # int32 in {-1=n/a, 0=non-diag, 1=bifurcation diag}
    true_a_trace: np.ndarray    # trace interne de diagnostic Option 1A
    true_y_trace: np.ndarray    # trace interne de diagnostic Option 1A


def forward_latent_trajectory(
    theta: tuple[float, float, float, float, float],
    sched: TaskSchedule,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """Calcule la trajectoire déterministe latente `(mu_x, mu_y, mu_a, q_vals, p_bif_diag)`.

    Équations v3.0 strictement alignées sur `DECISIONS_V3.md` et `66d9a0d` :
      1. Croyances internes `(b_X, b_Y)` mises à jour à vitesse centrée `rho_eff(Z)`.
      2. Plan cognitif `(X, Y)` à surface remplie :
         `(x_t, y_t) = A_t * R(Z_t) * (u_X, u_Y)` sous `|u_X|^p + |u_Y|^p = 1`,
         soit en coordonnées normalisées de strate `mu_x = x_t / R(Z_t) = A_t * u_X`
         et `mu_y = y_t / R(Z_t) = A_t * u_Y`.
      3. Canal autonome `A_t = A_min + (1 - A_min) * sigmoid(gamma_A * urgency_u_t)`,
         strictement indépendant du signe de `Y_t` (Option 1A).
      4. Option 3b : en Step 2 d'un épisode axial, seuls `Peur` (pole 0) et `Tristesse`
         (pole 1) subissent la contagion inter-boucles `chi > 0` vers l'axe complémentaire
         et la bifurcation diagonale ; `Courage` (pole 2) et `Joie` (pole 3) ont contagion 0
         et relaxent vers `Veille`.
      5. Valeurs d'action `Q(a)` (3 actions) dépendant des croyances courantes et de l'indice,
         avec précision décisionnelle unique `beta`.
    """
    rho, p_exp, gamma_a, chi, _beta = theta
    T = sched.num_trials

    mu_x = np.zeros(T, dtype=np.float64)
    mu_y = np.zeros(T, dtype=np.float64)
    q_vals = np.zeros((T, 3), dtype=np.float64)
    p_bif_diag = np.full(T, -1.0, dtype=np.float64)

    # Canal autonome A_t in (A_min, 1.0] strictement indépendant de sgn(Y_t)
    mu_a = A_MIN_FLOOR + (1.0 - A_MIN_FLOOR) * expit(gamma_a * sched.urgency_u)

    b_x = 0.0
    b_y = 0.0
    # Taux d'inertie centré sur Z_ref = 2 (élimine la colinéarité alpha_0 / gamma_alpha)
    rho_by_z = np.clip(rho / (1.0 + DEPTH_INERTIA_SLOPE * (sched.depth_z - 2.0)), 0.04, 0.95)

    for t in range(T):
        kind = int(sched.trial_kind[t])
        pole = int(sched.axial_pole[t])
        fx = float(sched.fb_x[t])
        fy = float(sched.fb_y[t])
        cue = float(sched.stim_cue[t])

        if kind == 0:
            # 1. Choix comportemental fondé STRICTEMENT sur la croyance interne pré-essai
            #    (b_x, b_y) avant l'observation de l'issue (zéro fuite temporelle) :
            #    - Action 0 : approche guidée par l'indice (+cue * b_x + 0.50 * b_y)
            #    - Action 1 : alternative opposée (-cue * b_x + 0.50 * b_y)
            #    - Action 2 : retrait / accommodation pragmatique (-0.85 * b_y)
            q_vals[t, 0] = +0.90 * cue * b_x + 0.50 * b_y
            q_vals[t, 1] = -0.90 * cue * b_x + 0.50 * b_y
            q_vals[t, 2] = -0.85 * b_y

            # 2. Mise à jour dynamique des croyances après retour d'évidence (identifie rho)
            lr = float(rho_by_z[t])
            b_x = (1.0 - lr) * b_x + lr * fx
            b_y = (1.0 - lr) * b_y + lr * fy
            e_x = b_x
            e_y = b_y
        elif kind == 1:
            # Step 1 axial : un seul axe engagé par l'amorce sensorielle de l'essai
            e_x = fx
            e_y = fy
            q_vals[t, 0] = +0.85 * cue * (fx if fx != 0.0 else fy)
            q_vals[t, 1] = -0.85 * cue * (fx if fx != 0.0 else fy)
            q_vals[t, 2] = -0.65 * fy
        else:
            # Step 2 axial : asymétrie dynamique Option 3b (Charge négative vs Décharge positive)
            sd = float(sched.sec_dir[t])
            if pole == 0:
                # Peur (-X, 0) : pôle en Charge négative -> contagion chi sur Y (Colère / Dégoût)
                e_x = fx
                e_y = chi * sd * abs(fx)
                p_bif_diag[t] = 0.05 + 0.90 * chi
            elif pole == 1:
                # Tristesse (0, -Y) : pôle en Charge négative -> contagion chi sur X (Calme / Dégoût)
                e_y = fy
                e_x = chi * sd * abs(fy)
                p_bif_diag[t] = 0.05 + 0.90 * chi
            elif pole == 2:
                # Courage (+X, 0) : pôle en Décharge positive -> 0 contagion, relaxation vers Veille
                e_x = DISCHARGE_DISSIPATION * fx
                e_y = 0.0
                p_bif_diag[t] = 0.05  # bruit exogène basal uniquement (chi_pos == 0)
            else:
                # Joie (0, +Y) : pôle en Décharge positive -> 0 contagion, relaxation vers Veille
                e_x = 0.0
                e_y = DISCHARGE_DISSIPATION * fy
                p_bif_diag[t] = 0.05  # bruit exogène basal uniquement (chi_pos == 0)

            q_vals[t, 0] = +0.85 * cue * (fx if fx != 0.0 else fy)
            q_vals[t, 1] = -0.85 * cue * (fx if fx != 0.0 else fy)
            q_vals[t, 2] = -0.65 * fy

        # Projection sur la sphère unité L_p : |u_X|^p + |u_Y|^p = 1
        ax = abs(e_x)
        ay = abs(e_y)
        norm_p = (ax ** p_exp + ay ** p_exp) ** (1.0 / p_exp)
        if norm_p > 1e-9:
            # Modulation d'amplitude douce pour les transitoires proches de zéro lors d'inversions
            # tout en saturant sur la sphère unité L_p dès que le signal est franc (|e| >= 0.4)
            u_x = e_x / norm_p
            u_y = e_y / norm_p
        else:
            u_x = 0.0
            u_y = 0.0

        # Surface remplie : (x, y) = A_t * R(Z_t) * (u_X, u_Y) -> coordonnées normalisées (mu_x, mu_y)
        a_t = float(mu_a[t])
        # Pour Courage/Joie en relaxation Step 2, le rayon effectif décroît vers Veille
        if kind == 2 and pole in (2, 3):
            scale_relax = DISCHARGE_DISSIPATION
        else:
            scale_relax = 1.0
        mu_x[t] = a_t * scale_relax * u_x
        mu_y[t] = a_t * scale_relax * u_y

    return mu_x, mu_y, mu_a, q_vals, p_bif_diag


def simulate_agent(
    theta: tuple[float, float, float, float, float],
    sched: TaskSchedule,
    rng: np.random.Generator,
) -> SyntheticAgentData:
    """Simule un agent synthétique sous bruit humain réaliste (Likert 1-7, 10 % MCAR, bruit moteur)."""
    mu_x, mu_y, mu_a, q_vals, p_bif_diag = forward_latent_trajectory(theta, sched)
    _rho, _p_exp, _gamma_a, _chi, beta = theta
    T = sched.num_trials

    # 1. Réponses ordinales Likert 1-7 bruitées
    lat_x = mu_x + rng.normal(0.0, SIGMA_XY_LIKERT, size=T)
    lat_y = mu_y + rng.normal(0.0, SIGMA_XY_LIKERT, size=T)
    lat_a = mu_a + rng.normal(0.0, SIGMA_A_LIKERT, size=T)

    likert_x = _discretize_likert(lat_x, CUTPOINTS_BIPOLAR)
    likert_y = _discretize_likert(lat_y, CUTPOINTS_BIPOLAR)
    likert_a = _discretize_likert(lat_a, CUTPOINTS_UNIPOLAR)

    # 2. 10 % de données manquantes MCAR indépendantes sur chaque canal de réponse
    mask_x = rng.random(T) >= MISSING_MCAR_RATE
    mask_y = rng.random(T) >= MISSING_MCAR_RATE
    mask_a = rng.random(T) >= MISSING_MCAR_RATE

    # 3. Choix comportementaux sous softmax(beta * Q) + 5 % de bruit moteur (lapse)
    logits = beta * q_vals
    logits -= np.max(logits, axis=1, keepdims=True)
    exp_l = np.exp(logits)
    probs = exp_l / np.sum(exp_l, axis=1, keepdims=True)
    probs = (1.0 - MOTOR_LAPSE_RATE) * probs + (MOTOR_LAPSE_RATE / 3.0)

    u_rand = rng.random(T)
    cdf = np.cumsum(probs, axis=1)
    actions = np.sum(u_rand[:, None] > cdf, axis=1).astype(np.int32)
    actions = np.clip(actions, 0, 2)

    # 4. Indicateur de bifurcation diagonale en Step 2 des épisodes axiaux (avec 10 % MCAR)
    axial_to_diag_obs = np.full(T, -1, dtype=np.int32)
    is_step2 = p_bif_diag >= 0.0
    step2_indices = np.flatnonzero(is_step2)
    for idx in step2_indices:
        if rng.random() >= MISSING_MCAR_RATE:
            axial_to_diag_obs[idx] = 1 if rng.random() < p_bif_diag[idx] else 0

    return SyntheticAgentData(
        likert_x=likert_x,
        likert_y=likert_y,
        likert_a=likert_a,
        mask_x=mask_x,
        mask_y=mask_y,
        mask_a=mask_a,
        actions=actions,
        axial_to_diag_obs=axial_to_diag_obs,
        true_a_trace=mu_a,
        true_y_trace=mu_y,
    )


def neg_log_posterior(
    theta_vec: np.ndarray,
    data: SyntheticAgentData,
    sched: TaskSchedule,
) -> float:
    """Log-vraisemblance négative exacte (probit ordonné + choix + bifurcation P2) + prior faible."""
    rho, p_exp, gamma_a, chi, beta = (
        float(theta_vec[0]),
        float(theta_vec[1]),
        float(theta_vec[2]),
        float(theta_vec[3]),
        float(theta_vec[4]),
    )
    mu_x, mu_y, mu_a, q_vals, p_bif_diag = forward_latent_trajectory(
        (rho, p_exp, gamma_a, chi, beta), sched
    )

    # 1. Probit ordonné Likert 1-7 avec gestion exacte des 10 % MCAR
    ll_x = _ordered_probit_loglik(data.likert_x, data.mask_x, mu_x, SIGMA_XY_LIKERT, CUTPOINTS_BIPOLAR)
    ll_y = _ordered_probit_loglik(data.likert_y, data.mask_y, mu_y, SIGMA_XY_LIKERT, CUTPOINTS_BIPOLAR)
    ll_a = _ordered_probit_loglik(data.likert_a, data.mask_a, mu_a, SIGMA_A_LIKERT, CUTPOINTS_UNIPOLAR)

    # 2. Vraisemblance des choix comportementaux (softmax + 5 % bruit moteur)
    logits = beta * q_vals
    logits -= np.max(logits, axis=1, keepdims=True)
    exp_l = np.exp(logits)
    probs = exp_l / np.sum(exp_l, axis=1, keepdims=True)
    probs = (1.0 - MOTOR_LAPSE_RATE) * probs + (MOTOR_LAPSE_RATE / 3.0)
    chosen_p = np.clip(probs[np.arange(sched.num_trials), data.actions], 1e-12, 1.0)
    ll_act = float(np.sum(np.log(chosen_p)))

    # 3. Vraisemblance de bifurcation axiale -> diagonale Option 3b (Step 2 Charge négative)
    obs_bif = data.axial_to_diag_obs >= 0
    if np.any(obs_bif):
        yb = data.axial_to_diag_obs[obs_bif].astype(np.float64)
        pb = np.clip(p_bif_diag[obs_bif], 1e-9, 1.0 - 1e-9)
        ll_bif = float(np.sum(yb * np.log(pb) + (1.0 - yb) * np.log(1.0 - pb)))
    else:
        ll_bif = 0.0

    # Prior faiblement informatif sur la boîte admissible (évite les divergences aux bornes
    # sans biaiser ni rétrécir la récupération)
    log_prior = 0.0
    for val, pname in zip(theta_vec, PARAM_NAMES):
        lo, hi = PARAM_BOUNDS[pname]
        mid = 0.5 * (lo + hi)
        half_w = 0.5 * (hi - lo)
        # Normal très large (écart-type = 2.0 * demi-largeur)
        z = (val - mid) / (2.0 * half_w)
        log_prior += -0.5 * z * z

    return -(ll_x + ll_y + ll_a + ll_act + ll_bif + log_prior)


def estimate_agent_parameters(
    data: SyntheticAgentData,
    sched: TaskSchedule,
) -> tuple[np.ndarray, bool]:
    """Estime `theta_hat` par L-BFGS-B multi-start (3 points de départ déterministes)."""
    bounds = [PARAM_BOUNDS[p] for p in PARAM_NAMES]
    starts = [
        np.array([0.50, 1.50, 2.00, 0.45, 2.50], dtype=np.float64),
        np.array([0.30, 1.05, 1.20, 0.25, 1.50], dtype=np.float64),
        np.array([0.70, 2.05, 2.80, 0.70, 3.60], dtype=np.float64),
    ]
    best_x = starts[0]
    best_fun = float("inf")
    best_ok = False
    for x0 in starts:
        res = minimize(
            neg_log_posterior,
            x0=x0,
            args=(data, sched),
            method="L-BFGS-B",
            bounds=bounds,
            options={"maxiter": 150, "ftol": 1e-7},
        )
        if float(res.fun) < best_fun:
            best_fun = float(res.fun)
            best_x = np.asarray(res.x, dtype=np.float64)
            best_ok = bool(res.success)
    return best_x, best_ok


# =============================================================================
# 4. DIAGNOSTIC DE LA COLINÉARITÉ V2 (`exp03_parameter_error_corr_matrix.csv`)
# =============================================================================

def diagnose_v2_collinearity(repo_root: Path) -> dict[str, Any]:
    """Lit `exp03_parameter_error_corr_matrix.csv` et extrait les paires colinéaires v2."""
    csv_path = repo_root / "extensions/in_silico/results/exp03_parameter_error_corr_matrix.csv"
    if not csv_path.is_file():
        return {"source_present": False}

    with csv_path.open("r", encoding="utf-8", newline="") as fh:
        rows = list(csv.reader(fh))
    headers = rows[0][1:]
    mat = np.array([[float(v) for v in r[1:]] for r in rows[1:]], dtype=np.float64)

    off = mat.copy()
    np.fill_diagonal(off, 0.0)
    idx_a0 = headers.index("alpha_0")
    idx_ga = headers.index("gamma_alpha")
    idx_bx = headers.index("beta_X")
    idx_by = headers.index("beta_Y")

    offending_pairs: list[dict[str, Any]] = []
    for i in range(len(headers)):
        for j in range(i + 1, len(headers)):
            val = float(mat[i, j])
            if abs(val) >= MAX_OFFDIAG_ERR_CORR_THRESHOLD:
                offending_pairs.append(
                    {"pair": f"{headers[i]} / {headers[j]}", "error_corr": round(val, 6)}
                )

    return {
        "source_file": "extensions/in_silico/results/exp03_parameter_error_corr_matrix.csv",
        "num_v2_free_parameters": len(headers),
        "alpha_0_vs_gamma_alpha_error_corr": round(float(mat[idx_a0, idx_ga]), 6),
        "beta_X_vs_beta_Y_error_corr": round(float(mat[idx_bx, idx_by]), 6),
        "max_abs_off_diag_error_corr_v2": round(float(np.max(np.abs(off))), 6),
        "offending_pairs_ge_0_35": offending_pairs,
        "root_causes": [
            "alpha_0 / gamma_alpha (-0.813): non-centrage de l'ordonnée à l'origine alpha(Z) = alpha_0 * exp(gamma_alpha * Z) évaluée à Z=0 loin du centroïde empirique de Z.",
            "beta_X / beta_Y (+0.667): double température sur un même softmax de choix aggravée par la reparamétrisation couplée beta_X = beta_Y + delta_beta.",
        ],
    }


# =============================================================================
# 5. EXÉCUTION PRINCIPALE DU `synthetic_identifiability_check`
# =============================================================================

def run_synthetic_identifiability_check(
    num_agents: int = 80,
    seed: int = 20260301,
    repo_root: Path | None = None,
) -> dict[str, Any]:
    """Exécute le `synthetic_identifiability_check` complet et vérifie les seuils bloquants."""
    if num_agents < 60:
        raise ValueError(f"num_agents doit être >= 60 (reçu {num_agents}).")

    root = Path(__file__).resolve().parents[3] if repo_root is None else repo_root.resolve()
    t0 = time.perf_counter()

    sched = build_orthogonal_2x2_schedule(seed=seed)
    rng = np.random.default_rng(seed + 1009)

    n_params = len(PARAM_NAMES)
    true_mat = np.zeros((num_agents, n_params), dtype=np.float64)
    est_mat = np.zeros((num_agents, n_params), dtype=np.float64)
    conv_flags = np.zeros(num_agents, dtype=bool)

    # Diagnostics structurels (Option 1A, Option 3b, MCAR)
    obs_missing_rates: list[float] = []
    a_vs_sgny_corrs: list[float] = []
    charge_bif_rates: list[float] = []
    discharge_bif_rates: list[float] = []

    for i in range(num_agents):
        # Tirage indépendant sur les plages larges non rétrécies
        theta_true = tuple(
            float(rng.uniform(*PARAM_BOUNDS[pname])) for pname in PARAM_NAMES
        )
        true_mat[i, :] = theta_true

        agent_rng = np.random.default_rng(seed + 10_000 + i)
        data = simulate_agent(theta_true, sched, agent_rng)

        # Contrôle du taux MCAR effectivement simulé
        total_likert = 3 * sched.num_trials
        missing_count = int(
            np.sum(~data.mask_x) + np.sum(~data.mask_y) + np.sum(~data.mask_a)
        )
        obs_missing_rates.append(missing_count / total_likert)

        # Contrôle Option 1A : orthogonalité de A par rapport à sgn(Y)
        nz_y = np.abs(data.true_y_trace) > 1e-6
        if np.any(nz_y):
            r_ay = float(
                np.corrcoef(data.true_a_trace[nz_y], np.sign(data.true_y_trace[nz_y]))[0, 1]
            )
            if math.isfinite(r_ay):
                a_vs_sgny_corrs.append(r_ay)

        # Contrôle Option 3b : taux empirique de bifurcation Charge négative vs Décharge positive
        is_step2_charge = (sched.trial_kind == 2) & np.isin(sched.axial_pole, [0, 1]) & (data.axial_to_diag_obs >= 0)
        is_step2_discharge = (sched.trial_kind == 2) & np.isin(sched.axial_pole, [2, 3]) & (data.axial_to_diag_obs >= 0)
        if np.any(is_step2_charge):
            charge_bif_rates.append(float(np.mean(data.axial_to_diag_obs[is_step2_charge])))
        if np.any(is_step2_discharge):
            discharge_bif_rates.append(float(np.mean(data.axial_to_diag_obs[is_step2_discharge])))

        theta_hat, ok = estimate_agent_parameters(data, sched)
        est_mat[i, :] = theta_hat
        conv_flags[i] = ok

    # Métriques de récupération vrai-vs-estimé
    recovery_metrics: dict[str, dict[str, float]] = {}
    recovery_r_values: dict[str, float] = {}
    for j, pname in enumerate(PARAM_NAMES):
        t_col = true_mat[:, j]
        e_col = est_mat[:, j]
        r_val = float(np.corrcoef(t_col, e_col)[0, 1])
        rmse = float(np.sqrt(np.mean((e_col - t_col) ** 2)))
        bias = float(np.mean(e_col - t_col))
        mae = float(np.mean(np.abs(e_col - t_col)))
        recovery_r_values[pname] = r_val
        recovery_metrics[pname] = {
            "pearson_r": round(r_val, 6),
            "rmse": round(rmse, 6),
            "mae": round(mae, 6),
            "bias": round(bias, 6),
            "prior_range": [PARAM_BOUNDS[pname][0], PARAM_BOUNDS[pname][1]],
        }

    # Matrice complète de corrélation des erreurs d'estimation (theta_hat - theta_true)
    err_mat = est_mat - true_mat
    err_corr_mat = np.corrcoef(err_mat, rowvar=False)
    off_diag = err_corr_mat.copy()
    np.fill_diagonal(off_diag, 0.0)

    min_r_recovery = float(min(recovery_r_values.values()))
    max_abs_off_diag = float(np.max(np.abs(off_diag)))

    # Identification de la paire hors-diagonale maximale
    max_pair = ""
    max_pair_val = 0.0
    for i in range(n_params):
        for j in range(i + 1, n_params):
            if abs(float(err_corr_mat[i, j])) > abs(max_pair_val):
                max_pair_val = float(err_corr_mat[i, j])
                max_pair = f"{PARAM_NAMES[i]} / {PARAM_NAMES[j]}"

    # Matrice nommée pour lisibilité complète dans le JSON
    err_corr_named: dict[str, dict[str, float]] = {
        p_row: {
            p_col: round(float(err_corr_mat[i, j]), 6)
            for j, p_col in enumerate(PARAM_NAMES)
        }
        for i, p_row in enumerate(PARAM_NAMES)
    }

    mean_a_sgny_corr = float(np.mean(a_vs_sgny_corrs)) if a_vs_sgny_corrs else 0.0
    mean_charge_bif = float(np.mean(charge_bif_rates)) if charge_bif_rates else 0.0
    mean_discharge_bif = float(np.mean(discharge_bif_rates)) if discharge_bif_rates else 0.0
    elapsed_s = round(time.perf_counter() - t0, 3)

    v2_diag = diagnose_v2_collinearity(root)

    checks_passed = (
        min_r_recovery >= MIN_RECOVERY_R_THRESHOLD
        and max_abs_off_diag < MAX_OFFDIAG_ERR_CORR_THRESHOLD
        and abs(mean_a_sgny_corr) < 0.10
        and mean_charge_bif > mean_discharge_bif + 0.20
    )

    report: dict[str, Any] = {
        "check_name": "synthetic_identifiability_check",
        "epistemic_status": "synthetic_identifiability_check",
        "epistemic_warning": (
            "STRICTLY SYNTHETIC IDENTIFIABILITY CHECK (V3 = 0). "
            "No human empirical data, no external validation, and no clinical result."
        ),
        "V3_empirical_validation": 0,
        "aligned_commit_spec": "66d9a0d",
        "model_spec": {
            "name": "CARTOGRAFFECT_v3_orthogonalized_5param",
            "num_free_parameters": n_params,
            "parameters": list(PARAM_NAMES),
            "filled_surface_equation": "(x, y) = A * R(Z) * (u_X, u_Y), |u_X|^p + |u_Y|^p = 1",
            "option_1A_autonomous_A": "A_t = 0.15 + 0.85 * sigmoid(gamma_A * urgency_u_t), strictly decoupled from sgn(Y_t)",
            "option_2a_vertical_Z": "Stepwise Z in {2, 3, 4, 5}, |Delta Z| <= 1, centered inertia at Z_ref = 2",
            "option_3b_asymmetric_p2": "Cross-loop contagion chi > 0 strictly restricted to negative Charge axial poles (Peur, Tristesse); chi = 0 on positive Discharge poles (Courage, Joie)",
        },
        "simulation_design": {
            "task": "Orthogonal 2x2 (Volatility x Controllability) with embedded axial P2 episodes",
            "num_synthetic_agents": num_agents,
            "num_trials_per_agent": sched.num_trials,
            "seed": seed,
            "likert_scale": "1-7 ordinal (exact ordered probit likelihood)",
            "sigma_XY_likert": SIGMA_XY_LIKERT,
            "sigma_A_likert": SIGMA_A_LIKERT,
            "missing_data_mcar_target": MISSING_MCAR_RATE,
            "missing_data_mcar_observed_mean": round(float(np.mean(obs_missing_rates)), 6),
            "motor_lapse_rate": MOTOR_LAPSE_RATE,
            "optimizer": "scipy.optimize.minimize (L-BFGS-B, 3 deterministic multi-starts)",
            "optimizer_convergence_rate": round(float(np.mean(conv_flags)), 6),
        },
        "environment": {
            "python_version": platform.python_version(),
            "os": platform.system(),
            "numpy_version": np.__version__,
            "scipy_version": scipy.__version__,
            "runtime_seconds": elapsed_s,
            "script_path": "extensions/in_silico/scripts/v3_identifiability_check.py",
        },
        "v2_collinearity_diagnosis": v2_diag,
        "v3_recovery_metrics": recovery_metrics,
        "v3_error_correlation_matrix": err_corr_named,
        "v3_architectural_invariants_check": {
            "option_1A_mean_corr_A_vs_sgnY": round(mean_a_sgny_corr, 6),
            "option_1A_orthogonal_lt_0_10": bool(abs(mean_a_sgny_corr) < 0.10),
            "option_3b_charge_bifurcation_rate": round(mean_charge_bif, 6),
            "option_3b_discharge_bifurcation_rate": round(mean_discharge_bif, 6),
            "option_3b_asymmetry_verified": bool(mean_charge_bif > mean_discharge_bif + 0.20),
        },
        "thresholds_and_verdict": {
            "min_r_recovery": round(min_r_recovery, 6),
            "required_min_r_recovery": MIN_RECOVERY_R_THRESHOLD,
            "min_r_recovery_passed": bool(min_r_recovery >= MIN_RECOVERY_R_THRESHOLD),
            "max_abs_off_diag_error_corr": round(max_abs_off_diag, 6),
            "max_off_diag_pair": max_pair,
            "max_off_diag_value": round(max_pair_val, 6),
            "required_max_abs_off_diag_lt": MAX_OFFDIAG_ERR_CORR_THRESHOLD,
            "max_abs_off_diag_passed": bool(max_abs_off_diag < MAX_OFFDIAG_ERR_CORR_THRESHOLD),
            "overall_status": "PASS" if checks_passed else "FAIL",
        },
    }

    out_path = root / "extensions/in_silico/results/v3_identifiability_report.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    # Garde-fous bloquants (AssertionError obligatoire si non satisfaits)
    if min_r_recovery < MIN_RECOVERY_R_THRESHOLD:
        raise AssertionError(
            f"ÉCHEC IDENTIFIABILITÉ : min_r_recovery = {min_r_recovery:.4f} "
            f"< {MIN_RECOVERY_R_THRESHOLD:.2f} ({recovery_r_values})"
        )
    if max_abs_off_diag >= MAX_OFFDIAG_ERR_CORR_THRESHOLD:
        raise AssertionError(
            f"ÉCHEC COLINÉARITÉ : max |r_off_diag| = {max_abs_off_diag:.4f} "
            f">= {MAX_OFFDIAG_ERR_CORR_THRESHOLD:.2f} (paire {max_pair} = {max_pair_val:.4f})"
        )
    if abs(mean_a_sgny_corr) >= 0.10:
        raise AssertionError(
            f"ÉCHEC OPTION 1A : |Corr(A, sgn(Y))| = {abs(mean_a_sgny_corr):.4f} >= 0.10"
        )
    if not (mean_charge_bif > mean_discharge_bif + 0.20):
        raise AssertionError(
            f"ÉCHEC OPTION 3b : bifurcation Charge ({mean_charge_bif:.4f}) "
            f"non nettement supérieure à Décharge ({mean_discharge_bif:.4f})"
        )

    return report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="CARTOGRAFFECT v3.0 — synthetic_identifiability_check (5 paramètres orthogonalisés)."
    )
    parser.add_argument("--agents", type=int, default=80, help="Nombre d'agents synthétiques (>= 60).")
    parser.add_argument("--seed", type=int, default=20260301, help="Graine PRNG fixée et documentée.")
    args = parser.parse_args(argv)

    report = run_synthetic_identifiability_check(num_agents=args.agents, seed=args.seed)
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
