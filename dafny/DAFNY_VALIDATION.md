<!--
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
-->

# Rapport de Validation Formelle Croisée — Dafny 4.11.0 (`dafny/`)

## 1. Synthèse Exécutive

Ce dossier `dafny/` fournit une **validation formelle croisée indépendante** de l'architecture **CARTOGRAFFECT** via le vérificateur déductif par contrat **Dafny 4.11.0** (traduction vers **Boogie** et décharge d'obligations de preuve SMT).

- **Vérification formelle complète (`dafny verify dfyconfig.toml`) :** **2 113 obligations de preuve vérifiées, 0 erreur, 0 timeout**.
- **Théorèmes audités :** **113 / 113 lemmes certifiés** (`7 + 23 + 13 + 10 + 10 + 8 + 41 + 1`), portant exactement les mêmes identifiants que `Cartograffect/*.lean` et `rocq/theories/*.v`.
- **Intégrité statique :** **0 `assume`**, **0 `{:axiom}`**, **0 `{:verify false}`**, **0 `{:extern}`**.
- **Parité d'exécution concrète (`dafny run --target:py --no-verify src/AuditTests.dfy`) :** **11 / 11 blocs (`B1:`..`B11:`)** exécutés avec assertions `expect` à l'exécution et parité bit-à-bit avec Lean 4, Rocq 9.0, SMT Z3 et TLA+ TLC.

---

## 2. Architecture et Métriques des Modules (`dafny/src/`)

| # | Fichier `.dfy` | Lignes | Rôle | Théorèmes audités | Lemmes totaux | Statut Dafny |
|---:|:---|---:|:---|---:|---:|:---:|
| 01 | `PredictiveEngine.dfy` | 351 | Polarités, régimes, couplages, boucles inférentielles et `EngineStep` | 7 | 11 | Vérifié (0 erreur) |
| 02 | `CoreAffect.dfy` | 560 | Géométrie $L_1$, `ApportionRay`, `ProjectToCoreAffect`, R5 et dissipation | 23 | 42 | Vérifié (0 erreur) |
| 03 | `AffectiveMatrix.dfy` | 308 | Valence hédonique, antagoniste involutif, invariance de mapping R3 | 13 | 19 | Vérifié (0 erreur) |
| 04 | `AffectiveTaxonomy.dfy` | 367 | 8 strates, 9 groupes, 17 sous-secteurs, cohérence terminale R4 | 10 | 14 | Vérifié (0 erreur) |
| 05 | `AffectiveDynamics.dfy` | 419 | Noyau stochastique inter-strates `CanonicalDepthWeight` et attracteurs R1 | 10 (+ 4 lois) | 28 | Vérifié (0 erreur) |
| 06 | `Lexicon176.dfy` | 3 221 | Table complète des 176 états ($Z=0..7$), arbres binaires équilibrés et bijection | 8 | 25 | Vérifié (0 erreur) |
| 07 | `PredictiveCircuit.dfy` | 1 244 | 6 opérations, bijection $\Phi_{L_1}$, noyau $4 \cdot m^6$, loi unifiée $(R_t, Z_t, \pi_A, \pi_C)$ | 41 | 62 | Vérifié (0 erreur) |
| 08 | `AuditTests.dfy` | 219 | 113e théorème et méthodes d'exécution `CheckBlock1()`..`CheckBlock11()` + `Main()` | 1 | 1 | Vérifié (0 erreur) |
| 09 | `Cartograffect.dfy` | 23 | Module chapeau ré-exportant les 8 modules | — | — | Vérifié (0 erreur) |
| **Total** | **9 fichiers `.dfy`** | **6 712** | **2 113 obligations de preuve vérifiées, 0 erreur** | **113 / 113** | **202** | **100 % Vérifié** |

---

## 3. Choix d'Ingénierie de Preuve en Dafny 4.11

1. **Types raffinés (`subset types`) avec témoins constructifs :**
   - `SalientDiscrepancy`, `CoreAffectState`, `CircuitKernelParams`, `CircularCircuitState` et `UnifiedDynamicsParams` sont définis comme sous-types raffinés munis de clauses `witness` explicites.
2. **Arbres de décision binaires équilibrés et étiquettes opaques dans `Lexicon176.dfy` :**
   - Les 176 étiquettes françaises UTF-8 sont encapsulées dans `opaque function LabelsZ0()..LabelsZ7()` (évitant de saturer le solveur SMT avec ~2 000 axiomes de séquences de caractères), tandis que `PointZ0..PointZ7` et `IndexInZ0..IndexInZ7` sont structurés en arbres binaires équilibrés de profondeur $\le 6$.
   - L'unicité globale des 176 coordonnées (`all176Entries_unique_points`) est prouvée algébriquement en $O(1)$ par inversion à gauche (`IndexInZk(PointZk(i).x, PointZk(i).y) == i`) et séparation des strates `.z == k`.
