-------------------------- MODULE EndToEndBridge ----------------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Module derive : EndToEndBridge — Ponts formels complets de bout en bout (TLA+ / TLC)
*)
EXTENDS Integers, Sequences, FiniteSets,
        PredictiveEngine, CoreAffect, AffectiveMatrix, AffectiveTaxonomy,
        AffectiveDynamics, Lexicon176, PredictiveCircuit, OperantFactorization

-----------------------------------------------------------------------------
(* 1. Definitions canoniques des ponts operants et pipelines terminaux *)
-----------------------------------------------------------------------------

RoleCentralOperator == [kind |-> "centralOperator"]
RolePreOperantAxial(sec) == [kind |-> "preOperantAxial", sector |-> sec]
RolePureOperant(c) == [kind |-> "pureOperant", contingency |-> c]
RoleBlendedLateral(sec, c) == [kind |-> "blendedLateral", sector |-> sec, contingency |-> c]

CouplingToContingency(c) ==
  IF c.attente = "pos" /\ c.controle = "pos" THEN SomeContingency(MkContingency("Reinforcement", "Addition"))
  ELSE IF c.attente = "pos" /\ c.controle = "neg" THEN SomeContingency(MkContingency("Reinforcement", "Removal"))
  ELSE IF c.attente = "neg" /\ c.controle = "neg" THEN SomeContingency(MkContingency("Punishment",    "Addition"))
  ELSE IF c.attente = "neg" /\ c.controle = "pos" THEN SomeContingency(MkContingency("Punishment",    "Removal"))
  ELSE NoneContingency

QuadrantContingency(x, y) ==
  IF x > 0 /\ y > 0 THEN SomeContingency(MkContingency("Reinforcement", "Addition"))
  ELSE IF x > 0 /\ y < 0 THEN SomeContingency(MkContingency("Reinforcement", "Removal"))
  ELSE IF x < 0 /\ y < 0 THEN SomeContingency(MkContingency("Punishment",    "Addition"))
  ELSE IF x < 0 /\ y > 0 THEN SomeContingency(MkContingency("Punishment",    "Removal"))
  ELSE NoneContingency

SectorNameOfOption(optSec) ==
  IF optSec = "some_joie" THEN "joie"
  ELSE IF optSec = "some_tristesse" THEN "tristesse"
  ELSE IF optSec = "some_peur" THEN "peur"
  ELSE "courage"

ClassifyOperantRole(p) ==
  LET qc == QuadrantContingency(p.x, p.y)
      sec == DominantSector(p)
  IN IF qc.isSome /\ sec # "none" THEN RoleBlendedLateral(SectorNameOfOption(sec), qc.val)
     ELSE IF qc.isSome THEN RolePureOperant(qc.val)
     ELSE IF sec # "none" THEN RolePreOperantAxial(SectorNameOfOption(sec))
     ELSE RoleCentralOperator

EvaluateUnifiedTaxonomy(p, c, z, rhoHat, kappaHat, susp) ==
  EvaluateTaxonomyOfPoint(ProjectUnifiedState(p, c, z, rhoHat, kappaHat, susp))

EvaluateCircularTaxonomy(s) ==
  EvaluateTaxonomyOfPoint(Op3CrossingIPoint(s))

-----------------------------------------------------------------------------
(* 2. Les 10 predicats de pont complet de bout en bout *)
-----------------------------------------------------------------------------

\* [1/10] circuit_coupling_operant_bridge
Thm_circuit_coupling_operant_bridge(Depths, PrecSet) ==
  \A c \in Couplings, d \in Depths, piA \in PrecSet, piC \in PrecSet, susp \in BOOLEAN :
    /\ DiagToContingency(ProjectPerceptible(c, 2, piA, piC, susp)) = CouplingToContingency(c)
    /\ LET pt == ProjectPerceptible(c, d + 2, piA, piC, susp) IN
       QuadrantContingency(pt.x, pt.y) = CouplingToContingency(c)

\* [2/10] triggerSecondaryGradient_enters_operant
Thm_triggerSecondaryGradient_enters_operant ==
  \A c \in Couplings, newPol \in Polarities :
    (IsSingleEngaged(c) /\ PolarityIsEngaged(newPol)) =>
      LET c2 == TriggerSecondaryGradient(c, newPol)
          p2 == DeployCouplingAtDepth(c2, 0)
      IN /\ DiagToContingency(DeployCouplingAtDepth(c, 0)) = NoneContingency
         /\ \E oc \in OperantContingencies :
              /\ DiagToContingency(p2) = SomeContingency(oc)
              /\ CouplingToContingency(c2) = SomeContingency(oc)
              /\ (c = MkCoupling("pos", "zero") => oc.effect = "Reinforcement")
              /\ (c = MkCoupling("neg", "zero") => oc.effect = "Punishment")
              /\ (c = MkCoupling("zero", "pos") =>
                    (oc = MkContingency("Reinforcement", "Addition") \/
                     oc = MkContingency("Punishment", "Removal")))
              /\ (c = MkCoupling("zero", "neg") =>
                    (oc = MkContingency("Reinforcement", "Removal") \/
                     oc = MkContingency("Punishment", "Addition")))

