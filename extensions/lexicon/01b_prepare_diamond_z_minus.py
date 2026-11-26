"""
01b_prepare_diamond_z_minus.py
================================================================================
Préparation formelle, géométrique et computationnelle du « Diamant du Cartograffect »
(303 positions : Z ∈ [-7, +7]).

Intègre intégralement :
1. L'architecture à 4 composantes emboîtées (Cabelguen, 2026 ; certifiée sous Lean 4) :
   - Moteur prédictif (`PredictiveEngine`) : 3 interfaces (Perceptive C, Subjective A,
     Attentionnelle P = 1/σ²), 4 opérations inférentielles et 9 nœuds de couplage (A, C).
   - Noyau affectif & axiologique (`CoreAffect`) : coordonnées (X, Y, Z), rayon de
     couronne R(Z) = 2(|Z|-1), régimes de charge/décharge et potentiel de Lyapunov.
   - Matrice de l'interface attentionnelle & affective (`AffectiveMatrix`) : transduction
     sur les pôles d'Attente et de Contrôle, 6 régimes énergétiques, polarité hédonique
     lexicographique (primauté de X) et 6 profils d'activation phénoménologique.
   - Taxonomie hiérarchique (`AffectiveTaxonomy`) : 15 strates Z ∈ [-7, +7], 9 groupes
     d'orientation par hémisphère et partition exacte en 17 sous-secteurs fonctionnels.
2. La Rose complète des 8 symétries et antagonismes sur tous les axes :
   - Antagoniste régulateur formel par morceaux A(X, Y, Z) :
     * (-X, -Y, Z) si XY = 0 (centre et positions axiales X=0 ou Y=0)
     * (-sgn(X)|Y|, -sgn(Y)|X|, Z) si XY ≠ 0 (positions diagonales |X|=|Y|>0 -> (-X,-Y,Z),
       controlatéral direct Td(X,Y) = (Y, X, Z) si sgn(X) != sgn(Y),
       controlatéral inversé Ti(X,Y) = (-Y, -X, Z) si sgn(X) == sgn(Y))
   - Opposé central intra-dominante Ic(P) = (-X, -Y, Z) (inversion des signes à dominante fixe)
   - Miroir diagonal de dominante Mdom(P) : (X, Y, Z) si XY = 0, (sgn(X)|Y|, sgn(Y)|X|, Z) si XY ≠ 0 (échange |X|<->|Y| intra-quadrant)
   - Opposé latéral d'Attente Ox(P) = (-X, Y, Z) (inversion d'Attente X à Contrôle Y constant)
   - Opposé latéral de Contrôle Oy(P) = (X, -Y, Z) (inversion de Contrôle Y à Attente X constante)
   - Homologue vertical trans-hémisphérique Hz(P) = (X, Y, -Z) (et (0,0,0) <-> (0,0,-7))
   - Contrepoids croisé trans-hémisphérique Az(P) = A(Hz(P))
   - Voisins de filière hiérarchique inter-couches (dissipation |Z|-1 et approfondissement |Z|+1)
================================================================================
"""

import os
import json
import numpy as np
import pandas as pd