3. **Isolation des assertions non-linéaires (`{:isolate_assertions}` et `opaque function MarginalWeight`) :**
   - Le théorème polynomial de degré 6 `circuitRowSum_exact` ($\sum_{\text{dst}} W(\text{src}, \text{dst}) = 4 \cdot \text{scale}^6$) se factorise via `MarginalWeightSum`, `SumCircuitWeightsUnroll`, `SumNineOuter` et `FactorSquareProd` sans déplier `MarginalWeight`.
   - La borne invariante de l'accumulateur de charge `charge_accumulator_bounded` ($R_{t+1} \le \lfloor s^2 / (s - \lambda) \rfloor$) est certifiée via la propriété de division euclidienne `ChargeDecayStepBound`.

---

## 4. Correspondance des 113 Théorèmes Audités

| Module | Plage | Lemmes Dafny certifiés | Obligations |
|:---|:---:|:---|---:|
| `PredictiveEngine.dfy` | 1–7 | `Polarity_invert_involutive`, `coupling_regime_partition`, `feedbackUpdate_couples_gradients`, `inferential_loop_covers_interfaces`, `feedbackUpdateWeighted_couples_precision`, `engineStep_remanence`, `engineStep_phase_progression` | 36 |
| `CoreAffect.dfy` | 8–30 | `engine_induces_valid_core_affect`, `z2_budget_conservation`, `axial_to_diagonal_reallocation`, `dissipationStep_valid`, `dissipationStep_fixed_iff`, `dissipation_strictly_decreases`, `remanence_preserves_state`, `cooperative_step_leaves_crown`, `deployCouplingWithPrecision_valid`, `neutral_coupling_without_suspension_yields_veille`, `neutral_or_subthreshold_with_suspension_yields_central`, `descending_suspension_yields_central_operator`, `central_z_ge2_requires_descending_suspension`, `deployCouplingWithPrecision_budget_conservation`, `dual_engaged_yields_diagonal_z2_precision`, `symmetric_precision_never_lateral`, `projectToCoreAffect_surjective`, `engineStep_canonical_trajectory`, `engineStep_surprise_to_crown`, `anticipation_short_circuits_to_veille`, `dissipation_from_ge2_never_visits_surprise`, `dissipationPotential_short_circuit_jump`, `dissipation_reaches_veille` | 64 |
| `AffectiveMatrix.dfy` | 31–43 | `HedonicPolarity_invert_involutive`, `x_positive_determines_positive_valence`, `x_negative_determines_negative_valence`, `antagonistPoint_preserves_validity`, `antagonistPoint_involutive`, `contralateral_swaps_amplitudes`, `antagonist_commutes_with_invert`, `antagonistPoint_unified`, `antagonist_preserves_validity_in`, `transferUnitYtoX_preserves_sum`, `antagonist_commutes_with_invert_precision`, `evaluateMatrix_core_antagonist_independent`, `mapping_independent_antagonist_invariants` | 48 |
| `AffectiveTaxonomy.dfy` | 44–53 | `inventory_176_certified`, `taxonomy_group_exhaustive`, `taxonomy_group_exclusive`, `dominantSector_iff_taxonomicGroup`, `contralateral_group_bindings`, `classifySubsector_correct`, `subsector_exclusive`, `classifySubsector_refines_group`, `classifySubsector_determines_valence`, `end_to_end_coherence` | 22 |
| `AffectiveDynamics.dfy` | 54–63 | `canonicalDepthKernel_reaches_crown`, `canonicalDepthKernel_reaches_lateral`, `lateral_reachable`, `lateral_reachable_from_surprise`, `canonicalDepthKernel_colere_bifurcates`, `canonicalDepthKernel_axial_instability_p2`, `canonicalDepthKernel_outgoingWeight_pos`, `classifyTaxonomicGroup_unique_maximizer`, `classifyTaxonomicGroup_maximizes_membership`, `lateral_has_overlapping_attractors` (+ 4 lois `canonicalDepthKernel_*`) | 44 |
| `Lexicon176.dfy` | 64–71 | `all176Entries_length`, `all176Entries_geometrically_valid`, `all176Entries_z_bounds`, `all176Entries_unique_points`, `all176Entries_complete`, `all176Entries_deterministically_reachable`, `all176Entries_reachable_by_engine`, `all176Entries_witness_check` | 1 543 |
| `PredictiveCircuit.dfy` | 72–112 | `circuit_covers_interfaces_both_sides`, `circuit_refines_inferential_ops`, `phiL1_left_inv`, `phiL1_right_inv`, `phiL1_agrees_with_deployZ2`, `crossingII_is_transpose_of_crossingI`, `routeToSubjective_injective`, `routeToPerceptive_injective`, `projectPerceptible_valid`, `projectPerceptible_z2_matches_phiL1`, `projectPerceptible_neutral_elevates_to_central`, `attentional_bottleneck_sum_active`, `circuitRowSum_exact`, `veille_absorbing_free`, `lyapunov_monotone_free`, `lyapunov_strict_descent_witness`, `lyapunov_expected_drift_constant`, `axial_peur_bifurcates_p2`, `veille_reaches_all_one_step`, `all_reach_veille_two_steps`, `veille_unreachable_when_eps_max`, `circularCycle_veille_fixed_point`, `circularCycle_reduces_total_discrepancy`, `lyapunov_drift_charge_with_passive_extinction`, `p1_without_p2_eps_independent`, `epistemic_rigidity_traps_charge_slice`, `pragmatic_helplessness_traps_charge_slice`, `perseveration_traps_discharge_free`, `passive_extinction_zero_relief`, `active_resolution_beats_passive_extinction`, `charge_accumulator_bounded`, `nextStratumR5_le_zMax`, `nextStratumR5_short_circuits_z2_to_veille`, `nextStratumR5_from_ge2_never_visits_surprise`, `symmetricSigmoid_sum`, `symmetricSigmoid_pos`, `symmetricSigmoid_neg`, `precisionShare_double_charge_cancels_alpha`, `projectUnifiedState_valid`, `projectUnifiedState_crown_budget`, `projectUnifiedState_reaches_lateral_consternation` | 337 |
| `AuditTests.dfy` | 113 | `all176Entries_antagonist_inverts_hedonic_polarity` (+ `CheckBlock1`..`CheckBlock11`, `Main`) | 19 |
| **Total** | **1–113** | **113 théorèmes audités (0 erreur, 0 timeout)** | **2 113** |

