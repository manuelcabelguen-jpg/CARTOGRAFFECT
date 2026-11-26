"""[SYNTHETIC EXPLORATORY ONLY — V3 = 0]
QUARANTAINE EXPLORATOIRE — AUCUNE VALIDATION CLINIQUE OU NOSOLOGIQUE EXTERNE.
Ce script génère des agents synthétiques à partir de lois a priori paramétriques
définies dans le simulateur (zéro donnée patient humaine, V3 = 0). Les taux de
séparabilité, chevauchements entre cohortes simulées et réponses différentielles
aux perturbations paramétriques ne constituent aucune preuve nosologique ou
clinique réelle.

Expérience 5 : Simulation exploratoire synthétique sur 26 régimes paramétriques (inspirés DSM-5 / HiTOP).

Étend l'expérience 4 (8 cohortes conservées intactes) à un panorama complet de
26 régimes paramétriques dynamiques couvrant l'ensemble des grands chapitres
cliniques de la Section II du DSM-5 (APA, 2013) et 7 spectres dimensionnels
HiTOP, soit N_total = 26 × N agents (par défaut 26 × 100 = 2 600 agents) :
    - Référence : Normothymique
    - Neurodéveloppemental : TSA, TDAH
    - Spectre schizophrénique : Schizophrénie (profil positif), Schizophrénie (profil négatif)
    - Bipolaire : Épisode maniaque, Dépression bipolaire / mixte
    - Dépressif : TDC inhibé
    - Anxieux : TAG, Trouble panique, Anxiété sociale, Phobie spécifique
    - TOC et apparentés : TOC
    - Traumatismes et stresseurs : TSPT (bimodal hypervigilance / dissociation)
    - Dissociatif : Trouble de dépersonnalisation / déréalisation (DPDR)
    - Somatique : Trouble à symptomatologie somatique
    - Conduites alimentaires : Anorexie mentale restrictive, Boulimie / hyperphagie
    - Sommeil-éveil : Trouble de l'insomnie chronique
    - Contrôle des impulsions : Trouble explosif intermittent (TEI)
    - Addictions : Trouble de l'usage de substances
    - Personnalités (Clusters A, B, C) : Schizoïde, Limite (Z=4,6), Antisociale,
      Évitante, Obsessionnelle-compulsive (POC)

Conformément à la contrainte épistémologique de CARTOGRAFFECT®, chaque cohorte
formalise une trajectoire fonctionnelle réversible dans l'espace continu
θ = {τ_A, τ_C, λ, α_0, γ_α, η_diss, β_X, β_Y} et sur le lexique ``Lexicon176``,
et non une étiquette diagnostique statique.

Exporte 5 figures 300 DPI, tableaux CSV et rapport JSON dans ``results/dsm5_full_nosology/``.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
import time
from collections import Counter
from pathlib import Path
from typing import Any

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse
import numpy as np
import pandas as pd
import seaborn as sns
from scipy import linalg, stats
from scipy.cluster.hierarchy import cophenet, dendrogram, linkage
from scipy.spatial.distance import cdist, jensenshannon, squareform

ROOT_DIR = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT_DIR / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from cartograffect_sim.clinical_profiles import (  # noqa: E402
    DSM5FullNosologyPriorBank,
    FULL_DSM5_COHORT_KEYS,
    InterventionModality,
    TherapeuticIntervention,
    build_dsm5_phenotyping_schedule,
    invert_clinical_batch_svi,
    simulate_clinical_agent,
)
from cartograffect_sim.lexicon_176 import ALL_176_ENTRIES  # noqa: E402
from cartograffect_sim.recovery import THETA_NAMES  # noqa: E402

THETA_TEX_LABELS: dict[str, str] = {
    "tau_A": r"$\tau_A$",
    "tau_C": r"$\tau_C$",
    "lambda": r"$\lambda$",
    "alpha_0": r"$\alpha_0$",
    "gamma_alpha": r"$\gamma_\alpha$",
    "eta_diss": r"$\eta_{\mathrm{diss}}$",
    "beta_X": r"$\beta_X$",
    "beta_Y": r"$\beta_Y$",
}

SPECTRUM_ORDER: tuple[str, ...] = (
    "Normothymique",
    "Internalisé — Détresse & Peur",
    "Compulsif & Surcontrôle",
    "Bipolaire & Psychotique",
    "Détachement & Dissociation",
    "Somatoforme & Hyperéveil",
    "Désinhibé & Externalisé",
)

SPECTRUM_COLORS: dict[str, str] = {
    "Normothymique": "#1b9e77",
    "Internalisé — Détresse & Peur": "#386cb0",
    "Compulsif & Surcontrôle": "#6a3d9a",
    "Bipolaire & Psychotique": "#e31a1c",
    "Détachement & Dissociation": "#1f78b4",
    "Somatoforme & Hyperéveil": "#b15928",
    "Désinhibé & Externalisé": "#ff7f00",
}

SPECTRUM_SHORT_LABELS: dict[str, str] = {
    "Normothymique": "Normothymique",
    "Internalisé — Détresse & Peur": "Internalisé",
    "Compulsif & Surcontrôle": "Surcontrôle",
    "Bipolaire & Psychotique": "Bip./Psychot.",
    "Détachement & Dissociation": "Détachement",
    "Somatoforme & Hyperéveil": "Somato./Éveil",
    "Désinhibé & Externalisé": "Externalisé",
}


def _format_p(p: float) -> str:
    if not math.isfinite(p):
        return "nan"
    if p < 1e-300:
        return "< 1e-300"
    return f"{p:.2e}"


def _sarles_bimodality_coefficient(values: np.ndarray) -> float:
    """Coefficient de bimodalité de Sarle (> 5/9 ≈ 0.556 suggère une bimodalité)."""
    x = np.asarray(values, dtype=np.float64)
    n = len(x)
    if n < 4 or np.std(x) < 1e-12:
        return 0.0
    skew = float(stats.skew(x, bias=False))
    kurt_ex = float(stats.kurtosis(x, fisher=True, bias=False))
    denom = kurt_ex + 3.0 * ((n - 1) ** 2) / ((n - 2) * (n - 3))
    if denom <= 1e-12:
        return 0.0
    return float((skew**2 + 1.0) / denom)


def _repel_label_positions(
    points: np.ndarray,
    xlim: tuple[float, float],
    ylim: tuple[float, float],
    *,
    labels: Sequence[str] | None = None,
    box_w_per_char: float = 0.009,
    box_h: float = 0.048,
    n_iter: int = 450,
    seed: int = 0,
) -> np.ndarray:
    """Calcule des ancres d'étiquettes sans collision par résolution AABB en coordonnées normalisées."""
    n_pts = len(points)
    if n_pts == 0:
        return np.zeros((0, 2), dtype=np.float64)

    x_lo, x_hi = float(xlim[0]), float(xlim[1])
    y_lo, y_hi = float(ylim[0]), float(ylim[1])
    x_span = max(1e-6, x_hi - x_lo)
    y_span = max(1e-6, y_hi - y_lo)

    pts_norm = np.column_stack([(points[:, 0] - x_lo) / x_span, (points[:, 1] - y_lo) / y_span])
    half_w = np.array(
        [
            0.5 * (max(4, len(labels[i]) if labels is not None else 8) * box_w_per_char + 0.016)
            for i in range(n_pts)
        ],
        dtype=np.float64,
    )
    half_h = np.full(n_pts, 0.5 * box_h, dtype=np.float64)

    rng = np.random.default_rng(seed)
    angles = np.linspace(0.0, 2.0 * math.pi, n_pts, endpoint=False)
    anchors = pts_norm + np.column_stack([0.045 * np.cos(angles), 0.055 * np.sin(angles)])
    anchors += rng.normal(0.0, 0.003, size=anchors.shape)

    tether_stop = int(0.75 * n_iter)
    for it in range(n_iter):
        # 1. Répulsion boîte-à-boîte (AABB)
        for i in range(n_pts):
            for j in range(i + 1, n_pts):
                dx = anchors[i, 0] - anchors[j, 0]
                dy = anchors[i, 1] - anchors[j, 1]
                ox = (half_w[i] + half_w[j] + 0.006) - abs(dx)
                oy = (half_h[i] + half_h[j] + 0.006) - abs(dy)
                if ox > 0.0 and oy > 0.0:
                    if ox < oy:
                        sgn = 1.0 if dx >= 0.0 else -1.0
                        if abs(dx) < 1e-6:
                            sgn = 1.0 if (i % 2 == 0) else -1.0
                        anchors[i, 0] += 0.52 * ox * sgn
                        anchors[j, 0] -= 0.52 * ox * sgn
                    else:
                        sgn = 1.0 if dy >= 0.0 else -1.0
                        if abs(dy) < 1e-6:
                            sgn = 1.0 if (i % 2 == 0) else -1.0
                        anchors[i, 1] += 0.52 * oy * sgn
                        anchors[j, 1] -= 0.52 * oy * sgn

        # 2. Évitement des points de données
        for i in range(n_pts):
            for m in range(n_pts):
                pr = 0.022 if m == i else 0.015
                dx = anchors[i, 0] - pts_norm[m, 0]
                dy = anchors[i, 1] - pts_norm[m, 1]
                ox = (half_w[i] + pr) - abs(dx)
                oy = (half_h[i] + pr) - abs(dy)
                if ox > 0.0 and oy > 0.0:
                    if ox < oy:
                        sgn = 1.0 if dx >= 0.0 else -1.0
                        anchors[i, 0] += 0.55 * ox * sgn
                    else:
                        sgn = 1.0 if dy >= 0.0 else -1.0
                        anchors[i, 1] += 0.55 * oy * sgn

        # 3. Rappel doux vers son propre point pendant les premières itérations
        if it < tether_stop:
            anchors += 0.014 * (pts_norm - anchors)

        for i in range(n_pts):
            anchors[i, 0] = np.clip(anchors[i, 0], 0.015 + half_w[i], 0.985 - half_w[i])
            anchors[i, 1] = np.clip(anchors[i, 1], 0.025 + half_h[i], 0.975 - half_h[i])

    return np.column_stack([x_lo + anchors[:, 0] * x_span, y_lo + anchors[:, 1] * y_span])


# ---------------------------------------------------------------------------
# Utilitaires purs NumPy / SciPy pour séparabilité, CV QDA, MANOVA & Ward
# ---------------------------------------------------------------------------


def _stratified_kfold_indices(
    y: np.ndarray,
    n_splits: int = 10,
    seed: int = 42,
) -> list[tuple[np.ndarray, np.ndarray]]:
    rng = np.random.default_rng(seed)
    classes, counts = np.unique(y, return_counts=True)
    k_eff = max(2, min(int(n_splits), int(np.min(counts))))
    per_class_folds: list[list[np.ndarray]] = [[] for _ in range(k_eff)]
    for cls in classes:
        cls_idx = np.flatnonzero(y == cls).copy()
        rng.shuffle(cls_idx)
        splits = np.array_split(cls_idx, k_eff)
        for fold_i in range(k_eff):
            per_class_folds[fold_i].append(splits[fold_i])

    folds: list[tuple[np.ndarray, np.ndarray]] = []
    for fold_i in range(k_eff):
        test_idx = np.concatenate(per_class_folds[fold_i])
        train_idx = np.concatenate(
            [np.concatenate(per_class_folds[j]) for j in range(k_eff) if j != fold_i]
        )
        folds.append((train_idx, test_idx))
    return folds


