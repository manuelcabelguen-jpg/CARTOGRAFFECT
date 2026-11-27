"""Espace d'affect central CARTOGRAFFECT (isomorphe à `Cartograffect/CoreAffect.lean`).

Implémente la géométrie discrète tridimensionnelle `(X, Y, Z)` du Noyau affectif :
- Coordonnées `(X = Attente, Y = Contrôle, Z = Profondeur)`, somme de déplacements
  L1 (`|X| + |Y|`) et loi des couronnes (`crown_radius(Z) = 2Z - 2` pour `Z >= 2`) ;
- Point de Veille `(0, 0, 0)` et sept opérateurs centraux (`Z = 1..7`) ;
- Typologie géométrique (`central`, `axial`, `diagonal`, `lateral`) et secteurs
  d'orientation dominants (`joie`, `tristesse`, `peur`, `courage`) ;
- Projection déterministe du Moteur prédictif (`project_to_core_affect`,
  `apportion_ray`, `deploy_coupling_with_precision`, `witness_engine_for_point`) ;
- Conservation budgétaire en `Z = 2`, réallocation axiale → diagonale,
  dissipation allostatique avec court-circuit `(0, 0, 2) -> (0, 0, 0)` et
  régimes de ressources (`competitive` vs `cooperative`).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum

from .predictive_engine import (
    ALL_COUPLINGS,
    AttentionalInterface,
    EngineCoupling,
    PerceptiveInterface,
    Polarity,
    PredictiveEngineState,
    SalientDiscrepancy,
    SubjectiveInterface,
    engine_step,
)


def _require_nat(value: int, name: str) -> None:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise ValueError(f"{name} doit être un entier naturel (Nat >= 0), reçu {value!r}.")


def _require_int(value: int, name: str) -> None:
    if isinstance(value, bool) or not isinstance(value, int):
        raise ValueError(f"{name} doit être un entier (Int), reçu {value!r}.")


def crown_radius(z: int) -> int:
    """Rayon de Manhattan de la couronne périphérique à la strate ``z``.

    - ``Z = 0`` ou ``Z = 1`` : rayon ``0`` (cône d'amorçage sans couronne).
    - ``Z >= 2`` : ``R(Z) = 2 * Z - 2``.
    """
    _require_nat(z, "z")
    if z < 2:
        return 0
    return 2 * z - 2


class GeometryType(str, Enum):
    """Typologie géométrique des positions au sein de l'espace affectif."""

    CENTRAL = "central"
    AXIAL = "axial"
    DIAGONAL = "diagonal"
    LATERAL = "lateral"


class OrientationSector(str, Enum):
    """Secteurs d'orientation géométrique définis par l'axe dominant et son signe."""

    JOIE = "joie"
    TRISTESSE = "tristesse"
    PEUR = "peur"
    COURAGE = "courage"


@dataclass(frozen=True)
class CoreAffectPoint:
    """Coordonnée tridimensionnelle dans l'espace du Noyau affectif."""

    x: int = 0
    y: int = 0
    z: int = 0

    def __post_init__(self) -> None:
        _require_int(self.x, "x")
        _require_int(self.y, "y")
        _require_nat(self.z, "z")

    def displacement_sum(self) -> int:
        """Cumul des déplacements absolus ``|X| + |Y|`` (norme L1)."""
        return abs(self.x) + abs(self.y)

    def is_central(self) -> bool:
        """Prédicat caractérisant un opérateur central ``(0, 0, Z)``."""
        return self.x == 0 and self.y == 0

    def is_on_crown(self) -> bool:
        """Prédicat caractérisant une position périphérique admissible (``Z >= 2``)."""
        return self.z >= 2 and self.displacement_sum() == crown_radius(self.z)

    def is_valid(self) -> bool:
        """Invariant d'admissibilité topologique ``isValidCoreAffect``."""
        return self.is_central() or self.is_on_crown()

    def classify_geometry(self) -> GeometryType:
        """Classification géométrique exacte de tout point du Noyau affectif."""
        if self.x == 0 and self.y == 0:
            return GeometryType.CENTRAL
        if self.x == 0 or self.y == 0:
            return GeometryType.AXIAL
        if abs(self.x) == abs(self.y):
            return GeometryType.DIAGONAL
        return GeometryType.LATERAL

    def dominant_sector(self) -> OrientationSector | None:
        """Retourne le secteur d'orientation dominant, ou ``None`` si ``|X| == |Y|``."""
        ax = abs(self.x)
        ay = abs(self.y)
        if ay > ax:
            return OrientationSector.JOIE if self.y > 0 else OrientationSector.TRISTESSE
        if ax > ay:
            return OrientationSector.PEUR if self.x < 0 else OrientationSector.COURAGE
        return None


def is_valid_core_affect(p: CoreAffectPoint) -> bool:
    """Invariant d'admissibilité topologique du Noyau affectif (centre ou couronne)."""
    return p.is_valid()


class ResourceRegime(str, Enum):
    """Régimes d'allocation des ressources attentionnelles."""

    COMPETITIVE = "competitive"
    COOPERATIVE = "cooperative"


def is_valid_core_affect_in(regime: ResourceRegime, p: CoreAffectPoint) -> bool:
    """Invariant d'admissibilité topologique paramétré par le régime de ressources."""
    if regime is ResourceRegime.COMPETITIVE:
        return is_valid_core_affect(p)
    return p.is_central() or (p.z >= 2 and crown_radius(p.z) <= p.displacement_sum())


@dataclass(frozen=True)
class CoreAffectState:
    """État certifié du Noyau affectif satisfaisant ``is_valid_core_affect``."""

    point: CoreAffectPoint = field(default_factory=CoreAffectPoint)

    def __post_init__(self) -> None:
        if not is_valid_core_affect(self.point):
            raise ValueError(
                f"Point géométriquement invalide dans le Noyau affectif : {self.point!r}."
            )


class CentralOperator(str, Enum):
    """Point de Veille (Z=0) et sept opérateurs centraux (Z=1 à Z=7)."""

    POINT_DE_VEILLE = "Point de Veille"
    SURPRISE = "Surprise"
    ANTICIPATION = "Anticipation"
    EMOI = "Émoi"
    RESERVE = "Réserve"
    RECUL = "Recul"
    SAISISSEMENT = "Saisissement"
    SUSPENSION = "Suspension"

    def to_point(self) -> CoreAffectPoint:
        """Coordonnée canonique ``(0, 0, Z)`` de l'opérateur central."""
        return CoreAffectPoint(0, 0, _CENTRAL_OPERATOR_Z[self])

    def to_core_affect_state(self) -> CoreAffectState:
        """Convertit l'opérateur central en ``CoreAffectState`` valide."""
        return CoreAffectState(point=self.to_point())


_CENTRAL_OPERATOR_Z: dict[CentralOperator, int] = {
    CentralOperator.POINT_DE_VEILLE: 0,
    CentralOperator.SURPRISE: 1,
    CentralOperator.ANTICIPATION: 2,
    CentralOperator.EMOI: 3,
    CentralOperator.RESERVE: 4,
    CentralOperator.RECUL: 5,
    CentralOperator.SAISISSEMENT: 6,
    CentralOperator.SUSPENSION: 7,
}


def signed_amplitude(pol: Polarity, amp: int) -> int:
    """Projection signée d'une amplitude naturelle selon la polarité d'un gradient."""
    _require_nat(amp, "amp")
    return pol.to_int() * amp


def _clamp_nat(lo: int, hi: int, v: int) -> int:
    if v < lo:
        return lo
    if hi < v:
        return hi
    return v


def apportion_ray(d: int, pi_a: int, pi_c: int) -> tuple[int, int]:
    """Partage discret du rayon ``R(Z) = 2 * d + 2`` selon ``(pi_A, pi_C)``."""
    _require_nat(d, "d")
    _require_nat(pi_a, "pi_a")
    _require_nat(pi_c, "pi_c")
    r = 2 * d + 2
    if pi_a == pi_c:
        return (d + 1, d + 1)
    total = pi_a + pi_c
    if pi_a < pi_c:
        raw = (2 * r * pi_a + total) // (2 * total)
        ax = _clamp_nat(1, d + 1, raw)
        return (ax, r - ax)
    raw = (2 * r * pi_c + total) // (2 * total)
    ay = _clamp_nat(1, d + 1, raw)
    return (r - ay, ay)


def _deploy_with_amplitudes(c: EngineCoupling, d: int, ax: int, ay: int) -> CoreAffectPoint:
    z = d + 2
    r = 2 * d + 2
    if c.is_global_neutrality():
        return CoreAffectPoint(0, 0, 0)
    if c.is_single_engaged():
        return CoreAffectPoint(
            signed_amplitude(c.attente, r),
            signed_amplitude(c.controle, r),
            z,
        )
    return CoreAffectPoint(
        signed_amplitude(c.attente, ax),
        signed_amplitude(c.controle, ay),
        z,
    )


def deploy_coupling_at_depth(c: EngineCoupling, d: int) -> CoreAffectPoint:
    """Déploiement spatial symétrique d'un couplage ``(A, C)`` en ``Z = d + 2``."""
    _require_nat(d, "d")
    k = d + 1
    return _deploy_with_amplitudes(c, d, k, k)


def deploy_coupling_with_precision(
    c: EngineCoupling,
    d: int,
    pi_a: int,
    pi_c: int,
) -> CoreAffectPoint:
    """Déploiement spatial généralisé sous pondération relative ``(pi_A, pi_C)``."""
    _require_nat(d, "d")
    _require_nat(pi_a, "pi_a")
    _require_nat(pi_c, "pi_c")
    if c.is_dual_engaged():
        ax, ay = apportion_ray(d, pi_a, pi_c)
        return _deploy_with_amplitudes(c, d, ax, ay)
    return _deploy_with_amplitudes(c, d, 0, 0)


def project_to_core_affect(s: PredictiveEngineState) -> CoreAffectPoint:
    """Projection déterministe d'un état du Moteur prédictif vers ``CoreAffectPoint``."""
    c = s.current_coupling()
    if not s.discrepancy.is_sensorily_salient() or c.is_global_neutrality():
        if s.subjective.descending_suspension:
            return CoreAffectPoint(0, 0, s.attentional.persistence_depth + 2)
        return CoreAffectPoint(0, 0, 0)
    if not s.attentional.is_engaged():
        if s.subjective.descending_suspension:
            return CoreAffectPoint(0, 0, s.attentional.persistence_depth + 2)
        return CoreAffectPoint(0, 0, 1)
    return deploy_coupling_with_precision(
        c,
        s.attentional.persistence_depth,
        s.attentional.precision_a,
        s.attentional.precision_c,
    )


def evaluate_core_affect(s: PredictiveEngineState) -> CoreAffectState:
    """Évalue un état du Moteur en un état certifié ``CoreAffectState``."""
    return CoreAffectState(point=project_to_core_affect(s))


def trigger_secondary_gradient(c: EngineCoupling, new_pol: Polarity) -> EngineCoupling:
    """Réalloue un couplage axial lors du déclenchement du second gradient."""
    if c.attente is not Polarity.ZERO and c.controle is Polarity.ZERO:
        return EngineCoupling(attente=c.attente, controle=new_pol)
    if c.attente is Polarity.ZERO and c.controle is not Polarity.ZERO:
        return EngineCoupling(attente=new_pol, controle=c.controle)
    return c


def apply_budget_constraint(
    dx: float,
    dy: float,
    radius: float,
    lambda_weight: float,
) -> tuple[float, float]:
    """Projection budgétaire symétrique sous contrainte ``|X| + λ|Y| <= R``."""
    r = float(radius)
    if r <= 0.0:
        return 0.0, 0.0
    dx_c = min(r, max(0.0, float(dx)))
    dy_c = min(r, max(0.0, float(dy)))
    denom = dx_c + float(lambda_weight) * dy_c
    if denom > r and denom > 0.0:
        scale = r / denom
        return scale * dx_c, min(r, scale * dy_c)
    return dx_c, dy_c


def witness_engine_for_point(p: CoreAffectPoint) -> PredictiveEngineState:
    """Construit le témoin explicite du Moteur atteignant ``p`` via ``project_to_core_affect``."""
    if not is_valid_core_affect(p):
        raise ValueError(
            f"Point géométriquement invalide dans le Noyau affectif : {p!r}."
        )
    if p.x == 0 and p.y == 0:
        if p.z == 0:
            return PredictiveEngineState()
        if p.z == 1:
            return PredictiveEngineState(
                discrepancy=SalientDiscrepancy(magnitude=2, sensory_threshold=1, resorption_threshold=1),
                perceptive=PerceptiveInterface(controle_gradient=Polarity.ZERO),
                subjective=SubjectiveInterface(attente_gradient=Polarity.POS, descending_suspension=False),
                attentional=AttentionalInterface(
                    allocated_precision=0,
                    engagement_threshold=1,
                    persistence_depth=0,
                    precision_a=1,
                    precision_c=1,
                ),
            )
        return PredictiveEngineState(
            discrepancy=SalientDiscrepancy(magnitude=2, sensory_threshold=1, resorption_threshold=1),
            perceptive=PerceptiveInterface(controle_gradient=Polarity.ZERO),
            subjective=SubjectiveInterface(attente_gradient=Polarity.POS, descending_suspension=True),
            attentional=AttentionalInterface(
                allocated_precision=0,
                engagement_threshold=1,
                persistence_depth=p.z - 2,
                precision_a=1,
                precision_c=1,
            ),
        )
    if p.z < 2:
        raise ValueError(
            f"Un point périphérique doit satisfaire z >= 2 pour admettre un témoin, reçu {p!r}."
        )
    ax = abs(p.x)
    ay = abs(p.y)
    pi_a, pi_c = (1, 1) if (ax == 0 or ay == 0) else (ax, ay)
    return PredictiveEngineState(
        discrepancy=SalientDiscrepancy(magnitude=2, sensory_threshold=1, resorption_threshold=1),
        perceptive=PerceptiveInterface(controle_gradient=Polarity.from_int(p.y)),
        subjective=SubjectiveInterface(
            attente_gradient=Polarity.from_int(p.x),
            descending_suspension=True,
        ),
        attentional=AttentionalInterface(
            allocated_precision=1,
            engagement_threshold=1,
            persistence_depth=p.z - 2,
            precision_a=pi_a,
            precision_c=pi_c,
        ),
    )


def dissipation_step(p: CoreAffectPoint) -> CoreAffectPoint:
    """Opérateur de dissipation allostatique pas à pas (avec court-circuit en ``Z = 2``)."""
    if p.x != 0 or p.y != 0:
        return CoreAffectPoint(0, 0, p.z)
    if p.z <= 2:
        return CoreAffectPoint(0, 0, 0)
    return CoreAffectPoint(0, 0, p.z - 1)


def dissipation_potential(p: CoreAffectPoint) -> int:
    """Potentiel de Lyapunov discret ``2 * Z + [p périphérique]``."""
    return 2 * p.z + (1 if (p.x != 0 or p.y != 0) else 0)


def allostatic_step(d: SalientDiscrepancy, p: CoreAffectPoint) -> CoreAffectPoint:
    """Transition allostatique couplée au seuil de résorption (hystérésis)."""
    if d.magnitude < d.resorption_threshold:
        return dissipation_step(p)
    return p


__all__ = [
    "ALL_COUPLINGS",
    "CentralOperator",
    "CoreAffectPoint",
    "CoreAffectState",
    "EngineCoupling",
    "GeometryType",
    "OrientationSector",
    "Polarity",
    "PredictiveEngineState",
    "ResourceRegime",
    "allostatic_step",
    "apply_budget_constraint",
    "apportion_ray",
    "crown_radius",
    "deploy_coupling_at_depth",
    "deploy_coupling_with_precision",
    "dissipation_potential",
    "dissipation_step",
    "engine_step",
    "evaluate_core_affect",
    "is_valid_core_affect",
    "is_valid_core_affect_in",
    "project_to_core_affect",
    "signed_amplitude",
    "trigger_secondary_gradient",
    "witness_engine_for_point",
]
