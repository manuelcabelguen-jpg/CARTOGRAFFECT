--------------------- MODULE Model_OperantFactorization ---------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Modele de verification TLC : Factorisation operante sur Z = 2 et 176 points
*)
EXTENDS Integers, Lexicon176, OperantFactorization

ASSUME All7_OperantFactorization(All176Points)

VARIABLE opStepDone

Init == opStepDone = TRUE
Next == opStepDone' = opStepDone
Spec == Init /\ [][Next]_opStepDone

Inv_All7OperantTheorems == All7_OperantFactorization(All176Points)

=============================================================================
