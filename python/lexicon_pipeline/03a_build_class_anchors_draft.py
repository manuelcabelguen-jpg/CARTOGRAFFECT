# SPDX-License-Identifier: AGPL-3.0-or-later
"""
03a_build_class_anchors_draft.py — Micro-Passe 3 : Extraction Lean 4 v3.0.0 &
Table d'ancrage clinique des 109 classes DIMA vers Z in {3, 4, 5} et 17 FunctionalSubsector.

Périmètre strict :
- Lecture seule sur Cartograffect/ (noyau Lean 4 normatif v3.0.0 intouché).
- Lecture seule sur data/processed/dima_classes_summary.csv et
  data/processed/dima_z_plus_psychometrics.parquet.
- Aucun accès aux fichiers Diamant_303.
- Aucun chemin absolu utilisateur/Windows écrit dans les sorties.
- Strictement idempotent (sorties déterministes octet pour octet, fins de ligne LF).
- Zéro appel réseau / API externe.

Exports :
- data/config/canonical_z0_z2_anchors.json
- data/config/dima_class_to_subsector_109.yaml
- reports/lexicon_v3/mp3_anchors_review.md
"""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Any

import pandas as pd

REPO_ROOT = Path(__file__).resolve().parents[2]
LEAN_DIR = REPO_ROOT / "Cartograffect"
CORE_AFFECT_LEAN = LEAN_DIR / "CoreAffect.lean"
MATRIX_LEAN = LEAN_DIR / "AffectiveMatrix.lean"
TAXONOMY_LEAN = LEAN_DIR / "AffectiveTaxonomy.lean"
OPERANT_LEAN = LEAN_DIR / "OperantFactorization.lean"

SUMMARY_CSV_PATH = REPO_ROOT / "data" / "processed" / "dima_classes_summary.csv"
Z_PLUS_PARQUET_PATH = REPO_ROOT / "data" / "processed" / "dima_z_plus_psychometrics.parquet"

ANCHORS_JSON_PATH = REPO_ROOT / "data" / "config" / "canonical_z0_z2_anchors.json"
DRAFT_YAML_PATH = REPO_ROOT / "data" / "config" / "dima_class_to_subsector_109.yaml"
REVIEW_MD_PATH = REPO_ROOT / "reports" / "lexicon_v3" / "mp3_anchors_review.md"

CART_VERSION = "3.0.0"

# =============================================================================
# 1. EXTRACTION VERBATIM DU NOYAU NORMATIF LEAN 4 (LECTURE SEULE)
# =============================================================================

SUBSECTOR_GEOMETRY_SPEC: dict[str, dict[str, Any]] = {
    "centralOperator": {
        "pair_id": "CENTER",
        "block": "Centre fixe",
        "conjugate_subsector": "centralOperator",
        "u_x": 0.0,
        "u_y": 0.0,
        "l1_norm": 0.0,
        "quadrant": "CENTER",
        "ray_description": "X = 0, Y = 0 (Opérateurs centraux de suspens)",
        "z2_prototype": "anticipation",
        "tableau_1b_z3_high_A": "Émoi (0, 0, 3)",
        "tableau_1b_z3_low_A": "Émoi (0, 0, 3)",
        "tableau_1b_z4_high_A": "Réserve (0, 0, 4)",
        "tableau_1b_z4_low_A": "Réserve (0, 0, 4)",
        "tableau_1b_z5_high_A": "Recul (0, 0, 5)",
        "tableau_1b_z5_low_A": "Recul (0, 0, 5)",
    },
    "axialExpectationPos": {
        "pair_id": "A1",
        "block": "Bloc A (axial)",
        "conjugate_subsector": "axialExpectationNeg",
        "u_x": 1.0,
        "u_y": 0.0,
        "l1_norm": 1.0,
        "quadrant": "AXIS_POS_X",
        "ray_description": "X > 0, Y = 0 (Attente positive pure)",
        "z2_prototype": "courage",
        "tableau_1b_z3_high_A": "Audace",
        "tableau_1b_z3_low_A": "Curiosité",
        "tableau_1b_z4_high_A": "Détermination",
        "tableau_1b_z4_low_A": "Confiance",
        "tableau_1b_z5_high_A": "Conviction",
        "tableau_1b_z5_low_A": "Lucidité",
    },
    "axialExpectationNeg": {
        "pair_id": "A1",
        "block": "Bloc A (axial)",
        "conjugate_subsector": "axialExpectationPos",
        "u_x": -1.0,
        "u_y": 0.0,
        "l1_norm": 1.0,
        "quadrant": "AXIS_NEG_X",
        "ray_description": "X < 0, Y = 0 (Attente négative pure)",
        "z2_prototype": "peur",
        "tableau_1b_z3_high_A": "Frayeur",
        "tableau_1b_z3_low_A": "Inquiétude",
        "tableau_1b_z4_high_A": "Effroi",
        "tableau_1b_z4_low_A": "Méfiance",
        "tableau_1b_z5_high_A": "Épouvante",
        "tableau_1b_z5_low_A": "Insécurité",
    },
    "axialControlPos": {
        "pair_id": "A2",
        "block": "Bloc A (axial)",
        "conjugate_subsector": "axialControlNeg",
        "u_x": 0.0,
        "u_y": 1.0,
        "l1_norm": 1.0,
        "quadrant": "AXIS_POS_Y",
        "ray_description": "X = 0, Y > 0 (Contrôle positif pur)",
        "z2_prototype": "joie",
        "tableau_1b_z3_high_A": "Allégresse",
        "tableau_1b_z3_low_A": "Contentement",
        "tableau_1b_z4_high_A": "Euphorie",
        "tableau_1b_z4_low_A": "Bien-être",
        "tableau_1b_z5_high_A": "Jubilation",
        "tableau_1b_z5_low_A": "Épanouissement",
    },
    "axialControlNeg": {
        "pair_id": "A2",
        "block": "Bloc A (axial)",
        "conjugate_subsector": "axialControlPos",
        "u_x": 0.0,
        "u_y": -1.0,
        "l1_norm": 1.0,
        "quadrant": "AXIS_NEG_Y",
        "ray_description": "X = 0, Y < 0 (Contrôle négatif pur)",
        "z2_prototype": "tristesse",
        "tableau_1b_z3_high_A": "Chagrin",
        "tableau_1b_z3_low_A": "Mélancolie",
        "tableau_1b_z4_high_A": "Affliction",
        "tableau_1b_z4_low_A": "Lassitude",
        "tableau_1b_z5_high_A": "Désolation",
        "tableau_1b_z5_low_A": "Abattement",
    },
    "diagonalSynergyPos": {
        "pair_id": "D1",
        "block": "Bloc A (diagonal)",
        "conjugate_subsector": "diagonalSynergyNeg",
        "u_x": 0.5,
        "u_y": 0.5,
        "l1_norm": 1.0,
        "quadrant": "Q1_DIAG",
        "ray_description": "X = Y > 0 (Synergie positive / congruence de décharge)",
        "z2_prototype": "desir",
        "tableau_1b_z3_high_A": "Enthousiasme",
        "tableau_1b_z3_low_A": "Attrait",
        "tableau_1b_z4_high_A": "Passion",
        "tableau_1b_z4_low_A": "Affection",
        "tableau_1b_z5_high_A": "Amour",
        "tableau_1b_z5_low_A": "Attachement",
    },
    "diagonalSynergyNeg": {
        "pair_id": "D1",
        "block": "Bloc A (diagonal)",
        "conjugate_subsector": "diagonalSynergyPos",
        "u_x": -0.5,
        "u_y": -0.5,
        "l1_norm": 1.0,
        "quadrant": "Q3_DIAG",
        "ray_description": "X = Y < 0 (Synergie négative / rejet aversif à faible contrôle)",
        "z2_prototype": "degout",
        "tableau_1b_z3_high_A": "Révulsion",
        "tableau_1b_z3_low_A": "Malaise",
        "tableau_1b_z4_high_A": "Aversion",
        "tableau_1b_z4_low_A": "Écœurement",
        "tableau_1b_z5_high_A": "Répulsion",
        "tableau_1b_z5_low_A": "Rejet durable",
    },
    "diagonalAgenticConfront": {
        "pair_id": "D2",
        "block": "Bloc A (diagonal)",
        "conjugate_subsector": "diagonalAccommodation",
        "u_x": -0.5,
        "u_y": 0.5,
        "l1_norm": 1.0,
        "quadrant": "Q2_DIAG",
        "ray_description": "X = -Y < 0 (Affrontement agentique équilibré)",
        "z2_prototype": "colere",
        "tableau_1b_z3_high_A": "Exaspération",
        "tableau_1b_z3_low_A": "Agacement",
        "tableau_1b_z4_high_A": "Rage",
        "tableau_1b_z4_low_A": "Contrariété",
        "tableau_1b_z5_high_A": "Haine",
        "tableau_1b_z5_low_A": "Rancœur",
    },
    "diagonalAccommodation": {
        "pair_id": "D2",
        "block": "Bloc A (diagonal)",
        "conjugate_subsector": "diagonalAgenticConfront",
        "u_x": 0.5,
        "u_y": -0.5,
        "l1_norm": 1.0,
        "quadrant": "Q4_DIAG",
        "ray_description": "X = -Y > 0 (Accommodation face à une limite objective d'action)",
        "z2_prototype": "calme",
        "tableau_1b_z3_high_A": "Délivrance",
        "tableau_1b_z3_low_A": "Apaisement",
        "tableau_1b_z4_high_A": "Soulagement",
        "tableau_1b_z4_low_A": "Quiétude",
        "tableau_1b_z5_high_A": "Sagesse apaisée",
        "tableau_1b_z5_low_A": "Paix intérieure",
    },
    "lateralEpistemicMastery": {
        "pair_id": "L1",
        "block": "Bloc B (latéral contralatéral)",
        "conjugate_subsector": "lateralAversiveDistress",
        "u_x": 0.75,
        "u_y": 0.25,
        "l1_norm": 1.0,
        "quadrant": "Q1_DOM_POS_X",
        "ray_description": "X > |Y|, Y > 0 (Ouverture épistémique maîtrisée)",
        "z2_prototype": None,
        "tableau_1b_z3_high_A": "Élan",
        "tableau_1b_z3_low_A": "Satisfaction",
        "tableau_1b_z4_high_A": "Fierté",
        "tableau_1b_z4_low_A": "Estime",
        "tableau_1b_z5_high_A": "Optimisme actif",
        "tableau_1b_z5_low_A": "Espoir",
    },
    "lateralAversiveDistress": {
        "pair_id": "L1",
        "block": "Bloc B (latéral contralatéral)",
        "conjugate_subsector": "lateralEpistemicMastery",
        "u_x": -0.25,
        "u_y": -0.75,
        "l1_norm": 1.0,
        "quadrant": "Q3_DOM_NEG_Y",
        "ray_description": "Y < -|X|, X < 0 (Faible contrôle aversif)",
        "z2_prototype": None,
        "tableau_1b_z3_high_A": "Déception vive",
        "tableau_1b_z3_low_A": "Découragement",
        "tableau_1b_z4_high_A": "Honte",
        "tableau_1b_z4_low_A": "Résignation",
        "tableau_1b_z5_high_A": "Désespoir",
        "tableau_1b_z5_low_A": "Apathie",
    },
    "lateralApproachSynergy": {
        "pair_id": "L2",
        "block": "Bloc B (latéral contralatéral)",
        "conjugate_subsector": "lateralEpistemicClosure",
        "u_x": 0.25,
        "u_y": 0.75,
        "l1_norm": 1.0,
        "quadrant": "Q1_DOM_POS_Y",
        "ray_description": "Y > |X|, X > 0 (Engagement instrumental favorable ; sécurité/plénitude à A bas)",
        "z2_prototype": None,
        "tableau_1b_z3_high_A": "Assurance",
        "tableau_1b_z3_low_A": "Plaisir paisible",
        "tableau_1b_z4_high_A": "Exaltation",
        "tableau_1b_z4_low_A": "Sérénité",
        "tableau_1b_z5_high_A": "Plénitude",
        "tableau_1b_z5_low_A": "Sécurité",
    },
    "lateralEpistemicClosure": {
        "pair_id": "L2",
        "block": "Bloc B (latéral contralatéral)",
        "conjugate_subsector": "lateralApproachSynergy",
        "u_x": -0.75,
        "u_y": -0.25,
        "l1_norm": 1.0,
        "quadrant": "Q3_DOM_NEG_X",
        "ray_description": "X < -|Y|, Y < 0 (Fermeture épistémique à faible contrôle)",
        "z2_prototype": None,
        "tableau_1b_z3_high_A": "Alarme",
        "tableau_1b_z3_low_A": "Anxiété",
        "tableau_1b_z4_high_A": "Angoisse",
        "tableau_1b_z4_low_A": "Appréhension diffuse",
        "tableau_1b_z5_high_A": "Terreur",
        "tableau_1b_z5_low_A": "Tourment",
    },
    "lateralAgenticConfront": {
        "pair_id": "L3",
        "block": "Bloc B (latéral contralatéral)",
        "conjugate_subsector": "lateralReceptiveAccomm",
        "u_x": -0.25,
        "u_y": 0.75,
        "l1_norm": 1.0,
        "quadrant": "Q2_DOM_POS_Y",
        "ray_description": "Y > |X|, X < 0 (Affrontement agentique à contrôle dominant)",
        "z2_prototype": None,
        "tableau_1b_z3_high_A": "Frustration",
        "tableau_1b_z3_low_A": "Opposition",
        "tableau_1b_z4_high_A": "Hostilité",
        "tableau_1b_z4_low_A": "Ressentiment",
        "tableau_1b_z5_high_A": "Révolte",
        "tableau_1b_z5_low_A": "Amertume",
    },
    "lateralReceptiveAccomm": {
        "pair_id": "L3",
        "block": "Bloc B (latéral contralatéral)",
        "conjugate_subsector": "lateralAgenticConfront",
        "u_x": 0.75,
        "u_y": -0.25,
        "l1_norm": 1.0,
        "quadrant": "Q4_DOM_POS_X",
        "ray_description": "X > |Y|, Y < 0 (Accommodation réceptive face à une limite d'action)",
        "z2_prototype": None,
        "tableau_1b_z3_high_A": "Résilience vive",
        "tableau_1b_z3_low_A": "Acceptation",
        "tableau_1b_z4_high_A": "Endurance active",
        "tableau_1b_z4_low_A": "Patience",
        "tableau_1b_z5_high_A": "Stoïcisme",
        "tableau_1b_z5_low_A": "Consentement lucide",
    },
    "lateralActiveContest": {
        "pair_id": "L4",
        "block": "Bloc B (latéral contralatéral)",
        "conjugate_subsector": "lateralSecondaryAccomm",
        "u_x": -0.75,
        "u_y": 0.25,
        "l1_norm": 1.0,
        "quadrant": "Q2_DOM_NEG_X",
        "ray_description": "X < -|Y|, Y > 0 (Menace épistémique sous maintien d'action)",
        "z2_prototype": None,
        "tableau_1b_z3_high_A": "Contestation",
        "tableau_1b_z3_low_A": "Dépit",
        "tableau_1b_z4_high_A": "Indignation",
        "tableau_1b_z4_low_A": "Mépris froid",
        "tableau_1b_z5_high_A": "Défiance combative",
        "tableau_1b_z5_low_A": "Cynisme",
    },
    "lateralSecondaryAccomm": {
        "pair_id": "L4",
        "block": "Bloc B (latéral contralatéral)",
        "conjugate_subsector": "lateralActiveContest",
        "u_x": 0.25,
        "u_y": -0.75,
        "l1_norm": 1.0,
        "quadrant": "Q4_DOM_NEG_Y",
        "ray_description": "Y < -|X|, X > 0 (Accommodation secondaire à limite d'action dominante)",
        "z2_prototype": None,
        "tableau_1b_z3_high_A": "Répit vif",
        "tableau_1b_z3_low_A": "Relâchement",
        "tableau_1b_z4_high_A": "Détachement",
        "tableau_1b_z4_low_A": "Lâcher-prise",
        "tableau_1b_z5_high_A": "Recul serein",
        "tableau_1b_z5_low_A": "Abandon confiant",
    },
}

CONJUGATE_PAIRS_META: list[dict[str, Any]] = [
    {"pair_id": "A1", "block": "Bloc A (axial)", "subsector_pos": "axialExpectationPos", "subsector_neg": "axialExpectationNeg", "relation": "inversion_centrale"},
    {"pair_id": "A2", "block": "Bloc A (axial)", "subsector_pos": "axialControlPos", "subsector_neg": "axialControlNeg", "relation": "inversion_centrale"},
    {"pair_id": "D1", "block": "Bloc A (diagonal)", "subsector_pos": "diagonalSynergyPos", "subsector_neg": "diagonalSynergyNeg", "relation": "inversion_centrale"},
    {"pair_id": "D2", "block": "Bloc A (diagonal)", "subsector_pos": "diagonalAccommodation", "subsector_neg": "diagonalAgenticConfront", "relation": "inversion_centrale"},
    {"pair_id": "L1", "block": "Bloc B (latéral contralatéral)", "subsector_pos": "lateralEpistemicMastery", "subsector_neg": "lateralAversiveDistress", "relation": "echange_contralateral_abs_X_abs_Y"},
    {"pair_id": "L2", "block": "Bloc B (latéral contralatéral)", "subsector_pos": "lateralApproachSynergy", "subsector_neg": "lateralEpistemicClosure", "relation": "echange_contralateral_abs_X_abs_Y"},
    {"pair_id": "L3", "block": "Bloc B (latéral contralatéral)", "subsector_pos": "lateralReceptiveAccomm", "subsector_neg": "lateralAgenticConfront", "relation": "echange_contralateral_abs_X_abs_Y"},
    {"pair_id": "L4", "block": "Bloc B (latéral contralatéral)", "subsector_pos": "lateralSecondaryAccomm", "subsector_neg": "lateralActiveContest", "relation": "echange_contralateral_abs_X_abs_Y"},
]

PROTOTYPE_DISPLAY_FR: dict[str, str] = {
    "pointDeVeille": "Point de Veille",
    "surprise": "Surprise",
    "anticipation": "Anticipation",
    "emoi": "Émoi",
    "reserve": "Réserve",
    "recul": "Recul",
    "saisissement": "Saisissement",
    "suspension": "Suspension",
    "joie": "Joie",
    "tristesse": "Tristesse",
    "peur": "Peur",
    "courage": "Courage",
    "desir": "Désir",
    "degout": "Dégoût",
    "colere": "Colère",
    "calme": "Calme",
}

ROLLS_NOTATION: dict[str, dict[str, str]] = {
    "rewPlus": {
        "symbol": "Rew+",
        "stimulus_notation": "S+",
        "description_fr": "Ajout / présentation d'une récompense (Désir (+1, +1, 2))",
    },
    "rewMinus": {
        "symbol": "Rew−",
        "stimulus_notation": "¬S+",
        "description_fr": "Retrait / omission d'une récompense (Colère (-1, +1, 2))",
    },
    "punPlus": {
        "symbol": "Pun+",
        "stimulus_notation": "S−",
        "description_fr": "Ajout / présentation d'une punition (Dégoût (-1, -1, 2))",
    },
    "punMinus": {
        "symbol": "Pun−",
        "stimulus_notation": "¬S−",
        "description_fr": "Retrait / omission d'une punition — distinct du R− skinnerien (Calme (+1, -1, 2))",
    },
}


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _extract_inductive_block(text: str, type_name: str) -> list[tuple[str, str]]:
    pattern = re.compile(
        rf"inductive\s+{re.escape(type_name)}(?:\s*:\s*Type)?\s+where\s*\n(.*?)\n\s*deriving\b",
        re.DOTALL,
    )
    m = pattern.search(text)
    if not m:
        raise ValueError(f"Bloc inductive {type_name} introuvable dans le noyau Lean 4.")
    items: list[tuple[str, str]] = []
    for raw_line in m.group(1).splitlines():
        line = raw_line.strip()
        if not line.startswith("|"):
            continue
        m_item = re.match(r"^\|\s*([A-Za-z0-9_]+)(?:\s*:\s*[A-Za-z0-9_]+)?(?:\s*--\s*(.*))?$", line)
        if m_item:
            items.append((m_item.group(1), (m_item.group(2) or "").strip()))
    return items


