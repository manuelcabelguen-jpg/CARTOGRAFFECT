"""Tests d'intégration et de validation du modèle POMDP sous inférence active (Phase 2).

Vérifie :
1. Le paramétrage ``θ = {τ_A, τ_C, λ, α_0, γ_α, η_diss, β_X, β_Y}`` et la loi
   de concentration de Dirichlet ``α_z = α_0 exp(γ_α z)``.
2. La matrice de vraisemblance ``A = P(o_t | s_t)`` à 3 modalités non redondantes
   ``(3, 176), (3, 176), (4, 176)`` et le générateur EMA en deux temps.
3. Le tenseur de transition ``B = P(s_{t+1} | s_t, u_t)`` :
   (a) arbitrage intra-strate symétrique ``|X_{t+1}| + λ|Y_{t+1}| <= 2Z_t - 2`` ;
   (b) approfondissement ``Z -> Z + 1`` conforme à ``canonicalDepthWeight`` ;
   (c) dissipation allostatique au taux effectif ``η_eff(Z)`` modulé par ``α_z``.
4. L'absence de double-comptage (filtre bayésien en 1 passe et ``pA``/``pB``) et
   l'invariance absolue face aux labels cachés ``is_remission`` / ``d_obj``.
5. La stabilité numérique et la rémission complète d'une session standard de 400 essais.
"""

from __future__ import annotations

import math

import numpy as np
import pytest

from cartograffect_sim import (
    ActiveInferenceCartograffectAgent,
    AffectiveControlAction,
    AffectivePOMDPEngine,
    AgentParameters,
    BanditAction,
    BlockSpec,
    CoreAffectPoint,
    CueSignal,
    EMAObservation,
    NonStationaryBanditEnv,
    OutcomeValence,
    Polarity,
    SessionResult,
    TaskInferenceEngine,
    TrialObservation,
    TwoStageEMAGenerator,
    apply_budget_constraint,
    build_dirichlet_priors_pA,
    build_dirichlet_priors_pB,
    build_likelihood_matrix_A,
    build_preference_tensor_C,
    build_transition_tensor_B,
    canonical_depth_weight,
    compute_expected_free_energy,
    default_400_trial_schedule,
    discretize_gradients,
    effective_dissipation_rate,
    get_point_by_state_index,
    get_state_index_by_point,
    is_intra_stratum_budget_admissible,
    stratum_valid_grid,
    witness_engine_for_point,
)


def _assert_stochastic_columns(mat: np.ndarray, *, tol: float = 1e-5) -> None:
    assert np.all(np.isfinite(mat)), "Le tenseur contient des NaN ou Inf"
    assert np.all(mat >= 0.0), "Le tenseur contient des probabilités négatives"
    col_sums = mat.sum(axis=0)
    assert np.allclose(col_sums, 1.0, atol=tol, rtol=tol), (
        f"Sommes de colonnes hors tolérance [1-tol, 1+tol]: "
        f"min={col_sums.min()}, max={col_sums.max()}"
    )


class TestAgentParametersAndDirichlet:
    def test_theta_vector_and_validation(self) -> None:
        params = AgentParameters()
        theta = params.theta_dict()
        assert set(theta.keys()) == {
            "tau_A",
            "tau_C",
            "lambda",
            "alpha_0",
            "gamma_alpha",
            "eta_diss",
            "beta_X",
            "beta_Y",
        }
        assert params.beta_x > params.beta_y > 0.0

        with pytest.raises(ValueError, match="β_X"):
            AgentParameters(beta_x=1.0, beta_y=1.5)
        with pytest.raises(ValueError, match="lambda_weight"):
            AgentParameters(lambda_weight=1.2)
        with pytest.raises(ValueError, match="eta_diss"):
            AgentParameters(eta_diss=0.0)
        with pytest.raises(ValueError, match="τ_A et τ_C"):
            AgentParameters(tau_a=0.0)

    def test_dirichlet_concentration_increases_with_depth_z(self) -> None:
        params = AgentParameters(alpha_0=1.2, gamma_alpha=0.45)
        alphas = [params.dirichlet_concentration(z) for z in range(8)]
        for z in range(8):
            assert math.isclose(
                alphas[z], 1.2 * math.exp(0.45 * z), rel_tol=1e-12
            )
        for z in range(7):
            assert alphas[z + 1] > alphas[z]

    def test_geometry_helpers_and_budget_constraint(self) -> None:
        # Témoin rejette un point hors grille valide
        with pytest.raises(ValueError):
            witness_engine_for_point(CoreAffectPoint(1, 0, 2))

        # Aucun doublon dans stratum_valid_grid(z)
        for z in range(8):
            pts_z = stratum_valid_grid(z)
            assert len(pts_z) == len(set(pts_z))

        # Loi budgétaire symétrique : R = 6, λ = 1 vs λ = 0
        x1, y1 = apply_budget_constraint(5.0, 5.0, 6.0, 1.0)
        assert math.isclose(x1, 3.0, abs_tol=1e-12)
        assert math.isclose(y1, 3.0, abs_tol=1e-12)
        x0, y0 = apply_budget_constraint(5.0, 5.0, 6.0, 0.0)
        assert math.isclose(x0, 5.0, abs_tol=1e-12)
        assert math.isclose(y0, 5.0, abs_tol=1e-12)


