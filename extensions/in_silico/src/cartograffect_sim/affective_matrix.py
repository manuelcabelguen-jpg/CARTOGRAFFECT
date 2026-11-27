"""Matrice affective CARTOGRAFFECT (isomorphe à `Cartograffect/AffectiveMatrix.lean`).

Implémente la transduction phénoménologique et les opérateurs d'antagonisme :
- Pôles vécus (`LivedExpectationPole`, `LivedControlPole`), régimes énergétiques
  (`EnergyRegime`), polarité hédonique lexicographique (`HedonicPolarity`, primauté de X)
  et profils d'activation (`PhenomenologicalActivation`) ;
- Les 8 prototypes de la première couronne ``Z = 2`` (`PrimaryCrownPrototype`) ;
- L'opérateur d'antagonisme involutif `antagonist_point` (symétrie centrale pour
  positions centrales/axiales/diagonales ; réflexion diagonale controlatérale
  pour les positions latérales `|X| != |Y|`) et sa forme unifiée hors axes ;
- Transferts unitaires intra-couronne (`transfer_unit_x_to_y`, `transfer_unit_y_to_x`) ;
- Paramétrisation des hypothèses de correspondance (`PhenomenologicalMapping`, R3)
  et évaluation complète `evaluate_matrix`.
"""

from __future__ import annotations

import math
from collections.abc import Callable, Sequence
from dataclasses import dataclass
from enum import Enum, IntEnum
from typing import TYPE_CHECKING

import equinox as eqx
import jax
import jax.numpy as jnp
import numpy as np
from pymdp.agent import Agent

from .core_affect import (
    CoreAffectPoint,
    CoreAffectState,
    dissipation_step,
    is_valid_core_affect,
)
from .generative_process import EnvStepResult, NonStationaryBanditEnv, TrialObservation
from .predictive_engine import (
    AgentParameters,
    EMAObservation,
    ExpectedFreeEnergyResult,
    TaskInferenceEngine,
    TaskStepSignals,
    TwoStageEMAGenerator,
    _jit_efe_components,
    build_dirichlet_priors_pA,
    build_likelihood_matrix_A,
    compute_expected_free_energy,
)

if TYPE_CHECKING:
    from .lexicon_176 import LexiconEntry


class LivedExpectationPole(str, Enum):
    """Traduction vécue du pôle computationnel sur l'Axe X (Attente)."""

    EPISTEMIC_CHARGE = "epistemicCharge"
    EPISTEMIC_NEUTRAL = "epistemicNeutral"
    EPISTEMIC_DISCHARGE = "epistemicDischarge"


class LivedControlPole(str, Enum):
    """Traduction vécue du pôle computationnel sur l'Axe Y (Contrôle)."""

    PRAGMATIC_CHARGE = "pragmaticCharge"
    PRAGMATIC_NEUTRAL = "pragmaticNeutral"
    PRAGMATIC_DISCHARGE = "pragmaticDischarge"


class EnergyRegime(str, Enum):
    """Régime énergétique et cinétique du couplage entre Attente (X) et Contrôle (Y)."""

    NEUTRAL_BASAL = "neutralBasal"
    AXIAL_PURE = "axialPure"
    POSITIVE_SYNERGY = "positiveSynergy"
    NEGATIVE_SYNERGY = "negativeSynergy"
    ERGOTROPIC_COMPENSATION = "ergotropicCompensation"
    TROPHOTROPIC_RELEASE = "trophotropicRelease"


def compute_energy_regime(x: int, y: int) -> EnergyRegime:
    """Calcul du régime énergétique à partir des coordonnées ``(X, Y)``."""
    if x == 0 and y == 0:
        return EnergyRegime.NEUTRAL_BASAL
    if x == 0 or y == 0:
        return EnergyRegime.AXIAL_PURE
    if x > 0 and y > 0:
        return EnergyRegime.POSITIVE_SYNERGY
    if x < 0 and y < 0:
        return EnergyRegime.NEGATIVE_SYNERGY
    if x < 0 and y > 0:
        return EnergyRegime.ERGOTROPIC_COMPENSATION
    return EnergyRegime.TROPHOTROPIC_RELEASE


class HedonicPolarity(str, Enum):
    """Polarité hédonique phénoménologique (Valence vécue)."""

    POSITIVE = "positive"
    NEGATIVE = "negative"
    NEUTRAL = "neutral"

    def invert(self) -> HedonicPolarity:
        """Inversion stricte de la polarité hédonique."""
        if self is HedonicPolarity.POSITIVE:
            return HedonicPolarity.NEGATIVE
        if self is HedonicPolarity.NEGATIVE:
            return HedonicPolarity.POSITIVE
        return HedonicPolarity.NEUTRAL


def compute_hedonic_polarity(x: int, y: int) -> HedonicPolarity:
    """Loi de primauté hédonique lexicographique de l'Axe X (puis Y si X == 0)."""
    if x > 0:
        return HedonicPolarity.POSITIVE
    if x < 0:
        return HedonicPolarity.NEGATIVE
    if y > 0:
        return HedonicPolarity.POSITIVE
    if y < 0:
        return HedonicPolarity.NEGATIVE
    return HedonicPolarity.NEUTRAL


compute_valence = compute_hedonic_polarity


class PhenomenologicalActivation(str, Enum):
    """Niveau d'activation qualifiant l'amplitude de mobilisation de la trajectoire."""

    BASAL_WAKEFULNESS = "basalWakefulness"
    ASCENDING_RUPTURE = "ascendingRupture"
    OPERATOR_SUSPENSION = "operatorSuspension"
    LOW_INHIBITION = "lowInhibition"
    EPISTEMIC_VIGILANCE = "epistemicVigilance"
    HIGH_MOBILIZATION = "highMobilization"


def transduce_expectation(x: int) -> LivedExpectationPole:
    """Transduction de la coordonnée X en pôle vécu d'Attente."""
    if x < 0:
        return LivedExpectationPole.EPISTEMIC_CHARGE
    if x > 0:
        return LivedExpectationPole.EPISTEMIC_DISCHARGE
    return LivedExpectationPole.EPISTEMIC_NEUTRAL


