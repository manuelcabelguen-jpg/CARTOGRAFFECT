------------------------ MODULE Model_EndToEndBridge -------------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Modele temporel TLC 7/7 : Pont de bout en bout jusqu'a Z = 7 sans interblocage
*)
EXTENDS Integers, Sequences, FiniteSets,
        PredictiveEngine, CoreAffect, AffectiveMatrix, AffectiveTaxonomy,
        AffectiveDynamics, Lexicon176, PredictiveCircuit, OperantFactorization,
        EndToEndBridge

BridgeKernelSet == {
  MkKernelParams(4, 3, 3, 0, 0, 2, 2, 1, 2, 2, 1),
  DefaultKernelParams20
}

BridgeUnifiedSet == {
  [halfScale |-> 4, lambdaNum |-> 4, etaScaled |-> 3, betaAtt |-> 2, alphaCharge |-> 3, sigmoidK |-> 4, zMax |-> 7],
  DefaultUnifiedDynamicsParams
}

BridgeCircStates == {
  DefaultCircularCircuitState,
  MkCircularState(2, TRUE, FALSE, 1, TRUE, 0, 1, 1, MkAttentional(2, 1, 0, 1, 1)),
  MkCircularState(0, TRUE, FALSE, 3, TRUE, 0, 1, 1, MkAttentional(2, 1, 1, 2, 2)),
  MkCircularState(3, TRUE, TRUE,  2, TRUE, 0, 2, 1, MkAttentional(3, 2, 1, 1, 3))
}

BridgeEngineStates ==
  {
    DefaultEngineState,
    MkEngineState(MkDiscrepancy(5, 2, 1), MkPerceptive("pos"), MkSubjective("neg", FALSE), MkAttentional(1, 3, 0, 1, 1)),
    MkEngineState(MkDiscrepancy(5, 2, 1), MkPerceptive("pos"), MkSubjective("neg", TRUE),  MkAttentional(5, 3, 0, 1, 1)),
    MkEngineState(MkDiscrepancy(5, 2, 1), MkPerceptive("zero"), MkSubjective("zero", TRUE), MkAttentional(5, 3, 0, 1, 1)),
    MkEngineState(MkDiscrepancy(6, 2, 1), MkPerceptive("pos"), MkSubjective("neg", TRUE),  MkAttentional(5, 3, 1, 1, 3))
  } \cup {WitnessEngineForPoint(p) : p \in All176Points}

ASSUME
  /\ Thm_all176Entries_unique_labels
  /\ Thm_all176Entries_closed_under_antagonist
  /\ All10_EndToEndBridge(
       0..5,
       1..4,
       BridgeKernelSet,
       All176Points,
       BridgeUnifiedSet,
       0..7,
       {10, 90},
       BridgeCircStates,
       BridgeEngineStates
     )

VARIABLE pt

Stratum1To7Points == {p \in All176Points : p.z \in 1..7}

Init == pt \in Stratum1To7Points

Next ==
  IF pt.z < 7 THEN
    pt' \in {q \in Stratum1To7Points : CanonicalDepthWeight(pt, q) > 0}
  ELSE
    UNCHANGED pt

Spec == Init /\ [][Next]_pt /\ WF_pt(Next)

Inv_ValidBridgePoint ==
  /\ IsValidCoreAffect(pt)
  /\ pt.z \in 1..7
  /\ pt \in All176Points
  /\ AntagonistPoint(pt) \in All176Points
  /\ HasUniqueLexiconEntry(pt)
  /\ HasUniqueLexiconEntry(AntagonistPoint(pt))

Inv_TerminalPipelineCoherence ==
  LET s == WitnessEngineForPoint(pt)
      ts == RunCartograffectPipeline(s)
  IN /\ IsCoherentTerminalStateUnique(s, ts)
     /\ ts.matrix.core = pt
     /\ ts.matrix.antagonist = AntagonistPoint(pt)
     /\ SubsectorToTaxonomicGroup(ts.subsector) = ts.group
     /\ SubsectorToHedonicPolarity(ts.subsector) = ts.matrix.valence

Inv_OperantAntagonistDuality ==
  (pt.x # 0 /\ pt.y # 0) =>
    LET c1 == QuadrantContingency(pt.x, pt.y)
        ap == AntagonistPoint(pt)
        c2 == QuadrantContingency(ap.x, ap.y)
    IN /\ c1.isSome
       /\ c2.isSome
       /\ c1.val.effect # c2.val.effect
       /\ c1.val.op = c2.val.op

Inv_Z7TranscendentalConsistency ==
  (pt.z = 7) =>
    /\ ClassifyStratum(pt.z) = "Z7_sentimentsTranscendants"
    /\ pt \in All176Points

Prop_DepthNonDecreasing == [][pt'.z >= pt.z]_pt

Prop_OperantQuadrantPreserved ==
  [][(pt.x # 0 /\ pt.y # 0) =>
       (pt'.x # 0 /\ pt'.y # 0 /\
        QuadrantContingency(pt'.x, pt'.y) = QuadrantContingency(pt.x, pt.y))]_pt

Prop_EventuallyStratum7 == <>(pt.z = 7)

=============================================================================
