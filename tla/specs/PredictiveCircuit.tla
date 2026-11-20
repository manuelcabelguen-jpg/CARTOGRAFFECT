------------------------- MODULE PredictiveCircuit --------------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Module 07 : Circuit predictif ferme, noyau markovien 4*m^6, loi unifiee (TLA+ / TLC)
*)
EXTENDS Integers, PredictiveEngine, CoreAffect

InterfaceSides == {"internal", "external"}
CircuitOperations == {
  "subjectiveOut", "perceptiveOut",
  "attentionalCrossingI", "attentionalCrossingII",
  "subjectiveIn", "perceptiveIn"
}

CircuitCarrierInterface(op) ==
  IF op \in {"subjectiveOut", "subjectiveIn"} THEN "subjective"
  ELSE IF op \in {"perceptiveOut", "perceptiveIn"} THEN "perceptive"
  ELSE "attentional"

CircuitOperationSide(op) ==
  IF op \in {"subjectiveOut", "perceptiveOut", "attentionalCrossingI"} THEN "internal"
  ELSE "external"

CircuitToInferentialOp(op) ==
  IF op \in {"subjectiveOut", "subjectiveIn"} THEN "contextualGenerative"
  ELSE IF op = "perceptiveOut" THEN "actionImplementation"
  ELSE IF op = "perceptiveIn" THEN "ascendingSensory"
  ELSE "integrativeWeighting"

MkProtoNode(px, py) == [x |-> px, y |-> py]
ProtoL1Norm(n) == IntAbs(n.x) + IntAbs(n.y)
IsValidProtoSpatial(n) == (n.x = 0 /\ n.y = 0) \/ ProtoL1Norm(n) = 2

PhiL1(c) ==
  IF c.attente = "zero" /\ c.controle = "zero" THEN MkProtoNode(0, 0)
  ELSE IF c.attente = "pos" /\ c.controle = "zero" THEN MkProtoNode(2, 0)
  ELSE IF c.attente = "neg" /\ c.controle = "zero" THEN MkProtoNode(-2, 0)
  ELSE IF c.attente = "zero" /\ c.controle = "pos" THEN MkProtoNode(0, 2)
  ELSE IF c.attente = "zero" /\ c.controle = "neg" THEN MkProtoNode(0, -2)
  ELSE IF c.attente = "pos" /\ c.controle = "pos" THEN MkProtoNode(1, 1)
  ELSE IF c.attente = "pos" /\ c.controle = "neg" THEN MkProtoNode(1, -1)
  ELSE IF c.attente = "neg" /\ c.controle = "pos" THEN MkProtoNode(-1, 1)
  ELSE MkProtoNode(-1, -1)

PhiL1Inv(n) == MkCoupling(PolarityOfInt(n.x), PolarityOfInt(n.y))

IdxAttente(p) == IF p = "zero" THEN 0 ELSE IF p = "neg" THEN 1 ELSE 2
IdxControle(p) == IF p = "pos" THEN 0 ELSE IF p = "neg" THEN 1 ELSE 2

CrossingIPos(c) == <<IdxAttente(c.attente), IdxControle(c.controle)>>
CrossingIIPos(c) == <<IdxControle(c.controle), IdxAttente(c.attente)>>

RouteToSubjective(c) == [regimeA |-> PolarityToRegime(c.attente), contextC |-> c.controle]
RouteToPerceptive(c) == [regimeC |-> PolarityToRegime(c.controle), contextA |-> c.attente]

ProjectPerceptible(c, z, piA, piC, susp) ==
  IF IsGlobalNeutrality(c) THEN
    IF susp /\ z >= 2 THEN MkPoint(0, 0, z) ELSE MkPoint(0, 0, 0)
  ELSE IF z = 0 THEN MkPoint(0, 0, 0)
  ELSE IF z = 1 THEN MkPoint(0, 0, 1)
  ELSE DeployCouplingWithPrecision(c, z - 2, piA, piC)

AttentionalWeightX2(c) == IF c.attente = "zero" THEN 2 ELSE IntAbs(PhiL1(c).x)
AttentionalWeightY2(c) == IF c.controle = "zero" THEN 2 ELSE IntAbs(PhiL1(c).y)

