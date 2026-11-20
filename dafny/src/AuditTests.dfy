/*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*/

include "PredictiveEngine.dfy"
include "CoreAffect.dfy"
include "AffectiveMatrix.dfy"
include "AffectiveTaxonomy.dfy"
include "AffectiveDynamics.dfy"
include "Lexicon176.dfy"
include "PredictiveCircuit.dfy"

module AuditTests {
  import opened PredictiveEngine
  import opened CoreAffect
  import opened AffectiveMatrix
  import opened AffectiveTaxonomy
  import opened AffectiveDynamics
  import opened Lexicon176
  import opened PredictiveCircuit

  // [113/113] all176Entries_antagonist_inverts_hedonic_polarity
  lemma all176Entries_antagonist_inverts_hedonic_polarity()
    ensures forall i | 0 <= i < |All176Entries()| ::
      var e := All176Entries()[i];
      var ant := AntagonistPoint(e.point);
      ComputeHedonicPolarity(ant.x, ant.y) == HedonicPolarityInvert(ComputeHedonicPolarity(e.point.x, e.point.y))
  {
    forall i | 0 <= i < |All176Entries()|
      ensures var e := All176Entries()[i];
        var ant := AntagonistPoint(e.point);
        ComputeHedonicPolarity(ant.x, ant.y) == HedonicPolarityInvert(ComputeHedonicPolarity(e.point.x, e.point.y))
    {
      antagonistPoint_inverts_hedonic_polarity(All176Entries()[i].point);
    }
  }

  // Helper constructors for the 11 concrete evaluation blocks
  function SampleSurpriseEngine(): PredictiveEngineState {
    PredictiveEngineState(
      SalientDiscrepancyRaw(5, 2, 1),
      PerceptiveInterface(Pos),
      SubjectiveInterface(Neg, false),
      AttentionalInterface(1, 3, 0, 1, 1)
    )
  }

  function SampleColereEngine(): PredictiveEngineState {
    PredictiveEngineState(
      SalientDiscrepancyRaw(5, 2, 1),
      PerceptiveInterface(Pos),
      SubjectiveInterface(Neg, true),
      AttentionalInterface(5, 3, 0, 1, 1)
    )
  }

  function SampleNeutralSuspendedEngine(): PredictiveEngineState {
    PredictiveEngineState(
      SalientDiscrepancyRaw(5, 2, 1),
      PerceptiveInterface(Zero),
      SubjectiveInterface(Zero, true),
      AttentionalInterface(5, 3, 0, 1, 1)
    )
  }

  function SampleSubthresholdSuspendedEngine(): PredictiveEngineState {
    PredictiveEngineState(
      SalientDiscrepancyRaw(0, 2, 1),
      PerceptiveInterface(Pos),
      SubjectiveInterface(Neg, true),
      AttentionalInterface(5, 3, 0, 1, 1)
    )
  }

  function SampleVeilleStepStart(): PredictiveEngineState {
    PredictiveEngineState(
      SalientDiscrepancyRaw(5, 2, 1),
      PerceptiveInterface(Zero),
      SubjectiveInterface(Zero, false),
      AttentionalInterface(0, 2, 0, 1, 1)
    )
  }

  function SampleConsternationEngine(): PredictiveEngineState {
    PredictiveEngineState(
      SalientDiscrepancyRaw(6, 2, 1),
      PerceptiveInterface(Pos),
      SubjectiveInterface(Neg, true),
      AttentionalInterface(5, 3, 1, 1, 3)
    )
  }

  function InvertedPhenomenologicalMapping(): PhenomenologicalMapping {
    PhenomenologicalMapping(
      x => if x < 0 then EpistemicDischarge else if x > 0 then EpistemicCharge else EpistemicNeutral,
      y => if y < 0 then PragmaticDischarge else if y > 0 then PragmaticCharge else PragmaticNeutral,
      (x, y) => HedonicPolarityInvert(ComputeValence(x, y)),
      _ => OperatorSuspension
    )
  }

  method CheckBlock1() {
    var b1 := RunCartograffectPipeline(DefaultPredictiveEngineState());
    expect b1.matrix.core == CoreAffectPoint(0, 0, 0);
    expect b1.stratum == Z0_pointDeVeille;
    expect b1.group == OperateurCentral;
    print "B1:", b1.matrix.core, " ", b1.stratum, " ", b1.group, "\n";
  }

