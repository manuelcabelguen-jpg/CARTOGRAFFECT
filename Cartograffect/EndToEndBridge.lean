/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
Author: Manuel Cabelguen
-/

import Cartograffect.PredictiveEngine
import Cartograffect.CoreAffect
import Cartograffect.AffectiveMatrix
import Cartograffect.AffectiveTaxonomy
import Cartograffect.AffectiveDynamics
import Cartograffect.Lexicon176
import Cartograffect.PredictiveCircuit
import Cartograffect.OperantFactorization

namespace Cartograffect

namespace EndToEndBridge

open PredictiveEngine
open CoreAffect
open AffectiveMatrix
open AffectiveTaxonomy
open AffectiveDynamics
open Lexicon176
open PredictiveCircuit
open OperantFactorization

/-!
# Ponts formels complets de bout en bout (Strate 0)

Ce module soude formellement l'intégralité de la chaîne logique CARTOGRAFFECT® :
- Couche 0 : `PredictiveEngine` + `PredictiveCircuit` (circuit fermé à 6 opérateurs, noyau 9×9, loi unifiée) ;
- Couche 1 : `CoreAffect` (projection valide `(X, Y, Z)`, conservation `L1`, `apportionRay`) ;
- Couche 2 : `AffectiveMatrix` & `OperantFactorization` (`R+`, `R-`, `P+`, `P-` et pré-opérance axiale) ;
- Couche 3 : `AffectiveDynamics` (`canonicalDepthKernel`, P2 et persistance de quadrant) ;
- Couche 4 : `AffectiveTaxonomy` & `Lexicon176` (strates jusqu'aux Sentiments transcendantaux `Z = 7` et unicité nominale).
-/

/-!
## 1. Définitions canoniques des ponts opérants et pipelines terminaux
-/

/-- Rôle fonctionnel opérant d'une position affective dans l'espace `(X, Y, Z)`. -/
inductive OperantRole : Type where
  | centralOperator : OperantRole
  | preOperantAxial : OrientationSector → OperantRole
  | pureOperant     : OperantContingency → OperantRole
  | blendedLateral  : OrientationSector → OperantContingency → OperantRole
  deriving DecidableEq, Repr, Inhabited

/-- Contingence opérante induite par un couplage doublement engagé `(A, C)` du Moteur prédictif. -/
def couplingToContingency (c : EngineCoupling) : Option OperantContingency :=
  match c.attente, c.controle with
  | .pos, .pos => some ⟨.Reinforcement, .Addition⟩
  | .pos, .neg => some ⟨.Reinforcement, .Removal⟩
  | .neg, .neg => some ⟨.Punishment,    .Addition⟩
  | .neg, .pos => some ⟨.Punishment,    .Removal⟩
  | _,    _    => none

/-- Extension de la factorisation opérante aux quatre quadrants ouverts `(X ≠ 0, Y ≠ 0)` à toute strate `Z`. -/
def quadrantContingency (x y : Int) : Option OperantContingency :=
  if x > 0 ∧ y > 0 then some ⟨.Reinforcement, .Addition⟩
  else if x > 0 ∧ y < 0 then some ⟨.Reinforcement, .Removal⟩
  else if x < 0 ∧ y < 0 then some ⟨.Punishment,    .Addition⟩
  else if x < 0 ∧ y > 0 then some ⟨.Punishment,    .Removal⟩
  else none

/-- Classification du rôle opérant combinant quadrant `(R+, R-, P+, P-)` et secteur dominant. -/
def classifyOperantRole (p : CoreAffectPoint) : OperantRole :=
  match quadrantContingency p.x p.y, p.dominantSector? with
  | some c, some sec => .blendedLateral sec c
  | some c, none     => .pureOperant c
  | none,   some sec => .preOperantAxial sec
  | none,   none     => .centralOperator

/-- Évaluation complète reliant la loi unifiée `(R_t, Z_t, π_A, π_C)` à la Taxonomie terminale. -/
def evaluateUnifiedTaxonomy (p : UnifiedDynamicsParams) (c : EngineCoupling)
    (z rhoHat kappaHat : Nat) (susp : Bool) : TaxonomicState :=
  evaluateTaxonomy (evaluateMatrix (projectUnifiedState p c z rhoHat kappaHat susp) canonicalMapping)

/-- Évaluation complète reliant l'Opération 3 du circuit continu fermé à 6 opérateurs à la Taxonomie terminale. -/
def evaluateCircularTaxonomy (s : CircularCircuitState) : TaxonomicState :=
  evaluateTaxonomy (evaluateMatrix (op3_crossingI_perceptible s).2 canonicalMapping)

/-!
## 2. Lemmes auxiliaires (unicité nominale/spatiale, quadrants et arithmétique des signes)
-/

private theorem nodup_map_inj {α β : Type} (f : α → β) {l : List α}
    (hnodup : (l.map f).Nodup) {a b : α} (ha : a ∈ l) (hb : b ∈ l) (heq : f a = f b) :
    a = b := by
  induction l with
  | nil => cases ha
  | cons x xs ih =>
    simp only [List.map_cons, List.nodup_cons] at hnodup
    rcases hnodup with ⟨hx_not, hxs⟩
    rcases List.mem_cons.mp ha with rfl | ha' <;> rcases List.mem_cons.mp hb with rfl | hb'
    · rfl
    · exfalso; apply hx_not; rw [heq]; exact List.mem_map_of_mem hb'
    · exfalso; apply hx_not; rw [← heq]; exact List.mem_map_of_mem ha'
    · exact ih hxs ha' hb'

set_option maxRecDepth 2000000 in
set_option maxHeartbeats 4000000 in
/-- Lemme auxiliaire d'audit : les 176 étiquettes nominales de `all176Entries` sont deux à deux distinctes. -/
theorem all176Entries_unique_labels : (all176Entries.map (·.label)).Nodup := by
  decide

private theorem ofNat_ge1_pos (n : Nat) (hn : n ≥ 1) : (Int.ofNat n) > 0 := by
  change (n : Int) > 0
  omega

private theorem neg_ofNat_ge1_neg (n : Nat) (hn : n ≥ 1) : (- (Int.ofNat n)) < 0 := by
  change -(n : Int) < 0
  omega

private theorem quadrant_pos_pos {x y : Int} (hx : x > 0) (hy : y > 0) :
    quadrantContingency x y = some ⟨.Reinforcement, .Addition⟩ := by
  unfold quadrantContingency
  split
  · rfl
  · exfalso; omega

private theorem quadrant_pos_neg {x y : Int} (hx : x > 0) (hy : y < 0) :
    quadrantContingency x y = some ⟨.Reinforcement, .Removal⟩ := by
  unfold quadrantContingency
  split
  · exfalso; omega
  · split
    · rfl
    · exfalso; omega

private theorem quadrant_neg_neg {x y : Int} (hx : x < 0) (hy : y < 0) :
    quadrantContingency x y = some ⟨.Punishment, .Addition⟩ := by
  unfold quadrantContingency
  split
  · exfalso; omega
  · split
    · exfalso; omega
    · split
      · rfl
      · exfalso; omega

private theorem quadrant_neg_pos {x y : Int} (hx : x < 0) (hy : y > 0) :
    quadrantContingency x y = some ⟨.Punishment, .Removal⟩ := by
  unfold quadrantContingency
  split
  · exfalso; omega
  · split
    · exfalso; omega
    · split
      · exfalso; omega
      · split
        · rfl
        · exfalso; omega

private theorem quadrant_zero_left (y : Int) : quadrantContingency 0 y = none := by
  unfold quadrantContingency
  (repeat split) <;> first | rfl | (exfalso; omega)

private theorem quadrant_zero_right (x : Int) : quadrantContingency x 0 = none := by
  have h1 : ¬ (x > 0 ∧ (0 : Int) > 0) := by omega
  have h3 : ¬ (x < 0 ∧ (0 : Int) < 0) := by omega
  unfold quadrantContingency
  simp only [h1, h3, ↓reduceIte]

private theorem deploy_quadrant_eq (c : EngineCoupling) (d piA piC : Nat) :
    quadrantContingency (deployCouplingWithPrecision c d piA piC).x
      (deployCouplingWithPrecision c d piA piC).y = couplingToContingency c := by
  have hb := apportionRay_bounds d piA piC
  rcases h_eq : apportionRay d piA piC with ⟨ax, ay⟩
  rw [h_eq] at hb
  dsimp only at hb
  have hax_pos : (Int.ofNat ax) > 0 := ofNat_ge1_pos ax hb.1
  have hay_pos : (Int.ofNat ay) > 0 := ofNat_ge1_pos ay hb.2.1
  have hax_neg : (- (Int.ofNat ax)) < 0 := neg_ofNat_ge1_neg ax hb.1
  have hay_neg : (- (Int.ofNat ay)) < 0 := neg_ofNat_ge1_neg ay hb.2.1
  rcases c with ⟨a, ctrl⟩
  cases a <;> cases ctrl <;>
    simp only [deployCouplingWithPrecision, couplingToContingency, signedAmplitude, h_eq]
  · exact quadrant_neg_neg hax_neg hay_neg
  · exact quadrant_zero_right _
  · exact quadrant_neg_pos hax_neg hay_pos
  · exact quadrant_zero_left _
  · exact quadrant_zero_left _
  · exact quadrant_zero_left _
  · exact quadrant_pos_neg hax_pos hay_neg
  · exact quadrant_zero_right _
  · exact quadrant_pos_pos hax_pos hay_pos

private theorem projectPerceptible_neutral_quadrant (c : EngineCoupling)
    (hneut : c.isGlobalNeutrality = true) (z piA piC : Nat) (susp : Bool) :
    quadrantContingency (projectPerceptible c z piA piC susp).x
      (projectPerceptible c z piA piC susp).y = none := by
  unfold projectPerceptible
  split
  · split <;> exact quadrant_zero_left _
  · exact absurd hneut ‹_›

private theorem projectPerceptible_quadrant_eq (c : EngineCoupling) (d piA piC : Nat) (susp : Bool) :
    quadrantContingency (projectPerceptible c (d + 2) piA piC susp).x
      (projectPerceptible c (d + 2) piA piC susp).y = couplingToContingency c := by
  by_cases hneut : c.isGlobalNeutrality = true
  · have hnone : couplingToContingency c = none := by
      rcases c with ⟨a, ctrl⟩
      cases a <;> cases ctrl <;> first | rfl | exact absurd hneut (by decide)
    rw [hnone]
    exact projectPerceptible_neutral_quadrant c hneut (d + 2) piA piC susp
  · unfold projectPerceptible
    split
    · rename_i h; exact absurd h hneut
    · dsimp only
      exact deploy_quadrant_eq c d piA piC

private theorem int_mul_sign_pos {a b : Int}
    (h : (a > 0 ∧ b > 0) ∨ (a < 0 ∧ b < 0)) : a * b > 0 := by
  rcases h with ⟨ha, hb⟩ | ⟨ha, hb⟩
  · exact Int.mul_pos ha hb
  · exact Int.mul_pos_of_neg_of_neg ha hb

private theorem int_mul_sign_neg {a b : Int}
    (h : (a > 0 ∧ b < 0) ∨ (a < 0 ∧ b > 0)) : a * b < 0 := by
  rcases h with ⟨ha, hb⟩ | ⟨ha, hb⟩
  · exact Int.mul_neg_of_pos_of_neg ha hb
  · exact Int.mul_neg_of_neg_of_pos ha hb

private theorem hedonic_pos {x y : Int} (hx : x > 0) :
    computeHedonicPolarity x y = .positive := by
  unfold computeHedonicPolarity
  (repeat split) <;> first | rfl | (exfalso; omega)

private theorem hedonic_neg {x y : Int} (hx : x < 0) :
    computeHedonicPolarity x y = .negative := by
  unfold computeHedonicPolarity
  (repeat split) <;> first | rfl | (exfalso; omega)

private theorem energy_pos_pos {x y : Int} (hx : x > 0) (hy : y > 0) :
    computeEnergyRegime x y = .positiveSynergy := by
  have b1 : (x == 0 && y == 0) = false := by
    rw [beq_false_of_ne (by omega)]; rfl
  have b2 : (x == 0 || y == 0) = false := by
    rw [beq_false_of_ne (by omega), beq_false_of_ne (by omega)]; rfl
  have b3 : (decide (x > 0) && decide (y > 0)) = true := by
    rw [decide_eq_true hx, decide_eq_true hy]; rfl
  unfold computeEnergyRegime
  rw [b1, b2, b3]
  simp only [Bool.false_eq_true, ↓reduceIte]

private theorem energy_pos_neg {x y : Int} (hx : x > 0) (hy : y < 0) :
    computeEnergyRegime x y = .trophotropicRelease := by
  have b1 : (x == 0 && y == 0) = false := by
    rw [beq_false_of_ne (by omega)]; rfl
  have b2 : (x == 0 || y == 0) = false := by
    rw [beq_false_of_ne (by omega), beq_false_of_ne (by omega)]; rfl
  have b3 : (decide (x > 0) && decide (y > 0)) = false := by
    rw [decide_eq_true hx, decide_eq_false (by omega : ¬ (y > 0))]; rfl
  have b4 : (decide (x < 0) && decide (y < 0)) = false := by
    rw [decide_eq_false (by omega : ¬ (x < 0))]; rfl
  have b5 : (decide (x < 0) && decide (y > 0)) = false := by
    rw [decide_eq_false (by omega : ¬ (x < 0))]; rfl
  unfold computeEnergyRegime
  rw [b1, b2, b3, b4, b5]
  simp only [Bool.false_eq_true, ↓reduceIte]

private theorem energy_neg_pos {x y : Int} (hx : x < 0) (hy : y > 0) :
    computeEnergyRegime x y = .ergotropicCompensation := by
  have b1 : (x == 0 && y == 0) = false := by
    rw [beq_false_of_ne (by omega)]; rfl
  have b2 : (x == 0 || y == 0) = false := by
    rw [beq_false_of_ne (by omega), beq_false_of_ne (by omega)]; rfl
  have b3 : (decide (x > 0) && decide (y > 0)) = false := by
    rw [decide_eq_false (by omega : ¬ (x > 0))]; rfl
  have b4 : (decide (x < 0) && decide (y < 0)) = false := by
    rw [decide_eq_true hx, decide_eq_false (by omega : ¬ (y < 0))]; rfl
  have b5 : (decide (x < 0) && decide (y > 0)) = true := by
    rw [decide_eq_true hx, decide_eq_true hy]; rfl
  unfold computeEnergyRegime
  rw [b1, b2, b3, b4, b5]
  simp only [Bool.false_eq_true, ↓reduceIte]

private theorem energy_neg_neg {x y : Int} (hx : x < 0) (hy : y < 0) :
    computeEnergyRegime x y = .negativeSynergy := by
  have b1 : (x == 0 && y == 0) = false := by
    rw [beq_false_of_ne (by omega)]; rfl
  have b2 : (x == 0 || y == 0) = false := by
    rw [beq_false_of_ne (by omega), beq_false_of_ne (by omega)]; rfl
  have b3 : (decide (x > 0) && decide (y > 0)) = false := by
    rw [decide_eq_false (by omega : ¬ (x > 0))]; rfl
  have b4 : (decide (x < 0) && decide (y < 0)) = true := by
    rw [decide_eq_true hx, decide_eq_true hy]; rfl
  unfold computeEnergyRegime
  rw [b1, b2, b3, b4]
  simp only [Bool.false_eq_true, ↓reduceIte]

private theorem weight_pos_qx_nz {p q : CoreAffectPoint}
    (hx : p.x ≠ 0) (hy : p.y ≠ 0) (hw : canonicalDepthKernel.weight p q > 0) : q.x ≠ 0 := by
  intro hqx0
  dsimp only [canonicalDepthKernel, canonicalDepthWeight] at hw
  split at hw
  · split at hw
    · exfalso; simp_all [Bool.and_eq_true, beq_iff_eq]
    · split at hw
      · exfalso; simp_all [beq_iff_eq]
      · split at hw
        · rename_i h; rw [beq_false_of_ne hx, beq_false_of_ne hy] at h; cases h
        · split at hw
          · rename_i h
            rw [hqx0, (rfl : ((0 : Int) != 0) = false)] at h
            cases h
          · omega
  · omega

private theorem weight_pos_qy_nz {p q : CoreAffectPoint}
    (hx : p.x ≠ 0) (hy : p.y ≠ 0) (hw : canonicalDepthKernel.weight p q > 0) : q.y ≠ 0 := by
  intro hqy0
  dsimp only [canonicalDepthKernel, canonicalDepthWeight] at hw
  split at hw
  · split at hw
    · exfalso; simp_all [Bool.and_eq_true, beq_iff_eq]
    · split at hw
      · exfalso; simp_all [beq_iff_eq]
      · split at hw
        · rename_i h; rw [beq_false_of_ne hx, beq_false_of_ne hy] at h; cases h
        · split at hw
          · rename_i h
            rw [hqy0, (rfl : ((0 : Int) != 0) = false)] at h
            cases hqx : (q.x != 0) <;> rw [hqx] at h <;> cases h
          · omega
  · omega

/-!
## 3. Les 10 théorèmes de bout en bout (Strate 0 Hexa-Prouvée)
-/

/--
[1/10] Pont Circuit prédictif → Contingences opérantes `{R+, R-, P+, P-}` :
À la strate primaire `Z = 2`, `diagToContingency ∘ projectPerceptible` coïncide exactement avec
`couplingToContingency` ; pour toute couronne `Z = d + 2 ≥ 2`, `quadrantContingency` du point
projeté par `projectPerceptible` conserve identiquement `couplingToContingency c`.
-/
theorem circuit_coupling_operant_bridge
    (c : EngineCoupling) (d piA piC : Nat) (susp : Bool) :
    diagToContingency (projectPerceptible c 2 piA piC susp) = couplingToContingency c ∧
    quadrantContingency (projectPerceptible c (d + 2) piA piC susp).x
      (projectPerceptible c (d + 2) piA piC susp).y = couplingToContingency c := by
  constructor
  · by_cases hneut : c.isGlobalNeutrality = true
    · have hcz : c = ⟨.zero, .zero⟩ := by
        rcases c with ⟨a, ctrl⟩
        cases a <;> cases ctrl <;> first | rfl | exact absurd hneut (by decide)
      subst hcz
      unfold projectPerceptible
      dsimp only [EngineCoupling.isGlobalNeutrality, Polarity.isEngaged]
      cases susp <;> rfl
    · have hnn : c.isGlobalNeutrality = false := Bool.eq_false_iff.mpr hneut
      rw [projectPerceptible_z2_matches_phiL1 c hnn piA piC susp]
      rcases c with ⟨a, ctrl⟩
      cases a <;> cases ctrl <;> first | exact absurd hnn (by decide) | rfl
  · exact projectPerceptible_quadrant_eq c d piA piC susp

/--
[2/10] Pont Amorçage axial pré-opérant → Entrée dans l'espace opérant :
Depuis tout couplage axial unidimensionnel `c`, l'état initial en `Z = 2` est pré-opérant (`none`),
et le déclenchement d'un gradient secondaire saillant `newPol` projette exactement dans l'une des
4 contingences opérantes en préservant le type d'effet ou d'engagement du pôle axial d'origine.
-/
theorem triggerSecondaryGradient_enters_operant
    (c : EngineCoupling) (newPol : Polarity)
    (h_axial : c.isSingleEngaged = true) (h_salient : newPol.isEngaged = true) :
    let c' := triggerSecondaryGradient c newPol
    let p' := deployCouplingAtDepth c' 0
    diagToContingency (deployCouplingAtDepth c 0) = none ∧
    (∃ oc : OperantContingency,
      diagToContingency p' = some oc ∧
      couplingToContingency c' = some oc ∧
      (c = ⟨.pos, .zero⟩ → oc.effect = .Reinforcement) ∧
      (c = ⟨.neg, .zero⟩ → oc.effect = .Punishment) ∧
      (c = ⟨.zero, .pos⟩ → oc = ⟨.Reinforcement, .Addition⟩ ∨ oc = ⟨.Punishment, .Removal⟩) ∧
      (c = ⟨.zero, .neg⟩ → oc = ⟨.Reinforcement, .Removal⟩ ∨ oc = ⟨.Punishment, .Addition⟩)) := by
  rcases c with ⟨a, ctrl⟩
  cases a <;> cases ctrl <;> cases newPol <;>
    first
    | exact absurd h_axial (by decide)
    | exact absurd h_salient (by decide)
    | (dsimp only; exact ⟨rfl, ⟨_, rfl, rfl, fun _ => rfl,
        fun h => absurd h (by decide), fun h => absurd h (by decide), fun h => absurd h (by decide)⟩⟩)
    | (dsimp only; exact ⟨rfl, ⟨_, rfl, rfl, fun h => absurd h (by decide),
        fun _ => rfl, fun h => absurd h (by decide), fun h => absurd h (by decide)⟩⟩)
    | (dsimp only; exact ⟨rfl, ⟨_, rfl, rfl, fun h => absurd h (by decide),
        fun h => absurd h (by decide), fun _ => Or.inl rfl, fun h => absurd h (by decide)⟩⟩)
    | (dsimp only; exact ⟨rfl, ⟨_, rfl, rfl, fun h => absurd h (by decide),
        fun h => absurd h (by decide), fun _ => Or.inr rfl, fun h => absurd h (by decide)⟩⟩)
    | (dsimp only; exact ⟨rfl, ⟨_, rfl, rfl, fun h => absurd h (by decide),
        fun h => absurd h (by decide), fun h => absurd h (by decide), fun _ => Or.inl rfl⟩⟩)
    | (dsimp only; exact ⟨rfl, ⟨_, rfl, rfl, fun h => absurd h (by decide),
        fun h => absurd h (by decide), fun h => absurd h (by decide), fun _ => Or.inr rfl⟩⟩)

/--
[3/10] Pont Noyau Markovien (P2) → Bifurcation punitive `{P-, P+}` :
Sous les hypothèses exactes de contagion croisée P2 (`chi > 0`), la Peur `(A-, C0)` (pré-opérante)
transitionne avec poids strictement positif vers la Colère `(A-, C+)` (`P-`) et le Dégoût `(A-, C-)` (`P+`).
-/
theorem p2_markov_contagion_enters_operant_punishment (p : CircuitKernelParams)
    (h_chi : p.chi > 0) (h_q_pos : p.qPosC > 0) (h_q_lt : p.qPosC < p.scale)
    (h_stay : p.rho + p.deltaA < p.scale) :
    circuitWeight p ⟨.neg, .zero⟩ ⟨.neg, .pos⟩ > 0 ∧
    circuitWeight p ⟨.neg, .zero⟩ ⟨.neg, .neg⟩ > 0 ∧
    couplingToContingency ⟨.neg, .zero⟩ = none ∧
    couplingToContingency ⟨.neg, .pos⟩ = some ⟨.Punishment, .Removal⟩ ∧
    couplingToContingency ⟨.neg, .neg⟩ = some ⟨.Punishment, .Addition⟩ := by
  have hb := axial_peur_bifurcates_p2 p h_chi h_q_pos h_q_lt h_stay
  exact ⟨hb.1, hb.2, rfl, rfl, rfl⟩

/--
[4/10] Relèvement universel de la factorisation opérante sur toutes les strates `Z ∈ ℕ` :
Tout point hors des axes (`x ≠ 0 ∧ y ≠ 0`) à n'importe quelle profondeur `Z` (y compris les 120
états latéraux et les sentiments `Z = 4..7`) possède une contingence opérante unique induite par
ses signes, en accord exact avec la valence lexicographique, les régimes énergétiques et `diagToContingency` en `Z = 2`.
-/
theorem operant_quadrant_lifting_all_strata (p : CoreAffectPoint)
    (hx : p.x ≠ 0) (hy : p.y ≠ 0) :
    (∃ oc : OperantContingency,
      quadrantContingency p.x p.y = some oc ∧
      (oc.effect = .Reinforcement ↔ p.x > 0) ∧
      (oc.effect = .Punishment ↔ p.x < 0) ∧
      (oc.op = .Addition ↔ p.x * p.y > 0) ∧
      (oc.op = .Removal ↔ p.x * p.y < 0) ∧
      (computeHedonicPolarity p.x p.y = .positive ↔ oc.effect = .Reinforcement) ∧
      (oc.op = .Addition ↔
        computeEnergyRegime p.x p.y = .positiveSynergy ∨
        computeEnergyRegime p.x p.y = .negativeSynergy) ∧
      (oc.op = .Removal ↔
        computeEnergyRegime p.x p.y = .ergotropicCompensation ∨
        computeEnergyRegime p.x p.y = .trophotropicRelease)) ∧
    (∀ q ∈ z2DiagonalPoints, quadrantContingency q.x q.y = diagToContingency q) := by
  constructor
  · rcases (by omega : p.x > 0 ∨ p.x < 0) with hxp | hxn <;>
    rcases (by omega : p.y > 0 ∨ p.y < 0) with hyp | hyn
    · have hmul : p.x * p.y > 0 := int_mul_sign_pos (Or.inl ⟨hxp, hyp⟩)
      have hpol := hedonic_pos (y := p.y) hxp
      have her := energy_pos_pos hxp hyp
      refine ⟨⟨.Reinforcement, .Addition⟩, quadrant_pos_pos hxp hyp,
        ⟨(fun _ => hxp), (fun _ => rfl)⟩,
        ⟨(fun h => by cases h), (fun h => by omega)⟩,
        ⟨(fun _ => hmul), (fun _ => rfl)⟩,
        ⟨(fun h => by cases h), (fun h => by omega)⟩,
        ⟨(fun _ => rfl), (fun _ => hpol)⟩,
        ⟨(fun _ => Or.inl her), (fun _ => rfl)⟩,
        ⟨(fun h => by cases h), (fun h => by rcases h with h | h <;> rw [her] at h <;> cases h)⟩⟩
    · have hmul : p.x * p.y < 0 := int_mul_sign_neg (Or.inl ⟨hxp, hyn⟩)
      have hpol := hedonic_pos (y := p.y) hxp
      have her := energy_pos_neg hxp hyn
      refine ⟨⟨.Reinforcement, .Removal⟩, quadrant_pos_neg hxp hyn,
        ⟨(fun _ => hxp), (fun _ => rfl)⟩,
        ⟨(fun h => by cases h), (fun h => by omega)⟩,
        ⟨(fun h => by cases h), (fun h => by omega)⟩,
        ⟨(fun _ => hmul), (fun _ => rfl)⟩,
        ⟨(fun _ => rfl), (fun _ => hpol)⟩,
        ⟨(fun h => by cases h), (fun h => by rcases h with h | h <;> rw [her] at h <;> cases h)⟩,
        ⟨(fun _ => Or.inr her), (fun _ => rfl)⟩⟩
    · have hmul : p.x * p.y < 0 := int_mul_sign_neg (Or.inr ⟨hxn, hyp⟩)
      have hpol := hedonic_neg (y := p.y) hxn
      have her := energy_neg_pos hxn hyp
      refine ⟨⟨.Punishment, .Removal⟩, quadrant_neg_pos hxn hyp,
        ⟨(fun h => by cases h), (fun h => by omega)⟩,
        ⟨(fun _ => hxn), (fun _ => rfl)⟩,
        ⟨(fun h => by cases h), (fun h => by omega)⟩,
        ⟨(fun _ => hmul), (fun _ => rfl)⟩,
        ⟨(fun h => by rw [hpol] at h; cases h), (fun h => by cases h)⟩,
        ⟨(fun h => by cases h), (fun h => by rcases h with h | h <;> rw [her] at h <;> cases h)⟩,
        ⟨(fun _ => Or.inl her), (fun _ => rfl)⟩⟩
    · have hmul : p.x * p.y > 0 := int_mul_sign_pos (Or.inr ⟨hxn, hyn⟩)
      have hpol := hedonic_neg (y := p.y) hxn
      have her := energy_neg_neg hxn hyn
      refine ⟨⟨.Punishment, .Addition⟩, quadrant_neg_neg hxn hyn,
        ⟨(fun h => by cases h), (fun h => by omega)⟩,
        ⟨(fun _ => hxn), (fun _ => rfl)⟩,
        ⟨(fun _ => hmul), (fun _ => rfl)⟩,
        ⟨(fun h => by cases h), (fun h => by omega)⟩,
        ⟨(fun h => by rw [hpol] at h; cases h), (fun h => by cases h)⟩,
        ⟨(fun _ => Or.inr her), (fun _ => rfl)⟩,
        ⟨(fun h => by cases h), (fun h => by rcases h with h | h <;> rw [her] at h <;> cases h)⟩⟩
  · decide

