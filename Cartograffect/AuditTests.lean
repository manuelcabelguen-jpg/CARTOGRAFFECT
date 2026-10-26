/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
Released under MIT license as described in the file LICENSE.
Author: Manuel Cabelguen
-/

import Cartograffect.PredictiveEngine
import Cartograffect.CoreAffect
import Cartograffect.AffectiveMatrix
import Cartograffect.AffectiveTaxonomy
import Cartograffect.Lexicon176

namespace Cartograffect.Audit

open PredictiveEngine
open CoreAffect
open AffectiveMatrix
open AffectiveTaxonomy
open Lexicon176

/-!
## PHASE 1 : Audit Axiomatique (#print axioms)
-/
#print axioms Polarity.invert_involutive
#print axioms coupling_regime_partition
#print axioms engine_induces_valid_core_affect
#print axioms z2_budget_conservation
#print axioms axial_to_diagonal_reallocation
#print axioms dissipationStep_valid
#print axioms antagonistPoint_preserves_validity
#print axioms antagonistPoint_involutive
#print axioms contralateral_swaps_amplitudes
#print axioms inventory_176_certified
#print axioms taxonomy_group_exhaustive
#print axioms taxonomy_group_exclusive
#print axioms end_to_end_coherence
#print axioms Cartograffect.Lexicon176.all176Entries_length
#print axioms Cartograffect.Lexicon176.all176Entries_geometrically_valid
#print axioms Cartograffect.Lexicon176.all176Entries_unique_points
#print axioms Cartograffect.Lexicon176.all176Entries_closed_under_antagonist

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
#eval (runCartograffectPipeline sampleColereEngine).antagonistGroup
#eval (runCartograffectPipeline sampleColereEngine).matrix.valence

end Cartograffect.Audit
