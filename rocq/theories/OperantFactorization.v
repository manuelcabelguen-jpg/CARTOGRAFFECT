(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*)

From Stdlib Require Import Bool Arith PeanoNat ZArith Lia List.
Import ListNotations.
Require Import CartograffectRocq.CoreAffect.
Require Import CartograffectRocq.AffectiveMatrix.

Open Scope bool_scope.
Open Scope nat_scope.

(** * Module OperantFactorization — Validation Rocq 9.1.0 *)
(** Factorisation structurale des contingences opérantes sur la couronne Z = 2 *)

(** ** 1. Métrique L1 intra-plan *)

Definition manhattanDistXY (p q : CoreAffectPoint) : nat :=
  Z.abs_nat (pt_x p - pt_x q)%Z + Z.abs_nat (pt_y p - pt_y q)%Z.

Theorem manhattanDistXY_origin :
  forall p : CoreAffectPoint,
    manhattanDistXY p (mkPoint 0%Z 0%Z (pt_z p)) = CoreAffectPoint_displacementSum p.
Proof.
  intros [x y z].
  unfold manhattanDistXY, CoreAffectPoint_displacementSum. simpl.
  rewrite !Z.sub_0_r. reflexivity.
Qed.

(** ** 2. Contingences opérantes {R+, R-, P+, P-} et projection sur Z = 2 *)

Inductive OperantEffect : Type :=
  | OE_Reinforcement : OperantEffect
  | OE_Punishment    : OperantEffect.

Inductive OperantOperator : Type :=
  | OO_Addition : OperantOperator
  | OO_Removal  : OperantOperator.

Record OperantContingency : Type := mkOperantContingency {
  oc_effect : OperantEffect;
  oc_op     : OperantOperator
}.

Definition diagToContingency (p : CoreAffectPoint) : option OperantContingency :=
  if Nat.eqb (pt_z p) 2 then
    if (pt_x p =? 1)%Z && (pt_y p =? 1)%Z then
      Some (mkOperantContingency OE_Reinforcement OO_Addition)
    else if (pt_x p =? 1)%Z && (pt_y p =? (-1))%Z then
      Some (mkOperantContingency OE_Reinforcement OO_Removal)
    else if (pt_x p =? (-1))%Z && (pt_y p =? (-1))%Z then
      Some (mkOperantContingency OE_Punishment OO_Addition)
    else if (pt_x p =? (-1))%Z && (pt_y p =? 1)%Z then
      Some (mkOperantContingency OE_Punishment OO_Removal)
    else
      None
  else
    None.

Definition prototypeToContingency (proto : PrimaryCrownPrototype) : option OperantContingency :=
  diagToContingency (PrimaryCrownPrototype_toPoint proto).

Definition z2DiagonalPoints : list CoreAffectPoint := [
  PrimaryCrownPrototype_toPoint Proto_desir;
  PrimaryCrownPrototype_toPoint Proto_calme;
  PrimaryCrownPrototype_toPoint Proto_degout;
  PrimaryCrownPrototype_toPoint Proto_colere
].

Definition z2AxialPoints : list CoreAffectPoint := [
  PrimaryCrownPrototype_toPoint Proto_courage;
  PrimaryCrownPrototype_toPoint Proto_peur;
  PrimaryCrownPrototype_toPoint Proto_joie;
  PrimaryCrownPrototype_toPoint Proto_tristesse
].

(** ** 3. Les 7 théorèmes de factorisation opérante *)

Theorem operant_factorization_law :
  forall p : CoreAffectPoint,
    In p z2DiagonalPoints ->
    match diagToContingency p with
    | Some c =>
        (oc_effect c = OE_Reinforcement <-> pt_x p = 1%Z) /\
        (oc_effect c = OE_Punishment <-> pt_x p = (-1)%Z) /\
        (oc_op c = OO_Addition <-> (pt_x p * pt_y p)%Z = 1%Z) /\
        (oc_op c = OO_Removal <-> (pt_x p * pt_y p)%Z = (-1)%Z) /\
        ((c = mkOperantContingency OE_Reinforcement OO_Addition \/
          c = mkOperantContingency OE_Punishment OO_Removal) <-> pt_y p = 1%Z) /\
        (computeHedonicPolarity (pt_x p) (pt_y p) = Hed_positive <->
          oc_effect c = OE_Reinforcement)
    | None => False
    end.
Proof.
  intros p Hp.
  destruct Hp as [<- | [<- | [<- | [<- | []]]]];
    simpl; repeat split; intro H;
    try reflexivity; try discriminate; try lia;
    try (left; reflexivity); try (right; reflexivity);
    try (destruct H as [H | H]; discriminate H).
Qed.

