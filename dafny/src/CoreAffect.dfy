/*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*/

include "PredictiveEngine.dfy"

module CoreAffect {
  import opened PredictiveEngine

  // =========================================================================
  // 1. Coordonnées spatiales, Loi des couronnes et Opérateurs centraux
  // =========================================================================

  datatype CoreAffectPoint = CoreAffectPoint(x: int, y: int, z: nat)

  function DefaultCoreAffectPoint(): CoreAffectPoint {
    CoreAffectPoint(0, 0, 0)
  }

  function AbsNat(v: int): nat {
    if v >= 0 then v else -v
  }

  function DisplacementSum(p: CoreAffectPoint): nat {
    AbsNat(p.x) + AbsNat(p.y)
  }

  function CrownRadius(z: nat): nat {
    if z < 2 then 0 else 2 * z - 2
  }

  lemma crownRadius_eq_formula(z: nat)
    requires z >= 2
    ensures CrownRadius(z) == 2 * z - 2
  {
  }

  datatype CentralOperator =
    | PointDeVeille
    | Surprise
    | Anticipation
    | Emoi
    | Reserve
    | Recul
    | Saisissement
    | Suspension

  function CentralOperatorToPoint(op: CentralOperator): CoreAffectPoint {
    match op
    case PointDeVeille => CoreAffectPoint(0, 0, 0)
    case Surprise      => CoreAffectPoint(0, 0, 1)
    case Anticipation  => CoreAffectPoint(0, 0, 2)
    case Emoi          => CoreAffectPoint(0, 0, 3)
    case Reserve       => CoreAffectPoint(0, 0, 4)
    case Recul         => CoreAffectPoint(0, 0, 5)
    case Saisissement  => CoreAffectPoint(0, 0, 6)
    case Suspension    => CoreAffectPoint(0, 0, 7)
  }

  // =========================================================================
  // 2. Typologie géométrique, Secteurs d'orientation et État valide
  // =========================================================================

  datatype GeometryType = Central | Axial | Diagonal | Lateral

  datatype OrientationSector = SectorJoie | SectorTristesse | SectorPeur | SectorCourage

  datatype OptionSector = NoSector | SomeSector(sector: OrientationSector)

  function DominantSector(p: CoreAffectPoint): OptionSector {
    if AbsNat(p.y) > AbsNat(p.x) then
      if p.y > 0 then SomeSector(SectorJoie) else SomeSector(SectorTristesse)
    else if AbsNat(p.x) > AbsNat(p.y) then
      if p.x < 0 then SomeSector(SectorPeur) else SomeSector(SectorCourage)
    else
      NoSector
  }

  predicate IsCentral(p: CoreAffectPoint) {
    p.x == 0 && p.y == 0
  }

  predicate IsOnCrown(p: CoreAffectPoint) {
    p.z >= 2 && DisplacementSum(p) == CrownRadius(p.z)
  }

  predicate IsValidCoreAffect(p: CoreAffectPoint) {
    IsCentral(p) || IsOnCrown(p)
  }

  function ClassifyGeometry(p: CoreAffectPoint): GeometryType {
    if p.x == 0 && p.y == 0 then
      Central
    else if p.x == 0 || p.y == 0 then
      Axial
    else if AbsNat(p.x) == AbsNat(p.y) then
      Diagonal
    else
      Lateral
  }

  type CoreAffectState = p: CoreAffectPoint |
    IsValidCoreAffect(p)
    witness CoreAffectPoint(0, 0, 0)

  function DefaultCoreAffectState(): CoreAffectState {
    CoreAffectPoint(0, 0, 0)
  }

  function CentralOperatorToCoreAffectState(op: CentralOperator): CoreAffectState {
    CentralOperatorToPoint(op)
  }

  // =========================================================================
  // 3. Opérateur de projection : Couplage PredictiveEngine -> CoreAffect
  // =========================================================================

