# SPDX-License-Identifier: AGPL-3.0-or-later
"""
04_compute_antagonism.py — Micro-Passe 5 : Antagonisme involutif A,
appariement Top-3 et audit croisé DIMA (CARTOGRAFFECT v3.0.0)

Périmètre strict :
- Lecture seule sur data/processed/lexicon_v3_master.parquet,
  data/config/canonical_z0_z2_anchors.json et data/processed/dima_normalized.parquet.
- Aucune modification dans Cartograffect/ (noyau Lean 4 normatif en lecture seule).
- Aucun accès aux fichiers Diamant_303.
- Strictement idempotent (sorties déterministes octet pour octet, fins de ligne LF).
- Zéro appel réseau / API externe.

Exports :
- data/processed/antagonism_pairs_v3.parquet (local uniquement, ignoré Git)
- data/processed/antagonism_pairs_v3.tsv (local uniquement, ignoré Git)
- data/processed/antagonism_audit_conflicts.csv (local uniquement, ignoré Git)
- reports/lexicon_v3/mp5_antagonism_audit.md (versionnable Git)
"""

from __future__ import annotations

import hashlib
import json
from collections import Counter
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd

REPO_ROOT = Path(__file__).resolve().parents[2]
MASTER_PARQUET_PATH = REPO_ROOT / "data" / "processed" / "lexicon_v3_master.parquet"
ANCHORS_JSON_PATH = REPO_ROOT / "data" / "config" / "canonical_z0_z2_anchors.json"
DIMA_PARQUET_PATH = REPO_ROOT / "data" / "processed" / "dima_normalized.parquet"

PAIRS_PARQUET_PATH = REPO_ROOT / "data" / "processed" / "antagonism_pairs_v3.parquet"
PAIRS_TSV_PATH = REPO_ROOT / "data" / "processed" / "antagonism_pairs_v3.tsv"
CONFLICTS_CSV_PATH = REPO_ROOT / "data" / "processed" / "antagonism_audit_conflicts.csv"
REPORT_MD_PATH = REPO_ROOT / "reports" / "lexicon_v3" / "mp5_antagonism_audit.md"

BONUS_ENTREES_ANTONYMES = 1.00
BONUS_ANTONYMIE_FAMILY = 0.50
WEIGHT_DELTA_A = 0.0
AROUSAL_REGIME_THRESHOLD = 0.25

PROVENANCE_RANK: dict[str, int] = {
    "lean4_canonical": 0,
    "fancat_direct": 1,
    "nrc_override": 2,
    "nrc_bridge_auto": 3,
    "subclass_centroid": 4,
    "class_centroid": 5,
}

# Pôles antonymiques explicites au sein des 24 familles ANTONYMIE multi-classes
# présentes dans Z_PLUS_ACTIVE (empêche d'apparier deux classes co-hyponymes du même pôle).
DIMA_ANTONYMIE_POLES: dict[str, dict[str, int]] = {
    "Admiration-Mépris": {"Admiration": 0, "Mépris": 1},
    "Amitié-Inimitié": {"Amitié": 0, "Amitié préférence": 0, "Inimitié": 1},
    "Amour / Affection-Haine / Désamour": {
        "Affection": 0,
        "Amour": 0,
        "Amour désamour": 1,
        "Haine de qq": 1,
    },
    "Apaiser-Troubler": {"Apaiser": 0, "Troubler": 1},
    "Bon moral-Mauvais moral": {"Bon moral": 0, "Mauvais moral": 1},
    "Bonne & Mauvaise conscience": {
        "Bonne conscience": 0,
        "Mauvaise conscience": 1,
        "Mauvaise conscience scrupule": 1,
    },
    "Combler-Décevoir": {
        "Combler Bonheur": 0,
        "Décevoir": 1,
        "Décevoir Malheur": 1,
    },
    "Confiance / Croyance & Défiance / Doute": {
        "Confiance": 0,
        "Confiance_Sentiment de sécurité": 0,
        "Doute": 1,
        "Défiance": 1,
        "Défiance_Sentiment d'insécurité": 1,
    },
    "Curiosité-Désintérêt": {"Curiosité": 0, "Désintérêt": 1},
    "Désinhiber-Inhiber / Embarrasser": {
        "Désinhiber": 0,
        "Embarrasser": 1,
        "Inhiber": 1,
    },
    "Désir / impatience & Absence de désir": {
        "Désir": 0,
        "Désir impatience": 0,
        "Absence de désir": 1,
    },
    "Détendre-Importuner": {"Détendre": 0, "Importuner": 1},
    "Energie-Apathie": {"Energie": 0, "Apathie": 1},
    "Espoir & Crainte / Désespérer de": {"Espoir": 0, "Crainte": 1},
    "Estime / Respect & Mésestime / Irrespect": {
        "Estime": 0,
        "Estime respect": 0,
        "Mésestime": 1,
    },
    "Goût-Aversion": {"Goût": 0, "Aversion": 1},
    "Gratitude-Ressentiment": {"Gratitude": 0, "Ressentiment": 1},
    "Humeurs bonne-mauvaise-songeuse": {
        "Humeur bonne": 0,
        "Humeur mauvaise": 1,
        "Humeur songeuse": 2,
    },
    "Jouissance-Souffrance": {"Jouissance": 0, "Souffrance": 1},
    "Orgueil / Honte / Pudeur": {"Orgueil": 0, "Honte": 1},
    "Plaire-Déplaire": {"Plaire_A": 0, "Déplaire_A": 1},
    "Rassurer-Inquiéter & Effrayer": {
        "Rassurer": 0,
        "Inquiéter": 1,
        "Inquiéter Effrayer": 1,
    },
    "Réjouir-Attrister": {"Réjouir": 0, "Attrister": 1},
    "Résignation-Colère": {"Résignation": 0, "Colère": 1},
}

PHILIE_PHOBIE_PAIRED_ROOTS: frozenset[tuple[str, str]] = frozenset({
    ("américanophile", "américanophobe"),
    ("américanophilie", "américanophobie"),
    ("anglophile", "anglophobe"),
    ("anglophilie", "anglophobie"),
    ("francophile", "francophobe"),
    ("francophilie", "francophobie"),
    ("germanophile", "germanophobe"),
    ("germanophilie", "germanophobie"),
    ("philanthrope", "misanthrope"),
    ("philanthropie", "misanthropie"),
    ("philosémite", "antisémite"),
})

AUDIT_CATEGORIES_ORDER: tuple[str, ...] = (
    "CONGRUENT_EXACT",
    "CONGRUENT_CROSS_Z",
    "CENTRAL_VS_CONTRALATERAL",
    "INTRA_SECTOR_OR_AROUSAL_CONTRAST",
    "OTHER_FUNCTIONAL_DIVERGENCE",
)


def sha256_file(path: Path) -> str:
    """Calcule l'empreinte SHA-256 hexadécimale d'un fichier."""
    return hashlib.sha256(path.read_bytes()).hexdigest()


def clean_zero(val: float) -> float:
    """Normalise -0.0 vers +0.0 pour garantir la reproductibilité binaire."""
    f = float(val)
    return 0.0 if abs(f) == 0.0 else f


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


