# SPDX-License-Identifier: AGPL-3.0-or-later
"""
test_lexicon_invariants.py — Suite de tests pytest bloquante (Micro-Passe 5)
vérifiant les invariants formels, géométriques, psychométriques et d'hygiène
du lexique CARTOGRAFFECT v3.0.0 sans modification de Cartograffect/.
"""

from __future__ import annotations

import importlib.util
import json
import re
import sys
from pathlib import Path

import numpy as np
import pandas as pd

REPO_ROOT = Path(__file__).resolve().parents[2]
PYTHON_DIR = REPO_ROOT / "python"
if str(PYTHON_DIR) not in sys.path:
    sys.path.insert(0, str(PYTHON_DIR))

from cartograffect_predictive_engine import antagoniste_noyau, repartir_rayon


def _load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, str(path))
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


MOD_MP4 = _load_module("mp4_project_surface", REPO_ROOT / "python" / "lexicon_pipeline" / "03_project_surface_v3.py")
MOD_MP5 = _load_module("mp5_compute_antagonism", REPO_ROOT / "python" / "lexicon_pipeline" / "04_compute_antagonism.py")

MASTER_PATH = REPO_ROOT / "data" / "processed" / "lexicon_v3_master.parquet"
PAIRS_PATH = REPO_ROOT / "data" / "processed" / "antagonism_pairs_v3.parquet"
CONFLICTS_PATH = REPO_ROOT / "data" / "processed" / "antagonism_audit_conflicts.csv"
DIMA_PATH = REPO_ROOT / "data" / "processed" / "dima_normalized.parquet"
ZMINUS_PATH = REPO_ROOT / "data" / "processed" / "dima_z_minus_reserve.parquet"
ANCHORS_JSON_PATH = REPO_ROOT / "data" / "config" / "canonical_z0_z2_anchors.json"
METAPHOR_CSV_PATH = REPO_ROOT / "data" / "config" / "z_plus_metaphor_exclusions.csv"
TAXONOMY_LEAN_PATH = REPO_ROOT / "Cartograffect" / "AffectiveTaxonomy.lean"


def _extract_lean_subsectors() -> set[str]:
    text = TAXONOMY_LEAN_PATH.read_text(encoding="utf-8")
    m = re.search(
        r"inductive\s+FunctionalSubsector\s+where(.*?)deriving\s+DecidableEq",
        text,
        flags=re.DOTALL,
    )
    assert m is not None, "Définition FunctionalSubsector introuvable dans AffectiveTaxonomy.lean"
    return set(re.findall(r"^\s*\|\s*([A-Za-z0-9_]+)\b", m.group(1), flags=re.MULTILINE))