class TestLikelihoodMatrixAAndTwoStageEMA:
    def test_likelihood_a_normalized_and_threshold_sensitive(self) -> None:
        p_low = AgentParameters(tau_a=0.15, tau_c=0.45)
        p_high = AgentParameters(tau_a=0.65, tau_c=0.45)
        a_low = build_likelihood_matrix_A(p_low)
        a_high = build_likelihood_matrix_A(p_high)

        assert len(a_low) == 3
        expected_shapes = [(3, 176), (3, 176), (4, 176)]
        for mat, shp in zip(a_low, expected_shapes):
            assert mat.shape == shp
            _assert_stochastic_columns(mat, tol=1e-12)
        for mat in a_high:
            _assert_stochastic_columns(mat, tol=1e-12)

        idx_courage = get_state_index_by_point()[CoreAffectPoint(2, 0, 2)]
        idx_joie = get_state_index_by_point()[CoreAffectPoint(0, 2, 2)]
        idx_veil = get_state_index_by_point()[CoreAffectPoint(0, 0, 0)]
        idx_desir = get_state_index_by_point()[CoreAffectPoint(1, 1, 2)]

        # Seuil τ_A plus bas => probabilité de filtrage (idx 0) plus basse sur (1,1,2)
        assert (1.0 - a_low[0][0, idx_desir]) > (1.0 - a_high[0][0, idx_desir])
        # τ_C inchangé => vraisemblance obs_C identique sur Joie (0,2,2)
        assert np.allclose(a_low[1][:, idx_joie], a_high[1][:, idx_joie])
        # Point de Veille maximise la probabilité d'être filtré (indice 0)
        assert a_low[0][0, idx_veil] > a_low[0][0, idx_courage]
        assert a_low[1][0, idx_veil] > a_low[1][0, idx_joie]

    def test_dirichlet_priors_pa_match_alpha_z(self) -> None:
        params = AgentParameters(alpha_0=0.8, gamma_alpha=0.5)
        a_mats = build_likelihood_matrix_A(params)
        pa_mats = build_dirichlet_priors_pA(a_mats, params)
        points = get_point_by_state_index()
        expected_alphas = np.array(
            [params.dirichlet_concentration(pt.z) for pt in points]
        )
        for m, pa in enumerate(pa_mats):
            assert pa.shape == a_mats[m].shape
            assert np.all(pa >= 0.0)
            assert np.allclose(pa.sum(axis=0), expected_alphas, rtol=1e-12, atol=1e-12)

    def test_two_stage_ema_gating_and_gradient_discretization(self) -> None:
        params = AgentParameters(tau_a=0.30, tau_c=0.40)
        assert discretize_gradients(0.20, -0.20, params.tau_a, params.tau_c) == (
            Polarity.ZERO,
            Polarity.ZERO,
        )
        assert discretize_gradients(0.45, -0.50, params.tau_a, params.tau_c) == (
            Polarity.POS,
            Polarity.NEG,
        )

        # Mode déterministe : seuil binaire exact + 3 modalités non redondantes
        gen_det = TwoStageEMAGenerator(params, seed=1, stochastic=False)
        ema_quiet = gen_det.sample_from_gradients(0.10, -0.25, persistence_level=0)
        assert ema_quiet == EMAObservation(0, None, 0, None, persistence_level=0)
        assert ema_quiet.modality_indices == (0, 0, 0)

        ema_active = gen_det.sample_from_gradients(-0.55, 0.45, persistence_level=2)
        assert ema_active == EMAObservation(1, -1, 1, 1, persistence_level=2)
        assert ema_active.modality_indices == (2, 1, 2)

        with pytest.raises(ValueError, match="bipolar_a"):
            EMAObservation(0, 1, 0, None)

        gen_stoch = TwoStageEMAGenerator(params, seed=7, stochastic=True)
        a_mats = build_likelihood_matrix_A(params)
        for s_idx in (0, 5, 25, 100):
            ema = gen_stoch.sample_from_state(s_idx, a_mats)
            assert (ema.filter_a == 0) == (ema.bipolar_a is None)
            assert (ema.filter_c == 0) == (ema.bipolar_c is None)