PolarityEnergy(p) == IF p = "zero" THEN 0 ELSE IF p = "pos" THEN 1 ELSE 2
LyapunovPotential(c) == PolarityEnergy(c.attente) + PolarityEnergy(c.controle)

IsCharged(p) == p = "neg"

Pow5(m) == m * m * m * m * m
Pow6(m) == m * m * m * m * m * m

MkKernelParams(m, r, k, dA, dC, gA, gC, eps, qA, qC, chi) ==
  [scale |-> m, rho |-> r, kappa |-> k, deltaA |-> dA, deltaC |-> dC,
   gammaA |-> gA, gammaC |-> gC, epsilon |-> eps, qPosA |-> qA, qPosC |-> qC, chi |-> chi]

ValidCircuitKernelParams(p) ==
  /\ p.scale > 0
  /\ p.rho \in 0..p.scale /\ p.kappa \in 0..p.scale
  /\ p.deltaA \in 0..p.scale /\ p.deltaC \in 0..p.scale
  /\ p.rho + p.deltaA <= p.scale /\ p.kappa + p.deltaC <= p.scale
  /\ p.gammaA \in 0..p.scale /\ p.gammaC \in 0..p.scale
  /\ p.epsilon \in 0..p.scale
  /\ p.qPosA \in 0..p.scale /\ p.qPosC \in 0..p.scale
  /\ p.chi \in 0..p.scale

\* Exact rational-equivalent scale=20 default (parameters / 5): 4 * 20^6 = 256,000,000 < 2^31 - 1
DefaultKernelParams20 == MkKernelParams(20, 16, 16, 0, 0, 14, 14, 3, 7, 7, 5)
\* Exact base-100 profile (for MarginalWeight and base-10^6 big-int product parity)
DefaultKernelParams100 == MkKernelParams(100, 80, 80, 0, 0, 70, 70, 15, 35, 35, 25)

EffectiveEpsScaled(m, eps, chi, otherCharged) ==
  IF otherCharged THEN m * eps + chi * (m - eps) ELSE m * eps

MarginalWeight(m, rate, delta, deseng, eps, qPos, chi, otherCharged, w2, src, dst) ==
  LET e2 == EffectiveEpsScaled(m, eps, chi, otherCharged) IN
  IF src = "zero" THEN
    IF dst = "zero" THEN 2 * m * (m * m - e2)
    ELSE IF dst = "neg" THEN 2 * e2 * (m - qPos)
    ELSE 2 * e2 * qPos
  ELSE IF src = "neg" THEN
    IF dst = "zero" THEN m * m * (2 * delta)
    ELSE IF dst = "neg" THEN m * m * (2 * m - w2 * rate - 2 * delta)
    ELSE m * m * (w2 * rate)
  ELSE
    IF dst = "zero" THEN (m * m - e2) * (w2 * deseng)
    ELSE IF dst = "neg" THEN 2 * m * e2
    ELSE (m * m - e2) * (2 * m - w2 * deseng)

CircuitWeight(p, src, dst) ==
  MarginalWeight(p.scale, p.rho, p.deltaA, p.gammaA, p.epsilon, p.qPosA, p.chi,
                 IsCharged(src.controle), AttentionalWeightX2(src), src.attente, dst.attente)
  *
  MarginalWeight(p.scale, p.kappa, p.deltaC, p.gammaC, p.epsilon, p.qPosC, p.chi,
                 IsCharged(src.attente), AttentionalWeightY2(src), src.controle, dst.controle)

CircuitRowSum(p, src) ==
    CircuitWeight(p, src, MkCoupling("zero", "zero"))
  + CircuitWeight(p, src, MkCoupling("pos",  "zero"))
  + CircuitWeight(p, src, MkCoupling("neg",  "zero"))
  + CircuitWeight(p, src, MkCoupling("zero", "pos"))
  + CircuitWeight(p, src, MkCoupling("zero", "neg"))
  + CircuitWeight(p, src, MkCoupling("pos",  "pos"))
  + CircuitWeight(p, src, MkCoupling("pos",  "neg"))
  + CircuitWeight(p, src, MkCoupling("neg",  "pos"))
  + CircuitWeight(p, src, MkCoupling("neg",  "neg"))