def transduce_control(y: int) -> LivedControlPole:
    """Transduction de la coordonnée Y en pôle vécu de Contrôle."""
    if y < 0:
        return LivedControlPole.PRAGMATIC_CHARGE
    if y > 0:
        return LivedControlPole.PRAGMATIC_DISCHARGE
    return LivedControlPole.PRAGMATIC_NEUTRAL


def compute_activation(p: CoreAffectPoint) -> PhenomenologicalActivation:
    """Calcul du profil d'activation phénoménologique depuis le Noyau."""
    if p.x == 0 and p.y == 0:
        if p.z == 0:
            return PhenomenologicalActivation.BASAL_WAKEFULNESS
        if p.z == 1:
            return PhenomenologicalActivation.ASCENDING_RUPTURE
        return PhenomenologicalActivation.OPERATOR_SUSPENSION
    if p.y > 0:
        return PhenomenologicalActivation.HIGH_MOBILIZATION
    if p.y < 0:
        return PhenomenologicalActivation.LOW_INHIBITION
    return PhenomenologicalActivation.EPISTEMIC_VIGILANCE


class PrimaryCrownPrototype(str, Enum):
    """Les huit prototypes affectifs de la première couronne (``Z = 2``)."""

    JOIE = "joie"
    TRISTESSE = "tristesse"
    PEUR = "peur"
    COURAGE = "courage"
    DESIR = "desir"
    DEGOUT = "degout"
    COLERE = "colere"
    CALME = "calme"

    def to_point(self) -> CoreAffectPoint:
        """Associe chaque prototype de la première couronne à ses coordonnées exactes."""
        return _PROTOTYPE_POINTS[self]


_PROTOTYPE_POINTS: dict[PrimaryCrownPrototype, CoreAffectPoint] = {
    PrimaryCrownPrototype.JOIE: CoreAffectPoint(0, 2, 2),
    PrimaryCrownPrototype.TRISTESSE: CoreAffectPoint(0, -2, 2),
    PrimaryCrownPrototype.PEUR: CoreAffectPoint(-2, 0, 2),
    PrimaryCrownPrototype.COURAGE: CoreAffectPoint(2, 0, 2),
    PrimaryCrownPrototype.DESIR: CoreAffectPoint(1, 1, 2),
    PrimaryCrownPrototype.DEGOUT: CoreAffectPoint(-1, -1, 2),
    PrimaryCrownPrototype.COLERE: CoreAffectPoint(-1, 1, 2),
    PrimaryCrownPrototype.CALME: CoreAffectPoint(1, -1, 2),
}


def antagonist_point(p: CoreAffectPoint) -> CoreAffectPoint:
    """Opérateur général d'antagonisme formel (central, axial, diagonal et controlatéral).

    - Positions centrales, axiales ou diagonales (``x == 0 or y == 0 or |x| == |y|``) :
      symétrie centrale ``(X, Y, Z) -> (-X, -Y, Z)``.
    - Positions latérales (``x != 0, y != 0, |x| != |y|``) :
      réflexion diagonale controlatérale permutant les amplitudes absolues et inversant
      les signes : ``(Y, X, Z)`` si signes opposés, ``(-Y, -X, Z)`` si même signe.
    """
    if p.x == 0 or p.y == 0 or abs(p.x) == abs(p.y):
        return CoreAffectPoint(-p.x, -p.y, p.z)
    if (p.x > 0 and p.y < 0) or (p.x < 0 and p.y > 0):
        return CoreAffectPoint(p.y, p.x, p.z)
    return CoreAffectPoint(-p.y, -p.x, p.z)


def _int_sign(v: int) -> int:
    if v > 0:
        return 1
    if v < 0:
        return -1
    return 0


def antagonist_point_unified(p: CoreAffectPoint) -> CoreAffectPoint:
    """Branche hors des axes (`XY != 0`) de l'antagoniste par morceaux : ``(-sgn(X)*|Y|, -sgn(Y)*|X|, Z)`` (sur les axes `XY == 0`, utiliser ``antagonist_point`` qui renvoie ``(-X, -Y, Z)``)."""
    if p.x == 0 or p.y == 0:
        raise ValueError(
            f"La loi algébrique unifiée est définie hors des axes (x != 0 et y != 0), reçu {p!r}."
        )
    return CoreAffectPoint(
        x=-_int_sign(p.x) * abs(p.y),
        y=-_int_sign(p.y) * abs(p.x),
        z=p.z,
    )


def transfer_unit_x_to_y(p: CoreAffectPoint) -> CoreAffectPoint:
    """Transfert élémentaire d'une unité de X vers Y dans le premier quadrant."""
    if p.x > 0 and p.y >= 0:
        return CoreAffectPoint(p.x - 1, p.y + 1, p.z)
    return p


def transfer_unit_y_to_x(p: CoreAffectPoint) -> CoreAffectPoint:
    """Transfert élémentaire d'une unité de Y vers X dans le premier quadrant."""
    if p.x >= 0 and p.y > 0:
        return CoreAffectPoint(p.x + 1, p.y - 1, p.z)
    return p


@dataclass(frozen=True)
class PhenomenologicalMapping:
    """Conventions paramétrables d'interprétation phénoménologique (Résolution R3)."""

    expectation_fn: Callable[[int], LivedExpectationPole]
    control_fn: Callable[[int], LivedControlPole]
    valence_fn: Callable[[int, int], HedonicPolarity]
    activation_fn: Callable[[CoreAffectPoint], PhenomenologicalActivation]


CANONICAL_MAPPING = PhenomenologicalMapping(
    expectation_fn=transduce_expectation,
    control_fn=transduce_control,
    valence_fn=compute_valence,
    activation_fn=compute_activation,
)


