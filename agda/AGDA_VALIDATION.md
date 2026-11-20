# Validation Croisée Formelle sous Agda 2.9.0 — CARTOGRAFFECT

**Auteur :** Manuel Cabelguen  
**Enregistrement OPIC :** Certificat de droit d'auteur canadien **#1233199**  
**Licence :** `AGPL-3.0-or-later` (code source) et `CC-BY-NC-SA-4.0` (modèle théorique et taxonomie)  
**Toolchain vérifiée :** `Agda version 2.9.0` (`{-# OPTIONS --safe --without-K #-}`, autonome sur `Agda.Builtin.*`)  
**Statut :** **10/10 modules vérifiés — 113/113 théorèmes certifiés — 11/11 blocs d'évaluation exacts (`refl`) — 0 `postulate` — 0 `trustMe` — 0 trou `{!}` (6,00 s)**

---

## 1. Objectif et Fondements Logiques

Ce dossier (`agda/`) constitue la **sixième formalisation indépendante** de l'architecture **CARTOGRAFFECT**, en complément de :
1. **Lean 4 (`v4.29.0-rc2`)** — Théorie des types dépendants avec quotient et tactiques (`Cartograffect/*.lean`) ;
2. **Rocq Prover (`9.0.0`)** — Calcul des Constructions Inductives (`rocq/theories/*.v`) ;
3. **SMT-LIB 2.6 / Z3 (`5.3.3`)** — Logique du premier ordre multi-sortes par réfutation (`smt/theories/*.smt2`) ;
4. **Dafny (`4.11.0` / Boogie)** — Logique de Hoare et vérification déductive (`dafny/src/*.dfy`) ;
5. **TLA+ (`SANY` + `TLC 2.19`)** — Logique temporelle des actions et model checking exhaustif (`tla/specs/*.tla`).

La formalisation Agda 2.9.0 repose sur la **Théorie Intuitionniste des Types de Martin-Löf intensionnelle** sous les options les plus strictes du noyau :
- `{-# OPTIONS --safe #-}` : interdit tout postulat (`postulate`), tout axiome d'égalité non constructif (`primTrustMe`, `BUILTIN TRUSTME`), toute pragma d'incohérence (`--type-in-type`, `--injective-type-constructors`, `--rewriting`) et tout méta-terme non résolu ;
- `{-# OPTIONS --without-K #-}` : désactive l'axiome K de Streicher (Uniqueness of Identity Proofs générale), rendant l'ensemble des 113 théorèmes compatible avec la **Théorie Homotopique des Types (HoTT)** et les mathématiques univalentes, tout en prouvant constructivement le principe d'unicité des preuves d'ordre et d'égalité booléenne (`UIP-Bool`, `≤ℕ-pi`) par décidabilité d'Hedberg ;
- **Zéro dépendance externe** : le module `Cartograffect.Prelude` (509 lignes) construit intégralement l'arithmétique de Peano, la division euclidienne certifiée (`div-mod-eq`, `mod-<`, `÷-mono-≤`, `÷-≤-of-≤-*`, `÷-<-of-<-*`, `div-mul-add-exact`), l'arithmétique entière signée (`Int`) et les combinaires de réflexion booléenne (`All`, `_∈_`, `All-lookup`) directement au-dessus des seuls primitifs `Agda.Builtin.*`.

---

## 2. Architecture et Métriques de Compilation (Clean Build)

La suite comprend **10 fichiers `.agda`** totalisant **5 227 lignes de code** vérifiées en **6,00 secondes** à partir d'un état vierge (suppression préalable de tous les fichiers d'interface `*.agdai`) :