def _extract_match_points(text: str, fn_name: str) -> dict[str, list[int]]:
    pattern = re.compile(
        rf"def\s+{re.escape(fn_name)}\s*:[^\n]*\n(.*?)(?:\n\n|\n/-!|\n/--|\ntheorem\b|\ndef\b)",
        re.DOTALL,
    )
    m = pattern.search(text)
    if not m:
        raise ValueError(f"Fonction {fn_name} introuvable dans le noyau Lean 4.")
    pts: dict[str, list[int]] = {}
    for line in m.group(1).splitlines():
        mm = re.match(r"^\s*\|\s*\.([A-Za-z0-9_]+)\s*=>\s*⟨\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(\d+)\s*⟩", line)
        if mm:
            pts[mm.group(1)] = [int(mm.group(2)), int(mm.group(3)), int(mm.group(4))]
    return pts


def _extract_match_symbols(text: str, fn_name: str) -> dict[str, str]:
    pattern = re.compile(
        rf"def\s+{re.escape(fn_name)}\s*:[^\n]*\n(.*?)(?:\n\n|\n/-!|\n/--|\ntheorem\b|\ndef\b)",
        re.DOTALL,
    )
    m = pattern.search(text)
    if not m:
        raise ValueError(f"Fonction {fn_name} introuvable dans le noyau Lean 4.")
    mapping: dict[str, str] = {}
    for line in m.group(1).splitlines():
        mm = re.match(r"^\s*\|\s*\.([A-Za-z0-9_]+)\s*=>\s*(?:PrimaryCrownPrototype\.)?\.?([A-Za-z0-9_.]+)", line)
        if mm:
            mapping[mm.group(1)] = mm.group(2)
    return mapping


def classify_subsector_py(x: float | int, y: float | int) -> str:
    """Miroir exact de `Cartograffect.AffectiveTaxonomy.classifySubsector`."""
    if x == 0 and y == 0:
        return "centralOperator"
    if x == 0 and y > 0:
        return "axialControlPos"
    if x == 0 and y < 0:
        return "axialControlNeg"
    if x > 0 and y == 0:
        return "axialExpectationPos"
    if x < 0 and y == 0:
        return "axialExpectationNeg"
    if x == y and x > 0:
        return "diagonalSynergyPos"
    if x == y and x < 0:
        return "diagonalSynergyNeg"
    if x == -y and x < 0:
        return "diagonalAgenticConfront"
    if x == -y and x > 0:
        return "diagonalAccommodation"
    if y > abs(x) and x > 0:
        return "lateralApproachSynergy"
    if y > abs(x) and x < 0:
        return "lateralAgenticConfront"
    if -y > abs(x) and x > 0:
        return "lateralSecondaryAccomm"
    if -y > abs(x) and x < 0:
        return "lateralAversiveDistress"
    if x > abs(y) and y > 0:
        return "lateralEpistemicMastery"
    if x > abs(y) and y < 0:
        return "lateralReceptiveAccomm"
    if -x > abs(y) and y > 0:
        return "lateralActiveContest"
    return "lateralEpistemicClosure"


def antagonist_point_py(x: float | int, y: float | int, z: int | None = None) -> tuple[float | int, ...]:
    """Miroir exact de `Cartograffect.AffectiveMatrix.antagonistPoint`."""
    if x == 0 or y == 0 or abs(x) == abs(y):
        res = (-x, -y)
    elif (x > 0 and y < 0) or (x < 0 and y > 0):
        res = (y, x)
    else:
        res = (-y, -x)
    return (*res, z) if z is not None else res


def hedonic_polarity_py(x: float | int, y: float | int) -> str:
    """Miroir exact de `Cartograffect.AffectiveMatrix.computeHedonicPolarity`."""
    if x > 0:
        return "positive"
    if x < 0:
        return "negative"
    if y > 0:
        return "positive"
    if y < 0:
        return "negative"
    return "neutral"


def extract_lean_canonical_spec() -> dict[str, Any]:
    """Lit les 4 modules Lean 4 normatifs en lecture seule et vérifie tous les invariants."""
    core_txt = CORE_AFFECT_LEAN.read_text(encoding="utf-8")
    matrix_txt = MATRIX_LEAN.read_text(encoding="utf-8")
    tax_txt = TAXONOMY_LEAN.read_text(encoding="utf-8")
    oper_txt = OPERANT_LEAN.read_text(encoding="utf-8")

    # 1. CentralOperator (CoreAffect.lean)
    central_ops_raw = _extract_inductive_block(core_txt, "CentralOperator")
    central_pts = _extract_match_points(core_txt, "CentralOperator.toPoint")
    expected_central = [
        "pointDeVeille", "surprise", "anticipation", "emoi",
        "reserve", "recul", "saisissement", "suspension",
    ]
    assert [c[0] for c in central_ops_raw] == expected_central, f"CentralOperator mismatch: {central_ops_raw}"
    for idx, op_id in enumerate(expected_central):
        assert central_pts[op_id] == [0, 0, idx], f"Point mismatch for {op_id}: {central_pts.get(op_id)}"

    # Vérifier la formule crownRadius dans CoreAffect.lean
    assert "| 0     => 0" in core_txt and "| 1     => 0" in core_txt and "| d + 2 => 2 * d + 2" in core_txt

    # 2. PrimaryCrownPrototype (AffectiveMatrix.lean)
    proto_raw = _extract_inductive_block(matrix_txt, "PrimaryCrownPrototype")
    proto_pts = _extract_match_points(matrix_txt, "PrimaryCrownPrototype.toPoint")
    expected_protos = ["joie", "tristesse", "peur", "courage", "desir", "degout", "colere", "calme"]
    assert [p[0] for p in proto_raw] == expected_protos, f"PrimaryCrownPrototype mismatch: {proto_raw}"
    for p_id in expected_protos:
        pt = proto_pts[p_id]
        assert pt[2] == 2 and (abs(pt[0]) + abs(pt[1]) == 2), f"Z=2 radius mismatch for {p_id}: {pt}"

    # 3. RollsContingency (OperantFactorization.lean)
    rolls_raw = _extract_inductive_block(oper_txt, "RollsContingency")
    expected_rolls = ["rewPlus", "rewMinus", "punPlus", "punMinus"]
    assert [r[0] for r in rolls_raw] == expected_rolls, f"RollsContingency mismatch: {rolls_raw}"
    rolls_reinforcer = _extract_match_symbols(oper_txt, "RollsContingency.reinforcerClass")
    rolls_operation = _extract_match_symbols(oper_txt, "RollsContingency.operation")
    rolls_outcome = _extract_match_symbols(oper_txt, "RollsContingency.outcome")
    rolls_antagonist = _extract_match_symbols(oper_txt, "RollsContingency.antagonist")
    rolls_to_proto_raw = _extract_match_symbols(oper_txt, "RollsContingency.toPoint")
    rolls_to_proto = {k: v.split(".")[0] for k, v in rolls_to_proto_raw.items()}
    proto_to_rolls = {v: k for k, v in rolls_to_proto.items()}
    assert proto_to_rolls == {
        "desir": "rewPlus",
        "colere": "rewMinus",
        "degout": "punPlus",
        "calme": "punMinus",
    }, f"Bijection Rolls Z=2 inattendue: {proto_to_rolls}"
    assert "if p.z == 2 then" in oper_txt and "none" in oper_txt

    # 4. FunctionalSubsector (AffectiveTaxonomy.lean)
    subsectors_raw = _extract_inductive_block(tax_txt, "FunctionalSubsector")
    subsector_ids = [s[0] for s in subsectors_raw]
    assert len(subsector_ids) == 17, f"Attendu 17 FunctionalSubsector, trouvé {len(subsector_ids)}"
    assert set(subsector_ids) == set(SUBSECTOR_GEOMETRY_SPEC.keys()), "Divergence identifiants FunctionalSubsector"

    sub_to_group = _extract_match_symbols(tax_txt, "FunctionalSubsector.toTaxonomicGroup")
    sub_to_valence = _extract_match_symbols(tax_txt, "FunctionalSubsector.toHedonicPolarity")

    # Vérifications géométriques exactes de chacun des 17 sous-secteurs
    for sid in subsector_ids:
        spec = SUBSECTOR_GEOMETRY_SPEC[sid]
        ux, uy = spec["u_x"], spec["u_y"]
        l1_val = abs(ux) + abs(uy)
        if sid == "centralOperator":
            assert l1_val == 0.0
        else:
            assert abs(l1_val - 1.0) < 1e-12, f"Norme L1 != 1 pour {sid}: {l1_val}"
        # Test à Z=3 (rayon R(3) = 4, où 4 * u_X et 4 * u_Y sont entiers exacts)
        x3, y3 = int(round(4 * ux)), int(round(4 * uy))
        assert classify_subsector_py(x3, y3) == sid, f"classifySubsector mismatch pour {sid}: ({x3},{y3})"
        ax3, ay3 = antagonist_point_py(x3, y3)
        assert classify_subsector_py(ax3, ay3) == spec["conjugate_subsector"], (
            f"Antagoniste mismatch pour {sid}: ({ax3},{ay3}) -> {classify_subsector_py(ax3, ay3)}"
        )
        assert hedonic_polarity_py(x3, y3) == sub_to_valence[sid], f"Valence mismatch pour {sid}"

    # Construire la liste des 11 états canoniques verrouillés sur Z in {0, 1, 2}
    canonical_states_z0_z2: list[dict[str, Any]] = []
    for op_id in ("pointDeVeille", "surprise", "anticipation"):
        pt = central_pts[op_id]
        op_comment = dict(central_ops_raw)[op_id]
        canonical_states_z0_z2.append({
            "id": op_id,
            "lean_type": "CentralOperator",
            "lean_constructor": f"CentralOperator.{op_id}",
            "label_fr": PROTOTYPE_DISPLAY_FR[op_id],
            "point": pt,
            "z": pt[2],
            "geometry_type": "central",
            "subsector_id": "centralOperator",
            "taxonomic_group": "centralOperator",
            "hedonic_polarity": "neutral",
            "antagonist_id": op_id,
            "antagonist_point": pt,
            "p2_axial_instability_negative_charge": False,
            "rolls_contingency": None,
            "lean_comment": op_comment,
        })

    pt_to_proto = {tuple(v): k for k, v in proto_pts.items()}
    for p_id in expected_protos:
        pt = proto_pts[p_id]
        ant_pt = list(antagonist_point_py(pt[0], pt[1], pt[2]))
        ant_id = pt_to_proto[tuple(ant_pt)]
        sub_id = classify_subsector_py(pt[0], pt[1])
        geom = "axial" if (pt[0] == 0 or pt[1] == 0) else "diagonal"
        rolls_id = proto_to_rolls.get(p_id)
        rolls_block = None
        if rolls_id is not None:
            rolls_block = {
                "lean_constructor": f"RollsContingency.{rolls_id}",
                "symbol": ROLLS_NOTATION[rolls_id]["symbol"],
                "stimulus_notation": ROLLS_NOTATION[rolls_id]["stimulus_notation"],
                "reinforcer_class": rolls_reinforcer[rolls_id],
                "operation": rolls_operation[rolls_id],
                "outcome": rolls_outcome[rolls_id],
                "antagonist_contingency": rolls_antagonist[rolls_id],
                "strictly_bounded_to_z2": True,
                "description_fr": ROLLS_NOTATION[rolls_id]["description_fr"],
            }
        canonical_states_z0_z2.append({
            "id": p_id,
            "lean_type": "PrimaryCrownPrototype",
            "lean_constructor": f"PrimaryCrownPrototype.{p_id}",
            "label_fr": PROTOTYPE_DISPLAY_FR[p_id],
            "point": pt,
            "z": 2,
            "geometry_type": geom,
            "subsector_id": sub_id,
            "taxonomic_group": sub_to_group[sub_id],
            "hedonic_polarity": sub_to_valence[sub_id],
            "antagonist_id": ant_id,
            "antagonist_point": ant_pt,
            "p2_axial_instability_negative_charge": p_id in ("peur", "tristesse"),
            "rolls_contingency": rolls_block,
            "lean_comment": dict(proto_raw)[p_id],
        })

    assert len(canonical_states_z0_z2) == 11

    # Les 3 opérateurs centraux de la taxonomie structurée Z in {3, 4, 5}
    central_ops_z3_z5: list[dict[str, Any]] = []
    op_comments_map = dict(central_ops_raw)
    for op_id, z_val in (("emoi", 3), ("reserve", 4), ("recul", 5)):
        pt = central_pts[op_id]
        central_ops_z3_z5.append({
            "id": op_id,
            "lean_constructor": f"CentralOperator.{op_id}",
            "label_fr": PROTOTYPE_DISPLAY_FR[op_id],
            "point": pt,
            "z": z_val,
            "crown_radius": 2 * z_val - 2,
            "subsector_id": "centralOperator",
            "hedonic_polarity": "neutral",
            "descending_suspension_r5": True,
            "lean_comment": op_comments_map[op_id],
        })

    exploratory_z6_z7_ops = [
        {
            "id": op_id,
            "lean_constructor": f"CentralOperator.{op_id}",
            "label_fr": PROTOTYPE_DISPLAY_FR[op_id],
            "point": central_pts[op_id],
            "z": central_pts[op_id][2],
            "status": "exploratory_out_of_normative_scope",
            "lean_comment": op_comments_map[op_id],
        }
        for op_id in ("saisissement", "suspension")
    ]

    # Les 17 FunctionalSubsector avec vecteurs L1 et métadonnées Lean
    subsector_comments = dict(subsectors_raw)
    subsectors_list: list[dict[str, Any]] = []
    for sid in subsector_ids:
        spec = SUBSECTOR_GEOMETRY_SPEC[sid]
        subsectors_list.append({
            "subsector_id": sid,
            "lean_constructor": f"FunctionalSubsector.{sid}",
            "pair_id": spec["pair_id"],
            "block": spec["block"],
            "conjugate_subsector": spec["conjugate_subsector"],
            "taxonomic_group": sub_to_group[sid],
            "hedonic_polarity": sub_to_valence[sid],
            "u_X": spec["u_x"],
            "u_Y": spec["u_y"],
            "l1_norm": spec["l1_norm"],
            "quadrant": spec["quadrant"],
            "ray_description": spec["ray_description"],
            "z2_prototype": spec["z2_prototype"],
            "tableau_1b": {
                "z3_high_A": spec["tableau_1b_z3_high_A"],
                "z3_low_A": spec["tableau_1b_z3_low_A"],
                "z4_high_A": spec["tableau_1b_z4_high_A"],
                "z4_low_A": spec["tableau_1b_z4_low_A"],
                "z5_high_A": spec["tableau_1b_z5_high_A"],
                "z5_low_A": spec["tableau_1b_z5_low_A"],
            },
            "lean_comment": subsector_comments[sid],
        })

    return {
        "schema_version": "1.0.0",
        "cartograffect_version": CART_VERSION,
        "epistemic_note": (
            "Extraction verbatim en lecture seule du noyau normatif Lean 4 v3.0.0. "
            "Z in {0, 1, 2} forme la fondation canonique formelle (11 états) ; "
            "Z in {3, 4, 5} forme la taxonomie structurée testable empiriquement (17 FunctionalSubsector, "
            "8 paires conjuguées + centre fixe). La bijection Rolls (Rew+/Rew-/Pun+/Pun-) est strictement bornée à Z = 2."
        ),
        "source_lean_modules": {
            "Cartograffect/CoreAffect.lean": sha256_file(CORE_AFFECT_LEAN),
            "Cartograffect/AffectiveMatrix.lean": sha256_file(MATRIX_LEAN),
            "Cartograffect/AffectiveTaxonomy.lean": sha256_file(TAXONOMY_LEAN),
            "Cartograffect/OperantFactorization.lean": sha256_file(OPERANT_LEAN),
        },
        "crown_radius_law": {
            "formula": "0 for Z in {0, 1}; 2*Z - 2 for Z >= 2",
            "values": {"0": 0, "1": 0, "2": 2, "3": 4, "4": 6, "5": 8},
        },
        "canonical_z0_z2_states": canonical_states_z0_z2,
        "rolls_bijection_z2_invariant": {
            "strictly_bounded_to_z2": True,
            "diagToContingency_z_ne_2": "none",
            "distinct_from_skinnerian_negative_reinforcement_R_minus": True,
            "mapping": {
                "desir (+1, +1, 2)": "Rew+ (S+, reward delivery)",
                "colere (-1, +1, 2)": "Rew- (not-S+, reward omission)",
                "degout (-1, -1, 2)": "Pun+ (S-, punishment delivery)",
                "calme (+1, -1, 2)": "Pun- (not-S-, punishment omission)",
            },
            "antagonist_symmetry": ["Rew+ <-> Pun+", "Rew- <-> Pun-"],
        },
        "structured_taxonomy_central_operators_z3_z5": central_ops_z3_z5,
        "exploratory_central_operators_z6_z7_out_of_normative_scope": exploratory_z6_z7_ops,
        "conjugate_pairs_8": CONJUGATE_PAIRS_META,
        "functional_subsectors_17": subsectors_list,
    }


# =============================================================================
# 2. TABLE D'ANCRAGE CLINIQUE DES 109 CLASSES DIMA (92 Z+ + 17 RESERVE/DISCARD)
# =============================================================================

