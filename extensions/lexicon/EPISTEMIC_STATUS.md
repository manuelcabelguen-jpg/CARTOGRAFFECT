# Statut Épistémique — `extensions/lexicon/` (Strate 1 : Extensions Lexicales Exploratoires)

Ce sous-projet appartient à la **Strate 1 (Extensions lexicales et explorations géométriques)** du compendium **CARTOGRAFFECT (`v3.0.0`)**. Conformément à la hiérarchie épistémique stricte du projet ([`../../DECISIONS_V3.md`](../../DECISIONS_V3.md)), il est **asservi à la Strate 0 (Cœur normatif Lean 4 : 8 modules normatifs, 148 théorèmes substantiels / 169 déclarations exportées, 0 `sorryAx`, 0 `native_decide`)** et n'introduit aucune validation empirique externe (`V3 = 0`).

> [!WARNING]
> **Archive historique sous ancien axe Y hybride v2.1.0 :** Voir [`ARCHIVE_V2_HYBRID_Y_WARNING.md`](ARCHIVE_V2_HYBRID_Y_WARNING.md). Les tables TSV historiques (`CARTOGRAFFECT_Full_Dictionary_MultiStrata.tsv`, `nrc_llm_classified.tsv`, `nrc_candidates_filtered.tsv`, etc.) ont été générées sous l'ancien axe `Y` hybride v2.1.0 avant le découplage Option 1A (`Y` contrôlabilité instrumentale stricte / canal autonome `A ≥ 0`). Elles sont conservées sans altération à titre d'archive exploratoire hors cœur normatif v3.0.0.

---

## 1. Ce qui provient de l'annexe exploratoire `Cartograffect/Lexicon176.lean`

Les invariants combinatoires suivants sont importés depuis l'annexe exploratoire [`Cartograffect/Lexicon176.lean`](../../Cartograffect/Lexicon176.lean) (`Z ∈ {0, ..., 7}`, hors cœur normatif v3.0.0 dont la discrétisation canonique est bornée à `Z ∈ {0, 1, 2}`) :

1. **Géométrie discrète $L_1$ des 176 entrées ($Z \in \{0, \dots, 7\}$) :**
   - Loi des couronnes $R(Z) = |X| + |Y| = 2(Z - 1)$ pour tout état périphérique ($Z \ge 2$).
   - Parité paire $(X + Y) \equiv 0 \pmod 2$ et cardinaux par strate $N(Z) = 8(Z - 1) + 1$ ($1 + 1 + 9 + 17 + 25 + 33 + 41 + 49 = 176$).
2. **Nomenclature canonique du pôle d'origine $(0, 0, 0)$ :**
   - Le sommet basal à $Z = 0$ porte le libellé canonique **`"Point de Veille"`** dans [`Cartograffect/Lexicon176.lean`](../../Cartograffect/Lexicon176.lean).
   - Le script [`01_build_ref176.py`](01_build_ref176.py) lit directement `../../Cartograffect/Lexicon176.lean`, avec alias de lecture `"Veille"` $\leftrightarrow$ `"Point de Veille"` pour la compatibilité avec les tables `.tsv` historiques.
3. **Antagonisme involutif par morceaux $\mathcal{A}(X, Y, Z)$ :**
   - `(-X, -Y, Z)` si `XY = 0`, et `(-sgn(X)|Y|, -sgn(Y)|X|, Z)` si `XY ≠ 0`.
   - Les 4 lemmes géométriques supplémentaires sur `polarity3D` et `zAntipodal3D` sont isolés dans [`lean/PolarityAntipodal3D.lean`](lean/PolarityAntipodal3D.lean) (Strate 1, hors cœur normatif v3.0.0).

---

## 2. Ce qui relève de la Strate 1 (Projections Heuristiques et Audits Exploratoires — `V3 = 0`)