WeightedDriftSum(p, src) ==
    CircuitWeight(p, src, MkCoupling("zero", "zero")) * (LyapunovPotential(src) - LyapunovPotential(MkCoupling("zero", "zero")))
  + CircuitWeight(p, src, MkCoupling("pos",  "zero")) * (LyapunovPotential(src) - LyapunovPotential(MkCoupling("pos",  "zero")))
  + CircuitWeight(p, src, MkCoupling("neg",  "zero")) * (LyapunovPotential(src) - LyapunovPotential(MkCoupling("neg",  "zero")))
  + CircuitWeight(p, src, MkCoupling("zero", "pos"))  * (LyapunovPotential(src) - LyapunovPotential(MkCoupling("zero", "pos")))
  + CircuitWeight(p, src, MkCoupling("zero", "neg"))  * (LyapunovPotential(src) - LyapunovPotential(MkCoupling("zero", "neg")))
  + CircuitWeight(p, src, MkCoupling("pos",  "pos"))  * (LyapunovPotential(src) - LyapunovPotential(MkCoupling("pos",  "pos")))
  + CircuitWeight(p, src, MkCoupling("pos",  "neg"))  * (LyapunovPotential(src) - LyapunovPotential(MkCoupling("pos",  "neg")))
  + CircuitWeight(p, src, MkCoupling("neg",  "pos"))  * (LyapunovPotential(src) - LyapunovPotential(MkCoupling("neg",  "pos")))
  + CircuitWeight(p, src, MkCoupling("neg",  "neg"))  * (LyapunovPotential(src) - LyapunovPotential(MkCoupling("neg",  "neg")))

\* Base-10^6 split big-int arithmetic (<<hi, lo>> = hi * 10^6 + lo) for exact scale=100 Block 10 parity
BigZero == <<0, 0>>

MulBig(a, b) ==
  LET a1 == a \div 1000
      a0 == a % 1000
      b1 == b \div 1000
      b0 == b % 1000
      p0 == a0 * b0
      mid == a1 * b0 + a0 * b1
      rawLo == p0 + (mid % 1000) * 1000
  IN <<a1 * b1 + (mid \div 1000) + (rawLo \div 1000000), rawLo % 1000000>>

AddBig(u, v) ==
  LET sLo == u[2] + v[2] IN
  <<u[1] + v[1] + (sLo \div 1000000), sLo % 1000000>>

CircuitWeightBig(p, src, dst) ==
  MulBig(
    MarginalWeight(p.scale, p.rho, p.deltaA, p.gammaA, p.epsilon, p.qPosA, p.chi,
                   IsCharged(src.controle), AttentionalWeightX2(src), src.attente, dst.attente),
    MarginalWeight(p.scale, p.kappa, p.deltaC, p.gammaC, p.epsilon, p.qPosC, p.chi,
                   IsCharged(src.attente), AttentionalWeightY2(src), src.controle, dst.controle)
  )

CircuitRowSumBig(p, src) ==
  AddBig(AddBig(AddBig(CircuitWeightBig(p, src, MkCoupling("zero", "zero")),
                       CircuitWeightBig(p, src, MkCoupling("pos",  "zero"))),
                AddBig(CircuitWeightBig(p, src, MkCoupling("neg",  "zero")),
                       CircuitWeightBig(p, src, MkCoupling("zero", "pos")))),
         AddBig(AddBig(CircuitWeightBig(p, src, MkCoupling("zero", "neg")),
                       CircuitWeightBig(p, src, MkCoupling("pos",  "pos"))),
                AddBig(CircuitWeightBig(p, src, MkCoupling("pos",  "neg")),
                       AddBig(CircuitWeightBig(p, src, MkCoupling("neg",  "pos")),
                              CircuitWeightBig(p, src, MkCoupling("neg",  "neg"))))))

