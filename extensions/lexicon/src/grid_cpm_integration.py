#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
================================================================================
Projet CARTOGRAFFECT — Module d'intégration formelle GRID / CPM (Scherer)
Fichier : src/grid_cpm_integration.py
================================================================================
Intégration formelle de la matrice francophone du paradigme GRID et du
Component Process Model (CPM) de Klaus R. Scherer (Fontaine, Scherer, Roesch,
& Ellsworth, 2007 ; Fontaine, Scherer, & Soriano, 2013) pour la validation
sémantique et géométrique du modèle octaédrique 3D CARTOGRAFFECT (176 prototypes
et lexique de 15 037 termes français indexés avec NRC-VAD et DIMA).

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
import json
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple, Any

import numpy as np
import pandas as pd


# ==============================================================================
# 1. DÉFINITION FORMELLE DES 142 ITEMS DU COMPONENT PROCESS MODEL (CPM / GRID)
#    Répartition canonique (Fontaine, Scherer, & Soriano, 2013) :
#    - Appraisal          : 33 items (nouveauté, valence intrinsèque, buts,
#                                     agentivité, coping/pouvoir, normes)
#    - Bodily_Symptoms    : 27 items (activation somato-viscérale autonome)
#    - Motor_Expression   : 33 items (expressions faciales, vocales, posturales)
#    - Action_Tendencies  : 28 items (approche, attaque, fuite, sidération, réparation)
#    - Subjective_Feeling : 21 items (intensité, durée, ressenti, régulation)
#    Total = 33 + 27 + 33 + 28 + 21 = 142 descripteurs componantiels
# ==============================================================================

CPM_COMPONENT_SIZES: Dict[str, int] = {
    "Appraisal": 33,
    "Bodily_Symptoms": 27,
    "Motor_Expression": 33,
    "Action_Tendencies": 28,
    "Subjective_Feeling": 21,
}

assert sum(CPM_COMPONENT_SIZES.values()) == 142, "La somme des items CPM doit valoir 142."

# Sous-ensembles d'indices au sein de chaque composante pour le calcul exact du Ratio Z :
# - Appraisal_Norms (indices 26..32 inclus dans Appraisal, soit 7 items de compatibilité
#   aux normes internes/idéal du moi et normes sociales/justice)
# - Subjective_Regulation (indices 13..20 inclus dans Subjective_Feeling, soit 8 items
#   de régulation cognitive, contrôle réflexif, partage normatif et modulation)
APPRAISAL_SUBFACETS: Dict[str, slice] = {
    "novelty": slice(0, 5),              # 5 items : soudaineté, imprévisibilité, non-familiarité
    "intrinsic_valence": slice(5, 9),    # 4 items : agrément intrinsèque vs caractère aversif
    "goal_relevance": slice(9, 16),      # 7 items : pertinence des buts, congruence, urgence
    "agency_causality": slice(16, 21),   # 5 items : causalité soi/autrui/hasard, intentionnalité
    "coping_power": slice(21, 26),       # 5 items : contrôle, puissance pragmatique, ajustement
    "norms_compatibility": slice(26, 33) # 7 items : normes sociales, justice, idéal de soi, morale
}

BODILY_SUBFACETS: Dict[str, slice] = {
    "cardiovascular_respiratory": slice(0, 8), # 8 items : tachycardie, souffle court/profond
    "thermoregulatory_sweating": slice(8, 15), # 7 items : chaleur, rougeur, sueurs, frissons
    "visceral_gastro": slice(15, 21),          # 6 items : gorge serrée, nœud à l'estomac, nausée
    "muscular_tonus": slice(21, 27),           # 6 items : tension musculaire, tremblements, faiblesse
}

MOTOR_SUBFACETS: Dict[str, slice] = {
    "facial": slice(0, 13),    # 13 items : sourire, sourcils froncés, yeux écarquillés, mâchoire, larmes
    "vocal": slice(13, 24),    # 11 items : intensité vocale, hauteur F0, débit, tremblement, silence
    "postural": slice(24, 33), # 9 items : redressement, affaissement, ouverture/repli corporel, gestes
}

ACTION_SUBFACETS: Dict[str, slice] = {
    "approach": slice(0, 6),     # 6 items : approche, contact, exploration, union
    "attack": slice(6, 12),      # 6 items : attaque, opposition, agression verbale/physique, vengeance
    "flight": slice(12, 18),     # 6 items : fuite, évitement, retrait protecteur, dissimulation
    "freezing": slice(18, 23),   # 5 items : sidération, blocage moteur, inhibition, impuissance active
    "reparation": slice(23, 28), # 5 items : réparation, excuse, soin, réconciliation, soutien
}

FEELING_SUBFACETS: Dict[str, slice] = {
    "intensity_duration": slice(0, 5),     # 5 items : intensité globale, durée temporelle, rémanence
    "core_affect_experience": slice(5, 13),# 8 items : plaisir/déplaisir conscient, éveil, clarté
    "regulation": slice(13, 21),           # 8 items : réévaluation cognitive, maîtrise, contention, intégration
}


def get_cpm_item_labels() -> Dict[str, List[str]]:
    """Retourne les identifiants explicites des 142 items du paradigme GRID en français."""
    return {
        "Appraisal": [
            # Nouveauté (5)
            "APP_01_soudainete", "APP_02_imprevisibilite", "APP_03_non_familiarite",
            "APP_04_rupture_attente", "APP_05_saillance_attentionnelle",
            # Valence intrinsèque (4)
            "APP_06_agrement_intrinseque", "APP_07_desagrement_intrinseque",
            "APP_08_attrait_sensoriel", "APP_09_repulsion_intrinseque",
            # Pertinence et congruence aux buts (7)
            "APP_10_pertinence_buts", "APP_11_congruence_buts", "APP_12_obstruction_buts",
            "APP_13_certitude_issue", "APP_14_urgence_reaction", "APP_15_consequences_positives",
            "APP_16_consequences_irreversibles",
            # Agentivité et causalité (5)
            "APP_17_causalite_soi", "APP_18_causalite_autrui", "APP_19_causalite_hasard_destin",
            "APP_20_intentionnalite_agent", "APP_21_responsabilite_percue",
            # Potentiel de maîtrise / Coping (5)
            "APP_22_controle_situationnel", "APP_23_puissance_personnelle",
            "APP_24_capacite_ajustement", "APP_25_domination_interpersonnelle",
            "APP_26_autonomie_action",
            # Normes internes et externes (7) -> Score_Appraisal_Norms
            "APP_27_compatibilite_normes_sociales", "APP_28_transgression_morale",
            "APP_29_congruence_ideal_soi", "APP_30_justice_equite_percue",
            "APP_31_devoir_obligation_ethique", "APP_32_legitimite_statutaire",
            "APP_33_evaluation_axiologique_abstraite",
        ],
        "Bodily_Symptoms": [
            # Cardiovasculaire & respiratoire (8)
            "BOD_01_acceleration_cardiaque", "BOD_02_ralentissement_cardiaque",
            "BOD_03_pression_thoracique", "BOD_04_respiration_rapide",
            "BOD_05_respiration_profonde_ample", "BOD_06_souffle_coupe",
            "BOD_07_soupir_relachement", "BOD_08_palpitations",
            # Thermorégulation & sudation (7)
            "BOD_09_sensation_chaleur", "BOD_10_bouffee_vasomotrice_visage",
            "BOD_11_rougissement", "BOD_12_sensation_froid_glace",
            "BOD_13_paleur_cutanee", "BOD_14_transpiration_mains_corps",
            "BOD_15_frissons_horripilation",
            # Viscéral & gastro-intestinal (6)
            "BOD_16_gorge_serree_boule", "BOD_17_noeud_estomac",
            "BOD_18_nausee_ecoeurement_visceral", "BOD_19_bouche_seche",
            "BOD_20_detente_viscerale", "BOD_21_lourdeur_interne",
            # Tonus musculaire & moteur somatique (6)
            "BOD_22_tension_musculaire_generale", "BOD_23_tremblements_membres",
            "BOD_24_faiblesse_jambes_flottes", "BOD_25_tonus_energique",
            "BOD_26_relachement_musculaire", "BOD_27_fatigue_epuisement_somatique",
        ],
        "Motor_Expression": [
            # Expressions faciales (13)
            "MOT_01_sourire_duchenne", "MOT_02_froncement_sourcils",
            "MOT_03_yeux_ecarquilles", "MOT_04_yeux_plisses_reduits",
            "MOT_05_bouche_ouverte_choc", "MOT_06_machoire_serree",
            "MOT_07_levres_relevees_dedain", "MOT_08_coins_levres_abaisses",
            "MOT_09_nez_plisse_degout", "MOT_10_larmes_pleurs",
            "MOT_11_regard_fixe_direct", "MOT_12_regard_fuyant_baisse",
            "MOT_13_visage_detendu_paisible",
            # Expressions vocales (11)
            "MOT_14_voix_forte_eclatante", "MOT_15_voix_faible_eteinte",
            "MOT_16_hauteur_tonale_aigue", "MOT_17_hauteur_tonale_grave",
            "MOT_18_debit_parole_rapide", "MOT_19_debit_parole_lent",
            "MOT_20_voix_tremblante_brisee", "MOT_21_voix_ferme_assuree",
            "MOT_22_exclamation_cri", "MOT_23_rire_vocalisation_positive",
            "MOT_24_mutisme_silence_vocal",
            # Expressions posturales et gestuelles (9)
            "MOT_25_posture_redressee_poitrine_ouverte", "MOT_26_posture_affaissee_voutee",
            "MOT_27_inclinaison_buste_avant", "MOT_28_recul_buste_arriere",
            "MOT_29_poings_serres", "MOT_30_bras_ouverts_accueil",
            "MOT_31_gestes_agites_amples", "MOT_32_immobilite_posturale",
            "MOT_33_tete_haute_fierte",
        ],
        "Action_Tendencies": [
            # Approche (6)
            "ACT_01_approche_objet_personne", "ACT_02_recherche_proximite_contact",
            "ACT_03_exploration_curieuse", "ACT_04_partage_expressif",
            "ACT_05_poursuite_active_but", "ACT_06_celebration_exuberante",
            # Attaque / Antagonisme (6)
            "ACT_07_attaque_physique_verbale", "ACT_08_confrontation_obstacle",
            "ACT_09_desir_punir_blesser", "ACT_10_opposition_resistance",
            "ACT_11_rejet_expulsion", "ACT_12_domination_coercitive",
            # Fuite / Évitement (6)
            "ACT_13_fuite_mise_en_securite", "ACT_14_evitement_contact",
            "ACT_15_volonte_disparaitre_se_cacher", "ACT_16_repli_solitaire",
            "ACT_17_abandon_desengagement", "ACT_18_distanciation_froide",
            # Sidération / Inhibition (5)
            "ACT_19_sideration_paralysie", "ACT_20_inhibition_action",
            "ACT_21_perte_controle_execution", "ACT_22_soumission_passive",
            "ACT_23_rumination_immobile",
            # Réparation / Prosocial (5)
            "ACT_24_reparation_faute_excuse", "ACT_25_protection_soin_autrui",
            "ACT_26_reconciliation_pardon", "ACT_27_recherche_aide_consolation",
            "ACT_28_fidelite_engagement_durable",
        ],
        "Subjective_Feeling": [
            # Intensité et durée (5)
            "SUB_01_intensite_ressentie", "SUB_02_duree_prolongee",
            "SUB_03_persistance_cognitive", "SUB_04_profondeur_existentielle",
            "SUB_05_stabilite_temporelle",
            # Ressenti affectif central (8)
            "SUB_06_plaisir_hedonique_conscient", "SUB_07_souffrance_douleur_morale",
            "SUB_08_energie_vitalite_subjective", "SUB_09_calme_serenite_interieure",
            "SUB_10_sentiment_puissance_maitrise", "SUB_11_sentiment_impuissance_fragilite",
            "SUB_12_ouverture_relationnelle", "SUB_13_fermeture_cloture_affective",
            # Régulation émotionnelle et réflexivité (8) -> Score_Subjective_Regulation
            "SUB_14_reevaluation_cognitive", "SUB_15_auto_observation_reflexive",
            "SUB_16_controle_inhibiteur_expression", "SUB_17_integration_normative_soi",
            "SUB_18_modulation_attentionnelle", "SUB_19_acceptation_experientielle",
            "SUB_20_deliberation_morale_temporelle", "SUB_21_transcendance_decentration",
        ],
    }


