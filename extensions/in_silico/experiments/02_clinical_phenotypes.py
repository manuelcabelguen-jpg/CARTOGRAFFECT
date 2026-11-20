"""Expérience 2 : Simulation des 4 phénotypes cliniques en inférence active (pure-θ).

Compare quatre paramétrisations du POMDP complet à 176 états CARTOGRAFFECT
en ne faisant varier STRICTEMENT QUE les 8 paramètres théoriques θ
(τ_A, τ_C, λ, α_0, γ_α, η_diss, β_X, β_Y), tous les hyperparamètres
numériques restant identiques :
    - (a) Normothymique flexible : retour homéostatique rapide vers (0, 0, 0).
    - (b) Dépression inhibée (α_0, γ_α élevés, η_diss faible) : piégeage profond
          en rémission et persistance en (-X, -Y) sous perte incontrôlable.
    - (c) Dépression agitée / anxieuse (α élevé, τ_C bas, β_X/β_Y élevé) :
          dominance et oscillation ergotropique en (-X, +Y) sous menace volatile.
    - (d) Biais attentionnel rigide (τ_A >> τ_C) : verrouillage X = 0 sans
          saturation pathologique sur l'apex positif (0, +12, 7).

Exporte :
    - `results/exp02_phenotypes.json`
    - `results/exp02_trajectories.csv`
    - `results/exp02_phenotype_metrics.csv`
    - `results/fig2_clinical_phenotypes.png` (300 DPI)
"""

from __future__ import annotations

import json
import math
import sys
from collections import Counter
from dataclasses import fields
from pathlib import Path
from typing import Any

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from scipy import stats

ROOT_DIR = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT_DIR / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from cartograffect_sim.affective_matrix import (  # noqa: E402
    ActiveInferenceCartograffectAgent,
    SessionResult,
)
from cartograffect_sim.generative_process import (  # noqa: E402
    BlockSpec,
    NonStationaryBanditEnv,
)
from cartograffect_sim.predictive_engine import AgentParameters  # noqa: E402

_THETA_FIELDS: frozenset[str] = frozenset(
    {
        "tau_a",
        "tau_c",
        "lambda_weight",
        "alpha_0",
        "gamma_alpha",
        "eta_diss",
        "beta_x",
        "beta_y",
    }
)


def _format_p(p: float) -> str:
    """Formate une p-value sans jamais afficher `0.00e+00`."""
    if not math.isfinite(p):
        return "nan"
    if p < 1e-300:
        return "< 1e-300"
    return f"{p:.2e}"


def get_clinical_profiles() -> dict[str, dict[str, Any]]:
    """Définit les 4 profils cliniques en ne variant STRICTEMENT que les 8 paramètres θ."""
    return {
        "a_normothymic": {
            "display_name": "Normothymique flexible",
            "short_name": "(a) Normothymique",
            "color": "#1b9e77",
            "params": AgentParameters(
                tau_a=0.24,
                tau_c=0.24,
                lambda_weight=0.75,
                alpha_0=0.80,
                gamma_alpha=0.35,
                eta_diss=0.45,
                beta_x=2.2,
                beta_y=1.1,
            ),
        },
        "b_inhibited": {
            "display_name": "Dépression inhibée",
            "short_name": "(b) Dépression inhibée",
            "color": "#377eb8",
            "params": AgentParameters(
                tau_a=0.25,
                tau_c=0.12,
                lambda_weight=0.85,
                alpha_0=3.50,
                gamma_alpha=0.75,
                eta_diss=0.03,
                beta_x=1.8,
                beta_y=1.4,
            ),
        },
        "c_agitated": {
            "display_name": "Dépression agitée / anxieuse",
            "short_name": "(c) Dépression agitée",
            "color": "#d95f02",
            "params": AgentParameters(
                tau_a=0.14,
                tau_c=0.09,
                lambda_weight=0.68,
                alpha_0=2.50,
                gamma_alpha=0.58,
                eta_diss=0.08,
                beta_x=2.9,
                beta_y=1.0,
            ),
        },
        "d_rigid_bias": {
            "display_name": "Biais attentionnel rigide",
            "short_name": "(d) Biais rigide",
            "color": "#7570b3",
            "params": AgentParameters(
                tau_a=0.95,
                tau_c=0.12,
                lambda_weight=0.80,
                alpha_0=1.80,
                gamma_alpha=0.45,
                eta_diss=0.30,
                beta_x=2.0,
                beta_y=1.2,
            ),
        },
    }


