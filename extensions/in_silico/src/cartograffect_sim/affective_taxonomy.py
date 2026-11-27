"""Taxonomie affective hiérarchique CARTOGRAFFECT (isomorphe à `Cartograffect/AffectiveTaxonomy.lean`).

Implémente la couche terminale de classification et de cohérence :
- Strates hiérarchiques ``Z = 0..7`` et prolongement ``Z >= 8`` (`TaxonomicStratum`,
  `classify_stratum`) ;
- Les 9 groupes structurels d'orientation (`TaxonomicGroup`), prédicat d'appartenance
  (`matches_taxonomic_group`) et classificateur total (`classify_taxonomic_group`) ;
- Les 17 sous-secteurs fonctionnels (`FunctionalSubsector`), raffinant les groupes
  et déterminant la polarité hédonique (`classify_subsector`, `matches_subsector`) ;
- Loi combinatoire des effectifs (`crown_peripheral_count`, `stratum_total_count`)
  certifiant les 176 états (`8` centres + `168` positions périphériques) ;
- Pipeline complet `run_cartograffect_pipeline` (`PredictiveEngine -> CoreAffect ->
  AffectiveMatrix -> AffectiveTaxonomy`) et prédicat de cohérence à 18 clauses
  `is_coherent_terminal_state` (théorème maître `end_to_end_coherence`) ;
- Réexportation directe de l'opérateur d'antagonisme involutif `antagonist_point`.
"""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from enum import Enum

from .affective_matrix import (
    AffectiveMatrixState,
    HedonicPolarity,
    antagonist_point,
    antagonist_point_unified,
    compute_activation,
    compute_energy_regime,
    compute_hedonic_polarity,
    evaluate_matrix,
    transduce_control,
    transduce_expectation,
)
from .core_affect import (
    CoreAffectPoint,
    GeometryType,
    crown_radius,
    evaluate_core_affect,
    is_valid_core_affect,
    project_to_core_affect,
)
from .predictive_engine import PredictiveEngineState


def _require_nat(value: int, name: str) -> None:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise ValueError(f"{name} doit être un entier naturel (Nat >= 0), reçu {value!r}.")


class StratumKind(str, Enum):
    """Identifiants canoniques des strates hiérarchiques sur l'Axe Z."""

    Z0_POINT_DE_VEILLE = "z0_pointDeVeille"
    Z1_SAILLANCE_PERCEPTIVE = "z1_saillancePerceptive"
    Z2_AFFECTS_PRIMAIRES = "z2_affectsPrimaires"
    Z3_EMOTIONS_REACTIVES = "z3_emotionsReactives"
    Z4_SENTIMENTS_REFLEXIFS = "z4_sentimentsReflexifs"
    Z5_ORIENTATIONS_DURABLES = "z5_orientationsDurables"
    Z6_IDENTITES_AFFECTIVES = "z6_identitesAffectives"
    Z7_SENTIMENTS_TRANSCENDANTS = "z7_sentimentsTranscendants"
    Z_DEEP_PROLONGATION = "zDeepProlongation"


@dataclass(frozen=True)
class TaxonomicStratum:
    """Strate hiérarchique indexée sur ``Z`` (``Z = 0..7`` ou prolongement ``Z >= 8``)."""

    kind: StratumKind
    z: int

    def __post_init__(self) -> None:
        _require_nat(self.z, "z")

    @property
    def lean_name(self) -> str:
        """Nom canonique correspondant au constructeur Lean ``TaxonomicStratum``."""
        if self.kind is StratumKind.Z_DEEP_PROLONGATION:
            return f"zDeepProlongation {self.z}"
        return self.kind.value


_FIXED_STRATA: dict[int, TaxonomicStratum] = {
    0: TaxonomicStratum(StratumKind.Z0_POINT_DE_VEILLE, 0),
    1: TaxonomicStratum(StratumKind.Z1_SAILLANCE_PERCEPTIVE, 1),
    2: TaxonomicStratum(StratumKind.Z2_AFFECTS_PRIMAIRES, 2),
    3: TaxonomicStratum(StratumKind.Z3_EMOTIONS_REACTIVES, 3),
    4: TaxonomicStratum(StratumKind.Z4_SENTIMENTS_REFLEXIFS, 4),
    5: TaxonomicStratum(StratumKind.Z5_ORIENTATIONS_DURABLES, 5),
    6: TaxonomicStratum(StratumKind.Z6_IDENTITES_AFFECTIVES, 6),
    7: TaxonomicStratum(StratumKind.Z7_SENTIMENTS_TRANSCENDANTS, 7),
}


