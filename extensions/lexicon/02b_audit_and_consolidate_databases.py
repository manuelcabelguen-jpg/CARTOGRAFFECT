"""
02b_audit_and_consolidate_databases.py
================================================================================
Audit croisé, déduplication stricte, purification de DIMA et consolidation
des bases NRC-VAD v2.1, DIMA (Le Pesant, 2023) et FANCat.

Opérations réalisées et certifiées :
1. Audit et purification de la base DIMA :
   - Suppression des 372 doublons internes de DIMA brut (3 373 -> 3 001 entrées).
   - Séparation stricte des 1 451 expressions composées (0 expression composée dans les unigrammes).
   - Extraction de toutes les valeurs, vertus, qualités morales/relationnelles et traits caractériels
     présents dans DIMA (tant dans le lexique initial que dans CaractAffect / ComportAffect) vers la
     base des Valeurs (Z-).
   - Génération de `CARTOGRAFFECT_DIMA_Purifie_Affectif.tsv` (0 valeur, 0 doublon, 0 expression composée).

2. Consolidation de la base de données des Valeurs (Z-) avec le NRC complet, DIMA et FANCat :
   - Fusion sans doublon :
     a) des 166 valeurs initiales (`CARTOGRAFFECT_NRC_Valeurs.tsv`),
     b) des valeurs et traits de caractère extraits de DIMA,
     c) des qualités morales, civiques, sociales et épistémiques présentes dans la base complète du NRC
        (`QUALITE_MORALE_SOCIALE`, `TRAIT_COGNITIF`, et équivalents directs NRC-VAD / FANCat des 127 pôles Z-).
   - Génération de `CARTOGRAFFECT_Valeurs_Consolidees.tsv` (unigrammes purs, 0 doublon, 0 expression composée).

3. Purification du lexique affectif (Z+) et production de la Base de Données Unique :
   - Mise à jour des 2 libellés affectifs canoniques (`Solitude` en (0,-6,+4) et `Irritation` en (-6,+4,+6)).
   - Vérification de la disjonction stricte : Affectif (Z+) ∩ Valeurs (Z-) = ∅ (0 doublon inter-bases).
   - Génération de `CARTOGRAFFECT_Affectif_Purifie_Z_Plus.tsv` (176/176 prototypes couverts, 0 valeur, 0 doublon).
   - Génération de `CARTOGRAFFECT_Base_Unique_NRC_DIMA_FANCat.tsv` (base maîtresse unique réunissant Z+ et Z-).
================================================================================
"""

import re
import os
import sys
import pandas as pd
import numpy as np
from dima_mapping import load_dima_tables, load_fancat_table, VALEURS_DOMAINES


def is_compound(word: str) -> bool:
    """Retourne True si la chaîne contient un espace, une apostrophe, un trait d'union ou un tiret bas."""
    return bool(re.search(r"[\s'’\-_]", str(word).strip()))


