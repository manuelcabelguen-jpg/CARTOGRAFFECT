/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later
Author: Manuel Cabelguen
-/

import Cartograffect.PredictiveEngine
import Cartograffect.CoreAffect
import Cartograffect.AffectiveMatrix

namespace Cartograffect

namespace PredictiveCircuit

open PredictiveEngine
open CoreAffect
open AffectiveMatrix

/-!
# Architecture circulaire à 6 opérateurs du Moteur prédictif (Figure 1)

Ce module formalise la boucle fermée continue reliant les trois interfaces du Moteur prédictif
(`Subjective`, `Perceptive`, `Attentionnelle`) à travers deux boucles à trois circuits
(`Attente` `{A0, A-, A+}` et `Contrôle` `{C0, C-, C+}`) et six opérations de frontière :
1. `subjectiveOut` / `perceptiveOut` : émissions internes (`Anticipation [0,0,Z]` et `Surprise [0,0,1]`) ;
2. `attentionalCrossingI` : Croisement I perceptible par l'Agent `(X,Y,0) → (X,Y,Z)` et émission
   des voies réflexive (ascendante) et comportementale (descendante vers `Corps & Environnement`) ;
3. `attentionalCrossingII` : Croisement II rétroactif sub-personnel `[A/C]` (transposé du Croisement I) ;
4. `subjectiveIn` / `perceptiveIn` : réintégration des 9 canaux `A/C` et `C/A` avec les retours
   réflexifs et afférents au sein des états cachés.

Sans dépendance externe (noyau Lean 4 et `Init` uniquement).
-/

/-!
## 1. Les deux boucles à trois circuits et les six opérations de frontière
-/

/-- Les deux boucles de régulation de l'incertitude circulant à travers le Moteur. -/
inductive CircuitLoop : Type where
  | expectationLoop : CircuitLoop -- Boucle épistémique d'Attente : {A0, A-, A+} (milieu interne)
  | controlLoop     : CircuitLoop -- Boucle pragmatique de Contrôle : {C0, C-, C+} (milieu externe)
  deriving DecidableEq, Repr, Inhabited

/-- Versant interne (émission / projection perceptible) ou externe (rétroaction / intégration). -/
inductive InterfaceSide : Type where
  | internal : InterfaceSide
  | external : InterfaceSide
  deriving DecidableEq, Repr, Inhabited

/-- Les six opérations constitutives du circuit computationnel continu (Figure 1). -/
inductive CircuitOperation : Type where
  | subjectiveOut         : CircuitOperation -- [États cachés subj.] --Anticipation--> (+X, -X, 0)
  | perceptiveOut         : CircuitOperation -- [États cachés perc.] --Surprise------> (+Y, -Y, 0)
  | attentionalCrossingI  : CircuitOperation -- Croisement I perceptible : (X,Y,0) -> (X,Y,Z)
  | attentionalCrossingII : CircuitOperation -- Croisement II sub-personnel : [A/C] -> flux
  | subjectiveIn          : CircuitOperation -- 9 canaux A/C + voie réflexive -> [États cachés subj.]
  | perceptiveIn          : CircuitOperation -- 9 canaux C/A + signaux afférents -> [États cachés perc.]
  deriving DecidableEq, Repr, Inhabited

/-- Liste exhaustive des six opérations du circuit continu. -/
def allCircuitOperations : List CircuitOperation := [
  .subjectiveOut,
  .perceptiveOut,
  .attentionalCrossingI,
  .attentionalCrossingII,
  .subjectiveIn,
  .perceptiveIn
]

/-- Interface porteuse de chaque opération du circuit. -/
def CircuitOperation.carrierInterface : CircuitOperation → EngineInterface
  | .subjectiveOut         => .subjective
  | .subjectiveIn          => .subjective
  | .perceptiveOut         => .perceptive
  | .perceptiveIn          => .perceptive
  | .attentionalCrossingI  => .attentional
  | .attentionalCrossingII => .attentional

/-- Versant (interne ou externe) sur lequel s'opère chaque transformation ou croisement. -/
def CircuitOperation.side : CircuitOperation → InterfaceSide
  | .subjectiveOut         => .internal
  | .perceptiveOut         => .internal
  | .attentionalCrossingI  => .internal
  | .attentionalCrossingII => .external
  | .subjectiveIn          => .external
  | .perceptiveIn          => .external

/-- Indique l'unique croisement dont la sortie est directement perceptible par l'Agent. -/
def CircuitOperation.isAgentPerceptible : CircuitOperation → Bool
  | .attentionalCrossingI => true
  | _                     => false

/-- Rattachement des 6 opérations de frontière aux 4 opérations inférentielles de `PredictiveEngine`. -/
def CircuitOperation.toInferentialOperation : CircuitOperation → InferentialOperation
  | .subjectiveOut         => .contextualGenerative
  | .subjectiveIn          => .contextualGenerative
  | .perceptiveOut         => .actionImplementation
  | .perceptiveIn          => .ascendingSensory
  | .attentionalCrossingI  => .integrativeWeighting
  | .attentionalCrossingII => .integrativeWeighting

/-- Le circuit computationnel continu comporte exactement 6 opérations. -/
theorem allCircuitOperations_card : allCircuitOperations.length = 6 := rfl

/-- Complétude de `allCircuitOperations`. -/
theorem mem_allCircuitOperations (op : CircuitOperation) : op ∈ allCircuitOperations := by
  cases op <;> decide

/-- Chaque couple `(interface, versant)` est réalisé par une unique opération du circuit. -/
theorem circuit_covers_interfaces_both_sides (iface : EngineInterface) (s : InterfaceSide) :
    ∃ op : CircuitOperation,
      op.carrierInterface = iface ∧
      op.side = s ∧
      ∀ op', op'.carrierInterface = iface → op'.side = s → op' = op := by
  cases iface <;> cases s <;>
    first
    | exact ⟨.perceptiveOut, rfl, rfl, fun op' h1 h2 => by cases op' <;> cases h1 <;> cases h2 <;> rfl⟩
    | exact ⟨.perceptiveIn, rfl, rfl, fun op' h1 h2 => by cases op' <;> cases h1 <;> cases h2 <;> rfl⟩
    | exact ⟨.subjectiveOut, rfl, rfl, fun op' h1 h2 => by cases op' <;> cases h1 <;> cases h2 <;> rfl⟩
    | exact ⟨.subjectiveIn, rfl, rfl, fun op' h1 h2 => by cases op' <;> cases h1 <;> cases h2 <;> rfl⟩
    | exact ⟨.attentionalCrossingI, rfl, rfl, fun op' h1 h2 => by cases op' <;> cases h1 <;> cases h2 <;> rfl⟩
    | exact ⟨.attentionalCrossingII, rfl, rfl, fun op' h1 h2 => by cases op' <;> cases h1 <;> cases h2 <;> rfl⟩

/-- Surjection des 6 opérations de circuit sur les 4 opérations inférentielles. -/
theorem circuit_refines_inferential_ops (iop : InferentialOperation) :
    ∃ op : CircuitOperation, op.toInferentialOperation = iop := by
  cases iop
  · exact ⟨.perceptiveIn, rfl⟩
  · exact ⟨.perceptiveOut, rfl⟩
  · exact ⟨.subjectiveOut, rfl⟩
  · exact ⟨.attentionalCrossingI, rfl⟩

/-- La projection vers `InferentialOperation` conserve exactement l'interface porteuse. -/
theorem circuit_preserves_carrier (op : CircuitOperation) :
    op.toInferentialOperation.carrierInterface = op.carrierInterface := by
  cases op <;> rfl

/-- Seul le Croisement Attentionnel I est perceptible par l'Agent. -/
theorem unique_agent_perceptible_crossing (op : CircuitOperation) :
    op.isAgentPerceptible = true ↔ op = .attentionalCrossingI := by
  cases op <;> decide

/-!
## 2. Bijection L1 `Φ : Ω_II ↔ Ω_I`, transposition I ↔ II et 9 canaux `A/C`, `C/A`
-/

/-- Nœud proto-spatial `(X, Y)` au Croisement I avant élévation sur la strate `Z`. -/
structure ProtoSpatialNode where
  x : Int
  y : Int
  deriving DecidableEq, Repr, Inhabited

/-- Norme `L1` dans le plan proto-spatial `(X, Y)`. -/
def ProtoSpatialNode.l1Norm (n : ProtoSpatialNode) : Nat :=
  n.x.natAbs + n.y.natAbs

/-- Admissibilité proto-spatiale : origine `(0, 0)` (Veille) ou losange `|X| + |Y| = 2`. -/
def isValidProtoSpatial (n : ProtoSpatialNode) : Prop :=
  (n.x = 0 ∧ n.y = 0) ∨ n.l1Norm = 2

/-- Opérateur `Φ` projetant les 9 couplages `[A/C]` du Croisement II vers les 9 nœuds `(X, Y, 0)`. -/
def phiL1 (c : EngineCoupling) : ProtoSpatialNode :=
  match c.attente, c.controle with
  | .zero, .zero => ⟨0, 0⟩
  | .pos,  .zero => ⟨2, 0⟩
  | .neg,  .zero => ⟨-2, 0⟩
  | .zero, .pos  => ⟨0, 2⟩
  | .zero, .neg  => ⟨0, -2⟩
  | .pos,  .pos  => ⟨1, 1⟩
  | .pos,  .neg  => ⟨1, -1⟩
  | .neg,  .pos  => ⟨-1, 1⟩
  | .neg,  .neg  => ⟨-1, -1⟩

/-- Conversion du signe entier en polarité discrète. -/
def polarityOfInt (v : Int) : Polarity :=
  if v > 0 then .pos else if v < 0 then .neg else .zero

/-- Opérateur réciproque `Φ⁻¹` restituant le couplage `[A/C]` depuis un nœud `(X, Y)`. -/
def phiL1Inv (n : ProtoSpatialNode) : EngineCoupling :=
  ⟨polarityOfInt n.x, polarityOfInt n.y⟩

private def idxAttente : Polarity → Nat
  | .zero => 0
  | .neg  => 1
  | .pos  => 2

private def idxControle : Polarity → Nat
  | .pos  => 0
  | .neg  => 1
  | .zero => 2

/-- Position `(ligne, colonne)` dans la grille 3×3 du Croisement I (Veille en `(0, 2)`). -/
def crossingIPos (c : EngineCoupling) : Nat × Nat :=
  (idxAttente c.attente, idxControle c.controle)

/-- Position `(ligne, colonne)` dans la grille 3×3 du Croisement II (`[A0/C0]` en `(2, 0)`). -/
def crossingIIPos (c : EngineCoupling) : Nat × Nat :=
  (idxControle c.controle, idxAttente c.attente)

/-- Canal de retour orienté vers les `[États cachés]` de l'Interface Subjective (`A/C`). -/
structure SubjectiveReturnChannel where
  regimeA  : FunctionalRegime
  contextC : Polarity
  deriving DecidableEq, Repr, Inhabited

/-- Canal de retour orienté vers les `[États cachés]` de l'Interface Perceptive (`C/A`). -/
structure PerceptiveReturnChannel where
  regimeC  : FunctionalRegime
  contextA : Polarity
  deriving DecidableEq, Repr, Inhabited

/-- Routage sub-personnel des 9 nœuds du Croisement II vers les 9 entrées `A/C` de l'Interface Subjective. -/
def routeToSubjective (c : EngineCoupling) : SubjectiveReturnChannel :=
  ⟨c.attente.toRegime, c.controle⟩

/-- Routage sub-personnel des 9 nœuds du Croisement II vers les 9 entrées `C/A` de l'Interface Perceptive. -/
def routeToPerceptive (c : EngineCoupling) : PerceptiveReturnChannel :=
  ⟨c.controle.toRegime, c.attente⟩

/-- Tout couplage `[A/C]` se projette sur un nœud proto-spatial admissible. -/
theorem phiL1_valid (c : EngineCoupling) : isValidProtoSpatial (phiL1 c) := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> first
      | exact Or.inl ⟨rfl, rfl⟩
      | exact Or.inr rfl

/-- Conservation stricte `|X| + |Y| = 2` pour tout couplage actif (hors Veille). -/
theorem phiL1_l1Norm_active (c : EngineCoupling) (h : c.isGlobalNeutrality = false) :
    (phiL1 c).l1Norm = 2 := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> first
      | contradiction
      | decide

/-- Inverse à gauche de `Φ` : `Φ⁻¹(Φ(A, C)) = (A, C)`. -/
theorem phiL1_left_inv (c : EngineCoupling) : phiL1Inv (phiL1 c) = c := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> rfl

/-- Inverse à droite de `Φ` sur tout nœud proto-spatial admissible : `Φ(Φ⁻¹(X, Y)) = (X, Y)`. -/
theorem phiL1_right_inv (n : ProtoSpatialNode) (h : isValidProtoSpatial n) :
    phiL1 (phiL1Inv n) = n := by
  obtain ⟨x, y⟩ := n
  rcases h with ⟨hx, hy⟩ | hl
  · subst hx hy
    rfl
  · unfold ProtoSpatialNode.l1Norm at hl
    dsimp only at hl
    have hx_cases : x = -2 ∨ x = -1 ∨ x = 0 ∨ x = 1 ∨ x = 2 := by omega
    have hy_cases : y = -2 ∨ y = -1 ∨ y = 0 ∨ y = 1 ∨ y = 2 := by omega
    rcases hx_cases with rfl | rfl | rfl | rfl | rfl <;>
    rcases hy_cases with rfl | rfl | rfl | rfl | rfl <;>
      first | omega | decide