def classify_stratum(z: int) -> TaxonomicStratum:
    """Projection de la coordonnée verticale ``z`` vers sa strate taxonomique."""
    _require_nat(z, "z")
    if z in _FIXED_STRATA:
        return _FIXED_STRATA[z]
    return TaxonomicStratum(StratumKind.Z_DEEP_PROLONGATION, z)


class TaxonomicGroup(str, Enum):
    """Les 9 groupes structurels d'orientation de la Taxonomie affective."""

    OPERATEUR_CENTRAL = "operateurCentral"
    GROUPE_JOIE = "groupeJoie"
    GROUPE_TRISTESSE = "groupeTristesse"
    GROUPE_PEUR = "groupePeur"
    GROUPE_COURAGE = "groupeCourage"
    GROUPE_DESIR = "groupeDesir"
    GROUPE_DEGOUT = "groupeDegout"
    GROUPE_COLERE = "groupeColere"
    GROUPE_CALME = "groupeCalme"

    @property
    def orientation_sector(self) -> str | None:
        """Secteur d'orientation canonique (``None`` pour l'opérateur central)."""
        return _GROUP_TO_ORIENTATION_SECTOR[self]


_GROUP_TO_ORIENTATION_SECTOR: dict[TaxonomicGroup, str | None] = {
    TaxonomicGroup.OPERATEUR_CENTRAL: None,
    TaxonomicGroup.GROUPE_JOIE: "JOIE",
    TaxonomicGroup.GROUPE_TRISTESSE: "TRISTESSE",
    TaxonomicGroup.GROUPE_PEUR: "PEUR",
    TaxonomicGroup.GROUPE_COURAGE: "COURAGE",
    TaxonomicGroup.GROUPE_DESIR: "DESIR",
    TaxonomicGroup.GROUPE_DEGOUT: "DEGOUT",
    TaxonomicGroup.GROUPE_COLERE: "COLERE",
    TaxonomicGroup.GROUPE_CALME: "CALME",
}


_GROUP_PREDICATES: dict[TaxonomicGroup, Callable[[CoreAffectPoint], bool]] = {
    TaxonomicGroup.OPERATEUR_CENTRAL: lambda p: p.x == 0 and p.y == 0,
    TaxonomicGroup.GROUPE_JOIE: lambda p: abs(p.y) > abs(p.x) and p.y > 0,
    TaxonomicGroup.GROUPE_TRISTESSE: lambda p: abs(p.y) > abs(p.x) and p.y < 0,
    TaxonomicGroup.GROUPE_PEUR: lambda p: abs(p.x) > abs(p.y) and p.x < 0,
    TaxonomicGroup.GROUPE_COURAGE: lambda p: abs(p.x) > abs(p.y) and p.x > 0,
    TaxonomicGroup.GROUPE_DESIR: lambda p: abs(p.x) == abs(p.y) and p.x > 0 and p.y > 0,
    TaxonomicGroup.GROUPE_DEGOUT: lambda p: abs(p.x) == abs(p.y) and p.x < 0 and p.y < 0,
    TaxonomicGroup.GROUPE_COLERE: lambda p: abs(p.x) == abs(p.y) and p.x < 0 and p.y > 0,
    TaxonomicGroup.GROUPE_CALME: lambda p: abs(p.x) == abs(p.y) and p.x > 0 and p.y < 0,
}


def matches_taxonomic_group(p: CoreAffectPoint, group: TaxonomicGroup) -> bool:
    """Prédicat formel d'appartenance de ``p`` au groupe taxonomique ``group``."""
    return _GROUP_PREDICATES[group](p)


def classify_taxonomic_group(p: CoreAffectPoint) -> TaxonomicGroup:
    """Fonction déterministe assignant à tout point son unique groupe taxonomique."""
    if p.x == 0 and p.y == 0:
        return TaxonomicGroup.OPERATEUR_CENTRAL
    if abs(p.y) > abs(p.x):
        return TaxonomicGroup.GROUPE_JOIE if p.y > 0 else TaxonomicGroup.GROUPE_TRISTESSE
    if abs(p.x) > abs(p.y):
        return TaxonomicGroup.GROUPE_PEUR if p.x < 0 else TaxonomicGroup.GROUPE_COURAGE
    if p.x > 0:
        return TaxonomicGroup.GROUPE_DESIR if p.y > 0 else TaxonomicGroup.GROUPE_CALME
    return TaxonomicGroup.GROUPE_COLERE if p.y > 0 else TaxonomicGroup.GROUPE_DEGOUT