/--
[5/10] Invariance antagoniste opérante sur toutes les strates `Z ∈ ℕ` :
Sur tout point non axial (diagonales ET les 120 états latéraux), `antagonistPoint` inverse
l'effet (`Reinforcement ↔ Punishment`) tout en conservant exactement l'opérateur écologique
(`Addition` ou `Removal`).
-/
theorem operant_antagonist_invariance_all_strata (p : CoreAffectPoint)
    (hx : p.x ≠ 0) (hy : p.y ≠ 0) :
    ∃ c1 c2 : OperantContingency,
      quadrantContingency p.x p.y = some c1 ∧
      quadrantContingency (antagonistPoint p).x (antagonistPoint p).y = some c2 ∧
      c1.effect ≠ c2.effect ∧ c1.op = c2.op := by
  rcases (by omega : p.x > 0 ∨ p.x < 0) with hxp | hxn <;>
  rcases (by omega : p.y > 0 ∨ p.y < 0) with hyp | hyn
  · refine ⟨⟨.Reinforcement, .Addition⟩, ⟨.Punishment, .Addition⟩,
      quadrant_pos_pos hxp hyp, ?_, by decide, rfl⟩
    unfold antagonistPoint; split
    · dsimp only; exact quadrant_neg_neg (by omega) (by omega)
    · split
      · omega
      · dsimp only; exact quadrant_neg_neg (by omega) (by omega)
  · refine ⟨⟨.Reinforcement, .Removal⟩, ⟨.Punishment, .Removal⟩,
      quadrant_pos_neg hxp hyn, ?_, by decide, rfl⟩
    unfold antagonistPoint; split
    · dsimp only; exact quadrant_neg_pos (by omega) (by omega)
    · split
      · dsimp only; exact quadrant_neg_pos (by omega) (by omega)
      · dsimp only; exact quadrant_neg_pos (by omega) (by omega)
  · refine ⟨⟨.Punishment, .Removal⟩, ⟨.Reinforcement, .Removal⟩,
      quadrant_neg_pos hxn hyp, ?_, by decide, rfl⟩
    unfold antagonistPoint; split
    · dsimp only; exact quadrant_pos_neg (by omega) (by omega)
    · split
      · dsimp only; exact quadrant_pos_neg (by omega) (by omega)
      · dsimp only; exact quadrant_pos_neg (by omega) (by omega)
  · refine ⟨⟨.Punishment, .Addition⟩, ⟨.Reinforcement, .Addition⟩,
      quadrant_neg_neg hxn hyn, ?_, by decide, rfl⟩
    unfold antagonistPoint; split
    · dsimp only; exact quadrant_pos_pos (by omega) (by omega)
    · split
      · omega
      · dsimp only; exact quadrant_pos_pos (by omega) (by omega)

