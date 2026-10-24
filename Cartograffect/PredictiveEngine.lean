namespace Cartograffect

namespace PredictiveEngine

/-!
## 1. Types fondamentaux des gradients et régimes fonctionnels
-/

-- Source : Document 1, §4 (Le Moteur prédictif) & §5 (Le Noyau affectif)
/--
Polarité discrète d'un gradient d'incertitude :
- `neg`  (−) : état d'incertitude (faible confiance dans la capacité de résolution).
- `zero` (0) : état de neutralité (signal sous le seuil de saillance propre au gradient).
- `pos`  (+) : état de certitude (confiance élevée dans la capacité de résolution).
Ces signes qualifient exclusivement un état computationnel et non une valence.
-/
inductive Polarity : Type where
  | neg  : Polarity
  | zero : Polarity
  | pos  : Polarity
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 1, Résumé & §4 (Le Moteur prédictif)
/--
Modalités fonctionnelles du traitement de l'écart de prédiction :
- `charge`    : accumulation de l'écart de prédiction.
- `neutral`   : maintien sous le seuil de saillance (ni charge ni décharge).
- `discharge` : dissipation de l'écart de prédiction.
-/
inductive FunctionalRegime : Type where
  | charge    : FunctionalRegime
  | neutral   : FunctionalRegime
  | discharge : FunctionalRegime
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 1, §4 (Le Moteur prédictif)
/-- Associe chaque polarité de gradient à sa modalité fonctionnelle de résolution. -/
def Polarity.toRegime : Polarity → FunctionalRegime
  | .neg  => .charge
  | .zero => .neutral
  | .pos  => .discharge

-- Source : Document 1, §4 (Le Moteur prédictif) & §6.2 (Antagonismes formels)
/-- Opérateur d'inversion formelle de la polarité d'un gradient. -/
def Polarity.invert : Polarity → Polarity
  | .neg  => .pos
  | .zero => .zero
  | .pos  => .neg

-- Source : Document 1, §4 (Le Moteur prédictif)
/-- Conversion unitaire d'une polarité en entier signé {-1, 0, +1}. -/
def Polarity.toInt : Polarity → Int
  | .neg  => -1
  | .zero => 0
  | .pos  => 1

