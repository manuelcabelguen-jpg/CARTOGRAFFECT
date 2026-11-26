------------------------- MODULE AffectiveTaxonomy --------------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Module 04 : Taxonomie, strates, groupes, sous-secteurs et pipeline R4 (TLA+ / TLC)
*)
EXTENDS Integers, PredictiveEngine, CoreAffect, AffectiveMatrix

OrientationSectors == {"joie", "tristesse", "peur", "courage"}
TaxonomicGroups == {
  "operateurCentral", "groupeJoie", "groupeTristesse", "groupePeur",
  "groupeCourage", "groupeDesir", "groupeDegout", "groupeColere", "groupeCalme"
}
FunctionalSubsectors == {
  "centralOperator", "axialElan", "axialWithdrawal", "axialOpening", "axialThreat",
  "diagonalDesire", "diagonalDisgust", "diagonalAnger", "diagonalCalm",
  "lateralApproachSynergy", "lateralDefensiveUrgency",
  "lateralTrophotropicPeace", "lateralAversiveDistress",
  "lateralEpistemicMastery", "lateralContemplativeOpen",
  "lateralVigilantAlert", "lateralEpistemicClosure"
}

DominantSector(p) ==
  IF IntAbs(p.y) > IntAbs(p.x) THEN
    IF p.y > 0 THEN "some_joie" ELSE "some_tristesse"
  ELSE IF IntAbs(p.x) > IntAbs(p.y) THEN
    IF p.x < 0 THEN "some_peur" ELSE "some_courage"
  ELSE "none"

ClassifyStratum(z) ==
  IF z = 0 THEN "Z0_pointDeVeille"
  ELSE IF z = 1 THEN "Z1_saillancePerceptive"
  ELSE IF z = 2 THEN "Z2_affectsPrimaires"
  ELSE IF z = 3 THEN "Z3_emotionsReactives"
  ELSE IF z = 4 THEN "Z4_sentimentsReflexifs"
  ELSE IF z = 5 THEN "Z5_orientationsDurables"
  ELSE IF z = 6 THEN "Z6_identitesAffectives"
  ELSE IF z = 7 THEN "Z7_sentimentsTranscendants"
  ELSE [kind |-> "ZDeepProlongation", depth |-> z]

MatchesTaxonomicGroup(p, g) ==
  LET x == p.x
      y == p.y
  IN IF g = "operateurCentral" THEN x = 0 /\ y = 0
     ELSE IF g = "groupeJoie" THEN IntAbs(y) > IntAbs(x) /\ y > 0
     ELSE IF g = "groupeTristesse" THEN IntAbs(y) > IntAbs(x) /\ y < 0
     ELSE IF g = "groupePeur" THEN IntAbs(x) > IntAbs(y) /\ x < 0
     ELSE IF g = "groupeCourage" THEN IntAbs(x) > IntAbs(y) /\ x > 0
     ELSE IF g = "groupeDesir" THEN IntAbs(x) = IntAbs(y) /\ x > 0 /\ y > 0
     ELSE IF g = "groupeDegout" THEN IntAbs(x) = IntAbs(y) /\ x < 0 /\ y < 0
     ELSE IF g = "groupeColere" THEN IntAbs(x) = IntAbs(y) /\ x < 0 /\ y > 0
     ELSE IntAbs(x) = IntAbs(y) /\ x > 0 /\ y < 0

ClassifyTaxonomicGroup(p) ==
  LET x == p.x
      y == p.y
  IN IF x = 0 /\ y = 0 THEN "operateurCentral"
     ELSE IF IntAbs(y) > IntAbs(x) THEN IF y > 0 THEN "groupeJoie" ELSE "groupeTristesse"
     ELSE IF IntAbs(x) > IntAbs(y) THEN IF x < 0 THEN "groupePeur" ELSE "groupeCourage"
     ELSE IF x > 0 THEN IF y > 0 THEN "groupeDesir" ELSE "groupeCalme"
     ELSE IF y > 0 THEN "groupeColere" ELSE "groupeDegout"

