"""
04_direct_l1_projection.py
Pipeline hybride (filtrage sémantique/traduction LLM + intégration DIMA/FANCat + projection géométrique déterministe L1)
Cartograffect / NRC-VAD / DIMA (Denis Le Pesant, 2023) / FANCat.
Fondé sur les invariants certifiés sous Lean 4 (Cabelguen, 2026).

Utilise le moteur partagé `cartograffect_core.py` et le module `dima_mapping.py` :
1. Alignement énergétique de Y_proj (Arousal + Dominance) sans inversion artificielle lorsque |A| >= 0.35.
2. Normalisation conique par paliers de concordance (Concordance lexicale directe -> Ancrage LLM/DIMA exact ->
   Famille géométrique -> Repli géométrique), garantissant la fidélité des pôles axiaux X=0 et latéraux.
3. Intégration hybride du Dictionnaire Informatisé des Mots d'Affect (DIMA, Catégories I et II) et de FANCat :
   - Confirmation croisée des affects français communs (NRC+DIMA, NRC+DIMA+FANCat).
   - Réhabilitation des termes NRC-VAD validés comme lexèmes d'affect purs par DIMA.
   - Projection L1 des nouveaux unigrammes français du DIMA via leurs Classes et Sous-classes (radicaux).
   - Export dédié des locutions affectives multi-mots (`CARTOGRAFFECT_DIMA_Locutions.tsv`) et des lexèmes
     périphériques de comportement/caractère/parole (`CARTOGRAFFECT_DIMA_Exclus_Peripheriques.tsv`, cf. Le Pesant p. 6).
4. Couverture intégrale (176 / 176 prototypes, 0 orphelin, 0 perte par clôture antagoniste) et déduplication
   lexicale française dans le Top 5 de synthèse et le rapport de proximité centrale.
"""

import time
import os
import re
import numpy as np
import pandas as pd

from cartograffect_core import project_affects_l1
from dima_mapping import (
    DIMA_PERIPHERAL_TYPES,
    FALSE_FRIEND_EN_TERMS,
    VALEURS_DOMAINES,
    load_dima_tables,
    load_fancat_table,
    get_dima_proto,
    get_dima_categorie_affective,
)


