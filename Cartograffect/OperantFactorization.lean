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
## Articulation des contingences opérantes et pavloviennes sur la fondation `Z = 2` (v3.0)

Ce module relie formellement les quatre prototypes diagonaux de la **première couronne (`Z = 2`)**
aux régimes d'apprentissage associatif et instrumental (Skinner, 1953 ; Rolls, 2005, 2014),
conformément à l'**Option 1A** (`Y` = contrôlabilité instrumentale perçue stricte) et sans aucun
relèvement universel sur les strates supérieures (`Z ≥ 3`) :

1. **Régime opérant actif (`Y = +1 > 0`, contrôle instrumental perçu élevé) :**
   - `activeOperantReinforcement` en `Désir (+1, +1, 2)` : englobe le **renforcement positif opérant
     (`R+` : acquisition active d'une issue appétitive)** ET le **renforcement négatif opérant
     (`R-` : évitement ou échappement actif réussi, exigeant `Y > 0`)**.
   - `agenticOmissionPunishment` en `Colère (-1, +1, 2)` : **omission / blocage frustratif (`P-` /
     sursaut d'extinction)** où une issue attendue est contrariée tandis que l'agent maintient une
     prise instrumentale active (`Y > 0`) pour lever l'obstacle.
2. **Régime non opérant / pavlovien et d'accommodation (`Y = -1 < 0`, faible contrôle instrumental) :**
   - `pavlovianPassiveSafety` en `Calme (+1, -1, 2)` : **soulagement pavlovien passif** (cessation
     exogène d'un stimulus aversif → signal de sécurité passive) et **accommodation / contrôle
     secondaire face à une limite objective d'action**, rigoureusement distinct du renforcement
     négatif opérant `R-` (qui exige `Y > 0`).
   - `inescapableAversivePunishment` en `Dégoût (-1, -1, 2)` : **exposition aversive subie (`P+`
     à faible contrôle)** face à un événement non révisable et non modifiable par l'action.
-/

/-- Distance de Manhattan intra-plan (métrique `L1` sur `(X, Y)`) entre deux coordonnées du Noyau. -/
def manhattanDistXY (p q : CoreAffectPoint) : Nat :=
  (p.x - q.x).natAbs + (p.y - q.y).natAbs

/-- Cohérence directe de `manhattanDistXY` avec `CoreAffectPoint.displacementSum` depuis l'origine de strate. -/
theorem manhattanDistXY_origin (p : CoreAffectPoint) :
    manhattanDistXY p ⟨0, 0, p.z⟩ = p.displacementSum := by
  dsimp [manhattanDistXY, CoreAffectPoint.displacementSum]
  simp only [Int.sub_zero]

/-- Issue adaptative sur l'Axe X (`+X` favorable vs `-X` aversif/contrarié). -/
inductive AdaptiveOutcome : Type where
  | favorable : AdaptiveOutcome
  | aversive  : AdaptiveOutcome
  deriving DecidableEq, Repr, Inhabited

/-- Régime d'agentivité instrumentale sur l'Axe Y (`+Y` opérant actif vs `-Y` passif/accommodation). -/
inductive InstrumentalAgency : Type where
  | activeOperant           : InstrumentalAgency -- Y > 0 : l'action modifie la contingence (inclut R+ et R- actif)
  | nonOperantAccommodation : InstrumentalAgency -- Y < 0 : limite objective d'action (sécurité pavlovienne ou P+ subi)
  deriving DecidableEq, Repr, Inhabited

/-- Les deux sous-modalités du renforcement opérant actif exigeant toutes deux `Y > 0` et `X > 0`. -/
inductive ActiveReinforcementMode : Type where
  | positiveAddition        : ActiveReinforcementMode -- R+ : obtention active d'une issue appétitive
  | negativeEscapeAvoidance : ActiveReinforcementMode -- R- : évitement / échappement actif d'un aversif (exige Y > 0)
  deriving DecidableEq, Repr, Inhabited

/-- Les quatre régimes écologiques fondamentaux bornés exclusivement aux diagonales de `Z = 2`. -/
inductive Z2ContingencyRegime : Type where
  | activeOperantReinforcement    : Z2ContingencyRegime -- (+1, +1, 2) Désir : R+ et R- opérant actif (X > 0, Y > 0)
  | agenticOmissionPunishment     : Z2ContingencyRegime -- (-1, +1, 2) Colère : P- / blocage sous prise active (X < 0, Y > 0)
  | pavlovianPassiveSafety        : Z2ContingencyRegime -- (+1, -1, 2) Calme : sécurité pavlovienne passive / accommodation (X > 0, Y < 0)
  | inescapableAversivePunishment : Z2ContingencyRegime -- (-1, -1, 2) Dégoût : P+ aversif subi à faible contrôle (X < 0, Y < 0)
  deriving DecidableEq, Repr, Inhabited

/-- Issue adaptative associée à chaque régime de `Z = 2`. -/
def Z2ContingencyRegime.outcome : Z2ContingencyRegime → AdaptiveOutcome
  | .activeOperantReinforcement    => .favorable
  | .pavlovianPassiveSafety        => .favorable
  | .agenticOmissionPunishment     => .aversive
  | .inescapableAversivePunishment => .aversive

/-- Régime d'agentivité instrumentale associé à chaque régime de `Z = 2`. -/
def Z2ContingencyRegime.agency : Z2ContingencyRegime → InstrumentalAgency
  | .activeOperantReinforcement    => .activeOperant
  | .agenticOmissionPunishment     => .activeOperant
  | .pavlovianPassiveSafety        => .nonOperantAccommodation
  | .inescapableAversivePunishment => .nonOperantAccommodation

/-- Tout sous-mode de renforcement opérant actif (`R+` comme `R-` d'évitement/échappement) relève
    exclusivement de `activeOperantReinforcement` (`Y > 0`), jamais de `pavlovianPassiveSafety` (`Y < 0`). -/
def activeModeToRegime : ActiveReinforcementMode → Z2ContingencyRegime
  | .positiveAddition        => .activeOperantReinforcement
  | .negativeEscapeAvoidance => .activeOperantReinforcement

/--
Projection partielle stricte bornée à la fondation `Z = 2` :
associe uniquement les 4 positions diagonales de `Z = 2` à leur `Z2ContingencyRegime`, et renvoie
`none` sur les axes, les centres et **toutes les strates `Z ≠ 2`** (aucun relèvement en `Z = 3..7`).
-/
def diagToContingency (p : CoreAffectPoint) : Option Z2ContingencyRegime :=
  if p.z == 2 then
    if p.x == 1 && p.y == 1 then some .activeOperantReinforcement
    else if p.x == -1 && p.y == 1 then some .agenticOmissionPunishment
    else if p.x == 1 && p.y == -1 then some .pavlovianPassiveSafety
    else if p.x == -1 && p.y == -1 then some .inescapableAversivePunishment
    else none
  else
    none

/-- Projection d'un prototype de la première couronne `PrimaryCrownPrototype` vers son régime `Z = 2`. -/
def prototypeToContingency (proto : PrimaryCrownPrototype) : Option Z2ContingencyRegime :=
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
Loi 1 (Factorisation complète sur la fondation `Z = 2`) :
Sur les 4 diagonales de la première couronne :
- `X` détermine l'issue adaptative (`+1 ↔ favorable`, `-1 ↔ aversive`) et la valence hédonique ;
- `Y` détermine l'agentivité instrumentale (`+1 ↔ activeOperant`, `-1 ↔ nonOperantAccommodation`).
-/
theorem operant_factorization_law :
    ∀ p ∈ z2DiagonalPoints,
      match diagToContingency p with
      | some c =>
          (c.outcome = .favorable ↔ p.x = 1) ∧
          (c.outcome = .aversive ↔ p.x = -1) ∧
          (c.agency = .activeOperant ↔ p.y = 1) ∧
          (c.agency = .nonOperantAccommodation ↔ p.y = -1) ∧
          (computeHedonicPolarity p.x p.y = .positive ↔ c.outcome = .favorable)
      | none => False := by
  have h1 : diagToContingency PrimaryCrownPrototype.desir.toPoint = some .activeOperantReinforcement := rfl
  have h2 : diagToContingency PrimaryCrownPrototype.calme.toPoint = some .pavlovianPassiveSafety := rfl
  have h3 : diagToContingency PrimaryCrownPrototype.degout.toPoint = some .inescapableAversivePunishment := rfl
  have h4 : diagToContingency PrimaryCrownPrototype.colere.toPoint = some .agenticOmissionPunishment := rfl
  intro p hp
  simp only [z2DiagonalPoints, List.mem_cons, List.not_mem_nil, or_false] at hp
  rcases hp with rfl | rfl | rfl | rfl
  · rw [h1]; decide
  · rw [h2]; decide
  · rw [h3]; decide
  · rw [h4]; decide

/--
Loi 2 (Séparation stricte entre renforcement négatif opérant `R-` et sécurité pavlovienne passive,
et absence de relèvement au-delà de `Z = 2`) :
- Toute réalisation du renforcement négatif opérant `R-` (`negativeEscapeAvoidance`) exige `p.y > 0`
  et se distingue formellement du pôle `Calme (+1, -1, 2)` (`pavlovianPassiveSafety`, `p.y < 0`) ;
- Toute position située hors de `Z = 2` (`p.z ≠ 2`, incluant `Z ≥ 3`) renvoie `diagToContingency p = none`.
-/
theorem active_r_minus_vs_pavlovian_safety_and_z2_bound :
    (∀ (p : CoreAffectPoint) (m : ActiveReinforcementMode),
      diagToContingency p = some (activeModeToRegime m) →
      p.x > 0 ∧ p.y > 0 ∧ p.z = 2 ∧ activeModeToRegime m ≠ .pavlovianPassiveSafety) ∧
    (diagToContingency PrimaryCrownPrototype.calme.toPoint = some .pavlovianPassiveSafety ∧
     PrimaryCrownPrototype.calme.toPoint.y < 0) ∧
    (∀ p : CoreAffectPoint, p.z ≠ 2 → diagToContingency p = none) := by
  refine ⟨?_, by decide, ?_⟩
  · intro p m h
    unfold diagToContingency activeModeToRegime at h
    by_cases hz2 : p.z = 2
    · have hbz : (p.z == 2) = true := beq_iff_eq.mpr hz2
      rw [hbz] at h
      simp only [↓reduceIte] at h
      by_cases h11 : (p.x == 1 && p.y == 1) = true
      · simp only [Bool.and_eq_true, beq_iff_eq] at h11
        rcases h11 with ⟨hx1, hy1⟩
        exact ⟨by omega, by omega, hz2, by cases m <;> decide⟩
      · have hb11 : (p.x == 1 && p.y == 1) = false := Bool.eq_false_iff.mpr h11
        rw [hb11] at h
        simp only [Bool.false_eq_true, ↓reduceIte] at h
        cases m <;> (
          dsimp [activeModeToRegime] at h
          split at h
          · cases h
          · split at h
            · cases h
            · split at h <;> cases h
        )
    · have hbz : (p.z == 2) = false := beq_false_of_ne hz2
      rw [hbz] at h
      cases h
  · intro p hz
    have hbz : (p.z == 2) = false := beq_false_of_ne hz
    unfold diagToContingency
    rw [hbz]
    rfl

/--
Correspondance exacte entre les 4 régimes de `Z = 2` et les régimes d'interaction de `AffectiveMatrix`
(`positiveSynergy`, `agenticConfrontation`, `secondaryAccommodation`, `negativeSynergy`).
-/
theorem energyRegime_matches_operant_operator :
    ∀ p ∈ z2DiagonalPoints,
      match diagToContingency p with
      | some c =>
          (c = .activeOperantReinforcement ↔ computeEnergyRegime p.x p.y = .positiveSynergy) ∧
          (c = .agenticOmissionPunishment ↔ computeEnergyRegime p.x p.y = .agenticConfrontation) ∧
          (c = .pavlovianPassiveSafety ↔ computeEnergyRegime p.x p.y = .secondaryAccommodation) ∧
          (c = .inescapableAversivePunishment ↔ computeEnergyRegime p.x p.y = .negativeSynergy)
      | none => False := by
  have h1 : diagToContingency PrimaryCrownPrototype.desir.toPoint = some .activeOperantReinforcement := rfl
  have h2 : diagToContingency PrimaryCrownPrototype.calme.toPoint = some .pavlovianPassiveSafety := rfl
  have h3 : diagToContingency PrimaryCrownPrototype.degout.toPoint = some .inescapableAversivePunishment := rfl
  have h4 : diagToContingency PrimaryCrownPrototype.colere.toPoint = some .agenticOmissionPunishment := rfl
  intro p hp
  simp only [z2DiagonalPoints, List.mem_cons, List.not_mem_nil, or_false] at hp
  rcases hp with rfl | rfl | rfl | rfl
  · rw [h1]; decide
  · rw [h2]; decide
  · rw [h3]; decide
  · rw [h4]; decide

/--
Loi 3 (Dualité antagoniste sur la couronne `Z = 2`) :
Sur les 4 diagonales de `Z = 2`, l'antagoniste statique `antagonistPoint` inverse simultanément
l'issue adaptative (`favorable ↔ aversive`) et le régime d'agentivité (`activeOperant ↔ nonOperantAccommodation`),
appariant `Désir (R+/R- actif)` à `Dégoût (P+ subi)` et `Colère (P- actif)` à `Calme (sécurité pavlovienne)`.
-/
theorem antagonist_flips_outcome_and_agency_z2 :
    ∀ p ∈ z2DiagonalPoints,
      match diagToContingency p, diagToContingency (antagonistPoint p) with
      | some c1, some c2 => c1.outcome ≠ c2.outcome ∧ c1.agency ≠ c2.agency
      | _, _ => False := by
  have ha1 : antagonistPoint PrimaryCrownPrototype.desir.toPoint = PrimaryCrownPrototype.degout.toPoint := by decide
  have ha2 : antagonistPoint PrimaryCrownPrototype.calme.toPoint = PrimaryCrownPrototype.colere.toPoint := by decide
  have ha3 : antagonistPoint PrimaryCrownPrototype.degout.toPoint = PrimaryCrownPrototype.desir.toPoint := by decide
  have ha4 : antagonistPoint PrimaryCrownPrototype.colere.toPoint = PrimaryCrownPrototype.calme.toPoint := by decide
  have h1 : diagToContingency PrimaryCrownPrototype.desir.toPoint = some .activeOperantReinforcement := rfl
  have h2 : diagToContingency PrimaryCrownPrototype.calme.toPoint = some .pavlovianPassiveSafety := rfl
  have h3 : diagToContingency PrimaryCrownPrototype.degout.toPoint = some .inescapableAversivePunishment := rfl
  have h4 : diagToContingency PrimaryCrownPrototype.colere.toPoint = some .agenticOmissionPunishment := rfl
  intro p hp
  simp only [z2DiagonalPoints, List.mem_cons, List.not_mem_nil, or_false] at hp
  rcases hp with rfl | rfl | rfl | rfl
  · rw [ha1, h1, h3]; decide
  · rw [ha2, h2, h4]; decide
  · rw [ha3, h3, h1]; decide
  · rw [ha4, h4, h2]; decide

/--
Loi 4 (Pont géométrique `L1` des pôles axiaux vers les paires de régimes en `Z = 2`) :
Chaque pôle axial de `Z = 2` se situe à distance `L1 = 2` des deux prototypes diagonaux partageant
sa polarité engagée et à distance `L1 = 4` des deux prototypes opposés.
-/
theorem axial_poles_bridge_operant_pairs :
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

/-- Les quatre orientations axiales précèdent la spécification d'un régime diagonal de `Z = 2`. -/
theorem axial_poles_pre_operant :
    ∀ p ∈ z2AxialPoints, diagToContingency p = none := by
  decide

/-- Bijection exacte entre les 4 positions diagonales de `Z = 2` et les 4 régimes mixtes opérants-pavloviens `Z2ContingencyRegime`. -/
theorem z2_contingency_regime_bijection :
    (∀ c : Z2ContingencyRegime,
      ∃ p ∈ z2DiagonalPoints, diagToContingency p = some c) ∧
    (∀ p₁ ∈ z2DiagonalPoints, ∀ p₂ ∈ z2DiagonalPoints,
      diagToContingency p₁ = diagToContingency p₂ → p₁ = p₂) := by
  constructor
  · intro c
    cases c
    · exact ⟨PrimaryCrownPrototype.desir.toPoint, by decide, rfl⟩
    · exact ⟨PrimaryCrownPrototype.colere.toPoint, by decide, rfl⟩
    · exact ⟨PrimaryCrownPrototype.calme.toPoint, by decide, rfl⟩
    · exact ⟨PrimaryCrownPrototype.degout.toPoint, by decide, rfl⟩
  · decide

end OperantFactorization

end Cartograffect
