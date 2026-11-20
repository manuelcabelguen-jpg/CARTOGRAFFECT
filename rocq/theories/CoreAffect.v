(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*)

From Stdlib Require Import Bool Arith PeanoNat ZArith Lia List Eqdep_dec.
Require Import CartograffectRocq.PredictiveEngine.

Open Scope bool_scope.
Open Scope nat_scope.

(** * Module CoreAffect — Validation Rocq 9.1.0 *)

(** ** 1. Coordonnées spatiales, Loi des couronnes et Opérateurs centraux *)

Record CoreAffectPoint : Type := mkPoint {
  pt_x : Z;
  pt_y : Z;
  pt_z : nat
}.

Definition defaultCoreAffectPoint : CoreAffectPoint := mkPoint 0%Z 0%Z 0.

Definition CoreAffectPoint_eqb (p1 p2 : CoreAffectPoint) : bool :=
  (pt_x p1 =? pt_x p2)%Z && (pt_y p1 =? pt_y p2)%Z && Nat.eqb (pt_z p1) (pt_z p2).

Lemma CoreAffectPoint_eqb_eq :
  forall p1 p2 : CoreAffectPoint, CoreAffectPoint_eqb p1 p2 = true <-> p1 = p2.
Proof.
  intros [x1 y1 z1] [x2 y2 z2].
  unfold CoreAffectPoint_eqb; simpl.
  rewrite !andb_true_iff, !Z.eqb_eq, Nat.eqb_eq.
  split.
  - intros [[Hx Hy] Hz]; subst; reflexivity.
  - intro H; inversion H; repeat split; reflexivity.
Qed.

Lemma CoreAffectPoint_eq_dec : forall p1 p2 : CoreAffectPoint, {p1 = p2} + {p1 <> p2}.
Proof.
  intros [x1 y1 z1] [x2 y2 z2].
  destruct (Z.eq_dec x1 x2); destruct (Z.eq_dec y1 y2); destruct (Nat.eq_dec z1 z2);
    try (left; subst; reflexivity);
    right; intro H; inversion H; contradiction.
Defined.

Definition CoreAffectPoint_displacementSum (p : CoreAffectPoint) : nat :=
  Z.abs_nat (pt_x p) + Z.abs_nat (pt_y p).

Definition crownRadius (z : nat) : nat :=
  match z with
  | 0          => 0
  | 1          => 0
  | S (S d)    => 2 * d + 2
  end.

Theorem crownRadius_eq_formula :
  forall z : nat, z >= 2 -> crownRadius z = 2 * z - 2.
Proof.
  intros [| [| d]] H; simpl; lia.
Qed.

Inductive CentralOperator : Type :=
  | COp_pointDeVeille : CentralOperator
  | COp_surprise      : CentralOperator
  | COp_anticipation  : CentralOperator
  | COp_emoi          : CentralOperator
  | COp_reserve       : CentralOperator
  | COp_recul         : CentralOperator
  | COp_saisissement  : CentralOperator
  | COp_suspension    : CentralOperator.

Definition CentralOperator_toPoint (op : CentralOperator) : CoreAffectPoint :=
  match op with
  | COp_pointDeVeille => mkPoint 0%Z 0%Z 0
  | COp_surprise      => mkPoint 0%Z 0%Z 1
  | COp_anticipation  => mkPoint 0%Z 0%Z 2
  | COp_emoi          => mkPoint 0%Z 0%Z 3
  | COp_reserve       => mkPoint 0%Z 0%Z 4
  | COp_recul         => mkPoint 0%Z 0%Z 5
  | COp_saisissement  => mkPoint 0%Z 0%Z 6
  | COp_suspension    => mkPoint 0%Z 0%Z 7
  end.