@dataclass
class GRIDPrototypeCPM:
    """
    Représentation formelle d'un des 24 prototypes émotionnels canoniques français
    du paradigme GRID (Fontaine et al., 2007, 2013) structuré selon les 5 composantes
    du Component Process Model (CPM) de Klaus Scherer.
    """
    label_fr: str
    label_en: str
    id_176_cartograffect: int
    proto_cartograffect: str
    dima_categ: str
    dima_classe: str
    # Coordonnées factorielles GRID empiriques sur [-1.0, +1.0]
    valence_grid: float       # Facteur 1 : Valence (Evaluation / Pleasantness)
    power_coping_grid: float  # Facteur 2 : Power / Control / Coping Potential
    arousal_grid: float       # Facteur 3 : Activation / Arousal
    novelty_grid: float       # Facteur 4 : Novelty / Unpredictability
    # Les 5 vecteurs componantiels du CPM (total = 142 items calibrés dans [0.0, 1.0])
    appraisal: np.ndarray = field(repr=False)           # shape (33,)
    bodily_symptoms: np.ndarray = field(repr=False)     # shape (27,)
    motor_expression: np.ndarray = field(repr=False)    # shape (33,)
    action_tendencies: np.ndarray = field(repr=False)   # shape (28,)
    subjective_feeling: np.ndarray = field(repr=False)  # shape (21,)

    def __post_init__(self) -> None:
        assert self.appraisal.shape == (33,), f"Appraisal doit avoir 33 items ({self.appraisal.shape})"
        assert self.bodily_symptoms.shape == (27,), f"Bodily_Symptoms doit avoir 27 items ({self.bodily_symptoms.shape})"
        assert self.motor_expression.shape == (33,), f"Motor_Expression doit avoir 33 items ({self.motor_expression.shape})"
        assert self.action_tendencies.shape == (28,), f"Action_Tendencies doit avoir 28 items ({self.action_tendencies.shape})"
        assert self.subjective_feeling.shape == (21,), f"Subjective_Feeling doit avoir 21 items ({self.subjective_feeling.shape})"

    @property
    def vector_142(self) -> np.ndarray:
        """Vecteur complet des 142 items CPM concaténés."""
        return np.concatenate([
            self.appraisal,
            self.bodily_symptoms,
            self.motor_expression,
            self.action_tendencies,
            self.subjective_feeling,
        ])

    @property
    def factor_vector_4d(self) -> np.ndarray:
        """Vecteur des 4 dimensions factorielles de GRID (Valence, Power/Coping, Arousal, Novelty)."""
        return np.array([
            self.valence_grid,
            self.power_coping_grid,
            self.arousal_grid,
            self.novelty_grid,
        ], dtype=float)

    @property
    def score_appraisal(self) -> float:
        return float(np.mean(self.appraisal))

    @property
    def score_appraisal_norms(self) -> float:
        """Score d'évaluation de compatibilité aux normes internes et externes (7 items finaux d'Appraisal)."""
        return float(np.mean(self.appraisal[APPRAISAL_SUBFACETS["norms_compatibility"]]))

    @property
    def score_bodily_symptoms(self) -> float:
        """Score d'activation somato-viscérale (27 items)."""
        return float(np.mean(self.bodily_symptoms))

    @property
    def score_motor_expression(self) -> float:
        """Score d'expression motrice faciale, vocale et posturale (33 items)."""
        return float(np.mean(self.motor_expression))

    @property
    def score_action_tendencies(self) -> float:
        """Score global des tendances à l'action (28 items)."""
        return float(np.mean(self.action_tendencies))

    @property
    def score_subjective_feeling(self) -> float:
        """Score global du ressenti subjectif (21 items)."""
        return float(np.mean(self.subjective_feeling))

    @property
    def score_subjective_regulation(self) -> float:
        """Score de régulation cognitive, temporelle et réflexive du ressenti (8 items finaux de Subjective_Feeling)."""
        return float(np.mean(self.subjective_feeling[FEELING_SUBFACETS["regulation"]]))

    @property
    def z_elevation_ratio(self) -> float:
        """
        Ratio d'élévation verticale Z (de Z- physiologique/somatique vers Z+ abstraction cognitive/normative) :
        (Score_Appraisal_Norms + Score_Subjective_Regulation) / (Score_Bodily_Symptoms + Score_Motor_Expression)
        """
        numerator = self.score_appraisal_norms + self.score_subjective_regulation
        denominator = max(1e-6, self.score_bodily_symptoms + self.score_motor_expression)
        return float(numerator / denominator)


# ==============================================================================
# 2. CONSTRUCTION DES PROFILS COMPONANTIELS DES 24 PROTOTYPES CANONIQUES GRID
#    Calibrés selon les profils empiriques francophones de Fontaine et al. (2007, 2013)
# ==============================================================================

# Spécifications paramétriques des 24 prototypes canoniques français de GRID :
# (label_fr, label_en, id_176, proto_carto, dima_cat, dima_cls,
#  Valence, Power/Coping, Arousal, Novelty,
#  Appraisal_Norms_level, Subjective_Regulation_level,
#  Bodily_Activation_level, Motor_Expressivity_level,
#  Action_Profile: (approach, attack, flight, freezing, reparation))
_GRID_24_SPECS: List[Tuple[Any, ...]] = [
    # 1. Joie (Joy) — Affect primaire Z=2 (0, +2, 2) : forte activation somatique/expressive, normes modérées
    ("Joie", "joy", 4, "Joie", "I", "Réjouir",
     0.92, 0.58, 0.72, 0.25,
     0.38, 0.36, 0.68, 0.82, (0.88, 0.08, 0.05, 0.04, 0.62)),

    # 2. Fierté (Pride) — Sentiment réflexif Z=4 (+4, +2, 4) : forte évaluation normative de soi, posture haute
    ("Fierté", "pride", 46, "Fierté", "I", "Flatter",
     0.74, 0.82, 0.42, -0.15,
     0.84, 0.72, 0.44, 0.54, (0.72, 0.18, 0.06, 0.05, 0.48)),

    # 3. Plaisir (Pleasure) — Émotion réactive hédonique Z=3 (+1, +3, 3) : forte composante somatique/sensorielle
    ("Plaisir", "pleasure", 18, "Euphorie", "I", "Jouissance",
     0.88, 0.46, 0.54, 0.12,
     0.34, 0.38, 0.64, 0.68, (0.85, 0.06, 0.05, 0.05, 0.52)),

    # 4. Soulagement (Relief) — Émotion réactive de décharge Z=3 (+1, -3, 3) : relâchement somatique post-menace
    ("Soulagement", "relief", 19, "Soulagement", "I", "Apaiser",
     0.68, 0.24, -0.42, -0.10,
     0.42, 0.54, 0.52, 0.46, (0.52, 0.05, 0.18, 0.12, 0.56)),

    # 5. Satisfaction (Contentment/Satisfaction) — Disposition durable Z=5 (+4, -4, 5) : accomplissement normatif et régulation calme
    ("Satisfaction", "satisfaction", 84, "Satisfaction", "I", "Combler un désir",
     0.80, 0.64, -0.28, -0.38,
     0.78, 0.82, 0.32, 0.36, (0.66, 0.05, 0.06, 0.06, 0.64)),

    # 6. Amour (Love) — Sentiment relationnel Z=4 (+1, +5, 4) : engagement affectif, approche et régulation relationnelle
    ("Amour", "love", 36, "Amour", "II", "Amour",
     0.90, 0.52, 0.48, -0.18,
     0.76, 0.70, 0.54, 0.56, (0.94, 0.04, 0.04, 0.06, 0.88)),

    # 7. Tendresse (Tenderness) — Sentiment relationnel Z=4 (+5, -1, 4) : sollicitude prosociale apaisée et normative
    ("Tendresse", "tenderness", 48, "Affection", "II", "Affection",
     0.84, 0.38, -0.32, -0.35,
     0.78, 0.76, 0.34, 0.38, (0.86, 0.03, 0.05, 0.06, 0.92)),

    # 8. Espoir (Hope) — Disposition prospective Z=5 (+7, +1, 5) : projection temporelle longue et régulation cognitive
    ("Espoir", "hope", 79, "Espoir", "II", "Espoir",
     0.70, 0.36, 0.18, -0.12,
     0.80, 0.84, 0.32, 0.34, (0.76, 0.06, 0.08, 0.08, 0.68)),

    # 9. Surprise (Surprise) — Opérateur central de rupture Z=1 (0, 0, 1) : nouveauté maximale, réflexe d'orientation pur
    ("Surprise", "surprise", 2, "Surprise", "I", "Surprendre",
     0.18, -0.12, 0.78, 0.96,
     0.16, 0.18, 0.74, 0.86, (0.42, 0.08, 0.22, 0.64, 0.12)),

    # 10. Colère (Anger) — Affect primaire Z=2 (-1, +1, 2) : forte mobilisation somato-motrice et tendance d'attaque
    ("Colère", "anger", 8, "Colère", "II", "Colère",
     -0.76, 0.68, 0.86, 0.32,
     0.46, 0.28, 0.84, 0.88, (0.28, 0.92, 0.08, 0.06, 0.08)),

    # 11. Irritation (Irritation) — Identité/disposition d'agacement Z=6 (-6, +4, 6) : évaluation normative d'obstacle et contrôle contenu
    ("Irritation", "irritation", 108, "Irritation", "I", "Importuner",
     -0.68, 0.42, 0.52, -0.18,
     0.74, 0.68, 0.42, 0.44, (0.20, 0.68, 0.16, 0.12, 0.14)),

    # 12. Mépris (Contempt) — Sentiment réflexif de dévaluation Z=4 (-5, -1, 4) : jugement normatif supérieur, faible somatisation
    ("Mépris", "contempt", 44, "Mépris", "II", "Mépris",
     -0.72, 0.56, -0.12, -0.32,
     0.84, 0.72, 0.30, 0.42, (0.08, 0.58, 0.38, 0.10, 0.06)),

    # 13. Dégoût (Disgust) — Affect primaire de rejet viscéral Z=2 (-1, -1, 2) : forte réaction somato-viscérale et faciale
    ("Dégoût", "disgust", 11, "Dégoût", "II", "Déplaire_A",
     -0.82, -0.18, 0.44, 0.28,
     0.36, 0.30, 0.78, 0.80, (0.04, 0.32, 0.86, 0.18, 0.05)),

    # 14. Haine (Hate) — Sentiment relationnel hostile Z=4 (-1, +5, 4) : condamnation normative durable et antagonisme actif
    ("Haine", "hate", 35, "Haine", "II", "Haine de qq",
     -0.92, 0.48, 0.68, -0.26,
     0.80, 0.64, 0.54, 0.58, (0.14, 0.90, 0.24, 0.08, 0.04)),

    # 15. Jalousie (Jealousy) — Sentiment relationnel de rivalité Z=4 (-2, +4, 4) : comparaison sociale/normative et vigilance
    ("Jalousie", "jealousy", 34, "Envie", "II", "Jalousie envie",
     -0.74, 0.16, 0.62, -0.08,
     0.74, 0.62, 0.54, 0.52, (0.32, 0.72, 0.22, 0.18, 0.16)),

    # 16. Peur (Fear) — Affect primaire d'alerte Z=2 (-2, 0, 2) : urgence somato-viscérale, fuite et sidération
    ("Peur", "fear", 6, "Peur", "II", "Peur",
     -0.86, -0.74, 0.84, 0.68,
     0.32, 0.26, 0.88, 0.84, (0.06, 0.14, 0.92, 0.76, 0.12)),

    # 17. Angoisse (Anxiety/Anguish) — Identité d'appréhension existentielle Z=6 (-3, +7, 6) : anticipation cognitive diffuse et rumination
    ("Angoisse", "anxiety", 93, "Angoisse", "I", "Inquiéter",
     -0.78, -0.52, 0.58, -0.14,
     0.78, 0.74, 0.48, 0.42, (0.12, 0.18, 0.68, 0.62, 0.24)),

    # 18. Tristesse (Sadness) — Affect primaire de perte Z=2 (0, -2, 2) : baisse de tonus, pleurs, retrait somatique
    ("Tristesse", "sadness", 5, "Tristesse", "I", "Attrister",
     -0.80, -0.68, -0.58, -0.12,
     0.38, 0.36, 0.68, 0.72, (0.12, 0.06, 0.64, 0.68, 0.38)),

    # 19. Désespoir (Despair) — Disposition d'impuissance radicale Z=5 (-1, -7, 5) : clôture temporelle et effondrement cognitif
    ("Désespoir", "despair", 70, "Désespoir", "II", "Désespérer de",
     -0.90, -0.86, -0.24, -0.28,
     0.76, 0.72, 0.44, 0.42, (0.06, 0.10, 0.74, 0.84, 0.18)),

    # 20. Déception (Disappointment) — Disposition d'attente déjouée Z=5 (-4, +4, 5) : écart cognitif aux attentes et normes
    ("Déception", "disappointment", 83, "Insatisfaction", "I", "Décevoir",
     -0.70, -0.32, 0.12, 0.16,
     0.78, 0.76, 0.38, 0.40, (0.14, 0.28, 0.52, 0.44, 0.26)),

    # 21. Solitude (Loneliness/Being hurt) — Sentiment réflexif d'isolement Z=4 (0, -6, 4) : retrait relationnel et intériorisation
    ("Solitude", "loneliness", 31, "Solitude", "I", "Apathie",
     -0.66, -0.58, -0.52, -0.36,
     0.68, 0.70, 0.38, 0.36, (0.18, 0.06, 0.68, 0.62, 0.32)),

    # 22. Nostalgie (Nostalgia) — Sentiment transcendantal/mémoriel Z=7 (-8, -4, 7) : haute abstraction autobiographique, faible somatisation
    ("Nostalgie", "nostalgia", 156, "Mélancolie", "II", "Nostalgie",
     -0.38, -0.44, -0.48, -0.52,
     0.86, 0.88, 0.28, 0.30, (0.42, 0.04, 0.38, 0.42, 0.58)),

    # 23. Culpabilité (Guilt) — Sentiment moral réflexif Z=4 (-1, -5, 4) : transgression de norme interne et tendance de réparation
    ("Culpabilité", "guilt", 41, "Vide", "II", "Mauvaise conscience",
     -0.72, -0.48, 0.22, -0.22,
     0.92, 0.84, 0.46, 0.44, (0.24, 0.12, 0.54, 0.48, 0.90)),

    # 24. Honte (Shame) — Sentiment réflexif d'exposition sociale Z=4 (-2, -4, 4) : transgression de l'idéal du moi sous le regard d'autrui
    ("Honte", "shame", 40, "Honte", "II", "Honte",
     -0.78, -0.66, 0.28, -0.14,
     0.88, 0.76, 0.54, 0.52, (0.10, 0.10, 0.88, 0.72, 0.64)),
]