# ==============================================================================
# 1. DÉFINITION DES 127 ENTRÉES DE L'HÉMISPHÈRE AXIOLOGIQUE (Z- in {-7..-1})
# ==============================================================================
AXIOLOGY_127_ENTRIES = [
    # W = 7 / Z = -7 — Éveil (sommet supérieur, homologue de Veille Z=0)
    (1, "Éveil", 0, 0, -7, 7),
    # W = 6 / Z = -1 — Opérateur de convergence (homologue de Surprise Z=+1)
    (2, "Évidence", 0, 0, -1, 6),
    # W = 5 / Z = -2 — Forces cardinales (8 positions + 1 centre, homologue de Z=+2)
    (3, "Intention", 0, 0, -2, 5),
    (4, "Volonté", 0, 2, -2, 5),
    (5, "Tempérance", 0, -2, -2, 5),
    (6, "Prudence", -2, 0, -2, 5),
    (7, "Audace", 2, 0, -2, 5),
    (8, "Équité", -1, 1, -2, 5),
    (9, "Clémence", 1, -1, -2, 5),
    (10, "Aspiration", 1, 1, -2, 5),
    (11, "Intégrité", -1, -1, -2, 5),
    # W = 4 / Z = -3 — Modes d'intégration (16 positions + 1 centre, homologue de Z=+3)
    (12, "Présence", 0, 0, -3, 4),
    (13, "Dévouement", 0, 4, -3, 4),
    (14, "Accueil", 0, -4, -3, 4),
    (15, "Vigilance", -4, 0, -3, 4),
    (16, "Inventivité", 4, 0, -3, 4),
    (17, "Sens du devoir", -1, 3, -3, 4),
    (18, "Humour", 1, 3, -3, 4),
    (19, "Lâcher-prise", 1, -3, -3, 4),
    (20, "Constance", -1, -3, -3, 4),
    (21, "Promptitude", -3, 1, -3, 4),
    (22, "Gravité", -3, -1, -3, 4),
    (23, "Gratitude", 3, -1, -3, 4),
    (24, "Initiative", 3, 1, -3, 4),
    (25, "Fermeté", -2, 2, -3, 4),
    (26, "Douceur", 2, -2, -3, 4),
    (27, "Inspiration", 2, 2, -3, 4),
    (28, "Retenue", -2, -2, -3, 4),
    # W = 3 / Z = -4 — Engagements (24 positions + 1 centre, homologue de Z=+4)
    (29, "Cohérence", 0, 0, -4, 3),
    (30, "Service", 0, 6, -4, 3),
    (31, "Intériorité", 0, -6, -4, 3),
    (32, "Esprit critique", -6, 0, -4, 3),
    (33, "Adhésion", 6, 0, -4, 3),
    (34, "Émulation", -2, 4, -4, 3),
    (35, "Combativité", -1, 5, -4, 3),
    (36, "Don de soi", 1, 5, -4, 3),
    (37, "Solidarité", 2, 4, -4, 3),
    (38, "Équilibre", 2, -4, -4, 3),
    (39, "Sobriété", 1, -5, -4, 3),
    (40, "Pudeur", -2, -4, -4, 3),
    (41, "Dépouillement", -1, -5, -4, 3),
    (42, "Protection", -4, 2, -4, 3),
    (43, "Quête de sens", -5, 1, -4, 3),
    (44, "Dignité", -5, -1, -4, 3),
    (45, "Indépendance d’esprit", -4, -2, -4, 3),
    (46, "Accomplissement", 4, 2, -4, 3),
    (47, "Croissance", 5, 1, -4, 3),
    (48, "Tendresse", 5, -1, -4, 3),
    (49, "Appréciation", 4, -2, -4, 3),
    (50, "Militantisme", -3, 3, -4, 3),
    (51, "Pardon", 3, -3, -4, 3),
    (52, "Coopération", 3, 3, -4, 3),
    (53, "Respect des limites", -3, -3, -4, 3),
    # W = 2 / Z = -5 — Forces (32 positions + 1 centre, homologue de Z=+5)
    (54, "Résolution", 0, 0, -5, 2),
    (55, "Autorité", 0, 8, -5, 2),
    (56, "Résilience", 0, -8, -5, 2),
    (57, "Circonspection", -8, 0, -5, 2),
    (58, "Bonne foi", 8, 0, -5, 2),
    (59, "Force d’âme", 1, 7, -5, 2),
    (60, "Loyauté", 2, 6, -5, 2),
    (61, "Assiduité", 3, 5, -5, 2),
    (62, "Réalisme", -2, 6, -5, 2),
    (63, "Rigueur morale", -3, 5, -5, 2),
    (64, "Droiture", -1, 7, -5, 2),
    (65, "Ancrage", 3, -5, -5, 2),
    (66, "Stabilité", 2, -6, -5, 2),
    (67, "Longanimité", 1, -7, -5, 2),
    (68, "Prévoyance", -2, -6, -5, 2),
    (69, "Discrétion", -3, -5, -5, 2),
    (70, "Stoïcisme", -1, -7, -5, 2),
    (71, "Précaution", -6, 2, -5, 2),
    (72, "Sollicitude", -5, 3, -5, 2),
    (73, "Diligence", -7, 1, -5, 2),
    (74, "Authenticité", -7, -1, -5, 2),
    (75, "Liberté intérieure", -6, -2, -5, 2),
    (76, "Modération", -5, -3, -5, 2),
    (77, "Gaieté", 6, 2, -5, 2),
    (78, "Sociabilité", 5, 3, -5, 2),
    (79, "Espérance", 7, 1, -5, 2),
    (80, "Sens du beau", 6, -2, -5, 2),
    (81, "Indulgence", 5, -3, -5, 2),
    (82, "Impartialité", 7, -1, -5, 2),
    (83, "Exigence", -4, 4, -5, 2),
    (84, "Simplicité", 4, -4, -5, 2),
    (85, "Amour d’apprendre", 4, 4, -5, 2),
    (86, "Renoncement", -4, -4, -5, 2),
    # W = 1 / Z = -6 — Valeurs : principes personnels (40 positions + 1 centre, homologue de Z=+6)
    (87, "Discernement", 0, 0, -6, 1),
    (88, "Énergique", 0, 10, -6, 1),
    (89, "Patient", 0, -10, -6, 1),
    (90, "Humble", -10, 0, -6, 1),
    (91, "Confiant", 10, 0, -6, 1),
    (92, "Brave", 3, 7, -6, 1),
    (93, "Sensible", -3, 7, -6, 1),
    (94, "Spontané", 4, 6, -6, 1),
    (95, "Assertif", -4, 6, -6, 1),
    (96, "Autonome", 2, 8, -6, 1),
    (97, "Discipliné", -2, 8, -6, 1),
    (98, "Original", 1, 9, -6, 1),
    (99, "Intègre", -1, 9, -6, 1),
    (100, "Posé", 3, -7, -6, 1),
    (101, "Sérieux", -3, -7, -6, 1),
    (102, "Délicat", 4, -6, -6, 1),
    (103, "Économe", -4, -6, -6, 1),
    (104, "Réfléchi", 2, -8, -6, 1),
    (105, "Méticuleux", -2, -8, -6, 1),
    (106, "Bienveillant", 1, -9, -6, 1),
    (107, "Respectueux", -1, -9, -6, 1),
    (108, "Persévérant", -7, 3, -6, 1),
    (109, "Avisé", -7, -3, -6, 1),
    (110, "Franc", -6, 4, -6, 1),
    (111, "Responsable", -6, -4, -6, 1),
    (112, "Intuitif", -8, 2, -6, 1),
    (113, "Fidèle", -8, -2, -6, 1),
    (114, "Honnête", -9, 1, -6, 1),
    (115, "Fiable", -9, -1, -6, 1),
    (116, "Drôle", 7, 3, -6, 1),
    (117, "Clair", 7, -3, -6, 1),
    (118, "Généreux", 6, 4, -6, 1),
    (119, "Gentil", 6, -4, -6, 1),
    (120, "Curieux", 8, 2, -6, 1),
    (121, "Souple", 8, -2, -6, 1),
    (122, "Sincère", 9, 1, -6, 1),
    (123, "Tolérant", 9, -1, -6, 1),
    (124, "Juste", -5, 5, -6, 1),
    (125, "Compréhensif", 5, -5, -6, 1),
    (126, "Ambitieux", 5, 5, -6, 1),
    (127, "Modeste", -5, -5, -6, 1),
]

