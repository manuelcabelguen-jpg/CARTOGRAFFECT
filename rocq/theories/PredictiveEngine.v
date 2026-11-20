(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*)

From Stdlib Require Import Bool Arith PeanoNat ZArith Lia List.
Import ListNotations.

Open Scope bool_scope.
Open Scope nat_scope.

(** * Module PredictiveEngine — Validation Rocq 9.1.0 *)

(** ** 1. Types fondamentaux des gradients et régimes fonctionnels *)

Inductive Polarity : Type :=
  | Pol_neg  : Polarity
  | Pol_zero : Polarity
  | Pol_pos  : Polarity.

Definition defaultPolarity : Polarity := Pol_neg.

Definition Polarity_eqb (a b : Polarity) : bool :=
  match a, b with
  | Pol_neg, Pol_neg   => true
  | Pol_zero, Pol_zero => true
  | Pol_pos, Pol_pos   => true
  | _, _               => false
  end.

Lemma Polarity_eqb_eq : forall a b : Polarity, Polarity_eqb a b = true <-> a = b.
Proof.
  intros [] []; simpl; split; intro H; try reflexivity; try discriminate.
Qed.

Lemma Polarity_eq_dec : forall a b : Polarity, {a = b} + {a <> b}.
Proof. decide equality. Defined.

Inductive FunctionalRegime : Type :=
  | Reg_charge    : FunctionalRegime
  | Reg_neutral   : FunctionalRegime
  | Reg_discharge : FunctionalRegime.

Definition defaultFunctionalRegime : FunctionalRegime := Reg_charge.

Definition FunctionalRegime_eqb (a b : FunctionalRegime) : bool :=
  match a, b with
  | Reg_charge, Reg_charge       => true
  | Reg_neutral, Reg_neutral     => true
  | Reg_discharge, Reg_discharge => true
  | _, _                         => false
  end.

Lemma FunctionalRegime_eqb_eq :
  forall a b : FunctionalRegime, FunctionalRegime_eqb a b = true <-> a = b.
Proof.
  intros [] []; simpl; split; intro H; try reflexivity; try discriminate.
Qed.

Lemma FunctionalRegime_eq_dec : forall a b : FunctionalRegime, {a = b} + {a <> b}.
Proof. decide equality. Defined.

Definition Polarity_toRegime (p : Polarity) : FunctionalRegime :=
  match p with
  | Pol_neg  => Reg_charge
  | Pol_zero => Reg_neutral
  | Pol_pos  => Reg_discharge
  end.

Definition Polarity_invert (p : Polarity) : Polarity :=
  match p with
  | Pol_neg  => Pol_pos
  | Pol_zero => Pol_zero
  | Pol_pos  => Pol_neg
  end.

Definition Polarity_toInt (p : Polarity) : Z :=
  match p with
  | Pol_neg  => (-1)%Z
  | Pol_zero => 0%Z
  | Pol_pos  => 1%Z
  end.

Definition Polarity_isEngaged (p : Polarity) : bool :=
  match p with
  | Pol_zero => false
  | Pol_neg  => true
  | Pol_pos  => true
  end.

