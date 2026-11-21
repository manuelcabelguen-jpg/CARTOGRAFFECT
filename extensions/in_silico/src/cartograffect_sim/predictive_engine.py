"""Moteur prédictif CARTOGRAFFECT® (isomorphe à `Cartograffect/PredictiveEngine.lean`).

Implémente les types discrets et opérateurs déterministes du Moteur prédictif :
- Polarités discrètes des gradients (`Polarity`) et régimes fonctionnels (`FunctionalRegime`) ;
- Écart de prédiction saillant avec invariant d'hystérésis (`SalientDiscrepancy`) ;
- Trois interfaces fonctionnelles (`PerceptiveInterface`, `SubjectiveInterface`,
  `AttentionalInterface`) et quatre opérations inférentielles (`InferentialOperation`) ;
- Partition exhaustive des 9 couplages `(A, C)` (`EngineCoupling`, `ALL_COUPLINGS`) ;
- Rétroactions (`feedback_update`, `feedback_update_weighted`) et transition
  séquentielle à quatre régimes (`engine_step`).
"""

from __future__ import annotations

import math
from collections.abc import Sequence
from dataclasses import dataclass, field, replace
from enum import Enum
from functools import partial

import equinox as eqx
import jax
import jax.numpy as jnp
import numpy as np
from pymdp import control as pymdp_control
from pymdp.agent import Agent

from .generative_process import (
    BanditAction,
    CueSignal,
    OutcomeValence,
    TrialObservation,
)


class FunctionalRegime(str, Enum):
    """Modalités fonctionnelles du traitement de l'écart de prédiction."""

    CHARGE = "charge"
    NEUTRAL = "neutral"
    DISCHARGE = "discharge"


class Polarity(str, Enum):
    """Polarité discrète d'un gradient d'incertitude : `-1`, `0`, `+1`."""

    NEG = "neg"
    ZERO = "zero"
    POS = "pos"

    def to_regime(self) -> FunctionalRegime:
        """Associe chaque polarité de gradient à sa modalité fonctionnelle."""
        return _POLARITY_TO_REGIME[self]

    def invert(self) -> Polarity:
        """Opérateur d'inversion formelle de la polarité d'un gradient."""
        return _POLARITY_INVERT[self]

    def to_int(self) -> int:
        """Conversion unitaire d'une polarité en entier signé ``{-1, 0, +1}``."""
        return _POLARITY_TO_INT[self]

    def is_engaged(self) -> bool:
        """Indique si le gradient est engagé (tranché positivement ou négativement)."""
        return self is not Polarity.ZERO

    @classmethod
    def from_int(cls, value: int) -> Polarity:
        """Convertit un entier signé ``(< 0, 0, > 0)`` en polarité discrète."""
        if value < 0:
            return cls.NEG
        if value > 0:
            return cls.POS
        return cls.ZERO


_POLARITY_TO_REGIME: dict[Polarity, FunctionalRegime] = {
    Polarity.NEG: FunctionalRegime.CHARGE,
    Polarity.ZERO: FunctionalRegime.NEUTRAL,
    Polarity.POS: FunctionalRegime.DISCHARGE,
}

_POLARITY_INVERT: dict[Polarity, Polarity] = {
    Polarity.NEG: Polarity.POS,
    Polarity.ZERO: Polarity.ZERO,
    Polarity.POS: Polarity.NEG,
}

_POLARITY_TO_INT: dict[Polarity, int] = {
    Polarity.NEG: -1,
    Polarity.ZERO: 0,
    Polarity.POS: 1,
}


def _require_nat(value: int, name: str) -> None:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise ValueError(f"{name} doit être un entier naturel (Nat >= 0), reçu {value!r}.")


@dataclass(frozen=True)
class SalientDiscrepancy:
    """Écart de prédiction saillant muni de l'invariant d'hystérésis.

    Invariant : ``resorption_threshold <= sensory_threshold``.
    """

    magnitude: int = 0
    sensory_threshold: int = 1
    resorption_threshold: int = 1

    def __post_init__(self) -> None:
        _require_nat(self.magnitude, "magnitude")
        _require_nat(self.sensory_threshold, "sensory_threshold")
        _require_nat(self.resorption_threshold, "resorption_threshold")
        if self.resorption_threshold > self.sensory_threshold:
            raise ValueError(
                "Invariant d'hystérésis violé : resorption_threshold "
                f"({self.resorption_threshold}) > sensory_threshold ({self.sensory_threshold})."
            )

    def is_sensorily_salient(self) -> bool:
        """Vérifie si l'écart franchit le seuil de saillance sensorielle."""
        return self.sensory_threshold <= self.magnitude

    def is_in_remanence_window(self) -> bool:
        """Vérifie si l'écart demeure dans la fenêtre de rémanence temporaire."""
        return self.resorption_threshold <= self.magnitude < self.sensory_threshold


@dataclass(frozen=True)
class PerceptiveInterface:
    """Interface Perceptive évaluant le gradient de Contrôle (C)."""

    controle_gradient: Polarity = Polarity.NEG


@dataclass(frozen=True)
class SubjectiveInterface:
    """Interface Subjective évaluant le gradient d'Attente (A) et la suspension."""

    attente_gradient: Polarity = Polarity.NEG
    descending_suspension: bool = False


@dataclass(frozen=True)
class AttentionalInterface:
    """Interface Attentionnelle (précision globale et poids relatifs ``(pi_A, pi_C)``)."""

    allocated_precision: int = 0
    engagement_threshold: int = 0
    persistence_depth: int = 0
    precision_a: int = 1
    precision_c: int = 1

    def __post_init__(self) -> None:
        _require_nat(self.allocated_precision, "allocated_precision")
        _require_nat(self.engagement_threshold, "engagement_threshold")
        _require_nat(self.persistence_depth, "persistence_depth")
        _require_nat(self.precision_a, "precision_a")
        _require_nat(self.precision_c, "precision_c")

    def is_engaged(self) -> bool:
        """Vérifie si la précision allouée franchit le seuil d'engagement attentionnel."""
        return self.engagement_threshold <= self.allocated_precision


class EngineInterface(str, Enum):
    """Les trois interfaces fonctionnelles composant le Moteur prédictif."""

    PERCEPTIVE = "perceptive"
    SUBJECTIVE = "subjective"
    ATTENTIONAL = "attentional"


class InferentialOperation(str, Enum):
    """Les quatre opérations inférentielles de la boucle récursive."""

    ASCENDING_SENSORY = "ascendingSensory"
    ACTION_IMPLEMENTATION = "actionImplementation"
    CONTEXTUAL_GENERATIVE = "contextualGenerative"
    INTEGRATIVE_WEIGHTING = "integrativeWeighting"

    def carrier_interface(self) -> EngineInterface:
        """Associe chaque opération inférentielle à son interface porteuse."""
        return _OPERATION_CARRIER[self]


_OPERATION_CARRIER: dict[InferentialOperation, EngineInterface] = {
    InferentialOperation.ASCENDING_SENSORY: EngineInterface.PERCEPTIVE,
    InferentialOperation.ACTION_IMPLEMENTATION: EngineInterface.PERCEPTIVE,
    InferentialOperation.CONTEXTUAL_GENERATIVE: EngineInterface.SUBJECTIVE,
    InferentialOperation.INTEGRATIVE_WEIGHTING: EngineInterface.ATTENTIONAL,
}


