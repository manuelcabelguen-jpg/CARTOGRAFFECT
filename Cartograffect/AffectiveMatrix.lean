/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
Author: Manuel Cabelguen
-/

import Cartograffect.PredictiveEngine
import Cartograffect.CoreAffect

namespace Cartograffect

namespace AffectiveMatrix

open PredictiveEngine
open CoreAffect

/-!
## 1. Transduction phénoménologique : Pôles vécus, Valence et Activation
-/

-- Source : Document 1, §6 (La Matrice affective - Transduction sur le gradient d'Attente)
/--
Traduction vécue (hypothèse de correspondance) du pôle computationnel sur l'Axe X (Attente) :
- `epistemicCharge`    (X < 0) : suspension de la signification, perspective d'une menace ou coût de révision.
- `epistemicNeutral`   (X = 0) : absence de contribution polarisée propre sur la dimension épistémique.
- `epistemicDischarge` (X > 0) : résorption de l'incertitude épistémique, impression de prédictibilité ou d'opportunité.
-/
inductive LivedExpectationPole : Type where
  | epistemicCharge    : LivedExpectationPole
  | epistemicNeutral   : LivedExpectationPole
  | epistemicDischarge : LivedExpectationPole
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 1, §6 (La Matrice affective - Transduction sur le gradient de Contrôle)
/--
Traduction vécue (hypothèse de correspondance) du pôle computationnel sur l'Axe Y (Contrôle) :
- `pragmaticCharge`    (Y < 0) : impuissance perçue, hésitation ou inhibition de l'action.
- `pragmaticNeutral`   (Y = 0) : absence de contribution polarisée propre sur la dimension pragmatique.
- `pragmaticDischarge` (Y > 0) : puissance d'agir et mobilisation énergétique ciblée.
-/
inductive LivedControlPole : Type where
  | pragmaticCharge    : LivedControlPole
  | pragmaticNeutral   : LivedControlPole
  | pragmaticDischarge : LivedControlPole
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 1, Résumé, §6 & §6.3 (Dynamique de la tension allostatique et Valence)
/--
Valence phénoménologique issue de l'interprétation conjointe des deux pôles et de la variation
de la tension allostatique :
- `homeostaticNeutral`     : maintien basal ou suspension opératoire au centre (X = 0 et Y = 0).
- `pleasantDissipation`    : dissipation nette de la tension allostatique (décharge sans charge adverse).
- `unpleasantAccumulation` : accumulation nette de la tension allostatique (charge sans décharge compensatoire).
- `mixedCompensation`      : régime de compensation combinant une charge sur un axe et une décharge sur l'autre.
-/
inductive PhenomenologicalValence : Type where
  | homeostaticNeutral     : PhenomenologicalValence
  | pleasantDissipation    : PhenomenologicalValence
  | unpleasantAccumulation : PhenomenologicalValence
  | mixedCompensation      : PhenomenologicalValence
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 1, Résumé & §6 (Activation et sélection d'une politique d'action)
/--
Niveau d'activation qualifiant l'amplitude de mobilisation de la trajectoire :
- `basalWakefulness`   : maintien homéostatique de fond au Point de Veille (0, 0, 0).
- `operatorSuspension` : suspension de la décharge immédiate au centre opérateur (0, 0, Z ≥ 1).
- `lowInhibition`      : repli, réduction ou suspension de l'effort moteur (Y < 0).
- `epistemicVigilance` : mobilisation purement épistémique à Contrôle neutre (Y = 0 et X ≠ 0).
- `highMobilization`   : mobilisation énergétique et motrice active (Y > 0).
-/
inductive PhenomenologicalActivation : Type where
  | basalWakefulness   : PhenomenologicalActivation
  | operatorSuspension : PhenomenologicalActivation
  | lowInhibition      : PhenomenologicalActivation
  | epistemicVigilance : PhenomenologicalActivation
  | highMobilization   : PhenomenologicalActivation
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 1, §6 (La Matrice affective)
/-- Transduction de la coordonnée X en pôle vécu d'Attente. -/
def transduceExpectation (x : Int) : LivedExpectationPole :=
  if x < 0 then .epistemicCharge
  else if x > 0 then .epistemicDischarge
  else .epistemicNeutral

-- Source : Document 1, §6 (La Matrice affective)
/-- Transduction de la coordonnée Y en pôle vécu de Contrôle. -/
def transduceControl (y : Int) : LivedControlPole :=
  if y < 0 then .pragmaticCharge
  else if y > 0 then .pragmaticDischarge
  else .pragmaticNeutral

-- Source : Document 1, §6 (Interprétation conjointe des deux pôles pour la valence)
/--
Calcul de la valence vécue à partir de la configuration conjointe (X, Y) :
La valence n'émerge qu'au niveau de la Matrice par la lecture conjointe des deux dimensions.
-/
def computeValence (p : CoreAffectPoint) : PhenomenologicalValence :=
  if p.x = 0 ∧ p.y = 0 then
    .homeostaticNeutral
  else if p.x ≥ 0 ∧ p.y ≥ 0 then
    .pleasantDissipation
  else if p.x ≤ 0 ∧ p.y ≤ 0 then
    .unpleasantAccumulation
  else
    .mixedCompensation

-- Source : Document 1, §6 (Activation et orientation de la politique d'action)
/-- Calcul du profil d'activation phénoménologique à partir de la position dans le Noyau. -/
def computeActivation (p : CoreAffectPoint) : PhenomenologicalActivation :=
  if p.x = 0 ∧ p.y = 0 then
    if p.z = 0 then .basalWakefulness else .operatorSuspension
  else if p.y > 0 then
    .highMobilization
  else if p.y < 0 then
    .lowInhibition
  else
    .epistemicVigilance

/-!
## 2. Les huit prototypes de la première couronne (Z = 2)
-/

-- Source : Document 1, §6.1 (Les quatre orientations axiales) & §6.2 (Les quatre prototypes combinés)
-- Source : Document 2, §1 & §3 (Catégorie 2 : Affects primaires et prototypes fondamentaux)
/--
Les huit prototypes affectifs de la première couronne (Z = 2, rayon = 2) déployés autour
de l'opérateur d'Anticipation (0, 0, 2) :
- Quatre orientations axiales : `joie`, `tristesse`, `peur`, `courage`.
- Quatre prototypes combinés (diagonaux) : `desir`, `colere`, `calme`, `degout`.
-/
inductive PrimaryCrownPrototype : Type where
  | joie      : PrimaryCrownPrototype -- (0, +2, 2) : A0 / C+ (Axe Y positif)
  | tristesse : PrimaryCrownPrototype -- (0, -2, 2) : A0 / C- (Axe Y négatif)
  | peur      : PrimaryCrownPrototype -- (-2, 0, 2) : A- / C0 (Axe X négatif)
  | courage   : PrimaryCrownPrototype -- (+2, 0, 2) : A+ / C0 (Axe X positif)
  | desir     : PrimaryCrownPrototype -- (+1, +1, 2) : A+ / C+ (Diagonale de congruence)
  | degout    : PrimaryCrownPrototype -- (-1, -1, 2) : A- / C- (Diagonale de congruence)
  | colere    : PrimaryCrownPrototype -- (-1, +1, 2) : A- / C+ (Diagonale de compensation)
  | calme     : PrimaryCrownPrototype -- (+1, -1, 2) : A+ / C- (Diagonale de compensation)
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 1, §6.1 & §6.2 ; Document 2, §1 & §3
/-- Associe chaque prototype de la première couronne (Z = 2) à ses coordonnées exactes. -/
def PrimaryCrownPrototype.toPoint : PrimaryCrownPrototype → CoreAffectPoint
  | .joie      => ⟨0, 2, 2⟩
  | .tristesse => ⟨0, -2, 2⟩
  | .peur      => ⟨-2, 0, 2⟩
  | .courage   => ⟨2, 0, 2⟩
  | .desir     => ⟨1, 1, 2⟩
  | .degout    => ⟨-1, -1, 2⟩
  | .colere    => ⟨-1, 1, 2⟩
  | .calme     => ⟨1, -1, 2⟩

/--
Preuve que chacun des huit prototypes de la première couronne (Z = 2) constitue un état
géométriquement valide sur la couronne du Noyau affectif (`isOnCrown`).
-/
theorem PrimaryCrownPrototype.valid_on_crown (proto : PrimaryCrownPrototype) :
    (proto.toPoint).isOnCrown := by
  cases proto <;> refine ⟨by decide, by decide⟩

/-!
## 3. Opérateur général d'antagonisme formel (Axial, Diagonal et Controlatéral)
-/

-- Source : Document 1, §6.2 & §7.1 (Organisation hiérarchique et antagonismes)
-- Source : Document 2, §4 (Logique de placement et règles de correspondance antagoniste)
/--
Transformation géométrique associant à toute position de la Matrice son antagoniste régulateur
sur la même strate Z :
1. **Correspondance axiale et diagonale** (`x = 0 ∨ y = 0 ∨ |x| = |y|`) :
   Symétrie centrale inversant simultanément le signe des coordonnées `(X, Y, Z) ↦ (-X, -Y, Z)`.
2. **Correspondance controlatérale** (positions latérales où `x ≠ 0`, `y ≠ 0` et `|x| ≠ |y|`) :
   Réflexion diagonale permutant les valeurs absolues entre l'Axe X et l'Axe Y tout en inversant
   le signe propre de chaque axe :
   - Lorsque X et Y sont de signes opposés (`(x > 0 ∧ y < 0) ∨ (x < 0 ∧ y > 0)`), la réflexion
     permute directement les coordonnées `(X, Y, Z) ↦ (Y, X, Z)` (ex. Haine `(-1, +5, 4)` ↔
     Affection `(+5, -1, 4)`).
   - Lorsqu'ils sont de même signe, elle les permute en inversant leurs signes
     `(X, Y, Z) ↦ (-Y, -X, Z)` (ex. Invulnérabilité `(+1, +7, 5)` ↔ Vulnérabilité `(-7, -1, 5)`).
-/
def antagonistPoint (p : CoreAffectPoint) : CoreAffectPoint :=
  if p.x = 0 ∨ p.y = 0 ∨ p.x.natAbs = p.y.natAbs then
    ⟨-p.x, -p.y, p.z⟩
  else if (p.x > 0 ∧ p.y < 0) ∨ (p.x < 0 ∧ p.y > 0) then
    ⟨p.y, p.x, p.z⟩
  else
    ⟨-p.y, -p.x, p.z⟩

/-!
## 4. Propriétés structurelles et Invariants de la Matrice Affective
-/

/--
Théorème 1 (Conservation de la strate Z par l'antagonisme, Doc. 2, §4) :
L'antagoniste régulateur d'une position appartient toujours à la même strate Z.
-/
theorem antagonistPoint_preserves_z (p : CoreAffectPoint) :
    (antagonistPoint p).z = p.z := by
  unfold antagonistPoint
  split
  · rfl
  · split <;> rfl

/--
Théorème 2 (Conservation du rayon de couronne / budget attentionnel, Doc. 1, §5.2 & §7.1) :
La transformation antagoniste conserve exactement la somme des déplacements absolus `|X| + |Y|`.
-/
theorem antagonistPoint_preserves_displacementSum (p : CoreAffectPoint) :
    (antagonistPoint p).displacementSum = p.displacementSum := by
  cases p with
  | mk x y z =>
    unfold antagonistPoint CoreAffectPoint.displacementSum
    split
    · simp only [Int.natAbs_neg]
    · split
      · simp only [Nat.add_comm]
      · simp only [Int.natAbs_neg, Nat.add_comm]

/--
Théorème 3 (Stabilité topologique de l'espace matriciel, Doc. 1, §7.1 & Doc. 2, §4) :
L'opérateur d'antagonisme préserve la validité géométrique `isValidCoreAffect` sur l'ensemble
du Noyau et de la Matrice.
-/
theorem antagonistPoint_preserves_validity (p : CoreAffectPoint) (h : isValidCoreAffect p) :
    isValidCoreAffect (antagonistPoint p) := by
  rcases h with ⟨hx, hy⟩ | ⟨hz, hsum⟩
  · left
    unfold antagonistPoint CoreAffectPoint.isCentral
    have h_cond : p.x = 0 ∨ p.y = 0 ∨ p.x.natAbs = p.y.natAbs := Or.inl hx
    split
    · dsimp; omega
    · contradiction
  · right
    refine ⟨?_, ?_⟩
    · rw [antagonistPoint_preserves_z]
      exact hz
    · rw [antagonistPoint_preserves_displacementSum, antagonistPoint_preserves_z]
      exact hsum

/--
Théorème 4 (Involution stricte de l'antagonisme, Doc. 1, §7.1 & Doc. 2, §4) :
Pour toute coordonnée de l'espace affectif, l'antagoniste de l'antagoniste restitue
exactement la position initiale (dualité symétrique `A ↔ B`).
-/
theorem antagonistPoint_involutive (p : CoreAffectPoint) :
    antagonistPoint (antagonistPoint p) = p := by
  obtain ⟨x, y, z⟩ := p
  by_cases h1 : x = 0 ∨ y = 0 ∨ x.natAbs = y.natAbs
  · have h_inner : antagonistPoint ⟨x, y, z⟩ = ⟨-x, -y, z⟩ := by
      unfold antagonistPoint
      split
      · rfl
      · contradiction
    rw [h_inner]
    unfold antagonistPoint
    split
    · simp only [Int.neg_neg]
    · dsimp at *
      rw [Int.natAbs_neg, Int.natAbs_neg] at *
      omega
  · by_cases h2 : (x > 0 ∧ y < 0) ∨ (x < 0 ∧ y > 0)
    · have h_inner : antagonistPoint ⟨x, y, z⟩ = ⟨y, x, z⟩ := by
        unfold antagonistPoint
        split
        · contradiction
        · rfl
      rw [h_inner]
      unfold antagonistPoint
      split
      · dsimp at *; omega
      · split
        · rfl
        · dsimp at *; omega
    · have h_inner : antagonistPoint ⟨x, y, z⟩ = ⟨-y, -x, z⟩ := by
        unfold antagonistPoint
        split
        · contradiction
        · rfl
      rw [h_inner]
      unfold antagonistPoint
      split
      · dsimp at *
        rw [Int.natAbs_neg, Int.natAbs_neg] at *
        omega
      · split
        · dsimp at *; omega
        · dsimp; simp only [Int.neg_neg]

/--
Théorème 5 (Caractérisation des points fixes aux limites centrales, Doc. 2, §1 & §4) :
Un point est invariant par l'opérateur d'antagonisme si et seulement s'il s'agit d'un
opérateur central `(0, 0, Z)` (dont le Point de Veille en Z = 0). Toute position périphérique
possède un antagoniste strictement distinct d'elle-même.
-/
theorem antagonistPoint_fixed_iff_central (p : CoreAffectPoint) :
    antagonistPoint p = p ↔ p.isCentral := by
  obtain ⟨x, y, z⟩ := p
  unfold antagonistPoint CoreAffectPoint.isCentral
  constructor
  · intro h
    split at h
    · simp only [CoreAffectPoint.mk.injEq] at h
      dsimp; omega
    · split at h
      · simp only [CoreAffectPoint.mk.injEq] at h
        dsimp at *; omega
      · simp only [CoreAffectPoint.mk.injEq] at h
        dsimp at *; omega
  · rintro ⟨hx, hy⟩
    subst hx hy
    dsimp

/--
Théorème 6 (Permutation controlatérale des amplitudes dominantes, Doc. 1, §7.1 & Doc. 2, §4) :
Pour toute position latérale (`x ≠ 0`, `y ≠ 0`, `|x| ≠ |y|`), l'antagoniste controlatéral
permute les valeurs absolues entre l'Axe X et l'Axe Y, inversant ainsi le biais d'allocation
attentionnelle entre la voie épistémique et la voie pragmatique.
-/
theorem contralateral_swaps_amplitudes (p : CoreAffectPoint)
    (h_lat : ¬(p.x = 0 ∨ p.y = 0 ∨ p.x.natAbs = p.y.natAbs)) :
    (antagonistPoint p).x.natAbs = p.y.natAbs ∧
    (antagonistPoint p).y.natAbs = p.x.natAbs := by
  unfold antagonistPoint
  split
  · contradiction
  · split
    · exact ⟨rfl, rfl⟩
    · exact ⟨Int.natAbs_neg p.y, Int.natAbs_neg p.x⟩

/--
Vérification formelle des exemples canoniques du texte (Doc. 1, §6.2 & §7.1 ; Doc. 2, §4) :
- Joie (0, 2, 2) ↔ Tristesse (0, -2, 2)
- Peur (-2, 0, 2) ↔ Courage (2, 0, 2)
- Colère (-1, 1, 2) ↔ Calme (1, -1, 2)
- Désir (1, 1, 2) ↔ Dégoût (-1, -1, 2)
- Haine (-1, 5, 4) ↔ Affection (5, -1, 4)
- Invulnérabilité (1, 7, 5) ↔ Vulnérabilité (-7, -1, 5)
- Abandon (3, -9, 7) ↔ Sidération (-9, 3, 7)
-/
theorem canonical_antagonist_examples :
    antagonistPoint ⟨0, 2, 2⟩ = ⟨0, -2, 2⟩ ∧
    antagonistPoint ⟨-2, 0, 2⟩ = ⟨2, 0, 2⟩ ∧
    antagonistPoint ⟨-1, 1, 2⟩ = ⟨1, -1, 2⟩ ∧
    antagonistPoint ⟨1, 1, 2⟩ = ⟨-1, -1, 2⟩ ∧
    antagonistPoint ⟨-1, 5, 4⟩ = ⟨5, -1, 4⟩ ∧
    antagonistPoint ⟨1, 7, 5⟩ = ⟨-7, -1, 5⟩ ∧
    antagonistPoint ⟨3, -9, 7⟩ = ⟨-9, 3, 7⟩ := by
  decide

/-!
## 5. Règle de transition intra-couronne et Structure `AffectiveMatrixState`
-/

-- Source : Document 1, §6.3 (Dynamique de la Matrice - Transfert d'une unité de résolution)
/--
Transition élémentaire à strate constante dans le premier quadrant (`x > 0`, `y ≥ 0`)
transférant une unité de résolution de l'Attente (X) vers le Contrôle (Y).
-/
def transferUnitXtoY (p : CoreAffectPoint) : CoreAffectPoint :=
  if p.x > 0 ∧ p.y ≥ 0 then
    ⟨p.x - 1, p.y + 1, p.z⟩
  else
    p

/--
Lemme 7 (Invariance de couronne par transfert unitaire, Doc. 1, §6.3) :
Le transfert d'une unité de résolution à l'intérieur d'un quadrant conserve la somme
des déplacements `|X| + |Y|` et maintient la trajectoire sur la même couronne.
-/
theorem transferUnitXtoY_preserves_sum (p : CoreAffectPoint) :
    (transferUnitXtoY p).displacementSum = p.displacementSum := by
  unfold transferUnitXtoY CoreAffectPoint.displacementSum
  split
  · dsimp; omega
  · rfl

-- Source : Document 1, §6 (La Matrice affective)
/--
État complet de la Matrice affective (`AffectiveMatrixState`), couplant un état certifié
du Noyau affectif (`CoreAffectState`) à sa transduction phénoménologique (pôles vécus,
valence, activation) et à son antagoniste régulateur certifié.
-/
structure AffectiveMatrixState where
  core            : CoreAffectState
  expectationPole : LivedExpectationPole
  controlPole     : LivedControlPole
  valence         : PhenomenologicalValence
  activation      : PhenomenologicalActivation
  antagonist      : CoreAffectState

-- Source : Document 1, §6 (La Matrice affective)
/--
Opérateur de transduction projetant tout état valide du Noyau affectif (`CoreAffectState`)
dans un état complet de la Matrice affective (`AffectiveMatrixState`).
-/
def evaluateMatrix (cs : CoreAffectState) : AffectiveMatrixState :=
  let p := cs.point
  { core            := cs
    expectationPole := transduceExpectation p.x
    controlPole     := transduceControl p.y
    valence         := computeValence p
    activation      := computeActivation p
    antagonist      := {
      point   := antagonistPoint p
      h_valid := antagonistPoint_preserves_validity p cs.h_valid
    } }

/-- Preuve d'inhabitation de `AffectiveMatrixState` centrée sur le Point de Veille. -/
instance : Inhabited AffectiveMatrixState where
  default := evaluateMatrix default

end AffectiveMatrix

end Cartograffect
