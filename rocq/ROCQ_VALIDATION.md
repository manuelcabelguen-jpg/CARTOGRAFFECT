# ROCQ_VALIDATION — Validation croisée formelle isolée (The Rocq Prover 9.1.0)

**Projet :** CARTOGRAFFECT — *Cartographie des affects*  
**Date :** 2026-11-19  
**Statut :** ✅ **CERTIFIÉ (113 / 113 théorèmes `Closed under the global context`, 0 axiome, 0 `Admitted`)**

---

## 1. Garantie d'isolation stricte par rapport à Lean 4

Conformément à l'exigence d'isolation totale :

- L'intégralité de la validation Rocq (configuration `_CoqProject`, `.gitignore` dédié, 9 modules `.v`, script autonome `verify.ps1`, rapport `ROCQ_VALIDATION.md`) est confinée dans [`rocq/`](.) :
  - [`rocq/.gitignore`](.gitignore)
  - [`rocq/_CoqProject`](_CoqProject)
  - [`rocq/verify.ps1`](verify.ps1)
  - [`rocq/theories/`](theories/)
- **Aucun fichier** de la formalisation Lean 4 (`Cartograffect/*.lean`, `Cartograffect.lean`, `lakefile.lean`, `lean-toolchain`, `.github/workflows/lean.yml`, `.gitignore` racine, `README.md`, `AUDIT_REPORT.md`) ni du code Python n'a été modifié, déplacé ou supprimé.
- Le contrôle non-régression `git status --short` montre uniquement l'ajout de `rocq/`, et `lake build` complète toujours avec succès (**11 jobs**, 0 erreur).

---

## 2. Environnement et double vérification mécanique

| Composant / Contrôle | Résultat observé |
|---|---|
| Prouveur | **The Rocq Prover, version 9.1.0** (`compiled with OCaml 4.14.2`) |
| Bibliothèque utilisée | **`From Stdlib` uniquement** (`Bool`, `Arith`, `PeanoNat`, `NArith`, `ZArith`, `Lia`, `String`, `List`, `Eqdep_dec`) — **0 dépendance externe** |
| Options de compilation | `rocq compile -q -w +default -Q theories CartograffectRocq <fichier.v>` (tous les avertissements par défaut traités strictement : **0 erreur, 0 avertissement**) |
| Mots-clés interdits | Scan syntaxique après suppression des commentaires imbriqués `(* ... *)` et chaînes : **0** occurrence de `Admitted`, `admit`, `Axiom`, `Parameter`, `Conjecture`, `Variable`, `Hypothesis`, `Unsafe`, `vm_cast_no_check`, `native_cast_no_check`, `Declare ML Module` |
| Audit `Print Assumptions` | **113 / 113** théorèmes rapportés **`Closed under the global context`** |
| Vérificateur indépendant du noyau | `rocq check -silent -o -Q theories CartograffectRocq CartograffectRocq.Cartograffect` : **ExitCode 0**, **`Axioms: <none>`**, `Set is predicative`, `Rewrite rules are not allowed`, 0 constante/inductif non sûr |
| Durée totale (compilation propre + contrôles + `rocq check -o`) | **70,84 s** |

---

## 3. Modules validés et temps de compilation mesurés

