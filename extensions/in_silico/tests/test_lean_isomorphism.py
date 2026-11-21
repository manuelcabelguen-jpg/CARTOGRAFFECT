"""Suite d'audit isomorphe Lean 4 -> pytest (`Cartograffect/AuditTests.lean`).

Vérifie en Python l'ensemble des invariants géométriques, algébriques et de
cohérence de bout en bout certifiés sous Lean 4.35.0 dans le dépôt formel
`CARTOGRAFFECT` (v1.0.1) :
1. Les 17 théorèmes principaux certifiés (8 purement constructifs + 9 structurels) ;
2. Les théorèmes complémentaires des 6 modules (`PredictiveEngine`, `CoreAffect`,
   `AffectiveMatrix`, `AffectiveTaxonomy`, `Lexicon176`, `AuditTests`, dont le
   théorème 18 et les résolutions R3, R5, R8) ;
3. Les témoins concrets `#eval` de la Phase 2 d'`AuditTests.lean` et l'intégrité
   du lexique canonique (`data/lexicon_176.json`).
"""

from __future__ import annotations

import json
import re
from collections import Counter
from itertools import product
from pathlib import Path

import pytest

from cartograffect_sim.affective_matrix import (
    CANONICAL_MAPPING,
    EnergyRegime,
    HedonicPolarity,
    LivedControlPole,
    LivedExpectationPole,
    PhenomenologicalActivation,
    PhenomenologicalMapping,
    PrimaryCrownPrototype,
    antagonist_point,
    antagonist_point_unified,
    compute_activation,
    compute_energy_regime,
    compute_hedonic_polarity,
    compute_valence,
    evaluate_matrix,
    transfer_unit_x_to_y,
    transfer_unit_y_to_x,
)
from cartograffect_sim.affective_taxonomy import (
    FunctionalSubsector,
    StratumKind,
    TaxonomicGroup,
    TaxonomicState,
    TaxonomicStratum,
    classify_stratum,
    classify_subsector,
    classify_taxonomic_group,
    crown_peripheral_count,
    evaluate_taxonomy,
    is_coherent_terminal_state,
    matches_subsector,
    matches_taxonomic_group,
    run_cartograffect_pipeline,
    stratum_total_count,
)
from cartograffect_sim.core_affect import (
    CentralOperator,
    CoreAffectPoint,
    CoreAffectState,
    GeometryType,
    OrientationSector,
    ResourceRegime,
    allostatic_step,
    apportion_ray,
    crown_radius,
    deploy_coupling_at_depth,
    deploy_coupling_with_precision,
    dissipation_potential,
    dissipation_step,
    evaluate_core_affect,
    is_valid_core_affect,
    is_valid_core_affect_in,
    project_to_core_affect,
    trigger_secondary_gradient,
    witness_engine_for_point,
)
from cartograffect_sim.lexicon_176 import (
    ALL_176_ENTRIES,
    DEFAULT_LEXICON_JSON_PATH,
    ENTRY_BY_LABEL,
    ENTRY_BY_POINT,
    ORIENTATION_SECTORS,
    get_antagonist_entry,
    is_valid_point_bool,
    stratum_valid_grid,
)
from cartograffect_sim.predictive_engine import (
    ALL_COUPLINGS,
    AttentionalInterface,
    EngineCoupling,
    EngineInterface,
    FunctionalRegime,
    InferentialOperation,
    PerceptiveInterface,
    Polarity,
    PredictiveEngineState,
    SalientDiscrepancy,
    SubjectiveInterface,
    engine_step,
)

# ---------------------------------------------------------------------------
# Générateurs d'états / grilles pour vérification exhaustive finie
# ---------------------------------------------------------------------------


def _sample_engine_states() -> list[PredictiveEngineState]:
    """Construit un échantillon représentatif couvrant toutes les branches de `projectToCoreAffect`."""
    states: list[PredictiveEngineState] = [PredictiveEngineState()]
    discrepancies = [
        SalientDiscrepancy(magnitude=0, sensory_threshold=2, resorption_threshold=1),
        SalientDiscrepancy(magnitude=1, sensory_threshold=2, resorption_threshold=1),
        SalientDiscrepancy(magnitude=5, sensory_threshold=2, resorption_threshold=1),
    ]
    precisions = [
        (0, 2, 1, 1),
        (2, 2, 1, 1),
        (5, 2, 1, 3),
        (5, 2, 3, 1),
        (5, 2, 4, 2),
    ]
    for disc in discrepancies:
        for coupling in ALL_COUPLINGS:
            for susp in (False, True):
                for depth in (0, 1, 3, 5):
                    for alloc, thresh, pa, pc in precisions:
                        states.append(
                            PredictiveEngineState(
                                discrepancy=disc,
                                perceptive=PerceptiveInterface(controle_gradient=coupling.controle),
                                subjective=SubjectiveInterface(
                                    attente_gradient=coupling.attente,
                                    descending_suspension=susp,
                                ),
                                attentional=AttentionalInterface(
                                    allocated_precision=alloc,
                                    engagement_threshold=thresh,
                                    persistence_depth=depth,
                                    precision_a=pa,
                                    precision_c=pc,
                                ),
                            )
                        )
    # Ajoute les 176 témoins exacts du lexique
    for entry in ALL_176_ENTRIES:
        states.append(witness_engine_for_point(entry.point))
    return states


