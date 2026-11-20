/*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*/

include "PredictiveEngine.dfy"
include "CoreAffect.dfy"
include "AffectiveMatrix.dfy"

module PredictiveCircuit {
  import opened PredictiveEngine
  import opened CoreAffect
  import opened AffectiveMatrix

  // =========================================================================
  // 1. Les deux boucles à trois circuits et les six opérations de frontière
  // =========================================================================

  datatype CircuitLoop = ExpectationLoop | ControlLoop

  datatype InterfaceSide = InternalSide | ExternalSide

  datatype CircuitOperation =
    | SubjectiveOut
    | PerceptiveOut
    | AttentionalCrossingI
    | AttentionalCrossingII
    | SubjectiveIn
    | PerceptiveIn

  function AllCircuitOperations(): seq<CircuitOperation> {
    [
      SubjectiveOut,
      PerceptiveOut,
      AttentionalCrossingI,
      AttentionalCrossingII,
      SubjectiveIn,
      PerceptiveIn
    ]
  }

  function CircuitCarrierInterface(op: CircuitOperation): EngineInterface {
    match op
    case SubjectiveOut         => Subjective
    case SubjectiveIn          => Subjective
    case PerceptiveOut         => Perceptive
    case PerceptiveIn          => Perceptive
    case AttentionalCrossingI  => Attentional
    case AttentionalCrossingII => Attentional
  }

  function CircuitOperationSide(op: CircuitOperation): InterfaceSide {
    match op
    case SubjectiveOut         => InternalSide
    case PerceptiveOut         => InternalSide
    case AttentionalCrossingI  => InternalSide
    case AttentionalCrossingII => ExternalSide
    case SubjectiveIn          => ExternalSide
    case PerceptiveIn          => ExternalSide
  }

  predicate IsAgentPerceptible(op: CircuitOperation) {
    match op
    case AttentionalCrossingI => true
    case _                    => false
  }

  function ToInferentialOperation(op: CircuitOperation): InferentialOperation {
    match op
    case SubjectiveOut         => ContextualGenerative
    case SubjectiveIn          => ContextualGenerative
    case PerceptiveOut         => ActionImplementation
    case PerceptiveIn          => AscendingSensory
    case AttentionalCrossingI  => IntegrativeWeighting
    case AttentionalCrossingII => IntegrativeWeighting
  }