def _fit_predict_qda(
    x_train: np.ndarray,
    y_train: np.ndarray,
    x_test: np.ndarray,
    n_classes: int,
    reg_covar: float = 0.08,
) -> tuple[np.ndarray, np.ndarray]:
    """Classifieur quadratique bayésien régularisé (QDA) ajusté sans fuite sur ``x_train``."""
    mu_all = np.mean(x_train, axis=0)
    sd_all = np.maximum(1e-6, np.std(x_train, axis=0, ddof=1 if len(x_train) > 1 else 0))
    z_train = (x_train - mu_all) / sd_all
    z_test = (x_test - mu_all) / sd_all
    dim = z_train.shape[1]

    log_scores = np.full((len(z_test), n_classes), -1e12, dtype=np.float64)
    n_tr = float(len(z_train))
    eye_d = np.eye(dim, dtype=np.float64)

    for k in range(n_classes):
        xk = z_train[y_train == k]
        nk = len(xk)
        if nk == 0:
            continue
        mu_k = np.mean(xk, axis=0)
        if nk > 1:
            cov_emp = np.cov(xk, rowvar=False, bias=False)
            if cov_emp.ndim == 0:
                cov_emp = np.array([[float(cov_emp)]], dtype=np.float64)
        else:
            cov_emp = eye_d.copy()
        cov_reg = (1.0 - reg_covar) * cov_emp + (reg_covar + 1e-4) * eye_d
        sign, logdet = np.linalg.slogdet(cov_reg)
        if sign <= 0:
            cov_reg = cov_reg + 1e-2 * eye_d
            _, logdet = np.linalg.slogdet(cov_reg)
        inv_cov = np.linalg.inv(cov_reg)
        diff = z_test - mu_k[None, :]
        quad = np.sum((diff @ inv_cov) * diff, axis=1)
        log_prior = math.log(max(1e-12, nk / n_tr))
        log_scores[:, k] = log_prior - 0.5 * float(logdet) - 0.5 * quad

    return np.argmax(log_scores, axis=1).astype(np.int32), log_scores


def _compute_classification_metrics(
    y_true: np.ndarray,
    y_pred: np.ndarray,
    class_keys: Sequence[str],
) -> dict[str, Any]:
    n_cls = len(class_keys)
    cm = np.zeros((n_cls, n_cls), dtype=np.int64)
    for t_lbl, p_lbl in zip(y_true, y_pred):
        cm[int(t_lbl), int(p_lbl)] += 1

    cm_norm = cm / np.maximum(1, cm.sum(axis=1, keepdims=True))
    total = float(np.sum(cm))
    accuracy = float(np.trace(cm) / max(1.0, total))

    p_o = accuracy
    p_e = float(np.sum(cm.sum(axis=1) * cm.sum(axis=0)) / max(1.0, total**2))
    kappa = float((p_o - p_e) / max(1e-12, 1.0 - p_e))

    per_class: dict[str, dict[str, Any]] = {}
    recalls: list[float] = []
    f1s: list[float] = []
    for k, ckey in enumerate(class_keys):
        tp = float(cm[k, k])
        fn = float(cm[k, :].sum() - tp)
        fp = float(cm[:, k].sum() - tp)
        prec = tp / max(1e-12, tp + fp) if (tp + fp) > 0 else 0.0
        rec = tp / max(1e-12, tp + fn) if (tp + fn) > 0 else 0.0
        f1 = (2.0 * prec * rec / (prec + rec)) if (prec + rec) > 0 else 0.0
        recalls.append(rec)
        f1s.append(f1)
        per_class[ckey] = {
            "precision": float(prec),
            "recall": float(rec),
            "f1": float(f1),
            "support": int(cm[k, :].sum()),
        }

    return {
        "confusion_counts": cm,
        "confusion_norm": cm_norm,
        "accuracy": accuracy,
        "balanced_accuracy": float(np.mean(recalls)),
        "macro_f1": float(np.mean(f1s)),
        "cohen_kappa": kappa,
        "per_class": per_class,
    }


def _evaluate_cv_qda(
    x_feat: np.ndarray,
    y: np.ndarray,
    class_keys: Sequence[str],
    *,
    n_splits: int = 10,
    reg_covar: float = 0.08,
    seed: int = 42,
) -> dict[str, Any]:
    folds = _stratified_kfold_indices(y, n_splits=n_splits, seed=seed)
    y_pred = np.zeros_like(y)
    n_cls = len(class_keys)
    for train_idx, test_idx in folds:
        preds, _ = _fit_predict_qda(
            x_feat[train_idx],
            y[train_idx],
            x_feat[test_idx],
            n_classes=n_cls,
            reg_covar=reg_covar,
        )
        y_pred[test_idx] = preds
    res = _compute_classification_metrics(y, y_pred, class_keys)
    res["n_folds"] = len(folds)
    res["y_pred"] = y_pred
    return res


def _compute_silhouette_scores(
    x_feat: np.ndarray,
    y: np.ndarray,
    class_keys: Sequence[str],
) -> dict[str, Any]:
    mu = np.mean(x_feat, axis=0)
    sd = np.maximum(1e-6, np.std(x_feat, axis=0, ddof=1 if len(x_feat) > 1 else 0))
    z = (x_feat - mu) / sd
    dist_mat = cdist(z, z, metric="euclidean")
    n = len(z)
    n_cls = len(class_keys)
    masks = [y == k for k in range(n_cls)]

    sil = np.zeros(n, dtype=np.float64)
    for i in range(n):
        yi = int(y[i])
        same = masks[yi]
        cnt = int(np.sum(same))
        if cnt <= 1:
            sil[i] = 0.0
            continue
        a_i = float(np.sum(dist_mat[i, same]) / (cnt - 1))
        b_i = min(
            float(np.mean(dist_mat[i, masks[k]]))
            for k in range(n_cls)
            if k != yi and np.any(masks[k])
        )
        denom = max(a_i, b_i)
        sil[i] = (b_i - a_i) / denom if denom > 1e-12 else 0.0

    by_class = {
        ckey: float(np.mean(sil[masks[k]])) if np.any(masks[k]) else 0.0
        for k, ckey in enumerate(class_keys)
    }
    return {
        "global_silhouette": float(np.mean(sil)),
        "silhouette_by_class": by_class,
    }


def _compute_manova_and_lda(
    x_feat: np.ndarray,
    y: np.ndarray,
    n_classes: int,
) -> dict[str, Any]:
    mu = np.mean(x_feat, axis=0)
    sd = np.maximum(1e-6, np.std(x_feat, axis=0, ddof=1 if len(x_feat) > 1 else 0))
    z = (x_feat - mu) / sd
    dim = z.shape[1]
    z_mean = np.mean(z, axis=0)

    sb = np.zeros((dim, dim), dtype=np.float64)
    sw = np.zeros((dim, dim), dtype=np.float64)
    for k in range(n_classes):
        zk = z[y == k]
        nk = len(zk)
        if nk == 0:
            continue
        mk = np.mean(zk, axis=0)
        diff_m = (mk - z_mean)[:, None]
        sb += float(nk) * (diff_m @ diff_m.T)
        if nk > 1:
            centered = zk - mk[None, :]
            sw += centered.T @ centered

    sw_reg = sw + 1e-4 * np.eye(dim, dtype=np.float64)
    st = sb + sw_reg
    _, logdet_w = np.linalg.slogdet(sw_reg)
    _, logdet_t = np.linalg.slogdet(st)
    wilks_lambda = float(math.exp(max(-500.0, min(0.0, logdet_w - logdet_t))))
    pillais_trace = float(np.trace(sb @ np.linalg.inv(st)))

    eigvals, eigvecs = linalg.eigh(sb, sw_reg)
    order = np.argsort(eigvals)[::-1]
    eigvals = np.maximum(0.0, eigvals[order])
    eigvecs = eigvecs[:, order]
    proj_2d = z @ eigvecs[:, :2]
    total_eig = float(np.sum(eigvals))
    var_ratio = (
        (eigvals[:2] / total_eig).tolist() if total_eig > 1e-12 else [0.5, 0.5]
    )

    return {
        "wilks_lambda": wilks_lambda,
        "pillais_trace": pillais_trace,
        "lda_2d": proj_2d,
        "lda_explained_ratio": var_ratio,
        "pooled_within_cov": sw_reg / max(1.0, float(len(z) - n_classes)),
        "z_standardized": z,
    }


def _compute_pairwise_and_ward(
    z_std: np.ndarray,
    y: np.ndarray,
    pooled_cov: np.ndarray,
    cohort_keys: Sequence[str],
    cm_theta_norm: np.ndarray,
    cm_comb_norm: np.ndarray,
    occ_matrix: np.ndarray,
    *,
    reg_covar: float = 0.08,
) -> tuple[list[dict[str, Any]], np.ndarray, np.ndarray, float]:
    n_cls = len(cohort_keys)
    dim = z_std.shape[1]
    eye_d = np.eye(dim, dtype=np.float64)
    inv_pooled = np.linalg.inv(pooled_cov + 1e-4 * eye_d)

    means_k: list[np.ndarray] = []
    covs_k: list[np.ndarray] = []
    logdets_k: list[float] = []
    for k in range(n_cls):
        zk = z_std[y == k]
        means_k.append(np.mean(zk, axis=0))
        ck = np.cov(zk, rowvar=False, bias=False) if len(zk) > 1 else eye_d.copy()
        if ck.ndim == 0:
            ck = np.array([[float(ck)]], dtype=np.float64)
        ck = (1.0 - reg_covar) * ck + (reg_covar + 1e-4) * eye_d
        covs_k.append(ck)
        _, ld = np.linalg.slogdet(ck)
        logdets_k.append(float(ld))

    mahal_mat = np.zeros((n_cls, n_cls), dtype=np.float64)
    rows: list[dict[str, Any]] = []
    for i in range(n_cls):
        for j in range(i + 1, n_cls):
            dm = means_k[i] - means_k[j]
            mahal = float(math.sqrt(max(0.0, float(dm.T @ inv_pooled @ dm))))
            mahal_mat[i, j] = mahal
            mahal_mat[j, i] = mahal
            cov_avg = 0.5 * (covs_k[i] + covs_k[j])
            _, ld_avg = np.linalg.slogdet(cov_avg)
            db = float(
                0.125 * float(dm.T @ np.linalg.inv(cov_avg) @ dm)
                + 0.5 * (ld_avg - 0.5 * (logdets_k[i] + logdets_k[j]))
            )
            bc = float(math.exp(-max(0.0, db)))
            js_dist = float(jensenshannon(occ_matrix[i], occ_matrix[j], base=2.0))
            js_div = float(js_dist**2) if math.isfinite(js_dist) else 0.0
            conf_theta = float(0.5 * (cm_theta_norm[i, j] + cm_theta_norm[j, i]))
            conf_comb = float(0.5 * (cm_comb_norm[i, j] + cm_comb_norm[j, i]))
            rows.append(
                {
                    "cohort_a": cohort_keys[i],
                    "cohort_b": cohort_keys[j],
                    "mahalanobis_distance": mahal,
                    "bhattacharyya_distance": db,
                    "bhattacharyya_overlap": bc,
                    "lexicon176_js_divergence": js_div,
                    "sym_confusion_theta_hat": conf_theta,
                    "sym_confusion_combined": conf_comb,
                }
            )

    condensed = squareform(mahal_mat, checks=False)
    z_linkage = linkage(condensed, method="ward")
    coph_r, _ = cophenet(z_linkage, condensed)
    return rows, mahal_mat, z_linkage, float(coph_r)


# ---------------------------------------------------------------------------
# Génération des 5 figures comparatives (300 DPI)
# ---------------------------------------------------------------------------