def _all_valid_points_up_to(max_z: int = 7) -> list[CoreAffectPoint]:
    pts: list[CoreAffectPoint] = []
    seen: set[CoreAffectPoint] = set()
    for z in range(max_z + 1):
        for p in stratum_valid_grid(z):
            if p not in seen:
                seen.add(p)
                pts.append(p)
    return pts


def _grid_points_sample() -> list[CoreAffectPoint]:
    """Grille finie étendue couvrant axes, diagonales, latérales et points hors couronne."""
    pts: list[CoreAffectPoint] = [e.point for e in ALL_176_ENTRIES]
    for x in range(-6, 7):
        for y in range(-6, 7):
            for z in (0, 1, 2, 3, 5, 8):
                pts.append(CoreAffectPoint(x, y, z))
    return pts


# ===========================================================================
# SECTION 1 : LES 17 THÉORÈMES PRINCIPAUX CERTIFIÉS DANS AuditTests.lean
# ===========================================================================


def test_thm_01_polarity_invert_involutive() -> None:
    """Théorème 1 (`Polarity.invert_involutive`) : `p.invert.invert = p`."""
    for p in Polarity:
        assert p.invert().invert() is p


def test_thm_02_coupling_regime_partition() -> None:
    """Théorème 2 (`coupling_regime_partition`, `allCouplings_card`, `mem_allCouplings`)."""
    assert len(ALL_COUPLINGS) == 9
    assert len(set(ALL_COUPLINGS)) == 9
    for a, ctrl in product(Polarity, Polarity):
        c = EngineCoupling(attente=a, controle=ctrl)
        assert c in ALL_COUPLINGS
        flags = (
            c.is_global_neutrality(),
            c.is_single_engaged(),
            c.is_dual_engaged(),
        )
        assert sum(flags) == 1


def test_thm_03_z2_budget_conservation() -> None:
    """Théorème 3 (`z2_budget_conservation`) : en Z = 2, tout couplage non neutre vérifie `|X| + |Y| = 2`."""
    for c in ALL_COUPLINGS:
        if not c.is_global_neutrality():
            pt = deploy_coupling_at_depth(c, 0)
            assert pt.z == 2
            assert pt.displacement_sum() == 2


def test_thm_04_contralateral_swaps_amplitudes() -> None:
    """Théorème 4 (`contralateral_swaps_amplitudes`) : permutation des amplitudes pour `|X| != |Y|`."""
    lateral_entries = [e for e in ALL_176_ENTRIES if e.geometry_type is GeometryType.LATERAL]
    assert len(lateral_entries) == 120
    extra_laterals = [
        CoreAffectPoint(x, y, z)
        for x in range(-8, 9)
        for y in range(-8, 9)
        for z in (3, 4, 7, 9)
        if x != 0 and y != 0 and abs(x) != abs(y)
    ]
    for p in [e.point for e in lateral_entries] + extra_laterals:
        assert p.x != 0 and p.y != 0 and abs(p.x) != abs(p.y)
        ant = antagonist_point(p)
        assert abs(ant.x) == abs(p.y)
        assert abs(ant.y) == abs(p.x)
        assert ant.z == p.z
        assert ant.classify_geometry() is GeometryType.LATERAL


def test_thm_05_inventory_176_certified() -> None:
    """Théorème 5 (`inventory_176_certified`) : effectifs combinatoires 8..48 -> 168 + 8 = 176."""
    assert crown_peripheral_count(0) == 0
    assert crown_peripheral_count(1) == 0
    expected_periph = {2: 8, 3: 16, 4: 24, 5: 32, 6: 40, 7: 48}
    for z, expected in expected_periph.items():
        assert crown_peripheral_count(z) == expected
    assert sum(crown_peripheral_count(z) for z in range(2, 8)) == 168
    assert sum(stratum_total_count(z) for z in range(8)) == 176


def test_thm_06_all176_entries_length() -> None:
    """Théorème 6 (`all176Entries_length`) : cardinalité exacte de 176 entrées."""
    assert len(ALL_176_ENTRIES) == 176


def test_thm_07_all176_entries_unique_points() -> None:
    """Théorème 7 (`all176Entries_unique_points`) : absence totale de collision spatiale."""
    points = [e.point for e in ALL_176_ENTRIES]
    labels = [e.label for e in ALL_176_ENTRIES]
    assert len(set(points)) == 176
    assert len(set(labels)) == 176


def test_thm_08_all176_entries_closed_under_antagonist() -> None:
    """Théorème 8 (`all176Entries_closed_under_antagonist`) : clôture intégrale du lexique."""
    point_set = set(ENTRY_BY_POINT.keys())
    for entry in ALL_176_ENTRIES:
        ant = antagonist_point(entry.point)
        assert ant in point_set
        assert ant == entry.antagonist_point
        ant_entry = get_antagonist_entry(entry)
        assert ant_entry.label == entry.antagonist_label
        assert ant_entry.antagonist_point == entry.point


