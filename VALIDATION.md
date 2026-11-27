# VALIDATION — Synthèse Globale de Certification Formelle et Computationnelle (CARTOGRAFFECT v3.0.0)

**Projet :** CARTOGRAFFECT — *Cartographie des affects* (`v3.0.0`, branche `v3.0.0-dev`)  
**Auteur :** Manuel Cabelguen, Ph. D. (CIPO / OPIC Copyright Registration No. `1233199`)  
**Licences (séparation physique FAIR4RS / OSI) :** Code source & preuves Lean 4 sous **`AGPL-3.0-or-later`** ([`LICENSE`](LICENSE)) · Manuscrit, documentation & tables taxonomiques sous **`CC-BY-4.0`** ([`LICENSE-CC-BY-4.0.md`](LICENSE-CC-BY-4.0.md))  
**Statut :** ✅ **CERTIFIÉ v3.0.0 (Lean 4 prouveur de référence unique : 8 modules normatifs, 148 théorèmes substantiels / 169 déclarations exportées, 8 piliers · `PredictiveEngineCanonical.lean` : 16 + 5 = 21 · Python : 11 tests · 0 `sorryAx`, 0 `native_decide`)**

---

## 1. Dossier d'Audit Prioritaire — [`FORMAL_AUDIT_PACK.md`](FORMAL_AUDIT_PACK.md)

L'audit exhaustif, dédupliqué et vérifiable ligne par ligne de chaque théorème (incluant la ventilation complète des dépendances à `Classical.choice` et les traces brutes `#print axioms`) est consigné dans [`FORMAL_AUDIT_PACK.md`](FORMAL_AUDIT_PACK.md).

