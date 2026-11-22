/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
Author: Manuel Cabelguen
-/

import Cartograffect.CoreAffect
import Cartograffect.AffectiveMatrix

namespace Cartograffect

namespace OperantFactorization

open CoreAffect
open AffectiveMatrix

/-!
## Factorisation structurale des contingences opérantes sur la couronne Z = 2

Ce module dérivé relie formellement les prototypes de la première couronne (`Z = 2`)
aux quatre contingences du conditionnement opérant (`R+`, `R-`, `P+`, `P-`) sans
altérer les modules existants du noyau :
- L'Axe X discrimine l'issue fonctionnelle (`Reinforcement` pour `X = +1`, `Punishment` pour `X = -1`),
  en coïncidence exacte avec la polarité hédonique lexicographique.
- L'Axe Y discrimine la posture pragmatique d'engagement actif (`Y = +1` : `R+` ou `P-`)
  versus désengagement/relâchement (`Y = -1` : `R-` ou `P+`).
- Le produit `X * Y` discrimine l'opérateur d'ajout (`Addition`, diagonale de congruence)
  et l'opérateur de retrait (`Removal`, diagonale de compensation), en correspondance exacte
  avec `EnergyRegime`.
- L'antagoniste régulateur `antagonistPoint` inverse `Reinforcement ↔ Punishment` tout en
  conservant l'opérateur (`Addition` ou `Removal`).
- Chaque pôle axial (`Courage`, `Peur`, `Joie`, `Tristesse`) se situe à distance `L1 = 2`
  des deux diagonales partageant sa propriété génératrice et à distance `L1 = 4` des deux autres.
-/

/-- Distance de Manhattan intra-plan (métrique L1 sur `(X, Y)`) entre deux coordonnées du Noyau. -/
def manhattanDistXY (p q : CoreAffectPoint) : Nat :=
  (p.x - q.x).natAbs + (p.y - q.y).natAbs

/-- Cohérence directe de `manhattanDistXY` avec `CoreAffectPoint.displacementSum` depuis l'origine de strate. -/
theorem manhattanDistXY_origin (p : CoreAffectPoint) :
    manhattanDistXY p ⟨0, 0, p.z⟩ = p.displacementSum := by
  dsimp [manhattanDistXY, CoreAffectPoint.displacementSum]
  simp only [Int.sub_zero]

/-- Issue fonctionnelle de la contingence opérante : renforcement (`R`) ou punition (`P`). -/
inductive OperantEffect : Type where
  | Reinforcement : OperantEffect
  | Punishment    : OperantEffect
  deriving DecidableEq, Repr, Inhabited

/-- Opérateur écologique de la contingence : ajout (`+`) ou retrait (`-`). -/
inductive OperantOperator : Type where
  | Addition : OperantOperator
  | Removal  : OperantOperator
  deriving DecidableEq, Repr, Inhabited

/-- Structure d'une contingence opérante élémentaire `{R+, R-, P+, P-}`. -/
structure OperantContingency where
  effect : OperantEffect
  op     : OperantOperator
  deriving DecidableEq, Repr, Inhabited

/-- Projection algébrique exacte des 4 positions diagonales de `Z = 2` sur `{R+, R-, P+, P-}`. -/
def diagToContingency (p : CoreAffectPoint) : Option OperantContingency :=
  match p.x, p.y, p.z with
  |  1,  1, 2 => some ⟨.Reinforcement, .Addition⟩ -- Désir (R+)
  |  1, -1, 2 => some ⟨.Reinforcement, .Removal⟩  -- Calme (R-)
  | -1, -1, 2 => some ⟨.Punishment,    .Addition⟩ -- Dégoût (P+)
  | -1,  1, 2 => some ⟨.Punishment,    .Removal⟩  -- Colère (P-)
  | _,   _, _ => none

/-- Projection opérante d'un prototype de la première couronne `PrimaryCrownPrototype`. -/
def prototypeToContingency (proto : PrimaryCrownPrototype) : Option OperantContingency :=
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

private theorem diagToContingency_desir :
    diagToContingency PrimaryCrownPrototype.desir.toPoint = some ⟨.Reinforcement, .Addition⟩ := rfl

private theorem diagToContingency_calme :
    diagToContingency PrimaryCrownPrototype.calme.toPoint = some ⟨.Reinforcement, .Removal⟩ := rfl

private theorem diagToContingency_degout :
    diagToContingency PrimaryCrownPrototype.degout.toPoint = some ⟨.Punishment, .Addition⟩ := rfl

