<!--
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
-->

# Rapport de Validation Formelle Croisée — TLA+ / TLC 2.19 (`tla/`)

## 1. Synthèse Exécutive

Ce dossier `tla/` fournit une **validation formelle croisée indépendante** de l'architecture **CARTOGRAFFECT** via **TLA+ (SANY 2.1 + TLC 2.19)** sur **Temurin Java 21.0.13**. Il complète les preuves déductives en théorie des types (Lean 4, Rocq 9.0, Agda 2.9), par contrat/Boogie (Dafny 4.11) et par réfutation SMT-LIB (Z3 5.3.3) par du **model checking explicite d'états finis et de propriétés temporelles LTL** (`[]`, `<>`, `~>`, équité faible `WF`).

- **Analyse syntaxique et sémantique SANY :** **14 / 14 modules `.tla`** validés sans erreur.
- **Théorèmes audités :** **113 / 113 prédicats `Thm_*`** vérifiés par TLC (`ASSUME` + `INVARIANT Inv_All113Theorems`) sans aucun `AXIOM`.
- **Blocs d'évaluation concrète :** **11 / 11 blocs (`EvalBlock01`..`EvalBlock11`)** vérifiés bit-à-bit (`INVARIANT Inv_All11EvalBlocks`).
- **Modèles temporels et de vivacité (LTL) :** **5 / 5 machines d'états TLC** vérifiées sans deadlock ni violation d'invariant ou de propriété temporelle.
- **Temps total d'exécution (`tla/verify.ps1`) :** **21,69 s**.

---

## 2. Architecture et Métriques des Modules (`tla/specs/`)

| # | Fichier `.tla` | Lignes | Rôle | Théorèmes (`Thm_*`) | Temps SANY |
|---:|:---|---:|:---|---:|---:|
| 01 | `PredictiveEngine.tla` | 184 | Polarités, régimes, couplages, boucles et `EngineStep` | 7 | 0,37 s |
| 02 | `CoreAffect.tla` | 199 | Géométrie $L_1$, `ApportionRay`, `ProjectToCoreAffect`, R5 & dissipation | 23 | 0,41 s |
| 03 | `AffectiveMatrix.tla` | 141 | Valence hédonique, antagoniste involutif, invariance de mapping R3 | 13 | 0,44 s |
| 04 | `AffectiveTaxonomy.tla` | 199 | 8 strates, 9 groupes, 17 sous-secteurs, pipeline terminal R4 | 10 | 0,45 s |
| 05 | `AffectiveDynamics.tla` | 184 | Noyau inter-strates `CanonicalDepthWeight` et attracteurs R1 | 10 (+ 4 lois) | 0,45 s |
| 06 | `Lexicon176.tla` | 237 | Table complète des 176 états affectifs ($Z = 0..7$) | 8 | 0,50 s |
| 07 | `PredictiveCircuit.tla` | 423 | 6 opérations, bijection $\Phi_{L_1}$, noyau $4 \cdot m^6$, loi unifiée | 41 | 0,48 s |
| 08 | `AuditTests.tla` (+ `.cfg`) | 339 | 113e théorème, conjonction des 113 théorèmes et 11 blocs d'évaluation | 1 (total 113) | 0,57 s |
| 09 | `Cartograffect.tla` | 10 | Module chapeau ré-exportant les 8 modules | — | 0,63 s |
| M1 | `Model_Dissipation.tla` (+ `.cfg`) | 18 | Convergence LTL universelle depuis les 176 états vers Veille `(0,0,0)` | Modèle LTL | 0,49 s |
| M2 | `Model_Engine.tla` (+ `.cfg`) | 25 | Progression de phase `EngineStep` et rémanence | Modèle LTL | 0,41 s |
| M3 | `Model_DepthKernel.tla` (+ `.cfg`) | 26 | Transitions inter-strates $Z = 1..5$ et équivariance antagoniste | Modèle LTL | 0,55 s |
| M4 | `Model_Circuit.tla` (+ `.cfg`) | 32 | Graphe markovien à 9 états et descente de Lyapunov en régime libre | Modèle LTL | 0,42 s |
| M5 | `Model_Unified.tla` (+ `.cfg`) | 39 | Dynamique fermée bornée $(c_t, R_t, Z_t)$ et hystérésis R5 | Modèle LTL | 0,47 s |
| **Total** | **14 modules `.tla` + 6 `.cfg`** | **2 056** | **0 `AXIOM`, 113 théorèmes, 11 blocs, 5 modèles temporels** | **113 / 113** | **6,64 s** |

---