def antagonist_ray(u_x: float, u_y: float, z: int) -> tuple[float, float, int]:
    """
    Opérateur statique exact A(u_X, u_Y, Z) sur les rayons directionnels L1 :
    - centre fixe (0, 0, Z) -> (0, 0, Z)
    - axiaux (u_X * u_Y == 0) -> (-u_X, -u_Y, Z)
    - non axiaux (u_X * u_Y != 0) -> (-sgn(u_X)|u_Y|, -sgn(u_Y)|u_X|, Z)
    """
    z_int = int(z)
    ux = clean_zero(u_x)
    uy = clean_zero(u_y)
    if ux == 0.0 and uy == 0.0:
        return (0.0, 0.0, z_int)
    if ux == 0.0 or uy == 0.0:
        return (clean_zero(-ux), clean_zero(-uy), z_int)
    sx = 1.0 if ux > 0.0 else -1.0
    sy = 1.0 if uy > 0.0 else -1.0
    return (clean_zero(-sx * abs(uy)), clean_zero(-sy * abs(ux)), z_int)


def antagonist_crown(x_crown: int, y_crown: int, z: int) -> tuple[int, int, int]:
    """Miroir exact de `Cartograffect.AffectiveMatrix.antagonistPoint` sur Z x Z x N."""
    x_i = int(x_crown)
    y_i = int(y_crown)
    z_i = int(z)
    if x_i == 0 or y_i == 0:
        return (-x_i, -y_i, z_i)
    sx = 1 if x_i > 0 else -1
    sy = 1 if y_i > 0 else -1
    return (-sx * abs(y_i), -sy * abs(x_i), z_i)


def conjugate_subsector_of(subsector_id: str, subsector_map: dict[str, dict[str, Any]]) -> str:
    """Retourne le `conjugate_subsector` Lean 4 exact pour `subsector_id`."""
    return str(subsector_map[subsector_id]["conjugate_subsector"])


def classify_activation_regime(delta_a: float) -> str:
    """Diagnostique le régime d'activation de la paire (sans pénalité de score)."""
    return "iso_energetic" if float(delta_a) <= AROUSAL_REGIME_THRESHOLD + 1e-12 else "asymmetric_arousal"


def are_opposite_dima_poles(rec_a: dict[str, Any], rec_b: dict[str, Any]) -> bool:
    """Vérifie que deux entrées DIMA ne relèvent pas d'une même classe ou d'un même pôle antonymique."""
    cl_a = str(rec_a["classe"])
    cl_b = str(rec_b["classe"])
    if cl_a == cl_b:
        return False
    ant_a = rec_a.get("antonymie")
    ant_b = rec_b.get("antonymie")
    if ant_a and ant_b and ant_a == ant_b and ant_a in DIMA_ANTONYMIE_POLES:
        pmap = DIMA_ANTONYMIE_POLES[ant_a]
        p_a = pmap.get(cl_a)
        p_b = pmap.get(cl_b)
        if p_a is not None and p_b is not None:
            return p_a != p_b
    return True


def is_same_antonymie_opposite_pole(rec_a: dict[str, Any], rec_b: dict[str, Any]) -> bool:
    """Vérifie si deux entrées appartiennent à des pôles opposés d'une même famille ANTONYMIE."""
    ant_a = rec_a.get("antonymie")
    ant_b = rec_b.get("antonymie")
    if not ant_a or not ant_b or ant_a != ant_b:
        return False
    pmap = DIMA_ANTONYMIE_POLES.get(ant_a)
    if not pmap:
        return False
    p_a = pmap.get(str(rec_a["classe"]))
    p_b = pmap.get(str(rec_b["classe"]))
    return p_a is not None and p_b is not None and p_a != p_b


def _literal_entrees_antonymes_match(ea_str: str | None, lem_a: str, lem_b: str) -> bool:
    """Teste si un champ `entrees_antonymes` de la forme `X-Y` apparie littéralement `{lem_a, lem_b}`."""
    if not ea_str or ea_str.count("-") != 1:
        return False
    left, right = [part.strip().lower() for part in ea_str.split("-", 1)]
    if not left or not right:
        return False
    pair_lemmas = {lem_a.strip().lower(), lem_b.strip().lower()}
    if pair_lemmas == {left, right}:
        return True
    if pair_lemmas == {left.replace(" ", "-"), right.replace(" ", "-")}:
        return True
    return False


def is_entrees_antonymes_pair(rec_a: dict[str, Any], rec_b: dict[str, Any]) -> bool:
    """Détecte une relation antonymique lexicale explicite issue de `Entrées antonymes` de DIMA."""
    if not are_opposite_dima_poles(rec_a, rec_b):
        return False
    ea_a = rec_a.get("entrees_antonymes")
    ea_b = rec_b.get("entrees_antonymes")
    lem_a = str(rec_a["lemme_norm"]).lower()
    lem_b = str(rec_b["lemme_norm"]).lower()

    if ea_a and ea_b and ea_a == ea_b:
        if ea_a == "philie-phobie":
            return (lem_a, lem_b) in PHILIE_PHOBIE_PAIRED_ROOTS or (lem_b, lem_a) in PHILIE_PHOBIE_PAIRED_ROOTS
        return True

    return _literal_entrees_antonymes_match(ea_a, lem_a, lem_b) or _literal_entrees_antonymes_match(ea_b, lem_a, lem_b)


def score_antagonist_candidate(
    src: dict[str, Any],
    cand: dict[str, Any],
    expected_u_x: float,
    expected_u_y: float,
) -> dict[str, Any]:
    """
    Évalue un candidat antagoniste selon :
    - proximité directionnelle L1 entre (u'_X, u'_Y) et A(u_X, u_Y) ;
    - bonus explicite DIMA (Entrées antonymes et/ou famille ANTONYMIE) ;
    - pénalité STRICTEMENT NULLE (WEIGHT_DELTA_A == 0.0) sur |A - A'|.
    """
    assert WEIGHT_DELTA_A == 0.0
    l1_ray_dist = abs(float(cand["u_X"]) - float(expected_u_x)) + abs(float(cand["u_Y"]) - float(expected_u_y))
    is_ea = is_entrees_antonymes_pair(src, cand)
    is_ant = is_same_antonymie_opposite_pole(src, cand)
    bonus = BONUS_ENTREES_ANTONYMES if is_ea else (BONUS_ANTONYMIE_FAMILY if is_ant else 0.0)
    delta_a = abs(float(src["A_norm"]) - float(cand["A_norm"]))
    composite_score = l1_ray_dist - bonus + WEIGHT_DELTA_A * delta_a
    pos_mismatch = 0 if str(cand["part_disc"]) == str(src["part_disc"]) else 1
    prov_rank = PROVENANCE_RANK.get(str(cand["metric_provenance"]), 99)

    return {
        "l1_ray_dist": clean_zero(l1_ray_dist),
        "delta_a": clean_zero(delta_a),
        "activation_pair_regime": classify_activation_regime(delta_a),
        "dima_antonymie_match": bool(is_ant),
        "dima_entrees_antonymes_match": bool(is_ea),
        "dima_congruence_bonus": float(bonus),
        "composite_score": clean_zero(composite_score),
        "sort_key": (
            round(composite_score, 12),
            pos_mismatch,
            prov_rank,
            str(cand["lemme_norm"]),
            str(cand["lemma_id"]),
        ),
    }