# Format par classe :
# (default_z, subsector_id, central_operator_link, subsector_alt_or_split_note,
#  z_minus_value_decision, z_minus_value_rationale, exploratory_z6_z7_tag, anchor_rationale)
CLASS_ANCHOR_SPECS: dict[str, dict[str, Any]] = {
    # -------------------------------------------------------------------------
    # CATÉGORIE I (35 classes : 27 active_z_plus + 3 satellite_only_z_plus + 5 reserve_or_discard_only)
    # -------------------------------------------------------------------------
    "Amuser": {
        "default_z": 3,
        "subsector_id": "axialControlPos",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Réaction hédonique ludique à valence très positive (V=+0.77, A=+0.41, D=+0.04) centrée sur l'axe +Y (Joie/Allégresse Z=3).",
    },
    "Apaiser": {
        "default_z": 3,
        "subsector_id": "diagonalAccommodation",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage recommandé par SOUS-CLASSE : 'ataraxie', 'imperturbable', 'inébranlable' -> "
            "lateralReceptiveAccomm (Z=5, stoïcisme/consentement lucide) ; 'impassible' -> lateralSecondaryAccomm ; "
            "le cœur 'apaiser'/'calmer'/'zen'/'placidité' reste en diagonalAccommodation (Calme -> Apaisement Z=3)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Prototype de l'accommodation apaisée (Calme/Apaisement Z=3, V=+0.42, A=-0.68, D=-0.24) conforme au Verrou 1A-c en Q4.",
    },
    "Apathie": {
        "default_z": 5,
        "subsector_id": "lateralAversiveDistress",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage optionnel : 'prostration'/'avachissement' peuvent basculer vers axialControlNeg "
            "(Abattement Z=5) ; 'spleen'/'vague à l'âme' voisinent la mélancolie (axialControlNeg)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Disposition durable aversive à faible contrôle et activation basse (V=-0.62, A=-0.47, D=-0.21), jalon exact Tableau 1b L1 Z=5 (Apathie).",
    },
    "Attrister": {
        "default_z": 3,
        "subsector_id": "axialControlNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Granularité temporelle par SOUS-CLASSE : 'chagrin'/'peiner' (Z=3), 'affliger'/'affliction' (Z=4), "
            "'désoler'/'désolation'/'inconsolable' (Z=5) le long du même axe -Y (axialControlNeg)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Prototype axial -Y de la Tristesse/Chagrin (V=-0.71, A=-0.25, D=-0.19), conforme au Verrou 1A-a et au Tableau 1b A2 Z=3.",
    },
    "Blesser": {
        "default_z": 3,
        "subsector_id": "lateralActiveContest",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Classe uniquement satellite en Z+ ('prendre ombrage', 'se formaliser', 'se sentir agressé' ; "
            "50 entrées en réserve -Z CausAffect). Si lue comme blessure subie/vulnérabilité passive plutôt que "
            "susceptibilité défensive/vexation active, basculer vers lateralAversiveDistress (Q3)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Les 3 satellites expérientiels ('prendre ombrage', 'se formaliser', 'se sentir agressé', V=-0.71, A=+0.54) expriment une susceptibilité défensive réactive en Q2.",
    },
    "Bon moral": {
        "default_z": 5,
        "subsector_id": "lateralApproachSynergy",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage recommandé par SOUS-CLASSE : 'ivre', 'ivresse', 'enivrement', 'surexcitation' présentent "
            "des valeurs V_harm négatives artefactuelles (gloses EN 'intoxication' / hyper-arousal) à isoler de 'tonus'/'exalter'."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "État de moral élevé et d'élan dispositionnel durable (Z=5, V=+0.12 actif / +0.48 global, A=+0.67, D=+0.03) en Q1 dom. +Y (Verrou 1A-c).",
    },
    "Bon moral Revigorer": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Classe 100 % CausAffect en réserve -Z (11 entrées) : aucune projection directe en Z+.",
    },
    "Combler Bonheur": {
        "default_z": 3,
        "subsector_id": "axialControlPos",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage par SOUS-CLASSE : 'satisfaction'/'contentement' -> lateralEpistemicMastery (Tableau 1b L1 Z=3) ; "
            "'bien-être'/'bonheur' s'étendent en Z=4 et 'épanouissement' en Z=5 sur axialControlPos."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": "z7_transcendental_candidate",
        "anchor_rationale": "Plénitude hédonique de comblement (V=+0.80, A=+0.10, D=0.00) sur l'axe +Y (Verrou 1A-c) ; note documentaire Z=7 pour 'béatitude'/'félicité'.",
    },
    "Combler un désir": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Classe 100 % CausAffect en réserve -Z (11 entrées) : aucune projection directe en Z+.",
    },
    "Décevoir": {
        "default_z": 3,
        "subsector_id": "lateralAversiveDistress",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage encodé dans `subclass_overrides` (MP3b) : "
            "{décevoir, désappointer, désillusionner} -> lateralAversiveDistress (L1, Z=3) ; "
            "{contrarier} -> diagonalAgenticConfront (D2, Q2, Z=3) ; "
            "{frustrer, amertume, insatisfaisant, mécontenter} -> lateralAgenticConfront (L3, Q2, Z=3) ; "
            "{dépiter} -> lateralActiveContest (L4, Q2, Z=3)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Le noyau 'déception'/'désappointement'/'désillusion' (V=-0.71, D=-0.12) correspond à Déception vive en Q3 dom. -Y (Tableau 1b L1 Z=3).",
    },
    "Décevoir Malheur": {
        "default_z": 3,
        "subsector_id": "lateralAversiveDistress",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Extension verticale possible : 'mal-être' et 'sentiment d'abandon' relèvent souvent de Z=4/Z=5 "
            "sur lateralAversiveDistress / axialControlNeg."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Détresse et malheur subi à faible contrôle (V=-0.77, A=+0.17, D=-0.06) en Q3 dom. -Y (Verrou 1A-a).",
    },
    "Désinhiber": {
        "default_z": 3,
        "subsector_id": "lateralEpistemicMastery",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "DÉCOUPAGE IMPÉRATIF actif vs satellites : l'unique entrée Z_PLUS_ACTIVE est 'sans-gêne' "
            "(V=-0.45, A=+0.43, connotation morale/comportementale péjorative, proche de Q2/CaractAffect), "
            "tandis que les 10 satellites ('à l'aise', 'décontracté', 'libéré', 'relax', V_all=+0.49) relèvent "
            "de lateralApproachSynergy / lateralSecondaryAccomm."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Levée d'inhibition comportementale et épistémique orientée vers l'aisance maîtrisée (Q1 dom. +X), sous réserve du split 'sans-gêne'.",
    },
    "Détendre": {
        "default_z": 3,
        "subsector_id": "lateralSecondaryAccomm",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Relâchement post-effort à valence positive et très basse activation (V=+0.70, A=-0.54, D=-0.50), jalon exact Tableau 1b L4 Z=3 (Relâchement/Répit).",
    },
    "Embarrasser": {
        "default_z": 3,
        "subsector_id": "diagonalSynergyNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage recommandé par SOUS-CLASSE : 'embarras'/'gêne'/'penaud'/'déconfit' voisinent lateralAversiveDistress "
            "(voisin Z=3 de la Honte en Z=4) ; 'confusion' -> lateralEpistemicClosure."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Malaise situationnel aversif à faible contrôle (V=-0.59, A=+0.14, D=-0.26), jalon exact Tableau 1b D1 Z=3 (Malaise en Q3).",
    },
    "Energie": {
        "default_z": 5,
        "subsector_id": "lateralEpistemicMastery",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Sous-classes à forte mobilisation instrumentale ('dynamisme', 'énergie', 'entrain', 'exubérance') "
            "voisinent lateralApproachSynergy (Q1 dom. +Y)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Disposition tonique durable (antonyme d'Apathie ; V=+0.61, A=+0.63, D=+0.17) en Q1 dom. +X (élan/vitalité maîtrisée).",
    },
    "Ennuyer": {
        "default_z": 3,
        "subsector_id": "axialControlNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "L'ennui réactionnel immédiat siège en Z=3 (axialControlNeg) ; sa forme chronique ('trouver le temps long') "
            "prolonge vers lateralAversiveDistress / Absence de désir (Z=5)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Défaut d'engagement et hypo-contrôle situationnel (V=-0.53, A=-0.26, D=-0.19) sur l'axe -Y.",
    },
    "Flatter": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Classe 100 % CausAffect/HumAffect en réserve -Z (11 entrées) : aucune projection en Z+.",
    },
    "Humeur bonne": {
        "default_z": 5,
        "subsector_id": "axialControlPos",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Humeur durable hédonique (Z=5, V=+0.80, A=+0.42, D=-0.13) couvrant gaieté, enjouement, allégresse et euphorie sur +Y (Verrou 1A-c).",
    },
    "Humeur mauvaise": {
        "default_z": 5,
        "subsector_id": "lateralAversiveDistress",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "DÉCOUPAGE IMPÉRATIF par SOUS-CLASSE : classe hétérogène mêlant irritabilité active (Q2) et morosité (Q3/-Y). "
            "'bougon', 'grincheux', 'grognon', 'humeur massacrante' (D_orth=+0.24) -> Q2 lateralActiveContest ; "
            "'humeur chagrine' -> axialControlNeg ; 'morose'/'morosité'/'sinistrose' restent en lateralAversiveDistress (Q3)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Humeur dysphorique durable dominée par la morosité et le faible contrôle (V=-0.60, A=+0.17, D=-0.01) en Q3 dom. -Y (Verrou 1A-a).",
    },
    "Humeur songeuse": {
        "default_z": 5,
        "subsector_id": "lateralSecondaryAccomm",
        "central_operator_link": "recul_z5",
        "subsector_alt_or_split_note": (
            "Découpage encodé dans `subclass_overrides` (MP3b) : "
            "{méditatif, pensif, rêveur, songeur} -> lateralSecondaryAccomm (L4, Q4 dom. -Y, Z=5) ; "
            "{mélancolie} -> axialControlNeg (A2, Axe -Y, Z=4 ; Tableau 1b A2)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Humeur méditative et rêveuse apaisée (Z=5, Q4 dom. -Y) liée à Recul (0, 0, 5), avec isolement de 'mélancolie' sur axialControlNeg (Z=4).",
    },
    "Importuner": {
        "default_z": 3,
        "subsector_id": "diagonalAgenticConfront",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage encodé dans `subclass_overrides` (MP3b) : "
            "{énerver, crisper, tendre} -> diagonalAgenticConfront (D2, Q2, Z=3) ; "
            "{fatiguer, lasser} -> axialControlNeg (A2, Axe -Y, Z=3 ; Tableau 1b A2)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Ancrée en Q2 diagonalAgenticConfront sur son versant d'irritation active (énerver/crisper/tendre, Verrou 1A-b), avec split fatiguer/lasser vers axialControlNeg ; 123 entrées CausAffect restent en -Z.",
    },
    "Inhiber": {
        "default_z": 3,
        "subsector_id": "lateralEpistemicClosure",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage optionnel : 'complexe' (V=-0.81) relève plutôt de Z=4 (lateralAversiveDistress, voisin de Honte/Mésestime de soi)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Blocage et fermeture inhibitrice de la révision et de l'action (V=-0.59, A=+0.10, D=+0.06) en Q3 dom. -X.",
    },
    "Inquiéter": {
        "default_z": 3,
        "subsector_id": "lateralEpistemicClosure",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage encodé dans `subclass_overrides` (MP3b) : "
            "{inquiéter, préoccuper, souci, tracasser} -> axialExpectationNeg (A1, Axe -X, Z=3) ; "
            "{angoisser, anxiété, oppresser, trac} -> lateralEpistemicClosure (L2, Q3 dom. -X, Z=3/4)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Fermeture épistémique anxieuse sous forte charge de menace (V=-0.61, A=+0.56, D=-0.07) en Q3 dom. -X.",
    },
    "Inquiéter Effrayer": {
        "default_z": 3,
        "subsector_id": "lateralEpistemicClosure",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage par SOUS-CLASSE : 'frayeur'/'effroi'/'épouvante' -> axialExpectationNeg (Tableau 1b A1) ; "
            "'détresse' -> lateralAversiveDistress (Q3 dom. -Y) ; 'terreur' -> lateralEpistemicClosure (Tableau 1b L2)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": "z6_z7_effraction_candidate",
        "anchor_rationale": "Effroi, terreur et épouvante à haute activation autonome (V=-0.74, A=+0.64, D=-0.05) en Q3 dom. -X (Option 1A).",
    },
    "Jouissance": {
        "default_z": 3,
        "subsector_id": "lateralApproachSynergy",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage optionnel : 'réconfort' (A=-0.54) relève de diagonalAccommodation (Q4, apaisement post-stress)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Plaisir sensoriel et hédonique positif (V=+0.83, A=+0.31, D=-0.09) en Q1 dom. +Y (Verrou 1A-c, Tableau 1b L2 Plaisir).",
    },
    "Mauvais moral": {
        "default_z": 5,
        "subsector_id": "lateralAversiveDistress",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage recommandé par SOUS-CLASSE : 'abattement'/'accablement' (V=-1.00, A=-0.92) -> axialControlNeg "
            "(Tableau 1b A2 Z=5) ; 'consternation'/'anéantissement'/'atterrement' -> lateralEpistemicClosure ; "
            "'désespoir'/'désespérance'/'dépression'/'découragement' restent en lateralAversiveDistress (Tableau 1b L1 Z=5)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": "z6_z7_effraction_candidate",
        "anchor_rationale": "Disposition dépressive et désespoir durable à faible contrôle (V=-0.72, D=-0.13) en Q3 dom. -Y (Verrou 1A-a).",
    },
    "Rassurer": {
        "default_z": 3,
        "subsector_id": "diagonalAccommodation",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage encodé dans `subclass_overrides` (MP3b, Verrou 1A-c) : "
            "{soulager, quiétude} -> diagonalAccommodation (D2, Q4, Z=3/4) ; "
            "{sérénité, tranquilliser, insouciance} -> lateralApproachSynergy (L2, Q1 dom. +Y, A bas, Z=4)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Réassurance et soulagement apaisé (V=+0.58, A=-0.63, D=-0.29) en Q4 diagonalAccommodation, avec split encodé pour sérénité/tranquilliser/insouciance vers Q1.",
    },
    "Réjouir": {
        "default_z": 3,
        "subsector_id": "axialControlPos",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage par SOUS-CLASSE : 'joie mauvaise' (sat: 'schadenfreude', V<0 en NRC) constitue une sous-classe "
            "sociale hostile hors axe +Y ; 'jubiler'/'jubilation' s'étend vers Z=5 sur axialControlPos (Tableau 1b A2)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Jalon canonique de la Joie/Allégresse sur l'axe +Y (V=+0.92, A=+0.68, D=+0.07), conforme au Verrou 1A-c.",
    },
    "Sans surprise": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": "surprise_z1",
        "subsector_alt_or_split_note": "Classe 100 % CausAffect en réserve -Z (1 entrée : 'sans surprise') ; lien documentaire à Surprise Z=1.",
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Aucune entrée Z+ (réserve -Z uniquement) ; signalée avec central_operator_link: surprise_z1 (Verrou 1A-d).",
    },
    "Souffrance": {
        "default_z": 3,
        "subsector_id": "lateralAversiveDistress",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Extension verticale possible : la douleur immédiate siège en Z=3, tandis que 'souffrance morale'/'martyre' "
            "prolongent vers Z=4/Z=5 sur lateralAversiveDistress."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Souffrance aversive subie à faible contrôle (V=-0.71, A=+0.10, D=-0.10) en Q3 dom. -Y (Verrou 1A-a).",
    },
    "Surprendre": {
        "default_z": 3,
        "subsector_id": "centralOperator",
        "central_operator_link": "surprise_z1",
        "subsector_alt_or_split_note": (
            "DÉCOUPAGE IMPÉRATIF par SOUS-CLASSE (Verrou 1A-d) : classe bipolaire centrée sur la rupture de veille Z=1 "
            "se déployant en Z=3 vers : (a) ouverture/étonnement positif ('étonnement', 'ébahissement', 'abasourdissement') -> "
            "axialExpectationPos ; (b) choc/effraction sidérante ('sidération', 'stupéfaction', 'ahurissement', 'pantelant', 'interdit') -> "
            "lateralEpistemicClosure."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": "z6_z7_effraction_candidate",
        "anchor_rationale": "Rupture de prédiction pré-valencée (V_harm=-0.04 quasi nul, A=+0.37) reliée à Surprise (0,0,1) et projetée à l'axe central Z=3 en attente d'orientation.",
    },
    "Surprendre Bonne surprise": {
        "default_z": 3,
        "subsector_id": "axialExpectationPos",
        "central_operator_link": "surprise_z1",
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Orientation post-surprise positive en Z=3 (satellites V=+0.72, A=+0.77) sur +X (Verrou 1A-d).",
    },
    "Surprendre Mauvaise surprise": {
        "default_z": 3,
        "subsector_id": "axialExpectationNeg",
        "central_operator_link": "surprise_z1",
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Orientation post-surprise négative en Z=3 (satellite 'désagréablement surpris', V=-0.67, A=+0.47) sur -X (Verrou 1A-d).",
    },
    "Troubler": {
        "default_z": 3,
        "subsector_id": "centralOperator",
        "central_operator_link": "emoi_z3",
        "subsector_alt_or_split_note": (
            "Découpage encodé dans `subclass_overrides` (MP3b) après exclusion des 4 métatermes "
            "(affect, affectivité, sentiment, émotion -> NON_LEXICAL_DISCARD/META_CLASSIFIER) : "
            "{affoler, désarroi, effarer, hébéter, vertige, égarer, éperdu} -> lateralEpistemicClosure (L2, Q3 dom. -X, Z=3) ; "
            "{confusion, perplexité, troubler, agitation} -> axialExpectationNeg (A1, Axe -X, Z=3) ; "
            "{émouvoir (émoi), saisir, dépayser} -> centralOperator (Z=3)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": "z6_z7_effraction_candidate",
        "anchor_rationale": "Noyau de l'émoi perturbateur recentré sur Émoi (0,0,3) après exclusion des 4 métatermes et encodage complet du découpage Q3/-X/centralOperator.",
    },
    "Z Classifieurs": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Classe métalinguistique classifieur (12 entrées NON_LEXICAL_DISCARD) : aucune projection en Z+.",
    },

    # -------------------------------------------------------------------------
    # CATÉGORIE II (74 classes : 49 active_z_plus + 13 satellite_only_z_plus + 12 reserve_or_discard_only)
    # -------------------------------------------------------------------------
    "Absence de désir": {
        "default_z": 5,
        "subsector_id": "diagonalSynergyNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "DÉCOUPAGE IMPÉRATIF par SOUS-CLASSE : "
            "'détachement' -> lateralSecondaryAccomm (Tableau 1b L4 Z=4) ; "
            "'lassitude'/'fatigue' -> axialControlNeg (Tableau 1b A2) ; "
            "'démotivation'/'démobilisation'/'désabusement'/'désenchantement' -> lateralAversiveDistress (Q3) ; "
            "'rassasiement'/'satiété'/'repu' (V>+0.20) -> satiété apaisée hors Q3 (Q4/Q1) ; "
            "'dégoût'/'indigestion'/'saturation' restent en diagonalSynergyNeg (antonyme exact de Désir)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Pôle antagoniste de Désir (V=-0.40, A=-0.30, D=-0.13) en Q3 diagonalSynergyNeg (Verrou 1A-a).",
    },
    "Admiration": {
        "default_z": 4,
        "subsector_id": "lateralReceptiveAccomm",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage encodé dans `subclass_overrides` (MP3b) : "
            "{admiration} -> lateralReceptiveAccomm (L3, Q4, Z=4) ; "
            "{extase} -> lateralApproachSynergy (L2, Q1, Z=4) ; "
            "{ferveur} -> diagonalSynergyPos (D1, Q1, Z=4)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": "z7_transcendental_candidate",
        "anchor_rationale": "Exemple canonique de l'article (§7.1, Tableau 1b) : ouverture épistémique réceptive (+X dominant, Y<0) antagoniste d'Hostilité (V=+0.66, A=+0.39).",
    },
    "Affection": {
        "default_z": 4,
        "subsector_id": "diagonalSynergyPos",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Sous-classes 'tendresse'/'attendrissement' (D_orth=-0.50) voisinent lateralReceptiveAccomm ou axialControlPos."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Jalon exact du Tableau 1b D1 Z=4 (Affection, V=+0.59, A=-0.04) en Q1 diagonalSynergyPos.",
    },
    "Amitié": {
        "default_z": 4,
        "subsector_id": "diagonalSynergyPos",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage recommandé par SOUS-CLASSE : les termes en '-philie'/'-phile' (américanophile, francophilie, "
            "philanthropie, etc.) relèvent d'attitudes durables (Z=5 lateralEpistemicMastery) ; "
            "'harmonie'/'concorde'/'entente' voisinent lateralApproachSynergy."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Sentiment relationnel affiliatif réciproque (V=+0.63, A=-0.04, D=-0.06) en Q1 diagonalSynergyPos.",
    },
    "Amitié préférence": {
        "default_z": 4,
        "subsector_id": "lateralEpistemicMastery",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Préférence élective fondée sur l'évaluation favorable (+X dominant, V=+0.46, D=+0.11) en Z=4.",
    },
    "Amour": {
        "default_z": 4,
        "subsector_id": "diagonalSynergyPos",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage recommandé par SOUS-CLASSE : 'faible', 'faiblesse', 'fou', 'béguin' tirent artificiellement la moyenne V_harm "
            "vers +0.30 (gloses EN polysémiques) ; le cœur ('amour', 'passion', 'flamme', 'amour-passion', V>+0.70) "
            "couvre Z=4 (Passion) et Z=5 (Amour) dans Tableau 1b D1."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": "z6_z7_transcendence_candidate",
        "anchor_rationale": "Jalon Tableau 1b D1 (Passion Z=4 / Amour Z=5) en Q1 diagonalSynergyPos.",
    },
    "Amour désamour": {
        "default_z": 4,
        "subsector_id": "diagonalSynergyNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": "Le satellite 'se détacher' touche lateralSecondaryAccomm.",
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Antonyme exact d'Amour (V=-0.67, A=-0.57, D=-0.27) en Q3 diagonalSynergyNeg.",
    },
    "Apprécier": {
        "default_z": 4,
        "subsector_id": "lateralEpistemicMastery",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Satellite verbal évaluatif positif (V=+0.77, A=-0.16, D=+0.09) voisin d'Estime en Q1 dom. +X.",
    },
    "Aversion": {
        "default_z": 4,
        "subsector_id": "diagonalSynergyNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "DÉCOUPAGE IMPÉRATIF par SOUS-CLASSE : 'aversion', 'répugnance', 'rejet', 'détestation', 'exécration' "
            "relèvent de diagonalSynergyNeg (Tableau 1b D1 Z=4 Aversion, Verrou 1A-a) ; "
            "'haine', 'hostile', 'hostilité', 'rebelle', 'réfractaire', 'rétif' (D_orth>0) doivent basculer en Q2 "
            "(diagonalAgenticConfront / lateralAgenticConfront)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Jalon exact Tableau 1b D1 Z=4 (Aversion, V=-0.85 en actif sur 'aversion'), conforme au Verrou 1A-a.",
    },
    "Bonne conscience": {
        "default_z": 4,
        "subsector_id": "diagonalAccommodation",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Classe 100 % Z_PLUS_SATELLITE (11 entrées ; déjà exclue de Z_PLUS_ACTIVE en MP1c) à valence positive "
            "et basse activation (V=+0.57, A=-0.65) ; statut axiologique frontalier avec -Z."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Paix morale intérieure ('avoir la conscience en paix', quiétude Z=4) en Q4 diagonalAccommodation.",
    },
    "Colère": {
        "default_z": 3,
        "subsector_id": "diagonalAgenticConfront",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage hiérarchique par SOUS-CLASSE : 'agacement'/'exaspération'/'colère' en Z=3 (diagonalAgenticConfront) ; "
            "'rage'/'fureur'/'courroux' en Z=4 ; 'indignation' -> lateralActiveContest (Z=4) ; "
            "'révolte' -> lateralAgenticConfront (Z=5)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Prototype de l'affrontement agentique en Q2 (V=-0.65, A=+0.67, D=+0.23), conforme au Verrou 1A-b.",
    },
    "Compassion": {
        "default_z": 4,
        "subsector_id": "lateralReceptiveAccomm",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage par SOUS-CLASSE : 'compassion', 'empathie', 'attendrissement', 'sympathie' (V>+0.45) en "
            "lateralReceptiveAccomm ; 'pitié', 'apitoiement', 'commisération' (V<-0.33) penchent vers axialControlNeg."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Ouverture réceptive face à la souffrance d'autrui hors maîtrise directe (V=+0.21, A=-0.29, D=-0.26) en Q4 dom. +X.",
    },
    "Confiance": {
        "default_z": 5,
        "subsector_id": "axialExpectationPos",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Note d'échelle : 'confiance' figure à Z=4 dans Tableau 1b A1 (et Conviction/Lucidité à Z=5) ; "
            "ancrée par défaut en Z=5 comme disposition épistémique générale."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": "z7_transcendental_candidate",
        "anchor_rationale": "Ouverture épistémique positive durable (V=+0.66, A=-0.27, D=+0.12) sur l'axe +X (Tableau 1b A1).",
    },
    "Confiance en soi": {
        "default_z": 4,
        "subsector_id": "lateralEpistemicMastery",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Sentiment réflexif de maîtrise et d'efficacité sur soi (Z=4, satellites V=+0.62, A=+0.33, D=+0.23) en Q1 dom. +X.",
    },
    "Confiance_Crédit": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Classe 100 % CausAffect/ObjAffect en réserve -Z (4 entrées) : aucune projection en Z+.",
    },
    "Confiance_Fiabilité": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Classe 100 % ObjAffect en réserve -Z (6 entrées) : aucune projection en Z+.",
    },
    "Confiance_Sentiment de sécurité": {
        "default_z": 5,
        "subsector_id": "lateralApproachSynergy",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage par SOUS-CLASSE : 'optimisme'/'optimiste' -> lateralEpistemicMastery (Tableau 1b L1 Z=5) ; "
            "'assurance'/'sûr'/'sentiment de sécurité' restent en lateralApproachSynergy (Tableau 1b L2 Z=5, Verrou 1A-c)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Sécurité stable hors contrainte d'incontrôlabilité (V=+0.68, A=-0.04, D=+0.15) en Q1 dom. +Y (Verrou 1A-c).",
    },
    "Crainte": {
        "default_z": 3,
        "subsector_id": "axialExpectationNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage optionnel : 'appréhender'/'appréhension' penche vers lateralEpistemicClosure (Tableau 1b L2 Z=4)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Anticipation anxieuse immédiate (V=-0.55, A=+0.18, D=-0.07) sur l'axe -X (axialExpectationNeg).",
    },
    "Croyance": {
        "default_z": 5,
        "subsector_id": "axialExpectationPos",
        "central_operator_link": None,
        "subsector_alt_or_split_note": "Classe mono-entrée active ('croyance') à très faible charge affective (V=+0.05, A=-0.32).",
        "z_minus_value_decision": "move_to_z_minus_reserve",
        "z_minus_value_rationale": "Terme épistémique cognitif quasi neutre (V=+0.05) sans vécu affectif autonome ; recommandé en réserve -Z.",
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Adhésion épistémique générale (+X) placée en Z=5 sous réserve de bascule vers -Z.",
    },
    "Croyance relig": {
        "default_z": 5,
        "subsector_id": "axialExpectationPos",
        "central_operator_link": None,
        "subsector_alt_or_split_note": "Classe mono-entrée active ('foi') ; forte composante culturelle/religieuse.",
        "z_minus_value_decision": "move_to_z_minus_reserve",
        "z_minus_value_rationale": "Attitude propositionnelle religieuse ('foi') relevant prioritairement du registre axiologique/épistémique -Z.",
        "exploratory_z6_z7_tag": "z7_transcendental_candidate",
        "anchor_rationale": "Adhésion de foi (+X, V=+0.67, A=-0.56, D=+0.15) en Z=5, proposée vers -Z lors de la revue.",
    },
    "Curiosité": {
        "default_z": 3,
        "subsector_id": "axialExpectationPos",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "DÉCOUPAGE IMPÉRATIF par SOUS-CLASSE : 'souci'/'soucieux' (V<-0.51, doublons d'Inquiéter) doivent être "
            "rattachés à axialExpectationNeg ; 'engouement' -> diagonalSynergyPos ; 'curieux'/'curiosité'/'attentif' "
            "restent en axialExpectationPos (Tableau 1b A1 Z=3)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Jalon exact Tableau 1b A1 Z=3 (Curiosité, V=+0.50 sur 'curiosité') sur l'axe +X.",
    },
    "Doute": {
        "default_z": 5,
        "subsector_id": "axialExpectationNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "DÉCOUPAGE IMPÉRATIF par SOUS-CLASSE : 'circonspection'/'circonspect'/'prudent'/'réservé' (V_harm>=+0.10, "
            "suspension réflexive sans dysphorie) relèvent de centralOperator (Réserve Z=4 / Recul Z=5) ; "
            "'doute'/'incertitude'/'scepticisme'/'dubitatif' (V=-0.41 à -0.87) restent en axialExpectationNeg."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Incertitude épistémique durable (V=-0.25, A=-0.07, D=-0.03) sur l'axe -X.",
    },
    "Doute de soi": {
        "default_z": 4,
        "subsector_id": "lateralAversiveDistress",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Auto-évaluation réflexive négative à faible contrôle perçu (satellite 'douter de soi', V=-0.21, D=-0.36) en Q3.",
    },
    "Défiance": {
        "default_z": 5,
        "subsector_id": "axialExpectationNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage par SOUS-CLASSE : 'défiance' (versant combatif) -> lateralActiveContest (Tableau 1b L4 Z=5) ; "
            "'méfiance'/'méfiant' (versant replié) -> axialExpectationNeg (Z=4 Méfiance) ou lateralEpistemicClosure."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Disposition durable de fermeture épistémique et méfiance (V=-0.81, A=0.00, D=-0.07) sur -X.",
    },
    "Défiance_Discrédit": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Classe 100 % CausAffect/ObjAffect en réserve -Z (5 entrées) : aucune projection en Z+.",
    },
    "Défiance_Non fiabilité": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Classe 100 % ObjAffect/HumAffect en réserve -Z (2 entrées) : aucune projection en Z+.",
    },
    "Défiance_Sentiment d'insécurité": {
        "default_z": 5,
        "subsector_id": "lateralEpistemicClosure",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage par SOUS-CLASSE : 'se sentir en insécurité' -> axialExpectationNeg (Tableau 1b A1 Z=5 Insécurité) ; "
            "'pessimisme'/'pessimiste' -> lateralAversiveDistress (Article §8.1 Pessimisme (-2,-6,5)) ; "
            "'suspicion'/'soupçon' -> lateralEpistemicClosure."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Climat durable de vulnérabilité épistémique et insécurité (V=-0.70, A=+0.26, D=-0.04) en Q3 dom. -X.",
    },
    "Déplaire_A": {
        "default_z": 3,
        "subsector_id": "diagonalSynergyNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage optionnel : 'horreur' -> lateralEpistemicClosure (Q3 dom. -X)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Noyau du Dégoût / Révulsion / Écœurement (V=-0.71, A=+0.40, D=-0.02) en Q3 diagonalSynergyNeg (Verrou 1A-a).",
    },
    "Déplaire_B": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Classe 100 % ObjAffect en réserve -Z (38 entrées) : aucune projection en Z+.",
    },
    "Déplorer": {
        "default_z": 4,
        "subsector_id": "axialControlNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Regret réflexif d'un événement accompli hors prise instrumentale (V=-0.59, A=+0.22, D=-0.12) sur -Y.",
    },
    "Désespérer de": {
        "default_z": 5,
        "subsector_id": "lateralAversiveDistress",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Jalon exact Tableau 1b L1 Z=5 (Désespoir, 7 satellites verbaux V=-0.77, D=-0.17) en Q3 dom. -Y (Verrou 1A-a).",
    },
    "Désintérêt": {
        "default_z": 5,
        "subsector_id": "diagonalSynergyNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "DÉCOUPAGE IMPÉRATIF par SOUS-CLASSE : 'insouciance'/'insouciant'/'insoucieux' (V=+0.51, doublons Rassurer) -> "
            "Q4 lateralSecondaryAccomm ; 'impassibilité'/'impassible' -> lateralSecondaryAccomm ; "
            "'indifférence'/'insensibilité' -> lateralAversiveDistress / diagonalSynergyNeg."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Désinvestissement durable conforme à l'article §8.1 (Désintérêt (-4,-4,5)) et au Verrou 1A-a (Q3).",
    },
    "Désir": {
        "default_z": 3,
        "subsector_id": "diagonalSynergyPos",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage recommandé par SOUS-CLASSE : le noyau actif inclut des états de manque/excès ('avide', 'avidité', "
            "'compulsion', 'convoitise', 'faim', 'fureur', V<0) qui abaissent V_harm à +0.08 alors que 'désir'/'aspiration'/"
            "'motivation' sont franchement positifs (V>+0.40)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Déploiement réactif en Z=3 du prototype canonique Désir (Q1 diagonalSynergyPos, A=+0.47, D=+0.08).",
    },
    "Désir impatience": {
        "default_z": 3,
        "subsector_id": "diagonalSynergyPos",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Tension frustrative d'attente (V_harm=-0.39, A=+0.52) : frontière entre Désir bloqué (diagonalSynergyPos) "
            "et frustration active en Q2 (diagonalAgenticConfront / lateralAgenticConfront)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Rattachée à Désir (Q1) par héritage taxonomique DIMA, avec alerte de glissement Q2 (impatience/frustration).",
    },
    "Espoir": {
        "default_z": 5,
        "subsector_id": "lateralEpistemicMastery",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Jalon exact Tableau 1b L1 Z=5 (Espoir, V=+0.62, A=+0.11, D=+0.06) en Q1 dom. +X.",
    },
    "Estime": {
        "default_z": 4,
        "subsector_id": "lateralEpistemicMastery",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Jalon exact Tableau 1b L1 Z=4 (Estime, V=+0.33, A=-0.24, D=+0.13) en Q1 dom. +X.",
    },
    "Estime respect": {
        "default_z": 4,
        "subsector_id": "lateralReceptiveAccomm",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage optionnel : 'respect'/'respectueux' égalitaire voisine lateralEpistemicMastery, tandis que "
            "'vénération' et 'crainte révérentielle' relèvent pleinement de la déférence réceptive (Q4 dom. +X). "
            "Arbitrage frontière -Z à confirmer."
        ),
        "z_minus_value_decision": "keep_z_plus",
        "z_minus_value_rationale": "Forte valence positive (+0.65) et présence affective claire ('crainte révérentielle', 'vénération') ancrées en Q4.",
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Déférence admirative et respectueuse envers autrui (V=+0.65, A=-0.18, D=+0.08) en Q4 dom. +X.",
    },
    "Goût": {
        "default_z": 4,
        "subsector_id": "diagonalSynergyPos",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Outlier à isoler : 'jaloux' (V=-0.65, emploi 'jaloux de ses prérogatives') est à écarter de cette classe positive."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Inclination évaluative durable envers un objet (antonyme d'Aversion ; 'goût' V=+0.93) en Q1 diagonalSynergyPos.",
    },
    "Gratitude": {
        "default_z": 4,
        "subsector_id": "lateralReceptiveAccomm",
        "central_operator_link": None,
        "subsector_alt_or_split_note": "Arbitrage frontière -Z : sentiment relationnel prosocial conservé en Z=4 par défaut.",
        "z_minus_value_decision": "keep_z_plus",
        "z_minus_value_rationale": "Sentiment relationnel canonique à très forte valence affective (V=+0.82, A=-0.18, D=-0.14), pleinement cohérent avec Q4 dom. +X.",
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Reconnaissance vécue d'un bienfait reçu sans contrôle instrumental direct (Q4 dom. +X).",
    },
    "Haine de qq": {
        "default_z": 4,
        "subsector_id": "diagonalAgenticConfront",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage par SOUS-CLASSE : 'aversion' chevauche Aversion (Q3 diagonalSynergyNeg) ; 'haine' est également "
            "repérée en Z=5 dans Tableau 1b D2."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Jalon Tableau 1b D2 (Haine, V=-0.77, A=+0.40, D=+0.12) en Q2 diagonalAgenticConfront (Verrou 1A-b).",
    },
    "Honte": {
        "default_z": 4,
        "subsector_id": "lateralAversiveDistress",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Jalon exact Tableau 1b L1 Z=4 et Article §7.3 (-2, -4, 4) : V=-0.88, A=+0.26, D=-0.25 en Q3 dom. -Y (Verrou 1A-a).",
    },
    "Honte de soi": {
        "default_z": 4,
        "subsector_id": "lateralAversiveDistress",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Satellites réflexifs de honte envers soi (V=-0.80, A=+0.15, D=-0.14) en Q3 dom. -Y (Verrou 1A-a).",
    },
    "Incrédulité": {
        "default_z": 5,
        "subsector_id": "axialExpectationNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": "Classe épistémique (2 entrées actives : 'incrédule', 'incrédulité') candidate à la réserve -Z.",
        "z_minus_value_decision": "move_to_z_minus_reserve",
        "z_minus_value_rationale": "Posture épistémique de non-adhésion cognitive ('incrédule', 'incrédulité') symétrique de Croyance -> -Z.",
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Fermeture/scepticisme épistémique pur (V=-0.42, D=-0.24) sur -X si maintenue en Z+.",
    },
    "Incrédulité relig": {
        "default_z": 5,
        "subsector_id": "axialExpectationNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": "Classe épistémique religieuse (2 entrées actives : 'incroyance', 'incroyant') candidate à la réserve -Z.",
        "z_minus_value_decision": "move_to_z_minus_reserve",
        "z_minus_value_rationale": "Positionnement doctrinal/épistémique ('incroyance', 'incroyant') symétrique de Croyance relig -> -Z.",
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Non-adhésion religieuse sur -X (V=-0.57, A=-0.09) si maintenue en Z+.",
    },
    "Inimitié": {
        "default_z": 4,
        "subsector_id": "lateralAgenticConfront",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage recommandé par SOUS-CLASSE : les attitudes idéologiques/discriminatoires durables ('antisémitisme', "
            "'racisme', 'xénophobie', 'homophobie', 'misanthropie', '-phobe') relèvent de Z=5 ou de la réserve -Z, "
            "tandis que 'hostilité'/'inimitié'/'fâcherie'/'discorde' restent en Z=4 lateralAgenticConfront (Tableau 1b L3)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Jalon exact Tableau 1b L3 Z=4 (Hostilité, V=-0.73, A=+0.37, D=+0.28) en Q2 dom. +Y (Verrou 1A-b).",
    },
    "Intéresser_A": {
        "default_z": 3,
        "subsector_id": "diagonalSynergyPos",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "DÉCOUPAGE IMPÉRATIF : 'préoccupation' (V=-0.25, D=-0.13) est un outlier aversif à rattacher à Inquiéter / "
            "axialExpectationNeg ; 'intérêt' voisine Curiosité (axialExpectationPos) ; 'enthousiasme'/'passion' "
            "sont exactement en diagonalSynergyPos (Tableau 1b D1)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Jalon exact Tableau 1b D1 Z=3 (Enthousiasme, V=+0.58, A=+0.47, D=+0.07) en Q1 diagonalSynergyPos.",
    },
    "Intéresser_B": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Classe 100 % ObjAffect en réserve -Z (23 entrées) : aucune projection en Z+.",
    },
    "Irrespect": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": None,
        "subsector_alt_or_split_note": "8/8 entrées ComportAffect en réserve -Z (si projetée ultérieurement : affinité Q2 lateralActiveContest).",
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Classe 100 % ComportAffect en réserve -Z (8 entrées) : aucune projection en Z+.",
    },
    "Jalousie envie": {
        "default_z": 4,
        "subsector_id": "lateralActiveContest",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage optionnel : le versant 'envie' impuissante/dépressive (sans revendication active) voisine lateralAversiveDistress (Q3)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Contestation comparative sociale sous menace sur l'estime et mobilisation (V=-0.61, A=+0.46, D=+0.02) en Q2 dom. -X.",
    },
    "Jalousie sexuelle": {
        "default_z": 4,
        "subsector_id": "lateralActiveContest",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Menace relationnelle d'exclusivité avec maintien actif d'action/surveillance (V=-0.58, A=+0.47, D=+0.04) en Q2 dom. -X.",
    },
    "Laisser indifférent_A": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Classe 100 % ObjAffect en réserve -Z (1 entrée) : aucune projection en Z+.",
    },
    "Laisser indifférent_B": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Classe 100 % ObjAffect en réserve -Z (16 entrées) : aucune projection en Z+.",
    },
    "Manque de confiance en soi": {
        "default_z": 4,
        "subsector_id": "lateralAversiveDistress",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Antonyme exact de Confiance en soi (satellites V=-0.81, A=+0.29, D=-0.01) en Q3 dom. -Y.",
    },
    "Mauvaise conscience": {
        "default_z": 4,
        "subsector_id": "lateralAversiveDistress",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Arbitrage frontière -Z : les sous-classes religieuses/expiatoires ('résipiscence', 'pénitence', 'repentance') "
            "sont les plus proches de la norme morale (-Z), tandis que 'remords'/'regret'/'contrition' relèvent "
            "pleinement de la culpabilité réflexive en Z=4."
        ),
        "z_minus_value_decision": "keep_z_plus",
        "z_minus_value_rationale": "La culpabilité/remords (V=-0.35, D=-0.16) est un sentiment réflexif clinique majeur centré sur soi en Z=4.",
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Culpabilité réflexive et regret irréversible d'une faute commise (Q3 dom. -Y).",
    },
    "Mauvaise conscience scrupule": {
        "default_z": 4,
        "subsector_id": "lateralEpistemicClosure",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": "keep_z_plus",
        "z_minus_value_rationale": "Le scrupule (V=-0.33, A=-0.57, D=-0.20) traduit une hésitation anxieuse réflexive pertinente pour la clinique (TOC/scrupulosité).",
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Fermeture épistémique anxieuse centrée sur la crainte de faute morale en Z=4 (Q3 dom. -X).",
    },
    "Mépris": {
        "default_z": 4,
        "subsector_id": "lateralActiveContest",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Jalon exact Tableau 1b L4 Z=4 (Mépris froid, V=-0.70, A=+0.04, D=-0.02) en Q2 dom. -X.",
    },
    "Mésestime": {
        "default_z": 4,
        "subsector_id": "lateralActiveContest",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Classe à D_orth=-0.13 : si lue comme dépréciation froide sans affrontement actif, basculer vers "
            "lateralEpistemicClosure (Y < 0) ; maintenue en lateralActiveContest par symétrie avec Mépris/Irrespect."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Évaluation dépréciative dirigée vers autrui en Z=4 (proche de Mépris froid, Tableau 1b L4).",
    },
    "Mésestime de soi": {
        "default_z": 4,
        "subsector_id": "lateralAversiveDistress",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Dévalorisation réflexive de soi (satellite 'se sous-estimer', V=-0.17, D=-0.43) en Q3 dom. -Y.",
    },
    "Nostalgie": {
        "default_z": 4,
        "subsector_id": "axialControlNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Tonalité douce-amère : le regret du passé révolu ('mal du pays', V=-0.28, D=-0.27) siège en axialControlNeg "
            "(impuissance sur le révolu), avec un versant apaisé voisinant lateralSecondaryAccomm."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Sentiment réflexif de manque face à un passé hors de portée instrumentale (-Y).",
    },
    "Orgueil": {
        "default_z": 4,
        "subsector_id": "lateralEpistemicMastery",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage par SOUS-CLASSE : 'fierté', 'amour-propre', 'contentement de soi' (V>+0.45, D=+0.34) -> "
            "jalon exact Tableau 1b L1 Z=4 (Fierté) ; 'autosatisfaction'/'autosatisfait' (glose EN 'smug', V=-0.60) et "
            "'vanité' reflètent un jugement moral d'autrui (candidats CaractAffect/-Z)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Jalon exact Tableau 1b L1 Z=4 (Fierté, V=+0.27 actif / +0.46 sur 'fierté', D=+0.25) en Q1 dom. +X.",
    },
    "Orgueil impudence": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Classe 100 % ComportAffect en réserve -Z (8 entrées) : aucune projection en Z+.",
    },
    "Orgueil surestimation de soi": {
        "default_z": 4,
        "subsector_id": "lateralEpistemicMastery",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Classe 100 % Z_PLUS_SATELLITE (13 locutions familières ; 12 CaractAffect déjà en -Z). "
            "Le V_harm=-0.57 mesuré sur 'overconfidence'/'arrogant' reflète la réprobation sociale de l'observateur, "
            "non une détresse vécue ; forte affinité avec -Z si épurée des locutions familières."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Hypertrophie réflexive du sentiment de maîtrise (D_orth=+0.46) rattachée à Orgueil en Q1 dom. +X.",
    },
    "Peur": {
        "default_z": 3,
        "subsector_id": "axialExpectationNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Déploiement réactif en Z=3 du prototype axial Peur (V=-0.64, A=+0.48, D=-0.08) sur -X.",
    },
    "Peur panique": {
        "default_z": 3,
        "subsector_id": "lateralEpistemicClosure",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": "z6_z7_effraction_candidate",
        "anchor_rationale": "Effraction anxieuse aiguë à faible contrôle (V=-0.88, A=+0.88) en Q3 dom. -X (Verrou 1A-a).",
    },
    "Peur phobie": {
        "default_z": 5,
        "subsector_id": "lateralEpistemicClosure",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Ancrée en Z=5 comme disposition phobique durable (agoraphobie, claustrophobie, zoophobie) ; "
            "peut se lire en Z=4 sur une phobie centrée sur un objet relationnel spécifique."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Fermeture épistémique durable et évitement à faible contrôle (V=-0.80, A=+0.16, D=-0.11) en Q3 dom. -X (Verrou 1A-a).",
    },
    "Plaire_A": {
        "default_z": 3,
        "subsector_id": "diagonalSynergyPos",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Jalon exact Tableau 1b D1 Z=3 (Attrait, V=+0.64, A=+0.47, D=+0.01) en Q1 diagonalSynergyPos.",
    },
    "Plaire_B": {
        "default_z": 3,
        "subsector_id": "lateralReceptiveAccomm",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Classe 100 % Z_PLUS_SATELLITE (2 entrées : 'subjugation', 'être sous le charme') ; "
            "la glose EN 'subjugation' (V=-0.44) tire artificiellement vers le négatif alors que le sens français est "
            "l'enchantement réceptif (si lu comme attirance active -> diagonalSynergyPos)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Fascination réceptive subie face à un charme (+X réceptif, contrôle passif -Y) en Q4 dom. +X.",
    },
    "Pudeur": {
        "default_z": 4,
        "subsector_id": "lateralReceptiveAccomm",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Arbitrage clinique MP3b : norme/vertu morale de retenue ('modesty') basculée vers la réserve axiologique -Z."
        ),
        "z_minus_value_decision": "move_to_z_minus_reserve",
        "z_minus_value_rationale": "Arbitrage clinique MP3b : norme/vertu morale de retenue basculée vers la réserve axiologique -Z (avec Croyance/Incrédulité).",
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Retenue et consentement mesuré face au regard d'autrui en Q4 dom. +X (maintenue en Z+ jusqu'à la projection MP4 ou réaffectée en -Z).",
    },
    "Regretter qq": {
        "default_z": 4,
        "subsector_id": "axialControlNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Deuil et regret relationnel d'une personne absente (satellites V=-0.41, D=-0.12) sur l'axe -Y.",
    },
    "Regretter qqc ou qq": {
        "default_z": 4,
        "subsector_id": "axialControlNeg",
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Regret réflexif et pleurs sur une perte (satellites 'pleurer', 'regretter', V=-0.72, D=-0.19) sur -Y.",
    },
    "Ressentiment": {
        "default_z": 4,
        "subsector_id": "lateralAgenticConfront",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Note d'échelle : 'rancœur' figure aussi en Tableau 1b D2 Z=5 (diagonalAgenticConfront)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Jalon exact Tableau 1b L3 Z=4 (Ressentiment, V=-0.71, A=+0.41, D=+0.10) en Q2 dom. +Y (Verrou 1A-b).",
    },
    "Résignation": {
        "default_z": 5,
        "subsector_id": "lateralAversiveDistress",
        "central_operator_link": None,
        "subsector_alt_or_split_note": (
            "Découpage encodé dans `subclass_overrides` (MP3b, Verrou 1A-c) : "
            "{acceptation} -> lateralReceptiveAccomm (L3, Q4, Z=4) ; "
            "{résignation, fatalisme} -> lateralAversiveDistress (L1, Q3, Z=4/5)."
        ),
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Disposition durable de renoncement face à une limite objective d'action (Q3 par défaut, avec split encodé d'acceptation vers Q4).",
    },
    "Sentiment": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Classe 100 % CaractAffect en réserve -Z (3 entrées) : aucune projection en Z+.",
    },
    "Sentiment classifieur": {
        "default_z": None,
        "subsector_id": None,
        "central_operator_link": None,
        "subsector_alt_or_split_note": None,
        "z_minus_value_decision": None,
        "z_minus_value_rationale": None,
        "exploratory_z6_z7_tag": None,
        "anchor_rationale": "Classe métalinguistique classifieur (3 entrées NON_LEXICAL_DISCARD) : aucune projection en Z+.",
    },
}