  method CheckBlock2() {
    var b2 := RunCartograffectPipeline(SampleSurpriseEngine());
    expect b2.matrix.core == CoreAffectPoint(0, 0, 1);
    expect b2.stratum == Z1_saillancePerceptive;
    expect b2.matrix.activation == AscendingRupture;
    print "B2:", b2.matrix.core, " ", b2.stratum, " ", b2.matrix.activation, "\n";
  }

  method CheckBlock3() {
    var b3 := RunCartograffectPipeline(SampleColereEngine());
    expect b3.matrix.core == CoreAffectPoint(-1, 1, 2);
    expect b3.matrix.antagonist == CoreAffectPoint(1, -1, 2);
    expect b3.group == GroupeColere && b3.subsector == DiagonalAnger;
    expect b3.antagonistGroup == GroupeCalme && b3.antagonistSubsector == DiagonalCalm;
    expect b3.matrix.energyRegime == ErgotropicCompensation && b3.matrix.valence == HedNegative;
    print "B3:", b3.matrix.core, " ", b3.matrix.antagonist, " ",
      b3.group, " ", b3.subsector, " ", b3.antagonistGroup, " ", b3.antagonistSubsector, " ",
      b3.matrix.energyRegime, " ", b3.matrix.valence, "\n";
  }

  method CheckBlock4() {
    var b4a := RunCartograffectPipeline(SampleNeutralSuspendedEngine());
    var b4b := RunCartograffectPipeline(SampleSubthresholdSuspendedEngine());
    var s0 := SampleVeilleStepStart();
    var s1 := EngineStep(s0);
    var s2 := EngineStep(s1);
    var s3 := EngineStep(s2);
    expect b4a.matrix.core == CoreAffectPoint(0, 0, 2);
    expect b4b.matrix.core == CoreAffectPoint(0, 0, 2);
    expect ProjectToCoreAffect(s0) == CoreAffectPoint(0, 0, 0);
    expect ProjectToCoreAffect(s1) == CoreAffectPoint(0, 0, 1);
    expect ProjectToCoreAffect(s2) == CoreAffectPoint(0, 0, 2);
    expect ProjectToCoreAffect(s3) == CoreAffectPoint(0, 2, 2);
    print "B4:", ProjectToCoreAffect(s0), "->", ProjectToCoreAffect(s1), "->",
      ProjectToCoreAffect(s2), "->", ProjectToCoreAffect(s3), "\n";
  }

  method CheckBlock5() {
    var p002 := CoreAffectPoint(0, 0, 2);
    var jump := DissipationPotential(p002) - DissipationPotential(DissipationStep(p002));
    var pcon := CoreAffectPoint(-1, 3, 3);
    expect DissipationStep(p002) == CoreAffectPoint(0, 0, 0) && jump == 4;
    expect RepeatDissipation(3, pcon) == CoreAffectPoint(0, 0, 0);
    print "B5:", DissipationStep(p002), " jump=", jump, " ",
      DissipationStep(pcon), "->", DissipationStep(DissipationStep(pcon)), "->", RepeatDissipation(3, pcon), "\n";
  }

  method CheckBlock6() {
    var b6 := RunCartograffectPipeline(SampleConsternationEngine());
    expect b6.matrix.core == CoreAffectPoint(-1, 3, 3);
    expect b6.geometry == Lateral && b6.group == GroupeJoie;
    expect b6.subsector == LateralDefensiveUrgency && b6.matrix.valence == HedNegative;
    expect b6.matrix.antagonist == CoreAffectPoint(3, -1, 3);
    print "B6:", b6.matrix.core, " ", b6.geometry, " ", b6.group, " ",
      b6.subsector, " ", b6.matrix.valence, " ", b6.matrix.antagonist, "\n";
  }

  method CheckBlock7() {
    var srcCol := CoreAffectPoint(-1, 1, 2);
    var wEx := CanonicalDepthWeight(srcCol, CoreAffectPoint(-2, 2, 3));
    var wCo := CanonicalDepthWeight(srcCol, CoreAffectPoint(-1, 3, 3));
    var wPa := CanonicalDepthWeight(srcCol, CoreAffectPoint(-3, 1, 3));
    var wOut := OutgoingWeight(srcCol);
    var wAnt := CanonicalDepthWeight(AntagonistPoint(srcCol), AntagonistPoint(CoreAffectPoint(-1, 3, 3)));
    expect wEx == 2 && wCo == 1 && wPa == 1 && wOut == 4 && wAnt == 1;
    print "B7:", wEx, ",", wCo, ",", wPa, " out=", wOut, " ant=", wAnt, "\n";
  }

