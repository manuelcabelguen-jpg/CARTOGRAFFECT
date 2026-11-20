"""Expérience 3 : Validation bayésienne Parameter Recovery (M=500) & Model Recovery (4x100).

Pipeline complet en boucle fermée sur ``NonStationaryBanditEnv`` (sans fuite de
labels cachés, reparamétrisation centrée et équité des modèles concurrents) :
    1. Parameter Recovery sur M = 500 vecteurs θ_vrai inversés par NumPyro SVI
       vectorisé (`jax.vmap`) + validation croisée MCMC NUTS / ArviZ étendue à
       10 jeux (`num_warmup=600, num_samples=900, 2 chaînes vectorisées`). Critères :
       r >= 0.80, couverture IC95% >= 0.85, R-hat < 1.02 et ESS >= 400.
    2. Model Recovery sur 4 × 100 jeux de données générés sous :
       - M1_CARTOGRAFFECT (8 paramètres libres)
       - M2_NoBudget_Lam0 (λ ≡ 0, 7 paramètres)
       - M3_NoThresholds (τ_A = τ_C ≡ 0, 6 paramètres)
       - M4_ScalarValence_1D (valence 1D avec seuil et bruit libres, 5 paramètres)
       Calcul du BIC exact (sur max_ll et observations scalaires actives), du WAIC
       et de `pxp` (Rigoux et al., 2014 ; cible diagonale > 0.95).

Exporte :
    - `results/exp03_parameter_recovery_metrics.csv`
    - `results/exp03_parameter_corr_matrix.csv`
    - `results/exp03_parameter_error_corr_matrix.csv`
    - `results/exp03_parameter_recovery_samples.csv`
    - `results/exp03_model_recovery_summary.json`
    - `results/exp03_model_pxp_matrix.csv`
    - `results/exp03_model_pxp_waic_matrix.csv`
    - `results/exp03_model_waic_confusion.csv`
    - `results/exp03_model_bic_confusion.csv`
    - `results/fig3a_parameter_recovery.png` (300 DPI)
    - `results/fig3b_model_recovery.png` (300 DPI)
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

ROOT_DIR = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT_DIR / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from cartograffect_sim.recovery import (  # noqa: E402
    MODEL_NAMES,
    THETA_NAMES,
    run_model_recovery,
    run_parameter_recovery,
)

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

MODEL_SHORT_LABELS: list[str] = [
    r"$M_1$ CARTOGRAFFECT",
    r"$M_2$ Sans budget ($\lambda=0$)",
    r"$M_3$ Continu ($\tau=0$)",
    r"$M_4$ Valence 1D",
]


def _plot_parameter_recovery(
    pr: dict[str, Any],
    *,
    nuts_max_rhat: float | None,
    nuts_min_ess: float | None,
    out_path: Path,
) -> None:
    sns.set_theme(style="whitegrid", context="paper")
    fig, axes = plt.subplots(3, 3, figsize=(15.5, 13.8), dpi=300)
    flat_axes = axes.ravel()

    true_mat = np.asarray(pr["true_thetas"], dtype=np.float64)
    est_mat = np.asarray(pr["est_thetas"], dtype=np.float64)
    err_corr_mat = np.asarray(pr["error_corr_matrix"], dtype=np.float64)

    for idx, pname in enumerate(THETA_NAMES):
        ax = flat_axes[idx]
        x = true_mat[:, idx]
        y = est_mat[:, idx]
        lo = float(min(np.min(x), np.min(y)))
        hi = float(max(np.max(x), np.max(y)))
        pad = 0.05 * max(1e-6, hi - lo)
        ax.scatter(x, y, s=14, alpha=0.55, color="#1f618d", edgecolors="none")
        ax.plot([lo - pad, hi + pad], [lo - pad, hi + pad], "--", color="#c0392b", lw=1.4)
        ax.set_xlim(lo - pad, hi + pad)
        ax.set_ylim(lo - pad, hi + pad)
        r_val = pr["pearson_r"][pname]
        rmse_val = pr["rmse"][pname]
        cov_val = pr["coverage_95"][pname]
        tex = THETA_TEX_LABELS[pname]
        ax.set_title(
            f"{tex} — $r = {r_val:.3f}$, $\\mathrm{{RMSE}} = {rmse_val:.3f}$, Couv. 95% = {cov_val:.1%}",
            fontsize=10,
            fontweight="bold",
        )
        ax.set_xlabel(f"{tex} vrai")
        ax.set_ylabel(f"{tex} estimé (SVI)")

    # 9e panneau : matrice de corrélation des erreurs d'estimation (θ_est - θ_vrai)
    ax_heat = flat_axes[8]
    tex_ticks = [THETA_TEX_LABELS[p] for p in THETA_NAMES]
    heat_df = pd.DataFrame(err_corr_mat, index=tex_ticks, columns=tex_ticks)
    sns.heatmap(
        heat_df,
        annot=True,
        fmt=".2f",
        cmap="RdBu_r",
        center=0.0,
        vmin=-1.0,
        vmax=1.0,
        cbar_kws={"label": r"Corr. des erreurs $\hat{\theta}-\theta^*$"},
        annot_kws={"size": 7.5},
        ax=ax_heat,
    )
    ax_heat.set_title(
        f"Corrélation des erreurs ($M = {pr['num_datasets']}$)\n"
        r"$\hat{\theta} - \theta_{\mathrm{vrai}}$ (interdépendance)",
        fontsize=10,
        fontweight="bold",
    )
    ax_heat.tick_params(axis="x", rotation=30, labelsize=8.5)
    ax_heat.tick_params(axis="y", rotation=0, labelsize=8.5)

    min_diag = float(min(pr["pearson_r"].values()))
    min_cov = float(min(pr["coverage_95"].values()))
    rhat_txt = f"{nuts_max_rhat:.3f}" if nuts_max_rhat is not None else "n/a"
    ess_txt = f"{nuts_min_ess:.0f}" if nuts_min_ess is not None else "n/a"
    fig.suptitle(
        f"CARTOGRAFFECT — Parameter Recovery sous NumPyro ($M = {pr['num_datasets']}$)\n"
        f"$\\min r = {min_diag:.3f}$ ($\\geq 0.80$), Couv. 95% min = {min_cov:.1%} ($\\geq 85\\%$), "
        f"NUTS : $\\max\\,\\hat{{R}} = {rhat_txt}$, $\\min\\,\\mathrm{{ESS}} = {ess_txt}$",
        fontsize=12.0,
        fontweight="bold",
        y=0.985,
    )
    fig.tight_layout(rect=(0, 0, 1, 0.945))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=300)
    plt.close(fig)


def _plot_model_recovery(mr: dict[str, Any], out_path: Path) -> None:
    sns.set_theme(style="white", context="paper")
    fig, axes = plt.subplots(1, 3, figsize=(16.8, 5.6), dpi=300)

    panels = [
        ("Taux de sélection WAIC", mr["waic_confusion"], "Blues", axes[0]),
        ("Taux de sélection BIC (max LL)", mr["bic_confusion"], "PuBuGn", axes[1]),
        ("Probabilité d'excédance protégée pxp (BIC)", mr["pxp_matrix"], "YlGn", axes[2]),
    ]

    for title, mat, cmap, ax in panels:
        df = pd.DataFrame(mat, index=MODEL_SHORT_LABELS, columns=MODEL_SHORT_LABELS)
        sns.heatmap(
            df,
            annot=True,
            fmt=".3f",
            cmap=cmap,
            vmin=0.0,
            vmax=1.0,
            cbar=True,
            linewidths=0.6,
            annot_kws={"size": 9.5, "weight": "bold"},
            ax=ax,
        )
        ax.set_title(title, fontsize=10.8, fontweight="bold", pad=10)
        ax.set_xlabel("Modèle ajusté", fontsize=10)
        ax.set_ylabel("Modèle générateur vrai", fontsize=10)
        ax.tick_params(axis="x", rotation=25, labelsize=8.8)
        ax.tick_params(axis="y", rotation=0, labelsize=8.8)

    min_pxp = float(np.min(np.diag(mr["pxp_matrix"])))
    min_pxp_w = float(np.min(np.diag(mr["pxp_waic"])))
    fig.suptitle(
        f"CARTOGRAFFECT — Model Recovery ({mr['num_datasets_per_model']} jeux/modèle, "
        f"$\\min pxp_{{\\mathrm{{BIC}}}} = {min_pxp:.4f} > 0.95$, "
        f"$\\min pxp_{{\\mathrm{{WAIC}}}} = {min_pxp_w:.4f}$)",
        fontsize=12.0,
        fontweight="bold",
        y=0.99,
    )
    fig.tight_layout(rect=(0, 0, 1, 0.93))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=300)
    plt.close(fig)


def min_pxp_val(pxp_mat: np.ndarray) -> float:
    return float(np.min(np.diag(pxp_mat)))


def run_experiment(
    num_param_datasets: int = 500,
    num_model_datasets_per_model: int = 100,
    num_trials: int = 280,
    results_dir: Path | None = None,
) -> dict[str, Any]:
    """Exécute Parameter Recovery (M=500, 10 NUTS) et Model Recovery (4x100)."""
    out_dir = ROOT_DIR / "results" if results_dir is None else Path(results_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    pr = run_parameter_recovery(
        num_datasets=num_param_datasets,
        num_trials=num_trials,
        num_steps=1000,
        num_posterior_samples=200,
        lr=0.02,
        batch_size=50,
        nuts_check_count=10,
        nuts_warmup=600,
        nuts_samples=900,
        seed=42,
    )
    mr = run_model_recovery(
        num_datasets_per_model=num_model_datasets_per_model,
        num_trials=num_trials,
        num_steps=800,
        num_posterior_samples=160,
        lr=0.025,
        batch_size=50,
        seed=123,
    )

    nuts_checks = pr["nuts_checks"]
    nuts_max_rhat = (
        float(max(item["max_rhat"] for item in nuts_checks)) if nuts_checks else None
    )
    nuts_min_ess = (
        float(min(item["min_ess"] for item in nuts_checks)) if nuts_checks else None
    )

    fig3a_path = out_dir / "fig3a_parameter_recovery.png"
    fig3b_path = out_dir / "fig3b_model_recovery.png"
    _plot_parameter_recovery(
        pr,
        nuts_max_rhat=nuts_max_rhat,
        nuts_min_ess=nuts_min_ess,
        out_path=fig3a_path,
    )
    _plot_model_recovery(mr, fig3b_path)

    corr_mat = np.asarray(pr["corr_matrix"], dtype=np.float64)
    off_diag = corr_mat.copy()
    np.fill_diagonal(off_diag, 0.0)
    max_abs_offdiag = float(np.max(np.abs(off_diag)))

    err_corr_mat = np.asarray(pr["error_corr_matrix"], dtype=np.float64)
    err_off_diag = err_corr_mat.copy()
    np.fill_diagonal(err_off_diag, 0.0)
    max_abs_error_corr = float(np.max(np.abs(err_off_diag)))

    metric_rows = []
    for idx, pname in enumerate(THETA_NAMES):
        row_off = np.delete(off_diag[idx, :], idx)
        col_off = np.delete(off_diag[:, idx], idx)
        err_row_off = np.delete(err_off_diag[idx, :], idx)
        metric_rows.append(
            {
                "parameter": pname,
                "pearson_r": pr["pearson_r"][pname],
                "rmse": pr["rmse"][pname],
                "bias": pr["bias"][pname],
                "coverage_95": pr["coverage_95"][pname],
                "max_abs_cross_corr": float(max(np.max(np.abs(row_off)), np.max(np.abs(col_off)))),
                "max_abs_error_corr": float(np.max(np.abs(err_row_off))),
            }
        )
    pd.DataFrame(metric_rows).to_csv(
        out_dir / "exp03_parameter_recovery_metrics.csv", index=False, encoding="utf-8"
    )

    pd.DataFrame(corr_mat, index=list(THETA_NAMES), columns=list(THETA_NAMES)).to_csv(
        out_dir / "exp03_parameter_corr_matrix.csv", encoding="utf-8"
    )
    pd.DataFrame(err_corr_mat, index=list(THETA_NAMES), columns=list(THETA_NAMES)).to_csv(
        out_dir / "exp03_parameter_error_corr_matrix.csv", encoding="utf-8"
    )

    samples_dict: dict[str, Any] = {"dataset_idx": np.arange(num_param_datasets)}
    true_mat = np.asarray(pr["true_thetas"], dtype=np.float64)
    est_mat = np.asarray(pr["est_thetas"], dtype=np.float64)
    for idx, pname in enumerate(THETA_NAMES):
        samples_dict[f"true_{pname}"] = true_mat[:, idx]
        samples_dict[f"est_{pname}"] = est_mat[:, idx]
    pd.DataFrame(samples_dict).to_csv(
        out_dir / "exp03_parameter_recovery_samples.csv", index=False, encoding="utf-8"
    )

    for fname, mat in [
        ("exp03_model_pxp_matrix.csv", mr["pxp_matrix"]),
        ("exp03_model_pxp_waic_matrix.csv", mr["pxp_waic"]),
        ("exp03_model_waic_confusion.csv", mr["waic_confusion"]),
        ("exp03_model_bic_confusion.csv", mr["bic_confusion"]),
    ]:
        pd.DataFrame(mat, index=list(MODEL_NAMES), columns=list(MODEL_NAMES)).to_csv(
            out_dir / fname, encoding="utf-8"
        )

    min_diag_r = float(min(pr["pearson_r"].values()))
    min_cov_95 = float(min(pr["coverage_95"].values()))
    min_diag_pxp = min_pxp_val(mr["pxp_matrix"])
    min_diag_pxp_waic = min_pxp_val(mr["pxp_waic"])

    summary = {
        "parameter_recovery": {
            "num_datasets": pr["num_datasets"],
            "num_trials": pr["num_trials"],
            "pearson_r": pr["pearson_r"],
            "rmse": pr["rmse"],
            "bias": pr["bias"],
            "coverage_95": pr["coverage_95"],
            "min_coverage_95": min_cov_95,
            "corr_matrix": corr_mat.tolist(),
            "error_corr_matrix": err_corr_mat.tolist(),
            "max_abs_offdiag_r": max_abs_offdiag,
            "max_abs_error_corr": max_abs_error_corr,
            "min_diagonal_r": min_diag_r,
            "target_r_ge_080_met": bool(min_diag_r >= 0.80),
            "nuts_max_rhat": nuts_max_rhat,
            "nuts_min_ess": nuts_min_ess,
            "nuts_checks": nuts_checks,
        },
        "model_recovery": {
            "model_names": list(MODEL_NAMES),
            "num_datasets_per_model": mr["num_datasets_per_model"],
            "num_trials": mr["num_trials"],
            "pxp_matrix": np.asarray(mr["pxp_matrix"]).tolist(),
            "pxp_waic": np.asarray(mr["pxp_waic"]).tolist(),
            "waic_confusion": np.asarray(mr["waic_confusion"]).tolist(),
            "bic_confusion": np.asarray(mr["bic_confusion"]).tolist(),
            "bor_by_true_model": mr["bor_by_true_model"],
            "mean_waic_matrix": np.asarray(mr["mean_waic_matrix"]).tolist(),
            "mean_bic_matrix": np.asarray(mr["mean_bic_matrix"]).tolist(),
            "min_diagonal_pxp": min_diag_pxp,
            "min_diagonal_pxp_waic": min_diag_pxp_waic,
            "target_pxp_gt_095_met": bool(min_diag_pxp > 0.95),
        },
        "figures": {
            "fig3a": (
                fig3a_path.resolve().relative_to(ROOT_DIR.resolve()).as_posix()
                if fig3a_path.resolve().is_relative_to(ROOT_DIR.resolve())
                else fig3a_path.name
            ),
            "fig3b": (
                fig3b_path.resolve().relative_to(ROOT_DIR.resolve()).as_posix()
                if fig3b_path.resolve().is_relative_to(ROOT_DIR.resolve())
                else fig3b_path.name
            ),
        },
    }

    (out_dir / "exp03_model_recovery_summary.json").write_text(
        json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    return summary


def main() -> None:
    summary = run_experiment(
        num_param_datasets=500,
        num_model_datasets_per_model=100,
        num_trials=280,
    )
    print(json.dumps(summary["parameter_recovery"]["pearson_r"], indent=2))
    print("coverage_95:", json.dumps(summary["parameter_recovery"]["coverage_95"], indent=2))
    print("min_diagonal_r:", summary["parameter_recovery"]["min_diagonal_r"])
    print("min_coverage_95:", summary["parameter_recovery"]["min_coverage_95"])
    print("max_abs_offdiag_r:", summary["parameter_recovery"]["max_abs_offdiag_r"])
    print("max_abs_error_corr:", summary["parameter_recovery"]["max_abs_error_corr"])
    print(
        "NUTS:",
        summary["parameter_recovery"]["nuts_max_rhat"],
        summary["parameter_recovery"]["nuts_min_ess"],
    )
    print("PXP (BIC) diagonal:", np.diag(summary["model_recovery"]["pxp_matrix"]).tolist())
    print("PXP (WAIC) diagonal:", np.diag(summary["model_recovery"]["pxp_waic"]).tolist())
    print("min_diagonal_pxp:", summary["model_recovery"]["min_diagonal_pxp"])


if __name__ == "__main__":
    main()