# =============================================================================
# 2b. RÈGLES STRUCTURÉES DE DÉCOUPAGE PAR SOUS-CLASSE (MP3b — 8 CLASSES / 52 RÈGLES)
# =============================================================================

SUBCLASS_OVERRIDES_SPECS: dict[str, list[dict[str, Any]]] = {
    "Décevoir": [
        {"sous_classe": "décevoir", "subsector_id": "lateralAversiveDistress", "default_z": 3, "z_alt": None, "rationale": "Perte subie / attente déçue (L1, Q3, Tableau 1b Déception vive Z=3)."},
        {"sous_classe": "désappointer", "subsector_id": "lateralAversiveDistress", "default_z": 3, "z_alt": None, "rationale": "Désappointement subi à faible contrôle (L1, Q3)."},
        {"sous_classe": "désillusionner", "subsector_id": "lateralAversiveDistress", "default_z": 3, "z_alt": None, "rationale": "Désillusion subie (L1, Q3)."},
        {"sous_classe": "contrarier", "subsector_id": "diagonalAgenticConfront", "default_z": 3, "z_alt": None, "rationale": "Contrariété / blocage contrariant agentique (D2, Q2, Tableau 1b)."},
        {"sous_classe": "frustrer", "subsector_id": "lateralAgenticConfront", "default_z": 3, "z_alt": None, "rationale": "Frustration avec maintien d'agentivité (L3, Q2, Tableau 1b Frustration Z=3)."},
        {"sous_classe": "amertume", "subsector_id": "lateralAgenticConfront", "default_z": 3, "z_alt": None, "rationale": "Amertume / rancœur agentique (L3, Q2, Tableau 1b Amertume)."},
        {"sous_classe": "insatisfaisant", "subsector_id": "lateralAgenticConfront", "default_z": 3, "z_alt": None, "rationale": "Insatisfaction frustrative active (L3, Q2)."},
        {"sous_classe": "mécontenter", "subsector_id": "lateralAgenticConfront", "default_z": 3, "z_alt": None, "rationale": "Mécontentement actif (L3, Q2)."},
        {"sous_classe": "dépiter", "subsector_id": "lateralActiveContest", "default_z": 3, "z_alt": None, "rationale": "Dépit / contestation dépitée (L4, Q2, Tableau 1b Dépit Z=3)."},
    ],
    "Résignation": [
        {"sous_classe": "acceptation", "subsector_id": "lateralReceptiveAccomm", "default_z": 4, "z_alt": None, "rationale": "Accommodation réceptive acceptée face à une limite objective (L3, Q4, Verrou 1A-c)."},
        {"sous_classe": "résignation", "subsector_id": "lateralAversiveDistress", "default_z": 4, "z_alt": 5, "rationale": "Résignation subie à faible contrôle (L1, Q3, Tableau 1b Z=4/5)."},
        {"sous_classe": "fatalisme", "subsector_id": "lateralAversiveDistress", "default_z": 5, "z_alt": 4, "rationale": "Disposition fataliste durable à faible contrôle (L1, Q3, Z=5/4)."},
    ],
    "Rassurer": [
        {"sous_classe": "sérénité", "subsector_id": "lateralApproachSynergy", "default_z": 4, "z_alt": None, "rationale": "Sérénité stable à bas arousal hors contrainte d'incontrôlabilité (L2, Q1 dom. +Y, Z=4, Verrou 1A-c)."},
        {"sous_classe": "tranquilliser", "subsector_id": "lateralApproachSynergy", "default_z": 4, "z_alt": None, "rationale": "Tranquillité sûre à bas arousal (L2, Q1 dom. +Y, Z=4, Verrou 1A-c)."},
        {"sous_classe": "insouciance", "subsector_id": "lateralApproachSynergy", "default_z": 4, "z_alt": None, "rationale": "Insouciance apaisée hors menace active (L2, Q1 dom. +Y, Z=4)."},
        {"sous_classe": "soulager", "subsector_id": "diagonalAccommodation", "default_z": 3, "z_alt": 4, "rationale": "Soulagement post-alerte face à une contrainte levée (D2, Q4, Z=3/4)."},
        {"sous_classe": "quiétude", "subsector_id": "diagonalAccommodation", "default_z": 4, "z_alt": 3, "rationale": "Quiétude apaisée en accommodation secondaire (D2, Q4, Z=4/3)."},
    ],
    "Inquiéter": [
        {"sous_classe": "inquiéter", "subsector_id": "axialExpectationNeg", "default_z": 3, "z_alt": None, "rationale": "Inquiétude situationnelle centrée sur l'attente négative (A1, Axe -X, Tableau 1b Z=3)."},
        {"sous_classe": "préoccuper", "subsector_id": "axialExpectationNeg", "default_z": 3, "z_alt": None, "rationale": "Préoccupation épistémique ciblée sur l'attente (A1, Axe -X, Z=3)."},
        {"sous_classe": "souci", "subsector_id": "axialExpectationNeg", "default_z": 3, "z_alt": None, "rationale": "Souci immédiat sur l'attente négative (A1, Axe -X, Z=3)."},
        {"sous_classe": "tracasser", "subsector_id": "axialExpectationNeg", "default_z": 3, "z_alt": None, "rationale": "Tracas focalisé sur une issue incertaine (A1, Axe -X, Z=3)."},
        {"sous_classe": "anxiété", "subsector_id": "lateralEpistemicClosure", "default_z": 3, "z_alt": 4, "rationale": "Anxiété diffuse à faible contrôle (L2, Q3 dom. -X, Tableau 1b Anxiété Z=3/4)."},
        {"sous_classe": "angoisser", "subsector_id": "lateralEpistemicClosure", "default_z": 4, "z_alt": 3, "rationale": "Angoisse avec fermeture épistémique marquée (L2, Q3 dom. -X, Tableau 1b Angoisse Z=4/3)."},
        {"sous_classe": "oppresser", "subsector_id": "lateralEpistemicClosure", "default_z": 3, "z_alt": 4, "rationale": "Oppression anxieuse somatique/épistémique (L2, Q3 dom. -X, Z=3/4)."},
        {"sous_classe": "trac", "subsector_id": "lateralEpistemicClosure", "default_z": 3, "z_alt": 4, "rationale": "Trac / appréhension anxieuse situationnelle (L2, Q3 dom. -X, Z=3/4)."},
    ],
    "Importuner": [
        {"sous_classe": "énerver", "subsector_id": "diagonalAgenticConfront", "default_z": 3, "z_alt": None, "rationale": "Énervement / nervosité en affrontement agentique actif (D2, Q2, Z=3, Verrou 1A-b)."},
        {"sous_classe": "crisper", "subsector_id": "diagonalAgenticConfront", "default_z": 3, "z_alt": None, "rationale": "Crispation réactive irritée (D2, Q2, Z=3)."},
        {"sous_classe": "tendre", "subsector_id": "diagonalAgenticConfront", "default_z": 3, "z_alt": None, "rationale": "Tension réactive active (D2, Q2, Z=3)."},
        {"sous_classe": "fatiguer", "subsector_id": "axialControlNeg", "default_z": 3, "z_alt": None, "rationale": "Fatigue et baisse de contrôle instrumental sans affrontement Q2 (A2, Axe -Y, Z=3)."},
        {"sous_classe": "lasser", "subsector_id": "axialControlNeg", "default_z": 3, "z_alt": None, "rationale": "Lassitude à bas contrôle (A2, Axe -Y, Z=3, Tableau 1b Lassitude)."},
    ],
    "Troubler": [
        {"sous_classe": "affoler", "subsector_id": "lateralEpistemicClosure", "default_z": 3, "z_alt": None, "rationale": "Affolement à faible contrôle et fermeture épistémique (L2, Q3 dom. -X, Z=3)."},
        {"sous_classe": "désarroi", "subsector_id": "lateralEpistemicClosure", "default_z": 3, "z_alt": None, "rationale": "Désarroi sidérant en Q3 dom. -X (L2, Z=3, hors Y+)."},
        {"sous_classe": "effarer", "subsector_id": "lateralEpistemicClosure", "default_z": 3, "z_alt": None, "rationale": "Effarement à fermeture épistémique (L2, Q3 dom. -X, Z=3)."},
        {"sous_classe": "hébéter", "subsector_id": "lateralEpistemicClosure", "default_z": 3, "z_alt": None, "rationale": "Hébétude sous charge choc (L2, Q3 dom. -X, Z=3)."},
        {"sous_classe": "vertige", "subsector_id": "lateralEpistemicClosure", "default_z": 3, "z_alt": None, "rationale": "Vertige psychique / perte de repères en Q3 dom. -X (L2, Z=3, hors Y+)."},
        {"sous_classe": "égarer", "subsector_id": "lateralEpistemicClosure", "default_z": 3, "z_alt": None, "rationale": "Égarement confusionnel en Q3 dom. -X (L2, Z=3)."},
        {"sous_classe": "éperdu", "subsector_id": "lateralEpistemicClosure", "default_z": 3, "z_alt": None, "rationale": "Éperdu / submersion aversive en Q3 dom. -X (L2, Z=3)."},
        {"sous_classe": "confusion", "subsector_id": "axialExpectationNeg", "default_z": 3, "z_alt": None, "rationale": "Confusion cognitive sur l'attente négative (A1, Axe -X, Z=3)."},
        {"sous_classe": "perplexité", "subsector_id": "axialExpectationNeg", "default_z": 3, "z_alt": None, "rationale": "Perplexité dubitative sur l'axe -X (A1, Z=3)."},
        {"sous_classe": "troubler", "subsector_id": "axialExpectationNeg", "default_z": 3, "z_alt": None, "rationale": "Trouble épistémique négatif sur l'axe -X (A1, Z=3)."},
        {"sous_classe": "agitation", "subsector_id": "axialExpectationNeg", "default_z": 3, "z_alt": None, "rationale": "Agitation inquiète sur l'axe -X (A1, Z=3)."},
        {"sous_classe": "émouvoir", "subsector_id": "centralOperator", "default_z": 3, "z_alt": None, "rationale": "Opérateur central Émoi (0, 0, 3) ; émoi conservé après exclusion des 4 métatermes."},
        {"sous_classe": "saisir", "subsector_id": "centralOperator", "default_z": 3, "z_alt": None, "rationale": "Saisissement suspensif pré-valencé sur l'axe central Z=3."},
        {"sous_classe": "dépayser", "subsector_id": "centralOperator", "default_z": 3, "z_alt": None, "rationale": "Dépaysement / suspens de repères sur l'axe central Z=3."},
    ],
    "Humeur songeuse": [
        {"sous_classe": "mélancolie", "subsector_id": "axialControlNeg", "default_z": 4, "z_alt": None, "rationale": "Mélancolie dysphorique à faible contrôle (A2, Axe -Y, Z=4, Tableau 1b A2)."},
        {"sous_classe": "méditatif", "subsector_id": "lateralSecondaryAccomm", "default_z": 5, "z_alt": None, "rationale": "Disposition méditative sereine en Q4 dom. -Y (L4, Z=5)."},
        {"sous_classe": "pensif", "subsector_id": "lateralSecondaryAccomm", "default_z": 5, "z_alt": None, "rationale": "Disposition pensive apaisée en Q4 dom. -Y (L4, Z=5)."},
        {"sous_classe": "rêveur", "subsector_id": "lateralSecondaryAccomm", "default_z": 5, "z_alt": None, "rationale": "Rêverie détachée en Q4 dom. -Y (L4, Z=5)."},
        {"sous_classe": "songeur", "subsector_id": "lateralSecondaryAccomm", "default_z": 5, "z_alt": None, "rationale": "Humeur songeuse contemplative en Q4 dom. -Y (L4, Z=5)."},
    ],
    "Admiration": [
        {"sous_classe": "admiration", "subsector_id": "lateralReceptiveAccomm", "default_z": 4, "z_alt": None, "rationale": "Admiration réceptive canonique (L3, Q4, Z=4, Article §7.1)."},
        {"sous_classe": "extase", "subsector_id": "lateralApproachSynergy", "default_z": 4, "z_alt": None, "rationale": "Extase / exaltation positive en Q1 dom. +Y (L2, Z=4)."},
        {"sous_classe": "ferveur", "subsector_id": "diagonalSynergyPos", "default_z": 4, "z_alt": None, "rationale": "Ferveur enthousiaste / passionnelle en Q1 diagonale (D1, Z=4)."},
    ],
}


