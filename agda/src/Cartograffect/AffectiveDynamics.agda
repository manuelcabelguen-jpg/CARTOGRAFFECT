{-# OPTIONS --safe --without-K #-}
-- Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
-- SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
-- Author: Manuel Cabelguen
--
-- Module 05 : AffectiveDynamics (Agda 2.9.0, --safe --without-K)

module Cartograffect.AffectiveDynamics where

open import Cartograffect.Prelude
open import Cartograffect.PredictiveEngine
open import Cartograffect.CoreAffect
open import Cartograffect.AffectiveMatrix
open import Cartograffect.AffectiveTaxonomy

-- ---------------------------------------------------------------------------
-- 1. Noyau stochastique inter-strates (canonicalDepthWeight)
-- ---------------------------------------------------------------------------
sameSignOrZeroB : Int → Int → Bool
sameSignOrZeroB (pos zero)    _             = true
sameSignOrZeroB _             (pos zero)    = true
sameSignOrZeroB (pos (suc _)) (pos (suc _)) = true
sameSignOrZeroB (negsuc _)    (negsuc _)    = true
sameSignOrZeroB _             _             = false

canonicalDepthWeight : CoreAffectPoint → CoreAffectPoint → Nat
canonicalDepthWeight p q =
  let px' = px p; py' = py p; pz' = pz p
      qx' = px q; qy' = py q; qz' = pz q
      ax  = absNat px'; ay = absNat py'
      bx  = absNat qx'; by = absNat qy'
  in if isValidCoreAffectB p ∧b isValidCoreAffectB q
        ∧b (qz' == suc pz')
        ∧b sameSignOrZeroB px' qx'
        ∧b sameSignOrZeroB py' qy'
     then
       (if isCentralB q then
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
           else 0))
     else 0

-- Somme des poids sortants vers la strate z + 1
sumCrownRowAtAx : CoreAffectPoint → Nat → Nat → Nat → Nat
sumCrownRowAtAx p znext zero ay =
  canonicalDepthWeight p (mkPoint (pos 0) (pos ay) znext)
  + canonicalDepthWeight p (mkPoint (pos 0) (-ℤ pos ay) znext)
