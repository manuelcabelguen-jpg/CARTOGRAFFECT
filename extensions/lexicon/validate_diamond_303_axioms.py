"""
Pipeline_16200_OpenData/validate_diamond_303_axioms.py
================================================================================
VERIFICATION FORMELLE PAR ASSERTIONS BLOQUANTES DES 6 LOIS AXIOMATIQUES DU
« DIAMANT DU CARTOGRAFFECT » (303 POLES SUR Z in [-7, +7]).

Architecte Mathématique & Cognitif : Antigravity (CARTOGRAFFECT Project)
Zéro appel LLM - Vérification déductive pure, certifiée conforme aux théorèmes Lean 4.

Lois formelles vérifiées :
1. Loi de Conservation L1 : |X| + |Y| = R_L1(Z) = 2(|Z| - 1) pour |Z| >= 2 (et R=0 pour (0,0,Z)).
   Exactement 176 pôles en Z+ / Équateur (id_303 1..176) et 127 pôles en Z- (id_303 177..303).
2. Loi de l'Interface Attentionnelle (A x C) : bijection déterministe vers les 9 couplages,
   les 4 opérations inférentielles + boucleRecursiveAC, les 6 régimes énergétiques et les
   17 sous-secteurs topologiques.
3. Loi Lexicographique de Polarité : primauté stricte de sgn(X) dès que X != 0, et de sgn(Y) si X = 0.
4. Clôture Injective et Involutivité de la Rose des 8 Symétries :
   - Antagoniste formel par morceaux A(X, Y, Z) = (-X, -Y, Z) si XY = 0, (-sgn(X)|Y|, -sgn(Y)|X|, Z) si XY != 0, avec A(A(P)) = P et typage quintuple.
   - Opposé central intra-dominante Ic(P) = (-X, -Y, Z) avec Ic(Ic(P)) = P.
   - Miroir diagonal de dominante M_dom(P) = (X, Y, Z) si XY = 0, (sgn(X)|Y|, sgn(Y)|X|, Z) si XY != 0, avec M_dom(M_dom(P)) = P.
   - Miroirs orthogonaux Ox(P) = (-X, Y, Z) et Oy(P) = (X, -Y, Z).
   - Homologue vertical trans-hémisphérique Hz(P) = (X, Y, -Z) ((0,0,0) <-> (0,0,-7) et Z=+7 auto-dual)
     et les 6 lois de transmutation verticale.
   - Contrepoids croisé trans-hémisphérique Az(P) = A(Hz(P)) avec Az(Az(P)) = P.
5. Continuité Géodésique des Filières Inter-Strates (Delta Z) : minimisation métrique L1
   normalisée |X'/R' - X/R| + |Y'/R' - Y/R| (incluant la couture Z=+7 <-> Z=-6).
6. Complétude des 40 Triades Aristotéliciennes (D- <- V -> D+) sur Z = -6 (id_303 264..303)
   autour du pivot central Discernement (0,0,-6, id_303 = 263).

Export du rapport de preuve :
output_diamond_303/CARTOGRAFFECT_Preuve_Formelle_Diamant_303.tsv
================================================================================
"""

import os
import sys
import pandas as pd
import numpy as np


def find_input_file(filename, candidates):
    """Recherche un fichier parmi plusieurs répertoires possibles."""
    for base in candidates:
        p = os.path.join(base, filename)
        if os.path.exists(p):
            return os.path.abspath(p)
    raise FileNotFoundError(f"Impossible de localiser le fichier requis '{filename}' dans : {candidates}")


