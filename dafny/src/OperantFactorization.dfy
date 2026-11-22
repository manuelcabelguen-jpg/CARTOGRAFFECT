/*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*/

include "CoreAffect.dfy"
include "AffectiveMatrix.dfy"

module OperantFactorization {
  import opened CoreAffect
  import opened AffectiveMatrix

  // =========================================================================
  // 1. Distance de Manhattan intra-plan (métrique L1 sur (X, Y))
  // =========================================================================

  function ManhattanDistXY(p: CoreAffectPoint, q: CoreAffectPoint): nat {
    AbsNat(p.x - q.x) + AbsNat(p.y - q.y)
  }

  lemma manhattanDistXY_origin(p: CoreAffectPoint)
    ensures ManhattanDistXY(p, CoreAffectPoint(0, 0, p.z)) == DisplacementSum(p)
  {
  }

  // =========================================================================
  // 2. Contingences opérantes {R+, R-, P+, P-} et projection sur Z = 2
  // =========================================================================

  datatype OperantEffect = Reinforcement | Punishment

  datatype OperantOperator = Addition | Removal

  datatype OperantContingency = OperantContingency(effect: OperantEffect, op: OperantOperator)

  datatype OptionContingency =
    | NoContingency
    | SomeContingency(val: OperantContingency)

  function DiagToContingency(p: CoreAffectPoint): OptionContingency {
    if p.z != 2 then NoContingency
    else if p.x ==  1 && p.y ==  1 then SomeContingency(OperantContingency(Reinforcement, Addition))
    else if p.x ==  1 && p.y == -1 then SomeContingency(OperantContingency(Reinforcement, Removal))
    else if p.x == -1 && p.y == -1 then SomeContingency(OperantContingency(Punishment,    Addition))
    else if p.x == -1 && p.y ==  1 then SomeContingency(OperantContingency(Punishment,    Removal))
    else NoContingency
  }

  function PrototypeToContingency(proto: PrimaryCrownPrototype): OptionContingency {
    DiagToContingency(PrimaryCrownPrototypeToPoint(proto))
  }

  function Z2DiagonalPoints(): seq<CoreAffectPoint> {
    [
      PrimaryCrownPrototypeToPoint(ProtoDesir),
      PrimaryCrownPrototypeToPoint(ProtoCalme),
      PrimaryCrownPrototypeToPoint(ProtoDegout),
      PrimaryCrownPrototypeToPoint(ProtoColere)
    ]
  }

  function Z2AxialPoints(): seq<CoreAffectPoint> {
    [
      PrimaryCrownPrototypeToPoint(ProtoCourage),
      PrimaryCrownPrototypeToPoint(ProtoPeur),
      PrimaryCrownPrototypeToPoint(ProtoJoie),
      PrimaryCrownPrototypeToPoint(ProtoTristesse)
    ]
  }

  // =========================================================================
  // 3. Les 7 théorèmes de factorisation opérante
  // =========================================================================

  lemma operant_factorization_law(p: CoreAffectPoint)
    requires p in Z2DiagonalPoints()
    ensures DiagToContingency(p).SomeContingency?
    ensures var c := DiagToContingency(p).val;
      (c.effect == Reinforcement <==> p.x == 1) &&
      (c.effect == Punishment <==> p.x == -1) &&
      (c.op == Addition <==> p.x * p.y == 1) &&
      (c.op == Removal <==> p.x * p.y == -1) &&
      ((c == OperantContingency(Reinforcement, Addition) ||
        c == OperantContingency(Punishment, Removal)) <==> p.y == 1) &&
      (ComputeHedonicPolarity(p.x, p.y) == HedPositive <==> c.effect == Reinforcement)
  {
  }

  lemma energyRegime_matches_operant_operator(p: CoreAffectPoint)
    requires p in Z2DiagonalPoints()
    ensures DiagToContingency(p).SomeContingency?
    ensures var c := DiagToContingency(p).val;
      (c.op == Addition <==>
        (ComputeEnergyRegime(p.x, p.y) == PositiveSynergy ||
         ComputeEnergyRegime(p.x, p.y) == NegativeSynergy)) &&
      (c.op == Removal <==>
        (ComputeEnergyRegime(p.x, p.y) == ErgotropicCompensation ||
         ComputeEnergyRegime(p.x, p.y) == TrophotropicRelease))
  {
  }

  lemma antagonist_flips_effect_preserves_operator(p: CoreAffectPoint)
    requires p in Z2DiagonalPoints()
    ensures DiagToContingency(p).SomeContingency?
    ensures DiagToContingency(AntagonistPoint(p)).SomeContingency?
    ensures var c1 := DiagToContingency(p).val;
      var c2 := DiagToContingency(AntagonistPoint(p)).val;
      c1.effect != c2.effect && c1.op == c2.op
  {
  }

