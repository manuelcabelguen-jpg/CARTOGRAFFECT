----------------------------- MODULE CoreAffect -----------------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Module 02 : CoreAffect — Geometrie toroidale 3D, R5 et dissipation (TLA+ / TLC)
*)
EXTENDS Integers, PredictiveEngine

GeometryTypes == {"central", "axial", "diagonal", "lateral"}
ResourceRegimes == {"competitive", "cooperative"}

IntAbs(v) == IF v >= 0 THEN v ELSE -v
PolarityOfInt(v) == IF v > 0 THEN "pos" ELSE IF v < 0 THEN "neg" ELSE "zero"
SignedAmplitude(pol, amp) == IF pol = "neg" THEN -amp ELSE IF pol = "zero" THEN 0 ELSE amp
ClampInt(lo, hi, v) == IF v < lo THEN lo ELSE IF hi < v THEN hi ELSE v

MkPoint(px, py, pz) == [x |-> px, y |-> py, z |-> pz]

DisplacementSum(p) == IntAbs(p.x) + IntAbs(p.y)
CrownRadius(z) == IF z < 2 THEN 0 ELSE 2 * z - 2

IsCentral(p) == p.x = 0 /\ p.y = 0
IsOnCrown(p) == p.z >= 2 /\ DisplacementSum(p) = CrownRadius(p.z)

IsValidCoreAffect(p) ==
  /\ p.z >= 0
  /\ (IsCentral(p) \/ IsOnCrown(p))

IsValidCoreAffectIn(reg, p) ==
  IF reg = "competitive" THEN IsValidCoreAffect(p)
  ELSE /\ p.z >= 0
       /\ (IsCentral(p) \/ (p.z >= 2 /\ CrownRadius(p.z) <= DisplacementSum(p)))

ClassifyGeometry(p) ==
  IF p.x = 0 /\ p.y = 0 THEN "central"
  ELSE IF p.x = 0 \/ p.y = 0 THEN "axial"
  ELSE IF IntAbs(p.x) = IntAbs(p.y) THEN "diagonal"
  ELSE "lateral"

DeployCouplingAtDepth(c, d) ==
  LET z == d + 2
      r == 2 * d + 2
      k == d + 1
  IN IF c.attente = "zero" /\ c.controle = "zero" THEN MkPoint(0, 0, 0)
     ELSE IF c.controle = "zero" THEN MkPoint(SignedAmplitude(c.attente, r), 0, z)
     ELSE IF c.attente = "zero" THEN MkPoint(0, SignedAmplitude(c.controle, r), z)
     ELSE MkPoint(SignedAmplitude(c.attente, k), SignedAmplitude(c.controle, k), z)

ApportionRayX(d, piA, piC) ==
  LET r == 2 * d + 2
      tot == piA + piC
  IN IF piA = piC THEN d + 1
     ELSE IF piA < piC THEN ClampInt(1, d + 1, (2 * r * piA + tot) \div (2 * tot))
     ELSE r - ClampInt(1, d + 1, (2 * r * piC + tot) \div (2 * tot))

ApportionRayY(d, piA, piC) == (2 * d + 2) - ApportionRayX(d, piA, piC)

DeployCouplingWithPrecision(c, d, piA, piC) ==
  LET z == d + 2
      r == 2 * d + 2
  IN IF c.attente = "zero" /\ c.controle = "zero" THEN MkPoint(0, 0, 0)
     ELSE IF c.controle = "zero" THEN MkPoint(SignedAmplitude(c.attente, r), 0, z)
     ELSE IF c.attente = "zero" THEN MkPoint(0, SignedAmplitude(c.controle, r), z)
     ELSE MkPoint(SignedAmplitude(c.attente, ApportionRayX(d, piA, piC)),
                  SignedAmplitude(c.controle, ApportionRayY(d, piA, piC)),
                  z)

ProjectToCoreAffect(s) ==
  LET c == CurrentCoupling(s) IN
  IF ~IsSensorilySalient(s.discrepancy) \/ IsGlobalNeutrality(c) THEN
    IF s.subjective.descendingSuspension THEN MkPoint(0, 0, s.attentional.persistenceDepth + 2)
    ELSE MkPoint(0, 0, 0)
  ELSE IF ~AttentionalIsEngaged(s.attentional) THEN
    IF s.subjective.descendingSuspension THEN MkPoint(0, 0, s.attentional.persistenceDepth + 2)
    ELSE MkPoint(0, 0, 1)
  ELSE DeployCouplingWithPrecision(c, s.attentional.persistenceDepth,
                                   s.attentional.precisionA, s.attentional.precisionC)

TriggerSecondaryGradient(c, newPol) ==
  IF PolarityIsEngaged(c.attente) /\ c.controle = "zero" THEN MkCoupling(c.attente, newPol)
  ELSE IF c.attente = "zero" /\ PolarityIsEngaged(c.controle) THEN MkCoupling(newPol, c.controle)
  ELSE c