/--
[6/10] Pont Dynamique inter-strates ↔ Opérants (`canonicalDepthKernel`) :
- (a) Toute transition `p → q` de poids non nul depuis un état opérant (`x ≠ 0, y ≠ 0`) conserve
  strictement l'appartenance hors axes et le quadrant opérant `quadrantContingency` ;
- (b) Les 4 pôles axiaux pré-opérants en `Z = 2` amorcent exactement leur paire de contingences opérantes en `Z = 3`.
-/
theorem depthKernel_preserves_operant_quadrant :
    (∀ p q : CoreAffectPoint, p.x ≠ 0 → p.y ≠ 0 →
      canonicalDepthKernel.weight p q > 0 →
      q.x ≠ 0 ∧ q.y ≠ 0 ∧ quadrantContingency q.x q.y = quadrantContingency p.x p.y) ∧
    (canonicalDepthKernel.weight ⟨2, 0, 2⟩ ⟨2, 2, 3⟩ > 0 ∧
     canonicalDepthKernel.weight ⟨2, 0, 2⟩ ⟨2, -2, 3⟩ > 0 ∧
     canonicalDepthKernel.weight ⟨-2, 0, 2⟩ ⟨-2, 2, 3⟩ > 0 ∧
     canonicalDepthKernel.weight ⟨-2, 0, 2⟩ ⟨-2, -2, 3⟩ > 0 ∧
     canonicalDepthKernel.weight ⟨0, 2, 2⟩ ⟨2, 2, 3⟩ > 0 ∧
     canonicalDepthKernel.weight ⟨0, 2, 2⟩ ⟨-2, 2, 3⟩ > 0 ∧
     canonicalDepthKernel.weight ⟨0, -2, 2⟩ ⟨2, -2, 3⟩ > 0 ∧
     canonicalDepthKernel.weight ⟨0, -2, 2⟩ ⟨-2, -2, 3⟩ > 0) := by
  refine ⟨?_, by decide⟩
  intro p q hx hy hw
  have hquad := canonicalDepthKernel.quadrant_preserved p q (by omega)
  rcases hquad with ⟨hmul_x, hmul_y⟩
  have hqx_nz : q.x ≠ 0 := weight_pos_qx_nz hx hy hw
  have hqy_nz : q.y ≠ 0 := weight_pos_qy_nz hx hy hw
  refine ⟨hqx_nz, hqy_nz, ?_⟩
  rcases (by omega : p.x > 0 ∨ p.x < 0) with hxp | hxn <;>
  rcases (by omega : p.y > 0 ∨ p.y < 0) with hyp | hyn
  · have hqx : q.x > 0 := by
      rcases (by omega : q.x > 0 ∨ q.x < 0) with hq1 | hq1
      · exact hq1
      · have := int_mul_sign_neg (Or.inl ⟨hxp, hq1⟩); omega
    have hqy : q.y > 0 := by
      rcases (by omega : q.y > 0 ∨ q.y < 0) with hq2 | hq2
      · exact hq2
      · have := int_mul_sign_neg (Or.inl ⟨hyp, hq2⟩); omega
    rw [quadrant_pos_pos hqx hqy, quadrant_pos_pos hxp hyp]
  · have hqx : q.x > 0 := by
      rcases (by omega : q.x > 0 ∨ q.x < 0) with hq1 | hq1
      · exact hq1
      · have := int_mul_sign_neg (Or.inl ⟨hxp, hq1⟩); omega
    have hqy : q.y < 0 := by
      rcases (by omega : q.y > 0 ∨ q.y < 0) with hq2 | hq2
      · have := int_mul_sign_neg (Or.inr ⟨hyn, hq2⟩); omega
      · exact hq2
    rw [quadrant_pos_neg hqx hqy, quadrant_pos_neg hxp hyn]
  · have hqx : q.x < 0 := by
      rcases (by omega : q.x > 0 ∨ q.x < 0) with hq1 | hq1
      · have := int_mul_sign_neg (Or.inr ⟨hxn, hq1⟩); omega
      · exact hq1
    have hqy : q.y > 0 := by
      rcases (by omega : q.y > 0 ∨ q.y < 0) with hq2 | hq2
      · exact hq2
      · have := int_mul_sign_neg (Or.inl ⟨hyp, hq2⟩); omega
    rw [quadrant_neg_pos hqx hqy, quadrant_neg_pos hxn hyp]
  · have hqx : q.x < 0 := by
      rcases (by omega : q.x > 0 ∨ q.x < 0) with hq1 | hq1
      · have := int_mul_sign_neg (Or.inr ⟨hxn, hq1⟩); omega
      · exact hq1
    have hqy : q.y < 0 := by
      rcases (by omega : q.y > 0 ∨ q.y < 0) with hq2 | hq2
      · have := int_mul_sign_neg (Or.inr ⟨hyn, hq2⟩); omega
      · exact hq2
    rw [quadrant_neg_neg hqx hqy, quadrant_neg_neg hxn hyn]

