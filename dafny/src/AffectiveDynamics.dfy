/*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*/

include "PredictiveEngine.dfy"
include "CoreAffect.dfy"
include "AffectiveMatrix.dfy"
include "AffectiveTaxonomy.dfy"

module AffectiveDynamics {
  import opened PredictiveEngine
  import opened CoreAffect
  import opened AffectiveMatrix
  import opened AffectiveTaxonomy

  // =========================================================================
  // 1. Lemmes auxiliaires de symétrie antagoniste
  // =========================================================================

  lemma AntagonistZ(p: CoreAffectPoint)
    ensures AntagonistPoint(p).z == p.z
  {}

  lemma AntagonistValidB(p: CoreAffectPoint)
    ensures IsValidCoreAffect(AntagonistPoint(p)) == IsValidCoreAffect(p)
  {
    if IsValidCoreAffect(p) {
      antagonistPoint_preserves_validity(p);
    }
    if IsValidCoreAffect(AntagonistPoint(p)) {
      antagonistPoint_preserves_validity(AntagonistPoint(p));
      antagonistPoint_involutive(p);
    }
  }

  lemma AntagonistSignLemmas(p: CoreAffectPoint)
    ensures AntagonistPoint(p).x == 0 <==> p.x == 0
    ensures AntagonistPoint(p).y == 0 <==> p.y == 0
    ensures AntagonistPoint(p).x > 0 <==> p.x < 0
    ensures AntagonistPoint(p).x < 0 <==> p.x > 0
    ensures AntagonistPoint(p).y > 0 <==> p.y < 0
    ensures AntagonistPoint(p).y < 0 <==> p.y > 0
  {}

  lemma MulNonnegIff(a: int, b: int)
    ensures a * b >= 0 <==> !((a > 0 && b < 0) || (a < 0 && b > 0))
  {
    if a > 0 && b > 0 {
    } else if a < 0 && b < 0 {
    } else if a > 0 && b < 0 {
    } else if a < 0 && b > 0 {
    } else {
    }
  }

  lemma AntagonistMulNonneg(p: CoreAffectPoint, q: CoreAffectPoint)
    ensures AntagonistPoint(p).x * AntagonistPoint(q).x >= 0 <==> p.x * q.x >= 0
    ensures AntagonistPoint(p).y * AntagonistPoint(q).y >= 0 <==> p.y * q.y >= 0
  {
    AntagonistSignLemmas(p);
    AntagonistSignLemmas(q);
    MulNonnegIff(p.x, q.x);
    MulNonnegIff(AntagonistPoint(p).x, AntagonistPoint(q).x);
    MulNonnegIff(p.y, q.y);
    MulNonnegIff(AntagonistPoint(p).y, AntagonistPoint(q).y);
  }

  lemma AntagonistDiagIff(p: CoreAffectPoint)
    ensures (AbsNat(AntagonistPoint(p).x) == AbsNat(AntagonistPoint(p).y)) <==>
            (AbsNat(p.x) == AbsNat(p.y))
  {}

  lemma AntagonistNonaxialAbs(r: CoreAffectPoint)
    requires r.x != 0 && r.y != 0
    ensures AbsNat(AntagonistPoint(r).x) == AbsNat(r.y)
    ensures AbsNat(AntagonistPoint(r).y) == AbsNat(r.x)
  {}

  // =========================================================================
  // 2. Noyau canonique d'approfondissement inter-strates (Z -> Z + 1)
  // =========================================================================

  function CanonicalDepthWeight(p: CoreAffectPoint, q: CoreAffectPoint): nat {
    if IsValidCoreAffect(p) && IsValidCoreAffect(q) &&
       q.z == p.z + 1 &&
       p.x * q.x >= 0 && p.y * q.y >= 0 then
      if q.x == 0 && q.y == 0 then
        if p.x == 0 && p.y == 0 then 1 else 0
      else if p.x == 0 && p.y == 0 then
        if p.z == 1 then 1 else 0
      else if p.x == 0 || p.y == 0 then
        if (p.x == 0 || q.x != 0) && (p.y == 0 || q.y != 0) then
          if q.x == 0 || q.y == 0 then 1
          else if AbsNat(q.x) == AbsNat(q.y) then 2
          else 0
        else 0
      else
        if q.x != 0 && q.y != 0 &&
           AbsNat(q.x) >= AbsNat(p.x) && AbsNat(q.y) >= AbsNat(p.y) then
          if AbsNat(p.x) == AbsNat(p.y) && AbsNat(q.x) == AbsNat(q.y) then 2 else 1
        else 0
    else
      0
  }