class TestTransitionTensorBAndDirichlet:
    def test_transition_b_normalization_and_structural_rules(self) -> None:
        params = AgentParameters(lambda_weight=0.6, eta_diss=0.30)
        b_list = build_transition_tensor_B(params)
        assert len(b_list) == 1
        b_mat = b_list[0]
        assert b_mat.shape == (176, 176, 17)
        _assert_stochastic_columns(b_mat, tol=1e-12)

        points = get_point_by_state_index()
        idx_by_pt = get_state_index_by_point()

        for u in range(
            AffectiveControlAction.INTRA_JOIE, AffectiveControlAction.INTRA_DEGOUT + 1
        ):
            for s_idx, src in enumerate(points):
                nz = np.flatnonzero(b_mat[:, s_idx, u] > 0.0)
                for t_idx in nz:
                    tgt = points[int(t_idx)]
                    assert is_intra_stratum_budget_admissible(
                        src, tgt, params.lambda_weight
                    )

        for u in range(
            AffectiveControlAction.DEEPEN_JOIE, AffectiveControlAction.DEEPEN_DEGOUT + 1
        ):
            for s_idx, src in enumerate(points):
                if src.z < 7:
                    nz = np.flatnonzero(b_mat[:, s_idx, u] > 0.0)
                    for t_idx in nz:
                        tgt = points[int(t_idx)]
                        assert canonical_depth_weight(src, tgt) > 0

        idx_veil = idx_by_pt[CoreAffectPoint(0, 0, 0)]
        idx_antic = idx_by_pt[CoreAffectPoint(0, 0, 2)]
        idx_surprise = idx_by_pt[CoreAffectPoint(0, 0, 1)]
        idx_joie = idx_by_pt[CoreAffectPoint(0, 2, 2)]
        idx_emoi = idx_by_pt[CoreAffectPoint(0, 0, 3)]
        idx_enthou = idx_by_pt[CoreAffectPoint(0, 4, 3)]

        eta_2 = effective_dissipation_rate(params, 2)
        eta_3 = effective_dissipation_rate(params, 3)

        assert math.isclose(b_mat[idx_veil, idx_veil, 0], 1.0, abs_tol=1e-12)
        assert math.isclose(b_mat[idx_emoi, idx_enthou, 0], eta_3, abs_tol=1e-12)
        assert math.isclose(b_mat[idx_enthou, idx_enthou, 0], 1.0 - eta_3, abs_tol=1e-12)
        assert math.isclose(b_mat[idx_antic, idx_joie, 0], eta_2, abs_tol=1e-12)
        assert math.isclose(b_mat[idx_antic, idx_emoi, 0], eta_3, abs_tol=1e-12)
        assert math.isclose(b_mat[idx_veil, idx_antic, 0], eta_2, abs_tol=1e-12)
        assert b_mat[idx_surprise, idx_antic, 0] == 0.0

    def test_z2_axial_diagonal_prior_symmetry(self) -> None:
        b_mat = build_transition_tensor_B(AgentParameters(lambda_weight=1.0))[0]
        pts = get_point_by_state_index()
        z2_idx = [i for i, p in enumerate(pts) if p.z == 2 and (p.x, p.y) != (0, 0)]
        intra_u = range(AffectiveControlAction.INTRA_JOIE, AffectiveControlAction.INTRA_DEGOUT + 1)
        b_avg = np.mean(b_mat[np.ix_(z2_idx, z2_idx, list(intra_u))], axis=2)
        is_ax = [pts[i].x == 0 or pts[i].y == 0 for i in z2_idx]
        stay_ax = float(np.mean([b_avg[k, k] for k in range(8) if is_ax[k]]))
        stay_dg = float(np.mean([b_avg[k, k] for k in range(8) if not is_ax[k]]))
        assert abs(stay_ax - stay_dg) < 1e-12

    def test_lambda_modulates_xy_arbitrage_preference(self) -> None:
        b_small_lam = build_transition_tensor_B(AgentParameters(lambda_weight=0.1))[0]
        b_large_lam = build_transition_tensor_B(AgentParameters(lambda_weight=1.0))[0]
        idx_by_pt = get_state_index_by_point()

        src_z3 = idx_by_pt[CoreAffectPoint(0, 0, 3)]
        y_dom = idx_by_pt[CoreAffectPoint(0, 4, 3)]
        x_dom = idx_by_pt[CoreAffectPoint(4, 0, 3)]

        u = AffectiveControlAction.INTRA_DESIR
        ratio_small = b_small_lam[y_dom, src_z3, u] / b_small_lam[x_dom, src_z3, u]
        ratio_large = b_large_lam[y_dom, src_z3, u] / b_large_lam[x_dom, src_z3, u]
        assert ratio_small > ratio_large

    def test_dirichlet_priors_pb_and_zero_preservation(self) -> None:
        params = AgentParameters(alpha_0=1.5, gamma_alpha=0.4)
        b_mats = build_transition_tensor_B(params)
        pb_mats = build_dirichlet_priors_pB(b_mats, params)
        points = get_point_by_state_index()
        expected_alphas = np.array(
            [params.dirichlet_concentration(pt.z) for pt in points]
        )

        pb = pb_mats[0]
        assert pb.shape == (176, 176, 17)
        assert np.array_equal(pb == 0.0, b_mats[0] == 0.0)
        for u in range(17):
            assert np.allclose(pb[:, :, u].sum(axis=0), expected_alphas, rtol=1e-12)