def _plot_fig5a_xyz_atlas_26(
    bank: DSM5FullNosologyPriorBank,
    cohort_keys: tuple[str, ...],
    sims_by_cohort: dict[str, list[Any]],
    occ_summary: dict[str, Any],
    out_path: Path,
) -> None:
    sns.set_theme(style="whitegrid", context="paper")
    fig = plt.figure(figsize=(24.0, 20.0), dpi=300)
    gs = fig.add_gridspec(5, 6, hspace=0.40, wspace=0.22, left=0.04, right=0.905, top=0.93, bottom=0.04)
    cmap = plt.get_cmap("plasma")

    sc = None
    for idx, ckey in enumerate(cohort_keys):
        row_i, col_i = divmod(idx, 6)
        ax = fig.add_subplot(gs[row_i, col_i])
        spec = bank.get_spec(ckey)
        sub_sims = sims_by_cohort[ckey]

        for radius, ls, alpha_r in [(2, ":", 0.35), (6, "--", 0.30), (10, "-.", 0.24), (12, "-", 0.16)]:
            px = [radius, 0, -radius, 0, radius]
            py = [0, radius, 0, -radius, 0]
            ax.plot(px, py, linestyle=ls, color="#666666", lw=0.75, alpha=alpha_r)
        ax.axhline(0, color="#aaaaaa", lw=0.65, alpha=0.55)
        ax.axvline(0, color="#aaaaaa", lw=0.65, alpha=0.55)

        xs_all = np.concatenate([s.xs for s in sub_sims])
        ys_all = np.concatenate([s.ys for s in sub_sims])
        zs_all = np.concatenate([s.zs for s in sub_sims])
        n_total = float(len(xs_all))

        pt_counts = Counter(zip(xs_all.tolist(), ys_all.tolist(), zs_all.tolist()))
        periph_pts = [(pt, cnt / n_total) for pt, cnt in pt_counts.items() if (pt[0], pt[1]) != (0, 0)]
        periph_pts.sort(key=lambda item: item[1])

        if periph_pts:
            px_vals = np.array([p[0][0] for p in periph_pts], dtype=np.float64)
            py_vals = np.array([p[0][1] for p in periph_pts], dtype=np.float64)
            pz_vals = np.array([p[0][2] for p in periph_pts], dtype=np.float64)
            pf_vals = np.array([p[1] for p in periph_pts], dtype=np.float64)
            sc = ax.scatter(
                px_vals,
                py_vals,
                c=pz_vals,
                cmap=cmap,
                vmin=1,
                vmax=7,
                s=14.0 + 1850.0 * pf_vals,
                alpha=0.82,
                edgecolors="black",
                linewidths=0.30,
                zorder=4,
            )

        pdv_frac = float(pt_counts.get((0, 0, 0), 0)) / n_total
        susp_frac = sum(
            cnt for (xx, yy, zz), cnt in pt_counts.items() if xx == 0 and yy == 0 and zz >= 2
        ) / n_total

        ax.scatter(
            [0],
            [0],
            marker="*",
            s=80.0 + 360.0 * pdv_frac,
            color="#ffd92f",
            edgecolors="black",
            linewidths=0.6,
            zorder=6,
        )
        if susp_frac > 0.03:
            ax.scatter(
                [0],
                [0],
                marker="o",
                s=130.0 + 680.0 * susp_frac,
                facecolors="none",
                edgecolors="#8c2d04",
                linewidths=1.5,
                zorder=5,
            )

        top_non_pdv = occ_summary[ckey]["top_non_pdv_states"][:2]
        top_txt = " | ".join(
            f"{st['label']} ({st['x']:+d},{st['y']:+d},{st['z']}): {100.0 * st['occupancy']:.0f}%"
            for st in top_non_pdv[:1]
        )
        if len(top_non_pdv) > 1:
            st1 = top_non_pdv[1]
            top_txt += f"\n{st1['label']} ({st1['x']:+d},{st1['y']:+d},{st1['z']}): {100.0 * st1['occupancy']:.0f}%"
        badge = f"PdV {100.0 * pdv_frac:.0f}% | Susp {100.0 * susp_frac:.0f}%\n{top_txt}"
        ax.text(
            0.03,
            0.03,
            badge,
            transform=ax.transAxes,
            fontsize=6.3,
            va="bottom",
            ha="left",
            bbox={"boxstyle": "round,pad=0.22", "facecolor": "white", "alpha": 0.90, "edgecolor": spec.color},
            zorder=8,
        )

        m_x = occ_summary[ckey]["mean_x"]
        m_y = occ_summary[ckey]["mean_y"]
        m_z = occ_summary[ckey]["mean_z"]
        ax.set_xlim(-12.6, 12.6)
        ax.set_ylim(-12.6, 12.6)
        ax.tick_params(labelsize=6.8)
        if row_i == 4 or (row_i == 3 and col_i >= 2):
            ax.set_xlabel("$X$", fontsize=7.8)
        if col_i == 0:
            ax.set_ylabel("$Y$", fontsize=7.8)
        sp_short = SPECTRUM_SHORT_LABELS.get(spec.hitop_spectrum, spec.hitop_spectrum)
        ax.set_title(
            f"{spec.short_label} [{sp_short}]\n"
            f"$\\bar{{X}}={m_x:+.2f},\\;\\bar{{Y}}={m_y:+.2f},\\;\\bar{{Z}}={m_z:.2f}$",
            fontsize=8.2,
            fontweight="bold",
            color=SPECTRUM_COLORS.get(spec.hitop_spectrum, spec.color),
        )

    # 4 cases fusionnées en bas à droite : Carte synthétique des 26 centroïdes (X, Y)
    ax_map = fig.add_subplot(gs[4, 2:6])
    cx = np.array([occ_summary[k]["mean_x"] for k in cohort_keys], dtype=np.float64)
    cy = np.array([occ_summary[k]["mean_y"] for k in cohort_keys], dtype=np.float64)
    cz = np.array([occ_summary[k]["mean_z"] for k in cohort_keys], dtype=np.float64)

    for sp_name in SPECTRUM_ORDER:
        sp_mask = np.array([bank.get_spec(k).hitop_spectrum == sp_name for k in cohort_keys])
        if np.any(sp_mask):
            ax_map.scatter(
                cx[sp_mask],
                cy[sp_mask],
                s=45.0 + 28.0 * cz[sp_mask],
                color=SPECTRUM_COLORS[sp_name],
                edgecolors="black",
                linewidths=0.7,
                alpha=0.90,
                label=sp_name,
                zorder=5,
            )

    xlim_map = (float(np.min(cx)) - 0.16, float(np.max(cx)) + 0.16)
    ylim_map = (float(np.min(cy)) - 1.55, float(np.max(cy)) + 0.90)
    map_labels = [bank.get_spec(k).short_label for k in cohort_keys]
    anchors = _repel_label_positions(
        np.column_stack([cx, cy]),
        xlim_map,
        (float(np.min(cy)) - 0.35, ylim_map[1]),
        labels=map_labels,
        box_w_per_char=0.0075,
        box_h=0.072,
        n_iter=500,
        seed=11,
    )
    for i, ckey in enumerate(cohort_keys):
        spec = bank.get_spec(ckey)
        col_lbl = SPECTRUM_COLORS.get(spec.hitop_spectrum, "#222222")
        ax_map.annotate(
            spec.short_label,
            xy=(cx[i], cy[i]),
            xytext=(anchors[i, 0], anchors[i, 1]),
            fontsize=7.0,
            fontweight="bold",
            color=col_lbl,
            ha="center",
            va="center",
            bbox={"boxstyle": "round,pad=0.14", "facecolor": "white", "alpha": 0.86, "edgecolor": col_lbl, "lw": 0.4},
            arrowprops={"arrowstyle": "-", "lw": 0.60, "color": "#555555", "alpha": 0.70},
            zorder=6,
        )
    ax_map.axhline(0, color="#999999", ls="--", lw=0.8)
    ax_map.axvline(0, color="#999999", ls="--", lw=0.8)
    ax_map.set_xlim(xlim_map)
    ax_map.set_ylim(ylim_map)
    ax_map.set_xlabel("Centroïde moyen épistémique $\\bar{X}$", fontsize=9.0)
    ax_map.set_ylabel("Centroïde moyen pragmatique $\\bar{Y}$", fontsize=9.0)
    ax_map.set_title(
        "Atlas global des 26 centroïdes $( \\bar{X}, \\bar{Y} )$ colorés par spectre HiTOP (taille $\\propto \\bar{Z}$)",
        fontsize=9.8,
        fontweight="bold",
    )
    ax_map.legend(ncol=4, fontsize=7.2, loc="lower left", frameon=True)

    if sc is not None:
        cbar_ax = fig.add_axes([0.922, 0.10, 0.014, 0.80])
        cbar = fig.colorbar(sc, cax=cbar_ax)
        cbar.set_label("Strate hiérarchique $Z$ (taille $\\propto$ densité d'occupation)", fontsize=10.0)

    n_per = len(next(iter(sims_by_cohort.values())))
    n_all = sum(len(v) for v in sims_by_cohort.values())
    fig.suptitle(
        f"Expérience 5a — Atlas pan-DSM-5 des densités d'occupation $(X, Y, Z)$ et coordonnées Lexicon176 ($26 \\times {n_per} = {n_all:,}$ agents)",
        fontsize=13.8,
        fontweight="bold",
        y=0.975,
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=300, bbox_inches="tight")
    plt.close(fig)


def _plot_fig5b_dendrogram_and_profiles(
    bank: DSM5FullNosologyPriorBank,
    cohort_keys: tuple[str, ...],
    est_theta_mat: np.ndarray,
    ctrl_bias_hat: np.ndarray,
    y: np.ndarray,
    z_linkage: np.ndarray,
    coph_r: float,
    occ_summary: dict[str, Any],
    out_path: Path,
) -> None:
    sns.set_theme(style="whitegrid", context="paper")
    fig = plt.figure(figsize=(19.5, 11.5), dpi=300)
    gs = fig.add_gridspec(1, 3, width_ratios=[1.15, 2.35, 1.10], wspace=0.08, left=0.14, right=0.95, top=0.89, bottom=0.12)

    ax_dend = fig.add_subplot(gs[0, 0])
    ax_heat = fig.add_subplot(gs[0, 1])
    ax_dyn = fig.add_subplot(gs[0, 2])

    short_labels = [bank.get_spec(k).short_label for k in cohort_keys]
    dn = dendrogram(
        z_linkage,
        labels=short_labels,
        orientation="left",
        color_threshold=0.0,
        above_threshold_color="#333333",
        ax=ax_dend,
    )
    ax_dend.invert_yaxis()
    leaf_order = dn["leaves"]
    ordered_keys = [cohort_keys[i] for i in leaf_order]
    ordered_labels = [bank.get_spec(k).short_label for k in ordered_keys]

    ax_dend.set_title(f"A. Dendrogramme Ward\n(Mahalanobis, $c_{{\\mathrm{{coph}}}} = {coph_r:.3f}$)", fontsize=10.5, fontweight="bold")
    ax_dend.set_xlabel("Distance de Ward", fontsize=9.2)
    ax_dend.yaxis.tick_left()
    ax_dend.spines["right"].set_visible(False)
    ax_dend.set_yticks(np.arange(len(ordered_keys)) * 10.0 + 5.0)
    ax_dend.set_yticklabels(ordered_labels, fontsize=8.8, fontweight="bold")
    ax_dend.tick_params(axis="y", pad=4)
    for tick_lbl, ckey in zip(ax_dend.get_yticklabels(), ordered_keys):
        sp = bank.get_spec(ckey).hitop_spectrum
        tick_lbl.set_color(SPECTRUM_COLORS.get(sp, "#222222"))

    # B. Heatmap 26×9 z-score (θ̂_i, δ̂_c) ordonnée selon les feuilles du dendrogramme
    feat_full = np.column_stack([est_theta_mat, ctrl_bias_hat])
    feat_z = (feat_full - feat_full.mean(axis=0)) / np.maximum(1e-6, feat_full.std(axis=0, ddof=1))
    mean_theta_ordered = np.vstack([feat_z[y == i].mean(axis=0) for i in leaf_order])
    col_labels = [THETA_TEX_LABELS[p] for p in THETA_NAMES] + [r"$\hat{\delta}_c$"]
    df_heat = pd.DataFrame(mean_theta_ordered, index=ordered_labels, columns=col_labels)

    cbar_ax_b = fig.add_axes([0.38, 0.045, 0.31, 0.016])
    sns.heatmap(
        df_heat,
        annot=True,
        fmt=".2f",
        cmap="RdBu_r",
        center=0.0,
        vmin=-2.0,
        vmax=2.0,
        linewidths=0.45,
        annot_kws={"size": 7.6},
        cbar=True,
        cbar_ax=cbar_ax_b,
        cbar_kws={"orientation": "horizontal", "label": "Score $z$ moyen des paramètres inversés $(\\hat{\\theta}_i, \\hat{\\delta}_c)$"},
        ax=ax_heat,
    )
    ax_heat.set_title("B. Empreintes paramétriques $(\\hat{\\theta}_i, \\hat{\\delta}_c)$ ordonnées", fontsize=10.5, fontweight="bold")
    ax_heat.set_yticks([])
    ax_heat.set_ylabel("")
    ax_heat.tick_params(axis="x", labelsize=9.2)

    # C. Bandeau 26×4 des marqueurs comportementaux/structuraux
    raw_markers = np.array(
        [
            [
                100.0 * occ_summary[k]["pdv_fraction_remission"],
                occ_summary[k]["probe_rate"],
                100.0 * occ_summary[k]["central_suspension_rate"],
                occ_summary[k]["z4_z6_instability_ratio"],
            ]
            for k in cohort_keys
        ],
        dtype=np.float64,
    )
    marker_z = (raw_markers - raw_markers.mean(axis=0)) / np.maximum(1e-6, raw_markers.std(axis=0, ddof=1))
    marker_z_ord = marker_z[leaf_order]
    raw_ord = raw_markers[leaf_order]
    annot_dyn = np.empty_like(raw_ord, dtype=object)
    for r_i in range(raw_ord.shape[0]):
        annot_dyn[r_i, 0] = f"{raw_ord[r_i, 0]:.0f}%"
        annot_dyn[r_i, 1] = f"{raw_ord[r_i, 1]:.2f}"
        annot_dyn[r_i, 2] = f"{raw_ord[r_i, 2]:.0f}%"
        annot_dyn[r_i, 3] = f"{raw_ord[r_i, 3]:.2f}"

    df_dyn = pd.DataFrame(
        marker_z_ord,
        index=ordered_labels,
        columns=["PdV rém.", "Probe", "Susp.", r"$Z_{4,6}$"],
    )
    cbar_ax_c = fig.add_axes([0.77, 0.045, 0.16, 0.016])
    sns.heatmap(
        df_dyn,
        annot=annot_dyn,
        fmt="",
        cmap="YlGnBu",
        vmin=-1.8,
        vmax=2.5,
        linewidths=0.45,
        annot_kws={"size": 7.6},
        cbar=True,
        cbar_ax=cbar_ax_c,
        cbar_kws={"orientation": "horizontal", "label": "Score $z$ marqueurs"},
        ax=ax_dyn,
    )
    ax_dyn.set_title("C. Marqueurs dynamiques\n& structuraux", fontsize=10.5, fontweight="bold")
    ax_dyn.set_yticks([])
    ax_dyn.set_ylabel("")
    ax_dyn.tick_params(axis="x", labelsize=8.8)

    fig.suptitle(
        "Expérience 5b — Taxonomie computationnelle ascendante (Ward) et signatures paramétriques des 26 régimes DSM-5",
        fontsize=13.2,
        fontweight="bold",
        y=0.96,
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=300, bbox_inches="tight")
    plt.close(fig)


