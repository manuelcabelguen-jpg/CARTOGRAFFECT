{-# OPTIONS --safe --without-K #-}
------------------------------------------------------------------------
-- Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
-- SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
-- Cartograffect.PredictiveCircuit: Closed predictive circuit, proto-spatial
-- bijection phiL1, 4*m^6 Markov kernel, Lyapunov drift, and unified R1-R5 law
------------------------------------------------------------------------
module Cartograffect.PredictiveCircuit where

open import Cartograffect.Prelude
open import Cartograffect.PredictiveEngine
open import Cartograffect.CoreAffect
open import Cartograffect.AffectiveMatrix
open import Cartograffect.AffectiveTaxonomy
open import Cartograffect.AffectiveDynamics
open import Cartograffect.Lexicon176

------------------------------------------------------------------------
-- 1. Circuit Topology & 6 Interface Operations
------------------------------------------------------------------------

data InterfaceSide : Set where
  sideInternal : InterfaceSide
  sideExternal : InterfaceSide

data CircuitOperation : Set where
  subjectiveOut        : CircuitOperation
  perceptiveOut        : CircuitOperation
  attentionalCrossingI : CircuitOperation
  attentionalCrossingII : CircuitOperation
  subjectiveIn         : CircuitOperation
  perceptiveIn         : CircuitOperation

circuitCarrierInterface : CircuitOperation → EngineInterface
circuitCarrierInterface subjectiveOut         = ifSubjective
circuitCarrierInterface subjectiveIn          = ifSubjective
circuitCarrierInterface perceptiveOut         = ifPerceptive
circuitCarrierInterface perceptiveIn          = ifPerceptive
circuitCarrierInterface attentionalCrossingI  = ifAttentional
circuitCarrierInterface attentionalCrossingII = ifAttentional

circuitOperationSide : CircuitOperation → InterfaceSide
circuitOperationSide subjectiveOut         = sideInternal
circuitOperationSide perceptiveOut         = sideInternal
circuitOperationSide attentionalCrossingI  = sideInternal
circuitOperationSide attentionalCrossingII = sideExternal
circuitOperationSide subjectiveIn          = sideExternal
circuitOperationSide perceptiveIn          = sideExternal

circuitToInferentialOp : CircuitOperation → InferentialOperation
circuitToInferentialOp subjectiveOut         = contextualGenerative
circuitToInferentialOp subjectiveIn          = contextualGenerative
circuitToInferentialOp perceptiveOut         = actionImplementation
circuitToInferentialOp perceptiveIn          = ascendingSensory
circuitToInferentialOp attentionalCrossingI  = integrativeWeighting
circuitToInferentialOp attentionalCrossingII = integrativeWeighting

------------------------------------------------------------------------
-- 2. Proto-Spatial L1 Bijection phiL1 & Chiasmatic Crossings I / II
------------------------------------------------------------------------

record ProtoSpatialNode : Set where
  constructor mkProtoNode
  field
    nx : Int
    ny : Int
open ProtoSpatialNode public

protoL1Norm : ProtoSpatialNode → Nat
protoL1Norm n = absNat (nx n) + absNat (ny n)

isValidProtoSpatialB : ProtoSpatialNode → Bool
isValidProtoSpatialB n =
  (isZeroℤ (nx n) ∧b isZeroℤ (ny n)) ∨b (protoL1Norm n == 2)

phiL1 : EngineCoupling → ProtoSpatialNode
phiL1 (mkEngineCoupling zero zero) = mkProtoNode (pos 0)    (pos 0)
phiL1 (mkEngineCoupling pos  zero) = mkProtoNode (pos 2)    (pos 0)
phiL1 (mkEngineCoupling neg  zero) = mkProtoNode (negsuc 1) (pos 0)
phiL1 (mkEngineCoupling zero pos)  = mkProtoNode (pos 0)    (pos 2)
phiL1 (mkEngineCoupling zero neg)  = mkProtoNode (pos 0)    (negsuc 1)
phiL1 (mkEngineCoupling pos  pos)  = mkProtoNode (pos 1)    (pos 1)
phiL1 (mkEngineCoupling pos  neg)  = mkProtoNode (pos 1)    (negsuc 0)
phiL1 (mkEngineCoupling neg  pos)  = mkProtoNode (negsuc 0) (pos 1)
phiL1 (mkEngineCoupling neg  neg)  = mkProtoNode (negsuc 0) (negsuc 0)

phiL1Inv : ProtoSpatialNode → EngineCoupling
phiL1Inv n = mkEngineCoupling (polarityOfInt (nx n)) (polarityOfInt (ny n))

idxAttente : Polarity → Nat
idxAttente zero = 0
idxAttente neg  = 1
idxAttente pos  = 2

idxControle : Polarity → Nat
idxControle pos  = 0
idxControle neg  = 1
idxControle zero = 2

crossingIPos : EngineCoupling → Nat × Nat
crossingIPos c = idxAttente (attente c) , idxControle (controle c)

crossingIIPos : EngineCoupling → Nat × Nat
crossingIIPos c = idxControle (controle c) , idxAttente (attente c)

record SubjectiveChannel : Set where
  constructor mkSubjectiveChannel
  field
    regimeA  : FunctionalRegime
    contextC : Polarity
open SubjectiveChannel public

record PerceptiveChannel : Set where
  constructor mkPerceptiveChannel
  field
    regimeC  : FunctionalRegime
    contextA : Polarity
open PerceptiveChannel public

routeToSubjective : EngineCoupling → SubjectiveChannel
routeToSubjective c = mkSubjectiveChannel (Polarity-toRegime (attente c)) (controle c)

routeToPerceptive : EngineCoupling → PerceptiveChannel
routeToPerceptive c = mkPerceptiveChannel (Polarity-toRegime (controle c)) (attente c)

projectPerceptible : EngineCoupling → Nat → Nat → Nat → Bool → CoreAffectPoint
projectPerceptible c z piA piC susp =
  if isGlobalNeutralityB c then
    (if susp ∧b ge2ℕ z then mkPoint (pos 0) (pos 0) z else mkPoint (pos 0) (pos 0) 0)
  else if z == 0 then mkPoint (pos 0) (pos 0) 0
  else if z == 1 then mkPoint (pos 0) (pos 0) 1
  else deployCouplingWithPrecision c (z - 2) piA piC

attentionalWeightX2 : EngineCoupling → Nat
attentionalWeightX2 c with attente c
... | zero = 2
... | _    = absNat (nx (phiL1 c))

attentionalWeightY2 : EngineCoupling → Nat
attentionalWeightY2 c with controle c
... | zero = 2
... | _    = absNat (ny (phiL1 c))

polarityEnergy : Polarity → Nat
polarityEnergy zero = 0
polarityEnergy pos  = 1
polarityEnergy neg  = 2

lyapunovPotential : EngineCoupling → Nat
lyapunovPotential c = polarityEnergy (attente c) + polarityEnergy (controle c)

isChargedB : Polarity → Bool
isChargedB neg = true
isChargedB _   = false

------------------------------------------------------------------------
-- 3. 9x9 Markov Kernel (4 * m^6 exact integer weights)
------------------------------------------------------------------------

pow5 : Nat → Nat
pow5 m = m * m * m * m * m

pow6 : Nat → Nat
pow6 m = m * m * m * m * m * m

record CircuitKernelParams : Set where
  constructor mkKernelParams
  field
    scale   : Nat
    rho     : Nat
    kappa   : Nat
    deltaA  : Nat
    deltaC  : Nat
    gammaA  : Nat
    gammaC  : Nat
    epsilon : Nat
    qPosA   : Nat
    qPosC   : Nat
    chi     : Nat
open CircuitKernelParams public

defaultCircuitKernelParams : CircuitKernelParams
defaultCircuitKernelParams = mkKernelParams 100 80 80 0 0 70 70 15 35 35 25

freeCircuitKernelParams : CircuitKernelParams
freeCircuitKernelParams = mkKernelParams 100 80 80 0 0 70 70 0 35 35 0

uniformFreeKernelParams : Nat → Nat → CircuitKernelParams
uniformFreeKernelParams m r = mkKernelParams m r r 0 0 r r 0 0 0 0

effectiveEpsScaled : Nat → Nat → Nat → Bool → Nat
effectiveEpsScaled m eps chi true  = m * eps + chi * (m - eps)
effectiveEpsScaled m eps _   false = m * eps

marginalWeight : Nat → Nat → Nat → Nat → Nat → Nat → Nat → Bool → Nat → Polarity → Polarity → Nat
marginalWeight m rate delta deseng eps qPos chi otherCharged w2 src dst =
  let e2 = effectiveEpsScaled m eps chi otherCharged in
  caseSrc src dst e2
  where
    caseSrc : Polarity → Polarity → Nat → Nat
    caseSrc zero zero e2 = 2 * m * (m * m - e2)
    caseSrc zero neg  e2 = 2 * e2 * (m - qPos)
    caseSrc zero pos  e2 = 2 * e2 * qPos
    caseSrc neg  zero _  = m * m * (2 * delta)
    caseSrc neg  neg  _  = m * m * (2 * m - w2 * rate - 2 * delta)
    caseSrc neg  pos  _  = m * m * (w2 * rate)
    caseSrc pos  zero e2 = (m * m - e2) * (w2 * deseng)
    caseSrc pos  neg  e2 = 2 * m * e2
    caseSrc pos  pos  e2 = (m * m - e2) * (2 * m - w2 * deseng)

circuitWeight : CircuitKernelParams → EngineCoupling → EngineCoupling → Nat
circuitWeight p src dst =
  marginalWeight (scale p) (rho p) (deltaA p) (gammaA p) (epsilon p) (qPosA p) (chi p)
                 (isChargedB (controle src)) (attentionalWeightX2 src) (attente src) (attente dst)
  *
  marginalWeight (scale p) (kappa p) (deltaC p) (gammaC p) (epsilon p) (qPosC p) (chi p)
                 (isChargedB (attente src)) (attentionalWeightY2 src) (controle src) (controle dst)

circuitRowSum : CircuitKernelParams → EngineCoupling → Nat
circuitRowSum p src =
    circuitWeight p src (mkEngineCoupling zero zero)
  + circuitWeight p src (mkEngineCoupling pos  zero)
  + circuitWeight p src (mkEngineCoupling neg  zero)
  + circuitWeight p src (mkEngineCoupling zero pos)
  + circuitWeight p src (mkEngineCoupling zero neg)
  + circuitWeight p src (mkEngineCoupling pos  pos)
  + circuitWeight p src (mkEngineCoupling pos  neg)
  + circuitWeight p src (mkEngineCoupling neg  pos)
  + circuitWeight p src (mkEngineCoupling neg  neg)

weightedDriftSum : CircuitKernelParams → EngineCoupling → Nat
weightedDriftSum p src =
    circuitWeight p src (mkEngineCoupling zero zero) * (lyapunovPotential src - lyapunovPotential (mkEngineCoupling zero zero))
  + circuitWeight p src (mkEngineCoupling pos  zero) * (lyapunovPotential src - lyapunovPotential (mkEngineCoupling pos  zero))
  + circuitWeight p src (mkEngineCoupling neg  zero) * (lyapunovPotential src - lyapunovPotential (mkEngineCoupling neg  zero))
  + circuitWeight p src (mkEngineCoupling zero pos)  * (lyapunovPotential src - lyapunovPotential (mkEngineCoupling zero pos))
  + circuitWeight p src (mkEngineCoupling zero neg)  * (lyapunovPotential src - lyapunovPotential (mkEngineCoupling zero neg))
  + circuitWeight p src (mkEngineCoupling pos  pos)  * (lyapunovPotential src - lyapunovPotential (mkEngineCoupling pos  pos))
  + circuitWeight p src (mkEngineCoupling pos  neg)  * (lyapunovPotential src - lyapunovPotential (mkEngineCoupling pos  neg))
  + circuitWeight p src (mkEngineCoupling neg  pos)  * (lyapunovPotential src - lyapunovPotential (mkEngineCoupling neg  pos))
  + circuitWeight p src (mkEngineCoupling neg  neg)  * (lyapunovPotential src - lyapunovPotential (mkEngineCoupling neg  neg))

------------------------------------------------------------------------
-- 4. Closed 6-Operator Circular Circuit
------------------------------------------------------------------------

record SubjectiveHiddenState : Set where
  constructor mkSubjectiveHidden
  field
    modelDiscrepancy     : Nat
    revisable            : Bool
    descendingSuspension : Bool
open SubjectiveHiddenState public

record PerceptiveHiddenState : Set where
  constructor mkPerceptiveHidden
  field
    afferentDiscrepancy : Nat
    controllable        : Bool
open PerceptiveHiddenState public

record BodyEnvState : Set where
  constructor mkBodyEnv
  field
    perturbation : Nat
open BodyEnvState public

record CircularCircuitState : Set where
  constructor mkCircularState
  field
    subjectiveHidden    : SubjectiveHiddenState
    perceptiveHidden    : PerceptiveHiddenState
    bodyEnv             : BodyEnvState
    sensoryThreshold    : Nat
    resorptionThreshold : Nat
    attentional         : AttentionalInterface
open CircularCircuitState public

defaultCircularCircuitState : CircularCircuitState
defaultCircularCircuitState =
  mkCircularState
    (mkSubjectiveHidden 0 true false)
    (mkPerceptiveHidden 0 true)
    (mkBodyEnv 0)
    1 1
    (mkAttentionalInterface 0 0 0 1 1)

op1_subjectiveOut : CircularCircuitState → Polarity
op1_subjectiveOut s =
  if modelDiscrepancy (subjectiveHidden s) < resorptionThreshold s then zero
  else if revisable (subjectiveHidden s) then pos else neg

op2_perceptiveOut : CircularCircuitState → Polarity
op2_perceptiveOut s =
  if afferentDiscrepancy (perceptiveHidden s) < resorptionThreshold s then zero
  else if controllable (perceptiveHidden s) then pos else neg

op3_crossingI_perceptible : CircularCircuitState → CoreAffectPoint
op3_crossingI_perceptible s =
  let c    = mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s)
      att  = attentional s
      susp = SubjectiveHiddenState.descendingSuspension (subjectiveHidden s)
      z    = if isGlobalNeutralityB c then (if susp then persistenceDepth att + 2 else 0)
             else if not (Attentional-isEngagedB att) then (if susp then persistenceDepth att + 2 else 1)
             else persistenceDepth att + 2
  in projectPerceptible c z (precisionA att) (precisionC att) susp

