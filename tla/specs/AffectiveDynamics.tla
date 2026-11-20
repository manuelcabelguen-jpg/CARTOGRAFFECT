-------------------------- MODULE AffectiveDynamics -------------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Module 05 : Dynamique inter-strates et attracteurs R1 (TLA+ / TLC)
*)
EXTENDS Integers, CoreAffect, AffectiveMatrix, AffectiveTaxonomy

CanonicalDepthWeight(p, q) ==
  LET px == p.x
      py == p.y
      pz == p.z
      qx == q.x
      qy == q.y
      qz == q.z
  IN IF /\ IsValidCoreAffect(p)
        /\ IsValidCoreAffect(q)
        /\ qz = pz + 1
        /\ px * qx >= 0
        /\ py * qy >= 0
     THEN
       IF qx = 0 /\ qy = 0 THEN
         IF px = 0 /\ py = 0 THEN 1 ELSE 0
       ELSE IF px = 0 /\ py = 0 THEN
         IF pz = 1 THEN 1 ELSE 0
       ELSE IF px = 0 \/ py = 0 THEN
         IF (px = 0 \/ qx # 0) /\ (py = 0 \/ qy # 0) THEN
           IF qx = 0 \/ qy = 0 THEN 1
           ELSE IF IntAbs(qx) = IntAbs(qy) THEN 2 ELSE 0
         ELSE 0
       ELSE IF qx # 0 /\ qy # 0 /\ IntAbs(qx) >= IntAbs(px) /\ IntAbs(qy) >= IntAbs(py) THEN
         IF IntAbs(px) = IntAbs(py) /\ IntAbs(qx) = IntAbs(qy) THEN 2 ELSE 1
       ELSE 0
     ELSE 0

PredForCrown(q) ==
  LET qx == q.x
      qy == q.y
      qz == q.z
      rPrev == CrownRadius(qz - 1)
  IN IF qx = 0 THEN
       MkPoint(0, IF qy > 0 THEN rPrev ELSE -rPrev, qz - 1)
     ELSE IF qy = 0 THEN
       MkPoint(IF qx > 0 THEN rPrev ELSE -rPrev, 0, qz - 1)
     ELSE
       LET ax == IF IntAbs(qx) >= 2 THEN
                   IF IntAbs(qy) >= 2 THEN IntAbs(qx) - 1 ELSE IntAbs(qx) - 2
                 ELSE 1
           ay == rPrev - ax
       IN MkPoint(IF qx > 0 THEN ax ELSE -ax, IF qy > 0 THEN ay ELSE -ay, qz - 1)

WitnessSuccForPoint(p) ==
  LET px == p.x
      py == p.y
      pz == p.z
      zn == pz + 1
      rn == CrownRadius(zn)
  IN IF px = 0 /\ py = 0 THEN MkPoint(0, 0, zn)
     ELSE IF px = 0 THEN MkPoint(0, IF py > 0 THEN rn ELSE -rn, zn)
     ELSE IF py = 0 THEN MkPoint(IF px > 0 THEN rn ELSE -rn, 0, zn)
     ELSE MkPoint(IF px > 0 THEN px + 1 ELSE px - 1,
                  IF py > 0 THEN py + 1 ELSE py - 1,
                  zn)

SumCrownRowAtAx(p, znext, ax, ay) ==
  IF ax = 0 THEN
    CanonicalDepthWeight(p, MkPoint(0, ay, znext))
    + CanonicalDepthWeight(p, MkPoint(0, -ay, znext))
  ELSE IF ay = 0 THEN
    CanonicalDepthWeight(p, MkPoint(ax, 0, znext))
    + CanonicalDepthWeight(p, MkPoint(-ax, 0, znext))
  ELSE
    CanonicalDepthWeight(p, MkPoint(ax, ay, znext))
    + CanonicalDepthWeight(p, MkPoint(ax, -ay, znext))
    + CanonicalDepthWeight(p, MkPoint(-ax, ay, znext))
    + CanonicalDepthWeight(p, MkPoint(-ax, -ay, znext))

RECURSIVE SumCrownWeightsRec(_, _, _, _)
SumCrownWeightsRec(p, znext, r, ax) ==
  IF ax < 0 THEN 0
  ELSE SumCrownRowAtAx(p, znext, ax, r - ax) + SumCrownWeightsRec(p, znext, r, ax - 1)

OutgoingWeight(p) ==
  LET zn == p.z + 1 IN
  CanonicalDepthWeight(p, MkPoint(0, 0, zn))
  + (IF zn < 2 THEN 0 ELSE SumCrownWeightsRec(p, zn, CrownRadius(zn), CrownRadius(zn)))

AttractorMembership(p, g) ==
  LET px == p.x
      py == p.y
      ax == IntAbs(px)
      ay == IntAbs(py)
      r == ax + ay
      m == IF ax <= ay THEN ax ELSE ay
  IN IF g = "operateurCentral" THEN IF px = 0 /\ py = 0 THEN 1 ELSE 0
     ELSE IF g = "groupeJoie" THEN IF py > 0 THEN IF ay > ax THEN r ELSE ay ELSE 0
     ELSE IF g = "groupeTristesse" THEN IF py < 0 THEN IF ay > ax THEN r ELSE ay ELSE 0
     ELSE IF g = "groupeCourage" THEN IF px > 0 THEN IF ax > ay THEN r ELSE ax ELSE 0
     ELSE IF g = "groupePeur" THEN IF px < 0 THEN IF ax > ay THEN r ELSE ax ELSE 0
     ELSE IF g = "groupeDesir" THEN IF px > 0 /\ py > 0 THEN 2 * m ELSE 0
     ELSE IF g = "groupeDegout" THEN IF px < 0 /\ py < 0 THEN 2 * m ELSE 0
     ELSE IF g = "groupeColere" THEN IF px < 0 /\ py > 0 THEN 2 * m ELSE 0
     ELSE IF px > 0 /\ py < 0 THEN 2 * m ELSE 0

-----------------------------------------------------------------------------
(* 4 DepthTransitionKernel laws + 10 audited theorems for AffectiveDynamics *)
-----------------------------------------------------------------------------

DepthKernelLawsOk(PointSet) ==
  \A p \in PointSet, q \in PointSet :
    /\ CanonicalDepthWeight(p, q) >= 0
    /\ (CanonicalDepthWeight(p, q) # 0 =>
         /\ IsValidCoreAffect(q)
         /\ q.z = p.z + 1
         /\ p.x * q.x >= 0
         /\ p.y * q.y >= 0)
    /\ CanonicalDepthWeight(AntagonistPoint(p), AntagonistPoint(q)) = CanonicalDepthWeight(p, q)

Thm_canonicalDepthKernel_reaches_crown(PointSet) ==
  \A q \in PointSet :
    (IsValidCoreAffect(q) /\ q.z >= 3 /\ ~IsCentral(q)) =>
      LET p == PredForCrown(q) IN
      /\ IsValidCoreAffect(p)
      /\ p.z + 1 = q.z
      /\ CanonicalDepthWeight(p, q) # 0

Thm_canonicalDepthKernel_reaches_lateral(PointSet) ==
  \A q \in PointSet :
    (IsValidCoreAffect(q) /\ ClassifyGeometry(q) = "lateral") =>
      LET p == PredForCrown(q) IN
      /\ IsValidCoreAffect(p)
      /\ p.z + 1 = q.z
      /\ CanonicalDepthWeight(p, q) # 0

Thm_lateral_reachable(PointSet) ==
  \A q \in PointSet :
    (IsValidCoreAffect(q) /\ ClassifyGeometry(q) = "lateral") =>
      \E p \in PointSet :
        /\ IsValidCoreAffect(p)
        /\ p.z + 1 = q.z
        /\ CanonicalDepthWeight(p, q) # 0

RECURSIVE LateralTraceToSurprise(_)
LateralTraceToSurprise(q) ==
  IF q.z = 2 THEN
    /\ IsValidCoreAffect(q)
    /\ ~IsCentral(q)
    /\ CanonicalDepthWeight(MkPoint(0, 0, 1), q) # 0
  ELSE IF q.z >= 3 THEN
    LET p == PredForCrown(q) IN
    /\ IsValidCoreAffect(p)
    /\ ~IsCentral(p)
    /\ p.z + 1 = q.z
    /\ CanonicalDepthWeight(p, q) # 0
    /\ LateralTraceToSurprise(p)
  ELSE FALSE

Thm_lateral_reachable_from_surprise(PointSet) ==
  \A q \in PointSet :
    (IsValidCoreAffect(q) /\ ClassifyGeometry(q) = "lateral") =>
      /\ q.z >= 3
      /\ ~IsCentral(q)
      /\ LateralTraceToSurprise(q)

Thm_canonicalDepthKernel_colere_bifurcates ==
  /\ CanonicalDepthWeight(MkPoint(-1, 1, 2), MkPoint(-2, 2, 3)) = 2
  /\ CanonicalDepthWeight(MkPoint(-1, 1, 2), MkPoint(-1, 3, 3)) = 1
  /\ CanonicalDepthWeight(MkPoint(-1, 1, 2), MkPoint(-3, 1, 3)) = 1

Thm_canonicalDepthKernel_axial_instability_p2 ==
  /\ CanonicalDepthWeight(MkPoint(0, 2, 2), MkPoint(2, 2, 3))
     > CanonicalDepthWeight(MkPoint(0, 2, 2), MkPoint(0, 4, 3))
  /\ CanonicalDepthWeight(MkPoint(0, 2, 2), MkPoint(-2, 2, 3))
     > CanonicalDepthWeight(MkPoint(0, 2, 2), MkPoint(0, 4, 3))

Thm_canonicalDepthKernel_outgoingWeight_pos(PointSet) ==
  \A p \in PointSet :
    IsValidCoreAffect(p) =>
      LET q == WitnessSuccForPoint(p) IN
      /\ IsValidCoreAffect(q)
      /\ q.z = p.z + 1
      /\ CanonicalDepthWeight(p, q) > 0
      /\ OutgoingWeight(p) > 0

Thm_classifyTaxonomicGroup_unique_maximizer(PointSet) ==
  \A p \in PointSet, g \in TaxonomicGroups :
    (g # ClassifyTaxonomicGroup(p)) =>
      AttractorMembership(p, g) < AttractorMembership(p, ClassifyTaxonomicGroup(p))

Thm_classifyTaxonomicGroup_maximizes_membership(PointSet) ==
  \A p \in PointSet, g \in TaxonomicGroups :
    AttractorMembership(p, g) <= AttractorMembership(p, ClassifyTaxonomicGroup(p))

Thm_lateral_has_overlapping_attractors(PointSet) ==
  \A p \in PointSet :
    ClassifyGeometry(p) = "lateral" =>
      LET g1 == IF p.y > 0 THEN "groupeJoie" ELSE "groupeTristesse"
          g2 == IF p.x > 0 THEN (IF p.y > 0 THEN "groupeDesir" ELSE "groupeCalme")
                ELSE (IF p.y > 0 THEN "groupeColere" ELSE "groupeDegout")
      IN /\ g1 # g2
         /\ AttractorMembership(p, g1) > 0
         /\ AttractorMembership(p, g2) > 0

=============================================================================