@dataclass(frozen=True)
class AffectiveMatrixState:
    """État complet de la Matrice affective couplant Noyau, transduction et antagoniste."""

    core: CoreAffectState
    expectation_pole: LivedExpectationPole
    control_pole: LivedControlPole
    energy_regime: EnergyRegime
    valence: HedonicPolarity
    activation: PhenomenologicalActivation
    antagonist: CoreAffectState


def evaluate_matrix(
    cs: CoreAffectState,
    mapping: PhenomenologicalMapping = CANONICAL_MAPPING,
) -> AffectiveMatrixState:
    """Projette un ``CoreAffectState`` valide dans un ``AffectiveMatrixState`` complet."""
    p = cs.point
    return AffectiveMatrixState(
        core=cs,
        expectation_pole=mapping.expectation_fn(p.x),
        control_pole=mapping.control_fn(p.y),
        energy_regime=compute_energy_regime(p.x, p.y),
        valence=mapping.valence_fn(p.x, p.y),
        activation=mapping.activation_fn(p),
        antagonist=CoreAffectState(point=antagonist_point(p)),
    )


# ---------------------------------------------------------------------------
# Phase 2 : Tenseur de transition B (176 états), α_z, pB et boucle couplée
# ---------------------------------------------------------------------------

NUM_AFFECTIVE_STATES = 176
_STATE_MAPS_CACHE: (
    tuple[
        tuple[LexiconEntry, ...],
        tuple[CoreAffectPoint, ...],
        dict[CoreAffectPoint, int],
    ]
    | None
) = None


def _get_state_maps() -> tuple[
    tuple[LexiconEntry, ...],
    tuple[CoreAffectPoint, ...],
    dict[CoreAffectPoint, int],
]:
    """Construit et met en cache l'indexation canonique des 176 états."""
    global _STATE_MAPS_CACHE
    if _STATE_MAPS_CACHE is None:
        from .lexicon_176 import ALL_176_ENTRIES

        entries = tuple(ALL_176_ENTRIES)
        points = tuple(entry.point for entry in entries)
        idx_by_pt = {entry.point: idx for idx, entry in enumerate(entries)}
        _STATE_MAPS_CACHE = (entries, points, idx_by_pt)
    return _STATE_MAPS_CACHE


def get_entry_by_state_index() -> tuple[LexiconEntry, ...]:
    """Retourne le tuple ordonné des 176 ``LexiconEntry`` indexant les matrices POMDP."""
    return _get_state_maps()[0]


def get_point_by_state_index() -> tuple[CoreAffectPoint, ...]:
    """Retourne le tuple ordonné des 176 ``CoreAffectPoint`` indexant les matrices POMDP."""
    return _get_state_maps()[1]


def get_state_index_by_point() -> dict[CoreAffectPoint, int]:
    """Retourne la correspondance ``CoreAffectPoint -> indice POMDP (0..175)``."""
    return _get_state_maps()[2]

# 8 directions sectorielles correspondant aux 8 prototypes de la couronne primaire Z=2
SECTOR_DIRECTIONS: tuple[tuple[int, int], ...] = (
    (0, 1),    # 0 : JOIE (+Y)
    (0, -1),   # 1 : TRISTESSE (-Y)
    (-1, 0),   # 2 : PEUR (-X)
    (1, 0),    # 3 : COURAGE (+X)
    (-1, 1),   # 4 : COLERE (-X, +Y)
    (1, -1),   # 5 : CALME (+X, -Y)
    (1, 1),    # 6 : DESIR (+X, +Y)
    (-1, -1),  # 7 : DEGOUT (-X, -Y)
)


class AffectiveControlAction(IntEnum):
    """Actions internes de régulation sur les 176 états (17 actions discrètes)."""

    DISSIPATE = 0
    INTRA_JOIE = 1
    INTRA_TRISTESSE = 2
    INTRA_PEUR = 3
    INTRA_COURAGE = 4
    INTRA_COLERE = 5
    INTRA_CALME = 6
    INTRA_DESIR = 7
    INTRA_DEGOUT = 8
    DEEPEN_JOIE = 9
    DEEPEN_TRISTESSE = 10
    DEEPEN_PEUR = 11
    DEEPEN_COURAGE = 12
    DEEPEN_COLERE = 13
    DEEPEN_CALME = 14
    DEEPEN_DESIR = 15
    DEEPEN_DEGOUT = 16


NUM_AFFECTIVE_ACTIONS = len(AffectiveControlAction)


def compute_weighted_valence(
    grad_a: float,
    grad_c: float,
    beta_x: float = 2.0,
    beta_y: float = 1.0,
) -> float:
    """Valence continue pondérée par ``β_X > β_Y`` (primauté épistémique de X)."""
    return float(beta_x * grad_a + beta_y * grad_c)


def canonical_depth_weight(p: CoreAffectPoint, q: CoreAffectPoint) -> int:
    """Noyau canonique ``canonicalDepthWeight`` isomorphe à ``AffectiveDynamics.lean``."""
    if not (is_valid_core_affect(p) and is_valid_core_affect(q)):
        return 0
    if q.z != p.z + 1 or p.x * q.x < 0 or p.y * q.y < 0:
        return 0
    if q.x == 0 and q.y == 0:
        return 1 if (p.x == 0 and p.y == 0) else 0
    if p.x == 0 and p.y == 0:
        return 1 if p.z == 1 else 0
    if p.x == 0 or p.y == 0:
        if (p.x == 0 or q.x != 0) and (p.y == 0 or q.y != 0):
            if q.x == 0 or q.y == 0:
                return 1
            if abs(q.x) == abs(q.y):
                return 2
            return 0
        return 0
    if q.x != 0 and q.y != 0 and abs(q.x) >= abs(p.x) and abs(q.y) >= abs(p.y):
        return 2 if (abs(p.x) == abs(p.y) and abs(q.x) == abs(q.y)) else 1
    return 0


