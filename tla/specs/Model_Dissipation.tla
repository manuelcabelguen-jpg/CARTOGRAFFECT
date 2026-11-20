-------------------------- MODULE Model_Dissipation ---------------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Modele temporel TLC 1/5 : Convergence et court-circuit R5 de la dissipation
*)
EXTENDS Integers, CoreAffect, Lexicon176

VARIABLE pt

Init == pt \in All176Points
Next == pt' = DissipationStep(pt)
Spec == Init /\ [][Next]_pt /\ WF_pt(Next)

Inv_ValidCoreAffect == IsValidCoreAffect(pt)
Inv_StratumBounded == pt.z \in 0..7

Prop_NoSurpriseFromCrown == [][pt.z >= 2 => pt' # MkPoint(0, 0, 1)]_pt
Prop_StrictPotentialDescent == [][pt # MkPoint(0, 0, 0) => DissipationPotential(pt') < DissipationPotential(pt)]_pt
Prop_EventuallyVeille == <>(pt = MkPoint(0, 0, 0))

=============================================================================
