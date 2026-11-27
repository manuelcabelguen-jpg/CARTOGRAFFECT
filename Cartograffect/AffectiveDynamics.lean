/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
Author: Manuel Cabelguen
-/

import Cartograffect.PredictiveEngine
import Cartograffect.CoreAffect
import Cartograffect.AffectiveMatrix
import Cartograffect.AffectiveTaxonomy

namespace Cartograffect

namespace AffectiveDynamics

open PredictiveEngine
open CoreAffect
open AffectiveMatrix
open AffectiveTaxonomy

/-!
# Dynamique stochastique inter-strates (`DepthTransitionKernel`) — Alignement v3.0 (Options 1A, 2a, 3b)

Ce module formalise la **surcouche stochastique** inter-strates `Z → Z + 1` sans dépendance externe
(uniquement noyau Lean 4 et `Init`) :
- Une structure abstraite à poids entiers `DepthTransitionKernel` capturant les trois invariants
  structurels d'une transition markovienne d'approfondissement d'un pas (`ΔZ = +1`, Option 2a) :
  support géométriquement valide (`support_valid`), adjacence verticale stricte (`support_adjacent`),
  et conservation du quadrant (`quadrant_preserved`).
- Conformément à l'**Option 3b** (`DECISIONS_V3.md`), `DepthTransitionKernel` n'impose **pas**
  d'équivariance dynamique sous `antagonistPoint` : l'antagonisme demeure une **symétrie géométrique
  statique**, tandis que la dynamique assume la **brisure de symétrie Charge / Décharge** (biais de
  négativité). L'instabilité axiale (`χ > 0`, P2) porte exclusivement sur les **2 pôles axiaux en
  Charge négative** (`Peur (-2, 0, 2)` et `Tristesse (0, -2, 2)`), en parité exacte avec
  `PredictiveCircuit.lean` et `python/cartograffect_predictive_engine.py`.
- Une fonction de somme sortante `DepthTransitionKernel.outgoingWeight` prouvée strictement
  positive sur tout état valide, et la mesure d'appartenance graduée `attractorMembership` sur les
  9 groupes fonctionnels neutres de l'**Option 1A**.
-/

/-!
## 1. Prédicat booléen de validité géométrique
-/

/-- Version décidable (`Bool`) de l'invariant géométrique `isValidCoreAffect`. -/
def isValidCoreAffectB (p : CoreAffectPoint) : Bool :=
  (p.x == 0 && p.y == 0) || (decide (p.z ≥ 2) && (p.displacementSum == crownRadius p.z))

theorem isValidCoreAffectB_iff (p : CoreAffectPoint) :
    isValidCoreAffectB p = true ↔ isValidCoreAffect p := by
  simp only [isValidCoreAffectB, Bool.or_eq_true, Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq,
    isValidCoreAffect, CoreAffectPoint.isCentral, CoreAffectPoint.isOnCrown]

/-!
## 2. Structure abstraite du noyau de transition inter-strates (`DepthTransitionKernel`)
-/

/--
Structure de noyau de transition inter-strates à poids entiers (`Z → Z + 1`, Options 2a & 3b) :
formalise la dynamique d'approfondissement pas-à-pas sans dépendance Mathlib en exigeant :
1. `support_valid` : tout état cible de poids non nul est géométriquement valide (`isValidCoreAffect`).
2. `support_adjacent` : toute transition de poids non nul progresse d'une unique strate (`q.z = p.z + 1`).
3. `quadrant_preserved` : toute transition conserve l'orientation des signes (`p.x * q.x ≥ 0 ∧ p.y * q.y ≥ 0`).
(Conformément à l'Option 3b, aucune équivariance dynamique sous `antagonistPoint` n'est postulée.)
-/
structure DepthTransitionKernel where
  weight : CoreAffectPoint → CoreAffectPoint → Nat
  -- (i) support admissible : on n'atteint que des états valides
  support_valid : ∀ p q, weight p q ≠ 0 → isValidCoreAffect q
  -- (ii) adjacence verticale stricte (Option 2a : pas unitaire Z → Z + 1)
  support_adjacent : ∀ p q, weight p q ≠ 0 → q.z = p.z + 1
  -- (iii) conservation du quadrant (« une même orientation conserve son signe », §5.2)
  quadrant_preserved : ∀ p q, weight p q ≠ 0 → p.x * q.x ≥ 0 ∧ p.y * q.y ≥ 0

/-!
## 3. Noyau canonique d'approfondissement asymétrique Charge / Décharge (`canonicalDepthKernel`)
-/