def is_intra_stratum_budget_admissible(
    source: CoreAffectPoint,
    target: CoreAffectPoint,
    lambda_weight: float,
) -> bool:
    """Vérifie la contrainte intra-strate ``|X_{t+1}| + λ |Y_{t+1}| <= 2 Z_t - 2``."""
    if target.z != source.z:
        return False
    if source.z <= 1:
        return target.x == 0 and target.y == 0
    budget = 2 * source.z - 2
    cost = abs(target.x) + float(lambda_weight) * abs(target.y)
    return cost <= budget + 1e-9


def _cosine_alignment(x1: int | float, y1: int | float, x2: int | float, y2: int | float) -> float:
    n1 = math.hypot(x1, y1)
    n2 = math.hypot(x2, y2)
    if n1 == 0.0 or n2 == 0.0:
        return 0.0
    return float((x1 * x2 + y1 * y2) / (n1 * n2))


def effective_dissipation_rate(params: AgentParameters, z: int) -> float:
    """Taux effectif de dissipation allostatique modulé par l'inertie de Dirichlet ``α_z``."""
    alpha_z = params.dirichlet_concentration(z)
    return float(np.clip(params.eta_diss / (1.0 + 0.18 * alpha_z), 0.005, 1.0))


def build_transition_tensor_B(
    params: AgentParameters,
) -> list[np.ndarray]:
    """Construit le tenseur de transition ``B = P(s_{t+1} | s_t, u_t)`` (forme ``(176, 176, 17)``).

    Gouverne :
        (a) Arbitrage intra-strate (actions 1..8) contraint par ``|X_{t+1}| + λ|Y_{t+1}| <= 2Z_t - 2`` ;
        (b) Approfondissement ``Z -> Z+1`` (actions 9..16) suivant ``canonicalDepthWeight`` ;
        (c) Dissipation allostatique (action 0) au taux ``η_eff(Z)`` vers ``(0,0,Z)`` puis ``(0,0,0)``.
    """
    _, points, idx_by_pt = _get_state_maps()
    n_s = len(points)
    n_u = NUM_AFFECTIVE_ACTIONS
    b_mat = np.zeros((n_s, n_s, n_u), dtype=np.float64)
    lam = float(params.lambda_weight)

    idx_veil = idx_by_pt[CoreAffectPoint(0, 0, 0)]

    for s_idx, src in enumerate(points):
        eta_z = effective_dissipation_rate(params, src.z)
        alpha_z = params.dirichlet_concentration(src.z)
        self_bonus = 1.0 + 0.35 * math.log1p(alpha_z)

        # ------------------------------------------------------------------
        # (c) Action 0 : Dissipation allostatique (taux η_eff(Z))
        # ------------------------------------------------------------------
        if src.z == 0:
            b_mat[idx_veil, s_idx, AffectiveControlAction.DISSIPATE] = 1.0
        elif src.x != 0 or src.y != 0:
            # Phase 1 : dépolarisation radiale vers (0, 0, Z)
            central_z = CoreAffectPoint(0, 0, src.z)
            idx_cz = idx_by_pt[central_z]
            b_mat[idx_cz, s_idx, AffectiveControlAction.DISSIPATE] = eta_z
            b_mat[s_idx, s_idx, AffectiveControlAction.DISSIPATE] = 1.0 - eta_z
        elif src.z <= 2:
            # Phase 2 : court-circuit canonique (0,0,2) -> (0,0,0) et (0,0,1) -> (0,0,0)
            b_mat[idx_veil, s_idx, AffectiveControlAction.DISSIPATE] = eta_z
            b_mat[s_idx, s_idx, AffectiveControlAction.DISSIPATE] = 1.0 - eta_z
        else:
            # Phase 2 : descente centrale (0, 0, Z) -> (0, 0, Z-1)
            below_z = CoreAffectPoint(0, 0, src.z - 1)
            idx_bz = idx_by_pt[below_z]
            b_mat[idx_bz, s_idx, AffectiveControlAction.DISSIPATE] = eta_z
            b_mat[s_idx, s_idx, AffectiveControlAction.DISSIPATE] = 1.0 - eta_z

        # ------------------------------------------------------------------
        # (a) Actions 1..8 : Arbitrage intra-strate symétrique contraint par λ
        # ------------------------------------------------------------------
        for sector_id, (gx, gy) in enumerate(SECTOR_DIRECTIONS):
            u_intra = AffectiveControlAction.INTRA_JOIE + sector_id
            col = np.zeros(n_s, dtype=np.float64)
            if src.z <= 1:
                col[s_idx] = 1.0
            else:
                denom_z = float(max(1, src.z))
                for t_idx, tgt in enumerate(points):
                    if not is_intra_stratum_budget_admissible(src, tgt, lam):
                        continue
                    if tgt.x == 0 and tgt.y == 0:
                        weight = 0.0
                    else:
                        align_goal = _cosine_alignment(tgt.x, tgt.y, gx, gy)
                        align_self = (
                            1.0
                            if (src.x == 0 and src.y == 0)
                            else _cosine_alignment(tgt.x, tgt.y, src.x, src.y)
                        )
                        weighted_effort = (abs(tgt.x) + lam * abs(tgt.y)) / denom_z
                        weight = (
                            math.exp(3.0 * align_goal + 0.8 * align_self - 0.5 * weighted_effort)
                        )
                        if t_idx == s_idx:
                            weight *= self_bonus
                    col[t_idx] = weight
                col_sum = float(col.sum())
                if col_sum <= 0.0:
                    col[s_idx] = 1.0
                else:
                    col /= col_sum
            b_mat[:, s_idx, u_intra] = col

        # ------------------------------------------------------------------
        # (b) Actions 9..16 : Approfondissement Z -> Z + 1
        # ------------------------------------------------------------------
        for sector_id, (gx, gy) in enumerate(SECTOR_DIRECTIONS):
            u_deep = AffectiveControlAction.DEEPEN_JOIE + sector_id
            col = np.zeros(n_s, dtype=np.float64)
            if src.z == 0:
                idx_surprise = idx_by_pt[CoreAffectPoint(0, 0, 1)]
                col[idx_surprise] = 1.0
            elif src.z < 7:
                for t_idx, tgt in enumerate(points):
                    dw = canonical_depth_weight(src, tgt)
                    if dw <= 0:
                        continue
                    if tgt.x == 0 and tgt.y == 0:
                        align = 0.15 if (src.x == 0 and src.y == 0) else 0.0
                    else:
                        align = max(0.0, _cosine_alignment(tgt.x, tgt.y, gx, gy))
                    col[t_idx] = float(dw) * (0.1 + 3.0 * (align ** 2))
                col_sum = float(col.sum())
                if col_sum <= 0.0:
                    # Repli sur la même strate dans le sens sectoriel si aucun successeur aligné
                    col[s_idx] = 1.0
                else:
                    col /= col_sum
            else:
                # Strate limite Z = 7 : maintien sur la strate Z=7 orienté vers (gx, gy)
                for t_idx, tgt in enumerate(points):
                    if tgt.z != 7:
                        continue
                    if tgt.x == 0 and tgt.y == 0:
                        col[t_idx] = 0.05 if (src.x == 0 and src.y == 0) else 0.01
                    else:
                        align_goal = _cosine_alignment(tgt.x, tgt.y, gx, gy)
                        align_self = (
                            1.0
                            if (src.x == 0 and src.y == 0)
                            else _cosine_alignment(tgt.x, tgt.y, src.x, src.y)
                        )
                        w = math.exp(2.5 * align_goal + 1.0 * align_self)
                        if t_idx == s_idx:
                            w *= 1.5
                        col[t_idx] = w
                col /= float(col.sum())
            b_mat[:, s_idx, u_deep] = col

    # Normalisation stricte finale par colonne
    b_mat = b_mat / b_mat.sum(axis=0, keepdims=True)
    return [b_mat]


