----------------------------- MODULE Model_Unified ------------------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Modele temporel TLC 5/5 : Loi unifiee (R_t, Z_t, pi_A, pi_C) sous dynamique R5 bornee
*)
EXTENDS Integers, PredictiveEngine, CoreAffect, PredictiveCircuit

VARIABLES c, r, z
vars == <<c, r, z>>

SmallUnifiedModelParams ==
  [halfScale |-> 5, lambdaNum |-> 8, etaScaled |-> 6,
   betaAtt |-> 2, alphaCharge |-> 5, sigmoidK |-> 1, zMax |-> 7]

ModelThetaUp(str) == 6 + 2 * str
ModelThetaDown(str) == 3 + 2 * str

ModelNextStratumR5(str, rNext) ==
  IF rNext > ModelThetaUp(str) THEN MinInt(SmallUnifiedModelParams.zMax, str + 1)
  ELSE IF rNext < ModelThetaDown(str) THEN
    IF str <= 2 THEN 0 ELSE MinInt(SmallUnifiedModelParams.zMax, str - 1)
  ELSE MinInt(SmallUnifiedModelParams.zMax, str)

Init ==
  /\ c \in Couplings
  /\ r \in {0, 10, 25}
  /\ z \in {0, 2, 3}

Next ==
  \E dst \in Couplings :
    LET sh == PrecisionShares(SmallUnifiedModelParams, 1, 9, c)
        rNext == NextChargeAccumulator(SmallUnifiedModelParams, r, sh[1], sh[2], c, dst)
    IN /\ c' = dst
       /\ r' = rNext
       /\ z' = ModelNextStratumR5(z, rNext)

Spec == Init /\ [][Next]_vars

Inv_ChargeBounded == r \in 0..ChargeAccumulatorBound(SmallUnifiedModelParams)
Inv_StratumBounded == z \in 0..SmallUnifiedModelParams.zMax
Inv_ProjectedValid ==
  IsValidCoreAffect(ProjectUnifiedState(SmallUnifiedModelParams, c, z, 1, 9, TRUE))

Prop_FromGe2NeverSurprise == [][z >= 2 => z' # 1]_vars
Prop_Z2ShortCircuit == [][(z = 2 /\ r' < ModelThetaDown(2)) => z' = 0]_vars

=============================================================================
