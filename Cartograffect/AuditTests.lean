/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later
Author: Manuel Cabelguen
-/

import Cartograffect.PredictiveEngine
import Cartograffect.CoreAffect
import Cartograffect.AffectiveMatrix
import Cartograffect.AffectiveDynamics
import Cartograffect.AffectiveTaxonomy
import Cartograffect.PredictiveCircuit
import Cartograffect.OperantFactorization
import Cartograffect.EndToEndBridge

namespace Cartograffect.Audit

open PredictiveEngine
open CoreAffect
open AffectiveMatrix
open AffectiveDynamics
open AffectiveTaxonomy
open PredictiveCircuit
open OperantFactorization
open EndToEndBridge

/-!
# Audit axiomatique exhaustif et tests d'évaluation du cœur normatif v3.0

Ce fichier audite via `#print axioms` **l'intégralité dédupliquée des théorèmes exportés**
par les 8 modules du cœur normatif v3.0 (`PredictiveEngine`, `CoreAffect`, `AffectiveMatrix`,
`AffectiveTaxonomy`, `AffectiveDynamics`, `PredictiveCircuit`, `OperantFactorization`,
`EndToEndBridge`), sans dépendance envers l'annexe exploratoire `Lexicon176` et sans aucun
alias compté en double (`lateral_reachable` et `all176Entries_reachable_by_engine` supprimés).
-/

/-!
## PHASE 1 : Audit Axiomatique exhaustif (#print axioms) des 8 modules du noyau v3.0
-/

-- 1. Module `Cartograffect.PredictiveEngine` (14 théorèmes exportés)
#print axioms engineStep_of_salient_neutral
#print axioms engineStep_of_salient_nonneutral_unsuspended
#print axioms engineStep_of_salient_nonneutral_suspended_unengaged
#print axioms Polarity.invert_involutive
#print axioms Polarity.toRegime_neutral_iff
#print axioms single_neutral_not_global_neutral
#print axioms allCouplings_card
#print axioms mem_allCouplings
#print axioms coupling_regime_partition
#print axioms feedbackUpdate_couples_gradients
#print axioms feedbackUpdateWeighted_couples_precision
#print axioms inferential_loop_covers_interfaces
#print axioms engineStep_remanence
#print axioms engineStep_phase_progression

-- 2. Module `Cartograffect.CoreAffect` (37 théorèmes exportés)
#print axioms crownRadius_eq_formula
#print axioms natAbs_neg_ofNat
#print axioms natAbs_pos_ofNat
#print axioms apportionRay_bounds
#print axioms apportionRay_swap
#print axioms apportionRay_symm
#print axioms apportionRay_z2
#print axioms apportionRay_exact
#print axioms deployCouplingWithPrecision_symm_eq
#print axioms deployCouplingAtDepth_valid
#print axioms deployCouplingWithPrecision_valid
#print axioms engine_induces_valid_core_affect
#print axioms neutral_coupling_without_suspension_yields_veille
#print axioms neutral_or_subthreshold_with_suspension_yields_central
#print axioms descending_suspension_yields_central_operator
#print axioms central_z_ge2_requires_descending_suspension
#print axioms z2_budget_conservation
#print axioms single_engaged_yields_axial_z2
#print axioms dual_engaged_yields_diagonal_z2
#print axioms axial_to_diagonal_reallocation
#print axioms deployCouplingWithPrecision_budget_conservation
#print axioms dual_engaged_yields_diagonal_z2_precision
#print axioms symmetric_precision_never_lateral
#print axioms projectToCoreAffect_independent_of_activation
#print axioms projectToCoreAffect_surjective
#print axioms engineStep_canonical_trajectory
#print axioms engineStep_surprise_to_crown
#print axioms dissipationStep_valid
#print axioms anticipation_short_circuits_to_veille
#print axioms dissipation_from_ge2_never_visits_surprise
#print axioms pointDeVeille_is_fixed_point
#print axioms dissipationStep_fixed_iff
#print axioms dissipation_strictly_decreases
#print axioms dissipationPotential_short_circuit_jump
#print axioms dissipation_reaches_veille
#print axioms remanence_preserves_state
#print axioms cooperative_step_leaves_crown