class FunctionalSubsector(str, Enum):
    """Les 17 sous-secteurs fonctionnels affinant l'orientation géométrique et la valence."""

    CENTRAL_OPERATOR = "centralOperator"
    AXIAL_ELAN = "axialElan"
    AXIAL_WITHDRAWAL = "axialWithdrawal"
    AXIAL_OPENING = "axialOpening"
    AXIAL_THREAT = "axialThreat"
    DIAGONAL_DESIRE = "diagonalDesire"
    DIAGONAL_DISGUST = "diagonalDisgust"
    DIAGONAL_ANGER = "diagonalAnger"
    DIAGONAL_CALM = "diagonalCalm"
    LATERAL_APPROACH_SYNERGY = "lateralApproachSynergy"
    LATERAL_DEFENSIVE_URGENCY = "lateralDefensiveUrgency"
    LATERAL_TROPHOTROPIC_PEACE = "lateralTrophotropicPeace"
    LATERAL_AVERSIVE_DISTRESS = "lateralAversiveDistress"
    LATERAL_EPISTEMIC_MASTERY = "lateralEpistemicMastery"
    LATERAL_CONTEMPLATIVE_OPEN = "lateralContemplativeOpen"
    LATERAL_VIGILANT_ALERT = "lateralVigilantAlert"
    LATERAL_EPISTEMIC_CLOSURE = "lateralEpistemicClosure"

    def to_taxonomic_group(self) -> TaxonomicGroup:
        """Projection canonique du sous-secteur vers son ``TaxonomicGroup``."""
        return _SUBSECTOR_TO_GROUP[self]

    def to_hedonic_polarity(self) -> HedonicPolarity:
        """Projection canonique du sous-secteur vers sa polarité hédonique."""
        return _SUBSECTOR_TO_VALENCE[self]


_SUBSECTOR_TO_GROUP: dict[FunctionalSubsector, TaxonomicGroup] = {
    FunctionalSubsector.CENTRAL_OPERATOR: TaxonomicGroup.OPERATEUR_CENTRAL,
    FunctionalSubsector.AXIAL_ELAN: TaxonomicGroup.GROUPE_JOIE,
    FunctionalSubsector.LATERAL_APPROACH_SYNERGY: TaxonomicGroup.GROUPE_JOIE,
    FunctionalSubsector.LATERAL_DEFENSIVE_URGENCY: TaxonomicGroup.GROUPE_JOIE,
    FunctionalSubsector.AXIAL_WITHDRAWAL: TaxonomicGroup.GROUPE_TRISTESSE,
    FunctionalSubsector.LATERAL_TROPHOTROPIC_PEACE: TaxonomicGroup.GROUPE_TRISTESSE,
    FunctionalSubsector.LATERAL_AVERSIVE_DISTRESS: TaxonomicGroup.GROUPE_TRISTESSE,
    FunctionalSubsector.AXIAL_OPENING: TaxonomicGroup.GROUPE_COURAGE,
    FunctionalSubsector.LATERAL_EPISTEMIC_MASTERY: TaxonomicGroup.GROUPE_COURAGE,
    FunctionalSubsector.LATERAL_CONTEMPLATIVE_OPEN: TaxonomicGroup.GROUPE_COURAGE,
    FunctionalSubsector.AXIAL_THREAT: TaxonomicGroup.GROUPE_PEUR,
    FunctionalSubsector.LATERAL_VIGILANT_ALERT: TaxonomicGroup.GROUPE_PEUR,
    FunctionalSubsector.LATERAL_EPISTEMIC_CLOSURE: TaxonomicGroup.GROUPE_PEUR,
    FunctionalSubsector.DIAGONAL_DESIRE: TaxonomicGroup.GROUPE_DESIR,
    FunctionalSubsector.DIAGONAL_DISGUST: TaxonomicGroup.GROUPE_DEGOUT,
    FunctionalSubsector.DIAGONAL_ANGER: TaxonomicGroup.GROUPE_COLERE,
    FunctionalSubsector.DIAGONAL_CALM: TaxonomicGroup.GROUPE_CALME,
}