class TestNonDoubleCountingAndZeroLeakage:
    def test_task_engine_single_pass_exact_bayes_and_no_leakage(self) -> None:
        params = AgentParameters()
        t_clean = TaskInferenceEngine(params, seed=42)
        t_mutated = TaskInferenceEngine(params, seed=42)

        obs_clean = TrialObservation(
            trial_index=0,
            block_id=0,
            block_name="active",
            trial_in_block=0,
            cue=CueSignal.RULE_A,
            outcome=OutcomeValence.POSITIVE,
            reward=1.0,
            perturbation_active=False,
            perturbation_intensity=0.0,
            d_obj=2,
            is_remission=False,
            evaluative_score=None,
            sequence_failure_rate=0.0,
            block_accuracy=1.0,
        )
        # Même payload sensoriel, métadonnées cachées entièrement inversées
        obs_mutated = TrialObservation(
            trial_index=0,
            block_id=9,
            block_name="fake_remission",
            trial_in_block=0,
            cue=CueSignal.RULE_A,
            outcome=OutcomeValence.POSITIVE,
            reward=1.0,
            perturbation_active=True,
            perturbation_intensity=0.95,
            d_obj=4,
            is_remission=True,
            evaluative_score=None,
            sequence_failure_rate=0.0,
            block_accuracy=1.0,
        )

        t_clean.select_action(obs_clean)
        # Calcul analytique exact de q_rule_pre après l'indice RULE_A (p_true=0.72, p_false=0.10, choix A/B)
        expected_pre = 0.72 / (0.72 + 0.10)
        assert math.isclose(float(t_clean._qs_pre[0][0, -1, 0]), expected_pre, abs_tol=1e-5)

        sig1 = t_clean.observe_outcome(obs_clean, BanditAction.CHOICE_A)

        t_mutated.select_action(obs_mutated)
        sig2 = t_mutated.observe_outcome(obs_mutated, BanditAction.CHOICE_A)

        # Zéro fuite : signaux strictement identiques malgré d_obj / is_remission inversés
        assert math.isclose(sig1.grad_a, sig2.grad_a, abs_tol=1e-12)
        assert math.isclose(sig1.grad_c, sig2.grad_c, abs_tol=1e-12)
        assert math.isclose(sig1.bayesian_surprise, sig2.bayesian_surprise, abs_tol=1e-12)
        assert np.allclose(sig1.q_rule, sig2.q_rule, atol=1e-12)
        assert np.allclose(sig1.q_ctrl, sig2.q_ctrl, atol=1e-12)

        # Aucun double-comptage de cue ni double transition B : point fixe FPI exact en 1 passe
        q_c = sig1.q_ctrl
        a_out_a = t_clean._a[1][:, :, :, 0]
        log_lr0 = q_c[0] * math.log(float(a_out_a[1, 0, 0])) + q_c[1] * math.log(float(a_out_a[1, 0, 1]))
        log_lr1 = q_c[0] * math.log(float(a_out_a[1, 1, 0])) + q_c[1] * math.log(float(a_out_a[1, 1, 1]))
        u0 = expected_pre * math.exp(log_lr0)
        u1 = (1.0 - expected_pre) * math.exp(log_lr1)
        expected_post0 = u0 / (u0 + u1)
        assert math.isclose(sig1.q_rule[0], expected_post0, abs_tol=1e-4)

    def test_affect_engine_exact_dirichlet_learning_no_double_counting(self) -> None:
        params = AgentParameters(lr_pa=1.0, lr_pb=1.0)
        eng = AffectivePOMDPEngine(params, seed=42)
        task = TaskInferenceEngine(params, seed=42)

        obs0 = TrialObservation(
            trial_index=0, block_id=0, block_name="b", trial_in_block=0,
            cue=CueSignal.RULE_A, outcome=OutcomeValence.NEGATIVE, reward=-1.0,
            perturbation_active=True, perturbation_intensity=0.8,
            d_obj=2, is_remission=False, evaluative_score=None,
            sequence_failure_rate=0.5, block_accuracy=0.2,
        )
        act0 = task.select_action(obs0)
        sig0 = task.observe_outcome(obs0, act0)
        ema0 = EMAObservation(1, -1, 1, -1, persistence_level=1)

        pa0_sum_before = float(eng.current_pA[0].sum())
        pb0_before = eng.current_pB[0].copy()
        act_aff0, _, qs0 = eng.step(ema0, sig0, update_parameters=True)
        pa0_sum_after_0 = float(eng.current_pA[0].sum())
        pb0_after_0 = eng.current_pB[0].copy()

        # Au pas t=0 : pA augmente exactement de lr_pa=1.0, pB reste inchangé (0 transition)
        assert math.isclose(pa0_sum_after_0 - pa0_sum_before, 1.0, abs_tol=1e-4)
        assert math.isclose(float(pb0_after_0.sum() - pb0_before.sum()), 0.0, abs_tol=1e-4)

        # Au pas t=1 : pA augmente exactement de lr_pa=1.0 et pB[:, :, act_aff0] augmente de lr_pb * (qs1 x qs0) * (B > 0)
        _, _, qs1 = eng.step(ema0, sig0, update_parameters=True)
        pa0_sum_after_1 = float(eng.current_pA[0].sum())
        pb0_after_1 = eng.current_pB[0].copy()
        delta_pb = pb0_after_1 - pb0_after_0
        expected_slice = np.outer(qs1, qs0) * (eng.B_init[0][:, :, int(act_aff0)] > 0.0)
        assert math.isclose(pa0_sum_after_1 - pa0_sum_after_0, 1.0, abs_tol=1e-4)
        assert np.allclose(delta_pb[:, :, int(act_aff0)], expected_slice, atol=1e-5)
        for u in range(delta_pb.shape[2]):
            if u != int(act_aff0):
                assert np.allclose(delta_pb[:, :, u], 0.0, atol=1e-6)


