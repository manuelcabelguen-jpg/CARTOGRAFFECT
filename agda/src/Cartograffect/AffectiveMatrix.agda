{-# OPTIONS --safe --without-K #-}
-- Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
-- SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
-- Author: Manuel Cabelguen
--
-- Module 03 : AffectiveMatrix (Agda 2.9.0, --safe --without-K)

module Cartograffect.AffectiveMatrix where

open import Cartograffect.Prelude
open import Cartograffect.PredictiveEngine
open import Cartograffect.CoreAffect

-- ---------------------------------------------------------------------------
-- 1. Types phénoménologiques de la Matrice Affective
-- ---------------------------------------------------------------------------
data LivedExpectationPole : Set where
  epistemicCharge    : LivedExpectationPole
  epistemicNeutral   : LivedExpectationPole
  epistemicDischarge : LivedExpectationPole

data LivedControlPole : Set where
  pragmaticCharge    : LivedControlPole
  pragmaticNeutral   : LivedControlPole
  pragmaticDischarge : LivedControlPole

data EnergyRegime : Set where
  neutralBasal           : EnergyRegime
  axialPure              : EnergyRegime
  positiveSynergy        : EnergyRegime
  negativeSynergy        : EnergyRegime
  ergotropicCompensation : EnergyRegime
  trophotropicRelease    : EnergyRegime

data HedonicPolarity : Set where
  hedPositive : HedonicPolarity
  hedNegative : HedonicPolarity
  hedNeutral  : HedonicPolarity

data PhenomenologicalActivation : Set where
  basalWakefulness   : PhenomenologicalActivation
  ascendingRupture   : PhenomenologicalActivation
  operatorSuspension : PhenomenologicalActivation
  lowInhibition      : PhenomenologicalActivation
  epistemicVigilance : PhenomenologicalActivation
  highMobilization   : PhenomenologicalActivation

record PhenomenologicalMapping : Set where
  constructor mkPhenomenologicalMapping
  field
    expectationFn : Int → LivedExpectationPole
    controlFn     : Int → LivedControlPole
    valenceFn     : Int → Int → HedonicPolarity
    activationFn  : CoreAffectPoint → PhenomenologicalActivation

open PhenomenologicalMapping public

record AffectiveMatrixState : Set where
  constructor mkAffectiveMatrixState
  field
    core            : CoreAffectPoint
    expectationPole : LivedExpectationPole
    controlPole     : LivedControlPole
    energyRegime    : EnergyRegime
    valence         : HedonicPolarity
    activation      : PhenomenologicalActivation
    antagonist      : CoreAffectPoint

open AffectiveMatrixState public

-- ---------------------------------------------------------------------------
-- 2. Opérateurs canoniques, valence, antagoniste et évaluation R3
-- ---------------------------------------------------------------------------
HedonicPolarity-invert : HedonicPolarity → HedonicPolarity
HedonicPolarity-invert hedPositive = hedNegative
HedonicPolarity-invert hedNegative = hedPositive
HedonicPolarity-invert hedNeutral  = hedNeutral

computeHedonicPolarity : Int → Int → HedonicPolarity
computeHedonicPolarity (pos (suc _)) _             = hedPositive
computeHedonicPolarity (negsuc _)    _             = hedNegative
computeHedonicPolarity (pos zero)    (pos (suc _)) = hedPositive
computeHedonicPolarity (pos zero)    (negsuc _)    = hedNegative
computeHedonicPolarity (pos zero)    (pos zero)    = hedNeutral

transduceExpectation : Int → LivedExpectationPole
transduceExpectation (negsuc _)    = epistemicCharge
transduceExpectation (pos (suc _)) = epistemicDischarge
transduceExpectation (pos zero)    = epistemicNeutral

transduceControl : Int → LivedControlPole
transduceControl (negsuc _)    = pragmaticCharge
transduceControl (pos (suc _)) = pragmaticDischarge
transduceControl (pos zero)    = pragmaticNeutral

computeEnergyRegime : Int → Int → EnergyRegime
computeEnergyRegime (pos zero)    (pos zero)    = neutralBasal
computeEnergyRegime (pos zero)    (pos (suc _)) = axialPure
computeEnergyRegime (pos zero)    (negsuc _)    = axialPure
computeEnergyRegime (pos (suc _)) (pos zero)    = axialPure
computeEnergyRegime (negsuc _)    (pos zero)    = axialPure
computeEnergyRegime (pos (suc _)) (pos (suc _)) = positiveSynergy
computeEnergyRegime (negsuc _)    (negsuc _)    = negativeSynergy
computeEnergyRegime (negsuc _)    (pos (suc _)) = ergotropicCompensation
computeEnergyRegime (pos (suc _)) (negsuc _)    = trophotropicRelease

computeActivation : CoreAffectPoint → PhenomenologicalActivation
computeActivation (mkPoint (pos zero) (pos zero) zero)          = basalWakefulness
computeActivation (mkPoint (pos zero) (pos zero) (suc zero))    = ascendingRupture
computeActivation (mkPoint (pos zero) (pos zero) (suc (suc _))) = operatorSuspension
computeActivation (mkPoint _          (pos (suc _)) _)          = highMobilization
computeActivation (mkPoint _          (negsuc _)    _)          = lowInhibition
computeActivation (mkPoint _          (pos zero)    _)          = epistemicVigilance

canonicalMapping : PhenomenologicalMapping
canonicalMapping =
  mkPhenomenologicalMapping
    transduceExpectation
    transduceControl
    computeHedonicPolarity
    computeActivation

intSign : Int → Int
intSign (pos zero)    = pos 0
intSign (pos (suc _)) = pos 1
intSign (negsuc _)    = negsuc 0

antagonistPoint : CoreAffectPoint → CoreAffectPoint
antagonistPoint (mkPoint (pos zero)     (pos zero)     z) = mkPoint (pos 0)        (pos 0)        z
antagonistPoint (mkPoint (pos (suc ax)) (pos zero)     z) = mkPoint (negsuc ax)    (pos 0)        z
antagonistPoint (mkPoint (negsuc ax)    (pos zero)     z) = mkPoint (pos (suc ax)) (pos 0)        z
antagonistPoint (mkPoint (pos zero)     (pos (suc ay)) z) = mkPoint (pos 0)        (negsuc ay)    z
antagonistPoint (mkPoint (pos zero)     (negsuc ay)    z) = mkPoint (pos 0)        (pos (suc ay)) z
antagonistPoint (mkPoint (pos (suc ax)) (pos (suc ay)) z) = mkPoint (negsuc ay)    (negsuc ax)    z
antagonistPoint (mkPoint (negsuc ax)    (negsuc ay)    z) = mkPoint (pos (suc ay)) (pos (suc ax)) z
antagonistPoint (mkPoint (pos (suc ax)) (negsuc ay)    z) = mkPoint (negsuc ay)    (pos (suc ax)) z
antagonistPoint (mkPoint (negsuc ax)    (pos (suc ay)) z) = mkPoint (pos (suc ay)) (negsuc ax)    z

transferUnitYtoX : CoreAffectPoint → CoreAffectPoint
transferUnitYtoX (mkPoint (pos ax) (pos (suc ay)) z) = mkPoint (pos (suc ax)) (pos ay) z
transferUnitYtoX p                                   = p

evaluateMatrix : CoreAffectPoint → PhenomenologicalMapping → AffectiveMatrixState
evaluateMatrix p m =
  mkAffectiveMatrixState
    p
    (expectationFn m (px p))
    (controlFn m (py p))
    (computeEnergyRegime (px p) (py p))
    (valenceFn m (px p) (py p))
    (activationFn m p)
    (antagonistPoint p)

-- ---------------------------------------------------------------------------
-- 3. Lemmes auxiliaires sur l'antagoniste et ApportionRay
-- ---------------------------------------------------------------------------
antagonist-isCentral : ∀ (p : CoreAffectPoint) → isCentralB (antagonistPoint p) ≡ isCentralB p
antagonist-isCentral (mkPoint (pos zero)     (pos zero)     _) = refl
antagonist-isCentral (mkPoint (pos (suc _))  (pos zero)     _) = refl
antagonist-isCentral (mkPoint (negsuc _)     (pos zero)     _) = refl
antagonist-isCentral (mkPoint (pos zero)     (pos (suc _))  _) = refl
antagonist-isCentral (mkPoint (pos zero)     (negsuc _)     _) = refl
antagonist-isCentral (mkPoint (pos (suc _))  (pos (suc _))  _) = refl
antagonist-isCentral (mkPoint (negsuc _)     (negsuc _)     _) = refl
antagonist-isCentral (mkPoint (pos (suc _))  (negsuc _)     _) = refl
antagonist-isCentral (mkPoint (negsuc _)     (pos (suc _))  _) = refl

antagonist-pz : ∀ (p : CoreAffectPoint) → pz (antagonistPoint p) ≡ pz p
antagonist-pz (mkPoint (pos zero)     (pos zero)     _) = refl
antagonist-pz (mkPoint (pos (suc _))  (pos zero)     _) = refl
antagonist-pz (mkPoint (negsuc _)     (pos zero)     _) = refl
antagonist-pz (mkPoint (pos zero)     (pos (suc _))  _) = refl
antagonist-pz (mkPoint (pos zero)     (negsuc _)     _) = refl
antagonist-pz (mkPoint (pos (suc _))  (pos (suc _))  _) = refl
antagonist-pz (mkPoint (negsuc _)     (negsuc _)     _) = refl
antagonist-pz (mkPoint (pos (suc _))  (negsuc _)     _) = refl
antagonist-pz (mkPoint (negsuc _)     (pos (suc _))  _) = refl

antagonist-displacementSum :
  ∀ (p : CoreAffectPoint) → displacementSum (antagonistPoint p) ≡ displacementSum p
antagonist-displacementSum (mkPoint (pos zero)     (pos zero)     _) = refl
antagonist-displacementSum (mkPoint (pos (suc _))  (pos zero)     _) = refl
antagonist-displacementSum (mkPoint (negsuc _)     (pos zero)     _) = refl
antagonist-displacementSum (mkPoint (pos zero)     (pos (suc _))  _) = refl
antagonist-displacementSum (mkPoint (pos zero)     (negsuc _)     _) = refl
antagonist-displacementSum (mkPoint (pos (suc ax)) (pos (suc ay)) _) = +-comm (suc ay) (suc ax)
antagonist-displacementSum (mkPoint (negsuc ax)    (negsuc ay)    _) = +-comm (suc ay) (suc ax)
antagonist-displacementSum (mkPoint (pos (suc ax)) (negsuc ay)    _) = +-comm (suc ay) (suc ax)
antagonist-displacementSum (mkPoint (negsuc ax)    (pos (suc ay)) _) = +-comm (suc ay) (suc ax)

-- ---------------------------------------------------------------------------
-- 4. Les 13 théorèmes certifiés d'AffectiveMatrix
-- ---------------------------------------------------------------------------

-- [1/13] HedonicPolarity_invert_involutive
HedonicPolarity_invert_involutive :
  ∀ (p : HedonicPolarity) → HedonicPolarity-invert (HedonicPolarity-invert p) ≡ p
HedonicPolarity_invert_involutive hedPositive = refl
HedonicPolarity_invert_involutive hedNegative = refl
HedonicPolarity_invert_involutive hedNeutral  = refl

-- [2/13] x_positive_determines_positive_valence
x_positive_determines_positive_valence :
  ∀ (k : Nat) (y : Int) → computeHedonicPolarity (pos (suc k)) y ≡ hedPositive
x_positive_determines_positive_valence _ _ = refl

-- [3/13] x_negative_determines_negative_valence
x_negative_determines_negative_valence :
  ∀ (k : Nat) (y : Int) → computeHedonicPolarity (negsuc k) y ≡ hedNegative
x_negative_determines_negative_valence _ _ = refl

-- [4/13] antagonistPoint_preserves_validity
antagonistPoint_preserves_validity :
  ∀ (p : CoreAffectPoint) → IsValidCoreAffect p → IsValidCoreAffect (antagonistPoint p)
antagonistPoint_preserves_validity p h =
  trans (cong₂ (λ c s → c ∨b (ge2ℕ (pz (antagonistPoint p)) ∧b (s == crownRadius (pz (antagonistPoint p)))))
               (antagonist-isCentral p)
               (antagonist-displacementSum p))
        (trans (cong (λ z → isCentralB p ∨b (ge2ℕ z ∧b (displacementSum p == crownRadius z)))
                     (antagonist-pz p))
               h)

-- [5/13] antagonistPoint_involutive
antagonistPoint_involutive :
  ∀ (p : CoreAffectPoint) → antagonistPoint (antagonistPoint p) ≡ p
antagonistPoint_involutive (mkPoint (pos zero)     (pos zero)     _) = refl
antagonistPoint_involutive (mkPoint (pos (suc _))  (pos zero)     _) = refl
antagonistPoint_involutive (mkPoint (negsuc _)     (pos zero)     _) = refl
antagonistPoint_involutive (mkPoint (pos zero)     (pos (suc _))  _) = refl
antagonistPoint_involutive (mkPoint (pos zero)     (negsuc _)     _) = refl
antagonistPoint_involutive (mkPoint (pos (suc _))  (pos (suc _))  _) = refl
antagonistPoint_involutive (mkPoint (negsuc _)     (negsuc _)     _) = refl
antagonistPoint_involutive (mkPoint (pos (suc _))  (negsuc _)     _) = refl
antagonistPoint_involutive (mkPoint (negsuc _)     (pos (suc _))  _) = refl

-- [6/13] contralateral_swaps_amplitudes
contralateral_swaps_amplitudes :
  ∀ (p : CoreAffectPoint) →
  (absNat (px (antagonistPoint p)) ≡ absNat (py p))
  × (absNat (py (antagonistPoint p)) ≡ absNat (px p))
  ⊎ (isZeroℤ (px p) ∨b isZeroℤ (py p) ≡ true)
contralateral_swaps_amplitudes (mkPoint (pos zero)     (pos zero)     _) = inj₂ refl
contralateral_swaps_amplitudes (mkPoint (pos (suc _))  (pos zero)     _) = inj₂ refl
contralateral_swaps_amplitudes (mkPoint (negsuc _)     (pos zero)     _) = inj₂ refl
contralateral_swaps_amplitudes (mkPoint (pos zero)     (pos (suc _))  _) = inj₂ refl
contralateral_swaps_amplitudes (mkPoint (pos zero)     (negsuc _)     _) = inj₂ refl
contralateral_swaps_amplitudes (mkPoint (pos (suc _))  (pos (suc _))  _) = inj₁ (refl , refl)
contralateral_swaps_amplitudes (mkPoint (negsuc _)     (negsuc _)     _) = inj₁ (refl , refl)
contralateral_swaps_amplitudes (mkPoint (pos (suc _))  (negsuc _)     _) = inj₁ (refl , refl)
contralateral_swaps_amplitudes (mkPoint (negsuc _)     (pos (suc _))  _) = inj₁ (refl , refl)

-- [7/13] antagonist_commutes_with_invert
antagonist_commutes-with-invert :
  ∀ (c : EngineCoupling) (d : Nat) →
  antagonistPoint (deployCouplingAtDepth c d) ≡
  deployCouplingAtDepth (mkEngineCoupling (Polarity-invert (attente c)) (Polarity-invert (controle c))) d
antagonist_commutes-with-invert (mkEngineCoupling zero zero) _ = refl
antagonist_commutes-with-invert (mkEngineCoupling neg  zero) _ = refl
antagonist_commutes-with-invert (mkEngineCoupling pos  zero) _ = refl
antagonist_commutes-with-invert (mkEngineCoupling zero neg)  _ = refl
antagonist_commutes-with-invert (mkEngineCoupling zero pos)  _ = refl
antagonist_commutes-with-invert (mkEngineCoupling neg  neg)  _ = refl
antagonist_commutes-with-invert (mkEngineCoupling neg  pos)  _ = refl
antagonist_commutes-with-invert (mkEngineCoupling pos  neg)  _ = refl
antagonist_commutes-with-invert (mkEngineCoupling pos  pos)  _ = refl

-- [8/13] antagonistPoint_unified
antagonistPoint_unified :
  ∀ (p : CoreAffectPoint) →
  isZeroℤ (px p) ≡ false → isZeroℤ (py p) ≡ false →
  antagonistPoint p ≡
    mkPoint ((-ℤ intSign (px p)) *ℤ pos (absNat (py p)))
            ((-ℤ intSign (py p)) *ℤ pos (absNat (px p)))
            (pz p)
antagonistPoint_unified (mkPoint (pos zero)     _              _) () _
antagonistPoint_unified (mkPoint _              (pos zero)     _) _  ()
antagonistPoint_unified (mkPoint (pos (suc ax)) (pos (suc ay)) _) _  _  rewrite +-zero-r ax | +-zero-r ay = refl
antagonistPoint_unified (mkPoint (negsuc ax)    (negsuc ay)    _) _  _  rewrite +-zero-r ax | +-zero-r ay = refl
antagonistPoint_unified (mkPoint (pos (suc ax)) (negsuc ay)    _) _  _  rewrite +-zero-r ax | +-zero-r ay = refl
antagonistPoint_unified (mkPoint (negsuc ax)    (pos (suc ay)) _) _  _  rewrite +-zero-r ax | +-zero-r ay = refl

-- [9/13] antagonist_preserves_validity_in
antagonist_preserves_validity-in :
  ∀ (r : ResourceRegime) (p : CoreAffectPoint) →
  IsValidCoreAffectIn r p → IsValidCoreAffectIn r (antagonistPoint p)
antagonist_preserves_validity-in competitive p h = antagonistPoint_preserves_validity p h
antagonist_preserves_validity-in cooperative p h =
  trans (cong₂ (λ c s → c ∨b (ge2ℕ (pz (antagonistPoint p)) ∧b leNatB (crownRadius (pz (antagonistPoint p))) s))
               (antagonist-isCentral p)
               (antagonist-displacementSum p))
        (trans (cong (λ z → isCentralB p ∨b (ge2ℕ z ∧b leNatB (crownRadius z) (displacementSum p)))
                     (antagonist-pz p))
               h)

-- [10/13] transferUnitYtoX_preserves_sum
transferUnitYtoX_preserves_sum :
  ∀ (p : CoreAffectPoint) →
  displacementSum (transferUnitYtoX p) ≡ displacementSum p
transferUnitYtoX_preserves_sum (mkPoint (pos ax)     (pos (suc ay)) _) = sym (+-suc-r ax ay)
transferUnitYtoX_preserves_sum (mkPoint (pos _)      (pos zero)     _) = refl
transferUnitYtoX_preserves_sum (mkPoint (pos _)      (negsuc _)     _) = refl
transferUnitYtoX_preserves_sum (mkPoint (negsuc _)   (pos zero)     _) = refl
transferUnitYtoX_preserves_sum (mkPoint (negsuc _)   (pos (suc _))  _) = refl
transferUnitYtoX_preserves_sum (mkPoint (negsuc _)   (negsuc _)     _) = refl

-- [11/13] antagonist_commutes_with_invert_precision
-- Helper: symmetry of apportionRay under swapping piA and piC
nat-==-sym : ∀ (a b : Nat) → (a == b) ≡ (b == a)
nat-==-sym zero    zero    = refl
nat-==-sym zero    (suc _) = refl
nat-==-sym (suc _) zero    = refl
nat-==-sym (suc a) (suc b) = nat-==-sym a b

nat-<-trichotomy :
  ∀ (a b : Nat) → (a == b) ≡ false → (a < b) ≡ not (b < a)
nat-<-trichotomy zero    zero    ()
nat-<-trichotomy zero    (suc _) _  = refl
nat-<-trichotomy (suc _) zero    _  = refl
nat-<-trichotomy (suc a) (suc b) h  = nat-<-trichotomy a b h

sub-sub-cancel : ∀ {k r : Nat} → k ≤ℕ r → r - (r - k) ≡ k
sub-sub-cancel {k} {r} h =
  +-cancel-l (r - k) (trans (add-sub-cancel (≤-minus-self r k))
                            (sym (trans (+-comm (r - k) k) (add-sub-cancel h))))

apportionRayCore-swap-x :
  ∀ (d piA piC : Nat) → apportionRayXCore d piC piA ≡ fullRay d - apportionRayXCore d piA piC
apportionRayCore-swap-x d piA piC
  rewrite nat-==-sym piC piA | +-comm piC piA =
  aux (piA == piC) refl
  where
    tot = piA + piC
    qC  = (2 * fullRay d * piC + tot) ÷ (2 * tot)
    aux : ∀ (b : Bool) → (piA == piC) ≡ b →
          (if b then halfRay d
           else if piC < piA then rawShare d piC tot
           else fullRay d - rawShare d piA tot)
          ≡ fullRay d -
            (if b then halfRay d
             else if piA < piC then rawShare d piA tot
             else fullRay d - rawShare d piC tot)
    aux true _ = sym (-ℕ-cancel (suc d) (suc d))
    aux false neq rewrite nat-<-trichotomy piA piC neq with piC < piA
    ... | true  = sym (sub-sub-cancel (≤ℕ-trans (clamp1-le d qC) (≤ℕ-add-r (suc d) (suc d))))
    ... | false = refl

apportionRay-swap-x :
  ∀ (d piA piC : Nat) → apportionRayX d piC piA ≡ apportionRayY d piA piC
apportionRay-swap-x d zero     zero     = apportionRayCore-swap-x d zero zero
apportionRay-swap-x d zero     (suc ay) = apportionRayCore-swap-x d zero (suc ay)
apportionRay-swap-x d (suc ax) zero     = apportionRayCore-swap-x d (suc ax) zero
apportionRay-swap-x d (suc ax) (suc ay) =
  trans (cong (λ c → if c then suc ay else apportionRayXCore d (suc ay) (suc ax))
              (cong (_== fullRay d) (+-comm (suc ay) (suc ax))))
        (aux ((suc ax + suc ay) == fullRay d) refl)
  where
    aux : ∀ (b : Bool) → ((suc ax + suc ay) == fullRay d) ≡ b →
          (if b then suc ay else apportionRayXCore d (suc ay) (suc ax))
          ≡ fullRay d - (if b then suc ax else apportionRayXCore d (suc ax) (suc ay))
    aux false _ = apportionRayCore-swap-x d (suc ax) (suc ay)
    aux true eq =
      trans (sym (-ℕ-cancel (suc ax) (suc ay)))
            (cong (_- suc ax) (nat-==-to-≡ (suc ax + suc ay) (fullRay d) eq))

apportionRay-swap-y :
  ∀ (d piA piC : Nat) → apportionRayY d piC piA ≡ apportionRayX d piA piC
apportionRay-swap-y d piA piC =
  trans (cong (fullRay d -_) (apportionRay-swap-x d piA piC))
        (sub-sub-cancel (apportionRayX-le-fullRay d piA piC))

antagonist-signed-pair :
  ∀ (a ctrl : Polarity) (rx ry z : Nat) →
  1 ≤ℕ rx → 1 ≤ℕ ry →
  Polarity-isEngaged a ≡ true → Polarity-isEngaged ctrl ≡ true →
  antagonistPoint (mkPoint (signedAmplitude a rx) (signedAmplitude ctrl ry) z) ≡
  mkPoint (signedAmplitude (Polarity-invert a) ry) (signedAmplitude (Polarity-invert ctrl) rx) z
antagonist-signed-pair neg  neg  (suc _) (suc _) _ _ _ _ _ = refl
antagonist-signed-pair neg  pos  (suc _) (suc _) _ _ _ _ _ = refl
antagonist-signed-pair pos  neg  (suc _) (suc _) _ _ _ _ _ = refl
antagonist-signed-pair pos  pos  (suc _) (suc _) _ _ _ _ _ = refl
antagonist-signed-pair zero _    _       _       _ _ _ () _
antagonist-signed-pair neg  zero _       _       _ _ _ _ ()
antagonist-signed-pair pos  zero _       _       _ _ _ _ ()

antagonist_commutes-with-invert_precision :
  ∀ (c : EngineCoupling) (d piA piC : Nat) →
  antagonistPoint (deployCouplingWithPrecision c d piA piC) ≡
  deployCouplingWithPrecision (mkEngineCoupling (Polarity-invert (attente c)) (Polarity-invert (controle c))) d piC piA
antagonist_commutes-with-invert_precision (mkEngineCoupling zero zero) _ _   _   = refl
antagonist_commutes-with-invert_precision (mkEngineCoupling neg  zero) _ _   _   = refl
antagonist_commutes-with-invert_precision (mkEngineCoupling pos  zero) _ _   _   = refl
antagonist_commutes-with-invert_precision (mkEngineCoupling zero neg)  _ _   _   = refl
antagonist_commutes-with-invert_precision (mkEngineCoupling zero pos)  _ _   _   = refl
antagonist_commutes-with-invert_precision (mkEngineCoupling neg  neg)  d piA piC =
  trans (antagonist-signed-pair neg neg (apportionRayX d piA piC) (apportionRayY d piA piC) (depthToZ d)
          (apportionRayX-pos d piA piC) (apportionRayY-pos d piA piC) refl refl)
        (cong₂ (λ rx ry → mkPoint (signedAmplitude pos rx) (signedAmplitude pos ry) (depthToZ d))
               (sym (apportionRay-swap-x d piA piC))
               (sym (apportionRay-swap-y d piA piC)))
antagonist_commutes-with-invert_precision (mkEngineCoupling neg  pos)  d piA piC =
  trans (antagonist-signed-pair neg pos (apportionRayX d piA piC) (apportionRayY d piA piC) (depthToZ d)
          (apportionRayX-pos d piA piC) (apportionRayY-pos d piA piC) refl refl)
        (cong₂ (λ rx ry → mkPoint (signedAmplitude pos rx) (signedAmplitude neg ry) (depthToZ d))
               (sym (apportionRay-swap-x d piA piC))
               (sym (apportionRay-swap-y d piA piC)))
antagonist_commutes-with-invert_precision (mkEngineCoupling pos  neg)  d piA piC =
  trans (antagonist-signed-pair pos neg (apportionRayX d piA piC) (apportionRayY d piA piC) (depthToZ d)
          (apportionRayX-pos d piA piC) (apportionRayY-pos d piA piC) refl refl)
        (cong₂ (λ rx ry → mkPoint (signedAmplitude neg rx) (signedAmplitude pos ry) (depthToZ d))
               (sym (apportionRay-swap-x d piA piC))
               (sym (apportionRay-swap-y d piA piC)))
antagonist_commutes-with-invert_precision (mkEngineCoupling pos  pos)  d piA piC =
  trans (antagonist-signed-pair pos pos (apportionRayX d piA piC) (apportionRayY d piA piC) (depthToZ d)
          (apportionRayX-pos d piA piC) (apportionRayY-pos d piA piC) refl refl)
        (cong₂ (λ rx ry → mkPoint (signedAmplitude neg rx) (signedAmplitude neg ry) (depthToZ d))
               (sym (apportionRay-swap-x d piA piC))
               (sym (apportionRay-swap-y d piA piC)))

-- [12/13] evaluateMatrix_core_antagonist_independent
evaluateMatrix_core_antagonist_independent :
  ∀ (p : CoreAffectPoint) (m1 m2 : PhenomenologicalMapping) →
  let r1 = evaluateMatrix p m1
      r2 = evaluateMatrix p m2
  in (core r1 ≡ core r2)
     × (energyRegime r1 ≡ energyRegime r2)
     × (antagonist r1 ≡ antagonist r2)
evaluateMatrix_core_antagonist_independent _ _ _ = refl , refl , refl

-- [13/13] mapping_independent_antagonist_invariants
mapping_independent_antagonist_invariants :
  ∀ (p : CoreAffectPoint) (m : PhenomenologicalMapping) →
  IsValidCoreAffect p →
  let r1 = evaluateMatrix p m
      rc = evaluateMatrix p canonicalMapping
  in IsValidCoreAffect (antagonist r1)
     × (antagonist (evaluateMatrix (antagonist r1) m) ≡ p)
     × (antagonist r1 ≡ antagonist rc)
mapping_independent_antagonist_invariants p _ h =
  antagonistPoint_preserves_validity p h , antagonistPoint_involutive p , refl