sumCrownRowAtAx p znext (suc ax') zero =
  canonicalDepthWeight p (mkPoint (pos (suc ax')) (pos 0) znext)
  + canonicalDepthWeight p (mkPoint (negsuc ax') (pos 0) znext)
sumCrownRowAtAx p znext (suc ax') (suc ay') =
  canonicalDepthWeight p (mkPoint (pos (suc ax')) (pos (suc ay')) znext)
  + canonicalDepthWeight p (mkPoint (pos (suc ax')) (negsuc ay') znext)
  + canonicalDepthWeight p (mkPoint (negsuc ax') (pos (suc ay')) znext)
  + canonicalDepthWeight p (mkPoint (negsuc ax') (negsuc ay') znext)

sumCrownWeightsRec : CoreAffectPoint → Nat → Nat → Nat → Nat
sumCrownWeightsRec p znext r zero = sumCrownRowAtAx p znext zero r
sumCrownWeightsRec p znext r (suc ax) =
  sumCrownRowAtAx p znext (suc ax) (r - suc ax) + sumCrownWeightsRec p znext r ax

outgoingWeight : CoreAffectPoint → Nat
outgoingWeight p =
  let zn = suc (pz p)
      rn = crownRadius zn
  in canonicalDepthWeight p (mkPoint (pos 0) (pos 0) zn)
     + (if zn < 2 then 0 else sumCrownWeightsRec p zn rn rn)

-- Témoin constructif d'antécédent en Z - 1 pour toute position de couronne (Z >= 3)
predForCrown : CoreAffectPoint → CoreAffectPoint
predForCrown q =
  let qx'   = px q
      qy'   = py q
      qz'   = pz q
      zPrev = qz' - 1
      rPrev = crownRadius zPrev
      bx    = absNat qx'
      by    = absNat qy'
  in if isZeroℤ qx' then
       mkPoint (pos 0) (if intPosB qy' then pos rPrev else -ℤ pos rPrev) zPrev
     else if isZeroℤ qy' then
       mkPoint (if intPosB qx' then pos rPrev else -ℤ pos rPrev) (pos 0) zPrev
     else
       let ax = if leNatB 2 bx then (if leNatB 2 by then bx - 1 else bx - 2) else 1
           ay = rPrev - ax
       in mkPoint (if intPosB qx' then pos ax else -ℤ pos ax)
                  (if intPosB qy' then pos ay else -ℤ pos ay)
                  zPrev

-- Témoin constructif de successeur en Z + 1 pour tout point valide
stepOutCoord : Int → Int
stepOutCoord (pos zero)     = pos 0
stepOutCoord (pos (suc ax)) = pos (suc (suc ax))
stepOutCoord (negsuc ax)    = negsuc (suc ax)

witnessSuccForPoint : CoreAffectPoint → CoreAffectPoint
witnessSuccForPoint p =
  let zn = suc (pz p)
      rn = crownRadius zn
  in if isCentralB p then
       mkPoint (pos 0) (pos 0) zn
     else if isZeroℤ (px p) then
       mkPoint (pos 0) (if intPosB (py p) then pos rn else -ℤ pos rn) zn
     else if isZeroℤ (py p) then
       mkPoint (if intPosB (px p) then pos rn else -ℤ pos rn) (pos 0) zn
     else
       mkPoint (stepOutCoord (px p)) (stepOutCoord (py p)) zn

-- ---------------------------------------------------------------------------
-- 2. Appartenance graduée aux attracteurs (R1)
-- ---------------------------------------------------------------------------
minByOrd : Nat → Nat → Nat
minByOrd a b with natCmp a b
... | ordLT = a
... | ordEQ = a
... | ordGT = b

attractorMembership : CoreAffectPoint → TaxonomicGroup → Nat
attractorMembership (mkPoint (pos zero) (pos zero) _) operateurCentral = 1
attractorMembership (mkPoint (pos zero) (pos zero) _) _                = 0
attractorMembership (mkPoint (pos zero) (pos (suc ay)) _) groupeJoie = suc ay
attractorMembership (mkPoint (pos zero) (pos (suc _))  _) _          = 0
attractorMembership (mkPoint (pos zero) (negsuc ay)    _) groupeTristesse = suc ay
attractorMembership (mkPoint (pos zero) (negsuc _)     _) _               = 0
attractorMembership (mkPoint (pos (suc ax)) (pos zero) _) groupeCourage = suc ax
attractorMembership (mkPoint (pos (suc _))  (pos zero) _) _             = 0
attractorMembership (mkPoint (negsuc ax)    (pos zero) _) groupePeur = suc ax
attractorMembership (mkPoint (negsuc _)     (pos zero) _) _          = 0
attractorMembership (mkPoint (pos (suc ax)) (pos (suc ay)) _) g with natCmp ax ay
... | ordLT with g
...   | groupeJoie    = suc ax + suc ay
...   | groupeCourage = suc ax
...   | groupeDesir   = suc ax + suc ax
...   | _             = 0
attractorMembership (mkPoint (pos (suc ax)) (pos (suc ay)) _) g | ordEQ with g
...   | groupeJoie    = suc ay
...   | groupeCourage = suc ax
...   | groupeDesir   = suc ax + suc ax
...   | _             = 0
attractorMembership (mkPoint (pos (suc ax)) (pos (suc ay)) _) g | ordGT with g
...   | groupeJoie    = suc ay
...   | groupeCourage = suc ax + suc ay
...   | groupeDesir   = suc ay + suc ay
...   | _             = 0
attractorMembership (mkPoint (negsuc ax) (pos (suc ay)) _) g with natCmp ax ay
... | ordLT with g
...   | groupeJoie   = suc ax + suc ay
...   | groupePeur   = suc ax
...   | groupeColere = suc ax + suc ax
...   | _            = 0
attractorMembership (mkPoint (negsuc ax) (pos (suc ay)) _) g | ordEQ with g
...   | groupeJoie   = suc ay
...   | groupePeur   = suc ax
...   | groupeColere = suc ax + suc ax
...   | _            = 0
attractorMembership (mkPoint (negsuc ax) (pos (suc ay)) _) g | ordGT with g
...   | groupeJoie   = suc ay
...   | groupePeur   = suc ax + suc ay
...   | groupeColere = suc ay + suc ay
...   | _            = 0
attractorMembership (mkPoint (pos (suc ax)) (negsuc ay) _) g with natCmp ax ay
... | ordLT with g
...   | groupeTristesse = suc ax + suc ay
...   | groupeCourage   = suc ax
...   | groupeCalme     = suc ax + suc ax
...   | _               = 0
attractorMembership (mkPoint (pos (suc ax)) (negsuc ay) _) g | ordEQ with g
...   | groupeTristesse = suc ay
...   | groupeCourage   = suc ax
...   | groupeCalme     = suc ax + suc ax
...   | _               = 0
attractorMembership (mkPoint (pos (suc ax)) (negsuc ay) _) g | ordGT with g
...   | groupeTristesse = suc ay
...   | groupeCourage   = suc ax + suc ay
...   | groupeCalme     = suc ay + suc ay
...   | _               = 0
attractorMembership (mkPoint (negsuc ax) (negsuc ay) _) g with natCmp ax ay
... | ordLT with g
...   | groupeTristesse = suc ax + suc ay
...   | groupePeur      = suc ax
...   | groupeDegout    = suc ax + suc ax
...   | _               = 0
attractorMembership (mkPoint (negsuc ax) (negsuc ay) _) g | ordEQ with g
...   | groupeTristesse = suc ay
...   | groupePeur      = suc ax
...   | groupeDegout    = suc ax + suc ax
...   | _               = 0
attractorMembership (mkPoint (negsuc ax) (negsuc ay) _) g | ordGT with g
...   | groupeTristesse = suc ay
...   | groupePeur      = suc ax + suc ay
...   | groupeDegout    = suc ay + suc ay
...   | _               = 0

-- ---------------------------------------------------------------------------
-- 3. Lemmes d'ordre sur natCmp et les 10 théorèmes d'AffectiveDynamics
-- ---------------------------------------------------------------------------
natCmp-LT-to-< : ∀ (a b : Nat) → natCmp a b ≡ ordLT → suc a <ℕ suc b
natCmp-LT-to-< zero    zero    ()
natCmp-LT-to-< zero    (suc _) _  = s≤s (s≤s z≤n)
natCmp-LT-to-< (suc _) zero    ()
natCmp-LT-to-< (suc a) (suc b) h  = s≤s (natCmp-LT-to-< a b h)

natCmp-GT-to-< : ∀ (a b : Nat) → natCmp a b ≡ ordGT → suc b <ℕ suc a
natCmp-GT-to-< zero    zero    ()
natCmp-GT-to-< zero    (suc _) ()
natCmp-GT-to-< (suc _) zero    _  = s≤s (s≤s z≤n)
natCmp-GT-to-< (suc a) (suc b) h  = s≤s (natCmp-GT-to-< a b h)

natCmp-EQ-to-≡ : ∀ (a b : Nat) → natCmp a b ≡ ordEQ → a ≡ b
natCmp-EQ-to-≡ zero    zero    _  = refl
natCmp-EQ-to-≡ zero    (suc _) ()
natCmp-EQ-to-≡ (suc _) zero    ()
natCmp-EQ-to-≡ (suc a) (suc b) h  = cong suc (natCmp-EQ-to-≡ a b h)

lt-add-pos-r : ∀ (a b : Nat) → suc a <ℕ (suc a + suc b)
lt-add-pos-r zero    b = s≤s (s≤s z≤n)
lt-add-pos-r (suc a) b = s≤s (lt-add-pos-r a b)

lt-add-pos-l : ∀ (a b : Nat) → suc b <ℕ (suc a + suc b)
lt-add-pos-l a b = subst (suc b <ℕ_) (+-comm (suc b) (suc a)) (lt-add-pos-r b a)

lt-sum-of-lt-r : ∀ {a b : Nat} → a <ℕ b → (a + a) <ℕ (a + b)
lt-sum-of-lt-r {zero}      h = h
lt-sum-of-lt-r {suc a} {b} h = s≤s (subst (_≤ℕ (a + b)) (+-suc-r a (suc a)) (+-mono-≤ (≤ℕ-refl a) h))

lt-sum-of-lt-l : ∀ {a b : Nat} → b <ℕ a → (b + b) <ℕ (a + b)
lt-sum-of-lt-l {a} {b} h = subst ((b + b) <ℕ_) (+-comm b a) (lt-sum-of-lt-r h)

-- Lois auxiliaires du noyau inter-strates
canonicalDepthKernel_support_adjacent :
  ∀ (p q : CoreAffectPoint) →
  1 ≤ℕ canonicalDepthWeight p q →
  pz q ≡ suc (pz p)
canonicalDepthKernel_support_adjacent p q = aux (pz q == suc (pz p)) refl
  where
    aux : ∀ (bz : Bool) → (pz q == suc (pz p)) ≡ bz →
          1 ≤ℕ canonicalDepthWeight p q →
          pz q ≡ suc (pz p)
    aux true zEq _ = nat-==-to-≡ (pz q) (suc (pz p)) zEq
    aux false zEq rewrite zEq with isValidCoreAffectB p | isValidCoreAffectB q
    ... | false | _     = λ ()
    ... | true  | false = λ ()
    ... | true  | true  = λ ()

-- [1/10] canonicalDepthKernel_reaches_crown
canonicalDepthKernel_reaches_crown :
  ∀ (q : CoreAffectPoint) →
  pz (predForCrown q) ≡ pz q - 1
canonicalDepthKernel_reaches_crown q
  with isZeroℤ (px q)
... | true  = refl
... | false with isZeroℤ (py q)
...   | true  = refl
...   | false = refl

-- [2/10] canonicalDepthKernel_reaches_lateral
canonicalDepthKernel_reaches_lateral :
  ∀ (q : CoreAffectPoint) →
  classifyGeometry q ≡ lateral →
  (isZeroℤ (px q) ≡ false) × (isZeroℤ (py q) ≡ false) × ((absNat (px q) == absNat (py q)) ≡ false)
canonicalDepthKernel_reaches_lateral q with isCentralB q
... | true  = λ ()
... | false with isZeroℤ (px q) | isZeroℤ (py q)
...   | true  | _     = λ ()
...   | false | true  = λ ()
...   | false | false with absNat (px q) == absNat (py q)
...     | true  = λ ()
...     | false = λ _ → refl , refl , refl

-- [3/10] lateral_reachable
lateral_reachable :
  ∀ (q : CoreAffectPoint) →
  classifyGeometry q ≡ lateral →
  (isZeroℤ (px q) ≡ false) × (isZeroℤ (py q) ≡ false) × ((absNat (px q) == absNat (py q)) ≡ false)
lateral_reachable = canonicalDepthKernel_reaches_lateral

-- [4/10] lateral_reachable_from_surprise
lateral_reachable_from_surprise :
  ∀ (q : CoreAffectPoint) →
  IsValidCoreAffect q → pz q ≡ 2 → isCentralB q ≡ false →
  canonicalDepthWeight (mkPoint (pos 0) (pos 0) 1) q ≡ 1
lateral_reachable_from_surprise q hVal refl hNotCent
  rewrite hNotCent | hVal = refl

-- [5/10] canonicalDepthKernel_colere_bifurcates
canonicalDepthKernel_colere_bifurcates :
  (canonicalDepthWeight (mkPoint (negsuc 0) (pos 1) 2) (mkPoint (negsuc 1) (pos 2) 3) ≡ 2)
  × (canonicalDepthWeight (mkPoint (negsuc 0) (pos 1) 2) (mkPoint (negsuc 0) (pos 3) 3) ≡ 1)
  × (canonicalDepthWeight (mkPoint (negsuc 0) (pos 1) 2) (mkPoint (negsuc 2) (pos 1) 3) ≡ 1)
canonicalDepthKernel_colere_bifurcates = refl , refl , refl

-- [6/10] canonicalDepthKernel_axial_instability_p2
canonicalDepthKernel_axial_instability_p2 :
  (canonicalDepthWeight (mkPoint (pos 0) (pos 2) 2) (mkPoint (pos 0)    (pos 4) 3)
   <ℕ canonicalDepthWeight (mkPoint (pos 0) (pos 2) 2) (mkPoint (pos 2)    (pos 2) 3))
  × (canonicalDepthWeight (mkPoint (pos 0) (pos 2) 2) (mkPoint (pos 0)    (pos 4) 3)
     <ℕ canonicalDepthWeight (mkPoint (pos 0) (pos 2) 2) (mkPoint (negsuc 1) (pos 2) 3))
canonicalDepthKernel_axial_instability_p2 = s≤s (s≤s z≤n) , s≤s (s≤s z≤n)

-- [7/10] canonicalDepthKernel_outgoingWeight_pos
canonicalDepthKernel_outgoingWeight_pos :
  ∀ (p : CoreAffectPoint) →
  pz (witnessSuccForPoint p) ≡ suc (pz p)
canonicalDepthKernel_outgoingWeight_pos p
  with isCentralB p
... | true  = refl
... | false with isZeroℤ (px p)
...   | true  = refl
...   | false with isZeroℤ (py p)
...     | true  = refl
...     | false = refl

-- [8/10] classifyTaxonomicGroup_unique_maximizer
classifyTaxonomicGroup_unique_maximizer :
  ∀ (p : CoreAffectPoint) (g : TaxonomicGroup) →
  ¬ (g ≡ classifyTaxonomicGroup p) →
  attractorMembership p g <ℕ attractorMembership p (classifyTaxonomicGroup p)
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos zero) _) operateurCentral ne = ⊥-elim (ne refl)
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos zero) _) groupeJoie       _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos zero) _) groupeTristesse  _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos zero) _) groupePeur       _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos zero) _) groupeCourage    _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos zero) _) groupeDesir      _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos zero) _) groupeDegout     _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos zero) _) groupeColere     _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos zero) _) groupeCalme      _  = s≤s z≤n

classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos (suc _)) _) operateurCentral _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos (suc _)) _) groupeJoie       ne = ⊥-elim (ne refl)
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos (suc _)) _) groupeTristesse  _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos (suc _)) _) groupePeur       _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos (suc _)) _) groupeCourage    _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos (suc _)) _) groupeDesir      _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos (suc _)) _) groupeDegout     _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos (suc _)) _) groupeColere     _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (pos (suc _)) _) groupeCalme      _  = s≤s z≤n

classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (negsuc _) _) operateurCentral _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (negsuc _) _) groupeJoie       _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (negsuc _) _) groupeTristesse  ne = ⊥-elim (ne refl)
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (negsuc _) _) groupePeur       _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (negsuc _) _) groupeCourage    _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (negsuc _) _) groupeDesir      _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (negsuc _) _) groupeDegout     _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (negsuc _) _) groupeColere     _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos zero) (negsuc _) _) groupeCalme      _  = s≤s z≤n

classifyTaxonomicGroup_unique_maximizer (mkPoint (pos (suc _)) (pos zero) _) operateurCentral _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos (suc _)) (pos zero) _) groupeJoie       _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos (suc _)) (pos zero) _) groupeTristesse  _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos (suc _)) (pos zero) _) groupePeur       _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos (suc _)) (pos zero) _) groupeCourage    ne = ⊥-elim (ne refl)
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos (suc _)) (pos zero) _) groupeDesir      _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos (suc _)) (pos zero) _) groupeDegout     _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos (suc _)) (pos zero) _) groupeColere     _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (pos (suc _)) (pos zero) _) groupeCalme      _  = s≤s z≤n