eqRegimeB : FunctionalRegime → FunctionalRegime → Bool
eqRegimeB charge    charge    = true
eqRegimeB neutral   neutral   = true
eqRegimeB discharge discharge = true
eqRegimeB _         _         = false

eqPolarityB : Polarity → Polarity → Bool
eqPolarityB neg  neg  = true
eqPolarityB zero zero = true
eqPolarityB pos  pos  = true
eqPolarityB _    _    = false

op5_subjectiveIn : CircularCircuitState → SubjectiveChannel → CoreAffectPoint → SubjectiveHiddenState
op5_subjectiveIn s ch pt =
  let sh = subjectiveHidden s
      md = if eqRegimeB (regimeA ch) discharge then modelDiscrepancy sh - 1
           else modelDiscrepancy sh
      rv = revisable sh ∨b (eqRegimeB (regimeA ch) charge ∧b eqPolarityB (contextC ch) pos ∧b ge2ℕ (pz pt))
      ds = if eqRegimeB (regimeA ch) neutral ∧b eqPolarityB (contextC ch) zero then false
           else SubjectiveHiddenState.descendingSuspension sh
  in mkSubjectiveHidden md rv ds

op6_perceptiveIn : CircularCircuitState → PerceptiveChannel → CoreAffectPoint → PerceptiveHiddenState
op6_perceptiveIn s ch pt =
  let ph  = perceptiveHidden s
      red = if eqRegimeB (regimeC ch) discharge ∧b intPosB (py pt) then afferentDiscrepancy ph - 1
            else afferentDiscrepancy ph
  in mkPerceptiveHidden (red + perturbation (bodyEnv s)) (controllable ph)

circularCycle : CircularCircuitState → CircularCircuitState
circularCycle s =
  let c  = mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s)
      pt = op3_crossingI_perceptible s
  in mkCircularState
       (op5_subjectiveIn s (routeToSubjective c) pt)
       (op6_perceptiveIn s (routeToPerceptive c) pt)
       (bodyEnv s)
       (sensoryThreshold s)
       (resorptionThreshold s)
       (attentional s)

------------------------------------------------------------------------
-- 5. Unified Dynamics (R_t, Z_t, pi_A, pi_C)
------------------------------------------------------------------------

record UnifiedDynamicsParams : Set where
  constructor mkUnifiedDynamicsParams
  field
    halfScale   : Nat
    lambdaNum   : Nat
    etaScaled   : Nat
    betaAtt     : Nat
    alphaCharge : Nat
    sigmoidK    : Nat
    zMax        : Nat
open UnifiedDynamicsParams public

defaultUnifiedDynamicsParams : UnifiedDynamicsParams
defaultUnifiedDynamicsParams = mkUnifiedDynamicsParams 500 800 600 2 50 100 7

canonicalThetaUp : Nat → Nat
canonicalThetaUp z = 600 + 200 * z

canonicalThetaDown : Nat → Nat
canonicalThetaDown z = 300 + 200 * z

activeResolutionCount : EngineCoupling → EngineCoupling → Nat
activeResolutionCount src dst =
    (if eqPolarityB (attente src) neg ∧b eqPolarityB (attente dst) pos then 1 else 0)
  + (if eqPolarityB (controle src) neg ∧b eqPolarityB (controle dst) pos then 1 else 0)