@dataclass(frozen=True)
class EngineCoupling:
    """Couplage discret des gradients d'Attente (A) et de Contrôle (C)."""

    attente: Polarity = Polarity.NEG
    controle: Polarity = Polarity.NEG

    def is_global_neutrality(self) -> bool:
        """Vrai ssi ``(A0, C0)`` (neutralité globale du Point de Veille)."""
        return not self.attente.is_engaged() and not self.controle.is_engaged()

    def is_single_engaged(self) -> bool:
        """Vrai ssi exactement une des deux dimensions est engagée (régime axial)."""
        a_eng = self.attente.is_engaged()
        c_eng = self.controle.is_engaged()
        return (a_eng and not c_eng) or (not a_eng and c_eng)

    def is_dual_engaged(self) -> bool:
        """Vrai ssi les deux dimensions A et C sont tranchées simultanément."""
        return self.attente.is_engaged() and self.controle.is_engaged()

    def invert(self) -> EngineCoupling:
        """Inverse formellement les deux polarités du couplage."""
        return EngineCoupling(attente=self.attente.invert(), controle=self.controle.invert())

    def regime_name(self) -> str:
        """Retourne l'unique régime fonctionnel de la trichotomie."""
        if self.is_global_neutrality():
            return "global_neutrality"
        if self.is_single_engaged():
            return "single_engaged"
        return "dual_engaged"


ALL_COUPLINGS: tuple[EngineCoupling, ...] = (
    EngineCoupling(Polarity.ZERO, Polarity.ZERO),
    EngineCoupling(Polarity.POS, Polarity.ZERO),
    EngineCoupling(Polarity.NEG, Polarity.ZERO),
    EngineCoupling(Polarity.ZERO, Polarity.POS),
    EngineCoupling(Polarity.ZERO, Polarity.NEG),
    EngineCoupling(Polarity.POS, Polarity.POS),
    EngineCoupling(Polarity.POS, Polarity.NEG),
    EngineCoupling(Polarity.NEG, Polarity.POS),
    EngineCoupling(Polarity.NEG, Polarity.NEG),
)


@dataclass(frozen=True)
class PredictiveEngineState:
    """État global du Moteur prédictif réunissant écart et trois interfaces."""

    discrepancy: SalientDiscrepancy = field(default_factory=SalientDiscrepancy)
    perceptive: PerceptiveInterface = field(default_factory=PerceptiveInterface)
    subjective: SubjectiveInterface = field(default_factory=SubjectiveInterface)
    attentional: AttentionalInterface = field(default_factory=AttentionalInterface)

    def current_coupling(self) -> EngineCoupling:
        """Extrait le couplage ``(A, C)`` courant."""
        return EngineCoupling(
            attente=self.subjective.attente_gradient,
            controle=self.perceptive.controle_gradient,
        )

    def feedback_update(
        self,
        new_a: Polarity,
        new_c: Polarity,
        new_precision: int,
    ) -> PredictiveEngineState:
        """Réinjecte ``(newA, newC)`` et la précision globale ``newPrecision``."""
        _require_nat(new_precision, "new_precision")
        return replace(
            self,
            subjective=replace(self.subjective, attente_gradient=new_a),
            perceptive=replace(self.perceptive, controle_gradient=new_c),
            attentional=replace(self.attentional, allocated_precision=new_precision),
        )

    def feedback_update_weighted(
        self,
        new_a: Polarity,
        new_c: Polarity,
        new_precision: int,
        new_precision_a: int,
        new_precision_c: int,
    ) -> PredictiveEngineState:
        """Réinjecte ``(newA, newC, newPrecision, newPrecisionA, newPrecisionC)``."""
        _require_nat(new_precision, "new_precision")
        _require_nat(new_precision_a, "new_precision_a")
        _require_nat(new_precision_c, "new_precision_c")
        return replace(
            self,
            subjective=replace(self.subjective, attente_gradient=new_a),
            perceptive=replace(self.perceptive, controle_gradient=new_c),
            attentional=replace(
                self.attentional,
                allocated_precision=new_precision,
                precision_a=new_precision_a,
                precision_c=new_precision_c,
            ),
        )


def engine_step(s: PredictiveEngineState) -> PredictiveEngineState:
    """Opérateur de transition séquentielle d'un pas du Moteur prédictif (R5)."""
    c = s.current_coupling()
    if not s.discrepancy.is_sensorily_salient():
        if s.discrepancy.is_in_remanence_window():
            return s
        return replace(
            s,
            perceptive=PerceptiveInterface(controle_gradient=Polarity.ZERO),
            subjective=SubjectiveInterface(
                attente_gradient=Polarity.ZERO,
                descending_suspension=False,
            ),
            attentional=replace(
                s.attentional,
                allocated_precision=0,
                persistence_depth=0,
            ),
        )
    if c.is_global_neutrality():
        return replace(s, perceptive=PerceptiveInterface(controle_gradient=Polarity.POS))
    if not s.subjective.descending_suspension and not s.attentional.is_engaged():
        return replace(
            s,
            subjective=replace(s.subjective, descending_suspension=True),
        )
    if not s.attentional.is_engaged():
        return replace(
            s,
            attentional=replace(
                s.attentional,
                allocated_precision=s.attentional.engagement_threshold,
            ),
        )
    return s