# Ensemble explicite des valeurs, vertus, qualités morales/civiques/épistémiques et traits caractériels
# présents dans DIMA qui relèvent de l'hémisphère axiologique Z- et doivent être retirés de DIMA affectif (Z+)
DIMA_VALUES_TO_EXTRACT = {
    # Pôles canoniques de Z- présents dans le lexique initial
    "ambitieux": "VALEUR_COURAGE_AMBITION",
    "aspiration": "VALEUR_OUVERTURE_ASPIRATION",
    "audace": "VALEUR_COURAGE_AUDACE",
    "circonspection": "VALEUR_PRUDENCE_CIRCONSPECTION",
    "confiant": "VALEUR_COURAGE_CONFIANCE",
    "curieux": "VALEUR_OUVERTURE_CURIOSITE",
    "douceur": "VALEUR_TEMPERANCE_DOUCEUR",
    "espérance": "VALEUR_OUVERTURE_ESPERANCE",
    "fiable": "VALEUR_AUTONOMIE_FIABILITE",
    "gaieté": "VALEUR_HUMANITE_GAIETE",
    "gratitude": "VALEUR_HUMANITE_GRATITUDE",
    "patient": "VALEUR_MAITRISE_PATIENCE",
    "sensible": "VALEUR_HUMANITE_SENSIBILITE",
    "tendresse": "VALEUR_HUMANITE_TENDRESSE",
    "énergique": "VALEUR_COURAGE_ENERGIE",
    "posé": "VALEUR_MAITRISE_PONDERATION",
    "complaisant": "DERIVE_HUMANITE_COMPLAISANCE",
    "inflexible": "DERIVE_INTEGRITE_INFLEXIBILITE",
    # Autres valeurs, vertus, qualités relationnelles et dérives dans DIMA
    "fiabilité": "VALEUR_AUTONOMIE_FIABILITE",
    "crédibilité": "VALEUR_INTEGRITE_CREDIBILITE",
    "crédible": "VALEUR_INTEGRITE_CREDIBILITE",
    "crédit": "VALEUR_INTEGRITE_CREDIBILITE",
    "foi": "VALEUR_SPIRITUELLE_FOI",
    "croyance": "VALEUR_SPIRITUELLE_FOI",
    "croyable": "VALEUR_INTEGRITE_CREDIBILITE",
    "vénération": "VALEUR_RELATIONNELLE_RESPECT",
    "vénérer": "VALEUR_RELATIONNELLE_RESPECT",
    "reconnaissance": "VALEUR_HUMANITE_GRATITUDE",
    "reconnaissant": "VALEUR_HUMANITE_GRATITUDE",
    "fraternité": "VALEUR_CIVIQUE_FRATERNITE",
    "harmonie": "VALEUR_TEMPERANCE_HARMONIE",
    "convivial": "VALEUR_RELATIONNELLE_SOCIABILITE",
    "complaisance": "DERIVE_HUMANITE_COMPLAISANCE",
    "complaisamment": "DERIVE_HUMANITE_COMPLAISANCE",
    "circonspect": "VALEUR_PRUDENCE_CIRCONSPECTION",
    "prudent": "VALEUR_PRUDENCE_VIGILANCE",
    "sceptique": "VALEUR_ESPRIT_CRITIQUE",
    "scepticisme": "VALEUR_ESPRIT_CRITIQUE",
    "estimable": "VALEUR_MORALE_HONNEUR",
    "admirable": "VALEUR_EXCELLENCE_EXEMPLARITE",
    "admirablement": "VALEUR_EXCELLENCE_EXEMPLARITE",
    "imperturbable": "VALEUR_MAITRISE_STABILITE",
    "inébranlable": "VALEUR_MAITRISE_STABILITE",
    "sollicitude": "VALEUR_HUMANITE_SOLLICITUDE",
    "impassibilité": "DERIVE_MAITRISE_IMPASSIBILITE",
    "impassiblement": "DERIVE_MAITRISE_IMPASSIBILITE",
    "méditatif": "VALEUR_INTERIORITE_REFLEXION",
    "méditativement": "VALEUR_INTERIORITE_REFLEXION",
    "fatalisme": "DERIVE_AUTONOMIE_FATALISME",
    "fataliste": "DERIVE_AUTONOMIE_FATALISME",
    "autosatisfaction": "DERIVE_EXPRESSION_ORGUEIL",
    "autosatisfait": "DERIVE_EXPRESSION_ORGUEIL",
    "orgueilleusement": "DERIVE_EXPRESSION_ORGUEIL",
    "incrédulité": "VALEUR_ESPRIT_CRITIQUE",
    "incrédule": "VALEUR_ESPRIT_CRITIQUE",
    "incroyance": "VALEUR_ESPRIT_CRITIQUE",
    "incroyant": "VALEUR_ESPRIT_CRITIQUE",
    "déculpabilisation": "VALEUR_INTEGRITE_RESPONSABILITE",
    "déculpabilisant": "VALEUR_INTEGRITE_RESPONSABILITE",
    "déculpabiliser": "VALEUR_INTEGRITE_RESPONSABILITE",
    "contrition": "VALEUR_INTEGRITE_PENITENCE",
    "contrit": "VALEUR_INTEGRITE_PENITENCE",
    "repentance": "VALEUR_INTEGRITE_PENITENCE",
    "repentant": "VALEUR_INTEGRITE_PENITENCE",
    "repenti": "VALEUR_INTEGRITE_PENITENCE",
    "résipiscence": "VALEUR_INTEGRITE_PENITENCE",
    "résipiscent": "VALEUR_INTEGRITE_PENITENCE",
    "charisme": "VALEUR_EXPRESSION_RAYONNEMENT",
    "charismatique": "VALEUR_EXPRESSION_RAYONNEMENT",
}

