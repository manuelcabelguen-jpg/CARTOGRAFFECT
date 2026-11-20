----------------------------- MODULE AuditTests -------------------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Module 08 : AuditTests — 113e theoreme, ancre 113 theoremes & 11 blocs (TLA+ / TLC)
*)
EXTENDS Integers, Sequences, FiniteSets,
        PredictiveEngine, CoreAffect, AffectiveMatrix, AffectiveTaxonomy,
        AffectiveDynamics, Lexicon176, PredictiveCircuit

\* Echantillons moteurs canoniques (identiques a AuditTests.lean)
SampleSurpriseEngine ==
  MkEngineState(MkDiscrepancy(5, 2, 1), MkPerceptive("pos"), MkSubjective("neg", FALSE), MkAttentional(1, 3, 0, 1, 1))

SampleColereEngine ==
  MkEngineState(MkDiscrepancy(5, 2, 1), MkPerceptive("pos"), MkSubjective("neg", TRUE), MkAttentional(5, 3, 0, 1, 1))

SampleNeutralSuspendedEngine ==
  MkEngineState(MkDiscrepancy(5, 2, 1), MkPerceptive("zero"), MkSubjective("zero", TRUE), MkAttentional(5, 3, 0, 1, 1))

SampleSubthresholdSuspendedEngine ==
  MkEngineState(MkDiscrepancy(0, 2, 1), MkPerceptive("pos"), MkSubjective("neg", TRUE), MkAttentional(5, 3, 0, 1, 1))

SampleVeilleStepStart ==
  MkEngineState(MkDiscrepancy(5, 2, 1), MkPerceptive("zero"), MkSubjective("zero", FALSE), MkAttentional(0, 2, 0, 1, 1))

SampleConsternationEngine ==
  MkEngineState(MkDiscrepancy(6, 2, 1), MkPerceptive("pos"), MkSubjective("neg", TRUE), MkAttentional(5, 3, 1, 1, 3))

SampleEngineStates == {
  DefaultEngineState,
  SampleSurpriseEngine,
  SampleColereEngine,
  SampleNeutralSuspendedEngine,
  SampleSubthresholdSuspendedEngine,
  SampleVeilleStepStart,
  SampleConsternationEngine,
  MkEngineState(MkDiscrepancy(0, 2, 1), MkPerceptive("neg"), MkSubjective("neg", FALSE), MkAttentional(3, 3, 1, 2, 2)),
  MkEngineState(MkDiscrepancy(1, 2, 1), MkPerceptive("neg"), MkSubjective("zero", FALSE), MkAttentional(0, 2, 0, 1, 1)),
  MkEngineState(MkDiscrepancy(3, 2, 1), MkPerceptive("pos"), MkSubjective("pos", FALSE), MkAttentional(0, 2, 0, 1, 1)),
  MkEngineState(MkDiscrepancy(3, 2, 1), MkPerceptive("zero"), MkSubjective("pos", FALSE), MkAttentional(0, 2, 0, 1, 1)),
  MkEngineState(MkDiscrepancy(3, 2, 1), MkPerceptive("neg"), MkSubjective("pos", FALSE), MkAttentional(2, 2, 1, 3, 3))
} \cup {WitnessEngineForPoint(All176Entries[i].point) : i \in 1..40}

SampleDiscSet == {
  MkDiscrepancy(0, 2, 1), MkDiscrepancy(1, 2, 1), MkDiscrepancy(2, 2, 1),
  MkDiscrepancy(0, 1, 1), MkDiscrepancy(5, 2, 1), MkDiscrepancy(3, 4, 2)
}

RepresentativePoints == {
  MkPoint(0, 0, 0), MkPoint(0, 0, 1), MkPoint(0, 0, 2), MkPoint(0, 0, 3),
  MkPoint(0, 2, 2), MkPoint(2, 0, 2), MkPoint(-1, 1, 2), MkPoint(1, -1, 2),
  MkPoint(-1, 3, 3), MkPoint(3, -1, 3), MkPoint(-2, 4, 4), MkPoint(5, -7, 7)
}

ValidNodes == {
  MkProtoNode(0, 0), MkProtoNode(2, 0), MkProtoNode(-2, 0),
  MkProtoNode(0, 2), MkProtoNode(0, -2),
  MkProtoNode(1, 1), MkProtoNode(1, -1), MkProtoNode(-1, 1), MkProtoNode(-1, -1)
}