ClassifySubsector(x, y) ==
  IF x = 0 /\ y = 0 THEN "centralOperator"
  ELSE IF x = 0 /\ y > 0 THEN "axialElan"
  ELSE IF x = 0 /\ y < 0 THEN "axialWithdrawal"
  ELSE IF x > 0 /\ y = 0 THEN "axialOpening"
  ELSE IF x < 0 /\ y = 0 THEN "axialThreat"
  ELSE IF x = y /\ x > 0 THEN "diagonalDesire"
  ELSE IF x = y /\ x < 0 THEN "diagonalDisgust"
  ELSE IF x = -y /\ x < 0 THEN "diagonalAnger"
  ELSE IF x = -y /\ x > 0 THEN "diagonalCalm"
  ELSE IF y > IntAbs(x) /\ x > 0 THEN "lateralApproachSynergy"
  ELSE IF y > IntAbs(x) /\ x < 0 THEN "lateralDefensiveUrgency"
  ELSE IF -y > IntAbs(x) /\ x > 0 THEN "lateralTrophotropicPeace"
  ELSE IF -y > IntAbs(x) /\ x < 0 THEN "lateralAversiveDistress"
  ELSE IF x > IntAbs(y) /\ y > 0 THEN "lateralEpistemicMastery"
  ELSE IF x > IntAbs(y) /\ y < 0 THEN "lateralContemplativeOpen"
  ELSE IF -x > IntAbs(y) /\ y > 0 THEN "lateralVigilantAlert"
  ELSE "lateralEpistemicClosure"

MatchesSubsector(x, y, sub) ==
  IF sub = "centralOperator" THEN x = 0 /\ y = 0
  ELSE IF sub = "axialElan" THEN x = 0 /\ y > 0
  ELSE IF sub = "axialWithdrawal" THEN x = 0 /\ y < 0
  ELSE IF sub = "axialOpening" THEN x > 0 /\ y = 0
  ELSE IF sub = "axialThreat" THEN x < 0 /\ y = 0
  ELSE IF sub = "diagonalDesire" THEN x = y /\ x > 0
  ELSE IF sub = "diagonalDisgust" THEN x = y /\ x < 0
  ELSE IF sub = "diagonalAnger" THEN x = -y /\ x < 0
  ELSE IF sub = "diagonalCalm" THEN x = -y /\ x > 0
  ELSE IF sub = "lateralApproachSynergy" THEN y > IntAbs(x) /\ x > 0
  ELSE IF sub = "lateralDefensiveUrgency" THEN y > IntAbs(x) /\ x < 0
  ELSE IF sub = "lateralTrophotropicPeace" THEN -y > IntAbs(x) /\ x > 0
  ELSE IF sub = "lateralAversiveDistress" THEN -y > IntAbs(x) /\ x < 0
  ELSE IF sub = "lateralEpistemicMastery" THEN x > IntAbs(y) /\ y > 0
  ELSE IF sub = "lateralContemplativeOpen" THEN x > IntAbs(y) /\ y < 0
  ELSE IF sub = "lateralVigilantAlert" THEN -x > IntAbs(y) /\ y > 0
  ELSE -x > IntAbs(y) /\ y < 0

SubsectorToTaxonomicGroup(sub) ==
  IF sub = "centralOperator" THEN "operateurCentral"
  ELSE IF sub \in {"axialElan", "lateralApproachSynergy", "lateralDefensiveUrgency"} THEN "groupeJoie"
  ELSE IF sub \in {"axialWithdrawal", "lateralTrophotropicPeace", "lateralAversiveDistress"} THEN "groupeTristesse"
  ELSE IF sub \in {"axialOpening", "lateralEpistemicMastery", "lateralContemplativeOpen"} THEN "groupeCourage"
  ELSE IF sub \in {"axialThreat", "lateralVigilantAlert", "lateralEpistemicClosure"} THEN "groupePeur"
  ELSE IF sub = "diagonalDesire" THEN "groupeDesir"
  ELSE IF sub = "diagonalDisgust" THEN "groupeDegout"
  ELSE IF sub = "diagonalAnger" THEN "groupeColere"
  ELSE "groupeCalme"

