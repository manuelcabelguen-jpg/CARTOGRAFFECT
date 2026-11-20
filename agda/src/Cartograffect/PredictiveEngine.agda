{-# OPTIONS --safe --without-K #-}
-- Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
-- SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
-- Author: Manuel Cabelguen
--
-- Module 01 : PredictiveEngine (Agda 2.9.0, --safe --without-K)

module Cartograffect.PredictiveEngine where

open import Cartograffect.Prelude

-- ---------------------------------------------------------------------------
-- 1. Types fondamentaux du moteur inférentiel prédictif
-- ---------------------------------------------------------------------------
data Polarity : Set where
  neg  : Polarity
  zero : Polarity
  pos  : Polarity

data FunctionalRegime : Set where
  charge    : FunctionalRegime
  neutral   : FunctionalRegime
  discharge : FunctionalRegime

data InferentialOperation : Set where
  ascendingSensory     : InferentialOperation
  actionImplementation : InferentialOperation
  contextualGenerative : InferentialOperation
  integrativeWeighting : InferentialOperation

data EngineInterface : Set where
  ifPerceptive  : EngineInterface
  ifSubjective  : EngineInterface
  ifAttentional : EngineInterface

Polarity-toRegime : Polarity → FunctionalRegime
Polarity-toRegime neg  = charge
Polarity-toRegime zero = neutral
Polarity-toRegime pos  = discharge

Polarity-invert : Polarity → Polarity
Polarity-invert neg  = pos
Polarity-invert zero = zero
Polarity-invert pos  = neg

Polarity-isEngaged : Polarity → Bool
Polarity-isEngaged neg  = true
Polarity-isEngaged zero = false
Polarity-isEngaged pos  = true

InferentialOperation-carrierInterface : InferentialOperation → EngineInterface
InferentialOperation-carrierInterface ascendingSensory     = ifPerceptive
InferentialOperation-carrierInterface actionImplementation = ifPerceptive
InferentialOperation-carrierInterface contextualGenerative = ifSubjective
InferentialOperation-carrierInterface integrativeWeighting = ifAttentional

record SalientDiscrepancy : Set where
  constructor mkSalientDiscrepancy
  field
    magnitude           : Nat
    sensoryThreshold    : Nat
    resorptionThreshold : Nat
    thresholdInvariant  : resorptionThreshold ≤ℕ sensoryThreshold

open SalientDiscrepancy public

isSensorilySalientB : SalientDiscrepancy → Bool
isSensorilySalientB d = not (magnitude d < sensoryThreshold d)

isInRemanenceWindowB : SalientDiscrepancy → Bool
isInRemanenceWindowB d = not (magnitude d < resorptionThreshold d) ∧b (magnitude d < sensoryThreshold d)

record PerceptiveInterface : Set where
  constructor mkPerceptiveInterface
  field
    controleGradient : Polarity

open PerceptiveInterface public

record SubjectiveInterface : Set where
  constructor mkSubjectiveInterface
  field
    attenteGradient      : Polarity
    descendingSuspension : Bool

open SubjectiveInterface public

record AttentionalInterface : Set where
  constructor mkAttentionalInterface
  field
    allocatedPrecision  : Nat
    engagementThreshold : Nat
    persistenceDepth    : Nat
    precisionA          : Nat
    precisionC          : Nat

open AttentionalInterface public

Attentional-isEngagedB : AttentionalInterface → Bool
Attentional-isEngagedB att = not (allocatedPrecision att < engagementThreshold att)

record EngineCoupling : Set where
  constructor mkEngineCoupling
  field
    attente  : Polarity
    controle : Polarity

open EngineCoupling public

isGlobalNeutralityB : EngineCoupling → Bool
isGlobalNeutralityB c = not (Polarity-isEngaged (attente c)) ∧b not (Polarity-isEngaged (controle c))

isSingleEngagedB : EngineCoupling → Bool
isSingleEngagedB c =
  (Polarity-isEngaged (attente c) ∧b not (Polarity-isEngaged (controle c)))
  ∨b (not (Polarity-isEngaged (attente c)) ∧b Polarity-isEngaged (controle c))

isDualEngagedB : EngineCoupling → Bool
isDualEngagedB c = Polarity-isEngaged (attente c) ∧b Polarity-isEngaged (controle c)

record PredictiveEngineState : Set where
  constructor mkPredictiveEngineState
  field
    discrepancy : SalientDiscrepancy
    perceptive  : PerceptiveInterface
    subjective  : SubjectiveInterface
    attentional : AttentionalInterface

open PredictiveEngineState public

defaultPredictiveEngineState : PredictiveEngineState
defaultPredictiveEngineState =
  mkPredictiveEngineState
    (mkSalientDiscrepancy 0 1 1 (s≤s z≤n))
    (mkPerceptiveInterface neg)
    (mkSubjectiveInterface neg false)
    (mkAttentionalInterface 0 0 0 1 1)

currentCoupling : PredictiveEngineState → EngineCoupling
currentCoupling s =
  mkEngineCoupling (attenteGradient (subjective s)) (controleGradient (perceptive s))

feedbackUpdate : PredictiveEngineState → Polarity → Polarity → Nat → PredictiveEngineState
feedbackUpdate s newA newC newP =
  mkPredictiveEngineState
    (discrepancy s)
    (mkPerceptiveInterface newC)
    (mkSubjectiveInterface newA (descendingSuspension (subjective s)))
    (mkAttentionalInterface
      newP
      (engagementThreshold (attentional s))
      (persistenceDepth (attentional s))
      (precisionA (attentional s))
      (precisionC (attentional s)))

feedbackUpdateWeighted : PredictiveEngineState → Polarity → Polarity → Nat → Nat → Nat → PredictiveEngineState
feedbackUpdateWeighted s newA newC newP newPA newPC =
  mkPredictiveEngineState
    (discrepancy s)
    (mkPerceptiveInterface newC)
    (mkSubjectiveInterface newA (descendingSuspension (subjective s)))
    (mkAttentionalInterface
      newP
      (engagementThreshold (attentional s))
      (persistenceDepth (attentional s))
      newPA
      newPC)

engineStep : PredictiveEngineState → PredictiveEngineState
engineStep s =
  let c = currentCoupling s
  in if not (isSensorilySalientB (discrepancy s)) then
       (if isInRemanenceWindowB (discrepancy s) then s
        else mkPredictiveEngineState
               (discrepancy s)
               (mkPerceptiveInterface zero)
               (mkSubjectiveInterface zero false)
               (mkAttentionalInterface 0 (engagementThreshold (attentional s)) 0
                 (precisionA (attentional s)) (precisionC (attentional s))))
     else if isGlobalNeutralityB c then
       mkPredictiveEngineState
         (discrepancy s)
         (mkPerceptiveInterface pos)
         (subjective s)
         (attentional s)
     else if not (descendingSuspension (subjective s)) ∧b not (Attentional-isEngagedB (attentional s)) then
       mkPredictiveEngineState
         (discrepancy s)
         (perceptive s)
         (mkSubjectiveInterface (attenteGradient (subjective s)) true)
         (attentional s)
     else if not (Attentional-isEngagedB (attentional s)) then
       mkPredictiveEngineState
         (discrepancy s)
         (perceptive s)
         (subjective s)
         (mkAttentionalInterface
           (engagementThreshold (attentional s))
           (engagementThreshold (attentional s))
           (persistenceDepth (attentional s))
           (precisionA (attentional s))
           (precisionC (attentional s)))
     else s

-- ---------------------------------------------------------------------------
-- 2. Les 7 théorèmes certifiés de PredictiveEngine
-- ---------------------------------------------------------------------------

-- [1/7] Polarity_invert_involutive
Polarity_invert_involutive : ∀ (p : Polarity) → Polarity-invert (Polarity-invert p) ≡ p
Polarity_invert_involutive neg  = refl
Polarity_invert_involutive zero = refl
Polarity_invert_involutive pos  = refl

-- [2/7] coupling_regime_partition
coupling_regime_partition :
  ∀ (c : EngineCoupling) →
  ((isGlobalNeutralityB c ≡ true) × (isSingleEngagedB c ≡ false) × (isDualEngagedB c ≡ false))
  ⊎ (((isGlobalNeutralityB c ≡ false) × (isSingleEngagedB c ≡ true) × (isDualEngagedB c ≡ false))
     ⊎ ((isGlobalNeutralityB c ≡ false) × (isSingleEngagedB c ≡ false) × (isDualEngagedB c ≡ true)))
coupling_regime_partition (mkEngineCoupling neg  neg)  = inj₂ (inj₂ (refl , refl , refl))
coupling_regime_partition (mkEngineCoupling neg  zero) = inj₂ (inj₁ (refl , refl , refl))
coupling_regime_partition (mkEngineCoupling neg  pos)  = inj₂ (inj₂ (refl , refl , refl))
coupling_regime_partition (mkEngineCoupling zero neg)  = inj₂ (inj₁ (refl , refl , refl))
coupling_regime_partition (mkEngineCoupling zero zero) = inj₁ (refl , refl , refl)
coupling_regime_partition (mkEngineCoupling zero pos)  = inj₂ (inj₁ (refl , refl , refl))
coupling_regime_partition (mkEngineCoupling pos  neg)  = inj₂ (inj₂ (refl , refl , refl))
coupling_regime_partition (mkEngineCoupling pos  zero) = inj₂ (inj₁ (refl , refl , refl))
coupling_regime_partition (mkEngineCoupling pos  pos)  = inj₂ (inj₂ (refl , refl , refl))

-- [3/7] feedbackUpdate_couples_gradients
feedbackUpdate_couples_gradients :
  ∀ (s : PredictiveEngineState) (newA newC : Polarity) (newP : Nat) →
  (currentCoupling (feedbackUpdate s newA newC newP) ≡ mkEngineCoupling newA newC)
  × (allocatedPrecision (attentional (feedbackUpdate s newA newC newP)) ≡ newP)
feedbackUpdate_couples_gradients _ _ _ _ = refl , refl

-- [4/7] inferential_loop_covers_interfaces
inferential_loop_covers_interfaces :
  ∀ (iface : EngineInterface) → Σ InferentialOperation (λ op → InferentialOperation-carrierInterface op ≡ iface)
inferential_loop_covers_interfaces ifPerceptive  = ascendingSensory     ,, refl
inferential_loop_covers_interfaces ifSubjective  = contextualGenerative ,, refl
inferential_loop_covers_interfaces ifAttentional = integrativeWeighting ,, refl

-- [5/7] feedbackUpdateWeighted_couples_precision
feedbackUpdateWeighted_couples_precision :
  ∀ (s : PredictiveEngineState) (newA newC : Polarity) (newP newPA newPC : Nat) →
  let s1 = feedbackUpdateWeighted s newA newC newP newPA newPC in
  (currentCoupling s1 ≡ mkEngineCoupling newA newC)
  × (allocatedPrecision (attentional s1) ≡ newP)
  × (precisionA (attentional s1) ≡ newPA)
  × (precisionC (attentional s1) ≡ newPC)
feedbackUpdateWeighted_couples_precision _ _ _ _ _ _ = refl , refl , refl , refl

-- [6/7] engineStep_remanence
engineStep_remanence :
  ∀ (s : PredictiveEngineState) →
  isSensorilySalientB (discrepancy s) ≡ false →
  isInRemanenceWindowB (discrepancy s) ≡ true →
  engineStep s ≡ s
engineStep_remanence s hSal hRem rewrite hSal | hRem = refl

-- [7/7] engineStep_phase_progression
nat-<-irrefl-pe : ∀ (n : Nat) → (n < n) ≡ false
nat-<-irrefl-pe zero    = refl
nat-<-irrefl-pe (suc n) = nat-<-irrefl-pe n

Attentional-engaged-self :
  ∀ (thr depth pA pC : Nat) →
  Attentional-isEngagedB (mkAttentionalInterface thr thr depth pA pC) ≡ true
Attentional-engaged-self thr _ _ _ rewrite nat-<-irrefl-pe thr = refl

engineStep-phase1 :
  ∀ (d : SalientDiscrepancy) (att : AttentionalInterface) →
  isSensorilySalientB d ≡ true →
  engineStep (mkPredictiveEngineState d (mkPerceptiveInterface zero) (mkSubjectiveInterface zero false) att)
  ≡ mkPredictiveEngineState d (mkPerceptiveInterface pos) (mkSubjectiveInterface zero false) att
engineStep-phase1 d _ hSal rewrite hSal = refl

engineStep-phase2 :
  ∀ (d : SalientDiscrepancy) (aPol cPol : Polarity) (att : AttentionalInterface) →
  isSensorilySalientB d ≡ true →
  isGlobalNeutralityB (mkEngineCoupling aPol cPol) ≡ false →
  Attentional-isEngagedB att ≡ false →
  engineStep (mkPredictiveEngineState d (mkPerceptiveInterface cPol) (mkSubjectiveInterface aPol false) att)
  ≡ mkPredictiveEngineState d (mkPerceptiveInterface cPol) (mkSubjectiveInterface aPol true) att
engineStep-phase2 d aPol cPol att hSal hNotNeut hAtt
  rewrite hSal | hNotNeut | hAtt = refl

engineStep-phase3 :
  ∀ (d : SalientDiscrepancy) (aPol cPol : Polarity) (att : AttentionalInterface) →
  isSensorilySalientB d ≡ true →
  isGlobalNeutralityB (mkEngineCoupling aPol cPol) ≡ false →
  Attentional-isEngagedB att ≡ false →
  engineStep (mkPredictiveEngineState d (mkPerceptiveInterface cPol) (mkSubjectiveInterface aPol true) att)
  ≡ mkPredictiveEngineState d (mkPerceptiveInterface cPol) (mkSubjectiveInterface aPol true)
      (mkAttentionalInterface (engagementThreshold att) (engagementThreshold att)
        (persistenceDepth att) (precisionA att) (precisionC att))
engineStep-phase3 d aPol cPol att hSal hNotNeut hAtt
  rewrite hSal | hNotNeut | hAtt = refl

engineStep_phase_progression :
  ∀ (s : PredictiveEngineState) →
  isSensorilySalientB (discrepancy s) ≡ true →
  isGlobalNeutralityB (currentCoupling s) ≡ true →
  descendingSuspension (subjective s) ≡ false →
  Attentional-isEngagedB (attentional s) ≡ false →
  let s1 = engineStep s
      s2 = engineStep s1
      s3 = engineStep s2
  in (Polarity-isEngaged (controle (currentCoupling s1)) ≡ true)
     × (descendingSuspension (subjective s2) ≡ true)
     × (Attentional-isEngagedB (attentional s3) ≡ true)
engineStep_phase_progression
  (mkPredictiveEngineState d (mkPerceptiveInterface zero) (mkSubjectiveInterface zero false) att)
  hSal _ _ hAtt
  rewrite engineStep-phase1 d att hSal
        | engineStep-phase2 d zero pos att hSal refl hAtt
        | engineStep-phase3 d zero pos att hSal refl hAtt =
  refl , refl , Attentional-engaged-self
                  (engagementThreshold att)
                  (persistenceDepth att)
                  (precisionA att)
                  (precisionC att)
engineStep_phase_progression
  (mkPredictiveEngineState _ (mkPerceptiveInterface zero) (mkSubjectiveInterface zero true) _)
  _ _ () _
engineStep_phase_progression
  (mkPredictiveEngineState _ (mkPerceptiveInterface _) (mkSubjectiveInterface neg _) _)
  _ () _ _
engineStep_phase_progression
  (mkPredictiveEngineState _ (mkPerceptiveInterface _) (mkSubjectiveInterface pos _) _)
  _ () _ _
engineStep_phase_progression
  (mkPredictiveEngineState _ (mkPerceptiveInterface neg) (mkSubjectiveInterface zero _) _)
  _ () _ _
engineStep_phase_progression
  (mkPredictiveEngineState _ (mkPerceptiveInterface pos) (mkSubjectiveInterface zero _) _)
  _ () _ _