def test_thm_09_engine_induces_valid_core_affect() -> None:
    """Théorème 9 (`engine_induces_valid_core_affect`) : tout état moteur induit un `CoreAffectState` valide."""
    for state in _sample_engine_states():
        pt = project_to_core_affect(state)
        assert is_valid_core_affect(pt)
        cs = evaluate_core_affect(state)
        assert cs.point == pt
    with pytest.raises(ValueError):
        CoreAffectState(point=CoreAffectPoint(1, 0, 2))


def test_thm_10_taxonomy_group_exclusive() -> None:
    """Théorème 10 (`taxonomy_group_exclusive`) : disjonction mutuelle des 9 groupes taxonomiques."""
    for p in _grid_points_sample():
        matching = [g for g in TaxonomicGroup if matches_taxonomic_group(p, g)]
        assert len(matching) <= 1


def test_thm_11_axial_to_diagonal_reallocation() -> None:
    """Théorème 11 (`axial_to_diagonal_reallocation`) : réallocation axiale -> diagonale en Z = 2."""
    for c in ALL_COUPLINGS:
        if c.is_single_engaged():
            for new_pol in Polarity:
                if new_pol.is_engaged():
                    c_next = trigger_secondary_gradient(c, new_pol)
                    pt = deploy_coupling_at_depth(c_next, 0)
                    assert pt.classify_geometry() is GeometryType.DIAGONAL
                    assert pt.displacement_sum() == 2


def test_thm_12_dissipation_step_valid() -> None:
    """Théorème 12 (`dissipationStep_valid`) : tout pas de dissipation produit un état valide."""
    for p in _grid_points_sample():
        dp = dissipation_step(p)
        assert is_valid_core_affect(dp)
        assert dp.is_central()


def test_thm_13_antagonist_point_preserves_validity() -> None:
    """Théorème 13 (`antagonistPoint_preserves_validity`) : préservation de `isValidCoreAffect`."""
    for p in _all_valid_points_up_to(7):
        assert is_valid_core_affect(p)
        ant = antagonist_point(p)
        assert is_valid_core_affect(ant)
        assert ant.z == p.z
        assert ant.displacement_sum() == p.displacement_sum()


def test_thm_14_antagonist_point_involutive() -> None:
    """Théorème 14 (`antagonistPoint_involutive`, `antagonistPoint_fixed_iff_central`)."""
    for p in _grid_points_sample():
        assert antagonist_point(antagonist_point(p)) == p
        assert (antagonist_point(p) == p) is p.is_central()


def test_thm_15_taxonomy_group_exhaustive() -> None:
    """Théorème 15 (`taxonomy_group_exhaustive`, `classifyTaxonomicGroup_correct`)."""
    for p in _grid_points_sample():
        g = classify_taxonomic_group(p)
        assert matches_taxonomic_group(p, g)
        assert any(matches_taxonomic_group(p, grp) for grp in TaxonomicGroup)


def test_thm_16_end_to_end_coherence() -> None:
    """Théorème 16 (`end_to_end_coherence`) : cohérence intégrale (18 clauses) et unicité."""
    for state in _sample_engine_states():
        ts = run_cartograffect_pipeline(state)
        assert is_coherent_terminal_state(state, ts)
        # Vérification d'unicité substantielle : altérer un champ rompt la cohérence
        alt_group = (
            TaxonomicGroup.GROUPE_JOIE
            if ts.group is not TaxonomicGroup.GROUPE_JOIE
            else TaxonomicGroup.OPERATEUR_CENTRAL
        )
        broken = TaxonomicState(
            matrix=ts.matrix,
            stratum=ts.stratum,
            geometry=ts.geometry,
            group=alt_group,
            subsector=ts.subsector,
            antagonist_group=ts.antagonist_group,
            antagonist_subsector=ts.antagonist_subsector,
        )
        assert not is_coherent_terminal_state(state, broken)


def test_thm_17_all176_entries_geometrically_valid() -> None:
    """Théorème 17 (`all176Entries_geometrically_valid`)."""
    for entry in ALL_176_ENTRIES:
        assert is_valid_point_bool(entry.point)
        assert is_valid_core_affect(entry.point)


# ===========================================================================
# SECTION 2 : THÉORÈME 18 & INVARIANTS COMPLÉMENTAIRES DES 6 MODULES LEAN 4
# ===========================================================================


def test_thm_18_all176_antagonist_inverts_hedonic_polarity() -> None:
    """Théorème 18 (`all176Entries_antagonist_inverts_hedonic_polarity` d'AuditTests.lean)."""
    for entry in ALL_176_ENTRIES:
        ant = antagonist_point(entry.point)
        assert compute_hedonic_polarity(ant.x, ant.y) is compute_hedonic_polarity(entry.x, entry.y).invert()