/-- Accord exact entre `phiL1` et les coordonnées `(X, Y)` déployées à `Z = 2` dans `CoreAffect`. -/
theorem phiL1_agrees_with_deployZ2 (c : EngineCoupling) :
    (phiL1 c).x = (deployCouplingAtDepth c 0).x ∧
    (phiL1 c).y = (deployCouplingAtDepth c 0).y := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> exact ⟨rfl, rfl⟩

/-- Dualité transposée exacte entre le Croisement I et le Croisement II. -/
theorem crossingII_is_transpose_of_crossingI (c : EngineCoupling) :
    crossingIIPos c = ((crossingIPos c).2, (crossingIPos c).1) := rfl

/-- Les 9 canaux `A/C` vers l'Interface Subjective sont deux à deux distincts (injectivité). -/
theorem routeToSubjective_injective (c1 c2 : EngineCoupling)
    (h : routeToSubjective c1 = routeToSubjective c2) : c1 = c2 := by
  cases c1 with
  | mk a1 ctrl1 =>
    cases c2 with
    | mk a2 ctrl2 =>
      cases a1 <;> cases ctrl1 <;> cases a2 <;> cases ctrl2 <;>
        first | rfl | cases h

/-- Les 9 canaux `C/A` vers l'Interface Perceptive sont deux à deux distincts (injectivité). -/
theorem routeToPerceptive_injective (c1 c2 : EngineCoupling)
    (h : routeToPerceptive c1 = routeToPerceptive c2) : c1 = c2 := by
  cases c1 with
  | mk a1 ctrl1 =>
    cases c2 with
    | mk a2 ctrl2 =>
      cases a1 <;> cases ctrl1 <;> cases a2 <;> cases ctrl2 <;>
        first | rfl | cases h

/-!
## 3. Projection perceptible `Π_Z` certifiée dans `CoreAffectState`
-/

/--
Projection perceptible par l'Agent `Π_Z` réalisant le passage `(X, Y, 0) → (X, Y, Z)` du Croisement I
tout en respectant strictement la loi géométrique des couronnes de `CoreAffect` :
- `Veille (A0, C0)` sans suspension descendante → `(0, 0, 0)` ; avec suspension dès `Z ≥ 2` → `(0, 0, Z)` ;
- Couplage actif à `Z = 0` → `(0, 0, 0)` ; à `Z = 1` → `Surprise (0, 0, 1)` ;
- Couplage actif à `Z = d + 2 ≥ 2` → couronne `R(Z) = 2Z - 2` au prorata de `(piA, piC)`.
-/
def projectPerceptible (c : EngineCoupling) (z piA piC : Nat) (descendingSusp : Bool) :
    CoreAffectPoint :=
  if c.isGlobalNeutrality then
    if descendingSusp && decide (z ≥ 2) then ⟨0, 0, z⟩ else ⟨0, 0, 0⟩
  else
    match z with
    | 0     => ⟨0, 0, 0⟩
    | 1     => ⟨0, 0, 1⟩
    | d + 2 => deployCouplingWithPrecision c d piA piC

/-- La projection perceptible produit toujours une coordonnée géométriquement valide dans `CoreAffect`. -/
theorem projectPerceptible_valid (c : EngineCoupling) (z piA piC : Nat) (susp : Bool) :
    isValidCoreAffect (projectPerceptible c z piA piC susp) := by
  unfold projectPerceptible
  split
  · split <;> exact Or.inl ⟨rfl, rfl⟩
  · cases z with
    | zero => exact Or.inl ⟨rfl, rfl⟩
    | succ n =>
      cases n with
      | zero => exact Or.inl ⟨rfl, rfl⟩
      | succ d => exact deployCouplingWithPrecision_valid c d piA piC

/-- Constructeur certifié reliant directement le circuit continu à `CoreAffectState`. -/
def projectPerceptibleState (c : EngineCoupling) (z piA piC : Nat) (descendingSusp : Bool) :
    CoreAffectState :=
  { point   := projectPerceptible c z piA piC descendingSusp
    h_valid := projectPerceptible_valid c z piA piC descendingSusp }

/-- En strate `Z = 2`, `projectPerceptible` relève exactement les coordonnées `(X, Y)` de `phiL1` sur `Z = 2`. -/
theorem projectPerceptible_z2_matches_phiL1 (c : EngineCoupling)
    (h : c.isGlobalNeutrality = false) (piA piC : Nat) (susp : Bool) :
    projectPerceptible c 2 piA piC susp = ⟨(phiL1 c).x, (phiL1 c).y, 2⟩ := by
  have h_nn : ¬(c.attente = .zero ∧ c.controle = .zero) := by
    intro ⟨h1, h2⟩
    have hz : c = ⟨.zero, .zero⟩ := by cases c; simp_all
    rw [hz] at h
    exact absurd h (by decide)
  cases c with
  | mk a ctrl =>
    dsimp at h_nn
    cases a <;> cases ctrl
    all_goals first
      | exact absurd ⟨rfl, rfl⟩ h_nn
      | (dsimp [projectPerceptible, deployCouplingWithPrecision, phiL1, signedAmplitude,
           EngineCoupling.isGlobalNeutrality, Polarity.isEngaged]
         try rw [apportionRay_z2 piA piC]
         try rfl)

/-- En neutralité globale sous suspension descendante active (`Z ≥ 2`), `Veille` se projette au centre `(0, 0, Z)`. -/
theorem projectPerceptible_neutral_elevates_to_central (z piA piC : Nat) (hz : z ≥ 2) :
    projectPerceptible ⟨.zero, .zero⟩ z piA piC true = ⟨0, 0, z⟩ := by
  unfold projectPerceptible
  simp [EngineCoupling.isGlobalNeutrality, Polarity.isEngaged, hz]

/-!
## 4. Goulot attentionnel `L1`, potentiel de Lyapunov `V` et cohérence interne/externe
-/

/-- Poids attentionnel doublé (`2 * w_X ∈ {1, 2}`) sur la boucle d'Attente. -/
def attentionalWeightX2 (c : EngineCoupling) : Nat :=
  if c.attente == .zero then 2 else (phiL1 c).x.natAbs

/-- Poids attentionnel doublé (`2 * w_Y ∈ {1, 2}`) sur la boucle de Contrôle. -/
def attentionalWeightY2 (c : EngineCoupling) : Nat :=
  if c.controle == .zero then 2 else (phiL1 c).y.natAbs

/-- Énergie élémentaire d'une polarité : Neutre = 0, Décharge = 1, Charge = 2. -/
def polarityEnergy : Polarity → Nat
  | .zero => 0
  | .pos  => 1
  | .neg  => 2

/-- Potentiel de Lyapunov discret mesurant l'écart résiduel du couplage `(A, C)`. -/
def lyapunovPotential (c : EngineCoupling) : Nat :=
  polarityEnergy c.attente + polarityEnergy c.controle

/-- Typologie fonctionnelle de la cohérence entre milieu interne (Attente) et milieu externe (Contrôle). -/
inductive InternalExternalCoherence : Type where
  | homeostaticEquilibrium : InternalExternalCoherence -- [A0/C0] : Veille
  | axialUnilateral        : InternalExternalCoherence -- Un seul gradient mobilisé
  | congruentDischarge     : InternalExternalCoherence -- [A+/C+] : Désir / maîtrise conjointe
  | compensatoryTension    : InternalExternalCoherence -- [A-/C+] ou [A+/C-] : Colère / Calme
  | doubleChargeImpasse    : InternalExternalCoherence -- [A-/C-] : Dégoût / double charge
  deriving DecidableEq, Repr, Inhabited

/-- Classe la cohérence interne/externe d'un couplage `(A, C)`. -/
def classifyCoherence (c : EngineCoupling) : InternalExternalCoherence :=
  match c.attente, c.controle with
  | .zero, .zero => .homeostaticEquilibrium
  | .zero, _     => .axialUnilateral
  | _,     .zero => .axialUnilateral
  | .pos,  .pos  => .congruentDischarge
  | .neg,  .neg  => .doubleChargeImpasse
  | _,     _     => .compensatoryTension

/-- Conservation du goulot attentionnel (`w_X + w_Y = 1`, soit `2w_X + 2w_Y = 2`) sur tout état actif. -/
theorem attentional_bottleneck_sum_active (c : EngineCoupling) (h : c.isGlobalNeutrality = false) :
    (if c.attente.isEngaged then attentionalWeightX2 c else 0) +
    (if c.controle.isEngaged then attentionalWeightY2 c else 0) = 2 := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> first
      | contradiction
      | decide

/-- Le potentiel de Lyapunov s'annule exclusivement en Veille `(A0, C0)`. -/
theorem lyapunovPotential_zero_iff (c : EngineCoupling) :
    lyapunovPotential c = 0 ↔ c = ⟨.zero, .zero⟩ := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> decide

/-- Le potentiel de Lyapunov est borné supérieurement par 4. -/
theorem lyapunovPotential_le_four (c : EngineCoupling) :
    lyapunovPotential c ≤ 4 := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> decide

/-- Le potentiel de Lyapunov atteint son maximum 4 exclusivement en Double Charge `(A-, C-)`. -/
theorem lyapunovPotential_max_iff (c : EngineCoupling) :
    lyapunovPotential c = 4 ↔ c = ⟨.neg, .neg⟩ := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> decide

/-!
## 5. Noyau markovien couplé exact du circuit continu (`CircuitKernelParams`, `circuitWeight`)

Intègre les axes (i)–(iii) :
- Extinction passive (`deltaA`, `deltaC`) vs résolution active (`rho`, `kappa` puis `gammaA`, `gammaC`) ;
- Indépendance entre contrainte allocative `L1` (`w2 ∈ {1, 2}`) et contagion croisée `chi` portée
  exclusivement par une Charge complémentaire (`effectiveEpsScaled`) ;
- Typologie des ruptures topologiques et fonctionnelles d'ergodicité.
-/

/-- Prédicat booléen caractérisant un état de Charge (`Polarity.neg`). -/
def isCharged : Polarity → Bool
  | .neg => true
  | _    => false

/--
Paramètres structurels rationnels exacts (sur dénominateur entier `scale > 0`)
régissant les transitions du circuit continu sur les 9 configurations `(A, C)` :
- `rho`, `kappa` : révisabilité subjective et contrôlabilité perçue (résolution active `- -> +`) ;
- `deltaA`, `deltaC` : taux d'extinction passive (`- -> 0`, sans passage par `+`) ;
- `gammaA`, `gammaC` : taux de désengagement homéostatique (`+ -> 0`) ;
- `epsilon` : volatilité exogène issue de `Corps & Environnement` ;
- `qPosA`, `qPosC` : propension directe vers la décharge (`0 -> +`) sous perturbation ;
- `chi` : opérateur causal inter-boucles P2 majorant la surprise sur l'axe complémentaire en Charge.
-/
structure CircuitKernelParams where
  scale       : Nat
  rho         : Nat
  kappa       : Nat
  deltaA      : Nat
  deltaC      : Nat
  gammaA      : Nat
  gammaC      : Nat
  epsilon     : Nat
  qPosA       : Nat
  qPosC       : Nat
  chi         : Nat
  h_scale_pos : scale > 0
  h_rho_le    : rho ≤ scale
  h_kap_le    : kappa ≤ scale
  h_da_le     : deltaA ≤ scale
  h_dc_le     : deltaC ≤ scale
  h_rho_da_le : rho + deltaA ≤ scale
  h_kap_dc_le : kappa + deltaC ≤ scale
  h_ga_le     : gammaA ≤ scale
  h_gc_le     : gammaC ≤ scale
  h_eps_le    : epsilon ≤ scale
  h_qa_le     : qPosA ≤ scale
  h_qc_le     : qPosC ≤ scale
  h_chi_le    : chi ≤ scale
  deriving DecidableEq, Repr

/-- Profil homéostatique par défaut (base 100, régime circulaire avec bifurcation P2 active et `delta = 0`). -/
instance : Inhabited CircuitKernelParams where
  default := {
    scale       := 100
    rho         := 80
    kappa       := 80
    deltaA      := 0
    deltaC      := 0
    gammaA      := 70
    gammaC      := 70
    epsilon     := 15
    qPosA       := 35
    qPosC       := 35
    chi         := 25
    h_scale_pos := by decide
    h_rho_le    := by decide
    h_kap_le    := by decide
    h_da_le     := by decide
    h_dc_le     := by decide
    h_rho_da_le := by decide
    h_kap_dc_le := by decide
    h_ga_le     := by decide
    h_gc_le     := by decide
    h_eps_le    := by decide
    h_qa_le     := by decide
    h_qc_le     := by decide
    h_chi_le    := by decide
  }

/--
Taux de surprise effectif exact sur dénominateur `M^2` :
`eps_eff(otherCharged) = eps + chi * (1 - eps) * I(otherCharged)`
codé exactement en entiers comme `M * eps + chi * (M - eps)` lorsque l'axe complémentaire est en Charge.
-/
def effectiveEpsScaled (M eps chi : Nat) (otherCharged : Bool) : Nat :=
  if otherCharged then M * eps + chi * (M - eps) else M * eps