def _plot_fig5c_confusion_and_hitop(
    bank: DSM5FullNosologyPriorBank,
    cohort_keys: tuple[str, ...],
    spectrum_keys: tuple[str, ...],
    cv_26_comb: dict[str, Any],
    cv_hitop_comb: dict[str, Any],
    sil_26_comb: dict[str, Any],
    sil_hitop_comb: dict[str, Any],
    manova_26_comb: dict[str, Any],
    y: np.ndarray,
    out_path: Path,
) -> None:
    sns.set_theme(style="white", context="paper")
    fig = plt.figure(figsize=(23.0, 8.2), dpi=300)
    gs = fig.add_gridspec(1, 3, width_ratios=[1.48, 0.92, 1.15], wspace=0.34, left=0.06, right=0.98, top=0.84, bottom=0.17)

    # Réordonner les 26 cohortes par spectre HiTOP pour révéler la structure en blocs transdiagnostiques
    order_indices: list[int] = []
    block_boundaries: list[int] = []
    for sp in spectrum_keys:
        grp = [i for i, k in enumerate(cohort_keys) if bank.get_spec(k).hitop_spectrum == sp]
        order_indices.extend(grp)
        block_boundaries.append(len(order_indices))

    cm_raw = cv_26_comb["confusion_norm"]
    cm_ord = cm_raw[np.ix_(order_indices, order_indices)]
    lbl_ord = [bank.get_spec(cohort_keys[i]).short_label for i in order_indices]
    annot_26 = np.where(cm_ord >= 0.03, np.vectorize(lambda v: f"{v:.2f}")(cm_ord), "")

    ax_a = fig.add_subplot(gs[0, 0])
    sns.heatmap(
        pd.DataFrame(cm_ord, index=lbl_ord, columns=lbl_ord),
        annot=annot_26,
        fmt="",
        cmap="YlGnBu",
        vmin=0.0,
        vmax=1.0,
        linewidths=0.30,
        annot_kws={"size": 6.0},
        cbar=True,
        cbar_kws={"shrink": 0.85},
        ax=ax_a,
    )
    for b_pos in block_boundaries[:-1]:
        ax_a.axhline(b_pos, color="#333333", lw=1.1, ls="--")
        ax_a.axvline(b_pos, color="#333333", lw=1.1, ls="--")
    ax_a.set_title(
        f"A. Confusion 26×26 ordonnée par spectre ($\\hat{{\\theta}}_i$ + dyn., CV {cv_26_comb['n_folds']} plis)\n"
        f"Exact. = {100.0 * cv_26_comb['accuracy']:.1f}%, $\\kappa$ = {cv_26_comb['cohen_kappa']:.3f}, Silh. = {sil_26_comb['global_silhouette']:.3f}",
        fontsize=9.6,
        fontweight="bold",
    )
    ax_a.set_xlabel("Régime prédit")
    ax_a.set_ylabel("Cohorte génératrice")
    ax_a.tick_params(axis="x", rotation=48, labelsize=7.0)
    ax_a.tick_params(axis="y", rotation=0, labelsize=7.0)

    # B. Matrice de confusion 7×7 par spectre HiTOP
    sp_short = [SPECTRUM_SHORT_LABELS.get(s, s) for s in spectrum_keys]
    ax_b = fig.add_subplot(gs[0, 1])
    sns.heatmap(
        pd.DataFrame(cv_hitop_comb["confusion_norm"], index=sp_short, columns=sp_short),
        annot=True,
        fmt=".2f",
        cmap="Blues",
        vmin=0.0,
        vmax=1.0,
        linewidths=0.5,
        annot_kws={"size": 8.2},
        cbar=True,
        cbar_kws={"shrink": 0.85},
        ax=ax_b,
    )
    ax_b.set_title(
        f"B. Consolidation en 7 spectres HiTOP\n"
        f"Exact. = {100.0 * cv_hitop_comb['accuracy']:.1f}%, $\\kappa$ = {cv_hitop_comb['cohen_kappa']:.3f}, Silh. = {sil_hitop_comb['global_silhouette']:.3f}",
        fontsize=9.6,
        fontweight="bold",
    )
    ax_b.set_xlabel("Spectre prédit")
    ax_b.set_ylabel("")
    ax_b.tick_params(axis="x", rotation=32, labelsize=8.0)
    ax_b.tick_params(axis="y", rotation=0, labelsize=8.0)

    # C. Espace discriminant canonique LDA 2D (N_total agents) avec étiquettes non chevauchantes
    ax_c = fig.add_subplot(gs[0, 2])
    proj = manova_26_comb["lda_2d"]
    var_r = manova_26_comb["lda_explained_ratio"]
    centroids = np.zeros((len(cohort_keys), 2), dtype=np.float64)

    for k, ckey in enumerate(cohort_keys):
        spec = bank.get_spec(ckey)
        col_sp = SPECTRUM_COLORS.get(spec.hitop_spectrum, spec.color)
        pts_k = proj[y == k]
        ax_c.scatter(pts_k[:, 0], pts_k[:, 1], s=8, alpha=0.22, color=col_sp, edgecolors="none")
        mean_k = pts_k.mean(axis=0)
        centroids[k] = mean_k
        if len(pts_k) > 2:
            cov_k = np.cov(pts_k, rowvar=False)
            vals, vecs = np.linalg.eigh(cov_k)
            order = vals.argsort()[::-1]
            vals, vecs = np.maximum(1e-6, vals[order]), vecs[:, order]
            angle = math.degrees(math.atan2(vecs[1, 0], vecs[0, 0]))
            ell = Ellipse(
                xy=mean_k,
                width=2.1 * math.sqrt(vals[0]),
                height=2.1 * math.sqrt(vals[1]),
                angle=angle,
                edgecolor=col_sp,
                facecolor="none",
                lw=1.25,
                alpha=0.85,
                zorder=5,
            )
            ax_c.add_patch(ell)
        ax_c.scatter([mean_k[0]], [mean_k[1]], marker="o", s=34, color=col_sp, edgecolors="black", lw=0.6, zorder=6)

    pad_x = 0.22 * max(1e-3, float(np.max(proj[:, 0]) - np.min(proj[:, 0])))
    pad_y = 0.22 * max(1e-3, float(np.max(proj[:, 1]) - np.min(proj[:, 1])))
    xlim_c = (float(np.min(proj[:, 0])) - pad_x, float(np.max(proj[:, 0])) + pad_x)
    ylim_c = (float(np.min(proj[:, 1])) - pad_y, float(np.max(proj[:, 1])) + pad_y)

    lda_labels = [bank.get_spec(k).short_label for k in cohort_keys]
    anchors = _repel_label_positions(
        centroids,
        xlim_c,
        ylim_c,
        labels=lda_labels,
        box_w_per_char=0.0165,
        box_h=0.052,
        n_iter=600,
        seed=19,
    )
    for k, ckey in enumerate(cohort_keys):
        spec = bank.get_spec(ckey)
        col_sp = SPECTRUM_COLORS.get(spec.hitop_spectrum, spec.color)
        ax_c.annotate(
            spec.short_label,
            xy=(centroids[k, 0], centroids[k, 1]),
            xytext=(anchors[k, 0], anchors[k, 1]),
            fontsize=6.5,
            fontweight="bold",
            color=col_sp,
            ha="center",
            va="center",
            bbox={"boxstyle": "round,pad=0.12", "facecolor": "white", "alpha": 0.84, "edgecolor": col_sp, "lw": 0.4},
            arrowprops={"arrowstyle": "-", "lw": 0.55, "color": "#444444", "alpha": 0.70},
            zorder=7,
        )

    w_val = float(manova_26_comb["wilks_lambda"])
    wilks_str = f"{w_val:.2e}" if w_val < 1e-3 else f"{w_val:.4f}"
    ax_c.set_xlim(xlim_c)
    ax_c.set_ylim(ylim_c)
    ax_c.set_xlabel(f"Axe discriminant LD1 ({100.0 * var_r[0]:.1f}% var. inter)")
    ax_c.set_ylabel(f"Axe discriminant LD2 ({100.0 * var_r[1]:.1f}% var. inter)")
    ax_c.set_title(
        f"C. Espace canonique 26 régimes ($N={len(y):,}$)\n"
        f"MANOVA $\\Lambda_{{\\mathrm{{Wilks}}}} = {wilks_str}$, Pillai = {manova_26_comb['pillais_trace']:.3f}",
        fontsize=9.6,
        fontweight="bold",
    )
    ax_c.grid(True, alpha=0.3)

    fig.suptitle(
        "Expérience 5c — Séparabilité catégorielle (26×26), chevauchements transdiagnostiques et consolidation spectrale HiTOP",
        fontsize=12.8,
        fontweight="bold",
        y=0.96,
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=300, bbox_inches="tight")
    plt.close(fig)