# ---------------------------------------------------------------------------
# Phase 2 : Paramétrage θ, sondes EMA à double seuil, vraisemblance A et G(π)
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class AgentParameters:
    """Vecteur complet de paramètres de l'agent d'inférence active CARTOGRAFFECT.

    Contient le vecteur théorique ``θ = {τ_A, τ_C, λ, α_0, γ_α, η_diss, β_X, β_Y}``
    ainsi que les hyperparamètres numériques d'inférence et d'apprentissage.
    """

    tau_a: float = 0.25
    tau_c: float = 0.25
    lambda_weight: float = 0.50
    alpha_0: float = 1.0
    gamma_alpha: float = 0.50
    eta_diss: float = 0.25
    beta_x: float = 2.0
    beta_y: float = 1.0

    # Hyperparamètres de seuil / précision et d'apprentissage POMDP
    salience_slope: float = 12.0
    likelihood_floor: float = 0.01
    deepen_precision_threshold: float = 0.55
    resorption_threshold: float = 0.15
    ema_response_noise: float = 0.0
    task_gamma: float = 4.0
    affect_gamma: float = 1.0
    rule_volatility_prior: float = 0.15
    ctrl_volatility_prior: float = 0.05
    lr_pa: float = 1.0
    lr_pb: float = 1.0
    enforce_theoretical_constraints: bool = True

    def __post_init__(self) -> None:
        numeric_fields = (
            "tau_a",
            "tau_c",
            "lambda_weight",
            "alpha_0",
            "gamma_alpha",
            "eta_diss",
            "beta_x",
            "beta_y",
            "salience_slope",
            "likelihood_floor",
            "deepen_precision_threshold",
            "resorption_threshold",
            "ema_response_noise",
            "task_gamma",
            "affect_gamma",
            "rule_volatility_prior",
            "ctrl_volatility_prior",
            "lr_pa",
            "lr_pb",
        )
        for fname in numeric_fields:
            val = float(getattr(self, fname))
            if not math.isfinite(val):
                raise ValueError(f"{fname} doit être fini (reçu {val})")

        if self.tau_a <= 0.0 or self.tau_c <= 0.0:
            raise ValueError("Les seuils τ_A et τ_C doivent être strictement positifs")
        if not (0.0 <= self.lambda_weight <= 1.0):
            raise ValueError(
                f"lambda_weight doit appartenir à [0, 1] (reçu {self.lambda_weight})"
            )
        if self.alpha_0 <= 0.0:
            raise ValueError(f"alpha_0 doit être > 0 (reçu {self.alpha_0})")
        if self.gamma_alpha < 0.0:
            raise ValueError(f"gamma_alpha doit être >= 0 (reçu {self.gamma_alpha})")
        if not (0.0 < self.eta_diss <= 1.0):
            raise ValueError(
                f"eta_diss doit appartenir à ]0, 1] (reçu {self.eta_diss})"
            )
        if self.beta_x <= 0.0 or self.beta_y <= 0.0:
            raise ValueError("β_X et β_Y doivent être strictement positifs")
        if self.enforce_theoretical_constraints and self.beta_x <= self.beta_y:
            raise ValueError(
                "Contrainte théorique violée : β_X (épistémique) doit être "
                f"strictement supérieur à β_Y (pragmatique) "
                f"(reçu β_X={self.beta_x}, β_Y={self.beta_y})"
            )
        if self.salience_slope <= 0.0:
            raise ValueError("salience_slope doit être > 0")
        if not (0.0 < self.likelihood_floor < 0.2):
            raise ValueError("likelihood_floor doit appartenir à ]0, 0.2[")
        if self.deepen_precision_threshold < 0.0 or self.resorption_threshold < 0.0:
            raise ValueError("Les seuils d'approfondissement/résorption doivent être >= 0")
        if not (0.0 <= self.ema_response_noise < 0.5):
            raise ValueError("ema_response_noise doit être dans [0, 0.5[")
        if not (0.0 <= self.rule_volatility_prior <= 0.5):
            raise ValueError("rule_volatility_prior doit être dans [0, 0.5]")
        if not (0.0 <= self.ctrl_volatility_prior <= 0.5):
            raise ValueError("ctrl_volatility_prior doit être dans [0, 0.5]")

    def dirichlet_concentration(self, z: int) -> float:
        """Retourne ``α_z = α_0 * exp(γ_α * z)`` (Smith et al., 2019)."""
        if z < 0:
            raise ValueError(f"La strate Z doit être >= 0 (reçu {z})")
        return float(self.alpha_0 * math.exp(self.gamma_alpha * z))

    def theta_dict(self) -> dict[str, float]:
        """Exporte le dictionnaire canonique des 8 paramètres θ."""
        return {
            "tau_A": float(self.tau_a),
            "tau_C": float(self.tau_c),
            "lambda": float(self.lambda_weight),
            "alpha_0": float(self.alpha_0),
            "gamma_alpha": float(self.gamma_alpha),
            "eta_diss": float(self.eta_diss),
            "beta_X": float(self.beta_x),
            "beta_Y": float(self.beta_y),
        }


def discretize_gradients(
    grad_a: float,
    grad_c: float,
    tau_a: float,
    tau_c: float,
) -> tuple[Polarity, Polarity]:
    """Discrétise deux gradients continus via les seuils ``τ_A`` et ``τ_C``."""
    if tau_a <= 0.0 or tau_c <= 0.0:
        raise ValueError("τ_A et τ_C doivent être > 0")
    pol_a = (
        Polarity.ZERO
        if abs(grad_a) <= tau_a
        else (Polarity.POS if grad_a > 0.0 else Polarity.NEG)
    )
    pol_c = (
        Polarity.ZERO
        if abs(grad_c) <= tau_c
        else (Polarity.POS if grad_c > 0.0 else Polarity.NEG)
    )
    return pol_a, pol_c


@dataclass(frozen=True)
class EMAObservation:
    """Sonde écologique momentanée (EMA) en deux temps + persistance ordinale.

    Modalités encodées pour la matrice de vraisemblance ``A`` (3 modalités non redondantes) :
        - ``obs_a`` in ``{0: filtré, 1: +1, 2: -1}`` (Interface Subjective / Attente) ;
        - ``obs_c`` in ``{0: filtré, 1: +1, 2: -1}`` (Interface Perceptive / Contrôle) ;
        - ``persistence_level`` in ``{0: basal, 1: réactif, 2: réflexif, 3: profond}``.
    """

    filter_a: int
    bipolar_a: int | None
    filter_c: int
    bipolar_c: int | None
    persistence_level: int = 0

    def __post_init__(self) -> None:
        if self.filter_a not in (0, 1) or self.filter_c not in (0, 1):
            raise ValueError("filter_a et filter_c doivent valoir 0 ou 1")
        if self.filter_a == 0 and self.bipolar_a is not None:
            raise ValueError("bipolar_a doit être None lorsque filter_a == 0")
        if self.filter_a == 1 and self.bipolar_a not in (-1, 1):
            raise ValueError("bipolar_a doit valoir -1 ou +1 lorsque filter_a == 1")
        if self.filter_c == 0 and self.bipolar_c is not None:
            raise ValueError("bipolar_c doit être None lorsque filter_c == 0")
        if self.filter_c == 1 and self.bipolar_c not in (-1, 1):
            raise ValueError("bipolar_c doit valoir -1 ou +1 lorsque filter_c == 1")
        if self.persistence_level not in (0, 1, 2, 3):
            raise ValueError("persistence_level doit appartenir à {0, 1, 2, 3}")

    @property
    def modality_indices(self) -> tuple[int, int, int]:
        """Convertit la sonde en 3 indices discrets ``(obs_A, obs_C, persistence_level)``."""
        b_map = {None: 0, 1: 1, -1: 2}
        return (
            b_map[self.bipolar_a],
            b_map[self.bipolar_c],
            int(self.persistence_level),
        )


