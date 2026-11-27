# FORMAL_AUDIT_PACK — Noyau Formel de Référence Lean 4 (CARTOGRAFFECT v3.0)

**Branche :** `v3.0.0-dev` · **Prouveur de référence unique :** Lean 4 (`v4.35.0`, Lake `5.0.0`, sans dépendance Mathlib — `Init` uniquement) · **Option de compilation :** `warningAsError := true`

> [!IMPORTANT]
> ### Top 8 théorèmes piliers v3.0 (lecture prioritaire en 30 min pour vérificateur humain)
>
> | # | Pilier architectural v3.0 (`DECISIONS_V3.md`) | Théorème de référence | Fichier : Ligne | Axiomes (`#print axioms`) |
> |---:|:---|:---|:---|:---|
> | **P1** | **Option 1A** — Découplage strict `(X, Y, Z)` / canal autonome `A ≥ 0` et surjectivité conjointe | `projectToCoreAffect_surjective` *(+ `autonomousActivation_decoupled_from_core`)* | `Cartograffect/CoreAffect.lean:844` *(`AffectiveMatrix.lean:779`)* | `[propext, Classical.choice, Quot.sound]` |
> | **P2** | **Arbitrage 4** — Validité géométrique et conservation `L1` sous partage positif `(π_A, π_C)` | `deployCouplingWithPrecision_valid` *(+ `apportionRay_exact`)* | `Cartograffect/CoreAffect.lean:488` *(`:345`)* | `[propext, Classical.choice, Quot.sound]` |
> | **P3** | **Option 2a** — Convergence allostatique pas-à-pas stricte et court-circuit unique `2 → 0` | `dissipation_reaches_veille` *(+ `dissipation_from_ge2_never_visits_surprise`)* | `Cartograffect/CoreAffect.lean:1308` *(`:1163`)* | `[propext, Classical.choice, Quot.sound]` |
> | **P4** | **Priorité hédonique (P4) & Antagonisme** — Inversion universelle de valence par morceaux | `antagonistPoint_inverts_hedonic_polarity` *(+ `antagonistPoint_piecewise`)* | `Cartograffect/AffectiveMatrix.lean:731` *(`:569`)* | `[propext, Classical.choice, Quot.sound]` |
> | **P5** | **Taxonomie neutre Option 1A** — Unicité terminale cohérente sur les 17 sous-secteurs | `end_to_end_coherence` | `Cartograffect/AffectiveTaxonomy.lean:547` | `[propext, Classical.choice, Quot.sound]` |
> | **P6** | **Option 3b** — Instabilité axiale P2 restreinte à la Charge négative (`Peur`, `Tristesse`) | `canonicalDepthKernel_axial_instability_p2` *(+ `axial_tristesse_and_discharge_asymmetry_p2`)* | `Cartograffect/AffectiveDynamics.lean:480` *(`PredictiveCircuit.lean:983`)* | `[propext, Classical.choice, Quot.sound]` *(`[propext, Quot.sound]`)* |
> | **P7** | **Dynamique de Lyapunov (P1)** — Constance signée sur `ℤ` de la dérive attendue par goulot `L1` | `lyapunov_expected_drift_constant` *(+ `lyapunov_monotone_free`)* | `Cartograffect/PredictiveCircuit.lean:874` *(`:699`)* | `[propext, Quot.sound]` *(sans `Classical.choice`)* |
> | **P8** | **Bijection $2 \times 2$ de Rolls (`Z = 2`) & Clôture v3.0** — `Rew±/Pun±` bornés à `Z = 2` et pont global | `rolls_contingencies_z2_bound` & `full_end_to_end_v3_coherence` | `Cartograffect/OperantFactorization.lean:190` & `Cartograffect/EndToEndBridge.lean:277` | `[propext, Classical.choice, Quot.sound]` |

---

## 1. Synthèse Exécutive et Garanties d'Honnêteté Formelle

Ce dossier d'audit recense de manière **exhaustive, dédupliquée et vérifiable ligne par ligne** l'ensemble des théorèmes du cœur normatif **CARTOGRAFFECT (v3.0)** réaligné sur les quatre arbitrages irréversibles de [`DECISIONS_V3.md`](DECISIONS_V3.md) :

- **0 `sorry`**, **0 `admit`**, **0 `native_decide`**, **0 axiome *ad hoc***, **0 constante statistique externe** dans les fichiers `.lean`.
- **0 alias compté en double** : les deux alias redondants de v2.1 (`AffectiveDynamics.lateral_reachable` et `Lexicon176.all176Entries_reachable_by_engine`) ont été supprimés.
- **0 lemme vide** : tous les lemmes reposant sur la soustraction tronquée `Nat` (`informationReductionGap`, `hartley_bits_reduction_nonneg`, dérives signées) ou sur des arguments ignorés (`directProjectToAttentional` ignorant `zOperability`) ont été éliminés ou reformulés en identités signées exactes sur `ℤ`.
- **Séparation stricte du cœur normatif et des annexes exploratoires** : aucun des 8 modules du cœur normatif (`Cartograffect/`) ni `PredictiveEngineCanonical.lean` n'importe `Cartograffect/Lexicon176.lean`, et tout relèvement universel des contingences de Rolls `{Rew+, Rew−, Pun+, Pun−}` (anciennement notées de façon ambiguë `{R+, R-, P+, P-}`) sur `Z ≥ 3` a été retiré.
- **Transparence axiomatique sur `Classical.choice`** : `84` déclarations du cœur normatif sollicitent l'axiome standard `Classical.choice` de la fondation Lean 4 (principalement via le solveur d'arithmétique linéaire entière `omega` et les disjonctions décidables classiques). En conséquence, **aucun théorème dépendant de `Classical.choice` n'est qualifié de « constructif »**, et toute référence à la théorie intuitionniste des types de Martin-Löf (1984) a été retirée du manuscrit [`docs/01-Article_Cartograffect.md`](docs/01-Article_Cartograffect.md).

### Décompte exact et dédupliqué (Cœur normatif `Cartograffect/` — 8 modules)

Afin de faciliter l'audit par un vérificateur mathématique indépendant, les **169 déclarations `theorem` exportées** par les 8 modules du cœur normatif (`Cartograffect/AuditTests.lean`) sont scindées explicitement entre :
1. **148 théorèmes substantiels non triviaux** (listés individuellement en Section 2) ;
2. **21 lemmes élémentaires de définition, de cardinalité finie ou de projection de champs** (isolés à part en Section 3 afin de ne gonfler aucun décompte).

| Module du cœur normatif v3.0 | Déclarations `theorem` exportées | Lemmes élémentaires (Section 3) | **Théorèmes non triviaux dédupliqués (Section 2)** | `[aucun axiome]` (non triviaux / total) | `[propext]` (non triviaux / total) | `[propext, Quot.sound]` (non triviaux / total) | `[propext, Classical.choice, Quot.sound]` (non triviaux / total) |
|:---|---:|---:|---:|---:|---:|---:|---:|
| `Cartograffect/PredictiveEngine.lean` | 14 | 8 | **6** | 4 / 8 | 1 / 5 | 1 / 1 | 0 / 0 |
| `Cartograffect/CoreAffect.lean` | 37 | 5 | **32** | 4 / 6 | 1 / 1 | 4 / 4 | 23 / 26 |
| `Cartograffect/AffectiveMatrix.lean` | 22 | 3 | **19** | 2 / 5 | 4 / 4 | 2 / 2 | 11 / 11 |
| `Cartograffect/AffectiveTaxonomy.lean` | 16 | 0 | **16** | 0 / 0 | 0 / 0 | 4 / 4 | 12 / 12 |
| `Cartograffect/AffectiveDynamics.lean` | 13 | 0 | **13** | 0 / 0 | 0 / 0 | 0 / 0 | 13 / 13 |
| `Cartograffect/PredictiveCircuit.lean` | 53 | 5 | **48** | 12 / 16 | 8 / 9 | 17 / 17 | 11 / 11 |
| `Cartograffect/OperantFactorization.lean` | 8 | 0 | **8** | 1 / 1 | 1 / 1 | 0 / 0 | 6 / 6 |
| `Cartograffect/EndToEndBridge.lean` | 6 | 0 | **6** | 0 / 0 | 0 / 0 | 1 / 1 | 5 / 5 |
| **TOTAL CŒUR NORMATIF (`Cartograffect/`)** | **169** | **21** | **148** | **23 / 36** | **15 / 20** | **29 / 29** | **81 / 84** |

> **Extension formelle dédiée (`extensions/predictive_engine/PredictiveEngineCanonical.lean`, cible Lake `PredictiveEngineCanonical`) :** **21 déclarations `theorem` exportées** additionnelles, scindées avec la même rigueur en **16 théorèmes propres non triviaux** (Section 4.1) et **5 lemmes auxiliaires élémentaires / corollaires d'encapsulation** incluant explicitement `veille_disjoint_from_attentional_point` (Section 4.2 ; profil axiomatique total : `5` sans axiome, `2` `[propext]`, `6` `[propext, Quot.sound]`, `8` `[propext, Classical.choice, Quot.sound]`).

---

## 2. Inventaire Complet et Dédupliqué des 148 Théorèmes Non Triviaux du Cœur v3.0

### 2.1. `Cartograffect/PredictiveEngine.lean` (6 théorèmes non triviaux)

| # | Fichier : Ligne | Identifiant Lean 4 | Propriété certifiée | Axiomes (`#print axioms`) |
|---:|:---|:---|:---|:---|
| 1 | `Cartograffect/PredictiveEngine.lean:381` | `Polarity.invert_involutive` | Involutivité de l'inversion des polarités `Polarity` | `[none]` |
| 2 | `Cartograffect/PredictiveEngine.lean:385` | `Polarity.toRegime_neutral_iff` | Caractérisation exacte du régime fonctionnel neutre (`p = .zero`) | `[none]` |
| 3 | `Cartograffect/PredictiveEngine.lean:419` | `coupling_regime_partition` | Trichotomie exclusive des 9 couplages (neutralité, engagement simple, double) | `[none]` |
| 4 | `Cartograffect/PredictiveEngine.lean:458` | `inferential_loop_covers_interfaces` | Couverture surjective des 3 interfaces par les 4 opérations inférentielles | `[none]` |
| 5 | `Cartograffect/PredictiveEngine.lean:470` | `engineStep_remanence` | Stabilité par hystérésis dans la fenêtre de rémanence | `[propext]` |
| 6 | `Cartograffect/PredictiveEngine.lean:494` | `engineStep_phase_progression` | Progression séquentielle en 4 phases (`Veille → Surprise → Anticipation → Couronne`) | `[propext, Quot.sound]` |