/--
[7/10] Lignées opérantes complètes `Z = 2 → Z = 7` (Sentiments transcendantaux) :
Chacune des 4 contingences `{R+, R-, P+, P-}` engendre une chaîne ininterrompue de poids maximal `2`
sous `canonicalDepthKernel` depuis son prototype `Z = 2` (`Désir`, `Calme`, `Dégoût`, `Colère`)
jusqu'à son sentiment transcendantal terminal en `Z = 7` (`Sublimation`, `Impassibilité`, `Dissolution`, `Rage`)
au sein de `all176Entries`, en conservant rôle opérant, groupe et sous-secteur.
-/
theorem operant_lineages_reach_z7_transcendentals :
    -- R+ : Désir (1,1,2) -> ... -> Sublimation (6,6,7)
    (canonicalDepthKernel.weight ⟨1, 1, 2⟩ ⟨2, 2, 3⟩ = 2 ∧
     canonicalDepthKernel.weight ⟨2, 2, 3⟩ ⟨3, 3, 4⟩ = 2 ∧
     canonicalDepthKernel.weight ⟨3, 3, 4⟩ ⟨4, 4, 5⟩ = 2 ∧
     canonicalDepthKernel.weight ⟨4, 4, 5⟩ ⟨5, 5, 6⟩ = 2 ∧
     canonicalDepthKernel.weight ⟨5, 5, 6⟩ ⟨6, 6, 7⟩ = 2 ∧
     classifyOperantRole ⟨6, 6, 7⟩ = .pureOperant ⟨.Reinforcement, .Addition⟩ ∧
     classifyStratum 7 = .z7_sentimentsTranscendants ∧
     classifyTaxonomicGroup ⟨6, 6, 7⟩ = .groupeDesir ∧
     classifySubsector 6 6 = .diagonalDesire ∧
     (⟨"Sublimation", ⟨6, 6, 7⟩⟩ : LexiconEntry) ∈ all176Entries) ∧
    -- R- : Calme (1,-1,2) -> ... -> Impassibilité (6,-6,7)
    (canonicalDepthKernel.weight ⟨1, -1, 2⟩ ⟨2, -2, 3⟩ = 2 ∧
     canonicalDepthKernel.weight ⟨2, -2, 3⟩ ⟨3, -3, 4⟩ = 2 ∧
     canonicalDepthKernel.weight ⟨3, -3, 4⟩ ⟨4, -4, 5⟩ = 2 ∧
     canonicalDepthKernel.weight ⟨4, -4, 5⟩ ⟨5, -5, 6⟩ = 2 ∧
     canonicalDepthKernel.weight ⟨5, -5, 6⟩ ⟨6, -6, 7⟩ = 2 ∧
     classifyOperantRole ⟨6, -6, 7⟩ = .pureOperant ⟨.Reinforcement, .Removal⟩ ∧
     classifyStratum 7 = .z7_sentimentsTranscendants ∧
     classifyTaxonomicGroup ⟨6, -6, 7⟩ = .groupeCalme ∧
     classifySubsector 6 (-6) = .diagonalCalm ∧
     (⟨"Impassibilité", ⟨6, -6, 7⟩⟩ : LexiconEntry) ∈ all176Entries) ∧
    -- P+ : Dégoût (-1,-1,2) -> ... -> Dissolution (-6,-6,7)
    (canonicalDepthKernel.weight ⟨-1, -1, 2⟩ ⟨-2, -2, 3⟩ = 2 ∧
     canonicalDepthKernel.weight ⟨-2, -2, 3⟩ ⟨-3, -3, 4⟩ = 2 ∧
     canonicalDepthKernel.weight ⟨-3, -3, 4⟩ ⟨-4, -4, 5⟩ = 2 ∧
     canonicalDepthKernel.weight ⟨-4, -4, 5⟩ ⟨-5, -5, 6⟩ = 2 ∧
     canonicalDepthKernel.weight ⟨-5, -5, 6⟩ ⟨-6, -6, 7⟩ = 2 ∧
     classifyOperantRole ⟨-6, -6, 7⟩ = .pureOperant ⟨.Punishment, .Addition⟩ ∧
     classifyStratum 7 = .z7_sentimentsTranscendants ∧
     classifyTaxonomicGroup ⟨-6, -6, 7⟩ = .groupeDegout ∧
     classifySubsector (-6) (-6) = .diagonalDisgust ∧
     (⟨"Dissolution", ⟨-6, -6, 7⟩⟩ : LexiconEntry) ∈ all176Entries) ∧
    -- P- : Colère (-1,1,2) -> ... -> Rage (-6,6,7)
    (canonicalDepthKernel.weight ⟨-1, 1, 2⟩ ⟨-2, 2, 3⟩ = 2 ∧
     canonicalDepthKernel.weight ⟨-2, 2, 3⟩ ⟨-3, 3, 4⟩ = 2 ∧
     canonicalDepthKernel.weight ⟨-3, 3, 4⟩ ⟨-4, 4, 5⟩ = 2 ∧
     canonicalDepthKernel.weight ⟨-4, 4, 5⟩ ⟨-5, 5, 6⟩ = 2 ∧
     canonicalDepthKernel.weight ⟨-5, 5, 6⟩ ⟨-6, 6, 7⟩ = 2 ∧
     classifyOperantRole ⟨-6, 6, 7⟩ = .pureOperant ⟨.Punishment, .Removal⟩ ∧
     classifyStratum 7 = .z7_sentimentsTranscendants ∧
     classifyTaxonomicGroup ⟨-6, 6, 7⟩ = .groupeColere ∧
     classifySubsector (-6) 6 = .diagonalAnger ∧
     (⟨"Rage", ⟨-6, 6, 7⟩⟩ : LexiconEntry) ∈ all176Entries) := by
  decide