  function SignedAmplitude(pol: Polarity, amp: nat): int {
    match pol
    case Neg  => -(amp as int)
    case Zero => 0
    case Pos  => amp as int
  }

  function DeployCouplingAtDepth(c: EngineCoupling, d: nat): CoreAffectPoint {
    var z := d + 2;
    var r := 2 * d + 2;
    var k := d + 1;
    match (c.attente, c.controle)
    case (Zero, Zero) => CoreAffectPoint(0, 0, 0)
    case (Pos,  Zero) => CoreAffectPoint(SignedAmplitude(Pos, r), 0, z)
    case (Neg,  Zero) => CoreAffectPoint(SignedAmplitude(Neg, r), 0, z)
    case (Zero, Pos)  => CoreAffectPoint(0, SignedAmplitude(Pos, r), z)
    case (Zero, Neg)  => CoreAffectPoint(0, SignedAmplitude(Neg, r), z)
    case (Pos,  Pos)  => CoreAffectPoint(SignedAmplitude(Pos, k), SignedAmplitude(Pos, k), z)
    case (Pos,  Neg)  => CoreAffectPoint(SignedAmplitude(Pos, k), SignedAmplitude(Neg, k), z)
    case (Neg,  Pos)  => CoreAffectPoint(SignedAmplitude(Neg, k), SignedAmplitude(Pos, k), z)
    case (Neg,  Neg)  => CoreAffectPoint(SignedAmplitude(Neg, k), SignedAmplitude(Neg, k), z)
  }

  function ClampNat(lo: nat, hi: nat, v: nat): nat {
    if v < lo then lo else if hi < v then hi else v
  }

  lemma clampNat_bounds(lo: nat, hi: nat, v: nat)
    requires lo <= hi
    ensures lo <= ClampNat(lo, hi, v) <= hi
  {
  }

  function ApportionRay(d: nat, piA: nat, piC: nat): (nat, nat) {
    var r := 2 * d + 2;
    if piA == piC then
      (d + 1, d + 1)
    else if piA < piC then
      var total := piA + piC;
      var raw := (2 * r * piA + total) / (2 * total);
      var ax := ClampNat(1, d + 1, raw);
      (ax, r - ax)
    else
      var total := piA + piC;
      var raw := (2 * r * piC + total) / (2 * total);
      var ay := ClampNat(1, d + 1, raw);
      (r - ay, ay)
  }

  lemma apportionRay_bounds(d: nat, piA: nat, piC: nat)
    ensures ApportionRay(d, piA, piC).0 >= 1
    ensures ApportionRay(d, piA, piC).1 >= 1
    ensures ApportionRay(d, piA, piC).0 + ApportionRay(d, piA, piC).1 == 2 * d + 2
  {
    var r := 2 * d + 2;
    if piA == piC {
    } else if piA < piC {
      var total := piA + piC;
      var raw := (2 * r * piA + total) / (2 * total);
      clampNat_bounds(1, d + 1, raw);
    } else {
      var total := piA + piC;
      var raw := (2 * r * piC + total) / (2 * total);
      clampNat_bounds(1, d + 1, raw);
    }
  }

  lemma apportionRay_swap(d: nat, piA: nat, piC: nat)
    ensures ApportionRay(d, piC, piA) == (ApportionRay(d, piA, piC).1, ApportionRay(d, piA, piC).0)
  {
  }

  lemma apportionRay_symm(d: nat, k: nat)
    ensures ApportionRay(d, k, k) == (d + 1, d + 1)
  {
  }

  lemma apportionRay_z2(piA: nat, piC: nat)
    ensures ApportionRay(0, piA, piC) == (1, 1)
  {
    apportionRay_bounds(0, piA, piC);
  }

  lemma NatMulAddDivExact(a: nat, b: nat, rem: nat)
    requires b > 0 && rem < b
    ensures (b * a + rem) / b == a
  {
    var total := b * a + rem;
    var q := total / b;
    var r := total % b;
    assert b * q + r == total && 0 <= r < b;
    if q > a {
      assert b * q >= b * (a + 1);
      assert b * (a + 1) == b * a + b;
    } else if q < a {
      assert b * a >= b * (q + 1);
      assert b * (q + 1) == b * q + b;
    }
  }

