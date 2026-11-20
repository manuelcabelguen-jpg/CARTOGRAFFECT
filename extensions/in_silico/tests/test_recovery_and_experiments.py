"""Tests unitaires et d'intégration pour `recovery.py` et les prédictions CARTOGRAFFECT."""

from __future__ import annotations

import importlib.util
import math
from pathlib import Path

import numpy as np
import pytest

from cartograffect_sim import (
    MODEL_NAMES,
    MODEL_PARAM_COUNTS,
    THETA_NAMES,
    AffectiveControlAction,
    AgentParameters,
    BanditAction,
    BlockSpec,
    CueSignal,
    batch_invert_svi,
    build_recovery_schedule,
    build_transition_tensor_B,
    compute_protected_exceedance_probability,
    compute_sensory_calm_sequence,
    compute_waic_and_bic,
    get_point_by_state_index,
    invert_dataset_nuts,
    invert_dataset_svi,
    sample_true_parameters,
    simulate_dataset_for_model,
)


def _load_mod(name: str, rel: str):
    root = Path(__file__).resolve().parents[1]
    spec = importlib.util.spec_from_file_location(name, root / rel)
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_recovery_schedule_and_parameter_sampling() -> None:
    sched = build_recovery_schedule(280)
    assert sum(b.num_trials for b in sched) == 280
    assert any(b.is_remission for b in sched)
    assert {b.d_obj for b in sched if not b.is_remission} == {2, 3, 4}

    thetas = sample_true_parameters(64, seed=123)
    assert len(thetas) == 64
    for th in thetas:
        assert set(th.keys()) == set(THETA_NAMES)
        assert th["beta_X"] > th["beta_Y"]
        assert 0.0 < th["lambda"] < 1.0


def test_closed_loop_simulation_all_four_models_and_probe_clarification() -> None:
    params = sample_true_parameters(1, seed=7)[0]
    for model_name in MODEL_NAMES:
        ds = simulate_dataset_for_model(model_name, params, num_trials=140, seed=19)
        assert ds.cues.shape == (140,)
        assert ds.actions.shape == (140,)
        assert ds.obs_calm.shape == (140,)
        assert ds.filter_a.shape == (140,)
        assert np.all(np.isfinite(ds.ema_x))
        assert np.all(np.isfinite(ds.ema_y))
        assert np.all(np.isin(ds.actions, [0, 1, 2]))
        assert np.all(np.isin(ds.outcomes, [0, 1, 2]))
        assert np.allclose(ds.ema_x[ds.filter_a == 0.0], 0.0)
        assert np.allclose(ds.ema_y[ds.filter_c == 0.0], 0.0)
        # Vérifie que RecoveryDataset ne fuit pas is_remission ni d_obj vers JAX
        jdict = ds.to_jax_dict()
        assert "is_remission" not in jdict and "d_obj" not in jdict

    # PROBE_CUE doit réellement clarifier cue_{t+1} sur NonStationaryBanditEnv en boucle fermée
    ambig_sched = (
        BlockSpec(0, "ambig", 240, p_ctrl=0.80, v_rule=0.35, cue_clarity=0.10, d_obj=2),
    )
    probe_params = {
        "tau_A": 0.25, "tau_C": 0.25, "lambda": 0.5,
        "alpha_0": 1.0, "gamma_alpha": 0.4, "eta_diss": 0.25,
        "beta_X": 3.2, "beta_Y": 0.8,
    }
    ds_amb = simulate_dataset_for_model("M1_CARTOGRAFFECT", probe_params, schedule=ambig_sched, seed=31)
    post_probe = [t + 1 for t in range(len(ds_amb.actions) - 1) if ds_amb.actions[t] == int(BanditAction.PROBE_CUE)]
    post_choice = [t + 1 for t in range(len(ds_amb.actions) - 1) if ds_amb.actions[t] != int(BanditAction.PROBE_CUE)]
    assert len(post_probe) >= 10 and len(post_choice) >= 10
    clarity_after_probe = float(np.mean(ds_amb.cues[post_probe] != int(CueSignal.AMBIGUOUS)))
    clarity_after_choice = float(np.mean(ds_amb.cues[post_choice] != int(CueSignal.AMBIGUOUS)))
    assert clarity_after_probe > clarity_after_choice + 0.30