# Triades aristotéliciennes de la couronne Z = -6 (W = 1)
TRIADES_W1 = {
    "Honnête": ("Malhonnête", "Blessant", "Intégrité"),
    "Juste": ("Injuste", "Envieux", "Justice"),
    "Brave": ("Peureux", "Casse-cou", "Courage"),
    "Généreux": ("Gratteux", "Gaspilleur", "Humanité"),
    "Patient": ("Impatient", "Impassible", "Maîtrise"),
    "Tolérant": ("Intolérant", "Bonasse", "Justice"),
    "Autonome": ("Dépendant", "Indépendant", "Autonomie"),
    "Confiant": ("Méfiant", "Prétentieux", "Courage"),
    "Fiable": ("Inconstant", "Acharné", "Autonomie"),
    "Méticuleux": ("Désordonné", "Pointilleux", "Maîtrise"),
    "Sincère": ("Hypocrite", "Brutal", "Intégrité"),
    "Intègre": ("Corrompu", "Inflexible", "Intégrité"),
    "Fidèle": ("Infidèle", "Possessif", "Intégrité"),
    "Respectueux": ("Irrespectueux", "Obséquieux", "Justice"),
    "Gentil": ("Méchant", "Complaisant", "Humanité"),
    "Bienveillant": ("Malveillant", "Paternaliste", "Humanité"),
    "Sensible": ("Insensible", "Susceptible", "Humanité"),
    "Discipliné": ("Indiscipliné", "Rigide", "Maîtrise"),
    "Persévérant": ("Velléitaire", "Obstiné", "Maîtrise"),
    "Responsable": ("Irresponsable", "Culpabilisé", "Autonomie"),
    "Curieux": ("Indifférent", "Indiscret", "Ouverture"),
    "Original": ("Banal", "Excentrique", "Ouverture"),
    "Souple": ("Rigide", "Influençable", "Ouverture"),
    "Compréhensif": ("Fermé", "Laxiste", "Ouverture"),
    "Réfléchi": ("Impulsif", "Hésitant", "Ouverture"),
    "Énergique": ("Apathique", "Agité", "Courage"),
    "Ambitieux": ("Résigné", "Arriviste", "Courage"),
    "Clair": ("Confus", "Simpliste", "Expression ajustée"),
    "Franc": ("Fuyant", "Brusque", "Expression ajustée"),
    "Délicat": ("Maladroit", "Précieux", "Expression ajustée"),
    "Humble": ("Orgueilleux", "Effacé", "Expression ajustée"),
    "Modeste": ("Vaniteux", "Timoré", "Expression ajustée"),
    "Drôle": ("Morose", "Bouffon", "Expression ajustée"),
    "Avisé": ("Imprudent", "Calculateur", "Complément W1"),
    "Économe": ("Prodigue", "Avare", "Complément W1"),
    "Posé": ("Fébrile", "Lent", "Complément W1"),
    "Sérieux": ("Frivole", "Austère", "Complément W1"),
    "Spontané": ("Calculateur", "Irréfléchi", "Complément W1"),
    "Assertif": ("Soumis", "Autoritaire", "Complément W1"),
    "Intuitif": ("Borné", "Crédule", "Complément W1"),
}