-- 3. Module `Cartograffect.AffectiveMatrix` (22 théorèmes exportés)
#print axioms HedonicPolarity.invert_involutive
#print axioms x_positive_determines_positive_valence
#print axioms x_negative_determines_negative_valence
#print axioms PrimaryCrownPrototype.valid_on_crown
#print axioms antagonistPoint_preserves_z
#print axioms antagonistPoint_preserves_displacementSum
#print axioms antagonistPoint_preserves_validity
#print axioms antagonistPoint_involutive
#print axioms antagonistPoint_fixed_iff_central
#print axioms contralateral_swaps_amplitudes
#print axioms canonical_antagonist_examples
#print axioms antagonist_commutes_with_invert
#print axioms antagonist_commutes_with_invert_precision
#print axioms antagonistPoint_off_axis
#print axioms antagonistPoint_piecewise
#print axioms antagonist_preserves_validity_in
#print axioms transferUnitXtoY_preserves_sum
#print axioms transferUnitYtoX_preserves_sum
#print axioms antagonistPoint_inverts_hedonic_polarity
#print axioms autonomousActivation_decoupled_from_core
#print axioms evaluateMatrix_core_antagonist_independent
#print axioms mapping_independent_antagonist_invariants

-- 4. Module `Cartograffect.AffectiveTaxonomy` (16 théorèmes exportés)
#print axioms canonical_crown_counts_certified
#print axioms classifyTaxonomicGroup_correct
#print axioms taxonomy_group_exhaustive
#print axioms taxonomy_group_exclusive
#print axioms matchesTaxonomicGroup_iff
#print axioms dominantSector_iff_taxonomicGroup
#print axioms contralateral_group_bindings
#print axioms classifySubsector_correct
#print axioms subsector_exclusive
#print axioms matchesSubsector_iff
#print axioms matchesSubsector_toTaxonomicGroup
#print axioms classifySubsector_refines_group
#print axioms matchesSubsector_toHedonicPolarity
#print axioms classifySubsector_determines_valence
#print axioms end_to_end_coherence
#print axioms pipeline_decouples_point_and_activation

-- 5. Module `Cartograffect.AffectiveDynamics` (13 théorèmes exportés)
#print axioms isValidCoreAffectB_iff
#print axioms canonicalDepthKernel_reaches_crown
#print axioms canonicalDepthKernel_reaches_lateral
#print axioms canonicalDepthKernel_crown_from_surprise
#print axioms lateral_reachable_from_surprise
#print axioms canonicalDepthKernel_colere_bifurcates
#print axioms canonicalDepthKernel_axial_instability_p2
#print axioms mem_stratumPoints_of_valid
#print axioms DepthTransitionKernel.outgoingWeight_pos_of_witness
#print axioms canonicalDepthKernel_outgoingWeight_pos
#print axioms classifyTaxonomicGroup_unique_maximizer
#print axioms classifyTaxonomicGroup_maximizes_membership
#print axioms lateral_has_overlapping_attractors

-- 6. Module `Cartograffect.PredictiveCircuit` (53 théorèmes exportés)
#print axioms allCircuitOperations_card
#print axioms mem_allCircuitOperations
#print axioms circuit_covers_interfaces_both_sides
#print axioms circuit_refines_inferential_ops
#print axioms circuit_preserves_carrier
#print axioms unique_agent_perceptible_crossing
#print axioms phiL1_valid
#print axioms phiL1_l1Norm_active
#print axioms phiL1_left_inv
#print axioms phiL1_right_inv
#print axioms phiL1_agrees_with_deployZ2
#print axioms crossingII_is_transpose_of_crossingI
#print axioms routeToSubjective_injective
#print axioms routeToPerceptive_injective
#print axioms projectPerceptible_valid
#print axioms projectPerceptible_z2_matches_phiL1
#print axioms projectPerceptible_neutral_elevates_to_central
#print axioms attentional_bottleneck_sum_active
#print axioms lyapunovPotential_zero_iff
#print axioms lyapunovPotential_le_four
#print axioms lyapunovPotential_max_iff
#print axioms circuitRowSum_exact
#print axioms veille_absorbing_free
#print axioms lyapunov_monotone_free
#print axioms lyapunov_strict_descent_witness
#print axioms lyapunov_expected_drift_constant
#print axioms lyapunov_drift_charge_with_passive_extinction
#print axioms p1_without_p2_eps_independent
#print axioms axial_peur_bifurcates_p2
#print axioms axial_tristesse_and_discharge_asymmetry_p2
#print axioms veille_self_loop_ergodic
#print axioms veille_reaches_all_one_step
#print axioms all_reach_veille_two_steps
#print axioms veille_unreachable_when_eps_max
#print axioms epistemic_rigidity_traps_charge_slice
#print axioms pragmatic_helplessness_traps_charge_slice
#print axioms perseveration_traps_discharge_free
#print axioms circularCycle_emits_valid_core_affect
#print axioms circularCycle_veille_fixed_point
#print axioms circularCycle_reduces_total_discrepancy
#print axioms passive_extinction_zero_relief
#print axioms active_resolution_beats_passive_extinction
#print axioms charge_accumulator_bounded
#print axioms nextStratumR5_le_zMax
#print axioms nextStratumR5_short_circuits_z2_to_veille
#print axioms nextStratumR5_from_ge2_never_visits_surprise
#print axioms symmetricSigmoid_sum
#print axioms symmetricSigmoid_pos
#print axioms symmetricSigmoid_neg
#print axioms precisionShare_double_charge_cancels_alpha
#print axioms projectUnifiedState_valid
#print axioms projectUnifiedState_crown_budget
#print axioms projectUnifiedState_reaches_lateral_agentic_confront

