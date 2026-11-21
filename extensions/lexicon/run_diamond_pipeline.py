"""
run_diamond_pipeline.py
================================================================================
Orchestrateur maître du Diamant du Cartograffect (303 Pôles, Z ∈ [-7, +7]).
Exécute et valide de bout en bout :
  1. Préparation géométrique du Diamant (01b_prepare_diamond_z_minus.py)
  2. Audit, déduplication et consolidation des bases NRC / DIMA / FANCat (02b_audit_and_consolidate_databases.py)
  3. Projection et validation logique des oppositions multi-axes (08_project_diamond_303_lexicon.py)
  4. Construction des visualiseurs 3D du Diamant (07_build_diamond_brut_viewer.py & 09_build_diamond_complete_viewer.py)
================================================================================
"""

import os
import sys
import time
import subprocess
import pandas as pd

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(SCRIPT_DIR)


def run_cmd(step_num, title, script_name):
    print("\n" + "=" * 80)
    print(f" ÉTAPE {step_num} : {title}")
    print(f" Script : {script_name}")
    print("=" * 80)
    t0 = time.time()
    res = subprocess.run([sys.executable, script_name])
    t1 = time.time()
    if res.returncode != 0:
        print(f"Erreur critique lors de l'exécution de {script_name} (code {res.returncode})", file=sys.stderr)
        sys.exit(res.returncode)
    print(f"-> Étape {step_num} validée en {t1 - t0:.2f} s.")


def verify_diamond_artifacts():
    print("\n" + "=" * 80)
    print(" CONTRÔLE FINAL DES INVARIANTS DU DIAMANT DU CARTOGRAFFECT")
    print("=" * 80)

    # 1. ref_303_diamant_z.tsv
    ref303 = pd.read_csv("ref_303_diamant_z.tsv", sep="\t")
    assert len(ref303) == 303, f"Attendu 303 pôles, trouvé {len(ref303)}"
    assert ref303["label_fr"].nunique() == 303, "Doublons de libellés dans ref303"
    assert (ref303["Z_signe"].min() == -7) and (ref303["Z_signe"].max() == 7), "Strates Z hors [-7, +7]"
    print("[OK] ref_303_diamant_z.tsv : 303 pôles uniques sur Z ∈ [-7, +7].")

    # 2. CARTOGRAFFECT_Base_Unique_NRC_DIMA_FANCat.tsv
    base_uni = pd.read_csv("CARTOGRAFFECT_Base_Unique_NRC_DIMA_FANCat.tsv", sep="\t")
    assert len(base_uni) == 2780, f"Attendu 2 780 entrées, trouvé {len(base_uni)}"
    assert base_uni["terme_fr"].nunique() == 2780, "Doublons dans la base unique !"
    assert not base_uni["terme_fr"].str.contains(r"[\s'’\-_]", regex=True).any(), "Expressions composées dans la base unique !"
    print("[OK] CARTOGRAFFECT_Base_Unique_NRC_DIMA_FANCat.tsv : 2 780 unigrammes uniques (0 doublon, 0 expression composée).")

    # 3. CARTOGRAFFECT_Diamant_303_Lexique_Complet.tsv
    lex_comp = pd.read_csv("CARTOGRAFFECT_Diamant_303_Lexique_Complet.tsv", sep="\t")
    assert len(lex_comp) == 2780, f"Attendu 2 780 entrées projetées, trouvé {len(lex_comp)}"
    assert lex_comp["id_303_ancre"].nunique() == 303, "Tous les 303 pôles ne sont pas couverts !"
    print("[OK] CARTOGRAFFECT_Diamant_303_Lexique_Complet.tsv : 100% couverture des 303 pôles (0 orphelin).")

    # 4. CARTOGRAFFECT_Diamant_303_Stats_Synthese.tsv
    stats = pd.read_csv("CARTOGRAFFECT_Diamant_303_Stats_Synthese.tsv", sep="\t")
    assert len(stats) == 303, f"Attendu 303 statistiques, trouvé {len(stats)}"
    assert (stats["effectif_termes"] > 0).all(), "Un ou plusieurs pôles ont un effectif nul !"
    print("[OK] CARTOGRAFFECT_Diamant_303_Stats_Synthese.tsv : 303 pôles analysés avec effectif > 0.")

    # 5. Visualiseurs 3D
    assert os.path.exists("CARTOGRAFFECT_Interactive_3D_Explorer.html"), "Visualiseur 176 Z+ manquant"
    assert os.path.exists("CARTOGRAFFECT_Diamond_303_Brut.html"), "Visualiseur brut manquant"
    assert os.path.exists("CARTOGRAFFECT_Diamond_303_Complet.html"), "Visualiseur complet manquant"
    print("[OK] Visualiseurs 3D interactifs générés et vérifiés : 176 Z+, Diamant Brut et Diamant Complet.")

    print("\n TOUS LES ARTÉFACTS ET INVARIANTS DU DIAMANT DU CARTOGRAFFECT SONT CONFORMES ET CERTIFIÉS !")


def main():
    t_start = time.time()
    print("=" * 80)
    print(" DÉPLOIEMENT COMPLET DU PIPELINE DU DIAMANT DU CARTOGRAFFECT (303 PÔLES)")
    print("=" * 80)

    run_cmd(1, "Géométrie et référentiel du Diamant Brut 303", "01b_prepare_diamond_z_minus.py")
    run_cmd(2, "Audit, déduplication, purification DIMA et consolidation des valeurs", "02b_audit_and_consolidate_databases.py")
    run_cmd(3, "Projection déterministe et validation par oppositions multi-axes", "08_project_diamond_303_lexicon.py")
    run_cmd(4, "Génération du visualiseur 3D de l'Hémisphère Z+ (176 pôles équilibrés)", "06_build_interactive_3d_viewer.py")
    run_cmd(5, "Génération du visualiseur 3D du Diamant Brut", "07_build_diamond_brut_viewer.py")
    run_cmd(6, "Génération du visualiseur 3D du Diamant Complet avec constellations", "09_build_diamond_complete_viewer.py")

    verify_diamond_artifacts()
    t_end = time.time()
    print(f"\nDurée totale du pipeline Diamant : {t_end - t_start:.2f} secondes.")


if __name__ == "__main__":
    main()