## 3. Résultats du Model Checking TLC (6 Configurations)

| Modèle TLC | Configuration | États générés | États distincts | Invariants & Propriétés LTL vérifiés | Temps TLC |
|:---|:---|---:|---:|:---|---:|
| `AuditTests.tla` | `AuditTests.cfg` | 2 | 1 | `ASSUME`, `Inv_All113Theorems` (113/113), `Inv_All11EvalBlocks` (11/11) | 4,78 s |
| `Model_Dissipation.tla` | `Model_Dissipation.cfg` | 352 | 176 | `Inv_ValidCoreAffect`, `Inv_StratumBounded`, `[][z >= 2 => pt' # (0,0,1)]`, `[][pt # 0 => V(pt') < V(pt)]`, `<>(pt = (0,0,0))` | 2,30 s |
| `Model_Engine.tla` | `Model_Engine.cfg` | 16 | 11 | `Inv_ValidEngine`, `Inv_ValidProjection`, `Inv_RemanencePreserves`, `<>[](EngineStep(st) = st)` | 2,13 s |
| `Model_DepthKernel.tla` | `Model_DepthKernel.cfg` | 274 | 85 | `Inv_ValidStratumPoint`, `Inv_OutgoingPositive`, `Inv_AntagonistEquivariant`, `[][pt'.z >= pt.z]`, `<>(pt.z = 5)` | 2,39 s |
| `Model_Circuit.tla` | `Model_Circuit.cfg` | 107 | 18 | `Inv_ExactRowSum` ($4 \cdot m^6$), `Inv_CouplingValid`, `[][free => V(c') <= V(c)]`, `free ~> (c = (zero,zero))` | 1,56 s |
| `Model_Unified.tla` | `Model_Unified.cfg` | 17 325 | 1 916 | `Inv_ChargeBounded` ($R_t \le R_{\max}$), `Inv_StratumBounded` ($Z_t \le Z_{\max}$), `Inv_ProjectedValid`, `[][z >= 2 => z' # 1]`, `[][(z=2 /\ r' < \theta_{\text{down}}(2)) => z'=0]` | 1,72 s |

---

## 4. Traitement Exact de l'Arithmétique 32-bit de TLC (`4 * scale^6`)

L'évaluateur TLC représente le type `Int` en entier signé 32-bit (`[-2 147 483 648, 2 147 483 647]`). Or, pour le profil base-100 (`scale = 100`), la constante de normalisation exacte vaut $4 \cdot 100^6 = 4\,000\,000\,000\,000 > 2^{31}-1$.

Pour garantir une vérification **sans aucune perte de précision ni débordement 32-bit**, `PredictiveCircuit.tla` combine deux mécanismes complémentaires :
1. **Profil rationnellement équivalent exact `DefaultKernelParams20` (`scale = 20`) :** tous les paramètres du profil par défaut (`100, 80, 80, 0, 0, 70, 70, 15, 35, 35, 25`) étant divisibles par $5$, le profil réduit `÷ 5` (`20, 16, 16, 0, 0, 14, 14, 3, 7, 7, 5`) définit **exactement la même matrice de transition rationnelle $T$**, avec une somme de ligne entière $4 \cdot 20^6 = 256\,000\,000 < 2^{31}-1$ et un poids `CircuitWeight((Neg,Zero) -> (Neg,Pos)) = 6 496 000 = 101 500 000 000 / 5^6`.
2. **Arithmétique exacte big-int en base $10^6$ (`<<hi, lo>>` où $N = \text{hi} \cdot 10^6 + \text{lo}$) :** chaque poids marginal pour `scale = 100` étant borné par $2 \cdot 100^3 = 2\,000\,000 \ll 2^{31}-1$, les opérateurs `MulBig` et `AddBig` découpent les facteurs en base $10^3$ (intermédiaires $\le 4\,000\,000$) et certifient sur `DefaultKernelParams100` :
   - `CircuitRowSumBig(DefaultKernelParams100, (neg, zero)) = <<4000000, 0>>` ($= 4\,000\,000\,000\,000$)
   - `CircuitWeightBig(DefaultKernelParams100, (neg, zero), (neg, pos)) = <<101500, 0>>` ($= 101\,500\,000\,000$)

---

## 5. Correspondance des 113 Théorèmes Audités

