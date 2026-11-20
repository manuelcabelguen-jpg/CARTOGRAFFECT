(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*)

From Stdlib Require Import Bool Arith PeanoNat ZArith Lia List.
Import ListNotations.
Require Import CartograffectRocq.PredictiveEngine.
Require Import CartograffectRocq.CoreAffect.
Require Import CartograffectRocq.AffectiveMatrix.
Require Import CartograffectRocq.AffectiveTaxonomy.

Open Scope bool_scope.
Open Scope nat_scope.

(** * Module AffectiveDynamics — Validation Rocq 9.1.0 *)

(** ** 1. Prédicat booléen de validité et lemmes de symétrie antagoniste *)

Definition isValidCoreAffectB (p : CoreAffectPoint) : bool :=
  ((pt_x p =? 0)%Z && (pt_y p =? 0)%Z) ||
  (Nat.leb 2 (pt_z p) && Nat.eqb (CoreAffectPoint_displacementSum p) (crownRadius (pt_z p))).

Theorem isValidCoreAffectB_iff :
  forall p : CoreAffectPoint, isValidCoreAffectB p = true <-> isValidCoreAffect p.
Proof.
  intros [x y z].
  unfold isValidCoreAffectB, isValidCoreAffect,
    CoreAffectPoint_isCentral, CoreAffectPoint_isOnCrown; cbn [pt_x pt_y pt_z].
  rewrite orb_true_iff, !andb_true_iff, !Z.eqb_eq, Nat.leb_le, Nat.eqb_eq.
  split; intros [[Hx Hy] | [Hz Hsum]]; [left; auto | right; split; [lia | exact Hsum] | left; auto | right; split; [lia | exact Hsum]].
Qed.

Theorem antagonist_z :
  forall p : CoreAffectPoint, pt_z (antagonistPoint p) = pt_z p.
Proof.
  apply antagonistPoint_preserves_z.
Qed.

Theorem antagonist_displacementSum :
  forall p : CoreAffectPoint,
    CoreAffectPoint_displacementSum (antagonistPoint p) = CoreAffectPoint_displacementSum p.
Proof.
  apply antagonistPoint_preserves_displacementSum.
Qed.

Theorem antagonist_validB :
  forall p : CoreAffectPoint, isValidCoreAffectB (antagonistPoint p) = isValidCoreAffectB p.
Proof.
  intro p.
  destruct (isValidCoreAffectB p) eqn:Hp.
  - apply (proj2 (isValidCoreAffectB_iff _)).
    apply antagonistPoint_preserves_validity.
    apply (proj1 (isValidCoreAffectB_iff _)). exact Hp.
  - destruct (isValidCoreAffectB (antagonistPoint p)) eqn:Ha; [| reflexivity].
    exfalso.
    assert (Hv : isValidCoreAffect p).
    { rewrite <- (antagonistPoint_involutive p).
      apply antagonistPoint_preserves_validity.
      apply (proj1 (isValidCoreAffectB_iff _)). exact Ha. }
    apply (proj2 (isValidCoreAffectB_iff p)) in Hv.
    rewrite Hv in Hp. discriminate.
Qed.

Theorem antagonist_zero_x_iff :
  forall p : CoreAffectPoint, pt_x (antagonistPoint p) = 0%Z <-> pt_x p = 0%Z.
Proof.
  intros [x y z]. unfold antagonistPoint; simpl.
  destruct (Z.eqb_spec x 0); destruct (Z.eqb_spec y 0); simpl; try lia.
  - destruct (Nat.eqb_spec (Z.abs_nat x) (Z.abs_nat y)); simpl; [lia |].
    destruct (((0 <? x)%Z && (y <? 0)%Z) || ((x <? 0)%Z && (0 <? y)%Z)); simpl; lia.
Qed.

Theorem antagonist_zero_y_iff :
  forall p : CoreAffectPoint, pt_y (antagonistPoint p) = 0%Z <-> pt_y p = 0%Z.
Proof.
  intros [x y z]. unfold antagonistPoint; simpl.
  destruct (Z.eqb_spec x 0); destruct (Z.eqb_spec y 0); simpl; try lia.
  - destruct (Nat.eqb_spec (Z.abs_nat x) (Z.abs_nat y)); simpl; [lia |].
    destruct (((0 <? x)%Z && (y <? 0)%Z) || ((x <? 0)%Z && (0 <? y)%Z)); simpl; lia.
Qed.

Lemma antagonist_pos_x_iff :
  forall p : CoreAffectPoint, (pt_x (antagonistPoint p) > 0)%Z <-> (pt_x p < 0)%Z.
Proof.
  intros [x y z]. unfold antagonistPoint; simpl.
  destruct (Z.eqb_spec x 0); destruct (Z.eqb_spec y 0); simpl; try lia.
  destruct (Nat.eqb_spec (Z.abs_nat x) (Z.abs_nat y)); simpl; [lia |].
  destruct (Z.ltb_spec0 0 x); destruct (Z.ltb_spec0 y 0);
  destruct (Z.ltb_spec0 x 0); destruct (Z.ltb_spec0 0 y); simpl; lia.
Qed.

Lemma antagonist_neg_x_iff :
  forall p : CoreAffectPoint, (pt_x (antagonistPoint p) < 0)%Z <-> (pt_x p > 0)%Z.
Proof.
  intros [x y z]. unfold antagonistPoint; simpl.
  destruct (Z.eqb_spec x 0); destruct (Z.eqb_spec y 0); simpl; try lia.
  destruct (Nat.eqb_spec (Z.abs_nat x) (Z.abs_nat y)); simpl; [lia |].
  destruct (Z.ltb_spec0 0 x); destruct (Z.ltb_spec0 y 0);
  destruct (Z.ltb_spec0 x 0); destruct (Z.ltb_spec0 0 y); simpl; lia.
Qed.

Lemma antagonist_pos_y_iff :
  forall p : CoreAffectPoint, (pt_y (antagonistPoint p) > 0)%Z <-> (pt_y p < 0)%Z.
Proof.
  intros [x y z]. unfold antagonistPoint; simpl.
  destruct (Z.eqb_spec x 0); destruct (Z.eqb_spec y 0); simpl; try lia.
  destruct (Nat.eqb_spec (Z.abs_nat x) (Z.abs_nat y)); simpl; [lia |].
  destruct (Z.ltb_spec0 0 x); destruct (Z.ltb_spec0 y 0);
  destruct (Z.ltb_spec0 x 0); destruct (Z.ltb_spec0 0 y); simpl; lia.
Qed.

Lemma antagonist_neg_y_iff :
  forall p : CoreAffectPoint, (pt_y (antagonistPoint p) < 0)%Z <-> (pt_y p > 0)%Z.
Proof.
  intros [x y z]. unfold antagonistPoint; simpl.
  destruct (Z.eqb_spec x 0); destruct (Z.eqb_spec y 0); simpl; try lia.
  destruct (Nat.eqb_spec (Z.abs_nat x) (Z.abs_nat y)); simpl; [lia |].
  destruct (Z.ltb_spec0 0 x); destruct (Z.ltb_spec0 y 0);
  destruct (Z.ltb_spec0 x 0); destruct (Z.ltb_spec0 0 y); simpl; lia.