private theorem effectiveEpsScaled_le (M eps chi : Nat) (otherCharged : Bool)
    (h_eps : eps ≤ M) (h_chi : chi ≤ M) :
    effectiveEpsScaled M eps chi otherCharged ≤ M * M := by
  unfold effectiveEpsScaled
  split
  · have h1 : chi * (M - eps) ≤ M * (M - eps) := Nat.mul_le_mul_right (M - eps) h_chi
    have h2 : M * eps + M * (M - eps) = M * M := by
      rw [← Nat.mul_add, Nat.add_sub_of_le h_eps]
    omega
  · exact Nat.mul_le_mul_left M h_eps

private theorem effectiveEpsScaled_sub_pos (M eps chi : Nat) (otherCharged : Bool)
    (h_eps : eps < M) (h_chi : chi < M) :
    M * M - effectiveEpsScaled M eps chi otherCharged > 0 := by
  unfold effectiveEpsScaled
  cases otherCharged
  · dsimp
    have h1 : M * eps < M * M := Nat.mul_lt_mul_of_pos_left h_eps (by omega)
    omega
  · dsimp
    have hme : M - eps > 0 := by omega
    have h1 : chi * (M - eps) < M * (M - eps) := Nat.mul_lt_mul_of_pos_right h_chi hme
    have h2 : M * eps + M * (M - eps) = M * M := by
      rw [← Nat.mul_add, Nat.add_sub_of_le (Nat.le_of_lt h_eps)]
    omega

/--
Poids entier marginal d'une boucle sur la base `{.zero, .neg, .pos}` (somme exacte `2 * M^3`).
Intègre :
- l'extinction passive `delta` (`- -> 0`) distincte de la résolution active `w2 * rate` (`- -> +`) ;
- la contrainte allocative P1 (`w2 ∈ {1, 2}`) et la propension directe `qPos` (`0 -> +`) ;
- la contagion croisée P2 exacte `e2 = effectiveEpsScaled M eps chi otherCharged` (dénominateur `M^2`).
-/
def marginalWeight (M rate delta deseng eps qPos chi : Nat) (otherCharged : Bool) (w2 : Nat)
    (src dst : Polarity) : Nat :=
  let e2 := effectiveEpsScaled M eps chi otherCharged
  match src, dst with
  | .zero, .zero => 2 * M * (M * M - e2)
  | .zero, .neg  => 2 * e2 * (M - qPos)
  | .zero, .pos  => 2 * e2 * qPos
  | .neg,  .zero => M * M * (2 * delta)
  | .neg,  .neg  => M * M * (2 * M - w2 * rate - 2 * delta)
  | .neg,  .pos  => M * M * (w2 * rate)
  | .pos,  .zero => (M * M - e2) * (w2 * deseng)
  | .pos,  .neg  => 2 * M * e2
  | .pos,  .pos  => (M * M - e2) * (2 * M - w2 * deseng)

/-- Poids de transition exact sur l'espace des 9 couplages `(A, C)` (somme de ligne `4 * M^6`). -/
def circuitWeight (p : CircuitKernelParams) (src dst : EngineCoupling) : Nat :=
  let mwA := marginalWeight p.scale p.rho p.deltaA p.gammaA p.epsilon p.qPosA p.chi
    (isCharged src.controle) (attentionalWeightX2 src) src.attente dst.attente
  let mwC := marginalWeight p.scale p.kappa p.deltaC p.gammaC p.epsilon p.qPosC p.chi
    (isCharged src.attente) (attentionalWeightY2 src) src.controle dst.controle
  mwA * mwC

/-- Somme sortante sur l'ensemble des 9 couplages cibles. -/
def circuitRowSum (p : CircuitKernelParams) (src : EngineCoupling) : Nat :=
  (allCouplings.map (circuitWeight p src)).foldl (· + ·) 0

private theorem attentionalWeightX2_le_two (c : EngineCoupling) :
    attentionalWeightX2 c ≤ 2 := by
  cases c with | mk a ctrl => cases a <;> cases ctrl <;> decide

private theorem attentionalWeightY2_le_two (c : EngineCoupling) :
    attentionalWeightY2 c ≤ 2 := by
  cases c with | mk a ctrl => cases a <;> cases ctrl <;> decide

private theorem attentionalWeightX2_pos (c : EngineCoupling) :
    attentionalWeightX2 c > 0 := by
  cases c with | mk a ctrl => cases a <;> cases ctrl <;> decide

private theorem attentionalWeightY2_pos (c : EngineCoupling) :
    attentionalWeightY2 c > 0 := by
  cases c with | mk a ctrl => cases a <;> cases ctrl <;> decide

private theorem marginalWeight_sum (M rate delta deseng eps qPos chi : Nat)
    (otherCharged : Bool) (w2 : Nat) (src : Polarity)
    (h_rd : rate + delta ≤ M) (h_des : deseng ≤ M)
    (h_eps : eps ≤ M) (h_q : qPos ≤ M) (h_chi : chi ≤ M) (h_w2 : w2 ≤ 2) :
    marginalWeight M rate delta deseng eps qPos chi otherCharged w2 src .zero +
    marginalWeight M rate delta deseng eps qPos chi otherCharged w2 src .neg +
    marginalWeight M rate delta deseng eps qPos chi otherCharged w2 src .pos = 2 * M * M * M := by
  have h_wrd : w2 * rate + 2 * delta ≤ 2 * M := by
    have hw : w2 * rate ≤ 2 * rate := Nat.mul_le_mul_right rate h_w2
    omega
  have h_wd : w2 * deseng ≤ 2 * M := Nat.mul_le_mul h_w2 h_des
  have h_e2 : effectiveEpsScaled M eps chi otherCharged ≤ M * M :=
    effectiveEpsScaled_le M eps chi otherCharged h_eps h_chi
  cases src with
  | neg =>
    dsimp [marginalWeight]
    have h_inner : 2 * delta + (2 * M - w2 * rate - 2 * delta) + w2 * rate = 2 * M := by omega
    rw [← Nat.mul_add, ← Nat.mul_add, h_inner]
    ac_rfl
  | zero =>
    dsimp [marginalWeight]
    let e2 := effectiveEpsScaled M eps chi otherCharged
    change 2 * M * (M * M - e2) + 2 * e2 * (M - qPos) + 2 * e2 * qPos = 2 * M * M * M
    have h1 : 2 * e2 * (M - qPos) + 2 * e2 * qPos = 2 * e2 * M := by
      rw [← Nat.mul_add, Nat.sub_add_cancel h_q]
    have h2 : 2 * e2 * M = 2 * M * e2 := by ac_rfl
    have h3 : 2 * M * (M * M - e2) + 2 * M * e2 = 2 * M * (M * M) := by
      rw [← Nat.mul_add, Nat.sub_add_cancel h_e2]
    have h4 : 2 * M * (M * M) = 2 * M * M * M := by ac_rfl
    omega
  | pos =>
    dsimp [marginalWeight]
    let e2 := effectiveEpsScaled M eps chi otherCharged
    change (M * M - e2) * (w2 * deseng) + 2 * M * e2 + (M * M - e2) * (2 * M - w2 * deseng) =
      2 * M * M * M
    have h1 : (M * M - e2) * (w2 * deseng) + (M * M - e2) * (2 * M - w2 * deseng) =
        (M * M - e2) * (2 * M) := by
      rw [← Nat.mul_add, Nat.add_sub_of_le h_wd]
    have h2 : (M * M - e2) * (2 * M) = 2 * M * (M * M - e2) := by ac_rfl
    have h3 : 2 * M * (M * M - e2) + 2 * M * e2 = 2 * M * (M * M) := by
      rw [← Nat.mul_add, Nat.sub_add_cancel h_e2]
    have h4 : 2 * M * (M * M) = 2 * M * M * M := by ac_rfl
    omega

private theorem sum_nine_outer (fA fC : Polarity → Nat) :
    ((((((((0 + fA .zero * fC .zero) + fA .pos * fC .zero) + fA .neg * fC .zero) +
      fA .zero * fC .pos) + fA .zero * fC .neg) + fA .pos * fC .pos) +
      fA .pos * fC .neg) + fA .neg * fC .pos) + fA .neg * fC .neg =
    (fA .zero + fA .neg + fA .pos) * (fC .zero + fC .neg + fC .pos) := by
  simp only [Nat.add_mul, Nat.mul_add]
  omega

/-- Conservation stochastique exacte : la somme des poids sortants vaut toujours `4 * scale ^ 6`. -/
theorem circuitRowSum_exact (p : CircuitKernelParams) (src : EngineCoupling) :
    circuitRowSum p src = 4 * p.scale ^ 6 := by
  unfold circuitRowSum allCouplings circuitWeight
  dsimp only [List.map, List.foldl]
  rw [sum_nine_outer
    (marginalWeight p.scale p.rho p.deltaA p.gammaA p.epsilon p.qPosA p.chi
      (isCharged src.controle) (attentionalWeightX2 src) src.attente)
    (marginalWeight p.scale p.kappa p.deltaC p.gammaC p.epsilon p.qPosC p.chi
      (isCharged src.attente) (attentionalWeightY2 src) src.controle)]
  rw [marginalWeight_sum p.scale p.rho p.deltaA p.gammaA p.epsilon p.qPosA p.chi
    (isCharged src.controle) (attentionalWeightX2 src) src.attente
    p.h_rho_da_le p.h_ga_le p.h_eps_le p.h_qa_le p.h_chi_le (attentionalWeightX2_le_two src)]
  rw [marginalWeight_sum p.scale p.kappa p.deltaC p.gammaC p.epsilon p.qPosC p.chi
    (isCharged src.attente) (attentionalWeightY2 src) src.controle
    p.h_kap_dc_le p.h_gc_le p.h_eps_le p.h_qc_le p.h_chi_le (attentionalWeightY2_le_two src)]
  have hp : p.scale ^ 6 = p.scale * p.scale * p.scale * p.scale * p.scale * p.scale := by
    simp [Nat.pow_succ]
  have h4 : (4 : Nat) = 2 * 2 := rfl
  rw [hp, h4]
  ac_rfl

/-- En régime libre (`epsilon = 0`), la Veille `(A0, C0)` est un état absorbant strict. -/
theorem veille_absorbing_free (p : CircuitKernelParams) (h_eps : p.epsilon = 0)
    (dst : EngineCoupling) :
    circuitWeight p ⟨.zero, .zero⟩ dst =
      if dst = ⟨.zero, .zero⟩ then 4 * p.scale ^ 6 else 0 := by
  have hp : p.scale ^ 6 = p.scale * p.scale * p.scale * p.scale * p.scale * p.scale := by
    simp [Nat.pow_succ]
  have h4 : (4 : Nat) = 2 * 2 := rfl
  cases dst with
  | mk da dc =>
    cases da <;> cases dc <;>
      dsimp [circuitWeight, marginalWeight, effectiveEpsScaled, isCharged] <;>
      simp only [h_eps, Nat.mul_zero, Nat.sub_zero, Nat.zero_mul]
    all_goals first
      | (rw [hp, h4]; ac_rfl)
      | (split <;> first | rfl | (exfalso; decide))

private theorem marginal_lyapunov_monotone (M rate delta deseng qPos : Nat)
    (otherCharged : Bool) (w2 : Nat) (src dst : Polarity)
    (hw : marginalWeight M rate delta deseng 0 qPos 0 otherCharged w2 src dst > 0) :
    polarityEnergy dst ≤ polarityEnergy src := by
  have he2 : effectiveEpsScaled M 0 0 otherCharged = 0 := by
    cases otherCharged <;> simp [effectiveEpsScaled]
  cases src <;> cases dst <;>
    dsimp [marginalWeight, polarityEnergy] at hw ⊢
  all_goals try rw [he2] at hw
  all_goals omega

/--
En régime libre sans couplage exogène (`epsilon = 0, chi = 0`), le potentiel de Lyapunov est
décroissant quels que soient les taux d'extinction passive `deltaA, deltaC`.
-/
theorem lyapunov_monotone_free (p : CircuitKernelParams)
    (h_eps : p.epsilon = 0) (h_chi : p.chi = 0)
    (src dst : EngineCoupling) (hw : circuitWeight p src dst > 0) :
    lyapunovPotential dst ≤ lyapunovPotential src := by
  unfold circuitWeight at hw
  rw [h_eps, h_chi] at hw
  have ha : 0 < marginalWeight p.scale p.rho p.deltaA p.gammaA 0 p.qPosA 0
      (isCharged src.controle) (attentionalWeightX2 src) src.attente dst.attente :=
    Nat.pos_of_mul_pos_right hw
  have hc : 0 < marginalWeight p.scale p.kappa p.deltaC p.gammaC 0 p.qPosC 0
      (isCharged src.attente) (attentionalWeightY2 src) src.controle dst.controle :=
    Nat.pos_of_mul_pos_left hw
  have h1 := marginal_lyapunov_monotone p.scale p.rho p.deltaA p.gammaA p.qPosA
    (isCharged src.controle) (attentionalWeightX2 src) src.attente dst.attente ha
  have h2 := marginal_lyapunov_monotone p.scale p.kappa p.deltaC p.gammaC p.qPosC
    (isCharged src.attente) (attentionalWeightY2 src) src.controle dst.controle hc
  unfold lyapunovPotential
  omega

private def stepDownPol : Polarity → Polarity
  | .zero => .zero
  | .neg  => .pos
  | .pos  => .zero

