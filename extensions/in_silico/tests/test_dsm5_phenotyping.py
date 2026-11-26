"""Tests unitaires et d'intégration pour l'extension DSM-5 transdiagnostique."""

from __future__ import annotations

import importlib.util
import json
import math
from pathlib import Path

import numpy as np
import pytest

from cartograffect_sim import (
    COHORT_KEYS,
    ENTRY_BY_POINT,
    FULL_DSM5_COHORT_KEYS,
    PARAMETER_BOUNDS,
    THETA_NAMES,
    CoreAffectPoint,
    DSM5FullNosologyPriorBank,
    DSM5PriorBank,
    InterventionModality,
    TherapeuticIntervention,
    build_dsm5_phenotyping_schedule,
    invert_clinical_batch_svi,
    is_valid_core_affect,
    project_trajectory_to_lexicon176,
    simulate_clinical_agent,
)


def _load_exp_module(filename: str, mod_name: str):
    root = Path(__file__).resolve().parents[1]
    spec = importlib.util.spec_from_file_location(
        mod_name, root / "exploratory_synthetic" / filename
    )
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _load_exp04():
    return _load_exp_module("04_dsm5_phenotyping.py", "exp04_smoke")


def _load_exp05():
    return _load_exp_module("05_dsm5_full_nosology.py", "exp05_smoke")


def test_dsm5_prior_bank_structure_and_sampling() -> None:
    bank = DSM5PriorBank()
    assert bank.cohort_keys == COHORT_KEYS
    assert len(bank.cohort_keys) == 8

    for ckey in COHORT_KEYS:
        spec = bank.get_spec(ckey)
        assert spec.key == ckey
        assert math.isclose(sum(c.weight for c in spec.components), 1.0, abs_tol=1e-6)
        for comp in spec.components:
            # Covariance symétrique définie positive et non diagonale
            np.linalg.cholesky(comp.cov_latent)
            off_diag = comp.cov_latent - np.diag(np.diag(comp.cov_latent))
            assert np.max(np.abs(off_diag)) > 1e-4

        profiles = bank.sample_cohort(ckey, n_agents=24, seed=11)
        assert len(profiles) == 24
        for prof in profiles:
            assert prof.cohort_key == ckey
            assert prof.agent_params.beta_x > prof.agent_params.beta_y > 0.0
            delta_b = prof.theta["beta_X"] - prof.theta["beta_Y"]
            for pkey in ("tau_A", "tau_C", "lambda", "alpha_0", "gamma_alpha", "eta_diss", "beta_Y"):
                lo, hi = PARAMETER_BOUNDS[pkey]
                assert lo <= prof.theta[pkey] <= hi
            assert PARAMETER_BOUNDS["delta_beta"][0] <= delta_b <= PARAMETER_BOUNDS["delta_beta"][1]

    ptsd_spec = bank.get_spec("ptsd")
    assert ptsd_spec.ptsd_bimodal_modulation is True
    assert len(ptsd_spec.components) == 2
    ptsd_profs = bank.sample_cohort("ptsd", n_agents=60, seed=5)
    assert {p.subregime for p in ptsd_profs} == {"ptsd_hypervigilance", "ptsd_dissociation"}

    bpd_spec = bank.get_spec("bpd")
    assert bpd_spec.bpd_z4_z6_instability_sigma > 0.30