> [!IMPORTANT]
> ### Top 8 théorèmes piliers v3.0.0 (lecture prioritaire — [`FORMAL_AUDIT_PACK.md`](FORMAL_AUDIT_PACK.md))
>
> | # | Pilier architectural v3.0 (`DECISIONS_V3.md`) | Théorème de référence | Fichier : Ligne | Axiomes (`#print axioms`) |
> |---:|:---|:---|:---|:---|
> | **P1** | **Option 1A** — Découplage strict `(X, Y, Z)` / canal autonome `A ≥ 0` et surjectivité conjointe | `projectToCoreAffect_surjective` *(+ `autonomousActivation_decoupled_from_core`)* | `Cartograffect/CoreAffect.lean:844` *(`AffectiveMatrix.lean:779`)* | `[propext, Classical.choice, Quot.sound]` |
> | **P2** | **Arbitrage 4** — Validité géométrique et conservation `L1` sous partage positif `(π_A, π_C)` | `deployCouplingWithPrecision_valid` *(+ `apportionRay_exact`)* | `Cartograffect/CoreAffect.lean:488` *(`:345`)* | `[propext, Classical.choice, Quot.sound]` |
> | **P3** | **Option 2a** — Convergence allostatique pas-à-pas stricte et court-circuit unique `2 → 0` | `dissipation_reaches_veille` *(+ `dissipation_from_ge2_never_visits_surprise`)* | `Cartograffect/CoreAffect.lean:1308` *(`:1163`)* | `[propext, Classical.choice, Quot.sound]` |
> | **P4** | **Priorité hédonique (P4) & Antagonisme** — Inversion universelle de valence par morceaux et échange contralatéral (`\|X\| ↔ \|Y\|`) | `antagonistPoint_inverts_hedonic_polarity`, `antagonistPoint_piecewise`, `contralateral_swaps_amplitudes` & `contralateral_group_bindings` | `Cartograffect/AffectiveMatrix.lean:731, :569, :334` & `Cartograffect/AffectiveTaxonomy.lean:307` | `[propext, Classical.choice, Quot.sound]` *(`[none]` pour `contralateral_swaps_amplitudes`)* |
> | **P5** | **Taxonomie neutre Option 1A** — Unicité terminale cohérente sur les 17 sous-secteurs (8 paires conjuguées + centre) | `end_to_end_coherence` | `Cartograffect/AffectiveTaxonomy.lean:547` | `[propext, Classical.choice, Quot.sound]` |
> | **P6** | **Option 3b** — Instabilité axiale P2 restreinte à la Charge négative (`Peur`, `Tristesse`) | `canonicalDepthKernel_axial_instability_p2` *(+ `axial_tristesse_and_discharge_asymmetry_p2`)* | `Cartograffect/AffectiveDynamics.lean:480` *(`PredictiveCircuit.lean:983`)* | `[propext, Classical.choice, Quot.sound]` *(`[propext, Quot.sound]`)* |
> | **P7** | **Dynamique de Lyapunov (P1)** — Constance signée sur `ℤ` de la dérive attendue par goulot `L1` | `lyapunov_expected_drift_constant` *(+ `lyapunov_monotone_free`)* | `Cartograffect/PredictiveCircuit.lean:874` *(`:699`)* | `[propext, Quot.sound]` *(sans `Classical.choice`)* |
> | **P8** | **Bijection $2 \times 2$ de Rolls (`Z = 2`) & Clôture v3.0** — `Rew±/Pun±`, **Calme**, bornés à `Z = 2` et pont global | `rolls_contingencies_z2_bound` & `full_end_to_end_v3_coherence` | `Cartograffect/OperantFactorization.lean:190` & `Cartograffect/EndToEndBridge.lean:277` | `[propext, Classical.choice, Quot.sound]` |
>
> **Cibles empiriques Étude 1 et alignement géométrique v3.0.0 :** P1 met à l'épreuve la **frontière de capacité (`A = 1`, `\|X\| + \|Y\| = R(Z)` en norme $L_1$ vs $L_2$)** conjointement à la surface intérieure sous-saturée (`A < 1`, `\|X\| + \|Y\| < R(Z)`) ; P4 porte sur la priorité hédonique de `X` et l'antagonisme contralatéral sur rayons conjugués (`contralateral_swaps_amplitudes`, `\|X\| ↔ \|Y\|` sans imposer `A' = A`) ; l'Étude 1 cible la bijection $2 \times 2$ de Rolls (`Rew+`, `Rew−`, `Pun+`, `Pun−`, prototype **Calme** en `Z = 2`) et les **8 paires antagonistes conjuguées (`A1, A2, D1, D2` + `L1, L2, L3, L4`)** sur `Z = 3..5` du Tableau 1b (`docs/01-Article_Cartograffect.md`).

---

## 2. Déclaration Transparente d'Usage de l'IA Générative

Conformément à [`docs/01-Article_Cartograffect.md`](docs/01-Article_Cartograffect.md) :

- **Paternité scientifique intégrale :** L'auteur (**Manuel Cabelguen, Ph. D.**) conçoit et assume intégralement l'architecture conceptuelle, la psychologie affective, les arbitrages taxonomiques et l'orientation théorique de **CARTOGRAFFECT**.
- **Assistance technique IA :** Des outils d'intelligence artificielle générative ont servi d'assistants techniques pour l'aide à la rédaction, la réalisation du site web vitrine, la traduction et la formalisation sous l'assistant de preuve de référence Lean 4 (ainsi que pour les annexes exploratoires archivées).
- **Portée de vérification et appel à audit :** Psychologue clinicien et **non mathématicien formel**, l'auteur **n'a pas vérifié manuellement ligne par ligne** le code mathématique et formel généré ; la validité technique repose sur la **compilation et vérification mécanique** par le prouveur (`lake build`, `lake env lean Cartograffect/AuditTests.lean`, `0 sorryAx`, `0 native_decide`) ainsi que sur les **tests automatisés**. L'ensemble est publié en accès libre sur GitHub pour inviter l'**audit indépendant de mathématiciens et de spécialistes des méthodes formelles**.

---

## 3. Strate 0 — Décompte Exact du Cœur Normatif Lean 4 (`v4.35.0`, `Init` uniquement)