WitnessEngineForPoint(p) ==
  LET ax == IntAbs(p.x)
      ay == IntAbs(p.y)
      useSym == (ax = 0 \/ ay = 0)
  IN IF p.x = 0 /\ p.y = 0 THEN
       IF p.z = 0 THEN
         MkEngineState(MkDiscrepancy(0, 1, 1), MkPerceptive("zero"), MkSubjective("zero", FALSE), MkAttentional(0, 0, 0, 1, 1))
       ELSE IF p.z = 1 THEN
         MkEngineState(MkDiscrepancy(2, 1, 1), MkPerceptive("zero"), MkSubjective("pos", FALSE), MkAttentional(0, 1, 0, 1, 1))
       ELSE
         MkEngineState(MkDiscrepancy(2, 1, 1), MkPerceptive("zero"), MkSubjective("pos", TRUE), MkAttentional(0, 1, p.z - 2, 1, 1))
     ELSE
       MkEngineState(
         MkDiscrepancy(2, 1, 1),
         MkPerceptive(PolarityOfInt(p.y)),
         MkSubjective(PolarityOfInt(p.x), TRUE),
         MkAttentional(1, 1, p.z - 2, IF useSym THEN 1 ELSE ax, IF useSym THEN 1 ELSE ay)
       )

DissipationStep(p) ==
  IF p.x # 0 \/ p.y # 0 THEN MkPoint(0, 0, p.z)
  ELSE IF p.z <= 2 THEN MkPoint(0, 0, 0)
  ELSE MkPoint(0, 0, p.z - 1)

