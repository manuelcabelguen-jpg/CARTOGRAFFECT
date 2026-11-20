----------------------------- MODULE Model_Engine -------------------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Modele temporel TLC 2/5 : Progression de phase du moteur predictif (Veille -> Appariement -> Engagement)
*)
EXTENDS Integers, PredictiveEngine, CoreAffect

VARIABLE st

InitialEngines == {
  DefaultEngineState,
  MkEngineState(MkDiscrepancy(5, 2, 1), MkPerceptive("zero"), MkSubjective("zero", FALSE), MkAttentional(0, 2, 0, 1, 1)),
  MkEngineState(MkDiscrepancy(5, 2, 1), MkPerceptive("pos"),  MkSubjective("neg", FALSE),  MkAttentional(1, 3, 0, 1, 1)),
  MkEngineState(MkDiscrepancy(1, 2, 1), MkPerceptive("neg"),  MkSubjective("pos", FALSE),  MkAttentional(0, 2, 0, 1, 1)),
  MkEngineState(MkDiscrepancy(0, 2, 1), MkPerceptive("neg"),  MkSubjective("pos", TRUE),   MkAttentional(2, 2, 1, 1, 3))
}

Init == st \in InitialEngines
Next == st' = EngineStep(st)
Spec == Init /\ [][Next]_st /\ WF_st(Next)

Inv_ValidEngine == ValidEngineState(st)
Inv_ValidProjection == IsValidCoreAffect(ProjectToCoreAffect(st))
Inv_RemanencePreserves ==
  (~IsSensorilySalient(st.discrepancy) /\ IsInRemanenceWindow(st.discrepancy)) => EngineStep(st) = st

Prop_Stabilizes == <>[](EngineStep(st) = st)

=============================================================================
