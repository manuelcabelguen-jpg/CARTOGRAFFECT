-------------------------- MODULE Model_DepthKernel ---------------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Modele temporel TLC 3/5 : Noyau stochastique inter-strates (Z=1..5)
*)
EXTENDS Integers, CoreAffect, AffectiveMatrix, AffectiveDynamics, Lexicon176

VARIABLE pt

Stratum1To5Points == {p \in All176Points : p.z \in 1..5}

Init == pt \in Stratum1To5Points

Next ==
  IF pt.z < 5 THEN
    pt' \in {q \in Stratum1To5Points : CanonicalDepthWeight(pt, q) > 0}
  ELSE
    UNCHANGED pt

Spec == Init /\ [][Next]_pt /\ WF_pt(Next)

Inv_ValidStratumPoint == IsValidCoreAffect(pt) /\ pt.z \in 1..5
Inv_OutgoingPositive == pt.z <= 4 => OutgoingWeight(pt) > 0
Inv_AntagonistEquivariant ==
  pt.z < 5 =>
    \A q \in {x \in Stratum1To5Points : x.z = pt.z + 1} :
      CanonicalDepthWeight(AntagonistPoint(pt), AntagonistPoint(q)) = CanonicalDepthWeight(pt, q)

Prop_DepthNonDecreasing == [][pt'.z >= pt.z]_pt
Prop_EventuallyStratum5 == <>(pt.z = 5)

=============================================================================