def test_predictive_engine_invariants() -> None:
    """Vérifie les théorèmes additionnels de `PredictiveEngine.lean`."""
    # Polarity.toRegime_neutral_iff
    for p in Polarity:
        assert (p.to_regime() is FunctionalRegime.NEUTRAL) is (p is Polarity.ZERO)

    # single_neutral_not_global_neutral
    c_single = EngineCoupling(attente=Polarity.ZERO, controle=Polarity.POS)
    assert c_single.attente is Polarity.ZERO and not c_single.is_global_neutrality()

    # feedbackUpdate_couples_gradients & feedbackUpdateWeighted_couples_precision
    s0 = PredictiveEngineState(
        discrepancy=SalientDiscrepancy(magnitude=4, sensory_threshold=2, resorption_threshold=1)
    )
    s_fb = s0.feedback_update(Polarity.POS, Polarity.NEG, 7)
    assert s_fb.current_coupling() == EngineCoupling(Polarity.POS, Polarity.NEG)
    assert s_fb.attentional.allocated_precision == 7
    assert s_fb.discrepancy == s0.discrepancy

    s_fbw = s0.feedback_update_weighted(Polarity.NEG, Polarity.POS, 6, 3, 5)
    assert s_fbw.current_coupling() == EngineCoupling(Polarity.NEG, Polarity.POS)
    assert s_fbw.attentional.allocated_precision == 6
    assert s_fbw.attentional.precision_a == 3
    assert s_fbw.attentional.precision_c == 5
    assert s_fbw.discrepancy == s0.discrepancy

    # inferential_loop_covers_interfaces
    covered = {op.carrier_interface() for op in InferentialOperation}
    assert covered == set(EngineInterface)

    # engineStep_remanence
    s_rem = PredictiveEngineState(
        discrepancy=SalientDiscrepancy(magnitude=2, sensory_threshold=3, resorption_threshold=1),
        perceptive=PerceptiveInterface(controle_gradient=Polarity.POS),
        subjective=SubjectiveInterface(attente_gradient=Polarity.NEG, descending_suspension=True),
        attentional=AttentionalInterface(allocated_precision=4, engagement_threshold=2),
    )
    assert s_rem.discrepancy.is_in_remanence_window()
    assert engine_step(s_rem) == s_rem

    # engineStep_phase_progression
    s_start = PredictiveEngineState(
        discrepancy=SalientDiscrepancy(magnitude=5, sensory_threshold=2, resorption_threshold=1),
        perceptive=PerceptiveInterface(controle_gradient=Polarity.ZERO),
        subjective=SubjectiveInterface(attente_gradient=Polarity.ZERO, descending_suspension=False),
        attentional=AttentionalInterface(allocated_precision=0, engagement_threshold=2, persistence_depth=0),
    )
    s1 = engine_step(s_start)
    s2 = engine_step(s1)
    s3 = engine_step(s2)
    assert not s1.current_coupling().is_global_neutrality()
    assert not s1.subjective.descending_suspension and not s1.attentional.is_engaged()
    assert not s2.current_coupling().is_global_neutrality()
    assert s2.subjective.descending_suspension and not s2.attentional.is_engaged()
    assert not s3.current_coupling().is_global_neutrality()
    assert s3.subjective.descending_suspension and s3.attentional.is_engaged()


def test_core_affect_deployment_precision_and_surjectivity() -> None:
    """Vérifie `apportionRay`, R5, R8 (`projectToCoreAffect_surjective`) et `symmetric_precision_never_lateral`."""
    # crownRadius_eq_formula
    for z in range(2, 12):
        assert crown_radius(z) == 2 * z - 2

    # single_engaged / dual_engaged at Z = 2
    for c in ALL_COUPLINGS:
        if c.is_single_engaged():
            assert deploy_coupling_at_depth(c, 0).classify_geometry() is GeometryType.AXIAL
        if c.is_dual_engaged():
            assert deploy_coupling_at_depth(c, 0).classify_geometry() is GeometryType.DIAGONAL
            for pa in range(1, 5):
                for pc in range(1, 5):
                    assert deploy_coupling_with_precision(c, 0, pa, pc).classify_geometry() is GeometryType.DIAGONAL

    # apportionRay_bounds, apportionRay_swap, apportionRay_symm, apportionRay_z2, apportionRay_exact
    for d in range(6):
        r = 2 * d + 2
        assert apportion_ray(0, d + 1, d + 3) == (1, 1)
        assert apportion_ray(d, d + 2, d + 2) == (d + 1, d + 1)
        for pa in range(7):
            for pc in range(7):
                ax, ay = apportion_ray(d, pa, pc)
                assert ax >= 1 and ay >= 1 and ax + ay == r
                assert apportion_ray(d, pc, pa) == (ay, ax)
        for ax in range(1, r):
            ay = r - ax
            assert apportion_ray(d, ax, ay) == (ax, ay)

    # symmetric_precision_never_lateral & 56 vs 176 reachability
    sym_points = set()
    for s in _sample_engine_states():
        if s.attentional.precision_a == s.attentional.precision_c:
            assert project_to_core_affect(s).classify_geometry() is not GeometryType.LATERAL
    for d in range(6):
        for c in ALL_COUPLINGS:
            sym_points.add(deploy_coupling_with_precision(c, d, 1, 1))
    for z in range(8):
        sym_points.add(CoreAffectPoint(0, 0, z))
    assert len(sym_points) == 56  # 8 centraux + 24 axiales + 24 diagonales

    # projectToCoreAffect_surjective & all176Entries_witness_check (176/176)
    for entry in ALL_176_ENTRIES:
        w = witness_engine_for_point(entry.point)
        assert project_to_core_affect(w) == entry.point
        assert run_cartograffect_pipeline(w).matrix.core.point == entry.point


