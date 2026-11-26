# VALIDATION — Synthèse Globale de Certification Formelle et Computationnelle (CARTOGRAFFECT® v2.1.0)

**Projet :** CARTOGRAFFECT® — *Cartographie des affects* (`v2.1.0`)  
**Auteur :** Manuel Cabelguen, Ph. D. (CIPO / OPIC Registration No. `1233199`)  
**Licence :** `SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0`  
**Statut :** ✅ **CERTIFIÉ (Parité Hexa-Prover Strate 0 : 130/130 théorèmes · Strate 1 Lean : 36/36 théorèmes · 0 `sorry` / `Admitted` / `postulate` / `{:axiom}`)**

---

## 1. Strate 0 — Parité Hexa-Prover (6 systèmes formels indépendants, zéro trou de preuve)

Le noyau normatif de la **Strate 0** est vérifié symétriquement sur **six assistants de preuve et solveurs indépendants**, intégrant le module de soudure de bout en bout **`EndToEndBridge`** (`Moteur prédictif / Circuit fermé → Noyau L1 → Matrice → Factorisation opérante {R+, R-, P+, P-} → Dynamique inter-strates → Taxonomie Z=0..7 → Lexicon176`) :

| # | Système formel | Version | Modules / Fichiers | Théorèmes Strate 0 | Lemmes / Contrôles totaux | Blocs d'éval. | Garanties mécaniques vérifiées | Rapport détaillé |
| :-: | :--- | :---: | :---: | :---: | :---: | :---: | :--- | :--- |
| 1 | **Lean 4** | `4.35.0` | **11** `.lean` (`Cartograffect/` + `Cartograffect.lean`) | **130 / 130** | `130` + `all176Entries_unique_labels` + `PredictiveEngineCanonical.lean` (**21/21**) | **11 / 11** `#eval` | `0 sorryAx`, `#print axioms`, `warningAsError := true` | [`AUDIT_REPORT.md`](AUDIT_REPORT.md) |
| 2 | **The Rocq Prover** | `9.1.0` | **11** `.v` (`rocq/theories/`, dont `EndToEndBridge.v`) | **130 / 130** | **131 / 131** `Closed under the global context` | **11 / 11** `Compute` | `Axioms: <none>`, `0 Admitted`, `rocq check -o` | [`rocq/ROCQ_VALIDATION.md`](rocq/ROCQ_VALIDATION.md) |
| 3 | **Agda** | `2.9.0` | **12** `.agda` (`agda/src/`, dont `EndToEndBridge.agda`) | **130 / 130** | `130` + `all176Entries_unique_labels` | **11 / 11** `refl` | `{-# OPTIONS --safe --without-K #-}`, `0 postulate`, `0 trustMe` | [`agda/AGDA_VALIDATION.md`](agda/AGDA_VALIDATION.md) |
| 4 | **Dafny** | `4.11.0` | **11** `.dfy` (`dafny/src/`, dont `EndToEndBridge.dfy`, `Lexicon176.dfy`) | **130 / 130** | **132 / 132** lemmes (**3 021 verified**, `0 errors`) | **11 / 11** `--target:py` | `0 {:axiom}`, `0 {:verify false}`, `0 assume` | [`dafny/DAFNY_VALIDATION.md`](dafny/DAFNY_VALIDATION.md) |
| 5 | **SMT-LIB 2.6 / Z3** | `5.3.3` | **10** `.smt2` (`smt/theories/`, dont `10_EndToEndBridge.smt2`) | **130 / 130** `unsat` | **10/10** `sat` (`CONSISTENCY`), **2/2** `unsat` (`AUX`) | **11 / 11** `unsat` (`EVAL`) | `0 unknown`, `0 timeout`, parité `[VALUES]` | [`smt/SMT_VALIDATION.md`](smt/SMT_VALIDATION.md) |
| 6 | **TLA+ / TLC** | `2.19` | **18** `.tla` SANY + **8** `.cfg` (`tla/specs/`, dont `Model_EndToEndBridge.tla`) | **130 / 130** `Thm_*` | **132 / 132** prédicats, **8 / 8** modèles TLC | **11 / 11** `EvalBlock*` | `0 AXIOM`, `0` violation, `Model_EndToEndBridge` (`598` états, `175` distincts, `<>(pt.z = 7)`) | [`tla/TLA_VALIDATION.md`](tla/TLA_VALIDATION.md) |

### Décomposition des 130 théorèmes Strate 0 (+ lemmes auxiliaires d'audit)