def build_dirichlet_priors_pB(
    transition_b: Sequence[np.ndarray],
    params: AgentParameters,
) -> list[np.ndarray]:
    """Construit ``pB`` avec concentration ``α_z = α_0 exp(γ_α z)`` par strate source."""
    points = get_point_by_state_index()
    alphas = np.array(
        [params.dirichlet_concentration(pt.z) for pt in points],
        dtype=np.float64,
    )
    pb_list: list[np.ndarray] = []
    for b_f in transition_b:
        arr = np.asarray(b_f, dtype=np.float64)
        # arr.shape == (176, 176, 17) : dimension 1 = état source s_t
        pb_list.append(arr * alphas[None, :, None])
    return pb_list


def build_preference_tensor_C(params: AgentParameters) -> list[np.ndarray]:
    """Construit les préférences a priori sur les 3 modalités EMA non redondantes.

    Modalités : ``obs_A(3), obs_C(3), persistence_level(4)``.
    Valorise la résolution homéostatique (état basal filtré) et les issues
    positives plutôt que les charges négatives ou profondes.
    """
    del params  # Utilise l'échelle unitaire pour C ; β_X, β_Y pondèrent G(π)
    return [
        np.array([1.00, 0.50, -1.40], dtype=np.float64),
        np.array([1.00, 0.50, -1.40], dtype=np.float64),
        np.array([1.40, 0.10, -0.70, -1.50], dtype=np.float64),
    ]


def _sector_index_for_gradients(grad_a: float, grad_c: float) -> int:
    """Retourne l'indice ``0..7`` dans ``SECTOR_DIRECTIONS`` aligné sur ``(∇A, ∇C)``."""
    best_idx = 0
    best_score = -1e9
    for idx, (gx, gy) in enumerate(SECTOR_DIRECTIONS):
        score = _cosine_alignment(grad_a, grad_c, gx, gy)
        if score > best_score:
            best_score = score
            best_idx = idx
    return best_idx


@eqx.filter_jit
def _jit_affect_infer_step(
    agent: Agent,
    obs_arrays: list[jax.Array],
    empirical_prior: list[jax.Array],
) -> list[jax.Array]:
    return agent.infer_states(obs_arrays, empirical_prior)


@eqx.filter_jit
def _jit_affect_learn_a_only(
    agent: Agent,
    beliefs_a: list[jax.Array],
    obs_a: list[jax.Array],
    lr_pa: jax.Array,
) -> Agent:
    dummy_b = [jnp.concatenate([beliefs_a[0], beliefs_a[0]], axis=1)]
    sentinel_act = jnp.full((1, 1, 1), -1, dtype=jnp.int32)
    return agent.infer_parameters(
        beliefs_a,
        obs_a,
        actions=sentinel_act,
        beliefs_B=dummy_b,
        lr_pA=lr_pa,
        lr_pB=0.0,
    )


@eqx.filter_jit
def _jit_affect_learn_step(
    agent: Agent,
    beliefs_a: list[jax.Array],
    obs_a: list[jax.Array],
    beliefs_b: list[jax.Array],
    act_hist: jax.Array,
    lr_pa: jax.Array,
    lr_pb: jax.Array,
) -> Agent:
    return agent.infer_parameters(
        beliefs_a,
        obs_a,
        act_hist,
        beliefs_B=beliefs_b,
        lr_pA=lr_pa,
        lr_pB=lr_pb,
    )


@eqx.filter_jit
def _jit_affect_decide_step(
    agent: Agent,
    e_j: jax.Array,
    qs_post: list[jax.Array],
    c_unit_j: list[jax.Array],
    policies_j: jax.Array,
    batched_key: jax.Array,
) -> tuple[jax.Array, jax.Array, jax.Array, jax.Array, jax.Array, list[jax.Array]]:
    agent_ctx = eqx.tree_at(lambda a: a.E, agent, e_j)
    q_pi, _ = agent_ctx.infer_policies(qs_post)
    ep_j, pr_j, pm_j = _jit_efe_components(
        [qs_post[0][0, -1, :]],
        [a[0] for a in agent.A],
        [b[0] for b in agent.B],
        c_unit_j,
        None,
        None,
        policies_j,
        ((0,), (0,), (0,)),
        ((0,),),
    )
    act_arr = agent_ctx.sample_action(q_pi, rng_key=batched_key)
    next_prior = agent.update_empirical_prior(act_arr, qs_post)
    return q_pi, ep_j, pr_j, pm_j, act_arr, next_prior


