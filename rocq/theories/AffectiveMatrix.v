(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*)

From Stdlib Require Import Bool Arith PeanoNat ZArith Lia.
Require Import CartograffectRocq.PredictiveEngine.
Require Import CartograffectRocq.CoreAffect.

Open Scope bool_scope.
Open Scope nat_scope.

(** * Module AffectiveMatrix — Validation Rocq 9.1.0 *)

(** ** 1. Transduction phénoménologique : Pôles vécus, Valence et Activation *)

Inductive LivedExpectationPole : Type :=
  | LEP_epistemicCharge    : LivedExpectationPole
  | LEP_epistemicNeutral   : LivedExpectationPole
  | LEP_epistemicDischarge : LivedExpectationPole.

Inductive LivedControlPole : Type :=
  | LCP_pragmaticCharge    : LivedControlPole
  | LCP_pragmaticNeutral   : LivedControlPole
  | LCP_pragmaticDischarge : LivedControlPole.

Inductive EnergyRegime : Type :=
  | ER_neutralBasal           : EnergyRegime
  | ER_axialPure              : EnergyRegime
  | ER_positiveSynergy        : EnergyRegime
  | ER_negativeSynergy        : EnergyRegime
  | ER_ergotropicCompensation : EnergyRegime
  | ER_trophotropicRelease    : EnergyRegime.

Definition computeEnergyRegime (x y : Z) : EnergyRegime :=
  if (x =? 0)%Z && (y =? 0)%Z then ER_neutralBasal
  else if (x =? 0)%Z || (y =? 0)%Z then ER_axialPure
  else if (0 <? x)%Z && (0 <? y)%Z then ER_positiveSynergy
  else if (x <? 0)%Z && (y <? 0)%Z then ER_negativeSynergy
  else if (x <? 0)%Z && (0 <? y)%Z then ER_ergotropicCompensation
  else ER_trophotropicRelease.

Inductive HedonicPolarity : Type :=
  | Hed_positive : HedonicPolarity
  | Hed_negative : HedonicPolarity
  | Hed_neutral  : HedonicPolarity.

Definition HedonicPolarity_eqb (a b : HedonicPolarity) : bool :=
  match a, b with
  | Hed_positive, Hed_positive => true
  | Hed_negative, Hed_negative => true
  | Hed_neutral, Hed_neutral   => true
  | _, _                       => false
  end.

Definition HedonicPolarity_invert (p : HedonicPolarity) : HedonicPolarity :=
  match p with
  | Hed_positive => Hed_negative
  | Hed_negative => Hed_positive
  | Hed_neutral  => Hed_neutral
  end.

Definition computeHedonicPolarity (x y : Z) : HedonicPolarity :=
  if (0 <? x)%Z then Hed_positive
  else if (x <? 0)%Z then Hed_negative
  else if (0 <? y)%Z then Hed_positive
  else if (y <? 0)%Z then Hed_negative
  else Hed_neutral.

Definition computeValence (x y : Z) : HedonicPolarity :=
  computeHedonicPolarity x y.

Theorem HedonicPolarity_invert_involutive :
  forall p : HedonicPolarity, HedonicPolarity_invert (HedonicPolarity_invert p) = p.
Proof.
  intros []; reflexivity.
Qed.

Theorem x_positive_determines_positive_valence :
  forall x y : Z, (x > 0)%Z -> computeHedonicPolarity x y = Hed_positive.
Proof.
  intros x y Hx. unfold computeHedonicPolarity.
  destruct (Z.ltb_spec0 0 x); [reflexivity | lia].
Qed.

Theorem x_negative_determines_negative_valence :
  forall x y : Z, (x < 0)%Z -> computeHedonicPolarity x y = Hed_negative.
Proof.
  intros x y Hx. unfold computeHedonicPolarity.
  destruct (Z.ltb_spec0 0 x); [lia |].
  destruct (Z.ltb_spec0 x 0); [reflexivity | lia].
