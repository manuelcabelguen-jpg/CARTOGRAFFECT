# CARTOGRAFFECT — Formal Verification in Lean 4.35.0

[![Lean 4 Formal Verification](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/lean.yml/badge.svg)](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/lean.yml)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23833938.svg)](https://doi.org/10.5281/zenodo.23833938)
![Lean 4.35.0](https://img.shields.io/badge/Lean-v4.35.0-blue?logo=lean)
![Zero Sorry](https://img.shields.io/badge/Proof_Audit-0_sorry_%7C_0_custom_axioms-success)
[![License: AGPL v3](https://img.shields.io/badge/Code_License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/Theory_%26_Taxonomy-CC_BY--NC--SA_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

Ce dépôt contient la formalisation mathématique et la preuve assistée par ordinateur sous **Lean 4 (v4.35.0)** de l'architecture fonctionnelle de la **Cartographie des affects**, ainsi que le référentiel algorithmique complet des **176 positions de l'espace affectif ($Z = 0$ à $Z = 7$)**.

> **English Overview:** This repository contains the mechanized formal verification in **Lean 4 (v4.35.0)** of **CARTOGRAFFECT** (*Cartographie des affects*), a hierarchical 3D affective geometry and predictive-processing taxonomy mapping **176 affective states** across 8 vertical strata ($Z = 0$ to $Z = 7$). Built exclusively on Lean 4's core `Init` library (**0 external dependencies**, **0 `sorry`**, **0 `admit`**, **0 custom axioms**), it formally certifies $L_1$ attentional budget conservation, involutive antagonist symmetries, exhaustive taxonomic partitioning, and the master theorem `end_to_end_coherence`.

---

## Architecture des Modules Certifiés

1. **[`Cartograffect/PredictiveEngine.lean`](Cartograffect/PredictiveEngine.lean)** : Formalisation de l'écart de prédiction saillant (avec hystérésis de résorption), des trois interfaces (Perceptive, Subjective, Attentionnelle), des régimes de charge/décharge et de la partition des 9 couplages $(A/C)$.
2. **[`Cartograffect/CoreAffect.lean`](Cartograffect/CoreAffect.lean)** : Projection spatiale tridimensionnelle $(X, Y, Z)$, opérateurs centraux ($Z = 0$ à $Z = 7$), loi géométrique des couronnes ($R(Z) = 2Z - 2$ pour $Z \ge 2$), conservation du budget attentionnel, réallocation axiale $\to$ diagonale et dissipation allostatique graduelle vers le Point de Veille $(0, 0, 0)$.
3. **[`Cartograffect/AffectiveMatrix.lean`](Cartograffect/AffectiveMatrix.lean)** : Transduction phénoménologique (valence et activation), formalisation des 8 prototypes de la première couronne ($Z = 2$) et preuve d'involutivité de l'opérateur d'antagonisme (symétrie centrale axiale/diagonale et réflexion diagonale controlatérale pour $Z \ge 3$).
4. **[`Cartograffect/AffectiveTaxonomy.lean`](Cartograffect/AffectiveTaxonomy.lean)** : Partition exhaustive et mutuellement exclusive des 9 groupes d'orientation, certification arithmétique des 176 entrées (8 centres + 168 positions périphériques) et démonstration du théorème maître `end_to_end_coherence`.
5. **[`Cartograffect/Lexicon176.lean`](Cartograffect/Lexicon176.lean)** : Répertoire nominal exhaustif des 176 positions affectives ($Z = 0$ à $Z = 7$) et vérification mécanique des 84 paires antagonistes axiales, diagonales et controlatérales.
6. **[`Cartograffect/AuditTests.lean`](Cartograffect/AuditTests.lean) & [`AUDIT_REPORT.md`](AUDIT_REPORT.md)** : Audit axiomatique (`#print axioms`), tests d'évaluation constructive (`#eval`) et certificat d'audit formel complet.
7. **[`Cartograffect.lean`](Cartograffect.lean)** : Module racine agrégeant l'ensemble de la bibliothèque formelle.

---

## Vérification Formelle Mécanisée (Lean 4.35.0)

L'intégralité du système formel CARTOGRAFFECT est compilée, vérifiée et auditée en continu au sein du pipeline d'Intégration Continue (CI) GitHub Actions.

### Environnement de preuve certifié (CI GitHub Actions)

- **Prover :** Lean 4 (`v4.35.0`, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, Release `x86_64-linux`)
- **Build system :** Lake `5.0.0-src+eb6cafb`
- **Commit d'introduction initiale du noyau formel :** [`6fc3a987ab047974d10b679f6d1fb1c11183e10b`](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/commit/6fc3a987ab047974d10b679f6d1fb1c11183e10b) *(commit de référence du code Lean vérifié ; les commits ultérieurs sont documentaires et ne touchent, dans les fichiers `.lean`, qu'aux en-têtes de licence en commentaire, sans altérer aucune définition ni preuve)*
- **Compilation `lake build` :** **9 tâches compilées** avec succès (0 erreur, 0 avertissement).
- **Audit statique et axiomatique :** `git grep -n -E "\b(sorry|admit|axiom)\b" -- Cartograffect/ Cartograffect.lean` $\rightarrow$ **0 `sorry`, 0 `admit`, 0 axiome ad hoc**.
- **Dépendances externes :** **0** (aucune dépendance vis-à-vis de Mathlib ou Batteries ; uniquement le noyau formel de Lean 4 et sa bibliothèque standard `Init`).

### Architecture des 9 unités de compilation (`lake build`)

Le pipeline CI orchestre la compilation stricte de 9 cibles (`lake build`, `warningAsError := true`) avec **0 erreur et 0 avertissement** :

1. **[`Cartograffect.PredictiveEngine`](Cartograffect/PredictiveEngine.lean)** (449 ms) : Polarité prédictive involutive et partition des régimes de couplage.
2. **[`Cartograffect.CoreAffect`](Cartograffect/CoreAffect.lean)** (548 ms) : Induction valide du Core Affect, conservation budgétaire ($Z = 2$), réallocation axiale/diagonale et dynamique de dissipation.
3. **[`Cartograffect.AffectiveMatrix`](Cartograffect/AffectiveMatrix.lean)** (678 ms) : Symétrie antagoniste involutive, préservation de la validité géométrique et permutation controlatérale des amplitudes.
4. **[`Cartograffect.AffectiveTaxonomy`](Cartograffect/AffectiveTaxonomy.lean)** (853 ms) : Certification combinatoire des 176 états affectifs ($Z = 0$ à $Z = 7$), exhaustivité/exclusivité des groupes taxonomiques et cohérence de bout en bout.
5. **[`Cartograffect.Lexicon176`](Cartograffect/Lexicon176.lean)** (6,2 s) : Instanciation explicite des 176 entrées lexicales, validité géométrique $L_1$, unicité des coordonnées et clôture par symétrie antagoniste.
6. **[`Cartograffect.AuditTests`](Cartograffect/AuditTests.lean)** (209 ms) : Audit des dépendances axiomatiques (`#print axioms`) sur les 17 théorèmes majeurs et tests d'évaluation phénoménologique ($Z = 0, Z = 1, Z = 2$).
7. **[`Cartograffect`](Cartograffect.lean)** (180 ms) : Module racine agrégeant l'ensemble de la bibliothèque formelle.

> *Note sur les 9 cibles `lake build` :* Le compteur de 9 tâches compilées par Lake 5.0 (`warningAsError := true`) correspond à la compilation individuelle des **7 unités modulaires `.lean`** ci-dessus, complétée par les **2 cibles internes d'assemblage et d'agrégation de la bibliothèque**.

---

### Tableau d'audit des 17 théorèmes certifiés (`Cartograffect/AuditTests.lean`)

L'audit automatique exécuté via `#print axioms` dans [`Cartograffect/AuditTests.lean`](Cartograffect/AuditTests.lean) contrôle l'arbre déductif complet de chaque théorème. Il atteste formellement que le système repose exclusivement sur la réduction computationnelle pure ou sur le socle logique standard du noyau de Lean 4, sans aucun axiome personnalisé ou ad hoc :

#### A. Théorèmes purement constructifs (8 théorèmes — Dépendance axiomatique : `Aucune / [none]`)

Ces théorèmes sont établis par pure réduction computationnelle (`rfl`, `decide`, disjonction de cas exhaustive). Le noyau de Lean valide leur preuve sans faire appel à la moindre hypothèse logique externe :

| # | Théorème certifié | Source & Ligne | Dépendances axiomatiques (`#print axioms`) | Classification logique |
|---|---|---|---|---|
| 1 | `Cartograffect.PredictiveEngine.Polarity.invert_involutive` | [`AuditTests.lean:24`](Cartograffect/AuditTests.lean#L24) | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| 2 | `Cartograffect.PredictiveEngine.coupling_regime_partition` | [`AuditTests.lean:25`](Cartograffect/AuditTests.lean#L25) | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| 3 | `Cartograffect.CoreAffect.z2_budget_conservation` | [`AuditTests.lean:27`](Cartograffect/AuditTests.lean#L27) | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| 4 | `Cartograffect.AffectiveMatrix.contralateral_swaps_amplitudes` | [`AuditTests.lean:32`](Cartograffect/AuditTests.lean#L32) | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| 5 | `Cartograffect.AffectiveTaxonomy.inventory_176_certified` | [`AuditTests.lean:33`](Cartograffect/AuditTests.lean#L33) | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| 6 | `Cartograffect.Lexicon176.all176Entries_length` | [`AuditTests.lean:37`](Cartograffect/AuditTests.lean#L37) | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| 7 | `Cartograffect.Lexicon176.all176Entries_unique_points` | [`AuditTests.lean:39`](Cartograffect/AuditTests.lean#L39) | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| 8 | `Cartograffect.Lexicon176.all176Entries_closed_under_antagonist` | [`AuditTests.lean:40`](Cartograffect/AuditTests.lean#L40) | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |

#### B. Théorèmes structurels reposant uniquement sur les axiomes standards de Lean (`propext`, `Quot.sound`, `Classical.choice` — 9 théorèmes)

Ces théorèmes s'appuient uniquement sur le socle axiomatique classique standard du calcul des constructions inductives (CIC) de Lean 4 (`propext` pour l'extensionnalité propositionnelle, `Quot.sound` pour l'exactitude des types quotients, et `Classical.choice` mobilisé par les lemmes de décision de la bibliothèque `Init`) :

| # | Théorème certifié | Source & Ligne | Dépendances axiomatiques (`#print axioms`) | Classification logique |
|---|---|---|---|---|
| 9 | `Cartograffect.CoreAffect.engine_induces_valid_core_affect` | [`AuditTests.lean:26`](Cartograffect/AuditTests.lean#L26) | `[propext, Quot.sound]` | **Fondations standard de Lean** |
| 10 | `Cartograffect.AffectiveTaxonomy.taxonomy_group_exclusive` | [`AuditTests.lean:35`](Cartograffect/AuditTests.lean#L35) | `[propext, Quot.sound]` | **Fondations standard de Lean** |
| 11 | `Cartograffect.CoreAffect.axial_to_diagonal_reallocation` | [`AuditTests.lean:28`](Cartograffect/AuditTests.lean#L28) | `[propext, Classical.choice, Quot.sound]` | **Fondations classiques standard** |
| 12 | `Cartograffect.CoreAffect.dissipationStep_valid` | [`AuditTests.lean:29`](Cartograffect/AuditTests.lean#L29) | `[propext, Classical.choice, Quot.sound]` | **Fondations classiques standard** |
| 13 | `Cartograffect.AffectiveMatrix.antagonistPoint_preserves_validity` | [`AuditTests.lean:30`](Cartograffect/AuditTests.lean#L30) | `[propext, Classical.choice, Quot.sound]` | **Fondations classiques standard** |
| 14 | `Cartograffect.AffectiveMatrix.antagonistPoint_involutive` | [`AuditTests.lean:31`](Cartograffect/AuditTests.lean#L31) | `[propext, Classical.choice, Quot.sound]` | **Fondations classiques standard** |
| 15 | `Cartograffect.AffectiveTaxonomy.taxonomy_group_exhaustive` | [`AuditTests.lean:34`](Cartograffect/AuditTests.lean#L34) | `[propext, Classical.choice, Quot.sound]` | **Fondations classiques standard** |
| 16 | `Cartograffect.AffectiveTaxonomy.end_to_end_coherence` | [`AuditTests.lean:36`](Cartograffect/AuditTests.lean#L36) | `[propext, Classical.choice, Quot.sound]` | **Fondations classiques standard** *(Théorème Maître)* |
| 17 | `Cartograffect.Lexicon176.all176Entries_geometrically_valid` | [`AuditTests.lean:38`](Cartograffect/AuditTests.lean#L38) | `[propext, Classical.choice, Quot.sound]` | **Fondations classiques standard** |

> **Note sur le socle logique :**  
> `propext` (extensionnalité des propositions), `Classical.choice` (principe du choix classique) et `Quot.sound` (exactitude des types quotients) constituent les fondements standard universellement admis du noyau de Lean 4 (identiques au socle de Mathlib). Le modèle CARTOGRAFFECT n'admet aucun axiome supplémentaire ni aucune dépendance externe.

---

### Vérifications phénoménologiques exécutables (`#eval` dans `AuditTests.lean`, lignes 47–75)

Au-delà des preuves formelles statiques, le noyau Lean 4 évalue par calcul direct (`#eval`) le pipeline déterministe `runCartograffectPipeline` sur trois témoins phénoménologiques canoniques :

1. **Origine $(0, 0, 0) \rightarrow$ `z0_pointDeVeille` / `operateurCentral` ([lignes 47–49](Cartograffect/AuditTests.lean#L47-L49)) :**  
   Évaluation de l'état basal par défaut : sous le seuil sensoriel (`magnitude = 0 < sensoryThreshold = 1`), le système converge vers le Point de Veille canonique, confirmant la stabilité homéostatique de l'origine (`stratum = z0_pointDeVeille`, `group = operateurCentral`).

2. **Suspension $(0, 0, 1) \rightarrow$ `z1_saillancePerceptive` / `operatorSuspension` ([lignes 59–61](Cartograffect/AuditTests.lean#L59-L61)) :**  
   Évaluation d'un écart franchissant le seuil sensoriel (`magnitude 5 ≥ sensoryThreshold 2`) sans précision attentionnelle suffisante (`allocatedPrecision 1 < engagementThreshold 3`) : le moteur projette la Surprise sur l'axe vertical d'activation avant tout déploiement spatial (`stratum = z1_saillancePerceptive`, `activation = operatorSuspension`).

3. **Dyade diagonale (de compensation) $(-1, 1, 2) \leftrightarrow (1, -1, 2) \rightarrow$ `groupeColere` $\leftrightarrow$ `groupeCalme` (`mixedCompensation`) ([lignes 71–75](Cartograffect/AuditTests.lean#L71-L75)) :**  
   Évaluation d'un couplage engagé ($A-, C+$) à $Z = 2$ (`allocatedPrecision 5 ≥ 3`) : projection exacte de la Colère $(-1, 1, 2)$, transduction de son antagoniste géométrique direct le Calme $(1, -1, 2)$, et attribution de la valence de compensation mixte (`mixedCompensation`), avec stricte conservation budgétaire $L_1$ ($|-1| + |1| = 2$).

---

### Instructions de reproduction locale

Tout pair évaluateur peut reproduire, compiler et auditer mécaniquement l'ensemble des preuves et calculs en local :

```bash
# 1. Cloner le dépôt et se positionner à la racine
git clone https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT.git
cd CARTOGRAFFECT

# 2. Vérification des versions de la toolchain (Lean 4.35.0 & Lake 5.0.0)
lean --version
lake --version

# 3. Compilation stricte de la bibliothèque et vérification formelle (9 cibles)
lake build

# 4. Exécution du banc d'audit axiomatique (#print axioms) et des tests (#eval)
lake env lean Cartograffect/AuditTests.lean

# 5. Audit statique d'intégrité (garantie de 0 sorry, 0 admit, 0 axiome ad hoc)
git grep -n -E "\b(sorry|admit|axiom)\b" -- Cartograffect/ Cartograffect.lean
```

---

## Documentation associée

- **[`AUDIT_REPORT.md`](AUDIT_REPORT.md)** : Rapport complet d'audit de certification formelle et de fidélité épistémique (Phases 1 à 5).
- **[`docs/01-Article_Cartograffect.md`](docs/01-Article_Cartograffect.md)** : Article théorique de référence (fondements conceptuels et dynamiques).
- **[`docs/02-Inventaire_176.md`](docs/02-Inventaire_176.md)** : Inventaire exhaustif des 176 positions affectives et relations antagonistes.

---

## Auteur et Correspondance

Manuel Cabelguen, Ph. D.  
Correspondance : manuelcabelguen@gmail.com

---

## Licence / Propriété intellectuelle

Copyright (C) 2025-2026 Manuel Cabelguen — `SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0`

- **Code source et preuves formelles Lean 4** : distribués sous licence **GNU AGPLv3** ([`LICENSE`](./LICENSE)).
- **Architecture théorique, géométrie affective et taxonomie des 176 états** : distribuées sous licence **Creative Commons BY-NC-SA 4.0** ([`LICENSE-CC-BY-NC-SA-4.0.md`](./LICENSE-CC-BY-NC-SA-4.0.md)). Toute exploitation commerciale est strictement réservée.
- **Propriété intellectuelle** : *CARTOGRAFFECT* fait l'objet d'un enregistrement de droit d'auteur auprès de l'Office de la propriété intellectuelle du Canada (OPIC, enregistrement n° 1233199). Pour toute demande de licence commerciale, contacter l'auteur (manuelcabelguen@gmail.com). Voir aussi [`NOTICE`](./NOTICE).

---

## Citation

Si vous utilisez ce modèle ou cette formalisation, merci de citer l'article théorique de référence ainsi que la bibliothèque formelle (voir aussi [`CITATION.cff`](CITATION.cff)) :

- **Modèle théorique :**  
  Cabelguen, M. (2026). *Cartographie des affects : une architecture hiérarchique de l’expérience affective fondée sur le traitement prédictif*.
- **Formalisation Lean 4 :**  
  Cabelguen, M. (2026). *CARTOGRAFFECT: Architecture mathématique et taxonomique vérifiée sous Lean 4* (version taguée `v1.0.1`) [Logiciel]. Zenodo. https://doi.org/10.5281/zenodo.23833938
- **Assistant de preuve :**  
  de Moura, L., & Ullrich, S. (2021). The Lean 4 Theorem Prover and Programming Language. In A. Platzer & G. Sutcliffe (Eds.), *Automated Deduction – CADE 28* (LNCS, Vol. 12699, pp. 625–635). Springer. https://doi.org/10.1007/978-3-030-79876-5_37

```bibtex
@unpublished{cabelguen2026cartographie,
  author = {Cabelguen, Manuel},
  title  = {Cartographie des affects : une architecture hi{\'e}rarchique de l'exp{\'e}rience affective fond{\'e}e sur le traitement pr{\'e}dictif},
  year   = {2026},
  note   = {Manuscrit théorique de référence (docs/01-Article_Cartograffect.md), enregistrement OPIC n° 1233199}
}

@software{cabelguen2026cartograffect,
  author    = {Cabelguen, Manuel},
  title     = {{CARTOGRAFFECT}: Architecture math{\'e}matique et taxonomique v{\'e}rifi{\'e}e sous {Lean} 4},
  year      = {2026},
  publisher = {Zenodo},
  version   = {1.0.1},
  doi       = {10.5281/zenodo.23833938},
  url       = {https://doi.org/10.5281/zenodo.23833938},
  note      = {Version v1.0.1, formal verification in Lean 4.35.0 (https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT)}
}

@inproceedings{demoura2021lean4,
  author    = {de Moura, Leonardo and Ullrich, Sebastian},
  title     = {The {Lean} 4 Theorem Prover and Programming Language},
  booktitle = {Automated Deduction -- CADE 28},
  series    = {Lecture Notes in Computer Science},
  volume    = {12699},
  pages     = {625--635},
  publisher = {Springer},
  year      = {2021},
  doi       = {10.1007/978-3-030-79876-5_37}
}
```