class AffectivePOMDPEngine:
    """Agent POMDP ``pymdp`` complet sur les 176 états canoniques CARTOGRAFFECT."""

    def __init__(
        self,
        params: AgentParameters,
        seed: int | None = 42,
        *,
        learn_a: bool = True,
        learn_b: bool = True,
    ) -> None:
        self.params = params
        self.learn_a = learn_a
        self.learn_b = learn_b
        self._rng_key = jax.random.PRNGKey(0 if seed is None else int(seed) + 101)

        self.A_init = build_likelihood_matrix_A(params)
        self.B_init = build_transition_tensor_B(params)
        self.C_unit = build_preference_tensor_C(params)
        self._c_unit_j = [jnp.asarray(c, dtype=jnp.float32) for c in self.C_unit]
        self._policies_j = jnp.arange(NUM_AFFECTIVE_ACTIONS, dtype=jnp.int32).reshape(
            NUM_AFFECTIVE_ACTIONS, 1, 1
        )
        self._lr_pa_j = jnp.asarray(self.params.lr_pa, dtype=jnp.float32)
        self._lr_pb_j = jnp.asarray(self.params.lr_pb, dtype=jnp.float32)
        self.pA_init = build_dirichlet_priors_pA(self.A_init, params)
        self.pB_init = build_dirichlet_priors_pB(self.B_init, params)

        self._z_arr = np.array(
            [pt.z for pt in get_point_by_state_index()], dtype=np.float64
        )
        self.D_init = np.zeros(NUM_AFFECTIVE_STATES, dtype=np.float64)
        idx_veil = get_state_index_by_point()[CoreAffectPoint(0, 0, 0)]
        self.D_init[idx_veil] = 0.95
        self.D_init += 0.05 / NUM_AFFECTIVE_STATES
        self.D_init /= self.D_init.sum()

        self.E_base = np.ones(NUM_AFFECTIVE_ACTIONS, dtype=np.float64)
        self.E_base /= self.E_base.sum()

        self._agent = self._instantiate_agent()
        self._qs: list[jax.Array] = [
            jnp.asarray(self.D_init[None, None, :], dtype=jnp.float32)
        ]
        self._empirical_prior: list[jax.Array] = [
            jnp.asarray(self.D_init[None, :], dtype=jnp.float32)
        ]
        self._prev_qs: jax.Array | None = None
        self._prev_action: jax.Array | None = None
        self._persistent_discrepancy_steps: int = 0

    def _instantiate_agent(self) -> Agent:
        ratio = self.params.beta_y / self.params.beta_x
        c_scaled = [jnp.asarray(c * ratio, dtype=jnp.float32) for c in self.C_unit]
        return Agent(
            A=[jnp.asarray(a, dtype=jnp.float32) for a in self.A_init],
            B=[jnp.asarray(b, dtype=jnp.float32) for b in self.B_init],
            C=c_scaled,
            D=[jnp.asarray(self.D_init, dtype=jnp.float32)],
            E=jnp.asarray(self.E_base, dtype=jnp.float32),
            pA=[jnp.asarray(pa, dtype=jnp.float32) for pa in self.pA_init],
            pB=[jnp.asarray(pb, dtype=jnp.float32) for pb in self.pB_init],
            num_controls=[NUM_AFFECTIVE_ACTIONS],
            control_fac_idx=[0],
            policy_len=1,
            gamma=float(self.params.affect_gamma * self.params.beta_x),
            alpha=8.0,
            use_utility=True,
            use_states_info_gain=True,
            use_param_info_gain=False,
            action_selection="stochastic",
            inference_algo="fpi",
            num_iter=8,
            batch_size=1,
            learning_mode="online",
            learn_A=self.learn_a,
            learn_B=self.learn_b,
        )

    def reset(self) -> None:
        self._agent = self._instantiate_agent()
        self._qs = [jnp.asarray(self.D_init[None, None, :], dtype=jnp.float32)]
        self._empirical_prior = [
            jnp.asarray(self.D_init[None, :], dtype=jnp.float32)
        ]
        self._prev_qs = None
        self._prev_action = None
        self._persistent_discrepancy_steps = 0

    @property
    def current_A(self) -> list[np.ndarray]:
        return [np.asarray(a[0], dtype=np.float64) for a in self._agent.A]

    @property
    def current_B(self) -> list[np.ndarray]:
        return [np.asarray(b[0], dtype=np.float64) for b in self._agent.B]

    @property
    def current_pA(self) -> list[np.ndarray]:
        return [np.asarray(pa[0], dtype=np.float64) for pa in self._agent.pA]

    @property
    def current_pB(self) -> list[np.ndarray]:
        return [np.asarray(pb[0], dtype=np.float64) for pb in self._agent.pB]

    @property
    def current_qs(self) -> np.ndarray:
        arr = np.asarray(self._qs[0][0, -1, :], dtype=np.float64)
        return arr / float(arr.sum())

    def _compute_contextual_habits(
        self,
        task_signals: TaskStepSignals,
        ema_obs: EMAObservation,
    ) -> np.ndarray:
        """Construit les priorités contextuelles douces ``E`` gouvernées par les seuls signaux internes."""
        e_ctx = np.full(NUM_AFFECTIVE_ACTIONS, 0.004, dtype=np.float64)

        active_ema = ema_obs.filter_a == 1 or ema_obs.filter_c == 1
        discrepancy = task_signals.discrepancy_magnitude
        precision = task_signals.attentional_precision
        eff_ga = task_signals.grad_a if ema_obs.filter_a == 1 else 0.0
        eff_gc = task_signals.grad_c if ema_obs.filter_c == 1 else 0.0
        # Écart aversif ou épistémique non résolu filtré par (τ_A, τ_C)
        unresolved_error = (
            eff_ga < -self.params.tau_a
            or eff_gc < -self.params.tau_c
            or (ema_obs.filter_a == 1 and task_signals.bayesian_surprise > 0.15)
        )
        qs = self.current_qs
        mean_z = float(np.dot(qs, self._z_arr))
        p_below_z2 = float(qs[self._z_arr <= 1.0].sum())
        p_z0 = float(qs[self._z_arr == 0.0].sum())

        if (
            not active_ema
            and task_signals.persistence_level == 0
            and discrepancy < self.params.resorption_threshold
        ):
            self._persistent_discrepancy_steps = 0
            e_ctx[AffectiveControlAction.DISSIPATE] = 0.85
        else:
            if unresolved_error:
                self._persistent_discrepancy_steps += 1
            else:
                self._persistent_discrepancy_steps = max(
                    0, self._persistent_discrepancy_steps - 1
                )
            if eff_ga == 0.0 and eff_gc == 0.0:
                eff_ga = task_signals.grad_a
                eff_gc = task_signals.grad_c
            sector = _sector_index_for_gradients(eff_ga, eff_gc)
            depth_cap = float(min(7, 2 + round(1.65 * task_signals.persistence_level)))

            if p_below_z2 > 0.5 and active_ema:
                e_ctx[AffectiveControlAction.DEEPEN_JOIE + sector] = 0.70
                e_ctx[AffectiveControlAction.INTRA_JOIE + sector] = 0.18
            elif (
                unresolved_error
                and self._persistent_discrepancy_steps >= 2
                and precision >= self.params.deepen_precision_threshold
                and mean_z < depth_cap
                and p_z0 < 0.15
            ):
                e_ctx[AffectiveControlAction.DEEPEN_JOIE + sector] = 0.65
                e_ctx[AffectiveControlAction.INTRA_JOIE + sector] = 0.22
            else:
                e_ctx[AffectiveControlAction.INTRA_JOIE + sector] = (
                    0.75 if mean_z >= depth_cap else 0.70
                )
                e_ctx[AffectiveControlAction.DEEPEN_JOIE + sector] = (
                    0.10
                    if (unresolved_error and mean_z < depth_cap and p_z0 < 0.15)
                    else 0.004
                )
                e_ctx[AffectiveControlAction.DISSIPATE] = 0.02 if active_ema else 0.18

        e_ctx /= float(e_ctx.sum())
        return e_ctx

    def step(
        self,
        ema_obs: EMAObservation,
        task_signals: TaskStepSignals,
        *,
        update_parameters: bool = True,
    ) -> tuple[AffectiveControlAction, ExpectedFreeEnergyResult, np.ndarray]:
        """Exécute un pas inférentiel complet du POMDP affectif (176 états) sans double-comptage."""
        obs_tuple = ema_obs.modality_indices
        obs_arrays = [jnp.array([idx], dtype=jnp.int32) for idx in obs_tuple]

        # 1. Inférence variationnelle des états affectifs q(s_t) via pymdp
        qs_post = _jit_affect_infer_step(self._agent, obs_arrays, self._empirical_prior)
        self._qs = qs_post

        # 2. Apprentissage Dirichlet sans double-comptage : pA sur le pas t uniquement (T=1),
        #    pB sur la transition (t-1 -> t) lorsque prev_qs est disponible.
        if update_parameters and (self.learn_a or self.learn_b):
            obs_curr = [jnp.array([[obs_tuple[m]]], dtype=jnp.int32) for m in range(3)]
            beliefs_a = [qs_post[0]]
            if self._prev_qs is not None and self._prev_action is not None:
                beliefs_b = [jnp.concatenate([self._prev_qs, qs_post[0]], axis=1)]
                act_hist = self._prev_action[:, None, :]
                self._agent = _jit_affect_learn_step(
                    self._agent,
                    beliefs_a,
                    obs_curr,
                    beliefs_b,
                    act_hist,
                    self._lr_pa_j,
                    self._lr_pb_j,
                )
            elif self.learn_a:
                self._agent = _jit_affect_learn_a_only(
                    self._agent,
                    beliefs_a,
                    obs_curr,
                    self._lr_pa_j,
                )

        # 3. Priorités contextuelles douces E, G(π) (incluant param info gain) et transition B
        e_ctx = self._compute_contextual_habits(task_signals, ema_obs)
        e_j = jnp.asarray(e_ctx[None, :], dtype=jnp.float32)
        self._rng_key, subkey = jax.random.split(self._rng_key)
        batched_key = jax.random.split(subkey, 1)

        q_pi, ep_j, pr_j, pm_j, act_arr, next_prior = _jit_affect_decide_step(
            self._agent,
            e_j,
            qs_post,
            self._c_unit_j,
            self._policies_j,
            batched_key,
        )
        self._empirical_prior = next_prior

        ep_arr = np.asarray(ep_j, dtype=np.float64)
        pr_arr = np.asarray(pr_j, dtype=np.float64)
        pm_arr = np.asarray(pm_j, dtype=np.float64)
        neg_efe = self.params.beta_x * ep_arr + self.params.beta_y * pr_arr
        efe_result = ExpectedFreeEnergyResult(
            efe=-neg_efe,
            neg_efe=neg_efe,
            epistemic_value=ep_arr,
            pragmatic_value=pr_arr,
            param_info_gain=pm_arr,
            policy_posterior=np.asarray(q_pi[0], dtype=np.float64),
        )

        self._prev_qs = qs_post[0]
        self._prev_action = act_arr

        chosen_action = AffectiveControlAction(int(act_arr[0, 0]))
        qs_vec = self.current_qs
        return chosen_action, efe_result, qs_vec


