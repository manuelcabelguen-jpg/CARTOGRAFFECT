{-# OPTIONS --safe --without-K #-}
-- Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
-- SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
-- Author: Manuel Cabelguen
--
-- Module 02 : CoreAffect (Agda 2.9.0, --safe --without-K)

module Cartograffect.CoreAffect where

open import Cartograffect.Prelude
open import Cartograffect.PredictiveEngine

-- ---------------------------------------------------------------------------
-- 1. Lemmes booléens et égalité décidable sur Nat / Bool
-- ---------------------------------------------------------------------------
UIP-Bool : ∀ {b1 b2 : Bool} (p q : b1 ≡ b2) → p ≡ q
UIP-Bool {true}  {true}  refl refl = refl
UIP-Bool {false} {false} refl refl = refl

nat-==-refl : ∀ (n : Nat) → (n == n) ≡ true
nat-==-refl zero    = refl
nat-==-refl (suc n) = nat-==-refl n

nat-==-of-≡ : ∀ {m n : Nat} → m ≡ n → (m == n) ≡ true
nat-==-of-≡ {m} refl = nat-==-refl m

nat-==-to-≡ : ∀ (m n : Nat) → (m == n) ≡ true → m ≡ n
nat-==-to-≡ zero    zero    _  = refl
nat-==-to-≡ zero    (suc _) ()
nat-==-to-≡ (suc _) zero    ()
nat-==-to-≡ (suc m) (suc n) h  = cong suc (nat-==-to-≡ m n h)

∨b-true-l : ∀ {a b : Bool} → a ≡ true → (a ∨b b) ≡ true
∨b-true-l refl = refl

∨b-true-r : ∀ {a b : Bool} → b ≡ true → (a ∨b b) ≡ true
∨b-true-r {true}  _    = refl
∨b-true-r {false} refl = refl

double-inj : ∀ (a b : Nat) → a + a ≡ b + b → a ≡ b
double-inj zero    zero    _  = refl
double-inj zero    (suc _) ()
double-inj (suc _) zero    ()
double-inj (suc a) (suc b) eq =
  cong suc (double-inj a b (pred2 (trans (sym (+-suc-r a a)) (trans (cong pred1 eq) (+-suc-r b b)))))
  where
    pred1 : Nat → Nat
    pred1 zero    = zero
    pred1 (suc x) = x
    pred2 : ∀ {x y} → suc x ≡ suc y → x ≡ y
    pred2 eq' = cong pred1 eq'

-- ---------------------------------------------------------------------------
-- 2. Types géométriques CoreAffect (espace toroïdal L1 3D)
-- ---------------------------------------------------------------------------
record CoreAffectPoint : Set where
  constructor mkPoint
  field
    px : Int
    py : Int
    pz : Nat

open CoreAffectPoint public

data GeometryType : Set where
  central  : GeometryType
  axial    : GeometryType
  diagonal : GeometryType
  lateral  : GeometryType

data ResourceRegime : Set where
  competitive : ResourceRegime
  cooperative : ResourceRegime

displacementSum : CoreAffectPoint → Nat
displacementSum p = absNat (px p) + absNat (py p)

depthToZ : Nat → Nat
depthToZ d = suc (suc d)

halfRay : Nat → Nat
halfRay d = suc d

fullRay : Nat → Nat
fullRay d = suc d + suc d

crownRadius : Nat → Nat
crownRadius zero          = 0
crownRadius (suc zero)    = 0
crownRadius (suc (suc d)) = suc d + suc d

isZeroℤ : Int → Bool
isZeroℤ (pos zero) = true
isZeroℤ _          = false

ge2ℕ : Nat → Bool
ge2ℕ (suc (suc _)) = true
ge2ℕ _             = false

leNatB : Nat → Nat → Bool
leNatB a b = not (b < a)

isCentralB : CoreAffectPoint → Bool
isCentralB p = isZeroℤ (px p) ∧b isZeroℤ (py p)

isOnCrownB : CoreAffectPoint → Bool
isOnCrownB p = ge2ℕ (pz p) ∧b (displacementSum p == crownRadius (pz p))

isValidCoreAffectB : CoreAffectPoint → Bool
isValidCoreAffectB p = isCentralB p ∨b isOnCrownB p

IsValidCoreAffect : CoreAffectPoint → Set
IsValidCoreAffect p = isValidCoreAffectB p ≡ true

isValidCoreAffect-pi : ∀ {p} (h1 h2 : IsValidCoreAffect p) → h1 ≡ h2
isValidCoreAffect-pi = UIP-Bool

isValidCoreAffectInB : ResourceRegime → CoreAffectPoint → Bool
isValidCoreAffectInB competitive p = isValidCoreAffectB p
isValidCoreAffectInB cooperative p =
  isCentralB p ∨b (ge2ℕ (pz p) ∧b leNatB (crownRadius (pz p)) (displacementSum p))

IsValidCoreAffectIn : ResourceRegime → CoreAffectPoint → Set
IsValidCoreAffectIn r p = isValidCoreAffectInB r p ≡ true

record CoreAffectState : Set where
  constructor mkCoreAffectState
  field
    point : CoreAffectPoint
    valid : IsValidCoreAffect point

open CoreAffectState public

CoreAffectState-eq : ∀ {s1 s2 : CoreAffectState} → point s1 ≡ point s2 → s1 ≡ s2
CoreAffectState-eq {mkCoreAffectState p v1} {mkCoreAffectState .p v2} refl =
  cong (mkCoreAffectState p) (isValidCoreAffect-pi {p} v1 v2)

classifyGeometry : CoreAffectPoint → GeometryType
classifyGeometry p =
  if isCentralB p then central
  else if isZeroℤ (px p) ∨b isZeroℤ (py p) then axial
  else if absNat (px p) == absNat (py p) then diagonal
  else lateral

-- ---------------------------------------------------------------------------
-- 3. Déploiement, répartition de rayon (ApportionRay) et projection R5
-- ---------------------------------------------------------------------------
signedAmplitude : Polarity → Nat → Int
signedAmplitude neg  zero    = pos zero
signedAmplitude neg  (suc k) = negsuc k
signedAmplitude zero _       = pos zero
signedAmplitude pos  amp     = pos amp

absNat-signedAmplitude :
  ∀ (pol : Polarity) (amp : Nat) → Polarity-isEngaged pol ≡ true → absNat (signedAmplitude pol amp) ≡ amp
absNat-signedAmplitude neg  zero    _ = refl
absNat-signedAmplitude neg  (suc _) _ = refl
absNat-signedAmplitude zero _       ()
absNat-signedAmplitude pos  _       _ = refl

deployCouplingAtDepth : EngineCoupling → Nat → CoreAffectPoint
deployCouplingAtDepth (mkEngineCoupling zero zero) _ = mkPoint (pos 0) (pos 0) 0
deployCouplingAtDepth (mkEngineCoupling a    zero) d = mkPoint (signedAmplitude a (fullRay d)) (pos 0) (depthToZ d)
deployCouplingAtDepth (mkEngineCoupling zero ctrl) d = mkPoint (pos 0) (signedAmplitude ctrl (fullRay d)) (depthToZ d)
deployCouplingAtDepth (mkEngineCoupling a    ctrl) d =
  mkPoint (signedAmplitude a (halfRay d)) (signedAmplitude ctrl (halfRay d)) (depthToZ d)

clamp1 : Nat → Nat → Nat
clamp1 _  zero    = 1
clamp1 hi (suc v) with ≤ℕ-dec (suc v) hi
... | yes _ = suc v
... | no  _ = hi

clamp1-ge1 : ∀ (d v : Nat) → 1 ≤ℕ clamp1 (suc d) v
clamp1-ge1 _ zero = s≤s z≤n
clamp1-ge1 d (suc v) with ≤ℕ-dec (suc v) (suc d)
... | yes _ = s≤s z≤n
... | no  _ = s≤s z≤n

clamp1-le : ∀ (d v : Nat) → clamp1 (suc d) v ≤ℕ suc d
clamp1-le _ zero = s≤s z≤n
clamp1-le d (suc v) with ≤ℕ-dec (suc v) (suc d)
... | yes h = h
... | no  _ = ≤ℕ-refl (suc d)

clamp1-d0 : ∀ (v : Nat) → clamp1 1 v ≡ 1
clamp1-d0 zero = refl
clamp1-d0 (suc zero) = refl
clamp1-d0 (suc (suc v)) with ≤ℕ-dec (suc (suc v)) 1
... | yes (s≤s ())
... | no  _ = refl

isExactRaySplitB : Nat → Nat → Nat → Bool
isExactRaySplitB d (suc ax) (suc ay) = (suc ax + suc ay) == fullRay d
isExactRaySplitB _ _        _        = false

rawShare : Nat → Nat → Nat → Nat
rawShare d num tot = clamp1 (halfRay d) ((2 * fullRay d * num + tot) ÷ (2 * tot))

apportionRayXCore : Nat → Nat → Nat → Nat
apportionRayXCore d piA piC =
  let r   = fullRay d
      tot = piA + piC
  in if piA == piC then halfRay d
     else if piA < piC then rawShare d piA tot
     else r - rawShare d piC tot

apportionRayX : Nat → Nat → Nat → Nat
apportionRayX d piA piC =
  if isExactRaySplitB d piA piC then piA
  else apportionRayXCore d piA piC

apportionRayY : Nat → Nat → Nat → Nat
apportionRayY d piA piC = fullRay d - apportionRayX d piA piC

add-sub-cancel : ∀ {k r : Nat} → k ≤ℕ r → k + (r - k) ≡ r
add-sub-cancel {zero}  {r}     z≤n     = -ℕ-zero r
add-sub-cancel {suc k} {suc r} (s≤s h) = cong suc (add-sub-cancel h)

≤-minus-self : ∀ (a b : Nat) → (a - b) ≤ℕ a
≤-minus-self a       zero    = ≤ℕ-refl a
≤-minus-self zero    (suc _) = z≤n
≤-minus-self (suc a) (suc b) = ≤-step-r (≤-minus-self a b)

apportionRayXCore-le-fullRay : ∀ d piA piC → apportionRayXCore d piA piC ≤ℕ fullRay d
apportionRayXCore-le-fullRay d piA piC with piA == piC
... | true  = ≤ℕ-add-r (suc d) (suc d)
... | false with piA < piC
...   | true  = ≤ℕ-trans (clamp1-le d (((2 * fullRay d * piA + (piA + piC)) ÷ (2 * (piA + piC))))) (≤ℕ-add-r (suc d) (suc d))
...   | false = ≤-minus-self (fullRay d) (rawShare d piC (piA + piC))

apportionRayX-le-fullRay : ∀ d piA piC → apportionRayX d piA piC ≤ℕ fullRay d
apportionRayX-le-fullRay d zero     piC      = apportionRayXCore-le-fullRay d zero piC
apportionRayX-le-fullRay d (suc ax) zero     = apportionRayXCore-le-fullRay d (suc ax) zero
apportionRayX-le-fullRay d (suc ax) (suc ay) = aux ((suc ax + suc ay) == fullRay d) refl
  where
    aux : ∀ (b : Bool) → ((suc ax + suc ay) == fullRay d) ≡ b →
          (if b then suc ax else apportionRayXCore d (suc ax) (suc ay)) ≤ℕ fullRay d
    aux true  eq = subst (suc ax ≤ℕ_) (nat-==-to-≡ (suc ax + suc ay) (fullRay d) eq) (≤ℕ-add-r (suc ax) (suc ay))
    aux false _  = apportionRayXCore-le-fullRay d (suc ax) (suc ay)

lt-double : ∀ (d : Nat) → suc d <ℕ fullRay d
lt-double zero    = s≤s (s≤s z≤n)
lt-double (suc d) rewrite +-suc-r (suc d) (suc d) = s≤s (≤-step-r (lt-double d))

sub-pos-of-lt : ∀ (a b : Nat) → b <ℕ a → 1 ≤ℕ a - b
sub-pos-of-lt (suc _) zero    (s≤s _) = s≤s z≤n
sub-pos-of-lt (suc a) (suc b) (s≤s h) = sub-pos-of-lt a b h

sub-ge1 : ∀ d {k} → k ≤ℕ suc d → 1 ≤ℕ fullRay d - k
sub-ge1 d {k} h = sub-pos-of-lt (fullRay d) k (≤ℕ-trans (s≤s h) (lt-double d))

apportionRayXCore-pos : ∀ d piA piC → 1 ≤ℕ apportionRayXCore d piA piC
apportionRayXCore-pos d piA piC with piA == piC
... | true  = s≤s z≤n
... | false with piA < piC
...   | true  = clamp1-ge1 d (((2 * fullRay d * piA + (piA + piC)) ÷ (2 * (piA + piC))))
...   | false = sub-ge1 d (clamp1-le d (((2 * fullRay d * piC + (piA + piC)) ÷ (2 * (piA + piC)))))

apportionRayX-pos : ∀ d piA piC → 1 ≤ℕ apportionRayX d piA piC
apportionRayX-pos d zero     piC      = apportionRayXCore-pos d zero piC
apportionRayX-pos d (suc ax) zero     = apportionRayXCore-pos d (suc ax) zero
apportionRayX-pos d (suc ax) (suc ay) with (suc ax + suc ay) == fullRay d
... | true  = s≤s z≤n
... | false = apportionRayXCore-pos d (suc ax) (suc ay)

sub-lt-of-pos : ∀ (r k : Nat) → 1 ≤ℕ r → 1 ≤ℕ k → (r - k) <ℕ r
sub-lt-of-pos (suc r) (suc k) _ _ = s≤s (≤-minus-self r k)

sub-sub-ge1 : ∀ (r k : Nat) → 1 ≤ℕ k → k ≤ℕ r → 1 ≤ℕ r - (r - k)
sub-sub-ge1 r k hk hkr = sub-pos-of-lt r (r - k) (sub-lt-of-pos r k (≤ℕ-trans hk hkr) hk)

apportionRayYCore-pos : ∀ d piA piC → 1 ≤ℕ fullRay d - apportionRayXCore d piA piC
apportionRayYCore-pos d piA piC with piA == piC
... | true  = sub-ge1 d (≤ℕ-refl (suc d))
... | false with piA < piC
...   | true  = sub-ge1 d (clamp1-le d (((2 * fullRay d * piA + (piA + piC)) ÷ (2 * (piA + piC)))))
...   | false =
  let q = (2 * fullRay d * piC + (piA + piC)) ÷ (2 * (piA + piC))
  in sub-sub-ge1 (fullRay d) (clamp1 (suc d) q) (clamp1-ge1 d q) (≤ℕ-trans (clamp1-le d q) (≤ℕ-add-r (suc d) (suc d)))

apportionRayY-pos : ∀ d piA piC → 1 ≤ℕ apportionRayY d piA piC
apportionRayY-pos d zero     piC      = apportionRayYCore-pos d zero piC
apportionRayY-pos d (suc ax) zero     = apportionRayYCore-pos d (suc ax) zero
apportionRayY-pos d (suc ax) (suc ay) = aux ((suc ax + suc ay) == fullRay d) refl
  where
    aux : ∀ (b : Bool) → ((suc ax + suc ay) == fullRay d) ≡ b →
          1 ≤ℕ (fullRay d - (if b then suc ax else apportionRayXCore d (suc ax) (suc ay)))
    aux true  eq =
      subst (1 ≤ℕ_) (trans (sym (-ℕ-cancel (suc ax) (suc ay)))
                           (cong (_- suc ax) (nat-==-to-≡ (suc ax + suc ay) (fullRay d) eq)))
            (s≤s z≤n)
    aux false _ = apportionRayYCore-pos d (suc ax) (suc ay)

apportionRay-sum : ∀ d piA piC → apportionRayX d piA piC + apportionRayY d piA piC ≡ fullRay d
apportionRay-sum d piA piC = add-sub-cancel (apportionRayX-le-fullRay d piA piC)

apportionRayCore-d0-x : ∀ piA piC → apportionRayXCore 0 piA piC ≡ 1
apportionRayCore-d0-x piA piC with piA == piC
... | true  = refl
... | false with piA < piC
...   | true  = clamp1-d0 (((4 * piA + (piA + piC)) ÷ (2 * (piA + piC))))
...   | false rewrite clamp1-d0 ((4 * piC + (piA + piC)) ÷ (2 * (piA + piC))) = refl

apportionRay-d0-x : ∀ piA piC → apportionRayX 0 piA piC ≡ 1
apportionRay-d0-x zero             piC      = apportionRayCore-d0-x zero piC
apportionRay-d0-x (suc ax)         zero     = apportionRayCore-d0-x (suc ax) zero
apportionRay-d0-x (suc zero)       (suc ay) with (1 + suc ay) == 2
... | true  = refl
... | false = apportionRayCore-d0-x 1 (suc ay)
apportionRay-d0-x (suc (suc ax))   (suc ay) = aux ((ax + suc ay) == 0) refl
  where
    absurd0 : ∀ a b → (a + suc b) ≡ 0 → ⊥
    absurd0 zero    _ ()
    absurd0 (suc _) _ ()
    aux : ∀ (b : Bool) → ((ax + suc ay) == 0) ≡ b →
          (if b then suc (suc ax) else apportionRayXCore 0 (suc (suc ax)) (suc ay)) ≡ 1
    aux false _  = apportionRayCore-d0-x (suc (suc ax)) (suc ay)
    aux true  eq = ⊥-elim (absurd0 ax ay (nat-==-to-≡ (ax + suc ay) 0 eq))

apportionRay-d0-y : ∀ piA piC → apportionRayY 0 piA piC ≡ 1
apportionRay-d0-y piA piC rewrite apportionRay-d0-x piA piC = refl

apportionRayCore-sym-x : ∀ d pi → apportionRayXCore d pi pi ≡ suc d
apportionRayCore-sym-x d pi rewrite nat-==-refl pi = refl

apportionRay-sym-x : ∀ d pi → apportionRayX d pi pi ≡ suc d
apportionRay-sym-x d zero = apportionRayCore-sym-x d zero
apportionRay-sym-x d (suc ax) = aux ((suc ax + suc ax) == fullRay d) refl
  where
    aux : ∀ (b : Bool) → ((suc ax + suc ax) == fullRay d) ≡ b →
          (if b then suc ax else apportionRayXCore d (suc ax) (suc ax)) ≡ suc d
    aux true  eq = double-inj (suc ax) (suc d) (nat-==-to-≡ (suc ax + suc ax) (fullRay d) eq)
    aux false _  = apportionRayCore-sym-x d (suc ax)

apportionRay-sym-y : ∀ d pi → apportionRayY d pi pi ≡ suc d
apportionRay-sym-y d pi rewrite apportionRay-sym-x d pi = -ℕ-cancel (suc d) (suc d)

deployCouplingWithPrecision : EngineCoupling → Nat → Nat → Nat → CoreAffectPoint
deployCouplingWithPrecision (mkEngineCoupling zero zero) _ _   _   = mkPoint (pos 0) (pos 0) 0
deployCouplingWithPrecision (mkEngineCoupling a    zero) d _   _   = mkPoint (signedAmplitude a (fullRay d)) (pos 0) (depthToZ d)
deployCouplingWithPrecision (mkEngineCoupling zero ctrl) d _   _   = mkPoint (pos 0) (signedAmplitude ctrl (fullRay d)) (depthToZ d)
deployCouplingWithPrecision (mkEngineCoupling a    ctrl) d piA piC =
  mkPoint (signedAmplitude a (apportionRayX d piA piC))
          (signedAmplitude ctrl (apportionRayY d piA piC))
          (depthToZ d)

projectToCoreAffect : PredictiveEngineState → CoreAffectPoint
projectToCoreAffect s =
  let c = currentCoupling s
      d = persistenceDepth (attentional s)
  in if not (isSensorilySalientB (discrepancy s)) ∨b isGlobalNeutralityB c then
       (if descendingSuspension (subjective s) then mkPoint (pos 0) (pos 0) (depthToZ d)
        else mkPoint (pos 0) (pos 0) 0)
     else if not (Attentional-isEngagedB (attentional s)) then
       (if descendingSuspension (subjective s) then mkPoint (pos 0) (pos 0) (depthToZ d)
        else mkPoint (pos 0) (pos 0) 1)
     else deployCouplingWithPrecision c d (precisionA (attentional s)) (precisionC (attentional s))

triggerSecondaryGradient : EngineCoupling → Polarity → EngineCoupling
triggerSecondaryGradient (mkEngineCoupling neg  zero) newPol = mkEngineCoupling neg newPol
triggerSecondaryGradient (mkEngineCoupling pos  zero) newPol = mkEngineCoupling pos newPol
triggerSecondaryGradient (mkEngineCoupling zero neg)  newPol = mkEngineCoupling newPol neg
triggerSecondaryGradient (mkEngineCoupling zero pos)  newPol = mkEngineCoupling newPol pos
triggerSecondaryGradient c                            _      = c

polarityOfInt : Int → Polarity
polarityOfInt (pos zero)    = zero
polarityOfInt (pos (suc _)) = pos
polarityOfInt (negsuc _)    = neg

witnessEngineForPoint : CoreAffectPoint → PredictiveEngineState
witnessEngineForPoint p =
  let ax = absNat (px p)
      ay = absNat (py p)
      d  = pz p - 2
  in if isCentralB p then
       (if pz p == 0 then
          mkPredictiveEngineState
            (mkSalientDiscrepancy 0 1 1 (s≤s z≤n))
            (mkPerceptiveInterface zero)
            (mkSubjectiveInterface zero false)
            (mkAttentionalInterface 0 0 0 1 1)
        else if pz p == 1 then
          mkPredictiveEngineState
            (mkSalientDiscrepancy 2 1 1 (s≤s z≤n))
            (mkPerceptiveInterface zero)
            (mkSubjectiveInterface pos false)
            (mkAttentionalInterface 0 1 0 1 1)
        else
          mkPredictiveEngineState
            (mkSalientDiscrepancy 2 1 1 (s≤s z≤n))
            (mkPerceptiveInterface zero)
            (mkSubjectiveInterface pos true)
            (mkAttentionalInterface 0 1 d 1 1))
     else
       let useSym = (ax == 0) ∨b (ay == 0)
       in mkPredictiveEngineState
            (mkSalientDiscrepancy 2 1 1 (s≤s z≤n))
            (mkPerceptiveInterface (polarityOfInt (py p)))
            (mkSubjectiveInterface (polarityOfInt (px p)) true)
            (mkAttentionalInterface 1 1 d
              (if useSym then 1 else ax)
              (if useSym then 1 else ay))

dissipationStep : CoreAffectPoint → CoreAffectPoint
dissipationStep p =
  if not (isCentralB p) then mkPoint (pos 0) (pos 0) (pz p)
  else if leNatB (pz p) 2 then mkPoint (pos 0) (pos 0) 0
  else mkPoint (pos 0) (pos 0) (pz p - 1)

dissipationPotential : CoreAffectPoint → Nat
dissipationPotential p =
  2 * pz p + (if not (isCentralB p) then 1 else 0)

allostaticStep : SalientDiscrepancy → CoreAffectPoint → CoreAffectPoint
allostaticStep d p =
  if magnitude d < resorptionThreshold d then dissipationStep p else p

repeatDissipation : Nat → CoreAffectPoint → CoreAffectPoint
repeatDissipation zero    p = p
repeatDissipation (suc n) p = repeatDissipation n (dissipationStep p)

-- ---------------------------------------------------------------------------
-- 4. Les 23 théorèmes certifiés de CoreAffect
-- ---------------------------------------------------------------------------

-- [9/23] deployCouplingWithPrecision_valid
deployCouplingWithPrecision_valid :
  ∀ (c : EngineCoupling) (d piA piC : Nat) →
  IsValidCoreAffect (deployCouplingWithPrecision c d piA piC)
deployCouplingWithPrecision_valid (mkEngineCoupling zero zero) _ _ _ = refl
deployCouplingWithPrecision_valid (mkEngineCoupling neg  zero) d _ _ =
  ∨b-true-r (nat-==-of-≡ (+-zero-r (fullRay d)))
deployCouplingWithPrecision_valid (mkEngineCoupling pos  zero) d _ _ =
  ∨b-true-r (nat-==-of-≡ (+-zero-r (fullRay d)))
deployCouplingWithPrecision_valid (mkEngineCoupling zero neg)  d _ _ =
  ∨b-true-r (nat-==-refl (fullRay d))
deployCouplingWithPrecision_valid (mkEngineCoupling zero pos)  d _ _ =
  ∨b-true-r (nat-==-refl (fullRay d))
deployCouplingWithPrecision_valid (mkEngineCoupling neg  neg)  d piA piC =
  ∨b-true-r (nat-==-of-≡ (trans (cong₂ _+_ (absNat-signedAmplitude neg (apportionRayX d piA piC) refl)
                                           (absNat-signedAmplitude neg (apportionRayY d piA piC) refl))
                                (apportionRay-sum d piA piC)))
deployCouplingWithPrecision_valid (mkEngineCoupling neg  pos)  d piA piC =
  ∨b-true-r (nat-==-of-≡ (trans (cong₂ _+_ (absNat-signedAmplitude neg (apportionRayX d piA piC) refl)
                                           (absNat-signedAmplitude pos (apportionRayY d piA piC) refl))
                                (apportionRay-sum d piA piC)))
deployCouplingWithPrecision_valid (mkEngineCoupling pos  neg)  d piA piC =
  ∨b-true-r (nat-==-of-≡ (trans (cong₂ _+_ (absNat-signedAmplitude pos (apportionRayX d piA piC) refl)
                                           (absNat-signedAmplitude neg (apportionRayY d piA piC) refl))
                                (apportionRay-sum d piA piC)))
deployCouplingWithPrecision_valid (mkEngineCoupling pos  pos)  d piA piC =
  ∨b-true-r (nat-==-of-≡ (trans (cong₂ _+_ (absNat-signedAmplitude pos (apportionRayX d piA piC) refl)
                                           (absNat-signedAmplitude pos (apportionRayY d piA piC) refl))
                                (apportionRay-sum d piA piC)))

-- [1/23] engine_induces_valid_core_affect
engine_induces_valid_core_affect :
  ∀ (s : PredictiveEngineState) → IsValidCoreAffect (projectToCoreAffect s)
engine_induces_valid_core_affect s
  with not (isSensorilySalientB (discrepancy s)) ∨b isGlobalNeutralityB (currentCoupling s)
... | true with descendingSuspension (subjective s)
...   | true  = refl
...   | false = refl
engine_induces_valid_core_affect s | false with not (Attentional-isEngagedB (attentional s))
... | true with descendingSuspension (subjective s)
...   | true  = refl
...   | false = refl
engine_induces_valid_core_affect s | false | false =
  deployCouplingWithPrecision_valid
    (currentCoupling s)
    (persistenceDepth (attentional s))
    (precisionA (attentional s))
    (precisionC (attentional s))

evaluateCoreAffect : PredictiveEngineState → CoreAffectState
evaluateCoreAffect s = mkCoreAffectState (projectToCoreAffect s) (engine_induces_valid_core_affect s)

-- [2/23] z2_budget_conservation
z2_budget_conservation :
  ∀ (c : EngineCoupling) → isGlobalNeutralityB c ≡ false →
  displacementSum (deployCouplingAtDepth c 0) ≡ 2
z2_budget_conservation (mkEngineCoupling zero zero) ()
z2_budget_conservation (mkEngineCoupling neg  zero) _ = refl
z2_budget_conservation (mkEngineCoupling pos  zero) _ = refl
z2_budget_conservation (mkEngineCoupling zero neg)  _ = refl
z2_budget_conservation (mkEngineCoupling zero pos)  _ = refl
z2_budget_conservation (mkEngineCoupling neg  neg)  _ = refl
z2_budget_conservation (mkEngineCoupling neg  pos)  _ = refl
z2_budget_conservation (mkEngineCoupling pos  neg)  _ = refl
z2_budget_conservation (mkEngineCoupling pos  pos)  _ = refl

-- [3/23] axial_to_diagonal_reallocation
axial-to-diagonal_reallocation :
  ∀ (c : EngineCoupling) (newPol : Polarity) →
  isSingleEngagedB c ≡ true →
  Polarity-isEngaged newPol ≡ true →
  let pt = deployCouplingAtDepth (triggerSecondaryGradient c newPol) 0 in
  (classifyGeometry pt ≡ diagonal) × (displacementSum pt ≡ 2)
axial-to-diagonal_reallocation (mkEngineCoupling neg  zero) neg  _ _ = refl , refl
axial-to-diagonal_reallocation (mkEngineCoupling neg  zero) pos  _ _ = refl , refl
axial-to-diagonal_reallocation (mkEngineCoupling neg  zero) zero _ ()
axial-to-diagonal_reallocation (mkEngineCoupling pos  zero) neg  _ _ = refl , refl
axial-to-diagonal_reallocation (mkEngineCoupling pos  zero) pos  _ _ = refl , refl
axial-to-diagonal_reallocation (mkEngineCoupling pos  zero) zero _ ()
axial-to-diagonal_reallocation (mkEngineCoupling zero neg)  neg  _ _ = refl , refl
axial-to-diagonal_reallocation (mkEngineCoupling zero neg)  pos  _ _ = refl , refl
axial-to-diagonal_reallocation (mkEngineCoupling zero neg)  zero _ ()
axial-to-diagonal_reallocation (mkEngineCoupling zero pos)  neg  _ _ = refl , refl
axial-to-diagonal_reallocation (mkEngineCoupling zero pos)  pos  _ _ = refl , refl
axial-to-diagonal_reallocation (mkEngineCoupling zero pos)  zero _ ()
axial-to-diagonal_reallocation (mkEngineCoupling zero zero) _    () _
axial-to-diagonal_reallocation (mkEngineCoupling neg  neg)  _    () _
axial-to-diagonal_reallocation (mkEngineCoupling neg  pos)  _    () _
axial-to-diagonal_reallocation (mkEngineCoupling pos  neg)  _    () _
axial-to-diagonal_reallocation (mkEngineCoupling pos  pos)  _    () _

-- [4/23] dissipationStep_valid
dissipationStep_valid : ∀ (p : CoreAffectPoint) → IsValidCoreAffect (dissipationStep p)
dissipationStep_valid p with isCentralB p
... | false = refl
... | true with leNatB (pz p) 2
...   | true  = refl
...   | false = refl

-- [5/23] dissipationStep_fixed_iff
isCentralB-to-xy : ∀ (p : CoreAffectPoint) → isCentralB p ≡ true → (px p ≡ pos 0) × (py p ≡ pos 0)
isCentralB-to-xy (mkPoint (pos zero)    (pos zero)    _) _  = refl , refl
isCentralB-to-xy (mkPoint (pos zero)    (pos (suc _)) _) ()
isCentralB-to-xy (mkPoint (pos zero)    (negsuc _)    _) ()
isCentralB-to-xy (mkPoint (pos (suc _)) _             _) ()
isCentralB-to-xy (mkPoint (negsuc _)    _             _) ()

dissipationStep_fixed_iff :
  ∀ (p : CoreAffectPoint) →
  ((dissipationStep p ≡ p) → (p ≡ mkPoint (pos 0) (pos 0) 0))
  × ((p ≡ mkPoint (pos 0) (pos 0) 0) → (dissipationStep p ≡ p))
dissipationStep_fixed_iff p = fwd p , (λ eq → subst (λ q → dissipationStep q ≡ q) (sym eq) refl)
  where
    no-fix-sub1 : ∀ (n : Nat) → ¬ (suc (suc n) ≡ suc (suc (suc n)))
    no-fix-sub1 zero    ()
    no-fix-sub1 (suc n) eq = no-fix-sub1 n (cong pred eq)
      where pred : Nat → Nat; pred zero = zero; pred (suc x) = x
    false≢true : false ≡ true → ⊥
    false≢true ()
    z1≢0 : 0 ≡ 1 → ⊥
    z1≢0 ()
    z2≢0 : 0 ≡ 2 → ⊥
    z2≢0 ()

    fwd : ∀ (q : CoreAffectPoint) → dissipationStep q ≡ q → q ≡ mkPoint (pos 0) (pos 0) 0
    fwd (mkPoint x y z) = aux z (isCentralB (mkPoint x y z)) refl
      where
        aux : ∀ (zv : Nat) (b : Bool) → isCentralB (mkPoint x y zv) ≡ b →
              (if not b then mkPoint (pos 0) (pos 0) zv
               else if leNatB zv 2 then mkPoint (pos 0) (pos 0) 0
               else mkPoint (pos 0) (pos 0) (zv - 1)) ≡ mkPoint x y zv →
              mkPoint x y zv ≡ mkPoint (pos 0) (pos 0) 0
        aux _               false cEq eq =
          ⊥-elim (false≢true (trans (sym cEq) (sym (cong isCentralB eq))))
        aux zero            true  _   eq = sym eq
        aux (suc zero)      true  _   eq = ⊥-elim (z1≢0 (cong pz eq))
        aux (suc (suc zero)) true _   eq = ⊥-elim (z2≢0 (cong pz eq))
        aux (suc (suc (suc n))) true _ eq = ⊥-elim (no-fix-sub1 n (cong pz eq))

-- [6/23] dissipation_strictly_decreases
dissipation_strictly_decreases :
  ∀ (p : CoreAffectPoint) → ¬ (p ≡ mkPoint (pos 0) (pos 0) 0) →
  dissipationPotential (dissipationStep p) <ℕ dissipationPotential p
dissipation_strictly_decreases (mkPoint x y z) neq = aux z (isCentralB (mkPoint x y z)) refl neq
  where
    add-0-lt-add-1 : ∀ (n : Nat) → (n + 0) <ℕ (n + 1)
    add-0-lt-add-1 zero    = s≤s z≤n
    add-0-lt-add-1 (suc n) = s≤s (add-0-lt-add-1 n)

    pot-step-lt : ∀ (m : Nat) → (2 * m + 0) <ℕ (2 * suc m + 0)
    pot-step-lt m rewrite +-zero-r (2 * m) | +-zero-r (2 * suc m) | +-suc-r m (m + 0) =
      s≤s (≤-step-r (≤ℕ-refl (m + (m + 0))))

    aux : ∀ (zv : Nat) (b : Bool) → isCentralB (mkPoint x y zv) ≡ b →
          ¬ (mkPoint x y zv ≡ mkPoint (pos 0) (pos 0) 0) →
          dissipationPotential
            (if not b then mkPoint (pos 0) (pos 0) zv
             else if leNatB zv 2 then mkPoint (pos 0) (pos 0) 0
             else mkPoint (pos 0) (pos 0) (zv - 1))
          <ℕ (2 * zv + (if not b then 1 else 0))
    aux zv false _ _ = add-0-lt-add-1 (2 * zv)
    aux zero true cEq neq' =
      let xy = isCentralB-to-xy (mkPoint x y 0) cEq
      in ⊥-elim (neq' (cong₂ (λ a b → mkPoint a b 0) (fst xy) (snd xy)))
    aux (suc zero)          true _ _ = s≤s z≤n
    aux (suc (suc zero))    true _ _ = s≤s z≤n
    aux (suc (suc (suc n))) true _ _ = pot-step-lt (suc (suc n))

-- [7/23] remanence_preserves_state
remanence_preserves_state :
  ∀ (d : SalientDiscrepancy) (p : CoreAffectPoint) →
  isInRemanenceWindowB d ≡ true →
  allostaticStep d p ≡ p
remanence_preserves_state d p h with magnitude d < resorptionThreshold d | h
... | false | _  = refl
... | true  | ()

-- [8/23] cooperative_step_leaves_crown
cooperative_step_leaves_crown :
  ∀ (p : CoreAffectPoint) (nx ny : Nat) →
  px p ≡ pos nx → py p ≡ pos ny →
  isOnCrownB p ≡ true →
  isOnCrownB (mkPoint (pos (suc nx)) (pos (suc ny)) (pz p)) ≡ false
cooperative_step_leaves_crown (mkPoint .(pos nx) .(pos ny) z) nx ny refl refl h
  with z
... | zero = refl
... | suc zero = refl
... | suc (suc d) =
  let eqSum : nx + ny ≡ suc d + suc d
      eqSum = nat-==-to-≡ (nx + ny) (suc d + suc d) h
  in neq-to-==-false (suc nx + suc ny) (suc d + suc d)
       (λ bad → suc2-ne (nx + ny) (trans (sym (+-suc-r (suc nx) ny)) (trans bad (sym eqSum))))
  where
    suc2-ne : ∀ (m : Nat) → ¬ (suc (suc m) ≡ m)
    suc2-ne zero ()
    suc2-ne (suc m) eq = suc2-ne m (cong pred eq)
      where pred : Nat → Nat; pred zero = zero; pred (suc v) = v
    neq-to-==-false : ∀ (a b : Nat) → ¬ (a ≡ b) → (a == b) ≡ false
    neq-to-==-false zero zero ne = ⊥-elim (ne refl)
    neq-to-==-false zero (suc _) _ = refl
    neq-to-==-false (suc _) zero _ = refl
    neq-to-==-false (suc a) (suc b) ne = neq-to-==-false a b (λ e → ne (cong suc e))

-- [10/23] neutral_coupling_without_suspension_yields_veille
neutral_coupling_without_suspension_yields_veille :
  ∀ (s : PredictiveEngineState) →
  isGlobalNeutralityB (currentCoupling s) ≡ true →
  descendingSuspension (subjective s) ≡ false →
  projectToCoreAffect s ≡ mkPoint (pos 0) (pos 0) 0
neutral_coupling_without_suspension_yields_veille s hNeut hSusp
  with isSensorilySalientB (discrepancy s)
... | true  rewrite hNeut | hSusp = refl
... | false rewrite hSusp = refl

-- [11/23] neutral_or_subthreshold_with_suspension_yields_central
neutral_or_subthreshold-with-suspension_yields_central :
  ∀ (s : PredictiveEngineState) →
  (not (isSensorilySalientB (discrepancy s)) ∨b isGlobalNeutralityB (currentCoupling s)) ≡ true →
  descendingSuspension (subjective s) ≡ true →
  projectToCoreAffect s ≡ mkPoint (pos 0) (pos 0) (depthToZ (persistenceDepth (attentional s)))
neutral_or_subthreshold-with-suspension_yields_central s hCond hSusp
  rewrite hCond | hSusp = refl

-- [12/23] descending_suspension_yields_central_operator
descending_suspension_yields_central_operator :
  ∀ (s : PredictiveEngineState) →
  descendingSuspension (subjective s) ≡ true →
  ((not (isSensorilySalientB (discrepancy s)) ∨b isGlobalNeutralityB (currentCoupling s)) ≡ true)
  ⊎ (Attentional-isEngagedB (attentional s) ≡ false) →
  projectToCoreAffect s ≡ mkPoint (pos 0) (pos 0) (depthToZ (persistenceDepth (attentional s)))
descending_suspension_yields_central_operator s hSusp (inj₁ h1)
  rewrite h1 | hSusp = refl
descending_suspension_yields_central_operator s hSusp (inj₂ h2)
  with not (isSensorilySalientB (discrepancy s)) ∨b isGlobalNeutralityB (currentCoupling s)
... | true  rewrite hSusp = refl
... | false rewrite h2 | hSusp = refl

-- [13/23] central_z_ge2_requires_descending_suspension
deploy-never-central :
  ∀ (c : EngineCoupling) (d piA piC d' : Nat) →
  isGlobalNeutralityB c ≡ false →
  ¬ (deployCouplingWithPrecision c d piA piC ≡ mkPoint (pos 0) (pos 0) (depthToZ d'))
deploy-never-central (mkEngineCoupling zero zero) _ _ _ _ () _
deploy-never-central (mkEngineCoupling neg  zero) _ _ _ _ _ ()
deploy-never-central (mkEngineCoupling pos  zero) _ _ _ _ _ ()
deploy-never-central (mkEngineCoupling zero neg)  _ _ _ _ _ ()
deploy-never-central (mkEngineCoupling zero pos)  _ _ _ _ _ ()
deploy-never-central (mkEngineCoupling neg  neg)  d piA piC _ _ eq =
  pos0≢signed-neg (apportionRayX d piA piC) (apportionRayX-pos d piA piC) (cong px eq)
  where
    pos0≢signed-neg : ∀ (v : Nat) → 1 ≤ℕ v → ¬ (signedAmplitude neg v ≡ pos 0)
    pos0≢signed-neg (suc _) _ ()
deploy-never-central (mkEngineCoupling neg  pos)  d piA piC _ _ eq =
  pos0≢signed-neg (apportionRayX d piA piC) (apportionRayX-pos d piA piC) (cong px eq)
  where
    pos0≢signed-neg : ∀ (v : Nat) → 1 ≤ℕ v → ¬ (signedAmplitude neg v ≡ pos 0)
    pos0≢signed-neg (suc _) _ ()
deploy-never-central (mkEngineCoupling pos  neg)  d piA piC _ _ eq =
  pos0≢signed-pos (apportionRayX d piA piC) (apportionRayX-pos d piA piC) (cong px eq)
  where
    pos0≢signed-pos : ∀ (v : Nat) → 1 ≤ℕ v → ¬ (signedAmplitude pos v ≡ pos 0)
    pos0≢signed-pos (suc _) _ ()
deploy-never-central (mkEngineCoupling pos  pos)  d piA piC _ _ eq =
  pos0≢signed-pos (apportionRayX d piA piC) (apportionRayX-pos d piA piC) (cong px eq)
  where
    pos0≢signed-pos : ∀ (v : Nat) → 1 ≤ℕ v → ¬ (signedAmplitude pos v ≡ pos 0)
    pos0≢signed-pos (suc _) _ ()

central_z_ge2_requires_descending_suspension :
  ∀ (s : PredictiveEngineState) (d : Nat) →
  projectToCoreAffect s ≡ mkPoint (pos 0) (pos 0) (depthToZ d) →
  (descendingSuspension (subjective s) ≡ true)
  × (persistenceDepth (attentional s) ≡ d)
  × (((not (isSensorilySalientB (discrepancy s)) ∨b isGlobalNeutralityB (currentCoupling s)) ≡ true)
     ⊎ (Attentional-isEngagedB (attentional s) ≡ false))
central_z_ge2_requires_descending_suspension s d =
  aux (not (isSensorilySalientB (discrepancy s)) ∨b isGlobalNeutralityB (currentCoupling s)) refl
  where
    or-false-r : ∀ (a b : Bool) → (a ∨b b) ≡ false → b ≡ false
    or-false-r false false _ = refl
    or-false-r false true  ()
    or-false-r true  _     ()

    aux : ∀ (b : Bool) →
          (not (isSensorilySalientB (discrepancy s)) ∨b isGlobalNeutralityB (currentCoupling s)) ≡ b →
          (if b then
             (if descendingSuspension (subjective s) then mkPoint (pos 0) (pos 0) (depthToZ (persistenceDepth (attentional s)))
              else mkPoint (pos 0) (pos 0) 0)
           else if not (Attentional-isEngagedB (attentional s)) then
             (if descendingSuspension (subjective s) then mkPoint (pos 0) (pos 0) (depthToZ (persistenceDepth (attentional s)))
              else mkPoint (pos 0) (pos 0) 1)
           else deployCouplingWithPrecision (currentCoupling s) (persistenceDepth (attentional s))
                  (precisionA (attentional s)) (precisionC (attentional s)))
          ≡ mkPoint (pos 0) (pos 0) (depthToZ d) →
          (descendingSuspension (subjective s) ≡ true)
          × (persistenceDepth (attentional s) ≡ d)
          × (((not (isSensorilySalientB (discrepancy s)) ∨b isGlobalNeutralityB (currentCoupling s)) ≡ true)
             ⊎ (Attentional-isEngagedB (attentional s) ≡ false))
    aux true orEq eq with descendingSuspension (subjective s)
    ... | true  = refl , cong (λ n → n - 2) (cong pz eq) , inj₁ orEq
    ... | false with cong pz eq
    ...   | ()
    aux false orEq eq = auxAtt (Attentional-isEngagedB (attentional s)) refl eq
      where
        auxAtt : ∀ (ea : Bool) → Attentional-isEngagedB (attentional s) ≡ ea →
                 (if not ea then
                    (if descendingSuspension (subjective s) then mkPoint (pos 0) (pos 0) (depthToZ (persistenceDepth (attentional s)))
                     else mkPoint (pos 0) (pos 0) 1)
                  else deployCouplingWithPrecision (currentCoupling s) (persistenceDepth (attentional s))
                         (precisionA (attentional s)) (precisionC (attentional s)))
                 ≡ mkPoint (pos 0) (pos 0) (depthToZ d) →
                 (descendingSuspension (subjective s) ≡ true)
                 × (persistenceDepth (attentional s) ≡ d)
                 × (((not (isSensorilySalientB (discrepancy s)) ∨b isGlobalNeutralityB (currentCoupling s)) ≡ true)
                    ⊎ (Attentional-isEngagedB (attentional s) ≡ false))
        auxAtt false eaEq eq2 with descendingSuspension (subjective s)
        ... | true  = refl , cong (λ n → n - 2) (cong pz eq2) , inj₂ eaEq
        ... | false with cong pz eq2
        ...   | ()
        auxAtt true _ eq2 =
          ⊥-elim (deploy-never-central (currentCoupling s) (persistenceDepth (attentional s))
                    (precisionA (attentional s)) (precisionC (attentional s)) d
                    (or-false-r (not (isSensorilySalientB (discrepancy s))) (isGlobalNeutralityB (currentCoupling s)) orEq) eq2)

-- [14/23] deployCouplingWithPrecision_budget_conservation
deployCouplingWithPrecision_budget_conservation :
  ∀ (c : EngineCoupling) (d piA piC : Nat) →
  isGlobalNeutralityB c ≡ false →
  displacementSum (deployCouplingWithPrecision c d piA piC) ≡ fullRay d
deployCouplingWithPrecision_budget_conservation (mkEngineCoupling zero zero) _ _   _   ()
deployCouplingWithPrecision_budget_conservation (mkEngineCoupling neg  zero) d _   _   _ = +-zero-r (fullRay d)
deployCouplingWithPrecision_budget_conservation (mkEngineCoupling pos  zero) d _   _   _ = +-zero-r (fullRay d)
deployCouplingWithPrecision_budget_conservation (mkEngineCoupling zero neg)  _ _   _   _ = refl
deployCouplingWithPrecision_budget_conservation (mkEngineCoupling zero pos)  _ _   _   _ = refl
deployCouplingWithPrecision_budget_conservation (mkEngineCoupling neg  neg)  d piA piC _ =
  trans (cong₂ _+_ (absNat-signedAmplitude neg (apportionRayX d piA piC) refl)
                   (absNat-signedAmplitude neg (apportionRayY d piA piC) refl))
        (apportionRay-sum d piA piC)
deployCouplingWithPrecision_budget_conservation (mkEngineCoupling neg  pos)  d piA piC _ =
  trans (cong₂ _+_ (absNat-signedAmplitude neg (apportionRayX d piA piC) refl)
                   (absNat-signedAmplitude pos (apportionRayY d piA piC) refl))
        (apportionRay-sum d piA piC)
deployCouplingWithPrecision_budget_conservation (mkEngineCoupling pos  neg)  d piA piC _ =
  trans (cong₂ _+_ (absNat-signedAmplitude pos (apportionRayX d piA piC) refl)
                   (absNat-signedAmplitude neg (apportionRayY d piA piC) refl))
        (apportionRay-sum d piA piC)
deployCouplingWithPrecision_budget_conservation (mkEngineCoupling pos  pos)  d piA piC _ =
  trans (cong₂ _+_ (absNat-signedAmplitude pos (apportionRayX d piA piC) refl)
                   (absNat-signedAmplitude pos (apportionRayY d piA piC) refl))
        (apportionRay-sum d piA piC)

-- [15/23] dual_engaged_yields_diagonal_z2_precision
dual_engaged_yields_diagonal_z2_precision :
  ∀ (c : EngineCoupling) (piA piC : Nat) →
  isDualEngagedB c ≡ true →
  classifyGeometry (deployCouplingWithPrecision c 0 piA piC) ≡ diagonal
dual_engaged_yields_diagonal_z2_precision (mkEngineCoupling neg  neg)  piA piC _
  rewrite apportionRay-d0-x piA piC = refl
dual_engaged_yields_diagonal_z2_precision (mkEngineCoupling neg  pos)  piA piC _
  rewrite apportionRay-d0-x piA piC = refl
dual_engaged_yields_diagonal_z2_precision (mkEngineCoupling pos  neg)  piA piC _
  rewrite apportionRay-d0-x piA piC = refl
dual_engaged_yields_diagonal_z2_precision (mkEngineCoupling pos  pos)  piA piC _
  rewrite apportionRay-d0-x piA piC = refl
dual_engaged_yields_diagonal_z2_precision (mkEngineCoupling zero _)    _   _   ()
dual_engaged_yields_diagonal_z2_precision (mkEngineCoupling neg  zero) _   _   ()
dual_engaged_yields_diagonal_z2_precision (mkEngineCoupling pos  zero) _   _   ()

-- [16/23] symmetric_precision_never_lateral
deploy-sym-not-lateral :
  ∀ (c : EngineCoupling) (d pi : Nat) →
  ¬ (classifyGeometry (deployCouplingWithPrecision c d pi pi) ≡ lateral)
deploy-sym-not-lateral (mkEngineCoupling zero zero) _ _ ()
deploy-sym-not-lateral (mkEngineCoupling neg  zero) _ _ ()
deploy-sym-not-lateral (mkEngineCoupling pos  zero) _ _ ()
deploy-sym-not-lateral (mkEngineCoupling zero neg)  _ _ ()
deploy-sym-not-lateral (mkEngineCoupling zero pos)  _ _ ()
deploy-sym-not-lateral (mkEngineCoupling neg  neg)  d pi eq
  with apportionRay-sym-x d pi | apportionRay-sym-y d pi | nat-==-refl (suc d)
... | ex | ey | ed rewrite ex | ey | ed with eq
...   | ()
deploy-sym-not-lateral (mkEngineCoupling neg  pos)  d pi eq
  with apportionRay-sym-x d pi | apportionRay-sym-y d pi | nat-==-refl (suc d)
... | ex | ey | ed rewrite ex | ey | ed with eq
...   | ()
deploy-sym-not-lateral (mkEngineCoupling pos  neg)  d pi eq
  with apportionRay-sym-x d pi | apportionRay-sym-y d pi | nat-==-refl (suc d)
... | ex | ey | ed rewrite ex | ey | ed with eq
...   | ()
deploy-sym-not-lateral (mkEngineCoupling pos  pos)  d pi eq
  with apportionRay-sym-x d pi | apportionRay-sym-y d pi | nat-==-refl (suc d)
... | ex | ey | ed rewrite ex | ey | ed with eq
...   | ()

symmetric_precision_never_lateral :
  ∀ (s : PredictiveEngineState) →
  precisionA (attentional s) ≡ precisionC (attentional s) →
  ¬ (classifyGeometry (projectToCoreAffect s) ≡ lateral)
symmetric_precision_never_lateral s hEq
  with not (isSensorilySalientB (discrepancy s)) ∨b isGlobalNeutralityB (currentCoupling s)
... | true with descendingSuspension (subjective s)
...   | true  = λ ()
...   | false = λ ()
symmetric_precision_never_lateral s hEq | false
  with not (Attentional-isEngagedB (attentional s))
... | true with descendingSuspension (subjective s)
...   | true  = λ ()
...   | false = λ ()
symmetric_precision_never_lateral s hEq | false | false
  rewrite hEq = deploy-sym-not-lateral (currentCoupling s) (persistenceDepth (attentional s)) (precisionC (attentional s))

-- [17/23] projectToCoreAffect_surjective
projectToCoreAffect_surjective :
  ∀ (p : CoreAffectPoint) → IsValidCoreAffect p →
  projectToCoreAffect (witnessEngineForPoint p) ≡ p
projectToCoreAffect_surjective (mkPoint (pos zero) (pos zero) zero)          _  = refl
projectToCoreAffect_surjective (mkPoint (pos zero) (pos zero) (suc zero))    _  = refl
projectToCoreAffect_surjective (mkPoint (pos zero) (pos zero) (suc (suc d))) _  = refl
projectToCoreAffect_surjective (mkPoint (pos zero) (pos (suc _)) zero)       ()
projectToCoreAffect_surjective (mkPoint (pos zero) (pos (suc _)) (suc zero)) ()
projectToCoreAffect_surjective (mkPoint (pos zero) (pos (suc ay)) (suc (suc d))) h =
  cong (λ r → mkPoint (pos 0) (pos r) (suc (suc d))) (sym (nat-==-to-≡ (suc ay) (fullRay d) h))
projectToCoreAffect_surjective (mkPoint (pos zero) (negsuc _) zero)          ()
projectToCoreAffect_surjective (mkPoint (pos zero) (negsuc _) (suc zero))    ()
projectToCoreAffect_surjective (mkPoint (pos zero) (negsuc ay) (suc (suc d))) h =
  cong (λ r → mkPoint (pos 0) (signedAmplitude neg r) (suc (suc d))) (sym (nat-==-to-≡ (suc ay) (fullRay d) h))
projectToCoreAffect_surjective (mkPoint (pos (suc _)) (pos zero) zero)       ()
projectToCoreAffect_surjective (mkPoint (pos (suc _)) (pos zero) (suc zero)) ()
projectToCoreAffect_surjective (mkPoint (pos (suc ax)) (pos zero) (suc (suc d))) h =
  cong (λ r → mkPoint (pos r) (pos 0) (suc (suc d)))
       (trans (sym (nat-==-to-≡ (suc ax + 0) (fullRay d) h)) (+-zero-r (suc ax)))
projectToCoreAffect_surjective (mkPoint (negsuc _) (pos zero) zero)          ()
projectToCoreAffect_surjective (mkPoint (negsuc _) (pos zero) (suc zero))    ()
projectToCoreAffect_surjective (mkPoint (negsuc ax) (pos zero) (suc (suc d))) h =
  cong (λ r → mkPoint (signedAmplitude neg r) (pos 0) (suc (suc d)))
       (trans (sym (nat-==-to-≡ (suc ax + 0) (fullRay d) h)) (+-zero-r (suc ax)))
projectToCoreAffect_surjective (mkPoint (pos (suc _)) (pos (suc _)) zero)       ()
projectToCoreAffect_surjective (mkPoint (pos (suc _)) (pos (suc _)) (suc zero)) ()
projectToCoreAffect_surjective (mkPoint (pos (suc ax)) (pos (suc ay)) (suc (suc d))) h
  rewrite h =
  cong (λ ry → mkPoint (pos (suc ax)) (pos ry) (suc (suc d)))
       (trans (cong (_- suc ax) (sym (nat-==-to-≡ (suc ax + suc ay) (fullRay d) h)))
              (-ℕ-cancel (suc ax) (suc ay)))
projectToCoreAffect_surjective (mkPoint (pos (suc _)) (negsuc _) zero)       ()
projectToCoreAffect_surjective (mkPoint (pos (suc _)) (negsuc _) (suc zero)) ()
projectToCoreAffect_surjective (mkPoint (pos (suc ax)) (negsuc ay) (suc (suc d))) h
  rewrite h =
  cong (λ ry → mkPoint (pos (suc ax)) (signedAmplitude neg ry) (suc (suc d)))
       (trans (cong (_- suc ax) (sym (nat-==-to-≡ (suc ax + suc ay) (fullRay d) h)))
              (-ℕ-cancel (suc ax) (suc ay)))
projectToCoreAffect_surjective (mkPoint (negsuc _) (pos (suc _)) zero)       ()
projectToCoreAffect_surjective (mkPoint (negsuc _) (pos (suc _)) (suc zero)) ()
projectToCoreAffect_surjective (mkPoint (negsuc ax) (pos (suc ay)) (suc (suc d))) h
  rewrite h =
  cong (λ ry → mkPoint (negsuc ax) (pos ry) (suc (suc d)))
       (trans (cong (_- suc ax) (sym (nat-==-to-≡ (suc ax + suc ay) (fullRay d) h)))
              (-ℕ-cancel (suc ax) (suc ay)))
projectToCoreAffect_surjective (mkPoint (negsuc _) (negsuc _) zero)       ()
projectToCoreAffect_surjective (mkPoint (negsuc _) (negsuc _) (suc zero)) ()
projectToCoreAffect_surjective (mkPoint (negsuc ax) (negsuc ay) (suc (suc d))) h
  rewrite h =
  cong (λ ry → mkPoint (negsuc ax) (signedAmplitude neg ry) (suc (suc d)))
       (trans (cong (_- suc ax) (sym (nat-==-to-≡ (suc ax + suc ay) (fullRay d) h)))
              (-ℕ-cancel (suc ax) (suc ay)))

-- [18/23] engineStep_canonical_trajectory
engineStep_canonical_trajectory :
  ∀ (s0 : PredictiveEngineState) →
  isSensorilySalientB (discrepancy s0) ≡ true →
  isGlobalNeutralityB (currentCoupling s0) ≡ true →
  descendingSuspension (subjective s0) ≡ false →
  Attentional-isEngagedB (attentional s0) ≡ false →
  persistenceDepth (attentional s0) ≡ 0 →
  let s1 = engineStep s0
      s2 = engineStep s1
      s3 = engineStep s2
  in (projectToCoreAffect s0 ≡ mkPoint (pos 0) (pos 0) 0)
     × (projectToCoreAffect s1 ≡ mkPoint (pos 0) (pos 0) 1)
     × (projectToCoreAffect s2 ≡ mkPoint (pos 0) (pos 0) 2)
     × (projectToCoreAffect s3 ≡ mkPoint (pos 0) (pos 2) 2)
engineStep_canonical_trajectory
  (mkPredictiveEngineState d (mkPerceptiveInterface zero) (mkSubjectiveInterface zero false) att)
  hSal _ _ hAtt hDepth
  rewrite engineStep-phase1 d att hSal
        | engineStep-phase2 d zero pos att hSal refl hAtt
        | engineStep-phase3 d zero pos att hSal refl hAtt
        | hSal | hAtt | hDepth
        | Attentional-engaged-self (engagementThreshold att) 0 (precisionA att) (precisionC att) =
  refl , refl , refl , refl
engineStep_canonical_trajectory
  (mkPredictiveEngineState _ (mkPerceptiveInterface zero) (mkSubjectiveInterface zero true) _)
  _ _ () _ _
engineStep_canonical_trajectory
  (mkPredictiveEngineState _ (mkPerceptiveInterface _) (mkSubjectiveInterface neg _) _) _ () _ _ _
engineStep_canonical_trajectory
  (mkPredictiveEngineState _ (mkPerceptiveInterface _) (mkSubjectiveInterface pos _) _) _ () _ _ _
engineStep_canonical_trajectory
  (mkPredictiveEngineState _ (mkPerceptiveInterface neg) (mkSubjectiveInterface zero _) _) _ () _ _ _
engineStep_canonical_trajectory
  (mkPredictiveEngineState _ (mkPerceptiveInterface pos) (mkSubjectiveInterface zero _) _) _ () _ _ _

-- [19/23] engineStep_surprise_to_crown
engineStep_surprise_to_crown :
  ∀ (s1 : PredictiveEngineState) →
  isSensorilySalientB (discrepancy s1) ≡ true →
  isGlobalNeutralityB (currentCoupling s1) ≡ false →
  descendingSuspension (subjective s1) ≡ false →
  Attentional-isEngagedB (attentional s1) ≡ false →
  persistenceDepth (attentional s1) ≡ 0 →
  let s2 = engineStep s1
      s3 = engineStep s2
      pCrown = projectToCoreAffect s3
  in (projectToCoreAffect s1 ≡ mkPoint (pos 0) (pos 0) 1)
     × (projectToCoreAffect s2 ≡ mkPoint (pos 0) (pos 0) 2)
     × (pCrown ≡ deployCouplingWithPrecision (currentCoupling s1) 0 (precisionA (attentional s1)) (precisionC (attentional s1)))
engineStep_surprise_to_crown
  (mkPredictiveEngineState d (mkPerceptiveInterface cPol) (mkSubjectiveInterface aPol false) att)
  hSal hNotNeut _ hAtt hDepth
  rewrite engineStep-phase2 d aPol cPol att hSal hNotNeut hAtt
        | engineStep-phase3 d aPol cPol att hSal hNotNeut hAtt
        | hSal | hNotNeut | hAtt | hDepth
        | Attentional-engaged-self (engagementThreshold att) 0 (precisionA att) (precisionC att) =
  refl , refl , refl
engineStep_surprise_to_crown
  (mkPredictiveEngineState _ _ (mkSubjectiveInterface _ true) _) _ _ () _ _

-- [20/23] anticipation_short_circuits_to_veille
anticipation_short_circuits_to_veille :
  dissipationStep (mkPoint (pos 0) (pos 0) 2) ≡ mkPoint (pos 0) (pos 0) 0
anticipation_short_circuits_to_veille = refl

-- [21/23] dissipation_from_ge2_never_visits_surprise
dissipation_from_ge2_never_visits_surprise :
  ∀ (p : CoreAffectPoint) → 2 ≤ℕ pz p →
  ¬ (dissipationStep p ≡ mkPoint (pos 0) (pos 0) 1)
dissipation_from_ge2_never_visits_surprise (mkPoint _ _ zero)       ()      _
dissipation_from_ge2_never_visits_surprise (mkPoint _ _ (suc zero)) (s≤s ()) _
dissipation_from_ge2_never_visits_surprise (mkPoint x y (suc (suc zero))) _ eq
  with isCentralB (mkPoint x y 2)
... | false = z2≢1 (cong pz eq) where z2≢1 : 2 ≡ 1 → ⊥; z2≢1 ()
... | true  = z0≢1 (cong pz eq) where z0≢1 : 0 ≡ 1 → ⊥; z0≢1 ()
dissipation_from_ge2_never_visits_surprise (mkPoint x y (suc (suc (suc d)))) _ eq
  with isCentralB (mkPoint x y (suc (suc (suc d))))
... | false = z3≢1 (cong pz eq) where z3≢1 : ∀ {n} → suc (suc (suc n)) ≡ 1 → ⊥; z3≢1 ()
... | true  = z2≢1 (cong pz eq) where z2≢1 : ∀ {n} → suc (suc n) ≡ 1 → ⊥; z2≢1 ()

-- [22/23] dissipationPotential_short_circuit_jump
dissipationPotential_short_circuit_jump :
  dissipationPotential (mkPoint (pos 0) (pos 0) 2)
  - dissipationPotential (dissipationStep (mkPoint (pos 0) (pos 0) 2)) ≡ 4
dissipationPotential_short_circuit_jump = refl

-- [23/23] dissipation_reaches_veille
dissipation-central-reaches-veille :
  ∀ (z : Nat) → repeatDissipation z (mkPoint (pos 0) (pos 0) z) ≡ mkPoint (pos 0) (pos 0) 0
dissipation-central-reaches-veille zero          = refl
dissipation-central-reaches-veille (suc zero)    = refl
dissipation-central-reaches-veille (suc (suc zero)) = refl
dissipation-central-reaches-veille (suc (suc (suc d))) =
  dissipation-central-reaches-veille (suc (suc d))

dissipation-central-reaches-veille-suc :
  ∀ (z : Nat) → repeatDissipation (suc z) (mkPoint (pos 0) (pos 0) z) ≡ mkPoint (pos 0) (pos 0) 0
dissipation-central-reaches-veille-suc zero          = refl
dissipation-central-reaches-veille-suc (suc zero)    = refl
dissipation-central-reaches-veille-suc (suc (suc zero)) = refl
dissipation-central-reaches-veille-suc (suc (suc (suc d))) =
  dissipation-central-reaches-veille-suc (suc (suc d))

dissipation_reaches_veille :
  ∀ (p : CoreAffectPoint) →
  repeatDissipation (suc (pz p)) p ≡ mkPoint (pos 0) (pos 0) 0
dissipation_reaches_veille (mkPoint x y z) with isCentralB (mkPoint x y z)
... | false = dissipation-central-reaches-veille z
... | true  = dissipation-central-reaches-veille-suc z