  lemma apportionRay_exact(d: nat, ax: nat, ay: nat)
    requires ax >= 1 && ay >= 1 && ax + ay == 2 * d + 2
    ensures ApportionRay(d, ax, ay) == (ax, ay)
  {
    var r := 2 * d + 2;
    if ax == ay {
    } else if ax < ay {
      NatMulAddDivExact(ax, 2 * r, r);
      assert (2 * r * ax + (ax + ay)) == (2 * r) * ax + r;
    } else {
      NatMulAddDivExact(ay, 2 * r, r);
      assert (2 * r * ay + (ax + ay)) == (2 * r) * ay + r;
    }
  }

  function DeployCouplingWithPrecision(c: EngineCoupling, d: nat, piA: nat, piC: nat): CoreAffectPoint {
    var z := d + 2;
    var r := 2 * d + 2;
    match (c.attente, c.controle)
    case (Zero, Zero) => CoreAffectPoint(0, 0, 0)
    case (Pos,  Zero) => CoreAffectPoint(SignedAmplitude(Pos, r), 0, z)
    case (Neg,  Zero) => CoreAffectPoint(SignedAmplitude(Neg, r), 0, z)
    case (Zero, Pos)  => CoreAffectPoint(0, SignedAmplitude(Pos, r), z)
    case (Zero, Neg)  => CoreAffectPoint(0, SignedAmplitude(Neg, r), z)
    case (Pos,  Pos)  =>
      var p := ApportionRay(d, piA, piC);
      CoreAffectPoint(SignedAmplitude(Pos, p.0), SignedAmplitude(Pos, p.1), z)
    case (Pos,  Neg)  =>
      var p := ApportionRay(d, piA, piC);
      CoreAffectPoint(SignedAmplitude(Pos, p.0), SignedAmplitude(Neg, p.1), z)
    case (Neg,  Pos)  =>
      var p := ApportionRay(d, piA, piC);
      CoreAffectPoint(SignedAmplitude(Neg, p.0), SignedAmplitude(Pos, p.1), z)
    case (Neg,  Neg)  =>
      var p := ApportionRay(d, piA, piC);
      CoreAffectPoint(SignedAmplitude(Neg, p.0), SignedAmplitude(Neg, p.1), z)
  }

  lemma deployCouplingWithPrecision_symm_eq(c: EngineCoupling, d: nat, k: nat)
    ensures DeployCouplingWithPrecision(c, d, k, k) == DeployCouplingAtDepth(c, d)
  {
    apportionRay_symm(d, k);
  }

  function ProjectToCoreAffect(s: PredictiveEngineState): CoreAffectPoint {
    var c := CurrentCoupling(s);
    if !IsSensorilySalient(s.discrepancy) || IsGlobalNeutrality(c) then
      if s.subjective.descendingSuspension then
        CoreAffectPoint(0, 0, s.attentional.persistenceDepth + 2)
      else
        CoreAffectPoint(0, 0, 0)
    else if !AttentionalIsEngaged(s.attentional) then
      if s.subjective.descendingSuspension then
        CoreAffectPoint(0, 0, s.attentional.persistenceDepth + 2)
      else
        CoreAffectPoint(0, 0, 1)
    else
      DeployCouplingWithPrecision(c, s.attentional.persistenceDepth, s.attentional.precisionA, s.attentional.precisionC)
  }

  // =========================================================================
  // 4. Lemmes de transition et Invariants géométriques (Moteur -> Noyau)
  // =========================================================================

  lemma deployCouplingAtDepth_valid(c: EngineCoupling, d: nat)
    ensures IsValidCoreAffect(DeployCouplingAtDepth(c, d))
  {
  }