| # | Module Rocq (`CartograffectRocq.*`) | Équivalent Lean 4 | Lignes | Temps (`verify.ps1`) |
|---|---|---|---|---|
| 1 | [`theories/PredictiveEngine.v`](theories/PredictiveEngine.v) | `Cartograffect/PredictiveEngine.lean` | 599 | 2,14 s |
| 2 | [`theories/CoreAffect.v`](theories/CoreAffect.v) | `Cartograffect/CoreAffect.lean` | 1 098 | 2,72 s |
| 3 | [`theories/AffectiveMatrix.v`](theories/AffectiveMatrix.v) | `Cartograffect/AffectiveMatrix.lean` | 540 | 2,38 s |
| 4 | [`theories/AffectiveTaxonomy.v`](theories/AffectiveTaxonomy.v) | `Cartograffect/AffectiveTaxonomy.lean` | 517 | 3,23 s |
| 5 | [`theories/AffectiveDynamics.v`](theories/AffectiveDynamics.v) | `Cartograffect/AffectiveDynamics.lean` | 844 | 10,08 s |
| 6 | [`theories/Lexicon176.v`](theories/Lexicon176.v) | `Cartograffect/Lexicon176.lean` | 374 | 1,54 s |
| 7 | [`theories/PredictiveCircuit.v`](theories/PredictiveCircuit.v) | `Cartograffect/PredictiveCircuit.lean` | 1 452 | 4,08 s |
| 8 | [`theories/AuditTests.v`](theories/AuditTests.v) | `Cartograffect/AuditTests.lean` | 363 | 18,19 s |
| 9 | [`theories/Cartograffect.v`](theories/Cartograffect.v) | `Cartograffect.lean` | 15 | 0,73 s |
| — | Vérificateur indépendant (`rocq check -o`) | Noyau autonome (`rocqchk`) | — | 25,48 s |
| **Total** | **9 fichiers (bibliothèque + audit + racine)** | **9 fichiers Lean 4** | **5 802** | **70,84 s** |

---

## 4. Comparaison fondationnelle Lean 4 ↔ Rocq 9.1

Dans [`Cartograffect/AuditTests.lean`](../Cartograffect/AuditTests.lean), les **113 théorèmes** audités sont prouvés sans axiome domaine *ad hoc*, mais s'appuient dans la logique standard de Lean 4 sur :
- **24** théorèmes purement réductionnels (`does not depend on any axioms`) ;
- **34** théorèmes extensionnels (`[propext]` ou `[propext, Quot.sound]`) ;
- **55** théorèmes mobilisant le socle classique standard (`[propext, Classical.choice, Quot.sound]`).

Sous **The Rocq Prover 9.1.0**, l'ensemble des **113 théorèmes** — y compris `end_to_end_coherence`, l'atteignabilité exhaustive des 176 entrées, le noyau stochastique `DepthTransitionKernel`, l'indépendance de `PhenomenologicalMapping` et les 41 théorèmes du circuit génératif `PredictiveCircuit` — est certifié **100 % constructivement** (`Closed under the global context`, **0 axiome**), grâce notamment à :

1. **Irrélevance de preuve constructive (`CoreAffect.isValidCoreAffect_pi` & `CoreAffectState_eq`) :** plutôt que d'invoquer `proof_irrel` (classique/extensionnel), la décidabilité de l'égalité sur `Z` et `nat` (`UIP_dec Z.eq_dec`, `UIP_dec Nat.eq_dec`), `Peano_dec.le_unique` et l'exclusion mutuelle constructive `isCentral_not_isOnCrown` établissent l'unicité de preuve de `isValidCoreAffect p` sans aucun axiome.
2. **Entiers binaires `N` (`NArith`) dans [`PredictiveCircuit.v`](theories/PredictiveCircuit.v) :** l'usage d'entiers binaires `N` pour `CircuitKernelParams`, `circuitWeight`, `circuitRowSum` (`4 * scale^6 = 4 000 000 000 000`), `UnifiedDynamicsParams`, `nextChargeAccumulator` et `symmetricSigmoid` permet une évaluation directe par réduction du noyau (`vm_compute; reflexivity` générant un pur `eq_refl`, compatible `rocq check` sans compilo bytecode ni `vm_cast_no_check`).

---

## 5. Inventaire complet des 113 théorèmes certifiés (1-à-1 avec `AuditTests.lean`)

> Tous les identifiants suivent exactement ceux de [`Cartograffect/AuditTests.lean`](../Cartograffect/AuditTests.lean), avec remplacement du séparateur de namespace Lean `.` par `_` pour les deux méthodes homonymes (`Polarity.invert_involutive` → `Polarity_invert_involutive`, `HedonicPolarity.invert_involutive` → `HedonicPolarity_invert_involutive`).

### 5.1 `PredictiveEngine` (7 théorèmes)
`Polarity_invert_involutive`, `coupling_regime_partition`, `feedbackUpdate_couples_gradients`, `inferential_loop_covers_interfaces`, `feedbackUpdateWeighted_couples_precision`, `engineStep_remanence`, `engineStep_phase_progression`.

