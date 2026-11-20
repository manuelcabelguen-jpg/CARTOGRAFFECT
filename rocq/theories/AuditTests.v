(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*)

From Stdlib Require Import Bool Arith ZArith NArith Lia List.
Require Import CartograffectRocq.PredictiveEngine.
Require Import CartograffectRocq.CoreAffect.
Require Import CartograffectRocq.AffectiveMatrix.
Require Import CartograffectRocq.AffectiveDynamics.
Require Import CartograffectRocq.AffectiveTaxonomy.
Require Import CartograffectRocq.Lexicon176.
Require Import CartograffectRocq.PredictiveCircuit.

Open Scope bool_scope.
Open Scope nat_scope.

(** * Module AuditTests — Validation Rocq 9.1.0 (Audit des 113 théorèmes & 11 évaluations) *)

(** ** Phase 1 : Théorème 18 constructif et Audit Axiomatique (Print Assumptions) *)

Theorem all176Entries_antagonist_inverts_hedonic_polarity :
  forallb (fun e =>
    let ant := antagonistPoint (le_point e) in
    HedonicPolarity_eqb
      (computeHedonicPolarity (pt_x ant) (pt_y ant))
      (HedonicPolarity_invert (computeHedonicPolarity (pt_x (le_point e)) (pt_y (le_point e)))))
    all176Entries = true.
Proof.
  vm_compute. reflexivity.
Qed.