### 2.2. `Cartograffect/CoreAffect.lean` (32 théorèmes non triviaux)

| # | Fichier : Ligne | Identifiant Lean 4 | Propriété certifiée | Axiomes (`#print axioms`) |
|---:|:---|:---|:---|:---|
| 7 | `Cartograffect/CoreAffect.lean:59` | `crownRadius_eq_formula` | Accord exact de `crownRadius` avec `2 * Z - 2` pour `Z ≥ 2` | `[propext, Quot.sound]` |
| 8 | `Cartograffect/CoreAffect.lean:297` | `apportionRay_bounds` | Bornes strictes (`≥ 1`) et conservation `ax + ay = 2d + 2` du partage proportionnel | `[propext, Classical.choice, Quot.sound]` |
| 9 | `Cartograffect/CoreAffect.lean:311` | `apportionRay_swap` | Antisymétrie d'échange `apportionRay d piC piA = swap (apportionRay d piA piC)` | `[propext, Classical.choice, Quot.sound]` |
| 10 | `Cartograffect/CoreAffect.lean:328` | `apportionRay_symm` | Équipartition diagonale `(d + 1, d + 1)` à précisions égales | `[propext, Classical.choice, Quot.sound]` |
| 11 | `Cartograffect/CoreAffect.lean:333` | `apportionRay_z2` | Unicité diagonale `(1, 1)` sur la couronne primaire `Z = 2` | `[propext, Classical.choice, Quot.sound]` |
| 12 | `Cartograffect/CoreAffect.lean:345` | `apportionRay_exact` | Idempotence exacte de `apportionRay` sur tout couple entier du losange | `[propext, Classical.choice, Quot.sound]` |
| 13 | `Cartograffect/CoreAffect.lean:423` | `deployCouplingWithPrecision_symm_eq` | Équivalence entre déploiement symétrique et `deployCouplingAtDepth` | `[propext, Classical.choice, Quot.sound]` |
| 14 | `Cartograffect/CoreAffect.lean:471` | `deployCouplingAtDepth_valid` | Validité géométrique `isValidCoreAffect` de `deployCouplingAtDepth` | `[propext, Quot.sound]` |
| 15 | `Cartograffect/CoreAffect.lean:488` | `deployCouplingWithPrecision_valid` | Validité géométrique `isValidCoreAffect` sous pondération `(π_A, π_C)` quelconque | `[propext, Classical.choice, Quot.sound]` |
| 16 | `Cartograffect/CoreAffect.lean:512` | `engine_induces_valid_core_affect` | Tout état `PredictiveEngineState` se projette sur un `CoreAffectPoint` valide | `[propext, Classical.choice, Quot.sound]` |
| 17 | `Cartograffect/CoreAffect.lean:531` | `neutral_coupling_without_suspension_yields_veille` | Neutralité globale sans suspension descendante → `Veille (0, 0, 0)` | `[none]` |
| 18 | `Cartograffect/CoreAffect.lean:547` | `neutral_or_subthreshold_with_suspension_yields_central` | Suspension descendante sous neutralité ou sous-seuil → centre `(0, 0, d + 2)` | `[none]` |
| 19 | `Cartograffect/CoreAffect.lean:561` | `descending_suspension_yields_central_operator` | Écart saillant non engagé sous suspension → opérateur central `(0, 0, d + 2)` | `[propext]` |
| 20 | `Cartograffect/CoreAffect.lean:580` | `central_z_ge2_requires_descending_suspension` | Caractérisation nécessaire de `descendingSuspension` pour atteindre `(0, 0, Z ≥ 2)` | `[propext, Classical.choice, Quot.sound]` |
| 21 | `Cartograffect/CoreAffect.lean:636` | `z2_budget_conservation` | Conservation `|X| + |Y| = 2` sur les 8 configurations actives de `Z = 2` | `[none]` |
| 22 | `Cartograffect/CoreAffect.lean:649` | `single_engaged_yields_axial_z2` | Un seul gradient engagé produit une position axiale en `Z = 2` | `[propext, Classical.choice, Quot.sound]` |
| 23 | `Cartograffect/CoreAffect.lean:662` | `dual_engaged_yields_diagonal_z2` | Deux gradients engagés produisent une position diagonale en `Z = 2` | `[propext, Classical.choice, Quot.sound]` |
| 24 | `Cartograffect/CoreAffect.lean:690` | `axial_to_diagonal_reallocation` | Réallocation `L1 = 2` d'un pôle axial vers une diagonale sous `triggerSecondaryGradient` | `[propext, Classical.choice, Quot.sound]` |
| 25 | `Cartograffect/CoreAffect.lean:709` | `deployCouplingWithPrecision_budget_conservation` | Conservation `|X| + |Y| = 2d + 2` sur toute couronne `Z = d + 2 ≥ 2` | `[propext, Classical.choice, Quot.sound]` |
| 26 | `Cartograffect/CoreAffect.lean:727` | `dual_engaged_yields_diagonal_z2_precision` | Invariance diagonale en `Z = 2` quels que soient `(π_A, π_C)` | `[propext, Classical.choice, Quot.sound]` |
| 27 | `Cartograffect/CoreAffect.lean:759` | `symmetric_precision_never_lateral` | Impossibilité géométrique des positions latérales sous précisions symétriques | `[propext, Classical.choice, Quot.sound]` |
| 28 | `Cartograffect/CoreAffect.lean:771` | `projectToCoreAffect_independent_of_activation` | Indépendance stricte de `(X, Y, Z)` vis-à-vis du canal autonome `A ≥ 0` (Option 1A) | `[none]` |
| 29 | `Cartograffect/CoreAffect.lean:844` | `projectToCoreAffect_surjective` | Surjectivité conjointe sur tout `p` valide et tout niveau autonome `a : Nat` (Option 1A) | `[propext, Classical.choice, Quot.sound]` |
| 30 | `Cartograffect/CoreAffect.lean:999` | `engineStep_canonical_trajectory` | Trajectoire canonique complète `(0,0,0) → (0,0,1) → (0,0,2) → (0,2,2)` | `[propext, Quot.sound]` |
| 31 | `Cartograffect/CoreAffect.lean:1058` | `engineStep_surprise_to_crown` | Déploiement sur couronne en 2 pas depuis tout état projeté en `Surprise (0,0,1)` | `[propext, Classical.choice, Quot.sound]` |
| 32 | `Cartograffect/CoreAffect.lean:1138` | `dissipationStep_valid` | Préservation de `isValidCoreAffect` par l'opérateur `dissipationStep` | `[propext, Classical.choice, Quot.sound]` |
| 33 | `Cartograffect/CoreAffect.lean:1163` | `dissipation_from_ge2_never_visits_surprise` | Exclusion stricte de `Surprise (0,0,1)` en redescente depuis `Z ≥ 2` (Option 2a) | `[propext, Classical.choice, Quot.sound]` |
| 34 | `Cartograffect/CoreAffect.lean:1200` | `dissipationStep_fixed_iff` | Unicité du point fixe global `Veille (0, 0, 0)` de `dissipationStep` | `[propext, Classical.choice, Quot.sound]` |
| 35 | `Cartograffect/CoreAffect.lean:1244` | `dissipation_strictly_decreases` | Décroissance stricte du potentiel `dissipationPotential` hors `Veille` | `[propext, Classical.choice, Quot.sound]` |
| 36 | `Cartograffect/CoreAffect.lean:1308` | `dissipation_reaches_veille` | Convergence universelle en au plus `Z + 1` pas vers `Veille (0, 0, 0)` | `[propext, Classical.choice, Quot.sound]` |
| 37 | `Cartograffect/CoreAffect.lean:1346` | `remanence_preserves_state` | Maintien de la coordonnée par `allostaticStep` dans la fenêtre de rémanence | `[propext, Classical.choice, Quot.sound]` |
| 38 | `Cartograffect/CoreAffect.lean:1367` | `cooperative_step_leaves_crown` | Sortie nécessaire du losange `L1` sous co-progression simultanée `(x+1, y+1, z)` | `[propext, Quot.sound]` |

### 2.3. `Cartograffect/AffectiveMatrix.lean` (19 théorèmes non triviaux)