class TestExpectedFreeEnergyG:
    def test_efe_weights_epistemic_vs_pragmatic_with_beta_primary(self) -> None:
        params = AgentParameters(beta_x=4.0, beta_y=1.0, affect_gamma=2.0)
        a_mats = build_likelihood_matrix_A(params)
        b_mats = build_transition_tensor_B(params)
        c_unit = build_preference_tensor_C(params)
        e_vec = np.ones(17, dtype=np.float64) / 17.0
        qs_init = [np.ones(176, dtype=np.float64) / 176.0]

        res = compute_expected_free_energy(
            qs_init, a_mats, b_mats, c_unit, e_vec, params, num_controls=[17]
        )
        assert res.efe.shape == (17,)
        assert np.all(np.isfinite(res.efe))
        assert np.all(res.epistemic_value >= -1e-6)
        assert math.isclose(float(res.policy_posterior.sum()), 1.0, abs_tol=1e-9)

        expected_g = -(
            params.beta_x * res.epistemic_value + params.beta_y * res.pragmatic_value
        )
        assert np.allclose(res.efe, expected_g, atol=1e-10)

        p_more_ep = AgentParameters(beta_x=8.0, beta_y=1.0, affect_gamma=2.0)
        res_ep = compute_expected_free_energy(
            qs_init, a_mats, b_mats, c_unit, e_vec, p_more_ep, num_controls=[17]
        )
        assert np.allclose(res.epistemic_value, res_ep.epistemic_value, atol=1e-6)
        assert np.all(
            res_ep.neg_efe - res.neg_efe >= -1e-6 + 4.0 * res.epistemic_value
        )


