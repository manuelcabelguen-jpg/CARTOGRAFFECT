#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
================================================================================
Projet CARTOGRAFFECT® — Dictionnaire Vectoriel Complet Multi-Strates (6 Strates)
& Analyseur Open-Data CNRS (GLAWI / Morphalou 3.1 / TLFi) & Lexique 3.83
Fichier : src/build_full_cartograffect_dictionary.py
================================================================================
Construction, analyse morpho-sémantique open-data (CNRS CLLE-ERSS GLAWI, CNRS
ATILF Morphalou 3.1 / TLFi, Lexique 3.83) et projection géométrique 3D du
Dictionnaire Vectoriel Complet CARTOGRAFFECT® (Certificat d'enregistrement de
droit d'auteur OPIC / CIPO n° 1233199 — Titulaire : Manuel Cabelguen) couvrant
les 6 strates sémantiques verticales de l'expérience humaine sur l'axe Z :

  1. STRATUM_1_AFFECTIVE_SOMATIC      (Z- profond, Ratio_Z < 0.65)
     Affects basaux, états viscéraux, réflexes interoceptifs, pulsions.
  2. STRATUM_2_EMOTIONAL_EPISODIC     (Z- à Z_7, 0.65 <= Ratio_Z < 0.95)
     Émotions aiguës épisodiques, réactions immédiates d'orientation et d'action.
  3. STRATUM_3_SENTIMENTAL_RELATIONAL (Équateur Z_7 à Z+ bas, 0.95 <= Ratio_Z < 1.25)
     Sentiments durables, attachements interpersonnels, humeurs et tonalités.
  4. STRATUM_4_ETHICAL_MORAL          (Z+ moyen, 1.25 <= Ratio_Z < 1.60)
     Émotions morales, vertus, transgressions, responsabilité (Haidt, 2003).
  5. STRATUM_5_AXIOLOGICAL_VALUES     (Z+ élevé, 1.60 <= Ratio_Z < 2.00)
     Valeurs fondamentales, principes, dignité, équité (Schwartz, 2012).
  6. STRATUM_6_POLITICAL_CIVIC        (Z+ culminant, Ratio_Z >= 2.00)
     Affects collectifs, justice sociale, gouvernance, contrat social, idéologie.

Conformité juridique stricte :
- Code source sous licence GNU AGPLv3 (SPDX-License-Identifier: AGPL-3.0-or-later).
- Architecture théorique, taxonomie et tables dérivées sous licence CC BY-NC-SA 4.0.
- Nomenclature lexicographique française exclusivement issue de bases ouvertes :
  * Lexique 3.83 (New et al., 2004 — CC BY-SA 4.0)
  * GLAWI (Sajous & Hathout, 2015, CLLE-ERSS CNRS UMR 5263 — CC BY-SA)
  * Morphalou 3.1 / TLFi (CNRS ATILF UMR 7118 — Licence Ouverte)
  croisée avec les paramètres dérivés NRC-VAD (Mohammad, 2018), DIMA (Le Pesant,
  2023, recherche équitable art. 29 LDA Canada) et les 24 ancres componantielles
  GRID / CPM (Scherer, 2005 ; Fontaine et al., 2007, 2013).
  Aucune donnée issue de dictionnaires commerciaux (ex. Larousse, Le Robert)
  n'est utilisée.

Copyright (C) 2026  Manuel Cabelguen — Projet CARTOGRAFFECT® (OPIC n° 1233199)
SPDX-License-Identifier: AGPL-3.0-or-later
================================================================================
"""

from __future__ import annotations

import json
import os
import sys
from enum import Enum
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
import pandas as pd

# Permet l'import depuis la racine du dépôt ou depuis src/
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from src.grid_cpm_integration import (
    GRID_24_CANONICAL_PROTOTYPES,
    map_grid_to_cartograffect_3d,
)


# ==============================================================================
# 1. ÉNUMÉRATION DES 6 STRATES SÉMANTIQUES VERTICALES SUR L'AXE Z
# ==============================================================================

class SemanticDomainStratum(str, Enum):
    """
    Hiérarchie formelle des 6 strates verticales de l'expérience humaine sur l'axe Z
    (plus l'ancre neutre d'origine Z_0), paramétrée par le ratio componantiel :
        Ratio_Z = (Score_Appraisal_Norms + Score_Subjective_Regulation)
                  / (Score_Bodily_Symptoms + Score_Motor_Expression)
    """
    STRATUM_0_NEUTRAL_ANCHOR = "STRATUM_0_NEUTRAL_ANCHOR"
    STRATUM_1_AFFECTIVE_SOMATIC = "STRATUM_1_AFFECTIVE_SOMATIC"
    STRATUM_2_EMOTIONAL_EPISODIC = "STRATUM_2_EMOTIONAL_EPISODIC"
    STRATUM_3_SENTIMENTAL_RELATIONAL = "STRATUM_3_SENTIMENTAL_RELATIONAL"
    STRATUM_4_ETHICAL_MORAL = "STRATUM_4_ETHICAL_MORAL"
    STRATUM_5_AXIOLOGICAL_VALUES = "STRATUM_5_AXIOLOGICAL_VALUES"
    STRATUM_6_POLITICAL_CIVIC = "STRATUM_6_POLITICAL_CIVIC"


STRATUM_METADATA: Dict[SemanticDomainStratum, Dict[str, Any]] = {
    SemanticDomainStratum.STRATUM_0_NEUTRAL_ANCHOR: {
        "rank": 0,
        "label_fr": "Origine homéostatique neutre (Z_0)",
        "short_fr": "S0 • Origine Z_0",
        "glawi_domain": "《homéostasie/origine》",
        "z_regime": "Z_0 (Point de Veille)",
        "ratio_z_min": 0.0,
        "ratio_z_max": 0.0,
        "z_crown_target": 0,
        "description": "Point de veille basal sans activation somatique ni médiation normative.",
        "theoretical_reference": "Cabelguen (2026) — Opérateur central Z_0",
    },
    SemanticDomainStratum.STRATUM_1_AFFECTIVE_SOMATIC: {
        "rank": 1,
        "label_fr": "1. Affectif basal & somatique",
        "short_fr": "S1 • Affectif / Somatique",
        "glawi_domain": "《physiologie/somatique》",
        "z_regime": "Z- profond (Ratio_Z < 0.65)",
        "ratio_z_min": 0.0,
        "ratio_z_max": 0.65,
        "z_crown_target": 2,
        "description": "Affects basaux, états viscéraux, interoception, réflexes d'orientation et pulsions.",
        "theoretical_reference": "Damasio (1999) ; Panksepp (1998) ; Scherer (2005) — Bodily Symptoms & Motor Expression",
    },
    SemanticDomainStratum.STRATUM_2_EMOTIONAL_EPISODIC: {
        "rank": 2,
        "label_fr": "2. Émotif épisodique",
        "short_fr": "S2 • Émotif épisodique",
        "glawi_domain": "《psychologie/émotion》",
        "z_regime": "Z- à Z_7 (0.65 <= Ratio_Z < 0.95)",
        "ratio_z_min": 0.65,
        "ratio_z_max": 0.95,
        "z_crown_target": 3,
        "description": "Émotions aiguës épisodiques, synchronisation componantielle rapide et tendances à l'action immédiates.",
        "theoretical_reference": "Scherer (2005) ; Fontaine, Scherer, Roesch, & Ellsworth (2007) — Épisodes émotionnels GRID",
    },
    SemanticDomainStratum.STRATUM_3_SENTIMENTAL_RELATIONAL: {
        "rank": 3,
        "label_fr": "3. Sentimental & relationnel durable",
        "short_fr": "S3 • Sentimental durable",
        "glawi_domain": "《affectivité/sentiment》",
        "z_regime": "Équateur Z_7 à Z+ bas (0.95 <= Ratio_Z < 1.25)",
        "ratio_z_min": 0.95,
        "ratio_z_max": 1.25,
        "z_crown_target": 4,
        "description": "Sentiments durables, liens d'attachement interpersonnel, humeurs et dispositions affectives stabilisées.",
        "theoretical_reference": "Frijda (1986) ; Le Pesant (2023, DIMA Cat. II) ; Fontaine, Scherer, & Soriano (2013)",
    },
    SemanticDomainStratum.STRATUM_4_ETHICAL_MORAL: {
        "rank": 4,
        "label_fr": "4. Éthique & moral",
        "short_fr": "S4 • Éthique & moral",
        "glawi_domain": "《éthique/morale》",
        "z_regime": "Z+ moyen (1.25 <= Ratio_Z < 1.60)",
        "ratio_z_min": 1.25,
        "ratio_z_max": 1.60,
        "z_crown_target": 5,
        "description": "Émotions morales auto-évaluatives et hétéro-évaluatives, vertus, transgressions, devoir et responsabilité.",
        "theoretical_reference": "Haidt (2003) — The Moral Emotions ; Tangney, Stuewig, & Mashek (2007)",
    },
    SemanticDomainStratum.STRATUM_5_AXIOLOGICAL_VALUES: {
        "rank": 5,
        "label_fr": "5. Axiologique & Valeurs fondamentales",
        "short_fr": "S5 • Axiologique / Valeurs",
        "glawi_domain": "《philosophie/axiologie》",
        "z_regime": "Z+ élevé (1.60 <= Ratio_Z < 2.00)",
        "ratio_z_min": 1.60,
        "ratio_z_max": 2.00,
        "z_crown_target": 6,
        "description": "Valeurs trans-situationnelles, principes directeurs, dignité humaine, équité, vérité et transcendance.",
        "theoretical_reference": "Schwartz (2012) — Theory of Basic Human Values ; Ricoeur (1990)",
    },
    SemanticDomainStratum.STRATUM_6_POLITICAL_CIVIC: {
        "rank": 6,
        "label_fr": "6. Politique, civique & social",
        "short_fr": "S6 • Politique & civique",
        "glawi_domain": "《politique/droit/société》",
        "z_regime": "Z+ culminant (Ratio_Z >= 2.00)",
        "ratio_z_min": 2.00,
        "ratio_z_max": 99.0,
        "z_crown_target": 7,
        "description": "Affects collectifs, justice sociale, institutions, gouvernance, contrat social, citoyenneté et idéologies.",
        "theoretical_reference": "Nussbaum (2013) — Political Emotions ; Rawls (1971) ; Habermas (1992)",
    },
}


def classify_ratio_z_to_stratum(
    ratio_z: float,
    is_neutral_origin: bool = False,
) -> SemanticDomainStratum:
    """
    Classifie de façon déterministe un indice vertical `Ratio_Z` dans l'une des
    6 strates sémantiques verticales (ou `STRATUM_0_NEUTRAL_ANCHOR` à l'origine Z_0).
    """
    if is_neutral_origin or ratio_z <= 0.0:
        return SemanticDomainStratum.STRATUM_0_NEUTRAL_ANCHOR
    if ratio_z < 0.65:
        return SemanticDomainStratum.STRATUM_1_AFFECTIVE_SOMATIC
    if ratio_z < 0.95:
        return SemanticDomainStratum.STRATUM_2_EMOTIONAL_EPISODIC
    if ratio_z < 1.25:
        return SemanticDomainStratum.STRATUM_3_SENTIMENTAL_RELATIONAL
    if ratio_z < 1.60:
        return SemanticDomainStratum.STRATUM_4_ETHICAL_MORAL
    if ratio_z < 2.00:
        return SemanticDomainStratum.STRATUM_5_AXIOLOGICAL_VALUES
    return SemanticDomainStratum.STRATUM_6_POLITICAL_CIVIC


# ==============================================================================
# 2. NOMENCLATURE FRANÇAISE OUVERTE (CNRS GLAWI / MORPHALOU 3.1 / LEXIQUE 3.83)
#    Extension ciblée pour les 6 strates sans aucune source commerciale.
# ==============================================================================

# Format : (lemme_fr, term_en_equiv, stratum_hint, sous_domaine, valence, arousal, dominance)
OPEN_FRENCH_EXTENSION_LEMMAS: List[Tuple[str, str, int, str, float, float, float]] = [
    # --- STRATE 1 : Affectif basal, viscéral, somatique et pulsionnel (Ratio_Z < 0.65) ---
    ("interoception", "interoception", 1, "SOMATIQUE_VISCERAL", 0.08, 0.42, -0.10),
    ("nociception", "nociception", 1, "SOMATIQUE_DOULEUR", -0.82, 0.78, -0.68),
    ("tachycardie", "tachycardia", 1, "SOMATIQUE_AUTONOME", -0.58, 0.88, -0.62),
    ("bradycardie", "bradycardia", 1, "SOMATIQUE_AUTONOME", -0.44, -0.64, -0.52),
    ("vasoconstriction", "vasoconstriction", 1, "SOMATIQUE_AUTONOME", -0.32, 0.62, -0.45),
    ("vasodilatation", "vasodilation", 1, "SOMATIQUE_AUTONOME", 0.28, 0.36, 0.12),
    ("horripilation", "piloerection", 1, "SOMATIQUE_FRISSON", -0.42, 0.74, -0.48),
    ("chair de poule", "goosebumps", 1, "SOMATIQUE_FRISSON", -0.25, 0.68, -0.38),
    ("hyperventilation", "hyperventilation", 1, "SOMATIQUE_RESPIRATOIRE", -0.68, 0.86, -0.72),
    ("oppression thoracique", "chest tightness", 1, "SOMATIQUE_RESPIRATOIRE", -0.78, 0.72, -0.74),
    ("boule au ventre", "stomach knot", 1, "SOMATIQUE_VISCERAL", -0.72, 0.68, -0.64),
    ("gorge nouée", "lump in throat", 1, "SOMATIQUE_VISCERAL", -0.74, 0.58, -0.68),
    ("spasme viscéral", "visceral spasm", 1, "SOMATIQUE_VISCERAL", -0.76, 0.75, -0.70),
    ("haut-le-cœur", "retching", 1, "SOMATIQUE_DEGOUT", -0.84, 0.66, -0.62),
    ("écœurement", "visceral nausea", 1, "SOMATIQUE_DEGOUT", -0.82, 0.54, -0.58),
    ("sursaut réflexe", "startle reflex", 1, "SOMATIQUE_ORIENTATION", -0.22, 0.92, -0.54),
    ("sidération motrice", "motor freezing", 1, "SOMATIQUE_SIDERATION", -0.80, 0.72, -0.88),
    ("catalepsie", "catalepsy", 1, "SOMATIQUE_SIDERATION", -0.66, -0.72, -0.86),
    ("léthargie", "lethargy", 1, "SOMATIQUE_TONUS", -0.58, -0.84, -0.72),
    ("torpeur", "torpor", 1, "SOMATIQUE_TONUS", -0.46, -0.82, -0.64),
    ("hébétude", "stupor", 1, "SOMATIQUE_TONUS", -0.54, -0.62, -0.68),
    ("asthénie", "asthenia", 1, "SOMATIQUE_TONUS", -0.64, -0.78, -0.70),
    ("éréthisme", "erethism", 1, "SOMATIQUE_EXCITATION", -0.28, 0.84, 0.14),
    ("prurit", "itching sensation", 1, "SOMATIQUE_CUTANE", -0.52, 0.56, -0.42),
    ("fourmillement", "tingling", 1, "SOMATIQUE_CUTANE", -0.18, 0.44, -0.24),
    ("étourdissement", "dizziness", 1, "SOMATIQUE_VESTIBULAIRE", -0.56, 0.48, -0.66),
    ("lipothymie", "faintness", 1, "SOMATIQUE_AUTONOME", -0.72, -0.54, -0.82),
    ("syncope", "syncope", 1, "SOMATIQUE_AUTONOME", -0.78, -0.76, -0.90),
    ("appétence", "appetitive drive", 1, "PULSION_APPROCHE", 0.68, 0.64, 0.48),
    ("satiété", "satiety", 1, "HOMEOSTASIE_SOMATIQUE", 0.72, -0.52, 0.42),
    ("désaltération", "quenching", 1, "HOMEOSTASIE_SOMATIQUE", 0.74, -0.38, 0.36),
    ("délivrance physique", "bodily relief", 1, "HOMEOSTASIE_SOMATIQUE", 0.76, -0.44, 0.40),
    ("volupté sensorielle", "sensory voluptuousness", 1, "PLAISIR_SOMATIQUE", 0.88, 0.62, 0.54),
    ("frémissement", "quivering", 1, "SOMATIQUE_FRISSON", 0.24, 0.66, -0.12),
    ("tressaillement", "thrill startle", 1, "SOMATIQUE_ORIENTATION", 0.18, 0.78, -0.18),
    ("crispation", "muscular tensing", 1, "SOMATIQUE_TONUS", -0.62, 0.68, -0.34),
    ("décharge adrénergique", "adrenaline rush", 1, "SOMATIQUE_AUTONOME", 0.12, 0.96, 0.44),
    ("endorphinie", "endorphin rush", 1, "HOMEOSTASIE_SOMATIQUE", 0.84, 0.32, 0.52),
    ("spasmophilie", "spasmophilia", 1, "SOMATIQUE_TONUS", -0.64, 0.72, -0.66),
    ("paresthésie", "paresthesia", 1, "SOMATIQUE_CUTANE", -0.38, 0.34, -0.44),
    ("dyspnée", "dyspnea", 1, "SOMATIQUE_RESPIRATOIRE", -0.80, 0.82, -0.78),
    ("apnée", "apnea", 1, "SOMATIQUE_RESPIRATOIRE", -0.68, 0.64, -0.72),
    ("sudation", "sweating", 1, "SOMATIQUE_AUTONOME", -0.34, 0.68, -0.40),
    ("algie", "acute pain", 1, "SOMATIQUE_DOULEUR", -0.86, 0.76, -0.72),
    ("endolorissement", "soreness", 1, "SOMATIQUE_DOULEUR", -0.68, -0.28, -0.56),
    ("courbature", "muscle ache", 1, "SOMATIQUE_TONUS", -0.54, -0.36, -0.42),
    ("fourbu", "exhausted", 1, "SOMATIQUE_TONUS", -0.58, -0.72, -0.60),
    ("éreinté", "worn out", 1, "SOMATIQUE_TONUS", -0.62, -0.74, -0.64),
    ("harassé", "exhausted fatigued", 1, "SOMATIQUE_TONUS", -0.64, -0.68, -0.62),
    ("assoupissement", "drowsiness", 1, "SOMATIQUE_TONUS", 0.28, -0.82, -0.24),

    # --- STRATE 2 : Émotif épisodique (0.65 <= Ratio_Z < 0.95) ---
    ("courroux", "wrath", 2, "EMOTION_COLERE", -0.78, 0.84, 0.62),
    ("ire", "acute anger", 2, "EMOTION_COLERE", -0.76, 0.82, 0.58),
    ("esclandre", "outburst", 2, "EMOTION_COLERE", -0.64, 0.78, 0.44),
    ("emportement", "flare-up", 2, "EMOTION_COLERE", -0.68, 0.82, 0.48),
    ("épouvante", "terror", 2, "EMOTION_PEUR", -0.90, 0.88, -0.82),
    ("frayeur", "fright", 2, "EMOTION_PEUR", -0.82, 0.84, -0.72),
    ("affolement", "panic alarm", 2, "EMOTION_PEUR", -0.78, 0.86, -0.74),
    ("ahurissement", "bewilderment", 2, "EMOTION_SURPRISE", -0.14, 0.76, -0.46),
    ("ébahi", "flabbergasted", 2, "EMOTION_SURPRISE", 0.22, 0.72, -0.32),
    ("stupéfaction", "stupefaction", 2, "EMOTION_SURPRISE", -0.18, 0.80, -0.48),
    ("allégresse", "elation", 2, "EMOTION_JOIE", 0.90, 0.76, 0.62),
    ("liesse", "jubilation", 2, "EMOTION_JOIE", 0.92, 0.80, 0.66),
    ("exultation", "exultation", 2, "EMOTION_JOIE", 0.88, 0.84, 0.74),
    ("jubilation", "glee", 2, "EMOTION_JOIE", 0.86, 0.78, 0.68),
    ("accablement", "overwhelming grief", 2, "EMOTION_TRISTESSE", -0.84, -0.54, -0.78),
    ("éploré", "tearful grief", 2, "EMOTION_TRISTESSE", -0.80, 0.24, -0.72),
    ("consterné", "dismayed", 2, "EMOTION_TRISTESSE", -0.74, 0.42, -0.56),
    ("répugnance", "revulsion", 2, "EMOTION_DEGOUT", -0.84, 0.52, -0.36),
    ("aversion aiguë", "acute aversion", 2, "EMOTION_DEGOUT", -0.80, 0.58, -0.28),
    ("enchantement", "delight", 2, "EMOTION_JOIE", 0.88, 0.56, 0.52),
    ("ébaudissement", "merry amazement", 2, "EMOTION_JOIE", 0.78, 0.68, 0.46),
    ("éblouissement", "dazzled wonder", 2, "EMOTION_SURPRISE", 0.82, 0.74, 0.32),
    ("sidération", "stunned shock", 2, "EMOTION_SURPRISE", -0.62, 0.82, -0.78),
    ("effarement", "alarmed bewilderment", 2, "EMOTION_PEUR", -0.72, 0.78, -0.68),
    ("affliction", "acute affliction", 2, "EMOTION_TRISTESSE", -0.82, -0.32, -0.68),
    ("désolation", "desolation", 2, "EMOTION_TRISTESSE", -0.86, -0.42, -0.74),
    ("rogne", "bad-tempered anger", 2, "EMOTION_COLERE", -0.66, 0.64, 0.36),
    ("grogne", "grumbling anger", 2, "EMOTION_COLERE", -0.62, 0.58, 0.32),
    ("transport", "ecstatic transport", 2, "EMOTION_JOIE", 0.88, 0.82, 0.58),
    ("ivresse", "euphoric intoxication", 2, "EMOTION_JOIE", 0.80, 0.78, 0.48),

    # --- STRATE 3 : Sentimental & relationnel durable (0.95 <= Ratio_Z < 1.25) ---
    ("dévotion affective", "loving devotion", 3, "SENTIMENT_ATTACHEMENT", 0.86, 0.28, 0.34),
    ("sollicitude", "solicitude", 3, "SENTIMENT_BIENVEILLANCE", 0.82, 0.14, 0.42),
    ("mansuétude", "clemency gentleness", 3, "SENTIMENT_BIENVEILLANCE", 0.78, -0.32, 0.38),
    ("dilection", "tender predilection", 3, "SENTIMENT_ATTACHEMENT", 0.84, 0.12, 0.40),
    ("attachement sécure", "secure attachment", 3, "SENTIMENT_ATTACHEMENT", 0.88, -0.18, 0.56),
    ("complicité", "interpersonal complicity", 3, "SENTIMENT_LIEN", 0.84, 0.32, 0.52),
    ("connivence", "tacit rapport", 3, "SENTIMENT_LIEN", 0.68, 0.24, 0.44),
    ("inimitié", "enmity", 3, "SENTIMENT_HOSTILITE", -0.78, 0.42, 0.28),
    ("animosité", "animosity", 3, "SENTIMENT_HOSTILITE", -0.76, 0.56, 0.36),
    ("acrimonie", "acrimony", 3, "SENTIMENT_HOSTILITE", -0.74, 0.48, 0.22),
    ("rancœur", "resentment", 3, "SENTIMENT_RESSENTIMENT", -0.78, 0.34, -0.24),
    ("ressentiment", "deep resentment", 3, "SENTIMENT_RESSENTIMENT", -0.80, 0.38, -0.32),
    ("amertume", "bitterness", 3, "SENTIMENT_RESSENTIMENT", -0.72, -0.12, -0.38),
    ("langueur", "languor", 3, "HUMEUR_MELANCOLIE", -0.34, -0.64, -0.44),
    ("spleen", "spleen melancholy", 3, "HUMEUR_MELANCOLIE", -0.62, -0.58, -0.52),
    ("vague à l'âme", "yearning melancholy", 3, "HUMEUR_MELANCOLIE", -0.48, -0.46, -0.42),
    ("désenchantement", "disenchantment", 3, "SENTIMENT_DECEPTION", -0.66, -0.34, -0.46),
    ("quiétude", "quietude", 3, "HUMEUR_SERENITE", 0.82, -0.68, 0.48),
    ("ataraxie", "ataraxia", 3, "HUMEUR_SERENITE", 0.76, -0.78, 0.62),
    ("plénitude", "fulfillment", 3, "SENTIMENT_ACCOMPLISSEMENT", 0.90, -0.14, 0.68),
    ("cordialité", "cordiality", 3, "SENTIMENT_LIEN", 0.80, 0.18, 0.48),
    ("camaraderie", "camaraderie", 3, "SENTIMENT_LIEN", 0.84, 0.34, 0.54),
    ("fraternisation", "fraternization", 3, "SENTIMENT_LIEN", 0.82, 0.28, 0.50),
    ("inclination", "affectionate inclination", 3, "SENTIMENT_ATTACHEMENT", 0.74, 0.14, 0.32),
    ("prédilection", "predilection", 3, "SENTIMENT_ATTACHEMENT", 0.78, 0.12, 0.42),
    ("éloignement affectif", "estrangement", 3, "SENTIMENT_RUPTURE", -0.68, -0.28, -0.36),
    ("désaffection", "disaffection", 3, "SENTIMENT_RUPTURE", -0.72, -0.34, -0.40),
    ("indifférence", "indifference", 3, "SENTIMENT_DETACHEMENT", -0.24, -0.62, 0.08),
    ("impassibilité", "impassivity", 3, "SENTIMENT_DETACHEMENT", 0.04, -0.74, 0.36),
    ("équanimité", "equanimity", 3, "HUMEUR_SERENITE", 0.80, -0.58, 0.64),

    # --- STRATE 4 : Éthique & moral (1.25 <= Ratio_Z < 1.60 — Haidt, 2003) ---
    ("indignation morale", "moral indignation", 4, "EMOTION_MORALE_CONDAMNATION", -0.72, 0.68, 0.54),
    ("réprobation", "moral reprobation", 4, "EMOTION_MORALE_CONDAMNATION", -0.68, 0.32, 0.46),
    ("opprobre", "opprobrium", 4, "SANCTION_MORALE", -0.82, 0.44, -0.38),
    ("ignominie", "ignominy", 4, "TRANSGRESSION_MORALE", -0.88, 0.42, -0.52),
    ("infamie", "infamy", 4, "TRANSGRESSION_MORALE", -0.86, 0.48, -0.46),
    ("turpitude", "moral turpitude", 4, "TRANSGRESSION_MORALE", -0.84, 0.36, -0.42),
    ("félonie", "felony betrayal", 4, "TRANSGRESSION_LOYAUTE", -0.86, 0.52, -0.28),
    ("parjure", "perjury", 4, "TRANSGRESSION_LOYAUTE", -0.82, 0.44, -0.34),
    ("apostasie", "apostasy", 4, "TRANSGRESSION_LOYAUTE", -0.54, 0.28, -0.18),
    ("fourberie", "deceitfulness", 4, "TRANSGRESSION_HONNETETE", -0.78, 0.38, 0.12),
    ("duplicité", "duplicity", 4, "TRANSGRESSION_HONNETETE", -0.76, 0.34, 0.08),
    ("imposture", "imposture", 4, "TRANSGRESSION_HONNETETE", -0.74, 0.42, -0.14),
    ("vénalité", "venality", 4, "TRANSGRESSION_INTEGRITE", -0.78, 0.28, -0.12),
    ("concussion", "malfeasance graft", 4, "TRANSGRESSION_INTEGRITE", -0.80, 0.36, 0.14),
    ("prévarication", "prevarication breach of duty", 4, "TRANSGRESSION_DEVOIR", -0.82, 0.34, 0.10),
    ("impénitence", "impenitence", 4, "TRANSGRESSION_MORALE", -0.68, 0.26, 0.24),
    ("contrition", "contrition", 4, "EMOTION_MORALE_CONSCIENCE", -0.58, -0.18, -0.44),
    ("compunction", "compunction", 4, "EMOTION_MORALE_CONSCIENCE", -0.54, -0.12, -0.38),
    ("repentance", "repentance", 4, "REPARATION_MORALE", 0.24, -0.14, -0.22),
    ("expiation", "atonement", 4, "REPARATION_MORALE", 0.18, 0.12, -0.16),
    ("rédemption", "redemption", 4, "REPARATION_MORALE", 0.78, 0.18, 0.42),
    ("absolution", "absolution", 4, "REPARATION_MORALE", 0.74, -0.22, 0.48),
    ("clémence", "clemency", 4, "VERTU_COMPASSION", 0.82, -0.28, 0.56),
    ("miséricorde", "mercy", 4, "VERTU_COMPASSION", 0.86, -0.18, 0.48),
    ("commisération", "commiseration", 4, "EMOTION_MORALE_SOUFFRANCE_AUTRUI", 0.32, -0.24, -0.12),
    ("abnégation morale", "self-abnegation", 4, "VERTU_DEVOUEMENT", 0.76, -0.26, 0.34),
    ("probité", "probity", 4, "VERTU_INTEGRITE", 0.86, -0.12, 0.64),
    ("droiture", "rectitude", 4, "VERTU_INTEGRITE", 0.84, -0.08, 0.66),
    ("rectitude", "moral uprightness", 4, "VERTU_INTEGRITE", 0.82, -0.14, 0.64),
    ("incorruptibilité", "incorruptibility", 4, "VERTU_INTEGRITE", 0.88, 0.12, 0.76),
    ("véracité", "veracity", 4, "VERTU_HONNETETE", 0.84, -0.06, 0.58),
    ("franc-parler", "candor", 4, "VERTU_HONNETETE", 0.72, 0.34, 0.62),
    ("loyauté", "loyalty", 4, "VERTU_LOYAUTE", 0.88, 0.16, 0.60),
    ("fidélité", "fidelity", 4, "VERTU_LOYAUTE", 0.86, -0.08, 0.54),
    ("piété filiale", "filial piety", 4, "VERTU_RESPECT", 0.74, -0.22, 0.32),
    ("déférence", "deference", 4, "VERTU_RESPECT", 0.56, -0.34, -0.18),
    ("exemplarité", "exemplarity", 4, "VERTU_ELEVATION", 0.86, 0.22, 0.68),
    ("élévation morale", "moral elevation", 4, "EMOTION_MORALE_ELEVATION", 0.90, 0.28, 0.62),
    ("magnanimité", "magnanimity", 4, "VERTU_GENEROSITE", 0.88, 0.14, 0.72),
    ("munificence", "munificence", 4, "VERTU_GENEROSITE", 0.80, 0.18, 0.64),
    ("charité", "charity", 4, "VERTU_COMPASSION", 0.84, -0.06, 0.44),
    ("philanthropie", "philanthropy", 4, "VERTU_BIENVEILLANCE", 0.86, 0.16, 0.58),
    ("scrupule", "moral scruple", 4, "CONSCIENCE_MORALE", 0.42, 0.18, 0.14),
    ("casuistique", "casuistry", 4, "DELIBERATION_MORALE", 0.12, -0.18, 0.28),
    ("déontologie", "deontology", 4, "DEVOIR_ETHIQUE", 0.76, -0.12, 0.64),
    ("imputabilité", "moral accountability", 4, "RESPONSABILITE_MORALE", 0.58, 0.14, 0.52),
    ("responsabilité morale", "moral responsibility", 4, "RESPONSABILITE_MORALE", 0.80, 0.16, 0.68),
    ("intégrité", "integrity", 4, "VERTU_INTEGRITE", 0.90, 0.08, 0.74),
    ("tempérance", "temperance", 4, "VERTU_CARDINALE", 0.78, -0.48, 0.56),
    ("prudence", "practical wisdom phronesis", 4, "VERTU_CARDINALE", 0.74, -0.36, 0.52),
    ("fortitude", "fortitude moral courage", 4, "VERTU_CARDINALE", 0.84, 0.44, 0.78),
    ("pudeur", "modesty pudor", 4, "EMOTION_MORALE_RETENUE", 0.62, -0.32, 0.18),
    ("décence", "decency", 4, "NORME_MORALE", 0.76, -0.24, 0.46),
    ("bienséance", "propriety", 4, "NORME_MORALE", 0.64, -0.28, 0.38),
    ("outrecuidance", "hubris arrogance", 4, "TRANSGRESSION_ORGUEIL", -0.68, 0.46, 0.38),
    ("hubris", "hubris", 4, "TRANSGRESSION_ORGUEIL", -0.64, 0.58, 0.52),
    ("ingratitude", "ingratitude", 4, "TRANSGRESSION_RECIPROCITE", -0.78, 0.22, -0.18),
    ("félon", "traitorous", 4, "TRANSGRESSION_LOYAUTE", -0.84, 0.48, -0.24),
    ("iniquité", "iniquity", 4, "TRANSGRESSION_JUSTICE", -0.88, 0.46, -0.44),
    ("mansuétude morale", "moral gentleness", 4, "VERTU_COMPASSION", 0.80, -0.26, 0.44),
    ("longanimité", "forbearance", 4, "VERTU_PATIENCE", 0.78, -0.32, 0.52),
    ("intégrisme", "fundamentalism", 4, "DERIVE_MORALE_DOGMATIQUE", -0.78, 0.48, 0.22),
    ("Tartuffe", "hypocrisy archetype", 4, "TRANSGRESSION_HONNETETE", -0.76, 0.28, 0.10),
    ("tartufferie", "sanctimonious hypocrisy", 4, "TRANSGRESSION_HONNETETE", -0.78, 0.32, 0.08),
    ("pharisianisme", "self-righteous hypocrisy", 4, "TRANSGRESSION_HONNETETE", -0.74, 0.24, 0.16),
    ("cynisme", "cynicism", 4, "TRANSGRESSION_MORALE", -0.68, 0.22, 0.32),
    ("machiavélisme", "machiavellianism", 4, "TRANSGRESSION_MORALE", -0.72, 0.36, 0.48),
    ("parricide", "parricide transgression", 4, "TRANSGRESSION_MAJEURE", -0.96, 0.78, -0.42),
    ("sacrilège", "sacrilege", 4, "TRANSGRESSION_SACRE", -0.76, 0.52, -0.18),
    ("profanation", "profanation", 4, "TRANSGRESSION_SACRE", -0.82, 0.54, -0.22),

    # --- STRATE 5 : Axiologique & Valeurs fondamentales (1.60 <= Ratio_Z < 2.00 — Schwartz, 2012) ---
    ("dignité humaine", "human dignity", 5, "VALEUR_UNIVERSALISME", 0.94, 0.12, 0.78),
    ("inaliénabilité", "inalienability", 5, "VALEUR_DROITS_FONDAMENTAUX", 0.86, 0.08, 0.74),
    ("inviolabilité", "inviolability", 5, "VALEUR_SACRALITE_PERSONNE", 0.84, 0.10, 0.72),
    ("équité", "equity", 5, "VALEUR_JUSTICE_AXIOLOGIQUE", 0.90, 0.06, 0.70),
    ("impartialité", "impartiality", 5, "VALEUR_JUSTICE_AXIOLOGIQUE", 0.84, -0.22, 0.68),
    ("universalité", "universality", 5, "VALEUR_UNIVERSALISME", 0.86, -0.08, 0.72),
    ("universalisme", "universalism", 5, "VALEUR_SCHWARTZ_UNIVERSALISME", 0.88, 0.04, 0.70),
    ("bienveillance axiologique", "benevolence value", 5, "VALEUR_SCHWARTZ_BIENVEILLANCE", 0.92, -0.04, 0.64),
    ("autodétermination", "self-direction", 5, "VALEUR_SCHWARTZ_AUTONOMIE", 0.88, 0.28, 0.82),
    ("autonomie intellectuelle", "intellectual autonomy", 5, "VALEUR_SCHWARTZ_AUTONOMIE", 0.86, 0.18, 0.78),
    ("libre arbitre", "free will", 5, "VALEUR_LIBERTE", 0.88, 0.22, 0.80),
    ("émancipation", "emancipation", 5, "VALEUR_LIBERTE", 0.90, 0.42, 0.82),
    ("affranchissement", "liberation", 5, "VALEUR_LIBERTE", 0.86, 0.38, 0.76),
    ("véridicité", "truthfulness", 5, "VALEUR_EPISTEMIQUE", 0.84, -0.10, 0.66),
    ("objectivité", "objectivity", 5, "VALEUR_EPISTEMIQUE", 0.78, -0.28, 0.64),
    ("rationalité", "rationality", 5, "VALEUR_EPISTEMIQUE", 0.80, -0.24, 0.70),
    ("lucidité", "lucidity", 5, "VALEUR_EPISTEMIQUE", 0.84, 0.04, 0.72),
    ("clairvoyance", "clairvoyance insight", 5, "VALEUR_EPISTEMIQUE", 0.86, 0.08, 0.74),
    ("sagacité", "sagacity", 5, "VALEUR_SAGESSE", 0.84, 0.06, 0.70),
    ("sapience", "sapience wisdom", 5, "VALEUR_SAGESSE", 0.86, -0.22, 0.72),
    ("érudition", "erudition", 5, "VALEUR_CONNAISSANCE", 0.80, -0.14, 0.66),
    ("épistémè", "epistemic truth", 5, "VALEUR_CONNAISSANCE", 0.78, -0.18, 0.64),
    ("authenticité", "authenticity", 5, "VALEUR_EXISTENTIELLE", 0.90, 0.08, 0.74),
    ("altérité", "alterity respect for otherness", 5, "VALEUR_UNIVERSALISME", 0.84, -0.06, 0.58),
    ("réciprocité", "reciprocity", 5, "VALEUR_EQUITE", 0.86, 0.04, 0.64),
    ("proportionnalité", "proportionality", 5, "VALEUR_JUSTICE_AXIOLOGIQUE", 0.78, -0.18, 0.62),
    ("perfectibilité", "perfectibility", 5, "VALEUR_PROGRES", 0.82, 0.16, 0.66),
    ("exemplarité axiologique", "axiological ideal", 5, "VALEUR_EXCELLENCE", 0.86, 0.14, 0.70),
    ("sublimité", "sublimity", 5, "VALEUR_ESTHETIQUE_TRANSCENDANTE", 0.92, 0.24, 0.68),
    ("harmonie cosmique", "harmony with nature", 5, "VALEUR_SCHWARTZ_UNIVERSALISME", 0.90, -0.32, 0.62),
    ("sobriété", "ethical sobriety", 5, "VALEUR_MODERATION", 0.76, -0.44, 0.58),
    ("frugalité", "frugality", 5, "VALEUR_MODERATION", 0.68, -0.42, 0.52),
    ("pérennité", "sustainability", 5, "VALEUR_TRANSMISSION", 0.82, -0.22, 0.64),
    ("patrimonialité", "heritage stewardship", 5, "VALEUR_TRADITION", 0.74, -0.20, 0.56),
    ("sacralité", "sacredness", 5, "VALEUR_TRANSCENDANCE", 0.84, -0.12, 0.60),
    ("incommensurabilité", "incommensurability of person", 5, "VALEUR_DIGNITE", 0.76, -0.16, 0.58),
    ("nihilisme", "nihilism", 5, "ANTI_VALEUR_AXIOLOGIQUE", -0.78, -0.22, -0.46),
    ("relativisme cynique", "cynical relativism", 5, "ANTI_VALEUR_AXIOLOGIQUE", -0.68, -0.10, -0.22),
    ("utilitarisme réducteur", "reductive instrumentalization", 5, "ANTI_VALEUR_AXIOLOGIQUE", -0.64, -0.08, 0.14),
    ("réification", "reification objectification", 5, "ANTI_VALEUR_DIGNITE", -0.82, -0.04, -0.48),
    ("aliénation", "alienation", 5, "ANTI_VALEUR_AUTONOMIE", -0.86, -0.18, -0.74),
    ("asservissement", "subjugation", 5, "ANTI_VALEUR_LIBERTE", -0.92, 0.28, -0.84),
    ("obscurantisme", "obscurantism", 5, "ANTI_VALEUR_EPISTEMIQUE", -0.86, 0.18, -0.42),
    ("dogmatisme", "dogmatism", 5, "ANTI_VALEUR_EPISTEMIQUE", -0.72, 0.24, 0.28),
    ("fanatisme", "fanaticism", 5, "ANTI_VALEUR_TOLERANCE", -0.88, 0.74, 0.36),
    ("intolérance", "intolerance", 5, "ANTI_VALEUR_TOLERANCE", -0.84, 0.48, 0.18),
    ("sectarisme", "sectarianism", 5, "ANTI_VALEUR_UNIVERSALISME", -0.80, 0.38, 0.12),
    ("chauvinisme", "chauvinism", 5, "ANTI_VALEUR_UNIVERSALISME", -0.72, 0.42, 0.24),
    ("xénophobie", "xenophobia", 5, "ANTI_VALEUR_UNIVERSALISME", -0.88, 0.52, -0.16),
    ("ostracisme", "ostracism", 5, "ANTI_VALEUR_INCLUSION", -0.82, 0.22, -0.44),
    ("eudémonisme", "eudaimonism", 5, "VALEUR_PHILOSOPHIQUE", 0.88, -0.12, 0.70),
    ("stoïcisme", "stoicism", 5, "VALEUR_MAITRISE_AXIOLOGIQUE", 0.76, -0.54, 0.74),
    ("humanisme", "humanism", 5, "VALEUR_UNIVERSALISME", 0.92, 0.08, 0.74),
    ("rationalisme", "rationalism", 5, "VALEUR_EPISTEMIQUE", 0.78, -0.22, 0.68),
    ("faillibilisme", "fallibilism epistemic humility", 5, "VALEUR_EPISTEMIQUE", 0.74, -0.26, 0.56),
    ("pluralisme axiologique", "value pluralism", 5, "VALEUR_UNIVERSALISME", 0.86, 0.04, 0.68),
    ("inconditionnalité", "unconditionality", 5, "VALEUR_DEONTOLOGIQUE", 0.82, 0.06, 0.66),
    ("imprescriptibilité", "imprescriptibility", 5, "VALEUR_DROITS_FONDAMENTAUX", 0.86, 0.04, 0.74),
    ("transcendance", "transcendence", 5, "VALEUR_TRANSCENDANCE", 0.88, 0.14, 0.70),
    ("immanence", "immanence", 5, "VALEUR_PHILOSOPHIQUE", 0.72, -0.18, 0.58),

    # --- STRATE 6 : Politique, civique & social (Ratio_Z >= 2.00) ---
    ("citoyenneté", "citizenship", 6, "POLITIQUE_CITOYENNETE", 0.88, 0.14, 0.76),
    ("civisme", "civic-mindedness", 6, "POLITIQUE_CITOYENNETE", 0.86, 0.08, 0.70),
    ("républicanisme", "republicanism", 6, "POLITIQUE_REGIME", 0.84, 0.12, 0.74),
    ("démocratie délibérative", "deliberative democracy", 6, "POLITIQUE_DEMOCRATIE", 0.90, 0.10, 0.78),
    ("souveraineté populaire", "popular sovereignty", 6, "POLITIQUE_SOUVERAINETE", 0.88, 0.24, 0.84),
    ("suffrage universel", "universal suffrage", 6, "POLITIQUE_DEMOCRATIE", 0.90, 0.16, 0.80),
    ("contrat social", "social contract", 6, "POLITIQUE_FONDEMENT", 0.88, -0.06, 0.76),
    ("état de droit", "rule of law", 6, "POLITIQUE_INSTITUTIONS", 0.90, -0.12, 0.82),
    ("constitutionnalité", "constitutionality", 6, "POLITIQUE_INSTITUTIONS", 0.84, -0.18, 0.76),
    ("séparation des pouvoirs", "separation of powers", 6, "POLITIQUE_INSTITUTIONS", 0.86, -0.16, 0.78),
    ("parlementarisme", "parliamentarism", 6, "POLITIQUE_INSTITUTIONS", 0.76, -0.10, 0.68),
    ("pluralisme politique", "political pluralism", 6, "POLITIQUE_DEMOCRATIE", 0.88, 0.08, 0.74),
    ("laïcité", "secularism laicite", 6, "POLITIQUE_PRINCIPES_REPUBLICAINS", 0.84, -0.08, 0.72),
    ("isonomie", "equality before the law", 6, "POLITIQUE_JUSTICE_SOCIALE", 0.88, -0.10, 0.76),
    ("justice distributive", "distributive justice", 6, "POLITIQUE_JUSTICE_SOCIALE", 0.88, 0.06, 0.74),
    ("justice réparatrice", "restorative justice", 6, "POLITIQUE_JUSTICE_SOCIALE", 0.86, 0.04, 0.70),
    ("justice sociale", "social justice", 6, "POLITIQUE_JUSTICE_SOCIALE", 0.92, 0.22, 0.78),
    ("solidarité civique", "civic solidarity", 6, "POLITIQUE_COHESION", 0.90, 0.18, 0.74),
    ("fraternité républicaine", "republican fraternity", 6, "POLITIQUE_PRINCIPES_REPUBLICAINS", 0.92, 0.16, 0.74),
    ("cohésion sociale", "social cohesion", 6, "POLITIQUE_COHESION", 0.86, -0.08, 0.70),
    ("concorde civile", "civil concord", 6, "POLITIQUE_PAIX_CIVILE", 0.90, -0.22, 0.74),
    ("paix perpétuelle", "perpetual peace", 6, "POLITIQUE_COSMOPOLITISME", 0.94, -0.28, 0.76),
    ("cosmopolitisme", "cosmopolitanism", 6, "POLITIQUE_COSMOPOLITISME", 0.84, 0.08, 0.68),
    ("multilatéralisme", "multilateralism", 6, "POLITIQUE_DIPLOMATIE", 0.80, -0.12, 0.68),
    ("diplomatie", "diplomacy", 6, "POLITIQUE_DIPLOMATIE", 0.82, -0.16, 0.72),
    ("gouvernance", "governance", 6, "POLITIQUE_GOUVERNANCE", 0.74, -0.08, 0.74),
    ("subsidiarité", "subsidiarity", 6, "POLITIQUE_GOUVERNANCE", 0.76, -0.18, 0.68),
    ("décentralisation", "decentralization", 6, "POLITIQUE_GOUVERNANCE", 0.72, -0.10, 0.66),
    ("fédéralisme", "federalism", 6, "POLITIQUE_GOUVERNANCE", 0.74, -0.08, 0.68),
    ("intérêt général", "common good public interest", 6, "POLITIQUE_BIEN_COMMUN", 0.90, -0.04, 0.76),
    ("bien commun", "commonwealth common good", 6, "POLITIQUE_BIEN_COMMUN", 0.92, -0.06, 0.76),
    ("service public", "public service", 6, "POLITIQUE_INSTITUTIONS", 0.82, -0.08, 0.66),
    ("redevabilité publique", "public accountability", 6, "POLITIQUE_ETHIQUE_PUBLIQUE", 0.84, 0.06, 0.70),
    ("transparence démocratique", "democratic transparency", 6, "POLITIQUE_ETHIQUE_PUBLIQUE", 0.88, 0.04, 0.74),
    ("légitimité démocratique", "democratic legitimacy", 6, "POLITIQUE_LEGITIMITE", 0.88, 0.06, 0.78),
    ("légalité", "legality", 6, "POLITIQUE_DROIT", 0.80, -0.18, 0.70),
    ("jurisprudence", "jurisprudence", 6, "POLITIQUE_DROIT", 0.74, -0.24, 0.66),
    ("magistrature", "magistracy", 6, "POLITIQUE_INSTITUTIONS", 0.72, -0.16, 0.70),
    ("droits humains", "human rights", 6, "POLITIQUE_DROITS_HUMAINS", 0.94, 0.18, 0.82),
    ("libertés publiques", "civil liberties", 6, "POLITIQUE_DROITS_HUMAINS", 0.92, 0.20, 0.80),
    ("droit d'asile", "right of asylum", 6, "POLITIQUE_DROITS_HUMAINS", 0.84, 0.08, 0.64),
    ("habeas corpus", "habeas corpus", 6, "POLITIQUE_DROITS_HUMAINS", 0.86, -0.08, 0.76),
    ("syndicalisme", "trade unionism", 6, "POLITIQUE_MOUVEMENT_SOCIAL", 0.72, 0.34, 0.66),
    ("militantisme", "activism", 6, "POLITIQUE_ENGAGEMENT", 0.70, 0.56, 0.68),
    ("engagement civique", "civic engagement", 6, "POLITIQUE_ENGAGEMENT", 0.88, 0.28, 0.76),
    ("désobéissance civile", "civil disobedience", 6, "POLITIQUE_RESISTANCE", 0.64, 0.48, 0.66),
    ("dissidence", "dissidence", 6, "POLITIQUE_RESISTANCE", 0.58, 0.44, 0.58),
    ("insurrection", "insurrection", 6, "POLITIQUE_CONFLIT", -0.28, 0.82, 0.52),
    ("sédition", "sedition", 6, "POLITIQUE_CONFLIT", -0.58, 0.68, 0.32),
    ("totalitarisme", "totalitarianism", 6, "POLITIQUE_PATHOLOGIE_POUVOIR", -0.94, 0.48, -0.78),
    ("autoritarisme", "authoritarianism", 6, "POLITIQUE_PATHOLOGIE_POUVOIR", -0.88, 0.42, -0.62),
    ("despotisme", "despotism", 6, "POLITIQUE_PATHOLOGIE_POUVOIR", -0.92, 0.46, -0.72),
    ("autocratie", "autocracy", 6, "POLITIQUE_PATHOLOGIE_POUVOIR", -0.86, 0.36, -0.58),
    ("ploutocratie", "plutocracy", 6, "POLITIQUE_PATHOLOGIE_POUVOIR", -0.82, 0.24, -0.46),
    ("oligarchie", "oligarchy", 6, "POLITIQUE_PATHOLOGIE_POUVOIR", -0.78, 0.20, -0.42),
    ("kleptocratie", "kleptocracy", 6, "POLITIQUE_CORRUPTION", -0.90, 0.34, -0.56),
    ("népotisme", "nepotism", 6, "POLITIQUE_CORRUPTION", -0.84, 0.26, -0.38),
    ("clientélisme", "clientelism", 6, "POLITIQUE_CORRUPTION", -0.80, 0.22, -0.34),
    ("démagogie", "demagogy", 6, "POLITIQUE_PATHOLOGIE_DISCOURS", -0.84, 0.52, -0.28),
    ("populisme", "populism", 6, "POLITIQUE_IDEOLOGIE", -0.62, 0.48, -0.14),
    ("impérialisme", "imperialism", 6, "POLITIQUE_DOMINATION", -0.86, 0.54, 0.24),
    ("colonialisme", "colonialism", 6, "POLITIQUE_DOMINATION", -0.90, 0.48, -0.48),
    ("hégémonie", "hegemony", 6, "POLITIQUE_DOMINATION", -0.48, 0.38, 0.56),
    ("oppression systémique", "systemic oppression", 6, "POLITIQUE_INJUSTICE", -0.92, 0.44, -0.78),
    ("ségrégation", "segregation", 6, "POLITIQUE_INJUSTICE", -0.92, 0.42, -0.72),
    ("apartheid", "apartheid", 6, "POLITIQUE_INJUSTICE", -0.96, 0.52, -0.80),
    ("anomie sociale", "social anomie", 6, "POLITIQUE_DESINTEGRATION", -0.82, -0.24, -0.68),
    ("paupérisation", "pauperization", 6, "POLITIQUE_ECONOMIE_SOCIALE", -0.86, -0.18, -0.74),
    ("précarité sociale", "social precarity", 6, "POLITIQUE_ECONOMIE_SOCIALE", -0.84, 0.16, -0.76),
    ("justice climatique", "climate justice", 6, "POLITIQUE_ECOLOGIE_CIVIQUE", 0.88, 0.26, 0.72),
    ("autogestion", "workers self-management", 6, "POLITIQUE_GOUVERNANCE", 0.78, 0.24, 0.74),
    ("collégialité", "collegiality", 6, "POLITIQUE_GOUVERNANCE", 0.82, -0.06, 0.68),
    ("bicamérisme", "bicameralism", 6, "POLITIQUE_INSTITUTIONS", 0.68, -0.18, 0.62),
    ("référendum", "referendum", 6, "POLITIQUE_DEMOCRATIE", 0.76, 0.22, 0.72),
    ("plébiscite", "plebiscite", 6, "POLITIQUE_DEMOCRATIE", 0.54, 0.28, 0.56),
    ("ostracisation", "political ostracization", 6, "POLITIQUE_EXCLUSION", -0.84, 0.28, -0.52),
    ("bannissement", "banishment", 6, "POLITIQUE_EXCLUSION", -0.86, 0.34, -0.64),
    ("apatridie", "statelessness", 6, "POLITIQUE_DROITS_HUMAINS", -0.88, -0.14, -0.82),
    ("irredentisme", "irredentism", 6, "POLITIQUE_GEOPOLITIQUE", -0.58, 0.46, 0.22),
    ("souverainisme", "sovereignism", 6, "POLITIQUE_IDEOLOGIE", 0.42, 0.24, 0.64),
]


# ==============================================================================
# 3. ANALYSEUR MORPHO-SYNTAXIQUE & SÉMANTIQUE OPEN-DATA (CNRS / LEXIQUE 3.83 / GLAWI)
# ==============================================================================

def infer_cnrs_lexique_glawi_pos_and_domain(
    lemme_fr: str,
    term_en: str,
    stratum: SemanticDomainStratum,
    dima_pos: str = "-",
    source_nomenclature: str = "",
    is_certified_fr_lemma: bool = False,
) -> Tuple[str, str, str, int]:
    """
    Analyse morpho-syntaxique et sémantique selon les conventions de :
    - Lexique 3.83 (New et al., 2004 : NOM, ADJ, VER, ADV)
    - GLAWI (Sajous & Hathout, CLLE-ERSS CNRS : étiquettes morphosyntaxiques & marqueurs de domaines)
    - Morphalou 3.1 (ATILF CNRS)

    Retourne :
        (pos_cnrs_lexique, glawi_domaine_cnrs, open_data_badge, est_lemme_fr_certifie)
    """
    w = lemme_fr.strip()
    w_low = w.lower()

    # 1. Détermination si le lemme est un terme français certifié (ou locution française)
    has_french_chars = any(c in w_low for c in "éèêëàâîïôùûüçœæ")
    is_from_fr_corpus = source_nomenclature in {
        "DIMA_AXIOLOGIE_OUVERTE_FR",
        "LEXIQUE383_MORPHALOU_OPEN_FR",
        "CNRS_GLAWI_LEXIQUE_DIMA_AFFECT",
    }
    is_translated = (w_low != term_en.strip().lower())
    is_shared_cognate = w_low.endswith((
        "tion", "sion", "isme", "iste", "ance", "ence", "itude", "able", "ible",
        "ique", "al", "el", "if", "ive", "eur", "euse", "ent", "ant",
    ))
    est_fr = 1 if (is_certified_fr_lemma or is_from_fr_corpus or has_french_chars or is_translated or is_shared_cognate) else 0

    # 2. Catégorie morpho-syntaxique (POS : NOM, ADJ, VER, ADV, LOC)
    d_pos = str(dima_pos).strip().upper()
    if " " in w_low or "-" in w_low and len(w_low) > 14:
        pos = "LOC"
    elif d_pos in {"NOM", "N"}:
        pos = "NOM"
    elif d_pos in {"ADJ", "A"}:
        pos = "ADJ"
    elif d_pos in {"VERB", "VER", "V"}:
        pos = "VER"
    elif d_pos in {"ADVERB", "ADV"}:
        pos = "ADV"
    elif w_low.endswith("ment") and not w_low.endswith((
        "sentiment", "entendement", "discernement", "emportement", "accablement",
        "ahurissement", "affolement", "enchantement", "éblouissement", "effarement",
        "désenchantement", "éloignement", "affranchissement", "asservissement",
        "bannissement", "fourmillement", "étourdissement", "endolorissement",
        "assoupissement", "frémissement", "tressaillement", "châtiment", "jugement",
        "accomplissement", "consentement", "ravissement", "abaissement", "abattement",
        "soulagement", "émerveillement", "saisissement", "attachement", "ressentiment",
        "dévouement", "engagement", "gouvernement", "parlement", "amendement",
    )):
        pos = "ADV"
    elif w_low.endswith(("er", "ir", "re", "oir")) and len(w_low) > 4 and not w_low.endswith((
        "espoir", "désespoir", "devoir", "pouvoir", "savoir", "vouloir", "plaisir",
        "déplaisir", "souvenir", "avenir", "repentir", "loisir", "soupir", "désir",
        "martyr", "élixir", "zéphyr", "danger", "étranger", "passager", "mensonger",
        "léger", "amer", "fier", "altier", "entier", "singulier", "particulier",
        "régulier", "séculier", "familier", "hospitalier", "chevalier", "guerrier",
        "ouvrier", "prisonnier", "pionnier", "héritier", "usurier", "meurtrier",
        "colère", "misère", "chimère", "ulcère", "caractère", "mystère", "austère",
        "sincère", "sévère", "éphémère", "adultère", " délire", "sourire", "rire",
        "empire", "pire", "martyre", "satire", "navire", "cire", "ire", "gloire",
        "mémoire", "victoire", "histoire", "territoire", "purgatoire", "observatoire",
        "obligatoire", "contradictoire", "illusoire", "dérisoire", "provisoire",
        "aléatoire", "expiatoire", "diffamatoire", "discriminatoire",
    )):
        pos = "VER"
    elif w_low.endswith((
        "eux", "euse", "if", "ive", "able", "ible", "ique", "el", "elle",
        "al", "ale", "aux", "ent", "ente", "ant", "ante", "é", "ée", "i", "ie", "u", "ue",
        "iste", "ien", "ienne", "ard", "arde", "aud", "aude", "ois", "oise",
    )) and not w_low.endswith((
        "pitié", "amitié", "inimitié", "moitié", "chasteté", "pauvreté", "cruauté",
        "loyauté", "royauté", "beauté", "nouveauté", "primauté", "communauté",
        "souveraineté", "citoyenneté", "fraternité", "égalité", "liberté", "équité",
        "dignité", "probité", "intégrité", "vérité", "charité", "solidarité",
        "humanité", "laïcité", "légalité", "légitimité", "responsabilité", "culpabilité",
        "impartialité", "universalité", "objectivité", "rationalité", "lucidité",
        "authenticité", "altérité", "réciprocité", "sobriété", "frugalité", "pérennité",
        "sacralité", "vénalité", "duplicité", "férocité", "atrocité", "perversité",
        "adversité", "diversité", "intensité", "immensité", "curiosité", "générosité",
        "animosité", "morosité", "virtuosité", "monstruosité", "religiosité",
        "angoisse", "tristesse", "tendresse", "allégresse", "liesse", "ivresse",
        " détresse", "faiblesse", "bassesse", "noblesse", "sagesse", "finesse",
        "délicatesse", "politesse", "justesse", "hardiesse", "paresse", "mollesse",
        "rudesse", "vieillesse", "jeunesse", "richesse", "promesse", "caresse",
        "idéologie", "démocratie", "autocratie", "oligarchie", "ploutocratie",
        "kleptocratie", "démagogie", "hégémonie", "anomie", "autonomie", "isonomie",
        "économi", "harmonie", "ironie", "agonie", "ignominie", "infamie", "félonie",
        "apostasie", "hypocrisie", "jalousie", "envie", "folie", "mélancolie",
        "nostalgie", "euphorie", "apathie", "empathie", "sympathie", "antipathie",
        "tachycardie", "bradycardie", "catalepsie", "léthargie", "asthénie",
        "lipothymie", "endorphinie", "spasmophilie", "paresthésie", "algie",
        "philanthropie", "misanthropie", "xénophobie", "modestie", "inertie",
        "diplomatie", "suprématie", "théocratie", "bureaucratie", "méritocratie",
        "aristocratie", "tyrannie", "barbarie", "fourberie", "tartufferie",
        "veulerie", "flagornerie", "mesquinerie", "coquetterie", "galanterie",
        "camaraderie", "fraternrie", "chevalerie", "sorcellerie", "raillerie",
        "moquerie", "bouffonnerie", "fanfaronnade", "bravade", "embuscade",
        "vertu", "tribu", "individu", "absolu", "malentendu", "inconnu", "imprévu",
    )):
        pos = "ADJ"
    else:
        pos = "NOM"

    # 3. Domaine GLAWI / CNRS ATILF
    glawi_domain = STRATUM_METADATA[stratum]["glawi_domain"]

    # 4. Badge Open-Data synthétique
    if "DIMA" in source_nomenclature and "NRC" in source_nomenclature:
        badge = "CNRS-GLAWI+Lexique3.83+NRC+DIMA"
    elif "DIMA" in source_nomenclature:
        badge = "CNRS-GLAWI+Lexique3.83+Morphalou+DIMA"
    elif "LEXIQUE383" in source_nomenclature:
        badge = "CNRS-GLAWI+Lexique3.83+Morphalou-ATILF"
    else:
        badge = "CNRS-GLAWI+Lexique3.83+NRC"

    return pos, glawi_domain, badge, est_fr


# ==============================================================================
# 4. CLASSIFIEUR MULTI-STRATES ET PROJECTEUR SUR L'ENVELOPPE OCTAÉDRIQUE L1
# ==============================================================================

_POLITICAL_CIVIC_KEYWORDS = {
    "citoyen", "civique", "civism", "démocrat", "républi", "souverain", "suffrage",
    "constitution", "parlement", "gouvern", "législat", "juridique", "juridiction",
    "magistrat", "tribunal", "état de droit", "laïc", "fédéral", "diplomat",
    "multilatéral", "cosmopolit", "syndic", "militant", "insurrection", "sédition",
    "totalitar", "autoritar", "despot", "tyran", "autocrat", "oligarch", "ploutocrat",
    "kleptocrat", "népotism", "clientélism", "démagog", "impérialism", "colonial",
    "hégémon", "apartheid", "ségrégation", "anomie", "politique", "idéologi",
    "électoral", "plébiscit", "référendum", "décret", "amendement", "sénat",
    "minist", "ambassad", "géopolitique", "traité", "coalition", "bipartite",
    "manifestation", "grève", "prolétar", "bourgeois", "capitalism", "socialism",
    "communism", "libéralism", "anarchism", "fascism", "nationalism", "patriot",
    "allégeance", "émancipation civique", "droits humains", "contrat social",
    "intérêt général", "bien commun", "service public", "subversion", "putsch",
    "coup d'état", "révolution", "opprim", "oppression", "dictat", "censure",
    "autogestion", "collégialité", "bicamérisme", "apatridie", "bannissement",
}

_AXIOLOGICAL_VALUES_KEYWORDS = {
    "dignité", "équité", "impartial", "universal", "autodétermination", "autonomie",
    "liberté", "libre arbitre", "émancipation", "affranchissement", "vérité",
    "véridicité", "objectivité", "rationalité", "lucidité", "clairvoyance",
    "sagesse", "sagacité", "sapience", "érudition", "épistém", "authenticité",
    "altérité", "réciprocité", "proportionnalité", "perfectibilité", "sublim",
    "harmonie", "sobriété", "frugalité", "pérennité", "sacré", "sacralité",
    "transcendan", "nihilism", "relativism", "réification", "aliénation",
    "asservissement", "obscurantism", "dogmatism", "fanatism", "intoléran",
    "sectarism", "chauvinism", "xénophob", "ostracism", "valeur", "axiolog",
    "principe", "idéal", "absolu", "éternel", "inviolab", "inaliénab", "honneur",
    "excellence", "perfection", "beauté", "esthétique", "humanisme", "tolérance",
    "pluralisme", "paix", "justice", "eudémonisme", "stoïcisme", "rationalisme",
    "imprescriptibilité", "inconditionnalité",
}

_ETHICAL_MORAL_KEYWORDS = {
    "culpabilité", "coupable", "honte", "honteux", "remords", "repent", "contrition",
    "expiation", "rédemption", "absolution", "pardon", "clémence", "miséricorde",
    "compassion", "pitié", "commisération", "indignation", "réprobation", "opprobre",
    "ignominie", "infamie", "turpitude", "félon", "parjure", "trahison", "traître",
    "fourb", "duplicité", "hypocri", "imposture", "mensonge", "menteur", "vénal",
    "corrupt", "prévarication", "probité", "droiture", "rectitude", "incorrupt",
    "véracité", "honnête", "loyauté", "loyal", "fidèle", "fidélité", "déférence",
    "respect", "admiration", "gratitude", "reconnaissance", "magnanim", "générosité",
    "généreux", "charité", "philanthrop", "altruis", "abnégation", "dévouement",
    "scrupule", "conscience", "déontolog", "éthique", "moral", "vertu", "vice",
    "péché", "faute", "transgress", "devoir", "obligation", "responsabilité",
    "imputab", "intégrité", "tempérance", "prudence", "fortitude", "pudeur",
    "décence", "bienséance", "hubris", "orgueil", "arrogance", "ingrat", "iniquité",
    "mépris", "blâme", "éloge", "mérite", "démérite", "châtiment", "punition",
    "sanction", "innocen", "pureté", "impureté", "souillure", "profanation",
    "sacrilège", "machiavélisme", "cynisme", "tartuff", "longanimité",
}

_SOMATIC_AFFECTIVE_KEYWORDS = {
    "faim", "soif", "douleur", "souffrance physique", "spasme", "frisson", "sursaut",
    "nausée", "vomir", "écœur", "vertige", "étourdissement", "tachycard", "palpitat",
    "sueur", "transpir", "trembl", "frémis", "tressaill", "crisp", "suffoc",
    "asphyx", "halet", "essouffl", "fatigue", "épuis", "létharg", "torpeur",
    "somnolen", "insomni", "orgasm", "volupté", "jouissance", "excit", "pulsion",
    "instinct", "réflexe", "viscér", "somatique", "corporel", "chair", "sang",
    "nerf", "nerveux", "agonie", "convuls", "tétani", "paralys", "sidérat",
    "choc", "satiété", "détente musculaire", "relâchement", "chatouill", "démange",
    "prurit", "brûlure", "crampe", "courbature", "fièvre", "frissonner", "dyspnée",
    "apnée", "sudation", "algie", "fourbu", "éreinté", "harassé", "assoupissement",
}


def compute_calibrated_stratum_and_ratio_z(
    lemme_fr: str,
    term_en: str,
    valence: float,
    arousal: float,
    dominance: float,
    score_norms_base: float,
    score_reg_base: float,
    score_bod_base: float,
    score_mot_base: float,
    dima_categ: str,
    dima_classe: str,
    domaine_valeur: str = "-",
    explicit_stratum_hint: Optional[int] = None,
) -> Tuple[SemanticDomainStratum, float, float, float, float, float]:
    """
    Calibre les sous-scores componantiels CPM (`Score_Appraisal_Norms`,
    `Score_Subjective_Regulation`, `Score_Bodily_Symptoms`, `Score_Motor_Expression`)
    et le `Ratio_Z` exact pour refléter fidèlement la position du lemme dans l'une
    des 6 strates sémantiques verticales de l'expérience humaine.
    """
    text_low = f"{lemme_fr} {term_en} {dima_classe} {domaine_valeur}".lower()

    target_stratum_idx: int
    if explicit_stratum_hint is not None and 1 <= explicit_stratum_hint <= 6:
        target_stratum_idx = explicit_stratum_hint
    elif any(kw in text_low for kw in _POLITICAL_CIVIC_KEYWORDS) or "CIVIQUE" in domaine_valeur or "POLITIQUE" in domaine_valeur or "IDEOLOGIQUE" in domaine_valeur:
        target_stratum_idx = 6
    elif any(kw in text_low for kw in _AXIOLOGICAL_VALUES_KEYWORDS) or "EPISTEMIQUE" in domaine_valeur or "ESTHETIQUE" in domaine_valeur or "VALEUR_EXCELLENCE" in domaine_valeur or "TRANSCENDAN" in domaine_valeur:
        target_stratum_idx = 5
    elif any(kw in text_low for kw in _ETHICAL_MORAL_KEYWORDS) or "MORALE" in domaine_valeur or dima_classe in {
        "Honte", "Honte de soi", "Mauvaise conscience", "Bonne conscience",
        "Mépris", "Admiration", "Estime", "Estime respect", "Gratitude", "Orgueil",
    }:
        target_stratum_idx = 4
    elif any(kw in text_low for kw in _SOMATIC_AFFECTIVE_KEYWORDS):
        target_stratum_idx = 1
    else:
        somatic_drive = 0.55 * max(0.0, arousal) + 0.30 * (1.0 - abs(dominance)) + (0.15 if dima_categ == "I" else 0.0)
        cognitive_drive = 0.45 * score_norms_base + 0.45 * score_reg_base + 0.20 * max(0.0, dominance) - 0.25 * max(0.0, arousal)

        if arousal >= 0.62 and somatic_drive >= 0.52 and cognitive_drive < 0.62:
            target_stratum_idx = 1
        elif arousal >= 0.22 or dima_categ == "I":
            if cognitive_drive < 0.68:
                target_stratum_idx = 2
            else:
                target_stratum_idx = 3
        else:
            if cognitive_drive < 0.66 or dima_categ == "II":
                target_stratum_idx = 3
            elif cognitive_drive < 0.74:
                target_stratum_idx = 4
            elif cognitive_drive < 0.80:
                target_stratum_idx = 5
            else:
                target_stratum_idx = 6

    bounds_map: Dict[int, Tuple[float, float, SemanticDomainStratum]] = {
        1: (0.34, 0.635, SemanticDomainStratum.STRATUM_1_AFFECTIVE_SOMATIC),
        2: (0.66, 0.935, SemanticDomainStratum.STRATUM_2_EMOTIONAL_EPISODIC),
        3: (0.96, 1.235, SemanticDomainStratum.STRATUM_3_SENTIMENTAL_RELATIONAL),
        4: (1.26, 1.585, SemanticDomainStratum.STRATUM_4_ETHICAL_MORAL),
        5: (1.61, 1.985, SemanticDomainStratum.STRATUM_5_AXIOLOGICAL_VALUES),
        6: (2.02, 2.750, SemanticDomainStratum.STRATUM_6_POLITICAL_CIVIC),
    }
    r_min, r_max, stratum_enum = bounds_map[target_stratum_idx]

    base_ratio = (score_norms_base + score_reg_base) / max(1e-6, score_bod_base + score_mot_base)
    sig_pos = 1.0 / (1.0 + np.exp(-1.8 * (base_ratio - 1.45) - 0.55 * dominance + 0.45 * arousal))
    target_ratio = float(r_min + (r_max - r_min) * np.clip(sig_pos, 0.05, 0.95))

    som_scale = {
        1: 1.45,
        2: 1.22,
        3: 1.00,
        4: 0.84,
        5: 0.72,
        6: 0.62,
    }[target_stratum_idx]
    bodily_new = float(np.clip(score_bod_base * som_scale, 0.12, 0.94))
    motor_new = float(np.clip(score_mot_base * som_scale, 0.12, 0.94))
    den_new = bodily_new + motor_new

    num_target = target_ratio * den_new
    norms_share = float(score_norms_base / max(1e-6, score_norms_base + score_reg_base))
    norms_share = float(np.clip(norms_share, 0.42, 0.58))
    norms_new = float(round(num_target * norms_share, 4))
    reg_new = float(round(num_target * (1.0 - norms_share), 4))
    bodily_new = float(round(bodily_new, 4))
    motor_new = float(round(motor_new, 4))

    ratio_exact = float(round((norms_new + reg_new) / max(1e-6, bodily_new + motor_new), 4))
    if ratio_exact < r_min or ratio_exact > r_max:
        ratio_exact = float(round(0.5 * (r_min + r_max), 4))

    return stratum_enum, ratio_exact, norms_new, reg_new, bodily_new, motor_new


def classify_octant(valence: float, coping_power: float, arousal: float) -> Tuple[str, str]:
    """
    Détermine l'octant tridimensionnel (Valence x Coping Agi/Réflexif x Énergie/Arousal).
    """
    if abs(valence) < 1e-6 and abs(coping_power) < 1e-6 and abs(arousal) < 1e-6:
        return "OCT_0_ORIGIN", "Neutre / Origine (V0, C0, E0)"

    v_sign = "V+" if valence >= 0.0 else "V-"
    c_sign = "C+" if coping_power >= 0.0 else "C-"
    e_sign = "E+" if arousal >= 0.0 else "E-"
    code = f"{v_sign}_{c_sign}_{e_sign}"

    descriptions = {
        "V+_C+_E+": "Octant I (V+ Agi Énergique : Joie, Fierté, Enthousiasme, Émancipation)",
        "V+_C+_E-": "Octant II (V+ Agi Apaisé : Satisfaction, Sérénité, Équité, Sagesse)",
        "V+_C-_E+": "Octant III (V+ Réflexif Énergique : Émerveillement, Surprise positive, Fascination)",
        "V+_C-_E-": "Octant IV (V+ Réflexif Apaisé : Tendresse, Soulagement, Quiétude, Mansuétude)",
        "V-_C+_E+": "Octant V (V- Agi Énergique : Colère, Indignation, Révolte, Insurrection)",
        "V-_C+_E-": "Octant VI (V- Agi Froid : Mépris, Dédain, Hégémonie, Autoritarisme)",
        "V-_C-_E+": "Octant VII (V- Subi/Réflexif Énergique : Peur, Panique, Angoisse, Oppression)",
        "V-_C-_E-": "Octant VIII (V- Subi/Réflexif Atonique : Tristesse, Honte, Culpabilité, Aliénation)",
    }
    return code, descriptions[code]


def project_to_octahedral_l1_envelope(
    valence: float,
    arousal: float,
    dominance: float,
    ratio_z: float,
    stratum: SemanticDomainStratum,
) -> Tuple[int, int, int, int, float, float, float, float]:
    """
    Projette chaque lemme sur l'enveloppe octaédrique L1 de CARTOGRAFFECT vérifiant
    exactement la loi géométrique :
        |X| + |Y| = 2 * (Z - 1)   pour Z >= 2
    """
    if stratum == SemanticDomainStratum.STRATUM_0_NEUTRAL_ANCHOR:
        return 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0

    z_int = int(STRATUM_METADATA[stratum]["z_crown_target"])
    r_l1_int = 2 * (z_int - 1)

    z_cont = float(np.clip(1.35 + 2.25 * ratio_z, 2.0, 7.0))
    r_l1_cont = 2.0 * (z_cont - 1.0)

    x_dir = float(valence)
    y_dir = float(0.60 * arousal + 0.40 * dominance)
    norm_dir = abs(x_dir) + abs(y_dir)
    if norm_dir < 1e-6:
        x_dir, y_dir, norm_dir = 1.0, 0.0, 1.0

    u = x_dir / norm_dir
    v = y_dir / norm_dir

    x_cont = float(round(u * r_l1_cont, 4))
    y_sign = 1.0 if v >= 0.0 else -1.0
    y_cont = float(round(y_sign * max(0.0, round(r_l1_cont, 4) - abs(x_cont)), 4))
    r_l1_cont = float(round(abs(x_cont) + abs(y_cont), 4))
    z_cont = float(round(1.0 + 0.5 * r_l1_cont, 4))

    x_mag_int = int(np.clip(round(abs(u) * r_l1_int), 0, r_l1_int))
    y_mag_int = r_l1_int - x_mag_int
    x_int = x_mag_int if x_dir >= 0.0 else -x_mag_int
    y_int = y_mag_int if y_dir >= 0.0 else -y_mag_int

    assert abs(x_int) + abs(y_int) == 2 * (z_int - 1), "Invariant L1 entier violé"
    return x_int, y_int, z_int, r_l1_int, x_cont, y_cont, z_cont, r_l1_cont


# ==============================================================================
# 5. PIPELINE DE CONSOLIDATION DU DICTIONNAIRE COMPLET & CORPUS 3D OPEN-DATA
# ==============================================================================

def build_full_cartograffect_dictionary(
    workspace_dir: str = ".",
    export_files: bool = True,
) -> Dict[str, Any]:
    """
    Construit le Dictionnaire Vectoriel Complet CARTOGRAFFECT® multi-strates ainsi
    que la table 3D dédiée aux Open-Data CNRS / Lexique 3.83 / GLAWI :
    - `CARTOGRAFFECT_Full_Dictionary_MultiStrata.tsv`
    - `CARTOGRAFFECT_OpenData_CNRS_Lexique_GLAWI_3D.tsv`
    - `CARTOGRAFFECT_Strata_Distribution_Stats.json`
    """
    lex15037_path = os.path.join(workspace_dir, "CARTOGRAFFECT_15037_Lexique_GRID_CPM.tsv")
    proto176_path = os.path.join(workspace_dir, "CARTOGRAFFECT_176_GRID_CPM_Interpolated.tsv")
    grid24_path = os.path.join(workspace_dir, "CARTOGRAFFECT_GRID_24_Prototypes_CPM.tsv")

    if not (os.path.exists(lex15037_path) and os.path.exists(proto176_path) and os.path.exists(grid24_path)):
        map_grid_to_cartograffect_3d(workspace_dir=workspace_dir, export_tsv=True)

    df_15037 = pd.read_csv(lex15037_path, sep="\t", encoding="utf-8")
    df_176 = pd.read_csv(proto176_path, sep="\t", encoding="utf-8")
    df_grid24 = pd.read_csv(grid24_path, sep="\t", encoding="utf-8")

    proto176_ids = df_176["id_176"].to_numpy(dtype=int)
    proto176_labels = df_176["label_fr"].astype(str).tolist()
    proto176_z = df_176["Z"].to_numpy(dtype=int)
    proto176_r = np.maximum(1.0, df_176["rayon_L1"].to_numpy(dtype=float))
    proto176_u = df_176["X"].to_numpy(dtype=float) / proto176_r
    proto176_v = df_176["Y"].to_numpy(dtype=float) / proto176_r
    proto176_val = df_176["mean_valence"].to_numpy(dtype=float)
    proto176_aro = df_176["mean_arousal"].to_numpy(dtype=float)
    proto176_dom = df_176["mean_dominance"].to_numpy(dtype=float)
    id176_to_label = {int(i): str(lbl) for i, lbl in zip(proto176_ids, proto176_labels)}
    id176_to_uvz = {
        int(r.id_176): (
            float(r.X) / max(1.0, float(r.rayon_L1)),
            float(r.Y) / max(1.0, float(r.rayon_L1)),
            int(r.Z),
        )
        for r in df_176.itertuples()
    }

    # Table d'ancrage direct pour garantir la couverture 176/176 des prototypes certifiés
    known_id176_by_lemma: Dict[str, int] = {}
    known_pos_by_lemma: Dict[str, str] = {}
    known_3d_proj_by_lemma: Dict[str, Tuple[float, float, float, float]] = {}

    for affect_file in [
        "CARTOGRAFFECT_Affectif_Purifie_Z_Plus.tsv",
        "CARTOGRAFFECT_NRC_Lexicon_Complet.tsv",
        "CARTOGRAFFECT_DIMA_Purifie_Affectif.tsv",
    ]:
        fpath = os.path.join(workspace_dir, affect_file)
        if os.path.exists(fpath):
            df_af = pd.read_csv(fpath, sep="\t", encoding="utf-8")
            id_col = "id_176_ancre" if "id_176_ancre" in df_af.columns else ("id_176" if "id_176" in df_af.columns else None)
            if "terme_fr" in df_af.columns and id_col is not None:
                for r in df_af.itertuples():
                    k = str(r.terme_fr).strip().lower()
                    pid = int(getattr(r, id_col))
                    if 1 <= pid <= 176:
                        known_id176_by_lemma[k] = pid
                    if hasattr(r, "dima_pos") and str(r.dima_pos) not in {"-", "nan"}:
                        known_pos_by_lemma[k] = str(r.dima_pos)
                    if hasattr(r, "X_proj") and hasattr(r, "Y_proj") and hasattr(r, "Z_proj"):
                        known_3d_proj_by_lemma[k] = (
                            float(r.X_proj),
                            float(r.Y_proj),
                            float(r.Z_proj),
                            float(getattr(r, "distance_L1", 0.02)),
                        )

    valeurs_domain_lookup: Dict[str, Tuple[str, str, float, float, float, str, str, str]] = {}
    stats176_path = os.path.join(workspace_dir, "CARTOGRAFFECT_176_Stats_Synthese.tsv")
    if os.path.exists(stats176_path):
        df_s176 = pd.read_csv(stats176_path, sep="\t", encoding="utf-8")
        for r in df_s176.itertuples():
            pid = int(r.id_176)
            lbl_clean = str(r.label_fr).strip().lower()
            known_id176_by_lemma[lbl_clean] = pid
            for w in str(r.top5_mots_fideles).split(","):
                w_clean = w.strip().lower()
                if w_clean and w_clean not in known_id176_by_lemma:
                    known_id176_by_lemma[w_clean] = pid
            # Garantit que chaque label de prototype (ex. Point de Veille) existe dans valeurs_domain_lookup
            if lbl_clean not in valeurs_domain_lookup:
                valeurs_domain_lookup[lbl_clean] = (
                    str(r.label_fr).strip(),
                    f"PROTOTYPE_176_{r.groupe_geom}",
                    float(r.mean_valence),
                    float(r.mean_arousal),
                    float(r.mean_dominance),
                    "I" if int(r.Z) <= 3 else "II",
                    str(r.label_fr).strip(),
                    "NOM",
                )

    grid24_labels = df_grid24["grid_label_fr"].astype(str).tolist()
    grid24_en = df_grid24["grid_label_en"].astype(str).tolist()
    grid24_id176 = df_grid24["id_176_cartograffect"].to_numpy(dtype=int)
    grid24_val = df_grid24["GRID_Valence"].to_numpy(dtype=float)
    grid24_pow = df_grid24["GRID_Power_Coping"].to_numpy(dtype=float)
    grid24_aro = df_grid24["GRID_Arousal"].to_numpy(dtype=float)
    grid24_ratio_z = df_grid24["Ratio_Z_CPM"].to_numpy(dtype=float)

    # Indexation des domaines de valeurs et affectifs depuis Valeurs_Consolidees, Diamant 303 et Affectif_Purifie
    val_path = os.path.join(workspace_dir, "CARTOGRAFFECT_Valeurs_Consolidees.tsv")
    if os.path.exists(val_path):
        df_val = pd.read_csv(val_path, sep="\t", encoding="utf-8")
        for r in df_val.itertuples():
            t_fr = str(r.terme_fr).strip()
            d_pos = str(getattr(r, "dima_pos", "-"))
            if d_pos not in {"-", "nan"}:
                known_pos_by_lemma[t_fr.lower()] = d_pos
            valeurs_domain_lookup[t_fr.lower()] = (
                t_fr,
                str(r.domaine_valeur),
                float(r.valence),
                float(r.arousal),
                float(r.dominance),
                str(r.dima_categ),
                str(r.dima_classe),
                d_pos,
            )

    diamant_path = os.path.join(workspace_dir, "CARTOGRAFFECT_Diamant_303_Lexique_Complet.tsv")
    if os.path.exists(diamant_path):
        df_dia = pd.read_csv(diamant_path, sep="\t", encoding="utf-8")
        for r in df_dia.itertuples():
            t_fr = str(r.terme_fr).strip()
            d_pos = str(getattr(r, "dima_pos", "-"))
            if d_pos not in {"-", "nan"}:
                known_pos_by_lemma[t_fr.lower()] = d_pos
            if t_fr.lower() not in valeurs_domain_lookup:
                valeurs_domain_lookup[t_fr.lower()] = (
                    t_fr,
                    str(r.categorie_semantique),
                    float(r.valence),
                    float(r.arousal),
                    float(r.dominance),
                    str(r.dima_categ),
                    str(r.dima_classe),
                    d_pos,
                )

    for affect_file in ["CARTOGRAFFECT_Affectif_Purifie_Z_Plus.tsv", "CARTOGRAFFECT_NRC_Lexicon_Complet.tsv"]:
        fpath = os.path.join(workspace_dir, affect_file)
        if os.path.exists(fpath):
            df_af = pd.read_csv(fpath, sep="\t", encoding="utf-8")
            for r in df_af.itertuples():
                t_fr = str(r.terme_fr).strip()
                if t_fr.lower() not in valeurs_domain_lookup:
                    valeurs_domain_lookup[t_fr.lower()] = (
                        t_fr,
                        str(getattr(r, "categorie_affective", "AFFECT_PUR")),
                        float(r.valence),
                        float(r.arousal),
                        float(r.dominance),
                        str(getattr(r, "dima_categ", "-")),
                        str(getattr(r, "dima_classe", "-")),
                        str(getattr(r, "dima_pos", "-")),
                    )

    raw_entries: List[Tuple[Any, ...]] = []
    seen_french_lemmas_in_15037 = set()

    # A. Les 15 037 entrées de base (NRC-VAD + DIMA)
    for row in df_15037.itertuples():
        l_fr = str(row.lemme_fr).strip()
        seen_french_lemmas_in_15037.add(l_fr.lower())
        dom_val = "-"
        if l_fr.lower() in valeurs_domain_lookup:
            dom_val = valeurs_domain_lookup[l_fr.lower()][1]
        raw_entries.append((
            f"CARTO_{int(row.nrc_id):05d}",
            l_fr,
            str(row.term_en).strip(),
            "NRC_VAD_DIMA_15037",
            "NRC_Research_License + DIMA_FairDealing_CA + Lexique383_GLAWI_CC_BY_SA",
            float(row.valence_nrc),
            float(row.arousal_nrc),
            float(row.dominance_nrc),
            float(row.Score_Appraisal_Norms),
            float(row.Score_Subjective_Regulation),
            float(row.Score_Bodily_Symptoms),
            float(row.Score_Motor_Expression),
            str(row.dima_categ),
            str(row.dima_classe),
            dom_val,
            None,
        ))

    # B. Extension depuis Valeurs_Consolidees, Diamant 303 & Affectif_Purifie (lemmes français non encore présents)
    ext_counter = 15038
    for key_low, (t_fr, dom_val, v_f, a_f, d_f, d_cat, d_cls, _d_pos) in valeurs_domain_lookup.items():
        if key_low not in seen_french_lemmas_in_15037:
            seen_french_lemmas_in_15037.add(key_low)
            raw_entries.append((
                f"CARTO_{ext_counter:05d}",
                t_fr,
                t_fr,
                "DIMA_AXIOLOGIE_OUVERTE_FR",
                "Lexique383_CC_BY_SA_4.0 + GLAWI_CNRS_CC_BY_SA + Morphalou3.1_ATILF + DIMA_FairDealing_CA",
                v_f,
                a_f,
                d_f,
                0.78,
                0.76,
                0.36,
                0.38,
                d_cat,
                d_cls,
                dom_val,
                None,
            ))
            ext_counter += 1

    # C. Extension depuis la nomenclature ouverte française (CNRS GLAWI / Lexique 3.83 / Morphalou 3.1 / TLFi)
    for (l_fr, t_en, s_hint, sub_dom, v_f, a_f, d_f) in OPEN_FRENCH_EXTENSION_LEMMAS:
        key_low = l_fr.strip().lower()
        if key_low not in seen_french_lemmas_in_15037:
            seen_french_lemmas_in_15037.add(key_low)
            if s_hint == 1:
                nb, rb, bb, mb = 0.28, 0.26, 0.78, 0.76
            elif s_hint == 2:
                nb, rb, bb, mb = 0.44, 0.42, 0.64, 0.66
            elif s_hint == 3:
                nb, rb, bb, mb = 0.64, 0.66, 0.52, 0.50
            elif s_hint == 4:
                nb, rb, bb, mb = 0.78, 0.76, 0.46, 0.44
            elif s_hint == 5:
                nb, rb, bb, mb = 0.86, 0.84, 0.38, 0.36
            else:
                nb, rb, bb, mb = 0.92, 0.90, 0.32, 0.30

            raw_entries.append((
                f"CARTO_{ext_counter:05d}",
                l_fr.strip(),
                t_en.strip(),
                "LEXIQUE383_MORPHALOU_OPEN_FR",
                "Lexique383_CC_BY_SA_4.0 + GLAWI_CNRS_CC_BY_SA + Morphalou3.1_TLFi_CNRS_ATILF",
                float(v_f),
                float(a_f),
                float(d_f),
                nb,
                rb,
                bb,
                mb,
                "II" if s_hint >= 3 else "I",
                sub_dom,
                sub_dom,
                s_hint,
            ))
            ext_counter += 1

    # D. Projection géométrique et analyse morpho-lexicale CNRS / Lexique 3.83 / GLAWI
    records: List[Dict[str, Any]] = []
    for (
        entry_id, lemme_fr, term_en, src_nom, lic_src,
        val, aro, dom, n_base, r_base, b_base, m_base,
        d_cat, d_cls, dom_sem, s_hint
    ) in raw_entries:
        stratum, ratio_z, s_norms, s_reg, s_bod, s_mot = compute_calibrated_stratum_and_ratio_z(
            lemme_fr=lemme_fr,
            term_en=term_en,
            valence=val,
            arousal=aro,
            dominance=dom,
            score_norms_base=n_base,
            score_reg_base=r_base,
            score_bod_base=b_base,
            score_mot_base=m_base,
            dima_categ=d_cat,
            dima_classe=d_cls,
            domaine_valeur=dom_sem,
            explicit_stratum_hint=s_hint,
        )

        x_int, y_int, z_int, r_l1_int, x_cont, y_cont, z_cont, r_l1_cont = project_to_octahedral_l1_envelope(
            valence=val,
            arousal=aro,
            dominance=dom,
            ratio_z=ratio_z,
            stratum=stratum,
        )

        octant_code, octant_label = classify_octant(valence=val, coping_power=dom, arousal=aro)

        lemma_key = lemme_fr.strip().lower()
        if lemma_key in known_id176_by_lemma:
            id176_val = int(known_id176_by_lemma[lemma_key])
            proto176_lbl = id176_to_label[id176_val]
        else:
            u_q = x_int / max(1.0, float(r_l1_int))
            v_q = y_int / max(1.0, float(r_l1_int))
            z_penalty = 0.35 * np.abs(proto176_z - z_int)
            dir_dist = np.abs(proto176_u - u_q) + np.abs(proto176_v - v_q)
            vad_dist = 0.35 * (np.abs(proto176_val - val) + np.abs(proto176_aro - aro) + np.abs(proto176_dom - dom))
            best_176_idx = int(np.argmin(z_penalty + dir_dist + vad_dist))
            id176_val = int(proto176_ids[best_176_idx])
            proto176_lbl = proto176_labels[best_176_idx]

        grid_dist = (
            1.20 * (grid24_val - val) ** 2
            + 1.00 * (grid24_pow - dom) ** 2
            + 0.90 * (grid24_aro - aro) ** 2
            + 0.65 * ((grid24_ratio_z - ratio_z) / 1.5) ** 2
        )
        best_grid_idx = int(np.argmin(grid_dist))
        grid24_nearest_fr = grid24_labels[best_grid_idx]
        grid24_nearest_en = grid24_en[best_grid_idx]
        grid24_nearest_id176 = int(grid24_id176[best_grid_idx])

        pos_cnrs, glawi_dom, open_badge, est_fr_cert = infer_cnrs_lexique_glawi_pos_and_domain(
            lemme_fr=lemme_fr,
            term_en=term_en,
            stratum=stratum,
            dima_pos=known_pos_by_lemma.get(lemma_key, "-"),
            source_nomenclature=src_nom,
            is_certified_fr_lemma=(lemma_key in known_id176_by_lemma or lemma_key in valeurs_domain_lookup or d_cat != "-"),
        )

        # Coordonnées 3D unitaires pour l'affichage dans le visualiseur 3D de la Pyramide 176
        if lemma_key in known_3d_proj_by_lemma:
            xp_3d, yp_3d, zp_3d, dist_l1_3d = known_3d_proj_by_lemma[lemma_key]
        else:
            pu, pv, pz = id176_to_uvz[id176_val]
            u_l1 = x_cont / max(1.0, r_l1_cont)
            v_l1 = y_cont / max(1.0, r_l1_cont)
            xp_3d = round(0.75 * pu + 0.25 * u_l1, 4)
            yp_3d = round(0.75 * pv + 0.25 * v_l1, 4)
            zp_3d = float(pz)
            dist_l1_3d = round(abs(pu - u_l1) + abs(pv - v_l1), 4)

        records.append({
            "entry_id": entry_id,
            "lemme_fr": lemme_fr,
            "term_en_ref": term_en,
            "est_lemme_fr_ouvert": est_fr_cert,
            "pos_cnrs_lexique": pos_cnrs,
            "glawi_domaine_cnrs": glawi_dom,
            "open_data_badge": open_badge,
            "source_nomenclature": src_nom,
            "licence_conformite": lic_src,
            "SemanticDomainStratum": stratum.value,
            "stratum_rank": int(STRATUM_METADATA[stratum]["rank"]),
            "stratum_label_fr": STRATUM_METADATA[stratum]["label_fr"],
            "domaine_semantique": dom_sem,
            "dima_categ": d_cat,
            "dima_classe": d_cls,
            "valence": round(val, 4),
            "coping_power": round(dom, 4),
            "arousal_energy": round(aro, 4),
            "octant_code": octant_code,
            "octant_label": octant_label,
            "Score_Appraisal_Norms": s_norms,
            "Score_Subjective_Regulation": s_reg,
            "Score_Bodily_Symptoms": s_bod,
            "Score_Motor_Expression": s_mot,
            "Ratio_Z": ratio_z,
            "X_L1_int": x_int,
            "Y_L1_int": y_int,
            "Z_L1_int": z_int,
            "R_L1_int": r_l1_int,
            "X_L1_cont": x_cont,
            "Y_L1_cont": y_cont,
            "Z_L1_cont": z_cont,
            "R_L1_cont": r_l1_cont,
            "X_proj_3d": xp_3d,
            "Y_proj_3d": yp_3d,
            "Z_proj_3d": zp_3d,
            "distance_L1_3d": dist_l1_3d,
            "id176": id176_val,
            "proto176_label": proto176_lbl,
            "grid24_nearest": grid24_nearest_fr,
            "grid24_nearest_en": grid24_nearest_en,
            "grid24_id176": grid24_nearest_id176,
        })

    df_full = pd.DataFrame(records)

    # Vérification stricte de l'invariant d'enveloppe octaédrique L1 : |X| + |Y| = 2(Z - 1)
    l1_lhs = df_full["X_L1_int"].abs() + df_full["Y_L1_int"].abs()
    l1_rhs = 2 * (df_full["Z_L1_int"] - 1)
    assert bool((l1_lhs == l1_rhs).all()), "Violation de l'enveloppe L1 |X| + |Y| = 2(Z - 1)"

    # Extraction du Corpus 100 % Français Certifié Open-Data (CNRS / Lexique 3.83 / GLAWI) pour le Cartograffect 3D
    df_open_fr = df_full[df_full["est_lemme_fr_ouvert"] == 1].copy()
    # Priorité aux entrées DIMA/Open-FR lors de la déduplication sur lemme_fr
    df_open_fr["_prio"] = df_open_fr["source_nomenclature"].map({
        "LEXIQUE383_MORPHALOU_OPEN_FR": 0,
        "DIMA_AXIOLOGIE_OUVERTE_FR": 1,
        "NRC_VAD_DIMA_15037": 2,
    }).fillna(3)
    df_open_fr = (
        df_open_fr
        .sort_values(["_prio", "distance_L1_3d"])
        .drop_duplicates(subset=["lemme_fr"], keep="first")
        .drop(columns=["_prio"])
        .reset_index(drop=True)
    )

    # Résumé statistique par strate
    total_n = len(df_full)
    open_fr_n = len(df_open_fr)
    strata_stats: Dict[str, Any] = {}
    for stratum in [
        SemanticDomainStratum.STRATUM_1_AFFECTIVE_SOMATIC,
        SemanticDomainStratum.STRATUM_2_EMOTIONAL_EPISODIC,
        SemanticDomainStratum.STRATUM_3_SENTIMENTAL_RELATIONAL,
        SemanticDomainStratum.STRATUM_4_ETHICAL_MORAL,
        SemanticDomainStratum.STRATUM_5_AXIOLOGICAL_VALUES,
        SemanticDomainStratum.STRATUM_6_POLITICAL_CIVIC,
    ]:
        sub = df_full[df_full["SemanticDomainStratum"] == stratum.value]
        sub_fr = df_open_fr[df_open_fr["SemanticDomainStratum"] == stratum.value]
        meta = STRATUM_METADATA[stratum]
        count_s = int(len(sub))
        count_fr_s = int(len(sub_fr))
        oct_counts = sub["octant_code"].value_counts().to_dict()
        pos_counts = sub_fr["pos_cnrs_lexique"].value_counts().to_dict()
        top_grid = sub["grid24_nearest"].value_counts().head(5).to_dict()
        sample_lemmas = sub_fr["lemme_fr"].head(12).tolist()
        strata_stats[stratum.value] = {
            "rank": meta["rank"],
            "label_fr": meta["label_fr"],
            "glawi_domain_cnrs": meta["glawi_domain"],
            "z_regime": meta["z_regime"],
            "theoretical_reference": meta["theoretical_reference"],
            "ratio_z_bounds": [meta["ratio_z_min"], meta["ratio_z_max"]],
            "z_crown_target": meta["z_crown_target"],
            "count": count_s,
            "count_open_french_3d": count_fr_s,
            "percentage": round(100.0 * count_s / max(1, total_n), 2),
            "ratio_z_mean": round(float(sub["Ratio_Z"].mean()), 4) if count_s > 0 else 0.0,
            "ratio_z_min_observed": round(float(sub["Ratio_Z"].min()), 4) if count_s > 0 else 0.0,
            "ratio_z_max_observed": round(float(sub["Ratio_Z"].max()), 4) if count_s > 0 else 0.0,
            "valence_mean": round(float(sub["valence"].mean()), 4) if count_s > 0 else 0.0,
            "coping_power_mean": round(float(sub["coping_power"].mean()), 4) if count_s > 0 else 0.0,
            "arousal_energy_mean": round(float(sub["arousal_energy"].mean()), 4) if count_s > 0 else 0.0,
            "octant_distribution": {str(k): int(v) for k, v in oct_counts.items()},
            "pos_cnrs_lexique_distribution": {str(k): int(v) for k, v in pos_counts.items()},
            "top_5_grid24_anchors": {str(k): int(v) for k, v in top_grid.items()},
            "sample_lemmas_fr": sample_lemmas,
        }

    stats_summary = {
        "project": "CARTOGRAFFECT® — Dictionnaire Vectoriel Complet Multi-Strates & Open-Data CNRS/Lexique/GLAWI",
        "copyright_registration": "OPIC / CIPO Certificat n° 1233199 — Manuel Cabelguen",
        "dual_license": {
            "code_and_lean4_proofs": "GNU AGPLv3 (SPDX: AGPL-3.0-or-later)",
            "theory_taxonomy_and_tables": "CC BY-NC-SA 4.0 (SPDX: CC-BY-NC-SA-4.0)",
        },
        "nomenclature_compliance": (
            "100% ressources ouvertes ou sous licence de recherche équitable "
            "(Lexique 3.83 CC BY-SA 4.0, GLAWI CLLE-CNRS CC BY-SA, Morphalou 3.1 / TLFi CNRS ATILF Licence Ouverte, "
            "NRC-VAD Research License, DIMA art. 29 LDA Canada, Scherer GRID/CPM CISA Genève). "
            "0 dictionnaire commercial utilisé."
        ),
        "total_entries": total_n,
        "base_15037_entries": 15037,
        "open_french_extension_entries": total_n - 15037,
        "open_french_3d_unique_lemmas": open_fr_n,
        "unique_prototypes_176_covered": int(df_full["id176"].nunique()),
        "unique_prototypes_176_covered_open_fr_3d": int(df_open_fr["id176"].nunique()),
        "unique_grid24_anchors_covered": int(df_full["grid24_nearest"].nunique()),
        "octahedral_l1_envelope_verified": True,
        "open_data_pos_distribution_fr": {
            str(k): int(v) for k, v in df_open_fr["pos_cnrs_lexique"].value_counts().to_dict().items()
        },
        "open_data_glawi_domain_distribution_fr": {
            str(k): int(v) for k, v in df_open_fr["glawi_domaine_cnrs"].value_counts().to_dict().items()
        },
        "open_data_badge_distribution_fr": {
            str(k): int(v) for k, v in df_open_fr["open_data_badge"].value_counts().to_dict().items()
        },
        "octant_global_distribution": {
            str(k): int(v) for k, v in df_full["octant_code"].value_counts().to_dict().items()
        },
        "source_nomenclature_breakdown": {
            str(k): int(v) for k, v in df_full["source_nomenclature"].value_counts().to_dict().items()
        },
        "strata_distribution": strata_stats,
    }

    if export_files:
        out_tsv = os.path.join(workspace_dir, "CARTOGRAFFECT_Full_Dictionary_MultiStrata.tsv")
        out_open_3d_tsv = os.path.join(workspace_dir, "CARTOGRAFFECT_OpenData_CNRS_Lexique_GLAWI_3D.tsv")
        out_json = os.path.join(workspace_dir, "CARTOGRAFFECT_Strata_Distribution_Stats.json")
        df_full.to_csv(out_tsv, sep="\t", index=False, encoding="utf-8")
        df_open_fr.to_csv(out_open_3d_tsv, sep="\t", index=False, encoding="utf-8")
        with open(out_json, "w", encoding="utf-8") as f:
            json.dump(stats_summary, f, ensure_ascii=False, indent=2)

    return {
        "df_full": df_full,
        "df_open_fr_3d": df_open_fr,
        "stats_summary": stats_summary,
    }


def main() -> None:
    workspace_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    res = build_full_cartograffect_dictionary(workspace_dir=workspace_dir, export_files=True)
    stats = res["stats_summary"]
    print("=" * 90)
    print("DICTIONNAIRE VECTORIEL COMPLET CARTOGRAFFECT® & OPEN-DATA CNRS / LEXIQUE 3.83 / GLAWI")
    print("=" * 90)
    print(f"Total entrées projetées            : {stats['total_entries']} (15 037 base + {stats['open_french_extension_entries']} extension FR ouverte)")
    print(f"Lemmes FR Open-Data 3D uniques     : {stats['open_french_3d_unique_lemmas']} (CNRS GLAWI / Lexique 3.83 / Morphalou)")
    print(f"Prototypes 176 couverts (Total/FR) : {stats['unique_prototypes_176_covered']}/176 | {stats['unique_prototypes_176_covered_open_fr_3d']}/176")
    print(f"Ancres Scherer GRID couvertes      : {stats['unique_grid24_anchors_covered']} / 24")
    print(f"Distribution POS (CNRS/Lexique)    : {stats['open_data_pos_distribution_fr']}")
    print("-" * 90)
    for s_key, s_info in stats["strata_distribution"].items():
        print(
            f"  {s_info['label_fr']:<38} | Total={s_info['count']:>5d} | FR_Open3D={s_info['count_open_french_3d']:>5d} "
            f"| Ratio_Z={s_info['ratio_z_mean']:.4f} | {s_info['glawi_domain_cnrs']}"
        )
    print("=" * 90)


if __name__ == "__main__":
    main()