/-- Existence d'une transition strictement décroissante en énergie depuis tout état actif en régime libre flexible. -/
theorem lyapunov_strict_descent_witness (p : CircuitKernelParams)
    (h_eps : p.epsilon = 0) (h_chi : p.chi = 0)
    (h_rho : p.rho > 0) (h_kap : p.kappa > 0) (h_ga : p.gammaA > 0) (h_gc : p.gammaC > 0)
    (src : EngineCoupling) (h_act : src.isGlobalNeutrality = false) :
    ∃ dst : EngineCoupling,
      circuitWeight p src dst > 0 ∧ lyapunovPotential dst < lyapunovPotential src := by
  let dst : EngineCoupling := ⟨stepDownPol src.attente, stepDownPol src.controle⟩
  refine ⟨dst, ?_, ?_⟩
  · have hM := p.h_scale_pos
    have hMM : p.scale * p.scale > 0 := Nat.mul_pos hM hM
    have hwx := attentionalWeightX2_pos src
    have hwy := attentionalWeightY2_pos src
    have he2 : ∀ b, effectiveEpsScaled p.scale 0 0 b = 0 := by
      intro b; cases b <;> simp [effectiveEpsScaled]
    cases src with
    | mk sa sc =>
      have hmwA : marginalWeight p.scale p.rho p.deltaA p.gammaA 0 p.qPosA 0
          (isCharged sc) (attentionalWeightX2 ⟨sa, sc⟩) sa (stepDownPol sa) > 0 := by
        cases sa with
        | neg =>
          dsimp [marginalWeight, stepDownPol]
          exact Nat.mul_pos hMM (Nat.mul_pos hwx h_rho)
        | zero =>
          dsimp [marginalWeight, stepDownPol]
          rw [he2 (isCharged sc), Nat.sub_zero]
          exact Nat.mul_pos (Nat.mul_pos (by decide) hM) hMM
        | pos =>
          dsimp [marginalWeight, stepDownPol]
          rw [he2 (isCharged sc), Nat.sub_zero]
          exact Nat.mul_pos hMM (Nat.mul_pos hwx h_ga)
      have hmwC : marginalWeight p.scale p.kappa p.deltaC p.gammaC 0 p.qPosC 0
          (isCharged sa) (attentionalWeightY2 ⟨sa, sc⟩) sc (stepDownPol sc) > 0 := by
        cases sc with
        | neg =>
          dsimp [marginalWeight, stepDownPol]
          exact Nat.mul_pos hMM (Nat.mul_pos hwy h_kap)
        | zero =>
          dsimp [marginalWeight, stepDownPol]
          rw [he2 (isCharged sa), Nat.sub_zero]
          exact Nat.mul_pos (Nat.mul_pos (by decide) hM) hMM
        | pos =>
          dsimp [marginalWeight, stepDownPol]
          rw [he2 (isCharged sa), Nat.sub_zero]
          exact Nat.mul_pos hMM (Nat.mul_pos hwy h_gc)
      unfold circuitWeight
      rw [h_eps, h_chi]
      exact Nat.mul_pos hmwA hmwC
  · cases src with
    | mk sa sc =>
      cases sa <;> cases sc <;> first | contradiction | decide

private theorem drift_mixed_identity (M r : Nat) (h : r ≤ M) :
    (M * M * r) * (M * M * (2 * M - r)) +
    (M * M * (2 * M - r)) * (M * M * r) +
    (M * M * r) * (M * M * r) * 2 =
      4 * M ^ 5 * r := by
  have hle : r ≤ 2 * M := by omega
  have hba : M * M * (2 * M - r) + M * M * r = 2 * M * M * M := by
    rw [← Nat.mul_add, Nat.sub_add_cancel hle]
    ac_rfl
  have h_lhs :
      (M * M * r) * (M * M * (2 * M - r)) +
      (M * M * (2 * M - r)) * (M * M * r) +
      (M * M * r) * (M * M * r) * 2 =
      2 * ((M * M * r) * (M * M * (2 * M - r) + M * M * r)) := by
    have hba_eq :
        (M * M * (2 * M - r)) * (M * M * r) = (M * M * r) * (M * M * (2 * M - r)) :=
      Nat.mul_comm _ _
    have h_aa :
        (M * M * r) * (M * M * r) * 2 = 2 * ((M * M * r) * (M * M * r)) :=
      Nat.mul_comm _ 2
    rw [hba_eq, h_aa, Nat.mul_add]
    omega
  rw [h_lhs, hba]
  have hp : M ^ 5 = M * M * M * M * M := by simp [Nat.pow_succ]
  have h4 : (4 : Nat) = 2 * 2 := rfl
  rw [hp, h4]
  ac_rfl

private theorem effectiveEpsScaled_zero (M : Nat) (b : Bool) :
    effectiveEpsScaled M 0 0 b = 0 := by
  unfold effectiveEpsScaled
  split <;> simp

private theorem natCast_add_eq (a b : Nat) : (a : Int) + (b : Int) = ((a + b : Nat) : Int) := rfl

private theorem natCast_mul_eq (a b : Nat) : (a : Int) * (b : Int) = ((a * b : Nat) : Int) := rfl

private theorem natCast_pow5_eq (M : Nat) : ((M ^ 5 : Nat) : Int) = (M : Int) ^ 5 := by
  have hpN : M ^ 5 = M * M * M * M * M := by simp [Nat.pow_succ]
  have hpI : (M : Int) ^ 5 = (M : Int) * (M : Int) * (M : Int) * (M : Int) * (M : Int) := by
    simp [Int.pow_succ]
  rw [hpN, hpI]
  rfl

private theorem nat_to_int_drift_term (w vSrc vDst : Nat) (h : w > 0 → vDst ≤ vSrc) :
    (w : Int) * ((vSrc : Int) - (vDst : Int)) = ↑(w * (vSrc - vDst)) := by
  cases w with
  | zero => simp
  | succ k =>
    have hle : vDst ≤ vSrc := h (Nat.zero_lt_succ k)
    have hsub : (vSrc : Int) - (vDst : Int) = ((vSrc - vDst : Nat) : Int) := by omega
    rw [hsub, natCast_mul_eq]

private theorem foldl_int_eq_of_nat {α : Type} (l : List α) (fI : α → Int) (fN : α → Nat)
    (acc : Nat) (h : ∀ x ∈ l, fI x = ↑(fN x)) :
    (l.map fI).foldl (· + ·) (acc : Int) = ↑((l.map fN).foldl (· + ·) acc) := by
  induction l generalizing acc with
  | nil => rfl
  | cons x xs ih =>
    simp only [List.map_cons, List.foldl_cons]
    rw [h x (List.Mem.head xs), natCast_add_eq]
    exact ih (acc + fN x) (fun y hy => h y (List.Mem.tail x hy))

private theorem lyapunov_expected_drift_constant_nat (p : CircuitKernelParams) (r : Nat)
    (h_eps : p.epsilon = 0) (h_chi : p.chi = 0)
    (h_da : p.deltaA = 0) (h_dc : p.deltaC = 0)
    (h_rho : p.rho = r) (h_kap : p.kappa = r) (h_ga : p.gammaA = r) (h_gc : p.gammaC = r)
    (src : EngineCoupling) (h_act : src.isGlobalNeutrality = false) :
    (allCouplings.map (fun dst =>
      circuitWeight p src dst * (lyapunovPotential src - lyapunovPotential dst))).foldl (· + ·) 0 =
      4 * p.scale ^ 5 * r := by
  have hr_le : r ≤ p.scale := by rw [← h_rho]; exact p.h_rho_le
  have hmix := drift_mixed_identity p.scale r hr_le
  have hp5 : p.scale ^ 5 = p.scale * p.scale * p.scale * p.scale * p.scale := by simp [Nat.pow_succ]
  have h4 : (4 : Nat) = 2 * 2 := rfl
  have he2 : ∀ b, effectiveEpsScaled p.scale p.epsilon p.chi b = 0 := by
    intro b; rw [h_eps, h_chi]; exact effectiveEpsScaled_zero p.scale b
  cases src with
  | mk sa sc =>
    cases sa <;> cases sc
    all_goals first
      | contradiction
      | (dsimp [allCouplings, List.map, List.foldl, circuitWeight, marginalWeight,
          attentionalWeightX2, attentionalWeightY2, phiL1, lyapunovPotential,
          polarityEnergy, isCharged]
         simp only [he2, h_da, h_dc, h_rho, h_kap, h_ga, h_gc,
           Nat.sub_zero, Nat.mul_zero, Nat.zero_mul, Nat.add_zero, Nat.zero_add,
           Nat.mul_one, Nat.one_mul]
         first
           | (rw [hp5, h4]; ac_rfl)
           | (rw [← hmix]; omega))

/--
Loi exacte de conservation de la dérive de Lyapunov sur `ℤ` (sans soustraction tronquée `Nat`,
résolution active pure `deltaA = deltaC = 0`) :
sous paramètres symétriques `r` en régime libre (`epsilon = 0, chi = 0`), la perte moyenne signée
d'énergie par cycle vaut exactement `4 * scale ^ 5 * r` (sur le dénominateur `4 * scale ^ 6`),
que l'état actif soit axial ou mixte (conséquence du goulot `L1`).
-/
theorem lyapunov_expected_drift_constant (p : CircuitKernelParams) (r : Nat)
    (h_eps : p.epsilon = 0) (h_chi : p.chi = 0)
    (h_da : p.deltaA = 0) (h_dc : p.deltaC = 0)
    (h_rho : p.rho = r) (h_kap : p.kappa = r) (h_ga : p.gammaA = r) (h_gc : p.gammaC = r)
    (src : EngineCoupling) (h_act : src.isGlobalNeutrality = false) :
    (allCouplings.map (fun dst =>
      (circuitWeight p src dst : Int) *
        ((lyapunovPotential src : Int) - (lyapunovPotential dst : Int)))).foldl (· + ·) (0 : Int) =
      (4 * p.scale ^ 5 * r : Int) := by
  have h0 : (0 : Int) = ((0 : Nat) : Int) := rfl
  rw [h0, foldl_int_eq_of_nat allCouplings _ _ 0 (fun dst _ =>
    nat_to_int_drift_term _ _ _ (lyapunov_monotone_free p h_eps h_chi src dst))]
  have heq := lyapunov_expected_drift_constant_nat p r h_eps h_chi h_da h_dc h_rho h_kap h_ga h_gc src h_act
  rw [heq]
  have h4 : (4 : Int) = ((4 : Nat) : Int) := rfl
  rw [h4, ← natCast_pow5_eq p.scale, natCast_mul_eq, natCast_mul_eq]

private theorem lyapunov_drift_charge_with_passive_extinction_nat (p : CircuitKernelParams)
    (h_eps : p.epsilon = 0) (h_chi : p.chi = 0) :
    (allCouplings.map (fun dst =>
      circuitWeight p ⟨.neg, .zero⟩ dst *
        (lyapunovPotential ⟨.neg, .zero⟩ - lyapunovPotential dst))).foldl (· + ·) 0 =
      4 * p.scale ^ 5 * (p.rho + 2 * p.deltaA) := by
  have hp5 : p.scale ^ 5 = p.scale * p.scale * p.scale * p.scale * p.scale := by simp [Nat.pow_succ]
  have h4 : (4 : Nat) = 2 * 2 := rfl
  have he2 : ∀ b, effectiveEpsScaled p.scale p.epsilon p.chi b = 0 := by
    intro b; rw [h_eps, h_chi]; exact effectiveEpsScaled_zero p.scale b
  dsimp [allCouplings, List.map, List.foldl, circuitWeight, marginalWeight,
    attentionalWeightX2, attentionalWeightY2, phiL1,
    lyapunovPotential, polarityEnergy, isCharged]
  simp only [he2, Nat.mul_zero, Nat.add_zero, Nat.zero_add, Nat.sub_zero, Nat.zero_mul, Nat.mul_one]
  rw [hp5, h4, Nat.mul_add]
  have h_a :
      p.scale * p.scale * (2 * p.deltaA) * (2 * p.scale * (p.scale * p.scale)) * 2 =
      2 * 2 * (p.scale * p.scale * p.scale * p.scale * p.scale) * (2 * p.deltaA) := by ac_rfl
  have h_b :
      p.scale * p.scale * (2 * p.rho) * (2 * p.scale * (p.scale * p.scale)) =
      2 * 2 * (p.scale * p.scale * p.scale * p.scale * p.scale) * p.rho := by ac_rfl
  rw [h_a, h_b]
  omega

