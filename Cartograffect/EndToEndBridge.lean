/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later
Author: Manuel Cabelguen
-/

import Cartograffect.PredictiveEngine
import Cartograffect.CoreAffect
import Cartograffect.AffectiveMatrix
import Cartograffect.AffectiveTaxonomy
import Cartograffect.AffectiveDynamics
import Cartograffect.PredictiveCircuit
import Cartograffect.OperantFactorization

namespace Cartograffect

namespace EndToEndBridge

open PredictiveEngine
open CoreAffect
open AffectiveMatrix
open AffectiveTaxonomy
open AffectiveDynamics
open PredictiveCircuit
open OperantFactorization

/-!
# Ponts formels de bout en bout du noyau normatif v3.0

Ce module soude formellement la chaîne logique du cœur normatif **CARTOGRAFFECT (v3.0)**
sans aucune dépendance envers les annexes exploratoires (`Lexicon176`) ni aucun relèvement
universel des contingences opérantes au-delà de la fondation `Z = 2` :
- **Option 1A** : `Y` = contrôlabilité instrumentale perçue stricte, canal autonome `A ≥ 0`
  (`autonomousActivation`) indépendant de `(X, Y)` et groupes fonctionnels neutres ;
- **Option 2a** : transitions verticales pas-à-pas strictes (`ΔZ ∈ {-1, 0, +1}` avec unique
  court-circuit descendant `2 → 0` évitant `Z = 1` Surprise) ;
- **Option 3b** : instabilité axiale (`χ > 0`, P2) restreinte aux 2 pôles en Charge négative
  (`Peur`, `Tristesse`), brisant la symétrie dynamique Charge / Décharge ;
- **Fondation `Z = 2`** : séparation stricte entre renforcement négatif opérant `R-` (`Y > 0`)
  et sécurité pavlovienne passive (`Calme (+1, -1, 2)`, `Y < 0`), bornée à `Z = 2`.
-/

/-!
## 1. Ponts fonctionnels canoniques (fondation `Z = 2` et évaluateurs terminaux)
-/

/-- Régime écologique induit en `Z = 2` par un couplage doublement engagé `(A, C)`. -/
def couplingToZ2Contingency (c : EngineCoupling) : Option Z2ContingencyRegime :=
  match c.attente, c.controle with
  | .pos, .pos => some .activeOperantReinforcement
  | .neg, .pos => some .agenticOmissionPunishment
  | .pos, .neg => some .pavlovianPassiveSafety
  | .neg, .neg => some .inescapableAversivePunishment
  | _,    _    => none

/-- Prédicat exact de la loi verticale pas-à-pas de l'Option 2a (`ΔZ ∈ {-1, 0, +1}` sans `2 → 1`,
    plus l'unique court-circuit descendant `2 → 0`). -/
def isValidVerticalStep2a (zSrc zDst : Nat) : Prop :=
  zDst = zSrc ∨
  zDst = zSrc + 1 ∨
  (zSrc ≥ 3 ∧ zDst + 1 = zSrc) ∨
  ((zSrc = 1 ∨ zSrc = 2) ∧ zDst = 0)

/-- Évaluation complète reliant la loi unifiée `(R_t, Z_t, π_A, π_C)` et le canal autonome `a` à `TaxonomicState`. -/
def evaluateUnifiedTaxonomy (p : UnifiedDynamicsParams) (c : EngineCoupling)
    (z rhoHat kappaHat : Nat) (susp : Bool) (a : Nat := 0) : TaxonomicState :=
  evaluateTaxonomy (evaluateMatrix (projectUnifiedState p c z rhoHat kappaHat susp) a canonicalMapping)

/-- Évaluation complète reliant l'Opération 3 du circuit fermé à 6 opérateurs et le canal autonome `a` à `TaxonomicState`. -/
def evaluateCircularTaxonomy (s : CircularCircuitState) (a : Nat := 0) : TaxonomicState :=
  evaluateTaxonomy (evaluateMatrix (op3_crossingI_perceptible s).2 a canonicalMapping)

/-!
## 2. Théorèmes de soudure de bout en bout du noyau v3.0
-/

/--
[1/6] Pont Circuit prédictif ↔ Contingences bornées à la fondation `Z = 2` :
- En strate `Z = 2`, `diagToContingency ∘ projectPerceptible` coïncide exactement avec `couplingToZ2Contingency` ;
- Sur toute autre strate `z ≠ 2` (notamment `Z = 0, 1` et les strates supérieures `Z ≥ 3`),
  `diagToContingency` renvoie identiquement `none` (aucun relèvement universel sur `Z = 3..7`).
