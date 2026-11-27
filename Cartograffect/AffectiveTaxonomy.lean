/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later
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
## 1. Régimes discrets de profondeur (`⌊Z⌋`) et Groupes fonctionnels d'orientation (Option 1A)
-/

-- Source : Document 1, §7.2 & DECISIONS_V3 (Arbitrage 4 : Z continu 0..5, discrétisation canonique Z ∈ {0, 1, 2})
/--
Abstraction par régimes discrets de la profondeur hiérarchique continue `Z` :
- `z0_pointDeVeille`        (`⌊Z⌋ = 0`) : Maintien homéostatique basal (discrétisation canonique).
- `z1_saillancePerceptive`  (`⌊Z⌋ = 1`) : Rupture de veille sous la Surprise (discrétisation canonique).
- `z2_affectsPrimaires`     (`⌊Z⌋ = 2`) : Couronne des 8 prototypes affectifs primaires (discrétisation canonique).
- `z3_emotionsReactives`    (`⌊Z⌋ = 3`) : Émotions réactives rattachées à une cause inférée (régime continu, repères illustratifs).
- `z4_sentimentsReflexifs`  (`⌊Z⌋ = 4`) : Sentiments réflexifs et états relationnels (régime continu, repères illustratifs).
- `z5_orientationsDurables` (`⌊Z⌋ = 5`) : Dispositions durables et humeurs (régime continu, repères illustratifs).
- `zExploratoryExtension`   (`⌊Z⌋ ≥ 6`) : Prolongement géométrique exploratoire hors cœur normatif v3.0 (Annexe A).
-/
inductive TaxonomicStratum : Type where
  | z0_pointDeVeille        : TaxonomicStratum
  | z1_saillancePerceptive  : TaxonomicStratum
  | z2_affectsPrimaires     : TaxonomicStratum
  | z3_emotionsReactives    : TaxonomicStratum
  | z4_sentimentsReflexifs  : TaxonomicStratum
  | z5_orientationsDurables : TaxonomicStratum
  | zExploratoryExtension   : Nat → TaxonomicStratum
  deriving DecidableEq, Repr, Inhabited

/-- Projection du régime discret `z = ⌊Z⌋` vers sa strate taxonomique. -/
def classifyStratum : Nat → TaxonomicStratum
  | 0     => .z0_pointDeVeille
  | 1     => .z1_saillancePerceptive
  | 2     => .z2_affectsPrimaires
  | 3     => .z3_emotionsReactives
  | 4     => .z4_sentimentsReflexifs
  | 5     => .z5_orientationsDurables
  | d + 6 => .zExploratoryExtension (d + 6)

-- Source : DECISIONS_V3 (Option 1A — Nomenclature fonctionnelle neutre sans rattachement hédonique croisé)
/--
Les 9 macro-groupes fonctionnels d'orientation de l'espace `(X, Y)` (Option 1A) :
- `centralOperator` : Point de Veille `(0, 0, 0)` et opérateurs centraux `(0, 0, Z)`.
- 4 groupes sectoriels définis par l'axe dominant et son signe (sans assimilation de `(-X, +Y)` à la joie ni de `(+X, -Y)` à la tristesse) :
  `sectorControlPos` (`|Y| > |X|, Y > 0`), `sectorControlNeg` (`|Y| > |X|, Y < 0`),
  `sectorExpectationNeg` (`|X| > |Y|, X < 0`), `sectorExpectationPos` (`|X| > |Y|, X > 0`).
- 4 groupes diagonaux (`|X| = |Y| > 0`) :
  `diagonalSynergyPos` (`X > 0, Y > 0`), `diagonalSynergyNeg` (`X < 0, Y < 0`),
  `diagonalAgenticConfront` (`X < 0, Y > 0`), `diagonalAccommodation` (`X > 0, Y < 0`).
-/
inductive TaxonomicGroup : Type where
  | centralOperator         : TaxonomicGroup
  | sectorControlPos        : TaxonomicGroup
  | sectorControlNeg        : TaxonomicGroup
  | sectorExpectationNeg    : TaxonomicGroup
  | sectorExpectationPos    : TaxonomicGroup
  | diagonalSynergyPos      : TaxonomicGroup
  | diagonalSynergyNeg      : TaxonomicGroup
  | diagonalAgenticConfront : TaxonomicGroup
  | diagonalAccommodation   : TaxonomicGroup
  deriving DecidableEq, Repr, Inhabited