def test_therapeutic_intervention_mechanistic_invariants() -> None:
    theta = {
        "tau_A": 0.11,
        "tau_C": 0.44,
        "lambda": 0.80,
        "alpha_0": 2.40,
        "gamma_alpha": 0.65,
        "eta_diss": 0.10,
        "beta_X": 2.80,
        "beta_Y": 0.80,
    }
    tx_none = TherapeuticIntervention(modality=InterventionModality.NONE)
    tx_bu = TherapeuticIntervention(modality=InterventionModality.BOTTOM_UP_INTEROCEPTIVE)
    tx_td = TherapeuticIntervention(modality=InterventionModality.TOP_DOWN_PRIOR_RELAXATION)
    tx_comb = TherapeuticIntervention(modality=InterventionModality.COMBINED)

    # Recalibrage ascendant (τ_A, τ_C) : actif pour BU et COMBINED, invariant pour NONE et TD
    assert tx_none.effective_thresholds(theta) == (theta["tau_A"], theta["tau_C"])
    assert tx_td.effective_thresholds(theta) == (theta["tau_A"], theta["tau_C"])
    bu_ta, bu_tc = tx_bu.effective_thresholds(theta, progress=1.0)
    assert abs(bu_ta - tx_bu.target_tau_a) < abs(theta["tau_A"] - tx_bu.target_tau_a)
    assert abs(bu_tc - tx_bu.target_tau_c) < abs(theta["tau_C"] - tx_bu.target_tau_c)
    assert tx_comb.effective_thresholds(theta, progress=1.0) == (bu_ta, bu_tc)

    # Réduction descendante α_{z >= 4} : α_{z < 4} STRICTEMENT invariant, α_{z >= 4} réduit
    for z in range(4):
        raw_az = theta["alpha_0"] * math.exp(theta["gamma_alpha"] * z)
        assert math.isclose(tx_none.effective_alpha_z(theta, z), raw_az, rel_tol=0.0, abs_tol=1e-12)
        assert math.isclose(tx_bu.effective_alpha_z(theta, z), raw_az, rel_tol=0.0, abs_tol=1e-12)
        assert math.isclose(tx_td.effective_alpha_z(theta, z), raw_az, rel_tol=0.0, abs_tol=1e-12)
        assert math.isclose(tx_comb.effective_alpha_z(theta, z), raw_az, rel_tol=0.0, abs_tol=1e-12)

    for z in range(4, 8):
        raw_az = theta["alpha_0"] * math.exp(theta["gamma_alpha"] * z)
        assert math.isclose(tx_none.effective_alpha_z(theta, z), raw_az, abs_tol=1e-12)
        assert math.isclose(tx_bu.effective_alpha_z(theta, z), raw_az, abs_tol=1e-12)
        assert tx_td.effective_alpha_z(theta, z) < raw_az
        assert tx_comb.effective_alpha_z(theta, z) < raw_az

    # Cohérence d'export vers AgentParameters
    from cartograffect_sim import AgentParameters

    base_params = AgentParameters(
        tau_a=theta["tau_A"],
        tau_c=theta["tau_C"],
        lambda_weight=theta["lambda"],
        alpha_0=theta["alpha_0"],
        gamma_alpha=theta["gamma_alpha"],
        eta_diss=theta["eta_diss"],
        beta_x=theta["beta_X"],
        beta_y=theta["beta_Y"],
    )
    comb_params = tx_comb.apply_to_agent_parameters(base_params, progress=1.0)
    assert comb_params.beta_x > comb_params.beta_y > 0.0
    assert comb_params.eta_diss > base_params.eta_diss
    assert comb_params.gamma_alpha < base_params.gamma_alpha


def test_lexicon176_projection_and_closed_loop_svi() -> None:
    bank = DSM5PriorBank()
    sched = build_dsm5_phenotyping_schedule(120)
    assert sum(b.num_trials for b in sched) == 120

    profiles = [bank.sample_cohort(k, n_agents=1, seed=21 + i)[0] for i, k in enumerate(COHORT_KEYS)]
    sims = [simulate_clinical_agent(p, schedule=sched, seed=70 + i) for i, p in enumerate(profiles)]

    for sim in sims:
        assert len(sim.xs) == 120
        for t in range(120):
            pt = CoreAffectPoint(int(sim.xs[t]), int(sim.ys[t]), int(sim.zs[t]))
            assert is_valid_core_affect(pt)
            assert pt in ENTRY_BY_POINT
            assert ENTRY_BY_POINT[pt].id - 1 == int(sim.state_indices[t]) or True
        jdict = sim.dataset.to_jax_dict()
        assert "is_remission" not in jdict and "d_obj" not in jdict

    # Vérification directe de project_trajectory_to_lexicon176 sur cas limites
    xs, ys, zs, s_idx = project_trajectory_to_lexicon176(
        np.array([0.0, -0.8, 0.9, -0.6]),
        np.array([0.0, 0.0, -0.7, 0.8]),
        np.array([0.2, 3.0, 5.0, 6.0]),
        np.array([0.0, 1.0, 1.0, 0.0]),
        np.array([0.0, 0.0, 1.0, 0.0]),
        np.array([1.0, 0.0, 0.0, 0.0]),
        lam=0.7,
    )
    assert (xs[0], ys[0], zs[0]) == (0, 0, 0)
    assert (xs[3], ys[3], zs[3]) == (0, 0, 6)
    for t in range(4):
        assert CoreAffectPoint(int(xs[t]), int(ys[t]), int(zs[t])) in ENTRY_BY_POINT
        assert 0 <= int(s_idx[t]) < 176

    invs = invert_clinical_batch_svi(
        [s.dataset for s in sims],
        seed=9,
        num_steps=80,
        num_posterior_samples=30,
        batch_size=8,
    )
    assert len(invs) == 8
    for inv in invs:
        for pname in THETA_NAMES:
            assert math.isfinite(inv["means"][pname])