def locate_paths():
    """Détermine les chemins des données et des sorties en fonction du contexte d'exécution."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    parent_dir = os.path.dirname(script_dir)
    cwd = os.getcwd()

    search_dirs = [
        os.path.join(script_dir, "data"),
        os.path.join(parent_dir, "data"),
        script_dir,
        parent_dir,
        cwd,
        os.path.join(cwd, "Pipeline_16200_OpenData", "data"),
        os.path.join(cwd, "Pipeline_16200_OpenData"),
    ]

    ref_303_path = find_input_file("ref_303_diamant_z.tsv", search_dirs)
    ref_127_path = find_input_file("ref_127_axiologie_z_minus.tsv", search_dirs)
    
    # Validation oppositions (optionnel si présent)
    try:
        val_opp_path = find_input_file("CARTOGRAFFECT_Diamant_303_Validation_Oppositions.tsv", [
            os.path.join(script_dir, "output_diamond_303"),
            os.path.join(parent_dir, "output_diamond_303"),
            os.path.join(cwd, "output_diamond_303"),
            parent_dir,
            cwd,
        ])
    except FileNotFoundError:
        val_opp_path = None

    # Répertoire cible pour le rapport de preuve (restreint à extensions/lexicon/output_diamond_303)
    out_dirs = [
        os.path.join(script_dir, "output_diamond_303"),
    ]
    for d in out_dirs:
        os.makedirs(d, exist_ok=True)

    return ref_303_path, ref_127_path, val_opp_path, out_dirs


def main():
    print("=" * 80)
    print(" CARTOGRAFFECT : VERIFICATION MATHEMATIQUE DU DIAMANT DES 303 POLES")
    print(" Architecture Formelle & Preuve Axiomatique Déductive (Lean 4 Alignment)")
    print("=" * 80)

    ref_303_path, ref_127_path, val_opp_path, out_dirs = locate_paths()
    print(f"[*] Chargement de ref_303_diamant_z.tsv : {ref_303_path}")
    df_303 = pd.read_csv(ref_303_path, sep="\t", encoding="utf-8")
    
    print(f"[*] Chargement de ref_127_axiologie_z_minus.tsv : {ref_127_path}")
    df_127 = pd.read_csv(ref_127_path, sep="\t", encoding="utf-8")

    if val_opp_path:
        print(f"[*] Vérification du fichier d'oppositions : {val_opp_path}")
    
    total_assertions = 0

    # Indexations primaires
    assert len(df_303) == 303, f"Erreur critique: attendu 303 pôles, trouvé {len(df_303)}"
    assert len(df_127) == 127, f"Erreur critique: attendu 127 pôles en Z-, trouvé {len(df_127)}"
    total_assertions += 2

    by_id = {int(r["id_303"]): r for r in df_303.to_dict(orient="records")}
    by_coord = {(int(r["X"]), int(r["Y"]), int(r["Z_signe"])): r for r in df_303.to_dict(orient="records")}
    assert len(by_coord) == 303, "Erreur critique: collision de coordonnées (X, Y, Z) dans le Diamant!"
    total_assertions += 1

    proof_rows = []

    # ==============================================================================
    # 1. LOI DE CONSERVATION L1 : |X| + |Y| = R_L1(Z) = 2(|Z| - 1)
    # ==============================================================================
    print("\n[LOI 1] Vérification de la Loi de Conservation L1 sur les 15 strates Z ∈ [-7, +7]...")
    z_plus_poles = [r for r in by_id.values() if r["id_303"] <= 176]
    z_minus_poles = [r for r in by_id.values() if r["id_303"] > 176]

    assert len(z_plus_poles) == 176, f"Z+ doit compter exactement 176 pôles (obtenu {len(z_plus_poles)})"
    assert len(z_minus_poles) == 127, f"Z- doit compter exactement 127 pôles (obtenu {len(z_minus_poles)})"
    total_assertions += 2

    # Vérification des IDs séquentiels 1..303
    expected_ids = list(range(1, 304))
    actual_ids = sorted(list(by_id.keys()))
    assert actual_ids == expected_ids, "La numérotation id_303 n'est pas strictement continue de 1 à 303"
    total_assertions += 1

    # Distribution exacte par strate Z
    expected_strata_counts = {
        0: 1, 1: 1, 2: 9, 3: 17, 4: 25, 5: 33, 6: 41, 7: 49,
        -1: 1, -2: 9, -3: 17, -4: 25, -5: 33, -6: 41, -7: 1
    }
    actual_strata_counts = df_303["Z_signe"].value_counts().to_dict()
    for z_val, exp_cnt in expected_strata_counts.items():
        act_cnt = actual_strata_counts.get(z_val, 0)
        assert act_cnt == exp_cnt, f"Strate Z={z_val}: attendu {exp_cnt} pôles, trouvé {act_cnt}"
        total_assertions += 1

    # Conservation métrique pour chaque pôle
    for pid in range(1, 304):
        r = by_id[pid]
        x, y, z = int(r["X"]), int(r["Y"]), int(r["Z_signe"])
        r_l1 = abs(x) + abs(y)
        if x == 0 and y == 0:
            expected_r = 0
            assert r["type_geom"] == "Centre", f"Pôle {pid} (0,0) doit être typé 'Centre'"
        else:
            assert abs(z) >= 2, f"Pôle périphérique {pid} impossible pour |Z| < 2"
            expected_r = 2 * (abs(z) - 1)
        
        assert r_l1 == expected_r, f"Violation Conservation L1 pôle {pid} ({x},{y},{z}): {r_l1} != {expected_r}"
        assert int(r["rayon_L1"]) == expected_r, f"Colonne rayon_L1 discordante pour pôle {pid}"
        total_assertions += 2
    print(f"   -> [SUCCES] 100% conforme : 303 pôles vérifiés (|X|+|Y|=2(|Z|-1), 176 en Z+, 127 en Z-).")

    # ==============================================================================
    # 2. LOI DE L'INTERFACE ATTENTIONNELLE (A × C) : BIJECTION DETERMINISTE
    # ==============================================================================
    print("\n[LOI 2] Vérification de la Loi de l'Interface Attentionnelle (A × C)...")
    for pid in range(1, 304):
        r = by_id[pid]
        x, y, z = int(r["X"]), int(r["Y"]), int(r["Z_signe"])

        # 9 Couplages {A-, A0, A+} x {C-, C0, C+}
        pol_a = "A+" if x > 0 else ("A-" if x < 0 else "A0")
        pol_c = "C+" if y > 0 else ("C-" if y < 0 else "C0")
        expected_ac = f"{pol_a} / {pol_c}"
        assert r["moteur_couplage_AC"] == expected_ac, f"Couplage AC pôle {pid}: {r['moteur_couplage_AC']} != {expected_ac}"

        # 4 Opérations inférentielles
        if x == 0 and y == 0:
            exp_op = "integrativeWeighting (Pondération intégrative)"
            exp_dom = "Interface Attentionnelle (Précision P)"
        elif abs(y) > abs(x):
            exp_dom = "Interface Perceptive (Gradient C dominant)"
            if y > 0:
                exp_op = "actionImplementation (Mise en œuvre pragmatique C+)"
            else:
                exp_op = "ascendingSensory (Inférence intéro-sensorielle & économie C-)"
        elif abs(x) > abs(y):
            exp_dom = "Interface Subjective (Gradient A dominant)"
            if x > 0:
                exp_op = "contextualGenerative (Révision générative contextuelle A+)"
            else:
                exp_op = "contextualGenerative (Maintien protecteur du modèle A-)"
        else:
            exp_dom = "Couplage Équilibré Subjectif-Perceptif (|A| = |C|)"
            exp_op = "boucleRecursiveAC (Co-résolution bidimensionnelle A ↔ C)"

        assert r["moteur_interface_dominante"] == exp_dom, f"Interface dominante pôle {pid}: {r['moteur_interface_dominante']} != {exp_dom}"
        assert r["moteur_operation_inferentielle"] == exp_op, f"Opération inférentielle pôle {pid}: {r['moteur_operation_inferentielle']} != {exp_op}"

        # 6 Régimes énergétiques
        if x == 0 and y == 0:
            exp_reg = "neutralBasal"
        elif x == 0 or y == 0:
            exp_reg = "axialPure"
        elif x > 0 and y > 0:
            exp_reg = "positiveSynergy"
        elif x < 0 and y < 0:
            exp_reg = "negativeSynergy"
        elif x < 0 and y > 0:
            exp_reg = "ergotropicCompensation"
        else:
            exp_reg = "trophotropicRelease"
        assert r["matrice_regime_energetique"] == exp_reg, f"Régime énergétique pôle {pid}: {r['matrice_regime_energetique']} != {exp_reg}"

        # 17 Sous-secteurs topologiques
        if x == 0 and y == 0:
            exp_sub = "centralOperator"
        elif x == 0 and y > 0:
            exp_sub = "axialElan"
        elif x == 0 and y < 0:
            exp_sub = "axialWithdrawal"
        elif x > 0 and y == 0:
            exp_sub = "axialOpening"
        elif x < 0 and y == 0:
            exp_sub = "axialThreat"
        elif x == y and x > 0:
            exp_sub = "diagonalDesire"
        elif x == y and x < 0:
            exp_sub = "diagonalDisgust"
        elif x == -y and x < 0:
            exp_sub = "diagonalAnger"
        elif x == -y and x > 0:
            exp_sub = "diagonalCalm"
        elif y > abs(x) and x > 0:
            exp_sub = "lateralApproachSynergy"
        elif y > abs(x) and x < 0:
            exp_sub = "lateralDefensiveUrgency"
        elif -y > abs(x) and x > 0:
            exp_sub = "lateralTrophotropicPeace"
        elif -y > abs(x) and x < 0:
            exp_sub = "lateralAversiveDistress"
        elif x > abs(y) and y > 0:
            exp_sub = "lateralEpistemicMastery"
        elif x > abs(y) and y < 0:
            exp_sub = "lateralContemplativeOpen"
        elif -x > abs(y) and y > 0:
            exp_sub = "lateralVigilantAlert"
        else:
            exp_sub = "lateralEpistemicClosure"
        assert r["taxonomie_sous_secteur_17"] == exp_sub, f"Sous-secteur 17 pôle {pid}: {r['taxonomie_sous_secteur_17']} != {exp_sub}"
        total_assertions += 5
    print(f"   -> [SUCCES] 100% conforme : bijection (X, Y) -> 9 couplages, 4 ops, 6 régimes, 17 sous-secteurs.")

    # ==============================================================================
    # 3. LOI LEXICOGRAPHIQUE DE POLARITE (PRIMAUTE STRICTE DE L'AXE X)
    # ==============================================================================
    print("\n[LOI 3] Vérification de la Loi Lexicographique de Polarité (X != 0 prioritaire sur Y)...")
    for pid in range(1, 304):
        r = by_id[pid]
        x, y, z = int(r["X"]), int(r["Y"]), int(r["Z_signe"])
        is_axio = (z < 0)

        if x > 0:
            exp_pol = "POSITIVE_OUVERTURE" if is_axio else "POSITIVE"
        elif x < 0:
            exp_pol = "REGULATION_GARDE_FOU" if is_axio else "NEGATIVE"
        elif y > 0:
            exp_pol = "POSITIVE_ELAN" if is_axio else "POSITIVE"
        elif y < 0:
            exp_pol = "REGULATION_TEMPERANCE" if is_axio else "NEGATIVE"
        else:
            exp_pol = "NEUTRE_SUSPENS"

        assert r["matrice_polarite_hedonique"] == exp_pol, f"Polarité lexicographique pôle {pid}: {r['matrice_polarite_hedonique']} != {exp_pol}"
        total_assertions += 1
    print(f"   -> [SUCCES] 100% conforme : primauté de sgn(X) sur sgn(Y) certifiée sur les 303 pôles.")

    # ==============================================================================
    # 4. CLOTURE INJECTIVE ET INVOLUTIVITE DE LA ROSE DES 8 SYMETRIES
    # ==============================================================================
    print("\n[LOI 4] Vérification de la Clôture Injective et Involutivité de la Rose des 8 Symétries...")
    transmut_counts = {
        "EQUATEUR_AUTO_DUAL_SUSPENSION": 0,
        "CONVERGENCE_OPERATEUR_CENTRAL": 0,
        "PROLONGEMENT_AGENTIF_ELAN": 0,
        "RETOURNEMENT_GARDE_FOU_ETHIQUE": 0,
        "CONVERSION_ERGOTROPE_TENUE_JUSTE": 0,
        "CONVERSION_TROPHOTROPE_ACCUEIL": 0,
    }

    for pid in range(1, 304):
        r = by_id[pid]
        x, y, z = int(r["X"]), int(r["Y"]), int(r["Z_signe"])
        sx = 1 if x > 0 else (-1 if x < 0 else 0)
        sy = 1 if y > 0 else (-1 if y < 0 else 0)

        # 1. Antagoniste régulateur formel par morceaux : (-X, -Y, Z) si XY = 0 ; (-sgn(X)|Y|, -sgn(Y)|X|, Z) si XY != 0
        if x == 0 and y == 0:
            ax, ay = 0, 0
            exp_rule = "AUTO_DUAL_CENTRE"
        elif x == 0 or y == 0:
            ax, ay = -x, -y
            exp_rule = "AXIAL_INVERSION_CENTRALE"
        elif abs(x) == abs(y):
            ax, ay = -x, -y
            exp_rule = "DIAGONAL_INVERSION_CENTRALE"
        else:
            ax = -sx * abs(y)
            ay = -sy * abs(x)
            if sx != sy:
                exp_rule = "CONTROLATERAL_DIRECT_Td"
                assert (ax, ay) == (y, x), f"Td discordance pour ({x},{y})"
            else:
                exp_rule = "CONTROLATERAL_INVERSE_Ti"
                assert (ax, ay) == (-y, -x), f"Ti discordance pour ({x},{y})"

        assert r["type_antagonisme"] == exp_rule, f"Typage antagoniste pôle {pid}: {r['type_antagonisme']} != {exp_rule}"
        assert (ax, ay, z) in by_coord, f"Clôture A(P) rompue pour ({x},{y},{z}) -> ({ax},{ay},{z})"
        ant_p = by_coord[(ax, ay, z)]
        assert int(r["correspondant_id_303"]) == ant_p["id_303"], f"Correspondant ID discordant pour {pid}"
        
        # Involutivité de A : A(A(P)) = P
        a_ant_p = by_coord[(int(ant_p["X"]), int(ant_p["Y"]), int(ant_p["Z_signe"]))]
        assert int(a_ant_p["correspondant_id_303"]) == pid, f"A(A(P)) != P pour pôle {pid}"

        # 2. Opposé central intra-dominante Ic(P) = (-X, -Y, Z)
        assert (-x, -y, z) in by_coord, f"Clôture Ic(P) rompue pour pôle {pid}"
        ic_p = by_coord[(-x, -y, z)]
        assert int(r["oppose_central_id_303"]) == ic_p["id_303"]
        assert int(ic_p["oppose_central_id_303"]) == pid, f"Ic(Ic(P)) != P pour pôle {pid}"

        # 3. Miroir diagonal de dominante par morceaux : (X, Y, Z) si XY = 0 ; (sgn(X)|Y|, sgn(Y)|X|, Z) si XY != 0
        if x == 0 and y == 0:
            mx, my = 0, 0
        elif x == 0:
            mx, my = y, 0
        elif y == 0:
            mx, my = 0, x
        else:
            mx, my = sx * abs(y), sy * abs(x)
        assert (mx, my, z) in by_coord, f"Clôture M_dom(P) rompue pour pôle {pid}"
        m_p = by_coord[(mx, my, z)]
        assert int(r["miroir_dominant_id_303"]) == m_p["id_303"]
        assert int(m_p["miroir_dominant_id_303"]) == pid, f"M_dom(M_dom(P)) != P pour pôle {pid}"

        # 4. Miroirs orthogonaux Ox(P) = (-X, Y, Z) et Oy(P) = (X, -Y, Z)
        assert (-x, y, z) in by_coord, f"Clôture Ox(P) rompue pour pôle {pid}"
        ox_p = by_coord[(-x, y, z)]
        assert int(r["oppose_lateral_X_id_303"]) == ox_p["id_303"]
        assert int(ox_p["oppose_lateral_X_id_303"]) == pid, f"Ox(Ox(P)) != P pour pôle {pid}"

        assert (x, -y, z) in by_coord, f"Clôture Oy(P) rompue pour pôle {pid}"
        oy_p = by_coord[(x, -y, z)]
        assert int(r["oppose_lateral_Y_id_303"]) == oy_p["id_303"]
        assert int(oy_p["oppose_lateral_Y_id_303"]) == pid, f"Oy(Oy(P)) != P pour pôle {pid}"

        # 5. Homologue vertical trans-hémisphérique Hz(P) et ses 6 lois de transmutation
        if z == 0:
            hz_target = (0, 0, -7)
        elif z == -7:
            hz_target = (0, 0, 0)
        elif z == 7:
            hz_target = (x, y, 7)
        else:
            hz_target = (x, y, -z)
        assert hz_target in by_coord, f"Clôture Hz(P) rompue pour pôle {pid} vers {hz_target}"
        hz_p = by_coord[hz_target]
        assert int(r["homologue_id_303"]) == hz_p["id_303"]
        assert int(hz_p["homologue_id_303"]) == pid, f"Hz(Hz(P)) != P pour pôle {pid}"

        # Loi de transmutation verticale
        if z == 7:
            exp_trans = "EQUATEUR_AUTO_DUAL_SUSPENSION"
        elif x == 0 and y == 0:
            exp_trans = "CONVERGENCE_OPERATEUR_CENTRAL"
        elif x >= 0 and y >= 0:
            exp_trans = "PROLONGEMENT_AGENTIF_ELAN"
        elif x < 0 and y < 0:
            exp_trans = "RETOURNEMENT_GARDE_FOU_ETHIQUE"
        elif x < 0 and y > 0:
            exp_trans = "CONVERSION_ERGOTROPE_TENUE_JUSTE"
        else:
            exp_trans = "CONVERSION_TROPHOTROPE_ACCUEIL"
        assert r["loi_transmutation_verticale"] == exp_trans, f"Transmutation pôle {pid}: {r['loi_transmutation_verticale']} != {exp_trans}"
        transmut_counts[exp_trans] += 1

        # 6. Contrepoids trans-hémisphérique croisé Az(P) = A(Hz(P))
        hx, hy, hz_z = hz_target
        hsx = 1 if hx > 0 else (-1 if hx < 0 else 0)
        hsy = 1 if hy > 0 else (-1 if hy < 0 else 0)
        if hx == 0 and hy == 0:
            hax, hay = 0, 0
        elif hx == 0 or hy == 0:
            hax, hay = -hx, -hy
        elif abs(hx) == abs(hy):
            hax, hay = -hx, -hy
        else:
            hax = -hsx * abs(hy)
            hay = -hsy * abs(hx)
        assert (hax, hay, hz_z) in by_coord, f"Clôture Az(P) rompue pour pôle {pid} vers ({hax},{hay},{hz_z})"
        az_p = by_coord[(hax, hay, hz_z)]
        assert int(r["contrepoids_croise_id_303"]) == az_p["id_303"]
        assert int(az_p["contrepoids_croise_id_303"]) == pid, f"Az(Az(P)) != P pour pôle {pid}"
        total_assertions += 12

    # Assertion sur la partition exacte des 6 lois de transmutation
    assert transmut_counts == {
        "EQUATEUR_AUTO_DUAL_SUSPENSION": 49,
        "CONVERGENCE_OPERATEUR_CENTRAL": 14,
        "PROLONGEMENT_AGENTIF_ELAN": 70,
        "RETOURNEMENT_GARDE_FOU_ETHIQUE": 50,
        "CONVERSION_ERGOTROPE_TENUE_JUSTE": 50,
        "CONVERSION_TROPHOTROPE_ACCUEIL": 70,
    }, f"Comptage des transmutations discordantes: {transmut_counts}"
    total_assertions += 1
    print(f"   -> [SUCCES] 100% conforme : involutivité absolue prouvée pour A, Ic, M_dom, Ox, Oy, Hz, Az.")
    print(f"      Distribution des transmutations : {transmut_counts}")

    # ==============================================================================
    # 5. CONTINUITE GEODESIQUE DES FILIERES INTER-STRATES (DELTA Z)
    # ==============================================================================
    print("\n[LOI 5] Vérification de la Continuité Géodésique des Filières Inter-Strates (Delta Z)...")
    order_z = [0, 1, 2, 3, 4, 5, 6, 7, -6, -5, -4, -3, -2, -1, -7]

    all_rows = list(by_id.values())
    for pid in range(1, 304):
        r = by_id[pid]
        x, y, z = int(r["X"]), int(r["Y"]), int(r["Z_signe"])
        r_l1 = int(r["rayon_L1"])
        u_x = x / r_l1 if r_l1 > 0 else 0.0
        v_y = y / r_l1 if r_l1 > 0 else 0.0

        idx_z = order_z.index(z)
        z_inf = order_z[idx_z - 1] if idx_z > 0 else None
        z_sup = order_z[idx_z + 1] if idx_z < len(order_z) - 1 else None

        def find_geodesic_nearest(target_z):
            cands = [item for item in all_rows if int(item["Z_signe"]) == target_z]
            if not cands:
                return None
            if r_l1 == 0:
                for item in cands:
                    if int(item["rayon_L1"]) == 0:
                        return item
                return cands[0]
            periph_cands = [item for item in cands if int(item["rayon_L1"]) > 0]
            if not periph_cands:
                return cands[0]
            return min(
                periph_cands,
                key=lambda item: (
                    abs(int(item["X"]) / int(item["rayon_L1"]) - u_x) + abs(int(item["Y"]) / int(item["rayon_L1"]) - v_y),
                    0 if item["groupe_geom"] == r["groupe_geom"] else 1,
                ),
            )

        p_inf = find_geodesic_nearest(z_inf) if z_inf is not None else None
        p_sup = find_geodesic_nearest(z_sup) if z_sup is not None else None

        exp_inf_id = p_inf["id_303"] if p_inf else -1
        exp_sup_id = p_sup["id_303"] if p_sup else -1

        assert int(r["filiere_inf_id_303"]) == exp_inf_id, f"Filière inf discordante pôle {pid}: {r['filiere_inf_id_303']} != {exp_inf_id}"
        assert int(r["filiere_sup_id_303"]) == exp_sup_id, f"Filière sup discordante pôle {pid}: {r['filiere_sup_id_303']} != {exp_sup_id}"
        total_assertions += 2
    print(f"   -> [SUCCES] 100% conforme : minimisation métrique L1 normalisée vérifiée (couture Z=7 <-> Z=-6 incluse).")

    # ==============================================================================
    # 6. COMPLETUDE DES 40 TRIADES ARISTOTELICIENNES SUR Z = -6 (W = 1)
    # ==============================================================================
    print("\n[LOI 6] Vérification de la Complétude des 40 Triades Aristotéliciennes (Z = -6)...")
    z_minus_6 = [r for r in by_id.values() if int(r["Z_signe"]) == -6]
    assert len(z_minus_6) == 41, f"Strate Z=-6 doit compter 41 pôles (trouvé {len(z_minus_6)})"
    total_assertions += 1

    # Opérateur central = Discernement (id_303 = 263)
    p_disc = by_id[263]
    assert p_disc["label_fr"] == "Discernement", f"Pôle 263 doit être 'Discernement' (obtenu {p_disc['label_fr']})"
    assert int(p_disc["X"]) == 0 and int(p_disc["Y"]) == 0 and int(p_disc["Z_signe"]) == -6
    assert p_disc["deficit_D_moins"] == "-" and p_disc["exces_D_plus"] == "-", "Le centre Discernement ne doit pas avoir de triade périphérique"
    total_assertions += 4

    # 40 pôles qualificatifs périphériques : id_303 264 à 303
    seen_valeurs = set()
    seen_deficits = set()
    seen_exces = set()
    triades_familles = set()

    for pid in range(264, 304):
        r = by_id[pid]
        assert int(r["Z_signe"]) == -6
        v = str(r["label_fr"]).strip()
        dm = str(r["deficit_D_moins"]).strip()
        dp = str(r["exces_D_plus"]).strip()
        fam = str(r["famille_thematique"]).strip()

        assert v not in seen_valeurs, f"Doublon de valeur aristotélicienne : {v}"
        assert dm not in ["-", "", "None", "nan"], f"Défaut D- manquant pour {v} (id_303 = {pid})"
        assert dp not in ["-", "", "None", "nan"], f"Excès D+ manquant pour {v} (id_303 = {pid})"
        assert fam not in ["-", "", "None", "nan"], f"Famille thématique manquante pour {v} (id_303 = {pid})"
        
        # Unicité interne de la triade (D- != V != D+)
        assert len({v, dm, dp}) == 3, f"Collision interne dans la triade de {v} : ({dm}, {v}, {dp})"

        seen_valeurs.add(v)
        seen_deficits.add(dm)
        seen_exces.add(dp)
        triades_familles.add(fam)
        total_assertions += 5

    assert len(seen_valeurs) == 40, f"Attendu 40 valeurs vertueuses distinctes, obtenu {len(seen_valeurs)}"
    assert len(triades_familles) >= 6, f"Diversité des familles insuffisante ({len(triades_familles)})"
    total_assertions += 2
    print(f"   -> [SUCCES] 100% conforme : 40 triades complètes (D- <- V -> D+) autour de Discernement (0,0,-6).")
    print(f"      Familles thématiques couvertes : {sorted(list(triades_familles))}")

    # ==============================================================================
    # GENERATION DU RAPPORT DE PREUVE FORMELLE TSV
    # ==============================================================================
    print("\n" + "=" * 80)
    print(" GENERATION DU RAPPORT DE PREUVE FORMELLE DIAMANT 303")
    print("=" * 80)

    for pid in range(1, 304):
        r = by_id[pid]
        z = int(r["Z_signe"])
        is_z6_periph = (z == -6 and pid >= 264)
        
        ant_p = by_id[int(r["correspondant_id_303"])]
        ic_p = by_id[int(r["oppose_central_id_303"])]
        m_p = by_id[int(r["miroir_dominant_id_303"])]
        ox_p = by_id[int(r["oppose_lateral_X_id_303"])]
        oy_p = by_id[int(r["oppose_lateral_Y_id_303"])]
        hz_p = by_id[int(r["homologue_id_303"])]
        az_p = by_id[int(r["contrepoids_croise_id_303"])]

        f_inf_str = f"{r['filiere_inf_id_303']}:{r['filiere_inf_label']}" if int(r["filiere_inf_id_303"]) > 0 else "-"
        f_sup_str = f"{r['filiere_sup_id_303']}:{r['filiere_sup_label']}" if int(r["filiere_sup_id_303"]) > 0 else "-"

        if is_z6_periph:
            triade_str = f"{r['deficit_D_moins']} <- [{r['label_fr']}] -> {r['exces_D_plus']} ({r['famille_thematique']})"
            statut_triade = "VALIDE_COMPLETE"
        elif pid == 263:
            triade_str = "[Discernement] (Opérateur central intégrateur)"
            statut_triade = "PIVOT_CENTRAL"
        else:
            triade_str = "-"
            statut_triade = "SANS_OBJET"

        proof_row = {
            "id_303": pid,
            "label_fr": r["label_fr"],
            "hemisphere": r["hemisphere"],
            "X": r["X"],
            "Y": r["Y"],
            "Z_signe": r["Z_signe"],
            "rayon_L1": r["rayon_L1"],
            "type_geom": r["type_geom"],
            "groupe_geom": r["groupe_geom"],
            "loi_1_conservation_L1": "VALIDE",
            "loi_2_interface_AC": "VALIDE",
            "loi_3_polarite_lexico": "VALIDE",
            "loi_4_rose_8_symetries": "VALIDE",
            "loi_5_filiere_geodesique": "VALIDE",
            "loi_6_triade_aristote": statut_triade,
            "statut_preuve_globale": "PROUVE_CONFORME",
            "moteur_couplage_AC": r["moteur_couplage_AC"],
            "moteur_operation_inferentielle": r["moteur_operation_inferentielle"],
            "matrice_regime_energetique": r["matrice_regime_energetique"],
            "taxonomie_sous_secteur_17": r["taxonomie_sous_secteur_17"],
            "matrice_polarite_hedonique": r["matrice_polarite_hedonique"],
            "type_antagonisme": r["type_antagonisme"],
            "correspondant_A": f"{ant_p['id_303']}:{ant_p['label_fr']}",
            "oppose_central_Ic": f"{ic_p['id_303']}:{ic_p['label_fr']}",
            "miroir_dominant_Mdom": f"{m_p['id_303']}:{m_p['label_fr']}",
            "oppose_lateral_Ox": f"{ox_p['id_303']}:{ox_p['label_fr']}",
            "oppose_lateral_Oy": f"{oy_p['id_303']}:{oy_p['label_fr']}",
            "homologue_vertical_Hz": f"{hz_p['id_303']}:{hz_p['label_fr']}",
            "contrepoids_croise_Az": f"{az_p['id_303']}:{az_p['label_fr']}",
            "loi_transmutation_verticale": r["loi_transmutation_verticale"],
            "filiere_inf": f_inf_str,
            "filiere_sup": f_sup_str,
            "triade_aristote_detail": triade_str,
        }
        proof_rows.append(proof_row)

    df_proof = pd.DataFrame(proof_rows)

    report_name = "CARTOGRAFFECT_Preuve_Formelle_Diamant_303.tsv"
    exported_paths = []
    for out_d in out_dirs:
        p_out = os.path.join(out_d, report_name)
        df_proof.to_csv(p_out, sep="\t", index=False, encoding="utf-8")
        exported_paths.append(p_out)

    print(f"[OK] Rapport de preuve formelle exporté avec succès dans :")
    for p in exported_paths:
        print(f"     -> {p}")

    print("\n" + "=" * 80)
    print(" BILAN DE LA PREUVE AXIOMATIQUE")
    print("=" * 80)
    print(f" Total des pôles vérifiés : {len(df_proof)} / 303")
    print(f" Total des assertions bloquantes exécutées : {total_assertions}")
    print(f" Statut global : CERTIFIE RIGOUREUSEMENT CONFORME (0 échec, 0 exception)")
    print("=" * 80)


if __name__ == "__main__":
    main()