private theorem projectPerceptible_z_le (c : EngineCoupling) (z piA piC : Nat) (susp : Bool) :
    (projectPerceptible c z piA piC susp).z ≤ z := by
  unfold projectPerceptible
  split
  · split <;> simp
  · cases z with
    | zero => simp
    | succ n =>
      cases n with
      | zero => simp
      | succ d =>
        rcases c with ⟨a, ctrl⟩
        cases a <;> cases ctrl <;> simp [deployCouplingWithPrecision]

/--
[8/10] Cohérence complète de la loi unifiée `(R_t, Z_t, π_A, π_C)` vers la Taxonomie,
les opérants et le Lexique 176.
-/
theorem unified_circuit_to_taxonomy_coherence
    (p : UnifiedDynamicsParams) (c : EngineCoupling)
    (z rhoHat kappaHat : Nat) (susp : Bool) :
    let ts := evaluateUnifiedTaxonomy p c z rhoHat kappaHat susp
    let cp := ts.matrix.core.point
    let ap := ts.matrix.antagonist.point
    isValidCoreAffect cp ∧
    isValidCoreAffect ap ∧
    ts.stratum = classifyStratum cp.z ∧
    matchesTaxonomicGroup cp ts.group ∧
    ts.subsector.toTaxonomicGroup = ts.group ∧
    ts.subsector.toHedonicPolarity = ts.matrix.valence ∧
    (z ≥ 2 → quadrantContingency cp.x cp.y = couplingToContingency c) ∧
    (z ≤ 7 → cp ∈ all176Entries.map (·.point) ∧ ap ∈ all176Entries.map (·.point)) := by
  dsimp only [evaluateUnifiedTaxonomy, evaluateTaxonomy, evaluateMatrix, canonicalMapping]
  have hvc : isValidCoreAffect (projectUnifiedState p c z rhoHat kappaHat susp).point :=
    projectUnifiedState_valid p c z rhoHat kappaHat susp
  have hva : isValidCoreAffect (antagonistPoint (projectUnifiedState p c z rhoHat kappaHat susp).point) :=
    antagonistPoint_preserves_validity _ hvc
  refine ⟨hvc, hva, rfl, classifyTaxonomicGroup_correct _, classifySubsector_refines_group _,
    classifySubsector_determines_valence _ _, ?_, ?_⟩
  · intro hz
    cases hzs : z with
    | zero => omega
    | succ n =>
      cases n with
      | zero => omega
      | succ d =>
        dsimp only [projectUnifiedState, projectPerceptibleState]
        exact projectPerceptible_quadrant_eq c d
          (precisionShares p rhoHat kappaHat c).1 (precisionShares p rhoHat kappaHat c).2 susp
  · intro hz7
    have hcz : (projectUnifiedState p c z rhoHat kappaHat susp).point.z ≤ 7 := by
      have hle := projectPerceptible_z_le c z
        (precisionShares p rhoHat kappaHat c).1 (precisionShares p rhoHat kappaHat c).2 susp
      exact Nat.le_trans hle hz7
    have haz : (antagonistPoint (projectUnifiedState p c z rhoHat kappaHat susp).point).z ≤ 7 := by
      rw [antagonistPoint_preserves_z]
      exact hcz
    exact ⟨all176Entries_spatial_completeness _ hcz hvc,
           all176Entries_spatial_completeness _ haz hva⟩