def _plot_fig5d_therapeutic_matrix(
    bank: DSM5FullNosologyPriorBank,
    cohort_keys: tuple[str, ...],
    spectrum_keys: tuple[str, ...],
    tx_summary: dict[str, Any],
    spectrum_tx_curves: dict[str, dict[str, dict[str, np.ndarray]]],
    out_path: Path,
) -> None:
    sns.set_theme(style="whitegrid", context="paper")
    fig = plt.figure(figsize=(20.0, 14.2), dpi=300)
    gs = fig.add_gridspec(3, 4, height_ratios=[0.85, 0.85, 1.55], hspace=0.42, wspace=0.28, left=0.11, right=0.97, top=0.92, bottom=0.05)

    ind_t = int(tx_summary["induction_trials"])
    exp_t = int(tx_summary["exposure_trials"])
    tot_t = int(tx_summary["total_trials"])
    trials = np.arange(tot_t)

    modality_styles = {
        InterventionModality.NONE.value: ("#555555", "--", "Sans intervention"),
        InterventionModality.BOTTOM_UP_INTEROCEPTIVE.value: ("#1f78b4", "-.", "Ascendant (τ_A, τ_C)"),
        InterventionModality.TOP_DOWN_PRIOR_RELAXATION.value: ("#d95f02", ":", "Descendant (α_{z≥4})"),
        InterventionModality.COMBINED.value: ("#1b9e77", "-", "Approche combinée"),
    }

    # Haut (7 spectres HiTOP + panneau comparatif des 6 régimes les plus résistants sous NONE)
    for sp_idx, sp_name in enumerate(spectrum_keys):
        row_i, col_i = divmod(sp_idx, 4)
        ax = fig.add_subplot(gs[row_i, col_i])
        ax.axvspan(0, ind_t, color="#fde0dd", alpha=0.35, zorder=0)
        ax.axvspan(ind_t, ind_t + exp_t, color="#deebf7", alpha=0.35, zorder=0)
        ax.axvspan(ind_t + exp_t, tot_t - 1, color="#e5f5e0", alpha=0.38, zorder=0)
        ax.axvline(ind_t, color="#444444", ls=":", lw=0.9)
        ax.axvline(ind_t + exp_t, color="#444444", ls=":", lw=0.9)

        for m_val, (col_m, ls_m, lbl_m) in modality_styles.items():
            mean_z = spectrum_tx_curves[sp_name][m_val]["mean_z"]
            ci_z = spectrum_tx_curves[sp_name][m_val]["ci95_z"]
            ax.plot(trials, mean_z, color=col_m, ls=ls_m, lw=1.9, label=lbl_m)
            ax.fill_between(trials, np.maximum(0.0, mean_z - ci_z), mean_z + ci_z, color=col_m, alpha=0.13)

        n_c_sp = len([k for k in cohort_keys if bank.get_spec(k).hitop_spectrum == sp_name])
        ax.set_ylim(-0.1, 6.5)
        ax.set_xlim(0, tot_t - 1)
        ax.set_title(
            f"{SPECTRUM_SHORT_LABELS.get(sp_name, sp_name)} ({n_c_sp} cohorte{'s' if n_c_sp > 1 else ''})",
            fontsize=9.4,
            fontweight="bold",
            color=SPECTRUM_COLORS.get(sp_name, "#222222"),
        )
        if col_i == 0:
            ax.set_ylabel("Profondeur $Z_t$")
        if row_i == 1:
            ax.set_xlabel("Essai $t$ (Ind. | Expo. | Rém.)")
        if sp_idx == 0:
            ax.legend(fontsize=7.0, loc="upper right", frameon=True)

    # Panneau 7 : Top 6 régimes à plus forte charge résiduelle sous NONE vs COMBINED
    ax_top6 = fig.add_subplot(gs[1, 3])
    ax_top6.axvspan(0, ind_t, color="#fde0dd", alpha=0.30, zorder=0)
    ax_top6.axvspan(ind_t, ind_t + exp_t, color="#deebf7", alpha=0.30, zorder=0)
    ax_top6.axvspan(ind_t + exp_t, tot_t - 1, color="#e5f5e0", alpha=0.32, zorder=0)
    ax_top6.axvline(ind_t, color="#444444", ls=":", lw=0.9)
    ax_top6.axvline(ind_t + exp_t, color="#444444", ls=":", lw=0.9)
    top_res_keys = sorted(
        cohort_keys,
        key=lambda k: tx_summary["cohorts"][k]["modalities"][InterventionModality.NONE.value]["end_z_mean"],
        reverse=True,
    )[:6]
    for k in top_res_keys:
        sp = bank.get_spec(k)
        c_info = tx_summary["cohorts"][k]["modalities"]
        z_none = np.asarray(c_info[InterventionModality.NONE.value]["mean_z_curve"], dtype=np.float64)
        z_comb = np.asarray(c_info[InterventionModality.COMBINED.value]["mean_z_curve"], dtype=np.float64)
        ax_top6.plot(trials, z_none, color=sp.color, ls="--", lw=1.4, alpha=0.75)
        ax_top6.plot(trials, z_comb, color=sp.color, ls="-", lw=1.8, label=sp.short_label)
    ax_top6.set_ylim(-0.1, 6.5)
    ax_top6.set_xlim(0, tot_t - 1)
    ax_top6.set_xlabel("Essai $t$ (Pointillé: Sans tx | Plein: Combinée)")
    ax_top6.set_title("6 régimes les plus inertes : Sans tx vs Combinée", fontsize=9.2, fontweight="bold")
    ax_top6.legend(ncol=2, fontsize=6.8, loc="lower left", frameon=True)

    # Bas : tri des 26 cohortes par PdV rémission croissante (sévérité basale)
    sorted_keys_sev = sorted(
        cohort_keys,
        key=lambda k: tx_summary["cohorts"][k]["modalities"][InterventionModality.NONE.value]["pdv_remission_fraction"],
    )
    y_pos = np.arange(len(sorted_keys_sev))
    y_lbls = [bank.get_spec(k).short_label for k in sorted_keys_sev]

    # Bas-gauche : Graphique en haltères PdV en rémission (%)
    ax_pdv = fig.add_subplot(gs[2, 0:2])
    pdv_none = np.array([100.0 * tx_summary["cohorts"][k]["modalities"][InterventionModality.NONE.value]["pdv_remission_fraction"] for k in sorted_keys_sev])
    pdv_bu = np.array([100.0 * tx_summary["cohorts"][k]["modalities"][InterventionModality.BOTTOM_UP_INTEROCEPTIVE.value]["pdv_remission_fraction"] for k in sorted_keys_sev])
    pdv_td = np.array([100.0 * tx_summary["cohorts"][k]["modalities"][InterventionModality.TOP_DOWN_PRIOR_RELAXATION.value]["pdv_remission_fraction"] for k in sorted_keys_sev])
    pdv_comb = np.array([100.0 * tx_summary["cohorts"][k]["modalities"][InterventionModality.COMBINED.value]["pdv_remission_fraction"] for k in sorted_keys_sev])

    for i in range(len(sorted_keys_sev)):
        ax_pdv.plot([pdv_none[i], pdv_comb[i]], [y_pos[i], y_pos[i]], color="#bbbbbb", lw=2.2, zorder=2)
    ax_pdv.scatter(pdv_none, y_pos, s=46, color="#555555", marker="o", label="Sans intervention", zorder=4)
    ax_pdv.scatter(pdv_bu, y_pos, s=44, color="#1f78b4", marker="^", label="Ascendant (τ_A, τ_C)", zorder=5)
    ax_pdv.scatter(pdv_td, y_pos, s=44, color="#d95f02", marker="s", label="Descendant (α_{z≥4})", zorder=5)
    ax_pdv.scatter(pdv_comb, y_pos, s=56, color="#1b9e77", marker="D", edgecolors="black", linewidths=0.5, label="Approche combinée", zorder=6)

    ax_pdv.set_yticks(y_pos)
    ax_pdv.set_yticklabels(y_lbls, fontsize=8.0, fontweight="bold")
    for tl, k in zip(ax_pdv.get_yticklabels(), sorted_keys_sev):
        tl.set_color(SPECTRUM_COLORS.get(bank.get_spec(k).hitop_spectrum, "#222222"))
    ax_pdv.set_xlim(0.0, 106.0)
    ax_pdv.set_xlabel("Temps moyen au Point de Veille $(0,0,0)$ en rémission (%)")
    ax_pdv.set_title("I. Gain thérapeutique d'accès au Point de Veille $(0,0,0)$ sur les 26 régimes", fontsize=10.2, fontweight="bold")
    ax_pdv.legend(ncol=2, fontsize=7.6, loc="lower right", frameon=True)

    # Bas-droite : Barres horizontales de réduction relative AUC de Lyapunov (%)
    ax_red = fig.add_subplot(gs[2, 2:4])
    red_bu = []
    red_td = []
    red_comb = []
    for k in sorted_keys_sev:
        c_m = tx_summary["cohorts"][k]["modalities"]
        a_n = max(1e-6, c_m[InterventionModality.NONE.value]["auc_lyap_tx_mean"])
        red_bu.append(100.0 * (a_n - c_m[InterventionModality.BOTTOM_UP_INTEROCEPTIVE.value]["auc_lyap_tx_mean"]) / a_n)
        red_td.append(100.0 * (a_n - c_m[InterventionModality.TOP_DOWN_PRIOR_RELAXATION.value]["auc_lyap_tx_mean"]) / a_n)
        red_comb.append(100.0 * (a_n - c_m[InterventionModality.COMBINED.value]["auc_lyap_tx_mean"]) / a_n)

    bar_h = 0.27
    ax_red.barh(y_pos - bar_h, red_bu, height=bar_h, color="#1f78b4", label="Ascendant (τ_A, τ_C)")
    ax_red.barh(y_pos, red_td, height=bar_h, color="#d95f02", label="Descendant (α_{z≥4})")
    ax_red.barh(y_pos + bar_h, red_comb, height=bar_h, color="#1b9e77", label="Approche combinée")
    ax_red.axvline(0.0, color="#333333", lw=0.8)
    ax_red.set_yticks(y_pos)
    ax_red.set_yticklabels(y_lbls, fontsize=8.0)
    ax_red.set_xlabel("Réduction relative AUC potentiel de Lyapunov vs Sans intervention (%)")
    ax_red.set_title("J. Réduction de charge allostatique & double dissociation Ascendant vs Descendant", fontsize=10.2, fontweight="bold")
    ax_red.legend(fontsize=7.8, loc="lower right", frameon=True)

    fig.suptitle(
        "Expérience 5d — Synthèse spectrale et thérapeutique du rétablissement vers le Point de Veille $(0,0,0)$",
        fontsize=13.2,
        fontweight="bold",
        y=0.97,
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=300, bbox_inches="tight")
    plt.close(fig)


