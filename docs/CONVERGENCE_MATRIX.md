# Matrice de Convergence et d'Arbitrage Épistémique — CARTOGRAFFECT®

**Branche :** `refactor/unified-compendium`  
**Hiérarchie épistémique appliquée :**
- **STRATE 0 (Noyau canonique faisant autorité) :** Fondation formelle Hexa-Prover (113 théorèmes constructifs sur 6 assistants de preuve : Lean 4, Rocq 9.0, Agda 2.8, Dafny 4.11 / Z3, SMT-LIB2 / Z3, TLA+ / TLC), moteur markovien entier [`python/cartograffect_predictive_engine.py`](../python/cartograffect_predictive_engine.py) et article théorique consolidé [`docs/01-Article_Cartograffect.md`](01-Article_Cartograffect.md) (fusion de `v1.0.2.docx` et de la section `4.1`).
- **STRATE 1 (Satellites exploratoires asservis au Noyau) :** [`extensions/lexicon/`](../extensions/lexicon/) (`nrc_cartograffect_pipeline`) et [`extensions/in_silico/`](../extensions/in_silico/) (`Cartograffect-simulation-in-silico`).

---

## Partie 1 — Alignements descendants requis (Approximations des satellites à corriger face au Noyau)

Cette première partie recense tous les écarts, approximations paramétriques ou divergences de nomenclature identifiés dans les satellites (**Strate 1**) et sur le site web vis-à-vis de la **Strate 0**, afin que le Noyau exerce son autorité descendante sans contamination inverse.

### 1.1 Écarts entre `extensions/in_silico/` et le Noyau (Strate 0)

| Domaine / Fichier satellite | État dans `extensions/in_silico/` (Strate 1) | Vérité canonique du Noyau (Strate 0) | Action d'alignement descendant (exécutée ou requise à l'Étape 3) |
| :--- | :--- | :--- | :--- |
| **Couverture des 5 prédictions falsifiables (Tableau 2)** | [`experiments/01_falsifiable_predictions.py`](../extensions/in_silico/experiments/01_falsifiable_predictions.py) teste par Monte-Carlo ($N=1\,000$) les prédictions **P1** (arbitrage $L_1$), **P2** (instabilité axiale en $Z=2$) et **P3** (inertie hiérarchique $t_{1/2}(Z)$), mais **omet P4 et P5**. | [`docs/01-Article_Cartograffect.md`](01-Article_Cartograffect.md) (Tableau 2) définit **5 prédictions falsifiables P1 à P5**, incluant **P4** (priorité lexicographique de la valence $\text{sgn}(X_t)$ sur le taux de variation $\Delta X_t$, contre Joffily & Coricelli, 2013) et **P5** (médiation par le contrôle pragmatique $\hat{p}_{\text{ctrl}}$ de la transition depuis la Peur axiale $(-2,0,2)$ vers la Colère $(-1,1,2)$ vs le Dégoût $(-1,-1,2)$), toutes deux certifiées dans [`Cartograffect/AffectiveMatrix.lean`](../Cartograffect/AffectiveMatrix.lean) et [`Cartograffect/AffectiveDynamics.lean`](../Cartograffect/AffectiveDynamics.lean). | **À arbitrer pour l'Étape 3 :** Étendre `01_falsifiable_predictions.py` (ou ajouter un module complémentaire) pour tester empiriquement P4 et P5 sur les trajectoires Monte-Carlo, afin d'aligner la couverture *in silico* sur les 5 prédictions du Tableau 2. |
| **Paramétrisation et dynamique du circuit fermé** | Le simulateur POMDP [`src/cartograffect_sim/`](../extensions/in_silico/src/cartograffect_sim/) utilise un vecteur continu $\theta = (\tau_A, \tau_C, \lambda, \alpha_0, \gamma_\alpha, \eta_{\text{diss}}, \beta_X, \beta_Y, \delta_c)$ en virgule flottante, avec mise à jour de Dirichlet $\alpha(Z) = \alpha_0 \exp(\gamma_\alpha Z)$ sur la matrice de vraisemblance $A$ et tenseur de transition $B$ à 11 actions. | [`Cartograffect/PredictiveCircuit.lean`](../Cartograffect/PredictiveCircuit.lean) et [`python/cartograffect_predictive_engine.py`](../python/cartograffect_predictive_engine.py) définissent un système dynamique discret en **arithmétique entière exacte ($\mathbb{Z}$, `scale = 1 000`)** paramétré par $(\rho, \kappa, \delta_A, \delta_C, \gamma_A, \gamma_C, \chi, \epsilon)$ sur le quadruplet d'état $(R_t, Z_t, \tilde{\pi}_{A,t}, \tilde{\pi}_{C,t})$, avec l'identité de conservation $4 \cdot \text{scale}^6$ et l'opérateur idempotent `apportionRay`. | **Documenté dans [`extensions/in_silico/EPISTEMIC_STATUS.md`](../extensions/in_silico/EPISTEMIC_STATUS.md) :** Le POMDP `pymdp` est explicitement qualifié d'opérationnalisation statistique continue destinée à l'inversion bayésienne (SVI/NUTS), subordonnée au noyau markovien entier exact. À l'Étape 3, un pont de correspondance explicite entre $\theta$ et `CircuitParams` pourra être ajouté. |
| **Source du lexique des 176 états** | [`data/lexicon_176.json`](../extensions/in_silico/data/lexicon_176.json) est un export JSON statique autonome (déjà conforme à `"Point de Veille"` en $(0,0,0)$ et à `Désenchantement`/`Enchantement` en $(\mp 2, \pm 6, 5)$). | [`Cartograffect/Lexicon176.lean`](../Cartograffect/Lexicon176.lean) est l'unique source de vérité formelle des 176 prototypes. | **Vérifié :** `data/lexicon_176.json` est 100 % isomorphe aux 176 entrées de `Cartograffect/Lexicon176.lean`. |
| **Fuites de chemins locaux absolus (profil utilisateur / Dropbox)** | 19 occurrences de chemins absolus locaux (`C:\Users\<user>\...`) étaient présentes dans `results/*.json`, `results/dsm5_*/*.json` et `articles/05_...md`, causées par `str(fig_path)` dans `experiments/01..05_*.py`. | Exigence de reproductibilité zéro-fuite (`0` chemin absolu local dans le dépôt). | **Corrigé à l'Étape 2.3 :** Les 5 scripts `experiments/01..05_*.py`, les 6 fichiers JSON de résultats et l'article `05_...md` utilisent désormais exclusivement des chemins relatifs POSIX. |