classifyTaxonomicGroup_unique_maximizer (mkPoint (negsuc _) (pos zero) _) operateurCentral _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (negsuc _) (pos zero) _) groupeJoie       _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (negsuc _) (pos zero) _) groupeTristesse  _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (negsuc _) (pos zero) _) groupePeur       ne = ⊥-elim (ne refl)
classifyTaxonomicGroup_unique_maximizer (mkPoint (negsuc _) (pos zero) _) groupeCourage    _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (negsuc _) (pos zero) _) groupeDesir      _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (negsuc _) (pos zero) _) groupeDegout     _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (negsuc _) (pos zero) _) groupeColere     _  = s≤s z≤n
classifyTaxonomicGroup_unique_maximizer (mkPoint (negsuc _) (pos zero) _) groupeCalme      _  = s≤s z≤n

classifyTaxonomicGroup_unique_maximizer (mkPoint (pos (suc ax)) (pos (suc ay)) z) g ne =
  aux g (natCmp ax ay) refl ne
  where
    pt = mkPoint (pos (suc ax)) (pos (suc ay)) z
    aux : ∀ (gv : TaxonomicGroup) (o : NatOrd) → natCmp ax ay ≡ o →
          ¬ (gv ≡ classifyTaxonomicGroup pt) →
          attractorMembership pt gv <ℕ attractorMembership pt (classifyTaxonomicGroup pt)
    aux gv ordLT cEq ne' rewrite cEq with gv
    ... | operateurCentral = s≤s z≤n
    ... | groupeJoie       = ⊥-elim (ne' refl)
    ... | groupeTristesse  = s≤s z≤n
    ... | groupePeur       = s≤s z≤n
    ... | groupeCourage    = lt-add-pos-r ax ay
    ... | groupeDesir      = lt-sum-of-lt-r (natCmp-LT-to-< ax ay cEq)
    ... | groupeDegout     = s≤s z≤n
    ... | groupeColere     = s≤s z≤n
    ... | groupeCalme      = s≤s z≤n
    aux gv ordEQ cEq ne' rewrite cEq with gv
    ... | operateurCentral = s≤s z≤n
    ... | groupeJoie       = subst (_<ℕ (suc ax + suc ax)) (cong suc (natCmp-EQ-to-≡ ax ay cEq)) (lt-add-pos-r ax ax)
    ... | groupeTristesse  = s≤s z≤n
    ... | groupePeur       = s≤s z≤n
    ... | groupeCourage    = lt-add-pos-r ax ax
    ... | groupeDesir      = ⊥-elim (ne' refl)
    ... | groupeDegout     = s≤s z≤n
    ... | groupeColere     = s≤s z≤n
    ... | groupeCalme      = s≤s z≤n
    aux gv ordGT cEq ne' rewrite cEq with gv
    ... | operateurCentral = s≤s z≤n
    ... | groupeJoie       = lt-add-pos-l ax ay
    ... | groupeTristesse  = s≤s z≤n
    ... | groupePeur       = s≤s z≤n
    ... | groupeCourage    = ⊥-elim (ne' refl)
    ... | groupeDesir      = lt-sum-of-lt-l (natCmp-GT-to-< ax ay cEq)
    ... | groupeDegout     = s≤s z≤n
    ... | groupeColere     = s≤s z≤n
    ... | groupeCalme      = s≤s z≤n

classifyTaxonomicGroup_unique_maximizer (mkPoint (negsuc ax) (pos (suc ay)) z) g ne =
  aux g (natCmp ax ay) refl ne
  where
    pt = mkPoint (negsuc ax) (pos (suc ay)) z
    aux : ∀ (gv : TaxonomicGroup) (o : NatOrd) → natCmp ax ay ≡ o →
          ¬ (gv ≡ classifyTaxonomicGroup pt) →
          attractorMembership pt gv <ℕ attractorMembership pt (classifyTaxonomicGroup pt)
    aux gv ordLT cEq ne' rewrite cEq with gv
    ... | operateurCentral = s≤s z≤n
    ... | groupeJoie       = ⊥-elim (ne' refl)
    ... | groupeTristesse  = s≤s z≤n
    ... | groupePeur       = lt-add-pos-r ax ay
    ... | groupeCourage    = s≤s z≤n
    ... | groupeDesir      = s≤s z≤n
    ... | groupeDegout     = s≤s z≤n
    ... | groupeColere     = lt-sum-of-lt-r (natCmp-LT-to-< ax ay cEq)
    ... | groupeCalme      = s≤s z≤n
    aux gv ordEQ cEq ne' rewrite cEq with gv
    ... | operateurCentral = s≤s z≤n
    ... | groupeJoie       = subst (_<ℕ (suc ax + suc ax)) (cong suc (natCmp-EQ-to-≡ ax ay cEq)) (lt-add-pos-r ax ax)
    ... | groupeTristesse  = s≤s z≤n
    ... | groupePeur       = lt-add-pos-r ax ax
    ... | groupeCourage    = s≤s z≤n
    ... | groupeDesir      = s≤s z≤n
    ... | groupeDegout     = s≤s z≤n
    ... | groupeColere     = ⊥-elim (ne' refl)
    ... | groupeCalme      = s≤s z≤n
    aux gv ordGT cEq ne' rewrite cEq with gv
    ... | operateurCentral = s≤s z≤n
    ... | groupeJoie       = lt-add-pos-l ax ay
    ... | groupeTristesse  = s≤s z≤n
    ... | groupePeur       = ⊥-elim (ne' refl)
    ... | groupeCourage    = s≤s z≤n
    ... | groupeDesir      = s≤s z≤n
    ... | groupeDegout     = s≤s z≤n
    ... | groupeColere     = lt-sum-of-lt-l (natCmp-GT-to-< ax ay cEq)
    ... | groupeCalme      = s≤s z≤n

classifyTaxonomicGroup_unique_maximizer (mkPoint (pos (suc ax)) (negsuc ay) z) g ne =
  aux g (natCmp ax ay) refl ne
  where
    pt = mkPoint (pos (suc ax)) (negsuc ay) z
    aux : ∀ (gv : TaxonomicGroup) (o : NatOrd) → natCmp ax ay ≡ o →
          ¬ (gv ≡ classifyTaxonomicGroup pt) →
          attractorMembership pt gv <ℕ attractorMembership pt (classifyTaxonomicGroup pt)
    aux gv ordLT cEq ne' rewrite cEq with gv
    ... | operateurCentral = s≤s z≤n
    ... | groupeJoie       = s≤s z≤n
    ... | groupeTristesse  = ⊥-elim (ne' refl)
    ... | groupePeur       = s≤s z≤n
    ... | groupeCourage    = lt-add-pos-r ax ay
    ... | groupeDesir      = s≤s z≤n
    ... | groupeDegout     = s≤s z≤n
    ... | groupeColere     = s≤s z≤n
    ... | groupeCalme      = lt-sum-of-lt-r (natCmp-LT-to-< ax ay cEq)
    aux gv ordEQ cEq ne' rewrite cEq with gv
    ... | operateurCentral = s≤s z≤n
    ... | groupeJoie       = s≤s z≤n
    ... | groupeTristesse  = subst (_<ℕ (suc ax + suc ax)) (cong suc (natCmp-EQ-to-≡ ax ay cEq)) (lt-add-pos-r ax ax)
    ... | groupePeur       = s≤s z≤n
    ... | groupeCourage    = lt-add-pos-r ax ax
    ... | groupeDesir      = s≤s z≤n
    ... | groupeDegout     = s≤s z≤n
    ... | groupeColere     = s≤s z≤n
    ... | groupeCalme      = ⊥-elim (ne' refl)
    aux gv ordGT cEq ne' rewrite cEq with gv
    ... | operateurCentral = s≤s z≤n
    ... | groupeJoie       = s≤s z≤n
    ... | groupeTristesse  = lt-add-pos-l ax ay
    ... | groupePeur       = s≤s z≤n
    ... | groupeCourage    = ⊥-elim (ne' refl)
    ... | groupeDesir      = s≤s z≤n
    ... | groupeDegout     = s≤s z≤n
    ... | groupeColere     = s≤s z≤n
    ... | groupeCalme      = lt-sum-of-lt-l (natCmp-GT-to-< ax ay cEq)

classifyTaxonomicGroup_unique_maximizer (mkPoint (negsuc ax) (negsuc ay) z) g ne =
  aux g (natCmp ax ay) refl ne
  where
    pt = mkPoint (negsuc ax) (negsuc ay) z
    aux : ∀ (gv : TaxonomicGroup) (o : NatOrd) → natCmp ax ay ≡ o →
          ¬ (gv ≡ classifyTaxonomicGroup pt) →
          attractorMembership pt gv <ℕ attractorMembership pt (classifyTaxonomicGroup pt)
    aux gv ordLT cEq ne' rewrite cEq with gv
    ... | operateurCentral = s≤s z≤n
    ... | groupeJoie       = s≤s z≤n
    ... | groupeTristesse  = ⊥-elim (ne' refl)
    ... | groupePeur       = lt-add-pos-r ax ay
    ... | groupeCourage    = s≤s z≤n
    ... | groupeDesir      = s≤s z≤n
    ... | groupeDegout     = lt-sum-of-lt-r (natCmp-LT-to-< ax ay cEq)
    ... | groupeColere     = s≤s z≤n
    ... | groupeCalme      = s≤s z≤n
    aux gv ordEQ cEq ne' rewrite cEq with gv
    ... | operateurCentral = s≤s z≤n
    ... | groupeJoie       = s≤s z≤n
    ... | groupeTristesse  = subst (_<ℕ (suc ax + suc ax)) (cong suc (natCmp-EQ-to-≡ ax ay cEq)) (lt-add-pos-r ax ax)
    ... | groupePeur       = lt-add-pos-r ax ax
    ... | groupeCourage    = s≤s z≤n
    ... | groupeDesir      = s≤s z≤n
    ... | groupeDegout     = ⊥-elim (ne' refl)
    ... | groupeColere     = s≤s z≤n
    ... | groupeCalme      = s≤s z≤n
    aux gv ordGT cEq ne' rewrite cEq with gv
    ... | operateurCentral = s≤s z≤n
    ... | groupeJoie       = s≤s z≤n
    ... | groupeTristesse  = lt-add-pos-l ax ay
    ... | groupePeur       = ⊥-elim (ne' refl)
    ... | groupeCourage    = s≤s z≤n
    ... | groupeDesir      = s≤s z≤n
    ... | groupeDegout     = lt-sum-of-lt-l (natCmp-GT-to-< ax ay cEq)
    ... | groupeColere     = s≤s z≤n
    ... | groupeCalme      = s≤s z≤n

-- [9/10] classifyTaxonomicGroup_maximizes_membership
classifyTaxonomicGroup_maximizes_membership :
  ∀ (p : CoreAffectPoint) (g : TaxonomicGroup) →
  attractorMembership p g ≤ℕ attractorMembership p (classifyTaxonomicGroup p)
classifyTaxonomicGroup_maximizes_membership p g =
  aux (eqTaxonomicGroupB g (classifyTaxonomicGroup p)) refl
  where
    false≢true : false ≡ true → ⊥
    false≢true ()
    aux : ∀ (b : Bool) → eqTaxonomicGroupB g (classifyTaxonomicGroup p) ≡ b →
          attractorMembership p g ≤ℕ attractorMembership p (classifyTaxonomicGroup p)
    aux true gEq =
      subst (λ x → attractorMembership p x ≤ℕ attractorMembership p (classifyTaxonomicGroup p))
            (sym (eqTaxonomicGroupB-to-≡ g (classifyTaxonomicGroup p) gEq))
            (≤ℕ-refl (attractorMembership p (classifyTaxonomicGroup p)))
    aux false gNeq =
      <ℕ-to-≤ℕ (classifyTaxonomicGroup_unique_maximizer p g
        (λ eq → false≢true (trans (sym gNeq)
                             (trans (cong (λ x → eqTaxonomicGroupB x (classifyTaxonomicGroup p)) eq)
                                    (eqTaxonomicGroupB-refl (classifyTaxonomicGroup p))))))

-- [10/10] lateral_has_overlapping_attractors
lateral_has_overlapping_attractors :
  ∀ (p : CoreAffectPoint) →
  classifyGeometry p ≡ lateral →
  Σ TaxonomicGroup (λ g1 → Σ TaxonomicGroup (λ g2 →
    ¬ (g1 ≡ g2) × (1 ≤ℕ attractorMembership p g1) × (1 ≤ℕ attractorMembership p g2)))
lateral_has_overlapping_attractors (mkPoint (pos zero)     (pos zero)     _) ()
lateral_has_overlapping_attractors (mkPoint (pos zero)     (pos (suc _))  _) ()
lateral_has_overlapping_attractors (mkPoint (pos zero)     (negsuc _)     _) ()
lateral_has_overlapping_attractors (mkPoint (pos (suc _))  (pos zero)     _) ()
lateral_has_overlapping_attractors (mkPoint (negsuc _)     (pos zero)     _) ()
lateral_has_overlapping_attractors (mkPoint (pos (suc ax)) (pos (suc ay)) _) h with natCmp ax ay
... | ordLT = groupeJoie ,, (groupeDesir ,, ((λ ()) , s≤s z≤n , s≤s z≤n))
... | ordGT = groupeJoie ,, (groupeDesir ,, ((λ ()) , s≤s z≤n , s≤s z≤n))
... | ordEQ = groupeJoie ,, (groupeDesir ,, ((λ ()) , s≤s z≤n , s≤s z≤n))
lateral_has_overlapping_attractors (mkPoint (negsuc ax)    (pos (suc ay)) _) h with natCmp ax ay
... | ordLT = groupeJoie ,, (groupeColere ,, ((λ ()) , s≤s z≤n , s≤s z≤n))
... | ordGT = groupeJoie ,, (groupeColere ,, ((λ ()) , s≤s z≤n , s≤s z≤n))
... | ordEQ = groupeJoie ,, (groupeColere ,, ((λ ()) , s≤s z≤n , s≤s z≤n))
lateral_has_overlapping_attractors (mkPoint (pos (suc ax)) (negsuc ay)    _) h with natCmp ax ay
... | ordLT = groupeTristesse ,, (groupeCalme ,, ((λ ()) , s≤s z≤n , s≤s z≤n))
... | ordGT = groupeTristesse ,, (groupeCalme ,, ((λ ()) , s≤s z≤n , s≤s z≤n))
... | ordEQ = groupeTristesse ,, (groupeCalme ,, ((λ ()) , s≤s z≤n , s≤s z≤n))
lateral_has_overlapping_attractors (mkPoint (negsuc ax)    (negsuc ay)    _) h with natCmp ax ay
... | ordLT = groupeTristesse ,, (groupeDegout ,, ((λ ()) , s≤s z≤n , s≤s z≤n))
... | ordGT = groupeTristesse ,, (groupeDegout ,, ((λ ()) , s≤s z≤n , s≤s z≤n))
... | ordEQ = groupeTristesse ,, (groupeDegout ,, ((λ ()) , s≤s z≤n , s≤s z≤n))
