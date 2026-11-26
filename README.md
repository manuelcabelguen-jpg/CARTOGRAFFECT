# CARTOGRAFFECT — Hexa-Prover Formal Verification (Lean 4.35 · Rocq 9.1 · Agda 2.9 · Dafny 4.11 · Z3 5.3 · TLA+ 2.19)

[![Lean 4 Formal Verification](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/lean.yml/badge.svg)](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/lean.yml)
[![Rocq 9.0 CI](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/rocq-ci.yml/badge.svg)](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/rocq-ci.yml)
[![Agda 2.9 CI](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/agda-ci.yml/badge.svg)](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/agda-ci.yml)
[![Dafny 4.11 CI](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/dafny-ci.yml/badge.svg)](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/dafny-ci.yml)
[![SMT Z3 CI](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/smt-ci.yml/badge.svg)](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/smt-ci.yml)
[![TLA+ TLC CI](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/tla-ci.yml/badge.svg)](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/tla-ci.yml)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23833938.svg)](https://doi.org/10.5281/zenodo.23833938)
![Lean 4.35.0](https://img.shields.io/badge/Lean-v4.35.0-blue?logo=lean)
![Zero Sorry](https://img.shields.io/badge/Proof_Audit-6_Provers_%7C_130_Theorems_%7C_0_Axioms-success)
[![License: AGPL v3](https://img.shields.io/badge/Code_License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/Theory_%26_Taxonomy-CC_BY--NC--SA_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

Ce dépôt contient la sextuple certification formelle mécanisée sous **Lean 4 (v4.35.0)**, **The Rocq Prover 9.1.0**, **Agda 2.9.0** (`--safe --without-K`), **Dafny 4.11.0**, **SMT-LIB 2.6 / Z3 5.3.3** et **TLA+ / TLC 2.19** (validation croisée sur **six systèmes formels indépendants**, **130 / 130 théorèmes certifiés** de la Strate 0 + `all176Entries_unique_labels` et **11 / 11 blocs d'évaluation bit à bit** dans chaque système, **10 / 10 théorèmes géométriques Lean 4** dans les extensions lexicales actives de la Strate 1, **0 `sorry`**, **0 `Admitted`**, **0 `postulate`**, **0 `{:axiom}`**, **0 axiome personnalisé**) de l'architecture fonctionnelle de la **Cartographie des affects**, ainsi que le référentiel algorithmique complet des **176 positions de l'espace affectif ($Z = 0$ à $Z = 7$)**.

> **English Overview:** This repository contains the six-fold mechanized formal verification in **Lean 4 (v4.35.0)**, **The Rocq Prover 9.1.0**, **Agda 2.9.0** (`--safe --without-K`), **Dafny 4.11.0**, **SMT-LIB 2.6 / Z3 5.3.3**, and **TLA+ / TLC 2.19** (cross-validated across six independent formal verification paradigms) of **CARTOGRAFFECT** (*Cartographie des affects*), a hierarchical 3D affective geometry, closed-loop generative predictive circuit, and taxonomy mapping **176 affective states** across 8 vertical strata ($Z = 0$ to $Z = 7$). Built with **0 external dependencies**, **0 `sorry`**, **0 `admit` / `Admitted`**, **0 `postulate` / `trustMe`**, **0 `{:axiom}` / `assume`**, and **0 custom axioms** across all six suites (**130 / 130** Strate 0 theorems + `all176Entries_unique_labels` and **11 / 11** computational evaluation blocks matched bit-for-bit across all 6 provers, plus **21 / 21** theorems in `PredictiveEngineCanonical.lean` and **10 / 10** active geometric Strate 1 Lean 4 theorems in `extensions/lexicon/lean/`), it formally certifies $L_1$ attentional budget conservation, involutive antagonist symmetries, exhaustive taxonomic partitioning, exact integer Markov transition conservation ($4 \cdot \mathrm{scale}^6$), unified $(R_t, Z_t, \pi_A, \pi_C)$ coupling, operant contingency factorization (`EndToEndBridge`), and the master theorems `end_to_end_coherence` and `full_end_to_end_lexicon_resolution`, paired with an isomorphic Python numerical engine (`python/cartograffect_predictive_engine.py`).

---

## Déclaration relative à l’utilisation de l’intelligence artificielle générative et statut épistémique du matériel formel

- **Paternité intégrale de l’auteur sur le modèle psychologique, conceptuel et taxonomique :** L’architecture conceptuelle, la psychologie affective, la taxonomie des 176 états et l’orientation théorique de **CARTOGRAFFECT®** sont entièrement conçues et assumées par **Manuel Cabelguen, Ph. D.** (psychologue clinicien et chercheur indépendant), qui assume l’entière responsabilité des hypothèses cliniques et de la lecture critique des travaux cités.
- **Rôle d’assistance technique de l’IA générative :** Des outils d’intelligence artificielle générative ont servi d’**assistants techniques** pour la rédaction, la réalisation du site web vitrine, la traduction et la **transposition exploratoire** de propriétés du modèle vers des assistants de preuve formelle (Lean 4, Rocq, Agda, Dafny, Z3, TLA+) et des scripts compagnons hébergés sur GitHub.
- **Portée et limites de vérification (transparence méthodologique) :** Psychologue clinicien et **non mathématicien formel**, l’auteur **n’a pas vérifié manuellement ligne par ligne** le code mathématique et formel généré. La validité technique de ces artefacts repose sur la **compilation et vérification mécanique** par les prouveurs et solveurs exécutés en intégration continue (0 `sorry`, 0 `Admitted`, 0 `postulate`, 0 `{:axiom}`) ainsi que sur les **tests automatisés**. Ce matériel formel et algorithmique est distinct du manuscrit théorique et est **publié en accès libre sur GitHub précisément pour inviter l’audit indépendant de mathématiciens et de spécialistes des méthodes formelles**.

> **AI Transparency & Epistemic Notice (EN):** The conceptual architecture, affective psychology, 176-state taxonomy, and theoretical orientation of CARTOGRAFFECT® are entirely conceived and owned by Manuel Cabelguen, Ph. D. Generative AI tools served as technical assistants for writing, website engineering, translation, and exploratory transposition of model properties into formal proof assistants (Lean 4, Rocq, Agda, Dafny, Z3, TLA+) and GitHub scripts. As a clinical psychologist and not a formal mathematician, the author has not manually verified the generated mathematical/formal code line by line; technical validity rests on mechanical compilation by the respective provers/solvers and automated tests, and all formal material is published open-access on GitHub precisely to invite independent audit by mathematicians and formal-methods specialists.

---

## Architecture des Modules Certifiés

1. **[`Cartograffect/PredictiveEngine.lean`](Cartograffect/PredictiveEngine.lean)** : Formalisation de l'écart de prédiction saillant (avec hystérésis de résorption), des trois interfaces (Perceptive, Subjective, Attentionnelle), des régimes de charge/décharge et de la partition des 9 couplages $(A/C)$.
2. **[`Cartograffect/CoreAffect.lean`](Cartograffect/CoreAffect.lean)** : Projection spatiale tridimensionnelle $(X, Y, Z)$, opérateurs centraux ($Z = 0$ à $Z = 7$), loi géométrique des couronnes ($R(Z) = 2Z - 2$ pour $Z \ge 2$), partage discret `apportionRay`, conservation du budget attentionnel, réallocation axiale $\to$ diagonale, suspension descendante endogène (`R5`) et dissipation allostatique court-circuitée vers le Point de Veille $(0, 0, 0)$.
3. **[`Cartograffect/AffectiveMatrix.lean`](Cartograffect/AffectiveMatrix.lean)** : Transduction phénoménologique paramétrique (`PhenomenologicalMapping`, `R3`), formalisation des 8 prototypes de la première couronne ($Z = 2$) et preuve d'involutivité de l'opérateur d'antagonisme (symétrie centrale axiale/diagonale et réflexion diagonale controlatérale pour $Z \ge 3$).
4. **[`Cartograffect/AffectiveDynamics.lean`](Cartograffect/AffectiveDynamics.lean)** : Noyau stochastique inter-strates $Z \to Z + 1$ (`DepthTransitionKernel`, atteignabilité latérale `R8`) et appartenance graduée aux 9 attracteurs taxonomiques (`attractorMembership`, `R1`).
5. **[`Cartograffect/AffectiveTaxonomy.lean`](Cartograffect/AffectiveTaxonomy.lean)** : Partition exhaustive et mutuellement exclusive des 9 groupes d'orientation et sous-secteurs fonctionnels, certification arithmétique des 176 entrées (8 centres + 168 positions périphériques) et démonstration du théorème maître `end_to_end_coherence`.
6. **[`Cartograffect/Lexicon176.lean`](Cartograffect/Lexicon176.lean)** : Répertoire nominal exhaustif des 176 positions affectives ($Z = 0$ à $Z = 7$), vérification mécanique des 84 paires antagonistes et atteignabilité complète (`176 / 176`).
7. **[`Cartograffect/PredictiveCircuit.lean`](Cartograffect/PredictiveCircuit.lean)** : Formalisation générative du circuit continu fermé à 2 boucles × 3 circuits et 6 opérateurs de frontière (Figure 1), dualité transposée Croisement I / II, noyau markovien entier exact (`4 * scale ^ 6`) distinguant extinction passive ($\delta$) et résolution active ($\rho, \kappa$), indépendance P1 ($L_1$) / P2 ($\chi$), ruptures topologiques d'ergodicité et loi unifiée $(R_t, Z_t, \pi_{A,t}, \pi_{C,t})$ couplée au court-circuit `R5` et à `apportionRay`.
8. **[`Cartograffect/AuditTests.lean`](Cartograffect/AuditTests.lean) & [`AUDIT_REPORT.md`](AUDIT_REPORT.md)** : Audit axiomatique (`#print axioms` sur 130 théorèmes de la Strate 0 + `all176Entries_unique_labels`), tests d'évaluation constructive (`#eval`) et certificat d'audit formel complet.
9. **[`Cartograffect/OperantFactorization.lean`](Cartograffect/OperantFactorization.lean)** : Module dérivé factorisant les 4 prototypes diagonaux de la première couronne ($Z = 2$) sur les contingences opérantes $\{R^+, R^-, P^+, P^-\}$ et reliant les pôles axiaux par métrique $L_1$ (7 théorèmes).
10. **[`Cartograffect/EndToEndBridge.lean`](Cartograffect/EndToEndBridge.lean)** : Module de soudure de bout en bout reliant le Moteur prédictif, le circuit continu à 6 opérateurs, la loi unifiée, la factorisation opérante sur toutes les strates $Z \in \mathbb{N}$ (y compris les 120 états latéraux et les lignées $Z=2 \to Z=7$), la taxonomie et l'unicité nominale de `Lexicon176` (10 théorèmes + `all176Entries_unique_labels`).
11. **[`Cartograffect.lean`](Cartograffect.lean)** : Module racine agrégeant l'ensemble des 11 modules de la bibliothèque formelle Strate 0.
12. **[`extensions/predictive_engine/PredictiveEngineCanonical.lean`](extensions/predictive_engine/PredictiveEngineCanonical.lean) & [`extensions/predictive_engine/EPISTEMIC_STATUS.md`](extensions/predictive_engine/EPISTEMIC_STATUS.md)** : Extension Lean 4 canonique (21/21 théorèmes, 0 `sorryAx`) formalisant les arbitrages A1–A4 du Moteur prédictif (réponses isolées sur 3 circuits, projection directe du niveau d'opérabilité $Z \ge 1$, ensembles de possibles $\{±X, ±Y, Z\}$, réduction d'information $\Delta H \ge 0$, loi de couronne, disjonction stricte de `Veille (0,0,0)` hors de l'`INTERFACE ATTENTIONNELLE`, distinction extinction passive / résolution active et ponts vers `EndToEndBridge`).
13. **[`extensions/lexicon/lean/`](extensions/lexicon/lean/)** : 3 modules d'extension géométrique et combinatoire actifs de la Strate 1 compilés sous Lean 4.35.0 avec `-DwarningAsError=true` et audités par `#print axioms` (**10/10 théorèmes géométriques, 0 `sorryAx`, 0 constante statistique Python codée en dur**) : [`PolarityAntipodal3D.lean`](extensions/lexicon/lean/PolarityAntipodal3D.lean) (4/4), [`AuditGeometricLexicalPlacement.lean`](extensions/lexicon/lean/AuditGeometricLexicalPlacement.lean) (4/4) et [`EmotionWheelsChallenge.lean`](extensions/lexicon/lean/EmotionWheelsChallenge.lean) (2/2) *(l'ancien module synthétique `SchererGRID.lean` a été archivé dans `archive/deprecated_synthetic_v2/`)*.
14. **[`python/cartograffect_predictive_engine.py`](python/cartograffect_predictive_engine.py) & [`python/test_predictive_engine.py`](python/test_predictive_engine.py)** : Moteur prédictif numérique en Python (matrice markovienne $9\times 9$ factorisée sur `4 * scale^6` avec indépendance P1/P2, analyse spectrale d'ergodicité, diagnostic des 5 ruptures d'ergodicité, assemblage des réponses isolées et projection directe de $Z$, réduction d'information $\Delta H \ge 0$, pont opérant `EndToEndBridge`, et suite de 18 tests unitaires).
15. **[`docs/assets/moteur_predictif_canonique.html`](docs/assets/moteur_predictif_canonique.html) & [`docs/assets/moteur_predictif_article.svg`](docs/assets/moteur_predictif_article.svg)** : Source unique de vérité vectorielle du Moteur prédictif (topologie à 2 boucles contra-rotatives et 6 circuits continus) et export autonome thème clair pour manuscrit sans `var(...)` CSS résiduel.
16. **[`rocq/`](rocq/)** : Validation croisée formelle isolée et entièrement constructive sous **The Rocq Prover 9.1.0** (`From Stdlib` uniquement, 0 dépendance externe), regroupant les **11 modules isomorphes** dans `rocq/theories/` — [`PredictiveEngine.v`](rocq/theories/PredictiveEngine.v), [`CoreAffect.v`](rocq/theories/CoreAffect.v), [`AffectiveMatrix.v`](rocq/theories/AffectiveMatrix.v), [`AffectiveTaxonomy.v`](rocq/theories/AffectiveTaxonomy.v), [`AffectiveDynamics.v`](rocq/theories/AffectiveDynamics.v), [`Lexicon176.v`](rocq/theories/Lexicon176.v), [`PredictiveCircuit.v`](rocq/theories/PredictiveCircuit.v), [`AuditTests.v`](rocq/theories/AuditTests.v), [`OperantFactorization.v`](rocq/theories/OperantFactorization.v), [`EndToEndBridge.v`](rocq/theories/EndToEndBridge.v) et [`Cartograffect.v`](rocq/theories/Cartograffect.v) (`131/131 Closed under the global context`, `Axioms: <none>`, `0 Admitted`) — accompagnés du descripteur de projet [`rocq/_CoqProject`](rocq/_CoqProject), du script d'audit autonome [`rocq/verify.ps1`](rocq/verify.ps1) et du rapport détaillé [`rocq/ROCQ_VALIDATION.md`](rocq/ROCQ_VALIDATION.md).
17. **[`agda/`](agda/)** : Validation croisée formelle intensionnelle sous **Agda 2.9.0** (`{-# OPTIONS --safe --without-K #-}`, compatible HoTT, 0 dépendance externe, uniquement `Agda.Builtin.*`), regroupant **12 modules** dans `agda/src/` ([`Prelude.agda`](agda/src/Cartograffect/Prelude.agda), [`PredictiveEngine.agda`](agda/src/Cartograffect/PredictiveEngine.agda), [`CoreAffect.agda`](agda/src/Cartograffect/CoreAffect.agda), [`AffectiveMatrix.agda`](agda/src/Cartograffect/AffectiveMatrix.agda), [`AffectiveTaxonomy.agda`](agda/src/Cartograffect/AffectiveTaxonomy.agda), [`AffectiveDynamics.agda`](agda/src/Cartograffect/AffectiveDynamics.agda), [`Lexicon176.agda`](agda/src/Cartograffect/Lexicon176.agda), [`PredictiveCircuit.agda`](agda/src/Cartograffect/PredictiveCircuit.agda), [`OperantFactorization.agda`](agda/src/Cartograffect/OperantFactorization.agda), [`EndToEndBridge.agda`](agda/src/Cartograffect/EndToEndBridge.agda), [`AuditTests.agda`](agda/src/Cartograffect/AuditTests.agda), [`Cartograffect.agda`](agda/src/Cartograffect.agda); `130/130` théorèmes + `all176Entries_unique_labels` + `11/11` blocs d'évaluation, `0 postulate`), le descripteur [`agda/cartograffect.agda-lib`](agda/cartograffect.agda-lib), le script [`agda/verify.ps1`](agda/verify.ps1) et le rapport [`agda/AGDA_VALIDATION.md`](agda/AGDA_VALIDATION.md).
18. **[`dafny/`](dafny/)** : Vérification déductive de programmes et compilation exécutable certifiée sous **Dafny 4.11.0** (**3 021 obligations Boogie/Z3 vérifiées**, 0 erreur, 0 `{:axiom}`), regroupant **11 modules** dans `dafny/src/` ([`PredictiveEngine.dfy`](dafny/src/PredictiveEngine.dfy), [`CoreAffect.dfy`](dafny/src/CoreAffect.dfy), [`AffectiveMatrix.dfy`](dafny/src/AffectiveMatrix.dfy), [`AffectiveTaxonomy.dfy`](dafny/src/AffectiveTaxonomy.dfy), [`AffectiveDynamics.dfy`](dafny/src/AffectiveDynamics.dfy), [`Lexicon176.dfy`](dafny/src/Lexicon176.dfy), [`PredictiveCircuit.dfy`](dafny/src/PredictiveCircuit.dfy), [`AuditTests.dfy`](dafny/src/AuditTests.dfy), [`OperantFactorization.dfy`](dafny/src/OperantFactorization.dfy), [`EndToEndBridge.dfy`](dafny/src/EndToEndBridge.dfy), [`Cartograffect.dfy`](dafny/src/Cartograffect.dfy); `132/132` lemmes = `130` théorèmes + `all176Entries_unique_labels` + `all176Entries_closed_under_antagonist`, parité `--target:py` `11/11` blocs exacts), la configuration [`dafny/dfyconfig.toml`](dafny/dfyconfig.toml), le script [`dafny/verify.ps1`](dafny/verify.ps1) et le rapport [`dafny/DAFNY_VALIDATION.md`](dafny/DAFNY_VALIDATION.md).
19. **[`smt/`](smt/)** : Certification par réfutation en logique du premier ordre multi-sortes (**SMT-LIB 2.6 / Z3 5.3.3**), regroupant **10 théories autonomes** dans `smt/theories/` ([`01_PredictiveEngine.smt2`](smt/theories/01_PredictiveEngine.smt2) à [`10_EndToEndBridge.smt2`](smt/theories/10_EndToEndBridge.smt2), **10/10** preuves de cohérence axiomatique `[CONSISTENCY] = sat`, **130/130** théorèmes réfutés `[THM] = unsat`, **2/2** lemmes auxiliaires `[AUX] = unsat` et **11/11** blocs d'évaluation `[EVAL] = unsat`, `0 unknown`), le script [`smt/verify.ps1`](smt/verify.ps1) et le rapport [`smt/SMT_VALIDATION.md`](smt/SMT_VALIDATION.md).
20. **[`tla/`](tla/)** : Spécification en logique temporelle des actions et model checking exhaustif à états finis (**TLA+ SANY + TLC 2.19**), regroupant **18 modules `.tla`** et **8 configurations `.cfg`** dans `tla/specs/` (11 modules théoriques `PredictiveEngine.tla` à `Cartograffect.tla` incluant `OperantFactorization.tla` et `EndToEndBridge.tla`, `132/132` prédicats, `11/11` `EvalBlocks` + **8 modèles TLC** sans violation dont `Model_EndToEndBridge.tla` avec 598 états générés, 175 distincts et vivacité `Prop_EventuallyStratum7 == <>(pt.z = 7)`), le script [`tla/verify.ps1`](tla/verify.ps1) et le rapport [`tla/TLA_VALIDATION.md`](tla/TLA_VALIDATION.md).

---

## Vérification Formelle Mécanisée (Lean 4.35.0 & Rocq 9.0)

L'intégralité du système formel CARTOGRAFFECT est compilée, vérifiée et auditée en continu au sein du pipeline d'Intégration Continue (CI) GitHub Actions.

### Environnement de preuve certifié (CI GitHub Actions)

- **Prover :** Lean 4 (`v4.35.0`, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, Release `x86_64-linux`)
- **Build system :** Lake `5.0.0-src+eb6cafb`
- **Commit d'introduction initiale du noyau formel :** [`6fc3a987ab047974d10b679f6d1fb1c11183e10b`](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/commit/6fc3a987ab047974d10b679f6d1fb1c11183e10b) *(commit de référence initial du noyau des 17 théorèmes et du lexique des 176 entrées, étendu aux modules `AffectiveDynamics`, `PredictiveCircuit` et aux résolutions documentées dans [`AUDIT_REPORT.md`](AUDIT_REPORT.md))*
- **Compilation `lake build` (`warningAsError := true`) :** **14 cibles compilées** avec succès (11 modules Strate 0 + `PredictiveEngineCanonical.lean`, 0 erreur, 0 avertissement).
- **Audit statique et axiomatique :** `Select-String` / `git grep` $\rightarrow$ **0 `sorry`, 0 `admit`, 0 `axiom`, 0 `unsafe`, 0 `implemented_by`, 0 `noncomputable`** ; **130 théorèmes Strate 0 audités** (+ `all176Entries_unique_labels`) par `#print axioms` (113 du noyau + 7 de `OperantFactorization` + 10 de `EndToEndBridge`), complétés par **21/21** théorèmes dans `PredictiveEngineCanonical.lean` et **10/10** théorèmes géométriques Strate 1 Lean actifs dans `extensions/lexicon/lean/` (**0 `sorryAx`**).
- **Dépendances externes :** **0** (aucune dépendance vis-à-vis de Mathlib ou Batteries ; uniquement le noyau formel de Lean 4 et sa bibliothèque standard `Init`).

### Architecture des cibles `lake build`

Le pipeline CI orchestre la compilation stricte de Lake (`lake build`, `warningAsError := true`, couvrant les **11 unités modulaires `.lean` de la Strate 0** et l'extension canonique `PredictiveEngineCanonical`) avec **0 erreur et 0 avertissement** :

1. **[`Cartograffect.PredictiveEngine`](Cartograffect/PredictiveEngine.lean)** : Polarité prédictive involutive, hystérésis, précisions $(\pi_A, \pi_C)$ et transition `engineStep`.
2. **[`Cartograffect.CoreAffect`](Cartograffect/CoreAffect.lean)** : Induction valide du Core Affect, partage discret `apportionRay`, surjectivité sur 176/176, suspension endogène `R5` et dissipation court-circuitée.
3. **[`Cartograffect.AffectiveMatrix`](Cartograffect/AffectiveMatrix.lean)** : Symétrie antagoniste involutive, paramétrisation phénoménologique (`R3`) et permutation controlatérale des amplitudes.
4. **[`Cartograffect.AffectiveDynamics`](Cartograffect/AffectiveDynamics.lean)** : Noyau stochastique `DepthTransitionKernel` ($Z \to Z + 1$) et appartenance graduée `attractorMembership` (`R1`, `R8`).
5. **[`Cartograffect.AffectiveTaxonomy`](Cartograffect/AffectiveTaxonomy.lean)** : Certification combinatoire des 176 états affectifs ($Z = 0$ à $Z = 7$), exhaustivité/exclusivité des groupes taxonomiques, sous-secteurs et cohérence de bout en bout (`end_to_end_coherence`).
6. **[`Cartograffect.Lexicon176`](Cartograffect/Lexicon176.lean)** : Instanciation explicite des 176 entrées lexicales, validité géométrique $L_1$, unicité des coordonnées, clôture antagoniste et atteignabilité complète.
7. **[`Cartograffect.PredictiveCircuit`](Cartograffect/PredictiveCircuit.lean)** : Boucle fermée continue à 6 opérateurs, bijection $L_1$, noyau entier exact (`4 * scale ^ 6`, extinction passive $\delta$ vs résolution active, P1 vs P2, ruptures topologiques) et loi unifiée $(R_t, Z_t, \pi_A, \pi_C)$.
8. **[`Cartograffect.AuditTests`](Cartograffect/AuditTests.lean)** : Audit des dépendances axiomatiques (`#print axioms` sur les 130 théorèmes Strate 0 + `all176Entries_unique_labels`) et tests d'évaluation constructive (`#eval`, blocs 1 à 11).
9. **[`Cartograffect.OperantFactorization`](Cartograffect/OperantFactorization.lean)** : Factorisation structurale des contingences opérantes $\{R^+, R^-, P^+, P^-\}$ sur $Z = 2$ et pont métrique $L_1$ des pôles axiaux (7 théorèmes).
10. **[`Cartograffect.EndToEndBridge`](Cartograffect/EndToEndBridge.lean)** : Soudure formelle de bout en bout entre le circuit prédictif, le relèvement opérant sur toutes les strates $Z$, la dynamique inter-strates jusqu'aux sentiments transcendantaux ($Z = 7$), la taxonomie et l'unicité nominale des 176 entrées (10 théorèmes + `all176Entries_unique_labels`).
11. **[`Cartograffect`](Cartograffect.lean)** : Module racine agrégeant l'ensemble de la bibliothèque formelle.

> *Note sur les cibles `lake build` :* L'audit complet de la Strate 0 couvre désormais **130 théorèmes** (`113` du noyau dans [`AUDIT_REPORT.md`](AUDIT_REPORT.md) + `7` de `OperantFactorization` + `10` de `EndToEndBridge`, ainsi que le lemme d'audit `all176Entries_unique_labels`), complétés par **21 théorèmes** dans `PredictiveEngineCanonical.lean` et **10 théorèmes géométriques** dans `extensions/lexicon/lean/` (synthèse complète dans [`VALIDATION.md`](VALIDATION.md)).

---

### Tableau synthétique du noyau historique (17 théorèmes fondateurs, complétés par 113 théorèmes — total 130)

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

### Validation croisée indépendante sous Rocq 9.0 (CI GitHub Actions & [`rocq/ROCQ_VALIDATION.md`](rocq/ROCQ_VALIDATION.md))

En complément de Lean 4.35.0, l'ensemble du développement formel est porté et vérifié de façon strictement isolée dans [`rocq/`](rocq/) sur un second assistant de preuve indépendant (**Rocq 9.0** en CI et **The Rocq Prover 9.1.0** pour l'audit complet consigné dans [`rocq/ROCQ_VALIDATION.md`](rocq/ROCQ_VALIDATION.md)) :

- **Environnement CI ([`.github/workflows/rocq-ci.yml`](.github/workflows/rocq-ci.yml)) :** Conteneur officiel `rocq/rocq-prover:9.0` sur `ubuntu-latest`, déclenché sur `rocq/**` et `.github/workflows/rocq-ci.yml`.
- **Bibliothèque et configuration ([`rocq/_CoqProject`](rocq/_CoqProject)) :** **`From Stdlib` uniquement** (`Bool`, `Arith`, `PeanoNat`, `NArith`, `ZArith`, `Lia`, `String`, `List`, `Eqdep_dec`) — **0 dépendance externe**, espace logique `-Q theories CartograffectRocq`.
- **Audit statique (`0 Admitted` / `0 Axiom`) :** Contrôle CI par `grep -rnE "\b(Admitted|give_up|Axiom|Parameter|Conjecture)\b" theories/` et scan syntaxique hors commentaires imbriqués `(* ... *)` et chaînes dans [`rocq/verify.ps1`](rocq/verify.ps1) (**0** occurrence de `Admitted`, `admit`, `Axiom`, `Parameter`, `Conjecture`, `Variable`, `Hypothesis`, `Unsafe`, `vm_cast_no_check`, `native_cast_no_check`, `Declare ML Module`).
- **Compilation stricte :** Génération et exécution via `rocq makefile -f _CoqProject -o Makefile && make -j$(nproc)` en CI, et `rocq compile -q -w +default -Q theories CartograffectRocq` dans `verify.ps1` (**0 erreur, 0 avertissement**).
- **Certification constructive intégrale (`Print Assumptions` & `rocq check -o`) :**
  - **130 / 130 théorèmes** (+ `all176Entries_unique_labels` = **131 / 131** vérifications) rapportés **`Closed under the global context`** (**100 % constructifs, 0 axiome**, incluant `end_to_end_coherence` et `full_end_to_end_lexicon_resolution` grâce à l'irrélevance de preuve décidable `isValidCoreAffect_pi`, les entiers binaires `N` de `NArith`, les 7 théorèmes de `OperantFactorization.v` et les 10 théorèmes de `EndToEndBridge.v` ; répartition `7 + 23 + 13 + 10 + 10 + 9 + 41 + 7 + 10 = 130`).
  - **Vérificateur indépendant du noyau (`rocq check -silent -o -Q theories CartograffectRocq CartograffectRocq.Cartograffect`) :** `ExitCode 0`, **`Axioms: <none>`**, `Set is predicative`, `Rewrite rules are not allowed`, 0 constante ou inductif non sûr.
  - **Parité des 11 blocs d'évaluation concrète (`Compute` $\leftrightarrow$ `#eval`) :** Concordance bit à bit entre `AuditTests.v` et `AuditTests.lean` sur les 11 scénarios (Point de Veille `(0, 0, 0)`, Surprise `(0, 0, 1)`, dyade Colère `(-1, 1, 2)` / Calme `(1, -1, 2)`, suspension et court-circuit `R5`, Consternation latérale `(-1, 3, 3)`, noyau `canonicalDepthKernel`, attracteurs `R1`, mapping `R3`, `circuitRowSum = 4000000000000%N`, loi unifiée `nextChargeAccumulator = (700%N, 1300%N)`).

| # | Module Rocq (`CartograffectRocq.*`) | Équivalent Lean 4 | Lignes | Temps (`verify.ps1`) |
|---|---|---|---|---|
| 1 | [`rocq/theories/PredictiveEngine.v`](rocq/theories/PredictiveEngine.v) | `Cartograffect/PredictiveEngine.lean` | 599 | 2,14 s |
| 2 | [`rocq/theories/CoreAffect.v`](rocq/theories/CoreAffect.v) | `Cartograffect/CoreAffect.lean` | 1 098 | 2,72 s |
| 3 | [`rocq/theories/AffectiveMatrix.v`](rocq/theories/AffectiveMatrix.v) | `Cartograffect/AffectiveMatrix.lean` | 540 | 2,38 s |
| 4 | [`rocq/theories/AffectiveTaxonomy.v`](rocq/theories/AffectiveTaxonomy.v) | `Cartograffect/AffectiveTaxonomy.lean` | 517 | 3,23 s |
| 5 | [`rocq/theories/AffectiveDynamics.v`](rocq/theories/AffectiveDynamics.v) | `Cartograffect/AffectiveDynamics.lean` | 844 | 10,08 s |
| 6 | [`rocq/theories/Lexicon176.v`](rocq/theories/Lexicon176.v) | `Cartograffect/Lexicon176.lean` | 374 | 1,54 s |
| 7 | [`rocq/theories/PredictiveCircuit.v`](rocq/theories/PredictiveCircuit.v) | `Cartograffect/PredictiveCircuit.lean` | 1 452 | 4,08 s |
| 8 | [`rocq/theories/AuditTests.v`](rocq/theories/AuditTests.v) | `Cartograffect/AuditTests.lean` | 363 | 18,19 s |
| 9 | [`rocq/theories/OperantFactorization.v`](rocq/theories/OperantFactorization.v) | `Cartograffect/OperantFactorization.lean` | 190 | 2,43 s |
| 10 | [`rocq/theories/EndToEndBridge.v`](rocq/theories/EndToEndBridge.v) | `Cartograffect/EndToEndBridge.lean` | 867 | ~15 s |
| 11 | [`rocq/theories/Cartograffect.v`](rocq/theories/Cartograffect.v) | `Cartograffect.lean` | 17 | 1,35 s |
| — | Vérificateur indépendant (`rocq check -o`) | Noyau autonome (`rocqchk`) | — | ~66 s |
| **Total** | **11 fichiers (bibliothèque + audit + racine)** | **11 fichiers Lean 4** | **6 861** | — |

---

### Synthèse Comparative des 6 Systèmes Formels Indépendants

Chaque suite de vérification réside dans son propre sous-dossier isolé, vérifie les **130 théorèmes audités** (`7 + 23 + 13 + 10 + 10 + 8 + 41 + 1 + 7 + 10`) ainsi que la parité bit à bit sur les **11 blocs d'évaluation concrète**, et dispose de son propre script d'audit local (`verify.ps1`) et workflow GitHub Actions :

| # | Système formel | Fondement logique & paradigme | Dossier | Fichiers | Lignes | Théorèmes | Éval. | Garanties du noyau / solveur | Temps | Rapport |
| :-: | :--- | :--- | :--- | :-: | :-: | :-: | :-: | :--- | :-: | :--- |
| 1 | **Lean 4** (`v4.35.0`) | Calcul des Constructions Inductives (CIC + quotients) | [`Cartograffect/`](Cartograffect/) | 11 `.lean` | 5 654 | 130 / 130 | 11 `#eval` | `0 sorryAx`, `#print axioms`, `+21` (`PredictiveEngineCanonical`) & `+10` (Strate 1) | ~15 s | [`AUDIT_REPORT.md`](AUDIT_REPORT.md) |
| 2 | **Rocq Prover** (`9.1.0`) | Calcul des Constructions Inductives prédicatif (`Stdlib`) | [`rocq/`](rocq/) | 11 `.v` | 6 861 | 130 / 130 | 11 `Compute` | `0 Admitted`, `131/131 Closed under the global context`, `Axioms: <none>` | ~90 s | [`rocq/ROCQ_VALIDATION.md`](rocq/ROCQ_VALIDATION.md) |
| 3 | **Agda** (`2.9.0`) | Théorie des types de Martin-Löf intensionnelle (compatible HoTT) | [`agda/`](agda/) | 12 `.agda` | 6 311 | 130 / 130 | 11 `refl` | `{-# OPTIONS --safe --without-K #-}`, `0 postulate`, `0 trustMe` | ~30 s | [`agda/AGDA_VALIDATION.md`](agda/AGDA_VALIDATION.md) |
| 4 | **Dafny** (`4.11.0`) | Logique de Hoare / plus faible précondition (Boogie + Z3) & exécution Python | [`dafny/`](dafny/) | 11 `.dfy` | 8 953 | 130 / 130 (`132` lemmes) | 11 `Main()` | `3021 verified, 0 errors`, `0 {:axiom}`, `0 assume` | ~60 s | [`dafny/DAFNY_VALIDATION.md`](dafny/DAFNY_VALIDATION.md) |
| 5 | **SMT-LIB 2.6 / Z3** (`5.3.3`) | Logique du premier ordre multi-sortes par réfutation (`check-sat`) | [`smt/`](smt/) | 10 `.smt2` | 6 168 | 130 / 130 | 11 `unsat` + `get-value` | `10/10 [CONSISTENCY] = sat`, `130/130 [THM] = unsat`, `2/2 [AUX] = unsat`, `0 unknown` | ~25 s | [`smt/SMT_VALIDATION.md`](smt/SMT_VALIDATION.md) |
| 6 | **TLA+ / TLC** (`SANY` + `TLC 2.19`) | Logique temporelle des actions (TLA) & model checking exhaustif | [`tla/`](tla/) | 18 `.tla` + 8 `.cfg` | 2 549 | 130 / 130 (`132` préd.) | 11 `ASSUME` / `INVARIANT` | `18/18 SANY OK`, `8/8 TLC OK` (0 violation, `0 AXIOM`, `Model_EndToEndBridge` 598/175 états) | ~35 s | [`tla/TLA_VALIDATION.md`](tla/TLA_VALIDATION.md) |

---

### Validation croisée sous Agda 2.9.0 (`--safe --without-K` — [`agda/AGDA_VALIDATION.md`](agda/AGDA_VALIDATION.md))

La suite [`agda/`](agda/) certifie les 130 théorèmes (+ `all176Entries_unique_labels`) et les 11 blocs d'évaluation dans la théorie intensionnelle des types de Martin-Löf sous les options **`{-# OPTIONS --safe --without-K #-}`** (sans l'axiome K de Streicher ni aucune dépendance externe au-delà de `Agda.Builtin.*`) :
- **Fondations constructives autonomes ([`agda/src/Cartograffect/Prelude.agda`](agda/src/Cartograffect/Prelude.agda), 509 lignes) :** Preuves constructives de l'arithmétique sur `Nat` et `Int`, unicité des preuves d'ordre et d'égalité booléenne (`UIP-Bool`, `≤ℕ-pi`), théorème de division euclidienne certifiée (`div-mod-eq`, `mod-<`, `÷-mono-≤`, `÷-≤-of-≤-*`, `÷-<-of-<-*`, `div-mul-add-exact`) et réflexion booléenne (`All`, `_∈_`, `All-lookup`).
- **Résultat de vérification ([`agda/verify.ps1`](agda/verify.ps1)) :** **12/12 modules vérifiés** depuis un état vierge (`0 postulate`, `0 trustMe`, `0` trou `{!}`), **130/130 théorèmes** (+ `all176Entries_unique_labels`) et **11/11 blocs d'évaluation** prouvés par pure réflexivité définitionnelle (`refl`), incluant `circuitRowSum = 4000000000000` et `circuitWeight = 101500000000`.

### Validation croisée sous Dafny 4.11.0 (Vérification déductive & exécution certifiée — [`dafny/DAFNY_VALIDATION.md`](dafny/DAFNY_VALIDATION.md))

La suite [`dafny/`](dafny/) formalise les 10 modules fonctionnels (dont `OperantFactorization` et `EndToEndBridge`) et le module racine sous forme de types algébriques, sous-types raffinés (`type CoreAffectState = p: CoreAffectPoint | IsValidCoreAffect(p)`), fonctions pures avec pré/post-conditions (`requires` / `ensures`) et lemmes inductifs :
- **Arbre de décision équilibré pour le lexique des 176 états ([`dafny/src/Lexicon176.dfy`](dafny/src/Lexicon176.dfy) & [`dafny/src/EndToEndBridge.dfy`](dafny/src/EndToEndBridge.dfy)) :** Indexation spatiale $O(1)$ par strate `PointZ0..PointZ7`, inverse gauche `IndexInZ0..IndexInZ7` et arbre de décision `LabelRank` certifiant `all176Entries_unique_labels` et `all176Entries_closed_under_antagonist`.
- **Factorisation algébrique non linéaire ([`dafny/src/PredictiveCircuit.dfy`](dafny/src/PredictiveCircuit.dfy)) :** Encapsulation contrôlée `NatProd` et lemmes de distributivité exacte certifiant la conservation markovienne $4 \cdot \mathrm{scale}^6$, la dérive de Lyapunov et la borne euclidienne de l'accumulateur de charge $R_t$.
- **Résultat de vérification ([`dafny/verify.ps1`](dafny/verify.ps1)) :** **`Dafny program verifier finished with 3021 verified, 0 errors`** (`0 {:axiom}`, `0 {:verify false}`, `0 assume`, **132/132 lemmes** = 130 théorèmes + `all176Entries_unique_labels` + `all176Entries_closed_under_antagonist`) et exécution certifiée de `AuditTests.Main()` (`dafny run --target:py --no-verify`) restituant bit à bit les 11 blocs (`B1` à `B11`).

### Validation croisée sous SMT-LIB 2.6 / Z3 5.3.3 (Preuve par réfutation — [`smt/SMT_VALIDATION.md`](smt/SMT_VALIDATION.md))

La suite [`smt/`](smt/) encode chaque module dans une théorie SMT-LIB 2.6 autonome à base de types algébriques inductifs (`declare-datatypes`) et de fonctions totales (`define-fun` / `define-fun-rec`) :
- **Non-vacuité axiomatique systématique :** Avant toute preuve par réfutation dans chacun des 10 fichiers `.smt2` (incluant `10_EndToEndBridge.smt2`), une requête `[CONSISTENCY]` vérifie que le système d'axiomes et de définitions admet un modèle concret (**`10 / 10 sat`**), éliminant tout risque de preuve triviale par explosion (*ex falso quodlibet*).
- **Réfutation universelle (`push` / `assert (not P)` / `check-sat` / `pop`) :** Chacun des **130 théorèmes** (`[THM]`), les **2 lemmes auxiliaires** `[AUX]` (`canonicalDepthKernel_laws` et `all176Entries_unique_labels`) et les **11 blocs d'évaluation** (`[EVAL]`) sont certifiés par insatisfiabilité de leur négation (**`143 / 143 unsat`**, `0 unknown`), complétés par l'extraction `(get-value ...)` dans `08_AuditTests.smt2`.

### Validation croisée sous TLA+ / TLC 2.19 (Logique temporelle & Model Checking — [`tla/TLA_VALIDATION.md`](tla/TLA_VALIDATION.md))

La suite [`tla/`](tla/) combine la vérification statique des **132 prédicats de théorèmes** (`130` théorèmes + `Thm_all176Entries_unique_labels` + `Thm_all176Entries_closed_under_antagonist`) et des **11 blocs d'évaluation** (`EvalBlock01..11`) avec l'exploration exhaustive d'états par `TLC 2.19` sur **8 modèles TLC** (`AuditTests`, `Model_Dissipation`, `Model_Engine`, `Model_DepthKernel`, `Model_Circuit`, `Model_Unified`, `Model_OperantFactorization`, `Model_EndToEndBridge`) :
- **Arithmétique exacte base-$10^6$ (`MulBig` / `AddBig` dans [`tla/specs/PredictiveCircuit.tla`](tla/specs/PredictiveCircuit.tla)) :** Représentation exacte par paires `<<hi, lo>>` permettant à TLC (entiers signés 32 bits) de certifier la somme de ligne markovienne au profil `scale = 100` (`<<4000000, 0>>` $= 4\,000\,000\,000\,000$) et la transition P2 (`<<101500, 0>>` $= 101\,500\,000\,000$) en complément du profil rationnellement équivalent `scale = 20` ($4 \cdot 20^6 = 256\,000\,000$).
- **Résultat de vérification ([`tla/verify.ps1`](tla/verify.ps1)) :** **18/18 modules validés par SANY**, **8/8 modèles certifiés par TLC** (incluant `AuditTests`, `Model_Dissipation` [176 états], `Model_Engine` [11 états], `Model_DepthKernel` [85 états], `Model_Circuit` [18 états], `Model_Unified` [1 916 états], `Model_OperantFactorization` [1 état] et `Model_EndToEndBridge` [598 états générés, 175 distincts, vivacité `Prop_EventuallyStratum7 == <>(pt.z = 7)`], **0 `AXIOM`**, **0 violation d'invariant**, **0 deadlock**).

---

### Instructions de reproduction locale

Tout pair évaluateur peut reproduire, compiler et auditer mécaniquement l'ensemble des preuves **Lean 4**, des preuves **Rocq 9.0** et des tests **Python** en local :

#### Lean 4.35.0 & Moteur Python

```bash
# 1. Cloner le dépôt et se positionner à la racine
git clone https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT.git
cd CARTOGRAFFECT

# 2. Vérification des versions de la toolchain (Lean 4.35.0 & Lake 5.0.0)
lean --version
lake --version

# 3. Compilation stricte de la bibliothèque et vérification formelle (12 cibles)
lake build

# 4. Exécution du banc d'audit axiomatique (#print axioms, 113 théorèmes du noyau) et des tests (#eval)
lake env lean Cartograffect/AuditTests.lean

# 5. Audit statique d'intégrité (garantie de 0 sorry, 0 admit, 0 axiome ad hoc)
git grep -n -E "\b(sorry|admit|axiom|unsafe|implemented_by|noncomputable)\b" -- Cartograffect/ Cartograffect.lean

# 6. Tests unitaires et contrôle de parité du moteur prédictif Python (12 tests)
python -m unittest discover -s python -v
python python/cartograffect_predictive_engine.py
```

#### Rocq 9.0 (Linux / macOS)

```bash
# Depuis la racine du dépôt :
cd rocq

# 1. Audit statique (0 Admitted / 0 Axiom)
grep -rnE "\b(Admitted|give_up|Axiom|Parameter|Conjecture)\b" theories/

# 2. Génération du Makefile et compilation parallèle stricte des 10 modules
rocq makefile -f _CoqProject -o Makefile && make -j$(nproc)

# 3. Vérification indépendante du noyau (Axioms: <none>)
rocq check -silent -o -Q theories CartograffectRocq CartograffectRocq.Cartograffect
```

#### Rocq 9.0+ (Windows PowerShell)

```powershell
# Exécution du script autonome d'audit complet (compilation -w +default, scan syntaxique,
# contrôle des 120 Print Assumptions, évaluations Compute et rocq check -o) :
.\rocq\verify.ps1
```

#### Agda 2.9.0 (`--safe --without-K`)

```powershell
# Audit statique (--safe --without-K, 0 postulate/trustMe/hole), recensement des 120 théorèmes
# et vérification de types clean-room des 11 modules .agda :
powershell -ExecutionPolicy Bypass -File .\agda\verify.ps1
```

#### Dafny 4.11.0 (Vérification déductive Boogie/Z3 & exécution certifiée)

```powershell
# Audit statique (0 {:axiom}, 0 {:verify false}, 0 assume), vérification formelle des 10 modules
# (2139 obligations vérifiées) et exécution des 11 blocs dans AuditTests.Main() :
powershell -ExecutionPolicy Bypass -File .\dafny\verify.ps1
```

#### SMT-LIB 2.6 / Z3 5.3.3

```powershell
# Vérification des 9 théories SMT-LIB 2.6 (9/9 [CONSISTENCY] = sat, 120/120 [THM] = unsat,
# 11/11 [EVAL] = unsat et parité exacte des valeurs get-value) :
powershell -ExecutionPolicy Bypass -File .\smt\verify.ps1
```

#### TLA+ / TLC 2.19 (SANY + Model Checking)

```powershell
# Audit statique (0 AXIOM), analyse syntaxique/sémantique SANY des 16 modules .tla
# et model checking exhaustif TLC des 7 modèles (AuditTests + 5 temporels + OperantFactorization) :
powershell -ExecutionPolicy Bypass -File .\tla\verify.ps1
```

---

## Documentation associée

- **[`VALIDATION.md`](VALIDATION.md)** : Synthèse globale de validation formelle et computationnelle v2.1.0 (Strate 0 Hexa-Prover 130/130 théorèmes, Strate 1 Lean 36/36 théorèmes, tests `pytest`, gardes d'intégrité et banc *in silico*).
- **[`AUDIT_REPORT.md`](AUDIT_REPORT.md)** : Rapport complet d'audit de certification formelle et de fidélité épistémique sous Lean 4 (Phases 1 à 5 & Section 6 `PredictiveCircuit`).
- **[`rocq/ROCQ_VALIDATION.md`](rocq/ROCQ_VALIDATION.md)** : Rapport complet de validation croisée formelle isolée sous The Rocq Prover 9.1.0 (11 modules `.v`, 130 / 130 théorèmes constructifs + `all176Entries_unique_labels` = 131 / 131 `Closed under the global context`, parité des 11 blocs `Compute` $\leftrightarrow$ `#eval` et vérification `rocq check -o`).
- **[`agda/AGDA_VALIDATION.md`](agda/AGDA_VALIDATION.md)** : Rapport de validation croisée sous Agda 2.9.0 (`{-# OPTIONS --safe --without-K #-}`, 12 modules `.agda`, 130 / 130 théorèmes + `all176Entries_unique_labels`, 11 / 11 blocs `refl`, 0 `postulate`).
- **[`dafny/DAFNY_VALIDATION.md`](dafny/DAFNY_VALIDATION.md)** : Rapport de validation croisée sous Dafny 4.11.0 (11 modules `.dfy`, 3 021 obligations vérifiées, 132 / 132 lemmes = 130 théorèmes + `all176Entries_unique_labels` + `all176Entries_closed_under_antagonist`, exécution certifiée des 11 blocs, 0 `{:axiom}`).
- **[`smt/SMT_VALIDATION.md`](smt/SMT_VALIDATION.md)** : Rapport de validation croisée sous SMT-LIB 2.6 / Z3 5.3.3 (10 théories `.smt2`, 10 / 10 preuves de cohérence `sat`, 130 / 130 théorèmes réfutés `unsat`, 2 / 2 lemmes `AUX` `unsat`, 11 / 11 blocs `unsat`).
- **[`tla/TLA_VALIDATION.md`](tla/TLA_VALIDATION.md)** : Rapport de validation croisée sous TLA+ / TLC 2.19 (18 modules SANY, 8 modèles TLC dont `Model_EndToEndBridge.tla`, 132 / 132 prédicats, 0 violation d'invariant, 0 deadlock).
- **[`docs/01-Article_Cartograffect.md`](docs/01-Article_Cartograffect.md)** : Article théorique de référence (architecture conceptuelle à 4 composantes, fondements et prédictions P1–P5 ; le matériel formel et computationnel approfondi est présenté dans ce compendium technique à titre d'annexe soumise à audit).
- **[`docs/02-Inventaire_176.md`](docs/02-Inventaire_176.md)** : Inventaire exhaustif des 176 positions affectives et relations antagonistes.
- **[`docs/CONVERGENCE_MATRIX.md`](docs/CONVERGENCE_MATRIX.md)** : Matrice de gouvernance épistémique et d'arbitrage entre la Strate 0 (Noyau) et la Strate 1 (satellites).
- **[`extensions/lexicon/EPISTEMIC_STATUS.md`](extensions/lexicon/EPISTEMIC_STATUS.md)** : Charte épistémique du satellite lexical, triangulation GRID/CPM et clôture du prolongement exploratoire Diamant 303.
- **[`extensions/in_silico/EPISTEMIC_STATUS.md`](extensions/in_silico/EPISTEMIC_STATUS.md)** : Charte épistémique du banc de simulation Active Inference (`pymdp`/JAX/NumPyro, P1–P5 et phénotypage DSM-5/HiTOP).
- **[`CHANGELOG.md`](CHANGELOG.md)** & **[`manifest.json`](manifest.json)** : Historique sémantique (`2.1.0`) et carte de traçabilité structurée du Research Compendium.

---

## Auteur et Correspondance

Manuel Cabelguen, Ph. D.  
Correspondance : `manuelcabelguen@gmail.com`  
Identifiants persistants : Dépôt Zenodo [`10.5281/zenodo.23833938`](https://doi.org/10.5281/zenodo.23833938) · Article théorique [`10.5281/zenodo.24022795`](https://doi.org/10.5281/zenodo.24022795) · OSF [`https://osf.io/z89sg`](https://osf.io/z89sg)

---

## Licence / Propriété intellectuelle

Copyright (C) 2025-2026 Manuel Cabelguen — `SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0`

- **Code source, scripts et preuves formelles (Lean 4, Rocq, Agda, Dafny, SMT-LIB/Z3, TLA+, Python et pipelines `extensions/lexicon/` & `extensions/in_silico/`)** : distribués sous licence **GNU AGPLv3** ([`LICENSE`](./LICENSE)).
- **Architecture théorique, manuscrit, géométrie affective et taxonomie des 176 états** : distribués sous licence **Creative Commons BY-NC-SA 4.0** ([`LICENSE-CC-BY-NC-SA-4.0.md`](./LICENSE-CC-BY-NC-SA-4.0.md)). Toute exploitation commerciale est strictement réservée.
- **Clause explicite sur les fichiers hybrides** : pour [`Cartograffect/Lexicon176.lean`](Cartograffect/Lexicon176.lean), [`rocq/theories/Lexicon176.v`](rocq/theories/Lexicon176.v), [`agda/src/Cartograffect/Lexicon176.agda`](agda/src/Cartograffect/Lexicon176.agda), [`dafny/src/Lexicon176.dfy`](dafny/src/Lexicon176.dfy), [`smt/theories/06_Lexicon176.smt2`](smt/theories/06_Lexicon176.smt2), [`tla/specs/Lexicon176.tla`](tla/specs/Lexicon176.tla), [`extensions/in_silico/data/lexicon_176.json`](extensions/in_silico/data/lexicon_176.json) et les explorateurs HTML 3D ([`CARTOGRAFFECT_Interactive_3D_Explorer.html`](extensions/lexicon/CARTOGRAFFECT_Interactive_3D_Explorer.html), [`CARTOGRAFFECT_Diamond_303_Brut.html`](extensions/lexicon/CARTOGRAFFECT_Diamond_303_Brut.html), [`CARTOGRAFFECT_Diamond_303_Complet.html`](extensions/lexicon/CARTOGRAFFECT_Diamond_303_Complet.html)), leur structure logicielle/formelle relève de **GNU AGPLv3**, tandis que la nomenclature, les coordonnées et l'architecture taxonomique embarquées relèvent exclusivement de **CC BY-NC-SA 4.0** (**toute extraction commerciale de la taxonomie est interdite**).
- **Propriété intellectuelle** : *CARTOGRAFFECT®* fait l'objet d'un enregistrement de droit d'auteur auprès de l'Office de la propriété intellectuelle du Canada (CIPO / OPIC, enregistrement n° 1233199). Pour toute demande de licence commerciale, contacter l'auteur (`manuelcabelguen@gmail.com`). Voir aussi [`NOTICE`](./NOTICE).

---

## Citation

Si vous utilisez ce compendium, cette formalisation ou ce modèle, merci de citer l'article théorique de référence ainsi que le compendium formel (source unique : [`CITATION.cff`](CITATION.cff)) :

- **Modèle théorique (`v2.1.0`) :**  
  Cabelguen, M. (2026). *Cartographie des affects : une architecture hiérarchique de l’expérience affective fondée sur le traitement prédictif* (version `v2.1.0`). Zenodo. https://doi.org/10.5281/zenodo.24022795
- **Compendium & vérification formelle (`v2.1.0`) :**  
  Cabelguen, M. (2026). *CARTOGRAFFECT®: Unified Research Compendium — Hexa-Prover Formal Verification, Theory, Lexicon & Active Inference Simulation* (version `v2.1.0`) [Logiciel]. Zenodo. https://doi.org/10.5281/zenodo.23833938 · OSF : https://osf.io/z89sg
- **Assistant de preuve :**  
  de Moura, L., & Ullrich, S. (2021). The Lean 4 Theorem Prover and Programming Language. In A. Platzer & G. Sutcliffe (Eds.), *Automated Deduction – CADE 28* (LNCS, Vol. 12699, pp. 625–635). Springer. https://doi.org/10.1007/978-3-030-79876-5_37

```bibtex
@article{cabelguen2026cartographie,
  author  = {Cabelguen, Manuel},
  title   = {Cartographie des affects : une architecture hi{\'e}rarchique de l'exp{\'e}rience affective fond{\'e}e sur le traitement pr{\'e}dictif},
  year    = {2026},
  version = {2.1.0},
  doi     = {10.5281/zenodo.24022795},
  url     = {https://doi.org/10.5281/zenodo.24022795},
  note    = {Manuscrit th{\'e}orique de r{\'e}f{\'e}rence v2.1.0 (docs/01-Article_Cartograffect.md), enregistrement CIPO / OPIC n° 1233199}
}

@software{cabelguen2026cartograffect,
  author  = {Cabelguen, Manuel},
  title   = {{CARTOGRAFFECT}{\textregistered}: Unified Research Compendium --- Hexa-Prover Formal Verification, Theory, Lexicon \& Active Inference Simulation},
  year    = {2026},
  publisher = {Zenodo},
  version = {2.1.0},
  doi     = {10.5281/zenodo.23833938},
  url     = {https://doi.org/10.5281/zenodo.23833938},
  note    = {Version v2.1.0 (2026-11-22); AGPL-3.0-or-later AND CC-BY-NC-SA-4.0; OSF: https://osf.io/z89sg}
}
```