/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
Author: Manuel Cabelguen
-/

import Cartograffect.PredictiveEngine
import Cartograffect.CoreAffect
import Cartograffect.PredictiveCircuit

namespace Cartograffect

namespace PredictiveEngineCanonical

open PredictiveEngine
open CoreAffect
open PredictiveCircuit

/-!
# Moteur Prédictif Canonique Unifié (Arbitrages A1–A4)

Extension formelle en Lean 4 raccordée aux types natifs du noyau Strate 0
(`PredictiveEngine`, `CoreAffect`, `PredictiveCircuit`) sans modification d'aucun module
existant du noyau ni de la parité des 6 prouveurs.

Formalise et certifie (`0 sorry`, `0 axiom`, `warningAsError := true`) :
1. **Arbitrage A1** : Réponse isolée sur 3 circuits (`A0, A-, A+` et `C0, C-, C+`),
   projection directe du niveau d'opérabilité `Z` depuis les `[États cachés]`
   (court-circuitage ascendant et descendant sans incrémentation séquentielle forcée),
   ensembles de possibles `{±X, ±Y, Z}` dans l'`INTERFACE ATTENTIONNELLE` (excluant
   strictement `Veille (0,0,0)`) et réduction de l'information (`ΔH ≥ 0`) vers l'action ;
2. **Arbitrage A2** : Double système de notation — base projective directionnelle `(X_0, Y_0, 0)`
   au Croisement I (`|X_0| + |Y_0| = 2` hors Veille) et loi d'échelle de couronne
   `|π_A| + |π_C| = 2Z - 2` pour `Z ≥ 2` ;
3. **Arbitrage A3 & A4** : Bijection `Φ`, conservation `L1` (P1), disjonction stricte entre
   `Veille (0,0,0)` et tout domaine attentionnel (`Z ≥ 1`), décroissance stricte du potentiel
   de Lyapunov (`ΔV < 0`) sur toute transition non triviale de résolution active
   (`ε = 0, χ = 0, δ = 0`) et séparation formelle entre résolution active et extinction passive.
-/

/-!
## 1. Arbitrages A1–A3 : Réponses isolées, projection directe de Z et réduction de l'information
-/

/-- Réponse isolée émise sur l'un des 3 circuits d'une boucle (`A0, A-, A+` ou `C0, C-, C+`)
    avec projection directe du niveau d'opérabilité `zOperability` requis par les `[États cachés]`. -/
structure IsolatedCircuitResponse where
  loop         : CircuitLoop
  polarity     : Polarity
  zOperability : Nat
  deriving DecidableEq, Repr, Inhabited

/-- Régime fonctionnel associé à une réponse isolée (`charge`, `neutral`, `discharge`). -/
def IsolatedCircuitResponse.regime (r : IsolatedCircuitResponse) : FunctionalRegime :=
  r.polarity.toRegime

/-- Domaine attentionnel symbolique `{±X, ±Y, Z}` dans l'`INTERFACE ATTENTIONNELLE`.
    L'invariant `h_z_pos : z ≥ 1` exclut structurellement `Z = 0` (`Veille (0,0,0)`). -/
structure AttentionalPossibilityDomain where
  coupling : EngineCoupling
  z        : Nat
  h_z_pos  : z ≥ 1
  deriving DecidableEq, Repr

/-- Instance par défaut située en `Surprise {0, 0, 1}` (`Z = 1 ≥ 1`). -/
instance : Inhabited AttentionalPossibilityDomain where
  default := {
    coupling := ⟨.zero, .zero⟩
    z        := 1
    h_z_pos  := Nat.le_refl 1
  }

/-- Base projective directionnelle `(X_0, Y_0, 0)` associée au domaine au Croisement I. -/
def AttentionalPossibilityDomain.protoNode (d : AttentionalPossibilityDomain) : ProtoSpatialNode :=
  phiL1 d.coupling

/-- Nombre de réalisations discrètes admissibles contenues dans l'ensemble des possibles
    `{±X, ±Y, Z}` :
    - `1` en `Z = 1` ou sur les domaines centraux/axiaux (un seul point admissible) ;
    - `2 * Z - 3` sur les quadrants diagonaux/latéraux en `Z ≥ 2` (`|π_A| + |π_C| = 2Z - 2`
      avec `|π_A| ≥ 1`, `|π_C| ≥ 1`). -/