(** ** 2. Typologie géométrique, Secteurs d'orientation et État valide du Noyau affectif *)

Inductive GeometryType : Type :=
  | GT_central  : GeometryType
  | GT_axial    : GeometryType
  | GT_diagonal : GeometryType
  | GT_lateral  : GeometryType.

Definition GeometryType_eqb (a b : GeometryType) : bool :=
  match a, b with
  | GT_central, GT_central   => true
  | GT_axial, GT_axial       => true
  | GT_diagonal, GT_diagonal => true
  | GT_lateral, GT_lateral   => true
  | _, _                     => false
  end.

Inductive OrientationSector : Type :=
  | Sec_joie      : OrientationSector
  | Sec_tristesse : OrientationSector
  | Sec_peur      : OrientationSector
  | Sec_courage   : OrientationSector.

Definition CoreAffectPoint_dominantSector (p : CoreAffectPoint) : option OrientationSector :=
  if Nat.ltb (Z.abs_nat (pt_x p)) (Z.abs_nat (pt_y p)) then
    if Z.ltb 0%Z (pt_y p) then Some Sec_joie else Some Sec_tristesse
  else if Nat.ltb (Z.abs_nat (pt_y p)) (Z.abs_nat (pt_x p)) then
    if Z.ltb (pt_x p) 0%Z then Some Sec_peur else Some Sec_courage
  else
    None.

Definition CoreAffectPoint_isCentral (p : CoreAffectPoint) : Prop :=
  pt_x p = 0%Z /\ pt_y p = 0%Z.

Definition CoreAffectPoint_isOnCrown (p : CoreAffectPoint) : Prop :=
  pt_z p >= 2 /\ CoreAffectPoint_displacementSum p = crownRadius (pt_z p).

Definition isValidCoreAffect (p : CoreAffectPoint) : Prop :=
  CoreAffectPoint_isCentral p \/ CoreAffectPoint_isOnCrown p.

Definition CoreAffectPoint_classifyGeometry (p : CoreAffectPoint) : GeometryType :=
  if (pt_x p =? 0)%Z && (pt_y p =? 0)%Z then
    GT_central
  else if (pt_x p =? 0)%Z || (pt_y p =? 0)%Z then
    GT_axial
  else if Nat.eqb (Z.abs_nat (pt_x p)) (Z.abs_nat (pt_y p)) then
    GT_diagonal
  else
    GT_lateral.

Record CoreAffectState : Type := mkCoreAffectState {
  cas_point : CoreAffectPoint;
  cas_valid : isValidCoreAffect cas_point
}.

Definition defaultCoreAffectState : CoreAffectState := {|
  cas_point := mkPoint 0%Z 0%Z 0;
  cas_valid := or_introl (conj eq_refl eq_refl)
|}.

Definition CentralOperator_toCoreAffectState (op : CentralOperator) : CoreAffectState.
Proof.
  refine (mkCoreAffectState (CentralOperator_toPoint op) _).
  destruct op; left; split; reflexivity.
Defined.

Lemma isCentral_not_isOnCrown :
  forall p : CoreAffectPoint,
    CoreAffectPoint_isCentral p -> CoreAffectPoint_isOnCrown p -> False.
Proof.
  intros [x y z] [Hx Hy] [Hz Hsum].
  unfold CoreAffectPoint_displacementSum in Hsum; simpl in *.
  subst x y. simpl in Hsum.
  destruct z as [| [| d]]; simpl in *; lia.
Qed.

Lemma isValidCoreAffect_pi :
  forall (p : CoreAffectPoint) (h1 h2 : isValidCoreAffect p), h1 = h2.
Proof.
  intros p [hc1 | ho1] [hc2 | ho2].
  - destruct hc1 as [hx1 hy1], hc2 as [hx2 hy2].
    f_equal. f_equal.
    + apply (UIP_dec Z.eq_dec).
    + apply (UIP_dec Z.eq_dec).
  - exfalso. exact (isCentral_not_isOnCrown p hc1 ho2).
  - exfalso. exact (isCentral_not_isOnCrown p hc2 ho1).
  - destruct ho1 as [hz1 hs1], ho2 as [hz2 hs2].
    f_equal. f_equal.
    + apply Peano_dec.le_unique.
    + apply (UIP_dec Nat.eq_dec).
Qed.

Lemma CoreAffectState_eq :
  forall s1 s2 : CoreAffectState, cas_point s1 = cas_point s2 -> s1 = s2.
Proof.
  intros [p1 h1] [p2 h2] Hp.
  simpl in Hp. subst p2.
  f_equal. apply isValidCoreAffect_pi.
Qed.

(** ** 3. Opérateur de projection : Couplage du PredictiveEngine vers CoreAffect *)

Definition signedAmplitude (pol : Polarity) (amp : nat) : Z :=
  match pol with
  | Pol_neg  => (- (Z.of_nat amp))%Z
  | Pol_zero => 0%Z
  | Pol_pos  => Z.of_nat amp
  end.

Lemma natAbs_neg_ofNat : forall n : nat, Z.abs_nat (- Z.of_nat n) = n.
Proof. intro n; lia. Qed.

Lemma natAbs_pos_ofNat : forall n : nat, Z.abs_nat (Z.of_nat n) = n.
Proof. intro n; lia. Qed.

Definition deployCouplingAtDepth (c : EngineCoupling) (d : nat) : CoreAffectPoint :=
  let z := d + 2 in
  let r := 2 * d + 2 in
  let k := d + 1 in
  match ec_attente c, ec_controle c with
  | Pol_zero, Pol_zero => mkPoint 0%Z 0%Z 0
  | Pol_pos,  Pol_zero => mkPoint (signedAmplitude Pol_pos r) 0%Z z
  | Pol_neg,  Pol_zero => mkPoint (signedAmplitude Pol_neg r) 0%Z z
  | Pol_zero, Pol_pos  => mkPoint 0%Z (signedAmplitude Pol_pos r) z
  | Pol_zero, Pol_neg  => mkPoint 0%Z (signedAmplitude Pol_neg r) z
  | Pol_pos,  Pol_pos  => mkPoint (signedAmplitude Pol_pos k) (signedAmplitude Pol_pos k) z
  | Pol_pos,  Pol_neg  => mkPoint (signedAmplitude Pol_pos k) (signedAmplitude Pol_neg k) z
  | Pol_neg,  Pol_pos  => mkPoint (signedAmplitude Pol_neg k) (signedAmplitude Pol_pos k) z
  | Pol_neg,  Pol_neg  => mkPoint (signedAmplitude Pol_neg k) (signedAmplitude Pol_neg k) z
  end.

Definition clampNat (lo hi v : nat) : nat :=
  if Nat.ltb v lo then lo
  else if Nat.ltb hi v then hi
  else v.

Lemma clampNat_bounds :
  forall lo hi v : nat, lo <= hi -> lo <= clampNat lo hi v /\ clampNat lo hi v <= hi.
Proof.
  intros lo hi v H.
  unfold clampNat.
  destruct (Nat.ltb_spec0 v lo); [lia |].
  destruct (Nat.ltb_spec0 hi v); lia.
Qed.

Definition apportionRay (d piA piC : nat) : nat * nat :=
  let r := 2 * d + 2 in
  if Nat.eqb piA piC then
    (d + 1, d + 1)
  else if Nat.ltb piA piC then
    let total := piA + piC in
    let raw := (2 * r * piA + total) / (2 * total) in
    let ax := clampNat 1 (d + 1) raw in
    (ax, r - ax)
  else
    let total := piA + piC in
    let raw := (2 * r * piC + total) / (2 * total) in
    let ay := clampNat 1 (d + 1) raw in
    (r - ay, ay).

Theorem apportionRay_bounds :
  forall d piA piC : nat,
    fst (apportionRay d piA piC) >= 1 /\
    snd (apportionRay d piA piC) >= 1 /\
    fst (apportionRay d piA piC) + snd (apportionRay d piA piC) = 2 * d + 2.
Proof.
  intros d piA piC.
  unfold apportionRay.
  destruct (Nat.eqb_spec piA piC); simpl; [lia |].
  destruct (Nat.ltb_spec0 piA piC);
    cbv zeta; simpl;
    match goal with
    | |- context [clampNat 1 (d + 1) ?v] =>
      pose proof (clampNat_bounds 1 (d + 1) v ltac:(lia)) as Hcb
    end; lia.
Qed.

Theorem apportionRay_swap :
  forall d piA piC : nat,
    apportionRay d piC piA = (snd (apportionRay d piA piC), fst (apportionRay d piA piC)).
Proof.
  intros d piA piC.
  unfold apportionRay.
  destruct (Nat.eqb_spec piA piC) as [Heq | Hne].
  - subst piC. rewrite Nat.eqb_refl. reflexivity.
  - assert (Hne1 : Nat.eqb piC piA = false) by (apply Nat.eqb_neq; lia).
    rewrite Hne1. cbv zeta.
    destruct (Nat.ltb_spec0 piA piC); destruct (Nat.ltb_spec0 piC piA); try lia.
    + simpl. rewrite Nat.add_comm with (n := piC) (m := piA). reflexivity.
    + simpl. rewrite Nat.add_comm with (n := piC) (m := piA). reflexivity.
Qed.

Theorem apportionRay_symm :
  forall d k : nat, apportionRay d k k = (d + 1, d + 1).
Proof.
  intros d k. unfold apportionRay. rewrite Nat.eqb_refl. reflexivity.
Qed.

Theorem apportionRay_z2 :
  forall piA piC : nat, apportionRay 0 piA piC = (1, 1).
Proof.
  intros piA piC.
  pose proof (apportionRay_bounds 0 piA piC) as Hb.
  destruct (apportionRay 0 piA piC) as [ax ay]; simpl in Hb.
  f_equal; lia.
Qed.

Theorem apportionRay_exact :
  forall d ax ay : nat,
    ax >= 1 -> ay >= 1 -> ax + ay = 2 * d + 2 ->
    apportionRay d ax ay = (ax, ay).
Proof.
  intros d ax ay Hx Hy Hsum.
  unfold apportionRay. cbv zeta.
  destruct (Nat.eqb_spec ax ay) as [Heq | Hne].
  - f_equal; lia.
  - destruct (Nat.ltb_spec0 ax ay).
    + assert (Hdiv : (2 * (2 * d + 2) * ax + (ax + ay)) / (2 * (ax + ay)) = ax).
      { rewrite Hsum.
        symmetry. apply Nat.div_unique with (r := 2 * d + 2); lia. }
      rewrite Hdiv.
      assert (Hclamp : clampNat 1 (d + 1) ax = ax).
      { unfold clampNat.
        destruct (Nat.ltb_spec0 ax 1); [lia |].
        destruct (Nat.ltb_spec0 (d + 1) ax); lia. }
      rewrite Hclamp. f_equal; lia.
    + assert (Hdiv : (2 * (2 * d + 2) * ay + (ax + ay)) / (2 * (ax + ay)) = ay).
      { rewrite Hsum.
        symmetry. apply Nat.div_unique with (r := 2 * d + 2); lia. }
      rewrite Hdiv.
      assert (Hclamp : clampNat 1 (d + 1) ay = ay).
      { unfold clampNat.
        destruct (Nat.ltb_spec0 ay 1); [lia |].
        destruct (Nat.ltb_spec0 (d + 1) ay); lia. }
      rewrite Hclamp. f_equal; lia.
Qed.

Definition deployCouplingWithPrecision (c : EngineCoupling) (d piA piC : nat) : CoreAffectPoint :=
  let z := d + 2 in
  let r := 2 * d + 2 in
  match ec_attente c, ec_controle c with
  | Pol_zero, Pol_zero => mkPoint 0%Z 0%Z 0
  | Pol_pos,  Pol_zero => mkPoint (signedAmplitude Pol_pos r) 0%Z z
  | Pol_neg,  Pol_zero => mkPoint (signedAmplitude Pol_neg r) 0%Z z
  | Pol_zero, Pol_pos  => mkPoint 0%Z (signedAmplitude Pol_pos r) z
  | Pol_zero, Pol_neg  => mkPoint 0%Z (signedAmplitude Pol_neg r) z
  | Pol_pos,  Pol_pos  =>
    let p := apportionRay d piA piC in
    mkPoint (signedAmplitude Pol_pos (fst p)) (signedAmplitude Pol_pos (snd p)) z
  | Pol_pos,  Pol_neg  =>
    let p := apportionRay d piA piC in
    mkPoint (signedAmplitude Pol_pos (fst p)) (signedAmplitude Pol_neg (snd p)) z
  | Pol_neg,  Pol_pos  =>
    let p := apportionRay d piA piC in
    mkPoint (signedAmplitude Pol_neg (fst p)) (signedAmplitude Pol_pos (snd p)) z
  | Pol_neg,  Pol_neg  =>
    let p := apportionRay d piA piC in
    mkPoint (signedAmplitude Pol_neg (fst p)) (signedAmplitude Pol_neg (snd p)) z
  end.

Theorem deployCouplingWithPrecision_symm_eq :
  forall (c : EngineCoupling) (d k : nat),
    deployCouplingWithPrecision c d k k = deployCouplingAtDepth c d.
Proof.
  intros [a ctrl] d k.
  destruct a; destruct ctrl; unfold deployCouplingWithPrecision, deployCouplingAtDepth;
    simpl; try rewrite apportionRay_symm; reflexivity.
Qed.

Definition projectToCoreAffect (s : PredictiveEngineState) : CoreAffectPoint :=
  let c := PredictiveEngineState_currentCoupling s in
  if negb (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s)) ||
     EngineCoupling_isGlobalNeutrality c then
    if si_descendingSuspension (pes_subjective s) then
      mkPoint 0%Z 0%Z (ai_persistenceDepth (pes_attentional s) + 2)
    else
      mkPoint 0%Z 0%Z 0
  else if negb (AttentionalInterface_isEngaged (pes_attentional s)) then
    if si_descendingSuspension (pes_subjective s) then
      mkPoint 0%Z 0%Z (ai_persistenceDepth (pes_attentional s) + 2)
    else
      mkPoint 0%Z 0%Z 1
  else
    deployCouplingWithPrecision c
      (ai_persistenceDepth (pes_attentional s))
      (ai_precisionA (pes_attentional s))
      (ai_precisionC (pes_attentional s)).