(** ** 2. Signaux d'entrée, Interfaces et Opérations inférentielles *)

Record SalientDiscrepancy : Type := mkSalientDiscrepancy {
  sd_magnitude           : nat;
  sd_sensoryThreshold    : nat;
  sd_resorptionThreshold : nat;
  sd_hysteresis          : sd_resorptionThreshold <= sd_sensoryThreshold
}.

Definition defaultSalientDiscrepancy : SalientDiscrepancy := {|
  sd_magnitude           := 0;
  sd_sensoryThreshold    := 1;
  sd_resorptionThreshold := 1;
  sd_hysteresis          := le_n 1
|}.

Lemma SalientDiscrepancy_eq :
  forall d1 d2 : SalientDiscrepancy,
    sd_magnitude d1 = sd_magnitude d2 ->
    sd_sensoryThreshold d1 = sd_sensoryThreshold d2 ->
    sd_resorptionThreshold d1 = sd_resorptionThreshold d2 ->
    d1 = d2.
Proof.
  intros [m1 s1 r1 h1] [m2 s2 r2 h2] Hm Hs Hr.
  simpl in Hm, Hs, Hr. subst.
  f_equal. apply Peano_dec.le_unique.
Qed.

Definition SalientDiscrepancy_isSensorilySalient (d : SalientDiscrepancy) : bool :=
  Nat.leb (sd_sensoryThreshold d) (sd_magnitude d).

Definition SalientDiscrepancy_isInRemanenceWindow (d : SalientDiscrepancy) : bool :=
  Nat.leb (sd_resorptionThreshold d) (sd_magnitude d) &&
  Nat.ltb (sd_magnitude d) (sd_sensoryThreshold d).

Record PerceptiveInterface : Type := mkPerceptiveInterface {
  pi_controleGradient : Polarity
}.

Definition defaultPerceptiveInterface : PerceptiveInterface := {|
  pi_controleGradient := defaultPolarity
|}.

Record SubjectiveInterface : Type := mkSubjectiveInterface {
  si_attenteGradient      : Polarity;
  si_descendingSuspension : bool
}.

Definition defaultSubjectiveInterface : SubjectiveInterface := {|
  si_attenteGradient      := defaultPolarity;
  si_descendingSuspension := false
|}.

Record AttentionalInterface : Type := mkAttentionalInterface {
  ai_allocatedPrecision  : nat;
  ai_engagementThreshold : nat;
  ai_persistenceDepth    : nat;
  ai_precisionA          : nat;
  ai_precisionC          : nat
}.

Definition defaultAttentionalInterface : AttentionalInterface := {|
  ai_allocatedPrecision  := 0;
  ai_engagementThreshold := 0;
  ai_persistenceDepth    := 0;
  ai_precisionA          := 1;
  ai_precisionC          := 1
|}.

Definition AttentionalInterface_isEngaged (att : AttentionalInterface) : bool :=
  Nat.leb (ai_engagementThreshold att) (ai_allocatedPrecision att).

Inductive InferentialOperation : Type :=
  | IO_ascendingSensory     : InferentialOperation
  | IO_actionImplementation : InferentialOperation
  | IO_contextualGenerative : InferentialOperation
  | IO_integrativeWeighting : InferentialOperation.

Definition InferentialOperation_eqb (a b : InferentialOperation) : bool :=
  match a, b with
  | IO_ascendingSensory, IO_ascendingSensory         => true
  | IO_actionImplementation, IO_actionImplementation => true
  | IO_contextualGenerative, IO_contextualGenerative => true
  | IO_integrativeWeighting, IO_integrativeWeighting => true
  | _, _                                             => false
  end.

Inductive EngineInterface : Type :=
  | EI_perceptive  : EngineInterface
  | EI_subjective  : EngineInterface
  | EI_attentional : EngineInterface.

Definition EngineInterface_eqb (a b : EngineInterface) : bool :=
  match a, b with
  | EI_perceptive, EI_perceptive   => true
  | EI_subjective, EI_subjective   => true
  | EI_attentional, EI_attentional => true
  | _, _                           => false
  end.

Definition InferentialOperation_carrierInterface (op : InferentialOperation) : EngineInterface :=
  match op with
  | IO_ascendingSensory     => EI_perceptive
  | IO_actionImplementation => EI_perceptive
  | IO_contextualGenerative => EI_subjective
  | IO_integrativeWeighting => EI_attentional
  end.

(** ** 3. Espace des couplages (A/C) et État global du Moteur prédictif *)

Record EngineCoupling : Type := mkEngineCoupling {
  ec_attente  : Polarity;
  ec_controle : Polarity
}.

Definition defaultEngineCoupling : EngineCoupling := {|
  ec_attente  := defaultPolarity;
  ec_controle := defaultPolarity
|}.

Definition EngineCoupling_eqb (c1 c2 : EngineCoupling) : bool :=
  Polarity_eqb (ec_attente c1) (ec_attente c2) &&
  Polarity_eqb (ec_controle c1) (ec_controle c2).

Lemma EngineCoupling_eqb_eq :
  forall c1 c2 : EngineCoupling, EngineCoupling_eqb c1 c2 = true <-> c1 = c2.
Proof.
  intros [a1 ctrl1] [a2 ctrl2].
  unfold EngineCoupling_eqb; simpl.
  rewrite andb_true_iff, !Polarity_eqb_eq.
  split.
  - intros [Ha Hc]; subst; reflexivity.
  - intro H; inversion H; split; reflexivity.
Qed.

Definition EngineCoupling_isGlobalNeutrality (c : EngineCoupling) : bool :=
  negb (Polarity_isEngaged (ec_attente c)) && negb (Polarity_isEngaged (ec_controle c)).

Definition EngineCoupling_isSingleEngaged (c : EngineCoupling) : bool :=
  (Polarity_isEngaged (ec_attente c) && negb (Polarity_isEngaged (ec_controle c))) ||
  (negb (Polarity_isEngaged (ec_attente c)) && Polarity_isEngaged (ec_controle c)).

Definition EngineCoupling_isDualEngaged (c : EngineCoupling) : bool :=
  Polarity_isEngaged (ec_attente c) && Polarity_isEngaged (ec_controle c).

Definition allCouplings : list EngineCoupling := [
  mkEngineCoupling Pol_zero Pol_zero;
  mkEngineCoupling Pol_pos  Pol_zero;
  mkEngineCoupling Pol_neg  Pol_zero;
  mkEngineCoupling Pol_zero Pol_pos;
  mkEngineCoupling Pol_zero Pol_neg;
  mkEngineCoupling Pol_pos  Pol_pos;
  mkEngineCoupling Pol_pos  Pol_neg;
  mkEngineCoupling Pol_neg  Pol_pos;
  mkEngineCoupling Pol_neg  Pol_neg
].

Record PredictiveEngineState : Type := mkPredictiveEngineState {
  pes_discrepancy : SalientDiscrepancy;
  pes_perceptive  : PerceptiveInterface;
  pes_subjective  : SubjectiveInterface;
  pes_attentional : AttentionalInterface
}.

Definition defaultPredictiveEngineState : PredictiveEngineState := {|
  pes_discrepancy := defaultSalientDiscrepancy;
  pes_perceptive  := defaultPerceptiveInterface;
  pes_subjective  := defaultSubjectiveInterface;
  pes_attentional := defaultAttentionalInterface
|}.

Definition PredictiveEngineState_currentCoupling (s : PredictiveEngineState) : EngineCoupling := {|
  ec_attente  := si_attenteGradient (pes_subjective s);
  ec_controle := pi_controleGradient (pes_perceptive s)
|}.

Definition PredictiveEngineState_feedbackUpdate
    (s : PredictiveEngineState)
    (newA newC : Polarity)
    (newPrecision : nat) : PredictiveEngineState := {|
  pes_discrepancy := pes_discrepancy s;
  pes_perceptive  := {| pi_controleGradient := newC |};
  pes_subjective  := {|
    si_attenteGradient      := newA;
    si_descendingSuspension := si_descendingSuspension (pes_subjective s)
  |};
  pes_attentional := {|
    ai_allocatedPrecision  := newPrecision;
    ai_engagementThreshold := ai_engagementThreshold (pes_attentional s);
    ai_persistenceDepth    := ai_persistenceDepth (pes_attentional s);
    ai_precisionA          := ai_precisionA (pes_attentional s);
    ai_precisionC          := ai_precisionC (pes_attentional s)
  |}
|}.

Definition PredictiveEngineState_feedbackUpdateWeighted
    (s : PredictiveEngineState)
    (newA newC : Polarity)
    (newPrecision newPrecisionA newPrecisionC : nat) : PredictiveEngineState := {|
  pes_discrepancy := pes_discrepancy s;
  pes_perceptive  := {| pi_controleGradient := newC |};
  pes_subjective  := {|
    si_attenteGradient      := newA;
    si_descendingSuspension := si_descendingSuspension (pes_subjective s)
  |};
  pes_attentional := {|
    ai_allocatedPrecision  := newPrecision;
    ai_engagementThreshold := ai_engagementThreshold (pes_attentional s);
    ai_persistenceDepth    := ai_persistenceDepth (pes_attentional s);
    ai_precisionA          := newPrecisionA;
    ai_precisionC          := newPrecisionC
  |}
|}.

Definition engineStep (s : PredictiveEngineState) : PredictiveEngineState :=
  let c := PredictiveEngineState_currentCoupling s in
  if negb (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s)) then
    if SalientDiscrepancy_isInRemanenceWindow (pes_discrepancy s) then
      s
    else {|
      pes_discrepancy := pes_discrepancy s;
      pes_perceptive  := {| pi_controleGradient := Pol_zero |};
      pes_subjective  := {| si_attenteGradient := Pol_zero; si_descendingSuspension := false |};
      pes_attentional := {|
        ai_allocatedPrecision  := 0;
        ai_engagementThreshold := ai_engagementThreshold (pes_attentional s);
        ai_persistenceDepth    := 0;
        ai_precisionA          := ai_precisionA (pes_attentional s);
        ai_precisionC          := ai_precisionC (pes_attentional s)
      |}
    |}
  else if EngineCoupling_isGlobalNeutrality c then {|
    pes_discrepancy := pes_discrepancy s;
    pes_perceptive  := {| pi_controleGradient := Pol_pos |};
    pes_subjective  := pes_subjective s;
    pes_attentional := pes_attentional s
  |}
  else if negb (si_descendingSuspension (pes_subjective s)) &&
          negb (AttentionalInterface_isEngaged (pes_attentional s)) then {|
    pes_discrepancy := pes_discrepancy s;
    pes_perceptive  := pes_perceptive s;
    pes_subjective  := {|
      si_attenteGradient      := si_attenteGradient (pes_subjective s);
      si_descendingSuspension := true
    |};
    pes_attentional := pes_attentional s
  |}
  else if negb (AttentionalInterface_isEngaged (pes_attentional s)) then {|
    pes_discrepancy := pes_discrepancy s;
    pes_perceptive  := pes_perceptive s;
    pes_subjective  := pes_subjective s;
    pes_attentional := {|
      ai_allocatedPrecision  := ai_engagementThreshold (pes_attentional s);
      ai_engagementThreshold := ai_engagementThreshold (pes_attentional s);
      ai_persistenceDepth    := ai_persistenceDepth (pes_attentional s);
      ai_precisionA          := ai_precisionA (pes_attentional s);
      ai_precisionC          := ai_precisionC (pes_attentional s)
    |}
  |}
  else
    s.

