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
/--
Répertoire formel du Point de Veille (Z = 0) et des sept opérateurs centraux (Z = 1 à Z = 7)
qui président à l'orientation des trajectoires au centre (0, 0, Z) de chaque strate.
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
Déploiement spatial d'un couplage (A, C) sur la couronne de profondeur `z = d + 2`
(où `d` est la profondeur de persistance additionnelle au-delà de Z = 2) :
- Lorsqu'une seule dimension (A ou C) est engagée tandis que l'autre demeure neutre,
  elle capte l'intégralité du poids attentionnel `r = 2 * d + 2` (soit ±2 en Z = 2).
- Lorsque les deux dimensions sont engagées conjointement, la précision se divise
  équitablement entre elles en `k = d + 1` sur chaque axe (soit ±1 en Z = 2).
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

-- Source : Document 1, §4 (Le Moteur prédictif) & §5.2 (Modulation attentionnelle)
/--
Projection complète d'un état du Moteur prédictif (`PredictiveEngineState`) dans l'espace
de coordonnées du Noyau affectif (`CoreAffectPoint`) :
1. Si l'écart est sous le seuil de saillance sensorielle ou si le couplage est (A0, C0),
   le système demeure au Point de Veille (0, 0, 0).
2. Si l'écart franchit le seuil de saillance sensorielle mais que la précision attentionnelle
   reste sous son seuil d'engagement :
   - Sans suspension descendante, le système signale la Surprise (0, 0, 1).
   - Avec suspension descendante par l'Interface Subjective, le système active l'opérateur
     central d'orientation (Anticipation (0, 0, 2) pour `persistenceDepth = 0`, ou (0, 0, d + 2)).
3. Dès que la précision allouée franchit son seuil d'engagement, elle déploie le couplage
   latent vers l'une des huit configurations axiales ou diagonales de la couronne `z = d + 2`.
-/
def projectToCoreAffect (s : PredictiveEngineState) : CoreAffectPoint :=
  let c := s.currentCoupling
  if !s.discrepancy.isSensorilySalient || c.isGlobalNeutrality then
    ⟨0, 0, 0⟩
  else if !s.attentional.isEngaged then
    if s.subjective.descendingSuspension then
      ⟨0, 0, s.attentional.persistenceDepth + 2⟩
    else
      ⟨0, 0, 1⟩
  else
    deployCouplingAtDepth c s.attentional.persistenceDepth

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
Théorème Fondamental de Transition (Doc. 1, §4 & §5) :
Toute configuration ou variation des signaux dans le Moteur prédictif (`PredictiveEngineState`)
induit un état géométriquement bien défini et valide dans le Noyau affectif (`isValidCoreAffect`).
-/
theorem engine_induces_valid_core_affect (s : PredictiveEngineState) :
    isValidCoreAffect (projectToCoreAffect s) := by
  dsimp [projectToCoreAffect]
  split
  · exact Or.inl ⟨rfl, rfl⟩
  · split
    · split
      · exact Or.inl ⟨rfl, rfl⟩
      · exact Or.inl ⟨rfl, rfl⟩
    · exact deployCouplingAtDepth_valid s.currentCoupling s.attentional.persistenceDepth

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

/-!
## 5. Loi de dissipation allostatique graduelle (Retour vers le Point de Veille)
-/

-- Source : Document 1, §6.3 (Dynamique de la Matrice - Loi de dissipation allostatique graduelle)
/--
Opérateur de dissipation allostatique pas à pas :
Lorsque la perturbation redescend sous le seuil de résorption :
1. Le système contracte d'abord ses coordonnées périphériques `(X, Y, Z)` vers le centre
   opérateur `(0, 0, Z)` de sa strate.
2. Il redescend ensuite séquentiellement d'une strate à la strate inférieure `(0, 0, Z - 1)`
   jusqu'au Point de Veille `(0, 0, 0)`, unique attracteur stable d'équilibre basal.
-/
def dissipationStep (p : CoreAffectPoint) : CoreAffectPoint :=
  if p.x != 0 || p.y != 0 then
    ⟨0, 0, p.z⟩
  else match p.z with
    | 0     => ⟨0, 0, 0⟩
    | z + 1 => ⟨0, 0, z⟩

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
    | zero   => exact Or.inl ⟨rfl, rfl⟩
    | succ z => exact Or.inl ⟨rfl, rfl⟩

/--
Lemme 7 (Stabilité de l'attracteur basal, Doc. 1, §4 & §6.3) :
Le Point de Veille `(0, 0, 0)` est un point fixe de l'opérateur de dissipation allostatique.
-/
theorem pointDeVeille_is_fixed_point :
    dissipationStep ⟨0, 0, 0⟩ = ⟨0, 0, 0⟩ := rfl

end CoreAffect

end Cartograffect