  lemma deployCouplingWithPrecision_valid(c: EngineCoupling, d: nat, piA: nat, piC: nat)
    ensures IsValidCoreAffect(DeployCouplingWithPrecision(c, d, piA, piC))
  {
    apportionRay_bounds(d, piA, piC);
  }

  lemma engine_induces_valid_core_affect(s: PredictiveEngineState)
    ensures IsValidCoreAffect(ProjectToCoreAffect(s))
  {
    deployCouplingWithPrecision_valid(
      CurrentCoupling(s),
      s.attentional.persistenceDepth,
      s.attentional.precisionA,
      s.attentional.precisionC
    );
  }

  lemma neutral_coupling_without_suspension_yields_veille(s: PredictiveEngineState)
    requires IsGlobalNeutrality(CurrentCoupling(s))
    requires !s.subjective.descendingSuspension
    ensures ProjectToCoreAffect(s) == CoreAffectPoint(0, 0, 0)
  {
  }

  lemma neutral_or_subthreshold_with_suspension_yields_central(s: PredictiveEngineState)
    requires !IsSensorilySalient(s.discrepancy) || IsGlobalNeutrality(CurrentCoupling(s))
    requires s.subjective.descendingSuspension
    ensures ProjectToCoreAffect(s) == CoreAffectPoint(0, 0, s.attentional.persistenceDepth + 2)
  {
  }

  lemma descending_suspension_yields_central_operator(s: PredictiveEngineState)
    requires s.subjective.descendingSuspension
    requires (!IsSensorilySalient(s.discrepancy) || IsGlobalNeutrality(CurrentCoupling(s))) ||
             !AttentionalIsEngaged(s.attentional)
    ensures ProjectToCoreAffect(s) == CoreAffectPoint(0, 0, s.attentional.persistenceDepth + 2)
  {
  }

  lemma central_z_ge2_requires_descending_suspension(s: PredictiveEngineState, d: nat)
    requires ProjectToCoreAffect(s) == CoreAffectPoint(0, 0, d + 2)
    ensures s.subjective.descendingSuspension
    ensures s.attentional.persistenceDepth == d
    ensures !IsSensorilySalient(s.discrepancy) || IsGlobalNeutrality(CurrentCoupling(s)) ||
            !AttentionalIsEngaged(s.attentional)
  {
    apportionRay_bounds(s.attentional.persistenceDepth, s.attentional.precisionA, s.attentional.precisionC);
  }

  function EvaluateCoreAffect(s: PredictiveEngineState): CoreAffectState {
    engine_induces_valid_core_affect(s);
    ProjectToCoreAffect(s)
  }

  lemma z2_budget_conservation(c: EngineCoupling)
    requires !IsGlobalNeutrality(c)
    ensures DisplacementSum(DeployCouplingAtDepth(c, 0)) == 2
  {
  }

  lemma single_engaged_yields_axial_z2(c: EngineCoupling)
    requires IsSingleEngaged(c)
    ensures ClassifyGeometry(DeployCouplingAtDepth(c, 0)) == Axial
  {
  }

  lemma dual_engaged_yields_diagonal_z2(c: EngineCoupling)
    requires IsDualEngaged(c)
    ensures ClassifyGeometry(DeployCouplingAtDepth(c, 0)) == Diagonal
  {
  }

  function TriggerSecondaryGradient(c: EngineCoupling, newPol: Polarity): EngineCoupling {
    match (c.attente, c.controle)
    case (Pos,  Zero) => EngineCoupling(Pos,  newPol)
    case (Neg,  Zero) => EngineCoupling(Neg,  newPol)
    case (Zero, Pos)  => EngineCoupling(newPol, Pos)
    case (Zero, Neg)  => EngineCoupling(newPol, Neg)
    case (a,    ctrl) => EngineCoupling(a, ctrl)
  }