/--
Axe (i) — Effet de l'extinction passive `deltaA` sur la perte signée d'énergie sur `ℤ` :
en régime libre (`epsilon = 0, chi = 0`) depuis la Charge épistémique pure `(A-, C0)`, la dérive
signée vaut exactement `4 * scale ^ 5 * (rho + 2 * deltaA)`, car `Charge -> Neutre` fait chuter `V`
de 2 unités d'un coup (pseudo-veille sans consolidation par Décharge).
-/
theorem lyapunov_drift_charge_with_passive_extinction (p : CircuitKernelParams)
    (h_eps : p.epsilon = 0) (h_chi : p.chi = 0) :
    (allCouplings.map (fun dst =>
      (circuitWeight p ⟨.neg, .zero⟩ dst : Int) *
        ((lyapunovPotential ⟨.neg, .zero⟩ : Int) - (lyapunovPotential dst : Int)))).foldl (· + ·) (0 : Int) =
      (4 * p.scale ^ 5 * (p.rho + 2 * p.deltaA) : Int) := by
  have h0 : (0 : Int) = ((0 : Nat) : Int) := rfl
  rw [h0, foldl_int_eq_of_nat allCouplings _ _ 0 (fun dst _ =>
    nat_to_int_drift_term _ _ _ (lyapunov_monotone_free p h_eps h_chi ⟨.neg, .zero⟩ dst))]
  have heq := lyapunov_drift_charge_with_passive_extinction_nat p h_eps h_chi
  rw [heq]
  have h4 : (4 : Int) = ((4 : Nat) : Int) := rfl
  have h2 : (2 : Int) = ((2 : Nat) : Int) := rfl
  rw [h4, h2, ← natCast_pow5_eq p.scale, natCast_mul_eq, natCast_mul_eq, natCast_add_eq, natCast_mul_eq]

/--
Axe (ii) — Indépendance logique P1 sans P2 : lorsque `chi = 0`, la surprise effective d'une boucle
vaut uniformément `M * eps`, strictement indépendante de l'état de Charge de l'autre boucle.
-/
theorem p1_without_p2_eps_independent (M eps : Nat) (otherCharged : Bool) :
    effectiveEpsScaled M eps 0 otherCharged = M * eps := by
  unfold effectiveEpsScaled
  cases otherCharged <;> simp

/--
Bifurcation axiale → diagonale en Charge négative (Prédiction P2, Option 3b) :
1. Depuis la `Peur (-2, 0)` (`(A-, C0)`), `chi > 0` induit la bascule vers `Colère (-1, +1)` et `Dégoût (-1, -1)` ;
2. Depuis la `Tristesse (0, -2)` (`(A0, C-)`), `chi > 0` induit la bascule vers `Calme (+1, -1)` et `Dégoût (-1, -1)` ;
3. À bruit exogène nul (`epsilon = 0`), les 2 pôles en Décharge positive (`Courage (A+, C0)` et `Joie (A0, C+)`)
   ne subissent aucune contagion croisée vers les diagonales (`circuitWeight = 0`) quel que soit `chi`.
-/
theorem axial_peur_bifurcates_p2 (p : CircuitKernelParams)
    (h_chi : p.chi > 0) (h_q_pos : p.qPosC > 0) (h_q_lt : p.qPosC < p.scale)
    (h_stay : p.rho + p.deltaA < p.scale) :
    circuitWeight p ⟨.neg, .zero⟩ ⟨.neg, .pos⟩ > 0 ∧
    circuitWeight p ⟨.neg, .zero⟩ ⟨.neg, .neg⟩ > 0 := by
  have hM := p.h_scale_pos
  have hMM : p.scale * p.scale > 0 := Nat.mul_pos hM hM
  have h_e2 : effectiveEpsScaled p.scale p.epsilon p.chi true > 0 := by
    unfold effectiveEpsScaled
    dsimp
    by_cases he : p.epsilon = p.scale
    · rw [he]
      have hpos : p.scale * p.scale > 0 := hMM
      omega
    · have hme : p.scale - p.epsilon > 0 := by have := p.h_eps_le; omega
      have hcp : p.chi * (p.scale - p.epsilon) > 0 := Nat.mul_pos h_chi hme
      omega
  have h_sub : 2 * p.scale - 2 * p.rho - 2 * p.deltaA > 0 := by omega
  have h_qsub : p.scale - p.qPosC > 0 := by omega
  unfold circuitWeight marginalWeight attentionalWeightX2 attentionalWeightY2
  dsimp [phiL1, isCharged]
  refine ⟨?_, ?_⟩
  · exact Nat.mul_pos (Nat.mul_pos hMM h_sub) (Nat.mul_pos (Nat.mul_pos (by decide) h_e2) h_q_pos)
  · exact Nat.mul_pos (Nat.mul_pos hMM h_sub) (Nat.mul_pos (Nat.mul_pos (by decide) h_e2) h_qsub)

/--
Second volet de P2 (Option 3b) et brisure de symétrie Charge / Décharge sur le noyau 9×9 :
la `Tristesse (A0, C-)` bifurque vers `Calme (A+, C-)` et `Dégoût (A-, C-)` sous `chi > 0`,
tandis qu'à `epsilon = 0`, `Courage (A+, C0)` et `Joie (A0, C+)` ont un poids nul vers leurs
diagonales adjacentes quel que soit `chi`.
-/
theorem axial_tristesse_and_discharge_asymmetry_p2 (p : CircuitKernelParams)
    (h_chi : p.chi > 0) (h_qa_pos : p.qPosA > 0) (h_qa_lt : p.qPosA < p.scale)
    (h_stay_c : p.kappa + p.deltaC < p.scale) :
    (circuitWeight p ⟨.zero, .neg⟩ ⟨.pos, .neg⟩ > 0 ∧
     circuitWeight p ⟨.zero, .neg⟩ ⟨.neg, .neg⟩ > 0) ∧
    (p.epsilon = 0 →
      circuitWeight p ⟨.pos, .zero⟩ ⟨.pos, .pos⟩ = 0 ∧
      circuitWeight p ⟨.pos, .zero⟩ ⟨.pos, .neg⟩ = 0 ∧
      circuitWeight p ⟨.zero, .pos⟩ ⟨.pos, .pos⟩ = 0 ∧
      circuitWeight p ⟨.zero, .pos⟩ ⟨.neg, .pos⟩ = 0) := by
  have hM := p.h_scale_pos
  have hMM : p.scale * p.scale > 0 := Nat.mul_pos hM hM
  have h_e2 : effectiveEpsScaled p.scale p.epsilon p.chi true > 0 := by
    unfold effectiveEpsScaled
    dsimp
    by_cases he : p.epsilon = p.scale
    · rw [he]; omega
    · have hme : p.scale - p.epsilon > 0 := by have := p.h_eps_le; omega
      have hcp : p.chi * (p.scale - p.epsilon) > 0 := Nat.mul_pos h_chi hme
      omega
  have h_sub : 2 * p.scale - 2 * p.kappa - 2 * p.deltaC > 0 := by omega
  have h_qsub : p.scale - p.qPosA > 0 := by omega
  refine ⟨⟨?_, ?_⟩, ?_⟩
  · unfold circuitWeight marginalWeight attentionalWeightX2 attentionalWeightY2
    dsimp [phiL1, isCharged]
    exact Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (by decide) h_e2) h_qa_pos) (Nat.mul_pos hMM h_sub)
  · unfold circuitWeight marginalWeight attentionalWeightX2 attentionalWeightY2
    dsimp [phiL1, isCharged]
    exact Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (by decide) h_e2) h_qsub) (Nat.mul_pos hMM h_sub)
  · intro h_eps0
    unfold circuitWeight marginalWeight effectiveEpsScaled
    dsimp [isCharged]
    simp [h_eps0]

/-- Apériodicité du régime ergodique : tant que `epsilon < scale`, la Veille possède une boucle de séjour > 0. -/
theorem veille_self_loop_ergodic (p : CircuitKernelParams) (h_lt : p.epsilon < p.scale) :
    circuitWeight p ⟨.zero, .zero⟩ ⟨.zero, .zero⟩ > 0 := by
  have hM := p.h_scale_pos
  have h_sub : p.scale * p.scale - effectiveEpsScaled p.scale p.epsilon p.chi false > 0 := by
    dsimp [effectiveEpsScaled]
    have h1 : p.scale * p.epsilon < p.scale * p.scale := Nat.mul_lt_mul_of_pos_left h_lt hM
    omega
  unfold circuitWeight marginalWeight
  dsimp [isCharged]
  exact Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (by decide) hM) h_sub)
    (Nat.mul_pos (Nat.mul_pos (by decide) hM) h_sub)

/-- Accessibilité en 1 pas depuis la Veille vers les 9 configurations dès que `0 < epsilon < scale` et `0 < qPos < scale`. -/
theorem veille_reaches_all_one_step (p : CircuitKernelParams)
    (h_eps_pos : p.epsilon > 0) (h_eps_lt : p.epsilon < p.scale)
    (h_qa_pos : p.qPosA > 0) (h_qa_lt : p.qPosA < p.scale)
    (h_qc_pos : p.qPosC > 0) (h_qc_lt : p.qPosC < p.scale)
    (dst : EngineCoupling) :
    circuitWeight p ⟨.zero, .zero⟩ dst > 0 := by
  have hM := p.h_scale_pos
  have h_e2_pos : effectiveEpsScaled p.scale p.epsilon p.chi false > 0 := by
    dsimp [effectiveEpsScaled]; exact Nat.mul_pos hM h_eps_pos
  have h_e2_sub : p.scale * p.scale - effectiveEpsScaled p.scale p.epsilon p.chi false > 0 := by
    dsimp [effectiveEpsScaled]
    have h1 : p.scale * p.epsilon < p.scale * p.scale := Nat.mul_lt_mul_of_pos_left h_eps_lt hM
    omega
  have h_qa_sub : p.scale - p.qPosA > 0 := by omega
  have h_qc_sub : p.scale - p.qPosC > 0 := by omega
  unfold circuitWeight
  have hA : marginalWeight p.scale p.rho p.deltaA p.gammaA p.epsilon p.qPosA p.chi false 2 .zero dst.attente > 0 := by
    cases dst.attente with
    | neg  => dsimp [marginalWeight]; exact Nat.mul_pos (Nat.mul_pos (by decide) h_e2_pos) h_qa_sub
    | zero => dsimp [marginalWeight]; exact Nat.mul_pos (Nat.mul_pos (by decide) hM) h_e2_sub
    | pos  => dsimp [marginalWeight]; exact Nat.mul_pos (Nat.mul_pos (by decide) h_e2_pos) h_qa_pos
  have hC : marginalWeight p.scale p.kappa p.deltaC p.gammaC p.epsilon p.qPosC p.chi false 2 .zero dst.controle > 0 := by
    cases dst.controle with
    | neg  => dsimp [marginalWeight]; exact Nat.mul_pos (Nat.mul_pos (by decide) h_e2_pos) h_qc_sub
    | zero => dsimp [marginalWeight]; exact Nat.mul_pos (Nat.mul_pos (by decide) hM) h_e2_sub
    | pos  => dsimp [marginalWeight]; exact Nat.mul_pos (Nat.mul_pos (by decide) h_e2_pos) h_qc_pos
  dsimp [isCharged]
  exact Nat.mul_pos hA hC

/--
Retour en au plus 2 pas vers la Veille depuis tout état sous résolution active (`rho, kappa, gammaA, gammaC > 0`)
et non-saturation (`epsilon < scale` et `chi < scale`, garantissant `M^2 - e2 > 0`).
-/
theorem all_reach_veille_two_steps (p : CircuitKernelParams)
    (h_eps_lt : p.epsilon < p.scale) (h_chi_lt : p.chi < p.scale)
    (h_rho : p.rho > 0) (h_kap : p.kappa > 0) (h_ga : p.gammaA > 0) (h_gc : p.gammaC > 0)
    (src : EngineCoupling) :
    ∃ mid : EngineCoupling,
      circuitWeight p src mid > 0 ∧ circuitWeight p mid ⟨.zero, .zero⟩ > 0 := by
  let stepPol : Polarity → Polarity
    | .neg => .pos
    | _    => .zero
  let mid : EngineCoupling := ⟨stepPol src.attente, stepPol src.controle⟩
  have hM := p.h_scale_pos
  have hMM : p.scale * p.scale > 0 := Nat.mul_pos hM hM
  have h_eff_sub_of : ∀ b : Bool, p.scale * p.scale - effectiveEpsScaled p.scale p.epsilon p.chi b > 0 :=
    fun b => effectiveEpsScaled_sub_pos p.scale p.epsilon p.chi b h_eps_lt h_chi_lt
  refine ⟨mid, ?_, ?_⟩
  · have hwx := attentionalWeightX2_pos src
    have hwy := attentionalWeightY2_pos src
    have hA : marginalWeight p.scale p.rho p.deltaA p.gammaA p.epsilon p.qPosA p.chi
        (isCharged src.controle) (attentionalWeightX2 src) src.attente (stepPol src.attente) > 0 := by
      cases ha : src.attente with
      | neg =>
        dsimp [marginalWeight, stepPol]
        exact Nat.mul_pos hMM (Nat.mul_pos hwx h_rho)
      | zero =>
        dsimp [marginalWeight, stepPol]
        exact Nat.mul_pos (Nat.mul_pos (by decide) hM) (h_eff_sub_of (isCharged src.controle))
      | pos =>
        dsimp [marginalWeight, stepPol]
        exact Nat.mul_pos (h_eff_sub_of (isCharged src.controle)) (Nat.mul_pos hwx h_ga)
    have hC : marginalWeight p.scale p.kappa p.deltaC p.gammaC p.epsilon p.qPosC p.chi
        (isCharged src.attente) (attentionalWeightY2 src) src.controle (stepPol src.controle) > 0 := by
      cases hc : src.controle with
      | neg =>
        dsimp [marginalWeight, stepPol]
        exact Nat.mul_pos hMM (Nat.mul_pos hwy h_kap)
      | zero =>
        dsimp [marginalWeight, stepPol]
        exact Nat.mul_pos (Nat.mul_pos (by decide) hM) (h_eff_sub_of (isCharged src.attente))
      | pos =>
        dsimp [marginalWeight, stepPol]
        exact Nat.mul_pos (h_eff_sub_of (isCharged src.attente)) (Nat.mul_pos hwy h_gc)
    exact Nat.mul_pos hA hC
  · have hA2 : marginalWeight p.scale p.rho p.deltaA p.gammaA p.epsilon p.qPosA p.chi
        (isCharged mid.controle) (attentionalWeightX2 mid) mid.attente .zero > 0 := by
      cases ha : src.attente with
      | neg =>
        dsimp [mid, stepPol]; rw [ha]; dsimp [marginalWeight]
        exact Nat.mul_pos (h_eff_sub_of (isCharged (stepPol src.controle)))
          (Nat.mul_pos (attentionalWeightX2_pos _) h_ga)
      | zero =>
        dsimp [mid, stepPol]; rw [ha]; dsimp [marginalWeight]
        exact Nat.mul_pos (Nat.mul_pos (by decide) hM) (h_eff_sub_of (isCharged (stepPol src.controle)))
      | pos =>
        dsimp [mid, stepPol]; rw [ha]; dsimp [marginalWeight]
        exact Nat.mul_pos (Nat.mul_pos (by decide) hM) (h_eff_sub_of (isCharged (stepPol src.controle)))
    have hC2 : marginalWeight p.scale p.kappa p.deltaC p.gammaC p.epsilon p.qPosC p.chi
        (isCharged mid.attente) (attentionalWeightY2 mid) mid.controle .zero > 0 := by
      cases hc : src.controle with
      | neg =>
        dsimp [mid, stepPol]; rw [hc]; dsimp [marginalWeight]
        exact Nat.mul_pos (h_eff_sub_of (isCharged (stepPol src.attente)))
          (Nat.mul_pos (attentionalWeightY2_pos _) h_gc)
      | zero =>
        dsimp [mid, stepPol]; rw [hc]; dsimp [marginalWeight]
        exact Nat.mul_pos (Nat.mul_pos (by decide) hM) (h_eff_sub_of (isCharged (stepPol src.attente)))
      | pos =>
        dsimp [mid, stepPol]; rw [hc]; dsimp [marginalWeight]
        exact Nat.mul_pos (Nat.mul_pos (by decide) hM) (h_eff_sub_of (isCharged (stepPol src.attente)))
    exact Nat.mul_pos hA2 hC2