def AttentionalPossibilityDomain.domainCardinality (d : AttentionalPossibilityDomain) : Nat :=
  if d.z ≤ 1 then 1
  else if d.coupling.isDualEngaged then 2 * d.z - 3
  else 1

/-- Tout domaine attentionnel contient au moins une réalisation admissible. -/
theorem AttentionalPossibilityDomain.domainCardinality_pos (d : AttentionalPossibilityDomain) :
    d.domainCardinality ≥ 1 := by
  unfold domainCardinality
  split
  · exact Nat.le_refl 1
  · split
    · have hz := d.h_z_pos
      have hge2 : d.z ≥ 2 := by omega
      omega
    · exact Nat.le_refl 1

/-- Projection directe des réponses isolées `(respA, respC)` vers un domaine de possibles
    attentionnel au niveau d'opérabilité `zReq ≥ 1` projeté par les `[États cachés]`,
    sans incrémentation séquentielle forcée de `Z`. -/
def directProjectToAttentional
    (respA respC : IsolatedCircuitResponse)
    (zReq : Nat) (h_z : zReq ≥ 1) : AttentionalPossibilityDomain :=
  { coupling := ⟨respA.polarity, respC.polarity⟩
    z        := zReq
    h_z_pos  := h_z }

/-- Projection géométrique certifiée d'un domaine attentionnel `{±X, ±Y, Z}` vers le Noyau
    affectif (`CoreAffectPoint`) sous arbitrage `(π_A, π_C)`.
    Pour `{0, 0, Z}` : projette vers `Surprise (0, 0, 1)` si `Z = 1` et vers `(0, 0, Z)` si `Z ≥ 2`. -/
def projectAttentionalDomain
    (d : AttentionalPossibilityDomain) (piA piC : Nat) : CoreAffectPoint :=
  if d.coupling.isGlobalNeutrality then
    ⟨0, 0, d.z⟩
  else
    projectPerceptible d.coupling d.z piA piC true

/-- La projection d'un domaine attentionnel produit toujours une coordonnée valide
    au sens de `isValidCoreAffect`. -/
theorem projectAttentionalDomain_valid
    (d : AttentionalPossibilityDomain) (piA piC : Nat) :
    isValidCoreAffect (projectAttentionalDomain d piA piC) := by
  unfold projectAttentionalDomain
  split
  · exact Or.inl ⟨rfl, rfl⟩
  · exact projectPerceptible_valid d.coupling d.z piA piC true

/-- La coordonnée verticale `z` projetée par `projectAttentionalDomain` est exactement `d.z`. -/
theorem projectAttentionalDomain_z
    (d : AttentionalPossibilityDomain) (piA piC : Nat) :
    (projectAttentionalDomain d piA piC).z = d.z := by
  rcases d with ⟨⟨a, ctrl⟩, z, hz⟩
  dsimp [projectAttentionalDomain]
  split
  · rfl
  · rename_i h_not_neut
    cases z with
    | zero => omega
    | succ n =>
      cases n with
      | zero =>
        unfold projectPerceptible
        simp [h_not_neut]
      | succ k =>
        unfold projectPerceptible
        simp only [h_not_neut, Bool.false_eq_true, ↓reduceIte]
        cases a <;> cases ctrl <;>
          first
          | (exfalso; apply h_not_neut; rfl)
          | (simp [deployCouplingWithPrecision]; try omega)

/-- Court-circuitage direct du niveau d'opérabilité `Z` : `directProjectToAttentional` atteint
    directement toute strate cible `zReq ≥ 1` (ascendante ou descendante) en un seul saut,
    sans incrémentation séquentielle intermédiaire. -/
theorem directProjectToAttentional_preserves_z
    (respA respC : IsolatedCircuitResponse) (zReq : Nat) (h_z : zReq ≥ 1) :
    (directProjectToAttentional respA respC zReq h_z).z = zReq ∧
    (projectAttentionalDomain (directProjectToAttentional respA respC zReq h_z) 1 1).z = zReq := by
  refine ⟨rfl, projectAttentionalDomain_z _ 1 1⟩

/-- Témoin constructif de court-circuitage direct ascendant (`Z = 0 → Z = 5`) et descendant
    (`Z = 7 → Z = 2`), sans passage séquentiel par les strates intermédiaires. -/