nextChargeAccumulator : UnifiedDynamicsParams → Nat → Nat → Nat → EngineCoupling → EngineCoupling → Nat
nextChargeAccumulator p r piA piC src dst =
  let s        = 2 * halfScale p
      contribA = if eqPolarityB (attente src) neg then piA else 0
      contribC = if eqPolarityB (controle src) neg then piC else 0
      relief   = etaScaled p * activeResolutionCount src dst
      posPart  = ((lambdaNum p * r) ÷ s) + contribA + contribC
  in posPart - relief

chargeAccumulatorBound : UnifiedDynamicsParams → Nat
chargeAccumulatorBound p =
  let s = 2 * halfScale p
  in (s * s) ÷ (s - lambdaNum p)

nextStratumR5 : UnifiedDynamicsParams → Nat → Nat → Nat
nextStratumR5 p z rNext =
  if canonicalThetaUp z < rNext then minℕ (zMax p) (z + 1)
  else if rNext < canonicalThetaDown z then
    (if leNatB z 2 then 0 else minℕ (zMax p) (z - 1))
  else minℕ (zMax p) z

symmetricSigmoid : Nat → Nat → Int → Nat × Nat
symmetricSigmoid hs k u =
  let au    = absNat u
      shift = (hs * au) ÷ (au + k)
  in if intNonNegB u then (hs + shift , hs - shift)
     else (hs - shift , hs + shift)

chargeIndicatorInt : Polarity → Int
chargeIndicatorInt neg = pos 1
chargeIndicatorInt _   = pos 0

precisionScore : UnifiedDynamicsParams → Int → Int → EngineCoupling → Int
precisionScore p rhoHat kappaHat c =
  pos (betaAtt p) *ℤ
    ((rhoHat -ℤ kappaHat)
     +ℤ (pos (alphaCharge p) *ℤ (chargeIndicatorInt (attente c) -ℤ chargeIndicatorInt (controle c))))

precisionShares : UnifiedDynamicsParams → Int → Int → EngineCoupling → Nat × Nat
precisionShares p rhoHat kappaHat c =
  symmetricSigmoid (halfScale p) (sigmoidK p) (precisionScore p rhoHat kappaHat c)

spatialBudget : Nat → Nat
spatialBudget z = if z < 2 then 0 else 2 * z - 2

projectUnifiedState : UnifiedDynamicsParams → EngineCoupling → Nat → Int → Int → Bool → CoreAffectPoint
projectUnifiedState p c z rhoHat kappaHat susp =
  let sh = precisionShares p rhoHat kappaHat c
  in projectPerceptible c z (fst sh) (snd sh) susp

------------------------------------------------------------------------
-- 6. 41 Audited Theorems (Module 07: PredictiveCircuit)
------------------------------------------------------------------------

-- [1/41] circuit_covers_interfaces_both_sides
circuit_covers_interfaces_both_sides :
  ∀ (iface : EngineInterface) (s : InterfaceSide) →
  Σ CircuitOperation (λ op → (circuitCarrierInterface op ≡ iface) × (circuitOperationSide op ≡ s))
circuit_covers_interfaces_both_sides ifSubjective  sideInternal = subjectiveOut         ,, (refl , refl)
circuit_covers_interfaces_both_sides ifSubjective  sideExternal = subjectiveIn          ,, (refl , refl)
circuit_covers_interfaces_both_sides ifPerceptive  sideInternal = perceptiveOut         ,, (refl , refl)
circuit_covers_interfaces_both_sides ifPerceptive  sideExternal = perceptiveIn          ,, (refl , refl)
circuit_covers_interfaces_both_sides ifAttentional sideInternal = attentionalCrossingI  ,, (refl , refl)
circuit_covers_interfaces_both_sides ifAttentional sideExternal = attentionalCrossingII ,, (refl , refl)

-- [2/41] circuit_refines_inferential_ops
circuit_refines_inferential_ops :
  ∀ (iop : InferentialOperation) →
  Σ CircuitOperation (λ op → circuitToInferentialOp op ≡ iop)
circuit_refines_inferential_ops ascendingSensory     = perceptiveIn         ,, refl
circuit_refines_inferential_ops actionImplementation = perceptiveOut        ,, refl
circuit_refines_inferential_ops contextualGenerative = subjectiveOut        ,, refl
circuit_refines_inferential_ops integrativeWeighting = attentionalCrossingI ,, refl

-- [3/41] phiL1_left_inv
phiL1_left_inv : ∀ (c : EngineCoupling) → phiL1Inv (phiL1 c) ≡ c
phiL1_left_inv (mkEngineCoupling zero zero) = refl
phiL1_left_inv (mkEngineCoupling pos  zero) = refl
phiL1_left_inv (mkEngineCoupling neg  zero) = refl
phiL1_left_inv (mkEngineCoupling zero pos)  = refl
phiL1_left_inv (mkEngineCoupling zero neg)  = refl
phiL1_left_inv (mkEngineCoupling pos  pos)  = refl
phiL1_left_inv (mkEngineCoupling pos  neg)  = refl
phiL1_left_inv (mkEngineCoupling neg  pos)  = refl
phiL1_left_inv (mkEngineCoupling neg  neg)  = refl

-- [4/41] phiL1_right_inv
phiL1_right_inv :
  ∀ (n : ProtoSpatialNode) → isValidProtoSpatialB n ≡ true → phiL1 (phiL1Inv n) ≡ n
phiL1_right_inv (mkProtoNode (pos zero)                 (pos zero))                 _  = refl
phiL1_right_inv (mkProtoNode (pos zero)                 (pos (suc zero)))           ()
phiL1_right_inv (mkProtoNode (pos zero)                 (pos (suc (suc zero))))     _  = refl
phiL1_right_inv (mkProtoNode (pos zero)                 (pos (suc (suc (suc _)))))  ()
phiL1_right_inv (mkProtoNode (pos zero)                 (negsuc zero))              ()
phiL1_right_inv (mkProtoNode (pos zero)                 (negsuc (suc zero)))        _  = refl
phiL1_right_inv (mkProtoNode (pos zero)                 (negsuc (suc (suc _))))     ()
phiL1_right_inv (mkProtoNode (pos (suc zero))           (pos zero))                 ()
phiL1_right_inv (mkProtoNode (pos (suc (suc zero)))     (pos zero))                 _  = refl
phiL1_right_inv (mkProtoNode (pos (suc (suc (suc _))))  (pos zero))                 ()
phiL1_right_inv (mkProtoNode (negsuc zero)              (pos zero))                 ()
phiL1_right_inv (mkProtoNode (negsuc (suc zero))        (pos zero))                 _  = refl
phiL1_right_inv (mkProtoNode (negsuc (suc (suc _)))     (pos zero))                 ()
phiL1_right_inv (mkProtoNode (pos (suc zero))           (pos (suc zero)))           _  = refl
phiL1_right_inv (mkProtoNode (pos (suc zero))           (pos (suc (suc _))))        ()
phiL1_right_inv (mkProtoNode (pos (suc (suc ax)))       (pos (suc ay)))             h  =
  ⊥-elim (absurd-sum ax ay h)
  where
    absurd-sum : ∀ a b → ((suc (suc a) + suc b) == 2) ≡ true → ⊥
    absurd-sum zero    _ ()
    absurd-sum (suc _) _ ()
phiL1_right_inv (mkProtoNode (pos (suc zero))           (negsuc zero))              _  = refl
phiL1_right_inv (mkProtoNode (pos (suc zero))           (negsuc (suc _)))           ()
phiL1_right_inv (mkProtoNode (pos (suc (suc ax)))       (negsuc ay))                h  =
  ⊥-elim (absurd-sum ax ay h)
  where
    absurd-sum : ∀ a b → ((suc (suc a) + suc b) == 2) ≡ true → ⊥
    absurd-sum zero    _ ()
    absurd-sum (suc _) _ ()
phiL1_right_inv (mkProtoNode (negsuc zero)              (pos (suc zero)))           _  = refl
phiL1_right_inv (mkProtoNode (negsuc zero)              (pos (suc (suc _))))        ()
phiL1_right_inv (mkProtoNode (negsuc (suc ax))          (pos (suc ay)))             h  =
  ⊥-elim (absurd-sum ax ay h)
  where
    absurd-sum : ∀ a b → ((suc (suc a) + suc b) == 2) ≡ true → ⊥
    absurd-sum zero    _ ()
    absurd-sum (suc _) _ ()
phiL1_right_inv (mkProtoNode (negsuc zero)              (negsuc zero))              _  = refl
phiL1_right_inv (mkProtoNode (negsuc zero)              (negsuc (suc _)))           ()
phiL1_right_inv (mkProtoNode (negsuc (suc ax))          (negsuc ay))                h  =
  ⊥-elim (absurd-sum ax ay h)
  where
    absurd-sum : ∀ a b → ((suc (suc a) + suc b) == 2) ≡ true → ⊥
    absurd-sum zero    _ ()
    absurd-sum (suc _) _ ()