/--
Prédicat formel d'appartenance d'une coordonnée `CoreAffectPoint` à chacun des 9 groupes
fonctionnels d'orientation, défini à partir des relations d'ordre et de dominance sur `(X, Y)`.
-/
def matchesTaxonomicGroup (p : CoreAffectPoint) : TaxonomicGroup → Prop
  | .centralOperator         => p.x = 0 ∧ p.y = 0
  | .sectorControlPos        => p.y.natAbs > p.x.natAbs ∧ p.y > 0
  | .sectorControlNeg        => p.y.natAbs > p.x.natAbs ∧ p.y < 0
  | .sectorExpectationNeg    => p.x.natAbs > p.y.natAbs ∧ p.x < 0
  | .sectorExpectationPos    => p.x.natAbs > p.y.natAbs ∧ p.x > 0
  | .diagonalSynergyPos      => p.x.natAbs = p.y.natAbs ∧ p.x > 0 ∧ p.y > 0
  | .diagonalSynergyNeg      => p.x.natAbs = p.y.natAbs ∧ p.x < 0 ∧ p.y < 0
  | .diagonalAgenticConfront => p.x.natAbs = p.y.natAbs ∧ p.x < 0 ∧ p.y > 0
  | .diagonalAccommodation   => p.x.natAbs = p.y.natAbs ∧ p.x > 0 ∧ p.y < 0

/-- Fonction déterministe assignant à tout point de la Matrice son groupe d'orientation fonctionnel. -/
def classifyTaxonomicGroup (p : CoreAffectPoint) : TaxonomicGroup :=
  if p.x = 0 ∧ p.y = 0 then
    .centralOperator
  else if p.y.natAbs > p.x.natAbs then
    if p.y > 0 then .sectorControlPos else .sectorControlNeg
  else if p.x.natAbs > p.y.natAbs then
    if p.x < 0 then .sectorExpectationNeg else .sectorExpectationPos
  else if p.x > 0 then
    if p.y > 0 then .diagonalSynergyPos else .diagonalAccommodation
  else
    if p.y > 0 then .diagonalAgenticConfront else .diagonalSynergyNeg

-- Source : DECISIONS_V3 (Option 1A — Symétrie sémantique totale sur Y− et canal autonome indépendant A ≥ 0)
/--
Les 17 sous-secteurs fonctionnels affinant la partition de `(X, Y)` en croisant la dominance
d'axe (`|Y| > |X|` vs `|X| > |Y|`) et la polarité de chaque coordonnée conformément à l'Option 1A :
- `(X < 0, Y > 0)` est restreint à l'affrontement agentique (`diagonalAgenticConfront`,
  `lateralAgenticConfront`, `lateralActiveContest` : Colère, Frustration, Hostilité, Révolte) ;
- les états aversifs à faible contrôle perçu (`Angoisse`, `Terreur`, `Horreur`, `Détresse`)
  résident en `(X < 0, Y < 0)` avec activation autonome `A` élevée (`lateralAversiveDistress`, `lateralEpistemicClosure`) ;