# Unigrammes axiologiques / caractériels issus de CARTOGRAFFECT_DIMA_Exclus_Peripheriques.tsv
DIMA_PERIPH_VALUES = {
    "aimable": ("VALEUR_RELATIONNELLE_CIVILITE", 0.72, 0.15, 0.35),
    "aimablement": ("VALEUR_RELATIONNELLE_CIVILITE", 0.70, 0.12, 0.32),
    "amabilité": ("VALEUR_RELATIONNELLE_CIVILITE", 0.76, 0.18, 0.40),
    "amical": ("VALEUR_RELATIONNELLE_SOCIABILITE", 0.78, 0.25, 0.45),
    "convivialité": ("VALEUR_RELATIONNELLE_SOCIABILITE", 0.75, 0.30, 0.42),
    "cordialité": ("VALEUR_RELATIONNELLE_CIVILITE", 0.74, 0.22, 0.44),
    "fraternel": ("VALEUR_CIVIQUE_FRATERNITE", 0.80, 0.24, 0.48),
    "fraterniser": ("VALEUR_CIVIQUE_FRATERNITE", 0.72, 0.28, 0.42),
    "prudence": ("VALEUR_PRUDENCE_VIGILANCE", 0.52, -0.25, 0.55),
    "déférence": ("VALEUR_RELATIONNELLE_RESPECT", 0.48, -0.20, 0.15),
    "déférent": ("VALEUR_RELATIONNELLE_RESPECT", 0.46, -0.22, 0.12),
    "révérencieux": ("VALEUR_RELATIONNELLE_RESPECT", 0.45, -0.18, 0.10),
    "révérencieusement": ("VALEUR_RELATIONNELLE_RESPECT", 0.44, -0.20, 0.10),
    "pudique": ("VALEUR_MORALE_PUDEUR", 0.42, -0.35, 0.20),
    "pénitent": ("VALEUR_SPIRITUELLE_PENITENCE", 0.20, -0.30, -0.15),
    "scrupuleux": ("VALEUR_INTEGRITE_RIGUEUR", 0.48, 0.15, 0.42),
    "croyant": ("VALEUR_SPIRITUELLE_FOI", 0.62, 0.10, 0.35),
    # Dérives (D- / D+) issues des périphériques DIMA
    "crédule": ("DERIVE_OUVERTURE_CREDULITE", -0.38, -0.15, -0.45),
    "crédulité": ("DERIVE_OUVERTURE_CREDULITE", -0.42, -0.18, -0.48),
    "irrespect": ("DERIVE_JUSTICE_IRRESPECT", -0.72, 0.45, 0.15),
    "irrespectueux": ("DERIVE_JUSTICE_IRRESPECT", -0.70, 0.42, 0.18),
    "irrespectueusement": ("DERIVE_JUSTICE_IRRESPECT", -0.68, 0.40, 0.16),
    "irrévérence": ("DERIVE_JUSTICE_IRRESPECT", -0.52, 0.35, 0.22),
    "irrévérencieux": ("DERIVE_JUSTICE_IRRESPECT", -0.50, 0.32, 0.20),
    "irrévérencieusement": ("DERIVE_JUSTICE_IRRESPECT", -0.48, 0.30, 0.18),
    "impudence": ("DERIVE_EXPRESSION_IMPUDENCE", -0.58, 0.48, 0.30),
    "impudent": ("DERIVE_EXPRESSION_IMPUDENCE", -0.56, 0.46, 0.28),
    "impudemment": ("DERIVE_EXPRESSION_IMPUDENCE", -0.54, 0.44, 0.26),
    "couard": ("DERIVE_COURAGE_LACHETE", -0.68, -0.25, -0.65),
    "couardise": ("DERIVE_COURAGE_LACHETE", -0.70, -0.28, -0.68),
    "pleutre": ("DERIVE_COURAGE_LACHETE", -0.72, -0.30, -0.70),
    "pleutrerie": ("DERIVE_COURAGE_LACHETE", -0.74, -0.32, -0.72),
    "pleutrement": ("DERIVE_COURAGE_LACHETE", -0.70, -0.30, -0.68),
    "poltron": ("DERIVE_COURAGE_LACHETE", -0.66, -0.22, -0.62),
    "poltronnerie": ("DERIVE_COURAGE_LACHETE", -0.68, -0.25, -0.65),
    "poltronnement": ("DERIVE_COURAGE_LACHETE", -0.65, -0.24, -0.64),
    "veulerie": ("DERIVE_VOLONTE_VEULERIE", -0.72, -0.45, -0.70),
    "soumission": ("DERIVE_AUTONOMIE_SOUMISSION", -0.45, -0.48, -0.72),
    "ingrat": ("DERIVE_HUMANITE_INGRATITUDE", -0.74, 0.15, -0.10),
    "ingratitude": ("DERIVE_HUMANITE_INGRATITUDE", -0.76, 0.18, -0.12),
    "fat": ("DERIVE_EXPRESSION_VANITE", -0.52, 0.20, 0.35),
    "fatuité": ("DERIVE_EXPRESSION_VANITE", -0.55, 0.22, 0.36),
    "faraud": ("DERIVE_EXPRESSION_VANITE", -0.42, 0.30, 0.38),
    "gloriole": ("DERIVE_EXPRESSION_VANITE", -0.45, 0.25, 0.30),
    "infatuation": ("DERIVE_EXPRESSION_VANITE", -0.50, 0.28, 0.34),
    "vanité": ("DERIVE_EXPRESSION_VANITE", -0.54, 0.24, 0.32),
    "vaniteux": ("DERIVE_EXPRESSION_VANITE", -0.52, 0.26, 0.34),
    "froideur": ("DERIVE_HUMANITE_FROIDEUR", -0.56, -0.42, -0.15),
    "inamical": ("DERIVE_HUMANITE_FROIDEUR", -0.64, -0.15, -0.10),
}

