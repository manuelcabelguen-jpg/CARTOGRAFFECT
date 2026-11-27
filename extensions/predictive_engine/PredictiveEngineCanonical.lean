/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later
Author: Manuel Cabelguen
-/

import Cartograffect.PredictiveEngine
import Cartograffect.CoreAffect
import Cartograffect.PredictiveCircuit
import Cartograffect.AffectiveMatrix
import Cartograffect.AffectiveTaxonomy
import Cartograffect.OperantFactorization
import Cartograffect.EndToEndBridge

namespace Cartograffect

namespace PredictiveEngineCanonical

open PredictiveEngine
open CoreAffect
open PredictiveCircuit
open AffectiveMatrix
open AffectiveTaxonomy
open OperantFactorization
open EndToEndBridge

/-!
# Moteur Prédictif Canonique Unifié — Réalignement v3.0 (Options 1A, 2a, 3b, 4)

Extension formelle en Lean 4 raccordée aux types natifs du cœur normatif v3.0
(`PredictiveEngine`, `CoreAffect`, `PredictiveCircuit`, `AffectiveMatrix`,
`AffectiveTaxonomy`, `OperantFactorization`, `EndToEndBridge`), sans dépendance
envers `Lexicon176` ni aucune constante empirique externe (`0 sorry`, `0 admit`,
`0 native_decide`, `warningAsError := true`).

Formalise et certifie :
1. **Assemblage des réponses isolées et dynamique verticale pas-à-pas stricte (Option 2a)** :
   couplage typé des boucles `expectationLoop` (`{A0, A-, A+}`) et `controlLoop` (`{C0, C-, C+}`),
   énumération constructive exacte des réalisations admissibles de tout domaine attentionnel
   `{s_X, s_Y, Z}` (`Z ≥ 1`, excluant `Veille (0,0,0)`), rejet de tout saut vertical direct et
   conformité stricte à `isValidVerticalStep2a` (`ΔZ ∈ {-1, 0, +1}` avec unique court-circuit
   descendant `2 → 0`, cascades rapides `0 → 1 → 2 → … → Z`) ;
2. **Typage bayésien et postulat géométrique `L1`** : polarités signées `(s_X, s_Y) ∈ {-1, 0, +1}²`
   pondérées par des précisions `(π_A, π_C)`, base projective `(X_0, Y_0, 0)` au Croisement I
   (`|X_0| + |Y_0| = 2` hors Veille) et loi de couronne `|X| + |Y| = 2Z - 2` pour `Z ≥ 2` ;
3. **Bijection `Φ`, disjonction `Veille (0,0,0)` / `Z ≥ 1` et décroissance de Lyapunov** :
   décroissance stricte `V(dst) < V(src)` sur toute transition non triviale de résolution active
   (`ε = 0, χ = 0, δ = 0`) et séparation signée exacte sur `ℤ` d'avec l'extinction passive ;
4. **Ponts v3.0 vers `Z2ContingencyRegime` et `TaxonomicState` (Options 1A & 4)** :
   contingences bornées exclusivement à `Z = 2` (sans relèvement en `Z ≥ 3`) et indépendance du
   canal autonome `A ≥ 0` (`autonomousActivation`).
-/

/-!
## 1. Réponses isolées, domaines attentionnels et transitions verticales pas-à-pas (Option 2a)
-/