def test_sensory_calm_sequence_requires_two_non_probe_neutrals() -> None:
    acts = np.array([0, 2, 0, 0, 2, 0, 1], dtype=np.int32)
    outs = np.array([2, 0, 0, 0, 0, 0, 1], dtype=np.int32)
    calm = compute_sensory_calm_sequence(acts, outs)
    # t=0 NEG -> 0; t=1 PROBE NEUT -> 0 (streak=0); t=2 CHOICE NEUT -> 0 (streak=1);
    # t=3 CHOICE NEUT -> 1 (streak=2); t=4 PROBE NEUT -> 1; t=5 CHOICE NEUT -> 1; t=6 POS -> 0
    assert calm.tolist() == [0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0]


def test_waic_bic_uses_max_ll_and_m4_prior_includes_true_sigma() -> None:
    assert MODEL_PARAM_COUNTS["M4_ScalarValence_1D"] == 5

    # Vérification analytique que BIC utilise max_ll et n_obs explicite
    ll_draws = np.array(
        [
            [-2.0, -2.0, -2.0],  # total = -6.0
            [-1.0, -1.0, -1.0],  # total = -3.0 (max)
        ],
        dtype=np.float64,
    )
    waic, bic, p_waic = compute_waic_and_bic(ll_draws, num_params=5, n_obs=100)
    expected_bic = -2.0 * (-3.0) + 5 * math.log(100)
    assert math.isclose(bic, expected_bic, abs_tol=1e-12)
    assert np.isfinite(waic) and p_waic >= 0.0

    # Matrices de log-vraisemblance favorisant nettement le modèle 2
    log_ev = np.tile(np.array([-320.0, -315.0, -250.0, -340.0]), (25, 1))
    bms = compute_protected_exceedance_probability(log_ev, seed=11)
    assert np.isclose(np.sum(bms["pxp"]), 1.0, atol=1e-6)
    assert 0.0 <= bms["bor"] <= 1.0
    assert bms["pxp"][2] > 0.98

    # Vérifier le support effectif du prior sigma_v de M4 (inclut sigma_ema = 0.14)
    import numpyro.handlers as handlers
    import jax
    ds_m4 = simulate_dataset_for_model(
        "M4_ScalarValence_1D",
        {"alpha_v": 1.0, "tau_v": 0.25, "eta_diss": 0.25, "beta_scalar": 1.2},
        num_trials=40,
        seed=5,
    )
    from cartograffect_sim import build_numpyro_model
    m4_fn = build_numpyro_model("M4_ScalarValence_1D")
    tr = handlers.trace(handlers.seed(m4_fn, jax.random.PRNGKey(0))).get_trace(ds_m4.to_jax_dict())
    sigma_dist = tr["sigma_v"]["fn"]
    assert float(sigma_dist.low) < 0.14 < float(sigma_dist.high)


def test_svi_batch_and_nuts_inference_finite() -> None:
    thetas = sample_true_parameters(2, seed=99)
    datasets = [
        simulate_dataset_for_model("M1_CARTOGRAFFECT", th, num_trials=140, seed=100 + i)
        for i, th in enumerate(thetas)
    ]
    single = invert_dataset_svi(
        "M1_CARTOGRAFFECT",
        datasets[0],
        seed=5,
        num_steps=150,
        num_posterior_samples=40,
    )
    assert set(single["means"].keys()) == set(THETA_NAMES)
    assert all(np.isfinite(v) for v in single["means"].values())
    assert np.isfinite(single["waic"]) and np.isfinite(single["bic"])

    batched = batch_invert_svi(
        "M1_CARTOGRAFFECT",
        datasets,
        seed=5,
        num_steps=150,
        num_posterior_samples=40,
        batch_size=2,
    )
    assert len(batched) == 2
    assert all(np.isfinite(r["waic"]) for r in batched)

    nuts = invert_dataset_nuts(
        datasets[0],
        model_name="M4_ScalarValence_1D",
        seed=5,
        num_warmup=60,
        num_samples=60,
        num_chains=2,
    )
    assert all(np.isfinite(v) and v > 0.9 for v in nuts["rhat"].values())
    assert all(np.isfinite(v) and v > 0.0 for v in nuts["ess"].values())


