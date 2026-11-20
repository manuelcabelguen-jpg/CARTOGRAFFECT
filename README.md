# CARTOGRAFFECT — Formal Verification in Lean 4.35.0

[![Lean 4 Formal Verification](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/lean.yml/badge.svg)](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/lean.yml)
[![Rocq 9.0 CI](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/rocq-ci.yml/badge.svg)](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/rocq-ci.yml)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23833938.svg)](https://doi.org/10.5281/zenodo.23833938)
![Lean 4.35.0](https://img.shields.io/badge/Lean-v4.35.0-blue?logo=lean)
![Zero Sorry](https://img.shields.io/badge/Proof_Audit-0_sorry_%7C_0_custom_axioms-success)
[![License: AGPL v3](https://img.shields.io/badge/Code_License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/Theory_%26_Taxonomy-CC_BY--NC--SA_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

Ce dépôt contient la formalisation mathématique et la preuve assistée par ordinateur sous **Lean 4 (v4.35.0)** de l'architecture fonctionnelle de la **Cartographie des affects**, ainsi que le référentiel algorithmique complet des **176 positions de l'espace affectif ($Z = 0$ à $Z = 7$)**.

> **English Overview:** This repository contains the mechanized formal verification in **Lean 4 (v4.35.0)** of **CARTOGRAFFECT** (*Cartographie des affects*), a hierarchical 3D affective geometry, closed-loop generative predictive circuit, and taxonomy mapping **176 affective states** across 8 vertical strata ($Z = 0$ to $Z = 7$). Built exclusively on Lean 4's core `Init` library (**0 external dependencies**, **0 `sorry`**, **0 `admit`**, **0 custom axioms**), it formally certifies $L_1$ attentional budget conservation, involutive antagonist symmetries, exhaustive taxonomic partitioning, exact integer Markov transition conservation ($4 \cdot \mathrm{scale}^6$), unified $(R_t, Z_t, \pi_A, \pi_C)$ coupling, and the master theorem `end_to_end_coherence`, paired with an isomorphic Python numerical engine (`python/cartograffect_predictive_engine.py`).

---

## Architecture des Modules Certifiés

1. **[`Cartograffect/PredictiveEngine.lean`](Cartograffect/PredictiveEngine.lean)** : Formalisation de l'écart de prédiction saillant (avec hystérésis de résorption), des trois interfaces (Perceptive, Subjective, Attentionnelle), des régimes de charge/décharge et de la partition des 9 couplages $(A/C)$.
2. **[`Cartograffect/CoreAffect.lean`](Cartograffect/CoreAffect.lean)** : Projection spatiale tridimensionnelle $(X, Y, Z)$, opérateurs centraux ($Z = 0$ à $Z = 7$), loi géométrique des couronnes ($R(Z) = 2Z - 2$ pour $Z \ge 2$), partage discret `apportionRay`, conservation du budget attentionnel, réallocation axiale $\to$ diagonale, suspension descendante endogène (`R5`) et dissipation allostatique court-circuitée vers le Point de Veille $(0, 0, 0)$.
3. **[`Cartograffect/AffectiveMatrix.lean`](Cartograffect/AffectiveMatrix.lean)** : Transduction phénoménologique paramétrique (`PhenomenologicalMapping`, `R3`), formalisation des 8 prototypes de la première couronne ($Z = 2$) et preuve d'involutivité de l'opérateur d'antagonisme (symétrie centrale axiale/diagonale et réflexion diagonale controlatérale pour $Z \ge 3$).
4. **[`Cartograffect/AffectiveDynamics.lean`](Cartograffect/AffectiveDynamics.lean)** : Noyau stochastique inter-strates $Z \to Z + 1$ (`DepthTransitionKernel`, atteignabilité latérale `R8`) et appartenance graduée aux 9 attracteurs taxonomiques (`attractorMembership`, `R1`).
5. **[`Cartograffect/AffectiveTaxonomy.lean`](Cartograffect/AffectiveTaxonomy.lean)** : Partition exhaustive et mutuellement exclusive des 9 groupes d'orientation et sous-secteurs fonctionnels, certification arithmétique des 176 entrées (8 centres + 168 positions périphériques) et démonstration du théorème maître `end_to_end_coherence`.
6. **[`Cartograffect/Lexicon176.lean`](Cartograffect/Lexicon176.lean)** : Répertoire nominal exhaustif des 176 positions affectives ($Z = 0$ à $Z = 7$), vérification mécanique des 84 paires antagonistes et atteignabilité complète (`176 / 176`).
7. **[`Cartograffect/PredictiveCircuit.lean`](Cartograffect/PredictiveCircuit.lean)** : Formalisation générative du circuit continu fermé à 2 boucles × 3 circuits et 6 opérateurs de frontière (Figure 1), dualité transposée Croisement I / II, noyau markovien entier exact (`4 * scale ^ 6`) distinguant extinction passive ($\delta$) et résolution active ($\rho, \kappa$), indépendance P1 ($L_1$) / P2 ($\chi$), ruptures topologiques d'ergodicité et loi unifiée $(R_t, Z_t, \pi_{A,t}, \pi_{C,t})$ couplée au court-circuit `R5` et à `apportionRay`.
8. **[`Cartograffect/AuditTests.lean`](Cartograffect/AuditTests.lean) & [`AUDIT_REPORT.md`](AUDIT_REPORT.md)** : Audit axiomatique (`#print axioms` sur 113 théorèmes), tests d'évaluation constructive (`#eval`) et certificat d'audit formel complet.
9. **[`Cartograffect.lean`](Cartograffect.lean)** : Module racine agrégeant l'ensemble de la bibliothèque formelle.
10. **[`python/cartograffect_predictive_engine.py`](python/cartograffect_predictive_engine.py) & [`python/test_predictive_engine.py`](python/test_predictive_engine.py)** : Moteur prédictif numérique en Python isomorphe à `PredictiveCircuit.lean` (écart maximal $|T - W / (4 \cdot 100^6)| \le 1{,}11 \times 10^{-16}$, analyse spectrale d'ergodicité, simulation unifiée $(R_t, Z_t, \tilde{\pi}_A, \tilde{\pi}_C)$ et suite de 12 tests unitaires).

---

## Vérification Formelle Mécanisée (Lean 4.35.0)

L'intégralité du système formel CARTOGRAFFECT est compilée, vérifiée et auditée en continu au sein du pipeline d'Intégration Continue (CI) GitHub Actions.

### Environnement de preuve certifié (CI GitHub Actions)

- **Prover :** Lean 4 (`v4.35.0`, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, Release `x86_64-linux`)
- **Build system :** Lake `5.0.0-src+eb6cafb`
- **Commit d'introduction initiale du noyau formel :** [`6fc3a987ab047974d10b679f6d1fb1c11183e10b`](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/commit/6fc3a987ab047974d10b679f6d1fb1c11183e10b) *(commit de référence initial du noyau des 17 théorèmes et du lexique des 176 entrées, étendu aux modules `AffectiveDynamics`, `PredictiveCircuit` et aux résolutions documentées dans [`AUDIT_REPORT.md`](AUDIT_REPORT.md))*
- **Compilation `lake build` (`warningAsError := true`) :** **11 cibles compilées** avec succès (0 erreur, 0 avertissement).
- **Audit statique et axiomatique :** `Select-String` / `git grep` $\rightarrow$ **0 `sorry`, 0 `admit`, 0 `axiom`, 0 `unsafe`, 0 `implemented_by`, 0 `noncomputable`** ; **113 théorèmes audités** par `#print axioms` (24 purement réductionnels `[none]`, 34 extensionnels, 55 socle classique standard).
- **Dépendances externes :** **0** (aucune dépendance vis-à-vis de Mathlib ou Batteries ; uniquement le noyau formel de Lean 4 et sa bibliothèque standard `Init`).

### Architecture des 11 cibles `lake build`

Le pipeline CI orchestre la compilation stricte de 11 cibles (`lake build`, `warningAsError := true`, couvrant les **9 unités modulaires `.lean`** et les cibles d'assemblage de la bibliothèque) avec **0 erreur et 0 avertissement** :

1. **[`Cartograffect.PredictiveEngine`](Cartograffect/PredictiveEngine.lean)** : Polarité prédictive involutive, hystérésis, précisions $(\pi_A, \pi_C)$ et transition `engineStep`.
2. **[`Cartograffect.CoreAffect`](Cartograffect/CoreAffect.lean)** : Induction valide du Core Affect, partage discret `apportionRay`, surjectivité sur 176/176, suspension endogène `R5` et dissipation court-circuitée.
3. **[`Cartograffect.AffectiveMatrix`](Cartograffect/AffectiveMatrix.lean)** : Symétrie antagoniste involutive, paramétrisation phénoménologique (`R3`) et permutation controlatérale des amplitudes.
4. **[`Cartograffect.AffectiveDynamics`](Cartograffect/AffectiveDynamics.lean)** : Noyau stochastique `DepthTransitionKernel` ($Z \to Z + 1$) et appartenance graduée `attractorMembership` (`R1`, `R8`).
5. **[`Cartograffect.AffectiveTaxonomy`](Cartograffect/AffectiveTaxonomy.lean)** : Certification combinatoire des 176 états affectifs ($Z = 0$ à $Z = 7$), exhaustivité/exclusivité des groupes taxonomiques, sous-secteurs et cohérence de bout en bout (`end_to_end_coherence`).
6. **[`Cartograffect.Lexicon176`](Cartograffect/Lexicon176.lean)** : Instanciation explicite des 176 entrées lexicales, validité géométrique $L_1$, unicité des coordonnées, clôture antagoniste et atteignabilité complète.
7. **[`Cartograffect.PredictiveCircuit`](Cartograffect/PredictiveCircuit.lean)** : Boucle fermée continue à 6 opérateurs, bijection $L_1$, noyau entier exact (`4 * scale ^ 6`, extinction passive $\delta$ vs résolution active, P1 vs P2, ruptures topologiques) et loi unifiée $(R_t, Z_t, \pi_A, \pi_C)$.
8. **[`Cartograffect.AuditTests`](Cartograffect/AuditTests.lean)** : Audit des dépendances axiomatiques (`#print axioms` sur 113 théorèmes) et tests d'évaluation constructive (`#eval`, blocs 1 à 11).
9. **[`Cartograffect`](Cartograffect.lean)** : Module racine agrégeant l'ensemble de la bibliothèque formelle.

> *Note sur les 11 cibles `lake build` :* Le compteur de 11 tâches compilées par Lake 5.0 (`warningAsError := true`) correspond à la compilation des **9 unités modulaires `.lean`** ci-dessus, complétée par les **2 cibles d'agrégation de la bibliothèque** (`Cartograffect`, `Cartograffect.AffectiveDynamics`, `Cartograffect.PredictiveCircuit`). L'audit complet couvre désormais **113 théorèmes** (`24` purement réductionnels `[none]`, `34` extensionnels `[propext]`/`[propext, Quot.sound]` et `55` classiques standard `[propext, Classical.choice, Quot.sound]`, détaillés dans [`AUDIT_REPORT.md`](AUDIT_REPORT.md)).

---

### Tableau synthétique du noyau historique (17 théorèmes fondateurs, complétés par 96 théorèmes d'extension — total 113)

L'audit automatique exécuté via `#print axioms` dans [`Cartograffect/AuditTests.lean`](Cartograffect/AuditTests.lean) contrôle l'arbre déductif complet de chaque théorème. Il atteste formellement que le système repose exclusivement sur la réduction computationnelle pure ou sur le socle logique standard du noyau de Lean 4, sans aucun axiome personnalisé ou ad hoc. *(Pour la lisibilité des tableaux ci-dessous, le préfixe racine `Cartograffect.` est omis devant les identifiants, dont les chemins complets sont de la forme `Cartograffect.<Module>.<théorème>`, par exemple `Cartograffect.AffectiveTaxonomy.end_to_end_coherence`.)*

#### A. Théorèmes purement constructifs (8 théorèmes — Dépendance axiomatique : `Aucune / [none]`)

Ces théorèmes sont établis par pure réduction computationnelle (`rfl`, `decide`, disjonction de cas exhaustive). Le noyau de Lean valide leur preuve sans faire appel à la moindre hypothèse logique externe :

| # | Théorème certifié | Module & Source | Dépendances axiomatiques (`#print axioms`) | Classification logique |
|---|---|---|---|---|
| 1 | `Polarity.invert_involutive` | `PredictiveEngine` · [`L28`](Cartograffect/AuditTests.lean#L28) | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| 2 | `coupling_regime_partition` | `PredictiveEngine` · [`L29`](Cartograffect/AuditTests.lean#L29) | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| 3 | `z2_budget_conservation` | `CoreAffect` · [`L33`](Cartograffect/AuditTests.lean#L33) | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| 4 | `contralateral_swaps_amplitudes` | `AffectiveMatrix` · [`L45`](Cartograffect/AuditTests.lean#L45) | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| 5 | `inventory_176_certified` | `AffectiveTaxonomy` · [`L50`](Cartograffect/AuditTests.lean#L50) | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| 6 | `all176Entries_length` | `Lexicon176` · [`L60`](Cartograffect/AuditTests.lean#L60) | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| 7 | `all176Entries_unique_points` | `Lexicon176` · [`L62`](Cartograffect/AuditTests.lean#L62) | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| 8 | `all176Entries_closed_under_antagonist` | `Lexicon176` · [`L63`](Cartograffect/AuditTests.lean#L63) | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |

#### B. Théorèmes structurels reposant uniquement sur les axiomes standards de Lean (`propext`, `Quot.sound`, `Classical.choice` — 9 théorèmes)

Ces théorèmes s'appuient uniquement sur le socle axiomatique classique standard du calcul des constructions inductives (CIC) de Lean 4 (`propext` pour l'extensionnalité propositionnelle, `Quot.sound` pour l'exactitude des types quotients, et `Classical.choice` mobilisé par les lemmes de décision de la bibliothèque `Init`) :

| # | Théorème certifié | Module & Source | Dépendances axiomatiques (`#print axioms`) | Classification logique |
|---|---|---|---|---|
| 9 | `engine_induces_valid_core_affect` | `CoreAffect` · [`L32`](Cartograffect/AuditTests.lean#L32) | `[propext, Classical.choice, Quot.sound]` | **Fondations classiques standard** |
| 10 | `taxonomy_group_exclusive` | `AffectiveTaxonomy` · [`L52`](Cartograffect/AuditTests.lean#L52) | `[propext, Quot.sound]` | **Fondations standard de Lean** |
| 11 | `axial_to_diagonal_reallocation` | `CoreAffect` · [`L34`](Cartograffect/AuditTests.lean#L34) | `[propext, Classical.choice, Quot.sound]` | **Fondations classiques standard** |
| 12 | `dissipationStep_valid` | `CoreAffect` · [`L35`](Cartograffect/AuditTests.lean#L35) | `[propext, Classical.choice, Quot.sound]` | **Fondations classiques standard** |
| 13 | `antagonistPoint_preserves_validity` | `AffectiveMatrix` · [`L43`](Cartograffect/AuditTests.lean#L43) | `[propext, Classical.choice, Quot.sound]` | **Fondations classiques standard** |
| 14 | `antagonistPoint_involutive` | `AffectiveMatrix` · [`L44`](Cartograffect/AuditTests.lean#L44) | `[propext, Classical.choice, Quot.sound]` | **Fondations classiques standard** |
| 15 | `taxonomy_group_exhaustive` | `AffectiveTaxonomy` · [`L51`](Cartograffect/AuditTests.lean#L51) | `[propext, Classical.choice, Quot.sound]` | **Fondations classiques standard** |
| 16 | `end_to_end_coherence` | `AffectiveTaxonomy` · [`L59`](Cartograffect/AuditTests.lean#L59) | `[propext, Classical.choice, Quot.sound]` | **Fondations classiques standard** *(Théorème Maître)* |
| 17 | `all176Entries_geometrically_valid` | `Lexicon176` · [`L61`](Cartograffect/AuditTests.lean#L61) | `[propext, Classical.choice, Quot.sound]` | **Fondations classiques standard** |

> **Note sur le socle logique :**  
> `propext` (extensionnalité des propositions), `Classical.choice` (principe du choix classique) et `Quot.sound` (exactitude des types quotients) constituent les fondements standard universellement admis du noyau de Lean 4 (identiques au socle de Mathlib). Le modèle CARTOGRAFFECT n'admet aucun axiome supplémentaire ni aucune dépendance externe.

---

### Vérifications exécutables (`#eval` dans `AuditTests.lean`, blocs 1 à 11)

Au-delà des preuves formelles statiques, le noyau Lean 4 évalue par calcul direct (`#eval`) le pipeline déterministe `runCartograffectPipeline` ainsi que le circuit fermé `PredictiveCircuit` et la loi unifiée `UnifiedDynamicsParams`, notamment :

1. **Origine $(0, 0, 0) \rightarrow$ `z0_pointDeVeille` / `operateurCentral` :**  
   Évaluation de l'état basal par défaut : sous le seuil sensoriel (`magnitude = 0 < sensoryThreshold = 1`), le système converge vers le Point de Veille canonique (`stratum = z0_pointDeVeille`, `group = operateurCentral`).

2. **Rupture de veille $(0, 0, 1) \rightarrow$ `z1_saillancePerceptive` / `ascendingRupture` :**  
   Évaluation d'un écart franchissant le seuil sensoriel (`magnitude 5 ≥ sensoryThreshold 2`) sans précision attentionnelle suffisante (`allocatedPrecision 1 < engagementThreshold 3`) : le moteur projette la Surprise (`stratum = z1_saillancePerceptive`, `activation = ascendingRupture`).

3. **Dyade diagonale $(-1, 1, 2) \leftrightarrow (1, -1, 2) \rightarrow$ `groupeColere` $\leftrightarrow$ `groupeCalme` (`ergotropicCompensation` / `negative`) :**  
   Projection exacte de la Colère $(-1, 1, 2)$, transduction de son antagoniste géométrique le Calme $(1, -1, 2)$, avec stricte conservation budgétaire $L_1$ ($|-1| + |1| = 2$).

4. **Circuit circulaire et loi unifiée (`PredictiveCircuit`, blocs 10–11) :**  
   Vérification numérique directe de `circuitRowSum = 4000000000000`, de la distinction actif vs passif sur `nextChargeAccumulator` (`(700, 1300)`), du court-circuit `nextStratumR5 default 2 100 = 0` (`R5`) et de l'atteinte de la coordonnée latérale `Consternation (-1, 3, 3)` par partage logistique.

---

### Instructions de reproduction locale

Tout pair évaluateur peut reproduire, compiler et auditer mécaniquement l'ensemble des preuves Lean 4 et des tests Python en local :

```bash
# 1. Cloner le dépôt et se positionner à la racine
git clone https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT.git
cd CARTOGRAFFECT

# 2. Vérification des versions de la toolchain (Lean 4.35.0 & Lake 5.0.0)
lean --version
lake --version

# 3. Compilation stricte de la bibliothèque et vérification formelle (11 cibles)
lake build

# 4. Exécution du banc d'audit axiomatique (#print axioms, 113 théorèmes) et des tests (#eval)
lake env lean Cartograffect/AuditTests.lean

# 5. Audit statique d'intégrité (garantie de 0 sorry, 0 admit, 0 axiome ad hoc)
git grep -n -E "\b(sorry|admit|axiom|unsafe|implemented_by|noncomputable)\b" -- Cartograffect/ Cartograffect.lean

# 6. Tests unitaires et contrôle de parité du moteur prédictif Python (12 tests)
python -m unittest discover -s python -v
python python/cartograffect_predictive_engine.py
```

---

## Documentation associée

- **[`AUDIT_REPORT.md`](AUDIT_REPORT.md)** : Rapport complet d'audit de certification formelle et de fidélité épistémique (Phases 1 à 5 & Section 6 `PredictiveCircuit`).
- **[`docs/01-Article_Cartograffect.md`](docs/01-Article_Cartograffect.md)** : Article théorique de référence (fondements conceptuels, section 4.1 et dynamiques).
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
  title = {Cartographie des affects : une architecture hi{\'e}rarchique de l'exp{\'e}rience affective fond{\'e}e sur le traitement pr{\'e}dictif},
  year = {2026},
  note = {Manuscrit théorique de référence (docs/01-Article_Cartograffect.md), enregistrement OPIC n° 1233199}
}

@software{cabelguen2026cartograffect,
  author = {Cabelguen, Manuel},
  title = {{CARTOGRAFFECT}: Architecture math{\'e}matique et taxonomique v{\'e}rifi{\'e}e sous {Lean} 4},
  year = {2026},
  publisher = {Zenodo},
  version = {1.0.1},
  doi = {10.5281/zenodo.23833938},
  url = {https://doi.org/10.5281/zenodo.23833938},
  note = {Version v1.0.1, formal verification in Lean 4.35.0 (https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT)}
}

@inproceedings{demoura2021lean4,
  author = {de Moura, Leonardo and Ullrich, Sebastian},
  title = {The {Lean} 4 Theorem Prover and Programming Language},
  booktitle = {Automated Deduction -- CADE 28},
  series = {Lecture Notes in Computer Science},
  volume = {12699},
  pages = {625--635},
  publisher = {Springer},
  year = {2021},
  doi = {10.1007/978-3-030-79876-5_37}
}
```
