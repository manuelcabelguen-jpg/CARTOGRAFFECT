# Statut Épistémique — `extensions/in_silico/` (Strate 1 : Simulations Actives & Explorations Synthétiques)

Ce sous-projet appartient à la **Strate 1 (Simulations génératives *in silico* et explorations synthétiques)** du compendium **CARTOGRAFFECT (`v3.0.0`)**. Il est strictement subordonné à la **Strate 0 (Cœur normatif Lean 4 : 8 modules normatifs, 148 théorèmes substantiels / 169 déclarations exportées, 0 `sorryAx`, 0 `native_decide`, et moteur prédictif exact Python à 11 tests unitaires)** et n'apporte aucune validation empirique ou clinique sur sujets humains (`V3 = 0`).

---

## 1. Distinction Fondamentale entre le Moteur Exact de Strate 0 et le Simulateur `pymdp` de Strate 1

Le dépôt contient deux implémentations Python qu'il convient de ne jamais confondre sur le plan épistémologique :

| Caractéristique | Strate 0 : [`python/cartograffect_predictive_engine.py`](../../python/cartograffect_predictive_engine.py) | Strate 1 : [`extensions/in_silico/src/cartograffect_sim/`](src/cartograffect_sim/) |
| :--- | :--- | :--- |
| **Fondement formel** | **Isomorphe exact v3.0.0** aux 8 modules normatifs Lean 4 (`Cartograffect/`, Options 1A, 2a, 3b, fondation `Z = 2`) | **Opérationnalisation probabiliste continue/discrète** sous Active Inference (`pymdp` / JAX / NumPyro) issue du banc exploratoire sur la grille annexe à 176 états |
| **Arithmétique** | **Arithmétique entière exacte (`ℤ`)** à facteur d'échelle fixe (`scale = 1 000`), zéro flottant critique | **Flottants IEEE 754 (`float32`/`float64`)**, tenseurs stochastiques et échantillonnage Monte-Carlo / MCMC |
| **Invariants certifiés** | Identité algébrique exacte `4 * scale^6`, budget $L_1$ `apportionRay`, dérive signée de Lyapunov sur `ℤ`, point fixe `(0,0,0)`, pas-à-pas strict 2a (`2 → 0`), brisure P2 Option 3b | Conservation géométrique sur la grille $L_1$, symétrie préalable du tenseur `B(Z=2)` ($\Delta_{\text{prior}} < 10^{-12}$), monotonie des concentrations de Dirichlet $\alpha(Z)$ |
| **Espace paramétrique** | Paramètres entiers `CircuitParams` $(\rho, \kappa, \delta_A, \delta_C, \gamma_A, \gamma_C, \chi, \epsilon)$ et état unifié $(R_t, Z_t, \tilde{\pi}_{A,t}, \tilde{\pi}_{C,t}, A_t)$ | Vecteur continu $\theta = (\tau_A, \tau_C, \lambda, \alpha_0, \gamma_\alpha, \eta_{\text{diss}}, \beta_X, \beta_Y)$ (+ $\delta_c$ transdiagnostique) |
| **Rôle scientifique** | **Référence de vérité formelle** et jumeau exécutable des **148 théorèmes substantiels / 169 déclarations** Lean 4 (**11 tests unitaires**) | **Banc d'essai génératif exploratoire (`V3 = 0`)** : tests de cohérence numérique/générative interne (Exp 1–3) et explorations synthétiques en quarantaine (Exp 4–5) |

> **Portée épistémique de P1–P5 (`V3 = 0`) :** Les cinq tests exécutés dans `experiments/01_falsifiable_predictions.py` (P1–P5) relèvent exclusivement de la **vérification numérique et générative interne *in silico*** (`V3 = 0`). En particulier, **P1** est explicitement qualifié de **test de cohérence numérique du projecteur budgétaire** (`apply_budget_constraint`), et P2–P5 de tests de cohérence générative interne du moteur `pymdp`. Ils **ne constituent pas une validation empirique sur sujets humains**, laquelle requiert des protocoles expérimentaux dédiés (EMA, comportemental, psychophysiologie). En outre, le simulateur `pymdp` conserve par principe d'économie le pavage exploratoire à 176 états hérité de v2.x ; sa refonte complète vers les Options 1A (`A ≥ 0`) et 3b (brisure Charge/Décharge) relève d'un chantier ultérieur.

---

## 2. Périmètre et Résultats Internes des Expériences *in silico* (`results/validation_summary.md`, `V3 = 0`)