def _plot_fig5e_curves_all26(
    bank: DSM5FullNosologyPriorBank,
    cohort_keys: tuple[str, ...],
    tx_summary: dict[str, Any],
    double_dissoc: dict[str, dict[str, Any]],
    out_path: Path,
) -> None:
    sns.set_theme(style="whitegrid", context="paper")
    fig = plt.figure(figsize=(24.0, 19.5), dpi=300)
    gs = fig.add_gridspec(5, 6, hspace=0.45, wspace=0.24, left=0.04, right=0.96, top=0.93, bottom=0.04)

    ind_t = int(tx_summary["induction_trials"])
    exp_t = int(tx_summary["exposure_trials"])
    tot_t = int(tx_summary["total_trials"])
    trials = np.arange(tot_t)

    modality_styles = {
        InterventionModality.NONE.value: ("#555555", "--", "Sans intervention"),
        InterventionModality.BOTTOM_UP_INTEROCEPTIVE.value: ("#1f78b4", "-.", "Ascendant (τ_A, τ_C)"),
        InterventionModality.TOP_DOWN_PRIOR_RELAXATION.value: ("#d95f02", ":", "Descendant (α_{z≥4})"),
        InterventionModality.COMBINED.value: ("#1b9e77", "-", "Approche combinée"),
    }

    for idx, ckey in enumerate(cohort_keys):
        row_i, col_i = divmod(idx, 6)
        ax = fig.add_subplot(gs[row_i, col_i])
        spec = bank.get_spec(ckey)
        c_info = tx_summary["cohorts"][ckey]

        ax.axvspan(0, ind_t, color="#fde0dd", alpha=0.35, zorder=0)
        ax.axvspan(ind_t, ind_t + exp_t, color="#deebf7", alpha=0.35, zorder=0)
        ax.axvspan(ind_t + exp_t, tot_t - 1, color="#e5f5e0", alpha=0.38, zorder=0)
        ax.axvline(ind_t, color="#444444", ls=":", lw=0.8)
        ax.axvline(ind_t + exp_t, color="#444444", ls=":", lw=0.8)

        for m_val, (col_m, ls_m, lbl_m) in modality_styles.items():
            m_data = c_info["modalities"][m_val]
            mean_z = np.asarray(m_data["mean_z_curve"], dtype=np.float64)
            ci_z = np.asarray(m_data["ci95_z_curve"], dtype=np.float64)
            ax.plot(trials, mean_z, color=col_m, ls=ls_m, lw=1.7, label=lbl_m)
            ax.fill_between(trials, np.maximum(0.0, mean_z - ci_z), mean_z + ci_z, color=col_m, alpha=0.12)

        rem_none = 100.0 * c_info["modalities"][InterventionModality.NONE.value]["pdv_remission_fraction"]
        rem_comb = 100.0 * c_info["modalities"][InterventionModality.COMBINED.value]["pdv_remission_fraction"]
        pref_tag = {"bottom_up": "BU*", "top_down": "TD*", "equivalent": "Eq"}[double_dissoc[ckey]["preferred_monotherapy"]]

        ax.set_ylim(-0.1, 6.5)
        ax.set_xlim(0, tot_t - 1)
        ax.tick_params(labelsize=6.8)
        if col_i == 0:
            ax.set_ylabel("$Z_t$ (→0 PdV)", fontsize=7.6)
        if row_i == 4 or (row_i == 3 and col_i >= 2):
            ax.set_xlabel("Essai $t$", fontsize=7.6)
        ax.set_title(
            f"{spec.short_label} [{pref_tag}]\nPdV rém.: {rem_none:.0f}% → {rem_comb:.0f}%",
            fontsize=8.2,
            fontweight="bold",
            color=SPECTRUM_COLORS.get(spec.hitop_spectrum, spec.color),
        )
        if idx == 0:
            ax.legend(fontsize=6.4, loc="upper right", frameon=True)

    # 4 cases fusionnées en bas à droite : Nuage de double dissociation ΔAUC Ascendant vs Descendant
    ax_dd = fig.add_subplot(gs[4, 2:6])
    bu_red = np.array([double_dissoc[k]["bu_auc_reduction_pct"] for k in cohort_keys], dtype=np.float64)
    td_red = np.array([double_dissoc[k]["td_auc_reduction_pct"] for k in cohort_keys], dtype=np.float64)
    log_a0 = np.array(
        [math.log(max(1e-4, next(r["alpha_0"] for r in bank.summary_table() if r["cohort_key"] == k))) for k in cohort_keys],
        dtype=np.float64,
    )
    sc_dd = ax_dd.scatter(bu_red, td_red, c=log_a0, cmap="viridis", s=68, edgecolors="black", lw=0.7, zorder=5)
    cbar = fig.colorbar(sc_dd, ax=ax_dd, fraction=0.032, pad=0.02)
    cbar.set_label(r"$\log(\alpha_0)$ a priori", fontsize=8.8)

    lo_x = float(np.min(bu_red)) - 2.0
    hi_x = float(np.max(bu_red)) + 2.5
    lo_y = float(np.min(td_red)) - 2.2
    hi_y = float(np.max(td_red)) + 2.8
    lo_diag = min(lo_x, lo_y)
    hi_diag = max(hi_x, hi_y)
    ax_dd.plot([lo_diag, hi_diag], [lo_diag, hi_diag], color="#444444", ls="--", lw=1.2, label="Équivalence (Descendant = Ascendant)", zorder=3)
    ax_dd.text(lo_x + 0.03 * (hi_x - lo_x), hi_y - 0.09 * (hi_y - lo_y), "Domaine Descendant (α_{z≥4} > τ)", fontsize=8.4, color="#d95f02", fontweight="bold")
    ax_dd.text(hi_x - 0.34 * (hi_x - lo_x), lo_y + 0.14 * (hi_y - lo_y), "Domaine Ascendant (τ_A, τ_C > α)", fontsize=8.4, color="#1f78b4", fontweight="bold")

    dd_labels = [bank.get_spec(k).short_label for k in cohort_keys]
    anchors = _repel_label_positions(
        np.column_stack([bu_red, td_red]),
        (lo_x, hi_x),
        (lo_y, hi_y),
        labels=dd_labels,
        box_w_per_char=0.0076,
        box_h=0.072,
        n_iter=500,
        seed=23,
    )
    for i, ckey in enumerate(cohort_keys):
        spec = bank.get_spec(ckey)
        pref = double_dissoc[ckey]["preferred_monotherapy"]
        col_lbl = "#d95f02" if pref == "top_down" else ("#1f78b4" if pref == "bottom_up" else "#444444")
        ax_dd.annotate(
            spec.short_label,
            xy=(bu_red[i], td_red[i]),
            xytext=(anchors[i, 0], anchors[i, 1]),
            fontsize=6.9,
            fontweight="bold" if pref != "equivalent" else "normal",
            color=col_lbl,
            ha="center",
            va="center",
            bbox={"boxstyle": "round,pad=0.13", "facecolor": "white", "alpha": 0.86, "edgecolor": col_lbl, "lw": 0.4},
            arrowprops={"arrowstyle": "-", "lw": 0.55, "color": "#555555", "alpha": 0.70},
            zorder=6,
        )

    ax_dd.set_xlim(lo_x, hi_x)
    ax_dd.set_ylim(lo_y, hi_y)
    ax_dd.set_xlabel("Réduction AUC de Lyapunov sous Ascendant τ_A, τ_C (%)", fontsize=9.0)
    ax_dd.set_ylabel("Réduction AUC de Lyapunov sous Descendant α_{z≥4} (%)", fontsize=9.0)
    ax_dd.set_title("Double dissociation mécanistique Ascendant vs Descendant selon l'inertie basale log(α_0)", fontsize=9.8, fontweight="bold")
    ax_dd.legend(fontsize=7.8, loc="lower right", frameon=True)

    fig.suptitle(
        "Expérience 5e — Courbes individuelles de rétablissement vers le Point de Veille (0,0,0) pour les 26 régimes DSM-5",
        fontsize=13.5,
        fontweight="bold",
        y=0.975,
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=300, bbox_inches="tight")
    plt.close(fig)


# ---------------------------------------------------------------------------
# Pipeline expérimental complet (26 régimes pan-DSM-5)
# ---------------------------------------------------------------------------