private theorem diagToContingency_colere :
    diagToContingency PrimaryCrownPrototype.colere.toPoint = some ⟨.Punishment, .Removal⟩ := rfl

/--
Loi 1 (Factorisation complète des contingences opérantes en `Z = 2`) :
Sur les 4 diagonales de la première couronne :
- `X` détermine l'effet (`+1 ↔ Reinforcement`, `-1 ↔ Punishment`) ainsi que la valence hédonique ;
- `X * Y` détermine l'opérateur (`+1 ↔ Addition`, `-1 ↔ Removal`) ;
- `Y = +1` caractérise exactement les deux contingences d'engagement actif appétitif (`R+` ou `P-`).
-/
theorem operant_factorization_law :
    ∀ p ∈ z2DiagonalPoints,
      match diagToContingency p with
      | some c =>
          (c.effect = .Reinforcement ↔ p.x = 1) ∧
          (c.effect = .Punishment ↔ p.x = -1) ∧
          (c.op = .Addition ↔ p.x * p.y = 1) ∧
          (c.op = .Removal ↔ p.x * p.y = -1) ∧
          ((c = ⟨.Reinforcement, .Addition⟩ ∨ c = ⟨.Punishment, .Removal⟩) ↔ p.y = 1) ∧
          (computeHedonicPolarity p.x p.y = .positive ↔ c.effect = .Reinforcement)
      | none => False := by
  intro p hp
  simp only [z2DiagonalPoints, List.mem_cons, List.not_mem_nil, or_false] at hp
  rcases hp with rfl | rfl | rfl | rfl
  · rw [diagToContingency_desir]; dsimp only; decide
  · rw [diagToContingency_calme]; dsimp only; decide
  · rw [diagToContingency_degout]; dsimp only; decide
  · rw [diagToContingency_colere]; dsimp only; decide

/--
Correspondance exacte entre l'opérateur écologique (`Addition` vs `Removal`) et les régimes
énergétiques de `AffectiveMatrix` (diagonale de congruence vs diagonale de compensation).
-/
theorem energyRegime_matches_operant_operator :
    ∀ p ∈ z2DiagonalPoints,
      match diagToContingency p with
      | some c =>
          (c.op = .Addition ↔
            computeEnergyRegime p.x p.y = .positiveSynergy ∨
            computeEnergyRegime p.x p.y = .negativeSynergy) ∧
          (c.op = .Removal ↔
            computeEnergyRegime p.x p.y = .ergotropicCompensation ∨
            computeEnergyRegime p.x p.y = .trophotropicRelease)
      | none => False := by
  intro p hp
  simp only [z2DiagonalPoints, List.mem_cons, List.not_mem_nil, or_false] at hp
  rcases hp with rfl | rfl | rfl | rfl
  · rw [diagToContingency_desir]; dsimp only; decide
  · rw [diagToContingency_calme]; dsimp only; decide
  · rw [diagToContingency_degout]; dsimp only; decide
  · rw [diagToContingency_colere]; dsimp only; decide

/--
Loi 2 (Dualité antagoniste opérante) :
L'opérateur natif `antagonistPoint` inverse `Reinforcement ↔ Punishment` tout en conservant
strictement l'opérateur écologique d'ajout (`Addition`) ou de retrait (`Removal`).
-/
theorem antagonist_flips_effect_preserves_operator :
    ∀ p ∈ z2DiagonalPoints,
      match diagToContingency p, diagToContingency (antagonistPoint p) with
      | some c1, some c2 => c1.effect ≠ c2.effect ∧ c1.op = c2.op
      | _, _ => False := by
  intro p hp
  simp only [z2DiagonalPoints, List.mem_cons, List.not_mem_nil, or_false] at hp
  rcases hp with rfl | rfl | rfl | rfl
  · change OperantEffect.Reinforcement ≠ OperantEffect.Punishment ∧
      OperantOperator.Addition = OperantOperator.Addition; decide
  · change OperantEffect.Reinforcement ≠ OperantEffect.Punishment ∧
      OperantOperator.Removal = OperantOperator.Removal; decide
  · change OperantEffect.Punishment ≠ OperantEffect.Reinforcement ∧
      OperantOperator.Addition = OperantOperator.Addition; decide
  · change OperantEffect.Punishment ≠ OperantEffect.Reinforcement ∧
      OperantOperator.Removal = OperantOperator.Removal; decide