Theorem engineStep_of_salient_neutral :
  forall s : PredictiveEngineState,
    SalientDiscrepancy_isSensorilySalient (pes_discrepancy s) = true ->
    EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s) = true ->
    engineStep s = {|
      pes_discrepancy := pes_discrepancy s;
      pes_perceptive  := {| pi_controleGradient := Pol_pos |};
      pes_subjective  := pes_subjective s;
      pes_attentional := pes_attentional s
    |}.
Proof.
  intros s Hsal Hneut.
  unfold engineStep. rewrite Hsal, Hneut. reflexivity.
Qed.

Theorem engineStep_of_salient_nonneutral_unsuspended :
  forall s : PredictiveEngineState,
    SalientDiscrepancy_isSensorilySalient (pes_discrepancy s) = true ->
    EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s) = false ->
    si_descendingSuspension (pes_subjective s) = false ->
    AttentionalInterface_isEngaged (pes_attentional s) = false ->
    engineStep s = {|
      pes_discrepancy := pes_discrepancy s;
      pes_perceptive  := pes_perceptive s;
      pes_subjective  := {|
        si_attenteGradient      := si_attenteGradient (pes_subjective s);
        si_descendingSuspension := true
      |};
      pes_attentional := pes_attentional s
    |}.
Proof.
  intros s Hsal Hnon Hnosusp Huneng.
  unfold engineStep. rewrite Hsal, Hnon, Hnosusp, Huneng. reflexivity.
