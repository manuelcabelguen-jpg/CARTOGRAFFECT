# Statut Épistémique — `extensions/in_silico/` (Strate 1 : Simulations Actives & Psychiatrie Computationnelle)

Ce sous-projet appartient à la **Strate 1 (Simulations génératives *in silico* et explorations cliniques)** du compendium unifié **CARTOGRAFFECT®**. Il est strictement subordonné à la **Strate 0 (Noyau formel Hexa-Prover et moteur prédictif exact)**.

---

## 1. Distinction Fondamentale entre le Moteur Exact de Strate 0 et le Simulateur `pymdp` de Strate 1

Le dépôt contient deux implémentations Python qu'il convient de ne jamais confondre sur le plan épistémologique :

| Caractéristique | Strate 0 : [`python/cartograffect_predictive_engine.py`](../../python/cartograffect_predictive_engine.py) | Strate 1 : [`extensions/in_silico/src/cartograffect_sim/`](src/cartograffect_sim/) |
| :--- | :--- | :--- |
| **Fondement formel** | **Isomorphe exact** à [`Cartograffect/PredictiveCircuit.lean`](../../Cartograffect/PredictiveCircuit.lean) et [`Cartograffect/AffectiveDynamics.lean`](../../Cartograffect/AffectiveDynamics.lean) | **Opérationnalisation probabiliste continue/discrète** sous Active Inference (`pymdp` / JAX / NumPyro) |
| **Arithmétique** | **Arithmétique entière exacte ($\mathbb{Z}$)** à facteur d'échelle fixe (`scale = 1 000`), zéro flottant critique | **Flottants IEEE 754 (`float32`/`float64`)**, tenseurs stochastiques et échantillonnage Monte-Carlo / MCMC |
| **Invariants certifiés** | Identité algébrique exacte $4 \cdot \text{scale}^6$, budget $L_1$ `apportionRay`, non-négativité de l'énergie libre $F_t \ge 0$, théorème du point fixe homéostatique $(0,0,0)$, cliquet d'irréversibilité $\Delta Z \in \{-1, 0, +1\}$ | Conservation géométrique des 176 états sur la grille $L_1$, symétrie non circulaire du tenseur $B(Z=2)$ ($\Delta_{\text{prior}} < 10^{-12}$), monotonie des concentrations de Dirichlet $\alpha(Z)$ |
| **Espace paramétrique** | Septuplet entier `CircuitParams` $(\rho, \kappa, \delta_A, \delta_C, \gamma_A, \gamma_C, \chi, \epsilon)$ et vecteur d'état $(R_t, Z_t, \tilde{\pi}_{A,t}, \tilde{\pi}_{C,t})$ | Vecteur continu $\theta = (\tau_A, \tau_C, \lambda, \alpha_0, \gamma_\alpha, \eta_{\text{diss}}, \beta_X, \beta_Y)$ (+ $\delta_c$ transdiagnostique) |
| **Rôle scientifique** | **Référence de vérité formelle** et jumeau d'exécution des 113 théorèmes Hexa-Prover | **Banc d'essai génératif** : réfutabilité Monte-Carlo (P1–P3), inversion bayésienne (Parameter & Model Recovery) et explorations nosologiques DSM-5 / HiTOP |

---

## 2. Périmètre et Approximations des Cinq Expériences *in silico*

### 2.1 Expérience 1 — Tests de réfutation Monte-Carlo ([`experiments/01_falsifiable_predictions.py`](experiments/01_falsifiable_predictions.py))
- **Ce qui est validé :**
  - **P1 (Arbitrage énergétique $L_1$) :** Corrélation négative intra-strate $\text{Corr}(\Delta |X_t|, \Delta |Y_t|) = -0.8445$ sous contrainte $\lambda = 1$ contre $+0.0052$ sous $\lambda = 0$ ($p = 2.91 \times 10^{-165}$).
  - **P2 (Instabilité axiale émergente en $Z=2$) :** Sans biais dans le tenseur de transition préalable $B(Z=2)$, les pôles axiaux présentent un temps de résidence inférieur aux pôles diagonaux ($1.404$ vs $1.564$, $p = 2.67 \times 10^{-37}$) et un flux préférentiel Axial $\to$ Diagonal.
  - **P3 (Inertie hiérarchique) :** Croissance monotone de la demi-vie de rémission $t_{1/2}(Z=5) > t_{1/2}(Z=4) > t_{1/2}(Z=2)$ gouvernée par la concentration de Dirichlet $\alpha(Z) = \alpha_0 \exp(\gamma_\alpha Z)$.