(** ** 4. Lemmes de transition et Invariants géométriques (Couplage Moteur -> Noyau) *)

Theorem deployCouplingAtDepth_valid :
  forall (c : EngineCoupling) (d : nat),
    isValidCoreAffect (deployCouplingAtDepth c d).
Proof.
  intros [a ctrl] d.
  destruct a; destruct ctrl; simpl;
    [| | | | left; split; reflexivity | | | |];
    right; unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum, signedAmplitude;
    simpl; (split; [lia | replace (d + 2) with (S (S d)) by lia; simpl; rewrite ?natAbs_neg_ofNat, ?natAbs_pos_ofNat; lia]).
Qed.

Theorem deployCouplingWithPrecision_valid :
  forall (c : EngineCoupling) (d piA piC : nat),
    isValidCoreAffect (deployCouplingWithPrecision c d piA piC).
Proof.
  intros [a ctrl] d piA piC.
  pose proof (apportionRay_bounds d piA piC) as Hb.
  destruct a; destruct ctrl; simpl;
    [| | | | left; split; reflexivity | | | |];
    right; unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum, signedAmplitude;
    simpl; (split; [lia | replace (d + 2) with (S (S d)) by lia; simpl; rewrite ?natAbs_neg_ofNat, ?natAbs_pos_ofNat; lia]).
Qed.

Theorem engine_induces_valid_core_affect :
  forall s : PredictiveEngineState, isValidCoreAffect (projectToCoreAffect s).
Proof.
  intro s. unfold projectToCoreAffect.
  destruct (negb (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s)) ||
            EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s)).
  - destruct (si_descendingSuspension (pes_subjective s)); left; split; reflexivity.
  - destruct (negb (AttentionalInterface_isEngaged (pes_attentional s))).
    + destruct (si_descendingSuspension (pes_subjective s)); left; split; reflexivity.
    + apply deployCouplingWithPrecision_valid.
Qed.

Theorem neutral_coupling_without_suspension_yields_veille :
  forall s : PredictiveEngineState,
    EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s) = true ->
    si_descendingSuspension (pes_subjective s) = false ->
    projectToCoreAffect s = mkPoint 0%Z 0%Z 0.
Proof.
  intros s Hneut Hnosusp.
  unfold projectToCoreAffect.
  rewrite Hneut, orb_true_r, Hnosusp. reflexivity.
Qed.

Theorem neutral_or_subthreshold_with_suspension_yields_central :
  forall s : PredictiveEngineState,
    (negb (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s)) ||
     EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s)) = true ->
    si_descendingSuspension (pes_subjective s) = true ->
    projectToCoreAffect s = mkPoint 0%Z 0%Z (ai_persistenceDepth (pes_attentional s) + 2).
Proof.
  intros s Hcond Hsusp.
  unfold projectToCoreAffect.
  rewrite Hcond, Hsusp. reflexivity.
Qed.

Theorem descending_suspension_yields_central_operator :
  forall s : PredictiveEngineState,
    si_descendingSuspension (pes_subjective s) = true ->
    ((negb (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s)) ||
      EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s)) = true \/
     AttentionalInterface_isEngaged (pes_attentional s) = false) ->
    projectToCoreAffect s = mkPoint 0%Z 0%Z (ai_persistenceDepth (pes_attentional s) + 2).
Proof.
  intros s Hsusp [H1 | H2]; unfold projectToCoreAffect.
  - rewrite H1, Hsusp. reflexivity.
  - destruct (negb (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s)) ||
              EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s)).
    + rewrite Hsusp. reflexivity.
    + rewrite H2; simpl. rewrite Hsusp. reflexivity.
Qed.

Theorem central_z_ge2_requires_descending_suspension :
  forall (s : PredictiveEngineState) (d : nat),
    projectToCoreAffect s = mkPoint 0%Z 0%Z (d + 2) ->
    si_descendingSuspension (pes_subjective s) = true /\
    ai_persistenceDepth (pes_attentional s) = d /\
    (negb (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s)) ||
     EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s) ||
     negb (AttentionalInterface_isEngaged (pes_attentional s))) = true.