def run_experiment(
    *,
    n_per_cohort: int = 100,
    n_therapy_per_cohort: int = 100,
    num_trials: int = 280,
    svi_steps: int = 750,
    svi_samples: int = 150,
    batch_size: int = 100,
    seed: int = 42,
    results_dir: Path | None = None,
) -> dict[str, Any]:
    """Exécute l'expérience 5 complète sur les 26 cohortes pan-DSM-5 et exporte tous les artefacts."""
    t_start = time.perf_counter()
    out_dir = (
        Path(results_dir)
        if results_dir is not None
        else ROOT_DIR / "results" / "dsm5_full_nosology"
    )
    out_dir.mkdir(parents=True, exist_ok=True)

    bank = DSM5FullNosologyPriorBank()
    cohort_keys = bank.cohort_keys
    assert cohort_keys == FULL_DSM5_COHORT_KEYS
    spectrum_keys = tuple(s for s in SPECTRUM_ORDER if s in bank.cohorts_by_spectrum())

    schedule = build_dsm5_phenotyping_schedule(num_trials=num_trials)
    cohorts = bank.sample_all_cohorts(n_per_cohort=n_per_cohort, seed=seed)

    # 1. Passage de la tâche orthogonale GenerativeProcess aux 26 × N agents
    all_profiles = [p for ckey in cohort_keys for p in cohorts[ckey]]
    sims_by_cohort: dict[str, list[Any]] = {ckey: [] for ckey in cohort_keys}
    all_sims: list[Any] = []
    for idx, prof in enumerate(all_profiles):
        sim_res = simulate_clinical_agent(prof, schedule=schedule, seed=seed + 10_000 + idx)
        sims_by_cohort[prof.cohort_key].append(sim_res)
        all_sims.append(sim_res)

    # 2. Inversion bayésienne aveugle aux cohortes (estimation θ̂_i)
    inversions = invert_clinical_batch_svi(
        [s.dataset for s in all_sims],
        seed=seed + 50_000,
        num_steps=svi_steps,
        num_posterior_samples=svi_samples,
        lr=0.025,
        batch_size=batch_size,
    )

    n_total = len(all_profiles)
    y = np.array([cohort_keys.index(p.cohort_key) for p in all_profiles], dtype=np.int32)
    y_spec = np.array(
        [spectrum_keys.index(bank.get_spec(p.cohort_key).hitop_spectrum) for p in all_profiles],
        dtype=np.int32,
    )
    true_theta_mat = np.array([[p.theta[pname] for pname in THETA_NAMES] for p in all_profiles], dtype=np.float64)
    est_theta_mat = np.array([[inv["means"][pname] for pname in THETA_NAMES] for inv in inversions], dtype=np.float64)
    ctrl_bias_true = np.array([p.ctrl_prior_bias for p in all_profiles], dtype=np.float64)
    ctrl_bias_hat = np.array([inv["means"]["ctrl_prior_bias"] for inv in inversions], dtype=np.float64)

    recovery_metrics: dict[str, dict[str, float]] = {}
    for j, pname in enumerate(THETA_NAMES):
        tr_col, es_col = true_theta_mat[:, j], est_theta_mat[:, j]
        cov_rate = float(
            np.mean([inversions[i]["ci95"][pname][0] <= tr_col[i] <= inversions[i]["ci95"][pname][1] for i in range(n_total)])
        )
        recovery_metrics[pname] = {
            "pearson_r": float(np.corrcoef(tr_col, es_col)[0, 1]),
            "rmse": float(np.sqrt(np.mean((es_col - tr_col) ** 2))),
            "bias": float(np.mean(es_col - tr_col)),
            "coverage_95": cov_rate,
        }
    recovery_metrics["ctrl_prior_bias"] = {
        "pearson_r": float(np.corrcoef(ctrl_bias_true, ctrl_bias_hat)[0, 1]),
        "rmse": float(np.sqrt(np.mean((ctrl_bias_hat - ctrl_bias_true) ** 2))),
        "bias": float(np.mean(ctrl_bias_hat - ctrl_bias_true)),
        "coverage_95": float(
            np.mean([inversions[i]["ci95"]["ctrl_prior_bias"][0] <= ctrl_bias_true[i] <= inversions[i]["ci95"]["ctrl_prior_bias"][1] for i in range(n_total)])
        ),
    }

    agent_rows: list[dict[str, Any]] = []
    for prof, sim_res, inv in zip(all_profiles, all_sims, inversions):
        spec = bank.get_spec(prof.cohort_key)
        row: dict[str, Any] = {
            "agent_id": prof.agent_id,
            "cohort_key": prof.cohort_key,
            "dsm5_chapter": spec.dsm5_chapter,
            "hitop_spectrum": spec.hitop_spectrum,
            "subregime": prof.subregime,
            "true_ctrl_prior_bias": prof.ctrl_prior_bias,
            "est_ctrl_prior_bias": inv["means"]["ctrl_prior_bias"],
            "elbo_final": inv["elbo_final"],
            "waic": inv["waic"],
            "bic": inv["bic"],
        }
        for pname in THETA_NAMES:
            row[f"true_{pname}"] = prof.theta[pname]
            row[f"est_{pname}"] = inv["means"][pname]
            row[f"sd_{pname}"] = inv["sds"][pname]
        for mkey, mval in sim_res.summary_metrics.items():
            row[f"traj_{mkey}"] = mval
        agent_rows.append(row)
    pd.DataFrame(agent_rows).to_csv(out_dir / "full_dsm5_cohort_theta_true_and_estimated.csv", index=False, encoding="utf-8")

    # 3. Analyse (a) : Densités d'occupation (X, Y, Z) & coordonnées Lexicon176
    occ_matrix = np.zeros((len(cohort_keys), len(ALL_176_ENTRIES)), dtype=np.float64)
    occ_summary: dict[str, Any] = {}
    xyz_rows: list[dict[str, Any]] = []

    for c_idx, ckey in enumerate(cohort_keys):
        spec = bank.get_spec(ckey)
        sub = sims_by_cohort[ckey]
        s_idx_all = np.concatenate([s.state_indices for s in sub])
        zs_all = np.concatenate([s.zs for s in sub])
        counts = np.bincount(s_idx_all, minlength=len(ALL_176_ENTRIES)).astype(np.float64)
        occ_probs = counts / float(np.sum(counts))
        occ_matrix[c_idx, :] = occ_probs

        z_counts = np.bincount(zs_all, minlength=8).astype(np.float64)
        z_probs = z_counts / float(np.sum(z_counts))

        top_non_pdv: list[dict[str, Any]] = []
        for s_i in np.argsort(occ_probs)[::-1]:
            entry = ALL_176_ENTRIES[int(s_i)]
            if entry.point == (0, 0, 0) or (entry.x == 0 and entry.y == 0 and entry.z == 0):
                continue
            top_non_pdv.append(
                {
                    "state_index": int(s_i),
                    "label": entry.label,
                    "x": int(entry.x),
                    "y": int(entry.y),
                    "z": int(entry.z),
                    "occupancy": float(occ_probs[s_i]),
                }
            )
            if len(top_non_pdv) >= 5:
                break

        occ_summary[ckey] = {
            "dsm5_chapter": spec.dsm5_chapter,
            "hitop_spectrum": spec.hitop_spectrum,
            "mean_x": float(np.mean([s.summary_metrics["mean_x"] for s in sub])),
            "mean_y": float(np.mean([s.summary_metrics["mean_y"] for s in sub])),
            "mean_z": float(np.mean([s.summary_metrics["mean_z"] for s in sub])),
            "mean_z_stress": float(np.mean([s.summary_metrics["mean_z_stress"] for s in sub])),
            "mean_z_remission": float(np.mean([s.summary_metrics["mean_z_remission"] for s in sub])),
            "pdv_occupancy_session": float(occ_probs[0]),
            "pdv_fraction_remission": float(np.mean([s.summary_metrics["pdv_fraction_remission"] for s in sub])),
            "probe_rate": float(np.mean([s.summary_metrics["probe_rate"] for s in sub])),
            "quadrant_pos_y": float(np.mean([s.summary_metrics["quadrant_pos_y"] for s in sub])),
            "quadrant_neg_neg": float(np.mean([s.summary_metrics["quadrant_neg_neg"] for s in sub])),
            "quadrant_neg_pos": float(np.mean([s.summary_metrics["quadrant_neg_pos"] for s in sub])),
            "quadrant_pos_pos": float(np.mean([s.summary_metrics["quadrant_pos_pos"] for s in sub])),
            "central_suspension_rate": float(np.mean([s.summary_metrics["central_suspension_rate"] for s in sub])),
            "state_switch_rate": float(np.mean([s.summary_metrics["state_switch_rate"] for s in sub])),
            "z4_z6_instability_ratio": float(np.mean([s.summary_metrics["z4_z6_instability_ratio"] for s in sub])),
            "stratum_distribution": z_probs.tolist(),
            "top_non_pdv_states": top_non_pdv,
        }
        dom1 = top_non_pdv[0]
        dom2 = top_non_pdv[1] if len(top_non_pdv) > 1 else dom1
        xyz_rows.append(
            {
                "cohort_key": ckey,
                "display_name": spec.display_name,
                **{k: v for k, v in occ_summary[ckey].items() if k not in ("stratum_distribution", "top_non_pdv_states")},
                "dominant_1_label": dom1["label"],
                "dominant_1_xyz": f"({dom1['x']:+d},{dom1['y']:+d},{dom1['z']})",
                "dominant_1_pct": 100.0 * dom1["occupancy"],
                "dominant_2_label": dom2["label"],
                "dominant_2_xyz": f"({dom2['x']:+d},{dom2['y']:+d},{dom2['z']})",
                "dominant_2_pct": 100.0 * dom2["occupancy"],
            }
        )

    pd.DataFrame(xyz_rows).to_csv(out_dir / "full_dsm5_xyz_occupation_summary.csv", index=False, encoding="utf-8")
    lex_cols = [f"{e.label}_({e.x},{e.y},{e.z})" for e in ALL_176_ENTRIES]
    pd.DataFrame(occ_matrix, index=list(cohort_keys), columns=lex_cols).to_csv(
        out_dir / "full_dsm5_lexicon176_occupancy_matrix.csv", encoding="utf-8"
    )

    # Signatures spécifiques TSPT bimodal et TPL Z=4,6 vs 25 autres cohortes
    ptsd_idx = cohort_keys.index("ptsd")
    ptsd_tau_a = est_theta_mat[y == ptsd_idx, THETA_NAMES.index("tau_A")]
    ptsd_susp = np.array([s.summary_metrics["central_suspension_rate"] for s in sims_by_cohort["ptsd"]])
    ptsd_bimodality = {
        "sarle_bc_tau_a_hat": _sarles_bimodality_coefficient(ptsd_tau_a),
        "sarle_bc_suspension": _sarles_bimodality_coefficient(ptsd_susp),
        "hypervigilance_count": int(sum(1 for s in sims_by_cohort["ptsd"] if s.profile.subregime == "ptsd_hypervigilance")),
        "dissociation_count": int(sum(1 for s in sims_by_cohort["ptsd"] if s.profile.subregime == "ptsd_dissociation")),
    }

    bpd_ratios = np.array([s.summary_metrics["z4_z6_instability_ratio"] for s in sims_by_cohort["bpd"]])
    bpd_raw_tests: dict[str, dict[str, Any]] = {}
    for other_k in cohort_keys:
        if other_k == "bpd":
            continue
        other_ratios = np.array([s.summary_metrics["z4_z6_instability_ratio"] for s in sims_by_cohort[other_k]])
        mw = stats.mannwhitneyu(bpd_ratios, other_ratios, alternative="greater")
        bpd_raw_tests[f"bpd_vs_{other_k}"] = {
            "u_stat": float(mw.statistic),
            "p_value": float(mw.pvalue),
            "bpd_mean": float(np.mean(bpd_ratios)),
            "other_mean": float(np.mean(other_ratios)),
        }
    sorted_bpd = sorted(bpd_raw_tests.keys(), key=lambda k: bpd_raw_tests[k]["p_value"])
    prev_p = 0.0
    for rk, bk in enumerate(sorted_bpd):
        adj = min(1.0, max(prev_p, bpd_raw_tests[bk]["p_value"] * (len(sorted_bpd) - rk)))
        prev_p = adj
        bpd_raw_tests[bk]["p_holm"] = float(adj)

    # 4. Analyse (b) : Séparabilité 26 régimes, 7 spectres HiTOP et dendrogramme Ward
    dyn_features = np.column_stack(
        [
            est_theta_mat,
            ctrl_bias_hat,
            np.array([s.summary_metrics["z4_z6_instability_ratio"] for s in all_sims], dtype=np.float64),
            np.array([s.summary_metrics["central_suspension_rate"] for s in all_sims], dtype=np.float64),
            np.array([s.summary_metrics["state_switch_rate"] for s in all_sims], dtype=np.float64),
        ]
    )

    cv_26_theta = _evaluate_cv_qda(est_theta_mat, y, cohort_keys, n_splits=10, reg_covar=0.08, seed=seed)
    cv_26_comb = _evaluate_cv_qda(dyn_features, y, cohort_keys, n_splits=10, reg_covar=0.08, seed=seed)
    sil_26_theta = _compute_silhouette_scores(est_theta_mat, y, cohort_keys)
    sil_26_comb = _compute_silhouette_scores(dyn_features, y, cohort_keys)
    manova_26_theta = _compute_manova_and_lda(est_theta_mat, y, len(cohort_keys))
    manova_26_comb = _compute_manova_and_lda(dyn_features, y, len(cohort_keys))

    cv_hitop_theta = _evaluate_cv_qda(est_theta_mat, y_spec, spectrum_keys, n_splits=10, reg_covar=0.08, seed=seed)
    cv_hitop_comb = _evaluate_cv_qda(dyn_features, y_spec, spectrum_keys, n_splits=10, reg_covar=0.08, seed=seed)
    sil_hitop_theta = _compute_silhouette_scores(est_theta_mat, y_spec, spectrum_keys)
    sil_hitop_comb = _compute_silhouette_scores(dyn_features, y_spec, spectrum_keys)
    manova_hitop_comb = _compute_manova_and_lda(dyn_features, y_spec, len(spectrum_keys))

    pairwise_rows, mahal_mat, z_linkage, coph_r = _compute_pairwise_and_ward(
        manova_26_theta["z_standardized"],
        y,
        manova_26_theta["pooled_within_cov"],
        cohort_keys,
        cv_26_theta["confusion_norm"],
        cv_26_comb["confusion_norm"],
        occ_matrix,
        reg_covar=0.08,
    )
    pd.DataFrame(pairwise_rows).to_csv(out_dir / "full_dsm5_pairwise_mahalanobis_and_jsd.csv", index=False, encoding="utf-8")
    pd.DataFrame(cv_26_theta["confusion_norm"], index=list(cohort_keys), columns=list(cohort_keys)).to_csv(
        out_dir / "full_dsm5_confusion_matrix_theta_hat.csv", encoding="utf-8"
    )
    pd.DataFrame(cv_26_comb["confusion_norm"], index=list(cohort_keys), columns=list(cohort_keys)).to_csv(
        out_dir / "full_dsm5_confusion_matrix_combined_features.csv", encoding="utf-8"
    )
    pd.DataFrame(cv_hitop_comb["confusion_norm"], index=list(spectrum_keys), columns=list(spectrum_keys)).to_csv(
        out_dir / "full_dsm5_confusion_matrix_hitop_spectra.csv", encoding="utf-8"
    )

    # 5. Analyse (c) : Courbes thérapeutiques appariées & double dissociation
    tx_profiles = [p for ckey in cohort_keys for p in cohorts[ckey][: min(n_therapy_per_cohort, len(cohorts[ckey]))]]
    tx_summary = TherapeuticIntervention.simulate_paired_recovery(
        tx_profiles,
        seed=seed + 90_000,
        induction_trials=80,
        exposure_trials=40,
        remission_trials=60,
    )

    # Courbes moyennes par spectre HiTOP (pondérées uniformément sur les agents du spectre)
    spectrum_tx_curves: dict[str, dict[str, dict[str, np.ndarray]]] = {}
    for sp_name in spectrum_keys:
        sp_cohorts = [k for k in cohort_keys if bank.get_spec(k).hitop_spectrum == sp_name]
        sp_dict: dict[str, dict[str, np.ndarray]] = {}
        for m_val in tx_summary["modalities"]:
            curves = [np.asarray(tx_summary["cohorts"][k]["modalities"][m_val]["mean_z_curve"], dtype=np.float64) for k in sp_cohorts]
            cis = [np.asarray(tx_summary["cohorts"][k]["modalities"][m_val]["ci95_z_curve"], dtype=np.float64) for k in sp_cohorts]
            mean_sp = np.mean(curves, axis=0)
            ci_sp = np.sqrt(np.mean(np.square(cis), axis=0)) / math.sqrt(max(1, len(sp_cohorts)))
            sp_dict[m_val] = {"mean_z": mean_sp, "ci95_z": ci_sp}
        spectrum_tx_curves[sp_name] = sp_dict

    double_dissoc: dict[str, dict[str, Any]] = {}
    tx_metric_rows: list[dict[str, Any]] = []
    tx_curve_rows: list[dict[str, Any]] = []
    for ckey in cohort_keys:
        spec = bank.get_spec(ckey)
        c_res = tx_summary["cohorts"][ckey]
        bu_vs_td = c_res["paired_tests"]["bottom_up_vs_top_down_auc_lyap"]
        auc_none = max(1e-6, float(c_res["modalities"][InterventionModality.NONE.value]["auc_lyap_tx_mean"]))
        auc_bu = float(c_res["modalities"][InterventionModality.BOTTOM_UP_INTEROCEPTIVE.value]["auc_lyap_tx_mean"])
        auc_td = float(c_res["modalities"][InterventionModality.TOP_DOWN_PRIOR_RELAXATION.value]["auc_lyap_tx_mean"])
        auc_comb = float(c_res["modalities"][InterventionModality.COMBINED.value]["auc_lyap_tx_mean"])
        if bu_vs_td["p_holm"] < 0.05:
            pref = "bottom_up" if bu_vs_td["mean_a"] < bu_vs_td["mean_b"] else "top_down"
        else:
            pref = "equivalent"

        double_dissoc[ckey] = {
            "dsm5_chapter": spec.dsm5_chapter,
            "hitop_spectrum": spec.hitop_spectrum,
            "preferred_monotherapy": pref,
            "p_holm_bu_vs_td": float(bu_vs_td["p_holm"]),
            "r_rb_bu_vs_td": float(bu_vs_td["r_rb"]),
            "bu_auc_reduction_pct": float(100.0 * (auc_none - auc_bu) / auc_none),
            "td_auc_reduction_pct": float(100.0 * (auc_none - auc_td) / auc_none),
            "comb_auc_reduction_pct": float(100.0 * (auc_none - auc_comb) / auc_none),
        }

        for m_val, m_stats in c_res["modalities"].items():
            tx_metric_rows.append(
                {
                    "cohort_key": ckey,
                    "dsm5_chapter": spec.dsm5_chapter,
                    "hitop_spectrum": spec.hitop_spectrum,
                    "modality": m_val,
                    "preferred_monotherapy": pref,
                    "n_agents": c_res["n_agents"],
                    "end_z_mean": m_stats["end_z_mean"],
                    "end_z_sd": m_stats["end_z_sd"],
                    "pdv_final_rate": m_stats["pdv_final_rate"],
                    "pdv_remission_fraction": m_stats["pdv_remission_fraction"],
                    "auc_z_tx_mean": m_stats["auc_z_tx_mean"],
                    "auc_lyap_tx_mean": m_stats["auc_lyap_tx_mean"],
                    "half_life_tx_mean": m_stats["half_life_tx_mean"],
                }
            )
            for t_i, (mz, ciz, ml, mpdv) in enumerate(
                zip(
                    m_stats["mean_z_curve"],
                    m_stats["ci95_z_curve"],
                    m_stats["mean_lyap_curve"],
                    m_stats["mean_pdv_curve"],
                )
            ):
                tx_curve_rows.append(
                    {
                        "cohort_key": ckey,
                        "modality": m_val,
                        "trial": t_i,
                        "mean_z": mz,
                        "ci95_z": ciz,
                        "mean_lyapunov": ml,
                        "pdv_rate": mpdv,
                    }
                )
    pd.DataFrame(tx_metric_rows).to_csv(out_dir / "full_dsm5_therapeutic_recovery_metrics.csv", index=False, encoding="utf-8")
    pd.DataFrame(tx_curve_rows).to_csv(out_dir / "full_dsm5_therapeutic_recovery_curves.csv", index=False, encoding="utf-8")

    # 6. 5 figures 300 DPI
    fig5a_path = out_dir / "fig5a_xyz_occupation_atlas_26.png"
    fig5b_path = out_dir / "fig5b_theta_profiles_and_dendrogram.png"
    fig5c_path = out_dir / "fig5c_confusion_26x26_and_hitop.png"
    fig5d_path = out_dir / "fig5d_therapeutic_recovery_matrix.png"
    fig5e_path = out_dir / "fig5e_therapeutic_curves_all26.png"

    _plot_fig5a_xyz_atlas_26(bank, cohort_keys, sims_by_cohort, occ_summary, fig5a_path)
    _plot_fig5b_dendrogram_and_profiles(
        bank, cohort_keys, est_theta_mat, ctrl_bias_hat, y, z_linkage, coph_r, occ_summary, fig5b_path
    )
    _plot_fig5c_confusion_and_hitop(
        bank,
        cohort_keys,
        spectrum_keys,
        cv_26_comb,
        cv_hitop_comb,
        sil_26_comb,
        sil_hitop_comb,
        manova_26_comb,
        y,
        fig5c_path,
    )
    _plot_fig5d_therapeutic_matrix(bank, cohort_keys, spectrum_keys, tx_summary, spectrum_tx_curves, fig5d_path)
    _plot_fig5e_curves_all26(bank, cohort_keys, tx_summary, double_dissoc, fig5e_path)

    sorted_by_sep = sorted(pairwise_rows, key=lambda r: (r["sym_confusion_combined"], -r["mahalanobis_distance"]))
    sorted_by_ovl = sorted(pairwise_rows, key=lambda r: (-r["sym_confusion_combined"], r["mahalanobis_distance"]))

    tx_compact = {
        "total_trials": tx_summary["total_trials"],
        "induction_trials": tx_summary["induction_trials"],
        "exposure_trials": tx_summary["exposure_trials"],
        "remission_trials": tx_summary["remission_trials"],
        "double_dissociation_by_cohort": double_dissoc,
        "double_dissociation_counts": dict(
            Counter(v["preferred_monotherapy"] for v in double_dissoc.values())
        ),
        "cohorts": {
            ckey: {
                "n_agents": tx_summary["cohorts"][ckey]["n_agents"],
                "modalities": {
                    m_val: {k: v for k, v in m_d.items() if not k.endswith("_curve")}
                    for m_val, m_d in tx_summary["cohorts"][ckey]["modalities"].items()
                },
                "paired_tests": tx_summary["cohorts"][ckey]["paired_tests"],
            }
            for ckey in cohort_keys
        },
    }

    summary = {
        "epistemological_note": (
            "Conformément à CARTOGRAFFECT®, les 26 cohortes pan-DSM-5 formalisent des régimes "
            "paramétriques dynamiques et des trajectoires fonctionnelles réversibles dans "
            "l'espace (X, Y, Z), et non des étiquettes diagnostiques statiques."
        ),
        "configuration": {
            "n_cohorts": len(cohort_keys),
            "n_chapters": len(bank.cohorts_by_chapter()),
            "n_hitop_spectra": len(spectrum_keys),
            "n_per_cohort": n_per_cohort,
            "n_total_agents": n_total,
            "n_therapy_per_cohort": min(n_therapy_per_cohort, n_per_cohort),
            "num_trials": num_trials,
            "svi_steps": svi_steps,
            "svi_samples": svi_samples,
            "runtime_seconds": round(time.perf_counter() - t_start, 2),
        },
        "cohort_priors": bank.summary_table(),
        "parameter_recovery": recovery_metrics,
        "xyz_occupation": occ_summary,
        "ptsd_bimodality": ptsd_bimodality,
        "bpd_z4_z6_instability_tests": bpd_raw_tests,
        "ward_hierarchy": {
            "cophenetic_correlation": coph_r,
            "linkage_matrix": z_linkage.tolist(),
        },
        "separability_26": {
            "theta_hat_only": {
                "accuracy": cv_26_theta["accuracy"],
                "balanced_accuracy": cv_26_theta["balanced_accuracy"],
                "macro_f1": cv_26_theta["macro_f1"],
                "cohen_kappa": cv_26_theta["cohen_kappa"],
                "n_folds": cv_26_theta["n_folds"],
                "per_class": cv_26_theta["per_class"],
                "confusion_norm": cv_26_theta["confusion_norm"].tolist(),
                "silhouette": sil_26_theta,
                "wilks_lambda": manova_26_theta["wilks_lambda"],
                "pillais_trace": manova_26_theta["pillais_trace"],
            },
            "theta_hat_plus_dynamics": {
                "accuracy": cv_26_comb["accuracy"],
                "balanced_accuracy": cv_26_comb["balanced_accuracy"],
                "macro_f1": cv_26_comb["macro_f1"],
                "cohen_kappa": cv_26_comb["cohen_kappa"],
                "n_folds": cv_26_comb["n_folds"],
                "per_class": cv_26_comb["per_class"],
                "confusion_norm": cv_26_comb["confusion_norm"].tolist(),
                "silhouette": sil_26_comb,
                "wilks_lambda": manova_26_comb["wilks_lambda"],
                "pillais_trace": manova_26_comb["pillais_trace"],
            },
            "clearest_separations_top12": sorted_by_sep[:12],
            "transdiagnostic_overlaps_top12": sorted_by_ovl[:12],
        },
        "separability_hitop_spectra": {
            "spectrum_keys": list(spectrum_keys),
            "theta_hat_only": {
                "accuracy": cv_hitop_theta["accuracy"],
                "balanced_accuracy": cv_hitop_theta["balanced_accuracy"],
                "macro_f1": cv_hitop_theta["macro_f1"],
                "cohen_kappa": cv_hitop_theta["cohen_kappa"],
                "per_class": cv_hitop_theta["per_class"],
                "confusion_norm": cv_hitop_theta["confusion_norm"].tolist(),
                "silhouette": sil_hitop_theta,
            },
            "theta_hat_plus_dynamics": {
                "accuracy": cv_hitop_comb["accuracy"],
                "balanced_accuracy": cv_hitop_comb["balanced_accuracy"],
                "macro_f1": cv_hitop_comb["macro_f1"],
                "cohen_kappa": cv_hitop_comb["cohen_kappa"],
                "per_class": cv_hitop_comb["per_class"],
                "confusion_norm": cv_hitop_comb["confusion_norm"].tolist(),
                "silhouette": sil_hitop_comb,
                "wilks_lambda": manova_hitop_comb["wilks_lambda"],
                "pillais_trace": manova_hitop_comb["pillais_trace"],
            },
        },
        "therapeutic_recovery": tx_compact,
        "figures": {
            k: (
                p.resolve().relative_to(ROOT_DIR.resolve()).as_posix()
                if p.resolve().is_relative_to(ROOT_DIR.resolve())
                else p.name
            )
            for k, p in (
                ("fig5a", fig5a_path),
                ("fig5b", fig5b_path),
                ("fig5c", fig5c_path),
                ("fig5d", fig5d_path),
                ("fig5e", fig5e_path),
            )
        },
    }
    (out_dir / "full_dsm5_separability_and_nosology_summary.json").write_text(
        json.dumps(summary, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    return summary


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Expérience 5 : Panorama pan-DSM-5 des 26 régimes cliniques transdiagnostiques."
    )
    parser.add_argument("--n-per-cohort", type=int, default=100)
    parser.add_argument("--n-therapy-per-cohort", type=int, default=100)
    parser.add_argument("--num-trials", type=int, default=280)
    parser.add_argument("--svi-steps", type=int, default=750)
    parser.add_argument("--svi-samples", type=int, default=150)
    parser.add_argument("--batch-size", type=int, default=100)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--output-dir", type=Path, default=None)
    args = parser.parse_args()

    summary = run_experiment(
        n_per_cohort=args.n_per_cohort,
        n_therapy_per_cohort=args.n_therapy_per_cohort,
        num_trials=args.num_trials,
        svi_steps=args.svi_steps,
        svi_samples=args.svi_samples,
        batch_size=args.batch_size,
        seed=args.seed,
        results_dir=args.output_dir,
    )
    print(f"Runtime: {summary['configuration']['runtime_seconds']:.1f}s")
    print("SVI Recovery r (N_total =", summary["configuration"]["n_total_agents"], "):")
    for pname, m in summary["parameter_recovery"].items():
        print(f"  {pname:16s}: r={m['pearson_r']:.4f}, rmse={m['rmse']:.4f}, cov95={m['coverage_95']:.3f}")
    s26_t = summary["separability_26"]["theta_hat_only"]
    s26_c = summary["separability_26"]["theta_hat_plus_dynamics"]
    sp_c = summary["separability_hitop_spectra"]["theta_hat_plus_dynamics"]
    print(
        f"CV Accuracy 26 regimes theta_hat={100*s26_t['accuracy']:.1f}% (kappa={s26_t['cohen_kappa']:.3f}) | "
        f"combined={100*s26_c['accuracy']:.1f}% (kappa={s26_c['cohen_kappa']:.3f}) | "
        f"7 HiTOP spectra={100*sp_c['accuracy']:.1f}% | Ward coph_r={summary['ward_hierarchy']['cophenetic_correlation']:.3f}"
    )
    print("Double dissociation counts:", summary["therapeutic_recovery"]["double_dissociation_counts"])


if __name__ == "__main__":
    main()