---

### 1.2 Écarts entre `extensions/lexicon/` et le Noyau (Strate 0)

| Domaine / Fichier satellite | État dans `extensions/lexicon/` (Strate 1) | Vérité canonique du Noyau (Strate 0) | Action d'alignement descendant (exécutée ou requise à l'Étape 3) |
| :--- | :--- | :--- | :--- |
| **Libellé de l'origine $(0, 0, 0)$ à $Z=0$** | Le fichier divergent `nrc_cartograffect_pipeline/Lexicon176.lean` et les tables `.tsv` historiques utilisaient `"Veille"` en $(0,0,0)$ pour que [`scripts/audit_geometric_lexical_placement.py`](../extensions/lexicon/scripts/audit_geometric_lexical_placement.py) puisse rejeter le syntagme multi-mot `"Point de Veille"` du lexique empirique d'unigrammes. | [`Cartograffect/Lexicon176.lean`](../Cartograffect/Lexicon176.lean) et [`docs/01-Article_Cartograffect.md`](01-Article_Cartograffect.md) définissent **`"Point de Veille"`** comme nom ontologique canonique de l'opérateur $(0,0,0)$ (tandis que le lemme français d'unigramme projeté sur ce pôle est `"veille"`). | **Corrigé à l'Étape 2.3 :** Le fichier divergent `Lexicon176.lean` n'a **pas** été copié. Les 4 fichiers Lean de [`extensions/lexicon/lean/`](../extensions/lexicon/lean/) importent directement le canonique `Cartograffect.Lexicon176` et compilent avec `0 sorry`. [`01_build_ref176.py`](../extensions/lexicon/01_build_ref176.py) lit `../../Cartograffect/Lexicon176.lean`, avec alias de compatibilité `"Veille"` $\leftrightarrow$ `"Point de Veille"` en lecture. |
| **Deux substitutions de libellés dans le Diamant 303 ($Z=4$ et $Z=6$)** | Dans [`01b_prepare_diamond_z_minus.py`](../extensions/lexicon/01b_prepare_diamond_z_minus.py) (L502–509) et dans un commentaire de [`lean/SchererGRID.lean`](../extensions/lexicon/lean/SchererGRID.lean) (L391, L401), deux prototypes de $Z > 0$ sont renommés : `(0, -6, 4)` **`Langueur` $\to$ `Solitude`** (ancre GRID `SADNESS`) et `(-6, 4, 6)` **`Rancœur` $\to$ `Irritation`** (ancre GRID `IRRITATION`). | [`Cartograffect/Lexicon176.lean`](../Cartograffect/Lexicon176.lean), [`docs/01-Article_Cartograffect.md`](01-Article_Cartograffect.md) et [`docs/02-Inventaire_176.md`](02-Inventaire_176.md) définissent invariablement **`Langueur`** en $(0,-6,4)$ (antagoniste d'*Exaltation* $(0,6,4)$) et **`Rancœur`** en $(-6,4,6)$ (antagoniste de *Mansuétude* $(4,-6,6)$). | **À arbitrer pour l'Étape 3 :** Dans la Strate 0, `Langueur` et `Rancœur` demeurent intouchables. Dans `extensions/lexicon/`, il est recommandé à l'Étape 3 de conserver `Langueur` et `Rancœur` comme noms de prototypes canoniques tout en rattachant `solitude` et `irritation` comme **lemmes empiriques / ancres GRID** projetés sur ces coordonnées, évitant ainsi toute dualité de nomenclature entre les tables 176 et 303. |
| **Paire controlatérale $(\mp 2, \pm 6, 5)$ entre `v1.0.2.docx` (Annexe A) et `Lexicon176.lean`** | L'Annexe A du manuscrit `v1.0.2.docx` mentionnait `Malveillance (-2, 6, 5) <-> Bienveillance (6, -2, 5)`, tandis que tous les fichiers de code (Strate 0 et Strate 1) utilisent `Désenchantement (-2, 6, 5) <-> Enchantement (6, -2, 5)` (car `Malveillance` et `Bienveillance` occupent déjà $(\mp 3, \pm 5, 5)$). | [`Cartograffect/Lexicon176.lean`](../Cartograffect/Lexicon176.lean) (L152, L161) prouve l'unicité des 176 étiquettes : $(\mp 3, \pm 5, 5) =$ `Malveillance` / `Bienveillance` et $(\mp 2, \pm 6, 5) =$ **`Désenchantement` / `Enchantement`**. | **Corrigé à l'Étape 2.2 :** Lors de la fusion canonique dans [`docs/01-Article_Cartograffect.md`](01-Article_Cartograffect.md), l'Annexe A a été alignée sur la preuve formelle `Cartograffect/Lexicon176.lean` (`Désenchantement` $\leftrightarrow$ `Enchantement`), éliminant le doublon avec $(\mp 3, \pm 5, 5)$. |
| **Statut de la strate $Z$ négative ($Z \in [-7, -1]$, Diamant 303)** | [`01b_prepare_diamond_z_minus.py`](../extensions/lexicon/01b_prepare_diamond_z_minus.py) et [`08_project_diamond_303_lexicon.py`](../extensions/lexicon/08_project_diamond_303_lexicon.py) présentent l'hémisphère axiologique $Z^- \in \{-7, \dots, -1\}$ (127 pôles de valeurs et triades aristotéliciennes $D_-/V/D_+$ à $Z=-6$) comme partie intégrante d'un « Diamant 303 ». | Dans la Strate 0 ([`Cartograffect/CoreAffect.lean`](../Cartograffect/CoreAffect.lean) et [`docs/01-Article_Cartograffect.md`](01-Article_Cartograffect.md)), la profondeur $Z \in \mathbb{N}$ ($Z \in \{0, \dots, 7\}$) est une **complexité générative et précision métacognitive strictement positive ou nulle** (pyramide à 176 états). | **Cloisonné dans [`extensions/lexicon/EPISTEMIC_STATUS.md`](../extensions/lexicon/EPISTEMIC_STATUS.md) :** Le Diamant 303 est clairement identifié comme une extension exploratoire de Strate 1. Il ne doit pas être injecté dans le corps axiomatique de l'article `v1.0.2` sans arbitrage explicite (voir Partie 2.4). |
| **Hypothèses d'interpolation GRID/CPM et proxy linéaire $y_{\text{raw}}$** | Les scripts de projection utilisent $y_{\text{raw}} = 0.60\,D + 0.40\,A$ (ou $0.60\,A + 0.40\,D$), une régression linéaire de profondeur $z_{\text{ded}} = 1.2 + 3.2\,r_{L_1}$ et une interpolation RBF + $k$-NN des 24 ancres GRID vers 176 pôles puis 15 037 lemmes. | Dans la Strate 0, $Y$ représente exclusivement la **transduction du Contrôle pragmatique ($\pi_C \cdot \text{sgn}(\Delta C)$)** et $Z$ la **précision métacognitive hiérarchique**, distincte de l'amplitude $R(Z)$ ou de l'activation somatique (*arousal*). | **Documenté dans [`extensions/lexicon/EPISTEMIC_STATUS.md`](../extensions/lexicon/EPISTEMIC_STATUS.md) :** Ces formules sont qualifiées de proxys psycholinguistiques nécessaires pour pallier l'absence de mesure directe de $Z$ dans les bases VAD classiques, et non d'identités théoriques du modèle. |

---

### 1.3 Écarts du site internet (`SITE INTERNET CARTOGRAFFECT`) à corriger à l'Étape 5

*(Conformément aux règles de sécurité de l'Étape 2, aucun fichier du dossier `SITE INTERNET CARTOGRAFFECT` n'a été modifié. Ces écarts sont consignés ici pour exécution à l'Étape 5.)*

1. **Compteurs de théorèmes et architecture formelle obsolètes :**
   - `index.html` (L35, L256) et `preuves.html` affichent encore : *« 68 théorèmes prouvés (dont 33 théorèmes audités et 38 vérifications d'axiomes), répartis dans 18 fichiers de preuve sur 6 environnements formels »*.
   - **Correction requise à l'Étape 5 :** Aligner sur la fondation Hexa-Prover canonique : **113 théorèmes constructifs (`0 sorry`, `0 axiom` ad hoc)** vérifiés symétriquement sur **6 environnements formels** (Lean 4 [9 modules `.lean`], Rocq 9.0, Agda 2.8, Dafny 4.11, SMT-LIB2 / Z3, TLA+ / TLC).
2. **Version et contenu de l'article web (`article.html`) en retard :**
   - `article.html` affiche `Version 1.0.1` (L190), l'ancienne affiliation (*« Chercheur indépendant, Québec, Canada »* au lieu de *« Psychologue clinicien, chercheur indépendant en psychologie, Sainte-Agathe-des-Monts, Québec, Canada »*), seulement 7 modules `.lean` (omettant `AffectiveDynamics.lean` et `PredictiveCircuit.lean`), 3 prédictions au lieu des **5 prédictions P1–P5 (Tableau 2)**, et omet le **Tableau 1**, la section `4.1` (circuit génératif fermé et tableau des 5 ruptures d'ergodicité) ainsi que les contingences écologiques ($R^+, P^-, P^+, R^-$).
3. **Clone imbriqué obsolète :**
   - Le sous-dossier `SITE INTERNET CARTOGRAFFECT/CARTOGRAFFECT` est en retard de 9 commits sur `main` (commit `fe41bb3`). Il devra être supprimé ou synchronisé à l'Étape 5.

---

## Partie 2 — Propositions d'enrichissement ascendant (Apports des satellites soumis à arbitrage)

Cette seconde partie présente les **4 apports scientifiques majeurs** produits par les satellites de Strate 1, évalués selon trois critères : **(a) ce qu'ils renforcent dans la théorie**, **(b) leurs limites et approximations actuelles**, et **(c) la recommandation d'intégration** soumise à votre arbitrage avant l'Étape 3.

---

### 2.1 Apport A — Validation psychométrique externe via Scherer GRID / CPM et défi aux Roues des Émotions 2D
*(Sources : [`extensions/lexicon/lean/SchererGRID.lean`](../extensions/lexicon/lean/SchererGRID.lean), [`extensions/lexicon/lean/EmotionWheelsChallenge.lean`](../extensions/lexicon/lean/EmotionWheelsChallenge.lean), [`extensions/lexicon/src/validate_emotion_wheels.py`](../extensions/lexicon/src/validate_emotion_wheels.py))*

- **(a) Ce qu'il renforce dans la théorie :**
  1. **Ancrage empirique multi-composantes :** Démontre que les coordonnées théoriques $(X, Y, Z)$ s'alignent fortement avec les 142 descripteurs empiriques du *Component Process Model* (Scherer et al., 2013) sur les 24 émotions GRID ($\rho_1 = 0.9163$ en corrélation canonique CCA ; congruence de Tucker $\phi_Z = 0.8762$ sur le témoin GRID-24).
  2. **Validité discriminante de $Z$ face à l'intensité (Test H5) :** Établit que la profondeur $Z$ est positivement corrélée à la complexité cognitive/normative (`Ratio_Z`, $r = +0.517, p < 10^{-4}$ en intra-famille à rayon normalisé) et **négativement ou orthogonalement** corrélée à l'activation somatique brute ($r = -0.779$), réfutant l'objection selon laquelle $Z$ ne serait qu'un axe d'intensité.
  3. **Supériorité géométrique sur les modèles 2D (GEW 3.0 et Plutchik) :** Prouve formellement sous Lean 4 (`EmotionWheelsChallenge.lean`) qu'aucune roue 2D à rayon fixe ne peut représenter sans écrasement projectif les 8 cônes de 36 états ni l'involution 3D $\mathcal{A}(P)$ (erreur angulaire moyenne de $53.3^\circ$ des paires de Plutchik dans l'espace empirique GRID contre une involution exacte dans CARTOGRAFFECT).
- **(b) Limites et approximations actuelles :**
  - L'échantillon empirique direct du GRID ne comporte que **24 termes émotionnels** ; l'extension aux 176 prototypes repose sur une interpolation RBF/$k$-NN.
  - Le fichier `SchererGRID.lean` mentionne en commentaire les deux alias du Diamant 303 (`Solitude`, `Irritation`).
- **(c) Recommandation d'intégration :**
  - **Citer synthétiquement en Section 5 (Discussion / Validation psychométrique convergente) de [`docs/01-Article_Cartograffect.md`](01-Article_Cartograffect.md)** (en 1 paragraphe précis rapportant le test sur les 24 ancres GRID et la comparaison avec GEW 3.0 / Plutchik), tout en **conservant le pipeline lexical complet dans `extensions/lexicon/`** comme programme empirique de Strate 1.

---

### 2.2 Apport B — Falsifiabilité Monte-Carlo non circulaire des prédictions P1, P2 et P3
*(Sources : [`extensions/in_silico/experiments/01_falsifiable_predictions.py`](../extensions/in_silico/experiments/01_falsifiable_predictions.py), [`extensions/in_silico/results/exp01_statistics.json`](../extensions/in_silico/results/exp01_statistics.json))*

- **(a) Ce qu'il renforce dans la théorie :**
  1. **Preuve de non-circularité générative :** Démontre que même lorsque le tenseur de transition $B(Z=2)$ est construit avec une symétrie exacte entre pôles axiaux et diagonaux ($\Delta_{\text{prior}} = 0.00$), la dynamique d'inférence active en boucle fermée fait **émerger** spontanément une durée de résidence plus courte sur les pôles axiaux ($1.404$ vs $1.564$ essais, $p = 2.67 \times 10^{-37}$, $d_z = 0.43$) et une asymétrie de flux Axial $\to$ Diagonal ($0.1449$ vs $0.1304$, $p = 4.35 \times 10^{-36}$).
  2. **Quantification des tailles d'effet pour P1 et P3 :** Fournit des ordres de grandeur statistiques précis ($\text{Corr}(\Delta|X|, \Delta|Y|) = -0.8445, d_z = -4.29$ pour P1 ; $t_{1/2}(Z=5) = 9.06 > t_{1/2}(Z=4) = 5.47 > t_{1/2}(Z=2) = 1.98$ essais pour P3) permettant de calibrer la puissance statistique ($1 - \beta > 0.95$) de futurs protocoles EMA humains.
- **(b) Limites et approximations actuelles :**
  - Ne couvre actuellement que **P1, P2 et P3** sur les 5 prédictions du Tableau 2 (P4 et P5 restent à implémenter dans `01_falsifiable_predictions.py`).
- **(c) Recommandation d'intégration :**
  - **Compléter `01_falsifiable_predictions.py` avec P4 et P5 à l'Étape 3**, puis **référencer ces résultats Monte-Carlo dans la Section 4.4 de [`docs/01-Article_Cartograffect.md`](01-Article_Cartograffect.md)** comme validation computationnelle *in silico* des prédictions P1–P5.

---

### 2.3 Apport C — Identifiabilité Bayésienne (Parameter/Model Recovery) et Nosologie Computationnelle DSM-5 / HiTOP
*(Sources : [`extensions/in_silico/experiments/02_clinical_phenotypes.py`](../extensions/in_silico/experiments/02_clinical_phenotypes.py), [`03_parameter_and_model_recovery.py`](../extensions/in_silico/experiments/03_parameter_and_model_recovery.py), [`04_dsm5_phenotyping.py`](../extensions/in_silico/experiments/04_dsm5_phenotyping.py), [`05_dsm5_full_nosology.py`](../extensions/in_silico/experiments/05_dsm5_full_nosology.py))*

- **(a) Ce qu'il renforce dans la théorie :**
  1. **Inversibilité empirique du modèle :** Prouve qu'à partir de seulement $T = 280$ essais comportementaux et oculométriques/EMA simulés, l'inférence variationnelle (SVI) et MCMC (NUTS) récupère fidèlement les paramètres latents ($r \in [0.88, 0.99]$, $\max \hat{R} = 1.010$) et discrimine CARTOGRAFFECT des modèles 1D/2D/3D-sans-$L_1$ avec une probabilité de dépassement protégée $\text{PXP}_{\text{BIC}} = 1.0000$.
  2. **Opérationnalisation transdiagnostique et double dissociation thérapeutique :** Montre comment les 5 ruptures d'ergodicité de la section `4.1` génèrent des signatures d'occupation distinctes sur les 176 états à travers 26 régimes DSM-5 et 7 spectres HiTOP, et prédit une **double dissociation mécanistique** entre interventions *Bottom-Up* (réétalonnage de la précision sensorielle $\tau_{A,C}$, supérieur dans les troubles d'hyper-réactivité / alarme phasique) et *Top-Down* (assouplissement des priors de Dirichlet $\alpha_{z \ge 4}$, supérieur dans les troubles rigides/internalisés).
- **(b) Limites et approximations actuelles :**
  - Les cohortes DSM-5 / HiTOP sont définies par des **priors paramétriques synthétiques** (et non estimées sur des cohortes cliniques réelles).
  - La paramétrisation $\theta$ de `pymdp` utilise des approximations continues distinctes du moteur entier `PredictiveCircuit.lean`.
- **(c) Recommandation d'intégration :**
  - **Garder les Expériences 4 et 5 (DSM-5 / HiTOP) comme programme de recherche séparé dans `extensions/in_silico/`** (matière d'un second article dédié de psychiatrie computationnelle), et **ne citer dans la Section 4.1 / Discussion de [`docs/01-Article_Cartograffect.md`](01-Article_Cartograffect.md) que l'identifiabilité bayésienne (Expérience 3) et les 4 phénotypes purs-$\theta$ (Expérience 2)** illustrant le tableau des 5 ruptures d'ergodicité.

---

### 2.4 Apport D — Symétrie Axiologique $Z \in [-7, -1]$ (« Diamant 303 ») et Lemmes d'Antipodalité 3D
*(Sources : [`extensions/lexicon/01b_prepare_diamond_z_minus.py`](../extensions/lexicon/01b_prepare_diamond_z_minus.py), [`08_project_diamond_303_lexicon.py`](../extensions/lexicon/08_project_diamond_303_lexicon.py), [`extensions/lexicon/lean/PolarityAntipodal3D.lean`](../extensions/lexicon/lean/PolarityAntipodal3D.lean))*

- **(a) Ce qu'il renforce dans la théorie :**
  1. **Clôture octaédrique duale :** En adjoignant à la pyramide affective $Z \in [0, +7]$ (176 états) un hémisphère supérieur $Z \in [-7, -1]$ (127 pôles axiologiques de valeurs, forces et engagements) recollé le long de l'équateur de *Suspension* ($Z = +7, R = 12$), l'espace d'états devient un **octaèdre discret complet de 303 pôles** doté de la *Rose des 8 symétries* (incluant l'homologie verticale $+Z \leftrightarrow -Z$ et le contrepoids croisé trans-hémisphérique).
  2. **Séparation grammaticale et triades aristotéliciennes ($Z = -6$) :** Permet de séparer rigoureusement dans les lexiques (NRC-VAD, DIMA) les *affects éprouvés* ($Z^+$) des *valeurs et traits moraux/épistémiques* ($Z^-$), tout en structurant la strate $Z = -6$ en triades $(D_-\text{ déficit}, V\text{ valeur centrale}, D_+\text{ excès})$.
  3. **Lemmes `polarity3D` et `zAntipodal3D` :** Les 4 théorèmes constructifs isolés dans [`extensions/lexicon/lean/PolarityAntipodal3D.lean`](../extensions/lexicon/lean/PolarityAntipodal3D.lean) prouvent la partition exacte $127 + 49 + 127 = 303$ et la conservation du rayon $L_1$ par réflexion verticale autour de l'équateur $Z = 7$.
- **(b) Limites et approximations actuelles :**
  - Dans le Noyau formel actuel (113 théorèmes Hexa-Prover) et l'article `v1.0.2`, $Z \in \mathbb{N}$ est défini comme un niveau de précision et de profondeur générative non négatif ($Z \in \{0, \dots, 7\}$). L'introduction de $Z < 0$ modifie l'interprétation ontologique de l'axe vertical (qui devient bipolaire Affects $Z^+$ $\leftrightarrow$ Valeurs $Z^-$ après traversée de la Suspension $Z = +7$).
  - Les 127 pôles axiologiques de $Z^-$ ne sont pas encore formalisés dans les 6 prouveurs du Noyau.
- **(c) Recommandation d'intégration :**
  - **Maintenir le Diamant 303 ($Z \in [-7, +7]$) strictement cloisonné dans `extensions/lexicon/` pour la version actuelle (`v1.0.2`)** afin de préserver l'unité axiomatique de la pyramide affective $Z \in \{0, \dots, 7\}$ dans l'article principal, et le désigner comme **candidat futur à un second mémoire théorique et à une extension formelle Hexa-Prover v2.0** (avec mention prospective possible en conclusion de l'article si vous le souhaitez).

---

## Tableau Récapitulatif des Arbitrages Soumis pour l'Étape 3

| ID | Décision soumise à votre arbitrage | Option recommandée par l'architecte épistémique |
| :---: | :--- | :--- |
| **A1** | **Nomenclature des 2 pôles $(0,-6,4)$ et $(-6,4,6)$ dans `extensions/lexicon/`** | Aligner `extensions/lexicon/` sur le Noyau (**`Langueur`** et **`Rancœur`**) comme noms de prototypes, en conservant *Solitude* et *Irritation* comme étiquettes d'ancres GRID / lemmes rattachés. |
| **A2** | **Tests Monte-Carlo des prédictions P4 et P5 dans `extensions/in_silico/`** | Implémenter les tests Monte-Carlo de **P4** (priorité lexicographique de $X$) et **P5** (médiation pragmatique Peur $\to$ Colère vs Dégoût) dans `01_falsifiable_predictions.py` pour couvrir 100 % du Tableau 2. |
| **A3** | **Intégration des résultats Scherer GRID / GEW 3.0 dans l'article (`01-Article_Cartograffect.md`)** | Ajouter un paragraphe synthétique de validation psychométrique convergente (24 ancres GRID, test H5 sur $Z$, réfutation de l'antagonisme 2D) en Section 5 (Discussion). |
| **A4** | **Intégration des résultats *in silico* (Expériences 1–3 vs 4–5) dans l'article** | Citer les résultats Monte-Carlo (Exp 1), les 4 phénotypes purs-$\theta$ (Exp 2) et l'identifiabilité bayésienne (Exp 3) dans les Sections 4.1/4.4, et réserver les Expériences 4–5 (DSM-5 / HiTOP) à un article séparé. |
| **A5** | **Statut de l'extension axiologique $Z^-$ (Diamant 303)** | Conserver le Diamant 303 dans `extensions/lexicon/` (Strate 1) sans modifier l'axiomatique $Z \in \{0,\dots,7\}$ de l'article `v1.0.2` (éventuellement 1 phrase d'ouverture en Conclusion). |