Qed.

Inductive PhenomenologicalActivation : Type :=
  | PA_basalWakefulness   : PhenomenologicalActivation
  | PA_ascendingRupture   : PhenomenologicalActivation
  | PA_operatorSuspension : PhenomenologicalActivation
  | PA_lowInhibition      : PhenomenologicalActivation
  | PA_epistemicVigilance : PhenomenologicalActivation
  | PA_highMobilization   : PhenomenologicalActivation.

Definition transduceExpectation (x : Z) : LivedExpectationPole :=
  if (x <? 0)%Z then LEP_epistemicCharge
  else if (0 <? x)%Z then LEP_epistemicDischarge
  else LEP_epistemicNeutral.

Definition transduceControl (y : Z) : LivedControlPole :=
  if (y <? 0)%Z then LCP_pragmaticCharge
  else if (0 <? y)%Z then LCP_pragmaticDischarge
  else LCP_pragmaticNeutral.

Definition computeActivation (p : CoreAffectPoint) : PhenomenologicalActivation :=
  if (pt_x p =? 0)%Z && (pt_y p =? 0)%Z then
    if Nat.eqb (pt_z p) 0 then PA_basalWakefulness
    else if Nat.eqb (pt_z p) 1 then PA_ascendingRupture
    else PA_operatorSuspension
  else if (0 <? pt_y p)%Z then
    PA_highMobilization
  else if (pt_y p <? 0)%Z then
    PA_lowInhibition
  else
    PA_epistemicVigilance.

(** ** 2. Les huit prototypes de la première couronne (Z = 2) *)

Inductive PrimaryCrownPrototype : Type :=
  | Proto_joie      : PrimaryCrownPrototype
  | Proto_tristesse : PrimaryCrownPrototype
  | Proto_peur      : PrimaryCrownPrototype
  | Proto_courage   : PrimaryCrownPrototype
  | Proto_desir     : PrimaryCrownPrototype
  | Proto_degout    : PrimaryCrownPrototype
  | Proto_colere    : PrimaryCrownPrototype
  | Proto_calme     : PrimaryCrownPrototype.

Definition PrimaryCrownPrototype_toPoint (proto : PrimaryCrownPrototype) : CoreAffectPoint :=
  match proto with
  | Proto_joie      => mkPoint 0%Z    2%Z    2
  | Proto_tristesse => mkPoint 0%Z    (-2)%Z 2
  | Proto_peur      => mkPoint (-2)%Z 0%Z    2
  | Proto_courage   => mkPoint 2%Z    0%Z    2
  | Proto_desir     => mkPoint 1%Z    1%Z    2
  | Proto_degout    => mkPoint (-1)%Z (-1)%Z 2
  | Proto_colere    => mkPoint (-1)%Z 1%Z    2
  | Proto_calme     => mkPoint 1%Z    (-1)%Z 2
  end.

Theorem PrimaryCrownPrototype_valid_on_crown :
  forall proto : PrimaryCrownPrototype,
    CoreAffectPoint_isOnCrown (PrimaryCrownPrototype_toPoint proto).
Proof.
  intros []; (split; [simpl; lia | reflexivity]).
Qed.