Theorem energyRegime_matches_operant_operator :
  forall p : CoreAffectPoint,
    In p z2DiagonalPoints ->
    match diagToContingency p with
    | Some c =>
        (oc_op c = OO_Addition <->
          computeEnergyRegime (pt_x p) (pt_y p) = ER_positiveSynergy \/
          computeEnergyRegime (pt_x p) (pt_y p) = ER_negativeSynergy) /\
        (oc_op c = OO_Removal <->
          computeEnergyRegime (pt_x p) (pt_y p) = ER_ergotropicCompensation \/
          computeEnergyRegime (pt_x p) (pt_y p) = ER_trophotropicRelease)
    | None => False
    end.
Proof.
  intros p Hp.
  destruct Hp as [<- | [<- | [<- | [<- | []]]]];
    simpl; repeat split; intro H;
    try reflexivity; try discriminate;
    try (left; reflexivity); try (right; reflexivity);
    try (destruct H as [H | H]; discriminate H).
Qed.

Theorem antagonist_flips_effect_preserves_operator :
  forall p : CoreAffectPoint,
    In p z2DiagonalPoints ->
    match diagToContingency p, diagToContingency (antagonistPoint p) with
    | Some c1, Some c2 => oc_effect c1 <> oc_effect c2 /\ oc_op c1 = oc_op c2
    | _, _ => False
    end.
Proof.
  intros p Hp.
  destruct Hp as [<- | [<- | [<- | [<- | []]]]];
    simpl; split; try discriminate; reflexivity.
Qed.

Theorem axial_poles_bridge_operant_pairs :
  manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_courage) (PrimaryCrownPrototype_toPoint Proto_desir) = 2 /\
  manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_courage) (PrimaryCrownPrototype_toPoint Proto_calme) = 2 /\
  manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_courage) (PrimaryCrownPrototype_toPoint Proto_colere) = 4 /\
  manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_courage) (PrimaryCrownPrototype_toPoint Proto_degout) = 4 /\
  manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_peur) (PrimaryCrownPrototype_toPoint Proto_colere) = 2 /\
  manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_peur) (PrimaryCrownPrototype_toPoint Proto_degout) = 2 /\
  manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_peur) (PrimaryCrownPrototype_toPoint Proto_desir) = 4 /\
  manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_peur) (PrimaryCrownPrototype_toPoint Proto_calme) = 4 /\
  manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_joie) (PrimaryCrownPrototype_toPoint Proto_desir) = 2 /\
  manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_joie) (PrimaryCrownPrototype_toPoint Proto_colere) = 2 /\
  manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_joie) (PrimaryCrownPrototype_toPoint Proto_calme) = 4 /\
  manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_joie) (PrimaryCrownPrototype_toPoint Proto_degout) = 4 /\
  manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_tristesse) (PrimaryCrownPrototype_toPoint Proto_calme) = 2 /\
  manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_tristesse) (PrimaryCrownPrototype_toPoint Proto_degout) = 2 /\
  manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_tristesse) (PrimaryCrownPrototype_toPoint Proto_desir) = 4 /\
  manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_tristesse) (PrimaryCrownPrototype_toPoint Proto_colere) = 4.
Proof.
  repeat split; reflexivity.
Qed.

Theorem axial_poles_pre_operant :
  forall p : CoreAffectPoint,
    In p z2AxialPoints -> diagToContingency p = None.
Proof.
  intros p Hp.
  destruct Hp as [<- | [<- | [<- | [<- | []]]]]; reflexivity.
Qed.

Theorem operant_bijection_on_z2_diagonals :
  (forall c : OperantContingency,
    exists p : CoreAffectPoint, In p z2DiagonalPoints /\ diagToContingency p = Some c) /\
  (forall p1 p2 : CoreAffectPoint,
    In p1 z2DiagonalPoints -> In p2 z2DiagonalPoints ->
    diagToContingency p1 = diagToContingency p2 -> p1 = p2).
Proof.
  split.
  - intros [[|] [|]].
    + exists (PrimaryCrownPrototype_toPoint Proto_desir). simpl; split; [left; reflexivity | reflexivity].
    + exists (PrimaryCrownPrototype_toPoint Proto_calme). simpl; split; [right; left; reflexivity | reflexivity].
    + exists (PrimaryCrownPrototype_toPoint Proto_degout). simpl; split; [right; right; left; reflexivity | reflexivity].
    + exists (PrimaryCrownPrototype_toPoint Proto_colere). simpl; split; [right; right; right; left; reflexivity | reflexivity].
  - intros p1 p2 Hp1 Hp2 Heq.
    destruct Hp1 as [<- | [<- | [<- | [<- | []]]]];
    destruct Hp2 as [<- | [<- | [<- | [<- | []]]]];
      try reflexivity; discriminate Heq.
Qed.

(** ** 4. Audit axiomatique (Print Assumptions — 7/7 constructifs) *)
Print Assumptions manhattanDistXY_origin.
Print Assumptions operant_factorization_law.
Print Assumptions energyRegime_matches_operant_operator.
Print Assumptions antagonist_flips_effect_preserves_operator.
Print Assumptions axial_poles_bridge_operant_pairs.
Print Assumptions axial_poles_pre_operant.
Print Assumptions operant_bijection_on_z2_diagonals.
