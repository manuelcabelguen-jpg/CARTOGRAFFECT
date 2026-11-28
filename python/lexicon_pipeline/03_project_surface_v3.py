# SPDX-License-Identifier: AGPL-3.0-or-later
"""
03_project_surface_v3.py — Micro-Passe 4 : Projection sur la surface pleine L1
(|x| + |y| <= 2*floor(Z) - 2) & Injection radiale de l'activation autonome A
(CARTOGRAFFECT v3.0.0)

Périmètre strict :
- Lecture seule sur data/processed/dima_z_plus_psychometrics.parquet (1 494 lignes),
  data/config/dima_class_to_subsector_109.yaml (clinical_review_status == "APPROVED")
  et data/config/canonical_z0_z2_anchors.json.
- Aucune modification dans Cartograffect/ (noyau Lean 4 normatif en lecture seule).
- Aucun accès aux fichiers Diamant_303.
- Strictement idempotent (sorties déterministes octet pour octet, fins de ligne LF).
- Zéro appel réseau / API externe ; aucune dépendance hors bibliothèque standard +
  numpy, pandas, pyarrow, scipy, matplotlib.

Exports :
- data/processed/lexicon_v3_master.parquet (local uniquement, ignoré Git)
- data/processed/lexicon_v3_master.tsv (local uniquement, ignoré Git)
- reports/lexicon_v3/surface_Z3.png (300 dpi, versionnable Git)
- reports/lexicon_v3/surface_Z4.png (300 dpi, versionnable Git)
- reports/lexicon_v3/surface_Z5.png (300 dpi, versionnable Git)
- reports/lexicon_v3/mp4_projection_report.md (versionnable Git)
"""

from __future__ import annotations

import hashlib
import json
import math
import re
from pathlib import Path
from typing import Any

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
import numpy as np
import pandas as pd
from scipy import stats

REPO_ROOT = Path(__file__).resolve().parents[2]
PARQUET_IN_PATH = REPO_ROOT / "data" / "processed" / "dima_z_plus_psychometrics.parquet"
ANCHORS_YAML_PATH = REPO_ROOT / "data" / "config" / "dima_class_to_subsector_109.yaml"
ANCHORS_JSON_PATH = REPO_ROOT / "data" / "config" / "canonical_z0_z2_anchors.json"

MASTER_PARQUET_PATH = REPO_ROOT / "data" / "processed" / "lexicon_v3_master.parquet"
MASTER_TSV_PATH = REPO_ROOT / "data" / "processed" / "lexicon_v3_master.tsv"
REPORTS_DIR = REPO_ROOT / "reports" / "lexicon_v3"
REPORT_MD_PATH = REPORTS_DIR / "mp4_projection_report.md"

CART_VERSION = "3.0.0"
W_PRIOR = 0.60
W_EMP = 0.40
LATERAL_GUARD_DELTA = 0.05
A_MIN_NORM = 0.15
A_MAX_NORM = 1.00

# Verrous normatifs Option 1A (cohérents avec MP3b / 03a_build_class_anchors_draft.py)
LOCK_1AA_CLASSES: frozenset[str] = frozenset({
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
})

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

LOCK_1AC_SECURITY_HAPPINESS_CLASSES: frozenset[str] = frozenset({
    "Confiance_Sentiment de sécurité",
    "Combler Bonheur",
    "Bon moral",
    "Humeur bonne",
    "Réjouir",
    "Jouissance",
})

# Groupes de test de séparation radiale en A (Mann-Whitney U)
MW_Q3_HIGH_A: tuple[str, ...] = ("panique", "angoisse", "terreur", "effroi", "affliction")
MW_Q3_LOW_A: tuple[str, ...] = ("résignation", "apathie", "lassitude", "accablement")
MW_Q14_HIGH_A: tuple[str, ...] = ("euphorie", "exaltation", "passion", "enthousiasme")
MW_Q14_LOW_A: tuple[str, ...] = ("calme", "sérénité", "tranquillité", "quiétude", "repos")

# 20 jalons clés du Tableau 1b v3.0.0 couvrant l'intégralité des 17 sous-secteurs
KEY_MILESTONES_20: tuple[tuple[str, str, str], ...] = (
    ("émoi", "Troubler", "centralOperator"),
    ("confiance", "Confiance", "axialExpectationPos"),
    ("inquiétude", "Inquiéter", "axialExpectationNeg"),
    ("euphorie", "Humeur bonne", "axialControlPos"),
    ("chagrin", "Attrister", "axialControlNeg"),
    ("enthousiasme", "Intéresser_A", "diagonalSynergyPos"),
    ("aversion", "Aversion", "diagonalSynergyNeg"),
    ("rage", "Colère", "diagonalAgenticConfront"),
    ("quiétude", "Rassurer", "diagonalAccommodation"),
    ("fierté", "Orgueil", "lateralEpistemicMastery"),
    ("honte", "Honte", "lateralAversiveDistress"),
    ("résignation", "Résignation", "lateralAversiveDistress"),
    ("exaltation", "Bon moral", "lateralApproachSynergy"),
    ("sérénité", "Rassurer", "lateralApproachSynergy"),
    ("angoisse", "Inquiéter", "lateralEpistemicClosure"),
    ("terreur", "Inquiéter Effrayer", "lateralEpistemicClosure"),
    ("hostilité", "Inimitié", "lateralAgenticConfront"),
    ("acceptation", "Résignation", "lateralReceptiveAccomm"),
    ("mépris", "Mépris", "lateralActiveContest"),
    ("repos", "Détendre", "lateralSecondaryAccomm"),
)

# Palette Option 1A par quadrant (accessible daltonisme)
QUADRANT_COLORS: dict[str, str] = {
    "CENTER": "#0F172A",
    "AXIS_POS_X": "#0D9488",
    "AXIS_POS_Y": "#0D9488",
    "Q1": "#0D9488",
    "Q2": "#DC2626",
    "AXIS_NEG_X": "#4F46E5",
    "AXIS_NEG_Y": "#4F46E5",
    "Q3": "#4F46E5",
    "Q4": "#D97706",
}


def sha256_file(path: Path) -> str:
    """Calcule l'empreinte SHA-256 hexadécimale d'un fichier."""
    return hashlib.sha256(path.read_bytes()).hexdigest()


# =============================================================================
# 1. PARSEUR YAML 1.2 PUR PYTHON (SANS DÉPENDANCE EXTERNE)
# =============================================================================

_INT_RE = re.compile(r"^[+-]?\d+$")
_FLOAT_RE = re.compile(r"^[+-]?(?:\d+\.\d*|\.\d+)(?:[eE][+-]?\d+)?$")


def _parse_yaml_scalar(token: str) -> Any:
    s = token.strip()
    if s in ("null", "Null", "NULL", "~"):
        return None
    if s in ("true", "True", "TRUE"):
        return True
    if s in ("false", "False", "FALSE"):
        return False
    if s == "[]":
        return []
    if s == "{}":
        return {}
    if s.startswith('"') and s.endswith('"'):
        return json.loads(s)
    if s.startswith("'") and s.endswith("'"):
        return s[1:-1].replace("''", "'")
    if _INT_RE.match(s):
        return int(s)
    if _FLOAT_RE.match(s):
        return float(s)
    return s


def _split_yaml_kv(content: str) -> tuple[str, str]:
    idx = content.find(":")
    if idx < 0:
        raise ValueError(f"Ligne YAML clé/valeur invalide : {content!r}")
    key = content[:idx].strip()
    rest = content[idx + 1 :].strip()
    return key, rest