- `(X > 0, Y < 0)` code exclusivement l'accommodation / contrôle secondaire face à une limite
  objective d'action (`diagonalAccommodation`, `lateralSecondaryAccomm`, `lateralReceptiveAccomm` :
  Calme adaptatif, Acceptation, Lâcher-prise), tandis que la sécurité/maîtrise apaisée
  (`Sécurité`, `Plénitude`, `Sérénité` hors limite d'action) réside en `Y ≥ 0` avec `A` bas.
-/
inductive FunctionalSubsector where
  | centralOperator         -- X = 0, Y = 0 (Opérateurs centraux de suspens)
  | axialControlPos         -- X = 0, Y > 0 (Contrôle positif pur ; Z=2 : Joie)
  | axialControlNeg         -- X = 0, Y < 0 (Contrôle négatif pur ; Z=2 : Tristesse)
  | axialExpectationPos     -- X > 0, Y = 0 (Attente positive pure ; Z=2 : Courage, Sécurité/Sérénité apaisée à A bas)
  | axialExpectationNeg     -- X < 0, Y = 0 (Attente négative pure ; Z=2 : Peur)
  | diagonalSynergyPos      -- X = Y > 0 (Z=2 : Désir, maîtrise instrumentale)
  | diagonalSynergyNeg      -- X = Y < 0 (Z=2 : Dégoût, rejet aversif à faible contrôle)
  | diagonalAgenticConfront -- X = -Y < 0 (Z=2 : Colère, Frustration — affrontement agentique équilibré)
  | diagonalAccommodation   -- X = -Y > 0 (Z=2 : Calme adaptatif, Acceptation — accommodation face à une limite d'action)
  | lateralApproachSynergy  -- Y > |X|, X > 0 (Engagement instrumental favorable ; Plénitude/Sécurité active à A bas)
  | lateralAgenticConfront  -- Y > |X|, X < 0 (Affrontement agentique à contrôle dominant : Hostilité, Révolte)
  | lateralSecondaryAccomm  -- Y < -|X|, X > 0 (Accommodation / contrôle secondaire à limite d'action dominante : Lâcher-prise)
  | lateralAversiveDistress -- Y < -|X|, X < 0 (Faible contrôle aversif : Angoisse/Terreur/Horreur/Détresse [A haut], Désespoir/Résignation [A bas])
  | lateralEpistemicMastery -- X > |Y|, Y > 0 (Ouverture épistémique maîtrisée : Aplomb, Fierté, Sérénité maîtrisée à A bas)
  | lateralReceptiveAccomm  -- X > |Y|, Y < 0 (Accommodation réceptive face à une limite d'action : Admiration, Consentement)
  | lateralActiveContest    -- X < -|Y|, Y > 0 (Menace épistémique sous maintien d'action : Contestation, Rancœur active)
  | lateralEpistemicClosure -- X < -|Y|, Y < 0 (Fermeture épistémique à faible contrôle : Effroi/Sidération [A haut], Méfiance repliée [A bas])
  deriving DecidableEq, Repr, Inhabited

/-- Classification fonctionnelle fine de toute coordonnée `(X, Y)`. -/
def classifySubsector (x y : Int) : FunctionalSubsector :=
  if x == 0 && y == 0 then .centralOperator
  else if x == 0 && y > 0 then .axialControlPos
  else if x == 0 && y < 0 then .axialControlNeg
  else if x > 0 && y == 0 then .axialExpectationPos
  else if x < 0 && y == 0 then .axialExpectationNeg
  else if x == y && x > 0 then .diagonalSynergyPos
  else if x == y && x < 0 then .diagonalSynergyNeg
  else if x == -y && x < 0 then .diagonalAgenticConfront
  else if x == -y && x > 0 then .diagonalAccommodation
  else if y > Int.natAbs x && x > 0 then .lateralApproachSynergy
  else if y > Int.natAbs x && x < 0 then .lateralAgenticConfront
  else if -y > Int.natAbs x && x > 0 then .lateralSecondaryAccomm
  else if -y > Int.natAbs x && x < 0 then .lateralAversiveDistress
  else if x > Int.natAbs y && y > 0 then .lateralEpistemicMastery
  else if x > Int.natAbs y && y < 0 then .lateralReceptiveAccomm
  else if -x > Int.natAbs y && y > 0 then .lateralActiveContest
  else .lateralEpistemicClosure

/-- Projection canonique d'un sous-secteur fonctionnel vers son groupe d'orientation. -/
def FunctionalSubsector.toTaxonomicGroup : FunctionalSubsector → TaxonomicGroup
  | .centralOperator         => .centralOperator
  | .axialControlPos         => .sectorControlPos
  | .lateralApproachSynergy  => .sectorControlPos
  | .lateralAgenticConfront  => .sectorControlPos
  | .axialControlNeg         => .sectorControlNeg
  | .lateralSecondaryAccomm  => .sectorControlNeg
  | .lateralAversiveDistress => .sectorControlNeg
  | .axialExpectationPos     => .sectorExpectationPos
  | .lateralEpistemicMastery => .sectorExpectationPos
  | .lateralReceptiveAccomm  => .sectorExpectationPos
  | .axialExpectationNeg     => .sectorExpectationNeg
  | .lateralActiveContest    => .sectorExpectationNeg
  | .lateralEpistemicClosure => .sectorExpectationNeg
  | .diagonalSynergyPos      => .diagonalSynergyPos
  | .diagonalSynergyNeg      => .diagonalSynergyNeg
  | .diagonalAgenticConfront => .diagonalAgenticConfront
  | .diagonalAccommodation   => .diagonalAccommodation

/-- Projection canonique d'un sous-secteur fonctionnel vers sa polarité hédonique (Valence). -/
def FunctionalSubsector.toHedonicPolarity : FunctionalSubsector → HedonicPolarity
  | .centralOperator         => .neutral
  | .axialControlPos         => .positive
  | .axialExpectationPos     => .positive
  | .diagonalSynergyPos      => .positive
  | .diagonalAccommodation   => .positive
  | .lateralApproachSynergy  => .positive
  | .lateralSecondaryAccomm  => .positive
  | .lateralEpistemicMastery => .positive
  | .lateralReceptiveAccomm  => .positive
  | .axialControlNeg         => .negative
  | .axialExpectationNeg     => .negative
  | .diagonalSynergyNeg      => .negative
  | .diagonalAgenticConfront => .negative
  | .lateralAgenticConfront  => .negative
  | .lateralAversiveDistress => .negative
  | .lateralActiveContest    => .negative
  | .lateralEpistemicClosure => .negative

/-!
## 2. Loi générale des effectifs de couronne et discrétisation canonique `Z ∈ {0, 1, 2}` (Arbitrage 4)
-/

/-- Effectif des positions entières périphériques sur le losange `L1` de la strate `z`. -/
def crownPeripheralCount (z : Nat) : Nat :=
  4 * crownRadius z

/-- Effectif total d'une strate discrétisée `z` (1 opérateur central + couronne périphérique). -/
def stratumTotalCount (z : Nat) : Nat :=
  1 + crownPeripheralCount z

/--
Loi combinatoire des effectifs de la discrétisation canonique `Z ∈ {0, 1, 2}` (Veille = 1,
Surprise = 1, première couronne = 8 prototypes périphériques, soit 11 états canoniques)
et formule exacte `8 * (d + 1)` pour toute couronne `z = d + 2 ≥ 2`.
-/
theorem canonical_crown_counts_certified (d : Nat) :
    stratumTotalCount 0 = 1 ∧
    stratumTotalCount 1 = 1 ∧
    crownPeripheralCount 2 = 8 ∧
    stratumTotalCount 0 + stratumTotalCount 1 + stratumTotalCount 2 = 11 ∧
    crownPeripheralCount (d + 2) = 8 * (d + 1) := by
  refine ⟨rfl, rfl, rfl, rfl, ?_⟩
  dsimp [crownPeripheralCount, crownRadius]
  omega

/-!
## 3. Preuves de cohérence terminale : Exhaustivité et Exclusivité mutuelle
-/

/--
Théorème d'adéquation taxonomique :
Pour tout point `p : CoreAffectPoint`, le groupe assigné par `classifyTaxonomicGroup p`
satisfait le prédicat `matchesTaxonomicGroup p`.
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
Théorème d'Exhaustivité des catégories d'orientation :
Tout point de l'espace affectif appartient à au moins un groupe de `TaxonomicGroup`.
-/
theorem taxonomy_group_exhaustive (p : CoreAffectPoint) :
    ∃ g : TaxonomicGroup, matchesTaxonomicGroup p g :=
  ⟨classifyTaxonomicGroup p, classifyTaxonomicGroup_correct p⟩

/--
Théorème d'Exclusivité mutuelle des catégories d'orientation :
Les 9 prédicats `matchesTaxonomicGroup` forment une partition disjointe de `CoreAffectPoint`.
-/
theorem taxonomy_group_exclusive (p : CoreAffectPoint) (g1 g2 : TaxonomicGroup)
    (h1 : matchesTaxonomicGroup p g1) (h2 : matchesTaxonomicGroup p g2) :
    g1 = g2 := by
  cases g1 <;> cases g2 <;> first
    | rfl
    | (exfalso; unfold matchesTaxonomicGroup at h1 h2; omega)

/-- Caractérisation bijective de la partition en 9 groupes fonctionnels. -/
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
du Noyau affectif et les 4 groupes sectoriels fonctionnels (`TaxonomicGroup`, Option 1A).
-/
theorem dominantSector_iff_taxonomicGroup (p : CoreAffectPoint) :
    (p.dominantSector? = some .controlPos ↔ matchesTaxonomicGroup p .sectorControlPos) ∧
    (p.dominantSector? = some .controlNeg ↔ matchesTaxonomicGroup p .sectorControlNeg) ∧
    (p.dominantSector? = some .expectationNeg ↔ matchesTaxonomicGroup p .sectorExpectationNeg) ∧
    (p.dominantSector? = some .expectationPos ↔ matchesTaxonomicGroup p .sectorExpectationPos) := by
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
Théorème des quatre liaisons controlatérales entre secteurs perpendiculaires sous `antagonistPoint` :
Pour toute position latérale (`x ≠ 0`, `y ≠ 0`, `|x| ≠ |y|`), l'antagoniste statique permute
systématiquement la dominance de Contrôle (`|Y| > |X|`) et la dominance d'Attente (`|X| > |Y|`) :
- `sectorControlPos` avec `X > 0` ↔ `sectorExpectationNeg` avec `Y < 0`
- `sectorControlPos` avec `X < 0` ↔ `sectorExpectationPos` avec `Y < 0`
- `sectorControlNeg` avec `X > 0` ↔ `sectorExpectationNeg` avec `Y > 0`
- `sectorControlNeg` avec `X < 0` ↔ `sectorExpectationPos` avec `Y > 0`
-/
theorem contralateral_group_bindings (p : CoreAffectPoint) :
    (matchesTaxonomicGroup p .sectorControlPos ∧ p.x > 0 →
      matchesTaxonomicGroup (antagonistPoint p) .sectorExpectationNeg ∧ (antagonistPoint p).y < 0) ∧
    (matchesTaxonomicGroup p .sectorControlPos ∧ p.x < 0 →
      matchesTaxonomicGroup (antagonistPoint p) .sectorExpectationPos ∧ (antagonistPoint p).y < 0) ∧
    (matchesTaxonomicGroup p .sectorControlNeg ∧ p.x > 0 →
      matchesTaxonomicGroup (antagonistPoint p) .sectorExpectationNeg ∧ (antagonistPoint p).y > 0) ∧
    (matchesTaxonomicGroup p .sectorControlNeg ∧ p.x < 0 →
      matchesTaxonomicGroup (antagonistPoint p) .sectorExpectationPos ∧ (antagonistPoint p).y > 0) := by
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

/-- Prédicat formel d'appartenance d'un couple `(x, y)` à chacun des 17 sous-secteurs fonctionnels. -/
def matchesSubsector (x y : Int) : FunctionalSubsector → Prop
  | .centralOperator         => x = 0 ∧ y = 0
  | .axialControlPos         => x = 0 ∧ y > 0
  | .axialControlNeg         => x = 0 ∧ y < 0
  | .axialExpectationPos     => x > 0 ∧ y = 0
  | .axialExpectationNeg     => x < 0 ∧ y = 0
  | .diagonalSynergyPos      => x = y ∧ x > 0
  | .diagonalSynergyNeg      => x = y ∧ x < 0
  | .diagonalAgenticConfront => x = -y ∧ x < 0
  | .diagonalAccommodation   => x = -y ∧ x > 0
  | .lateralApproachSynergy  => y > x.natAbs ∧ x > 0
  | .lateralAgenticConfront  => y > x.natAbs ∧ x < 0
  | .lateralSecondaryAccomm  => -y > x.natAbs ∧ x > 0
  | .lateralAversiveDistress => -y > x.natAbs ∧ x < 0
  | .lateralEpistemicMastery => x > y.natAbs ∧ y > 0
  | .lateralReceptiveAccomm  => x > y.natAbs ∧ y < 0
  | .lateralActiveContest    => -x > y.natAbs ∧ y > 0
  | .lateralEpistemicClosure => -x > y.natAbs ∧ y < 0

private theorem step_subsector (x y : Int) (c : Prop) [Decidable c] (t e : FunctionalSubsector)
    (ht : c → matchesSubsector x y t) (he : ¬c → matchesSubsector x y e) :
    matchesSubsector x y (if c then t else e) := by
  split
  · exact ht ‹_›
  · exact he ‹_›

/--
Théorème d'adéquation des sous-secteurs fonctionnels :
Pour toute coordonnée `(x, y)`, `classifySubsector x y` satisfait `matchesSubsector x y`.
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

/-- Exclusivité mutuelle des 17 sous-secteurs fonctionnels sur le plan `(X, Y)`. -/
theorem subsector_exclusive (x y : Int) (s1 s2 : FunctionalSubsector)
    (h1 : matchesSubsector x y s1) (h2 : matchesSubsector x y s2) :
    s1 = s2 := by
  cases s1 <;> cases s2 <;> first
    | rfl
    | (exfalso; unfold matchesSubsector at h1 h2; omega)

/-- Caractérisation bijective des 17 sous-secteurs fonctionnels. -/
theorem matchesSubsector_iff (x y : Int) (s : FunctionalSubsector) :
    matchesSubsector x y s ↔ s = classifySubsector x y := by
  constructor
  · intro h
    exact subsector_exclusive x y s (classifySubsector x y) h (classifySubsector_correct x y)
  · intro h
    subst h
    exact classifySubsector_correct x y

/-- Tout sous-secteur fonctionnel vérifiant `matchesSubsector p.x p.y s` se projette sur le groupe correspondant. -/
theorem matchesSubsector_toTaxonomicGroup (p : CoreAffectPoint) (s : FunctionalSubsector)
    (h : matchesSubsector p.x p.y s) :
    matchesTaxonomicGroup p s.toTaxonomicGroup := by
  cases s <;> (dsimp [matchesSubsector, FunctionalSubsector.toTaxonomicGroup, matchesTaxonomicGroup] at h ⊢; omega)

/-- Raffinement exact des groupes d'orientation par les 17 sous-secteurs fonctionnels. -/
theorem classifySubsector_refines_group (p : CoreAffectPoint) :
    (classifySubsector p.x p.y).toTaxonomicGroup = classifyTaxonomicGroup p :=
  (matchesTaxonomicGroup_iff p _).mp
    (matchesSubsector_toTaxonomicGroup p (classifySubsector p.x p.y) (classifySubsector_correct p.x p.y))

/-- Tout sous-secteur fonctionnel vérifiant `matchesSubsector x y s` détermine la polarité hédonique. -/
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

/-- Consistance hédonique des 17 sous-secteurs fonctionnels avec la règle lexicographique sur X. -/
theorem classifySubsector_determines_valence (x y : Int) :
    (classifySubsector x y).toHedonicPolarity = computeHedonicPolarity x y :=
  matchesSubsector_toHedonicPolarity x y (classifySubsector x y) (classifySubsector_correct x y)

/-!
## 4. Structure finale `TaxonomicState` et Théorème Maître (`end_to_end_coherence`)
-/

/--
Entrée terminale de la Taxonomie affective (`TaxonomicState`), intégrant l'état de la
Matrice affective (`AffectiveMatrixState` muni du canal autonome `autonomousActivation`),
son régime discret de strate (`TaxonomicStratum`), sa typologie géométrique (`GeometryType`),
son groupe fonctionnel d'orientation (`TaxonomicGroup`), son sous-secteur fonctionnel
(`FunctionalSubsector`), ainsi que ceux de son antagoniste régulateur statique.
-/
structure TaxonomicState where
  matrix              : AffectiveMatrixState
  stratum             : TaxonomicStratum
  geometry            : GeometryType
  group               : TaxonomicGroup
  subsector           : FunctionalSubsector
  antagonistGroup     : TaxonomicGroup
  antagonistSubsector : FunctionalSubsector

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

/-- Preuve d'inhabitation de `TaxonomicState` centrée sur le Point de Veille `(0, 0, 0)`. -/
instance : Inhabited TaxonomicState where
  default := evaluateTaxonomy default

/--
Pipeline fonctionnel complet de bout en bout (`PredictiveEngine` → `CoreAffect` →
`AffectiveMatrix` → `AffectiveTaxonomy`), transmettant le canal d'activation autonome
`s.autonomousActivation` (`A ≥ 0`) indépendamment de la projection `(X, Y, Z)` (Option 1A).
-/
def runCartograffectPipeline (s : PredictiveEngineState) : TaxonomicState :=
  evaluateTaxonomy (evaluateMatrix (evaluateCoreAffect s) s.autonomousActivation)

/--
Prédicat de cohérence intégrale d'un état taxonomique `ts` vis-à-vis d'un état initial `s`
du Moteur prédictif (Option 1A) :
1. Le point du Noyau est exactement `projectToCoreAffect s` et respecte `isValidCoreAffect`.
2. Son antagoniste statique est `antagonistPoint`, respecte `isValidCoreAffect`, appartient à la
   même strate `Z` et conserve le rayon `|X| + |Y|`.
3. Les pôles vécus, le régime d'interaction, la valence, la strate, la géométrie et les
   sous-secteurs sont exactement transduits, tandis que le canal d'activation autonome
   `ts.matrix.autonomousActivation` reproduit `s.autonomousActivation` indépendamment de `(X, Y)`.
4. Le groupe d'orientation de la position et celui de son antagoniste satisfont de manière
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
  ts.matrix.autonomousActivation = s.autonomousActivation ∧
  ts.stratum = classifyStratum ts.matrix.core.point.z ∧
  ts.geometry = ts.matrix.core.point.classifyGeometry ∧
  ts.subsector = classifySubsector ts.matrix.core.point.x ts.matrix.core.point.y ∧
  ts.antagonistSubsector = classifySubsector ts.matrix.antagonist.point.x ts.matrix.antagonist.point.y ∧
  matchesTaxonomicGroup ts.matrix.core.point ts.group ∧
  (∀ g : TaxonomicGroup, matchesTaxonomicGroup ts.matrix.core.point g → g = ts.group) ∧
  matchesTaxonomicGroup ts.matrix.antagonist.point ts.antagonistGroup

/--
THÉORÈME MAÎTRE (`end_to_end_coherence`) :
Tout état initial du Moteur prédictif (`s : PredictiveEngineState`) traverse de manière
déterministe le Noyau affectif et la Matrice affective pour aboutir à un unique état
terminal cohérent dans `TaxonomicState`, découplant strictement le canal autonome `A ≥ 0`
des coordonnées `(X, Y)` tout en certifiant les invariants géométriques et antagonistes.
-/
theorem end_to_end_coherence (s : PredictiveEngineState) :
    ∃ ts : TaxonomicState,
      isCoherentTerminalState s ts ∧
      ∀ ts' : TaxonomicState, isCoherentTerminalState s ts' → ts' = ts := by
  refine ⟨runCartograffectPipeline s, ?_, ?_⟩
  · refine ⟨rfl, ?_, rfl, ?_, ?_, ?_, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_, ?_⟩
    · exact (evaluateCoreAffect s).h_valid
    · exact (evaluateMatrix (evaluateCoreAffect s) s.autonomousActivation).antagonist.h_valid
    · exact antagonistPoint_preserves_z (projectToCoreAffect s)
    · exact antagonistPoint_preserves_displacementSum (projectToCoreAffect s)
    · exact classifyTaxonomicGroup_correct (projectToCoreAffect s)
    · intro g hg
      exact taxonomy_group_exclusive (projectToCoreAffect s) g
        (classifyTaxonomicGroup (projectToCoreAffect s))
        hg (classifyTaxonomicGroup_correct (projectToCoreAffect s))
    · exact classifyTaxonomicGroup_correct (antagonistPoint (projectToCoreAffect s))
  · intro ts' hts'
    rcases ts' with ⟨⟨⟨cp, hcp⟩, ep, ctrlp, ereg, val, aAct, ⟨ap, hap⟩⟩, strat, geom, grp, sub, agrp, asub⟩
    rcases hts' with ⟨h_cp, _, h_ap, _, _, _, h_ep, h_ctrl, h_ereg, h_val, h_act, h_strat, h_geom, h_sub, h_asub, h_grp, _, h_agrp⟩
    dsimp at *
    subst h_cp h_ap h_ep h_ctrl h_ereg h_val h_act h_strat h_geom h_sub h_asub
    have h_grp_eq : grp = classifyTaxonomicGroup (projectToCoreAffect s) :=
      (matchesTaxonomicGroup_iff (projectToCoreAffect s) grp).mp h_grp
    have h_agrp_eq : agrp = classifyTaxonomicGroup (antagonistPoint (projectToCoreAffect s)) :=
      (matchesTaxonomicGroup_iff (antagonistPoint (projectToCoreAffect s)) agrp).mp h_agrp
    subst h_grp_eq h_agrp_eq
    rfl

/--
Réalisation conjointe découplée de toute position géométriquement valide `p` et de tout
niveau d'activation autonome `a : Nat` (`A ≥ 0`) dans le pipeline complet (Option 1A).
-/
theorem pipeline_decouples_point_and_activation (p : CoreAffectPoint) (a : Nat)
    (h : isValidCoreAffect p) :
    ∃ s : PredictiveEngineState,
      (runCartograffectPipeline s).matrix.core.point = p ∧
      (runCartograffectPipeline s).matrix.autonomousActivation = a := by
  have hsurj := projectToCoreAffect_surjective p h a
  exact ⟨witnessEngineForPoint p a, hsurj.1, hsurj.2⟩

end AffectiveTaxonomy

export AffectiveTaxonomy (FunctionalSubsector classifySubsector)

end Cartograffect