-- [5/41] phiL1_agrees_with_deployZ2
phiL1_agrees-with-deployZ2 :
  ∀ (c : EngineCoupling) →
  (nx (phiL1 c) ≡ px (deployCouplingAtDepth c 0))
  × (ny (phiL1 c) ≡ py (deployCouplingAtDepth c 0))
phiL1_agrees-with-deployZ2 (mkEngineCoupling zero zero) = refl , refl
phiL1_agrees-with-deployZ2 (mkEngineCoupling pos  zero) = refl , refl
phiL1_agrees-with-deployZ2 (mkEngineCoupling neg  zero) = refl , refl
phiL1_agrees-with-deployZ2 (mkEngineCoupling zero pos)  = refl , refl
phiL1_agrees-with-deployZ2 (mkEngineCoupling zero neg)  = refl , refl
phiL1_agrees-with-deployZ2 (mkEngineCoupling pos  pos)  = refl , refl
phiL1_agrees-with-deployZ2 (mkEngineCoupling pos  neg)  = refl , refl
phiL1_agrees-with-deployZ2 (mkEngineCoupling neg  pos)  = refl , refl
phiL1_agrees-with-deployZ2 (mkEngineCoupling neg  neg)  = refl , refl

-- [6/41] crossingII_is_transpose_of_crossingI
crossingII_is_transpose_of_crossingI :
  ∀ (c : EngineCoupling) →
  crossingIIPos c ≡ (snd (crossingIPos c) , fst (crossingIPos c))
crossingII_is_transpose_of_crossingI _ = refl

-- [7/41] routeToSubjective_injective
Polarity-toRegime-inj : ∀ (p1 p2 : Polarity) → Polarity-toRegime p1 ≡ Polarity-toRegime p2 → p1 ≡ p2
Polarity-toRegime-inj neg  neg  _  = refl
Polarity-toRegime-inj zero zero _  = refl
Polarity-toRegime-inj pos  pos  _  = refl
Polarity-toRegime-inj neg  zero ()
Polarity-toRegime-inj neg  pos  ()
Polarity-toRegime-inj zero neg  ()
Polarity-toRegime-inj zero pos  ()
Polarity-toRegime-inj pos  neg  ()
Polarity-toRegime-inj pos  zero ()

routeToSubjective_injective :
  ∀ (c1 c2 : EngineCoupling) → routeToSubjective c1 ≡ routeToSubjective c2 → c1 ≡ c2
routeToSubjective_injective (mkEngineCoupling a1 ctrl1) (mkEngineCoupling a2 ctrl2) h =
  cong₂ mkEngineCoupling
        (Polarity-toRegime-inj a1 a2 (cong regimeA h))
        (cong contextC h)

-- [8/41] routeToPerceptive_injective
routeToPerceptive_injective :
  ∀ (c1 c2 : EngineCoupling) → routeToPerceptive c1 ≡ routeToPerceptive c2 → c1 ≡ c2
routeToPerceptive_injective (mkEngineCoupling a1 ctrl1) (mkEngineCoupling a2 ctrl2) h =
  cong₂ mkEngineCoupling
        (cong contextA h)
        (Polarity-toRegime-inj ctrl1 ctrl2 (cong regimeC h))

-- [9/41] projectPerceptible_valid
projectPerceptible_valid :
  ∀ (c : EngineCoupling) (z piA piC : Nat) (susp : Bool) →
  IsValidCoreAffect (projectPerceptible c z piA piC susp)
projectPerceptible_valid c z piA piC susp with isGlobalNeutralityB c
... | true with susp ∧b ge2ℕ z
...   | true  = refl
...   | false = refl
projectPerceptible_valid c zero          _   _   _ | false = refl
projectPerceptible_valid c (suc zero)    _   _   _ | false = refl
projectPerceptible_valid c (suc (suc d)) piA piC _ | false = deployCouplingWithPrecision_valid c d piA piC

-- [10/41] projectPerceptible_z2_matches_phiL1
projectPerceptible_z2_matches_phiL1 :
  ∀ (c : EngineCoupling) (piA piC : Nat) (susp : Bool) →
  isGlobalNeutralityB c ≡ false →
  projectPerceptible c 2 piA piC susp ≡ mkPoint (nx (phiL1 c)) (ny (phiL1 c)) 2
projectPerceptible_z2_matches_phiL1 (mkEngineCoupling zero zero) _   _   _ ()
projectPerceptible_z2_matches_phiL1 (mkEngineCoupling pos  zero) _   _   _ _ = refl
projectPerceptible_z2_matches_phiL1 (mkEngineCoupling neg  zero) _   _   _ _ = refl
projectPerceptible_z2_matches_phiL1 (mkEngineCoupling zero pos)  _   _   _ _ = refl
projectPerceptible_z2_matches_phiL1 (mkEngineCoupling zero neg)  _   _   _ _ = refl
projectPerceptible_z2_matches_phiL1 (mkEngineCoupling pos  pos)  piA piC _ _
  rewrite apportionRay-d0-x piA piC = refl
projectPerceptible_z2_matches_phiL1 (mkEngineCoupling pos  neg)  piA piC _ _
  rewrite apportionRay-d0-x piA piC = refl
projectPerceptible_z2_matches_phiL1 (mkEngineCoupling neg  pos)  piA piC _ _
  rewrite apportionRay-d0-x piA piC = refl
projectPerceptible_z2_matches_phiL1 (mkEngineCoupling neg  neg)  piA piC _ _
  rewrite apportionRay-d0-x piA piC = refl

-- [11/41] projectPerceptible_neutral_elevates_to_central
projectPerceptible_neutral_elevates-to-central :
  ∀ (d piA piC : Nat) →
  projectPerceptible (mkEngineCoupling zero zero) (suc (suc d)) piA piC true
  ≡ mkPoint (pos 0) (pos 0) (suc (suc d))
projectPerceptible_neutral_elevates-to-central _ _ _ = refl

-- [12/41] attentional_bottleneck_sum_active
attentional_bottleneck_sum_active :
  ∀ (c : EngineCoupling) →
  isGlobalNeutralityB c ≡ false →
  (if Polarity-isEngaged (attente c) then attentionalWeightX2 c else 0)
  + (if Polarity-isEngaged (controle c) then attentionalWeightY2 c else 0) ≡ 2
attentional_bottleneck_sum_active (mkEngineCoupling zero zero) ()
attentional_bottleneck_sum_active (mkEngineCoupling pos  zero) _ = refl
attentional_bottleneck_sum_active (mkEngineCoupling neg  zero) _ = refl
attentional_bottleneck_sum_active (mkEngineCoupling zero pos)  _ = refl
attentional_bottleneck_sum_active (mkEngineCoupling zero neg)  _ = refl
attentional_bottleneck_sum_active (mkEngineCoupling pos  pos)  _ = refl
attentional_bottleneck_sum_active (mkEngineCoupling pos  neg)  _ = refl
attentional_bottleneck_sum_active (mkEngineCoupling neg  pos)  _ = refl
attentional_bottleneck_sum_active (mkEngineCoupling neg  neg)  _ = refl

-- [13/41] circuitRowSum_exact
circuitRowSum_exact :
  ∀ (src : EngineCoupling) →
  circuitRowSum defaultCircuitKernelParams src ≡ 4 * pow6 (scale defaultCircuitKernelParams)
circuitRowSum_exact (mkEngineCoupling zero zero) = refl
circuitRowSum_exact (mkEngineCoupling pos  zero) = refl
circuitRowSum_exact (mkEngineCoupling neg  zero) = refl
circuitRowSum_exact (mkEngineCoupling zero pos)  = refl
circuitRowSum_exact (mkEngineCoupling zero neg)  = refl
circuitRowSum_exact (mkEngineCoupling pos  pos)  = refl
circuitRowSum_exact (mkEngineCoupling pos  neg)  = refl
circuitRowSum_exact (mkEngineCoupling neg  pos)  = refl
circuitRowSum_exact (mkEngineCoupling neg  neg)  = refl

-- [14/41] veille_absorbing_free
eqCouplingB : EngineCoupling → EngineCoupling → Bool
eqCouplingB c1 c2 = eqPolarityB (attente c1) (attente c2) ∧b eqPolarityB (controle c1) (controle c2)

veille_absorbing_free :
  ∀ (dst : EngineCoupling) →
  circuitWeight freeCircuitKernelParams (mkEngineCoupling zero zero) dst ≡
    (if eqCouplingB dst (mkEngineCoupling zero zero) then 4 * pow6 (scale freeCircuitKernelParams) else 0)
veille_absorbing_free (mkEngineCoupling zero zero) = refl
veille_absorbing_free (mkEngineCoupling pos  zero) = refl
veille_absorbing_free (mkEngineCoupling neg  zero) = refl
veille_absorbing_free (mkEngineCoupling zero pos)  = refl
veille_absorbing_free (mkEngineCoupling zero neg)  = refl
veille_absorbing_free (mkEngineCoupling pos  pos)  = refl
veille_absorbing_free (mkEngineCoupling pos  neg)  = refl
veille_absorbing_free (mkEngineCoupling neg  pos)  = refl
veille_absorbing_free (mkEngineCoupling neg  neg)  = refl