Proof.
  intros s d H.
  unfold projectToCoreAffect in H.
  destruct (negb (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s)) ||
            EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s)) eqn:H1.
  - destruct (si_descendingSuspension (pes_subjective s)) eqn:H3.
    + inversion H as [Hz]. repeat split; try lia; reflexivity.
    + inversion H as [Hz]. lia.
  - destruct (AttentionalInterface_isEngaged (pes_attentional s)) eqn:H2; simpl in H.
    + exfalso.
      rewrite orb_false_iff in H1. destruct H1 as [_ Hnon].
      pose proof (apportionRay_bounds (ai_persistenceDepth (pes_attentional s))
                    (ai_precisionA (pes_attentional s))
                    (ai_precisionC (pes_attentional s))) as [Hb1 [Hb2 _]].
      unfold deployCouplingWithPrecision, signedAmplitude,
        PredictiveEngineState_currentCoupling, EngineCoupling_isGlobalNeutrality in H, Hnon.
      cbv zeta in H.
      destruct (si_attenteGradient (pes_subjective s));
      destruct (pi_controleGradient (pes_perceptive s));
        simpl in H, Hnon; try discriminate; inversion H; lia.
    + destruct (si_descendingSuspension (pes_subjective s)) eqn:H3.
      * inversion H. repeat split; try lia; rewrite orb_true_r; reflexivity.
      * inversion H; lia.
Qed.

Definition evaluateCoreAffect (s : PredictiveEngineState) : CoreAffectState :=
  mkCoreAffectState (projectToCoreAffect s) (engine_induces_valid_core_affect s).

Theorem z2_budget_conservation :
  forall c : EngineCoupling,
    EngineCoupling_isGlobalNeutrality c = false ->
    CoreAffectPoint_displacementSum (deployCouplingAtDepth c 0) = 2.
Proof.
  intros [[] []] H; try discriminate; reflexivity.
Qed.

Theorem single_engaged_yields_axial_z2 :
  forall c : EngineCoupling,
    EngineCoupling_isSingleEngaged c = true ->
    CoreAffectPoint_classifyGeometry (deployCouplingAtDepth c 0) = GT_axial.
Proof.
  intros [[] []] H; try discriminate; reflexivity.
Qed.

Theorem dual_engaged_yields_diagonal_z2 :
  forall c : EngineCoupling,
    EngineCoupling_isDualEngaged c = true ->
    CoreAffectPoint_classifyGeometry (deployCouplingAtDepth c 0) = GT_diagonal.
Proof.
  intros [[] []] H; try discriminate; reflexivity.
Qed.

Definition triggerSecondaryGradient (c : EngineCoupling) (newPol : Polarity) : EngineCoupling :=
  match ec_attente c, ec_controle c with
  | Pol_pos,  Pol_zero => mkEngineCoupling Pol_pos  newPol
  | Pol_neg,  Pol_zero => mkEngineCoupling Pol_neg  newPol
  | Pol_zero, Pol_pos  => mkEngineCoupling newPol   Pol_pos
  | Pol_zero, Pol_neg  => mkEngineCoupling newPol   Pol_neg
  | a,        ctrl     => mkEngineCoupling a        ctrl
  end.

Theorem axial_to_diagonal_reallocation :
  forall (c : EngineCoupling) (newPol : Polarity),
    EngineCoupling_isSingleEngaged c = true ->
    Polarity_isEngaged newPol = true ->
    let c' := triggerSecondaryGradient c newPol in
    CoreAffectPoint_classifyGeometry (deployCouplingAtDepth c' 0) = GT_diagonal /\
    CoreAffectPoint_displacementSum (deployCouplingAtDepth c' 0) = 2.
Proof.
  intros [[] []] [] Hax Hsal; try discriminate; split; reflexivity.
Qed.

Theorem deployCouplingWithPrecision_budget_conservation :
  forall (c : EngineCoupling) (d piA piC : nat),
    EngineCoupling_isGlobalNeutrality c = false ->
    CoreAffectPoint_displacementSum (deployCouplingWithPrecision c d piA piC) = 2 * d + 2.
Proof.
  intros [a ctrl] d piA piC Hnon.
  pose proof (apportionRay_bounds d piA piC) as Hb.
  destruct a; destruct ctrl;
    try (simpl in Hnon; discriminate);
    unfold deployCouplingWithPrecision, CoreAffectPoint_displacementSum, signedAmplitude;
    simpl; rewrite ?natAbs_neg_ofNat, ?natAbs_pos_ofNat; lia.
Qed.

Theorem dual_engaged_yields_diagonal_z2_precision :
  forall (c : EngineCoupling) (piA piC : nat),
    EngineCoupling_isDualEngaged c = true ->
    CoreAffectPoint_classifyGeometry (deployCouplingWithPrecision c 0 piA piC) = GT_diagonal.
Proof.
  intros [a ctrl] piA piC H.
  destruct a; destruct ctrl; try (simpl in H; discriminate);
    unfold deployCouplingWithPrecision, CoreAffectPoint_classifyGeometry, signedAmplitude;
    simpl; rewrite apportionRay_z2; reflexivity.
Qed.

Lemma deployCouplingAtDepth_not_lateral :
  forall (c : EngineCoupling) (d : nat),
    CoreAffectPoint_classifyGeometry (deployCouplingAtDepth c d) <> GT_lateral.
Proof.
  intros [a ctrl] d.
  destruct a; destruct ctrl;
    unfold deployCouplingAtDepth, CoreAffectPoint_classifyGeometry, signedAmplitude; simpl;
    repeat match goal with
    | |- context [ (Z.of_nat ?n =? 0)%Z ] =>
      destruct (Z.eqb_spec (Z.of_nat n) 0); [lia |]
    | |- context [ (- Z.of_nat ?n =? 0)%Z ] =>
      destruct (Z.eqb_spec (- Z.of_nat n) 0); [lia |]
    | |- context [ Nat.eqb (Z.abs_nat ?z) (Z.abs_nat ?w) ] =>
      destruct (Nat.eqb_spec (Z.abs_nat z) (Z.abs_nat w)); [| lia]
    end;
    simpl; discriminate.
Qed.

Theorem symmetric_precision_never_lateral :
  forall s : PredictiveEngineState,
    ai_precisionA (pes_attentional s) = ai_precisionC (pes_attentional s) ->
    CoreAffectPoint_classifyGeometry (projectToCoreAffect s) <> GT_lateral.
Proof.
  intros s Hsym.
  unfold projectToCoreAffect.
  destruct (negb (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s)) ||
            EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s)).
  - destruct (si_descendingSuspension (pes_subjective s)); simpl; discriminate.
  - destruct (negb (AttentionalInterface_isEngaged (pes_attentional s))).
    + destruct (si_descendingSuspension (pes_subjective s)); simpl; discriminate.
    + rewrite Hsym, deployCouplingWithPrecision_symm_eq.
      apply deployCouplingAtDepth_not_lateral.
Qed.