| # | Fichier : Ligne | Identifiant Lean 4 | Propriété certifiée | Axiomes (`#print axioms`) |
|---:|:---|:---|:---|:---|
| 39 | `Cartograffect/AffectiveMatrix.lean:101` | `HedonicPolarity.invert_involutive` | Involutivité de l'inversion hédonique | `[none]` |
| 40 | `Cartograffect/AffectiveMatrix.lean:107` | `x_positive_determines_positive_valence` | Priorité lexicographique : `X > 0` impose une valence positive pour tout `Y` (P4) | `[propext]` |
| 41 | `Cartograffect/AffectiveMatrix.lean:113` | `x_negative_determines_negative_valence` | Priorité lexicographique : `X < 0` impose une valence négative pour tout `Y` (P4) | `[propext]` |
| 42 | `Cartograffect/AffectiveMatrix.lean:223` | `antagonistPoint_preserves_displacementSum` | Conservation de la norme `|X| + |Y|` par `antagonistPoint` | `[propext]` |
| 43 | `Cartograffect/AffectiveMatrix.lean:239` | `antagonistPoint_preserves_validity` | Clôture de `isValidCoreAffect` sous `antagonistPoint` | `[propext, Classical.choice, Quot.sound]` |
| 44 | `Cartograffect/AffectiveMatrix.lean:260` | `antagonistPoint_involutive` | Involutivité universelle `antagonistPoint (antagonistPoint p) = p` | `[propext, Classical.choice, Quot.sound]` |
| 45 | `Cartograffect/AffectiveMatrix.lean:310` | `antagonistPoint_fixed_iff_central` | Caractérisation des points fixes de `antagonistPoint` (`x = 0 ∧ y = 0`) | `[propext, Classical.choice, Quot.sound]` |
| 46 | `Cartograffect/AffectiveMatrix.lean:334` | `contralateral_swaps_amplitudes` | Échange exact des amplitudes `(|X|, |Y|) ↔ (|Y|, |X|)` sur les positions latérales | `[none]` |
| 47 | `Cartograffect/AffectiveMatrix.lean:371` | `antagonist_commutes_with_invert` | Commutation entre `antagonistPoint` et `EngineCoupling.invert` (précisions égales) | `[propext]` |
| 48 | `Cartograffect/AffectiveMatrix.lean:488` | `antagonist_commutes_with_invert_precision` | Commutation entre `antagonistPoint` et l'inversion couplée à l'échange `(π_C, π_A)` | `[propext, Classical.choice, Quot.sound]` |
| 49 | `Cartograffect/AffectiveMatrix.lean:540` | `antagonistPoint_off_axis` | Branche algébrique hors-axes `XY ≠ 0` : `(-sgn(x)|y|, -sgn(y)|x|, z)` | `[propext, Classical.choice, Quot.sound]` |
| 50 | `Cartograffect/AffectiveMatrix.lean:569` | `antagonistPoint_piecewise` | Décomposition en 2 cas disjoints (axial vs non axial) | `[propext, Classical.choice, Quot.sound]` |
| 51 | `Cartograffect/AffectiveMatrix.lean:593` | `antagonist_preserves_validity_in` | Préservation de validité dans les régimes compétitif et coopératif | `[propext, Classical.choice, Quot.sound]` |
| 52 | `Cartograffect/AffectiveMatrix.lean:628` | `transferUnitXtoY_preserves_sum` | Conservation de `|X| + |Y|` par transfert élémentaire `X → Y` dans le quadrant | `[propext, Quot.sound]` |
| 53 | `Cartograffect/AffectiveMatrix.lean:650` | `transferUnitYtoX_preserves_sum` | Conservation de `|X| + |Y|` par transfert élémentaire `Y → X` dans le quadrant | `[propext, Quot.sound]` |
| 54 | `Cartograffect/AffectiveMatrix.lean:731` | `antagonistPoint_inverts_hedonic_polarity` | Inversion universelle de la polarité hédonique par `antagonistPoint` sur `ℤ × ℤ × ℕ` | `[propext, Classical.choice, Quot.sound]` |
| 55 | `Cartograffect/AffectiveMatrix.lean:779` | `autonomousActivation_decoupled_from_core` | Orthogonalité du canal autonome `A ≥ 0` vis-à-vis du Noyau et de la valence (Option 1A) | `[propext, Classical.choice, Quot.sound]` |
| 56 | `Cartograffect/AffectiveMatrix.lean:796` | `evaluateMatrix_core_antagonist_independent` | Invariance de `core`, `antagonist` et `autonomousActivation` vis-à-vis du mapping | `[propext, Classical.choice, Quot.sound]` |
| 57 | `Cartograffect/AffectiveMatrix.lean:808` | `mapping_independent_antagonist_invariants` | Invariants géométriques d'antagonisme indépendants des correspondances lexicales | `[propext, Classical.choice, Quot.sound]` |

### 2.4. `Cartograffect/AffectiveTaxonomy.lean` (16 théorèmes non triviaux)

| # | Fichier : Ligne | Identifiant Lean 4 | Propriété certifiée | Axiomes (`#print axioms`) |
|---:|:---|:---|:---|:---|
| 58 | `Cartograffect/AffectiveTaxonomy.lean:215` | `canonical_crown_counts_certified` | Effectifs de la discrétisation canonique `Z ∈ {0, 1, 2}` (11 états) et loi `8(d + 1)` | `[propext, Quot.sound]` |
| 59 | `Cartograffect/AffectiveTaxonomy.lean:234` | `classifyTaxonomicGroup_correct` | Correction de `classifyTaxonomicGroup` vis-à-vis des 9 groupes neutres (Option 1A) | `[propext, Classical.choice, Quot.sound]` |
| 60 | `Cartograffect/AffectiveTaxonomy.lean:251` | `taxonomy_group_exhaustive` | Exhaustivité des 9 groupes fonctionnels d'orientation sur `CoreAffectPoint` | `[propext, Classical.choice, Quot.sound]` |
| 61 | `Cartograffect/AffectiveTaxonomy.lean:259` | `taxonomy_group_exclusive` | Disjonction deux à deux des 9 groupes fonctionnels d'orientation | `[propext, Quot.sound]` |
| 62 | `Cartograffect/AffectiveTaxonomy.lean:267` | `matchesTaxonomicGroup_iff` | Caractérisation bijective de la partition en 9 groupes fonctionnels | `[propext, Classical.choice, Quot.sound]` |
| 63 | `Cartograffect/AffectiveTaxonomy.lean:280` | `dominantSector_iff_taxonomicGroup` | Équivalence entre `OrientationSector` et les 4 groupes sectoriels neutres | `[propext, Classical.choice, Quot.sound]` |
| 64 | `Cartograffect/AffectiveTaxonomy.lean:307` | `contralateral_group_bindings` | Quatre liaisons controlatérales exactes entre secteurs perpendiculaires | `[propext, Classical.choice, Quot.sound]` |
| 65 | `Cartograffect/AffectiveTaxonomy.lean:361` | `classifySubsector_correct` | Correction de `classifySubsector` sur les 17 sous-secteurs fonctionnels (Option 1A) | `[propext, Classical.choice, Quot.sound]` |
| 66 | `Cartograffect/AffectiveTaxonomy.lean:414` | `subsector_exclusive` | Exclusivité mutuelle des 17 sous-secteurs sur `ℤ × ℤ` | `[propext, Quot.sound]` |
| 67 | `Cartograffect/AffectiveTaxonomy.lean:422` | `matchesSubsector_iff` | Caractérisation bijective des 17 sous-secteurs fonctionnels | `[propext, Classical.choice, Quot.sound]` |
| 68 | `Cartograffect/AffectiveTaxonomy.lean:432` | `matchesSubsector_toTaxonomicGroup` | Inclusion de chaque sous-secteur dans son macro-groupe d'orientation | `[propext, Classical.choice, Quot.sound]` |
| 69 | `Cartograffect/AffectiveTaxonomy.lean:438` | `classifySubsector_refines_group` | Raffinement exact de `classifyTaxonomicGroup` par `classifySubsector` | `[propext, Classical.choice, Quot.sound]` |
| 70 | `Cartograffect/AffectiveTaxonomy.lean:444` | `matchesSubsector_toHedonicPolarity` | Détermination exacte de la polarité hédonique par le prédicat `matchesSubsector` | `[propext, Quot.sound]` |
| 71 | `Cartograffect/AffectiveTaxonomy.lean:460` | `classifySubsector_determines_valence` | Consistance hédonique globale des 17 sous-secteurs avec `computeHedonicPolarity` | `[propext, Classical.choice, Quot.sound]` |
| 72 | `Cartograffect/AffectiveTaxonomy.lean:547` | `end_to_end_coherence` | Existence et unicité du `TaxonomicState` terminal cohérent à 18 clauses (Option 1A) | `[propext, Classical.choice, Quot.sound]` |
| 73 | `Cartograffect/AffectiveTaxonomy.lean:579` | `pipeline_decouples_point_and_activation` | Réalisation conjointe découplée de tout `p` valide et de tout canal `a : Nat` | `[propext, Classical.choice, Quot.sound]` |

### 2.5. `Cartograffect/AffectiveDynamics.lean` (13 théorèmes non triviaux)

| # | Fichier : Ligne | Identifiant Lean 4 | Propriété certifiée | Axiomes (`#print axioms`) |
|---:|:---|:---|:---|:---|
| 74 | `Cartograffect/AffectiveDynamics.lean:49` | `isValidCoreAffectB_iff` | Équivalence entre le décideur booléen `isValidCoreAffectB` et `isValidCoreAffect` | `[propext, Classical.choice, Quot.sound]` |
| 75 | `Cartograffect/AffectiveDynamics.lean:219` | `canonicalDepthKernel_reaches_crown` | Existence d'un antécédent valide `Z - 1 → Z` pour toute position de couronne `Z ≥ 3` | `[propext, Classical.choice, Quot.sound]` |
| 76 | `Cartograffect/AffectiveDynamics.lean:348` | `canonicalDepthKernel_reaches_lateral` | Atteignabilité en un pas de toute position latérale valide par `canonicalDepthKernel` | `[propext, Classical.choice, Quot.sound]` |
| 77 | `Cartograffect/AffectiveDynamics.lean:397` | `canonicalDepthKernel_crown_from_surprise` | Atteignabilité par cascade pas-à-pas `1 → 2 → … → Z` depuis `Surprise (0,0,1)` | `[propext, Classical.choice, Quot.sound]` |
| 78 | `Cartograffect/AffectiveDynamics.lean:445` | `lateral_reachable_from_surprise` | Atteignabilité pas-à-pas de toutes les positions latérales depuis `Surprise (0,0,1)` | `[propext, Classical.choice, Quot.sound]` |
| 79 | `Cartograffect/AffectiveDynamics.lean:464` | `canonicalDepthKernel_colere_bifurcates` | Bifurcation canonique depuis `Colère (-1, 1, 2)` en `Z = 3` (diagonale + 2 latérales) | `[propext, Classical.choice, Quot.sound]` |
| 80 | `Cartograffect/AffectiveDynamics.lean:480` | `canonicalDepthKernel_axial_instability_p2` | Instabilité axiale P2 restreinte aux 2 pôles en Charge (`Peur`, `Tristesse`) & brisure 3b | `[propext, Classical.choice, Quot.sound]` |
| 81 | `Cartograffect/AffectiveDynamics.lean:550` | `mem_stratumPoints_of_valid` | Complétude finie de `stratumPoints z` sur tous les points valides de la strate `z` | `[propext, Classical.choice, Quot.sound]` |
| 82 | `Cartograffect/AffectiveDynamics.lean:588` | `DepthTransitionKernel.outgoingWeight_pos_of_witness` | Positivité stricte de `outgoingWeight` dès l'existence d'une transition non nulle | `[propext, Classical.choice, Quot.sound]` |
| 83 | `Cartograffect/AffectiveDynamics.lean:604` | `canonicalDepthKernel_outgoingWeight_pos` | Absence de puits mort : `outgoingWeight p > 0` pour tout état valide `p` | `[propext, Classical.choice, Quot.sound]` |
| 84 | `Cartograffect/AffectiveDynamics.lean:709` | `classifyTaxonomicGroup_unique_maximizer` | Unicité stricte du maximum de `attractorMembership` sur `classifyTaxonomicGroup` | `[propext, Classical.choice, Quot.sound]` |
| 85 | `Cartograffect/AffectiveDynamics.lean:720` | `classifyTaxonomicGroup_maximizes_membership` | Majoration globale de `attractorMembership` par le groupe fonctionnel assigné | `[propext, Classical.choice, Quot.sound]` |
| 86 | `Cartograffect/AffectiveDynamics.lean:730` | `lateral_has_overlapping_attractors` | Chevauchement strict d'au moins 2 attracteurs de poids `> 0` sur toute position latérale | `[propext, Classical.choice, Quot.sound]` |