-- [15/41] lyapunov_monotone_free
lyapunov_monotone_free :
  ∀ (src dst : EngineCoupling) →
  (0 < circuitWeight freeCircuitKernelParams src dst) ≡ true →
  leNatB (lyapunovPotential dst) (lyapunovPotential src) ≡ true
lyapunov_monotone_free (mkEngineCoupling zero zero) (mkEngineCoupling zero zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling zero zero) (mkEngineCoupling pos  zero) ()
lyapunov_monotone_free (mkEngineCoupling zero zero) (mkEngineCoupling neg  zero) ()
lyapunov_monotone_free (mkEngineCoupling zero zero) (mkEngineCoupling zero pos)  ()
lyapunov_monotone_free (mkEngineCoupling zero zero) (mkEngineCoupling zero neg)  ()
lyapunov_monotone_free (mkEngineCoupling zero zero) (mkEngineCoupling pos  pos)  ()
lyapunov_monotone_free (mkEngineCoupling zero zero) (mkEngineCoupling pos  neg)  ()
lyapunov_monotone_free (mkEngineCoupling zero zero) (mkEngineCoupling neg  pos)  ()
lyapunov_monotone_free (mkEngineCoupling zero zero) (mkEngineCoupling neg  neg)  ()
lyapunov_monotone_free (mkEngineCoupling pos  zero) (mkEngineCoupling zero zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling pos  zero) (mkEngineCoupling pos  zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling pos  zero) (mkEngineCoupling neg  zero) ()
lyapunov_monotone_free (mkEngineCoupling pos  zero) (mkEngineCoupling zero pos)  ()
lyapunov_monotone_free (mkEngineCoupling pos  zero) (mkEngineCoupling zero neg)  ()
lyapunov_monotone_free (mkEngineCoupling pos  zero) (mkEngineCoupling pos  pos)  ()
lyapunov_monotone_free (mkEngineCoupling pos  zero) (mkEngineCoupling pos  neg)  ()
lyapunov_monotone_free (mkEngineCoupling pos  zero) (mkEngineCoupling neg  pos)  ()
lyapunov_monotone_free (mkEngineCoupling pos  zero) (mkEngineCoupling neg  neg)  ()
lyapunov_monotone_free (mkEngineCoupling neg  zero) (mkEngineCoupling zero zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  zero) (mkEngineCoupling pos  zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  zero) (mkEngineCoupling neg  zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  zero) (mkEngineCoupling zero pos)  ()
lyapunov_monotone_free (mkEngineCoupling neg  zero) (mkEngineCoupling zero neg)  ()
lyapunov_monotone_free (mkEngineCoupling neg  zero) (mkEngineCoupling pos  pos)  ()
lyapunov_monotone_free (mkEngineCoupling neg  zero) (mkEngineCoupling pos  neg)  ()
lyapunov_monotone_free (mkEngineCoupling neg  zero) (mkEngineCoupling neg  pos)  ()
lyapunov_monotone_free (mkEngineCoupling neg  zero) (mkEngineCoupling neg  neg)  ()
lyapunov_monotone_free (mkEngineCoupling zero pos)  (mkEngineCoupling zero zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling zero pos)  (mkEngineCoupling pos  zero) ()
lyapunov_monotone_free (mkEngineCoupling zero pos)  (mkEngineCoupling neg  zero) ()
lyapunov_monotone_free (mkEngineCoupling zero pos)  (mkEngineCoupling zero pos)  _  = refl
lyapunov_monotone_free (mkEngineCoupling zero pos)  (mkEngineCoupling zero neg)  ()
lyapunov_monotone_free (mkEngineCoupling zero pos)  (mkEngineCoupling pos  pos)  ()
lyapunov_monotone_free (mkEngineCoupling zero pos)  (mkEngineCoupling pos  neg)  ()
lyapunov_monotone_free (mkEngineCoupling zero pos)  (mkEngineCoupling neg  pos)  ()
lyapunov_monotone_free (mkEngineCoupling zero pos)  (mkEngineCoupling neg  neg)  ()
lyapunov_monotone_free (mkEngineCoupling zero neg)  (mkEngineCoupling zero zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling zero neg)  (mkEngineCoupling pos  zero) ()
lyapunov_monotone_free (mkEngineCoupling zero neg)  (mkEngineCoupling neg  zero) ()
lyapunov_monotone_free (mkEngineCoupling zero neg)  (mkEngineCoupling zero pos)  _  = refl
lyapunov_monotone_free (mkEngineCoupling zero neg)  (mkEngineCoupling zero neg)  _  = refl
lyapunov_monotone_free (mkEngineCoupling zero neg)  (mkEngineCoupling pos  pos)  ()
lyapunov_monotone_free (mkEngineCoupling zero neg)  (mkEngineCoupling pos  neg)  ()
lyapunov_monotone_free (mkEngineCoupling zero neg)  (mkEngineCoupling neg  pos)  ()
lyapunov_monotone_free (mkEngineCoupling zero neg)  (mkEngineCoupling neg  neg)  ()
lyapunov_monotone_free (mkEngineCoupling pos  pos)  (mkEngineCoupling zero zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling pos  pos)  (mkEngineCoupling pos  zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling pos  pos)  (mkEngineCoupling neg  zero) ()
lyapunov_monotone_free (mkEngineCoupling pos  pos)  (mkEngineCoupling zero pos)  _  = refl
lyapunov_monotone_free (mkEngineCoupling pos  pos)  (mkEngineCoupling zero neg)  ()
lyapunov_monotone_free (mkEngineCoupling pos  pos)  (mkEngineCoupling pos  pos)  _  = refl
lyapunov_monotone_free (mkEngineCoupling pos  pos)  (mkEngineCoupling pos  neg)  ()
lyapunov_monotone_free (mkEngineCoupling pos  pos)  (mkEngineCoupling neg  pos)  ()
lyapunov_monotone_free (mkEngineCoupling pos  pos)  (mkEngineCoupling neg  neg)  ()
lyapunov_monotone_free (mkEngineCoupling pos  neg)  (mkEngineCoupling zero zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling pos  neg)  (mkEngineCoupling pos  zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling pos  neg)  (mkEngineCoupling neg  zero) ()
lyapunov_monotone_free (mkEngineCoupling pos  neg)  (mkEngineCoupling zero pos)  _  = refl
lyapunov_monotone_free (mkEngineCoupling pos  neg)  (mkEngineCoupling zero neg)  _  = refl
lyapunov_monotone_free (mkEngineCoupling pos  neg)  (mkEngineCoupling pos  pos)  _  = refl
lyapunov_monotone_free (mkEngineCoupling pos  neg)  (mkEngineCoupling pos  neg)  _  = refl
lyapunov_monotone_free (mkEngineCoupling pos  neg)  (mkEngineCoupling neg  pos)  ()
lyapunov_monotone_free (mkEngineCoupling pos  neg)  (mkEngineCoupling neg  neg)  ()
lyapunov_monotone_free (mkEngineCoupling neg  pos)  (mkEngineCoupling zero zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  pos)  (mkEngineCoupling pos  zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  pos)  (mkEngineCoupling neg  zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  pos)  (mkEngineCoupling zero pos)  _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  pos)  (mkEngineCoupling zero neg)  ()
lyapunov_monotone_free (mkEngineCoupling neg  pos)  (mkEngineCoupling pos  pos)  _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  pos)  (mkEngineCoupling pos  neg)  ()
lyapunov_monotone_free (mkEngineCoupling neg  pos)  (mkEngineCoupling neg  pos)  _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  pos)  (mkEngineCoupling neg  neg)  ()
lyapunov_monotone_free (mkEngineCoupling neg  neg)  (mkEngineCoupling zero zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  neg)  (mkEngineCoupling pos  zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  neg)  (mkEngineCoupling neg  zero) _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  neg)  (mkEngineCoupling zero pos)  _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  neg)  (mkEngineCoupling zero neg)  _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  neg)  (mkEngineCoupling pos  pos)  _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  neg)  (mkEngineCoupling pos  neg)  _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  neg)  (mkEngineCoupling neg  pos)  _  = refl
lyapunov_monotone_free (mkEngineCoupling neg  neg)  (mkEngineCoupling neg  neg)  _  = refl

-- [16/41] lyapunov_strict_descent_witness
lyapunov_strict_descent_witness :
  ∀ (src : EngineCoupling) →
  isGlobalNeutralityB src ≡ false →
  Σ EngineCoupling (λ dst →
    ((0 < circuitWeight freeCircuitKernelParams src dst) ≡ true)
    × ((lyapunovPotential dst < lyapunovPotential src) ≡ true))