-/
theorem circuit_coupling_z2_contingency_bridge
    (c : EngineCoupling) (z piA piC : Nat) (susp : Bool) :
    diagToContingency (projectPerceptible c 2 piA piC susp) = couplingToZ2Contingency c ∧
    (z ≠ 2 → diagToContingency (projectPerceptible c z piA piC susp) = none) := by
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
  · intro hz2
    apply active_r_minus_vs_pavlovian_safety_and_z2_bound.2.2
    unfold projectPerceptible
    split
    · split
      · dsimp only; exact hz2
      · dsimp only; omega
    · cases z with
      | zero => dsimp only; omega
      | succ n =>
        cases n with
        | zero => dsimp only; omega
        | succ d =>
          have hd0 : d ≠ 0 := fun h => hz2 (by omega)
          rcases c with ⟨a, ctrl⟩
          cases a <;> cases ctrl <;>
            (dsimp only [deployCouplingWithPrecision]; omega)

/--
[2/6] Amorçage axial pré-opérant → Entrée dans les régimes `Z = 2` (distinguant `R-` actif et sécurité pavlovienne) :
Depuis tout couplage axial `c` en `Z = 2`, l'état initial est pré-opérant (`none`), et l'engagement
du second gradient `newPol` projette dans un unique `Z2ContingencyRegime` où `Y > 0` caractérise
l'agentivité opérante active (`R+`/`R-` actif ou `P-`) et `Y < 0` le régime non opérant (`Calme`
pavlovien ou `P+` subi).
-/
theorem triggerSecondaryGradient_enters_z2_contingency
    (c : EngineCoupling) (newPol : Polarity)
    (h_axial : c.isSingleEngaged = true) (h_salient : newPol.isEngaged = true) :
    let c' := triggerSecondaryGradient c newPol
    let p' := deployCouplingAtDepth c' 0
    diagToContingency (deployCouplingAtDepth c 0) = none ∧
    (∃ reg : Z2ContingencyRegime,
      diagToContingency p' = some reg ∧
      couplingToZ2Contingency c' = some reg ∧
      (reg.agency = .activeOperant ↔ p'.y > 0) ∧
      (reg = .pavlovianPassiveSafety ↔ (p'.x > 0 ∧ p'.y < 0))) := by
  rcases c with ⟨a, ctrl⟩
  cases a <;> cases ctrl <;> cases newPol <;>
    first
    | exact absurd h_axial (by decide)
    | exact absurd h_salient (by decide)
    | decide

/--
[3/6] Pont Noyau Markovien P2 (Option 3b) → Bifurcation asymétrique depuis les 2 pôles en Charge négative :
Sous `chi > 0`, la `Peur (A-, C0)` bifurque vers `Colère` (`agenticOmissionPunishment`) et `Dégoût`
(`inescapableAversivePunishment`), et la `Tristesse (A0, C-)` bifurque vers `Calme` (`pavlovianPassiveSafety`)
et `Dégoût` (`inescapableAversivePunishment`), tandis qu'à bruit nul (`epsilon = 0`) les 2 pôles en
Décharge (`Courage`, `Joie`) ont un poids nul vers les diagonales.
-/
theorem p2_negative_charge_enters_z2_contingencies (p : CircuitKernelParams)
    (h_chi : p.chi > 0)
    (h_qa_pos : p.qPosA > 0) (h_qa_lt : p.qPosA < p.scale)
    (h_qc_pos : p.qPosC > 0) (h_qc_lt : p.qPosC < p.scale)
    (h_stay_a : p.rho + p.deltaA < p.scale)
    (h_stay_c : p.kappa + p.deltaC < p.scale) :
    (circuitWeight p ⟨.neg, .zero⟩ ⟨.neg, .pos⟩ > 0 ∧
     circuitWeight p ⟨.neg, .zero⟩ ⟨.neg, .neg⟩ > 0 ∧
     couplingToZ2Contingency ⟨.neg, .pos⟩ = some .agenticOmissionPunishment ∧
     couplingToZ2Contingency ⟨.neg, .neg⟩ = some .inescapableAversivePunishment) ∧
    (circuitWeight p ⟨.zero, .neg⟩ ⟨.pos, .neg⟩ > 0 ∧
     circuitWeight p ⟨.zero, .neg⟩ ⟨.neg, .neg⟩ > 0 ∧
     couplingToZ2Contingency ⟨.pos, .neg⟩ = some .pavlovianPassiveSafety ∧
     couplingToZ2Contingency ⟨.neg, .neg⟩ = some .inescapableAversivePunishment) ∧
    (p.epsilon = 0 →
      circuitWeight p ⟨.pos, .zero⟩ ⟨.pos, .pos⟩ = 0 ∧
      circuitWeight p ⟨.pos, .zero⟩ ⟨.pos, .neg⟩ = 0 ∧
      circuitWeight p ⟨.zero, .pos⟩ ⟨.pos, .pos⟩ = 0 ∧
      circuitWeight p ⟨.zero, .pos⟩ ⟨.neg, .pos⟩ = 0) := by
  have hp_peur := axial_peur_bifurcates_p2 p h_chi h_qc_pos h_qc_lt h_stay_a
  have hp_tris := axial_tristesse_and_discharge_asymmetry_p2 p h_chi h_qa_pos h_qa_lt h_stay_c
  exact ⟨⟨hp_peur.1, hp_peur.2, rfl, rfl⟩, ⟨hp_tris.1.1, hp_tris.1.2, rfl, rfl⟩, hp_tris.2⟩

/--
[4/6] Conformité stricte de `nextStratumR5` et `dissipationStep` à la loi verticale pas-à-pas (Option 2a) :
Toute mise à jour de strate par `nextStratumR5` (pour `z ≤ p.zMax`) et toute étape de dissipation
allostatique par `dissipationStep` respectent `isValidVerticalStep2a` (`ΔZ ∈ {-1, 0, +1}` sans `2 → 1`,
avec unique court-circuit descendant `2 → 0`).
-/
theorem vertical_operators_obey_stepwise_2a
    (p : UnifiedDynamicsParams) (z rNext : Nat) (hz : z ≤ p.zMax) (pt : CoreAffectPoint) :
    isValidVerticalStep2a z (nextStratumR5 p z rNext) ∧
    isValidVerticalStep2a pt.z (dissipationStep pt).z := by
  constructor
  · unfold nextStratumR5 isValidVerticalStep2a
    split
    · by_cases hlt : z < p.zMax
      · right; left; omega
      · left; omega
    · split
      · cases z with
        | zero => left; rfl
        | succ z1 =>
          cases z1 with
          | zero => right; right; right; exact ⟨Or.inl rfl, rfl⟩
          | succ z2 =>
            cases z2 with
            | zero => right; right; right; exact ⟨Or.inr rfl, rfl⟩
            | succ k =>
              dsimp only
              have hmin : min p.zMax (k + 2) = k + 2 := Nat.min_eq_right (by omega)
              rw [hmin]
              right; right; left; omega
      · left; exact Nat.min_eq_right hz
  · unfold dissipationStep isValidVerticalStep2a
    split
    · left; rfl
    · cases pt.z with
      | zero => left; rfl
      | succ z1 =>
        cases z1 with
        | zero => right; right; right; exact ⟨Or.inl rfl, rfl⟩
        | succ z2 =>
          cases z2 with
          | zero => right; right; right; exact ⟨Or.inr rfl, rfl⟩
          | succ k => dsimp only; right; right; left; omega

/--
[5/6] Cohérence complète de la loi unifiée `(R_t, Z_t, π_A, π_C)` et du circuit fermé à 6 opérateurs
vers la Taxonomie fonctionnelle neutre (Options 1A, 2a, 4) :
garantit la validité géométrique, l'indépendance du canal autonome `a`, le raffinement des groupes
et la restriction stricte des contingences à `Z = 2`.
-/
theorem unified_and_circular_to_taxonomy_coherence
    (p : UnifiedDynamicsParams) (c : EngineCoupling)
    (z rhoHat kappaHat a : Nat) (susp : Bool) (s : CircularCircuitState) :
    let tsU := evaluateUnifiedTaxonomy p c z rhoHat kappaHat susp a
    let cpU := tsU.matrix.core.point
    let tsC := evaluateCircularTaxonomy s a
    let cpC := tsC.matrix.core.point
    (isValidCoreAffect cpU ∧
     isValidCoreAffect tsU.matrix.antagonist.point ∧
     tsU.matrix.autonomousActivation = a ∧
     matchesTaxonomicGroup cpU tsU.group ∧
     tsU.subsector.toTaxonomicGroup = tsU.group ∧
     tsU.subsector.toHedonicPolarity = tsU.matrix.valence ∧
     (z = 2 → diagToContingency cpU = couplingToZ2Contingency c) ∧
     (z ≠ 2 → diagToContingency cpU = none)) ∧
    (isValidCoreAffect cpC ∧
     isValidCoreAffect tsC.matrix.antagonist.point ∧
     tsC.matrix.autonomousActivation = a ∧
     matchesTaxonomicGroup cpC tsC.group ∧
     tsC.subsector.toTaxonomicGroup = tsC.group ∧
     tsC.subsector.toHedonicPolarity = tsC.matrix.valence) := by
  dsimp only [evaluateUnifiedTaxonomy, evaluateCircularTaxonomy, evaluateTaxonomy, evaluateMatrix, canonicalMapping]
  have hvcU : isValidCoreAffect (projectUnifiedState p c z rhoHat kappaHat susp).point :=
    projectUnifiedState_valid p c z rhoHat kappaHat susp
  have hvaU : isValidCoreAffect (antagonistPoint (projectUnifiedState p c z rhoHat kappaHat susp).point) :=
    antagonistPoint_preserves_validity _ hvcU
  have hvcC : isValidCoreAffect (op3_crossingI_perceptible s).2.point :=
    (op3_crossingI_perceptible s).2.h_valid
  have hvaC : isValidCoreAffect (antagonistPoint (op3_crossingI_perceptible s).2.point) :=
    antagonistPoint_preserves_validity _ hvcC
  refine ⟨⟨hvcU, hvaU, rfl, classifyTaxonomicGroup_correct _, classifySubsector_refines_group _,
    classifySubsector_determines_valence _ _, ?_, ?_⟩,
    ⟨hvcC, hvaC, rfl, classifyTaxonomicGroup_correct _, classifySubsector_refines_group _,
    classifySubsector_determines_valence _ _⟩⟩
  · intro hz2
    subst hz2
    dsimp only [projectUnifiedState, projectPerceptibleState]
    exact (circuit_coupling_z2_contingency_bridge c 2
      (precisionShares p rhoHat kappaHat c).1 (precisionShares p rhoHat kappaHat c).2 susp).1
  · intro hne2
    dsimp only [projectUnifiedState, projectPerceptibleState]
    exact (circuit_coupling_z2_contingency_bridge c z
      (precisionShares p rhoHat kappaHat c).1 (precisionShares p rhoHat kappaHat c).2 susp).2 hne2

/--
[6/6] THÉORÈME DE SYNTHÈSE DU NOYAU v3.0 (`full_end_to_end_v3_coherence`) :
Pour tout état moteur `s : PredictiveEngineState`, le pipeline `runCartograffectPipeline s` :
1. Aboutit à l'unique `TaxonomicState` terminal cohérent (18 clauses de `isCoherentTerminalState`) ;
2. Découple le canal d'activation autonome `s.autonomousActivation` (`A ≥ 0`) des coordonnées `(X, Y)` ;
3. Associe un antagoniste géométrique statique involutif inversant universellement la valence hédonique ;
4. Converge vers `Veille (0, 0, 0)` par dissipation pas-à-pas `dissipationStep` sans jamais visiter `Surprise (0, 0, 1)` dès `Z ≥ 2` ;
5. Restreint l'articulation des contingences opérantes/pavloviennes à la seule fondation `Z = 2`.
-/
theorem full_end_to_end_v3_coherence (s : PredictiveEngineState) :
    let ts := runCartograffectPipeline s
    let cp := ts.matrix.core.point
    let ap := ts.matrix.antagonist.point
    isCoherentTerminalState s ts ∧
    (∀ ts' : TaxonomicState, isCoherentTerminalState s ts' → ts' = ts) ∧
    ts.matrix.autonomousActivation = s.autonomousActivation ∧
    computeHedonicPolarity ap.x ap.y = (computeHedonicPolarity cp.x cp.y).invert ∧
    Nat.repeat dissipationStep (cp.z + 1) cp = ⟨0, 0, 0⟩ ∧
    (cp.z ≥ 2 → dissipationStep cp ≠ ⟨0, 0, 1⟩) ∧
    (cp.z ≠ 2 → diagToContingency cp = none) := by
  rcases end_to_end_coherence s with ⟨ts0, hcoh0, huniq0⟩
  have hcoh_run : isCoherentTerminalState s (runCartograffectPipeline s) := by
    refine ⟨rfl, (evaluateCoreAffect s).h_valid, rfl,
      (evaluateMatrix (evaluateCoreAffect s) s.autonomousActivation).antagonist.h_valid,
      antagonistPoint_preserves_z _, antagonistPoint_preserves_displacementSum _,
      rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl,
      classifyTaxonomicGroup_correct _, ?_, classifyTaxonomicGroup_correct _⟩
    intro g hg
    exact taxonomy_group_exclusive _ g _ hg (classifyTaxonomicGroup_correct _)
  have hts_eq : runCartograffectPipeline s = ts0 := huniq0 _ hcoh_run
  rw [← hts_eq] at huniq0
  refine ⟨hcoh_run, huniq0, rfl, ?_, dissipation_reaches_veille _, dissipation_from_ge2_never_visits_surprise _, ?_⟩
  · exact antagonistPoint_inverts_hedonic_polarity (projectToCoreAffect s)
  · exact active_r_minus_vs_pavlovian_safety_and_z2_bound.2.2 _

end EndToEndBridge

end Cartograffect
