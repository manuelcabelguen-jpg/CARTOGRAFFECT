{-# OPTIONS --safe --without-K #-}
-- Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
-- SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
-- Author: Manuel Cabelguen
--
-- Module dérivé : EndToEndBridge (Agda 2.9.0, --safe --without-K)
-- Ponts formels complets de bout en bout (Strate 0 Hexa-Prouvée)

module Cartograffect.EndToEndBridge where

open import Agda.Builtin.String using (primStringEquality)
open import Cartograffect.Prelude
open import Cartograffect.PredictiveEngine
open import Cartograffect.CoreAffect
open import Cartograffect.AffectiveMatrix
open import Cartograffect.AffectiveTaxonomy
open import Cartograffect.AffectiveDynamics
open import Cartograffect.Lexicon176
open import Cartograffect.PredictiveCircuit
open import Cartograffect.OperantFactorization

-- ---------------------------------------------------------------------------
-- 1. Définitions canoniques des ponts opérants et pipelines terminaux
-- ---------------------------------------------------------------------------

data OperantRole : Set where
  roleCentralOperator : OperantRole
  rolePreOperantAxial : OrientationSector → OperantRole
  rolePureOperant     : OperantContingency → OperantRole
  roleBlendedLateral  : OrientationSector → OperantContingency → OperantRole

couplingToContingency : EngineCoupling → Maybe OperantContingency
couplingToContingency (mkEngineCoupling pos pos) = just (mkOperantContingency reinforcement addition)
couplingToContingency (mkEngineCoupling pos neg) = just (mkOperantContingency reinforcement removal)
couplingToContingency (mkEngineCoupling neg neg) = just (mkOperantContingency punishment    addition)
couplingToContingency (mkEngineCoupling neg pos) = just (mkOperantContingency punishment    removal)
couplingToContingency _                          = nothing

quadrantContingency : Int → Int → Maybe OperantContingency
quadrantContingency (pos (suc _)) (pos (suc _)) = just (mkOperantContingency reinforcement addition)
quadrantContingency (pos (suc _)) (negsuc _)    = just (mkOperantContingency reinforcement removal)
quadrantContingency (negsuc _)    (negsuc _)    = just (mkOperantContingency punishment    addition)
quadrantContingency (negsuc _)    (pos (suc _)) = just (mkOperantContingency punishment    removal)
quadrantContingency _             _             = nothing

classifyOperantRole : CoreAffectPoint → OperantRole
classifyOperantRole p with quadrantContingency (px p) (py p) | dominantSector p
... | just c  | optSome sec = roleBlendedLateral sec c
... | just c  | optNone     = rolePureOperant c
... | nothing | optSome sec = rolePreOperantAxial sec
... | nothing | optNone     = roleCentralOperator

evaluateUnifiedTaxonomy :
  UnifiedDynamicsParams → EngineCoupling → Nat → Int → Int → Bool → TaxonomicState
evaluateUnifiedTaxonomy p c z rhoHat kappaHat susp =
  evaluateTaxonomy (evaluateMatrix (projectUnifiedState p c z rhoHat kappaHat susp) canonicalMapping)

evaluateCircularTaxonomy : CircularCircuitState → TaxonomicState
evaluateCircularTaxonomy s =
  evaluateTaxonomy (evaluateMatrix (op3_crossingI_perceptible s) canonicalMapping)

-- ---------------------------------------------------------------------------
-- 2. Unicité nominale (all176Entries_unique_labels) et lemmes auxiliaires
-- ---------------------------------------------------------------------------

-- Lemme auxiliaire d'audit : les 176 étiquettes nominales de all176Entries sont deux à deux distinctes.
all176Entries_unique_labels : NoDup (map entryLabel all176Entries)
all176Entries_unique_labels =
  nodupByB-to-NoDup primStringEquality (map entryLabel all176Entries) refl

+-2-eq-suc2 : ∀ (d : Nat) → d + 2 ≡ suc (suc d)
+-2-eq-suc2 d =
  trans (+-suc-r d 1)
        (cong suc (trans (+-suc-r d 0) (cong suc (+-zero-r d))))

quadrant-zero-right : ∀ (x : Int) → quadrantContingency x (pos 0) ≡ nothing
quadrant-zero-right (pos zero)    = refl
quadrant-zero-right (pos (suc _)) = refl
quadrant-zero-right (negsuc _)    = refl

quadrant-signed-engaged :
  ∀ (a ctrl : Polarity) (rx ry : Nat) →
  1 ≤ℕ rx → 1 ≤ℕ ry →
  Polarity-isEngaged a ≡ true → Polarity-isEngaged ctrl ≡ true →
  quadrantContingency (signedAmplitude a rx) (signedAmplitude ctrl ry)
  ≡ couplingToContingency (mkEngineCoupling a ctrl)
quadrant-signed-engaged pos pos (suc _) (suc _) _ _ _ _ = refl
quadrant-signed-engaged pos neg (suc _) (suc _) _ _ _ _ = refl
quadrant-signed-engaged neg neg (suc _) (suc _) _ _ _ _ = refl
quadrant-signed-engaged neg pos (suc _) (suc _) _ _ _ _ = refl
quadrant-signed-engaged zero _  _       _       _ _ () _
quadrant-signed-engaged pos zero _      _       _ _ _ ()
quadrant-signed-engaged neg zero _      _       _ _ _ ()

deploy-quadrant-eq :
  ∀ (c : EngineCoupling) (d piA piC : Nat) →
  quadrantContingency
    (px (deployCouplingWithPrecision c d piA piC))
    (py (deployCouplingWithPrecision c d piA piC))
  ≡ couplingToContingency c
deploy-quadrant-eq (mkEngineCoupling zero zero) _ _   _   = refl
deploy-quadrant-eq (mkEngineCoupling pos  zero) d _   _   = quadrant-zero-right (pos (fullRay d))
deploy-quadrant-eq (mkEngineCoupling neg  zero) d _   _   = quadrant-zero-right (signedAmplitude neg (fullRay d))
deploy-quadrant-eq (mkEngineCoupling zero pos)  _ _   _   = refl
deploy-quadrant-eq (mkEngineCoupling zero neg)  _ _   _   = refl
deploy-quadrant-eq (mkEngineCoupling pos  pos)  d piA piC =
  quadrant-signed-engaged pos pos (apportionRayX d piA piC) (apportionRayY d piA piC)
    (apportionRayX-pos d piA piC) (apportionRayY-pos d piA piC) refl refl
deploy-quadrant-eq (mkEngineCoupling pos  neg)  d piA piC =
  quadrant-signed-engaged pos neg (apportionRayX d piA piC) (apportionRayY d piA piC)
    (apportionRayX-pos d piA piC) (apportionRayY-pos d piA piC) refl refl
deploy-quadrant-eq (mkEngineCoupling neg  pos)  d piA piC =
  quadrant-signed-engaged neg pos (apportionRayX d piA piC) (apportionRayY d piA piC)
    (apportionRayX-pos d piA piC) (apportionRayY-pos d piA piC) refl refl
deploy-quadrant-eq (mkEngineCoupling neg  neg)  d piA piC =
  quadrant-signed-engaged neg neg (apportionRayX d piA piC) (apportionRayY d piA piC)
    (apportionRayX-pos d piA piC) (apportionRayY-pos d piA piC) refl refl

projectPerceptible-neutral-quadrant :
  ∀ (c : EngineCoupling) (z piA piC : Nat) (susp : Bool) →
  isGlobalNeutralityB c ≡ true →
  quadrantContingency
    (px (projectPerceptible c z piA piC susp))
    (py (projectPerceptible c z piA piC susp))
  ≡ nothing
projectPerceptible-neutral-quadrant c z _ _ susp hNeut
  rewrite hNeut with susp ∧b ge2ℕ z
... | true  = refl
... | false = refl

couplingToContingency-neutral :
  ∀ (c : EngineCoupling) → isGlobalNeutralityB c ≡ true → couplingToContingency c ≡ nothing
couplingToContingency-neutral (mkEngineCoupling zero zero) _  = refl
couplingToContingency-neutral (mkEngineCoupling pos  _)    ()
couplingToContingency-neutral (mkEngineCoupling neg  _)    ()
couplingToContingency-neutral (mkEngineCoupling zero pos)  ()
couplingToContingency-neutral (mkEngineCoupling zero neg)  ()

projectPerceptible-quadrant-suc2 :
  ∀ (c : EngineCoupling) (d piA piC : Nat) (susp : Bool) →
  quadrantContingency
    (px (projectPerceptible c (suc (suc d)) piA piC susp))
    (py (projectPerceptible c (suc (suc d)) piA piC susp))
  ≡ couplingToContingency c
projectPerceptible-quadrant-suc2 c d piA piC susp =
  aux (isGlobalNeutralityB c) susp refl
  where
    aux : ∀ (b s0 : Bool) → isGlobalNeutralityB c ≡ b →
          quadrantContingency
            (px (if b then (if s0 ∧b true then mkPoint (pos 0) (pos 0) (suc (suc d)) else mkPoint (pos 0) (pos 0) 0)
                 else deployCouplingWithPrecision c d piA piC))
            (py (if b then (if s0 ∧b true then mkPoint (pos 0) (pos 0) (suc (suc d)) else mkPoint (pos 0) (pos 0) 0)
                 else deployCouplingWithPrecision c d piA piC))
          ≡ couplingToContingency c
    aux true  true  hNeut = sym (couplingToContingency-neutral c hNeut)
    aux true  false hNeut = sym (couplingToContingency-neutral c hNeut)
    aux false _     _     = deploy-quadrant-eq c d piA piC

projectPerceptible-quadrant-eq :
  ∀ (c : EngineCoupling) (d piA piC : Nat) (susp : Bool) →
  quadrantContingency
    (px (projectPerceptible c (d + 2) piA piC susp))
    (py (projectPerceptible c (d + 2) piA piC susp))
  ≡ couplingToContingency c
projectPerceptible-quadrant-eq c d piA piC susp
  rewrite +-2-eq-suc2 d = projectPerceptible-quadrant-suc2 c d piA piC susp

projectPerceptible-le7 :
  ∀ (c : EngineCoupling) (z piA piC : Nat) (susp : Bool) →
  leNatB z 7 ≡ true →
  leNatB (pz (projectPerceptible c z piA piC susp)) 7 ≡ true
projectPerceptible-le7 c z piA piC susp hz7 with isGlobalNeutralityB c
... | true with susp ∧b ge2ℕ z
...   | true  = hz7
...   | false = refl
projectPerceptible-le7 _ zero          _   _   _ _   | false = refl
projectPerceptible-le7 _ (suc zero)    _   _   _ _   | false = refl
projectPerceptible-le7 (mkEngineCoupling zero zero) (suc (suc _)) _ _ _ _   | false = refl
projectPerceptible-le7 (mkEngineCoupling pos  zero) (suc (suc _)) _ _ _ hz7 | false = hz7
projectPerceptible-le7 (mkEngineCoupling neg  zero) (suc (suc _)) _ _ _ hz7 | false = hz7
projectPerceptible-le7 (mkEngineCoupling zero pos)  (suc (suc _)) _ _ _ hz7 | false = hz7
projectPerceptible-le7 (mkEngineCoupling zero neg)  (suc (suc _)) _ _ _ hz7 | false = hz7
projectPerceptible-le7 (mkEngineCoupling pos  pos)  (suc (suc _)) _ _ _ hz7 | false = hz7
projectPerceptible-le7 (mkEngineCoupling pos  neg)  (suc (suc _)) _ _ _ hz7 | false = hz7
projectPerceptible-le7 (mkEngineCoupling neg  pos)  (suc (suc _)) _ _ _ hz7 | false = hz7
projectPerceptible-le7 (mkEngineCoupling neg  neg)  (suc (suc _)) _ _ _ hz7 | false = hz7

le5-add2-le7 : ∀ (d : Nat) → leNatB d 5 ≡ true → leNatB (d + 2) 7 ≡ true
le5-add2-le7 0 _ = refl
le5-add2-le7 1 _ = refl
le5-add2-le7 2 _ = refl
le5-add2-le7 3 _ = refl
le5-add2-le7 4 _ = refl
le5-add2-le7 5 _ = refl
le5-add2-le7 (suc (suc (suc (suc (suc (suc _)))))) ()

-- Arithmétique positive pour le théorème [3/10] (P2 Markov)
mul-posℕ : ∀ {a b : Nat} → 1 ≤ℕ a → 1 ≤ℕ b → 1 ≤ℕ (a * b)
mul-posℕ {suc _} {suc _} (s≤s _) (s≤s _) = s≤s z≤n

effectiveEps-true-pos :
  ∀ (m eps chi : Nat) →
  1 ≤ℕ m → 1 ≤ℕ chi → eps ≤ℕ m →
  1 ≤ℕ effectiveEpsScaled m eps chi true
effectiveEps-true-pos m eps chi hm hchi heps with ≡ℕ-dec eps m
... | yes refl =
  let m2pos = mul-posℕ hm hm
  in ≤ℕ-trans m2pos (≤ℕ-add-r (m * m) (chi * (m - m)))
... | no neq =
  let subPos = sub-pos-of-lt m eps (lt-of-≤-neq heps neq)
      chiPos = mul-posℕ hchi subPos
  in ≤ℕ-trans chiPos (≤ℕ-add-l (m * eps) (chi * (m - eps)))

stay-margin-pos :
  ∀ (r dA m : Nat) → (r + dA) <ℕ m → 1 ≤ℕ ((2 * m - 2 * r) - 2 * dA)
stay-margin-pos r dA m hlt =
  let twoRD<2m : (2 * (r + dA)) <ℕ (2 * m)
      twoRD<2m = double-lt (r + dA) m hlt
      distrib  : 2 * (r + dA) ≡ 2 * r + 2 * dA
      distrib  = *-distrib-l-+ 2 r dA
      sumLt    : (2 * r + 2 * dA) <ℕ (2 * m)
      sumLt    = subst (_<ℕ (2 * m)) distrib twoRD<2m
      sub1Pos  : 1 ≤ℕ (2 * m - (2 * r + 2 * dA))
      sub1Pos  = sub-pos-of-lt (2 * m) (2 * r + 2 * dA) sumLt
  in subst (1 ≤ℕ_) (sub-add-eq (2 * m) (2 * r) (2 * dA)) sub1Pos
  where
    double-lt : ∀ (a b : Nat) → a <ℕ b → (2 * a) <ℕ (2 * b)
    double-lt a (suc b') (s≤s a≤b')
      rewrite +-zero-r a | +-zero-r (suc b') | +-suc-r b' b' =
      s≤s (≤-step-r (+-mono-≤ a≤b' a≤b'))

    sub-add-eq : ∀ (x a b : Nat) → (x - (a + b)) ≡ ((x - a) - b)
    sub-add-eq x       zero    b       = cong (_- b) (-ℕ-zero x)
    sub-add-eq zero    (suc _) zero    = refl
    sub-add-eq zero    (suc _) (suc _) = refl
    sub-add-eq (suc x) (suc a) b       = sub-add-eq x a b

-- ---------------------------------------------------------------------------
-- 3. Les 10 théorèmes de bout en bout (Strate 0 Hexa-Prouvée)
-- ---------------------------------------------------------------------------

-- [1/10] circuit_coupling_operant_bridge
circuit_coupling_operant_bridge :
  ∀ (c : EngineCoupling) (d piA piC : Nat) (susp : Bool) →
    (diagToContingency (projectPerceptible c 2 piA piC susp) ≡ couplingToContingency c)
  × (quadrantContingency
       (px (projectPerceptible c (d + 2) piA piC susp))
       (py (projectPerceptible c (d + 2) piA piC susp))
     ≡ couplingToContingency c)
circuit_coupling_operant_bridge c d piA piC susp =
  part1 c piA piC susp , projectPerceptible-quadrant-eq c d piA piC susp
  where
    part1 : ∀ (c0 : EngineCoupling) (pA pC : Nat) (s0 : Bool) →
            diagToContingency (projectPerceptible c0 2 pA pC s0) ≡ couplingToContingency c0
    part1 (mkEngineCoupling zero zero) _  _  true  = refl
    part1 (mkEngineCoupling zero zero) _  _  false = refl
    part1 (mkEngineCoupling pos  zero) _  _  _     = refl
    part1 (mkEngineCoupling neg  zero) _  _  _     = refl
    part1 (mkEngineCoupling zero pos)  _  _  _     = refl
    part1 (mkEngineCoupling zero neg)  _  _  _     = refl
    part1 (mkEngineCoupling pos  pos)  pA pC _     rewrite apportionRay-d0-x pA pC = refl
    part1 (mkEngineCoupling pos  neg)  pA pC _     rewrite apportionRay-d0-x pA pC = refl
    part1 (mkEngineCoupling neg  pos)  pA pC _     rewrite apportionRay-d0-x pA pC = refl
    part1 (mkEngineCoupling neg  neg)  pA pC _     rewrite apportionRay-d0-x pA pC = refl

-- [2/10] triggerSecondaryGradient_enters_operant
triggerSecondaryGradient_enters_operant :
  ∀ (c : EngineCoupling) (newPol : Polarity) →
  isSingleEngagedB c ≡ true →
  Polarity-isEngaged newPol ≡ true →
  let c' = triggerSecondaryGradient c newPol
      p' = deployCouplingAtDepth c' 0
  in (diagToContingency (deployCouplingAtDepth c 0) ≡ nothing)
     × Σ OperantContingency (λ oc →
         (diagToContingency p' ≡ just oc)
         × (couplingToContingency c' ≡ just oc)
         × ((c ≡ mkEngineCoupling pos zero) → opEffect oc ≡ reinforcement)
         × ((c ≡ mkEngineCoupling neg zero) → opEffect oc ≡ punishment)
         × ((c ≡ mkEngineCoupling zero pos) →
             (oc ≡ mkOperantContingency reinforcement addition)
             ⊎ (oc ≡ mkOperantContingency punishment removal))
         × ((c ≡ mkEngineCoupling zero neg) →
             (oc ≡ mkOperantContingency reinforcement removal)
             ⊎ (oc ≡ mkOperantContingency punishment addition)))
triggerSecondaryGradient_enters_operant (mkEngineCoupling pos  zero) pos  _ _ =
  refl , (mkOperantContingency reinforcement addition ,,
    (refl , refl , (λ _ → refl) , (λ ()) , (λ ()) , (λ ())))
triggerSecondaryGradient_enters_operant (mkEngineCoupling pos  zero) neg  _ _ =
  refl , (mkOperantContingency reinforcement removal ,,
    (refl , refl , (λ _ → refl) , (λ ()) , (λ ()) , (λ ())))
triggerSecondaryGradient_enters_operant (mkEngineCoupling neg  zero) pos  _ _ =
  refl , (mkOperantContingency punishment removal ,,
    (refl , refl , (λ ()) , (λ _ → refl) , (λ ()) , (λ ())))
triggerSecondaryGradient_enters_operant (mkEngineCoupling neg  zero) neg  _ _ =
  refl , (mkOperantContingency punishment addition ,,
    (refl , refl , (λ ()) , (λ _ → refl) , (λ ()) , (λ ())))
triggerSecondaryGradient_enters_operant (mkEngineCoupling zero pos)  pos  _ _ =
  refl , (mkOperantContingency reinforcement addition ,,
    (refl , refl , (λ ()) , (λ ()) , (λ _ → inj₁ refl) , (λ ())))
triggerSecondaryGradient_enters_operant (mkEngineCoupling zero pos)  neg  _ _ =
  refl , (mkOperantContingency punishment removal ,,
    (refl , refl , (λ ()) , (λ ()) , (λ _ → inj₂ refl) , (λ ())))
triggerSecondaryGradient_enters_operant (mkEngineCoupling zero neg)  pos  _ _ =
  refl , (mkOperantContingency reinforcement removal ,,
    (refl , refl , (λ ()) , (λ ()) , (λ ()) , (λ _ → inj₁ refl)))
triggerSecondaryGradient_enters_operant (mkEngineCoupling zero neg)  neg  _ _ =
  refl , (mkOperantContingency punishment addition ,,
    (refl , refl , (λ ()) , (λ ()) , (λ ()) , (λ _ → inj₂ refl)))
triggerSecondaryGradient_enters_operant (mkEngineCoupling _    _)    zero _ ()
triggerSecondaryGradient_enters_operant (mkEngineCoupling zero zero) _    () _
triggerSecondaryGradient_enters_operant (mkEngineCoupling pos  pos)  _    () _
triggerSecondaryGradient_enters_operant (mkEngineCoupling pos  neg)  _    () _
triggerSecondaryGradient_enters_operant (mkEngineCoupling neg  pos)  _    () _
triggerSecondaryGradient_enters_operant (mkEngineCoupling neg  neg)  _    () _

-- [3/10] p2_markov_contagion_enters_operant_punishment
p2_markov_contagion_enters_operant_punishment :
  ∀ (p : CircuitKernelParams) →
  1 ≤ℕ chi p →
  1 ≤ℕ qPosC p →
  qPosC p <ℕ scale p →
  (rho p + deltaA p) <ℕ scale p →
  epsilon p ≤ℕ scale p →
    (1 ≤ℕ circuitWeight p (mkEngineCoupling neg zero) (mkEngineCoupling neg pos))
  × (1 ≤ℕ circuitWeight p (mkEngineCoupling neg zero) (mkEngineCoupling neg neg))
  × (couplingToContingency (mkEngineCoupling neg zero) ≡ nothing)
  × (couplingToContingency (mkEngineCoupling neg pos)  ≡ just (mkOperantContingency punishment removal))
  × (couplingToContingency (mkEngineCoupling neg neg)  ≡ just (mkOperantContingency punishment addition))
p2_markov_contagion_enters_operant_punishment p hChi hQpos hQlt hStay hEps =
  let hmPos : 1 ≤ℕ scale p
      hmPos = ≤ℕ-trans hQpos (<ℕ-to-≤ℕ hQlt)
      he2   = effectiveEps-true-pos (scale p) (epsilon p) (chi p) hmPos hChi hEps
      h2e2  = mul-posℕ {2} (s≤s z≤n) he2
      hmwA  = mul-posℕ (mul-posℕ hmPos hmPos) (stay-margin-pos (rho p) (deltaA p) (scale p) hStay)
      hmwCp = mul-posℕ h2e2 hQpos
      hmwCn = mul-posℕ h2e2 (sub-pos-of-lt (scale p) (qPosC p) hQlt)
  in mul-posℕ hmwA hmwCp
   , mul-posℕ hmwA hmwCn
   , refl
   , refl
   , refl

-- [4/10] operant_quadrant_lifting_all_strata
operant_quadrant_lifting_all_strata :
  ∀ (p : CoreAffectPoint) →
  ¬ (px p ≡ pos 0) →
  ¬ (py p ≡ pos 0) →
    Σ OperantContingency (λ oc →
      (quadrantContingency (px p) (py p) ≡ just oc)
      × ((opEffect oc ≡ reinforcement) ↔ (intPosB (px p) ≡ true))
      × ((opEffect oc ≡ punishment) ↔ (intNegB (px p) ≡ true))
      × ((opOperator oc ≡ addition) ↔ (intPosB (px p *ℤ py p) ≡ true))
      × ((opOperator oc ≡ removal) ↔ (intNegB (px p *ℤ py p) ≡ true))
      × ((computeHedonicPolarity (px p) (py p) ≡ hedPositive) ↔ (opEffect oc ≡ reinforcement))
      × ((opOperator oc ≡ addition) ↔
          ((computeEnergyRegime (px p) (py p) ≡ positiveSynergy)
           ⊎ (computeEnergyRegime (px p) (py p) ≡ negativeSynergy)))
      × ((opOperator oc ≡ removal) ↔
          ((computeEnergyRegime (px p) (py p) ≡ ergotropicCompensation)
           ⊎ (computeEnergyRegime (px p) (py p) ≡ trophotropicRelease))))
  × (∀ (q : CoreAffectPoint) → q ∈ z2DiagonalPoints →
      quadrantContingency (px q) (py q) ≡ diagToContingency q)
operant_quadrant_lifting_all_strata p hx hy = liftQuadrant p hx hy , diagAgree
  where
    liftQuadrant :
      ∀ (pt : CoreAffectPoint) → ¬ (px pt ≡ pos 0) → ¬ (py pt ≡ pos 0) →
      Σ OperantContingency (λ oc →
        (quadrantContingency (px pt) (py pt) ≡ just oc)
        × ((opEffect oc ≡ reinforcement) ↔ (intPosB (px pt) ≡ true))
        × ((opEffect oc ≡ punishment) ↔ (intNegB (px pt) ≡ true))
        × ((opOperator oc ≡ addition) ↔ (intPosB (px pt *ℤ py pt) ≡ true))
        × ((opOperator oc ≡ removal) ↔ (intNegB (px pt *ℤ py pt) ≡ true))
        × ((computeHedonicPolarity (px pt) (py pt) ≡ hedPositive) ↔ (opEffect oc ≡ reinforcement))
        × ((opOperator oc ≡ addition) ↔
            ((computeEnergyRegime (px pt) (py pt) ≡ positiveSynergy)
             ⊎ (computeEnergyRegime (px pt) (py pt) ≡ negativeSynergy)))
        × ((opOperator oc ≡ removal) ↔
            ((computeEnergyRegime (px pt) (py pt) ≡ ergotropicCompensation)
             ⊎ (computeEnergyRegime (px pt) (py pt) ≡ trophotropicRelease))))
    liftQuadrant (mkPoint (pos zero)     _              _) hx0 _   = ⊥-elim (hx0 refl)
    liftQuadrant (mkPoint _              (pos zero)     _) _   hy0 = ⊥-elim (hy0 refl)
    liftQuadrant (mkPoint (pos (suc _))  (pos (suc _))  _) _   _   =
      mkOperantContingency reinforcement addition ,,
        ( refl
        , ((λ _ → refl) , (λ _ → refl))
        , ((λ ()) , (λ ()))
        , ((λ _ → refl) , (λ _ → refl))
        , ((λ ()) , (λ ()))
        , ((λ _ → refl) , (λ _ → refl))
        , ((λ _ → inj₁ refl) , (λ _ → refl))
        , ((λ ()) , (λ { (inj₁ ()) ; (inj₂ ()) }))
        )
    liftQuadrant (mkPoint (pos (suc _))  (negsuc _)     _) _   _   =
      mkOperantContingency reinforcement removal ,,
        ( refl
        , ((λ _ → refl) , (λ _ → refl))
        , ((λ ()) , (λ ()))
        , ((λ ()) , (λ ()))
        , ((λ _ → refl) , (λ _ → refl))
        , ((λ _ → refl) , (λ _ → refl))
        , ((λ ()) , (λ { (inj₁ ()) ; (inj₂ ()) }))
        , ((λ _ → inj₂ refl) , (λ _ → refl))
        )
    liftQuadrant (mkPoint (negsuc _)     (pos (suc _))  _) _   _   =
      mkOperantContingency punishment removal ,,
        ( refl
        , ((λ ()) , (λ ()))
        , ((λ _ → refl) , (λ _ → refl))
        , ((λ ()) , (λ ()))
        , ((λ _ → refl) , (λ _ → refl))
        , ((λ ()) , (λ ()))
        , ((λ ()) , (λ { (inj₁ ()) ; (inj₂ ()) }))
        , ((λ _ → inj₁ refl) , (λ _ → refl))
        )
    liftQuadrant (mkPoint (negsuc _)     (negsuc _)     _) _   _   =
      mkOperantContingency punishment addition ,,
        ( refl
        , ((λ ()) , (λ ()))
        , ((λ _ → refl) , (λ _ → refl))
        , ((λ _ → refl) , (λ _ → refl))
        , ((λ ()) , (λ ()))
        , ((λ ()) , (λ ()))
        , ((λ _ → inj₂ refl) , (λ _ → refl))
        , ((λ ()) , (λ { (inj₁ ()) ; (inj₂ ()) }))
        )

    diagAgree :
      ∀ (q : CoreAffectPoint) → q ∈ z2DiagonalPoints →
      quadrantContingency (px q) (py q) ≡ diagToContingency q
    diagAgree .(prototypeToPoint protoDesir)  here                         = refl
    diagAgree .(prototypeToPoint protoCalme)  (there here)                 = refl
    diagAgree .(prototypeToPoint protoDegout) (there (there here))         = refl
    diagAgree .(prototypeToPoint protoColere) (there (there (there here))) = refl
    diagAgree _ (there (there (there (there ()))))

-- [5/10] operant_antagonist_invariance_all_strata
operant_antagonist_invariance_all_strata :
  ∀ (p : CoreAffectPoint) →
  ¬ (px p ≡ pos 0) →
  ¬ (py p ≡ pos 0) →
  Σ OperantContingency (λ c1 → Σ OperantContingency (λ c2 →
    (quadrantContingency (px p) (py p) ≡ just c1)
    × (quadrantContingency (px (antagonistPoint p)) (py (antagonistPoint p)) ≡ just c2)
    × ¬ (opEffect c1 ≡ opEffect c2)
    × (opOperator c1 ≡ opOperator c2)))
operant_antagonist_invariance_all_strata (mkPoint (pos zero)    _             _) hx _  = ⊥-elim (hx refl)
operant_antagonist_invariance_all_strata (mkPoint _             (pos zero)    _) _  hy = ⊥-elim (hy refl)
operant_antagonist_invariance_all_strata (mkPoint (pos (suc _)) (pos (suc _)) _) _  _  =
  mkOperantContingency reinforcement addition ,,
    (mkOperantContingency punishment addition ,, (refl , refl , (λ ()) , refl))
operant_antagonist_invariance_all_strata (mkPoint (pos (suc _)) (negsuc _)    _) _  _  =
  mkOperantContingency reinforcement removal ,,
    (mkOperantContingency punishment removal ,, (refl , refl , (λ ()) , refl))
operant_antagonist_invariance_all_strata (mkPoint (negsuc _)    (pos (suc _)) _) _  _  =
  mkOperantContingency punishment removal ,,
    (mkOperantContingency reinforcement removal ,, (refl , refl , (λ ()) , refl))
operant_antagonist_invariance_all_strata (mkPoint (negsuc _)    (negsuc _)    _) _  _  =
  mkOperantContingency punishment addition ,,
    (mkOperantContingency reinforcement addition ,, (refl , refl , (λ ()) , refl))

-- [6/10] depthKernel_preserves_operant_quadrant
private
  if-pos-snd : ∀ (b : Bool) {t : Nat} → 1 ≤ℕ (if b then t else 0) → (b ≡ true) × (1 ≤ℕ t)
  if-pos-snd true  h = refl , h
  if-pos-snd false ()

  and5-4-5 : ∀ (b1 b2 b3 b4 b5 : Bool) →
             (b1 ∧b b2 ∧b b3 ∧b b4 ∧b b5) ≡ true → (b4 ≡ true) × (b5 ≡ true)
  and5-4-5 true  true  true  true  true  _  = refl , refl
  and5-4-5 false _     _     _     _     ()
  and5-4-5 true  false _     _     _     ()
  and5-4-5 true  true  false _     _     ()
  and5-4-5 true  true  true  false _     ()
  and5-4-5 true  true  true  true  false ()

  depthKernelInner : CoreAffectPoint → CoreAffectPoint → Nat
  depthKernelInner p q =
    let px' = px p; py' = py p; pz' = pz p
        qx' = px q; qy' = py q
        ax  = absNat px'; ay = absNat py'
        bx  = absNat qx'; by = absNat qy'
    in if isCentralB q then
         (if isCentralB p then 1 else 0)
       else if isCentralB p then
         (if pz' == 1 then 1 else 0)
       else if isZeroℤ px' ∨b isZeroℤ py' then
         (if (isZeroℤ px' ∨b not (isZeroℤ qx')) ∧b (isZeroℤ py' ∨b not (isZeroℤ qy')) then
            (if isZeroℤ qx' ∨b isZeroℤ qy' then 1
             else if bx == by then 2 else 0)
          else 0)
       else
         (if not (isZeroℤ qx') ∧b not (isZeroℤ qy') ∧b leNatB ax bx ∧b leNatB ay by then
            (if (ax == ay) ∧b (bx == by) then 2 else 1)
          else 0)

  preservesSigns :
    ∀ (x1 y1 : Int) (pz' : Nat) (x2 y2 : Int) (qz' : Nat) →
    ¬ (x1 ≡ pos 0) → ¬ (y1 ≡ pos 0) →
    sameSignOrZeroB x1 x2 ≡ true →
    sameSignOrZeroB y1 y2 ≡ true →
    1 ≤ℕ depthKernelInner (mkPoint x1 y1 pz') (mkPoint x2 y2 qz') →
    ¬ (x2 ≡ pos 0) × ¬ (y2 ≡ pos 0) × (quadrantContingency x2 y2 ≡ quadrantContingency x1 y1)
  preservesSigns (pos zero)    _             _   _             _             _   hx1 _   _   _   _  = ⊥-elim (hx1 refl)
  preservesSigns _             (pos zero)    _   _             _             _   _   hy1 _   _   _  = ⊥-elim (hy1 refl)
  -- x2 = 0 : depthKernelInner reduces to 0
  preservesSigns (pos (suc _)) (pos (suc _)) _   (pos zero)    (pos zero)    _   _   _   _   _   ()
  preservesSigns (pos (suc _)) (pos (suc _)) _   (pos zero)    (pos (suc _)) _   _   _   _   _   ()
  preservesSigns (pos (suc _)) (pos (suc _)) _   (pos zero)    (negsuc _)    _   _   _   _   _   ()
  preservesSigns (pos (suc _)) (negsuc _)    _   (pos zero)    (pos zero)    _   _   _   _   _   ()
  preservesSigns (pos (suc _)) (negsuc _)    _   (pos zero)    (pos (suc _)) _   _   _   _   _   ()
  preservesSigns (pos (suc _)) (negsuc _)    _   (pos zero)    (negsuc _)    _   _   _   _   _   ()
  preservesSigns (negsuc _)    (pos (suc _)) _   (pos zero)    (pos zero)    _   _   _   _   _   ()
  preservesSigns (negsuc _)    (pos (suc _)) _   (pos zero)    (pos (suc _)) _   _   _   _   _   ()
  preservesSigns (negsuc _)    (pos (suc _)) _   (pos zero)    (negsuc _)    _   _   _   _   _   ()
  preservesSigns (negsuc _)    (negsuc _)    _   (pos zero)    (pos zero)    _   _   _   _   _   ()
  preservesSigns (negsuc _)    (negsuc _)    _   (pos zero)    (pos (suc _)) _   _   _   _   _   ()
  preservesSigns (negsuc _)    (negsuc _)    _   (pos zero)    (negsuc _)    _   _   _   _   _   ()
  -- y2 = 0 (x2 != 0) : depthKernelInner reduces to 0
  preservesSigns (pos (suc _)) (pos (suc _)) _   (pos (suc _)) (pos zero)    _   _   _   _   _   ()
  preservesSigns (pos (suc _)) (pos (suc _)) _   (negsuc _)    (pos zero)    _   _   _   _   _   ()
  preservesSigns (pos (suc _)) (negsuc _)    _   (pos (suc _)) (pos zero)    _   _   _   _   _   ()
  preservesSigns (pos (suc _)) (negsuc _)    _   (negsuc _)    (pos zero)    _   _   _   _   _   ()
  preservesSigns (negsuc _)    (pos (suc _)) _   (pos (suc _)) (pos zero)    _   _   _   _   _   ()
  preservesSigns (negsuc _)    (pos (suc _)) _   (negsuc _)    (pos zero)    _   _   _   _   _   ()
  preservesSigns (negsuc _)    (negsuc _)    _   (pos (suc _)) (pos zero)    _   _   _   _   _   ()
  preservesSigns (negsuc _)    (negsuc _)    _   (negsuc _)    (pos zero)    _   _   _   _   _   ()
  -- Opposite signs refute sameSignOrZeroB = true
  preservesSigns (pos (suc _)) (pos (suc _)) _   (pos (suc _)) (negsuc _)    _   _   _   _   ()  _
  preservesSigns (pos (suc _)) (pos (suc _)) _   (negsuc _)    _             _   _   _   ()  _   _
  preservesSigns (pos (suc _)) (negsuc _)    _   (pos (suc _)) (pos (suc _)) _   _   _   _   ()  _
  preservesSigns (pos (suc _)) (negsuc _)    _   (negsuc _)    _             _   _   _   ()  _   _
  preservesSigns (negsuc _)    (pos (suc _)) _   (pos (suc _)) _             _   _   _   ()  _   _
  preservesSigns (negsuc _)    (pos (suc _)) _   (negsuc _)    (negsuc _)    _   _   _   _   ()  _
  preservesSigns (negsuc _)    (negsuc _)    _   (pos (suc _)) _             _   _   _   ()  _   _
  preservesSigns (negsuc _)    (negsuc _)    _   (negsuc _)    (pos (suc _)) _   _   _   _   ()  _
  -- Identical non-zero signs : quadrant preserved!
  preservesSigns (pos (suc _)) (pos (suc _)) _   (pos (suc _)) (pos (suc _)) _   _   _   _   _   _  = (λ ()) , (λ ()) , refl
  preservesSigns (pos (suc _)) (negsuc _)    _   (pos (suc _)) (negsuc _)    _   _   _   _   _   _  = (λ ()) , (λ ()) , refl
  preservesSigns (negsuc _)    (pos (suc _)) _   (negsuc _)    (pos (suc _)) _   _   _   _   _   _  = (λ ()) , (λ ()) , refl
  preservesSigns (negsuc _)    (negsuc _)    _   (negsuc _)    (negsuc _)    _   _   _   _   _   _  = (λ ()) , (λ ()) , refl

depthKernel_preserves_operant_quadrant :
  (∀ (p q : CoreAffectPoint) →
    ¬ (px p ≡ pos 0) → ¬ (py p ≡ pos 0) →
    1 ≤ℕ canonicalDepthWeight p q →
    ¬ (px q ≡ pos 0)
    × ¬ (py q ≡ pos 0)
    × (quadrantContingency (px q) (py q) ≡ quadrantContingency (px p) (py p)))
  × (1 ≤ℕ canonicalDepthWeight (mkPoint (pos 2)    (pos 0)    2) (mkPoint (pos 2)    (pos 2)    3))
  × (1 ≤ℕ canonicalDepthWeight (mkPoint (pos 2)    (pos 0)    2) (mkPoint (pos 2)    (negsuc 1) 3))
  × (1 ≤ℕ canonicalDepthWeight (mkPoint (negsuc 1) (pos 0)    2) (mkPoint (negsuc 1) (pos 2)    3))
  × (1 ≤ℕ canonicalDepthWeight (mkPoint (negsuc 1) (pos 0)    2) (mkPoint (negsuc 1) (negsuc 1) 3))
  × (1 ≤ℕ canonicalDepthWeight (mkPoint (pos 0)    (pos 2)    2) (mkPoint (pos 2)    (pos 2)    3))
  × (1 ≤ℕ canonicalDepthWeight (mkPoint (pos 0)    (pos 2)    2) (mkPoint (negsuc 1) (pos 2)    3))
  × (1 ≤ℕ canonicalDepthWeight (mkPoint (pos 0)    (negsuc 1) 2) (mkPoint (pos 2)    (negsuc 1) 3))
  × (1 ≤ℕ canonicalDepthWeight (mkPoint (pos 0)    (negsuc 1) 2) (mkPoint (negsuc 1) (negsuc 1) 3))
depthKernel_preserves_operant_quadrant =
  preserves ,
  s≤s z≤n , s≤s z≤n , s≤s z≤n , s≤s z≤n ,
  s≤s z≤n , s≤s z≤n , s≤s z≤n , s≤s z≤n
  where
    preserves :
      ∀ (p q : CoreAffectPoint) →
      ¬ (px p ≡ pos 0) → ¬ (py p ≡ pos 0) →
      1 ≤ℕ canonicalDepthWeight p q →
      ¬ (px q ≡ pos 0)
      × ¬ (py q ≡ pos 0)
      × (quadrantContingency (px q) (py q) ≡ quadrantContingency (px p) (py p))
    preserves p@(mkPoint px' py' pz') q@(mkPoint qx' qy' qz') hx hy hw =
      let gBool = isValidCoreAffectB p ∧b isValidCoreAffectB q
                  ∧b (qz' == suc pz') ∧b sameSignOrZeroB px' qx' ∧b sameSignOrZeroB py' qy'
          split = if-pos-snd gBool hw
          signs = and5-4-5 (isValidCoreAffectB p) (isValidCoreAffectB q) (qz' == suc pz')
                    (sameSignOrZeroB px' qx') (sameSignOrZeroB py' qy') (fst split)
      in preservesSigns px' py' pz' qx' qy' qz' hx hy (fst signs) (snd signs) (snd split)

-- [7/10] operant_lineages_reach_z7_transcendentals
private
  defaultLexiconEntry : LexiconEntry
  defaultLexiconEntry = mkEntry "Point de Veille" (pos 0) (pos 0) 0

operant_lineages_reach_z7_transcendentals :
  -- R+ : Désir (1,1,2) -> ... -> Sublimation (6,6,7)
  (  (canonicalDepthWeight (mkPoint (pos 1) (pos 1) 2) (mkPoint (pos 2) (pos 2) 3) ≡ 2)
   × (canonicalDepthWeight (mkPoint (pos 2) (pos 2) 3) (mkPoint (pos 3) (pos 3) 4) ≡ 2)
   × (canonicalDepthWeight (mkPoint (pos 3) (pos 3) 4) (mkPoint (pos 4) (pos 4) 5) ≡ 2)
   × (canonicalDepthWeight (mkPoint (pos 4) (pos 4) 5) (mkPoint (pos 5) (pos 5) 6) ≡ 2)
   × (canonicalDepthWeight (mkPoint (pos 5) (pos 5) 6) (mkPoint (pos 6) (pos 6) 7) ≡ 2)
   × (classifyOperantRole (mkPoint (pos 6) (pos 6) 7) ≡ rolePureOperant (mkOperantContingency reinforcement addition))
   × (classifyStratum 7 ≡ z7_sentimentsTranscendants)
   × (classifyTaxonomicGroup (mkPoint (pos 6) (pos 6) 7) ≡ groupeDesir)
   × (classifySubsector (pos 6) (pos 6) ≡ diagonalDesire)
   × (mkEntry "Sublimation" (pos 6) (pos 6) 7 ∈ all176Entries))
  -- R- : Calme (1,-1,2) -> ... -> Impassibilité (6,-6,7)
  × ((canonicalDepthWeight (mkPoint (pos 1) (negsuc 0) 2) (mkPoint (pos 2) (negsuc 1) 3) ≡ 2)
   × (canonicalDepthWeight (mkPoint (pos 2) (negsuc 1) 3) (mkPoint (pos 3) (negsuc 2) 4) ≡ 2)
   × (canonicalDepthWeight (mkPoint (pos 3) (negsuc 2) 4) (mkPoint (pos 4) (negsuc 3) 5) ≡ 2)
   × (canonicalDepthWeight (mkPoint (pos 4) (negsuc 3) 5) (mkPoint (pos 5) (negsuc 4) 6) ≡ 2)
   × (canonicalDepthWeight (mkPoint (pos 5) (negsuc 4) 6) (mkPoint (pos 6) (negsuc 5) 7) ≡ 2)
   × (classifyOperantRole (mkPoint (pos 6) (negsuc 5) 7) ≡ rolePureOperant (mkOperantContingency reinforcement removal))
   × (classifyStratum 7 ≡ z7_sentimentsTranscendants)
   × (classifyTaxonomicGroup (mkPoint (pos 6) (negsuc 5) 7) ≡ groupeCalme)
   × (classifySubsector (pos 6) (negsuc 5) ≡ diagonalCalm)
   × (mkEntry "Impassibilité" (pos 6) (negsuc 5) 7 ∈ all176Entries))
  -- P+ : Dégoût (-1,-1,2) -> ... -> Dissolution (-6,-6,7)
  × ((canonicalDepthWeight (mkPoint (negsuc 0) (negsuc 0) 2) (mkPoint (negsuc 1) (negsuc 1) 3) ≡ 2)
   × (canonicalDepthWeight (mkPoint (negsuc 1) (negsuc 1) 3) (mkPoint (negsuc 2) (negsuc 2) 4) ≡ 2)
   × (canonicalDepthWeight (mkPoint (negsuc 2) (negsuc 2) 4) (mkPoint (negsuc 3) (negsuc 3) 5) ≡ 2)
   × (canonicalDepthWeight (mkPoint (negsuc 3) (negsuc 3) 5) (mkPoint (negsuc 4) (negsuc 4) 6) ≡ 2)
   × (canonicalDepthWeight (mkPoint (negsuc 4) (negsuc 4) 6) (mkPoint (negsuc 5) (negsuc 5) 7) ≡ 2)
   × (classifyOperantRole (mkPoint (negsuc 5) (negsuc 5) 7) ≡ rolePureOperant (mkOperantContingency punishment addition))
   × (classifyStratum 7 ≡ z7_sentimentsTranscendants)
   × (classifyTaxonomicGroup (mkPoint (negsuc 5) (negsuc 5) 7) ≡ groupeDegout)
   × (classifySubsector (negsuc 5) (negsuc 5) ≡ diagonalDisgust)
   × (mkEntry "Dissolution" (negsuc 5) (negsuc 5) 7 ∈ all176Entries))
  -- P- : Colère (-1,1,2) -> ... -> Rage (-6,6,7)
  × ((canonicalDepthWeight (mkPoint (negsuc 0) (pos 1) 2) (mkPoint (negsuc 1) (pos 2) 3) ≡ 2)
   × (canonicalDepthWeight (mkPoint (negsuc 1) (pos 2) 3) (mkPoint (negsuc 2) (pos 3) 4) ≡ 2)
   × (canonicalDepthWeight (mkPoint (negsuc 2) (pos 3) 4) (mkPoint (negsuc 3) (pos 4) 5) ≡ 2)
   × (canonicalDepthWeight (mkPoint (negsuc 3) (pos 4) 5) (mkPoint (negsuc 4) (pos 5) 6) ≡ 2)
   × (canonicalDepthWeight (mkPoint (negsuc 4) (pos 5) 6) (mkPoint (negsuc 5) (pos 6) 7) ≡ 2)
   × (classifyOperantRole (mkPoint (negsuc 5) (pos 6) 7) ≡ rolePureOperant (mkOperantContingency punishment removal))
   × (classifyStratum 7 ≡ z7_sentimentsTranscendants)
   × (classifyTaxonomicGroup (mkPoint (negsuc 5) (pos 6) 7) ≡ groupeColere)
   × (classifySubsector (negsuc 5) (pos 6) ≡ diagonalAnger)
   × (mkEntry "Rage" (negsuc 5) (pos 6) 7 ∈ all176Entries))
operant_lineages_reach_z7_transcendentals =
    (refl , refl , refl , refl , refl , refl , refl , refl , refl , nth-∈ defaultLexiconEntry 174 all176Entries refl)
  , (refl , refl , refl , refl , refl , refl , refl , refl , refl , nth-∈ defaultLexiconEntry 173 all176Entries refl)
  , (refl , refl , refl , refl , refl , refl , refl , refl , refl , nth-∈ defaultLexiconEntry 175 all176Entries refl)
  , (refl , refl , refl , refl , refl , refl , refl , refl , refl , nth-∈ defaultLexiconEntry 172 all176Entries refl)

-- [8/10] unified_circuit_to_taxonomy_coherence
unified_circuit-to-taxonomy_coherence :
  ∀ (p : UnifiedDynamicsParams) (c : EngineCoupling)
    (z : Nat) (rhoHat kappaHat : Int) (susp : Bool) →
  let ts = evaluateUnifiedTaxonomy p c z rhoHat kappaHat susp
      cp = core (matrix ts)
      ap = antagonist (matrix ts)
  in IsValidCoreAffect cp
     × IsValidCoreAffect ap
     × (stratum ts ≡ classifyStratum (pz cp))
     × (matchesTaxonomicGroupB cp (group ts) ≡ true)
     × (Subsector-toTaxonomicGroup (subsector ts) ≡ group ts)
     × (Subsector-toHedonicPolarity (subsector ts) ≡ valence (matrix ts))
     × (2 ≤ℕ z → quadrantContingency (px cp) (py cp) ≡ couplingToContingency c)
     × (leNatB z 7 ≡ true →
         (cp ∈ map entryPoint all176Entries) × (ap ∈ map entryPoint all176Entries))
unified_circuit-to-taxonomy_coherence p c z rhoHat kappaHat susp =
  let cp  = projectUnifiedState p c z rhoHat kappaHat susp
      sh  = precisionShares p rhoHat kappaHat c
      hvc = projectUnifiedState_valid p c z rhoHat kappaHat susp
      hva = antagonistPoint_preserves_validity cp hvc
  in hvc
   , hva
   , refl
   , classifyTaxonomicGroup_correct cp
   , classifySubsector_refines_group cp
   , classifySubsector_determines_valence (px cp) (py cp)
   , quadGe2 z
   , (λ hz7 →
       let hcz = projectPerceptible-le7 c z (fst sh) (snd sh) susp hz7
           haz = subst (λ zv → leNatB zv 7 ≡ true) (sym (antagonist-pz cp)) hcz
       in all176Entries_spatial_completeness cp hcz hvc
        , all176Entries_spatial_completeness (antagonistPoint cp) haz hva)
  where
    sh = precisionShares p rhoHat kappaHat c
    quadGe2 : ∀ (zv : Nat) → 2 ≤ℕ zv →
              quadrantContingency
                (px (projectPerceptible c zv (fst sh) (snd sh) susp))
                (py (projectPerceptible c zv (fst sh) (snd sh) susp))
              ≡ couplingToContingency c
    quadGe2 (suc (suc d)) (s≤s (s≤s _)) = projectPerceptible-quadrant-suc2 c d (fst sh) (snd sh) susp

-- [9/10] circularCycle_to_taxonomy_and_lexicon_coherence
private
  op3-valid : ∀ (s : CircularCircuitState) → IsValidCoreAffect (op3_crossingI_perceptible s)
  op3-valid s =
    let c    = mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s)
        att  = CircularCircuitState.attentional s
        susp = SubjectiveHiddenState.descendingSuspension (subjectiveHidden s)
        z    = if isGlobalNeutralityB c then (if susp then persistenceDepth att + 2 else 0)
               else if not (Attentional-isEngagedB att) then (if susp then persistenceDepth att + 2 else 1)
               else persistenceDepth att + 2
    in projectPerceptible_valid c z (precisionA att) (precisionC att) susp

  op3-engaged-quadrant :
    ∀ (s : CircularCircuitState) →
    Attentional-isEngagedB (CircularCircuitState.attentional s) ≡ true →
    quadrantContingency (px (op3_crossingI_perceptible s)) (py (op3_crossingI_perceptible s))
    ≡ couplingToContingency (mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s))
  op3-engaged-quadrant s hEng =
    aux (isGlobalNeutralityB c) (Attentional-isEngagedB att) refl hEng
    where
      c    = mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s)
      att  = CircularCircuitState.attentional s
      susp = SubjectiveHiddenState.descendingSuspension (subjectiveHidden s)
      aux : ∀ (b1 b2 : Bool) → isGlobalNeutralityB c ≡ b1 → b2 ≡ true →
            let z = if b1 then (if susp then persistenceDepth att + 2 else 0)
                    else if not b2 then (if susp then persistenceDepth att + 2 else 1)
                    else persistenceDepth att + 2
            in quadrantContingency
                 (px (projectPerceptible c z (precisionA att) (precisionC att) susp))
                 (py (projectPerceptible c z (precisionA att) (precisionC att) susp))
               ≡ couplingToContingency c
      aux true  _     hNeut _   =
        let zv = if susp then persistenceDepth att + 2 else 0
        in trans (projectPerceptible-neutral-quadrant c zv (precisionA att) (precisionC att) susp hNeut)
                 (sym (couplingToContingency-neutral c hNeut))
      aux false true  _     _   =
        projectPerceptible-quadrant-eq c (persistenceDepth att) (precisionA att) (precisionC att) susp
      aux false false _     ()

  op3-z-le7 :
    ∀ (s : CircularCircuitState) →
    leNatB (persistenceDepth (CircularCircuitState.attentional s)) 5 ≡ true →
    leNatB (pz (op3_crossingI_perceptible s)) 7 ≡ true
  op3-z-le7 s hd5 =
    projectPerceptible-le7 c
      (zChoice (isGlobalNeutralityB c) (not (Attentional-isEngagedB att)) susp)
      (precisionA att) (precisionC att) susp
      (zBound (isGlobalNeutralityB c) (not (Attentional-isEngagedB att)) susp)
    where
      c    = mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s)
      att  = CircularCircuitState.attentional s
      susp = SubjectiveHiddenState.descendingSuspension (subjectiveHidden s)
      zChoice : Bool → Bool → Bool → Nat
      zChoice b1 b2 b3 =
        if b1 then (if b3 then persistenceDepth att + 2 else 0)
        else if b2 then (if b3 then persistenceDepth att + 2 else 1)
        else persistenceDepth att + 2
      zBound : ∀ (b1 b2 b3 : Bool) → leNatB (zChoice b1 b2 b3) 7 ≡ true
      zBound true  _     true  = le5-add2-le7 (persistenceDepth att) hd5
      zBound true  _     false = refl
      zBound false true  true  = le5-add2-le7 (persistenceDepth att) hd5
      zBound false true  false = refl
      zBound false false _     = le5-add2-le7 (persistenceDepth att) hd5