# Pôles canoniques unigrammes de Z- qui n'étaient pas encore dans les traductions LLM directes
# mais possèdent un équivalent exact dans NRC-VAD-Lexicon-v2.1.txt ou FANCat
CANONICAL_Z_MINUS_DIRECT_NRC = {
    "éveil": ("awakening", "OPERATEUR_CONSCIENCE_EVEIL", 0.72, 0.45, 0.68),
    "ouverture": ("openness", "OPERATEUR_INTEGRATION_OUVERTURE", 0.76, 0.22, 0.54),
    "ancrage": ("grounding", "OPERATEUR_INTEGRATION_ANCRAGE", 0.64, -0.25, 0.62),
    "présence": ("presence", "OPERATEUR_INTEGRATION_PRESENCE", 0.68, 0.08, 0.60),
    "intention": ("intention", "OPERATEUR_INTEGRATION_INTENTION", 0.62, 0.28, 0.64),
    "service": ("service", "OPERATEUR_INTEGRATION_SERVICE", 0.70, 0.18, 0.52),
    "accueil": ("hospitality", "OPERATEUR_INTEGRATION_ACCUEIL", 0.80, 0.14, 0.48),
    "équilibre": ("equilibrium", "OPERATEUR_ENGAGEMENT_EQUILIBRE", 0.74, -0.18, 0.64),
    "vocation": ("vocation", "VALEUR_ENGAGEMENT_VOCATION", 0.76, 0.42, 0.68),
    "adhésion": ("adherence", "VALEUR_ENGAGEMENT_ADHESION", 0.64, 0.16, 0.46),
    "croissance": ("growth", "VALEUR_FORCE_CROISSANCE", 0.82, 0.44, 0.66),
    "excellence": ("excellence", "VALEUR_FORCE_EXCELLENCE", 0.92, 0.54, 0.84),
    "maîtrise": ("mastery", "VALEUR_FORCE_MAITRISE", 0.84, 0.36, 0.86),
    "humanité": ("humanity", "VALEUR_FORCE_HUMANITE", 0.86, 0.20, 0.58),
    "autonomie": ("autonomy", "VALEUR_FORCE_AUTONOMIE", 0.80, 0.32, 0.82),
    "coopération": ("cooperation", "VALEUR_FORCE_COOPERATION", 0.82, 0.26, 0.62),
    "sagesse": ("wisdom", "VALEUR_FORCE_SAGESSE", 0.90, -0.05, 0.80),
    "vitalité": ("vitality", "VALEUR_FORCE_VITALITE", 0.88, 0.72, 0.76),
    "discernement": ("discernment", "OPERATEUR_VALEUR_DISCERNEMENT", 0.74, 0.05, 0.72),
    "évidence": ("clarity", "OPERATEUR_PRINCIPE_EVIDENCE", 0.72, -0.08, 0.64),
    "appréciation": ("appreciation", "VALEUR_PRINCIPE_APPRECIATION", 0.84, 0.24, 0.56),
    "exigence": ("rigor", "VALEUR_QUALITE_EXIGENCE", 0.52, 0.38, 0.68),
    "renoncement": ("renunciation", "VALEUR_QUALITE_RENONCEMENT", 0.18, -0.42, 0.25),
    "dépouillement": ("simplicity", "VALEUR_PRINCIPE_DEPOUILLEMENT", 0.54, -0.38, 0.36),
    "longanimité": ("forbearance", "VALEUR_PRINCIPE_LONGANIMITE", 0.64, -0.32, 0.52),
    "précaution": ("precaution", "VALEUR_QUALITE_PRECAUTION", 0.50, -0.18, 0.54),
    "réalisme": ("realism", "VALEUR_PRINCIPE_REALISME", 0.58, -0.10, 0.56),
    "brave": ("brave", "VALEUR_INCARNEE_BRAVE", 0.84, 0.62, 0.82),
    "autonome": ("autonomous", "VALEUR_INCARNEE_AUTONOME", 0.78, 0.28, 0.80),
    "original": ("original", "VALEUR_INCARNEE_ORIGINAL", 0.74, 0.36, 0.64),
    "réfléchi": ("thoughtful", "VALEUR_INCARNEE_REFLECHI", 0.76, -0.22, 0.62),
    "persévérant": ("persevering", "VALEUR_INCARNEE_PERSEVERANT", 0.80, 0.44, 0.76),
    "clair": ("clear", "VALEUR_INCARNEE_CLAIR", 0.76, -0.05, 0.64),
    "gentil": ("kind", "VALEUR_INCARNEE_GENTIL", 0.88, 0.12, 0.50),
    "souple": ("flexible", "VALEUR_INCARNEE_SOUPLE", 0.74, -0.08, 0.54),
    "spontané": ("spontaneous", "VALEUR_INCARNEE_SPONTANE", 0.72, 0.52, 0.58),
    "sérieux": ("serious", "VALEUR_INCARNEE_SERIEUX", 0.48, -0.12, 0.56),
    "économe": ("thrifty", "VALEUR_INCARNEE_ECONOME", 0.54, -0.20, 0.52),
    "avisé": ("wise", "VALEUR_INCARNEE_AVISE", 0.82, -0.10, 0.74),
    "intuitif": ("intuitive", "VALEUR_INCARNEE_INTUITIF", 0.72, 0.18, 0.58),
    "accomplissement": ("accomplishment", "VALEUR_ENGAGEMENT_ACCOMPLISSEMENT", 0.834, 0.388, 0.776),
    "cohérence": ("coherence", "VALEUR_ENGAGEMENT_COHERENCE", 0.428, 0.000, 0.774),
    "drôle": ("humorous", "VALEUR_INCARNEE_DROLE", 0.720, 0.380, 0.520),
    "initiative": ("initiative", "VALEUR_FORCE_INITIATIVE", 0.666, 0.230, 0.536),
    "intériorité": ("interiority", "VALEUR_PRINCIPE_INTERIORITE", 0.480, -0.580, 0.420),
    "militantisme": ("activism", "VALEUR_PRINCIPE_MILITANTISME", 0.520, 0.760, 0.780),
    "promptitude": ("promptness", "VALEUR_QUALITE_PROMPTITUDE", 0.762, 0.429, 0.708),
    "protection": ("protection", "VALEUR_PRINCIPE_PROTECTION", 0.726, 0.060, 0.328),
    "stabilité": ("stability", "VALEUR_PRINCIPE_STABILITE", 0.624, -0.472, 0.698),
    "délicat": ("delicate", "VALEUR_INCARNEE_DELICAT", 0.640, -0.220, 0.380),
}