/-- Réponse isolée émise sur l'un des 3 circuits d'une boucle (`expectationLoop` ou `controlLoop`),
    sans projection directe de strate (conformément à l'Option 2a). -/
structure IsolatedCircuitResponse where
  loop     : CircuitLoop
  polarity : Polarity
  deriving DecidableEq, Repr, Inhabited

/-- Régime fonctionnel associé à une réponse isolée (`charge`, `neutral`, `discharge`). -/
def IsolatedCircuitResponse.regime (r : IsolatedCircuitResponse) : FunctionalRegime :=
  r.polarity.toRegime

/-- Assemblage typé d'une réponse subjective (`expectationLoop`) et d'une réponse perceptive
    (`controlLoop`) en un couplage `EngineCoupling` ; renvoie `none` si les boucles ne correspondent pas. -/
def assembleIsolatedResponses (respA respC : IsolatedCircuitResponse) : Option EngineCoupling :=
  if respA.loop == .expectationLoop && respC.loop == .controlLoop then
    some ⟨respA.polarity, respC.polarity⟩
  else
    none

/-- Caractérisation exacte de l'assemblage des réponses isolées sur leurs boucles respectives. -/
theorem assembleIsolatedResponses_iff
    (respA respC : IsolatedCircuitResponse) (c : EngineCoupling) :
    assembleIsolatedResponses respA respC = some c ↔
      respA.loop = .expectationLoop ∧
      respC.loop = .controlLoop ∧
      c = ⟨respA.polarity, respC.polarity⟩ := by
  rcases respA with ⟨la, pa⟩
  rcases respC with ⟨lc, pc⟩
  rcases c with ⟨ca, cc⟩
  cases la <;> cases lc <;> cases pa <;> cases pc <;> cases ca <;> cases cc <;> decide

/-- Domaine attentionnel symbolique `{s_X, s_Y, Z}` dans l'`INTERFACE ATTENTIONNELLE`.
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

/-- Nombre de réalisations discrètes entières contenues dans le domaine `{s_X, s_Y, Z}` :
    - `1` en `Z = 1` ou sur les domaines centraux/axiaux (un unique point entier admissible) ;
    - `2 * Z - 3` sur les quadrants doublement engagés en `Z = k + 2 ≥ 2` (`2 * k + 1` points
      vérifiant `|X| + |Y| = 2k + 2` avec `|X| ≥ 1` et `|Y| ≥ 1`). -/
def AttentionalPossibilityDomain.domainCardinality (d : AttentionalPossibilityDomain) : Nat :=
  match d.z with
  | 0     => 1
  | 1     => 1
  | k + 2 => if d.coupling.isDualEngaged then 2 * k + 1 else 1

/-- Énumération explicite exacte des coordonnées entières `CoreAffectPoint` réalisant le
    domaine attentionnel `d` à la strate `d.z`. -/
def AttentionalPossibilityDomain.realizations (d : AttentionalPossibilityDomain) : List CoreAffectPoint :=
  match d.z with
  | 0     => [⟨0, 0, 0⟩]
  | 1     => [⟨0, 0, 1⟩]
  | k + 2 =>
    let r := 2 * k + 2
    match d.coupling.attente, d.coupling.controle with
    | .zero, .zero => [⟨0, 0, k + 2⟩]
    | a,     .zero => [⟨signedAmplitude a r, 0, k + 2⟩]
    | .zero, ctrl  => [⟨0, signedAmplitude ctrl r, k + 2⟩]
    | a,     ctrl  =>
      (List.range (2 * k + 1)).map fun i =>
        let ax := i + 1
        let ay := r - ax
        ⟨signedAmplitude a ax, signedAmplitude ctrl ay, k + 2⟩

private theorem signedAmplitude_natAbs_engaged (pol : Polarity) (m : Nat)
    (h : pol.isEngaged = true) :
    (signedAmplitude pol m).natAbs = m := by
  cases pol with
  | zero => cases h
  | pos  => rfl
  | neg  => dsimp [signedAmplitude]; exact Int.natAbs_neg (m : Int)

/-- Adéquation et cardinalité exacte des réalisations d'un domaine attentionnel :
    1. La liste `d.realizations` a exactement pour longueur `d.domainCardinality ≥ 1`
       (et strictement plus d'une réalisation dès `d.z ≥ 3` en double engagement) ;
    2. Chaque coordonnée de `d.realizations` satisfait `isValidCoreAffect` et siège à la strate `d.z`. -/
theorem attentional_domain_realizations_valid_and_card (d : AttentionalPossibilityDomain) :
    d.realizations.length = d.domainCardinality ∧
    d.domainCardinality ≥ 1 ∧
    (d.z ≥ 3 → d.coupling.isDualEngaged = true → d.domainCardinality > 1) ∧
    (∀ p ∈ d.realizations, isValidCoreAffect p ∧ p.z = d.z) := by
  rcases d with ⟨⟨a, ctrl⟩, z, hz⟩
  refine ⟨?_, ?_, ?_, ?_⟩
  · cases z with
    | zero => omega
    | succ n =>
      cases n with
      | zero => rfl
      | succ k =>
        cases a <;> cases ctrl <;>
          simp [AttentionalPossibilityDomain.realizations,
            AttentionalPossibilityDomain.domainCardinality,
            EngineCoupling.isDualEngaged, Polarity.isEngaged]
  · cases z with
    | zero => omega
    | succ n =>
      cases n with
      | zero => exact Nat.le_refl 1
      | succ k =>
        dsimp [AttentionalPossibilityDomain.domainCardinality]
        split <;> omega
  · intro hz3 hdual
    dsimp only at hz3 hdual ⊢
    cases z with
    | zero => omega
    | succ n =>
      cases n with
      | zero => omega
      | succ k =>
        dsimp [AttentionalPossibilityDomain.domainCardinality]
        rw [hdual]
        simp only [↓reduceIte]
        omega
  · intro p hp
    dsimp only at hp ⊢
    cases z with
    | zero => omega
    | succ n =>
      cases n with
      | zero =>
        simp [AttentionalPossibilityDomain.realizations] at hp
        subst hp
        exact ⟨Or.inl ⟨rfl, rfl⟩, rfl⟩
      | succ k =>
        cases a with
        | zero =>
          cases ctrl with
          | zero =>
            simp [AttentionalPossibilityDomain.realizations] at hp
            subst hp
            exact ⟨Or.inl ⟨rfl, rfl⟩, rfl⟩
          | neg =>
            simp [AttentionalPossibilityDomain.realizations] at hp
            subst hp
            refine ⟨Or.inr ⟨by dsimp; omega, ?_⟩, rfl⟩
            dsimp [CoreAffectPoint.displacementSum, crownRadius]
            rw [signedAmplitude_natAbs_engaged .neg (2 * k + 2) rfl]
            omega
          | pos =>
            simp [AttentionalPossibilityDomain.realizations] at hp
            subst hp
            refine ⟨Or.inr ⟨by dsimp; omega, ?_⟩, rfl⟩
            dsimp [CoreAffectPoint.displacementSum, crownRadius]
            rw [signedAmplitude_natAbs_engaged .pos (2 * k + 2) rfl]
            omega
        | neg =>
          cases ctrl with
          | zero =>
            simp [AttentionalPossibilityDomain.realizations] at hp
            subst hp
            refine ⟨Or.inr ⟨by dsimp; omega, ?_⟩, rfl⟩
            dsimp [CoreAffectPoint.displacementSum, crownRadius]
            rw [signedAmplitude_natAbs_engaged .neg (2 * k + 2) rfl]
          | neg =>
            dsimp [AttentionalPossibilityDomain.realizations] at hp
            rw [List.mem_map] at hp
            rcases hp with ⟨i, hi, rfl⟩
            rw [List.mem_range] at hi
            refine ⟨Or.inr ⟨by dsimp; omega, ?_⟩, rfl⟩
            dsimp [CoreAffectPoint.displacementSum, crownRadius]
            rw [signedAmplitude_natAbs_engaged .neg (i + 1) rfl,
                signedAmplitude_natAbs_engaged .neg (2 * k + 2 - (i + 1)) rfl]
            omega
          | pos =>
            dsimp [AttentionalPossibilityDomain.realizations] at hp
            rw [List.mem_map] at hp
            rcases hp with ⟨i, hi, rfl⟩
            rw [List.mem_range] at hi
            refine ⟨Or.inr ⟨by dsimp; omega, ?_⟩, rfl⟩
            dsimp [CoreAffectPoint.displacementSum, crownRadius]
            rw [signedAmplitude_natAbs_engaged .neg (i + 1) rfl,
                signedAmplitude_natAbs_engaged .pos (2 * k + 2 - (i + 1)) rfl]
            omega
        | pos =>
          cases ctrl with
          | zero =>
            simp [AttentionalPossibilityDomain.realizations] at hp
            subst hp
            refine ⟨Or.inr ⟨by dsimp; omega, ?_⟩, rfl⟩
            dsimp [CoreAffectPoint.displacementSum, crownRadius]
            rw [signedAmplitude_natAbs_engaged .pos (2 * k + 2) rfl]
          | neg =>
            dsimp [AttentionalPossibilityDomain.realizations] at hp
            rw [List.mem_map] at hp
            rcases hp with ⟨i, hi, rfl⟩
            rw [List.mem_range] at hi
            refine ⟨Or.inr ⟨by dsimp; omega, ?_⟩, rfl⟩
            dsimp [CoreAffectPoint.displacementSum, crownRadius]
            rw [signedAmplitude_natAbs_engaged .pos (i + 1) rfl,
                signedAmplitude_natAbs_engaged .neg (2 * k + 2 - (i + 1)) rfl]
            omega
          | pos =>
            dsimp [AttentionalPossibilityDomain.realizations] at hp
            rw [List.mem_map] at hp
            rcases hp with ⟨i, hi, rfl⟩
            rw [List.mem_range] at hi
            refine ⟨Or.inr ⟨by dsimp; omega, ?_⟩, rfl⟩
            dsimp [CoreAffectPoint.displacementSum, crownRadius]
            rw [signedAmplitude_natAbs_engaged .pos (i + 1) rfl,
                signedAmplitude_natAbs_engaged .pos (2 * k + 2 - (i + 1)) rfl]
            omega

/-- Opérateur de transition verticale pas-à-pas vers un domaine attentionnel (`Z ≥ 1`)
    strictement conforme à l'Option 2a (`DECISIONS_V3.md`) :
    - `delta = 0` : maintien en strate `zSrc` (admissible ssi `zSrc ≥ 1`) ;
    - `delta = +1` : montée unitaire `zSrc → zSrc + 1` (incluant l'entrée `0 → 1` en Surprise) ;
    - `delta = -1` : descente unitaire `zSrc → zSrc - 1` uniquement pour `zSrc ≥ 3`
      (depuis `Z ∈ {1, 2}`, la redescente regagne `Veille (Z = 0)` hors de l'Interface Attentionnelle,
      sans jamais visiter `Surprise Z = 1` depuis `Z = 2`) ;
    - tout saut direct `|delta| ≥ 2` renvoie `none`. -/
def stepAttentionalDomain2a
    (zSrc : Nat) (cNext : EngineCoupling) (delta : Int) : Option AttentionalPossibilityDomain :=
  if delta == 0 then
    if h : zSrc ≥ 1 then some ⟨cNext, zSrc, h⟩ else none
  else if delta == 1 then
    some ⟨cNext, zSrc + 1, by omega⟩
  else if delta == -1 then
    if h : zSrc ≥ 3 then some ⟨cNext, zSrc - 1, by omega⟩ else none
  else
    none

/-- Correction et complétude de `stepAttentionalDomain2a` vis-à-vis de `isValidVerticalStep2a` :
    1. Toute transition acceptée par `stepAttentionalDomain2a` satisfait `isValidVerticalStep2a zSrc d.z` ;
    2. Inversement, toute transition `isValidVerticalStep2a zSrc zDst` aboutissant dans l'Interface
       Attentionnelle (`zDst ≥ 1`) est réalisée par `stepAttentionalDomain2a` avec `delta ∈ {-1, 0, +1}`
       (excluant tout saut direct `0 → Z ≥ 2`, `Z → Z + k` pour `k ≥ 2` et `2 → 1`). -/
theorem stepAttentionalDomain2a_sound_and_no_jump
    (zSrc : Nat) (cNext : EngineCoupling) :
    (∀ (delta : Int) (d : AttentionalPossibilityDomain),
      stepAttentionalDomain2a zSrc cNext delta = some d →
      isValidVerticalStep2a zSrc d.z ∧ d.coupling = cNext ∧ (delta = -1 ∨ delta = 0 ∨ delta = 1)) ∧
    (∀ (zDst : Nat) (hz : zDst ≥ 1),
      isValidVerticalStep2a zSrc zDst →
      ∃ delta : Int, stepAttentionalDomain2a zSrc cNext delta = some ⟨cNext, zDst, hz⟩) ∧
    (∀ zDst : Nat, zDst > zSrc + 1 → ¬ isValidVerticalStep2a zSrc zDst) ∧
    ¬ isValidVerticalStep2a 2 1 := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro delta d hstep
    unfold stepAttentionalDomain2a at hstep
    by_cases hd0 : delta = 0
    · subst hd0
      simp only [beq_self_eq_true, ↓reduceIte] at hstep
      split at hstep
      · cases hstep
        exact ⟨Or.inl rfl, rfl, Or.inr (Or.inl rfl)⟩
      · cases hstep
    · have hb0 : (delta == 0) = false := beq_false_of_ne hd0
      rw [hb0] at hstep
      simp only [Bool.false_eq_true, ↓reduceIte] at hstep
      by_cases hd1 : delta = 1
      · subst hd1
        simp only [beq_self_eq_true, ↓reduceIte, Option.some.injEq] at hstep
        subst hstep
        exact ⟨Or.inr (Or.inl rfl), rfl, Or.inr (Or.inr rfl)⟩
      · have hb1 : (delta == 1) = false := beq_false_of_ne hd1
        rw [hb1] at hstep
        simp only [Bool.false_eq_true, ↓reduceIte] at hstep
        by_cases hdm1 : delta = -1
        · subst hdm1
          simp only [beq_self_eq_true, ↓reduceIte] at hstep
          split at hstep
          · rename_i hz3
            cases hstep
            dsimp only
            exact ⟨Or.inr (Or.inr (Or.inl ⟨hz3, by omega⟩)), rfl, Or.inl rfl⟩
          · cases hstep
        · have hbm1 : (delta == -1) = false := beq_false_of_ne hdm1
          rw [hbm1] at hstep
          cases hstep
  · intro zDst hz hvalid
    rcases hvalid with rfl | rfl | ⟨hz3, hsub⟩ | ⟨_, hz0⟩
    · refine ⟨0, ?_⟩
      unfold stepAttentionalDomain2a
      simp [hz]
    · refine ⟨1, rfl⟩
    · refine ⟨-1, ?_⟩
      have heq : zDst = zSrc - 1 := by omega
      subst heq
      unfold stepAttentionalDomain2a
      simp [hz3]
    · omega
  · intro zDst hgt hvalid
    unfold isValidVerticalStep2a at hvalid
    omega
  · unfold isValidVerticalStep2a
    omega

/-- Cascade rapide pas-à-pas `0 → 1 → 2 → … → k + 1` (Option 2a : reformulation des effractions
    aiguës comme cascades séquentielles à constante de temps brève, sans saut discontinu) :
    depuis `Veille (Z = 0)`, `k + 1` pas unitaires `+1` atteignent exactement la strate `k + 1`
    tout en respectant `isValidVerticalStep2a` à chaque transition. -/
def cascadeAscentSteps (c : EngineCoupling) : Nat → AttentionalPossibilityDomain
  | 0     => ⟨c, 1, Nat.le_refl 1⟩
  | k + 1 =>
    let prev := cascadeAscentSteps c k
    ⟨c, prev.z + 1, by omega⟩

theorem cascadeAscentSteps_reaches_and_obeys_2a (c : EngineCoupling) (k : Nat) :
    (cascadeAscentSteps c k).z = k + 1 ∧
    isValidVerticalStep2a 0 (cascadeAscentSteps c 0).z ∧
    isValidVerticalStep2a (cascadeAscentSteps c k).z (cascadeAscentSteps c (k + 1)).z := by
  induction k with
  | zero =>
    exact ⟨rfl, Or.inr (Or.inl rfl), Or.inr (Or.inl rfl)⟩
  | succ n ih =>
    refine ⟨?_, Or.inr (Or.inl rfl), Or.inr (Or.inl rfl)⟩
    dsimp [cascadeAscentSteps]
    omega

/-- Projection géométrique certifiée d'un domaine attentionnel `{s_X, s_Y, Z}` vers le Noyau
    affectif (`CoreAffectPoint`) sous pondération de précision `(π_A, π_C)`.
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

/-!
## 2. Les Invariants structurels du Moteur Prédictif Canonique
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

/-- **Invariant 3 (Postulat géométrique d'échelle de couronne sur `ℤ`)** :
    Dans le plan perceptible de l'`INTERFACE ATTENTIONNELLE`, tout état actif à la strate `Z ≥ 2`
    vérifie exactement `|X| + |Y| = 2 * Z - 2` en arithmétique signée exacte sur `ℤ`. -/
theorem canonical_crown_scaling_law
    (c : EngineCoupling) (z piA piC : Nat) (susp : Bool)
    (h_active : c ≠ ⟨.zero, .zero⟩) (hz : z ≥ 2) :
    let pt := projectPerceptible c z piA piC susp
    (pt.x.natAbs : Int) + (pt.y.natAbs : Int) = 2 * (z : Int) - 2 := by
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

/-- Loi d'échelle exacte de `apportionRay` sur toute couronne `Z = d + 2 ≥ 2`. -/
theorem canonical_apportionRay_scaling (d piA piC : Nat) :
    let pair := apportionRay d piA piC
    pair.1 + pair.2 = 2 * d + 2 := by
  dsimp
  exact (apportionRay_bounds d piA piC).2.2

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

/-- Signature différentielle signée exacte sur `ℤ` entre résolution active et extinction passive
    depuis `(A-, C0)` :
    - Résolution active `(A-, C0) → (A+, C0)` : `V(src) - V(dst) = 1` sur `ℤ` et `activeResolutionCount = 1` ;
    - Extinction passive `(A-, C0) → (A0, C0)` : `V(src) - V(dst) = 2` sur `ℤ` et `activeResolutionCount = 0`. -/
theorem active_vs_passive_energy_signature :
    let src : EngineCoupling := ⟨.neg, .zero⟩
    let dstActive : EngineCoupling := ⟨.pos, .zero⟩
    let dstPassive : EngineCoupling := ⟨.zero, .zero⟩
    isActiveResolutionStep src dstActive ∧
    isPassiveExtinctionStep src dstPassive ∧
    activeResolutionCount src dstActive = 1 ∧
    activeResolutionCount src dstPassive = 0 ∧
    (lyapunovPotential src : Int) - (lyapunovPotential dstActive : Int) = 1 ∧
    (lyapunovPotential src : Int) - (lyapunovPotential dstPassive : Int) = 2 := by
  refine ⟨⟨by decide, Or.inr rfl, Or.inl rfl⟩, Or.inl rfl, rfl, rfl, rfl, rfl⟩

/-!
## 3. Ponts v3.0 vers `Z2ContingencyRegime` et `TaxonomicState` (Options 1A & 4)
-/

/-- Pont borné à `Z = 2` pour la projection des domaines attentionnels :
    - En `d.z = 2`, `diagToContingency` coïncide exactement avec `couplingToZ2Contingency d.coupling` ;
    - En toute autre strate `d.z ≠ 2` (`d.z = 1` ou `d.z ≥ 3`), `diagToContingency` renvoie `none`
      (aucun relèvement universel des contingences opérantes sur `Z ≥ 3`). -/
theorem canonical_project_z2_contingency_bound
    (d : AttentionalPossibilityDomain) (piA piC : Nat) :
    (d.z = 2 → diagToContingency (projectAttentionalDomain d piA piC) = couplingToZ2Contingency d.coupling) ∧
    (d.z ≠ 2 → diagToContingency (projectAttentionalDomain d piA piC) = none) := by
  constructor
  · intro hz2
    unfold projectAttentionalDomain
    split
    · rename_i hneut
      rw [hz2]
      have hnone : couplingToZ2Contingency d.coupling = none := by
        rcases d with ⟨⟨a, ctrl⟩, z, hzpos⟩
        cases a <;> cases ctrl <;>
          first
          | rfl
          | (dsimp only [EngineCoupling.isGlobalNeutrality, Polarity.isEngaged] at hneut; cases hneut)
      rw [hnone]
      rfl
    · rw [hz2]
      exact (circuit_coupling_z2_contingency_bridge d.coupling 2 piA piC true).1
  · intro hne2
    apply active_r_minus_vs_pavlovian_safety_and_z2_bound.2.2
    rw [projectAttentionalDomain_z d piA piC]
    exact hne2

/-- Toute projection d'un domaine attentionnel produit un état taxonomique terminal valide,
    strictement disjoint du `Point de Veille` (`stratum ≠ .z0_pointDeVeille`), indépendant du canal
    autonome `a : Nat` (`A ≥ 0`, Option 1A), et rattaché aux régimes discrets normatifs `0..5` ssi `d.z ≤ 5`. -/
theorem canonical_attentional_domain_to_taxonomy_coherent
    (d : AttentionalPossibilityDomain) (piA piC a : Nat) :
    let st : CoreAffectState := ⟨projectAttentionalDomain d piA piC, projectAttentionalDomain_valid d piA piC⟩
    let ts := evaluateTaxonomy (evaluateMatrix st a canonicalMapping)
    let cp := ts.matrix.core.point
    let ap := ts.matrix.antagonist.point
    isValidCoreAffect cp ∧
    isValidCoreAffect ap ∧
    ts.matrix.autonomousActivation = a ∧
    ts.stratum ≠ .z0_pointDeVeille ∧
    (d.z ≤ 5 ↔ ts.stratum ≠ .zExploratoryExtension d.z) ∧
    ts.subsector.toTaxonomicGroup = ts.group ∧
    ts.subsector.toHedonicPolarity = ts.matrix.valence ∧
    matchesTaxonomicGroup cp ts.group ∧
    matchesTaxonomicGroup ap ts.antagonistGroup := by
  dsimp only [evaluateTaxonomy, evaluateMatrix, canonicalMapping]
  have hvc : isValidCoreAffect (projectAttentionalDomain d piA piC) :=
    projectAttentionalDomain_valid d piA piC
  have hva : isValidCoreAffect (antagonistPoint (projectAttentionalDomain d piA piC)) :=
    antagonistPoint_preserves_validity _ hvc
  have hz_eq : (projectAttentionalDomain d piA piC).z = d.z :=
    projectAttentionalDomain_z d piA piC
  have hz_pos : d.z ≥ 1 := d.h_z_pos
  have h_not_z0 : classifyStratum (projectAttentionalDomain d piA piC).z ≠ .z0_pointDeVeille := by
    rw [hz_eq]
    cases hdz : d.z with
    | zero => omega
    | succ n =>
      cases n with
      | zero => simp [classifyStratum]
      | succ m =>
        cases m with | zero => simp [classifyStratum] | succ m =>
        cases m with | zero => simp [classifyStratum] | succ m =>
        cases m with | zero => simp [classifyStratum] | succ m =>
        cases m with | zero => simp [classifyStratum] | succ _ => simp [classifyStratum]
  have h_norm5 : d.z ≤ 5 ↔ classifyStratum (projectAttentionalDomain d piA piC).z ≠ .zExploratoryExtension d.z := by
    rw [hz_eq]
    cases hdz : d.z with
    | zero => omega
    | succ n =>
      cases n with
      | zero => simp [classifyStratum]
      | succ m =>
        cases m with | zero => simp [classifyStratum] | succ m =>
        cases m with | zero => simp [classifyStratum] | succ m =>
        cases m with | zero => simp [classifyStratum] | succ m =>
        cases m with | zero => simp [classifyStratum] | succ k => simp [classifyStratum]
  exact ⟨hvc, hva, rfl, h_not_z0, h_norm5, classifySubsector_refines_group _,
    classifySubsector_determines_valence _ _,
    classifyTaxonomicGroup_correct _, classifyTaxonomicGroup_correct _⟩

/-!
## 4. Audit axiomatique (#print axioms)
-/

#print axioms assembleIsolatedResponses_iff
#print axioms attentional_domain_realizations_valid_and_card
#print axioms stepAttentionalDomain2a_sound_and_no_jump
#print axioms cascadeAscentSteps_reaches_and_obeys_2a
#print axioms projectAttentionalDomain_valid
#print axioms projectAttentionalDomain_z
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
#print axioms canonical_project_z2_contingency_bound
#print axioms canonical_attentional_domain_to_taxonomy_coherent

end PredictiveEngineCanonical

end Cartograffect