  lemma canonicalDepthKernel_support_valid(p: CoreAffectPoint, q: CoreAffectPoint)
    requires CanonicalDepthWeight(p, q) != 0
    ensures IsValidCoreAffect(q)
  {}

  lemma canonicalDepthKernel_support_adjacent(p: CoreAffectPoint, q: CoreAffectPoint)
    requires CanonicalDepthWeight(p, q) != 0
    ensures q.z == p.z + 1
  {}

  lemma canonicalDepthKernel_quadrant_preserved(p: CoreAffectPoint, q: CoreAffectPoint)
    requires CanonicalDepthWeight(p, q) != 0
    ensures p.x * q.x >= 0 && p.y * q.y >= 0
  {}

  lemma canonicalDepthKernel_antagonist_equivariant(p: CoreAffectPoint, q: CoreAffectPoint)
    ensures CanonicalDepthWeight(AntagonistPoint(p), AntagonistPoint(q)) == CanonicalDepthWeight(p, q)
  {
    AntagonistZ(p);
    AntagonistZ(q);
    AntagonistValidB(p);
    AntagonistValidB(q);
    AntagonistSignLemmas(p);
    AntagonistSignLemmas(q);
    AntagonistMulNonneg(p, q);
    AntagonistDiagIff(p);
    AntagonistDiagIff(q);
    if p.x != 0 && p.y != 0 {
      AntagonistNonaxialAbs(p);
    }
    if q.x != 0 && q.y != 0 {
      AntagonistNonaxialAbs(q);
    }
  }

  // =========================================================================
  // 3. Atteignabilité des couronnes et des 120 positions latérales
  // =========================================================================

  function PredForCrown(q: CoreAffectPoint): CoreAffectPoint
    requires q.z >= 3
  {
    var rPrev := CrownRadius(q.z - 1);
    if q.x == 0 then
      CoreAffectPoint(0, if q.y > 0 then rPrev else -(rPrev as int), q.z - 1)
    else if q.y == 0 then
      CoreAffectPoint(if q.x > 0 then rPrev else -(rPrev as int), 0, q.z - 1)
    else
      var ax: nat :=
        if AbsNat(q.x) >= 2 then
          if AbsNat(q.y) >= 2 then AbsNat(q.x) - 1 else AbsNat(q.x) - 2
        else 1;
      var ay: nat := if rPrev >= ax then rPrev - ax else 0;
      CoreAffectPoint(
        if q.x > 0 then ax as int else -(ax as int),
        if q.y > 0 then ay as int else -(ay as int),
        q.z - 1
      )
  }

  lemma CanonicalDepthWeightPredPos(q: CoreAffectPoint)
    requires IsValidCoreAffect(q) && q.z >= 3 && !IsCentral(q)
    ensures var p := PredForCrown(q);
      IsValidCoreAffect(p) && !IsCentral(p) && p.z + 1 == q.z && CanonicalDepthWeight(p, q) != 0
  {
    var p := PredForCrown(q);
    MulNonnegIff(p.x, q.x);
    MulNonnegIff(p.y, q.y);
    assert IsValidCoreAffect(p);
    assert !IsCentral(p);
    assert p.z + 1 == q.z;
    assert p.x * q.x >= 0 && p.y * q.y >= 0;
    assert CanonicalDepthWeight(p, q) != 0;
  }

  // [1/10] canonicalDepthKernel_reaches_crown
  lemma canonicalDepthKernel_reaches_crown(q: CoreAffectPoint)
    requires IsValidCoreAffect(q) && q.z >= 3 && !IsCentral(q)
    ensures exists p: CoreAffectPoint ::
      IsValidCoreAffect(p) && p.z + 1 == q.z && CanonicalDepthWeight(p, q) != 0
  {
    CanonicalDepthWeightPredPos(q);
    var p := PredForCrown(q);
    assert IsValidCoreAffect(p) && p.z + 1 == q.z && CanonicalDepthWeight(p, q) != 0;
  }

