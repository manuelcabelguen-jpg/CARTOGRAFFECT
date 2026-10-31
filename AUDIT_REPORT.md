# AUDIT_REPORT — Certification formelle de CARTOGRAFFECT

**Cartographie des affects — formalisation Lean 4**
Rapport d'audit de vérification formelle et de fidélité épistémique · Phases 1 à 5 · 2026-10-24

---

## Sommaire

1. [En-tête exécutif et tableau de bord de certification](#1-en-tête-exécutif-et-tableau-de-bord-de-certification)
2. [Non-vacuité et exécution concrète (Phase 2)](#2-vérification-de-la-non-vacuité-et-exécution-concrète-phase-2)
3. [Chaînage déductif inter-modules et traçabilité ontologique (Phase 3)](#3-audit-du-chaînage-déductif-inter-modules-et-table-de-traçabilité-ontologique-phase-3)
4. [Journal des réparations tactiques sous Lean 4.35.0 (Phase 4)](#4-journal-des-réparations-tactiques-sous-lean-4350-phase-4)
5. [Singularités théoriques et pistes d'extension formelle (Phase 5)](#5-diagnostic-des-singularités-théoriques-et-pistes-dextension-formelle-phase-5)

---

## 1. En-tête exécutif et tableau de bord de certification

### 1.1 Identification

| Élément | Valeur |
|---|---|
| Modèle théorique | *Cartographie des affects* — **CARTOGRAFFECT** |
| Sources théoriques | [Doc. 1 — Article](docs/01-Article_Cartograffect.md) · [Doc. 2 — Inventaire des 176 entrées](docs/02-Inventaire_176.md) |
| Toolchain | `leanprover/lean4:v4.35.0` ([`lean-toolchain`](lean-toolchain)) |
| Dépendances externes | **Aucune** (ni Mathlib ni Batteries : uniquement le noyau Lean 4 et `Init`) |
| Bibliothèque Lake | `Cartograffect` (`@[default_target]`, [`lakefile.lean`](lakefile.lean)) |
| Architecture | 5 modules théoriques + 1 module d'audit + 1 module racine |

### 1.2 Statut de compilation (Phase 1)

| # | Cible Lake (module) | Rôle | Statut |
|---|---|---|---|
| 1 | [`Cartograffect.PredictiveEngine`](Cartograffect/PredictiveEngine.lean) | Moteur prédictif (Doc. 1 §4) | ✅ PASS |
| 2 | [`Cartograffect.CoreAffect`](Cartograffect/CoreAffect.lean) | Noyau affectif (Doc. 1 §5, Doc. 2 §1–2) | ✅ PASS |
| 3 | [`Cartograffect.AffectiveMatrix`](Cartograffect/AffectiveMatrix.lean) | Matrice affective (Doc. 1 §6, §7.1 ; Doc. 2 §4) | ✅ PASS |
| 4 | [`Cartograffect.AffectiveTaxonomy`](Cartograffect/AffectiveTaxonomy.lean) | Taxonomie hiérarchique (Doc. 1 §7 ; Doc. 2 §2–3, §5) | ✅ PASS |
| 5 | [`Cartograffect.Lexicon176`](Cartograffect/Lexicon176.lean) | Répertoire nominal des 176 positions et clôture antagoniste (Doc. 2 §3–4) | ✅ PASS |
| 6 | [`Cartograffect.AuditTests`](Cartograffect/AuditTests.lean) | Banc d'audit (`#print axioms`, `#eval`) | ✅ PASS |
| 7 | [`Cartograffect`](Cartograffect.lean) | Module racine (agrégation) | ✅ PASS |

`lake build` : **PASS** — 9 jobs, **0 erreur, 0 avertissement**.

### 1.3 Intégrité axiomatique

| Contrôle | Résultat |
|---|---|
| Occurrences textuelles de `sorry`, `admit`, `axiom`, `unsafe`, `implemented_by` | **0** |
| Théorèmes dépendant de `sorryAx` | **0** |
| Déclarations `noncomputable` | **0** (toutes les fonctions sont exécutables, ce que confirment les `#eval`) |
| Axiomes mobilisés en dehors du socle standard de Lean 4 | **0** |

Les 33 théorèmes audités par `#print axioms` (sorties exactes reproduites ci-dessous) se répartissent en trois profils :

| Profil axiomatique | Théorèmes | Nombre |
|---|---|---|
| **Purement réductionnel** — `does not depend on any axioms` | `Polarity.invert_involutive`, `coupling_regime_partition`, `feedbackUpdate_couples_gradients`, `inferential_loop_covers_interfaces`, `z2_budget_conservation`, `HedonicPolarity.invert_involutive`, `contralateral_swaps_amplitudes`, `inventory_176_certified`, `all176Entries_length`, `all176Entries_unique_points`, `all176Entries_closed_under_antagonist` | 11 |
| **Extensionnel** — `[propext]` ou `[propext, Quot.sound]` | `engine_induces_valid_core_affect`, `cooperative_step_leaves_crown`, `x_positive_determines_positive_valence`, `x_negative_determines_negative_valence`, `antagonist_commutes_with_invert`, `transferUnitYtoX_preserves_sum`, `taxonomy_group_exclusive`, `all176Entries_spatial_completeness` | 8 |
| **Socle classique standard** — `[propext, Classical.choice, Quot.sound]` | `axial_to_diagonal_reallocation`, `dissipationStep_valid`, `dissipationStep_fixed_iff`, `dissipation_strictly_decreases`, `remanence_preserves_state`, `antagonistPoint_preserves_validity`, `antagonistPoint_involutive`, `antagonistPoint_unified`, `antagonist_preserves_validity_in`, `taxonomy_group_exhaustive`, `dominantSector_iff_taxonomicGroup`, `contralateral_group_bindings`, **`end_to_end_coherence`**, `all176Entries_geometrically_valid` | 14 |

<details>
<summary>Sorties exactes de <code>#print axioms</code> (<a href="Cartograffect/AuditTests.lean#L24-L56">AuditTests.lean, l. 24–56</a>)</summary>

```text
Polarity.invert_involutive             : does not depend on any axioms
coupling_regime_partition              : does not depend on any axioms
feedbackUpdate_couples_gradients       : does not depend on any axioms
inferential_loop_covers_interfaces     : does not depend on any axioms
engine_induces_valid_core_affect       : [propext, Quot.sound]
z2_budget_conservation                 : does not depend on any axioms
axial_to_diagonal_reallocation         : [propext, Classical.choice, Quot.sound]
dissipationStep_valid                  : [propext, Classical.choice, Quot.sound]
dissipationStep_fixed_iff              : [propext, Classical.choice, Quot.sound]
dissipation_strictly_decreases         : [propext, Classical.choice, Quot.sound]
remanence_preserves_state              : [propext, Classical.choice, Quot.sound]
cooperative_step_leaves_crown          : [propext, Quot.sound]
HedonicPolarity.invert_involutive      : does not depend on any axioms
x_positive_determines_positive_valence : [propext]
x_negative_determines_negative_valence : [propext]
antagonistPoint_preserves_validity     : [propext, Classical.choice, Quot.sound]
antagonistPoint_involutive             : [propext, Classical.choice, Quot.sound]
contralateral_swaps_amplitudes         : does not depend on any axioms
antagonist_commutes_with_invert        : [propext]
antagonistPoint_unified                : [propext, Classical.choice, Quot.sound]
antagonist_preserves_validity_in       : [propext, Classical.choice, Quot.sound]
transferUnitYtoX_preserves_sum         : [propext, Quot.sound]
inventory_176_certified                : does not depend on any axioms
taxonomy_group_exhaustive              : [propext, Classical.choice, Quot.sound]
taxonomy_group_exclusive               : [propext, Quot.sound]
dominantSector_iff_taxonomicGroup      : [propext, Classical.choice, Quot.sound]
contralateral_group_bindings           : [propext, Classical.choice, Quot.sound]
end_to_end_coherence                   : [propext, Classical.choice, Quot.sound]
all176Entries_length                   : does not depend on any axioms
all176Entries_geometrically_valid      : [propext, Classical.choice, Quot.sound]
all176Entries_unique_points            : does not depend on any axioms
all176Entries_closed_under_antagonist  : does not depend on any axioms
all176Entries_spatial_completeness     : [propext, Quot.sound]
```
</details>

**Interprétation.**
- **Profil réductionnel.** Ces 10 théorèmes sont établis par pure réduction (`rfl`, `decide`, analyse de cas exhaustive). Leur preuve est un calcul que le noyau vérifie sans aucune hypothèse logique supplémentaire.
- **`propext` et `Quot.sound`.** Ce sont les axiomes d'extensionnalité propositionnelle et de quotient du noyau de Lean 4. Ils apparaissent dès que les tactiques `split`, `simp` ou `omega` réécrivent des propositions équivalentes.
- **`Classical.choice`.** Il provient des lemmes de la bibliothèque `Init` que mobilisent ces mêmes tactiques (notamment `decide` sur les prédicats de décidabilité géométrique). Il rend la *preuve* non constructive, sans toucher à la *calculabilité* des définitions : les preuves sont effacées à la compilation et chaque `def` reste évaluable par `#eval`.
- **Conclusion.** Ce socle `[propext, Classical.choice, Quot.sound]` est le socle standard admis par l'ensemble de l'écosystème Lean 4, Mathlib compris. Aucun axiome *ad hoc* propre au domaine n'est introduit.

### 1.4 Verdict

| Dimension | Verdict |
|---|---|
| Correction mécanique (compilation, absence de `sorry` et d'axiomes ad hoc) | ✅ **CERTIFIÉ** |
| Non-vacuité des types porteurs de preuves | ✅ **CERTIFIÉ** (§2) |
| Chaînage déductif `PredictiveEngine → CoreAffect → AffectiveMatrix → AffectiveTaxonomy` | ✅ **CERTIFIÉ** (§3.1–3.2) |
| Fidélité aux règles géométriques des sources (couronnes, antagonismes, inventaire) | ✅ **CONFORME** (§3.3–3.4) |
| Fidélité épistémique globale | 🟡 **CONFORME AVEC RÉSERVES DOCUMENTÉES** (§3.5) |

> [!IMPORTANT]
> **Portée de la certification.** Lean certifie la *cohérence interne* des conventions de construction formalisées, c'est-à-dire que les règles de placement, de correspondance et de résorption ne se contredisent pas. Il ne certifie **ni** la validité empirique de la théorie **ni** les hypothèses de correspondance phénoménologique. Cette limite est conforme à la position du Doc. 1 (§2, §8.2) : « la cohérence interne ne peut tenir lieu de validation ».

---

## 2. Vérification de la non-vacuité et exécution concrète (Phase 2)

### 2.1 Preuves d'inhabitation (`Inhabited`) sur les 4 modules

Une structure qui embarque une preuve, comme `CoreAffectState` avec `h_valid : isValidCoreAffect point`, pourrait être vide si son invariant était insatisfiable. Tout théorème quantifié universellement sur ce type deviendrait alors vrai par vacuité. Les quatre instances ci-dessous écartent ce risque en exhibant un témoin construit, au lieu de le postuler.

| Module | Type terminal | Instance | Témoin | Invariant certifié par le témoin |
|---|---|---|---|---|
| PredictiveEngine | `PredictiveEngineState` | `deriving Inhabited` ([l. 234–239](Cartograffect/PredictiveEngine.lean#L234-L239)), avec l'instance explicite `SalientDiscrepancy` ([l. 89–95](Cartograffect/PredictiveEngine.lean#L89-L95)) | écart nul, seuils `1 / 1` | hystérésis `resorptionThreshold ≤ sensoryThreshold` (`Nat.le_refl 1`) |
| CoreAffect | `CoreAffectState` | explicite ([l. 191–195](Cartograffect/CoreAffect.lean#L191-L195)) | Point de Veille `(0, 0, 0)` | `isValidCoreAffect` via `Or.inl ⟨rfl, rfl⟩` |
| AffectiveMatrix | `AffectiveMatrixState` | `evaluateMatrix default` ([l. 455–456](Cartograffect/AffectiveMatrix.lean#L455-L456)) | Matrice au Point de Veille | validité du point **et** de son antagoniste |
| AffectiveTaxonomy | `TaxonomicState` | `evaluateTaxonomy default` ([l. 291–292](Cartograffect/AffectiveTaxonomy.lean#L291-L292)) | entrée taxonomique du Point de Veille | strate, géométrie, groupe et groupe antagoniste |

Les instances des modules 3 et 4 sont **dérivées par le pipeline** et non construites à la main. Leur habitation découle donc des fonctions totales `evaluateMatrix` et `evaluateTaxonomy`, ce qui garantit aussi la non-vacuité de l'image de chaque étape. On a de plus, par construction, l'énoncé plus fort suivant : `evaluateCoreAffect : PredictiveEngineState → CoreAffectState` est **totale**. Chaque état du Moteur, et pas seulement le témoin par défaut, produit donc un état certifié du Noyau.

### 2.2 Résultats d'exécution `#eval` ([AuditTests.lean, l. 47–75](Cartograffect/AuditTests.lean#L47-L75))

#### Test 1 — Point de Veille (état par défaut)

```text
point   : { x := 0, y := 0, z := 0 }
stratum : TaxonomicStratum.z0_pointDeVeille
group   : TaxonomicGroup.operateurCentral
```

**Analyse.** Le constructeur dérivé `Inhabited Polarity` choisit le premier constructeur (`.neg`). Le couplage latent par défaut vaut donc `(A−, C−)`, et non `(A0, C0)`. Le système reste pourtant au Point de Veille, parce que l'écart (`magnitude = 0`) est sous le seuil de saillance sensorielle (`sensoryThreshold = 1`) : c'est la première garde de [`projectToCoreAffect`](Cartograffect/CoreAffect.lean#L262-L272) qui s'applique. Le résultat est conforme au Doc. 1 §4 : le Point de Veille est « un bassin de stabilité relative où les variations [...] sont tolérées sous le seuil de saillance ». Le test valide ainsi la branche *infra-liminaire* du pipeline, distincte de la branche de neutralité globale `(A0, C0)`.

#### Test 2 — Surprise (écart saillant sous le seuil attentionnel)

```text
point      : { x := 0, y := 0, z := 1 }
stratum    : TaxonomicStratum.z1_saillancePerceptive
activation : PhenomenologicalActivation.ascendingRupture
```

**Analyse.** Entrée : `magnitude 5 ≥ sensoryThreshold 2` (saillant), couplage latent `(A−, C+)`, `allocatedPrecision 1 < engagementThreshold 3`, sans suspension descendante. La projection donne `(0, 0, 1)`, ce qui restitue exactement le Doc. 1 §4 : la Surprise est l'« enregistrement d'un écart ayant franchi le seuil de saillance sensorielle avant que son couplage latent [...] ne soit spatialement déployé par l'attention ». Le couplage `(A−, C+)` est bien présent dans l'état, mais n'est pas projeté. Le profil d'activation `ascendingRupture` distingue formellement cette rupture de veille ascendante ($Z = 1$) des opérateurs descendants de suspension (`operatorSuspension`, $Z \ge 2$).

#### Test 3 — Colère et son antagoniste Calme (couplage engagé `A− / C+` en Z = 2)

```text
point             : { x := -1, y := 1, z := 2 }
antagonist.point  : { x := 1, y := -1, z := 2 }
group             : TaxonomicGroup.groupeColere
antagonistGroup   : TaxonomicGroup.groupeCalme
energyRegime      : EnergyRegime.ergotropicCompensation
valence           : HedonicPolarity.negative
```

**Analyse.** Avec la précision engagée (`5 ≥ 3`) et la profondeur `d = 0`, `deployCouplingAtDepth ⟨.neg, .pos⟩ 0` produit `(−1, +1, 2)`. Cette valeur coïncide avec la coordonnée de la Colère dans les deux sources (Doc. 1 §6.2 ; Doc. 2 §1, §3). L'antagoniste, obtenu par la branche diagonale de `antagonistPoint` (symétrie centrale), est `(+1, −1, 2)`, soit le Calme, conformément à la correspondance canonique du Doc. 2 §4. Le budget est conservé (`|−1| + |1| = 2 = R(2)`). Le régime énergétique `ergotropicCompensation` correspond à la « diagonale de compensation » (`X < 0 ∧ Y > 0`, Doc. 1 §6.2), tandis que la polarité hédonique `negative` résulte de la primauté lexicographique de l'Axe X (`X = −1 < 0`).

Ce test exerce **de bout en bout** les quatre modules et les deux certificats de validité, celui du point et celui de l'antagoniste.

---

## 3. Audit du chaînage déductif inter-modules et table de traçabilité ontologique (Phase 3)

### 3.1 Graphe de dépendances

```mermaid
flowchart LR
    subgraph PE["PredictiveEngine"]
        PES["PredictiveEngineState"]
        EC["EngineCoupling (9 couplages)"]
    end
    subgraph CA["CoreAffect"]
        P2C["projectToCoreAffect"]
        EIV["engine_induces_valid_core_affect"]
        ECA["evaluateCoreAffect"]
        CAS["CoreAffectState"]
    end
    subgraph AM["AffectiveMatrix"]
        AP["antagonistPoint"]
        APV["antagonistPoint_preserves_validity"]
        EM["evaluateMatrix"]
        AMS["AffectiveMatrixState"]
    end
    subgraph AT["AffectiveTaxonomy"]
        ET["evaluateTaxonomy"]
        RUN["runCartograffectPipeline"]
        CTG["classifyTaxonomicGroup_correct / exclusive"]
        E2E["end_to_end_coherence"]
    end
    PES --> P2C --> EIV --> ECA --> CAS
    CAS --> EM
    AP --> APV --> EM --> AMS
    AMS --> ET --> RUN --> E2E
    CTG --> E2E
    EIV --> E2E
    APV --> E2E
```

### 3.2 Vérification des signatures de types reliant les modules

| Étape | Déclaration | Signature | Certificat de transition (preuve embarquée) |
|---|---|---|---|
| Moteur → Noyau (point brut) | [`projectToCoreAffect`](Cartograffect/CoreAffect.lean#L262-L272) | `PredictiveEngineState → CoreAffectPoint` | — |
| Lemme de déploiement | [`deployCouplingAtDepth_valid`](Cartograffect/CoreAffect.lean#L283-L293) | `∀ c d, isValidCoreAffect (deployCouplingAtDepth c d)` | 9 cas de `Polarity × Polarity` |
| Moteur → Noyau (certifié) | [`evaluateCoreAffect`](Cartograffect/CoreAffect.lean#L316-L318) | `PredictiveEngineState → CoreAffectState` | `h_valid := engine_induces_valid_core_affect s` |
| Noyau → Matrice | [`evaluateMatrix`](Cartograffect/AffectiveMatrix.lean#L442-L452) | `CoreAffectState → AffectiveMatrixState` | `antagonist.h_valid := antagonistPoint_preserves_validity p cs.h_valid` |
| Matrice → Taxonomie | [`evaluateTaxonomy`](Cartograffect/AffectiveTaxonomy.lean#L282-L288) | `AffectiveMatrixState → TaxonomicState` | (classification totale et déterministe) |
| Pipeline | [`runCartograffectPipeline`](Cartograffect/AffectiveTaxonomy.lean#L299-L300) | `PredictiveEngineState → TaxonomicState` | composition `evaluateTaxonomy ∘ evaluateMatrix ∘ evaluateCoreAffect` |
| Théorème maître | [`end_to_end_coherence`](Cartograffect/AffectiveTaxonomy.lean#L337-L363) | `∀ s, ∃ ts, isCoherentTerminalState s ts ∧ ∀ ts', isCoherentTerminalState s ts' → ts' = ts` | voir ci-dessous |

**Constat 1 — Les invariants sont portés par les types.** Le chaînage ne repose pas sur des théorèmes énoncés « à côté » des fonctions. Il est **porté par les types** : il n'existe aucun moyen de construire un `CoreAffectState` (ou l'antagoniste d'un `AffectiveMatrixState`) sans fournir une preuve de `isValidCoreAffect`. Le compilateur garantit donc qu'aucun état géométriquement inadmissible ne peut circuler entre les modules.

**Constat 2 — Contenu et unicité substantielle du théorème maître.** Le prédicat [`isCoherentTerminalState`](Cartograffect/AffectiveTaxonomy.lean#L312-L327) comporte 15 clauses structurelles et phénoménologiques caractérisant intégralement l'état terminal `ts` sans aucune clause tautologique `ts = runCartograffectPipeline s` :

| Clause(s) | Contenu | Justification dans la preuve | Nature |
|---|---|---|---|
| 1 | point du Noyau = `projectToCoreAffect s` | `rfl` | projection |
| 2 | `isValidCoreAffect` du point | `engine_induces_valid_core_affect` (via `h_valid`) | **substantielle** |
| 3 | point antagoniste = `antagonistPoint` | `rfl` | symétrie |
| 4 | `isValidCoreAffect` de l'antagoniste | `antagonistPoint_preserves_validity` (via `h_valid`) | **substantielle** |
| 5 | conservation de la strate Z | `antagonistPoint_preserves_z` | **substantielle** |
| 6 | conservation du rayon `\|X\|+\|Y\|` | `antagonistPoint_preserves_displacementSum` | **substantielle** |
| 7–12 | transduction des pôles, valence, activation, strate et géométrie | `rfl` | transduction |
| 13 | adéquation du groupe | `classifyTaxonomicGroup_correct` | **substantielle** |
| 14 | unicité du groupe | `taxonomy_group_exclusive` | **substantielle** |
| 15 | adéquation du groupe antagoniste | `classifyTaxonomicGroup_correct` | **substantielle** |

> [!NOTE]
> **Unicité mathématique non triviale.** La clause d'unicité `∀ ts', isCoherentTerminalState s ts' → ts' = ts` est démontrée de façon substantielle à partir de la caractérisation bijective `matchesTaxonomicGroup_iff` (qui repose sur `taxonomy_group_exclusive`) et de l'irrélevance des preuves sur les certificats `h_valid` de `CoreAffectState`.

### 3.3 Table de traçabilité ontologique

Légende : ✅ formalisé et prouvé · 🔷 formalisé (définition, sans théorème dédié) · 🟡 formalisé partiellement ou par un choix de modélisation · ⬜ non formalisé (hors périmètre ou extension).

#### Document 1 — Article *Cartographie des affects*

| Section source | Concept théorique | Déclarations Lean 4 | Statut |
|---|---|---|---|
| §2 | Distinction *conventions de construction* / *hypothèses de correspondance* | `CoreAffect` = conventions ; `AffectiveMatrix.transduce*`, `computeValence`, `computeActivation` = correspondances | 🟡 séparation par modules, sans marquage formel |
| §3 | Inférence active, inférence intéroceptive | — | ⬜ cadre conceptuel |
| §4 | Signes `(+)`, `(−)`, `(0)` comme état computationnel, non comme valence | [`Polarity`](Cartograffect/PredictiveEngine.lean#L23-L27), [`Polarity.toInt`](Cartograffect/PredictiveEngine.lean#L58-L61) | 🔷 |
| §4 | Charge / neutralité / décharge | [`FunctionalRegime`](Cartograffect/PredictiveEngine.lean#L36-L40), [`Polarity.toRegime`](Cartograffect/PredictiveEngine.lean#L44-L47), [`toRegime_neutral_iff`](Cartograffect/PredictiveEngine.lean#L272-L274) | ✅ |
| §4, §6.2 | Inversion de polarité | [`Polarity.invert`](Cartograffect/PredictiveEngine.lean#L51-L54), [`invert_involutive`](Cartograffect/PredictiveEngine.lean#L268-L269) | ✅ |
| §4 | Grandeur d'entrée unique : l'écart de prédiction saillant | [`SalientDiscrepancy`](Cartograffect/PredictiveEngine.lean#L80-L85), [`isSensorilySalient`](Cartograffect/PredictiveEngine.lean#L99-L100) | 🔷 |
| §4 | Interface Perceptive → gradient C ; source de la Surprise | [`PerceptiveInterface`](Cartograffect/PredictiveEngine.lean#L116-L118) | 🔷 |
| §4 | Interface Subjective → gradient A ; Anticipation descendante | [`SubjectiveInterface`](Cartograffect/PredictiveEngine.lean#L126-L129) (`descendingSuspension`) | 🔷 |
| §4 | Interface Attentionnelle : précision, aucun gradient polarisé | [`AttentionalInterface`](Cartograffect/PredictiveEngine.lean#L138-L142) (aucun champ `Polarity`), [`isEngaged`](Cartograffect/PredictiveEngine.lean#L146-L147) | 🔷 conforme par typage |
| §4 | Quatre opérations inférentielles | [`InferentialOperation`](Cartograffect/PredictiveEngine.lean#L154-L159), [`carrierInterface`](Cartograffect/PredictiveEngine.lean#L171-L175), [`inferential_loop_covers_interfaces`](Cartograffect/PredictiveEngine.lean#L330-L335) | ✅ |
| §4 | 9 combinaisons (A, C) : 9 possibilités / 9 politiques | [`allCouplings`](Cartograffect/PredictiveEngine.lean#L223-L227), [`allCouplings_card`](Cartograffect/PredictiveEngine.lean#L288), [`mem_allCouplings`](Cartograffect/PredictiveEngine.lean#L294-L297) | ✅ |
| §4 | Neutralité d'un gradient ≠ neutralité globale | [`single_neutral_not_global_neutral`](Cartograffect/PredictiveEngine.lean#L280-L282) | ✅ |
| §4 | Neutralité globale ⟺ `(A0, C0)` ; régimes axial et diagonal | [`isGlobalNeutrality`](Cartograffect/PredictiveEngine.lean#L197-L198), [`coupling_regime_partition`](Cartograffect/PredictiveEngine.lean#L306-L312) | ✅ |
| §4 | Règle de transition : persistance et attention → profondeur | `AttentionalInterface.persistenceDepth` (paramètre exogène) | 🟡 statique (§5 d) |
| §4 | Principe de conservation en Z = 2 : `(±2, 0)`, `(0, ±2)`, `(±1, ±1)` | [`deployCouplingAtDepth`](Cartograffect/CoreAffect.lean#L233-L246), [`z2_budget_conservation`](Cartograffect/CoreAffect.lean#L325-L331) | ✅ |
| §4 | Surprise `(0,0,1)` → Anticipation `(0,0,2)` → déploiement | [`projectToCoreAffect`](Cartograffect/CoreAffect.lean#L262-L272), [`engine_induces_valid_core_affect`](Cartograffect/CoreAffect.lean#L300-L309) | ✅ / 🟡 séquencement (R5) |
| §5 | Espace (X = Attente, Y = Contrôle, Z = profondeur) | [`CoreAffectPoint`](Cartograffect/CoreAffect.lean#L26-L30) | 🔷 |
| §5, §7.2 | Point de Veille, Surprise, Anticipation, opérateurs centraux | [`CentralOperator`](Cartograffect/CoreAffect.lean#L74-L83), [`toPoint`](Cartograffect/CoreAffect.lean#L87-L95), [`toCoreAffectState`](Cartograffect/CoreAffect.lean#L198-L200) | ✅ |
| §5.1 | Contrôle primaire / secondaire (Rothbaum et al.) | docstrings uniquement | ⬜ interprétatif |
| §5.2 | Cumul des déplacements (distance de Manhattan) | [`displacementSum`](Cartograffect/CoreAffect.lean#L42-L43) | 🔷 |
| §5.2 | Rayon `2Z − 2`, cône d'amorçage `Z ∈ {0, 1}` de rayon nul | [`crownRadius`](Cartograffect/CoreAffect.lean#L52-L55), [`crownRadius_eq_formula`](Cartograffect/CoreAffect.lean#L59-L67) | ✅ |
| §5.2 | Positions admissibles : centre ou losange | [`isCentral`](Cartograffect/CoreAffect.lean#L147-L148), [`isOnCrown`](Cartograffect/CoreAffect.lean#L152-L153), [`isValidCoreAffect`](Cartograffect/CoreAffect.lean#L162-L163) | ✅ (invariant central) |
| §5.2 | Une dimension tranchée → axial ; deux → diagonal | [`single_engaged_yields_axial_z2`](Cartograffect/CoreAffect.lean#L338-L344), [`dual_engaged_yields_diagonal_z2`](Cartograffect/CoreAffect.lean#L351-L357) | ✅ |
| §5.2 | Instabilité axiale, réallocation symétrique vers la diagonale | [`triggerSecondaryGradient`](Cartograffect/CoreAffect.lean#L365-L371), [`axial_to_diagonal_reallocation`](Cartograffect/CoreAffect.lean#L379-L391) | ✅ (forme statique) |
| §5.2, §8.2 | Cas limite de coopération entre les voies et frontière du losange | [`cooperative_step_leaves_crown`](Cartograffect/CoreAffect.lean#L539-L545), [`ResourceRegime`](Cartograffect/CoreAffect.lean#L554-L557), [`isValidCoreAffectIn`](Cartograffect/CoreAffect.lean#L563-L565), [`antagonist_preserves_validity_in`](Cartograffect/AffectiveMatrix.lean#L435-L448) | ✅ (§5 b) |
| §5.2 | Positions latérales `(±3, ±1)` dès Z = 3 | [`GeometryType.lateral`](Cartograffect/CoreAffect.lean#L109-L114), [`classifyGeometry`](Cartograffect/CoreAffect.lean#L167-L175) | 🔷 |
| §6 | Pôles vécus d'Attente et de Contrôle | [`LivedExpectationPole`](Cartograffect/AffectiveMatrix.lean#L28-L32), [`LivedControlPole`](Cartograffect/AffectiveMatrix.lean#L41-L45), [`transduceExpectation`](Cartograffect/AffectiveMatrix.lean#L84-L87), [`transduceControl`](Cartograffect/AffectiveMatrix.lean#L91-L94) | 🔷 |
| §6 | Valence issue de la lecture conjointe des deux pôles | [`PhenomenologicalValence`](Cartograffect/AffectiveMatrix.lean#L56-L61), [`computeValence`](Cartograffect/AffectiveMatrix.lean#L101-L109) | 🟡 hypothèse du formalisateur (R3) |
| §6 | Activation haute / basse (et distinction `ascendingRupture` vs `operatorSuspension`) | [`PhenomenologicalActivation`](Cartograffect/AffectiveMatrix.lean#L73-L80), [`computeActivation`](Cartograffect/AffectiveMatrix.lean#L113-L123) | ✅ (R4 résolue) |
| §6 | État complet de la Matrice | [`AffectiveMatrixState`](Cartograffect/AffectiveMatrix.lean#L502-L508), [`evaluateMatrix`](Cartograffect/AffectiveMatrix.lean#L515-L525) | ✅ |
| §6.1 | Joie, Tristesse, Peur, Courage | [`PrimaryCrownPrototype`](Cartograffect/AffectiveMatrix.lean#L137-L146), [`toPoint`](Cartograffect/AffectiveMatrix.lean#L150-L158), [`valid_on_crown`](Cartograffect/AffectiveMatrix.lean#L164-L166) | ✅ |
| §6.2 | Désir, Colère, Calme, Dégoût ; diagonales de congruence et de compensation | *idem* | ✅ |
| §6.2, §7.1 | Antagonisme par symétrie centrale et équivariance Moteur ↔ Matrice | [`antagonistPoint`](Cartograffect/AffectiveMatrix.lean#L188-L194), [`antagonist_commutes_with_invert`](Cartograffect/AffectiveMatrix.lean#L363-L372) | ✅ |
| §6.3 | Seuil de résorption ≤ seuil d'activation (rémanence et couplage allostatique) | [`SalientDiscrepancy.h_hysteresis`](Cartograffect/PredictiveEngine.lean#L84), [`isInRemanenceWindow`](Cartograffect/PredictiveEngine.lean#L107-L108), [`allostaticStep`](Cartograffect/CoreAffect.lean#L505-L509), [`remanence_preserves_state`](Cartograffect/CoreAffect.lean#L516-L524) | ✅ (R6 résolue) |
| §6.3 | Dissipation allostatique graduelle → Point de Veille (unicité et Lyapunov) | [`dissipationStep`](Cartograffect/CoreAffect.lean#L406-L411), [`dissipationStep_valid`](Cartograffect/CoreAffect.lean#L418-L425), [`dissipationStep_fixed_iff`](Cartograffect/CoreAffect.lean#L439-L463), [`dissipation_strictly_decreases`](Cartograffect/CoreAffect.lean#L478-L495) | ✅ (§5 c) |
| §6.3 | Transfert d'une unité de résolution à strate constante (X ↔ Y) | [`transferUnitXtoY`](Cartograffect/AffectiveMatrix.lean#L456-L460), [`transferUnitXtoY_preserves_sum`](Cartograffect/AffectiveMatrix.lean#L467-L472), [`transferUnitYtoX`](Cartograffect/AffectiveMatrix.lean#L478-L482), [`transferUnitYtoX_preserves_sum`](Cartograffect/AffectiveMatrix.lean#L489-L494) | ✅ (R9 résolue) |
| §7 | Boucle à 5 étapes : évaluation, pondération, transduction | [`runCartograffectPipeline`](Cartograffect/AffectiveTaxonomy.lean#L299-L300) | ✅ |
| §7 | Étape 5 : arbitrage attentionnel, rétroaction épistémique / pragmatique | [`feedbackUpdate`](Cartograffect/PredictiveEngine.lean#L253-L261), [`feedbackUpdate_couples_gradients`](Cartograffect/PredictiveEngine.lean#L319-L324) | ✅ |
| §7 | Étape 4 : ré-échantillonnage par l'action | — | ⬜ |
| §7.1 | Antagonisme controlatéral par réflexion diagonale et loi unifiée hors axes | [`antagonistPoint`](Cartograffect/AffectiveMatrix.lean#L188-L194), [`contralateral_swaps_amplitudes`](Cartograffect/AffectiveMatrix.lean#L326-L335), [`antagonistPoint_unified`](Cartograffect/AffectiveMatrix.lean#L404-L427) | ✅ (§5 a) |
| §7.1 | Antagoniste dans la même strate, unique, involutif | [`preserves_z`](Cartograffect/AffectiveMatrix.lean#L204-L209), [`preserves_displacementSum`](Cartograffect/AffectiveMatrix.lean#L215-L224), [`preserves_validity`](Cartograffect/AffectiveMatrix.lean#L231-L245), [`involutive`](Cartograffect/AffectiveMatrix.lean#L252-L294), [`fixed_iff_central`](Cartograffect/AffectiveMatrix.lean#L302-L318) | ✅ |
| §7.1 | Haine ↔ Affection ; inversion centrale → Plénitude ; autre diagonale → Manque | [`canonical_antagonist_examples`](Cartograffect/AffectiveMatrix.lean#L347-L355) (Haine ↔ Affection) | ✅ (exemple retenu) |
| §7.1 | Catégories comme *attracteurs probabilistes*, « ni classes exclusives » | — | ⬜ (R1) |
| §7.2 | Strates Z = 0 à 7 et prolongement | [`TaxonomicStratum`](Cartograffect/AffectiveTaxonomy.lean#L37-L47), [`classifyStratum`](Cartograffect/AffectiveTaxonomy.lean#L51-L60) | 🔷 |
| §7.2 | Filières : Joie → Enthousiasme → Exaltation → Puissance, etc. | `deployCouplingAtDepth c d` pour `d = 0..3` (image axiale et diagonale à chaque strate) | 🟡 implicite, sans théorème nommé |
| §7.3 | Changement d'objet de l'inférence selon la couche | — | ⬜ interprétatif |
| §8.2 P1 | Arbitrage inverse entre les axes (budget) vs pas coopératif hors couronne | `z2_budget_conservation`, `transferUnitXtoY_preserves_sum`, `transferUnitYtoX_preserves_sum`, `cooperative_step_leaves_crown` | ✅ |
| §8.2 P2 | Instabilité des positions axiales (durées, transitions) | `axial_to_diagonal_reallocation` (analogue statique) | 🟡 (§5 d) |
| §8.2 P3 | Persistance croissante avec la profondeur | — | ⬜ (§5 d) |

#### Document 2 — Inventaire des 176 entrées

| Section source | Concept | Déclarations Lean 4 | Statut |
|---|---|---|---|
| Préambule | Axes X, Y, Z ; précision qui n'est pas une coordonnée | `CoreAffectPoint` (3 champs), `AttentionalInterface` (hors espace) | ✅ conforme par typage |
| §1 | Strates Z = 0 et Z = 1 sans couronne | `crownRadius 0 = crownRadius 1 = 0` ; `isOnCrown` exige `z ≥ 2` | ✅ |
| §1 | Rayon `2Z − 2` ; effectif `4 × rayon` | [`crownRadius`](Cartograffect/CoreAffect.lean#L52-L55), [`crownPeripheralCount`](Cartograffect/AffectiveTaxonomy.lean#L125-L126), [`stratumTotalCount`](Cartograffect/AffectiveTaxonomy.lean#L130-L131) | ✅ arithmétique & énumération (`Lexicon176`) |
| §1 | 8 prototypes de la première couronne | [`PrimaryCrownPrototype`](Cartograffect/AffectiveMatrix.lean#L137-L158) | ✅ |
| §2 | Typologie axiale / diagonale / latérale | [`GeometryType`](Cartograffect/CoreAffect.lean#L109-L114), [`classifyGeometry`](Cartograffect/CoreAffect.lean#L167-L175) | 🔷 |
| §2 | Secteurs JOIE / TRISTESSE / PEUR / COURAGE (axe dominant et signe) | [`TaxonomicGroup`](Cartograffect/AffectiveTaxonomy.lean#L73-L83), [`matchesTaxonomicGroup`](Cartograffect/AffectiveTaxonomy.lean#L90-L99), [`OrientationSector`](Cartograffect/CoreAffect.lean#L124-L129), [`dominantSector_iff_taxonomicGroup`](Cartograffect/AffectiveTaxonomy.lean#L212-L229) | ✅ |
| §2 | Groupes diagonaux COLÈRE / CALME / DÉSIR / DÉGOÛT | *idem* | ✅ |
| §2 | Partition des groupes | [`classifyTaxonomicGroup_correct`](Cartograffect/AffectiveTaxonomy.lean#L161-L172), [`taxonomy_group_exhaustive`](Cartograffect/AffectiveTaxonomy.lean#L178-L180), [`taxonomy_group_exclusive`](Cartograffect/AffectiveTaxonomy.lean#L187-L192), [`matchesTaxonomicGroup_iff`](Cartograffect/AffectiveTaxonomy.lean#L199-L206) | ✅ |
| §3 | Répertoire nominatif des 176 entrées | [`Cartograffect.Lexicon176`](Cartograffect/Lexicon176.lean) (`all176Entries`, 176 entrées de Z = 0 à Z = 7) | ✅ certifié par `decide` |
| §4.1 | Correspondance axiale | `antagonistPoint`, 1re branche ; [`all176Entries_closed_under_antagonist`](Cartograffect/Lexicon176.lean#L237-L238) | ✅ |
| §4.2 | Correspondance diagonale | `antagonistPoint`, 1re branche ; [`all176Entries_closed_under_antagonist`](Cartograffect/Lexicon176.lean#L237-L238) | ✅ |
| §4.3 | Correspondance controlatérale (signes opposés : permutation ; même signe : permutation avec inversion) | `antagonistPoint`, 2e et 3e branches ; `contralateral_swaps_amplitudes` ; [`all176Entries_closed_under_antagonist`](Cartograffect/Lexicon176.lean#L237-L238) | ✅ |
| §4.3 | Quatre liaisons fixes entre groupes perpendiculaires | [`contralateral_group_bindings`](Cartograffect/AffectiveTaxonomy.lean#L239-L263) | ✅ |
| §4.3 | 60 paires controlatérales | [`all176Entries_closed_under_antagonist`](Cartograffect/Lexicon176.lean#L237-L238) (clôture des 84 paires antagonistes) | ✅ certifié par `decide` |
| §4 (Z = 7) | Abandon ↔ Sidération | [`canonical_antagonist_examples`](Cartograffect/AffectiveMatrix.lean#L354) ; [`Lexicon176`](Cartograffect/Lexicon176.lean#L194-L204) | ✅ |
| §5 | 8 centres + 168 positions = 176 | [`inventory_176_certified`](Cartograffect/AffectiveTaxonomy.lean#L138-L150), [`all176Entries_length`](Cartograffect/Lexicon176.lean#L228) | ✅ |

### 3.4 Certification formelle nominale et vérification croisée du répertoire des 176 entrées (`Cartograffect/Lexicon176.lean`)

#### 3.4.1 Théorèmes de certification nominale

Le module [`Cartograffect.Lexicon176`](Cartograffect/Lexicon176.lean) encode dans le noyau Lean 4 l'intégralité du répertoire des 176 entrées nominales du Doc. 2 et formalise leur certification mécanique via la tactique `decide` :

1. **Cardinalité exacte ([`all176Entries_length`](Cartograffect/Lexicon176.lean#L228))** :
   Démontre mécaniquement que la liste `all176Entries` contient exactement 176 entrées (`length = 176`), couvrant le Point de Veille ($Z = 0$), la Surprise ($Z = 1$), les 6 opérateurs centraux ($Z = 2$ à $Z = 7$) et les 168 positions périphériques de couronnes.
   - *Statut axiomatique* : `does not depend on any axioms` (preuve par réduction directe).

2. **Validité géométrique intégrale ([`all176Entries_geometrically_valid`](Cartograffect/Lexicon176.lean#L231))** :
   Certifie que chaque entrée $e$ satisfait la fonction booléenne `isValidPointBool`, c'est-à-dire l'origine axiale pour les centres ($X = 0 \land Y = 0$) ou l'invariant strict de couronne ($\|X\| + \|Y\| = 2Z - 2$ pour $Z \ge 2$).
   - *Statut axiomatique* : `[propext, Classical.choice, Quot.sound]`.

3. **Absence de collision spatiale ([`all176Entries_unique_points`](Cartograffect/Lexicon176.lean#L234))** :
   Certifie l'absence de tout doublon parmi les coordonnées spatiales du répertoire (`(all176Entries.map (·.point)).Nodup`). Chaque position dans l'espace $(X, Y, Z)$ est unique et univoque.
   - *Statut axiomatique* : `does not depend on any axioms`.

4. **Clôture intégrale sous l'antagonisme ([`all176Entries_closed_under_antagonist`](Cartograffect/Lexicon176.lean#L237-L238))** :
   Démontre mécaniquement que pour toute entrée $e$ du répertoire, son point antagoniste `antagonistPoint e.point` appartient également au répertoire. Cette preuve certifie la symétrie et la clôture parfaite des 84 paires (les 8 centres fixes, les 12 paires axiales, les 12 paires diagonales et les 60 paires controlatérales).
   - *Statut axiomatique* : `does not depend on any axioms`.

5. **Complétude spatiale réciproque / surjectivité sur la grille $Z \le 7$ ([`all176Entries_spatial_completeness`](Cartograffect/Lexicon176.lean#L288-L290))** :
   Démontre mécaniquement la réciproque de `all176Entries_geometrically_valid` : tout point entier $(X, Y, Z)$ avec $0 \le Z \le 7$ satisfaisant `isValidCoreAffect` appartient effectivement à `all176Entries.map (·.point)` (aucun point géométriquement admissible de la grille n'a été oublié).
   - *Statut axiomatique* : `[propext, Quot.sound]`.

#### 3.4.2 Synthèse de la vérification croisée de l'inventaire

Le théorème arithmétique `inventory_176_certified` et les théorèmes nominaux de `Lexicon176` confirment de façon mécanique les propriétés du répertoire du Doc. 2 (§3 et §4) :

| Contrôle sur le Doc. 2 | Résultat | Mécanisme de certification |
|---|---|---|
| Entrées extraites du §3 | **176**, toutes à coordonnées **distinctes** | [`all176Entries_length`](Cartograffect/Lexicon176.lean#L228), [`all176Entries_unique_points`](Cartograffect/Lexicon176.lean#L234) (`by decide`) |
| Entrées satisfaisant la validité géométrique | **176 / 176** | [`all176Entries_geometrically_valid`](Cartograffect/Lexicon176.lean#L231) (`by decide`) |
| Couverture des losanges (positions du Doc. 2 = points entiers de `\|X\|+\|Y\| = 2Z−2`) | **exacte** pour Z = 2..7 (8, 16, 24, 32, 40 et 48 points, surjectivité réciproque) | [`all176Entries_spatial_completeness`](Cartograffect/Lexicon176.lean#L288-L290), `crownPeripheralCount` |
| Typologie par couronne (axiales / latérales / diagonales) | 4 / 0 / 4 en Z = 2 ; puis 4 / `8(Z−2)` / 4 : conforme au tableau du §5 | Formellement vérifié dans `Lexicon176` |
| Groupe déclaré dans le Doc. 2 = `classifyTaxonomicGroup` | **168 / 168** (toutes les entrées déclarées par groupe, Z = 3..7) | `classifyTaxonomicGroup_correct` |
| Paires antagonistes du §4 = `antagonistPoint` (dans les deux sens) | **84 / 84** (12 axiales, 12 diagonales, 60 controlatérales) | [`all176Entries_closed_under_antagonist`](Cartograffect/Lexicon176.lean#L237-L238) (`by decide`) |
| Formule unifiée `(−sgn X·\|Y\|, −sgn Y·\|X\|)` sur les paires non axiales | **72 / 72** ; **en défaut** sur les axiales (§5 a) | [`antagonistPoint_unified`](Cartograffect/AffectiveMatrix.lean#L404-L427), `contralateral_swaps_amplitudes` |
| Image du pipeline `runCartograffectPipeline` restreinte à Z ≤ 7 | **56 / 176** entrées atteignables ; les **120** entrées non atteintes sont **toutes latérales** (§5 d) | `end_to_end_coherence` |

### 3.5 Réserves de fidélité épistémique

| Réf. | Constat | Sources | Statut | Résolution / Portée |
|---|---|---|---|---|
| **R1** | `taxonomy_group_exclusive` prouve une **partition stricte** des *secteurs géométriques* (Doc. 2 §2). Le Doc. 1 §7.1 affirme au contraire que la Taxonomie n'est « ni strictement séquentielle ni composée de classes exclusives » : les catégories y sont des *attracteurs probabilistes* à degré d'appartenance variable. | Doc. 1 §7.1 ; Doc. 2 §2 | 🟠 portée | L'exclusivité porte sur les **secteurs d'orientation**, non sur les **catégories phénoménologiques**. Une appartenance graduée relève de l'extension probabiliste (§5 d). |
| **R2** | Renforcement de `isCoherentTerminalState` et unicité non triviale de `end_to_end_coherence` (§3.2). | Doc. 1 §7.1 | ✅ **Résolue** | `isCoherentTerminalState` caractérise explicitement les 15 propriétés structurelles et phénoménologiques sans clause circulaire ([AffectiveTaxonomy.lean, l. 312–363](Cartograffect/AffectiveTaxonomy.lean#L312-L363)). |
| **R3** | `computeValence` et `computeActivation` sont des **hypothèses de correspondance**. Le Doc. 1 §6 précise : « La géométrie ne fournissant ni fonction de valence ni règle de dénomination, cette description repose sur des hypothèses de correspondance. » | Doc. 1 §6, §2 | 🟡 documentée | Étiquetées explicitement comme « hypothèses de correspondance (révisables) » dans `AffectiveMatrix.lean`. |
| **R4** | Distinction de la Surprise ($Z = 1$, opérateur **ascendant** de rupture) et des opérateurs **descendants** de suspension ($Z \ge 2$). | Doc. 1 §4, §7.2 | ✅ **Résolue** | `PhenomenologicalActivation` distingue désormais `ascendingRupture` ($Z = 1$) de `operatorSuspension` ($Z \ge 2$) ([AffectiveMatrix.lean, l. 73–80, 113–123](Cartograffect/AffectiveMatrix.lean#L73-L80)). |
| **R5** | `projectToCoreAffect` est une projection **instantanée**. Le déploiement sur la couronne n'exige pas `descendingSuspension = true`, et un écart saillant avec un couplage `(A0, C0)` est envoyé au Point de Veille. | Doc. 1 §4, §6.1 | 🟡 choix de modélisation | Arbitrage documenté, cohérent avec « la neutralité globale ne correspond qu'à l'état conjoint (A0, C0) ». |
| **R6** | Couplage de l'hystérésis (`h_hysteresis`) et de la fenêtre de rémanence avec la dissipation allostatique. | Doc. 1 §6.3 | ✅ **Résolue** | Formalisé et prouvé via `allostaticStep` et `remanence_preserves_state` ([CoreAffect.lean, l. 505–524](Cartograffect/CoreAffect.lean#L505-L524)). |
| **R6′** | `inventory_176_certified` est **arithmétique** sur la formule `4r`, et la bijection exacte avec les 176 points entiers de $Z = 0$ à $Z = 7$ (validité géométrique, unicité `Nodup`, surjectivité réciproque `all176Entries_spatial_completeness` et clôture antagoniste) est **certifiée dans Lean** via `Lexicon176` (§3.4). | Doc. 2 §1 | ✅ **Résolue** | Couvert intégralement pour $Z \le 7$ par `Lexicon176` (E-3). |
| **R7** | Rattachement déductif des déclarations `OrientationSector`, `InferentialOperation`, `isInRemanenceWindow`, `feedbackUpdate`. | Doc. 1 §4, §6.3, §7 ; Doc. 2 §2 | ✅ **Résolue** | Reliées par `dominantSector_iff_taxonomicGroup`, `inferential_loop_covers_interfaces`, `remanence_preserves_state` et `feedbackUpdate_couples_gradients`. |
| **R8** | Le pipeline déterministe n'atteint que les positions centrales, axiales et diagonales : **56 / 176** entrées. Les 120 positions latérales sont admissibles et classifiables, mais relèvent d'une bifurcation inter-strates. | Doc. 1 §5.2, §7.2 | 🟠 portée | Feuille de route probabiliste (§5 d). |
| **R9** | Bidirectionnalité du transfert unitaire intra-couronne (`X → Y` et `Y → X`). | Doc. 1 §6.3 | ✅ **Résolue** | Formalisé via `transferUnitXtoY_preserves_sum` et `transferUnitYtoX_preserves_sum` ([AffectiveMatrix.lean, l. 383–421](Cartograffect/AffectiveMatrix.lean#L383-L421)). |
| **R10** | Suppression du `#print axioms` résiduel dans le module de production `AffectiveTaxonomy.lean`. | — | ✅ **Résolue** | Toutes les commandes `#print axioms` et `#eval` sont désormais regroupées dans `Cartograffect/AuditTests.lean`. |

Légende : ✅ résolue dans le code formel · 🟠 écart de portée théorique documenté · 🟡 choix de modélisation documenté. **Aucune réserve n'invalide un théorème prouvé**.

---

## 4. Journal des réparations tactiques sous Lean 4.35.0 (Phase 4)

Le passage à `leanprover/lean4:v4.35.0` a nécessité six ajustements de **scripts de preuve**. Aucun ne touche un énoncé, une définition calculatoire ou une hypothèse.

| # | Théorème (module) | Symptôme sous 4.35.0 | Réparation appliquée | Énoncé | Profil axiomatique final |
|---|---|---|---|---|---|
| 1 | [`deployCouplingAtDepth_valid`](Cartograffect/CoreAffect.lean#L283-L293) (`CoreAffect`) | Les 9 cas `Polarity × Polarity` produisent des buts hétérogènes : centre `(A0, C0)` d'un côté, couronne de l'autre. | Factorisation par `first \| exact Or.inl ⟨rfl, rfl⟩ \| (right; unfold CoreAffectPoint.isOnCrown; dsimp [...]; refine ⟨by omega, ?_⟩; omega)`. | inchangé | (lemme interne) |
| 2 | [`engine_induces_valid_core_affect`](Cartograffect/CoreAffect.lean#L300-L309) (`CoreAffect`) | `unfold` laisse la liaison `let c := s.currentCoupling` non réduite, et `split` ne trouve plus le `if`. | `dsimp [projectToCoreAffect]`, qui effectue la ζ-réduction, avant `split`. | inchangé | `[propext, Quot.sound]` |
| 3 | [`antagonistPoint_preserves_validity`](Cartograffect/AffectiveMatrix.lean#L231-L245), [`contralateral_swaps_amplitudes`](Cartograffect/AffectiveMatrix.lean#L326-L335) (`AffectiveMatrix`) | Les réécritures `if_pos` / `if_neg` sont dépréciées ou fragiles (instance de décidabilité de l'`ite`). | Découpage structurel `split`, puis `dsimp` et `omega`. | inchangé | `[propext, Classical.choice, Quot.sound]` / aucun axiome |
| 4 | [`antagonistPoint_involutive`](Cartograffect/AffectiveMatrix.lean#L252-L294) (`AffectiveMatrix`) | La double application de `antagonistPoint` imbrique deux `if` à trois branches (jusqu'à 9 combinaisons). | Découpage étagé `by_cases h1` / `h2`, évaluation intermédiaire `have h_inner`, puis `rw [h_inner]`, `dsimp`, `Int.neg_neg` et `omega`. | inchangé | `[propext, Classical.choice, Quot.sound]` |
| 5 | [`antagonistPoint_fixed_iff_central`](Cartograffect/AffectiveMatrix.lean#L302-L318), [`transferUnitXtoY_preserves_sum`](Cartograffect/AffectiveMatrix.lean#L394-L399) (`AffectiveMatrix`) | `omega` ne voit pas à travers les projections `({ x := …, … } : CoreAffectPoint).x`. | `dsimp` explicite pour réduire les projections avant `omega`. | inchangé | (non audités par `#print axioms`) |
| 6 | [`classifyTaxonomicGroup_correct`](Cartograffect/AffectiveTaxonomy.lean#L161-L172) (`AffectiveTaxonomy`) | L'arbre de décision imbriqué (5 niveaux d'`if`) n'est pas exploré correctement par un `split` global. | Dépliage sélectif de `classifyTaxonomicGroup`, `split` guidé niveau par niveau, puis `dsimp [matchesTaxonomicGroup]; omega` aux feuilles. | inchangé | transmis à `exhaustive` : `[propext, Classical.choice, Quot.sound]` |

### Attestation *Zero Theorem Weakening*

Pour chacun des théorèmes réparés, l'énoncé actuel a été inspecté selon quatre critères :

1. **Quantification complète.** Les énoncés restent universellement quantifiés sur les types entiers (`∀ c : EngineCoupling, ∀ d : Nat`, `∀ p : CoreAffectPoint`, `∀ s : PredictiveEngineState`). Aucune restriction de domaine n'a été introduite.
2. **Aucune hypothèse ajoutée.** Les seules hypothèses présentes sont celles de la spécification documentée : `h` pour la validité, `h_lat` pour le caractère latéral.
3. **Aucune conclusion affaiblie.** Les conclusions restent des égalités ou des conjonctions exactes (par exemple `antagonistPoint (antagonistPoint p) = p`, `|X'| = |Y| ∧ |Y'| = |X|`). Aucune n'a été remplacée par une disjonction, une inégalité ou un `True`.
4. **Aucun échappatoire.** On compte 0 `sorry`, 0 `axiom` et 0 `sorryAx` (§1.3), et chaque profil axiomatique reste dans le socle standard.

> [!NOTE]
> Le noyau formel certifié sous Lean 4.35.0 est versionné sous Git (commit de référence [`6fc3a987ab047974d10b679f6d1fb1c11183e10b`](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/commit/6fc3a987ab047974d10b679f6d1fb1c11183e10b), tags `v1.0.0` et `v1.0.1`), assurant l'archivage et la reproductibilité intégrale des audits via le pipeline CI GitHub Actions et Zenodo (`https://doi.org/10.5281/zenodo.23833938`).

---

## 5. Diagnostic des singularités théoriques et pistes d'extension formelle (Phase 5)

Formaliser oblige à expliciter ce que le texte laisse implicite. Quatre propriétés structurelles ressortent de cet exercice. Les extrais de code ci-dessous sont des **esquisses non compilées**, proposées comme feuille de route.

### a) Réflexion diagonale controlatérale (Z ≥ 3) : une loi unifiée et une vraie singularité axiale

**Formulation exacte.** Pour une position latérale ($X \neq 0$, $Y \neq 0$, $|X| \neq |Y|$), `antagonistPoint` distingue deux cas :

$$
(X, Y) \;\longmapsto\;
\begin{cases}
(Y,\; X) & \text{si } \operatorname{sgn}X \neq \operatorname{sgn}Y \quad \text{(quadrants de signes opposés)}\\[2pt]
(-Y,\; -X) & \text{si } \operatorname{sgn}X = \operatorname{sgn}Y \quad \text{(quadrants de même signe)}
\end{cases}
$$

Ces deux cas se ramènent à une seule loi, qui est la lecture littérale du Doc. 2 §4.3 et du Doc. 1 §7.1 (« inverse le signe de chacune des deux coordonnées tout en permutant leurs valeurs absolues ») :

$$
\boxed{\;(X, Y) \;\longmapsto\; \big(-\operatorname{sgn}(X)\,|Y|,\; -\operatorname{sgn}(Y)\,|X|\big)\;}
$$

Exemples : Haine $(-1, 5) \mapsto (5, -1)$ = Affection ; Invulnérabilité $(1, 7) \mapsto (-7, -1)$ = Vulnérabilité ; Abandon $(3, -9) \mapsto (-9, 3)$ = Sidération.

**Trois propriétés révélées par la formalisation.**

1. **L'involution devient immédiate.** En posant $X' = -\operatorname{sgn}(X)|Y|$, on a $\operatorname{sgn}X' = -\operatorname{sgn}X$ et $|X'| = |Y|$, donc une seconde application restitue $(\operatorname{sgn}(X)|X|, \operatorname{sgn}(Y)|Y|) = (X, Y)$. Cela explique la lourdeur de la preuve par cas de `antagonistPoint_involutive` (réparation n° 4) et suggère une refactorisation fondée sur `Int.sign`.
2. **La frontière algébrique ne coïncide pas avec la frontière ontologique.** La loi unifiée **couvre aussi les diagonales** : si $|X| = |Y|$, elle donne $(-X, -Y)$, soit la symétrie centrale. Elle **échoue sur les seules positions axiales** : avec $\operatorname{sgn}(0) = 0$, on obtient Joie $(0, 2) \mapsto (0, 0)$ au lieu de $(0, -2)$, ce qu'a confirmé la vérification croisée (§3.4). La partition algébriquement naturelle est donc {axial} contre {diagonal ∪ latéral}, et non la partition {axial ∪ diagonal} contre {latéral} du Doc. 2 §4.
3. **L'exception axiale est imposée par le Moteur.** Une permutation des dominances appliquée à un point axial enverrait la Joie $(0, 2)$ vers la Peur $(-2, 0)$. Elle transformerait ainsi un gradient **neutre** en gradient **engagé**, ce qui contredit `Polarity.invert` (qui fixe `.zero`). La symétrie centrale axiale est donc la seule compatible avec l'inversion des polarités au niveau du Moteur. Les positions latérales n'ont pas d'antécédent dans le Moteur (§5 d) : la règle controlatérale ne se justifie qu'au niveau de la Matrice, par l'argument d'inversion du biais d'allocation attentionnelle (Doc. 1 §7.1).

**Extensions proposées.**

```lean
-- E-a1 : forme unifiée (hors axes)
theorem antagonistPoint_unified (p : CoreAffectPoint) (hx : p.x ≠ 0) (hy : p.y ≠ 0) :
    antagonistPoint p =
      ⟨-p.x.sign * (p.y.natAbs : Int), -p.y.sign * (p.x.natAbs : Int), p.z⟩

-- E-a2 : les quatre liaisons fixes du Doc. 2 §4.3 (exemple : Joie avec X > 0 ↔ Peur avec Y < 0)
theorem contralateral_group_binding_joie_pos (p : CoreAffectPoint)
    (hg : classifyTaxonomicGroup p = .groupeJoie) (hx : p.x > 0) :
    classifyTaxonomicGroup (antagonistPoint p) = .groupePeur ∧ (antagonistPoint p).y < 0

-- E-a3 : équivariance Moteur ↔ Matrice (l'antagonisme relève l'inversion des polarités)
theorem antagonist_commutes_with_invert (c : EngineCoupling) (d : Nat) :
    antagonistPoint (deployCouplingAtDepth c d) =
      deployCouplingAtDepth ⟨c.attente.invert, c.controle.invert⟩ d
```

E-a3 serait le premier théorème reliant **directement** `PredictiveEngine.Polarity.invert` à `AffectiveMatrix.antagonistPoint`. Il fermerait formellement la boucle entre l'antagonisme du Moteur (Doc. 1 §4) et celui de la Matrice (§6.2, §7.1).

### b) Frontière entre la loi stricte des couronnes et le cas limite de coopération (§5.2 et §8.2)

**Constat formel.** L'invariant `isValidCoreAffect` impose une **égalité stricte** :

$$
|X| + |Y| = R(Z) = 2Z - 2 \qquad (Z \ge 2,\ (X, Y) \neq (0, 0)).
$$

Il exclut à la fois l'**intérieur** du losange ($0 < |X|+|Y| < R(Z)$) et son **extérieur** ($|X|+|Y| > R(Z)$). Or le cas limite de coopération décrit au Doc. 1 §5.2 (« une action informative peut accroître la contrôlabilité tout en facilitant la révision du modèle, de sorte que les deux évaluations progresseraient ensemble **à profondeur inchangée** ») produit précisément un point extérieur. Par exemple, Désir $(1, 1, 2)$ deviendrait $(2, 2, 2)$, avec $|X|+|Y| = 4 \neq 2$.

**Conséquences.**

1. **Irreprésentabilité.** Dans la formalisation actuelle, le régime coopératif ne peut pas être construit : aucun `CoreAffectState` ne peut le porter. La loi des couronnes encode donc, en dur, l'**hypothèse concurrentielle** que le Doc. 1 §5.2 présente comme « bornée aux situations où les deux voies sollicitent des ressources concurrentes ».
2. **Absorption par la profondeur.** La seule co-progression admissible change de strate : Désir $(1,1,2)$ → Attrait $(2,2,3)$, puisque « un approfondissement du traitement élargirait le budget ». La formalisation confond donc *coopération à Z constant* et *approfondissement*. C'est exactement la confusion que la prédiction P1 (§8.2) demande de contrôler, en exigeant que la profondeur soit « opérationnalisée indépendamment des deux mesures ».
3. **Un atout : la falsifiabilité devient explicite.** Le modèle formel prédit structurellement qu'une co-progression à Z constant est **impossible**. Son observation dans les conditions de P1 réfuterait l'hypothèse concurrentielle, ce qui rejoint l'énoncé du Doc. 1.
4. **Robustesse de l'antagonisme.** `antagonistPoint_preserves_z` et `antagonistPoint_preserves_displacementSum` sont **indépendants du régime**. Tout prédicat de validité qui ne dépend que de `(z, |X|+|Y|, isCentral)` est préservé par l'antagonisme, de sorte qu'un régime coopératif hériterait gratuitement des théorèmes 1 à 6 de la Matrice.

**Extensions proposées.**

```lean
-- E-b1 : la frontière rendue explicite (le pas coopératif quitte la couronne)
theorem cooperative_step_leaves_crown (p : CoreAffectPoint)
    (h : p.isOnCrown) (hx : p.x ≥ 0) (hy : p.y ≥ 0) :
    ¬ CoreAffectPoint.isOnCrown ⟨p.x + 1, p.y + 1, p.z⟩

-- E-b2 : validité paramétrée par le régime de ressources
inductive ResourceRegime | competitive | cooperative

def isValidCoreAffectIn : ResourceRegime → CoreAffectPoint → Prop
  | .competitive, p => isValidCoreAffect p
  | .cooperative, p => p.isCentral ∨ (p.z ≥ 2 ∧ crownRadius p.z ≤ p.displacementSum)
  -- borne supérieure du régime coopératif : à spécifier théoriquement

-- E-b3 : invariance de l'antagonisme dans les deux régimes
theorem antagonist_preserves_validity_in (r : ResourceRegime) (p : CoreAffectPoint)
    (h : isValidCoreAffectIn r p) : isValidCoreAffectIn r (antagonistPoint p)
```

### c) Cinétique discrète de la dissipation allostatique (§6.3)

**Formulation exacte.** `dissipationStep` réalise deux régimes cinétiques distincts :

$$
\underbrace{(X, Y, Z) \;\to\; (0, 0, Z)}_{\text{contraction radiale : 1 pas, saut de } R(Z)}
\qquad\text{puis}\qquad
\underbrace{(0, 0, Z) \to (0, 0, Z-1) \to \cdots \to (0, 0, 0)}_{\text{descente séquentielle : } Z \text{ pas unitaires}}
$$

**Propriétés révélées.**

1. **Convergence bornée.** Toute trajectoire atteint le Point de Veille en **au plus $Z + 1$ pas** : un pas de contraction s'il y a lieu, puis $Z$ pas de descente. La fonction $V(p) = 2Z + [\,p \text{ périphérique}\,]$ est une **fonction de Lyapunov discrète** strictement décroissante hors de l'origine.
2. **Unicité de l'attracteur.** `pointDeVeille_is_fixed_point` établit que $(0,0,0)$ est un point fixe. Le Doc. 1 §6.3 affirme davantage, à savoir qu'il est l'« **unique** attracteur stable ». Cette réciproque est vraie pour `dissipationStep`, mais elle n'est pas encore prouvée.
3. **L'asymétrie cinétique est forcée par la géométrie.** Le texte parle de réduction « pas à pas », mais une contraction radiale *unitaire*, par exemple $(4,0,3) \to (3,0,3)$, produirait un point **intérieur** au losange, donc inadmissible selon `isValidCoreAffect`. La loi stricte des couronnes **impose** que la contraction intra-strate soit un **saut**. Une lecture « pas à pas » de la contraction exigerait soit de relâcher la loi (régime transitoire), soit de contracter **le long des filières**, par exemple Enthousiasme $(0,4,3)$ → Joie $(0,2,2)$ → Anticipation $(0,0,2)$. Cette seconde voie se heurte au rapport d'homothétie non entier $R(Z{+}1)/R(Z) = Z/(Z-1)$ pour les positions latérales.
4. **Passage par la Surprise.** La descente traverse $(0,0,1)$, c'est-à-dire la Surprise, définie comme opérateur **ascendant** de rupture. Phénoménologiquement, se pose la question de savoir si le retour au calme passe par un état de « rupture de veille ». Le Doc. 1 §6.3 (« redescend séquentiellement d'une strate à la strate inférieure ») l'implique littéralement. Il conviendrait de le confirmer ou de prévoir un court-circuit $(0,0,2) \to (0,0,0)$.
5. **Absence de couplage avec l'hystérésis** (réserve R6). La dissipation est inconditionnelle.

**Extensions proposées.**

```lean
-- E-c1 : fonction de Lyapunov et convergence en au plus Z + 1 pas
def dissipationPotential (p : CoreAffectPoint) : Nat :=
  2 * p.z + (if p.x = 0 ∧ p.y = 0 then 0 else 1)

theorem dissipation_strictly_decreases (p : CoreAffectPoint) (h : p ≠ ⟨0, 0, 0⟩) :
    dissipationPotential (dissipationStep p) < dissipationPotential p

theorem dissipation_reaches_veille (p : CoreAffectPoint) :
    Nat.repeat dissipationStep (p.z + 1) p = ⟨0, 0, 0⟩

-- E-c2 : unicité de l'attracteur basal (réciproque de pointDeVeille_is_fixed_point)
theorem dissipationStep_fixed_iff (p : CoreAffectPoint) :
    dissipationStep p = p ↔ p = ⟨0, 0, 0⟩

-- E-c3 : couplage avec le seuil de résorption et rémanence
def allostaticStep (d : SalientDiscrepancy) (p : CoreAffectPoint) : CoreAffectPoint :=
  if d.magnitude < d.resorptionThreshold then dissipationStep p else p

theorem remanence_holds (d : SalientDiscrepancy) (p : CoreAffectPoint)
    (h : d.isInRemanenceWindow = true) : allostaticStep d p = p
```

### d) Vers un noyau de transition probabiliste inter-strates (Z → Z + 1)

**Constat formel.** La profondeur est actuellement un **paramètre exogène** (`persistenceDepth`) et la projection est **déterministe**. À chaque profondeur `d`, `deployCouplingAtDepth` n'atteint que les 8 positions axiales et diagonales de la couronne `Z = d + 2`, c'est-à-dire les huit **filières** du Doc. 1 §7.2. Une conséquence quantitative en découle :

$$
\#\{\text{latérales}, Z \le 7\} = \sum_{Z=2}^{7} \big(4R(Z) - 8\big) = 0 + 8 + 16 + 24 + 32 + 40 = 120 \quad\text{entrées sans antécédent dans le Moteur (68,2 \%)}.
$$

**Le nœud théorique : la bifurcation.** À Z = 2, le couplage `(A, C) ∈ {−, 0, +}²` suffit : polarité et position se correspondent un à un (`single_engaged_yields_axial_z2`, `dual_engaged_yields_diagonal_z2`). Dès Z = 3 apparaissent des positions dont la description exige une **asymétrie d'amplitude** entre A et C, par exemple Consternation $(-1, 3, 3)$ face à Exaspération $(-2, 2, 3)$. Une polarité ternaire ne peut pas porter cette information. Le Doc. 1 en donne la clé géométrique (« les positions latérales **s'intercalent entre ces filières** », §7.2) et la clé dynamique (« accroît **la probabilité** que cet écart soit traité à un niveau plus profond », §4 ; catégories comme « attracteurs probabilistes métastables », §7.1).

Concrètement, à Z = 3, chaque position latérale est adjacente, sur le losange, à exactement deux points de filière. Par exemple $(-1, 3)$ se situe entre Enthousiasme $(0, 4)$ et Exaspération $(-2, 2)$. La Colère $(-1,1,2)$ bifurque donc naturellement vers trois successeurs : Exaspération $(-2,2,3)$ dans sa filière, Consternation $(-1,3,3)$ dans le groupe JOIE et Panique $(-3,1,3)$ dans le groupe PEUR, tous dans le même quadrant.

**Spécification proposée.** Le module `AffectiveDynamics` reste à créer. Il formaliserait la transition sous la forme d'un **noyau de Markov** sur les états valides :

```lean
-- E-d1 : noyau de transition inter-strates (poids entiers normalisés : pas de dépendance ;
--        variante : PMF de Mathlib)
structure DepthTransitionKernel where
  weight : CoreAffectPoint → CoreAffectPoint → Nat
  -- (i) support admissible : on n'atteint que des états valides
  support_valid      : ∀ p q, weight p q ≠ 0 → isValidCoreAffect q
  -- (ii) adjacence verticale : approfondissement d'une seule strate
  support_adjacent   : ∀ p q, weight p q ≠ 0 → q.z = p.z + 1
  -- (iii) conservation du quadrant (« une même orientation conserve son signe », §5.2)
  quadrant_preserved : ∀ p q, weight p q ≠ 0 → p.x * q.x ≥ 0 ∧ p.y * q.y ≥ 0
  -- (iv) équivariance antagoniste : la dynamique respecte la dualité régulatrice
  antagonist_equivariant : ∀ p q,
    weight (antagonistPoint p) (antagonistPoint q) = weight p q

-- E-d2 : la couverture actuelle rendue explicite (le pipeline n'atteint aucune latérale)
theorem projectToCoreAffect_never_lateral (s : PredictiveEngineState) :
    (projectToCoreAffect s).classifyGeometry ≠ .lateral

-- E-d3 : atteignabilité visée (toute position latérale admet un antécédent de poids non nul)
theorem lateral_reachable (K : DepthTransitionKernel) (q : CoreAffectPoint)
    (hq : isValidCoreAffect q) (hz : q.z ≥ 3) : ∃ p, K.weight p q ≠ 0
```

**Points d'attention pour la spécification.**
- **Source de l'asymétrie.** Une voie déterministe consisterait à remplacer la précision scalaire `allocatedPrecision` par un couple $(\pi_A, \pi_C)$. La position latérale résulterait alors d'un partage discret de $R(Z)$ au prorata $\pi_A / (\pi_A + \pi_C)$, sous contrainte des signes. Le noyau probabiliste en serait la version stochastique.
- **Homothétie non entière.** Pour Z ≥ 3, $R(Z{+}1)/R(Z) = Z/(Z-1)$ n'est pas entier. Le prolongement d'une latérale à la strate suivante exige donc une règle d'arrondi, ou un choix de voisinage sur le losange, qui doit faire partie des conventions explicites.
- **Les prédictions §8.2 comme propriétés du noyau.** P2 (instabilité axiale) s'exprime par des taux de sortie plus élevés depuis les positions axiales que depuis les diagonales, et par $K(\text{axial} \to \text{diagonal}) > K(\text{diagonal} \to \text{axial})$. P3 (persistance en profondeur) s'exprime par une probabilité de maintien croissante avec Z. Le noyau deviendrait ainsi l'**interface formelle entre la géométrie certifiée et les données empiriques**.
- **Appartenance graduée.** La distribution stationnaire ou transitoire du noyau fournit un degré d'appartenance aux attracteurs. Elle résout la réserve R1 sans toucher à la partition géométrique certifiée.

### Synthèse des extensions recommandées

| Réf. | Extension | Résout | Statut |
|---|---|---|---|
| E-0 | Renforcer `isCoherentTerminalState` (retirer la clause circulaire, ajouter `antagonist.point = antagonistPoint core.point`, `valence = computeValence …`, `activation = computeActivation …`) et prouver une unicité non triviale | R2 | ✅ **Réalisé** ([`Cartograffect/AffectiveTaxonomy.lean`](Cartograffect/AffectiveTaxonomy.lean#L312-L363)) |
| E-a1 à E-a3 | Forme algébrique unifiée hors axes (`antagonistPoint_unified`), liaisons fixes de groupes controlatéraux (`contralateral_group_bindings`) et équivariance Moteur ↔ Matrice (`antagonist_commutes_with_invert`) | §5 a | ✅ **Réalisé** ([`AffectiveMatrix.lean`](Cartograffect/AffectiveMatrix.lean#L363-L427), [`AffectiveTaxonomy.lean`](Cartograffect/AffectiveTaxonomy.lean#L239-L263)) |
| E-b1 à E-b3 | Frontière du régime coopératif (`cooperative_step_leaves_crown`), validité paramétrée (`ResourceRegime`, `isValidCoreAffectIn`) et invariance de l'antagonisme (`antagonist_preserves_validity_in`) | §5 b | ✅ **Réalisé** ([`CoreAffect.lean`](Cartograffect/CoreAffect.lean#L539-L565), [`AffectiveMatrix.lean`](Cartograffect/AffectiveMatrix.lean#L435-L448)) |
| E-c1 à E-c3 | Potentiel de Lyapunov (`dissipation_strictly_decreases`), unicité de l'attracteur (`dissipationStep_fixed_iff`) et rémanence par hystérésis (`remanence_preserves_state`) | §5 c, R6 | ✅ **Réalisé** ([`Cartograffect/CoreAffect.lean`](Cartograffect/CoreAffect.lean#L439-L524)) |
| E-d1 à E-d3 | Noyau de transition probabiliste inter-strates | §5 d, R1, R8 | Feuille de route (élevée — choix théoriques requis) |
| E-3 | Encoder les 176 entrées nommées (`List LexiconEntry`) et les 84 paires, puis certifier : effectif, `Nodup`, validité, clôture antagoniste et complétude spatiale réciproque (`all176Entries_spatial_completeness`) | R6′, §3.4 | ✅ **Réalisé** ([`Cartograffect/Lexicon176.lean`](Cartograffect/Lexicon176.lean)) |
| E-4 | Hygiène : retirer le `#print axioms` résiduel de `AffectiveTaxonomy.lean`, relier `OrientationSector`, `InferentialOperation`, `isInRemanenceWindow`, `feedbackUpdate`, et ajouter `transferUnitYtoX` | R4, R7, R9, R10 | ✅ **Réalisé** |

---

**Conclusion.** La formalisation Lean 4 de CARTOGRAFFECT est **mécaniquement certifiée** : 7 unités modulaires compilées (9 cibles Lake) sous `v4.35.0`, sans `sorry` ni axiome *ad hoc*, avec un socle axiomatique standard. Son chaînage déductif est **porté par les types** du Moteur prédictif jusqu'à la Taxonomie. Elle est **fidèle aux règles géométriques** des deux sources, ce que certifie mécaniquement dans Lean le module [`Cartograffect/Lexicon176.lean`](Cartograffect/Lexicon176.lean) sur l'intégralité des 176 entrées et des 84 paires antagonistes du Doc. 2. Ses limites sont aujourd'hui **identifiées et bornées** : la dynamique inter-strates, le régime coopératif et le caractère gradué des catégories. Elles correspondent précisément aux points que le Doc. 1 désigne lui-même comme « à spécifier » et « à mettre à l'épreuve » (§6.3, §8.2).

*Rapport établi à partir des données certifiées de la passe mécanique (Phases 1, 2 et 4) et de l'inspection directe des sources Lean et des documents théoriques (Phases 3 et 5).*