theorem direct_z_jump_ascent_and_descent_witness :
    let respA : IsolatedCircuitResponse := ⟨.expectationLoop, .neg, 5⟩
    let respC : IsolatedCircuitResponse := ⟨.controlLoop, .pos, 5⟩
    let domUp := directProjectToAttentional respA respC 5 (by decide)
    let domDown := directProjectToAttentional
      ⟨.expectationLoop, .pos, 2⟩ ⟨.controlLoop, .pos, 2⟩ 2 (by decide)
    domUp.z = 5 ∧ domDown.z = 2 ∧
    (projectAttentionalDomain domUp 1 3).z = 5 ∧
    (projectAttentionalDomain domDown 1 1).z = 2 := by
  decide

/-- Mesure discrète de réduction d'information sur un ensemble fini de possibles comprimé
    de `cardPossibles` vers `cardReduced` alternatives. -/
def informationReductionGap (cardPossibles cardReduced : Nat) : Nat :=
  cardPossibles - cardReduced

/-- Monotonie de l'entropie discrète : toute compression `cardR ≤ cardP` assure
    une réduction non négative et la conservation exacte du reste. -/
theorem informationReduction_nonneg
    (cardPossibles cardReduced : Nat)
    (h_le : cardReduced ≤ cardPossibles) :
    informationReductionGap cardPossibles cardReduced ≥ 0 ∧
    informationReductionGap cardPossibles cardReduced + cardReduced = cardPossibles := by
  unfold informationReductionGap
  omega

private theorem two_pow_pos (n : Nat) : 0 < 2 ^ n := by
  induction n with
  | zero => exact Nat.le_refl 1
  | succ k ih => simp [Nat.pow_succ]; omega

private theorem two_pow_lt_of_lt {a b : Nat} (h : a < b) : 2 ^ a < 2 ^ b := by
  induction b with
  | zero => omega
  | succ b ih =>
    have h_le : a ≤ b := Nat.lt_succ_iff.mp h
    have h_succ : 2 ^ (b + 1) = 2 ^ b * 2 := Nat.pow_succ 2 b
    have hb_pos : 0 < 2 ^ b := two_pow_pos b
    rcases Nat.eq_or_lt_of_le h_le with rfl | h_lt
    · rw [h_succ]; omega
    · have h_ih := ih h_lt
      rw [h_succ]
      omega

/-- Compression stricte en bits (`2^kR ≤ 2^kP → kR ≤ kP` et `kP - kR ≥ 0`) pour l'opérateur
    de réduction de l'information `R(P)`. -/
theorem hartley_bits_reduction_nonneg (kP kR : Nat) (h_pow : 2 ^ kR ≤ 2 ^ kP) :
    kR ≤ kP ∧ kP - kR ≥ 0 := by
  rcases Nat.lt_or_ge kP kR with h_lt | h_le
  · have h_pow_lt : 2 ^ kP < 2 ^ kR := two_pow_lt_of_lt h_lt
    omega
  · exact ⟨h_le, Nat.zero_le _⟩

/-- Tout ensemble de possibles attentionnel comprimé vers une politique d'action unique (`1`)
    vérifie `Δ_card ≥ 0`, avec réduction strictement positive dès `Z ≥ 3` et double engagement. -/
theorem attentional_domain_compression_nonneg (d : AttentionalPossibilityDomain) :
    informationReductionGap d.domainCardinality 1 + 1 = d.domainCardinality ∧
    (d.z ≥ 3 → d.coupling.isDualEngaged = true →
      informationReductionGap d.domainCardinality 1 > 0) := by
  have h_pos := d.domainCardinality_pos
  refine ⟨?_, ?_⟩
  · unfold informationReductionGap; omega
  · intro hz hdual
    unfold informationReductionGap AttentionalPossibilityDomain.domainCardinality
    have hnot1 : ¬ (d.z ≤ 1) := by omega
    simp only [hnot1, ↓reduceIte, hdual]
    omega

/-!
## 2. Les 5 Invariants canoniques des Arbitrages A1–A4
-/

/-- **Invariant 1 (Bijection `Φ` entre Croisement II `[A/C]` et Croisement I `(X_0, Y_0, 0)`)** :
    Opérateur direct sur `Polarity × Polarity`. -/
def canonicalPhi (ac : Polarity × Polarity) : ProtoSpatialNode :=
  phiL1 ⟨ac.1, ac.2⟩