  // [2/10] canonicalDepthKernel_reaches_lateral
  lemma canonicalDepthKernel_reaches_lateral(q: CoreAffectPoint)
    requires IsValidCoreAffect(q) && ClassifyGeometry(q) == Lateral
    ensures exists p: CoreAffectPoint ::
      IsValidCoreAffect(p) && p.z + 1 == q.z && CanonicalDepthWeight(p, q) != 0
  {
    assert q.z >= 3;
    canonicalDepthKernel_reaches_crown(q);
  }

  // [3/10] lateral_reachable
  lemma lateral_reachable(q: CoreAffectPoint)
    requires IsValidCoreAffect(q) && ClassifyGeometry(q) == Lateral
    ensures exists p: CoreAffectPoint ::
      IsValidCoreAffect(p) && p.z + 1 == q.z && CanonicalDepthWeight(p, q) != 0
  {
    canonicalDepthKernel_reaches_lateral(q);
  }

  ghost predicate ReachableIn(steps: nat, p: CoreAffectPoint, q: CoreAffectPoint)
    decreases steps
  {
    if steps == 0 then p == q
    else exists m: CoreAffectPoint :: ReachableIn(steps - 1, p, m) && CanonicalDepthWeight(m, q) != 0
  }

  ghost predicate Reachable(p: CoreAffectPoint, q: CoreAffectPoint) {
    exists k: nat :: ReachableIn(k, p, q)
  }

  lemma CanonicalDepthKernelCrownFromSurprise(d: nat, q: CoreAffectPoint)
    requires IsValidCoreAffect(q) && q.z == d + 2 && !IsCentral(q)
    ensures ReachableIn(d + 1, CoreAffectPoint(0, 0, 1), q)
    decreases d
  {
    if d == 0 {
      var s1 := CoreAffectPoint(0, 0, 1);
      assert IsValidCoreAffect(s1);
      assert CanonicalDepthWeight(s1, q) != 0;
      assert ReachableIn(0, s1, s1);
      assert ReachableIn(1, s1, q);
    } else {
      CanonicalDepthWeightPredPos(q);
      var p := PredForCrown(q);
      CanonicalDepthKernelCrownFromSurprise(d - 1, p);
      assert ReachableIn(d, CoreAffectPoint(0, 0, 1), p);
      assert CanonicalDepthWeight(p, q) != 0;
      assert ReachableIn(d + 1, CoreAffectPoint(0, 0, 1), q);
    }
  }

  // [4/10] lateral_reachable_from_surprise
  lemma lateral_reachable_from_surprise(q: CoreAffectPoint)
    requires IsValidCoreAffect(q) && ClassifyGeometry(q) == Lateral
    ensures Reachable(CoreAffectPoint(0, 0, 1), q)
  {
    assert q.z >= 3;
    CanonicalDepthKernelCrownFromSurprise(q.z - 2, q);
    assert ReachableIn((q.z - 2) + 1, CoreAffectPoint(0, 0, 1), q);
  }