_SUBSECTOR_TO_VALENCE: dict[FunctionalSubsector, HedonicPolarity] = {
    FunctionalSubsector.CENTRAL_OPERATOR: HedonicPolarity.NEUTRAL,
    FunctionalSubsector.AXIAL_ELAN: HedonicPolarity.POSITIVE,
    FunctionalSubsector.AXIAL_OPENING: HedonicPolarity.POSITIVE,
    FunctionalSubsector.DIAGONAL_DESIRE: HedonicPolarity.POSITIVE,
    FunctionalSubsector.DIAGONAL_CALM: HedonicPolarity.POSITIVE,
    FunctionalSubsector.LATERAL_APPROACH_SYNERGY: HedonicPolarity.POSITIVE,
    FunctionalSubsector.LATERAL_TROPHOTROPIC_PEACE: HedonicPolarity.POSITIVE,
    FunctionalSubsector.LATERAL_EPISTEMIC_MASTERY: HedonicPolarity.POSITIVE,
    FunctionalSubsector.LATERAL_CONTEMPLATIVE_OPEN: HedonicPolarity.POSITIVE,
    FunctionalSubsector.AXIAL_WITHDRAWAL: HedonicPolarity.NEGATIVE,
    FunctionalSubsector.AXIAL_THREAT: HedonicPolarity.NEGATIVE,
    FunctionalSubsector.DIAGONAL_DISGUST: HedonicPolarity.NEGATIVE,
    FunctionalSubsector.DIAGONAL_ANGER: HedonicPolarity.NEGATIVE,
    FunctionalSubsector.LATERAL_DEFENSIVE_URGENCY: HedonicPolarity.NEGATIVE,
    FunctionalSubsector.LATERAL_AVERSIVE_DISTRESS: HedonicPolarity.NEGATIVE,
    FunctionalSubsector.LATERAL_VIGILANT_ALERT: HedonicPolarity.NEGATIVE,
    FunctionalSubsector.LATERAL_EPISTEMIC_CLOSURE: HedonicPolarity.NEGATIVE,
}

_SUBSECTOR_PREDICATES: dict[FunctionalSubsector, Callable[[int, int], bool]] = {
    FunctionalSubsector.CENTRAL_OPERATOR: lambda x, y: x == 0 and y == 0,
    FunctionalSubsector.AXIAL_ELAN: lambda x, y: x == 0 and y > 0,
    FunctionalSubsector.AXIAL_WITHDRAWAL: lambda x, y: x == 0 and y < 0,
    FunctionalSubsector.AXIAL_OPENING: lambda x, y: x > 0 and y == 0,
    FunctionalSubsector.AXIAL_THREAT: lambda x, y: x < 0 and y == 0,
    FunctionalSubsector.DIAGONAL_DESIRE: lambda x, y: x == y and x > 0,
    FunctionalSubsector.DIAGONAL_DISGUST: lambda x, y: x == y and x < 0,
    FunctionalSubsector.DIAGONAL_ANGER: lambda x, y: x == -y and x < 0,
    FunctionalSubsector.DIAGONAL_CALM: lambda x, y: x == -y and x > 0,
    FunctionalSubsector.LATERAL_APPROACH_SYNERGY: lambda x, y: y > abs(x) and x > 0,
    FunctionalSubsector.LATERAL_DEFENSIVE_URGENCY: lambda x, y: y > abs(x) and x < 0,
    FunctionalSubsector.LATERAL_TROPHOTROPIC_PEACE: lambda x, y: -y > abs(x) and x > 0,
    FunctionalSubsector.LATERAL_AVERSIVE_DISTRESS: lambda x, y: -y > abs(x) and x < 0,
    FunctionalSubsector.LATERAL_EPISTEMIC_MASTERY: lambda x, y: x > abs(y) and y > 0,
    FunctionalSubsector.LATERAL_CONTEMPLATIVE_OPEN: lambda x, y: x > abs(y) and y < 0,
    FunctionalSubsector.LATERAL_VIGILANT_ALERT: lambda x, y: -x > abs(y) and y > 0,
    FunctionalSubsector.LATERAL_EPISTEMIC_CLOSURE: lambda x, y: -x > abs(y) and y < 0,
}