/-- Opérateur réciproque `Φ⁻¹` sur le plan proto-spatial `(X_0, Y_0, 0)`. -/
def canonicalPhiInv (n : ProtoSpatialNode) : Polarity × Polarity :=
  let c := phiL1Inv n
  (c.attente, c.controle)

/-- Inverse à gauche de la bijection `Φ` : `Φ⁻¹(Φ(A, C)) = (A, C)`. -/
theorem canonicalPhi_left_inv (ac : Polarity × Polarity) :
    canonicalPhiInv (canonicalPhi ac) = ac := by
  rcases ac with ⟨a, c⟩
  have h := phiL1_left_inv ⟨a, c⟩
  unfold canonicalPhiInv canonicalPhi
  rw [h]

/-- Inverse à droite de la bijection `Φ` sur tout nœud admissible du Croisement I :
    `Φ(Φ⁻¹(X_0, Y_0)) = (X_0, Y_0)`. -/
theorem canonicalPhi_right_inv (n : ProtoSpatialNode) (h : isValidProtoSpatial n) :
    canonicalPhi (canonicalPhiInv n) = n := by
  unfold canonicalPhi canonicalPhiInv
  exact phiL1_right_inv n h

/-- **Invariant 2 (Conservation `L1` — P1)** :
    Pour tout état actif hors `Veille (0,0,0)`, la base projective directionnelle `(X_0, Y_0, 0)`
    au Croisement I conserve exactement `|X_0| + |Y_0| = 2`. -/
theorem canonical_l1_conservation (c : EngineCoupling) (h_active : c ≠ ⟨.zero, .zero⟩) :
    (phiL1 c).x.natAbs + (phiL1 c).y.natAbs = 2 := by
  have h_non_neut : c.isGlobalNeutrality = false := by
    cases c with
    | mk a ctrl =>
      cases a <;> cases ctrl <;>
        first
        | exact absurd rfl h_active
        | rfl
  exact phiL1_l1Norm_active c h_non_neut

/-- La norme `L1` au Croisement I s'annule si et seulement si l'état est `Veille (0,0,0)`. -/
theorem canonical_l1_zero_iff_veille (c : EngineCoupling) :
    (phiL1 c).x.natAbs + (phiL1 c).y.natAbs = 0 ↔ c = ⟨.zero, .zero⟩ := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> decide

