------------------------ MODULE OperantFactorization --------------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Module derive : OperantFactorization — Factorisation des contingences operantes (Z = 2)
*)
EXTENDS Integers, CoreAffect, AffectiveMatrix

ManhattanDistXY(p, q) == IntAbs(p.x - q.x) + IntAbs(p.y - q.y)

OperantEffects == {"Reinforcement", "Punishment"}
OperantOperators == {"Addition", "Removal"}

MkContingency(eff, op) == [effect |-> eff, op |-> op]
OperantContingencies == [effect : OperantEffects, op : OperantOperators]

SomeContingency(c) == [isSome |-> TRUE, val |-> c]
NoneContingency == [isSome |-> FALSE, val |-> MkContingency("Reinforcement", "Addition")]

PrimaryCrownPrototypes == {
  "joie", "tristesse", "peur", "courage",
  "desir", "degout", "colere", "calme"
}

PrimaryCrownPrototypeToPoint(proto) ==
  IF proto = "joie" THEN MkPoint(0, 2, 2)
  ELSE IF proto = "tristesse" THEN MkPoint(0, -2, 2)
  ELSE IF proto = "peur" THEN MkPoint(-2, 0, 2)
  ELSE IF proto = "courage" THEN MkPoint(2, 0, 2)
  ELSE IF proto = "desir" THEN MkPoint(1, 1, 2)
  ELSE IF proto = "degout" THEN MkPoint(-1, -1, 2)
  ELSE IF proto = "colere" THEN MkPoint(-1, 1, 2)
  ELSE MkPoint(1, -1, 2)

DiagToContingency(p) ==
  IF p.z # 2 THEN NoneContingency
  ELSE IF p.x = 1 /\ p.y = 1 THEN SomeContingency(MkContingency("Reinforcement", "Addition"))
  ELSE IF p.x = 1 /\ p.y = -1 THEN SomeContingency(MkContingency("Reinforcement", "Removal"))
  ELSE IF p.x = -1 /\ p.y = -1 THEN SomeContingency(MkContingency("Punishment", "Addition"))
  ELSE IF p.x = -1 /\ p.y = 1 THEN SomeContingency(MkContingency("Punishment", "Removal"))
  ELSE NoneContingency

PrototypeToContingency(proto) ==
  DiagToContingency(PrimaryCrownPrototypeToPoint(proto))

Z2DiagonalPoints == {
  PrimaryCrownPrototypeToPoint("desir"),
  PrimaryCrownPrototypeToPoint("calme"),
  PrimaryCrownPrototypeToPoint("degout"),
  PrimaryCrownPrototypeToPoint("colere")
}

Z2AxialPoints == {
  PrimaryCrownPrototypeToPoint("courage"),
  PrimaryCrownPrototypeToPoint("peur"),
  PrimaryCrownPrototypeToPoint("joie"),
  PrimaryCrownPrototypeToPoint("tristesse")
}

-----------------------------------------------------------------------------
(* 7 audited theorem predicates for OperantFactorization *)
-----------------------------------------------------------------------------

Thm_manhattanDistXY_origin(PointSet) ==
  \A p \in PointSet : ManhattanDistXY(p, MkPoint(0, 0, p.z)) = DisplacementSum(p)

Thm_operant_factorization_law ==
  \A p \in Z2DiagonalPoints :
    LET res == DiagToContingency(p) IN
    /\ res.isSome
    /\ LET c == res.val IN
       /\ ((c.effect = "Reinforcement") <=> (p.x = 1))
       /\ ((c.effect = "Punishment") <=> (p.x = -1))
       /\ ((c.op = "Addition") <=> (p.x * p.y = 1))
       /\ ((c.op = "Removal") <=> (p.x * p.y = -1))
       /\ ((c = MkContingency("Reinforcement", "Addition") \/
            c = MkContingency("Punishment", "Removal")) <=> (p.y = 1))
       /\ ((ComputeHedonicPolarity(p.x, p.y) = "positive") <=> (c.effect = "Reinforcement"))