private theorem op3_point_engaged_quadrant (s : CircularCircuitState)
    (heng : s.attentional.isEngaged = true) :
    quadrantContingency (op3_crossingI_perceptible s).2.point.x
      (op3_crossingI_perceptible s).2.point.y =
      couplingToContingency ⟨op1_subjectiveOut s, op2_perceptiveOut s⟩ := by
  dsimp only [op3_crossingI_perceptible, projectPerceptibleState]
  by_cases hneut : (⟨op1_subjectiveOut s, op2_perceptiveOut s⟩ : EngineCoupling).isGlobalNeutrality = true
  · have hnone : couplingToContingency ⟨op1_subjectiveOut s, op2_perceptiveOut s⟩ = none := by
      cases hx1 : op1_subjectiveOut s <;> cases hx2 : op2_perceptiveOut s <;>
        first | rfl | (exfalso; rw [hx1, hx2] at hneut; exact absurd hneut (by decide))
    rw [hnone]
    exact projectPerceptible_neutral_quadrant _ hneut _ _ _ _
  · split
    · rename_i h; exact absurd h hneut
    · split
      · rename_i h; exfalso; rw [heng] at h; cases h
      · exact projectPerceptible_quadrant_eq _ s.attentional.persistenceDepth
          s.attentional.precisionA s.attentional.precisionC s.subjectiveHidden.descendingSuspension

