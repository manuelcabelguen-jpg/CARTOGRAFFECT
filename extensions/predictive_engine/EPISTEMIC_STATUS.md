# Statut Épistémique — `extensions/predictive_engine/` (Extension Lean 4 canonique A1–A4)

Ce module constitue une **extension formelle Lean 4** raccordée directement aux types natifs du noyau **Strate 0** (`Cartograffect.PredictiveEngine`, `Cartograffect.CoreAffect`, `Cartograffect.PredictiveCircuit`) dans le respect de la gouvernance du compendium **CARTOGRAFFECT®**.

## Articulation avec la Strate 0

- **Intégrité du noyau Strate 0 préservée :** Aucun des 10 modules existants sous `Cartograffect/` et `Cartograffect.lean` ni la parité symétrique des **120 théorèmes** sur les **6 environnements formels** (Lean 4, Rocq 9.0, Agda 2.9.0, Dafny 4.11.0, SMT-LIB2 / Z3 5.3.3, TLA+ / TLC 2.19) n'ont été modifiés.
- **Compilation stricte :** [`PredictiveEngineCanonical.lean`](PredictiveEngineCanonical.lean) est déclaré comme cible dédiée `PredictiveEngineCanonical` dans [`../../lakefile.lean`](../../lakefile.lean) avec `warningAsError := true`, `0 sorry`, `0 admit`, `0 axiom`, `0 noncomputable` et sans dépendance externe (`Init` uniquement).

## Propriétés certifiées (Arbitrages A1–A4)

1. **Bijection `Φ`** (`canonicalPhi_left_inv`, `canonicalPhi_right_inv`) entre le Croisement II `[A/C]` et la base projective `(X_0, Y_0, 0)` du Croisement I.
2. **Conservation `L1` (P1)** (`canonical_l1_conservation`, `canonical_l1_zero_iff_veille`) : `|X_0| + |Y_0| = 2` pour tout état actif hors `Veille (0,0,0)`.
3. **Loi d'échelle de couronne (A2)** (`canonical_crown_scaling_law`, `canonical_apportionRay_scaling`) : `|π_A| + |π_C| = 2Z - 2` pour tout `Z ≥ 2`.
4. **Disjonction stricte `Veille (0,0,0)` / `INTERFACE ATTENTIONNELLE` (A1)** (`veille_disjoint_from_attentional_point`, `attentional_domain_disjoint_from_veille`, `attentional_neutral_domain_is_non_veille`) : `Veille (0,0,0)` siège exclusivement au Croisement I (`Z = 0`), tandis que tout domaine attentionnel `{±X, ±Y, Z}` (incluant `{0, 0, Z}`) impose `Z ≥ 1`.
5. **Décroissance stricte de Lyapunov et distinction actif vs passif** (`lyapunov_strict_decrease_active_free`, `passive_extinction_requires_delta_pos`, `active_vs_passive_step_disjoint`, `active_vs_passive_energy_signature`) : décroissance stricte `ΔV < 0` sur toute transition non triviale de résolution active (`ε = 0, χ = 0, δ = 0`) et séparation formelle d'avec l'extinction passive (`Charge → Neutre`).
6. **Réponses isolées, projection directe de `Z` et réduction de l'information** (`directProjectToAttentional_preserves_z`, `direct_z_jump_ascent_and_descent_witness`, `informationReduction_nonneg`, `hartley_bits_reduction_nonneg`, `attentional_domain_compression_nonneg`).