  method CheckBlock8() {
    var cPt := CoreAffectPoint(-1, 3, 3);
    var ePt := CoreAffectPoint(-2, 4, 4);
    expect AttractorMembership(cPt, GroupeJoie) == 4 && AttractorMembership(cPt, GroupeColere) == 2 &&
      AttractorMembership(cPt, GroupePeur) == 1 && ClassifyTaxonomicGroup(cPt) == GroupeJoie;
    expect AttractorMembership(ePt, GroupeJoie) == 6 && AttractorMembership(ePt, GroupeColere) == 4 &&
      AttractorMembership(ePt, GroupePeur) == 2 && ClassifyTaxonomicGroup(ePt) == GroupeJoie;
    print "B8:C=(", AttractorMembership(cPt, GroupeJoie), ",", AttractorMembership(cPt, GroupeColere), ",",
      AttractorMembership(cPt, GroupePeur), ",", ClassifyTaxonomicGroup(cPt), ") E=(",
      AttractorMembership(ePt, GroupeJoie), ",", AttractorMembership(ePt, GroupeColere), ",",
      AttractorMembership(ePt, GroupePeur), ",", ClassifyTaxonomicGroup(ePt), ")\n";
  }

  method CheckBlock9() {
    var csCol := EvaluateCoreAffect(SampleColereEngine());
    var mCan := EvaluateMatrix(csCol, CanonicalMapping());
    var mInv := EvaluateMatrix(csCol, InvertedPhenomenologicalMapping());
    expect mCan.core == mInv.core && mCan.antagonist == mInv.antagonist;
    expect mCan.valence == HedNegative && mInv.valence == HedPositive;
    print "B9:", mCan.core, " ", mCan.antagonist, " ",
      mCan.valence, "->", mInv.valence, "\n";
  }

  method CheckBlock10() {
    var cPosI := CrossingIPos(EngineCoupling(Zero, Zero));
    var cPosII := CrossingIIPos(EngineCoupling(Zero, Zero));
    var pPerc := ProjectPerceptible(EngineCoupling(Neg, Pos), 3, 1, 3, true);
    var rSum := CircuitRowSum(DefaultCircuitKernelParams(), EngineCoupling(Neg, Zero));
    var cWt := CircuitWeight(DefaultCircuitKernelParams(), EngineCoupling(Neg, Zero), EngineCoupling(Neg, Pos));
    var op3Def := Op3CrossingIPerceptible(DefaultCircularCircuitState()).1;
    expect cPosI == (0, 2) && cPosII == (2, 0) && pPerc == CoreAffectPoint(-1, 3, 3);
    expect rSum == 4000000000000 && cWt == 101500000000 && op3Def == CoreAffectPoint(0, 0, 0);
    print "B10:", cPosI, " ", cPosII, " ", pPerc, " sum=", rSum, " w=", cWt, " op3=", op3Def, "\n";
  }

  method CheckBlock11() {
    var up := DefaultUnifiedDynamicsParams();
    var rAct := NextChargeAccumulator(up, 1000, 500, 500, EngineCoupling(Neg, Zero), EngineCoupling(Pos, Zero));
    var rPass := NextChargeAccumulator(up, 1000, 500, 500, EngineCoupling(Neg, Zero), EngineCoupling(Zero, Zero));
    var z2d := NextStratumR5(up, 2, 100);
    var z3d := NextStratumR5(up, 3, 100);
    var uPt := ProjectUnifiedState(up, EngineCoupling(Neg, Pos), 3, 10, 90, true);
    var sh := PrecisionShares(up, 10, 90, EngineCoupling(Neg, Neg));
    expect rAct == 700 && rPass == 1300 && z2d == 0 && z3d == 2;
    expect uPt == CoreAffectPoint(-1, 3, 3) && sh == (193, 807);
    print "B11:acc=(", rAct, ",", rPass, ") r5=(", z2d, ",", z3d, ") pt=", uPt, " sh=", sh, "\n";
  }

  method Main() {
    CheckBlock1();
    CheckBlock2();
    CheckBlock3();
    CheckBlock4();
    CheckBlock5();
    CheckBlock6();
    CheckBlock7();
    CheckBlock8();
    CheckBlock9();
    CheckBlock10();
    CheckBlock11();
  }

}