/-- **Invariant 3 (Loi d'échelle de couronne — A2)** :
    Dans le plan perceptible de l'`INTERFACE ATTENTIONNELLE`, tout état actif à la strate `Z ≥ 2`
    vérifie exactement `|π_A| + |π_C| = 2 * Z - 2`. -/
theorem canonical_crown_scaling_law
    (c : EngineCoupling) (z piA piC : Nat) (susp : Bool)
    (h_active : c ≠ ⟨.zero, .zero⟩) (hz : z ≥ 2) :
    let pt := projectPerceptible c z piA piC susp
    pt.x.natAbs + pt.y.natAbs = 2 * z - 2 := by
  dsimp
  have h_non_neut : c.isGlobalNeutrality = false := by
    cases c with
    | mk a ctrl =>
      cases a <;> cases ctrl <;>
        first
        | exact absurd rfl h_active
        | rfl
  cases hzs : z with
  | zero => omega
  | succ z1 =>
    cases z1 with
    | zero => omega
    | succ d =>
      unfold projectPerceptible
      simp only [h_non_neut, Bool.false_eq_true, ↓reduceIte]
      have hb := deployCouplingWithPrecision_budget_conservation c d piA piC h_non_neut
      unfold CoreAffectPoint.displacementSum at hb
      omega

/-- Loi d'échelle exacte de `apportionRay` sur toute couronne `Z ≥ 2`. -/
theorem canonical_apportionRay_scaling (z piA piC : Nat) (hz : z ≥ 2) :
    let pair := apportionRay (z - 2) piA piC
    pair.1 + pair.2 = 2 * z - 2 := by
  dsimp
  have hb := apportionRay_bounds (z - 2) piA piC
  omega

/-- **Invariant 4 (Disjonction stricte entre `Veille (0,0,0)` et tout domaine attentionnel `Z ≥ 1`)** :
    Aucun point dont la profondeur vérifie `z ≥ 1` ne peut être `Veille (0,0,0)`. -/
theorem veille_disjoint_from_attentional_point (p : CoreAffectPoint) (h : p.z ≥ 1) :
    p ≠ ⟨0, 0, 0⟩ := by
  intro heq
  rw [heq] at h
  dsimp at h
  omega

/-- Tout domaine attentionnel `AttentionalPossibilityDomain` exclut `Z = 0`, et sa projection
    géométrique `projectAttentionalDomain` n'est jamais `Veille (0,0,0)` (y compris `{0, 0, Z}`). -/
theorem attentional_domain_disjoint_from_veille
    (d : AttentionalPossibilityDomain) (piA piC : Nat) :
    d.z ≠ 0 ∧
    (⟨0, 0, d.z⟩ : CoreAffectPoint) ≠ ⟨0, 0, 0⟩ ∧
    projectAttentionalDomain d piA piC ≠ ⟨0, 0, 0⟩ := by
  have hz := d.h_z_pos
  have h_z_proj := projectAttentionalDomain_z d piA piC
  refine ⟨by omega, ?_, ?_⟩
  · intro h_eq
    have hzz : d.z = 0 := congrArg CoreAffectPoint.z h_eq
    omega
  · intro h_eq
    have hzz : (projectAttentionalDomain d piA piC).z = 0 := congrArg CoreAffectPoint.z h_eq
    rw [h_z_proj] at hzz
    omega

/-- Le domaine axial `{0, 0, Z}` de l'`INTERFACE ATTENTIONNELLE` projette vers `(0, 0, Z)`
    avec `Z ≥ 1` (`Surprise (0,0,1)` ou opérateur central `(0,0,Z)`), jamais vers `Veille (0,0,0)`. -/
theorem attentional_neutral_domain_is_non_veille (z piA piC : Nat) (hz : z ≥ 1) :
    let d : AttentionalPossibilityDomain := ⟨⟨.zero, .zero⟩, z, hz⟩
    projectAttentionalDomain d piA piC = ⟨0, 0, z⟩ ∧
    projectAttentionalDomain d piA piC ≠ ⟨0, 0, 0⟩ := by
  dsimp
  have h_proj : projectAttentionalDomain ⟨⟨.zero, .zero⟩, z, hz⟩ piA piC = ⟨0, 0, z⟩ := rfl
  refine ⟨h_proj, ?_⟩
  rw [h_proj]
  exact veille_disjoint_from_attentional_point ⟨0, 0, z⟩ hz

/-- **Invariant 5 (Décroissance stricte du potentiel de Lyapunov `ΔV < 0` en résolution active
    et séparation formelle d'avec l'extinction passive)** :
    Transition élémentaire de résolution active sur une boucle (`Charge → Décharge` ou `Décharge → Neutre`). -/
def isActivePolarityStep (src dst : Polarity) : Bool :=
  (src == .neg && dst == .pos) || (src == .pos && dst == .zero)

/-- Transition élémentaire d'extinction passive sur une boucle (`Charge → Neutre` directe sans
    passage par la Décharge). -/
def isPassivePolarityExtinction (src dst : Polarity) : Bool :=
  src == .neg && dst == .zero

/-- Prédicat d'une étape non triviale de résolution active sur le couple `(A, C)`. -/
def isActiveResolutionStep (src dst : EngineCoupling) : Prop :=
  dst ≠ src ∧
  (dst.attente = src.attente ∨ isActivePolarityStep src.attente dst.attente = true) ∧
  (dst.controle = src.controle ∨ isActivePolarityStep src.controle dst.controle = true)

/-- Prédicat d'une étape comportant au moins une extinction passive (`Charge → Neutre`). -/
def isPassiveExtinctionStep (src dst : EngineCoupling) : Prop :=
  isPassivePolarityExtinction src.attente dst.attente = true ∨
  isPassivePolarityExtinction src.controle dst.controle = true

/-- Disjonction stricte entre étape de résolution active et étape d'extinction passive. -/
theorem active_vs_passive_step_disjoint (src dst : EngineCoupling) :
    ¬ (isActiveResolutionStep src dst ∧ isPassiveExtinctionStep src dst) := by
  intro ⟨⟨_, ha, hc⟩, hpass⟩
  rcases hpass with hpa | hpc
  · cases hs : src.attente <;> cases hd : dst.attente <;>
      simp_all [isPassivePolarityExtinction, isActivePolarityStep]
  · cases hs : src.controle <;> cases hd : dst.controle <;>
      simp_all [isPassivePolarityExtinction, isActivePolarityStep]