### 2.1 Expérience 1 — Tests de cohérence numérique et générative interne ([`experiments/01_falsifiable_predictions.py`](experiments/01_falsifiable_predictions.py))
- **Ce qui est mesuré sur le simulateur interne ($N = 1\,000$ trajectoires / condition, `V3 = 0`, voir [`results/validation_summary.md`](results/validation_summary.md)) :**
  - **P1 (Test de cohérence numérique du projecteur budgétaire $L_1$, $Z=4$) :** Vérifie numériquement le comportement de l'opérateur implémenté `apply_budget_constraint` sous $\lambda = 1$ ($\text{Corr}(\Delta |X_t|, \Delta |Y_t|) = -0.7232$) contre $\lambda = 0$ ($+0.0481$, Wilcoxon $p = 3.33 \times 10^{-165}$, $d_z = -6.59$). Test de cohérence interne de la contrainte implémentée, et non validation empirique non circulaire.
  - **P2 (Instabilité axiale émergente en $Z=2$ sur le simulateur `pymdp`) :** Sous tenseur préalable $B(Z=2)$ symétrique ($\Delta_{\text{prior}} = 8.33 \times 10^{-17}$), temps de résidence axial inférieur au diagonal ($1.998$ vs $3.067$, Wilcoxon $p = 9.41 \times 10^{-159}$, $d_z = 1.35$) et flux $P(\text{Ax}\to\text{Diag}) = 0.3939 > P(\text{Diag}\to\text{Ax}) = 0.3197$ ($p = 1.79 \times 10^{-84}$, $d_z = 0.75$).
  - **P3 (Inertie hiérarchique) :** Croissance monotone de la demi-vie de rémission $t_{1/2}(Z=5) = 5.19 > t_{1/2}(Z=4) = 3.72 > t_{1/2}(Z=2) = 1.75$ ($p < 10^{-300}$) et de la rétention de vraisemblance Dirichlet ($0.9988 > 0.9978 > 0.9799$, $p < 10^{-300}$).
  - **P4 (Priorité lexicographique de $\text{sgn}(X_t)$ sur $\Delta \nabla A_t$) :** Dissociation interne sur les fenêtres transitoires du Bras A ($10\,362$ essais, Wilcoxon $p = 1.80 \times 10^{-219}$) et du Bras B ($2\,505$ essais, Wilcoxon $p = 2.69 \times 10^{-167}$).
  - **P5 (Médiation par $\hat{p}_{\text{ctrl}}$ de `Peur → Colère` vs `Dégoût`) :** Inversion de l'indice $P(\text{Colère}) - P(\text{Dégoût})$ de $-0.5806$ à $+0.0526$ ($p = 9.62 \times 10^{-250}$, $d = 2.13$) médiée par $\hat{p}_{\text{ctrl}}$ ($a \cdot b = 0.8037$, Sobel $z = 46.91$, $\rho_S = 0.8985$).
- **Limites documentées honnêtement :**
  - **Limite P4 :** La dissociation dans `TaskInferenceEngine` est circonscrite aux essais transitoires où $X_t < 0$ et $\Delta \nabla A_t > 0$.
  - **Limite P5 :** En régime de très forte volatilité et faible clarté ($v_{\text{rule}} = 0.35$, $\text{cue\_clarity} = 0.50$, $N = 200$), le couplage champ moyen maintient $\hat{p}_{\text{ctrl}} < 0.50$ sans croisement complet.
  - **Portée empirique (`V3 = 0`) :** Ces résultats ne testent que la cohérence interne du simulateur ; seule une confrontation sur données humaines indépendantes peut falsifier P1–P5.

### 2.2 Expérience 3 — Récupération de paramètres et de modèles ([`experiments/03_parameter_and_model_recovery.py`](experiments/03_parameter_and_model_recovery.py))
- **Statut épistémique (`V3 = 0`) :** Vérifie l'identifiabilité computationnelle interne du simulateur (`min r = 0.8915 >= 0.80`, couverture IC 95 % $\ge 0.904$, $\max \hat{R} = 1.010$ sous NUTS, $\text{PXP}_{\text{BIC}} = 1.0000$ face aux 3 modèles rivaux simulés sur $T = 280$ essais synthétiques, voir [`results/validation_summary.md`](results/validation_summary.md)). Conformément à l'arbitrage A4-Sanctuaire, aucune de ces métriques *in silico* n'est injectée dans le corps théorique de [`docs/01-Article_Cartograffect.md`](../../docs/01-Article_Cartograffect.md).

### 2.3 Expérience 2 (Phénotypes synthétiques) et Quarantaine des Expériences 4 & 5 (`exploratory_synthetic/`)
- **Fichier actif (Exp 2) :** [`experiments/02_clinical_phenotypes.py`](experiments/02_clinical_phenotypes.py) (4 profils pure-$\theta$ synthétiques).
- **Fichiers isolés en quarantaine (`SYNTHETIC EXPLORATORY ONLY — V3 = 0`) :** [`exploratory_synthetic/04_dsm5_phenotyping.py`](exploratory_synthetic/04_dsm5_phenotyping.py), [`exploratory_synthetic/05_dsm5_full_nosology.py`](exploratory_synthetic/05_dsm5_full_nosology.py), [`exploratory_synthetic/05_psychiatrie_computationnelle_dsm5_et_interventions.md`](exploratory_synthetic/05_psychiatrie_computationnelle_dsm5_et_interventions.md).
- **Statut épistémique :** Les cohortes DSM-5 / HiTOP reposent exclusivement sur des **priors paramétriques synthétiques** (aucune donnée patient humaine, `V3 = 0`) et ne sauraient être présentées comme validation clinique, diagnostique ou thérapeutique.

---

## 3. Reproductibilité FAIR4RS et Licences (v3.0.0)

- **Épinglage exact et lockfile :** Toutes les dépendances Python sont épinglées à la version exacte (`==`) dans [`pyproject.toml`](pyproject.toml) et [`requirements.txt`](requirements.txt), avec fichier de verrouillage reproductible [`uv.lock`](uv.lock).
- **Séparation physique des licences :** Code source Python sous **`AGPL-3.0-or-later`** ([`../../LICENSE`](../../LICENSE)), documentation et textes sous **`CC-BY-4.0`** ([`../../LICENSE-CC-BY-4.0.md`](../../LICENSE-CC-BY-4.0.md)).