| # | Module Agda | Fichier | Lignes | Théorèmes | Temps (`agda`) | Statut |
| :-: | :--- | :--- | :-: | :-: | :-: | :-: |
| 00 | `Cartograffect.Prelude` | `src/Cartograffect/Prelude.agda` | 509 | — (lemmes fondationnels) | 0,44 s | `PASS` |
| 01 | `Cartograffect.PredictiveEngine` | `src/Cartograffect/PredictiveEngine.agda` | 339 | 7 | 0,43 s | `PASS` |
| 02 | `Cartograffect.CoreAffect` | `src/Cartograffect/CoreAffect.agda` | 1 004 | 23 | 0,53 s | `PASS` |
| 03 | `Cartograffect.AffectiveMatrix` | `src/Cartograffect/AffectiveMatrix.agda` | 439 | 13 | 0,59 s | `PASS` |
| 04 | `Cartograffect.AffectiveTaxonomy` | `src/Cartograffect/AffectiveTaxonomy.agda` | 506 | 10 | 0,54 s | `PASS` |
| 05 | `Cartograffect.AffectiveDynamics` | `src/Cartograffect/AffectiveDynamics.agda` | 576 | 10 | 0,62 s | `PASS` |
| 06 | `Cartograffect.Lexicon176` | `src/Cartograffect/Lexicon176.agda` | 338 | 8 | 0,62 s | `PASS` |
| 07 | `Cartograffect.PredictiveCircuit` | `src/Cartograffect/PredictiveCircuit.agda` | 1 184 | 41 | 0,76 s | `PASS` |
| 08 | `Cartograffect.AuditTests` | `src/Cartograffect/AuditTests.agda` | 315 | 1 (+ 11 blocs `refl`) | 0,70 s | `PASS` |
| 09 | `Cartograffect` | `src/Cartograffect.agda` | 17 | Agrégateur racine | 0,75 s | `PASS` |
| **Total** | **10 modules** | `agda/src/**` | **5 227** | **113 théorèmes + 11 blocs** | **6,00 s** | **100 %** |

---

## 3. Garanties d'Intégrité Statique et du Vérificateur de Types

Le script `agda/verify.ps1` applique trois niveaux d'audit :
1. **Audit de sûreté du noyau (`[1/3]`)** : vérifie que la première ligne de chacun des 10 fichiers `.agda` est exactement `{-# OPTIONS --safe --without-K #-}` et qu'aucun fichier ne contient `postulate`, `trustMe`, `primTrustMe`, `BUILTIN TRUSTME`, `{!`, `--type-in-type`, `--unsafe`, `--rewriting`, `--allow-unsolved-metas`, `--sized-types` ou `--guardedness`.
2. **Recensement exhaustif (`[2/3]`)** : vérifie la présence explicite des **113 signatures de théorèmes** (`7 + 23 + 13 + 10 + 10 + 8 + 41 + 1`) et des **11 blocs d'évaluation concrète** (`eval_block-01` .. `eval_block-11`), ainsi que leur ancrage typé dans `Cartograffect.AuditTests` (`auditAnchor-01-PredictiveEngine` .. `auditAnchor-08-AuditTests`).
3. **Vérification de types clean-room (`[3/3]`)** : supprime tous les artéfacts `*.agdai` et exécute `agda.exe -i agda/src` sur chacun des 10 modules dans l'ordre topologique strict.

---

## 4. Correspondance des 113 Théorèmes Certifiés

> **Convention syntaxique Agda :** En Agda, le caractère `_` sépare les emplacements d'arguments des opérateurs mixfixes ; aucun segment entre deux `_` ne peut donc être un mot-clé réservé d'Agda (`with`, `to`, `in`) ni un littéral numérique (`176`). Dans les 10 identifiants concernés sur 113, le séparateur autour du mot-clé ou du nombre est remplacé par un trait d'union `-` standard Agda (ex. `inventory-176-certified`, `end-to-end_coherence`), tout en conservant le nom Lean/Rocq canonique en commentaire d'en-tête.

### Module 01 — `Cartograffect.PredictiveEngine` (7 théorèmes)
1. `Polarity_invert_involutive`
2. `coupling_regime_partition`
3. `feedbackUpdate_couples_gradients`
4. `inferential_loop_covers_interfaces`
5. `feedbackUpdateWeighted_couples_precision`
6. `engineStep_remanence`
7. `engineStep_phase_progression`

### Module 02 — `Cartograffect.CoreAffect` (23 théorèmes)
8. `engine_induces_valid_core_affect`
9. `z2_budget_conservation`
10. `axial-to-diagonal_reallocation` (`axial_to_diagonal_reallocation`)
11. `dissipationStep_valid`
12. `dissipationStep_fixed_iff`
13. `dissipation_strictly_decreases`
14. `remanence_preserves_state`
15. `cooperative_step_leaves_crown`
16. `deployCouplingWithPrecision_valid`
17. `neutral_coupling_without_suspension_yields_veille`
18. `neutral_or_subthreshold-with-suspension_yields_central` (`neutral_or_subthreshold_with_suspension_yields_central`)
19. `descending_suspension_yields_central_operator`
20. `central_z_ge2_requires_descending_suspension`
21. `deployCouplingWithPrecision_budget_conservation`
22. `dual_engaged_yields_diagonal_z2_precision`
23. `symmetric_precision_never_lateral`
24. `projectToCoreAffect_surjective`
25. `engineStep_canonical_trajectory`
26. `engineStep_surprise_to_crown`
27. `anticipation_short_circuits_to_veille`
28. `dissipation_from_ge2_never_visits_surprise`
29. `dissipationPotential_short_circuit_jump`
30. `dissipation_reaches_veille`

