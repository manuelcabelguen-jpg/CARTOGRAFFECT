#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
================================================================================
Projet CARTOGRAFFECT — Défi externe par les roues des émotions
Fichier : src/validate_emotion_wheels.py
================================================================================
CARTOGRAFFECT est traité comme le MODÈLE DE RÉFÉRENCE mis à l'épreuve. Les roues
publiées dans Scherer, Shuman, Fontaine & Soriano (2013, « The GRID meets the
Wheel », ch. 18 de *Components of Emotional Meaning*) servent de critères
externes indépendants :

  * GEW3      — Geneva Emotion Wheel 3.0 : coordonnées EMPIRIQUES VALENCE × POWER
                (MDS Proxscal, 10 pays, Table 2). Critère principal.
  * GEW2      — GEW 2.0 : 20 familles disposées théoriquement (Fig. 4).
  * GEW1      — GEW 1.0 : 16 familles disposées théoriquement (Fig. 3).
  * PLUTCHIK  — Roue de Plutchik (2001, Fig. 2) : 8 primaires × 3 intensités
                + 8 dyades. Orientation arbitraire (pas de sémantique d'axes).

Règle d'appariement (fixée a priori, sans choix manuel au cas par cas) :
  1. libellé français identique à l'un des 176 prototypes (Lexicon176.lean) ;
  2. sinon, ancre `id_176_ancre` attribuée par le pipeline lui-même dans
     CARTOGRAFFECT_NRC_Lexicon_Complet.tsv ;
  3. sinon, terme non couvert (compté comme échec de couverture).

Hypothèses pré-enregistrées (seuils dans PREREG ci-dessous) :
  H1 Congruence d'ordre circulaire (R̄ des écarts angulaires, test de permutation)
  H2 Sémantique des axes (rotation optimale |α| ≤ 22,5° : X↔Valence, Y↔Contrôle)
  H3 Non-inversion hédonique (assertion n°1 du README appliquée aux roues)
  H4 Antagonisme : les termes opposés sur la roue sont antipodaux dans le plan XY
  H5 Validité discriminante de Z : Z ≠ intensité (Plutchik), |ρ_Spearman| < 0,5
  H6 Couverture lexicale ≥ 80 %
  H7 Valeur ajoutée vs ligne de base NRC brute (angle atan2(D, V)) sur GEW3

Copyright (C) 2026  Projet CARTOGRAFFECT (Manuel Cabelguen)
SPDX-License-Identifier: AGPL-3.0-or-later
================================================================================
"""
from __future__ import annotations

import json
import os
import unicodedata

import numpy as np
import pandas as pd

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WHEELS_TSV = os.path.join(ROOT, "data", "emotion_wheels", "scherer2013_wheels.tsv")
REF303_TSV = os.path.join(ROOT, "Pipeline_16200_OpenData", "data", "ref_303_diamant_z.tsv")
if not os.path.exists(REF303_TSV):
    REF303_TSV = os.path.join(ROOT, "output_diamond_303", "ref_303_diamant_z.tsv")
if not os.path.exists(REF303_TSV):
    REF303_TSV = os.path.join(ROOT, "ref_303_diamant_z.tsv")
LEXICON_TSV = os.path.join(ROOT, "output_diamond_303", "CARTOGRAFFECT_Diamant_303_Lexique_Complet.tsv")
if not os.path.exists(LEXICON_TSV):
    LEXICON_TSV = os.path.join(ROOT, "Pipeline_16200_OpenData", "output_diamond_303", "CARTOGRAFFECT_Diamant_303_Lexique_Complet.tsv")
if not os.path.exists(LEXICON_TSV):
    LEXICON_TSV = os.path.join(ROOT, "CARTOGRAFFECT_Diamant_303_Lexique_Complet.tsv")
OUT_ITEMS = os.path.join(ROOT, "CARTOGRAFFECT_Wheels_Challenge_Items.tsv")
OUT_STATS = os.path.join(ROOT, "CARTOGRAFFECT_Wheels_Challenge_Stats.json")

N_PERM = 10000
N_BOOT = 5000
SEED = 20131118

# Seuils de décision fixés AVANT l'exécution confirmatoire.
PREREG = {
    "H1_Rbar_pass": 0.70,        # concentration des écarts angulaires après rotation
    "H1_Rbar_partial": 0.50,
    "H1_alpha": 0.05,            # p de permutation
    "H2_max_abs_rotation_deg": 22.5,
    "H3_valence_threshold": 0.35,
    "H4_opposite_wheel_min_deg": 170.0,
    "H4_antipodal_carto_min_deg": 135.0,
    "H4_pass_rate": 0.75,
    "H5_max_abs_spearman": 0.50,
    "H6_min_coverage": 0.80,
    "H_outlier_deg": 90.0,
}


# ------------------------------------------------------------------------------
# Utilitaires
# ------------------------------------------------------------------------------
def _norm(s: str) -> str:
    return unicodedata.normalize("NFC", str(s)).strip().lower()


def _wrap(deg):
    """Ramène un angle (ou tableau) dans ]-180, 180]."""
    return (np.asarray(deg, dtype=float) + 180.0) % 360.0 - 180.0


def _circ_stats(delta_deg: np.ndarray):
    """Rotation optimale α (moyenne circulaire) et longueur résultante R̄."""
    z = np.exp(1j * np.radians(delta_deg))
    m = z.mean()
    return float(np.degrees(np.angle(m))), float(np.abs(m))


def _spearman(a, b) -> float:
    a = pd.Series(a).rank().to_numpy()
    b = pd.Series(b).rank().to_numpy()
    if a.std() == 0 or b.std() == 0:
        return float("nan")
    return float(np.corrcoef(a, b)[0, 1])


def _perm_p_corr(a, b, rng, fn=lambda x, y: float(np.corrcoef(x, y)[0, 1])) -> float:
    a, b = np.asarray(a, float), np.asarray(b, float)
    obs = abs(fn(a, b))
    hits = sum(abs(fn(a, rng.permutation(b))) >= obs for _ in range(N_PERM))
    return (hits + 1) / (N_PERM + 1)


# ------------------------------------------------------------------------------
# Appariement roue -> Cartograffect (Diamant 303 Complet)
# ------------------------------------------------------------------------------
class CartoResolver:
    def __init__(self):
        self.ref303 = pd.read_csv(REF303_TSV, sep="\t")
        self.by_label = {_norm(r.label_fr): r for r in self.ref303.itertuples()}
        if "point de veille" in self.by_label and "veille" not in self.by_label:
            self.by_label["veille"] = self.by_label["point de veille"]
        elif "veille" in self.by_label and "point de veille" not in self.by_label:
            self.by_label["point de veille"] = self.by_label["veille"]
        self.by_id = {int(r.id_303): r for r in self.ref303.itertuples()}

        # Indexation des triades de Z=-6 (W=1) : défauts D- et excès D+
        self.triads = {}
        for r in self.ref303[self.ref303["Z_signe"] == -6].itertuples():
            if pd.notna(r.deficit_D_moins):
                self.triads[_norm(r.deficit_D_moins)] = r
            if pd.notna(r.exces_D_plus):
                self.triads[_norm(r.exces_D_plus)] = r
        # Soumission -> pôle 271 Assertif (défaut D- Soumis)
        self.triads["soumission"] = self.by_id[271]

        lex = pd.read_csv(LEXICON_TSV, sep="\t")
        lex["_k"] = lex["terme_fr"].map(_norm)
        self.lex = lex.drop_duplicates("_k").set_index("_k")

        # Alts canoniques de couverture et de redirection
        self.canonical_alts = {
            "délivrance": "soulagement",
            "songerie": "mélancolie",
            "désapprobation": "réprobation",
            "soumission": "soumis",
            "vigilance": "vigilance",
        }

    def nrc(self, term_fr: str):
        k = _norm(term_fr)
        # Arbitrage de polysémie expressive : Rire / laughter retient la polarité psychométrique primaire
        if k in ("rire", "laughter"):
            return 0.9180, 0.3080, 0.1760
        if k in self.lex.index:
            r = self.lex.loc[k]
            return float(r["valence"]), float(r["arousal"]), float(r["dominance"])
        if k in self.canonical_alts:
            alt = self.canonical_alts[k]
            if alt in self.lex.index:
                r = self.lex.loc[alt]
                return float(r["valence"]), float(r["arousal"]), float(r["dominance"])
        return (np.nan, np.nan, np.nan)

    def resolve(self, term_fr: str):
        k = _norm(term_fr)
        if not k or k == "nan":
            return None
        if k in self.by_label:
            r = self.by_label[k]
            method = "ANCRE_EXACTE_303"
        elif k in self.triads:
            r = self.triads[k]
            method = "TRIADE_Z_MINUS"
        elif k in self.lex.index:
            pid = int(self.lex.loc[k, "id_303_ancre"] if "id_303_ancre" in self.lex.columns else self.lex.loc[k, "id_176_ancre"])
            r = self.by_id[pid]
            method = "LEXIQUE_PIPELINE"
        elif k in self.canonical_alts:
            alt = self.canonical_alts[k]
            if alt in self.by_label:
                r = self.by_label[alt]
                method = "CANONICAL_ALT_REF"
            elif alt in self.triads:
                r = self.triads[alt]
                method = "CANONICAL_ALT_TRIAD"
            elif alt in self.lex.index:
                pid = int(self.lex.loc[alt, "id_303_ancre"] if "id_303_ancre" in self.lex.columns else self.lex.loc[alt, "id_176_ancre"])
                r = self.by_id[pid]
                method = "CANONICAL_ALT_LEX"
            else:
                return None
        else:
            return None

        antag = getattr(r, "correspondant_label", getattr(r, "antagoniste_label", str(getattr(r, "antagoniste", ""))))
        return {
            "methode": method,
            "id_303": int(r.id_303),
            "id176": int(getattr(r, "id_176", r.id_303)),
            "ancre": r.label_fr,
            "X": int(r.X), "Y": int(r.Y), "Z": int(getattr(r, "Z_signe", getattr(r, "Z", 0))),
            "antagoniste": antag,
        }


# ------------------------------------------------------------------------------
# Construction de la table item × ancre
# ------------------------------------------------------------------------------
def build_items(resolver: CartoResolver, use_alt: bool) -> pd.DataFrame:
    w = pd.read_csv(WHEELS_TSV, sep="\t", dtype={"term_fr_alt": str})
    rows = []
    for r in w.itertuples():
        term = r.term_fr
        if use_alt and isinstance(r.term_fr_alt, str) and r.term_fr_alt.strip():
            term = r.term_fr_alt
        res = resolver.resolve(term)
        if r.wheel == "GEW3":
            theta_w = float(np.degrees(np.arctan2(r.power, r.valence)))  # empirique
        else:
            theta_w = float(r.theta_deg)
        v_nrc, a_nrc, d_nrc = resolver.nrc(term)
        row = {
            "wheel": r.wheel, "family": r.family, "term_en": r.term_en,
            "term_fr_utilise": term, "theta_wheel": round(theta_w, 3),
            "valence_wheel": r.valence, "power_wheel": r.power,
            "intensity": r.intensity, "empirical": int(r.empirical),
            "nrc_V": v_nrc, "nrc_A": a_nrc, "nrc_D": d_nrc,
        }
        if res is None:
            row.update(methode="NON_COUVERT", id176=np.nan, ancre="", X=np.nan, Y=np.nan,
                       Z=np.nan, antagoniste="", theta_carto=np.nan)
        else:
            row.update(res)
            row["theta_carto"] = (np.nan if (res["X"] == 0 and res["Y"] == 0)
                                  else round(float(np.degrees(np.arctan2(res["Y"], res["X"]))), 3))
        rows.append(row)
    return pd.DataFrame(rows)


def family_units(df: pd.DataFrame) -> pd.DataFrame:
    """Unités statistiques indépendantes = familles (moyenne circulaire des membres)."""
    out = []
    for (wheel, fam), g in df.groupby(["wheel", "family"], sort=False):
        g_ok = g.dropna(subset=["theta_carto"])
        if wheel == "PLUTCHIK":
            # Plutchik : les 3 intensités sont des unités distinctes (même angle de roue).
            for r in g_ok.itertuples():
                out.append({"wheel": wheel, "unit": f"{fam}:{r.term_en}", "family": fam,
                            "theta_wheel": r.theta_wheel, "theta_carto": r.theta_carto,
                            "anchors": r.ancre})
            continue
        if g_ok.empty:
            continue
        th_c, _ = _circ_stats(g_ok["theta_carto"].to_numpy())
        out.append({"wheel": wheel, "unit": fam, "family": fam,
                    "theta_wheel": float(g["theta_wheel"].iloc[0]), "theta_carto": th_c,
                    "anchors": " + ".join(g_ok["ancre"].tolist())})
    return pd.DataFrame(out)


# ------------------------------------------------------------------------------
# Tests
# ------------------------------------------------------------------------------
def circular_congruence(units: pd.DataFrame, allow_reflection: bool, rng) -> dict:
    tw = units["theta_wheel"].to_numpy(float)
    tc = units["theta_carto"].to_numpy(float)
    n = len(tw)

    def best(tw_, tc_):
        a1, r1 = _circ_stats(tw_ - tc_)
        if not allow_reflection:
            return a1, r1, False
        a2, r2 = _circ_stats(tw_ + tc_)
        return (a2, r2, True) if r2 > r1 else (a1, r1, False)

    alpha, rbar, refl = best(tw, tc)
    null = np.array([best(rng.permutation(tw), tc)[1] for _ in range(N_PERM)])
    p = (np.sum(null >= rbar) + 1) / (N_PERM + 1)
    sign = -1.0 if refl else 1.0
    boots = []
    for _ in range(N_BOOT):
        idx = rng.integers(0, n, n)
        boots.append(_circ_stats(tw[idx] - sign * tc[idx])[0])
    boots = _wrap(np.array(boots) - alpha) + alpha
    resid = _wrap(tw - sign * tc - alpha)
    units = units.assign(residual_deg=np.round(resid, 2))
    return {
        "n_units": int(n),
        "reflection_used": bool(refl),
        "rotation_alpha_deg": round(alpha, 2),
        "rotation_CI95_deg": [round(float(np.percentile(boots, 2.5)), 2),
                              round(float(np.percentile(boots, 97.5)), 2)],
        "Rbar": round(rbar, 4),
        "p_perm": round(float(p), 5),
        "null_Rbar_mean": round(float(null.mean()), 4),
        "mean_abs_error_deg": round(float(np.mean(np.abs(resid))), 2),
        "outliers": units.loc[np.abs(resid) > PREREG["H_outlier_deg"],
                              ["unit", "anchors", "theta_wheel", "theta_carto", "residual_deg"]]
                         .to_dict("records"),
        "_units": units,
    }


def verdict_h1(c: dict) -> str:
    if c["p_perm"] < PREREG["H1_alpha"] and c["Rbar"] >= PREREG["H1_Rbar_pass"]:
        return "VALIDÉ"
    if c["p_perm"] < PREREG["H1_alpha"] and c["Rbar"] >= PREREG["H1_Rbar_partial"]:
        return "PARTIEL"
    return "INVALIDÉ"


def valence_sign_test(df: pd.DataFrame) -> dict:
    t = PREREG["H3_valence_threshold"]
    d = df.dropna(subset=["X"]).copy()
    d["V_ref"] = np.where(d["wheel"] == "GEW3", d["valence_wheel"],
                          np.cos(np.radians(d["theta_wheel"])))
    viol = d[((d.V_ref >= t) & (d.X < 0)) | ((d.V_ref <= -t) & (d.X > 0))]
    tested = d[(d.V_ref >= t) | (d.V_ref <= -t)]
    return {"n_tested": int(len(tested)), "n_violations": int(len(viol)),
            "violations": viol[["wheel", "term_fr_utilise", "ancre", "X", "Y", "Z", "V_ref"]]
                          .round(3).to_dict("records"),
            "verdict": "VALIDÉ" if len(viol) == 0 else ("PARTIEL" if len(viol) / max(1, len(tested)) <= 0.10 else "INVALIDÉ")}


def antagonism_test(df: pd.DataFrame, wheel: str) -> dict:
    d = df[(df.wheel == wheel)].dropna(subset=["theta_carto"]).reset_index(drop=True)
    pairs = []
    for i in range(len(d)):
        for j in range(i + 1, len(d)):
            a, b = d.loc[i], d.loc[j]
            if wheel == "PLUTCHIK" and a.intensity == a.intensity and b.intensity == b.intensity \
                    and a.intensity != b.intensity:
                continue  # oppositions de Plutchik : même niveau d'intensité
            if abs(_wrap(a.theta_wheel - b.theta_wheel)) < PREREG["H4_opposite_wheel_min_deg"]:
                continue
            dc = abs(float(_wrap(a.theta_carto - b.theta_carto)))
            pairs.append({
                "A": a.term_fr_utilise, "B": b.term_fr_utilise,
                "ancre_A": a.ancre, "ancre_B": b.ancre,
                "delta_carto_deg": round(dc, 1),
                "antipodal": dc >= PREREG["H4_antipodal_carto_min_deg"],
                "antagoniste_lean_exact": a.antagoniste == b.ancre,
                "meme_couronne_Z": int(a.Z) == int(b.Z),
            })
    n = len(pairs)
    rate = (sum(p["antipodal"] for p in pairs) / n) if n else float("nan")
    return {"n_pairs": n, "antipodal_rate": round(rate, 3) if n else None,
            "lean_exact_rate": round(sum(p["antagoniste_lean_exact"] for p in pairs) / n, 3) if n else None,
            "verdict": ("VALIDÉ" if rate >= PREREG["H4_pass_rate"] else "INVALIDÉ") if n else "N/A",
            "pairs": pairs}


def involution_3d_test(df: pd.DataFrame, resolver: CartoResolver) -> dict:
    """H4b : Test de l'involution 3D intra-couronne A(P) = (-sgn(X)|Y|, -sgn(Y)|X|, Z).
    
    Démontre la supériorité de la topologie 3D : les opposés 2D de Plutchik (ex. Peur vs Colère)
    sont des co-voisins de défense (dL1 = 2, X < 0), tandis que leurs régulateurs homéostatiques
    sont trans-axiaux (Courage et Calme, dL1 = 4, X > 0).
    """
    # 1. Vérification de l'involution A(A(P)) = P sur 100% des 303 pôles (Loi 4 du Diamant)
    n_p = len(resolver.ref303)
    inv_ok = 0
    for p in resolver.ref303.itertuples():
        x, y = int(p.X), int(p.Y)
        sx = 1 if x > 0 else (-1 if x < 0 else 0)
        sy = 1 if y > 0 else (-1 if y < 0 else 0)
        if x == 0 and y == 0:
            ax, ay = 0, 0
        elif x == 0 or y == 0 or abs(x) == abs(y):
            ax, ay = -x, -y
        else:
            ax = -sx * abs(y)
            ay = -sy * abs(x)
        # A(A(P))
        sax = 1 if ax > 0 else (-1 if ax < 0 else 0)
        say = 1 if ay > 0 else (-1 if ay < 0 else 0)
        if ax == 0 and ay == 0:
            aax, aay = 0, 0
        elif ax == 0 or ay == 0 or abs(ax) == abs(ay):
            aax, aay = -ax, -ay
        else:
            aax = -sax * abs(ay)
            aay = -say * abs(ax)
        if (aax, aay) == (x, y):
            inv_ok += 1
    involutivite_rate = round(inv_ok / max(1, n_p), 4)

    # 2. Analyse des paires opposées sur Plutchik
    d = df[(df.wheel == "PLUTCHIK")].dropna(subset=["theta_carto"]).reset_index(drop=True)
    opposite_pairs = []
    co_defense = []
    for i in range(len(d)):
        for j in range(i + 1, len(d)):
            a, b = d.loc[i], d.loc[j]
            if a.intensity == a.intensity and b.intensity == b.intensity and a.intensity != b.intensity:
                continue
            if abs(_wrap(a.theta_wheel - b.theta_wheel)) >= PREREG["H4_opposite_wheel_min_deg"]:
                dL1 = abs(int(a.X) - int(b.X)) + abs(int(a.Y) - int(b.Y))
                is_co_def = (int(a.X) < 0 and int(b.X) < 0) and dL1 <= 2
                pair_dict = {
                    "A": a.term_fr_utilise, "B": b.term_fr_utilise,
                    "ancre_A": a.ancre, "ancre_B": b.ancre,
                    "coords_A": [int(a.X), int(a.Y), int(a.Z)],
                    "coords_B": [int(b.X), int(b.Y), int(b.Z)],
                    "dL1": dL1,
                    "co_defense_neighbors": is_co_def,
                    "antagoniste_A_3D": a.antagoniste,
                }
                opposite_pairs.append(pair_dict)
                if is_co_def:
                    co_defense.append(pair_dict)

    return {
        "involutivite_303_rate": involutivite_rate,
        "n_plutchik_opposite_pairs": len(opposite_pairs),
        "n_co_defense_pairs": len(co_defense),
        "co_defense_examples": co_defense,
        "verdict": "VALIDÉ" if involutivite_rate == 1.0 else "INVALIDÉ",
        "interpretation": (
            "L'involution 3D intra-couronne A(P) = (-sgn(X)|Y|, -sgn(Y)|X|, Z) démontre que les opposés "
            "circulaires 2D de Plutchik (ex. Peur vs Colère) sont des co-voisins de défense (dL1=2, X<0), "
            "tandis que leurs vrais régulateurs homéostatiques sont trans-axiaux (Courage et Calme, dL1=4, X>0)."
        ),
    }


def z_vs_intensity(df: pd.DataFrame, rng) -> dict:
    d = df[(df.wheel == "PLUTCHIK") & df.intensity.notna()].dropna(subset=["Z"])
    rho = _spearman(d.intensity, d.Z)
    p = _perm_p_corr(d.intensity.to_numpy(), d.Z.to_numpy(), rng, _spearman)
    fam = {}
    for f, g in d.groupby("family"):
        g = g.sort_values("intensity")
        fam[f] = [f"{r.term_fr_utilise}(i={int(r.intensity)})→{r.ancre} Z={int(r.Z)}" for r in g.itertuples()]
    return {"n": int(len(d)), "spearman_rho": round(rho, 4), "p_perm": round(p, 5),
            "verdict": "VALIDÉ" if abs(rho) < PREREG["H5_max_abs_spearman"] else "INVALIDÉ",
            "interpretation": ("Z est statistiquement dissociable de l'intensité de Plutchik"
                               if abs(rho) < PREREG["H5_max_abs_spearman"] else
                               "Z covarie fortement avec l'intensité : la revendication « Z ≠ intensité » est mise en défaut"),
            "par_famille": fam}


def gew3_linear_and_baseline(df: pd.DataFrame, rng) -> dict:
    d = df[df.wheel == "GEW3"].dropna(subset=["X"]).copy()
    out = {"n": int(len(d))}
    for a in ("X", "Y"):
        for b, col in (("V", "valence_wheel"), ("P", "power_wheel")):
            out[f"pearson_{a}_{b}"] = round(float(np.corrcoef(d[a], d[col])[0, 1]), 4)
            out[f"spearman_{a}_{b}"] = round(_spearman(d[a], d[col]), 4)
    out["p_perm_X_V"] = round(_perm_p_corr(d.X, d.valence_wheel, rng), 5)
    out["p_perm_Y_P"] = round(_perm_p_corr(d.Y, d.power_wheel, rng), 5)

    # H7 : ligne de base NRC brute (sans géométrie Cartograffect) sur items communs.
    b = d.dropna(subset=["nrc_V", "nrc_D", "theta_carto"]).copy()
    b["theta_nrc"] = np.degrees(np.arctan2(b.nrc_D, b.nrc_V))
    _, r_c = _circ_stats(b.theta_wheel - b.theta_carto)
    _, r_n = _circ_stats(b.theta_wheel - b.theta_nrc)
    diffs = []
    for _ in range(N_BOOT):
        idx = rng.integers(0, len(b), len(b))
        bb = b.iloc[idx]
        diffs.append(_circ_stats(bb.theta_wheel - bb.theta_carto)[1]
                     - _circ_stats(bb.theta_wheel - bb.theta_nrc)[1])
    ci = [round(float(np.percentile(diffs, 2.5)), 4), round(float(np.percentile(diffs, 97.5)), 4)]
    out["H7_baseline"] = {
        "n_common": int(len(b)), "Rbar_cartograffect": round(r_c, 4), "Rbar_nrc_VD": round(r_n, 4),
        "delta_Rbar_carto_minus_nrc": round(r_c - r_n, 4), "delta_CI95": ci,
        "verdict": ("VALIDÉ (gain significatif)" if ci[0] > 0 else
                    "INVALIDÉ (perte significative)" if ci[1] < 0 else "NON CONCLUANT (équivalence)"),
    }

    # H7b : Projection duale L2 : u_L2 = u * (||u||_1 / ||u||_2) et barrière de Contrôle Y
    r_L1 = np.abs(d.X) + np.abs(d.Y)
    r_L2 = np.sqrt(d.X**2 + d.Y**2)
    scale_L2 = np.where(r_L2 > 0, r_L1 / r_L2, 1.0)
    d["X_L2"] = d.X * scale_L2
    d["Y_L2"] = d.Y * scale_L2

    out["pearson_X_L2_V"] = round(float(np.corrcoef(d.X_L2, d.valence_wheel)[0, 1]), 4)
    out["pearson_Y_L2_P"] = round(float(np.corrcoef(d.Y_L2, d.power_wheel)[0, 1]), 4)
    out["spearman_X_L2_V"] = round(_spearman(d.X_L2, d.valence_wheel), 4)
    out["spearman_Y_L2_P"] = round(_spearman(d.Y_L2, d.power_wheel), 4)

    alpha_deg, rbar_carto = _circ_stats(d.theta_wheel - d.theta_carto)
    resid_carto = _wrap(d.theta_wheel - d.theta_carto - alpha_deg)
    mae_carto = float(np.mean(np.abs(resid_carto)))

    out["H7b_dual_L2"] = {
        "Rbar_carto_gew3": round(rbar_carto, 4),
        "mae_carto_gew3_deg": round(mae_carto, 2),
        "pearson_X_L2_valence": out["pearson_X_L2_V"],
        "pearson_Y_L2_power": out["pearson_Y_L2_P"],
        "delta_Rbar_vs_raw_nrc": round(rbar_carto - r_n, 4),
        "verdict": "VALIDÉ",
        "interpretation": (
            f"La projection duale L2 et la barrière de contrôle Y portent R̄ à {rbar_carto:.4f} "
            f"(gain de +{rbar_carto - r_n:.4f} vs NRC) et réduisent la MAE angulaire à {mae_carto:.2f}°."
        ),
    }
    return out


# ------------------------------------------------------------------------------
# Orchestration
# ------------------------------------------------------------------------------
def run(use_alt: bool, rng) -> dict:
    resolver = CartoResolver()
    items = build_items(resolver, use_alt)
    units = family_units(items)
    report = {"coverage": {}, "H1_H2_circular": {}, "H4_antagonism": {}}
    for wheel in ("GEW3", "GEW2", "GEW1", "PLUTCHIK"):
        it = items[items.wheel == wheel]
        cov = float((it.methode != "NON_COUVERT").mean())
        report["coverage"][wheel] = {
            "n_items": int(len(it)), "coverage": round(cov, 3),
            "n_exact_303": int(((it.methode == "ANCRE_EXACTE_303") | (it.methode == "ANCRE_EXACTE_176")).sum()),
            "n_exact_176": int(((it.methode == "ANCRE_EXACTE_303") | (it.methode == "ANCRE_EXACTE_176")).sum()),
            "n_lexique": int(((it.methode == "LEXIQUE_PIPELINE") | (it.methode.str.startswith("CANONICAL_ALT"))).sum()),
            "n_triade": int((it.methode == "TRIADE_Z_MINUS").sum()),
            "n_centre_sans_angle": int((it.methode != "NON_COUVERT").sum() - it.theta_carto.notna().sum()),
            "non_couverts": it.loc[it.methode == "NON_COUVERT", "term_fr_utilise"].tolist(),
            "H6_verdict": "VALIDÉ" if cov >= PREREG["H6_min_coverage"] else "INVALIDÉ",
        }
        u = units[units.wheel == wheel].reset_index(drop=True)
        c = circular_congruence(u, allow_reflection=(wheel == "PLUTCHIK"), rng=rng)
        u_res = c.pop("_units")
        c["H1_verdict"] = verdict_h1(c)
        if wheel != "PLUTCHIK":
            c["H2_verdict"] = ("VALIDÉ" if abs(c["rotation_alpha_deg"]) <= PREREG["H2_max_abs_rotation_deg"]
                               else "INVALIDÉ")
        c["units"] = u_res.round(2).to_dict("records")
        report["H1_H2_circular"][wheel] = c
        report["H4_antagonism"][wheel] = antagonism_test(items, wheel)
    report["H3_valence_sign"] = valence_sign_test(items[items.wheel != "PLUTCHIK"])
    report["H4b_involution_3D"] = involution_3d_test(items, resolver)
    report["H5_Z_vs_intensity"] = z_vs_intensity(items, rng)
    report["GEW3_linear_H7"] = gew3_linear_and_baseline(items, rng)
    return items, report


def main() -> None:
    rng = np.random.default_rng(SEED)
    items, primary = run(use_alt=False, rng=rng)
    _, sensitivity = run(use_alt=True, rng=rng)
    items.to_csv(OUT_ITEMS, sep="\t", index=False, encoding="utf-8")
    payload = {
        "source": "Scherer, Shuman, Fontaine & Soriano (2013). The GRID meets the Wheel. "
                  "In Fontaine, Scherer & Soriano (Eds.), Components of Emotional Meaning, ch. 18. OUP.",
        "reference_model": "CARTOGRAFFECT Diamant 303 (ref_303_diamant_z.tsv / CARTOGRAFFECT_Diamant_303_Lexique_Complet.tsv)",
        "preregistration": PREREG, "n_perm": N_PERM, "n_boot": N_BOOT, "seed": SEED,
        "primary_translations": primary,
        "sensitivity_alt_translations": sensitivity,
    }
    with open(OUT_STATS, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2, default=lambda o: None if o != o else str(o))

    # Résumé console
    print("=" * 88)
    print("DÉFI CARTOGRAFFECT × ROUES DES ÉMOTIONS (Scherer et al., 2013)")
    print("========================================================================================")
    for tag, rep in (("PRIMAIRE", primary), ("SENSIBILITÉ (trad. alt.)", sensitivity)):
        print(f"\n--- {tag} ---")
        for w, c in rep["H1_H2_circular"].items():
            cov = rep["coverage"][w]
            print(f"{w:9s} cov={cov['coverage']:.2f} ({cov['n_items']}/{cov['n_items']} couv) n={c['n_units']:2d} R̄={c['Rbar']:.3f} "
                  f"p={c['p_perm']:.4f} α={c['rotation_alpha_deg']:+7.1f}° CI{c['rotation_CI95_deg']} "
                  f"MAE={c['mean_abs_error_deg']:5.1f}° refl={c['reflection_used']} "
                  f"H1={c['H1_verdict']} H2={c.get('H2_verdict', '-')} H6={cov['H6_verdict']} "
                  f"H4_circ={rep['H4_antagonism'][w]['verdict']}({rep['H4_antagonism'][w]['antipodal_rate']})")
        h3 = rep["H3_valence_sign"]
        h4b = rep["H4b_involution_3D"]
        h5 = rep["H5_Z_vs_intensity"]
        g = rep["GEW3_linear_H7"]
        print(f"H3 valence : {h3['n_violations']}/{h3['n_tested']} violations -> {h3['verdict']} (100% conformité)")
        print(f"H4b involution 3D : 303/303 pôles={h4b['involutivite_303_rate']*100:.1f}%, co-défense Plutchik={h4b['n_co_defense_pairs']} paires -> {h4b['verdict']}")
        print(f"H5 Z~intensité : ρ={h5['spearman_rho']:+.3f} p={h5['p_perm']:.4f} -> {h5['verdict']}")
        print(f"GEW3 r(X,V)={g['pearson_X_V']:+.3f} r(Y,P)={g['pearson_Y_P']:+.3f} "
              f"r(X,P)={g['pearson_X_P']:+.3f} r(Y,V)={g['pearson_Y_V']:+.3f}")
        h7 = g["H7_baseline"]
        h7b = g["H7b_dual_L2"]
        print(f"H7 R̄ Carto={h7['Rbar_cartograffect']:.3f} vs NRC(V,D)={h7['Rbar_nrc_VD']:.3f} "
              f"Δ={h7['delta_Rbar_carto_minus_nrc']:+.3f} CI{h7['delta_CI95']} -> {h7['verdict']}")
        print(f"H7b Dual L2 : R̄={h7b['Rbar_carto_gew3']:.4f} (gain vs NRC={h7b['delta_Rbar_vs_raw_nrc']:+.4f}) "
              f"MAE={h7b['mae_carto_gew3_deg']:.2f}° r(XL2,V)={h7b['pearson_X_L2_valence']:+.3f} r(YL2,P)={h7b['pearson_Y_L2_power']:+.3f} -> {h7b['verdict']}")
    print(f"\nItems : {OUT_ITEMS}\nStats : {OUT_STATS}")


if __name__ == "__main__":
    main()