def test_core_affect_suspension_r5_and_dissipation_dynamics() -> None:
    """Vérifie la résolution R5 (`Veille -> Surprise -> Anticipation -> Couronne`) et la dissipation."""
    # neutral_coupling_without_suspension_yields_veille
    s_veille = PredictiveEngineState(
        discrepancy=SalientDiscrepancy(magnitude=5, sensory_threshold=2, resorption_threshold=1),
        perceptive=PerceptiveInterface(controle_gradient=Polarity.ZERO),
        subjective=SubjectiveInterface(attente_gradient=Polarity.ZERO, descending_suspension=False),
    )
    assert project_to_core_affect(s_veille) == CoreAffectPoint(0, 0, 0)

    # central_z_ge2_requires_descending_suspension & engineStep_canonical_trajectory
    s_traj0 = PredictiveEngineState(
        discrepancy=SalientDiscrepancy(magnitude=5, sensory_threshold=2, resorption_threshold=1),
        perceptive=PerceptiveInterface(controle_gradient=Polarity.ZERO),
        subjective=SubjectiveInterface(attente_gradient=Polarity.ZERO, descending_suspension=False),
        attentional=AttentionalInterface(allocated_precision=0, engagement_threshold=2, persistence_depth=0),
    )
    s_traj1 = engine_step(s_traj0)
    s_traj2 = engine_step(s_traj1)
    s_traj3 = engine_step(s_traj2)
    assert project_to_core_affect(s_traj0) == CoreAffectPoint(0, 0, 0)
    assert project_to_core_affect(s_traj1) == CoreAffectPoint(0, 0, 1)
    assert project_to_core_affect(s_traj2) == CoreAffectPoint(0, 0, 2)
    assert project_to_core_affect(s_traj3) == CoreAffectPoint(0, 2, 2)

    # anticipation_short_circuits_to_veille & dissipationPotential_short_circuit_jump
    assert dissipation_step(CoreAffectPoint(0, 0, 2)) == CoreAffectPoint(0, 0, 0)
    assert (
        dissipation_potential(CoreAffectPoint(0, 0, 2))
        - dissipation_potential(dissipation_step(CoreAffectPoint(0, 0, 2)))
        == 4
    )

    # dissipation_from_ge2_never_visits_surprise & dissipation_strictly_decreases & convergence <= Z+1
    for entry in ALL_176_ENTRIES:
        p = entry.point
        if p.z >= 2:
            assert dissipation_step(p) != CoreAffectPoint(0, 0, 1)
        if p != CoreAffectPoint(0, 0, 0):
            assert dissipation_potential(dissipation_step(p)) < dissipation_potential(p)
        else:
            assert dissipation_step(p) == p
        cur = p
        for _ in range(p.z + 1):
            cur = dissipation_step(cur)
        assert cur == CoreAffectPoint(0, 0, 0)

    # remanence_preserves_state
    rem_disc = SalientDiscrepancy(magnitude=2, sensory_threshold=3, resorption_threshold=1)
    assert rem_disc.is_in_remanence_window()
    for entry in ALL_176_ENTRIES:
        assert allostatic_step(rem_disc, entry.point) == entry.point

    # cooperative_step_leaves_crown & antagonist_preserves_validity_in
    for entry in ALL_176_ENTRIES:
        p = entry.point
        assert is_valid_core_affect_in(ResourceRegime.COMPETITIVE, antagonist_point(p))
        assert is_valid_core_affect_in(ResourceRegime.COOPERATIVE, antagonist_point(p))
        if p.is_on_crown() and p.x >= 0 and p.y >= 0:
            shifted = CoreAffectPoint(p.x + 1, p.y + 1, p.z)
            assert not shifted.is_on_crown()
            assert is_valid_core_affect_in(ResourceRegime.COOPERATIVE, shifted)