### 5.2 `CoreAffect` (23 théorèmes)
`engine_induces_valid_core_affect`, `z2_budget_conservation`, `axial_to_diagonal_reallocation`, `dissipationStep_valid`, `dissipationStep_fixed_iff`, `dissipation_strictly_decreases`, `remanence_preserves_state`, `cooperative_step_leaves_crown`, `deployCouplingWithPrecision_valid`, `neutral_coupling_without_suspension_yields_veille`, `neutral_or_subthreshold_with_suspension_yields_central`, `descending_suspension_yields_central_operator`, `central_z_ge2_requires_descending_suspension`, `deployCouplingWithPrecision_budget_conservation`, `dual_engaged_yields_diagonal_z2_precision`, `symmetric_precision_never_lateral`, `projectToCoreAffect_surjective`, `engineStep_canonical_trajectory`, `engineStep_surprise_to_crown`, `anticipation_short_circuits_to_veille`, `dissipation_from_ge2_never_visits_surprise`, `dissipationPotential_short_circuit_jump`, `dissipation_reaches_veille`.

### 5.3 `AffectiveMatrix` (13 théorèmes)
`HedonicPolarity_invert_involutive`, `x_positive_determines_positive_valence`, `x_negative_determines_negative_valence`, `antagonistPoint_preserves_validity`, `antagonistPoint_involutive`, `contralateral_swaps_amplitudes`, `antagonist_commutes_with_invert`, `antagonistPoint_unified`, `antagonist_preserves_validity_in`, `transferUnitYtoX_preserves_sum`, `antagonist_commutes_with_invert_precision`, `evaluateMatrix_core_antagonist_independent`, `mapping_independent_antagonist_invariants`.

### 5.4 `AffectiveTaxonomy` (10 théorèmes)
`inventory_176_certified`, `taxonomy_group_exhaustive`, `taxonomy_group_exclusive`, `dominantSector_iff_taxonomicGroup`, `contralateral_group_bindings`, `classifySubsector_correct`, `subsector_exclusive`, `classifySubsector_refines_group`, `classifySubsector_determines_valence`, **`end_to_end_coherence`**.

### 5.5 `AffectiveDynamics` (10 théorèmes)
`canonicalDepthKernel_reaches_crown`, `canonicalDepthKernel_reaches_lateral`, `lateral_reachable`, `lateral_reachable_from_surprise`, `canonicalDepthKernel_colere_bifurcates`, `canonicalDepthKernel_axial_instability_p2`, `canonicalDepthKernel_outgoingWeight_pos`, `classifyTaxonomicGroup_unique_maximizer`, `classifyTaxonomicGroup_maximizes_membership`, `lateral_has_overlapping_attractors`.

### 5.6 `Lexicon176` & `AuditTests` (8 + 1 théorèmes)
`all176Entries_length`, `all176Entries_geometrically_valid`, `all176Entries_unique_points`, `all176Entries_closed_under_antagonist`, `all176Entries_spatial_completeness`, `all176Entries_deterministically_reachable`, `all176Entries_reachable_by_engine`, `all176Entries_witness_check`, `all176Entries_antagonist_inverts_hedonic_polarity` (`AuditTests.v`).

### 5.7 `PredictiveCircuit` (41 théorèmes)
`circuit_covers_interfaces_both_sides`, `circuit_refines_inferential_ops`, `phiL1_left_inv`, `phiL1_right_inv`, `phiL1_agrees_with_deployZ2`, `crossingII_is_transpose_of_crossingI`, `routeToSubjective_injective`, `routeToPerceptive_injective`, `projectPerceptible_valid`, `projectPerceptible_z2_matches_phiL1`, `projectPerceptible_neutral_elevates_to_central`, `attentional_bottleneck_sum_active`, `circuitRowSum_exact`, `veille_absorbing_free`, `lyapunov_monotone_free`, `lyapunov_strict_descent_witness`, `lyapunov_expected_drift_constant`, `axial_peur_bifurcates_p2`, `veille_reaches_all_one_step`, `all_reach_veille_two_steps`, `veille_unreachable_when_eps_max`, `circularCycle_veille_fixed_point`, `circularCycle_reduces_total_discrepancy`, `lyapunov_drift_charge_with_passive_extinction`, `p1_without_p2_eps_independent`, `epistemic_rigidity_traps_charge_slice`, `pragmatic_helplessness_traps_charge_slice`, `perseveration_traps_discharge_free`, `passive_extinction_zero_relief`, `active_resolution_beats_passive_extinction`, `charge_accumulator_bounded`, `nextStratumR5_le_zMax`, `nextStratumR5_short_circuits_z2_to_veille`, `nextStratumR5_from_ge2_never_visits_surprise`, `symmetricSigmoid_sum`, `symmetricSigmoid_pos`, `symmetricSigmoid_neg`, `precisionShare_double_charge_cancels_alpha`, `projectUnifiedState_valid`, `projectUnifiedState_crown_budget`, `projectUnifiedState_reaches_lateral_consternation`.