Definition witnessEngineForPoint (p : CoreAffectPoint) : PredictiveEngineState :=
  let polOf (v : Z) : Polarity :=
    if Z.ltb 0%Z v then Pol_pos else if Z.ltb v 0%Z then Pol_neg else Pol_zero in
  if (pt_x p =? 0)%Z && (pt_y p =? 0)%Z then
    match pt_z p with
    | 0 => defaultPredictiveEngineState
    | 1 => {|
        pes_discrepancy := {|
          sd_magnitude := 2; sd_sensoryThreshold := 1;
          sd_resorptionThreshold := 1; sd_hysteresis := le_n 1
        |};
        pes_perceptive  := {| pi_controleGradient := Pol_zero |};
        pes_subjective  := {| si_attenteGradient := Pol_pos; si_descendingSuspension := false |};
        pes_attentional := {|
          ai_allocatedPrecision := 0; ai_engagementThreshold := 1;
          ai_persistenceDepth := 0; ai_precisionA := 1; ai_precisionC := 1
        |}
      |}
    | S (S d) => {|
        pes_discrepancy := {|
          sd_magnitude := 2; sd_sensoryThreshold := 1;
          sd_resorptionThreshold := 1; sd_hysteresis := le_n 1
        |};
        pes_perceptive  := {| pi_controleGradient := Pol_zero |};
        pes_subjective  := {| si_attenteGradient := Pol_pos; si_descendingSuspension := true |};
        pes_attentional := {|
          ai_allocatedPrecision := 0; ai_engagementThreshold := 1;
          ai_persistenceDepth := d; ai_precisionA := 1; ai_precisionC := 1
        |}
      |}
    end
  else
    let ax := Z.abs_nat (pt_x p) in
    let ay := Z.abs_nat (pt_y p) in
    let '(piA, piC) := if Nat.eqb ax 0 || Nat.eqb ay 0 then (1, 1) else (ax, ay) in
    {|
      pes_discrepancy := {|
        sd_magnitude := 2; sd_sensoryThreshold := 1;
        sd_resorptionThreshold := 1; sd_hysteresis := le_n 1
      |};
      pes_perceptive  := {| pi_controleGradient := polOf (pt_y p) |};
      pes_subjective  := {| si_attenteGradient := polOf (pt_x p); si_descendingSuspension := true |};
      pes_attentional := {|
        ai_allocatedPrecision := 1; ai_engagementThreshold := 1;
        ai_persistenceDepth := pt_z p - 2; ai_precisionA := piA; ai_precisionC := piC
      |}
    |}.

Lemma project_engaged_crown :
  forall (a ctrl : Polarity) (d piA piC : nat),
    EngineCoupling_isGlobalNeutrality (mkEngineCoupling a ctrl) = false ->
    projectToCoreAffect {|
      pes_discrepancy := {|
        sd_magnitude := 2; sd_sensoryThreshold := 1;
        sd_resorptionThreshold := 1; sd_hysteresis := le_n 1
      |};
      pes_perceptive  := {| pi_controleGradient := ctrl |};
      pes_subjective  := {| si_attenteGradient := a; si_descendingSuspension := true |};
      pes_attentional := {|
        ai_allocatedPrecision := 1; ai_engagementThreshold := 1;
        ai_persistenceDepth := d; ai_precisionA := piA; ai_precisionC := piC
      |}
    |} = deployCouplingWithPrecision (mkEngineCoupling a ctrl) d piA piC.
Proof.
  intros a ctrl d piA piC Hnon.
  unfold projectToCoreAffect, PredictiveEngineState_currentCoupling,
    SalientDiscrepancy_isSensorilySalient, AttentionalInterface_isEngaged; simpl.
  rewrite Hnon. reflexivity.
Qed.

Theorem projectToCoreAffect_surjective :
  forall p : CoreAffectPoint,
    isValidCoreAffect p ->
    projectToCoreAffect (witnessEngineForPoint p) = p.
Proof.
  intros [x y z] [[Hx Hy] | [Hz Hsum]].
  - unfold CoreAffectPoint_isCentral in Hx, Hy; simpl in Hx, Hy.
    subst x y.
    destruct z as [| [| d]]; [reflexivity | reflexivity | unfold projectToCoreAffect, witnessEngineForPoint; simpl; f_equal; lia].
  - unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum in Hz, Hsum; simpl in Hz, Hsum.
    destruct z as [| [| d]]; [lia | lia |].
    simpl in Hsum.
    assert (Hxy_nz : (x =? 0)%Z && (y =? 0)%Z = false).
    { apply andb_false_iff.
      destruct (Z.eq_dec x 0); destruct (Z.eq_dec y 0);
        try (left; apply Z.eqb_neq; lia);
        try (right; apply Z.eqb_neq; lia); lia. }
    unfold witnessEngineForPoint; simpl.
    rewrite Hxy_nz.
    replace (S (S d) - 2) with d by lia.
    (destruct (Z_lt_le_dec 0 x) as [Hx_pos | Hx_le];
      [| destruct (Z.eq_dec x 0) as [Hx0 | Hx_neg]]);
    (destruct (Z_lt_le_dec 0 y) as [Hy_pos | Hy_le];
      [| destruct (Z.eq_dec y 0) as [Hy0 | Hy_neg]]).
    + (* x > 0, y > 0 *)
      assert (Hx_b : (0 <? x)%Z = true) by (apply Z.ltb_lt; lia).
      assert (Hy_b : (0 <? y)%Z = true) by (apply Z.ltb_lt; lia).
      assert (Hax : (Z.abs_nat x =? 0) = false) by (apply Nat.eqb_neq; lia).
      assert (Hay : (Z.abs_nat y =? 0) = false) by (apply Nat.eqb_neq; lia).
      rewrite Hx_b, Hy_b, Hax, Hay; simpl.
      rewrite project_engaged_crown; [| reflexivity].
      unfold deployCouplingWithPrecision; simpl.
      rewrite apportionRay_exact; [| lia | lia | lia].
      unfold signedAmplitude; simpl. f_equal; lia.
    + (* x > 0, y = 0 *)
      subst y.
      assert (Hx_b : (0 <? x)%Z = true) by (apply Z.ltb_lt; lia).
      rewrite Hx_b; simpl. rewrite orb_true_r.
      rewrite project_engaged_crown; [| reflexivity].
      unfold deployCouplingWithPrecision, signedAmplitude; simpl.
      f_equal; lia.
    + (* x > 0, y < 0 *)
      assert (Hx_b : (0 <? x)%Z = true) by (apply Z.ltb_lt; lia).
      assert (Hy_b1 : (0 <? y)%Z = false) by (apply Z.ltb_ge; lia).
      assert (Hy_b2 : (y <? 0)%Z = true) by (apply Z.ltb_lt; lia).
      assert (Hax : (Z.abs_nat x =? 0) = false) by (apply Nat.eqb_neq; lia).
      assert (Hay : (Z.abs_nat y =? 0) = false) by (apply Nat.eqb_neq; lia).
      rewrite Hx_b, Hy_b1, Hy_b2, Hax, Hay; simpl.
      rewrite project_engaged_crown; [| reflexivity].
      unfold deployCouplingWithPrecision; simpl.
      rewrite apportionRay_exact; [| lia | lia | lia].
      unfold signedAmplitude; simpl. f_equal; lia.
    + (* x = 0, y > 0 *)
      subst x.
      assert (Hy_b : (0 <? y)%Z = true) by (apply Z.ltb_lt; lia).
      rewrite Hy_b; simpl.
      rewrite project_engaged_crown; [| reflexivity].
      unfold deployCouplingWithPrecision, signedAmplitude; simpl.
      f_equal; lia.
    + (* x = 0, y = 0 *)
      subst x y. simpl in Hsum. lia.
    + (* x = 0, y < 0 *)
      subst x.
      assert (Hy_b1 : (0 <? y)%Z = false) by (apply Z.ltb_ge; lia).
      assert (Hy_b2 : (y <? 0)%Z = true) by (apply Z.ltb_lt; lia).
      rewrite Hy_b1, Hy_b2; simpl.
      rewrite project_engaged_crown; [| reflexivity].
      unfold deployCouplingWithPrecision, signedAmplitude; simpl.
      f_equal; lia.
    + (* x < 0, y > 0 *)
      assert (Hx_b1 : (0 <? x)%Z = false) by (apply Z.ltb_ge; lia).
      assert (Hx_b2 : (x <? 0)%Z = true) by (apply Z.ltb_lt; lia).
      assert (Hy_b : (0 <? y)%Z = true) by (apply Z.ltb_lt; lia).
      assert (Hax : (Z.abs_nat x =? 0) = false) by (apply Nat.eqb_neq; lia).
      assert (Hay : (Z.abs_nat y =? 0) = false) by (apply Nat.eqb_neq; lia).
      rewrite Hx_b1, Hx_b2, Hy_b, Hax, Hay; simpl.
      rewrite project_engaged_crown; [| reflexivity].
      unfold deployCouplingWithPrecision; simpl.
      rewrite apportionRay_exact; [| lia | lia | lia].
      unfold signedAmplitude; simpl. f_equal; lia.
    + (* x < 0, y = 0 *)
      subst y.
      assert (Hx_b1 : (0 <? x)%Z = false) by (apply Z.ltb_ge; lia).
      assert (Hx_b2 : (x <? 0)%Z = true) by (apply Z.ltb_lt; lia).
      rewrite Hx_b1, Hx_b2; simpl. rewrite orb_true_r.
      rewrite project_engaged_crown; [| reflexivity].
      unfold deployCouplingWithPrecision, signedAmplitude; simpl.
      f_equal; lia.
    + (* x < 0, y < 0 *)
      assert (Hx_b1 : (0 <? x)%Z = false) by (apply Z.ltb_ge; lia).
      assert (Hx_b2 : (x <? 0)%Z = true) by (apply Z.ltb_lt; lia).
      assert (Hy_b1 : (0 <? y)%Z = false) by (apply Z.ltb_ge; lia).
      assert (Hy_b2 : (y <? 0)%Z = true) by (apply Z.ltb_lt; lia).
      assert (Hax : (Z.abs_nat x =? 0) = false) by (apply Nat.eqb_neq; lia).
      assert (Hay : (Z.abs_nat y =? 0) = false) by (apply Nat.eqb_neq; lia).
      rewrite Hx_b1, Hx_b2, Hy_b1, Hy_b2, Hax, Hay; simpl.
      rewrite project_engaged_crown; [| reflexivity].
      unfold deployCouplingWithPrecision; simpl.
      rewrite apportionRay_exact; [| lia | lia | lia].
      unfold signedAmplitude; simpl. f_equal; lia.