class TestOrthogonalGenerativeProcess:
    def test_schedule_orthogonality_and_remission_purity(self) -> None:
        schedule = default_400_trial_schedule()
        assert sum(b.num_trials for b in schedule) == 400
        assert {b.d_obj for b in schedule} == {2, 3, 4}
        assert any(b.is_remission for b in schedule)
        assert min(b.p_ctrl for b in schedule) <= 0.2
        assert max(b.p_ctrl for b in schedule) >= 0.8
        assert min(b.v_rule for b in schedule) <= 0.05
        assert max(b.v_rule for b in schedule) >= 0.4

        env = NonStationaryBanditEnv(schedule=schedule, seed=123)
        assert env.total_trials == 400

        rng = np.random.default_rng(123)
        for _ in range(400):
            act = BanditAction(int(rng.integers(0, 3)))
            step_res = env.step(act)
            if step_res.observation.is_remission:
                assert step_res.observation.perturbation_active is False
                assert step_res.observation.perturbation_intensity == 0.0
                assert step_res.observation.outcome == OutcomeValence.NEUTRAL
                assert step_res.observation.reward == 0.0
        assert env.is_done

    def test_objective_contingency_delta_p_and_rule_volatility(self) -> None:
        blk_hi = (BlockSpec(0, "hi", 400, p_ctrl=0.90, v_rule=0.05, cue_clarity=1.0, d_obj=2),)
        env_hi = NonStationaryBanditEnv(blk_hi, seed=9)
        pos_match_hi: list[int] = []
        pos_miss_hi: list[int] = []
        for t in range(400):
            res = env_hi.step(t % 2)
            win = int(res.observation.outcome == OutcomeValence.POSITIVE)
            if res.ground_truth.matched_rule:
                pos_match_hi.append(win)
            else:
                pos_miss_hi.append(win)
        delta_p_hi = np.mean(pos_match_hi) - np.mean(pos_miss_hi)
        assert delta_p_hi > 0.70

        blk_lo = (BlockSpec(0, "lo", 400, p_ctrl=0.10, v_rule=0.05, cue_clarity=1.0, d_obj=2),)
        env_lo = NonStationaryBanditEnv(blk_lo, seed=9)
        pos_match_lo: list[int] = []
        pos_miss_lo: list[int] = []
        for t in range(400):
            res = env_lo.step(t % 2)
            win = int(res.observation.outcome == OutcomeValence.POSITIVE)
            if res.ground_truth.matched_rule:
                pos_match_lo.append(win)
            else:
                pos_miss_lo.append(win)
        delta_p_lo = np.mean(pos_match_lo) - np.mean(pos_miss_lo)
        assert abs(delta_p_lo) < 0.25
        assert delta_p_hi - delta_p_lo > 0.55


@pytest.fixture(scope="module")
def standard_400_session() -> tuple[SessionResult, AgentParameters, NonStationaryBanditEnv]:
    """Exécute une session standard complète de 400 essais une seule fois pour les tests."""
    params = AgentParameters(alpha_0=2.0, gamma_alpha=0.55, eta_diss=0.35, beta_x=2.0, beta_y=1.2)
    env = NonStationaryBanditEnv(schedule=default_400_trial_schedule(), seed=42)
    agent = ActiveInferenceCartograffectAgent(params, seed=42, stochastic_ema=True)
    result = agent.run_session(env)
    return result, params, env