class TwoStageEMAGenerator:
    """Générateur stochastique de sondes EMA en deux temps paramétré par ``τ_A, τ_C``."""

    def __init__(
        self,
        params: AgentParameters,
        seed: int | None = 42,
        stochastic: bool = True,
    ) -> None:
        self.params = params
        self.stochastic = stochastic
        self._rng = np.random.default_rng(seed)

    @staticmethod
    def _sigmoid(x: float) -> float:
        x_clamped = max(-30.0, min(30.0, x))
        return 1.0 / (1.0 + math.exp(-x_clamped))

    def salience_probability(self, abs_grad: float, tau: float) -> float:
        """Probabilité logistique d'activation de l'item filtre binaire pour ``|grad|`` et ``τ``."""
        if abs_grad <= 1e-9:
            return 0.0
        return float(self._sigmoid(self.params.salience_slope * (abs_grad - tau)))

    def sample_from_gradients(
        self,
        grad_a: float,
        grad_c: float,
        persistence_level: int = 0,
    ) -> EMAObservation:
        """Échantillonne une sonde EMA à 2 temps à partir des gradients ``(∇A, ∇C)``."""
        fa = self._sample_single_filter(abs(grad_a), self.params.tau_a)
        fc = self._sample_single_filter(abs(grad_c), self.params.tau_c)
        ba = self._sample_bipolar(grad_a) if fa == 1 else None
        bc = self._sample_bipolar(grad_c) if fc == 1 else None
        return EMAObservation(
            filter_a=fa,
            bipolar_a=ba,
            filter_c=fc,
            bipolar_c=bc,
            persistence_level=int(persistence_level),
        )

    def sample_from_state(
        self,
        state_idx: int,
        likelihood_a: Sequence[np.ndarray],
    ) -> EMAObservation:
        """Échantillonne une sonde EMA à 3 modalités à partir d'un état ``s_t`` et ``A``."""
        p_a = np.asarray(likelihood_a[0][:, state_idx], dtype=np.float64)
        p_a = p_a / p_a.sum()
        oa = int(self._rng.choice(3, p=p_a)) if self.stochastic else int(np.argmax(p_a))
        fa = 0 if oa == 0 else 1
        ba: int | None = None if oa == 0 else (1 if oa == 1 else -1)

        p_c = np.asarray(likelihood_a[1][:, state_idx], dtype=np.float64)
        p_c = p_c / p_c.sum()
        oc = int(self._rng.choice(3, p=p_c)) if self.stochastic else int(np.argmax(p_c))
        fc = 0 if oc == 0 else 1
        bc: int | None = None if oc == 0 else (1 if oc == 1 else -1)

        p_p = np.asarray(likelihood_a[2][:, state_idx], dtype=np.float64)
        p_p = p_p / p_p.sum()
        pers = int(self._rng.choice(4, p=p_p)) if self.stochastic else int(np.argmax(p_p))

        return EMAObservation(
            filter_a=fa,
            bipolar_a=ba,
            filter_c=fc,
            bipolar_c=bc,
            persistence_level=pers,
        )

    def _sample_single_filter(self, abs_grad: float, tau: float) -> int:
        if not self.stochastic:
            return 1 if abs_grad > tau else 0
        p_act = self.salience_probability(abs_grad, tau)
        return int(self._rng.random() < p_act)

    def _sample_bipolar(self, grad: float) -> int:
        if not self.stochastic or self.params.ema_response_noise == 0.0:
            if grad > 0.0:
                return 1
            if grad < 0.0:
                return -1
            return 1 if self._rng.random() < 0.5 else -1
        dominant = 1 if grad >= 0.0 else -1
        if self._rng.random() < (1.0 - self.params.ema_response_noise):
            return dominant
        return -dominant


def _normalized_axis_intensity(coord: int, z: int) -> float:
    """Intensité normalisée d'une coordonnée ``X`` ou ``Y`` sur sa strate ``Z``."""
    if z <= 1 or coord == 0:
        return 0.0
    radius = max(1, 2 * z - 2)
    return float(abs(coord) / radius)


def _sigmoid_scalar(val: float) -> float:
    c = max(-30.0, min(30.0, val))
    return 1.0 / (1.0 + math.exp(-c))


_PERSISTENCE_LIKELIHOOD_BY_Z: dict[int, tuple[float, float, float, float]] = {
    0: (0.92, 0.06, 0.015, 0.005),
    1: (0.08, 0.84, 0.06, 0.02),
    2: (0.03, 0.82, 0.13, 0.02),
    3: (0.01, 0.22, 0.68, 0.09),
    4: (0.005, 0.06, 0.72, 0.215),
    5: (0.005, 0.02, 0.245, 0.73),
    6: (0.005, 0.01, 0.125, 0.86),
    7: (0.005, 0.005, 0.05, 0.94),
}


def build_likelihood_matrix_A(
    params: AgentParameters,
    entries: Sequence[object] | None = None,
) -> list[np.ndarray]:
    """Construit la matrice de vraisemblance ``A = P(o_t | s_t)`` à 3 modalités non redondantes.

    Retourne une liste de 3 tableaux ``float64`` normalisés par colonne sur les 176 états :
        - ``A[0]`` : forme ``(3, 176)`` — Attente ``{0=filtré, 1=+1, 2=-1}`` (seuil ``τ_A``) ;
        - ``A[1]`` : forme ``(3, 176)`` — Contrôle ``{0=filtré, 1=+1, 2=-1}`` (seuil ``τ_C``) ;
        - ``A[2]`` : forme ``(4, 176)`` — niveau de persistance/mobilisation ``{0, 1, 2, 3}``.
    """
    if entries is None:
        from .lexicon_176 import ALL_176_ENTRIES

        entries = ALL_176_ENTRIES

    num_states = len(entries)
    floor = params.likelihood_floor
    slope = params.salience_slope

    a_obs_a = np.zeros((3, num_states), dtype=np.float64)
    a_obs_c = np.zeros((3, num_states), dtype=np.float64)
    a_pers = np.zeros((4, num_states), dtype=np.float64)

    for idx, entry in enumerate(entries):
        pt = entry.point  # type: ignore[attr-defined]
        mx = _normalized_axis_intensity(pt.x, pt.z)
        my = _normalized_axis_intensity(pt.y, pt.z)

        # Modalité 0 : Attente (seuil τ_A sur Interface Subjective X)
        raw_pa = _sigmoid_scalar(slope * (mx - params.tau_a))
        if pt.z == 0:
            raw_pa = min(raw_pa, 0.03)
        p_sal_a = float(np.clip(raw_pa, floor, 1.0 - floor))
        p_gated_a = 1.0 - p_sal_a
        if pt.x > 0:
            p_pos_a = p_sal_a * (1.0 - floor)
            p_neg_a = p_sal_a * floor
        elif pt.x < 0:
            p_pos_a = p_sal_a * floor
            p_neg_a = p_sal_a * (1.0 - floor)
        else:
            p_pos_a = 0.5 * p_sal_a
            p_neg_a = 0.5 * p_sal_a
        col_a = np.array([p_gated_a, p_pos_a, p_neg_a], dtype=np.float64)
        col_a = np.maximum(col_a, floor * 0.25)
        a_obs_a[:, idx] = col_a / col_a.sum()

        # Modalité 1 : Contrôle (seuil τ_C sur Interface Perceptive Y)
        raw_pc = _sigmoid_scalar(slope * (my - params.tau_c))
        if pt.z == 0:
            raw_pc = min(raw_pc, 0.03)
        p_sal_c = float(np.clip(raw_pc, floor, 1.0 - floor))
        p_gated_c = 1.0 - p_sal_c
        if pt.y > 0:
            p_pos_c = p_sal_c * (1.0 - floor)
            p_neg_c = p_sal_c * floor
        elif pt.y < 0:
            p_pos_c = p_sal_c * floor
            p_neg_c = p_sal_c * (1.0 - floor)
        else:
            p_pos_c = 0.5 * p_sal_c
            p_neg_c = 0.5 * p_sal_c
        col_c = np.array([p_gated_c, p_pos_c, p_neg_c], dtype=np.float64)
        col_c = np.maximum(col_c, floor * 0.25)
        a_obs_c[:, idx] = col_c / col_c.sum()

        # Modalité 2 : Persistance ordinale indexée sur la strate Z
        p_vec = np.array(_PERSISTENCE_LIKELIHOOD_BY_Z[int(pt.z)], dtype=np.float64)
        a_pers[:, idx] = p_vec / p_vec.sum()

    return [a_obs_a, a_obs_c, a_pers]