### 2.6. `Cartograffect/PredictiveCircuit.lean` (48 théorèmes non triviaux)

| # | Fichier : Ligne | Identifiant Lean 4 | Propriété certifiée | Axiomes (`#print axioms`) |
|---:|:---|:---|:---|:---|
| 87 | `Cartograffect/PredictiveCircuit.lean:111` | `circuit_covers_interfaces_both_sides` | Bijection entre les 6 opérations de circuit et `EngineInterface × InterfaceSide` | `[none]` |
| 88 | `Cartograffect/PredictiveCircuit.lean:126` | `circuit_refines_inferential_ops` | Surjection des 6 opérations de circuit sur `InferentialOperation` | `[none]` |
| 89 | `Cartograffect/PredictiveCircuit.lean:140` | `unique_agent_perceptible_crossing` | Unicité du Croisement I perceptible par l'Agent | `[propext]` |
| 90 | `Cartograffect/PredictiveCircuit.lean:222` | `phiL1_valid` | Validité proto-spatiale `isValidProtoSpatial` de `phiL1` | `[none]` |
| 91 | `Cartograffect/PredictiveCircuit.lean:230` | `phiL1_l1Norm_active` | Conservation `|X_0| + |Y_0| = 2` au Croisement I hors `Veille` | `[none]` |
| 92 | `Cartograffect/PredictiveCircuit.lean:239` | `phiL1_left_inv` | Inverse à gauche `phiL1Inv (phiL1 c) = c` | `[none]` |
| 93 | `Cartograffect/PredictiveCircuit.lean:245` | `phiL1_right_inv` | Inverse à droite `phiL1 (phiL1Inv n) = n` sur tout nœud proto-spatial valide | `[propext, Quot.sound]` |
| 94 | `Cartograffect/PredictiveCircuit.lean:260` | `phiL1_agrees_with_deployZ2` | Coïncidence de `phiL1` avec les coordonnées déployées en `Z = 2` | `[none]` |
| 95 | `Cartograffect/PredictiveCircuit.lean:272` | `routeToSubjective_injective` | Injectivité des 9 canaux de retour `A/C` vers l'Interface Subjective | `[none]` |
| 96 | `Cartograffect/PredictiveCircuit.lean:282` | `routeToPerceptive_injective` | Injectivité des 9 canaux de retour `C/A` vers l'Interface Perceptive | `[none]` |
| 97 | `Cartograffect/PredictiveCircuit.lean:313` | `projectPerceptible_valid` | Validité géométrique `isValidCoreAffect` de `projectPerceptible` | `[propext, Classical.choice, Quot.sound]` |
| 98 | `Cartograffect/PredictiveCircuit.lean:332` | `projectPerceptible_z2_matches_phiL1` | Coïncidence de `projectPerceptible` en `Z = 2` avec `phiL1` | `[propext, Classical.choice, Quot.sound]` |
| 99 | `Cartograffect/PredictiveCircuit.lean:352` | `projectPerceptible_neutral_elevates_to_central` | Élévation de `(A0, C0)` sous suspension active vers `(0, 0, Z ≥ 2)` | `[propext]` |
| 100 | `Cartograffect/PredictiveCircuit.lean:399` | `attentional_bottleneck_sum_active` | Conservation du goulot attentionnel `2w_X + 2w_Y = 2` hors `Veille` | `[none]` |
| 101 | `Cartograffect/PredictiveCircuit.lean:409` | `lyapunovPotential_zero_iff` | Annulation de `lyapunovPotential` exclusivement en `Veille (A0, C0)` | `[none]` |
| 102 | `Cartograffect/PredictiveCircuit.lean:416` | `lyapunovPotential_le_four` | Borne supérieure `lyapunovPotential c ≤ 4` | `[none]` |
| 103 | `Cartograffect/PredictiveCircuit.lean:423` | `lyapunovPotential_max_iff` | Maximum `V = 4` atteint exclusivement en Double Charge `(A-, C-)` | `[none]` |
| 104 | `Cartograffect/PredictiveCircuit.lean:646` | `circuitRowSum_exact` | Normalisation stochastique entière exacte `circuitRowSum = 4 * scale^6` | `[propext, Quot.sound]` |
| 105 | `Cartograffect/PredictiveCircuit.lean:668` | `veille_absorbing_free` | Absorption stricte de `Veille (A0, C0)` à bruit exogène nul (`epsilon = 0`) | `[propext, Quot.sound]` |
| 106 | `Cartograffect/PredictiveCircuit.lean:699` | `lyapunov_monotone_free` | Décroissance large de Lyapunov sur toute transition libre (`epsilon = chi = 0`) | `[propext, Quot.sound]` |
| 107 | `Cartograffect/PredictiveCircuit.lean:724` | `lyapunov_strict_descent_witness` | Existence d'une transition strictement décroissante depuis tout état actif libre | `[propext]` |
| 108 | `Cartograffect/PredictiveCircuit.lean:874` | `lyapunov_expected_drift_constant` | Dérive signée constante sur `ℤ` (`4 * scale^5 * r`) par goulot `L1` | `[propext, Quot.sound]` |
| 109 | `Cartograffect/PredictiveCircuit.lean:921` | `lyapunov_drift_charge_with_passive_extinction` | Dérive signée sur `ℤ` (`4 * scale^5 * (rho + 2 * deltaA)`) sous extinction passive | `[propext, Quot.sound]` |
| 110 | `Cartograffect/PredictiveCircuit.lean:940` | `p1_without_p2_eps_independent` | Indépendance logique de P1 vis-à-vis de la Charge complémentaire lorsque `chi = 0` | `[propext]` |
| 111 | `Cartograffect/PredictiveCircuit.lean:952` | `axial_peur_bifurcates_p2` | Bifurcation P2 depuis `Peur (A-, C0)` vers `Colère` et `Dégoût` sous `chi > 0` | `[propext, Quot.sound]` |
| 112 | `Cartograffect/PredictiveCircuit.lean:983` | `axial_tristesse_and_discharge_asymmetry_p2` | Bifurcation P2 depuis `Tristesse (A0, C-)` & immunité diagonale de `Courage`/`Joie` (3b) | `[propext, Quot.sound]` |
| 113 | `Cartograffect/PredictiveCircuit.lean:1018` | `veille_self_loop_ergodic` | Apériodicité (`W(Veille → Veille) > 0`) pour `epsilon < scale` | `[propext, Quot.sound]` |
| 114 | `Cartograffect/PredictiveCircuit.lean:1031` | `veille_reaches_all_one_step` | Atteignabilité en 1 pas des 9 états depuis `Veille` sous `0 < epsilon < scale` | `[propext, Quot.sound]` |
| 115 | `Cartograffect/PredictiveCircuit.lean:1064` | `all_reach_veille_two_steps` | Retour en au plus 2 pas vers `Veille` depuis les 9 états en régime flexible | `[propext, Quot.sound]` |
| 116 | `Cartograffect/PredictiveCircuit.lean:1138` | `veille_unreachable_when_eps_max` | Inaccessibilité de `Veille` sous saturation `epsilon = scale` et `delta = 0` | `[propext]` |
| 117 | `Cartograffect/PredictiveCircuit.lean:1163` | `epistemic_rigidity_traps_charge_slice` | Piégeage absorbant de la tranche `A-` sous rigidité épistémique (`rho = deltaA = 0`) | `[propext]` |
| 118 | `Cartograffect/PredictiveCircuit.lean:1180` | `pragmatic_helplessness_traps_charge_slice` | Piégeage absorbant de la tranche `C-` sous impuissance pragmatique (`kappa = deltaC = 0`) | `[propext]` |
| 119 | `Cartograffect/PredictiveCircuit.lean:1198` | `perseveration_traps_discharge_free` | Piégeage de la Décharge à bruit nul sous persévération (`gammaA = gammaC = 0`) | `[propext, Quot.sound]` |
| 120 | `Cartograffect/PredictiveCircuit.lean:1348` | `circularCycle_emits_valid_core_affect` | Validité géométrique émise par `circularCycle` au Croisement I | `[propext, Classical.choice, Quot.sound]` |
| 121 | `Cartograffect/PredictiveCircuit.lean:1353` | `circularCycle_veille_fixed_point` | Point fixe basal exact de la boucle fermée `circularCycle` | `[propext, Classical.choice, Quot.sound]` |
| 122 | `Cartograffect/PredictiveCircuit.lean:1389` | `circularCycle_reduces_total_discrepancy` | Décroissance stricte de l'écart cumulé en régime révisable et contrôlable | `[propext, Classical.choice, Quot.sound]` |
| 123 | `Cartograffect/PredictiveCircuit.lean:1535` | `active_resolution_beats_passive_extinction` | Décharge allostatique supérieure de la résolution active face à l'extinction passive | `[propext, Quot.sound]` |
| 124 | `Cartograffect/PredictiveCircuit.lean:1555` | `charge_accumulator_bounded` | Invariance de la borne `R_{t+1} ≤ M^2 / (M - lam)` de l'accumulateur `R_t` | `[propext, Classical.choice, Quot.sound]` |
| 125 | `Cartograffect/PredictiveCircuit.lean:1611` | `nextStratumR5_le_zMax` | Invariance de la borne `nextStratumR5 ≤ zMax` (`zMax = 5` par défaut) | `[propext, Quot.sound]` |
| 126 | `Cartograffect/PredictiveCircuit.lean:1629` | `nextStratumR5_short_circuits_z2_to_veille` | Court-circuit descendant direct `2 → 0` sous le seuil de résorption (Option 2a) | `[propext, Quot.sound]` |
| 127 | `Cartograffect/PredictiveCircuit.lean:1641` | `nextStratumR5_from_ge2_never_visits_surprise` | Impossibilité de visiter `Surprise (Z = 1)` depuis `Z ≥ 2` via `nextStratumR5` | `[propext, Quot.sound]` |
| 128 | `Cartograffect/PredictiveCircuit.lean:1678` | `symmetricSigmoid_sum` | Antisymétrie normalisée `σ(u) + σ(-u) = 2 * halfScale` | `[propext, Quot.sound]` |
| 129 | `Cartograffect/PredictiveCircuit.lean:1690` | `symmetricSigmoid_pos` | Positivité stricte `σ(u) > 0` de la sigmoïde entière | `[propext, Classical.choice, Quot.sound]` |
| 130 | `Cartograffect/PredictiveCircuit.lean:1701` | `symmetricSigmoid_neg` | Borne stricte `σ(u) < 2 * halfScale` de la sigmoïde entière | `[propext, Classical.choice, Quot.sound]` |
| 131 | `Cartograffect/PredictiveCircuit.lean:1747` | `precisionShare_double_charge_cancels_alpha` | Annulation exacte du biais `alpha` en Double Charge `(A-, C-)` | `[propext]` |
| 132 | `Cartograffect/PredictiveCircuit.lean:1755` | `projectUnifiedState_valid` | Validité `isValidCoreAffect` de tout état projeté par la loi unifiée | `[propext, Classical.choice, Quot.sound]` |
| 133 | `Cartograffect/PredictiveCircuit.lean:1761` | `projectUnifiedState_crown_budget` | Conservation du rayon de couronne `2Z - 2` par `projectUnifiedState` | `[propext, Classical.choice, Quot.sound]` |
| 134 | `Cartograffect/PredictiveCircuit.lean:1791` | `projectUnifiedState_reaches_lateral_agentic_confront` | Témoin d'atteinte de la coordonnée latérale d'affrontement agentique `(-1, 3, 3)` | `[propext, Classical.choice, Quot.sound]` |