\* Closed 6-operator circular circuit
MkCircularState(mDisc, rev, susp, aDisc, ctrl, pert, sThr, rThr, att) ==
  [
    subjectiveHidden |-> [modelDiscrepancy |-> mDisc, revisable |-> rev, descendingSuspension |-> susp],
    perceptiveHidden |-> [afferentDiscrepancy |-> aDisc, controllable |-> ctrl],
    bodyEnv |-> [perturbation |-> pert],
    sensoryThreshold |-> sThr,
    resorptionThreshold |-> rThr,
    attentional |-> att
  ]

ValidCircularState(s) ==
  /\ s.subjectiveHidden.modelDiscrepancy >= 0
  /\ s.perceptiveHidden.afferentDiscrepancy >= 0
  /\ s.bodyEnv.perturbation >= 0
  /\ s.sensoryThreshold >= 0
  /\ s.resorptionThreshold >= 0
  /\ s.resorptionThreshold <= s.sensoryThreshold
  /\ ValidAttentional(s.attentional)

DefaultCircularCircuitState ==
  MkCircularState(0, TRUE, FALSE, 0, TRUE, 0, 1, 1, MkAttentional(0, 0, 0, 1, 1))

Op1SubjectiveOut(s) ==
  IF s.subjectiveHidden.modelDiscrepancy < s.resorptionThreshold THEN "zero"
  ELSE IF s.subjectiveHidden.revisable THEN "pos" ELSE "neg"

Op2PerceptiveOut(s) ==
  IF s.perceptiveHidden.afferentDiscrepancy < s.resorptionThreshold THEN "zero"
  ELSE IF s.perceptiveHidden.controllable THEN "pos" ELSE "neg"

Op3CrossingIPoint(s) ==
  LET c == MkCoupling(Op1SubjectiveOut(s), Op2PerceptiveOut(s))
      att == s.attentional
      susp == s.subjectiveHidden.descendingSuspension
      z == IF IsGlobalNeutrality(c) THEN IF susp THEN att.persistenceDepth + 2 ELSE 0
           ELSE IF ~AttentionalIsEngaged(att) THEN IF susp THEN att.persistenceDepth + 2 ELSE 1
           ELSE att.persistenceDepth + 2
  IN ProjectPerceptible(c, z, att.precisionA, att.precisionC, susp)

Op5SubjectiveIn(s, ch, pt) ==
  LET sh == s.subjectiveHidden IN
  [
    modelDiscrepancy |->
      IF ch.regimeA = "discharge" THEN
        IF sh.modelDiscrepancy > 0 THEN sh.modelDiscrepancy - 1 ELSE 0
      ELSE sh.modelDiscrepancy,
    revisable |-> sh.revisable \/ (ch.regimeA = "charge" /\ ch.contextC = "pos" /\ pt.z >= 2),
    descendingSuspension |->
      IF ch.regimeA = "neutral" /\ ch.contextC = "zero" THEN FALSE ELSE sh.descendingSuspension
  ]

Op6PerceptiveIn(s, ch, pt) ==
  LET ph == s.perceptiveHidden
      reduced == IF ch.regimeC = "discharge" /\ pt.y > 0 THEN
                   IF ph.afferentDiscrepancy > 0 THEN ph.afferentDiscrepancy - 1 ELSE 0
                 ELSE ph.afferentDiscrepancy
  IN [afferentDiscrepancy |-> reduced + s.bodyEnv.perturbation, controllable |-> ph.controllable]

CircularCycle(s) ==
  LET c == MkCoupling(Op1SubjectiveOut(s), Op2PerceptiveOut(s))
      pt == Op3CrossingIPoint(s)
  IN MkCircularState(
       Op5SubjectiveIn(s, RouteToSubjective(c), pt).modelDiscrepancy,
       Op5SubjectiveIn(s, RouteToSubjective(c), pt).revisable,
       Op5SubjectiveIn(s, RouteToSubjective(c), pt).descendingSuspension,
       Op6PerceptiveIn(s, RouteToPerceptive(c), pt).afferentDiscrepancy,
       Op6PerceptiveIn(s, RouteToPerceptive(c), pt).controllable,
       s.bodyEnv.perturbation,
       s.sensoryThreshold,
       s.resorptionThreshold,
       s.attentional
     )