def test_affective_matrix_invariants_and_r3_independence() -> None:
    """Vérifie `AffectiveMatrix.lean` : valence, prototypes, loi unifiée, équivariance, transferts et R3."""
    for hp in HedonicPolarity:
        assert hp.invert().invert() is hp
    for x in (-5, -1, 1, 5):
        for y in (-5, 0, 5):
            expected = HedonicPolarity.POSITIVE if x > 0 else HedonicPolarity.NEGATIVE
            assert compute_hedonic_polarity(x, y) is expected
            assert compute_valence(x, y) is expected

    for proto in PrimaryCrownPrototype:
        assert proto.to_point().is_on_crown()

    # canonical_antagonist_examples
    canonical_pairs = [
        (CoreAffectPoint(0, 2, 2), CoreAffectPoint(0, -2, 2)),
        (CoreAffectPoint(-2, 0, 2), CoreAffectPoint(2, 0, 2)),
        (CoreAffectPoint(-1, 1, 2), CoreAffectPoint(1, -1, 2)),
        (CoreAffectPoint(1, 1, 2), CoreAffectPoint(-1, -1, 2)),
        (CoreAffectPoint(-1, 5, 4), CoreAffectPoint(5, -1, 4)),
        (CoreAffectPoint(1, 7, 5), CoreAffectPoint(-7, -1, 5)),
        (CoreAffectPoint(3, -9, 7), CoreAffectPoint(-9, 3, 7)),
    ]
    for a, b in canonical_pairs:
        assert antagonist_point(a) == b
        assert antagonist_point(b) == a

    # antagonistPoint_unified hors des axes (diagonales + latérales) et singularité axiale
    for entry in ALL_176_ENTRIES:
        if entry.x != 0 and entry.y != 0:
            assert antagonist_point_unified(entry.point) == antagonist_point(entry.point)
        else:
            with pytest.raises(ValueError):
                antagonist_point_unified(entry.point)

    # antagonist_commutes_with_invert & antagonist_commutes_with_invert_precision
    for d in range(5):
        for c in ALL_COUPLINGS:
            assert antagonist_point(deploy_coupling_at_depth(c, d)) == deploy_coupling_at_depth(c.invert(), d)
            for pa in (1, 2, 3):
                for pc in (1, 2, 4):
                    lhs = antagonist_point(deploy_coupling_with_precision(c, d, pa, pc))
                    rhs = deploy_coupling_with_precision(c.invert(), d, pc, pa)
                    assert lhs == rhs

    # transferUnitXtoY_preserves_sum & transferUnitYtoX_preserves_sum
    for entry in ALL_176_ENTRIES:
        assert transfer_unit_x_to_y(entry.point).displacement_sum() == entry.point.displacement_sum()
        assert transfer_unit_y_to_x(entry.point).displacement_sum() == entry.point.displacement_sum()

    # R3 : indépendance de core, energy_regime et antagonist vis-à-vis de PhenomenologicalMapping
    inverted_mapping = PhenomenologicalMapping(
        expectation_fn=lambda x: (
            LivedExpectationPole.EPISTEMIC_DISCHARGE
            if x < 0
            else (LivedExpectationPole.EPISTEMIC_CHARGE if x > 0 else LivedExpectationPole.EPISTEMIC_NEUTRAL)
        ),
        control_fn=lambda y: (
            LivedControlPole.PRAGMATIC_DISCHARGE
            if y < 0
            else (LivedControlPole.PRAGMATIC_CHARGE if y > 0 else LivedControlPole.PRAGMATIC_NEUTRAL)
        ),
        valence_fn=lambda x, y: compute_valence(x, y).invert(),
        activation_fn=lambda _: PhenomenologicalActivation.OPERATOR_SUSPENSION,
    )
    for entry in ALL_176_ENTRIES:
        cs = CoreAffectState(entry.point)
        m_can = evaluate_matrix(cs, CANONICAL_MAPPING)
        m_inv = evaluate_matrix(cs, inverted_mapping)
        assert m_can.core == m_inv.core
        assert m_can.energy_regime == m_inv.energy_regime
        assert m_can.antagonist == m_inv.antagonist


def test_affective_taxonomy_subsectors_and_contralateral_bindings() -> None:
    """Vérifie `dominantSector_iff_taxonomicGroup`, `contralateral_group_bindings` et `FunctionalSubsector`."""
    sector_group_pairs = (
        (OrientationSector.JOIE, TaxonomicGroup.GROUPE_JOIE),
        (OrientationSector.TRISTESSE, TaxonomicGroup.GROUPE_TRISTESSE),
        (OrientationSector.PEUR, TaxonomicGroup.GROUPE_PEUR),
        (OrientationSector.COURAGE, TaxonomicGroup.GROUPE_COURAGE),
    )
    for p in _grid_points_sample():
        for sec, grp in sector_group_pairs:
            assert (p.dominant_sector() is sec) is matches_taxonomic_group(p, grp)

        sub = classify_subsector(p.x, p.y)
        assert matches_subsector(p.x, p.y, sub)
        assert sum(matches_subsector(p.x, p.y, s) for s in FunctionalSubsector) == 1
        assert sub.to_taxonomic_group() is classify_taxonomic_group(p)
        assert sub.to_hedonic_polarity() is compute_hedonic_polarity(p.x, p.y)

    # contralateral_group_bindings sur les 120 positions latérales
    for entry in ALL_176_ENTRIES:
        p = entry.point
        ant = antagonist_point(p)
        if matches_taxonomic_group(p, TaxonomicGroup.GROUPE_JOIE) and p.x > 0:
            assert matches_taxonomic_group(ant, TaxonomicGroup.GROUPE_PEUR) and ant.y < 0
        if matches_taxonomic_group(p, TaxonomicGroup.GROUPE_JOIE) and p.x < 0:
            assert matches_taxonomic_group(ant, TaxonomicGroup.GROUPE_COURAGE) and ant.y < 0
        if matches_taxonomic_group(p, TaxonomicGroup.GROUPE_TRISTESSE) and p.x > 0:
            assert matches_taxonomic_group(ant, TaxonomicGroup.GROUPE_PEUR) and ant.y > 0
        if matches_taxonomic_group(p, TaxonomicGroup.GROUPE_TRISTESSE) and p.x < 0:
            assert matches_taxonomic_group(ant, TaxonomicGroup.GROUPE_COURAGE) and ant.y > 0


