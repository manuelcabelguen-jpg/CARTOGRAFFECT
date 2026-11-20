# Rapport de validation *in silico* — CARTOGRAFFECT

- **Horodatage (UTC) :** `2026-11-19T13:29:37.912820+00:00`
- **Durée totale :** `751.86 s` (Exp 1 : `17.52 s`, Exp 2 : `341.02 s`, Exp 3 : `389.23 s`)
- **Statut global :** `SUCCÈS COMPLET`

## 1. Expérience 1 — Prédictions falsifiables Monte-Carlo (non circulaire)

*(N = 1000 trajectoires par condition ; symétrie préalable `B(Z=2)` : `Δ_prior = 8.33e-17`, bascule pôles opposés max = `0.0375`)*

| Prédiction | Condition / Comparaison | Valeur principale | Comparateur | Statistique / p-value |
| :--- | :--- | :---: | :---: | :--- |
| **P1 — Arbitrage $L_1$** ($Z=4$) | Corr. $(\Delta|X_t|, \Delta|Y_t|)$ : $\lambda=1$ vs $\lambda=0$ | `-0.7232` | `0.0481` | $p = 3.33e-165$ (paired t: `< 1e-300`), $d_z = -6.59$ |
| **P2 — Résidence axiale** ($Z=2$) | Temps moyen Axial vs Diagonal | `1.986` | `3.078` | $p = 1.02e-162$, $d_z = 1.59$ |
| **P2 — Asymétrie de transition** | $P(\text{Ax}\to\text{Diag})$ vs $P(\text{Diag}\to\text{Ax})$ | `0.3968` | `0.3151` | $p = 5.72e-106$, $d_z = 0.91$ |
| **P3 — Demi-vie hiérarchique** | $t_{1/2}(Z=4)$ vs $t_{1/2}(Z=2)$ | `3.72` | `1.75` | $p = < 1e-300$, $d = 4.80$ |
| **P3 — Demi-vie hiérarchique** | $t_{1/2}(Z=5)$ vs $t_{1/2}(Z=2)$ | `5.19` | `1.75` | $p = < 1e-300$, $d = 8.32$ |
| **P3 — Résistance Dirichlet** | Rétention vraisemblance $Z=5$ vs $Z=2$ | `0.9988` | `0.9799` | $p = < 1e-300$, $d = 7.48$ |

## 2. Expérience 2 — Phénotypes cliniques comparés (pure-θ, protocole unifié)

*(N = 20 graines appariées / phénotype ; `pure_theta_only = True`)*

| Phénotype | $Z$ en rémission (moy. ± ET) | Retour `PdV` rém. | Quadrant $(-X,-Y)$ perte | Quadrant $(-X,+Y)$ menace | Verrouillage $X=0$ (stresseurs) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| `a_normothymic` | `1.05 ± 0.54` | `0.731` | `0.704` | `0.363` | `0.240` |
| `b_inhibited` | `5.54 ± 0.36` | `0.000` | `0.797` | `0.395` | `0.146` |
| `c_agitated` | `3.00 ± 0.37` | `0.179` | `0.771` | `0.716` | `0.154` |
| `d_rigid_bias` | `0.62 ± 0.15` | `0.825` | `0.280` | `0.140` | `0.665` |

| Hypothèse (Wilcoxon apparié bilatéral + Holm-Bonferroni) | Médiane A vs B | $p_{\text{brut}}$ | $p_{\text{Holm}}$ | Rang-bisérial $r_{rb}$ |
| :--- | :---: | :---: | :---: | :---: |
| `inhibited_vs_normo_z_remission` | `5.625` vs `0.790` | `1.91e-06` | `1.53e-05` | `1.000` |
| `inhibited_vs_normo_pdv_remission` | `0.785` vs `0.000` | `8.71e-05` | `5.22e-04` | `1.000` |
| `inhibited_vs_normo_neg_neg_loss` | `0.814` vs `0.729` | `2.88e-03` | `5.76e-03` | `0.779` |
| `agitated_vs_normo_neg_pos_threat` | `0.729` vs `0.350` | `8.83e-05` | `5.22e-04` | `1.000` |
| `agitated_vs_inhibited_neg_pos_threat` | `0.729` vs `0.421` | `1.20e-04` | `5.22e-04` | `0.981` |
| `agitated_vs_normo_oscillation` | `0.106` vs `0.077` | `9.99e-03` | `9.99e-03` | `0.657` |
| `rigid_vs_normo_x_zero_lock` | `0.796` vs `0.556` | `8.83e-05` | `5.22e-04` | `1.000` |
| `rigid_vs_normo_x_zero_stress` | `0.682` vs `0.211` | `1.91e-06` | `1.53e-05` | `1.000` |