\* Unified dynamics (R_t, Z_t, pi_A, pi_C)
DefaultUnifiedDynamicsParams ==
  [halfScale |-> 500, lambdaNum |-> 800, etaScaled |-> 600,
   betaAtt |-> 2, alphaCharge |-> 50, sigmoidK |-> 100, zMax |-> 7]

CanonicalThetaUp(z) == 600 + 200 * z
CanonicalThetaDown(z) == 300 + 200 * z

ActiveResolutionCount(src, dst) ==
  (IF src.attente = "neg" /\ dst.attente = "pos" THEN 1 ELSE 0)
  + (IF src.controle = "neg" /\ dst.controle = "pos" THEN 1 ELSE 0)

NextChargeAccumulator(p, r, piA, piC, src, dst) ==
  LET s == 2 * p.halfScale
      contribA == IF src.attente = "neg" THEN piA ELSE 0
      contribC == IF src.controle = "neg" THEN piC ELSE 0
      relief == p.etaScaled * ActiveResolutionCount(src, dst)
      raw == ((p.lambdaNum * r) \div s) + contribA + contribC - relief
  IN IF raw >= 0 THEN raw ELSE 0

ChargeAccumulatorBound(p) ==
  LET s == 2 * p.halfScale IN (s * s) \div (s - p.lambdaNum)

MinInt(a, b) == IF a <= b THEN a ELSE b

NextStratumR5(p, z, rNext) ==
  IF rNext > CanonicalThetaUp(z) THEN MinInt(p.zMax, z + 1)
  ELSE IF rNext < CanonicalThetaDown(z) THEN
    IF z <= 2 THEN 0 ELSE MinInt(p.zMax, z - 1)
  ELSE MinInt(p.zMax, z)

SymmetricSigmoid(halfScale, k, u) ==
  LET au == IntAbs(u)
      shift == (halfScale * au) \div (au + k)
  IN IF u >= 0 THEN <<halfScale + shift, halfScale - shift>>
     ELSE <<halfScale - shift, halfScale + shift>>

ChargeIndicatorInt(pol) == IF pol = "neg" THEN 1 ELSE 0

PrecisionScore(p, rhoHat, kappaHat, c) ==
  p.betaAtt * ((rhoHat - kappaHat)
    + p.alphaCharge * (ChargeIndicatorInt(c.attente) - ChargeIndicatorInt(c.controle)))

PrecisionShares(p, rhoHat, kappaHat, c) ==
  SymmetricSigmoid(p.halfScale, p.sigmoidK, PrecisionScore(p, rhoHat, kappaHat, c))

SpatialBudget(z) == IF z < 2 THEN 0 ELSE 2 * z - 2

ProjectUnifiedState(p, c, z, rhoHat, kappaHat, susp) ==
  LET sh == PrecisionShares(p, rhoHat, kappaHat, c) IN
  ProjectPerceptible(c, z, sh[1], sh[2], susp)

-----------------------------------------------------------------------------
(* 41 audited theorem predicates for PredictiveCircuit *)
-----------------------------------------------------------------------------

Thm_circuit_covers_interfaces_both_sides ==
  \A iface \in EngineInterfaces, s \in InterfaceSides :
    \E op \in CircuitOperations :
      /\ CircuitCarrierInterface(op) = iface
      /\ CircuitOperationSide(op) = s
      /\ \A op2 \in CircuitOperations :
           (CircuitCarrierInterface(op2) = iface /\ CircuitOperationSide(op2) = s) => op2 = op

Thm_circuit_refines_inferential_ops ==
  \A iop \in InferentialOperations :
    \E op \in CircuitOperations : CircuitToInferentialOp(op) = iop

Thm_phiL1_left_inv ==
  \A c \in Couplings : PhiL1Inv(PhiL1(c)) = c

Thm_phiL1_right_inv(NodeSet) ==
  \A n \in NodeSet : IsValidProtoSpatial(n) => PhiL1(PhiL1Inv(n)) = n

Thm_phiL1_agrees_with_deployZ2 ==
  \A c \in Couplings :
    /\ PhiL1(c).x = DeployCouplingAtDepth(c, 0).x
    /\ PhiL1(c).y = DeployCouplingAtDepth(c, 0).y