def load_and_verify_inputs() -> tuple[pd.DataFrame, dict[str, Any], dict[str, dict[str, Any]]]:
    """Charge en lecture seule les 3 entrées, joint DIMA et vérifie 100 % des invariants géométriques de A."""
    anchors_json = json.loads(ANCHORS_JSON_PATH.read_text(encoding="utf-8"))
    subsector_map = {str(s["subsector_id"]): s for s in anchors_json["functional_subsectors_17"]}
    assert len(subsector_map) == 17

    master_df = pd.read_parquet(MASTER_PARQUET_PATH)
    assert len(master_df) == 1496, f"Attendu 1 496 lignes dans master, trouvé {len(master_df)}"
    counts = master_df["hemisphere_route"].value_counts().to_dict()
    assert counts == {
        "Z_PLUS_SATELLITE": 940,
        "Z_PLUS_ACTIVE": 542,
        "CANONICAL_LOCKED": 11,
        "CENTRAL_OPERATOR_LOCKED": 3,
    }, f"Répartition inattendue dans master : {counts}"

    dima_df = pd.read_parquet(DIMA_PARQUET_PATH)
    assert len(dima_df) == 3342
    dima_rel = dima_df[["lemme_norm", "part_disc", "classe", "categ", "antonymie", "entrees_antonymes"]].copy()
    for col in ("antonymie", "entrees_antonymes"):
        dima_rel[col] = dima_rel[col].map(lambda v: None if pd.isna(v) else str(v))

    dima_rows = master_df[master_df["record_origin"] == "dima_z_plus_projected"].merge(
        dima_rel,
        on=["lemme_norm", "part_disc", "classe", "categ"],
        how="left",
        validate="one_to_one",
    )
    assert len(dima_rows) == 1482
    locked_rows = master_df[master_df["record_origin"] != "dima_z_plus_projected"].copy()
    locked_rows["antonymie"] = None
    locked_rows["entrees_antonymes"] = None

    df = pd.concat([locked_rows, dima_rows], ignore_index=True)
    assert len(df) == 1496

    # Vérification stricte de l'opérateur A sur 100 % des 1 496 entrées
    for row in df.itertuples(index=False):
        ux, uy, z = float(row.u_X), float(row.u_Y), int(row.Z_stratum)
        xc, yc = int(row.X_crown), int(row.Y_crown)
        sid = str(row.subsector_id)
        exp_conj = conjugate_subsector_of(sid, subsector_map)
        assert str(row.conjugate_subsector) == exp_conj

        ax_u, ay_u, az_u = antagonist_ray(ux, uy, z)
        aax_u, aay_u, aaz_u = antagonist_ray(ax_u, ay_u, az_u)
        assert az_u == z and aaz_u == z
        assert abs(aax_u - ux) < 1e-12 and abs(aay_u - uy) < 1e-12
        assert abs((abs(ax_u) + abs(ay_u)) - (abs(ux) + abs(uy))) < 1e-12
        assert classify_subsector_py(ax_u, ay_u) == exp_conj

        ax_c, ay_c, az_c = antagonist_crown(xc, yc, z)
        aax_c, aay_c, aaz_c = antagonist_crown(ax_c, ay_c, az_c)
        assert az_c == z and aaz_c == z
        assert (aax_c, aay_c) == (xc, yc)
        assert (ax_c, ay_c) == (int(row.antagonist_X_crown), int(row.antagonist_Y_crown))
        assert abs(ax_c) + abs(ay_c) == abs(xc) + abs(yc)
        assert classify_subsector_py(ax_c, ay_c) == exp_conj

        if sid.startswith("lateral"):
            assert abs(abs(ax_u) - abs(uy)) < 1e-12 and abs(abs(ay_u) - abs(ux)) < 1e-12
            assert abs(ax_c) == abs(yc) and abs(ay_c) == abs(xc)

    return df, anchors_json, subsector_map


def build_antagonism_pairs(
    df: pd.DataFrame,
    subsector_map: dict[str, dict[str, Any]],
) -> pd.DataFrame:
    """Construit la table Top-3 des antagonistes sur les 8 prototypes canoniques Z=2 et les 542 Z_PLUS_ACTIVE."""
    canon_z2 = df[
        (df["record_origin"] == "canonical_lean4")
        & (df["Z_stratum"] == 2)
        & (df["subsector_id"] != "centralOperator")
    ].copy()
    assert len(canon_z2) == 8

    active_df = df[df["hemisphere_route"] == "Z_PLUS_ACTIVE"].copy()
    assert len(active_df) == 542

    canon_recs = canon_z2.to_dict("records")
    active_recs = active_df.to_dict("records")

    canon_by_sub: dict[str, list[dict[str, Any]]] = {}
    for rec in canon_recs:
        canon_by_sub.setdefault(str(rec["subsector_id"]), []).append(rec)

    active_by_sub_z: dict[tuple[str, int], list[dict[str, Any]]] = {}
    active_by_sub: dict[str, list[dict[str, Any]]] = {}
    for rec in active_recs:
        sid = str(rec["subsector_id"])
        z = int(rec["Z_stratum"])
        active_by_sub_z.setdefault((sid, z), []).append(rec)
        active_by_sub.setdefault(sid, []).append(rec)

    pair_rows: list[dict[str, Any]] = []
    sources = canon_recs + active_recs
    assert len(sources) == 550

    for src in sources:
        src_origin = str(src["record_origin"])
        src_sid = str(src["subsector_id"])
        src_z = int(src["Z_stratum"])
        conj_sid = conjugate_subsector_of(src_sid, subsector_map)
        exp_ux, exp_uy, _ = antagonist_ray(float(src["u_X"]), float(src["u_Y"]), src_z)
        exp_xc, exp_yc, _ = antagonist_crown(int(src["X_crown"]), int(src["Y_crown"]), src_z)

        if src_origin == "canonical_lean4":
            pool = canon_by_sub[conj_sid]
            assert len(pool) == 1
            scored = []
            for cand in pool:
                sc = score_antagonist_candidate(src, cand, exp_ux, exp_uy)
                scored.append((0, sc["sort_key"], cand, sc, "canonical_z2_exact"))
            top_items = scored[:1]
        elif src_sid == "centralOperator":
            sc = score_antagonist_candidate(src, src, exp_ux, exp_uy)
            top_items = [(0, sc["sort_key"], src, sc, "central_fixed_point")]
        else:
            same_z_pool = active_by_sub_z.get((conj_sid, src_z), [])
            if same_z_pool:
                scope = "same_Z_exact"
                pool = same_z_pool
            else:
                scope = "cross_Z_conjugate_fallback"
                pool = active_by_sub[conj_sid]
                assert len(pool) > 0, f"Aucun candidat actif pour conjugué {conj_sid}"

            scored = []
            for cand in pool:
                sc = score_antagonist_candidate(src, cand, exp_ux, exp_uy)
                dz = abs(src_z - int(cand["Z_stratum"]))
                scored.append((dz, sc["sort_key"], cand, sc, scope))
            scored.sort(key=lambda item: (item[0], item[1]))
            top_items = scored[:3]

        for rank_idx, (dz, _, cand, sc, scope) in enumerate(top_items, 1):
            pair_rows.append({
                "source_lemma_id": str(src["lemma_id"]),
                "source_record_origin": src_origin,
                "source_lemme_norm": str(src["lemme_norm"]),
                "source_part_disc": str(src["part_disc"]),
                "source_classe": str(src["classe"]),
                "source_Z_stratum": src_z,
                "source_subsector_id": src_sid,
                "subsector_pair": str(src["subsector_pair"]),
                "source_u_X": clean_zero(src["u_X"]),
                "source_u_Y": clean_zero(src["u_Y"]),
                "source_X_crown": int(src["X_crown"]),
                "source_Y_crown": int(src["Y_crown"]),
                "source_A_norm": float(src["A_norm"]),
                "expected_ant_u_X": exp_ux,
                "expected_ant_u_Y": exp_uy,
                "expected_ant_X_crown": exp_xc,
                "expected_ant_Y_crown": exp_yc,
                "conjugate_subsector": conj_sid,
                "rank": rank_idx,
                "match_scope": scope,
                "same_Z_match": bool(src_z == int(cand["Z_stratum"])),
                "delta_Z": int(dz),
                "target_lemma_id": str(cand["lemma_id"]),
                "target_record_origin": str(cand["record_origin"]),
                "target_lemme_norm": str(cand["lemme_norm"]),
                "target_part_disc": str(cand["part_disc"]),
                "target_classe": str(cand["classe"]),
                "target_Z_stratum": int(cand["Z_stratum"]),
                "target_subsector_id": str(cand["subsector_id"]),
                "target_u_X": clean_zero(cand["u_X"]),
                "target_u_Y": clean_zero(cand["u_Y"]),
                "target_X_crown": int(cand["X_crown"]),
                "target_Y_crown": int(cand["Y_crown"]),
                "target_A_norm": float(cand["A_norm"]),
                "l1_ray_dist": sc["l1_ray_dist"],
                "delta_A": sc["delta_a"],
                "activation_pair_regime": sc["activation_pair_regime"],
                "dima_antonymie_match": sc["dima_antonymie_match"],
                "dima_entrees_antonymes_match": sc["dima_entrees_antonymes_match"],
                "dima_congruence_bonus": sc["dima_congruence_bonus"],
                "composite_score": sc["composite_score"],
            })

    pairs_df = pd.DataFrame(pair_rows)
    directed_edges = set(zip(pairs_df["source_lemma_id"], pairs_df["target_lemma_id"]))
    pairs_df["is_mutual_top3"] = [
        (tgt, src) in directed_edges
        for src, tgt in zip(pairs_df["source_lemma_id"], pairs_df["target_lemma_id"])
    ]
    pairs_df = pairs_df.sort_values(
        [
            "source_record_origin",
            "source_Z_stratum",
            "subsector_pair",
            "source_subsector_id",
            "source_lemma_id",
            "rank",
        ],
        kind="mergesort",
    ).reset_index(drop=True)
    return pairs_df