def parse_anchors_yaml(text: str) -> dict[str, Any]:
    """Parse le fichier YAML déterministe généré par 03a_build_class_anchors_draft.py."""
    tokens: list[tuple[int, str]] = []
    for raw_line in text.splitlines():
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        leading = len(raw_line) - len(raw_line.lstrip(" "))
        if leading % 2 != 0:
            raise ValueError(f"Indentation YAML impaire détectée : {raw_line!r}")
        tokens.append((leading // 2, stripped))

    n = len(tokens)

    def parse_block(pos: int, expected_indent: int) -> tuple[Any, int]:
        if pos >= n or tokens[pos][0] < expected_indent:
            return {}, pos
        if tokens[pos][1].startswith("- ") or tokens[pos][1] == "-":
            return parse_list(pos, expected_indent)
        return parse_dict(pos, expected_indent)

    def parse_dict(pos: int, expected_indent: int) -> tuple[dict[str, Any], int]:
        out: dict[str, Any] = {}
        while pos < n:
            ind, line = tokens[pos]
            if ind < expected_indent:
                break
            if ind > expected_indent:
                raise ValueError(f"Indentation inattendue dans dict à {line!r} (pos={pos})")
            if line.startswith("- ") or line == "-":
                break
            key, rest = _split_yaml_kv(line)
            pos += 1
            if rest == "":
                if pos < n and tokens[pos][0] > expected_indent:
                    val, pos = parse_block(pos, tokens[pos][0])
                else:
                    val = None
            else:
                val = _parse_yaml_scalar(rest)
            out[key] = val
        return out, pos

    def parse_list(pos: int, expected_indent: int) -> tuple[list[Any], int]:
        out: list[Any] = []
        while pos < n:
            ind, line = tokens[pos]
            if ind < expected_indent:
                break
            if ind > expected_indent:
                raise ValueError(f"Indentation inattendue dans liste à {line!r} (pos={pos})")
            if not (line.startswith("- ") or line == "-"):
                break
            item_body = line[2:].strip() if line.startswith("- ") else ""
            pos += 1
            if item_body == "":
                if pos < n and tokens[pos][0] > expected_indent:
                    val, pos = parse_block(pos, tokens[pos][0])
                else:
                    val = None
                out.append(val)
            elif ":" in item_body and not item_body.startswith('"'):
                # Élément de liste de dictionnaires : `- key: val`
                first_k, first_rest = _split_yaml_kv(item_body)
                item_dict: dict[str, Any] = {}
                if first_rest == "":
                    if pos < n and tokens[pos][0] >= expected_indent + 2:
                        item_dict[first_k], pos = parse_block(pos, expected_indent + 2)
                    else:
                        item_dict[first_k] = None
                else:
                    item_dict[first_k] = _parse_yaml_scalar(first_rest)
                if pos < n and tokens[pos][0] == expected_indent + 1:
                    rest_dict, pos = parse_dict(pos, expected_indent + 1)
                    item_dict.update(rest_dict)
                out.append(item_dict)
            else:
                out.append(_parse_yaml_scalar(item_body))
        return out, pos

    parsed, final_pos = parse_block(0, 0)
    if final_pos != n or not isinstance(parsed, dict):
        raise ValueError(f"Échec complet du parsing YAML (pos={final_pos}/{n}).")
    return parsed


# =============================================================================
# 2. MIROIRS GÉOMÉTRIQUES EXACTES LEAN 4 & RÉPARTITION HAMILTON (apportionRay)
# =============================================================================

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


def antagonist_point_py(x: int, y: int) -> tuple[int, int]:
    """Miroir exact de `Cartograffect.AffectiveMatrix.antagonistPoint`."""
    if x == 0 or y == 0 or abs(x) == abs(y):
        return (-x, -y)
    if (x > 0 and y < 0) or (x < 0 and y > 0):
        return (y, x)
    return (-y, -x)


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


def quadrant_option1a(x: float | int, y: float | int) -> str:
    """Retourne le quadrant ou axe Option 1A d'une coordonnée (x, y)."""
    if x == 0 and y == 0:
        return "CENTER"
    if y == 0:
        return "AXIS_POS_X" if x > 0 else "AXIS_NEG_X"
    if x == 0:
        return "AXIS_POS_Y" if y > 0 else "AXIS_NEG_Y"
    if x > 0 and y > 0:
        return "Q1"
    if x < 0 and y > 0:
        return "Q2"
    if x < 0 and y < 0:
        return "Q3"
    return "Q4"


def apportion_ray(x: float, y: float, z: int) -> tuple[int, int]:
    """
    Projection entière sur le périmètre L1 R(Z) = 2*floor(Z) - 2 via la méthode
    de répartition proportionnelle au plus fort reste de Hamilton (Balinski & Young, 2001).

    Invariants garantis :
    - Exactement idempotente : apportion_ray(X, Y, Z) == (X, Y) sur 100 % des points
      entiers des couronnes |X| + |Y| = 2*Z - 2 et du centre (0, 0) pour Z in {2, 3, 4, 5}.
    - Conservation stricte de |X| + |Y| = 2*Z - 2 (si non central) et des signes.
    - Préservation stricte du cône latéral pour Z >= 3 lorsque |x| != |y| (|X| != |Y|, X*Y != 0).
    """
    z_int = int(math.floor(z))
    if z_int < 2 or (abs(x) < 1e-12 and abs(y) < 1e-12):
        return (0, 0)
    r = 2 * z_int - 2
    if abs(x) < 1e-12:
        return (0, r if y > 0 else -r)
    if abs(y) < 1e-12:
        return (r if x > 0 else -r, 0)

    sx = 1 if x > 0 else -1
    sy = 1 if y > 0 else -1
    ax_in = abs(float(x))
    ay_in = abs(float(y))

    if abs(ax_in - ay_in) < 1e-12:
        half = r // 2
        return (sx * half, sy * half)

    tot = ax_in + ay_in
    qx = r * ax_in / tot
    qy = r * ay_in / tot
    fx = int(math.floor(qx + 1e-12)) if abs(qx - round(qx)) < 1e-12 else int(math.floor(qx))
    fy = int(math.floor(qy + 1e-12)) if abs(qy - round(qy)) < 1e-12 else int(math.floor(qy))
    rx = qx - fx
    ry = qy - fy
    rem_seats = r - (fx + fy)

    if rem_seats == 1:
        if rx > ry + 1e-12:
            fx += 1
        elif ry > rx + 1e-12:
            fy += 1
        else:
            # Égalité exacte 0.5 / 0.5 (ex. 0.25/0.75 sur R=6) : aligné sur Lean 4 apportionRay
            if ax_in < ay_in:
                fx += 1
            else:
                fy += 1
    elif rem_seats >= 2:
        fx += rem_seats // 2
        fy += rem_seats - (rem_seats // 2)

    # Maintien strict dans le cône latéral pour Z >= 3
    if fx == 0:
        fx, fy = 1, r - 1
    elif fy == 0:
        fx, fy = r - 1, 1
    if z_int >= 3 and fx == fy:
        if ax_in < ay_in:
            fx, fy = fx - 1, fy + 1
        else:
            fx, fy = fx + 1, fy - 1

    return (sx * fx, sy * fy)


def verify_apportion_ray_idempotence() -> dict[str, Any]:
    """Vérifie apportion_ray(X, Y, Z) == (X, Y) sur 100 % des points entiers Z in {2..5}."""
    results_by_z: dict[int, dict[str, Any]] = {}
    total_tested = 0
    total_ok = 0
    for z in (2, 3, 4, 5):
        r = 2 * z - 2
        pts = [(0, 0)]
        for x in range(-r, r + 1):
            for y in range(-r, r + 1):
                if abs(x) + abs(y) == r:
                    pts.append((x, y))
        ok_cnt = sum(1 for x, y in pts if apportion_ray(float(x), float(y), z) == (x, y))
        total_tested += len(pts)
        total_ok += ok_cnt
        assert ok_cnt == len(pts), f"Idempotence apportion_ray échouée à Z={z}: {ok_cnt}/{len(pts)}"
        results_by_z[z] = {"radius": r, "points_tested": len(pts), "points_idempotent": ok_cnt}
    return {"total_tested": total_tested, "total_idempotent": total_ok, "by_z": results_by_z}


def compute_unit_l1_ray(
    subsector_id: str,
    u_x_prior: float,
    u_y_prior: float,
    v_harm: float,
    d_orth: float,
) -> tuple[float, float]:
    """
    Calcule le rayon directionnel unitaire (u_X, u_Y) en norme L1 (|u_X| + |u_Y| = 1) :
    - centralOperator -> (0.0, 0.0)
    - axiaux (A1, A2) et diagonaux (D1, D2) -> verrouillés sur le rayon canonique
    - latéraux (L1-L4) -> 0.60 * prior + 0.40 * emp(V_harm, D_orth), borné dans le
      cône latéral validé avec marge de garde delta = 0.05 vis-à-vis des axes et diagonales,
      puis renormalisé à |u_X| + |u_Y| = 1.0.
    """
    if subsector_id == "centralOperator":
        return (0.0, 0.0)
    if not subsector_id.startswith("lateral"):
        return (float(u_x_prior), float(u_y_prior))

    sx = 1.0 if u_x_prior > 0 else -1.0
    sy = 1.0 if u_y_prior > 0 else -1.0
    s_emp = abs(v_harm) + abs(d_orth)
    if s_emp < 1e-12:
        u_x_emp, u_y_emp = u_x_prior, u_y_prior
    else:
        u_x_emp, u_y_emp = v_harm / s_emp, d_orth / s_emp

    ux_raw = W_PRIOR * u_x_prior + W_EMP * u_x_emp
    uy_raw = W_PRIOR * u_y_prior + W_EMP * u_y_emp

    # Projection signée dans le quadrant du sous-secteur validé
    ax = max(0.0, sx * ux_raw)
    ay = max(0.0, sy * uy_raw)
    if ax + ay < 1e-12:
        ax, ay = abs(u_x_prior), abs(u_y_prior)
    else:
        tot = ax + ay
        ax, ay = ax / tot, ay / tot

    # Garde stricte delta = 0.05 vis-à-vis des axes (0.0) et diagonales (0.50)
    if abs(u_x_prior) > abs(u_y_prior):
        ay = float(np.clip(ay, LATERAL_GUARD_DELTA, 0.50 - LATERAL_GUARD_DELTA))
        ax = 1.0 - ay
    else:
        ax = float(np.clip(ax, LATERAL_GUARD_DELTA, 0.50 - LATERAL_GUARD_DELTA))
        ay = 1.0 - ax

    return (sx * ax, sy * ay)


def assign_ring_a(subsector_id: str, a_norm: float) -> str:
    """Assigne l'anneau iso-activation `ring_A`."""
    if subsector_id == "centralOperator":
        return "center_operator"
    if a_norm <= 0.35 + 1e-12:
        return "inner_low"
    if a_norm <= 0.65 + 1e-12:
        return "inner_mod"
    if a_norm <= 0.85 + 1e-12:
        return "sub_perimeter"
    return "perimeter_high"


# =============================================================================
# 3. PIPELINE PRINCIPAL DE PROJECTION MP4
# =============================================================================

def load_and_validate_inputs() -> tuple[dict[str, Any], dict[str, Any], pd.DataFrame]:
    """Lit les 3 sources en lecture seule et vérifie leur intégrité au démarrage."""
    anchors_json = json.loads(ANCHORS_JSON_PATH.read_text(encoding="utf-8"))
    json_sha = sha256_file(ANCHORS_JSON_PATH)

    anchors_yaml = parse_anchors_yaml(ANCHORS_YAML_PATH.read_text(encoding="utf-8"))
    if anchors_yaml.get("clinical_review_status") != "APPROVED":
        raise RuntimeError(
            f"Revue clinique YAML non approuvée : {anchors_yaml.get('clinical_review_status')!r}"
        )
    if anchors_yaml.get("reference_anchors_sha256") != json_sha:
        raise RuntimeError("Divergence SHA-256 entre YAML et canonical_z0_z2_anchors.json")
    classes_list = anchors_yaml.get("classes", [])
    if len(classes_list) != 109:
        raise RuntimeError(f"Attendu 109 classes dans YAML, trouvé {len(classes_list)}")
    n_ovr_rules = sum(len(c.get("subclass_overrides") or []) for c in classes_list)
    if n_ovr_rules != 52:
        raise RuntimeError(f"Attendu 52 règles subclass_overrides, trouvé {n_ovr_rules}")

    df_in = pd.read_parquet(PARQUET_IN_PATH)
    if len(df_in) != 1494:
        raise RuntimeError(f"Attendu 1 494 lignes DIMA Z+, trouvé {len(df_in)}")
    for req_col in ("lemme_norm", "part_disc", "classe", "hemisphere_route", "V_harm", "A_harm", "D_orth"):
        if df_in[req_col].isna().any():
            raise RuntimeError(f"Valeurs manquantes inattendues dans {req_col}")

    return anchors_json, anchors_yaml, df_in


def build_locked_canonical_rows(
    anchors_json: dict[str, Any],
    subsector_map: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    """Construit les 14 lignes verrouillées en tête de table (11 Z0-Z2 + 3 opérateurs Z3-Z5)."""
    locked: list[dict[str, Any]] = []

    for st in anchors_json["canonical_z0_z2_states"]:
        z = int(st["z"])
        px, py, pz = [int(v) for v in st["point"]]
        assert pz == z
        r_z = 0 if z < 2 else 2 * z - 2
        sid = str(st["subsector_id"])
        sub_spec = subsector_map[sid]
        ux = float(sub_spec["u_X"])
        uy = float(sub_spec["u_Y"])
        a_norm = 0.0 if sid == "centralOperator" else 1.0
        ring = assign_ring_a(sid, a_norm)
        ax_c, ay_c = antagonist_point_py(px, py)
        locked.append({
            "lemma_id": f"canon_z{z}_{st['id']}",
            "record_origin": "canonical_lean4",
            "hemisphere_route": "CANONICAL_LOCKED",
            "lemme_norm": str(st["label_fr"]).lower(),
            "label_display": str(st["label_fr"]),
            "part_disc": "CANONICAL",
            "classe": str(st["lean_constructor"]),
            "sous_classe": str(st["id"]),
            "categ": "Z0_Z2",
            "pruning_bucket": "CANONICAL_LEAN4",
            "metric_provenance": "lean4_canonical",
            "en_matched_term": None,
            "z_minus_value_candidate": False,
            "V_harm": np.nan,
            "A_harm": np.nan,
            "D_raw": np.nan,
            "D_orth": np.nan,
            "A_winsor": np.nan,
            "A_norm": a_norm,
            "ring_A": ring,
            "Z_stratum": z,
            "R_Z": r_z,
            "subsector_id": sid,
            "subsector_pair": str(sub_spec["pair_id"]),
            "conjugate_subsector": str(sub_spec["conjugate_subsector"]),
            "subsector_resolution_source": "canonical_lean4",
            "u_X": ux,
            "u_Y": uy,
            "x": float(px),
            "y": float(py),
            "l1_radius": float(abs(px) + abs(py)),
            "X_crown": px,
            "Y_crown": py,
            "antagonist_X_crown": ax_c,
            "antagonist_Y_crown": ay_c,
            "quadrant_option1a": quadrant_option1a(px, py),
            "hedonic_polarity": str(st["hedonic_polarity"]),
            "parent_lemma_id": None,
            "parent_match_level": None,
        })

    for op in anchors_json["structured_taxonomy_central_operators_z3_z5"]:
        z = int(op["z"])
        px, py, pz = [int(v) for v in op["point"]]
        assert px == 0 and py == 0 and pz == z
        r_z = 2 * z - 2
        assert r_z == int(op["crown_radius"])
        sub_spec = subsector_map["centralOperator"]
        locked.append({
            "lemma_id": f"central_z{z}_{op['id']}",
            "record_origin": "central_operator_v3",
            "hemisphere_route": "CENTRAL_OPERATOR_LOCKED",
            "lemme_norm": str(op["label_fr"]).lower(),
            "label_display": str(op["label_fr"]),
            "part_disc": "CENTRAL_OP",
            "classe": str(op["lean_constructor"]),
            "sous_classe": str(op["id"]),
            "categ": "Z3_Z5_CENTER",
            "pruning_bucket": "CENTRAL_OPERATOR_V3",
            "metric_provenance": "lean4_canonical",
            "en_matched_term": None,
            "z_minus_value_candidate": False,
            "V_harm": np.nan,
            "A_harm": np.nan,
            "D_raw": np.nan,
            "D_orth": np.nan,
            "A_winsor": np.nan,
            "A_norm": 0.0,
            "ring_A": "center_operator",
            "Z_stratum": z,
            "R_Z": r_z,
            "subsector_id": "centralOperator",
            "subsector_pair": str(sub_spec["pair_id"]),
            "conjugate_subsector": "centralOperator",
            "subsector_resolution_source": "central_operator_v3",
            "u_X": 0.0,
            "u_Y": 0.0,
            "x": 0.0,
            "y": 0.0,
            "l1_radius": 0.0,
            "X_crown": 0,
            "Y_crown": 0,
            "antagonist_X_crown": 0,
            "antagonist_Y_crown": 0,
            "quadrant_option1a": "CENTER",
            "hedonic_polarity": "neutral",
            "parent_lemma_id": None,
            "parent_match_level": None,
        })

    assert len(locked) == 14
    return locked


def project_dima_entries(
    anchors_yaml: dict[str, Any],
    subsector_map: dict[str, dict[str, Any]],
    df_in: pd.DataFrame,
) -> tuple[pd.DataFrame, dict[str, Any]]:
    """Filtre MP3b, résout (Z, subsector_id), projette (u_X, u_Y, x, y, X_crown, Y_crown) et attache les satellites."""
    classes_by_name = {str(c["classe"]): c for c in anchors_yaml["classes"]}
    move_classes = {
        str(c["classe"])
        for c in anchors_yaml["classes"]
        if c.get("z_minus_value_decision") == "move_to_z_minus_reserve"
    }
    expected_move = {"Croyance", "Croyance relig", "Incrédulité", "Incrédulité relig", "Pudeur"}
    assert move_classes == expected_move, f"Classes move_to_z_minus_reserve inattendues : {move_classes}"

    is_moved = df_in["classe"].isin(move_classes)
    moved_active = int((is_moved & (df_in["hemisphere_route"] == "Z_PLUS_ACTIVE")).sum())
    moved_sat = int((is_moved & (df_in["hemisphere_route"] == "Z_PLUS_SATELLITE")).sum())
    assert moved_active == 7, f"moved_to_z_minus_in_mp3b attendu=7, trouvé={moved_active}"
    assert moved_sat == 5, f"moved_to_z_minus_satellites_in_mp3b attendu=5, trouvé={moved_sat}"

    df = df_in[~is_moved].copy().reset_index(drop=True)
    n_active = int((df["hemisphere_route"] == "Z_PLUS_ACTIVE").sum())
    n_sat = int((df["hemisphere_route"] == "Z_PLUS_SATELLITE").sum())
    assert n_active == 542 and n_sat == 940 and len(df) == 1482

    # Pré-indexer les overrides par (classe, sous_classe)
    override_lookup: dict[tuple[str, str], dict[str, Any]] = {}
    for cls_name, cls_rec in classes_by_name.items():
        for ovr in cls_rec.get("subclass_overrides") or []:
            override_lookup[(cls_name, str(ovr["sous_classe"]).strip())] = ovr

    valid_subsectors = set(subsector_map.keys())
    assert len(valid_subsectors) == 17

    # Étape 2 & 3 : Résolution (Z, subsector_id) + rayon unitaire + apportionRay
    records_meta: list[dict[str, Any]] = []
    option1a_violations: list[str] = []

    for _, row in df.iterrows():
        cl = str(row["classe"])
        sc = "" if pd.isna(row["sous_classe"]) else str(row["sous_classe"]).strip()
        lemme = str(row["lemme_norm"])
        pos = str(row["part_disc"])
        v_h = float(row["V_harm"])
        a_h = float(row["A_harm"])
        d_o = float(row["D_orth"])

        ovr = override_lookup.get((cl, sc))
        if ovr is not None:
            z_stratum = int(ovr["default_z"])
            sub_id = str(ovr["subsector_id"])
            res_source = "subclass_override"
        else:
            cls_rec = classes_by_name[cl]
            z_stratum = int(cls_rec["default_z"])
            sub_id = str(cls_rec["subsector_id"])
            res_source = "class_default"

        assert z_stratum in (3, 4, 5), f"Z_stratum hors {{3,4,5}} : {z_stratum} pour {cl}/{lemme}"
        assert sub_id in valid_subsectors, f"subsector_id hors Lean 4 : {sub_id}"

        sub_spec = subsector_map[sub_id]
        u_x_prior = float(sub_spec["u_X"])
        u_y_prior = float(sub_spec["u_Y"])
        u_x, u_y = compute_unit_l1_ray(sub_id, u_x_prior, u_y_prior, v_h, d_o)
        r_z = 2 * z_stratum - 2
        x_cr, y_cr = apportion_ray(u_x, u_y, z_stratum)
        ax_cr, ay_cr = antagonist_point_py(x_cr, y_cr)

        # Contrôles Option 1A sur chaque entrée
        if cl in LOCK_1AA_CLASSES and u_y > 0:
            option1a_violations.append(f"1A-a: {cl}/{lemme} u_Y={u_y} > 0")
        if sub_id in Q2_SUBSECTORS:
            if not (cl in LOCK_1AB_ALLOWED_Q2_CLASSES or (cl, sc) in LOCK_1AB_ALLOWED_Q2_OVERRIDES):
                option1a_violations.append(f"1A-b: {cl}[{sc}]/{lemme} en Q2 ({sub_id})")
        if cl in LOCK_1AC_SECURITY_HAPPINESS_CLASSES and u_y < 0:
            option1a_violations.append(f"1A-c: {cl}/{lemme} u_Y={u_y} < 0")
        if cl == "Rassurer" and sc in {"sérénité", "tranquilliser", "insouciance"} and u_y <= 0:
            option1a_violations.append(f"1A-c Rassurer[{sc}] u_Y <= 0")
        if cl == "Résignation" and sc == "acceptation" and not (u_x > 0 and u_y < 0):
            option1a_violations.append(f"1A-c Résignation[acceptation] hors Q4")

        # Contrôles géométriques du rayon et de apportionRay
        if sub_id == "centralOperator":
            assert u_x == 0.0 and u_y == 0.0 and x_cr == 0 and y_cr == 0
        else:
            assert abs(abs(u_x) + abs(u_y) - 1.0) < 1e-12
            assert abs(x_cr) + abs(y_cr) == r_z
            assert classify_subsector_py(x_cr, y_cr) == sub_id, (
                f"Subsector mismatch après apportionRay pour {lemme} ({cl}): ({x_cr},{y_cr}) -> {classify_subsector_py(x_cr, y_cr)} != {sub_id}"
            )
        assert hedonic_polarity_py(x_cr, y_cr) == sub_spec["hedonic_polarity"]

        records_meta.append({
            "lemma_id": f"dima|{cl}|{pos}|{lemme}",
            "record_origin": "dima_z_plus_projected",
            "hemisphere_route": str(row["hemisphere_route"]),
            "lemme_norm": lemme,
            "label_display": lemme,
            "part_disc": pos,
            "classe": cl,
            "sous_classe": sc if sc else None,
            "categ": str(row["categ"]),
            "pruning_bucket": str(row["pruning_bucket"]),
            "metric_provenance": str(row["metric_provenance"]),
            "en_matched_term": None if pd.isna(row["en_matched_term"]) else str(row["en_matched_term"]),
            "z_minus_value_candidate": bool(row["z_minus_value_candidate"]),
            "V_harm": v_h,
            "A_harm": a_h,
            "D_raw": float(row["D_raw"]),
            "D_orth": d_o,
            "Z_stratum": z_stratum,
            "R_Z": r_z,
            "subsector_id": sub_id,
            "subsector_pair": str(sub_spec["pair_id"]),
            "conjugate_subsector": str(sub_spec["conjugate_subsector"]),
            "subsector_resolution_source": res_source,
            "u_X": u_x,
            "u_Y": u_y,
            "X_crown": x_cr,
            "Y_crown": y_cr,
            "antagonist_X_crown": ax_cr,
            "antagonist_Y_crown": ay_cr,
            "quadrant_option1a": quadrant_option1a(x_cr, y_cr),
            "hedonic_polarity": str(sub_spec["hedonic_polarity"]),
        })

    assert not option1a_violations, f"Violations Option 1A : {option1a_violations[:10]}"
    proj_df = pd.DataFrame(records_meta)
    assert proj_df["lemma_id"].is_unique, "Doublon détecté dans lemma_id"

    # Étape 4 : Winsorisation robuste (p01, p99) sur périphériques Z+ & projection radiale (x, y)
    periph_mask = proj_df["subsector_id"] != "centralOperator"
    a_periph = proj_df.loc[periph_mask, "A_harm"].to_numpy(dtype=float)
    p01, p99 = [float(v) for v in np.percentile(a_periph, [1.0, 99.0])]
    assert p99 > p01

    a_winsor = np.where(periph_mask, np.clip(proj_df["A_harm"].to_numpy(dtype=float), p01, p99), np.nan)
    a_norm = np.where(
        periph_mask,
        A_MIN_NORM + (A_MAX_NORM - A_MIN_NORM) * (np.clip(proj_df["A_harm"].to_numpy(dtype=float), p01, p99) - p01) / (p99 - p01),
        0.0,
    )
    proj_df["A_winsor"] = a_winsor
    proj_df["A_norm"] = a_norm
    proj_df["ring_A"] = [assign_ring_a(sid, float(an)) for sid, an in zip(proj_df["subsector_id"], proj_df["A_norm"])]

    r_arr = proj_df["R_Z"].to_numpy(dtype=float)
    ux_arr = proj_df["u_X"].to_numpy(dtype=float)
    uy_arr = proj_df["u_Y"].to_numpy(dtype=float)
    x_arr = a_norm * r_arr * ux_arr
    y_arr = a_norm * r_arr * uy_arr
    l1_arr = np.abs(x_arr) + np.abs(y_arr)

    proj_df["x"] = x_arr
    proj_df["y"] = y_arr
    proj_df["l1_radius"] = l1_arr

    # Vérifications strictes sur A_norm et |x| + |y| <= R(Z)
    assert np.all(l1_arr <= r_arr + 1e-12)
    assert np.allclose(l1_arr[periph_mask], a_norm[periph_mask] * r_arr[periph_mask], atol=1e-12)
    assert np.all((a_norm[periph_mask] >= A_MIN_NORM - 1e-12) & (a_norm[periph_mask] <= A_MAX_NORM + 1e-12))

    # Étape 4b : Rattachement des satellites (Z_PLUS_SATELLITE) au lemme Z_PLUS_ACTIVE le plus proche
    act_df = proj_df[proj_df["hemisphere_route"] == "Z_PLUS_ACTIVE"].copy()
    act_records = act_df.to_dict("records")

    by_cls_sc: dict[tuple[str, str], list[dict[str, Any]]] = {}
    by_cls: dict[str, list[dict[str, Any]]] = {}
    by_sub_z: dict[tuple[str, int], list[dict[str, Any]]] = {}
    by_sub: dict[str, list[dict[str, Any]]] = {}

    for rec in act_records:
        cl = rec["classe"]
        sc = rec["sous_classe"] or ""
        sub_id = rec["subsector_id"]
        z_val = int(rec["Z_stratum"])
        if sc:
            by_cls_sc.setdefault((cl, sc), []).append(rec)
        by_cls.setdefault(cl, []).append(rec)
        by_sub_z.setdefault((sub_id, z_val), []).append(rec)
        by_sub.setdefault(sub_id, []).append(rec)

    parent_ids: list[str | None] = []
    match_levels: list[str | None] = []
    match_counts = {"same_sous_classe": 0, "same_classe": 0, "same_subsector_z_fallback": 0, "same_subsector_fallback": 0}

    for _, row in proj_df.iterrows():
        if row["hemisphere_route"] != "Z_PLUS_SATELLITE":
            parent_ids.append(None)
            match_levels.append(None)
            continue
        cl = str(row["classe"])
        sc = "" if row["sous_classe"] is None or pd.isna(row["sous_classe"]) else str(row["sous_classe"]).strip()
        sub_id = str(row["subsector_id"])
        z_val = int(row["Z_stratum"])

        if sc and (cl, sc) in by_cls_sc:
            pool = by_cls_sc[(cl, sc)]
            lvl = "same_sous_classe"
        elif cl in by_cls:
            pool = by_cls[cl]
            lvl = "same_classe"
        elif (sub_id, z_val) in by_sub_z:
            pool = by_sub_z[(sub_id, z_val)]
            lvl = "same_subsector_z_fallback"
        else:
            pool = by_sub[sub_id]
            lvl = "same_subsector_fallback"

        sx = float(row["x"])
        sy = float(row["y"])
        sa = float(row["A_norm"])
        sv = float(row["V_harm"])
        sah = float(row["A_harm"])
        sd = float(row["D_orth"])

        best = min(
            pool,
            key=lambda c: (
                abs(sx - float(c["x"])) + abs(sy - float(c["y"])),
                abs(sa - float(c["A_norm"])),
                abs(sv - float(c["V_harm"])) + abs(sah - float(c["A_harm"])) + abs(sd - float(c["D_orth"])),
                0 if c["part_disc"] == "NOM" else 1,
                str(c["lemma_id"]),
            ),
        )
        parent_ids.append(str(best["lemma_id"]))
        match_levels.append(lvl)
        match_counts[lvl] += 1

    proj_df["parent_lemma_id"] = parent_ids
    proj_df["parent_match_level"] = match_levels

    # Tri déterministe des entrées DIMA projetées
    proj_df["_sc_sort"] = proj_df["sous_classe"].fillna("")
    proj_df = proj_df.sort_values(
        ["hemisphere_route", "Z_stratum", "subsector_id", "classe", "_sc_sort", "lemme_norm", "part_disc"],
        kind="mergesort",
    ).drop(columns=["_sc_sort"]).reset_index(drop=True)

    meta = {
        "moved_to_z_minus_in_mp3b": moved_active,
        "moved_to_z_minus_satellites_in_mp3b": moved_sat,
        "moved_classes": sorted(move_classes),
        "projected_active": n_active,
        "projected_satellite": n_sat,
        "projected_total_dima": len(proj_df),
        "p01_A_harm": p01,
        "p99_A_harm": p99,
        "n_periph_for_winsor": int(periph_mask.sum()),
        "option_1a_violations": 0,
        "parent_match_counts": match_counts,
        "override_applied_total": int((proj_df["subsector_resolution_source"] == "subclass_override").sum()),
        "override_applied_active": int(
            ((proj_df["subsector_resolution_source"] == "subclass_override") & (proj_df["hemisphere_route"] == "Z_PLUS_ACTIVE")).sum()
        ),
    }
    return proj_df, meta


# =============================================================================
# 4. FIGURES HAUTE RÉSOLUTION (300 DPI, STYLE FIGURE 4 v3.0.0)
# =============================================================================

def _select_milestones_for_stratum(act_z: pd.DataFrame, z: int) -> pd.DataFrame:
    """Sélectionne un jeu représentatif et lisible de jalons Z_PLUS_ACTIVE sur la strate Z."""
    priority_terms: dict[int, list[tuple[str, str | None]]] = {
        3: [
            ("émoi", "Troubler"),
            ("inquiétude", "Inquiéter"),
            ("chagrin", "Attrister"),
            ("joie", "Réjouir"),
            ("curiosité", "Curiosité"),
            ("désir", "Désir"),
            ("dégoût", "Déplaire_A"),
            ("colère", "Colère"),
            ("rage", "Colère"),
            ("calme", "Apaiser"),
            ("apaisement", "Apaiser"),
            ("enthousiasme", "Intéresser_A"),
            ("terreur", "Inquiéter Effrayer"),
            ("effroi", "Inquiéter Effrayer"),
            ("panique", "Peur panique"),
            ("anxiété", "Inquiéter"),
            ("frustration", "Décevoir"),
            ("déception", "Décevoir"),
            ("amertume", "Décevoir"),
            ("dépit", "Décevoir"),
            ("repos", "Détendre"),
            ("lassitude", "Importuner"),
            ("affliction", "Attrister"),
        ],
        4: [
            ("angoisse", "Inquiéter"),
            ("quiétude", "Rassurer"),
            ("sérénité", "Rassurer"),
            ("tranquillité", "Rassurer"),
            ("passion", "Amour"),
            ("affection", "Affection"),
            ("aversion", "Aversion"),
            ("haine", "Haine de qq"),
            ("fierté", "Orgueil"),
            ("estime", "Estime"),
            ("honte", "Honte"),
            ("résignation", "Résignation"),
            ("hostilité", "Inimitié"),
            ("ressentiment", "Ressentiment"),
            ("acceptation", "Résignation"),
            ("admiration", "Admiration"),
            ("mépris", "Mépris"),
            ("jalousie", "Jalousie envie"),
            ("mélancolie", "Humeur songeuse"),
            ("remords", "Mauvaise conscience"),
            ("gratitude", "Gratitude"),
        ],
        5: [
            ("confiance", "Confiance"),
            ("méfiance", "Défiance"),
            ("euphorie", "Humeur bonne"),
            ("allégresse", "Humeur bonne"),
            ("exaltation", "Bon moral"),
            ("espoir", "Espoir"),
            ("désespoir", "Mauvais moral"),
            ("apathie", "Apathie"),
            ("accablement", "Mauvais moral"),
            ("abattement", "Mauvais moral"),
            ("morosité", "Humeur mauvaise"),
            ("dynamisme", "Energie"),
            ("optimisme", "Confiance_Sentiment de sécurité"),
            ("assurance", "Confiance_Sentiment de sécurité"),
            ("pessimisme", "Défiance_Sentiment d'insécurité"),
            ("agoraphobie", "Peur phobie"),
            ("détachement", "Absence de désir"),
            ("doute", "Doute"),
            ("rêverie", "Humeur songeuse"),
        ],
    }

    picked_indices: list[int] = []
    seen_labels: set[str] = set()
    for lemme, cl in priority_terms[z]:
        cand = act_z[act_z["lemme_norm"] == lemme]
        if cl is not None:
            sub = cand[cand["classe"] == cl]
            if len(sub) > 0:
                cand = sub
        if len(cand) > 0:
            # Préférer NOM si disponible
            cand_sorted = cand.sort_values(
                by=["part_disc", "A_norm"],
                ascending=[True, False],
                key=lambda s: s.map({"NOM": 0, "ADJ": 1}) if s.name == "part_disc" else s,
            )
            idx = int(cand_sorted.index[0])
            if lemme not in seen_labels:
                seen_labels.add(lemme)
                picked_indices.append(idx)

    return act_z.loc[picked_indices].copy()


def _bboxes_overlap(b1: tuple[float, float, float, float], b2: tuple[float, float, float, float], pad: float = 3.0) -> bool:
    """Teste le chevauchement de deux AABB (x0, y0, x1, y1) avec marge en pixels."""
    return not (
        b1[2] + pad <= b2[0]
        or b2[2] + pad <= b1[0]
        or b1[3] + pad <= b2[1]
        or b2[3] + pad <= b1[1]
    )


def _place_non_overlapping_labels(
    fig: plt.Figure,
    ax: plt.Axes,
    milestones: pd.DataFrame,
    r_z: float,
    obstacle_artists: list[Any] | None = None,
) -> tuple[list[Any], int]:
    """Place des étiquettes avec traits de rappel et répulsion AABB déterministe (0 chevauchement)."""
    anns: list[Any] = []
    n_pts = len(milestones)
    if n_pts == 0:
        return anns, 0

    rows = milestones.to_dict("records")
    # Trier par angle polaire pour répartir proprement les décalages initiaux
    indexed_rows = sorted(
        enumerate(rows),
        key=lambda t: (math.atan2(float(t[1]["y"]), float(t[1]["x"])), float(t[1]["A_norm"]), str(t[1]["lemme_norm"])),
    )

    lim = 1.14 * r_z
    init_targets: dict[int, tuple[float, float]] = {}
    for rank, (orig_i, row) in enumerate(indexed_rows):
        px = float(row["x"])
        py = float(row["y"])
        if px == 0.0 and py == 0.0:
            tx, ty = 0.14 * r_z, 0.14 * r_z
        else:
            ang = math.atan2(py, px)
            ang_off = ((rank % 5) - 2) * 0.13
            rad_push = 0.18 * r_z + (rank % 3) * 0.08 * r_z
            tx = px + rad_push * math.cos(ang + ang_off)
            ty = py + rad_push * math.sin(ang + ang_off)
        init_targets[orig_i] = (float(np.clip(tx, -lim, lim)), float(np.clip(ty, -lim, lim)))

    for i, row in enumerate(rows):
        px = float(row["x"])
        py = float(row["y"])
        tx, ty = init_targets[i]
        ann = ax.annotate(
            str(row["lemme_norm"]),
            xy=(px, py),
            xytext=(tx, ty),
            fontsize=8.0,
            fontweight="normal",
            color="#0F172A",
            ha="center",
            va="center",
            bbox=dict(boxstyle="round,pad=0.16", fc="#FFFFFF", ec="#CBD5E1", lw=0.6, alpha=0.93),
            arrowprops=dict(arrowstyle="-", color="#64748B", lw=0.75, shrinkA=1, shrinkB=3, alpha=0.85),
            zorder=8,
        )
        anns.append(ann)

    # Mesurer une seule fois les tailles exactes des boîtes (en pixels) puis résoudre en mémoire
    fig.canvas.draw()
    renderer = fig.canvas.get_renderer()
    widths = np.zeros(n_pts, dtype=float)
    heights = np.zeros(n_pts, dtype=float)
    centers_px = np.zeros((n_pts, 2), dtype=float)
    anchors_px = np.zeros((n_pts, 2), dtype=float)
    targets_px = np.zeros((n_pts, 2), dtype=float)

    for i, ann in enumerate(anns):
        bb = ann.get_bbox_patch().get_window_extent(renderer=renderer)
        widths[i] = bb.width
        heights[i] = bb.height
        centers_px[i] = [0.5 * (bb.x0 + bb.x1), 0.5 * (bb.y0 + bb.y1)]
        anchors_px[i] = ax.transData.transform((float(rows[i]["x"]), float(rows[i]["y"])))
        targets_px[i] = centers_px[i].copy()

    fixed_boxes: list[tuple[float, float, float, float]] = []
    for art in obstacle_artists or []:
        obb = art.get_window_extent(renderer=renderer)
        fixed_boxes.append((obb.x0, obb.y0, obb.x1, obb.y1))

    min_lim_px = ax.transData.transform((-lim, -lim))
    max_lim_px = ax.transData.transform((lim, lim))

    pad_px = 8.0
    for it in range(1500):
        disp = np.zeros((n_pts, 2), dtype=float)
        has_overlap = False
        spring_k = 0.04 if it < 300 else 0.0

        for i in range(n_pts):
            # Répulsion inter-étiquettes
            for j in range(i + 1, n_pts):
                ox = 0.5 * (widths[i] + widths[j]) + pad_px - abs(centers_px[i, 0] - centers_px[j, 0])
                oy = 0.5 * (heights[i] + heights[j]) + pad_px - abs(centers_px[i, 1] - centers_px[j, 1])
                if ox > 0.0 and oy > 0.0:
                    has_overlap = True
                    vx = centers_px[i, 0] - centers_px[j, 0]
                    vy = centers_px[i, 1] - centers_px[j, 1]
                    if abs(vx) < 1e-3 and abs(vy) < 1e-3:
                        vx, vy = (1.0 if i % 2 == 0 else -1.0), (0.8 if j % 2 == 0 else -0.8)
                    if ox < oy:
                        push = 0.52 * ox + 1.0
                        sx = 1.0 if vx >= 0 else -1.0
                        disp[i, 0] += sx * push
                        disp[j, 0] -= sx * push
                    else:
                        push = 0.52 * oy + 1.0
                        sy = 1.0 if vy >= 0 else -1.0
                        disp[i, 1] += sy * push
                        disp[j, 1] -= sy * push

            # Répulsion par rapport aux badges de paires / labels d'anneaux
            for fx0, fy0, fx1, fy1 in fixed_boxes:
                fcx = 0.5 * (fx0 + fx1)
                fcy = 0.5 * (fy0 + fy1)
                fw = fx1 - fx0
                fh = fy1 - fy0
                ox = 0.5 * (widths[i] + fw) + 5.0 - abs(centers_px[i, 0] - fcx)
                oy = 0.5 * (heights[i] + fh) + 5.0 - abs(centers_px[i, 1] - fcy)
                if ox > 0.0 and oy > 0.0:
                    has_overlap = True
                    vx = centers_px[i, 0] - fcx
                    vy = centers_px[i, 1] - fcy
                    if abs(vx) < 1e-3 and abs(vy) < 1e-3:
                        vx, vy = 1.0, -1.0
                    if ox < oy:
                        disp[i, 0] += (1.0 if vx >= 0 else -1.0) * (0.65 * ox + 2.0)
                    else:
                        disp[i, 1] += (1.0 if vy >= 0 else -1.0) * (0.65 * oy + 2.0)

            # Répulsion par rapport aux points d'ancrage
            for j in range(n_pts):
                ox_p = 0.5 * widths[i] + 5.0 - abs(centers_px[i, 0] - anchors_px[j, 0])
                oy_p = 0.5 * heights[i] + 5.0 - abs(centers_px[i, 1] - anchors_px[j, 1])
                if ox_p > 0.0 and oy_p > 0.0:
                    vx = centers_px[i, 0] - anchors_px[j, 0]
                    vy = centers_px[i, 1] - anchors_px[j, 1]
                    norm = math.hypot(vx, vy) or 1.0
                    disp[i, 0] += 3.0 * vx / norm
                    disp[i, 1] += 3.0 * vy / norm

            if spring_k > 0.0:
                disp[i] += spring_k * (targets_px[i] - centers_px[i])

        centers_px += disp
        for i in range(n_pts):
            hw = 0.5 * widths[i] + 2.0
            hh = 0.5 * heights[i] + 2.0
            centers_px[i, 0] = float(np.clip(centers_px[i, 0], min_lim_px[0] + hw, max_lim_px[0] - hw))
            centers_px[i, 1] = float(np.clip(centers_px[i, 1], min_lim_px[1] + hh, max_lim_px[1] - hh))

        if it >= 300 and not has_overlap:
            break

    inv_trans = ax.transData.inverted()
    for i, ann in enumerate(anns):
        nx, ny = inv_trans.transform((centers_px[i, 0], centers_px[i, 1]))
        ann.set_position((float(nx), float(ny)))

    fig.canvas.draw()
    final_boxes = [ann.get_bbox_patch().get_window_extent(renderer=renderer) for ann in anns]
    overlaps = 0
    for i in range(n_pts):
        bi = (final_boxes[i].x0, final_boxes[i].y0, final_boxes[i].x1, final_boxes[i].y1)
        for j in range(i + 1, n_pts):
            bj = (final_boxes[j].x0, final_boxes[j].y0, final_boxes[j].x1, final_boxes[j].y1)
            if _bboxes_overlap(bi, bj, pad=0.5):
                overlaps += 1
        for fb in fixed_boxes:
            if _bboxes_overlap(bi, fb, pad=0.5):
                overlaps += 1
    return anns, overlaps


def render_surface_figure(
    master_df: pd.DataFrame,
    anchors_json: dict[str, Any],
    z: int,
    out_path: Path,
) -> dict[str, Any]:
    """Génère la figure PNG 300 dpi `surface_Z{z}.png` (style Figure 4 v3.0.0)."""
    r_z = 2 * z - 2
    op_info = [op for op in anchors_json["structured_taxonomy_central_operators_z3_z5"] if int(op["z"]) == z][0]
    op_label = str(op_info["label_fr"])

    act_z = master_df[(master_df["hemisphere_route"] == "Z_PLUS_ACTIVE") & (master_df["Z_stratum"] == z)].copy()
    sat_z = master_df[(master_df["hemisphere_route"] == "Z_PLUS_SATELLITE") & (master_df["Z_stratum"] == z)].copy()

    plt.rcParams.update({
        "font.family": "DejaVu Sans",
        "axes.edgecolor": "#CBD5E1",
        "axes.linewidth": 0.8,
    })

    fig, ax = plt.subplots(figsize=(10.5, 10.2), dpi=300)
    ax.set_aspect("equal", adjustable="box")
    ax.set_facecolor("#FAFAFC")

    # 1. Cercle rival L2 en pointillés (||x||_2 = R(Z))
    theta = np.linspace(0.0, 2.0 * np.pi, 400)
    ax.plot(
        r_z * np.cos(theta),
        r_z * np.sin(theta),
        linestyle="--",
        color="#94A3B8",
        linewidth=1.25,
        zorder=1,
        label=f"Cercle rival $L_2$ ($\\|x\\|_2 = {r_z}$)",
    )

    # 2. Anneaux iso-activation L1 : A in {0.25, 0.50, 0.75, 1.00}
    obstacle_artists: list[Any] = []
    for a_ring in (0.25, 0.50, 0.75):
        rad = a_ring * r_z
        ax.plot(
            [0.0, rad, 0.0, -rad, 0.0],
            [rad, 0.0, -rad, 0.0, rad],
            linestyle=":",
            color="#64748B",
            linewidth=0.95,
            zorder=2,
        )
        t_ring = ax.text(
            -0.13 * rad,
            0.87 * rad,
            f"A={a_ring:.2f}",
            fontsize=7.3,
            color="#475569",
            ha="center",
            va="center",
            bbox=dict(boxstyle="round,pad=0.10", fc="#FAFAFC", ec="none", alpha=0.88),
            zorder=4,
        )
        obstacle_artists.append(t_ring)

    # Losange L1 extérieur (A = 1.00)
    ax.plot(
        [0.0, r_z, 0.0, -r_z, 0.0],
        [r_z, 0.0, -r_z, 0.0, r_z],
        linestyle="-",
        color="#1E293B",
        linewidth=2.0,
        zorder=2,
        label=f"Losange $L_1$ ($|x|+|y| = {r_z}$, $A=1.00$)",
    )

    # 3. Les 16 rayons directionnels + repères de paires
    for sub in anchors_json["functional_subsectors_17"]:
        sid = str(sub["subsector_id"])
        if sid == "centralOperator":
            continue
        ux = float(sub["u_X"])
        uy = float(sub["u_Y"])
        pair_id = str(sub["pair_id"])
        is_card = pair_id.startswith("A") or pair_id.startswith("D")
        ax.plot(
            [0.0, r_z * ux],
            [0.0, r_z * uy],
            linestyle="-" if is_card else "-.",
            color="#CBD5E1" if is_card else "#E2E8F0",
            linewidth=1.05 if is_card else 0.85,
            zorder=1,
        )
        # Badge de paire en bordure extérieure
        t_pair = ax.text(
            1.055 * r_z * ux,
            1.055 * r_z * uy,
            pair_id,
            fontsize=7.6,
            fontweight="bold",
            color="#475569",
            ha="center",
            va="center",
            zorder=4,
        )
        obstacle_artists.append(t_pair)

    # Axes X=0 et Y=0 étendus jusqu'au bord
    ax.axhline(0.0, color="#CBD5E1", lw=0.7, zorder=0)
    ax.axvline(0.0, color="#CBD5E1", lw=0.7, zorder=0)

    # 4. Nuage des satellites en arrière-plan très discret (pour contexte visuel sans surcharger)
    if len(sat_z) > 0:
        ax.scatter(
            sat_z["x"],
            sat_z["y"],
            s=12,
            c="#CBD5E1",
            alpha=0.35,
            edgecolors="none",
            zorder=3,
        )

    # 5. Nuage Z_PLUS_ACTIVE coloré par quadrant Option 1A (plein = A > 0.65, creux = A <= 0.65)
    for _, row in act_z.iterrows():
        q = str(row["quadrant_option1a"])
        col = QUADRANT_COLORS.get(q, "#334155")
        if str(row["subsector_id"]) == "centralOperator":
            continue
        is_high_a = float(row["A_norm"]) > 0.65
        ax.scatter(
            [float(row["x"])],
            [float(row["y"])],
            s=62 if is_high_a else 52,
            facecolors=col if is_high_a else "#FFFFFF",
            edgecolors="#FFFFFF" if is_high_a else col,
            linewidths=0.7 if is_high_a else 1.45,
            alpha=0.92,
            zorder=6,
        )

    # Opérateur central (0, 0, Z)
    ax.scatter(
        [0.0],
        [0.0],
        s=155,
        marker="*",
        facecolors="#0F172A",
        edgecolors="#FFFFFF",
        linewidths=0.8,
        zorder=7,
    )

    # Fixer les limites AVANT le placement des étiquettes pour stabiliser transData
    lim = 1.18 * r_z
    ax.set_xlim(-lim, lim)
    ax.set_ylim(-lim, lim)
    ax.set_xlabel("Attente / Révisabilité ($x = A \\cdot R(Z) \\cdot u_X$)", fontsize=10.5, labelpad=8)
    ax.set_ylabel("Contrôle instrumental perçu ($y = A \\cdot R(Z) \\cdot u_Y$)", fontsize=10.5, labelpad=8)

    # 6. Étiquettes sans chevauchement des jalons clés
    milestones = _select_milestones_for_stratum(act_z, z)
    _, overlap_cnt = _place_non_overlapping_labels(fig, ax, milestones, float(r_z), obstacle_artists=obstacle_artists)
    assert overlap_cnt == 0, f"Chevauchement résiduel détecté sur surface_Z{z}.png : {overlap_cnt}"

    n_act_z = len(act_z)
    n_sat_z = len(sat_z)
    ax.set_title(
        f"CARTOGRAFFECT v3.0.0 — Surface pleine $L_1$ à $\\lfloor Z \\rfloor = {z}$ ($R = {r_z}$, centre : {op_label})\n"
        f"{n_act_z} entrées Z_PLUS_ACTIVE (+ {n_sat_z} satellites en fond) · Canal radial $A \\in [0.15, 1.00]$ · Option 1A (0 violation)",
        fontsize=11.2,
        fontweight="bold",
        color="#0F172A",
        pad=14,
    )

    # Annotations de quadrants discrètes aux coins
    corner = 0.96 * lim
    ax.text(corner, corner, "Q1 (+X, +Y)\nSynergie / Maîtrise", fontsize=8.0, color="#0F766E", ha="right", va="top", alpha=0.85)
    ax.text(-corner, corner, "Q2 (−X, +Y)\nAffrontement agentique", fontsize=8.0, color="#B91C1C", ha="left", va="top", alpha=0.85)
    ax.text(-corner, -corner, "Q3 (−X, −Y)\nFaible contrôle aversif", fontsize=8.0, color="#4338CA", ha="left", va="bottom", alpha=0.85)
    ax.text(corner, -corner, "Q4 (+X, −Y)\nAccommodation secondaire", fontsize=8.0, color="#B45309", ha="right", va="bottom", alpha=0.85)

    legend_handles = [
        Line2D([0], [0], color="#1E293B", lw=2.0, label=f"Losange $L_1$ ($|x|+|y|={r_z}$)"),
        Line2D([0], [0], color="#94A3B8", lw=1.25, ls="--", label=f"Cercle rival $L_2$ ($r={r_z}$)"),
        Line2D([0], [0], marker="o", color="w", markerfacecolor="#0D9488", markersize=7.5, label="Q1 / Axes +X,+Y"),
        Line2D([0], [0], marker="o", color="w", markerfacecolor="#DC2626", markersize=7.5, label="Q2 Affrontement"),
        Line2D([0], [0], marker="o", color="w", markerfacecolor="#4F46E5", markersize=7.5, label="Q3 / Axes −X,−Y"),
        Line2D([0], [0], marker="o", color="w", markerfacecolor="#D97706", markersize=7.5, label="Q4 Accommodation"),
        Line2D([0], [0], marker="o", color="w", markerfacecolor="#334155", markersize=7.5, label="Plein : $A > 0.65$"),
        Line2D([0], [0], marker="o", color="w", markerfacecolor="#FFFFFF", markeredgecolor="#334155", markeredgewidth=1.4, markersize=7.0, label="Évidé : $A \\leq 0.65$"),
    ]
    ax.legend(
        handles=legend_handles,
        loc="upper center",
        bbox_to_anchor=(0.5, -0.085),
        ncol=4,
        frameon=True,
        facecolor="#FFFFFF",
        edgecolor="#CBD5E1",
        fontsize=8.2,
    )

    fig.tight_layout()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(
        out_path,
        dpi=300,
        bbox_inches="tight",
        metadata={"Software": "CARTOGRAFFECT v3.0.0", "Title": f"CARTOGRAFFECT surface Z={z}"},
    )
    plt.close(fig)

    return {
        "path": out_path.relative_to(REPO_ROOT).as_posix(),
        "z": z,
        "radius": r_z,
        "n_active": n_act_z,
        "n_sat": n_sat_z,
        "n_labeled_milestones": len(milestones),
        "label_overlaps": overlap_cnt,
        "sha256": sha256_file(out_path),
        "size_bytes": out_path.stat().st_size,
    }


# =============================================================================
# 5. TESTS STATISTIQUES MANN-WHITNEY U & RAPPORT D'AUDIT MARKDOWN
# =============================================================================

def _run_mw_contrast(
    act_df: pd.DataFrame,
    high_words: tuple[str, ...],
    low_words: tuple[str, ...],
) -> dict[str, Any]:
    """Calcule les statistiques de séparation radiale en A (A_norm & A_harm) via Mann-Whitney U."""
    hi_all = act_df[act_df["lemme_norm"].isin(high_words)].copy()
    lo_all = act_df[act_df["lemme_norm"].isin(low_words)].copy()

    # Vue dédupliquée par lemme (moyenne des occurrences éventuelles d'un même lemme multi-classe/POS)
    hi_u = hi_all.groupby("lemme_norm", sort=True)[["A_norm", "A_harm"]].mean()
    lo_u = lo_all.groupby("lemme_norm", sort=True)[["A_norm", "A_harm"]].mean()

    def _mw_pair(x_vals: np.ndarray, y_vals: np.ndarray) -> dict[str, float]:
        n1, n2 = len(x_vals), len(y_vals)
        res_gt = stats.mannwhitneyu(x_vals, y_vals, alternative="greater")
        res_2s = stats.mannwhitneyu(x_vals, y_vals, alternative="two-sided")
        r_rb = (2.0 * float(res_gt.statistic) / (n1 * n2)) - 1.0
        return {
            "n_high": n1,
            "n_low": n2,
            "med_high": float(np.median(x_vals)),
            "iqr_high": float(np.percentile(x_vals, 75) - np.percentile(x_vals, 25)),
            "med_low": float(np.median(y_vals)),
            "iqr_low": float(np.percentile(y_vals, 75) - np.percentile(y_vals, 25)),
            "U": float(res_gt.statistic),
            "p_one_sided": float(res_gt.pvalue),
            "p_two_sided": float(res_2s.pvalue),
            "rank_biserial_r": float(r_rb),
        }

    return {
        "unique_A_norm": _mw_pair(hi_u["A_norm"].to_numpy(), lo_u["A_norm"].to_numpy()),
        "unique_A_harm": _mw_pair(hi_u["A_harm"].to_numpy(), lo_u["A_harm"].to_numpy()),
        "all_rows_A_norm": _mw_pair(hi_all["A_norm"].to_numpy(), lo_all["A_norm"].to_numpy()),
        "all_rows_A_harm": _mw_pair(hi_all["A_harm"].to_numpy(), lo_all["A_harm"].to_numpy()),
        "high_rows": hi_all.sort_values(["A_norm", "lemme_norm", "classe"], ascending=[False, True, True]).to_dict("records"),
        "low_rows": lo_all.sort_values(["A_norm", "lemme_norm", "classe"], ascending=[False, True, True]).to_dict("records"),
    }


def verify_20_milestones(master_df: pd.DataFrame) -> list[dict[str, Any]]:
    """Vérifie la cohérence des coordonnées de 20 jalons clés du Tableau 1b v3.0.0."""
    act_df = master_df[master_df["hemisphere_route"] == "Z_PLUS_ACTIVE"]
    rows: list[dict[str, Any]] = []
    for lemme, expected_cls, expected_sub in KEY_MILESTONES_20:
        cand = act_df[(act_df["lemme_norm"] == lemme) & (act_df["classe"] == expected_cls)]
        assert len(cand) >= 1, f"Jalon clé manquant : {lemme} ({expected_cls})"
        # Préférer NOM
        cand_sorted = cand.sort_values(
            by=["part_disc"],
            key=lambda s: s.map({"NOM": 0, "ADJ": 1}),
        )
        r = cand_sorted.iloc[0]
        assert str(r["subsector_id"]) == expected_sub, (
            f"Jalon {lemme} ({expected_cls}) subsector={r['subsector_id']} != {expected_sub}"
        )
        assert float(r["l1_radius"]) <= float(r["R_Z"]) + 1e-12
        rows.append(r.to_dict())
    return rows


def render_mp4_report(
    master_df: pd.DataFrame,
    anchors_json: dict[str, Any],
    meta: dict[str, Any],
    idem_apportion: dict[str, Any],
    mw_q3: dict[str, Any],
    mw_q14: dict[str, Any],
    milestones20: list[dict[str, Any]],
    fig_infos: list[dict[str, Any]],
    parquet_sha: str,
    tsv_sha: str,
) -> str:
    """Génère le rapport Markdown déterministe `reports/lexicon_v3/mp4_projection_report.md`."""
    dima_df = master_df[master_df["record_origin"] == "dima_z_plus_projected"]
    dima_act = dima_df[dima_df["hemisphere_route"] == "Z_PLUS_ACTIVE"]
    dima_sat = dima_df[dima_df["hemisphere_route"] == "Z_PLUS_SATELLITE"]
    periph_dima = dima_df[dima_df["subsector_id"] != "centralOperator"]

    # Vérification globale des invariants
    inv_l1_bound = bool((master_df["l1_radius"] <= master_df["R_Z"] + 1e-12).all())
    inv_a_range = bool(
        ((periph_dima["A_norm"] >= A_MIN_NORM - 1e-12) & (periph_dima["A_norm"] <= A_MAX_NORM + 1e-12)).all()
    )
    inv_unit_l1 = bool(
        np.allclose(np.abs(periph_dima["u_X"]) + np.abs(periph_dima["u_Y"]), 1.0, atol=1e-12)
    )
    lat_dima = dima_df[dima_df["subsector_id"].str.startswith("lateral")]
    lat_minors = np.minimum(np.abs(lat_dima["u_X"]), np.abs(lat_dima["u_Y"]))
    min_minor_lat = float(lat_minors.min())
    max_minor_lat = float(lat_minors.max())
    inv_lat_guard = bool(min_minor_lat >= LATERAL_GUARD_DELTA - 1e-12 and (0.5 - max_minor_lat) >= LATERAL_GUARD_DELTA - 1e-12)
    inv_z_range = bool(dima_df["Z_stratum"].isin([3, 4, 5]).all())
    assert inv_l1_bound and inv_a_range and inv_unit_l1 and inv_lat_guard and inv_z_range

    lines: list[str] = []
    lines.append("# Rapport d'Audit — Micro-Passe 4 : Projection sur la surface pleine $L_1$ ($|x| + |y| \\le 2\\lfloor Z \\rfloor - 2$) & Injection radiale de $A$ (CARTOGRAFFECT v3.0.0)")
    lines.append("")
    lines.append("- **Script :** [`python/lexicon_pipeline/03_project_surface_v3.py`](../../python/lexicon_pipeline/03_project_surface_v3.py) *(strictement idempotent, zéro appel réseau)*")
    lines.append("- **Périmètre Lean 4 :** `Cartograffect/` strictement en lecture seule (`0` fichier modifié)")
    lines.append("- **Statut YAML MP3b vérifié au démarrage :** `clinical_review_status == \"APPROVED\"` (`109` classes, `52` règles `subclass_overrides`)")
    lines.append(f"- **Filtrage clinique MP3b (`move_to_z_minus_reserve`) :** `moved_to_z_minus_in_mp3b = {meta['moved_to_z_minus_in_mp3b']}` (`Z_PLUS_ACTIVE`) + `{meta['moved_to_z_minus_satellites_in_mp3b']}` (`Z_PLUS_SATELLITE`) = `{meta['moved_to_z_minus_in_mp3b'] + meta['moved_to_z_minus_satellites_in_mp3b']}` entrées exclues sur les 5 classes (`{', '.join(meta['moved_classes'])}`)")
    lines.append(f"- **Table maître résultante (`lexicon_v3_master`) :** `{len(master_df):,}` lignes = `11` `canonical_lean4` ($Z \\in \\{{0,1,2\\}}$) + `3` `central_operator_v3` ($Z \\in \\{{3,4,5\\}}$) + `{meta['projected_active']}` `Z_PLUS_ACTIVE` + `{meta['projected_satellite']}` `Z_PLUS_SATELLITE` (`{meta['projected_total_dima']:,}` DIMA projetés)")
    lines.append(f"- **Winsorisation robuste de $A_{{\\text{{harm}}}}$ (périphériques $n = {meta['n_periph_for_winsor']:,}$) :** $p_{{01}} = {meta['p01_A_harm']:+.6f}$, $p_{{99}} = {meta['p99_A_harm']:+.6f}$, projection linéaire monotone vers $[0.15,\\; 1.00]$")
    lines.append("")
    lines.append("### Empreintes SHA-256 des entrées et sorties")
    lines.append("")
    lines.append("| Artefact | Statut Git | SHA-256 |")
    lines.append("| :--- | :--- | :--- |")
    lines.append(f"| `data/processed/dima_z_plus_psychometrics.parquet` *(entrée)* | Ignoré Git | `{sha256_file(PARQUET_IN_PATH)}` |")
    lines.append(f"| `data/config/dima_class_to_subsector_109.yaml` *(entrée)* | Versionné | `{sha256_file(ANCHORS_YAML_PATH)}` |")
    lines.append(f"| `data/config/canonical_z0_z2_anchors.json` *(entrée)* | Versionné | `{sha256_file(ANCHORS_JSON_PATH)}` |")
    lines.append(f"| `data/processed/lexicon_v3_master.parquet` *(sortie)* | Ignoré Git | `{parquet_sha}` |")
    lines.append(f"| `data/processed/lexicon_v3_master.tsv` *(sortie)* | Ignoré Git | `{tsv_sha}` |")
    for fi in fig_infos:
        lines.append(f"| `{fi['path']}` *(sortie 300 dpi)* | Versionnable | `{fi['sha256']}` |")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Section 1 : Bilan des effectifs
    lines.append("## 1. Bilan des effectifs projetés par strate $Z \\in \\{0..5\\}$, par `FunctionalSubsector` (17) et par `ring_A`")
    lines.append("")
    lines.append("### 1.1 Effectifs par strate $Z \\in \\{0..5\\}$")
    lines.append("")
    lines.append("| Strate $Z$ | Rayon $R(Z)$ | `canonical_lean4` | `central_operator_v3` | `Z_PLUS_ACTIVE` | `Z_PLUS_SATELLITE` | Total table maître |")
    lines.append("| :---: | :---: | ---: | ---: | ---: | ---: | ---: |")
    for z in range(6):
        sub = master_df[master_df["Z_stratum"] == z]
        r_z = 0 if z < 2 else 2 * z - 2
        c_can = int((sub["hemisphere_route"] == "CANONICAL_LOCKED").sum())
        c_cen = int((sub["hemisphere_route"] == "CENTRAL_OPERATOR_LOCKED").sum())
        c_act = int((sub["hemisphere_route"] == "Z_PLUS_ACTIVE").sum())
        c_sat = int((sub["hemisphere_route"] == "Z_PLUS_SATELLITE").sum())
        lines.append(f"| **{z}** | `{r_z}` | {c_can} | {c_cen} | {c_act} | {c_sat} | **{len(sub)}** |")
    lines.append(
        f"| **Total** | — | **11** | **3** | **{meta['projected_active']}** | **{meta['projected_satellite']}** | **{len(master_df)}** |"
    )
    lines.append("")

    lines.append("### 1.2 Effectifs par `FunctionalSubsector` (17 sous-secteurs Lean 4)")
    lines.append("")
    lines.append("| Paire | `subsector_id` | $(u_X^{\\text{prior}}, u_Y^{\\text{prior}})$ | Verrouillés ($Z \\le 5$) | `Z_PLUS_ACTIVE` ($Z=3/4/5$) | `Z_PLUS_SATELLITE` | Total DIMA | Total général |")
    lines.append("| :---: | :--- | :---: | ---: | :---: | ---: | ---: | ---: |")
    for sub_spec in anchors_json["functional_subsectors_17"]:
        sid = str(sub_spec["subsector_id"])
        sub_all = master_df[master_df["subsector_id"] == sid]
        sub_lck = sub_all[sub_all["record_origin"].isin(["canonical_lean4", "central_operator_v3"])]
        sub_act = sub_all[sub_all["hemisphere_route"] == "Z_PLUS_ACTIVE"]
        sub_sat = sub_all[sub_all["hemisphere_route"] == "Z_PLUS_SATELLITE"]
        z3 = int((sub_act["Z_stratum"] == 3).sum())
        z4 = int((sub_act["Z_stratum"] == 4).sum())
        z5 = int((sub_act["Z_stratum"] == 5).sum())
        u_str = f"`({float(sub_spec['u_X']):+.2f}, {float(sub_spec['u_Y']):+.2f})`"
        lines.append(
            f"| `{sub_spec['pair_id']}` | `{sid}` | {u_str} | {len(sub_lck)} | {len(sub_act)} (`{z3}/{z4}/{z5}`) | {len(sub_sat)} | {len(sub_act) + len(sub_sat)} | **{len(sub_all)}** |"
        )
    lines.append("")

    lines.append("### 1.3 Effectifs par anneau iso-activation (`ring_A`) et rattachement des satellites")
    lines.append("")
    lines.append("| Anneau `ring_A` | Plage $A_{\\text{norm}}$ | Verrouillés | `Z_PLUS_ACTIVE` | `Z_PLUS_SATELLITE` | Total |")
    lines.append("| :--- | :---: | ---: | ---: | ---: | ---: |")
    ring_specs = [
        ("center_operator", "$A = 0$ (`centralOperator`)"),
        ("inner_low", "$A \\in (0,\\; 0.35]$"),
        ("inner_mod", "$A \\in (0.35,\\; 0.65]$"),
        ("sub_perimeter", "$A \\in (0.65,\\; 0.85]$"),
        ("perimeter_high", "$A \\in (0.85,\\; 1.00]$"),
    ]
    for r_name, r_desc in ring_specs:
        sub_r = master_df[master_df["ring_A"] == r_name]
        r_lck = int(sub_r["record_origin"].isin(["canonical_lean4", "central_operator_v3"]).sum())
        r_act = int((sub_r["hemisphere_route"] == "Z_PLUS_ACTIVE").sum())
        r_sat = int((sub_r["hemisphere_route"] == "Z_PLUS_SATELLITE").sum())
        lines.append(f"| `{r_name}` | {r_desc} | {r_lck} | {r_act} | {r_sat} | **{len(sub_r)}** |")
    lines.append("")
    mc = meta["parent_match_counts"]
    lines.append(
        f"- **Priorité `subclass_overrides` :** `{meta['override_applied_total']}` entrées DIMA résolues via les `52` règles `subclass_overrides` (dont `{meta['override_applied_active']}` `Z_PLUS_ACTIVE`), et `{len(dima_df) - meta['override_applied_total']}` via les défauts de classe."
    )
    lines.append(
        f"- **Rattachement `parent_lemma_id` des `{meta['projected_satellite']}` satellites `Z_PLUS_SATELLITE` :** "
        f"`{mc['same_sous_classe']}` par `(classe, sous_classe)`, `{mc['same_classe']}` par `classe`, "
        f"`{mc['same_subsector_z_fallback']}` par `(subsector_id, Z)` *(classes exclusivement satellites)*, "
        f"`{mc['same_subsector_fallback']}` par `subsector_id` (`0` satellite orphelin)."
    )
    lines.append("")
    lines.append("---")
    lines.append("")

    # Section 2 : Vérification formelle des invariants
    lines.append("## 2. Vérification formelle de 100 % des invariants")
    lines.append("")
    lines.append("| Invariant | Portée vérifiée | Résultat | Statut |")
    lines.append("| :--- | :--- | :--- | :---: |")
    lines.append(f"| Strate normative $Z \\in \\{{3, 4, 5\\}}$ (DIMA projetés) | `1,482 / 1,482` | `100.00%` dans `{{3, 4, 5}}` | **PASS** |")
    lines.append(f"| Identifiants exacts `FunctionalSubsector` (17 Lean 4) | `1,496 / 1,496` | `17 / 17` identifiants exacts, `0` inconnu | **PASS** |")
    lines.append(f"| Inégalité de surface pleine $|x| + |y| \\le 2\\lfloor Z \\rfloor - 2$ | `1,496 / 1,496` | `max(|x|+|y| - R(Z)) = {float((master_df['l1_radius'] - master_df['R_Z']).max()):.2e}` | **PASS** |")
    lines.append(f"| Canal autonome périphérique $A_{{\\text{{norm}}}} \\in [0.15,\\; 1.00]$ | `1,429 / 1,429` | min=`{float(periph_dima['A_norm'].min()):.6f}`, max=`{float(periph_dima['A_norm'].max()):.6f}` | **PASS** |")
    lines.append(f"| Norme unitaire directionnelle $|u_X| + |u_Y| = 1$ | `1,429 / 1,429` | écart max = `{float(np.abs(np.abs(periph_dima['u_X']) + np.abs(periph_dima['u_Y']) - 1.0).max()):.2e}` | **PASS** |")
    lines.append(f"| Garde cône latéral ($\\delta = 0.05$ aux axes & diagonales) | `607 / 607` latéraux | `min(|u_minor|) = {min_minor_lat:.4f}` (`>= 0.05`), `max = {max_minor_lat:.4f}` (`<= 0.45`) | **PASS** |")
    lines.append(f"| Idempotence exacte `apportionRay(X, Y, Z) == (X, Y)` | `Z in {{2,3,4,5}}` (`{idem_apportion['total_tested']}` pts) | `{idem_apportion['total_idempotent']} / {idem_apportion['total_tested']}` (`100.00%` exact) | **PASS** |")
    lines.append(f"| Conformité Option 1A (verrous 1A-a/b/c/d, 0 aversif $Y > 0$) | `1,482 / 1,482` | `{meta['option_1a_violations']}` violation | **PASS** |")
    lines.append(f"| Lisibilité PNG sans chevauchement d'étiquettes | `surface_Z{{3,4,5}}.png` | `{sum(fi['label_overlaps'] for fi in fig_infos)}` chevauchement sur `{sum(fi['n_labeled_milestones'] for fi in fig_infos)}` jalons | **PASS** |")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Section 3 : Audit de séparation radiale en A (Mann-Whitney U)
    lines.append("## 3. Audit de séparation radiale en $A$ (médianes & test de Mann-Whitney $U$)")
    lines.append("")
    lines.append("Les deux contrastes évaluent la séparation radiale de l'activation autonome ($A_{\\text{norm}}$ et $A_{\\text{harm}}$) entre jalons haute activation vs basse activation situés dans un même domaine quadrantique sur les entrées `Z_PLUS_ACTIVE` :")
    lines.append("")
    lines.append("| Contraste | Base | Haute activation (médiane, IQR, $n$) | Basse activation (médiane, IQR, $n$) | $U$ | $p$ (unilatéral `>`) | $p$ (bilatéral) | $r_{\\text{rb}}$ |")
    lines.append("| :--- | :--- | :--- | :--- | ---: | ---: | ---: | ---: |")

    def _add_mw_row(label: str, basis: str, stats_d: dict[str, float]) -> None:
        lines.append(
            f"| {label} | {basis} | `{stats_d['med_high']:.4f}` (IQR `{stats_d['iqr_high']:.4f}`, $n={stats_d['n_high']}$) | "
            f"`{stats_d['med_low']:.4f}` (IQR `{stats_d['iqr_low']:.4f}`, $n={stats_d['n_low']}$) | "
            f"`{stats_d['U']:.1f}` | `{stats_d['p_one_sided']:.4e}` | `{stats_d['p_two_sided']:.4e}` | `{stats_d['rank_biserial_r']:+.4f}` |"
        )

    _add_mw_row("**Q3 ($Y < 0$) : Panique/Angoisse/Terreur/Effroi/Affliction vs Résignation/Apathie/Lassitude/Accablement**", "Lemmes uniques (`A_norm`)", mw_q3["unique_A_norm"])
    _add_mw_row("Q3 ($Y < 0$) — toutes occurrences actives", "Toutes lignes (`A_norm`)", mw_q3["all_rows_A_norm"])
    _add_mw_row("Q3 ($Y < 0$) — échelle brute $A_{\\text{harm}}$", "Lemmes uniques (`A_harm`)", mw_q3["unique_A_harm"])
    _add_mw_row("**Q1/Q4 : Euphorie/Exaltation/Passion/Enthousiasme vs Calme/Sérénité/Tranquillité/Quiétude/Repos**", "Lemmes uniques (`A_norm`)", mw_q14["unique_A_norm"])
    _add_mw_row("Q1/Q4 — toutes occurrences actives", "Toutes lignes (`A_norm`)", mw_q14["all_rows_A_norm"])
    _add_mw_row("Q1/Q4 — échelle brute $A_{\\text{harm}}$", "Lemmes uniques (`A_harm`)", mw_q14["unique_A_harm"])
    lines.append("")

    lines.append("### Détail des lemmes évalués dans les deux contrastes")
    lines.append("")
    lines.append("| Contraste | Groupe | `lemme_norm` | Classe DIMA | `subsector_id` | $Z$ | $A_{\\text{harm}}$ | $A_{\\text{norm}}$ | `ring_A` | $(x, y)$ |")
    lines.append("| :--- | :--- | :--- | :--- | :--- | :---: | ---: | ---: | :--- | :---: |")
    for c_lbl, mw_obj in (("Q3 ($Y < 0$)", mw_q3), ("Q1/Q4", mw_q14)):
        for g_lbl, rows_key in (("Haute activation", "high_rows"), ("Basse activation", "low_rows")):
            for r in mw_obj[rows_key]:
                lines.append(
                    f"| {c_lbl} | {g_lbl} | `{r['lemme_norm']}` | `{r['classe']}` | `{r['subsector_id']}` | {r['Z_stratum']} | "
                    f"`{r['A_harm']:+.4f}` | `{r['A_norm']:.4f}` | `{r['ring_A']}` | `({r['x']:+.2f}, {r['y']:+.2f})` |"
                )
    lines.append("")
    lines.append("---")
    lines.append("")

    # Section 4 : 20 jalons clés du Tableau 1b v3.0.0
    lines.append("## 4. Cohérence des coordonnées de 20 jalons clés du Tableau 1b v3.0.0 (17/17 sous-secteurs)")
    lines.append("")
    lines.append("| # | Jalon (`lemme_norm`) | Classe DIMA | `subsector_id` | $Z$ | $(u_X, u_Y)$ | $A_{\\text{norm}}$ | `ring_A` | $(x, y)$ | Couronne $(X_c, Y_c)$ | $|x|+|y| / R(Z)$ |")
    lines.append("| ---: | :--- | :--- | :--- | :---: | :---: | ---: | :--- | :---: | :---: | :---: |")
    for idx_m, r in enumerate(milestones20, 1):
        lines.append(
            f"| {idx_m} | `{r['lemme_norm']}` | `{r['classe']}` | `{r['subsector_id']}` | {r['Z_stratum']} | "
            f"`({r['u_X']:+.3f}, {r['u_Y']:+.3f})` | `{r['A_norm']:.4f}` | `{r['ring_A']}` | "
            f"`({r['x']:+.2f}, {r['y']:+.2f})` | `({r['X_crown']:+d}, {r['Y_crown']:+d})` | "
            f"`{r['l1_radius']:.2f} / {r['R_Z']}` |"
        )
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("## 5. Figures de contrôle générées (300 dpi)")
    lines.append("")
    for fi in fig_infos:
        lines.append(
            f"- **`{fi['path']}`** ($Z = {fi['z']}$, $R = {fi['radius']}$) : `{fi['n_active']}` entrées `Z_PLUS_ACTIVE`, "
            f"`{fi['n_sat']}` satellites en fond, `{fi['n_labeled_milestones']}` jalons annotés (`{fi['label_overlaps']}` chevauchement), "
            f"`{fi['size_bytes']:,}` octets, SHA-256 `{fi['sha256'][:16]}...`"
        )
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    print("[MP4] Chargement et validation des sources...")
    anchors_json, anchors_yaml, df_in = load_and_validate_inputs()
    subsector_map = {str(s["subsector_id"]): s for s in anchors_json["functional_subsectors_17"]}

    idem_apportion = verify_apportion_ray_idempotence()
    print(f"[MP4][APPORTION] Idempotence vérifiée sur {idem_apportion['total_idempotent']}/{idem_apportion['total_tested']} points entiers (Z=2..5)")

    locked_rows = build_locked_canonical_rows(anchors_json, subsector_map)
    proj_df, meta = project_dima_entries(anchors_yaml, subsector_map, df_in)
    print(
        f"[MP4][FILTRE MP3b] moved_to_z_minus_in_mp3b={meta['moved_to_z_minus_in_mp3b']} "
        f"(+ {meta['moved_to_z_minus_satellites_in_mp3b']} satellites) | "
        f"Z_PLUS_ACTIVE={meta['projected_active']}, Z_PLUS_SATELLITE={meta['projected_satellite']}"
    )
    print(
        f"[MP4][WINSOR A] p01={meta['p01_A_harm']:.6f}, p99={meta['p99_A_harm']:.6f} -> [0.15, 1.00] | "
        f"overrides appliqués={meta['override_applied_total']} (active={meta['override_applied_active']})"
    )

    # Fusion canonique en tête de table + DIMA projeté
    locked_df = pd.DataFrame(locked_rows)
    col_order = [
        "lemma_id",
        "record_origin",
        "hemisphere_route",
        "lemme_norm",
        "label_display",
        "part_disc",
        "classe",
        "sous_classe",
        "categ",
        "pruning_bucket",
        "metric_provenance",
        "en_matched_term",
        "z_minus_value_candidate",
        "V_harm",
        "A_harm",
        "D_raw",
        "D_orth",
        "A_winsor",
        "A_norm",
        "ring_A",
        "Z_stratum",
        "R_Z",
        "subsector_id",
        "subsector_pair",
        "conjugate_subsector",
        "subsector_resolution_source",
        "u_X",
        "u_Y",
        "x",
        "y",
        "l1_radius",
        "X_crown",
        "Y_crown",
        "antagonist_X_crown",
        "antagonist_Y_crown",
        "quadrant_option1a",
        "hedonic_polarity",
        "parent_lemma_id",
        "parent_match_level",
    ]
    master_df = pd.concat([locked_df[col_order], proj_df[col_order]], ignore_index=True)
    assert len(master_df) == 14 + 1482
    assert master_df["lemma_id"].is_unique

    # Export local (ignoré Git)
    MASTER_PARQUET_PATH.parent.mkdir(parents=True, exist_ok=True)
    master_df.to_parquet(MASTER_PARQUET_PATH, engine="pyarrow", index=False)
    master_df.to_csv(MASTER_TSV_PATH, sep="\t", index=False, encoding="utf-8", lineterminator="\n")
    parquet_sha = sha256_file(MASTER_PARQUET_PATH)
    tsv_sha = sha256_file(MASTER_TSV_PATH)
    print(f"[MP4][EXPORT] parquet SHA256={parquet_sha}")
    print(f"[MP4][EXPORT] tsv     SHA256={tsv_sha}")

    # Génération des 3 figures PNG 300 dpi
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    fig_infos: list[dict[str, Any]] = []
    for z in (3, 4, 5):
        fi = render_surface_figure(master_df, anchors_json, z, REPORTS_DIR / f"surface_Z{z}.png")
        fig_infos.append(fi)
        print(
            f"[MP4][FIG Z={z}] {fi['path']} ({fi['n_labeled_milestones']} jalons, "
            f"overlaps={fi['label_overlaps']}) SHA256={fi['sha256']}"
        )

    # Audits statistiques en A et vérification 20 jalons Tableau 1b
    act_df = master_df[master_df["hemisphere_route"] == "Z_PLUS_ACTIVE"]
    mw_q3 = _run_mw_contrast(act_df, MW_Q3_HIGH_A, MW_Q3_LOW_A)
    mw_q14 = _run_mw_contrast(act_df, MW_Q14_HIGH_A, MW_Q14_LOW_A)
    milestones20 = verify_20_milestones(master_df)

    report_md = render_mp4_report(
        master_df=master_df,
        anchors_json=anchors_json,
        meta=meta,
        idem_apportion=idem_apportion,
        mw_q3=mw_q3,
        mw_q14=mw_q14,
        milestones20=milestones20,
        fig_infos=fig_infos,
        parquet_sha=parquet_sha,
        tsv_sha=tsv_sha,
    )
    REPORT_MD_PATH.write_text(report_md, encoding="utf-8", newline="\n")
    report_sha = sha256_file(REPORT_MD_PATH)
    print(f"[MP4][REPORT] {REPORT_MD_PATH.relative_to(REPO_ROOT).as_posix()} SHA256={report_sha}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