### Module 03 — `Cartograffect.AffectiveMatrix` (13 théorèmes)
31. `HedonicPolarity_invert_involutive`
32. `x_positive_determines_positive_valence`
33. `x_negative_determines_negative_valence`
34. `antagonistPoint_preserves_validity`
35. `antagonistPoint_involutive`
36. `contralateral_swaps_amplitudes`
37. `antagonist_commutes-with-invert` (`antagonist_commutes_with_invert`)
38. `antagonistPoint_unified`
39. `antagonist_preserves_validity-in` (`antagonist_preserves_validity_in`)
40. `transferUnitYtoX_preserves_sum`
41. `antagonist_commutes-with-invert_precision` (`antagonist_commutes_with_invert_precision`)
42. `evaluateMatrix_core_antagonist_independent`
43. `mapping_independent_antagonist_invariants`

### Module 04 — `Cartograffect.AffectiveTaxonomy` (10 théorèmes)
44. `inventory-176-certified` (`inventory_176_certified`)
45. `taxonomy_group_exhaustive`
46. `taxonomy_group_exclusive`
47. `dominantSector_iff_taxonomicGroup`
48. `contralateral_group_bindings`
49. `classifySubsector_correct`
50. `subsector_exclusive`
51. `classifySubsector_refines_group`
52. `classifySubsector_determines_valence`
53. `end-to-end_coherence` (`end_to_end_coherence`)

### Module 05 — `Cartograffect.AffectiveDynamics` (10 théorèmes + 1 loi auxiliaire)
- Loi auxiliaire : `canonicalDepthKernel_support_adjacent`
54. `canonicalDepthKernel_reaches_crown`
55. `canonicalDepthKernel_reaches_lateral`
56. `lateral_reachable`
57. `lateral_reachable_from_surprise`
58. `canonicalDepthKernel_colere_bifurcates`
59. `canonicalDepthKernel_axial_instability_p2`
60. `canonicalDepthKernel_outgoingWeight_pos`
61. `classifyTaxonomicGroup_unique_maximizer`
62. `classifyTaxonomicGroup_maximizes_membership`
63. `lateral_has_overlapping_attractors`

### Module 06 — `Cartograffect.Lexicon176` (8 théorèmes)
64. `all176Entries_length`
65. `all176Entries_geometrically_valid`
66. `all176Entries_z_bounds`
67. `all176Entries_unique_points`
68. `all176Entries_complete`
69. `all176Entries_deterministically_reachable`
70. `all176Entries_reachable_by_engine`
71. `all176Entries_witness_check`

### Module 07 — `Cartograffect.PredictiveCircuit` (41 théorèmes)
72. `circuit_covers_interfaces_both_sides`
73. `circuit_refines_inferential_ops`
74. `phiL1_left_inv`
75. `phiL1_right_inv`
76. `phiL1_agrees-with-deployZ2` (`phiL1_agrees_with_deployZ2`)
77. `crossingII_is_transpose_of_crossingI`
78. `routeToSubjective_injective`
79. `routeToPerceptive_injective`
80. `projectPerceptible_valid`
81. `projectPerceptible_z2_matches_phiL1`
82. `projectPerceptible_neutral_elevates-to-central` (`projectPerceptible_neutral_elevates_to_central`)
83. `attentional_bottleneck_sum_active`
84. `circuitRowSum_exact`
85. `veille_absorbing_free`
86. `lyapunov_monotone_free`
87. `lyapunov_strict_descent_witness`
88. `lyapunov_expected_drift_constant`
89. `axial_peur_bifurcates_p2`
90. `veille_reaches_all_one_step`
91. `all_reach_veille_two_steps`
92. `veille_unreachable_when_eps_max`
93. `circularCycle_veille_fixed_point`
94. `circularCycle_reduces_total_discrepancy`
95. `lyapunov_drift_charge-with-passive_extinction` (`lyapunov_drift_charge_with_passive_extinction`)
96. `p1_without_p2_eps_independent`
97. `epistemic_rigidity_traps_charge_slice`
98. `pragmatic_helplessness_traps_charge_slice`
99. `perseveration_traps_discharge_free`
100. `passive_extinction_zero_relief`
101. `active_resolution_beats_passive_extinction`
102. `charge_accumulator_bounded`
103. `nextStratumR5_le_zMax`
104. `nextStratumR5_short_circuits_z2-to-veille` (`nextStratumR5_short_circuits_z2_to_veille`)
105. `nextStratumR5_from_ge2_never_visits_surprise`
106. `symmetricSigmoid_sum`
107. `symmetricSigmoid_pos`
108. `symmetricSigmoid_neg`
109. `precisionShare_double_charge_cancels_alpha`
110. `projectUnifiedState_valid`
111. `projectUnifiedState_crown_budget`
112. `projectUnifiedState_reaches_lateral_consternation`