def test_canonical_z0_z2_immutable() -> None:
    """Test 1 : intégrité exacte des 11 états Z0-Z2 + 3 opérateurs centraux Z3-Z5 et des 17 FunctionalSubsector."""
    anchors = json.loads(ANCHORS_JSON_PATH.read_text(encoding="utf-8"))
    lean_subsectors = _extract_lean_subsectors()
    assert len(lean_subsectors) == 17

    json_subsectors = {str(s["subsector_id"]) for s in anchors["functional_subsectors_17"]}
    assert json_subsectors == lean_subsectors

    master = pd.read_parquet(MASTER_PATH)
    assert len(master) == 1496
    assert master["lemma_id"].is_unique
    assert set(master["subsector_id"].unique()) == lean_subsectors

    counts = master["hemisphere_route"].value_counts().to_dict()
    assert counts == {
        "CANONICAL_LOCKED": 11,
        "CENTRAL_OPERATOR_LOCKED": 3,
        "Z_PLUS_ACTIVE": 542,
        "Z_PLUS_SATELLITE": 940,
    }

    sub_map = {str(s["subsector_id"]): s for s in anchors["functional_subsectors_17"]}
    by_id = master.set_index("lemma_id")

    for st in anchors["canonical_z0_z2_states"]:
        lid = f"canon_z{int(st['z'])}_{st['id']}"
        assert lid in by_id.index
        row = by_id.loc[lid]
        px, py, pz = [int(v) for v in st["point"]]
        ax, ay, az = [int(v) for v in st["antagonist_point"]]
        assert az == pz
        sid = str(st["subsector_id"])
        assert row["record_origin"] == "canonical_lean4"
        assert row["label_display"] == st["label_fr"]
        assert int(row["Z_stratum"]) == pz
        assert int(row["R_Z"]) == (0 if pz < 2 else 2 * pz - 2)
        assert (int(row["X_crown"]), int(row["Y_crown"])) == (px, py)
        assert (float(row["x"]), float(row["y"])) == (float(px), float(py))
        assert row["subsector_id"] == sid
        assert row["conjugate_subsector"] == sub_map[sid]["conjugate_subsector"]
        assert row["hedonic_polarity"] == st["hedonic_polarity"]
        assert (int(row["antagonist_X_crown"]), int(row["antagonist_Y_crown"])) == (ax, ay)

    for op in anchors["structured_taxonomy_central_operators_z3_z5"]:
        lid = f"central_z{int(op['z'])}_{op['id']}"
        assert lid in by_id.index
        row = by_id.loc[lid]
        assert row["record_origin"] == "central_operator_v3"
        assert row["label_display"] == op["label_fr"]
        assert int(row["Z_stratum"]) == int(op["z"])
        assert int(row["R_Z"]) == int(op["crown_radius"])
        assert (int(row["X_crown"]), int(row["Y_crown"])) == (0, 0)
        assert (float(row["x"]), float(row["y"])) == (0.0, 0.0)
        assert row["subsector_id"] == "centralOperator"
        assert row["conjugate_subsector"] == "centralOperator"
        assert row["hedonic_polarity"] == "neutral"
        assert (int(row["antagonist_X_crown"]), int(row["antagonist_Y_crown"])) == (0, 0)


def test_l1_surface_and_arousal_bounds() -> None:
    """Test 2 : |x|+|y| <= 2*floor(Z)-2 sur 100 % des 1 496 lignes, |u_X|+|u_Y|=1 et A in [0.15, 1.00] sur 1 429 périphériques DIMA, garde delta=0.05."""
    master = pd.read_parquet(MASTER_PATH)
    assert len(master) == 1496

    z_vals = master["Z_stratum"].to_numpy(dtype=int)
    expected_rz = np.where(z_vals < 2, 0, 2 * np.floor(z_vals).astype(int) - 2)
    l1_xy = np.abs(master["x"].to_numpy(dtype=float)) + np.abs(master["y"].to_numpy(dtype=float))
    assert np.all(l1_xy <= expected_rz + 1e-12)
    assert np.array_equal(master["R_Z"].to_numpy(dtype=int), expected_rz)

    periph_dima = master[
        (master["record_origin"] == "dima_z_plus_projected")
        & (master["subsector_id"] != "centralOperator")
    ]
    assert len(periph_dima) == 1429

    u_l1 = np.abs(periph_dima["u_X"].to_numpy(dtype=float)) + np.abs(periph_dima["u_Y"].to_numpy(dtype=float))
    assert np.allclose(u_l1, 1.0, atol=1e-12)

    a_norm = periph_dima["A_norm"].to_numpy(dtype=float)
    assert np.all((a_norm >= 0.15 - 1e-12) & (a_norm <= 1.00 + 1e-12))

    periph_l1 = np.abs(periph_dima["x"].to_numpy(dtype=float)) + np.abs(periph_dima["y"].to_numpy(dtype=float))
    assert np.allclose(periph_l1, a_norm * periph_dima["R_Z"].to_numpy(dtype=float), atol=1e-12)

    laterals = master[master["subsector_id"].str.startswith("lateral")]
    assert len(laterals) > 0
    minor_u = np.minimum(np.abs(laterals["u_X"].to_numpy(dtype=float)), np.abs(laterals["u_Y"].to_numpy(dtype=float)))
    assert np.all(minor_u >= 0.05 - 1e-12)
    assert np.all(minor_u <= 0.45 + 1e-12)
    assert np.all(np.abs(laterals["X_crown"].to_numpy(dtype=int)) != np.abs(laterals["Y_crown"].to_numpy(dtype=int)))