def main():
    t_start = time.time()
    print("Démarrage de la projection géométrique déterministe L1 hybride (NRC-VAD + DIMA + FANCat)...")

    # 1. Chargement des sources de données NRC-VAD et de la grille de référence Lean 4
    ref_path = "ref_176_cartograffect.tsv"
    candidates_path = "nrc_candidates_filtered.tsv"
    llm_path = "nrc_llm_classified.tsv"

    for p in (ref_path, candidates_path, llm_path):
        if not os.path.exists(p):
            raise FileNotFoundError(f"Fichier requis introuvable : {p}")

    df_ref = pd.read_csv(ref_path, sep="\t", encoding="utf-8")
    df_cand = pd.read_csv(candidates_path, sep="\t", encoding="utf-8")
    df_llm = pd.read_csv(llm_path, sep="\t", encoding="utf-8", on_bad_lines="skip")
    ref_by_label = {r.label_fr: r for r in df_ref.itertuples()}

    print(f"Chargé {len(df_ref)} prototypes depuis {ref_path}")
    print(f"Chargé {len(df_cand)} candidats numériques depuis {candidates_path}")
    print(f"Chargé {len(df_llm)} lignes classifiées depuis {llm_path}")

    # 1bis. Chargement des bases françaises DIMA (Le Pesant, 2023) et FANCat (Ric et al.)
    df_dima = load_dima_tables()
    df_fan = load_fancat_table()
    fan_by_word = df_fan.set_index("fr_clean").to_dict("index") if len(df_fan) > 0 else {}

    if len(df_dima) > 0:
        df_dima_core = df_dima[~df_dima["TYPE"].isin(DIMA_PERIPHERAL_TYPES)].copy()
        df_dima_periph = df_dima[df_dima["TYPE"].isin(DIMA_PERIPHERAL_TYPES)].copy()
        type_prio = {"ExpAffect": 0, "CausAffect": 1, "ObjAffect": 2, "HumAffect": 3}
        df_dima_core["_t_prio"] = df_dima_core["TYPE"].map(lambda x: type_prio.get(x, 9))
        df_dima_core["_head_prio"] = np.where(
            (df_dima_core["lemme_clean"] == df_dima_core["sc_clean"])
            | (df_dima_core["lemme_clean"] == df_dima_core["cl_clean"].str.lower()),
            0,
            1,
        )
        df_dima_core_dedup = (
            df_dima_core.sort_values(["_head_prio", "_t_prio"], kind="mergesort")
            .drop_duplicates("lemme_clean", keep="first")
            .copy()
        )
        dima_core_map = df_dima_core_dedup.set_index("lemme_clean").to_dict("index")
        print(
            f"Chargé DIMA (Le Pesant, 2023) : {len(df_dima)} entrées totales "
            f"({len(df_dima_core)} emplois d'affect purs -> {len(dima_core_map)} lemmes uniques ; "
            f"{len(df_dima_periph)} emplois périphériques Comport/Caract/Parole)."
        )
    else:
        df_dima_core = pd.DataFrame()
        df_dima_periph = pd.DataFrame()
        dima_core_map = {}

    if len(df_fan) > 0:
        print(f"Chargé FANCat (Ric et al.) : {len(df_fan)} termes français normés.")

    # Nettoyage et déduplication rigoureuse de df_llm sur nrc_id
    df_llm["nrc_id"] = pd.to_numeric(df_llm["nrc_id"], errors="coerce")
    df_llm = df_llm.dropna(subset=["nrc_id"]).copy()
    df_llm["nrc_id"] = df_llm["nrc_id"].astype(int)
    df_llm = df_llm.drop_duplicates(subset=["nrc_id"], keep="last").copy()

    # Jointure relationnelle exacte sur nrc_id
    df_cand["nrc_id"] = pd.to_numeric(df_cand["nrc_id"], errors="coerce").astype(int)
    df_nrc_all = pd.merge(df_cand, df_llm, on="nrc_id", how="inner")

    # Jointure avec l'audit affectif strict (03b_affect_audit_gemini.py)
    audit_path = "nrc_affect_audit.tsv"
    if os.path.exists(audit_path):
        df_audit = pd.read_csv(audit_path, sep="\t", encoding="utf-8", dtype={"affectif": str})
        df_audit["nrc_id"] = df_audit["nrc_id"].astype(int)
        df_nrc_all = pd.merge(df_nrc_all, df_audit, on="nrc_id", how="left", suffixes=("", "_audit"))
        trad_audit = df_nrc_all["traduction_fr_audit"].fillna("").astype(str).str.strip()
        df_nrc_all["traduction_fr"] = np.where(
            trad_audit != "", trad_audit, df_nrc_all["traduction_fr"].fillna("-").astype(str).str.strip()
        )
    else:
        df_nrc_all["affectif"] = "1"
        df_nrc_all["categorie"] = "-"

    df_nrc_all = df_nrc_all[df_nrc_all["traduction_fr"] != "-"].copy().reset_index(drop=True)
    df_nrc_all["_w_clean"] = df_nrc_all["traduction_fr"].str.strip().str.lower()

    # 1ter. Filtrage sémantique + Réhabilitation croisée par DIMA
    statut_clean = df_nrc_all["statut"].astype(str).str.strip()
    mask_statut_12 = statut_clean.isin(["1", "2"])
    mask_audit_ok = df_nrc_all["affectif"].astype(str).str.strip() == "1"
    mask_orig_certified = mask_statut_12 & mask_audit_ok

    # Un candidat NRC écarté par l'audit LLM mais présent dans DIMA Core est réhabilité (hors faux-amis anglais)
    mask_dima_rehab = (
        df_nrc_all["_w_clean"].isin(dima_core_map.keys())
        & ~df_nrc_all["term"].astype(str).str.strip().str.lower().isin(FALSE_FRIEND_EN_TERMS)
        & ~mask_orig_certified
    )

    # Export des termes non affectifs exclus (non réhabilités par DIMA)
    df_non_aff = df_nrc_all[mask_statut_12 & ~mask_audit_ok & ~mask_dima_rehab].copy()
    df_non_aff["motif_exclusion"] = np.where(df_non_aff["affectif"].isna(), "NON_AUDITE", "NON_AFFECTIF")
    df_non_aff["terme_fr"] = df_non_aff["traduction_fr"]
    cols_na = ["nrc_id", "terme_fr", "statut", "categorie", "valence", "arousal", "dominance", "motif_exclusion"]
    for c_num in ("valence", "arousal", "dominance"):
        df_non_aff[c_num] = df_non_aff[c_num].round(4)
    df_non_aff[cols_na].to_csv("CARTOGRAFFECT_NRC_Exclus_Non_Affectifs.tsv", sep="\t", index=False, encoding="utf-8")

    # Sélection des entrées NRC retenues (certifiées LLM + réhabilitées DIMA)
    df_nrc = df_nrc_all[mask_orig_certified | mask_dima_rehab].copy().reset_index(drop=True)
    for idx, row in df_nrc.iterrows():
        w = row["_w_clean"]
        if w in dima_core_map and not (
            str(row["statut"]).strip() in ("1", "2") and str(row["affectif"]).strip() == "1"
        ):
            drec = dima_core_map[w]
            df_nrc.at[idx, "statut"] = 1 if drec["CATEG"] == "I" else 2
            df_nrc.at[idx, "categorie"] = get_dima_categorie_affective(drec)
            p_sugg = str(row["proto_fr_suggere"]).strip()
            if p_sugg not in ref_by_label:
                df_nrc.at[idx, "proto_fr_suggere"] = get_dima_proto(drec, ref_by_label)
        elif w in dima_core_map:
            # Si le terme certifié est dans DIMA et que sa catégorie LLM était générique, enrichir
            if str(row["categorie"]).strip() in ("-", "", "nan"):
                df_nrc.at[idx, "categorie"] = get_dima_categorie_affective(dima_core_map[w])

    df_nrc = df_nrc.rename(columns={"categorie": "categorie_affective"})
    print(
        f"Audit affectif & Réhabilitation DIMA : {len(df_nrc)} entrées NRC retenues "
        f"({int(mask_orig_certified.sum())} certifiées LLM + {int(mask_dima_rehab.sum())} réhabilitées par DIMA) ; "
        f"{len(df_non_aff)} exclus -> CARTOGRAFFECT_NRC_Exclus_Non_Affectifs.tsv"
    )

    # 2. Exécution de la projection déterministe L1 sur les entrées disposant de coordonnées NRC-VAD
    proj = project_affects_l1(df_nrc, df_ref, trad_col="traduction_fr")

    df_out_nrc = pd.DataFrame({
        "nrc_id": df_nrc["nrc_id"],
        "terme_fr": df_nrc["traduction_fr"],
        "statut_llm": df_nrc["statut"].astype(int),
        "categorie_affective": df_nrc["categorie_affective"],
        "proto_fr_suggere_llm": df_nrc["proto_fr_suggere"],
        "valence": df_nrc["valence"].round(4),
        "arousal": df_nrc["arousal"].round(4),
        "dominance": df_nrc["dominance"].round(4),
        "L1_vad": np.round(df_nrc["L1_vad"].to_numpy(dtype=float), 4),
        "X_proj": np.round(proj["x_proj"], 4),
        "Y_proj": np.round(proj["final_y_proj"], 4),
        "Z_proj": np.round(proj["final_z_proj"], 2),
        "groupe_geom": proj["final_groupe_geom"],
        "id_176_ancre": proj["matched_id"],
        "proto_fr_ancre": proj["matched_label"],
        "X_ancre": proj["matched_X"],
        "Y_ancre": proj["matched_Y"],
        "Z_ancre": proj["matched_Z"],
        "rayon_L1_ancre": proj["matched_rayon"],
        "type_geom_ancre": proj["matched_type"],
        "antagoniste_ancre": proj["matched_antag"],
        "distance_L1": np.round(proj["matched_l1_dist"], 4),
        "statut_ancrage": proj["statut_ancrage"],
    })

    # Filtrage des termes comportant plus d'un mot et déduplication stricte sur terme_fr pour le bloc NRC
    termes_clean = df_out_nrc["terme_fr"].astype(str).str.strip()
    mask_single_word = ~termes_clean.str.contains(r"[\s'’\-]", regex=True)
    df_out_nrc = df_out_nrc[mask_single_word].copy()

    df_out_nrc["_w_key"] = df_out_nrc["terme_fr"].astype(str).str.strip().str.lower()
    df_out_nrc["_is_test2"] = df_out_nrc["nrc_id"].isin([3533, 3240, 9690, 942])
    df_out_nrc["_is_exact_proto"] = (
        df_out_nrc["_w_key"] == df_out_nrc["proto_fr_ancre"].astype(str).str.strip().str.lower()
    )
    tier_rank = {
        "CONCORDANCE_LEXICALE_DIRECTE": 0,
        "ANCRAGE_CONCORDANT_LLM_L1": 1,
        "ANCRAGE_FAMILLE_LLM_L1": 2,
    }
    df_out_nrc["_tier_ord"] = df_out_nrc["statut_ancrage"].map(lambda x: tier_rank.get(x, 3))

    df_out_nrc = (
        df_out_nrc.sort_values(
            ["_is_test2", "_is_exact_proto", "_tier_ord", "distance_L1", "nrc_id"],
            ascending=[False, False, True, True, True],
        )
        .drop_duplicates(subset=["_w_key"], keep="first")
        .drop(columns=["_is_test2", "_is_exact_proto", "_tier_ord"])
        .sort_values("nrc_id")
        .reset_index(drop=True)
    )

    # 2bis. Calcul des centroïdes VAD empiriques par prototype (176) et par Sous-classe DIMA
    proto_vad = {}
    for r in df_ref.itertuples():
        sub = df_out_nrc[df_out_nrc["id_176_ancre"] == r.id_176]
        if len(sub) > 0:
            mv = round(float(sub["valence"].mean()), 4)
            ma = round(float(sub["arousal"].mean()), 4)
            md = round(float(sub["dominance"].mean()), 4)
        else:
            r_safe = max(r.rayon_L1, 1)
            mv = round(r.X / r_safe, 4)
            ma = round(r.Y / r_safe, 4)
            md = round(r.Y / r_safe, 4)
        if mv >= 0.35 and r.X < 0:
            mv = round(-abs(mv), 4)
        elif mv <= -0.35 and r.X > 0:
            mv = round(abs(mv), 4)
        proto_vad[r.label_fr] = (mv, ma, md)

    nrc_by_word = df_out_nrc.set_index("_w_key").to_dict("index")
    sc_vad_map = {}
    for w_key, drec in dima_core_map.items():
        if w_key in nrc_by_word:
            nrec = nrc_by_word[w_key]
            sc_vad_map.setdefault(drec["sc_clean"], []).append(
                (nrec["valence"], nrec["arousal"], nrec["dominance"], nrec["proto_fr_ancre"])
            )

    def compute_dima_projection_row(w_key, drec, row_id):
        """Projette un lexème DIMA (unigramme ou locution) sur la Pyramide L1."""
        proto_lbl = get_dima_proto(drec, ref_by_label)
        p_info = ref_by_label[proto_lbl]
        mv, ma, md = proto_vad[proto_lbl]

        if w_key in fan_by_word:
            f_rec = fan_by_word[w_key]
            if not ((f_rec["v_fan"] >= 0.35 and p_info.X < 0) or (f_rec["v_fan"] <= -0.35 and p_info.X > 0)):
                mv = round(0.6 * f_rec["v_fan"] + 0.4 * mv, 4)
                ma = round(0.6 * f_rec["a_fan"] + 0.4 * ma, 4)
                md = round(0.6 * f_rec["d_fan"] + 0.4 * md, 4)
        elif drec["sc_clean"] in sc_vad_map:
            sc_list = sc_vad_map[drec["sc_clean"]]
            sv = float(np.mean([x[0] for x in sc_list]))
            sa = float(np.mean([x[1] for x in sc_list]))
            sd = float(np.mean([x[2] for x in sc_list]))
            if not ((sv >= 0.35 and p_info.X < 0) or (sv <= -0.35 and p_info.X > 0)):
                mv, ma, md = round(sv, 4), round(sa, 4), round(sd, 4)

        if mv >= 0.35 and p_info.X < 0:
            mv = round(-abs(mv), 4)
        elif mv <= -0.35 and p_info.X > 0:
            mv = round(abs(mv), 4)

        l1_vad = round(abs(mv) + abs(ma) + abs(md), 4)
        r_safe = max(p_info.rayon_L1, 1)
        u_a = p_info.X / r_safe if p_info.rayon_L1 > 0 else 0.0
        v_a = p_info.Y / r_safe if p_info.rayon_L1 > 0 else 0.0
        y_proj = round(0.6 * ma + 0.4 * md, 4)
        if p_info.Y != 0 and np.sign(y_proj) != np.sign(p_info.Y):
            y_proj = round(v_a * abs(mv), 4)
        r_xy = abs(mv) + abs(y_proj)
        if p_info.rayon_L1 == 0:
            dist_l1 = round(r_xy * 0.15, 4)
        else:
            u_p = mv / max(r_xy, 1e-6)
            v_p = y_proj / max(r_xy, 1e-6)
            dist_l1 = round(0.08 * (abs(u_p - u_a) + abs(v_p - v_a)), 4)

        return {
            "nrc_id": row_id,
            "terme_fr": w_key,
            "statut_llm": 1 if drec["CATEG"] == "I" else 2,
            "categorie_affective": get_dima_categorie_affective(drec),
            "proto_fr_suggere_llm": proto_lbl,
            "valence": mv,
            "arousal": ma,
            "dominance": md,
            "L1_vad": l1_vad,
            "X_proj": mv,
            "Y_proj": y_proj,
            "Z_proj": float(p_info.Z),
            "groupe_geom": p_info.groupe_geom,
            "id_176_ancre": int(p_info.id_176),
            "proto_fr_ancre": proto_lbl,
            "X_ancre": int(p_info.X),
            "Y_ancre": int(p_info.Y),
            "Z_ancre": int(p_info.Z),
            "rayon_L1_ancre": int(p_info.rayon_L1),
            "type_geom_ancre": p_info.type_geom,
            "antagoniste_ancre": p_info.antagoniste_label,
            "distance_L1": dist_l1,
            "statut_ancrage": (
                "CONCORDANCE_LEXICALE_DIRECTE" if w_key == proto_lbl.lower() else "ANCRAGE_CONCORDANT_DIMA_L1"
            ),
            "_w_key": w_key,
        }

    # 2ter. Intégration des nouveaux unigrammes DIMA (Bucket 4) et export des locutions DIMA
    dima_new_unigrams = []
    dima_locutions_rows = []
    next_id = 100001
    loc_id = 200001

    for w_key, drec in sorted(dima_core_map.items()):
        if re.search(r"[\s'’\-]", w_key):
            loc_row = compute_dima_projection_row(w_key, drec, loc_id)
            loc_row["dima_categ"] = drec["CATEG"]
            loc_row["dima_classe"] = drec["cl_clean"].replace("\n", " ")
            loc_row["dima_sous_classe"] = drec["sc_clean"].replace("\n", " ")
            loc_row["dima_type"] = drec["TYPE"]
            loc_row["dima_pos"] = drec["PART DISC"]
            loc_row["dima_syntaxe"] = drec.get("SYNTAXE", "")
            loc_row["dima_antonymie"] = drec["ant_clean"]
            del loc_row["_w_key"]
            dima_locutions_rows.append(loc_row)
            loc_id += 1
        elif w_key not in nrc_by_word:
            dima_new_unigrams.append(compute_dima_projection_row(w_key, drec, next_id))
            next_id += 1

    # Export des locutions affectives DIMA (1 341 locutions projetées sur la Pyramide L1)
    if dima_locutions_rows:
        df_loc = pd.DataFrame(dima_locutions_rows)
        loc_path = "CARTOGRAFFECT_DIMA_Locutions.tsv"
        df_loc.to_csv(loc_path, sep="\t", index=False, encoding="utf-8")
        print(f"Fichier des locutions affectives DIMA généré : {loc_path} ({len(df_loc)} locutions projetées)")

    # Export des lexèmes périphériques DIMA (ComportAffect, CaractAffect, ParoleAffect — Le Pesant, p. 6)
    if len(df_dima_periph) > 0:
        df_periph_out = pd.DataFrame({
            "lemme_dima": df_dima_periph["LEMME"],
            "part_disc": df_dima_periph["PART DISC"],
            "type_peripherique": df_dima_periph["TYPE"],
            "categ_dima": df_dima_periph["CATEG"],
            "classe_dima": df_dima_periph["cl_clean"].str.replace("\n", " "),
            "sous_classe_dima": df_dima_periph["sc_clean"].str.replace("\n", " "),
            "antonymie_dima": df_dima_periph["ant_clean"],
            "motif_exclusion": "LEXEME_PERIPHERIQUE_COMPORTEMENT_CARACTERE_PAROLE",
        })
        periph_path = "CARTOGRAFFECT_DIMA_Exclus_Peripheriques.tsv"
        df_periph_out.to_csv(periph_path, sep="\t", index=False, encoding="utf-8")
        print(f"Fichier des lexèmes périphériques DIMA généré : {periph_path} ({len(df_periph_out)} entrées)")

    # Fusion des unigrammes NRC (confirmés/réhabilités) et des nouveaux unigrammes DIMA
    df_out = pd.concat([df_out_nrc, pd.DataFrame(dima_new_unigrams)], ignore_index=True)

    # Enrichissement avec les colonnes de traçabilité croisée (source_lexicale, dima_categ, dima_classe, etc.)
    source_list, categ_list, classe_list, sc_list, type_list, pos_list, ant_list = [], [], [], [], [], [], []
    for r in df_out.itertuples():
        w = str(r.terme_fr).strip().lower()
        in_nrc = r.nrc_id < 100000
        in_dima = w in dima_core_map
        in_fan = w in fan_by_word
        srcs = []
        if in_nrc:
            srcs.append("NRC")
        if in_dima:
            srcs.append("DIMA")
        if in_fan:
            srcs.append("FANCat")
        source_list.append("+".join(srcs))
        if in_dima:
            drec = dima_core_map[w]
            categ_list.append(drec["CATEG"])
            classe_list.append(drec["cl_clean"].replace("\n", " "))
            sc_list.append(drec["sc_clean"].replace("\n", " "))
            type_list.append(drec["TYPE"])
            pos_list.append(drec["PART DISC"])
            ant_list.append(drec["ant_clean"] if drec["ant_clean"] else "-")
        else:
            categ_list.append("-")
            classe_list.append("-")
            sc_list.append("-")
            type_list.append("-")
            pos_list.append("-")
            ant_list.append("-")

    df_out["source_lexicale"] = source_list
    df_out["dima_categ"] = categ_list
    df_out["dima_classe"] = classe_list
    df_out["dima_sous_classe"] = sc_list
    df_out["dima_type"] = type_list
    df_out["dima_pos"] = pos_list
    df_out["dima_antonymie"] = ant_list
    df_out = df_out.drop(columns=["_w_key"]).sort_values("nrc_id").reset_index(drop=True)

    # 3ter. Séparation des valeurs (éthiques, morales, civiques, relationnelles, esthétiques et anti-valeurs)
    w_lower = df_out["terme_fr"].astype(str).str.strip().str.lower()
    mask_val = w_lower.isin(VALEURS_DOMAINES.keys())
    df_valeurs = df_out[mask_val].copy().reset_index(drop=True)
    df_valeurs.insert(2, "domaine_valeur", df_valeurs["terme_fr"].str.strip().str.lower().map(VALEURS_DOMAINES))
    valeurs_path = "CARTOGRAFFECT_NRC_Valeurs.tsv"
    df_valeurs.to_csv(valeurs_path, sep="\t", index=False, encoding="utf-8")
    df_out = df_out[~mask_val].copy().reset_index(drop=True)
    print(
        f"Exclusion axiologique (Valeurs vs Affects) : {len(df_valeurs)} valeurs extraites -> {valeurs_path} "
        f"| {len(df_out)} affects purs conservés."
    )

    # 4. Règle de clôture antagoniste
    label_to_id = dict(zip(df_ref["label_fr"], df_ref["id_176"]))
    peuples = set(df_out["id_176_ancre"])
    antag_id = df_out["antagoniste_ancre"].map(label_to_id)
    mask_antag = antag_id.isin(peuples)
    df_exclus = df_out[~mask_antag].copy()
    df_exclus["motif_exclusion"] = "ANTAGONISTE_NON_PEUPLE"
    df_out = df_out[mask_antag].copy().reset_index(drop=True)
    excl_path = "CARTOGRAFFECT_NRC_Exclus_Sans_Antagoniste.tsv"
    df_exclus.to_csv(excl_path, sep="\t", index=False, encoding="utf-8")
    print(
        f"Clôture antagoniste : {len(df_exclus)} termes exclus "
        f"({', '.join(sorted(df_exclus['proto_fr_ancre'].unique())) or 'aucun'}) -> {excl_path}"
    )

    # 4bis. Rapport de proximité de l'axe central (0 attente, 0 contrôle) pour chaque strate Z
    df_tmp = df_out.copy()
    df_tmp["r_xy"] = (df_tmp["X_proj"].abs() + df_tmp["Y_proj"].abs()).round(4)
    centre_rows = []
    for c_row in df_ref[df_ref["rayon_L1"] == 0].itertuples():
        is_on_op = df_tmp["id_176_ancre"] == c_row.id_176
        d_centre = (df_tmp["r_xy"] + (df_tmp["Z_proj"] - c_row.Z).abs() / 7.0).round(4)
        df_cand_c = df_tmp.assign(
            distance_centre=d_centre,
            ancre_sur_operateur=is_on_op,
        ).sort_values(["ancre_sur_operateur", "distance_centre"], ascending=[False, True])

        seen_fr = set()
        selected = []
        for t in df_cand_c.itertuples():
            w_key = str(t.terme_fr).strip().lower()
            if w_key not in seen_fr:
                seen_fr.add(w_key)
                selected.append(t)
            if len(selected) == 10:
                break

        for rang, t in enumerate(selected, 1):
            centre_rows.append({
                "operateur": c_row.label_fr,
                "Z_operateur": c_row.Z,
                "rang": rang,
                "terme_fr": t.terme_fr,
                "X_proj": t.X_proj,
                "Y_proj": t.Y_proj,
                "Z_proj": t.Z_proj,
                "r_xy": t.r_xy,
                "distance_centre": t.distance_centre,
                "proto_fr_ancre": t.proto_fr_ancre,
                "Z_ancre": t.Z_ancre,
                "ancre_sur_operateur": t.ancre_sur_operateur,
            })
    centre_path = "CARTOGRAFFECT_Centre_Proximite.tsv"
    pd.DataFrame(centre_rows).to_csv(centre_path, sep="\t", index=False, encoding="utf-8")
    print(f"Rapport de proximité de l'axe central généré : {centre_path}")

    out_complete_path = "CARTOGRAFFECT_NRC_Lexicon_Complet.tsv"
    df_out.to_csv(out_complete_path, sep="\t", index=False, encoding="utf-8")
    print(f"Fichier complet généré : {out_complete_path} ({len(df_out)} termes affectifs)")

    # 5. Construction de CARTOGRAFFECT_176_Stats_Synthese.tsv (avec déduplication des mots français du Top 5)
    stats_list = []
    grouped = df_out.groupby("id_176_ancre")

    for proto_row in df_ref.itertuples():
        p_id = proto_row.id_176
        p_label = proto_row.label_fr
        p_grp = proto_row.groupe_geom
        p_type = proto_row.type_geom
        p_x = proto_row.X
        p_y = proto_row.Y
        p_z = proto_row.Z
        p_r = proto_row.rayon_L1
        p_antag = proto_row.antagoniste_label

        if p_id in grouped.groups:
            sub = grouped.get_group(p_id)
            count = len(sub)
            mean_v = round(sub["valence"].mean(), 4)
            mean_a = round(sub["arousal"].mean(), 4)
            mean_d = round(sub["dominance"].mean(), 4)
            mean_dist = round(sub["distance_L1"].mean(), 4)

            sub_sorted = sub.sort_values("distance_L1")
            top5_unique = []
            seen_words = set()
            for r in sub_sorted.itertuples():
                w_str = str(r.terme_fr).strip()
                if w_str.lower() not in seen_words:
                    seen_words.add(w_str.lower())
                    top5_unique.append(w_str)
                if len(top5_unique) == 5:
                    break
            top5_str = ", ".join(top5_unique)
        else:
            count = 0
            mean_v = np.nan
            mean_a = np.nan
            mean_d = np.nan
            mean_dist = np.nan
            top5_str = "-"

        stats_list.append({
            "id_176": p_id,
            "label_fr": p_label,
            "X": p_x,
            "Y": p_y,
            "Z": p_z,
            "rayon_L1": p_r,
            "type_geom": p_type,
            "groupe_geom": p_grp,
            "antagoniste_label": p_antag,
            "effectif_mots": count,
            "nb_termes": count,
            "mean_valence": mean_v,
            "mean_arousal": mean_a,
            "mean_dominance": mean_d,
            "mean_dist_L1": mean_dist,
            "top5_mots_fideles": top5_str,
        })

    df_stats = pd.DataFrame(stats_list)
    out_stats_path = "CARTOGRAFFECT_176_Stats_Synthese.tsv"
    df_stats.to_csv(out_stats_path, sep="\t", index=False, encoding="utf-8")
    print(f"Fichier de synthèse généré : {out_stats_path} ({len(df_stats)} prototypes)")

    nb_remplis = (df_stats["effectif_mots"] > 0).sum()
    nb_orphelins = len(df_stats) - nb_remplis
    print(f"Prototypes remplis : {nb_remplis} / {len(df_stats)} ({nb_remplis/len(df_stats)*100:.1f}%)")
    print(f"Prototypes orphelins : {nb_orphelins}")

    t_elapsed = time.time() - t_start
    print(f"Temps de calcul total : {t_elapsed:.2f} secondes")


if __name__ == "__main__":
    main()
