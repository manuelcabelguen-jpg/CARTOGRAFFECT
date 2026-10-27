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

/-!
## 4. Structure finale `TaxonomicState` et Théorème Maître (`end_to_end_coherence`)
-/

-- Source : Document 1, §7 (La Taxonomie affective hiérarchique) & Document 2, §2 & §3
/--
Entrée terminale de la Taxonomie affective (`TaxonomicState`), intégrant l'état de la
Matrice affective (`AffectiveMatrixState`), sa strate hiérarchique (`TaxonomicStratum`),
 sa typologie géométrique (`GeometryType`), son groupe d'orientation (`TaxonomicGroup`)
ainsi que le groupe d'orientation de son antagoniste régulateur.
-/
structure TaxonomicState where
  matrix          : AffectiveMatrixState
  stratum         : TaxonomicStratum
  geometry        : GeometryType
  group           : TaxonomicGroup
  antagonistGroup : TaxonomicGroup

-- Source : Document 1, §7 (La Taxonomie affective hiérarchique)
/-- Projection d'un état de la Matrice affective dans la Taxonomie hiérarchique. -/
def evaluateTaxonomy (ms : AffectiveMatrixState) : TaxonomicState :=
  let p := ms.core.point
  { matrix          := ms
    stratum         := classifyStratum p.z
    geometry        := p.classifyGeometry
    group           := classifyTaxonomicGroup p
    antagonistGroup := classifyTaxonomicGroup ms.antagonist.point }

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
1. Le point du Noyau est exactement la projection de `s`.
2. Le point du Noyau et son antagoniste respectent l'invariant géométrique `isValidCoreAffect`.
3. L'antagoniste appartient à la même strate Z et conserve le rayon de couronne `|X| + |Y|`.
4. Le groupe taxonomique de la position et celui de son antagoniste satisfont de manière
   unique le prédicat de partition `matchesTaxonomicGroup`.
-/
def isCoherentTerminalState (s : PredictiveEngineState) (ts : TaxonomicState) : Prop :=
  ts = runCartograffectPipeline s ∧
  ts.matrix.core.point = projectToCoreAffect s ∧
  isValidCoreAffect ts.matrix.core.point ∧
  isValidCoreAffect ts.matrix.antagonist.point ∧
  ts.matrix.antagonist.point.z = ts.matrix.core.point.z ∧
  ts.matrix.antagonist.point.displacementSum = ts.matrix.core.point.displacementSum ∧
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
  · refine ⟨rfl, rfl, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
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
    exact hts'.1

-- Commande d'audit des axiomes pour la vérification formelle du Théorème Maître :
#print axioms end_to_end_coherence

end AffectiveTaxonomy

end Cartograffect