class TestFull400TrialSessionIntegration:
    def test_400_trials_numerical_stability_and_normalization(
        self,
        standard_400_session: tuple[SessionResult, AgentParameters, NonStationaryBanditEnv],
    ) -> None:
        result, params, env = standard_400_session
        assert len(result.records) == 400
        assert env.is_done

        for rec in result.records:
            assert np.all(np.isfinite(rec.qs_affect))
            assert np.all(rec.qs_affect >= 0.0)
            assert math.isclose(float(rec.qs_affect.sum()), 1.0, abs_tol=1e-4)
            assert math.isfinite(rec.expected_z) and 0.0 <= rec.expected_z <= 7.0
            assert math.isfinite(rec.p_homeostasis) and 0.0 <= rec.p_homeostasis <= 1.0

        # Aucune transition directe Z >= 2 -> Surprise (0,0,1)
        z_to_surprise = sum(
            1
            for r1, r2 in zip(result.records[:-1], result.records[1:])
            if r1.map_entry.point.z >= 2 and r2.map_entry.point.z == 1
        )
        assert z_to_surprise == 0

        for a_m in result.final_A:
            _assert_stochastic_columns(a_m, tol=1e-4)
        for b_f in result.final_B:
            assert b_f.shape == (176, 176, 17)
            for u in range(17):
                _assert_stochastic_columns(b_f[:, :, u], tol=1e-4)

        b_init = build_transition_tensor_B(params)[0]
        assert np.array_equal(result.final_B[0] == 0.0, b_init == 0.0)

    def test_remission_dissipation_and_behavioral_engagement(
        self,
        standard_400_session: tuple[SessionResult, AgentParameters, NonStationaryBanditEnv],
    ) -> None:
        result, _, env = standard_400_session
        records = result.records
        assert result.env_summary["accuracy_non_remission"] > 0.70

        remission_blocks = [b for b in env.schedule if b.is_remission]
        assert len(remission_blocks) >= 2
        for blk in remission_blocks:
            blk_recs = [r for r in records if r.block_id == blk.block_id]
            diss_rate = float(
                np.mean([r.affective_action == AffectiveControlAction.DISSIPATE for r in blk_recs])
            )
            assert diss_rate > 0.70
            tail_z = float(np.mean([r.expected_z for r in blk_recs[-5:]]))
            tail_h = float(np.mean([r.p_homeostasis for r in blk_recs[-5:]]))
            assert tail_z < 0.60
            assert tail_h > 0.75

        active_b0 = [r for r in records if r.block_id == 0]
        assert float(np.mean([r.expected_z for r in active_b0])) >= 1.8

    def test_eta_diss_governs_pure_dissipation_kinetics(self) -> None:
        schedule = (
            BlockSpec(0, "stress", 12, p_ctrl=0.15, v_rule=0.30, cue_clarity=0.30, d_obj=3),
            BlockSpec(1, "remission", 25, p_ctrl=0.50, v_rule=0.05, cue_clarity=0.90, d_obj=2, is_remission=True),
        )
        p_slow = AgentParameters(eta_diss=0.10)
        p_fast = AgentParameters(eta_diss=0.45)

        b_slow = build_transition_tensor_B(p_slow)[0]
        b_fast = build_transition_tensor_B(p_fast)[0]
        idx_by_pt = get_state_index_by_point()
        idx_veil = idx_by_pt[CoreAffectPoint(0, 0, 0)]
        idx_pe = idx_by_pt[CoreAffectPoint(-4, 0, 3)]

        q_slow = np.zeros(176, dtype=np.float64)
        q_fast = np.zeros(176, dtype=np.float64)
        q_slow[idx_pe] = 1.0
        q_fast[idx_pe] = 1.0
        for _ in range(10):
            q_slow = b_slow[:, :, AffectiveControlAction.DISSIPATE] @ q_slow
            q_fast = b_fast[:, :, AffectiveControlAction.DISSIPATE] @ q_fast
        assert q_fast[idx_veil] > q_slow[idx_veil] + 0.50

        env_test = NonStationaryBanditEnv(schedule=schedule, seed=7)
        ag_test = ActiveInferenceCartograffectAgent(p_fast, seed=7, stochastic_ema=False)
        res = ag_test.run_session(env_test)
        assert len(res.records) == 37
        assert res.records[-1].p_homeostasis > 0.90
        assert isinstance(ag_test.affect_engine, AffectivePOMDPEngine)