Print Assumptions Polarity_invert_involutive.
Print Assumptions coupling_regime_partition.
Print Assumptions feedbackUpdate_couples_gradients.
Print Assumptions inferential_loop_covers_interfaces.
Print Assumptions engine_induces_valid_core_affect.
Print Assumptions z2_budget_conservation.
Print Assumptions axial_to_diagonal_reallocation.
Print Assumptions dissipationStep_valid.
Print Assumptions dissipationStep_fixed_iff.
Print Assumptions dissipation_strictly_decreases.
Print Assumptions remanence_preserves_state.
Print Assumptions cooperative_step_leaves_crown.
Print Assumptions HedonicPolarity_invert_involutive.
Print Assumptions x_positive_determines_positive_valence.
Print Assumptions x_negative_determines_negative_valence.
Print Assumptions antagonistPoint_preserves_validity.
Print Assumptions antagonistPoint_involutive.
Print Assumptions contralateral_swaps_amplitudes.
Print Assumptions antagonist_commutes_with_invert.
Print Assumptions antagonistPoint_unified.
Print Assumptions antagonist_preserves_validity_in.
Print Assumptions transferUnitYtoX_preserves_sum.
Print Assumptions inventory_176_certified.
Print Assumptions taxonomy_group_exhaustive.
Print Assumptions taxonomy_group_exclusive.
Print Assumptions dominantSector_iff_taxonomicGroup.
Print Assumptions contralateral_group_bindings.
Print Assumptions classifySubsector_correct.
Print Assumptions subsector_exclusive.
Print Assumptions classifySubsector_refines_group.
Print Assumptions classifySubsector_determines_valence.
Print Assumptions end_to_end_coherence.
Print Assumptions all176Entries_length.
Print Assumptions all176Entries_geometrically_valid.
Print Assumptions all176Entries_unique_points.
Print Assumptions all176Entries_closed_under_antagonist.
Print Assumptions all176Entries_spatial_completeness.
Print Assumptions feedbackUpdateWeighted_couples_precision.
Print Assumptions engineStep_remanence.
Print Assumptions engineStep_phase_progression.
Print Assumptions deployCouplingWithPrecision_valid.
Print Assumptions neutral_coupling_without_suspension_yields_veille.
Print Assumptions neutral_or_subthreshold_with_suspension_yields_central.
Print Assumptions descending_suspension_yields_central_operator.
Print Assumptions central_z_ge2_requires_descending_suspension.
Print Assumptions deployCouplingWithPrecision_budget_conservation.
Print Assumptions dual_engaged_yields_diagonal_z2_precision.
Print Assumptions symmetric_precision_never_lateral.
Print Assumptions projectToCoreAffect_surjective.
Print Assumptions engineStep_canonical_trajectory.
Print Assumptions engineStep_surprise_to_crown.
Print Assumptions anticipation_short_circuits_to_veille.
Print Assumptions dissipation_from_ge2_never_visits_surprise.
Print Assumptions dissipationPotential_short_circuit_jump.
Print Assumptions dissipation_reaches_veille.
Print Assumptions antagonist_commutes_with_invert_precision.
Print Assumptions evaluateMatrix_core_antagonist_independent.
Print Assumptions mapping_independent_antagonist_invariants.
Print Assumptions canonicalDepthKernel_reaches_crown.
Print Assumptions canonicalDepthKernel_reaches_lateral.
Print Assumptions lateral_reachable.
Print Assumptions lateral_reachable_from_surprise.
Print Assumptions canonicalDepthKernel_colere_bifurcates.
Print Assumptions canonicalDepthKernel_axial_instability_p2.
Print Assumptions canonicalDepthKernel_outgoingWeight_pos.
Print Assumptions classifyTaxonomicGroup_unique_maximizer.
Print Assumptions classifyTaxonomicGroup_maximizes_membership.
Print Assumptions lateral_has_overlapping_attractors.
Print Assumptions all176Entries_deterministically_reachable.
Print Assumptions all176Entries_reachable_by_engine.
Print Assumptions all176Entries_witness_check.
Print Assumptions all176Entries_antagonist_inverts_hedonic_polarity.
Print Assumptions circuit_covers_interfaces_both_sides.
Print Assumptions circuit_refines_inferential_ops.
Print Assumptions phiL1_left_inv.
Print Assumptions phiL1_right_inv.
Print Assumptions phiL1_agrees_with_deployZ2.
Print Assumptions crossingII_is_transpose_of_crossingI.
Print Assumptions routeToSubjective_injective.
Print Assumptions routeToPerceptive_injective.
Print Assumptions projectPerceptible_valid.
Print Assumptions projectPerceptible_z2_matches_phiL1.
Print Assumptions projectPerceptible_neutral_elevates_to_central.
Print Assumptions attentional_bottleneck_sum_active.
Print Assumptions circuitRowSum_exact.
Print Assumptions veille_absorbing_free.
Print Assumptions lyapunov_monotone_free.
Print Assumptions lyapunov_strict_descent_witness.
Print Assumptions lyapunov_expected_drift_constant.
Print Assumptions axial_peur_bifurcates_p2.
Print Assumptions veille_reaches_all_one_step.
Print Assumptions all_reach_veille_two_steps.
Print Assumptions veille_unreachable_when_eps_max.
Print Assumptions circularCycle_veille_fixed_point.
Print Assumptions circularCycle_reduces_total_discrepancy.
Print Assumptions lyapunov_drift_charge_with_passive_extinction.
Print Assumptions p1_without_p2_eps_independent.
Print Assumptions epistemic_rigidity_traps_charge_slice.
Print Assumptions pragmatic_helplessness_traps_charge_slice.
Print Assumptions perseveration_traps_discharge_free.
Print Assumptions passive_extinction_zero_relief.
Print Assumptions active_resolution_beats_passive_extinction.
Print Assumptions charge_accumulator_bounded.
Print Assumptions nextStratumR5_le_zMax.
Print Assumptions nextStratumR5_short_circuits_z2_to_veille.
Print Assumptions nextStratumR5_from_ge2_never_visits_surprise.
Print Assumptions symmetricSigmoid_sum.
Print Assumptions symmetricSigmoid_pos.
Print Assumptions symmetricSigmoid_neg.
Print Assumptions precisionShare_double_charge_cancels_alpha.
Print Assumptions projectUnifiedState_valid.
Print Assumptions projectUnifiedState_crown_budget.
Print Assumptions projectUnifiedState_reaches_lateral_consternation.

