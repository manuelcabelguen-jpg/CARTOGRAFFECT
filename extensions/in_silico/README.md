# Cartograffect-simulation-in-silico

Traduction computationnelle de l'architecture formelle **CARTOGRAFFECT** (Strate 1 exploratoire, `V3 = 0`) en un modèle génératif probabiliste inversible (**POMDP hiérarchique sous inférence active** ; Friston et al., 2017 ; Parr et al., 2022) en vue de tests de cohérence numérique et générative interne *in silico*.

> **Statut épistémique & FAIR4RS (v3.0.0) :** Voir [`EPISTEMIC_STATUS.md`](EPISTEMIC_STATUS.md). Dépendances exactement épinglées (`==`) dans [`pyproject.toml`](pyproject.toml) et [`requirements.txt`](requirements.txt) avec verrouillage [`uv.lock`](uv.lock). Code source sous **`AGPL-3.0-or-later`** ([`../../LICENSE`](../../LICENSE)) ; documentation sous **`CC-BY-4.0`** ([`../../LICENSE-CC-BY-4.0.md`](../../LICENSE-CC-BY-4.0.md)).

---

## 1. Arborescence du projet

```text
Cartograffect-simulation-in-silico/
├── pyproject.toml                       # Configuration PEP 621, build setuptools et pytest
├── requirements.txt                     # Dépendances Python (numpy, scipy, jax, equinox, pymdp, numpyro, arviz)
├── README.md                            # Architecture, invariants formels et résumé de validation
├── run_all_validations.py               # Orchestrateur maître (Expériences 1, 2 et 3)
├── data/
│   └── lexicon_176.json                 # Lexique canonique certifié à 176 états affectifs
├── src/
│   └── cartograffect_sim/
│       ├── __init__.py                  # Exports publics du package
│       ├── predictive_engine.py         # Moteur de tâche pymdp (1 passe), gradients (∇A, ∇C), seuils (τ_A, τ_C) et matrice A (3 modalités)
│       ├── core_affect.py               # Espace discret 3D (X, Y, Z) à 176 états et loi budgétaire apply_budget_constraint
│       ├── affective_matrix.py          # POMDP affectif pymdp (176 états), tenseur B symétrique sur Z=2, dissipation η_eff(Z), transduction β_X > β_Y
│       ├── affective_taxonomy.py        # Partitions, sous-secteurs fonctionnels et taxonomie Lean 4
│       ├── lexicon_176.py               # Chargement et requêtes du lexique canonique à 176 points
│       ├── generative_process.py        # Environnement orthogonal NonStationaryBanditEnv (sensory_payload sans fuite)
│       └── recovery.py                  # Pipelines NumPyro / ArviZ (SVI vectorisé + NUTS reparamétré centré, BIC/WAIC, pxp Rigoux 2014)
├── experiments/
│   ├── 01_falsifiable_predictions.py    # Expérience 1 : P1 (arbitrage L1), P2 (instabilité axiale émergente), P3 (inertie POMDP JAX)
│   ├── 02_clinical_phenotypes.py        # Expérience 2 : 4 phénotypes pure-θ sur protocole unifié (N=20 appariés, Holm-Bonferroni)
│   └── 03_parameter_and_model_recovery.py # Expérience 3 : Parameter Recovery (M=500, 10 NUTS) & Model Recovery (4×100)
├── results/                             # Figures 300 DPI, tableaux CSV, JSON et validation_summary.md
└── tests/
    ├── conftest.py                      # Ajout automatique de src/ au sys.path
    ├── test_lean_isomorphism.py         # 25 théorèmes et invariants isomorphes à Lean 4
    ├── test_active_inference_integration.py # Intégration pymdp, 0 double-comptage, 0 fuite, session 400 essais
    └── test_recovery_and_experiments.py # Non-régression recovery, symétrie B(Z=2) et smoke tests expériences
```

---

## 2. Architecture computationnelle et principes d'audit

- **Moteur d'inférence active unifié (`predictive_engine.py`, `affective_matrix.py`)** :
  - **Niveau 1 (`TaskInferenceEngine`)** : agent POMDP `pymdp` à observations catégorielles avec masquage `[1/3, 1/3, 1/3]` garantissant une inférence pré-choix sur l'indice seul suivie d'une transition `B` unique post-issue (zéro double-comptage), détection purement sensorielle du calme (aucun accès aux attributs cachés `is_remission` ou `d_obj` via `TrialObservation.sensory_payload()`).
  - **Niveau 2 (`AffectivePOMDPEngine`)** : POMDP canonique à **176 états**, **3 modalités EMA non redondantes** `(obs_A[3], obs_C[3], persistence_level[4])`, tenseur de transition `B` sans aucun biais axial/diagonal a priori sur `Z=2` (`λ = 1`), taux effectif de dissipation $\eta_{\text{eff}}(Z) = \operatorname{clip}(\eta_{\text{diss}} / (1 + 0.18\,\alpha_z), 0.005, 1)$ et apprentissage Dirichlet exact `pA`/`pB` en une passe.
- **Inférence bayésienne (`recovery.py`)** :
  - Simulation en boucle fermée réelle sur `NonStationaryBanditEnv` (où `PROBE_CUE` clarifie effectivement `cue_{t+1}`), zéro lecture de `is_remission`/`d_obj` dans la vraisemblance, projection budgétaire symétrique `apply_budget_constraint`, reparamétrisation centrée (`log_alpha_mid` à $z_{\text{ref}} = 3.5$ et $\beta_X = \beta_Y + \Delta\beta$), BIC calculé sur $\max \log L$ et le nombre exact d'observations scalaires actives.