Thm_crossingII_is_transpose_of_crossingI ==
  \A c \in Couplings :
    CrossingIIPos(c) = <<CrossingIPos(c)[2], CrossingIPos(c)[1]>>

Thm_routeToSubjective_injective ==
  \A c1 \in Couplings, c2 \in Couplings :
    RouteToSubjective(c1) = RouteToSubjective(c2) => c1 = c2

Thm_routeToPerceptive_injective ==
  \A c1 \in Couplings, c2 \in Couplings :
    RouteToPerceptive(c1) = RouteToPerceptive(c2) => c1 = c2

Thm_projectPerceptible_valid(DepthRange, PrecSet) ==
  \A c \in Couplings, z \in DepthRange, piA \in PrecSet, piC \in PrecSet, susp \in BOOLEAN :
    IsValidCoreAffect(ProjectPerceptible(c, z, piA, piC, susp))

Thm_projectPerceptible_z2_matches_phiL1(PrecSet) ==
  \A c \in Couplings, piA \in PrecSet, piC \in PrecSet, susp \in BOOLEAN :
    ~IsGlobalNeutrality(c) =>
      ProjectPerceptible(c, 2, piA, piC, susp) = MkPoint(PhiL1(c).x, PhiL1(c).y, 2)

Thm_projectPerceptible_neutral_elevates_to_central(DepthGe2, PrecSet) ==
  \A z \in DepthGe2, piA \in PrecSet, piC \in PrecSet :
    ProjectPerceptible(MkCoupling("zero", "zero"), z, piA, piC, TRUE) = MkPoint(0, 0, z)

Thm_attentional_bottleneck_sum_active ==
  \A c \in Couplings :
    ~IsGlobalNeutrality(c) =>
      (IF PolarityIsEngaged(c.attente) THEN AttentionalWeightX2(c) ELSE 0)
      + (IF PolarityIsEngaged(c.controle) THEN AttentionalWeightY2(c) ELSE 0) = 2

Thm_circuitRowSum_exact(KernelSet) ==
  \A p \in KernelSet, src \in Couplings :
    CircuitRowSum(p, src) = 4 * Pow6(p.scale)

Thm_veille_absorbing_free(KernelSet) ==
  \A p \in KernelSet, dst \in Couplings :
    p.epsilon = 0 =>
      CircuitWeight(p, MkCoupling("zero", "zero"), dst) =
        IF dst = MkCoupling("zero", "zero") THEN 4 * Pow6(p.scale) ELSE 0

Thm_lyapunov_monotone_free(KernelSet) ==
  \A p \in KernelSet, src \in Couplings, dst \in Couplings :
    (p.epsilon = 0 /\ p.chi = 0 /\ CircuitWeight(p, src, dst) > 0) =>
      LyapunovPotential(dst) <= LyapunovPotential(src)

Thm_lyapunov_strict_descent_witness(KernelSet) ==
  \A p \in KernelSet, src \in Couplings :
    (p.epsilon = 0 /\ p.chi = 0 /\ p.rho > 0 /\ p.kappa > 0 /\ p.gammaA > 0 /\ p.gammaC > 0
     /\ ~IsGlobalNeutrality(src)) =>
      \E dst \in Couplings :
        CircuitWeight(p, src, dst) > 0 /\ LyapunovPotential(dst) < LyapunovPotential(src)

Thm_lyapunov_expected_drift_constant(KernelSet) ==
  \A p \in KernelSet :
    \A r \in 0..p.scale, src \in Couplings :
      (p.epsilon = 0 /\ p.chi = 0 /\ p.deltaA = 0 /\ p.deltaC = 0
       /\ p.rho = r /\ p.kappa = r /\ p.gammaA = r /\ p.gammaC = r
       /\ ~IsGlobalNeutrality(src)) =>
        WeightedDriftSum(p, src) = 4 * Pow5(p.scale) * r