  // [5/10] canonicalDepthKernel_colere_bifurcates
  lemma canonicalDepthKernel_colere_bifurcates()
    ensures CanonicalDepthWeight(CoreAffectPoint(-1, 1, 2), CoreAffectPoint(-2, 2, 3)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-1, 1, 2), CoreAffectPoint(-1, 3, 3)) == 1
    ensures CanonicalDepthWeight(CoreAffectPoint(-1, 1, 2), CoreAffectPoint(-3, 1, 3)) == 1
  {}

  // [6/10] canonicalDepthKernel_axial_instability_p2
  lemma canonicalDepthKernel_axial_instability_p2()
    ensures CanonicalDepthWeight(CoreAffectPoint(0, 2, 2), CoreAffectPoint(2, 2, 3)) >
            CanonicalDepthWeight(CoreAffectPoint(0, 2, 2), CoreAffectPoint(0, 4, 3))
    ensures CanonicalDepthWeight(CoreAffectPoint(0, 2, 2), CoreAffectPoint(-2, 2, 3)) >
            CanonicalDepthWeight(CoreAffectPoint(0, 2, 2), CoreAffectPoint(0, 4, 3))
  {}

  // =========================================================================
  // 4. Somme sortante discrète et normalisation rationnelle exacte
  // =========================================================================

  function IntRange(k: nat): seq<int> {
    seq(2 * k + 1, i requires 0 <= i < 2 * k + 1 => (i as int) - (k as int))
  }

  lemma MemIntRange(k: nat, v: int)
    requires AbsNat(v) <= k
    ensures v in IntRange(k)
  {
    var idx := v + (k as int);
    assert 0 <= idx < 2 * k + 1;
    assert IntRange(k)[idx] == v;
  }

  function StratumRowPoints(x: int, z: nat, k: nat): seq<CoreAffectPoint> {
    var ys := IntRange(k);
    seq(|ys|, i requires 0 <= i < |ys| => CoreAffectPoint(x, ys[i], z))
  }

  function FlattenStratumRows(xs: seq<int>, z: nat, k: nat): seq<CoreAffectPoint>
    decreases |xs|
  {
    if |xs| == 0 then []
    else StratumRowPoints(xs[0], z, k) + FlattenStratumRows(xs[1..], z, k)
  }

  function FilterValidPoints(pts: seq<CoreAffectPoint>): seq<CoreAffectPoint>
    decreases |pts|
  {
    if |pts| == 0 then []
    else if IsValidCoreAffect(pts[0]) then [pts[0]] + FilterValidPoints(pts[1..])
    else FilterValidPoints(pts[1..])
  }

  function StratumPoints(z: nat): seq<CoreAffectPoint> {
    var b := CrownRadius(z);
    FilterValidPoints(FlattenStratumRows(IntRange(b), z, b))
  }

  lemma MemFilterValid(pts: seq<CoreAffectPoint>, q: CoreAffectPoint)
    requires q in pts && IsValidCoreAffect(q)
    ensures q in FilterValidPoints(pts)
    decreases |pts|
  {
    if pts[0] != q {
      MemFilterValid(pts[1..], q);
    }
  }

  lemma MemFlattenStratumRows(xs: seq<int>, x: int, y: int, z: nat, k: nat)
    requires x in xs && y in IntRange(k)
    ensures CoreAffectPoint(x, y, z) in FlattenStratumRows(xs, z, k)
    decreases |xs|
  {
    if xs[0] == x {
      var ys := IntRange(k);
      var idx :| 0 <= idx < |ys| && ys[idx] == y;
      assert StratumRowPoints(x, z, k)[idx] == CoreAffectPoint(x, y, z);
    } else {
      MemFlattenStratumRows(xs[1..], x, y, z, k);
    }
  }

  lemma MemStratumPointsOfValid(q: CoreAffectPoint)
    requires IsValidCoreAffect(q)
    ensures q in StratumPoints(q.z)
  {
    var b := CrownRadius(q.z);
    assert AbsNat(q.x) <= b && AbsNat(q.y) <= b;
    MemIntRange(b, q.x);
    MemIntRange(b, q.y);
    MemFlattenStratumRows(IntRange(b), q.x, q.y, q.z, b);
    MemFilterValid(FlattenStratumRows(IntRange(b), q.z, b), q);
  }

  function SumWeightsList(p: CoreAffectPoint, qs: seq<CoreAffectPoint>): nat
    decreases |qs|
  {
    if |qs| == 0 then 0
    else CanonicalDepthWeight(p, qs[0]) + SumWeightsList(p, qs[1..])
  }

  lemma WeightLeSumWeightsList(p: CoreAffectPoint, q: CoreAffectPoint, qs: seq<CoreAffectPoint>)
    requires q in qs
    ensures CanonicalDepthWeight(p, q) <= SumWeightsList(p, qs)
    decreases |qs|
  {
    if qs[0] != q {
      WeightLeSumWeightsList(p, q, qs[1..]);
    }
  }

  function OutgoingWeight(p: CoreAffectPoint): nat {
    SumWeightsList(p, StratumPoints(p.z + 1))
  }

  function WitnessSuccForPoint(p: CoreAffectPoint): CoreAffectPoint
    requires IsValidCoreAffect(p)
  {
    var zn := p.z + 1;
    var rn := CrownRadius(zn);
    if p.x == 0 && p.y == 0 then
      CoreAffectPoint(0, 0, zn)
    else if p.x == 0 then
      CoreAffectPoint(0, if p.y > 0 then rn else -(rn as int), zn)
    else if p.y == 0 then
      CoreAffectPoint(if p.x > 0 then rn else -(rn as int), 0, zn)
    else
      CoreAffectPoint(
        if p.x > 0 then p.x + 1 else p.x - 1,
        if p.y > 0 then p.y + 1 else p.y - 1,
        zn
      )
  }

  // [7/10] canonicalDepthKernel_outgoingWeight_pos
  lemma canonicalDepthKernel_outgoingWeight_pos(p: CoreAffectPoint)
    requires IsValidCoreAffect(p)
    ensures OutgoingWeight(p) > 0
  {
    var q := WitnessSuccForPoint(p);
    MulNonnegIff(p.x, q.x);
    MulNonnegIff(p.y, q.y);
    assert IsValidCoreAffect(q);
    assert q.z == p.z + 1;
    assert p.x * q.x >= 0 && p.y * q.y >= 0;
    assert CanonicalDepthWeight(p, q) > 0;
    MemStratumPointsOfValid(q);
    WeightLeSumWeightsList(p, q, StratumPoints(p.z + 1));
  }

  // =========================================================================
  // 5. Appartenance graduée aux attracteurs probabilistes (Résolution R1)
  // =========================================================================

  function AttractorMembership(p: CoreAffectPoint, g: TaxonomicGroup): nat {
    var ax := AbsNat(p.x);
    var ay := AbsNat(p.y);
    var r := ax + ay;
    var m := if ax <= ay then ax else ay;
    match g
    case OperateurCentral => if p.x == 0 && p.y == 0 then 1 else 0
    case GroupeJoie       => if p.y > 0 then (if ay > ax then r else ay) else 0
    case GroupeTristesse  => if p.y < 0 then (if ay > ax then r else ay) else 0
    case GroupeCourage    => if p.x > 0 then (if ax > ay then r else ax) else 0
    case GroupePeur       => if p.x < 0 then (if ax > ay then r else ax) else 0
    case GroupeDesir      => if p.x > 0 && p.y > 0 then 2 * m else 0
    case GroupeDegout     => if p.x < 0 && p.y < 0 then 2 * m else 0
    case GroupeColere     => if p.x < 0 && p.y > 0 then 2 * m else 0
    case GroupeCalme      => if p.x > 0 && p.y < 0 then 2 * m else 0
  }

  // [8/10] classifyTaxonomicGroup_unique_maximizer
  lemma classifyTaxonomicGroup_unique_maximizer(p: CoreAffectPoint, g: TaxonomicGroup)
    requires g != ClassifyTaxonomicGroup(p)
    ensures AttractorMembership(p, g) < AttractorMembership(p, ClassifyTaxonomicGroup(p))
  {
    match g
    case OperateurCentral =>
    case GroupeJoie       =>
    case GroupeTristesse  =>
    case GroupeCourage    =>
    case GroupePeur       =>
    case GroupeDesir      =>
    case GroupeDegout     =>
    case GroupeColere     =>
    case GroupeCalme      =>
  }

  // [9/10] classifyTaxonomicGroup_maximizes_membership
  lemma classifyTaxonomicGroup_maximizes_membership(p: CoreAffectPoint, g: TaxonomicGroup)
    ensures AttractorMembership(p, g) <= AttractorMembership(p, ClassifyTaxonomicGroup(p))
  {
    if g != ClassifyTaxonomicGroup(p) {
      classifyTaxonomicGroup_unique_maximizer(p, g);
    }
  }

  // [10/10] lateral_has_overlapping_attractors
  lemma lateral_has_overlapping_attractors(p: CoreAffectPoint)
    requires ClassifyGeometry(p) == Lateral
    ensures exists g1: TaxonomicGroup, g2: TaxonomicGroup ::
      g1 != g2 && AttractorMembership(p, g1) > 0 && AttractorMembership(p, g2) > 0
  {
    if p.x > 0 && p.y > 0 {
      assert AttractorMembership(p, GroupeJoie) > 0 && AttractorMembership(p, GroupeDesir) > 0;
    } else if p.x > 0 && p.y < 0 {
      assert AttractorMembership(p, GroupeTristesse) > 0 && AttractorMembership(p, GroupeCalme) > 0;
    } else if p.x < 0 && p.y > 0 {
      assert AttractorMembership(p, GroupeJoie) > 0 && AttractorMembership(p, GroupeColere) > 0;
    } else {
      assert AttractorMembership(p, GroupeTristesse) > 0 && AttractorMembership(p, GroupeDegout) > 0;
    }
  }

}