private theorem active_marginal_free_rules
    (M rate deseng qPos : Nat) (otherCharged : Bool) (w2 : Nat) (src dst : Polarity)
    (hw : marginalWeight M rate 0 deseng 0 qPos 0 otherCharged w2 src dst > 0) :
    dst = src ∨ isActivePolarityStep src dst = true := by
  have he2 : effectiveEpsScaled M 0 0 otherCharged = 0 := by
    cases otherCharged <;> simp [effectiveEpsScaled]
  cases src <;> cases dst <;>
    dsimp [marginalWeight, isActivePolarityStep] at hw ⊢
  all_goals try rw [he2] at hw
  all_goals first | exact Or.inl rfl | exact Or.inr rfl | omega

private theorem active_polarity_strictly_decreases_energy (src dst : Polarity)
    (h : isActivePolarityStep src dst = true) :
    polarityEnergy dst < polarityEnergy src := by
  cases src <;> cases dst <;> simp_all [isActivePolarityStep, polarityEnergy]

/-- En régime libre sans extinction passive (`ε = 0, χ = 0, δ_A = δ_C = 0`), toute transition
    non triviale (`dst ≠ src`) de poids positif vérifie :
    1. Décroissance stricte du potentiel de Lyapunov : `V(dst) < V(src)` (`ΔV < 0`) ;
    2. Transition de résolution active (`Charge → Décharge` ou `Décharge → Neutre`) ;
    3. Exclusion stricte de toute extinction passive (`Charge → Neutre`). -/
theorem lyapunov_strict_decrease_active_free
    (p : CircuitKernelParams)
    (h_eps : p.epsilon = 0) (h_chi : p.chi = 0)
    (h_da : p.deltaA = 0) (h_dc : p.deltaC = 0)
    (src dst : EngineCoupling)
    (hw : circuitWeight p src dst > 0)
    (hne : dst ≠ src) :
    lyapunovPotential dst < lyapunovPotential src ∧
    isActiveResolutionStep src dst ∧
    ¬ isPassiveExtinctionStep src dst := by
  unfold circuitWeight at hw
  rw [h_eps, h_chi, h_da, h_dc] at hw
  have ha_pos : 0 < marginalWeight p.scale p.rho 0 p.gammaA 0 p.qPosA 0
      (isCharged src.controle) (attentionalWeightX2 src) src.attente dst.attente :=
    Nat.pos_of_mul_pos_right hw
  have hc_pos : 0 < marginalWeight p.scale p.kappa 0 p.gammaC 0 p.qPosC 0
      (isCharged src.attente) (attentionalWeightY2 src) src.controle dst.controle :=
    Nat.pos_of_mul_pos_left hw
  have hrule_a := active_marginal_free_rules p.scale p.rho p.gammaA p.qPosA
    (isCharged src.controle) (attentionalWeightX2 src) src.attente dst.attente ha_pos
  have hrule_c := active_marginal_free_rules p.scale p.kappa p.gammaC p.qPosC
    (isCharged src.attente) (attentionalWeightY2 src) src.controle dst.controle hc_pos
  have hact : isActiveResolutionStep src dst := ⟨hne, hrule_a, hrule_c⟩
  have hnotpass : ¬ isPassiveExtinctionStep src dst := by
    intro hpass
    exact active_vs_passive_step_disjoint src dst ⟨hact, hpass⟩
  have he_a_le : polarityEnergy dst.attente ≤ polarityEnergy src.attente := by
    rcases hrule_a with ha_eq | ha_act
    · rw [ha_eq]; exact Nat.le_refl _
    · exact Nat.le_of_lt (active_polarity_strictly_decreases_energy _ _ ha_act)
  have he_c_le : polarityEnergy dst.controle ≤ polarityEnergy src.controle := by
    rcases hrule_c with hc_eq | hc_act
    · rw [hc_eq]; exact Nat.le_refl _
    · exact Nat.le_of_lt (active_polarity_strictly_decreases_energy _ _ hc_act)
  have h_strict : lyapunovPotential dst < lyapunovPotential src := by
    unfold lyapunovPotential
    by_cases ha_eq : dst.attente = src.attente
    · have hc_neq : dst.controle ≠ src.controle := by
        intro hc_eq
        apply hne
        cases src; cases dst
        simp_all
      rcases hrule_c with hc_eq' | hc_act
      · contradiction
      · have hlt := active_polarity_strictly_decreases_energy _ _ hc_act
        omega
    · rcases hrule_a with ha_eq' | ha_act
      · contradiction
      · have hlt := active_polarity_strictly_decreases_energy _ _ ha_act
        omega
  exact ⟨h_strict, hact, hnotpass⟩

