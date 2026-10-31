/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
Author: Manuel Cabelguen
-/

import Cartograffect.PredictiveEngine
import Cartograffect.CoreAffect
import Cartograffect.AffectiveMatrix

namespace Cartograffect

namespace AffectiveTaxonomy

open PredictiveEngine
open CoreAffect
open AffectiveMatrix

/-!
## 1. Catégories de strates (Profondeur Z) et Groupes taxonomiques d'orientation
-/

-- Source : Document 1, §2 & §7.2 (Les cinq couches et extensions Z=6, Z=7)
-- Source : Document 2, §1, §3 & §5 (Répertoire systématique des strates Z = 0 à Z = 7)
/--
Strates hiérarchiques de la Taxonomie affective indexées sur l'Axe Z :
- `z0_pointDeVeille`           (Z = 0) : Maintien homéostatique basal (Origine).
- `z1_saillancePerceptive`     (Z = 1) : Rupture de veille sous l'effet de la Surprise.
- `z2_affectsPrimaires`        (Z = 2) : Affects primaires et prototypes fondamentaux (autour de l'Anticipation).
- `z3_emotionsReactives`       (Z = 3) : Émotions réactives rattachées à une cause inférée (autour de l'Émoi).
- `z4_sentimentsReflexifs`     (Z = 4) : Sentiments réflexifs et états relationnels (autour de la Réserve).
- `z5_orientationsDurables`    (Z = 5) : Dispositions, orientations durables et humeurs (autour du Recul).
- `z6_identitesAffectives`     (Z = 6) : Identités affectives (autour du Saisissement).
- `z7_sentimentsTranscendants` (Z = 7) : Sentiments transcendantaux (autour de la Suspension).
- `zDeepProlongation`          (Z ≥ 8) : Prolongement géométrique ouvert au-delà de la 7e strate (§7.2).
-/
inductive TaxonomicStratum : Type where
  | z0_pointDeVeille           : TaxonomicStratum
  | z1_saillancePerceptive     : TaxonomicStratum
  | z2_affectsPrimaires        : TaxonomicStratum
  | z3_emotionsReactives       : TaxonomicStratum
  | z4_sentimentsReflexifs     : TaxonomicStratum
  | z5_orientationsDurables    : TaxonomicStratum
  | z6_identitesAffectives     : TaxonomicStratum
  | z7_sentimentsTranscendants : TaxonomicStratum
  | zDeepProlongation          : Nat → TaxonomicStratum
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 1, §7.2 & Document 2, §3 & §5
/-- Projection de la coordonnée verticale Z vers sa strate taxonomique. -/
def classifyStratum : Nat → TaxonomicStratum
  | 0     => .z0_pointDeVeille
  | 1     => .z1_saillancePerceptive
  | 2     => .z2_affectsPrimaires
  | 3     => .z3_emotionsReactives
  | 4     => .z4_sentimentsReflexifs
  | 5     => .z5_orientationsDurables
  | 6     => .z6_identitesAffectives
  | 7     => .z7_sentimentsTranscendants
  | d + 8 => .zDeepProlongation (d + 8)

-- Source : Document 2, §2 (Typologie géométrique et groupes d'orientation) & §3 (Répertoire)
/--
Les 9 groupes structurels d'orientation de la Taxonomie affective :
- `operateurCentral` : Point de Veille (Z = 0) et opérateurs centraux (0, 0, Z).
- 4 groupes sectoriels (positions axiales et latérales où un axe domine en valeur absolue) :
  `groupeJoie` (Y+ dominant), `groupeTristesse` (Y- dominant),
  `groupePeur` (X- dominant), `groupeCourage` (X+ dominant).
- 4 groupes diagonaux (positions diagonales où `|X| = |Y| > 0`) :
  `groupeDesir` (X+, Y+), `groupeDegout` (X-, Y-),
  `groupeColere` (X-, Y+), `groupeCalme` (X+, Y-).
-/
inductive TaxonomicGroup : Type where
  | operateurCentral : TaxonomicGroup
  | groupeJoie       : TaxonomicGroup
  | groupeTristesse  : TaxonomicGroup
  | groupePeur       : TaxonomicGroup
  | groupeCourage    : TaxonomicGroup
  | groupeDesir      : TaxonomicGroup
  | groupeDegout     : TaxonomicGroup
  | groupeColere     : TaxonomicGroup
  | groupeCalme      : TaxonomicGroup
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 2, §2 & §3
/--
Prédicat formel d'appartenance d'une coordonnée `CoreAffectPoint` à chacun des 9 groupes
taxonomiques, défini directement à partir des relations d'ordre et de dominance sur (X, Y).
-/
def matchesTaxonomicGroup (p : CoreAffectPoint) : TaxonomicGroup → Prop
  | .operateurCentral => p.x = 0 ∧ p.y = 0
  | .groupeJoie       => p.y.natAbs > p.x.natAbs ∧ p.y > 0
  | .groupeTristesse  => p.y.natAbs > p.x.natAbs ∧ p.y < 0
  | .groupePeur       => p.x.natAbs > p.y.natAbs ∧ p.x < 0
  | .groupeCourage    => p.x.natAbs > p.y.natAbs ∧ p.x > 0
  | .groupeDesir      => p.x.natAbs = p.y.natAbs ∧ p.x > 0 ∧ p.y > 0
  | .groupeDegout     => p.x.natAbs = p.y.natAbs ∧ p.x < 0 ∧ p.y < 0
  | .groupeColere     => p.x.natAbs = p.y.natAbs ∧ p.x < 0 ∧ p.y > 0
  | .groupeCalme      => p.x.natAbs = p.y.natAbs ∧ p.x > 0 ∧ p.y < 0

-- Source : Document 2, §2 & §3
/-- Fonction déterministe assignant à tout point de la Matrice son groupe taxonomique. -/
def classifyTaxonomicGroup (p : CoreAffectPoint) : TaxonomicGroup :=
  if p.x = 0 ∧ p.y = 0 then
    .operateurCentral
  else if p.y.natAbs > p.x.natAbs then
    if p.y > 0 then .groupeJoie else .groupeTristesse
  else if p.x.natAbs > p.y.natAbs then
    if p.x < 0 then .groupePeur else .groupeCourage
  else if p.x > 0 then
    if p.y > 0 then .groupeDesir else .groupeCalme
  else
    if p.y > 0 then .groupeColere else .groupeDegout

-- Source : Document 1, §6 & §7 ; Document 2, §2 & §3 (Affinement Orientation géométrique vs Valence)
/-- Sous-secteurs fonctionnels affinant les groupes d'orientation géométrique
    en croisant la dominance d'axe (|Y| > |X| vs |X| > |Y|) et la polarité hédonique (sgn X). -/
inductive FunctionalSubsector where
  | centralOperator          -- X = 0, Y = 0 (Opérateurs de suspens Z = 0..7)
  | axialElan                -- X = 0, Y > 0 (Joie, Enthousiasme, Exaltation, Puissance, Élan, Infini)
  | axialWithdrawal          -- X = 0, Y < 0 (Tristesse, Ennui, Langueur, Impuissance, Inertie, Néant)
  | axialOpening             -- X > 0, Y = 0 (Courage, Curiosité, Assurance, Confiance, Affirmation, Communion)
  | axialThreat              -- X < 0, Y = 0 (Peur, Crainte, Doute, Méfiance, Effacement, Déréliction)
  | diagonalDesire           -- X = Y > 0 (Désir, Attrait, Estime, Intérêt, Triomphe, Sublimation)
  | diagonalDisgust          -- X = Y < 0 (Dégoût, Retrait, Rejet, Désintérêt, Abattement, Dissolution)
  | diagonalAnger            -- X = -Y < 0 (Colère, Exaspération, Frustration, Insatisfaction, Tourment, Rage)
  | diagonalCalm             -- X = -Y > 0 (Calme, Détente, Acceptation, Satisfaction, Ataraxie, Impassibilité)
  | lateralApproachSynergy   -- Y > |X|, X > 0 (Euphorie, Amour, Ferveur, Attachement, Allégresse, Transcendance...)
  | lateralDefensiveUrgency  -- Y > |X|, X < 0 (Consternation, Haine, Envie, Fureur, Terreur, Horreur, Détresse...)
  | lateralTrophotropicPeace -- Y < -|X|, X > 0 (Soulagement, Sérénité, Plénitude, Quiétude, Béatitude, Nirvana, Paix...)
  | lateralAversiveDistress  -- Y < -|X|, X < 0 (Chagrin, Honte, Vide, Désespoir, Accablement, Prostration, Abîme...)
  | lateralEpistemicMastery  -- X > |Y|, Y > 0 (Aplomb, Fierté, Épanouissement, Optimisme, Espoir, Extase...)
  | lateralContemplativeOpen -- X > |Y|, Y < 0 (Émerveillement, Affection, Admiration, Tolérance, Équanimité, Épiphanie...)
  | lateralVigilantAlert     -- X < -|Y|, Y > 0 (Panique, Anxiété, Manque, Inquiétude, Rancœur, Affolement, Sidération...)
  | lateralEpistemicClosure  -- X < -|Y|, Y < 0 (Effroi, Mépris, Défiance, Vulnérabilité, Amertume, Mélancolie, Isolement...)
  deriving DecidableEq, Repr, Inhabited

/-- Classification fonctionnelle fine de toute coordonnée (X, Y). -/
def classifySubsector (x y : Int) : FunctionalSubsector :=
  if x == 0 && y == 0 then .centralOperator
  else if x == 0 && y > 0 then .axialElan
  else if x == 0 && y < 0 then .axialWithdrawal
  else if x > 0 && y == 0 then .axialOpening
  else if x < 0 && y == 0 then .axialThreat
  else if x == y && x > 0 then .diagonalDesire
  else if x == y && x < 0 then .diagonalDisgust
  else if x == -y && x < 0 then .diagonalAnger
  else if x == -y && x > 0 then .diagonalCalm
  else if y > Int.natAbs x && x > 0 then .lateralApproachSynergy
  else if y > Int.natAbs x && x < 0 then .lateralDefensiveUrgency
  else if -y > Int.natAbs x && x > 0 then .lateralTrophotropicPeace
  else if -y > Int.natAbs x && x < 0 then .lateralAversiveDistress
  else if x > Int.natAbs y && y > 0 then .lateralEpistemicMastery
  else if x > Int.natAbs y && y < 0 then .lateralContemplativeOpen
  else if -x > Int.natAbs y && y > 0 then .lateralVigilantAlert
  else .lateralEpistemicClosure

/-- Projection canonique d'un sous-secteur fonctionnel vers son groupe taxonomique d'orientation. -/
def FunctionalSubsector.toTaxonomicGroup : FunctionalSubsector → TaxonomicGroup
  | .centralOperator          => .operateurCentral
  | .axialElan                => .groupeJoie
  | .lateralApproachSynergy   => .groupeJoie
  | .lateralDefensiveUrgency  => .groupeJoie
  | .axialWithdrawal          => .groupeTristesse
  | .lateralTrophotropicPeace => .groupeTristesse
  | .lateralAversiveDistress  => .groupeTristesse
  | .axialOpening             => .groupeCourage
  | .lateralEpistemicMastery  => .groupeCourage
  | .lateralContemplativeOpen => .groupeCourage
  | .axialThreat              => .groupePeur
  | .lateralVigilantAlert     => .groupePeur
  | .lateralEpistemicClosure  => .groupePeur
  | .diagonalDesire           => .groupeDesir
  | .diagonalDisgust          => .groupeDegout
  | .diagonalAnger            => .groupeColere
  | .diagonalCalm             => .groupeCalme

/-- Projection canonique d'un sous-secteur fonctionnel vers sa polarité hédonique (Valence). -/
def FunctionalSubsector.toHedonicPolarity : FunctionalSubsector → HedonicPolarity
  | .centralOperator          => .neutral
  | .axialElan                => .positive
  | .axialOpening             => .positive
  | .diagonalDesire           => .positive
  | .diagonalCalm             => .positive
  | .lateralApproachSynergy   => .positive
  | .lateralTrophotropicPeace => .positive
  | .lateralEpistemicMastery  => .positive
  | .lateralContemplativeOpen => .positive
  | .axialWithdrawal          => .negative
  | .axialThreat              => .negative
  | .diagonalDisgust          => .negative
  | .diagonalAnger            => .negative
  | .lateralDefensiveUrgency  => .negative
  | .lateralAversiveDistress  => .negative
  | .lateralVigilantAlert     => .negative
  | .lateralEpistemicClosure  => .negative

/-!
## 2. Certification de la loi des effectifs et des 176 entrées (Z = 0 à Z = 7)
-/

-- Source : Document 2, §1 & §5 (Règle géométrique de l'effectif des couronnes)
/--
Effectif des positions périphériques sur la couronne de la strate Z :
Pour Z ≥ 2, le nombre de positions à coordonnées entières sur chaque losange s'élève au
quadruple du rayon `crownRadius Z` (soit 8 * (Z - 1)). Aux strates Z = 0 et Z = 1, il est nul.
-/
def crownPeripheralCount (z : Nat) : Nat :=
  4 * crownRadius z

-- Source : Document 2, §1 & §5
/-- Effectif total d'une strate Z (1 opérateur central + positions périphériques de la couronne). -/
def stratumTotalCount (z : Nat) : Nat :=
  1 + crownPeripheralCount z

/--
Vérification formelle des effectifs périphériques des couronnes Z = 2 à Z = 7
(8, 16, 24, 32, 40 et 48 positions périphériques, totalisant 168 positions périphériques)
et du bilan global des 176 entrées (8 centres + 168 positions périphériques, Doc. 2, §3 & §5).
-/
theorem inventory_176_certified :
    crownPeripheralCount 2 = 8 ∧
    crownPeripheralCount 3 = 16 ∧
    crownPeripheralCount 4 = 24 ∧
    crownPeripheralCount 5 = 32 ∧
    crownPeripheralCount 6 = 40 ∧
    crownPeripheralCount 7 = 48 ∧
    (crownPeripheralCount 2 + crownPeripheralCount 3 + crownPeripheralCount 4 +
     crownPeripheralCount 5 + crownPeripheralCount 6 + crownPeripheralCount 7 = 168) ∧
    (stratumTotalCount 0 + stratumTotalCount 1 + stratumTotalCount 2 +
     stratumTotalCount 3 + stratumTotalCount 4 + stratumTotalCount 5 +
     stratumTotalCount 6 + stratumTotalCount 7 = 176) := by
  decide

/-!
## 3. Preuves de cohérence terminale : Exhaustivité et Exclusivité mutuelle
-/

/--
Théorème d'adéquation taxonomique :
Pour tout point `p : CoreAffectPoint`, le groupe assigné par `classifyTaxonomicGroup p`
satisfait le prédicat sémantique `matchesTaxonomicGroup p`.
-/
theorem classifyTaxonomicGroup_correct (p : CoreAffectPoint) :
    matchesTaxonomicGroup p (classifyTaxonomicGroup p) := by
  unfold classifyTaxonomicGroup
  split
  · dsimp [matchesTaxonomicGroup]; exact ‹_›
  · split
    · split <;> (dsimp [matchesTaxonomicGroup]; omega)
    · split
      · split <;> (dsimp [matchesTaxonomicGroup]; omega)
      · split
        · split <;> (dsimp [matchesTaxonomicGroup]; omega)
        · split <;> (dsimp [matchesTaxonomicGroup]; omega)

/--
Théorème d'Exhaustivité des catégories taxonomiques :
Tout point de l'espace affectif appartient à au moins un groupe de la Taxonomie.
-/
theorem taxonomy_group_exhaustive (p : CoreAffectPoint) :
    ∃ g : TaxonomicGroup, matchesTaxonomicGroup p g :=
  ⟨classifyTaxonomicGroup p, classifyTaxonomicGroup_correct p⟩

/--
Théorème d'Exclusivité mutuelle des catégories taxonomiques :
Les 9 prédicats de groupes taxonomiques forment une partition disjointe : aucune position
ne peut appartenir simultanément à deux groupes distincts.
-/
theorem taxonomy_group_exclusive (p : CoreAffectPoint) (g1 g2 : TaxonomicGroup)
    (h1 : matchesTaxonomicGroup p g1) (h2 : matchesTaxonomicGroup p g2) :
    g1 = g2 := by
  cases g1 <;> cases g2 <;> first
    | rfl
    | (exfalso; unfold matchesTaxonomicGroup at h1 h2; omega)

/--
Théorème de Caractérisation Bijective (Partition exacte) :
Un groupe taxonomique `g` correspond au point `p` si et seulement s'il est égal à
`classifyTaxonomicGroup p`.
-/
theorem matchesTaxonomicGroup_iff (p : CoreAffectPoint) (g : TaxonomicGroup) :
    matchesTaxonomicGroup p g ↔ g = classifyTaxonomicGroup p := by
  constructor
  · intro h
    exact taxonomy_group_exclusive p g (classifyTaxonomicGroup p) h (classifyTaxonomicGroup_correct p)
  · intro h
    subst h
    exact classifyTaxonomicGroup_correct p

/--
Correspondance exacte entre les 4 secteurs d'orientation géométrique (`OrientationSector`)
du Noyau affectif et les 4 groupes sectoriels de la Taxonomie (`TaxonomicGroup`, Doc. 2, §2).
-/
theorem dominantSector_iff_taxonomicGroup (p : CoreAffectPoint) :
    (p.dominantSector? = some .joie ↔ matchesTaxonomicGroup p .groupeJoie) ∧
    (p.dominantSector? = some .tristesse ↔ matchesTaxonomicGroup p .groupeTristesse) ∧
    (p.dominantSector? = some .peur ↔ matchesTaxonomicGroup p .groupePeur) ∧
    (p.dominantSector? = some .courage ↔ matchesTaxonomicGroup p .groupeCourage) := by
  unfold CoreAffectPoint.dominantSector?
  dsimp [matchesTaxonomicGroup]
  refine ⟨?_, ?_, ?_, ?_⟩
  all_goals (
    constructor
    · intro h
      split at h <;> try split at h <;> try split at h
      all_goals (first | contradiction | omega)
    · rintro ⟨h1, h2⟩
      split <;> try split <;> try split
      all_goals (first | rfl | omega)
  )

/--
Théorème des quatre liaisons fixes controlatérales entre groupes perpendiculaires (Doc. 2, §4.3) :
Pour toute position latérale (`x ≠ 0`, `y ≠ 0`, `|x| ≠ |y|`), l'opérateur d'antagonisme
associe systématiquement chaque groupe sectoriel au groupe d'orientation perpendiculaire :
- `groupeJoie` avec `X > 0` ↔ `groupePeur` avec `Y < 0`
- `groupeJoie` avec `X < 0` ↔ `groupeCourage` avec `Y < 0`
- `groupeTristesse` avec `X > 0` ↔ `groupePeur` avec `Y > 0`
- `groupeTristesse` avec `X < 0` ↔ `groupeCourage` avec `Y > 0`
-/
theorem contralateral_group_bindings (p : CoreAffectPoint) :
    (matchesTaxonomicGroup p .groupeJoie ∧ p.x > 0 →
      matchesTaxonomicGroup (antagonistPoint p) .groupePeur ∧ (antagonistPoint p).y < 0) ∧
    (matchesTaxonomicGroup p .groupeJoie ∧ p.x < 0 →
      matchesTaxonomicGroup (antagonistPoint p) .groupeCourage ∧ (antagonistPoint p).y < 0) ∧
    (matchesTaxonomicGroup p .groupeTristesse ∧ p.x > 0 →
      matchesTaxonomicGroup (antagonistPoint p) .groupePeur ∧ (antagonistPoint p).y > 0) ∧
    (matchesTaxonomicGroup p .groupeTristesse ∧ p.x < 0 →
      matchesTaxonomicGroup (antagonistPoint p) .groupeCourage ∧ (antagonistPoint p).y > 0) := by
  dsimp [matchesTaxonomicGroup]
  refine ⟨?_, ?_, ?_, ?_⟩
  all_goals (
    rintro ⟨⟨h_dom, h_sign⟩, h_sec⟩
    unfold antagonistPoint
    split
    · omega
    · split <;> (
        dsimp
        try simp only [Int.natAbs_neg]
        omega
      )
  )

/--
Prédicat formel d'appartenance d'un couple `(x, y)` à chacun des 17 sous-secteurs fonctionnels.
-/
def matchesSubsector (x y : Int) : FunctionalSubsector → Prop
  | .centralOperator          => x = 0 ∧ y = 0
  | .axialElan                => x = 0 ∧ y > 0
  | .axialWithdrawal          => x = 0 ∧ y < 0
  | .axialOpening             => x > 0 ∧ y = 0
  | .axialThreat              => x < 0 ∧ y = 0
  | .diagonalDesire           => x = y ∧ x > 0
  | .diagonalDisgust          => x = y ∧ x < 0
  | .diagonalAnger            => x = -y ∧ x < 0
  | .diagonalCalm             => x = -y ∧ x > 0
  | .lateralApproachSynergy   => y > x.natAbs ∧ x > 0
  | .lateralDefensiveUrgency  => y > x.natAbs ∧ x < 0
  | .lateralTrophotropicPeace => -y > x.natAbs ∧ x > 0
  | .lateralAversiveDistress  => -y > x.natAbs ∧ x < 0
  | .lateralEpistemicMastery  => x > y.natAbs ∧ y > 0
  | .lateralContemplativeOpen => x > y.natAbs ∧ y < 0
  | .lateralVigilantAlert     => -x > y.natAbs ∧ y > 0
  | .lateralEpistemicClosure  => -x > y.natAbs ∧ y < 0

private theorem step_subsector (x y : Int) (c : Prop) [Decidable c] (t e : FunctionalSubsector)
    (ht : c → matchesSubsector x y t) (he : ¬c → matchesSubsector x y e) :
    matchesSubsector x y (if c then t else e) := by
  split
  · exact ht ‹_›
  · exact he ‹_›

/--
Théorème d'adéquation des sous-secteurs fonctionnels :
Pour toute coordonnée `(x, y)`, le sous-secteur `classifySubsector x y` satisfait
le prédicat `matchesSubsector x y`.
-/
theorem classifySubsector_correct (x y : Int) :
    matchesSubsector x y (classifySubsector x y) := by
  unfold classifySubsector
  apply step_subsector; · intro h; simp only [Bool.and_eq_true, beq_iff_eq] at h; exact h
  intro h1; simp only [Bool.and_eq_true, beq_iff_eq] at h1
  apply step_subsector; · intro h; simp only [Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at h; exact h
  intro h2; simp only [Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at h2
  apply step_subsector; · intro h; simp only [Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at h; exact h
  intro h3; simp only [Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at h3
  have hx0 : x ≠ 0 := by omega
  clear h1 h2 h3
  apply step_subsector; · intro h; simp only [Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at h; exact h
  intro h4; simp only [Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at h4
  apply step_subsector; · intro h; simp only [Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at h; exact h
  intro h5; simp only [Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at h5
  have hy0 : y ≠ 0 := by omega
  clear h4 h5
  apply step_subsector; · intro h; simp only [Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at h; exact h
  intro h6; simp only [Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at h6
  apply step_subsector; · intro h; simp only [Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at h; exact h
  intro h7; simp only [Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at h7
  have hxy : x ≠ y := by omega
  clear h6 h7
  apply step_subsector; · intro h; simp only [Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at h; exact h
  intro h8; simp only [Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at h8
  apply step_subsector; · intro h; simp only [Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at h; exact h
  intro h9; simp only [Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at h9
  have hxny : x ≠ -y := by omega
  clear h8 h9
  apply step_subsector; · intro h; simp only [Bool.and_eq_true, decide_eq_true_eq] at h; exact h
  intro h10; simp only [Bool.and_eq_true, decide_eq_true_eq] at h10
  apply step_subsector; · intro h; simp only [Bool.and_eq_true, decide_eq_true_eq] at h; exact h
  intro h11; simp only [Bool.and_eq_true, decide_eq_true_eq] at h11
  have hyx : y ≤ x.natAbs := by omega
  clear h10 h11
  apply step_subsector; · intro h; simp only [Bool.and_eq_true, decide_eq_true_eq] at h; exact h
  intro h12; simp only [Bool.and_eq_true, decide_eq_true_eq] at h12
  apply step_subsector; · intro h; simp only [Bool.and_eq_true, decide_eq_true_eq] at h; exact h
  intro h13; simp only [Bool.and_eq_true, decide_eq_true_eq] at h13
  have hnyx : -y ≤ x.natAbs := by omega
  clear h12 h13
  apply step_subsector; · intro h; simp only [Bool.and_eq_true, decide_eq_true_eq] at h; exact h
  intro h14; simp only [Bool.and_eq_true, decide_eq_true_eq] at h14
  apply step_subsector; · intro h; simp only [Bool.and_eq_true, decide_eq_true_eq] at h; exact h
  intro h15; simp only [Bool.and_eq_true, decide_eq_true_eq] at h15
  have hxy2 : x ≤ y.natAbs := by omega
  clear h14 h15
  apply step_subsector; · intro h; simp only [Bool.and_eq_true, decide_eq_true_eq] at h; exact h
  intro h16; simp only [Bool.and_eq_true, decide_eq_true_eq] at h16
  dsimp [matchesSubsector]
  omega

/--
Théorème d'Exclusivité mutuelle des 17 sous-secteurs fonctionnels :
Les 17 sous-secteurs forment une partition disjointe du plan (X, Y).
-/
theorem subsector_exclusive (x y : Int) (s1 s2 : FunctionalSubsector)
    (h1 : matchesSubsector x y s1) (h2 : matchesSubsector x y s2) :
    s1 = s2 := by
  cases s1 <;> cases s2 <;> first
    | rfl
    | (exfalso; unfold matchesSubsector at h1 h2; omega)

/--
Caractérisation bijective des sous-secteurs fonctionnels :
Un sous-secteur `s` satisfait `matchesSubsector x y s` si et seulement s'il coïncide
avec `classifySubsector x y`.
-/
theorem matchesSubsector_iff (x y : Int) (s : FunctionalSubsector) :
    matchesSubsector x y s ↔ s = classifySubsector x y := by
  constructor
  · intro h
    exact subsector_exclusive x y s (classifySubsector x y) h (classifySubsector_correct x y)
  · intro h
    subst h
    exact classifySubsector_correct x y

/--
Tout sous-secteur fonctionnel vérifiant `matchesSubsector p.x p.y s` se projette sur le
groupe taxonomique correspondant de `p`.
-/
theorem matchesSubsector_toTaxonomicGroup (p : CoreAffectPoint) (s : FunctionalSubsector)
    (h : matchesSubsector p.x p.y s) :
    matchesTaxonomicGroup p s.toTaxonomicGroup := by
  cases s <;> (dsimp [matchesSubsector, FunctionalSubsector.toTaxonomicGroup, matchesTaxonomicGroup] at h ⊢; omega)

/--
Théorème de raffinement taxonomique des sous-secteurs fonctionnels :
Pour tout point `p : CoreAffectPoint`, la projection du sous-secteur fonctionnel
`classifySubsector p.x p.y` sur `TaxonomicGroup` restitue exactement `classifyTaxonomicGroup p`.
-/
theorem classifySubsector_refines_group (p : CoreAffectPoint) :
    (classifySubsector p.x p.y).toTaxonomicGroup = classifyTaxonomicGroup p :=
  (matchesTaxonomicGroup_iff p _).mp
    (matchesSubsector_toTaxonomicGroup p (classifySubsector p.x p.y) (classifySubsector_correct p.x p.y))

/--
Tout sous-secteur fonctionnel vérifiant `matchesSubsector x y s` détermine de manière univoque
la polarité hédonique `computeHedonicPolarity x y`.
-/
theorem matchesSubsector_toHedonicPolarity (x y : Int) (s : FunctionalSubsector)
    (h : matchesSubsector x y s) :
    s.toHedonicPolarity = computeHedonicPolarity x y := by
  cases s <;> (
    dsimp [matchesSubsector, FunctionalSubsector.toHedonicPolarity] at h ⊢
    unfold computeHedonicPolarity
    split
    · first | rfl | (exfalso; omega)
    · split
      · first | rfl | (exfalso; omega)
      · split
        · first | rfl | (exfalso; omega)
        · split <;> first | rfl | (exfalso; omega)
  )

/--
Théorème de consistance hédonique des sous-secteurs fonctionnels :
Pour toute coordonnée `(x, y)`, la polarité hédonique associée au sous-secteur
`classifySubsector x y` coïncide exactement avec `computeHedonicPolarity x y`.
-/
theorem classifySubsector_determines_valence (x y : Int) :
    (classifySubsector x y).toHedonicPolarity = computeHedonicPolarity x y :=
  matchesSubsector_toHedonicPolarity x y (classifySubsector x y) (classifySubsector_correct x y)

/-!
## 4. Structure finale `TaxonomicState` et Théorème Maître (`end_to_end_coherence`)
-/

-- Source : Document 1, §7 (La Taxonomie affective hiérarchique) & Document 2, §2 & §3
/--
Entrée terminale de la Taxonomie affective (`TaxonomicState`), intégrant l'état de la
Matrice affective (`AffectiveMatrixState`), sa strate hiérarchique (`TaxonomicStratum`),
sa typologie géométrique (`GeometryType`), son groupe d'orientation (`TaxonomicGroup`),
son sous-secteur fonctionnel (`FunctionalSubsector`), ainsi que le groupe d'orientation
et le sous-secteur fonctionnel de son antagoniste régulateur.
-/
structure TaxonomicState where
  matrix              : AffectiveMatrixState
  stratum             : TaxonomicStratum
  geometry            : GeometryType
  group               : TaxonomicGroup
  subsector           : FunctionalSubsector
  antagonistGroup     : TaxonomicGroup
  antagonistSubsector : FunctionalSubsector

-- Source : Document 1, §7 (La Taxonomie affective hiérarchique)
/-- Projection d'un état de la Matrice affective dans la Taxonomie hiérarchique. -/
def evaluateTaxonomy (ms : AffectiveMatrixState) : TaxonomicState :=
  let p := ms.core.point
  let ap := ms.antagonist.point
  { matrix              := ms
    stratum             := classifyStratum p.z
    geometry            := p.classifyGeometry
    group               := classifyTaxonomicGroup p
    subsector           := classifySubsector p.x p.y
    antagonistGroup     := classifyTaxonomicGroup ap
    antagonistSubsector := classifySubsector ap.x ap.y }

/-- Preuve d'inhabitation de `TaxonomicState` centrée sur le Point de Veille (0, 0, 0). -/
instance : Inhabited TaxonomicState where
  default := evaluateTaxonomy default

-- Source : Document 1, Résumé, §1, §4, §5, §6 & §7 (Architecture emboîtée à 4 composantes)
/--
Pipeline fonctionnel complet de bout en bout (`PredictiveEngine` → `CoreAffect` →
`AffectiveMatrix` → `AffectiveTaxonomy`).
-/
def runCartograffectPipeline (s : PredictiveEngineState) : TaxonomicState :=
  evaluateTaxonomy (evaluateMatrix (evaluateCoreAffect s))

/--
Prédicat de cohérence intégrale d'un état taxonomique `ts` vis-à-vis d'un état initial `s`
du Moteur prédictif :
1. Le point du Noyau est exactement la projection de `s` et respecte `isValidCoreAffect`.
2. Son antagoniste est `antagonistPoint`, respecte `isValidCoreAffect`, appartient à la même
   strate Z et conserve le rayon de couronne `|X| + |Y|`.
3. Les pôles vécus, la valence, l'activation, la strate, la géométrie et les sous-secteurs
   fonctionnels sont exactement transduits.
4. Le groupe taxonomique de la position et celui de son antagoniste satisfont de manière
   unique le prédicat de partition `matchesTaxonomicGroup`.
-/
def isCoherentTerminalState (s : PredictiveEngineState) (ts : TaxonomicState) : Prop :=
  ts.matrix.core.point = projectToCoreAffect s ∧
  isValidCoreAffect ts.matrix.core.point ∧
  ts.matrix.antagonist.point = antagonistPoint ts.matrix.core.point ∧
  isValidCoreAffect ts.matrix.antagonist.point ∧
  ts.matrix.antagonist.point.z = ts.matrix.core.point.z ∧
  ts.matrix.antagonist.point.displacementSum = ts.matrix.core.point.displacementSum ∧
  ts.matrix.expectationPole = transduceExpectation ts.matrix.core.point.x ∧
  ts.matrix.controlPole = transduceControl ts.matrix.core.point.y ∧
  ts.matrix.energyRegime = computeEnergyRegime ts.matrix.core.point.x ts.matrix.core.point.y ∧
  ts.matrix.valence = computeHedonicPolarity ts.matrix.core.point.x ts.matrix.core.point.y ∧
  ts.matrix.activation = computeActivation ts.matrix.core.point ∧
  ts.stratum = classifyStratum ts.matrix.core.point.z ∧
  ts.geometry = ts.matrix.core.point.classifyGeometry ∧
  ts.subsector = classifySubsector ts.matrix.core.point.x ts.matrix.core.point.y ∧
  ts.antagonistSubsector = classifySubsector ts.matrix.antagonist.point.x ts.matrix.antagonist.point.y ∧
  matchesTaxonomicGroup ts.matrix.core.point ts.group ∧
  (∀ g : TaxonomicGroup, matchesTaxonomicGroup ts.matrix.core.point g → g = ts.group) ∧
  matchesTaxonomicGroup ts.matrix.antagonist.point ts.antagonistGroup

/--
THÉORÈME MAÎTRE (`end_to_end_coherence`) :
Tout état initial valide du Moteur prédictif (`s : PredictiveEngineState`) traverse
de manière déterministe le Noyau affectif (`CoreAffect`) et la Matrice affective
(`AffectiveMatrix`) pour aboutir à un unique état terminal cohérent dans la Taxonomie
affective hiérarchique (`TaxonomicState`), muni de toutes ses garanties géométriques,
phénoménologiques et d'antagonisme régulateur.
-/
theorem end_to_end_coherence (s : PredictiveEngineState) :
    ∃ ts : TaxonomicState,
      isCoherentTerminalState s ts ∧
      ∀ ts' : TaxonomicState, isCoherentTerminalState s ts' → ts' = ts := by
  refine ⟨runCartograffectPipeline s, ?_, ?_⟩
  · refine ⟨rfl, ?_, rfl, ?_, ?_, ?_, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_, ?_⟩
    · exact (evaluateCoreAffect s).h_valid
    · exact (evaluateMatrix (evaluateCoreAffect s)).antagonist.h_valid
    · exact antagonistPoint_preserves_z (projectToCoreAffect s)
    · exact antagonistPoint_preserves_displacementSum (projectToCoreAffect s)
    · exact classifyTaxonomicGroup_correct (projectToCoreAffect s)
    · intro g hg
      exact taxonomy_group_exclusive (projectToCoreAffect s) g
        (classifyTaxonomicGroup (projectToCoreAffect s))
        hg (classifyTaxonomicGroup_correct (projectToCoreAffect s))
    · exact classifyTaxonomicGroup_correct (antagonistPoint (projectToCoreAffect s))
  · intro ts' hts'
    rcases ts' with ⟨⟨⟨cp, hcp⟩, ep, ctrlp, ereg, val, act, ⟨ap, hap⟩⟩, strat, geom, grp, sub, agrp, asub⟩
    rcases hts' with ⟨h_cp, _, h_ap, _, _, _, h_ep, h_ctrl, h_ereg, h_val, h_act, h_strat, h_geom, h_sub, h_asub, h_grp, _, h_agrp⟩
    dsimp at *
    subst h_cp h_ap h_ep h_ctrl h_ereg h_val h_act h_strat h_geom h_sub h_asub
    have h_grp_eq : grp = classifyTaxonomicGroup (projectToCoreAffect s) :=
      (matchesTaxonomicGroup_iff (projectToCoreAffect s) grp).mp h_grp
    have h_agrp_eq : agrp = classifyTaxonomicGroup (antagonistPoint (projectToCoreAffect s)) :=
      (matchesTaxonomicGroup_iff (antagonistPoint (projectToCoreAffect s)) agrp).mp h_agrp
    subst h_grp_eq h_agrp_eq
    rfl

end AffectiveTaxonomy

export AffectiveTaxonomy (FunctionalSubsector classifySubsector)

end Cartograffect