  lemma axial_to_diagonal_reallocation(c: EngineCoupling, newPol: Polarity)
    requires IsSingleEngaged(c) && PolarityIsEngaged(newPol)
    ensures var c' := TriggerSecondaryGradient(c, newPol);
      ClassifyGeometry(DeployCouplingAtDepth(c', 0)) == Diagonal &&
      DisplacementSum(DeployCouplingAtDepth(c', 0)) == 2
  {
  }

  lemma deployCouplingWithPrecision_budget_conservation(c: EngineCoupling, d: nat, piA: nat, piC: nat)
    requires !IsGlobalNeutrality(c)
    ensures DisplacementSum(DeployCouplingWithPrecision(c, d, piA, piC)) == 2 * d + 2
  {
    apportionRay_bounds(d, piA, piC);
  }

  lemma dual_engaged_yields_diagonal_z2_precision(c: EngineCoupling, piA: nat, piC: nat)
    requires IsDualEngaged(c)
    ensures ClassifyGeometry(DeployCouplingWithPrecision(c, 0, piA, piC)) == Diagonal
  {
    apportionRay_z2(piA, piC);
  }

  lemma deployCouplingAtDepth_not_lateral(c: EngineCoupling, d: nat)
    ensures ClassifyGeometry(DeployCouplingAtDepth(c, d)) != Lateral
  {
  }

  lemma symmetric_precision_never_lateral(s: PredictiveEngineState)
    requires s.attentional.precisionA == s.attentional.precisionC
    ensures ClassifyGeometry(ProjectToCoreAffect(s)) != Lateral
  {
    deployCouplingWithPrecision_symm_eq(
      CurrentCoupling(s),
      s.attentional.persistenceDepth,
      s.attentional.precisionA
    );
    deployCouplingAtDepth_not_lateral(CurrentCoupling(s), s.attentional.persistenceDepth);
  }

  function PolOfInt(v: int): Polarity {
    if v > 0 then Pos else if v < 0 then Neg else Zero
  }

  function WitnessEngineForPoint(p: CoreAffectPoint): PredictiveEngineState {
    if p.x == 0 && p.y == 0 then
      if p.z == 0 then
        DefaultPredictiveEngineState()
      else if p.z == 1 then
        PredictiveEngineState(
          SalientDiscrepancyRaw(2, 1, 1),
          PerceptiveInterface(Zero),
          SubjectiveInterface(Pos, false),
          AttentionalInterface(0, 1, 0, 1, 1)
        )
      else
        PredictiveEngineState(
          SalientDiscrepancyRaw(2, 1, 1),
          PerceptiveInterface(Zero),
          SubjectiveInterface(Pos, true),
          AttentionalInterface(0, 1, p.z - 2, 1, 1)
        )
    else
      var ax := AbsNat(p.x);
      var ay := AbsNat(p.y);
      var piPair := if ax == 0 || ay == 0 then (1, 1) else (ax, ay);
      var d: nat := if p.z >= 2 then p.z - 2 else 0;
      PredictiveEngineState(
        SalientDiscrepancyRaw(2, 1, 1),
        PerceptiveInterface(PolOfInt(p.y)),
        SubjectiveInterface(PolOfInt(p.x), true),
        AttentionalInterface(1, 1, d, piPair.0, piPair.1)
      )
  }

  lemma projectToCoreAffect_surjective(p: CoreAffectPoint)
    requires IsValidCoreAffect(p)
    ensures ProjectToCoreAffect(WitnessEngineForPoint(p)) == p
  {
    if p.x == 0 && p.y == 0 {
    } else {
      assert p.z >= 2;
      var d := p.z - 2;
      var ax := AbsNat(p.x);
      var ay := AbsNat(p.y);
      if ax >= 1 && ay >= 1 {
        apportionRay_exact(d, ax, ay);
      }
    }
  }

  lemma deployCouplingWithPrecision_nonneutral_crown(c: EngineCoupling, d: nat, piA: nat, piC: nat)
    requires !IsGlobalNeutrality(c)
    ensures DeployCouplingWithPrecision(c, d, piA, piC).z == d + 2
    ensures IsOnCrown(DeployCouplingWithPrecision(c, d, piA, piC))
  {
    apportionRay_bounds(d, piA, piC);
  }

  lemma engineStep_canonical_trajectory(s0: PredictiveEngineState)
    requires IsSensorilySalient(s0.discrepancy)
    requires IsGlobalNeutrality(CurrentCoupling(s0))
    requires !s0.subjective.descendingSuspension
    requires !AttentionalIsEngaged(s0.attentional)
    requires s0.attentional.persistenceDepth == 0
    ensures ProjectToCoreAffect(s0) == CoreAffectPoint(0, 0, 0)
    ensures ProjectToCoreAffect(EngineStep(s0)) == CoreAffectPoint(0, 0, 1)
    ensures ProjectToCoreAffect(EngineStep(EngineStep(s0))) == CoreAffectPoint(0, 0, 2)
    ensures ProjectToCoreAffect(EngineStep(EngineStep(EngineStep(s0)))) == CoreAffectPoint(0, 2, 2)
  {
  }

  lemma engineStep_surprise_to_crown(s1: PredictiveEngineState)
    requires IsSensorilySalient(s1.discrepancy)
    requires !IsGlobalNeutrality(CurrentCoupling(s1))
    requires !s1.subjective.descendingSuspension
    requires !AttentionalIsEngaged(s1.attentional)
    requires s1.attentional.persistenceDepth == 0
    ensures var p_crown := ProjectToCoreAffect(EngineStep(EngineStep(s1)));
      ProjectToCoreAffect(s1) == CoreAffectPoint(0, 0, 1) &&
      ProjectToCoreAffect(EngineStep(s1)) == CoreAffectPoint(0, 0, 2) &&
      p_crown == DeployCouplingWithPrecision(
        CurrentCoupling(s1), 0, s1.attentional.precisionA, s1.attentional.precisionC) &&
      p_crown.z == 2 &&
      IsOnCrown(p_crown)
  {
    deployCouplingWithPrecision_nonneutral_crown(
      CurrentCoupling(s1), 0, s1.attentional.precisionA, s1.attentional.precisionC);
  }

  // =========================================================================
  // 5. Loi de dissipation allostatique graduelle (Retour vers Veille)
  // =========================================================================

  function DissipationStep(p: CoreAffectPoint): CoreAffectPoint {
    if p.x != 0 || p.y != 0 then
      CoreAffectPoint(0, 0, p.z)
    else if p.z <= 2 then
      CoreAffectPoint(0, 0, 0)
    else
      CoreAffectPoint(0, 0, p.z - 1)
  }

  lemma dissipationStep_valid(p: CoreAffectPoint)
    ensures IsValidCoreAffect(DissipationStep(p))
  {
  }

  lemma anticipation_short_circuits_to_veille()
    ensures DissipationStep(CoreAffectPoint(0, 0, 2)) == CoreAffectPoint(0, 0, 0)
  {
  }

  lemma dissipation_from_ge2_never_visits_surprise(p: CoreAffectPoint)
    requires p.z >= 2
    ensures DissipationStep(p) != CoreAffectPoint(0, 0, 1)
  {
  }

  lemma pointDeVeille_is_fixed_point()
    ensures DissipationStep(CoreAffectPoint(0, 0, 0)) == CoreAffectPoint(0, 0, 0)
  {
  }

  lemma dissipationStep_fixed_iff(p: CoreAffectPoint)
    ensures DissipationStep(p) == p <==> p == CoreAffectPoint(0, 0, 0)
  {
  }

  function DissipationPotential(p: CoreAffectPoint): nat {
    2 * p.z + (if p.x != 0 || p.y != 0 then 1 else 0)
  }

  lemma dissipation_strictly_decreases(p: CoreAffectPoint)
    requires p != CoreAffectPoint(0, 0, 0)
    ensures DissipationPotential(DissipationStep(p)) < DissipationPotential(p)
  {
  }

  lemma dissipationPotential_short_circuit_jump()
    ensures DissipationPotential(CoreAffectPoint(0, 0, 2)) -
            DissipationPotential(DissipationStep(CoreAffectPoint(0, 0, 2))) == 4
  {
  }

  function RepeatDissipation(n: nat, p: CoreAffectPoint): CoreAffectPoint
    decreases n
  {
    if n == 0 then p else DissipationStep(RepeatDissipation(n - 1, p))
  }

  lemma RepeatDissipationStepShift(n: nat, p: CoreAffectPoint)
    ensures RepeatDissipation(n + 1, p) == RepeatDissipation(n, DissipationStep(p))
    decreases n
  {
    if n > 0 {
      RepeatDissipationStepShift(n - 1, p);
    }
  }

  lemma DissipationStepRepeatVeille(n: nat)
    ensures RepeatDissipation(n, CoreAffectPoint(0, 0, 0)) == CoreAffectPoint(0, 0, 0)
    decreases n
  {
    if n > 0 {
      DissipationStepRepeatVeille(n - 1);
    }
  }

  lemma DissipationCentralGe2ReachesVeille(k: nat)
    ensures RepeatDissipation(k + 2, CoreAffectPoint(0, 0, k + 2)) == CoreAffectPoint(0, 0, 0)
    decreases k
  {
    if k == 0 {
      RepeatDissipationStepShift(1, CoreAffectPoint(0, 0, 2));
      assert DissipationStep(CoreAffectPoint(0, 0, 2)) == CoreAffectPoint(0, 0, 0);
      DissipationStepRepeatVeille(1);
    } else {
      RepeatDissipationStepShift(k + 1, CoreAffectPoint(0, 0, k + 2));
      assert DissipationStep(CoreAffectPoint(0, 0, k + 2)) == CoreAffectPoint(0, 0, k + 1);
      DissipationCentralGe2ReachesVeille(k - 1);
    }
  }

  lemma DissipationCentralReachesVeille(z: nat)
    ensures RepeatDissipation(z, CoreAffectPoint(0, 0, z)) == CoreAffectPoint(0, 0, 0)
  {
    if z >= 2 {
      DissipationCentralGe2ReachesVeille(z - 2);
    }
  }

  lemma dissipation_reaches_veille(p: CoreAffectPoint)
    ensures RepeatDissipation(p.z + 1, p) == CoreAffectPoint(0, 0, 0)
  {
    if p.x != 0 || p.y != 0 {
      RepeatDissipationStepShift(p.z, p);
      assert DissipationStep(p) == CoreAffectPoint(0, 0, p.z);
      DissipationCentralReachesVeille(p.z);
    } else {
      DissipationCentralReachesVeille(p.z);
      assert RepeatDissipation(p.z + 1, p) == DissipationStep(RepeatDissipation(p.z, p));
    }
  }

  function AllostaticStep(d: SalientDiscrepancy, p: CoreAffectPoint): CoreAffectPoint {
    if d.magnitude < d.resorptionThreshold then
      DissipationStep(p)
    else
      p
  }

  lemma remanence_preserves_state(d: SalientDiscrepancy, p: CoreAffectPoint)
    requires IsInRemanenceWindow(d)
    ensures AllostaticStep(d, p) == p
  {
  }

  // =========================================================================
  // 6. Frontière du régime concurrentiel et cas limite de coopération
  // =========================================================================

  lemma cooperative_step_leaves_crown(p: CoreAffectPoint)
    requires IsOnCrown(p) && p.x >= 0 && p.y >= 0
    ensures !IsOnCrown(CoreAffectPoint(p.x + 1, p.y + 1, p.z))
  {
  }

  datatype ResourceRegime = Competitive | Cooperative

  predicate IsValidCoreAffectIn(regime: ResourceRegime, p: CoreAffectPoint) {
    match regime
    case Competitive => IsValidCoreAffect(p)
    case Cooperative => IsCentral(p) || (p.z >= 2 && CrownRadius(p.z) <= DisplacementSum(p))
  }

}