SmallKernelSet == {
  \* Standard active kernel (scale=4)
  MkKernelParams(4, 3, 3, 0, 0, 2, 2, 1, 2, 2, 1),
  \* Free equal-rate Lyapunov kernel (scale=4)
  MkKernelParams(4, 2, 2, 0, 0, 2, 2, 0, 2, 2, 0),
  MkKernelParams(4, 1, 1, 0, 0, 1, 1, 0, 2, 2, 0),
  \* Passive extinction (eps=0, chi=0, deltaA=1)
  MkKernelParams(4, 2, 2, 1, 1, 2, 2, 0, 2, 2, 0),
  \* Epistemic rigidity (rho=0, deltaA=0)
  MkKernelParams(4, 0, 2, 0, 1, 2, 2, 1, 2, 2, 1),
  \* Pragmatic helplessness (kappa=0, deltaC=0)
  MkKernelParams(4, 2, 0, 1, 0, 2, 2, 1, 2, 2, 1),
  \* Perseveration trap (eps=0, gammaA=0, gammaC=0)
  MkKernelParams(4, 2, 2, 1, 1, 0, 0, 0, 2, 2, 0),
  \* Max epsilon unreachability (eps=scale, deltaA=0)
  MkKernelParams(4, 2, 2, 0, 1, 2, 2, 4, 2, 2, 2),
  \* Rational-equivalent default profile (scale=20)
  DefaultKernelParams20
}

SmallCircStates == {
  DefaultCircularCircuitState,
  MkCircularState(2, TRUE, FALSE, 1, TRUE, 0, 1, 1, MkAttentional(2, 1, 0, 1, 1)),
  MkCircularState(0, TRUE, FALSE, 3, TRUE, 0, 1, 1, MkAttentional(2, 1, 1, 2, 2)),
  MkCircularState(3, TRUE, TRUE,  2, TRUE, 0, 2, 1, MkAttentional(3, 2, 1, 1, 3))
}

SmallUnifiedParams == {
  [halfScale |-> 4, lambdaNum |-> 0, etaScaled |-> 2, betaAtt |-> 1, alphaCharge |-> 2, sigmoidK |-> 2, zMax |-> 7],
  [halfScale |-> 4, lambdaNum |-> 4, etaScaled |-> 3, betaAtt |-> 2, alphaCharge |-> 3, sigmoidK |-> 4, zMax |-> 7],
  [halfScale |-> 4, lambdaNum |-> 6, etaScaled |-> 3, betaAtt |-> 2, alphaCharge |-> 4, sigmoidK |-> 3, zMax |-> 7],
  [halfScale |-> 5, lambdaNum |-> 8, etaScaled |-> 6, betaAtt |-> 2, alphaCharge |-> 5, sigmoidK |-> 1, zMax |-> 7]
}

-----------------------------------------------------------------------------
(* 113e theoreme : all176Entries_antagonist_inverts_hedonic_polarity *)
-----------------------------------------------------------------------------
Thm_all176Entries_antagonist_inverts_hedonic_polarity ==
  \A i \in 1..Len(All176Entries) :
    LET pt == All176Entries[i].point
        ant == AntagonistPoint(pt)
    IN ComputeHedonicPolarity(ant.x, ant.y) = HedonicPolarityInvert(ComputeHedonicPolarity(pt.x, pt.y))

-----------------------------------------------------------------------------
(* Conjonction des 113 theoremes nommes *)
-----------------------------------------------------------------------------
All7_PredictiveEngine ==
  /\ Thm_polarity_invert_involutive
  /\ Thm_coupling_regime_partition
  /\ Thm_feedbackUpdate_couples_gradients(SampleEngineStates)
  /\ Thm_inferential_loop_covers_interfaces
  /\ Thm_feedbackUpdateWeighted_couples_precision({DefaultEngineState, SampleSurpriseEngine})
  /\ Thm_engineStep_remanence(SampleEngineStates)
  /\ Thm_engineStep_phase_progression(SampleEngineStates)

