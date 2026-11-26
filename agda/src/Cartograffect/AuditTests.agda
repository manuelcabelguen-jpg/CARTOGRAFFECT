{-# OPTIONS --safe --without-K #-}
------------------------------------------------------------------------
-- Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
-- SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
-- Cartograffect.AuditTests: 113th theorem, 130-theorem (+ nominal uniqueness)
-- typechecked manifest across 11 anchor blocks, and 11 concrete computational
-- evaluation blocks (refl parity)
------------------------------------------------------------------------
module Cartograffect.AuditTests where

open import Cartograffect.Prelude
open import Cartograffect.PredictiveEngine
open import Cartograffect.CoreAffect
open import Cartograffect.AffectiveMatrix
open import Cartograffect.AffectiveTaxonomy
open import Cartograffect.AffectiveDynamics
open import Cartograffect.Lexicon176
open import Cartograffect.PredictiveCircuit
open import Cartograffect.OperantFactorization
open import Cartograffect.EndToEndBridge

------------------------------------------------------------------------
-- 1. Audited Theorem #113: all176Entries_antagonist_inverts_hedonic_polarity
------------------------------------------------------------------------

eqHedonicPolarityB : HedonicPolarity → HedonicPolarity → Bool
eqHedonicPolarityB hedPositive hedPositive = true
eqHedonicPolarityB hedNegative hedNegative = true
eqHedonicPolarityB hedNeutral  hedNeutral  = true
eqHedonicPolarityB _           _           = false

antagonistInvertsEntryB : LexiconEntry → Bool
antagonistInvertsEntryB e =
  let p  = entryPoint e
      ap = antagonistPoint p
  in eqHedonicPolarityB
       (computeHedonicPolarity (px ap) (py ap))
       (HedonicPolarity-invert (computeHedonicPolarity (px p) (py p)))

-- [1/1] all176Entries_antagonist_inverts_hedonic_polarity (Theorem #113)
all176Entries_antagonist_inverts_hedonic_polarity :
  ∀ {e : LexiconEntry} → e ∈ all176Entries →
  antagonistInvertsEntryB e ≡ true
all176Entries_antagonist_inverts_hedonic_polarity {e} e∈ =
  All-lookup (allB-to-All antagonistInvertsEntryB all176Entries refl) e∈

------------------------------------------------------------------------
-- 2. Exhaustive 130-Theorem Anchor across 11 Blocks
--    (7 + 23 + 13 + 10 + 10 + 8 + 41 + 1 + 7 + [unique_labels] + 10)
------------------------------------------------------------------------

auditAnchor-01-PredictiveEngine : _
auditAnchor-01-PredictiveEngine =
  ( Polarity_invert_involutive
  , coupling_regime_partition
  , feedbackUpdate_couples_gradients
  , inferential_loop_covers_interfaces
  , feedbackUpdateWeighted_couples_precision
  , engineStep_remanence
  , engineStep_phase_progression
  )

auditAnchor-02-CoreAffect : _
auditAnchor-02-CoreAffect =
  ( engine_induces_valid_core_affect
  , z2_budget_conservation
  , axial-to-diagonal_reallocation
  , dissipationStep_valid
  , dissipationStep_fixed_iff
  , dissipation_strictly_decreases
  , remanence_preserves_state
  , cooperative_step_leaves_crown
  , deployCouplingWithPrecision_valid
  , neutral_coupling_without_suspension_yields_veille
  , neutral_or_subthreshold-with-suspension_yields_central
  , descending_suspension_yields_central_operator
  , central_z_ge2_requires_descending_suspension
  , deployCouplingWithPrecision_budget_conservation
  , dual_engaged_yields_diagonal_z2_precision
  , symmetric_precision_never_lateral
  , projectToCoreAffect_surjective
  , engineStep_canonical_trajectory
  , engineStep_surprise_to_crown
  , anticipation_short_circuits_to_veille
  , dissipation_from_ge2_never_visits_surprise
  , dissipationPotential_short_circuit_jump
  , dissipation_reaches_veille
  )

auditAnchor-03-AffectiveMatrix : _
auditAnchor-03-AffectiveMatrix =
  ( HedonicPolarity_invert_involutive
  , x_positive_determines_positive_valence
  , x_negative_determines_negative_valence
  , antagonistPoint_preserves_validity
  , antagonistPoint_involutive
  , contralateral_swaps_amplitudes
  , antagonist_commutes-with-invert
  , antagonistPoint_unified
  , antagonist_preserves_validity-in
  , transferUnitYtoX_preserves_sum
  , antagonist_commutes-with-invert_precision
  , evaluateMatrix_core_antagonist_independent
  , mapping_independent_antagonist_invariants
  )

auditAnchor-04-AffectiveTaxonomy : _
auditAnchor-04-AffectiveTaxonomy =
  ( inventory-176-certified
  , taxonomy_group_exhaustive
  , taxonomy_group_exclusive
  , dominantSector_iff_taxonomicGroup
  , contralateral_group_bindings
  , classifySubsector_correct
  , subsector_exclusive
  , classifySubsector_refines_group
  , classifySubsector_determines_valence
  , end-to-end_coherence
  )

auditAnchor-05-AffectiveDynamics : _
auditAnchor-05-AffectiveDynamics =
  ( canonicalDepthKernel_reaches_crown
  , canonicalDepthKernel_reaches_lateral
  , lateral_reachable
  , lateral_reachable_from_surprise
  , canonicalDepthKernel_colere_bifurcates
  , canonicalDepthKernel_axial_instability_p2
  , canonicalDepthKernel_outgoingWeight_pos
  , classifyTaxonomicGroup_unique_maximizer
  , classifyTaxonomicGroup_maximizes_membership
  , lateral_has_overlapping_attractors
  )

auditAnchor-06-Lexicon176 : _
auditAnchor-06-Lexicon176 =
  ( all176Entries_length
  , (λ {e} → all176Entries_geometrically_valid {e})
  , (λ {e} → all176Entries_z_bounds {e})
  , (λ {e} → all176Entries_unique_points {e})
  , all176Entries_complete
  , (λ {e} → all176Entries_deterministically_reachable {e})
  , (λ {e} → all176Entries_reachable_by_engine {e})
  , (λ {e} → all176Entries_witness_check {e})
  )

auditAnchor-07-PredictiveCircuit : _
auditAnchor-07-PredictiveCircuit =
  ( circuit_covers_interfaces_both_sides
  , circuit_refines_inferential_ops
  , phiL1_left_inv
  , phiL1_right_inv
  , phiL1_agrees-with-deployZ2
  , crossingII_is_transpose_of_crossingI
  , routeToSubjective_injective
  , routeToPerceptive_injective
  , projectPerceptible_valid
  , projectPerceptible_z2_matches_phiL1
  , projectPerceptible_neutral_elevates-to-central
  , attentional_bottleneck_sum_active
  , circuitRowSum_exact
  , veille_absorbing_free
  , lyapunov_monotone_free
  , lyapunov_strict_descent_witness
  , lyapunov_expected_drift_constant
  , axial_peur_bifurcates_p2
  , veille_reaches_all_one_step
  , all_reach_veille_two_steps
  , veille_unreachable_when_eps_max
  , circularCycle_veille_fixed_point
  , circularCycle_reduces_total_discrepancy
  , lyapunov_drift_charge-with-passive_extinction
  , p1_without_p2_eps_independent
  , epistemic_rigidity_traps_charge_slice
  , pragmatic_helplessness_traps_charge_slice
  , perseveration_traps_discharge_free
  , passive_extinction_zero_relief
  , active_resolution_beats_passive_extinction
  , charge_accumulator_bounded
  , nextStratumR5_le_zMax
  , nextStratumR5_short_circuits_z2-to-veille
  , nextStratumR5_from_ge2_never_visits_surprise
  , symmetricSigmoid_sum
  , symmetricSigmoid_pos
  , symmetricSigmoid_neg
  , precisionShare_double_charge_cancels_alpha
  , projectUnifiedState_valid
  , projectUnifiedState_crown_budget
  , projectUnifiedState_reaches_lateral_consternation
  )

auditAnchor-08-AuditTests : _
auditAnchor-08-AuditTests =
  λ {e} → all176Entries_antagonist_inverts_hedonic_polarity {e}

auditAnchor-09-OperantFactorization : _
auditAnchor-09-OperantFactorization =
  ( manhattanDistXY_origin
  , operant_factorization_law
  , energyRegime_matches_operant_operator
  , antagonist_flips_effect_preserves_operator
  , axial_poles_bridge_operant_pairs
  , axial_poles_pre_operant
  , operant_bijection_on_z2_diagonals
  )

auditAnchor-10-LexiconNominalUniqueness : _
auditAnchor-10-LexiconNominalUniqueness =
  all176Entries_unique_labels

auditAnchor-11-EndToEndBridge : _
auditAnchor-11-EndToEndBridge =
  ( circuit_coupling_operant_bridge
  , triggerSecondaryGradient_enters_operant
  , p2_markov_contagion_enters_operant_punishment
  , operant_quadrant_lifting_all_strata
  , operant_antagonist_invariance_all_strata
  , depthKernel_preserves_operant_quadrant
  , operant_lineages_reach_z7_transcendentals
  , unified_circuit-to-taxonomy_coherence
  , circularCycle-to-taxonomy_and_lexicon_coherence
  , full_end-to-end_lexicon_resolution
  )

------------------------------------------------------------------------
-- 3. 11 Concrete Computational Evaluation Blocks (Bit-for-Bit Parity)
------------------------------------------------------------------------

-- Block 1: 3-phase trajectory Z0(0,0,0) -> Z1(0,0,1) -> Z2(0,0,2) -> Z2(0,2,2)
s0_block1 : PredictiveEngineState
s0_block1 =
  mkPredictiveEngineState
    (mkSalientDiscrepancy 2 1 1 (s≤s z≤n))
    (mkPerceptiveInterface zero)
    (mkSubjectiveInterface zero false)
    (mkAttentionalInterface 0 1 0 1 1)

eval_block-01 :
  let s1 = engineStep s0_block1
      s2 = engineStep s1
      s3 = engineStep s2
  in (projectToCoreAffect s0_block1 ≡ mkPoint (pos 0) (pos 0) 0)
     × (projectToCoreAffect s1 ≡ mkPoint (pos 0) (pos 0) 1)
     × (projectToCoreAffect s2 ≡ mkPoint (pos 0) (pos 0) 2)
     × (projectToCoreAffect s3 ≡ mkPoint (pos 0) (pos 2) 2)
eval_block-01 = refl , refl , refl , refl

-- Block 2: Z2 axial -> diagonal reallocation (-2,0,2) -> (-1,1,2)
eval_block-02 :
  let c0 = mkEngineCoupling neg zero
      p0 = deployCouplingAtDepth c0 0
      c1 = triggerSecondaryGradient c0 pos
      p1 = deployCouplingAtDepth c1 0
  in (p0 ≡ mkPoint (negsuc 1) (pos 0) 2)
     × (classifyGeometry p0 ≡ axial)
     × (classifyTaxonomicGroup p0 ≡ groupePeur)
     × (p1 ≡ mkPoint (negsuc 0) (pos 1) 2)
     × (classifyGeometry p1 ≡ diagonal)
     × (classifyTaxonomicGroup p1 ≡ groupeColere)
eval_block-02 = refl , refl , refl , refl , refl , refl

-- Block 3: Asymmetric precision -> lateral point (1,3,3) & antagonist (-3,-1,3)
eval_block-03 :
  let p  = deployCouplingWithPrecision (mkEngineCoupling pos pos) 1 1 3
      ap = antagonistPoint p
  in (p ≡ mkPoint (pos 1) (pos 3) 3)
     × (classifyGeometry p ≡ lateral)
     × (classifyTaxonomicGroup p ≡ groupeJoie)
     × (classifySubsector (px p) (py p) ≡ lateralApproachSynergy)
     × (ap ≡ mkPoint (negsuc 2) (negsuc 0) 3)
     × (classifyTaxonomicGroup ap ≡ groupePeur)
eval_block-03 = refl , refl , refl , refl , refl , refl

-- Block 4: Allostatic dissipation from (1,3,3) to (0,0,0) in 3 steps
eval_block-04 :
  let p0 = mkPoint (pos 1) (pos 3) 3
      p1 = repeatDissipation 1 p0
      p2 = repeatDissipation 2 p0
      p3 = repeatDissipation 3 p0
  in (p1 ≡ mkPoint (pos 0) (pos 0) 3)
     × (p2 ≡ mkPoint (pos 0) (pos 0) 2)
     × (p3 ≡ mkPoint (pos 0) (pos 0) 0)
     × ((dissipationPotential p0 , dissipationPotential p1 , dissipationPotential p2 , dissipationPotential p3)
        ≡ (7 , 6 , 4 , 0))
eval_block-04 = refl , refl , refl , refl

-- Block 5: Inter-stratum kernel weights (P2 instability & Colere bifurcation)
eval_block-05 :
  (canonicalDepthWeight (mkPoint (pos 0) (pos 0) 1)    (mkPoint (pos 1)    (pos 1) 2) ≡ 1)
  × (canonicalDepthWeight (mkPoint (pos 0) (pos 2) 2)  (mkPoint (pos 0)    (pos 4) 3) ≡ 1)
  × (canonicalDepthWeight (mkPoint (pos 0) (pos 2) 2)  (mkPoint (pos 2)    (pos 2) 3) ≡ 2)
  × (canonicalDepthWeight (mkPoint (pos 0) (pos 2) 2)  (mkPoint (negsuc 1) (pos 2) 3) ≡ 2)
  × (canonicalDepthWeight (mkPoint (negsuc 0) (pos 1) 2) (mkPoint (negsuc 1) (pos 2) 3) ≡ 2)
  × (canonicalDepthWeight (mkPoint (negsuc 0) (pos 1) 2) (mkPoint (negsuc 0) (pos 3) 3) ≡ 1)
  × (canonicalDepthWeight (mkPoint (negsuc 0) (pos 1) 2) (mkPoint (negsuc 2) (pos 1) 3) ≡ 1)
eval_block-05 = refl , refl , refl , refl , refl , refl , refl

-- Block 6: Overlapping attractor memberships at (1,3,3)
eval_block-06 :
  let p = mkPoint (pos 1) (pos 3) 3 in
  (attractorMembership p groupeJoie ≡ 4)
  × (attractorMembership p groupeDesir ≡ 2)
  × (attractorMembership p groupeCourage ≡ 1)
  × (attractorMembership p groupePeur ≡ 0)
  × (classifyTaxonomicGroup p ≡ groupeJoie)
eval_block-06 = refl , refl , refl , refl , refl

-- Block 7: Anticipation (0,0,2) short-circuit to Veille (0,0,0), jump = 4
eval_block-07 :
  (dissipationStep (mkPoint (pos 0) (pos 0) 2) ≡ mkPoint (pos 0) (pos 0) 0)
  × ((dissipationPotential (mkPoint (pos 0) (pos 0) 2)
      - dissipationPotential (dissipationStep (mkPoint (pos 0) (pos 0) 2))) ≡ 4)
eval_block-07 = refl , refl

-- Block 8: 176-state lexicon census & crown peripheral counts
eval_block-08 :
  ((crownPeripheralCount 2 , crownPeripheralCount 3 , crownPeripheralCount 4
    , crownPeripheralCount 5 , crownPeripheralCount 6 , crownPeripheralCount 7)
   ≡ (8 , 16 , 24 , 32 , 40 , 48))
  × (length all176Entries ≡ 176)
eval_block-08 = refl , refl

-- Block 9: Proto-spatial bijection phiL1, crossings I/II, bottleneck & Lyapunov
eval_block-09 :
  (phiL1 (mkEngineCoupling neg pos) ≡ mkProtoNode (negsuc 0) (pos 1))
  × (crossingIPos (mkEngineCoupling neg pos) ≡ (1 , 0))
  × (crossingIIPos (mkEngineCoupling neg pos) ≡ (0 , 1))
  × (attentionalWeightX2 (mkEngineCoupling neg zero) ≡ 2)
  × (attentionalWeightY2 (mkEngineCoupling neg zero) ≡ 2)
  × (lyapunovPotential (mkEngineCoupling neg neg) ≡ 4)
eval_block-09 = refl , refl , refl , refl , refl , refl

-- Block 10: 4 * 100^6 Markov row sum (4000000000000) & P2 transition weight (101500000000)
eval_block-10 :
  (circuitRowSum defaultCircuitKernelParams (mkEngineCoupling neg zero) ≡ 4000000000000)
  × (circuitWeight defaultCircuitKernelParams (mkEngineCoupling neg zero) (mkEngineCoupling neg pos) ≡ 101500000000)
eval_block-10 = refl , refl

-- Block 11: Unified R1-R5 projection -> shares (193, 807) & Consternation (-1, 3, 3)
eval_block-11 :
  (nextChargeAccumulator defaultUnifiedDynamicsParams 1000 500 500 (mkEngineCoupling neg zero) (mkEngineCoupling pos zero) ≡ 700)
  × (nextChargeAccumulator defaultUnifiedDynamicsParams 1000 500 500 (mkEngineCoupling neg zero) (mkEngineCoupling zero zero) ≡ 1300)
  × (nextStratumR5 defaultUnifiedDynamicsParams 2 100 ≡ 0)
  × (nextStratumR5 defaultUnifiedDynamicsParams 3 100 ≡ 2)
  × (precisionShares defaultUnifiedDynamicsParams (pos 10) (pos 90) (mkEngineCoupling neg neg) ≡ (193 , 807))
  × (projectUnifiedState defaultUnifiedDynamicsParams (mkEngineCoupling neg pos) 3 (pos 10) (pos 90) true
     ≡ mkPoint (negsuc 0) (pos 3) 3)
eval_block-11 = refl , refl , refl , refl , refl , refl