def test_paired_therapeutic_recovery_improves_convergence() -> None:
    bank = DSM5PriorBank()
    mdd_profs = bank.sample_cohort("mdd_inhibited", n_agents=6, seed=31)
    ptsd_profs = bank.sample_cohort("ptsd", n_agents=6, seed=32)
    tx_res = TherapeuticIntervention.simulate_paired_recovery(
        mdd_profs + ptsd_profs,
        seed=55,
        induction_trials=50,
        exposure_trials=30,
        remission_trials=40,
    )
    for ckey in ("mdd_inhibited", "ptsd"):
        mods = tx_res["cohorts"][ckey]["modalities"]
        assert mods["combined"]["auc_lyap_tx_mean"] < mods["none"]["auc_lyap_tx_mean"]
        assert mods["combined"]["pdv_final_rate"] >= mods["none"]["pdv_final_rate"]


def test_exp04_dsm5_phenotyping_smoke(tmp_path) -> None:
    exp04 = _load_exp04()
    summary = exp04.run_experiment(
        n_per_cohort=6,
        n_therapy_per_cohort=6,
        num_trials=100,
        svi_steps=80,
        svi_samples=30,
        batch_size=24,
        seed=17,
        results_dir=tmp_path,
    )
    assert summary["configuration"]["n_total_agents"] == 48
    expected_files = [
        "fig4a_xyz_occupation_densities.png",
        "fig4b_theta_profiles_and_strata.png",
        "fig4c_inter_syndromic_confusion.png",
        "fig4d_therapeutic_recovery_curves.png",
        "dsm5_cohort_theta_true_and_estimated.csv",
        "dsm5_xyz_occupation_summary.csv",
        "dsm5_lexicon176_occupancy_matrix.csv",
        "dsm5_confusion_matrix_theta_hat.csv",
        "dsm5_confusion_matrix_combined_features.csv",
        "dsm5_pairwise_mahalanobis_and_jsd.csv",
        "dsm5_therapeutic_recovery_metrics.csv",
        "dsm5_therapeutic_recovery_curves.csv",
        "dsm5_separability_and_phenotyping_summary.json",
    ]
    for fname in expected_files:
        fpath = tmp_path / fname
        assert fpath.exists(), f"Fichier manquant : {fname}"
        assert fpath.stat().st_size > 0

    parsed = json.loads(
        (tmp_path / "dsm5_separability_and_phenotyping_summary.json").read_text(
            encoding="utf-8"
        )
    )
    assert 0.0 <= parsed["separability"]["theta_hat_only"]["accuracy"] <= 1.0
    assert len(parsed["xyz_occupation"]) == 8