All23_CoreAffect ==
  /\ Thm_engine_induces_valid_core_affect(SampleEngineStates)
  /\ Thm_z2_budget_conservation
  /\ Thm_axial_to_diagonal_reallocation
  /\ Thm_dissipationStep_valid(All176Points)
  /\ Thm_dissipationStep_fixed_iff(All176Points)
  /\ Thm_dissipation_strictly_decreases(All176Points)
  /\ Thm_remanence_preserves_state(SampleDiscSet, RepresentativePoints)
  /\ Thm_cooperative_step_leaves_crown(All176Points)
  /\ Thm_deployCouplingWithPrecision_valid(0..3, 1..4)
  /\ Thm_neutral_coupling_without_suspension_yields_veille(SampleEngineStates)
  /\ Thm_neutral_or_subthreshold_with_suspension_yields_central(SampleEngineStates)
  /\ Thm_descending_suspension_yields_central_operator(SampleEngineStates)
  /\ Thm_central_z_ge2_requires_descending_suspension(SampleEngineStates, 0..3)
  /\ Thm_deployCouplingWithPrecision_budget_conservation(0..3, 1..4)
  /\ Thm_dual_engaged_yields_diagonal_z2_precision(1..4)
  /\ Thm_symmetric_precision_never_lateral(SampleEngineStates)
  /\ Thm_projectToCoreAffect_surjective(All176Points)
  /\ Thm_engineStep_canonical_trajectory(SampleEngineStates)
  /\ Thm_engineStep_surprise_to_crown(SampleEngineStates)
  /\ Thm_anticipation_short_circuits_to_veille
  /\ Thm_dissipation_from_ge2_never_visits_surprise(All176Points)
  /\ Thm_dissipationPotential_short_circuit_jump
  /\ Thm_dissipation_reaches_veille(All176Points)

All13_AffectiveMatrix ==
  /\ Thm_hedonicPolarity_invert_involutive
  /\ Thm_x_positive_determines_positive_valence(-6..6)
  /\ Thm_x_negative_determines_negative_valence(-6..6)
  /\ Thm_antagonistPoint_preserves_validity(All176Points)
  /\ Thm_antagonistPoint_involutive(All176Points)
  /\ Thm_contralateral_swaps_amplitudes(All176Points)
  /\ Thm_antagonist_commutes_with_invert(0..3)
  /\ Thm_antagonistPoint_unified(All176Points)
  /\ Thm_antagonist_preserves_validity_in(All176Points \cup {MkPoint(2, 3, 2), MkPoint(-1, -4, 3)})
  /\ Thm_transferUnitYtoX_preserves_sum(All176Points)
  /\ Thm_antagonist_commutes_with_invert_precision(0..3, 1..4)
  /\ Thm_evaluateMatrix_core_antagonist_independent(RepresentativePoints)
  /\ Thm_mapping_independent_antagonist_invariants(RepresentativePoints)

All10_AffectiveTaxonomy ==
  /\ Thm_inventory_176_certified
  /\ Thm_taxonomy_group_exhaustive(All176Points)
  /\ Thm_taxonomy_group_exclusive(All176Points)
  /\ Thm_dominantSector_iff_taxonomicGroup(All176Points)
  /\ Thm_contralateral_group_bindings(All176Points)
  /\ Thm_classifySubsector_correct(-6..6)
  /\ Thm_subsector_exclusive(-4..4)
  /\ Thm_classifySubsector_refines_group(All176Points)
  /\ Thm_classifySubsector_determines_valence(-6..6)
  /\ Thm_end_to_end_coherence(SampleEngineStates)

All10_AffectiveDynamics ==
  /\ DepthKernelLawsOk(ValidPointsUpToZ7)
  /\ Thm_canonicalDepthKernel_reaches_crown(ValidPointsUpToZ7)
  /\ Thm_canonicalDepthKernel_reaches_lateral(ValidPointsUpToZ7)
  /\ Thm_lateral_reachable(ValidPointsUpToZ7)
  /\ Thm_lateral_reachable_from_surprise(ValidPointsUpToZ7)
  /\ Thm_canonicalDepthKernel_colere_bifurcates
  /\ Thm_canonicalDepthKernel_axial_instability_p2
  /\ Thm_canonicalDepthKernel_outgoingWeight_pos(
       {p \in ValidPointsUpToZ7 : p.z <= 4})
  /\ Thm_classifyTaxonomicGroup_unique_maximizer(All176Points)
  /\ Thm_classifyTaxonomicGroup_maximizes_membership(All176Points)
  /\ Thm_lateral_has_overlapping_attractors(All176Points)

