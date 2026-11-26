"""Script maître de validation in silico du modèle CARTOGRAFFECT.

Exécute séquentiellement les volets expérimentaux :
    - Mode `--quick` (défaut, Expériences 1 à 3) :
        1. Expérience 1 (`experiments/01_falsifiable_predictions.py`) :
           Tests de cohérence in silico (N = 1 000 trajectoires / condition, V3 = 0) :
           P1 (test de cohérence numérique du projecteur budgétaire L1), P2 (instabilité
           axiale émergente en Z=2 sans biais dans B), P3 (inertie hiérarchique),
           P4 (priorité lexicographique sgn(X_t) vs Δ∇A_t) et P5 (médiation par le
           contrôle pragmatique Peur → Colère vs Dégoût) sur le POMDP canonique à
           176 états sous JAX/pymdp.
        2. Expérience 2 (`experiments/02_clinical_phenotypes.py`) :
           Comparaison pure-θ des 4 phénotypes synthétiques sur cohorte unifiée appariée
           (N = 20 graines / profil, Wilcoxon bilatéral + Holm-Bonferroni).
        3. Expérience 3 (`experiments/03_parameter_and_model_recovery.py`) :
           Parameter Recovery (M = 500, critère r >= 0.80, couverture >= 0.85,
           10 contrôles NUTS R-hat < 1.02 et ESS >= 400) et Model Recovery
           (4 × 100 jeux de données, pxp (BIC) > 0.95 sur la diagonale).
    - Mode `--full` (Expériences 1 à 5 — Exp 4 & 5 en quarantaine SYNTHETIC EXPLORATORY ONLY — V3 = 0) :
        Ajoute aux Expériences 1 à 3 :
        4. Expérience 4 (`exploratory_synthetic/04_dsm5_phenotyping.py`) :
           [SYNTHETIC EXPLORATORY ONLY — V3 = 0] Simulation exploratoire sur 8 cohortes paramétriques synthétiques (N = 1 600 agents).
        5. Expérience 5 (`exploratory_synthetic/05_dsm5_full_nosology.py`) :
           [SYNTHETIC EXPLORATORY ONLY — V3 = 0] Simulation exploratoire sur 26 régimes paramétriques synthétiques (N = 2 600 agents).

Exporte l'ensemble des tableaux CSV, figures 300 DPI et rapports consolidés
(`validation_report.json`, `validation_summary.md`) dans `results/`.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import math
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from types import ModuleType
from typing import Any

import numpy as np

ROOT_DIR = Path(__file__).resolve().parent
SRC_DIR = ROOT_DIR / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))


def _format_p(p: float) -> str:
    """Formate une p-value sans jamais afficher `0.00e+00`."""
    if not math.isfinite(p):
        return "nan"
    if p < 1e-300:
        return "< 1e-300"
    return f"{p:.2e}"


def _load_experiment_module(name: str, rel_path: str) -> ModuleType:
    path = ROOT_DIR / rel_path
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Impossible de charger le module expérimental : {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def run_all(
    num_mc_trajectories: int = 1000,
    num_clinical_seeds: int = 20,
    num_param_datasets: int = 500,
    num_model_datasets_per_model: int = 100,
    num_recovery_trials: int = 280,
    include_dsm5_full: bool = False,
    exp04_n_per_cohort: int = 200,
    exp05_n_per_cohort: int = 100,
    results_dir: Path | None = None,
) -> dict[str, Any]:
    """Exécute les expériences (1–3 en mode quick, 1–5 en mode full) et produit `validation_report.json` + `.md`."""
    out_dir = Path(results_dir) if results_dir is not None else ROOT_DIR / "results"
    out_dir.mkdir(parents=True, exist_ok=True)

    t_start = time.perf_counter()
    total_steps = 5 if include_dsm5_full else 3

    exp01 = _load_experiment_module("exp01_falsifiable_predictions", "experiments/01_falsifiable_predictions.py")
    exp02 = _load_experiment_module("exp02_clinical_phenotypes", "experiments/02_clinical_phenotypes.py")
    exp03 = _load_experiment_module("exp03_parameter_and_model_recovery", "experiments/03_parameter_and_model_recovery.py")

    print(f"[1/{total_steps}] Exécution Expérience 1 (Prédictions falsifiables Monte-Carlo)...", flush=True)
    t1 = time.perf_counter()
    res1 = exp01.run_experiment(num_trajectories=num_mc_trajectories, results_dir=out_dir)
    dt1 = time.perf_counter() - t1
    print(f"      Terminée en {dt1:.1f}s.", flush=True)

    print(f"[2/{total_steps}] Exécution Expérience 2 (Phénotypes cliniques pure-θ, N=20 appariés)...", flush=True)
    t2 = time.perf_counter()
    res2 = exp02.run_experiment(num_seeds_per_profile=num_clinical_seeds, results_dir=out_dir)
    dt2 = time.perf_counter() - t2
    print(f"      Terminée en {dt2:.1f}s.", flush=True)

    print(f"[3/{total_steps}] Exécution Expérience 3 (Parameter & Model Recovery NumPyro)...", flush=True)
    t3 = time.perf_counter()
    res3 = exp03.run_experiment(
        num_param_datasets=num_param_datasets,
        num_model_datasets_per_model=num_model_datasets_per_model,
        num_trials=num_recovery_trials,
        results_dir=out_dir,
    )
    dt3 = time.perf_counter() - t3
    print(f"      Terminée en {dt3:.1f}s.", flush=True)

    res4: dict[str, Any] | None = None
    res5: dict[str, Any] | None = None
    dt4 = 0.0
    dt5 = 0.0
    if include_dsm5_full:
        exp04 = _load_experiment_module("exp04_dsm5_phenotyping", "exploratory_synthetic/04_dsm5_phenotyping.py")
        exp05 = _load_experiment_module("exp05_dsm5_full_nosology", "exploratory_synthetic/05_dsm5_full_nosology.py")

        print(f"[4/{total_steps}] Exécution Expérience 4 [SYNTHETIC EXPLORATORY ONLY — V3 = 0] (8 cohortes synthétiques)...", flush=True)
        t4 = time.perf_counter()
        res4 = exp04.run_experiment(
            n_per_cohort=exp04_n_per_cohort,
            n_therapy_per_cohort=exp04_n_per_cohort,
            num_trials=num_recovery_trials,
            results_dir=out_dir / "dsm5_phenotyping",
        )
        dt4 = time.perf_counter() - t4
        print(f"      Terminée en {dt4:.1f}s.", flush=True)

        print(f"[5/{total_steps}] Exécution Expérience 5 [SYNTHETIC EXPLORATORY ONLY — V3 = 0] (26 régimes synthétiques)...", flush=True)
        t5 = time.perf_counter()
        res5 = exp05.run_experiment(
            n_per_cohort=exp05_n_per_cohort,
            n_therapy_per_cohort=exp05_n_per_cohort,
            num_trials=num_recovery_trials,
            results_dir=out_dir / "dsm5_full_nosology",
        )
        dt5 = time.perf_counter() - t5
        print(f"      Terminée en {dt5:.1f}s.", flush=True)

    total_dt = time.perf_counter() - t_start

    p1 = res1["prediction_1_budget_tradeoff"]
    p2 = res1["prediction_2_axial_instability"]
    p3 = res1["prediction_3_hierarchical_inertia"]
    p4 = res1.get("prediction_4_lexicographic_valence")
    p5 = res1.get("prediction_5_fear_control_mediation")
    pr = res3["parameter_recovery"]
    mr = res3["model_recovery"]
    ht2 = res2["hypothesis_tests"]

    nuts_checks = pr.get("nuts_checks", [])
    nuts_max_rhat = pr.get("nuts_max_rhat")
    if nuts_max_rhat is None and isinstance(nuts_checks, list) and nuts_checks:
        nuts_max_rhat = max(float(item["max_rhat"]) for item in nuts_checks)
    nuts_min_ess = pr.get("nuts_min_ess")
    if nuts_min_ess is None and isinstance(nuts_checks, list) and nuts_checks:
        nuts_min_ess = min(float(item["min_ess"]) for item in nuts_checks)

    criteria = {
        "exp01_p1_negative_budget_corr": bool(
            p1["lambda_1"]["mean_traj_corr"] < -0.60 and p1["comparison"]["paired_p"] < 1e-10
        ),
        "exp01_p1_cooperative_orthogonal": bool(
            abs(p1["lambda_0"]["mean_traj_corr"]) < 0.05
        ),
        "exp01_p2_b_prior_symmetric": bool(
            p2["b_prior_sym_diff"] < 1e-12 and p2["b_prior_symmetric"]
        ),
        "exp01_p2_axial_shorter_residence": bool(
            p2["residence_time"]["axial_mean"] < p2["residence_time"]["diagonal_mean"]
            and p2["residence_time"]["paired_p"] < 0.001
        ),
        "exp01_p2_axial_to_diag_gt_reverse": bool(
            p2["transition_rates"]["p_axial_to_diagonal_mean"]
            > p2["transition_rates"]["p_diagonal_to_axial_mean"]
            and p2["transition_rates"]["paired_p"] < 0.001
        ),
        "exp01_p2_opposite_pole_low": bool(
            p2["opposite_pole_transitions"]["max_opposite_pole_rate"] < 0.05
        ),
        "exp01_p3_halflife_z5_gt_z4_gt_z2": bool(
            p3["half_life"]["5"]["mean"] > p3["half_life"]["4"]["mean"] > p3["half_life"]["2"]["mean"]
            and p3["tests"]["half_life_z4_vs_z2"]["mannwhitney_p"] < 0.001
            and p3["tests"]["half_life_z5_vs_z2"]["mannwhitney_p"] < 0.001
            and p3["tests"]["half_life_z5_vs_z4"]["mannwhitney_p"] < 0.001
        ),
        "exp01_p3_resistance_z5_gt_z4_gt_z2": bool(
            p3["resistance_index"]["5"]["mean"]
            > p3["resistance_index"]["4"]["mean"]
            > p3["resistance_index"]["2"]["mean"]
            and p3["tests"]["resistance_z4_vs_z2"]["mannwhitney_p"] < 0.001
            and p3["tests"]["resistance_z5_vs_z2"]["mannwhitney_p"] < 0.001
            and p3["tests"]["resistance_z5_vs_z4"]["mannwhitney_p"] < 0.001
        ),
        "exp02_pure_theta_only": bool(res2["pure_theta_only"]),
        "exp02_inhibited_remission_trapping": bool(
            ht2["inhibited_vs_normo_z_remission"]["p_holm"] < 0.05
            and ht2["inhibited_vs_normo_neg_neg_loss"]["p_holm"] < 0.05
            and res2["clinical_probes"]["b_inhibited"]["seeds_reaching_z5_neg_neg"] >= 1
        ),
        "exp02_agitated_neg_pos_oscillation": bool(
            ht2["agitated_vs_normo_neg_pos_threat"]["p_holm"] < 0.05
            and ht2["agitated_vs_inhibited_neg_pos_threat"]["p_holm"] < 0.05
        ),
        "exp02_rigid_x_zero_lock": bool(
            ht2["rigid_vs_normo_x_zero_lock"]["p_holm"] < 0.05
            and ht2["rigid_vs_normo_x_zero_stress"]["p_holm"] < 0.05
            and res2["clinical_probes"]["d_rigid_bias"]["total_infini_visits"] == 0
        ),
        "exp03_parameter_recovery_r_ge_080": bool(pr["target_r_ge_080_met"]),
        "exp03_parameter_coverage_ge_085": bool(float(pr["min_coverage_95"]) >= 0.85),
        "exp03_parameter_no_critical_collinearity": bool(float(pr["max_abs_offdiag_r"]) < 0.50),
        "exp03_nuts_rhat_lt_102": bool(nuts_max_rhat is not None and float(nuts_max_rhat) < 1.02),
        "exp03_nuts_ess_ge_400": bool(nuts_min_ess is not None and float(nuts_min_ess) >= 400.0),
        "exp03_model_recovery_diag_pxp_gt_095": bool(mr["target_pxp_gt_095_met"]),
    }

    if isinstance(p4, dict):
        criteria["exp01_p4_b_prior_symmetric"] = bool(p4.get("b_prior_symmetric"))
        criteria["exp01_p4_arm_a_strict_opposition"] = bool(
            float(p4.get("carto_negative_rate_arm_a", 0.0)) > 0.99
            and float(p4.get("jc_positive_rate_arm_a", 0.0)) > 0.99
            and int(p4.get("arm_a_loss_resolution", {}).get("n_dissociation_trials", 0)) > 0
        )
        criteria["exp01_p4_arm_b_strict_opposition"] = bool(
            float(p4.get("carto_positive_rate_arm_b", 0.0)) > 0.99
            and float(p4.get("jc_negative_rate_arm_b", 0.0)) > 0.99
            and int(p4.get("arm_b_uncertainty_onset", {}).get("n_dissociation_trials", 0)) > 0
        )

    if isinstance(p5, dict):
        conds_p5 = p5.get("conditions", {})
        c010 = conds_p5.get("0.10", {})
        c090 = conds_p5.get("0.90", {})
        cmp_p5 = p5.get("comparisons_090_vs_010", {})
        med_p5 = p5.get("mediation", {})
        criteria["exp01_p5_b_prior_symmetric"] = bool(p5.get("b_prior_symmetric"))
        criteria["exp01_p5_control_shifts_colere_over_degout"] = bool(
            float(c090.get("p_colere_mean", 0.0)) > float(c010.get("p_colere_mean", 1.0))
            and float(c010.get("p_degout_mean", 0.0)) > float(c090.get("p_degout_mean", 1.0))
            and float(cmp_p5.get("bifurcation", {}).get("mannwhitney_p", 1.0)) < 0.001
        )
        criteria["exp01_p5_mediation_indirect_positive"] = bool(
            float(med_p5.get("indirect_ab", 0.0)) > 0.0
            and float(med_p5.get("sobel_p", 1.0)) < 0.001
        )

    if include_dsm5_full and res4 is not None and res5 is not None:
        criteria["exp04_dsm5_combined_accuracy_gt_085"] = bool(
            float(res4["separability"]["theta_hat_plus_dynamics"]["accuracy"]) > 0.85
        )
        criteria["exp05_hitop_combined_accuracy_gt_080"] = bool(
            float(res5["separability_hitop_spectra"]["theta_hat_plus_dynamics"]["accuracy"]) > 0.80
        )

    timings: dict[str, float] = {
        "exp01": round(dt1, 2),
        "exp02": round(dt2, 2),
        "exp03": round(dt3, 2),
    }
    if include_dsm5_full:
        timings["exp04"] = round(dt4, 2)
        timings["exp05"] = round(dt5, 2)

    report = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "mode": "full" if include_dsm5_full else "quick",
        "total_runtime_seconds": round(total_dt, 2),
        "timings_seconds": timings,
        "configuration": {
            "num_mc_trajectories": num_mc_trajectories,
            "num_clinical_seeds": num_clinical_seeds,
            "num_param_datasets": num_param_datasets,
            "num_model_datasets_per_model": num_model_datasets_per_model,
            "num_recovery_trials": num_recovery_trials,
            "include_dsm5_full": include_dsm5_full,
        },
        "all_criteria_passed": bool(all(criteria.values())),
        "criteria": criteria,
        "exp01_falsifiable_predictions": res1,
        "exp02_clinical_phenotypes": res2,
        "exp03_parameter_and_model_recovery": res3,
    }
    if res4 is not None:
        report["exp04_dsm5_phenotyping"] = res4
    if res5 is not None:
        report["exp05_dsm5_full_nosology"] = res5

    (out_dir / "validation_report.json").write_text(
        json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    _write_markdown_summary(out_dir / "validation_summary.md", report)
    return report


def _write_markdown_summary(md_path: Path, report: dict[str, Any]) -> None:
    r1 = report["exp01_falsifiable_predictions"]
    r2 = report["exp02_clinical_phenotypes"]
    r3 = report["exp03_parameter_and_model_recovery"]
    p1 = r1["prediction_1_budget_tradeoff"]
    p2 = r1["prediction_2_axial_instability"]
    p3 = r1["prediction_3_hierarchical_inertia"]
    p4 = r1.get("prediction_4_lexicographic_valence")
    p5 = r1.get("prediction_5_fear_control_mediation")
    pr = r3["parameter_recovery"]
    mr = r3["model_recovery"]

    pxp_diag = np.diag(np.asarray(mr["pxp_matrix"], dtype=np.float64)).tolist()
    pxp_waic_diag = (
        np.diag(np.asarray(mr["pxp_waic"], dtype=np.float64)).tolist()
        if "pxp_waic" in mr
        else pxp_diag
    )
    waic_diag = np.diag(np.asarray(mr["waic_confusion"], dtype=np.float64)).tolist()
    bic_diag = np.diag(np.asarray(mr["bic_confusion"], dtype=np.float64)).tolist()

    lines = [
        "# Rapport de validation *in silico* — CARTOGRAFFECT",
        "",
        f"- **Horodatage (UTC) :** `{report['generated_at_utc']}`",
        f"- **Durée totale :** `{report['total_runtime_seconds']:.2f} s` "
        f"(Exp 1 : `{report['timings_seconds']['exp01']:.2f} s`, "
        f"Exp 2 : `{report['timings_seconds']['exp02']:.2f} s`, "
        f"Exp 3 : `{report['timings_seconds']['exp03']:.2f} s`)",
        f"- **Statut global :** `{'SUCCÈS COMPLET' if report['all_criteria_passed'] else 'ATTENTION REQUISE'}`",
        "",
        "## 1. Expérience 1 — Tests de cohérence *in silico* (P1 : projecteur budgétaire $L_1$ ; P2–P5 : dynamique `pymdp`, V3 = 0)",
        "",
        f"*(N = {report['configuration']['num_mc_trajectories']} trajectoires par condition ; "
        f"symétrie préalable `B(Z=2)` : `Δ_prior = {p2.get('b_prior_sym_diff', 0.0):.2e}`, "
        f"bascule pôles opposés max = `{p2.get('opposite_pole_transitions', {}).get('max_opposite_pole_rate', 0.0):.4f}`)*",
        "",
        "| Prédiction | Condition / Comparaison | Valeur principale | Comparateur | Statistique / p-value |",
        "| :--- | :--- | :---: | :---: | :--- |",
        f"| **P1 — Arbitrage $L_1$** ($Z=4$) | Corr. $(\\Delta|X_t|, \\Delta|Y_t|)$ : $\\lambda=1$ vs $\\lambda=0$ | "
        f"`{p1['lambda_1']['mean_traj_corr']:.4f}` | `{p1['lambda_0']['mean_traj_corr']:.4f}` | "
        f"$p = {_format_p(float(p1['comparison']['wilcoxon_p']))}$ (paired t: `{_format_p(float(p1['comparison']['paired_p']))}`), $d_z = {p1['comparison']['cohens_dz']:.2f}$ |",
        f"| **P2 — Résidence axiale** ($Z=2$) | Temps moyen Axial vs Diagonal | "
        f"`{p2['residence_time']['axial_mean']:.3f}` | `{p2['residence_time']['diagonal_mean']:.3f}` | "
        f"$p = {_format_p(float(p2['residence_time']['wilcoxon_p']))}$, $d_z = {p2['residence_time']['cohens_dz_diag_minus_axial']:.2f}$ |",
        f"| **P2 — Asymétrie de transition** | $P(\\text{{Ax}}\\to\\text{{Diag}})$ vs $P(\\text{{Diag}}\\to\\text{{Ax}})$ | "
        f"`{p2['transition_rates']['p_axial_to_diagonal_mean']:.4f}` | `{p2['transition_rates']['p_diagonal_to_axial_mean']:.4f}` | "
        f"$p = {_format_p(float(p2['transition_rates']['wilcoxon_p']))}$, $d_z = {p2['transition_rates']['cohens_dz']:.2f}$ |",
        f"| **P3 — Demi-vie hiérarchique** | $t_{{1/2}}(Z=4)$ vs $t_{{1/2}}(Z=2)$ | "
        f"`{p3['half_life']['4']['mean']:.2f}` | `{p3['half_life']['2']['mean']:.2f}` | "
        f"$p = {_format_p(float(p3['tests']['half_life_z4_vs_z2']['mannwhitney_p']))}$, $d = {p3['tests']['half_life_z4_vs_z2']['cohens_d']:.2f}$ |",
        f"| **P3 — Demi-vie hiérarchique** | $t_{{1/2}}(Z=5)$ vs $t_{{1/2}}(Z=2)$ | "
        f"`{p3['half_life']['5']['mean']:.2f}` | `{p3['half_life']['2']['mean']:.2f}` | "
        f"$p = {_format_p(float(p3['tests']['half_life_z5_vs_z2']['mannwhitney_p']))}$, $d = {p3['tests']['half_life_z5_vs_z2']['cohens_d']:.2f}$ |",
        f"| **P3 — Résistance Dirichlet** | Rétention vraisemblance $Z=5$ vs $Z=2$ | "
        f"`{p3['resistance_index']['5']['mean']:.4f}` | `{p3['resistance_index']['2']['mean']:.4f}` | "
        f"$p = {_format_p(float(p3['tests']['resistance_z5_vs_z2']['mannwhitney_p']))}$, $d = {p3['tests']['resistance_z5_vs_z2']['cohens_d']:.2f}$ |",
    ]
    if isinstance(p4, dict):
        arm_a = p4["arm_a_loss_resolution"]
        arm_b = p4["arm_b_uncertainty_onset"]
        lines.extend(
            [
                f"| **P4 — Lexicographie (Bras A)** | Taux valence négative ($X_t<0, \\Delta\\nabla A_t>0$) : CARTO vs J\\&C | "
                f"`{arm_a['carto_negative_rate']:.3f}` | `{arm_a['jc_negative_rate']:.3f}` | "
                f"$p = {arm_a['wilcoxon_p_str']}$ (Wilcoxon, {arm_a['n_dissociation_trials']} essais) |",
                f"| **P4 — Lexicographie (Bras B)** | Taux valence positive ($X_t>0, \\Delta\\nabla A_t<0$) : CARTO vs J\\&C | "
                f"`{arm_b['carto_positive_rate']:.3f}` | `{arm_b['jc_positive_rate']:.3f}` | "
                f"$p = {arm_b['wilcoxon_p_str']}$ (Wilcoxon, {arm_b['n_dissociation_trials']} essais) |",
            ]
        )
    if isinstance(p5, dict):
        c010 = p5["conditions"]["0.10"]
        c090 = p5["conditions"]["0.90"]
        cmp5 = p5["comparisons_090_vs_010"]
        med5 = p5["mediation"]
        lines.extend(
            [
                f"| **P5 — Peur $\\to$ Colère vs Dégoût** | Indice $P(\\text{{Col}}) - P(\\text{{Dég}})$ : $p_{{\\text{{ctrl}}}}=0.90$ vs $0.10$ | "
                f"`{c090['bifurcation_index_mean']:+.4f}` | `{c010['bifurcation_index_mean']:+.4f}` | "
                f"$p = {cmp5['bifurcation']['mannwhitney_p_str']}$, $d = {cmp5['bifurcation']['cohens_d']:.2f}$ |",
                f"| **P5 — Médiation $\\hat{{p}}_{{\\text{{ctrl}}}}$** | Effet indirect Sobel $a\\cdot b$ ($c' = {med5['path_c_prime_direct']:+.4f}$) | "
                f"`{med5['indirect_ab']:.4f}` | `Sobel z = {med5['sobel_z']:.2f}` | "
                f"$p = {med5['sobel_p_str']}$, $\\rho_S = {med5['spearman_rho_p_hat_vs_bifurcation']:.4f}$ |",
            ]
        )
    lines.extend(
        [
            "",
            "## 2. Expérience 2 — Phénotypes cliniques comparés (pure-θ, protocole unifié)",
            "",
            f"*(N = {r2['num_seeds_per_profile']} graines appariées / phénotype ; "
            f"`pure_theta_only = {r2.get('pure_theta_only', True)}`)*",
            "",
            "| Phénotype | $Z$ en rémission (moy. ± ET) | Retour `PdV` rém. | Quadrant $(-X,-Y)$ perte | Quadrant $(-X,+Y)$ menace | Verrouillage $X=0$ (stresseurs) |",
            "| :--- | :---: | :---: | :---: | :---: | :---: |",
        ]
    )
    for pkey, metrics in r2["unified_cohort"].items():
        lines.append(
            f"| `{pkey}` | `{metrics['mean_z_remission']['mean']:.2f} ± {metrics['mean_z_remission']['sd']:.2f}` | "
            f"`{metrics['pdv_fraction_remission']['mean']:.3f}` | "
            f"`{metrics['quadrant_neg_neg_loss']['mean']:.3f}` | "
            f"`{metrics['quadrant_neg_pos_threat']['mean']:.3f}` | "
            f"`{metrics['x_zero_lock_stress']['mean']:.3f}` |"
        )

    ht2 = r2["hypothesis_tests"]
    lines.extend(
        [
            "",
            "| Hypothèse (Wilcoxon apparié bilatéral + Holm-Bonferroni) | Médiane A vs B | $p_{\\text{brut}}$ | $p_{\\text{Holm}}$ | Rang-bisérial $r_{rb}$ |",
            "| :--- | :---: | :---: | :---: | :---: |",
        ]
    )
    for hkey, hval in ht2.items():
        med_a = hval.get("median_a", hval.get("mean_a", 0.0))
        med_b = hval.get("median_b", hval.get("mean_b", 0.0))
        p_raw = float(hval["p_value"])
        p_h = float(hval.get("p_holm", p_raw))
        r_rb = float(hval.get("r_rb", hval.get("cohens_d", 0.0)))
        lines.append(
            f"| `{hkey}` | `{med_a:.3f}` vs `{med_b:.3f}` | "
            f"`{_format_p(p_raw)}` | `{_format_p(p_h)}` | `{r_rb:.3f}` |"
        )

    lines.extend(
        [
            "",
            "- **Attracteurs (cohorte unifiée) :** "
            f"`b_inhibited` atteint $Z\\geq 5$ en $(-X,-Y)$ sur `{r2['clinical_probes']['b_inhibited']['seeds_reaching_z5_neg_neg']}/{r2['num_seeds_per_profile']}` graines ; "
            f"`d_rigid_bias` enregistre `{r2['clinical_probes']['d_rigid_bias'].get('total_infini_visits', 0)}` visites sur *Infini* `(0,+12,7)`.",
            "",
            "## 3. Expérience 3 — Parameter & Model Recovery (NumPyro SVI + NUTS)",
            "",
            f"*(Parameter Recovery : M = {pr['num_datasets']} ; Model Recovery : 4 × {mr['num_datasets_per_model']}, T = {pr['num_trials']} essais)*",
            "",
            "| Paramètre | Pearson $r$ | RMSE | Couverture IC 95 % |",
            "| :--- | :---: | :---: | :---: |",
        ]
    )
    for pname in pr["pearson_r"]:
        lines.append(
            f"| `{pname}` | `{pr['pearson_r'][pname]:.4f}` | `{pr['rmse'][pname]:.4f}` | `{pr['coverage_95'][pname]:.3f}` |"
        )

    nuts_checks = pr.get("nuts_checks", [])
    if isinstance(nuts_checks, list) and nuts_checks:
        nuts_max_rhat = max(float(item["max_rhat"]) for item in nuts_checks)
        nuts_min_ess = min(float(item["min_ess"]) for item in nuts_checks)
        nuts_line = (
            f"- **Contrôle MCMC NUTS ({len(nuts_checks)} jeux) :** "
            f"`max R-hat = {nuts_max_rhat:.3f}`, `min ESS = {nuts_min_ess:.1f}`"
        )
    elif isinstance(nuts_checks, dict):
        nuts_line = (
            f"- **Contrôle MCMC NUTS :** "
            f"`max R-hat = {nuts_checks['max_rhat']:.3f}`, `min ESS = {nuts_checks['min_ess']:.1f}`"
        )
    else:
        nuts_line = "- **Contrôle MCMC NUTS :** non exécuté"

    min_cov = pr.get("min_coverage_95", min(pr["coverage_95"].values()))
    max_err_corr = pr.get("max_abs_error_corr", 0.0)
    lines.extend(
        [
            "",
            f"- **$r$ minimal sur $\\theta$ :** `{pr['min_diagonal_r']:.4f}` (critère $\\ge 0.80$ : `{pr['target_r_ge_080_met']}`)",
            f"- **Couverture IC 95 % minimale :** `{min_cov:.3f}` (critère $\\ge 0.85$)",
            f"- **Corrélation hors-diagonale max ($\\theta^*$ vs $\\hat{{\\theta}}$) :** `{pr['max_abs_offdiag_r']:.4f}`",
            f"- **Corrélation d'erreur max ($\\hat{{\\theta}} - \\theta^*$) :** `{max_err_corr:.4f}`",
            nuts_line,
            "",
            "| Modèle générateur | $pxp$ (BIC) | $pxp$ (WAIC) | Récup. BIC (max LL) | Récup. WAIC |",
            "| :--- | :---: | :---: | :---: | :---: |",
        ]
    )
    for idx, mname in enumerate(mr["model_names"]):
        lines.append(
            f"| `{mname}` | `{pxp_diag[idx]:.4f}` | `{pxp_waic_diag[idx]:.4f}` | `{bic_diag[idx]:.3f}` | `{waic_diag[idx]:.3f}` |"
        )
    lines.extend(
        [
            "",
            f"- **$pxp$ minimal sur la diagonale (BIC) :** `{mr['min_diagonal_pxp']:.4f}` (critère $> 0.95$ : `{mr['target_pxp_gt_095_met']}`)",
            "",
            "## 4. Critères de validation",
            "",
        ]
    )
    for cname, ok in report["criteria"].items():
        lines.append(f"- `[{'PASS' if ok else 'FAIL'}]` `{cname}`")

    md_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Suite complète de validation CARTOGRAFFECT.")
    mode_group = parser.add_mutually_exclusive_group()
    mode_group.add_argument(
        "--quick",
        action="store_true",
        help="Exécute les Expériences 1 à 3 (mode par défaut).",
    )
    mode_group.add_argument(
        "--full",
        action="store_true",
        help="Exécute les Expériences 1 à 5 (inclut le phénotypage DSM-5 Exp 4 et la nosologie complète Exp 5).",
    )
    parser.add_argument("--mc-trajectories", type=int, default=1000)
    parser.add_argument("--clinical-seeds", type=int, default=20)
    parser.add_argument("--param-datasets", type=int, default=500)
    parser.add_argument("--model-datasets", type=int, default=100)
    parser.add_argument("--recovery-trials", type=int, default=280)
    parser.add_argument("--exp04-n-per-cohort", type=int, default=200)
    parser.add_argument("--exp05-n-per-cohort", type=int, default=100)
    args = parser.parse_args()

    report = run_all(
        num_mc_trajectories=args.mc_trajectories,
        num_clinical_seeds=args.clinical_seeds,
        num_param_datasets=args.param_datasets,
        num_model_datasets_per_model=args.model_datasets,
        num_recovery_trials=args.recovery_trials,
        include_dsm5_full=bool(args.full),
        exp04_n_per_cohort=args.exp04_n_per_cohort,
        exp05_n_per_cohort=args.exp05_n_per_cohort,
    )
    print(json.dumps(report["criteria"], indent=2))
    print("ALL_CRITERIA_PASSED:", report["all_criteria_passed"])
    print(f"TOTAL_RUNTIME: {report['total_runtime_seconds']:.2f}s")
    if not report["all_criteria_passed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