(** ** Phase 2 : Tests d'inhabitation et évaluation concrète (Compute) *)

(** 1. État basal par défaut : Point de Veille (0, 0, 0) *)
Compute cas_point (ams_core (ts_matrix (runCartograffectPipeline defaultPredictiveEngineState))).
Compute ts_stratum (runCartograffectPipeline defaultPredictiveEngineState).
Compute ts_group (runCartograffectPipeline defaultPredictiveEngineState).

(** 2. Écart saillant sous le seuil attentionnel : Surprise (0, 0, 1) *)
Definition sampleSurpriseEngine : PredictiveEngineState := {|
  pes_discrepancy := {|
    sd_magnitude           := 5;
    sd_sensoryThreshold    := 2;
    sd_resorptionThreshold := 1;
    sd_hysteresis          := ltac:(lia)
  |};
  pes_perceptive  := {| pi_controleGradient := Pol_pos |};
  pes_subjective  := {| si_attenteGradient := Pol_neg; si_descendingSuspension := false |};
  pes_attentional := {|
    ai_allocatedPrecision  := 1;
    ai_engagementThreshold := 3;
    ai_persistenceDepth    := 0;
    ai_precisionA          := 1;
    ai_precisionC          := 1
  |}
|}.

Compute cas_point (ams_core (ts_matrix (runCartograffectPipeline sampleSurpriseEngine))).
Compute ts_stratum (runCartograffectPipeline sampleSurpriseEngine).
Compute ams_activation (ts_matrix (runCartograffectPipeline sampleSurpriseEngine)).

(** 3. Couplage engagé (A-, C+) à Z = 2 : Colère (-1, +1, 2) et Calme (+1, -1, 2) *)
Definition sampleColereEngine : PredictiveEngineState := {|
  pes_discrepancy := {|
    sd_magnitude           := 5;
    sd_sensoryThreshold    := 2;
    sd_resorptionThreshold := 1;
    sd_hysteresis          := ltac:(lia)
  |};
  pes_perceptive  := {| pi_controleGradient := Pol_pos |};
  pes_subjective  := {| si_attenteGradient := Pol_neg; si_descendingSuspension := true |};
  pes_attentional := {|
    ai_allocatedPrecision  := 5;
    ai_engagementThreshold := 3;
    ai_persistenceDepth    := 0;
    ai_precisionA          := 1;
    ai_precisionC          := 1
  |}
|}.

Compute cas_point (ams_core (ts_matrix (runCartograffectPipeline sampleColereEngine))).
Compute cas_point (ams_antagonist (ts_matrix (runCartograffectPipeline sampleColereEngine))).
Compute ts_group (runCartograffectPipeline sampleColereEngine).
Compute ts_subsector (runCartograffectPipeline sampleColereEngine).
Compute ts_antagonistGroup (runCartograffectPipeline sampleColereEngine).
Compute ts_antagonistSubsector (runCartograffectPipeline sampleColereEngine).
Compute ams_energyRegime (ts_matrix (runCartograffectPipeline sampleColereEngine)).
Compute ams_valence (ts_matrix (runCartograffectPipeline sampleColereEngine)).

(** 4. Résolution R5 : Neutralité globale / infra-liminaire -> Anticipation (0, 0, 2) et trajectoire *)
Definition sampleNeutralSuspendedEngine : PredictiveEngineState := {|
  pes_discrepancy := {|
    sd_magnitude           := 5;
    sd_sensoryThreshold    := 2;
    sd_resorptionThreshold := 1;
    sd_hysteresis          := ltac:(lia)
  |};
  pes_perceptive  := {| pi_controleGradient := Pol_zero |};
  pes_subjective  := {| si_attenteGradient := Pol_zero; si_descendingSuspension := true |};
  pes_attentional := {|
    ai_allocatedPrecision  := 5;
    ai_engagementThreshold := 3;
    ai_persistenceDepth    := 0;
    ai_precisionA          := 1;
    ai_precisionC          := 1
  |}
|}.

Definition sampleSubthresholdSuspendedEngine : PredictiveEngineState := {|
  pes_discrepancy := {|
    sd_magnitude           := 0;
    sd_sensoryThreshold    := 2;
    sd_resorptionThreshold := 1;
    sd_hysteresis          := ltac:(lia)
  |};
  pes_perceptive  := {| pi_controleGradient := Pol_pos |};
  pes_subjective  := {| si_attenteGradient := Pol_neg; si_descendingSuspension := true |};
  pes_attentional := {|
    ai_allocatedPrecision  := 5;
    ai_engagementThreshold := 3;
    ai_persistenceDepth    := 0;
    ai_precisionA          := 1;
    ai_precisionC          := 1
  |}
|}.

Definition sampleVeilleStepStart : PredictiveEngineState := {|
  pes_discrepancy := {|
    sd_magnitude           := 5;
    sd_sensoryThreshold    := 2;
    sd_resorptionThreshold := 1;
    sd_hysteresis          := ltac:(lia)
  |};
  pes_perceptive  := {| pi_controleGradient := Pol_zero |};
  pes_subjective  := {| si_attenteGradient := Pol_zero; si_descendingSuspension := false |};
  pes_attentional := {|
    ai_allocatedPrecision  := 0;
    ai_engagementThreshold := 2;
    ai_persistenceDepth    := 0;
    ai_precisionA          := 1;
    ai_precisionC          := 1
  |}
|}.

Compute cas_point (ams_core (ts_matrix (runCartograffectPipeline sampleNeutralSuspendedEngine))).
Compute cas_point (ams_core (ts_matrix (runCartograffectPipeline sampleSubthresholdSuspendedEngine))).
Compute (projectToCoreAffect sampleVeilleStepStart,
         projectToCoreAffect (engineStep sampleVeilleStepStart),
         projectToCoreAffect (engineStep (engineStep sampleVeilleStepStart)),
         projectToCoreAffect (engineStep (engineStep (engineStep sampleVeilleStepStart)))).

(** 5. Résolution R5 : Court-circuit allostatique (0, 0, 2) -> (0, 0, 0) et descente depuis (-1, 3, 3) *)
Compute dissipationStep (mkPoint 0%Z 0%Z 2).
Compute dissipationPotential (mkPoint 0%Z 0%Z 2) - dissipationPotential (dissipationStep (mkPoint 0%Z 0%Z 2)).
Compute (dissipationStep (mkPoint (-1)%Z 1%Z 2),
         dissipationStep (dissipationStep (mkPoint (-1)%Z 1%Z 2))).
Compute (dissipationStep (mkPoint (-1)%Z 3%Z 3),
         dissipationStep (dissipationStep (mkPoint (-1)%Z 3%Z 3)),
         nat_repeat dissipationStep 3 (mkPoint (-1)%Z 3%Z 3)).

(** 6. Résolution R8 (Voie déterministe) : Consternation (-1, 3, 3) via (pi_A, pi_C) = (1, 3) en Z = 3 *)
Definition sampleConsternationEngine : PredictiveEngineState := {|
  pes_discrepancy := {|
    sd_magnitude           := 6;
    sd_sensoryThreshold    := 2;
    sd_resorptionThreshold := 1;
    sd_hysteresis          := ltac:(lia)
  |};
  pes_perceptive  := {| pi_controleGradient := Pol_pos |};
  pes_subjective  := {| si_attenteGradient := Pol_neg; si_descendingSuspension := true |};
  pes_attentional := {|
    ai_allocatedPrecision  := 5;
    ai_engagementThreshold := 3;
    ai_persistenceDepth    := 1;
    ai_precisionA          := 1;
    ai_precisionC          := 3
  |}
|}.

Compute cas_point (ams_core (ts_matrix (runCartograffectPipeline sampleConsternationEngine))).
Compute ts_geometry (runCartograffectPipeline sampleConsternationEngine).
Compute ts_group (runCartograffectPipeline sampleConsternationEngine).
Compute ts_subsector (runCartograffectPipeline sampleConsternationEngine).
Compute ams_valence (ts_matrix (runCartograffectPipeline sampleConsternationEngine)).
Compute cas_point (ams_antagonist (ts_matrix (runCartograffectPipeline sampleConsternationEngine))).

(** 7. Résolution R8 (Voie stochastique) : Transitions du noyau canonicalDepthKernel depuis Colère (-1, 1, 2) *)
Compute dtk_weight canonicalDepthKernel (mkPoint (-1)%Z 1%Z 2) (mkPoint (-2)%Z 2%Z 3).
Compute dtk_weight canonicalDepthKernel (mkPoint (-1)%Z 1%Z 2) (mkPoint (-1)%Z 3%Z 3).
Compute dtk_weight canonicalDepthKernel (mkPoint (-1)%Z 1%Z 2) (mkPoint (-3)%Z 1%Z 3).
Compute DepthTransitionKernel_outgoingWeight canonicalDepthKernel (mkPoint (-1)%Z 1%Z 2).
Compute dtk_weight canonicalDepthKernel
  (antagonistPoint (mkPoint (-1)%Z 1%Z 2))
  (antagonistPoint (mkPoint (-1)%Z 3%Z 3)).

(** 8. Résolution R1 : Appartenance graduée attractorMembership sur Consternation (-1, 3, 3) et Envie (-2, 4, 4) *)
Compute (attractorMembership (mkPoint (-1)%Z 3%Z 3) TG_groupeJoie,
         attractorMembership (mkPoint (-1)%Z 3%Z 3) TG_groupeColere,
         attractorMembership (mkPoint (-1)%Z 3%Z 3) TG_groupePeur,
         classifyTaxonomicGroup (mkPoint (-1)%Z 3%Z 3)).
Compute (attractorMembership (mkPoint (-2)%Z 4%Z 4) TG_groupeJoie,
         attractorMembership (mkPoint (-2)%Z 4%Z 4) TG_groupeColere,
         attractorMembership (mkPoint (-2)%Z 4%Z 4) TG_groupePeur,
         classifyTaxonomicGroup (mkPoint (-2)%Z 4%Z 4)).

(** 9. Résolution R3 : PhenomenologicalMapping alternatif sans altérer core ni antagonist *)
Definition invertedPhenomenologicalMapping : PhenomenologicalMapping := {|
  pm_expectationFn := fun x =>
    if (x <? 0)%Z then LEP_epistemicDischarge
    else if (0 <? x)%Z then LEP_epistemicCharge
    else LEP_epistemicNeutral;
  pm_controlFn := fun y =>
    if (y <? 0)%Z then LCP_pragmaticDischarge
    else if (0 <? y)%Z then LCP_pragmaticCharge
    else LCP_pragmaticNeutral;
  pm_valenceFn    := fun x y => HedonicPolarity_invert (computeValence x y);
  pm_activationFn := fun _ => PA_operatorSuspension
|}.

Compute (cas_point (ams_core (evaluateMatrix (evaluateCoreAffect sampleColereEngine) canonicalMapping)),
         cas_point (ams_core (evaluateMatrix (evaluateCoreAffect sampleColereEngine) invertedPhenomenologicalMapping))).
Compute (cas_point (ams_antagonist (evaluateMatrix (evaluateCoreAffect sampleColereEngine) canonicalMapping)),
         cas_point (ams_antagonist (evaluateMatrix (evaluateCoreAffect sampleColereEngine) invertedPhenomenologicalMapping))).
Compute (ams_valence (evaluateMatrix (evaluateCoreAffect sampleColereEngine) canonicalMapping),
         ams_valence (evaluateMatrix (evaluateCoreAffect sampleColereEngine) invertedPhenomenologicalMapping)).

(** 10. Circuit circulaire à 6 opérateurs (PredictiveCircuit) : croisements, noyau exact et boucle fermée *)
Compute (crossingIPos (mkEngineCoupling Pol_zero Pol_zero),
         crossingIIPos (mkEngineCoupling Pol_zero Pol_zero)).
Compute projectPerceptible (mkEngineCoupling Pol_neg Pol_pos) 3 1 3 true.
Compute circuitRowSum defaultCircuitKernelParams (mkEngineCoupling Pol_neg Pol_zero).
Compute circuitWeight defaultCircuitKernelParams
          (mkEngineCoupling Pol_neg Pol_zero)
          (mkEngineCoupling Pol_neg Pol_pos).
Compute cas_point (snd (op3_crossingI_perceptible defaultCircularCircuitState)).

(** 11. Loi unifiée (UnifiedDynamicsParams) : R_t actif vs passif, strate R5 et Consternation (-1, 3, 3) *)
Compute (nextChargeAccumulator defaultUnifiedDynamicsParams 1000%N 500%N 500%N
           (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_pos Pol_zero),
         nextChargeAccumulator defaultUnifiedDynamicsParams 1000%N 500%N 500%N
           (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_zero Pol_zero)).
Compute (nextStratumR5 defaultUnifiedDynamicsParams 2 100%N,
         nextStratumR5 defaultUnifiedDynamicsParams 3 100%N).
Compute cas_point (projectUnifiedState defaultUnifiedDynamicsParams
          (mkEngineCoupling Pol_neg Pol_pos) 3 10%N 90%N true).
Compute precisionShares defaultUnifiedDynamicsParams 10%N 90%N
          (mkEngineCoupling Pol_neg Pol_neg).
