"""Répertoire canonique des 176 entrées CARTOGRAFFECT (isomorphe à `Cartograffect/Lexicon176.lean`).

Expose le lexique complet des 176 états affectifs (Point de Veille en ``Z = 0``,
7 opérateurs centraux de Surprise à Suspension en ``Z = 1..7``, et 168 positions
périphériques de ``Z = 2`` à ``Z = 7``), chargé depuis ``data/lexicon_176.json``,
ainsi que les prédicats et générateurs de grille géométrique de `Lexicon176.lean`.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from .affective_matrix import (
    EnergyRegime,
    HedonicPolarity,
    PhenomenologicalActivation,
)
from .affective_taxonomy import (
    FunctionalSubsector,
    TaxonomicGroup,
    TaxonomicStratum,
    classify_stratum,
)
from .core_affect import (
    CoreAffectPoint,
    GeometryType,
    OrientationSector,
    crown_radius,
)

ORIENTATION_SECTORS: tuple[str, ...] = (
    "JOIE",
    "TRISTESSE",
    "PEUR",
    "COURAGE",
    "COLERE",
    "CALME",
    "DESIR",
    "DEGOUT",
)

DEFAULT_LEXICON_JSON_PATH: Path = (
    Path(__file__).resolve().parents[2] / "data" / "lexicon_176.json"
)


@dataclass(frozen=True)
class LexiconEntry:
    """Entrée canonique du lexique des 176 positions affectives."""

    id: int
    label: str
    point: CoreAffectPoint
    geometry_type: GeometryType
    orientation_sector: str | None
    taxonomic_group: TaxonomicGroup
    dominant_sector: OrientationSector | None
    subsector: FunctionalSubsector
    stratum: TaxonomicStratum
    energy_regime: EnergyRegime
    valence: HedonicPolarity
    activation: PhenomenologicalActivation
    antagonist_label: str
    antagonist_point: CoreAffectPoint

    @property
    def x(self) -> int:
        """Coordonnée X (Attente)."""
        return self.point.x

    @property
    def y(self) -> int:
        """Coordonnée Y (Contrôle)."""
        return self.point.y

    @property
    def z(self) -> int:
        """Coordonnée Z (Profondeur)."""
        return self.point.z

    @property
    def l1_radius(self) -> int:
        """Distance de Manhattan ``|X| + |Y|``."""
        return self.point.displacement_sum()


def is_valid_point_bool(p: CoreAffectPoint) -> bool:
    """Fonction décidable vérifiant la conformité géométrique d'un point (centre ou couronne)."""
    return (p.x == 0 and p.y == 0) or (
        p.z >= 2 and p.displacement_sum() == crown_radius(p.z)
    )


def sign_variants(ax: int, ay: int, z: int) -> list[CoreAffectPoint]:
    """Génère les 4 combinaisons de signes ``(±ax, ±ay, z)`` pour un couple d'amplitudes."""
    return [
        CoreAffectPoint(ax, ay, z),
        CoreAffectPoint(ax, -ay, z),
        CoreAffectPoint(-ax, ay, z),
        CoreAffectPoint(-ax, -ay, z),
    ]


def stratum_valid_grid(z: int) -> list[CoreAffectPoint]:
    """Grille géométrique complète des positions admissibles (centre et couronne) en strate ``z``."""
    r = crown_radius(z)
    pts = [CoreAffectPoint(0, 0, z)]
    for ax in range(r + 1):
        pts.extend(sign_variants(ax, r - ax, z))
    return list(dict.fromkeys(pts))


def _parse_entry(raw: dict) -> LexiconEntry:
    pt = CoreAffectPoint(int(raw["x"]), int(raw["y"]), int(raw["z"]))
    ant_raw = raw["antagonist"]
    ant_pt = CoreAffectPoint(int(ant_raw["x"]), int(ant_raw["y"]), int(ant_raw["z"]))
    dom = raw["dominant_sector"]
    return LexiconEntry(
        id=int(raw["id"]),
        label=str(raw["label"]),
        point=pt,
        geometry_type=GeometryType(raw["geometry_type"]),
        orientation_sector=raw["orientation_sector"],
        taxonomic_group=TaxonomicGroup(raw["taxonomic_group"]),
        dominant_sector=OrientationSector(dom) if dom is not None else None,
        subsector=FunctionalSubsector(raw["subsector"]),
        stratum=classify_stratum(pt.z),
        energy_regime=EnergyRegime(raw["energy_regime"]),
        valence=HedonicPolarity(raw["valence"]),
        activation=PhenomenologicalActivation(raw["activation"]),
        antagonist_label=str(ant_raw["label"]),
        antagonist_point=ant_pt,
    )


def load_lexicon_entries(json_path: Path | None = None) -> tuple[LexiconEntry, ...]:
    """Charge l'intégralité des 176 entrées canoniques depuis ``data/lexicon_176.json``."""
    target = json_path if json_path is not None else DEFAULT_LEXICON_JSON_PATH
    payload = json.loads(target.read_text(encoding="utf-8"))
    return tuple(_parse_entry(raw) for raw in payload["entries"])


ALL_176_ENTRIES: tuple[LexiconEntry, ...] = load_lexicon_entries()
ENTRY_BY_POINT: dict[CoreAffectPoint, LexiconEntry] = {
    entry.point: entry for entry in ALL_176_ENTRIES
}
ENTRY_BY_LABEL: dict[str, LexiconEntry] = {
    entry.label: entry for entry in ALL_176_ENTRIES
}


def get_entry_by_point(point: CoreAffectPoint) -> LexiconEntry:
    """Retourne l'entrée du lexique correspondant exactement aux coordonnées ``point``."""
    return ENTRY_BY_POINT[point]


def get_entry_by_label(label: str) -> LexiconEntry:
    """Retourne l'entrée du lexique portant le libellé exact ``label``."""
    return ENTRY_BY_LABEL[label]


def get_antagonist_entry(
    target: LexiconEntry | CoreAffectPoint | str,
) -> LexiconEntry:
    """Retourne l'entrée antagoniste canonique pour une entrée, un point ou un libellé."""
    if isinstance(target, LexiconEntry):
        entry = target
    elif isinstance(target, CoreAffectPoint):
        entry = ENTRY_BY_POINT[target]
    elif isinstance(target, str):
        entry = ENTRY_BY_LABEL[target]
    else:
        raise TypeError(f"Type non supporté pour get_antagonist_entry : {type(target)!r}")
    return ENTRY_BY_POINT[entry.antagonist_point]


__all__ = [
    "ALL_176_ENTRIES",
    "DEFAULT_LEXICON_JSON_PATH",
    "ENTRY_BY_LABEL",
    "ENTRY_BY_POINT",
    "ORIENTATION_SECTORS",
    "LexiconEntry",
    "get_antagonist_entry",
    "get_entry_by_label",
    "get_entry_by_point",
    "is_valid_point_bool",
    "load_lexicon_entries",
    "sign_variants",
    "stratum_valid_grid",
]