circularCycle-to-taxonomy_and_lexicon_coherence :
  ∀ (s : CircularCircuitState) →
  let ts = evaluateCircularTaxonomy s
      cp = core (matrix ts)
      ap = antagonist (matrix ts)
      c  = mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s)
  in IsValidCoreAffect cp
     × IsValidCoreAffect ap
     × (matchesTaxonomicGroupB cp (group ts) ≡ true)
     × (Subsector-toTaxonomicGroup (subsector ts) ≡ group ts)
     × (Subsector-toHedonicPolarity (subsector ts) ≡ valence (matrix ts))
     × (Attentional-isEngagedB (CircularCircuitState.attentional s) ≡ true →
         quadrantContingency (px cp) (py cp) ≡ couplingToContingency c)
     × (leNatB (persistenceDepth (CircularCircuitState.attentional s)) 5 ≡ true →
         (leNatB (pz cp) 7 ≡ true)
         × (cp ∈ map entryPoint all176Entries)
         × (ap ∈ map entryPoint all176Entries))
circularCycle-to-taxonomy_and_lexicon_coherence s =
  let cp  = op3_crossingI_perceptible s
      hvc = op3-valid s
      hva = antagonistPoint_preserves_validity cp hvc
  in hvc
   , hva
   , classifyTaxonomicGroup_correct cp
   , classifySubsector_refines_group cp
   , classifySubsector_determines_valence (px cp) (py cp)
   , op3-engaged-quadrant s
   , (λ hd5 →
       let hcz = op3-z-le7 s hd5
           haz = subst (λ zv → leNatB zv 7 ≡ true) (sym (antagonist-pz cp)) hcz
       in hcz
        , all176Entries_spatial_completeness cp hcz hvc
        , all176Entries_spatial_completeness (antagonistPoint cp) haz hva)