# =============================================================================
# 3. VERROUS NORMES OPTION 1A & MATRICE TABLEAU 1b
# =============================================================================

# Verrou 1A-a : classes explicitement nommées à faible contrôle aversif -> Y <= 0
LOCK_1AA_CLASSES: tuple[str, ...] = (
    "Peur panique",
    "Peur phobie",
    "Désespérer de",
    "Honte",
    "Honte de soi",
    "Souffrance",
    "Attrister",
    "Décevoir Malheur",
    "Aversion",
    "Déplaire_A",
    "Mauvais moral",
    "Apathie",
    "Désintérêt",
    "Absence de désir",
)

# Verrou 1A-b : le quadrant Q2 (-X, +Y) est strictement réservé à l'affrontement agentique
Q2_SUBSECTORS: frozenset[str] = frozenset({
    "diagonalAgenticConfront",
    "lateralAgenticConfront",
    "lateralActiveContest",
})
LOCK_1AB_ALLOWED_Q2_CLASSES: frozenset[str] = frozenset({
    "Colère",
    "Ressentiment",
    "Haine de qq",
    "Inimitié",
    "Importuner",
    "Blesser",
    "Jalousie envie",
    "Jalousie sexuelle",
    "Mépris",
    "Mésestime",
})
LOCK_1AB_ALLOWED_Q2_OVERRIDES: frozenset[tuple[str, str]] = frozenset({
    ("Décevoir", "contrarier"),
    ("Décevoir", "frustrer"),
    ("Décevoir", "amertume"),
    ("Décevoir", "insatisfaisant"),
    ("Décevoir", "mécontenter"),
    ("Décevoir", "dépiter"),
    ("Importuner", "énerver"),
    ("Importuner", "crisper"),
    ("Importuner", "tendre"),
})

# Verrou 1A-c : Q4 (+X, -Y) = accommodation secondaire ; sécurité/bonheur hors contrainte -> Y >= 0
Q4_SUBSECTORS: frozenset[str] = frozenset({
    "diagonalAccommodation",
    "lateralSecondaryAccomm",
    "lateralReceptiveAccomm",
})
LOCK_1AC_SECURITY_HAPPINESS_CLASSES: tuple[str, ...] = (
    "Confiance_Sentiment de sécurité",
    "Combler Bonheur",
    "Bon moral",
    "Humeur bonne",
    "Réjouir",
    "Jouissance",
)

# Verrou 1A-d : classes de surprise -> central_operator_link == "surprise_z1"
LOCK_1AD_SURPRISE_CLASSES: tuple[str, ...] = (
    "Surprendre",
    "Surprendre Bonne surprise",
    "Surprendre Mauvaise surprise",
    "Sans surprise",
)

