/*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*/

include "PredictiveEngine.dfy"
include "CoreAffect.dfy"

module AffectiveMatrix {
  import opened PredictiveEngine
  import opened CoreAffect

  // =========================================================================
  // 1. Transduction phénoménologique : Pôles vécus, Valence et Activation
  // =========================================================================

  datatype LivedExpectationPole =
    | EpistemicCharge
    | EpistemicNeutral
    | EpistemicDischarge

  datatype LivedControlPole =
    | PragmaticCharge
    | PragmaticNeutral
    | PragmaticDischarge

  datatype EnergyRegime =
    | NeutralBasal
    | AxialPure
    | PositiveSynergy
    | NegativeSynergy
    | ErgotropicCompensation
    | TrophotropicRelease

  function ComputeEnergyRegime(x: int, y: int): EnergyRegime {
    if x == 0 && y == 0 then NeutralBasal
    else if x == 0 || y == 0 then AxialPure
    else if x > 0 && y > 0 then PositiveSynergy
    else if x < 0 && y < 0 then NegativeSynergy
    else if x < 0 && y > 0 then ErgotropicCompensation
    else TrophotropicRelease
  }

  datatype HedonicPolarity = HedPositive | HedNegative | HedNeutral

  function HedonicPolarityInvert(p: HedonicPolarity): HedonicPolarity {
    match p
    case HedPositive => HedNegative
    case HedNegative => HedPositive
    case HedNeutral  => HedNeutral
  }

  function ComputeHedonicPolarity(x: int, y: int): HedonicPolarity {
    if x > 0 then HedPositive
    else if x < 0 then HedNegative
    else if y > 0 then HedPositive
    else if y < 0 then HedNegative
    else HedNeutral
  }

  function ComputeValence(x: int, y: int): HedonicPolarity {
    ComputeHedonicPolarity(x, y)
  }

  lemma HedonicPolarity_invert_involutive(p: HedonicPolarity)
    ensures HedonicPolarityInvert(HedonicPolarityInvert(p)) == p
  {
    match p
    case HedPositive =>
    case HedNegative =>
    case HedNeutral  =>
  }

  lemma x_positive_determines_positive_valence(x: int, y: int)
    requires x > 0
    ensures ComputeHedonicPolarity(x, y) == HedPositive
  {
  }

  lemma x_negative_determines_negative_valence(x: int, y: int)
    requires x < 0
    ensures ComputeHedonicPolarity(x, y) == HedNegative
  {
  }

  datatype PhenomenologicalActivation =
    | BasalWakefulness
    | AscendingRupture
    | OperatorSuspension
    | LowInhibition
    | EpistemicVigilance
    | HighMobilization

  function TransduceExpectation(x: int): LivedExpectationPole {
    if x < 0 then EpistemicCharge
    else if x > 0 then EpistemicDischarge
    else EpistemicNeutral
  }

  function TransduceControl(y: int): LivedControlPole {
    if y < 0 then PragmaticCharge
    else if y > 0 then PragmaticDischarge
    else PragmaticNeutral
  }

  function ComputeActivation(p: CoreAffectPoint): PhenomenologicalActivation {
    if p.x == 0 && p.y == 0 then
      if p.z == 0 then BasalWakefulness
      else if p.z == 1 then AscendingRupture
      else OperatorSuspension
    else if p.y > 0 then HighMobilization
    else if p.y < 0 then LowInhibition
    else EpistemicVigilance
  }

  // =========================================================================
  // 2. Les huit prototypes de la première couronne (Z = 2)
  // =========================================================================

  datatype PrimaryCrownPrototype =
    | ProtoJoie
    | ProtoTristesse
    | ProtoPeur
    | ProtoCourage
    | ProtoDesir
    | ProtoDegout
    | ProtoColere
    | ProtoCalme

  function PrimaryCrownPrototypeToPoint(proto: PrimaryCrownPrototype): CoreAffectPoint {
    match proto
    case ProtoJoie      => CoreAffectPoint(0,  2, 2)
    case ProtoTristesse => CoreAffectPoint(0, -2, 2)
    case ProtoPeur      => CoreAffectPoint(-2, 0, 2)
    case ProtoCourage   => CoreAffectPoint(2,  0, 2)
    case ProtoDesir     => CoreAffectPoint(1,  1, 2)
    case ProtoDegout    => CoreAffectPoint(-1,-1, 2)
    case ProtoColere    => CoreAffectPoint(-1, 1, 2)
    case ProtoCalme     => CoreAffectPoint(1, -1, 2)
  }

  lemma PrimaryCrownPrototype_valid_on_crown(proto: PrimaryCrownPrototype)
    ensures IsOnCrown(PrimaryCrownPrototypeToPoint(proto))
  {
    match proto
    case ProtoJoie      =>
    case ProtoTristesse =>
    case ProtoPeur      =>
    case ProtoCourage   =>
    case ProtoDesir     =>
    case ProtoDegout    =>
    case ProtoColere    =>
    case ProtoCalme     =>
  }