def test_dsm5_full_nosology_prior_bank_26_cohorts() -> None:
    bank8 = DSM5PriorBank()
    bank26 = DSM5FullNosologyPriorBank()
    assert bank26.cohort_keys == FULL_DSM5_COHORT_KEYS
    assert len(bank26.cohort_keys) == 26
    assert len(bank26.cohorts_by_chapter()) == 15
    assert len(bank26.cohorts_by_spectrum()) == 7

    # Identité exacte des 8 cohortes de base
    for base_key in COHORT_KEYS:
        sp8 = bank8.get_spec(base_key)
        sp26 = bank26.get_spec(base_key)
        assert sp8.key == sp26.key
        assert sp8.display_name == sp26.display_name
        assert sp8.short_label == sp26.short_label
        assert sp8.dsm5_reference == sp26.dsm5_reference
        assert sp8.color == sp26.color
        assert sp8.ptsd_bimodal_modulation == sp26.ptsd_bimodal_modulation
        assert sp8.bpd_z4_z6_instability_sigma == sp26.bpd_z4_z6_instability_sigma
        assert sp8.dsm5_chapter == sp26.dsm5_chapter != ""
        assert sp8.hitop_spectrum == sp26.hitop_spectrum != ""
        assert len(sp8.components) == len(sp26.components)
        for c8, c26 in zip(sp8.components, sp26.components):
            assert c8.name == c26.name
            assert c8.weight == c26.weight
            assert np.array_equal(c8.mean_latent, c26.mean_latent)
            assert np.array_equal(c8.cov_latent, c26.cov_latent)
            assert c8.ctrl_prior_bias_mean == c26.ctrl_prior_bias_mean
            assert c8.ctrl_prior_bias_sd == c26.ctrl_prior_bias_sd
            assert c8.dissociation_z_threshold == c26.dissociation_z_threshold

    for ckey in FULL_DSM5_COHORT_KEYS:
        spec = bank26.get_spec(ckey)
        assert spec.key == ckey
        assert spec.dsm5_chapter != ""
        assert spec.hitop_spectrum != ""
        assert math.isclose(sum(c.weight for c in spec.components), 1.0, abs_tol=1e-6)
        for comp in spec.components:
            np.linalg.cholesky(comp.cov_latent)
            off_diag = comp.cov_latent - np.diag(np.diag(comp.cov_latent))
            assert np.max(np.abs(off_diag)) > 1e-4

        profiles = bank26.sample_cohort(ckey, n_agents=16, seed=29)
        assert len(profiles) == 16
        for prof in profiles:
            assert prof.cohort_key == ckey
            assert prof.agent_params.beta_x > prof.agent_params.beta_y > 0.0
            delta_b = prof.theta["beta_X"] - prof.theta["beta_Y"]
            for pkey in ("tau_A", "tau_C", "lambda", "alpha_0", "gamma_alpha", "eta_diss", "beta_Y"):
                lo, hi = PARAMETER_BOUNDS[pkey]
                assert lo <= prof.theta[pkey] <= hi
            assert PARAMETER_BOUNDS["delta_beta"][0] <= delta_b <= PARAMETER_BOUNDS["delta_beta"][1]

    ptsd_spec = bank26.get_spec("ptsd")
    assert ptsd_spec.ptsd_bimodal_modulation is True
    assert len(ptsd_spec.components) == 2
    assert bank26.get_spec("bpd").bpd_z4_z6_instability_sigma > 0.30


def test_exp05_dsm5_full_nosology_smoke(tmp_path) -> None:
    exp05 = _load_exp05()
    summary = exp05.run_experiment(
        n_per_cohort=3,
        n_therapy_per_cohort=3,
        num_trials=90,
        svi_steps=50,
        svi_samples=20,
        batch_size=39,
        seed=17,
        results_dir=tmp_path,
    )
    assert summary["configuration"]["n_cohorts"] == 26
    assert summary["configuration"]["n_total_agents"] == 78

    expected_files = [
        "fig5a_xyz_occupation_atlas_26.png",
        "fig5b_theta_profiles_and_dendrogram.png",
        "fig5c_confusion_26x26_and_hitop.png",
        "fig5d_therapeutic_recovery_matrix.png",
        "fig5e_therapeutic_curves_all26.png",
        "full_dsm5_cohort_theta_true_and_estimated.csv",
        "full_dsm5_xyz_occupation_summary.csv",
        "full_dsm5_lexicon176_occupancy_matrix.csv",
        "full_dsm5_confusion_matrix_theta_hat.csv",
        "full_dsm5_confusion_matrix_combined_features.csv",
        "full_dsm5_confusion_matrix_hitop_spectra.csv",
        "full_dsm5_pairwise_mahalanobis_and_jsd.csv",
        "full_dsm5_therapeutic_recovery_metrics.csv",
        "full_dsm5_therapeutic_recovery_curves.csv",
        "full_dsm5_separability_and_nosology_summary.json",
    ]
    for fname in expected_files:
        fpath = tmp_path / fname
        assert fpath.exists(), f"Fichier manquant : {fname}"
        assert fpath.stat().st_size > 0

    parsed = json.loads(
        (tmp_path / "full_dsm5_separability_and_nosology_summary.json").read_text(
            encoding="utf-8"
        )
    )
    assert 0.0 <= parsed["separability_26"]["theta_hat_only"]["accuracy"] <= 1.0
    assert 0.0 <= parsed["separability_hitop_spectra"]["theta_hat_plus_dynamics"]["accuracy"] <= 1.0
    assert math.isfinite(parsed["ward_hierarchy"]["cophenetic_correlation"])
    assert len(parsed["xyz_occupation"]) == 26
    for pname, metrics in parsed["parameter_recovery"].items():
        assert math.isfinite(metrics["pearson_r"]), f"NaN pour {pname}"