/--
Loi 3 (Pont géométrique L1 des pôles axiaux vers les paires opérantes) :
Chaque pôle axial de `Z = 2` (`Courage`, `Peur`, `Joie`, `Tristesse`) est à distance `L1 = 2`
des deux prototypes diagonaux partageant sa propriété génératrice et à distance `L1 = 4`
des deux prototypes diagonaux opposés.
-/
theorem axial_poles_bridge_operant_pairs :
    -- Courage (+2, 0, 2) amorce R+ (Désir) et R- (Calme) à L1 = 2 ; loin (L1 = 4) de P- et P+
    (manhattanDistXY PrimaryCrownPrototype.courage.toPoint PrimaryCrownPrototype.desir.toPoint = 2) ∧
    (manhattanDistXY PrimaryCrownPrototype.courage.toPoint PrimaryCrownPrototype.calme.toPoint = 2) ∧
    (manhattanDistXY PrimaryCrownPrototype.courage.toPoint PrimaryCrownPrototype.colere.toPoint = 4) ∧
    (manhattanDistXY PrimaryCrownPrototype.courage.toPoint PrimaryCrownPrototype.degout.toPoint = 4) ∧
    -- Peur (-2, 0, 2) amorce P- (Colère) et P+ (Dégoût) à L1 = 2 ; loin (L1 = 4) de R+ et R-
    (manhattanDistXY PrimaryCrownPrototype.peur.toPoint PrimaryCrownPrototype.colere.toPoint = 2) ∧
    (manhattanDistXY PrimaryCrownPrototype.peur.toPoint PrimaryCrownPrototype.degout.toPoint = 2) ∧
    (manhattanDistXY PrimaryCrownPrototype.peur.toPoint PrimaryCrownPrototype.desir.toPoint = 4) ∧
    (manhattanDistXY PrimaryCrownPrototype.peur.toPoint PrimaryCrownPrototype.calme.toPoint = 4) ∧
    -- Joie (0, +2, 2) amorce l'approche active R+ (Désir) et P- (Colère) à L1 = 2 ; loin (L1 = 4) de R- et P+
    (manhattanDistXY PrimaryCrownPrototype.joie.toPoint PrimaryCrownPrototype.desir.toPoint = 2) ∧
    (manhattanDistXY PrimaryCrownPrototype.joie.toPoint PrimaryCrownPrototype.colere.toPoint = 2) ∧
    (manhattanDistXY PrimaryCrownPrototype.joie.toPoint PrimaryCrownPrototype.calme.toPoint = 4) ∧
    (manhattanDistXY PrimaryCrownPrototype.joie.toPoint PrimaryCrownPrototype.degout.toPoint = 4) ∧
    -- Tristesse (0, -2, 2) amorce le désengagement R- (Calme) et P+ (Dégoût) à L1 = 2 ; loin (L1 = 4) de R+ et P-
    (manhattanDistXY PrimaryCrownPrototype.tristesse.toPoint PrimaryCrownPrototype.calme.toPoint = 2) ∧
    (manhattanDistXY PrimaryCrownPrototype.tristesse.toPoint PrimaryCrownPrototype.degout.toPoint = 2) ∧
    (manhattanDistXY PrimaryCrownPrototype.tristesse.toPoint PrimaryCrownPrototype.desir.toPoint = 4) ∧
    (manhattanDistXY PrimaryCrownPrototype.tristesse.toPoint PrimaryCrownPrototype.colere.toPoint = 4) := by
  decide

/-- Les quatre orientations axiales précèdent la spécification complète d'une contingence `{R+, R-, P+, P-}`. -/
theorem axial_poles_pre_operant :
    ∀ p ∈ z2AxialPoints, diagToContingency p = none := by
  decide

/-- Bijection exacte entre les 4 positions diagonales de `Z = 2` et les 4 contingences opérantes. -/
theorem operant_bijection_on_z2_diagonals :
    (∀ c : OperantContingency,
      ∃ p ∈ z2DiagonalPoints, diagToContingency p = some c) ∧
    (∀ p₁ ∈ z2DiagonalPoints, ∀ p₂ ∈ z2DiagonalPoints,
      diagToContingency p₁ = diagToContingency p₂ → p₁ = p₂) := by
  constructor
  · intro c
    rcases c with ⟨e, o⟩
    cases e <;> cases o
    · exact ⟨PrimaryCrownPrototype.desir.toPoint, by decide, rfl⟩
    · exact ⟨PrimaryCrownPrototype.calme.toPoint, by decide, rfl⟩
    · exact ⟨PrimaryCrownPrototype.degout.toPoint, by decide, rfl⟩
    · exact ⟨PrimaryCrownPrototype.colere.toPoint, by decide, rfl⟩
  · decide

end OperantFactorization

end Cartograffect