  // =========================================================================
  // 3. Opérateur général d'antagonisme formel (Axial, Diagonal, Controlatéral)
  // =========================================================================

  function AntagonistPoint(p: CoreAffectPoint): CoreAffectPoint {
    if p.x == 0 || p.y == 0 || AbsNat(p.x) == AbsNat(p.y) then
      CoreAffectPoint(-p.x, -p.y, p.z)
    else if (p.x > 0 && p.y < 0) || (p.x < 0 && p.y > 0) then
      CoreAffectPoint(p.y, p.x, p.z)
    else
      CoreAffectPoint(-p.y, -p.x, p.z)
  }

  // =========================================================================
  // 4. Propriétés structurelles et Invariants de la Matrice Affective
  // =========================================================================

  lemma antagonistPoint_preserves_z(p: CoreAffectPoint)
    ensures AntagonistPoint(p).z == p.z
  {
  }

  lemma antagonistPoint_preserves_displacementSum(p: CoreAffectPoint)
    ensures DisplacementSum(AntagonistPoint(p)) == DisplacementSum(p)
  {
  }

  lemma antagonistPoint_preserves_validity(p: CoreAffectPoint)
    requires IsValidCoreAffect(p)
    ensures IsValidCoreAffect(AntagonistPoint(p))
  {
    antagonistPoint_preserves_z(p);
    antagonistPoint_preserves_displacementSum(p);
  }

  lemma antagonistPoint_involutive(p: CoreAffectPoint)
    ensures AntagonistPoint(AntagonistPoint(p)) == p
  {
  }

  lemma antagonistPoint_fixed_iff_central(p: CoreAffectPoint)
    ensures AntagonistPoint(p) == p <==> IsCentral(p)
  {
  }

  lemma contralateral_swaps_amplitudes(p: CoreAffectPoint)
    requires !(p.x == 0 || p.y == 0 || AbsNat(p.x) == AbsNat(p.y))
    ensures AbsNat(AntagonistPoint(p).x) == AbsNat(p.y)
    ensures AbsNat(AntagonistPoint(p).y) == AbsNat(p.x)
  {
  }

  lemma canonical_antagonist_examples()
    ensures AntagonistPoint(CoreAffectPoint(0, 2, 2)) == CoreAffectPoint(0, -2, 2)
    ensures AntagonistPoint(CoreAffectPoint(-2, 0, 2)) == CoreAffectPoint(2, 0, 2)
    ensures AntagonistPoint(CoreAffectPoint(-1, 1, 2)) == CoreAffectPoint(1, -1, 2)
    ensures AntagonistPoint(CoreAffectPoint(1, 1, 2)) == CoreAffectPoint(-1, -1, 2)
    ensures AntagonistPoint(CoreAffectPoint(-1, 5, 4)) == CoreAffectPoint(5, -1, 4)
    ensures AntagonistPoint(CoreAffectPoint(1, 7, 5)) == CoreAffectPoint(-7, -1, 5)
    ensures AntagonistPoint(CoreAffectPoint(3, -9, 7)) == CoreAffectPoint(-9, 3, 7)
  {
  }

  lemma antagonist_commutes_with_invert(c: EngineCoupling, d: nat)
    ensures AntagonistPoint(DeployCouplingAtDepth(c, d)) ==
            DeployCouplingAtDepth(EngineCoupling(PolarityInvert(c.attente), PolarityInvert(c.controle)), d)
  {
  }

  lemma antagonist_commutes_with_invert_precision(c: EngineCoupling, d: nat, piA: nat, piC: nat)
    ensures AntagonistPoint(DeployCouplingWithPrecision(c, d, piA, piC)) ==
            DeployCouplingWithPrecision(EngineCoupling(PolarityInvert(c.attente), PolarityInvert(c.controle)), d, piC, piA)
  {
    apportionRay_bounds(d, piA, piC);
    apportionRay_swap(d, piA, piC);
  }

  function IntSign(v: int): int {
    if v > 0 then 1 else if v < 0 then -1 else 0
  }

  lemma antagonistPoint_unified(p: CoreAffectPoint)
    requires p.x != 0 && p.y != 0
    ensures AntagonistPoint(p) ==
            CoreAffectPoint(-IntSign(p.x) * (AbsNat(p.y) as int), -IntSign(p.y) * (AbsNat(p.x) as int), p.z)
  {
  }

  lemma antagonistPoint_inverts_hedonic_polarity(p: CoreAffectPoint)
    ensures var ant := AntagonistPoint(p);
      ComputeHedonicPolarity(ant.x, ant.y) == HedonicPolarityInvert(ComputeHedonicPolarity(p.x, p.y))
  {
  }

