/*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*/

include "PredictiveEngine.dfy"
include "CoreAffect.dfy"
include "AffectiveMatrix.dfy"

module AffectiveTaxonomy {
  import opened PredictiveEngine
  import opened CoreAffect
  import opened AffectiveMatrix

  // =========================================================================
  // 1. Catégories de strates (Axe Z) et Groupes taxonomiques d'orientation
  // =========================================================================

  datatype TaxonomicStratum =
    | Z0_pointDeVeille
    | Z1_saillancePerceptive
    | Z2_affectsPrimaires
    | Z3_emotionsReactives
    | Z4_sentimentsReflexifs
    | Z5_orientationsDurables
    | Z6_identitesAffectives
    | Z7_sentimentsTranscendants
    | ZDeepProlongation(z: nat)

  function ClassifyStratum(z: nat): TaxonomicStratum {
    if z == 0 then Z0_pointDeVeille
    else if z == 1 then Z1_saillancePerceptive
    else if z == 2 then Z2_affectsPrimaires
    else if z == 3 then Z3_emotionsReactives
    else if z == 4 then Z4_sentimentsReflexifs
    else if z == 5 then Z5_orientationsDurables
    else if z == 6 then Z6_identitesAffectives
    else if z == 7 then Z7_sentimentsTranscendants
    else ZDeepProlongation(z)
  }

  datatype TaxonomicGroup =
    | OperateurCentral
    | GroupeJoie
    | GroupeTristesse
    | GroupePeur
    | GroupeCourage
    | GroupeDesir
    | GroupeDegout
    | GroupeColere
    | GroupeCalme

  predicate MatchesTaxonomicGroup(p: CoreAffectPoint, g: TaxonomicGroup) {
    match g
    case OperateurCentral => p.x == 0 && p.y == 0
    case GroupeJoie       => AbsNat(p.y) > AbsNat(p.x) && p.y > 0
    case GroupeTristesse  => AbsNat(p.y) > AbsNat(p.x) && p.y < 0
    case GroupePeur       => AbsNat(p.x) > AbsNat(p.y) && p.x < 0
    case GroupeCourage    => AbsNat(p.x) > AbsNat(p.y) && p.x > 0
    case GroupeDesir      => AbsNat(p.x) == AbsNat(p.y) && p.x > 0 && p.y > 0
    case GroupeDegout     => AbsNat(p.x) == AbsNat(p.y) && p.x < 0 && p.y < 0
    case GroupeColere     => AbsNat(p.x) == AbsNat(p.y) && p.x < 0 && p.y > 0
    case GroupeCalme      => AbsNat(p.x) == AbsNat(p.y) && p.x > 0 && p.y < 0
  }

  function ClassifyTaxonomicGroup(p: CoreAffectPoint): TaxonomicGroup {
    if p.x == 0 && p.y == 0 then
      OperateurCentral
    else if AbsNat(p.y) > AbsNat(p.x) then
      if p.y > 0 then GroupeJoie else GroupeTristesse
    else if AbsNat(p.x) > AbsNat(p.y) then
      if p.x < 0 then GroupePeur else GroupeCourage
    else if p.x > 0 then
      if p.y > 0 then GroupeDesir else GroupeCalme
    else
      if p.y > 0 then GroupeColere else GroupeDegout
  }

  datatype FunctionalSubsector =
    | CentralOperatorSubsector
    | AxialElan
    | AxialWithdrawal
    | AxialOpening
    | AxialThreat
    | DiagonalDesire
    | DiagonalDisgust
    | DiagonalAnger
    | DiagonalCalm
    | LateralApproachSynergy
    | LateralDefensiveUrgency
    | LateralTrophotropicPeace
    | LateralAversiveDistress
    | LateralEpistemicMastery
    | LateralContemplativeOpen
    | LateralVigilantAlert
    | LateralEpistemicClosure