def test_lexicon176_spatial_completeness_and_json_integrity() -> None:
    """Vérifie `all176Entries_spatial_completeness`, les effectifs exacts et `data/lexicon_176.json`."""
    # all176Entries_spatial_completeness : toute coordonnée valide pour 0 <= Z <= 7 est dans le lexique
    for z in range(8):
        for q in stratum_valid_grid(z):
            assert q in ENTRY_BY_POINT

    # Effectifs par typologie géométrique, strate et secteur d'orientation
    assert Counter(e.geometry_type for e in ALL_176_ENTRIES) == {
        GeometryType.CENTRAL: 8,
        GeometryType.AXIAL: 24,
        GeometryType.DIAGONAL: 24,
        GeometryType.LATERAL: 120,
    }
    assert Counter(e.z for e in ALL_176_ENTRIES) == {
        0: 1, 1: 1, 2: 9, 3: 17, 4: 25, 5: 33, 6: 41, 7: 49
    }
    assert Counter(e.orientation_sector for e in ALL_176_ENTRIES) == {
        None: 8,
        "JOIE": 36,
        "TRISTESSE": 36,
        "PEUR": 36,
        "COURAGE": 36,
        "COLERE": 6,
        "CALME": 6,
        "DESIR": 6,
        "DEGOUT": 6,
    }
    for e in ALL_176_ENTRIES:
        if e.geometry_type is GeometryType.CENTRAL:
            assert e.orientation_sector is None
        else:
            assert e.orientation_sector in ORIENTATION_SECTORS

    # Cohérence directe avec les 8 opérateurs centraux
    for idx, op in enumerate(CentralOperator):
        entry = ENTRY_BY_POINT[op.to_point()]
        assert entry.label == op.value
        assert entry.z == idx
        assert entry.geometry_type is GeometryType.CENTRAL

    # Cohérence intégrale du fichier JSON
    raw_json = json.loads(DEFAULT_LEXICON_JSON_PATH.read_text(encoding="utf-8"))
    assert raw_json["metadata"]["total_entries"] == 176
    assert raw_json["metadata"]["central_entries"] == 8
    assert raw_json["metadata"]["peripheral_entries"] == 168
    assert len(raw_json["entries"]) == 176

    # Si le dépôt Lean 4 frère est présent dans le workspace, vérifier la parité littérale
    lean_lexicon = (
        Path(__file__).resolve().parents[2]
        / "CARTOGRAFFECT"
        / "Cartograffect"
        / "Lexicon176.lean"
    )
    if lean_lexicon.exists():
        content = lean_lexicon.read_text(encoding="utf-8")
        matches = re.findall(
            r'\u27e8"([^"]+)",\s*\u27e8(-?\d+),\s*(-?\d+),\s*(\d+)\u27e9\u27e9',
            content,
        )
        assert len(matches) == 176
        for entry, (lbl, xs, ys, zs) in zip(ALL_176_ENTRIES, matches):
            assert entry.label == lbl
            assert entry.point == CoreAffectPoint(int(xs), int(ys), int(zs))