Qed.

Lemma Z_mul_nonneg_iff :
  forall a b : Z, (a * b >= 0)%Z <-> ~ (((a > 0)%Z /\ (b < 0)%Z) \/ ((a < 0)%Z /\ (b > 0)%Z)).
Proof.
  intros a b. split.
  - intros H [[Ha Hb] | [Ha Hb]]; nia.
  - intro H.
    destruct (Z.lt_trichotomy a 0) as [Ha | [Ha | Ha]];
    destruct (Z.lt_trichotomy b 0) as [Hb | [Hb | Hb]];
      try nia; exfalso; apply H; ((left; split; lia) || (right; split; lia)).
Qed.

Theorem antagonist_mul_nonneg_x_iff :
  forall p q : CoreAffectPoint,
    (pt_x (antagonistPoint p) * pt_x (antagonistPoint q) >= 0)%Z <->
    (pt_x p * pt_x q >= 0)%Z.
Proof.
  intros p q.
  rewrite !Z_mul_nonneg_iff.
  rewrite antagonist_pos_x_iff, antagonist_neg_x_iff,
    antagonist_pos_x_iff, antagonist_neg_x_iff.
  tauto.
Qed.

Theorem antagonist_mul_nonneg_y_iff :
  forall p q : CoreAffectPoint,
    (pt_y (antagonistPoint p) * pt_y (antagonistPoint q) >= 0)%Z <->
    (pt_y p * pt_y q >= 0)%Z.
Proof.
  intros p q.
  rewrite !Z_mul_nonneg_iff.
  rewrite antagonist_pos_y_iff, antagonist_neg_y_iff,
    antagonist_pos_y_iff, antagonist_neg_y_iff.
  tauto.
Qed.

Lemma Z_abs_nat_opp : forall z : Z, Z.abs_nat (- z) = Z.abs_nat z.
Proof. intro z; lia. Qed.

Theorem antagonist_diag_iff :
  forall p : CoreAffectPoint,
    Nat.eqb (Z.abs_nat (pt_x (antagonistPoint p))) (Z.abs_nat (pt_y (antagonistPoint p))) =
    Nat.eqb (Z.abs_nat (pt_x p)) (Z.abs_nat (pt_y p)).
Proof.
  intros [x y z]. unfold antagonistPoint; simpl.
  destruct ((x =? 0)%Z || (y =? 0)%Z || (Z.abs_nat x =? Z.abs_nat y)).
  - simpl. rewrite !Z_abs_nat_opp. reflexivity.
  - destruct (((0 <? x)%Z && (y <? 0)%Z) || ((x <? 0)%Z && (0 <? y)%Z)); simpl.
    + apply Nat.eqb_sym.
    + rewrite !Z_abs_nat_opp. apply Nat.eqb_sym.
Qed.

Lemma antagonist_nonaxial_natAbs :
  forall r : CoreAffectPoint,
    pt_x r <> 0%Z -> pt_y r <> 0%Z ->
    Z.abs_nat (pt_x (antagonistPoint r)) = Z.abs_nat (pt_y r) /\
    Z.abs_nat (pt_y (antagonistPoint r)) = Z.abs_nat (pt_x r).
Proof.
  intros [x y z] Hx Hy; simpl in *.
  unfold antagonistPoint; simpl.
  destruct (Z.eqb_spec x 0); [lia |].
  destruct (Z.eqb_spec y 0); [lia |].
  destruct (Nat.eqb_spec (Z.abs_nat x) (Z.abs_nat y)); simpl.
  - split; lia.
  - destruct (((0 <? x)%Z && (y <? 0)%Z) || ((x <? 0)%Z && (0 <? y)%Z)); simpl; split; lia.
Qed.

(** ** 2. Structure abstraite du noyau de transition inter-strates (DepthTransitionKernel) *)

Record DepthTransitionKernel : Type := mkDepthTransitionKernel {
  dtk_weight                 : CoreAffectPoint -> CoreAffectPoint -> nat;
  dtk_support_valid          : forall p q, dtk_weight p q <> 0 -> isValidCoreAffect q;
  dtk_support_adjacent       : forall p q, dtk_weight p q <> 0 -> pt_z q = pt_z p + 1;
  dtk_quadrant_preserved     : forall p q, dtk_weight p q <> 0 ->
                                 (pt_x p * pt_x q >= 0)%Z /\ (pt_y p * pt_y q >= 0)%Z;
  dtk_antagonist_equivariant : forall p q,
                                 dtk_weight (antagonistPoint p) (antagonistPoint q) = dtk_weight p q
}.