  function ClassifySubsector(x: int, y: int): FunctionalSubsector {
    if x == 0 && y == 0 then CentralOperatorSubsector
    else if x == 0 && y > 0 then AxialElan
    else if x == 0 && y < 0 then AxialWithdrawal
    else if x > 0 && y == 0 then AxialOpening
    else if x < 0 && y == 0 then AxialThreat
    else if x == y && x > 0 then DiagonalDesire
    else if x == y && x < 0 then DiagonalDisgust
    else if x == -y && x < 0 then DiagonalAnger
    else if x == -y && x > 0 then DiagonalCalm
    else if y > (AbsNat(x) as int) && x > 0 then LateralApproachSynergy
    else if y > (AbsNat(x) as int) && x < 0 then LateralDefensiveUrgency
    else if -y > (AbsNat(x) as int) && x > 0 then LateralTrophotropicPeace
    else if -y > (AbsNat(x) as int) && x < 0 then LateralAversiveDistress
    else if x > (AbsNat(y) as int) && y > 0 then LateralEpistemicMastery
    else if x > (AbsNat(y) as int) && y < 0 then LateralContemplativeOpen
    else if -x > (AbsNat(y) as int) && y > 0 then LateralVigilantAlert
    else LateralEpistemicClosure
  }

  function SubsectorToGroup(s: FunctionalSubsector): TaxonomicGroup {
    match s
    case CentralOperatorSubsector => OperateurCentral
    case AxialElan                => GroupeJoie
    case LateralApproachSynergy   => GroupeJoie
    case LateralDefensiveUrgency  => GroupeJoie
    case AxialWithdrawal          => GroupeTristesse
    case LateralTrophotropicPeace => GroupeTristesse
    case LateralAversiveDistress  => GroupeTristesse
    case AxialOpening             => GroupeCourage
    case LateralEpistemicMastery  => GroupeCourage
    case LateralContemplativeOpen => GroupeCourage
    case AxialThreat              => GroupePeur
    case LateralVigilantAlert     => GroupePeur
    case LateralEpistemicClosure  => GroupePeur
    case DiagonalDesire           => GroupeDesir
    case DiagonalDisgust          => GroupeDegout
    case DiagonalAnger            => GroupeColere
    case DiagonalCalm             => GroupeCalme
  }

  function SubsectorToHedonicPolarity(s: FunctionalSubsector): HedonicPolarity {
    match s
    case CentralOperatorSubsector => HedNeutral
    case AxialElan                => HedPositive
    case AxialOpening             => HedPositive
    case DiagonalDesire           => HedPositive
    case DiagonalCalm             => HedPositive
    case LateralApproachSynergy   => HedPositive
    case LateralTrophotropicPeace => HedPositive
    case LateralEpistemicMastery  => HedPositive
    case LateralContemplativeOpen => HedPositive
    case AxialWithdrawal          => HedNegative
    case AxialThreat              => HedNegative
    case DiagonalDisgust          => HedNegative
    case DiagonalAnger            => HedNegative
    case LateralDefensiveUrgency  => HedNegative
    case LateralAversiveDistress  => HedNegative
    case LateralVigilantAlert     => HedNegative
    case LateralEpistemicClosure  => HedNegative
  }

  // =========================================================================
  // 2. Certification de la loi des effectifs et des 176 entrées (Z = 0..7)
  // =========================================================================

  function CrownPeripheralCount(z: nat): nat {
    4 * CrownRadius(z)
  }

  function StratumTotalCount(z: nat): nat {
    1 + CrownPeripheralCount(z)
  }