def classify_dima_conflict(
    rec_a: dict[str, Any],
    rec_b: dict[str, Any],
    subsector_map: dict[str, dict[str, Any]],
) -> str:
    """Classe une paire antonymique DIMA dans l'une des 5 catégories analytiques."""
    s_a = str(rec_a["subsector_id"])
    s_b = str(rec_b["subsector_id"])
    z_a = int(rec_a["Z_stratum"])
    z_b = int(rec_b["Z_stratum"])
    q_a = str(rec_a["quadrant_option1a"])
    q_b = str(rec_b["quadrant_option1a"])

    if s_a != "centralOperator":
        conj_a = conjugate_subsector_of(s_a, subsector_map)
        if s_b == conj_a:
            return "CONGRUENT_EXACT" if z_a == z_b else "CONGRUENT_CROSS_Z"
        cent_a = classify_subsector_py(-float(rec_a["u_X"]), -float(rec_a["u_Y"]))
        if s_b == cent_a:
            return "CENTRAL_VS_CONTRALATERAL"

    grp_a = str(subsector_map[s_a]["taxonomic_group"])
    grp_b = str(subsector_map[s_b]["taxonomic_group"])
    if (q_a == q_b) or (grp_a == grp_b):
        return "INTRA_SECTOR_OR_AROUSAL_CONTRAST"
    return "OTHER_FUNCTIONAL_DIVERGENCE"


def build_dima_conflicts_audit(
    df: pd.DataFrame,
    subsector_map: dict[str, dict[str, Any]],
) -> pd.DataFrame:
    """Extrait et classe toutes les paires antonymiques DIMA dans `Z_PLUS_ACTIVE`."""
    active_df = df[df["hemisphere_route"] == "Z_PLUS_ACTIVE"].sort_values("lemma_id", kind="mergesort")
    active_recs = active_df.to_dict("records")

    # Vérifier qu'aucune famille ANTONYMIE multi-classes dans Z_PLUS_ACTIVE n'est omise
    for ant, grp in active_df.dropna(subset=["antonymie"]).groupby("antonymie"):
        if grp["classe"].nunique() >= 2:
            assert str(ant) in DIMA_ANTONYMIE_POLES, f"Famille ANTONYMIE absente de DIMA_ANTONYMIE_POLES : {ant!r}"

    conflicts_rows: list[dict[str, Any]] = []
    n = len(active_recs)
    for i in range(n):
        rec_a = active_recs[i]
        for j in range(i + 1, n):
            rec_b = active_recs[j]
            is_ant = is_same_antonymie_opposite_pole(rec_a, rec_b)
            is_ea = is_entrees_antonymes_pair(rec_a, rec_b)
            if not (is_ant or is_ea):
                continue

            if is_ant and is_ea:
                oracle_src = "entrees_antonymes_and_antonymie"
            elif is_ea:
                oracle_src = "entrees_antonymes_only"
            else:
                oracle_src = "antonymie_family_opposite_classes"

            cat = classify_dima_conflict(rec_a, rec_b, subsector_map)
            delta_a = abs(float(rec_a["A_norm"]) - float(rec_b["A_norm"]))
            ant_fam = rec_a["antonymie"] if rec_a["antonymie"] == rec_b["antonymie"] else f"{rec_a['antonymie']} || {rec_b['antonymie']}"
            conflicts_rows.append({
                "lemma_id_a": str(rec_a["lemma_id"]),
                "lemme_norm_a": str(rec_a["lemme_norm"]),
                "part_disc_a": str(rec_a["part_disc"]),
                "classe_a": str(rec_a["classe"]),
                "Z_stratum_a": int(rec_a["Z_stratum"]),
                "subsector_id_a": str(rec_a["subsector_id"]),
                "quadrant_a": str(rec_a["quadrant_option1a"]),
                "u_X_a": clean_zero(rec_a["u_X"]),
                "u_Y_a": clean_zero(rec_a["u_Y"]),
                "A_norm_a": float(rec_a["A_norm"]),
                "lemma_id_b": str(rec_b["lemma_id"]),
                "lemme_norm_b": str(rec_b["lemme_norm"]),
                "part_disc_b": str(rec_b["part_disc"]),
                "classe_b": str(rec_b["classe"]),
                "Z_stratum_b": int(rec_b["Z_stratum"]),
                "subsector_id_b": str(rec_b["subsector_id"]),
                "quadrant_b": str(rec_b["quadrant_option1a"]),
                "u_X_b": clean_zero(rec_b["u_X"]),
                "u_Y_b": clean_zero(rec_b["u_Y"]),
                "A_norm_b": float(rec_b["A_norm"]),
                "antonymie_family": str(ant_fam),
                "entrees_antonymes_a": rec_a.get("entrees_antonymes") or "",
                "entrees_antonymes_b": rec_b.get("entrees_antonymes") or "",
                "oracle_source": oracle_src,
                "audit_category": cat,
                "delta_Z": abs(int(rec_a["Z_stratum"]) - int(rec_b["Z_stratum"])),
                "delta_A": clean_zero(delta_a),
                "activation_pair_regime": classify_activation_regime(delta_a),
            })

    conflicts_df = pd.DataFrame(conflicts_rows).sort_values(
        ["audit_category", "antonymie_family", "lemma_id_a", "lemma_id_b"],
        kind="mergesort",
    ).reset_index(drop=True)
    return conflicts_df