  lemma {:isolate_assertions} axial_poles_bridge_operant_pairs()
    ensures ManhattanDistXY(PrimaryCrownPrototypeToPoint(ProtoCourage), PrimaryCrownPrototypeToPoint(ProtoDesir)) == 2
    ensures ManhattanDistXY(PrimaryCrownPrototypeToPoint(ProtoCourage), PrimaryCrownPrototypeToPoint(ProtoCalme)) == 2
    ensures ManhattanDistXY(PrimaryCrownPrototypeToPoint(ProtoCourage), PrimaryCrownPrototypeToPoint(ProtoColere)) == 4
    ensures ManhattanDistXY(PrimaryCrownPrototypeToPoint(ProtoCourage), PrimaryCrownPrototypeToPoint(ProtoDegout)) == 4
    ensures ManhattanDistXY(PrimaryCrownPrototypeToPoint(ProtoPeur), PrimaryCrownPrototypeToPoint(ProtoColere)) == 2
    ensures ManhattanDistXY(PrimaryCrownPrototypeToPoint(ProtoPeur), PrimaryCrownPrototypeToPoint(ProtoDegout)) == 2
    ensures ManhattanDistXY(PrimaryCrownPrototypeToPoint(ProtoPeur), PrimaryCrownPrototypeToPoint(ProtoDesir)) == 4
    ensures ManhattanDistXY(PrimaryCrownPrototypeToPoint(ProtoPeur), PrimaryCrownPrototypeToPoint(ProtoCalme)) == 4
    ensures ManhattanDistXY(PrimaryCrownPrototypeToPoint(ProtoJoie), PrimaryCrownPrototypeToPoint(ProtoDesir)) == 2
    ensures ManhattanDistXY(PrimaryCrownPrototypeToPoint(ProtoJoie), PrimaryCrownPrototypeToPoint(ProtoColere)) == 2
    ensures ManhattanDistXY(PrimaryCrownPrototypeToPoint(ProtoJoie), PrimaryCrownPrototypeToPoint(ProtoCalme)) == 4
    ensures ManhattanDistXY(PrimaryCrownPrototypeToPoint(ProtoJoie), PrimaryCrownPrototypeToPoint(ProtoDegout)) == 4
    ensures ManhattanDistXY(PrimaryCrownPrototypeToPoint(ProtoTristesse), PrimaryCrownPrototypeToPoint(ProtoCalme)) == 2
    ensures ManhattanDistXY(PrimaryCrownPrototypeToPoint(ProtoTristesse), PrimaryCrownPrototypeToPoint(ProtoDegout)) == 2
    ensures ManhattanDistXY(PrimaryCrownPrototypeToPoint(ProtoTristesse), PrimaryCrownPrototypeToPoint(ProtoDesir)) == 4
    ensures ManhattanDistXY(PrimaryCrownPrototypeToPoint(ProtoTristesse), PrimaryCrownPrototypeToPoint(ProtoColere)) == 4
  {
  }

  lemma axial_poles_pre_operant(p: CoreAffectPoint)
    requires p in Z2AxialPoints()
    ensures DiagToContingency(p) == NoContingency
  {
  }

  lemma operant_bijection_on_z2_diagonals()
    ensures forall c: OperantContingency ::
      exists p :: p in Z2DiagonalPoints() && DiagToContingency(p) == SomeContingency(c)
    ensures forall p1, p2 ::
      (p1 in Z2DiagonalPoints() && p2 in Z2DiagonalPoints() &&
       DiagToContingency(p1) == DiagToContingency(p2)) ==> p1 == p2
  {
    var d0 := PrimaryCrownPrototypeToPoint(ProtoDesir);
    var d1 := PrimaryCrownPrototypeToPoint(ProtoCalme);
    var d2 := PrimaryCrownPrototypeToPoint(ProtoDegout);
    var d3 := PrimaryCrownPrototypeToPoint(ProtoColere);
    assert d0 in Z2DiagonalPoints() && DiagToContingency(d0) == SomeContingency(OperantContingency(Reinforcement, Addition));
    assert d1 in Z2DiagonalPoints() && DiagToContingency(d1) == SomeContingency(OperantContingency(Reinforcement, Removal));
    assert d2 in Z2DiagonalPoints() && DiagToContingency(d2) == SomeContingency(OperantContingency(Punishment, Addition));
    assert d3 in Z2DiagonalPoints() && DiagToContingency(d3) == SomeContingency(OperantContingency(Punishment, Removal));
    forall c: OperantContingency
      ensures SomeContingency(c).SomeContingency? &&
        (c == OperantContingency(Reinforcement, Addition) ||
         c == OperantContingency(Reinforcement, Removal) ||
         c == OperantContingency(Punishment, Addition) ||
         c == OperantContingency(Punishment, Removal))
    {
      match c
      case OperantContingency(Reinforcement, Addition) =>
      case OperantContingency(Reinforcement, Removal) =>
      case OperantContingency(Punishment, Addition) =>
      case OperantContingency(Punishment, Removal) =>
    }
  }

}
