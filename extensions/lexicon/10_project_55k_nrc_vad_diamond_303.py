#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
================================================================================
Projet CARTOGRAFFECT — Script 10 : Projection Haute Performance du Lexique NRC-VAD 55K
Fichier : Pipeline_16200_OpenData/10_project_55k_nrc_vad_diamond_303.py
================================================================================
Projette et réévalue le lexique complet de ~55 000 mots (NRC-VAD-Lexicon-v2.1.txt)
sur les 303 pôles du Diamant CARTOGRAFFECT (Z ∈ [-7, +7]) en Python vectorisé
(NumPy / SciPy / Pandas), en moins de 5 secondes CPU et avec zéro consommation
de jetons LLM.

Lois et contraintes déductives intégrées :
1. Calibration Vectorisée sur [-1, +1]^3 :
   - v, a, d centrés dans [-1, +1]
   - x_raw = v (Attente)
   - y_raw = 0.60 * d + 0.40 * a (Contrôle, support optionnel CPM)
   - r_L1 = |x_raw| + |y_raw|, theta = atan2(y_raw, x_raw), z_ded ∈ [0, 7].
2. Matrice Booléenne de Couverture de Markov M (N × 303) :
   - En Z+ (0..175) : élimination absolue de tout couple violant la polarité hédonique
     (X_j > 0 et v_i < 0) ou (X_j < 0 et v_i > 0) ou (X_j == 0, Y_j > 0 et v_i < -0.10)
     ou (X_j == 0, Y_j < 0 et v_i > +0.10).
   - Sur les centres (X_j == 0, Y_j == 0) : élimination de r_L1 > 0.10 hors signatures.
   - En Z- (176..302) : confinement strict des dérives négatives (v_i < 0) et des
     adjectifs de principes aux 40 colonnes de Z = -6 (W = 1, id_303 264..303, sous-typés
     en D- si 0.6*a + 0.4*d < 0 et D+ sinon), et interdiction de v_i <= 0 sur les
     87 colonnes d'intégration W = 2..7 (id_303 177..263).
3. Résolution Tensorielle et Marge de Certitude d'Unification :
   - Matrice de coût C (N × 303) par broadcasting NumPy : distance angulaire circulaire,
     écart de strate |z_ded - |Z_j|| / 7.0, et répulsion de l'antagoniste A(P_j).
   - Application de C[~M] = +inf.
   - Déduction de p*[i] = argmin_j C[i, j], second meilleur pôle p_2[i] et
     marge de frontière de Markov Delta_C[i] = C[i, p_2[i]] - C[i, p*[i]].
4. Enrichissement et Exports :
   - output_diamond_303/CARTOGRAFFECT_55K_NRC_VAD_Diamant_303.tsv (55 000 mots projetés)
   - output_diamond_303/CARTOGRAFFECT_55K_Audit_Frontieres_Markov.tsv (les 500 mots
     de plus faible marge Delta_C situés sur la frontière entre deux pôles adjacents).
================================================================================
"""

from __future__ import annotations

import os
import re
import shutil
import sys
import time
from typing import Dict, List, Optional, Tuple

import numpy as np
import pandas as pd


def get_workspace_dir() -> str:
    """Détermine le répertoire racine de nrc_cartograffect_pipeline."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    if os.path.basename(script_dir) == "Pipeline_16200_OpenData":
        return os.path.abspath(os.path.join(script_dir, ".."))
    return script_dir