private theorem op3_point_z_le (s : CircularCircuitState)
    (hd : s.attentional.persistenceDepth ≤ 5) :
    (op3_crossingI_perceptible s).2.point.z ≤ 7 := by
  dsimp only [op3_crossingI_perceptible, projectPerceptibleState]
  have hz_le : (if (⟨op1_subjectiveOut s, op2_perceptiveOut s⟩ : EngineCoupling).isGlobalNeutrality then
      if s.subjectiveHidden.descendingSuspension then s.attentional.persistenceDepth + 2 else 0
    else if !s.attentional.isEngaged then
      if s.subjectiveHidden.descendingSuspension then s.attentional.persistenceDepth + 2 else 1
    else
      s.attentional.persistenceDepth + 2) ≤ 7 := by
    split
    · split <;> omega
    · split
      · split <;> omega
      · omega
  exact Nat.le_trans (projectPerceptible_z_le _ _ _ _ _) hz_le

/--
[9/10] Cohérence complète du circuit continu fermé à 6 opérateurs (`CircularCircuitState`)
vers la Taxonomie, les opérants et le Lexique 176.
-/
theorem circularCycle_to_taxonomy_and_lexicon_coherence (s : CircularCircuitState) :
    let ts := evaluateCircularTaxonomy s
    let cp := ts.matrix.core.point
    let ap := ts.matrix.antagonist.point
    let c : EngineCoupling := ⟨op1_subjectiveOut s, op2_perceptiveOut s⟩
    isValidCoreAffect cp ∧
    isValidCoreAffect ap ∧
    matchesTaxonomicGroup cp ts.group ∧
    ts.subsector.toTaxonomicGroup = ts.group ∧
    ts.subsector.toHedonicPolarity = ts.matrix.valence ∧
    (s.attentional.isEngaged = true → quadrantContingency cp.x cp.y = couplingToContingency c) ∧
    (s.attentional.persistenceDepth ≤ 5 →
      cp.z ≤ 7 ∧ cp ∈ all176Entries.map (·.point) ∧ ap ∈ all176Entries.map (·.point)) := by
  dsimp only [evaluateCircularTaxonomy, evaluateTaxonomy, evaluateMatrix, canonicalMapping]
  have hvc : isValidCoreAffect (op3_crossingI_perceptible s).2.point :=
    (op3_crossingI_perceptible s).2.h_valid
  have hva : isValidCoreAffect (antagonistPoint (op3_crossingI_perceptible s).2.point) :=
    antagonistPoint_preserves_validity _ hvc
  refine ⟨hvc, hva, classifyTaxonomicGroup_correct _, classifySubsector_refines_group _,
    classifySubsector_determines_valence _ _, op3_point_engaged_quadrant s, ?_⟩
  intro hd
  have hcz : (op3_crossingI_perceptible s).2.point.z ≤ 7 := op3_point_z_le s hd
  have haz : (antagonistPoint (op3_crossingI_perceptible s).2.point).z ≤ 7 := by
    rw [antagonistPoint_preserves_z]
    exact hcz
  exact ⟨hcz, all176Entries_spatial_completeness _ hcz hvc,
         all176Entries_spatial_completeness _ haz hva⟩