/--
Contre-exemple formalisé au régime stationnaire global pour `epsilon = scale` et `deltaA = 0` :
lorsque la volatilité atteint `100 %` sans extinction passive, aucun état ne peut rejoindre la Veille `(A0, C0)`.
-/
theorem veille_unreachable_when_eps_max (p : CircuitKernelParams)
    (h_eps : p.epsilon = p.scale) (h_da : p.deltaA = 0) (src : EngineCoupling) :
    circuitWeight p src ⟨.zero, .zero⟩ = 0 := by
  have he2_eq : ∀ b : Bool, effectiveEpsScaled p.scale p.epsilon p.chi b = p.scale * p.scale := by
    intro b
    unfold effectiveEpsScaled
    rw [h_eps, Nat.sub_self, Nat.mul_zero, Nat.add_zero]
    cases b <;> rfl
  have hA0 : marginalWeight p.scale p.rho p.deltaA p.gammaA p.epsilon p.qPosA p.chi
      (isCharged src.controle) (attentionalWeightX2 src) src.attente .zero = 0 := by
    cases ha : src.attente with
    | neg =>
      dsimp [marginalWeight]; rw [h_da]; simp
    | zero =>
      dsimp [marginalWeight]; rw [he2_eq _, Nat.sub_self, Nat.mul_zero]
    | pos =>
      dsimp [marginalWeight]; rw [he2_eq _, Nat.sub_self, Nat.zero_mul]
  unfold circuitWeight
  rw [hA0, Nat.zero_mul]

/--
Axe (iii) — Rupture topologique par rigidité épistémique (`rho = 0, deltaA = 0`) :
tout état portant une Charge épistémique (`a = -1`) reste piégé dans la classe fermée `{a = -1}`
(singleton `s4` si `epsilon = chi = 0`, ou classe à 3 états `{s4, s5, s6}` sous P2 / perturbation).
-/
theorem epistemic_rigidity_traps_charge_slice (p : CircuitKernelParams)
    (h_rho : p.rho = 0) (h_da : p.deltaA = 0)
    (src dst : EngineCoupling) (h_src : src.attente = .neg) (h_dst : dst.attente ≠ .neg) :
    circuitWeight p src dst = 0 := by
  have hA : marginalWeight p.scale p.rho p.deltaA p.gammaA p.epsilon p.qPosA p.chi
      (isCharged src.controle) (attentionalWeightX2 src) src.attente dst.attente = 0 := by
    cases hda : dst.attente with
    | neg  => contradiction
    | zero => dsimp [marginalWeight]; rw [h_src, h_da]; simp
    | pos  => dsimp [marginalWeight]; rw [h_src, h_rho]; simp
  unfold circuitWeight
  rw [hA, Nat.zero_mul]

/--
Axe (iii) — Rupture topologique par impuissance pragmatique (`kappa = 0, deltaC = 0`) :
tout état portant une Charge motrice (`c = -1`) reste piégé dans la classe fermée `{c = -1}`.
-/
theorem pragmatic_helplessness_traps_charge_slice (p : CircuitKernelParams)
    (h_kap : p.kappa = 0) (h_dc : p.deltaC = 0)
    (src dst : EngineCoupling) (h_src : src.controle = .neg) (h_dst : dst.controle ≠ .neg) :
    circuitWeight p src dst = 0 := by
  have hC : marginalWeight p.scale p.kappa p.deltaC p.gammaC p.epsilon p.qPosC p.chi
      (isCharged src.attente) (attentionalWeightY2 src) src.controle dst.controle = 0 := by
    cases hdc : dst.controle with
    | neg  => contradiction
    | zero => dsimp [marginalWeight]; rw [h_src, h_dc]; simp
    | pos  => dsimp [marginalWeight]; rw [h_src, h_kap]; simp
  unfold circuitWeight
  rw [hC, Nat.mul_zero]

/--
Axe (iii) — Rupture topologique par persévération / hyper-verrouillage (`epsilon = 0, gammaA = gammaC = 0`) :
les configurations non chargées (`Veille`, `Courage (A+, C0)`, `Joie (A0, C+)`, `Désir (A+, C+)`)
deviennent chacune un état absorbant strict de poids `4 * scale ^ 6`.
-/
theorem perseveration_traps_discharge_free (p : CircuitKernelParams)
    (h_eps : p.epsilon = 0) (h_ga : p.gammaA = 0) (h_gc : p.gammaC = 0)
    (src dst : EngineCoupling) (h_sa : src.attente ≠ .neg) (h_sc : src.controle ≠ .neg) :
    circuitWeight p src dst =
      if dst = src then 4 * p.scale ^ 6 else 0 := by
  have hp6 : p.scale ^ 6 = p.scale * p.scale * p.scale * p.scale * p.scale * p.scale := by
    simp [Nat.pow_succ]
  have h4 : (4 : Nat) = 2 * 2 := rfl
  cases src with
  | mk sa sc =>
    cases dst with
    | mk da dc =>
      cases sa <;> cases sc
      all_goals first | contradiction | (
        cases da <;> cases dc <;>
          dsimp [circuitWeight, marginalWeight, effectiveEpsScaled, isCharged] <;>
          simp only [h_eps, h_ga, h_gc, Nat.mul_zero, Nat.sub_zero, Nat.zero_mul] <;>
          try split
        all_goals first
          | rfl
          | (rw [hp6, h4]; ac_rfl)
          | (exfalso; decide)
      )

/-!
## 6. Circuit continu fermé à 6 opérateurs avec états cachés (`CircularCircuitState`, `circularCycle`)
-/

/-- `[États cachés]` de l'Interface Subjective (modèle génératif interne). -/
structure HiddenSubjectiveState where
  modelDiscrepancy     : Nat
  revisable            : Bool
  descendingSuspension : Bool
  deriving DecidableEq, Repr, Inhabited

/-- `[États cachés]` de l'Interface Perceptive (boucle sensorimotrice). -/
structure HiddenPerceptiveState where
  afferentDiscrepancy : Nat
  controllable        : Bool
  deriving DecidableEq, Repr, Inhabited

/-- Milieu externe `Corps et Environnement` injectant des signaux afférents. -/
structure BodyEnvironmentState where
  perturbation : Nat
  deriving DecidableEq, Repr, Inhabited

/-- État complet du circuit continu fermé (Figure 1). -/
structure CircularCircuitState where
  subjectiveHidden    : HiddenSubjectiveState
  perceptiveHidden    : HiddenPerceptiveState
  bodyEnv             : BodyEnvironmentState
  sensoryThreshold    : Nat
  resorptionThreshold : Nat
  h_hysteresis        : resorptionThreshold ≤ sensoryThreshold
  attentional         : AttentionalInterface
  deriving Repr

/-- État basal canonique : Veille homéostatique `(0, 0, 0)` sans perturbation. -/
instance : Inhabited CircularCircuitState where
  default := {
    subjectiveHidden    := { modelDiscrepancy := 0, revisable := true, descendingSuspension := false }
    perceptiveHidden    := { afferentDiscrepancy := 0, controllable := true }
    bodyEnv             := { perturbation := 0 }
    sensoryThreshold    := 1
    resorptionThreshold := 1
    h_hysteresis        := Nat.le_refl 1
    attentional         := default
  }

/-- Opération 1 : Sortie interne de l'Interface Subjective (`+X / -X / 0`, via Anticipation). -/
def op1_subjectiveOut (s : CircularCircuitState) : Polarity :=
  if s.subjectiveHidden.modelDiscrepancy < s.resorptionThreshold then
    .zero
  else if s.subjectiveHidden.revisable then
    .pos
  else
    .neg

/-- Opération 2 : Sortie interne de l'Interface Perceptive (`+Y / -Y / 0`, via Surprise). -/
def op2_perceptiveOut (s : CircularCircuitState) : Polarity :=
  if s.perceptiveHidden.afferentDiscrepancy < s.resorptionThreshold then
    .zero
  else if s.perceptiveHidden.controllable then
    .pos
  else
    .neg

/-- Opération 3 : Croisement Attentionnel I — plan `(X, Y, 0)` et projection perceptible `(X, Y, Z)` certifiée. -/
def op3_crossingI_perceptible (s : CircularCircuitState) : ProtoSpatialNode × CoreAffectState :=
  let c : EngineCoupling := ⟨op1_subjectiveOut s, op2_perceptiveOut s⟩
  let proto := phiL1 c
  let z :=
    if c.isGlobalNeutrality then
      if s.subjectiveHidden.descendingSuspension then s.attentional.persistenceDepth + 2 else 0
    else if !s.attentional.isEngaged then
      if s.subjectiveHidden.descendingSuspension then s.attentional.persistenceDepth + 2 else 1
    else
      s.attentional.persistenceDepth + 2
  (proto, projectPerceptibleState c z s.attentional.precisionA s.attentional.precisionC
    s.subjectiveHidden.descendingSuspension)

/-- Opération 4 : Croisement Attentionnel II — routage sub-personnel vers les 9 canaux `A/C` et `C/A`. -/
def op4_crossingII_retroactive (s : CircularCircuitState) :
    SubjectiveReturnChannel × PerceptiveReturnChannel :=
  let c : EngineCoupling := ⟨op1_subjectiveOut s, op2_perceptiveOut s⟩
  (routeToSubjective c, routeToPerceptive c)

/-- Opération 5 : Entrée externe dans les `[États cachés]` subjectifs (9 canaux `A/C` + voie réflexive). -/
def op5_subjectiveIn (s : CircularCircuitState) (ch : SubjectiveReturnChannel)
    (perceptible : CoreAffectState) : HiddenSubjectiveState :=
  let nextDiscrepancy :=
    if ch.regimeA == .discharge then
      s.subjectiveHidden.modelDiscrepancy - 1
    else
      s.subjectiveHidden.modelDiscrepancy
  let nextRevisable :=
    s.subjectiveHidden.revisable ||
      (ch.regimeA == .charge && ch.contextC == .pos && decide (perceptible.point.z ≥ 2))
  let nextSuspension :=
    if ch.regimeA == .neutral && ch.contextC == .zero then false
    else s.subjectiveHidden.descendingSuspension
  { modelDiscrepancy     := nextDiscrepancy
    revisable            := nextRevisable
    descendingSuspension := nextSuspension }

/-- Opération 6 : Entrée externe dans les `[États cachés]` perceptifs (9 canaux `C/A` + `Corps & Env.`). -/
def op6_perceptiveIn (s : CircularCircuitState) (ch : PerceptiveReturnChannel)
    (perceptible : CoreAffectState) : HiddenPerceptiveState × BodyEnvironmentState :=
  let reduced :=
    if ch.regimeC == .discharge && decide (perceptible.point.y > 0) then
      s.perceptiveHidden.afferentDiscrepancy - 1
    else
      s.perceptiveHidden.afferentDiscrepancy
  let nextAfferent := reduced + s.bodyEnv.perturbation
  ({ afferentDiscrepancy := nextAfferent
     controllable        := s.perceptiveHidden.controllable },
   s.bodyEnv)