SubsectorToHedonicPolarity(sub) ==
  IF sub = "centralOperator" THEN "neutral"
  ELSE IF sub \in {
    "axialElan", "axialOpening", "diagonalDesire", "diagonalCalm",
    "lateralApproachSynergy", "lateralTrophotropicPeace",
    "lateralEpistemicMastery", "lateralContemplativeOpen"
  } THEN "positive"
  ELSE "negative"

CrownPeripheralCount(z) == 4 * CrownRadius(z)
StratumTotalCount(z) == 1 + CrownPeripheralCount(z)

EvaluateTaxonomy(m) ==
  LET cp == m.core
      ap == m.antagonist
  IN [
    matrix |-> m,
    stratum |-> ClassifyStratum(cp.z),
    geometry |-> ClassifyGeometry(cp),
    group |-> ClassifyTaxonomicGroup(cp),
    subsector |-> ClassifySubsector(cp.x, cp.y),
    antagonistGroup |-> ClassifyTaxonomicGroup(ap),
    antagonistSubsector |-> ClassifySubsector(ap.x, ap.y)
  ]

EvaluateTaxonomyOfPoint(p) ==
  EvaluateTaxonomy(EvaluateMatrixCanonical(p))

RunCartograffectPipeline(s) ==
  EvaluateTaxonomyOfPoint(ProjectToCoreAffect(s))

IsCoherentTerminalState(s, ts) ==
  LET m == ts.matrix
      cp == m.core
      ap == m.antagonist
  IN /\ cp = ProjectToCoreAffect(s)
     /\ IsValidCoreAffect(cp)
     /\ ap = AntagonistPoint(cp)
     /\ IsValidCoreAffect(ap)
     /\ ap.z = cp.z
     /\ DisplacementSum(ap) = DisplacementSum(cp)
     /\ m.expectationPole = TransduceExpectation(cp.x)
     /\ m.controlPole = TransduceControl(cp.y)
     /\ m.energyRegime = ComputeEnergyRegime(cp.x, cp.y)
     /\ m.valence = ComputeHedonicPolarity(cp.x, cp.y)
     /\ m.activation = ComputeActivation(cp)
     /\ ts.stratum = ClassifyStratum(cp.z)
     /\ ts.geometry = ClassifyGeometry(cp)
     /\ ts.subsector = ClassifySubsector(cp.x, cp.y)
     /\ ts.antagonistSubsector = ClassifySubsector(ap.x, ap.y)
     /\ MatchesTaxonomicGroup(cp, ts.group)
     /\ (\A g \in TaxonomicGroups : MatchesTaxonomicGroup(cp, g) => g = ts.group)
     /\ MatchesTaxonomicGroup(ap, ts.antagonistGroup)

IsCoherentTerminalStateUnique(s, ts) ==
  /\ IsCoherentTerminalState(s, ts)
  /\ ts = RunCartograffectPipeline(s)
  /\ (\A g \in TaxonomicGroups : MatchesTaxonomicGroup(ts.matrix.core, g) => g = ts.group)
  /\ (\A ag \in TaxonomicGroups : MatchesTaxonomicGroup(ts.matrix.antagonist, ag) => ag = ts.antagonistGroup)

-----------------------------------------------------------------------------
(* 10 audited theorem predicates for AffectiveTaxonomy *)
-----------------------------------------------------------------------------