def build_dirichlet_priors_pA(
    likelihood_a: Sequence[np.ndarray],
    params: AgentParameters,
    entries: Sequence[object] | None = None,
) -> list[np.ndarray]:
    """Construit les concentrations de Dirichlet ``pA`` croissantes en ``α_z = α_0 exp(γ_α z)``."""
    if entries is None:
        from .lexicon_176 import ALL_176_ENTRIES

        entries = ALL_176_ENTRIES

    alphas = np.array(
        [params.dirichlet_concentration(e.point.z) for e in entries],  # type: ignore[attr-defined]
        dtype=np.float64,
    )
    pa_list: list[np.ndarray] = []
    for a_m in likelihood_a:
        arr = np.asarray(a_m, dtype=np.float64)
        pa_list.append(arr * alphas[None, :])
    return pa_list


@dataclass(frozen=True)
class ExpectedFreeEnergyResult:
    """Décomposition exacte de l'énergie libre attendue ``G(π)`` par politique."""

    efe: np.ndarray
    neg_efe: np.ndarray
    epistemic_value: np.ndarray
    pragmatic_value: np.ndarray
    param_info_gain: np.ndarray
    policy_posterior: np.ndarray


@partial(jax.jit, static_argnums=(7, 8))
def _jit_efe_components(
    qs_j: list[jax.Array],
    a_j: list[jax.Array],
    b_j: list[jax.Array],
    c_j: list[jax.Array],
    pa_j: list[jax.Array] | None,
    pb_j: list[jax.Array] | None,
    policies_j: jax.Array,
    a_deps: tuple[tuple[int, ...], ...],
    b_deps: tuple[tuple[int, ...], ...],
) -> tuple[jax.Array, jax.Array, jax.Array]:
    """Noyau JIT vectorisé sur les politiques calculant (epistemic, pragmatic, param_ig)."""
    a_deps_l = [list(x) for x in a_deps]
    b_deps_l = [list(x) for x in b_deps]

    def single_policy(policy_i: jax.Array) -> tuple[jax.Array, jax.Array, jax.Array]:
        def scan_step(
            carry: tuple[list[jax.Array], jax.Array, jax.Array, jax.Array],
            t: jax.Array,
        ) -> tuple[tuple[list[jax.Array], jax.Array, jax.Array, jax.Array], None]:
            qs_curr, ep_acc, pr_acc, pm_acc = carry
            qs_next = pymdp_control.compute_expected_state(
                qs_curr, b_j, policy_i[t], b_deps_l
            )
            qo = pymdp_control.compute_expected_obs(qs_next, a_j, a_deps_l)
            ig = pymdp_control.compute_info_gain(qs_next, qo, a_j, a_deps_l)
            ut = pymdp_control.compute_expected_utility(qo, c_j, t)
            pig = jnp.asarray(0.0, dtype=jnp.float32)
            if pa_j is not None:
                pig = pig - pymdp_control.calc_negative_pA_info_gain(
                    pa_j, qo, qs_next, a_deps_l
                )
            if pb_j is not None:
                pig = pig - pymdp_control.calc_negative_pB_info_gain(
                    pb_j, qs_next, qs_curr, b_deps_l, policy_i[t]
                )
            return (qs_next, ep_acc + ig, pr_acc + ut, pm_acc + pig), None

        init_carry = (
            qs_j,
            jnp.asarray(0.0, dtype=jnp.float32),
            jnp.asarray(0.0, dtype=jnp.float32),
            jnp.asarray(0.0, dtype=jnp.float32),
        )
        (_, ep_sum, pr_sum, pm_sum), _ = jax.lax.scan(
            scan_step, init_carry, jnp.arange(policy_i.shape[0])
        )
        return ep_sum + pm_sum, pr_sum, pm_sum

    return jax.vmap(single_policy)(policies_j)


def compute_expected_free_energy(
    qs_init: Sequence[jax.Array | np.ndarray],
    likelihood_a: Sequence[jax.Array | np.ndarray],
    transition_b: Sequence[jax.Array | np.ndarray],
    preferences_c: Sequence[jax.Array | np.ndarray],
    habits_e: jax.Array | np.ndarray,
    params: AgentParameters,
    *,
    num_controls: Sequence[int] | None = None,
    policies: jax.Array | np.ndarray | None = None,
    a_dependencies: list[list[int]] | None = None,
    b_dependencies: list[list[int]] | None = None,
    p_a: Sequence[jax.Array | np.ndarray] | None = None,
    p_b: Sequence[jax.Array | np.ndarray] | None = None,
    gamma: float | None = None,
) -> ExpectedFreeEnergyResult:
    """Calcule ``G(π) = -(β_X * Valeur_Épistémique(π) + β_Y * Valeur_Pragmatique(π))``.

    S'appuie sur les primitives exactes de ``pymdp.control`` vectorisées sous JAX.
    """
    qs_j = [jnp.asarray(q, dtype=jnp.float32).reshape(-1) for q in qs_init]
    a_j = [jnp.asarray(a, dtype=jnp.float32) for a in likelihood_a]
    b_j = [jnp.asarray(b, dtype=jnp.float32) for b in transition_b]
    c_j = [jnp.asarray(c, dtype=jnp.float32) for c in preferences_c]
    e_j = jnp.asarray(habits_e, dtype=jnp.float32)
    pa_j = [jnp.asarray(x, dtype=jnp.float32) for x in p_a] if p_a is not None else None
    pb_j = [jnp.asarray(x, dtype=jnp.float32) for x in p_b] if p_b is not None else None

    n_factors = len(qs_j)
    if a_dependencies is None:
        a_dependencies = [list(range(n_factors)) for _ in a_j]
    if b_dependencies is None:
        b_dependencies = [[f] for f in range(n_factors)]

    if policies is None:
        if num_controls is None:
            num_controls = [b.shape[-1] for b in b_j]
        n_states = [q.shape[-1] for q in qs_j]
        control_fac_idx = [f for f, nc in enumerate(num_controls) if nc > 1]
        pol_list = pymdp_control.construct_policies(
            n_states, list(num_controls), policy_len=1, control_fac_idx=control_fac_idx
        )
        policies_j = jnp.asarray(pol_list, dtype=jnp.int32)
    else:
        policies_j = jnp.asarray(policies, dtype=jnp.int32)

    a_deps_t = tuple(tuple(d) for d in a_dependencies)
    b_deps_t = tuple(tuple(d) for d in b_dependencies)

    ep_j, pr_j, pm_j = _jit_efe_components(
        qs_j, a_j, b_j, c_j, pa_j, pb_j, policies_j, a_deps_t, b_deps_t
    )
    ep_arr = np.asarray(ep_j, dtype=np.float64)
    pr_arr = np.asarray(pr_j, dtype=np.float64)
    pm_arr = np.asarray(pm_j, dtype=np.float64)

    beta_x = float(params.beta_x)
    beta_y = float(params.beta_y)
    gamma_eff = float(params.affect_gamma if gamma is None else gamma)

    neg_efe = beta_x * ep_arr + beta_y * pr_arr
    efe = -neg_efe
    e_safe = np.maximum(np.asarray(e_j, dtype=np.float64), 1e-16)
    logits = gamma_eff * neg_efe + np.log(e_safe)
    logits = logits - np.max(logits)
    exp_logits = np.exp(logits)
    q_pi = exp_logits / np.sum(exp_logits)

    return ExpectedFreeEnergyResult(
        efe=efe,
        neg_efe=neg_efe,
        epistemic_value=ep_arr,
        pragmatic_value=pr_arr,
        param_info_gain=pm_arr,
        policy_posterior=q_pi,
    )