def test_structural_transition_z2_noncircular_symmetry_and_depth_inertia() -> None:
    params = AgentParameters(lambda_weight=1.0)
    b_mat = build_transition_tensor_B(params)[0]
    pts = get_point_by_state_index()

    z2_axial = [i for i, p in enumerate(pts) if p.z == 2 and (p.x == 0 or p.y == 0) and (p.x, p.y) != (0, 0)]
    z2_diag = [i for i, p in enumerate(pts) if p.z == 2 and abs(p.x) == 1 and abs(p.y) == 1]
    assert len(z2_axial) == 4 and len(z2_diag) == 4

    intra_actions = list(range(AffectiveControlAction.INTRA_JOIE, AffectiveControlAction.INTRA_DEGOUT + 1))
    b_intra = np.mean(b_mat[:, :, intra_actions], axis=2)

    p_stay_axial = float(np.mean([b_intra[i, i] for i in z2_axial]))
    p_stay_diag = float(np.mean([b_intra[i, i] for i in z2_diag]))
    p_ax_to_diag = float(np.mean([np.sum(b_intra[z2_diag, i]) for i in z2_axial]))
    p_diag_to_ax = float(np.mean([np.sum(b_intra[z2_axial, j]) for j in z2_diag]))

    # Preuve de non-circularité : B(Z=2) n'introduit aucun biais a priori axial vs diagonal
    assert abs(p_stay_axial - p_stay_diag) < 1e-12
    assert abs(p_ax_to_diag - p_diag_to_ax) < 1e-12

    assert params.dirichlet_concentration(5) > params.dirichlet_concentration(4) > params.dirichlet_concentration(2)


def test_exp02_pure_theta_and_experiments_smoke(tmp_path) -> None:
    exp01 = _load_mod("exp01_smoke", "experiments/01_falsifiable_predictions.py")
    exp02 = _load_mod("exp02_smoke", "experiments/02_clinical_phenotypes.py")
    runner = _load_mod("runner_smoke", "run_all_validations.py")

    # Vérification pure-θ sur les 4 phénotypes
    assert exp02.assert_pure_theta_profiles(exp02.get_clinical_profiles()) is True

    r1 = exp01.run_experiment(num_trajectories=15, results_dir=tmp_path)
    r2 = exp02.run_experiment(num_seeds_per_profile=2, results_dir=tmp_path)

    assert (tmp_path / "exp01_statistics.json").exists()
    assert (tmp_path / "fig1_falsifiable_predictions.png").exists()
    assert (tmp_path / "exp02_phenotypes.json").exists()
    assert (tmp_path / "fig2_clinical_phenotypes.png").exists()
    assert r2["pure_theta_only"] is True

    dummy_report = {
        "generated_at_utc": "2026-11-19T00:00:00+00:00",
        "total_runtime_seconds": 1.0,
        "timings_seconds": {"exp01": 0.3, "exp02": 0.4, "exp03": 0.3},
        "configuration": {
            "num_mc_trajectories": 15,
            "num_clinical_seeds": 2,
            "num_param_datasets": 10,
            "num_model_datasets_per_model": 5,
            "num_recovery_trials": 140,
        },
        "all_criteria_passed": True,
        "criteria": {"smoke_ok": True},
        "exp01_falsifiable_predictions": r1,
        "exp02_clinical_phenotypes": r2,
        "exp03_parameter_and_model_recovery": {
            "parameter_recovery": {
                "num_datasets": 10,
                "num_trials": 140,
                "pearson_r": {k: 0.9 for k in THETA_NAMES},
                "rmse": {k: 0.05 for k in THETA_NAMES},
                "coverage_95": {k: 0.92 for k in THETA_NAMES},
                "min_coverage_95": 0.92,
                "min_diagonal_r": 0.9,
                "target_r_ge_080_met": True,
                "max_abs_offdiag_r": 0.12,
                "max_abs_error_corr": 0.25,
                "nuts_checks": [{"max_rhat": 1.01, "min_ess": 450.0}],
            },
            "model_recovery": {
                "model_names": list(MODEL_NAMES),
                "num_datasets_per_model": 5,
                "pxp_matrix": np.eye(4).tolist(),
                "pxp_waic": np.eye(4).tolist(),
                "waic_confusion": np.eye(4).tolist(),
                "bic_confusion": np.eye(4).tolist(),
                "min_diagonal_pxp": 1.0,
                "target_pxp_gt_095_met": True,
            },
        },
    }
    md_out = tmp_path / "validation_summary.md"
    runner._write_markdown_summary(md_out, dummy_report)
    assert md_out.exists()
    md_text = md_out.read_text(encoding="utf-8")
    assert "max R-hat = 1.010" in md_text
    assert "0.00e+00" not in md_text