def test_apportion_ray_idempotent() -> None:
    """Test 3 : apportionRay(X, Y, Z) == (X, Y) sur l'ensemble des 84 points entiers (Z in {2..5})."""
    total_points = 0
    for z in (2, 3, 4, 5):
        r = 2 * z - 2
        pts = [(0, 0)]
        for x in range(-r, r + 1):
            for y in range(-r, r + 1):
                if abs(x) + abs(y) == r:
                    pts.append((x, y))
        total_points += len(pts)
        for x, y in pts:
            assert MOD_MP4.apportion_ray(float(x), float(y), z) == (x, y)
            if abs(x) >= 1 and abs(y) >= 1:
                assert repartir_rayon(z - 2, abs(x), abs(y)) == (abs(x), abs(y))
    assert total_points == 84


def test_antagonist_involutive_and_contralateral_swap() -> None:
    """Test 4 : involutivité stricte de A sur rayons et couronnes (100 % des 1 496 entrées) et échange |X| <-> |Y| sur 100 % des latéraux."""
    master = pd.read_parquet(MASTER_PATH)
    anchors = json.loads(ANCHORS_JSON_PATH.read_text(encoding="utf-8"))
    sub_map = {str(s["subsector_id"]): s for s in anchors["functional_subsectors_17"]}

    lat_count = 0
    for row in master.itertuples(index=False):
        ux, uy, z = float(row.u_X), float(row.u_Y), int(row.Z_stratum)
        xc, yc = int(row.X_crown), int(row.Y_crown)
        sid = str(row.subsector_id)
        exp_conj = sub_map[sid]["conjugate_subsector"]

        ax_u, ay_u, az_u = MOD_MP5.antagonist_ray(ux, uy, z)
        aax_u, aay_u, aaz_u = MOD_MP5.antagonist_ray(ax_u, ay_u, az_u)
        assert az_u == z and aaz_u == z
        assert abs(aax_u - ux) < 1e-12 and abs(aay_u - uy) < 1e-12
        assert MOD_MP5.classify_subsector_py(ax_u, ay_u) == exp_conj

        ax_c, ay_c, az_c = MOD_MP5.antagonist_crown(xc, yc, z)
        aax_c, aay_c, aaz_c = MOD_MP5.antagonist_crown(ax_c, ay_c, az_c)
        assert (aax_c, aay_c, aaz_c) == (xc, yc, z)
        assert (ax_c, ay_c, az_c) == antagoniste_noyau(xc, yc, z)
        assert (ax_c, ay_c) == (int(row.antagonist_X_crown), int(row.antagonist_Y_crown))
        assert MOD_MP5.classify_subsector_py(ax_c, ay_c) == exp_conj

        if sid == "centralOperator":
            assert (ax_u, ay_u) == (0.0, 0.0)
            assert (ax_c, ay_c) == (0, 0)
        else:
            assert not (abs(ax_u - ux) < 1e-12 and abs(ay_u - uy) < 1e-12)
            assert (ax_c, ay_c) != (xc, yc)

        if sid.startswith("lateral"):
            lat_count += 1
            assert abs(abs(ax_u) - abs(uy)) < 1e-12
            assert abs(abs(ay_u) - abs(ux)) < 1e-12
            assert abs(ax_c) == abs(yc) and abs(ay_c) == abs(xc)
            assert ax_u * ux < 0.0 and ay_u * uy < 0.0

    assert lat_count > 0