### 2.7. `Cartograffect/OperantFactorization.lean` (8 théorèmes non triviaux)

| # | Fichier : Ligne | Identifiant Lean 4 | Propriété certifiée | Axiomes (`#print axioms`) |
|---:|:---|:---|:---|:---|
| 135 | `Cartograffect/OperantFactorization.lean:46` | `manhattanDistXY_origin` | Identité entre `manhattanDistXY` à l'origine de strate et `displacementSum` | `[propext]` |
| 136 | `Cartograffect/OperantFactorization.lean:159` | `rolls_factorization_law` | Factorisation classe de stimulus (`Y`: `reward`/`punishment`) × opérateur (`X*Y`: `delivery`/`omission`) × issue (`X`) sur `Z = 2` | `[propext, Classical.choice, Quot.sound]` |
| 137 | `Cartograffect/OperantFactorization.lean:190` | `rolls_contingencies_z2_bound` | Ancrage exact `{Rew+, Rew−, Pun+, Pun−}` en `Z = 2`, reconstruction `fromPair` et annulation (`none`) sur `Z ≠ 2` | `[propext, Classical.choice, Quot.sound]` |
| 138 | `Cartograffect/OperantFactorization.lean:280` | `energyRegime_matches_rolls_contingency` | Correspondance exacte entre `RollsContingency` et `EnergyRegime` (Option 1A) | `[propext, Classical.choice, Quot.sound]` |
| 139 | `Cartograffect/OperantFactorization.lean:308` | `antagonist_rolls_symmetry_z2` | Symétrie d'antagonisme exacte `Rew+ ↔ Pun+` (`Désir ↔ Dégoût`) et `Rew− ↔ Pun−` (`Colère ↔ Calme`) | `[propext, Classical.choice, Quot.sound]` |
| 140 | `Cartograffect/OperantFactorization.lean:344` | `axial_poles_bridge_rolls_pairs` | Équidistance `L1 = 2` (adjacents) vs `L1 = 4` (opposés) depuis les 4 pôles axiaux `Z = 2` | `[none]` |
| 141 | `Cartograffect/OperantFactorization.lean:364` | `axial_poles_pre_contingency` | Caractère pré-contingent (`none`) des 4 orientations axiales de `Z = 2` | `[propext, Classical.choice, Quot.sound]` |
| 142 | `Cartograffect/OperantFactorization.lean:372` | `z2_rolls_bijection_2x2` | Bijection exacte $2 \times 2$ entre les 4 diagonales de `Z = 2` et `{Rew+, Rew−, Pun+, Pun−}` (`RollsContingency`) | `[propext, Classical.choice, Quot.sound]` |

### 2.8. `Cartograffect/EndToEndBridge.lean` (6 théorèmes non triviaux)

| # | Fichier : Ligne | Identifiant Lean 4 | Propriété certifiée | Axiomes (`#print axioms`) |
|---:|:---|:---|:---|:---|
| 143 | `Cartograffect/EndToEndBridge.lean:84` | `circuit_coupling_z2_contingency_bridge` | Pont Circuit ↔ `Z = 2` et annulation identique (`none`) sur toute strate `Z ≠ 2` | `[propext, Classical.choice, Quot.sound]` |
| 144 | `Cartograffect/EndToEndBridge.lean:126` | `triggerSecondaryGradient_enters_z2_contingency` | Transition pré-contingente → `RollsContingency` caractérisant `reward` (`Y > 0`), `delivery` (`X*Y > 0`) et `Calme` (`Pun−`) | `[propext, Classical.choice, Quot.sound]` |
| 145 | `Cartograffect/EndToEndBridge.lean:151` | `p2_negative_charge_enters_z2_contingencies` | Bifurcation markovienne P2 depuis `Peur` (`Rew−`/`Pun+`) et `Tristesse` (`Pun−`/`Pun+`) & immunité de `Courage`/`Joie` (3b) | `[propext, Quot.sound]` |
| 146 | `Cartograffect/EndToEndBridge.lean:180` | `vertical_operators_obey_stepwise_2a` | Conformité stricte de `nextStratumR5` et `dissipationStep` à `isValidVerticalStep2a` (2a) | `[propext, Classical.choice, Quot.sound]` |
| 147 | `Cartograffect/EndToEndBridge.lean:224` | `unified_and_circular_to_taxonomy_coherence` | Cohérence de la loi unifiée et du circuit fermé vers la Taxonomie neutre avec canal `A ≥ 0` | `[propext, Classical.choice, Quot.sound]` |
| 148 | `Cartograffect/EndToEndBridge.lean:277` | `full_end_to_end_v3_coherence` | Théorème de synthèse v3.0 (unicité terminale, canal `A ≥ 0`, antagonisme, descente 2a, borne `Z = 2`) | `[propext, Classical.choice, Quot.sound]` |

---

## 3. Lemmes Élémentaires Isolés du Décompte Principal (21 déclarations)

Ces 21 déclarations `theorem` exportées (également auditées par `#print axioms` dans `Cartograffect/AuditTests.lean`) consistent en dépliages d'une branche, témoins ponctuels par `rfl` ou cardinalités de listes constantes, et sont donc comptabilisées à part des 148 théorèmes non triviaux ci-dessus :

| # | Fichier : Ligne | Identifiant Lean 4 | Nature | Axiomes (`#print axioms`) |
|---:|:---|:---|:---|:---|
| E1 | `Cartograffect/PredictiveEngine.lean:346` | `engineStep_of_salient_neutral` | Dépliage d'une branche de `engineStep` | `[propext]` |
| E2 | `Cartograffect/PredictiveEngine.lean:355` | `engineStep_of_salient_nonneutral_unsuspended` | Dépliage d'une branche de `engineStep` | `[propext]` |
| E3 | `Cartograffect/PredictiveEngine.lean:366` | `engineStep_of_salient_nonneutral_suspended_unengaged` | Dépliage d'une branche de `engineStep` | `[propext]` |
| E4 | `Cartograffect/PredictiveEngine.lean:393` | `single_neutral_not_global_neutral` | Témoin concret `⟨.zero, .pos⟩` (`rfl`) | `[none]` |
| E5 | `Cartograffect/PredictiveEngine.lean:401` | `allCouplings_card` | Longueur de liste constante (`9`) | `[none]` |
| E6 | `Cartograffect/PredictiveEngine.lean:407` | `mem_allCouplings` | Énumération finie des 9 couplages | `[propext]` |
| E7 | `Cartograffect/PredictiveEngine.lean:432` | `feedbackUpdate_couples_gradients` | Mise à jour de champs (`rfl`) | `[none]` |
| E8 | `Cartograffect/PredictiveEngine.lean:444` | `feedbackUpdateWeighted_couples_precision` | Mise à jour de champs (`rfl`) | `[none]` |
| E9 | `Cartograffect/CoreAffect.lean:227` | `natAbs_neg_ofNat` | Auxiliaire arithmétique sur `Int.natAbs` | `[none]` |
| E10 | `Cartograffect/CoreAffect.lean:231` | `natAbs_pos_ofNat` | Auxiliaire définitionnel `rfl` sur `Int.natAbs` | `[none]` |
| E11 | `Cartograffect/CoreAffect.lean:1156` | `anticipation_short_circuits_to_veille` | Évaluation ponctuelle sur `⟨0, 0, 2⟩` | `[propext, Classical.choice, Quot.sound]` |
| E12 | `Cartograffect/CoreAffect.lean:1192` | `pointDeVeille_is_fixed_point` | Évaluation ponctuelle sur `⟨0, 0, 0⟩` | `[propext, Classical.choice, Quot.sound]` |
| E13 | `Cartograffect/CoreAffect.lean:1266` | `dissipationPotential_short_circuit_jump` | Saut signé sur `ℤ` en `⟨0, 0, 2⟩` (`rfl`) | `[propext, Classical.choice, Quot.sound]` |
| E14 | `Cartograffect/AffectiveMatrix.lean:172` | `PrimaryCrownPrototype.valid_on_crown` | Vérification finie des 8 prototypes `Z = 2` | `[none]` |
| E15 | `Cartograffect/AffectiveMatrix.lean:212` | `antagonistPoint_preserves_z` | Conservation immédiate du champ `.z` | `[none]` |
| E16 | `Cartograffect/AffectiveMatrix.lean:355` | `canonical_antagonist_examples` | Exemples ponctuels d'antagonistes | `[none]` |
| E17 | `Cartograffect/PredictiveCircuit.lean:104` | `allCircuitOperations_card` | Longueur de liste constante (`6`) | `[none]` |
| E18 | `Cartograffect/PredictiveCircuit.lean:107` | `mem_allCircuitOperations` | Énumération finie des 6 opérations | `[propext]` |
| E19 | `Cartograffect/PredictiveCircuit.lean:135` | `circuit_preserves_carrier` | Projection finie à 6 cas (`rfl`) | `[none]` |
| E20 | `Cartograffect/PredictiveCircuit.lean:268` | `crossingII_is_transpose_of_crossingI` | Échange de composantes de couple (`rfl`) | `[none]` |
| E21 | `Cartograffect/PredictiveCircuit.lean:1525` | `passive_extinction_zero_relief` | Évaluation ponctuelle `activeResolutionCount = 0` | `[none]` |