def assert_pure_theta_profiles(profiles: dict[str, dict[str, Any]]) -> bool:
    """Vérifie que tous les champs non-θ d'`AgentParameters` sont strictement identiques."""
    baseline = AgentParameters()
    non_theta_fields = [f.name for f in fields(AgentParameters) if f.name not in _THETA_FIELDS]
    for pkey, pinfo in profiles.items():
        p_obj: AgentParameters = pinfo["params"]
        for fname in non_theta_fields:
            v_prof = getattr(p_obj, fname)
            v_base = getattr(baseline, fname)
            if v_prof != v_base:
                raise AssertionError(
                    f"Le profil {pkey} modifie l'hyperparamètre non-θ '{fname}' "
                    f"({v_prof!r} != {v_base!r})."
                )
    return True


def build_unified_clinical_schedule() -> list[BlockSpec]:
    """Protocole unifié à 5 blocs (260 essais) testant perte, menace et rémission."""
    return [
        BlockSpec(
            block_id=0,
            name="baseline_calm",
            num_trials=20,
            p_ctrl=0.88,
            v_rule=0.05,
            cue_clarity=0.92,
            d_obj=2,
            is_remission=True,
        ),
        BlockSpec(
            block_id=1,
            name="loss_uncontrollable_d3",
            num_trials=70,
            p_ctrl=0.12,
            v_rule=0.25,
            cue_clarity=0.55,
            d_obj=3,
            is_remission=False,
        ),
        BlockSpec(
            block_id=2,
            name="remission_post_loss",
            num_trials=50,
            p_ctrl=0.88,
            v_rule=0.05,
            cue_clarity=0.92,
            d_obj=2,
            is_remission=True,
        ),
        BlockSpec(
            block_id=3,
            name="volatile_threat_d4",
            num_trials=70,
            p_ctrl=0.88,
            v_rule=0.35,
            cue_clarity=0.55,
            d_obj=4,
            is_remission=False,
        ),
        BlockSpec(
            block_id=4,
            name="remission_final",
            num_trials=50,
            p_ctrl=0.88,
            v_rule=0.05,
            cue_clarity=0.92,
            d_obj=2,
            is_remission=True,
        ),
    ]


def _extract_session_metrics(res: SessionResult) -> dict[str, Any]:
    recs = res.records
    xs = np.array([r.map_entry.point.x for r in recs], dtype=np.int32)
    ys = np.array([r.map_entry.point.y for r in recs], dtype=np.int32)
    zs = np.array([r.map_entry.point.z for r in recs], dtype=np.int32)
    exp_z = np.array([r.expected_z for r in recs], dtype=np.float64)
    p_homeo = np.array([r.p_homeostasis for r in recs], dtype=np.float64)
    labels = [r.map_entry.label for r in recs]
    rem_mask = np.array([bool(r.is_remission and r.block_id > 0) for r in recs], dtype=bool)
    rem_final_mask = np.array([r.block_name == "remission_final" for r in recs], dtype=bool)
    stress_mask = np.array([not r.is_remission for r in recs], dtype=bool)
    loss_mask = np.array([r.block_name == "loss_uncontrollable_d3" for r in recs], dtype=bool)
    threat_mask = np.array([r.block_name == "volatile_threat_d4" for r in recs], dtype=bool)

    state_changes = int(np.sum([labels[i] != labels[i - 1] for i in range(1, len(labels))]))
    q_np_mask = (xs < 0) & (ys > 0)
    q_nn_mask = (xs < 0) & (ys < 0)

    osc_np = int(
        sum(
            1
            for i in range(1, len(labels))
            if (q_np_mask[i] or q_np_mask[i - 1]) and labels[i] != labels[i - 1]
        )
    )

    rem_zs = zs[rem_mask] if np.any(rem_mask) else zs
    rem_pdv = p_homeo[rem_mask] if np.any(rem_mask) else p_homeo
    rem_final_tail = exp_z[rem_final_mask][-5:] if np.any(rem_final_mask) else exp_z[-5:]
    post_mask = loss_mask | rem_mask if np.any(loss_mask) else stress_mask | rem_mask

    return {
        "mean_z_stress": float(np.mean(zs[stress_mask])) if np.any(stress_mask) else float(np.mean(zs)),
        "max_z_session": int(np.max(zs)),
        "mean_z_remission": float(np.mean(rem_zs)),
        "end_z_remission_final": float(np.mean(rem_final_tail)),
        "pdv_fraction_remission": float(np.mean(rem_zs == 0)),
        "p_homeostasis_remission": float(np.mean(rem_pdv)),
        "quadrant_neg_neg_stress": float(np.mean(q_nn_mask[loss_mask]))
        if np.any(loss_mask)
        else float(np.mean(q_nn_mask[stress_mask])),
        "quadrant_neg_neg_post": float(np.mean(q_nn_mask[post_mask])),
        "quadrant_neg_pos_threat": float(np.mean(q_np_mask[threat_mask]))
        if np.any(threat_mask)
        else float(np.mean(q_np_mask[stress_mask])),
        "quadrant_neg_pos_session": float(np.mean(q_np_mask)),
        "oscillation_rate_neg_pos": float(osc_np / max(1, len(labels) - 1)),
        "state_switch_rate": float(state_changes / max(1, len(labels) - 1)),
        "x_zero_lock_fraction": float(np.mean(xs == 0)),
        "x_zero_lock_stress": float(np.mean(xs[stress_mask] == 0))
        if np.any(stress_mask)
        else float(np.mean(xs == 0)),
        "z5_neg_neg_visits": int(np.sum((zs >= 5) & q_nn_mask)),
        "z5_neg_pos_visits": int(np.sum((zs >= 5) & q_np_mask)),
        "z6_neg_pos_visits": int(np.sum((zs >= 6) & q_np_mask)),
        "desespoir_visits": int(sum(1 for lb in labels if lb == "Désespoir")),
        "tourment_visits": int(sum(1 for lb in labels if lb == "Tourment")),
        "infini_visits": int(sum(1 for lb in labels if lb == "Infini")),
        "top_states": Counter(labels).most_common(6),
        "xs": xs,
        "ys": ys,
        "zs": zs,
        "exp_z": exp_z,
        "p_homeo": p_homeo,
        "labels": labels,
    }