@dataclass(frozen=True)
class TaskStepSignals:
    """Signaux computationnels extraits par ``TaskInferenceEngine`` à l'essai ``t``."""

    trial_index: int
    action: BanditAction
    grad_a: float
    grad_c: float
    polarity_a: Polarity
    polarity_c: Polarity
    discrepancy_magnitude: float
    attentional_precision: float
    bayesian_surprise: float
    epistemic_value: np.ndarray
    pragmatic_value: np.ndarray
    efe: np.ndarray
    q_pi: np.ndarray
    q_rule: np.ndarray
    q_ctrl: np.ndarray
    persistence_level: int = 0


@eqx.filter_jit
def _jit_task_select_step(
    agent: Agent,
    obs_pre: list[jax.Array],
    empirical_prior: list[jax.Array],
    batched_key: jax.Array,
    a_j: list[jax.Array],
    b_j: list[jax.Array],
    c_unit_j: list[jax.Array],
    policies_j: jax.Array,
) -> tuple[list[jax.Array], jax.Array, jax.Array, jax.Array, jax.Array]:
    qs_pre = agent.infer_states(obs_pre, empirical_prior)
    q_pi, _ = agent.infer_policies(qs_pre)
    qs_latest = [q[0, -1, :] for q in qs_pre]
    ep_j, pr_j, _ = _jit_efe_components(
        qs_latest,
        a_j,
        b_j,
        c_unit_j,
        None,
        None,
        policies_j,
        ((0, 2), (0, 1, 2)),
        ((0,), (1,), (2,)),
    )
    act_arr = agent.sample_action(q_pi, rng_key=batched_key)
    return qs_pre, q_pi, act_arr, ep_j, pr_j


@eqx.filter_jit
def _jit_task_infer_only(
    agent: Agent,
    obs_cat: list[jax.Array],
    prior: list[jax.Array],
) -> list[jax.Array]:
    return agent.infer_states(obs_cat, prior)


@eqx.filter_jit
def _jit_task_observe_step(
    agent: Agent,
    obs_post: list[jax.Array],
    prior_post: list[jax.Array],
    act_tensor: jax.Array,
) -> tuple[list[jax.Array], list[jax.Array]]:
    qs_post = agent.infer_states(obs_post, prior_post)
    next_prior = agent.update_empirical_prior(act_tensor, qs_post)
    return qs_post, next_prior