private theorem runCartograffectPipeline_coherent (s : PredictiveEngineState) :
    isCoherentTerminalState s (runCartograffectPipeline s) := by
  refine ⟨rfl, ?_, rfl, ?_, ?_, ?_, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, ?_, ?_, ?_⟩
  · exact (evaluateCoreAffect s).h_valid
  · exact (evaluateMatrix (evaluateCoreAffect s)).antagonist.h_valid
  · exact antagonistPoint_preserves_z (projectToCoreAffect s)
  · exact antagonistPoint_preserves_displacementSum (projectToCoreAffect s)
  · exact classifyTaxonomicGroup_correct (projectToCoreAffect s)
  · intro g hg
    exact taxonomy_group_exclusive (projectToCoreAffect s) g
      (classifyTaxonomicGroup (projectToCoreAffect s))
      hg (classifyTaxonomicGroup_correct (projectToCoreAffect s))
  · exact classifyTaxonomicGroup_correct (antagonistPoint (projectToCoreAffect s))

/--
[10/10] THÉORÈME COMPLET DE BOUT EN BOUT (Moteur → Noyau → Matrice → Opérants → Taxonomie → Lexique 176) :
Pour tout état moteur `s` se projetant dans `Z ≤ 7`, le pipeline produit un unique état taxonomique
terminal cohérent, résout de façon unique l'entrée nominale de `cp` et de son antagoniste `ap` dans
`all176Entries`, et garantit hors des axes la dualité opérante (inversion d'effet, conservation d'opérateur).
-/
theorem full_end_to_end_lexicon_resolution (s : PredictiveEngineState)
    (hz : (projectToCoreAffect s).z ≤ 7) :
    let ts := runCartograffectPipeline s
    let cp := ts.matrix.core.point
    let ap := ts.matrix.antagonist.point
    isCoherentTerminalState s ts ∧
    (∀ ts' : TaxonomicState, isCoherentTerminalState s ts' → ts' = ts) ∧
    (∃ e ∈ all176Entries, e.point = cp ∧ ∀ e' ∈ all176Entries, e'.point = cp → e' = e) ∧
    (∃ ae ∈ all176Entries, ae.point = ap ∧ ∀ ae' ∈ all176Entries, ae'.point = ap → ae' = ae) ∧
    (cp.x ≠ 0 → cp.y ≠ 0 →
      ∃ c1 c2 : OperantContingency,
        quadrantContingency cp.x cp.y = some c1 ∧
        quadrantContingency ap.x ap.y = some c2 ∧
        c1.effect ≠ c2.effect ∧ c1.op = c2.op) := by
  rcases end_to_end_coherence s with ⟨ts0, hcoh0, huniq0⟩
  have hts_eq : runCartograffectPipeline s = ts0 :=
    huniq0 (runCartograffectPipeline s) (runCartograffectPipeline_coherent s)
  rw [← hts_eq] at hcoh0 huniq0
  have hvc : isValidCoreAffect (runCartograffectPipeline s).matrix.core.point := hcoh0.2.1
  have hva : isValidCoreAffect (runCartograffectPipeline s).matrix.antagonist.point := hcoh0.2.2.2.1
  have hap_eq : (runCartograffectPipeline s).matrix.antagonist.point =
      antagonistPoint (runCartograffectPipeline s).matrix.core.point := hcoh0.2.2.1
  have hcp_z : (runCartograffectPipeline s).matrix.core.point.z ≤ 7 := by
    rw [hcoh0.1]; exact hz
  have hap_z : (runCartograffectPipeline s).matrix.antagonist.point.z ≤ 7 := by
    rw [hap_eq, antagonistPoint_preserves_z]; exact hcp_z
  have hmem_cp : (runCartograffectPipeline s).matrix.core.point ∈ all176Entries.map (·.point) :=
    all176Entries_spatial_completeness (runCartograffectPipeline s).matrix.core.point hcp_z hvc
  have hmem_ap : (runCartograffectPipeline s).matrix.antagonist.point ∈ all176Entries.map (·.point) :=
    all176Entries_spatial_completeness (runCartograffectPipeline s).matrix.antagonist.point hap_z hva
  rcases List.mem_map.mp hmem_cp with ⟨e, he_mem, he_pt⟩
  rcases List.mem_map.mp hmem_ap with ⟨ae, hae_mem, hae_pt⟩
  refine ⟨hcoh0, huniq0, ⟨e, he_mem, he_pt, ?_⟩, ⟨ae, hae_mem, hae_pt, ?_⟩, ?_⟩
  · intro e' he' hpt'
    exact nodup_map_inj (·.point) all176Entries_unique_points he' he_mem (hpt'.trans he_pt.symm)
  · intro ae' hae' hpt'
    exact nodup_map_inj (·.point) all176Entries_unique_points hae' hae_mem (hpt'.trans hae_pt.symm)
  · intro hx hy
    rw [hap_eq]
    exact operant_antagonist_invariance_all_strata (runCartograffectPipeline s).matrix.core.point hx hy

end EndToEndBridge

end Cartograffect
