# CARTOGRAFFECT — Noyau Formel Lean 4, Théorie Affective & Bancs de Cohérence (v3.0.0)

[![Lean 4 CI](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/lean.yml/badge.svg)](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/lean.yml)
[![Compendium Guardrails CI](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/compendium-ci.yml/badge.svg)](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/compendium-ci.yml)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23833938.svg)](https://doi.org/10.5281/zenodo.23833938)
![Lean 4.35.0](https://img.shields.io/badge/Lean-v4.35.0-blue?logo=lean)
![Audit v3.0.0](https://img.shields.io/badge/Core_v3.0.0-8_Modules_%7C_148_Theorems_(169_Exported)_%7C_0_sorryAx-success)
[![Code License: AGPL-3.0-or-later](https://img.shields.io/badge/Code_License-AGPL--3.0--or--later-blue.svg)](LICENSE)
[![Docs & Tables License: CC-BY-4.0](https://img.shields.io/badge/Docs_%26_Tables-CC--BY--4.0-lightgrey.svg)](LICENSE-CC-BY-4.0.md)

Ce dépôt héberge le compendium de recherche **CARTOGRAFFECT (`v3.0.0`)** (*Cartographie des affects*), articulant un manuscrit théorique ([`docs/01-Article_Cartograffect.md`](docs/01-Article_Cartograffect.md)), un **noyau formel de référence unique en Lean 4 (`v4.35.0`, Lake `5.0.0`, sans dépendance Mathlib — `Init` uniquement, `warningAsError := true`)** et un moteur numérique isomorphe en arithmétique entière exacte ([`python/cartograffect_predictive_engine.py`](python/cartograffect_predictive_engine.py), **11 tests unitaires**).

Conformément aux quatre arbitrages irréversibles verrouillés dans [`DECISIONS_V3.md`](DECISIONS_V3.md), le **cœur normatif v3.0.0 (`Cartograffect/`)** réunit **8 modules normatifs** certifiant **148 théorèmes substantiels** (**169 déclarations `theorem` exportées**, **21 lemmes élémentaires / auxiliaires isolés à part**, **8 théorèmes piliers** de lecture prioritaire, **0 `sorryAx`**, **0 `native_decide`**, **0 axiome *ad hoc***), complétés par l'extension canonique [`extensions/predictive_engine/PredictiveEngineCanonical.lean`](extensions/predictive_engine/PredictiveEngineCanonical.lean) (**16 théorèmes propres `C1..C16`** + **5 lemmes auxiliaires `CE1..CE5`** = **21 déclarations exportées**).

> **English Overview:** This repository hosts the **CARTOGRAFFECT (`v3.0.0`)** Research Compendium. Centered on **Lean 4 (`v4.35.0`, Lake `5.0.0`, zero external dependencies — `Init` only, `warningAsError := true`)** as the single reference formal prover, the normative core (`Cartograffect/`) spans **8 normative modules** certifying **148 substantial theorems** (**169 exported declarations**, **21 auxiliary lemmas**, **8 pillar theorems**, **0 `sorryAx`**, **0 `native_decide`**, **0 custom axioms**), paired with the dedicated canonical extension `extensions/predictive_engine/PredictiveEngineCanonical.lean` (**16 own theorems `C1..C16` + 5 auxiliaries `CE1..CE5` = 21 declarations**) and an exact-integer isomorphic Python predictive engine (`python/cartograffect_predictive_engine.py`, **11 unit tests**). Exploratory annexes (`Cartograffect/Lexicon176.lean`, `docs/02-Inventaire_176.md`, Strate 1 `extensions/lexicon/` and `extensions/in_silico/`, and the frozen v2.1.0 multi-prover archive) are kept strictly separated outside the normative core.

---

## Audit Formel Prioritaire — [`FORMAL_AUDIT_PACK.md`](FORMAL_AUDIT_PACK.md)

Pour un vérificateur mathématique indépendant, [`FORMAL_AUDIT_PACK.md`](FORMAL_AUDIT_PACK.md) fournit l'inventaire exhaustif, dédupliqué et vérifiable ligne par ligne des **148 théorèmes substantiels** (+ **21 lemmes élémentaires** isolés), des **16 + 5 = 21 déclarations** de `PredictiveEngineCanonical.lean`, ainsi que la sortie brute intégrale de `#print axioms` distinguant explicitement les preuves sans axiome, propositionnelles (`[propext, Quot.sound]`) et classiques (`[propext, Classical.choice, Quot.sound]`).

> [!IMPORTANT]
> ### Top 8 théorèmes piliers v3.0.0 (lecture prioritaire en 30 min — voir [`FORMAL_AUDIT_PACK.md`](FORMAL_AUDIT_PACK.md))
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
> | **P8** | **Articulation mixte `Z = 2` & Clôture v3.0** — `R-` actif vs sécurité pavlovienne et pont global | `active_r_minus_vs_pavlovian_safety_and_z2_bound` & `full_end_to_end_v3_coherence` | `Cartograffect/OperantFactorization.lean:165` & `Cartograffect/EndToEndBridge.lean:276` | `[propext, Classical.choice, Quot.sound]` |

---

## Déclaration transparente d'usage de l'intelligence artificielle générative

Alignée sur la section correspondante de [`docs/01-Article_Cartograffect.md`](docs/01-Article_Cartograffect.md) :

- **Paternité intégrale de l'auteur sur le modèle psychologique, conceptuel et taxonomique :** L'auteur (**Manuel Cabelguen, Ph. D.**, psychologue clinicien et chercheur indépendant) conçoit et assume intégralement l'architecture conceptuelle, la psychologie affective, les arbitrages taxonomiques et l'orientation théorique de **CARTOGRAFFECT** : la conception du cadre théorique, la formulation des hypothèses cliniques, la lecture critique des travaux cités et l'ensemble des décisions scientifiques relèvent entièrement de sa paternité et de sa responsabilité.
- **Rôle d'assistance technique de l'IA générative :** Des outils d'intelligence artificielle générative ont été utilisés à titre d'**assistants techniques** pour l'aide à la rédaction, la réalisation du site web vitrine, la traduction et la formalisation sous l'assistant de preuve de référence Lean 4 (ainsi que pour les annexes exploratoires archivées sur le dépôt GitHub).
- **Portée et limites de vérification (transparence méthodologique) :** Psychologue clinicien et **non mathématicien formel**, l'auteur **n'a pas vérifié manuellement ligne par ligne** le code mathématique et formel ainsi généré. La validité technique de ce matériel repose à ce stade sur la **compilation et vérification mécanique** effectuées par les prouveurs et solveurs respectifs ainsi que sur les **tests automatisés**. L'ensemble de ce matériel formel et *in silico* est publié en accès libre sur GitHub précisément afin d'**inviter l'audit indépendant de mathématiciens et de spécialistes des méthodes formelles**.

> **AI Transparency & Epistemic Notice (EN):** The conceptual architecture, affective psychology, taxonomic decisions, and theoretical orientation of CARTOGRAFFECT are conceived and owned entirely by Manuel Cabelguen, Ph. D. Generative AI tools served as technical assistants for writing, website engineering, translation, and formalization in the reference Lean 4 proof assistant (and archived exploratory annexes). As a clinical psychologist and not a formal mathematician, the author has not manually verified the generated mathematical/formal code line by line; technical validity rests on mechanical compilation/verification by the proof assistant and automated tests, and all artifacts are open-sourced on GitHub precisely to invite independent audit by mathematicians and formal-methods specialists.

---

## Architecture v3.0.0 : Cœur Normatif vs Annexes Exploratoires

### 1. Strate 0 — Cœur Normatif v3.0.0 (`Cartograffect/`, `python/`, `docs/01-Article_Cartograffect.md`)

| Composante | Fichier / Module | Déclarations exportées | Théorèmes substantiels | Rôle normatif v3.0.0 |
| :--- | :--- | :---: | :---: | :--- |
| **Module 1** | [`Cartograffect/PredictiveEngine.lean`](Cartograffect/PredictiveEngine.lean) | 14 | **6** *(+8 aux.)* | Polarités involutives, 9 couplages `(A, C)`, hystérésis et boucle inférentielle |
| **Module 2** | [`Cartograffect/CoreAffect.lean`](Cartograffect/CoreAffect.lean) | 37 | **32** *(+5 aux.)* | Géométrie $L_1$ ($R(Z) = 2Z - 2$), partage `apportionRay`, découplage `A ≥ 0` (Option 1A), dissipation pas-à-pas `2 → 0` (Option 2a) |
| **Module 3** | [`Cartograffect/AffectiveMatrix.lean`](Cartograffect/AffectiveMatrix.lean) | 22 | **19** *(+3 aux.)* | Priorité hédonique `X` (P4), antagonisme involutif par morceaux, orthogonalité `A ≥ 0`, `PhenomenologicalMapping` (activation découplée de `Y`) |
| **Module 4** | [`Cartograffect/AffectiveTaxonomy.lean`](Cartograffect/AffectiveTaxonomy.lean) | 16 | **16** *(+0 aux.)* | Discrétisation canonique `Z ∈ {0, 1, 2}` (11 états), 9 groupes / 17 sous-secteurs neutres, `end_to_end_coherence` |
| **Module 5** | [`Cartograffect/AffectiveDynamics.lean`](Cartograffect/AffectiveDynamics.lean) | 13 | **13** *(+0 aux.)* | Noyau inter-strates `canonicalDepthKernel`, brisure de symétrie P2 sur Charge négative (`Peur`/`Tristesse`, Option 3b), attracteurs gradués |
| **Module 6** | [`Cartograffect/PredictiveCircuit.lean`](Cartograffect/PredictiveCircuit.lean) | 53 | **48** *(+5 aux.)* | Circuit fermé à 6 opérateurs, bijection $\Phi_{L_1}$, noyau entier `4 * scale^6`, dérive signée de Lyapunov sur `ℤ`, 5 ruptures d'ergodicité, loi unifiée |
| **Module 7** | [`Cartograffect/OperantFactorization.lean`](Cartograffect/OperantFactorization.lean) | 8 | **8** *(+0 aux.)* | Régimes mixtes `Z = 2` (`R-` actif sous `Y > 0` vs sécurité pavlovienne `Calme` sous `Y < 0`, borne stricte `Z = 2`) |
| **Module 8** | [`Cartograffect/EndToEndBridge.lean`](Cartograffect/EndToEndBridge.lean) | 6 | **6** *(+0 aux.)* | Pont global v3.0.0 (`full_end_to_end_v3_coherence`), conformité `isValidVerticalStep2a` et cohérence terminale neutre |
| **Total cœur normatif** | **8 modules normatifs Lean 4** | **169** | **148** *(+21 aux.)* | **`0 sorryAx`, `0 native_decide`, `0` axiome *ad hoc* — audité dans [`Cartograffect/AuditTests.lean`](Cartograffect/AuditTests.lean)** |
| **Extension canonique** | [`extensions/predictive_engine/PredictiveEngineCanonical.lean`](extensions/predictive_engine/PredictiveEngineCanonical.lean) | **21** | **16** *(+5 aux.)* | Assemblage typé des boucles, pas-à-pas strict 2a (`C1..C16` + `CE1..CE5`), `0` import de `Lexicon176` |
| **Moteur Python exact** | [`python/cartograffect_predictive_engine.py`](python/cartograffect_predictive_engine.py) & [`python/test_predictive_engine.py`](python/test_predictive_engine.py) | — | **11 tests** | Jumeau numérique exact en Python (Options 1A, 2a, 3b, fondation `Z = 2`, `z_max = 5` par défaut) |
| **Manuscrit & Figures** | [`docs/01-Article_Cartograffect.md`](docs/01-Article_Cartograffect.md), [`docs/assets/moteur_predictif_canonique.html`](docs/assets/moteur_predictif_canonique.html), [`docs/assets/moteur_predictif_article.svg`](docs/assets/moteur_predictif_article.svg) | — | **5 prédictions (P1–P5)** | Profondeur continue `Z ∈ [0, 5]`, discrétisation canonique `Z ∈ {0, 1, 2}` |

> **Transparence axiomatique (`#print axioms`) :** `84` des `169` déclarations exportées du cœur normatif mobilisent l'axiome classique standard `Classical.choice` du noyau Lean 4 (notamment via le solveur linéaire `omega`). En conséquence, **aucun théorème dépendant de `Classical.choice` n'est qualifié de « constructif »** ; la ventilation exacte (`[none]`, `[propext]`, `[propext, Quot.sound]`, `[propext, Classical.choice, Quot.sound]`) est publiée dans [`FORMAL_AUDIT_PACK.md`](FORMAL_AUDIT_PACK.md).

### 2. Annexes Exploratoires & Satellites Strate 1 (Hors Cœur Normatif v3.0.0)

- **Annexe combinatoire 176 entrées (`Z = 0..7`) :** [`Cartograffect/Lexicon176.lean`](Cartograffect/Lexicon176.lean) et [`docs/02-Inventaire_176.md`](docs/02-Inventaire_176.md) sont classés **séparément comme annexe exploratoire hors cœur normatif** (aucun des 8 modules normatifs ni `PredictiveEngineCanonical.lean` n'importe `Lexicon176`).
- **Satellite lexical Strate 1 ([`extensions/lexicon/`](extensions/lexicon/)) :**
  - 3 modules Lean 4 géométriques actifs (**10/10 théorèmes géométriques, `0 sorryAx`, `0` constante statistique Python codée en dur** : `PolarityAntipodal3D.lean`, `AuditGeometricLexicalPlacement.lean`, `EmotionWheelsChallenge.lean`) ; l'ancien module `SchererGRID.lean` et les scripts synthétiques GRID-24 / CPM-142 (`grid_cpm_integration.py`, etc.) ont été retirés et archivés dans [`archive/deprecated_synthetic_v2/`](archive/deprecated_synthetic_v2/).
  - Les tables lexicales TSV historiques (`CARTOGRAFFECT_Full_Dictionary_MultiStrata.tsv`, `nrc_llm_classified.tsv`, `nrc_candidates_filtered.tsv`) sont explicitement balisées comme archives v2.1.0 sous ancien axe `Y` hybride dans [`extensions/lexicon/ARCHIVE_V2_HYBRID_Y_WARNING.md`](extensions/lexicon/ARCHIVE_V2_HYBRID_Y_WARNING.md).
  - La provenance, les licences et les instructions SHA-256 des corpus tiers non redistribuables (`NRC-VAD-Lexicon-v2.1.txt`, `DIMA_GROUPE_*.xlsx`, `FANCatdatabaseRevisee.xlsx`) sont documentées dans [`DATA_PROVENANCE.md`](DATA_PROVENANCE.md).
- **Satellite *in silico* Strate 1 ([`extensions/in_silico/`](extensions/in_silico/)) :**
  - Dépendances exactement épinglées (`==`) dans [`extensions/in_silico/pyproject.toml`](extensions/in_silico/pyproject.toml) et [`extensions/in_silico/requirements.txt`](extensions/in_silico/requirements.txt) avec lockfile reproductible [`extensions/in_silico/uv.lock`](extensions/in_silico/uv.lock) (standard FAIR4RS).
  - Expériences 1 à 3 : tests de cohérence numérique/générative interne *in silico* (`V3 = 0`) ; Expériences 4–5 DSM-5 / HiTOP isolées en quarantaine dans [`extensions/in_silico/exploratory_synthetic/`](extensions/in_silico/exploratory_synthetic/) (`SYNTHETIC EXPLORATORY ONLY — V3 = 0`).
- **Archive figée multi-prouveurs v2.1.0 (Principe d'économie) :** Les répertoires [`rocq/`](rocq/), [`agda/`](agda/), [`dafny/`](dafny/), [`smt/`](smt/) et [`tla/`](tla/) (TLA+/TLC requalifié en *bounded model checking* fini sur domaines bornés) conservent l'instantané figé du tag `v2.1.0`. Leurs workflows CI ont été basculés en déclenchement manuel uniquement (`workflow_dispatch`, préfixe `[LEGACY v2.1 — ARCHIVED]`).

---

## Reproduction Locale & Contrôles Automatisés

```powershell
# 1. Compilation stricte Lean 4 (warningAsError := true, 0 dépendance externe)
lake build

# 2. Audit axiomatique exhaustif (#print axioms) et évaluations (#eval)
lake env lean Cartograffect/AuditTests.lean
lake env lean extensions/predictive_engine/PredictiveEngineCanonical.lean

# 3. Suite unitaire du moteur prédictif Python exact (11 tests)
python -m unittest discover -s python -v

# 4. Gardes d'intégrité, métadonnées et contrat web déterministe
python scripts/sync_metadata.py --check
python scripts/export_site_payload.py --check
python scripts/check_consistency.py --strict
python -m unittest scripts/test_check_consistency.py -v
```

---

## Documentation Associée

- **[`FORMAL_AUDIT_PACK.md`](FORMAL_AUDIT_PACK.md)** : Dossier d'audit exhaustif v3.0.0 (Top 8 piliers, 148 théorèmes substantiels / 169 exportés, 16 + 5 `PredictiveEngineCanonical`, sorties `#print axioms` brutes).
- **[`DECISIONS_V3.md`](DECISIONS_V3.md)** : Verrouillage des 4 arbitrages architecturaux irréversibles de la refonte v3.0.0 (Options 1A, 2a, 3b et périmètre `Z ∈ [0, 5]`).
- **[`VALIDATION.md`](VALIDATION.md)** : Synthèse globale de vérification formelle, logicielle et computationnelle v3.0.0.
- **[`DATA_PROVENANCE.md`](DATA_PROVENANCE.md)** : Provenance FAIR4RS, licences d'origine et vérification SHA-256 des corpus tiers non redistribuables.
- **[`docs/01-Article_Cartograffect.md`](docs/01-Article_Cartograffect.md)** : Manuscrit théorique de référence v3.0.0.
- **[`docs/02-Inventaire_176.md`](docs/02-Inventaire_176.md)** : Annexe exploratoire combinatoire à 176 entrées (`Z = 0..7`, hors cœur normatif).
- **[`docs/CONVERGENCE_MATRIX.md`](docs/CONVERGENCE_MATRIX.md)** : Matrice de gouvernance épistémique Strate 0 / Strate 1.
- **[`extensions/lexicon/EPISTEMIC_STATUS.md`](extensions/lexicon/EPISTEMIC_STATUS.md)** & **[`extensions/lexicon/ARCHIVE_V2_HYBRID_Y_WARNING.md`](extensions/lexicon/ARCHIVE_V2_HYBRID_Y_WARNING.md)** : Charte Strate 1 lexicale et avertissement d'archive sur les tables TSV v2.1.0.
- **[`extensions/in_silico/EPISTEMIC_STATUS.md`](extensions/in_silico/EPISTEMIC_STATUS.md)** : Charte Strate 1 des simulations Active Inference (`V3 = 0`).
- **[`extensions/predictive_engine/EPISTEMIC_STATUS.md`](extensions/predictive_engine/EPISTEMIC_STATUS.md)** : Charte de l'extension formelle `PredictiveEngineCanonical.lean`.
- **[`CHANGELOG.md`](CHANGELOG.md)** & **[`manifest.json`](manifest.json)** : Historique SemVer (`3.0.0`) et carte de traçabilité machine-lisible.

---

## Licences & Propriété Intellectuelle (Séparation Physique OSI / CC-BY-4.0)

Copyright (C) 2025-2026 Manuel Cabelguen — Enregistrement de droit d'auteur auprès de l'Office de la propriété intellectuelle du Canada (**CIPO / OPIC, n° 1233199** ; il s'agit d'un enregistrement de droit d'auteur, sans marque déposée distincte).

À compter de la version **3.0.0**, le dépôt applique une **séparation physique stricte par type de fichier**, sans aucune clause non commerciale (`NC`) dans le code source ni dans les artefacts v3.0.0 :

- **Code source, scripts et preuves formelles (`Cartograffect/`, `Cartograffect.lean`, `python/`, `scripts/`, `extensions/` code & `.lean`) :** distribués **exclusivement** sous licence libre approuvée OSI **GNU Affero General Public License v3.0 or later (`AGPL-3.0-or-later`)** — voir [`LICENSE`](LICENSE).
- **Textes, manuscrit (`docs/`), documentation et tables taxonomiques :** distribués sous **Creative Commons Attribution 4.0 International (`CC-BY-4.0`)** (standard Nature / TOP / FAIR4RS) — voir [`LICENSE-CC-BY-4.0.md`](LICENSE-CC-BY-4.0.md) et [`NOTICE`](NOTICE).

---

## Auteur, Correspondance & Citation

Manuel Cabelguen, Ph. D. (`manuelcabelguen@gmail.com`)  
Identifiants persistants : Zenodo Code [`10.5281/zenodo.23833938`](https://doi.org/10.5281/zenodo.23833938) · Zenodo Article [`10.5281/zenodo.24022795`](https://doi.org/10.5281/zenodo.24022795) · OSF [`https://osf.io/z89sg`](https://osf.io/z89sg)

Source unique de citation : [`CITATION.cff`](CITATION.cff).

```bibtex
@article{cabelguen2026cartographie,
  author  = {Cabelguen, Manuel},
  title   = {Cartographie des affects : une architecture hi{\'e}rarchique de l'exp{\'e}rience affective fond{\'e}e sur le traitement pr{\'e}dictif},
  year    = {2026},
  version = {3.0.0},
  doi     = {10.5281/zenodo.24022795},
  url     = {https://doi.org/10.5281/zenodo.24022795},
  note    = {Manuscrit th{\'e}orique de r{\'e}f{\'e}rence v3.0.0 (docs/01-Article_Cartograffect.md, CC-BY-4.0), enregistrement droit d'auteur CIPO / OPIC n° 1233199}
}

@software{cabelguen2026cartograffect,
  author    = {Cabelguen, Manuel},
  title     = {{CARTOGRAFFECT}: Research Compendium --- Lean 4 Formal Core, Theory \& Active Inference Benchmarks},
  year      = {2026},
  publisher = {Zenodo},
  version   = {3.0.0},
  doi       = {10.5281/zenodo.23833938},
  url       = {https://doi.org/10.5281/zenodo.23833938},
  note      = {Version v3.0.0 (2026-11-26); Code: AGPL-3.0-or-later, Docs/Tables: CC-BY-4.0; OSF: https://osf.io/z89sg}
}
```