def matches_subsector(x: int, y: int, subsector: FunctionalSubsector) -> bool:
    """Prédicat formel d'appartenance d'un couple ``(x, y)`` à un sous-secteur."""
    return _SUBSECTOR_PREDICATES[subsector](x, y)


def classify_subsector(x: int, y: int) -> FunctionalSubsector:
    """Classification fonctionnelle fine de toute coordonnée ``(X, Y)``."""
    for subsector, pred in _SUBSECTOR_PREDICATES.items():
        if pred(x, y):
            return subsector
    raise AssertionError(f"Partition des sous-secteurs non exhaustive pour ({x}, {y}).")


def crown_peripheral_count(z: int) -> int:
    """Effectif des positions périphériques sur la couronne de la strate ``z``."""
    _require_nat(z, "z")
    return 4 * crown_radius(z)


def stratum_total_count(z: int) -> int:
    """Effectif total d'une strate ``z`` (1 opérateur central + positions périphériques)."""
    _require_nat(z, "z")
    return 1 + crown_peripheral_count(z)


@dataclass(frozen=True)
class TaxonomicState:
    """Entrée terminale de la Taxonomie affective hiérarchique."""

    matrix: AffectiveMatrixState
    stratum: TaxonomicStratum
    geometry: GeometryType
    group: TaxonomicGroup
    subsector: FunctionalSubsector
    antagonist_group: TaxonomicGroup
    antagonist_subsector: FunctionalSubsector


def evaluate_taxonomy(ms: AffectiveMatrixState) -> TaxonomicState:
    """Projection d'un état de la Matrice affective dans la Taxonomie hiérarchique."""
    p = ms.core.point
    ap = ms.antagonist.point
    return TaxonomicState(
        matrix=ms,
        stratum=classify_stratum(p.z),
        geometry=p.classify_geometry(),
        group=classify_taxonomic_group(p),
        subsector=classify_subsector(p.x, p.y),
        antagonist_group=classify_taxonomic_group(ap),
        antagonist_subsector=classify_subsector(ap.x, ap.y),
    )


def run_cartograffect_pipeline(s: PredictiveEngineState) -> TaxonomicState:
    """Pipeline déterministe complet ``PredictiveEngine -> CoreAffect -> Matrix -> Taxonomy``."""
    return evaluate_taxonomy(evaluate_matrix(evaluate_core_affect(s)))


def is_coherent_terminal_state(s: PredictiveEngineState, ts: TaxonomicState) -> bool:
    """Prédicat de cohérence intégrale à 18 clauses du théorème maître ``end_to_end_coherence``."""
    cp = ts.matrix.core.point
    ap = ts.matrix.antagonist.point
    clauses = (
        cp == project_to_core_affect(s),
        is_valid_core_affect(cp),
        ap == antagonist_point(cp),
        is_valid_core_affect(ap),
        ap.z == cp.z,
        ap.displacement_sum() == cp.displacement_sum(),
        ts.matrix.expectation_pole == transduce_expectation(cp.x),
        ts.matrix.control_pole == transduce_control(cp.y),
        ts.matrix.energy_regime == compute_energy_regime(cp.x, cp.y),
        ts.matrix.valence == compute_hedonic_polarity(cp.x, cp.y),
        ts.matrix.activation == compute_activation(cp),
        ts.stratum == classify_stratum(cp.z),
        ts.geometry == cp.classify_geometry(),
        ts.subsector == classify_subsector(cp.x, cp.y),
        ts.antagonist_subsector == classify_subsector(ap.x, ap.y),
        matches_taxonomic_group(cp, ts.group),
        all((g == ts.group) for g in TaxonomicGroup if matches_taxonomic_group(cp, g)),
        matches_taxonomic_group(ap, ts.antagonist_group),
    )
    return all(clauses)


__all__ = [
    "FunctionalSubsector",
    "StratumKind",
    "TaxonomicGroup",
    "TaxonomicState",
    "TaxonomicStratum",
    "antagonist_point",
    "antagonist_point_unified",
    "classify_stratum",
    "classify_subsector",
    "classify_taxonomic_group",
    "crown_peripheral_count",
    "evaluate_matrix",
    "evaluate_taxonomy",
    "is_coherent_terminal_state",
    "matches_subsector",
    "matches_taxonomic_group",
    "run_cartograffect_pipeline",
    "stratum_total_count",
]