lyapunov_strict_descent_witness (mkEngineCoupling zero zero) ()
lyapunov_strict_descent_witness (mkEngineCoupling pos  zero) _ = mkEngineCoupling zero zero ,, (refl , refl)
lyapunov_strict_descent_witness (mkEngineCoupling neg  zero) _ = mkEngineCoupling pos  zero ,, (refl , refl)
lyapunov_strict_descent_witness (mkEngineCoupling zero pos)  _ = mkEngineCoupling zero zero ,, (refl , refl)
lyapunov_strict_descent_witness (mkEngineCoupling zero neg)  _ = mkEngineCoupling zero pos  ,, (refl , refl)
lyapunov_strict_descent_witness (mkEngineCoupling pos  pos)  _ = mkEngineCoupling zero zero ,, (refl , refl)
lyapunov_strict_descent_witness (mkEngineCoupling pos  neg)  _ = mkEngineCoupling zero pos  ,, (refl , refl)
lyapunov_strict_descent_witness (mkEngineCoupling neg  pos)  _ = mkEngineCoupling pos  zero ,, (refl , refl)
lyapunov_strict_descent_witness (mkEngineCoupling neg  neg)  _ = mkEngineCoupling pos  pos  ,, (refl , refl)

-- [17/41] lyapunov_expected_drift_constant
lyapunov_expected_drift_constant :
  ∀ (src : EngineCoupling) →
  isGlobalNeutralityB src ≡ false →
  weightedDriftSum (uniformFreeKernelParams 100 80) src ≡ 4 * pow5 100 * 80
lyapunov_expected_drift_constant (mkEngineCoupling zero zero) ()
lyapunov_expected_drift_constant (mkEngineCoupling pos  zero) _ = refl
lyapunov_expected_drift_constant (mkEngineCoupling neg  zero) _ = refl
lyapunov_expected_drift_constant (mkEngineCoupling zero pos)  _ = refl
lyapunov_expected_drift_constant (mkEngineCoupling zero neg)  _ = refl
lyapunov_expected_drift_constant (mkEngineCoupling pos  pos)  _ = refl
lyapunov_expected_drift_constant (mkEngineCoupling pos  neg)  _ = refl
lyapunov_expected_drift_constant (mkEngineCoupling neg  pos)  _ = refl
lyapunov_expected_drift_constant (mkEngineCoupling neg  neg)  _ = refl

-- [18/41] axial_peur_bifurcates_p2
axial_peur_bifurcates_p2 :
  ((0 < circuitWeight defaultCircuitKernelParams (mkEngineCoupling neg zero) (mkEngineCoupling neg pos)) ≡ true)
  × ((0 < circuitWeight defaultCircuitKernelParams (mkEngineCoupling neg zero) (mkEngineCoupling neg neg)) ≡ true)
axial_peur_bifurcates_p2 = refl , refl

-- [19/41] veille_reaches_all_one_step
veille_reaches_all_one_step :
  ∀ (dst : EngineCoupling) →
  (0 < circuitWeight defaultCircuitKernelParams (mkEngineCoupling zero zero) dst) ≡ true
veille_reaches_all_one_step (mkEngineCoupling zero zero) = refl
veille_reaches_all_one_step (mkEngineCoupling pos  zero) = refl
veille_reaches_all_one_step (mkEngineCoupling neg  zero) = refl
veille_reaches_all_one_step (mkEngineCoupling zero pos)  = refl
veille_reaches_all_one_step (mkEngineCoupling zero neg)  = refl
veille_reaches_all_one_step (mkEngineCoupling pos  pos)  = refl
veille_reaches_all_one_step (mkEngineCoupling pos  neg)  = refl
veille_reaches_all_one_step (mkEngineCoupling neg  pos)  = refl
veille_reaches_all_one_step (mkEngineCoupling neg  neg)  = refl

-- [20/41] all_reach_veille_two_steps
all_reach_veille_two_steps :
  ∀ (src : EngineCoupling) →
  Σ EngineCoupling (λ mid →
    ((0 < circuitWeight defaultCircuitKernelParams src mid) ≡ true)
    × ((0 < circuitWeight defaultCircuitKernelParams mid (mkEngineCoupling zero zero)) ≡ true))
all_reach_veille_two_steps (mkEngineCoupling zero zero) = mkEngineCoupling zero zero ,, (refl , refl)
all_reach_veille_two_steps (mkEngineCoupling pos  zero) = mkEngineCoupling zero zero ,, (refl , refl)
all_reach_veille_two_steps (mkEngineCoupling neg  zero) = mkEngineCoupling pos  zero ,, (refl , refl)
all_reach_veille_two_steps (mkEngineCoupling zero pos)  = mkEngineCoupling zero zero ,, (refl , refl)
all_reach_veille_two_steps (mkEngineCoupling zero neg)  = mkEngineCoupling zero pos  ,, (refl , refl)
all_reach_veille_two_steps (mkEngineCoupling pos  pos)  = mkEngineCoupling zero zero ,, (refl , refl)
all_reach_veille_two_steps (mkEngineCoupling pos  neg)  = mkEngineCoupling zero pos  ,, (refl , refl)
all_reach_veille_two_steps (mkEngineCoupling neg  pos)  = mkEngineCoupling pos  zero ,, (refl , refl)
all_reach_veille_two_steps (mkEngineCoupling neg  neg)  = mkEngineCoupling pos  pos  ,, (refl , refl)

-- [21/41] veille_unreachable_when_eps_max
maxNoiseKernelParams : CircuitKernelParams
maxNoiseKernelParams = mkKernelParams 100 80 80 0 0 70 70 100 35 35 25

veille_unreachable_when_eps_max :
  ∀ (src : EngineCoupling) →
  circuitWeight maxNoiseKernelParams src (mkEngineCoupling zero zero) ≡ 0
veille_unreachable_when_eps_max (mkEngineCoupling zero zero) = refl
veille_unreachable_when_eps_max (mkEngineCoupling pos  zero) = refl
veille_unreachable_when_eps_max (mkEngineCoupling neg  zero) = refl
veille_unreachable_when_eps_max (mkEngineCoupling zero pos)  = refl
veille_unreachable_when_eps_max (mkEngineCoupling zero neg)  = refl
veille_unreachable_when_eps_max (mkEngineCoupling pos  pos)  = refl
veille_unreachable_when_eps_max (mkEngineCoupling pos  neg)  = refl
veille_unreachable_when_eps_max (mkEngineCoupling neg  pos)  = refl
veille_unreachable_when_eps_max (mkEngineCoupling neg  neg)  = refl

-- [22/41] circularCycle_veille_fixed_point
circularCycle_veille_fixed_point :
  (circularCycle defaultCircularCircuitState ≡ defaultCircularCircuitState)
  × (op3_crossingI_perceptible defaultCircularCircuitState ≡ mkPoint (pos 0) (pos 0) 0)
circularCycle_veille_fixed_point = refl , refl

-- [23/41] circularCycle_reduces_total_discrepancy
activeCircularSample : CircularCircuitState
activeCircularSample =
  mkCircularState
    (mkSubjectiveHidden 2 true false)
    (mkPerceptiveHidden 2 true)
    (mkBodyEnv 0)
    1 1
    (mkAttentionalInterface 1 1 0 1 1)

circularCycle_reduces_total_discrepancy :
  let s1 = circularCycle activeCircularSample in
  (modelDiscrepancy (subjectiveHidden s1) + afferentDiscrepancy (perceptiveHidden s1))
  <ℕ (modelDiscrepancy (subjectiveHidden activeCircularSample) + afferentDiscrepancy (perceptiveHidden activeCircularSample))
circularCycle_reduces_total_discrepancy = s≤s (s≤s (s≤s (≤-step-r z≤n)))

-- [24/41] lyapunov_drift_charge_with_passive_extinction
passiveExtinctionKernelParams : Nat → Nat → CircuitKernelParams
passiveExtinctionKernelParams r dA = mkKernelParams 100 r 80 dA 0 70 70 0 35 35 0

lyapunov_drift_charge-with-passive_extinction :
  weightedDriftSum (passiveExtinctionKernelParams 60 10) (mkEngineCoupling neg zero)
  ≡ 4 * pow5 100 * (60 + 2 * 10)
lyapunov_drift_charge-with-passive_extinction = refl

-- [25/41] p1_without_p2_eps_independent
p1_without_p2_eps_independent :
  ∀ (m eps : Nat) (oc : Bool) →
  effectiveEpsScaled m eps 0 oc ≡ m * eps
p1_without_p2_eps_independent m eps false = refl
p1_without_p2_eps_independent m eps true  = +-zero-r (m * eps)

-- [26/41] epistemic_rigidity_traps_charge_slice
epistemic_rigidity_traps_charge_slice :
  ∀ (p : CircuitKernelParams) (src dst : EngineCoupling) →
  rho p ≡ 0 → deltaA p ≡ 0 →
  attente src ≡ neg → eqPolarityB (attente dst) neg ≡ false →
  circuitWeight p src dst ≡ 0
epistemic_rigidity_traps_charge_slice p (mkEngineCoupling .neg cSrc) (mkEngineCoupling zero cDst) hRho hDelta refl _
  rewrite hDelta | *-zero-r (scale p * scale p) = refl