  lemma inventory_176_certified()
    ensures CrownPeripheralCount(2) == 8
    ensures CrownPeripheralCount(3) == 16
    ensures CrownPeripheralCount(4) == 24
    ensures CrownPeripheralCount(5) == 32
    ensures CrownPeripheralCount(6) == 40
    ensures CrownPeripheralCount(7) == 48
    ensures CrownPeripheralCount(2) + CrownPeripheralCount(3) + CrownPeripheralCount(4) +
            CrownPeripheralCount(5) + CrownPeripheralCount(6) + CrownPeripheralCount(7) == 168
    ensures StratumTotalCount(0) + StratumTotalCount(1) + StratumTotalCount(2) +
            StratumTotalCount(3) + StratumTotalCount(4) + StratumTotalCount(5) +
            StratumTotalCount(6) + StratumTotalCount(7) == 176
  {
  }

  // =========================================================================
  // 3. Exhaustivité, Exclusivité mutuelle et Sous-secteurs fonctionnels
  // =========================================================================

  lemma classifyTaxonomicGroup_correct(p: CoreAffectPoint)
    ensures MatchesTaxonomicGroup(p, ClassifyTaxonomicGroup(p))
  {
  }

  lemma taxonomy_group_exhaustive(p: CoreAffectPoint)
    ensures exists g: TaxonomicGroup :: MatchesTaxonomicGroup(p, g)
  {
    classifyTaxonomicGroup_correct(p);
    var g := ClassifyTaxonomicGroup(p);
    assert MatchesTaxonomicGroup(p, g);
  }

  lemma taxonomy_group_exclusive(p: CoreAffectPoint, g1: TaxonomicGroup, g2: TaxonomicGroup)
    requires MatchesTaxonomicGroup(p, g1) && MatchesTaxonomicGroup(p, g2)
    ensures g1 == g2
  {
    match (g1, g2)
    case (OperateurCentral, OperateurCentral) =>
    case (GroupeJoie, GroupeJoie)             =>
    case (GroupeTristesse, GroupeTristesse)   =>
    case (GroupePeur, GroupePeur)             =>
    case (GroupeCourage, GroupeCourage)       =>
    case (GroupeDesir, GroupeDesir)           =>
    case (GroupeDegout, GroupeDegout)         =>
    case (GroupeColere, GroupeColere)         =>
    case (GroupeCalme, GroupeCalme)           =>
    case _                                    =>
  }

  lemma matchesTaxonomicGroup_iff(p: CoreAffectPoint, g: TaxonomicGroup)
    ensures MatchesTaxonomicGroup(p, g) <==> g == ClassifyTaxonomicGroup(p)
  {
    classifyTaxonomicGroup_correct(p);
    if MatchesTaxonomicGroup(p, g) {
      taxonomy_group_exclusive(p, g, ClassifyTaxonomicGroup(p));
    }
  }

  lemma dominantSector_iff_taxonomicGroup(p: CoreAffectPoint)
    ensures (DominantSector(p) == SomeSector(SectorJoie)      <==> MatchesTaxonomicGroup(p, GroupeJoie))
    ensures (DominantSector(p) == SomeSector(SectorTristesse) <==> MatchesTaxonomicGroup(p, GroupeTristesse))
    ensures (DominantSector(p) == SomeSector(SectorPeur)      <==> MatchesTaxonomicGroup(p, GroupePeur))
    ensures (DominantSector(p) == SomeSector(SectorCourage)   <==> MatchesTaxonomicGroup(p, GroupeCourage))
  {
  }

  lemma contralateral_group_bindings(p: CoreAffectPoint)
    ensures (MatchesTaxonomicGroup(p, GroupeJoie) && p.x > 0) ==>
              (MatchesTaxonomicGroup(AntagonistPoint(p), GroupePeur) && AntagonistPoint(p).y < 0)
    ensures (MatchesTaxonomicGroup(p, GroupeJoie) && p.x < 0) ==>
              (MatchesTaxonomicGroup(AntagonistPoint(p), GroupeCourage) && AntagonistPoint(p).y < 0)
    ensures (MatchesTaxonomicGroup(p, GroupeTristesse) && p.x > 0) ==>
              (MatchesTaxonomicGroup(AntagonistPoint(p), GroupePeur) && AntagonistPoint(p).y > 0)
    ensures (MatchesTaxonomicGroup(p, GroupeTristesse) && p.x < 0) ==>
              (MatchesTaxonomicGroup(AntagonistPoint(p), GroupeCourage) && AntagonistPoint(p).y > 0)
  {
  }

