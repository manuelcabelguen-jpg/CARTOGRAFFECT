{-# OPTIONS --safe --without-K #-}
------------------------------------------------------------------------
-- Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
-- SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
-- Cartograffect.Lexicon176: Exhaustive 176-state affective lexicon (Z0..Z7)
------------------------------------------------------------------------
module Cartograffect.Lexicon176 where

open import Cartograffect.Prelude
open import Cartograffect.PredictiveEngine
open import Cartograffect.CoreAffect
open import Cartograffect.AffectiveMatrix
open import Cartograffect.AffectiveTaxonomy
open import Cartograffect.AffectiveDynamics

record LexiconEntry : Set where
  constructor mkLexiconEntry
  field
    entryLabel : String
    entryPoint : CoreAffectPoint
open LexiconEntry public

mkEntry : String → Int → Int → Nat → LexiconEntry
mkEntry lbl x y z = mkLexiconEntry lbl (mkPoint x y z)

entriesZ0 : List LexiconEntry
entriesZ0 =
    mkEntry "Point de Veille" (pos 0) (pos 0) 0
  ∷ []

entriesZ1 : List LexiconEntry
entriesZ1 =
    mkEntry "Surprise" (pos 0) (pos 0) 1
  ∷ []

entriesZ2 : List LexiconEntry
entriesZ2 =
    mkEntry "Anticipation" (pos 0) (pos 0) 2
  ∷ mkEntry "Joie" (pos 0) (pos 2) 2
  ∷ mkEntry "Tristesse" (pos 0) (negsuc 1) 2
  ∷ mkEntry "Peur" (negsuc 1) (pos 0) 2
  ∷ mkEntry "Courage" (pos 2) (pos 0) 2
  ∷ mkEntry "Colère" (negsuc 0) (pos 1) 2
  ∷ mkEntry "Calme" (pos 1) (negsuc 0) 2
  ∷ mkEntry "Désir" (pos 1) (pos 1) 2
  ∷ mkEntry "Dégoût" (negsuc 0) (negsuc 0) 2
  ∷ []

entriesZ3 : List LexiconEntry
entriesZ3 =
    mkEntry "Émoi" (pos 0) (pos 0) 3
  ∷ mkEntry "Enthousiasme" (pos 0) (pos 4) 3
  ∷ mkEntry "Ennui" (pos 0) (negsuc 3) 3
  ∷ mkEntry "Crainte" (negsuc 3) (pos 0) 3
  ∷ mkEntry "Curiosité" (pos 4) (pos 0) 3
  ∷ mkEntry "Consternation" (negsuc 0) (pos 3) 3
  ∷ mkEntry "Euphorie" (pos 1) (pos 3) 3
  ∷ mkEntry "Soulagement" (pos 1) (negsuc 2) 3
  ∷ mkEntry "Chagrin" (negsuc 0) (negsuc 2) 3
  ∷ mkEntry "Panique" (negsuc 2) (pos 1) 3
  ∷ mkEntry "Effroi" (negsuc 2) (negsuc 0) 3
  ∷ mkEntry "Émerveillement" (pos 3) (negsuc 0) 3
  ∷ mkEntry "Aplomb" (pos 3) (pos 1) 3
  ∷ mkEntry "Exaspération" (negsuc 1) (pos 2) 3
  ∷ mkEntry "Détente" (pos 2) (negsuc 1) 3
  ∷ mkEntry "Attrait" (pos 2) (pos 2) 3
  ∷ mkEntry "Retrait" (negsuc 1) (negsuc 1) 3
  ∷ []

entriesZ4 : List LexiconEntry
entriesZ4 =
    mkEntry "Réserve" (pos 0) (pos 0) 4
  ∷ mkEntry "Exaltation" (pos 0) (pos 6) 4
  ∷ mkEntry "Langueur" (pos 0) (negsuc 5) 4
  ∷ mkEntry "Doute" (negsuc 5) (pos 0) 4
  ∷ mkEntry "Assurance" (pos 6) (pos 0) 4
  ∷ mkEntry "Envie" (negsuc 1) (pos 4) 4
  ∷ mkEntry "Haine" (negsuc 0) (pos 5) 4
  ∷ mkEntry "Amour" (pos 1) (pos 5) 4
  ∷ mkEntry "Ferveur" (pos 2) (pos 4) 4
  ∷ mkEntry "Sérénité" (pos 2) (negsuc 3) 4
  ∷ mkEntry "Plénitude" (pos 1) (negsuc 4) 4
  ∷ mkEntry "Honte" (negsuc 1) (negsuc 3) 4
  ∷ mkEntry "Vide" (negsuc 0) (negsuc 4) 4
  ∷ mkEntry "Anxiété" (negsuc 3) (pos 2) 4
  ∷ mkEntry "Manque" (negsuc 4) (pos 1) 4
  ∷ mkEntry "Mépris" (negsuc 4) (negsuc 0) 4
  ∷ mkEntry "Défiance" (negsuc 3) (negsuc 1) 4
  ∷ mkEntry "Fierté" (pos 4) (pos 2) 4
  ∷ mkEntry "Épanouissement" (pos 5) (pos 1) 4
  ∷ mkEntry "Affection" (pos 5) (negsuc 0) 4
  ∷ mkEntry "Admiration" (pos 4) (negsuc 1) 4
  ∷ mkEntry "Frustration" (negsuc 2) (pos 3) 4
  ∷ mkEntry "Acceptation" (pos 3) (negsuc 2) 4
  ∷ mkEntry "Estime" (pos 3) (pos 3) 4
  ∷ mkEntry "Rejet" (negsuc 2) (negsuc 2) 4
  ∷ []

entriesZ5 : List LexiconEntry
entriesZ5 =
    mkEntry "Recul" (pos 0) (pos 0) 5
  ∷ mkEntry "Puissance" (pos 0) (pos 8) 5
  ∷ mkEntry "Impuissance" (pos 0) (negsuc 7) 5
  ∷ mkEntry "Méfiance" (negsuc 7) (pos 0) 5
  ∷ mkEntry "Confiance" (pos 8) (pos 0) 5
  ∷ mkEntry "Invulnérabilité" (pos 1) (pos 7) 5
  ∷ mkEntry "Attachement" (pos 2) (pos 6) 5
  ∷ mkEntry "Engagement" (pos 3) (pos 5) 5
  ∷ mkEntry "Désenchantement" (negsuc 1) (pos 6) 5
  ∷ mkEntry "Intolérance" (negsuc 2) (pos 5) 5
  ∷ mkEntry "Injustice" (negsuc 0) (pos 7) 5
  ∷ mkEntry "Quiétude" (pos 3) (negsuc 4) 5
  ∷ mkEntry "Sécurité" (pos 2) (negsuc 5) 5
  ∷ mkEntry "Patience" (pos 1) (negsuc 6) 5
  ∷ mkEntry "Pessimisme" (negsuc 1) (negsuc 5) 5
  ∷ mkEntry "Fermeture" (negsuc 2) (negsuc 4) 5
  ∷ mkEntry "Désespoir" (negsuc 0) (negsuc 6) 5
  ∷ mkEntry "Insécurité" (negsuc 5) (pos 2) 5
  ∷ mkEntry "Inquiétude" (negsuc 4) (pos 3) 5
  ∷ mkEntry "Impatience" (negsuc 6) (pos 1) 5
  ∷ mkEntry "Vulnérabilité" (negsuc 6) (negsuc 0) 5
  ∷ mkEntry "Détachement" (negsuc 5) (negsuc 1) 5
  ∷ mkEntry "Désengagement" (negsuc 4) (negsuc 2) 5
  ∷ mkEntry "Optimisme" (pos 6) (pos 2) 5
  ∷ mkEntry "Ouverture" (pos 5) (pos 3) 5
  ∷ mkEntry "Espoir" (pos 7) (pos 1) 5
  ∷ mkEntry "Enchantement" (pos 6) (negsuc 1) 5
  ∷ mkEntry "Tolérance" (pos 5) (negsuc 2) 5
  ∷ mkEntry "Justice" (pos 7) (negsuc 0) 5
  ∷ mkEntry "Insatisfaction" (negsuc 3) (pos 4) 5
  ∷ mkEntry "Satisfaction" (pos 4) (negsuc 3) 5
  ∷ mkEntry "Intérêt" (pos 4) (pos 4) 5
  ∷ mkEntry "Désintérêt" (negsuc 3) (negsuc 3) 5
  ∷ []

entriesZ6 : List LexiconEntry
entriesZ6 =
    mkEntry "Saisissement" (pos 0) (pos 0) 6
  ∷ mkEntry "Élan" (pos 0) (pos 10) 6
  ∷ mkEntry "Inertie" (pos 0) (negsuc 9) 6
  ∷ mkEntry "Effacement" (negsuc 9) (pos 0) 6
  ∷ mkEntry "Affirmation" (pos 10) (pos 0) 6
  ∷ mkEntry "Ardeur" (pos 3) (pos 7) 6
  ∷ mkEntry "Angoisse" (negsuc 2) (pos 7) 6
  ∷ mkEntry "Allégresse" (pos 4) (pos 6) 6
  ∷ mkEntry "Fureur" (negsuc 3) (pos 6) 6
  ∷ mkEntry "Fougue" (pos 2) (pos 8) 6
  ∷ mkEntry "Frénésie" (negsuc 1) (pos 8) 6
  ∷ mkEntry "Jubilation" (pos 1) (pos 9) 6
  ∷ mkEntry "Terreur" (negsuc 0) (pos 9) 6
  ∷ mkEntry "Béatitude" (pos 3) (negsuc 6) 6
  ∷ mkEntry "Accablement" (negsuc 2) (negsuc 6) 6
  ∷ mkEntry "Apaisement" (pos 4) (negsuc 5) 6
  ∷ mkEntry "Morosité" (negsuc 3) (negsuc 5) 6
  ∷ mkEntry "Contemplation" (pos 2) (negsuc 7) 6
  ∷ mkEntry "Prostration" (negsuc 1) (negsuc 7) 6
  ∷ mkEntry "Félicité" (pos 1) (negsuc 8) 6
  ∷ mkEntry "Désolation" (negsuc 0) (negsuc 8) 6
  ∷ mkEntry "Rancœur" (negsuc 5) (pos 4) 6
  ∷ mkEntry "Amertume" (negsuc 5) (negsuc 3) 6
  ∷ mkEntry "Affolement" (negsuc 6) (pos 3) 6
  ∷ mkEntry "Écrasement" (negsuc 6) (negsuc 2) 6
  ∷ mkEntry "Fébrilité" (negsuc 7) (pos 2) 6
  ∷ mkEntry "Anéantissement" (negsuc 7) (negsuc 1) 6
  ∷ mkEntry "Désarroi" (negsuc 8) (pos 1) 6
  ∷ mkEntry "Lassitude" (negsuc 8) (negsuc 0) 6
  ∷ mkEntry "Entrain" (pos 6) (pos 4) 6
  ∷ mkEntry "Placidité" (pos 6) (negsuc 3) 6
  ∷ mkEntry "Liesse" (pos 7) (pos 3) 6
  ∷ mkEntry "Limpidité" (pos 7) (negsuc 2) 6
  ∷ mkEntry "Extase" (pos 8) (pos 2) 6
  ∷ mkEntry "Équanimité" (pos 8) (negsuc 1) 6
  ∷ mkEntry "Exultation" (pos 9) (pos 1) 6
  ∷ mkEntry "Harmonie" (pos 9) (negsuc 0) 6
  ∷ mkEntry "Tourment" (negsuc 4) (pos 5) 6
  ∷ mkEntry "Ataraxie" (pos 5) (negsuc 4) 6
  ∷ mkEntry "Triomphe" (pos 5) (pos 5) 6
  ∷ mkEntry "Abattement" (negsuc 4) (negsuc 4) 6
  ∷ []

entriesZ7 : List LexiconEntry
entriesZ7 =
    mkEntry "Suspension" (pos 0) (pos 0) 7
  ∷ mkEntry "Infini" (pos 0) (pos 12) 7
  ∷ mkEntry "Néant" (pos 0) (negsuc 11) 7
  ∷ mkEntry "Déréliction" (negsuc 11) (pos 0) 7
  ∷ mkEntry "Communion" (pos 12) (pos 0) 7
  ∷ mkEntry "Transcendance" (pos 2) (pos 10) 7
  ∷ mkEntry "Déchirement" (negsuc 1) (pos 10) 7
  ∷ mkEntry "Exubérance" (pos 4) (pos 8) 7
  ∷ mkEntry "Horreur" (negsuc 3) (pos 8) 7
  ∷ mkEntry "Renaissance" (pos 1) (pos 11) 7
  ∷ mkEntry "Vertige" (negsuc 0) (pos 11) 7
  ∷ mkEntry "Élévation" (pos 3) (pos 9) 7
  ∷ mkEntry "Détresse" (negsuc 2) (pos 9) 7
  ∷ mkEntry "Enivrement" (pos 5) (pos 7) 7
  ∷ mkEntry "Révolte" (negsuc 4) (pos 7) 7
  ∷ mkEntry "Nirvana" (pos 2) (negsuc 9) 7
  ∷ mkEntry "Perdition" (negsuc 1) (negsuc 9) 7
  ∷ mkEntry "Paix" (pos 4) (negsuc 7) 7
  ∷ mkEntry "Oppression" (negsuc 3) (negsuc 7) 7
  ∷ mkEntry "Pérennité" (pos 1) (negsuc 10) 7
  ∷ mkEntry "Abîme" (negsuc 0) (negsuc 10) 7
  ∷ mkEntry "Abandon" (pos 3) (negsuc 8) 7
  ∷ mkEntry "Damnation" (negsuc 2) (negsuc 8) 7
  ∷ mkEntry "Silence" (pos 5) (negsuc 6) 7
  ∷ mkEntry "Résignation" (negsuc 4) (negsuc 6) 7
  ∷ mkEntry "Hantise" (negsuc 9) (pos 2) 7
  ∷ mkEntry "Isolement" (negsuc 9) (negsuc 1) 7
  ∷ mkEntry "Affliction" (negsuc 7) (pos 4) 7
  ∷ mkEntry "Mélancolie" (negsuc 7) (negsuc 3) 7
  ∷ mkEntry "Précarité" (negsuc 10) (pos 1) 7
  ∷ mkEntry "Déchéance" (negsuc 10) (negsuc 0) 7
  ∷ mkEntry "Sidération" (negsuc 8) (pos 3) 7
  ∷ mkEntry "Engloutissement" (negsuc 8) (negsuc 2) 7
  ∷ mkEntry "Tumulte" (negsuc 6) (pos 5) 7
  ∷ mkEntry "Pétrification" (negsuc 6) (negsuc 4) 7
  ∷ mkEntry "Éblouissement" (pos 10) (pos 2) 7
  ∷ mkEntry "Recueillement" (pos 10) (negsuc 1) 7
  ∷ mkEntry "Rayonnement" (pos 8) (pos 4) 7
  ∷ mkEntry "Contentement" (pos 8) (negsuc 3) 7
  ∷ mkEntry "Ravissement" (pos 11) (pos 1) 7
  ∷ mkEntry "Épiphanie" (pos 11) (negsuc 0) 7
  ∷ mkEntry "Louange" (pos 9) (pos 3) 7
  ∷ mkEntry "Lucidité" (pos 9) (negsuc 2) 7
  ∷ mkEntry "Effusion" (pos 7) (pos 5) 7
  ∷ mkEntry "Consentement" (pos 7) (negsuc 4) 7
  ∷ mkEntry "Rage" (negsuc 5) (pos 6) 7
  ∷ mkEntry "Impassibilité" (pos 6) (negsuc 5) 7
  ∷ mkEntry "Sublimation" (pos 6) (pos 6) 7
  ∷ mkEntry "Dissolution" (negsuc 5) (negsuc 5) 7
  ∷ []

all176Entries : List LexiconEntry
all176Entries =
  entriesZ0 ++ entriesZ1 ++ entriesZ2 ++ entriesZ3 ++
  entriesZ4 ++ entriesZ5 ++ entriesZ6 ++ entriesZ7

------------------------------------------------------------------------
-- Boolean decidability & All-reflection helpers
------------------------------------------------------------------------

and-true-l : ∀ (a b : Bool) → (a ∧b b) ≡ true → a ≡ true
and-true-l true  _ _ = refl
and-true-l false _ ()

and-true-r : ∀ (a b : Bool) → (a ∧b b) ≡ true → b ≡ true
and-true-r true  b h = h
and-true-r false _ ()

allB : ∀ {A : Set} → (A → Bool) → List A → Bool
allB p []       = true
allB p (x ∷ xs) = p x ∧b allB p xs

allB-to-All : ∀ {A : Set} (p : A → Bool) (xs : List A) → allB p xs ≡ true → All (λ x → p x ≡ true) xs
allB-to-All p []       _ = []
allB-to-All p (x ∷ xs) h =
  and-true-l (p x) (allB p xs) h ∷ allB-to-All p xs (and-true-r (p x) (allB p xs) h)

eqIntB : Int → Int → Bool
eqIntB (pos a)    (pos b)    = a == b
eqIntB (negsuc a) (negsuc b) = a == b
eqIntB _          _          = false

eqPointB : CoreAffectPoint → CoreAffectPoint → Bool
eqPointB p q = eqIntB (px p) (px q) ∧b (eqIntB (py p) (py q) ∧b (pz p == pz q))

countPoint : CoreAffectPoint → List LexiconEntry → Nat
countPoint p []       = 0
countPoint p (e ∷ es) = (if eqPointB p (entryPoint e) then 1 else 0) + countPoint p es

witnessMatchesPointB : LexiconEntry → Bool
witnessMatchesPointB e =
  let p   = entryPoint e
      tax = runCartograffectPipeline (witnessEngineForPoint p)
  in eqPointB (core (matrix tax)) p

------------------------------------------------------------------------
-- 8 Audited Theorems (Module 06: Lexicon176)
------------------------------------------------------------------------

-- [1/8] all176Entries_length
all176Entries_length : length all176Entries ≡ 176
all176Entries_length = refl

-- [2/8] all176Entries_geometrically_valid
all176Entries_geometrically_valid :
  ∀ {e : LexiconEntry} → e ∈ all176Entries → IsValidCoreAffect (entryPoint e)
all176Entries_geometrically_valid e∈ =
  All-lookup (allB-to-All (λ e → isValidCoreAffectB (entryPoint e)) all176Entries refl) e∈

-- [3/8] all176Entries_z_bounds
all176Entries_z_bounds :
  ∀ {e : LexiconEntry} → e ∈ all176Entries → leNatB (pz (entryPoint e)) 7 ≡ true
all176Entries_z_bounds e∈ =
  All-lookup (allB-to-All (λ e → leNatB (pz (entryPoint e)) 7) all176Entries refl) e∈

-- [4/8] all176Entries_unique_points
all176Entries_unique_points :
  ∀ {e : LexiconEntry} → e ∈ all176Entries → (countPoint (entryPoint e) all176Entries == 1) ≡ true
all176Entries_unique_points e∈ =
  All-lookup (allB-to-All (λ e → countPoint (entryPoint e) all176Entries == 1) all176Entries refl) e∈

-- [5/8] all176Entries_complete
all176Entries_complete :
  (length entriesZ0 ≡ stratumTotalCount 0)
  × (length entriesZ1 ≡ stratumTotalCount 1)
  × (length entriesZ2 ≡ stratumTotalCount 2)
  × (length entriesZ3 ≡ stratumTotalCount 3)
  × (length entriesZ4 ≡ stratumTotalCount 4)
  × (length entriesZ5 ≡ stratumTotalCount 5)
  × (length entriesZ6 ≡ stratumTotalCount 6)
  × (length entriesZ7 ≡ stratumTotalCount 7)
  × (length all176Entries ≡
     stratumTotalCount 0 + stratumTotalCount 1 + stratumTotalCount 2 + stratumTotalCount 3 +
     stratumTotalCount 4 + stratumTotalCount 5 + stratumTotalCount 6 + stratumTotalCount 7)
all176Entries_complete = refl , refl , refl , refl , refl , refl , refl , refl , refl

-- [6/8] all176Entries_deterministically_reachable
all176Entries_deterministically_reachable :
  ∀ {e : LexiconEntry} → e ∈ all176Entries →
  core (matrix (runCartograffectPipeline (witnessEngineForPoint (entryPoint e)))) ≡ entryPoint e
all176Entries_deterministically_reachable {e} e∈ =
  cong (λ p → core (evaluateMatrix p canonicalMapping))
       (projectToCoreAffect_surjective (entryPoint e) (all176Entries_geometrically_valid e∈))

-- [7/8] all176Entries_reachable_by_engine
all176Entries_reachable_by_engine :
  ∀ {e : LexiconEntry} → e ∈ all176Entries →
  Σ PredictiveEngineState (λ s → core (matrix (runCartograffectPipeline s)) ≡ entryPoint e)
all176Entries_reachable_by_engine {e} e∈ =
  witnessEngineForPoint (entryPoint e) ,, all176Entries_deterministically_reachable e∈

-- [8/8] all176Entries_witness_check
all176Entries_witness_check :
  ∀ {e : LexiconEntry} → e ∈ all176Entries → witnessMatchesPointB e ≡ true
all176Entries_witness_check e∈ =
  All-lookup (allB-to-All witnessMatchesPointB all176Entries refl) e∈

------------------------------------------------------------------------
-- Structural Lemmas for End-to-End Bridge (NoDup, Lookup, Completeness)
------------------------------------------------------------------------

data NoDup {A : Set} : List A → Set where
  nodup-[] : NoDup []
  nodup-∷  : ∀ {x : A} {xs : List A} → ¬ (x ∈ xs) → NoDup xs → NoDup (x ∷ xs)

anyB : ∀ {A : Set} → (A → Bool) → List A → Bool
anyB _ []       = false
anyB p (x ∷ xs) = p x ∨b anyB p xs

nodupByB : ∀ {A : Set} → (A → A → Bool) → List A → Bool
nodupByB _   []       = true
nodupByB eqB (x ∷ xs) = eqB x x ∧b (not (anyB (eqB x) xs) ∧b nodupByB eqB xs)

not-true-to-false : ∀ (b : Bool) → not b ≡ true → b ≡ false
not-true-to-false false _ = refl
not-true-to-false true  ()

or-false-l-lex : ∀ (a b : Bool) → (a ∨b b) ≡ false → a ≡ false
or-false-l-lex false _ _ = refl
or-false-l-lex true  _ ()

or-false-r-lex : ∀ (a b : Bool) → (a ∨b b) ≡ false → b ≡ false
or-false-r-lex false b h = h
or-false-r-lex true  _ ()

false≢true-lex : false ≡ true → ⊥
false≢true-lex ()

anyB-false-not-∈ :
  ∀ {A : Set} (eqB : A → A → Bool) (x : A) (xs : List A) →
  eqB x x ≡ true →
  anyB (eqB x) xs ≡ false →
  ¬ (x ∈ xs)
anyB-false-not-∈ _   _ []        _     _    ()
anyB-false-not-∈ eqB x (.x ∷ xs) hRefl hAny here =
  false≢true-lex (trans (sym (or-false-l-lex (eqB x x) (anyB (eqB x) xs) hAny)) hRefl)
anyB-false-not-∈ eqB x (y ∷ xs)  hRefl hAny (there h∈) =
  anyB-false-not-∈ eqB x xs hRefl (or-false-r-lex (eqB x y) (anyB (eqB x) xs) hAny) h∈

nodupByB-to-NoDup :
  ∀ {A : Set} (eqB : A → A → Bool) (xs : List A) →
  nodupByB eqB xs ≡ true →
  NoDup xs
nodupByB-to-NoDup _   []       _ = nodup-[]
nodupByB-to-NoDup eqB (x ∷ xs) h =
  let h1   = and-true-l (eqB x x) (not (anyB (eqB x) xs) ∧b nodupByB eqB xs) h
      h23  = and-true-r (eqB x x) (not (anyB (eqB x) xs) ∧b nodupByB eqB xs) h
      hNot = and-true-l (not (anyB (eqB x) xs)) (nodupByB eqB xs) h23
      hTl  = and-true-r (not (anyB (eqB x) xs)) (nodupByB eqB xs) h23
  in nodup-∷ (anyB-false-not-∈ eqB x xs h1 (not-true-to-false (anyB (eqB x) xs) hNot))
             (nodupByB-to-NoDup eqB xs hTl)

in-map : ∀ {A B : Set} (f : A → B) {x : A} {xs : List A} → x ∈ xs → f x ∈ map f xs
in-map _ here      = here
in-map f (there h) = there (in-map f h)

nodup-map-inj :
  ∀ {A B : Set} (f : A → B) (xs : List A) →
  NoDup (map f xs) →
  ∀ {a b : A} → a ∈ xs → b ∈ xs → f a ≡ f b → a ≡ b
nodup-map-inj _ []       _                 ()         _          _
nodup-map-inj _ (_ ∷ _)  (nodup-∷ _    _)  here       here       _  = refl
nodup-map-inj f (_ ∷ xs) (nodup-∷ ¬fx∈ _)  here       (there hb) eq =
  ⊥-elim (¬fx∈ (subst (λ v → v ∈ map f xs) (sym eq) (in-map f hb)))
nodup-map-inj f (_ ∷ xs) (nodup-∷ ¬fx∈ _)  (there ha) here       eq =
  ⊥-elim (¬fx∈ (subst (λ v → v ∈ map f xs) eq (in-map f ha)))
nodup-map-inj f (_ ∷ xs) (nodup-∷ _    nd) (there ha) (there hb) eq =
  nodup-map-inj f xs nd ha hb eq

all176Entries_nodup_points : NoDup (map entryPoint all176Entries)
all176Entries_nodup_points = nodupByB-to-NoDup eqPointB (map entryPoint all176Entries) refl

all176Entries_point_injective :
  ∀ {e₁ e₂ : LexiconEntry} →
  e₁ ∈ all176Entries → e₂ ∈ all176Entries →
  entryPoint e₁ ≡ entryPoint e₂ →
  e₁ ≡ e₂
all176Entries_point_injective h1 h2 eq =
  nodup-map-inj entryPoint all176Entries all176Entries_nodup_points h1 h2 eq

nthOrDefault : ∀ {A : Set} → A → Nat → List A → A
nthOrDefault d _       []       = d
nthOrDefault _ zero    (x ∷ _)  = x
nthOrDefault d (suc k) (_ ∷ xs) = nthOrDefault d k xs

nth-∈ : ∀ {A : Set} (d : A) (k : Nat) (xs : List A) → (k < length xs) ≡ true → nthOrDefault d k xs ∈ xs
nth-∈ _ zero    (_ ∷ _)  _ = here
nth-∈ d (suc k) (_ ∷ xs) h = there (nth-∈ d k xs h)

eqIntB-to-≡ : ∀ (x y : Int) → eqIntB x y ≡ true → x ≡ y
eqIntB-to-≡ (pos a)    (pos b)    h = cong pos (nat-==-to-≡ a b h)
eqIntB-to-≡ (negsuc a) (negsuc b) h = cong negsuc (nat-==-to-≡ a b h)
eqIntB-to-≡ (pos _)    (negsuc _) ()
eqIntB-to-≡ (negsuc _) (pos _)    ()

eqPointB-to-≡ : ∀ (p q : CoreAffectPoint) → eqPointB p q ≡ true → p ≡ q
eqPointB-to-≡ (mkPoint xa ya za) (mkPoint xb yb zb) h =
  let hx  = and-true-l (eqIntB xa xb) (eqIntB ya yb ∧b (za == zb)) h
      hyz = and-true-r (eqIntB xa xb) (eqIntB ya yb ∧b (za == zb)) h
      hy  = and-true-l (eqIntB ya yb) (za == zb) hyz
      hz  = and-true-r (eqIntB ya yb) (za == zb) hyz
  in trans (cong (mkPoint xa ya) (nat-==-to-≡ za zb hz))
           (cong₂ (λ u v → mkPoint u v zb)
                  (eqIntB-to-≡ xa xb hx)
                  (eqIntB-to-≡ ya yb hy))

hasEntryForPointB : List LexiconEntry → CoreAffectPoint → Bool
hasEntryForPointB []       _ = false
hasEntryForPointB (e ∷ es) p = eqPointB (entryPoint e) p ∨b hasEntryForPointB es p

hasEntryForPointB-to-Σ :
  ∀ (es : List LexiconEntry) (p : CoreAffectPoint) →
  hasEntryForPointB es p ≡ true →
  Σ LexiconEntry (λ e → (e ∈ es) × (entryPoint e ≡ p))
hasEntryForPointB-to-Σ []       _ ()
hasEntryForPointB-to-Σ (e ∷ es) p h = aux (eqPointB (entryPoint e) p) refl h
  where
    aux : ∀ (b : Bool) → eqPointB (entryPoint e) p ≡ b →
          (b ∨b hasEntryForPointB es p) ≡ true →
          Σ LexiconEntry (λ e' → (e' ∈ (e ∷ es)) × (entryPoint e' ≡ p))
    aux true  eq _  = e ,, (here , eqPointB-to-≡ (entryPoint e) p eq)
    aux false _  h' =
      let res = hasEntryForPointB-to-Σ es p h'
      in proj₁ res ,, (there (fst (proj₂ res)) , snd (proj₂ res))

∈-++-l : ∀ {A : Set} {x : A} {xs ys : List A} → x ∈ xs → x ∈ (xs ++ ys)
∈-++-l here      = here
∈-++-l (there h) = there (∈-++-l h)

∈-++-r : ∀ {A : Set} {x : A} (xs : List A) {ys : List A} → x ∈ ys → x ∈ (xs ++ ys)
∈-++-r []       h = h
∈-++-r (_ ∷ xs) h = there (∈-++-r xs h)

flatMap : ∀ {A B : Set} → (A → List B) → List A → List B
flatMap _ []       = []
flatMap f (x ∷ xs) = f x ++ flatMap f xs

∈-flatMap :
  ∀ {A B : Set} (f : A → List B) {a : A} {b : B} {xs : List A} →
  a ∈ xs → b ∈ f a → b ∈ flatMap f xs
∈-flatMap _ here       hb = ∈-++-l hb
∈-flatMap f (there ha) hb = ∈-++-r (f _) (∈-flatMap f ha hb)

≤-of-≤-suc-neq : ∀ {a k : Nat} → a ≤ℕ suc k → ¬ (a ≡ suc k) → a ≤ℕ k
≤-of-≤-suc-neq {zero}          z≤n       _   = z≤n
≤-of-≤-suc-neq {suc _} {zero}  (s≤s z≤n) neq = ⊥-elim (neq refl)
≤-of-≤-suc-neq {suc _} {suc _} (s≤s h)   neq = s≤s (≤-of-≤-suc-neq h (λ eq → neq (cong suc eq)))

seq0 : Nat → List Nat
seq0 zero    = zero ∷ []
seq0 (suc k) = suc k ∷ seq0 k

∈-seq0 : ∀ (a k : Nat) → a ≤ℕ k → a ∈ seq0 k
∈-seq0 zero zero    z≤n = here
∈-seq0 a    (suc k) h with ≡ℕ-dec a (suc k)
... | yes refl = here
... | no  neq  = there (∈-seq0 a k (≤-of-≤-suc-neq h neq))

signVariants : Nat → Nat → Nat → List CoreAffectPoint
signVariants ax ay z =
    mkPoint (pos ax)     (pos ay)     z
  ∷ mkPoint (pos ax)     (-ℤ pos ay) z
  ∷ mkPoint (-ℤ pos ax) (pos ay)     z
  ∷ mkPoint (-ℤ pos ax) (-ℤ pos ay) z
  ∷ []

∈-signVariants :
  ∀ (p : CoreAffectPoint) → p ∈ signVariants (absNat (px p)) (absNat (py p)) (pz p)
∈-signVariants (mkPoint (pos _)    (pos _)    _) = here
∈-signVariants (mkPoint (pos _)    (negsuc _) _) = there here
∈-signVariants (mkPoint (negsuc _) (pos _)    _) = there (there here)
∈-signVariants (mkPoint (negsuc _) (negsuc _) _) = there (there (there here))

stratumValidGrid : Nat → List CoreAffectPoint
stratumValidGrid z =
  mkPoint (pos 0) (pos 0) z
  ∷ flatMap (λ ax → signVariants ax (crownRadius z - ax) z) (seq0 (crownRadius z))

valid-in-stratumValidGrid :
  ∀ (p : CoreAffectPoint) → IsValidCoreAffect p → p ∈ stratumValidGrid (pz p)
valid-in-stratumValidGrid p hVal = aux (isCentralB p) refl hVal
  where
    aux : ∀ (b : Bool) → isCentralB p ≡ b →
          (b ∨b isOnCrownB p) ≡ true →
          p ∈ stratumValidGrid (pz p)
    aux true cEq _ =
      let xy = isCentralB-to-xy p cEq
          pEq : mkPoint (pos 0) (pos 0) (pz p) ≡ p
          pEq = cong₂ (λ a b → mkPoint a b (pz p)) (sym (fst xy)) (sym (snd xy))
      in subst (λ q → q ∈ stratumValidGrid (pz p)) pEq here
    aux false _ hCrown = crownAux (pz p) refl hCrown
      where
        crownAux : ∀ (zv : Nat) → pz p ≡ zv →
                   (ge2ℕ zv ∧b (displacementSum p == crownRadius zv)) ≡ true →
                   p ∈ stratumValidGrid zv
        crownAux zero          _    ()
        crownAux (suc zero)    _    ()
        crownAux (suc (suc d)) pzEq hc =
          let r     = crownRadius (suc (suc d))
              eqSum = nat-==-to-≡ (displacementSum p) r hc
              ax≤r  = subst (absNat (px p) ≤ℕ_) eqSum (≤ℕ-add-r (absNat (px p)) (absNat (py p)))
              ayEq  = trans (cong (_- absNat (px p)) (sym eqSum))
                            (-ℕ-cancel (absNat (px p)) (absNat (py p)))
              inSV0 = subst (λ z' → p ∈ signVariants (absNat (px p)) (absNat (py p)) z')
                            pzEq (∈-signVariants p)
              inSV  = subst (λ v → p ∈ signVariants (absNat (px p)) v (suc (suc d)))
                            (sym ayEq) inSV0
          in there (∈-flatMap (λ ax → signVariants ax (r - ax) (suc (suc d)))
                              (∈-seq0 (absNat (px p)) r ax≤r)
                              inSV)

stratumValidGrid-hasEntry :
  ∀ (z : Nat) → leNatB z 7 ≡ true →
  ∀ {q : CoreAffectPoint} → q ∈ stratumValidGrid z →
  hasEntryForPointB all176Entries q ≡ true
stratumValidGrid-hasEntry 0 _ q∈ =
  All-lookup (allB-to-All (hasEntryForPointB all176Entries) (stratumValidGrid 0) refl) q∈
stratumValidGrid-hasEntry 1 _ q∈ =
  All-lookup (allB-to-All (hasEntryForPointB all176Entries) (stratumValidGrid 1) refl) q∈
stratumValidGrid-hasEntry 2 _ q∈ =
  All-lookup (allB-to-All (hasEntryForPointB all176Entries) (stratumValidGrid 2) refl) q∈
stratumValidGrid-hasEntry 3 _ q∈ =
  All-lookup (allB-to-All (hasEntryForPointB all176Entries) (stratumValidGrid 3) refl) q∈
stratumValidGrid-hasEntry 4 _ q∈ =
  All-lookup (allB-to-All (hasEntryForPointB all176Entries) (stratumValidGrid 4) refl) q∈
stratumValidGrid-hasEntry 5 _ q∈ =
  All-lookup (allB-to-All (hasEntryForPointB all176Entries) (stratumValidGrid 5) refl) q∈
stratumValidGrid-hasEntry 6 _ q∈ =
  All-lookup (allB-to-All (hasEntryForPointB all176Entries) (stratumValidGrid 6) refl) q∈
stratumValidGrid-hasEntry 7 _ q∈ =
  All-lookup (allB-to-All (hasEntryForPointB all176Entries) (stratumValidGrid 7) refl) q∈
stratumValidGrid-hasEntry (suc (suc (suc (suc (suc (suc (suc (suc _)))))))) () _

all176Entries_lookup_by_point :
  ∀ (p : CoreAffectPoint) →
  leNatB (pz p) 7 ≡ true →
  IsValidCoreAffect p →
  Σ LexiconEntry (λ e → (e ∈ all176Entries) × (entryPoint e ≡ p))
all176Entries_lookup_by_point p hz hVal =
  hasEntryForPointB-to-Σ all176Entries p
    (stratumValidGrid-hasEntry (pz p) hz (valid-in-stratumValidGrid p hVal))

all176Entries_spatial_completeness :
  ∀ (p : CoreAffectPoint) →
  leNatB (pz p) 7 ≡ true →
  IsValidCoreAffect p →
  p ∈ map entryPoint all176Entries
all176Entries_spatial_completeness p hz hVal =
  let res = all176Entries_lookup_by_point p hz hVal
  in subst (λ q → q ∈ map entryPoint all176Entries)
           (snd (proj₂ res))
           (in-map entryPoint {xs = all176Entries} (fst (proj₂ res)))