(** ** 3. Noyau canonique d'approfondissement (canonicalDepthKernel) *)

Definition canonicalDepthWeight (p q : CoreAffectPoint) : nat :=
  if isValidCoreAffectB p && isValidCoreAffectB q &&
     Nat.eqb (pt_z q) (pt_z p + 1) &&
     ((0 <=? pt_x p * pt_x q)%Z && (0 <=? pt_y p * pt_y q)%Z) then
    if (pt_x q =? 0)%Z && (pt_y q =? 0)%Z then
      if (pt_x p =? 0)%Z && (pt_y p =? 0)%Z then 1 else 0
    else if (pt_x p =? 0)%Z && (pt_y p =? 0)%Z then
      if Nat.eqb (pt_z p) 1 then 1 else 0
    else if (pt_x p =? 0)%Z || (pt_y p =? 0)%Z then
      if ((pt_x p =? 0)%Z || negb (pt_x q =? 0)%Z) &&
         ((pt_y p =? 0)%Z || negb (pt_y q =? 0)%Z) then
        if (pt_x q =? 0)%Z || (pt_y q =? 0)%Z then 1
        else if Nat.eqb (Z.abs_nat (pt_x q)) (Z.abs_nat (pt_y q)) then 2
        else 0
      else 0
    else
      if negb (pt_x q =? 0)%Z && negb (pt_y q =? 0)%Z &&
         Nat.leb (Z.abs_nat (pt_x p)) (Z.abs_nat (pt_x q)) &&
         Nat.leb (Z.abs_nat (pt_y p)) (Z.abs_nat (pt_y q)) then
        if Nat.eqb (Z.abs_nat (pt_x p)) (Z.abs_nat (pt_y p)) &&
           Nat.eqb (Z.abs_nat (pt_x q)) (Z.abs_nat (pt_y q)) then 2 else 1
      else 0
  else 0.

Lemma eqb_zero_eq_of_iff :
  forall a b : Z, (a = 0%Z <-> b = 0%Z) -> (a =? 0)%Z = (b =? 0)%Z.
Proof.
  intros a b H.
  destruct (Z.eqb_spec a 0); destruct (Z.eqb_spec b 0); try reflexivity; exfalso;
    [apply n; apply H; assumption | apply n; apply H; assumption].
Qed.

Theorem canonicalDepthWeight_antagonist :
  forall p q : CoreAffectPoint,
    canonicalDepthWeight (antagonistPoint p) (antagonistPoint q) = canonicalDepthWeight p q.
Proof.
  intros p q.
  unfold canonicalDepthWeight.
  rewrite antagonist_validB, antagonist_validB, !antagonist_z.
  assert (Hmx : (0 <=? pt_x (antagonistPoint p) * pt_x (antagonistPoint q))%Z =
                (0 <=? pt_x p * pt_x q)%Z).
  { apply eq_true_iff_eq. rewrite !Z.leb_le.
    pose proof (antagonist_mul_nonneg_x_iff p q). lia. }
  assert (Hmy : (0 <=? pt_y (antagonistPoint p) * pt_y (antagonistPoint q))%Z =
                (0 <=? pt_y p * pt_y q)%Z).
  { apply eq_true_iff_eq. rewrite !Z.leb_le.
    pose proof (antagonist_mul_nonneg_y_iff p q). lia. }
  assert (Hpx0 : (pt_x (antagonistPoint p) =? 0)%Z = (pt_x p =? 0)%Z)
    by (apply eqb_zero_eq_of_iff, antagonist_zero_x_iff).
  assert (Hpy0 : (pt_y (antagonistPoint p) =? 0)%Z = (pt_y p =? 0)%Z)
    by (apply eqb_zero_eq_of_iff, antagonist_zero_y_iff).
  assert (Hqx0 : (pt_x (antagonistPoint q) =? 0)%Z = (pt_x q =? 0)%Z)
    by (apply eqb_zero_eq_of_iff, antagonist_zero_x_iff).
  assert (Hqy0 : (pt_y (antagonistPoint q) =? 0)%Z = (pt_y q =? 0)%Z)
    by (apply eqb_zero_eq_of_iff, antagonist_zero_y_iff).
  rewrite Hmx, Hmy.
  destruct (isValidCoreAffectB p && isValidCoreAffectB q &&
            Nat.eqb (pt_z q) (pt_z p + 1) &&
            ((0 <=? pt_x p * pt_x q)%Z && (0 <=? pt_y p * pt_y q)%Z)); [| reflexivity].
  rewrite Hpx0, Hpy0, Hqx0, Hqy0.
  rewrite !antagonist_diag_iff.
  destruct ((pt_x q =? 0)%Z && (pt_y q =? 0)%Z); [reflexivity |].
  destruct ((pt_x p =? 0)%Z && (pt_y p =? 0)%Z); [reflexivity |].
  destruct ((pt_x p =? 0)%Z || (pt_y p =? 0)%Z) eqn:Hpa; [reflexivity |].
  rewrite orb_false_iff, !Z.eqb_neq in Hpa.
  destruct Hpa as [Hpx_nz Hpy_nz].
  destruct (antagonist_nonaxial_natAbs p Hpx_nz Hpy_nz) as [Hpx_abs Hpy_abs].
  destruct (Z.eqb_spec (pt_x q) 0) as [Hqx0_eq | Hqx_nz];
  destruct (Z.eqb_spec (pt_y q) 0) as [Hqy0_eq | Hqy_nz]; simpl;
    try reflexivity.
  destruct (antagonist_nonaxial_natAbs q Hqx_nz Hqy_nz) as [Hqx_abs Hqy_abs].
  rewrite Hqx_abs, Hqy_abs, Hpx_abs, Hpy_abs.
  rewrite andb_comm with (b1 := Nat.leb (Z.abs_nat (pt_y p)) (Z.abs_nat (pt_y q))).
  reflexivity.
Qed.

Definition canonicalDepthKernel : DepthTransitionKernel.
Proof.
  refine {|
    dtk_weight := canonicalDepthWeight;
    dtk_antagonist_equivariant := canonicalDepthWeight_antagonist
  |}.
  - intros p q Hw. unfold canonicalDepthWeight in Hw.
    destruct (isValidCoreAffectB p && isValidCoreAffectB q &&
              Nat.eqb (pt_z q) (pt_z p + 1) &&
              ((0 <=? pt_x p * pt_x q)%Z && (0 <=? pt_y p * pt_y q)%Z)) eqn:Hg;
      [| congruence].
    rewrite !andb_true_iff in Hg. destruct Hg as [[[_ Hvq] _] _].
    apply (proj1 (isValidCoreAffectB_iff q)). exact Hvq.
  - intros p q Hw. unfold canonicalDepthWeight in Hw.
    destruct (isValidCoreAffectB p && isValidCoreAffectB q &&
              Nat.eqb (pt_z q) (pt_z p + 1) &&
              ((0 <=? pt_x p * pt_x q)%Z && (0 <=? pt_y p * pt_y q)%Z)) eqn:Hg;
      [| congruence].
    rewrite !andb_true_iff, Nat.eqb_eq in Hg. destruct Hg as [[_ Hz] _]. exact Hz.
  - intros p q Hw. unfold canonicalDepthWeight in Hw.
    destruct (isValidCoreAffectB p && isValidCoreAffectB q &&
              Nat.eqb (pt_z q) (pt_z p + 1) &&
              ((0 <=? pt_x p * pt_x q)%Z && (0 <=? pt_y p * pt_y q)%Z)) eqn:Hg;
      [| congruence].
    rewrite !andb_true_iff, !Z.leb_le in Hg. destruct Hg as [_ [Hx Hy]]. lia.
Defined.

Definition defaultDepthTransitionKernel : DepthTransitionKernel := canonicalDepthKernel.

(** ** 4. Lemmes partagés de positivité et théorèmes dynamiques *)

Lemma canonicalDepthWeight_pos_of_central :
  forall z : nat, dtk_weight canonicalDepthKernel (mkPoint 0%Z 0%Z z) (mkPoint 0%Z 0%Z (z + 1)) <> 0.
Proof.
  intro z.
  unfold canonicalDepthKernel, canonicalDepthWeight, isValidCoreAffectB; simpl.
  rewrite Nat.eqb_refl; simpl. lia.
Qed.

Lemma canonicalDepthWeight_pos_of_axial_y :
  forall (py qy : Z) (pz : nat),
    isValidCoreAffect (mkPoint 0%Z py pz) ->
    isValidCoreAffect (mkPoint 0%Z qy (pz + 1)) ->
    py <> 0%Z -> qy <> 0%Z -> (py * qy >= 0)%Z ->
    dtk_weight canonicalDepthKernel (mkPoint 0%Z py pz) (mkPoint 0%Z qy (pz + 1)) <> 0.
Proof.
  intros py qy pz Hpv Hqv Hpy Hqy Hmul.
  apply (proj2 (isValidCoreAffectB_iff _)) in Hpv.
  apply (proj2 (isValidCoreAffectB_iff _)) in Hqv.
  unfold canonicalDepthKernel, canonicalDepthWeight; simpl.
  rewrite Hpv, Hqv, Nat.eqb_refl; simpl.
  destruct (Z.leb_spec0 0 (py * qy)); [| lia].
  destruct (Z.eqb_spec qy 0); [lia |].
  destruct (Z.eqb_spec py 0); [lia |].
  simpl. lia.
Qed.

Lemma canonicalDepthWeight_pos_of_axial_x :
  forall (px qx : Z) (pz : nat),
    isValidCoreAffect (mkPoint px 0%Z pz) ->
    isValidCoreAffect (mkPoint qx 0%Z (pz + 1)) ->
    px <> 0%Z -> qx <> 0%Z -> (px * qx >= 0)%Z ->
    dtk_weight canonicalDepthKernel (mkPoint px 0%Z pz) (mkPoint qx 0%Z (pz + 1)) <> 0.
Proof.
  intros px qx pz Hpv Hqv Hpx Hqx Hmul.
  apply (proj2 (isValidCoreAffectB_iff _)) in Hpv.
  apply (proj2 (isValidCoreAffectB_iff _)) in Hqv.
  unfold canonicalDepthKernel, canonicalDepthWeight; simpl.
  rewrite Hpv, Hqv, Nat.eqb_refl; simpl.
  destruct (Z.leb_spec0 0 (px * qx)); [| lia].
  destruct (Z.eqb_spec qx 0); [lia |].
  destruct (Z.eqb_spec px 0); [lia |].
  simpl. lia.
Qed.

Lemma canonicalDepthWeight_pos_of_nonaxial :
  forall (px py qx qy : Z) (pz : nat),
    isValidCoreAffect (mkPoint px py pz) ->
    isValidCoreAffect (mkPoint qx qy (pz + 1)) ->
    px <> 0%Z -> py <> 0%Z -> qx <> 0%Z -> qy <> 0%Z ->
    (px * qx >= 0)%Z -> (py * qy >= 0)%Z ->
    Z.abs_nat qx >= Z.abs_nat px -> Z.abs_nat qy >= Z.abs_nat py ->
    dtk_weight canonicalDepthKernel (mkPoint px py pz) (mkPoint qx qy (pz + 1)) <> 0.
Proof.
  intros px py qx qy pz Hpv Hqv Hpx Hpy Hqx Hqy Hmulx Hmuly Hgex Hgey.
  apply (proj2 (isValidCoreAffectB_iff _)) in Hpv.
  apply (proj2 (isValidCoreAffectB_iff _)) in Hqv.
  unfold canonicalDepthKernel, canonicalDepthWeight; simpl.
  rewrite Hpv, Hqv, Nat.eqb_refl; simpl.
  destruct (Z.leb_spec0 0 (px * qx)); [| lia].
  destruct (Z.leb_spec0 0 (py * qy)); [| lia].
  destruct (Z.eqb_spec qx 0); [lia |].
  destruct (Z.eqb_spec qy 0); [lia |].
  destruct (Z.eqb_spec px 0); [lia |].
  destruct (Z.eqb_spec py 0); [lia |].
  destruct (Nat.leb_spec0 (Z.abs_nat px) (Z.abs_nat qx)); [| lia].
  destruct (Nat.leb_spec0 (Z.abs_nat py) (Z.abs_nat qy)); [| lia].
  simpl.
  destruct ((Z.abs_nat px =? Z.abs_nat py) && (Z.abs_nat qx =? Z.abs_nat qy)); lia.
Qed.

Theorem canonicalDepthKernel_reaches_crown :
  forall q : CoreAffectPoint,
    isValidCoreAffect q ->
    pt_z q >= 3 ->
    ~ CoreAffectPoint_isCentral q ->
    exists p : CoreAffectPoint,
      isValidCoreAffect p /\
      pt_z p + 1 = pt_z q /\
      dtk_weight canonicalDepthKernel p q <> 0.
Proof.
  intros [qx qy qz] Hvalid Hz Hcrown; simpl in *.
  destruct qz as [| [| [| d]]]; [lia | lia | lia |].
  assert (Hcrown_q : CoreAffectPoint_isOnCrown (mkPoint qx qy (S (S (S d))))).
  { destruct Hvalid; [exfalso; apply Hcrown; assumption | assumption]. }
  unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum in Hcrown_q; simpl in Hcrown_q.
  destruct Hcrown_q as [_ Hsum].
  destruct (Z.eq_dec qx 0) as [Hqx0 | Hqx_nz].
  - subst qx.
    assert (Hqy_nz : qy <> 0%Z) by (intro H0; apply Hcrown; split; [reflexivity | exact H0]).
    destruct (Z_lt_le_dec 0 qy) as [Hpos | Hle].
    + assert (Hpv : isValidCoreAffect (mkPoint 0%Z (Z.of_nat (2 * d + 2)) (d + 2))).
      { right. unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum; simpl.
        split; [lia | replace (d + 2) with (S (S d)) by lia; simpl; lia]. }
      exists (mkPoint 0%Z (Z.of_nat (2 * d + 2)) (d + 2)).
      split; [exact Hpv | split; [simpl; lia |]].
      replace (S (S (S d))) with ((d + 2) + 1) in Hvalid |- * by lia.
      apply canonicalDepthWeight_pos_of_axial_y; try assumption; lia || nia.
    + assert (Hpv : isValidCoreAffect (mkPoint 0%Z (- Z.of_nat (2 * d + 2))%Z (d + 2))).
      { right. unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum; simpl.
        split; [lia | replace (d + 2) with (S (S d)) by lia; simpl; lia]. }
      exists (mkPoint 0%Z (- Z.of_nat (2 * d + 2))%Z (d + 2)).
      split; [exact Hpv | split; [simpl; lia |]].
      replace (S (S (S d))) with ((d + 2) + 1) in Hvalid |- * by lia.
      apply canonicalDepthWeight_pos_of_axial_y; try assumption; lia || nia.
  - destruct (Z.eq_dec qy 0) as [Hqy0 | Hqy_nz].
    + subst qy.
      destruct (Z_lt_le_dec 0 qx) as [Hpos | Hle].
      * assert (Hpv : isValidCoreAffect (mkPoint (Z.of_nat (2 * d + 2)) 0%Z (d + 2))).
        { right. unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum; simpl.
          split; [lia | replace (d + 2) with (S (S d)) by lia; simpl; lia]. }
        exists (mkPoint (Z.of_nat (2 * d + 2)) 0%Z (d + 2)).
        split; [exact Hpv | split; [simpl; lia |]].
        replace (S (S (S d))) with ((d + 2) + 1) in Hvalid |- * by lia.
        apply canonicalDepthWeight_pos_of_axial_x; try assumption; lia || nia.
      * assert (Hpv : isValidCoreAffect (mkPoint (- Z.of_nat (2 * d + 2))%Z 0%Z (d + 2))).
        { right. unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum; simpl.
          split; [lia | replace (d + 2) with (S (S d)) by lia; simpl; lia]. }
        exists (mkPoint (- Z.of_nat (2 * d + 2))%Z 0%Z (d + 2)).
        split; [exact Hpv | split; [simpl; lia |]].
        replace (S (S (S d))) with ((d + 2) + 1) in Hvalid |- * by lia.
        apply canonicalDepthWeight_pos_of_axial_x; try assumption; lia || nia.
    + set (ax := if Nat.leb 2 (Z.abs_nat qx) then
                   (if Nat.leb 2 (Z.abs_nat qy) then Z.abs_nat qx - 1 else Z.abs_nat qx - 2)
                 else 1).
      set (ay := 2 * d + 2 - ax).
      assert (Hbounds : ax >= 1 /\ ax <= Z.abs_nat qx /\ ay >= 1 /\ ay <= Z.abs_nat qy /\ ax + ay = 2 * d + 2).
      { unfold ax, ay.
        destruct (Nat.leb_spec0 2 (Z.abs_nat qx));
        [destruct (Nat.leb_spec0 2 (Z.abs_nat qy)) |]; lia. }
      destruct Hbounds as [Hax_lo [Hax_hi [Hay_lo [Hay_hi Hsum_ab]]]].
      set (px := if (0 <? qx)%Z then Z.of_nat ax else (- Z.of_nat ax)%Z).
      set (py := if (0 <? qy)%Z then Z.of_nat ay else (- Z.of_nat ay)%Z).
      assert (Hpx_abs : Z.abs_nat px = ax) by (unfold px; destruct (Z.ltb_spec0 0 qx); lia).
      assert (Hpy_abs : Z.abs_nat py = ay) by (unfold py; destruct (Z.ltb_spec0 0 qy); lia).
      assert (Hpx_nz : px <> 0%Z) by (unfold px; destruct (Z.ltb_spec0 0 qx); lia).
      assert (Hpy_nz : py <> 0%Z) by (unfold py; destruct (Z.ltb_spec0 0 qy); lia).
      assert (Hmulx : (px * qx >= 0)%Z) by (unfold px; destruct (Z.ltb_spec0 0 qx); nia).
      assert (Hmuly : (py * qy >= 0)%Z) by (unfold py; destruct (Z.ltb_spec0 0 qy); nia).
      assert (Hpv : isValidCoreAffect (mkPoint px py (d + 2))).
      { right. unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum; simpl.
        split; [lia | replace (d + 2) with (S (S d)) by lia; simpl; lia]. }
      exists (mkPoint px py (d + 2)).
      split; [exact Hpv | split; [simpl; lia |]].
      replace (S (S (S d))) with ((d + 2) + 1) in Hvalid |- * by lia.
      apply canonicalDepthWeight_pos_of_nonaxial; try assumption; lia.
Qed.

Theorem canonicalDepthKernel_reaches_lateral :
  forall q : CoreAffectPoint,
    isValidCoreAffect q ->
    CoreAffectPoint_classifyGeometry q = GT_lateral ->
    exists p : CoreAffectPoint,
      isValidCoreAffect p /\
      pt_z p + 1 = pt_z q /\
      dtk_weight canonicalDepthKernel p q <> 0.
Proof.
  intros [qx qy qz] Hvalid Hlat.
  assert (Hnc : ~ CoreAffectPoint_isCentral (mkPoint qx qy qz)).
  { intros [Hx Hy]. unfold CoreAffectPoint_isCentral in Hx, Hy; simpl in Hx, Hy.
    unfold CoreAffectPoint_classifyGeometry in Hlat; simpl in Hlat.
    subst qx qy. discriminate. }
  assert (Hz3 : qz >= 3).
  { destruct Hvalid as [Hc | [Hz2 Hsum]]; [exfalso; apply Hnc; exact Hc |].
    unfold CoreAffectPoint_displacementSum in Hsum; simpl in *.
    destruct qz as [| [| [| d]]]; try lia.
    simpl in Hsum.
    unfold CoreAffectPoint_classifyGeometry in Hlat; simpl in Hlat.
    destruct (Z.eqb_spec qx 0); destruct (Z.eqb_spec qy 0); simpl in Hlat; try discriminate.
    destruct (Nat.eqb_spec (Z.abs_nat qx) (Z.abs_nat qy)); simpl in Hlat; try discriminate.
    lia. }
  apply canonicalDepthKernel_reaches_crown; assumption.
Qed.

Theorem lateral_reachable :
  forall q : CoreAffectPoint,
    isValidCoreAffect q ->
    CoreAffectPoint_classifyGeometry q = GT_lateral ->
    exists p : CoreAffectPoint,
      isValidCoreAffect p /\
      pt_z p + 1 = pt_z q /\
      dtk_weight canonicalDepthKernel p q <> 0.
Proof.
  exact canonicalDepthKernel_reaches_lateral.
Qed.

Inductive DepthTransitionKernel_Reachable (K : DepthTransitionKernel) :
    CoreAffectPoint -> CoreAffectPoint -> Prop :=
  | Reach_refl : forall p : CoreAffectPoint, DepthTransitionKernel_Reachable K p p
  | Reach_step : forall p m q : CoreAffectPoint,
      DepthTransitionKernel_Reachable K p m ->
      dtk_weight K m q <> 0 ->
      DepthTransitionKernel_Reachable K p q.

Theorem canonicalDepthKernel_crown_from_surprise :
  forall (d : nat) (q : CoreAffectPoint),
    isValidCoreAffect q ->
    pt_z q = d + 2 ->
    ~ CoreAffectPoint_isCentral q ->
    DepthTransitionKernel_Reachable canonicalDepthKernel (mkPoint 0%Z 0%Z 1) q.
Proof.
  induction d as [| d IH].
  - intros [qx qy qz] Hvalid Hz Hnc; simpl in Hz.
    assert (Hq0 : qx <> 0%Z \/ qy <> 0%Z).
    { destruct (Z.eq_dec qx 0); [right; intro Hy; apply Hnc; split; assumption | left; assumption]. }
    assert (Hw : dtk_weight canonicalDepthKernel (mkPoint 0%Z 0%Z 1) (mkPoint qx qy qz) <> 0).
    { apply (proj2 (isValidCoreAffectB_iff _)) in Hvalid.
      unfold canonicalDepthKernel, canonicalDepthWeight; simpl.
      change (isValidCoreAffectB (mkPoint 0%Z 0%Z 1)) with true.
      rewrite Hvalid, Hz. simpl.
      replace (Nat.eqb 2 2) with true by reflexivity; simpl.
      destruct (Z.eqb_spec qx 0); destruct (Z.eqb_spec qy 0); simpl; lia. }
    eapply Reach_step; [apply Reach_refl | exact Hw].
  - intros q Hvalid Hz Hnc.
    destruct (canonicalDepthKernel_reaches_crown q Hvalid ltac:(lia) Hnc) as [p [Hpv [Hpz Hwpq]]].
    assert (Hp_nc : ~ CoreAffectPoint_isCentral p).
    { intros [Hpx Hpy].
      unfold CoreAffectPoint_isCentral in Hpx, Hpy.
      assert (Hzero : dtk_weight canonicalDepthKernel p q = 0).
      { unfold canonicalDepthKernel, canonicalDepthWeight; simpl.
        rewrite Hpx, Hpy; simpl.
        destruct (isValidCoreAffectB p && isValidCoreAffectB q &&
                  Nat.eqb (pt_z q) (pt_z p + 1) && (0 <=? 0)%Z); [| reflexivity].
        destruct (Z.eqb_spec (pt_x q) 0); destruct (Z.eqb_spec (pt_y q) 0); simpl;
          [exfalso; apply Hnc; split; assumption |
           destruct (Nat.eqb_spec (pt_z p) 1); simpl; lia |
           destruct (Nat.eqb_spec (pt_z p) 1); simpl; lia |
           destruct (Nat.eqb_spec (pt_z p) 1); simpl; lia]. }
      exact (Hwpq Hzero). }
    eapply Reach_step with (m := p); [apply IH; try assumption; lia | exact Hwpq].
Qed.

Theorem lateral_reachable_from_surprise :
  forall q : CoreAffectPoint,
    isValidCoreAffect q ->
    CoreAffectPoint_classifyGeometry q = GT_lateral ->
    DepthTransitionKernel_Reachable canonicalDepthKernel (mkPoint 0%Z 0%Z 1) q.
Proof.
  intros [qx qy qz] Hvalid Hlat.
  assert (Hnc : ~ CoreAffectPoint_isCentral (mkPoint qx qy qz)).
  { intros [Hx Hy]. unfold CoreAffectPoint_isCentral in Hx, Hy; simpl in Hx, Hy.
    unfold CoreAffectPoint_classifyGeometry in Hlat; simpl in Hlat.
    subst qx qy. discriminate. }
  assert (Hz2 : qz >= 2).
  { destruct Hvalid as [Hc | [Hz2 _]]; [exfalso; apply Hnc; exact Hc | exact Hz2]. }
  apply canonicalDepthKernel_crown_from_surprise with (d := qz - 2); try assumption; simpl; lia.
Qed.

Theorem canonicalDepthKernel_colere_bifurcates :
  dtk_weight canonicalDepthKernel (mkPoint (-1)%Z 1%Z 2) (mkPoint (-2)%Z 2%Z 3) = 2 /\
  dtk_weight canonicalDepthKernel (mkPoint (-1)%Z 1%Z 2) (mkPoint (-1)%Z 3%Z 3) = 1 /\
  dtk_weight canonicalDepthKernel (mkPoint (-1)%Z 1%Z 2) (mkPoint (-3)%Z 1%Z 3) = 1.
Proof.
  repeat split; reflexivity.
Qed.

Theorem canonicalDepthKernel_axial_instability_p2 :
  dtk_weight canonicalDepthKernel (mkPoint 0%Z 2%Z 2) (mkPoint 2%Z 2%Z 3) >
  dtk_weight canonicalDepthKernel (mkPoint 0%Z 2%Z 2) (mkPoint 0%Z 4%Z 3) /\
  dtk_weight canonicalDepthKernel (mkPoint 0%Z 2%Z 2) (mkPoint (-2)%Z 2%Z 3) >
  dtk_weight canonicalDepthKernel (mkPoint 0%Z 2%Z 2) (mkPoint 0%Z 4%Z 3).
Proof.
  split;
    [replace (dtk_weight canonicalDepthKernel (mkPoint 0%Z 2%Z 2) (mkPoint 2%Z 2%Z 3)) with 2 by reflexivity;
     replace (dtk_weight canonicalDepthKernel (mkPoint 0%Z 2%Z 2) (mkPoint 0%Z 4%Z 3)) with 1 by reflexivity; lia |
     replace (dtk_weight canonicalDepthKernel (mkPoint 0%Z 2%Z 2) (mkPoint (-2)%Z 2%Z 3)) with 2 by reflexivity;
     replace (dtk_weight canonicalDepthKernel (mkPoint 0%Z 2%Z 2) (mkPoint 0%Z 4%Z 3)) with 1 by reflexivity; lia].
Qed.

(** ** 5. Somme sortante discrète et normalisation rationnelle exacte *)

Definition intRange (k : nat) : list Z :=
  map (fun i : nat => (Z.of_nat i - Z.of_nat k)%Z) (seq 0 (2 * k + 1)).

Lemma mem_intRange :
  forall (k : nat) (v : Z), Z.abs_nat v <= k -> In v (intRange k).
Proof.
  intros k v Hv.
  unfold intRange.
  apply in_map_iff.
  exists (Z.to_nat (v + Z.of_nat k)).
  split; [lia |].
  apply in_seq. lia.
Qed.

Definition zBound (z : nat) : nat :=
  match z with
  | 0 => 0
  | 1 => 0
  | S (S d) => 2 * d + 2
  end.

Lemma valid_x_bound :
  forall q : CoreAffectPoint, isValidCoreAffect q -> Z.abs_nat (pt_x q) <= zBound (pt_z q).
Proof.
  intros [x y z] [[Hx _] | [Hz Hsum]].
  - unfold CoreAffectPoint_isCentral in Hx; simpl in *; lia.
  - unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum in Hz, Hsum; simpl in *.
    destruct z as [| [| d]]; simpl in *; lia.
Qed.

Lemma valid_y_bound :
  forall q : CoreAffectPoint, isValidCoreAffect q -> Z.abs_nat (pt_y q) <= zBound (pt_z q).
Proof.
  intros [x y z] [[_ Hy] | [Hz Hsum]].
  - unfold CoreAffectPoint_isCentral in Hy; simpl in *; lia.
  - unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum in Hz, Hsum; simpl in *.
    destruct z as [| [| d]]; simpl in *; lia.
Qed.

Definition stratumPoints (z : nat) : list CoreAffectPoint :=
  filter isValidCoreAffectB
    (flat_map (fun x => map (fun y => mkPoint x y z) (intRange (zBound z)))
              (intRange (zBound z))).

Theorem mem_stratumPoints_of_valid :
  forall q : CoreAffectPoint, isValidCoreAffect q -> In q (stratumPoints (pt_z q)).
Proof.
  intros [x y z] Hv; simpl.
  pose proof (valid_x_bound _ Hv) as Hbx.
  pose proof (valid_y_bound _ Hv) as Hby.
  unfold stratumPoints.
  apply filter_In. split.
  - apply in_flat_map. exists x. split; [apply mem_intRange; exact Hbx |].
    apply in_map_iff. exists y. split; [reflexivity | apply mem_intRange; exact Hby].
  - apply (proj2 (isValidCoreAffectB_iff _)). exact Hv.
Qed.

Lemma fold_left_add_init :
  forall (l : list nat) (acc : nat),
    fold_left Nat.add l acc = acc + fold_left Nat.add l 0.
Proof.
  induction l as [| a t IH]; intro acc; simpl.
  - lia.
  - rewrite IH, (IH a). lia.
Qed.

Lemma le_fold_left_add_of_mem :
  forall (A : Type) (f : A -> nat) (l : list A) (x : A),
    In x l -> f x <= fold_left Nat.add (map f l) 0.
Proof.
  intros A f. induction l as [| a t IH]; intros x Hx; simpl in *.
  - contradiction.
  - rewrite fold_left_add_init.
    destruct Hx as [Heq | Ht].
    + subst a. lia.
    + specialize (IH x Ht). lia.
Qed.

Definition DepthTransitionKernel_outgoingWeight (K : DepthTransitionKernel) (p : CoreAffectPoint) : nat :=
  fold_left Nat.add (map (dtk_weight K p) (stratumPoints (pt_z p + 1))) 0.

Theorem DepthTransitionKernel_outgoingWeight_pos_of_witness :
  forall (K : DepthTransitionKernel) (p q : CoreAffectPoint),
    dtk_weight K p q <> 0 ->
    DepthTransitionKernel_outgoingWeight K p > 0.
Proof.
  intros K p q Hw.
  pose proof (dtk_support_valid K p q Hw) as Hv.
  pose proof (dtk_support_adjacent K p q Hw) as Hadj.
  assert (Hmem : In q (stratumPoints (pt_z p + 1))).
  { rewrite <- Hadj. apply mem_stratumPoints_of_valid. exact Hv. }
  pose proof (le_fold_left_add_of_mem _ (dtk_weight K p) (stratumPoints (pt_z p + 1)) q Hmem) as Hle.
  unfold DepthTransitionKernel_outgoingWeight. lia.
Qed.

Theorem canonicalDepthKernel_outgoingWeight_pos :
  forall p : CoreAffectPoint,
    isValidCoreAffect p ->
    DepthTransitionKernel_outgoingWeight canonicalDepthKernel p > 0.
Proof.
  intros [px py pz] H.
  destruct (Z.eq_dec px 0) as [Hpx0 | Hpx_nz];
  destruct (Z.eq_dec py 0) as [Hpy0 | Hpy_nz].
  - subst px py.
    eapply DepthTransitionKernel_outgoingWeight_pos_of_witness.
    apply canonicalDepthWeight_pos_of_central.
  - assert (Hcr : CoreAffectPoint_isOnCrown (mkPoint px py pz)).
    { destruct H as [[Hx Hy] | Hcr]; [simpl in *; lia | exact Hcr]. }
    destruct Hcr as [Hz2 Hsum]. simpl in Hz2.
    destruct pz as [| [| d]]; [lia | lia |].
    subst px.
    destruct (Z_lt_le_dec 0 py) as [Hpos | Hle].
    + assert (Hqv : isValidCoreAffect (mkPoint 0%Z (Z.of_nat (2 * d + 4)) ((d + 2) + 1))).
      { right. unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum; simpl.
        split; [lia | replace ((d + 2) + 1) with (S (S (S d))) by lia; simpl; lia]. }
      replace (S (S d)) with (d + 2) in H |- * by lia.
      eapply DepthTransitionKernel_outgoingWeight_pos_of_witness with (q := mkPoint 0%Z (Z.of_nat (2 * d + 4)) ((d + 2) + 1)).
      apply canonicalDepthWeight_pos_of_axial_y; try assumption; try lia; nia.
    + assert (Hqv : isValidCoreAffect (mkPoint 0%Z (- Z.of_nat (2 * d + 4))%Z ((d + 2) + 1))).
      { right. unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum; simpl.
        split; [lia | replace ((d + 2) + 1) with (S (S (S d))) by lia; simpl; lia]. }
      replace (S (S d)) with (d + 2) in H |- * by lia.
      eapply DepthTransitionKernel_outgoingWeight_pos_of_witness with (q := mkPoint 0%Z (- Z.of_nat (2 * d + 4))%Z ((d + 2) + 1)).
      apply canonicalDepthWeight_pos_of_axial_y; try assumption; try lia; nia.
  - assert (Hcr : CoreAffectPoint_isOnCrown (mkPoint px py pz)).
    { destruct H as [[Hx Hy] | Hcr]; [simpl in *; lia | exact Hcr]. }
    destruct Hcr as [Hz2 Hsum]. simpl in Hz2.
    destruct pz as [| [| d]]; [lia | lia |].
    subst py.
    destruct (Z_lt_le_dec 0 px) as [Hpos | Hle].
    + assert (Hqv : isValidCoreAffect (mkPoint (Z.of_nat (2 * d + 4)) 0%Z ((d + 2) + 1))).
      { right. unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum; simpl.
        split; [lia | replace ((d + 2) + 1) with (S (S (S d))) by lia; simpl; lia]. }
      replace (S (S d)) with (d + 2) in H |- * by lia.
      eapply DepthTransitionKernel_outgoingWeight_pos_of_witness with (q := mkPoint (Z.of_nat (2 * d + 4)) 0%Z ((d + 2) + 1)).
      apply canonicalDepthWeight_pos_of_axial_x; try assumption; try lia; nia.
    + assert (Hqv : isValidCoreAffect (mkPoint (- Z.of_nat (2 * d + 4))%Z 0%Z ((d + 2) + 1))).
      { right. unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum; simpl.
        split; [lia | replace ((d + 2) + 1) with (S (S (S d))) by lia; simpl; lia]. }
      replace (S (S d)) with (d + 2) in H |- * by lia.
      eapply DepthTransitionKernel_outgoingWeight_pos_of_witness with (q := mkPoint (- Z.of_nat (2 * d + 4))%Z 0%Z ((d + 2) + 1)).
      apply canonicalDepthWeight_pos_of_axial_x; try assumption; try lia; nia.
  - assert (Hcr : CoreAffectPoint_isOnCrown (mkPoint px py pz)).
    { destruct H as [[Hx Hy] | Hcr]; [simpl in *; lia | exact Hcr]. }
    destruct Hcr as [Hz2 Hsum].
    unfold CoreAffectPoint_displacementSum in Hsum; simpl in *.
    destruct pz as [| [| d]]; [lia | lia |].
    simpl in Hsum.
    set (qx := if (0 <? px)%Z then (px + 1)%Z else (px - 1)%Z).
    set (qy := if (0 <? py)%Z then (py + 1)%Z else (py - 1)%Z).
    assert (Hq_props :
      Z.abs_nat qx = Z.abs_nat px + 1 /\
      Z.abs_nat qy = Z.abs_nat py + 1 /\
      qx <> 0%Z /\ qy <> 0%Z /\
      (px * qx >= 0)%Z /\ (py * qy >= 0)%Z).
    { unfold qx, qy.
      destruct (Z.ltb_spec0 0 px); destruct (Z.ltb_spec0 0 py); repeat split; try lia; nia. }
    destruct Hq_props as [Hqx_abs [Hqy_abs [Hqx_nz [Hqy_nz [Hmulx Hmuly]]]]].
    assert (Hqv : isValidCoreAffect (mkPoint qx qy ((d + 2) + 1))).
    { right. unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum; simpl.
      split; [lia | replace ((d + 2) + 1) with (S (S (S d))) by lia; simpl; lia]. }
    replace (S (S d)) with (d + 2) in H |- * by lia.
    eapply DepthTransitionKernel_outgoingWeight_pos_of_witness with (q := mkPoint qx qy ((d + 2) + 1)).
    apply canonicalDepthWeight_pos_of_nonaxial; try assumption; lia.
Qed.

(** ** 6. Appartenance graduée aux attracteurs probabilistes (Résolution R1) *)

Definition attractorMembership (p : CoreAffectPoint) (g : TaxonomicGroup) : nat :=
  let ax := Z.abs_nat (pt_x p) in
  let ay := Z.abs_nat (pt_y p) in
  let r  := ax + ay in
  let m  := if Nat.leb ax ay then ax else ay in
  match g with
  | TG_operateurCentral => if (pt_x p =? 0)%Z then (if (pt_y p =? 0)%Z then 1 else 0) else 0
  | TG_groupeJoie       => if (0 <? pt_y p)%Z then (if Nat.ltb ax ay then r else ay) else 0
  | TG_groupeTristesse  => if (pt_y p <? 0)%Z then (if Nat.ltb ax ay then r else ay) else 0
  | TG_groupeCourage    => if (0 <? pt_x p)%Z then (if Nat.ltb ay ax then r else ax) else 0
  | TG_groupePeur       => if (pt_x p <? 0)%Z then (if Nat.ltb ay ax then r else ax) else 0
  | TG_groupeDesir      => if (0 <? pt_x p)%Z then (if (0 <? pt_y p)%Z then 2 * m else 0) else 0
  | TG_groupeDegout     => if (pt_x p <? 0)%Z then (if (pt_y p <? 0)%Z then 2 * m else 0) else 0
  | TG_groupeColere     => if (pt_x p <? 0)%Z then (if (0 <? pt_y p)%Z then 2 * m else 0) else 0
  | TG_groupeCalme      => if (0 <? pt_x p)%Z then (if (pt_y p <? 0)%Z then 2 * m else 0) else 0
  end.

Theorem classifyTaxonomicGroup_unique_maximizer :
  forall (p : CoreAffectPoint) (g : TaxonomicGroup),
    g <> classifyTaxonomicGroup p ->
    attractorMembership p g < attractorMembership p (classifyTaxonomicGroup p).
Proof.
  intros [x y z] g Hne.
  remember (classifyTaxonomicGroup (mkPoint x y z)) as c eqn:Hc.
  pose proof (classifyTaxonomicGroup_correct (mkPoint x y z)) as Hmatch.
  rewrite <- Hc in Hmatch.
  destruct c; destruct g;
    try (exfalso; apply Hne; reflexivity);
    unfold matchesTaxonomicGroup, attractorMembership in *; cbv zeta in *; simpl in *;
    try (destruct (Z.eqb_spec x 0); try lia);
    try (destruct (Z.eqb_spec y 0); try lia);
    try (destruct (Z.ltb_spec0 0 x); try lia);
    try (destruct (Z.ltb_spec0 x 0); try lia);
    try (destruct (Z.ltb_spec0 0 y); try lia);
    try (destruct (Z.ltb_spec0 y 0); try lia);
    try (destruct (Nat.ltb_spec0 (Z.abs_nat x) (Z.abs_nat y)); try lia);
    try (destruct (Nat.ltb_spec0 (Z.abs_nat y) (Z.abs_nat x)); try lia);
    try (destruct (Nat.leb_spec0 (Z.abs_nat x) (Z.abs_nat y)); try lia);
    lia.
Qed.

Theorem classifyTaxonomicGroup_maximizes_membership :
  forall (p : CoreAffectPoint) (g : TaxonomicGroup),
    attractorMembership p g <= attractorMembership p (classifyTaxonomicGroup p).
Proof.
  intros p g.
  destruct (TaxonomicGroup_eq_dec g (classifyTaxonomicGroup p)) as [Heq | Hne].
  - subst g. apply le_n.
  - apply Nat.lt_le_incl. apply classifyTaxonomicGroup_unique_maximizer. exact Hne.
Qed.

Theorem lateral_has_overlapping_attractors :
  forall p : CoreAffectPoint,
    CoreAffectPoint_classifyGeometry p = GT_lateral ->
    exists g1 g2 : TaxonomicGroup,
      g1 <> g2 /\ attractorMembership p g1 > 0 /\ attractorMembership p g2 > 0.
Proof.
  intros [x y z] Hlat.
  assert (Hx0 : x <> 0%Z).
  { intro H; unfold CoreAffectPoint_classifyGeometry in Hlat; simpl in Hlat.
    subst x; simpl in Hlat. destruct (Z.eqb_spec y 0); discriminate. }
  assert (Hy0 : y <> 0%Z).
  { intro H; unfold CoreAffectPoint_classifyGeometry in Hlat; simpl in Hlat.
    subst y; rewrite orb_true_r in Hlat; simpl in Hlat.
    destruct (Z.eqb_spec x 0); discriminate. }
  destruct (Z_lt_le_dec 0 x) as [Hx | Hxle];
  destruct (Z_lt_le_dec 0 y) as [Hy | Hyle].
  - exists TG_groupeJoie, TG_groupeDesir. repeat split; [discriminate | |];
      unfold attractorMembership; cbv zeta; simpl;
      try (destruct (Z.ltb_spec0 0 x); try lia);
      try (destruct (Z.ltb_spec0 0 y); try lia);
      try (destruct (Nat.ltb_spec0 (Z.abs_nat x) (Z.abs_nat y)));
      try (destruct (Nat.leb_spec0 (Z.abs_nat x) (Z.abs_nat y)));
      lia.
  - exists TG_groupeTristesse, TG_groupeCalme. repeat split; [discriminate | |];
      unfold attractorMembership; cbv zeta; simpl;
      try (destruct (Z.ltb_spec0 0 x); try lia);
      try (destruct (Z.ltb_spec0 y 0); try lia);
      try (destruct (Nat.ltb_spec0 (Z.abs_nat x) (Z.abs_nat y)));
      try (destruct (Nat.leb_spec0 (Z.abs_nat x) (Z.abs_nat y)));
      lia.
  - exists TG_groupeJoie, TG_groupeColere. repeat split; [discriminate | |];
      unfold attractorMembership; cbv zeta; simpl;
      try (destruct (Z.ltb_spec0 x 0); try lia);
      try (destruct (Z.ltb_spec0 0 y); try lia);
      try (destruct (Nat.ltb_spec0 (Z.abs_nat x) (Z.abs_nat y)));
      try (destruct (Nat.leb_spec0 (Z.abs_nat x) (Z.abs_nat y)));
      lia.
  - exists TG_groupeTristesse, TG_groupeDegout. repeat split; [discriminate | |];
      unfold attractorMembership; cbv zeta; simpl;
      try (destruct (Z.ltb_spec0 x 0); try lia);
      try (destruct (Z.ltb_spec0 y 0); try lia);
      try (destruct (Nat.ltb_spec0 (Z.abs_nat x) (Z.abs_nat y)));
      try (destruct (Nat.leb_spec0 (Z.abs_nat x) (Z.abs_nat y)));
      lia.
Qed.