def _select_exemplar_pairs(pairs_df: pd.DataFrame) -> list[dict[str, Any]]:
    """Sélectionne 20 paires exemplaires vérifiées (couvrant les 8 paires conjuguées et les deux régimes de A)."""
    specs: list[tuple[str, str, str | None, str]] = [
        # --- Prototypes canoniques Z=2 ---
        ("canon_z2_colere", "calme", None, "Z=2 canonique (D2, Rew− ↔ Pun−)"),
        ("canon_z2_desir", "dégoût", None, "Z=2 canonique (D1, Rew+ ↔ Pun+)"),
        # --- Paires Z_PLUS_ACTIVE asymétriques en activation (asymmetric_arousal) ---
        ("dima|Colère|NOM|colère", "calme", "Apaiser", "Asymétrique en A (D2, Z=3 : colère haut A ↔ calme bas A)"),
        ("dima|Inquiéter|NOM|angoisse", "sérénité", "Rassurer", "Asymétrique en A + ANT (L2, Z=4 : angoisse haut A ↔ sérénité bas A)"),
        ("dima|Inquiéter|NOM|angoisse", "tranquillité", "Rassurer", "Asymétrique en A + ANT (L2, Z=4 : angoisse haut A ↔ tranquillité bas A)"),
        ("dima|Energie|NOM|énergie", "avachissement", "Apathie", "Asymétrique en A + ANT (L1, Z=5 : énergie haut A ↔ avachissement bas A)"),
        ("dima|Apathie|NOM|apathie", "fougue", "Energie", "Asymétrique en A + ANT (L1, Z=5 : apathie bas A ↔ fougue haut A)"),
        ("dima|Bon moral|NOM|exaltation", "agoraphobe", "Peur phobie", "Asymétrique en A (L2, Z=5 : exaltation haut A ↔ agoraphobe bas A)"),
        ("dima|Colère|NOM|rage", "apaisement", "Apaiser", "Asymétrique en A (D2, Z=3 : rage haut A ↔ apaisement bas A)"),
        ("dima|Gratitude|NOM|gratitude", "rancœur", "Ressentiment", "Asymétrique en A + ANT (L3, Z=4 : gratitude ↔ rancœur)"),
        ("dima|Amour désamour|NOM|désamour", "amour", "Amour", "Asymétrique en A + EA/ANT (D1, Z=4 : désamour ↔ amour)"),
        ("dima|Détendre|NOM|repos", "dépit", "Décevoir", "Asymétrique en A (L4, Z=3 : repos bas A ↔ dépit modéré)"),
        # --- Paires Z_PLUS_ACTIVE iso-énergétiques (iso_energetic) ---
        ("dima|Orgueil|NOM|fierté", "honte", "Honte", "Iso-énergétique + ANT (L1, Z=4 : fierté ↔ honte)"),
        ("dima|Réjouir|NOM|joie", "tristesse", "Attrister", "Iso-énergétique + ANT (A2, Z=3 : joie ↔ tristesse)"),
        ("dima|Confiance|NOM|confiance", "défiance", "Défiance", "Iso-énergétique + EA/ANT (A1, Z=5 : confiance ↔ défiance)"),
        ("dima|Confiance_Sentiment de sécurité|NOM|optimisme", "pessimisme", "Défiance_Sentiment d'insécurité", "Iso-énergétique + EA/ANT (L2, Z=5 : optimisme ↔ pessimisme)"),
        ("dima|Plaire_A|NOM|sympathie", "antipathie", "Déplaire_A", "Iso-énergétique + EA/ANT (D1, Z=3 : sympathie ↔ antipathie)"),
        ("dima|Goût|NOM|goût", "aversion", "Aversion", "Iso-énergétique + ANT (D1, Z=4 : goût ↔ aversion)"),
        ("dima|Espoir|NOM|espoir", "épuisement", "Mauvais moral", "Iso-énergétique (L1, Z=5 : espoir ↔ épuisement)"),
        ("dima|Inquiéter Effrayer|NOM|terreur", "plaisir", "Jouissance", "Iso-énergétique (L2, Z=3 : terreur haut A ↔ plaisir haut A)"),
    ]

    selected: list[dict[str, Any]] = []
    for src_id, tgt_lem, tgt_cls, note in specs:
        sub = pairs_df[pairs_df["source_lemma_id"] == src_id]
        if tgt_cls is not None:
            m = sub[(sub["target_lemme_norm"] == tgt_lem) & (sub["target_classe"] == tgt_cls)]
        else:
            m = sub[sub["target_lemme_norm"] == tgt_lem]
        assert len(m) >= 1, f"Paire exemplaire introuvable : {src_id} -> {tgt_lem} ({tgt_cls})"
        rec = m.iloc[0].to_dict()
        rec["note"] = note
        selected.append(rec)

    assert len(selected) == 20
    return selected