Thm_energyRegime_matches_operant_operator ==
  \A p \in Z2DiagonalPoints :
    LET res == DiagToContingency(p) IN
    /\ res.isSome
    /\ LET c == res.val IN
       /\ ((c.op = "Addition") <=>
             (ComputeEnergyRegime(p.x, p.y) = "positiveSynergy" \/
              ComputeEnergyRegime(p.x, p.y) = "negativeSynergy"))
       /\ ((c.op = "Removal") <=>
             (ComputeEnergyRegime(p.x, p.y) = "ergotropicCompensation" \/
              ComputeEnergyRegime(p.x, p.y) = "trophotropicRelease"))

Thm_antagonist_flips_effect_preserves_operator ==
  \A p \in Z2DiagonalPoints :
    LET r1 == DiagToContingency(p)
        r2 == DiagToContingency(AntagonistPoint(p))
    IN /\ r1.isSome
       /\ r2.isSome
       /\ r1.val.effect # r2.val.effect
       /\ r1.val.op = r2.val.op

Thm_axial_poles_bridge_operant_pairs ==
  /\ ManhattanDistXY(PrimaryCrownPrototypeToPoint("courage"), PrimaryCrownPrototypeToPoint("desir")) = 2
  /\ ManhattanDistXY(PrimaryCrownPrototypeToPoint("courage"), PrimaryCrownPrototypeToPoint("calme")) = 2
  /\ ManhattanDistXY(PrimaryCrownPrototypeToPoint("courage"), PrimaryCrownPrototypeToPoint("colere")) = 4
  /\ ManhattanDistXY(PrimaryCrownPrototypeToPoint("courage"), PrimaryCrownPrototypeToPoint("degout")) = 4
  /\ ManhattanDistXY(PrimaryCrownPrototypeToPoint("peur"), PrimaryCrownPrototypeToPoint("colere")) = 2
  /\ ManhattanDistXY(PrimaryCrownPrototypeToPoint("peur"), PrimaryCrownPrototypeToPoint("degout")) = 2
  /\ ManhattanDistXY(PrimaryCrownPrototypeToPoint("peur"), PrimaryCrownPrototypeToPoint("desir")) = 4
  /\ ManhattanDistXY(PrimaryCrownPrototypeToPoint("peur"), PrimaryCrownPrototypeToPoint("calme")) = 4
  /\ ManhattanDistXY(PrimaryCrownPrototypeToPoint("joie"), PrimaryCrownPrototypeToPoint("desir")) = 2
  /\ ManhattanDistXY(PrimaryCrownPrototypeToPoint("joie"), PrimaryCrownPrototypeToPoint("colere")) = 2
  /\ ManhattanDistXY(PrimaryCrownPrototypeToPoint("joie"), PrimaryCrownPrototypeToPoint("calme")) = 4
  /\ ManhattanDistXY(PrimaryCrownPrototypeToPoint("joie"), PrimaryCrownPrototypeToPoint("degout")) = 4
  /\ ManhattanDistXY(PrimaryCrownPrototypeToPoint("tristesse"), PrimaryCrownPrototypeToPoint("calme")) = 2
  /\ ManhattanDistXY(PrimaryCrownPrototypeToPoint("tristesse"), PrimaryCrownPrototypeToPoint("degout")) = 2
  /\ ManhattanDistXY(PrimaryCrownPrototypeToPoint("tristesse"), PrimaryCrownPrototypeToPoint("desir")) = 4
  /\ ManhattanDistXY(PrimaryCrownPrototypeToPoint("tristesse"), PrimaryCrownPrototypeToPoint("colere")) = 4

Thm_axial_poles_pre_operant ==
  \A p \in Z2AxialPoints : DiagToContingency(p) = NoneContingency

Thm_operant_bijection_on_z2_diagonals ==
  /\ (\A c \in OperantContingencies :
        \E p \in Z2DiagonalPoints : DiagToContingency(p) = SomeContingency(c))
  /\ (\A p1, p2 \in Z2DiagonalPoints :
        (DiagToContingency(p1) = DiagToContingency(p2)) => (p1 = p2))

All7_OperantFactorization(PointSet) ==
  /\ Thm_manhattanDistXY_origin(PointSet)
  /\ Thm_operant_factorization_law
  /\ Thm_energyRegime_matches_operant_operator
  /\ Thm_antagonist_flips_effect_preserves_operator
  /\ Thm_axial_poles_bridge_operant_pairs
  /\ Thm_axial_poles_pre_operant
  /\ Thm_operant_bijection_on_z2_diagonals

=============================================================================