/-- En régime libre (`ε = 0, χ = 0`), une transition d'extinction passive (`Charge → Neutre`)
    ne peut se produire que si le taux d'extinction passive correspondant (`δ_A` ou `δ_C`) est > 0. -/
theorem passive_extinction_requires_delta_pos
    (p : CircuitKernelParams) (h_eps : p.epsilon = 0) (h_chi : p.chi = 0)
    (src dst : EngineCoupling)
    (hpass : isPassiveExtinctionStep src dst)
    (hw : circuitWeight p src dst > 0) :
    p.deltaA > 0 ∨ p.deltaC > 0 := by
  unfold circuitWeight at hw
  rw [h_eps, h_chi] at hw
  have ha_pos := Nat.pos_of_mul_pos_right hw
  have hc_pos := Nat.pos_of_mul_pos_left hw
  rcases hpass with hpa | hpc
  · left
    cases ha_s : src.attente <;> cases ha_d : dst.attente <;>
      simp only [isPassivePolarityExtinction, ha_s, ha_d] at hpa
    all_goals try exact absurd hpa (by decide)
    rw [ha_s, ha_d] at ha_pos
    dsimp [marginalWeight] at ha_pos
    cases hda : p.deltaA with
    | zero => rw [hda] at ha_pos; omega
    | succ _ => exact Nat.zero_lt_succ _
  · right
    cases hc_s : src.controle <;> cases hc_d : dst.controle <;>
      simp only [isPassivePolarityExtinction, hc_s, hc_d] at hpc
    all_goals try exact absurd hpc (by decide)
    rw [hc_s, hc_d] at hc_pos
    dsimp [marginalWeight] at hc_pos
    cases hdc : p.deltaC with
    | zero => rw [hdc] at hc_pos; omega
    | succ _ => exact Nat.zero_lt_succ _

/-- Signature différentielle entre résolution active et extinction passive depuis `(A-, C0)` :
    - Résolution active `(A-, C0) → (A+, C0)` : `ΔV = 1` et `activeResolutionCount = 1` (passe par la Décharge) ;
    - Extinction passive `(A-, C0) → (A0, C0)` : `ΔV = 2` et `activeResolutionCount = 0` (saut sans Décharge). -/
theorem active_vs_passive_energy_signature :
    let src : EngineCoupling := ⟨.neg, .zero⟩
    let dstActive : EngineCoupling := ⟨.pos, .zero⟩
    let dstPassive : EngineCoupling := ⟨.zero, .zero⟩
    isActiveResolutionStep src dstActive ∧
    isPassiveExtinctionStep src dstPassive ∧
    activeResolutionCount src dstActive = 1 ∧
    activeResolutionCount src dstPassive = 0 ∧
    lyapunovPotential src - lyapunovPotential dstActive = 1 ∧
    lyapunovPotential src - lyapunovPotential dstPassive = 2 := by
  refine ⟨⟨by decide, Or.inr rfl, Or.inl rfl⟩, Or.inl rfl, rfl, rfl, rfl, rfl⟩

/-!
## 3. Audit axiomatique (#print axioms)
-/

#print axioms directProjectToAttentional_preserves_z
#print axioms direct_z_jump_ascent_and_descent_witness
#print axioms informationReduction_nonneg
#print axioms hartley_bits_reduction_nonneg
#print axioms attentional_domain_compression_nonneg
#print axioms canonicalPhi_left_inv
#print axioms canonicalPhi_right_inv
#print axioms canonical_l1_conservation
#print axioms canonical_l1_zero_iff_veille
#print axioms canonical_crown_scaling_law
#print axioms canonical_apportionRay_scaling
#print axioms veille_disjoint_from_attentional_point
#print axioms attentional_domain_disjoint_from_veille
#print axioms attentional_neutral_domain_is_non_veille
#print axioms active_vs_passive_step_disjoint
#print axioms lyapunov_strict_decrease_active_free
#print axioms passive_extinction_requires_delta_pos
#print axioms active_vs_passive_energy_signature

end PredictiveEngineCanonical

end Cartograffect