Qed.

Lemma deployCouplingWithPrecision_nonneutral_crown :
  forall (c : EngineCoupling) (d piA piC : nat),
    EngineCoupling_isGlobalNeutrality c = false ->
    pt_z (deployCouplingWithPrecision c d piA piC) = d + 2 /\
    CoreAffectPoint_isOnCrown (deployCouplingWithPrecision c d piA piC).
Proof.
  intros [a ctrl] d piA piC Hnon.
  pose proof (apportionRay_bounds d piA piC) as Hb.
  destruct a; destruct ctrl;
    try (simpl in Hnon; discriminate);
    unfold deployCouplingWithPrecision, CoreAffectPoint_isOnCrown,
      CoreAffectPoint_displacementSum, signedAmplitude; simpl;
    (split; [reflexivity | (split; [lia | replace (d + 2) with (S (S d)) by lia; simpl; rewrite ?natAbs_neg_ofNat, ?natAbs_pos_ofNat; lia])]).
Qed.

Theorem engineStep_canonical_trajectory :
  forall s0 : PredictiveEngineState,
    SalientDiscrepancy_isSensorilySalient (pes_discrepancy s0) = true ->
    EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s0) = true ->
    si_descendingSuspension (pes_subjective s0) = false ->
    AttentionalInterface_isEngaged (pes_attentional s0) = false ->
    ai_persistenceDepth (pes_attentional s0) = 0 ->
    projectToCoreAffect s0 = mkPoint 0%Z 0%Z 0 /\
    projectToCoreAffect (engineStep s0) = mkPoint 0%Z 0%Z 1 /\
    projectToCoreAffect (engineStep (engineStep s0)) = mkPoint 0%Z 0%Z 2 /\
    projectToCoreAffect (engineStep (engineStep (engineStep s0))) = mkPoint 0%Z 2%Z 2.
Proof.
  intros s0 Hsal Hneut Hnosusp Huneng Hdepth.
  assert (Hatt0 : si_attenteGradient (pes_subjective s0) = Pol_zero).
  { unfold PredictiveEngineState_currentCoupling, EngineCoupling_isGlobalNeutrality in Hneut.
    simpl in Hneut. destruct (si_attenteGradient (pes_subjective s0)); simpl in Hneut;
      try reflexivity; discriminate. }
  set (s1 := {|
    pes_discrepancy := pes_discrepancy s0;
    pes_perceptive  := {| pi_controleGradient := Pol_pos |};
    pes_subjective  := pes_subjective s0;
    pes_attentional := pes_attentional s0
  |}).
  assert (Hs1 : engineStep s0 = s1) by (apply engineStep_of_salient_neutral; assumption).
  assert (Hs1_neut : EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s1) = false).
  { unfold s1, PredictiveEngineState_currentCoupling, EngineCoupling_isGlobalNeutrality; simpl.
    rewrite Hatt0; reflexivity. }
  set (s2 := {|
    pes_discrepancy := pes_discrepancy s0;
    pes_perceptive  := {| pi_controleGradient := Pol_pos |};
    pes_subjective  := {|
      si_attenteGradient      := si_attenteGradient (pes_subjective s0);
      si_descendingSuspension := true
    |};
    pes_attentional := pes_attentional s0
  |}).
  assert (Hs2 : engineStep s1 = s2).
  { apply engineStep_of_salient_nonneutral_unsuspended; assumption. }
  assert (Hs2_neut : EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s2) = false).
  { unfold s2, PredictiveEngineState_currentCoupling, EngineCoupling_isGlobalNeutrality; simpl.
    rewrite Hatt0; reflexivity. }
  set (s3 := {|
    pes_discrepancy := pes_discrepancy s0;
    pes_perceptive  := {| pi_controleGradient := Pol_pos |};
    pes_subjective  := {|
      si_attenteGradient      := si_attenteGradient (pes_subjective s0);
      si_descendingSuspension := true
    |};
    pes_attentional := {|
      ai_allocatedPrecision  := ai_engagementThreshold (pes_attentional s0);
      ai_engagementThreshold := ai_engagementThreshold (pes_attentional s0);
      ai_persistenceDepth    := ai_persistenceDepth (pes_attentional s0);
      ai_precisionA          := ai_precisionA (pes_attentional s0);
      ai_precisionC          := ai_precisionC (pes_attentional s0)
    |}
  |}).
  assert (Hs3 : engineStep s2 = s3).
  { apply engineStep_of_salient_nonneutral_suspended_unengaged; try assumption; reflexivity. }
  assert (Hs3_neut : EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s3) = false)
    by exact Hs2_neut.
  assert (Hs3_eng : AttentionalInterface_isEngaged (pes_attentional s3) = true).
  { unfold s3, AttentionalInterface_isEngaged; simpl. apply Nat.leb_refl. }
  repeat split.
  - apply neutral_coupling_without_suspension_yields_veille; assumption.
  - rewrite Hs1. unfold projectToCoreAffect.
    rewrite Hs1_neut. unfold s1; simpl.
    rewrite Hsal, Huneng, Hnosusp. reflexivity.
  - rewrite Hs1, Hs2. unfold projectToCoreAffect.
    rewrite Hs2_neut. unfold s2; simpl.
    rewrite Hsal, Huneng, Hdepth. reflexivity.
  - rewrite Hs1, Hs2, Hs3. unfold projectToCoreAffect.
    rewrite Hs3_neut, Hs3_eng. unfold s3; simpl.
    rewrite Hsal, Hatt0, Hdepth. reflexivity.
