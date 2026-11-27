"""
run_pipeline.py
Orchestrateur maître du pipeline Cartograffect / NRC-VAD (Pyramide des Couronnes L1, Z = 0..7).
Exécute et valide les étapes de bout en bout de manière déterministe et reproductible.
"""

import sys
import os
import time
import argparse
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(SCRIPT_DIR)

def run_step(step_num, script_name, description, args=None):
    print(f"\n{'='*70}")
    print(f" ÉTAPE {step_num} : {description}")
    print(f" Script : {script_name}")
    print(f"{'='*70}")
    
    if not os.path.exists(script_name):
        print(f"Erreur : script {script_name} introuvable.", file=sys.stderr)
        sys.exit(1)

    cmd = [sys.executable, script_name]
    if args:
        cmd.extend(args)

    t0 = time.time()
    result = subprocess.run(cmd)
    t1 = time.time()

    if result.returncode != 0:
        print(f"Échec critique à l'étape {step_num} ({script_name}, code {result.returncode}). Arrêt du pipeline.", file=sys.stderr)
        sys.exit(result.returncode)

    print(f"-> Étape {step_num} terminée avec succès en {t1 - t0:.2f} secondes.")

def verify_artifacts():
    print(f"\n{'='*70}")
    print(" VÉRIFICATION DES ARTÉFACTS ET INVARIANTS DE LA PYRAMIDE L1")
    print(f"{'='*70}")

    import pandas as pd

    # 1. Vérification ref_176_cartograffect.tsv
    ref_path = "ref_176_cartograffect.tsv"
    if not os.path.exists(ref_path):
        print(f"ERREUR : {ref_path} manquant.")
        return False
    df_ref = pd.read_csv(ref_path, sep="\t")
    assert len(df_ref) == 176, f"Attendu 176 prototypes, trouvé {len(df_ref)}"
    assert df_ref["label_fr"].nunique() == 176, "Doublons dans les libellés de prototypes"
    assert set(df_ref["Z"].unique()) == {0, 1, 2, 3, 4, 5, 6, 7}, "Strates Z non conformes à {0..7}"
    print(f"[OK] {ref_path} : 176 prototypes uniques sur la Pyramide L1 (Z = 0..7) conformes à Lean 4.")

    # 1bis. Symétrie géométrique de la Pyramide : 4 cônes cardinaux (36) + 4 diagonales (6) + 8 centres
    expected_groups = {
        "JOIE": 36, "TRISTESSE": 36, "COURAGE": 36, "PEUR": 36,
        "DESIR": 6, "DEGOUT": 6, "COLERE": 6, "CALME": 6,
        "OPERATEUR_CENTRAL": 8,
    }
    actual_groups = df_ref["groupe_geom"].value_counts().to_dict()
    assert actual_groups == expected_groups, (
        f"Symétrie des groupes géométriques rompue : {actual_groups} (attendu {expected_groups})"
    )
    print("[OK] Symétrie de la Pyramide : 4 cônes x 36 (144) + 4 diagonales x 6 (24) + 8 centres = 176.")

    # 1ter. Loi des couronnes L1 : R_L1 = 2*(Z-1) et effectifs par strate Z
    expected_z_counts = {0: 1, 1: 1, 2: 9, 3: 17, 4: 25, 5: 33, 6: 41, 7: 49}
    actual_z_counts = df_ref["Z"].value_counts().to_dict()
    assert actual_z_counts == expected_z_counts, (
        f"Loi des couronnes L1 rompue : {actual_z_counts} (attendu {expected_z_counts})"
    )
    print("[OK] Loi des couronnes L1 vérifiée : 1 + 1 + 9 + 17 + 25 + 33 + 41 + 49 = 176 positions.")

    # 2. Vérification nrc_candidates_filtered.tsv
    cand_path = "nrc_candidates_filtered.tsv"
    if not os.path.exists(cand_path):
        print(f"ERREUR : {cand_path} manquant.")
        return False
    df_cand = pd.read_csv(cand_path, sep="\t")
    print(f"[OK] {cand_path} : {len(df_cand)} candidats filtrés WordNet.")

    # 3. Vérification nrc_llm_classified.tsv
    llm_path = "nrc_llm_classified.tsv"
    if not os.path.exists(llm_path):
        print(f"ERREUR : {llm_path} manquant.")
        return False
    df_llm = pd.read_csv(llm_path, sep="\t", on_bad_lines="skip")
    clean_llm = df_llm[df_llm["statut"].astype(str).isin(["0", "1", "2"])]
    affects = df_llm[df_llm["statut"].astype(str).isin(["1", "2"])]
    valid_protos = set(df_ref["label_fr"])
    non_canon_llm = set(affects["proto_fr_suggere"]) - valid_protos
    assert len(non_canon_llm) == 0, f"Prototypes non-canoniques dans {llm_path} : {non_canon_llm}"
    print(f"[OK] {llm_path} : {len(clean_llm)} entrées classifiées ({len(affects)} affects, 100% prototypes canoniques).")

    # 4. Vérification CARTOGRAFFECT_NRC_Lexicon_Complet.tsv
    lex_path = "CARTOGRAFFECT_NRC_Lexicon_Complet.tsv"
    if not os.path.exists(lex_path):
        print(f"ERREUR : {lex_path} manquant.")
        return False
    df_lex = pd.read_csv(lex_path, sep="\t")
    assert not (df_lex["statut_llm"] == 0).any(), "Des termes non-affectifs (statut 0) sont encore présents dans le lexique !"
    termes_s = df_lex["terme_fr"].astype(str).str.strip()
    nb_multi = int(termes_s.str.contains(r"[\s'’\-]", regex=True).sum())
    assert nb_multi == 0, f"{nb_multi} termes comportant plus d'un mot détectés dans {lex_path} !"
    nb_dups = len(df_lex) - termes_s.str.lower().nunique()
    assert nb_dups == 0, f"{nb_dups} doublons détectés dans {lex_path} !"
    print(f"[OK] {lex_path} : {len(df_lex)} termes affectifs uniques d'un seul mot (0 doublon, 0 multi-mot, aucun statut 0).")

    # 5. Vérification CARTOGRAFFECT_176_Stats_Synthese.tsv
    stats_path = "CARTOGRAFFECT_176_Stats_Synthese.tsv"
    if not os.path.exists(stats_path):
        print(f"ERREUR : {stats_path} manquant.")
        return False
    df_stats = pd.read_csv(stats_path, sep="\t")
    assert len(df_stats) == 176, f"Attendu 176 lignes de synthèse, trouvé {len(df_stats)}"
    count_col = "nb_termes" if "nb_termes" in df_stats.columns else "effectif_mots"
    couverts = (df_stats[count_col] > 0).sum()
    print(f"[OK] {stats_path} : 176 prototypes synthétisés ({couverts}/176 couverts par le lexique).")

    # 6. Vérification CARTOGRAFFECT_NRC_Exclus_Sans_Antagoniste.tsv (+ exclus non affectifs)
    excl_path = "CARTOGRAFFECT_NRC_Exclus_Sans_Antagoniste.tsv"
    nonaff_path = "CARTOGRAFFECT_NRC_Exclus_Non_Affectifs.tsv"
    if os.path.exists(excl_path):
        df_excl = pd.read_csv(excl_path, sep="\t")
        n_nonaff = len(pd.read_csv(nonaff_path, sep="\t")) if os.path.exists(nonaff_path) else 0
        assert len(df_excl) == 0, f"Attendu 0 terme exclu par clôture antagoniste, trouvé {len(df_excl)}"
        print(f"[OK] {excl_path} : {len(df_excl)} termes isolés par clôture antagoniste.")
        if n_nonaff:
            print(f"[OK] {nonaff_path} : {n_nonaff} termes exclus par l'audit affectif strict.")
        val_path = "CARTOGRAFFECT_NRC_Valeurs.tsv"
        if os.path.exists(val_path):
            df_val = pd.read_csv(val_path, sep="\t")
            print(f"[OK] {val_path} : {len(df_val)} valeurs morales, civiques, relationnelles et esthétiques extraites.")
        loc_path = "CARTOGRAFFECT_DIMA_Locutions.tsv"
        if os.path.exists(loc_path):
            df_loc = pd.read_csv(loc_path, sep="\t")
            print(f"[OK] {loc_path} : {len(df_loc)} locutions affectives DIMA (Le Pesant, 2023) projetées sur la Pyramide L1.")
        periph_path = "CARTOGRAFFECT_DIMA_Exclus_Peripheriques.tsv"
        if os.path.exists(periph_path):
            df_periph = pd.read_csv(periph_path, sep="\t")
            print(f"[OK] {periph_path} : {len(df_periph)} lexèmes périphériques DIMA (ComportAffect, CaractAffect, ParoleAffect) isolés.")
        if "source_lexicale" in df_lex.columns:
            src_counts = df_lex["source_lexicale"].value_counts().to_dict()
            print(f"[OK] Répartition des sources lexicales (NRC-VAD / DIMA / FANCat) : {src_counts}")
        print(f"[OK] Lexique purifié : {len(df_lex)} unigrammes affectifs uniques retenus.")

    # 7. Vérification CARTOGRAFFECT_Centre_Proximite.tsv
    prox_path = "CARTOGRAFFECT_Centre_Proximite.tsv"
    if os.path.exists(prox_path):
        df_prox = pd.read_csv(prox_path, sep="\t")
        assert len(df_prox) == 80, f"Attendu 80 lignes (top 10 pour 8 opérateurs centraux), trouvé {len(df_prox)}"
        print(f"[OK] {prox_path} : 80 entrées de proximité centrale (top 10 pour chacun des 8 opérateurs centraux).")

    # =========================================================================
    # TESTS D'INTÉGRITÉ AXIOMATIQUE CARTOGRAFFECT (Lean 4 / Cabelguen, 2026)
    # =========================================================================
    print(f"\n{'-'*70}")
    print(" EXÉCUTION DES 4 TESTS D'INTÉGRITÉ AXIOMATIQUE")
    print(f"{'-'*70}")

    # TEST 1 : Assertion de non-inversion hédonique (Invariance du signe X)
    print("\n[TEST 1] Assertion de non-inversion hédonique (|Valence| >= 0.35)...")
    inversions_pos = df_lex[(df_lex["valence"] >= 0.35) & (df_lex["X_ancre"] < 0)]
    inversions_neg = df_lex[(df_lex["valence"] <= -0.35) & (df_lex["X_ancre"] > 0)]
    nb_inversions = len(inversions_pos) + len(inversions_neg)

    if nb_inversions > 0:
        print(f"ERREUR : {nb_inversions} inversions hédoniques détectées !")
        assert nb_inversions == 0, f"Échec Test 1 : {nb_inversions} termes violent l'invariance hédonique du signe X."
    else:
        print(f"  [SUCCÈS] 0 inversion hédonique sur {len(df_lex)} termes.")
        print("  - Aucun terme à valence >= 0.35 ancré sur X_ancre < 0.")
        print("  - Aucun terme à valence <= -0.35 ancré sur X_ancre > 0.")

    # TEST 2 : Assertion de non-contamination des pôles primaires (Z=2)
    print("\n[TEST 2] Assertion de non-contamination des pôles primaires (Z=2)...")
    expected_families = {
        3533: ("dégoût", "DEGOUT"),
        3240: ("désir", "DESIR"),
        9690: ("courageux", "COURAGE"),
        942: ("audace", "COURAGE"),
    }
    for nrc_id, (term_label, exp_fam) in expected_families.items():
        row_term = df_lex[df_lex["nrc_id"] == nrc_id]
        assert len(row_term) == 1, f"Terme clé '{term_label}' (id {nrc_id}) introuvable dans le lexique !"
        r = row_term.iloc[0]
        actual_fam = r["groupe_geom"]
        assert actual_fam == exp_fam, (
            f"Échec Test 2 pour '{r['terme_fr']}' : attendu famille {exp_fam}, trouvé {actual_fam}"
        )
        print(f"  [SUCCÈS] '{r['terme_fr']}' -> Famille {actual_fam} (Prototype: '{r['proto_fr_ancre']}', Z={r['Z_ancre']}, X={r['X_ancre']})")

    # TEST 3 : Diagnostic de couverture des 176 prototypes de la Pyramide
    print("\n[TEST 3] Diagnostic de couverture des 176 prototypes de la Pyramide L1...")
    z_col = "Z_ancre" if "Z_ancre" in df_stats.columns else "Z"

    orphans = df_stats[df_stats[count_col] == 0]
    nb_couverts = len(df_stats) - len(orphans)
    pct_couv = (nb_couverts / len(df_stats)) * 100
    print(f"  Couverture globale : {nb_couverts} / {len(df_stats)} prototypes ({pct_couv:.1f}%)")

    print("  Couverture par couronne Z :")
    for z_val, sub_z in df_stats.groupby(z_col):
        z_couv = (sub_z[count_col] > 0).sum()
        z_tot = len(sub_z)
        z_pct = (z_couv / z_tot) * 100
        print(f"    - Z={z_val} : {z_couv}/{z_tot} prototypes couverts ({z_pct:.1f}%)")

    assert len(orphans) == 0, f"Échec Test 3 : {len(orphans)} prototypes orphelins détectés !"
    print("  [SUCCÈS] Couverture absolue : 176 / 176 prototypes couverts (0 orphelin).")

    # TEST 4 : Assertion de pureté flottante (aucun artefact IEEE 754 > 4 décimales)
    print("\n[TEST 4] Assertion de pureté flottante (max 4 décimales)...")
    def detect_float_artifacts(df):
        artifacts = []
        for col in df.columns:
            vals = df[col].dropna().astype(str)
            for v in vals:
                if "." in v and "e" not in v.lower():
                    dec_part = v.split(".")[1]
                    if len(dec_part) > 4:
                        artifacts.append((col, v))
                        break
        return artifacts

    artifacts_cand = detect_float_artifacts(df_cand)
    artifacts_lex = detect_float_artifacts(df_lex)
    artifacts_stats = detect_float_artifacts(df_stats)
    total_artifacts = len(artifacts_cand) + len(artifacts_lex) + len(artifacts_stats)

    assert total_artifacts == 0, f"Échec Test 4 : Présence de {total_artifacts} colonnes avec artefacts IEEE 754."
    print(f"  [SUCCÈS] Pureté flottante certifiée pour tous les artéfacts du pipeline.")
    print("  - Toutes les colonnes numériques ont <= 4 décimales (aucun artefact IEEE 754).")

    print("\nTous les contrôles d'intégrité et tests axiomatiques de la Pyramide L1 sont passés avec succès !")
    return True