---

## 5. Parité Bit-à-Bit des 11 Blocs d'Évaluation Concrète (`--target:py`)

| Bloc | Méthode Dafny | Sortie exécutée (`dafny run --target:py src/AuditTests.dfy`) | Parité Lean 4 / Rocq 9 / Z3 / TLA+ |
|:---:|:---|:---|:---:|
| 1 | `CheckBlock1()` | `B1:CoreAffectPoint(0, 0, 0) Z0_pointDeVeille OperateurCentral` | Exacte |
| 2 | `CheckBlock2()` | `B2:CoreAffectPoint(0, 0, 1) Z1_saillancePerceptive AscendingRupture` | Exacte |
| 3 | `CheckBlock3()` | `B3:CoreAffectPoint(-1, 1, 2) CoreAffectPoint(1, -1, 2) GroupeColere DiagonalAnger GroupeCalme DiagonalCalm ErgotropicCompensation HedNegative` | Exacte |
| 4 | `CheckBlock4()` | `B4:CoreAffectPoint(0, 0, 0)->CoreAffectPoint(0, 0, 1)->CoreAffectPoint(0, 0, 2)->CoreAffectPoint(0, 2, 2)` | Exacte |
| 5 | `CheckBlock5()` | `B5:CoreAffectPoint(0, 0, 0) jump=4 CoreAffectPoint(0, 0, 3)->CoreAffectPoint(0, 0, 2)->CoreAffectPoint(0, 0, 0)` | Exacte |
| 6 | `CheckBlock6()` | `B6:CoreAffectPoint(-1, 3, 3) Lateral GroupeJoie LateralDefensiveUrgency HedNegative CoreAffectPoint(3, -1, 3)` | Exacte |
| 7 | `CheckBlock7()` | `B7:2,1,1 out=4 ant=1` | Exacte |
| 8 | `CheckBlock8()` | `B8:C=(4,2,1,GroupeJoie) E=(6,4,2,GroupeJoie)` | Exacte |
| 9 | `CheckBlock9()` | `B9:CoreAffectPoint(-1, 1, 2) CoreAffectPoint(1, -1, 2) HedNegative->HedPositive` | Exacte |
| 10 | `CheckBlock10()` | `B10:(0, 2) (2, 0) CoreAffectPoint(-1, 3, 3) sum=4000000000000 w=101500000000 op3=CoreAffectPoint(0, 0, 0)` | Exacte |
| 11 | `CheckBlock11()` | `B11:acc=(700,1300) r5=(0,2) pt=CoreAffectPoint(-1, 3, 3) sh=(193, 807)` | Exacte |

---

## 6. Reproduction Locale

```powershell
powershell -ExecutionPolicy Bypass -File "dafny\verify.ps1"
```