---

## 4. Extension `extensions/predictive_engine/PredictiveEngineCanonical.lean` (16 théorèmes non triviaux + 5 lemmes auxiliaires élémentaires)

### 4.1. Théorèmes propres non triviaux de l'extension (16 déclarations)

| # | Fichier : Ligne | Identifiant Lean 4 | Propriété certifiée | Axiomes (`#print axioms`) |
|---:|:---|:---|:---|:---|
| C1 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:78` | `assembleIsolatedResponses_iff` | Caractérisation bijective du couplage typé des boucles `expectationLoop` / `controlLoop` | `[none]` |
| C2 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:149` | `attentional_domain_realizations_valid_and_card` | Adéquation `isValidCoreAffect` et cardinalité exacte (`1` ou `2Z - 3`) des réalisations de `{s_X, s_Y, Z}` | `[propext, Classical.choice, Quot.sound]` |
| C3 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:299` | `stepAttentionalDomain2a_sound_and_no_jump` | Conformité stricte à `isValidVerticalStep2a` et exclusion de tout saut direct `|ΔZ| ≥ 2` vers `Z ≥ 1` | `[propext, Classical.choice, Quot.sound]` |
| C4 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:370` | `cascadeAscentSteps_reaches_and_obeys_2a` | Atteinte séquentielle `0 → 1 → 2 → … → Z` par pas unitaires conformes à 2a | `[propext, Quot.sound]` |
| C5 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:394` | `projectAttentionalDomain_valid` | Validité géométrique `isValidCoreAffect` de `projectAttentionalDomain` | `[propext, Classical.choice, Quot.sound]` |
| C6 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:403` | `projectAttentionalDomain_z` | Conservation exacte de la profondeur `z = d.z` par `projectAttentionalDomain` | `[propext, Quot.sound]` |
| C7 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:458` | `canonical_l1_conservation` | Conservation `|X_0| + |Y_0| = 2` au Croisement I hors `Veille` | `[none]` |
| C8 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:470` | `canonical_l1_zero_iff_veille` | Caractérisation exacte `|X_0| + |Y_0| = 0 ↔ c = ⟨.zero, .zero⟩` | `[none]` |
| C9 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:479` | `canonical_crown_scaling_law` | Identité signée sur `ℤ` (`|X| + |Y| = 2Z - 2`) pour tout état actif `Z ≥ 2` | `[propext, Classical.choice, Quot.sound]` |
| C10 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:522` | `attentional_domain_disjoint_from_veille` | Exclusion structurelle de `Veille (0,0,0)` pour tout domaine attentionnel et sa projection | `[propext, Quot.sound]` |
| C11 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:540` | `attentional_neutral_domain_is_non_veille` | Disjonction du domaine central `{0, 0, Z ≥ 1}` d'avec `Veille (0,0,0)` | `[propext, Quot.sound]` |
| C12 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:573` | `active_vs_passive_step_disjoint` | Disjonction stricte entre résolution active et extinction passive (`Charge → Neutre`) | `[propext]` |
| C13 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:603` | `lyapunov_strict_decrease_active_free` | Décroissance stricte `V(dst) < V(src)` en régime libre sans extinction passive | `[propext, Quot.sound]` |
| C14 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:657` | `passive_extinction_requires_delta_pos` | Nécessité de `δ_A > 0 ∨ δ_C > 0` pour toute extinction passive à bruit nul | `[propext]` |
| C15 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:711` | `canonical_project_z2_contingency_bound` | Coïncidence des contingences en `Z = 2` et annulation identique (`none`) pour tout `Z ≠ 2` | `[propext, Classical.choice, Quot.sound]` |
| C16 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:739` | `canonical_attentional_domain_to_taxonomy_coherent` | Cohérence terminale vers `TaxonomicState` neutre avec canal `A ≥ 0` et borne `Z ≤ 5` | `[propext, Classical.choice, Quot.sound]` |

### 4.2. Lemmes auxiliaires élémentaires et corollaires d'interface isolés (5 déclarations)

| # | Fichier : Ligne | Identifiant Lean 4 | Nature | Axiomes (`#print axioms`) |
|---:|:---|:---|:---|:---|
| CE1 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:441` | `canonicalPhi_left_inv` | Encapsulation directe de `phiL1_left_inv` | `[none]` |
| CE2 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:450` | `canonicalPhi_right_inv` | Encapsulation directe de `phiL1_right_inv` | `[propext, Quot.sound]` |
| CE3 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:505` | `canonical_apportionRay_scaling` | Projection directe de `(apportionRay_bounds d piA piC).2.2` | `[propext, Classical.choice, Quot.sound]` |
| CE4 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:513` | `veille_disjoint_from_attentional_point` | Lemme auxiliaire élémentaire (`p.z ≥ 1 → p ≠ ⟨0, 0, 0⟩`) | `[propext, Quot.sound]` |
| CE5 | `extensions/predictive_engine/PredictiveEngineCanonical.lean:691` | `active_vs_passive_energy_signature` | Témoin concret sur `⟨.neg, .zero⟩` (`rfl` / `decide`) | `[none]` |

---

## 5. Sortie Brute Intégrale de `#print axioms` (`Cartograffect/AuditTests.lean` & `PredictiveEngineCanonical.lean`)

### 5.1. `lake env lean Cartograffect/AuditTests.lean` (Phase 1 — 169 théorèmes)