(** ** 3. Opérateur général d'antagonisme formel (Axial, Diagonal et Controlatéral) *)

Definition antagonistPoint (p : CoreAffectPoint) : CoreAffectPoint :=
  if (pt_x p =? 0)%Z || (pt_y p =? 0)%Z || Nat.eqb (Z.abs_nat (pt_x p)) (Z.abs_nat (pt_y p)) then
    mkPoint (- pt_x p)%Z (- pt_y p)%Z (pt_z p)
  else if ((0 <? pt_x p)%Z && (pt_y p <? 0)%Z) || ((pt_x p <? 0)%Z && (0 <? pt_y p)%Z) then
    mkPoint (pt_y p) (pt_x p) (pt_z p)
  else
    mkPoint (- pt_y p)%Z (- pt_x p)%Z (pt_z p).

(** ** 4. Propriétés structurelles et Invariants de la Matrice Affective *)

Theorem antagonistPoint_preserves_z :
  forall p : CoreAffectPoint, pt_z (antagonistPoint p) = pt_z p.
Proof.
  intros [x y z]. unfold antagonistPoint; simpl.
  destruct ((x =? 0)%Z || (y =? 0)%Z || (Z.abs_nat x =? Z.abs_nat y));
    [reflexivity |].
  destruct (((0 <? x)%Z && (y <? 0)%Z) || ((x <? 0)%Z && (0 <? y)%Z)); reflexivity.
Qed.

Theorem antagonistPoint_preserves_displacementSum :
  forall p : CoreAffectPoint,
    CoreAffectPoint_displacementSum (antagonistPoint p) = CoreAffectPoint_displacementSum p.
Proof.
  intros [x y z]. unfold antagonistPoint, CoreAffectPoint_displacementSum; simpl.
  destruct ((x =? 0)%Z || (y =? 0)%Z || (Z.abs_nat x =? Z.abs_nat y));
    simpl; [lia |].
  destruct (((0 <? x)%Z && (y <? 0)%Z) || ((x <? 0)%Z && (0 <? y)%Z)); simpl; lia.
Qed.

Theorem antagonistPoint_preserves_validity :
  forall p : CoreAffectPoint,
    isValidCoreAffect p -> isValidCoreAffect (antagonistPoint p).
Proof.
  intros [x y z] [[Hx Hy] | [Hz Hsum]].
  - left. unfold CoreAffectPoint_isCentral in Hx, Hy; simpl in Hx, Hy.
    subst x y. split; reflexivity.
  - right. split.
    + rewrite antagonistPoint_preserves_z. exact Hz.
    + rewrite antagonistPoint_preserves_displacementSum, antagonistPoint_preserves_z. exact Hsum.
Qed.

Theorem antagonistPoint_involutive :
  forall p : CoreAffectPoint, antagonistPoint (antagonistPoint p) = p.
Proof.
  intros [x y z].
  unfold antagonistPoint; simpl.
  destruct ((x =? 0)%Z || (y =? 0)%Z || (Z.abs_nat x =? Z.abs_nat y)) eqn:H1.
  - simpl.
    rewrite !orb_true_iff, !Z.eqb_eq, !Nat.eqb_eq in H1.
    destruct (( (-x =? 0)%Z || (-y =? 0)%Z || (Z.abs_nat (-x) =? Z.abs_nat (-y)) )) eqn:H1'.
    + f_equal; lia.
    + rewrite !orb_false_iff, !Z.eqb_neq, !Nat.eqb_neq in H1'. lia.
  - rewrite !orb_false_iff, !Z.eqb_neq, !Nat.eqb_neq in H1.
    destruct H1 as [[Hx0 Hy0] Hne].
    destruct (((0 <? x)%Z && (y <? 0)%Z) || ((x <? 0)%Z && (0 <? y)%Z)) eqn:H2; simpl.
    + rewrite orb_true_iff, !andb_true_iff, !Z.ltb_lt in H2.
      destruct (( (y =? 0)%Z || (x =? 0)%Z || (Z.abs_nat y =? Z.abs_nat x) )) eqn:H1'.
      * rewrite !orb_true_iff, !Z.eqb_eq, !Nat.eqb_eq in H1'. lia.
      * destruct (((0 <? y)%Z && (x <? 0)%Z) || ((y <? 0)%Z && (0 <? x)%Z)) eqn:H2'.
        -- reflexivity.
        -- rewrite orb_false_iff, !andb_false_iff, !Z.ltb_ge in H2'. lia.
    + rewrite orb_false_iff, !andb_false_iff, !Z.ltb_ge in H2.
      destruct (( (-y =? 0)%Z || (-x =? 0)%Z || (Z.abs_nat (-y) =? Z.abs_nat (-x)) )) eqn:H1'.
      * rewrite !orb_true_iff, !Z.eqb_eq, !Nat.eqb_eq in H1'. lia.
      * destruct (((0 <? -y)%Z && (-x <? 0)%Z) || ((-y <? 0)%Z && (0 <? -x)%Z)) eqn:H2'.
        -- rewrite orb_true_iff, !andb_true_iff, !Z.ltb_lt in H2'. lia.
        -- f_equal; lia.
Qed.

Theorem antagonistPoint_fixed_iff_central :
  forall p : CoreAffectPoint,
    antagonistPoint p = p <-> CoreAffectPoint_isCentral p.
Proof.
  intros [x y z].
  unfold antagonistPoint, CoreAffectPoint_isCentral; simpl.
  split.
  - intro H.
    destruct ((x =? 0)%Z || (y =? 0)%Z || (Z.abs_nat x =? Z.abs_nat y)) eqn:H1.
    + inversion H. lia.
    + rewrite !orb_false_iff, !Z.eqb_neq, !Nat.eqb_neq in H1.
      destruct (((0 <? x)%Z && (y <? 0)%Z) || ((x <? 0)%Z && (0 <? y)%Z)) eqn:H2.
      * inversion H. lia.
      * inversion H. lia.
  - intros [Hx Hy]. subst x y. reflexivity.
Qed.

Theorem contralateral_swaps_amplitudes :
  forall p : CoreAffectPoint,
    ~ (pt_x p = 0%Z \/ pt_y p = 0%Z \/ Z.abs_nat (pt_x p) = Z.abs_nat (pt_y p)) ->
    Z.abs_nat (pt_x (antagonistPoint p)) = Z.abs_nat (pt_y p) /\
    Z.abs_nat (pt_y (antagonistPoint p)) = Z.abs_nat (pt_x p).
Proof.
  intros [x y z] Hlat.
  unfold antagonistPoint; simpl.
  destruct ((x =? 0)%Z || (y =? 0)%Z || (Z.abs_nat x =? Z.abs_nat y)) eqn:H1.
  - rewrite !orb_true_iff, !Z.eqb_eq, !Nat.eqb_eq in H1. exfalso; apply Hlat; tauto.
  - destruct (((0 <? x)%Z && (y <? 0)%Z) || ((x <? 0)%Z && (0 <? y)%Z)); simpl; (split; lia).
Qed.

Theorem canonical_antagonist_examples :
  antagonistPoint (mkPoint 0%Z 2%Z 2) = mkPoint 0%Z (-2)%Z 2 /\
  antagonistPoint (mkPoint (-2)%Z 0%Z 2) = mkPoint 2%Z 0%Z 2 /\
  antagonistPoint (mkPoint (-1)%Z 1%Z 2) = mkPoint 1%Z (-1)%Z 2 /\
  antagonistPoint (mkPoint 1%Z 1%Z 2) = mkPoint (-1)%Z (-1)%Z 2 /\
  antagonistPoint (mkPoint (-1)%Z 5%Z 4) = mkPoint 5%Z (-1)%Z 4 /\
  antagonistPoint (mkPoint 1%Z 7%Z 5) = mkPoint (-7)%Z (-1)%Z 5 /\
  antagonistPoint (mkPoint 3%Z (-9)%Z 7) = mkPoint (-9)%Z 3%Z 7.
Proof.
  repeat split; reflexivity.
Qed.

Theorem antagonist_commutes_with_invert :
  forall (c : EngineCoupling) (d : nat),
    antagonistPoint (deployCouplingAtDepth c d) =
    deployCouplingAtDepth (mkEngineCoupling (Polarity_invert (ec_attente c)) (Polarity_invert (ec_controle c))) d.
Proof.
  intros [a ctrl] d.
  destruct a; destruct ctrl;
    unfold deployCouplingAtDepth, Polarity_invert, signedAmplitude, antagonistPoint; simpl;
    repeat match goal with
    | |- context [ (Z.of_nat ?n =? 0)%Z ] =>
      destruct (Z.eqb_spec (Z.of_nat n) 0); [lia |]
    | |- context [ (- Z.of_nat ?n =? 0)%Z ] =>
      destruct (Z.eqb_spec (- Z.of_nat n) 0); [lia |]
    | |- context [ Nat.eqb (Z.abs_nat ?z) (Z.abs_nat ?w) ] =>
      destruct (Nat.eqb_spec (Z.abs_nat z) (Z.abs_nat w)); [| lia]
    end;
    simpl; f_equal; lia.
Qed.

Lemma antagonistPoint_pos_pos :
  forall a b z : nat, a >= 1 -> b >= 1 ->
    antagonistPoint (mkPoint (Z.of_nat a) (Z.of_nat b) z) =
    mkPoint (- Z.of_nat b)%Z (- Z.of_nat a)%Z z.
Proof.
  intros a b z Ha Hb.
  unfold antagonistPoint; simpl.
  destruct (Z.eqb_spec (Z.of_nat a) 0); [lia |].
  destruct (Z.eqb_spec (Z.of_nat b) 0); [lia |].
  destruct (Nat.eqb_spec (Z.abs_nat (Z.of_nat a)) (Z.abs_nat (Z.of_nat b))) as [Heq | Hne]; simpl.
  - f_equal; lia.
  - destruct (Z.ltb_spec0 0 (Z.of_nat a)); [| lia].
    destruct (Z.ltb_spec0 (Z.of_nat b) 0); [lia |].
    destruct (Z.ltb_spec0 (Z.of_nat a) 0); [lia |].
    reflexivity.
Qed.

Lemma antagonistPoint_neg_neg :
  forall a b z : nat, a >= 1 -> b >= 1 ->
    antagonistPoint (mkPoint (- Z.of_nat a)%Z (- Z.of_nat b)%Z z) =
    mkPoint (Z.of_nat b) (Z.of_nat a) z.
Proof.
  intros a b z Ha Hb.
  unfold antagonistPoint; simpl.
  destruct (Z.eqb_spec (- Z.of_nat a) 0); [lia |].
  destruct (Z.eqb_spec (- Z.of_nat b) 0); [lia |].
  destruct (Nat.eqb_spec (Z.abs_nat (- Z.of_nat a)) (Z.abs_nat (- Z.of_nat b))) as [Heq | Hne]; simpl.
  - f_equal; lia.
  - destruct (Z.ltb_spec0 0 (- Z.of_nat a)); [lia |].
    destruct (Z.ltb_spec0 (- Z.of_nat a) 0); [| lia].
    destruct (Z.ltb_spec0 0 (- Z.of_nat b)); [lia |].
    simpl. f_equal; lia.
Qed.

Lemma antagonistPoint_pos_neg :
  forall a b z : nat, a >= 1 -> b >= 1 ->
    antagonistPoint (mkPoint (Z.of_nat a) (- Z.of_nat b)%Z z) =
    mkPoint (- Z.of_nat b)%Z (Z.of_nat a) z.
Proof.
  intros a b z Ha Hb.
  unfold antagonistPoint; simpl.
  destruct (Z.eqb_spec (Z.of_nat a) 0); [lia |].
  destruct (Z.eqb_spec (- Z.of_nat b) 0); [lia |].
  destruct (Nat.eqb_spec (Z.abs_nat (Z.of_nat a)) (Z.abs_nat (- Z.of_nat b))) as [Heq | Hne]; simpl.
  - f_equal; lia.
  - destruct (Z.ltb_spec0 0 (Z.of_nat a)); [| lia].
    destruct (Z.ltb_spec0 (- Z.of_nat b) 0); [| lia].
    reflexivity.
Qed.

Lemma antagonistPoint_neg_pos :
  forall a b z : nat, a >= 1 -> b >= 1 ->
    antagonistPoint (mkPoint (- Z.of_nat a)%Z (Z.of_nat b) z) =
    mkPoint (Z.of_nat b) (- Z.of_nat a)%Z z.
Proof.
  intros a b z Ha Hb.
  unfold antagonistPoint; simpl.
  destruct (Z.eqb_spec (- Z.of_nat a) 0); [lia |].
  destruct (Z.eqb_spec (Z.of_nat b) 0); [lia |].
  destruct (Nat.eqb_spec (Z.abs_nat (- Z.of_nat a)) (Z.abs_nat (Z.of_nat b))) as [Heq | Hne]; simpl.
  - f_equal; lia.
  - destruct (Z.ltb_spec0 0 (- Z.of_nat a)); [lia |].
    destruct (Z.ltb_spec0 (- Z.of_nat a) 0); [| lia].
    destruct (Z.ltb_spec0 0 (Z.of_nat b)); [| lia].
    simpl. reflexivity.
Qed.

Theorem antagonist_commutes_with_invert_precision :
  forall (c : EngineCoupling) (d piA piC : nat),
    antagonistPoint (deployCouplingWithPrecision c d piA piC) =
    deployCouplingWithPrecision
      (mkEngineCoupling (Polarity_invert (ec_attente c)) (Polarity_invert (ec_controle c)))
      d piC piA.
Proof.
  intros [a ctrl] d piA piC.
  pose proof (apportionRay_bounds d piA piC) as Hb.
  pose proof (apportionRay_swap d piA piC) as Hsw.
  destruct (apportionRay d piA piC) as [ax ay] eqn:Heq.
  simpl in Hb, Hsw. destruct Hb as [Hax [Hay _]].
  destruct a; destruct ctrl;
    unfold deployCouplingWithPrecision, Polarity_invert, signedAmplitude; simpl;
    try rewrite Heq; try rewrite Hsw; simpl.
  - apply antagonistPoint_neg_neg; assumption.
  - unfold antagonistPoint; simpl; rewrite orb_true_r; simpl; f_equal; lia.
  - apply antagonistPoint_neg_pos; assumption.
  - unfold antagonistPoint; simpl; f_equal; lia.
  - reflexivity.
  - unfold antagonistPoint; simpl; f_equal; lia.
  - apply antagonistPoint_pos_neg; assumption.
  - unfold antagonistPoint; simpl; rewrite orb_true_r; simpl; f_equal; lia.
  - apply antagonistPoint_pos_pos; assumption.
Qed.

Theorem antagonistPoint_unified :
  forall p : CoreAffectPoint,
    pt_x p <> 0%Z -> pt_y p <> 0%Z ->
    antagonistPoint p =
    mkPoint (- Z.sgn (pt_x p) * Z.of_nat (Z.abs_nat (pt_y p)))%Z
            (- Z.sgn (pt_y p) * Z.of_nat (Z.abs_nat (pt_x p)))%Z
            (pt_z p).
Proof.
  intros [x y z] Hx Hy; simpl in *.
  unfold antagonistPoint; simpl.
  destruct (Z.eqb_spec x 0); [lia |].
  destruct (Z.eqb_spec y 0); [lia |].
  destruct (Z_lt_le_dec 0 x) as [Hx_pos | Hx_le];
  destruct (Z_lt_le_dec 0 y) as [Hy_pos | Hy_le].
  - rewrite (Z.sgn_pos x) by lia; rewrite (Z.sgn_pos y) by lia.
    destruct (Nat.eqb_spec (Z.abs_nat x) (Z.abs_nat y));
      [rewrite !orb_false_l; f_equal; lia | rewrite !orb_false_l].
    destruct (Z.ltb_spec0 0 x); [| lia].
    destruct (Z.ltb_spec0 y 0); [lia |].
    destruct (Z.ltb_spec0 x 0); [lia |].
    rewrite !andb_false_l, !andb_false_r, !orb_false_l; f_equal; lia.
  - rewrite (Z.sgn_pos x) by lia; rewrite (Z.sgn_neg y) by lia.
    destruct (Nat.eqb_spec (Z.abs_nat x) (Z.abs_nat y));
      [rewrite !orb_false_l; f_equal; lia | rewrite !orb_false_l].
    destruct (Z.ltb_spec0 0 x); [| lia].
    destruct (Z.ltb_spec0 y 0); [| lia].
    rewrite !andb_true_l, !orb_true_l; f_equal; lia.
  - rewrite (Z.sgn_neg x) by lia; rewrite (Z.sgn_pos y) by lia.
    destruct (Nat.eqb_spec (Z.abs_nat x) (Z.abs_nat y));
      [rewrite !orb_false_l; f_equal; lia | rewrite !orb_false_l].
    destruct (Z.ltb_spec0 0 x); [lia |].
    destruct (Z.ltb_spec0 x 0); [| lia].
    destruct (Z.ltb_spec0 0 y); [| lia].
    rewrite !andb_true_r, !orb_true_r; f_equal; lia.
  - rewrite (Z.sgn_neg x) by lia; rewrite (Z.sgn_neg y) by lia.
    destruct (Nat.eqb_spec (Z.abs_nat x) (Z.abs_nat y));
      [rewrite !orb_false_l; f_equal; lia | rewrite !orb_false_l].
    destruct (Z.ltb_spec0 0 x); [lia |].
    destruct (Z.ltb_spec0 x 0); [| lia].
    destruct (Z.ltb_spec0 0 y); [lia |].
    rewrite !andb_false_l, !andb_false_r, !orb_false_l; f_equal; lia.
Qed.

Theorem antagonist_preserves_validity_in :
  forall (r : ResourceRegime) (p : CoreAffectPoint),
    isValidCoreAffectIn r p -> isValidCoreAffectIn r (antagonistPoint p).
Proof.
  intros [] p H.
  - apply antagonistPoint_preserves_validity. exact H.
  - destruct H as [Hcent | [Hz Hsum]].
    + left.
      pose proof (proj2 (antagonistPoint_fixed_iff_central p) Hcent) as Hfix.
      rewrite Hfix. exact Hcent.
    + right.
      rewrite antagonistPoint_preserves_z, antagonistPoint_preserves_displacementSum.
      split; assumption.
Qed.

(** ** 5. Règle de transition intra-couronne et Structure AffectiveMatrixState *)

Definition transferUnitXtoY (p : CoreAffectPoint) : CoreAffectPoint :=
  if (0 <? pt_x p)%Z && (0 <=? pt_y p)%Z then
    mkPoint (pt_x p - 1)%Z (pt_y p + 1)%Z (pt_z p)
  else
    p.

Theorem transferUnitXtoY_preserves_sum :
  forall p : CoreAffectPoint,
    CoreAffectPoint_displacementSum (transferUnitXtoY p) = CoreAffectPoint_displacementSum p.
Proof.
  intros [x y z]. unfold transferUnitXtoY, CoreAffectPoint_displacementSum; simpl.
  destruct (Z.ltb_spec0 0 x); destruct (Z.leb_spec0 0 y); simpl; lia.
Qed.

Definition transferUnitYtoX (p : CoreAffectPoint) : CoreAffectPoint :=
  if (0 <=? pt_x p)%Z && (0 <? pt_y p)%Z then
    mkPoint (pt_x p + 1)%Z (pt_y p - 1)%Z (pt_z p)
  else
    p.

Theorem transferUnitYtoX_preserves_sum :
  forall p : CoreAffectPoint,
    CoreAffectPoint_displacementSum (transferUnitYtoX p) = CoreAffectPoint_displacementSum p.
Proof.
  intros [x y z]. unfold transferUnitYtoX, CoreAffectPoint_displacementSum; simpl.
  destruct (Z.leb_spec0 0 x); destruct (Z.ltb_spec0 0 y); simpl; lia.
Qed.

Record AffectiveMatrixState : Type := mkAffectiveMatrixState {
  ams_core            : CoreAffectState;
  ams_expectationPole : LivedExpectationPole;
  ams_controlPole     : LivedControlPole;
  ams_energyRegime    : EnergyRegime;
  ams_valence         : HedonicPolarity;
  ams_activation      : PhenomenologicalActivation;
  ams_antagonist      : CoreAffectState
}.

Record PhenomenologicalMapping : Type := mkPhenomenologicalMapping {
  pm_expectationFn : Z -> LivedExpectationPole;
  pm_controlFn     : Z -> LivedControlPole;
  pm_valenceFn     : Z -> Z -> HedonicPolarity;
  pm_activationFn  : CoreAffectPoint -> PhenomenologicalActivation
}.

Definition canonicalMapping : PhenomenologicalMapping := {|
  pm_expectationFn := transduceExpectation;
  pm_controlFn     := transduceControl;
  pm_valenceFn     := computeValence;
  pm_activationFn  := computeActivation
|}.

Definition evaluateMatrix
    (cs : CoreAffectState)
    (mapping : PhenomenologicalMapping) : AffectiveMatrixState :=
  let p := cas_point cs in
  {|
    ams_core            := cs;
    ams_expectationPole := pm_expectationFn mapping (pt_x p);
    ams_controlPole     := pm_controlFn mapping (pt_y p);
    ams_energyRegime    := computeEnergyRegime (pt_x p) (pt_y p);
    ams_valence         := pm_valenceFn mapping (pt_x p) (pt_y p);
    ams_activation      := pm_activationFn mapping p;
    ams_antagonist      := {|
      cas_point := antagonistPoint p;
      cas_valid := antagonistPoint_preserves_validity p (cas_valid cs)
    |}
  |}.

Definition defaultAffectiveMatrixState : AffectiveMatrixState :=
  evaluateMatrix defaultCoreAffectState canonicalMapping.

Theorem evaluateMatrix_core_antagonist_independent :
  forall (cs : CoreAffectState) (m1 m2 : PhenomenologicalMapping),
    ams_core (evaluateMatrix cs m1) = ams_core (evaluateMatrix cs m2) /\
    ams_energyRegime (evaluateMatrix cs m1) = ams_energyRegime (evaluateMatrix cs m2) /\
    ams_antagonist (evaluateMatrix cs m1) = ams_antagonist (evaluateMatrix cs m2).
Proof.
  intros cs m1 m2. repeat split; reflexivity.
Qed.

Theorem mapping_independent_antagonist_invariants :
  forall (cs : CoreAffectState) (mapping : PhenomenologicalMapping),
    isValidCoreAffect (cas_point (ams_antagonist (evaluateMatrix cs mapping))) /\
    cas_point (ams_antagonist (evaluateMatrix (ams_antagonist (evaluateMatrix cs mapping)) mapping)) =
      cas_point cs /\
    (pt_x (cas_point cs) <> 0%Z -> pt_y (cas_point cs) <> 0%Z ->
      cas_point (ams_antagonist (evaluateMatrix cs mapping)) =
      mkPoint (- Z.sgn (pt_x (cas_point cs)) * Z.of_nat (Z.abs_nat (pt_y (cas_point cs))))%Z
              (- Z.sgn (pt_y (cas_point cs)) * Z.of_nat (Z.abs_nat (pt_x (cas_point cs))))%Z
              (pt_z (cas_point cs))) /\
    ams_antagonist (evaluateMatrix cs mapping) =
      ams_antagonist (evaluateMatrix cs canonicalMapping).
Proof.
  intros cs mapping.
  repeat split.
  - apply antagonistPoint_preserves_validity. exact (cas_valid cs).
  - apply antagonistPoint_involutive.
  - intros Hx Hy. apply antagonistPoint_unified; assumption.
Qed.