-- 7. Module `Cartograffect.OperantFactorization` (8 théorèmes exportés)
#print axioms manhattanDistXY_origin
#print axioms rolls_factorization_law
#print axioms rolls_contingencies_z2_bound
#print axioms energyRegime_matches_rolls_contingency
#print axioms antagonist_rolls_symmetry_z2
#print axioms axial_poles_bridge_rolls_pairs
#print axioms axial_poles_pre_contingency
#print axioms z2_rolls_bijection_2x2

-- 8. Module `Cartograffect.EndToEndBridge` (6 théorèmes exportés)
#print axioms circuit_coupling_z2_contingency_bridge
#print axioms triggerSecondaryGradient_enters_z2_contingency
#print axioms p2_negative_charge_enters_z2_contingencies
#print axioms vertical_operators_obey_stepwise_2a
#print axioms unified_and_circular_to_taxonomy_coherence
#print axioms full_end_to_end_v3_coherence

/-!
## PHASE 2 : Tests d'Inhabitation et Évaluation Concrète (#eval) — Alignement v3.0
-/

/- 1. Évaluation de l'état basal par défaut : Point de Veille (0, 0, 0) -/
#eval (runCartograffectPipeline default).matrix.core.point
#eval (runCartograffectPipeline default).stratum
#eval (runCartograffectPipeline default).group

/-- 2. Évaluation d'un écart saillant sous le seuil attentionnel avec canal autonome A = 7 : Surprise (0, 0, 1) -/
def sampleSurpriseEngine : PredictiveEngineState := {
  discrepancy          := { magnitude := 5, sensoryThreshold := 2, resorptionThreshold := 1, h_hysteresis := by decide }
  perceptive           := { controleGradient := .pos }
  subjective           := { attenteGradient := .neg, descendingSuspension := false }
  attentional          := { allocatedPrecision := 1, engagementThreshold := 3, persistenceDepth := 0 }
  autonomousActivation := 7
}

#eval (runCartograffectPipeline sampleSurpriseEngine).matrix.core.point
#eval (runCartograffectPipeline sampleSurpriseEngine).stratum
#eval (runCartograffectPipeline sampleSurpriseEngine).matrix.autonomousActivation

/-- 3. Option 1A : Couplage engagé (A-, C+) à Z = 2 : Colère (-1, +1, 2) [affrontement agentique] et son antagoniste Calme (+1, -1, 2) [accommodation] -/
def sampleColereEngine : PredictiveEngineState := {
  discrepancy          := { magnitude := 5, sensoryThreshold := 2, resorptionThreshold := 1, h_hysteresis := by decide }
  perceptive           := { controleGradient := .pos }
  subjective           := { attenteGradient := .neg, descendingSuspension := true }
  attentional          := { allocatedPrecision := 5, engagementThreshold := 3, persistenceDepth := 0 }
  autonomousActivation := 9
}

#eval (runCartograffectPipeline sampleColereEngine).matrix.core.point
#eval (runCartograffectPipeline sampleColereEngine).matrix.antagonist.point
#eval (runCartograffectPipeline sampleColereEngine).group
#eval (runCartograffectPipeline sampleColereEngine).subsector
#eval (runCartograffectPipeline sampleColereEngine).antagonistGroup
#eval (runCartograffectPipeline sampleColereEngine).antagonistSubsector
#eval (runCartograffectPipeline sampleColereEngine).matrix.energyRegime
#eval (runCartograffectPipeline sampleColereEngine).matrix.valence
#eval (runCartograffectPipeline sampleColereEngine).matrix.autonomousActivation