Qed.

Theorem engineStep_of_salient_nonneutral_suspended_unengaged :
  forall s : PredictiveEngineState,
    SalientDiscrepancy_isSensorilySalient (pes_discrepancy s) = true ->
    EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s) = false ->
    si_descendingSuspension (pes_subjective s) = true ->
    AttentionalInterface_isEngaged (pes_attentional s) = false ->
    engineStep s = {|
      pes_discrepancy := pes_discrepancy s;
      pes_perceptive  := pes_perceptive s;
      pes_subjective  := pes_subjective s;
      pes_attentional := {|
        ai_allocatedPrecision  := ai_engagementThreshold (pes_attentional s);
        ai_engagementThreshold := ai_engagementThreshold (pes_attentional s);
        ai_persistenceDepth    := ai_persistenceDepth (pes_attentional s);
        ai_precisionA          := ai_precisionA (pes_attentional s);
        ai_precisionC          := ai_precisionC (pes_attentional s)
      |}
    |}.
Proof.
  intros s Hsal Hnon Hsusp Huneng.
  unfold engineStep. rewrite Hsal, Hnon, Hsusp, Huneng. reflexivity.
Qed.

(** ** 4. Démonstration des invariants fondamentaux du Moteur prédictif *)

Theorem Polarity_invert_involutive :
  forall p : Polarity, Polarity_invert (Polarity_invert p) = p.
