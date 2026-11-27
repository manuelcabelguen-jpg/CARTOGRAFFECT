/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later
Author: Manuel Cabelguen
-/

import Cartograffect.CoreAffect
import Cartograffect.AffectiveMatrix

namespace Cartograffect

namespace OperantFactorization

open CoreAffect
open AffectiveMatrix

/-!
## Bijection 2 × 2 des contingences de récompense et de punition (Rolls, 2014) sur `Z = 2`

Ce module relie formellement les quatre prototypes diagonaux de la **première couronne (`Z = 2`)**
à la matrice $2 \times 2$ exacte des **contingences de récompense et de punition de Rolls (2014)**,
strictement bornée à `Z = 2` (sans aucun relèvement universel sur les strates `Z ≥ 3`) et conforme
à l'**Option 1A** (`Y` = contrôlabilité instrumentale perçue stricte) :

1. **Axe Y — Classe de stimulus (Rolls, 2014) :**
   - `reward` (`Y = +1 > 0`) : domaine des récompenses ($S^+ / \overline{S^+}$), où l'agent conserve
     une prise instrumentale active sur l'issue ;
   - `punishment` (`Y = -1 < 0`) : domaine des punitions ($S^- / \overline{S^-}$), face à une
     limite objective d'action instrumentale.
2. **Produit `X * Y` — Opérateur de contingence :**
   - `delivery` (`X * Y = +1`, diagonale de congruence) : ajout / présentation d'un stimulus ;
   - `omission` (`X * Y = -1`, diagonale de compensation) : retrait / omission d'un stimulus.