/-- Exécution d'un cycle complet fermé à travers les 6 opérations du circuit continu. -/
def circularCycle (s : CircularCircuitState) : CircularCircuitState :=
  let (_, perceptible) := op3_crossingI_perceptible s
  let (chSubj, chPerc) := op4_crossingII_retroactive s
  let nextSubj := op5_subjectiveIn s chSubj perceptible
  let (nextPerc, nextEnv) := op6_perceptiveIn s chPerc perceptible
  { s with
    subjectiveHidden := nextSubj
    perceptiveHidden := nextPerc
    bodyEnv          := nextEnv }

/-- Toute itération du circuit continu émet un `CoreAffectPoint` géométriquement valide. -/
theorem circularCycle_emits_valid_core_affect (s : CircularCircuitState) :
    isValidCoreAffect (op3_crossingI_perceptible s).2.point :=
  (op3_crossingI_perceptible s).2.h_valid

/-- Le point de Veille basal est un point fixe exact de la boucle fermée à 6 opérations. -/
theorem circularCycle_veille_fixed_point :
    circularCycle default = default ∧
    (op3_crossingI_perceptible default).2.point = ⟨0, 0, 0⟩ := by
  exact ⟨rfl, rfl⟩

private theorem op5_modelDiscrepancy_of_discharge (s : CircularCircuitState)
    (ch : SubjectiveReturnChannel) (p : CoreAffectState) (h : ch.regimeA = .discharge) :
    (op5_subjectiveIn s ch p).modelDiscrepancy = s.subjectiveHidden.modelDiscrepancy - 1 := by
  unfold op5_subjectiveIn; dsimp only; rw [h]; rfl

private theorem op5_modelDiscrepancy_le (s : CircularCircuitState)
    (ch : SubjectiveReturnChannel) (p : CoreAffectState) :
    (op5_subjectiveIn s ch p).modelDiscrepancy ≤ s.subjectiveHidden.modelDiscrepancy := by
  unfold op5_subjectiveIn; dsimp only; split <;> omega

private theorem op6_afferentDiscrepancy_le (s : CircularCircuitState)
    (ch : PerceptiveReturnChannel) (p : CoreAffectState) (h_pert : s.bodyEnv.perturbation = 0) :
    (op6_perceptiveIn s ch p).1.afferentDiscrepancy ≤ s.perceptiveHidden.afferentDiscrepancy := by
  unfold op6_perceptiveIn; dsimp only; rw [h_pert]; split <;> omega

private theorem op6_afferentDiscrepancy_of_discharge_pos (s : CircularCircuitState)
    (ch : PerceptiveReturnChannel) (p : CoreAffectState)
    (h_pert : s.bodyEnv.perturbation = 0) (hc : ch.regimeC = .discharge) (hy : p.point.y > 0) :
    (op6_perceptiveIn s ch p).1.afferentDiscrepancy = s.perceptiveHidden.afferentDiscrepancy - 1 := by
  unfold op6_perceptiveIn; dsimp only; rw [h_pert, hc]
  have hcond : (FunctionalRegime.discharge == FunctionalRegime.discharge && decide (p.point.y > 0)) = true := by
    have h1 : (FunctionalRegime.discharge == FunctionalRegime.discharge) = true := rfl
    have h2 : decide (p.point.y > 0) = true := decide_eq_true hy
    rw [h1, h2]; rfl
  simp only [hcond, ↓reduceIte, Nat.add_zero]

/--
En régime flexible sans perturbation exogène (`perturbation = 0`, `revisable = true`,
`controllable = true`, attention engagée et seuil `resorptionThreshold = 1`),
un cycle complet `circularCycle` réduit strictement l'écart total de prédiction.
-/
theorem circularCycle_reduces_total_discrepancy (s : CircularCircuitState)
    (h_pert : s.bodyEnv.perturbation = 0)
    (h_rev  : s.subjectiveHidden.revisable = true)
    (h_ctrl : s.perceptiveHidden.controllable = true)
    (h_eng  : s.attentional.isEngaged = true)
    (h_thr  : s.resorptionThreshold = 1)
    (h_pos  : s.subjectiveHidden.modelDiscrepancy + s.perceptiveHidden.afferentDiscrepancy > 0) :
    (circularCycle s).subjectiveHidden.modelDiscrepancy +
      (circularCycle s).perceptiveHidden.afferentDiscrepancy <
    s.subjectiveHidden.modelDiscrepancy + s.perceptiveHidden.afferentDiscrepancy := by
  change (op5_subjectiveIn s (op4_crossingII_retroactive s).1 (op3_crossingI_perceptible s).2).modelDiscrepancy +
      (op6_perceptiveIn s (op4_crossingII_retroactive s).2 (op3_crossingI_perceptible s).2).1.afferentDiscrepancy <
    s.subjectiveHidden.modelDiscrepancy + s.perceptiveHidden.afferentDiscrepancy
  cases hm : s.subjectiveHidden.modelDiscrepancy with
  | succ m' =>
    have hop1 : op1_subjectiveOut s = .pos := by
      unfold op1_subjectiveOut
      rw [h_thr, h_rev, hm]
      rfl
    have h_regA : (op4_crossingII_retroactive s).1.regimeA = .discharge := by
      unfold op4_crossingII_retroactive routeToSubjective
      dsimp only
      rw [hop1]
      rfl
    have h5 := op5_modelDiscrepancy_of_discharge s (op4_crossingII_retroactive s).1
      (op3_crossingI_perceptible s).2 h_regA
    have h6 := op6_afferentDiscrepancy_le s (op4_crossingII_retroactive s).2
      (op3_crossingI_perceptible s).2 h_pert
    omega
  | zero =>
    cases ha : s.perceptiveHidden.afferentDiscrepancy with
    | zero => omega
    | succ a' =>
      have hop1 : op1_subjectiveOut s = .zero := by
        unfold op1_subjectiveOut
        rw [h_thr, hm]
        rfl
      have hop2 : op2_perceptiveOut s = .pos := by
        unfold op2_perceptiveOut
        rw [h_thr, h_ctrl, ha]
        rfl
      have h_regC : (op4_crossingII_retroactive s).2.regimeC = .discharge := by
        unfold op4_crossingII_retroactive routeToPerceptive
        dsimp only
        rw [hop2]
        rfl
      have hy : (op3_crossingI_perceptible s).2.point.y > 0 := by
        unfold op3_crossingI_perceptible projectPerceptibleState
        dsimp only
        rw [hop1, hop2]
        have hn : ({ attente := Polarity.zero, controle := Polarity.pos } : EngineCoupling).isGlobalNeutrality = false := rfl
        have he : (!s.attentional.isEngaged) = false := by rw [h_eng]; rfl
        simp only [hn, he, Bool.false_eq_true, ↓reduceIte, projectPerceptible,
          deployCouplingWithPrecision, signedAmplitude]
        change (↑(2 * s.attentional.persistenceDepth + 2) : Int) > 0
        omega
      have h5 := op5_modelDiscrepancy_le s (op4_crossingII_retroactive s).1
        (op3_crossingI_perceptible s).2
      have h6 := op6_afferentDiscrepancy_of_discharge_pos s (op4_crossingII_retroactive s).2
        (op3_crossingI_perceptible s).2 h_pert h_regC hy
      omega

/-!
## 7. Loi unifiée (Axe iv) : récurrence de charge `R_t`, strate `Z_t` (R5) et partage `(pi_A, pi_C)`
-/

/--
Paramètres de la loi unifiée couplant le plan horizontal `(A, C)` à l'axe vertical `Z` :
- `halfScale` : demi-budget normalisé (`S = 2 * halfScale > 0`, défaut `S = 1000`) ;
- `lambdaNum` : facteur de mémoire allostatique (`lambda = lambdaNum / S < 1`) ;
- `etaScaled` : apaisement strict associé à chaque transition de résolution active (`- -> +`) ;
- `betaAtt`, `alphaCharge`, `sigmoidK` : sensibilité et gain d'arbitrage attentionnel ;
- `zMax` : profondeur maximale de la taxonomie (`7` par défaut, `≥ 2`) ;
- `thetaUp`, `thetaDown` : seuils avec hystérésis stricte `thetaDown z < thetaUp z`.
-/
structure UnifiedDynamicsParams where
  halfScale   : Nat
  lambdaNum   : Nat
  etaScaled   : Nat
  betaAtt     : Nat
  alphaCharge : Nat
  sigmoidK    : Nat
  zMax        : Nat
  thetaUp     : Nat → Nat
  thetaDown   : Nat → Nat
  h_half_pos  : halfScale > 0
  h_lambda_lt : lambdaNum < 2 * halfScale
  h_k_pos     : sigmoidK > 0
  h_zmax_ge2  : zMax ≥ 2
  h_hyst      : ∀ z, thetaDown z < thetaUp z

/-- Paramétrisation canonique de la loi unifiée (échelle normalisée `S = 1000`, horizon discret `Z_max = 5`, Arbitrage 4). -/
instance : Inhabited UnifiedDynamicsParams where
  default := {
    halfScale   := 500
    lambdaNum   := 800
    etaScaled   := 600
    betaAtt     := 2
    alphaCharge := 50
    sigmoidK    := 100
    zMax        := 5
    thetaUp     := fun z => 600 + 200 * z
    thetaDown   := fun z => 300 + 200 * z
    h_half_pos  := by decide
    h_lambda_lt := by decide
    h_k_pos     := by decide
    h_zmax_ge2  := by decide
    h_hyst      := fun z => by omega
  }

/--
Compte le nombre de transitions de résolution active (`Charge - -> Décharge +`) entre `src` et `dst`
(`0`, `1` ou `2`). Une extinction passive (`- -> 0`) produit rigoureusement `0`.
-/
def activeResolutionCount (src dst : EngineCoupling) : Nat :=
  (if src.attente == .neg && dst.attente == .pos then 1 else 0) +
  (if src.controle == .neg && dst.controle == .pos then 1 else 0)

/--
Équation 1 : mise à jour de l'accumulateur de récurrence de charge `R_{t+1}` (tronqué à `0` en `Nat`)
sur les parts de précision normalisées `piAScaled + piCScaled = 2 * halfScale`.
-/
def nextChargeAccumulator (p : UnifiedDynamicsParams) (r piAScaled piCScaled : Nat)
    (src dst : EngineCoupling) : Nat :=
  let s := 2 * p.halfScale
  let contribA := if src.attente == .neg then piAScaled else 0
  let contribC := if src.controle == .neg then piCScaled else 0
  let relief := p.etaScaled * activeResolutionCount src dst
  (p.lambdaNum * r) / s + contribA + contribC - relief

/-- Borne supérieure exacte de l'accumulateur de charge : `R_max = floor(S^2 / (S - lambdaNum))`. -/
def chargeAccumulatorBound (p : UnifiedDynamicsParams) : Nat :=
  let s := 2 * p.halfScale
  (s * s) / (s - p.lambdaNum)

/-- Toute extinction passive directe `(A-, C0) -> (A0, C0)` obtient un apaisement actif nul (`0`). -/
theorem passive_extinction_zero_relief :
    activeResolutionCount ⟨.neg, .zero⟩ ⟨.zero, .zero⟩ = 0 := by
  decide

/--
À précision `(piAScaled, piCScaled)` et état source `src` quelconques, toute transition de résolution
active (`activeResolutionCount src dstAct > 0`) réduit strictement davantage l'accumulateur `R_{t+1}`
qu'une transition sans résolution active (`activeResolutionCount src dstPass = 0`, dont l'extinction
passive) dès que `etaScaled > 0` et que l'accumulateur avant apaisement est strictement positif.
-/
theorem active_resolution_beats_passive_extinction (p : UnifiedDynamicsParams)
    (r piAScaled piCScaled : Nat) (src dstAct dstPass : EngineCoupling)
    (h_eta : p.etaScaled > 0)
    (h_act : activeResolutionCount src dstAct > 0)
    (h_pass : activeResolutionCount src dstPass = 0)
    (h_pos : (p.lambdaNum * r) / (2 * p.halfScale) +
      (if src.attente == .neg then piAScaled else 0) +
      (if src.controle == .neg then piCScaled else 0) > 0) :
    nextChargeAccumulator p r piAScaled piCScaled src dstAct <
    nextChargeAccumulator p r piAScaled piCScaled src dstPass := by
  unfold nextChargeAccumulator
  dsimp only
  rw [h_pass, Nat.mul_zero, Nat.sub_zero]
  have h_rel_pos : p.etaScaled * activeResolutionCount src dstAct > 0 := Nat.mul_pos h_eta h_act
  omega