- **Attracteurs (cohorte unifiée) :** `b_inhibited` atteint $Z\geq 5$ en $(-X,-Y)$ sur `20/20` graines ; `d_rigid_bias` enregistre `0` visites sur *Infini* `(0,+12,7)`.

## 3. Expérience 3 — Parameter & Model Recovery (NumPyro SVI + NUTS)

*(Parameter Recovery : M = 500 ; Model Recovery : 4 × 100, T = 280 essais)*

| Paramètre | Pearson $r$ | RMSE | Couverture IC 95 % |
| :--- | :---: | :---: | :---: |
| `tau_A` | `0.9829` | `0.0215` | `0.912` |
| `tau_C` | `0.9878` | `0.0178` | `0.950` |
| `lambda` | `0.9958` | `0.0223` | `0.904` |
| `alpha_0` | `0.9049` | `0.2711` | `0.936` |
| `gamma_alpha` | `0.9252` | `0.0696` | `0.944` |
| `eta_diss` | `0.9653` | `0.0388` | `0.946` |
| `beta_X` | `0.8915` | `0.3353` | `0.920` |
| `beta_Y` | `0.9492` | `0.1090` | `0.954` |

- **$r$ minimal sur $\theta$ :** `0.8915` (critère $\ge 0.80$ : `True`)
- **Couverture IC 95 % minimale :** `0.904` (critère $\ge 0.85$)
- **Corrélation hors-diagonale max ($\theta^*$ vs $\hat{\theta}$) :** `0.4650`
- **Corrélation d'erreur max ($\hat{\theta} - \theta^*$) :** `0.8130`
- **Contrôle MCMC NUTS (10 jeux) :** `max R-hat = 1.010`, `min ESS = 804.7`

| Modèle générateur | $pxp$ (BIC) | $pxp$ (WAIC) | Récup. BIC (max LL) | Récup. WAIC |
| :--- | :---: | :---: | :---: | :---: |
| `M1_CARTOGRAFFECT` | `1.0000` | `1.0000` | `1.000` | `1.000` |
| `M2_NoBudget_Lam0` | `1.0000` | `1.0000` | `1.000` | `0.840` |
| `M3_NoThresholds` | `1.0000` | `1.0000` | `1.000` | `0.990` |
| `M4_ScalarValence_1D` | `1.0000` | `1.0000` | `1.000` | `1.000` |

- **$pxp$ minimal sur la diagonale (BIC) :** `1.0000` (critère $> 0.95$ : `True`)

## 4. Critères de validation

- `[PASS]` `exp01_p1_negative_budget_corr`
- `[PASS]` `exp01_p1_cooperative_orthogonal`
- `[PASS]` `exp01_p2_b_prior_symmetric`
- `[PASS]` `exp01_p2_axial_shorter_residence`
- `[PASS]` `exp01_p2_axial_to_diag_gt_reverse`
- `[PASS]` `exp01_p2_opposite_pole_low`
- `[PASS]` `exp01_p3_halflife_z5_gt_z4_gt_z2`
- `[PASS]` `exp01_p3_resistance_z5_gt_z4_gt_z2`
- `[PASS]` `exp02_pure_theta_only`
- `[PASS]` `exp02_inhibited_remission_trapping`
- `[PASS]` `exp02_agitated_neg_pos_oscillation`
- `[PASS]` `exp02_rigid_x_zero_lock`
- `[PASS]` `exp03_parameter_recovery_r_ge_080`
- `[PASS]` `exp03_parameter_coverage_ge_085`
- `[PASS]` `exp03_parameter_no_critical_collinearity`
- `[PASS]` `exp03_nuts_rhat_lt_102`
- `[PASS]` `exp03_nuts_ess_ge_400`
- `[PASS]` `exp03_model_recovery_diag_pxp_gt_095`