# Jalons du Tableau 1b de la v3.0.0 attendus dans Z_PLUS_ACTIVE (pour vérification automatisée)
TABLEAU_1B_MILESTONES: list[dict[str, Any]] = [
    # Z=2 fondation canonique (vérifiés dans leurs classes DIMA correspondantes)
    {"jalon": "courage", "z_t1b": 2, "subsector_t1b": "axialExpectationPos", "dima_classe_expected": None},
    {"jalon": "peur", "z_t1b": 2, "subsector_t1b": "axialExpectationNeg", "dima_classe_expected": "Peur"},
    {"jalon": "joie", "z_t1b": 2, "subsector_t1b": "axialControlPos", "dima_classe_expected": "Réjouir"},
    {"jalon": "tristesse", "z_t1b": 2, "subsector_t1b": "axialControlNeg", "dima_classe_expected": "Attrister"},
    {"jalon": "désir", "z_t1b": 2, "subsector_t1b": "diagonalSynergyPos", "dima_classe_expected": "Désir"},
    {"jalon": "dégoût", "z_t1b": 2, "subsector_t1b": "diagonalSynergyNeg", "dima_classe_expected": "Déplaire_A"},
    {"jalon": "colère", "z_t1b": 2, "subsector_t1b": "diagonalAgenticConfront", "dima_classe_expected": "Colère"},
    {"jalon": "calme", "z_t1b": 2, "subsector_t1b": "diagonalAccommodation", "dima_classe_expected": "Apaiser"},
    # Z=3..5 A1
    {"jalon": "curiosité", "z_t1b": 3, "subsector_t1b": "axialExpectationPos", "dima_classe_expected": "Curiosité"},
    {"jalon": "frayeur", "z_t1b": 3, "subsector_t1b": "axialExpectationNeg", "dima_classe_expected": "Inquiéter Effrayer"},
    {"jalon": "inquiétude", "z_t1b": 3, "subsector_t1b": "axialExpectationNeg", "dima_classe_expected": "Inquiéter"},
    {"jalon": "confiance", "z_t1b": 4, "subsector_t1b": "axialExpectationPos", "dima_classe_expected": "Confiance"},
    {"jalon": "effroi", "z_t1b": 4, "subsector_t1b": "axialExpectationNeg", "dima_classe_expected": "Inquiéter Effrayer"},
    {"jalon": "méfiance", "z_t1b": 4, "subsector_t1b": "axialExpectationNeg", "dima_classe_expected": "Défiance"},
    {"jalon": "épouvante", "z_t1b": 5, "subsector_t1b": "axialExpectationNeg", "dima_classe_expected": "Inquiéter Effrayer"},
    # Z=3..5 A2
    {"jalon": "allégresse", "z_t1b": 3, "subsector_t1b": "axialControlPos", "dima_classe_expected": "Humeur bonne"},
    {"jalon": "contentement", "z_t1b": 3, "subsector_t1b": "axialControlPos", "dima_classe_expected": "Combler Bonheur"},
    {"jalon": "chagrin", "z_t1b": 3, "subsector_t1b": "axialControlNeg", "dima_classe_expected": "Attrister"},
    {"jalon": "mélancolie", "z_t1b": 3, "subsector_t1b": "axialControlNeg", "dima_classe_expected": "Humeur songeuse"},
    {"jalon": "euphorie", "z_t1b": 4, "subsector_t1b": "axialControlPos", "dima_classe_expected": "Humeur bonne"},
    {"jalon": "bien-être", "z_t1b": 4, "subsector_t1b": "axialControlPos", "dima_classe_expected": "Combler Bonheur"},
    {"jalon": "affliction", "z_t1b": 4, "subsector_t1b": "axialControlNeg", "dima_classe_expected": "Attrister"},
    {"jalon": "lassitude", "z_t1b": 4, "subsector_t1b": "axialControlNeg", "dima_classe_expected": "Importuner"},
    {"jalon": "jubilation", "z_t1b": 5, "subsector_t1b": "axialControlPos", "dima_classe_expected": "Réjouir"},
    {"jalon": "épanouissement", "z_t1b": 5, "subsector_t1b": "axialControlPos", "dima_classe_expected": "Combler Bonheur"},
    {"jalon": "désolation", "z_t1b": 5, "subsector_t1b": "axialControlNeg", "dima_classe_expected": "Attrister"},
    {"jalon": "abattement", "z_t1b": 5, "subsector_t1b": "axialControlNeg", "dima_classe_expected": "Mauvais moral"},
    # Z=3..5 D1
    {"jalon": "enthousiasme", "z_t1b": 3, "subsector_t1b": "diagonalSynergyPos", "dima_classe_expected": "Intéresser_A"},
    {"jalon": "attrait", "z_t1b": 3, "subsector_t1b": "diagonalSynergyPos", "dima_classe_expected": "Plaire_A"},
    {"jalon": "révulsion", "z_t1b": 3, "subsector_t1b": "diagonalSynergyNeg", "dima_classe_expected": "Déplaire_A"},
    {"jalon": "malaise", "z_t1b": 3, "subsector_t1b": "diagonalSynergyNeg", "dima_classe_expected": "Embarrasser"},
    {"jalon": "passion", "z_t1b": 4, "subsector_t1b": "diagonalSynergyPos", "dima_classe_expected": "Amour"},
    {"jalon": "affection", "z_t1b": 4, "subsector_t1b": "diagonalSynergyPos", "dima_classe_expected": "Affection"},
    {"jalon": "aversion", "z_t1b": 4, "subsector_t1b": "diagonalSynergyNeg", "dima_classe_expected": "Aversion"},
    {"jalon": "écœurement", "z_t1b": 4, "subsector_t1b": "diagonalSynergyNeg", "dima_classe_expected": "Déplaire_A"},
    {"jalon": "amour", "z_t1b": 5, "subsector_t1b": "diagonalSynergyPos", "dima_classe_expected": "Amour"},
    {"jalon": "attachement", "z_t1b": 5, "subsector_t1b": "diagonalSynergyPos", "dima_classe_expected": "Affection"},
    {"jalon": "répulsion", "z_t1b": 5, "subsector_t1b": "diagonalSynergyNeg", "dima_classe_expected": "Déplaire_A"},
    {"jalon": "rejet", "z_t1b": 5, "subsector_t1b": "diagonalSynergyNeg", "dima_classe_expected": "Aversion"},
    # Z=3..5 D2
    {"jalon": "exaspération", "z_t1b": 3, "subsector_t1b": "diagonalAgenticConfront", "dima_classe_expected": "Colère"},
    {"jalon": "agacement", "z_t1b": 3, "subsector_t1b": "diagonalAgenticConfront", "dima_classe_expected": "Colère"},
    {"jalon": "apaisement", "z_t1b": 3, "subsector_t1b": "diagonalAccommodation", "dima_classe_expected": "Apaiser"},
    {"jalon": "rage", "z_t1b": 4, "subsector_t1b": "diagonalAgenticConfront", "dima_classe_expected": "Colère"},
    {"jalon": "contrariété", "z_t1b": 4, "subsector_t1b": "diagonalAgenticConfront", "dima_classe_expected": "Décevoir"},
    {"jalon": "soulagement", "z_t1b": 4, "subsector_t1b": "diagonalAccommodation", "dima_classe_expected": "Rassurer"},
    {"jalon": "quiétude", "z_t1b": 4, "subsector_t1b": "diagonalAccommodation", "dima_classe_expected": "Rassurer"},
    {"jalon": "haine", "z_t1b": 5, "subsector_t1b": "diagonalAgenticConfront", "dima_classe_expected": "Haine de qq"},
    {"jalon": "rancœur", "z_t1b": 5, "subsector_t1b": "diagonalAgenticConfront", "dima_classe_expected": "Ressentiment"},
    # Z=3..5 L1
    {"jalon": "satisfaction", "z_t1b": 3, "subsector_t1b": "lateralEpistemicMastery", "dima_classe_expected": "Combler Bonheur"},
    {"jalon": "déception", "z_t1b": 3, "subsector_t1b": "lateralAversiveDistress", "dima_classe_expected": "Décevoir"},
    {"jalon": "découragement", "z_t1b": 3, "subsector_t1b": "lateralAversiveDistress", "dima_classe_expected": "Mauvais moral"},
    {"jalon": "fierté", "z_t1b": 4, "subsector_t1b": "lateralEpistemicMastery", "dima_classe_expected": "Orgueil"},
    {"jalon": "estime", "z_t1b": 4, "subsector_t1b": "lateralEpistemicMastery", "dima_classe_expected": "Estime"},
    {"jalon": "honte", "z_t1b": 4, "subsector_t1b": "lateralAversiveDistress", "dima_classe_expected": "Honte"},
    {"jalon": "résignation", "z_t1b": 4, "subsector_t1b": "lateralAversiveDistress", "dima_classe_expected": "Résignation"},
    {"jalon": "optimisme", "z_t1b": 5, "subsector_t1b": "lateralEpistemicMastery", "dima_classe_expected": "Confiance_Sentiment de sécurité"},
    {"jalon": "espoir", "z_t1b": 5, "subsector_t1b": "lateralEpistemicMastery", "dima_classe_expected": "Espoir"},
    {"jalon": "désespoir", "z_t1b": 5, "subsector_t1b": "lateralAversiveDistress", "dima_classe_expected": "Mauvais moral"},
    {"jalon": "apathie", "z_t1b": 5, "subsector_t1b": "lateralAversiveDistress", "dima_classe_expected": "Apathie"},
    # Z=3..5 L2
    {"jalon": "assurance", "z_t1b": 3, "subsector_t1b": "lateralApproachSynergy", "dima_classe_expected": "Confiance_Sentiment de sécurité"},
    {"jalon": "plaisir", "z_t1b": 3, "subsector_t1b": "lateralApproachSynergy", "dima_classe_expected": "Jouissance"},
    {"jalon": "anxiété", "z_t1b": 3, "subsector_t1b": "lateralEpistemicClosure", "dima_classe_expected": "Inquiéter"},
    {"jalon": "exaltation", "z_t1b": 4, "subsector_t1b": "lateralApproachSynergy", "dima_classe_expected": "Bon moral"},
    {"jalon": "sérénité", "z_t1b": 4, "subsector_t1b": "lateralApproachSynergy", "dima_classe_expected": "Rassurer"},
    {"jalon": "angoisse", "z_t1b": 4, "subsector_t1b": "lateralEpistemicClosure", "dima_classe_expected": "Inquiéter"},
    {"jalon": "appréhension", "z_t1b": 4, "subsector_t1b": "lateralEpistemicClosure", "dima_classe_expected": "Crainte"},
    {"jalon": "terreur", "z_t1b": 5, "subsector_t1b": "lateralEpistemicClosure", "dima_classe_expected": "Inquiéter Effrayer"},
    # Z=3..5 L3
    {"jalon": "frustration", "z_t1b": 3, "subsector_t1b": "lateralAgenticConfront", "dima_classe_expected": "Décevoir"},
    {"jalon": "acceptation", "z_t1b": 3, "subsector_t1b": "lateralReceptiveAccomm", "dima_classe_expected": "Résignation"},
    {"jalon": "hostilité", "z_t1b": 4, "subsector_t1b": "lateralAgenticConfront", "dima_classe_expected": "Inimitié"},
    {"jalon": "ressentiment", "z_t1b": 4, "subsector_t1b": "lateralAgenticConfront", "dima_classe_expected": "Ressentiment"},
    {"jalon": "révolte", "z_t1b": 5, "subsector_t1b": "lateralAgenticConfront", "dima_classe_expected": "Colère"},
    {"jalon": "amertume", "z_t1b": 5, "subsector_t1b": "lateralAgenticConfront", "dima_classe_expected": "Décevoir"},
    # Z=3..5 L4
    {"jalon": "dépit", "z_t1b": 3, "subsector_t1b": "lateralActiveContest", "dima_classe_expected": "Décevoir"},
    {"jalon": "indignation", "z_t1b": 4, "subsector_t1b": "lateralActiveContest", "dima_classe_expected": "Colère"},
    {"jalon": "mépris", "z_t1b": 4, "subsector_t1b": "lateralActiveContest", "dima_classe_expected": "Mépris"},
    {"jalon": "détachement", "z_t1b": 4, "subsector_t1b": "lateralSecondaryAccomm", "dima_classe_expected": "Absence de désir"},
    {"jalon": "défiance", "z_t1b": 5, "subsector_t1b": "lateralActiveContest", "dima_classe_expected": "Défiance"},
    # Centre
    {"jalon": "émoi", "z_t1b": 3, "subsector_t1b": "centralOperator", "dima_classe_expected": "Troubler"},
]


# =============================================================================
# 4. SÉRIALISEUR YAML 1.2 DÉTERMINISTE (PYTHON PUR, SANS DÉPENDANCE EXTERNE)
# =============================================================================

_YAML_SPECIAL_STRINGS = frozenset({
    "null", "Null", "NULL", "~",
    "true", "True", "TRUE", "false", "False", "FALSE",
    "yes", "Yes", "YES", "no", "No", "NO",
    "on", "On", "ON", "off", "Off", "OFF",
    "y", "Y", "n", "N",
    ".inf", ".Inf", ".INF", "-.inf", "-.Inf", "-.INF", "+.inf", ".nan", ".NaN", ".NAN",
})
_YAML_NUM_RE = re.compile(r"^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$")


def _yaml_format_scalar(val: Any) -> str:
    if val is None:
        return "null"
    if isinstance(val, bool):
        return "true" if val else "false"
    if isinstance(val, int):
        return str(val)
    if isinstance(val, float):
        return f"{val:.6f}"
    s = str(val)
    if s == "" or s != s.strip() or s in _YAML_SPECIAL_STRINGS or _YAML_NUM_RE.match(s):
        return json.dumps(s, ensure_ascii=False)
    # Toujours citer les chaînes contenant des caractères syntaxiques YAML ou non-ASCII simples
    needs_quote = any(ch in s for ch in (":", "#", "{", "}", "[", "]", ",", "&", "*", "?", "|", "-", "<", ">", "=", "!", "%", "@", "`", "'", '"', "\\", "\n", "\r", "\t"))
    if needs_quote or s[0] in ("-", "?", ":", "@", "`", " "):
        return json.dumps(s, ensure_ascii=False)
    return json.dumps(s, ensure_ascii=False)


def dump_yaml(data: Any, indent: int = 0) -> str:
    pad = "  " * indent
    if isinstance(data, dict):
        if not data:
            return "{}"
        lines: list[str] = []
        for k, v in data.items():
            key_str = str(k)
            if isinstance(v, (dict, list)) and len(v) > 0:
                lines.append(f"{pad}{key_str}:")
                lines.append(dump_yaml(v, indent + 1))
            elif isinstance(v, dict):
                lines.append(f"{pad}{key_str}: {{}}")
            elif isinstance(v, list):
                lines.append(f"{pad}{key_str}: []")
            else:
                lines.append(f"{pad}{key_str}: {_yaml_format_scalar(v)}")
        return "\n".join(lines)
    if isinstance(data, list):
        if not data:
            return "[]"
        lines = []
        for item in data:
            if isinstance(item, dict) and item:
                items_list = list(item.items())
                first_k, first_v = items_list[0]
                if isinstance(first_v, (dict, list)) and len(first_v) > 0:
                    lines.append(f"{pad}- {first_k}:")
                    lines.append(dump_yaml(first_v, indent + 2))
                elif isinstance(first_v, dict):
                    lines.append(f"{pad}- {first_k}: {{}}")
                elif isinstance(first_v, list):
                    lines.append(f"{pad}- {first_k}: []")
                else:
                    lines.append(f"{pad}- {first_k}: {_yaml_format_scalar(first_v)}")
                for k, v in items_list[1:]:
                    sub_pad = "  " * (indent + 1)
                    if isinstance(v, (dict, list)) and len(v) > 0:
                        lines.append(f"{sub_pad}{k}:")
                        lines.append(dump_yaml(v, indent + 2))
                    elif isinstance(v, dict):
                        lines.append(f"{sub_pad}{k}: {{}}")
                    elif isinstance(v, list):
                        lines.append(f"{sub_pad}{k}: []")
                    else:
                        lines.append(f"{sub_pad}{k}: {_yaml_format_scalar(v)}")
            elif isinstance(item, list) and item:
                lines.append(f"{pad}-")
                lines.append(dump_yaml(item, indent + 1))
            else:
                lines.append(f"{pad}- {_yaml_format_scalar(item)}")
        return "\n".join(lines)
    return _yaml_format_scalar(data)


# =============================================================================
# 5. CONSTRUCTION DU BROUILLON YAML ET AUDIT OPTION 1A / TABLEAU 1b
# =============================================================================

def verify_option_1a_locks(records: list[dict[str, Any]]) -> dict[str, Any]:
    """Vérifie programmatiquement les 4 verrous normatifs Option 1A sur classes et subclass_overrides (0 violation tolérée)."""
    by_classe = {r["classe"]: r for r in records}
    violations: list[str] = []

    # Verrou 1A-a : états aversifs à faible contrôle -> Y <= 0 (classes + overrides éventuels)
    checked_1aa: list[dict[str, Any]] = []
    for cls in LOCK_1AA_CLASSES:
        rec = by_classe[cls]
        sub_id = rec["subsector_id"]
        spec = SUBSECTOR_GEOMETRY_SPEC[sub_id]
        if spec["u_y"] > 0:
            violations.append(f"1A-a violation: {cls} -> {sub_id} (u_Y={spec['u_y']} > 0)")
        for ovr in rec["subclass_overrides"]:
            ospec = SUBSECTOR_GEOMETRY_SPEC[ovr["subsector_id"]]
            if ospec["u_y"] > 0:
                violations.append(
                    f"1A-a override violation: {cls}[{ovr['sous_classe']}] -> {ovr['subsector_id']} (u_Y={ospec['u_y']} > 0)"
                )
        checked_1aa.append({
            "classe": cls,
            "subsector_id": sub_id,
            "default_z": rec["default_z"],
            "u_X": spec["u_x"],
            "u_Y": spec["u_y"],
            "passed": spec["u_y"] <= 0,
        })

    # Verrou 1A-b : Q2 (-X, +Y) strictement réservé à l'affrontement agentique (classes + subclass_overrides)
    q2_assigned: list[dict[str, Any]] = []
    q2_overrides: list[dict[str, Any]] = []
    for rec in records:
        cls = rec["classe"]
        sub_id = rec["subsector_id"]
        if sub_id in Q2_SUBSECTORS:
            if cls not in LOCK_1AB_ALLOWED_Q2_CLASSES:
                violations.append(f"1A-b violation: {cls} en Q2 ({sub_id}) hors liste d'affrontement agentique")
            spec = SUBSECTOR_GEOMETRY_SPEC[sub_id]
            q2_assigned.append({
                "classe": cls,
                "subsector_id": sub_id,
                "default_z": rec["default_z"],
                "u_X": spec["u_x"],
                "u_Y": spec["u_y"],
                "has_split_note": rec["subsector_alt_or_split_note"] is not None,
            })
        for ovr in rec["subclass_overrides"]:
            osub = ovr["subsector_id"]
            if osub in Q2_SUBSECTORS:
                if (cls, ovr["sous_classe"]) not in LOCK_1AB_ALLOWED_Q2_OVERRIDES:
                    violations.append(
                        f"1A-b override violation: {cls}[{ovr['sous_classe']}] en Q2 ({osub}) non autorisé"
                    )
                ospec = SUBSECTOR_GEOMETRY_SPEC[osub]
                q2_overrides.append({
                    "classe": cls,
                    "sous_classe": ovr["sous_classe"],
                    "subsector_id": osub,
                    "default_z": ovr["default_z"],
                    "u_X": ospec["u_x"],
                    "u_Y": ospec["u_y"],
                })

    # Verrou 1A-c : Q4 (+X, -Y) accommodation ; sécurité/bonheur hors contrainte -> Y >= 0
    q4_assigned: list[dict[str, Any]] = []
    q4_overrides: list[dict[str, Any]] = []
    for rec in records:
        sub_id = rec["subsector_id"]
        if sub_id in Q4_SUBSECTORS:
            spec = SUBSECTOR_GEOMETRY_SPEC[sub_id]
            q4_assigned.append({
                "classe": rec["classe"],
                "subsector_id": sub_id,
                "default_z": rec["default_z"],
                "u_X": spec["u_x"],
                "u_Y": spec["u_y"],
            })
        for ovr in rec["subclass_overrides"]:
            osub = ovr["subsector_id"]
            if osub in Q4_SUBSECTORS:
                ospec = SUBSECTOR_GEOMETRY_SPEC[osub]
                q4_overrides.append({
                    "classe": rec["classe"],
                    "sous_classe": ovr["sous_classe"],
                    "subsector_id": osub,
                    "default_z": ovr["default_z"],
                    "u_X": ospec["u_x"],
                    "u_Y": ospec["u_y"],
                })

    # Vérifications explicites Option 1A-c sur splits Rassurer / Résignation
    rassurer_ovr = {o["sous_classe"]: o for o in by_classe["Rassurer"]["subclass_overrides"]}
    for sc in ("sérénité", "tranquilliser", "insouciance"):
        if rassurer_ovr[sc]["u_Y"] <= 0:
            violations.append(f"1A-c split violation: Rassurer[{sc}] doit résider en Y > 0 (Q1)")
    resign_ovr = {o["sous_classe"]: o for o in by_classe["Résignation"]["subclass_overrides"]}
    if not (resign_ovr["acceptation"]["u_X"] > 0 and resign_ovr["acceptation"]["u_Y"] < 0):
        violations.append("1A-c split violation: Résignation[acceptation] doit résider en Q4 (+X, -Y)")

    sec_happ_checked: list[dict[str, Any]] = []
    for cls in LOCK_1AC_SECURITY_HAPPINESS_CLASSES:
        rec = by_classe[cls]
        sub_id = rec["subsector_id"]
        spec = SUBSECTOR_GEOMETRY_SPEC[sub_id]
        if spec["u_y"] < 0:
            violations.append(f"1A-c violation: {cls} -> {sub_id} (u_Y={spec['u_y']} < 0)")
        for ovr in rec["subclass_overrides"]:
            if ovr["u_Y"] < 0:
                violations.append(f"1A-c override violation: {cls}[{ovr['sous_classe']}] u_Y < 0")
        sec_happ_checked.append({
            "classe": cls,
            "subsector_id": sub_id,
            "default_z": rec["default_z"],
            "u_X": spec["u_x"],
            "u_Y": spec["u_y"],
            "passed": spec["u_y"] >= 0,
        })

    # Verrou 1A-d : classes de surprise signalées avec central_operator_link: surprise_z1
    surprise_checked: list[dict[str, Any]] = []
    for cls in LOCK_1AD_SURPRISE_CLASSES:
        rec = by_classe[cls]
        ok = rec["central_operator_link"] == "surprise_z1"
        if not ok:
            violations.append(f"1A-d violation: {cls} sans central_operator_link='surprise_z1'")
        surprise_checked.append({
            "classe": cls,
            "scope_status": rec["scope_status"],
            "default_z": rec["default_z"],
            "subsector_id": rec["subsector_id"],
            "central_operator_link": rec["central_operator_link"],
            "passed": ok,
        })

    assert not violations, "Violations Option 1A détectées :\n" + "\n".join(violations)
    return {
        "violations_count": 0,
        "lock_1aa": checked_1aa,
        "lock_1ab_q2_classes": q2_assigned,
        "lock_1ab_q2_overrides": q2_overrides,
        "lock_1ac_q4_classes": q4_assigned,
        "lock_1ac_q4_overrides": q4_overrides,
        "lock_1ac_security_happiness": sec_happ_checked,
        "lock_1ad_surprise": surprise_checked,
    }


