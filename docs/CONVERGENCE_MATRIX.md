# Matrice de Convergence et d'Arbitrage Épistémique — CARTOGRAFFECT® (`v2.1.0` → `v3.0.0-dev`)

**Version :** `2.1.0` (branche de refonte `v3.0.0-dev` — Phase 1 : purges d'intégrité probatoire)  
**Hiérarchie épistémique appliquée :**
- **STRATE 0 (Noyau canonique faisant autorité) :** Fondation formelle Hexa-Prover (**130/130 théorèmes constructifs** + `all176Entries_unique_labels` sur 6 assistants de preuve : **Lean 4.35.0** [11 modules `.lean` + `PredictiveEngineCanonical.lean` 21/21, 0 `sorryAx`], **The Rocq Prover 9.1.0** [11 modules `.v`, 131/131 `Closed under the global context`, `Axioms: <none>`, 0 `Admitted`], **Agda 2.9.0** [`--safe --without-K`, 12 modules `.agda`, 130/130 théorèmes + `all176Entries_unique_labels` + 11/11 blocs, 0 `postulate`], **Dafny 4.11.0** [11 modules `.dfy`, 132/132 lemmes, 3 021 verified, 0 errors, parité `--target:py` 11/11], **SMT-LIB 2.6 / Z3 5.3.3** [10 fichiers `.smt2`, 10/10 `sat` CONSISTENCY, 130/130 `unsat` THM, 2/2 `unsat` AUX, 11/11 `unsat` EVAL, 0 `unknown`], **TLA+ / TLC 2.19** [18 modules SANY, 132/132 prédicats, 11/11 EvalBlocks, 8/8 modèles TLC dont `Model_EndToEndBridge.tla` : 598 états, 175 distincts, vivacité `<>(pt.z = 7)`]), moteur markovien entier [`python/cartograffect_predictive_engine.py`](../python/cartograffect_predictive_engine.py) et article théorique consolidé [`docs/01-Article_Cartograffect.md`](01-Article_Cartograffect.md).
- **STRATE 1 (Satellites exploratoires asservis au Noyau) :** [`extensions/lexicon/`](../extensions/lexicon/) (incluant **3 modules Lean 4.35.0** compilés avec `-DwarningAsError=true` et audités par `#print axioms` : **10/10 théorèmes géométriques/combinatoires, 0 `sorryAx`, 0 constante statistique Python codée en dur** — `PolarityAntipodal3D.lean` [4/4], `AuditGeometricLexicalPlacement.lean` [4/4], `EmotionWheelsChallenge.lean` [2/2] ; les anciens artefacts synthétiques GRID-24 / CPM-142 ont été archivés dans `archive/deprecated_synthetic_v2/`) et [`extensions/in_silico/`](../extensions/in_silico/) (`Cartograffect-simulation-in-silico`, avec quarantaine des Expériences 4–5 dans `exploratory_synthetic/` sous bandeau `SYNTHETIC EXPLORATORY ONLY — V3 = 0`).

---

## Partie 1 — Alignements descendants requis (Approximations des satellites à corriger face au Noyau)

Cette première partie recense tous les écarts, approximations paramétriques ou divergences de nomenclature identifiés dans les satellites (**Strate 1**) et sur le site web vis-à-vis de la **Strate 0**, afin que le Noyau exerce son autorité descendante sans contamination inverse.

### 1.1 Écarts entre `extensions/in_silico/` et le Noyau (Strate 0)

| Domaine / Fichier satellite | État dans `extensions/in_silico/` (Strate 1) | Vérité canonique du Noyau (Strate 0) | Action d'alignement descendant |
| :--- | :--- | :--- | :--- |
| **Couverture des 5 prédictions falsifiables (Tableau 2)** | [`experiments/01_falsifiable_predictions.py`](../extensions/in_silico/experiments/01_falsifiable_predictions.py) teste en simulation *in silico* ($N=1\,000$) **P1** (requalifié en **test de cohérence numérique du projecteur budgétaire** `apply_budget_constraint`), **P2** (instabilité axiale en $Z=2$), **P3** (inertie hiérarchique $t_{1/2}(Z)$), **P4** et **P5**. | [`docs/01-Article_Cartograffect.md`](01-Article_Cartograffect.md) (Tableau 2) définit **5 prédictions falsifiables P1 à P5**, incluant **P4** (priorité lexicographique de la valence $\text{sgn}(X_t)$ sur le taux de variation $\Delta X_t$, contre Joffily & Coricelli, 2013) et **P5** (médiation par le contrôle pragmatique $\hat{p}_{\text{ctrl}}$ de la transition depuis la Peur axiale $(-2,0,2)$ vers la Colère $(-1,1,2)$ vs le Dégoût $(-1,-1,2)$), toutes deux certifiées dans [`Cartograffect/AffectiveMatrix.lean`](../Cartograffect/AffectiveMatrix.lean) et [`Cartograffect/AffectiveDynamics.lean`](../Cartograffect/AffectiveDynamics.lean). | **Aligné & requalifié en Phase 1 (`v3.0.0-dev`) :** P1 est explicitement qualifié de **test de cohérence numérique du projecteur budgétaire** ; P1–P5 attestent exclusivement une cohérence computationnelle interne *in silico* (`V3 = 0`) dans [`extensions/in_silico/EPISTEMIC_STATUS.md`](../extensions/in_silico/EPISTEMIC_STATUS.md). |
| **Paramétrisation et dynamique du circuit fermé** | Le simulateur POMDP [`src/cartograffect_sim/`](../extensions/in_silico/src/cartograffect_sim/) utilise un vecteur continu $\theta = (\tau_A, \tau_C, \lambda, \alpha_0, \gamma_\alpha, \eta_{\text{diss}}, \beta_X, \beta_Y, \delta_c)$ en virgule flottante, avec mise à jour de Dirichlet $\alpha(Z) = \alpha_0 \exp(\gamma_\alpha Z)$ sur la matrice de vraisemblance $A$ et tenseur de transition $B$ à 11 actions. | [`Cartograffect/PredictiveCircuit.lean`](../Cartograffect/PredictiveCircuit.lean) et [`python/cartograffect_predictive_engine.py`](../python/cartograffect_predictive_engine.py) définissent un système dynamique discret en **arithmétique entière exacte ($\mathbb{Z}$, `scale = 1 000`)** paramétré par $(\rho, \kappa, \delta_A, \delta_C, \gamma_A, \gamma_C, \chi, \epsilon)$ sur le quadruplet d'état $(R_t, Z_t, \tilde{\pi}_{A,t}, \tilde{\pi}_{C,t})$, avec l'identité de conservation $4 \cdot \text{scale}^6$ et l'opérateur idempotent `apportionRay`. | **Documenté dans [`extensions/in_silico/EPISTEMIC_STATUS.md`](../extensions/in_silico/EPISTEMIC_STATUS.md) :** Le POMDP `pymdp` est explicitement qualifié d'opérationnalisation statistique continue destinée à l'inversion bayésienne (SVI/NUTS), subordonnée au noyau markovien entier exact. |
| **Source du lexique des 176 états** | [`data/lexicon_176.json`](../extensions/in_silico/data/lexicon_176.json) est un export JSON statique autonome (déjà conforme à `"Point de Veille"` en $(0,0,0)$ et à `Désenchantement`/`Enchantement` en $(\mp 2, \pm 6, 5)$). | [`Cartograffect/Lexicon176.lean`](../Cartograffect/Lexicon176.lean) est l'unique source de vérité formelle des 176 prototypes. | **Vérifié :** `data/lexicon_176.json` est 100 % isomorphe aux 176 entrées de `Cartograffect/Lexicon176.lean`. |
| **Fuites de chemins locaux absolus (profil utilisateur / Dropbox)** | 19 occurrences de chemins absolus locaux (`<USER_HOME>/...`) étaient présentes dans `results/*.json`, `results/dsm5_*/*.json` et `05_...md`, causées par `str(fig_path)`. | Exigence de reproductibilité zéro-fuite (`0` chemin absolu local dans le dépôt). | **Corrigé :** Tous les scripts, JSON de résultats et documents utilisent exclusivement des chemins relatifs POSIX. |

---

### 1.2 Écarts entre `extensions/lexicon/` et le Noyau (Strate 0)

| Domaine / Fichier satellite | État dans `extensions/lexicon/` (Strate 1) | Vérité canonique du Noyau (Strate 0) | Action d'alignement descendant |
| :--- | :--- | :--- | :--- |
| **Libellé de l'origine $(0, 0, 0)$ à $Z=0$** | Le fichier divergent `nrc_cartograffect_pipeline/Lexicon176.lean` et les tables `.tsv` historiques utilisaient `"Veille"` en $(0,0,0)$ pour que [`scripts/audit_geometric_lexical_placement.py`](../extensions/lexicon/scripts/audit_geometric_lexical_placement.py) puisse rejeter le syntagme multi-mot `"Point de Veille"` du lexique empirique d'unigrammes. | [`Cartograffect/Lexicon176.lean`](../Cartograffect/Lexicon176.lean) et [`docs/01-Article_Cartograffect.md`](01-Article_Cartograffect.md) définissent **`"Point de Veille"`** comme nom ontologique canonique de l'opérateur $(0,0,0)$ (tandis que le lemme français d'unigramme projeté sur ce pôle est `"veille"`). | **Corrigé :** Les 3 fichiers Lean actifs de [`extensions/lexicon/lean/`](../extensions/lexicon/lean/) importent directement le canonique `Cartograffect.Lexicon176` et compilent avec `0 sorry`. [`01_build_ref176.py`](../extensions/lexicon/01_build_ref176.py) lit `../../Cartograffect/Lexicon176.lean`, avec alias de compatibilité `"Veille"` $\leftrightarrow$ `"Point de Veille"` en lecture. |
| **Deux substitutions de libellés dans le Diamant 303 ($Z=4$ et $Z=6$)** | À l'Étape 2, [`01b_prepare_diamond_z_minus.py`](../extensions/lexicon/01b_prepare_diamond_z_minus.py) et les anciens scripts synthétiques GRID/CPM (désormais archivés dans `archive/deprecated_synthetic_v2/`) renommaient deux prototypes de $Z > 0$ : `(0, -6, 4)` **`Langueur` $\to$ `Solitude`** et `(-6, 4, 6)` **`Rancœur` $\to$ `Irritation`**. | [`Cartograffect/Lexicon176.lean`](../Cartograffect/Lexicon176.lean), [`docs/01-Article_Cartograffect.md`](01-Article_Cartograffect.md) et [`docs/02-Inventaire_176.md`](02-Inventaire_176.md) définissent invariablement **`Langueur`** en $(0,-6,4)$ (antagoniste d'*Exaltation* $(0,6,4)$) et **`Rancœur`** en $(-6,4,6)$ (antagoniste d'*Apaisement* $(4,-6,6)$). | **Résolu (Arbitrage A1) & purgé en Phase 1 (`v3.0.0-dev`) :** `Langueur` et `Rancœur` sont les noms canoniques dans `01b_prepare_diamond_z_minus.py` et toutes les tables actives ; les anciens artefacts synthétiques GRID/CPM ont été archivés dans `archive/deprecated_synthetic_v2/`. |
| **Paire controlatérale $(\mp 2, \pm 6, 5)$ entre `v1.0.2.docx` (Annexe A) et `Lexicon176.lean`** | L'Annexe A du manuscrit `v1.0.2.docx` mentionnait `Malveillance (-2, 6, 5) <-> Bienveillance (6, -2, 5)`, tandis que tous les fichiers de code (Strate 0 et Strate 1) utilisent `Désenchantement (-2, 6, 5) <-> Enchantement (6, -2, 5)` (car `Malveillance` et `Bienveillance` occupent déjà $(\mp 3, \pm 5, 5)$). | [`Cartograffect/Lexicon176.lean`](../Cartograffect/Lexicon176.lean) (L152, L161) prouve l'unicité des 176 étiquettes : $(\mp 3, \pm 5, 5) =$ `Malveillance` / `Bienveillance` et $(\mp 2, \pm 6, 5) =$ **`Désenchantement` / `Enchantement`**. | **Corrigé :** Lors de la fusion canonique dans [`docs/01-Article_Cartograffect.md`](01-Article_Cartograffect.md), l'Annexe A a été alignée sur la preuve formelle `Cartograffect/Lexicon176.lean` (`Désenchantement` $\leftrightarrow$ `Enchantement`), éliminant le doublon avec $(\mp 3, \pm 5, 5)$. |
| **Statut de la strate $Z$ négative ($Z \in [-7, -1]$, Diamant 303)** | [`01b_prepare_diamond_z_minus.py`](../extensions/lexicon/01b_prepare_diamond_z_minus.py) et [`08_project_diamond_303_lexicon.py`](../extensions/lexicon/08_project_diamond_303_lexicon.py) présentent l'hémisphère axiologique $Z^- \in \{-7, \dots, -1\}$ (127 pôles de valeurs et triades aristotéliciennes $D_-/V/D_+$ à $Z=-6$) comme partie intégrante d'un « Diamant 303 ». | Dans la Strate 0 ([`Cartograffect/CoreAffect.lean`](../Cartograffect/CoreAffect.lean) et [`docs/01-Article_Cartograffect.md`](01-Article_Cartograffect.md)), la profondeur $Z \in \mathbb{N}$ ($Z \in \{0, \dots, 7\}$) est une **complexité générative et précision métacognitive strictement positive ou nulle** (pyramide à 176 états). | **Cloisonné dans [`extensions/lexicon/EPISTEMIC_STATUS.md`](../extensions/lexicon/EPISTEMIC_STATUS.md) :** Le Diamant 303 est clairement identifié comme une extension exploratoire de Strate 1. Il ne doit pas être injecté dans le corps axiomatique du manuscrit principal. |
| **Proxy linéaire $y_{\text{raw}}$ et retrait des interpolations synthétiques GRID/CPM** | Les scripts de projection VAD utilisent $y_{\text{raw}} = 0.60\,D + 0.40\,A$ (ou $0.60\,A + 0.40\,D$) et une régression linéaire de profondeur $z_{\text{ded}} = 1.2 + 3.2\,r_{L_1}$. Les anciennes interpolations synthétiques GRID/CPM ont été retirées en Phase 1 (`v3.0.0-dev`). | Dans la Strate 0, $Y$ représente exclusivement la **transduction du Contrôle pragmatique ($\pi_C \cdot \text{sgn}(\Delta C)$)** et $Z$ la **précision métacognitive hiérarchique**, distincte de l'amplitude $R(Z)$ ou de l'activation somatique (*arousal*). | **Purge Phase 1 (`v3.0.0-dev`) & [`extensions/lexicon/EPISTEMIC_STATUS.md`](../extensions/lexicon/EPISTEMIC_STATUS.md) :** Les scripts synthétiques GRID/CPM ont été archivés dans `archive/deprecated_synthetic_v2/` ; les proxys VAD résiduels sont strictement qualifiés d'heuristiques exploratoires sans valeur de validation externe (`V3 = 0`). |

---

### 1.3 Écarts du site internet (`SITE INTERNET CARTOGRAFFECT`)

1. **Compteurs de théorèmes et architecture formelle :**
   - Alignés sur la fondation Hexa-Prover canonique (`v2.1.0`) : **130 théorèmes constructifs (`0 sorry`, `0 axiom` ad hoc)** vérifiés symétriquement sur **6 environnements formels** (Lean 4.35.0 [11 modules `.lean`], Rocq 9.1.0 [11 modules `.v`], Agda 2.9.0 [12 modules `.agda`], Dafny 4.11.0 [11 modules `.dfy`, 132 lemmes, 3 021 verified], SMT-LIB 2.6 / Z3 5.3.3 [10 fichiers `.smt2`], TLA+ / TLC 2.19 [18 modules `.tla`, 8 modèles TLC]), complétés par **21/21** théorèmes dans `PredictiveEngineCanonical.lean` et **10/10** théorèmes géométriques Strate 1 Lean dans `extensions/lexicon/lean/`.
2. **Formule exacte de l'antagoniste $\mathcal{A}(X, Y, Z)$ et retrait du bloc GRID-24 (`v3.0.0-dev` Phase 1) :**
   - Correction partout de la formule de l'antagoniste par morceaux (`(-X, -Y, Z)` si `XY = 0`, `(-sgn(X)|Y|, -sgn(Y)|X|, Z)` si `XY ≠ 0`), correction de « 24 positions » en « 48 positions / 24 paires » dans `scholar_drive.html`, et retrait du bloc GRID-24 dans `site-payload.json`.

---

## Partie 2 — Statut Épistémique des Satellites de Strate 1 (Post-Purge Phase 1)

Cette seconde partie consigne le statut épistémique strict de chaque satellite de Strate 1 après les purges d'intégrité probatoire de la Phase 1 (`v3.0.0-dev`).

---

### 2.1 Satellite A — Audit externe exploratoire GEW 3.0 / Plutchik (Retrait intégral de GRID-24 / CPM-142)
*(Sources actives : [`extensions/lexicon/lean/EmotionWheelsChallenge.lean`](../extensions/lexicon/lean/EmotionWheelsChallenge.lean), [`extensions/lexicon/src/validate_emotion_wheels.py`](../extensions/lexicon/src/validate_emotion_wheels.py) ; archives dépréciées : [`archive/deprecated_synthetic_v2/`](../archive/deprecated_synthetic_v2/))*

- **(a) Purge d'intégrité probatoire (Phase 1, `v3.0.0-dev`) :**
  1. **Retrait complet de GRID-24 / CPM-142 :** Les anciens scripts synthétiques GRID-24 / CPM-142 (vecteurs calibrés sur $Z$ avec réinjection sectorielle `0.45 * u_sector / v_sector`) et l'ancien module `SchererGRID.lean` (constantes statistiques Python figées par `decide`) ont été retirés du périmètre actif et archivés dans `archive/deprecated_synthetic_v2/`. Aucune validation empirique ou psychométrique externe (`V3`) n'est revendiquée à partir de ces données synthétiques.
  2. **Assainissement du banc GEW 3.0 / Plutchik :** Dans `EmotionWheelsChallenge.lean`, la preuve circulaire sur Plutchik et toute certification par `decide` de scores statistiques Python ont été supprimées (ne conservant que les 2 invariants géométriques purs). Dans `validate_emotion_wheels.py`, les surcharges manuelles codées en dur (`rire`, `soumission -> by_id[271]`, `canonical_alts`) ont été retirées, et les hypothèses **H2** et **H4** sont rapportées strictement comme **non corroborées** sans recadrage post-hoc.
- **(b) Limites actuelles :**
  - Le test lexical sur les roues publiées (Scherer et al., 2013) reste un audit psycholinguistique exploratoire de Strate 1 (`V3 = 0`) ; il ne constitue pas une validation expérimentale sur sujets humains.
- **(c) Politique d'intégration :**
  - **Maintenir l'audit GEW 3.0 / Plutchik strictement cloisonné en Strate 1** sans injecter aucune revendication de validation psychométrique externe dans [`docs/01-Article_Cartograffect.md`](01-Article_Cartograffect.md).

---

### 2.2 Satellite B — Tests de cohérence *in silico* (P1 : projecteur budgétaire ; P2–P5 : cohérence générative `pymdp`)
*(Sources : [`extensions/in_silico/experiments/01_falsifiable_predictions.py`](../extensions/in_silico/experiments/01_falsifiable_predictions.py), [`extensions/in_silico/results/exp01_statistics.json`](../extensions/in_silico/results/exp01_statistics.json))*

- **(a) Ce que vérifie le banc *in silico* (cohérence interne uniquement, `V3 = 0`) :**
  1. **P1 (Test de cohérence numérique du projecteur budgétaire) :** Vérifie le comportement numérique attendu de l'opérateur explicite `apply_budget_constraint` sous $\lambda = 1$ vs $\lambda = 0$ sur des demandes brutes orthogonales (test de cohérence numérique de la contrainte implémentée, et non validation empirique ou non circulaire).
  2. **P2–P5 (Cohérence générative interne du moteur `pymdp`) :** Vérifie numériquement, sur tenseur préalable $B(Z=2)$ symétrique ($\Delta_{\text{prior}} < 10^{-12}$), l'émergence interne des signatures P2–P5 et fournit des ordres de grandeur pour dimensionner de futurs protocoles expérimentaux humains (EMA / tâche comportementale).
- **(b) Limites actuelles :**
  - Toutes les trajectoires sont générées par le modèle lui-même (`V3 = 0`) ; seule une confrontation sur données humaines indépendantes pourra falsifier ou corroborer P1–P5.
- **(c) Politique d'intégration :**
  - **Maintenir l'ensemble des métriques *in silico* strictement hors du corps théorique** (Arbitrage A4-Sanctuaire) dans [`extensions/in_silico/`](../extensions/in_silico/).

---

### 2.3 Satellite C — Identifiabilité Bayésienne (Expérience 3) et Quarantaine Exploratoire Synthétique DSM-5 / HiTOP (Expériences 4 & 5)
*(Sources actives : [`extensions/in_silico/experiments/02_clinical_phenotypes.py`](../extensions/in_silico/experiments/02_clinical_phenotypes.py), [`03_parameter_and_model_recovery.py`](../extensions/in_silico/experiments/03_parameter_and_model_recovery.py) ; quarantaine : [`extensions/in_silico/exploratory_synthetic/`](../extensions/in_silico/exploratory_synthetic/))*

- **(a) Portée méthodologique :**
  1. **Inversibilité computationnelle (Expérience 3 — Parameter/Model Recovery) :** Vérifie que sur des données synthétiques de $T = 280$ essais générées par le simulateur, l'inversion SVI / NUTS récupère les paramètres latents du simulateur et discrimine les modèles candidats de la famille simulée (`V3 = 0`).
  2. **Quarantaine des Expériences 4 et 5 (`SYNTHETIC EXPLORATORY ONLY — V3 = 0`) :** Les scripts `04_dsm5_phenotyping.py`, `05_dsm5_full_nosology.py` et le texte `05_psychiatrie_computationnelle_dsm5_et_interventions.md` sont isolés dans `extensions/in_silico/exploratory_synthetic/` avec bandeau explicite `SYNTHETIC EXPLORATORY ONLY — V3 = 0` et purge de toute allégation clinique ou nosologique réelle.
- **(b) Limites et approximations actuelles :**
  - Les cohortes DSM-5 / HiTOP sont définies par des **priors paramétriques synthétiques** (aucune donnée patient humaine, `V3 = 0`).
  - La paramétrisation $\theta$ de `pymdp` utilise des approximations continues distinctes du moteur entier `PredictiveCircuit.lean`.
- **(c) Politique d'intégration :**
  - **Conserver Expériences 4 et 5 strictement isolées dans `extensions/in_silico/exploratory_synthetic/` (`SYNTHETIC EXPLORATORY ONLY — V3 = 0`)** et ne jamais les présenter comme validation clinique ou nosologique.

---

### 2.4 Satellite D — Symétrie Axiologique $Z \in [-7, -1]$ (« Diamant 303 ») et Lemmes d'Antipodalité 3D
*(Sources : [`extensions/lexicon/01b_prepare_diamond_z_minus.py`](../extensions/lexicon/01b_prepare_diamond_z_minus.py), [`08_project_diamond_303_lexicon.py`](../extensions/lexicon/08_project_diamond_303_lexicon.py), [`extensions/lexicon/lean/PolarityAntipodal3D.lean`](../extensions/lexicon/lean/PolarityAntipodal3D.lean))*

- **(a) Contenu géométrique :**
  1. **Clôture octaédrique duale :** Adjoint à la pyramide affective $Z \in [0, +7]$ (176 états) un hémisphère axiologique $Z \in [-7, -1]$ (127 pôles de valeurs) recollé le long de l'équateur $Z = +7$ (303 pôles).
  2. **Lemmes `polarity3D` et `zAntipodal3D` :** Les 4 théorèmes constructifs isolés dans [`extensions/lexicon/lean/PolarityAntipodal3D.lean`](../extensions/lexicon/lean/PolarityAntipodal3D.lean) vérifient l'équipartition `84/84` et l'antipodalité verticale sur les 168 pôles périphériques.
- **(b) Limites :**
  - Extension exploratoire strictement hors du périmètre normatif de la Strate 0 et de la refonte v3.0 (voir [`DECISIONS_V3.md`](../DECISIONS_V3.md)).
- **(c) Politique d'intégration :**
  - **Maintenir le Diamant 303 strictement cloisonné dans `extensions/lexicon/`** (intouché en Phase 1 conformément au principe d'économie strict).

---

## Tableau Récapitulatif des Arbitrages (`v2.0.0` → `v3.0.0-dev` Phase 1)

| ID | Décision d'arbitrage | Décision appliquée | Statut |
| :---: | :--- | :--- | :---: |
| **A1** | **Nomenclature des 2 pôles $(0,-6,4)$ et $(-6,4,6)$ dans `extensions/lexicon/`** | Alignement descendant sur la Strate 0 (**`Langueur`** et **`Rancœur`**) dans tous les scripts et tables actives. | **Résolu** |
| **A2** | **Couverture *in silico* P1–P5 dans `extensions/in_silico/`** | P1 requalifié en **test de cohérence numérique du projecteur budgétaire** ; P2–P5 en cohérence générative interne *in silico* (`V3 = 0`) sans règle *ad hoc*. | **Requalifié (Phase 1)** |
| **A3** | **Purge GRID-24 / CPM-142 et assainissement GEW 3.0 / Plutchik** | Retrait complet des artefacts synthétiques GRID-24 / CPM-142 (`archive/deprecated_synthetic_v2/`), suppression des constantes statistiques Python dans Lean et rapport honnête de H2 et H4 comme non corroborées. | **Purgé (Phase 1)** |
| **A4** | **Sanctuarisation des résultats *in silico* (Exp 1–3 vs 4–5)** | Aucune métrique quantitative *in silico* dans les sections théoriques ; Exp 4–5 isolées dans `extensions/in_silico/exploratory_synthetic/` (`SYNTHETIC EXPLORATORY ONLY — V3 = 0`). | **Isolé (Phase 1)** |
| **A5** | **Cloisonnement de l'extension axiologique $Z^-$ (Diamant 303)** | Axiomatique principale maintenue sur $Z \ge 0$ (130 théorèmes Strate 0) ; Diamant 303 cloisonné dans `extensions/lexicon/` (10 théorèmes géométriques Strate 1 Lean). | **Cloisonné** |
| **A6** | **Pont formel de bout en bout `EndToEndBridge` (`v2.1.0`)** | Soudure formelle complète `Circuit → Noyau → Matrice → Opérants {R+, R-, P+, P-} → Dynamique Z→Z+1 → Taxonomie Z=0..7 → Lexicon176` sur les 6 prouveurs (130/130 théorèmes Strate 0 + `all176Entries_unique_labels`). | **Résolu** |