def test_autonomous_activation_decoupled() -> None:
    """Test 5 : coexistence des régimes iso_energetic et asymmetric_arousal sans pénalité sur |A - A'|."""
    pairs = pd.read_parquet(PAIRS_PATH)
    assert len(pairs) > 500
    assert MOD_MP5.WEIGHT_DELTA_A == 0.0

    calc_delta_a = np.abs(pairs["source_A_norm"].to_numpy(dtype=float) - pairs["target_A_norm"].to_numpy(dtype=float))
    assert np.allclose(pairs["delta_A"].to_numpy(dtype=float), calc_delta_a, atol=1e-12)
    expected_regime = np.where(calc_delta_a <= 0.25 + 1e-12, "iso_energetic", "asymmetric_arousal")
    assert list(pairs["activation_pair_regime"]) == expected_regime.tolist()

    periph_same_z = pairs[
        (pairs["source_record_origin"] == "dima_z_plus_projected")
        & (pairs["source_subsector_id"] != "centralOperator")
        & (pairs["same_Z_match"])
    ]
    regimes = set(periph_same_z["activation_pair_regime"].unique())
    assert regimes == {"iso_energetic", "asymmetric_arousal"}

    # Exemples concrets asymétriques et iso-énergétiques à même Z
    col_calme = periph_same_z[
        (periph_same_z["source_lemme_norm"] == "colère")
        & (periph_same_z["target_lemme_norm"] == "calme")
    ]
    assert len(col_calme) >= 1
    assert (col_calme["activation_pair_regime"] == "asymmetric_arousal").all()

    ang_ser = periph_same_z[
        (periph_same_z["source_lemme_norm"] == "angoisse")
        & (periph_same_z["target_lemme_norm"] == "sérénité")
    ]
    assert len(ang_ser) >= 1
    assert (ang_ser["activation_pair_regime"] == "asymmetric_arousal").all()

    fierte_honte = periph_same_z[
        (periph_same_z["source_lemme_norm"] == "fierté")
        & (periph_same_z["target_lemme_norm"] == "honte")
    ]
    assert len(fierte_honte) >= 1
    assert (fierte_honte["activation_pair_regime"] == "iso_energetic").all()

    # Invariance stricte du score de classement sous perturbation de A_norm
    src_ex = {
        "lemme_norm": "angoisse",
        "part_disc": "NOM",
        "classe": "Inquiéter",
        "antonymie": "Rassurer-Inquiéter & Effrayer",
        "entrees_antonymes": None,
        "A_norm": 0.84,
    }
    cand_lo = {
        "lemma_id": "x_lo",
        "lemme_norm": "sérénité",
        "part_disc": "NOM",
        "classe": "Rassurer",
        "antonymie": "Rassurer-Inquiéter & Effrayer",
        "entrees_antonymes": None,
        "metric_provenance": "nrc_override",
        "u_X": 0.45,
        "u_Y": 0.55,
        "A_norm": 0.18,
    }
    cand_hi = {**cand_lo, "A_norm": 0.99}
    s_lo = MOD_MP5.score_antagonist_candidate(src_ex, cand_lo, 0.228, 0.772)
    s_hi = MOD_MP5.score_antagonist_candidate(src_ex, cand_hi, 0.228, 0.772)
    assert s_lo["composite_score"] == s_hi["composite_score"]
    assert s_lo["sort_key"] == s_hi["sort_key"]