/--
Fonction de poids canonique pour le noyau inter-strates `Z → Z + 1` (Option 3b) :
- `(0, 0, Z) → (0, 0, Z + 1)` : poids `1` (maintien sur l'axe central des opérateurs).
- `(0, 0, 1) → couronne(Z = 2)` : poids `1` (amorçage depuis la Surprise vers les 8 prototypes primaires).
- Position axiale en **Charge négative** (`p.x < 0` ou `p.y < 0`, dont `Peur (-2, 0, 2)` et `Tristesse (0, -2, 2)`) :
  poids `1` vers l'axe aligné, poids `2` vers les deux diagonales adjacentes (instabilité axiale P2 induite par `χ > 0`).
- Position axiale en **Décharge positive** (`p.x > 0` ou `p.y > 0`, dont `Courage (2, 0, 2)` et `Joie (0, 2, 2)`) :
  poids `2` sur l'axe aligné et poids `0` d'auto-déstabilisation vers les diagonales à bruit nul (`χ` inactif hors Charge).
- Position non axiale `Z ≥ 2` → position non axiale dans le même quadrant strict (`|q.x| ≥ |p.x| ∧ |q.y| ≥ |p.y|`) :
  poids `2` pour la poursuite diagonale → diagonale, poids `1` pour les bifurcations latérales.
-/
def canonicalDepthWeight (p q : CoreAffectPoint) : Nat :=
  if isValidCoreAffectB p && isValidCoreAffectB q && (q.z == p.z + 1) &&
     (decide (p.x * q.x ≥ 0) && decide (p.y * q.y ≥ 0)) then
    if q.x == 0 && q.y == 0 then
      if p.x == 0 && p.y == 0 then 1 else 0
    else if p.x == 0 && p.y == 0 then
      if p.z == 1 then 1 else 0
    else if p.x == 0 || p.y == 0 then
      if (p.x == 0 || q.x != 0) && (p.y == 0 || q.y != 0) then
        if decide (p.x < 0 || p.y < 0) then
          if q.x == 0 || q.y == 0 then 1
          else if q.x.natAbs == q.y.natAbs then 2
          else 0
        else
          if q.x == 0 || q.y == 0 then 2 else 0
      else 0
    else
      if q.x != 0 && q.y != 0 &&
         decide (q.x.natAbs ≥ p.x.natAbs) && decide (q.y.natAbs ≥ p.y.natAbs) then
        if (p.x.natAbs == p.y.natAbs) && (q.x.natAbs == q.y.natAbs) then 2 else 1
      else 0
  else 0

/--
Noyau canonique de transition inter-strates (`canonicalDepthKernel`), certifiant mécaniquement
les trois propriétés structurelles de `DepthTransitionKernel` en conformité avec l'Option 3b.
-/
def canonicalDepthKernel : DepthTransitionKernel where
  weight := canonicalDepthWeight
  support_valid := by
    intro p q hw
    unfold canonicalDepthWeight at hw
    split at hw
    · rename_i hguard
      simp only [Bool.and_eq_true] at hguard
      exact (isValidCoreAffectB_iff q).mp hguard.1.1.2
    · exact absurd rfl hw
  support_adjacent := by
    intro p q hw
    unfold canonicalDepthWeight at hw
    split at hw
    · rename_i hguard
      simp only [Bool.and_eq_true, beq_iff_eq] at hguard
      exact hguard.1.2
    · exact absurd rfl hw
  quadrant_preserved := by
    intro p q hw
    unfold canonicalDepthWeight at hw
    split at hw
    · rename_i hguard
      simp only [Bool.and_eq_true, decide_eq_true_eq] at hguard
      exact hguard.2
    · exact absurd rfl hw

instance : Inhabited DepthTransitionKernel where
  default := canonicalDepthKernel

/-!
## 4. Lemmes de positivité, atteignabilité pas-à-pas et asymétrie P2 (Option 3b)
-/

private theorem same_sign_mul_nonneg {a b : Int}
    (h : (a > 0 ∧ b > 0) ∨ (a < 0 ∧ b < 0)) : a * b ≥ 0 := by
  rcases h with ⟨ha, hb⟩ | ⟨ha, hb⟩
  · have hm := Int.mul_pos ha hb; omega
  · have hm := Int.mul_pos_of_neg_of_neg ha hb; omega

private theorem canonicalDepthWeight_pos_of_central (z : Nat) :
    canonicalDepthKernel.weight ⟨0, 0, z⟩ ⟨0, 0, z + 1⟩ ≠ 0 := by
  dsimp [canonicalDepthKernel, canonicalDepthWeight, isValidCoreAffectB]
  simp only [beq_self_eq_true, Bool.and_self, Bool.true_or, Int.le_refl, decide_true, ↓reduceIte]
  decide

private theorem canonicalDepthWeight_pos_of_axial_y (py qy : Int) (pz : Nat)
    (hpv : isValidCoreAffect ⟨0, py, pz⟩) (hqv : isValidCoreAffect ⟨0, qy, pz + 1⟩)
    (hpy : py ≠ 0) (hqy : qy ≠ 0) (hmul : py * qy ≥ 0) :
    canonicalDepthKernel.weight ⟨0, py, pz⟩ ⟨0, qy, pz + 1⟩ ≠ 0 := by
  have hp_b : isValidCoreAffectB ⟨0, py, pz⟩ = true := (isValidCoreAffectB_iff _).mpr hpv
  have hq_b : isValidCoreAffectB ⟨0, qy, pz + 1⟩ = true := (isValidCoreAffectB_iff _).mpr hqv
  have hpy0 : (py == 0) = false := beq_false_of_ne hpy
  have hqy0 : (qy == 0) = false := beq_false_of_ne hqy
  have hqyn : (qy != 0) = true := by simp [bne, hqy0]
  dsimp [canonicalDepthKernel, canonicalDepthWeight]
  simp only [hp_b, hq_b, hpy0, hqy0, hqyn, hmul, beq_self_eq_true, Int.le_refl,
    decide_true, Bool.true_and, Bool.and_false, Bool.or_true, Bool.or_false,
    Bool.false_eq_true, ↓reduceIte]
  split <;> decide

private theorem canonicalDepthWeight_pos_of_axial_x (px qx : Int) (pz : Nat)
    (hpv : isValidCoreAffect ⟨px, 0, pz⟩) (hqv : isValidCoreAffect ⟨qx, 0, pz + 1⟩)
    (hpx : px ≠ 0) (hqx : qx ≠ 0) (hmul : px * qx ≥ 0) :
    canonicalDepthKernel.weight ⟨px, 0, pz⟩ ⟨qx, 0, pz + 1⟩ ≠ 0 := by
  have hp_b : isValidCoreAffectB ⟨px, 0, pz⟩ = true := (isValidCoreAffectB_iff _).mpr hpv
  have hq_b : isValidCoreAffectB ⟨qx, 0, pz + 1⟩ = true := (isValidCoreAffectB_iff _).mpr hqv
  have hpx0 : (px == 0) = false := beq_false_of_ne hpx
  have hqx0 : (qx == 0) = false := beq_false_of_ne hqx
  have hqxn : (qx != 0) = true := by simp [bne, hqx0]
  dsimp [canonicalDepthKernel, canonicalDepthWeight]
  simp only [hp_b, hq_b, hpx0, hqx0, hqxn, hmul, beq_self_eq_true, Int.le_refl,
    decide_true, Bool.true_and, Bool.false_and, Bool.or_true, Bool.or_false,
    Bool.false_eq_true, ↓reduceIte]
  split <;> decide

private theorem canonicalDepthWeight_pos_of_nonaxial (px py qx qy : Int) (pz : Nat)
    (hpv : isValidCoreAffect ⟨px, py, pz⟩) (hqv : isValidCoreAffect ⟨qx, qy, pz + 1⟩)
    (hpx : px ≠ 0) (hpy : py ≠ 0) (hqx : qx ≠ 0) (hqy : qy ≠ 0)
    (hmul_x : px * qx ≥ 0) (hmul_y : py * qy ≥ 0)
    (hge_x : qx.natAbs ≥ px.natAbs) (hge_y : qy.natAbs ≥ py.natAbs) :
    canonicalDepthKernel.weight ⟨px, py, pz⟩ ⟨qx, qy, pz + 1⟩ ≠ 0 := by
  have hp_b : isValidCoreAffectB ⟨px, py, pz⟩ = true := (isValidCoreAffectB_iff _).mpr hpv
  have hq_b : isValidCoreAffectB ⟨qx, qy, pz + 1⟩ = true := (isValidCoreAffectB_iff _).mpr hqv
  have hpx0 : (px == 0) = false := beq_false_of_ne hpx
  have hpy0 : (py == 0) = false := beq_false_of_ne hpy
  have hqx0 : (qx == 0) = false := beq_false_of_ne hqx
  have hqy0 : (qy == 0) = false := beq_false_of_ne hqy
  have hqxn : (qx != 0) = true := by simp [bne, hqx0]
  have hqyn : (qy != 0) = true := by simp [bne, hqy0]
  have hx_ge : decide (qx.natAbs ≥ px.natAbs) = true := decide_eq_true hge_x
  have hy_ge : decide (qy.natAbs ≥ py.natAbs) = true := decide_eq_true hge_y
  dsimp [canonicalDepthKernel, canonicalDepthWeight]
  simp only [hp_b, hq_b, hpx0, hpy0, hqx0, hqy0, hqxn, hqyn, hmul_x, hmul_y, hx_ge, hy_ge,
    beq_self_eq_true, decide_true, Bool.true_and, Bool.false_and, Bool.false_or,
    Bool.false_eq_true, ↓reduceIte]
  split <;> decide

/--
Atteignabilité pas-à-pas de toute position de couronne en strate `Z ≥ 3` par au moins un
antécédent valide en strate `Z - 1` via `canonicalDepthKernel`.
-/
theorem canonicalDepthKernel_reaches_crown (q : CoreAffectPoint)
    (h_valid : isValidCoreAffect q) (hz : q.z ≥ 3) (h_crown : ¬q.isCentral) :
    ∃ p : CoreAffectPoint, isValidCoreAffect p ∧ p.z + 1 = q.z ∧ canonicalDepthKernel.weight p q ≠ 0 := by
  rcases q with ⟨qx, qy, qz⟩
  dsimp only at hz
  dsimp only [CoreAffectPoint.isCentral] at h_crown
  cases qz with
  | zero => omega
  | succ n =>
    cases n with
    | zero => omega
    | succ m =>
      cases m with
      | zero => omega
      | succ d =>
        have h_crown_q : CoreAffectPoint.isOnCrown ⟨qx, qy, d + 3⟩ := by
          rcases h_valid with hc | hcr
          · exact absurd hc h_crown
          · exact hcr
        dsimp [CoreAffectPoint.isOnCrown, CoreAffectPoint.displacementSum, crownRadius] at h_crown_q
        have hsum : qx.natAbs + qy.natAbs = 2 * d + 4 := by omega
        by_cases hax_q : qx = 0 ∨ qy = 0
        · rcases hax_q with hqx0 | hqy0
          · subst hqx0
            have hqy_nz : qy ≠ 0 := fun h0 => h_crown ⟨rfl, h0⟩
            rcases (by omega : qy > 0 ∨ qy < 0) with hpos | hneg
            · have hpv : isValidCoreAffect ⟨0, Int.ofNat (2 * d + 2), d + 2⟩ :=
                Or.inr ⟨by dsimp only; omega, by dsimp [CoreAffectPoint.displacementSum, crownRadius]; omega⟩
              refine ⟨⟨0, Int.ofNat (2 * d + 2), d + 2⟩, hpv, rfl, ?_⟩
              exact canonicalDepthWeight_pos_of_axial_y (Int.ofNat (2 * d + 2)) qy (d + 2)
                hpv h_valid (by change (↑(2 * d + 2) : Int) ≠ 0; omega) hqy_nz
                (same_sign_mul_nonneg (Or.inl ⟨by change (↑(2 * d + 2) : Int) > 0; omega, hpos⟩))
            · have hpv : isValidCoreAffect ⟨0, -Int.ofNat (2 * d + 2), d + 2⟩ :=
                Or.inr ⟨by dsimp only; omega, by
                  dsimp [CoreAffectPoint.displacementSum, crownRadius]
                  rw [Int.natAbs_neg]; omega⟩
              refine ⟨⟨0, -Int.ofNat (2 * d + 2), d + 2⟩, hpv, rfl, ?_⟩
              exact canonicalDepthWeight_pos_of_axial_y (-Int.ofNat (2 * d + 2)) qy (d + 2)
                hpv h_valid (by change -(↑(2 * d + 2) : Int) ≠ 0; omega) hqy_nz
                (same_sign_mul_nonneg (Or.inr ⟨by change -(↑(2 * d + 2) : Int) < 0; omega, hneg⟩))
          · subst hqy0
            have hqx_nz : qx ≠ 0 := fun h0 => h_crown ⟨h0, rfl⟩
            rcases (by omega : qx > 0 ∨ qx < 0) with hpos | hneg
            · have hpv : isValidCoreAffect ⟨Int.ofNat (2 * d + 2), 0, d + 2⟩ :=
                Or.inr ⟨by dsimp only; omega, by dsimp [CoreAffectPoint.displacementSum, crownRadius]; omega⟩
              refine ⟨⟨Int.ofNat (2 * d + 2), 0, d + 2⟩, hpv, rfl, ?_⟩
              exact canonicalDepthWeight_pos_of_axial_x (Int.ofNat (2 * d + 2)) qx (d + 2)
                hpv h_valid (by change (↑(2 * d + 2) : Int) ≠ 0; omega) hqx_nz
                (same_sign_mul_nonneg (Or.inl ⟨by change (↑(2 * d + 2) : Int) > 0; omega, hpos⟩))
            · have hpv : isValidCoreAffect ⟨-Int.ofNat (2 * d + 2), 0, d + 2⟩ :=
                Or.inr ⟨by dsimp only; omega, by
                  dsimp [CoreAffectPoint.displacementSum, crownRadius]
                  rw [Int.natAbs_neg]; omega⟩
              refine ⟨⟨-Int.ofNat (2 * d + 2), 0, d + 2⟩, hpv, rfl, ?_⟩
              exact canonicalDepthWeight_pos_of_axial_x (-Int.ofNat (2 * d + 2)) qx (d + 2)
                hpv h_valid (by change -(↑(2 * d + 2) : Int) ≠ 0; omega) hqx_nz
                (same_sign_mul_nonneg (Or.inr ⟨by change -(↑(2 * d + 2) : Int) < 0; omega, hneg⟩))
        · have hqx0 : qx ≠ 0 := fun h => hax_q (Or.inl h)
          have hqy0 : qy ≠ 0 := fun h => hax_q (Or.inr h)
          let ax : Nat := if qx.natAbs ≥ 2 then (if qy.natAbs ≥ 2 then qx.natAbs - 1 else qx.natAbs - 2) else 1
          let ay : Nat := 2 * d + 2 - ax
          have h_ax_lo : ax ≥ 1 := by
            dsimp only [ax]
            split
            · split <;> omega
            · omega
          have h_ax_hi : ax ≤ qx.natAbs := by
            dsimp only [ax]
            split
            · split <;> omega
            · omega
          have h_ay_lo : ay ≥ 1 := by
            dsimp only [ax, ay]
            split
            · split <;> omega
            · omega
          have h_ay_hi : ay ≤ qy.natAbs := by
            dsimp only [ax, ay]
            split
            · split <;> omega
            · omega
          have h_sum_ab : ax + ay = 2 * d + 2 := by
            dsimp only [ax, ay]
            split
            · split <;> omega
            · omega
          let px : Int := if qx > 0 then Int.ofNat ax else -Int.ofNat ax
          let py : Int := if qy > 0 then Int.ofNat ay else -Int.ofNat ay
          have hpx_abs : px.natAbs = ax := by
            dsimp only [px]
            split
            · rfl
            · exact natAbs_neg_ofNat ax
          have hpy_abs : py.natAbs = ay := by
            dsimp only [py]
            split
            · rfl
            · exact natAbs_neg_ofNat ay
          have hpx_nz : px ≠ 0 := by
            dsimp only [px]
            split
            · change (↑ax : Int) ≠ 0; omega
            · change -(↑ax : Int) ≠ 0; omega
          have hpy_nz : py ≠ 0 := by
            dsimp only [py]
            split
            · change (↑ay : Int) ≠ 0; omega
            · change -(↑ay : Int) ≠ 0; omega
          have hmul_x : px * qx ≥ 0 := by
            apply same_sign_mul_nonneg
            dsimp only [px]; split
            · rename_i hx; exact Or.inl ⟨by change (↑ax : Int) > 0; omega, hx⟩
            · rename_i hx; exact Or.inr ⟨by change -(↑ax : Int) < 0; omega, by omega⟩
          have hmul_y : py * qy ≥ 0 := by
            apply same_sign_mul_nonneg
            dsimp only [py]; split
            · rename_i hy; exact Or.inl ⟨by change (↑ay : Int) > 0; omega, hy⟩
            · rename_i hy; exact Or.inr ⟨by change -(↑ay : Int) < 0; omega, by omega⟩
          have hpv : isValidCoreAffect ⟨px, py, d + 2⟩ :=
            Or.inr ⟨by dsimp only; omega, by
              dsimp [CoreAffectPoint.displacementSum, crownRadius]
              rw [hpx_abs, hpy_abs]
              exact h_sum_ab⟩
          refine ⟨⟨px, py, d + 2⟩, hpv, rfl, ?_⟩
          exact canonicalDepthWeight_pos_of_nonaxial px py qx qy (d + 2) hpv h_valid
            hpx_nz hpy_nz hqx0 hqy0 hmul_x hmul_y
            (by rw [hpx_abs]; exact h_ax_hi) (by rw [hpy_abs]; exact h_ay_hi)

/-- Toute position latérale valide `q` est atteinte en un pas (`p.z + 1 = q.z`) par `canonicalDepthKernel`. -/
theorem canonicalDepthKernel_reaches_lateral (q : CoreAffectPoint)
    (h_valid : isValidCoreAffect q) (h_lat : q.classifyGeometry = .lateral) :
    ∃ p : CoreAffectPoint, isValidCoreAffect p ∧ p.z + 1 = q.z ∧ canonicalDepthKernel.weight p q ≠ 0 := by
  have hnc : ¬q.isCentral := by
    intro ⟨hx, hy⟩
    have hgeom : q.classifyGeometry = .central := by
      unfold CoreAffectPoint.classifyGeometry
      simp [hx, hy]
    rw [hgeom] at h_lat
    cases h_lat
  have hz3 : q.z ≥ 3 := by
    rcases h_valid with hc | ⟨hz2, hsum⟩
    · exact absurd hc hnc
    · cases hqz : q.z with
      | zero => rw [hqz] at hz2; omega
      | succ n =>
        cases n with
        | zero => rw [hqz] at hz2; omega
        | succ m =>
          cases m with
          | zero =>
            rw [hqz] at hsum
            dsimp [CoreAffectPoint.displacementSum, crownRadius] at hsum
            have hx0 : q.x ≠ 0 := by
              intro h; unfold CoreAffectPoint.classifyGeometry at h_lat
              simp [h] at h_lat
              split at h_lat <;> simp at h_lat
            have hy0 : q.y ≠ 0 := by
              intro h; unfold CoreAffectPoint.classifyGeometry at h_lat
              simp [h] at h_lat
              split at h_lat <;> simp at h_lat
            have hne : q.x.natAbs ≠ q.y.natAbs := by
              intro h; unfold CoreAffectPoint.classifyGeometry at h_lat
              simp [hx0, hy0, h] at h_lat
            omega
          | succ _ => omega
  exact canonicalDepthKernel_reaches_crown q h_valid hz3 hnc

/-- Clôture transitive des transitions pas-à-pas de poids non nul d'un noyau `DepthTransitionKernel`. -/
inductive DepthTransitionKernel.Reachable (K : DepthTransitionKernel) :
    CoreAffectPoint → CoreAffectPoint → Prop where
  | refl (p : CoreAffectPoint) : K.Reachable p p
  | step {p m q : CoreAffectPoint} :
      K.Reachable p m → K.weight m q ≠ 0 → K.Reachable p q

/--
Atteignabilité pas-à-pas (`1 → 2 → … → Z`) depuis la Surprise `(0, 0, 1)` vers toute position de
couronne valide, par récurrence sur la strate `Z = d + 2 ≥ 2` (Option 2a : cascades séquentielles).
-/
theorem canonicalDepthKernel_crown_from_surprise :
    ∀ (d : Nat) (q : CoreAffectPoint),
      isValidCoreAffect q → q.z = d + 2 → ¬q.isCentral →
      canonicalDepthKernel.Reachable ⟨0, 0, 1⟩ q := by
  intro d
  induction d with
  | zero =>
    intro q h_valid hz h_nc
    have hq0 : q.x ≠ 0 ∨ q.y ≠ 0 := by
      rcases (by omega : q.x = 0 ∨ q.x ≠ 0) with hx | hx
      · right; intro hy; exact h_nc ⟨hx, hy⟩
      · exact Or.inl hx
    have hw : canonicalDepthKernel.weight ⟨0, 0, 1⟩ q ≠ 0 := by
      unfold canonicalDepthKernel canonicalDepthWeight
      dsimp only
      have hvp : isValidCoreAffectB ⟨0, 0, 1⟩ = true := by decide
      have hvq : isValidCoreAffectB q = true := (isValidCoreAffectB_iff q).mpr h_valid
      have hzq : (q.z == 1 + 1) = true := beq_iff_eq.mpr hz
      have hqx0 : (q.x == 0 && q.y == 0) = false := by
        rcases hq0 with h | h <;> simp [beq_false_of_ne h]
      simp [hvp, hvq, hzq, hqx0]
    exact .step (.refl ⟨0, 0, 1⟩) hw
  | succ d ih =>
    intro q h_valid hz h_nc
    rcases canonicalDepthKernel_reaches_crown q h_valid (by omega) h_nc with ⟨p, hpv, hpz, hwpq⟩
    have hp_nc : ¬p.isCentral := by
      intro ⟨hpx, hpy⟩
      have hp_eq : (p.x == 0 && p.y == 0) = true := by simp [hpx, hpy]
      have hq_eq : (q.x == 0 && q.y == 0) = false := by
        apply Bool.eq_false_iff.mpr
        intro h
        simp only [Bool.and_eq_true, beq_iff_eq] at h
        exact h_nc h
      have hpz1 : (p.z == 1) = false := by
        have : p.z ≠ 1 := by omega
        exact beq_false_of_ne this
      have hzero : canonicalDepthKernel.weight p q = 0 := by
        unfold canonicalDepthKernel canonicalDepthWeight
        dsimp only
        rw [hq_eq]
        simp only [Bool.false_eq_true, ↓reduceIte, hp_eq, hpz1]
        split <;> rfl
      exact hwpq hzero
    exact .step (ih p hpv (by omega) hp_nc) hwpq

/--
Atteignabilité pas-à-pas depuis la Surprise `(0, 0, 1)` vers l'ensemble des positions latérales valides.
-/
theorem lateral_reachable_from_surprise (q : CoreAffectPoint)
    (h_valid : isValidCoreAffect q) (h_lat : q.classifyGeometry = .lateral) :
    canonicalDepthKernel.Reachable ⟨0, 0, 1⟩ q := by
  have hnc : ¬q.isCentral := by
    intro ⟨hx, hy⟩
    have hgeom : q.classifyGeometry = .central := by
      unfold CoreAffectPoint.classifyGeometry; simp [hx, hy]
    rw [hgeom] at h_lat; cases h_lat
  have hz2 : q.z ≥ 2 := by
    rcases h_valid with hc | hcr
    · exact absurd hc hnc
    · exact hcr.1
  exact canonicalDepthKernel_crown_from_surprise (q.z - 2) q h_valid (by omega) hnc

/--
Bifurcation canonique dans le quadrant d'affrontement agentique `(-X, +Y)` depuis la Colère `(-1, 1, 2)`
en strate `Z = 3` : vers la diagonale `(-2, 2, 3)` (poids 2) et les deux positions latérales
`(-1, 3, 3)` dans `sectorControlPos` (poids 1) et `(-3, 1, 3)` dans `sectorExpectationNeg` (poids 1).
-/
theorem canonicalDepthKernel_colere_bifurcates :
    canonicalDepthKernel.weight ⟨-1, 1, 2⟩ ⟨-2, 2, 3⟩ = 2 ∧
    canonicalDepthKernel.weight ⟨-1, 1, 2⟩ ⟨-1, 3, 3⟩ = 1 ∧
    canonicalDepthKernel.weight ⟨-1, 1, 2⟩ ⟨-3, 1, 3⟩ = 1 := by
  decide

/--
Formalisation exacte de P2 selon l'Option 3b (`DECISIONS_V3.md`, Arbitrage 3) :
1. L'instabilité axiale (`χ > 0` : poids diagonal strictement supérieur au maintien axial) porte
   **exclusivement sur les 2 pôles en Charge négative** :
   - `Peur (-2, 0, 2)` : poids `2` vers `(-2, 2, 3)` et `(-2, -2, 3)` contre `1` vers `(-4, 0, 3)` ;
   - `Tristesse (0, -2, 2)` : poids `2` vers `(2, -2, 3)` et `(-2, -2, 3)` contre `1` vers `(0, -4, 3)`.
2. Les **2 pôles en Décharge positive** (`Courage (2, 0, 2)` et `Joie (0, 2, 2)`) ne subissent
   aucune auto-déstabilisation croisée vers les diagonales à bruit nul (`poids = 0`), actant la
   brisure de symétrie dynamique Charge / Décharge face à la symétrie géométrique statique `antagonistPoint`.
-/
theorem canonicalDepthKernel_axial_instability_p2 :
    -- (1) Peur (-2, 0, 2) : instabilité axiale vers (-2, 2, 3) et (-2, -2, 3)
    (canonicalDepthKernel.weight ⟨-2, 0, 2⟩ ⟨-2, 2, 3⟩ > canonicalDepthKernel.weight ⟨-2, 0, 2⟩ ⟨-4, 0, 3⟩ ∧
     canonicalDepthKernel.weight ⟨-2, 0, 2⟩ ⟨-2, -2, 3⟩ > canonicalDepthKernel.weight ⟨-2, 0, 2⟩ ⟨-4, 0, 3⟩) ∧
    -- (2) Tristesse (0, -2, 2) : instabilité axiale vers (2, -2, 3) et (-2, -2, 3)
    (canonicalDepthKernel.weight ⟨0, -2, 2⟩ ⟨2, -2, 3⟩ > canonicalDepthKernel.weight ⟨0, -2, 2⟩ ⟨0, -4, 3⟩ ∧
     canonicalDepthKernel.weight ⟨0, -2, 2⟩ ⟨-2, -2, 3⟩ > canonicalDepthKernel.weight ⟨0, -2, 2⟩ ⟨0, -4, 3⟩) ∧
    -- (3) Courage (2, 0, 2) & Joie (0, 2, 2) : zéro auto-déstabilisation vers les diagonales à bruit nul
    (canonicalDepthKernel.weight ⟨2, 0, 2⟩ ⟨2, 2, 3⟩ = 0 ∧
     canonicalDepthKernel.weight ⟨2, 0, 2⟩ ⟨2, -2, 3⟩ = 0 ∧
     canonicalDepthKernel.weight ⟨0, 2, 2⟩ ⟨2, 2, 3⟩ = 0 ∧
     canonicalDepthKernel.weight ⟨0, 2, 2⟩ ⟨-2, 2, 3⟩ = 0) ∧
    -- (4) Brisure explicite de l'équivariance dynamique sous l'antagoniste statique
    (canonicalDepthKernel.weight ⟨-2, 0, 2⟩ ⟨-2, 2, 3⟩ ≠
     canonicalDepthKernel.weight (antagonistPoint ⟨-2, 0, 2⟩) (antagonistPoint ⟨-2, 2, 3⟩)) := by
  decide

/-!
## 5. Somme sortante discrète et normalisation rationnelle exacte
-/

private def intRange (k : Nat) : List Int :=
  (List.range (2 * k + 1)).map (fun (i : Nat) => (i : Int) - (k : Int))

private theorem mem_intRange {k : Nat} {v : Int} (hv : v.natAbs ≤ k) : v ∈ intRange k := by
  unfold intRange
  rw [List.mem_map]
  refine ⟨(v + (k : Int)).toNat, List.mem_range.mpr (by omega), by omega⟩

private def zBound (z : Nat) : Nat :=
  match z with
  | 0 => 0
  | 1 => 0
  | d + 2 => 2 * d + 2

private theorem valid_x_bound {q : CoreAffectPoint} (hv : isValidCoreAffect q) :
    q.x.natAbs ≤ zBound q.z := by
  rcases hv with ⟨hx0, _⟩ | ⟨hz2, hsum⟩
  · simp [hx0]
  · cases hqz : q.z with
    | zero => rw [hqz] at hz2; omega
    | succ n =>
      cases n with
      | zero => rw [hqz] at hz2; omega
      | succ d =>
        rw [hqz] at hsum
        dsimp [CoreAffectPoint.displacementSum, crownRadius] at hsum
        dsimp only [zBound]
        omega

private theorem valid_y_bound {q : CoreAffectPoint} (hv : isValidCoreAffect q) :
    q.y.natAbs ≤ zBound q.z := by
  rcases hv with ⟨_, hy0⟩ | ⟨hz2, hsum⟩
  · simp [hy0]
  · cases hqz : q.z with
    | zero => rw [hqz] at hz2; omega
    | succ n =>
      cases n with
      | zero => rw [hqz] at hz2; omega
      | succ d =>
        rw [hqz] at hsum
        dsimp [CoreAffectPoint.displacementSum, crownRadius] at hsum
        dsimp only [zBound]
        omega

/-- Liste finie de l'ensemble des points géométriquement valides de la strate `z`. -/
def stratumPoints (z : Nat) : List CoreAffectPoint :=
  ((intRange (zBound z)).flatMap fun x =>
    (intRange (zBound z)).map fun y => ⟨x, y, z⟩).filter isValidCoreAffectB

theorem mem_stratumPoints_of_valid (q : CoreAffectPoint) (hv : isValidCoreAffect q) :
    q ∈ stratumPoints q.z := by
  have hbx : q.x.natAbs ≤ zBound q.z := valid_x_bound hv
  have hby : q.y.natAbs ≤ zBound q.z := valid_y_bound hv
  rcases q with ⟨qx, qy, qz⟩
  dsimp only at hbx hby ⊢
  unfold stratumPoints
  rw [List.mem_filter]
  refine ⟨?_, (isValidCoreAffectB_iff _).mpr hv⟩
  rw [List.mem_flatMap]
  refine ⟨qx, mem_intRange hbx, ?_⟩
  rw [List.mem_map]
  exact ⟨qy, mem_intRange hby, rfl⟩

private theorem foldl_add_init (l : List Nat) (acc : Nat) :
    l.foldl (· + ·) acc = acc + l.foldl (· + ·) 0 := by
  induction l generalizing acc with
  | nil => simp
  | cons a t ih =>
    simp only [List.foldl_cons, Nat.zero_add]
    rw [ih (acc + a), ih a]
    omega

private theorem le_foldl_add_of_mem {α : Type} (f : α → Nat) {l : List α} {x : α} (hx : x ∈ l) :
    f x ≤ (l.map f).foldl (· + ·) 0 := by
  induction l with
  | nil => cases hx
  | cons a t ih =>
    simp only [List.map_cons, List.foldl_cons, Nat.zero_add]
    rw [foldl_add_init (t.map f) (f a)]
    cases List.mem_cons.mp hx with
    | inl h => subst h; omega
    | inr ht => have := ih ht; omega

/-- Poids sortant total d'un état `p` vers la strate suivante `p.z + 1`. -/
def DepthTransitionKernel.outgoingWeight (K : DepthTransitionKernel) (p : CoreAffectPoint) : Nat :=
  ((stratumPoints (p.z + 1)).map (K.weight p)).foldl (· + ·) 0

theorem DepthTransitionKernel.outgoingWeight_pos_of_witness (K : DepthTransitionKernel)
    {p q : CoreAffectPoint} (hw : K.weight p q ≠ 0) :
    K.outgoingWeight p > 0 := by
  have hv := K.support_valid p q hw
  have hadj := K.support_adjacent p q hw
  have hmem : q ∈ stratumPoints (p.z + 1) := by
    rw [← hadj]
    exact mem_stratumPoints_of_valid q hv
  have hle : K.weight p q ≤ K.outgoingWeight p :=
    le_foldl_add_of_mem (K.weight p) hmem
  omega

/--
Normalisation stricte du noyau canonique : tout état géométriquement valide `p` dispose
d'un poids sortant strictement positif (`outgoingWeight p > 0`).
-/
theorem canonicalDepthKernel_outgoingWeight_pos (p : CoreAffectPoint) (h : isValidCoreAffect p) :
    canonicalDepthKernel.outgoingWeight p > 0 := by
  rcases p with ⟨px, py, pz⟩
  by_cases hc : px = 0 ∧ py = 0
  · rcases hc with ⟨hx0, hy0⟩
    subst hx0 hy0
    exact canonicalDepthKernel.outgoingWeight_pos_of_witness (canonicalDepthWeight_pos_of_central pz)
  · have h_cr : CoreAffectPoint.isOnCrown ⟨px, py, pz⟩ := by
      rcases h with h0 | hcr
      · exact absurd h0 hc
      · exact hcr
    dsimp [CoreAffectPoint.isOnCrown, CoreAffectPoint.displacementSum] at h_cr
    rcases h_cr with ⟨hz2, hsum⟩
    cases pz with
    | zero => omega
    | succ n =>
      cases n with
      | zero => omega
      | succ d =>
        dsimp [crownRadius] at hsum
        by_cases hax : px = 0 ∨ py = 0
        · rcases hax with hx0 | hy0
          · subst hx0
            have hpy_nz : py ≠ 0 := fun h0 => hc ⟨rfl, h0⟩
            rcases (by omega : py > 0 ∨ py < 0) with hpos | hneg
            · have hqv : isValidCoreAffect ⟨0, Int.ofNat (2 * d + 4), d + 3⟩ :=
                Or.inr ⟨by dsimp only; omega, by dsimp [CoreAffectPoint.displacementSum, crownRadius]; omega⟩
              exact canonicalDepthKernel.outgoingWeight_pos_of_witness
                (canonicalDepthWeight_pos_of_axial_y py (Int.ofNat (2 * d + 4)) (d + 2)
                  h hqv hpy_nz (by change (↑(2 * d + 4) : Int) ≠ 0; omega)
                  (same_sign_mul_nonneg (Or.inl ⟨hpos, by change (↑(2 * d + 4) : Int) > 0; omega⟩)))
            · have hqv : isValidCoreAffect ⟨0, -Int.ofNat (2 * d + 4), d + 3⟩ :=
                Or.inr ⟨by dsimp only; omega, by
                  dsimp [CoreAffectPoint.displacementSum, crownRadius]
                  rw [Int.natAbs_neg]; omega⟩
              exact canonicalDepthKernel.outgoingWeight_pos_of_witness
                (canonicalDepthWeight_pos_of_axial_y py (-Int.ofNat (2 * d + 4)) (d + 2)
                  h hqv hpy_nz (by change -(↑(2 * d + 4) : Int) ≠ 0; omega)
                  (same_sign_mul_nonneg (Or.inr ⟨hneg, by change -(↑(2 * d + 4) : Int) < 0; omega⟩)))
          · subst hy0
            have hpx_nz : px ≠ 0 := fun h0 => hc ⟨h0, rfl⟩
            rcases (by omega : px > 0 ∨ px < 0) with hpos | hneg
            · have hqv : isValidCoreAffect ⟨Int.ofNat (2 * d + 4), 0, d + 3⟩ :=
                Or.inr ⟨by dsimp only; omega, by dsimp [CoreAffectPoint.displacementSum, crownRadius]; omega⟩
              exact canonicalDepthKernel.outgoingWeight_pos_of_witness
                (canonicalDepthWeight_pos_of_axial_x px (Int.ofNat (2 * d + 4)) (d + 2)
                  h hqv hpx_nz (by change (↑(2 * d + 4) : Int) ≠ 0; omega)
                  (same_sign_mul_nonneg (Or.inl ⟨hpos, by change (↑(2 * d + 4) : Int) > 0; omega⟩)))
            · have hqv : isValidCoreAffect ⟨-Int.ofNat (2 * d + 4), 0, d + 3⟩ :=
                Or.inr ⟨by dsimp only; omega, by
                  dsimp [CoreAffectPoint.displacementSum, crownRadius]
                  rw [Int.natAbs_neg]; omega⟩
              exact canonicalDepthKernel.outgoingWeight_pos_of_witness
                (canonicalDepthWeight_pos_of_axial_x px (-Int.ofNat (2 * d + 4)) (d + 2)
                  h hqv hpx_nz (by change -(↑(2 * d + 4) : Int) ≠ 0; omega)
                  (same_sign_mul_nonneg (Or.inr ⟨hneg, by change -(↑(2 * d + 4) : Int) < 0; omega⟩)))
        · have hpx_nz : px ≠ 0 := fun h0 => hax (Or.inl h0)
          have hpy_nz : py ≠ 0 := fun h0 => hax (Or.inr h0)
          let qx : Int := if px > 0 then px + 1 else px - 1
          let qy : Int := if py > 0 then py + 1 else py - 1
          have hqx_abs : qx.natAbs = px.natAbs + 1 := by dsimp only [qx]; split <;> omega
          have hqy_abs : qy.natAbs = py.natAbs + 1 := by dsimp only [qy]; split <;> omega
          have hqx_nz : qx ≠ 0 := by dsimp only [qx]; split <;> omega
          have hqy_nz : qy ≠ 0 := by dsimp only [qy]; split <;> omega
          have hmul_x : px * qx ≥ 0 := by
            apply same_sign_mul_nonneg
            dsimp only [qx]; split
            · rename_i hp; exact Or.inl ⟨hp, by omega⟩
            · rename_i hp; exact Or.inr ⟨by omega, by omega⟩
          have hmul_y : py * qy ≥ 0 := by
            apply same_sign_mul_nonneg
            dsimp only [qy]; split
            · rename_i hp; exact Or.inl ⟨hp, by omega⟩
            · rename_i hp; exact Or.inr ⟨by omega, by omega⟩
          have hqv : isValidCoreAffect ⟨qx, qy, d + 3⟩ :=
            Or.inr ⟨by dsimp only; omega, by dsimp [CoreAffectPoint.displacementSum, crownRadius]; omega⟩
          exact canonicalDepthKernel.outgoingWeight_pos_of_witness
            (canonicalDepthWeight_pos_of_nonaxial px py qx qy (d + 2)
              h hqv hpx_nz hpy_nz hqx_nz hqy_nz hmul_x hmul_y (by omega) (by omega))

/-!
## 6. Appartenance graduée aux 9 attracteurs fonctionnels (Résolution R1 & Option 1A)
-/

/--
Degré d'appartenance gradué d'un point `p : CoreAffectPoint` aux 9 groupes fonctionnels (`R1`, Option 1A),
sans modifier la partition géométrique stricte `taxonomy_group_exclusive`.
-/
def attractorMembership (p : CoreAffectPoint) (g : TaxonomicGroup) : Nat :=
  let ax := p.x.natAbs
  let ay := p.y.natAbs
  let r  := ax + ay
  let m  := if ax ≤ ay then ax else ay
  match g with
  | .centralOperator         => if p.x = 0 then (if p.y = 0 then 1 else 0) else 0
  | .sectorControlPos        => if p.y > 0 then (if ay > ax then r else ay) else 0
  | .sectorControlNeg        => if p.y < 0 then (if ay > ax then r else ay) else 0
  | .sectorExpectationPos    => if p.x > 0 then (if ax > ay then r else ax) else 0
  | .sectorExpectationNeg    => if p.x < 0 then (if ax > ay then r else ax) else 0
  | .diagonalSynergyPos      => if p.x > 0 then (if p.y > 0 then 2 * m else 0) else 0
  | .diagonalSynergyNeg      => if p.x < 0 then (if p.y < 0 then 2 * m else 0) else 0
  | .diagonalAgenticConfront => if p.x < 0 then (if p.y > 0 then 2 * m else 0) else 0
  | .diagonalAccommodation   => if p.x > 0 then (if p.y < 0 then 2 * m else 0) else 0

/-- Unicité stricte du maximum d'appartenance (décoder le maximum restitue `classifyTaxonomicGroup`). -/
theorem classifyTaxonomicGroup_unique_maximizer (p : CoreAffectPoint) (g : TaxonomicGroup)
    (h_ne : g ≠ classifyTaxonomicGroup p) :
    attractorMembership p g < attractorMembership p (classifyTaxonomicGroup p) := by
  unfold classifyTaxonomicGroup at h_ne ⊢
  repeat' split
  all_goals
    simp_all only [↓reduceIte, ne_eq]
    cases g <;> unfold attractorMembership <;> dsimp only <;> repeat' split
    all_goals first | exact absurd rfl h_ne | contradiction | omega

/-- Pour tout point `p` et tout groupe `g`, `classifyTaxonomicGroup p` maximise `attractorMembership`. -/
theorem classifyTaxonomicGroup_maximizes_membership (p : CoreAffectPoint) (g : TaxonomicGroup) :
    attractorMembership p g ≤ attractorMembership p (classifyTaxonomicGroup p) := by
  by_cases h : g = classifyTaxonomicGroup p
  · rw [h]; exact Nat.le_refl _
  · exact Nat.le_of_lt (classifyTaxonomicGroup_unique_maximizer p g h)

/--
Pour toute position latérale (`p.classifyGeometry = .lateral`), au moins deux groupes fonctionnels
distincts possèdent un degré d'appartenance `attractorMembership` strictement positif.
-/
theorem lateral_has_overlapping_attractors (p : CoreAffectPoint)
    (h_lat : p.classifyGeometry = .lateral) :
    ∃ g1 g2 : TaxonomicGroup,
      g1 ≠ g2 ∧ attractorMembership p g1 > 0 ∧ attractorMembership p g2 > 0 := by
  have hx0 : p.x ≠ 0 := by
    intro h; unfold CoreAffectPoint.classifyGeometry at h_lat
    simp [h] at h_lat; split at h_lat <;> cases h_lat
  have hy0 : p.y ≠ 0 := by
    intro h; unfold CoreAffectPoint.classifyGeometry at h_lat
    simp [h] at h_lat; split at h_lat <;> cases h_lat
  rcases (by omega : p.x > 0 ∨ p.x < 0) with hx | hx <;>
  rcases (by omega : p.y > 0 ∨ p.y < 0) with hy | hy
  · refine ⟨.sectorControlPos, .diagonalSynergyPos, by decide, ?_, ?_⟩ <;>
      (unfold attractorMembership; dsimp only; repeat' split) <;> omega
  · refine ⟨.sectorControlNeg, .diagonalAccommodation, by decide, ?_, ?_⟩ <;>
      (unfold attractorMembership; dsimp only; repeat' split) <;> omega
  · refine ⟨.sectorControlPos, .diagonalAgenticConfront, by decide, ?_, ?_⟩ <;>
      (unfold attractorMembership; dsimp only; repeat' split) <;> omega
  · refine ⟨.sectorControlNeg, .diagonalSynergyNeg, by decide, ?_, ?_⟩ <;>
      (unfold attractorMembership; dsimp only; repeat' split) <;> omega

end AffectiveDynamics

end Cartograffect