DissipationPotential(p) ==
  2 * p.z + (IF p.x # 0 \/ p.y # 0 THEN 1 ELSE 0)

AllostaticStep(d, p) ==
  IF d.magnitude < d.resorptionThreshold THEN DissipationStep(p) ELSE p

RECURSIVE RepeatDissipation(_, _)
RepeatDissipation(n, p) ==
  IF n <= 0 THEN p ELSE RepeatDissipation(n - 1, DissipationStep(p))

-----------------------------------------------------------------------------
(* 23 audited theorem predicates for CoreAffect *)
-----------------------------------------------------------------------------

Thm_engine_induces_valid_core_affect(StateSet) ==
  \A s \in StateSet : IsValidCoreAffect(ProjectToCoreAffect(s))

Thm_z2_budget_conservation ==
  \A c \in Couplings : ~IsGlobalNeutrality(c) => DisplacementSum(DeployCouplingAtDepth(c, 0)) = 2

Thm_axial_to_diagonal_reallocation ==
  \A c \in Couplings, newPol \in Polarities :
    (IsSingleEngaged(c) /\ PolarityIsEngaged(newPol)) =>
      LET pt == DeployCouplingAtDepth(TriggerSecondaryGradient(c, newPol), 0) IN
      ClassifyGeometry(pt) = "diagonal" /\ DisplacementSum(pt) = 2

Thm_dissipationStep_valid(PointSet) ==
  \A p \in PointSet : IsValidCoreAffect(DissipationStep(p))

Thm_dissipationStep_fixed_iff(PointSet) ==
  \A p \in PointSet : (DissipationStep(p) = p) <=> (p = MkPoint(0, 0, 0))

Thm_dissipation_strictly_decreases(PointSet) ==
  \A p \in PointSet :
    (p # MkPoint(0, 0, 0)) => DissipationPotential(DissipationStep(p)) < DissipationPotential(p)

Thm_remanence_preserves_state(DiscSet, PointSet) ==
  \A d \in DiscSet, p \in PointSet :
    IsInRemanenceWindow(d) => AllostaticStep(d, p) = p

Thm_cooperative_step_leaves_crown(PointSet) ==
  \A p \in PointSet :
    (IsOnCrown(p) /\ p.x >= 0 /\ p.y >= 0) => ~IsOnCrown(MkPoint(p.x + 1, p.y + 1, p.z))

Thm_deployCouplingWithPrecision_valid(Depths, PrecSet) ==
  \A c \in Couplings, d \in Depths, piA \in PrecSet, piC \in PrecSet :
    IsValidCoreAffect(DeployCouplingWithPrecision(c, d, piA, piC))

Thm_neutral_coupling_without_suspension_yields_veille(StateSet) ==
  \A s \in StateSet :
    (IsGlobalNeutrality(CurrentCoupling(s)) /\ ~s.subjective.descendingSuspension) =>
      ProjectToCoreAffect(s) = MkPoint(0, 0, 0)

Thm_neutral_or_subthreshold_with_suspension_yields_central(StateSet) ==
  \A s \in StateSet :
    ((~IsSensorilySalient(s.discrepancy) \/ IsGlobalNeutrality(CurrentCoupling(s)))
     /\ s.subjective.descendingSuspension) =>
      ProjectToCoreAffect(s) = MkPoint(0, 0, s.attentional.persistenceDepth + 2)

Thm_descending_suspension_yields_central_operator(StateSet) ==
  \A s \in StateSet :
    (s.subjective.descendingSuspension
     /\ (~IsSensorilySalient(s.discrepancy)
         \/ IsGlobalNeutrality(CurrentCoupling(s))
         \/ ~AttentionalIsEngaged(s.attentional))) =>
      ProjectToCoreAffect(s) = MkPoint(0, 0, s.attentional.persistenceDepth + 2)

Thm_central_z_ge2_requires_descending_suspension(StateSet, Depths) ==
  \A s \in StateSet, d \in Depths :
    (ProjectToCoreAffect(s) = MkPoint(0, 0, d + 2)) =>
      /\ s.subjective.descendingSuspension
      /\ s.attentional.persistenceDepth = d
      /\ (~IsSensorilySalient(s.discrepancy)
          \/ IsGlobalNeutrality(CurrentCoupling(s))
          \/ ~AttentionalIsEngaged(s.attentional))

Thm_deployCouplingWithPrecision_budget_conservation(Depths, PrecSet) ==
  \A c \in Couplings, d \in Depths, piA \in PrecSet, piC \in PrecSet :
    (~IsGlobalNeutrality(c)) =>
      DisplacementSum(DeployCouplingWithPrecision(c, d, piA, piC)) = 2 * d + 2

Thm_dual_engaged_yields_diagonal_z2_precision(PrecSet) ==
  \A c \in Couplings, piA \in PrecSet, piC \in PrecSet :
    IsDualEngaged(c) => ClassifyGeometry(DeployCouplingWithPrecision(c, 0, piA, piC)) = "diagonal"

Thm_symmetric_precision_never_lateral(StateSet) ==
  \A s \in StateSet :
    (s.attentional.precisionA = s.attentional.precisionC) =>
      ClassifyGeometry(ProjectToCoreAffect(s)) # "lateral"

Thm_projectToCoreAffect_surjective(ValidPointSet) ==
  \A p \in ValidPointSet :
    IsValidCoreAffect(p) => ProjectToCoreAffect(WitnessEngineForPoint(p)) = p

Thm_engineStep_canonical_trajectory(StateSet) ==
  \A s0 \in StateSet :
    (IsSensorilySalient(s0.discrepancy)
     /\ IsGlobalNeutrality(CurrentCoupling(s0))
     /\ ~s0.subjective.descendingSuspension
     /\ ~AttentionalIsEngaged(s0.attentional)
     /\ s0.attentional.persistenceDepth = 0) =>
      /\ ProjectToCoreAffect(s0) = MkPoint(0, 0, 0)
      /\ ProjectToCoreAffect(EngineStep(s0)) = MkPoint(0, 0, 1)
      /\ ProjectToCoreAffect(EngineStep(EngineStep(s0))) = MkPoint(0, 0, 2)
      /\ ProjectToCoreAffect(EngineStep(EngineStep(EngineStep(s0)))) = MkPoint(0, 2, 2)

Thm_engineStep_surprise_to_crown(StateSet) ==
  \A s1 \in StateSet :
    (IsSensorilySalient(s1.discrepancy)
     /\ ~IsGlobalNeutrality(CurrentCoupling(s1))
     /\ ~s1.subjective.descendingSuspension
     /\ ~AttentionalIsEngaged(s1.attentional)
     /\ s1.attentional.persistenceDepth = 0) =>
      LET pCrown == ProjectToCoreAffect(EngineStep(EngineStep(s1))) IN
      /\ ProjectToCoreAffect(s1) = MkPoint(0, 0, 1)
      /\ ProjectToCoreAffect(EngineStep(s1)) = MkPoint(0, 0, 2)
      /\ pCrown = DeployCouplingWithPrecision(
                    CurrentCoupling(s1), 0, s1.attentional.precisionA, s1.attentional.precisionC)
      /\ pCrown.z = 2
      /\ IsOnCrown(pCrown)

Thm_anticipation_short_circuits_to_veille ==
  DissipationStep(MkPoint(0, 0, 2)) = MkPoint(0, 0, 0)

Thm_dissipation_from_ge2_never_visits_surprise(PointSet) ==
  \A p \in PointSet : (p.z >= 2) => DissipationStep(p) # MkPoint(0, 0, 1)

Thm_dissipationPotential_short_circuit_jump ==
  DissipationPotential(MkPoint(0, 0, 2)) - DissipationPotential(DissipationStep(MkPoint(0, 0, 2))) = 4

Thm_dissipation_reaches_veille(PointSet) ==
  \A p \in PointSet :
    (p.z >= 0 /\ p.z <= 7) => RepeatDissipation(p.z + 1, p) = MkPoint(0, 0, 0)

=============================================================================