def test_audit_tests_phase2_eval_witnesses() -> None:
    """Reproduit exactement les 9 témoins exécutables `#eval` de `AuditTests.lean`."""
    # 1. État basal par défaut -> Point de Veille (0, 0, 0)
    ts_default = run_cartograffect_pipeline(PredictiveEngineState())
    assert ts_default.matrix.core.point == CoreAffectPoint(0, 0, 0)
    assert ts_default.stratum == TaxonomicStratum(StratumKind.Z0_POINT_DE_VEILLE, 0)
    assert ts_default.group is TaxonomicGroup.OPERATEUR_CENTRAL
    assert ENTRY_BY_POINT[ts_default.matrix.core.point].label == "Point de Veille"

    # 2. Surprise (0, 0, 1)
    sample_surprise = PredictiveEngineState(
        discrepancy=SalientDiscrepancy(magnitude=5, sensory_threshold=2, resorption_threshold=1),
        perceptive=PerceptiveInterface(controle_gradient=Polarity.POS),
        subjective=SubjectiveInterface(attente_gradient=Polarity.NEG, descending_suspension=False),
        attentional=AttentionalInterface(allocated_precision=1, engagement_threshold=3, persistence_depth=0),
    )
    ts_surprise = run_cartograffect_pipeline(sample_surprise)
    assert ts_surprise.matrix.core.point == CoreAffectPoint(0, 0, 1)
    assert ts_surprise.stratum == TaxonomicStratum(StratumKind.Z1_SAILLANCE_PERCEPTIVE, 1)
    assert ts_surprise.matrix.activation is PhenomenologicalActivation.ASCENDING_RUPTURE

    # 3. Colère (-1, +1, 2) <-> Calme (+1, -1, 2)
    sample_colere = PredictiveEngineState(
        discrepancy=SalientDiscrepancy(magnitude=5, sensory_threshold=2, resorption_threshold=1),
        perceptive=PerceptiveInterface(controle_gradient=Polarity.POS),
        subjective=SubjectiveInterface(attente_gradient=Polarity.NEG, descending_suspension=True),
        attentional=AttentionalInterface(allocated_precision=5, engagement_threshold=3, persistence_depth=0),
    )
    ts_colere = run_cartograffect_pipeline(sample_colere)
    assert ts_colere.matrix.core.point == CoreAffectPoint(-1, 1, 2)
    assert ts_colere.matrix.antagonist.point == CoreAffectPoint(1, -1, 2)
    assert ts_colere.group is TaxonomicGroup.GROUPE_COLERE
    assert ts_colere.subsector is FunctionalSubsector.DIAGONAL_ANGER
    assert ts_colere.antagonist_group is TaxonomicGroup.GROUPE_CALME
    assert ts_colere.antagonist_subsector is FunctionalSubsector.DIAGONAL_CALM
    assert ts_colere.matrix.energy_regime is EnergyRegime.ERGOTROPIC_COMPENSATION
    assert ts_colere.matrix.valence is HedonicPolarity.NEGATIVE
    assert ENTRY_BY_LABEL["Colère"].antagonist_label == "Calme"

    # 4. R5 : Neutralité globale / infra-liminaire sous suspension descendante -> Anticipation (0, 0, 2)
    sample_neutral_susp = PredictiveEngineState(
        discrepancy=SalientDiscrepancy(magnitude=5, sensory_threshold=2, resorption_threshold=1),
        perceptive=PerceptiveInterface(controle_gradient=Polarity.ZERO),
        subjective=SubjectiveInterface(attente_gradient=Polarity.ZERO, descending_suspension=True),
        attentional=AttentionalInterface(allocated_precision=5, engagement_threshold=3, persistence_depth=0),
    )
    sample_subthresh_susp = PredictiveEngineState(
        discrepancy=SalientDiscrepancy(magnitude=0, sensory_threshold=2, resorption_threshold=1),
        perceptive=PerceptiveInterface(controle_gradient=Polarity.POS),
        subjective=SubjectiveInterface(attente_gradient=Polarity.NEG, descending_suspension=True),
        attentional=AttentionalInterface(allocated_precision=5, engagement_threshold=3, persistence_depth=0),
    )
    assert run_cartograffect_pipeline(sample_neutral_susp).matrix.core.point == CoreAffectPoint(0, 0, 2)
    assert run_cartograffect_pipeline(sample_subthresh_susp).matrix.core.point == CoreAffectPoint(0, 0, 2)

    # 5. Descente allostatique depuis (-1, 3, 3) -> (0, 0, 3) -> (0, 0, 2) -> (0, 0, 0)
    p0 = CoreAffectPoint(-1, 3, 3)
    p1 = dissipation_step(p0)
    p2 = dissipation_step(p1)
    p3 = dissipation_step(p2)
    assert (p1, p2, p3) == (
        CoreAffectPoint(0, 0, 3),
        CoreAffectPoint(0, 0, 2),
        CoreAffectPoint(0, 0, 0),
    )

    # 6. R8 : Atteinte déterministe de Consternation (-1, 3, 3) via (piA, piC) = (1, 3)
    sample_consternation = PredictiveEngineState(
        discrepancy=SalientDiscrepancy(magnitude=6, sensory_threshold=2, resorption_threshold=1),
        perceptive=PerceptiveInterface(controle_gradient=Polarity.POS),
        subjective=SubjectiveInterface(attente_gradient=Polarity.NEG, descending_suspension=True),
        attentional=AttentionalInterface(
            allocated_precision=5,
            engagement_threshold=3,
            persistence_depth=1,
            precision_a=1,
            precision_c=3,
        ),
    )
    ts_const = run_cartograffect_pipeline(sample_consternation)
    assert ts_const.matrix.core.point == CoreAffectPoint(-1, 3, 3)
    assert ts_const.geometry is GeometryType.LATERAL
    assert ts_const.group is TaxonomicGroup.GROUPE_JOIE
    assert ts_const.subsector is FunctionalSubsector.LATERAL_DEFENSIVE_URGENCY
    assert ts_const.matrix.valence is HedonicPolarity.NEGATIVE
    assert ts_const.matrix.antagonist.point == CoreAffectPoint(3, -1, 3)
    assert ENTRY_BY_POINT[ts_const.matrix.core.point].label == "Consternation"
    assert ENTRY_BY_POINT[ts_const.matrix.antagonist.point].label == "Émerveillement"