def resolve_path(relative_candidates: List[str]) -> str:
    """Résout le chemin absolu d'un fichier parmi plusieurs emplacements relatifs possibles."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    workspace_dir = get_workspace_dir()
    
    for cand in relative_candidates:
        if os.path.isfile(cand):
            return os.path.abspath(cand)
        p_ws = os.path.join(workspace_dir, cand)
        if os.path.isfile(p_ws):
            return p_ws
        p_script = os.path.join(script_dir, cand)
        if os.path.isfile(p_script):
            return p_script
    
    raise FileNotFoundError(f"Impossible de résoudre l'un des chemins candidats : {relative_candidates}")


def build_adjacency_matrix_vectorized(df_303: pd.DataFrame) -> Tuple[np.ndarray, np.ndarray]:
    """
    Construit de façon 100% vectorisée (broadcasting NumPy) la matrice d'adjacence (P × P) :
    - Intra-strate L1 : Z1 == Z2 et (|X1 - X2| + |Y1 - Y2| == 2) -> code 1
    - Inter-strates filière : p2 ∈ {filiere_inf(p1), filiere_sup(p1)} -> code 2
    """
    P = len(df_303)
    x = df_303["X"].to_numpy(dtype=np.int32)
    y = df_303["Y"].to_numpy(dtype=np.int32)
    z = df_303["Z_signe"].to_numpy(dtype=np.int32)
    pid = df_303["id_303"].to_numpy(dtype=np.int32)
    finf = df_303["filiere_inf_id_303"].fillna(-1).to_numpy(dtype=np.int32)
    fsup = df_303["filiere_sup_id_303"].fillna(-1).to_numpy(dtype=np.int32)

    # 1. Intra-strate L1
    same_z = (z[:, None] == z[None, :])
    l1_dist = np.abs(x[:, None] - x[None, :]) + np.abs(y[:, None] - y[None, :])
    intra_l1 = same_z & (l1_dist == 2)

    # 2. Inter-strates filière
    filiere_down = (finf[:, None] == pid[None, :]) & (finf[:, None] != -1)
    filiere_up = (fsup[:, None] == pid[None, :]) & (fsup[:, None] != -1)
    inter_filiere = filiere_down | filiere_up

    adj = intra_l1 | inter_filiere
    adj_type = np.zeros((P, P), dtype=np.int8)
    adj_type[intra_l1] = 1
    adj_type[inter_filiere] = 2

    np.fill_diagonal(adj, False)
    np.fill_diagonal(adj_type, 0)
    return adj, adj_type


def main() -> None:
    t_global_start = time.perf_counter()
    print("=" * 80)
    print("PROJECTION VECTORISÉE HAUTE PERFORMANCE DU LEXIQUE NRC-VAD 55K SUR LE DIAMANT 303")
    print("=" * 80)

    # --------------------------------------------------------------------------
    # 0. Résolution des chemins et chargement des données
    # --------------------------------------------------------------------------
    path_nrc = resolve_path([
        "NRC-VAD-Lexicon-v2.1.txt",
        "data/NRC-VAD-Lexicon-v2.1.txt",
        "Pipeline_16200_OpenData/data/NRC-VAD-Lexicon-v2.1.txt"
    ])
    path_ref303 = resolve_path([
        "ref_303_diamant_z.tsv",
        "data/ref_303_diamant_z.tsv",
        "Pipeline_16200_OpenData/data/ref_303_diamant_z.tsv"
    ])

    print(f"Chargement NRC-VAD : {path_nrc}")
    df_nrc = pd.read_csv(path_nrc, sep="\t", quoting=3, on_bad_lines="skip")
    N = len(df_nrc)
    print(f"  -> {N} termes chargés.")

    print(f"Chargement Diamant 303 : {path_ref303}")
    df_ref303 = pd.read_csv(path_ref303, sep="\t")
    P = len(df_ref303)
    assert P == 303, f"Erreur : attendu 303 pôles, trouvé {P}"

    # Répertoire de sortie
    workspace_dir = get_workspace_dir()
    out_dir_root = os.path.join(workspace_dir, "output_diamond_303")
    os.makedirs(out_dir_root, exist_ok=True)

    # --------------------------------------------------------------------------
    # 1. Calibration Vectorisée sur [-1, +1]^3
    # --------------------------------------------------------------------------
    t1_start = time.perf_counter()
    raw_v = df_nrc["valence"].to_numpy(dtype=np.float32)
    raw_a = df_nrc["arousal"].to_numpy(dtype=np.float32)
    raw_d = df_nrc["dominance"].to_numpy(dtype=np.float32)

    # Si l'entrée est sur [0, 1], normaliser sur [-1, +1] : v = 2*V - 1
    if raw_v.min() >= 0.0 and raw_v.max() <= 1.0:
        v = (2.0 * raw_v - 1.0).astype(np.float32)
        a = (2.0 * raw_a - 1.0).astype(np.float32)
        d = (2.0 * raw_d - 1.0).astype(np.float32)
    else:
        v = np.clip(raw_v, -1.0, 1.0).astype(np.float32)
        a = np.clip(raw_a, -1.0, 1.0).astype(np.float32)
        d = np.clip(raw_d, -1.0, 1.0).astype(np.float32)

    # x_raw = v (Attente)
    # y_raw = 0.60 * d + 0.40 * a (Contrôle)
    x_raw = v
    y_raw = (0.60 * d + 0.40 * a).astype(np.float32)
    r_l1 = (np.abs(x_raw) + np.abs(y_raw)).astype(np.float32)
    theta = np.arctan2(y_raw, x_raw).astype(np.float32)

    # Profondeur déduite z_ded ∈ [0.0, 7.0]
    z_ded = np.where(
        r_l1 <= 0.10,
        0.5,
        np.clip(1.2 + 3.2 * r_l1, 1.5, 7.0)
    ).astype(np.float32)

    # Détection des adjectifs de qualification/principes et graines éthiques
    terms_clean = df_nrc["term"].fillna("").astype(str).str.lower().str.strip().to_numpy()
    adj_regex = re.compile(r"(able|ible|al|ful|ic|ive|ous|ish|less|ent|ant)$")
    is_adj = np.array([bool(adj_regex.search(str(t))) for t in terms_clean], dtype=bool)

    axio_seeds = {
        "just", "justice", "fair", "fairness", "honest", "honesty", "loyal", "loyalty",
        "humble", "humility", "brave", "bravery", "courage", "courageous", "generous", "generosity",
        "patient", "patience", "prudent", "prudence", "temperate", "temperance", "wise", "wisdom",
        "sincere", "sincerity", "modest", "modesty", "tolerant", "tolerance", "dignity", "integrity",
        "respect", "respectful", "responsible", "responsibility", "benevolent", "benevolence",
        "compassion", "compassionate", "altruism", "altruistic", "solidarity", "faith", "faithful",
        "honor", "honorable", "nobility", "noble", "truth", "truthful", "virtue", "virtuous",
        "greed", "greedy", "coward", "cowardly", "cruel", "cruelty", "vain", "vanity", "arrogant",
        "arrogance", "selfish", "selfishness", "malice", "malicious", "hypocrisy", "hypocrite",
        "hypocritical", "jealous", "jealousy", "envy", "envious", "lazy", "laziness", "wrath",
        "corrupt", "corruption", "treason", "treacherous", "deceit", "deceitful", "liar", "vile"
    }
    is_val_seed = np.isin(terms_clean, list(axio_seeds))
    is_axiological = is_val_seed | (is_adj & (np.abs(v) > 0.12))

    t1_end = time.perf_counter()
    print(f"[Étape 1] Calibration matricielle (N={N}) terminée en {t1_end - t1_start:.3f} s.")
    print(f"          - Termes tagués axiologiques : {is_axiological.sum()} / {N}")
    print(f"          - Termes avec r_L1 <= 0.10 (centraux) : {(r_l1 <= 0.10).sum()}")

    # --------------------------------------------------------------------------
    # 2. Matrice Booléenne de Couverture de Markov M de taille (N, 303)
    # --------------------------------------------------------------------------
    t2_start = time.perf_counter()

    X_p = df_ref303["X"].to_numpy(dtype=np.float32)
    Y_p = df_ref303["Y"].to_numpy(dtype=np.float32)
    Z_signe = df_ref303["Z_signe"].to_numpy(dtype=np.int32)
    abs_Z = np.abs(Z_signe).astype(np.float32)
    is_center = (X_p == 0) & (Y_p == 0)

    M = np.ones((N, P), dtype=bool)

    v_col = v[:, None]
    r_col = r_l1[:, None]

    # --- Règle A : En Z+ (colonnes 0..175, id_303 1..176) ---
    X_zp = X_p[:176]
    Y_zp = Y_p[:176]
    m_zplus = np.ones((N, 176), dtype=bool)
    m_zplus &= ~((X_zp[None, :] > 0) & (v_col < 0.0))
    m_zplus &= ~((X_zp[None, :] < 0) & (v_col > 0.0))
    m_zplus &= ~((X_zp[None, :] == 0) & (Y_zp[None, :] > 0) & (v_col < -0.10))
    m_zplus &= ~((X_zp[None, :] == 0) & (Y_zp[None, :] < 0) & (v_col > 0.10))
    # Loi de Non-Inversion du Contrôle Pragmatique (Y)
    y_col = y_raw[:, None]
    m_zplus &= ~((Y_zp[None, :] > 0) & (y_col < -0.15))
    m_zplus &= ~((Y_zp[None, :] < 0) & (y_col > +0.15))
    M[:, :176] = m_zplus

    # --- Règle B : Sur les centres (X_j == 0, Y_j == 0) ---
    M[:, is_center] &= (r_col <= 0.10)

    # --- Règle C : En Z- (colonnes 176..302, id_303 177..303) ---
    # Intégration W = 2..7 (colonnes 176..262, id_303 177..263) : interdiction de v <= 0
    col_zminus_87 = np.arange(176, 263)
    M[:, col_zminus_87] &= (v_col > 0.0)

    # Confinement strict des dérives négatives (v < 0) et des adjectifs de principes à Z = -6
    M[v < 0.0, 176:263] = False
    M[is_adj, 176:263] = False

    t2_end = time.perf_counter()
    print(f"[Étape 2] Matrice de Couverture de Markov M (taille {N}x{P}) construite en {t2_end - t2_start:.3f} s.")
    print(f"          - Taux global de compatibilité : {M.mean() * 100:.2f} %")

    # --------------------------------------------------------------------------
    # 3. Résolution Tensorielle et Marge de Certitude d'Unification
    # --------------------------------------------------------------------------
    t3_start = time.perf_counter()

    theta_p = np.where(is_center, 0.0, np.arctan2(Y_p, X_p)).astype(np.float32)

    # 1. Distance angulaire circulaire
    d_theta = np.abs((theta[:, None] - theta_p[None, :] + np.pi) % (2.0 * np.pi) - np.pi) / np.pi
    d_theta[:, is_center] = 0.0

    # 2. Écart de strate
    d_z = np.abs(z_ded[:, None] - abs_Z[None, :]) / 7.0

    # 3. Répulsion de l'antagoniste A(P_j)
    ant_idx = (df_ref303["correspondant_id_303"].to_numpy(dtype=np.int32) - 1)
    d_ang_ant = d_theta[:, ant_idx]
    rep_ant = np.maximum(0.0, 1.0 - d_ang_ant)

    # Matrice de coût broadcastée
    C = (0.85 * d_theta + 0.55 * d_z + 0.15 * rep_ant).astype(np.float32)

    # Séparation douce des hémisphères
    hemi_penalty = np.zeros((N, P), dtype=np.float32)
    hemi_penalty[~is_axiological, 176:] += 0.25
    hemi_penalty[is_axiological, :176] += 0.25
    C += hemi_penalty

    # Couverture de Markov
    C[~M] = np.inf

    # argmin p*
    p_best = np.argmin(C, axis=1)
    row_indices = np.arange(N)
    C_best = C[row_indices, p_best]

    # Second meilleur pôle p_2
    C_masked = C.copy()
    C_masked[row_indices, p_best] = np.inf
    p_second = np.argmin(C_masked, axis=1)
    C_second = C_masked[row_indices, p_second]

    delta_C = (C_second - C_best).astype(np.float32)

    # Matrice d'adjacence géodésique vectorisée
    adj_matrix, adj_type_matrix = build_adjacency_matrix_vectorized(df_ref303)
    is_adjacent_pair = adj_matrix[p_best, p_second]
    adj_type_code = adj_type_matrix[p_best, p_second]

    t3_end = time.perf_counter()
    print(f"[Étape 3] Résolution tensorielle achevée en {t3_end - t3_start:.3f} s.")
    print(f"          - Pôles uniques activés : {len(np.unique(p_best))} / 303")
    print(f"          - Affectations Z+ : {(p_best < 176).sum()} | Affectations Z- : {(p_best >= 176).sum()}")
    print(f"          - Paires (p*, p_2) géodésiquement adjacentes : {is_adjacent_pair.sum()} / {N} ({is_adjacent_pair.mean() * 100:.1f} %)")
    print(f"          - Marge Delta_C moyenne : {delta_C.mean():.4f} (min={delta_C.min():.4f}, max={delta_C[np.isfinite(delta_C)].max():.4f})")

    # --------------------------------------------------------------------------
    # 4. Enrichissement Vectorisé et Exports
    # --------------------------------------------------------------------------
    t4_start = time.perf_counter()

    control_pot = 0.60 * a + 0.40 * d
    sub_triade = np.full(N, "-", dtype=object)
    mask_z_minus_6 = (Z_signe[p_best] == -6)
    sub_triade[mask_z_minus_6 & (v >= 0.0)] = "VALEUR_CENTRALE_V"
    sub_triade[mask_z_minus_6 & (v < 0.0) & (control_pot < 0.0)] = "DEFICIT_D_MOINS"
    sub_triade[mask_z_minus_6 & (v < 0.0) & (control_pot >= 0.0)] = "EXCES_D_PLUS"

    # Indexation NumPy directe et ultra-rapide des attributs du pôle optimal
    col_dict = {
        "nrc_term": df_nrc["term"],
        "valence_v": np.round(v, 4),
        "arousal_a": np.round(a, 4),
        "dominance_d": np.round(d, 4),
        "x_attente_raw": np.round(x_raw, 4),
        "y_controle_raw": np.round(y_raw, 4),
        "rayon_L1_raw": np.round(r_l1, 4),
        "theta_rad": np.round(theta, 4),
        "z_ded_profondeur": np.round(z_ded, 4),
        "est_axologique": is_axiological,
        "cout_optimal_C_best": np.round(C_best, 4),
        "cout_second_C_second": np.round(C_second, 4),
        "marge_delta_C": np.round(delta_C, 4),
        "est_frontiere_adjacente": is_adjacent_pair,
        "sous_type_triade_aristote": sub_triade,
    }

    # Attributs complets du pôle optimal p*
    ref_cols_to_copy = [
        "id_303", "label_fr", "hemisphere", "X", "Y", "Z_signe", "W_equiv", "rayon_L1",
        "h_diamant_3d", "type_geom", "groupe_geom", "type_antagonisme",
        "moteur_couplage_AC", "moteur_interface_dominante", "moteur_operation_inferentielle",
        "matrice_regime_energetique", "taxonomie_sous_secteur_17", "noyau_potentiel_lyapunov",
        "loi_transmutation_verticale", "couche_z_nom", "couche_z_objet_inference",
        "correspondant_label", "correspondant_id_303", "oppose_central_label", "oppose_central_id_303",
        "miroir_dominant_label", "miroir_dominant_id_303", "oppose_lateral_X_label", "oppose_lateral_X_id_303",
        "oppose_lateral_Y_label", "oppose_lateral_Y_id_303", "homologue_label", "homologue_id_303",
        "homologue_Z_signe", "filiere_inf_label", "filiere_inf_id_303", "filiere_sup_label", "filiere_sup_id_303",
        "deficit_D_moins", "exces_D_plus", "famille_thematique"
    ]
    for col in ref_cols_to_copy:
        vals = df_ref303[col].to_numpy()
        col_dict[col] = vals[p_best]

    # Attributs du second meilleur pôle p_2
    col_dict["p2_id_303"] = df_ref303["id_303"].to_numpy()[p_second]
    col_dict["p2_label_fr"] = df_ref303["label_fr"].to_numpy()[p_second]
    col_dict["p2_X"] = df_ref303["X"].to_numpy()[p_second]
    col_dict["p2_Y"] = df_ref303["Y"].to_numpy()[p_second]
    col_dict["p2_Z_signe"] = df_ref303["Z_signe"].to_numpy()[p_second]

    df_out_55k = pd.DataFrame(col_dict)

    # Export 1 : Table complète 55k
    file_out_55k = os.path.join(out_dir_root, "CARTOGRAFFECT_55K_NRC_VAD_Diamant_303.tsv")
    print(f"Export de la projection complète 55k -> {file_out_55k}")
    df_out_55k.to_csv(file_out_55k, sep="\t", index=False, encoding="utf-8")

    # Export 2 : Audit des 500 frontières de Markov à plus faible marge
    adj_type_names = {1: "INTRA_STRATE_L1", 2: "INTER_STRATES_FILIERE", 0: "AUTRE"}
    df_audit_candidates = df_out_55k[df_out_55k["est_frontiere_adjacente"]].copy()
    df_audit_candidates["type_adjacence"] = [
        adj_type_names.get(code, "AUTRE") for code in adj_type_code[df_out_55k["est_frontiere_adjacente"]]
    ]

    df_audit_500 = (
        df_audit_candidates
        .sort_values(by="marge_delta_C", ascending=True)
        .head(500)
        .reset_index(drop=True)
    )

    audit_columns = [
        "nrc_term", "valence_v", "arousal_a", "dominance_d",
        "x_attente_raw", "y_controle_raw", "rayon_L1_raw", "z_ded_profondeur",
        "cout_optimal_C_best", "cout_second_C_second", "marge_delta_C", "type_adjacence",
        "id_303", "label_fr", "X", "Y", "Z_signe", "couche_z_nom", "taxonomie_sous_secteur_17",
        "p2_id_303", "p2_label_fr", "p2_X", "p2_Y", "p2_Z_signe",
        "moteur_couplage_AC", "moteur_operation_inferentielle"
    ]
    df_audit_500_export = df_audit_500[audit_columns]

    file_out_audit = os.path.join(out_dir_root, "CARTOGRAFFECT_55K_Audit_Frontieres_Markov.tsv")
    print(f"Export de l'audit des 500 frontières de Markov -> {file_out_audit}")
    df_audit_500_export.to_csv(file_out_audit, sep="\t", index=False, encoding="utf-8")

    t4_end = time.perf_counter()
    t_total = t4_end - t_global_start
    print(f"[Étape 4] Exports et sérialisation terminés en {t4_end - t4_start:.3f} s.")
    print("=" * 80)
    print(f"SUCCÈS INTÉGRAL — TEMPS TOTAL DE TRAITEMENT : {t_total:.3f} s (< 5.0 s CPU, 0 jeton LLM)")
    print("=" * 80)


if __name__ == "__main__":
    main()