*(Total : 7 + 23 + 13 + 10 + 10 + 9 + 41 = **113 théorèmes**.)*

---

## 6. Parité des 11 blocs d'évaluation concrète (`Compute` ↔ `#eval`)

| Bloc | Scénario testé | Sortie Rocq (`Compute`) = Sortie Lean 4 (`#eval`) |
|---|---|---|
| 1 | État basal par défaut | `(0, 0, 0)`, `TS_z0_pointDeVeille`, `TG_operateurCentral` |
| 2 | Surprise sous seuil attentionnel | `(0, 0, 1)`, `TS_z1_saillancePerceptive`, `PA_ascendingRupture` |
| 3 | Colère (`A−, C+`, Z=2) & antagoniste Calme | `(-1, 1, 2)` / `(1, -1, 2)`, `TG_groupeColere`/`FS_diagonalAnger` vs `TG_groupeCalme`/`FS_diagonalCalm`, `ER_ergotropicCompensation`, `Hed_negative` |
| 4 | Suspension R5 (`(0,0,2)`) & trajectoire `engineStep` | `(0, 0, 2)`, `(0, 0, 2)`, trajectoire `(0,0,0) → (0,0,1) → (0,0,2) → (0,2,2)` |
| 5 | Court-circuit de dissipation R5 | `dissipationStep (0,0,2) = (0,0,0)`, saut `ΔV = 4`, descente `(-1,3,3) → (0,0,3) → (0,0,2) → (0,0,0)` |
| 6 | Consternation latérale (voie déterministe R8) | `(-1, 3, 3)`, `GT_lateral`, `TG_groupeJoie`, `FS_lateralDefensiveUrgency`, `Hed_negative`, antagoniste `(3, -1, 3)` |
| 7 | Noyau `canonicalDepthKernel` depuis `(-1, 1, 2)` | poids `2` vers `(-2, 2, 3)`, `1` vers `(-1, 3, 3)`, `1` vers `(-3, 1, 3)`, `outgoingWeight = 4`, équivariant antagoniste `1` |
| 8 | Attracteurs gradués `attractorMembership` (R1) | Consternation `(-1,3,3) : (4, 2, 1, TG_groupeJoie)` ; Envie `(-2,4,4) : (6, 4, 2, TG_groupeJoie)` |
| 9 | Mapping phénoménologique inversé (R3) | `core.point = (-1, 1, 2)` et `antagonist.point = (1, -1, 2)` invariants ; `valence : Hed_negative → Hed_positive` |
| 10 | Circuit à 6 opérateurs (`PredictiveCircuit`) | croisements `(0, 2, (2, 0))`, `projectPerceptible = (-1, 3, 3)`, `circuitRowSum = 4000000000000%N`, `circuitWeight = 101500000000%N`, `op3(default) = (0, 0, 0)` |
| 11 | Loi unifiée (`UnifiedDynamicsParams`) | `nextChargeAccumulator (actif vs passif) = (700%N, 1300%N)`, `nextStratumR5 = (0, 2)`, `projectUnifiedState = (-1, 3, 3)`, `precisionShares = (193%N, 807%N)` |

---

## 7. Reproduction locale autonome

Depuis la racine du dépôt :

```powershell
powershell -ExecutionPolicy Bypass -File rocq/verify.ps1
```

*(Si `rocq.exe` n'est pas dans `PATH` et se trouve ailleurs que `C:\Rocq-Platform~9.1~2026.01\bin`, passer `-RocqBin <chemin>`.)*