Qed.

Theorem engineStep_surprise_to_crown :
  forall s1 : PredictiveEngineState,
    SalientDiscrepancy_isSensorilySalient (pes_discrepancy s1) = true ->
    EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s1) = false ->
    si_descendingSuspension (pes_subjective s1) = false ->
    AttentionalInterface_isEngaged (pes_attentional s1) = false ->
    ai_persistenceDepth (pes_attentional s1) = 0 ->
    let p_crown := projectToCoreAffect (engineStep (engineStep s1)) in
    projectToCoreAffect s1 = mkPoint 0%Z 0%Z 1 /\
    projectToCoreAffect (engineStep s1) = mkPoint 0%Z 0%Z 2 /\
    p_crown = deployCouplingWithPrecision (PredictiveEngineState_currentCoupling s1) 0
      (ai_precisionA (pes_attentional s1)) (ai_precisionC (pes_attentional s1)) /\
    pt_z p_crown = 2 /\
    CoreAffectPoint_isOnCrown p_crown.
Proof.
  intros s1 Hsal Hnon Hnosusp Huneng Hdepth p_crown.
  set (s2 := {|
    pes_discrepancy := pes_discrepancy s1;
    pes_perceptive  := pes_perceptive s1;
    pes_subjective  := {|
      si_attenteGradient      := si_attenteGradient (pes_subjective s1);
      si_descendingSuspension := true
    |};
    pes_attentional := pes_attentional s1
  |}).
  assert (Hs2 : engineStep s1 = s2).
  { apply engineStep_of_salient_nonneutral_unsuspended; assumption. }
  assert (Hs2_neut : EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s2) = false)
    by exact Hnon.
  set (s3 := {|
    pes_discrepancy := pes_discrepancy s1;
    pes_perceptive  := pes_perceptive s1;
    pes_subjective  := {|
      si_attenteGradient      := si_attenteGradient (pes_subjective s1);
      si_descendingSuspension := true
    |};
    pes_attentional := {|
      ai_allocatedPrecision  := ai_engagementThreshold (pes_attentional s1);
      ai_engagementThreshold := ai_engagementThreshold (pes_attentional s1);
      ai_persistenceDepth    := ai_persistenceDepth (pes_attentional s1);
      ai_precisionA          := ai_precisionA (pes_attentional s1);
      ai_precisionC          := ai_precisionC (pes_attentional s1)
    |}
  |}).
  assert (Hs3 : engineStep s2 = s3).
  { apply engineStep_of_salient_nonneutral_suspended_unengaged; try assumption; reflexivity. }
  assert (Hs3_eng : AttentionalInterface_isEngaged (pes_attentional s3) = true).
  { unfold s3, AttentionalInterface_isEngaged; simpl. apply Nat.leb_refl. }
  assert (Hcrown_pt :
    p_crown = deployCouplingWithPrecision (PredictiveEngineState_currentCoupling s1) 0
      (ai_precisionA (pes_attentional s1)) (ai_precisionC (pes_attentional s1))).
  { unfold p_crown. rewrite Hs2, Hs3.
    unfold projectToCoreAffect. rewrite Hs3_eng.
    change (PredictiveEngineState_currentCoupling s3) with (PredictiveEngineState_currentCoupling s1).
    rewrite Hnon; unfold s3; simpl. rewrite Hsal, Hdepth. reflexivity. }
  pose proof (deployCouplingWithPrecision_nonneutral_crown
    (PredictiveEngineState_currentCoupling s1) 0
    (ai_precisionA (pes_attentional s1)) (ai_precisionC (pes_attentional s1)) Hnon) as [Hz Hcr].
  split; [| split; [| split; [| split]]].
  - unfold projectToCoreAffect. rewrite Hsal, Hnon, Huneng, Hnosusp. reflexivity.
  - rewrite Hs2. unfold projectToCoreAffect.
    change (PredictiveEngineState_currentCoupling s2) with (PredictiveEngineState_currentCoupling s1).
    rewrite Hnon; unfold s2; simpl. rewrite Hsal, Huneng, Hdepth. reflexivity.
  - exact Hcrown_pt.
  - rewrite Hcrown_pt. exact Hz.
  - rewrite Hcrown_pt. exact Hcr.
Qed.

(** ** 5. Loi de dissipation allostatique graduelle (Retour vers le Point de Veille) *)

Definition dissipationStep (p : CoreAffectPoint) : CoreAffectPoint :=
  if negb (pt_x p =? 0)%Z || negb (pt_y p =? 0)%Z then
    mkPoint 0%Z 0%Z (pt_z p)
  else match pt_z p with
    | 0          => mkPoint 0%Z 0%Z 0
    | 1          => mkPoint 0%Z 0%Z 0
    | 2          => mkPoint 0%Z 0%Z 0
    | S (S (S k)) => mkPoint 0%Z 0%Z (S (S k))
  end.

Theorem dissipationStep_valid :
  forall p : CoreAffectPoint, isValidCoreAffect (dissipationStep p).
Proof.
  intros [x y z]. unfold dissipationStep; simpl.
  destruct (negb (x =? 0)%Z || negb (y =? 0)%Z).
  - left; split; reflexivity.
  - destruct z as [| [| [| k]]]; left; split; reflexivity.
Qed.

Theorem anticipation_short_circuits_to_veille :
  dissipationStep (mkPoint 0%Z 0%Z 2) = mkPoint 0%Z 0%Z 0.
Proof. reflexivity. Qed.

Theorem dissipation_from_ge2_never_visits_surprise :
  forall p : CoreAffectPoint, pt_z p >= 2 -> dissipationStep p <> mkPoint 0%Z 0%Z 1.
Proof.
  intros [x y z] Hz. unfold dissipationStep; simpl in *.
  destruct (negb (x =? 0)%Z || negb (y =? 0)%Z).
  - intro H; inversion H; lia.
  - destruct z as [| [| [| k]]]; try lia; intro H; inversion H; lia.
Qed.

Theorem pointDeVeille_is_fixed_point :
  dissipationStep (mkPoint 0%Z 0%Z 0) = mkPoint 0%Z 0%Z 0.