-- [10/10] full_end_to_end_lexicon_resolution
full_end-to-end_lexicon_resolution :
  ∀ (s : PredictiveEngineState) →
  leNatB (pz (projectToCoreAffect s)) 7 ≡ true →
  let ts = runCartograffectPipeline s
      cp = core (matrix ts)
      ap = antagonist (matrix ts)
  in IsCoherentTerminalState s ts
     × (∀ (ts' : TaxonomicState) → IsCoherentTerminalState s ts' → ts' ≡ ts)
     × Σ LexiconEntry (λ e →
         (e ∈ all176Entries)
         × (entryPoint e ≡ cp)
         × (∀ (e' : LexiconEntry) → e' ∈ all176Entries → entryPoint e' ≡ cp → e' ≡ e))
     × Σ LexiconEntry (λ ae →
         (ae ∈ all176Entries)
         × (entryPoint ae ≡ ap)
         × (∀ (ae' : LexiconEntry) → ae' ∈ all176Entries → entryPoint ae' ≡ ap → ae' ≡ ae))
     × (¬ (px cp ≡ pos 0) → ¬ (py cp ≡ pos 0) →
         Σ OperantContingency (λ c1 → Σ OperantContingency (λ c2 →
           (quadrantContingency (px cp) (py cp) ≡ just c1)
           × (quadrantContingency (px ap) (py ap) ≡ just c2)
           × ¬ (opEffect c1 ≡ opEffect c2)
           × (opOperator c1 ≡ opOperator c2))))
full_end-to-end_lexicon_resolution s hz7 =
  let cp    = projectToCoreAffect s
      ap    = antagonistPoint cp
      hvc   = engine_induces_valid_core_affect s
      hva   = antagonistPoint_preserves_validity cp hvc
      hapZ7 = subst (λ zv → leNatB zv 7 ≡ true) (sym (antagonist-pz cp)) hz7
      resE  = all176Entries_lookup_by_point cp hz7 hvc
      e     = proj₁ resE
      e∈    = fst (proj₂ resE)
      ePt   = snd (proj₂ resE)
      resAE = all176Entries_lookup_by_point ap hapZ7 hva
      ae    = proj₁ resAE
      ae∈   = fst (proj₂ resAE)
      aePt  = snd (proj₂ resAE)
  in runCartograffectPipeline_coherent s
   , isCoherentTerminalState_unique s
   , (e ,, (e∈ , ePt , (λ e' e'∈ e'Pt → all176Entries_point_injective e'∈ e∈ (trans e'Pt (sym ePt)))))
   , (ae ,, (ae∈ , aePt , (λ ae' ae'∈ ae'Pt → all176Entries_point_injective ae'∈ ae∈ (trans ae'Pt (sym aePt)))))
   , operant_antagonist_invariance_all_strata cp
