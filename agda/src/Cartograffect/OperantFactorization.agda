{-# OPTIONS --safe --without-K #-}
-- Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
-- SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
-- Author: Manuel Cabelguen
--
-- Module dérivé : OperantFactorization (Agda 2.9.0, --safe --without-K)
-- Factorisation structurale des contingences opérantes sur la couronne Z = 2

module Cartograffect.OperantFactorization where

open import Cartograffect.Prelude
open import Cartograffect.CoreAffect
open import Cartograffect.AffectiveMatrix

-- ---------------------------------------------------------------------------
-- 1. Utilitaires locaux (Maybe, équivalence logique ↔, prototypes Z = 2)
-- ---------------------------------------------------------------------------
data Maybe (A : Set) : Set where
  nothing : Maybe A
  just    : A → Maybe A

_↔_ : Set → Set → Set
A ↔ B = (A → B) × (B → A)

infixr 2 _↔_

data PrimaryCrownPrototype : Set where
  protoJoie      : PrimaryCrownPrototype
  protoTristesse : PrimaryCrownPrototype
  protoPeur      : PrimaryCrownPrototype
  protoCourage   : PrimaryCrownPrototype
  protoDesir     : PrimaryCrownPrototype
  protoDegout    : PrimaryCrownPrototype
  protoColere    : PrimaryCrownPrototype
  protoCalme     : PrimaryCrownPrototype

prototypeToPoint : PrimaryCrownPrototype → CoreAffectPoint
prototypeToPoint protoJoie      = mkPoint (pos 0)    (pos 2)    2
prototypeToPoint protoTristesse = mkPoint (pos 0)    (negsuc 1) 2
prototypeToPoint protoPeur      = mkPoint (negsuc 1) (pos 0)    2
prototypeToPoint protoCourage   = mkPoint (pos 2)    (pos 0)    2
prototypeToPoint protoDesir     = mkPoint (pos 1)    (pos 1)    2
prototypeToPoint protoDegout    = mkPoint (negsuc 0) (negsuc 0) 2
prototypeToPoint protoColere    = mkPoint (negsuc 0) (pos 1)    2
prototypeToPoint protoCalme     = mkPoint (pos 1)    (negsuc 0) 2

-- ---------------------------------------------------------------------------
-- 2. Métrique L1 intra-plan et projection opérante {R+, R-, P+, P-}
-- ---------------------------------------------------------------------------
manhattanDistXY : CoreAffectPoint → CoreAffectPoint → Nat
manhattanDistXY p q = absNat (px p -ℤ px q) + absNat (py p -ℤ py q)

subZero-ℤ : ∀ (x : Int) → (x -ℤ pos 0) ≡ x
subZero-ℤ (pos a)    = cong pos (+-zero-r a)
subZero-ℤ (negsuc _) = refl

-- [1/7] manhattanDistXY_origin
manhattanDistXY_origin :
  ∀ (p : CoreAffectPoint) →
  manhattanDistXY p (mkPoint (pos 0) (pos 0) (pz p)) ≡ displacementSum p
manhattanDistXY_origin (mkPoint x y _) =
  cong₂ (λ dx dy → absNat dx + absNat dy) (subZero-ℤ x) (subZero-ℤ y)

data OperantEffect : Set where
  reinforcement : OperantEffect
  punishment    : OperantEffect

data OperantOperator : Set where
  addition : OperantOperator
  removal  : OperantOperator

record OperantContingency : Set where
  constructor mkOperantContingency
  field
    opEffect   : OperantEffect
    opOperator : OperantOperator

open OperantContingency public

diagToContingency : CoreAffectPoint → Maybe OperantContingency
diagToContingency (mkPoint (pos 1)    (pos 1)    2) = just (mkOperantContingency reinforcement addition)
diagToContingency (mkPoint (pos 1)    (negsuc 0) 2) = just (mkOperantContingency reinforcement removal)
diagToContingency (mkPoint (negsuc 0) (negsuc 0) 2) = just (mkOperantContingency punishment    addition)
diagToContingency (mkPoint (negsuc 0) (pos 1)    2) = just (mkOperantContingency punishment    removal)
diagToContingency _                                 = nothing

prototypeToContingency : PrimaryCrownPrototype → Maybe OperantContingency
prototypeToContingency proto = diagToContingency (prototypeToPoint proto)

z2DiagonalPoints : List CoreAffectPoint
z2DiagonalPoints =
    prototypeToPoint protoDesir
  ∷ prototypeToPoint protoCalme
  ∷ prototypeToPoint protoDegout
  ∷ prototypeToPoint protoColere
  ∷ []

z2AxialPoints : List CoreAffectPoint
z2AxialPoints =
    prototypeToPoint protoCourage
  ∷ prototypeToPoint protoPeur
  ∷ prototypeToPoint protoJoie
  ∷ prototypeToPoint protoTristesse
  ∷ []

-- ---------------------------------------------------------------------------
-- 3. Prédicats de spécification et 6 théorèmes restants
-- ---------------------------------------------------------------------------
OperantFactorizationSpec : CoreAffectPoint → Maybe OperantContingency → Set
OperantFactorizationSpec _ nothing  = ⊥
OperantFactorizationSpec p (just c) =
    ((opEffect c ≡ reinforcement) ↔ (px p ≡ pos 1))
  × ((opEffect c ≡ punishment) ↔ (px p ≡ negsuc 0))
  × ((opOperator c ≡ addition) ↔ ((px p *ℤ py p) ≡ pos 1))
  × ((opOperator c ≡ removal) ↔ ((px p *ℤ py p) ≡ negsuc 0))
  × (((c ≡ mkOperantContingency reinforcement addition)
      ⊎ (c ≡ mkOperantContingency punishment removal)) ↔ (py p ≡ pos 1))
  × ((computeHedonicPolarity (px p) (py p) ≡ hedPositive) ↔ (opEffect c ≡ reinforcement))

-- [2/7] operant_factorization_law
operant_factorization_law :
  ∀ (p : CoreAffectPoint) → p ∈ z2DiagonalPoints →
  OperantFactorizationSpec p (diagToContingency p)
operant_factorization_law .(prototypeToPoint protoDesir) here =
    ((λ _ → refl) , (λ _ → refl))
  , ((λ ()) , (λ ()))
  , ((λ _ → refl) , (λ _ → refl))
  , ((λ ()) , (λ ()))
  , ((λ _ → refl) , (λ _ → inj₁ refl))
  , ((λ _ → refl) , (λ _ → refl))
operant_factorization_law .(prototypeToPoint protoCalme) (there here) =
    ((λ _ → refl) , (λ _ → refl))
  , ((λ ()) , (λ ()))
  , ((λ ()) , (λ ()))
  , ((λ _ → refl) , (λ _ → refl))
  , ((λ { (inj₁ ()) ; (inj₂ ()) }) , (λ ()))
  , ((λ _ → refl) , (λ _ → refl))
operant_factorization_law .(prototypeToPoint protoDegout) (there (there here)) =
    ((λ ()) , (λ ()))
  , ((λ _ → refl) , (λ _ → refl))
  , ((λ _ → refl) , (λ _ → refl))
  , ((λ ()) , (λ ()))
  , ((λ { (inj₁ ()) ; (inj₂ ()) }) , (λ ()))
  , ((λ ()) , (λ ()))
operant_factorization_law .(prototypeToPoint protoColere) (there (there (there here))) =
    ((λ ()) , (λ ()))
  , ((λ _ → refl) , (λ _ → refl))
  , ((λ ()) , (λ ()))
  , ((λ _ → refl) , (λ _ → refl))
  , ((λ _ → refl) , (λ _ → inj₂ refl))
  , ((λ ()) , (λ ()))
operant_factorization_law _ (there (there (there (there ()))))

EnergyRegimeOperantSpec : CoreAffectPoint → Maybe OperantContingency → Set
EnergyRegimeOperantSpec _ nothing  = ⊥
EnergyRegimeOperantSpec p (just c) =
    ((opOperator c ≡ addition) ↔
      ((computeEnergyRegime (px p) (py p) ≡ positiveSynergy)
       ⊎ (computeEnergyRegime (px p) (py p) ≡ negativeSynergy)))
  × ((opOperator c ≡ removal) ↔
      ((computeEnergyRegime (px p) (py p) ≡ ergotropicCompensation)
       ⊎ (computeEnergyRegime (px p) (py p) ≡ trophotropicRelease)))

-- [3/7] energyRegime_matches_operant_operator
energyRegime_matches_operant_operator :
  ∀ (p : CoreAffectPoint) → p ∈ z2DiagonalPoints →
  EnergyRegimeOperantSpec p (diagToContingency p)
energyRegime_matches_operant_operator .(prototypeToPoint protoDesir) here =
    ((λ _ → inj₁ refl) , (λ _ → refl))
  , ((λ ()) , (λ { (inj₁ ()) ; (inj₂ ()) }))
energyRegime_matches_operant_operator .(prototypeToPoint protoCalme) (there here) =
    ((λ ()) , (λ { (inj₁ ()) ; (inj₂ ()) }))
  , ((λ _ → inj₂ refl) , (λ _ → refl))
energyRegime_matches_operant_operator .(prototypeToPoint protoDegout) (there (there here)) =
    ((λ _ → inj₂ refl) , (λ _ → refl))
  , ((λ ()) , (λ { (inj₁ ()) ; (inj₂ ()) }))
energyRegime_matches_operant_operator .(prototypeToPoint protoColere) (there (there (there here))) =
    ((λ ()) , (λ { (inj₁ ()) ; (inj₂ ()) }))
  , ((λ _ → inj₁ refl) , (λ _ → refl))
energyRegime_matches_operant_operator _ (there (there (there (there ()))))

AntagonistFlipSpec : Maybe OperantContingency → Maybe OperantContingency → Set
AntagonistFlipSpec (just c1) (just c2) = (¬ (opEffect c1 ≡ opEffect c2)) × (opOperator c1 ≡ opOperator c2)
AntagonistFlipSpec _         _         = ⊥

-- [4/7] antagonist_flips_effect_preserves_operator
antagonist_flips_effect_preserves_operator :
  ∀ (p : CoreAffectPoint) → p ∈ z2DiagonalPoints →
  AntagonistFlipSpec (diagToContingency p) (diagToContingency (antagonistPoint p))
antagonist_flips_effect_preserves_operator .(prototypeToPoint protoDesir)  here                         = (λ ()) , refl
antagonist_flips_effect_preserves_operator .(prototypeToPoint protoCalme)  (there here)                 = (λ ()) , refl
antagonist_flips_effect_preserves_operator .(prototypeToPoint protoDegout) (there (there here))         = (λ ()) , refl
antagonist_flips_effect_preserves_operator .(prototypeToPoint protoColere) (there (there (there here))) = (λ ()) , refl
antagonist_flips_effect_preserves_operator _ (there (there (there (there ()))))

-- [5/7] axial_poles_bridge_operant_pairs
axial_poles_bridge_operant_pairs :
    (manhattanDistXY (prototypeToPoint protoCourage)   (prototypeToPoint protoDesir)  ≡ 2)
  × (manhattanDistXY (prototypeToPoint protoCourage)   (prototypeToPoint protoCalme)  ≡ 2)
  × (manhattanDistXY (prototypeToPoint protoCourage)   (prototypeToPoint protoColere) ≡ 4)
  × (manhattanDistXY (prototypeToPoint protoCourage)   (prototypeToPoint protoDegout) ≡ 4)
  × (manhattanDistXY (prototypeToPoint protoPeur)      (prototypeToPoint protoColere) ≡ 2)
  × (manhattanDistXY (prototypeToPoint protoPeur)      (prototypeToPoint protoDegout) ≡ 2)
  × (manhattanDistXY (prototypeToPoint protoPeur)      (prototypeToPoint protoDesir)  ≡ 4)
  × (manhattanDistXY (prototypeToPoint protoPeur)      (prototypeToPoint protoCalme)  ≡ 4)
  × (manhattanDistXY (prototypeToPoint protoJoie)      (prototypeToPoint protoDesir)  ≡ 2)
  × (manhattanDistXY (prototypeToPoint protoJoie)      (prototypeToPoint protoColere) ≡ 2)
  × (manhattanDistXY (prototypeToPoint protoJoie)      (prototypeToPoint protoCalme)  ≡ 4)
  × (manhattanDistXY (prototypeToPoint protoJoie)      (prototypeToPoint protoDegout) ≡ 4)
  × (manhattanDistXY (prototypeToPoint protoTristesse) (prototypeToPoint protoCalme)  ≡ 2)
  × (manhattanDistXY (prototypeToPoint protoTristesse) (prototypeToPoint protoDegout) ≡ 2)
  × (manhattanDistXY (prototypeToPoint protoTristesse) (prototypeToPoint protoDesir)  ≡ 4)
  × (manhattanDistXY (prototypeToPoint protoTristesse) (prototypeToPoint protoColere) ≡ 4)
axial_poles_bridge_operant_pairs =
  refl , refl , refl , refl ,
  refl , refl , refl , refl ,
  refl , refl , refl , refl ,
  refl , refl , refl , refl

-- [6/7] axial_poles_pre_operant
axial_poles_pre_operant :
  ∀ (p : CoreAffectPoint) → p ∈ z2AxialPoints → diagToContingency p ≡ nothing
axial_poles_pre_operant .(prototypeToPoint protoCourage)   here                         = refl
axial_poles_pre_operant .(prototypeToPoint protoPeur)      (there here)                 = refl
axial_poles_pre_operant .(prototypeToPoint protoJoie)      (there (there here))         = refl
axial_poles_pre_operant .(prototypeToPoint protoTristesse) (there (there (there here))) = refl
axial_poles_pre_operant _ (there (there (there (there ()))))

-- [7/7] operant_bijection_on_z2_diagonals
operant_bijection_on_z2_diagonals :
    (∀ (c : OperantContingency) →
      Σ CoreAffectPoint (λ p → (p ∈ z2DiagonalPoints) × (diagToContingency p ≡ just c)))
  × (∀ (p₁ p₂ : CoreAffectPoint) →
      p₁ ∈ z2DiagonalPoints → p₂ ∈ z2DiagonalPoints →
      diagToContingency p₁ ≡ diagToContingency p₂ → p₁ ≡ p₂)
operant_bijection_on_z2_diagonals = surj , inj
  where
    surj : ∀ (c : OperantContingency) →
           Σ CoreAffectPoint (λ p → (p ∈ z2DiagonalPoints) × (diagToContingency p ≡ just c))
    surj (mkOperantContingency reinforcement addition) =
      prototypeToPoint protoDesir ,, (here , refl)
    surj (mkOperantContingency reinforcement removal)  =
      prototypeToPoint protoCalme ,, (there here , refl)
    surj (mkOperantContingency punishment addition)    =
      prototypeToPoint protoDegout ,, (there (there here) , refl)
    surj (mkOperantContingency punishment removal)     =
      prototypeToPoint protoColere ,, (there (there (there here)) , refl)

    inj : ∀ (p₁ p₂ : CoreAffectPoint) →
          p₁ ∈ z2DiagonalPoints → p₂ ∈ z2DiagonalPoints →
          diagToContingency p₁ ≡ diagToContingency p₂ → p₁ ≡ p₂
    inj .(prototypeToPoint protoDesir)  .(prototypeToPoint protoDesir)  here                         here                         _  = refl
    inj .(prototypeToPoint protoDesir)  .(prototypeToPoint protoCalme)  here                         (there here)                 ()
    inj .(prototypeToPoint protoDesir)  .(prototypeToPoint protoDegout) here                         (there (there here))         ()
    inj .(prototypeToPoint protoDesir)  .(prototypeToPoint protoColere) here                         (there (there (there here))) ()
    inj .(prototypeToPoint protoCalme)  .(prototypeToPoint protoDesir)  (there here)                 here                         ()
    inj .(prototypeToPoint protoCalme)  .(prototypeToPoint protoCalme)  (there here)                 (there here)                 _  = refl
    inj .(prototypeToPoint protoCalme)  .(prototypeToPoint protoDegout) (there here)                 (there (there here))         ()
    inj .(prototypeToPoint protoCalme)  .(prototypeToPoint protoColere) (there here)                 (there (there (there here))) ()
    inj .(prototypeToPoint protoDegout) .(prototypeToPoint protoDesir)  (there (there here))         here                         ()
    inj .(prototypeToPoint protoDegout) .(prototypeToPoint protoCalme)  (there (there here))         (there here)                 ()
    inj .(prototypeToPoint protoDegout) .(prototypeToPoint protoDegout) (there (there here))         (there (there here))         _  = refl
    inj .(prototypeToPoint protoDegout) .(prototypeToPoint protoColere) (there (there here))         (there (there (there here))) ()
    inj .(prototypeToPoint protoColere) .(prototypeToPoint protoDesir)  (there (there (there here))) here                         ()
    inj .(prototypeToPoint protoColere) .(prototypeToPoint protoCalme)  (there (there (there here))) (there here)                 ()
    inj .(prototypeToPoint protoColere) .(prototypeToPoint protoDegout) (there (there (there here))) (there (there here))         ()
    inj .(prototypeToPoint protoColere) .(prototypeToPoint protoColere) (there (there (there here))) (there (there (there here))) _  = refl
    inj _ _ (there (there (there (there ())))) _ _
    inj _ _ _ (there (there (there (there ())))) _
