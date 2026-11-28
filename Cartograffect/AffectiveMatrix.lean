/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later
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

-- Source : Document 1, §6 & DECISIONS_V3 (Option 1A — Contrôlabilité instrumentale perçue stricte)
/--
Traduction vécue (hypothèse de correspondance) du pôle computationnel sur l'Axe Y (Contrôle instrumental perçu) :
- `pragmaticCharge`    (Y < 0) : faible contrôlabilité instrumentale perçue face à une limite objective d'action.
- `pragmaticNeutral`   (Y = 0) : absence de contribution polarisée propre sur la dimension instrumentale.
- `pragmaticDischarge` (Y > 0) : contrôlabilité instrumentale perçue élevée (capacité d'agir sur la situation).
L'activation physiologique / mobilisation allostatique est externalisée dans le canal autonome `A ≥ 0`.
-/
inductive LivedControlPole : Type where
  | pragmaticCharge    : LivedControlPole
  | pragmaticNeutral   : LivedControlPole
  | pragmaticDischarge : LivedControlPole
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 1, §6 & DECISIONS_V3 (Option 1A — Symétrie sémantique totale sur Y−)
/-- Régime d'interaction fonctionnelle du couplage entre Attente (X) et Contrôle instrumental (Y),
    découplé du canal d'activation autonome `A ≥ 0`. -/
inductive EnergyRegime where
  | neutralBasal           -- X = 0 ∧ Y = 0 (Point de Veille / Opérateurs centraux)
  | axialPure              -- (X = 0 ∧ Y ≠ 0) ∨ (X ≠ 0 ∧ Y = 0)
  | positiveSynergy        -- X > 0 ∧ Y > 0 (Congruence de décharge : Désir, maîtrise instrumentale)
  | negativeSynergy        -- X < 0 ∧ Y < 0 (Congruence de charge : Dégoût, rejet/détresse à faible contrôle)
  | agenticConfrontation   -- X < 0 ∧ Y > 0 (Affrontement agentique : Colère, Frustration, Hostilité, Révolte)
  | secondaryAccommodation -- X > 0 ∧ Y < 0 (Accommodation / contrôle secondaire face à une limite d'action : Calme, Acceptation, Lâcher-prise)
  deriving DecidableEq, Repr, Inhabited

/-- Calcul du régime d'interaction à partir des coordonnées (X, Y). -/
def computeEnergyRegime (x y : Int) : EnergyRegime :=
  if x == 0 && y == 0 then .neutralBasal
  else if x == 0 || y == 0 then .axialPure
  else if x > 0 && y > 0 then .positiveSynergy
  else if x < 0 && y < 0 then .negativeSynergy
  else if x < 0 && y > 0 then .agenticConfrontation
  else .secondaryAccommodation

/-- Polarité hédonique phénoménologique (Valence vécue). -/
inductive HedonicPolarity where
  | positive -- Ressenti agréable (intégration épistémique X > 0, ou élan axial X = 0, Y > 0)
  | negative -- Ressenti aversif (échec épistémique X < 0, ou abattement axial X = 0, Y < 0)
  | neutral  -- Suspens pré-valencé (X = 0, Y = 0 : Veille, Surprise, Anticipation, Émoi, Réserve, Recul, Saisissement, Suspension)
  deriving DecidableEq, Repr, Inhabited

/-- Inversion de la polarité hédonique. -/
def HedonicPolarity.invert : HedonicPolarity → HedonicPolarity
  | .positive => .negative
  | .negative => .positive
  | .neutral  => .neutral

/-- Loi de primauté hédonique lexicographique de l'Axe X :
    Le signe de X gouverne la valence au premier rang ; Y n'intervient que si X = 0. -/
def computeHedonicPolarity (x y : Int) : HedonicPolarity :=
  if x > 0 then .positive
  else if x < 0 then .negative
  else if y > 0 then .positive
  else if y < 0 then .negative
  else .neutral

/-- Rétrocompatibilité : alias de `computeValence` vers `computeHedonicPolarity`
    (ou conserver l'ancien nom pour ne casser aucun appel existant). -/
abbrev computeValence (x y : Int) : HedonicPolarity :=
  computeHedonicPolarity x y

-- ============================================================================
-- THÉORÈMES ASSOCIÉS À LA POLARITÉ HÉDONIQUE ET AU CANAL AUTONOME (OPTION 1A)
-- ============================================================================

/-- L'inversion de la polarité hédonique est strictement involutive. -/
theorem HedonicPolarity.invert_involutive (p : HedonicPolarity) :
    p.invert.invert = p := by
  cases p <;> rfl

/-- Théorème de primauté hédonique de l'Axe X :
    Dès que X > 0, la valence est positive quel que soit le signe ou l'amplitude de Y. -/
theorem x_positive_determines_positive_valence (x y : Int) (hx : x > 0) :
    computeHedonicPolarity x y = .positive := by
  unfold computeHedonicPolarity
  simp [hx]

/-- Dès que X < 0, la valence est négative quel que soit le signe ou l'amplitude de Y. -/
theorem x_negative_determines_negative_valence (x y : Int) (hx : x < 0) :
    computeHedonicPolarity x y = .negative := by
  unfold computeHedonicPolarity
  have hnot : ¬(x > 0) := Int.not_lt.mpr (Int.le_of_lt hx)
  simp [hnot, hx]

-- Source : Document 1, §6 (La Matrice affective)
/-- Transduction de la coordonnée X en pôle vécu d'Attente. -/
def transduceExpectation (x : Int) : LivedExpectationPole :=
  if x < 0 then .epistemicCharge
  else if x > 0 then .epistemicDischarge
  else .epistemicNeutral

-- Source : Document 1, §6 & DECISIONS_V3 (Option 1A)
/-- Transduction de la coordonnée Y en pôle vécu de Contrôle instrumental perçu. -/
def transduceControl (y : Int) : LivedControlPole :=
  if y < 0 then .pragmaticCharge
  else if y > 0 then .pragmaticDischarge
  else .pragmaticNeutral

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
sur la même strate Z, définie de manière exacte **par morceaux** :
- Si `XY = 0` (`p.x = 0 ∨ p.y = 0`, centre et positions axiales) :
  `A(X, Y, Z) = (-X, -Y, Z)` (symétrie centrale inversant l'axe actif ; la formule `(-sgn(X)|Y|, -sgn(Y)|X|, Z)`
  ne s'applique PAS ici car `sgn(0) = 0` annulerait la coordonnée active).
- Si `XY ≠ 0` (`p.x ≠ 0 ∧ p.y ≠ 0`, positions diagonales et latérales) :
  `A(X, Y, Z) = (-sgn(X)|Y|, -sgn(Y)|X|, Z)` :
  - Sur les diagonales (`|X| = |Y| > 0`), cela coïncide avec `(-X, -Y, Z)`.
  - Sur les positions latérales (`|X| ≠ |Y|`), la réflexion permute les amplitudes tout en
    inversant le signe propre de chaque axe : `(Y, X, Z)` si `X` et `Y` sont de signes opposés
    (ex. Haine `(-1, +5, 4)` ↔ Affection `(+5, -1, 4)`), et `(-Y, -X, Z)` s'ils sont de même
    signe (ex. Invulnérabilité `(+1, +7, 5)` ↔ Vulnérabilité `(-7, -1, 5)`).
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

/--
Théorème 7 (Équivariance Moteur ↔ Matrice, Doc. 1, §4, §6.2 & §7.1) :
Pour tout couplage `c` du Moteur prédictif et toute profondeur `d`, l'antagoniste géométrique
du point projeté dans la Matrice coïncide exactement avec le déploiement du couplage aux
polarités inversées `⟨c.attente.invert, c.controle.invert⟩`.
-/
theorem antagonist_commutes_with_invert (c : EngineCoupling) (d : Nat) :
    antagonistPoint (deployCouplingAtDepth c d) =
      deployCouplingAtDepth ⟨c.attente.invert, c.controle.invert⟩ d := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> (
      unfold deployCouplingAtDepth Polarity.invert signedAmplitude antagonistPoint
      dsimp
      try simp only [Int.natAbs_neg, or_true, ↓reduceIte, Int.neg_neg]
    )

private theorem int_ofNat_succ_ne_zero (n : Nat) : Int.ofNat (n + 1) ≠ 0 := by
  intro h; cases h

private theorem int_neg_ofNat_succ_ne_zero (n : Nat) : -Int.ofNat (n + 1) ≠ 0 := by
  intro h; cases h

private theorem int_ofNat_succ_pos (n : Nat) : Int.ofNat (n + 1) > 0 := by
  change (↑(n + 1) : Int) > 0; omega

private theorem int_neg_ofNat_succ_neg (n : Nat) : -Int.ofNat (n + 1) < 0 := by
  change -(↑(n + 1) : Int) < 0; omega

private theorem antagonistPoint_pos_pos (a b z : Nat) (ha : a ≥ 1) (hb : b ≥ 1) :
    antagonistPoint ⟨Int.ofNat a, Int.ofNat b, z⟩ = ⟨-Int.ofNat b, -Int.ofNat a, z⟩ := by
  cases a with
  | zero => omega
  | succ n =>
    cases b with
    | zero => omega
    | succ m =>
      unfold antagonistPoint
      have hx0 := int_ofNat_succ_ne_zero n
      have hy0 := int_ofNat_succ_ne_zero m
      have hxp := int_ofNat_succ_pos n
      have hyp := int_ofNat_succ_pos m
      by_cases hnm : n = m
      · subst hnm
        simp only [or_true, ↓reduceIte]
      · have hnd : (Int.ofNat (n + 1)).natAbs ≠ (Int.ofNat (m + 1)).natAbs := by
          simp only [natAbs_pos_ofNat]; omega
        have hnlt_y : ¬(Int.ofNat (m + 1) < 0) := by omega
        have hnlt_x : ¬(Int.ofNat (n + 1) < 0) := by omega
        simp only [hx0, hy0, hnd, ↓reduceIte, hnlt_y, hnlt_x, and_false, false_and, or_self]

private theorem antagonistPoint_neg_neg (a b z : Nat) (ha : a ≥ 1) (hb : b ≥ 1) :
    antagonistPoint ⟨-Int.ofNat a, -Int.ofNat b, z⟩ = ⟨Int.ofNat b, Int.ofNat a, z⟩ := by
  cases a with
  | zero => omega
  | succ n =>
    cases b with
    | zero => omega
    | succ m =>
      unfold antagonistPoint
      have hx0 := int_neg_ofNat_succ_ne_zero n
      have hy0 := int_neg_ofNat_succ_ne_zero m
      have hxn := int_neg_ofNat_succ_neg n
      have hyn := int_neg_ofNat_succ_neg m
      by_cases hnm : n = m
      · subst hnm
        simp only [or_true, ↓reduceIte, Int.neg_neg]
      · have hnd : (-Int.ofNat (n + 1)).natAbs ≠ (-Int.ofNat (m + 1)).natAbs := by
          simp only [natAbs_neg_ofNat]; omega
        have hngt_x : ¬(-Int.ofNat (n + 1) > 0) := by omega
        have hngt_y : ¬(-Int.ofNat (m + 1) > 0) := by omega
        simp only [hx0, hy0, hnd, ↓reduceIte, hngt_x, hngt_y, false_and, and_false, or_self, Int.neg_neg]

private theorem antagonistPoint_pos_neg (a b z : Nat) (ha : a ≥ 1) (hb : b ≥ 1) :
    antagonistPoint ⟨Int.ofNat a, -Int.ofNat b, z⟩ = ⟨-Int.ofNat b, Int.ofNat a, z⟩ := by
  cases a with
  | zero => omega
  | succ n =>
    cases b with
    | zero => omega
    | succ m =>
      unfold antagonistPoint
      have hx0 := int_ofNat_succ_ne_zero n
      have hy0 := int_neg_ofNat_succ_ne_zero m
      have hxp := int_ofNat_succ_pos n
      have hyn := int_neg_ofNat_succ_neg m
      by_cases hnm : n = m
      · subst hnm
        have hdiag : (Int.ofNat (n + 1)).natAbs = (-Int.ofNat (n + 1)).natAbs := by
          simp only [natAbs_pos_ofNat, natAbs_neg_ofNat]
        simp only [hdiag, or_true, ↓reduceIte, Int.neg_neg]
      · have hnd : (Int.ofNat (n + 1)).natAbs ≠ (-Int.ofNat (m + 1)).natAbs := by
          simp only [natAbs_pos_ofNat, natAbs_neg_ofNat]; omega
        simp only [hx0, hy0, hnd, false_or, ↓reduceIte, hxp, hyn, and_self, true_or]

private theorem antagonistPoint_neg_pos (a b z : Nat) (ha : a ≥ 1) (hb : b ≥ 1) :
    antagonistPoint ⟨-Int.ofNat a, Int.ofNat b, z⟩ = ⟨Int.ofNat b, -Int.ofNat a, z⟩ := by
  cases a with
  | zero => omega
  | succ n =>
    cases b with
    | zero => omega
    | succ m =>
      unfold antagonistPoint
      have hx0 := int_neg_ofNat_succ_ne_zero n
      have hy0 := int_ofNat_succ_ne_zero m
      have hxn := int_neg_ofNat_succ_neg n
      have hyp := int_ofNat_succ_pos m
      by_cases hnm : n = m
      · subst hnm
        have hdiag : (-Int.ofNat (n + 1)).natAbs = (Int.ofNat (n + 1)).natAbs := by
          simp only [natAbs_pos_ofNat, natAbs_neg_ofNat]
        simp only [hdiag, or_true, ↓reduceIte, Int.neg_neg]
      · have hnd : (-Int.ofNat (n + 1)).natAbs ≠ (Int.ofNat (m + 1)).natAbs := by
          simp only [natAbs_pos_ofNat, natAbs_neg_ofNat]; omega
        simp only [hx0, hy0, hnd, false_or, ↓reduceIte, hxn, hyp, and_self, or_true]

/--
Théorème 7bis (Équivariance généralisée sous partage de précision `(π_A, π_C)`, Arbitrage 4) :
Pour tout couplage `c`, toute profondeur `d` et tout couple de précisions `(piA, piC)`,
l'antagoniste géométrique du point déployé coïncide avec le déploiement du couplage aux
polarités inversées sous permutation des précisions `(piC, piA)`.
-/
theorem antagonist_commutes_with_invert_precision (c : EngineCoupling) (d piA piC : Nat) :
    antagonistPoint (deployCouplingWithPrecision c d piA piC) =
      deployCouplingWithPrecision ⟨c.attente.invert, c.controle.invert⟩ d piC piA := by
  have hb := apportionRay_bounds d piA piC
  have hsw := apportionRay_swap d piA piC
  rcases h_eq : apportionRay d piA piC with ⟨ax, ay⟩
  rw [h_eq] at hb hsw
  dsimp only at hb hsw
  rcases c with ⟨a, ctrl⟩
  cases a <;> cases ctrl <;>
    dsimp only [deployCouplingWithPrecision, Polarity.invert, signedAmplitude]
  · rw [h_eq, hsw]; exact antagonistPoint_neg_neg ax ay (d + 2) hb.1 hb.2.1
  · unfold antagonistPoint; simp
  · rw [h_eq, hsw]; exact antagonistPoint_neg_pos ax ay (d + 2) hb.1 hb.2.1
  · unfold antagonistPoint; simp [Int.neg_neg]
  · rfl
  · unfold antagonistPoint; simp
  · rw [h_eq, hsw]; exact antagonistPoint_pos_neg ax ay (d + 2) hb.1 hb.2.1
  · unfold antagonistPoint; simp
  · rw [h_eq, hsw]; exact antagonistPoint_pos_pos ax ay (d + 2) hb.1 hb.2.1

private theorem neg_sign_mul_of_pos {x : Int} (h : x > 0) (n : Int) : -x.sign * n = -n := by
  have hs : -x.sign = -1 := by
    cases x with
    | ofNat m =>
      cases m with
      | zero => contradiction
      | succ _ => rfl
    | negSucc _ => contradiction
  rw [hs]
  omega

private theorem neg_sign_mul_of_neg {x : Int} (h : x < 0) (n : Int) : -x.sign * n = n := by
  have hs : -x.sign = 1 := by
    cases x with
    | ofNat m => cases m <;> contradiction
    | negSucc _ => rfl
  rw [hs]
  omega

private theorem natAbs_cast_of_pos {y : Int} (h : y > 0) : (y.natAbs : Int) = y := by omega

private theorem natAbs_cast_of_neg {y : Int} (h : y < 0) : (y.natAbs : Int) = -y := by omega

/--
Théorème 8 (Branche hors-axes `XY ≠ 0` de l'antagonisme par morceaux, Doc. 1, §7.1 & Doc. 2, §4.3) :
Pour toute position hors des axes principaux (`XY ≠ 0`, soit `x ≠ 0` et `y ≠ 0`, couvrant
l'ensemble des positions diagonales et latérales), `antagonistPoint p` coïncide avec
`(-sgn(X)|Y|, -sgn(Y)|X|, Z)` qui inverse le signe de chaque coordonnée tout en permutant
leurs valeurs absolues. Sur les axes et au centre (`XY = 0`), la branche exacte est `(-X, -Y, Z)`
(voir `antagonistPoint_piecewise`).
-/
theorem antagonistPoint_off_axis (p : CoreAffectPoint) (hx : p.x ≠ 0) (hy : p.y ≠ 0) :
    antagonistPoint p =
      ⟨-p.x.sign * (p.y.natAbs : Int), -p.y.sign * (p.x.natAbs : Int), p.z⟩ := by
  obtain ⟨x, y, z⟩ := p
  dsimp at hx hy ⊢
  rcases (by omega : x < 0 ∨ x > 0) with hx_neg | hx_pos <;>
  rcases (by omega : y < 0 ∨ y > 0) with hy_neg | hy_pos
  · rw [neg_sign_mul_of_neg hx_neg, neg_sign_mul_of_neg hy_neg,
        natAbs_cast_of_neg hy_neg, natAbs_cast_of_neg hx_neg]
    unfold antagonistPoint; dsimp; split <;> try split
    all_goals (simp only [CoreAffectPoint.mk.injEq, Int.natAbs_eq_natAbs_iff, and_true] at *; try omega)
  · rw [neg_sign_mul_of_neg hx_neg, neg_sign_mul_of_pos hy_pos,
        natAbs_cast_of_pos hy_pos, natAbs_cast_of_neg hx_neg]
    unfold antagonistPoint; dsimp; split <;> try split
    all_goals (simp only [CoreAffectPoint.mk.injEq, Int.natAbs_eq_natAbs_iff, and_true, true_and] at *; try omega)
  · rw [neg_sign_mul_of_pos hx_pos, neg_sign_mul_of_neg hy_neg,
        natAbs_cast_of_neg hy_neg, natAbs_cast_of_pos hx_pos]
    unfold antagonistPoint; dsimp; split <;> try split
    all_goals (simp only [CoreAffectPoint.mk.injEq, Int.natAbs_eq_natAbs_iff, and_true] at *; try omega)
  · rw [neg_sign_mul_of_pos hx_pos, neg_sign_mul_of_pos hy_pos,
        natAbs_cast_of_pos hy_pos, natAbs_cast_of_pos hx_pos]
    unfold antagonistPoint; dsimp; split <;> try split
    all_goals (simp only [CoreAffectPoint.mk.injEq, Int.natAbs_eq_natAbs_iff, and_true] at *; try omega)

/--
Définition algébrique exacte **par morceaux** de l'antagoniste `A(X, Y, Z)` sur tout `CoreAffectPoint` :
- `(-X, -Y, Z)` si `XY = 0` (centre et positions axiales) ;
- `(-sgn(X)|Y|, -sgn(Y)|X|, Z)` si `XY ≠ 0` (positions diagonales et latérales).
-/
theorem antagonistPoint_piecewise (p : CoreAffectPoint) :
    antagonistPoint p =
      if p.x * p.y = 0 then
        ⟨-p.x, -p.y, p.z⟩
      else
        ⟨-p.x.sign * (p.y.natAbs : Int), -p.y.sign * (p.x.natAbs : Int), p.z⟩ := by
  split
  · rename_i hxy
    rcases Int.mul_eq_zero.mp hxy with hx | hy
    · unfold antagonistPoint
      simp [hx]
    · unfold antagonistPoint
      simp [hy]
  · rename_i hxy
    have hx : p.x ≠ 0 := fun h => hxy (by simp [h])
    have hy : p.y ≠ 0 := fun h => hxy (by simp [h])
    exact antagonistPoint_off_axis p hx hy

/--
Théorème 9 (Invariance de l'antagonisme sous les deux régimes de ressources, Doc. 1, §5.2 & §7.1) :
L'opérateur d'antagonisme préserve la validité topologique `isValidCoreAffectIn r` aussi bien
en régime concurrentiel (`ResourceRegime.competitive`) qu'en régime coopératif
(`ResourceRegime.cooperative`).
-/
theorem antagonist_preserves_validity_in (r : ResourceRegime) (p : CoreAffectPoint)
    (h : isValidCoreAffectIn r p) : isValidCoreAffectIn r (antagonistPoint p) := by
  cases r with
  | competitive =>
    exact antagonistPoint_preserves_validity p h
  | cooperative =>
    rcases h with h_cent | ⟨hz, hsum⟩
    · left
      have h_fix := (antagonistPoint_fixed_iff_central p).mpr h_cent
      rw [h_fix]
      exact h_cent
    · right
      rw [antagonistPoint_preserves_z, antagonistPoint_preserves_displacementSum]
      exact ⟨hz, hsum⟩

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
Lemme 7 (Invariance de couronne par transfert unitaire X → Y, Doc. 1, §6.3) :
Le transfert d'une unité de résolution de l'Attente vers le Contrôle conserve la somme
des déplacements `|X| + |Y|` et maintient la trajectoire sur la même couronne.
-/
theorem transferUnitXtoY_preserves_sum (p : CoreAffectPoint) :
    (transferUnitXtoY p).displacementSum = p.displacementSum := by
  unfold transferUnitXtoY CoreAffectPoint.displacementSum
  split
  · dsimp; omega
  · rfl

/--
Transition élémentaire réciproque à strate constante dans le premier quadrant (`x ≥ 0`, `y > 0`)
transférant une unité de résolution du Contrôle (Y) vers l'Attente (X).
-/
def transferUnitYtoX (p : CoreAffectPoint) : CoreAffectPoint :=
  if p.x ≥ 0 ∧ p.y > 0 then
    ⟨p.x + 1, p.y - 1, p.z⟩
  else
    p

/--
Lemme 8 (Invariance de couronne par transfert unitaire Y → X, Doc. 1, §6.3) :
Le transfert d'une unité de résolution du Contrôle vers l'Attente conserve la somme
des déplacements `|X| + |Y|` et maintient la trajectoire sur la même couronne.
-/
theorem transferUnitYtoX_preserves_sum (p : CoreAffectPoint) :
    (transferUnitYtoX p).displacementSum = p.displacementSum := by
  unfold transferUnitYtoX CoreAffectPoint.displacementSum
  split
  · dsimp; omega
  · rfl

-- Source : Document 1, §6 & DECISIONS_V3 (Option 1A — Canal d'activation autonome indépendant `A ≥ 0`)
/--
État complet de la Matrice affective (`AffectiveMatrixState`), couplant un état certifié
du Noyau affectif (`CoreAffectState`) à sa transduction phénoménologique (pôles vécus,
régime d'interaction, polarité hédonique / valence), à un canal autonome d'activation
physiologique / allostatique `autonomousActivation : Nat` (`A ≥ 0`, strictement indépendant
des coordonnées `(X, Y)`) et à son antagoniste régulateur géométrique certifié.
-/
structure AffectiveMatrixState where
  core                 : CoreAffectState
  expectationPole      : LivedExpectationPole
  controlPole          : LivedControlPole
  energyRegime         : EnergyRegime
  valence              : HedonicPolarity
  autonomousActivation : Nat
  antagonist           : CoreAffectState

-- Source : Résolution R3 & Option 1A (Paramétrisation formelle des hypothèses de correspondance phénoménologique)
/--
Structure encapsulant explicitement les conventions d'interprétation phénoménologique (R3) :
isole les trois règles de transduction vécue des coordonnées (`expectationFn`, `controlFn`,
`valenceFn`) des lois géométriques du Noyau et du canal autonome `autonomousActivation`.
-/
structure PhenomenologicalMapping where
  expectationFn : Int → LivedExpectationPole
  controlFn     : Int → LivedControlPole
  valenceFn     : Int → Int → HedonicPolarity

/-- Instance canonique reprenant les conventions phénoménologiques établies du modèle. -/
def canonicalMapping : PhenomenologicalMapping :=
  { expectationFn := transduceExpectation
    controlFn     := transduceControl
    valenceFn     := computeValence }

instance : Inhabited PhenomenologicalMapping where
  default := canonicalMapping

-- Source : Document 1, §6 & Option 1A
/--
Opérateur de transduction projetant tout état valide du Noyau affectif (`CoreAffectState`)
et tout niveau du canal d'activation autonome `autonomousActivation : Nat` (`A ≥ 0`)
dans un état complet de la Matrice affective (`AffectiveMatrixState`), paramétré par une
instance explicite de correspondance phénoménologique `mapping` (par défaut `canonicalMapping`).
-/
def evaluateMatrix (cs : CoreAffectState)
    (autonomousActivation : Nat := 0)
    (mapping : PhenomenologicalMapping := canonicalMapping) : AffectiveMatrixState :=
  let p := cs.point
  { core                 := cs
    expectationPole      := mapping.expectationFn p.x
    controlPole          := mapping.controlFn p.y
    energyRegime         := computeEnergyRegime p.x p.y
    valence              := mapping.valenceFn p.x p.y
    autonomousActivation := autonomousActivation
    antagonist           := {
      point   := antagonistPoint p
      h_valid := antagonistPoint_preserves_validity p cs.h_valid
    } }

/-- Preuve d'inhabitation de `AffectiveMatrixState` centrée sur le Point de Veille. -/
instance : Inhabited AffectiveMatrixState where
  default := evaluateMatrix default

/--
Inversion universelle de la polarité hédonique lexicographique par l'opérateur d'antagonisme
géométrique `antagonistPoint` sur tout point `(X, Y, Z) ∈ ℤ × ℤ × ℕ` (axial, diagonal, latéral ou central).
-/
private theorem computeHedonicPolarity_zero_x (y : Int) :
    computeHedonicPolarity 0 (-y) = (computeHedonicPolarity 0 y).invert := by
  unfold computeHedonicPolarity
  simp only [Int.lt_irrefl, ↓reduceIte]
  repeat' split
  all_goals first | rfl | omega

theorem antagonistPoint_inverts_hedonic_polarity (p : CoreAffectPoint) :
    computeHedonicPolarity (antagonistPoint p).x (antagonistPoint p).y =
      (computeHedonicPolarity p.x p.y).invert := by
  obtain ⟨x, y, z⟩ := p
  unfold antagonistPoint
  dsimp only
  split
  · dsimp only
    rcases (by omega : x > 0 ∨ x < 0 ∨ x = 0) with hxp | hxn | hx0
    · rw [x_negative_determines_negative_valence (-x) (-y) (by omega),
          x_positive_determines_positive_valence x y hxp]
      rfl
    · rw [x_positive_determines_positive_valence (-x) (-y) (by omega),
          x_negative_determines_negative_valence x y hxn]
      rfl
    · subst hx0
      exact computeHedonicPolarity_zero_x y
  · rename_i h_lat
    have hx_nz : x ≠ 0 := fun h => h_lat (Or.inl h)
    have hy_nz : y ≠ 0 := fun h => h_lat (Or.inr (Or.inl h))
    split
    · rename_i h_opp
      dsimp only
      rcases h_opp with ⟨hxp, hyn⟩ | ⟨hxn, hyp⟩
      · rw [x_negative_determines_negative_valence y x hyn,
            x_positive_determines_positive_valence x y hxp]
        rfl
      · rw [x_positive_determines_positive_valence y x hyp,
            x_negative_determines_negative_valence x y hxn]
        rfl
    · rename_i h_same
      dsimp only
      rcases (by omega : x > 0 ∨ x < 0) with hxp | hxn
      · have hyp : y > 0 := by omega
        rw [x_negative_determines_negative_valence (-y) (-x) (by omega),
            x_positive_determines_positive_valence x y hxp]
        rfl
      · have hyn : y < 0 := by omega
        rw [x_positive_determines_positive_valence (-y) (-x) (by omega),
            x_negative_determines_negative_valence x y hxn]
        rfl

/--
Orthogonalité fonctionnelle du canal d'activation autonome `A ≥ 0` (Option 1A) :
Pour tout état valide `cs : CoreAffectState` et tous niveaux autonomes `a1 a2 : Nat`,
`evaluateMatrix` réalise indépendamment `a1` et `a2` tout en laissant strictement invariants
les coordonnées du Noyau, la valence, les pôles vécus et l'antagoniste géométrique.
-/
theorem autonomousActivation_decoupled_from_core
    (cs : CoreAffectState) (a1 a2 : Nat) (mapping : PhenomenologicalMapping) :
    (evaluateMatrix cs a1 mapping).autonomousActivation = a1 ∧
    (evaluateMatrix cs a2 mapping).autonomousActivation = a2 ∧
    (evaluateMatrix cs a1 mapping).core = (evaluateMatrix cs a2 mapping).core ∧
    (evaluateMatrix cs a1 mapping).valence = (evaluateMatrix cs a2 mapping).valence ∧
    (evaluateMatrix cs a1 mapping).controlPole = (evaluateMatrix cs a2 mapping).controlPole ∧
    (evaluateMatrix cs a1 mapping).antagonist = (evaluateMatrix cs a2 mapping).antagonist :=
  ⟨rfl, rfl, rfl, rfl, rfl, rfl⟩

/--
Théorème 10 (Indépendance structurale de l'état de Noyau, du régime d'interaction, du canal
autonome et de l'antagoniste vis-à-vis du choix de `PhenomenologicalMapping`, R3) :
Deux interprétations phénoménologiques arbitraires `m1` et `m2` produisent exactement
le même état du Noyau `core`, le même régime d'interaction, la même activation autonome
et le même antagoniste régulateur.
-/
theorem evaluateMatrix_core_antagonist_independent
    (cs : CoreAffectState) (a : Nat) (m1 m2 : PhenomenologicalMapping) :
    (evaluateMatrix cs a m1).core = (evaluateMatrix cs a m2).core ∧
    (evaluateMatrix cs a m1).energyRegime = (evaluateMatrix cs a m2).energyRegime ∧
    (evaluateMatrix cs a m1).autonomousActivation = (evaluateMatrix cs a m2).autonomousActivation ∧
    (evaluateMatrix cs a m1).antagonist = (evaluateMatrix cs a m2).antagonist :=
  ⟨rfl, rfl, rfl, rfl⟩

/--
Théorème 11 (Indépendance complète des invariants géométriques et antagonistes vis-à-vis
du `PhenomenologicalMapping` choisi et du canal autonome `a`, R3 & Option 1A).
-/
theorem mapping_independent_antagonist_invariants
    (cs : CoreAffectState) (a : Nat) (mapping : PhenomenologicalMapping) :
    isValidCoreAffect (evaluateMatrix cs a mapping).antagonist.point ∧
    (evaluateMatrix (evaluateMatrix cs a mapping).antagonist a mapping).antagonist.point = cs.point ∧
    (cs.point.x ≠ 0 → cs.point.y ≠ 0 →
      (evaluateMatrix cs a mapping).antagonist.point =
        ⟨-cs.point.x.sign * (cs.point.y.natAbs : Int),
         -cs.point.y.sign * (cs.point.x.natAbs : Int),
         cs.point.z⟩) ∧
    (evaluateMatrix cs a mapping).antagonist = (evaluateMatrix cs 0 canonicalMapping).antagonist := by
  refine ⟨?_, ?_, ?_, rfl⟩
  · exact antagonistPoint_preserves_validity cs.point cs.h_valid
  · exact antagonistPoint_involutive cs.point
  · intro hx hy
    exact antagonistPoint_off_axis cs.point hx hy

end AffectiveMatrix

end Cartograffect