### Module 08 — `Cartograffect.AuditTests` (1 théorème + 11 blocs d'évaluation)
113. `all176Entries_antagonist_inverts_hedonic_polarity`

---

## 5. Parité Computationnelle Bit-à-Bit sur les 11 Blocs (`refl`)

Chacun des 11 blocs `eval_block-01` .. `eval_block-11` dans `Cartograffect.AuditTests` est certifié par **réflexivité définitionnelle (`refl`)** du normalisateur Agda :

| Bloc | Propriété évaluée par réduction définitionnelle (`refl`) | Valeur certifiée |
| :-: | :--- | :--- |
| `eval_block-01` | Trajectoire 3 phases `engineStep` depuis `s0_block1` | `(0,0,0) → (0,0,1) → (0,0,2) → (0,2,2)` |
| `eval_block-02` | Réallocation `Z2` axial vers diagonal via `triggerSecondaryGradient` | `(-2,0,2)` (`axial`, `groupePeur`) → `(-1,1,2)` (`diagonal`, `groupeColere`) |
| `eval_block-03` | Pondération asymétrique `(piA=1, piC=3)` à `d=1` (`Z3`) et antagoniste | `(1,3,3)` (`lateral`, `groupeJoie`, `lateralApproachSynergy`), ant. `(-3,-1,3)` |
| `eval_block-04` | Dissipation allostatique de `(1,3,3)` vers `(0,0,0)` et potentiels | `(1,3,3) → (0,0,3) → (0,0,2) → (0,0,0)`, potentiels `(7, 6, 4, 0)` |
| `eval_block-05` | Poids du noyau inter-strates `canonicalDepthWeight` (instabilité P2 & Colère) | `(1, 1, 2, 2, 2, 1, 1)` |
| `eval_block-06` | Appartenances graduées `attractorMembership` au point latéral `(1,3,3)` | `Joie = 4`, `Desir = 2`, `Courage = 1`, `Peur = 0` |
| `eval_block-07` | Court-circuit d'Anticipation `(0,0,2) → (0,0,0)` et saut de potentiel | `dissipationStep (0,0,2) = (0,0,0)`, `ΔΦ = 4` |
| `eval_block-08` | Cardinalités des couronnes `Z2..Z7` et du lexique `all176Entries` | `(8, 16, 24, 32, 40, 48)`, `length all176Entries = 176` |
| `eval_block-09` | Bijection `phiL1 (neg,pos)`, croisements I/II, goulot `X2/Y2` et Lyapunov | `(-1,1)`, `I=(1,0)`, `II=(0,1)`, `X2=2, Y2=2`, `V(neg,neg)=4` |
| `eval_block-10` | Somme de ligne markovienne $4 \cdot 100^6$ et transition P2 `(neg,0)→(neg,pos)` | `circuitRowSum = 4000000000000`, `circuitWeight = 101500000000` |
| `eval_block-11` | Dynamique unifiée `(R_t, Z_t, π_A, π_C)` et projection vers Consternation | `R'=(700, 1300)`, `Z'=(0, 2)`, `shares=(193, 807)`, `pt=(-1, 3, 3)` |

---

## 6. Reproduction Locale

```powershell
powershell -ExecutionPolicy Bypass -File .\agda\verify.ps1
```
