/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
Author: Manuel Cabelguen
-/

import Cartograffect.PredictiveEngine

namespace Cartograffect

namespace CoreAffect

open PredictiveEngine

/-!
## 1. Coordonnées spatiales, Loi des couronnes et Opérateurs centraux
-/

-- Source : Document 1, §5 (Le Noyau affectif) & Document 2, Préambule & §1
/--
Coordonnée tridimensionnelle dans l'espace du Noyau affectif :
- `x` (Axe X) : Attente — révisabilité épistémique du modèle interne.
- `y` (Axe Y) : Contrôle — contrôlabilité pragmatique de la situation.
- `z` (Axe Z) : Profondeur temporelle et degré d'abstraction cognitive du traitement.
-/
structure CoreAffectPoint where
  x : Int
  y : Int
  z : Nat
  deriving DecidableEq, Repr

-- Source : Document 1, §4 & §5 (Point de Veille à l'origine)
/-- Instance par défaut positionnée au Point de Veille (0, 0, 0). -/
instance : Inhabited CoreAffectPoint where
  default := ⟨0, 0, 0⟩

-- Source : Document 1, §5.2 (Modulation attentionnelle et géométrie) & Document 2, §1
/--
Cumul des déplacements absolus sur l'Axe X et sur l'Axe Y (distance de Manhattan
au centre opérateur (0, 0, Z) de la strate).
-/
def CoreAffectPoint.displacementSum (p : CoreAffectPoint) : Nat :=
  p.x.natAbs + p.y.natAbs

-- Source : Document 1, §5.2 & Document 2, §1 & §5 (Loi des couronnes)
/--
Rayon de placement de la couronne périphérique à la strate Z :
- Aux strates Z = 0 et Z = 1 (cône d'amorçage), le rayon est fixé à 0.
- À partir de Z = 2, le rayon équivaut au double du rang de la strate diminué
  de deux unités : R(Z) = 2 * Z - 2 (soit 2 en Z=2, 4 en Z=3, 6 en Z=4, etc.).
-/
def crownRadius : Nat → Nat
  | 0     => 0
  | 1     => 0
  | d + 2 => 2 * d + 2

-- Source : Document 1, §5.2 & Document 2, §1
/-- Preuve que `crownRadius` satisfait exactement l'équation 2 * Z - 2 pour tout Z ≥ 2. -/
theorem crownRadius_eq_formula (z : Nat) (h : z ≥ 2) : crownRadius z = 2 * z - 2 := by
  cases z with
  | zero => contradiction
  | succ n =>
    cases n with
    | zero => contradiction
    | succ d =>
      change 2 * d + 2 = 2 * (d + 2) - 2
      omega

-- Source : Document 1, §7.2 (Les cinq couches et extensions Z=6, Z=7) & Document 2, Préambule & §5
-- Source : Résolution R5 (Suspension descendante endogène pour Anticipation et les centres Z ≥ 2)
/--
Répertoire formel du Point de Veille (Z = 0) et des sept opérateurs centraux (Z = 1 à Z = 7)
qui président à l'orientation des trajectoires au centre (0, 0, Z) de chaque strate.

Résolution R5 : L'Anticipation `(0, 0, 2)` et l'ensemble des opérateurs centraux situés en strate
`Z ≥ 2` (`emoi`, `reserve`, `recul`, `saisissement`, `suspension`) encodent la **suspension
descendante endogène** (`descendingSuspension = true` issue de l'Interface Subjective).
Même lorsque le couplage sensoriel est neutre `(A0, C0)` ou infra-liminaire (et sous écart saillant
non engagé), une suspension descendante active projette le système vers `⟨0, 0, persistenceDepth + 2⟩`
(`(0, 0, 2)` pour `d = 0`), tandis qu'en l'absence de suspension un couplage neutre ou infra-liminaire
demeure au Point de Veille `(0, 0, 0)`.
-/
inductive CentralOperator : Type where
  | pointDeVeille : CentralOperator -- Z = 0 : Origine structurale et équilibre homéostatique basal
  | surprise      : CentralOperator -- Z = 1 : Opérateur ascendant de rupture et saillance perceptive
  | anticipation  : CentralOperator -- Z = 2 : Opérateur descendant d'orientation (affects primaires)
  | emoi          : CentralOperator -- Z = 3 : Opérateur central des émotions réactives
  | reserve       : CentralOperator -- Z = 4 : Opérateur central des sentiments réflexifs
  | recul         : CentralOperator -- Z = 5 : Opérateur central des orientations durables et humeurs
  | saisissement  : CentralOperator -- Z = 6 : Opérateur central des identités affectives
  | suspension    : CentralOperator -- Z = 7 : Opérateur central des sentiments transcendantaux
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 1, §7.2 & Document 2, §1 & §5
/-- Associe chaque opérateur central à sa coordonnée canonique (0, 0, Z) dans le Noyau affectif. -/
def CentralOperator.toPoint : CentralOperator → CoreAffectPoint
  | .pointDeVeille => ⟨0, 0, 0⟩
  | .surprise      => ⟨0, 0, 1⟩
  | .anticipation  => ⟨0, 0, 2⟩
  | .emoi          => ⟨0, 0, 3⟩
  | .reserve       => ⟨0, 0, 4⟩
  | .recul         => ⟨0, 0, 5⟩
  | .saisissement  => ⟨0, 0, 6⟩
  | .suspension    => ⟨0, 0, 7⟩

/-!
## 2. Typologie géométrique, Secteurs d'orientation et État valide du Noyau affectif
-/

-- Source : Document 1, §5.2 & Document 2, §2 (Typologie géométrique des positions)
/--
Typologie géométrique des positions au sein de l'espace affectif :
- `central`  : Opérateur central situé en (0, 0, Z).
- `axial`    : Position située sur l'un des deux axes principaux (X = 0 ou Y = 0, Z ≥ 2).
- `diagonal` : Implication égale et non nulle sur chacun des deux axes (|X| = |Y| > 0, Z ≥ 2).
- `lateral`  : Coordonnées non nulles d'amplitudes inégales (|X| ≠ |Y|, Z ≥ 3).
-/
inductive GeometryType : Type where
  | central  : GeometryType
  | axial    : GeometryType
  | diagonal : GeometryType
  | lateral  : GeometryType
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 2, §2 (Groupes d'orientation géométrique)
/--
Secteurs d'orientation géométrique définis par l'axe dominant et son signe :
- `joie`      : Y positif dominant (|Y| > |X| et Y > 0).
- `tristesse` : Y négatif dominant (|Y| > |X| et Y < 0).
- `peur`      : X négatif dominant (|X| > |Y| et X < 0).
- `courage`   : X positif dominant (|X| > |Y| et X > 0).
-/
inductive OrientationSector : Type where
  | joie      : OrientationSector
  | tristesse : OrientationSector
  | peur      : OrientationSector
  | courage   : OrientationSector
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 2, §2 (Groupes d'orientation géométrique par axe dominant)
/--
Détermine le secteur d'orientation dominant d'un point lorsque l'un des deux axes
domine strictement l'autre en valeur absolue (`|Y| > |X|` ou `|X| > |Y|`).
Renvoie `none` pour les opérateurs centraux et les positions diagonales.
-/
def CoreAffectPoint.dominantSector? (p : CoreAffectPoint) : Option OrientationSector :=
  if p.y.natAbs > p.x.natAbs then
    if p.y > 0 then some .joie else some .tristesse
  else if p.x.natAbs > p.y.natAbs then
    if p.x < 0 then some .peur else some .courage
  else
    none

-- Source : Document 1, §5.2 & Document 2, §1
/-- Prédicat caractérisant un opérateur central (0, 0, Z). -/
def CoreAffectPoint.isCentral (p : CoreAffectPoint) : Prop :=
  p.x = 0 ∧ p.y = 0

-- Source : Document 1, §5.2 & Document 2, §1
/-- Prédicat caractérisant une position périphérique admissible sur la couronne de la strate Z ≥ 2. -/
def CoreAffectPoint.isOnCrown (p : CoreAffectPoint) : Prop :=
  p.z ≥ 2 ∧ p.displacementSum = crownRadius p.z

-- Source : Document 1, §5.2 & Document 2, §1 & §5
/--
Invariant d'admissibilité topologique du Noyau affectif :
Un point est géométriquement valide dans le Noyau affectif si et seulement s'il constitue
soit le centre opérateur (0, 0, Z) de sa strate, soit une position périphérique sur le
losange de rayon `crownRadius Z` pour Z ≥ 2.
-/
def isValidCoreAffect (p : CoreAffectPoint) : Prop :=
  p.isCentral ∨ p.isOnCrown

-- Source : Document 1, §5.2 & Document 2, §2
/-- Classification géométrique exacte de tout point du Noyau affectif. -/
def CoreAffectPoint.classifyGeometry (p : CoreAffectPoint) : GeometryType :=
  if p.x == 0 && p.y == 0 then
    .central
  else if p.x == 0 || p.y == 0 then
    .axial
  else if p.x.natAbs == p.y.natAbs then
    .diagonal
  else
    .lateral

-- Source : Document 1, §5 (Le Noyau affectif) & Document 2, §1
/--
Structure formelle de l'état du Noyau affectif (`CoreAffectState`), encapsulant
une coordonnée tridimensionnelle munie de la preuve formelle de sa validité géométrique.
-/
structure CoreAffectState where
  point   : CoreAffectPoint
  h_valid : isValidCoreAffect point

-- Source : Document 1, §4, §5 & §6.3 (Point de Veille comme attracteur basal à l'origine)
/--
Preuve formelle d'inhabitation (`Inhabited CoreAffectState`) garantissant la non-vacuité
du système affectif par l'existence canonique du Point de Veille (0, 0, 0).
-/
instance : Inhabited CoreAffectState where
  default := {
    point   := ⟨0, 0, 0⟩
    h_valid := Or.inl ⟨rfl, rfl⟩
  }

/-- Tout opérateur central de la hiérarchie (Z = 0 à Z = 7) induit un `CoreAffectState` valide. -/
def CentralOperator.toCoreAffectState (op : CentralOperator) : CoreAffectState :=
  { point   := op.toPoint
    h_valid := by cases op <;> exact Or.inl ⟨rfl, rfl⟩ }

/-!
## 3. Opérateur de projection : Couplage du `PredictiveEngine` vers `CoreAffect`
-/

-- Source : Document 1, §4 & §5.2
/--
Projection signée d'une amplitude entière `amp` selon la polarité d'un gradient.
-/
def signedAmplitude (pol : Polarity) (amp : Nat) : Int :=
  match pol with
  | .neg  => - (Int.ofNat amp)
  | .zero => 0
  | .pos  => Int.ofNat amp

/-- Lemme auxiliaire : valeur absolue d'un entier négatif construit depuis `Nat`. -/
theorem natAbs_neg_ofNat (n : Nat) : (- (Int.ofNat n)).natAbs = n := by
  cases n <;> rfl

/-- Lemme auxiliaire : valeur absolue d'un entier positif construit depuis `Nat`. -/
theorem natAbs_pos_ofNat (n : Nat) : (Int.ofNat n).natAbs = n := rfl

-- Source : Document 1, §4 & §5.2 (Principe de conservation de la ressource de précision)
/--
Déploiement spatial symétrique d'un couplage (A, C) sur la couronne de profondeur `z = d + 2`
(où `d` est la profondeur de persistance additionnelle au-delà de Z = 2) :
- Lorsqu'une seule dimension (A ou C) est engagée tandis que l'autre demeure neutre,
  elle capte l'intégralité du poids attentionnel `r = 2 * d + 2` (soit ±2 en Z = 2).
- Lorsque les deux dimensions sont engagées conjointement à précision symétrique, la précision
  se divise équitablement entre elles en `k = d + 1` sur chaque axe (soit ±1 en Z = 2).
- Si le couplage est globalement neutre (A0, C0), le système demeure au Point de Veille (0, 0, 0).
-/
def deployCouplingAtDepth (c : EngineCoupling) (d : Nat) : CoreAffectPoint :=
  let z := d + 2
  let r := 2 * d + 2
  let k := d + 1
  match c.attente, c.controle with
  | .zero, .zero => ⟨0, 0, 0⟩
  | .pos,  .zero => ⟨signedAmplitude .pos r, 0, z⟩
  | .neg,  .zero => ⟨signedAmplitude .neg r, 0, z⟩
  | .zero, .pos  => ⟨0, signedAmplitude .pos r, z⟩
  | .zero, .neg  => ⟨0, signedAmplitude .neg r, z⟩
  | .pos,  .pos  => ⟨signedAmplitude .pos k, signedAmplitude .pos k, z⟩
  | .pos,  .neg  => ⟨signedAmplitude .pos k, signedAmplitude .neg k, z⟩
  | .neg,  .pos  => ⟨signedAmplitude .neg k, signedAmplitude .pos k, z⟩
  | .neg,  .neg  => ⟨signedAmplitude .neg k, signedAmplitude .neg k, z⟩

/-- Fonction auxiliaire de bornage entier sur `[lo, hi]`. -/
private def clampNat (lo hi v : Nat) : Nat :=
  if v < lo then lo else if hi < v then hi else v

private theorem clampNat_bounds (lo hi v : Nat) (h : lo ≤ hi) :
    lo ≤ clampNat lo hi v ∧ clampNat lo hi v ≤ hi := by
  unfold clampNat
  split
  · exact ⟨Nat.le_refl lo, h⟩
  · split
    · exact ⟨h, Nat.le_refl hi⟩
    · omega

-- Source : Arbitrage 4 (Partage de précision déterministe (π_A, π_C))
/--
Partage discret du rayon `R(Z) = 2 * d + 2` (où `Z = d + 2`) au prorata des précisions
relatives entières `(piA, piC)` lorsque les deux gradients `A` et `C` sont engagés :
- En strate `Z = 2` (`d = 0`), la contrainte non nulle impose l'unique couple diagonal `(1, 1)`.
- À partir de `Z ≥ 3` (`d ≥ 1`), le rayon `2 * d + 2` est réparti proportionnellement à
  `piA / (piA + piC)` et `piC / (piA + piC)` par arrondi symétrique borné dans `[1, 2 * d + 1]`,
  permettant d'atteindre déterministement l'ensemble des positions latérales comme diagonales.
- Lorsque `piA = piC` (cas par défaut `(1, 1)`), le partage restitue exactement `(d + 1, d + 1)`.
-/
def apportionRay (d piA piC : Nat) : Nat × Nat :=
  let r := 2 * d + 2
  if piA == piC then
    (d + 1, d + 1)
  else if piA < piC then
    let total := piA + piC
    let raw := (2 * r * piA + total) / (2 * total)
    let ax := clampNat 1 (d + 1) raw
    (ax, r - ax)
  else
    let total := piA + piC
    let raw := (2 * r * piC + total) / (2 * total)
    let ay := clampNat 1 (d + 1) raw
    (r - ay, ay)

/-- Bornes et conservation exacte du rayon pour `apportionRay`. -/
theorem apportionRay_bounds (d piA piC : Nat) :
    (apportionRay d piA piC).1 ≥ 1 ∧
    (apportionRay d piA piC).2 ≥ 1 ∧
    (apportionRay d piA piC).1 + (apportionRay d piA piC).2 = 2 * d + 2 := by
  unfold apportionRay
  split
  · dsimp; omega
  · split
    · have hcb := clampNat_bounds 1 (d + 1) ((2 * (2 * d + 2) * piA + (piA + piC)) / (2 * (piA + piC))) (by omega)
      dsimp; omega
    · have hcb := clampNat_bounds 1 (d + 1) ((2 * (2 * d + 2) * piC + (piA + piC)) / (2 * (piA + piC))) (by omega)
      dsimp; omega

/-- Symétrie exacte par permutation des précisions relatives `(π_A, π_C) ↔ (π_C, π_A)`. -/
theorem apportionRay_swap (d piA piC : Nat) :
    apportionRay d piC piA = ((apportionRay d piA piC).2, (apportionRay d piA piC).1) := by
  unfold apportionRay
  by_cases h_eq : piA = piC
  · subst h_eq; simp
  · have h_neq1 : (piC == piA) = false := beq_false_of_ne (Ne.symm h_eq)
    have h_neq2 : (piA == piC) = false := beq_false_of_ne h_eq
    simp only [h_neq1, h_neq2, Bool.false_eq_true, ↓reduceIte]
    split
    · split
      · omega
      · simp only [Nat.add_comm piC piA]
    · split
      · simp only [Nat.add_comm piC piA]
      · omega

/-- Rétrocompatibilité : pour des précisions égales (`piA = piC`), `apportionRay` vaut `(d + 1, d + 1)`. -/
theorem apportionRay_symm (d k : Nat) :
    apportionRay d k k = (d + 1, d + 1) := by
  simp [apportionRay]

/-- En strate `Z = 2` (`d = 0`), tout couple de précisions sur engagement conjoint produit `(1, 1)`. -/
theorem apportionRay_z2 (piA piC : Nat) :
    apportionRay 0 piA piC = (1, 1) := by
  have hb := apportionRay_bounds 0 piA piC
  rcases h_eq : apportionRay 0 piA piC with ⟨ax, ay⟩
  rw [h_eq] at hb
  dsimp at hb
  have h1 : ax = 1 := by omega
  have h2 : ay = 1 := by omega
  subst h1 h2
  rfl

/-- Exactitude entière de `apportionRay` sur toute décomposition admissible du rayon `2 * d + 2`. -/
theorem apportionRay_exact (d ax ay : Nat) (hx : ax ≥ 1) (hy : ay ≥ 1)
    (hsum : ax + ay = 2 * d + 2) :
    apportionRay d ax ay = (ax, ay) := by
  unfold apportionRay
  by_cases h_eq : ax = ay
  · have h_beq : (ax == ay) = true := beq_iff_eq.mpr h_eq
    simp only [h_beq, ↓reduceIte, Prod.mk.injEq]
    omega
  · have h_beq : (ax == ay) = false := beq_false_of_ne h_eq
    simp only [h_beq, Bool.false_eq_true, ↓reduceIte]
    have hr_pos : 0 < 2 * (2 * d + 2) := by omega
    by_cases h_lt : ax < ay
    · simp only [h_lt, ↓reduceIte]
      have hdiv : (2 * (2 * d + 2) * ax + (ax + ay)) / (2 * (ax + ay)) = ax := by
        rw [hsum]
        have h_assoc : 2 * (2 * d + 2) * ax + (2 * d + 2) = (2 * (2 * d + 2)) * ax + (2 * d + 2) := by omega
        rw [h_assoc, Nat.mul_add_div hr_pos, Nat.div_eq_of_lt (by omega : 2 * d + 2 < 2 * (2 * d + 2))]
        omega
      have hclamp : clampNat 1 (d + 1) ax = ax := by
        unfold clampNat
        split
        · omega
        · split <;> omega
      change (clampNat 1 (d + 1) ((2 * (2 * d + 2) * ax + (ax + ay)) / (2 * (ax + ay))),
        (2 * d + 2) - clampNat 1 (d + 1) ((2 * (2 * d + 2) * ax + (ax + ay)) / (2 * (ax + ay)))) = (ax, ay)
      rw [hdiv, hclamp]
      simp only [Prod.mk.injEq, true_and]
      omega
    · simp only [h_lt, ↓reduceIte]
      have hdiv : (2 * (2 * d + 2) * ay + (ax + ay)) / (2 * (ax + ay)) = ay := by
        rw [hsum]
        have h_assoc : 2 * (2 * d + 2) * ay + (2 * d + 2) = (2 * (2 * d + 2)) * ay + (2 * d + 2) := by omega
        rw [h_assoc, Nat.mul_add_div hr_pos, Nat.div_eq_of_lt (by omega : 2 * d + 2 < 2 * (2 * d + 2))]
        omega
      have hclamp : clampNat 1 (d + 1) ay = ay := by
        unfold clampNat
        split
        · omega
        · split <;> omega
      change ((2 * d + 2) - clampNat 1 (d + 1) ((2 * (2 * d + 2) * ay + (ax + ay)) / (2 * (ax + ay))),
        clampNat 1 (d + 1) ((2 * (2 * d + 2) * ay + (ax + ay)) / (2 * (ax + ay)))) = (ax, ay)
      rw [hdiv, hclamp]
      simp only [Prod.mk.injEq, and_true]
      omega

-- Source : Document 1, §4 & §5.2 ; Arbitrage 4 (Partage de précision déterministe (π_A, π_C))
/--
Déploiement spatial généralisé d'un couplage `(A, C)` sur la couronne `Z = d + 2`
sous pondération relative `(piA, piC)` :
- Couplage neutre `(A0, C0)` → Point de Veille `(0, 0, 0)`.
- Engagement unidimensionnel → position axiale d'amplitude totale `r = 2 * d + 2`.
- Engagement bidimensionnel → répartition discrète `(ax, ay) = apportionRay d piA piC`
  sur le losange `|X| + |Y| = 2 * d + 2`, restituant les positions diagonales lorsque
  `piA = piC` (ou en `Z = 2`) et atteignant l'ensemble des positions latérales dès `Z ≥ 3`.
-/
def deployCouplingWithPrecision (c : EngineCoupling) (d piA piC : Nat) : CoreAffectPoint :=
  let z := d + 2
  let r := 2 * d + 2
  match c.attente, c.controle with
  | .zero, .zero => ⟨0, 0, 0⟩
  | .pos,  .zero => ⟨signedAmplitude .pos r, 0, z⟩
  | .neg,  .zero => ⟨signedAmplitude .neg r, 0, z⟩
  | .zero, .pos  => ⟨0, signedAmplitude .pos r, z⟩
  | .zero, .neg  => ⟨0, signedAmplitude .neg r, z⟩
  | .pos,  .pos  =>
    let p := apportionRay d piA piC
    ⟨signedAmplitude .pos p.1, signedAmplitude .pos p.2, z⟩
  | .pos,  .neg  =>
    let p := apportionRay d piA piC
    ⟨signedAmplitude .pos p.1, signedAmplitude .neg p.2, z⟩
  | .neg,  .pos  =>
    let p := apportionRay d piA piC
    ⟨signedAmplitude .neg p.1, signedAmplitude .pos p.2, z⟩
  | .neg,  .neg  =>
    let p := apportionRay d piA piC
    ⟨signedAmplitude .neg p.1, signedAmplitude .neg p.2, z⟩

/-- Pour des précisions symétriques `piA = piC = k`, `deployCouplingWithPrecision` coïncide avec `deployCouplingAtDepth`. -/
theorem deployCouplingWithPrecision_symm_eq (c : EngineCoupling) (d k : Nat) :
    deployCouplingWithPrecision c d k k = deployCouplingAtDepth c d := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> simp [deployCouplingWithPrecision, deployCouplingAtDepth, apportionRay_symm]

-- Source : Document 1, §4 (Le Moteur prédictif) & §5.2 (Modulation attentionnelle) ; Résolutions R5 & R8
/--
Projection complète d'un état du Moteur prédictif (`PredictiveEngineState`) dans l'espace
de coordonnées du Noyau affectif (`CoreAffectPoint`) :
1. Si l'écart est sous le seuil de saillance sensorielle ou si le couplage est neutre `(A0, C0)` :
   - Avec **suspension descendante endogène** (`s.subjective.descendingSuspension = true`),
     le système projette vers l'opérateur central descendant `⟨0, 0, s.attentional.persistenceDepth + 2⟩`
     (soit l'**Anticipation** `(0, 0, 2)` pour `persistenceDepth = 0`) au lieu de retomber au Point de Veille.
   - Sans suspension descendante, le système demeure au Point de Veille `(0, 0, 0)`.
2. Si l'écart franchit le seuil de saillance sensorielle sous couplage non neutre mais que la
   précision globale `allocatedPrecision` reste sous son seuil d'engagement :
   - Avec **suspension descendante endogène** (`s.subjective.descendingSuspension = true`),
     le système active l'opérateur central `⟨0, 0, s.attentional.persistenceDepth + 2⟩`.
   - Sans suspension descendante, le système signale la Surprise `(0, 0, 1)` (rupture ascendante).
3. Dès que l'écart est saillant, le couplage non neutre, et que la précision allouée franchit son
   seuil d'engagement, `deployCouplingWithPrecision` déploie le couplage sur la couronne `z = d + 2`
   au prorata de `(precisionA, precisionC)` (couvrant positions axiales, diagonales et les 120 latérales).
-/
def projectToCoreAffect (s : PredictiveEngineState) : CoreAffectPoint :=
  let c := s.currentCoupling
  if !s.discrepancy.isSensorilySalient || c.isGlobalNeutrality then
    if s.subjective.descendingSuspension then
      ⟨0, 0, s.attentional.persistenceDepth + 2⟩
    else
      ⟨0, 0, 0⟩
  else if !s.attentional.isEngaged then
    if s.subjective.descendingSuspension then
      ⟨0, 0, s.attentional.persistenceDepth + 2⟩
    else
      ⟨0, 0, 1⟩
  else
    deployCouplingWithPrecision c s.attentional.persistenceDepth s.attentional.precisionA s.attentional.precisionC

/-!
## 4. Lemmes de transition et Invariants géométriques (Couplage Moteur → Noyau)
-/

/--
Lemme 1 (Validité du déploiement sur couronne, Doc. 1, §4 & §5.2) :
Pour tout couplage `c : EngineCoupling` et toute profondeur de persistance `d : Nat`,
le point déployé par `deployCouplingAtDepth c d` satisfait l'invariant `isValidCoreAffect`.
-/
theorem deployCouplingAtDepth_valid (c : EngineCoupling) (d : Nat) :
    isValidCoreAffect (deployCouplingAtDepth c d) := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> first
      | exact Or.inl ⟨rfl, rfl⟩
      | right
        unfold CoreAffectPoint.isOnCrown
        dsimp [deployCouplingAtDepth, CoreAffectPoint.displacementSum, signedAmplitude, crownRadius]
        refine ⟨by omega, ?_⟩
        omega

/--
Lemme 1bis (Validité du déploiement généralisé avec partage de précision `(π_A, π_C)`, Arbitrage 4) :
Pour tout couplage `c : EngineCoupling`, toute profondeur `d : Nat` et tout couple `(piA, piC) : Nat × Nat`,
le point déployé par `deployCouplingWithPrecision c d piA piC` satisfait l'invariant `isValidCoreAffect`.
-/
theorem deployCouplingWithPrecision_valid (c : EngineCoupling) (d piA piC : Nat) :
    isValidCoreAffect (deployCouplingWithPrecision c d piA piC) := by
  have hb := apportionRay_bounds d piA piC
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> first
      | exact Or.inl ⟨rfl, rfl⟩
      | (right
         unfold CoreAffectPoint.isOnCrown
         dsimp [deployCouplingWithPrecision, CoreAffectPoint.displacementSum, signedAmplitude, crownRadius]
         refine ⟨by omega, ?_⟩
         rw [natAbs_neg_ofNat] <;> omega)
      | (right
         unfold CoreAffectPoint.isOnCrown
         dsimp [deployCouplingWithPrecision, CoreAffectPoint.displacementSum, signedAmplitude, crownRadius]
         refine ⟨by omega, ?_⟩
         try simp only [natAbs_neg_ofNat, natAbs_pos_ofNat]
         omega)

/--
Théorème Fondamental de Transition (Doc. 1, §4 & §5) :
Toute configuration ou variation des signaux dans le Moteur prédictif (`PredictiveEngineState`)
induit un état géométriquement bien défini et valide dans le Noyau affectif (`isValidCoreAffect`).
-/
theorem engine_induces_valid_core_affect (s : PredictiveEngineState) :
    isValidCoreAffect (projectToCoreAffect s) := by
  dsimp [projectToCoreAffect]
  split
  · split
    · exact Or.inl ⟨rfl, rfl⟩
    · exact Or.inl ⟨rfl, rfl⟩
  · split
    · split
      · exact Or.inl ⟨rfl, rfl⟩
      · exact Or.inl ⟨rfl, rfl⟩
    · exact deployCouplingWithPrecision_valid s.currentCoupling
        s.attentional.persistenceDepth s.attentional.precisionA s.attentional.precisionC

/--
Résolution R5 (Neutralité sans suspension → Point de Veille) :
Sous couplage sensoriel globalement neutre `(A0, C0)` et en l'absence de suspension descendante
(`descendingSuspension = false`), `projectToCoreAffect` maintient le système au Point de Veille `(0, 0, 0)`.
-/
theorem neutral_coupling_without_suspension_yields_veille (s : PredictiveEngineState)
    (h_neut : s.currentCoupling.isGlobalNeutrality = true)
    (h_nosusp : s.subjective.descendingSuspension = false) :
    projectToCoreAffect s = ⟨0, 0, 0⟩ := by
  dsimp [projectToCoreAffect]
  rw [h_neut, h_nosusp]
  cases s.discrepancy.isSensorilySalient <;> rfl

/--
Résolution R5 (Neutralité ou infra-liminarité sous suspension descendante endogène) :
Lorsque le couplage sensoriel est neutre `(A0, C0)` ou que l'écart demeure infra-liminaire
(`!isSensorilySalient || isGlobalNeutrality = true`), mais que la suspension descendante
endogène est active (`s.subjective.descendingSuspension = true`), `projectToCoreAffect`
projette directement vers l'opérateur central descendant `⟨0, 0, persistenceDepth + 2⟩`
(soit l'Anticipation `(0, 0, 2)` pour `persistenceDepth = 0`) au lieu de retomber au Point de Veille.
-/
theorem neutral_or_subthreshold_with_suspension_yields_central (s : PredictiveEngineState)
    (h_cond : (!s.discrepancy.isSensorilySalient || s.currentCoupling.isGlobalNeutrality) = true)
    (h_susp : s.subjective.descendingSuspension = true) :
    projectToCoreAffect s = ⟨0, 0, s.attentional.persistenceDepth + 2⟩ := by
  dsimp [projectToCoreAffect]
  rw [h_cond, h_susp]
  rfl

/--
Résolution R5 (Suspension descendante endogène hors déploiement attentionnel) :
Dès que `descendingSuspension = true` et que le système n'est pas déployé sur couronne
(couplage neutre / infra-liminaire ou attention non engagée), la projection atteint
`⟨0, 0, s.attentional.persistenceDepth + 2⟩`.
-/
theorem descending_suspension_yields_central_operator (s : PredictiveEngineState)
    (h_susp : s.subjective.descendingSuspension = true)
    (h_nondep : (!s.discrepancy.isSensorilySalient || s.currentCoupling.isGlobalNeutrality) = true ∨
      s.attentional.isEngaged = false) :
    projectToCoreAffect s = ⟨0, 0, s.attentional.persistenceDepth + 2⟩ := by
  dsimp [projectToCoreAffect]
  rcases h_nondep with h1 | h2
  · simp [h1, h_susp]
  · by_cases h1 : (!s.discrepancy.isSensorilySalient || s.currentCoupling.isGlobalNeutrality) = true
    · simp [h1, h_susp]
    · simp [h1, h2, h_susp]

/--
Résolution R5 (Caractérisation des centres `Z ≥ 2` comme suspension descendante endogène) :
Tout état du Moteur prédictif projeté sur un opérateur central `(0, 0, d + 2)` (`Z ≥ 2`, dont
l'Anticipation `(0, 0, 2)`) possède nécessairement une suspension descendante endogène active
(`descendingSuspension = true`), une profondeur `persistenceDepth = d`, et se situe soit sous
couplage neutre/infra-liminaire soit sous le seuil d'engagement attentionnel.
-/
theorem central_z_ge2_requires_descending_suspension (s : PredictiveEngineState) (d : Nat)
    (h : projectToCoreAffect s = ⟨0, 0, d + 2⟩) :
    s.subjective.descendingSuspension = true ∧
    s.attentional.persistenceDepth = d ∧
    (!s.discrepancy.isSensorilySalient || s.currentCoupling.isGlobalNeutrality || !s.attentional.isEngaged) = true := by
  dsimp [projectToCoreAffect] at h
  by_cases h1 : (!s.discrepancy.isSensorilySalient || s.currentCoupling.isGlobalNeutrality) = true
  · simp only [h1, ↓reduceIte] at h
    by_cases h3 : s.subjective.descendingSuspension = true
    · simp only [h3, ↓reduceIte, CoreAffectPoint.mk.injEq] at h
      exact ⟨h3, by omega, by simp [h1]⟩
    · have h3f : s.subjective.descendingSuspension = false := Bool.eq_false_iff.mpr h3
      simp only [h3f, Bool.false_eq_true, ↓reduceIte, CoreAffectPoint.mk.injEq] at h
      omega
  · simp only [h1, Bool.false_eq_true, ↓reduceIte] at h
    simp only [Bool.not_eq_true, Bool.or_eq_false_iff, Bool.not_eq_false'] at h1
    rcases h1 with ⟨_, h_non_neut⟩
    by_cases h2 : (!s.attentional.isEngaged) = true
    · simp only [h2, ↓reduceIte] at h
      by_cases h3 : s.subjective.descendingSuspension = true
      · simp only [h3, ↓reduceIte, CoreAffectPoint.mk.injEq] at h
        exact ⟨h3, by omega, by simp [h2]⟩
      · have h3f : s.subjective.descendingSuspension = false := Bool.eq_false_iff.mpr h3
        simp only [h3f, Bool.false_eq_true, ↓reduceIte, CoreAffectPoint.mk.injEq] at h
        omega
    · simp only [h2, Bool.false_eq_true, ↓reduceIte] at h
      exfalso
      have hof : ∀ n : Nat, (Int.ofNat n = 0 ↔ n = 0) := fun n => by
        cases n with
        | zero => exact ⟨fun _ => rfl, fun _ => rfl⟩
        | succ _ => exact ⟨(fun hn => by cases hn), (fun hn => by cases hn)⟩
      have hneg : ∀ n : Nat, (-Int.ofNat n = 0 ↔ n = 0) := fun n => by
        cases n with
        | zero => exact ⟨fun _ => rfl, fun _ => rfl⟩
        | succ _ => exact ⟨(fun hn => by cases hn), (fun hn => by cases hn)⟩
      unfold PredictiveEngineState.currentCoupling at h h_non_neut
      unfold EngineCoupling.isGlobalNeutrality Polarity.isEngaged at h_non_neut
      rcases apportionRay_bounds s.attentional.persistenceDepth s.attentional.precisionA s.attentional.precisionC with ⟨hb1, hb2, hb3⟩
      cases ha : s.subjective.attenteGradient <;> cases hc : s.perceptive.controleGradient <;>
        (simp only [ha, hc, deployCouplingWithPrecision, signedAmplitude, CoreAffectPoint.mk.injEq, hof, hneg] at h h_non_neut
         first | contradiction | omega)

-- Source : Document 1, §4 & §5
/--
Fonction totale d'évaluation couplant le Moteur prédictif au Noyau affectif :
Associe à tout état `PredictiveEngineState` un état certifié `CoreAffectState`.
-/
def evaluateCoreAffect (s : PredictiveEngineState) : CoreAffectState :=
  { point   := projectToCoreAffect s
    h_valid := engine_induces_valid_core_affect s }

/--
Lemme 2 (Conservation du budget attentionnel à Z = 2, Doc. 1, §4 & §5.2) :
À la première couronne (Z = 2, soit `d = 0`), tout couplage non neutre déployé par l'Interface
Attentionnelle vérifie la loi de somme constante `|X| + |Y| = 2`.
-/
theorem z2_budget_conservation (c : EngineCoupling) (h_non_neutral : c.isGlobalNeutrality = false) :
    (deployCouplingAtDepth c 0).displacementSum = 2 := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> first
      | contradiction
      | decide

/--
Lemme 3 (Correspondance Engagement Unidimensionnel → Position Axiale, Doc. 1, §5.2) :
À la strate Z = 2, si une seule dimension (A ou C) est tranchée, la position projetée
dans le Noyau affectif est nécessairement de type géométrique `.axial`.
-/
theorem single_engaged_yields_axial_z2 (c : EngineCoupling) (h : c.isSingleEngaged = true) :
    (deployCouplingAtDepth c 0).classifyGeometry = .axial := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> first
      | contradiction
      | decide

/--
Lemme 4 (Correspondance Engagement Bidimensionnel → Position Diagonale, Doc. 1, §5.2) :
À la strate Z = 2, si les deux dimensions (A et C) sont tranchées simultanément,
la position projetée dans le Noyau affectif est nécessairement de type `.diagonal`.
-/
theorem dual_engaged_yields_diagonal_z2 (c : EngineCoupling) (h : c.isDualEngaged = true) :
    (deployCouplingAtDepth c 0).classifyGeometry = .diagonal := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> first
      | contradiction
      | decide

-- Source : Document 1, §5.2 (Instabilité des positions axiales et réallocation vers la diagonale)
/--
Opérateur de transition axiale → diagonale :
Lorsqu'un couplage axial voit son second gradient franchir son seuil de saillance avec une
polarité engagée `newPol`, le couplage se met à jour en préservant la polarité initiale.
-/
def triggerSecondaryGradient (c : EngineCoupling) (newPol : Polarity) : EngineCoupling :=
  match c.attente, c.controle with
  | .pos,  .zero => ⟨.pos,  newPol⟩
  | .neg,  .zero => ⟨.neg,  newPol⟩
  | .zero, .pos  => ⟨newPol, .pos⟩
  | .zero, .neg  => ⟨newPol, .neg⟩
  | a,     ctrl  => ⟨a,     ctrl⟩

/--
Lemme 5 (Réallocation symétrique Axial → Diagonal à budget constant, Doc. 1, §5.2 & §6.1) :
Dès que le gradient initialement neutre d'une position axiale en Z = 2 franchit son seuil de
saillance (`newPol.isEngaged = true`), la contrainte de conservation du budget réalloue
la résolution vers une position diagonale tout en conservant le budget total `|X| + |Y| = 2`.
-/
theorem axial_to_diagonal_reallocation
    (c : EngineCoupling)
    (newPol : Polarity)
    (h_axial : c.isSingleEngaged = true)
    (h_salient : newPol.isEngaged = true) :
    let c' := triggerSecondaryGradient c newPol
    (deployCouplingAtDepth c' 0).classifyGeometry = .diagonal ∧
    (deployCouplingAtDepth c' 0).displacementSum = 2 := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> cases newPol <;> first
      | contradiction
      | decide

/--
Lemme 5bis (Conservation du budget attentionnel à toute strate avec partage `(π_A, π_C)`, Arbitrage 4) :
Pour tout couplage non neutre `c`, toute profondeur `d` et tout partage `(piA, piC)`,
la somme des déplacements absolus vaut exactement `2 * d + 2 = crownRadius (d + 2)`.
-/
theorem deployCouplingWithPrecision_budget_conservation
    (c : EngineCoupling) (d piA piC : Nat)
    (h_non_neutral : c.isGlobalNeutrality = false) :
    (deployCouplingWithPrecision c d piA piC).displacementSum = 2 * d + 2 := by
  have hb := apportionRay_bounds d piA piC
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> first
      | contradiction
      | (dsimp [deployCouplingWithPrecision, CoreAffectPoint.displacementSum, signedAmplitude]
         try simp only [natAbs_neg_ofNat, natAbs_pos_ofNat]
         omega)

/--
Lemme 5ter (Stabilité de la première couronne Z = 2 sous engagement conjoint, Arbitrage 4) :
En strate `Z = 2` (`d = 0`), même en présence de précisions relatives asymétriques `(piA, piC)`,
un couplage bidimensionnel produit toujours une position diagonale `(±1, ±1, 2)`.
-/
theorem dual_engaged_yields_diagonal_z2_precision
    (c : EngineCoupling) (piA piC : Nat) (h : c.isDualEngaged = true) :
    (deployCouplingWithPrecision c 0 piA piC).classifyGeometry = .diagonal := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> first
      | contradiction
      | (dsimp [deployCouplingWithPrecision, CoreAffectPoint.classifyGeometry, signedAmplitude]
         rw [apportionRay_z2 piA piC]
         decide)

private theorem deployCouplingAtDepth_not_lateral (c : EngineCoupling) (d : Nat) :
    (deployCouplingAtDepth c d).classifyGeometry ≠ .lateral := by
  rcases c with ⟨a, ctrl⟩
  have hr_pos : (Int.ofNat (2 * d + 2) == 0) = false := by cases d <;> rfl
  have hr_neg : (-Int.ofNat (2 * d + 2) == 0) = false := by cases d <;> rfl
  have hk_pos : (Int.ofNat (d + 1) == 0) = false := rfl
  have hk_neg : (-Int.ofNat (d + 1) == 0) = false := rfl
  cases a <;> cases ctrl <;>
    (dsimp only [deployCouplingAtDepth, CoreAffectPoint.classifyGeometry, signedAmplitude]
     simp only [hr_pos, hr_neg, hk_pos, hk_neg,
       natAbs_neg_ofNat, natAbs_pos_ofNat,
       beq_self_eq_true, Bool.and_true, Bool.and_false,
       Bool.or_true, Bool.or_false,
       Bool.false_eq_true, ↓reduceIte]
     decide)

/--
Lemme 5quater (Caractérisation de l'image symétrique) :
Lorsque `precisionA = precisionC` (cas par défaut `(1, 1)`), `projectToCoreAffect s`
n'atteint jamais de position latérale (restriction aux 56 positions centrales, axiales et diagonales).
-/
theorem symmetric_precision_never_lateral (s : PredictiveEngineState)
    (h_sym : s.attentional.precisionA = s.attentional.precisionC) :
    (projectToCoreAffect s).classifyGeometry ≠ .lateral := by
  dsimp [projectToCoreAffect]
  split
  · split <;> (unfold CoreAffectPoint.classifyGeometry; simp)
  · split
    · split <;> (unfold CoreAffectPoint.classifyGeometry; simp)
    · rw [h_sym, deployCouplingWithPrecision_symm_eq]
      exact deployCouplingAtDepth_not_lateral s.currentCoupling s.attentional.persistenceDepth

-- Source : Arbitrage 4 (Atteignabilité déterministe des 176 positions via (π_A, π_C))
/--
Construit un témoin explicite du Moteur prédictif (`PredictiveEngineState`) atteignant
déterministement toute coordonnée géométriquement valide `p` via `projectToCoreAffect`.
- `(0, 0, 0)` : maintien au Point de Veille.
- `(0, 0, 1)` : rupture ascendante de Surprise sous le seuil d'engagement.
- `(0, 0, d + 2)` : suspension descendante endogène (`descendingSuspension = true`).
- Position de couronne `(X, Y, Z ≥ 2)` : engagement attentionnel (`allocatedPrecision = 1`),
  polarités issues des signes de `(X, Y)` et précisions relatives `(precisionA, precisionC) = (|X|, |Y|)`
  (ou `(1, 1)` sur les axes).
-/
def witnessEngineForPoint (p : CoreAffectPoint) : PredictiveEngineState :=
  let polOf (v : Int) : Polarity :=
    if v > 0 then .pos else if v < 0 then .neg else .zero
  if p.x == 0 && p.y == 0 then
    match p.z with
    | 0 => default
    | 1 => {
        discrepancy := { magnitude := 2, sensoryThreshold := 1, resorptionThreshold := 1, h_hysteresis := Nat.le_refl 1 }
        perceptive  := { controleGradient := .zero }
        subjective  := { attenteGradient := .pos, descendingSuspension := false }
        attentional := { allocatedPrecision := 0, engagementThreshold := 1, persistenceDepth := 0, precisionA := 1, precisionC := 1 }
      }
    | d + 2 => {
        discrepancy := { magnitude := 2, sensoryThreshold := 1, resorptionThreshold := 1, h_hysteresis := Nat.le_refl 1 }
        perceptive  := { controleGradient := .zero }
        subjective  := { attenteGradient := .pos, descendingSuspension := true }
        attentional := { allocatedPrecision := 0, engagementThreshold := 1, persistenceDepth := d, precisionA := 1, precisionC := 1 }
      }
  else
    let ax := p.x.natAbs
    let ay := p.y.natAbs
    let (piA, piC) := if ax == 0 || ay == 0 then (1, 1) else (ax, ay)
    {
      discrepancy := { magnitude := 2, sensoryThreshold := 1, resorptionThreshold := 1, h_hysteresis := Nat.le_refl 1 }
      perceptive  := { controleGradient := polOf p.y }
      subjective  := { attenteGradient := polOf p.x, descendingSuspension := true }
      attentional := {
        allocatedPrecision  := 1
        engagementThreshold := 1
        persistenceDepth    := p.z - 2
        precisionA          := piA
        precisionC          := piC
      }
    }

private theorem project_engaged_crown (a ctrl : Polarity) (d piA piC : Nat)
    (h_non_neut : EngineCoupling.isGlobalNeutrality ⟨a, ctrl⟩ = false) :
    projectToCoreAffect {
      discrepancy := { magnitude := 2, sensoryThreshold := 1, resorptionThreshold := 1, h_hysteresis := Nat.le_refl 1 }
      perceptive  := { controleGradient := ctrl }
      subjective  := { attenteGradient := a, descendingSuspension := true }
      attentional := { allocatedPrecision := 1, engagementThreshold := 1, persistenceDepth := d, precisionA := piA, precisionC := piC }
    } = deployCouplingWithPrecision ⟨a, ctrl⟩ d piA piC := by
  dsimp [projectToCoreAffect, PredictiveEngineState.currentCoupling,
    SalientDiscrepancy.isSensorilySalient, AttentionalInterface.isEngaged]
  have h12 : decide (1 ≤ 2) = true := rfl
  simp only [h_non_neut, h12, Bool.not_true, Bool.or_false, Bool.false_eq_true, ↓reduceIte]

private theorem ofNat_natAbs_pos (x : Int) (hx : x > 0) : Int.ofNat x.natAbs = x := by
  change (x.natAbs : Int) = x; omega

private theorem neg_ofNat_natAbs_neg (x : Int) (hx : x < 0) : -Int.ofNat x.natAbs = x := by
  change -(x.natAbs : Int) = x; omega

/--
Théorème de surjectivité déterministe du Moteur vers le Noyau affectif (Arbitrage 4) :
Tout point géométriquement valide `p` du Noyau affectif (central, axial, diagonal ou latéral
à toute strate `Z`) est déterministement atteint par `projectToCoreAffect (witnessEngineForPoint p) = p`.
-/
theorem projectToCoreAffect_surjective (p : CoreAffectPoint) (h : isValidCoreAffect p) :
    projectToCoreAffect (witnessEngineForPoint p) = p := by
  rcases p with ⟨x, y, z⟩
  rcases h with ⟨hx, hy⟩ | ⟨hz, hsum⟩
  · dsimp [CoreAffectPoint.isCentral] at hx hy
    subst hx hy
    cases z with
    | zero => rfl
    | succ n =>
      cases n with
      | zero => rfl
      | succ d => rfl
  · dsimp [CoreAffectPoint.isOnCrown, CoreAffectPoint.displacementSum] at hz hsum
    cases z with
    | zero => omega
    | succ n =>
      cases n with
      | zero => omega
      | succ d =>
        have hsum' : x.natAbs + y.natAbs = 2 * d + 2 := by
          dsimp [crownRadius] at hsum
          exact hsum
        have hxy_nz : ¬(x == 0 && y == 0) = true := by
          intro h0
          simp only [Bool.and_eq_true, beq_iff_eq] at h0
          omega
        have hxy_f : (x == 0 && y == 0) = false := Bool.eq_false_iff.mpr hxy_nz
        unfold witnessEngineForPoint
        dsimp only
        rw [hxy_f]
        simp only [Bool.false_eq_true, ↓reduceIte]
        have hd : Nat.succ (Nat.succ d) - 2 = d := rfl
        rcases (by omega : x > 0 ∨ x < 0 ∨ x = 0) with hx_pos | hx_neg | hx_zero <;>
        rcases (by omega : y > 0 ∨ y < 0 ∨ y = 0) with hy_pos | hy_neg | hy_zero
        · have hax : x.natAbs ≥ 1 := by omega
          have hay : y.natAbs ≥ 1 := by omega
          have h_ax0 : (x.natAbs == 0 || y.natAbs == 0) = false := by
            simp [Nat.ne_of_gt hax, Nat.ne_of_gt hay]
          simp only [hx_pos, hy_pos, h_ax0, Bool.false_eq_true, ↓reduceIte]
          rw [project_engaged_crown .pos .pos (Nat.succ (Nat.succ d) - 2) x.natAbs y.natAbs rfl, hd]
          unfold deployCouplingWithPrecision signedAmplitude
          rw [apportionRay_exact d x.natAbs y.natAbs hax hay hsum']
          simp only [CoreAffectPoint.mk.injEq, and_true]
          exact ⟨ofNat_natAbs_pos x hx_pos, ofNat_natAbs_pos y hy_pos⟩
        · have hax : x.natAbs ≥ 1 := by omega
          have hay : y.natAbs ≥ 1 := by omega
          have h_ax0 : (x.natAbs == 0 || y.natAbs == 0) = false := by
            simp [Nat.ne_of_gt hax, Nat.ne_of_gt hay]
          have hnoty : ¬(y > 0) := by omega
          simp only [hx_pos, hnoty, hy_neg, h_ax0, Bool.false_eq_true, ↓reduceIte]
          rw [project_engaged_crown .pos .neg (Nat.succ (Nat.succ d) - 2) x.natAbs y.natAbs rfl, hd]
          unfold deployCouplingWithPrecision signedAmplitude
          rw [apportionRay_exact d x.natAbs y.natAbs hax hay hsum']
          simp only [CoreAffectPoint.mk.injEq, and_true]
          exact ⟨ofNat_natAbs_pos x hx_pos, neg_ofNat_natAbs_neg y hy_neg⟩
        · subst hy_zero
          simp only [hx_pos, Int.lt_irrefl, Int.natAbs_zero,
            beq_self_eq_true, Bool.or_true, ↓reduceIte]
          rw [project_engaged_crown .pos .zero (Nat.succ (Nat.succ d) - 2) 1 1 rfl, hd]
          unfold deployCouplingWithPrecision signedAmplitude
          have hxr : 2 * d + 2 = x.natAbs := by omega
          simp only [CoreAffectPoint.mk.injEq, and_true]
          rw [hxr]
          exact ofNat_natAbs_pos x hx_pos
        · have hax : x.natAbs ≥ 1 := by omega
          have hay : y.natAbs ≥ 1 := by omega
          have h_ax0 : (x.natAbs == 0 || y.natAbs == 0) = false := by
            simp [Nat.ne_of_gt hax, Nat.ne_of_gt hay]
          have hnotx : ¬(x > 0) := by omega
          simp only [hnotx, hx_neg, hy_pos, h_ax0, Bool.false_eq_true, ↓reduceIte]
          rw [project_engaged_crown .neg .pos (Nat.succ (Nat.succ d) - 2) x.natAbs y.natAbs rfl, hd]
          unfold deployCouplingWithPrecision signedAmplitude
          rw [apportionRay_exact d x.natAbs y.natAbs hax hay hsum']
          simp only [CoreAffectPoint.mk.injEq, and_true]
          exact ⟨neg_ofNat_natAbs_neg x hx_neg, ofNat_natAbs_pos y hy_pos⟩
        · have hax : x.natAbs ≥ 1 := by omega
          have hay : y.natAbs ≥ 1 := by omega
          have h_ax0 : (x.natAbs == 0 || y.natAbs == 0) = false := by
            simp [Nat.ne_of_gt hax, Nat.ne_of_gt hay]
          have hnotx : ¬(x > 0) := by omega
          have hnoty : ¬(y > 0) := by omega
          simp only [hnotx, hx_neg, hnoty, hy_neg, h_ax0, Bool.false_eq_true, ↓reduceIte]
          rw [project_engaged_crown .neg .neg (Nat.succ (Nat.succ d) - 2) x.natAbs y.natAbs rfl, hd]
          unfold deployCouplingWithPrecision signedAmplitude
          rw [apportionRay_exact d x.natAbs y.natAbs hax hay hsum']
          simp only [CoreAffectPoint.mk.injEq, and_true]
          exact ⟨neg_ofNat_natAbs_neg x hx_neg, neg_ofNat_natAbs_neg y hy_neg⟩
        · subst hy_zero
          have hnotx : ¬(x > 0) := by omega
          simp only [hnotx, hx_neg, Int.lt_irrefl, Int.natAbs_zero,
            beq_self_eq_true, Bool.or_true, ↓reduceIte]
          rw [project_engaged_crown .neg .zero (Nat.succ (Nat.succ d) - 2) 1 1 rfl, hd]
          unfold deployCouplingWithPrecision signedAmplitude
          have hxr : 2 * d + 2 = x.natAbs := by omega
          simp only [CoreAffectPoint.mk.injEq, and_true]
          rw [hxr]
          exact neg_ofNat_natAbs_neg x hx_neg
        · subst hx_zero
          simp only [Int.lt_irrefl, hy_pos, Int.natAbs_zero,
            beq_self_eq_true, Bool.true_or, ↓reduceIte]
          rw [project_engaged_crown .zero .pos (Nat.succ (Nat.succ d) - 2) 1 1 rfl, hd]
          unfold deployCouplingWithPrecision signedAmplitude
          have hyr : 2 * d + 2 = y.natAbs := by omega
          simp only [CoreAffectPoint.mk.injEq, true_and, and_true]
          rw [hyr]
          exact ofNat_natAbs_pos y hy_pos
        · subst hx_zero
          have hnoty : ¬(y > 0) := by omega
          simp only [Int.lt_irrefl, hnoty, hy_neg, Int.natAbs_zero,
            beq_self_eq_true, Bool.true_or, ↓reduceIte]
          rw [project_engaged_crown .zero .neg (Nat.succ (Nat.succ d) - 2) 1 1 rfl, hd]
          unfold deployCouplingWithPrecision signedAmplitude
          have hyr : 2 * d + 2 = y.natAbs := by omega
          simp only [CoreAffectPoint.mk.injEq, true_and, and_true]
          rw [hyr]
          exact neg_ofNat_natAbs_neg y hy_neg
        · subst hx_zero hy_zero
          exact absurd rfl hxy_nz

private theorem deployCouplingWithPrecision_nonneutral_crown (c : EngineCoupling)
    (h_non_neut : c.isGlobalNeutrality = false) (d piA piC : Nat) :
    (deployCouplingWithPrecision c d piA piC).z = d + 2 ∧
    (deployCouplingWithPrecision c d piA piC).isOnCrown := by
  rcases apportionRay_bounds d piA piC with ⟨_, _, _⟩
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;>
      first
      | (simp [EngineCoupling.isGlobalNeutrality, Polarity.isEngaged] at h_non_neut; done)
      | (refine ⟨rfl, ?_⟩
         unfold CoreAffectPoint.isOnCrown
         dsimp [deployCouplingWithPrecision, CoreAffectPoint.displacementSum, crownRadius, signedAmplitude]
         refine ⟨by omega, ?_⟩
         try simp only [natAbs_neg_ofNat, natAbs_pos_ofNat]
         omega)

-- Source : Résolution R5 (Trajectoire canonique séquentielle Veille → Surprise → Anticipation → Couronne)
/--
Trajectoire séquentielle complète sous `engineStep` et `projectToCoreAffect` (R5) :
À profondeur basale `persistenceDepth = 0`, depuis un état de Veille `(0, 0, 0)` (couplage neutre
`(A0, C0)`, sans suspension descendante ni engagement attentionnel) soumis à un écart saillant,
l'itération de `engineStep` traverse exactement les quatre régimes canoniques :
- `s0` : Point de Veille `(0, 0, 0)` ;
- `engineStep s0` : Surprise `(0, 0, 1)` (rupture perceptive ascendante) ;
- `engineStep (engineStep s0)` : Anticipation `(0, 0, 2)` (suspension descendante endogène) ;
- `engineStep (engineStep (engineStep s0))` : Couronne `Z = 2` en `(0, 2, 2)`.
-/
theorem engineStep_canonical_trajectory (s0 : PredictiveEngineState)
    (h_sal : s0.discrepancy.isSensorilySalient = true)
    (h_neut : s0.currentCoupling.isGlobalNeutrality = true)
    (h_nosusp : s0.subjective.descendingSuspension = false)
    (h_uneng : s0.attentional.isEngaged = false)
    (h_depth : s0.attentional.persistenceDepth = 0) :
    projectToCoreAffect s0 = ⟨0, 0, 0⟩ ∧
    projectToCoreAffect (engineStep s0) = ⟨0, 0, 1⟩ ∧
    projectToCoreAffect (engineStep (engineStep s0)) = ⟨0, 0, 2⟩ ∧
    projectToCoreAffect (engineStep (engineStep (engineStep s0))) = ⟨0, 2, 2⟩ := by
  have h_att0 : s0.subjective.attenteGradient = .zero := by
    unfold PredictiveEngineState.currentCoupling EngineCoupling.isGlobalNeutrality Polarity.isEngaged at h_neut
    cases ha : s0.subjective.attenteGradient <;> simp [ha] at h_neut ⊢
  let s1 := { s0 with perceptive := { controleGradient := .pos } }
  have h_s1 : engineStep s0 = s1 := engineStep_of_salient_neutral s0 h_sal h_neut
  have h_s1_sal : s1.discrepancy.isSensorilySalient = true := h_sal
  have h_s1_neut : s1.currentCoupling.isGlobalNeutrality = false := by
    dsimp [s1, PredictiveEngineState.currentCoupling, EngineCoupling.isGlobalNeutrality, Polarity.isEngaged]
    rw [h_att0]
    rfl
  have h_s1_nosusp : s1.subjective.descendingSuspension = false := h_nosusp
  have h_s1_uneng : s1.attentional.isEngaged = false := h_uneng
  let s2 := { s1 with subjective := { s1.subjective with descendingSuspension := true } }
  have h_s2 : engineStep s1 = s2 :=
    engineStep_of_salient_nonneutral_unsuspended s1 h_s1_sal h_s1_neut h_s1_nosusp h_s1_uneng
  have h_s2_sal : s2.discrepancy.isSensorilySalient = true := h_sal
  have h_s2_neut : s2.currentCoupling.isGlobalNeutrality = false := h_s1_neut
  have h_s2_susp : s2.subjective.descendingSuspension = true := rfl
  have h_s2_uneng : s2.attentional.isEngaged = false := h_uneng
  have h_s2_depth : s2.attentional.persistenceDepth = 0 := h_depth
  let s3 := { s2 with attentional := { s2.attentional with allocatedPrecision := s2.attentional.engagementThreshold } }
  have h_s3 : engineStep s2 = s3 :=
    engineStep_of_salient_nonneutral_suspended_unengaged s2 h_s2_sal h_s2_neut h_s2_susp h_s2_uneng
  have h_s3_sal : s3.discrepancy.isSensorilySalient = true := h_sal
  have h_s3_neut : s3.currentCoupling.isGlobalNeutrality = false := h_s1_neut
  have h_s3_eng : s3.attentional.isEngaged = true := by
    dsimp [s3, AttentionalInterface.isEngaged]; simp
  refine ⟨?_, ?_, ?_, ?_⟩
  · exact neutral_coupling_without_suspension_yields_veille s0 h_neut h_nosusp
  · rw [h_s1]
    dsimp [projectToCoreAffect]
    simp only [h_s1_sal, h_s1_neut, h_s1_uneng, h_s1_nosusp, Bool.not_true, Bool.not_false,
      Bool.or_self, Bool.false_eq_true, ↓reduceIte]
  · rw [h_s1, h_s2]
    dsimp [projectToCoreAffect]
    simp only [h_s2_sal, h_s2_neut, h_s2_uneng, h_s2_susp, h_s2_depth, Bool.not_true, Bool.not_false,
      Bool.or_self, Bool.false_eq_true, ↓reduceIte]
  · rw [h_s1, h_s2, h_s3]
    dsimp [projectToCoreAffect]
    simp only [h_s3_sal, h_s3_neut, h_s3_eng, Bool.not_true, Bool.or_self, Bool.false_eq_true, ↓reduceIte]
    dsimp [s3, s2, s1, PredictiveEngineState.currentCoupling, deployCouplingWithPrecision, signedAmplitude]
    rw [h_att0, h_depth]
    rfl

/--
Extension de la trajectoire séquentielle depuis la Surprise `(0, 0, 1)` vers une couronne
`(X, Y, 2)` quelconque (à couplage non neutre arbitraire `s1.currentCoupling`) :
`Surprise (0, 0, 1) → Anticipation (0, 0, 2) → Couronne (X, Y, 2)`.
-/
theorem engineStep_surprise_to_crown (s1 : PredictiveEngineState)
    (h_sal : s1.discrepancy.isSensorilySalient = true)
    (h_non_neut : s1.currentCoupling.isGlobalNeutrality = false)
    (h_nosusp : s1.subjective.descendingSuspension = false)
    (h_uneng : s1.attentional.isEngaged = false)
    (h_depth : s1.attentional.persistenceDepth = 0) :
    let p_crown := projectToCoreAffect (engineStep (engineStep s1))
    projectToCoreAffect s1 = ⟨0, 0, 1⟩ ∧
    projectToCoreAffect (engineStep s1) = ⟨0, 0, 2⟩ ∧
    p_crown = deployCouplingWithPrecision s1.currentCoupling 0
      s1.attentional.precisionA s1.attentional.precisionC ∧
    p_crown.z = 2 ∧
    p_crown.isOnCrown := by
  let s2 := { s1 with subjective := { s1.subjective with descendingSuspension := true } }
  have h_s2 : engineStep s1 = s2 :=
    engineStep_of_salient_nonneutral_unsuspended s1 h_sal h_non_neut h_nosusp h_uneng
  have h_s2_sal : s2.discrepancy.isSensorilySalient = true := h_sal
  have h_s2_neut : s2.currentCoupling.isGlobalNeutrality = false := h_non_neut
  have h_s2_susp : s2.subjective.descendingSuspension = true := rfl
  have h_s2_uneng : s2.attentional.isEngaged = false := h_uneng
  have h_s2_depth : s2.attentional.persistenceDepth = 0 := h_depth
  let s3 := { s2 with attentional := { s2.attentional with allocatedPrecision := s2.attentional.engagementThreshold } }
  have h_s3 : engineStep s2 = s3 :=
    engineStep_of_salient_nonneutral_suspended_unengaged s2 h_s2_sal h_s2_neut h_s2_susp h_s2_uneng
  have h_s3_sal : s3.discrepancy.isSensorilySalient = true := h_sal
  have h_s3_neut : s3.currentCoupling.isGlobalNeutrality = false := h_non_neut
  have h_s3_eng : s3.attentional.isEngaged = true := by
    dsimp [s3, AttentionalInterface.isEngaged]; simp
  have h_crown_pt :
      projectToCoreAffect (engineStep (engineStep s1)) =
        deployCouplingWithPrecision s1.currentCoupling 0 s1.attentional.precisionA s1.attentional.precisionC := by
    rw [h_s2, h_s3]
    dsimp [projectToCoreAffect]
    simp only [h_s3_sal, h_s3_neut, h_s3_eng, Bool.not_true, Bool.or_self, Bool.false_eq_true, ↓reduceIte]
    change deployCouplingWithPrecision s1.currentCoupling s1.attentional.persistenceDepth
      s1.attentional.precisionA s1.attentional.precisionC = _
    rw [h_depth]
  have h_z_crown := deployCouplingWithPrecision_nonneutral_crown s1.currentCoupling h_non_neut 0
    s1.attentional.precisionA s1.attentional.precisionC
  refine ⟨?_, ?_, h_crown_pt, ?_, ?_⟩
  · dsimp [projectToCoreAffect]
    simp only [h_sal, h_non_neut, h_uneng, h_nosusp, Bool.not_true, Bool.not_false,
      Bool.or_self, Bool.false_eq_true, ↓reduceIte]
  · rw [h_s2]
    dsimp [projectToCoreAffect]
    simp only [h_s2_sal, h_s2_neut, h_s2_uneng, h_s2_susp, h_s2_depth, Bool.not_true, Bool.not_false,
      Bool.or_self, Bool.false_eq_true, ↓reduceIte]
  · rw [h_crown_pt]; exact h_z_crown.1
  · rw [h_crown_pt]; exact h_z_crown.2

/-!
## 5. Loi de dissipation allostatique graduelle (Retour vers le Point de Veille)
-/

-- Source : Document 1, §6.3 & Arbitrage 3 (Court-circuit de descente allostatique Z = 2 → Z = 0)
/--
Opérateur de dissipation allostatique pas à pas (avec court-circuit en Z = 2) :
Lorsque la perturbation redescend sous le seuil de résorption :
1. Le système contracte d'abord ses coordonnées périphériques `(X, Y, Z)` vers le centre
   opérateur `(0, 0, Z)` de sa strate.
2. Pour un centre en strate profonde (`Z ≥ 3`), il redescend d'une strate `(0, 0, Z - 1)`.
3. Depuis le centre d'Anticipation `(0, 0, 2)` — comme depuis `(0, 0, 1)` —, la descente
   **court-circuite directement vers le Point de Veille `(0, 0, 0)`** en un seul pas, sans
   transiter par la Surprise `(0, 0, 1)` qui demeure exclusivement réservée à la rupture
   ascendante de veille.
-/
def dissipationStep (p : CoreAffectPoint) : CoreAffectPoint :=
  if p.x != 0 || p.y != 0 then
    ⟨0, 0, p.z⟩
  else match p.z with
    | 0     => ⟨0, 0, 0⟩
    | 1     => ⟨0, 0, 0⟩
    | 2     => ⟨0, 0, 0⟩
    | z + 3 => ⟨0, 0, z + 2⟩

/--
Lemme 6 (Invariance topologique de la dissipation allostatique, Doc. 1, §6.3) :
Tout pas de dissipation allostatique appliqué à un point quelconque produit un état
géométriquement valide dans le Noyau affectif (centré sur l'axe des opérateurs `(0, 0, Z)`).
-/
theorem dissipationStep_valid (p : CoreAffectPoint) :
    isValidCoreAffect (dissipationStep p) := by
  unfold dissipationStep
  split
  · exact Or.inl ⟨rfl, rfl⟩
  · cases p.z with
    | zero => exact Or.inl ⟨rfl, rfl⟩
    | succ n =>
      cases n with
      | zero => exact Or.inl ⟨rfl, rfl⟩
      | succ m =>
        cases m <;> exact Or.inl ⟨rfl, rfl⟩

/--
Lemme 6bis (Court-circuit direct de l'Anticipation `(0, 0, 2) → (0, 0, 0)`, Arbitrage 3) :
L'opérateur d'Anticipation `(0, 0, 2)` redescend directement au Point de Veille `(0, 0, 0)`
en un seul pas sans passer par la Surprise `(0, 0, 1)`.
-/
theorem anticipation_short_circuits_to_veille :
    dissipationStep ⟨0, 0, 2⟩ = ⟨0, 0, 0⟩ := rfl

/--
Lemme 6ter (Évitement strict de la Surprise lors de la descente depuis `Z ≥ 2`, Arbitrage 3) :
Aucune trajectoire de dissipation amorcée en strate `Z ≥ 2` ne transite par la Surprise `(0, 0, 1)`.
-/
theorem dissipation_from_ge2_never_visits_surprise (p : CoreAffectPoint) (hz : p.z ≥ 2) :
    dissipationStep p ≠ ⟨0, 0, 1⟩ := by
  unfold dissipationStep
  split
  · intro h
    simp only [CoreAffectPoint.mk.injEq] at h
    omega
  · cases hpz : p.z with
    | zero => omega
    | succ n =>
      cases n with
      | zero => omega
      | succ m =>
        cases m with
        | zero =>
          dsimp
          intro h
          simp only [CoreAffectPoint.mk.injEq] at h
          omega
        | succ k =>
          dsimp
          intro h
          simp only [CoreAffectPoint.mk.injEq] at h
          omega

/--
Lemme 7 (Stabilité de l'attracteur basal, Doc. 1, §4 & §6.3) :
Le Point de Veille `(0, 0, 0)` est un point fixe de l'opérateur de dissipation allostatique.
-/
theorem pointDeVeille_is_fixed_point :
    dissipationStep ⟨0, 0, 0⟩ = ⟨0, 0, 0⟩ := rfl

/--
Lemme 8 (Unicité de l'attracteur basal, Doc. 1, §6.3) :
Un point de l'espace affectif est un point fixe de `dissipationStep` si et seulement s'il
s'agit du Point de Veille `(0, 0, 0)`.
-/
theorem dissipationStep_fixed_iff (p : CoreAffectPoint) :
    dissipationStep p = p ↔ p = ⟨0, 0, 0⟩ := by
  constructor
  · intro h
    obtain ⟨x, y, z⟩ := p
    unfold dissipationStep at h
    dsimp at h
    split at h
    · rename_i h_periph
      simp only [Bool.or_eq_true, bne_iff_ne, ne_eq] at h_periph
      simp only [CoreAffectPoint.mk.injEq] at h
      omega
    · rename_i h_cent
      simp only [Bool.or_eq_true, bne_iff_ne, ne_eq] at h_cent
      have hx : x = 0 := by omega
      have hy : y = 0 := by omega
      subst hx hy
      cases z with
      | zero => rfl
      | succ n =>
        cases n with
        | zero => simp only [CoreAffectPoint.mk.injEq] at h; omega
        | succ m =>
          cases m with
          | zero => simp only [CoreAffectPoint.mk.injEq] at h; omega
          | succ k => simp only [CoreAffectPoint.mk.injEq] at h; omega
  · intro h
    rw [h]
    rfl

-- Source : Document 1, §6.3 (Cinétique de dissipation allostatique)
/--
Potentiel de Lyapunov discret mesurant la distance cinétique au Point de Veille `(0, 0, 0)`
le long de la trajectoire de dissipation allostatique.
-/
def dissipationPotential (p : CoreAffectPoint) : Nat :=
  2 * p.z + (if p.x != 0 || p.y != 0 then 1 else 0)

/--
Lemme 9 (Décroissance stricte du potentiel de Lyapunov avec court-circuit, Doc. 1, §6.3 & Arbitrage 3) :
Pour tout état distinct du Point de Veille `(0, 0, 0)`, chaque pas de dissipation
allostatique réduit strictement le potentiel `dissipationPotential` (avec saut `ΔV = -4`
sur le palier de court-circuit `(0, 0, 2) → (0, 0, 0)`).
-/
theorem dissipation_strictly_decreases (p : CoreAffectPoint) (h : p ≠ ⟨0, 0, 0⟩) :
    dissipationPotential (dissipationStep p) < dissipationPotential p := by
  obtain ⟨x, y, z⟩ := p
  unfold dissipationStep dissipationPotential
  dsimp
  split
  · dsimp
    omega
  · rename_i h_cent
    simp only [Bool.or_eq_true, bne_iff_ne, ne_eq] at h_cent
    have hx : x = 0 := by omega
    have hy : y = 0 := by omega
    subst hx hy
    cases z with
    | zero => exact False.elim (h rfl)
    | succ n =>
      cases n with
      | zero => dsimp; omega
      | succ m =>
        cases m <;> (dsimp; omega)

/-- Vérification exacte du saut de potentiel `ΔV = -4` sur le palier court-circuité `Z = 2 → 0`. -/
theorem dissipationPotential_short_circuit_jump :
    dissipationPotential ⟨0, 0, 2⟩ - dissipationPotential (dissipationStep ⟨0, 0, 2⟩) = 4 := rfl

private theorem repeat_succ_apply {α : Type} (f : α → α) (n : Nat) (a : α) :
    Nat.repeat f (n + 1) a = Nat.repeat f n (f a) := by
  induction n with
  | zero => rfl
  | succ n ih => exact congrArg f ih

private theorem dissipationStep_repeat_veille (n : Nat) :
    Nat.repeat dissipationStep n ⟨0, 0, 0⟩ = ⟨0, 0, 0⟩ := by
  induction n with
  | zero => rfl
  | succ n ih => exact congrArg dissipationStep ih

private theorem dissipation_central_ge2_reaches_veille (k : Nat) :
    Nat.repeat dissipationStep (k + 2) ⟨0, 0, k + 2⟩ = ⟨0, 0, 0⟩ := by
  induction k with
  | zero =>
    rw [repeat_succ_apply]
    change Nat.repeat dissipationStep 1 ⟨0, 0, 0⟩ = ⟨0, 0, 0⟩
    exact dissipationStep_repeat_veille 1
  | succ k ih =>
    rw [repeat_succ_apply]
    change Nat.repeat dissipationStep (k + 2) ⟨0, 0, k + 2⟩ = ⟨0, 0, 0⟩
    exact ih

private theorem dissipation_central_reaches_veille (z : Nat) :
    Nat.repeat dissipationStep z ⟨0, 0, z⟩ = ⟨0, 0, 0⟩ := by
  cases z with
  | zero => rfl
  | succ n =>
    cases n with
    | zero => rfl
    | succ k => exact dissipation_central_ge2_reaches_veille k

/--
Lemme 9bis (Convergence en au plus `Z + 1` pas vers le Point de Veille, Doc. 1, §6.3 & Arbitrage 3) :
Toute trajectoire de dissipation allostatique amorcée en un point quelconque `(X, Y, Z)`
atteint exactement le Point de Veille `(0, 0, 0)` en au plus `Z + 1` pas.
-/
theorem dissipation_reaches_veille (p : CoreAffectPoint) :
    Nat.repeat dissipationStep (p.z + 1) p = ⟨0, 0, 0⟩ := by
  obtain ⟨x, y, z⟩ := p
  dsimp
  by_cases h_periph : (x != 0 || y != 0) = true
  · rw [repeat_succ_apply]
    have hstep : dissipationStep ⟨x, y, z⟩ = ⟨0, 0, z⟩ := by
      unfold dissipationStep
      simp only [h_periph, ↓reduceIte]
    rw [hstep]
    exact dissipation_central_reaches_veille z
  · simp only [Bool.or_eq_true, bne_iff_ne, ne_eq] at h_periph
    have hx : x = 0 := by omega
    have hy : y = 0 := by omega
    subst hx hy
    change dissipationStep (Nat.repeat dissipationStep z ⟨0, 0, z⟩) = ⟨0, 0, 0⟩
    rw [dissipation_central_reaches_veille z]
    rfl

-- Source : Document 1, §6.3 (Seuil de résorption homéostatique et rémanence temporaire)
/--
Opérateur de transition allostatique couplé au seuil de résorption :
Dès que l'écart `d.magnitude` redescend strictement sous le seuil de résorption
homéostatique (`d.resorptionThreshold`), le système exécute un pas de dissipation
allostatique ; tant que l'écart demeure supérieur ou égal à ce seuil (notamment dans
la fenêtre de rémanence temporaire), l'état affectif persiste par hystérésis.
-/
def allostaticStep (d : SalientDiscrepancy) (p : CoreAffectPoint) : CoreAffectPoint :=
  if d.magnitude < d.resorptionThreshold then
    dissipationStep p
  else
    p

/--
Lemme 10 (Rémanence par hystérésis allostatique, Doc. 1, §6.3) :
Tant que l'écart résiduel demeure dans la fenêtre de rémanence temporaire
(`d.isInRemanenceWindow = true`), l'état affectif est maintenu sans dissipation.
-/
theorem remanence_preserves_state (d : SalientDiscrepancy) (p : CoreAffectPoint)
    (h_rem : d.isInRemanenceWindow = true) :
    allostaticStep d p = p := by
  unfold SalientDiscrepancy.isInRemanenceWindow at h_rem
  simp only [decide_eq_true_eq] at h_rem
  unfold allostaticStep
  split
  · omega
  · rfl

/-!
## 6. Frontière du régime concurrentiel et cas limite de coopération (§5.2 & §8.2)
-/

-- Source : Document 1, §5.2 & §8.2 (Prédiction réfutable P1 : arbitrage vs coopération)
/--
Lemme 11 (Frontière du régime concurrentiel, Doc. 1, §5.2 & §8.2 P1) :
Pour toute position située sur la couronne dans le premier quadrant (`x ≥ 0`, `y ≥ 0`),
une co-progression simultanée des deux évaluations à profondeur constante (`(x + 1, y + 1, z)`)
sort nécessairement du losange concurrentiel (`¬ isOnCrown`).
-/
theorem cooperative_step_leaves_crown (p : CoreAffectPoint)
    (h : p.isOnCrown) (hx : p.x ≥ 0) (hy : p.y ≥ 0) :
    ¬ CoreAffectPoint.isOnCrown ⟨p.x + 1, p.y + 1, p.z⟩ := by
  rcases h with ⟨_, hsum⟩
  unfold CoreAffectPoint.isOnCrown CoreAffectPoint.displacementSum at *
  dsimp at *
  intro ⟨_, hsum'⟩
  omega

-- Source : Document 1, §5.2 & §8.2 (Régime concurrentiel vs cas limite de coopération)
/--
Régimes d'allocation des ressources attentionnelles :
- `competitive` : régime concurrentiel strict (budget de précision constant sur le losange `|X| + |Y| = R(Z)`).
- `cooperative` : cas limite de coopération où une action informative accroît simultanément
  les deux évaluations à profondeur constante (`|X| + |Y| ≥ R(Z)`).
-/
inductive ResourceRegime : Type where
  | competitive : ResourceRegime
  | cooperative : ResourceRegime
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 1, §5.2 & §8.2
/--
Invariant d'admissibilité topologique du Noyau affectif paramétré par le régime de ressources (`ResourceRegime`).
-/
def isValidCoreAffectIn : ResourceRegime → CoreAffectPoint → Prop
  | .competitive, p => isValidCoreAffect p
  | .cooperative, p => p.isCentral ∨ (p.z ≥ 2 ∧ crownRadius p.z ≤ p.displacementSum)

end CoreAffect

end Cartograffect