def main():
    parser = argparse.ArgumentParser(description="Orchestrateur global du pipeline Cartograffect (Pyramide L1)")
    parser.add_argument("--step", type=int, choices=[1, 2, 3, 4, 5, 6], help="Exécute uniquement l'étape spécifiée")
    parser.add_argument("--skip-llm", action="store_true", help="Saute l'étape 3 si la classification LLM existe déjà")
    parser.add_argument("--verify-only", action="store_true", help="Vérifie uniquement l'intégrité des fichiers sans recalcul")
    args = parser.parse_args()

    t_global_start = time.time()
    print("="*70)
    print(" PIPELINE CARTOGRAFFECT / NRC-VAD — PYRAMIDE L1 (Z = 0..7, Lean 4)")
    print("="*70)

    if args.verify_only:
        success = verify_artifacts()
        sys.exit(0 if success else 1)

    if args.step:
        if args.step == 1:
            run_step(1, "01_build_ref176.py", "Génération du référentiel des 176 prototypes depuis Lean 4")
        elif args.step == 2:
            run_step(2, "02_prefilter_nrc.py", "Préfiltrage lexical WordNet du lexique NRC-VAD v2.1")
        elif args.step == 3:
            run_step(3, "03_classify_batches_gemini.py", "Classification sémantique différentielle par lots via Gemini")
            run_step("3b", "03b_affect_audit_gemini.py", "Audit affectif strict et traduction française via Gemini")
        elif args.step == 4:
            run_step(4, "04_direct_l1_projection.py", "Projection géométrique déterministe L1 sur la Pyramide (Z = 0..7)")
        elif args.step in (5, 6):
            run_step(5, "06_build_interactive_3d_viewer.py", "Génération de l'explorateur interactif 3D de la Pyramide L1")
    else:
        run_step(1, "01_build_ref176.py", "Génération du référentiel des 176 prototypes depuis Lean 4")
        if os.path.exists("NRC-VAD-Lexicon-v2.1.txt"):
            run_step(2, "02_prefilter_nrc.py", "Préfiltrage lexical WordNet du lexique NRC-VAD v2.1")
        else:
            print(
                "\n[SKIP] Étape 2 sautée : NRC-VAD-Lexicon-v2.1.txt absent localement "
                "(fichier tiers non redistribuable — voir DATA_PROVENANCE.md)."
            )
        
        if not args.skip_llm:
            run_step(3, "03_classify_batches_gemini.py", "Classification sémantique différentielle par lots via Gemini")
            run_step("3b", "03b_affect_audit_gemini.py", "Audit affectif strict et traduction française via Gemini")
        else:
            print("\n[INFO] Étapes 3 et 3b (LLM) sautées (--skip-llm spécifié).")

        run_step(4, "04_direct_l1_projection.py", "Projection géométrique déterministe L1 sur la Pyramide (Z = 0..7)")
        run_step(5, "06_build_interactive_3d_viewer.py", "Génération de l'explorateur interactif 3D de la Pyramide L1")

    verify_artifacts()

    t_global_elapsed = time.time() - t_global_start
    print(f"\nTemps total d'exécution du pipeline : {t_global_elapsed:.2f} secondes.")

if __name__ == "__main__":
    main()