@dataclass(frozen=True)
class SimulationStepRecord:
    """Enregistrement complet d'un essai couplé (monde + tâche + EMA + affectivité)."""

    trial_index: int
    block_id: int
    block_name: str
    is_remission: bool
    env_result: EnvStepResult
    task_signals: TaskStepSignals
    ema_observation: EMAObservation
    affective_action: AffectiveControlAction
    map_state_index: int
    map_entry: LexiconEntry
    qs_affect: np.ndarray
    expected_z: float
    p_homeostasis: float
    weighted_valence: float
    affect_efe: ExpectedFreeEnergyResult


@dataclass(frozen=True)
class SessionResult:
    """Résultat complet d'une session expérimentale multi-essais."""

    params: AgentParameters
    records: tuple[SimulationStepRecord, ...]
    final_A: list[np.ndarray]
    final_B: list[np.ndarray]
    final_pA: list[np.ndarray]
    final_pB: list[np.ndarray]
    env_summary: dict[str, float | int]


class ActiveInferenceCartograffectAgent:
    """Agent complet couplant ``TaskInferenceEngine``, sondes EMA et ``AffectivePOMDPEngine``."""

    def __init__(
        self,
        params: AgentParameters | None = None,
        seed: int | None = 42,
        *,
        stochastic_ema: bool = True,
        learn_a: bool = True,
        learn_b: bool = True,
    ) -> None:
        self.params = params if params is not None else AgentParameters()
        self.seed = seed
        self.task_engine = TaskInferenceEngine(self.params, seed=seed)
        self.ema_generator = TwoStageEMAGenerator(
            self.params,
            seed=None if seed is None else seed + 17,
            stochastic=stochastic_ema,
        )
        self.affect_engine = AffectivePOMDPEngine(
            self.params,
            seed=seed,
            learn_a=learn_a,
            learn_b=learn_b,
        )

    def reset(self) -> None:
        self.task_engine.reset()
        self.affect_engine.reset()

    def step(
        self,
        env: NonStationaryBanditEnv,
        *,
        update_parameters: bool = True,
    ) -> SimulationStepRecord:
        """Exécute un essai complet d'interaction agent-environnement."""
        pre_obs = env.current_observation()
        behav_action = self.task_engine.select_action(pre_obs)
        env_result = env.step(behav_action)
        obs = env_result.observation

        task_signals = self.task_engine.observe_outcome(obs, behav_action)
        ema_obs = self.ema_generator.sample_from_gradients(
            task_signals.grad_a,
            task_signals.grad_c,
            persistence_level=task_signals.persistence_level,
        )
        affect_action, efe_res, qs_vec = self.affect_engine.step(
            ema_obs,
            task_signals,
            update_parameters=update_parameters,
        )

        entries, points, idx_by_pt = _get_state_maps()
        map_idx = int(np.argmax(qs_vec))
        map_entry = entries[map_idx]
        z_arr = np.array([pt.z for pt in points], dtype=np.float64)
        expected_z = float(np.dot(qs_vec, z_arr))
        idx_veil = idx_by_pt[CoreAffectPoint(0, 0, 0)]
        p_homeo = float(qs_vec[idx_veil])
        w_val = compute_weighted_valence(
            task_signals.grad_a,
            task_signals.grad_c,
            self.params.beta_x,
            self.params.beta_y,
        )

        return SimulationStepRecord(
            trial_index=obs.trial_index,
            block_id=obs.block_id,
            block_name=obs.block_name,
            is_remission=obs.is_remission,
            env_result=env_result,
            task_signals=task_signals,
            ema_observation=ema_obs,
            affective_action=affect_action,
            map_state_index=map_idx,
            map_entry=map_entry,
            qs_affect=qs_vec,
            expected_z=expected_z,
            p_homeostasis=p_homeo,
            weighted_valence=w_val,
            affect_efe=efe_res,
        )

    def run_session(
        self,
        env: NonStationaryBanditEnv,
        *,
        num_trials: int | None = None,
        reset_first: bool = True,
        update_parameters: bool = True,
    ) -> SessionResult:
        """Exécute une session complète (par défaut les 400 essais du protocole)."""
        if reset_first:
            env.reset()
            self.reset()

        n_steps = env.total_trials if num_trials is None else int(num_trials)
        records: list[SimulationStepRecord] = []
        for _ in range(n_steps):
            if env.is_done:
                break
            records.append(self.step(env, update_parameters=update_parameters))

        return SessionResult(
            params=self.params,
            records=tuple(records),
            final_A=self.affect_engine.current_A,
            final_B=self.affect_engine.current_B,
            final_pA=self.affect_engine.current_pA,
            final_pB=self.affect_engine.current_pB,
            env_summary=env.summarize(),
        )


