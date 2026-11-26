"""[SYNTHETIC EXPLORATORY ONLY — V3 = 0]
QUARANTAINE EXPLORATOIRE — AUCUNE VALIDATION CLINIQUE OU NOSOLOGIQUE EXTERNE.
Ce script génère des agents synthétiques à partir de lois a priori paramétriques
définies dans le simulateur (zéro donnée patient humaine, V3 = 0). Les taux de
séparabilité et réponses simulées ne prouvent aucun phénomène nosologique ou
thérapeutique réel.

Expérience 4 : Simulation exploratoire synthétique sur 8 cohortes paramétriques (inspirées DSM-5).

Étend la validation in silico à 8 cohortes cliniques synthétiques (N = 200 agents
chacune, soit 1 600 agents au total) formalisées comme régimes paramétriques
dynamiques dans ``DSM5PriorBank`` (et non comme étiquettes diagnostiques statiques) :
    1. Contrôle normothymique (``normothymic``)
    2. Trouble dépressif caractérisé inhibé (``mdd_inhibited``)
    3. Trouble anxieux généralisé (``gad``)
    4. Trouble panique (``panic``)
    5. Épisode maniaque (``mania``)
    6. Trouble obsessionnel-compulsif (``ocd``)
    7. Trouble de stress post-traumatique (``ptsd``, bimodal hypervigilance/dissociation)
    8. Trouble de la personnalité limite (``bpd``, instabilité en strates Z=4 et Z=6)

Pipeline complet :
    - Simulation des 1 600 agents sur la tâche orthogonale ``GenerativeProcess``
      (``NonStationaryBanditEnv``, 280 essais sans fuite de labels cachés) ;
    - Inversion bayésienne aveugle aux cohortes sous NumPyro SVI (estimation θ̂_i) ;
    - (a) Densités d'occupation (X, Y, Z) et coordonnées dominantes ``Lexicon176`` ;
    - (b) Matrices de confusion inter-syndromiques (CV stratifiée 10 plis, QDA
          régularisée, silhouette, Mahalanobis, Bhattacharyya, MANOVA Wilks/Pillai)
          identifiant séparations nettes et chevauchements transdiagnostiques ;
    - (c) Courbes de rétablissement appariées vers le Point de Veille (0, 0, 0) sous
          les trois modalités de ``TherapeuticIntervention`` (ascendant τ_A/τ_C,
          descendant α_{z>=4}, approche combinée) vs sans intervention.

Exporte figures 300 DPI, tableaux CSV et rapport JSON dans ``results/dsm5_phenotyping/``.
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
from scipy.spatial.distance import cdist, jensenshannon

ROOT_DIR = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT_DIR / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from cartograffect_sim.clinical_profiles import (  # noqa: E402
    COHORT_KEYS,
    DSM5PriorBank,
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


# ---------------------------------------------------------------------------
# Utilitaires purs NumPy / SciPy pour séparabilité & classification CV
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
        train_parts = [
            np.concatenate(per_class_folds[j]) for j in range(k_eff) if j != fold_i
        ]
        train_idx = np.concatenate(train_parts)
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

    preds = np.argmax(log_scores, axis=1).astype(np.int32)
    return preds, log_scores


def _compute_classification_metrics(
    y_true: np.ndarray,
    y_pred: np.ndarray,
    cohort_keys: Sequence[str],
) -> dict[str, Any]:
    n_cls = len(cohort_keys)
    cm = np.zeros((n_cls, n_cls), dtype=np.int64)
    for t_lbl, p_lbl in zip(y_true, y_pred):
        cm[int(t_lbl), int(p_lbl)] += 1

    row_sums = cm.sum(axis=1, keepdims=True)
    cm_norm = cm / np.maximum(1, row_sums)
    total = float(np.sum(cm))
    accuracy = float(np.trace(cm) / max(1.0, total))

    p_o = accuracy
    p_e = float(np.sum(cm.sum(axis=1) * cm.sum(axis=0)) / max(1.0, total**2))
    kappa = float((p_o - p_e) / max(1e-12, 1.0 - p_e))

    per_class: dict[str, dict[str, float]] = {}
    recalls: list[float] = []
    f1s: list[float] = []
    for k, ckey in enumerate(cohort_keys):
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
    cohort_keys: Sequence[str],
    *,
    n_splits: int = 10,
    reg_covar: float = 0.08,
    seed: int = 42,
) -> dict[str, Any]:
    folds = _stratified_kfold_indices(y, n_splits=n_splits, seed=seed)
    y_pred = np.zeros_like(y)
    n_cls = len(cohort_keys)
    for train_idx, test_idx in folds:
        preds, _ = _fit_predict_qda(
            x_feat[train_idx],
            y[train_idx],
            x_feat[test_idx],
            n_classes=n_cls,
            reg_covar=reg_covar,
        )
        y_pred[test_idx] = preds
    res = _compute_classification_metrics(y, y_pred, cohort_keys)
    res["n_folds"] = len(folds)
    res["y_pred"] = y_pred
    return res


def _compute_silhouette_scores(
    x_feat: np.ndarray,
    y: np.ndarray,
    cohort_keys: Sequence[str],
) -> dict[str, Any]:
    mu = np.mean(x_feat, axis=0)
    sd = np.maximum(1e-6, np.std(x_feat, axis=0, ddof=1 if len(x_feat) > 1 else 0))
    z = (x_feat - mu) / sd
    dist_mat = cdist(z, z, metric="euclidean")
    n = len(z)
    n_cls = len(cohort_keys)
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

    by_cohort = {
        ckey: float(np.mean(sil[masks[k]])) if np.any(masks[k]) else 0.0
        for k, ckey in enumerate(cohort_keys)
    }
    return {
        "global_silhouette": float(np.mean(sil)),
        "silhouette_by_cohort": by_cohort,
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


def _compute_pairwise_separability(
    z_std: np.ndarray,
    y: np.ndarray,
    pooled_cov: np.ndarray,
    cohort_keys: Sequence[str],
    cm_theta_norm: np.ndarray,
    cm_comb_norm: np.ndarray,
    occ_matrix: np.ndarray,
    reg_covar: float = 0.08,
) -> list[dict[str, Any]]:
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

    rows: list[dict[str, Any]] = []
    for i in range(n_cls):
        for j in range(i + 1, n_cls):
            dm = means_k[i] - means_k[j]
            mahal = float(math.sqrt(max(0.0, float(dm.T @ inv_pooled @ dm))))
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
    return rows


# ---------------------------------------------------------------------------
# Génération des 4 figures comparatives (300 DPI)
# ---------------------------------------------------------------------------


def _plot_fig4a_xyz_densities(
    bank: DSM5PriorBank,
    sims_by_cohort: dict[str, list[Any]],
    occ_summary: dict[str, Any],
    out_path: Path,
) -> None:
    sns.set_theme(style="whitegrid", context="paper")
    fig, axes = plt.subplots(2, 4, figsize=(18.0, 9.6), dpi=300)
    flat_axes = axes.ravel()
    cmap = plt.get_cmap("plasma")

    sc = None
    for idx, ckey in enumerate(COHORT_KEYS):
        ax = flat_axes[idx]
        spec = bank.get_spec(ckey)
        sub_sims = sims_by_cohort[ckey]

        for radius, ls, alpha_r in [(2, ":", 0.35), (6, "--", 0.30), (10, "-.", 0.25), (12, "-", 0.18)]:
            px = [radius, 0, -radius, 0, radius]
            py = [0, radius, 0, -radius, 0]
            ax.plot(px, py, linestyle=ls, color="#666666", lw=0.85, alpha=alpha_r)
        ax.axhline(0, color="#aaaaaa", lw=0.75, alpha=0.6)
        ax.axvline(0, color="#aaaaaa", lw=0.75, alpha=0.6)

        xs_all = np.concatenate([s.xs for s in sub_sims])
        ys_all = np.concatenate([s.ys for s in sub_sims])
        zs_all = np.concatenate([s.zs for s in sub_sims])
        n_total = float(len(xs_all))

        # Comptage exact des 176 points (x, y, z)
        pt_counts = Counter(zip(xs_all.tolist(), ys_all.tolist(), zs_all.tolist()))
        periph_pts = [(pt, cnt / n_total) for pt, cnt in pt_counts.items() if (pt[0], pt[1]) != (0, 0)]
        periph_pts.sort(key=lambda item: item[1])

        if periph_pts:
            px_vals = np.array([p[0][0] for p in periph_pts], dtype=np.float64)
            py_vals = np.array([p[0][1] for p in periph_pts], dtype=np.float64)
            pz_vals = np.array([p[0][2] for p in periph_pts], dtype=np.float64)
            pf_vals = np.array([p[1] for p in periph_pts], dtype=np.float64)
            sizes = 22.0 + 2400.0 * pf_vals
            sc = ax.scatter(
                px_vals,
                py_vals,
                c=pz_vals,
                cmap=cmap,
                vmin=1,
                vmax=7,
                s=sizes,
                alpha=0.82,
                edgecolors="black",
                linewidths=0.35,
                zorder=4,
            )

        pdv_frac = float(pt_counts.get((0, 0, 0), 0)) / n_total
        susp_frac = sum(
            cnt for (xx, yy, zz), cnt in pt_counts.items() if xx == 0 and yy == 0 and zz >= 2
        ) / n_total
        surp_frac = float(pt_counts.get((0, 0, 1), 0)) / n_total

        ax.scatter(
            [0],
            [0],
            marker="*",
            s=110.0 + 480.0 * pdv_frac,
            color="#ffd92f",
            edgecolors="black",
            linewidths=0.7,
            zorder=6,
        )
        if susp_frac > 0.02:
            ax.scatter(
                [0],
                [0],
                marker="o",
                s=180.0 + 900.0 * susp_frac,
                facecolors="none",
                edgecolors="#8c2d04",
                linewidths=1.8,
                zorder=5,
            )

        top_non_pdv = occ_summary[ckey]["top_non_pdv_states"][:2]
        top_lines = [
            f"{st['label']} ({st['x']:+d},{st['y']:+d},{st['z']}): {100.0 * st['occupancy']:.1f}%"
            for st in top_non_pdv
        ]
        badge = (
            f"PdV(0,0,0): {100.0 * pdv_frac:.1f}% | Cent(Z≥2): {100.0 * susp_frac:.1f}% | Surp: {100.0 * surp_frac:.1f}%\n"
            + "\n".join(top_lines)
        )
        ax.text(
            0.03,
            0.03,
            badge,
            transform=ax.transAxes,
            fontsize=7.3,
            va="bottom",
            ha="left",
            bbox={"boxstyle": "round,pad=0.28", "facecolor": "white", "alpha": 0.88, "edgecolor": spec.color},
            zorder=8,
        )

        # Annoter les 2 coordonnées périphériques majeures hors superposition
        if top_non_pdv:
            st0 = top_non_pdv[0]
            if (st0["x"], st0["y"]) != (0, 0):
                dx_off = 1.4 if st0["x"] >= 0 else -1.4
                dy_off = 1.6 if st0["y"] >= 0 else -1.6
                ax.annotate(
                    f"{st0['label']}\n({st0['x']:+d},{st0['y']:+d},{st0['z']})",
                    xy=(st0["x"], st0["y"]),
                    xytext=(np.clip(st0["x"] + dx_off, -10.5, 10.5), np.clip(st0["y"] + dy_off, -10.5, 10.5)),
                    fontsize=7.4,
                    fontweight="bold",
                    color="#222222",
                    ha="center",
                    arrowprops={"arrowstyle": "->", "lw": 0.8, "color": "#444444"},
                    zorder=7,
                )

        m_x = occ_summary[ckey]["mean_x"]
        m_y = occ_summary[ckey]["mean_y"]
        m_z = occ_summary[ckey]["mean_z"]
        ax.set_xlim(-12.8, 12.8)
        ax.set_ylim(-12.8, 12.8)
        if idx >= 4:
            ax.set_xlabel("Axe épistémique $X$")
        if idx % 4 == 0:
            ax.set_ylabel("Axe pragmatique $Y$")
        ax.set_title(
            f"{spec.short_label} ($N={len(sub_sims)}$)\n"
            f"$\\bar{{X}}={m_x:+.2f},\\;\\bar{{Y}}={m_y:+.2f},\\;\\bar{{Z}}={m_z:.2f}$",
            fontsize=9.6,
            fontweight="bold",
            color=spec.color,
        )

    fig.subplots_adjust(hspace=0.36, wspace=0.20, right=0.90, top=0.90, bottom=0.07)
    if sc is not None:
        cbar_ax = fig.add_axes([0.915, 0.12, 0.015, 0.76])
        cbar = fig.colorbar(sc, cax=cbar_ax)
        cbar.set_label("Strate hiérarchique $Z$ (taille $\\propto$ densité d'occupation)", fontsize=9.5)

    n_per = len(next(iter(sims_by_cohort.values())))
    n_agents_all = sum(len(v) for v in sims_by_cohort.values())
    fig.suptitle(
        f"Expérience 4a — Densités d'occupation $(X, Y, Z)$ et coordonnées dominantes Lexicon176 ($8 \\times {n_per} = {n_agents_all:,}$ agents)",
        fontsize=12.8,
        fontweight="bold",
        y=0.975,
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=300, bbox_inches="tight")
    plt.close(fig)


def _plot_fig4b_profiles_and_signatures(
    bank: DSM5PriorBank,
    est_theta_mat: np.ndarray,
    y: np.ndarray,
    ctrl_bias_hat: np.ndarray,
    occ_summary: dict[str, Any],
    bpd_tests: dict[str, Any],
    ptsd_bimodality: dict[str, float],
    sims_by_cohort: dict[str, list[Any]],
    out_path: Path,
) -> None:
    sns.set_theme(style="whitegrid", context="paper")
    fig, axes = plt.subplots(2, 2, figsize=(15.5, 11.2), dpi=300)

    # A. Empreinte z-score des paramètres estimés θ̂ + δ_c par cohorte
    ax_a = axes[0, 0]
    feat_full = np.column_stack([est_theta_mat, ctrl_bias_hat])
    feat_z = (feat_full - feat_full.mean(axis=0)) / np.maximum(1e-6, feat_full.std(axis=0, ddof=1))
    mean_mat = np.vstack([feat_z[y == k].mean(axis=0) for k in range(len(COHORT_KEYS))])
    col_labels = [THETA_TEX_LABELS[p] for p in THETA_NAMES] + [r"$\hat{\delta}_c$"]
    row_labels = [bank.get_spec(k).short_label for k in COHORT_KEYS]
    df_heat = pd.DataFrame(mean_mat, index=row_labels, columns=col_labels)
    sns.heatmap(
        df_heat,
        annot=True,
        fmt=".2f",
        cmap="RdBu_r",
        center=0.0,
        vmin=-2.0,
        vmax=2.0,
        linewidths=0.5,
        annot_kws={"size": 8.2},
        cbar_kws={"label": "Score $z$ moyen par cohorte"},
        ax=ax_a,
    )
    ax_a.set_title("A. Empreintes paramétriques inversées ($\\hat{\\theta}_i, \\hat{\\delta}_c$)", fontsize=10.5, fontweight="bold")
    ax_a.tick_params(axis="x", labelsize=9.0)
    ax_a.tick_params(axis="y", rotation=0, labelsize=8.8)

    # B. Distribution des strates hiérarchiques Z = 0..7
    ax_b = axes[0, 1]
    z_grid = np.arange(8)
    for ckey in COHORT_KEYS:
        spec = bank.get_spec(ckey)
        probs_z = occ_summary[ckey]["stratum_distribution"]
        ax_b.plot(
            z_grid,
            probs_z,
            marker="o",
            lw=2.0,
            ms=4.8,
            color=spec.color,
            label=spec.short_label,
        )
    ax_b.set_xticks(z_grid)
    ax_b.set_xlabel("Strate hiérarchique $Z$")
    ax_b.set_ylabel("Probabilité d'occupation $P(Z)$")
    ax_b.set_title("B. Profil d'occupation des strates $Z = 0\\dots 7$", fontsize=10.5, fontweight="bold")
    ax_b.legend(ncol=2, fontsize=8.0, frameon=True)

    # C. TSPT bimodal (Hypervigilance vs Dissociation)
    ax_c = axes[1, 0]
    ptsd_sims = sims_by_cohort["ptsd"]
    ptsd_idx = COHORT_KEYS.index("ptsd")
    ptsd_tau_a = est_theta_mat[y == ptsd_idx, THETA_NAMES.index("tau_A")]
    ptsd_susp = np.array([s.summary_metrics["central_suspension_rate"] for s in ptsd_sims])
    ptsd_sub = [s.profile.subregime for s in ptsd_sims]
    hyp_mask = np.array([sr == "ptsd_hypervigilance" for sr in ptsd_sub])
    dis_mask = ~hyp_mask
    ax_c.scatter(
        ptsd_tau_a[hyp_mask],
        ptsd_susp[hyp_mask],
        s=32,
        alpha=0.78,
        color="#e6550d",
        edgecolors="black",
        linewidths=0.35,
        label=f"Hypervigilance ($n={int(np.sum(hyp_mask))}$)",
    )
    ax_c.scatter(
        ptsd_tau_a[dis_mask],
        ptsd_susp[dis_mask],
        s=32,
        alpha=0.78,
        color="#54278f",
        edgecolors="black",
        linewidths=0.35,
        label=f"Dissociation ($n={int(np.sum(dis_mask))}$)",
    )
    ax_c.set_xlabel(r"Seuil épistémique estimé $\hat{\tau}_A$")
    ax_c.set_ylabel("Taux d'opérateurs centraux $(0,0,Z\\geq 2)$")
    ax_c.set_title(
        f"C. TSPT bimodal : $BC(\\hat{{\\tau}}_A) = {ptsd_bimodality['sarle_bc_tau_a_hat']:.3f} > 0.556$, "
        f"$BC(\\mathrm{{susp.}}) = {ptsd_bimodality['sarle_bc_suspension']:.3f}$",
        fontsize=10.2,
        fontweight="bold",
    )
    ax_c.legend(fontsize=8.5, frameon=True)

    # D. TPL : instabilité de précision aux strates Z=4 et Z=6
    ax_d = axes[1, 1]
    box_rows: list[dict[str, Any]] = []
    palette: dict[str, str] = {}
    for ckey in COHORT_KEYS:
        spec = bank.get_spec(ckey)
        palette[spec.short_label] = spec.color
        for s in sims_by_cohort[ckey]:
            box_rows.append(
                {
                    "Cohorte": spec.short_label,
                    "Ratio": float(s.summary_metrics["z4_z6_instability_ratio"]),
                }
            )
    box_df = pd.DataFrame(box_rows)
    sns.boxplot(
        data=box_df,
        x="Cohorte",
        y="Ratio",
        hue="Cohorte",
        palette=palette,
        legend=False,
        fliersize=2.0,
        ax=ax_d,
    )
    max_p_holm = max(v["p_holm"] for v in bpd_tests.values())
    ax_d.axhline(1.0, ls="--", color="#555555", lw=1.0)
    ax_d.set_xlabel("")
    ax_d.set_ylabel(r"Ratio d'instabilité $|\Delta g|_{Z\in\{4,6\}} / |\Delta g|_{Z\in\{2,3\}}$")
    ax_d.set_title(
        f"D. TPL : instabilité de précision aux strates $Z=4, 6$ ($\\max p_{{\\mathrm{{Holm}}}} = {_format_p(max_p_holm)}$)",
        fontsize=10.2,
        fontweight="bold",
    )
    ax_d.tick_params(axis="x", rotation=25, labelsize=8.3)

    fig.suptitle(
        "Expérience 4 — Signatures paramétriques $\\hat{\\theta}_i$, strates $Z$ et régimes non stationnaires (TSPT / TPL)",
        fontsize=12.6,
        fontweight="bold",
        y=0.985,
    )
    fig.tight_layout(rect=(0, 0, 1, 0.955))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=300)
    plt.close(fig)


def _plot_fig4c_confusion_and_lda(
    bank: DSM5PriorBank,
    cv_theta: dict[str, Any],
    cv_combined: dict[str, Any],
    manova_comb: dict[str, Any],
    y: np.ndarray,
    sil_theta: dict[str, Any],
    sil_comb: dict[str, Any],
    out_path: Path,
) -> None:
    sns.set_theme(style="white", context="paper")
    fig, axes = plt.subplots(1, 3, figsize=(19.2, 6.2), dpi=300)
    labels = [bank.get_spec(k).short_label for k in COHORT_KEYS]

    # A. Confusion sur θ̂_i seul (8 paramètres canoniques)
    df_a = pd.DataFrame(cv_theta["confusion_norm"], index=labels, columns=labels)
    sns.heatmap(
        df_a,
        annot=True,
        fmt=".2f",
        cmap="Blues",
        vmin=0.0,
        vmax=1.0,
        linewidths=0.5,
        annot_kws={"size": 8.0},
        cbar=True,
        ax=axes[0],
    )
    axes[0].set_title(
        f"A. Matrice de confusion ($\\hat{{\\theta}}_i$ seul, CV {cv_theta['n_folds']} plis)\n"
        f"Exact. = {100.0 * cv_theta['accuracy']:.1f}%, $\\kappa$ = {cv_theta['cohen_kappa']:.3f}, Silh. = {sil_theta['global_silhouette']:.3f}",
        fontsize=9.8,
        fontweight="bold",
    )
    axes[0].set_xlabel("Régime prédit")
    axes[0].set_ylabel("Cohorte génératrice")
    axes[0].tick_params(axis="x", rotation=32, labelsize=8.2)
    axes[0].tick_params(axis="y", rotation=0, labelsize=8.2)

    # B. Confusion sur θ̂_i + marqueurs dynamiques observables
    df_b = pd.DataFrame(cv_combined["confusion_norm"], index=labels, columns=labels)
    sns.heatmap(
        df_b,
        annot=True,
        fmt=".2f",
        cmap="YlGnBu",
        vmin=0.0,
        vmax=1.0,
        linewidths=0.5,
        annot_kws={"size": 8.0},
        cbar=True,
        ax=axes[1],
    )
    axes[1].set_title(
        f"B. Confusion ($\\hat{{\\theta}}_i$ + dynamique $\\hat{{\\delta}}_c$, $Z_{{4,6}}$, susp.)\n"
        f"Exact. = {100.0 * cv_combined['accuracy']:.1f}%, $\\kappa$ = {cv_combined['cohen_kappa']:.3f}, Silh. = {sil_comb['global_silhouette']:.3f}",
        fontsize=9.8,
        fontweight="bold",
    )
    axes[1].set_xlabel("Régime prédit")
    axes[1].set_ylabel("")
    axes[1].tick_params(axis="x", rotation=32, labelsize=8.2)
    axes[1].tick_params(axis="y", rotation=0, labelsize=8.2)

    # C. Projection LDA 2D des 1 600 agents + ellipses 1-σ
    ax_c = axes[2]
    proj = manova_comb["lda_2d"]
    var_r = manova_comb["lda_explained_ratio"]
    for k, ckey in enumerate(COHORT_KEYS):
        spec = bank.get_spec(ckey)
        pts_k = proj[y == k]
        ax_c.scatter(
            pts_k[:, 0],
            pts_k[:, 1],
            s=12,
            alpha=0.38,
            color=spec.color,
            edgecolors="none",
            label=spec.short_label,
        )
        if len(pts_k) > 2:
            mean_k = pts_k.mean(axis=0)
            cov_k = np.cov(pts_k, rowvar=False)
            vals, vecs = np.linalg.eigh(cov_k)
            order = vals.argsort()[::-1]
            vals, vecs = np.maximum(1e-6, vals[order]), vecs[:, order]
            angle = math.degrees(math.atan2(vecs[1, 0], vecs[0, 0]))
            ell = Ellipse(
                xy=mean_k,
                width=2.5 * math.sqrt(vals[0]),
                height=2.5 * math.sqrt(vals[1]),
                angle=angle,
                edgecolor=spec.color,
                facecolor="none",
                lw=1.8,
                ls="-",
                zorder=5,
            )
            ax_c.add_patch(ell)
            ax_c.scatter([mean_k[0]], [mean_k[1]], marker="X", s=70, color=spec.color, edgecolors="black", zorder=6)

    ax_c.set_xlabel(f"Axe discriminant LD1 ({100.0 * var_r[0]:.1f}% var. inter)")
    ax_c.set_ylabel(f"Axe discriminant LD2 ({100.0 * var_r[1]:.1f}% var. inter)")
    w_val = float(manova_comb["wilks_lambda"])
    wilks_str = f"{w_val:.2e}" if w_val < 1e-3 else f"{w_val:.4f}"
    ax_c.set_title(
        f"C. Espace discriminant canonique ($N={len(y)}$)\n"
        f"MANOVA $\\Lambda_{{\\mathrm{{Wilks}}}} = {wilks_str}$, Pillai = {manova_comb['pillais_trace']:.3f}",
        fontsize=9.8,
        fontweight="bold",
    )
    ax_c.legend(ncol=2, fontsize=7.6, frameon=True, loc="best")
    ax_c.grid(True, alpha=0.3)

    fig.suptitle(
        "Expérience 4b — Matrice de confusion inter-syndromique : séparations nettes et chevauchements transdiagnostiques",
        fontsize=12.6,
        fontweight="bold",
        y=0.99,
    )
    fig.tight_layout(rect=(0, 0, 1, 0.93))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=300)
    plt.close(fig)


def _plot_fig4d_therapeutic_recovery(
    bank: DSM5PriorBank,
    tx_summary: dict[str, Any],
    out_path: Path,
) -> None:
    sns.set_theme(style="whitegrid", context="paper")
    fig = plt.figure(figsize=(18.2, 12.8), dpi=300)
    gs = fig.add_gridspec(3, 4, height_ratios=[1.0, 1.0, 1.12], hspace=0.44, wspace=0.28, top=0.92, bottom=0.07)

    ind_t = int(tx_summary["induction_trials"])
    exp_t = int(tx_summary["exposure_trials"])
    tot_t = int(tx_summary["total_trials"])
    trials = np.arange(tot_t)

    modality_styles = {
        InterventionModality.NONE.value: ("#555555", "--", "Sans intervention"),
        InterventionModality.BOTTOM_UP_INTEROCEPTIVE.value: ("#1f78b4", "-.", "Ascendant ($\\tau_A, \\tau_C$)"),
        InterventionModality.TOP_DOWN_PRIOR_RELAXATION.value: ("#d95f02", ":", "Descendant ($\\alpha_{z\\geq 4}$)"),
        InterventionModality.COMBINED.value: ("#1b9e77", "-", "Approche combinée"),
    }

    for idx, ckey in enumerate(COHORT_KEYS):
        row_i, col_i = divmod(idx, 4)
        ax = fig.add_subplot(gs[row_i, col_i])
        spec = bank.get_spec(ckey)
        c_info = tx_summary["cohorts"][ckey]

        ax.axvspan(0, ind_t, color="#fde0dd", alpha=0.38, zorder=0)
        ax.axvspan(ind_t, ind_t + exp_t, color="#deebf7", alpha=0.38, zorder=0)
        ax.axvspan(ind_t + exp_t, tot_t - 1, color="#e5f5e0", alpha=0.40, zorder=0)
        ax.axvline(ind_t, color="#444444", ls=":", lw=1.0)
        ax.axvline(ind_t + exp_t, color="#444444", ls=":", lw=1.0)

        for m_val, (col_m, ls_m, lbl_m) in modality_styles.items():
            m_data = c_info["modalities"][m_val]
            mean_z = np.asarray(m_data["mean_z_curve"], dtype=np.float64)
            ci_z = np.asarray(m_data["ci95_z_curve"], dtype=np.float64)
            ax.plot(trials, mean_z, color=col_m, ls=ls_m, lw=2.0, label=lbl_m)
            ax.fill_between(trials, np.maximum(0.0, mean_z - ci_z), mean_z + ci_z, color=col_m, alpha=0.14)

        p_comb = c_info["paired_tests"]["combined_vs_none_auc_lyap"]["p_holm"]
        rem_none = c_info["modalities"][InterventionModality.NONE.value]["pdv_remission_fraction"]
        rem_comb = c_info["modalities"][InterventionModality.COMBINED.value]["pdv_remission_fraction"]
        ax.set_ylim(-0.1, 6.6)
        ax.set_xlim(0, tot_t - 1)
        ax.set_title(
            f"{spec.short_label}\nPdV rém. : {100.0 * rem_none:.0f}% → {100.0 * rem_comb:.0f}% ($p_{{\\mathrm{{Holm}}}}={_format_p(p_comb)}$)",
            fontsize=9.2,
            fontweight="bold",
            color=spec.color,
        )
        if col_i == 0:
            ax.set_ylabel("Profondeur $Z_t$ (→ 0 = PdV)")
        if row_i == 1:
            ax.set_xlabel("Essai $t$ (Induction | Expo. | Rémission)")
        if idx == 0:
            ax.legend(fontsize=7.4, loc="upper right", frameon=True)

    # Panneau inférieur gauche : Taux moyen au Point de Veille (0,0,0) en rémission par cohorte et modalité
    ax_bar1 = fig.add_subplot(gs[2, 0:2])
    bar_rows: list[dict[str, Any]] = []
    for ckey in COHORT_KEYS:
        spec = bank.get_spec(ckey)
        for m_val, (_, _, lbl_m) in modality_styles.items():
            bar_rows.append(
                {
                    "Cohorte": spec.short_label,
                    "Modalité": lbl_m,
                    "PdV_rem": 100.0 * tx_summary["cohorts"][ckey]["modalities"][m_val]["pdv_remission_fraction"],
                }
            )
    bar_df = pd.DataFrame(bar_rows)
    pal_bar = {lbl_m: col_m for col_m, _, lbl_m in modality_styles.values()}
    sns.barplot(
        data=bar_df,
        x="Cohorte",
        y="PdV_rem",
        hue="Modalité",
        palette=pal_bar,
        ax=ax_bar1,
    )
    ax_bar1.set_ylim(0, 120)
    ax_bar1.set_xlabel("")
    ax_bar1.set_ylabel("Temps au Point de Veille $(0,0,0)$ en rémission (%)")
    ax_bar1.set_title("I. Taux moyen au Point de Veille $(0,0,0)$ durant la phase de rémission", fontsize=10.2, fontweight="bold")
    ax_bar1.tick_params(axis="x", rotation=22, labelsize=8.4)
    ax_bar1.legend(ncol=4, fontsize=7.4, loc="upper center", frameon=True)

    # Panneau inférieur droit : Réduction relative de charge allostatique (AUC Lyapunov vs Sans interv.)
    ax_bar2 = fig.add_subplot(gs[2, 2:4])
    red_rows: list[dict[str, Any]] = []
    for ckey in COHORT_KEYS:
        spec = bank.get_spec(ckey)
        auc_none = tx_summary["cohorts"][ckey]["modalities"][InterventionModality.NONE.value]["auc_lyap_tx_mean"]
        for m_val in (
            InterventionModality.BOTTOM_UP_INTEROCEPTIVE.value,
            InterventionModality.TOP_DOWN_PRIOR_RELAXATION.value,
            InterventionModality.COMBINED.value,
        ):
            auc_m = tx_summary["cohorts"][ckey]["modalities"][m_val]["auc_lyap_tx_mean"]
            red_pct = 100.0 * (auc_none - auc_m) / max(1e-6, auc_none)
            red_rows.append(
                {
                    "Cohorte": spec.short_label,
                    "Modalité": modality_styles[m_val][2],
                    "Reduction_AUC": red_pct,
                }
            )
    red_df = pd.DataFrame(red_rows)
    sns.barplot(
        data=red_df,
        x="Cohorte",
        y="Reduction_AUC",
        hue="Modalité",
        palette={lbl: pal_bar[lbl] for lbl in red_df["Modalité"].unique()},
        ax=ax_bar2,
    )
    max_red = max(10.0, float(red_df["Reduction_AUC"].max()))
    min_red = min(0.0, float(red_df["Reduction_AUC"].min()))
    ax_bar2.set_ylim(min_red - 2.0, max_red * 1.24)
    ax_bar2.axhline(0.0, color="#333333", lw=0.9)
    ax_bar2.set_xlabel("")
    ax_bar2.set_ylabel("Réduction AUC potentiel de Lyapunov (%)")
    ax_bar2.set_title("J. Réduction relative de charge allostatique (Ascendant vs Descendant vs Combinée)", fontsize=10.2, fontweight="bold")
    ax_bar2.tick_params(axis="x", rotation=22, labelsize=8.4)
    ax_bar2.legend(ncol=3, fontsize=7.5, loc="upper center", frameon=True)

    fig.suptitle(
        "Expérience 4c — Courbes de rétablissement vers le Point de Veille $(0,0,0)$ sous les trois modalités d'intervention thérapeutique",
        fontsize=12.6,
        fontweight="bold",
        y=0.985,
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=300, bbox_inches="tight")
    plt.close(fig)


# ---------------------------------------------------------------------------
# Pipeline expérimental complet
# ---------------------------------------------------------------------------


def run_experiment(
    *,
    n_per_cohort: int = 200,
    n_therapy_per_cohort: int = 200,
    num_trials: int = 280,
    svi_steps: int = 750,
    svi_samples: int = 150,
    batch_size: int = 80,
    seed: int = 42,
    results_dir: Path | None = None,
) -> dict[str, Any]:
    """Exécute l'expérience 4 complète sur les 8 cohortes DSM-5 et sauvegarde tous les artefacts."""
    t_start = time.perf_counter()
    out_dir = (
        Path(results_dir)
        if results_dir is not None
        else ROOT_DIR / "results" / "dsm5_phenotyping"
    )
    out_dir.mkdir(parents=True, exist_ok=True)

    bank = DSM5PriorBank()
    schedule = build_dsm5_phenotyping_schedule(num_trials=num_trials)
    cohorts = bank.sample_all_cohorts(n_per_cohort=n_per_cohort, seed=seed)

    # 1. Passage de la tâche orthogonale GenerativeProcess aux 8 x N agents
    all_profiles = [p for ckey in COHORT_KEYS for p in cohorts[ckey]]
    sims_by_cohort: dict[str, list[Any]] = {ckey: [] for ckey in COHORT_KEYS}
    all_sims: list[Any] = []
    for idx, prof in enumerate(all_profiles):
        sim_res = simulate_clinical_agent(
            prof,
            schedule=schedule,
            seed=seed + 10_000 + idx,
        )
        sims_by_cohort[prof.cohort_key].append(sim_res)
        all_sims.append(sim_res)

    # 2. Inversion bayésienne aveugle aux cohortes (estimation θ̂_i)
    datasets = [s.dataset for s in all_sims]
    inversions = invert_clinical_batch_svi(
        datasets,
        seed=seed + 50_000,
        num_steps=svi_steps,
        num_posterior_samples=svi_samples,
        lr=0.025,
        batch_size=batch_size,
    )

    n_total = len(all_profiles)
    y = np.array([COHORT_KEYS.index(p.cohort_key) for p in all_profiles], dtype=np.int32)
    true_theta_mat = np.array(
        [[p.theta[pname] for pname in THETA_NAMES] for p in all_profiles],
        dtype=np.float64,
    )
    est_theta_mat = np.array(
        [[inv["means"][pname] for pname in THETA_NAMES] for inv in inversions],
        dtype=np.float64,
    )
    ctrl_bias_true = np.array([p.ctrl_prior_bias for p in all_profiles], dtype=np.float64)
    ctrl_bias_hat = np.array(
        [inv["means"]["ctrl_prior_bias"] for inv in inversions], dtype=np.float64
    )

    recovery_metrics: dict[str, dict[str, float]] = {}
    for j, pname in enumerate(THETA_NAMES):
        tr_col = true_theta_mat[:, j]
        es_col = est_theta_mat[:, j]
        cov_rate = float(
            np.mean(
                [
                    inversions[i]["ci95"][pname][0]
                    <= tr_col[i]
                    <= inversions[i]["ci95"][pname][1]
                    for i in range(n_total)
                ]
            )
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
            np.mean(
                [
                    inversions[i]["ci95"]["ctrl_prior_bias"][0]
                    <= ctrl_bias_true[i]
                    <= inversions[i]["ci95"]["ctrl_prior_bias"][1]
                    for i in range(n_total)
                ]
            )
        ),
    }

    # Export CSV individuel θ* et θ̂_i
    agent_rows: list[dict[str, Any]] = []
    for i, (prof, sim_res, inv) in enumerate(zip(all_profiles, all_sims, inversions)):
        row: dict[str, Any] = {
            "agent_id": prof.agent_id,
            "cohort_key": prof.cohort_key,
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
    pd.DataFrame(agent_rows).to_csv(
        out_dir / "dsm5_cohort_theta_true_and_estimated.csv",
        index=False,
        encoding="utf-8",
    )

    # 3. Analyse (a) : Densités d'occupation (X, Y, Z) et coordonnées Lexicon176
    occ_matrix = np.zeros((len(COHORT_KEYS), len(ALL_176_ENTRIES)), dtype=np.float64)
    occ_summary: dict[str, Any] = {}
    xyz_rows: list[dict[str, Any]] = []

    for c_idx, ckey in enumerate(COHORT_KEYS):
        sub = sims_by_cohort[ckey]
        s_idx_all = np.concatenate([s.state_indices for s in sub])
        zs_all = np.concatenate([s.zs for s in sub])
        counts = np.bincount(s_idx_all, minlength=len(ALL_176_ENTRIES)).astype(np.float64)
        occ_probs = counts / float(np.sum(counts))
        occ_matrix[c_idx, :] = occ_probs

        z_counts = np.bincount(zs_all, minlength=8).astype(np.float64)
        z_probs = z_counts / float(np.sum(z_counts))

        non_pdv_indices = np.argsort(occ_probs)[::-1]
        top_non_pdv: list[dict[str, Any]] = []
        for s_i in non_pdv_indices:
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

        pdv_occ = float(occ_probs[0])
        occ_summary[ckey] = {
            "mean_x": float(np.mean([s.summary_metrics["mean_x"] for s in sub])),
            "mean_y": float(np.mean([s.summary_metrics["mean_y"] for s in sub])),
            "mean_z": float(np.mean([s.summary_metrics["mean_z"] for s in sub])),
            "mean_z_stress": float(np.mean([s.summary_metrics["mean_z_stress"] for s in sub])),
            "mean_z_remission": float(np.mean([s.summary_metrics["mean_z_remission"] for s in sub])),
            "pdv_occupancy_session": pdv_occ,
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
                "display_name": bank.get_spec(ckey).display_name,
                **{k: v for k, v in occ_summary[ckey].items() if k not in ("stratum_distribution", "top_non_pdv_states")},
                "dominant_1_label": dom1["label"],
                "dominant_1_xyz": f"({dom1['x']:+d},{dom1['y']:+d},{dom1['z']})",
                "dominant_1_pct": 100.0 * dom1["occupancy"],
                "dominant_2_label": dom2["label"],
                "dominant_2_xyz": f"({dom2['x']:+d},{dom2['y']:+d},{dom2['z']})",
                "dominant_2_pct": 100.0 * dom2["occupancy"],
            }
        )

    pd.DataFrame(xyz_rows).to_csv(
        out_dir / "dsm5_xyz_occupation_summary.csv", index=False, encoding="utf-8"
    )
    lex_cols = [f"{e.label}_({e.x},{e.y},{e.z})" for e in ALL_176_ENTRIES]
    pd.DataFrame(occ_matrix, index=list(COHORT_KEYS), columns=lex_cols).to_csv(
        out_dir / "dsm5_lexicon176_occupancy_matrix.csv", encoding="utf-8"
    )

    # Vérifications spécifiques TSPT bimodal et TPL instabilité Z=4,6
    ptsd_idx = COHORT_KEYS.index("ptsd")
    ptsd_tau_a = est_theta_mat[y == ptsd_idx, THETA_NAMES.index("tau_A")]
    ptsd_susp = np.array([s.summary_metrics["central_suspension_rate"] for s in sims_by_cohort["ptsd"]])
    ptsd_bimodality = {
        "sarle_bc_tau_a_hat": _sarles_bimodality_coefficient(ptsd_tau_a),
        "sarle_bc_suspension": _sarles_bimodality_coefficient(ptsd_susp),
        "hypervigilance_count": int(
            sum(1 for s in sims_by_cohort["ptsd"] if s.profile.subregime == "ptsd_hypervigilance")
        ),
        "dissociation_count": int(
            sum(1 for s in sims_by_cohort["ptsd"] if s.profile.subregime == "ptsd_dissociation")
        ),
    }

    bpd_ratios = np.array([s.summary_metrics["z4_z6_instability_ratio"] for s in sims_by_cohort["bpd"]])
    bpd_raw_tests: dict[str, dict[str, Any]] = {}
    for other_k in COHORT_KEYS:
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

    # 4. Analyse (b) : Matrice de confusion inter-syndromique & séparabilité
    cv_theta = _evaluate_cv_qda(
        est_theta_mat, y, COHORT_KEYS, n_splits=10, reg_covar=0.08, seed=seed
    )
    dyn_features = np.column_stack(
        [
            est_theta_mat,
            ctrl_bias_hat,
            np.array([s.summary_metrics["z4_z6_instability_ratio"] for s in all_sims], dtype=np.float64),
            np.array([s.summary_metrics["central_suspension_rate"] for s in all_sims], dtype=np.float64),
            np.array([s.summary_metrics["state_switch_rate"] for s in all_sims], dtype=np.float64),
        ]
    )
    cv_combined = _evaluate_cv_qda(
        dyn_features, y, COHORT_KEYS, n_splits=10, reg_covar=0.08, seed=seed
    )

    sil_theta = _compute_silhouette_scores(est_theta_mat, y, COHORT_KEYS)
    sil_combined = _compute_silhouette_scores(dyn_features, y, COHORT_KEYS)
    manova_theta = _compute_manova_and_lda(est_theta_mat, y, len(COHORT_KEYS))
    manova_comb = _compute_manova_and_lda(dyn_features, y, len(COHORT_KEYS))

    pairwise_rows = _compute_pairwise_separability(
        manova_theta["z_standardized"],
        y,
        manova_theta["pooled_within_cov"],
        COHORT_KEYS,
        cv_theta["confusion_norm"],
        cv_combined["confusion_norm"],
        occ_matrix,
        reg_covar=0.08,
    )
    pd.DataFrame(pairwise_rows).to_csv(
        out_dir / "dsm5_pairwise_mahalanobis_and_jsd.csv",
        index=False,
        encoding="utf-8",
    )

    pd.DataFrame(
        cv_theta["confusion_norm"], index=list(COHORT_KEYS), columns=list(COHORT_KEYS)
    ).to_csv(out_dir / "dsm5_confusion_matrix_theta_hat.csv", encoding="utf-8")
    pd.DataFrame(
        cv_combined["confusion_norm"], index=list(COHORT_KEYS), columns=list(COHORT_KEYS)
    ).to_csv(out_dir / "dsm5_confusion_matrix_combined_features.csv", encoding="utf-8")

    # 5. Analyse (c) : Courbes de rétablissement sous 3 interventions thérapeutiques
    tx_profiles = [
        p
        for ckey in COHORT_KEYS
        for p in cohorts[ckey][: min(n_therapy_per_cohort, len(cohorts[ckey]))]
    ]
    tx_summary = TherapeuticIntervention.simulate_paired_recovery(
        tx_profiles,
        seed=seed + 90_000,
        induction_trials=80,
        exposure_trials=40,
        remission_trials=60,
    )

    tx_metric_rows: list[dict[str, Any]] = []
    tx_curve_rows: list[dict[str, Any]] = []
    for ckey in COHORT_KEYS:
        c_res = tx_summary["cohorts"][ckey]
        for m_val, m_stats in c_res["modalities"].items():
            tx_metric_rows.append(
                {
                    "cohort_key": ckey,
                    "modality": m_val,
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
    pd.DataFrame(tx_metric_rows).to_csv(
        out_dir / "dsm5_therapeutic_recovery_metrics.csv",
        index=False,
        encoding="utf-8",
    )
    pd.DataFrame(tx_curve_rows).to_csv(
        out_dir / "dsm5_therapeutic_recovery_curves.csv",
        index=False,
        encoding="utf-8",
    )

    # 6. Figures 300 DPI
    fig4a_path = out_dir / "fig4a_xyz_occupation_densities.png"
    fig4b_path = out_dir / "fig4b_theta_profiles_and_strata.png"
    fig4c_path = out_dir / "fig4c_inter_syndromic_confusion.png"
    fig4d_path = out_dir / "fig4d_therapeutic_recovery_curves.png"

    _plot_fig4a_xyz_densities(bank, sims_by_cohort, occ_summary, fig4a_path)
    _plot_fig4b_profiles_and_signatures(
        bank,
        est_theta_mat,
        y,
        ctrl_bias_hat,
        occ_summary,
        bpd_raw_tests,
        ptsd_bimodality,
        sims_by_cohort,
        fig4b_path,
    )
    _plot_fig4c_confusion_and_lda(
        bank,
        cv_theta,
        cv_combined,
        manova_comb,
        y,
        sil_theta,
        sil_combined,
        fig4c_path,
    )
    _plot_fig4d_therapeutic_recovery(bank, tx_summary, fig4d_path)

    # Classement net separations vs transdiagnostic overlaps
    sorted_by_sep = sorted(
        pairwise_rows,
        key=lambda r: (r["sym_confusion_theta_hat"], -r["mahalanobis_distance"]),
    )
    sorted_by_ovl = sorted(
        pairwise_rows,
        key=lambda r: (-r["sym_confusion_theta_hat"], r["mahalanobis_distance"]),
    )

    tx_compact = {
        "total_trials": tx_summary["total_trials"],
        "induction_trials": tx_summary["induction_trials"],
        "exposure_trials": tx_summary["exposure_trials"],
        "remission_trials": tx_summary["remission_trials"],
        "cohorts": {
            ckey: {
                "n_agents": tx_summary["cohorts"][ckey]["n_agents"],
                "modalities": {
                    m_val: {
                        k: v
                        for k, v in m_d.items()
                        if not k.endswith("_curve")
                    }
                    for m_val, m_d in tx_summary["cohorts"][ckey]["modalities"].items()
                },
                "paired_tests": tx_summary["cohorts"][ckey]["paired_tests"],
            }
            for ckey in COHORT_KEYS
        },
    }

    summary = {
        "epistemological_note": (
            "Conformément à CARTOGRAFFECT®, les 8 cohortes formalisent des régimes "
            "paramétriques dynamiques et des trajectoires réversibles dans l'espace "
            "(X, Y, Z), et non des étiquettes diagnostiques statiques."
        ),
        "configuration": {
            "n_per_cohort": n_per_cohort,
            "n_total_agents": n_total,
            "n_therapy_per_cohort": min(n_therapy_per_cohort, n_per_cohort),
            "num_trials": num_trials,
            "svi_steps": svi_steps,
            "svi_samples": svi_samples,
            "runtime_seconds": round(time.perf_counter() - t_start, 2),
        },
        "cohort_priors": bank.summary_table(),
        "parameter_recovery_1600": recovery_metrics,
        "xyz_occupation": occ_summary,
        "ptsd_bimodality": ptsd_bimodality,
        "bpd_z4_z6_instability_tests": bpd_raw_tests,
        "separability": {
            "theta_hat_only": {
                "accuracy": cv_theta["accuracy"],
                "balanced_accuracy": cv_theta["balanced_accuracy"],
                "macro_f1": cv_theta["macro_f1"],
                "cohen_kappa": cv_theta["cohen_kappa"],
                "n_folds": cv_theta["n_folds"],
                "per_class": cv_theta["per_class"],
                "confusion_norm": cv_theta["confusion_norm"].tolist(),
                "confusion_counts": cv_theta["confusion_counts"].tolist(),
                "silhouette": sil_theta,
                "wilks_lambda": manova_theta["wilks_lambda"],
                "pillais_trace": manova_theta["pillais_trace"],
            },
            "theta_hat_plus_dynamics": {
                "accuracy": cv_combined["accuracy"],
                "balanced_accuracy": cv_combined["balanced_accuracy"],
                "macro_f1": cv_combined["macro_f1"],
                "cohen_kappa": cv_combined["cohen_kappa"],
                "n_folds": cv_combined["n_folds"],
                "per_class": cv_combined["per_class"],
                "confusion_norm": cv_combined["confusion_norm"].tolist(),
                "confusion_counts": cv_combined["confusion_counts"].tolist(),
                "silhouette": sil_combined,
                "wilks_lambda": manova_comb["wilks_lambda"],
                "pillais_trace": manova_comb["pillais_trace"],
            },
            "clearest_separations_top6": sorted_by_sep[:6],
            "transdiagnostic_overlaps_top6": sorted_by_ovl[:6],
        },
        "therapeutic_recovery": tx_compact,
        "figures": {
            k: (
                p.resolve().relative_to(ROOT_DIR.resolve()).as_posix()
                if p.resolve().is_relative_to(ROOT_DIR.resolve())
                else p.name
            )
            for k, p in (
                ("fig4a", fig4a_path),
                ("fig4b", fig4b_path),
                ("fig4c", fig4c_path),
                ("fig4d", fig4d_path),
            )
        },
    }
    (out_dir / "dsm5_separability_and_phenotyping_summary.json").write_text(
        json.dumps(summary, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    return summary


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Expérience 4 : Phénotypage computationnel transdiagnostique DSM-5."
    )
    parser.add_argument("--n-per-cohort", type=int, default=200)
    parser.add_argument("--n-therapy-per-cohort", type=int, default=200)
    parser.add_argument("--num-trials", type=int, default=280)
    parser.add_argument("--svi-steps", type=int, default=750)
    parser.add_argument("--svi-samples", type=int, default=150)
    parser.add_argument("--batch-size", type=int, default=80)
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
    for pname, m in summary["parameter_recovery_1600"].items():
        print(f"  {pname:16s}: r={m['pearson_r']:.4f}, rmse={m['rmse']:.4f}, cov95={m['coverage_95']:.3f}")
    sep_th = summary["separability"]["theta_hat_only"]
    sep_cb = summary["separability"]["theta_hat_plus_dynamics"]
    print(
        f"CV Accuracy theta_hat={100*sep_th['accuracy']:.1f}% (kappa={sep_th['cohen_kappa']:.3f}, sil={sep_th['silhouette']['global_silhouette']:.3f}) | "
        f"combined={100*sep_cb['accuracy']:.1f}% (kappa={sep_cb['cohen_kappa']:.3f}, sil={sep_cb['silhouette']['global_silhouette']:.3f})"
    )


if __name__ == "__main__":
    main()