Thm_inventory_176_certified ==
  /\ CrownPeripheralCount(2) = 8
  /\ CrownPeripheralCount(3) = 16
  /\ CrownPeripheralCount(4) = 24
  /\ CrownPeripheralCount(5) = 32
  /\ CrownPeripheralCount(6) = 40
  /\ CrownPeripheralCount(7) = 48
  /\ (CrownPeripheralCount(2) + CrownPeripheralCount(3) + CrownPeripheralCount(4)
      + CrownPeripheralCount(5) + CrownPeripheralCount(6) + CrownPeripheralCount(7)) = 168
  /\ (StratumTotalCount(0) + StratumTotalCount(1) + StratumTotalCount(2) + StratumTotalCount(3)
      + StratumTotalCount(4) + StratumTotalCount(5) + StratumTotalCount(6) + StratumTotalCount(7)) = 176

Thm_taxonomy_group_exhaustive(PointSet) ==
  \A p \in PointSet : \E g \in TaxonomicGroups : MatchesTaxonomicGroup(p, g)

Thm_taxonomy_group_exclusive(PointSet) ==
  \A p \in PointSet, g1 \in TaxonomicGroups, g2 \in TaxonomicGroups :
    (MatchesTaxonomicGroup(p, g1) /\ MatchesTaxonomicGroup(p, g2)) => g1 = g2

Thm_dominantSector_iff_taxonomicGroup(PointSet) ==
  \A p \in PointSet :
    /\ (DominantSector(p) = "some_joie") <=> MatchesTaxonomicGroup(p, "groupeJoie")
    /\ (DominantSector(p) = "some_tristesse") <=> MatchesTaxonomicGroup(p, "groupeTristesse")
    /\ (DominantSector(p) = "some_peur") <=> MatchesTaxonomicGroup(p, "groupePeur")
    /\ (DominantSector(p) = "some_courage") <=> MatchesTaxonomicGroup(p, "groupeCourage")

Thm_contralateral_group_bindings(PointSet) ==
  \A p \in PointSet :
    /\ ((MatchesTaxonomicGroup(p, "groupeJoie") /\ p.x > 0) =>
          MatchesTaxonomicGroup(AntagonistPoint(p), "groupePeur") /\ AntagonistPoint(p).y < 0)
    /\ ((MatchesTaxonomicGroup(p, "groupeJoie") /\ p.x < 0) =>
          MatchesTaxonomicGroup(AntagonistPoint(p), "groupeCourage") /\ AntagonistPoint(p).y < 0)
    /\ ((MatchesTaxonomicGroup(p, "groupeTristesse") /\ p.x > 0) =>
          MatchesTaxonomicGroup(AntagonistPoint(p), "groupePeur") /\ AntagonistPoint(p).y > 0)
    /\ ((MatchesTaxonomicGroup(p, "groupeTristesse") /\ p.x < 0) =>
          MatchesTaxonomicGroup(AntagonistPoint(p), "groupeCourage") /\ AntagonistPoint(p).y > 0)

Thm_classifySubsector_correct(Range) ==
  \A x \in Range, y \in Range : MatchesSubsector(x, y, ClassifySubsector(x, y))

Thm_subsector_exclusive(Range) ==
  \A x \in Range, y \in Range, s1 \in FunctionalSubsectors, s2 \in FunctionalSubsectors :
    (MatchesSubsector(x, y, s1) /\ MatchesSubsector(x, y, s2)) => s1 = s2

Thm_classifySubsector_refines_group(PointSet) ==
  \A p \in PointSet : SubsectorToTaxonomicGroup(ClassifySubsector(p.x, p.y)) = ClassifyTaxonomicGroup(p)

Thm_classifySubsector_determines_valence(Range) ==
  \A x \in Range, y \in Range :
    SubsectorToHedonicPolarity(ClassifySubsector(x, y)) = ComputeHedonicPolarity(x, y)

Thm_end_to_end_coherence(StateSet) ==
  \A s \in StateSet :
    LET ts == RunCartograffectPipeline(s) IN
    /\ IsCoherentTerminalState(s, ts)
    /\ ts.group = ClassifyTaxonomicGroup(ProjectToCoreAffect(s))

=============================================================================
