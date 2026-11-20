/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
Author: Manuel Cabelguen
-/

import Cartograffect.PredictiveEngine
import Cartograffect.CoreAffect
import Cartograffect.AffectiveMatrix
import Cartograffect.AffectiveDynamics
import Cartograffect.AffectiveTaxonomy
import Cartograffect.Lexicon176
import Cartograffect.PredictiveCircuit

namespace Cartograffect.Audit

open PredictiveEngine
open CoreAffect
open AffectiveMatrix
open AffectiveDynamics
open AffectiveTaxonomy
open Lexicon176
open PredictiveCircuit

/-!
## PHASE 1 : Audit Axiomatique (#print axioms)
-/
#print axioms Polarity.invert_involutive
#print axioms coupling_regime_partition
#print axioms feedbackUpdate_couples_gradients
#print axioms inferential_loop_covers_interfaces
#print axioms engine_induces_valid_core_affect
#print axioms z2_budget_conservation
#print axioms axial_to_diagonal_reallocation
#print axioms dissipationStep_valid
#print axioms dissipationStep_fixed_iff
#print axioms dissipation_strictly_decreases
#print axioms remanence_preserves_state
#print axioms cooperative_step_leaves_crown
#print axioms HedonicPolarity.invert_involutive
#print axioms x_positive_determines_positive_valence
#print axioms x_negative_determines_negative_valence
#print axioms antagonistPoint_preserves_validity
#print axioms antagonistPoint_involutive
#print axioms contralateral_swaps_amplitudes
#print axioms antagonist_commutes_with_invert
#print axioms antagonistPoint_unified
#print axioms antagonist_preserves_validity_in
#print axioms transferUnitYtoX_preserves_sum
#print axioms inventory_176_certified
#print axioms taxonomy_group_exhaustive
#print axioms taxonomy_group_exclusive
#print axioms dominantSector_iff_taxonomicGroup
#print axioms contralateral_group_bindings
#print axioms classifySubsector_correct
#print axioms subsector_exclusive
#print axioms classifySubsector_refines_group
#print axioms classifySubsector_determines_valence
#print axioms end_to_end_coherence
#print axioms Cartograffect.Lexicon176.all176Entries_length
#print axioms Cartograffect.Lexicon176.all176Entries_geometrically_valid
#print axioms Cartograffect.Lexicon176.all176Entries_unique_points
#print axioms Cartograffect.Lexicon176.all176Entries_closed_under_antagonist
#print axioms Cartograffect.Lexicon176.all176Entries_spatial_completeness
#print axioms feedbackUpdateWeighted_couples_precision
#print axioms engineStep_remanence
#print axioms engineStep_phase_progression
#print axioms deployCouplingWithPrecision_valid
#print axioms neutral_coupling_without_suspension_yields_veille
#print axioms neutral_or_subthreshold_with_suspension_yields_central
#print axioms descending_suspension_yields_central_operator
#print axioms central_z_ge2_requires_descending_suspension
#print axioms deployCouplingWithPrecision_budget_conservation
#print axioms dual_engaged_yields_diagonal_z2_precision
#print axioms symmetric_precision_never_lateral
#print axioms projectToCoreAffect_surjective
#print axioms engineStep_canonical_trajectory
#print axioms engineStep_surprise_to_crown
#print axioms anticipation_short_circuits_to_veille
#print axioms dissipation_from_ge2_never_visits_surprise
#print axioms dissipationPotential_short_circuit_jump
#print axioms dissipation_reaches_veille
#print axioms antagonist_commutes_with_invert_precision
#print axioms evaluateMatrix_core_antagonist_independent
#print axioms mapping_independent_antagonist_invariants
#print axioms canonicalDepthKernel_reaches_crown
#print axioms canonicalDepthKernel_reaches_lateral
#print axioms lateral_reachable
#print axioms lateral_reachable_from_surprise
#print axioms canonicalDepthKernel_colere_bifurcates
#print axioms canonicalDepthKernel_axial_instability_p2
#print axioms canonicalDepthKernel_outgoingWeight_pos
#print axioms classifyTaxonomicGroup_unique_maximizer
#print axioms classifyTaxonomicGroup_maximizes_membership
#print axioms lateral_has_overlapping_attractors
#print axioms Cartograffect.Lexicon176.all176Entries_deterministically_reachable
#print axioms Cartograffect.Lexicon176.all176Entries_reachable_by_engine
#print axioms Cartograffect.Lexicon176.all176Entries_witness_check

/-- Théorème 18 (Constructif) : Sur l'intégralité des 176 positions du lexique affectif,
    l'opérateur d'antagonisme (axial, diagonal ou controlatéral) inverse exactement
    la polarité hédonique lexicographique (computeHedonicPolarity). -/
theorem all176Entries_antagonist_inverts_hedonic_polarity :
    all176Entries.all (fun e =>
      let ant := antagonistPoint ⟨e.x, e.y, e.z⟩
      computeHedonicPolarity ant.x ant.y == (computeHedonicPolarity e.x e.y).invert
    ) = true := by
  decide