/-- 4. Suspension descendante R5 et trajectoire pas-à-pas `engineStep` -/
def sampleNeutralSuspendedEngine : PredictiveEngineState := {
  discrepancy := { magnitude := 5, sensoryThreshold := 2, resorptionThreshold := 1, h_hysteresis := by decide }
  perceptive  := { controleGradient := .zero }
  subjective  := { attenteGradient := .zero, descendingSuspension := true }
  attentional := { allocatedPrecision := 5, engagementThreshold := 3, persistenceDepth := 0, precisionA := 1, precisionC := 1 }
}

def sampleSubthresholdSuspendedEngine : PredictiveEngineState := {
  discrepancy := { magnitude := 0, sensoryThreshold := 2, resorptionThreshold := 1, h_hysteresis := by decide }
  perceptive  := { controleGradient := .pos }
  subjective  := { attenteGradient := .neg, descendingSuspension := true }
  attentional := { allocatedPrecision := 5, engagementThreshold := 3, persistenceDepth := 0, precisionA := 1, precisionC := 1 }
}

def sampleVeilleStepStart : PredictiveEngineState := {
  discrepancy := { magnitude := 5, sensoryThreshold := 2, resorptionThreshold := 1, h_hysteresis := by decide }
  perceptive  := { controleGradient := .zero }
  subjective  := { attenteGradient := .zero, descendingSuspension := false }
  attentional := { allocatedPrecision := 0, engagementThreshold := 2, persistenceDepth := 0, precisionA := 1, precisionC := 1 }
}

#eval (runCartograffectPipeline sampleNeutralSuspendedEngine).matrix.core.point
#eval (runCartograffectPipeline sampleSubthresholdSuspendedEngine).matrix.core.point
#eval (projectToCoreAffect sampleVeilleStepStart,
       projectToCoreAffect (engineStep sampleVeilleStepStart),
       projectToCoreAffect (engineStep (engineStep sampleVeilleStepStart)),
       projectToCoreAffect (engineStep (engineStep (engineStep sampleVeilleStepStart))))

-- 5. Option 2a : Court-circuit descendant unique `(0, 0, 2) → (0, 0, 0)` et descente pas-à-pas depuis `(-1, 3, 3)`
#eval dissipationStep ⟨0, 0, 2⟩
#eval (dissipationPotential ⟨0, 0, 2⟩ : Int) - (dissipationPotential (dissipationStep ⟨0, 0, 2⟩) : Int)
#eval (dissipationStep ⟨-1, 1, 2⟩, dissipationStep (dissipationStep ⟨-1, 1, 2⟩))
#eval (dissipationStep ⟨-1, 3, 3⟩, dissipationStep (dissipationStep ⟨-1, 3, 3⟩), Nat.repeat dissipationStep 3 ⟨-1, 3, 3⟩)

/-- 6. Option 1A : Position latérale `(-1, 3, 3)` (affrontement agentique à contrôle dominant, `sectorControlPos`) et `(-1, -3, 3)` (détresse aversive à faible contrôle et A haut, `sectorControlNeg`) -/
def sampleAgenticLateralEngine : PredictiveEngineState := {
  discrepancy          := { magnitude := 6, sensoryThreshold := 2, resorptionThreshold := 1, h_hysteresis := by decide }
  perceptive           := { controleGradient := .pos }
  subjective           := { attenteGradient := .neg, descendingSuspension := true }
  attentional          := { allocatedPrecision := 5, engagementThreshold := 3, persistenceDepth := 1, precisionA := 1, precisionC := 3 }
  autonomousActivation := 8
}

def sampleAversiveLowControlHighA : PredictiveEngineState := {
  discrepancy          := { magnitude := 6, sensoryThreshold := 2, resorptionThreshold := 1, h_hysteresis := by decide }
  perceptive           := { controleGradient := .neg }
  subjective           := { attenteGradient := .neg, descendingSuspension := true }
  attentional          := { allocatedPrecision := 5, engagementThreshold := 3, persistenceDepth := 1, precisionA := 1, precisionC := 3 }
  autonomousActivation := 10
}

#eval (runCartograffectPipeline sampleAgenticLateralEngine).matrix.core.point
#eval (runCartograffectPipeline sampleAgenticLateralEngine).group
#eval (runCartograffectPipeline sampleAgenticLateralEngine).subsector
#eval (runCartograffectPipeline sampleAversiveLowControlHighA).matrix.core.point
#eval (runCartograffectPipeline sampleAversiveLowControlHighA).group
#eval (runCartograffectPipeline sampleAversiveLowControlHighA).subsector
#eval (runCartograffectPipeline sampleAversiveLowControlHighA).matrix.autonomousActivation