-- Source : Document 1, §4 (Le Moteur prédictif)
/-- Indique si le gradient est engagé (c'est-à-dire tranché positivement ou négativement). -/
def Polarity.isEngaged : Polarity → Bool
  | .zero => false
  | .neg  => true
  | .pos  => true

/-!
## 2. Signaux d'entrée, Interfaces et Opérations inférentielles
-/

-- Source : Document 1, §4 (Le Moteur prédictif) & §6.3 (Dynamique de la Matrice)
/--
Grandeur d'entrée du Moteur prédictif : l'écart de prédiction que l'organisme doit résorber.
Intègre l'invariant d'hystérésis (§6.3) : le seuil de résorption homéostatique est inférieur
ou égal au seuil d'activation sensorielle initial, créant une plage de rémanence temporaire.
-/
structure SalientDiscrepancy where
  magnitude           : Nat
  sensoryThreshold    : Nat
  resorptionThreshold : Nat
  h_hysteresis        : resorptionThreshold ≤ sensoryThreshold
  deriving Repr

-- Source : Document 1, §4 (Le Moteur prédictif)
/-- Instance par défaut représentant un écart nul en régime homéostatique basal. -/
instance : Inhabited SalientDiscrepancy where
  default := {
    magnitude           := 0
    sensoryThreshold    := 1
    resorptionThreshold := 1
    h_hysteresis        := Nat.le_refl 1
  }

-- Source : Document 1, §4 (Le Moteur prédictif)
/-- Vérifie si l'écart de prédiction franchit le seuil de saillance sensorielle. -/
def SalientDiscrepancy.isSensorilySalient (d : SalientDiscrepancy) : Bool :=
  decide (d.sensoryThreshold ≤ d.magnitude)

-- Source : Document 1, §6.3 (Dynamique de la Matrice)
/--
Vérifie si l'écart résiduel demeure dans la fenêtre de rémanence temporaire
(entre le seuil de résorption homéostatique et le seuil d'activation initial).
-/
def SalientDiscrepancy.isInRemanenceWindow (d : SalientDiscrepancy) : Bool :=
  decide (d.resorptionThreshold ≤ d.magnitude ∧ d.magnitude < d.sensoryThreshold)

-- Source : Document 1, §4 (Le Moteur prédictif - Interface Perceptive)
/--
Interface Perceptive (versant sensoriel et actif de la frontière) :
Évalue le gradient de Contrôle (C : contrôlabilité pragmatique de la situation)
à partir des signaux afférents confrontés aux effets attendus de l'action.
-/
structure PerceptiveInterface where
  controleGradient : Polarity
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 1, §4 (Le Moteur prédictif - Interface Subjective)
/--
Interface Subjective (versant prédictif interne de la frontière) :
Évalue le gradient d'Attente (A : révisabilité épistémique du modèle interne)
et génère l'Anticipation (projection proactive descendante pouvant suspendre la décharge).
-/
structure SubjectiveInterface where
  attenteGradient      : Polarity
  descendingSuspension : Bool
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 1, §4 (Le Moteur prédictif - Interface Attentionnelle) & Document 2, Préambule
/--
Interface Attentionnelle (mécanisme de pondération de la précision) :
N'évalue aucun contenu propre et ne produit aucun gradient polarisé.
Attribue un coefficient de précision aux gradients A et C et indexe la profondeur
additionnelle liée à la persistance d'un écart non résolu.
-/
structure AttentionalInterface where
  allocatedPrecision  : Nat
  engagementThreshold : Nat
  persistenceDepth    : Nat
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 1, §4 (Le Moteur prédictif - Interface Attentionnelle)
/-- Vérifie si la précision allouée franchit le seuil d'engagement attentionnel. -/
def AttentionalInterface.isEngaged (att : AttentionalInterface) : Bool :=
  decide (att.engagementThreshold ≤ att.allocatedPrecision)

-- Source : Document 1, §4 (Le Moteur prédictif)
/--
Les quatre opérations inférentielles interdépendantes et non séquentielles
formant la boucle récursive de circulation entre les trois interfaces.
-/
inductive InferentialOperation : Type where
  | ascendingSensory     : InferentialOperation -- Versant perceptif : inférence sensorielle ascendante
  | actionImplementation : InferentialOperation -- Versant sensorimoteur : mise en œuvre de l'action
  | contextualGenerative : InferentialOperation -- Interface Subjective : inférence générative contextuelle
  | integrativeWeighting : InferentialOperation -- Interface Attentionnelle : inférence intégrative pondérée
  deriving DecidableEq, Repr, Inhabited

/-!
## 3. Espace des couplages (A/C) et État global du Moteur prédictif
-/

-- Source : Document 1, §4 (Le Moteur prédictif & Figure 1)
/--
Couplage des deux gradients d'incertitude produits par le Moteur prédictif :
- `attente`  (A) : révisabilité du modèle génératif (Interface Subjective).
- `controle` (C) : contrôlabilité de la situation (Interface Perceptive).
-/
structure EngineCoupling where
  attente  : Polarity
  controle : Polarity
  deriving DecidableEq, Repr, Inhabited

-- Source : Document 1, §4 (Le Moteur prédictif)
/--
Neutralité globale du système : correspond exclusivement à l'état conjoint (A0, C0)
du Point de Veille.
-/
def EngineCoupling.isGlobalNeutrality (c : EngineCoupling) : Bool :=
  !c.attente.isEngaged && !c.controle.isEngaged

-- Source : Document 1, §4 (Le Moteur prédictif) & §5.2 (Modulation attentionnelle)
/--
Engagement unidimensionnel (régime axial) : une seule dimension (A ou C) est engagée
tandis que l'autre demeure sous son seuil de saillance (neutre).
-/
def EngineCoupling.isSingleEngaged (c : EngineCoupling) : Bool :=
  (c.attente.isEngaged && !c.controle.isEngaged) ||
  (!c.attente.isEngaged && c.controle.isEngaged)

-- Source : Document 1, §4 (Le Moteur prédictif) & §5.2 (Modulation attentionnelle)
/--
Engagement bidimensionnel conjoint (régime diagonal) : les deux dimensions A et C
sont tranchées simultanément.
-/
def EngineCoupling.isDualEngaged (c : EngineCoupling) : Bool :=
  c.attente.isEngaged && c.controle.isEngaged

-- Source : Document 1, §4 (Le Moteur prédictif)
/--
Liste exhaustive des 9 combinaisons d'états des gradients (A, C), définissant
les 9 possibilités d'action sur la voie ascendante réflexive et les 9 politiques
d'action sur la voie descendante comportementale.
-/
def allCouplings : List EngineCoupling := [
  ⟨.zero, .zero⟩,
  ⟨.pos,  .zero⟩, ⟨.neg,  .zero⟩, ⟨.zero, .pos⟩, ⟨.zero, .neg⟩,
  ⟨.pos,  .pos⟩,  ⟨.pos,  .neg⟩,  ⟨.neg,  .pos⟩, ⟨.neg,  .neg⟩
]

-- Source : Document 1, §4 (Le Moteur prédictif) & §7 (Boucle d'inférence active)
/--
État global du Moteur prédictif réunissant la grandeur d'entrée (écart de prédiction)
et les trois interfaces fonctionnelles (Perceptive, Subjective et Attentionnelle).
-/
structure PredictiveEngineState where
  discrepancy : SalientDiscrepancy
  perceptive  : PerceptiveInterface
  subjective  : SubjectiveInterface
  attentional : AttentionalInterface
  deriving Repr, Inhabited

-- Source : Document 1, §4 (Le Moteur prédictif)
/-- Extrait le couplage (A, C) courant produit par les Interfaces Subjective et Perceptive. -/
def PredictiveEngineState.currentCoupling (s : PredictiveEngineState) : EngineCoupling :=
  { attente  := s.subjective.attenteGradient
    controle := s.perceptive.controleGradient }

-- Source : Document 1, §7 (Arbitrage attentionnel - étape 5 de la boucle)
/--
Opérateur dynamique de rétroaction (Arbitrage attentionnel) :
Réinjecte les nouveaux gradients d'Attente (voie épistémique vers l'Interface Subjective)
et de Contrôle (voie pragmatique vers l'Interface Perceptive).
-/
def PredictiveEngineState.feedbackUpdate
    (s : PredictiveEngineState)
    (newA : Polarity)
    (newC : Polarity)
    (newPrecision : Nat) : PredictiveEngineState :=
  { s with
    subjective  := { s.subjective with attenteGradient := newA }
    perceptive  := { s.perceptive with controleGradient := newC }
    attentional := { s.attentional with allocatedPrecision := newPrecision } }

/-!
## 4. Démonstration des invariants fondamentaux du Moteur prédictif
-/

/-- Invariant 1 : L'inversion de polarité d'un gradient est une involution stricte. -/
theorem Polarity.invert_involutive (p : Polarity) : p.invert.invert = p := by
  cases p <;> rfl

/-- Invariant 2 : Le régime neutre correspond exclusivement à la polarité nulle (0). -/
theorem Polarity.toRegime_neutral_iff (p : Polarity) :
    p.toRegime = .neutral ↔ p = .zero := by
  cases p <;> decide

/--
Invariant 3 (Doc. 1, §4) : La neutralité d'un seul gradient n'implique pas la neutralité
globale du système, puisque l'autre gradient peut simultanément être engagé.
-/
theorem single_neutral_not_global_neutral :
    ∃ c : EngineCoupling, c.attente = .zero ∧ c.isGlobalNeutrality = false := by
  refine ⟨⟨.zero, .pos⟩, rfl, rfl⟩

/--
Invariant 4 (Doc. 1, §4) : Le répertoire des couplages (A, C) comporte exactement
9 configurations distinctes (9 possibilités d'action réflexives / 9 politiques comportementales).
-/
theorem allCouplings_card : allCouplings.length = 9 := rfl

/--
Invariant 5 : Complétude de l'espace des couplages — tout couplage possible des gradients
d'Attente et de Contrôle appartient aux 9 combinaisons répertoriées.
-/
theorem mem_allCouplings (c : EngineCoupling) : c ∈ allCouplings := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> decide

/--
Invariant 6 (Trichotomie fonctionnelle du Moteur prédictif, Doc. 1, §4) :
Tout couplage (A, C) se répartit de manière mutuellement exclusive entre :
1. La neutralité globale (A0, C0),
2. L'engagement unidimensionnel (exactement un gradient tranché),
3. L'engagement bidimensionnel conjoint (les deux gradients tranchés).
-/
theorem coupling_regime_partition (c : EngineCoupling) :
    (c.isGlobalNeutrality = true ∧ c.isSingleEngaged = false ∧ c.isDualEngaged = false) ∨
    (c.isGlobalNeutrality = false ∧ c.isSingleEngaged = true ∧ c.isDualEngaged = false) ∨
    (c.isGlobalNeutrality = false ∧ c.isSingleEngaged = false ∧ c.isDualEngaged = true) := by
  cases c with
  | mk a ctrl =>
    cases a <;> cases ctrl <;> decide

end PredictiveEngine

end Cartograffect