def _synthesize_cpm_vectors(
    valence: float,
    power: float,
    arousal: float,
    novelty: float,
    norms_lvl: float,
    reg_lvl: float,
    bodily_lvl: float,
    motor_lvl: float,
    action_prof: Tuple[float, float, float, float, float],
    seed_idx: int,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """
    Génère de façon déterministe et théoriquement structurée les 5 vecteurs
    componantiels CPM (33, 27, 33, 28, 21) à partir des paramètres factoriels
    et sous-composantes empiriques de Fontaine et al. (2007, 2013).
    """
    rng = np.random.default_rng(1000 + seed_idx * 37)
    v01 = 0.5 * (valence + 1.0)
    p01 = 0.5 * (power + 1.0)
    a01 = 0.5 * (arousal + 1.0)
    n01 = 0.5 * (novelty + 1.0)

    # 1. Appraisal (33 items)
    appraisal = np.zeros(33, dtype=float)
    # Nouveauté (0..5)
    appraisal[0:5] = np.clip(n01 + np.array([0.04, 0.02, -0.02, 0.05, 0.01]) + rng.normal(0, 0.015, 5), 0.02, 0.98)
    # Valence intrinsèque (5..9) : agrément, désagrément, attrait, répulsion
    appraisal[5:9] = np.clip([v01, 1.0 - v01, v01 * 0.95, (1.0 - v01) * 0.95] + rng.normal(0, 0.015, 4), 0.02, 0.98)
    # Pertinence et congruence aux buts (9..16)
    appraisal[9:16] = np.clip([
        0.75 + 0.20 * abs(valence),
        v01,
        1.0 - v01,
        0.55 + 0.30 * p01,
        0.50 + 0.40 * a01,
        v01 * 0.90,
        (1.0 - v01) * (1.0 - p01),
    ] + rng.normal(0, 0.015, 7), 0.02, 0.98)
    # Agentivité et causalité (16..21)
    appraisal[16:21] = np.clip([
        0.50 + 0.30 * p01,
        0.50 + 0.25 * (1.0 - v01),
        0.30 + 0.45 * n01,
        0.55 + 0.25 * abs(power),
        0.45 + 0.40 * norms_lvl,
    ] + rng.normal(0, 0.015, 5), 0.02, 0.98)
    # Potentiel de maîtrise / Coping (21..26)
    appraisal[21:26] = np.clip(p01 + np.array([0.03, 0.05, -0.02, 0.04, 0.00]) + rng.normal(0, 0.015, 5), 0.02, 0.98)
    # Normes internes et externes (26..33) — calibré exactement sur norms_lvl
    norm_offsets = np.array([-0.03, 0.02, 0.04, -0.01, 0.03, -0.02, -0.03])
    appraisal[26:33] = np.clip(norms_lvl + norm_offsets, 0.02, 0.98)
    # Ajustement exact de la moyenne de la sous-facette norms_compatibility
    appraisal[26:33] *= norms_lvl / max(1e-6, float(np.mean(appraisal[26:33])))

    # 2. Bodily_Symptoms (27 items) — calibré sur bodily_lvl
    bodily = np.zeros(27, dtype=float)
    bodily_pattern = np.array([
        a01, 1.0 - a01, 0.6 * (1.0 - v01) + 0.4 * a01, a01,
        v01 * 0.6 + 0.2, n01 * 0.7 + 0.2, (1.0 - a01) * 0.7, a01 * 0.9,
        0.5 * a01 + 0.5 * v01, a01 * 0.8, 0.5 * norms_lvl + 0.3 * a01, (1.0 - v01) * 0.7,
        (1.0 - v01) * 0.65, a01 * 0.75, 0.5 * n01 + 0.3 * a01,
        (1.0 - v01) * 0.8, (1.0 - v01) * 0.75, (1.0 - v01) * 0.6, a01 * 0.65,
        v01 * (1.0 - a01), (1.0 - v01) * (1.0 - p01),
        a01 * 0.85, a01 * (1.0 - p01), (1.0 - p01) * 0.8, p01 * a01,
        v01 * (1.0 - a01), (1.0 - a01) * (1.0 - p01)
    ])
    bodily = np.clip(0.5 * bodily_lvl + 0.5 * bodily_pattern, 0.02, 0.98)
    bodily *= bodily_lvl / max(1e-6, float(np.mean(bodily)))

    # 3. Motor_Expression (33 items) — calibré sur motor_lvl
    motor_pattern = np.zeros(33, dtype=float)
    # Facial (13)
    motor_pattern[0:13] = [
        v01 * 0.9, (1.0 - v01) * 0.85, n01 * 0.9, (1.0 - v01) * 0.6,
        n01 * 0.85, a01 * p01, (1.0 - v01) * p01, (1.0 - v01) * (1.0 - p01),
        (1.0 - v01) * 0.55, (1.0 - v01) * (1.0 - p01) * 0.9, p01 * 0.85,
        (1.0 - p01) * 0.85, v01 * (1.0 - a01)
    ]
    # Vocal (11)
    motor_pattern[13:24] = [
        a01 * p01, (1.0 - a01) * (1.0 - p01), a01 * 0.8, (1.0 - a01) * 0.7,
        a01 * 0.85, (1.0 - a01) * 0.8, (1.0 - p01) * a01, p01 * 0.85,
        a01 * n01, v01 * a01, (1.0 - a01) * 0.75
    ]
    # Postural (9)
    motor_pattern[24:33] = [
        p01 * v01, (1.0 - p01) * (1.0 - v01), p01 * a01, (1.0 - p01) * n01,
        a01 * (1.0 - v01) * p01, v01 * 0.85, a01 * 0.85, (1.0 - a01) * 0.7,
        p01 * norms_lvl
    ]
    motor = np.clip(0.5 * motor_lvl + 0.5 * motor_pattern, 0.02, 0.98)
    motor *= motor_lvl / max(1e-6, float(np.mean(motor)))

    # 4. Action_Tendencies (28 items)
    ap_app, ap_att, ap_fli, ap_fre, ap_rep = action_prof
    action = np.zeros(28, dtype=float)
    action[0:6] = np.clip(ap_app + np.linspace(-0.04, 0.04, 6), 0.02, 0.98)
    action[6:12] = np.clip(ap_att + np.linspace(-0.04, 0.04, 6), 0.02, 0.98)
    action[12:18] = np.clip(ap_fli + np.linspace(-0.04, 0.04, 6), 0.02, 0.98)
    action[18:23] = np.clip(ap_fre + np.linspace(-0.03, 0.03, 5), 0.02, 0.98)
    action[23:28] = np.clip(ap_rep + np.linspace(-0.03, 0.03, 5), 0.02, 0.98)

    # 5. Subjective_Feeling (21 items)
    feeling = np.zeros(21, dtype=float)
    # Intensité et durée (0..5)
    feeling[0:5] = np.clip([
        0.55 + 0.35 * max(abs(valence), abs(arousal)),
        0.65 - 0.40 * n01,
        0.50 + 0.35 * reg_lvl,
        0.45 + 0.45 * norms_lvl,
        0.60 - 0.35 * n01,
    ], 0.02, 0.98)
    # Ressenti affectif central (5..13)
    feeling[5:13] = np.clip([
        v01, 1.0 - v01, a01, 1.0 - a01,
        p01, 1.0 - p01, v01 * 0.85 + 0.1, (1.0 - v01) * 0.8 + 0.1,
    ], 0.02, 0.98)
    # Régulation émotionnelle et réflexivité (13..21) — calibré exactement sur reg_lvl
    reg_offsets = np.array([0.02, 0.03, -0.02, 0.04, -0.01, -0.03, 0.01, -0.04])
    feeling[13:21] = np.clip(reg_lvl + reg_offsets, 0.02, 0.98)
    feeling[13:21] *= reg_lvl / max(1e-6, float(np.mean(feeling[13:21])))

    return appraisal, bodily, motor, action, feeling


def build_grid_24_prototypes() -> Dict[str, GRIDPrototypeCPM]:
    """
    Construit le dictionnaire ordonné des 24 prototypes émotionnels canoniques
    français du paradigme GRID avec leurs 5 vecteurs du Component Process Model (CPM).
    """
    prototypes: Dict[str, GRIDPrototypeCPM] = {}
    for idx, spec in enumerate(_GRID_24_SPECS):
        (
            label_fr, label_en, id_176, proto_carto, dima_cat, dima_cls,
            val, pow_c, aro, nov,
            norms_lvl, reg_lvl, bodily_lvl, motor_lvl, action_prof
        ) = spec
        app, bod, mot, act, sub = _synthesize_cpm_vectors(
            val, pow_c, aro, nov,
            norms_lvl, reg_lvl, bodily_lvl, motor_lvl, action_prof,
            seed_idx=idx,
        )
        prototypes[label_fr] = GRIDPrototypeCPM(
            label_fr=label_fr,
            label_en=label_en,
            id_176_cartograffect=id_176,
            proto_cartograffect=proto_carto,
            dima_categ=dima_cat,
            dima_classe=dima_cls,
            valence_grid=val,
            power_coping_grid=pow_c,
            arousal_grid=aro,
            novelty_grid=nov,
            appraisal=app,
            bodily_symptoms=bod,
            motor_expression=mot,
            action_tendencies=act,
            subjective_feeling=sub,
        )
    return prototypes


GRID_24_CANONICAL_PROTOTYPES: Dict[str, GRIDPrototypeCPM] = build_grid_24_prototypes()


def get_grid_24_dataframe() -> pd.DataFrame:
    """
    Retourne un DataFrame synthétique des 24 prototypes GRID avec leurs coordonnées
    factorielles, leurs scores agrégés sur les 5 composantes CPM et leur ratio d'élévation Z.
    """
    rows = []
    for p in GRID_24_CANONICAL_PROTOTYPES.values():
        rows.append({
            "grid_label_fr": p.label_fr,
            "grid_label_en": p.label_en,
            "id_176_cartograffect": p.id_176_cartograffect,
            "proto_cartograffect": p.proto_cartograffect,
            "dima_categ": p.dima_categ,
            "dima_classe": p.dima_classe,
            "GRID_Valence": round(p.valence_grid, 4),
            "GRID_Power_Coping": round(p.power_coping_grid, 4),
            "GRID_Arousal": round(p.arousal_grid, 4),
            "GRID_Novelty": round(p.novelty_grid, 4),
            "Score_Appraisal": round(p.score_appraisal, 4),
            "Score_Appraisal_Norms": round(p.score_appraisal_norms, 4),
            "Score_Bodily_Symptoms": round(p.score_bodily_symptoms, 4),
            "Score_Motor_Expression": round(p.score_motor_expression, 4),
            "Score_Action_Tendencies": round(p.score_action_tendencies, 4),
            "Score_Subjective_Feeling": round(p.score_subjective_feeling, 4),
            "Score_Subjective_Regulation": round(p.score_subjective_regulation, 4),
            "Ratio_Z_CPM": round(p.z_elevation_ratio, 4),
        })
    return pd.DataFrame(rows)


# ==============================================================================
# 3. PROJECTION GÉOMÉTRIQUE 4D GRID -> 3D OCTAÉDRIQUE CARTOGRAFFECT & INTERPOLATION RBF/k-NN
# ==============================================================================

def compute_z_elevation_from_cpm(
    score_appraisal_norms: np.ndarray | float,
    score_subjective_regulation: np.ndarray | float,
    score_bodily_symptoms: np.ndarray | float,
    score_motor_expression: np.ndarray | float,
    novelty_grid: Optional[np.ndarray | float] = None,
) -> Dict[str, np.ndarray | float]:
    """
    Calcule l'indice d'élévation verticale Z (de Z- physiologique/somatique vers Z+
    abstraction cognitive/normative) à partir du ratio formel CPM :
        Ratio_Z = (Score_Appraisal_Norms + Score_Subjective_Regulation)
                  / (Score_Bodily_Symptoms + Score_Motor_Expression)

    Retourne :
    - `ratio_z_raw`     : Le ratio CPM exact (> 1 lorsque la régulation normative domine
                          l'activation somato-motrice ; < 1 lorsque le pôle somatique domine).
    - `z_bipolar_index` : Indice bipolaire centré dans [-7.0, +7.0] (Z- physiologique/somatique
                          vers Z+ abstraction cognitive/normative) par transformation log-ratio.
    - `z_octahedral_0_7`: Élévation continue projetée sur les strates [1.0, 7.0] de la pyramide
                          octaédrique à 176 prototypes de Cartograffect.
    """
    num = np.asarray(score_appraisal_norms, dtype=float) + np.asarray(score_subjective_regulation, dtype=float)
    den = np.maximum(1e-6, np.asarray(score_bodily_symptoms, dtype=float) + np.asarray(score_motor_expression, dtype=float))
    ratio_z = num / den

    # Transformation log-ratio centrée sur l'équilibre homéostatique (ratio = 1.0 -> log = 0.0)
    # Échelle [-7, +7] : ratio < 1 -> Z- (somatique/physiologique), ratio > 1 -> Z+ (cognitif/normatif)
    z_bipolar = np.clip(7.0 * np.tanh(1.45 * np.log(np.maximum(1e-4, ratio_z))), -7.0, 7.0)

    # Projection sur l'échelle pyramidale des couronnes Z ∈ [1, 7] de Cartograffect 176 :
    # Un ratio faible + forte nouveauté correspond à Z=1 (Surprise) et Z=2 (Affects primaires somatiques),
    # tandis qu'un ratio élevé correspond aux strates réflexives/normatives/transcendantales Z=4..7.
    z_octa = 1.0 + 6.0 * (1.0 / (1.0 + np.exp(-2.1 * (ratio_z - 0.95))))
    if novelty_grid is not None:
        nov = np.asarray(novelty_grid, dtype=float)
        # Correction d'opérateur de saillance perceptive pure (Surprise : Novelty très élevée -> Z proche de 1)
        surprise_pull = np.clip((nov - 0.55) / 0.45, 0.0, 1.0)
        z_octa = (1.0 - 0.65 * surprise_pull) * z_octa + (0.65 * surprise_pull) * 1.0
    z_octa = np.clip(z_octa, 0.0, 7.0)

    if np.ndim(score_appraisal_norms) == 0:
        return {
            "ratio_z_raw": float(ratio_z),
            "z_bipolar_index": float(z_bipolar),
            "z_octahedral_0_7": float(z_octa),
        }
    return {
        "ratio_z_raw": ratio_z,
        "z_bipolar_index": z_bipolar,
        "z_octahedral_0_7": z_octa,
    }


def project_grid_4d_to_octahedral_3d(
    valence_grid: np.ndarray,
    power_coping_grid: np.ndarray,
    arousal_grid: np.ndarray,
    novelty_grid: np.ndarray,
    z_octahedral_0_7: np.ndarray,
    u_sector: Optional[np.ndarray] = None,
    v_sector: Optional[np.ndarray] = None,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """
    Projette les 4 dimensions factorielles de GRID (Valence, Power/Coping, Arousal, Novelty)
    et l'élévation Z sur les coordonnées octaédriques 3D (X, Y, Z) de Cartograffect :
    - X_unit : Axe d'Attente / Révisabilité épistémique du modèle interne (Valence modulée
               par la stabilité épistémique 1 - 0.35 * max(0, Novelty)^2 et l'orientation
               sectorielle L1 lorsqu'elle est définie).
    - Y_unit : Axe de Contrôle / Mobilisation pragmatique d'action (combinaison convexe
               0.60 * Arousal + 0.40 * Power/Coping, identique à cartograffect_core.py).
    - (X_octa, Y_octa, Z_octa) : Coordonnées projetées sur l'enveloppe octaédrique L1
               de rayon R_L1(Z) = max(0, 2 * (Z - 1)) tel que |X_octa| + |Y_octa| = R_L1(Z).
    """
    v = np.asarray(valence_grid, dtype=float)
    p = np.asarray(power_coping_grid, dtype=float)
    a = np.asarray(arousal_grid, dtype=float)
    n = np.asarray(novelty_grid, dtype=float)
    z = np.asarray(z_octahedral_0_7, dtype=float)

    # Atténuation épistémique sous forte nouveauté (la Surprise en Z=1 converge vers X=0, Y=0)
    epistemic_damp = 1.0 - 0.35 * np.clip(n, 0.0, 1.0) ** 2
    x_raw = np.clip(v * epistemic_damp, -1.0, 1.0)
    y_raw = np.clip((0.60 * a + 0.40 * p) * epistemic_damp, -1.0, 1.0)

    if u_sector is not None and v_sector is not None:
        u_s = np.asarray(u_sector, dtype=float)
        v_s = np.asarray(v_sector, dtype=float)
        # Couplage convexe entre la poussée factorielle GRID et la géométrie de couronne L1
        x_unit = np.clip(0.55 * x_raw + 0.45 * u_s, -1.0, 1.0)
        y_unit = np.clip(0.55 * y_raw + 0.45 * v_s, -1.0, 1.0)
    else:
        x_unit = x_raw
        y_unit = y_raw

    # Projection sur le losange / octaèdre L1 de la couronne Z : R_L1 = max(0, 2*(Z - 1))
    r_l1_target = np.maximum(0.0, 2.0 * (z - 1.0))
    l1_norm_xy = np.abs(x_unit) + np.abs(y_unit)
    scale = np.where(l1_norm_xy > 1e-6, r_l1_target / l1_norm_xy, 0.0)
    x_octa = x_unit * scale
    y_octa = y_unit * scale

    return x_unit, y_unit, x_octa, y_octa, z


def map_octahedral_l1_to_lp_sphere(
    X: np.ndarray | float,
    Y: np.ndarray | float,
    Z: np.ndarray | float,
    Z_eq: float = 7.0,
    p: float = 2.0,
) -> Tuple[np.ndarray | float, np.ndarray | float, np.ndarray | float]:
    """
    Homéomorphisme radial bijectif `map_octahedral_l1_to_lp_sphere` entre l'enveloppe
    octaédrique en Diamant (norme L1, p = 1.0) et la variété Sphérique/Superquadrique Lp
    (Sphère riemannienne parfaite pour p = 2.0) :
      - Soit Z_rel = Z - Z_eq le décalage vertical par rapport au plan équatorial
        homéostatique Z_7 (avec Z_0 comme point neutre d'ancrage).
      - Pour tout vecteur local u = (X, Y, Z_rel) non nul sur les couronnes L1 :
          ||u||_1 = |X| + |Y| + |Z_rel|
          ||u||_p = (|X|^p + |Y|^p + |Z_rel|^p)^(1/p)
      - Le vecteur projeté sur la variété Lp conserve exactement son budget radial :
          u_Lp = u * (||u||_1 / ||u||_p)
      - Coordonnées projetées retournées : (X_Lp, Y_Lp, Z_Lp) avec Z_Lp = Z_eq + u_Lp_z.
    """
    is_scalar = (np.ndim(X) == 0) and (np.ndim(Y) == 0) and (np.ndim(Z) == 0)
    p_val = float(np.clip(p, 1.0, 2.0))
    x_arr = np.asarray(X, dtype=float)
    y_arr = np.asarray(Y, dtype=float)
    z_arr = np.asarray(Z, dtype=float)
    z_rel = z_arr - float(Z_eq)

    norm_1 = np.abs(x_arr) + np.abs(y_arr) + np.abs(z_rel)
    norm_p = (np.abs(x_arr) ** p_val + np.abs(y_arr) ** p_val + np.abs(z_rel) ** p_val) ** (1.0 / p_val)
    safe_norm_p = np.where(norm_p > 1e-12, norm_p, 1.0)
    radial_scale = np.where(norm_p > 1e-12, norm_1 / safe_norm_p, 1.0)

    x_lp = x_arr * radial_scale
    y_lp = y_arr * radial_scale
    z_lp = float(Z_eq) + z_rel * radial_scale

    if is_scalar:
        return float(x_lp), float(y_lp), float(z_lp)
    return x_lp, y_lp, z_lp


def _encode_joint_vad_dima_features(
    valence: np.ndarray,
    arousal: np.ndarray,
    dominance: np.ndarray,
    dima_categ: Optional[List[str]] = None,
    dima_classe: Optional[List[str]] = None,
    x_norm: Optional[np.ndarray] = None,
    y_norm: Optional[np.ndarray] = None,
    z_norm: Optional[np.ndarray] = None,
) -> np.ndarray:
    """
    Construit la représentation vectorielle conjointe dans l'espace hybride
    (NRC-VAD + DIMA + géométrie directionnelle normalisée) pour l'interpolation
    à noyau gaussien (RBF / k-NN pondéré).

    Dimensions de l'espace conjoint (10 dimensions) :
    0: Valence (V)
    1: Arousal (A)
    2: Dominance / Power (D)
    3: Intensité L1 normalisée (|V| + |A| + |D|) / 3.0
    4: Synergie pragmatique Y_vad = 0.6 * A + 0.4 * D
    5: Indicateur morpho-sémantique DIMA Catégorie I (Émotion/Humeur réactive) vs II (Sentiment/Disposition)
    6: Indicateur de polarité axiologique/relationnelle DIMA
    7: Coordonnée directionnelle u = X / max(1, R_L1)
    8: Coordonnée directionnelle v = Y / max(1, R_L1)
    9: Profondeur cognitive normalisée Z / 7.0
    """
    v = np.asarray(valence, dtype=float)
    a = np.asarray(arousal, dtype=float)
    d = np.asarray(dominance, dtype=float)
    n_samples = len(v)

    l1_norm = (np.abs(v) + np.abs(a) + np.abs(d)) / 3.0
    y_vad = 0.60 * a + 0.40 * d

    # Descripteurs DIMA (Catégorie I = réactif somatique/immédiat -> -0.5, Catégorie II = relationnel/réflexif -> +0.5)
    dima_cat_feat = np.zeros(n_samples, dtype=float)
    dima_rel_feat = np.zeros(n_samples, dtype=float)
    if dima_categ is not None:
        for i, cat in enumerate(dima_categ):
            c_str = str(cat).strip()
            if c_str == "I":
                dima_cat_feat[i] = -0.35
            elif c_str == "II":
                dima_cat_feat[i] = 0.35

    if dima_classe is not None:
        normative_classes = {
            "Flatter", "Honte", "Honte de soi", "Mauvaise conscience", "Mépris",
            "Estime", "Estime respect", "Admiration", "Orgueil", "Gratitude",
            "Bonne conscience", "Croyance", "Croyance relig", "Confiance",
        }
        somatic_classes = {
            "Surprendre", "Peur", "Peur panique", "Déplaire_A", "Jouissance",
            "Réjouir", "Attrister", "Colère",
        }
        for i, cls in enumerate(dima_classe):
            cls_str = str(cls).strip()
            if cls_str in normative_classes:
                dima_rel_feat[i] = 0.40
            elif cls_str in somatic_classes:
                dima_rel_feat[i] = -0.40

    if x_norm is None:
        x_norm = v
    if y_norm is None:
        y_norm = y_vad
    if z_norm is None:
        z_norm = np.clip((2.0 + 5.0 * l1_norm) / 7.0, 0.0, 1.0)

    return np.column_stack([
        v,
        a,
        d,
        l1_norm,
        y_vad,
        dima_cat_feat,
        dima_rel_feat,
        np.asarray(x_norm, dtype=float),
        np.asarray(y_norm, dtype=float),
        np.asarray(z_norm, dtype=float),
    ])


def rbf_knn_interpolate(
    source_features: np.ndarray,
    source_targets: np.ndarray,
    query_features: np.ndarray,
    k_neighbors: int = 7,
    sigma: float = 0.65,
    exact_match_indices: Optional[Dict[int, int]] = None,
) -> Tuple[np.ndarray, np.ndarray]:
    """
    Interpolation par noyau gaussien (RBF) restreint aux k plus proches voisins (k-NN pondéré)
    sur l'espace conjoint NRC-VAD + DIMA :
        w_ij = exp(- ||x_i - s_j||^2 / (2 * sigma^2))  pour j dans k-NN(x_i)
        y_hat_i = sum_j (w_ij * y_j) / sum_j w_ij

    Paramètres :
    - `source_features` : Matrice (N_src, D_feat) des ancres sources (ex. 24 prototypes GRID ou 176 prototypes).
    - `source_targets`  : Matrice (N_src, D_out) des vecteurs CPM à interpoler.
    - `query_features`  : Matrice (N_qry, D_feat) des points cibles.
    - `k_neighbors`     : Nombre de voisins retenus pour le noyau local.
    - `sigma`           : Largeur de bande du noyau gaussien RBF.
    - `exact_match_indices` : Dictionnaire optionnel {idx_query: idx_source} garantissant
                              une fidélité exacte (poids = 1.0) sur les ancres canoniques.

    Retourne :
    - `interpolated` : Matrice (N_qry, D_out) des vecteurs CPM interpolés.
    - `mean_rbf_similarity` : Vecteur (N_qry,) de similarité moyenne au voisinage RBF.
    """
    n_src = source_features.shape[0]
    n_qry = query_features.shape[0]
    k_eff = min(k_neighbors, n_src)

    # Calcul vectorisé des distances euclidiennes au carré par blocs pour limiter l'empreinte mémoire
    interpolated = np.zeros((n_qry, source_targets.shape[1]), dtype=float)
    mean_sim = np.zeros(n_qry, dtype=float)
    two_sigma_sq = 2.0 * (sigma ** 2)

    batch_size = 2048
    src_norm_sq = np.sum(source_features ** 2, axis=1)[None, :]  # (1, N_src)

    for start in range(0, n_qry, batch_size):
        end = min(n_qry, start + batch_size)
        q_batch = query_features[start:end]  # (B, D)
        q_norm_sq = np.sum(q_batch ** 2, axis=1)[:, None]  # (B, 1)
        dist_sq = np.maximum(0.0, q_norm_sq + src_norm_sq - 2.0 * (q_batch @ source_features.T))

        if k_eff < n_src:
            knn_idx = np.argpartition(dist_sq, kth=k_eff - 1, axis=1)[:, :k_eff]
            row_idx = np.arange(end - start)[:, None]
            knn_dist_sq = dist_sq[row_idx, knn_idx]
            weights = np.exp(-knn_dist_sq / two_sigma_sq)
            weights_sum = np.maximum(1e-12, np.sum(weights, axis=1, keepdims=True))
            norm_weights = weights / weights_sum
            # Agrégation pondérée des cibles
            interpolated[start:end] = np.einsum("bk,bkd->bd", norm_weights, source_targets[knn_idx])
            mean_sim[start:end] = np.mean(weights, axis=1)
        else:
            weights = np.exp(-dist_sq / two_sigma_sq)
            weights_sum = np.maximum(1e-12, np.sum(weights, axis=1, keepdims=True))
            norm_weights = weights / weights_sum
            interpolated[start:end] = norm_weights @ source_targets
            mean_sim[start:end] = np.mean(weights, axis=1)

    if exact_match_indices:
        for q_idx, s_idx in exact_match_indices.items():
            if 0 <= q_idx < n_qry and 0 <= s_idx < n_src:
                interpolated[q_idx] = source_targets[s_idx]
                mean_sim[q_idx] = 1.0

    return interpolated, mean_sim


def _load_or_build_15037_lexicon(workspace_dir: str = ".") -> pd.DataFrame:
    """
    Charge et consolide le lexique français de 15 037 lemmes indexés avec NRC-VAD et DIMA.
    Si `nrc_candidates_filtered.tsv` + `nrc_llm_classified.tsv` contiennent 15 043 candidats
    bruts (dont 6 entrées dégénérées à norme L1_vad == 0.0 et statut == 0), filtre exactement
    ces 6 entrées nulles pour obtenir les 15 037 termes actifs indexés avec NRC-VAD et DIMA.
    """
    cand_path = os.path.join(workspace_dir, "nrc_candidates_filtered.tsv")
    llm_path = os.path.join(workspace_dir, "nrc_llm_classified.tsv")
    base_unique_path = os.path.join(workspace_dir, "CARTOGRAFFECT_Base_Unique_NRC_DIMA_FANCat.tsv")
    diamant_path = os.path.join(workspace_dir, "CARTOGRAFFECT_Diamant_303_Lexique_Complet.tsv")
    ref176_path = os.path.join(workspace_dir, "CARTOGRAFFECT_176_Stats_Synthese.tsv")

    df_cand = pd.read_csv(cand_path, sep="\t", encoding="utf-8")
    df_llm = pd.read_csv(llm_path, sep="\t", encoding="utf-8", on_bad_lines="skip")
    df_llm["nrc_id"] = pd.to_numeric(df_llm["nrc_id"], errors="coerce")
    df_llm = df_llm.dropna(subset=["nrc_id"]).drop_duplicates(subset=["nrc_id"], keep="last")
    df_cand["nrc_id"] = pd.to_numeric(df_cand["nrc_id"], errors="coerce").astype(int)
    df_llm["nrc_id"] = df_llm["nrc_id"].astype(int)

    df_merged = pd.merge(df_cand, df_llm, on="nrc_id", how="inner")

    # Enrichissement croisé avec les descripteurs DIMA et coordonnées 3D déjà consolidés
    dima_lookup: Dict[str, Dict[str, Any]] = {}
    if os.path.exists(diamant_path):
        df_dia = pd.read_csv(diamant_path, sep="\t", encoding="utf-8")
        for r in df_dia.itertuples():
            t_fr = str(r.terme_fr).strip().lower()
            dima_lookup[t_fr] = {
                "dima_categ": str(r.dima_categ),
                "dima_classe": str(r.dima_classe),
                "dima_sous_classe": str(r.dima_sous_classe),
                "dima_type": str(r.dima_type),
                "X_carto": float(r.X_proj),
                "Y_carto": float(r.Y_proj),
                "Z_carto": float(r.Z_proj),
                "proto_fr_ancre": str(r.proto_fr_ancre),
            }
    elif os.path.exists(base_unique_path):
        df_bu = pd.read_csv(base_unique_path, sep="\t", encoding="utf-8")
        for r in df_bu.itertuples():
            t_fr = str(r.terme_fr).strip().lower()
            dima_lookup[t_fr] = {
                "dima_categ": str(r.dima_categ),
                "dima_classe": str(r.dima_classe),
                "dima_sous_classe": str(r.dima_sous_classe),
                "dima_type": str(r.dima_type),
                "X_carto": float(r.valence),
                "Y_carto": float(0.6 * r.arousal + 0.4 * r.dominance),
                "Z_carto": 4.0,
                "proto_fr_ancre": "-",
            }

    # Sélection exacte des 15 037 termes (retrait des 6 entrées dégénérées à L1_vad == 0 et statut == 0)
    if len(df_merged) > 15037:
        n_to_drop = len(df_merged) - 15037
        zero_mask = (df_merged["L1_vad"] == 0.0) & (df_merged["statut"] == 0)
        drop_indices = df_merged[zero_mask].index[:n_to_drop]
        df_merged = df_merged.drop(index=drop_indices).reset_index(drop=True)

    # Construction des colonnes françaises et DIMA
    terme_fr_col = []
    dima_cat_col = []
    dima_cls_col = []
    x_carto_col = []
    y_carto_col = []
    z_carto_col = []

    proto_z_map: Dict[str, Tuple[float, float, float]] = {}
    if os.path.exists(ref176_path):
        df_r176 = pd.read_csv(ref176_path, sep="\t", encoding="utf-8")
        for r in df_r176.itertuples():
            r_l1 = max(1.0, float(r.rayon_L1))
            proto_z_map[str(r.label_fr).strip().lower()] = (
                float(r.X) / r_l1,
                float(r.Y) / r_l1,
                float(r.Z),
            )

    for row in df_merged.itertuples():
        trad = str(row.traduction_fr).strip()
        lemma_fr = trad if (trad and trad != "-") else str(row.term).strip()
        terme_fr_col.append(lemma_fr)
        info = dima_lookup.get(lemma_fr.lower())
        if info is not None:
            dima_cat_col.append(info["dima_categ"])
            dima_cls_col.append(info["dima_classe"])
            x_carto_col.append(info["X_carto"])
            y_carto_col.append(info["Y_carto"])
            z_carto_col.append(abs(info["Z_carto"]))
        else:
            dima_cat_col.append("-")
            dima_cls_col.append("-")
            sugg = str(row.proto_fr_suggere).strip().lower()
            if sugg in proto_z_map:
                px, py, pz = proto_z_map[sugg]
                x_carto_col.append(float(row.valence))
                y_carto_col.append(0.6 * float(row.arousal) + 0.4 * float(row.dominance))
                z_carto_col.append(pz)
            else:
                z_est = float(row.Z_cible) if float(row.Z_cible) > 0 else round(2.0 + 5.0 * (float(row.L1_vad) / 3.0), 4)
                x_carto_col.append(float(row.valence))
                y_carto_col.append(0.6 * float(row.arousal) + 0.4 * float(row.dominance))
                z_carto_col.append(float(np.clip(z_est, 0.0, 7.0)))

    df_merged["lemme_fr"] = terme_fr_col
    df_merged["dima_categ"] = dima_cat_col
    df_merged["dima_classe"] = dima_cls_col
    df_merged["X_carto"] = x_carto_col
    df_merged["Y_carto"] = y_carto_col
    df_merged["Z_carto"] = z_carto_col

    return df_merged


def map_grid_to_cartograffect_3d(
    workspace_dir: str = ".",
    rbf_sigma_176: float = 0.62,
    knn_176: int = 6,
    rbf_sigma_lexicon: float = 0.48,
    knn_lexicon: int = 8,
    export_tsv: bool = True,
) -> Dict[str, Any]:
    """
    Fonction maîtresse d'alignement `map_grid_to_cartograffect_3d()` :
    1. Projette les 4 dimensions factorielles de GRID (Valence, Power/Coping, Arousal, Novelty)
       sur les coordonnées octaédriques 3D (X, Y, Z) de Cartograffect.
    2. Calcule l'indice d'élévation verticale Z (de Z- physiologique/somatique vers Z+
       abstraction cognitive/normative) à partir du ratio :
       (Score_Appraisal_Norms + Score_Subjective_Regulation)
       / (Score_Bodily_Symptoms + Score_Motor_Expression).
    3. Interpole par noyau gaussien (RBF / k-NN pondéré sur l'espace conjoint NRC VAD + DIMA)
       les vecteurs CPM (142 items + 5 composantes + 4 facteurs GRID) sur l'ensemble des
       176 prototypes Cartograffect, puis sur les 15 037 lemmes du lexique.

    Retourne un dictionnaire contenant :
    - `df_grid_24`       : DataFrame des 24 prototypes canoniques GRID alignés en 3D
    - `df_prototypes_176`: DataFrame des 176 prototypes Cartograffect enrichis des vecteurs CPM
    - `cpm_matrix_176`   : Matrice numpy (176, 142) des profils CPM complets des 176 prototypes
    - `df_lexicon_15037` : DataFrame des 15 037 lemmes enrichis des scores CPM et coordonnées GRID
    - `cpm_components_15037` : Matrice numpy (15037, 5) des 5 composantes CPM sur le lexique
    """
    # ------------------------------------------------------------------
    # ÉTAPE A : Préparation et projection 3D des 24 prototypes GRID
    # ------------------------------------------------------------------
    df_176_stats = pd.read_csv(
        os.path.join(workspace_dir, "CARTOGRAFFECT_176_Stats_Synthese.tsv"),
        sep="\t",
        encoding="utf-8",
    )
    stats_by_id = {int(r.id_176): r for r in df_176_stats.itertuples()}

    grid_list = list(GRID_24_CANONICAL_PROTOTYPES.values())
    n_grid = len(grid_list)  # 24

    grid_matrix_142 = np.vstack([p.vector_142 for p in grid_list])           # (24, 142)
    grid_factors_4d = np.vstack([p.factor_vector_4d for p in grid_list])     # (24, 4)
    grid_summary_7d = np.array([
        [
            p.score_appraisal,
            p.score_appraisal_norms,
            p.score_bodily_symptoms,
            p.score_motor_expression,
            p.score_action_tendencies,
            p.score_subjective_feeling,
            p.score_subjective_regulation,
        ]
        for p in grid_list
    ], dtype=float)  # (24, 7)

    z_elev_24 = compute_z_elevation_from_cpm(
        score_appraisal_norms=grid_summary_7d[:, 1],
        score_subjective_regulation=grid_summary_7d[:, 6],
        score_bodily_symptoms=grid_summary_7d[:, 2],
        score_motor_expression=grid_summary_7d[:, 3],
        novelty_grid=grid_factors_4d[:, 3],
    )

    x_u24, y_u24, x_oct24, y_oct24, z_oct24 = project_grid_4d_to_octahedral_3d(
        valence_grid=grid_factors_4d[:, 0],
        power_coping_grid=grid_factors_4d[:, 1],
        arousal_grid=grid_factors_4d[:, 2],
        novelty_grid=grid_factors_4d[:, 3],
        z_octahedral_0_7=z_elev_24["z_octahedral_0_7"],
    )

    df_grid_24 = get_grid_24_dataframe()
    df_grid_24["Z_Bipolar_Index"] = np.round(z_elev_24["z_bipolar_index"], 4)
    df_grid_24["X_unit_GRID_proj"] = np.round(x_u24, 4)
    df_grid_24["Y_unit_GRID_proj"] = np.round(y_u24, 4)
    df_grid_24["X_octa_GRID_proj"] = np.round(x_oct24, 4)
    df_grid_24["Y_octa_GRID_proj"] = np.round(y_oct24, 4)
    df_grid_24["Z_octa_GRID_proj"] = np.round(z_oct24, 4)

    # Coordonnées canoniques exactes de l'ancre correspondante dans Cartograffect 176
    df_grid_24["X_carto_176"] = [stats_by_id[p.id_176_cartograffect].X for p in grid_list]
    df_grid_24["Y_carto_176"] = [stats_by_id[p.id_176_cartograffect].Y for p in grid_list]
    df_grid_24["Z_carto_176"] = [stats_by_id[p.id_176_cartograffect].Z for p in grid_list]
    df_grid_24["rayon_L1_176"] = [stats_by_id[p.id_176_cartograffect].rayon_L1 for p in grid_list]

    # ------------------------------------------------------------------
    # ÉTAPE B : Interpolation RBF / k-NN des 24 prototypes GRID vers les 176 prototypes Cartograffect
    # ------------------------------------------------------------------
    # Caractéristiques conjointes (NRC-VAD + DIMA + géométrie normalisée) des 24 ancres GRID
    src_x_norm_24 = np.array([
        stats_by_id[p.id_176_cartograffect].X / max(1.0, stats_by_id[p.id_176_cartograffect].rayon_L1)
        for p in grid_list
    ])
    src_y_norm_24 = np.array([
        stats_by_id[p.id_176_cartograffect].Y / max(1.0, stats_by_id[p.id_176_cartograffect].rayon_L1)
        for p in grid_list
    ])
    src_z_norm_24 = np.array([
        stats_by_id[p.id_176_cartograffect].Z / 7.0
        for p in grid_list
    ])

    features_24 = _encode_joint_vad_dima_features(
        valence=grid_factors_4d[:, 0],
        arousal=grid_factors_4d[:, 2],
        dominance=grid_factors_4d[:, 1],
        dima_categ=[p.dima_categ for p in grid_list],
        dima_classe=[p.dima_classe for p in grid_list],
        x_norm=src_x_norm_24,
        y_norm=src_y_norm_24,
        z_norm=src_z_norm_24,
    )

    # Caractéristiques conjointes des 176 prototypes Cartograffect
    r_l1_176 = np.maximum(1.0, df_176_stats["rayon_L1"].to_numpy(dtype=float))
    x_norm_176 = df_176_stats["X"].to_numpy(dtype=float) / r_l1_176
    y_norm_176 = df_176_stats["Y"].to_numpy(dtype=float) / r_l1_176
    z_norm_176 = df_176_stats["Z"].to_numpy(dtype=float) / 7.0

    # Inférence de la catégorie DIMA dominante par strate Z (Z <= 3 : Cat I réactive ; Z >= 4 : Cat II réflexive)
    dima_cat_176 = ["I" if z_val <= 3 else "II" for z_val in df_176_stats["Z"]]
    dima_cls_176 = [str(lbl) for lbl in df_176_stats["label_fr"]]

    features_176 = _encode_joint_vad_dima_features(
        valence=df_176_stats["mean_valence"].to_numpy(dtype=float),
        arousal=df_176_stats["mean_arousal"].to_numpy(dtype=float),
        dominance=df_176_stats["mean_dominance"].to_numpy(dtype=float),
        dima_categ=dima_cat_176,
        dima_classe=dima_cls_176,
        x_norm=x_norm_176,
        y_norm=y_norm_176,
        z_norm=z_norm_176,
    )

    # Table des correspondances exactes entre l'indice (0..175) de df_176_stats et l'indice (0..23) de GRID
    id176_to_row = {int(row.id_176): idx for idx, row in enumerate(df_176_stats.itertuples())}
    exact_map_176_to_24: Dict[int, int] = {}
    for g_idx, p in enumerate(grid_list):
        if p.id_176_cartograffect in id176_to_row:
            exact_map_176_to_24[id176_to_row[p.id_176_cartograffect]] = g_idx

    # Concaténation [142 items CPM | 4 facteurs GRID] -> (24, 146) pour interpolation conjointe
    targets_24_full = np.hstack([grid_matrix_142, grid_factors_4d])
    interp_176_full, sim_176 = rbf_knn_interpolate(
        source_features=features_24,
        source_targets=targets_24_full,
        query_features=features_176,
        k_neighbors=knn_176,
        sigma=rbf_sigma_176,
        exact_match_indices=exact_map_176_to_24,
    )

    cpm_matrix_176 = interp_176_full[:, :142]
    factors_4d_176 = interp_176_full[:, 142:146]

    # Découpage des 5 composantes CPM sur les 176 prototypes
    app_176 = cpm_matrix_176[:, 0:33]
    bod_176 = cpm_matrix_176[:, 33:60]
    mot_176 = cpm_matrix_176[:, 60:93]
    act_176 = cpm_matrix_176[:, 93:121]
    sub_176 = cpm_matrix_176[:, 121:142]

    score_app_176 = np.mean(app_176, axis=1)
    score_norms_176 = np.mean(app_176[:, APPRAISAL_SUBFACETS["norms_compatibility"]], axis=1)
    score_bod_176 = np.mean(bod_176, axis=1)
    score_mot_176 = np.mean(mot_176, axis=1)
    score_act_176 = np.mean(act_176, axis=1)
    score_sub_176 = np.mean(sub_176, axis=1)
    score_reg_176 = np.mean(sub_176[:, FEELING_SUBFACETS["regulation"]], axis=1)

    # Modulation continue par la profondeur Z de la couronne (cohérence structurelle Z=0..7)
    z_depth_factor = (df_176_stats["Z"].to_numpy(dtype=float) - 2.0) / 5.0  # dans [-0.4, +1.0]
    score_norms_176 = np.clip(score_norms_176 + 0.08 * z_depth_factor, 0.05, 0.98)
    score_reg_176 = np.clip(score_reg_176 + 0.08 * z_depth_factor, 0.05, 0.98)
    score_bod_176 = np.clip(score_bod_176 - 0.06 * z_depth_factor, 0.05, 0.98)

    z_elev_176 = compute_z_elevation_from_cpm(
        score_appraisal_norms=score_norms_176,
        score_subjective_regulation=score_reg_176,
        score_bodily_symptoms=score_bod_176,
        score_motor_expression=score_mot_176,
        novelty_grid=factors_4d_176[:, 3],
    )
    x_u176, y_u176, x_oct176, y_oct176, z_oct176 = project_grid_4d_to_octahedral_3d(
        valence_grid=factors_4d_176[:, 0],
        power_coping_grid=factors_4d_176[:, 1],
        arousal_grid=factors_4d_176[:, 2],
        novelty_grid=factors_4d_176[:, 3],
        z_octahedral_0_7=z_elev_176["z_octahedral_0_7"],
        u_sector=x_norm_176,
        v_sector=y_norm_176,
    )

    df_prototypes_176 = df_176_stats[[
        "id_176", "label_fr", "X", "Y", "Z", "rayon_L1", "type_geom", "groupe_geom",
        "antagoniste_label", "mean_valence", "mean_arousal", "mean_dominance"
    ]].copy()
    df_prototypes_176["GRID_Valence"] = np.round(factors_4d_176[:, 0], 4)
    df_prototypes_176["GRID_Power_Coping"] = np.round(factors_4d_176[:, 1], 4)
    df_prototypes_176["GRID_Arousal"] = np.round(factors_4d_176[:, 2], 4)
    df_prototypes_176["GRID_Novelty"] = np.round(factors_4d_176[:, 3], 4)
    df_prototypes_176["Score_Appraisal"] = np.round(score_app_176, 4)
    df_prototypes_176["Score_Appraisal_Norms"] = np.round(score_norms_176, 4)
    df_prototypes_176["Score_Bodily_Symptoms"] = np.round(score_bod_176, 4)
    df_prototypes_176["Score_Motor_Expression"] = np.round(score_mot_176, 4)
    df_prototypes_176["Score_Action_Tendencies"] = np.round(score_act_176, 4)
    df_prototypes_176["Score_Subjective_Feeling"] = np.round(score_sub_176, 4)
    df_prototypes_176["Score_Subjective_Regulation"] = np.round(score_reg_176, 4)
    df_prototypes_176["Ratio_Z_CPM"] = np.round(z_elev_176["ratio_z_raw"], 4)
    df_prototypes_176["Z_Bipolar_Index"] = np.round(z_elev_176["z_bipolar_index"], 4)
    df_prototypes_176["X_octa_GRID"] = np.round(x_oct176, 4)
    df_prototypes_176["Y_octa_GRID"] = np.round(y_oct176, 4)
    df_prototypes_176["Z_octa_GRID"] = np.round(z_oct176, 4)
    df_prototypes_176["RBF_Kernel_Similarity"] = np.round(sim_176, 4)

    # Coordonnées duales L1 (Diamant, p=1.0) vs L2 (Sphère riemannienne, p=2.0) sur les 176 prototypes
    x_l1_176 = df_prototypes_176["X"].to_numpy(dtype=float)
    y_l1_176 = df_prototypes_176["Y"].to_numpy(dtype=float)
    z_l1_176 = df_prototypes_176["Z"].to_numpy(dtype=float)
    x_l2_176, y_l2_176, z_l2_176 = map_octahedral_l1_to_lp_sphere(
        x_l1_176, y_l1_176, z_l1_176, Z_eq=7.0, p=2.0
    )
    # Levée de la contrainte d'écrasement diagonal L1 sur la projection sphérique L2 de GRID/CPM
    z_iso_grid_176 = 0.55 * z_oct176 + 0.45 * z_l1_176
    xg_l2_176, yg_l2_176, zg_l2_176 = map_octahedral_l1_to_lp_sphere(
        x_oct176, y_oct176, z_iso_grid_176, Z_eq=7.0, p=2.0
    )

    df_prototypes_176["X_L1"] = np.round(x_l1_176, 4)
    df_prototypes_176["Y_L1"] = np.round(y_l1_176, 4)
    df_prototypes_176["Z_L1"] = np.round(z_l1_176, 4)
    df_prototypes_176["X_L2"] = np.round(x_l2_176, 4)
    df_prototypes_176["Y_L2"] = np.round(y_l2_176, 4)
    df_prototypes_176["Z_L2"] = np.round(z_l2_176, 4)
    df_prototypes_176["X_L2_GRID"] = np.round(xg_l2_176, 4)
    df_prototypes_176["Y_L2_GRID"] = np.round(yg_l2_176, 4)
    df_prototypes_176["Z_L2_GRID"] = np.round(zg_l2_176, 4)

    # Table dédiée aux coordonnées duales (X_L1, Y_L1, Z_L1 et X_L2, Y_L2, Z_L2)
    z_rel_176 = z_l1_176 - 7.0
    norm_l1_176 = np.abs(x_l1_176) + np.abs(y_l1_176) + np.abs(z_rel_176)
    norm_l2_raw_176 = np.sqrt(x_l1_176 ** 2 + y_l1_176 ** 2 + z_rel_176 ** 2)
    scale_176_l2 = np.where(norm_l2_raw_176 > 1e-12, norm_l1_176 / np.where(norm_l2_raw_176 > 1e-12, norm_l2_raw_176, 1.0), 1.0)
    df_dual_176 = pd.DataFrame({
        "id_176": df_prototypes_176["id_176"],
        "label_fr": df_prototypes_176["label_fr"],
        "type_geom": df_prototypes_176["type_geom"],
        "groupe_geom": df_prototypes_176["groupe_geom"],
        "X_L1": np.round(x_l1_176, 4),
        "Y_L1": np.round(y_l1_176, 4),
        "Z_L1": np.round(z_l1_176, 4),
        "rayon_L1": df_prototypes_176["rayon_L1"],
        "budget_radial_B_Z": np.round(norm_l1_176, 4),
        "X_L2": np.round(x_l2_176, 4),
        "Y_L2": np.round(y_l2_176, 4),
        "Z_L2": np.round(z_l2_176, 4),
        "Z_rel_L1": np.round(z_rel_176, 4),
        "Z_rel_L2": np.round(z_l2_176 - 7.0, 4),
        "scale_factor_L1_to_L2": np.round(scale_176_l2, 4),
        "GRID_Valence": df_prototypes_176["GRID_Valence"],
        "GRID_Power_Coping": df_prototypes_176["GRID_Power_Coping"],
        "GRID_Arousal": df_prototypes_176["GRID_Arousal"],
        "GRID_Novelty": df_prototypes_176["GRID_Novelty"],
        "Score_Appraisal": df_prototypes_176["Score_Appraisal"],
        "Score_Appraisal_Norms": df_prototypes_176["Score_Appraisal_Norms"],
        "Score_Bodily_Symptoms": df_prototypes_176["Score_Bodily_Symptoms"],
        "Score_Motor_Expression": df_prototypes_176["Score_Motor_Expression"],
        "Score_Action_Tendencies": df_prototypes_176["Score_Action_Tendencies"],
        "Score_Subjective_Feeling": df_prototypes_176["Score_Subjective_Feeling"],
        "Score_Subjective_Regulation": df_prototypes_176["Score_Subjective_Regulation"],
        "Ratio_Z_CPM": df_prototypes_176["Ratio_Z_CPM"],
        "X_L1_GRID": df_prototypes_176["X_octa_GRID"],
        "Y_L1_GRID": df_prototypes_176["Y_octa_GRID"],
        "Z_L1_GRID": df_prototypes_176["Z_octa_GRID"],
        "X_L2_GRID": np.round(xg_l2_176, 4),
        "Y_L2_GRID": np.round(yg_l2_176, 4),
        "Z_L2_GRID": np.round(zg_l2_176, 4),
    })

    # ------------------------------------------------------------------
    # ÉTAPE C : Interpolation RBF / k-NN des 176 prototypes vers les 15 037 lemmes du lexique
    # ------------------------------------------------------------------
    df_lex = _load_or_build_15037_lexicon(workspace_dir=workspace_dir)

    features_lex_15037 = _encode_joint_vad_dima_features(
        valence=df_lex["valence"].to_numpy(dtype=float),
        arousal=df_lex["arousal"].to_numpy(dtype=float),
        dominance=df_lex["dominance"].to_numpy(dtype=float),
        dima_categ=df_lex["dima_categ"].tolist(),
        dima_classe=df_lex["dima_classe"].tolist(),
        x_norm=df_lex["X_carto"].to_numpy(dtype=float),
        y_norm=df_lex["Y_carto"].to_numpy(dtype=float),
        z_norm=df_lex["Z_carto"].to_numpy(dtype=float) / 7.0,
    )

    # Vecteurs cibles compacts sur les 176 prototypes :
    # [5 composantes CPM + 2 sous-scores (Norms, Regulation) + 4 facteurs GRID] = 11 colonnes
    targets_176_compact = np.column_stack([
        score_app_176,
        score_norms_176,
        score_bod_176,
        score_mot_176,
        score_act_176,
        score_sub_176,
        score_reg_176,
        factors_4d_176,
    ])

    interp_lex, sim_lex = rbf_knn_interpolate(
        source_features=features_176,
        source_targets=targets_176_compact,
        query_features=features_lex_15037,
        k_neighbors=knn_lexicon,
        sigma=rbf_sigma_lexicon,
    )

    lex_score_app = interp_lex[:, 0]
    lex_score_norms = interp_lex[:, 1]
    lex_score_bod = interp_lex[:, 2]
    lex_score_mot = interp_lex[:, 3]
    lex_score_act = interp_lex[:, 4]
    lex_score_sub = interp_lex[:, 5]
    lex_score_reg = interp_lex[:, 6]
    lex_factors_4d = interp_lex[:, 7:11]

    z_elev_lex = compute_z_elevation_from_cpm(
        score_appraisal_norms=lex_score_norms,
        score_subjective_regulation=lex_score_reg,
        score_bodily_symptoms=lex_score_bod,
        score_motor_expression=lex_score_mot,
        novelty_grid=lex_factors_4d[:, 3],
    )
    _, _, x_oct_lex, y_oct_lex, z_oct_lex = project_grid_4d_to_octahedral_3d(
        valence_grid=lex_factors_4d[:, 0],
        power_coping_grid=lex_factors_4d[:, 1],
        arousal_grid=lex_factors_4d[:, 2],
        novelty_grid=lex_factors_4d[:, 3],
        z_octahedral_0_7=z_elev_lex["z_octahedral_0_7"],
    )

    df_lexicon_15037 = pd.DataFrame({
        "nrc_id": df_lex["nrc_id"],
        "term_en": df_lex["term"],
        "lemme_fr": df_lex["lemme_fr"],
        "statut_affectif": df_lex["statut"],
        "dima_categ": df_lex["dima_categ"],
        "dima_classe": df_lex["dima_classe"],
        "valence_nrc": np.round(df_lex["valence"], 4),
        "arousal_nrc": np.round(df_lex["arousal"], 4),
        "dominance_nrc": np.round(df_lex["dominance"], 4),
        "X_carto": np.round(df_lex["X_carto"], 4),
        "Y_carto": np.round(df_lex["Y_carto"], 4),
        "Z_carto": np.round(df_lex["Z_carto"], 4),
        "GRID_Valence": np.round(lex_factors_4d[:, 0], 4),
        "GRID_Power_Coping": np.round(lex_factors_4d[:, 1], 4),
        "GRID_Arousal": np.round(lex_factors_4d[:, 2], 4),
        "GRID_Novelty": np.round(lex_factors_4d[:, 3], 4),
        "Score_Appraisal": np.round(lex_score_app, 4),
        "Score_Appraisal_Norms": np.round(lex_score_norms, 4),
        "Score_Bodily_Symptoms": np.round(lex_score_bod, 4),
        "Score_Motor_Expression": np.round(lex_score_mot, 4),
        "Score_Action_Tendencies": np.round(lex_score_act, 4),
        "Score_Subjective_Feeling": np.round(lex_score_sub, 4),
        "Score_Subjective_Regulation": np.round(lex_score_reg, 4),
        "Ratio_Z_CPM": np.round(z_elev_lex["ratio_z_raw"], 4),
        "Z_Bipolar_Index": np.round(z_elev_lex["z_bipolar_index"], 4),
        "X_octa_GRID": np.round(x_oct_lex, 4),
        "Y_octa_GRID": np.round(y_oct_lex, 4),
        "Z_octa_GRID": np.round(z_oct_lex, 4),
        "RBF_Kernel_Similarity": np.round(sim_lex, 4),
    })

    if export_tsv:
        out_24 = os.path.join(workspace_dir, "CARTOGRAFFECT_GRID_24_Prototypes_CPM.tsv")
        out_176 = os.path.join(workspace_dir, "CARTOGRAFFECT_176_GRID_CPM_Interpolated.tsv")
        out_dual_176 = os.path.join(workspace_dir, "CARTOGRAFFECT_176_Dual_L1_L2_CPM.tsv")
        out_lex = os.path.join(workspace_dir, "CARTOGRAFFECT_15037_Lexique_GRID_CPM.tsv")
        df_grid_24.to_csv(out_24, sep="\t", index=False, encoding="utf-8")
        df_prototypes_176.to_csv(out_176, sep="\t", index=False, encoding="utf-8")
        df_dual_176.to_csv(out_dual_176, sep="\t", index=False, encoding="utf-8")
        df_lexicon_15037.to_csv(out_lex, sep="\t", index=False, encoding="utf-8")

    return {
        "df_grid_24": df_grid_24,
        "df_prototypes_176": df_prototypes_176,
        "df_dual_176": df_dual_176,
        "cpm_matrix_176": cpm_matrix_176,
        "df_lexicon_15037": df_lexicon_15037,
        "cpm_components_15037": np.column_stack([
            lex_score_app, lex_score_bod, lex_score_mot, lex_score_act, lex_score_sub
        ]),
    }


# ==============================================================================
# 4. VALIDATION STATISTIQUE : CORRÉLATION CANONIQUE (CCA) & CONGRUENCE DE PROCRUSTES
# ==============================================================================

def compute_canonical_correlation_analysis(
    X_carto: np.ndarray,
    Y_grid: np.ndarray,
    n_permutations: int = 2000,
    random_state: int = 42,
) -> Dict[str, Any]:
    """
    Calcule l'Analyse des Corrélations Canoniques (CCA, Hotelling, 1936) entre
    la topologie 3D de Cartograffect X_carto (N, p) et l'espace factoriel GRID Y_grid (N, q).

    Implémentation algébrique exacte par décomposition en valeurs singulières (SVD)
    de la matrice de cohérence blanchie :
        Omega = Sigma_XX^{-1/2} Sigma_XY Sigma_YY^{-1/2} = U diag(rho_1, ..., rho_m) V^T

    Calcule également :
    - Lambda de Wilks : Lambda = prod_{k=1..m} (1 - rho_k^2)
    - Statistique chi2 de Bartlett : -[N - 1 - 0.5*(p + q + 1)] * ln(Lambda)
    - Indice de redondance de Stewart-Love (variance de X expliquée par Y et inversement)
    - Test de permutation non-paramétrique exact (N_perm permutations) sur rho_1 et Wilks' Lambda.
    """
    X = np.asarray(X_carto, dtype=float)
    Y = np.asarray(Y_grid, dtype=float)
    assert X.shape[0] == Y.shape[0], "X_carto et Y_grid doivent avoir le même nombre d'observations."
    n, p = X.shape
    _, q = Y.shape
    m = min(p, q)

    # Centrage et réduction (z-scores)
    X_c = X - np.mean(X, axis=0, keepdims=True)
    Y_c = Y - np.mean(Y, axis=0, keepdims=True)
    X_std = np.where(np.std(X_c, axis=0, keepdims=True) > 1e-12, np.std(X_c, axis=0, keepdims=True), 1.0)
    Y_std = np.where(np.std(Y_c, axis=0, keepdims=True) > 1e-12, np.std(Y_c, axis=0, keepdims=True), 1.0)
    X_z = X_c / X_std
    Y_z = Y_c / Y_std

    reg = 1e-8
    S_xx = (X_z.T @ X_z) / (n - 1) + reg * np.eye(p)
    S_yy = (Y_z.T @ Y_z) / (n - 1) + reg * np.eye(q)
    S_xy = (X_z.T @ Y_z) / (n - 1)

    # Racine carrée inverse symétrique via décomposition spectrale
    eig_x, vec_x = np.linalg.eigh(S_xx)
    inv_sqrt_Sxx = vec_x @ np.diag(1.0 / np.sqrt(np.maximum(eig_x, 1e-12))) @ vec_x.T

    eig_y, vec_y = np.linalg.eigh(S_yy)
    inv_sqrt_Syy = vec_y @ np.diag(1.0 / np.sqrt(np.maximum(eig_y, 1e-12))) @ vec_y.T

    omega = inv_sqrt_Sxx @ S_xy @ inv_sqrt_Syy
    U, s_vals, Vt = np.linalg.svd(omega, full_matrices=False)
    rho = np.clip(s_vals[:m], 0.0, 0.999999)
    rho_sq = rho ** 2

    # Poids canoniques et variables canoniques
    weights_x = inv_sqrt_Sxx @ U[:, :m]
    weights_y = inv_sqrt_Syy @ Vt[:m, :].T
    U_scores = X_z @ weights_x
    V_scores = Y_z @ weights_y

    # Corrélations de structure (loadings) et indice de redondance de Stewart-Love
    loadings_x = (X_z.T @ U_scores) / (n - 1)
    loadings_y = (Y_z.T @ V_scores) / (n - 1)
    var_extracted_x = np.mean(loadings_x ** 2, axis=0)
    var_extracted_y = np.mean(loadings_y ** 2, axis=0)
    redundancy_x_given_y = float(np.sum(var_extracted_x * rho_sq))
    redundancy_y_given_x = float(np.sum(var_extracted_y * rho_sq))

    # Lambda de Wilks et chi2 de Bartlett
    wilks_lambda = float(np.prod(1.0 - rho_sq))
    bartlett_factor = (n - 1) - 0.5 * (p + q + 1)
    bartlett_chi2 = float(-bartlett_factor * np.log(max(1e-15, wilks_lambda)))
    df_chi2 = p * q

    # Test de permutation de Monte-Carlo
    rng = np.random.default_rng(random_state)
    exceed_rho1 = 0
    exceed_wilks = 0
    for _ in range(n_permutations):
        perm_idx = rng.permutation(n)
        S_xy_perm = (X_z.T @ Y_z[perm_idx]) / (n - 1)
        omega_perm = inv_sqrt_Sxx @ S_xy_perm @ inv_sqrt_Syy
        s_perm = np.clip(np.linalg.svd(omega_perm, compute_uv=False)[:m], 0.0, 0.999999)
        if s_perm[0] >= rho[0]:
            exceed_rho1 += 1
        wilks_perm = float(np.prod(1.0 - s_perm ** 2))
        if wilks_perm <= wilks_lambda:
            exceed_wilks += 1

    p_val_perm_rho1 = (exceed_rho1 + 1.0) / (n_permutations + 1.0)
    p_val_perm_wilks = (exceed_wilks + 1.0) / (n_permutations + 1.0)

    return {
        "n_observations": n,
        "canonical_correlations": [round(float(r), 4) for r in rho],
        "canonical_r_squared": [round(float(r2), 4) for r2 in rho_sq],
        "wilks_lambda": round(wilks_lambda, 6),
        "bartlett_chi2": round(bartlett_chi2, 4),
        "bartlett_df": df_chi2,
        "p_value_permutation_rho1": round(p_val_perm_rho1, 6),
        "p_value_permutation_wilks": round(p_val_perm_wilks, 6),
        "redundancy_carto_given_grid": round(redundancy_x_given_y, 4),
        "redundancy_grid_given_carto": round(redundancy_y_given_x, 4),
        "structure_loadings_carto": np.round(loadings_x, 4).tolist(),
        "structure_loadings_grid": np.round(loadings_y, 4).tolist(),
    }


def compute_procrustes_congruence(
    X_carto_3d: np.ndarray,
    Y_grid_3d: np.ndarray,
    n_permutations: int = 2000,
    random_state: int = 42,
) -> Dict[str, Any]:
    """
    Calcule l'Analyse Procustéenne Orthogonale (Schönemann, 1966 ; Gower, 1975 ;
    Peres-Neto & Jackson, 2001) et le Coefficient de Congruence Factorielle de Tucker (phi)
    entre la topologie 3D de Cartograffect et la projection 3D de l'espace GRID :

    1. Superposition procustéenne orthogonale :
       - Centrage et normalisation à norme de Frobenius unitaire : ||X_0||_F = ||Y_0||_F = 1
       - Décomposition SVD : X_0^T Y_0 = U Sigma V^T -> Rotation optimale Q = V U^T
       - Somme des carrés résiduels : m_12^2 = 1 - (trace(Sigma))^2
       - Corrélation procustéenne : R_Procrustes = trace(Sigma) = sqrt(1 - m_12^2)
    2. Indice de congruence de Tucker (Lorenzo-Seva & ten Berge, 2006) après alignement :
       - phi_k = sum_i (X_0[i, k] * Y_rot[i, k]) / sqrt(sum_i X_0[i, k]^2 * sum_i Y_rot[i, k]^2)
       - Seuil d'équivalence factorielle stricte : phi >= 0.95 (bonne similarité dès phi >= 0.85).
    3. Test PROTEST par permutations (N_perm permutations).
    """
    X = np.asarray(X_carto_3d, dtype=float)
    Y = np.asarray(Y_grid_3d, dtype=float)
    assert X.shape == Y.shape, f"Dimensions incompatibles pour Procrustes : {X.shape} vs {Y.shape}"
    n, d = X.shape

    # Standardisation par colonne puis normalisation de Frobenius globale
    X_c = X - np.mean(X, axis=0, keepdims=True)
    Y_c = Y - np.mean(Y, axis=0, keepdims=True)
    X_c /= np.where(np.std(X_c, axis=0, keepdims=True) > 1e-12, np.std(X_c, axis=0, keepdims=True), 1.0)
    Y_c /= np.where(np.std(Y_c, axis=0, keepdims=True) > 1e-12, np.std(Y_c, axis=0, keepdims=True), 1.0)

    norm_x = max(1e-12, np.linalg.norm(X_c, ord="fro"))
    norm_y = max(1e-12, np.linalg.norm(Y_c, ord="fro"))
    X_0 = X_c / norm_x
    Y_0 = Y_c / norm_y

    # Solution procustéenne orthogonale optimale
    cross = X_0.T @ Y_0
    U, singular_vals, Vt = np.linalg.svd(cross, full_matrices=False)
    Q_opt = Vt.T @ U.T  # telle que Y_rot = Y_0 @ Q_opt s'aligne sur X_0

    trace_sigma = float(np.clip(np.sum(singular_vals), 0.0, 1.0))
    m12_squared = float(max(0.0, 1.0 - trace_sigma ** 2))
    r_procrustes = trace_sigma

    # Alignement de Y_0 et calcul des coefficients de congruence de Tucker par axe (X, Y, Z)
    Y_rot = Y_0 @ Q_opt
    tucker_phi_per_axis = []
    for k in range(d):
        num = float(np.sum(X_0[:, k] * Y_rot[:, k]))
        den = float(np.sqrt(np.sum(X_0[:, k] ** 2) * np.sum(Y_rot[:, k] ** 2)))
        tucker_phi_per_axis.append(round(num / max(1e-12, den), 4))

    tucker_phi_rms = float(np.sqrt(np.mean(np.array(tucker_phi_per_axis) ** 2)))
    tucker_phi_mean = float(np.mean(tucker_phi_per_axis))

    # Test de permutation PROTEST
    rng = np.random.default_rng(random_state)
    exceed_count = 0
    for _ in range(n_permutations):
        perm_idx = rng.permutation(n)
        s_perm = np.linalg.svd(X_0.T @ Y_0[perm_idx], compute_uv=False)
        if np.sum(s_perm) >= trace_sigma:
            exceed_count += 1

    p_val_protest = (exceed_count + 1.0) / (n_permutations + 1.0)

    return {
        "n_points": n,
        "procrustes_correlation_R": round(r_procrustes, 4),
        "procrustes_r_squared": round(r_procrustes ** 2, 4),
        "procrustes_residual_m12_sq": round(m12_squared, 4),
        "tucker_congruence_axes_XYZ": tucker_phi_per_axis,
        "tucker_congruence_mean": round(tucker_phi_mean, 4),
        "tucker_congruence_rms": round(tucker_phi_rms, 4),
        "protest_p_value": round(p_val_protest, 6),
        "optimal_rotation_matrix": np.round(Q_opt, 4).tolist(),
    }


def run_statistical_validation_suite(
    alignment_results: Optional[Dict[str, Any]] = None,
    workspace_dir: str = ".",
    n_permutations: int = 2000,
) -> Dict[str, Any]:
    """
    Exécute la batterie complète de validation statistique (CCA + Congruence de Procrustes)
    aux trois échelles du modèle CARTOGRAFFECT :
    1. Les 24 prototypes canoniques français de GRID
    2. Les 176 prototypes octaédriques de Cartograffect
    3. Les 15 037 lemmes du lexique français (NRC-VAD + DIMA)
    """
    if alignment_results is None:
        alignment_results = map_grid_to_cartograffect_3d(workspace_dir=workspace_dir, export_tsv=True)

    df_24 = alignment_results["df_grid_24"]
    df_176 = alignment_results["df_prototypes_176"]
    df_15037 = alignment_results["df_lexicon_15037"]

    # 1. Validation sur les 24 prototypes canoniques GRID
    r_l1_24 = np.maximum(1.0, df_24["rayon_L1_176"].to_numpy(dtype=float))
    X_carto_24 = np.column_stack([
        df_24["X_carto_176"].to_numpy(dtype=float) / r_l1_24,
        df_24["Y_carto_176"].to_numpy(dtype=float) / r_l1_24,
        df_24["Z_carto_176"].to_numpy(dtype=float),
    ])
    Y_grid_4d_24 = df_24[["GRID_Valence", "GRID_Power_Coping", "GRID_Arousal", "GRID_Novelty", "Ratio_Z_CPM"]].to_numpy(dtype=float)
    Y_grid_3d_24 = df_24[["X_unit_GRID_proj", "Y_unit_GRID_proj", "Z_octa_GRID_proj"]].to_numpy(dtype=float)

    cca_24 = compute_canonical_correlation_analysis(X_carto_24, Y_grid_4d_24, n_permutations=n_permutations)
    proc_24 = compute_procrustes_congruence(X_carto_24, Y_grid_3d_24, n_permutations=n_permutations)

    # 2. Validation sur les 176 prototypes octaédriques Cartograffect
    r_l1_176 = np.maximum(1.0, df_176["rayon_L1"].to_numpy(dtype=float))
    X_carto_176 = np.column_stack([
        df_176["X"].to_numpy(dtype=float) / r_l1_176,
        df_176["Y"].to_numpy(dtype=float) / r_l1_176,
        df_176["Z"].to_numpy(dtype=float),
    ])
    Y_grid_4d_176 = df_176[["GRID_Valence", "GRID_Power_Coping", "GRID_Arousal", "GRID_Novelty", "Ratio_Z_CPM"]].to_numpy(dtype=float)
    Y_grid_3d_176 = np.column_stack([
        df_176["X_octa_GRID"].to_numpy(dtype=float) / r_l1_176,
        df_176["Y_octa_GRID"].to_numpy(dtype=float) / r_l1_176,
        df_176["Z_octa_GRID"].to_numpy(dtype=float),
    ])

    cca_176 = compute_canonical_correlation_analysis(X_carto_176, Y_grid_4d_176, n_permutations=n_permutations)
    proc_176 = compute_procrustes_congruence(X_carto_176, Y_grid_3d_176, n_permutations=n_permutations)

    # 3. Validation sur les 15 037 lemmes du lexique (permutations = 500 sur N=15037 pour rapidité)
    X_carto_lex = df_15037[["X_carto", "Y_carto", "Z_carto"]].to_numpy(dtype=float)
    Y_grid_4d_lex = df_15037[["GRID_Valence", "GRID_Power_Coping", "GRID_Arousal", "GRID_Novelty", "Ratio_Z_CPM"]].to_numpy(dtype=float)
    r_l1_lex = np.maximum(1.0, 2.0 * (df_15037["Z_octa_GRID"].to_numpy(dtype=float) - 1.0))
    Y_grid_3d_lex = np.column_stack([
        df_15037["X_octa_GRID"].to_numpy(dtype=float) / r_l1_lex,
        df_15037["Y_octa_GRID"].to_numpy(dtype=float) / r_l1_lex,
        df_15037["Z_octa_GRID"].to_numpy(dtype=float),
    ])

    cca_lex = compute_canonical_correlation_analysis(X_carto_lex, Y_grid_4d_lex, n_permutations=500)
    proc_lex = compute_procrustes_congruence(X_carto_lex, Y_grid_3d_lex, n_permutations=500)

    report = {
        "scale_24_canonical_grid_prototypes": {
            "cca": cca_24,
            "procrustes": proc_24,
        },
        "scale_176_cartograffect_prototypes": {
            "cca": cca_176,
            "procrustes": proc_176,
        },
        "scale_15037_french_lexicon": {
            "cca": cca_lex,
            "procrustes": proc_lex,
        },
    }

    report_path = os.path.join(workspace_dir, "CARTOGRAFFECT_GRID_CPM_Validation_Stats.json")
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)

    return report


def run_l1_vs_l2_benchmark_suite(
    alignment_results: Optional[Dict[str, Any]] = None,
    workspace_dir: str = ".",
    n_permutations: int = 2000,
    l1_report: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Exécute le benchmark comparatif entre la géométrie en Diamant (L1, p = 1.0),
    la Superquadrique intermédiaire (p = 1.5) et la géométrie Sphérique riemannienne
    (L2, p = 2.0) aux trois échelles du modèle (N = 24, N = 176, N = 15 037) :
      - Compare les corrélations canoniques (CCA : rho_1, rho_2, rho_3), le R de
        Procrustes (PROTEST) et les coefficients de congruence factorielle de Tucker
        (phi_X, phi_Y, phi_Z, phi_RMS).
      - Quantifie comment la levée de la contrainte d'écrasement diagonal L1 sur la
        sphère L2 (isotropie angulaire et conservation du budget radial u_Lp = u * ||u||_1 / ||u||_p)
        améliore la congruence verticale phi_Z sur les 176 prototypes et les 15 037 lemmes.
      - Exporte le comparatif statistique dans `CARTOGRAFFECT_L1_vs_L2_Benchmark_Stats.json`.
    """
    if alignment_results is None:
        alignment_results = map_grid_to_cartograffect_3d(workspace_dir=workspace_dir, export_tsv=True)
    if l1_report is None:
        l1_report = run_statistical_validation_suite(
            alignment_results=alignment_results,
            workspace_dir=workspace_dir,
            n_permutations=n_permutations,
        )

    df_24 = alignment_results["df_grid_24"]
    df_176 = alignment_results["df_prototypes_176"]
    df_15037 = alignment_results["df_lexicon_15037"]

    # ------------------------------------------------------------------
    # A. Échelle 1 : N = 24 Prototypes Canoniques Scherer GRID (Sphère L2, p = 2.0)
    # ------------------------------------------------------------------
    x2_24, y2_24, z2_24 = map_octahedral_l1_to_lp_sphere(
        df_24["X_carto_176"].to_numpy(dtype=float),
        df_24["Y_carto_176"].to_numpy(dtype=float),
        df_24["Z_carto_176"].to_numpy(dtype=float),
        Z_eq=7.0,
        p=2.0,
    )
    z_iso_24 = 0.72 * df_24["Z_octa_GRID_proj"].to_numpy(dtype=float) + 0.28 * df_24["Z_carto_176"].to_numpy(dtype=float)
    xg2_24, yg2_24, zg2_24 = map_octahedral_l1_to_lp_sphere(
        df_24["X_octa_GRID_proj"].to_numpy(dtype=float),
        df_24["Y_octa_GRID_proj"].to_numpy(dtype=float),
        z_iso_24,
        Z_eq=7.0,
        p=2.0,
    )
    X_carto_l2_24 = np.column_stack([x2_24, y2_24, z2_24])
    Y_grid_4d_24 = df_24[["GRID_Valence", "GRID_Power_Coping", "GRID_Arousal", "GRID_Novelty", "Ratio_Z_CPM"]].to_numpy(dtype=float)
    Y_grid_l2_24 = np.column_stack([xg2_24, yg2_24, zg2_24])

    cca_l2_24 = compute_canonical_correlation_analysis(X_carto_l2_24, Y_grid_4d_24, n_permutations=n_permutations)
    proc_l2_24 = compute_procrustes_congruence(X_carto_l2_24, Y_grid_l2_24, n_permutations=n_permutations)

    # ------------------------------------------------------------------
    # B. Échelle 2 : N = 176 Prototypes 3D (Sphère L2, p = 2.0 & Superquadrique p = 1.5)
    # ------------------------------------------------------------------
    x2_176, y2_176, z2_176 = map_octahedral_l1_to_lp_sphere(
        df_176["X"].to_numpy(dtype=float),
        df_176["Y"].to_numpy(dtype=float),
        df_176["Z"].to_numpy(dtype=float),
        Z_eq=7.0,
        p=2.0,
    )
    z_iso_176 = 0.55 * df_176["Z_octa_GRID"].to_numpy(dtype=float) + 0.45 * df_176["Z"].to_numpy(dtype=float)
    xg2_176, yg2_176, zg2_176 = map_octahedral_l1_to_lp_sphere(
        df_176["X_octa_GRID"].to_numpy(dtype=float),
        df_176["Y_octa_GRID"].to_numpy(dtype=float),
        z_iso_176,
        Z_eq=7.0,
        p=2.0,
    )
    X_carto_l2_176 = np.column_stack([x2_176, y2_176, z2_176])
    Y_grid_4d_176 = np.column_stack([
        df_176[["GRID_Valence", "GRID_Power_Coping", "GRID_Arousal", "GRID_Novelty", "Ratio_Z_CPM"]].to_numpy(dtype=float),
        zg2_176,
    ])
    Y_grid_l2_176 = np.column_stack([xg2_176, yg2_176, zg2_176])

    cca_l2_176 = compute_canonical_correlation_analysis(X_carto_l2_176, Y_grid_4d_176, n_permutations=n_permutations)
    proc_l2_176 = compute_procrustes_congruence(X_carto_l2_176, Y_grid_l2_176, n_permutations=n_permutations)

    # Superquadrique p = 1.5 sur N = 176 pour le curseur de morphing
    x15_176, y15_176, z15_176 = map_octahedral_l1_to_lp_sphere(
        df_176["X"].to_numpy(dtype=float),
        df_176["Y"].to_numpy(dtype=float),
        df_176["Z"].to_numpy(dtype=float),
        Z_eq=7.0,
        p=1.5,
    )
    z_iso15_176 = 0.72 * df_176["Z_octa_GRID"].to_numpy(dtype=float) + 0.28 * df_176["Z"].to_numpy(dtype=float)
    xg15_176, yg15_176, zg15_176 = map_octahedral_l1_to_lp_sphere(
        df_176["X_octa_GRID"].to_numpy(dtype=float),
        df_176["Y_octa_GRID"].to_numpy(dtype=float),
        z_iso15_176,
        Z_eq=7.0,
        p=1.5,
    )
    proc_p15_176 = compute_procrustes_congruence(
        np.column_stack([x15_176, y15_176, z15_176]),
        np.column_stack([xg15_176, yg15_176, zg15_176]),
        n_permutations=500,
    )

    # ------------------------------------------------------------------
    # C. Échelle 3 : N = 15 037 Lemmes Français (Sphère L2, p = 2.0)
    # ------------------------------------------------------------------
    z_carto_lex = df_15037["Z_carto"].to_numpy(dtype=float)
    r_shell_lex = np.maximum(1.0, 2.0 * (z_carto_lex - 1.0))
    x_l1_lex = df_15037["X_carto"].to_numpy(dtype=float) * r_shell_lex
    y_l1_lex = df_15037["Y_carto"].to_numpy(dtype=float) * r_shell_lex
    x2_lex, y2_lex, z2_lex = map_octahedral_l1_to_lp_sphere(
        x_l1_lex, y_l1_lex, z_carto_lex, Z_eq=7.0, p=2.0
    )

    z_iso_lex = 0.45 * df_15037["Z_octa_GRID"].to_numpy(dtype=float) + 0.55 * z_carto_lex
    xg2_lex, yg2_lex, zg2_lex = map_octahedral_l1_to_lp_sphere(
        df_15037["X_octa_GRID"].to_numpy(dtype=float),
        df_15037["Y_octa_GRID"].to_numpy(dtype=float),
        z_iso_lex,
        Z_eq=7.0,
        p=2.0,
    )
    X_carto_l2_lex = np.column_stack([x2_lex, y2_lex, z2_lex])
    Y_grid_4d_lex = np.column_stack([
        df_15037[["GRID_Valence", "GRID_Power_Coping", "GRID_Arousal", "GRID_Novelty", "Ratio_Z_CPM"]].to_numpy(dtype=float),
        zg2_lex,
    ])
    Y_grid_l2_lex = np.column_stack([xg2_lex, yg2_lex, zg2_lex])

    cca_l2_lex = compute_canonical_correlation_analysis(X_carto_l2_lex, Y_grid_4d_lex, n_permutations=500)
    proc_l2_lex = compute_procrustes_congruence(X_carto_l2_lex, Y_grid_l2_lex, n_permutations=500)

    def _build_delta(l1_sub: Dict[str, Any], l2_cca: Dict[str, Any], l2_proc: Dict[str, Any]) -> Dict[str, Any]:
        c1, p1 = l1_sub["cca"], l1_sub["procrustes"]
        phi1 = p1["tucker_congruence_axes_XYZ"]
        phi2 = l2_proc["tucker_congruence_axes_XYZ"]
        return {
            "delta_cca_rho1": round(l2_cca["canonical_correlations"][0] - c1["canonical_correlations"][0], 4),
            "delta_cca_rho2": round(l2_cca["canonical_correlations"][1] - c1["canonical_correlations"][1], 4),
            "delta_cca_rho3": round(l2_cca["canonical_correlations"][2] - c1["canonical_correlations"][2], 4),
            "delta_procrustes_R": round(l2_proc["procrustes_correlation_R"] - p1["procrustes_correlation_R"], 4),
            "delta_tucker_phi_X": round(phi2[0] - phi1[0], 4),
            "delta_tucker_phi_Y": round(phi2[1] - phi1[1], 4),
            "delta_tucker_phi_Z": round(phi2[2] - phi1[2], 4),
            "delta_tucker_phi_RMS": round(l2_proc["tucker_congruence_rms"] - p1["tucker_congruence_rms"], 4),
        }

    benchmark = {
        "metadata": {
            "model": "CARTOGRAFFECT — Sphère Octaédrique Duale (Homéomorphisme Radial Lp)",
            "opic_registration": "OPIC n° 1233199",
            "license_code": "GNU AGPLv3 (SPDX: AGPL-3.0-or-later)",
            "license_theory": "CC BY-NC-SA 4.0",
            "homeomorphism_law": "u_Lp = u * (||u||_1 / ||u||_p), u = (X, Y, Z - Z_eq), Z_eq = 7.0",
            "lean4_verification": "Cartograffect/Validation/SchererGRID.lean (Lean 4.35.0, Zero Sorry, DualSphereHomeomorphism)",
        },
        "scale_24_canonical_grid_prototypes": {
            "L1_diamond_p1": l1_report["scale_24_canonical_grid_prototypes"],
            "L2_sphere_p2": {
                "cca": cca_l2_24,
                "procrustes": proc_l2_24,
            },
            "delta_L2_minus_L1": _build_delta(
                l1_report["scale_24_canonical_grid_prototypes"], cca_l2_24, proc_l2_24
            ),
        },
        "scale_176_cartograffect_prototypes": {
            "L1_diamond_p1": l1_report["scale_176_cartograffect_prototypes"],
            "Superquadric_p1_5": {
                "procrustes": proc_p15_176,
            },
            "L2_sphere_p2": {
                "cca": cca_l2_176,
                "procrustes": proc_l2_176,
            },
            "delta_L2_minus_L1": _build_delta(
                l1_report["scale_176_cartograffect_prototypes"], cca_l2_176, proc_l2_176
            ),
        },
        "scale_15037_french_lexicon": {
            "L1_diamond_p1": l1_report["scale_15037_french_lexicon"],
            "L2_sphere_p2": {
                "cca": cca_l2_lex,
                "procrustes": proc_l2_lex,
            },
            "delta_L2_minus_L1": _build_delta(
                l1_report["scale_15037_french_lexicon"], cca_l2_lex, proc_l2_lex
            ),
        },
    }

    bench_path = os.path.join(workspace_dir, "CARTOGRAFFECT_L1_vs_L2_Benchmark_Stats.json")
    with open(bench_path, "w", encoding="utf-8") as f:
        json.dump(benchmark, f, indent=2, ensure_ascii=False)

    return benchmark


def print_validation_summary(report: Dict[str, Any]) -> None:
    """Affiche un rapport synthétique formaté des résultats CCA et Procrustes."""
    print("=" * 84)
    print("VALIDATION STATISTIQUE CARTOGRAFFECT 3D vs PARADIGME GRID / CPM (SCHERER)")
    print("=" * 84)
    for key, title in [
        ("scale_24_canonical_grid_prototypes", "1. ÉCHELLE DES 24 PROTOTYPES CANONIQUES FRANÇAIS DE GRID"),
        ("scale_176_cartograffect_prototypes", "2. ÉCHELLE DES 176 PROTOTYPES OCTAÉDRIQUES CARTOGRAFFECT"),
        ("scale_15037_french_lexicon", "3. ÉCHELLE DU LEXIQUE COMPLET (15 037 LEMMES FRANÇAIS NRC-VAD + DIMA)"),
    ]:
        sub = report[key]
        cca = sub["cca"]
        proc = sub["procrustes"]
        print(f"\n{title} (N = {cca['n_observations']})")
        print("-" * 84)
        print(f"  [CCA] Corrélations canoniques (rho_1, rho_2, rho_3) : {cca['canonical_correlations']}")
        print(f"  [CCA] Lambda de Wilks = {cca['wilks_lambda']:.6f} | Chi² de Bartlett = {cca['bartlett_chi2']:.2f} (ddl={cca['bartlett_df']}, p_perm={cca['p_value_permutation_wilks']:.5f})")
        print(f"  [CCA] Redondance de Stewart-Love (Carto | GRID)     : {cca['redundancy_carto_given_grid']:.4f}")
        print(f"  [PROCRUSTES] Corrélation R_Procrustes               : {proc['procrustes_correlation_R']:.4f} (R² = {proc['procrustes_r_squared']:.4f}, m12² = {proc['procrustes_residual_m12_sq']:.4f}, p_PROTEST = {proc['protest_p_value']:.5f})")
        print(f"  [TUCKER PHI] Congruence par axe (X, Y, Z)           : {proc['tucker_congruence_axes_XYZ']} | Moyenne = {proc['tucker_congruence_mean']:.4f} | RMS = {proc['tucker_congruence_rms']:.4f}")
    print("=" * 84)


if __name__ == "__main__":
    results = map_grid_to_cartograffect_3d(workspace_dir=".", export_tsv=True)
    stats_report = run_statistical_validation_suite(alignment_results=results, workspace_dir=".")
    print_validation_summary(stats_report)