```text
Cartograffect/AuditTests.lean:42:0: info: 'Cartograffect.PredictiveEngine.engineStep_of_salient_neutral' depends on axioms: [propext]
Cartograffect/AuditTests.lean:43:0: info: 'Cartograffect.PredictiveEngine.engineStep_of_salient_nonneutral_unsuspended' depends on axioms: [propext]
Cartograffect/AuditTests.lean:44:0: info: 'Cartograffect.PredictiveEngine.engineStep_of_salient_nonneutral_suspended_unengaged' depends on axioms: [propext]
Cartograffect/AuditTests.lean:45:0: info: 'Cartograffect.PredictiveEngine.Polarity.invert_involutive' does not depend on any axioms
Cartograffect/AuditTests.lean:46:0: info: 'Cartograffect.PredictiveEngine.Polarity.toRegime_neutral_iff' does not depend on any axioms
Cartograffect/AuditTests.lean:47:0: info: 'Cartograffect.PredictiveEngine.single_neutral_not_global_neutral' does not depend on any axioms
Cartograffect/AuditTests.lean:48:0: info: 'Cartograffect.PredictiveEngine.allCouplings_card' does not depend on any axioms
Cartograffect/AuditTests.lean:49:0: info: 'Cartograffect.PredictiveEngine.mem_allCouplings' depends on axioms: [propext]
Cartograffect/AuditTests.lean:50:0: info: 'Cartograffect.PredictiveEngine.coupling_regime_partition' does not depend on any axioms
Cartograffect/AuditTests.lean:51:0: info: 'Cartograffect.PredictiveEngine.feedbackUpdate_couples_gradients' does not depend on any axioms
Cartograffect/AuditTests.lean:52:0: info: 'Cartograffect.PredictiveEngine.feedbackUpdateWeighted_couples_precision' does not depend on any axioms
Cartograffect/AuditTests.lean:53:0: info: 'Cartograffect.PredictiveEngine.inferential_loop_covers_interfaces' does not depend on any axioms
Cartograffect/AuditTests.lean:54:0: info: 'Cartograffect.PredictiveEngine.engineStep_remanence' depends on axioms: [propext]
Cartograffect/AuditTests.lean:55:0: info: 'Cartograffect.PredictiveEngine.engineStep_phase_progression' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:58:0: info: 'Cartograffect.CoreAffect.crownRadius_eq_formula' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:59:0: info: 'Cartograffect.CoreAffect.natAbs_neg_ofNat' does not depend on any axioms
Cartograffect/AuditTests.lean:60:0: info: 'Cartograffect.CoreAffect.natAbs_pos_ofNat' does not depend on any axioms
Cartograffect/AuditTests.lean:61:0: info: 'Cartograffect.CoreAffect.apportionRay_bounds' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:62:0: info: 'Cartograffect.CoreAffect.apportionRay_swap' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:63:0: info: 'Cartograffect.CoreAffect.apportionRay_symm' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:64:0: info: 'Cartograffect.CoreAffect.apportionRay_z2' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:65:0: info: 'Cartograffect.CoreAffect.apportionRay_exact' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:66:0: info: 'Cartograffect.CoreAffect.deployCouplingWithPrecision_symm_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:67:0: info: 'Cartograffect.CoreAffect.deployCouplingAtDepth_valid' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:68:0: info: 'Cartograffect.CoreAffect.deployCouplingWithPrecision_valid' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:69:0: info: 'Cartograffect.CoreAffect.engine_induces_valid_core_affect' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:70:0: info: 'Cartograffect.CoreAffect.neutral_coupling_without_suspension_yields_veille' does not depend on any axioms
Cartograffect/AuditTests.lean:71:0: info: 'Cartograffect.CoreAffect.neutral_or_subthreshold_with_suspension_yields_central' does not depend on any axioms
Cartograffect/AuditTests.lean:72:0: info: 'Cartograffect.CoreAffect.descending_suspension_yields_central_operator' depends on axioms: [propext]
Cartograffect/AuditTests.lean:73:0: info: 'Cartograffect.CoreAffect.central_z_ge2_requires_descending_suspension' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:74:0: info: 'Cartograffect.CoreAffect.z2_budget_conservation' does not depend on any axioms
Cartograffect/AuditTests.lean:75:0: info: 'Cartograffect.CoreAffect.single_engaged_yields_axial_z2' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:76:0: info: 'Cartograffect.CoreAffect.dual_engaged_yields_diagonal_z2' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:77:0: info: 'Cartograffect.CoreAffect.axial_to_diagonal_reallocation' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:78:0: info: 'Cartograffect.CoreAffect.deployCouplingWithPrecision_budget_conservation' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:79:0: info: 'Cartograffect.CoreAffect.dual_engaged_yields_diagonal_z2_precision' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:80:0: info: 'Cartograffect.CoreAffect.symmetric_precision_never_lateral' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:81:0: info: 'Cartograffect.CoreAffect.projectToCoreAffect_independent_of_activation' does not depend on any axioms
Cartograffect/AuditTests.lean:82:0: info: 'Cartograffect.CoreAffect.projectToCoreAffect_surjective' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:83:0: info: 'Cartograffect.CoreAffect.engineStep_canonical_trajectory' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:84:0: info: 'Cartograffect.CoreAffect.engineStep_surprise_to_crown' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:85:0: info: 'Cartograffect.CoreAffect.dissipationStep_valid' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:86:0: info: 'Cartograffect.CoreAffect.anticipation_short_circuits_to_veille' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:87:0: info: 'Cartograffect.CoreAffect.dissipation_from_ge2_never_visits_surprise' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:88:0: info: 'Cartograffect.CoreAffect.pointDeVeille_is_fixed_point' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:89:0: info: 'Cartograffect.CoreAffect.dissipationStep_fixed_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:90:0: info: 'Cartograffect.CoreAffect.dissipation_strictly_decreases' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:91:0: info: 'Cartograffect.CoreAffect.dissipationPotential_short_circuit_jump' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:92:0: info: 'Cartograffect.CoreAffect.dissipation_reaches_veille' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:93:0: info: 'Cartograffect.CoreAffect.remanence_preserves_state' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:94:0: info: 'Cartograffect.CoreAffect.cooperative_step_leaves_crown' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:97:0: info: 'Cartograffect.AffectiveMatrix.HedonicPolarity.invert_involutive' does not depend on any axioms
Cartograffect/AuditTests.lean:98:0: info: 'Cartograffect.AffectiveMatrix.x_positive_determines_positive_valence' depends on axioms: [propext]
Cartograffect/AuditTests.lean:99:0: info: 'Cartograffect.AffectiveMatrix.x_negative_determines_negative_valence' depends on axioms: [propext]
Cartograffect/AuditTests.lean:100:0: info: 'Cartograffect.AffectiveMatrix.PrimaryCrownPrototype.valid_on_crown' does not depend on any axioms
Cartograffect/AuditTests.lean:101:0: info: 'Cartograffect.AffectiveMatrix.antagonistPoint_preserves_z' does not depend on any axioms
Cartograffect/AuditTests.lean:102:0: info: 'Cartograffect.AffectiveMatrix.antagonistPoint_preserves_displacementSum' depends on axioms: [propext]
Cartograffect/AuditTests.lean:103:0: info: 'Cartograffect.AffectiveMatrix.antagonistPoint_preserves_validity' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:104:0: info: 'Cartograffect.AffectiveMatrix.antagonistPoint_involutive' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:105:0: info: 'Cartograffect.AffectiveMatrix.antagonistPoint_fixed_iff_central' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:106:0: info: 'Cartograffect.AffectiveMatrix.contralateral_swaps_amplitudes' does not depend on any axioms
Cartograffect/AuditTests.lean:107:0: info: 'Cartograffect.AffectiveMatrix.canonical_antagonist_examples' does not depend on any axioms
Cartograffect/AuditTests.lean:108:0: info: 'Cartograffect.AffectiveMatrix.antagonist_commutes_with_invert' depends on axioms: [propext]
Cartograffect/AuditTests.lean:109:0: info: 'Cartograffect.AffectiveMatrix.antagonist_commutes_with_invert_precision' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:110:0: info: 'Cartograffect.AffectiveMatrix.antagonistPoint_off_axis' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:111:0: info: 'Cartograffect.AffectiveMatrix.antagonistPoint_piecewise' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:112:0: info: 'Cartograffect.AffectiveMatrix.antagonist_preserves_validity_in' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:113:0: info: 'Cartograffect.AffectiveMatrix.transferUnitXtoY_preserves_sum' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:114:0: info: 'Cartograffect.AffectiveMatrix.transferUnitYtoX_preserves_sum' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:115:0: info: 'Cartograffect.AffectiveMatrix.antagonistPoint_inverts_hedonic_polarity' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:116:0: info: 'Cartograffect.AffectiveMatrix.autonomousActivation_decoupled_from_core' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:117:0: info: 'Cartograffect.AffectiveMatrix.evaluateMatrix_core_antagonist_independent' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:118:0: info: 'Cartograffect.AffectiveMatrix.mapping_independent_antagonist_invariants' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:121:0: info: 'Cartograffect.AffectiveTaxonomy.canonical_crown_counts_certified' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:122:0: info: 'Cartograffect.AffectiveTaxonomy.classifyTaxonomicGroup_correct' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:123:0: info: 'Cartograffect.AffectiveTaxonomy.taxonomy_group_exhaustive' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:124:0: info: 'Cartograffect.AffectiveTaxonomy.taxonomy_group_exclusive' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:125:0: info: 'Cartograffect.AffectiveTaxonomy.matchesTaxonomicGroup_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:126:0: info: 'Cartograffect.AffectiveTaxonomy.dominantSector_iff_taxonomicGroup' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:127:0: info: 'Cartograffect.AffectiveTaxonomy.contralateral_group_bindings' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:128:0: info: 'Cartograffect.AffectiveTaxonomy.classifySubsector_correct' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:129:0: info: 'Cartograffect.AffectiveTaxonomy.subsector_exclusive' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:130:0: info: 'Cartograffect.AffectiveTaxonomy.matchesSubsector_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:131:0: info: 'Cartograffect.AffectiveTaxonomy.matchesSubsector_toTaxonomicGroup' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:132:0: info: 'Cartograffect.AffectiveTaxonomy.classifySubsector_refines_group' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:133:0: info: 'Cartograffect.AffectiveTaxonomy.matchesSubsector_toHedonicPolarity' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:134:0: info: 'Cartograffect.AffectiveTaxonomy.classifySubsector_determines_valence' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:135:0: info: 'Cartograffect.AffectiveTaxonomy.end_to_end_coherence' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:136:0: info: 'Cartograffect.AffectiveTaxonomy.pipeline_decouples_point_and_activation' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:139:0: info: 'Cartograffect.AffectiveDynamics.isValidCoreAffectB_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:140:0: info: 'Cartograffect.AffectiveDynamics.canonicalDepthKernel_reaches_crown' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:141:0: info: 'Cartograffect.AffectiveDynamics.canonicalDepthKernel_reaches_lateral' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:142:0: info: 'Cartograffect.AffectiveDynamics.canonicalDepthKernel_crown_from_surprise' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:143:0: info: 'Cartograffect.AffectiveDynamics.lateral_reachable_from_surprise' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:144:0: info: 'Cartograffect.AffectiveDynamics.canonicalDepthKernel_colere_bifurcates' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:145:0: info: 'Cartograffect.AffectiveDynamics.canonicalDepthKernel_axial_instability_p2' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:146:0: info: 'Cartograffect.AffectiveDynamics.mem_stratumPoints_of_valid' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:147:0: info: 'Cartograffect.AffectiveDynamics.DepthTransitionKernel.outgoingWeight_pos_of_witness' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:148:0: info: 'Cartograffect.AffectiveDynamics.canonicalDepthKernel_outgoingWeight_pos' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:149:0: info: 'Cartograffect.AffectiveDynamics.classifyTaxonomicGroup_unique_maximizer' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:150:0: info: 'Cartograffect.AffectiveDynamics.classifyTaxonomicGroup_maximizes_membership' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:151:0: info: 'Cartograffect.AffectiveDynamics.lateral_has_overlapping_attractors' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:154:0: info: 'Cartograffect.PredictiveCircuit.allCircuitOperations_card' does not depend on any axioms
Cartograffect/AuditTests.lean:155:0: info: 'Cartograffect.PredictiveCircuit.mem_allCircuitOperations' depends on axioms: [propext]
Cartograffect/AuditTests.lean:156:0: info: 'Cartograffect.PredictiveCircuit.circuit_covers_interfaces_both_sides' does not depend on any axioms
Cartograffect/AuditTests.lean:157:0: info: 'Cartograffect.PredictiveCircuit.circuit_refines_inferential_ops' does not depend on any axioms
Cartograffect/AuditTests.lean:158:0: info: 'Cartograffect.PredictiveCircuit.circuit_preserves_carrier' does not depend on any axioms
Cartograffect/AuditTests.lean:159:0: info: 'Cartograffect.PredictiveCircuit.unique_agent_perceptible_crossing' depends on axioms: [propext]
Cartograffect/AuditTests.lean:160:0: info: 'Cartograffect.PredictiveCircuit.phiL1_valid' does not depend on any axioms
Cartograffect/AuditTests.lean:161:0: info: 'Cartograffect.PredictiveCircuit.phiL1_l1Norm_active' does not depend on any axioms
Cartograffect/AuditTests.lean:162:0: info: 'Cartograffect.PredictiveCircuit.phiL1_left_inv' does not depend on any axioms
Cartograffect/AuditTests.lean:163:0: info: 'Cartograffect.PredictiveCircuit.phiL1_right_inv' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:164:0: info: 'Cartograffect.PredictiveCircuit.phiL1_agrees_with_deployZ2' does not depend on any axioms
Cartograffect/AuditTests.lean:165:0: info: 'Cartograffect.PredictiveCircuit.crossingII_is_transpose_of_crossingI' does not depend on any axioms
Cartograffect/AuditTests.lean:166:0: info: 'Cartograffect.PredictiveCircuit.routeToSubjective_injective' does not depend on any axioms
Cartograffect/AuditTests.lean:167:0: info: 'Cartograffect.PredictiveCircuit.routeToPerceptive_injective' does not depend on any axioms
Cartograffect/AuditTests.lean:168:0: info: 'Cartograffect.PredictiveCircuit.projectPerceptible_valid' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:169:0: info: 'Cartograffect.PredictiveCircuit.projectPerceptible_z2_matches_phiL1' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:170:0: info: 'Cartograffect.PredictiveCircuit.projectPerceptible_neutral_elevates_to_central' depends on axioms: [propext]
Cartograffect/AuditTests.lean:171:0: info: 'Cartograffect.PredictiveCircuit.attentional_bottleneck_sum_active' does not depend on any axioms
Cartograffect/AuditTests.lean:172:0: info: 'Cartograffect.PredictiveCircuit.lyapunovPotential_zero_iff' does not depend on any axioms
Cartograffect/AuditTests.lean:173:0: info: 'Cartograffect.PredictiveCircuit.lyapunovPotential_le_four' does not depend on any axioms
Cartograffect/AuditTests.lean:174:0: info: 'Cartograffect.PredictiveCircuit.lyapunovPotential_max_iff' does not depend on any axioms
Cartograffect/AuditTests.lean:175:0: info: 'Cartograffect.PredictiveCircuit.circuitRowSum_exact' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:176:0: info: 'Cartograffect.PredictiveCircuit.veille_absorbing_free' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:177:0: info: 'Cartograffect.PredictiveCircuit.lyapunov_monotone_free' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:178:0: info: 'Cartograffect.PredictiveCircuit.lyapunov_strict_descent_witness' depends on axioms: [propext]
Cartograffect/AuditTests.lean:179:0: info: 'Cartograffect.PredictiveCircuit.lyapunov_expected_drift_constant' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:180:0: info: 'Cartograffect.PredictiveCircuit.lyapunov_drift_charge_with_passive_extinction' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:181:0: info: 'Cartograffect.PredictiveCircuit.p1_without_p2_eps_independent' depends on axioms: [propext]
Cartograffect/AuditTests.lean:182:0: info: 'Cartograffect.PredictiveCircuit.axial_peur_bifurcates_p2' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:183:0: info: 'Cartograffect.PredictiveCircuit.axial_tristesse_and_discharge_asymmetry_p2' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:184:0: info: 'Cartograffect.PredictiveCircuit.veille_self_loop_ergodic' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:185:0: info: 'Cartograffect.PredictiveCircuit.veille_reaches_all_one_step' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:186:0: info: 'Cartograffect.PredictiveCircuit.all_reach_veille_two_steps' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:187:0: info: 'Cartograffect.PredictiveCircuit.veille_unreachable_when_eps_max' depends on axioms: [propext]
Cartograffect/AuditTests.lean:188:0: info: 'Cartograffect.PredictiveCircuit.epistemic_rigidity_traps_charge_slice' depends on axioms: [propext]
Cartograffect/AuditTests.lean:189:0: info: 'Cartograffect.PredictiveCircuit.pragmatic_helplessness_traps_charge_slice' depends on axioms: [propext]
Cartograffect/AuditTests.lean:190:0: info: 'Cartograffect.PredictiveCircuit.perseveration_traps_discharge_free' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:191:0: info: 'Cartograffect.PredictiveCircuit.circularCycle_emits_valid_core_affect' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:192:0: info: 'Cartograffect.PredictiveCircuit.circularCycle_veille_fixed_point' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:193:0: info: 'Cartograffect.PredictiveCircuit.circularCycle_reduces_total_discrepancy' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:194:0: info: 'Cartograffect.PredictiveCircuit.passive_extinction_zero_relief' does not depend on any axioms
Cartograffect/AuditTests.lean:195:0: info: 'Cartograffect.PredictiveCircuit.active_resolution_beats_passive_extinction' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:196:0: info: 'Cartograffect.PredictiveCircuit.charge_accumulator_bounded' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:197:0: info: 'Cartograffect.PredictiveCircuit.nextStratumR5_le_zMax' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:198:0: info: 'Cartograffect.PredictiveCircuit.nextStratumR5_short_circuits_z2_to_veille' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:199:0: info: 'Cartograffect.PredictiveCircuit.nextStratumR5_from_ge2_never_visits_surprise' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:200:0: info: 'Cartograffect.PredictiveCircuit.symmetricSigmoid_sum' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:201:0: info: 'Cartograffect.PredictiveCircuit.symmetricSigmoid_pos' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:202:0: info: 'Cartograffect.PredictiveCircuit.symmetricSigmoid_neg' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:203:0: info: 'Cartograffect.PredictiveCircuit.precisionShare_double_charge_cancels_alpha' depends on axioms: [propext]
Cartograffect/AuditTests.lean:204:0: info: 'Cartograffect.PredictiveCircuit.projectUnifiedState_valid' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:205:0: info: 'Cartograffect.PredictiveCircuit.projectUnifiedState_crown_budget' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:206:0: info: 'Cartograffect.PredictiveCircuit.projectUnifiedState_reaches_lateral_agentic_confront' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:209:0: info: 'Cartograffect.OperantFactorization.manhattanDistXY_origin' depends on axioms: [propext]
Cartograffect/AuditTests.lean:210:0: info: 'Cartograffect.OperantFactorization.rolls_factorization_law' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:211:0: info: 'Cartograffect.OperantFactorization.rolls_contingencies_z2_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:212:0: info: 'Cartograffect.OperantFactorization.energyRegime_matches_rolls_contingency' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:213:0: info: 'Cartograffect.OperantFactorization.antagonist_rolls_symmetry_z2' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:214:0: info: 'Cartograffect.OperantFactorization.axial_poles_bridge_rolls_pairs' does not depend on any axioms
Cartograffect/AuditTests.lean:215:0: info: 'Cartograffect.OperantFactorization.axial_poles_pre_contingency' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:216:0: info: 'Cartograffect.OperantFactorization.z2_rolls_bijection_2x2' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:219:0: info: 'Cartograffect.EndToEndBridge.circuit_coupling_z2_contingency_bridge' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:220:0: info: 'Cartograffect.EndToEndBridge.triggerSecondaryGradient_enters_z2_contingency' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:221:0: info: 'Cartograffect.EndToEndBridge.p2_negative_charge_enters_z2_contingencies' depends on axioms: [propext, Quot.sound]
Cartograffect/AuditTests.lean:222:0: info: 'Cartograffect.EndToEndBridge.vertical_operators_obey_stepwise_2a' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:223:0: info: 'Cartograffect.EndToEndBridge.unified_and_circular_to_taxonomy_coherence' depends on axioms: [propext, Classical.choice, Quot.sound]
Cartograffect/AuditTests.lean:224:0: info: 'Cartograffect.EndToEndBridge.full_end_to_end_v3_coherence' depends on axioms: [propext, Classical.choice, Quot.sound]
```