/--
Stabilité bornée de l'accumulateur de charge : dès que `piAScaled + piCScaled = 2 * halfScale`
et `r ≤ chargeAccumulatorBound p`, la valeur suivante `R_{t+1}` reste bornée par `chargeAccumulatorBound p`.
-/
theorem charge_accumulator_bounded (p : UnifiedDynamicsParams)
    (r piAScaled piCScaled : Nat) (src dst : EngineCoupling)
    (h_budget : piAScaled + piCScaled = 2 * p.halfScale)
    (h_le : r ≤ chargeAccumulatorBound p) :
    nextChargeAccumulator p r piAScaled piCScaled src dst ≤ chargeAccumulatorBound p := by
  let s := 2 * p.halfScale
  let l := p.lambdaNum
  let rMax := (s * s) / (s - l)
  have hs_pos : 0 < s := by have := p.h_half_pos; omega
  have hl_lt : l < s := p.h_lambda_lt
  have hd_pos : 0 < s - l := by omega
  have hd_le : s - l ≤ s := by omega
  have h_ss_ge : s * (s - l) ≤ s * s := Nat.mul_le_mul_left s hd_le
  have hrMax_ge_s : s ≤ rMax := by
    have hq : s = (s * (s - l)) / (s - l) := (Nat.mul_div_left s hd_pos).symm
    rw [hq]
    exact Nat.div_le_div_right h_ss_ge
  have h_div_add : (s - l) * rMax + (s * s) % (s - l) = s * s := Nat.div_add_mod (s * s) (s - l)
  have h_mod_lt : (s * s) % (s - l) < s - l := Nat.mod_lt (s * s) hd_pos
  have h_decomp : (s - l) * rMax + l * rMax = s * rMax := by
    rw [← Nat.add_mul, Nat.sub_add_cancel (Nat.le_of_lt hl_lt)]
  have h_rhs_eq : s * (rMax - s + 1) + s * s = s * rMax + s := by
    rw [Nat.mul_add, Nat.mul_sub_left_distrib, Nat.mul_one]
    have h_sr : s * s ≤ s * rMax := Nat.mul_le_mul_left s hrMax_ge_s
    omega
  have h_lt_s : l * rMax < s * (rMax - s + 1) := by omega
  have h_div_lt : (l * rMax) / s < rMax - s + 1 := Nat.div_lt_of_lt_mul h_lt_s
  have h_lr_le : (l * r) / s ≤ (l * rMax) / s :=
    Nat.div_le_div_right (Nat.mul_le_mul_left l h_le)
  have h_contrib :
      (if src.attente == .neg then piAScaled else 0) +
      (if src.controle == .neg then piCScaled else 0) ≤ s := by
    cases src.attente <;> cases src.controle <;> dsimp <;> omega
  change (l * r) / s + (if src.attente == .neg then piAScaled else 0) +
      (if src.controle == .neg then piCScaled else 0) -
      p.etaScaled * activeResolutionCount src dst ≤ rMax
  omega

/--
Équation 2 : loi de montée et de redescente en strate `Z_t` intégrant l'hystérésis `thetaDown < thetaUp`
et le court-circuit explicite R5 : la descente depuis `Z = 2` (ou `Z = 1`) rejoint directement `Z = 0`,
en réservant strictement `Z = 1` (Surprise) à la rupture ascendante.
-/
def nextStratumR5 (p : UnifiedDynamicsParams) (z rNext : Nat) : Nat :=
  if rNext > p.thetaUp z then
    min p.zMax (z + 1)
  else if rNext < p.thetaDown z then
    match z with
    | 0     => 0
    | 1     => 0
    | 2     => 0
    | k + 3 => min p.zMax (k + 2)
  else
    min p.zMax z

/-- La dynamique de strate préserve toujours le plafond `zMax`. -/
theorem nextStratumR5_le_zMax (p : UnifiedDynamicsParams) (z rNext : Nat) :
    nextStratumR5 p z rNext ≤ p.zMax := by
  unfold nextStratumR5
  split
  · exact Nat.min_le_left _ _
  · split
    · cases z with
      | zero => dsimp only; omega
      | succ z1 =>
        cases z1 with
        | zero => dsimp only; omega
        | succ z2 =>
          cases z2 with
          | zero => dsimp only; omega
          | succ k => exact Nat.min_le_left _ _
    · exact Nat.min_le_left _ _

/-- Court-circuit explicite R5 : en redescente depuis `Z = 2`, `nextStratumR5` saute directement à `0`. -/
theorem nextStratumR5_short_circuits_z2_to_veille (p : UnifiedDynamicsParams) (rNext : Nat)
    (h_down : rNext < p.thetaDown 2) :
    nextStratumR5 p 2 rNext = 0 := by
  have hh := p.h_hyst 2
  have h_not_up : ¬ (rNext > p.thetaUp 2) := by omega
  unfold nextStratumR5
  simp only [h_not_up, h_down, ↓reduceIte]

/--
Évitement strict de la Surprise en redescente (R5) :
aucune transition issue d'une strate `Z ≥ 2` n'atterrit en strate `Z = 1`.
-/
theorem nextStratumR5_from_ge2_never_visits_surprise (p : UnifiedDynamicsParams) (z rNext : Nat)
    (hz : z ≥ 2) :
    nextStratumR5 p z rNext ≠ 1 := by
  have hzmax := p.h_zmax_ge2
  unfold nextStratumR5
  split
  · omega
  · split
    · cases z with
      | zero => omega
      | succ z1 =>
        cases z1 with
        | zero => omega
        | succ z2 =>
          cases z2 with
          | zero => simp
          | succ k => dsimp; omega
    · omega

/-- Sigmoïde rationnelle entière symétrique sur `[0, 2 * halfScale]` modélisant le partage logistique. -/
def symmetricSigmoid (halfScale K : Nat) (u : Int) : Nat × Nat :=
  let shift := (halfScale * u.natAbs) / (u.natAbs + K)
  if u ≥ 0 then
    (halfScale + shift, halfScale - shift)
  else
    (halfScale - shift, halfScale + shift)

private theorem symmetricSigmoid_shift_lt (halfScale K : Nat) (u : Int)
    (h_pos : halfScale > 0) (hk : K > 0) :
    (halfScale * u.natAbs) / (u.natAbs + K) < halfScale := by
  have h_lt : halfScale * u.natAbs < (u.natAbs + K) * halfScale := by
    have h1 : u.natAbs * halfScale < (u.natAbs + K) * halfScale :=
      Nat.mul_lt_mul_of_pos_right (by omega) h_pos
    rwa [Nat.mul_comm u.natAbs halfScale] at h1
  exact Nat.div_lt_of_lt_mul h_lt

/-- Conservation exacte du budget normalisé de la sigmoïde rationnelle : `pi_A + pi_C = 2 * halfScale`. -/
theorem symmetricSigmoid_sum (halfScale K : Nat) (u : Int) (hk : K > 0) :
    (symmetricSigmoid halfScale K u).1 + (symmetricSigmoid halfScale K u).2 = 2 * halfScale := by
  have h_le : (halfScale * u.natAbs) / (u.natAbs + K) ≤ halfScale := by
    have h1 : u.natAbs * halfScale ≤ (u.natAbs + K) * halfScale :=
      Nat.mul_le_mul_right halfScale (by omega)
    rw [Nat.mul_comm u.natAbs halfScale] at h1
    exact Nat.div_le_of_le_mul h1
  unfold symmetricSigmoid
  dsimp only
  split <;> dsimp <;> omega

/-- Strict positivité des deux parts issues de `symmetricSigmoid` dès que `halfScale > 0` et `K > 0`. -/
theorem symmetricSigmoid_pos (halfScale K : Nat) (u : Int)
    (h_pos : halfScale > 0) (hk : K > 0) :
    (symmetricSigmoid halfScale K u).1 > 0 ∧ (symmetricSigmoid halfScale K u).2 > 0 := by
  have h_lt := symmetricSigmoid_shift_lt halfScale K u h_pos hk
  unfold symmetricSigmoid
  dsimp only
  split
  · exact ⟨Nat.lt_of_lt_of_le h_pos (Nat.le_add_right _ _), Nat.sub_pos_of_lt h_lt⟩
  · exact ⟨Nat.sub_pos_of_lt h_lt, Nat.lt_of_lt_of_le h_pos (Nat.le_add_right _ _)⟩

/-- Antisymétrie exacte : inverser le score `u -> -u` permute rigoureusement `(pi_A, pi_C) <-> (pi_C, pi_A)`. -/
theorem symmetricSigmoid_neg (halfScale K : Nat) (u : Int) :
    symmetricSigmoid halfScale K (-u) =
      ((symmetricSigmoid halfScale K u).2, (symmetricSigmoid halfScale K u).1) := by
  unfold symmetricSigmoid
  have habs : (-u).natAbs = u.natAbs := Int.natAbs_neg u
  rw [habs]
  dsimp only
  by_cases h0 : u = 0
  · subst h0; simp
  · split <;> split <;> first | rfl | (exfalso; omega)

/-- Indicateur entier `1` en état de Charge (`Polarity.neg`), `0` sinon. -/
def chargeIndicatorInt (pol : Polarity) : Int :=
  if pol == .neg then 1 else 0

/--
Score d'arbitrage attentionnel :
`u = beta * ((rhoHat - kappaHat) + alpha * (I(a = -1) - I(c = -1)))`.
-/
def precisionScore (p : UnifiedDynamicsParams) (rhoHat kappaHat : Nat) (c : EngineCoupling) : Int :=
  Int.ofNat p.betaAtt *
    ((Int.ofNat rhoHat - Int.ofNat kappaHat) +
      Int.ofNat p.alphaCharge * (chargeIndicatorInt c.attente - chargeIndicatorInt c.controle))

/-- Équation 3 : partage dynamique des précisions normalisées `(pi_A, pi_C)` sommant à `2 * halfScale`. -/
def precisionShares (p : UnifiedDynamicsParams) (rhoHat kappaHat : Nat)
    (c : EngineCoupling) : Nat × Nat :=
  symmetricSigmoid p.halfScale p.sigmoidK (precisionScore p rhoHat kappaHat c)

/-- Budget spatial géométrique à la strate `Z` : `0` en `Z < 2`, `2Z - 2` en `Z ≥ 2`. -/
def spatialBudget (z : Nat) : Nat :=
  if z < 2 then 0 else 2 * z - 2

/--
Pont complet vers le Noyau affectif : projette le couplage `(A, C)` et la strate `Z` en
injectant le partage dynamique `(pi_A, pi_C) = precisionShares` dans `projectPerceptibleState` (`apportionRay`).
-/
def projectUnifiedState (p : UnifiedDynamicsParams) (c : EngineCoupling)
    (z rhoHat kappaHat : Nat) (susp : Bool) : CoreAffectState :=
  let shares := precisionShares p rhoHat kappaHat c
  projectPerceptibleState c z shares.1 shares.2 susp

/--
Propriété émergente en Double Charge `(A-, C-)` : les indicateurs de charge s'annulent exactement
(`1 - 1 = 0`), de sorte que l'arbitrage attentionnel dépend uniquement de l'efficacité relative `(rhoHat - kappaHat)`.
-/
theorem precisionShare_double_charge_cancels_alpha (p : UnifiedDynamicsParams)
    (rhoHat kappaHat : Nat) :
    precisionScore p rhoHat kappaHat ⟨.neg, .neg⟩ =
      Int.ofNat p.betaAtt * (Int.ofNat rhoHat - Int.ofNat kappaHat) := by
  unfold precisionScore chargeIndicatorInt
  simp

/-- Toute projection issue de la loi unifiée satisfait l'invariant géométrique `isValidCoreAffect`. -/
theorem projectUnifiedState_valid (p : UnifiedDynamicsParams) (c : EngineCoupling)
    (z rhoHat kappaHat : Nat) (susp : Bool) :
    isValidCoreAffect (projectUnifiedState p c z rhoHat kappaHat susp).point :=
  (projectUnifiedState p c z rhoHat kappaHat susp).h_valid

/-- Sous couplage actif à une strate `Z ≥ 2`, la projection unifiée conserve exactement `spatialBudget z`. -/
theorem projectUnifiedState_crown_budget (p : UnifiedDynamicsParams) (c : EngineCoupling)
    (z rhoHat kappaHat : Nat) (susp : Bool)
    (h_act : c.isGlobalNeutrality = false) (hz : z ≥ 2) :
    let pt := (projectUnifiedState p c z rhoHat kappaHat susp).point
    pt.x.natAbs + pt.y.natAbs = spatialBudget z := by
  dsimp
  have h_sb : spatialBudget z = 2 * z - 2 := by unfold spatialBudget; split <;> omega
  rw [h_sb]
  unfold projectUnifiedState projectPerceptibleState projectPerceptible precisionShares
  dsimp only
  simp only [h_act, Bool.false_eq_true, ↓reduceIte]
  cases hzs : z with
  | zero => omega
  | succ z1 =>
    cases z1 with
    | zero => omega
    | succ d =>
      dsimp only
      have hv := deployCouplingWithPrecision_budget_conservation c d
        (symmetricSigmoid p.halfScale p.sigmoidK (precisionScore p rhoHat kappaHat c)).1
        (symmetricSigmoid p.halfScale p.sigmoidK (precisionScore p rhoHat kappaHat c)).2 h_act
      unfold CoreAffectPoint.displacementSum at hv
      have h_eq : 2 * d + 2 = 2 * (d + 2) - 2 := by omega
      omega

/--
Témoin d'accessibilité latérale (R8 & Option 1A) par la loi unifiée :
en couplage `(A-, C+)` à `Z = 3`, lorsque l'efficacité pragmatique domine l'efficacité épistémique
(`rhoHat = 10`, `kappaHat = 90`), le partage logistique projette l'agent en `(-1, 3, 3)` (affrontement agentique latéral).
-/
theorem projectUnifiedState_reaches_lateral_agentic_confront :
    (projectUnifiedState (default : UnifiedDynamicsParams) ⟨.neg, .pos⟩ 3 10 90 true).point =
      ⟨-1, 3, 3⟩ := by
  decide

end PredictiveCircuit

end Cartograffect