def render_mp5_report(
    df: pd.DataFrame,
    anchors_json: dict[str, Any],
    pairs_df: pd.DataFrame,
    conflicts_df: pd.DataFrame,
    pairs_parquet_sha: str,
    pairs_tsv_sha: str,
    conflicts_csv_sha: str,
) -> str:
    """Génère le rapport Markdown déterministe `reports/lexicon_v3/mp5_antagonism_audit.md`."""
    act_pairs = pairs_df[pairs_df["source_record_origin"] == "dima_z_plus_projected"]
    periph_act_pairs = act_pairs[act_pairs["source_subsector_id"] != "centralOperator"]
    same_z_periph = periph_act_pairs[periph_act_pairs["same_Z_match"]]
    cross_z_periph = periph_act_pairs[~periph_act_pairs["same_Z_match"]]

    n_sources_act_periph = int(periph_act_pairs["source_lemma_id"].nunique())
    n_sources_same_z = int(same_z_periph["source_lemma_id"].nunique())
    n_sources_cross_z = int(cross_z_periph["source_lemma_id"].nunique())

    n_iso = int((periph_act_pairs["activation_pair_regime"] == "iso_energetic").sum())
    n_asym = int((periph_act_pairs["activation_pair_regime"] == "asymmetric_arousal").sum())
    n_ea_hits = int(periph_act_pairs["dima_entrees_antonymes_match"].sum())
    n_ant_hits = int(periph_act_pairs["dima_antonymie_match"].sum())
    mutual_rate = 100.0 * float(periph_act_pairs["is_mutual_top3"].mean())

    n_lat = int(df["subsector_id"].str.startswith("lateral").sum())
    exemplars = _select_exemplar_pairs(pairs_df)

    lines: list[str] = []
    lines.append("# Rapport d'Audit — Micro-Passe 5 : Antagonisme involutif $\\mathcal{A}$, appariement Top-3 & confrontation DIMA (CARTOGRAFFECT v3.0.0)")
    lines.append("")
    lines.append("- **Script :** [`python/lexicon_pipeline/04_compute_antagonism.py`](../../python/lexicon_pipeline/04_compute_antagonism.py) *(strictement idempotent, zéro appel réseau)*")
    lines.append("- **Suite bloquante :** [`python/lexicon_pipeline/test_lexicon_invariants.py`](../../python/lexicon_pipeline/test_lexicon_invariants.py) *(7 invariants normatifs)*")
    lines.append("- **Périmètre Lean 4 :** `Cartograffect/` strictement en lecture seule (`0` fichier modifié)")
    lines.append(f"- **Population appariée (`antagonism_pairs_v3`) :** `550` entrées sources (`8` prototypes canoniques $Z=2$ + `542` `Z_PLUS_ACTIVE` sur $Z \\in \\{{3,4,5\\}}$) → **`{len(pairs_df):,}` lignes** (`8` canoniques $Z=2$ + `13` points fixes centraux $Z=3$ + `{len(periph_act_pairs):,}` paires périphériques `Z_PLUS_ACTIVE`)")
    lines.append(f"- **Couverture strate $Z$ identique (`Z_PLUS_ACTIVE` périphériques, $n = {n_sources_act_periph}$) :** `{n_sources_same_z}` entrées en `same_Z_exact` (`{100.0 * n_sources_same_z / n_sources_act_periph:.1f}%`) + `{n_sources_cross_z}` entrées en `cross_Z_conjugate_fallback` *(cellules conjuguées structurellement vides à ce $Z$ dans DIMA `Z_PLUS_ACTIVE`)*")
    lines.append(f"- **Découplage Option 1A ($w_{{|A - A'|}} = 0.0$) :** `{n_iso}` paires `iso_energetic` ($|\\Delta A| \\le 0.25$) et `{n_asym}` paires `asymmetric_arousal` ($|\\Delta A| > 0.25$) coexistent sans pénalité ; taux de réciprocité Top-3 = `{mutual_rate:.1f}%`")
    lines.append(f"- **Oracle DIMA (`antagonism_audit_conflicts.csv`) :** **`{len(conflicts_df):,}` paires** antonymiques distinctes extraites dans `Z_PLUS_ACTIVE` (`{int((conflicts_df['oracle_source'] != 'antonymie_family_opposite_classes').sum())}` impliquant `Entrées antonymes`)")
    lines.append("")
    lines.append("### Empreintes SHA-256 des entrées et sorties")
    lines.append("")
    lines.append("| Artefact | Statut Git | SHA-256 |")
    lines.append("| :--- | :--- | :--- |")
    lines.append(f"| `data/processed/lexicon_v3_master.parquet` *(entrée)* | Ignoré Git | `{sha256_file(MASTER_PARQUET_PATH)}` |")
    lines.append(f"| `data/processed/dima_normalized.parquet` *(entrée)* | Ignoré Git | `{sha256_file(DIMA_PARQUET_PATH)}` |")
    lines.append(f"| `data/config/canonical_z0_z2_anchors.json` *(entrée)* | Versionné | `{sha256_file(ANCHORS_JSON_PATH)}` |")
    lines.append(f"| `data/processed/antagonism_pairs_v3.parquet` *(sortie)* | Ignoré Git | `{pairs_parquet_sha}` |")
    lines.append(f"| `data/processed/antagonism_pairs_v3.tsv` *(sortie)* | Ignoré Git | `{pairs_tsv_sha}` |")
    lines.append(f"| `data/processed/antagonism_audit_conflicts.csv` *(sortie)* | Ignoré Git | `{conflicts_csv_sha}` |")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Section 1
    lines.append("## 1. Vérification formelle de l'opérateur géométrique $\\mathcal{A}$")
    lines.append("")
    lines.append("| Invariant Lean 4 (`antagonistPoint`) | Portée vérifiée | Résultat | Statut |")
    lines.append("| :--- | :--- | :--- | :---: |")
    lines.append("| Involutivité exacte rayon $\\mathcal{A}(\\mathcal{A}(u_X, u_Y, Z)) = (u_X, u_Y, Z)$ | `1,496 / 1,496` | écart max $< 10^{-12}$ | **PASS** |")
    lines.append("| Involutivité exacte couronne $\\mathcal{A}(\\mathcal{A}(X_c, Y_c, Z)) = (X_c, Y_c, Z)$ | `1,496 / 1,496` | `100.00%` exact (entier) | **PASS** |")
    lines.append("| Échange controlatéral d'amplitudes $|X| \\leftrightarrow |Y|$ (`L1`–`L4`) | `{0} / {0}` latéraux | `100.00%` exact (rayon & couronne) | **PASS** |".format(n_lat))
    lines.append("| Conservation de la strate $Z$ et de la norme $L_1$ | `1,496 / 1,496` | `100.00%` exact | **PASS** |")
    lines.append("| Points fixes $\\mathcal{A}(p) = p \\iff$ `centralOperator` | `1,496 / 1,496` | `59` fixes (`6` verrouillés + `53` DIMA), `1,437` mobiles | **PASS** |")
    lines.append("| Conjugaison exacte vers les `17` `FunctionalSubsector` | `1,496 / 1,496` | `100.00%` exact | **PASS** |")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Section 2
    lines.append("## 2. Synthèse chiffrée des 8 paires conjuguées + centre fixe (`Z_PLUS_ACTIVE`)")
    lines.append("")
    lines.append("| Paire | Sous-secteur $+$ (`Z=3/4/5`) | Sous-secteur $-$ (`Z=3/4/5`) | Paires Top-3 | `same_Z` | `cross_Z` | `iso_energetic` | `asymmetric_arousal` | Méd. $\\|\\Delta u\\|_1$ | Méd. $|\\Delta A|$ | Bonus DIMA (`EA` / `ANT`) |")
    lines.append("| :---: | :--- | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :---: |")

    act_df = df[df["hemisphere_route"] == "Z_PLUS_ACTIVE"]
    for pair in anchors_json["conjugate_pairs_8"]:
        pid = str(pair["pair_id"])
        s_pos = str(pair["subsector_pos"])
        s_neg = str(pair["subsector_neg"])
        z_pos = "/".join(str(int(((act_df["subsector_id"] == s_pos) & (act_df["Z_stratum"] == z)).sum())) for z in (3, 4, 5))
        z_neg = "/".join(str(int(((act_df["subsector_id"] == s_neg) & (act_df["Z_stratum"] == z)).sum())) for z in (3, 4, 5))
        sub_p = periph_act_pairs[periph_act_pairs["subsector_pair"] == pid]
        n_sz = int(sub_p["same_Z_match"].sum())
        n_cz = int((~sub_p["same_Z_match"]).sum())
        n_i = int((sub_p["activation_pair_regime"] == "iso_energetic").sum())
        n_a = int((sub_p["activation_pair_regime"] == "asymmetric_arousal").sum())
        med_u = float(sub_p["l1_ray_dist"].median())
        med_da = float(sub_p["delta_A"].median())
        ea_c = int(sub_p["dima_entrees_antonymes_match"].sum())
        ant_c = int(sub_p["dima_antonymie_match"].sum())
        lines.append(
            f"| `{pid}` | `{s_pos}` (`{z_pos}`) | `{s_neg}` (`{z_neg}`) | {len(sub_p)} | {n_sz} | {n_cz} | {n_i} | {n_a} | `{med_u:.3f}` | `{med_da:.3f}` | `{ea_c} / {ant_c}` |"
        )

    cen_p = act_pairs[act_pairs["subsector_pair"] == "CENTER"]
    z_cen = "/".join(str(int(((act_df["subsector_id"] == "centralOperator") & (act_df["Z_stratum"] == z)).sum())) for z in (3, 4, 5))
    lines.append(
        f"| `CENTER` | `centralOperator` (`{z_cen}`) | `centralOperator` *(point fixe)* | {len(cen_p)} | {len(cen_p)} | 0 | {len(cen_p)} | 0 | `0.000` | `0.000` | `0 / 0` |"
    )
    lines.append("")
    lines.append(
        f"> **Note sur les `73` sources en repli `cross_Z_conjugate_fallback` :** `6` cellules `(conjugate_subsector, Z)` ne contiennent aucune entrée `Z_PLUS_ACTIVE` dans DIMA (`A2` `axialControlPos` $Z=5$ : `13`, `axialControlNeg` $Z=4$ : `6` ; `D1` `diagonalSynergyNeg` $Z=5$ : `31` ; `L3` `lateralAgenticConfront` $Z=3$ : `7` ; `L4` `lateralSecondaryAccomm` $Z=5$ : `4`, `lateralActiveContest` $Z=4$ : `12`). Aucune entrée n'est écartée : le moteur sélectionne les Top-3 dans le sous-secteur conjugué sur les strates les plus proches ($|\\Delta Z| \\in \\{{1, 2\\}}$) et marque explicitement `same_Z_match = False`. Au total sur les paires périphériques actives, `{n_ea_hits}` paires bénéficient du bonus `Entrées antonymes` et `{n_ant_hits}` du bonus famille `ANTONYMIE`."
    )
    lines.append("")
    lines.append("---")
    lines.append("")

    # Section 3
    lines.append("## 3. Vingt (20) paires antagonistes exemplaires (iso-énergétiques & asymétriques en $A$)")
    lines.append("")
    lines.append("| # | Source (`lemme`, `classe`, $Z$) | Cible (`lemme`, `classe`, $Z$) | Paire | Rang | $(u_X, u_Y) \\to (u'_X, u'_Y)$ | $A \\to A'$ | $|\\Delta A|$ | Régime $A$ | Bonus DIMA | Contexte |")
    lines.append("| ---: | :--- | :--- | :---: | :---: | :--- | :---: | ---: | :--- | :---: | :--- |")
    for idx_ex, r in enumerate(exemplars, 1):
        dima_tag = "EA+ANT" if (r["dima_entrees_antonymes_match"] and r["dima_antonymie_match"]) else (
            "EA" if r["dima_entrees_antonymes_match"] else ("ANT" if r["dima_antonymie_match"] else "—")
        )
        src_lbl = f"`{r['source_lemme_norm']}` (`{r['source_classe']}`, Z={r['source_Z_stratum']})"
        tgt_lbl = f"`{r['target_lemme_norm']}` (`{r['target_classe']}`, Z={r['target_Z_stratum']})"
        u_lbl = f"`({r['source_u_X']:+.2f},{r['source_u_Y']:+.2f})` → `({r['target_u_X']:+.2f},{r['target_u_Y']:+.2f})`"
        a_lbl = f"`{r['source_A_norm']:.3f}` → `{r['target_A_norm']:.3f}`"
        lines.append(
            f"| {idx_ex} | {src_lbl} | {tgt_lbl} | `{r['subsector_pair']}` | #{r['rank']} | {u_lbl} | {a_lbl} | `{r['delta_A']:.3f}` | `{r['activation_pair_regime']}` | `{dima_tag}` | {r['note']} |"
        )
    lines.append("")
    lines.append("---")
    lines.append("")

    # Section 4
    lines.append("## 4. Audit croisé DIMA vs CARTOGRAFFECT : typologie des divergences (`antagonism_audit_conflicts.csv`)")
    lines.append("")
    total_conf = len(conflicts_df)
    ea_conf = conflicts_df[conflicts_df["oracle_source"] != "antonymie_family_opposite_classes"]
    total_ea_conf = len(ea_conf)

    lines.append("### 4.1 Répartition globale des 5 catégories analytiques")
    lines.append("")
    lines.append("| Catégorie | Toutes paires DIMA (`Z_PLUS_ACTIVE`) | Part (%) | Paires `Entrées antonymes` | Part `EA` (%) | Interprétation géométrique & cognitive |")
    lines.append("| :--- | ---: | ---: | ---: | ---: | :--- |")

    cat_descriptions = {
        "CONGRUENT_EXACT": "Même strate $Z$ et sous-secteurs conjugués exacts sous $\\mathcal{A}$",
        "CONGRUENT_CROSS_Z": "Sous-secteurs conjugués exacts sous $\\mathcal{A}$, mais strates $Z$ différentes (ex. $Z=3$ réactif opposé à $Z=5$ dispositionnel)",
        "CENTRAL_VS_CONTRALATERAL": "DIMA oppose par symétrie centrale simple $(-X, -Y)$ sur latéraux sans permuter $|X| \\leftrightarrow |Y|$",
        "INTRA_SECTOR_OR_AROUSAL_CONTRAST": "Opposition lexicale d'intensité ou de mode dans un même quadrant ou macro-secteur d'axe dominant",
        "OTHER_FUNCTIONAL_DIVERGENCE": "Divergence structurale entre antonymie linguistique de surface et antagonisme fonctionnel en inférence active",
    }

    for cat in AUDIT_CATEGORIES_ORDER:
        n_c = int((conflicts_df["audit_category"] == cat).sum())
        n_cea = int((ea_conf["audit_category"] == cat).sum())
        pct_c = 100.0 * n_c / total_conf if total_conf else 0.0
        pct_ea = 100.0 * n_cea / total_ea_conf if total_ea_conf else 0.0
        lines.append(f"| `{cat}` | {n_c:,} | `{pct_c:.1f}%` | {n_cea} | `{pct_ea:.1f}%` | {cat_descriptions[cat]} |")
    lines.append(f"| **Total** | **{total_conf:,}** | **`100.0%`** | **{total_ea_conf}** | **`100.0%`** | Congruents totaux (`EXACT + CROSS_Z`) : **`{100.0 * conflicts_df['audit_category'].isin(['CONGRUENT_EXACT', 'CONGRUENT_CROSS_Z']).mean():.1f}%`** (`{100.0 * ea_conf['audit_category'].isin(['CONGRUENT_EXACT', 'CONGRUENT_CROSS_Z']).mean():.1f}%` sur `EA`) |")
    lines.append("")

    lines.append("### 4.2 Macro-paires de classes DIMA par catégorie")
    lines.append("")
    for cat in AUDIT_CATEGORIES_ORDER:
        sub_c = conflicts_df[conflicts_df["audit_category"] == cat]
        if len(sub_c) == 0:
            continue
        lines.append(f"#### `{cat}` ({len(sub_c):,} paires)")
        lines.append("")
        lines.append("| Famille `ANTONYMIE` | Pôle A (`classe`, `subsector_id`, $Z$) | Pôle B (`classe`, `subsector_id`, $Z$) | Paires | Dont `EA` | Exemples |")
        lines.append("| :--- | :--- | :--- | ---: | ---: | :--- |")

        grp_counts: Counter[tuple[str, str, str, int, str, str, int]] = Counter()
        ea_grp_counts: Counter[tuple[str, str, str, int, str, str, int]] = Counter()
        examples_map: dict[tuple[str, str, str, int, str, str, int], list[str]] = {}
        for r in sub_c.itertuples(index=False):
            p1 = (str(r.classe_a), str(r.subsector_id_a), int(r.Z_stratum_a))
            p2 = (str(r.classe_b), str(r.subsector_id_b), int(r.Z_stratum_b))
            if p1 <= p2:
                k = (str(r.antonymie_family), p1[0], p1[1], p1[2], p2[0], p2[1], p2[2])
                ex = f"`{r.lemme_norm_a}`↔`{r.lemme_norm_b}`"
            else:
                k = (str(r.antonymie_family), p2[0], p2[1], p2[2], p1[0], p1[1], p1[2])
                ex = f"`{r.lemme_norm_b}`↔`{r.lemme_norm_a}`"
            grp_counts[k] += 1
            if r.oracle_source != "antonymie_family_opposite_classes":
                ea_grp_counts[k] += 1
            examples_map.setdefault(k, [])
            if ex not in examples_map[k] and len(examples_map[k]) < 2:
                examples_map[k].append(ex)

        for k, cnt in sorted(grp_counts.items(), key=lambda item: (-item[1], item[0])):
            fam, c1, s1, z1, c2, s2, z2 = k
            exs = ", ".join(examples_map[k])
            lines.append(f"| `{fam}` | `{c1}` (`{s1}`, Z={z1}) | `{c2}` (`{s2}`, Z={z2}) | {cnt} | {ea_grp_counts[k]} | {exs} |")
        lines.append("")

    lines.append("### 4.3 Lecture épistémologique et clinique des divergences")
    lines.append("")
    lines.append("1. **`CONGRUENT_EXACT` & `CONGRUENT_CROSS_Z` (congruence géométrique directe) :** Les oppositions lexicales symétriques en profondeur temporelle (`Energie`↔`Apathie` en L1, `Goût`↔`Aversion` en D1, `Plaire_A`↔`Déplaire_A` en D1, `Réjouir`↔`Attrister` en A2, `Confiance`↔`Défiance`/`Doute` en A1, `Gratitude`↔`Ressentiment` en L3, `Orgueil`↔`Honte` en L1) s'alignent exactement sur $\\mathcal{A}$. Le régime `CONGRUENT_CROSS_Z` révèle que DIMA mélange parfois des strates temporelles distinctes dans une même famille antonymique : par exemple `Désir` ($Z=3$ réactif) y est opposé à `Absence de désir` ($Z=5$ dispositionnel), et `Inquiéter Effrayer` ($Z=3$) à `Rassurer` ($Z=4$).")
    lines.append("2. **`CENTRAL_VS_CONTRALATERAL` (signature spécifique de l'échange $|X| \\leftrightarrow |Y|$) :** Sur les positions latérales (`Bon moral`↔`Mauvais moral`, `Jouissance`↔`Souffrance`, `Admiration`↔`Mépris`, `Estime respect`↔`Mésestime`, `Désinhiber`↔`Inhiber`), le langage courant associe les contraires par inversion hédonique/centrale $(-X, -Y)$, alors que la dynamique prédictive impose de permuter la voie dominante ($|Y| > |X| \\leftrightarrow |X| > |Y|$) afin d'équilibrer le biais d'allocation attentionnelle $(\\pi_A, \\pi_C)$ (`antagonistPoint_off_axis`).")
    lines.append("3. **`INTRA_SECTOR_OR_AROUSAL_CONTRAST` :** Regroupe les contrastes lexicaux internes à un même domaine fonctionnel (`Humeur mauvaise` vs `Humeur songeuse` en $Y < 0$, ou `Combler Bonheur` vs `Décevoir` dans le macro-secteur `sectorControlPos` à $Y > |X|$ où la valence s'inverse par le signe de $X$ sans changer la dominance pragmatique).")
    lines.append("4. **`OTHER_FUNCTIONAL_DIVERGENCE` (ex. `Résignation` vs `Colère` dans DIMA 2) :** En sémantique lexicale de surface, DIMA 2 regroupe sous `Résignation-Colère` la soumission résignée et la révolte colérique comme deux attitudes pragmatiques opposées face à l'adversité. En inférence active (Option 1A), la `Colère` occupe le quadrant d'affrontement agentique `Q2` $(-X, +Y)$ (non-révisabilité épistémique mais maintien d'un contrôle instrumental élevé), dont l'antagoniste régulateur exact est `diagonalAccommodation` `Q4` $(+X, -Y)$ (`Calme`, `Apaisement`). À l'inverse, la `Résignation` (`fatalisme`, `résignation`) relève de `Q3` `lateralAversiveDistress` $(-X, -Y)$ (faible contrôle perçu avec basse activation $A$), dont l'antagoniste est `lateralEpistemicMastery` `Q1` $(+X, +Y)$ (`Espoir`, `Fierté`, `Énergie`). De même, `Amitié` (`diagonalSynergyPos` `Q1`) est opposé par DIMA à `Inimitié` (`lateralAgenticConfront` `Q2`) et `Amour` (`Q1`) à `Haine de qq` (`Q2`) : DIMA privilégie l'axe relationnel positif/agressif (`Q1`↔`Q2`), alors que $\\mathcal{A}$ inverse simultanément Attente et Contrôle (`Q1`↔`Q3` et `Q2`↔`Q4`).")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    print("[MP5] Chargement de lexicon_v3_master, canonical_z0_z2_anchors et dima_normalized...")
    df, anchors_json, subsector_map = load_and_verify_inputs()
    print("[MP5] Vérification géométrique A sur 1 496/1 496 entrées : PASS (involutivité + échange L1-L4)")

    pairs_df = build_antagonism_pairs(df, subsector_map)
    PAIRS_PARQUET_PATH.parent.mkdir(parents=True, exist_ok=True)
    pairs_df.to_parquet(PAIRS_PARQUET_PATH, engine="pyarrow", index=False)
    pairs_df.to_csv(PAIRS_TSV_PATH, sep="\t", index=False, encoding="utf-8", lineterminator="\n")
    pairs_parquet_sha = sha256_file(PAIRS_PARQUET_PATH)
    pairs_tsv_sha = sha256_file(PAIRS_TSV_PATH)
    print(f"[MP5] Export antagonism_pairs_v3 : {len(pairs_df)} paires | parquet SHA256={pairs_parquet_sha}")
    print(f"[MP5] Export antagonism_pairs_v3.tsv SHA256={pairs_tsv_sha}")

    conflicts_df = build_dima_conflicts_audit(df, subsector_map)
    conflicts_df.to_csv(CONFLICTS_CSV_PATH, index=False, encoding="utf-8", lineterminator="\n")
    conflicts_csv_sha = sha256_file(CONFLICTS_CSV_PATH)
    print(f"[MP5] Export antagonism_audit_conflicts.csv : {len(conflicts_df)} paires | SHA256={conflicts_csv_sha}")

    report_md = render_mp5_report(
        df=df,
        anchors_json=anchors_json,
        pairs_df=pairs_df,
        conflicts_df=conflicts_df,
        pairs_parquet_sha=pairs_parquet_sha,
        pairs_tsv_sha=pairs_tsv_sha,
        conflicts_csv_sha=conflicts_csv_sha,
    )
    REPORT_MD_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_MD_PATH.write_text(report_md, encoding="utf-8", newline="\n")
    report_sha = sha256_file(REPORT_MD_PATH)
    print(f"[MP5] Export {REPORT_MD_PATH.relative_to(REPO_ROOT).as_posix()} SHA256={report_sha}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