3. **Bijection exacte $2 \times 2$ sur les diagonales de `Z = 2` :**
   - `(+1, +1, 2)` **Désir** : `Rew+` ($S^+$, ajout d'une récompense) ;
   - `(-1, +1, 2)` **Colère** : `Rew−` ($\overline{S^+}$, retrait/omission d'une récompense) ;
   - `(-1, -1, 2)` **Dégoût** : `Pun+` ($S^-$, ajout d'une punition) ;
   - `(+1, -1, 2)` **Calme** : `Pun−` ($\overline{S^-}$, retrait/omission d'une punition — à dissocier
     du renforcement négatif skinnerien `R−` défini par l'augmentation d'une conduite active d'évitement).
-/

/-- Distance de Manhattan intra-plan (métrique `L1` sur `(X, Y)`) entre deux coordonnées du Noyau. -/
def manhattanDistXY (p q : CoreAffectPoint) : Nat :=
  (p.x - q.x).natAbs + (p.y - q.y).natAbs

/-- Cohérence directe de `manhattanDistXY` avec `CoreAffectPoint.displacementSum` depuis l'origine de strate. -/
theorem manhattanDistXY_origin (p : CoreAffectPoint) :
    manhattanDistXY p ⟨0, 0, p.z⟩ = p.displacementSum := by
  dsimp [manhattanDistXY, CoreAffectPoint.displacementSum]
  simp only [Int.sub_zero]

/-- Classe de stimulus au sens de Rolls (2014) : récompense (`Y = +1`) vs punition (`Y = -1`). -/
inductive RollsReinforcerClass : Type where
  | reward     : RollsReinforcerClass -- S+ / ¬S+ : domaine des récompenses (Y = +1)
  | punishment : RollsReinforcerClass -- S- / ¬S- : domaine des punitions (Y = -1)
  deriving DecidableEq, Repr, Inhabited

/-- Opérateur de contingence sur le stimulus (Rolls, 2014) : ajout/présentation vs retrait/omission. -/
inductive RollsOperation : Type where
  | delivery : RollsOperation -- + : ajout / présentation du stimulus (X * Y = +1)
  | omission : RollsOperation -- - : retrait / omission du stimulus (X * Y = -1)
  deriving DecidableEq, Repr, Inhabited

/-- Issue adaptative sur l'Axe X (`+X` favorable vs `-X` aversif/contrarié). -/
inductive AdaptiveOutcome : Type where
  | favorable : AdaptiveOutcome
  | aversive  : AdaptiveOutcome
  deriving DecidableEq, Repr, Inhabited

/-- Les quatre contingences de Rolls (2014) bornées exclusivement aux diagonales de `Z = 2`. -/
inductive RollsContingency : Type where
  | rewPlus  : RollsContingency -- (+1, +1, 2) Désir  : Rew+ (S+, ajout d'une récompense)
  | rewMinus : RollsContingency -- (-1, +1, 2) Colère : Rew− (¬S+, retrait/omission d'une récompense)
  | punPlus  : RollsContingency -- (-1, -1, 2) Dégoût : Pun+ (S-, ajout d'une punition)
  | punMinus : RollsContingency -- (+1, -1, 2) Calme  : Pun− (¬S-, retrait/omission d'une punition)
  deriving DecidableEq, Repr, Inhabited

/-- Classe de stimulus (`reward` vs `punishment`) associée à chaque contingence de Rolls. -/
def RollsContingency.reinforcerClass : RollsContingency → RollsReinforcerClass
  | .rewPlus  => .reward
  | .rewMinus => .reward
  | .punPlus  => .punishment
  | .punMinus => .punishment

/-- Opérateur de contingence (`delivery` vs `omission`) associé à chaque contingence de Rolls. -/
def RollsContingency.operation : RollsContingency → RollsOperation
  | .rewPlus  => .delivery
  | .punPlus  => .delivery
  | .rewMinus => .omission
  | .punMinus => .omission

/-- Issue hédonique / adaptative associée à chaque contingence de Rolls sur l'Axe X. -/
def RollsContingency.outcome : RollsContingency → AdaptiveOutcome
  | .rewPlus  => .favorable
  | .punMinus => .favorable
  | .rewMinus => .aversive
  | .punPlus  => .aversive

/-- Symétrie d'antagonisme exacte sur `Z = 2` : `Rew+ ↔ Pun+` et `Rew− ↔ Pun−`. -/
def RollsContingency.antagonist : RollsContingency → RollsContingency
  | .rewPlus  => .punPlus
  | .punPlus  => .rewPlus
  | .rewMinus => .punMinus
  | .punMinus => .rewMinus

/-- Constructeur produit canonique `(RollsReinforcerClass × RollsOperation) → RollsContingency`. -/
def RollsContingency.fromPair : RollsReinforcerClass → RollsOperation → RollsContingency
  | .reward,     .delivery => .rewPlus
  | .reward,     .omission => .rewMinus
  | .punishment, .delivery => .punPlus
  | .punishment, .omission => .punMinus

/-- Coordonnée diagonale canonique en `Z = 2` associée à chaque contingence de Rolls. -/
def RollsContingency.toPoint : RollsContingency → CoreAffectPoint
  | .rewPlus  => PrimaryCrownPrototype.desir.toPoint
  | .rewMinus => PrimaryCrownPrototype.colere.toPoint
  | .punPlus  => PrimaryCrownPrototype.degout.toPoint
  | .punMinus => PrimaryCrownPrototype.calme.toPoint

/--
Projection partielle stricte bornée à la fondation `Z = 2` :
associe uniquement les 4 positions diagonales de `Z = 2` à leur `RollsContingency`, et renvoie
`none` sur les axes, les centres et **toutes les strates `Z ≠ 2`** (aucun relèvement en `Z = 3..7`).
-/
def diagToContingency (p : CoreAffectPoint) : Option RollsContingency :=
  if p.z == 2 then
    if p.x == 1 && p.y == 1 then some .rewPlus
    else if p.x == -1 && p.y == 1 then some .rewMinus
    else if p.x == -1 && p.y == -1 then some .punPlus
    else if p.x == 1 && p.y == -1 then some .punMinus
    else none
  else
    none

/-- Projection d'un prototype de la première couronne `PrimaryCrownPrototype` vers sa contingence de Rolls en `Z = 2`. -/
def prototypeToContingency (proto : PrimaryCrownPrototype) : Option RollsContingency :=
  diagToContingency proto.toPoint

/-- Liste canonique des quatre coordonnées diagonales de la couronne `Z = 2`. -/
def z2DiagonalPoints : List CoreAffectPoint :=
  [ PrimaryCrownPrototype.desir.toPoint
  , PrimaryCrownPrototype.calme.toPoint
  , PrimaryCrownPrototype.degout.toPoint
  , PrimaryCrownPrototype.colere.toPoint ]

/-- Liste canonique des quatre coordonnées axiales de la couronne `Z = 2`. -/
def z2AxialPoints : List CoreAffectPoint :=
  [ PrimaryCrownPrototype.courage.toPoint
  , PrimaryCrownPrototype.peur.toPoint
  , PrimaryCrownPrototype.joie.toPoint
  , PrimaryCrownPrototype.tristesse.toPoint ]

/--
Loi 1 (Factorisation complète de Rolls sur la fondation `Z = 2`) :
Sur les 4 diagonales de la première couronne :
- `Y` discrimine la classe de stimulus (`+1 ↔ reward`, `-1 ↔ punishment`) ;
- `X * Y` discrimine l'opérateur (`+1 ↔ delivery`, `-1 ↔ omission`) ;
- `X` discrimine l'issue adaptative (`+1 ↔ favorable`, `-1 ↔ aversive`) et la valence hédonique.
-/
theorem rolls_factorization_law :
    ∀ p ∈ z2DiagonalPoints,
      match diagToContingency p with
      | some c =>
          (c.reinforcerClass = .reward ↔ p.y = 1) ∧
          (c.reinforcerClass = .punishment ↔ p.y = -1) ∧
          (c.operation = .delivery ↔ p.x * p.y = 1) ∧
          (c.operation = .omission ↔ p.x * p.y = -1) ∧
          (c.outcome = .favorable ↔ p.x = 1) ∧
          (c.outcome = .aversive ↔ p.x = -1) ∧
          (computeHedonicPolarity p.x p.y = .positive ↔ c.outcome = .favorable)
      | none => False := by
  have h1 : diagToContingency PrimaryCrownPrototype.desir.toPoint = some .rewPlus := rfl
  have h2 : diagToContingency PrimaryCrownPrototype.calme.toPoint = some .punMinus := rfl
  have h3 : diagToContingency PrimaryCrownPrototype.degout.toPoint = some .punPlus := rfl
  have h4 : diagToContingency PrimaryCrownPrototype.colere.toPoint = some .rewMinus := rfl
  intro p hp
  simp only [z2DiagonalPoints, List.mem_cons, List.not_mem_nil, or_false] at hp
  rcases hp with rfl | rfl | rfl | rfl
  · rw [h1]; decide
  · rw [h2]; decide
  · rw [h3]; decide
  · rw [h4]; decide

/--
Loi 2 (Ancrage canonique exact et borne stricte à la fondation `Z = 2`) :
1. Toute contingence `diagToContingency p = some c` provient uniquement de la coordonnée `c.toPoint` en `Z = 2` ;
2. `Désir (+1,+1,2) ↔ Rew+`, `Colère (-1,+1,2) ↔ Rew−`, `Dégoût (-1,-1,2) ↔ Pun+`, `Calme (+1,-1,2) ↔ Pun−`,
   et `fromPair` reconstruit exactement `c` depuis `(c.reinforcerClass, c.operation)` ;
3. Toute position située hors de `Z = 2` (`p.z ≠ 2`, incluant `Z ≥ 3`) renvoie `diagToContingency p = none`.
-/
theorem rolls_contingencies_z2_bound :
    (∀ (p : CoreAffectPoint) (c : RollsContingency),
      diagToContingency p = some c →
      p = c.toPoint ∧ p.z = 2) ∧
    (∀ c : RollsContingency,
      diagToContingency c.toPoint = some c ∧
      RollsContingency.fromPair c.reinforcerClass c.operation = c) ∧
    (∀ p : CoreAffectPoint, p.z ≠ 2 → diagToContingency p = none) := by
  refine ⟨?_, ?_, ?_⟩
  · intro p c h
    unfold diagToContingency at h
    by_cases hz2 : p.z = 2
    · have hbz : (p.z == 2) = true := beq_iff_eq.mpr hz2
      rw [hbz] at h
      simp only [↓reduceIte] at h
      by_cases h11 : (p.x == 1 && p.y == 1) = true
      · simp only [Bool.and_eq_true, beq_iff_eq] at h11
        rw [h11.1, h11.2] at h
        have hc : c = .rewPlus := by
          cases h
          rfl
        subst hc
        rcases p with ⟨px, py, pz⟩
        dsimp at h11 hz2
        subst hz2
        rw [h11.1, h11.2]
        exact ⟨rfl, rfl⟩
      · have hb11 : (p.x == 1 && p.y == 1) = false := Bool.eq_false_iff.mpr h11
        rw [hb11] at h
        simp only [Bool.false_eq_true, ↓reduceIte] at h
        by_cases hm11 : (p.x == -1 && p.y == 1) = true
        · simp only [Bool.and_eq_true, beq_iff_eq] at hm11
          rw [hm11.1, hm11.2] at h
          have hc : c = .rewMinus := by
            cases h
            rfl
          subst hc
          rcases p with ⟨px, py, pz⟩
          dsimp at hm11 hz2
          subst hz2
          rw [hm11.1, hm11.2]
          exact ⟨rfl, rfl⟩
        · have hbm11 : (p.x == -1 && p.y == 1) = false := Bool.eq_false_iff.mpr hm11
          rw [hbm11] at h
          simp only [Bool.false_eq_true, ↓reduceIte] at h
          by_cases hmm : (p.x == -1 && p.y == -1) = true
          · simp only [Bool.and_eq_true, beq_iff_eq] at hmm
            rw [hmm.1, hmm.2] at h
            have hc : c = .punPlus := by
              cases h
              rfl
            subst hc
            rcases p with ⟨px, py, pz⟩
            dsimp at hmm hz2
            subst hz2
            rw [hmm.1, hmm.2]
            exact ⟨rfl, rfl⟩
          · have hbmm : (p.x == -1 && p.y == -1) = false := Bool.eq_false_iff.mpr hmm
            rw [hbmm] at h
            simp only [Bool.false_eq_true, ↓reduceIte] at h
            by_cases h1m : (p.x == 1 && p.y == -1) = true
            · simp only [Bool.and_eq_true, beq_iff_eq] at h1m
              rw [h1m.1, h1m.2] at h
              have hc : c = .punMinus := by
                cases h
                rfl
              subst hc
              rcases p with ⟨px, py, pz⟩
              dsimp at h1m hz2
              subst hz2
              rw [h1m.1, h1m.2]
              exact ⟨rfl, rfl⟩
            · have hb1m : (p.x == 1 && p.y == -1) = false := Bool.eq_false_iff.mpr h1m
              rw [hb1m] at h
              cases h
    · have hbz : (p.z == 2) = false := beq_false_of_ne hz2
      rw [hbz] at h
      cases h
  · intro c
    cases c <;> decide
  · intro p hz
    have hbz : (p.z == 2) = false := beq_false_of_ne hz
    unfold diagToContingency
    rw [hbz]
    rfl

/--
Correspondance exacte entre les 4 contingences de Rolls en `Z = 2` et les régimes d'interaction de `AffectiveMatrix`
(`positiveSynergy`, `agenticConfrontation`, `secondaryAccommodation`, `negativeSynergy`).
-/
theorem energyRegime_matches_rolls_contingency :
    ∀ p ∈ z2DiagonalPoints,
      match diagToContingency p with
      | some c =>
          (c = .rewPlus ↔ computeEnergyRegime p.x p.y = .positiveSynergy) ∧
          (c = .rewMinus ↔ computeEnergyRegime p.x p.y = .agenticConfrontation) ∧
          (c = .punMinus ↔ computeEnergyRegime p.x p.y = .secondaryAccommodation) ∧
          (c = .punPlus ↔ computeEnergyRegime p.x p.y = .negativeSynergy)
      | none => False := by
  have h1 : diagToContingency PrimaryCrownPrototype.desir.toPoint = some .rewPlus := rfl
  have h2 : diagToContingency PrimaryCrownPrototype.calme.toPoint = some .punMinus := rfl
  have h3 : diagToContingency PrimaryCrownPrototype.degout.toPoint = some .punPlus := rfl
  have h4 : diagToContingency PrimaryCrownPrototype.colere.toPoint = some .rewMinus := rfl
  intro p hp
  simp only [z2DiagonalPoints, List.mem_cons, List.not_mem_nil, or_false] at hp
  rcases hp with rfl | rfl | rfl | rfl
  · rw [h1]; decide
  · rw [h2]; decide
  · rw [h3]; decide
  · rw [h4]; decide

/--
Loi 3 (Symétrie d'antagonisme de Rolls sur la couronne `Z = 2`) :
Sur les 4 diagonales de `Z = 2`, l'antagoniste statique `antagonistPoint` réalise exactement la symétrie
`Rew+ ↔ Pun+` (`Désir ↔ Dégoût`) et `Rew− ↔ Pun−` (`Colère ↔ Calme`), en inversant simultanément
la classe de stimulus (`reward ↔ punishment`) et la valence (`favorable ↔ aversive`), tout en
conservant l'opérateur (`delivery` ou `omission`).
-/
theorem antagonist_rolls_symmetry_z2 :
    (antagonistPoint PrimaryCrownPrototype.desir.toPoint = PrimaryCrownPrototype.degout.toPoint ∧
     antagonistPoint PrimaryCrownPrototype.colere.toPoint = PrimaryCrownPrototype.calme.toPoint ∧
     RollsContingency.rewPlus.antagonist = .punPlus ∧
     RollsContingency.rewMinus.antagonist = .punMinus) ∧
    (∀ p ∈ z2DiagonalPoints,
      match diagToContingency p, diagToContingency (antagonistPoint p) with
      | some c1, some c2 =>
          c2 = c1.antagonist ∧
          c1.reinforcerClass ≠ c2.reinforcerClass ∧
          c1.outcome ≠ c2.outcome ∧
          c1.operation = c2.operation
      | _, _ => False) := by
  have ha1 : antagonistPoint PrimaryCrownPrototype.desir.toPoint = PrimaryCrownPrototype.degout.toPoint := by decide
  have ha2 : antagonistPoint PrimaryCrownPrototype.calme.toPoint = PrimaryCrownPrototype.colere.toPoint := by decide
  have ha3 : antagonistPoint PrimaryCrownPrototype.degout.toPoint = PrimaryCrownPrototype.desir.toPoint := by decide
  have ha4 : antagonistPoint PrimaryCrownPrototype.colere.toPoint = PrimaryCrownPrototype.calme.toPoint := by decide
  have h1 : diagToContingency PrimaryCrownPrototype.desir.toPoint = some .rewPlus := rfl
  have h2 : diagToContingency PrimaryCrownPrototype.calme.toPoint = some .punMinus := rfl
  have h3 : diagToContingency PrimaryCrownPrototype.degout.toPoint = some .punPlus := rfl
  have h4 : diagToContingency PrimaryCrownPrototype.colere.toPoint = some .rewMinus := rfl
  refine ⟨⟨ha1, ha4, rfl, rfl⟩, ?_⟩
  intro p hp
  simp only [z2DiagonalPoints, List.mem_cons, List.not_mem_nil, or_false] at hp
  rcases hp with rfl | rfl | rfl | rfl
  · rw [ha1, h1, h3]; decide
  · rw [ha2, h2, h4]; decide
  · rw [ha3, h3, h1]; decide
  · rw [ha4, h4, h2]; decide

/--
Loi 4 (Pont géométrique `L1` des pôles axiaux vers les paires de contingences de Rolls en `Z = 2`) :
Chaque pôle axial de `Z = 2` se situe à distance `L1 = 2` des deux prototypes diagonaux partageant
sa polarité engagée (`Courage ↔ {Rew+, Pun−}`, `Peur ↔ {Rew−, Pun+}`, `Joie ↔ {Rew+, Rew−}`,
`Tristesse ↔ {Pun+, Pun−}`) et à distance `L1 = 4` des deux prototypes opposés.
-/
theorem axial_poles_bridge_rolls_pairs :
    (manhattanDistXY PrimaryCrownPrototype.courage.toPoint PrimaryCrownPrototype.desir.toPoint = 2) ∧
    (manhattanDistXY PrimaryCrownPrototype.courage.toPoint PrimaryCrownPrototype.calme.toPoint = 2) ∧
    (manhattanDistXY PrimaryCrownPrototype.courage.toPoint PrimaryCrownPrototype.colere.toPoint = 4) ∧
    (manhattanDistXY PrimaryCrownPrototype.courage.toPoint PrimaryCrownPrototype.degout.toPoint = 4) ∧
    (manhattanDistXY PrimaryCrownPrototype.peur.toPoint PrimaryCrownPrototype.colere.toPoint = 2) ∧
    (manhattanDistXY PrimaryCrownPrototype.peur.toPoint PrimaryCrownPrototype.degout.toPoint = 2) ∧
    (manhattanDistXY PrimaryCrownPrototype.peur.toPoint PrimaryCrownPrototype.desir.toPoint = 4) ∧
    (manhattanDistXY PrimaryCrownPrototype.peur.toPoint PrimaryCrownPrototype.calme.toPoint = 4) ∧
    (manhattanDistXY PrimaryCrownPrototype.joie.toPoint PrimaryCrownPrototype.desir.toPoint = 2) ∧
    (manhattanDistXY PrimaryCrownPrototype.joie.toPoint PrimaryCrownPrototype.colere.toPoint = 2) ∧
    (manhattanDistXY PrimaryCrownPrototype.joie.toPoint PrimaryCrownPrototype.calme.toPoint = 4) ∧
    (manhattanDistXY PrimaryCrownPrototype.joie.toPoint PrimaryCrownPrototype.degout.toPoint = 4) ∧
    (manhattanDistXY PrimaryCrownPrototype.tristesse.toPoint PrimaryCrownPrototype.calme.toPoint = 2) ∧
    (manhattanDistXY PrimaryCrownPrototype.tristesse.toPoint PrimaryCrownPrototype.degout.toPoint = 2) ∧
    (manhattanDistXY PrimaryCrownPrototype.tristesse.toPoint PrimaryCrownPrototype.desir.toPoint = 4) ∧
    (manhattanDistXY PrimaryCrownPrototype.tristesse.toPoint PrimaryCrownPrototype.colere.toPoint = 4) := by
  decide

/-- Les quatre orientations axiales précèdent la spécification d'une contingence diagonale de Rolls en `Z = 2`. -/
theorem axial_poles_pre_contingency :
    ∀ p ∈ z2AxialPoints, diagToContingency p = none := by
  decide

/--
Bijection exacte $2 \times 2$ entre les 4 positions diagonales de `Z = 2` et les 4 contingences de Rolls
`{Rew+, Rew−, Pun+, Pun−}` (isomorphe à `RollsReinforcerClass × RollsOperation`).
-/
theorem z2_rolls_bijection_2x2 :
    (∀ c : RollsContingency,
      ∃ p ∈ z2DiagonalPoints, diagToContingency p = some c) ∧
    (∀ p₁ ∈ z2DiagonalPoints, ∀ p₂ ∈ z2DiagonalPoints,
      diagToContingency p₁ = diagToContingency p₂ → p₁ = p₂) ∧
    (∀ (cls : RollsReinforcerClass) (op : RollsOperation),
      ∃ p ∈ z2DiagonalPoints,
        diagToContingency p = some (RollsContingency.fromPair cls op) ∧
        (RollsContingency.fromPair cls op).reinforcerClass = cls ∧
        (RollsContingency.fromPair cls op).operation = op) := by
  refine ⟨?_, ?_, ?_⟩
  · intro c
    cases c
    · exact ⟨PrimaryCrownPrototype.desir.toPoint, by decide, rfl⟩
    · exact ⟨PrimaryCrownPrototype.colere.toPoint, by decide, rfl⟩
    · exact ⟨PrimaryCrownPrototype.degout.toPoint, by decide, rfl⟩
    · exact ⟨PrimaryCrownPrototype.calme.toPoint, by decide, rfl⟩
  · decide
  · intro cls op
    cases cls <;> cases op
    · exact ⟨PrimaryCrownPrototype.desir.toPoint, by decide, rfl, rfl, rfl⟩
    · exact ⟨PrimaryCrownPrototype.colere.toPoint, by decide, rfl, rfl, rfl⟩
    · exact ⟨PrimaryCrownPrototype.degout.toPoint, by decide, rfl, rfl, rfl⟩
    · exact ⟨PrimaryCrownPrototype.calme.toPoint, by decide, rfl, rfl, rfl⟩

end OperantFactorization

end Cartograffect