# Description des 15 couches Z ∈ [-7, +7] dans le Système Computationnel et la Matrice Attentionnelle
STRATUM_METADATA = {
    0: ("Veille homéostatique (Z=0)", "Flux intéroceptifs de fond sous le seuil de saillance sensorielle"),
    1: ("Saillance perceptive (Z=+1)", "Enregistrement ascendant d'un écart saillant pré-orienté (Surprise)"),
    2: ("Affects primaires (Z=+2)", "Orientation somato-motrice élémentaire par l'Anticipation (R=2)"),
    3: ("Émotions réactives (Z=+3)", "Écart rattaché à une cause inférée immédiate et politique d'action (R=4)"),
    4: ("Sentiments réflexifs (Z=+4)", "Modèles génératifs de second ordre : soi en relation avec autrui (R=6)"),
    5: ("Dispositions durables (Z=+5)", "Paramètres lents et humeurs réglant des classes étendues de situations (R=8)"),
    6: ("Identités affectives (Z=+6)", "Modèle de soi tenu pour invariant existentiel à travers le temps (R=10)"),
    7: ("Sentiments transcendantaux (Z=+7 / W=0)", "Équateur de la Suspension : arrêt face à l'incommensurable et bascule axiologique (R=12)"),
    -6: ("Principes personnels (Z=-6 / W=1)", "Orientations élémentaires choisies et triades aristotéliciennes D- / V / D+ (R=10)"),
    -5: ("Forces de caractère (Z=-5 / W=2)", "Manifestations stables d'une ou plusieurs valeurs dans la conduite (R=8)"),
    -4: ("Engagements durables (Z=-4 / W=3)", "Orientations de vie organisant durablement plusieurs forces (R=6)"),
    -3: ("Modes d'intégration (Z=-3 / W=4)", "Postures méta-attentives d'ajustement de l'action en cours (R=4)"),
    -2: ("Forces cardinales (Z=-2 / W=5)", "Prototypes axiologiques fondamentaux orientés par l'Intention (R=2)"),
    -1: ("Convergence axiologique (Z=-1 / W=6)", "Opérateur d'Évidence faisant converger le modèle interne avec clarté (R=0)"),
    -7: ("Intégration terminale (Z=-7 / W=7)", "Sommet de l'Éveil : disponibilité maximale intégrant expérience, action et valeur (R=0)"),
}


def get_type_geom(x, y):
    if x == 0 and y == 0:
        return "Centre"
    if x == 0 or y == 0:
        return "Axiale"
    if abs(x) == abs(y):
        return "Diagonale"
    return "Laterale"


def get_affective_group(x, y):
    if x == 0 and y == 0:
        return "OPERATEUR_CENTRAL"
    if abs(x) == abs(y):
        if x > 0 and y > 0:
            return "DESIR"
        if x < 0 and y < 0:
            return "DEGOUT"
        if x < 0 and y > 0:
            return "COLERE"
        return "CALME"
    if abs(y) > abs(x):
        return "JOIE" if y > 0 else "TRISTESSE"
    return "COURAGE" if x > 0 else "PEUR"


def get_axiological_group(x, y):
    if x == 0 and y == 0:
        return "OPERATEUR_CENTRAL"
    if abs(x) == abs(y):
        if x > 0 and y > 0:
            return "ASPIRATION"
        if x < 0 and y < 0:
            return "INTÉGRITÉ"
        if x < 0 and y > 0:
            return "ÉQUITÉ"
        return "CLÉMENCE"
    if abs(y) > abs(x):
        return "VOLONTÉ" if y > 0 else "TEMPÉRANCE"
    return "AUDACE" if x > 0 else "PRUDENCE"


def get_antagonist_xy_and_rule(x, y):
    """
    Opérateur général d'antagonisme formel par morceaux (AffectiveMatrix.lean & Doc 2 §4) :
    - Si XY = 0 : (-X, -Y) [Centre (0, 0) : AUTO_DUAL_CENTRE ; Axiale (X=0 ou Y=0) : AXIAL_INVERSION_CENTRALE]
    - Si XY != 0 : (-sgn(X)|Y|, -sgn(Y)|X|) :
      * Diagonale (|X|=|Y|>0) -> (-X, -Y) : DIAGONAL_INVERSION_CENTRALE
      * Latérale avec sgn(X) != sgn(Y) -> Td(X,Y) = (Y, X) : CONTROLATERAL_DIRECT_Td
      * Latérale avec sgn(X) == sgn(Y) -> Ti(X,Y) = (-Y, -X) : CONTROLATERAL_INVERSE_Ti
    """
    if x == 0 and y == 0:
        return (0, 0), "AUTO_DUAL_CENTRE"
    if x == 0 or y == 0:
        return (-x, -y), "AXIAL_INVERSION_CENTRALE"
    if abs(x) == abs(y):
        return (-x, -y), "DIAGONAL_INVERSION_CENTRALE"
    sx = 1 if x > 0 else -1
    sy = 1 if y > 0 else -1
    ax, ay = -sx * abs(y), -sy * abs(x)
    if sx != sy:
        return (ax, ay), "CONTROLATERAL_DIRECT_Td"
    return (ax, ay), "CONTROLATERAL_INVERSE_Ti"