| Module | Plage | Identifiants TLA+ (`Thm_<identifiant_lean>`) | Statut TLC |
|:---|:---:|:---|:---:|
| `PredictiveEngine.tla` | 1–7 | `Thm_polarity_invert_involutive`, `Thm_coupling_regime_partition`, `Thm_feedbackUpdate_couples_gradients`, `Thm_inferential_loop_covers_interfaces`, `Thm_feedbackUpdateWeighted_couples_precision`, `Thm_engineStep_remanence`, `Thm_engineStep_phase_progression` | `TRUE` |
| `CoreAffect.tla` | 8–30 | `Thm_engine_induces_valid_core_affect`, `Thm_z2_budget_conservation`, `Thm_axial_to_diagonal_reallocation`, `Thm_dissipationStep_valid`, `Thm_dissipationStep_fixed_iff`, `Thm_dissipation_strictly_decreases`, `Thm_remanence_preserves_state`, `Thm_cooperative_step_leaves_crown`, `Thm_deployCouplingWithPrecision_valid`, `Thm_neutral_coupling_without_suspension_yields_veille`, `Thm_neutral_or_subthreshold_with_suspension_yields_central`, `Thm_descending_suspension_yields_central_operator`, `Thm_central_z_ge2_requires_descending_suspension`, `Thm_deployCouplingWithPrecision_budget_conservation`, `Thm_dual_engaged_yields_diagonal_z2_precision`, `Thm_symmetric_precision_never_lateral`, `Thm_projectToCoreAffect_surjective`, `Thm_engineStep_canonical_trajectory`, `Thm_engineStep_surprise_to_crown`, `Thm_anticipation_short_circuits_to_veille`, `Thm_dissipation_from_ge2_never_visits_surprise`, `Thm_dissipationPotential_short_circuit_jump`, `Thm_dissipation_reaches_veille` | `TRUE` |
| `AffectiveMatrix.tla` | 31–43 | `Thm_hedonicPolarity_invert_involutive`, `Thm_x_positive_determines_positive_valence`, `Thm_x_negative_determines_negative_valence`, `Thm_antagonistPoint_preserves_validity`, `Thm_antagonistPoint_involutive`, `Thm_contralateral_swaps_amplitudes`, `Thm_antagonist_commutes_with_invert`, `Thm_antagonistPoint_unified`, `Thm_antagonist_preserves_validity_in`, `Thm_transferUnitYtoX_preserves_sum`, `Thm_antagonist_commutes_with_invert_precision`, `Thm_evaluateMatrix_core_antagonist_independent`, `Thm_mapping_independent_antagonist_invariants` | `TRUE` |
| `AffectiveTaxonomy.tla` | 44–53 | `Thm_inventory_176_certified`, `Thm_taxonomy_group_exhaustive`, `Thm_taxonomy_group_exclusive`, `Thm_dominantSector_iff_taxonomicGroup`, `Thm_contralateral_group_bindings`, `Thm_classifySubsector_correct`, `Thm_subsector_exclusive`, `Thm_classifySubsector_refines_group`, `Thm_classifySubsector_determines_valence`, `Thm_end_to_end_coherence` | `TRUE` |
| `AffectiveDynamics.tla` | 54–63 | `Thm_canonicalDepthKernel_reaches_crown`, `Thm_canonicalDepthKernel_reaches_lateral`, `Thm_lateral_reachable`, `Thm_lateral_reachable_from_surprise`, `Thm_canonicalDepthKernel_colere_bifurcates`, `Thm_canonicalDepthKernel_axial_instability_p2`, `Thm_canonicalDepthKernel_outgoingWeight_pos`, `Thm_classifyTaxonomicGroup_unique_maximizer`, `Thm_classifyTaxonomicGroup_maximizes_membership`, `Thm_lateral_has_overlapping_attractors` (+ `DepthKernelLawsOk`) | `TRUE` |
| `Lexicon176.tla` | 64–71 | `Thm_all176Entries_length`, `Thm_all176Entries_geometrically_valid`, `Thm_all176Entries_z_bounds`, `Thm_all176Entries_unique_points`, `Thm_all176Entries_complete`, `Thm_all176Entries_deterministically_reachable`, `Thm_all176Entries_reachable_by_engine`, `Thm_all176Entries_witness_check` | `TRUE` |
| `PredictiveCircuit.tla` | 72–112 | `Thm_circuit_covers_interfaces_both_sides`, `Thm_circuit_refines_inferential_ops`, `Thm_phiL1_left_inv`, `Thm_phiL1_right_inv`, `Thm_phiL1_agrees_with_deployZ2`, `Thm_crossingII_is_transpose_of_crossingI`, `Thm_routeToSubjective_injective`, `Thm_routeToPerceptive_injective`, `Thm_projectPerceptible_valid`, `Thm_projectPerceptible_z2_matches_phiL1`, `Thm_projectPerceptible_neutral_elevates_to_central`, `Thm_attentional_bottleneck_sum_active`, `Thm_circuitRowSum_exact`, `Thm_veille_absorbing_free`, `Thm_lyapunov_monotone_free`, `Thm_lyapunov_strict_descent_witness`, `Thm_lyapunov_expected_drift_constant`, `Thm_axial_peur_bifurcates_p2`, `Thm_veille_reaches_all_one_step`, `Thm_all_reach_veille_two_steps`, `Thm_veille_unreachable_when_eps_max`, `Thm_circularCycle_veille_fixed_point`, `Thm_circularCycle_reduces_total_discrepancy`, `Thm_lyapunov_drift_charge_with_passive_extinction`, `Thm_p1_without_p2_eps_independent`, `Thm_epistemic_rigidity_traps_charge_slice`, `Thm_pragmatic_helplessness_traps_charge_slice`, `Thm_perseveration_traps_discharge_free`, `Thm_passive_extinction_zero_relief`, `Thm_active_resolution_beats_passive_extinction`, `Thm_charge_accumulator_bounded`, `Thm_nextStratumR5_le_zMax`, `Thm_nextStratumR5_short_circuits_z2_to_veille`, `Thm_nextStratumR5_from_ge2_never_visits_surprise`, `Thm_symmetricSigmoid_sum`, `Thm_symmetricSigmoid_pos`, `Thm_symmetricSigmoid_neg`, `Thm_precisionShare_double_charge_cancels_alpha`, `Thm_projectUnifiedState_valid`, `Thm_projectUnifiedState_crown_budget`, `Thm_projectUnifiedState_reaches_lateral_consternation` | `TRUE` |
| `AuditTests.tla` | 113 | `Thm_all176Entries_antagonist_inverts_hedonic_polarity` | `TRUE` |