---

## 3. Résultats de la vérification de cohérence *in silico* (`py run_all_validations.py`, `V3 = 0`)

Tous les **24 critères internes** passent (`ALL_CRITERIA_PASSED: True`, durée totale `1176.61 s`) ; voir [results/validation_summary.md](results/validation_summary.md) :

1. **Expérience 1 — Tests de cohérence *in silico* ($N = 1\,000$ / condition, `V3 = 0`) :**
   - **P1 (Test de cohérence numérique du projecteur budgétaire $L_1$, $Z=4$) :** demandes orthogonales avant contrainte, donnant après application explicite de `apply_budget_constraint` $r(\lambda=1) = -0.7232$ vs $r(\lambda=0) = 0.0481$ ($p_{\text{Wilcoxon}} = 3.33 \times 10^{-165}$, $d_z = -6.59$).
   - **P2 (Instabilité axiale émergente, $Z=2$) :** symétrie préalable stricte dans $B(Z=2)$ ($\Delta_{\text{prior}} = 8.33 \times 10^{-17}$), temps de résidence $\tau_{\text{ax}} = 1.998 < \tau_{\text{diag}} = 3.067$ pas ($p = 9.41 \times 10^{-159}$) et $P(\text{Ax}\to\text{Diag}) = 0.3939 > P(\text{Diag}\to\text{Ax}) = 0.3197$ ($p = 1.79 \times 10^{-84}$), avec bascule directe entre pôles opposés $\le 0.0400$.
   - **P3 (Inertie hiérarchique) :** demi-vie de dissipation $t_{1/2}(Z=2)=1.75 < t_{1/2}(Z=4)=3.72 < t_{1/2}(Z=5)=5.19$ et résistance Dirichlet aux évidences contraires strictement croissante ($0.9799 < 0.9978 < 0.9988$, $p < 10^{-300}$).
   - **P4 & P5 :** dissociation lexicographique de la valence ($10\,362$ essais Bras A, $2\,505$ essais Bras B, $p < 10^{-166}$) et médiation par $\hat{p}_{\text{ctrl}}$ de `Peur → Colère` vs `Dégoût` ($a \cdot b = 0.8037$, Sobel $z = 46.91$).
2. **Expérience 2 — Phénotypes cliniques pure-$\theta$ ($N = 20$ graines appariées, protocole unifié) :**
   - Seuls les 8 paramètres $\theta$ varient (`pure_theta_only = True`).
   - Toutes les dissociations cliniques (piégeage en rémission de `b_inhibited`, dominance ergotropique $(-X,+Y)$ de `c_agitated`, verrouillage $X=0$ de `d_rigid_bias` avec `0` visite sur *Infini* `(0,+12,7)`) sont significatives par Wilcoxon apparié bilatéral après correction Holm-Bonferroni ($p_{\text{Holm}} \in [1.53 \times 10^{-5},\, 9.99 \times 10^{-3}]$, $r_{rb} \in [0.657,\, 1.000]$).
3. **Expérience 3 — Parameter & Model Recovery (NumPyro SVI + 10 NUTS) :**
   - **Parameter Recovery ($M = 500$, $T = 280$) :** $r \in [0.8915,\, 0.9958]$ ($\min r = 0.8915 \ge 0.80$), couverture IC 95 % $\in [90.4\%,\, 95.4\%]$ ($\ge 85\%$), validation croisée NUTS sur 10 jeux ($\max \hat{R} = 1.010 < 1.02$, $\min \text{ESS} = 804.7 \ge 400$).
   - **Model Recovery ($4 \times 100$) :** récupération diagonale BIC (max LL) = `1.000` sur les 4 modèles ($M_1 \dots M_4$), $\min pxp_{\text{BIC}} = 1.0000 > 0.95$ et $\min pxp_{\text{WAIC}} = 1.0000$.

---

## 4. Installation et exécution

```bash
# Installation des dépendances
pip install -r requirements.txt

# Ou installation éditable avec dépendances de développement
pip install -e .[dev]

# Exécution de la suite complète de tests (50 tests : 25 Lean 4 + 25 intégration / non-régression)
py -m pytest -v

# Exécution complète de la validation in silico (Expériences 1, 2 et 3)
py run_all_validations.py
```

---

## 5. Références

- Friston, K., FitzGerald, T., Rigoli, F., Schwartenbeck, P., & Pezzulo, G. (2017). Active Inference: A Process Theory. *Neural Computation*, 29(1), 1–49.
- Heins, C., Millidge, B., Demekas, D., Klein, B., Friston, K., Couzin, I. D., & Tschantz, A. (2022). pymdp: A Python library for active inference in discrete state spaces. *Journal of Open Source Software*, 7(73), 4098.
- Hesp, C., Smith, R., Parr, T., Allen, M., Friston, K. J., & Ramstead, M. J. (2021). Deeply Felt Affect: The Emergence of Valence in Deep Active Inference. *Neural Computation*, 33(2), 398–446.
- Parr, T., Pezzulo, G., & Friston, K. J. (2022). *Active Inference: The Free Energy Principle in Mind, Brain, and Behavior*. MIT Press.
- Rigoux, L., Stephan, K. E., Friston, K. J., & Daunizeau, J. (2014). Bayesian model selection for group studies — Revisited. *NeuroImage*, 84, 971–985.