__all__ = [
    "AffectiveControlAction",
    "AffectiveMatrixState",
    "AffectivePOMDPEngine",
    "ActiveInferenceCartograffectAgent",
    "CANONICAL_MAPPING",
    "EnergyRegime",
    "HedonicPolarity",
    "LivedControlPole",
    "LivedExpectationPole",
    "NUM_AFFECTIVE_ACTIONS",
    "NUM_AFFECTIVE_STATES",
    "PhenomenologicalActivation",
    "PhenomenologicalMapping",
    "PrimaryCrownPrototype",
    "SECTOR_DIRECTIONS",
    "SessionResult",
    "SimulationStepRecord",
    "antagonist_point",
    "antagonist_point_unified",
    "build_dirichlet_priors_pB",
    "build_preference_tensor_C",
    "build_transition_tensor_B",
    "canonical_depth_weight",
    "compute_activation",
    "compute_energy_regime",
    "compute_hedonic_polarity",
    "compute_valence",
    "compute_weighted_valence",
    "dissipation_step",
    "effective_dissipation_rate",
    "evaluate_matrix",
    "get_entry_by_state_index",
    "get_point_by_state_index",
    "get_state_index_by_point",
    "is_intra_stratum_budget_admissible",
    "transduce_control",
    "transduce_expectation",
    "transfer_unit_x_to_y",
    "transfer_unit_y_to_x",
]