  lemma antagonist_preserves_validity_in(r: ResourceRegime, p: CoreAffectPoint)
    requires IsValidCoreAffectIn(r, p)
    ensures IsValidCoreAffectIn(r, AntagonistPoint(p))
  {
    match r
    case Competitive => antagonistPoint_preserves_validity(p);
    case Cooperative =>
      antagonistPoint_preserves_z(p);
      antagonistPoint_preserves_displacementSum(p);
      antagonistPoint_fixed_iff_central(p);
  }

  // =========================================================================
  // 5. Transfert intra-couronne et Structure AffectiveMatrixState
  // =========================================================================

  function TransferUnitXtoY(p: CoreAffectPoint): CoreAffectPoint {
    if p.x > 0 && p.y >= 0 then CoreAffectPoint(p.x - 1, p.y + 1, p.z) else p
  }

  lemma transferUnitXtoY_preserves_sum(p: CoreAffectPoint)
    ensures DisplacementSum(TransferUnitXtoY(p)) == DisplacementSum(p)
  {
  }

  function TransferUnitYtoX(p: CoreAffectPoint): CoreAffectPoint {
    if p.x >= 0 && p.y > 0 then CoreAffectPoint(p.x + 1, p.y - 1, p.z) else p
  }

  lemma transferUnitYtoX_preserves_sum(p: CoreAffectPoint)
    ensures DisplacementSum(TransferUnitYtoX(p)) == DisplacementSum(p)
  {
  }

  datatype AffectiveMatrixState = AffectiveMatrixState(
    core: CoreAffectState,
    expectationPole: LivedExpectationPole,
    controlPole: LivedControlPole,
    energyRegime: EnergyRegime,
    valence: HedonicPolarity,
    activation: PhenomenologicalActivation,
    antagonist: CoreAffectState
  )

  datatype PhenomenologicalMapping = PhenomenologicalMapping(
    expectationFn: int -> LivedExpectationPole,
    controlFn: int -> LivedControlPole,
    valenceFn: (int, int) -> HedonicPolarity,
    activationFn: CoreAffectPoint -> PhenomenologicalActivation
  )

  function CanonicalMapping(): PhenomenologicalMapping {
    PhenomenologicalMapping(
      x => TransduceExpectation(x),
      y => TransduceControl(y),
      (x, y) => ComputeValence(x, y),
      p => ComputeActivation(p)
    )
  }

  function EvaluateMatrix(cs: CoreAffectState, mapping: PhenomenologicalMapping): AffectiveMatrixState {
    antagonistPoint_preserves_validity(cs);
    var p: CoreAffectPoint := cs;
    var ap: CoreAffectState := AntagonistPoint(p);
    AffectiveMatrixState(
      cs,
      mapping.expectationFn(p.x),
      mapping.controlFn(p.y),
      ComputeEnergyRegime(p.x, p.y),
      mapping.valenceFn(p.x, p.y),
      mapping.activationFn(p),
      ap
    )
  }

  function DefaultAffectiveMatrixState(): AffectiveMatrixState {
    EvaluateMatrix(DefaultCoreAffectState(), CanonicalMapping())
  }

  lemma evaluateMatrix_core_antagonist_independent(
    cs: CoreAffectState,
    m1: PhenomenologicalMapping,
    m2: PhenomenologicalMapping
  )
    ensures EvaluateMatrix(cs, m1).core == EvaluateMatrix(cs, m2).core
    ensures EvaluateMatrix(cs, m1).energyRegime == EvaluateMatrix(cs, m2).energyRegime
    ensures EvaluateMatrix(cs, m1).antagonist == EvaluateMatrix(cs, m2).antagonist
  {
  }

  lemma mapping_independent_antagonist_invariants(
    cs: CoreAffectState,
    mapping: PhenomenologicalMapping
  )
    ensures IsValidCoreAffect(EvaluateMatrix(cs, mapping).antagonist)
    ensures EvaluateMatrix(EvaluateMatrix(cs, mapping).antagonist, mapping).antagonist == cs
    ensures (cs.x != 0 && cs.y != 0) ==>
              EvaluateMatrix(cs, mapping).antagonist ==
                CoreAffectPoint(-IntSign(cs.x) * (AbsNat(cs.y) as int), -IntSign(cs.y) * (AbsNat(cs.x) as int), cs.z)
    ensures EvaluateMatrix(cs, mapping).antagonist == EvaluateMatrix(cs, CanonicalMapping()).antagonist
  {
    antagonistPoint_preserves_validity(cs);
    antagonistPoint_involutive(cs);
    if cs.x != 0 && cs.y != 0 {
      antagonistPoint_unified(cs);
    }
  }

}