\* [3/10] p2_markov_contagion_enters_operant_punishment
Thm_p2_markov_contagion_enters_operant_punishment(KernelSet) ==
  \A p \in KernelSet :
    (p.chi > 0 /\ p.qPosC > 0 /\ p.qPosC < p.scale /\ p.rho + p.deltaA < p.scale) =>
      /\ CircuitWeight(p, MkCoupling("neg", "zero"), MkCoupling("neg", "pos")) > 0
      /\ CircuitWeight(p, MkCoupling("neg", "zero"), MkCoupling("neg", "neg")) > 0
      /\ CouplingToContingency(MkCoupling("neg", "zero")) = NoneContingency
      /\ CouplingToContingency(MkCoupling("neg", "pos")) = SomeContingency(MkContingency("Punishment", "Removal"))
      /\ CouplingToContingency(MkCoupling("neg", "neg")) = SomeContingency(MkContingency("Punishment", "Addition"))

\* [4/10] operant_quadrant_lifting_all_strata
Thm_operant_quadrant_lifting_all_strata(PointSet) ==
  /\ (\A p \in PointSet :
        (p.x # 0 /\ p.y # 0) =>
          \E oc \in OperantContingencies :
            /\ QuadrantContingency(p.x, p.y) = SomeContingency(oc)
            /\ ((oc.effect = "Reinforcement") <=> (p.x > 0))
            /\ ((oc.effect = "Punishment") <=> (p.x < 0))
            /\ ((oc.op = "Addition") <=> (p.x * p.y > 0))
            /\ ((oc.op = "Removal") <=> (p.x * p.y < 0))
            /\ ((ComputeHedonicPolarity(p.x, p.y) = "positive") <=> (oc.effect = "Reinforcement"))
            /\ ((oc.op = "Addition") <=>
                  (ComputeEnergyRegime(p.x, p.y) = "positiveSynergy" \/
                   ComputeEnergyRegime(p.x, p.y) = "negativeSynergy"))
            /\ ((oc.op = "Removal") <=>
                  (ComputeEnergyRegime(p.x, p.y) = "ergotropicCompensation" \/
                   ComputeEnergyRegime(p.x, p.y) = "trophotropicRelease")))
  /\ (\A q \in Z2DiagonalPoints :
        QuadrantContingency(q.x, q.y) = DiagToContingency(q))

\* [5/10] operant_antagonist_invariance_all_strata
Thm_operant_antagonist_invariance_all_strata(PointSet) ==
  \A p \in PointSet :
    (p.x # 0 /\ p.y # 0) =>
      \E c1 \in OperantContingencies, c2 \in OperantContingencies :
        /\ QuadrantContingency(p.x, p.y) = SomeContingency(c1)
        /\ QuadrantContingency(AntagonistPoint(p).x, AntagonistPoint(p).y) = SomeContingency(c2)
        /\ c1.effect # c2.effect
        /\ c1.op = c2.op

\* [6/10] depthKernel_preserves_operant_quadrant
Thm_depthKernel_preserves_operant_quadrant(PointSet) ==
  /\ (\A p \in PointSet, q \in PointSet :
        (p.x # 0 /\ p.y # 0 /\ CanonicalDepthWeight(p, q) > 0) =>
          /\ q.x # 0
          /\ q.y # 0
          /\ QuadrantContingency(q.x, q.y) = QuadrantContingency(p.x, p.y))
  /\ CanonicalDepthWeight(MkPoint(2, 0, 2), MkPoint(2, 2, 3)) > 0
  /\ CanonicalDepthWeight(MkPoint(2, 0, 2), MkPoint(2, -2, 3)) > 0
  /\ CanonicalDepthWeight(MkPoint(-2, 0, 2), MkPoint(-2, 2, 3)) > 0
  /\ CanonicalDepthWeight(MkPoint(-2, 0, 2), MkPoint(-2, -2, 3)) > 0
  /\ CanonicalDepthWeight(MkPoint(0, 2, 2), MkPoint(2, 2, 3)) > 0
  /\ CanonicalDepthWeight(MkPoint(0, 2, 2), MkPoint(-2, 2, 3)) > 0
  /\ CanonicalDepthWeight(MkPoint(0, -2, 2), MkPoint(2, -2, 3)) > 0
  /\ CanonicalDepthWeight(MkPoint(0, -2, 2), MkPoint(-2, -2, 3)) > 0

\* [7/10] operant_lineages_reach_z7_transcendentals
Thm_operant_lineages_reach_z7_transcendentals ==
  \* R+ : Desir (1,1,2) -> ... -> Sublimation (6,6,7)
  /\ CanonicalDepthWeight(MkPoint(1, 1, 2), MkPoint(2, 2, 3)) = 2
  /\ CanonicalDepthWeight(MkPoint(2, 2, 3), MkPoint(3, 3, 4)) = 2
  /\ CanonicalDepthWeight(MkPoint(3, 3, 4), MkPoint(4, 4, 5)) = 2
  /\ CanonicalDepthWeight(MkPoint(4, 4, 5), MkPoint(5, 5, 6)) = 2
  /\ CanonicalDepthWeight(MkPoint(5, 5, 6), MkPoint(6, 6, 7)) = 2
  /\ ClassifyOperantRole(MkPoint(6, 6, 7)) = RolePureOperant(MkContingency("Reinforcement", "Addition"))
  /\ ClassifyStratum(7) = "Z7_sentimentsTranscendants"
  /\ ClassifyTaxonomicGroup(MkPoint(6, 6, 7)) = "groupeDesir"
  /\ ClassifySubsector(6, 6) = "diagonalDesire"
  /\ [label |-> "Sublimation", point |-> MkPoint(6, 6, 7)] \in All176EntrySet
  \* R- : Calme (1,-1,2) -> ... -> Impassibilite (6,-6,7)
  /\ CanonicalDepthWeight(MkPoint(1, -1, 2), MkPoint(2, -2, 3)) = 2
  /\ CanonicalDepthWeight(MkPoint(2, -2, 3), MkPoint(3, -3, 4)) = 2
  /\ CanonicalDepthWeight(MkPoint(3, -3, 4), MkPoint(4, -4, 5)) = 2
  /\ CanonicalDepthWeight(MkPoint(4, -4, 5), MkPoint(5, -5, 6)) = 2
  /\ CanonicalDepthWeight(MkPoint(5, -5, 6), MkPoint(6, -6, 7)) = 2
  /\ ClassifyOperantRole(MkPoint(6, -6, 7)) = RolePureOperant(MkContingency("Reinforcement", "Removal"))
  /\ ClassifyStratum(7) = "Z7_sentimentsTranscendants"
  /\ ClassifyTaxonomicGroup(MkPoint(6, -6, 7)) = "groupeCalme"
  /\ ClassifySubsector(6, -6) = "diagonalCalm"
  /\ [label |-> "Impassibilite", point |-> MkPoint(6, -6, 7)] \in All176EntrySet
  \* P+ : Degout (-1,-1,2) -> ... -> Dissolution (-6,-6,7)
  /\ CanonicalDepthWeight(MkPoint(-1, -1, 2), MkPoint(-2, -2, 3)) = 2
  /\ CanonicalDepthWeight(MkPoint(-2, -2, 3), MkPoint(-3, -3, 4)) = 2
  /\ CanonicalDepthWeight(MkPoint(-3, -3, 4), MkPoint(-4, -4, 5)) = 2
  /\ CanonicalDepthWeight(MkPoint(-4, -4, 5), MkPoint(-5, -5, 6)) = 2
  /\ CanonicalDepthWeight(MkPoint(-5, -5, 6), MkPoint(-6, -6, 7)) = 2
  /\ ClassifyOperantRole(MkPoint(-6, -6, 7)) = RolePureOperant(MkContingency("Punishment", "Addition"))
  /\ ClassifyStratum(7) = "Z7_sentimentsTranscendants"
  /\ ClassifyTaxonomicGroup(MkPoint(-6, -6, 7)) = "groupeDegout"
  /\ ClassifySubsector(-6, -6) = "diagonalDisgust"
  /\ [label |-> "Dissolution", point |-> MkPoint(-6, -6, 7)] \in All176EntrySet
  \* P- : Colere (-1,1,2) -> ... -> Rage (-6,6,7)
  /\ CanonicalDepthWeight(MkPoint(-1, 1, 2), MkPoint(-2, 2, 3)) = 2
  /\ CanonicalDepthWeight(MkPoint(-2, 2, 3), MkPoint(-3, 3, 4)) = 2
  /\ CanonicalDepthWeight(MkPoint(-3, 3, 4), MkPoint(-4, 4, 5)) = 2
  /\ CanonicalDepthWeight(MkPoint(-4, 4, 5), MkPoint(-5, 5, 6)) = 2
  /\ CanonicalDepthWeight(MkPoint(-5, 5, 6), MkPoint(-6, 6, 7)) = 2
  /\ ClassifyOperantRole(MkPoint(-6, 6, 7)) = RolePureOperant(MkContingency("Punishment", "Removal"))
  /\ ClassifyStratum(7) = "Z7_sentimentsTranscendants"
  /\ ClassifyTaxonomicGroup(MkPoint(-6, 6, 7)) = "groupeColere"
  /\ ClassifySubsector(-6, 6) = "diagonalAnger"
  /\ [label |-> "Rage", point |-> MkPoint(-6, 6, 7)] \in All176EntrySet

\* [8/10] unified_circuit_to_taxonomy_coherence
Thm_unified_circuit_to_taxonomy_coherence(UnifiedSet, ZSet, HatSet) ==
  \A p \in UnifiedSet, c \in Couplings, z \in ZSet, rH \in HatSet, kH \in HatSet, susp \in BOOLEAN :
    LET ts == EvaluateUnifiedTaxonomy(p, c, z, rH, kH, susp)
        cp == ts.matrix.core
        ap == ts.matrix.antagonist
    IN /\ IsValidCoreAffect(cp)
       /\ IsValidCoreAffect(ap)
       /\ ts.stratum = ClassifyStratum(cp.z)
       /\ MatchesTaxonomicGroup(cp, ts.group)
       /\ SubsectorToTaxonomicGroup(ts.subsector) = ts.group
       /\ SubsectorToHedonicPolarity(ts.subsector) = ts.matrix.valence
       /\ (z >= 2 => QuadrantContingency(cp.x, cp.y) = CouplingToContingency(c))
       /\ (z <= 7 => (cp \in All176Points /\ ap \in All176Points))

\* [9/10] circularCycle_to_taxonomy_and_lexicon_coherence
Thm_circularCycle_to_taxonomy_and_lexicon_coherence(CircStateSet) ==
  \A s \in CircStateSet :
    LET ts == EvaluateCircularTaxonomy(s)
        cp == ts.matrix.core
        ap == ts.matrix.antagonist
        c == MkCoupling(Op1SubjectiveOut(s), Op2PerceptiveOut(s))
    IN /\ IsValidCoreAffect(cp)
       /\ IsValidCoreAffect(ap)
       /\ MatchesTaxonomicGroup(cp, ts.group)
       /\ SubsectorToTaxonomicGroup(ts.subsector) = ts.group
       /\ SubsectorToHedonicPolarity(ts.subsector) = ts.matrix.valence
       /\ (AttentionalIsEngaged(s.attentional) =>
             QuadrantContingency(cp.x, cp.y) = CouplingToContingency(c))
       /\ (s.attentional.persistenceDepth <= 5 =>
             /\ cp.z <= 7
             /\ cp \in All176Points
             /\ ap \in All176Points)

\* [10/10] full_end_to_end_lexicon_resolution
Thm_full_end_to_end_lexicon_resolution(StateSet) ==
  \A s \in StateSet :
    (ProjectToCoreAffect(s).z <= 7) =>
      LET ts == RunCartograffectPipeline(s)
          cp == ts.matrix.core
          ap == ts.matrix.antagonist
      IN /\ IsCoherentTerminalStateUnique(s, ts)
         /\ HasUniqueLexiconEntry(cp)
         /\ HasUniqueLexiconEntry(ap)
         /\ ((cp.x # 0 /\ cp.y # 0) =>
               \E c1 \in OperantContingencies, c2 \in OperantContingencies :
                 /\ QuadrantContingency(cp.x, cp.y) = SomeContingency(c1)
                 /\ QuadrantContingency(ap.x, ap.y) = SomeContingency(c2)
                 /\ c1.effect # c2.effect
                 /\ c1.op = c2.op)

All10_EndToEndBridge(Depths, PrecSet, KernelSet, PointSet, UnifiedSet, ZSet, HatSet, CircStateSet, StateSet) ==
  /\ Thm_circuit_coupling_operant_bridge(Depths, PrecSet)
  /\ Thm_triggerSecondaryGradient_enters_operant
  /\ Thm_p2_markov_contagion_enters_operant_punishment(KernelSet)
  /\ Thm_operant_quadrant_lifting_all_strata(PointSet)
  /\ Thm_operant_antagonist_invariance_all_strata(PointSet)
  /\ Thm_depthKernel_preserves_operant_quadrant(PointSet)
  /\ Thm_operant_lineages_reach_z7_transcendentals
  /\ Thm_unified_circuit_to_taxonomy_coherence(UnifiedSet, ZSet, HatSet)
  /\ Thm_circularCycle_to_taxonomy_and_lexicon_coherence(CircStateSet)
  /\ Thm_full_end_to_end_lexicon_resolution(StateSet)

=============================================================================