---

## 6. Parité Bit-à-Bit des 11 Blocs d'Évaluation Concrète (`EvalBlock01`..`EvalBlock11`)

| Bloc | Prédicat TLA+ | Valeur certifiée par TLC | Parité Lean 4 / Rocq 9 / Z3 / Dafny |
|:---:|:---|:---|:---:|
| 1 | `EvalBlock01` | `(0, 0, 0)`, `"Z0_pointDeVeille"`, `"operateurCentral"` | Exacte |
| 2 | `EvalBlock02` | `(0, 0, 1)`, `"Z1_saillancePerceptive"`, `"ascendingRupture"` | Exacte |
| 3 | `EvalBlock03` | `(-1, 1, 2)` / `(1, -1, 2)`, `"groupeColere"` / `"groupeCalme"`, `"ergotropicCompensation"`, `"negative"` | Exacte |
| 4 | `EvalBlock04` | Suspension `(0, 0, 2)` ; trajectoire `(0,0,0) -> (0,0,1) -> (0,0,2) -> (0,2,2)` | Exacte |
| 5 | `EvalBlock05` | `(0,0,2) -> (0,0,0)` (saut `4`) ; `(-1,3,3) -> (0,0,3) -> (0,0,2) -> (0,0,0)` | Exacte |
| 6 | `EvalBlock06` | Consternation `(-1, 3, 3)`, `"lateral"`, `"groupeJoie"`, `"lateralDefensiveUrgency"`, `"negative"`, antagoniste `(3, -1, 3)` | Exacte |
| 7 | `EvalBlock07` | Poids depuis Colère `(-1, 1, 2)` : `2, 1, 1`, `OutgoingWeight = 4`, antagoniste `1` | Exacte |
| 8 | `EvalBlock08` | Consternation `(4, 2, 1, "groupeJoie")` ; Envie `(6, 4, 2, "groupeJoie")` | Exacte |
| 9 | `EvalBlock09` | Mapping inversé R3 : `(-1, 1, 2)`, antagoniste `(1, -1, 2)`, valence `"negative" -> "positive"` | Exacte |
| 10 | `EvalBlock10` | `CrossingI = <<0, 2>>`, `II = <<2, 0>>`, `(-1, 3, 3)`, `<<4000000, 0>>` ($4\cdot 10^{12}$), `<<101500, 0>>` ($1,015\cdot 10^{11}$), `op3 = (0, 0, 0)` | Exacte |
| 11 | `EvalBlock11` | `acc = (700, 1300)`, `r5 = (0, 2)`, `pt = (-1, 3, 3)`, `shares = <<193, 807>>` | Exacte |

---

## 7. Reproduction Locale

```powershell
powershell -ExecutionPolicy Bypass -File "tla\verify.ps1"
```