epistemic_rigidity_traps_charge_slice p (mkEngineCoupling .neg cSrc) (mkEngineCoupling pos  cDst) hRho hDelta refl _
  rewrite hRho | *-zero-r (attentionalWeightX2 (mkEngineCoupling neg cSrc)) | *-zero-r (scale p * scale p) = refl
epistemic_rigidity_traps_charge_slice _ (mkEngineCoupling .neg _)    (mkEngineCoupling neg  _)    _    _      refl ()

-- [27/41] pragmatic_helplessness_traps_charge_slice
pragmatic_helplessness_traps_charge_slice :
  ∀ (p : CircuitKernelParams) (src dst : EngineCoupling) →
  kappa p ≡ 0 → deltaC p ≡ 0 →
  controle src ≡ neg → eqPolarityB (controle dst) neg ≡ false →
  circuitWeight p src dst ≡ 0
pragmatic_helplessness_traps_charge_slice p (mkEngineCoupling aSrc .neg) (mkEngineCoupling aDst zero) hKappa hDelta refl _
  rewrite hDelta | *-zero-r (scale p * scale p) =
  *-zero-r (marginalWeight (scale p) (rho p) (deltaA p) (gammaA p) (epsilon p) (qPosA p) (chi p)
             true (attentionalWeightX2 (mkEngineCoupling aSrc neg)) aSrc aDst)
pragmatic_helplessness_traps_charge_slice p (mkEngineCoupling aSrc .neg) (mkEngineCoupling aDst pos)  hKappa hDelta refl _
  rewrite hKappa | *-zero-r (attentionalWeightY2 (mkEngineCoupling aSrc neg)) | *-zero-r (scale p * scale p) =
  *-zero-r (marginalWeight (scale p) (rho p) (deltaA p) (gammaA p) (epsilon p) (qPosA p) (chi p)
             true (attentionalWeightX2 (mkEngineCoupling aSrc neg)) aSrc aDst)
pragmatic_helplessness_traps_charge_slice _ (mkEngineCoupling _    .neg) (mkEngineCoupling _    neg)  _      _      refl ()

-- [28/41] perseveration_traps_discharge_free
perseverationKernelParams : CircuitKernelParams
perseverationKernelParams = mkKernelParams 100 80 80 0 0 0 0 0 35 35 0

perseveration_traps_discharge_free :
  ∀ (dst : EngineCoupling) →
  circuitWeight perseverationKernelParams (mkEngineCoupling pos pos) dst ≡
    (if eqCouplingB dst (mkEngineCoupling pos pos) then 4 * pow6 100 else 0)
perseveration_traps_discharge_free (mkEngineCoupling zero zero) = refl
perseveration_traps_discharge_free (mkEngineCoupling pos  zero) = refl
perseveration_traps_discharge_free (mkEngineCoupling neg  zero) = refl
perseveration_traps_discharge_free (mkEngineCoupling zero pos)  = refl
perseveration_traps_discharge_free (mkEngineCoupling zero neg)  = refl
perseveration_traps_discharge_free (mkEngineCoupling pos  pos)  = refl
perseveration_traps_discharge_free (mkEngineCoupling pos  neg)  = refl
perseveration_traps_discharge_free (mkEngineCoupling neg  pos)  = refl
perseveration_traps_discharge_free (mkEngineCoupling neg  neg)  = refl

-- [29/41] passive_extinction_zero_relief
passive_extinction_zero_relief :
  activeResolutionCount (mkEngineCoupling neg zero) (mkEngineCoupling zero zero) ≡ 0
passive_extinction_zero_relief = refl

-- [30/41] active_resolution_beats_passive_extinction
active_resolution_beats_passive_extinction :
  (nextChargeAccumulator defaultUnifiedDynamicsParams 1000 500 500
     (mkEngineCoupling neg zero) (mkEngineCoupling pos zero)
   <
   nextChargeAccumulator defaultUnifiedDynamicsParams 1000 500 500
     (mkEngineCoupling neg zero) (mkEngineCoupling zero zero))
  ≡ true
active_resolution_beats_passive_extinction = refl

-- [31/41] charge_accumulator_bounded
charge_accumulator_bounded :
  ∀ (src dst : EngineCoupling) →
  leNatB
    (nextChargeAccumulator defaultUnifiedDynamicsParams
      (chargeAccumulatorBound defaultUnifiedDynamicsParams)
      500 500 src dst)
    (chargeAccumulatorBound defaultUnifiedDynamicsParams)
  ≡ true
charge_accumulator_bounded (mkEngineCoupling zero zero) (mkEngineCoupling a2 c2) with a2 | c2
... | zero | zero = refl
... | zero | pos  = refl
... | zero | neg  = refl
... | pos  | zero = refl
... | pos  | pos  = refl
... | pos  | neg  = refl
... | neg  | zero = refl
... | neg  | pos  = refl
... | neg  | neg  = refl
charge_accumulator_bounded (mkEngineCoupling pos  zero) (mkEngineCoupling a2 c2) with a2 | c2
... | zero | zero = refl
... | zero | pos  = refl
... | zero | neg  = refl
... | pos  | zero = refl
... | pos  | pos  = refl
... | pos  | neg  = refl
... | neg  | zero = refl
... | neg  | pos  = refl
... | neg  | neg  = refl
charge_accumulator_bounded (mkEngineCoupling neg  zero) (mkEngineCoupling a2 c2) with a2 | c2
... | zero | zero = refl
... | zero | pos  = refl
... | zero | neg  = refl
... | pos  | zero = refl
... | pos  | pos  = refl
... | pos  | neg  = refl
... | neg  | zero = refl
... | neg  | pos  = refl
... | neg  | neg  = refl
charge_accumulator_bounded (mkEngineCoupling zero pos)  (mkEngineCoupling a2 c2) with a2 | c2
... | zero | zero = refl
... | zero | pos  = refl
... | zero | neg  = refl
... | pos  | zero = refl
... | pos  | pos  = refl
... | pos  | neg  = refl
... | neg  | zero = refl
... | neg  | pos  = refl
... | neg  | neg  = refl
charge_accumulator_bounded (mkEngineCoupling zero neg)  (mkEngineCoupling a2 c2) with a2 | c2
... | zero | zero = refl
... | zero | pos  = refl
... | zero | neg  = refl
... | pos  | zero = refl
... | pos  | pos  = refl
... | pos  | neg  = refl
... | neg  | zero = refl
... | neg  | pos  = refl
... | neg  | neg  = refl
charge_accumulator_bounded (mkEngineCoupling pos  pos)  (mkEngineCoupling a2 c2) with a2 | c2
... | zero | zero = refl
... | zero | pos  = refl
... | zero | neg  = refl
... | pos  | zero = refl
... | pos  | pos  = refl
... | pos  | neg  = refl
... | neg  | zero = refl
... | neg  | pos  = refl
... | neg  | neg  = refl
charge_accumulator_bounded (mkEngineCoupling pos  neg)  (mkEngineCoupling a2 c2) with a2 | c2
... | zero | zero = refl
... | zero | pos  = refl
... | zero | neg  = refl
... | pos  | zero = refl
... | pos  | pos  = refl
... | pos  | neg  = refl
... | neg  | zero = refl
... | neg  | pos  = refl
... | neg  | neg  = refl
charge_accumulator_bounded (mkEngineCoupling neg  pos)  (mkEngineCoupling a2 c2) with a2 | c2
... | zero | zero = refl
... | zero | pos  = refl
... | zero | neg  = refl
... | pos  | zero = refl
... | pos  | pos  = refl
... | pos  | neg  = refl
... | neg  | zero = refl
... | neg  | pos  = refl
... | neg  | neg  = refl
charge_accumulator_bounded (mkEngineCoupling neg  neg)  (mkEngineCoupling a2 c2) with a2 | c2
... | zero | zero = refl
... | zero | pos  = refl
... | zero | neg  = refl
... | pos  | zero = refl
... | pos  | pos  = refl
... | pos  | neg  = refl
... | neg  | zero = refl
... | neg  | pos  = refl
... | neg  | neg  = refl

-- [32/41] nextStratumR5_le_zMax
minℕ-le-l : ∀ (a b : Nat) → minℕ a b ≤ℕ a
minℕ-le-l a b with ≤ℕ-dec a b | ≤ℕ-total a b
... | yes _  | _       = ≤ℕ-refl a
... | no ¬ab | inj₁ ab = ⊥-elim (¬ab ab)
... | no _   | inj₂ ba = ba

nextStratumR5_le_zMax :
  ∀ (p : UnifiedDynamicsParams) (z rNext : Nat) →
  nextStratumR5 p z rNext ≤ℕ zMax p
nextStratumR5_le_zMax p z rNext with canonicalThetaUp z < rNext
... | true  = minℕ-le-l (zMax p) (z + 1)
... | false with rNext < canonicalThetaDown z
...   | false = minℕ-le-l (zMax p) z
...   | true with leNatB z 2
...     | true  = z≤n
...     | false = minℕ-le-l (zMax p) (z - 1)