- **Limites actuelles face au Noyau :**
  - Les prédictions **P4** (priorité lexicographique de la valence $\text{sgn}(X)$ sur le taux de variation $\Delta X_t$, contre Joffily & Coricelli, 2013) et **P5** (médiation par le contrôle pragmatique $\hat{p}_{\text{ctrl}}$ de la bifurcation depuis la Peur axiale $(-2,0,2)$ vers la Colère $(-1,1,2)$ vs le Dégoût $(-1,-1,2)$) du Tableau 2 de l'article `v1.0.2` ne font pas encore l'objet d'un test dédié dans `01_falsifiable_predictions.py`.

### 2.2 Expérience 3 — Récupération de paramètres et de modèles ([`experiments/03_parameter_and_model_recovery.py`](experiments/03_parameter_and_model_recovery.py))
- **Statut épistémique :** Établit l'identifiabilité statistique du modèle génératif ($\min r = 0.8806 \ge 0.80$, couverture IC 95 % $\ge 0.884$, $\max \hat{R} = 1.010$ sous NUTS) et sa séparabilité bayésienne face à trois modèles rivaux (2D circumplex sans $Z$, 3D sans contrainte $L_1$, valence scalaire 1D : $\text{PXP}_{\text{BIC}} = 1.0000$) sur une tâche de bandit non stationnaire à 280 essais (`GenerativeProcess`). Il s'agit d'une preuve d'**identifiabilité computationnelle *in silico*** préalable aux études cliniques empiriques (EMA/hrV).

### 2.3 Expériences 2, 4 et 5 — Phénotypes cliniques et Nosologie Computationnelle DSM-5 / HiTOP
- **Fichiers :** [`experiments/02_clinical_phenotypes.py`](experiments/02_clinical_phenotypes.py), [`experiments/04_dsm5_phenotyping.py`](experiments/04_dsm5_phenotyping.py), [`experiments/05_dsm5_full_nosology.py`](experiments/05_dsm5_full_nosology.py), [`src/cartograffect_sim/dsm5_profiles.py`](src/cartograffect_sim/dsm5_profiles.py), [`src/cartograffect_sim/dsm5_full_nosology.py`](src/cartograffect_sim/dsm5_full_nosology.py).
- **Statut épistémique :**
  - Les 4 profils de l'Expérience 2, les 8 cohortes DSM-5 de l'Expérience 4 ($N = 1\,600$) et les 26 régimes / 7 spectres HiTOP de l'Expérience 5 ($N = 2\,600$) reposent sur des **lois *a priori* paramétriques multivariées synthétiques** ($\theta$, biais de contrôlabilité $\delta_c$, mélange bimodal TSPT, agitation stochastique $\sigma_{Z_{4,6}}$ pour le TPL) calibrées sur la littérature théorique d'Active Inference (Friston et al., 2014 ; Schwartenbeck & Friston, 2016) et sur les 5 ruptures d'ergodicité de la section `4.1` de l'article canonique.
  - Les résultats de séparabilité QDA ($93.3\,\%$ sur 8 cohortes, $92.6\,\%$ sur 7 spectres HiTOP) et la **double dissociation thérapeutique *in silico*** (réétalonnage intéroceptif Bottom-Up $\tau_{A,C}$ vs restructuration métacognitive Top-Down $\alpha_{z \ge 4}$) constituent des **prédictions computationnelles exploratoires (pré-cliniques)** et non des données cliniques issues de patients humains.