### 5.2. `lake env lean extensions/predictive_engine/PredictiveEngineCanonical.lean` (21 théorèmes)

```text
extensions/predictive_engine/PredictiveEngineCanonical.lean:794:0: info: 'Cartograffect.PredictiveEngineCanonical.assembleIsolatedResponses_iff' does not depend on any axioms
extensions/predictive_engine/PredictiveEngineCanonical.lean:795:0: info: 'Cartograffect.PredictiveEngineCanonical.attentional_domain_realizations_valid_and_card' depends on axioms: [propext, Classical.choice, Quot.sound]
extensions/predictive_engine/PredictiveEngineCanonical.lean:796:0: info: 'Cartograffect.PredictiveEngineCanonical.stepAttentionalDomain2a_sound_and_no_jump' depends on axioms: [propext, Classical.choice, Quot.sound]
extensions/predictive_engine/PredictiveEngineCanonical.lean:797:0: info: 'Cartograffect.PredictiveEngineCanonical.cascadeAscentSteps_reaches_and_obeys_2a' depends on axioms: [propext, Quot.sound]
extensions/predictive_engine/PredictiveEngineCanonical.lean:798:0: info: 'Cartograffect.PredictiveEngineCanonical.projectAttentionalDomain_valid' depends on axioms: [propext, Classical.choice, Quot.sound]
extensions/predictive_engine/PredictiveEngineCanonical.lean:799:0: info: 'Cartograffect.PredictiveEngineCanonical.projectAttentionalDomain_z' depends on axioms: [propext, Quot.sound]
extensions/predictive_engine/PredictiveEngineCanonical.lean:800:0: info: 'Cartograffect.PredictiveEngineCanonical.canonicalPhi_left_inv' does not depend on any axioms
extensions/predictive_engine/PredictiveEngineCanonical.lean:801:0: info: 'Cartograffect.PredictiveEngineCanonical.canonicalPhi_right_inv' depends on axioms: [propext, Quot.sound]
extensions/predictive_engine/PredictiveEngineCanonical.lean:802:0: info: 'Cartograffect.PredictiveEngineCanonical.canonical_l1_conservation' does not depend on any axioms
extensions/predictive_engine/PredictiveEngineCanonical.lean:803:0: info: 'Cartograffect.PredictiveEngineCanonical.canonical_l1_zero_iff_veille' does not depend on any axioms
extensions/predictive_engine/PredictiveEngineCanonical.lean:804:0: info: 'Cartograffect.PredictiveEngineCanonical.canonical_crown_scaling_law' depends on axioms: [propext, Classical.choice, Quot.sound]
extensions/predictive_engine/PredictiveEngineCanonical.lean:805:0: info: 'Cartograffect.PredictiveEngineCanonical.canonical_apportionRay_scaling' depends on axioms: [propext, Classical.choice, Quot.sound]
extensions/predictive_engine/PredictiveEngineCanonical.lean:806:0: info: 'Cartograffect.PredictiveEngineCanonical.veille_disjoint_from_attentional_point' depends on axioms: [propext, Quot.sound]
extensions/predictive_engine/PredictiveEngineCanonical.lean:807:0: info: 'Cartograffect.PredictiveEngineCanonical.attentional_domain_disjoint_from_veille' depends on axioms: [propext, Quot.sound]
extensions/predictive_engine/PredictiveEngineCanonical.lean:808:0: info: 'Cartograffect.PredictiveEngineCanonical.attentional_neutral_domain_is_non_veille' depends on axioms: [propext, Quot.sound]
extensions/predictive_engine/PredictiveEngineCanonical.lean:809:0: info: 'Cartograffect.PredictiveEngineCanonical.active_vs_passive_step_disjoint' depends on axioms: [propext]
extensions/predictive_engine/PredictiveEngineCanonical.lean:810:0: info: 'Cartograffect.PredictiveEngineCanonical.lyapunov_strict_decrease_active_free' depends on axioms: [propext, Quot.sound]
extensions/predictive_engine/PredictiveEngineCanonical.lean:811:0: info: 'Cartograffect.PredictiveEngineCanonical.passive_extinction_requires_delta_pos' depends on axioms: [propext]
extensions/predictive_engine/PredictiveEngineCanonical.lean:812:0: info: 'Cartograffect.PredictiveEngineCanonical.active_vs_passive_energy_signature' does not depend on any axioms
extensions/predictive_engine/PredictiveEngineCanonical.lean:813:0: info: 'Cartograffect.PredictiveEngineCanonical.canonical_project_z2_contingency_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
extensions/predictive_engine/PredictiveEngineCanonical.lean:814:0: info: 'Cartograffect.PredictiveEngineCanonical.canonical_attentional_domain_to_taxonomy_coherent' depends on axioms: [propext, Classical.choice, Quot.sound]
```

---

## 6. Commandes de Reproduction pour Vérificateur Indépendant

```powershell
lake build
lake env lean Cartograffect/AuditTests.lean
lake env lean extensions/predictive_engine/PredictiveEngineCanonical.lean
python -m unittest discover -s python -v
```