-- 7. Option 3b : Asymétrie P2 du noyau `canonicalDepthKernel` (instabilité axiale en Charge négative uniquement)
#eval (canonicalDepthKernel.weight ⟨-2, 0, 2⟩ ⟨-2, 2, 3⟩,
       canonicalDepthKernel.weight ⟨-2, 0, 2⟩ ⟨-4, 0, 3⟩,
       canonicalDepthKernel.weight ⟨0, -2, 2⟩ ⟨2, -2, 3⟩,
       canonicalDepthKernel.weight ⟨0, -2, 2⟩ ⟨0, -4, 3⟩)
#eval (canonicalDepthKernel.weight ⟨2, 0, 2⟩ ⟨2, 2, 3⟩,
       canonicalDepthKernel.weight ⟨0, 2, 2⟩ ⟨2, 2, 3⟩)
#eval canonicalDepthKernel.outgoingWeight ⟨-1, 1, 2⟩

-- 8. Appartenance graduée `attractorMembership` sur groupes fonctionnels neutres (Option 1A)
#eval (attractorMembership ⟨-1, 3, 3⟩ .sectorControlPos,
       attractorMembership ⟨-1, 3, 3⟩ .diagonalAgenticConfront,
       attractorMembership ⟨-1, 3, 3⟩ .sectorExpectationNeg,
       classifyTaxonomicGroup ⟨-1, 3, 3⟩)
#eval (attractorMembership ⟨1, -3, 3⟩ .sectorControlNeg,
       attractorMembership ⟨1, -3, 3⟩ .diagonalAccommodation,
       classifyTaxonomicGroup ⟨1, -3, 3⟩)

/-- 9. Indépendance de `core`, `antagonist` et `autonomousActivation` vis-à-vis de `PhenomenologicalMapping` -/
def invertedPhenomenologicalMapping : PhenomenologicalMapping := {
  expectationFn := fun x =>
    if x < 0 then .epistemicDischarge else if x > 0 then .epistemicCharge else .epistemicNeutral
  controlFn     := fun y =>
    if y < 0 then .pragmaticDischarge else if y > 0 then .pragmaticCharge else .pragmaticNeutral
  valenceFn     := fun x y => (computeValence x y).invert
}

#eval ((evaluateMatrix (evaluateCoreAffect sampleColereEngine) 9 canonicalMapping).core.point,
       (evaluateMatrix (evaluateCoreAffect sampleColereEngine) 9 invertedPhenomenologicalMapping).core.point)
#eval ((evaluateMatrix (evaluateCoreAffect sampleColereEngine) 9 canonicalMapping).valence,
       (evaluateMatrix (evaluateCoreAffect sampleColereEngine) 9 invertedPhenomenologicalMapping).valence)

-- 10. Circuit circulaire à 6 opérateurs (`PredictiveCircuit`) et contingences bornées à `Z = 2`
#eval (crossingIPos ⟨.zero, .zero⟩, crossingIIPos ⟨.zero, .zero⟩)
#eval projectPerceptible ⟨.neg, .pos⟩ 3 1 3 true
#eval circuitRowSum (default : CircuitKernelParams) ⟨.neg, .zero⟩
#eval (diagToContingency ⟨1, 1, 2⟩, diagToContingency ⟨-1, 1, 2⟩, diagToContingency ⟨-1, -1, 2⟩, diagToContingency ⟨1, -1, 2⟩, diagToContingency ⟨2, 2, 3⟩)

-- 11. Loi unifiée (`UnifiedDynamicsParams` avec `zMax = 5` par défaut)
#eval (default : UnifiedDynamicsParams).zMax
#eval (nextChargeAccumulator (default : UnifiedDynamicsParams) 1000 500 500 ⟨.neg, .zero⟩ ⟨.pos, .zero⟩,
       nextChargeAccumulator (default : UnifiedDynamicsParams) 1000 500 500 ⟨.neg, .zero⟩ ⟨.zero, .zero⟩)
#eval (nextStratumR5 (default : UnifiedDynamicsParams) 2 100,
       nextStratumR5 (default : UnifiedDynamicsParams) 3 100)
#eval (projectUnifiedState (default : UnifiedDynamicsParams) ⟨.neg, .pos⟩ 3 10 90 true).point

end Cartograffect.Audit