#print axioms all176Entries_antagonist_inverts_hedonic_polarity
#print axioms circuit_covers_interfaces_both_sides
#print axioms circuit_refines_inferential_ops
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
#print axioms circuitRowSum_exact
#print axioms veille_absorbing_free
#print axioms lyapunov_monotone_free
#print axioms lyapunov_strict_descent_witness
#print axioms lyapunov_expected_drift_constant
#print axioms axial_peur_bifurcates_p2
#print axioms veille_reaches_all_one_step
#print axioms all_reach_veille_two_steps
#print axioms veille_unreachable_when_eps_max
#print axioms circularCycle_veille_fixed_point
#print axioms circularCycle_reduces_total_discrepancy
#print axioms lyapunov_drift_charge_with_passive_extinction
#print axioms p1_without_p2_eps_independent
#print axioms epistemic_rigidity_traps_charge_slice
#print axioms pragmatic_helplessness_traps_charge_slice
#print axioms perseveration_traps_discharge_free
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
#print axioms projectUnifiedState_reaches_lateral_consternation

/-!
## PHASE 2 : Tests d'Inhabitation et Évaluation Concrète (#eval)
-/

/- 1. Évaluation de l'état basal par défaut : Point de Veille (0, 0, 0) -/
#eval (runCartograffectPipeline default).matrix.core.point
#eval (runCartograffectPipeline default).stratum
#eval (runCartograffectPipeline default).group

/-- 2. Évaluation d'un écart saillant sous le seuil attentionnel : Surprise (0, 0, 1) -/
def sampleSurpriseEngine : PredictiveEngineState := {
  discrepancy := { magnitude := 5, sensoryThreshold := 2, resorptionThreshold := 1, h_hysteresis := by decide }
  perceptive  := { controleGradient := .pos }
  subjective  := { attenteGradient := .neg, descendingSuspension := false }
  attentional := { allocatedPrecision := 1, engagementThreshold := 3, persistenceDepth := 0 }
}

#eval (runCartograffectPipeline sampleSurpriseEngine).matrix.core.point
#eval (runCartograffectPipeline sampleSurpriseEngine).stratum
#eval (runCartograffectPipeline sampleSurpriseEngine).matrix.activation

/-- 3. Évaluation d'un couplage engagé (A-, C+) à Z = 2 : Colère (-1, +1, 2) et son antagoniste Calme (+1, -1, 2) -/
def sampleColereEngine : PredictiveEngineState := {
  discrepancy := { magnitude := 5, sensoryThreshold := 2, resorptionThreshold := 1, h_hysteresis := by decide }
  perceptive  := { controleGradient := .pos }
  subjective  := { attenteGradient := .neg, descendingSuspension := true }
  attentional := { allocatedPrecision := 5, engagementThreshold := 3, persistenceDepth := 0 }
}

#eval (runCartograffectPipeline sampleColereEngine).matrix.core.point
#eval (runCartograffectPipeline sampleColereEngine).matrix.antagonist.point
#eval (runCartograffectPipeline sampleColereEngine).group
#eval (runCartograffectPipeline sampleColereEngine).subsector
#eval (runCartograffectPipeline sampleColereEngine).antagonistGroup
#eval (runCartograffectPipeline sampleColereEngine).antagonistSubsector
#eval (runCartograffectPipeline sampleColereEngine).matrix.energyRegime
#eval (runCartograffectPipeline sampleColereEngine).matrix.valence

/-- 4. Résolution R5 : Neutralité globale `(A0, C0)` et état infra-liminaire sous `descendingSuspension = true` projetés en Anticipation `(0, 0, 2)`, et trajectoire `engineStep` -/
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

-- 5. Résolution R5 : Court-circuit direct de la dissipation allostatique `(0, 0, 2) → (0, 0, 0)` et descente depuis `(-1, 3, 3)`
#eval dissipationStep ⟨0, 0, 2⟩
#eval dissipationPotential ⟨0, 0, 2⟩ - dissipationPotential (dissipationStep ⟨0, 0, 2⟩)
#eval (dissipationStep ⟨-1, 1, 2⟩, dissipationStep (dissipationStep ⟨-1, 1, 2⟩))
#eval (dissipationStep ⟨-1, 3, 3⟩, dissipationStep (dissipationStep ⟨-1, 3, 3⟩), Nat.repeat dissipationStep 3 ⟨-1, 3, 3⟩)

/-- 6. Résolution R8 (Voie déterministe) : Atteinte de la position latérale Consternation `(-1, 3, 3)` via `(π_A, π_C) = (1, 3)` en `Z = 3` -/
def sampleConsternationEngine : PredictiveEngineState := {
  discrepancy := { magnitude := 6, sensoryThreshold := 2, resorptionThreshold := 1, h_hysteresis := by decide }
  perceptive  := { controleGradient := .pos }
  subjective  := { attenteGradient := .neg, descendingSuspension := true }
  attentional := { allocatedPrecision := 5, engagementThreshold := 3, persistenceDepth := 1, precisionA := 1, precisionC := 3 }
}