### 2.1 Épreuve exploratoire par les Roues des Émotions (Scherer et al., 2013) et retrait de GRID-24 / CPM-142
- **Fichiers actifs :** [`lean/EmotionWheelsChallenge.lean`](lean/EmotionWheelsChallenge.lean), [`lean/AuditGeometricLexicalPlacement.lean`](lean/AuditGeometricLexicalPlacement.lean), [`lean/PolarityAntipodal3D.lean`](lean/PolarityAntipodal3D.lean), [`src/validate_emotion_wheels.py`](src/validate_emotion_wheels.py).
- **Retrait Phase 1 — Purge GRID-24 / CPM-142 :**
  - Les anciens artefacts synthétiques GRID-24 / CPM-142 (`grid_cpm_integration.py`, vecteurs calibrés sur $Z$ avec réinjection sectorielle `0.45 * u_sector / v_sector`, ainsi que l'ancien module `SchererGRID.lean` embarquant des scores statistiques Python figés par `decide`) ont été **retirés du périmètre actif** et archivés dans [`archive/deprecated_synthetic_v2/`](../../archive/deprecated_synthetic_v2/). Aucune validation empirique ou psychométrique externe (`V3`) n'est revendiquée à partir de ces données synthétiques.
- **Statut épistémique actif :**
  - Les 3 modules Lean 4 actifs de `extensions/lexicon/lean/` (**10 théorèmes géométriques/combinatoires, `0 sorryAx`, `0` constante statistique Python codée en dur**) certifient exclusivement des invariants géométriques internes.
  - Le script [`src/validate_emotion_wheels.py`](src/validate_emotion_wheels.py) confronte le lexique aux coordonnées publiées des roues de Scherer et al. (2013) sans surcharges manuelles cachées, en rapportant **H2** et **H4** strictement comme **non corroborées** sans recadrage post-hoc.
  - L'homéomorphisme radial $L_1 \leftrightarrow L_2$ est un **outil continu de visualisation**, distinct de la métrique discrète $L_1$ du cœur normatif.

### 2.2 Pipeline de projection lexicale historique v2 (NRC-VAD v2.1, DIMA, FANCat, GLAWI/Lexique 3.83)
- **Fichiers :** [`02_prefilter_nrc.py`](02_prefilter_nrc.py), [`03_classify_batches_gemini.py`](03_classify_batches_gemini.py), [`03b_affect_audit_gemini.py`](03b_affect_audit_gemini.py), [`04_direct_l1_projection.py`](04_direct_l1_projection.py), [`dima_mapping.py`](dima_mapping.py), [`10_project_55k_nrc_vad_diamond_303.py`](10_project_55k_nrc_vad_diamond_303.py).
- **Statut épistémique :**
  - Les coordonnées $(V, A, D) \in [-1, +1]^3$ des lexiques tiers ont été projetées dans la version v2.1.0 au moyen d'une **combinaison linéaire heuristique hybride** (`y_raw = 0.60*D + 0.40*A` ou `0.60*A + 0.40*D`, obsolète vis-à-vis de l'Option 1A v3.0.0) et d'une estimation continue $z_{\text{ded}} = \text{clip}(1.2 + 3.2\,r_{L_1}, 1.5, 7.0)$, suivie d'une classification assistée par LLM (**famille Gemini Flash**, configurée via `GEMINI_MODEL_ID`, valeur par défaut `gemini-2.5-flash` ; l'ancien identifiant de modèle invalide de l'archive v2 a été corrigé en v3.0.0).
  - Ces projections constituent un **atlas psycholinguistique exploratoire archivé (`V3 = 0`)** et non une déduction formelle du cœur normatif v3.0.0.
  - **Politique des données tierces (FAIR4RS) :** Les fichiers bruts tiers non redistribuables (`NRC-VAD-Lexicon-v2.1.txt`, `DIMA_GROUPE_*.xlsx`, `FANCatdatabaseRevisee.xlsx`) ainsi que `CARTOGRAFFECT_55K_NRC_VAD_Diamant_303.tsv` sont **exclus du suivi Git** (`.gitignore`) et documentés dans [`../../DATA_PROVENANCE.md`](../../DATA_PROVENANCE.md). En leur absence locale, les scripts (`02_prefilter_nrc.py`, `dima_mapping.py`, `run_pipeline.py`) effectuent un **`[SKIP]` explicite** propre.

### 2.3 Extension Axiologique $Z \in [-7, -1]$ (« Diamant 303 »)
- **Fichiers :** [`01b_prepare_diamond_z_minus.py`](01b_prepare_diamond_z_minus.py), [`02b_audit_and_consolidate_databases.py`](02b_audit_and_consolidate_databases.py), [`08_project_diamond_303_lexicon.py`](08_project_diamond_303_lexicon.py), [`ref_303_diamant_z.tsv`](ref_303_diamant_z.tsv).
- **Statut épistémique :**
  - L'hémisphère supérieur à profondeur négative $Z \in \{-7, \dots, -1\}$ (127 pôles axiologiques complétant les 176 entrées $Z \ge 0$ pour former un octaèdre de 303 pôles) constitue un **chantier exploratoire de Strate 1 strictement hors cœur normatif v3.0.0**, conservé intact par principe d'économie (`DECISIONS_V3.md`).

---

## 3. Source de citation et séparation de licences (v3.0.0)

Source de citation unique : [`../../CITATION.cff`](../../CITATION.cff). Séparation physique des licences : code source Python et modules Lean 4 sous **`AGPL-3.0-or-later`** ([`../../LICENSE`](../../LICENSE)), documentation et tables taxonomiques sous **`CC-BY-4.0`** ([`../../LICENSE-CC-BY-4.0.md`](../../LICENSE-CC-BY-4.0.md)), voir [`../../NOTICE`](../../NOTICE).