def evaluate_tableau_1b_matrix(
    records: list[dict[str, Any]],
    df_zplus: pd.DataFrame,
) -> list[dict[str, Any]]:
    """Vérifie la cohérence des jalons du Tableau 1b présents dans Z_PLUS_ACTIVE (après subclass_overrides)."""
    by_classe = {r["classe"]: r for r in records}
    act_df = df_zplus[df_zplus["hemisphere_route"] == "Z_PLUS_ACTIVE"]
    rows: list[dict[str, Any]] = []

    for m in TABLEAU_1B_MILESTONES:
        jalon = m["jalon"]
        sub_t1b = m["subsector_t1b"]
        spec_t1b = SUBSECTOR_GEOMETRY_SPEC[sub_t1b]
        expected_cls = m["dima_classe_expected"]
        matches = act_df[act_df["lemme_norm"] == jalon]

        if expected_cls is None:
            rows.append({
                "jalon": jalon,
                "z_t1b": m["z_t1b"],
                "subsector_t1b": sub_t1b,
                "present_in_z_plus_active": False,
                "dima_classe": "— (absent de DIMA ExpAffect)",
                "sous_classe": "—",
                "assigned_subsector": "—",
                "assigned_z": None,
                "override_applied": False,
                "l1_ray_distance": None,
                "V_harm": None,
                "A_harm": None,
                "D_orth": None,
                "status": "OUT_OF_DIMA",
            })
            continue

        sub_matches = matches[matches["classe"] == expected_cls]
        assert len(sub_matches) >= 1, f"Jalon {jalon} attendu dans {expected_cls} (Z_PLUS_ACTIVE) introuvable."
        first_row = sub_matches.iloc[0]
        rec = by_classe[expected_cls]
        sc_val = "" if pd.isna(first_row["sous_classe"]) else str(first_row["sous_classe"]).strip()
        ovr_map = {o["sous_classe"]: o for o in rec["subclass_overrides"]}
        matched_ovr = ovr_map.get(sc_val)

        if matched_ovr is not None:
            sub_eff = matched_ovr["subsector_id"]
            z_eff = matched_ovr["default_z"]
            override_applied = True
        else:
            sub_eff = rec["subsector_id"]
            z_eff = rec["default_z"]
            override_applied = False

        spec_eff = SUBSECTOR_GEOMETRY_SPEC[sub_eff]
        l1_dist = abs(spec_eff["u_x"] - spec_t1b["u_x"]) + abs(spec_eff["u_y"] - spec_t1b["u_y"])

        if sub_eff == sub_t1b:
            status = "EXACT_MATCH"
        elif rec["subsector_alt_or_split_note"] is not None:
            status = "SPLIT_FLAGGED"
        else:
            status = "ADJACENT_RAY"

        rows.append({
            "jalon": jalon,
            "z_t1b": m["z_t1b"],
            "subsector_t1b": sub_t1b,
            "present_in_z_plus_active": True,
            "dima_classe": expected_cls,
            "sous_classe": sc_val or "—",
            "assigned_subsector": sub_eff,
            "assigned_z": z_eff,
            "override_applied": override_applied,
            "l1_ray_distance": l1_dist,
            "V_harm": float(first_row["V_harm"]),
            "A_harm": float(first_row["A_harm"]),
            "D_orth": float(first_row["D_orth"]),
            "status": status,
        })

    return rows


def build_class_records(
    df_summary: pd.DataFrame,
    df_zplus: pd.DataFrame,
) -> list[dict[str, Any]]:
    """Construit les 109 fiches de classes DIMA avec agrégats empiriques, ancrages et subclass_overrides."""
    assert len(df_summary) == 109, f"Attendu 109 classes, trouvé {len(df_summary)}"
    summary_classes = set(df_summary["classe"].tolist())
    assert summary_classes == set(CLASS_ANCHOR_SPECS.keys()), (
        f"Différence classes summary vs CLASS_ANCHOR_SPECS : "
        f"manquantes={summary_classes - set(CLASS_ANCHOR_SPECS.keys())}, "
        f"en_trop={set(CLASS_ANCHOR_SPECS.keys()) - summary_classes}"
    )
    assert len(SUBCLASS_OVERRIDES_SPECS) == 8, (
        f"Attendu 8 classes avec subclass_overrides, trouvé {len(SUBCLASS_OVERRIDES_SPECS)}"
    )

    records: list[dict[str, Any]] = []
    zm_move_entries = 0
    zm_keep_entries = 0
    zm_move_classes: set[str] = set()
    zm_keep_classes: set[str] = set()

    for _, row in df_summary.iterrows():
        cls = str(row["classe"])
        categ = str(row["categ"])
        ant_fam_raw = row["antonymie_family"]
        ant_fam = None if pd.isna(ant_fam_raw) or not str(ant_fam_raw).strip() else str(ant_fam_raw).strip()

        n_active = int(row["n_z_plus_active"])
        n_sat = int(row["n_z_plus_satellite"])
        n_res = int(row["n_z_minus_reserve"])
        n_disc = int(row["n_non_lexical_discard"])
        n_entries = int(row["n_entries"])
        n_zm = int(row["n_z_minus_value_candidate"])

        if n_active > 0:
            scope_status = "active_z_plus"
        elif n_sat > 0:
            scope_status = "satellite_only_z_plus"
        else:
            scope_status = "reserve_or_discard_only"

        spec = CLASS_ANCHOR_SPECS[cls]
        sub_df = df_zplus[df_zplus["classe"] == cls]

        if scope_status == "reserve_or_discard_only":
            assert len(sub_df) == 0
            assert spec["default_z"] is None and spec["subsector_id"] is None
            assert cls not in SUBCLASS_OVERRIDES_SPECS
            empirical_means = None
            sample_lemmes: list[str] = []
            dima_sous_classes: list[str] = []
            active_sous_classes: set[str] = set()
        else:
            assert len(sub_df) == n_active + n_sat
            assert spec["default_z"] in (3, 4, 5)
            assert spec["subsector_id"] in SUBSECTOR_GEOMETRY_SPEC

            basis_route = "Z_PLUS_ACTIVE" if n_active > 0 else "Z_PLUS_SATELLITE"
            basis_df = sub_df[sub_df["hemisphere_route"] == basis_route]
            sorted_basis = basis_df.sort_values(["part_disc", "lemme_norm"])
            sample_lemmes = list(dict.fromkeys(sorted_basis["lemme_norm"].astype(str).tolist()))[:5]
            dima_sous_classes = sorted({
                str(x).strip()
                for x in sub_df["sous_classe"].dropna().tolist()
                if str(x).strip()
            })
            active_sous_classes = {
                str(x).strip()
                for x in sub_df[sub_df["hemisphere_route"] == "Z_PLUS_ACTIVE"]["sous_classe"].dropna().tolist()
                if str(x).strip()
            }
            empirical_means = {
                "basis": basis_route,
                "V_harm": round(float(basis_df["V_harm"].mean()), 6),
                "A_harm": round(float(basis_df["A_harm"].mean()), 6),
                "D_orth": round(float(basis_df["D_orth"].mean()), 6),
                "all_z_plus_V_harm": round(float(sub_df["V_harm"].mean()), 6),
                "all_z_plus_A_harm": round(float(sub_df["A_harm"].mean()), 6),
                "all_z_plus_D_orth": round(float(sub_df["D_orth"].mean()), 6),
            }

        # Validation et construction des subclass_overrides structurés (pour MP4)
        raw_ovr_list = SUBCLASS_OVERRIDES_SPECS.get(cls, [])
        seen_ovr_sc: set[str] = set()
        subclass_overrides: list[dict[str, Any]] = []
        for ovr in sorted(raw_ovr_list, key=lambda x: str(x["sous_classe"])):
            sc = str(ovr["sous_classe"])
            assert sc not in seen_ovr_sc, f"sous_classe dupliquée dans SUBCLASS_OVERRIDES_SPECS[{cls}]: {sc}"
            seen_ovr_sc.add(sc)
            assert sc in dima_sous_classes, (
                f"sous_classe d'override '{sc}' introuvable dans dima_sous_classes[{cls}]: {dima_sous_classes}"
            )
            osub = str(ovr["subsector_id"])
            assert osub in SUBSECTOR_GEOMETRY_SPEC, f"subsector_id inconnu: {osub}"
            oz = int(ovr["default_z"])
            assert oz in (3, 4, 5), f"default_z invalide pour override {cls}[{sc}]: {oz}"
            ospec = SUBSECTOR_GEOMETRY_SPEC[osub]
            subclass_overrides.append({
                "sous_classe": sc,
                "subsector_id": osub,
                "pair_id": ospec["pair_id"],
                "default_z": oz,
                "z_alt": ovr["z_alt"],
                "u_X": ospec["u_x"],
                "u_Y": ospec["u_y"],
                "rationale": ovr["rationale"],
            })

        if cls in SUBCLASS_OVERRIDES_SPECS:
            missing_act_sc = active_sous_classes - seen_ovr_sc
            assert not missing_act_sc, (
                f"Sous-classes Z_PLUS_ACTIVE non couvertes dans SUBCLASS_OVERRIDES_SPECS[{cls}]: {sorted(missing_act_sc)}"
            )

        if n_zm > 0:
            dec = spec["z_minus_value_decision"]
            assert dec in ("keep_z_plus", "move_to_z_minus_reserve")
            if dec == "move_to_z_minus_reserve":
                zm_move_entries += n_zm
                zm_move_classes.add(cls)
            else:
                zm_keep_entries += n_zm
                zm_keep_classes.add(cls)
        else:
            assert spec["z_minus_value_decision"] is None

        sub_id = spec["subsector_id"]
        sub_geom = SUBSECTOR_GEOMETRY_SPEC[sub_id] if sub_id else None

        records.append({
            "classe": cls,
            "categ": categ,
            "antonymie_family": ant_fam,
            "scope_status": scope_status,
            "counts": {
                "n_entries": n_entries,
                "n_z_plus_active": n_active,
                "n_z_plus_satellite": n_sat,
                "n_z_minus_reserve": n_res,
                "n_non_lexical_discard": n_disc,
                "n_z_minus_value_candidate": n_zm,
            },
            "empirical_means": empirical_means,
            "default_z": spec["default_z"],
            "subsector_id": sub_id,
            "subsector_pair": sub_geom["pair_id"] if sub_geom else None,
            "subsector_u_X": sub_geom["u_x"] if sub_geom else None,
            "subsector_u_Y": sub_geom["u_y"] if sub_geom else None,
            "central_operator_link": spec["central_operator_link"],
            "subsector_alt_or_split_note": spec["subsector_alt_or_split_note"],
            "subclass_overrides": subclass_overrides,
            "z_minus_value_decision": spec["z_minus_value_decision"],
            "z_minus_value_rationale": spec["z_minus_value_rationale"],
            "exploratory_z6_z7_tag": spec["exploratory_z6_z7_tag"],
            "anchor_rationale": spec["anchor_rationale"],
            "sample_lemmes": sample_lemmes,
            "dima_sous_classes": dima_sous_classes,
        })

    assert zm_move_classes == {"Croyance", "Croyance relig", "Incrédulité", "Incrédulité relig", "Pudeur"} and zm_move_entries == 7, (
        f"Arbitrage move_to_z_minus_reserve inattendu : {sorted(zm_move_classes)} ({zm_move_entries} entrées)"
    )
    assert zm_keep_classes == {"Estime respect", "Gratitude", "Mauvaise conscience", "Mauvaise conscience scrupule"} and zm_keep_entries == 17, (
        f"Arbitrage keep_z_plus inattendu : {sorted(zm_keep_classes)} ({zm_keep_entries} entrées)"
    )

    n_act_cls = sum(1 for r in records if r["scope_status"] == "active_z_plus")
    n_sat_cls = sum(1 for r in records if r["scope_status"] == "satellite_only_z_plus")
    n_res_cls = sum(1 for r in records if r["scope_status"] == "reserve_or_discard_only")
    assert n_act_cls == 76 and n_sat_cls == 16 and n_res_cls == 17, (
        f"Comptes de portée inattendus : {n_act_cls}/{n_sat_cls}/{n_res_cls}"
    )
    total_ovr_rules = sum(len(r["subclass_overrides"]) for r in records)
    assert total_ovr_rules == 52, f"Nombre total de règles subclass_overrides inattendu : {total_ovr_rules} != 52"
    return records