| Module normatif (`Cartograffect/`) | Exportés | Auxiliaires / Élémentaires | **Théorèmes substantiels** | Axiomatique (sans `Classical.choice` / avec `Classical.choice`) |
| :--- | :---: | :---: | :---: | :---: |
| [`Cartograffect/PredictiveEngine.lean`](Cartograffect/PredictiveEngine.lean) | 14 | 8 | **6** | 14 / 0 |
| [`Cartograffect/CoreAffect.lean`](Cartograffect/CoreAffect.lean) | 37 | 5 | **32** | 11 / 26 |
| [`Cartograffect/AffectiveMatrix.lean`](Cartograffect/AffectiveMatrix.lean) | 22 | 3 | **19** | 11 / 11 |
| [`Cartograffect/AffectiveTaxonomy.lean`](Cartograffect/AffectiveTaxonomy.lean) | 16 | 0 | **16** | 4 / 12 |
| [`Cartograffect/AffectiveDynamics.lean`](Cartograffect/AffectiveDynamics.lean) | 13 | 0 | **13** | 0 / 13 |
| [`Cartograffect/PredictiveCircuit.lean`](Cartograffect/PredictiveCircuit.lean) | 53 | 5 | **48** | 42 / 11 |
| [`Cartograffect/OperantFactorization.lean`](Cartograffect/OperantFactorization.lean) | 8 | 0 | **8** | 2 / 6 |
| [`Cartograffect/EndToEndBridge.lean`](Cartograffect/EndToEndBridge.lean) | 6 | 0 | **6** | 1 / 5 |
| **TOTAL CŒUR NORMATIF (8 modules)** | **169** | **21** | **148** | **85 / 84** (`0 sorryAx`, `0 native_decide`) |
| **Extension [`PredictiveEngineCanonical.lean`](extensions/predictive_engine/PredictiveEngineCanonical.lean)** | **21** | **5** (`CE1..CE5`) | **16** (`C1..C16`) | **13 / 8** (`0 sorryAx`, `0 native_decide`, `0` import `Lexicon176`) |