-- [33/41] nextStratumR5_short_circuits_z2_to_veille
lt-trans-natB : ∀ (a b c : Nat) → (a < b) ≡ true → (b < c) ≡ true → (a < c) ≡ true
lt-trans-natB zero    (suc _) (suc _) _  _  = refl
lt-trans-natB (suc a) (suc b) (suc c) h1 h2 = lt-trans-natB a b c h1 h2

lt-irrefl-natB : ∀ (a : Nat) → (a < a) ≡ true → ⊥
lt-irrefl-natB (suc a) h = lt-irrefl-natB a h

nextStratumR5_short_circuits_z2-to-veille :
  ∀ (p : UnifiedDynamicsParams) (rNext : Nat) →
  (rNext < canonicalThetaDown 2) ≡ true →
  nextStratumR5 p 2 rNext ≡ 0
nextStratumR5_short_circuits_z2-to-veille p rNext h =
  aux (canonicalThetaUp 2 < rNext) refl
  where
    aux : ∀ (b : Bool) → (canonicalThetaUp 2 < rNext) ≡ b →
          (if b then minℕ (zMax p) 3
           else if rNext < canonicalThetaDown 2 then 0
           else minℕ (zMax p) 2) ≡ 0
    aux false _ rewrite h = refl
    aux true hUp =
      ⊥-elim (lt-irrefl-natB 700
        (lt-trans-natB 700 1000 700 refl (lt-trans-natB 1000 rNext 700 hUp h)))

-- [34/41] nextStratumR5_from_ge2_never_visits_surprise
minℕ-ge : ∀ {k a b : Nat} → k ≤ℕ a → k ≤ℕ b → k ≤ℕ minℕ a b
minℕ-ge {k} {a} {b} ha hb with ≤ℕ-dec a b
... | yes _ = ha
... | no  _ = hb

ge2-ne1 : ∀ {n : Nat} → 2 ≤ℕ n → ¬ (n ≡ 1)
ge2-ne1 (s≤s (s≤s _)) ()

nextStratumR5_from_ge2_never_visits_surprise :
  ∀ (p : UnifiedDynamicsParams) (d rNext : Nat) →
  2 ≤ℕ zMax p →
  ¬ (nextStratumR5 p (suc (suc d)) rNext ≡ 1)
nextStratumR5_from_ge2_never_visits_surprise p d rNext hMax
  with canonicalThetaUp (suc (suc d)) < rNext
... | true =
  ge2-ne1 (minℕ-ge hMax (subst (2 ≤ℕ_) (sym (+-suc-r (suc (suc d)) 0)) (s≤s (s≤s z≤n))))
... | false with rNext < canonicalThetaDown (suc (suc d))
...   | false = ge2-ne1 (minℕ-ge hMax (s≤s (s≤s z≤n)))
...   | true with d
...     | zero   = λ ()
...     | suc d' = ge2-ne1 (minℕ-ge hMax (s≤s (s≤s z≤n)))

-- [35/41] symmetricSigmoid_sum
shift-lt-suc-hs :
  ∀ (hs' au k' : Nat) →
  ((suc hs' * au) ÷ (au + suc k')) <ℕ suc hs'
shift-lt-suc-hs hs' au k' =
  ÷-<-of-<-* {suc hs' * au} {au + suc k'} {suc hs'}
    (subst (0 <ℕ_) (sym (+-suc-r au k')) (s≤s z≤n))
    (subst ((suc hs' * au) <ℕ_)
           (trans (sym (*-distrib-l-+ (suc hs') au (suc k')))
                  (*-comm (suc hs') (au + suc k')))
           (subst (suc (suc hs' * au) ≤ℕ_)
                  (sym (+-suc-r (suc hs' * au) (k' + hs' * suc k')))
                  (s≤s (≤ℕ-add-r (suc hs' * au) (k' + hs' * suc k')))))

shift-le-hs :
  ∀ (hs au k' : Nat) →
  ((hs * au) ÷ (au + suc k')) ≤ℕ hs
shift-le-hs zero au k' rewrite +-suc-r au k' = z≤n
shift-le-hs (suc hs') au k' = <ℕ-to-≤ℕ (shift-lt-suc-hs hs' au k')

plus-minus-twice :
  ∀ (hs sh : Nat) → sh ≤ℕ hs → (hs + sh) + (hs - sh) ≡ 2 * hs
plus-minus-twice hs sh h =
  trans (+-assoc hs sh (hs - sh))
        (trans (cong (hs +_) (add-sub-cancel h))
               (cong (hs +_) (sym (+-zero-r hs))))

symmetricSigmoid_sum :
  ∀ (hs k' : Nat) (u : Int) →
  let s = symmetricSigmoid hs (suc k') u
  in fst s + snd s ≡ 2 * hs
symmetricSigmoid_sum hs k' u with intNonNegB u
... | true  = plus-minus-twice hs ((hs * absNat u) ÷ (absNat u + suc k')) (shift-le-hs hs (absNat u) k')
... | false =
  let sh = (hs * absNat u) ÷ (absNat u + suc k') in
  trans (+-comm (hs - sh) (hs + sh))
        (plus-minus-twice hs sh (shift-le-hs hs (absNat u) k'))

-- [36/41] symmetricSigmoid_pos
symmetricSigmoid_pos :
  ∀ (hs' k' : Nat) (u : Int) →
  let s = symmetricSigmoid (suc hs') (suc k') u
  in (1 ≤ℕ fst s) × (1 ≤ℕ snd s)
symmetricSigmoid_pos hs' k' u with intNonNegB u
... | true =
  s≤s z≤n ,
  sub-pos-of-lt (suc hs') ((suc hs' * absNat u) ÷ (absNat u + suc k')) (shift-lt-suc-hs hs' (absNat u) k')
... | false =
  sub-pos-of-lt (suc hs') ((suc hs' * absNat u) ÷ (absNat u + suc k')) (shift-lt-suc-hs hs' (absNat u) k') ,
  s≤s z≤n

-- [37/41] symmetricSigmoid_neg
div-0-suc : ∀ (n : Nat) → (0 ÷ suc n) ≡ 0
div-0-suc _ = refl

symmetricSigmoid_neg :
  ∀ (hs k' : Nat) (u : Int) →
  let sp = symmetricSigmoid hs (suc k') u
  in symmetricSigmoid hs (suc k') (-ℤ u) ≡ (snd sp , fst sp)
symmetricSigmoid_neg hs k' (pos zero)
  rewrite *-zero-r hs | +-zero-r hs = refl
symmetricSigmoid_neg hs k' (pos (suc n)) = refl
symmetricSigmoid_neg hs k' (negsuc n)    = refl

-- [38/41] precisionShare_double_charge_cancels_alpha
addℤ-zero-r : ∀ (z : Int) → (z +ℤ pos 0) ≡ z
addℤ-zero-r (pos a)    rewrite +-zero-r a = refl
addℤ-zero-r (negsuc a) = refl

precisionShare_double_charge_cancels_alpha :
  ∀ (p : UnifiedDynamicsParams) (rH kH : Int) →
  precisionScore p rH kH (mkEngineCoupling neg neg)
  ≡ pos (betaAtt p) *ℤ (rH -ℤ kH)
precisionShare_double_charge_cancels_alpha p rH kH
  rewrite *-zero-r (alphaCharge p) | addℤ-zero-r (rH -ℤ kH) = refl

-- [39/41] projectUnifiedState_valid
projectUnifiedState_valid :
  ∀ (p : UnifiedDynamicsParams) (c : EngineCoupling) (z : Nat) (rH kH : Int) (susp : Bool) →
  IsValidCoreAffect (projectUnifiedState p c z rH kH susp)
projectUnifiedState_valid p c z rH kH susp =
  let sh = precisionShares p rH kH c
  in projectPerceptible_valid c z (fst sh) (snd sh) susp

-- [40/41] projectUnifiedState_crown_budget
projectUnifiedState_crown_budget :
  ∀ (p : UnifiedDynamicsParams) (c : EngineCoupling) (d : Nat) (rH kH : Int) (susp : Bool) →
  isGlobalNeutralityB c ≡ false →
  displacementSum (projectUnifiedState p c (suc (suc d)) rH kH susp)
  ≡ spatialBudget (suc (suc d))
projectUnifiedState_crown_budget p c d rH kH susp hNotNeut
  rewrite hNotNeut | +-suc-r d (suc d + 0) | +-zero-r (suc d) =
  let sh = precisionShares p rH kH c
  in deployCouplingWithPrecision_budget_conservation c d (fst sh) (snd sh) hNotNeut

-- [41/41] projectUnifiedState_reaches_lateral_consternation
projectUnifiedState_reaches_lateral_consternation :
  projectUnifiedState defaultUnifiedDynamicsParams (mkEngineCoupling neg pos) 3 (pos 10) (pos 90) true
  ≡ mkPoint (negsuc 0) (pos 3) 3
projectUnifiedState_reaches_lateral_consternation = refl