  // [1/41] circuit_covers_interfaces_both_sides
  lemma circuit_covers_interfaces_both_sides(iface: EngineInterface, s: InterfaceSide)
    ensures exists op: CircuitOperation ::
      CircuitCarrierInterface(op) == iface &&
      CircuitOperationSide(op) == s &&
      (forall op': CircuitOperation ::
        CircuitCarrierInterface(op') == iface && CircuitOperationSide(op') == s ==> op' == op)
  {
    match (iface, s)
    case (Perceptive,  InternalSide) => assert CircuitCarrierInterface(PerceptiveOut) == iface && CircuitOperationSide(PerceptiveOut) == s;
    case (Perceptive,  ExternalSide) => assert CircuitCarrierInterface(PerceptiveIn) == iface && CircuitOperationSide(PerceptiveIn) == s;
    case (Subjective,  InternalSide) => assert CircuitCarrierInterface(SubjectiveOut) == iface && CircuitOperationSide(SubjectiveOut) == s;
    case (Subjective,  ExternalSide) => assert CircuitCarrierInterface(SubjectiveIn) == iface && CircuitOperationSide(SubjectiveIn) == s;
    case (Attentional, InternalSide) => assert CircuitCarrierInterface(AttentionalCrossingI) == iface && CircuitOperationSide(AttentionalCrossingI) == s;
    case (Attentional, ExternalSide) => assert CircuitCarrierInterface(AttentionalCrossingII) == iface && CircuitOperationSide(AttentionalCrossingII) == s;
  }

  // [2/41] circuit_refines_inferential_ops
  lemma circuit_refines_inferential_ops(iop: InferentialOperation)
    ensures exists op: CircuitOperation :: ToInferentialOperation(op) == iop
  {
    match iop
    case AscendingSensory     => assert ToInferentialOperation(PerceptiveIn) == iop;
    case ActionImplementation => assert ToInferentialOperation(PerceptiveOut) == iop;
    case ContextualGenerative => assert ToInferentialOperation(SubjectiveOut) == iop;
    case IntegrativeWeighting => assert ToInferentialOperation(AttentionalCrossingI) == iop;
  }

  // =========================================================================
  // 2. Bijection L1 Phi : Omega_II <-> Omega_I, transposition et 9 canaux
  // =========================================================================

  datatype ProtoSpatialNode = ProtoSpatialNode(x: int, y: int)

  function L1Norm(n: ProtoSpatialNode): nat {
    AbsNat(n.x) + AbsNat(n.y)
  }

  predicate IsValidProtoSpatial(n: ProtoSpatialNode) {
    (n.x == 0 && n.y == 0) || L1Norm(n) == 2
  }

  function PhiL1(c: EngineCoupling): ProtoSpatialNode {
    match (c.attente, c.controle)
    case (Zero, Zero) => ProtoSpatialNode(0, 0)
    case (Pos,  Zero) => ProtoSpatialNode(2, 0)
    case (Neg,  Zero) => ProtoSpatialNode(-2, 0)
    case (Zero, Pos)  => ProtoSpatialNode(0, 2)
    case (Zero, Neg)  => ProtoSpatialNode(0, -2)
    case (Pos,  Pos)  => ProtoSpatialNode(1, 1)
    case (Pos,  Neg)  => ProtoSpatialNode(1, -1)
    case (Neg,  Pos)  => ProtoSpatialNode(-1, 1)
    case (Neg,  Neg)  => ProtoSpatialNode(-1, -1)
  }

  function PhiL1Inv(n: ProtoSpatialNode): EngineCoupling {
    EngineCoupling(PolOfInt(n.x), PolOfInt(n.y))
  }

  function IdxAttente(p: Polarity): nat {
    match p
    case Zero => 0
    case Neg  => 1
    case Pos  => 2
  }

  function IdxControle(p: Polarity): nat {
    match p
    case Pos  => 0
    case Neg  => 1
    case Zero => 2
  }

  function CrossingIPos(c: EngineCoupling): (nat, nat) {
    (IdxAttente(c.attente), IdxControle(c.controle))
  }

  function CrossingIIPos(c: EngineCoupling): (nat, nat) {
    (IdxControle(c.controle), IdxAttente(c.attente))
  }

  datatype SubjectiveReturnChannel = SubjectiveReturnChannel(
    regimeA: FunctionalRegime,
    contextC: Polarity
  )

  datatype PerceptiveReturnChannel = PerceptiveReturnChannel(
    regimeC: FunctionalRegime,
    contextA: Polarity
  )

  function RouteToSubjective(c: EngineCoupling): SubjectiveReturnChannel {
    SubjectiveReturnChannel(PolarityToRegime(c.attente), c.controle)
  }

  function RouteToPerceptive(c: EngineCoupling): PerceptiveReturnChannel {
    PerceptiveReturnChannel(PolarityToRegime(c.controle), c.attente)
  }

  // [3/41] phiL1_left_inv
  lemma phiL1_left_inv(c: EngineCoupling)
    ensures PhiL1Inv(PhiL1(c)) == c
  {}

  // [4/41] phiL1_right_inv
  lemma phiL1_right_inv(n: ProtoSpatialNode)
    requires IsValidProtoSpatial(n)
    ensures PhiL1(PhiL1Inv(n)) == n
  {}

  // [5/41] phiL1_agrees_with_deployZ2
  lemma phiL1_agrees_with_deployZ2(c: EngineCoupling)
    ensures PhiL1(c).x == DeployCouplingAtDepth(c, 0).x
    ensures PhiL1(c).y == DeployCouplingAtDepth(c, 0).y
  {}

  // [6/41] crossingII_is_transpose_of_crossingI
  lemma crossingII_is_transpose_of_crossingI(c: EngineCoupling)
    ensures CrossingIIPos(c) == (CrossingIPos(c).1, CrossingIPos(c).0)
  {}

  // [7/41] routeToSubjective_injective
  lemma routeToSubjective_injective(c1: EngineCoupling, c2: EngineCoupling)
    requires RouteToSubjective(c1) == RouteToSubjective(c2)
    ensures c1 == c2
  {}

  // [8/41] routeToPerceptive_injective
  lemma routeToPerceptive_injective(c1: EngineCoupling, c2: EngineCoupling)
    requires RouteToPerceptive(c1) == RouteToPerceptive(c2)
    ensures c1 == c2
  {}

  // =========================================================================
  // 3. Projection perceptible Pi_Z certifiée dans CoreAffectState
  // =========================================================================

  function ProjectPerceptible(
    c: EngineCoupling,
    z: nat,
    piA: nat,
    piC: nat,
    descendingSusp: bool
  ): CoreAffectPoint {
    if IsGlobalNeutrality(c) then
      if descendingSusp && z >= 2 then CoreAffectPoint(0, 0, z) else CoreAffectPoint(0, 0, 0)
    else if z == 0 then CoreAffectPoint(0, 0, 0)
    else if z == 1 then CoreAffectPoint(0, 0, 1)
    else DeployCouplingWithPrecision(c, z - 2, piA, piC)
  }

  // [9/41] projectPerceptible_valid
  lemma projectPerceptible_valid(c: EngineCoupling, z: nat, piA: nat, piC: nat, susp: bool)
    ensures IsValidCoreAffect(ProjectPerceptible(c, z, piA, piC, susp))
  {
    if !IsGlobalNeutrality(c) && z >= 2 {
      deployCouplingWithPrecision_valid(c, z - 2, piA, piC);
    }
  }

  function ProjectPerceptibleState(
    c: EngineCoupling,
    z: nat,
    piA: nat,
    piC: nat,
    descendingSusp: bool
  ): CoreAffectState {
    projectPerceptible_valid(c, z, piA, piC, descendingSusp);
    ProjectPerceptible(c, z, piA, piC, descendingSusp)
  }

  // [10/41] projectPerceptible_z2_matches_phiL1
  lemma projectPerceptible_z2_matches_phiL1(c: EngineCoupling, piA: nat, piC: nat, susp: bool)
    requires !IsGlobalNeutrality(c)
    ensures ProjectPerceptible(c, 2, piA, piC, susp) == CoreAffectPoint(PhiL1(c).x, PhiL1(c).y, 2)
  {
    apportionRay_z2(piA, piC);
  }

  // [11/41] projectPerceptible_neutral_elevates_to_central
  lemma projectPerceptible_neutral_elevates_to_central(z: nat, piA: nat, piC: nat)
    requires z >= 2
    ensures ProjectPerceptible(EngineCoupling(Zero, Zero), z, piA, piC, true) == CoreAffectPoint(0, 0, z)
  {}

  // =========================================================================
  // 4. Goulot attentionnel L1 et potentiel de Lyapunov V
  // =========================================================================

  function AttentionalWeightX2(c: EngineCoupling): nat {
    if c.attente == Zero then 2 else AbsNat(PhiL1(c).x)
  }

  function AttentionalWeightY2(c: EngineCoupling): nat {
    if c.controle == Zero then 2 else AbsNat(PhiL1(c).y)
  }

  function PolarityEnergy(p: Polarity): nat {
    match p
    case Zero => 0
    case Pos  => 1
    case Neg  => 2
  }

  function LyapunovPotential(c: EngineCoupling): nat {
    PolarityEnergy(c.attente) + PolarityEnergy(c.controle)
  }

  // [12/41] attentional_bottleneck_sum_active
  lemma attentional_bottleneck_sum_active(c: EngineCoupling)
    requires !IsGlobalNeutrality(c)
    ensures (if PolarityIsEngaged(c.attente) then AttentionalWeightX2(c) else 0) +
            (if PolarityIsEngaged(c.controle) then AttentionalWeightY2(c) else 0) == 2
  {}

  // =========================================================================
  // 5. Noyau markovien couplé exact (4 * scale ^ 6)
  // =========================================================================

  function IsCharged(p: Polarity): bool {
    p == Neg
  }

  datatype CircuitKernelParamsRaw = CircuitKernelParamsRaw(
    scale: nat,
    rho: nat,
    kappa: nat,
    deltaA: nat,
    deltaC: nat,
    gammaA: nat,
    gammaC: nat,
    epsilon: nat,
    qPosA: nat,
    qPosC: nat,
    chi: nat
  )

  predicate ValidCircuitKernelParams(p: CircuitKernelParamsRaw) {
    p.scale > 0 &&
    p.rho <= p.scale && p.kappa <= p.scale &&
    p.deltaA <= p.scale && p.deltaC <= p.scale &&
    p.rho + p.deltaA <= p.scale && p.kappa + p.deltaC <= p.scale &&
    p.gammaA <= p.scale && p.gammaC <= p.scale &&
    p.epsilon <= p.scale &&
    p.qPosA <= p.scale && p.qPosC <= p.scale &&
    p.chi <= p.scale
  }

  type CircuitKernelParams = p: CircuitKernelParamsRaw | ValidCircuitKernelParams(p)
    witness CircuitKernelParamsRaw(100, 80, 80, 0, 0, 70, 70, 15, 35, 35, 25)

  function DefaultCircuitKernelParams(): CircuitKernelParams {
    CircuitKernelParamsRaw(100, 80, 80, 0, 0, 70, 70, 15, 35, 35, 25)
  }

  function Pow5(m: nat): nat { m * m * m * m * m }
  function Pow6(m: nat): nat { m * m * m * m * m * m }

  function EffectiveEpsScaled(m: nat, eps: nat, chi: nat, otherCharged: bool): nat
    requires eps <= m
  {
    if otherCharged then m * eps + chi * (m - eps) else m * eps
  }

  lemma EffectiveEpsScaledBounds(m: nat, eps: nat, chi: nat, otherCharged: bool)
    requires eps <= m && chi <= m
    ensures EffectiveEpsScaled(m, eps, chi, otherCharged) <= m * m
  {
    if otherCharged {
      assert chi * (m - eps) <= m * (m - eps);
      assert m * eps + m * (m - eps) == m * m;
    }
  }

  lemma EffectiveEpsScaledSubPos(m: nat, eps: nat, chi: nat, otherCharged: bool)
    requires eps < m && chi < m
    ensures EffectiveEpsScaled(m, eps, chi, otherCharged) < m * m
  {
    if otherCharged {
      assert m - eps > 0;
      assert chi * (m - eps) < m * (m - eps);
      assert m * eps + m * (m - eps) == m * m;
    }
  }

  lemma MulLeTwoRight(w2: nat, x: nat)
    requires w2 <= 2
    ensures w2 * x <= 2 * x
  {}

  lemma PosMulPos(a: nat, b: nat)
    requires a > 0 && b > 0
    ensures a * b > 0
  {}

  lemma MulDistLe(a: nat, b: nat, k: nat)
    ensures a * b <= (b + k) * a
  {
    assert (b + k) * a == b * a + k * a;
    assert b * a == a * b;
  }

  lemma MulDistLt(a: nat, b: nat, k: nat)
    requires a > 0 && k > 0
    ensures a * b < (b + k) * a
  {
    assert (b + k) * a == b * a + k * a;
    assert b * a == a * b;
    assert k * a >= 1 * a == a > 0;
  }

  lemma MulLtRightPos(m: nat, a: nat, b: nat)
    requires m > 0 && a < b
    ensures m * a < m * b
  {
    PosMulPos(m, b - a);
    assert m * b == m * a + m * (b - a);
  }

  function NatProd(a: nat, b: nat): nat {
    a * b
  }

  opaque function {:isolate_assertions} MarginalWeight(
    m: nat, rate: nat, delta: nat, deseng: nat, eps: nat, qPos: nat, chi: nat,
    otherCharged: bool, w2: nat, src: Polarity, dst: Polarity
  ): nat
    requires rate + delta <= m && deseng <= m && eps <= m && qPos <= m && chi <= m && w2 <= 2
  {
    EffectiveEpsScaledBounds(m, eps, chi, otherCharged);
    MulLeTwoRight(w2, rate);
    MulLeTwoRight(w2, deseng);
    var m2: nat := NatProd(m, m);
    var e2: nat := EffectiveEpsScaled(m, eps, chi, otherCharged);
    var compE: nat := m2 - e2;
    var stayNeg: nat := 2 * m - w2 * rate - 2 * delta;
    var stayPos: nat := 2 * m - w2 * deseng;
    match (src, dst)
    case (Zero, Zero) => NatProd(2 * m, compE)
    case (Zero, Neg)  => NatProd(2 * e2, m - qPos)
    case (Zero, Pos)  => NatProd(2 * e2, qPos)
    case (Neg,  Zero) => NatProd(m2, 2 * delta)
    case (Neg,  Neg)  => NatProd(m2, stayNeg)
    case (Neg,  Pos)  => NatProd(m2, w2 * rate)
    case (Pos,  Zero) => NatProd(compE, w2 * deseng)
    case (Pos,  Neg)  => NatProd(2 * m, e2)
    case (Pos,  Pos)  => NatProd(compE, stayPos)
  }

  function CircuitWeight(p: CircuitKernelParams, src: EngineCoupling, dst: EngineCoupling): nat {
    var mwA := MarginalWeight(
      p.scale, p.rho, p.deltaA, p.gammaA, p.epsilon, p.qPosA, p.chi,
      IsCharged(src.controle), AttentionalWeightX2(src), src.attente, dst.attente);
    var mwC := MarginalWeight(
      p.scale, p.kappa, p.deltaC, p.gammaC, p.epsilon, p.qPosC, p.chi,
      IsCharged(src.attente), AttentionalWeightY2(src), src.controle, dst.controle);
    mwA * mwC
  }

  function SumCircuitWeights(p: CircuitKernelParams, src: EngineCoupling, dsts: seq<EngineCoupling>): nat
    decreases |dsts|
  {
    if |dsts| == 0 then 0
    else CircuitWeight(p, src, dsts[0]) + SumCircuitWeights(p, src, dsts[1..])
  }

  function CircuitRowSum(p: CircuitKernelParams, src: EngineCoupling): nat {
    SumCircuitWeights(p, src, AllCouplings())
  }

  lemma MarginalWeightSum(
    m: nat, rate: nat, delta: nat, deseng: nat, eps: nat, qPos: nat, chi: nat,
    otherCharged: bool, w2: nat, src: Polarity
  )
    requires rate + delta <= m && deseng <= m && eps <= m && qPos <= m && chi <= m && w2 <= 2
    ensures MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, otherCharged, w2, src, Zero) +
            MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, otherCharged, w2, src, Neg) +
            MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, otherCharged, w2, src, Pos) == 2 * m * m * m
  {
    EffectiveEpsScaledBounds(m, eps, chi, otherCharged);
    reveal MarginalWeight();
    var e2 := EffectiveEpsScaled(m, eps, chi, otherCharged);
    match src
    case Neg =>
      calc == {
        MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, otherCharged, w2, Neg, Zero) +
        MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, otherCharged, w2, Neg, Neg) +
        MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, otherCharged, w2, Neg, Pos);
        m * m * (2 * delta) + m * m * (2 * m - w2 * rate - 2 * delta) + m * m * (w2 * rate);
        m * m * (2 * delta + (2 * m - w2 * rate - 2 * delta) + w2 * rate);
        m * m * (2 * m);
        2 * m * m * m;
      }
    case Zero =>
      calc == {
        MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, otherCharged, w2, Zero, Zero) +
        MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, otherCharged, w2, Zero, Neg) +
        MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, otherCharged, w2, Zero, Pos);
        2 * m * (m * m - e2) + 2 * e2 * (m - qPos) + 2 * e2 * qPos;
        2 * m * (m * m - e2) + 2 * e2 * ((m - qPos) + qPos);
        2 * m * (m * m - e2) + 2 * m * e2;
        2 * m * ((m * m - e2) + e2);
        2 * m * m * m;
      }
    case Pos =>
      calc == {
        MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, otherCharged, w2, Pos, Zero) +
        MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, otherCharged, w2, Pos, Neg) +
        MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, otherCharged, w2, Pos, Pos);
        (m * m - e2) * (w2 * deseng) + 2 * m * e2 + (m * m - e2) * (2 * m - w2 * deseng);
        (m * m - e2) * (w2 * deseng + (2 * m - w2 * deseng)) + 2 * m * e2;
        (m * m - e2) * (2 * m) + 2 * m * e2;
        2 * m * ((m * m - e2) + e2);
        2 * m * m * m;
      }
  }

  lemma SumCircuitWeightsUnroll(p: CircuitKernelParams, src: EngineCoupling)
    ensures CircuitRowSum(p, src) ==
      CircuitWeight(p, src, EngineCoupling(Zero, Zero)) +
      CircuitWeight(p, src, EngineCoupling(Pos,  Zero)) +
      CircuitWeight(p, src, EngineCoupling(Neg,  Zero)) +
      CircuitWeight(p, src, EngineCoupling(Zero, Pos))  +
      CircuitWeight(p, src, EngineCoupling(Zero, Neg))  +
      CircuitWeight(p, src, EngineCoupling(Pos,  Pos))  +
      CircuitWeight(p, src, EngineCoupling(Pos,  Neg))  +
      CircuitWeight(p, src, EngineCoupling(Neg,  Pos))  +
      CircuitWeight(p, src, EngineCoupling(Neg,  Neg))
  {
    var s := AllCouplings();
    assert s[0] == EngineCoupling(Zero, Zero);
    assert s[1..][0] == EngineCoupling(Pos, Zero);
    assert s[1..][1..][0] == EngineCoupling(Neg, Zero);
    assert s[1..][1..][1..][0] == EngineCoupling(Zero, Pos);
    assert s[1..][1..][1..][1..][0] == EngineCoupling(Zero, Neg);
    assert s[1..][1..][1..][1..][1..][0] == EngineCoupling(Pos, Pos);
    assert s[1..][1..][1..][1..][1..][1..][0] == EngineCoupling(Pos, Neg);
    assert s[1..][1..][1..][1..][1..][1..][1..][0] == EngineCoupling(Neg, Pos);
    assert s[1..][1..][1..][1..][1..][1..][1..][1..][0] == EngineCoupling(Neg, Neg);
    assert s[1..][1..][1..][1..][1..][1..][1..][1..][1..] == [];
  }

  lemma SumNineOuter(a0: nat, a1: nat, a2: nat, c0: nat, c1: nat, c2: nat)
    ensures a0*c0 + a2*c0 + a1*c0 + a0*c2 + a0*c1 + a2*c2 + a2*c1 + a1*c2 + a1*c1 ==
            (a0 + a1 + a2) * (c0 + c1 + c2)
  {}

  lemma FactorSquareProd(sA: nat, sC: nat, m: nat)
    requires sA == 2 * (m * m * m) && sC == 2 * (m * m * m)
    ensures sA * sC == 4 * Pow6(m)
  {
    var m3 := m * m * m;
    calc == {
      sA * sC;
      (2 * m3) * (2 * m3);
      4 * (m3 * m3);
      4 * Pow6(m);
    }
  }

  // [13/41] circuitRowSum_exact
  lemma {:isolate_assertions} circuitRowSum_exact(p: CircuitKernelParams, src: EngineCoupling)
    ensures CircuitRowSum(p, src) == 4 * Pow6(p.scale)
  {
    var m := p.scale;
    var a0 := MarginalWeight(m, p.rho, p.deltaA, p.gammaA, p.epsilon, p.qPosA, p.chi,
      IsCharged(src.controle), AttentionalWeightX2(src), src.attente, Zero);
    var a1 := MarginalWeight(m, p.rho, p.deltaA, p.gammaA, p.epsilon, p.qPosA, p.chi,
      IsCharged(src.controle), AttentionalWeightX2(src), src.attente, Neg);
    var a2 := MarginalWeight(m, p.rho, p.deltaA, p.gammaA, p.epsilon, p.qPosA, p.chi,
      IsCharged(src.controle), AttentionalWeightX2(src), src.attente, Pos);
    var c0 := MarginalWeight(m, p.kappa, p.deltaC, p.gammaC, p.epsilon, p.qPosC, p.chi,
      IsCharged(src.attente), AttentionalWeightY2(src), src.controle, Zero);
    var c1 := MarginalWeight(m, p.kappa, p.deltaC, p.gammaC, p.epsilon, p.qPosC, p.chi,
      IsCharged(src.attente), AttentionalWeightY2(src), src.controle, Neg);
    var c2 := MarginalWeight(m, p.kappa, p.deltaC, p.gammaC, p.epsilon, p.qPosC, p.chi,
      IsCharged(src.attente), AttentionalWeightY2(src), src.controle, Pos);
    calc == {
      CircuitRowSum(p, src);
      { SumCircuitWeightsUnroll(p, src); }
      CircuitWeight(p, src, EngineCoupling(Zero, Zero)) +
      CircuitWeight(p, src, EngineCoupling(Pos,  Zero)) +
      CircuitWeight(p, src, EngineCoupling(Neg,  Zero)) +
      CircuitWeight(p, src, EngineCoupling(Zero, Pos))  +
      CircuitWeight(p, src, EngineCoupling(Zero, Neg))  +
      CircuitWeight(p, src, EngineCoupling(Pos,  Pos))  +
      CircuitWeight(p, src, EngineCoupling(Pos,  Neg))  +
      CircuitWeight(p, src, EngineCoupling(Neg,  Pos))  +
      CircuitWeight(p, src, EngineCoupling(Neg,  Neg));
      a0*c0 + a2*c0 + a1*c0 + a0*c2 + a0*c1 + a2*c2 + a2*c1 + a1*c2 + a1*c1;
      { SumNineOuter(a0, a1, a2, c0, c1, c2); }
      (a0 + a1 + a2) * (c0 + c1 + c2);
      {
        MarginalWeightSum(m, p.rho, p.deltaA, p.gammaA, p.epsilon, p.qPosA, p.chi,
          IsCharged(src.controle), AttentionalWeightX2(src), src.attente);
        MarginalWeightSum(m, p.kappa, p.deltaC, p.gammaC, p.epsilon, p.qPosC, p.chi,
          IsCharged(src.attente), AttentionalWeightY2(src), src.controle);
        FactorSquareProd(a0 + a1 + a2, c0 + c1 + c2, m);
      }
      4 * Pow6(m);
    }
  }

  // [14/41] veille_absorbing_free
  lemma veille_absorbing_free(p: CircuitKernelParams, dst: EngineCoupling)
    requires p.epsilon == 0
    ensures CircuitWeight(p, EngineCoupling(Zero, Zero), dst) ==
      (if dst == EngineCoupling(Zero, Zero) then 4 * Pow6(p.scale) else 0)
  {
    reveal MarginalWeight();
    var m := p.scale;
    if dst == EngineCoupling(Zero, Zero) {
      assert (2 * m * (m * m)) * (2 * m * (m * m)) == 4 * Pow6(m);
    }
  }

  lemma MarginalLyapunovMonotone(
    m: nat, rate: nat, delta: nat, deseng: nat, qPos: nat,
    otherCharged: bool, w2: nat, src: Polarity, dst: Polarity
  )
    requires rate + delta <= m && deseng <= m && qPos <= m && w2 <= 2
    requires MarginalWeight(m, rate, delta, deseng, 0, qPos, 0, otherCharged, w2, src, dst) > 0
    ensures PolarityEnergy(dst) <= PolarityEnergy(src)
  {
    reveal MarginalWeight();
  }

  // [15/41] lyapunov_monotone_free
  lemma lyapunov_monotone_free(p: CircuitKernelParams, src: EngineCoupling, dst: EngineCoupling)
    requires p.epsilon == 0 && p.chi == 0 && CircuitWeight(p, src, dst) > 0
    ensures LyapunovPotential(dst) <= LyapunovPotential(src)
  {
    MarginalLyapunovMonotone(
      p.scale, p.rho, p.deltaA, p.gammaA, p.qPosA,
      IsCharged(src.controle), AttentionalWeightX2(src), src.attente, dst.attente);
    MarginalLyapunovMonotone(
      p.scale, p.kappa, p.deltaC, p.gammaC, p.qPosC,
      IsCharged(src.attente), AttentionalWeightY2(src), src.controle, dst.controle);
  }

  function StepDownPol(p: Polarity): Polarity {
    match p
    case Zero => Zero
    case Neg  => Pos
    case Pos  => Zero
  }

  // [16/41] lyapunov_strict_descent_witness
  lemma lyapunov_strict_descent_witness(p: CircuitKernelParams, src: EngineCoupling)
    requires p.epsilon == 0 && p.chi == 0
    requires p.rho > 0 && p.kappa > 0 && p.gammaA > 0 && p.gammaC > 0
    requires !IsGlobalNeutrality(src)
    ensures exists dst: EngineCoupling ::
      CircuitWeight(p, src, dst) > 0 && LyapunovPotential(dst) < LyapunovPotential(src)
  {
    reveal MarginalWeight();
    var dst := EngineCoupling(StepDownPol(src.attente), StepDownPol(src.controle));
    var m := p.scale;
    assert m * m > 0;
    assert AttentionalWeightX2(src) > 0 && AttentionalWeightY2(src) > 0;
    assert MarginalWeight(m, p.rho, p.deltaA, p.gammaA, 0, p.qPosA, 0,
      IsCharged(src.controle), AttentionalWeightX2(src), src.attente, dst.attente) > 0;
    assert MarginalWeight(m, p.kappa, p.deltaC, p.gammaC, 0, p.qPosC, 0,
      IsCharged(src.attente), AttentionalWeightY2(src), src.controle, dst.controle) > 0;
    assert CircuitWeight(p, src, dst) > 0;
    assert LyapunovPotential(dst) < LyapunovPotential(src);
  }

  function WeightedDriftSumList(p: CircuitKernelParams, src: EngineCoupling, dsts: seq<EngineCoupling>): int
    decreases |dsts|
  {
    if |dsts| == 0 then 0
    else (CircuitWeight(p, src, dsts[0]) as int) *
           ((LyapunovPotential(src) as int) - (LyapunovPotential(dsts[0]) as int)) +
         WeightedDriftSumList(p, src, dsts[1..])
  }

  function WeightedDriftSum(p: CircuitKernelParams, src: EngineCoupling): int {
    WeightedDriftSumList(p, src, AllCouplings())
  }

  function WeightedDriftTerm(p: CircuitKernelParams, src: EngineCoupling, dst: EngineCoupling): int {
    (CircuitWeight(p, src, dst) as int) *
      ((LyapunovPotential(src) as int) - (LyapunovPotential(dst) as int))
  }

  lemma WeightedDriftSumUnroll(p: CircuitKernelParams, src: EngineCoupling)
    ensures WeightedDriftSum(p, src) ==
      WeightedDriftTerm(p, src, EngineCoupling(Zero, Zero)) +
      WeightedDriftTerm(p, src, EngineCoupling(Pos,  Zero)) +
      WeightedDriftTerm(p, src, EngineCoupling(Neg,  Zero)) +
      WeightedDriftTerm(p, src, EngineCoupling(Zero, Pos))  +
      WeightedDriftTerm(p, src, EngineCoupling(Zero, Neg))  +
      WeightedDriftTerm(p, src, EngineCoupling(Pos,  Pos))  +
      WeightedDriftTerm(p, src, EngineCoupling(Pos,  Neg))  +
      WeightedDriftTerm(p, src, EngineCoupling(Neg,  Pos))  +
      WeightedDriftTerm(p, src, EngineCoupling(Neg,  Neg))
  {
    var s := AllCouplings();
    assert s[0] == EngineCoupling(Zero, Zero);
    assert s[1..][0] == EngineCoupling(Pos, Zero);
    assert s[1..][1..][0] == EngineCoupling(Neg, Zero);
    assert s[1..][1..][1..][0] == EngineCoupling(Zero, Pos);
    assert s[1..][1..][1..][1..][0] == EngineCoupling(Zero, Neg);
    assert s[1..][1..][1..][1..][1..][0] == EngineCoupling(Pos, Pos);
    assert s[1..][1..][1..][1..][1..][1..][0] == EngineCoupling(Pos, Neg);
    assert s[1..][1..][1..][1..][1..][1..][1..][0] == EngineCoupling(Neg, Pos);
    assert s[1..][1..][1..][1..][1..][1..][1..][1..][0] == EngineCoupling(Neg, Neg);
    assert s[1..][1..][1..][1..][1..][1..][1..][1..][1..] == [];
  }

  // [17/41] lyapunov_expected_drift_constant
  lemma lyapunov_expected_drift_constant(p: CircuitKernelParams, r: nat, src: EngineCoupling)
    requires p.epsilon == 0 && p.chi == 0 && p.deltaA == 0 && p.deltaC == 0
    requires p.rho == r && p.kappa == r && p.gammaA == r && p.gammaC == r
    requires !IsGlobalNeutrality(src)
    ensures WeightedDriftSum(p, src) == 4 * Pow5(p.scale) * r
  {
    reveal MarginalWeight();
    WeightedDriftSumUnroll(p, src);
    var m := p.scale;
    var m2 := m * m;
    assert EffectiveEpsScaled(m, 0, 0, false) == 0 && EffectiveEpsScaled(m, 0, 0, true) == 0;
    match (src.attente, src.controle)
    case (Pos,  Zero) =>
      assert WeightedDriftSum(p, src) == (m2 * (2 * r)) * (2 * m * m2);
      assert (m2 * (2 * r)) * (2 * m * m2) == 4 * Pow5(m) * r;
    case (Neg,  Zero) =>
      assert WeightedDriftSum(p, src) == (m2 * (2 * r)) * (2 * m * m2);
      assert (m2 * (2 * r)) * (2 * m * m2) == 4 * Pow5(m) * r;
    case (Zero, Pos)  =>
      assert WeightedDriftSum(p, src) == (2 * m * m2) * (m2 * (2 * r));
      assert (2 * m * m2) * (m2 * (2 * r)) == 4 * Pow5(m) * r;
    case (Zero, Neg)  =>
      assert WeightedDriftSum(p, src) == (2 * m * m2) * (m2 * (2 * r));
      assert (2 * m * m2) * (m2 * (2 * r)) == 4 * Pow5(m) * r;
    case _ =>
      var a := m2 * r;
      var b := m2 * (2 * m - r);
      assert WeightedDriftSum(p, src) == a * b + b * a + 2 * (a * a);
      calc == {
        a * b + b * a + 2 * (a * a);
        2 * (a * (b + a));
        2 * ((m2 * r) * (2 * m * m2));
        4 * Pow5(m) * r;
      }
  }

  lemma MarginalFromZeroPos(
    m: nat, rate: nat, delta: nat, deseng: nat, eps: nat, qPos: nat, chi: nat, w2: nat, dst: Polarity
  )
    requires rate + delta <= m && deseng <= m && eps > 0 && eps < m && qPos > 0 && qPos < m && chi <= m && w2 <= 2
    ensures MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, false, w2, Zero, dst) > 0
  {
    reveal MarginalWeight();
    var m2 := m * m;
    var e2 := EffectiveEpsScaled(m, eps, chi, false);
    assert e2 == m * eps;
    MulLtRightPos(m, eps, m);
    assert m * eps < m * m;
    PosMulPos(m, eps);
    assert e2 > 0 && m2 - e2 > 0;
    match dst
    case Zero =>
      PosMulPos(2 * m, m2 - e2);
    case Neg =>
      PosMulPos(2 * e2, m - qPos);
    case Pos =>
      PosMulPos(2 * e2, qPos);
  }

  lemma MarginalToMidPos(
    m: nat, rate: nat, delta: nat, deseng: nat, eps: nat, qPos: nat, chi: nat,
    otherCharged: bool, w2: nat, src: Polarity
  )
    requires rate + delta <= m && deseng <= m && eps <= m && qPos <= m && chi <= m && w2 > 0 && w2 <= 2
    requires eps < m && chi < m && rate > 0 && deseng > 0
    ensures (
      var midPol := StepDownPol(src);
      MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, otherCharged, w2, src, midPol) > 0
    )
  {
    reveal MarginalWeight();
    EffectiveEpsScaledSubPos(m, eps, chi, otherCharged);
    var m2 := m * m;
    var e2 := EffectiveEpsScaled(m, eps, chi, otherCharged);
    PosMulPos(m, m);
    match src
    case Zero =>
      PosMulPos(2 * m, m2 - e2);
    case Neg =>
      PosMulPos(w2, rate);
      PosMulPos(m2, w2 * rate);
    case Pos =>
      PosMulPos(w2, deseng);
      PosMulPos(m2 - e2, w2 * deseng);
  }

  lemma MarginalMidToZeroPos(
    m: nat, rate: nat, delta: nat, deseng: nat, eps: nat, qPos: nat, chi: nat,
    otherCharged: bool, w2: nat, src: Polarity
  )
    requires rate + delta <= m && deseng <= m && eps <= m && qPos <= m && chi <= m && w2 > 0 && w2 <= 2
    requires eps < m && chi < m && deseng > 0 && src != Neg
    ensures MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, otherCharged, w2, src, Zero) > 0
  {
    reveal MarginalWeight();
    EffectiveEpsScaledSubPos(m, eps, chi, otherCharged);
    var m2 := m * m;
    var e2 := EffectiveEpsScaled(m, eps, chi, otherCharged);
    match src
    case Zero =>
      PosMulPos(2 * m, m2 - e2);
    case Pos =>
      PosMulPos(w2, deseng);
      PosMulPos(m2 - e2, w2 * deseng);
  }

  lemma EffectiveEpsChargedPos(m: nat, eps: nat, chi: nat)
    requires m > 0 && eps <= m && chi > 0
    ensures EffectiveEpsScaled(m, eps, chi, true) > 0
  {
    if eps > 0 {
      PosMulPos(m, eps);
      var t2: nat := NatProd(chi, m - eps);
      assert chi * (m - eps) == t2 >= 0;
    } else {
      assert m - eps == m > 0;
      PosMulPos(chi, m);
    }
  }

  lemma MarginalNegStayLessPos(
    m: nat, rate: nat, delta: nat, deseng: nat, eps: nat, qPos: nat, chi: nat,
    otherCharged: bool, w2: nat
  )
    requires rate + delta < m && deseng <= m && eps <= m && qPos <= m && chi <= m && w2 <= 2
    ensures MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, otherCharged, w2, Neg, Neg) > 0
  {
    reveal MarginalWeight();
    PosMulPos(m, m);
    MulLeTwoRight(w2, rate);
    assert 2 * m - w2 * rate - 2 * delta >= 2;
    PosMulPos(m * m, 2 * m - w2 * rate - 2 * delta);
  }

  lemma MarginalZeroChargedTargetPos(
    m: nat, rate: nat, delta: nat, deseng: nat, eps: nat, qPos: nat, chi: nat, w2: nat
  )
    requires m > 0 && rate + delta <= m && deseng <= m && eps <= m && chi > 0 && chi <= m && w2 <= 2
    requires qPos > 0 && qPos < m
    ensures MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, true, w2, Zero, Pos) > 0
    ensures MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, true, w2, Zero, Neg) > 0
  {
    reveal MarginalWeight();
    EffectiveEpsChargedPos(m, eps, chi);
    var e2 := EffectiveEpsScaled(m, eps, chi, true);
    PosMulPos(2 * e2, qPos);
    PosMulPos(2 * e2, m - qPos);
  }

  // [18/41] axial_peur_bifurcates_p2
  lemma axial_peur_bifurcates_p2(p: CircuitKernelParams)
    requires p.chi > 0 && p.qPosC > 0 && p.qPosC < p.scale && p.rho + p.deltaA < p.scale
    ensures CircuitWeight(p, EngineCoupling(Neg, Zero), EngineCoupling(Neg, Pos)) > 0
    ensures CircuitWeight(p, EngineCoupling(Neg, Zero), EngineCoupling(Neg, Neg)) > 0
  {
    var m := p.scale;
    var src := EngineCoupling(Neg, Zero);
    MarginalNegStayLessPos(m, p.rho, p.deltaA, p.gammaA, p.epsilon, p.qPosA, p.chi, false, AttentionalWeightX2(src));
    MarginalZeroChargedTargetPos(m, p.kappa, p.deltaC, p.gammaC, p.epsilon, p.qPosC, p.chi, AttentionalWeightY2(src));
    var mwA := MarginalWeight(m, p.rho, p.deltaA, p.gammaA, p.epsilon, p.qPosA, p.chi, false, AttentionalWeightX2(src), Neg, Neg);
    var mwCPos := MarginalWeight(m, p.kappa, p.deltaC, p.gammaC, p.epsilon, p.qPosC, p.chi, true, AttentionalWeightY2(src), Zero, Pos);
    var mwCNeg := MarginalWeight(m, p.kappa, p.deltaC, p.gammaC, p.epsilon, p.qPosC, p.chi, true, AttentionalWeightY2(src), Zero, Neg);
    PosMulPos(mwA, mwCPos);
    PosMulPos(mwA, mwCNeg);
  }

  // [19/41] veille_reaches_all_one_step
  lemma veille_reaches_all_one_step(p: CircuitKernelParams, dst: EngineCoupling)
    requires p.epsilon > 0 && p.epsilon < p.scale
    requires p.qPosA > 0 && p.qPosA < p.scale
    requires p.qPosC > 0 && p.qPosC < p.scale
    ensures CircuitWeight(p, EngineCoupling(Zero, Zero), dst) > 0
  {
    var m := p.scale;
    var src := EngineCoupling(Zero, Zero);
    MarginalFromZeroPos(m, p.rho, p.deltaA, p.gammaA, p.epsilon, p.qPosA, p.chi, AttentionalWeightX2(src), dst.attente);
    MarginalFromZeroPos(m, p.kappa, p.deltaC, p.gammaC, p.epsilon, p.qPosC, p.chi, AttentionalWeightY2(src), dst.controle);
    var mwA := MarginalWeight(m, p.rho, p.deltaA, p.gammaA, p.epsilon, p.qPosA, p.chi, false, AttentionalWeightX2(src), Zero, dst.attente);
    var mwC := MarginalWeight(m, p.kappa, p.deltaC, p.gammaC, p.epsilon, p.qPosC, p.chi, false, AttentionalWeightY2(src), Zero, dst.controle);
    PosMulPos(mwA, mwC);
  }

  // [20/41] all_reach_veille_two_steps
  lemma {:isolate_assertions} all_reach_veille_two_steps(p: CircuitKernelParams, src: EngineCoupling)
    requires p.epsilon < p.scale && p.chi < p.scale
    requires p.rho > 0 && p.kappa > 0 && p.gammaA > 0 && p.gammaC > 0
    ensures exists mid: EngineCoupling ::
      CircuitWeight(p, src, mid) > 0 &&
      CircuitWeight(p, mid, EngineCoupling(Zero, Zero)) > 0
  {
    var mid := EngineCoupling(StepDownPol(src.attente), StepDownPol(src.controle));
    var m := p.scale;
    MarginalToMidPos(m, p.rho, p.deltaA, p.gammaA, p.epsilon, p.qPosA, p.chi, IsCharged(src.controle), AttentionalWeightX2(src), src.attente);
    MarginalToMidPos(m, p.kappa, p.deltaC, p.gammaC, p.epsilon, p.qPosC, p.chi, IsCharged(src.attente), AttentionalWeightY2(src), src.controle);
    var w1A := MarginalWeight(m, p.rho, p.deltaA, p.gammaA, p.epsilon, p.qPosA, p.chi, IsCharged(src.controle), AttentionalWeightX2(src), src.attente, mid.attente);
    var w1C := MarginalWeight(m, p.kappa, p.deltaC, p.gammaC, p.epsilon, p.qPosC, p.chi, IsCharged(src.attente), AttentionalWeightY2(src), src.controle, mid.controle);
    PosMulPos(w1A, w1C);
    assert CircuitWeight(p, src, mid) == w1A * w1C > 0;

    MarginalMidToZeroPos(m, p.rho, p.deltaA, p.gammaA, p.epsilon, p.qPosA, p.chi, IsCharged(mid.controle), AttentionalWeightX2(mid), mid.attente);
    MarginalMidToZeroPos(m, p.kappa, p.deltaC, p.gammaC, p.epsilon, p.qPosC, p.chi, IsCharged(mid.attente), AttentionalWeightY2(mid), mid.controle);
    var w2A := MarginalWeight(m, p.rho, p.deltaA, p.gammaA, p.epsilon, p.qPosA, p.chi, IsCharged(mid.controle), AttentionalWeightX2(mid), mid.attente, Zero);
    var w2C := MarginalWeight(m, p.kappa, p.deltaC, p.gammaC, p.epsilon, p.qPosC, p.chi, IsCharged(mid.attente), AttentionalWeightY2(mid), mid.controle, Zero);
    PosMulPos(w2A, w2C);
    assert CircuitWeight(p, mid, EngineCoupling(Zero, Zero)) == w2A * w2C > 0;
  }

  // [21/41] veille_unreachable_when_eps_max
  lemma veille_unreachable_when_eps_max(p: CircuitKernelParams, src: EngineCoupling)
    requires p.epsilon == p.scale && p.deltaA == 0
    ensures CircuitWeight(p, src, EngineCoupling(Zero, Zero)) == 0
  {
    reveal MarginalWeight();
    assert EffectiveEpsScaled(p.scale, p.epsilon, p.chi, IsCharged(src.controle)) == p.scale * p.scale;
  }

  // =========================================================================
  // 6. Circuit continu fermé à 6 opérateurs avec états cachés
  // =========================================================================

  datatype HiddenSubjectiveState = HiddenSubjectiveState(
    modelDiscrepancy: nat,
    revisable: bool,
    descendingSuspension: bool
  )

  datatype HiddenPerceptiveState = HiddenPerceptiveState(
    afferentDiscrepancy: nat,
    controllable: bool
  )

  datatype BodyEnvironmentState = BodyEnvironmentState(perturbation: nat)

  datatype CircularCircuitStateRaw = CircularCircuitStateRaw(
    subjectiveHidden: HiddenSubjectiveState,
    perceptiveHidden: HiddenPerceptiveState,
    bodyEnv: BodyEnvironmentState,
    sensoryThreshold: nat,
    resorptionThreshold: nat,
    attentional: AttentionalInterface
  )

  type CircularCircuitState = s: CircularCircuitStateRaw |
    s.resorptionThreshold <= s.sensoryThreshold
    witness CircularCircuitStateRaw(
      HiddenSubjectiveState(0, true, false),
      HiddenPerceptiveState(0, true),
      BodyEnvironmentState(0),
      1, 1,
      DefaultAttentionalInterface()
    )

  function DefaultCircularCircuitState(): CircularCircuitState {
    CircularCircuitStateRaw(
      HiddenSubjectiveState(0, true, false),
      HiddenPerceptiveState(0, true),
      BodyEnvironmentState(0),
      1, 1,
      DefaultAttentionalInterface()
    )
  }

  function Op1SubjectiveOut(s: CircularCircuitState): Polarity {
    if s.subjectiveHidden.modelDiscrepancy < s.resorptionThreshold then Zero
    else if s.subjectiveHidden.revisable then Pos
    else Neg
  }

  function Op2PerceptiveOut(s: CircularCircuitState): Polarity {
    if s.perceptiveHidden.afferentDiscrepancy < s.resorptionThreshold then Zero
    else if s.perceptiveHidden.controllable then Pos
    else Neg
  }

  function Op3CrossingIPerceptible(s: CircularCircuitState): (ProtoSpatialNode, CoreAffectState) {
    var c := EngineCoupling(Op1SubjectiveOut(s), Op2PerceptiveOut(s));
    var proto := PhiL1(c);
    var z: nat :=
      if IsGlobalNeutrality(c) then
        if s.subjectiveHidden.descendingSuspension then s.attentional.persistenceDepth + 2 else 0
      else if !AttentionalIsEngaged(s.attentional) then
        if s.subjectiveHidden.descendingSuspension then s.attentional.persistenceDepth + 2 else 1
      else
        s.attentional.persistenceDepth + 2;
    (proto, ProjectPerceptibleState(c, z, s.attentional.precisionA, s.attentional.precisionC,
      s.subjectiveHidden.descendingSuspension))
  }

  function Op4CrossingIIRetroactive(s: CircularCircuitState): (SubjectiveReturnChannel, PerceptiveReturnChannel) {
    var c := EngineCoupling(Op1SubjectiveOut(s), Op2PerceptiveOut(s));
    (RouteToSubjective(c), RouteToPerceptive(c))
  }

  function Op5SubjectiveIn(
    s: CircularCircuitState,
    ch: SubjectiveReturnChannel,
    perceptible: CoreAffectState
  ): HiddenSubjectiveState {
    var nextDiscrepancy: nat :=
      if ch.regimeA == Discharge && s.subjectiveHidden.modelDiscrepancy > 0 then
        s.subjectiveHidden.modelDiscrepancy - 1
      else if ch.regimeA == Discharge then 0
      else s.subjectiveHidden.modelDiscrepancy;
    var nextRevisable :=
      s.subjectiveHidden.revisable ||
      (ch.regimeA == Charge && ch.contextC == Pos && perceptible.z >= 2);
    var nextSuspension :=
      if ch.regimeA == Neutral && ch.contextC == Zero then false
      else s.subjectiveHidden.descendingSuspension;
    HiddenSubjectiveState(nextDiscrepancy, nextRevisable, nextSuspension)
  }

  function Op6PerceptiveIn(
    s: CircularCircuitState,
    ch: PerceptiveReturnChannel,
    perceptible: CoreAffectState
  ): (HiddenPerceptiveState, BodyEnvironmentState) {
    var reduced: nat :=
      if ch.regimeC == Discharge && perceptible.y > 0 && s.perceptiveHidden.afferentDiscrepancy > 0 then
        s.perceptiveHidden.afferentDiscrepancy - 1
      else if ch.regimeC == Discharge && perceptible.y > 0 then 0
      else s.perceptiveHidden.afferentDiscrepancy;
    var nextAfferent := reduced + s.bodyEnv.perturbation;
    (HiddenPerceptiveState(nextAfferent, s.perceptiveHidden.controllable), s.bodyEnv)
  }

  function CircularCycle(s: CircularCircuitState): CircularCircuitState {
    var (_, perceptible) := Op3CrossingIPerceptible(s);
    var (chSubj, chPerc) := Op4CrossingIIRetroactive(s);
    var nextSubj := Op5SubjectiveIn(s, chSubj, perceptible);
    var (nextPerc, nextEnv) := Op6PerceptiveIn(s, chPerc, perceptible);
    CircularCircuitStateRaw(
      nextSubj,
      nextPerc,
      nextEnv,
      s.sensoryThreshold,
      s.resorptionThreshold,
      s.attentional
    )
  }

  // [22/41] circularCycle_veille_fixed_point
  lemma circularCycle_veille_fixed_point()
    ensures CircularCycle(DefaultCircularCircuitState()) == DefaultCircularCircuitState()
    ensures Op3CrossingIPerceptible(DefaultCircularCircuitState()).1 == CoreAffectPoint(0, 0, 0)
  {}

  // [23/41] circularCycle_reduces_total_discrepancy
  lemma circularCycle_reduces_total_discrepancy(s: CircularCircuitState)
    requires s.bodyEnv.perturbation == 0
    requires s.subjectiveHidden.revisable && s.perceptiveHidden.controllable
    requires AttentionalIsEngaged(s.attentional)
    requires s.resorptionThreshold == 1
    requires s.subjectiveHidden.modelDiscrepancy + s.perceptiveHidden.afferentDiscrepancy > 0
    ensures CircularCycle(s).subjectiveHidden.modelDiscrepancy +
            CircularCycle(s).perceptiveHidden.afferentDiscrepancy <
            s.subjectiveHidden.modelDiscrepancy + s.perceptiveHidden.afferentDiscrepancy
  {
    if s.subjectiveHidden.modelDiscrepancy > 0 {
      assert Op1SubjectiveOut(s) == Pos;
    } else {
      assert s.perceptiveHidden.afferentDiscrepancy > 0;
      assert Op1SubjectiveOut(s) == Zero && Op2PerceptiveOut(s) == Pos;
      assert Op3CrossingIPerceptible(s).1.y > 0;
    }
  }

  lemma Deg6DriftCombo(m: nat, a: nat, b: nat)
    ensures ((m * m) * (2 * a)) * (2 * m * (m * m)) * 2 +
            ((m * m) * (2 * b)) * (2 * m * (m * m)) == 4 * Pow5(m) * (b + 2 * a)
  {
    var m2 := m * m;
    assert Pow5(m) == m2 * m * m2;
    assert (m2 * (2 * a)) * (2 * m * m2) == 4 * (m2 * m * m2) * a;
    assert (m2 * (2 * b)) * (2 * m * m2) == 4 * (m2 * m * m2) * b;
  }

  // [24/41] lyapunov_drift_charge_with_passive_extinction
  lemma {:isolate_assertions} lyapunov_drift_charge_with_passive_extinction(p: CircuitKernelParams)
    requires p.epsilon == 0 && p.chi == 0
    ensures WeightedDriftSum(p, EngineCoupling(Neg, Zero)) ==
      4 * Pow5(p.scale) * (p.rho + 2 * p.deltaA)
  {
    reveal MarginalWeight();
    var src := EngineCoupling(Neg, Zero);
    WeightedDriftSumUnroll(p, src);
    var m := p.scale;
    var m2 := m * m;
    assert EffectiveEpsScaled(m, 0, 0, false) == 0 && EffectiveEpsScaled(m, 0, 0, true) == 0;
    assert WeightedDriftTerm(p, src, EngineCoupling(Zero, Zero)) == (m2 * (2 * p.deltaA)) * (2 * m * m2) * 2;
    assert WeightedDriftTerm(p, src, EngineCoupling(Pos,  Zero)) == (m2 * (2 * p.rho)) * (2 * m * m2);
    assert WeightedDriftTerm(p, src, EngineCoupling(Neg,  Zero)) == 0;
    assert WeightedDriftTerm(p, src, EngineCoupling(Zero, Pos))  == 0;
    assert WeightedDriftTerm(p, src, EngineCoupling(Zero, Neg))  == 0;
    assert WeightedDriftTerm(p, src, EngineCoupling(Pos,  Pos))  == 0;
    assert WeightedDriftTerm(p, src, EngineCoupling(Pos,  Neg))  == 0;
    assert WeightedDriftTerm(p, src, EngineCoupling(Neg,  Pos))  == 0;
    assert WeightedDriftTerm(p, src, EngineCoupling(Neg,  Neg))  == 0;
    Deg6DriftCombo(m, p.deltaA, p.rho);
  }

  // [25/41] p1_without_p2_eps_independent
  lemma p1_without_p2_eps_independent(m: nat, eps: nat, otherCharged: bool)
    requires eps <= m
    ensures EffectiveEpsScaled(m, eps, 0, otherCharged) == m * eps
  {}

  // [26/41] epistemic_rigidity_traps_charge_slice
  lemma epistemic_rigidity_traps_charge_slice(p: CircuitKernelParams, src: EngineCoupling, dst: EngineCoupling)
    requires p.rho == 0 && p.deltaA == 0 && src.attente == Neg && dst.attente != Neg
    ensures CircuitWeight(p, src, dst) == 0
  {
    reveal MarginalWeight();
  }

  // [27/41] pragmatic_helplessness_traps_charge_slice
  lemma pragmatic_helplessness_traps_charge_slice(p: CircuitKernelParams, src: EngineCoupling, dst: EngineCoupling)
    requires p.kappa == 0 && p.deltaC == 0 && src.controle == Neg && dst.controle != Neg
    ensures CircuitWeight(p, src, dst) == 0
  {
    reveal MarginalWeight();
  }

  // [28/41] perseveration_traps_discharge_free
  lemma perseveration_traps_discharge_free(p: CircuitKernelParams, src: EngineCoupling, dst: EngineCoupling)
    requires p.epsilon == 0 && p.gammaA == 0 && p.gammaC == 0
    requires src.attente != Neg && src.controle != Neg
    ensures CircuitWeight(p, src, dst) == (if dst == src then 4 * Pow6(p.scale) else 0)
  {
    reveal MarginalWeight();
    var m := p.scale;
    if dst == src {
      assert (2 * m * (m * m)) * (2 * m * (m * m)) == 4 * Pow6(m);
    }
  }

  // =========================================================================
  // 7. Loi unifiée (Axe iv) : récurrence R_t, strate Z_t (R5) et (pi_A, pi_C)
  // =========================================================================

  datatype UnifiedDynamicsParamsRaw = UnifiedDynamicsParamsRaw(
    halfScale: nat,
    lambdaNum: nat,
    etaScaled: nat,
    betaAtt: nat,
    alphaCharge: nat,
    sigmoidK: nat,
    zMax: nat,
    thetaUp: nat -> nat,
    thetaDown: nat -> nat
  )

  ghost predicate ValidUnifiedDynamicsParams(p: UnifiedDynamicsParamsRaw) {
    p.halfScale > 0 &&
    p.lambdaNum < 2 * p.halfScale &&
    p.sigmoidK > 0 &&
    p.zMax >= 2 &&
    (forall z: nat :: p.thetaDown(z) < p.thetaUp(z))
  }

  type UnifiedDynamicsParams = p: UnifiedDynamicsParamsRaw | ValidUnifiedDynamicsParams(p)
    witness UnifiedDynamicsParamsRaw(
      500, 800, 600, 2, 50, 100, 7,
      z => 600 + 200 * z,
      z => 300 + 200 * z
    )

  function DefaultUnifiedDynamicsParams(): UnifiedDynamicsParams {
    UnifiedDynamicsParamsRaw(
      500, 800, 600, 2, 50, 100, 7,
      z => 600 + 200 * z,
      z => 300 + 200 * z
    )
  }

  function ActiveResolutionCount(src: EngineCoupling, dst: EngineCoupling): nat {
    (if src.attente == Neg && dst.attente == Pos then 1 else 0) +
    (if src.controle == Neg && dst.controle == Pos then 1 else 0)
  }

  function NextChargeAccumulator(
    p: UnifiedDynamicsParams, r: nat, piAScaled: nat, piCScaled: nat,
    src: EngineCoupling, dst: EngineCoupling
  ): nat {
    var s := 2 * p.halfScale;
    var contribA := if src.attente == Neg then piAScaled else 0;
    var contribC := if src.controle == Neg then piCScaled else 0;
    var relief := p.etaScaled * ActiveResolutionCount(src, dst);
    var acc := (p.lambdaNum * r) / s + contribA + contribC;
    if acc >= relief then acc - relief else 0
  }

  function ChargeAccumulatorBound(p: UnifiedDynamicsParams): nat {
    var s := 2 * p.halfScale;
    (s * s) / (s - p.lambdaNum)
  }

  // [29/41] passive_extinction_zero_relief
  lemma passive_extinction_zero_relief()
    ensures ActiveResolutionCount(EngineCoupling(Neg, Zero), EngineCoupling(Zero, Zero)) == 0
  {}

  // [30/41] active_resolution_beats_passive_extinction
  lemma active_resolution_beats_passive_extinction(
    p: UnifiedDynamicsParams, r: nat, piAScaled: nat, piCScaled: nat
  )
    requires p.etaScaled > 0
    requires (p.lambdaNum * r) / (2 * p.halfScale) + piAScaled > 0
    ensures NextChargeAccumulator(p, r, piAScaled, piCScaled, EngineCoupling(Neg, Zero), EngineCoupling(Pos, Zero)) <
            NextChargeAccumulator(p, r, piAScaled, piCScaled, EngineCoupling(Neg, Zero), EngineCoupling(Zero, Zero))
  {}

  lemma DivLeMonotone(a: nat, b: nat, d: nat)
    requires a <= b && d > 0
    ensures a / d <= b / d
  {
    assert a / d * d <= a <= b;
    if a / d > b / d {
      assert (a / d) * d >= (b / d + 1) * d == (b / d) * d + d > b;
    }
  }

  lemma DivLtOfLtMul(a: nat, b: nat, q: nat)
    requires b > 0 && a < b * q
    ensures a / b < q
  {
    if a / b >= q {
      assert (a / b) * b >= q * b == b * q > a;
    }
  }

  lemma DivLeOfLeMul(a: nat, b: nat, q: nat)
    requires b > 0 && a <= b * q
    ensures a / b <= q
  {
    if a / b > q {
      assert (a / b) * b >= (q + 1) * b == q * b + b > a;
    }
  }

  lemma {:isolate_assertions} ChargeDecayStepBound(s: nat, l: nat, r: nat)
    requires s > 0 && l < s && r <= (s * s) / (s - l)
    ensures (l * r) / s <= (s * s) / (s - l) - s
  {
    var d := s - l;
    var rMax := (s * s) / d;
    assert s * d <= s * s;
    NatMulAddDivExact(s, d, 0);
    DivLeMonotone(s * d, s * s, d);
    assert s <= rMax;
    assert (s * s) == rMax * d + (s * s) % d;
    assert (s * s) % d < d;
    assert rMax * d == rMax * s - rMax * l;
    assert l * rMax < s * (rMax - s + 1);
    DivLtOfLtMul(l * rMax, s, rMax - s + 1);
    assert (l * rMax) / s <= rMax - s;
    assert l * r <= l * rMax;
    DivLeMonotone(l * r, l * rMax, s);
  }

  // [31/41] charge_accumulator_bounded
  lemma charge_accumulator_bounded(
    p: UnifiedDynamicsParams, r: nat, piAScaled: nat, piCScaled: nat,
    src: EngineCoupling, dst: EngineCoupling
  )
    requires piAScaled + piCScaled == 2 * p.halfScale
    requires r <= ChargeAccumulatorBound(p)
    ensures NextChargeAccumulator(p, r, piAScaled, piCScaled, src, dst) <= ChargeAccumulatorBound(p)
  {
    var s := 2 * p.halfScale;
    ChargeDecayStepBound(s, p.lambdaNum, r);
    var contribA := if src.attente == Neg then piAScaled else 0;
    var contribC := if src.controle == Neg then piCScaled else 0;
    assert contribA + contribC <= s;
  }

  function MinNat(a: nat, b: nat): nat {
    if a <= b then a else b
  }

  function NextStratumR5(p: UnifiedDynamicsParams, z: nat, rNext: nat): nat {
    if rNext > p.thetaUp(z) then MinNat(p.zMax, z + 1)
    else if rNext < p.thetaDown(z) then
      if z <= 2 then 0 else MinNat(p.zMax, z - 1)
    else MinNat(p.zMax, z)
  }

  // [32/41] nextStratumR5_le_zMax
  lemma nextStratumR5_le_zMax(p: UnifiedDynamicsParams, z: nat, rNext: nat)
    ensures NextStratumR5(p, z, rNext) <= p.zMax
  {}

  // [33/41] nextStratumR5_short_circuits_z2_to_veille
  lemma nextStratumR5_short_circuits_z2_to_veille(p: UnifiedDynamicsParams, rNext: nat)
    requires rNext < p.thetaDown(2)
    ensures NextStratumR5(p, 2, rNext) == 0
  {}

  // [34/41] nextStratumR5_from_ge2_never_visits_surprise
  lemma nextStratumR5_from_ge2_never_visits_surprise(p: UnifiedDynamicsParams, z: nat, rNext: nat)
    requires z >= 2
    ensures NextStratumR5(p, z, rNext) != 1
  {}

  function SymmetricSigmoid(halfScale: nat, k: nat, u: int): (nat, nat)
    requires k > 0
  {
    var au := AbsNat(u);
    MulDistLe(halfScale, au, k);
    DivLeOfLeMul(halfScale * au, au + k, halfScale);
    var shift := (halfScale * au) / (au + k);
    if u >= 0 then (halfScale + shift, halfScale - shift)
    else (halfScale - shift, halfScale + shift)
  }

  // [35/41] symmetricSigmoid_sum
  lemma symmetricSigmoid_sum(halfScale: nat, k: nat, u: int)
    requires k > 0
    ensures SymmetricSigmoid(halfScale, k, u).0 + SymmetricSigmoid(halfScale, k, u).1 == 2 * halfScale
  {}

  // [36/41] symmetricSigmoid_pos
  lemma symmetricSigmoid_pos(halfScale: nat, k: nat, u: int)
    requires halfScale > 0 && k > 0
    ensures SymmetricSigmoid(halfScale, k, u).0 > 0
    ensures SymmetricSigmoid(halfScale, k, u).1 > 0
  {
    var au := AbsNat(u);
    MulDistLt(halfScale, au, k);
    DivLtOfLtMul(halfScale * au, au + k, halfScale);
  }

  // [37/41] symmetricSigmoid_neg
  lemma symmetricSigmoid_neg(halfScale: nat, k: nat, u: int)
    requires k > 0
    ensures SymmetricSigmoid(halfScale, k, -u) ==
            (SymmetricSigmoid(halfScale, k, u).1, SymmetricSigmoid(halfScale, k, u).0)
  {}

  function ChargeIndicatorInt(pol: Polarity): int {
    if pol == Neg then 1 else 0
  }

  function PrecisionScore(p: UnifiedDynamicsParams, rhoHat: nat, kappaHat: nat, c: EngineCoupling): int {
    (p.betaAtt as int) *
      (((rhoHat as int) - (kappaHat as int)) +
       (p.alphaCharge as int) * (ChargeIndicatorInt(c.attente) - ChargeIndicatorInt(c.controle)))
  }

  function PrecisionShares(p: UnifiedDynamicsParams, rhoHat: nat, kappaHat: nat, c: EngineCoupling): (nat, nat) {
    SymmetricSigmoid(p.halfScale, p.sigmoidK, PrecisionScore(p, rhoHat, kappaHat, c))
  }

  function SpatialBudget(z: nat): nat {
    if z < 2 then 0 else 2 * z - 2
  }

  function ProjectUnifiedState(
    p: UnifiedDynamicsParams, c: EngineCoupling, z: nat, rhoHat: nat, kappaHat: nat, susp: bool
  ): CoreAffectState {
    var sh := PrecisionShares(p, rhoHat, kappaHat, c);
    ProjectPerceptibleState(c, z, sh.0, sh.1, susp)
  }

  // [38/41] precisionShare_double_charge_cancels_alpha
  lemma precisionShare_double_charge_cancels_alpha(p: UnifiedDynamicsParams, rhoHat: nat, kappaHat: nat)
    ensures PrecisionScore(p, rhoHat, kappaHat, EngineCoupling(Neg, Neg)) ==
            (p.betaAtt as int) * ((rhoHat as int) - (kappaHat as int))
  {}

  // [39/41] projectUnifiedState_valid
  lemma projectUnifiedState_valid(
    p: UnifiedDynamicsParams, c: EngineCoupling, z: nat, rhoHat: nat, kappaHat: nat, susp: bool
  )
    ensures IsValidCoreAffect(ProjectUnifiedState(p, c, z, rhoHat, kappaHat, susp))
  {}

  // [40/41] projectUnifiedState_crown_budget
  lemma projectUnifiedState_crown_budget(
    p: UnifiedDynamicsParams, c: EngineCoupling, z: nat, rhoHat: nat, kappaHat: nat, susp: bool
  )
    requires !IsGlobalNeutrality(c) && z >= 2
    ensures DisplacementSum(ProjectUnifiedState(p, c, z, rhoHat, kappaHat, susp)) == SpatialBudget(z)
  {
    var sh := PrecisionShares(p, rhoHat, kappaHat, c);
    deployCouplingWithPrecision_budget_conservation(c, z - 2, sh.0, sh.1);
  }

  // [41/41] projectUnifiedState_reaches_lateral_consternation
  lemma projectUnifiedState_reaches_lateral_consternation()
    ensures ProjectUnifiedState(DefaultUnifiedDynamicsParams(), EngineCoupling(Neg, Pos), 3, 10, 90, true) ==
            CoreAffectPoint(-1, 3, 3)
  {
    var p := DefaultUnifiedDynamicsParams();
    var c := EngineCoupling(Neg, Pos);
    assert PrecisionScore(p, 10, 90, c) == -60;
    assert PrecisionShares(p, 10, 90, c) == (313, 687);
    assert ApportionRay(1, 313, 687) == (1, 3);
  }

}