1. **`PredictiveEngine` (7 théorèmes)** : involutivité de `Polarity.invert`, partition des 9 régimes de couplage, boucles inférentielles, `feedbackUpdate` / `feedbackUpdateWeighted`, rémanence et progression de phase `engineStep`.
2. **`CoreAffect` (23 théorèmes)** : géométrie discrète $L_1$ ($R(Z) = 2Z - 2$), partage discret `apportionRay`, conservation budgétaire, surjectivité `176/176` (`projectToCoreAffect_surjective`), suspension endogène `R5` et dissipation allostatique court-circuitée `(0,0,2) → (0,0,0)`.
3. **`AffectiveMatrix` (13 théorèmes)** : valence lexicographique, opérateur d'antagonisme involutif `antagonistPoint` (forme unifiée hors axes), permutation controlatérale des amplitudes, transferts unitaires et indépendance vis-à-vis de `PhenomenologicalMapping` (`R3`).
4. **`AffectiveTaxonomy` (10 théorèmes)** : certification combinatoire des 176 états (`8` centres + `168` périphériques), exhaustivité et exclusivité des 9 groupes et 17 sous-secteurs, liaisons controlatérales et théorème maître `end_to_end_coherence` (18 clauses).
5. **`AffectiveDynamics` (10 théorèmes)** : noyau stochastique inter-strates `DepthTransitionKernel` / `canonicalDepthKernel` ($Z \to Z + 1$), atteignabilité latérale `R8`, instabilité axiale `P2` et attracteurs gradués `attractorMembership` (`R1`).
6. **`Lexicon176` & `AuditTests` (8 + 1 = 9 théorèmes + `all176Entries_unique_labels`)** : cardinalité `176`, validité géométrique, unicité spatiale (`all176Entries_unique_points`), unicité nominale (`all176Entries_unique_labels`), clôture sous antagonisme (`all176Entries_closed_under_antagonist`), complétude spatiale sur $Z \in \{0,\dots,7\}$, atteignabilité déterministe `176/176` et inversion exacte de la polarité hédonique sur les 176 entrées.
7. **`PredictiveCircuit` (41 théorèmes)** : circuit continu fermé à 2 boucles × 3 circuits et 6 opérateurs de frontière, bijection $\Phi_{L_1}$, transposition Croisement I / II, noyau markovien entier exact factorisé sur `4 * scale^6`, distinction résolution active vs extinction passive ($\delta$), indépendance `P1`/`P2`, 5 ruptures d'ergodicité et loi unifiée $(R_t, Z_t, \pi_A, \pi_C)$.
8. **`OperantFactorization` (7 théorèmes)** : factorisation des 4 prototypes diagonaux de $Z = 2$ sur les contingences opérantes $\{R^+, R^-, P^+, P^-\}$, correspondance avec `EnergyRegime`, dualité antagoniste opérante et pont métrique $L_1$ des 4 pôles axiaux pré-opérants.
9. **`EndToEndBridge` (10 théorèmes)** :
   - `circuit_coupling_operant_bridge`
   - `triggerSecondaryGradient_enters_operant`
   - `p2_markov_contagion_enters_operant_punishment`
   - `operant_quadrant_lifting_all_strata`
   - `operant_antagonist_invariance_all_strata`
   - `depthKernel_preserves_operant_quadrant`
   - `operant_lineages_reach_z7_transcendentals`
   - `unified_circuit_to_taxonomy_coherence`
   - `circularCycle_to_taxonomy_and_lexicon_coherence`
   - `full_end_to_end_lexicon_resolution`
