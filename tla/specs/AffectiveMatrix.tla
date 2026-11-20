-------------------------- MODULE AffectiveMatrix ---------------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Module 03 : Matrice Affective, polarite hedonique, antagoniste et R3 (TLA+ / TLC)
*)
EXTENDS Integers, PredictiveEngine, CoreAffect

LivedExpectationPoles == {"epistemicCharge", "epistemicNeutral", "epistemicDischarge"}
LivedControlPoles == {"pragmaticCharge", "pragmaticNeutral", "pragmaticDischarge"}
EnergyRegimes == {
  "neutralBasal", "axialPure", "positiveSynergy",
  "negativeSynergy", "ergotropicCompensation", "trophotropicRelease"
}
HedonicPolarities == {"positive", "negative", "neutral"}
PhenomenologicalActivations == {
  "basalWakefulness", "ascendingRupture", "operatorSuspension",
  "lowInhibition", "epistemicVigilance", "highMobilization"
}

IntSign(v) == IF v > 0 THEN 1 ELSE IF v < 0 THEN -1 ELSE 0

HedonicPolarityInvert(p) ==
  IF p = "positive" THEN "negative"
  ELSE IF p = "negative" THEN "positive"
  ELSE "neutral"

ComputeHedonicPolarity(x, y) ==
  IF x > 0 THEN "positive"
  ELSE IF x < 0 THEN "negative"
  ELSE IF y > 0 THEN "positive"
  ELSE IF y < 0 THEN "negative"
  ELSE "neutral"

TransduceExpectation(x) ==
  IF x < 0 THEN "epistemicCharge" ELSE IF x > 0 THEN "epistemicDischarge" ELSE "epistemicNeutral"

TransduceControl(y) ==
  IF y < 0 THEN "pragmaticCharge" ELSE IF y > 0 THEN "pragmaticDischarge" ELSE "pragmaticNeutral"

ComputeEnergyRegime(x, y) ==
  IF x = 0 /\ y = 0 THEN "neutralBasal"
  ELSE IF x = 0 \/ y = 0 THEN "axialPure"
  ELSE IF x > 0 /\ y > 0 THEN "positiveSynergy"
  ELSE IF x < 0 /\ y < 0 THEN "negativeSynergy"
  ELSE IF x < 0 /\ y > 0 THEN "ergotropicCompensation"
  ELSE "trophotropicRelease"

ComputeActivation(p) ==
  IF p.x = 0 /\ p.y = 0 THEN
    IF p.z = 0 THEN "basalWakefulness"
    ELSE IF p.z = 1 THEN "ascendingRupture"
    ELSE "operatorSuspension"
  ELSE IF p.y > 0 THEN "highMobilization"
  ELSE IF p.y < 0 THEN "lowInhibition"
  ELSE "epistemicVigilance"

AntagonistPoint(p) ==
  IF p.x = 0 \/ p.y = 0 \/ IntAbs(p.x) = IntAbs(p.y) THEN
    MkPoint(-p.x, -p.y, p.z)
  ELSE IF (p.x > 0 /\ p.y < 0) \/ (p.x < 0 /\ p.y > 0) THEN
    MkPoint(p.y, p.x, p.z)
  ELSE
    MkPoint(-p.y, -p.x, p.z)

TransferUnitYtoX(p) ==
  IF p.x >= 0 /\ p.y > 0 THEN MkPoint(p.x + 1, p.y - 1, p.z) ELSE p

EvaluateMatrixCanonical(p) ==
  [
    core |-> p,
    expectationPole |-> TransduceExpectation(p.x),
    controlPole |-> TransduceControl(p.y),
    energyRegime |-> ComputeEnergyRegime(p.x, p.y),
    valence |-> ComputeHedonicPolarity(p.x, p.y),
    activation |-> ComputeActivation(p),
    antagonist |-> AntagonistPoint(p)
  ]

EvaluateMatrixWith(p, expPole, ctrlPole, val, act) ==
  [
    core |-> p,
    expectationPole |-> expPole,
    controlPole |-> ctrlPole,
    energyRegime |-> ComputeEnergyRegime(p.x, p.y),
    valence |-> val,
    activation |-> act,
    antagonist |-> AntagonistPoint(p)
  ]

-----------------------------------------------------------------------------
(* 13 audited theorem predicates for AffectiveMatrix *)
-----------------------------------------------------------------------------

