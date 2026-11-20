----------------------------- MODULE Model_Circuit ------------------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Modele temporel TLC 4/5 : Graphe markovien a 9 etats & descente de Lyapunov en regime libre
*)
EXTENDS Integers, PredictiveEngine, PredictiveCircuit

VARIABLES mode, c
vars == <<mode, c>>

FreeKernel == MkKernelParams(4, 2, 2, 0, 0, 2, 2, 0, 2, 2, 0)
ActiveKernel == DefaultKernelParams20

CurrentKernel == IF mode = "active" THEN ActiveKernel ELSE FreeKernel

Init ==
  \/ (mode = "active" /\ c \in Couplings)
  \/ (mode = "free" /\ c \in Couplings)

Next ==
  /\ UNCHANGED mode
  /\ c' \in {dst \in Couplings : CircuitWeight(CurrentKernel, c, dst) > 0}

FreeStrictDescent ==
  /\ mode = "free"
  /\ UNCHANGED mode
  /\ c' \in {dst \in Couplings : CircuitWeight(FreeKernel, c, dst) > 0}
  /\ LyapunovPotential(c') < LyapunovPotential(c)

Spec == Init /\ [][Next]_vars /\ WF_vars(Next) /\ WF_vars(FreeStrictDescent)

Inv_ExactRowSum == CircuitRowSum(CurrentKernel, c) = 4 * Pow6(CurrentKernel.scale)
Inv_CouplingValid == c \in Couplings

Prop_FreeLyapunovMonotone ==
  [][mode = "free" => LyapunovPotential(c') <= LyapunovPotential(c)]_vars

Prop_FreeConvergesToVeille ==
  mode = "free" ~> (c = MkCoupling("zero", "zero"))

=============================================================================