Proof. reflexivity. Qed.

Theorem dissipationStep_fixed_iff :
  forall p : CoreAffectPoint, dissipationStep p = p <-> p = mkPoint 0%Z 0%Z 0.
Proof.
  intros [x y z]. split.
  - intro H. unfold dissipationStep in H; simpl in H.
    destruct (negb (x =? 0)%Z || negb (y =? 0)%Z) eqn:Hper.
    + inversion H; subst. simpl in Hper. discriminate.
    + rewrite orb_false_iff in Hper. destruct Hper as [Hx Hy].
      rewrite negb_false_iff, Z.eqb_eq in Hx, Hy. subst x y.
      destruct z as [| [| [| k]]]; [reflexivity | inversion H | inversion H | inversion H; lia].
  - intro H; inversion H; subst; reflexivity.
Qed.

Definition dissipationPotential (p : CoreAffectPoint) : nat :=
  2 * pt_z p + (if negb (pt_x p =? 0)%Z || negb (pt_y p =? 0)%Z then 1 else 0).

Theorem dissipation_strictly_decreases :
  forall p : CoreAffectPoint,
    p <> mkPoint 0%Z 0%Z 0 ->
    dissipationPotential (dissipationStep p) < dissipationPotential p.
Proof.
  intros [x y z] Hne.
  unfold dissipationStep, dissipationPotential; simpl.
  destruct (negb (x =? 0)%Z || negb (y =? 0)%Z) eqn:Hper.
  - simpl. lia.
  - rewrite orb_false_iff in Hper. destruct Hper as [Hx Hy].
    rewrite negb_false_iff, Z.eqb_eq in Hx, Hy. subst x y.
    destruct z as [| [| [| k]]]; simpl; try lia.
    exfalso; apply Hne; reflexivity.
Qed.

Theorem dissipationPotential_short_circuit_jump :
  dissipationPotential (mkPoint 0%Z 0%Z 2) - dissipationPotential (dissipationStep (mkPoint 0%Z 0%Z 2)) = 4.
Proof. reflexivity. Qed.

Definition nat_repeat {A : Type} (f : A -> A) (n : nat) (x : A) : A :=
  Nat.iter n f x.

Lemma repeat_succ_apply :
  forall (A : Type) (f : A -> A) (n : nat) (a : A),
    nat_repeat f (S n) a = nat_repeat f n (f a).
Proof.
  intros A f n a. unfold nat_repeat.
  induction n as [| n IH]; simpl.
  - reflexivity.
  - f_equal. exact IH.
Qed.

Lemma dissipationStep_repeat_veille :
  forall n : nat, nat_repeat dissipationStep n (mkPoint 0%Z 0%Z 0) = mkPoint 0%Z 0%Z 0.
Proof.
  intro n. induction n as [| n IH]; simpl.
  - reflexivity.
  - unfold nat_repeat in *; simpl. rewrite IH. reflexivity.
Qed.

Lemma dissipation_central_ge2_reaches_veille :
  forall k : nat, nat_repeat dissipationStep (k + 2) (mkPoint 0%Z 0%Z (k + 2)) = mkPoint 0%Z 0%Z 0.
Proof.
  induction k as [| k IH].
  - replace (0 + 2) with 2 by lia.
    rewrite repeat_succ_apply.
    change (dissipationStep (mkPoint 0%Z 0%Z 2)) with (mkPoint 0%Z 0%Z 0).
    apply dissipationStep_repeat_veille.
  - replace (S k + 2) with (S (k + 2)) by lia.
    rewrite repeat_succ_apply.
    replace (dissipationStep (mkPoint 0%Z 0%Z (S (k + 2)))) with (mkPoint 0%Z 0%Z (k + 2))
      by (replace (k + 2) with (S (S k)) by lia; reflexivity).
    exact IH.
Qed.

Lemma dissipation_central_reaches_veille :
  forall z : nat, nat_repeat dissipationStep z (mkPoint 0%Z 0%Z z) = mkPoint 0%Z 0%Z 0.
Proof.
  intros [| [| k]].
  - reflexivity.
  - reflexivity.
  - replace (S (S k)) with (k + 2) by lia.
    apply dissipation_central_ge2_reaches_veille.
Qed.

Theorem dissipation_reaches_veille :
  forall p : CoreAffectPoint,
    nat_repeat dissipationStep (pt_z p + 1) p = mkPoint 0%Z 0%Z 0.
Proof.
  intros [x y z]; simpl.
  replace (z + 1) with (S z) by lia.
  destruct (negb (x =? 0)%Z || negb (y =? 0)%Z) eqn:Hper.
  - rewrite repeat_succ_apply.
    replace (dissipationStep (mkPoint x y z)) with (mkPoint 0%Z 0%Z z)
      by (unfold dissipationStep; simpl; rewrite Hper; reflexivity).
    apply dissipation_central_reaches_veille.
  - rewrite orb_false_iff in Hper. destruct Hper as [Hx Hy].
    rewrite negb_false_iff, Z.eqb_eq in Hx, Hy. subst x y.
    unfold nat_repeat; simpl.
    change (Nat.iter z dissipationStep (mkPoint 0%Z 0%Z z))
      with (nat_repeat dissipationStep z (mkPoint 0%Z 0%Z z)).
    rewrite dissipation_central_reaches_veille.
    reflexivity.
Qed.

Definition allostaticStep (d : SalientDiscrepancy) (p : CoreAffectPoint) : CoreAffectPoint :=
  if Nat.ltb (sd_magnitude d) (sd_resorptionThreshold d) then
    dissipationStep p
  else
    p.

Theorem remanence_preserves_state :
  forall (d : SalientDiscrepancy) (p : CoreAffectPoint),
    SalientDiscrepancy_isInRemanenceWindow d = true ->
    allostaticStep d p = p.
Proof.
  intros d p Hrem.
  unfold SalientDiscrepancy_isInRemanenceWindow in Hrem.
  rewrite andb_true_iff in Hrem. destruct Hrem as [Hle _].
  apply Nat.leb_le in Hle.
  unfold allostaticStep.
  destruct (Nat.ltb_spec0 (sd_magnitude d) (sd_resorptionThreshold d)); [lia | reflexivity].
Qed.

(** ** 6. Frontière du régime concurrentiel et cas limite de coopération (§5.2 & §8.2) *)

Theorem cooperative_step_leaves_crown :
  forall p : CoreAffectPoint,
    CoreAffectPoint_isOnCrown p ->
    (pt_x p >= 0)%Z -> (pt_y p >= 0)%Z ->
    ~ CoreAffectPoint_isOnCrown (mkPoint (pt_x p + 1) (pt_y p + 1) (pt_z p)).
Proof.
  intros [x y z] [_ Hsum] Hx Hy [_ Hsum'].
  unfold CoreAffectPoint_displacementSum in *; simpl in *.
  lia.
Qed.

Inductive ResourceRegime : Type :=
  | RR_competitive : ResourceRegime
  | RR_cooperative : ResourceRegime.

Definition isValidCoreAffectIn (r : ResourceRegime) (p : CoreAffectPoint) : Prop :=
  match r with
  | RR_competitive => isValidCoreAffect p
  | RR_cooperative =>
    CoreAffectPoint_isCentral p \/
    (pt_z p >= 2 /\ crownRadius (pt_z p) <= CoreAffectPoint_displacementSum p)
  end.