All8_Lexicon176 ==
  /\ Thm_all176Entries_length
  /\ Thm_all176Entries_geometrically_valid
  /\ Thm_all176Entries_z_bounds
  /\ Thm_all176Entries_unique_points
  /\ Thm_all176Entries_complete
  /\ Thm_all176Entries_deterministically_reachable
  /\ Thm_all176Entries_reachable_by_engine
  /\ Thm_all176Entries_witness_check

All41_PredictiveCircuit ==
  /\ Thm_circuit_covers_interfaces_both_sides
  /\ Thm_circuit_refines_inferential_ops
  /\ Thm_phiL1_left_inv
  /\ Thm_phiL1_right_inv(ValidNodes)
  /\ Thm_phiL1_agrees_with_deployZ2
  /\ Thm_crossingII_is_transpose_of_crossingI
  /\ Thm_routeToSubjective_injective
  /\ Thm_routeToPerceptive_injective
  /\ Thm_projectPerceptible_valid(0..4, 1..4)
  /\ Thm_projectPerceptible_z2_matches_phiL1(1..4)
  /\ Thm_projectPerceptible_neutral_elevates_to_central(2..5, 1..3)
  /\ Thm_attentional_bottleneck_sum_active
  /\ Thm_circuitRowSum_exact(SmallKernelSet)
  /\ Thm_veille_absorbing_free(SmallKernelSet)
  /\ Thm_lyapunov_monotone_free(SmallKernelSet)
  /\ Thm_lyapunov_strict_descent_witness(SmallKernelSet)
  /\ Thm_lyapunov_expected_drift_constant(SmallKernelSet \ {DefaultKernelParams20})
  /\ Thm_axial_peur_bifurcates_p2(SmallKernelSet)
  /\ Thm_veille_reaches_all_one_step(SmallKernelSet)
  /\ Thm_all_reach_veille_two_steps(SmallKernelSet)
  /\ Thm_veille_unreachable_when_eps_max(SmallKernelSet)
  /\ Thm_circularCycle_veille_fixed_point
  /\ Thm_circularCycle_reduces_total_discrepancy(SmallCircStates)
  /\ Thm_lyapunov_drift_charge_with_passive_extinction(SmallKernelSet)
  /\ Thm_p1_without_p2_eps_independent(0..4)
  /\ Thm_epistemic_rigidity_traps_charge_slice(SmallKernelSet)
  /\ Thm_pragmatic_helplessness_traps_charge_slice(SmallKernelSet)
  /\ Thm_perseveration_traps_discharge_free(SmallKernelSet)
  /\ Thm_passive_extinction_zero_relief
  /\ Thm_active_resolution_beats_passive_extinction(SmallUnifiedParams, {0, 4, 10}, {2, 4})
  /\ Thm_charge_accumulator_bounded(SmallUnifiedParams)
  /\ Thm_nextStratumR5_le_zMax(SmallUnifiedParams \cup {DefaultUnifiedDynamicsParams}, 0..9, {0, 500, 1500, 3000})
  /\ Thm_nextStratumR5_short_circuits_z2_to_veille({DefaultUnifiedDynamicsParams}, {0, 100, 500, 699})
  /\ Thm_nextStratumR5_from_ge2_never_visits_surprise(SmallUnifiedParams \cup {DefaultUnifiedDynamicsParams}, 2..8, {0, 100, 1000, 2500})
  /\ Thm_symmetricSigmoid_sum({4, 5, 500}, {1, 100}, {-100, -10, 0, 10, 100})
  /\ Thm_symmetricSigmoid_pos({4, 5, 500}, {1, 100}, {-100, -10, 0, 10, 100})
  /\ Thm_symmetricSigmoid_neg({4, 5, 500}, {1, 100}, {-100, -10, 0, 10, 100})
  /\ Thm_precisionShare_double_charge_cancels_alpha({DefaultUnifiedDynamicsParams}, 0..3)
  /\ Thm_projectUnifiedState_valid({DefaultUnifiedDynamicsParams}, 0..4, {10, 90})
  /\ Thm_projectUnifiedState_crown_budget({DefaultUnifiedDynamicsParams}, 2..5, {10, 90})
  /\ Thm_projectUnifiedState_reaches_lateral_consternation

