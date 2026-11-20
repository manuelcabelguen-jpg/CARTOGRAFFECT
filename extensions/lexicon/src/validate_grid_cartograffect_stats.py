#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
================================================================================
Projet CARTOGRAFFECT — Script de validation statistique (CCA & Procrustes)
Fichier : src/validate_grid_cartograffect_stats.py
================================================================================
Validation statistique formelle de l'homomorphisme entre la topologie
octaédrique 3D de CARTOGRAFFECT (176 prototypes et 15 037 lemmes français) et
l'espace factoriel 4D / componantiel 142D du paradigme GRID (Klaus Scherer ;
Fontaine et al., 2007, 2013) :
  1. Analyse des Corrélations Canoniques (CCA, Hotelling) + Lambda de Wilks,
     Chi² de Bartlett, Redondance de Stewart-Love et tests par permutations.
  2. Analyse Procustéenne Orthogonale (Schönemann / Gower / PROTEST) et
     Indice de Congruence Factorielle de Tucker (phi) par axe (X, Y, Z).

Copyright (C) 2026  Projet CARTOGRAFFECT (Manuel Cabelguen)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

SPDX-License-Identifier: AGPL-3.0-or-later
================================================================================
"""

from __future__ import annotations

import os
import sys
import pandas as pd

# Permet l'import direct depuis la racine du projet ou depuis src/
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from src.grid_cpm_integration import (
    CPM_COMPONENT_SIZES,
    GRID_24_CANONICAL_PROTOTYPES,
    map_octahedral_l1_to_lp_sphere,
    map_grid_to_cartograffect_3d,
    run_statistical_validation_suite,
    run_l1_vs_l2_benchmark_suite,
    print_validation_summary,
)


def print_l1_vs_l2_benchmark_summary(benchmark: dict) -> None:
    """Affiche le tableau comparatif entre la géométrie Diamant (L1, p=1) et la Sphère (L2, p=2)."""
    print("\n" + "=" * 88)
    print("BENCHMARK COMPARATIF : GÉOMÉTRIE DIAMANT (L1, p=1.0) vs SPHÈRE RIEMANNIENNE (L2, p=2.0)")
    print("Homéomorphisme radial bijectif : u_Lp = u * (||u||_1 / ||u||_p), Z_eq = 7.0")
    print("=" * 88)
    for scale_key, title in [
        ("scale_24_canonical_grid_prototypes", "1. ÉCHELLE N = 24 PROTOTYPES CANONIQUES SCHERER GRID"),
        ("scale_176_cartograffect_prototypes", "2. ÉCHELLE N = 176 PROTOTYPES 3D CARTOGRAFFECT"),
        ("scale_15037_french_lexicon", "3. ÉCHELLE N = 15 037 LEMMES DU LEXIQUE FRANÇAIS (NRC-VAD + DIMA)"),
    ]:
        s = benchmark[scale_key]
        l1_cca = s["L1_diamond_p1"]["cca"]
        l1_pr = s["L1_diamond_p1"]["procrustes"]
        l2_cca = s["L2_sphere_p2"]["cca"]
        l2_pr = s["L2_sphere_p2"]["procrustes"]
        d = s["delta_L2_minus_L1"]
        phi1 = l1_pr["tucker_congruence_axes_XYZ"]
        phi2 = l2_pr["tucker_congruence_axes_XYZ"]

        print(f"\n{title}")
        print("-" * 88)
        print(
            f"  [L1 Diamant p=1.0] CCA (rho1..3) = {l1_cca['canonical_correlations']} | "
            f"R_Proc = {l1_pr['procrustes_correlation_R']:.4f} | "
            f"Tucker phi(X,Y,Z) = {phi1} (RMS={l1_pr['tucker_congruence_rms']:.4f})"
        )
        print(
            f"  [L2 Sphère  p=2.0] CCA (rho1..3) = {l2_cca['canonical_correlations']} | "
            f"R_Proc = {l2_pr['procrustes_correlation_R']:.4f} | "
            f"Tucker phi(X,Y,Z) = {phi2} (RMS={l2_pr['tucker_congruence_rms']:.4f})"
        )
        print(
            f"  [Gain L2 - L1]     Delta_rho1 = {d['delta_cca_rho1']:+.4f} | "
            f"Delta_R_Proc = {d['delta_procrustes_R']:+.4f} | "
            f"Delta_phi_Z = {d['delta_tucker_phi_Z']:+.4f} | "
            f"Delta_phi_RMS = {d['delta_tucker_phi_RMS']:+.4f}"
        )
    print("=" * 88)


def main() -> None:
    workspace_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    # 1. Vérification des invariants de structure CPM (24 prototypes, 5 composantes, 142 items)
    assert len(GRID_24_CANONICAL_PROTOTYPES) == 24, "24 prototypes GRID requis."
    assert CPM_COMPONENT_SIZES == {
        "Appraisal": 33,
        "Bodily_Symptoms": 27,
        "Motor_Expression": 33,
        "Action_Tendencies": 28,
        "Subjective_Feeling": 21,
    }

    # Test de cohérence de l'homéomorphisme radial Lp aux bornes p=1.0 et p=2.0
    x1, y1, z1 = map_octahedral_l1_to_lp_sphere(4.0, -2.0, 4.0, Z_eq=7.0, p=1.0)
    assert (x1, y1, z1) == (4.0, -2.0, 4.0), "L'identité doit être exacte en p=1.0."
    x2, y2, z2 = map_octahedral_l1_to_lp_sphere(4.0, -2.0, 4.0, Z_eq=7.0, p=2.0)
    assert abs(((x2 ** 2 + y2 ** 2 + (z2 - 7.0) ** 2) ** 0.5) - 9.0) < 1e-9, "Conservation du budget radial B(Z)=9."

    # 2. Alignement 3D et interpolation RBF / k-NN (24 -> 176 -> 15 037) + export dual L1/L2
    results = map_grid_to_cartograffect_3d(workspace_dir=workspace_dir, export_tsv=True)

    df_24 = results["df_grid_24"]
    df_176 = results["df_prototypes_176"]
    df_dual_176 = results["df_dual_176"]
    df_15037 = results["df_lexicon_15037"]

    assert len(df_24) == 24, f"Attendu 24 prototypes GRID, obtenu {len(df_24)}"
    assert len(df_176) == 176, f"Attendu 176 prototypes Cartograffect, obtenu {len(df_176)}"
    assert len(df_dual_176) == 176, f"Attendu 176 prototypes duaux L1/L2, obtenu {len(df_dual_176)}"
    assert len(df_15037) == 15037, f"Attendu 15 037 lemmes, obtenu {len(df_15037)}"

    # 3. Calcul de la validation statistique L1 (CCA + Procrustes)
    report = run_statistical_validation_suite(
        alignment_results=results,
        workspace_dir=workspace_dir,
        n_permutations=2000,
    )
    print_validation_summary(report)

    # 4. Benchmark comparatif Diamant (L1, p=1.0) vs Sphère (L2, p=2.0)
    benchmark = run_l1_vs_l2_benchmark_suite(
        alignment_results=results,
        workspace_dir=workspace_dir,
        n_permutations=2000,
        l1_report=report,
    )
    print_l1_vs_l2_benchmark_summary(benchmark)

    # 5. Export d'une table TSV synthétique des métriques de validation (L1 & L2)
    summary_rows = []
    for scale_key, label in [
        ("scale_24_canonical_grid_prototypes", "24_Prototypes_GRID"),
        ("scale_176_cartograffect_prototypes", "176_Prototypes_Cartograffect"),
        ("scale_15037_french_lexicon", "15037_Lemmes_Lexique_FR"),
    ]:
        for geom_key, geom_lbl in [("L1_diamond_p1", "Diamant_L1_p1.0"), ("L2_sphere_p2", "Sphere_L2_p2.0")]:
            cca = benchmark[scale_key][geom_key]["cca"]
            proc = benchmark[scale_key][geom_key]["procrustes"]
            rhos = cca["canonical_correlations"]
            phis = proc["tucker_congruence_axes_XYZ"]
            summary_rows.append({
                "echelle": label,
                "geometrie": geom_lbl,
                "N": cca["n_observations"],
                "CCA_rho1": rhos[0],
                "CCA_rho2": rhos[1],
                "CCA_rho3": rhos[2],
                "Wilks_Lambda": cca["wilks_lambda"],
                "Bartlett_Chi2": cca["bartlett_chi2"],
                "Bartlett_df": cca["bartlett_df"],
                "CCA_p_perm": cca["p_value_permutation_wilks"],
                "Redondance_Stewart_Love": cca["redundancy_carto_given_grid"],
                "Procrustes_R": proc["procrustes_correlation_R"],
                "Procrustes_R2": proc["procrustes_r_squared"],
                "Procrustes_m12_sq": proc["procrustes_residual_m12_sq"],
                "Tucker_Phi_X": phis[0],
                "Tucker_Phi_Y": phis[1],
                "Tucker_Phi_Z": phis[2],
                "Tucker_Phi_Mean": proc["tucker_congruence_mean"],
                "Tucker_Phi_RMS": proc["tucker_congruence_rms"],
                "PROTEST_p_value": proc["protest_p_value"],
            })

    df_summary = pd.DataFrame(summary_rows)
    out_tsv = os.path.join(workspace_dir, "CARTOGRAFFECT_GRID_CPM_Validation_Synthese.tsv")
    df_summary.to_csv(out_tsv, sep="\t", index=False, encoding="utf-8")
    print(f"\nSynthèse TSV exportée : {out_tsv}")
    print(f"Table duale L1/L2 exportée : {os.path.join(workspace_dir, 'CARTOGRAFFECT_176_Dual_L1_L2_CPM.tsv')}")
    print(f"Benchmark JSON L1 vs L2 exporté : {os.path.join(workspace_dir, 'CARTOGRAFFECT_L1_vs_L2_Benchmark_Stats.json')}")


if __name__ == "__main__":
    main()