  predicate MatchesSubsector(x: int, y: int, s: FunctionalSubsector) {
    match s
    case CentralOperatorSubsector => x == 0 && y == 0
    case AxialElan                => x == 0 && y > 0
    case AxialWithdrawal          => x == 0 && y < 0
    case AxialOpening             => x > 0 && y == 0
    case AxialThreat              => x < 0 && y == 0
    case DiagonalDesire           => x == y && x > 0
    case DiagonalDisgust          => x == y && x < 0
    case DiagonalAnger            => x == -y && x < 0
    case DiagonalCalm             => x == -y && x > 0
    case LateralApproachSynergy   => y > (AbsNat(x) as int) && x > 0
    case LateralDefensiveUrgency  => y > (AbsNat(x) as int) && x < 0
    case LateralTrophotropicPeace => -y > (AbsNat(x) as int) && x > 0
    case LateralAversiveDistress  => -y > (AbsNat(x) as int) && x < 0
    case LateralEpistemicMastery  => x > (AbsNat(y) as int) && y > 0
    case LateralContemplativeOpen => x > (AbsNat(y) as int) && y < 0
    case LateralVigilantAlert     => -x > (AbsNat(y) as int) && y > 0
    case LateralEpistemicClosure  => -x > (AbsNat(y) as int) && y < 0
  }

  lemma classifySubsector_correct(x: int, y: int)
    ensures MatchesSubsector(x, y, ClassifySubsector(x, y))
  {
  }

  lemma subsector_exclusive(x: int, y: int, s1: FunctionalSubsector, s2: FunctionalSubsector)
    requires MatchesSubsector(x, y, s1) && MatchesSubsector(x, y, s2)
    ensures s1 == s2
  {
  }

  lemma matchesSubsector_iff(x: int, y: int, s: FunctionalSubsector)
    ensures MatchesSubsector(x, y, s) <==> s == ClassifySubsector(x, y)
  {
    classifySubsector_correct(x, y);
    if MatchesSubsector(x, y, s) {
      subsector_exclusive(x, y, s, ClassifySubsector(x, y));
    }
  }

  lemma matchesSubsector_toTaxonomicGroup(p: CoreAffectPoint, s: FunctionalSubsector)
    requires MatchesSubsector(p.x, p.y, s)
    ensures MatchesTaxonomicGroup(p, SubsectorToGroup(s))
  {
  }

  lemma classifySubsector_refines_group(p: CoreAffectPoint)
    ensures SubsectorToGroup(ClassifySubsector(p.x, p.y)) == ClassifyTaxonomicGroup(p)
  {
    classifySubsector_correct(p.x, p.y);
    matchesSubsector_toTaxonomicGroup(p, ClassifySubsector(p.x, p.y));
    matchesTaxonomicGroup_iff(p, SubsectorToGroup(ClassifySubsector(p.x, p.y)));
  }

  lemma matchesSubsector_toHedonicPolarity(x: int, y: int, s: FunctionalSubsector)
    requires MatchesSubsector(x, y, s)
    ensures SubsectorToHedonicPolarity(s) == ComputeHedonicPolarity(x, y)
  {
  }

  lemma classifySubsector_determines_valence(x: int, y: int)
    ensures SubsectorToHedonicPolarity(ClassifySubsector(x, y)) == ComputeHedonicPolarity(x, y)
  {
    classifySubsector_correct(x, y);
    matchesSubsector_toHedonicPolarity(x, y, ClassifySubsector(x, y));
  }

  // =========================================================================
  // 4. Structure finale TaxonomicState & Théorème Maître end_to_end_coherence
  // =========================================================================

