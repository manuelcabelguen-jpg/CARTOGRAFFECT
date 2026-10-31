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

-- Source : Document 1, Résumé, §6, §6.2 & §6.3 ; Document 2, §2 (Découplage Régime Énergétique et Polarité Hédonique)
/-- Régime énergétique et cinétique du couplage entre Attente (X) et Contrôle (Y). -/
inductive EnergyRegime where
  | neutralBasal           -- X = 0 ∧ Y = 0 (Point de Veille / Opérateurs centraux)
  | axialPure              -- (X = 0 ∧ Y ≠ 0) ∨ (X ≠ 0 ∧ Y = 0)
  | positiveSynergy        -- X > 0 ∧ Y > 0 (Congruence de décharge : Désir, Attrait, Estime...)
  | negativeSynergy        -- X < 0 ∧ Y < 0 (Congruence de charge : Dégoût, Retrait, Rejet...)
  | ergotropicCompensation -- X < 0 ∧ Y > 0 (Modèle en échec, mobilisation d'urgence : Colère, Haine, Terreur...)
  | trophotropicRelease    -- X > 0 ∧ Y < 0 (Modèle révisé, relâchement moteur : Calme, Sérénité, Béatitude...)
  deriving DecidableEq, Repr, Inhabited

/-- Calcul du régime énergétique à partir des coordonnées (X, Y). -/
def computeEnergyRegime (x y : Int) : EnergyRegime :=
  if x == 0 && y == 0 then .neutralBasal
  else if x == 0 || y == 0 then .axialPure
  else if x > 0 && y > 0 then .positiveSynergy
  else if x < 0 && y < 0 then .negativeSynergy
  else if x < 0 && y > 0 then .ergotropicCompensation
  else .trophotropicRelease

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
-- THÉORÈMES CONSTRUCTIFS ASSOCIÉS À LA POLARITÉ HÉDONIQUE
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

-- Source : Document 1, Résumé & §6 (Activation et sélection d'une politique d'action)
/--
Niveau d'activation qualifiant l'amplitude de mobilisation de la trajectoire :
- `basalWakefulness`   : maintien homéostatique de fond au Point de Veille (0, 0, 0).
- `ascendingRupture`   : rupture de veille et saillance perceptive à la Surprise (0, 0, 1).
- `operatorSuspension` : suspension descendante de la décharge immédiate au centre opérateur (0, 0, Z ≥ 2).
- `lowInhibition`      : repli, réduction ou suspension de l'effort moteur (Y < 0).
- `epistemicVigilance` : mobilisation purement épistémique à Contrôle neutre (Y = 0 et X ≠ 0).
- `highMobilization`   : mobilisation énergétique et motrice active (Y > 0).
-/
inductive PhenomenologicalActivation : Type where
  | basalWakefulness   : PhenomenologicalActivation
  | ascendingRupture   : PhenomenologicalActivation
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

-- Source : Document 1, §6 (Activation et orientation de la politique d'action)
/-- Calcul du profil d'activation phénoménologique à partir de la position dans le Noyau. -/
def computeActivation (p : CoreAffectPoint) : PhenomenologicalActivation :=
  if p.x = 0 ∧ p.y = 0 then
    if p.z = 0 then .basalWakefulness
    else if p.z = 1 then .ascendingRupture
    else .operatorSuspension
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
Théorème 8 (Forme algébrique unifiée de l'antagonisme hors des axes, Doc. 1, §7.1 & Doc. 2, §4.3) :
Pour toute position hors des axes principaux (`x ≠ 0` et `y ≠ 0`, couvrant l'ensemble des
positions diagonales et latérales), `antagonistPoint p` coïncide avec la loi algébrique unique
`(-sgn(X)|Y|, -sgn(Y)|X|, Z)` qui inverse le signe de chaque coordonnée tout en permutant
leurs valeurs absolues.
-/
theorem antagonistPoint_unified (p : CoreAffectPoint) (hx : p.x ≠ 0) (hy : p.y ≠ 0) :
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

-- Source : Document 1, §6 (La Matrice affective)
/--
État complet de la Matrice affective (`AffectiveMatrixState`), couplant un état certifié
du Noyau affectif (`CoreAffectState`) à sa transduction phénoménologique (pôles vécus,
régime énergétique, polarité hédonique / valence, activation) et à son antagoniste régulateur certifié.
-/
structure AffectiveMatrixState where
  core            : CoreAffectState
  expectationPole : LivedExpectationPole
  controlPole     : LivedControlPole
  energyRegime    : EnergyRegime
  valence         : HedonicPolarity
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
    energyRegime    := computeEnergyRegime p.x p.y
    valence         := computeHedonicPolarity p.x p.y
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