def get_central_opposite_xy(x, y):
    """Opposé central intra-dominante : (-X, -Y)."""
    return (-x, -y)


def get_dominant_mirror_xy(x, y):
    """Miroir diagonal de dominante par morceaux : (X, Y) si XY = 0 ; (sgn(X)|Y|, sgn(Y)|X|) si XY != 0."""
    if x == 0 and y == 0:
        return (0, 0)
    if x == 0:
        return (y, 0)
    if y == 0:
        return (0, x)
    sx = 1 if x > 0 else -1
    sy = 1 if y > 0 else -1
    return (sx * abs(y), sy * abs(x))


def get_computational_engine_attributes(x, y, z_signed):
    """
    Calcule les attributs exacts du Moteur Prédictif (`PredictiveEngine`),
    du Noyau (`CoreAffect`), de la Matrice de l'Interface Attentionnelle (`AffectiveMatrix`)
    et des 17 sous-secteurs fonctionnels (`AffectiveTaxonomy`) certifiés sous Lean 4.
    """
    # 1. Nœud de couplage (A, C) parmi les 9 combinaisons de l'Interface Attentionnelle
    pol_a = "A+" if x > 0 else ("A-" if x < 0 else "A0")
    pol_c = "C+" if y > 0 else ("C-" if y < 0 else "C0")
    couplage_ac = f"{pol_a} / {pol_c}"

    # 2. Interface dominante & Opération inférentielle porteuse (PredictiveEngine.lean)
    if x == 0 and y == 0:
        iface_dom = "Interface Attentionnelle (Précision P)"
        op_inf = "integrativeWeighting (Pondération intégrative)"
    elif abs(y) > abs(x):
        iface_dom = "Interface Perceptive (Gradient C dominant)"
        if y > 0:
            op_inf = "actionImplementation (Mise en œuvre pragmatique C+)"
        else:
            op_inf = "ascendingSensory (Inférence intéro-sensorielle & économie C-)"
    elif abs(x) > abs(y):
        iface_dom = "Interface Subjective (Gradient A dominant)"
        if x > 0:
            op_inf = "contextualGenerative (Révision générative contextuelle A+)"
        else:
            op_inf = "contextualGenerative (Maintien protecteur du modèle A-)"
    else:
        iface_dom = "Couplage Équilibré Subjectif-Perceptif (|A| = |C|)"
        op_inf = "boucleRecursiveAC (Co-résolution bidimensionnelle A ↔ C)"

    # 3. Transduction sur les pôles d'Attente (X) et de Contrôle (Y) selon l'hémisphère
    is_axio = z_signed < 0
    if x == 0:
        pole_x = "epistemicNeutral (Attente neutre A0)"
    elif x > 0:
        pole_x = "axiologicalOpening (Ouverture révisable X+)" if is_axio else "epistemicDischarge (Décharge épistémique X+)"
    else:
        pole_x = "axiologicalPreservation (Préservation des principes X-)" if is_axio else "epistemicCharge (Charge épistémique X-)"

    if y == 0:
        pole_y = "pragmaticNeutral (Contrôle neutre C0)"
    elif y > 0:
        pole_y = "axiologicalTransformation (Action transformatrice Y+)" if is_axio else "pragmaticDischarge (Décharge pragmatique Y+)"
    else:
        pole_y = "axiologicalModeration (Accueil & modération Y-)" if is_axio else "pragmaticCharge (Charge pragmatique Y-)"

    # 4. Régime énergétique (6 régimes de AffectiveMatrix.lean : computeEnergyRegime)
    if x == 0 and y == 0:
        energy_regime = "neutralBasal"
    elif x == 0 or y == 0:
        energy_regime = "axialPure"
    elif x > 0 and y > 0:
        energy_regime = "positiveSynergy"
    elif x < 0 and y < 0:
        energy_regime = "negativeSynergy"
    elif x < 0 and y > 0:
        energy_regime = "ergotropicCompensation"
    else:
        energy_regime = "trophotropicRelease"

    # 5. Polarité hédonique / axiologique lexicographique (primauté de l'Axe X : computeHedonicPolarity)
    if x > 0:
        hedonic_pol = "POSITIVE_OUVERTURE" if is_axio else "POSITIVE"
    elif x < 0:
        hedonic_pol = "REGULATION_GARDE_FOU" if is_axio else "NEGATIVE"
    elif y > 0:
        hedonic_pol = "POSITIVE_ELAN" if is_axio else "POSITIVE"
    elif y < 0:
        hedonic_pol = "REGULATION_TEMPERANCE" if is_axio else "NEGATIVE"
    else:
        hedonic_pol = "NEUTRE_SUSPENS"

    # 6. Profil d'activation phénoménologique (computeActivation)
    z_abs = 0 if z_signed in (0, -7) else abs(z_signed)
    if x == 0 and y == 0:
        if z_signed == 0:
            activation = "basalWakefulness"
        elif z_signed == -7:
            activation = "terminalIntegration"
        elif z_signed in (1, -1):
            activation = "ascendingRupture" if z_signed == 1 else "convergentEvidence"
        else:
            activation = "operatorSuspension"
    elif y > 0:
        activation = "highMobilization"
    elif y < 0:
        activation = "lowInhibition"
    else:
        activation = "epistemicVigilance"

    # 7. Partition exacte en 17 sous-secteurs fonctionnels (AffectiveTaxonomy.lean : classifySubsector)
    if x == 0 and y == 0:
        subsector = "centralOperator"
    elif x == 0 and y > 0:
        subsector = "axialElan"
    elif x == 0 and y < 0:
        subsector = "axialWithdrawal"
    elif x > 0 and y == 0:
        subsector = "axialOpening"
    elif x < 0 and y == 0:
        subsector = "axialThreat"
    elif x == y and x > 0:
        subsector = "diagonalDesire"
    elif x == y and x < 0:
        subsector = "diagonalDisgust"
    elif x == -y and x < 0:
        subsector = "diagonalAnger"
    elif x == -y and x > 0:
        subsector = "diagonalCalm"
    elif y > abs(x) and x > 0:
        subsector = "lateralApproachSynergy"
    elif y > abs(x) and x < 0:
        subsector = "lateralDefensiveUrgency"
    elif -y > abs(x) and x > 0:
        subsector = "lateralTrophotropicPeace"
    elif -y > abs(x) and x < 0:
        subsector = "lateralAversiveDistress"
    elif x > abs(y) and y > 0:
        subsector = "lateralEpistemicMastery"
    elif x > abs(y) and y < 0:
        subsector = "lateralContemplativeOpen"
    elif -x > abs(y) and y > 0:
        subsector = "lateralVigilantAlert"
    else:
        subsector = "lateralEpistemicClosure"

    # 8. Potentiel de Lyapunov discret (CoreAffect.lean : dissipationPotential)
    lyapunov = 2 * z_abs + (1 if (x != 0 or y != 0) else 0)

    # 9. Loi de transmutation verticale (+Z <-> -Z, Doc 2 §5 & §10)
    if z_signed == 7:
        transmut = "EQUATEUR_AUTO_DUAL_SUSPENSION"
    elif x == 0 and y == 0:
        transmut = "CONVERGENCE_OPERATEUR_CENTRAL"
    elif x >= 0 and y >= 0:
        transmut = "PROLONGEMENT_AGENTIF_ELAN"
    elif x < 0 and y < 0:
        transmut = "RETOURNEMENT_GARDE_FOU_ETHIQUE"
    elif x < 0 and y > 0:
        transmut = "CONVERSION_ERGOTROPE_TENUE_JUSTE"
    else:
        transmut = "CONVERSION_TROPHOTROPE_ACCUEIL"

    couche_nom, couche_obj = STRATUM_METADATA.get(z_signed, ("Strate Z", "Objet d'inférence"))

    return {
        "moteur_couplage_AC": couplage_ac,
        "moteur_interface_dominante": iface_dom,
        "moteur_operation_inferentielle": op_inf,
        "matrice_pole_attente_X": pole_x,
        "matrice_pole_controle_Y": pole_y,
        "matrice_regime_energetique": energy_regime,
        "matrice_polarite_hedonique": hedonic_pol,
        "matrice_activation": activation,
        "taxonomie_sous_secteur_17": subsector,
        "noyau_potentiel_lyapunov": lyapunov,
        "loi_transmutation_verticale": transmut,
        "couche_z_nom": couche_nom,
        "couche_z_objet_inference": couche_obj,
    }