#eval (runCartograffectPipeline sampleConsternationEngine).matrix.core.point
#eval (runCartograffectPipeline sampleConsternationEngine).geometry
#eval (runCartograffectPipeline sampleConsternationEngine).group
#eval (runCartograffectPipeline sampleConsternationEngine).subsector
#eval (runCartograffectPipeline sampleConsternationEngine).matrix.valence
#eval (runCartograffectPipeline sampleConsternationEngine).matrix.antagonist.point

-- 7. Résolution R8 (Voie stochastique) : Transitions du noyau `canonicalDepthKernel` depuis la Colère `(-1, 1, 2)`
#eval canonicalDepthKernel.weight ⟨-1, 1, 2⟩ ⟨-2, 2, 3⟩
#eval canonicalDepthKernel.weight ⟨-1, 1, 2⟩ ⟨-1, 3, 3⟩
#eval canonicalDepthKernel.weight ⟨-1, 1, 2⟩ ⟨-3, 1, 3⟩
#eval canonicalDepthKernel.outgoingWeight ⟨-1, 1, 2⟩
#eval canonicalDepthKernel.weight (antagonistPoint ⟨-1, 1, 2⟩) (antagonistPoint ⟨-1, 3, 3⟩)

-- 8. Résolution R1 : Appartenance graduée `attractorMembership` et chevauchement d'attracteurs sur Consternation `(-1, 3, 3)` et Envie `(-2, 4, 4)`
#eval (attractorMembership ⟨-1, 3, 3⟩ .groupeJoie,
       attractorMembership ⟨-1, 3, 3⟩ .groupeColere,
       attractorMembership ⟨-1, 3, 3⟩ .groupePeur,
       classifyTaxonomicGroup ⟨-1, 3, 3⟩)
#eval (attractorMembership ⟨-2, 4, 4⟩ .groupeJoie,
       attractorMembership ⟨-2, 4, 4⟩ .groupeColere,
       attractorMembership ⟨-2, 4, 4⟩ .groupePeur,
       classifyTaxonomicGroup ⟨-2, 4, 4⟩)

/-- 9. Résolution R3 : Paramétrisation par `PhenomenologicalMapping` alternant l'interprétation sans altérer `core` ni `antagonist` -/
def invertedPhenomenologicalMapping : PhenomenologicalMapping := {
  expectationFn := fun x =>
    if x < 0 then .epistemicDischarge else if x > 0 then .epistemicCharge else .epistemicNeutral
  controlFn     := fun y =>
    if y < 0 then .pragmaticDischarge else if y > 0 then .pragmaticCharge else .pragmaticNeutral
  valenceFn     := fun x y => (computeValence x y).invert
  activationFn  := fun _ => .operatorSuspension
}

#eval ((evaluateMatrix (evaluateCoreAffect sampleColereEngine) canonicalMapping).core.point,
       (evaluateMatrix (evaluateCoreAffect sampleColereEngine) invertedPhenomenologicalMapping).core.point)
#eval ((evaluateMatrix (evaluateCoreAffect sampleColereEngine) canonicalMapping).antagonist.point,
       (evaluateMatrix (evaluateCoreAffect sampleColereEngine) invertedPhenomenologicalMapping).antagonist.point)
#eval ((evaluateMatrix (evaluateCoreAffect sampleColereEngine) canonicalMapping).valence,
       (evaluateMatrix (evaluateCoreAffect sampleColereEngine) invertedPhenomenologicalMapping).valence)

-- 10. Circuit circulaire à 6 opérateurs (`PredictiveCircuit`) : croisements, noyau exact et boucle fermée
#eval (crossingIPos ⟨.zero, .zero⟩, crossingIIPos ⟨.zero, .zero⟩)
#eval projectPerceptible ⟨.neg, .pos⟩ 3 1 3 true
#eval circuitRowSum (default : CircuitKernelParams) ⟨.neg, .zero⟩
#eval circuitWeight (default : CircuitKernelParams) ⟨.neg, .zero⟩ ⟨.neg, .pos⟩
#eval (op3_crossingI_perceptible (default : CircularCircuitState)).2.point

-- 11. Loi unifiée (`UnifiedDynamicsParams`) : R_t actif vs passif, court-circuit R5 et Consternation latérale (-1, 3, 3)
#eval (nextChargeAccumulator (default : UnifiedDynamicsParams) 1000 500 500 ⟨.neg, .zero⟩ ⟨.pos, .zero⟩,
       nextChargeAccumulator (default : UnifiedDynamicsParams) 1000 500 500 ⟨.neg, .zero⟩ ⟨.zero, .zero⟩)
#eval (nextStratumR5 (default : UnifiedDynamicsParams) 2 100,
       nextStratumR5 (default : UnifiedDynamicsParams) 3 100)
#eval (projectUnifiedState (default : UnifiedDynamicsParams) ⟨.neg, .pos⟩ 3 10 90 true).point
#eval precisionShares (default : UnifiedDynamicsParams) 10 90 ⟨.neg, .neg⟩

end Cartograffect.Audit