Proof.
  intros []; reflexivity.
Qed.

Theorem Polarity_toRegime_neutral_iff :
  forall p : Polarity, Polarity_toRegime p = Reg_neutral <-> p = Pol_zero.
Proof.
  intros []; simpl; split; intro H; try reflexivity; try discriminate.
Qed.

Theorem single_neutral_not_global_neutral :
  exists c : EngineCoupling,
    ec_attente c = Pol_zero /\ EngineCoupling_isGlobalNeutrality c = false.
Proof.
  exists (mkEngineCoupling Pol_zero Pol_pos). split; reflexivity.
Qed.

Theorem allCouplings_card : length allCouplings = 9.
Proof. reflexivity. Qed.

Theorem mem_allCouplings : forall c : EngineCoupling, In c allCouplings.
Proof.
  intros [[] []]; unfold allCouplings; simpl; tauto.
Qed.

Theorem coupling_regime_partition :
  forall c : EngineCoupling,
    (EngineCoupling_isGlobalNeutrality c = true /\
     EngineCoupling_isSingleEngaged c = false /\
     EngineCoupling_isDualEngaged c = false) \/
    (EngineCoupling_isGlobalNeutrality c = false /\
     EngineCoupling_isSingleEngaged c = true /\
     EngineCoupling_isDualEngaged c = false) \/
    (EngineCoupling_isGlobalNeutrality c = false /\
     EngineCoupling_isSingleEngaged c = false /\
     EngineCoupling_isDualEngaged c = true).
Proof.
  intros [[] []]; simpl; tauto.
Qed.

Theorem feedbackUpdate_couples_gradients :
  forall (s : PredictiveEngineState) (newA newC : Polarity) (newPrecision : nat),
    PredictiveEngineState_currentCoupling (PredictiveEngineState_feedbackUpdate s newA newC newPrecision) =
      mkEngineCoupling newA newC /\
    ai_allocatedPrecision (pes_attentional (PredictiveEngineState_feedbackUpdate s newA newC newPrecision)) =
      newPrecision /\
    pes_discrepancy (PredictiveEngineState_feedbackUpdate s newA newC newPrecision) =
      pes_discrepancy s.
Proof.
  intros s newA newC newPrecision. repeat split; reflexivity.
Qed.

Theorem feedbackUpdateWeighted_couples_precision :
  forall (s : PredictiveEngineState) (newA newC : Polarity)
         (newPrecision newPrecisionA newPrecisionC : nat),
    PredictiveEngineState_currentCoupling
      (PredictiveEngineState_feedbackUpdateWeighted s newA newC newPrecision newPrecisionA newPrecisionC) =
      mkEngineCoupling newA newC /\
    ai_allocatedPrecision
      (pes_attentional (PredictiveEngineState_feedbackUpdateWeighted s newA newC newPrecision newPrecisionA newPrecisionC)) =
      newPrecision /\
    ai_precisionA
      (pes_attentional (PredictiveEngineState_feedbackUpdateWeighted s newA newC newPrecision newPrecisionA newPrecisionC)) =
      newPrecisionA /\
    ai_precisionC
      (pes_attentional (PredictiveEngineState_feedbackUpdateWeighted s newA newC newPrecision newPrecisionA newPrecisionC)) =
      newPrecisionC /\
    pes_discrepancy
      (PredictiveEngineState_feedbackUpdateWeighted s newA newC newPrecision newPrecisionA newPrecisionC) =
      pes_discrepancy s.
Proof.
  intros s newA newC newPrecision newPrecisionA newPrecisionC. repeat split; reflexivity.
Qed.

Theorem inferential_loop_covers_interfaces :
  forall iface : EngineInterface,
    exists op : InferentialOperation, InferentialOperation_carrierInterface op = iface.
Proof.
  intros [].
  - exists IO_ascendingSensory. reflexivity.
  - exists IO_contextualGenerative. reflexivity.
  - exists IO_integrativeWeighting. reflexivity.
Qed.

Theorem engineStep_remanence :
  forall s : PredictiveEngineState,
    SalientDiscrepancy_isInRemanenceWindow (pes_discrepancy s) = true ->
    engineStep s = s.