def _session_to_rows(
    cohort_tag: str,
    profile_key: str,
    seed: int,
    res: SessionResult,
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for r in res.records:
        pt = r.map_entry.point
        rows.append(
            {
                "cohort": cohort_tag,
                "profile": profile_key,
                "seed": seed,
                "trial": r.trial_index,
                "block_id": r.block_id,
                "block_name": r.block_name,
                "is_remission": bool(r.is_remission),
                "x": int(pt.x),
                "y": int(pt.y),
                "z": int(pt.z),
                "expected_z": float(r.expected_z),
                "p_homeostasis": float(r.p_homeostasis),
                "weighted_valence": float(r.weighted_valence),
                "state_id": int(r.map_state_index),
                "label": r.map_entry.label,
                "sector": (
                    str(r.map_entry.orientation_sector)
                    if r.map_entry.orientation_sector is not None
                    else "CENTRAL"
                ),
                "filter_a": int(r.ema_observation.filter_a),
                "filter_c": int(r.ema_observation.filter_c),
            }
        )
    return rows


def _paired_wilcoxon_two_sided(
    va: np.ndarray,
    vb: np.ndarray,
) -> dict[str, Any]:
    """Wilcoxon signed-rank bilatéral apparié + corrélation rang-bisériale (r_rb)."""
    diff = np.asarray(va, dtype=np.float64) - np.asarray(vb, dtype=np.float64)
    nonzero = diff[np.abs(diff) > 1e-12]
    n_nz = len(nonzero)
    if n_nz == 0:
        w_stat = 0.0
        p_val = 1.0
        r_rb = 0.0
    else:
        res = stats.wilcoxon(diff, alternative="two-sided", zero_method="wilcox")
        w_stat = float(res.statistic)
        p_val = float(res.pvalue)
        # Rank-biserial correlation appariée : (W+ - W-) / T_total
        ranks = stats.rankdata(np.abs(nonzero))
        total_rank_sum = float(np.sum(ranks))
        w_pos = float(np.sum(ranks[nonzero > 0.0]))
        w_neg = float(np.sum(ranks[nonzero < 0.0]))
        r_rb = float((w_pos - w_neg) / max(1e-12, total_rank_sum))

    return {
        "wilcoxon_w": w_stat,
        "p_value": p_val,
        "p_value_str": _format_p(p_val),
        "r_rb": r_rb,
        "median_a": float(np.median(va)),
        "median_b": float(np.median(vb)),
        "iqr_a": float(np.percentile(va, 75) - np.percentile(va, 25)),
        "iqr_b": float(np.percentile(vb, 75) - np.percentile(vb, 25)),
        "mean_a": float(np.mean(va)),
        "mean_b": float(np.mean(vb)),
    }


def _apply_holm_bonferroni(tests: dict[str, dict[str, Any]]) -> dict[str, dict[str, Any]]:
    """Ajoute ``p_holm`` et ``p_holm_str`` par procédure séquentielle de Holm-Bonferroni."""
    keys = list(tests.keys())
    m = len(keys)
    sorted_keys = sorted(keys, key=lambda k: float(tests[k]["p_value"]))
    prev_adj = 0.0
    for rank_idx, k in enumerate(sorted_keys):
        mult = m - rank_idx
        raw_p = float(tests[k]["p_value"])
        adj_p = min(1.0, max(prev_adj, raw_p * mult))
        prev_adj = adj_p
        tests[k]["p_holm"] = float(adj_p)
        tests[k]["p_holm_str"] = _format_p(float(adj_p))
    return tests


def _select_median_representative_session(
    pkey: str,
    sessions: list[tuple[int, SessionResult, dict[str, Any]]],
) -> tuple[int, SessionResult, dict[str, Any]]:
    """Sélectionne la graine la plus proche de la médiane de la cohorte (zéro cherry-picking)."""
    criterion_map = {
        "a_normothymic": "pdv_fraction_remission",
        "b_inhibited": "mean_z_remission",
        "c_agitated": "quadrant_neg_pos_threat",
        "d_rigid_bias": "x_zero_lock_stress",
    }
    crit_key = criterion_map[pkey]
    vals = np.array([item[2][crit_key] for item in sessions], dtype=np.float64)
    med = float(np.median(vals))
    return min(sessions, key=lambda item: abs(float(item[2][crit_key]) - med))


def run_experiment(
    num_seeds_per_profile: int = 20,
    results_dir: Path | None = None,
) -> dict[str, Any]:
    """Exécute l'expérience 2 sur cohorte unifiée appariée (pure-θ) et génère CSV/JSON/PNG."""
    out_dir = Path(results_dir) if results_dir is not None else ROOT_DIR / "results"
    out_dir.mkdir(parents=True, exist_ok=True)

    profiles = get_clinical_profiles()
    pure_theta_ok = assert_pure_theta_profiles(profiles)
    unified_sched = build_unified_clinical_schedule()
    seeds = [1000 + i for i in range(num_seeds_per_profile)]

    unified_metrics: dict[str, list[dict[str, Any]]] = {k: [] for k in profiles}
    unified_sessions: dict[str, list[tuple[int, SessionResult, dict[str, Any]]]] = {
        k: [] for k in profiles
    }

    traj_rows: list[dict[str, Any]] = []
    cohort_rows: list[dict[str, Any]] = []
    median_rep_seeds: dict[str, int] = {}

    for pkey, pinfo in profiles.items():
        params = pinfo["params"]
        for seed in seeds:
            env_u = NonStationaryBanditEnv(schedule=unified_sched, seed=seed)
            agent_u = ActiveInferenceCartograffectAgent(params=params, seed=seed + 1000)
            res_u = agent_u.run_session(env_u)
            met_u = _extract_session_metrics(res_u)
            unified_metrics[pkey].append(met_u)
            unified_sessions[pkey].append((seed, res_u, met_u))
            traj_rows.extend(_session_to_rows("unified", pkey, seed, res_u))

        rep_seed, rep_res, _ = _select_median_representative_session(pkey, unified_sessions[pkey])
        median_rep_seeds[pkey] = int(rep_seed)
        traj_rows.extend(_session_to_rows("median_representative", pkey, rep_seed, rep_res))

    summary_unified: dict[str, Any] = {}
    summary_attractors: dict[str, Any] = {}
    for pkey in profiles:
        um = unified_metrics[pkey]

        def _agg(ms: list[dict[str, Any]], key: str) -> dict[str, float]:
            vals = np.array([m[key] for m in ms], dtype=np.float64)
            return {
                "mean": float(np.mean(vals)),
                "sd": float(np.std(vals, ddof=1) if len(vals) > 1 else 0.0),
                "median": float(np.median(vals)),
                "iqr": float(np.percentile(vals, 75) - np.percentile(vals, 25)),
            }

        u_agg = {
            "mean_z_stress": _agg(um, "mean_z_stress"),
            "mean_z_remission": _agg(um, "mean_z_remission"),
            "end_z_remission_final": _agg(um, "end_z_remission_final"),
            "pdv_fraction_remission": _agg(um, "pdv_fraction_remission"),
            "p_homeostasis_remission": _agg(um, "p_homeostasis_remission"),
            "quadrant_neg_neg_loss": _agg(um, "quadrant_neg_neg_stress"),
            "quadrant_neg_pos_threat": _agg(um, "quadrant_neg_pos_threat"),
            "x_zero_lock_fraction": _agg(um, "x_zero_lock_fraction"),
            "x_zero_lock_stress": _agg(um, "x_zero_lock_stress"),
            "oscillation_rate_neg_pos": _agg(um, "oscillation_rate_neg_pos"),
        }
        attr_agg = {
            "mean_z_remission": u_agg["mean_z_remission"],
            "pdv_fraction_remission": u_agg["pdv_fraction_remission"],
            "quadrant_neg_neg_loss": u_agg["quadrant_neg_neg_loss"],
            "quadrant_neg_pos_threat": u_agg["quadrant_neg_pos_threat"],
            "x_zero_lock_stress": u_agg["x_zero_lock_stress"],
            "seeds_reaching_z5_neg_neg": int(sum(1 for m in um if m["z5_neg_neg_visits"] > 0)),
            "seeds_reaching_desespoir": int(sum(1 for m in um if m["desespoir_visits"] > 0)),
            "seeds_reaching_z5_neg_pos": int(sum(1 for m in um if m["z5_neg_pos_visits"] > 0)),
            "seeds_reaching_z6_neg_pos": int(sum(1 for m in um if m["z6_neg_pos_visits"] > 0)),
            "seeds_reaching_tourment": int(sum(1 for m in um if m["tourment_visits"] > 0)),
            "total_infini_visits": int(sum(m["infini_visits"] for m in um)),
            "median_representative_seed": median_rep_seeds[pkey],
            "top_labels_pooled": Counter(
                lb for m in um for lb in m["labels"] if lb != "Point de Veille"
            ).most_common(8),
        }
        summary_unified[pkey] = u_agg
        summary_attractors[pkey] = attr_agg

        cohort_rows.append(
            {
                "profile": pkey,
                "display_name": profiles[pkey]["display_name"],
                "num_seeds": num_seeds_per_profile,
                "median_rep_seed": median_rep_seeds[pkey],
                "unified_z_rem_mean": u_agg["mean_z_remission"]["mean"],
                "unified_z_rem_median": u_agg["mean_z_remission"]["median"],
                "unified_end_z_rem_mean": u_agg["end_z_remission_final"]["mean"],
                "unified_pdv_rem_mean": u_agg["pdv_fraction_remission"]["mean"],
                "unified_neg_neg_loss_mean": u_agg["quadrant_neg_neg_loss"]["mean"],
                "unified_neg_pos_threat_mean": u_agg["quadrant_neg_pos_threat"]["mean"],
                "unified_x_zero_lock_mean": u_agg["x_zero_lock_fraction"]["mean"],
                "unified_x_zero_lock_stress_mean": u_agg["x_zero_lock_stress"]["mean"],
                "unified_osc_neg_pos_mean": u_agg["oscillation_rate_neg_pos"]["mean"],
                "z5_neg_neg_seeds": attr_agg["seeds_reaching_z5_neg_neg"],
                "z5_neg_pos_seeds": attr_agg["seeds_reaching_z5_neg_pos"],
                "total_infini_visits": attr_agg["total_infini_visits"],
            }
        )

    def _paired_test(a_key: str, b_key: str, metric: str) -> dict[str, Any]:
        va = np.array([m[metric] for m in unified_metrics[a_key]], dtype=np.float64)
        vb = np.array([m[metric] for m in unified_metrics[b_key]], dtype=np.float64)
        return _paired_wilcoxon_two_sided(va, vb)

    raw_tests = {
        "inhibited_vs_normo_z_remission": _paired_test("b_inhibited", "a_normothymic", "mean_z_remission"),
        "inhibited_vs_normo_pdv_remission": _paired_test("a_normothymic", "b_inhibited", "pdv_fraction_remission"),
        "inhibited_vs_normo_neg_neg_loss": _paired_test("b_inhibited", "a_normothymic", "quadrant_neg_neg_stress"),
        "agitated_vs_normo_neg_pos_threat": _paired_test("c_agitated", "a_normothymic", "quadrant_neg_pos_threat"),
        "agitated_vs_inhibited_neg_pos_threat": _paired_test("c_agitated", "b_inhibited", "quadrant_neg_pos_threat"),
        "agitated_vs_normo_oscillation": _paired_test("c_agitated", "a_normothymic", "oscillation_rate_neg_pos"),
        "rigid_vs_normo_x_zero_lock": _paired_test("d_rigid_bias", "a_normothymic", "x_zero_lock_fraction"),
        "rigid_vs_normo_x_zero_stress": _paired_test("d_rigid_bias", "a_normothymic", "x_zero_lock_stress"),
    }
    hypothesis_tests = _apply_holm_bonferroni(raw_tests)

    traj_df = pd.DataFrame(traj_rows)
    traj_df.to_csv(out_dir / "exp02_trajectories.csv", index=False, encoding="utf-8")
    pd.DataFrame(cohort_rows).to_csv(
        out_dir / "exp02_phenotype_metrics.csv", index=False, encoding="utf-8"
    )

    fig_path = _render_clinical_figure(
        out_dir=out_dir,
        profiles=profiles,
        traj_df=traj_df,
        unified_metrics=unified_metrics,
        median_rep_seeds=median_rep_seeds,
        hypothesis_tests=hypothesis_tests,
    )

    try:
        rel_fig = fig_path.resolve().relative_to(ROOT_DIR.resolve()).as_posix()
    except ValueError:
        rel_fig = fig_path.name

    report = {
        "num_seeds_per_profile": num_seeds_per_profile,
        "pure_theta_only": pure_theta_ok,
        "theta_profiles": {k: v["params"].theta_dict() for k, v in profiles.items()},
        "unified_cohort": summary_unified,
        "clinical_probes": summary_attractors,
        "hypothesis_tests": hypothesis_tests,
        "figure_path": rel_fig,
    }
    (out_dir / "exp02_phenotypes.json").write_text(
        json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    return report


def _render_clinical_figure(
    out_dir: Path,
    profiles: dict[str, dict[str, Any]],
    traj_df: pd.DataFrame,
    unified_metrics: dict[str, list[dict[str, Any]]],
    median_rep_seeds: dict[str, int],
    hypothesis_tests: dict[str, Any],
) -> Path:
    sns.set_theme(style="whitegrid", context="paper")
    fig = plt.figure(figsize=(16.0, 10.6), dpi=300)
    gs = fig.add_gridspec(2, 4, height_ratios=[1.15, 1.0], hspace=0.40, wspace=0.30, bottom=0.10)

    n_seeds = len(next(iter(unified_metrics.values())))
    all_u_df = traj_df[traj_df["cohort"] == "unified"]
    rep_df = traj_df[traj_df["cohort"] == "median_representative"]
    panel_tags = ["A", "B", "C", "D"]
    cmap = plt.get_cmap("viridis")

    sc = None
    for idx, (pkey, pinfo) in enumerate(profiles.items()):
        ax = fig.add_subplot(gs[0, idx])
        sub_all = all_u_df[all_u_df["profile"] == pkey]
        sub_rep = rep_df[rep_df["profile"] == pkey]

        for radius, ls, alpha_r in [(2, ":", 0.35), (8, "--", 0.35), (10, "-.", 0.25)]:
            poly_x = [radius, 0, -radius, 0, radius]
            poly_y = [0, radius, 0, -radius, 0]
            ax.plot(poly_x, poly_y, linestyle=ls, color="#666666", lw=0.9, alpha=alpha_r)

        ax.axhline(0, color="#999999", lw=0.8, alpha=0.6)
        ax.axvline(0, color="#999999", lw=0.8, alpha=0.6)

        # Densité agrégée sur les N graines (fond semi-transparent)
        rng_j = np.random.default_rng(700 + idx)
        ax_all_x = sub_all["x"].to_numpy(dtype=np.float64) + rng_j.normal(0.0, 0.18, size=len(sub_all))
        ax_all_y = sub_all["y"].to_numpy(dtype=np.float64) + rng_j.normal(0.0, 0.18, size=len(sub_all))
        ax.scatter(
            ax_all_x,
            ax_all_y,
            c=pinfo["color"],
            s=10,
            alpha=0.10,
            edgecolors="none",
            zorder=2,
        )

        # Trajectoire de la graine médiane représentative sur le protocole unifié
        xs = sub_rep["x"].to_numpy(dtype=np.float64)
        ys = sub_rep["y"].to_numpy(dtype=np.float64)
        zs = sub_rep["z"].to_numpy(dtype=np.float64)
        jx = xs + rng_j.normal(0.0, 0.12, size=xs.shape)
        jy = ys + rng_j.normal(0.0, 0.12, size=ys.shape)
        ax.plot(jx, jy, color=pinfo["color"], lw=0.95, alpha=0.48, zorder=3)
        sc = ax.scatter(
            jx,
            jy,
            c=zs,
            cmap=cmap,
            vmin=0,
            vmax=7,
            s=30,
            edgecolors="black",
            linewidths=0.3,
            alpha=0.90,
            zorder=4,
        )
        ax.scatter([0], [0], marker="*", s=130, color="gold", edgecolors="black", zorder=6)

        if pkey == "a_normothymic":
            ax.text(0.8, -9.2, r"Retour rapide $\mathrm{PdV}$ (0,0,0)", fontsize=7.5, color="#146c50", fontweight="bold")
        elif pkey == "b_inhibited":
            ax.text(-9.5, -9.2, r"Ancrage $(-X,-Y)$ & rém. lente", fontsize=7.5, color="#1f4e78", fontweight="bold")
        elif pkey == "c_agitated":
            ax.text(-9.5, 8.8, r"Dominance ergotropique $(-X,+Y)$", fontsize=7.5, color="#9e3d00", fontweight="bold")
        elif pkey == "d_rigid_bias":
            ax.axvspan(-0.7, 0.7, color="#7570b3", alpha=0.14)
            ax.text(0.9, -9.2, "Axe $X=0$ verrouillé", fontsize=7.5, color="#4a4482", fontweight="bold")

        ax.set_xlim(-10.5, 10.5)
        ax.set_ylim(-10.5, 10.5)
        ax.set_xlabel("Axe épistémique $X$")
        if idx == 0:
            ax.set_ylabel("Axe pragmatique $Y$")
        ax.set_title(
            f"{panel_tags[idx]}. {pinfo['short_name']}\n"
            f"(densité $N={n_seeds}$ + graine médiane #{median_rep_seeds[pkey]})",
            fontsize=9.6,
            fontweight="bold",
        )

    assert sc is not None
    cbar = fig.colorbar(sc, ax=fig.axes[:4], fraction=0.015, pad=0.02)
    cbar.set_label("Strate $Z$")

    # E. Cinétique moyenne E[Z_t] +/- IC95% sur le protocole unifié (260 essais)
    ax_e = fig.add_subplot(gs[1, 0:2])
    trials = np.arange(260)
    for x0, x1, lbl, col in [
        (0, 20, "Base", "#f0f0f0"),
        (20, 90, r"Perte ($d_{\mathrm{obj}}=3$)", "#fde0dd"),
        (90, 140, "Rémission 1", "#edf8e9"),
        (140, 210, r"Menace ($d_{\mathrm{obj}}=4$)", "#fff7bc"),
        (210, 260, "Rémission 2", "#edf8e9"),
    ]:
        ax_e.axvspan(x0, x1, color=col, alpha=0.55, zorder=0)
        ax_e.text(0.5 * (x0 + x1), 7.45, lbl, ha="center", va="top", fontsize=7.8, color="#333333")

    for pkey, pinfo in profiles.items():
        z_mat = np.vstack([m["exp_z"] for m in unified_metrics[pkey]]).astype(np.float64)
        mean_z = z_mat.mean(axis=0)
        ci95 = (
            1.96 * z_mat.std(axis=0, ddof=1) / math.sqrt(z_mat.shape[0])
            if z_mat.shape[0] > 1
            else np.zeros_like(mean_z)
        )
        ax_e.plot(trials, mean_z, color=pinfo["color"], lw=2.0, label=pinfo["short_name"])
        ax_e.fill_between(trials, mean_z - ci95, mean_z + ci95, color=pinfo["color"], alpha=0.18)

    ax_e.set_ylim(-0.2, 7.75)
    ax_e.set_xlim(0, 259)
    ax_e.set_xlabel("Essai $t$ (protocole unifié à 5 blocs)")
    ax_e.set_ylabel("Profondeur allostatique $E[Z_t]$ (moy. $\\pm$ IC95%)")
    ax_e.set_title(
        f"E. Cinétique de profondeur $E[Z_t]$ et persistance ($N={n_seeds}$ graines appariées/profil)",
        fontsize=10.2,
        fontweight="bold",
    )

    # F. Boxplots + stripplots comparatifs des métriques clés annotés par p_holm
    ax_f = fig.add_subplot(gs[1, 2:4])
    metric_specs = [
        ("pdv_fraction_remission", "Retour PdV\n(rémission)"),
        ("quadrant_neg_neg_stress", "Quadrant $(-X,-Y)$\n(perte)"),
        ("quadrant_neg_pos_threat", "Quadrant $(-X,+Y)$\n(menace)"),
        ("x_zero_lock_stress", "Verrou $X=0$\n(stresseurs)"),
    ]
    box_rows: list[dict[str, Any]] = []
    for pkey, pinfo in profiles.items():
        for m_key, m_lbl in metric_specs:
            for met in unified_metrics[pkey]:
                box_rows.append(
                    {
                        "Métrique": m_lbl,
                        "Profil": pinfo["short_name"],
                        "Proportion": float(met[m_key]),
                    }
                )
    box_df = pd.DataFrame(box_rows)
    palette = {pinfo["short_name"]: pinfo["color"] for pinfo in profiles.values()}
    sns.boxplot(
        data=box_df,
        x="Métrique",
        y="Proportion",
        hue="Profil",
        palette=palette,
        width=0.72,
        fliersize=2.5,
        ax=ax_f,
    )
    if ax_f.get_legend() is not None:
        ax_f.get_legend().remove()

    ax_f.set_ylim(-0.02, 1.08)
    ax_f.set_xlabel("")
    ax_f.set_ylabel("Proportion d'essais")
    p_rem = hypothesis_tests["inhibited_vs_normo_z_remission"]["p_holm_str"]
    p_thr = hypothesis_tests["agitated_vs_inhibited_neg_pos_threat"]["p_holm_str"]
    p_rig = hypothesis_tests["rigid_vs_normo_x_zero_stress"]["p_holm_str"]
    ax_f.set_title(
        f"F. Dissociation pure-$\\theta$ ($p_{{\\mathrm{{Holm}}}}$ : "
        f"rém.={p_rem}, men.={p_thr}, $X=0$={p_rig})",
        fontsize=9.6,
        fontweight="bold",
    )
    ax_f.tick_params(axis="x", labelsize=8.5)

    handles, labels = ax_e.get_legend_handles_labels()
    fig.legend(
        handles,
        labels,
        loc="lower center",
        ncol=4,
        bbox_to_anchor=(0.5, 0.015),
        fontsize=9.2,
        frameon=True,
    )

    fig.suptitle(
        "Expérience 2 — Validation pure-θ des 4 phénotypes CARTOGRAFFECT (protocole unifié)",
        fontsize=13,
        fontweight="bold",
        y=0.985,
    )
    fig_path = out_dir / "fig2_clinical_phenotypes.png"
    fig.savefig(fig_path, dpi=300, bbox_inches="tight")
    plt.close(fig)
    return fig_path


def main() -> None:
    report = run_experiment(num_seeds_per_profile=20)
    print(f"pure_theta_only: {report['pure_theta_only']}")
    print("Unified cohort means:")
    for pkey, metrics in report["unified_cohort"].items():
        print(
            f"  {pkey:14s}: Z_rem={metrics['mean_z_remission']['mean']:.2f} "
            f"endZ_rem={metrics['end_z_remission_final']['mean']:.2f} "
            f"PdV_rem={metrics['pdv_fraction_remission']['mean']:.2f} "
            f"(-,-)L={metrics['quadrant_neg_neg_loss']['mean']:.2f} "
            f"(-,+)T={metrics['quadrant_neg_pos_threat']['mean']:.2f} "
            f"X0_str={metrics['x_zero_lock_stress']['mean']:.2f}"
        )
    print("Attractors on unified protocol:")
    n_s = report["num_seeds_per_profile"]
    for pkey, metrics in report["clinical_probes"].items():
        print(
            f"  {pkey:14s}: Z5(-,-)={metrics['seeds_reaching_z5_neg_neg']}/{n_s} "
            f"Z5(-,+)={metrics['seeds_reaching_z5_neg_pos']}/{n_s} "
            f"Infini={metrics['total_infini_visits']} "
            f"med_seed={metrics['median_representative_seed']}"
        )
    print("Hypothesis tests (Wilcoxon apparié bilatéral + Holm-Bonferroni):")
    print(json.dumps(report["hypothesis_tests"], indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