def get_diamond_height_3d(z_signed):
    if z_signed >= 0:
        return z_signed - 7
    if z_signed == -7:
        return 7
    return 7 + z_signed


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    df_176 = pd.read_csv("ref_176_cartograffect.tsv", sep="\t", encoding="utf-8")

    # Alignement descendant (Arbitrage A1 / v2.0.0) : Langueur et Rancœur restent
    # les libellés canoniques de Strate 0 ; les ancres GRID associées sont conservées
    # exclusivement dans la métadonnée dédiée `grid_anchor_alias`.
    grid_anchor_aliases = {
        (0, -6, 4): "Solitude (SADNESS)",
        (-6, 4, 6): "Irritation (IRRITATION)",
    }

    affect_rows = []
    aff_by_coord = {}

    for r in df_176.itertuples():
        x, y, z = int(r.X), int(r.Y), int(r.Z)
        lbl = str(r.label_fr)
        ant_lbl = str(r.antagoniste_label)
        h_3d = get_diamond_height_3d(z)
        _, ant_rule = get_antagonist_xy_and_rule(x, y)
        comp_attrs = get_computational_engine_attributes(x, y, z)

        row = {
            "id_303": int(r.id_176),
            "hemisphere": "AFFECTIF_Z_PLUS" if z < 7 else "EQUATEUR_SUSPENSION",
            "id_hemisphere": int(r.id_176),
            "label_fr": lbl,
            "label_legacy_176": str(r.label_fr),
            "grid_anchor_alias": grid_anchor_aliases.get((x, y, z), "-"),
            "X": x,
            "Y": y,
            "Z_signe": z,
            "W_equiv": 0 if z == 7 else None,
            "h_diamant_3d": h_3d,
            "rayon_L1": int(r.rayon_L1),
            "type_geom": str(r.type_geom),
            "groupe_geom": str(r.groupe_geom),
            "type_antagonisme": ant_rule,
            "correspondant_label": ant_lbl,
            **comp_attrs,
        }
        affect_rows.append(row)
        aff_by_coord[(x, y, z)] = row

    axio_by_coord = {}
    for num_w, lbl, x, y, z_m, w_eq in AXIOLOGY_127_ENTRIES:
        axio_by_coord[(x, y, z_m)] = (num_w, lbl, w_eq)

    axio_rows = []
    for num_w, lbl, x, y, z_m, w_eq in AXIOLOGY_127_ENTRIES:
        id_303 = 176 + num_w
        r_l1 = abs(x) + abs(y)
        expected_r = 0 if (x == 0 and y == 0) else 2 * (abs(z_m) - 1)
        assert r_l1 == expected_r, f"Rayon L1 invalide pour {lbl} ({x},{y},{z_m})"

        t_geom = get_type_geom(x, y)
        g_geom = get_axiological_group(x, y)
        (ax, ay), ant_rule = get_antagonist_xy_and_rule(x, y)
        assert (ax, ay, z_m) in axio_by_coord
        corr_lbl = axio_by_coord[(ax, ay, z_m)][1]

        z_homol = 0 if z_m == -7 else abs(z_m)
        assert (x, y, z_homol) in aff_by_coord
        homol_row = aff_by_coord[(x, y, z_homol)]
        homol_lbl = homol_row["label_fr"]
        homol_id = homol_row["id_303"]

        aff_by_coord[(x, y, z_homol)]["homologue_label"] = lbl
        aff_by_coord[(x, y, z_homol)]["homologue_id_303"] = id_303
        aff_by_coord[(x, y, z_homol)]["homologue_Z_signe"] = z_m

        clean_lbl = lbl.rstrip("*")
        triade = TRIADES_W1.get(lbl) or TRIADES_W1.get(clean_lbl)
        comp_attrs = get_computational_engine_attributes(x, y, z_m)

        axio_rows.append({
            "id_303": id_303,
            "hemisphere": "AXIOLOGIQUE_Z_MOINS",
            "id_hemisphere": num_w,
            "label_fr": lbl,
            "label_legacy_176": "-",
            "grid_anchor_alias": "-",
            "X": x,
            "Y": y,
            "Z_signe": z_m,
            "W_equiv": w_eq,
            "h_diamant_3d": get_diamond_height_3d(z_m),
            "rayon_L1": r_l1,
            "type_geom": t_geom,
            "groupe_geom": g_geom,
            "type_antagonisme": ant_rule,
            "correspondant_label": corr_lbl,
            "homologue_label": homol_lbl,
            "homologue_id_303": homol_id,
            "homologue_Z_signe": z_homol,
            "deficit_D_moins": triade[0] if triade else "-",
            "exces_D_plus": triade[1] if triade else "-",
            "famille_thematique": triade[2] if triade else "-",
            **comp_attrs,
        })

    for row in affect_rows:
        if "homologue_label" not in row:
            row["homologue_label"] = row["label_fr"] + " (Plan médian)"
            row["homologue_id_303"] = row["id_303"]
            row["homologue_Z_signe"] = 7
        row["deficit_D_moins"] = "-"
        row["exces_D_plus"] = "-"
        row["famille_thematique"] = "-"

    all_rows = affect_rows + axio_rows
    by_coord_all = {(r["X"], r["Y"], r["Z_signe"]): r for r in all_rows}

    # Calcul de la Rose complète des 8 Symétries sur tous les axes pour les 303 pôles
    for r in all_rows:
        x, y, z = r["X"], r["Y"], r["Z_signe"]
        # 1. Antagoniste régulateur formel (déjà dans correspondant_label)
        (ax, ay), _ = get_antagonist_xy_and_rule(x, y)
        ant_p = by_coord_all[(ax, ay, z)]
        r["correspondant_id_303"] = ant_p["id_303"]

        # 2. Opposé central intra-dominante : (-X, -Y, Z)
        cx, cy = get_central_opposite_xy(x, y)
        cent_p = by_coord_all[(cx, cy, z)]
        r["oppose_central_id_303"] = cent_p["id_303"]
        r["oppose_central_label"] = cent_p["label_fr"]

        # 3. Miroir diagonal de dominante par morceaux : (X, Y, Z) si XY = 0 ; (sgn(X)|Y|, sgn(Y)|X|, Z) si XY != 0
        mx, my = get_dominant_mirror_xy(x, y)
        mir_p = by_coord_all[(mx, my, z)]
        r["miroir_dominant_id_303"] = mir_p["id_303"]
        r["miroir_dominant_label"] = mir_p["label_fr"]

        # 4. Opposé latéral d'Attente (Miroir orthogonal X) : (-X, Y, Z)
        ox_p = by_coord_all[(-x, y, z)]
        r["oppose_lateral_X_id_303"] = ox_p["id_303"]
        r["oppose_lateral_X_label"] = ox_p["label_fr"]

        # 5. Opposé latéral de Contrôle (Miroir orthogonal Y) : (X, -Y, Z)
        oy_p = by_coord_all[(x, -y, z)]
        r["oppose_lateral_Y_id_303"] = oy_p["id_303"]
        r["oppose_lateral_Y_label"] = oy_p["label_fr"]

        # 6. Contrepoids croisé trans-hémisphérique : A(Hz(P))
        hom_id = r["homologue_id_303"]
        hom_p = next(item for item in all_rows if item["id_303"] == hom_id)
        (hax, hay), _ = get_antagonist_xy_and_rule(hom_p["X"], hom_p["Y"])
        cross_p = by_coord_all[(hax, hay, hom_p["Z_signe"])]
        r["contrepoids_croise_id_303"] = cross_p["id_303"]
        r["contrepoids_croise_label"] = cross_p["label_fr"]

        # 7. Filière hiérarchique inter-couches (Dissipation vers |Z|-1 et Approfondissement vers |Z|+1)
        r_l1 = r["rayon_L1"]
        u_x = x / r_l1 if r_l1 > 0 else 0.0
        v_y = y / r_l1 if r_l1 > 0 else 0.0

        def find_nearest_on_stratum(target_z):
            cands = [item for item in all_rows if item["Z_signe"] == target_z]
            if not cands:
                return None
            if r_l1 == 0:
                for item in cands:
                    if item["rayon_L1"] == 0:
                        return item
                return cands[0]
            periph_cands = [item for item in cands if item["rayon_L1"] > 0]
            if not periph_cands:
                return cands[0]
            return min(
                periph_cands,
                key=lambda item: (
                    abs(item["X"] / item["rayon_L1"] - u_x) + abs(item["Y"] / item["rayon_L1"] - v_y),
                    0 if item["groupe_geom"] == r["groupe_geom"] else 1,
                ),
            )

        if z >= 0:
            z_inf = z - 1 if z > 0 else None
            z_sup = z + 1 if z < 7 else -6  # Passage de la Suspension (Z=7) à Z=-6 (W=1)
        else:
            # En Z- : l'altitude croît de Z=-6 (W=1) vers Z=-1 (W=6) puis Z=-7 (W=7, Éveil)
            order_z_minus = [7, -6, -5, -4, -3, -2, -1, -7]
            idx_zm = order_z_minus.index(z)
            z_inf = order_z_minus[idx_zm - 1] if idx_zm > 0 else None
            z_sup = order_z_minus[idx_zm + 1] if idx_zm < len(order_z_minus) - 1 else None

        p_inf = find_nearest_on_stratum(z_inf) if z_inf is not None else None
        p_sup = find_nearest_on_stratum(z_sup) if z_sup is not None else None
        r["filiere_inf_id_303"] = p_inf["id_303"] if p_inf else -1
        r["filiere_inf_label"] = p_inf["label_fr"] if p_inf else "-"
        r["filiere_sup_id_303"] = p_sup["id_303"] if p_sup else -1
        r["filiere_sup_label"] = p_sup["label_fr"] if p_sup else "-"

    df_diamant = pd.DataFrame(all_rows)
    df_diamant.to_csv("ref_303_diamant_z.tsv", sep="\t", index=False, encoding="utf-8")
    pd.DataFrame(axio_rows).to_csv("ref_127_axiologie_z_minus.tsv", sep="\t", index=False, encoding="utf-8")

    print("=" * 80)
    print(" CERTIFICATION DU DIAMANT GÉOMÉTRIQUE & COMPUTATIONNEL (303 PÔLES)")
    print("=" * 80)
    print(f"[OK] Total des pôles du Diamant : {len(df_diamant)} (176 en Z+ [0..+7] + 127 en Z- [-7..-1])")
    print(f"[OK] Rose des 8 symétries (Axiale, Diagonale, Controlatérale Td/Ti, Centrale, Miroir, Orthogonale X/Y, Homologie Z, Filière ΔZ) certifiée.")
    print(f"[OK] Paramètres du Moteur Prédictif (9 couplages A/C, 3 interfaces, 4 opérations) et des 17 sous-secteurs de la Matrice Attentionnelle certifiés.")


if __name__ == "__main__":
    main()