Thm_axial_peur_bifurcates_p2(KernelSet) ==
  \A p \in KernelSet :
    (p.chi > 0 /\ p.qPosC > 0 /\ p.qPosC < p.scale /\ p.rho + p.deltaA < p.scale) =>
      /\ CircuitWeight(p, MkCoupling("neg", "zero"), MkCoupling("neg", "pos")) > 0
      /\ CircuitWeight(p, MkCoupling("neg", "zero"), MkCoupling("neg", "neg")) > 0

Thm_veille_reaches_all_one_step(KernelSet) ==
  \A p \in KernelSet, dst \in Couplings :
    (p.epsilon > 0 /\ p.epsilon < p.scale
     /\ p.qPosA > 0 /\ p.qPosA < p.scale
     /\ p.qPosC > 0 /\ p.qPosC < p.scale) =>
      CircuitWeight(p, MkCoupling("zero", "zero"), dst) > 0

Thm_all_reach_veille_two_steps(KernelSet) ==
  \A p \in KernelSet, src \in Couplings :
    (p.epsilon < p.scale /\ p.chi < p.scale
     /\ p.rho > 0 /\ p.kappa > 0 /\ p.gammaA > 0 /\ p.gammaC > 0) =>
      \E mid \in Couplings :
        CircuitWeight(p, src, mid) > 0 /\ CircuitWeight(p, mid, MkCoupling("zero", "zero")) > 0

Thm_veille_unreachable_when_eps_max(KernelSet) ==
  \A p \in KernelSet, src \in Couplings :
    (p.epsilon = p.scale /\ p.deltaA = 0) =>
      CircuitWeight(p, src, MkCoupling("zero", "zero")) = 0

Thm_circularCycle_veille_fixed_point ==
  /\ CircularCycle(DefaultCircularCircuitState) = DefaultCircularCircuitState
  /\ Op3CrossingIPoint(DefaultCircularCircuitState) = MkPoint(0, 0, 0)

Thm_circularCycle_reduces_total_discrepancy(CircStateSet) ==
  \A s \in CircStateSet :
    (s.bodyEnv.perturbation = 0
     /\ s.subjectiveHidden.revisable
     /\ s.perceptiveHidden.controllable
     /\ AttentionalIsEngaged(s.attentional)
     /\ s.resorptionThreshold = 1
     /\ (s.subjectiveHidden.modelDiscrepancy + s.perceptiveHidden.afferentDiscrepancy) > 0) =>
      LET s1 == CircularCycle(s) IN
      (s1.subjectiveHidden.modelDiscrepancy + s1.perceptiveHidden.afferentDiscrepancy)
        < (s.subjectiveHidden.modelDiscrepancy + s.perceptiveHidden.afferentDiscrepancy)

Thm_lyapunov_drift_charge_with_passive_extinction(KernelSet) ==
  \A p \in KernelSet :
    (p.epsilon = 0 /\ p.chi = 0) =>
      WeightedDriftSum(p, MkCoupling("neg", "zero")) =
        4 * Pow5(p.scale) * (p.rho + 2 * p.deltaA)

Thm_p1_without_p2_eps_independent(Range) ==
  \A m \in Range, eps \in Range, oc \in BOOLEAN :
    EffectiveEpsScaled(m, eps, 0, oc) = m * eps