10. **Extension canonique `PredictiveEngineCanonical.lean` (21 théorèmes, `0 sorryAx`)** : formalisation Lean 4 des arbitrages A1–A4 (réponses isolées sur 3 circuits, projection directe de $Z \ge 1$, domaines `{±X, ±Y, Z}` disjoints de `Veille (0,0,0)`, réduction d'information $\Delta H \ge 0$, décroissance stricte de Lyapunov en résolution active et ponts vers `OperantFactorization`, `AffectiveTaxonomy` et `Lexicon176`).

---

## 2. Strate 1 — Extensions Lexicales Lean 4.35.0 (`extensions/lexicon/lean/`, 36/36 théorèmes, 0 `sorryAx`)

Les 4 modules Lean 4 du satellite lexical sont compilés avec `lake env lean -DwarningAsError=true` directement au-dessus du référentiel canonique `Cartograffect/Lexicon176.lean` et audités par `#print axioms` (**36 / 36 théorèmes certifiés, 0 `sorryAx`**) :

| # | Module Lean 4 (`extensions/lexicon/lean/`) | Théorèmes | Objet de la certification mécanique | Statut |
| :-: | :--- | :---: | :--- | :---: |
| 1 | [`PolarityAntipodal3D.lean`](extensions/lexicon/lean/PolarityAntipodal3D.lean) | **4 / 4** | Équipartition `84 / 84` en polarité $+Z/-Z$ et invariance antipodale 3D $Z_A + Z_B = 0$ sur les 168 prototypes périphériques | ✅ `0 sorryAx` |
| 2 | [`AuditGeometricLexicalPlacement.lean`](extensions/lexicon/lean/AuditGeometricLexicalPlacement.lean) | **4 / 4** | Conformité sur couronne $L_1$, parité paire $(X+Y) \equiv 0 \pmod 2$, non-centralité et conservation $\|X\|+\|Y\| = 2(Z-1)$ du Corpus 2 | ✅ `0 sorryAx` |
| 3 | [`EmotionWheelsChallenge.lean`](extensions/lexicon/lean/EmotionWheelsChallenge.lean) | **7 / 7** | Involutivité de la Rose des 8 symétries sur 176 pôles, réfutation de l'antagonisme 2D de Plutchik, couverture GEW 3.0 (20/20, H3 100 %), double barrière de Markov, dissociation $Z$ vs intensité (H5) et pureté axiologique du Diamant 303 | ✅ `0 sorryAx` |
| 4 | [`SchererGRID.lean`](extensions/lexicon/lean/SchererGRID.lean) | **21 / 21** | Somme des 5 composantes CPM (142 items), monotonie de l'enveloppe octaédrique $L_1$ et du `Ratio_Z`, partition Coping agi vs subi, plongement injectif des 24 ancres GRID, seuils CCA/Tucker, hiérarchie des 6 strates sémantiques et homéomorphisme radial $L_1 \leftrightarrow L_2$ | ✅ `0 sorryAx` |
| **Total** | **4 modules Strate 1 Lean 4.35.0** | **36 / 36** | **Compilation stricte `-DwarningAsError=true` & audit `#print axioms` complet** | ✅ **100 %** |

---

## 3. Moteur Python Isomorphe, Contrôles de Cohérence & Simulations *in silico*

| Banc de validation | Commande d'exécution | Périmètre vérifié | Statut |
| :--- | :--- | :--- | :---: |
| **Tests unitaires Python (Strate 0 + Strate 1 + Gardes)** | `pytest` | Moteur prédictif exact (`python/test_predictive_engine.py`, factorisation `4*scale^6`, pont `EndToEndBridge`), gardes d'intégrité (`scripts/test_check_consistency.py`) et isomorphisme / Active Inference (`extensions/in_silico/tests/`) | ✅ PASS |
| **Garde-fou de cohérence globale** | `python scripts/check_consistency.py --strict` | 7 catégories d'invariants : parité `VERSION = 2.1.0`, SHA-256 `Lexicon176.lean`, 11 modules Lean Strate 0 (130 th.) + Strate 1 Lean (36 th.), conformité Zenodo/CFF/SPDX, garde A4-Sanctuaire, Zéro-Fuite et contrat `site-payload.json` | ✅ PASS (`ExitCode 0`) |
| **Synchronisation des métadonnées** | `python scripts/sync_metadata.py --check` | Parité exacte `VERSION` (`2.1.0`), `130/130` théorèmes et SHA-256 `Lexicon176.lean` entre `VERSION`, `CITATION.cff`, `.zenodo.json`, `manifest.json` et `extensions/in_silico/pyproject.toml` | ✅ PASS (`ExitCode 0`) |
| **Contrat d'export web déterministe** | `python scripts/export_site_payload.py --check` | Validation croisée déterministe du payload JSON (`schema=1.0`, `version=2.1.0`, `theorems=130`, `provers=6`, `lean_modules=11`, `states=176`, `predictions=5`) | ✅ PASS (`ExitCode 0`) |
| **Pipeline de validation *in silico*** | `python extensions/in_silico/run_all_validations.py --quick` | Expériences 1 à 3 sous `pymdp`/JAX/NumPyro : prédictions falsifiables P1–P5 non circulaires, phénotypes cliniques pure-$\theta$ et Parameter/Model Recovery | ✅ PASS (`ExitCode 0`) |