Proof.
  intros s Hrem.
  pose proof Hrem as Hrem_copy.
  unfold SalientDiscrepancy_isInRemanenceWindow in Hrem_copy.
  rewrite andb_true_iff in Hrem_copy.
  destruct Hrem_copy as [_ Hlt].
  apply Nat.ltb_lt in Hlt.
  assert (Hnsal : SalientDiscrepancy_isSensorilySalient (pes_discrepancy s) = false).
  { unfold SalientDiscrepancy_isSensorilySalient. apply Nat.leb_gt. exact Hlt. }
  unfold engineStep. rewrite Hnsal. simpl. rewrite Hrem. reflexivity.
Qed.

Theorem engineStep_phase_progression :
  forall s0 : PredictiveEngineState,
    SalientDiscrepancy_isSensorilySalient (pes_discrepancy s0) = true ->
    EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s0) = true ->
    si_descendingSuspension (pes_subjective s0) = false ->
    AttentionalInterface_isEngaged (pes_attentional s0) = false ->
    let s1 := engineStep s0 in
    let s2 := engineStep s1 in
    let s3 := engineStep s2 in
    (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s1) = true /\
     EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s1) = false /\
     si_descendingSuspension (pes_subjective s1) = false /\
     AttentionalInterface_isEngaged (pes_attentional s1) = false) /\
    (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s2) = true /\
     EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s2) = false /\
     si_descendingSuspension (pes_subjective s2) = true /\
     AttentionalInterface_isEngaged (pes_attentional s2) = false) /\
    (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s3) = true /\
     EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s3) = false /\
     si_descendingSuspension (pes_subjective s3) = true /\
     AttentionalInterface_isEngaged (pes_attentional s3) = true).
Proof.
  intros s0 Hsal Hneut Hnosusp Huneng s1 s2 s3.
  assert (Hs1 : s1 = {|
    pes_discrepancy := pes_discrepancy s0;
    pes_perceptive  := {| pi_controleGradient := Pol_pos |};
    pes_subjective  := pes_subjective s0;
    pes_attentional := pes_attentional s0
  |}) by (apply engineStep_of_salient_neutral; assumption).
  assert (Hs1_neut : EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s1) = false).
  { rewrite Hs1. unfold PredictiveEngineState_currentCoupling, EngineCoupling_isGlobalNeutrality.
    simpl. rewrite andb_false_r. reflexivity. }
  assert (Hs2 : s2 = {|
    pes_discrepancy := pes_discrepancy s0;
    pes_perceptive  := {| pi_controleGradient := Pol_pos |};
    pes_subjective  := {|
      si_attenteGradient      := si_attenteGradient (pes_subjective s0);
      si_descendingSuspension := true
    |};
    pes_attentional := pes_attentional s0
  |}).
  { unfold s2.
    rewrite (engineStep_of_salient_nonneutral_unsuspended s1);
      [rewrite Hs1; reflexivity | rewrite Hs1; exact Hsal | exact Hs1_neut | rewrite Hs1; exact Hnosusp | rewrite Hs1; exact Huneng]. }
  assert (Hs2_neut : EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s2) = false).
  { rewrite Hs2. unfold PredictiveEngineState_currentCoupling, EngineCoupling_isGlobalNeutrality.
    simpl. rewrite andb_false_r. reflexivity. }
  assert (Hs3 : s3 = {|
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
  { unfold s3.
    rewrite (engineStep_of_salient_nonneutral_suspended_unengaged s2);
      [rewrite Hs2; reflexivity | rewrite Hs2; exact Hsal | exact Hs2_neut | rewrite Hs2; reflexivity | rewrite Hs2; exact Huneng]. }
  assert (Hs3_neut : EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s3) = false).
  { rewrite Hs3. unfold PredictiveEngineState_currentCoupling, EngineCoupling_isGlobalNeutrality.
    simpl. rewrite andb_false_r. reflexivity. }
  assert (Hs3_eng : AttentionalInterface_isEngaged (pes_attentional s3) = true).
  { rewrite Hs3. unfold AttentionalInterface_isEngaged; simpl. apply Nat.leb_refl. }
  repeat split.
  - rewrite Hs1; exact Hsal.
  - exact Hs1_neut.
  - rewrite Hs1; exact Hnosusp.
  - rewrite Hs1; exact Huneng.
  - rewrite Hs2; exact Hsal.
  - exact Hs2_neut.
  - rewrite Hs2; reflexivity.
  - rewrite Hs2; exact Huneng.
  - rewrite Hs3; exact Hsal.
  - exact Hs3_neut.
  - rewrite Hs3; reflexivity.
  - exact Hs3_eng.
Qed.