Thm_epistemic_rigidity_traps_charge_slice(KernelSet) ==
  \A p \in KernelSet, src \in Couplings, dst \in Couplings :
    (p.rho = 0 /\ p.deltaA = 0 /\ src.attente = "neg" /\ dst.attente # "neg") =>
      CircuitWeight(p, src, dst) = 0

Thm_pragmatic_helplessness_traps_charge_slice(KernelSet) ==
  \A p \in KernelSet, src \in Couplings, dst \in Couplings :
    (p.kappa = 0 /\ p.deltaC = 0 /\ src.controle = "neg" /\ dst.controle # "neg") =>
      CircuitWeight(p, src, dst) = 0

Thm_perseveration_traps_discharge_free(KernelSet) ==
  \A p \in KernelSet, src \in Couplings, dst \in Couplings :
    (p.epsilon = 0 /\ p.gammaA = 0 /\ p.gammaC = 0 /\ src.attente # "neg" /\ src.controle # "neg") =>
      CircuitWeight(p, src, dst) = IF dst = src THEN 4 * Pow6(p.scale) ELSE 0

Thm_passive_extinction_zero_relief ==
  ActiveResolutionCount(MkCoupling("neg", "zero"), MkCoupling("zero", "zero")) = 0

Thm_active_resolution_beats_passive_extinction(UnifiedSet, RSet, ShareSet) ==
  \A p \in UnifiedSet, r \in RSet, piA \in ShareSet, piC \in ShareSet :
    (p.etaScaled > 0 /\ (((p.lambdaNum * r) \div (2 * p.halfScale)) + piA > 0)) =>
      NextChargeAccumulator(p, r, piA, piC, MkCoupling("neg", "zero"), MkCoupling("pos", "zero"))
      < NextChargeAccumulator(p, r, piA, piC, MkCoupling("neg", "zero"), MkCoupling("zero", "zero"))

Thm_charge_accumulator_bounded(UnifiedSet) ==
  \A p \in UnifiedSet :
    LET s == 2 * p.halfScale
        b == ChargeAccumulatorBound(p)
    IN \A r \in 0..b, piA \in 0..s, src \in Couplings, dst \in Couplings :
         NextChargeAccumulator(p, r, piA, s - piA, src, dst) <= b

Thm_nextStratumR5_le_zMax(UnifiedSet, ZSet, RSet) ==
  \A p \in UnifiedSet, z \in ZSet, rNext \in RSet :
    NextStratumR5(p, z, rNext) <= p.zMax

Thm_nextStratumR5_short_circuits_z2_to_veille(UnifiedSet, RSet) ==
  \A p \in UnifiedSet, rNext \in RSet :
    (rNext < CanonicalThetaDown(2)) => NextStratumR5(p, 2, rNext) = 0

Thm_nextStratumR5_from_ge2_never_visits_surprise(UnifiedSet, ZGe2, RSet) ==
  \A p \in UnifiedSet, z \in ZGe2, rNext \in RSet :
    NextStratumR5(p, z, rNext) # 1

Thm_symmetricSigmoid_sum(HalfSet, KSet, USet) ==
  \A hs \in HalfSet, k \in KSet, u \in USet :
    LET s == SymmetricSigmoid(hs, k, u) IN s[1] + s[2] = 2 * hs

Thm_symmetricSigmoid_pos(HalfPosSet, KSet, USet) ==
  \A hs \in HalfPosSet, k \in KSet, u \in USet :
    LET s == SymmetricSigmoid(hs, k, u) IN s[1] > 0 /\ s[2] > 0

Thm_symmetricSigmoid_neg(HalfSet, KSet, USet) ==
  \A hs \in HalfSet, k \in KSet, u \in USet :
    LET sp == SymmetricSigmoid(hs, k, u) IN
    SymmetricSigmoid(hs, k, -u) = <<sp[2], sp[1]>>

Thm_precisionShare_double_charge_cancels_alpha(UnifiedSet, HatSet) ==
  \A p \in UnifiedSet, rH \in HatSet, kH \in HatSet :
    PrecisionScore(p, rH, kH, MkCoupling("neg", "neg")) = p.betaAtt * (rH - kH)

Thm_projectUnifiedState_valid(UnifiedSet, ZSet, HatSet) ==
  \A p \in UnifiedSet, c \in Couplings, z \in ZSet, rH \in HatSet, kH \in HatSet, susp \in BOOLEAN :
    IsValidCoreAffect(ProjectUnifiedState(p, c, z, rH, kH, susp))

Thm_projectUnifiedState_crown_budget(UnifiedSet, ZGe2, HatSet) ==
  \A p \in UnifiedSet, c \in Couplings, z \in ZGe2, rH \in HatSet, kH \in HatSet, susp \in BOOLEAN :
    ~IsGlobalNeutrality(c) =>
      DisplacementSum(ProjectUnifiedState(p, c, z, rH, kH, susp)) = SpatialBudget(z)

Thm_projectUnifiedState_reaches_lateral_consternation ==
  ProjectUnifiedState(DefaultUnifiedDynamicsParams, MkCoupling("neg", "pos"), 3, 10, 90, TRUE)
    = MkPoint(-1, 3, 3)

=============================================================================