Thm_hedonicPolarity_invert_involutive ==
  \A p \in HedonicPolarities : HedonicPolarityInvert(HedonicPolarityInvert(p)) = p

Thm_x_positive_determines_positive_valence(Range) ==
  \A x \in Range, y \in Range : (x > 0) => ComputeHedonicPolarity(x, y) = "positive"

Thm_x_negative_determines_negative_valence(Range) ==
  \A x \in Range, y \in Range : (x < 0) => ComputeHedonicPolarity(x, y) = "negative"

Thm_antagonistPoint_preserves_validity(PointSet) ==
  \A p \in PointSet : IsValidCoreAffect(p) => IsValidCoreAffect(AntagonistPoint(p))

Thm_antagonistPoint_involutive(PointSet) ==
  \A p \in PointSet : AntagonistPoint(AntagonistPoint(p)) = p

Thm_contralateral_swaps_amplitudes(PointSet) ==
  \A p \in PointSet :
    (p.x # 0 /\ p.y # 0 /\ IntAbs(p.x) # IntAbs(p.y)) =>
      /\ IntAbs(AntagonistPoint(p).x) = IntAbs(p.y)
      /\ IntAbs(AntagonistPoint(p).y) = IntAbs(p.x)

Thm_antagonist_commutes_with_invert(Depths) ==
  \A c \in Couplings, d \in Depths :
    AntagonistPoint(DeployCouplingAtDepth(c, d)) =
      DeployCouplingAtDepth(MkCoupling(PolarityInvert(c.attente), PolarityInvert(c.controle)), d)

Thm_antagonistPoint_unified(PointSet) ==
  \A p \in PointSet :
    (p.x # 0 /\ p.y # 0) =>
      AntagonistPoint(p) =
        MkPoint((-IntSign(p.x)) * IntAbs(p.y), (-IntSign(p.y)) * IntAbs(p.x), p.z)

Thm_antagonist_preserves_validity_in(PointSet) ==
  \A reg \in ResourceRegimes, p \in PointSet :
    IsValidCoreAffectIn(reg, p) => IsValidCoreAffectIn(reg, AntagonistPoint(p))

Thm_transferUnitYtoX_preserves_sum(PointSet) ==
  \A p \in PointSet : DisplacementSum(TransferUnitYtoX(p)) = DisplacementSum(p)

Thm_antagonist_commutes_with_invert_precision(Depths, PrecSet) ==
  \A c \in Couplings, d \in Depths, piA \in PrecSet, piC \in PrecSet :
    AntagonistPoint(DeployCouplingWithPrecision(c, d, piA, piC)) =
      DeployCouplingWithPrecision(MkCoupling(PolarityInvert(c.attente), PolarityInvert(c.controle)), d, piC, piA)

Thm_evaluateMatrix_core_antagonist_independent(PointSet) ==
  \A p \in PointSet :
    IsValidCoreAffect(p) =>
      \A e1 \in LivedExpectationPoles, c1 \in LivedControlPoles,
         v1 \in HedonicPolarities, a1 \in PhenomenologicalActivations :
      \A e2 \in LivedExpectationPoles, c2 \in LivedControlPoles,
         v2 \in HedonicPolarities, a2 \in PhenomenologicalActivations :
        LET r1 == EvaluateMatrixWith(p, e1, c1, v1, a1)
            r2 == EvaluateMatrixWith(p, e2, c2, v2, a2)
        IN  /\ r1.core = r2.core
            /\ r1.energyRegime = r2.energyRegime
            /\ r1.antagonist = r2.antagonist

Thm_mapping_independent_antagonist_invariants(PointSet) ==
  \A p \in PointSet :
    IsValidCoreAffect(p) =>
      \A e1 \in LivedExpectationPoles, c1 \in LivedControlPoles,
         v1 \in HedonicPolarities, a1 \in PhenomenologicalActivations :
        LET r1 == EvaluateMatrixWith(p, e1, c1, v1, a1)
            rc == EvaluateMatrixCanonical(p)
            ant == r1.antagonist
            rAnt == EvaluateMatrixWith(ant, e1, c1, v1, a1)
        IN  /\ IsValidCoreAffect(ant)
            /\ rAnt.antagonist = p
            /\ ((p.x # 0 /\ p.y # 0) =>
                  ant = MkPoint((-IntSign(p.x)) * IntAbs(p.y), (-IntSign(p.y)) * IntAbs(p.x), p.z))
            /\ ant = rc.antagonist

=============================================================================