def render_review_markdown(
    anchors_spec: dict[str, Any],
    records: list[dict[str, Any]],
    locks_audit: dict[str, Any],
    t1b_rows: list[dict[str, Any]],
    df_zplus: pd.DataFrame,
    json_sha: str,
    yaml_sha: str,
) -> str:
    """Génère le rapport clinique déterministe reports/lexicon_v3/mp3_anchors_review.md."""
    z_plus_records = [r for r in records if r["scope_status"] != "reserve_or_discard_only"]
    res_records = [r for r in records if r["scope_status"] == "reserve_or_discard_only"]

    lines: list[str] = []
    lines.append("# Rapport de Revue Clinique — Micro-Passe 3 (FINALISÉE MP3b) : Ancrage des 109 classes DIMA vers $Z \\in \\{3, 4, 5\\}$ et les 17 `FunctionalSubsector` (CARTOGRAFFECT v3.0.0)")
    lines.append("")
    lines.append("- **Script :** [`python/lexicon_pipeline/03a_build_class_anchors_draft.py`](../../python/lexicon_pipeline/03a_build_class_anchors_draft.py) *(idempotent, zéro appel réseau)*")
    lines.append("- **Statut de revue clinique :** `APPROVED` (`clinical_review_status: APPROVED`)")
    lines.append("- **Périmètre Lean 4 :** `Cartograffect/` strictement en lecture seule (`0` fichier modifié)")
    lines.append("- **Référentiel figé :** [`data/config/canonical_z0_z2_anchors.json`](../../data/config/canonical_z0_z2_anchors.json) (`SHA-256`: `" + json_sha + "`)")
    lines.append("- **Table d'ancrage approuvée :** [`data/config/dima_class_to_subsector_109.yaml`](../../data/config/dima_class_to_subsector_109.yaml) (`SHA-256`: `" + yaml_sha + "`)")
    lines.append("- **Couverture DIMA :** `109` classes = `76` `active_z_plus` + `16` `satellite_only_z_plus` (`92` classes $Z_+$ couvrant `1,494` entrées = `549` `Z_PLUS_ACTIVE` + `945` `Z_PLUS_SATELLITE`, après reclassement des 4 métatermes `affect`, `affectivité`, `sentiment`, `émotion` de `Troubler` vers `NON_LEXICAL_DISCARD`/`META_CLASSIFIER`) + `17` `reserve_or_discard_only`")
    lines.append("- **Règles `subclass_overrides` :** `8` classes hétérogènes découpées / `52` règles structurées par `SOUS-CLASSE`")
    lines.append("")
    lines.append("### Empreintes SHA-256 des entrées lues en lecture seule")
    lines.append("")
    lines.append("| Source | SHA-256 |")
    lines.append("| :--- | :--- |")
    for rel_p, digest in anchors_spec["source_lean_modules"].items():
        lines.append(f"| `{rel_p}` | `{digest}` |")
    lines.append(f"| `data/processed/dima_classes_summary.csv` | `{sha256_file(SUMMARY_CSV_PATH)}` |")
    lines.append(f"| `data/processed/dima_z_plus_psychometrics.parquet` | `{sha256_file(Z_PLUS_PARQUET_PATH)}` |")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Section 1 : Référence figée Lean 4
    lines.append("## 1. Spécification figée du noyau Lean 4 v3.0.0")
    lines.append("")
    lines.append("### 1.1 Les 11 états canoniques verrouillés sur $Z \\in \\{0, 1, 2\\}$ et la bijection Rolls bornée à $Z = 2$")
    lines.append("")
    lines.append("| Identifiant Lean 4 | Libellé | Coordonnée `(X, Y, Z)` | Géométrie | Sous-secteur | Valence | Antagoniste | Bijection Rolls ($Z=2$ uniquement) | Note |")
    lines.append("| :--- | :--- | :---: | :---: | :--- | :---: | :--- | :--- | :--- |")
    for st in anchors_spec["canonical_z0_z2_states"]:
        pt_str = f"`({st['point'][0]}, {st['point'][1]}, {st['point'][2]})`"
        rolls_str = f"`{st['rolls_contingency']['symbol']}` ({st['rolls_contingency']['stimulus_notation']})" if st["rolls_contingency"] else "—"
        note = "Instabilité axiale P2 (`χ > 0`)" if st["p2_axial_instability_negative_charge"] else ("Centre basal" if st["z"] == 0 else ("Rupture ascendante" if st["z"] == 1 else ("Suspension descendante R5" if st["id"] == "anticipation" else "—")))
        lines.append(f"| `{st['lean_constructor']}` | {st['label_fr']} | {pt_str} | `{st['geometry_type']}` | `{st['subsector_id']}` | `{st['hedonic_polarity']}` | `{st['antagonist_id']}` | {rolls_str} | {note} |")
    lines.append("")

    lines.append("### 1.2 Les 3 opérateurs centraux de la taxonomie structurée ($Z \\in \\{3, 4, 5\\}$)")
    lines.append("")
    lines.append("| Constructeur Lean 4 | Libellé | Coordonnée | Rayon $R(Z)$ | Rôle |")
    lines.append("| :--- | :--- | :---: | :---: | :--- |")
    for op in anchors_spec["structured_taxonomy_central_operators_z3_z5"]:
        pt_str = f"`({op['point'][0]}, {op['point'][1]}, {op['point'][2]})`"
        lines.append(f"| `{op['lean_constructor']}` | **{op['label_fr']}** | {pt_str} | `{op['crown_radius']}` | {op['lean_comment']} |")
    lines.append("")

    lines.append("### 1.3 Les 17 `FunctionalSubsector` (8 paires conjuguées + centre fixe) et vecteurs $L_1$")
    lines.append("")
    counts_by_sub = {s["subsector_id"]: 0 for s in anchors_spec["functional_subsectors_17"]}
    for r in z_plus_records:
        counts_by_sub[r["subsector_id"]] += 1

    lines.append("| Paire | Constructeur Lean 4 | Conjugué | $(u_X, u_Y)$ | $\\|u\\|_1$ | Valence | Repères Tableau 1b ($Z=3/4/5$) | Classes $Z_+$ |")
    lines.append("| :---: | :--- | :--- | :---: | :---: | :---: | :--- | ---: |")
    for s in anchors_spec["functional_subsectors_17"]:
        t1b = s["tableau_1b"]
        rep = f"Z3: {t1b['z3_high_A']}/{t1b['z3_low_A']} · Z4: {t1b['z4_high_A']}/{t1b['z4_low_A']} · Z5: {t1b['z5_high_A']}/{t1b['z5_low_A']}"
        u_str = f"`({s['u_X']:+.2f}, {s['u_Y']:+.2f})`"
        lines.append(f"| `{s['pair_id']}` | `{s['subsector_id']}` | `{s['conjugate_subsector']}` | {u_str} | `{s['l1_norm']:.1f}` | `{s['hedonic_polarity']}` | {rep} | {counts_by_sub[s['subsector_id']]} |")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Section 2 : Table complète des 92 classes Z+ regroupées par les 17 FunctionalSubsector
    lines.append("## 2. Table complète des 92 classes $Z_+$ regroupées par `FunctionalSubsector`")
    lines.append("")
    for s in anchors_spec["functional_subsectors_17"]:
        sid = s["subsector_id"]
        cls_list = sorted([r for r in z_plus_records if r["subsector_id"] == sid], key=lambda x: (x["default_z"], x["categ"], x["classe"]))
        lines.append(f"### `{sid}` (`{s['pair_id']}` · `u = ({s['u_X']:+.2f}, {s['u_Y']:+.2f})` · {len(cls_list)} classes)")
        lines.append("")
        if not cls_list:
            lines.append("*Aucune classe assignée directement par défaut à ce sous-secteur.*")
            lines.append("")
            continue
        lines.append("| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\\text{harm}}$ | $A_{\\text{harm}}$ | $D_{\\perp}$ | Exemples de lemmes (3–5) | Drapeaux |")
        lines.append("| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |")
        for r in cls_list:
            em = r["empirical_means"]
            c = r["counts"]
            scope_lbl = "ACT" if r["scope_status"] == "active_z_plus" else "SAT_ONLY"
            lems = ", ".join(f"`{lm}`" for lm in r["sample_lemmes"][:5])
            flags: list[str] = []
            if r["central_operator_link"]:
                flags.append(f"`link:{r['central_operator_link']}`")
            if r["subclass_overrides"]:
                flags.append(f"`OVR:{len(r['subclass_overrides'])}`")
            elif r["subsector_alt_or_split_note"]:
                flags.append("`SPLIT`")
            if r["z_minus_value_decision"]:
                flags.append(f"`zm:{r['z_minus_value_decision']}`")
            if r["exploratory_z6_z7_tag"]:
                flags.append(f"`{r['exploratory_z6_z7_tag']}`")
            flags_str = " ".join(flags) if flags else "—"
            lines.append(
                f"| `{r['classe']}` | {r['categ']} | `{scope_lbl}` | {r['default_z']} | "
                f"{c['n_z_plus_active']}/{c['n_z_plus_satellite']} | "
                f"`{em['V_harm']:+.2f}` | `{em['A_harm']:+.2f}` | `{em['D_orth']:+.2f}` | "
                f"{lems} | {flags_str} |"
            )
        lines.append("")
    lines.append("---")
    lines.append("")

    # Section 3 : Matrice de vérification des jalons du Tableau 1b
    lines.append("## 3. Matrice de vérification des jalons du Tableau 1b v3.0.0")
    lines.append("")
    present_rows = [r for r in t1b_rows if r["present_in_z_plus_active"]]
    exact_cnt = sum(1 for r in present_rows if r["status"] == "EXACT_MATCH")
    ovr_exact_cnt = sum(1 for r in present_rows if r["status"] == "EXACT_MATCH" and r["override_applied"])
    split_cnt = sum(1 for r in present_rows if r["status"] == "SPLIT_FLAGGED")
    adj_cnt = sum(1 for r in present_rows if r["status"] == "ADJACENT_RAY")
    lines.append(
        f"- **Jalons Tableau 1b vérifiés dans `Z_PLUS_ACTIVE` :** `{len(present_rows)}` "
        f"(`{exact_cnt}` `EXACT_MATCH` dont `{ovr_exact_cnt}` résolus via `subclass_overrides`, `{split_cnt}` `SPLIT_FLAGGED` résiduels pour découpage ultérieur, `{adj_cnt}` `ADJACENT_RAY`)."
    )
    lines.append("- **Note sur `Z_PLUS_SATELLITE` :** `sentiment de sécurité` (`Confiance_Sentiment de sécurité`, $V=+0.67, A=-0.28, D=+0.23$) et `sentiment d'insécurité` (`Défiance_Sentiment d'insécurité`, $V=-0.81, A=+0.29, D=-0.01$) sont présents en `Z_PLUS_SATELLITE` (locutions multi-mots) et alignés sur leurs classes respectives.")
    lines.append("- **Note sur les jalons absents de DIMA `ExpAffect` :** `courage`, `plénitude`, `émerveillement` sont conservés dans `data/config/fr_en_bridge_overrides.csv` comme ancres théoriques hors DIMA v35.")
    lines.append("")
    lines.append("| Jalon (`lemme_norm`) | $Z_{\\text{T1b}}$ | Sous-secteur Tableau 1b | Classe DIMA | `SOUS-CLASSE` | Sous-secteur assigné | $Z_{\\text{eff}}$ | Override | $\\|\\Delta u\\|_1$ | $V_{\\text{harm}}$ | $A_{\\text{harm}}$ | $D_{\\perp}$ | Statut |")
    lines.append("| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :---: | :---: | ---: | ---: | ---: | :--- |")
    for r in present_rows:
        ovr_lbl = "`OVR`" if r["override_applied"] else "—"
        lines.append(
            f"| `{r['jalon']}` | {r['z_t1b']} | `{r['subsector_t1b']}` | `{r['dima_classe']}` | `{r['sous_classe']}` | "
            f"`{r['assigned_subsector']}` | {r['assigned_z']} | {ovr_lbl} | `{r['l1_ray_distance']:.2f}` | "
            f"`{r['V_harm']:+.2f}` | `{r['A_harm']:+.2f}` | `{r['D_orth']:+.2f}` | `{r['status']}` |"
        )
    lines.append("")
    lines.append("---")
    lines.append("")

    # Section 4 : Audit explicite des verrous Option 1A
    lines.append("## 4. Audit explicite des 4 verrous normatifs Option 1A (`0` violation)")
    lines.append("")
    lines.append(f"- **Statut global de vérification programmatique :** **`PASS` ({locks_audit['violations_count']} violation — classes + 52 règles `subclass_overrides`)**")
    lines.append("")
    lines.append("### 4.1 Verrou 1A-a : États aversifs à faible contrôle instrumental perçu ($Y \\le 0$)")
    lines.append("")
    lines.append("| Classe | Sous-secteur | $Z$ | $u_X$ | $u_Y$ | Contrôle |")
    lines.append("| :--- | :--- | :---: | :---: | :---: | :---: |")
    for item in locks_audit["lock_1aa"]:
        lines.append(f"| `{item['classe']}` | `{item['subsector_id']}` | {item['default_z']} | `{item['u_X']:+.2f}` | `{item['u_Y']:+.2f}` | PASS (`Y <= 0`) |")
    lines.append("")

    lines.append("### 4.2 Verrou 1A-b : Quadrant Q2 ($-X, +Y$) strictement réservé à l'affrontement agentique")
    lines.append("")
    lines.append("| Classe | Sous-secteur Q2 | $Z$ | $u_X$ | $u_Y$ | Note de découpage |")
    lines.append("| :--- | :--- | :---: | :---: | :---: | :--- |")
    for item in locks_audit["lock_1ab_q2_classes"]:
        split_lbl = "Oui (`SPLIT` signalé)" if item["has_split_note"] else "Non"
        lines.append(f"| `{item['classe']}` | `{item['subsector_id']}` | {item['default_z']} | `{item['u_X']:+.2f}` | `{item['u_Y']:+.2f}` | {split_lbl} |")
    lines.append("")
    lines.append("- **Overrides Q2 autorisés (affrontement/frustration active) :** " + ", ".join(f"`{x['classe']}[{x['sous_classe']}]->{x['subsector_id']}`" for x in locks_audit["lock_1ab_q2_overrides"]) + ".")
    lines.append("")

    lines.append("### 4.3 Verrou 1A-c : Q4 ($+X, -Y$) accommodation secondaire vs sécurité/bonheur en $Y \\ge 0$")
    lines.append("")
    lines.append("- **Classes assignées en Q4 (`+X, -Y`, accommodation face à une limite objective d'action) :** " + ", ".join(f"`{x['classe']}` (`{x['subsector_id']}`)" for x in locks_audit["lock_1ac_q4_classes"]) + ".")
    lines.append("- **Splits encodés pour Verrou 1A-c :** `Rassurer` (`sérénité`, `tranquilliser`, `insouciance` -> Q1 `lateralApproachSynergy`, $Y > 0$) et `Résignation` (`acceptation` -> Q4 `lateralReceptiveAccomm`, $X > 0, Y < 0$).")
    lines.append("")
    lines.append("| Classe sécurité / bonheur | Sous-secteur | $Z$ | $u_X$ | $u_Y$ | Contrôle |")
    lines.append("| :--- | :--- | :---: | :---: | :---: | :---: |")
    for item in locks_audit["lock_1ac_security_happiness"]:
        lines.append(f"| `{item['classe']}` | `{item['subsector_id']}` | {item['default_z']} | `{item['u_X']:+.2f}` | `{item['u_Y']:+.2f}` | PASS (`Y >= 0`) |")
    lines.append("")

    lines.append("### 4.4 Verrou 1A-d : Classes de surprise et lien `central_operator_link: surprise_z1`")
    lines.append("")
    lines.append("| Classe | Portée | $Z$ | Sous-secteur | `central_operator_link` | Contrôle |")
    lines.append("| :--- | :--- | :---: | :--- | :--- | :---: |")
    for item in locks_audit["lock_1ad_surprise"]:
        lines.append(f"| `{item['classe']}` | `{item['scope_status']}` | {item['default_z'] if item['default_z'] is not None else '—'} | `{item['subsector_id'] or '—'}` | `{item['central_operator_link']}` | PASS |")
    lines.append("")

    ovr_records = [r for r in records if r["subclass_overrides"]]
    total_ovr = sum(len(r["subclass_overrides"]) for r in ovr_records)
    lines.append(f"### 4.5 Règles structurées `subclass_overrides` approuvées (`{len(ovr_records)}` classes / `{total_ovr}` règles)")
    lines.append("")
    lines.append("| Classe | `SOUS-CLASSE` | `subsector_id` | Paire | $Z$ | $Z_{\\text{alt}}$ | $(u_X, u_Y)$ | Justification clinique |")
    lines.append("| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :--- |")
    for r in ovr_records:
        for ovr in r["subclass_overrides"]:
            z_alt_str = str(ovr["z_alt"]) if ovr["z_alt"] is not None else "—"
            u_str = f"`({ovr['u_X']:+.2f}, {ovr['u_Y']:+.2f})`"
            lines.append(
                f"| `{r['classe']}` | `{ovr['sous_classe']}` | `{ovr['subsector_id']}` | `{ovr['pair_id']}` | "
                f"{ovr['default_z']} | {z_alt_str} | {u_str} | {ovr['rationale']} |"
            )
    lines.append("")

    split_records = [r for r in records if r["subsector_alt_or_split_note"]]
    lines.append(f"### 4.6 Synthèse des notes de découpage par `SOUS-CLASSE` (`{len(split_records)}` classes)")
    lines.append("")
    lines.append("| Classe | Sous-secteur par défaut | `subclass_overrides` | Note de découpage / sous-classes critiques |")
    lines.append("| :--- | :--- | :---: | :--- |")
    for r in split_records:
        ovr_cnt = len(r["subclass_overrides"])
        lines.append(f"| `{r['classe']}` | `{r['subsector_id'] or 'reserve'}` | {ovr_cnt if ovr_cnt else '—'} | {r['subsector_alt_or_split_note']} |")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Section 5 : Tableau dédié aux 24 entrées frontières z_minus_value_candidate == True
    lines.append("## 5. Tableau d'arbitrage clinique des 24 entrées frontières `z_minus_value_candidate == True` (9 classes)")
    lines.append("")
    lines.append("Arbitrage clinique définitif sur les 24 entrées restantes dans `Z_PLUS_ACTIVE` (9 classes axiologiques/épistémiques) : "
                 "**5 classes (`7` entrées) basculées vers `-Z` (`move_to_z_minus_reserve`)** "
                 "(`Croyance` : 1, `Croyance relig` : 1, `Incrédulité` : 2, `Incrédulité relig` : 2, `Pudeur` : 1) "
                 "et **4 classes (`17` entrées) maintenues en $Z_+$, $Z = 4$ (`keep_z_plus`)** "
                 "(`Estime respect` : 4, `Gratitude` : 3, `Mauvaise conscience` : 9, `Mauvaise conscience scrupule` : 1).")
    lines.append("")
    zm_df = df_zplus[df_zplus["z_minus_value_candidate"] == True].sort_values(["classe", "lemme_norm"])  # noqa: E712
    assert len(zm_df) == 24, f"Attendu 24 entrées z_minus_value_candidate, trouvé {len(zm_df)}"
    by_classe = {r["classe"]: r for r in records}
    lines.append("| # | Classe DIMA | `lemme_norm` | POS | `sous_classe` | $V_{\\text{harm}}$ | $A_{\\text{harm}}$ | $D_{\\perp}$ | Sous-secteur ($Z$) | Arbitrage proposé |")
    lines.append("| ---: | :--- | :--- | :---: | :--- | ---: | ---: | ---: | :--- | :--- |")
    for idx, (_, zr) in enumerate(zm_df.iterrows(), 1):
        rec = by_classe[str(zr["classe"])]
        lines.append(
            f"| {idx} | `{zr['classe']}` | `{zr['lemme_norm']}` | `{zr['part_disc']}` | `{zr['sous_classe']}` | "
            f"`{zr['V_harm']:+.2f}` | `{zr['A_harm']:+.2f}` | `{zr['D_orth']:+.2f}` | "
            f"`{rec['subsector_id']}` ($Z={rec['default_z']}$) | **`{rec['z_minus_value_decision']}`** |"
        )
    lines.append("")
    lines.append("---")
    lines.append("")

    # Section 6 : Traçabilité des 17 classes hors Z+ et des marqueurs exploratoires Z=6/Z=7
    lines.append("## 6. Traçabilité des 17 classes `reserve_or_discard_only` et marqueurs exploratoires $Z = 6 / Z = 7$")
    lines.append("")
    lines.append("### 6.1 Les 17 classes sans projection $Z_+$ (`reserve_or_discard_only`)")
    lines.append("")
    lines.append("| Classe DIMA | Cat. | `n_entries` | `Z_MINUS_RESERVE` | `NON_LEXICAL_DISCARD` | Famille `ANTONYMIE` | Note |")
    lines.append("| :--- | :---: | ---: | ---: | ---: | :--- | :--- |")
    for r in res_records:
        c = r["counts"]
        lines.append(
            f"| `{r['classe']}` | {r['categ']} | {c['n_entries']} | {c['n_z_minus_reserve']} | "
            f"{c['n_non_lexical_discard']} | {r['antonymie_family'] or '—'} | {r['anchor_rationale']} |"
        )
    lines.append("")
    z67_records = [r for r in z_plus_records if r["exploratory_z6_z7_tag"]]
    lines.append(f"### 6.2 Marqueurs documentaires facultatifs `exploratory_z6_z7_tag` (`{len(z67_records)}` classes, conservées dans $Z \\in \\{{3, 4, 5\\}}$)")
    lines.append("")
    lines.append("| Classe DIMA | $Z$ normatif | Sous-secteur | `exploratory_z6_z7_tag` |")
    lines.append("| :--- | :---: | :--- | :--- |")
    for r in z67_records:
        lines.append(f"| `{r['classe']}` | {r['default_z']} | `{r['subsector_id']}` | `{r['exploratory_z6_z7_tag']}` |")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    anchors_spec = extract_lean_canonical_spec()
    df_summary = pd.read_csv(SUMMARY_CSV_PATH)
    df_zplus = pd.read_parquet(Z_PLUS_PARQUET_PATH)

    records = build_class_records(df_summary, df_zplus)
    locks_audit = verify_option_1a_locks(records)
    t1b_rows = evaluate_tableau_1b_matrix(records, df_zplus)

    ANCHORS_JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
    REVIEW_MD_PATH.parent.mkdir(parents=True, exist_ok=True)

    json_text = json.dumps(anchors_spec, indent=2, ensure_ascii=False) + "\n"
    ANCHORS_JSON_PATH.write_bytes(json_text.encode("utf-8"))
    json_sha = hashlib.sha256(ANCHORS_JSON_PATH.read_bytes()).hexdigest()

    yaml_payload = {
        "clinical_review_status": "APPROVED",
        "schema_version": "1.1.0",
        "cartograffect_version": CART_VERSION,
        "reference_anchors_file": "data/config/canonical_z0_z2_anchors.json",
        "reference_anchors_sha256": json_sha,
        "summary": {
            "total_dima_classes": 109,
            "active_z_plus_classes": 76,
            "satellite_only_z_plus_classes": 16,
            "reserve_or_discard_only_classes": 17,
            "z_plus_entries_total": int(len(df_zplus)),
            "z_plus_active_entries": int((df_zplus["hemisphere_route"] == "Z_PLUS_ACTIVE").sum()),
            "z_plus_satellite_entries": int((df_zplus["hemisphere_route"] == "Z_PLUS_SATELLITE").sum()),
            "z_minus_value_candidate_active_entries": int((df_zplus["z_minus_value_candidate"] == True).sum()),  # noqa: E712
            "z_minus_value_keep_z_plus_classes": 4,
            "z_minus_value_keep_z_plus_entries": 17,
            "z_minus_value_move_to_reserve_classes": 5,
            "z_minus_value_move_to_reserve_entries": 7,
            "subclass_override_classes": len(SUBCLASS_OVERRIDES_SPECS),
            "subclass_override_rules": sum(len(v) for v in SUBCLASS_OVERRIDES_SPECS.values()),
            "tableau_1b_exact_match": sum(1 for r in t1b_rows if r["status"] == "EXACT_MATCH"),
            "tableau_1b_split_flagged": sum(1 for r in t1b_rows if r["status"] == "SPLIT_FLAGGED"),
            "tableau_1b_adjacent_ray": sum(1 for r in t1b_rows if r["status"] == "ADJACENT_RAY"),
            "option_1a_violations": locks_audit["violations_count"],
        },
        "classes": records,
    }
    yaml_header = (
        "# =============================================================================\n"
        "# CARTOGRAFFECT v3.0.0 — Micro-Passe 3 (TABLE D'ANCRAGE CLINIQUE APPROUVÉE — MP3b)\n"
        "# Ancrage des 109 classes DIMA vers Z in {3, 4, 5}, 17 FunctionalSubsector & 52 subclass_overrides\n"
        "# Généré de façon déterministe par python/lexicon_pipeline/03a_build_class_anchors_draft.py\n"
        "# =============================================================================\n\n"
    )
    yaml_text = yaml_header + dump_yaml(yaml_payload) + "\n"
    DRAFT_YAML_PATH.write_bytes(yaml_text.encode("utf-8"))
    yaml_sha = hashlib.sha256(DRAFT_YAML_PATH.read_bytes()).hexdigest()

    review_md = render_review_markdown(
        anchors_spec=anchors_spec,
        records=records,
        locks_audit=locks_audit,
        t1b_rows=t1b_rows,
        df_zplus=df_zplus,
        json_sha=json_sha,
        yaml_sha=yaml_sha,
    )
    REVIEW_MD_PATH.write_bytes(review_md.encode("utf-8"))
    md_sha = hashlib.sha256(REVIEW_MD_PATH.read_bytes()).hexdigest()

    print(f"WROTE {ANCHORS_JSON_PATH.relative_to(REPO_ROOT).as_posix()} SHA256={json_sha}")
    print(f"WROTE {DRAFT_YAML_PATH.relative_to(REPO_ROOT).as_posix()} SHA256={yaml_sha}")
    print(f"WROTE {REVIEW_MD_PATH.relative_to(REPO_ROOT).as_posix()} SHA256={md_sha}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