  datatype TaxonomicState = TaxonomicState(
    matrix: AffectiveMatrixState,
    stratum: TaxonomicStratum,
    geometry: GeometryType,
    group: TaxonomicGroup,
    subsector: FunctionalSubsector,
    antagonistGroup: TaxonomicGroup,
    antagonistSubsector: FunctionalSubsector
  )

  function EvaluateTaxonomy(ms: AffectiveMatrixState): TaxonomicState {
    var p := ms.core;
    var ap := ms.antagonist;
    TaxonomicState(
      ms,
      ClassifyStratum(p.z),
      ClassifyGeometry(p),
      ClassifyTaxonomicGroup(p),
      ClassifySubsector(p.x, p.y),
      ClassifyTaxonomicGroup(ap),
      ClassifySubsector(ap.x, ap.y)
    )
  }

  function DefaultTaxonomicState(): TaxonomicState {
    EvaluateTaxonomy(DefaultAffectiveMatrixState())
  }

  function RunCartograffectPipeline(s: PredictiveEngineState): TaxonomicState {
    EvaluateTaxonomy(EvaluateMatrix(EvaluateCoreAffect(s), CanonicalMapping()))
  }

  predicate IsCoherentTerminalState(s: PredictiveEngineState, ts: TaxonomicState) {
    var cp: CoreAffectPoint := ts.matrix.core;
    var ap: CoreAffectPoint := ts.matrix.antagonist;
    cp == ProjectToCoreAffect(s) &&
    IsValidCoreAffect(cp) &&
    ap == AntagonistPoint(cp) &&
    IsValidCoreAffect(ap) &&
    ap.z == cp.z &&
    DisplacementSum(ap) == DisplacementSum(cp) &&
    ts.matrix.expectationPole == TransduceExpectation(cp.x) &&
    ts.matrix.controlPole == TransduceControl(cp.y) &&
    ts.matrix.energyRegime == ComputeEnergyRegime(cp.x, cp.y) &&
    ts.matrix.valence == ComputeHedonicPolarity(cp.x, cp.y) &&
    ts.matrix.activation == ComputeActivation(cp) &&
    ts.stratum == ClassifyStratum(cp.z) &&
    ts.geometry == ClassifyGeometry(cp) &&
    ts.subsector == ClassifySubsector(cp.x, cp.y) &&
    ts.antagonistSubsector == ClassifySubsector(ap.x, ap.y) &&
    MatchesTaxonomicGroup(cp, ts.group) &&
    (forall g: TaxonomicGroup :: MatchesTaxonomicGroup(cp, g) ==> g == ts.group) &&
    MatchesTaxonomicGroup(ap, ts.antagonistGroup)
  }

  lemma end_to_end_coherence(s: PredictiveEngineState)
    ensures exists ts: TaxonomicState ::
      IsCoherentTerminalState(s, ts) &&
      forall ts': TaxonomicState :: IsCoherentTerminalState(s, ts') ==> ts' == ts
  {
    var ts := RunCartograffectPipeline(s);
    var cp := ProjectToCoreAffect(s);
    var ap := AntagonistPoint(cp);
    engine_induces_valid_core_affect(s);
    antagonistPoint_preserves_validity(cp);
    antagonistPoint_preserves_z(cp);
    antagonistPoint_preserves_displacementSum(cp);
    classifyTaxonomicGroup_correct(cp);
    classifyTaxonomicGroup_correct(ap);
    forall g: TaxonomicGroup | MatchesTaxonomicGroup(cp, g)
      ensures g == ts.group
    {
      matchesTaxonomicGroup_iff(cp, g);
    }
    assert IsCoherentTerminalState(s, ts);

    forall ts': TaxonomicState | IsCoherentTerminalState(s, ts')
      ensures ts' == ts
    {
      matchesTaxonomicGroup_iff(cp, ts'.group);
      matchesTaxonomicGroup_iff(ap, ts'.antagonistGroup);
    }
  }

}