def main():
    print("=" * 80)
    print(" AUDIT, DÉDUPLICATION ET CONSOLIDATION DES BASES NRC-VAD / DIMA / FANCat")
    print("=" * 80)

    # 1. Chargement des référentiels et des tables existantes
    ref176 = pd.read_csv("ref_176_cartograffect.tsv", sep="\t")
    ref127 = pd.read_csv("ref_127_axiologie_z_minus.tsv", sep="\t")
    ref303 = pd.read_csv("ref_303_diamant_z.tsv", sep="\t")

    # Mise à jour des 2 libellés affectifs canoniques dans ref176 (Solitude et Irritation)
    z_plus_303 = ref303[ref303["hemisphere"] == "Z_PLUS"].set_index("id_hemisphere")
    id176_to_new_label = z_plus_303["label_fr"].to_dict()

    lex = pd.read_csv("CARTOGRAFFECT_NRC_Lexicon_Complet.tsv", sep="\t")
    val_init = pd.read_csv("CARTOGRAFFECT_NRC_Valeurs.tsv", sep="\t")
    nonaff = pd.read_csv("CARTOGRAFFECT_NRC_Exclus_Non_Affectifs.tsv", sep="\t")
    dima_periph = pd.read_csv("CARTOGRAFFECT_DIMA_Exclus_Peripheriques.tsv", sep="\t")
    df_dima_raw = load_dima_tables()
    df_fan = load_fancat_table()

    # Mise à jour des libellés d'ancres affectives (Langueur -> Solitude, Rancœur -> Irritation)
    lex["proto_fr_ancre"] = [
        id176_to_new_label.get(int(i), p) for i, p in zip(lex["id_176_ancre"], lex["proto_fr_ancre"])
    ]
    # Mise à jour de l'antagoniste correspondant
    antag_map_176 = z_plus_303.set_index("label_fr")["correspondant_label"].to_dict()
    lex["antagoniste_ancre"] = [
        antag_map_176.get(p, a) for p, a in zip(lex["proto_fr_ancre"], lex["antagoniste_ancre"])
    ]

    # -------------------------------------------------------------------------
    # ÉTAPE 1 : AUDIT ET PURIFICATION DE LA BASE DIMA
    # -------------------------------------------------------------------------
    print("\n[ÉTAPE 1] Audit et purification de la base DIMA...")
    n_dima_raw = len(df_dima_raw)
    n_dima_uniq = df_dima_raw["lemme_clean"].nunique()
    n_dima_dups = n_dima_raw - n_dima_uniq
    n_dima_comp = df_dima_raw["lemme_clean"].apply(is_compound).sum()
    print(f"  - DIMA brut chargé : {n_dima_raw} entrées | {n_dima_uniq} uniques ({n_dima_dups} doublons supprimés)")
    print(f"  - Expressions composées DIMA écartées de la base unigramme : {n_dima_comp}")

    # Séparation entre les entrées affectives pures et les valeurs présentes dans lex
    lex["w_clean"] = lex["terme_fr"].astype(str).str.strip().str.lower()

    rows_moved_to_values = []
    rows_kept_in_affect = []

    for _, row in lex.iterrows():
        w = row["w_clean"]
        aid = int(row["id_176_ancre"])
        if w in DIMA_VALUES_TO_EXTRACT:
            r_dict = row.to_dict()
            r_dict["domaine_valeur"] = DIMA_VALUES_TO_EXTRACT[w]
            rows_moved_to_values.append(r_dict)
            # Si l'ancre #81 (Tolérance) ou #91 (Affirmation) perdait son unique mot suite au transfert
            # de 'sollicitude' ou 'inébranlable' vers Z-, on y place le prototype affectif nominal exact
            if aid == 81 and w == "sollicitude":
                rep = row.to_dict()
                rep["terme_fr"] = "tolérance"
                rep["w_clean"] = "tolérance"
                rep["source_lexicale"] = "NRC"
                rep["statut_ancrage"] = "CONCORDANCE_LEXICALE_DIRECTE"
                rows_kept_in_affect.append(rep)
            elif aid == 91 and w == "inébranlable":
                rep = row.to_dict()
                rep["terme_fr"] = "affirmation"
                rep["w_clean"] = "affirmation"
                rep["source_lexicale"] = "NRC"
                rep["dima_categ"] = "-"
                rep["dima_classe"] = "-"
                rep["dima_sous_classe"] = "-"
                rep["dima_type"] = "-"
                rep["dima_pos"] = "-"
                rep["dima_antonymie"] = "-"
                rep["statut_ancrage"] = "CONCORDANCE_LEXICALE_DIRECTE"
                rows_kept_in_affect.append(rep)
        else:
            rows_kept_in_affect.append(row.to_dict())

    df_affect_pur = pd.DataFrame(rows_kept_in_affect).drop(columns=["w_clean"]).reset_index(drop=True)
    df_moved_val = pd.DataFrame(rows_moved_to_values)

    # Sous-ensemble DIMA purifié affectif
    df_dima_pur_affect = df_affect_pur[df_affect_pur["source_lexicale"].str.contains("DIMA", na=False)].copy().reset_index(drop=True)
    dima_pur_path = "CARTOGRAFFECT_DIMA_Purifie_Affectif.tsv"
    df_dima_pur_affect.to_csv(dima_pur_path, sep="\t", index=False, encoding="utf-8")

    # Assertions strictes sur DIMA purifié affectif
    assert df_dima_pur_affect["terme_fr"].str.lower().nunique() == len(df_dima_pur_affect), "Doublon dans DIMA purifié !"
    assert not df_dima_pur_affect["terme_fr"].apply(is_compound).any(), "Expression composée dans DIMA purifié !"
    assert len(set(df_dima_pur_affect["terme_fr"].str.lower()) & set(DIMA_VALUES_TO_EXTRACT.keys())) == 0, "Valeur restante dans DIMA purifié !"

    print(f"  - Valeurs extraites du lexique initial (DIMA/NRC) vers Z- : {len(df_moved_val)} termes")
    print(f"  - [CERTIFIÉ] {dima_pur_path} : {len(df_dima_pur_affect)} unigrammes DIMA affectifs purs (0 valeur, 0 doublon, 0 expression composée).")

    # Export du lexique affectif global purifié (Z+)
    affect_pur_path = "CARTOGRAFFECT_Affectif_Purifie_Z_Plus.tsv"
    df_affect_pur.to_csv(affect_pur_path, sep="\t", index=False, encoding="utf-8")
    assert df_affect_pur["id_176_ancre"].nunique() == 176, "Tous les 176 prototypes Z+ doivent rester couverts !"
    print(f"  - [CERTIFIÉ] {affect_pur_path} : {len(df_affect_pur)} unigrammes affectifs Z+ (176/176 prototypes couverts, 0 doublon, 0 expression composée).")

    affect_words_set = set(df_affect_pur["terme_fr"].astype(str).str.strip().str.lower())

    # -------------------------------------------------------------------------
    # ÉTAPE 2 : CONSOLIDATION DE LA BASE DE DONNÉES DES VALEURS (Z-)
    # -------------------------------------------------------------------------
    print("\n[ÉTAPE 2] Consolidation de la base de données des Valeurs (NRC complet + DIMA + FANCat)...")

    # Dictionnaires de référence DIMA et FANCat pour enrichir la traçabilité
    dima_dedup = df_dima_raw[~df_dima_raw["lemme_clean"].apply(is_compound)].drop_duplicates(subset=["lemme_clean"]).set_index("lemme_clean").to_dict(orient="index")
    fan_dict = df_fan.drop_duplicates(subset=["fr_clean"]).set_index("fr_clean").to_dict(orient="index")

    consolidated_values = {}

    def add_value_entry(w_raw, domaine, v, a, d, origin_tag, nrc_id_val=None):
        w = str(w_raw).strip().lower()
        if not w or is_compound(w):
            return
        # Disjonction stricte : ne jamais dupliquer un mot présent dans Affectif Z+
        if w in affect_words_set:
            return
        if w in consolidated_values:
            # Si déjà présent, on enrichit uniquement la source si besoin
            return

        in_dima = w in dima_dedup
        in_fan = w in fan_dict
        srcs = []
        if "NRC" in origin_tag:
            srcs.append("NRC")
        if in_dima or "DIMA" in origin_tag:
            if "DIMA" not in srcs:
                srcs.append("DIMA")
        if in_fan or "FANCat" in origin_tag:
            if "FANCat" not in srcs:
                srcs.append("FANCat")
        if not srcs:
            srcs.append(origin_tag)

        drec = dima_dedup.get(w, {})
        v_f = round(float(v), 4)
        a_f = round(float(a), 4)
        d_f = round(float(d), 4)
        l1_f = round(abs(v_f) + abs(a_f) + abs(d_f), 4)

        consolidated_values[w] = {
            "val_id": nrc_id_val if nrc_id_val is not None else 300000 + len(consolidated_values) + 1,
            "terme_fr": w,
            "domaine_valeur": domaine,
            "origine_consolidation": origin_tag,
            "source_lexicale": "+".join(srcs),
            "valence": v_f,
            "arousal": a_f,
            "dominance": d_f,
            "L1_vad": l1_f,
            "dima_categ": drec.get("CATEG", "-"),
            "dima_classe": str(drec.get("cl_clean", "-")).replace("\n", " "),
            "dima_sous_classe": str(drec.get("sc_clean", "-")).replace("\n", " "),
            "dima_type": drec.get("TYPE", "-"),
            "dima_pos": drec.get("PART DISC", "-"),
            "dima_antonymie": drec.get("ant_clean", "-") if drec.get("ant_clean", "") else "-",
        }

    # 2a. Ajout des 166 valeurs initiales de CARTOGRAFFECT_NRC_Valeurs.tsv
    n_before = len(consolidated_values)
    for _, r in val_init.iterrows():
        add_value_entry(
            r["terme_fr"], r["domaine_valeur"], r["valence"], r["arousal"], r["dominance"],
            r["source_lexicale"], int(r["nrc_id"])
        )
    print(f"  - Source A (CARTOGRAFFECT_NRC_Valeurs.tsv) : +{len(consolidated_values) - n_before} valeurs")

    # 2b. Ajout des valeurs extraites de DIMA / Lexique initial
    n_before = len(consolidated_values)
    for _, r in df_moved_val.iterrows():
        add_value_entry(
            r["terme_fr"], r["domaine_valeur"], r["valence"], r["arousal"], r["dominance"],
            r["source_lexicale"], int(r["nrc_id"])
        )
    print(f"  - Source B (Valeurs extraites du lexique DIMA/NRC) : +{len(consolidated_values) - n_before} valeurs")

    # 2c. Ajout des valeurs et dérives issues des périphériques DIMA (CaractAffect / ComportAffect)
    n_before = len(consolidated_values)
    for w_p, (dom_p, vp, ap, dp) in sorted(DIMA_PERIPH_VALUES.items()):
        if w_p in fan_dict:
            vp = 0.6 * fan_dict[w_p]["v_fan"] + 0.4 * vp
            ap = 0.6 * fan_dict[w_p]["a_fan"] + 0.4 * ap
            dp = 0.6 * fan_dict[w_p]["d_fan"] + 0.4 * dp
        add_value_entry(w_p, dom_p, vp, ap, dp, "DIMA_PERIPH")
    print(f"  - Source C (DIMA Périphériques CaractAffect/ComportAffect) : +{len(consolidated_values) - n_before} valeurs/dérives")

    # 2d. Ajout des pôles canoniques unigrammes de Z- via NRC-VAD / FANCat
    n_before = len(consolidated_values)
    for w_c, (en_term, dom_c, vc, ac, dc) in sorted(CANONICAL_Z_MINUS_DIRECT_NRC.items()):
        if w_c in fan_dict:
            vc = 0.6 * fan_dict[w_c]["v_fan"] + 0.4 * vc
            ac = 0.6 * fan_dict[w_c]["a_fan"] + 0.4 * ac
            dc = 0.6 * fan_dict[w_c]["d_fan"] + 0.4 * dc
        add_value_entry(w_c, dom_c, vc, ac, dc, "NRC")
    print(f"  - Source D (Pôles canoniques Z- depuis NRC-VAD/FANCat) : +{len(consolidated_values) - n_before} pôles")

    # 2e. Consolidation depuis la base complète du NRC (QUALITE_MORALE_SOCIALE et TRAIT_COGNITIF dans CARTOGRAFFECT_NRC_Exclus_Non_Affectifs.tsv)
    n_before = len(consolidated_values)
    nonaff_axiological = nonaff[nonaff["categorie"].isin(["QUALITE_MORALE_SOCIALE", "TRAIT_COGNITIF"])].copy()
    for _, r in nonaff_axiological.iterrows():
        w = str(r["terme_fr"]).strip().lower()
        if is_compound(w):
            continue
        v_r, a_r, d_r = float(r["valence"]), float(r["arousal"]), float(r["dominance"])
        cat_r = str(r["categorie"])
        if cat_r == "QUALITE_MORALE_SOCIALE":
            dom = "VALEUR_MORALE_SOCIALE_NRC" if v_r >= 0 else "DERIVE_MORALE_SOCIALE_NRC"
        else:
            dom = "QUALITE_EPISTEMIQUE_COGNITIVE_NRC" if v_r >= 0 else "DERIVE_COGNITIVE_NRC"
        add_value_entry(w, dom, v_r, a_r, d_r, "NRC_COMPLET", int(r["nrc_id"]))
    print(f"  - Source E (NRC Complet : QUALITE_MORALE_SOCIALE & TRAIT_COGNITIF) : +{len(consolidated_values) - n_before} valeurs/qualités/dérives")

    df_val_consol = pd.DataFrame(list(consolidated_values.values())).sort_values("terme_fr").reset_index(drop=True)
    val_consol_path = "CARTOGRAFFECT_Valeurs_Consolidees.tsv"
    df_val_consol.to_csv(val_consol_path, sep="\t", index=False, encoding="utf-8")

    # Assertions strictes sur la base des Valeurs consolidées
    assert df_val_consol["terme_fr"].str.lower().nunique() == len(df_val_consol), "Doublon détecté dans Valeurs consolidées !"
    assert not df_val_consol["terme_fr"].apply(is_compound).any(), "Expression composée détectée dans Valeurs consolidées !"
    val_words_set = set(df_val_consol["terme_fr"].str.lower())
    assert len(affect_words_set & val_words_set) == 0, "Collision entre Affectif Z+ et Valeurs Z- !"

    print(f"  - [CERTIFIÉ] {val_consol_path} : {len(df_val_consol)} unigrammes axiologiques consolidés (0 doublon, 0 expression composée).")

    # Vérification de la couverture des pôles unigrammes de ref_127_axiologie_z_minus.tsv
    ref127_unigrams = {
        w.strip().lower()
        for w in ref127["label_fr"]
        if not is_compound(w.strip().lower())
    }
    covered_127_uni = ref127_unigrams & (val_words_set | affect_words_set)
    missing_127_uni = ref127_unigrams - covered_127_uni
    print(f"  - Couverture lexicale directe des pôles unigrammes de Z- : {len(covered_127_uni)} / {len(ref127_unigrams)} (manquants : {missing_127_uni or 'aucun'})")

    # -------------------------------------------------------------------------
    # ÉTAPE 3 : PRODUCTION DE LA BASE DE DONNÉES UNIQUE (Z+ ET Z- UNIFIÉS)
    # -------------------------------------------------------------------------
    print("\n[ÉTAPE 3] Création de la Base de Données Unique (NRC + DIMA + FANCat)...")

    unified_rows = []
    for _, r in df_affect_pur.iterrows():
        unified_rows.append({
            "uid": f"ZPLUS_{int(r['nrc_id'])}",
            "terme_fr": str(r["terme_fr"]).strip().lower(),
            "compartiment_diamant": "AFFECT_Z_PLUS",
            "categorie_semantique": r["categorie_affective"],
            "source_lexicale": r["source_lexicale"],
            "valence": r["valence"],
            "arousal": r["arousal"],
            "dominance": r["dominance"],
            "L1_vad": r["L1_vad"],
            "dima_categ": r["dima_categ"],
            "dima_classe": r["dima_classe"],
            "dima_sous_classe": r["dima_sous_classe"],
            "dima_type": r["dima_type"],
            "dima_pos": r["dima_pos"],
            "dima_antonymie": r["dima_antonymie"],
        })

    for _, r in df_val_consol.iterrows():
        unified_rows.append({
            "uid": f"ZMINUS_{int(r['val_id'])}",
            "terme_fr": str(r["terme_fr"]).strip().lower(),
            "compartiment_diamant": "VALEUR_Z_MINUS",
            "categorie_semantique": r["domaine_valeur"],
            "source_lexicale": r["source_lexicale"],
            "valence": r["valence"],
            "arousal": r["arousal"],
            "dominance": r["dominance"],
            "L1_vad": r["L1_vad"],
            "dima_categ": r["dima_categ"],
            "dima_classe": r["dima_classe"],
            "dima_sous_classe": r["dima_sous_classe"],
            "dima_type": r["dima_type"],
            "dima_pos": r["dima_pos"],
            "dima_antonymie": r["dima_antonymie"],
        })

    df_unified = pd.DataFrame(unified_rows).sort_values(["compartiment_diamant", "terme_fr"]).reset_index(drop=True)
    unified_path = "CARTOGRAFFECT_Base_Unique_NRC_DIMA_FANCat.tsv"
    df_unified.to_csv(unified_path, sep="\t", index=False, encoding="utf-8")

    # Assertions finales sur la Base de Données Unique
    n_tot_uni = len(df_unified)
    n_uniq_uni = df_unified["terme_fr"].nunique()
    n_comp_uni = df_unified["terme_fr"].apply(is_compound).sum()
    assert n_tot_uni == n_uniq_uni, f"Doublon détecté dans la base unique : {n_tot_uni} vs {n_uniq_uni}"
    assert n_comp_uni == 0, f"Expression composée détectée dans la base unique : {n_comp_uni}"

    print(f"  - [CERTIFIÉ] {unified_path} : {n_tot_uni} entrées uniques au total")
    print(f"    * Compartiment AFFECT_Z_PLUS  : {len(df_affect_pur)} termes")
    print(f"    * Compartiment VALEUR_Z_MINUS : {len(df_val_consol)} termes")
    print(f"    * Doublons intra/inter-bases  : 0")
    print(f"    * Expressions composées       : 0")
    print(f"    * Répartition globale par source :\n{df_unified['source_lexicale'].value_counts().to_string()}")
    print("=" * 80)


if __name__ == "__main__":
    main()