-----------------------------------------------------------------------------
(* Parite bit-a-bit des 11 blocs d'evaluation concrete (#eval <-> Compute) *)
-----------------------------------------------------------------------------
EvalBlock01 ==
  LET b == RunCartograffectPipeline(DefaultEngineState) IN
  /\ b.matrix.core = MkPoint(0, 0, 0)
  /\ b.stratum = "Z0_pointDeVeille"
  /\ b.group = "operateurCentral"

EvalBlock02 ==
  LET b == RunCartograffectPipeline(SampleSurpriseEngine) IN
  /\ b.matrix.core = MkPoint(0, 0, 1)
  /\ b.stratum = "Z1_saillancePerceptive"
  /\ b.matrix.activation = "ascendingRupture"

EvalBlock03 ==
  LET b == RunCartograffectPipeline(SampleColereEngine) IN
  /\ b.matrix.core = MkPoint(-1, 1, 2)
  /\ b.matrix.antagonist = MkPoint(1, -1, 2)
  /\ b.group = "groupeColere"
  /\ b.subsector = "diagonalAnger"
  /\ b.antagonistGroup = "groupeCalme"
  /\ b.antagonistSubsector = "diagonalCalm"
  /\ b.matrix.energyRegime = "ergotropicCompensation"
  /\ b.matrix.valence = "negative"

EvalBlock04 ==
  LET s0 == SampleVeilleStepStart
      s1 == EngineStep(s0)
      s2 == EngineStep(s1)
      s3 == EngineStep(s2)
  IN /\ ProjectToCoreAffect(SampleNeutralSuspendedEngine) = MkPoint(0, 0, 2)
     /\ ProjectToCoreAffect(SampleSubthresholdSuspendedEngine) = MkPoint(0, 0, 2)
     /\ ProjectToCoreAffect(s0) = MkPoint(0, 0, 0)
     /\ ProjectToCoreAffect(s1) = MkPoint(0, 0, 1)
     /\ ProjectToCoreAffect(s2) = MkPoint(0, 0, 2)
     /\ ProjectToCoreAffect(s3) = MkPoint(0, 2, 2)

EvalBlock05 ==
  LET p2 == MkPoint(0, 0, 2)
      pcol == MkPoint(-1, 1, 2)
      pcon == MkPoint(-1, 3, 3)
  IN /\ DissipationStep(p2) = MkPoint(0, 0, 0)
     /\ DissipationPotential(p2) - DissipationPotential(DissipationStep(p2)) = 4
     /\ DissipationStep(pcol) = MkPoint(0, 0, 2)
     /\ DissipationStep(DissipationStep(pcol)) = MkPoint(0, 0, 0)
     /\ DissipationStep(pcon) = MkPoint(0, 0, 3)
     /\ DissipationStep(DissipationStep(pcon)) = MkPoint(0, 0, 2)
     /\ RepeatDissipation(3, pcon) = MkPoint(0, 0, 0)

EvalBlock06 ==
  LET b == RunCartograffectPipeline(SampleConsternationEngine) IN
  /\ b.matrix.core = MkPoint(-1, 3, 3)
  /\ b.geometry = "lateral"
  /\ b.group = "groupeJoie"
  /\ b.subsector = "lateralDefensiveUrgency"
  /\ b.matrix.valence = "negative"
  /\ b.matrix.antagonist = MkPoint(3, -1, 3)

EvalBlock07 ==
  LET src == MkPoint(-1, 1, 2) IN
  /\ CanonicalDepthWeight(src, MkPoint(-2, 2, 3)) = 2
  /\ CanonicalDepthWeight(src, MkPoint(-1, 3, 3)) = 1
  /\ CanonicalDepthWeight(src, MkPoint(-3, 1, 3)) = 1
  /\ OutgoingWeight(src) = 4
  /\ CanonicalDepthWeight(AntagonistPoint(src), AntagonistPoint(MkPoint(-1, 3, 3))) = 1

EvalBlock08 ==
  LET c == MkPoint(-1, 3, 3)
      e == MkPoint(-2, 4, 4)
  IN /\ AttractorMembership(c, "groupeJoie") = 4
     /\ AttractorMembership(c, "groupeColere") = 2
     /\ AttractorMembership(c, "groupePeur") = 1
     /\ ClassifyTaxonomicGroup(c) = "groupeJoie"
     /\ AttractorMembership(e, "groupeJoie") = 6
     /\ AttractorMembership(e, "groupeColere") = 4
     /\ AttractorMembership(e, "groupePeur") = 2
     /\ ClassifyTaxonomicGroup(e) = "groupeJoie"

EvalBlock09 ==
  LET pt == ProjectToCoreAffect(SampleColereEngine)
      ant == AntagonistPoint(pt)
  IN /\ pt = MkPoint(-1, 1, 2)
     /\ ant = MkPoint(1, -1, 2)
     /\ ComputeHedonicPolarity(pt.x, pt.y) = "negative"
     /\ HedonicPolarityInvert(ComputeHedonicPolarity(pt.x, pt.y)) = "positive"

EvalBlock10 ==
  /\ CrossingIPos(MkCoupling("zero", "zero")) = <<0, 2>>
  /\ CrossingIIPos(MkCoupling("zero", "zero")) = <<2, 0>>
  /\ ProjectPerceptible(MkCoupling("neg", "pos"), 3, 1, 3, TRUE) = MkPoint(-1, 3, 3)
  /\ CircuitRowSum(DefaultKernelParams20, MkCoupling("neg", "zero")) = 256000000
  /\ CircuitWeight(DefaultKernelParams20, MkCoupling("neg", "zero"), MkCoupling("neg", "pos")) = 6496000
  /\ CircuitRowSumBig(DefaultKernelParams100, MkCoupling("neg", "zero")) = <<4000000, 0>>
  /\ CircuitWeightBig(DefaultKernelParams100, MkCoupling("neg", "zero"), MkCoupling("neg", "pos")) = <<101500, 0>>
  /\ Op3CrossingIPoint(DefaultCircularCircuitState) = MkPoint(0, 0, 0)

EvalBlock11 ==
  LET up == DefaultUnifiedDynamicsParams IN
  /\ NextChargeAccumulator(up, 1000, 500, 500, MkCoupling("neg", "zero"), MkCoupling("pos", "zero")) = 700
  /\ NextChargeAccumulator(up, 1000, 500, 500, MkCoupling("neg", "zero"), MkCoupling("zero", "zero")) = 1300
  /\ NextStratumR5(up, 2, 100) = 0
  /\ NextStratumR5(up, 3, 100) = 2
  /\ ProjectUnifiedState(up, MkCoupling("neg", "pos"), 3, 10, 90, TRUE) = MkPoint(-1, 3, 3)
  /\ PrecisionShares(up, 10, 90, MkCoupling("neg", "neg")) = <<193, 807>>

ASSUME
  /\ All7_PredictiveEngine
  /\ All23_CoreAffect
  /\ All13_AffectiveMatrix
  /\ All10_AffectiveTaxonomy
  /\ All10_AffectiveDynamics
  /\ All8_Lexicon176
  /\ All41_PredictiveCircuit
  /\ Thm_all176Entries_antagonist_inverts_hedonic_polarity
  /\ EvalBlock01 /\ EvalBlock02 /\ EvalBlock03 /\ EvalBlock04
  /\ EvalBlock05 /\ EvalBlock06 /\ EvalBlock07 /\ EvalBlock08
  /\ EvalBlock09 /\ EvalBlock10 /\ EvalBlock11

VARIABLE stepDone

Init == stepDone = TRUE
Next == stepDone' = stepDone
Spec == Init /\ [][Next]_stepDone

Inv_All113Theorems ==
  /\ All7_PredictiveEngine
  /\ All23_CoreAffect
  /\ All13_AffectiveMatrix
  /\ All10_AffectiveTaxonomy
  /\ All10_AffectiveDynamics
  /\ All8_Lexicon176
  /\ All41_PredictiveCircuit
  /\ Thm_all176Entries_antagonist_inverts_hedonic_polarity

Inv_All11EvalBlocks ==
  /\ EvalBlock01 /\ EvalBlock02 /\ EvalBlock03 /\ EvalBlock04
  /\ EvalBlock05 /\ EvalBlock06 /\ EvalBlock07 /\ EvalBlock08
  /\ EvalBlock09 /\ EvalBlock10 /\ EvalBlock11

=============================================================================