- **Isolation de l'annexe exploratoire :** [`Cartograffect/Lexicon176.lean`](Cartograffect/Lexicon176.lean) (`176` entrées sur `Z = 0..7`) est strictement séparé du cœur normatif (0 import dans les 8 modules normatifs et dans `PredictiveEngineCanonical.lean`).
- **Transparence sur `Classical.choice` :** Les théorèmes recourant à `Classical.choice` (sollicité notamment par `omega`) ne sont jamais qualifiés de « constructifs ».
- **Archive figée v2.1.0 des 5 prouveurs secondaires (Principe d'économie) :** Les suites [`rocq/`](rocq/), [`agda/`](agda/), [`dafny/`](dafny/), [`smt/`](smt/) et [`tla/`](tla/) (explicitement requalifié en *bounded model checking* fini sur domaines bornés) correspondent à l'instantané archivé `v2.1.0` et ne font pas partie des assertions CI automatiques v3.0.0 (workflows basculés en `workflow_dispatch` avec préfixe `[LEGACY v2.1 — ARCHIVED]`).

---

## 4. Strate 1 — Extensions Exploratoires Subordonnées (`V3 = 0`)

- **Modules Lean 4 géométriques (`extensions/lexicon/lean/`, 3 modules actifs, 10/10 théorèmes, `0 sorryAx`) :**
  1. [`PolarityAntipodal3D.lean`](extensions/lexicon/lean/PolarityAntipodal3D.lean) (**4 / 4**) : équipartition `84/84` et invariance antipodale 3D sur les 168 prototypes périphériques.
  2. [`AuditGeometricLexicalPlacement.lean`](extensions/lexicon/lean/AuditGeometricLexicalPlacement.lean) (**4 / 4**) : conformité $L_1$, parité paire et non-centralité du Corpus 2.
  3. [`EmotionWheelsChallenge.lean`](extensions/lexicon/lean/EmotionWheelsChallenge.lean) (**2 / 2**) : involutivité par morceaux de la Rose des symétries et pureté combinatoire du Diamant 303 (toute constante statistique Python figée et l'ancien `SchererGRID.lean` ont été retirés et archivés dans [`archive/deprecated_synthetic_v2/`](archive/deprecated_synthetic_v2/)).
- **Tables lexicales TSV historiques v2.1.0 :** Balisées dans [`extensions/lexicon/ARCHIVE_V2_HYBRID_Y_WARNING.md`](extensions/lexicon/ARCHIVE_V2_HYBRID_Y_WARNING.md) (ancien axe `Y` hybride, hors cœur normatif v3.0.0) ; provenance des corpus tiers non redistribuables documentée dans [`DATA_PROVENANCE.md`](DATA_PROVENANCE.md).
- **Simulations *in silico* (`extensions/in_silico/`) :** Environnement épinglé FAIR4RS (`pyproject.toml` `==` + `uv.lock`) ; Expériences 1–3 établissant uniquement la cohérence numérique/générative interne (`V3 = 0`) ; Expériences 4–5 DSM-5 / HiTOP isolées en quarantaine dans [`extensions/in_silico/exploratory_synthetic/`](extensions/in_silico/exploratory_synthetic/) (`SYNTHETIC EXPLORATORY ONLY — V3 = 0`).

---

## 5. Matrice des Commandes de Vérification v3.0.0

| Banc de validation | Commande d'exécution | Périmètre vérifié | Statut |
| :--- | :--- | :--- | :---: |
| **Compilation Lean 4 stricte** | `lake build` | Cœur normatif `Cartograffect` (8 modules + `AuditTests` + annexe `Lexicon176`) et cible `PredictiveEngineCanonical` (`warningAsError := true`) | ✅ PASS |
| **Audit axiomatique & `#eval`** | `lake env lean Cartograffect/AuditTests.lean` | `#print axioms` exhaustif sur les 169 déclarations du cœur normatif (`0 sorryAx`, `0 native_decide`) | ✅ PASS |
| **Audit extension canonique** | `lake env lean extensions/predictive_engine/PredictiveEngineCanonical.lean` | `#print axioms` exhaustif sur les 21 déclarations (`C1..C16` + `CE1..CE5`, `0 sorryAx`) | ✅ PASS |
| **Moteur prédictif Python exact** | `python -m unittest discover -s python -v` | 11 tests unitaires de parité exacte v3.0.0 (Options 1A, 2a, 3b, fondation `Z = 2`, `z_max = 5`) | ✅ PASS |
| **Synchronisation métadonnées** | `python scripts/sync_metadata.py --check` | Parité `VERSION = 3.0.0`, compteurs `8 / 148 / 169` et SHA-256 `Lexicon176.lean` entre `VERSION`, `CITATION.cff`, `.zenodo.json`, `manifest.json` et `pyproject.toml` | ✅ PASS |
| **Contrat d'export web déterministe** | `python scripts/export_site_payload.py --check` | Validation croisée déterministe du payload JSON v3.0.0 (`schema=2.0`, `version=3.0.0`, `AGPL-3.0-or-later` / `CC-BY-4.0`) | ✅ PASS |
| **Garde-fou de cohérence globale** | `python scripts/check_consistency.py --strict` | 7 catégories : SemVer `3.0.0`, intégrité Lean 4, séparation physique OSI / CC-BY-4.0 (0 NC dans le code), FAIR4RS (`==`, `uv.lock`, `DATA_PROVENANCE.md`), cloisonnement épistémique, Zéro-Fuite et contrat web | ✅ PASS |
| **Tests adversariaux des gardes** | `python -m unittest scripts/test_check_consistency.py -v` | Non-régression complète des gardes, injection de fautes (`sorry`/`native_decide`, clause NC, fuite locale, A4-Sanctuaire) et comportement `[SKIP]` sur corpus tiers absents | ✅ PASS |