class TaskInferenceEngine:
    """Agent POMDP ``pymdp`` inférant la règle latente et la contrôlabilité de la tâche.

    Facteurs cachés orthogonaux à l'affectivité :
        - Factor 0 : règle latente ``{RULE_A=0, RULE_B=1}`` ;
        - Factor 1 : contrôlabilité objective ``{HIGH_CTRL=0, LOW_CTRL=1}`` ;
        - Factor 2 : état de choix ``{CHOICE_A=0, CHOICE_B=1, PROBE_CUE=2}``.
    """

    def __init__(self, params: AgentParameters, seed: int | None = 42) -> None:
        self.params = params
        self._rng_key = jax.random.PRNGKey(0 if seed is None else int(seed))
        self._a, self._b, self._c_unit, self._d, self._e = self._build_model()
        self._a_j = [jnp.asarray(x, dtype=jnp.float32) for x in self._a]
        self._b_j = [jnp.asarray(x, dtype=jnp.float32) for x in self._b]
        self._c_unit_j = [jnp.asarray(x, dtype=jnp.float32) for x in self._c_unit]
        self._a_deps = [[0, 2], [0, 1, 2]]
        self._b_deps = [[0], [1], [2]]
        self._policies_j = jnp.asarray(
            pymdp_control.construct_policies(
                [2, 2, 3], [1, 1, 3], policy_len=1, control_fac_idx=[2]
            ),
            dtype=jnp.int32,
        )
        self._agent = self._instantiate_pymdp_agent()
        self._uniform_obs3 = jnp.array([[1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0]], dtype=jnp.float32)

        self._qs: list[jax.Array] = [
            jnp.asarray(d[None, None, :], dtype=jnp.float32) for d in self._d
        ]
        self._empirical_prior: list[jax.Array] = [
            jnp.asarray(d[None, :], dtype=jnp.float32) for d in self._d
        ]
        self._qs_pre: list[jax.Array] | None = None
        self._prior_rule_before_trial: jax.Array = jnp.asarray(
            self._d[0][None, :], dtype=jnp.float32
        )
        self._u_ep: float = 0.43
        self._grad_a: float = 0.0
        self._grad_c: float = 0.0
        self._persistence_load: float = 0.0
        self._seen_non_probe_neutral_streak: int = 0
        self._last_efe_decomp: ExpectedFreeEnergyResult | None = None

    def _build_model(
        self,
    ) -> tuple[
        list[np.ndarray],
        list[np.ndarray],
        list[np.ndarray],
        list[np.ndarray],
        np.ndarray,
    ]:
        # A[0] : observation de l'indice (3: RULE_A, RULE_B, AMBIGUOUS) x rule(2) x choice(3)
        a_cue = np.zeros((3, 2, 3), dtype=np.float64)
        for ch in range(3):
            p_true = 0.90 if ch == 2 else 0.72
            p_amb = 0.08 if ch == 2 else 0.18
            p_false = 1.0 - p_true - p_amb
            for rule in range(2):
                a_cue[rule, rule, ch] = p_true
                a_cue[2, rule, ch] = p_amb
                a_cue[1 - rule, rule, ch] = p_false
        a_cue = a_cue / a_cue.sum(axis=0, keepdims=True)

        # A[1] : observation d'issue (3: NEUTRAL=0, POS=1, NEG=2) x rule(2) x ctrl(2) x choice(3)
        a_out = np.zeros((3, 2, 2, 3), dtype=np.float64)
        for rule in range(2):
            for ctrl in range(2):
                for ch in range(3):
                    if ch == 2:
                        # PROBE_CUE -> issue neutre presque certaine
                        a_out[:, rule, ctrl, ch] = [0.96, 0.02, 0.02]
                    else:
                        matched = ch == rule
                        if ctrl == 0:  # HIGH_CTRL
                            if matched:
                                a_out[:, rule, ctrl, ch] = [0.05, 0.87, 0.08]
                            else:
                                a_out[:, rule, ctrl, ch] = [0.05, 0.08, 0.87]
                        else:  # LOW_CTRL
                            if matched:
                                a_out[:, rule, ctrl, ch] = [0.05, 0.50, 0.45]
                            else:
                                a_out[:, rule, ctrl, ch] = [0.05, 0.45, 0.50]
        a_out = a_out / a_out.sum(axis=0, keepdims=True)

        # B[0] : transition passive règle latente avec volatilité a priori
        vr = self.params.rule_volatility_prior
        b_rule = np.array(
            [[[1.0 - vr], [vr]], [[vr], [1.0 - vr]]], dtype=np.float64
        )
        # B[1] : transition lente contrôlabilité
        vc = self.params.ctrl_volatility_prior
        b_ctrl = np.array(
            [[[1.0 - vc], [vc]], [[vc], [1.0 - vc]]], dtype=np.float64
        )
        # B[2] : contrôle déterministe vers CHOICE_A (0), CHOICE_B (1), PROBE_CUE (2)
        b_choice = np.zeros((3, 3, 3), dtype=np.float64)
        for act in range(3):
            b_choice[act, :, act] = 1.0

        c_unit = [
            np.zeros(3, dtype=np.float64),
            np.array([0.0, 1.0, -1.0], dtype=np.float64),
        ]
        d = [
            np.array([0.5, 0.5], dtype=np.float64),
            np.array([0.5, 0.5], dtype=np.float64),
            np.array([0.5, 0.5, 0.0], dtype=np.float64),
        ]
        e = np.array([0.4, 0.4, 0.2], dtype=np.float64)
        e = e / e.sum()
        return [a_cue, a_out], [b_rule, b_ctrl, b_choice], c_unit, d, e

    def _instantiate_pymdp_agent(self) -> Agent:
        # Identité exacte : γ_eff * (I + (β_Y/β_X) * U) == γ_base * (β_X*I + β_Y*U)
        ratio = self.params.beta_y / self.params.beta_x
        c_scaled = [
            jnp.asarray(self._c_unit[0] * ratio, dtype=jnp.float32),
            jnp.asarray(self._c_unit[1] * ratio, dtype=jnp.float32),
        ]
        return Agent(
            A=[jnp.asarray(x, dtype=jnp.float32) for x in self._a],
            B=[jnp.asarray(x, dtype=jnp.float32) for x in self._b],
            C=c_scaled,
            D=[jnp.asarray(x, dtype=jnp.float32) for x in self._d],
            E=jnp.asarray(self._e, dtype=jnp.float32),
            A_dependencies=self._a_deps,
            B_dependencies=self._b_deps,
            num_controls=[1, 1, 3],
            control_fac_idx=[2],
            policy_len=1,
            gamma=float(self.params.task_gamma * self.params.beta_x),
            alpha=8.0,
            use_utility=True,
            use_states_info_gain=True,
            use_param_info_gain=False,
            categorical_obs=True,
            action_selection="stochastic",
            inference_algo="fpi",
            num_iter=8,
            batch_size=1,
            learn_A=False,
            learn_B=False,
        )

    def reset(self) -> None:
        self._qs = [
            jnp.asarray(d[None, None, :], dtype=jnp.float32) for d in self._d
        ]
        self._empirical_prior = [
            jnp.asarray(d[None, :], dtype=jnp.float32) for d in self._d
        ]
        self._qs_pre = None
        self._prior_rule_before_trial = jnp.asarray(
            self._d[0][None, :], dtype=jnp.float32
        )
        self._u_ep = 0.43
        self._grad_a = 0.0
        self._grad_c = 0.0
        self._persistence_load = 0.0
        self._seen_non_probe_neutral_streak = 0
        self._last_efe_decomp = None

    @staticmethod
    def _outcome_to_obs_idx(outcome: OutcomeValence) -> int:
        if outcome == OutcomeValence.POSITIVE:
            return 1
        if outcome == OutcomeValence.NEGATIVE:
            return 2
        return 0

    def select_action(self, pre_obs: TrialObservation) -> BanditAction:
        """Met à jour la croyance sur l'indice courant (sans double-comptage) et choisit l'action."""
        payload = pre_obs.sensory_payload()
        cue_oh = jax.nn.one_hot(jnp.array([int(payload["cue"])], dtype=jnp.int32), 3)
        obs_pre = [cue_oh, self._uniform_obs3]

        self._rng_key, subkey = jax.random.split(self._rng_key)
        batched_key = jax.random.split(subkey, 1)

        self._prior_rule_before_trial = self._empirical_prior[0]
        qs_pre, q_pi, act_arr, ep_j, pr_j = _jit_task_select_step(
            self._agent,
            obs_pre,
            self._empirical_prior,
            batched_key,
            self._a_j,
            self._b_j,
            self._c_unit_j,
            self._policies_j,
        )
        self._qs_pre = qs_pre
        self._qs = qs_pre

        ep_arr = np.asarray(ep_j, dtype=np.float64)
        pr_arr = np.asarray(pr_j, dtype=np.float64)
        neg_efe = self.params.beta_x * ep_arr + self.params.beta_y * pr_arr
        self._last_efe_decomp = ExpectedFreeEnergyResult(
            efe=-neg_efe,
            neg_efe=neg_efe,
            epistemic_value=ep_arr,
            pragmatic_value=pr_arr,
            param_info_gain=np.zeros_like(ep_arr),
            policy_posterior=np.asarray(q_pi[0], dtype=np.float64),
        )

        return BanditAction(int(act_arr[0, 2]))

    def observe_outcome(
        self,
        obs: TrialObservation,
        action_taken: BanditAction,
    ) -> TaskStepSignals:
        """Intègre l'issue observée en une transition unique et extrait ``(∇A, ∇C)`` sans fuite."""
        payload = obs.sensory_payload()
        cue_sig = payload["cue"]
        out_val = payload["outcome"]
        out_idx = self._outcome_to_obs_idx(out_val)

        if self._qs_pre is None:
            cue_oh = jax.nn.one_hot(jnp.array([int(cue_sig)], dtype=jnp.int32), 3)
            self._prior_rule_before_trial = self._empirical_prior[0]
            self._qs_pre = _jit_task_infer_only(
                self._agent, [cue_oh, self._uniform_obs3], self._empirical_prior
            )

        act_oh = jax.nn.one_hot(jnp.array([int(action_taken)], dtype=jnp.int32), 3)
        prior_post = [
            self._qs_pre[0][:, -1, :],
            self._qs_pre[1][:, -1, :],
            act_oh,
        ]
        out_oh = jax.nn.one_hot(jnp.array([out_idx], dtype=jnp.int32), 3)
        obs_post = [self._uniform_obs3, out_oh]
        act_tensor = jnp.array([[0, 0, int(action_taken)]], dtype=jnp.int32)

        prior_rule = np.asarray(self._prior_rule_before_trial[0], dtype=np.float64)
        self._qs, self._empirical_prior = _jit_task_observe_step(
            self._agent, obs_post, prior_post, act_tensor
        )
        self._qs_pre = None

        q_rule = np.asarray(self._qs[0][0, -1, :], dtype=np.float64)
        q_ctrl = np.asarray(self._qs[1][0, -1, :], dtype=np.float64)
        q_rule = np.maximum(q_rule, 1e-12)
        q_ctrl = np.maximum(q_ctrl, 1e-12)
        q_rule /= q_rule.sum()
        q_ctrl /= q_ctrl.sum()

        # Surprise bayésienne de l'essai : KL(Q_post(rule) || P_pre_trial(rule))
        p_r = np.maximum(prior_rule, 1e-12)
        p_r /= p_r.sum()
        kl_rule = float(np.sum(q_rule * np.log(q_rule / p_r)))

        # Précision attentionnelle : 1 - entropie normalisée moyenne (rule, ctrl)
        h_rule = -float(np.sum(q_rule * np.log(q_rule))) / math.log(2.0)
        h_ctrl = -float(np.sum(q_ctrl * np.log(q_ctrl))) / math.log(2.0)
        precision = float(np.clip(1.0 - 0.5 * (h_rule + h_ctrl), 0.0, 1.0))

        # Détection purement sensorielle du calme (aucune lecture de is_remission / d_obj)
        is_ambig = 1.0 if cue_sig == CueSignal.AMBIGUOUS else 0.0
        if out_val != OutcomeValence.NEUTRAL:
            self._seen_non_probe_neutral_streak = 0
        elif action_taken != BanditAction.PROBE_CUE:
            self._seen_non_probe_neutral_streak += 1
        is_sensory_calm = (
            out_val == OutcomeValence.NEUTRAL
            and (
                action_taken != BanditAction.PROBE_CUE
                or self._seen_non_probe_neutral_streak >= 1
            )
        )

        decay = 1.0 - self.params.eta_diss
        if is_sensory_calm:
            self._u_ep = 0.78 * self._u_ep + 0.22 * 0.43
            self._grad_a *= decay
            self._grad_c *= decay
            self._persistence_load *= decay
            if abs(self._grad_a) < 0.015:
                self._grad_a = 0.0
            if abs(self._grad_c) < 0.015:
                self._grad_c = 0.0
            if self._persistence_load < 0.05:
                self._persistence_load = 0.0
            discrepancy = float(math.hypot(self._grad_a, self._grad_c))
        else:
            ep_inst = 0.90 * kl_rule + 0.55 * h_rule + 0.55 * is_ambig
            self._u_ep = 0.78 * self._u_ep + 0.22 * ep_inst
            raw_ga = float(np.clip(4.2 * (0.43 - self._u_ep), -1.0, 1.0))

            ctrl_high = float(q_ctrl[0])
            out_s = (
                0.45
                if out_val == OutcomeValence.POSITIVE
                else (-0.55 if out_val == OutcomeValence.NEGATIVE else 0.0)
            )
            raw_gc = float(np.clip(2.4 * (ctrl_high - 0.50) + out_s, -1.0, 1.0))

            z_est = int(round(min(7.0, max(0.0, 2.0 + self._persistence_load))))
            alpha_est = self.params.dirichlet_concentration(z_est)
            lr_g = float(np.clip(0.45 / (1.0 + 0.06 * alpha_est), 0.12, 0.45))

            self._grad_a = float(
                np.clip((1.0 - lr_g) * self._grad_a + lr_g * raw_ga, -1.2, 1.2)
            )
            self._grad_c = float(
                np.clip((1.0 - lr_g) * self._grad_c + lr_g * raw_gc, -1.2, 1.2)
            )

            seq_err = float(payload["sequence_failure_rate"])
            ev_score = payload["evaluative_score"]
            eval_bad = (
                (1.0 - float(ev_score))
                if (ev_score is not None and float(ev_score) < 0.70)
                else 0.0
            )
            aversive_drive = 0.0
            if out_val == OutcomeValence.NEGATIVE:
                aversive_drive += 0.55 + 0.65 * seq_err
            if kl_rule > 0.15:
                aversive_drive += min(0.85, 1.40 * kl_rule)
            if is_ambig > 0.5:
                aversive_drive += 0.35
            if eval_bad > 0.0:
                aversive_drive += 1.40 * eval_bad

            leak = 1.0 - 0.55 * self.params.eta_diss
            if aversive_drive > 0.0:
                self._persistence_load = min(
                    3.5, leak * self._persistence_load + 0.38 * aversive_drive
                )
            else:
                self._persistence_load = max(0.0, self._persistence_load * leak)

            discrepancy = float(
                np.clip(
                    0.55 * math.hypot(self._grad_a, self._grad_c)
                    + 0.20 * self._persistence_load,
                    0.0,
                    2.0,
                )
            )

        if self._persistence_load < 0.25:
            persistence_level = 0
        elif self._persistence_load < 1.10:
            persistence_level = 1
        elif self._persistence_load < 2.05:
            persistence_level = 2
        else:
            persistence_level = 3

        grad_a = float(self._grad_a)
        grad_c = float(self._grad_c)
        pol_a, pol_c = discretize_gradients(
            grad_a, grad_c, self.params.tau_a, self.params.tau_c
        )
        efe_res = self._last_efe_decomp
        if efe_res is None:
            ep_arr = np.zeros(3, dtype=np.float64)
            pr_arr = np.zeros(3, dtype=np.float64)
            efe_arr = np.zeros(3, dtype=np.float64)
            q_pi_arr = np.array(self._e, dtype=np.float64)
        else:
            ep_arr = efe_res.epistemic_value
            pr_arr = efe_res.pragmatic_value
            efe_arr = efe_res.efe
            q_pi_arr = efe_res.policy_posterior

        return TaskStepSignals(
            trial_index=obs.trial_index,
            action=action_taken,
            grad_a=grad_a,
            grad_c=grad_c,
            polarity_a=pol_a,
            polarity_c=pol_c,
            discrepancy_magnitude=float(discrepancy),
            attentional_precision=float(precision),
            bayesian_surprise=float(kl_rule),
            epistemic_value=ep_arr,
            pragmatic_value=pr_arr,
            efe=efe_arr,
            q_pi=q_pi_arr,
            q_rule=q_rule,
            q_ctrl=q_ctrl,
            persistence_level=persistence_level,
        )


__all__ = [
    "ALL_COUPLINGS",
    "AgentParameters",
    "AttentionalInterface",
    "EMAObservation",
    "EngineCoupling",
    "EngineInterface",
    "ExpectedFreeEnergyResult",
    "FunctionalRegime",
    "InferentialOperation",
    "PerceptiveInterface",
    "Polarity",
    "PredictiveEngineState",
    "SalientDiscrepancy",
    "SubjectiveInterface",
    "TaskInferenceEngine",
    "TaskStepSignals",
    "TwoStageEMAGenerator",
    "build_dirichlet_priors_pA",
    "build_likelihood_matrix_A",
    "compute_expected_free_energy",
    "discretize_gradients",
    "engine_step",
]