def test_option1a_and_hygiene() -> None:
    """Test 6 : 0 violation Option 1A, 0 satellite orphelin, 0 métaterme classifieur et 0 homographe FANCat parasite dans Z_PLUS_ACTIVE."""
    master = pd.read_parquet(MASTER_PATH)
    dima = pd.read_parquet(DIMA_PATH)
    excl_df = pd.read_csv(METAPHOR_CSV_PATH, encoding="utf-8", dtype=str)

    dima_proj = master[master["record_origin"] == "dima_z_plus_projected"]
    assert len(dima_proj) == 1482

    # Verrous Option 1A
    for row in dima_proj.itertuples(index=False):
        cl = str(row.classe)
        sc = "" if pd.isna(row.sous_classe) else str(row.sous_classe).strip()
        sid = str(row.subsector_id)
        ux = float(row.u_X)
        uy = float(row.u_Y)
        if cl in MOD_MP4.LOCK_1AA_CLASSES:
            assert uy <= 0.0, f"Violation 1A-a : {row.lemma_id}"
        if sid in MOD_MP4.Q2_SUBSECTORS:
            assert (cl in MOD_MP4.LOCK_1AB_ALLOWED_Q2_CLASSES) or ((cl, sc) in MOD_MP4.LOCK_1AB_ALLOWED_Q2_OVERRIDES), (
                f"Violation 1A-b : {row.lemma_id}"
            )
        if cl in MOD_MP4.LOCK_1AC_SECURITY_HAPPINESS_CLASSES:
            assert uy >= 0.0, f"Violation 1A-c : {row.lemma_id}"
        if cl == "Rassurer" and sc in {"sérénité", "tranquilliser", "insouciance"}:
            assert uy > 0.0
        if cl == "Résignation" and sc == "acceptation":
            assert ux > 0.0 and uy < 0.0

    # 0 satellite orphelin
    act = master[master["hemisphere_route"] == "Z_PLUS_ACTIVE"]
    sat = master[master["hemisphere_route"] == "Z_PLUS_SATELLITE"]
    assert len(act) == 542 and len(sat) == 940
    assert sat["parent_lemma_id"].notna().all()
    assert set(sat["parent_lemma_id"]).issubset(set(act["lemma_id"]))

    # 0 métaterme classifieur et 0 exclusion de z_plus_metaphor_exclusions.csv dans Z_PLUS_ACTIVE
    assert int((master["pruning_bucket"] == "META_CLASSIFIER").sum()) == 0
    assert int(act["lemme_norm"].isin({"affect", "affectivité", "émotion"}).sum()) == 0
    # Note : `dima|Amour|NOM|sentiment` (DIMA 2, classe Amour = sentiment amoureux) est un emploi lexical légitime ;
    # les 4 métatermes classifieurs exclus en MP1c sont ceux de CLASSE=Troubler / Z Classifieurs / Sentiment classifieur.
    act_keys = set(zip(act["lemme_norm"], act["part_disc"], act["classe"]))
    for erow in excl_df.itertuples(index=False):
        key = (str(erow.lemme_norm).strip().lower(), str(erow.part_disc).strip(), str(erow.classe).strip())
        assert key not in act_keys, f"Terme exclu présent dans Z_PLUS_ACTIVE : {key}"
        d_match = dima[
            (dima["lemme_norm"] == key[0])
            & (dima["part_disc"] == key[1])
            & (dima["classe"] == key[2])
        ]
        assert len(d_match) == 1
        assert str(d_match.iloc[0]["pruning_bucket"]) == str(erow.target_bucket).strip()

    # 0 homographe FANCat parasite dans Z_PLUS_ACTIVE
    forbidden_glosses = {"roach", "transportation", "laughter", "mood", "thirst"}
    assert int(act["en_matched_term"].isin(forbidden_glosses).sum()) == 0


def test_z_minus_reserve_lossless() -> None:
    """Test 7 : intégrité de la partition sans perte (3 342 entrées DIMA dédupliquées, dont la réserve -Z intacte)."""
    dima = pd.read_parquet(DIMA_PATH)
    zmin = pd.read_parquet(ZMINUS_PATH)
    master = pd.read_parquet(MASTER_PATH)

    assert len(dima) == 3342
    assert dima.duplicated(subset=["lemme_norm", "part_disc", "classe", "categ"]).sum() == 0

    route_counts = dima["hemisphere_route"].value_counts().to_dict()
    assert route_counts == {
        "Z_MINUS_RESERVE": 1367,
        "Z_PLUS_SATELLITE": 945,
        "Z_PLUS_ACTIVE": 549,
        "NON_LEXICAL_DISCARD": 481,
    }
    assert sum(route_counts.values()) == 3342

    assert len(zmin) == 1367
    assert (zmin["hemisphere_route"] == "Z_MINUS_RESERVE").all()
    dima_zmin = dima[dima["hemisphere_route"] == "Z_MINUS_RESERVE"].reset_index(drop=True)
    pd.testing.assert_frame_equal(
        zmin.sort_values(["categ", "classe", "lemme_norm", "part_disc"], kind="mergesort").reset_index(drop=True),
        dima_zmin.sort_values(["categ", "classe", "lemme_norm", "part_disc"], kind="mergesort").reset_index(drop=True),
    )

    # Conservation exacte de MP1c -> MP4 : 1482 projetés + 12 (7+5) déplacés vers -Z en MP3b + 1367 -Z + 481 discard == 3342
    dima_proj = master[master["record_origin"] == "dima_z_plus_projected"]
    assert len(dima_proj) == 1482
    moved_classes = {"Croyance", "Croyance relig", "Incrédulité", "Incrédulité relig", "Pudeur"}
    moved_dima = dima[
        dima["classe"].isin(moved_classes)
        & dima["hemisphere_route"].isin(["Z_PLUS_ACTIVE", "Z_PLUS_SATELLITE"])
    ]
    assert len(moved_dima) == 12
    assert len(dima_proj) + len(moved_dima) + len(zmin) + route_counts["NON_LEXICAL_DISCARD"] == 3342
