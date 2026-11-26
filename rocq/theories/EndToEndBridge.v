(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*)

From Stdlib Require Import Bool Arith PeanoNat NArith ZArith Lia String List.
Import ListNotations.
Require Import CartograffectRocq.PredictiveEngine.
Require Import CartograffectRocq.CoreAffect.
Require Import CartograffectRocq.AffectiveMatrix.
Require Import CartograffectRocq.AffectiveTaxonomy.
Require Import CartograffectRocq.AffectiveDynamics.
Require Import CartograffectRocq.Lexicon176.
Require Import CartograffectRocq.PredictiveCircuit.
Require Import CartograffectRocq.OperantFactorization.

Open Scope bool_scope.
Open Scope nat_scope.

(** * Module EndToEndBridge — Validation Rocq 9.1.0 *)
(** Ponts formels complets de bout en bout (Strate 0 Hexa-Prouvée) *)

(** ** 1. Définitions canoniques des ponts opérants et pipelines terminaux *)

Inductive OperantRole : Type :=
  | OR_centralOperator : OperantRole
  | OR_preOperantAxial : OrientationSector -> OperantRole
  | OR_pureOperant     : OperantContingency -> OperantRole
  | OR_blendedLateral  : OrientationSector -> OperantContingency -> OperantRole.

Definition couplingToContingency (c : EngineCoupling) : option OperantContingency :=
  match ec_attente c, ec_controle c with
  | Pol_pos, Pol_pos => Some (mkOperantContingency OE_Reinforcement OO_Addition)
  | Pol_pos, Pol_neg => Some (mkOperantContingency OE_Reinforcement OO_Removal)
  | Pol_neg, Pol_neg => Some (mkOperantContingency OE_Punishment    OO_Addition)
  | Pol_neg, Pol_pos => Some (mkOperantContingency OE_Punishment    OO_Removal)
  | _,       _       => None
  end.

Definition quadrantContingency (x y : Z) : option OperantContingency :=
  if (0 <? x)%Z && (0 <? y)%Z then Some (mkOperantContingency OE_Reinforcement OO_Addition)
  else if (0 <? x)%Z && (y <? 0)%Z then Some (mkOperantContingency OE_Reinforcement OO_Removal)
  else if (x <? 0)%Z && (y <? 0)%Z then Some (mkOperantContingency OE_Punishment OO_Addition)
  else if (x <? 0)%Z && (0 <? y)%Z then Some (mkOperantContingency OE_Punishment OO_Removal)
  else None.

Definition classifyOperantRole (p : CoreAffectPoint) : OperantRole :=
  match quadrantContingency (pt_x p) (pt_y p), CoreAffectPoint_dominantSector p with
  | Some c, Some sec => OR_blendedLateral sec c
  | Some c, None     => OR_pureOperant c
  | None,   Some sec => OR_preOperantAxial sec
  | None,   None     => OR_centralOperator
  end.

Definition evaluateUnifiedTaxonomy (p : UnifiedDynamicsParams) (c : EngineCoupling)
    (z : nat) (rhoHat kappaHat : N) (susp : bool) : TaxonomicState :=
  evaluateTaxonomy (evaluateMatrix (projectUnifiedState p c z rhoHat kappaHat susp) canonicalMapping).

Definition evaluateCircularTaxonomy (s : CircularCircuitState) : TaxonomicState :=
  evaluateTaxonomy (evaluateMatrix (snd (op3_crossingI_perceptible s)) canonicalMapping).

(** ** 2. Lemmes auxiliaires (unicité nominale/spatiale, quadrants et arithmétique des signes) *)

Lemma nodup_map_inj :
  forall (A B : Type) (f : A -> B) (l : list A),
    NoDup (map f l) ->
    forall a b : A, In a l -> In b l -> f a = f b -> a = b.
Proof.
  intros A B f l Hnd.
  induction l as [| x xs IH]; intros a b Ha Hb Heq.
  - inversion Ha.
  - simpl in Hnd. inversion Hnd as [| ? ? Hnin Hnd_xs]; subst.
    destruct Ha as [<- | Ha']; destruct Hb as [<- | Hb'].
    + reflexivity.
    + exfalso. apply Hnin. rewrite Heq. apply in_map. exact Hb'.
    + exfalso. apply Hnin. rewrite <- Heq. apply in_map. exact Ha'.
    + exact (IH Hnd_xs a b Ha' Hb' Heq).
Qed.

Definition mem_string_list (s : string) (l : list string) : bool :=
  existsb (String.eqb s) l.

Lemma mem_string_list_iff :
  forall (s : string) (l : list string),
    mem_string_list s l = true <-> In s l.
Proof.
  intros s l. unfold mem_string_list.
  rewrite existsb_exists. split.
  - intros [x [Hx Heq]]. apply String.eqb_eq in Heq. subst; exact Hx.
  - intro H. exists s. split; [exact H | apply String.eqb_eq; reflexivity].
Qed.

Fixpoint nodupb_string (l : list string) : bool :=
  match l with
  | [] => true
  | h :: t => negb (mem_string_list h t) && nodupb_string t
  end.

Lemma nodupb_string_NoDup :
  forall l : list string, nodupb_string l = true -> NoDup l.
Proof.
  induction l as [| h t IH]; intro H; simpl in *.
  - constructor.
  - rewrite andb_true_iff in H. destruct H as [Hnin Hrest].
    constructor.
    + intro Hin. apply (proj2 (mem_string_list_iff h t)) in Hin.
      rewrite Hin in Hnin. discriminate.
    + exact (IH Hrest).
Qed.

(** Lemme auxiliaire d'audit : les 176 étiquettes nominales de all176Entries sont deux à deux distinctes. *)
Theorem all176Entries_unique_labels :
  NoDup (map le_label all176Entries).
Proof.
  apply nodupb_string_NoDup. vm_compute. reflexivity.
Qed.

Definition LexiconEntry_eqb (e1 e2 : LexiconEntry) : bool :=
  String.eqb (le_label e1) (le_label e2) && CoreAffectPoint_eqb (le_point e1) (le_point e2).

Lemma LexiconEntry_eqb_eq :
  forall e1 e2 : LexiconEntry, LexiconEntry_eqb e1 e2 = true <-> e1 = e2.
Proof.
  intros [l1 p1] [l2 p2]. unfold LexiconEntry_eqb; simpl.
  rewrite andb_true_iff, String.eqb_eq, CoreAffectPoint_eqb_eq.
  split.
  - intros [Hl Hp]; subst; reflexivity.
  - intro H; inversion H; split; reflexivity.
Qed.

Lemma mem_lexicon_of_existsb :
  forall (e : LexiconEntry) (l : list LexiconEntry),
    existsb (LexiconEntry_eqb e) l = true -> In e l.
Proof.
  intros e l H.
  rewrite existsb_exists in H.
  destruct H as [x [Hx Heq]].
  apply (proj1 (LexiconEntry_eqb_eq e x)) in Heq.
  subst x. exact Hx.
Qed.

Lemma quadrant_pos_pos :
  forall x y : Z,
    (x > 0)%Z -> (y > 0)%Z ->
    quadrantContingency x y = Some (mkOperantContingency OE_Reinforcement OO_Addition).
Proof.
  intros x y Hx Hy. unfold quadrantContingency.
  destruct (Z.ltb_spec0 0 x); destruct (Z.ltb_spec0 0 y); simpl; try reflexivity; lia.
Qed.

Lemma quadrant_pos_neg :
  forall x y : Z,
    (x > 0)%Z -> (y < 0)%Z ->
    quadrantContingency x y = Some (mkOperantContingency OE_Reinforcement OO_Removal).
Proof.
  intros x y Hx Hy. unfold quadrantContingency.
  destruct (Z.ltb_spec0 0 x); destruct (Z.ltb_spec0 0 y);
  destruct (Z.ltb_spec0 y 0); simpl; try reflexivity; lia.
Qed.

Lemma quadrant_neg_neg :
  forall x y : Z,
    (x < 0)%Z -> (y < 0)%Z ->
    quadrantContingency x y = Some (mkOperantContingency OE_Punishment OO_Addition).
Proof.
  intros x y Hx Hy. unfold quadrantContingency.
  destruct (Z.ltb_spec0 0 x); destruct (Z.ltb_spec0 x 0);
  destruct (Z.ltb_spec0 y 0); simpl; try reflexivity; lia.
Qed.

Lemma quadrant_neg_pos :
  forall x y : Z,
    (x < 0)%Z -> (y > 0)%Z ->
    quadrantContingency x y = Some (mkOperantContingency OE_Punishment OO_Removal).
Proof.
  intros x y Hx Hy. unfold quadrantContingency.
  destruct (Z.ltb_spec0 0 x); destruct (Z.ltb_spec0 x 0);
  destruct (Z.ltb_spec0 y 0); destruct (Z.ltb_spec0 0 y); simpl; try reflexivity; lia.
Qed.

Lemma quadrant_zero_left :
  forall y : Z, quadrantContingency 0%Z y = None.
Proof.
  intro y. unfold quadrantContingency; simpl. reflexivity.
Qed.

Lemma quadrant_zero_right :
  forall x : Z, quadrantContingency x 0%Z = None.
Proof.
  intro x. unfold quadrantContingency.
  change (0 <? 0)%Z with false.
  rewrite !andb_false_r. reflexivity.
Qed.

Lemma deploy_quadrant_eq :
  forall (c : EngineCoupling) (d piA piC : nat),
    quadrantContingency
      (pt_x (deployCouplingWithPrecision c d piA piC))
      (pt_y (deployCouplingWithPrecision c d piA piC)) =
    couplingToContingency c.
Proof.
  intros [a ctrl] d piA piC.
  pose proof (apportionRay_bounds d piA piC) as Hb.
  destruct (apportionRay d piA piC) as [ax ay] eqn:Heq; simpl in Hb.
  destruct Hb as [Hax [Hay _]].
  destruct a; destruct ctrl;
    unfold deployCouplingWithPrecision, couplingToContingency, signedAmplitude;
    simpl; rewrite ?Heq; simpl.
  - apply quadrant_neg_neg; lia.
  - apply quadrant_zero_right.
  - apply quadrant_neg_pos; lia.
  - apply quadrant_zero_left.
  - apply quadrant_zero_left.
  - apply quadrant_zero_left.
  - apply quadrant_pos_neg; lia.
  - apply quadrant_zero_right.
  - apply quadrant_pos_pos; lia.
Qed.

Lemma projectPerceptible_neutral_quadrant :
  forall (c : EngineCoupling) (z piA piC : nat) (susp : bool),
    EngineCoupling_isGlobalNeutrality c = true ->
    quadrantContingency
      (pt_x (projectPerceptible c z piA piC susp))
      (pt_y (projectPerceptible c z piA piC susp)) = None.
Proof.
  intros c z piA piC susp Hneut.
  unfold projectPerceptible. rewrite Hneut.
  destruct (susp && Nat.leb 2 z); simpl; apply quadrant_zero_left.
Qed.

Lemma projectPerceptible_quadrant_eq :
  forall (c : EngineCoupling) (d piA piC : nat) (susp : bool),
    quadrantContingency
      (pt_x (projectPerceptible c (d + 2) piA piC susp))
      (pt_y (projectPerceptible c (d + 2) piA piC susp)) =
    couplingToContingency c.
Proof.
  intros c d piA piC susp.
  destruct (EngineCoupling_isGlobalNeutrality c) eqn:Hneut.
  - assert (Hnone : couplingToContingency c = None).
    { destruct c as [[] []]; simpl in Hneut; try discriminate; reflexivity. }
    rewrite Hnone.
    apply projectPerceptible_neutral_quadrant; exact Hneut.
  - replace (d + 2) with (S (S d)) by lia.
    unfold projectPerceptible. rewrite Hneut.
    apply deploy_quadrant_eq.
Qed.

Lemma energy_pos_pos :
  forall x y : Z,
    (x > 0)%Z -> (y > 0)%Z ->
    computeEnergyRegime x y = ER_positiveSynergy.
Proof.
  intros x y Hx Hy. unfold computeEnergyRegime.
  destruct (Z.eqb_spec x 0); destruct (Z.eqb_spec y 0);
  destruct (Z.ltb_spec0 0 x); destruct (Z.ltb_spec0 0 y); simpl; try reflexivity; lia.
Qed.

Lemma energy_pos_neg :
  forall x y : Z,
    (x > 0)%Z -> (y < 0)%Z ->
    computeEnergyRegime x y = ER_trophotropicRelease.
Proof.
  intros x y Hx Hy. unfold computeEnergyRegime.
  destruct (Z.eqb_spec x 0); destruct (Z.eqb_spec y 0);
  destruct (Z.ltb_spec0 0 x); destruct (Z.ltb_spec0 0 y);
  destruct (Z.ltb_spec0 x 0); destruct (Z.ltb_spec0 y 0); simpl; try reflexivity; lia.
Qed.

Lemma energy_neg_pos :
  forall x y : Z,
    (x < 0)%Z -> (y > 0)%Z ->
    computeEnergyRegime x y = ER_ergotropicCompensation.
Proof.
  intros x y Hx Hy. unfold computeEnergyRegime.
  destruct (Z.eqb_spec x 0); destruct (Z.eqb_spec y 0);
  destruct (Z.ltb_spec0 0 x); destruct (Z.ltb_spec0 0 y);
  destruct (Z.ltb_spec0 x 0); destruct (Z.ltb_spec0 y 0); simpl; try reflexivity; lia.
Qed.

Lemma energy_neg_neg :
  forall x y : Z,
    (x < 0)%Z -> (y < 0)%Z ->
    computeEnergyRegime x y = ER_negativeSynergy.
Proof.
  intros x y Hx Hy. unfold computeEnergyRegime.
  destruct (Z.eqb_spec x 0); destruct (Z.eqb_spec y 0);
  destruct (Z.ltb_spec0 0 x); destruct (Z.ltb_spec0 0 y);
  destruct (Z.ltb_spec0 x 0); destruct (Z.ltb_spec0 y 0); simpl; try reflexivity; lia.
Qed.

Lemma weight_pos_qx_nz :
  forall p q : CoreAffectPoint,
    pt_x p <> 0%Z -> pt_y p <> 0%Z ->
    dtk_weight canonicalDepthKernel p q > 0 ->
    pt_x q <> 0%Z.
Proof.
  intros p q Hpx Hpy Hw Hqx0.
  unfold canonicalDepthKernel, canonicalDepthWeight in Hw; simpl in Hw.
  destruct (isValidCoreAffectB p && isValidCoreAffectB q &&
            Nat.eqb (pt_z q) (pt_z p + 1) &&
            ((0 <=? pt_x p * pt_x q)%Z && (0 <=? pt_y p * pt_y q)%Z)); [| lia].
  rewrite Hqx0 in Hw.
  replace (0 =? 0)%Z with true in Hw by reflexivity.
  destruct (Z.eqb_spec (pt_x p) 0); [lia |].
  destruct (Z.eqb_spec (pt_y p) 0); [lia |].
  destruct (pt_y q =? 0)%Z; simpl in Hw; lia.
Qed.

Lemma weight_pos_qy_nz :
  forall p q : CoreAffectPoint,
    pt_x p <> 0%Z -> pt_y p <> 0%Z ->
    dtk_weight canonicalDepthKernel p q > 0 ->
    pt_y q <> 0%Z.
Proof.
  intros p q Hpx Hpy Hw Hqy0.
  unfold canonicalDepthKernel, canonicalDepthWeight in Hw; simpl in Hw.
  destruct (isValidCoreAffectB p && isValidCoreAffectB q &&
            Nat.eqb (pt_z q) (pt_z p + 1) &&
            ((0 <=? pt_x p * pt_x q)%Z && (0 <=? pt_y p * pt_y q)%Z)); [| lia].
  rewrite Hqy0 in Hw.
  replace (0 =? 0)%Z with true in Hw by reflexivity.
  destruct (Z.eqb_spec (pt_x p) 0); [lia |].
  destruct (Z.eqb_spec (pt_y p) 0); [lia |].
  destruct (pt_x q =? 0)%Z; simpl in Hw; lia.
Qed.

Lemma projectPerceptible_z_le :
  forall (c : EngineCoupling) (z piA piC : nat) (susp : bool),
    pt_z (projectPerceptible c z piA piC susp) <= z.
Proof.
  intros [a ctrl] z piA piC susp.
  unfold projectPerceptible.
  destruct (EngineCoupling_isGlobalNeutrality (mkEngineCoupling a ctrl)).
  - destruct (susp && Nat.leb 2 z); simpl; lia.
  - destruct z as [| [| d]]; simpl; try lia.
    destruct a; destruct ctrl; unfold deployCouplingWithPrecision; simpl; lia.
Qed.

Lemma op3_point_engaged_quadrant :
  forall s : CircularCircuitState,
    AttentionalInterface_isEngaged (ccs_attentional s) = true ->
    quadrantContingency
      (pt_x (cas_point (snd (op3_crossingI_perceptible s))))
      (pt_y (cas_point (snd (op3_crossingI_perceptible s)))) =
    couplingToContingency (mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s)).
Proof.
  intros s Heng.
  unfold op3_crossingI_perceptible, projectPerceptibleState; simpl.
  set (c := mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s)).
  destruct (EngineCoupling_isGlobalNeutrality c) eqn:Hneut.
  - assert (Hnone : couplingToContingency c = None).
    { destruct c as [[] []]; simpl in Hneut; try discriminate; reflexivity. }
    rewrite Hnone.
    apply projectPerceptible_neutral_quadrant; exact Hneut.
  - rewrite Heng; simpl.
    apply projectPerceptible_quadrant_eq.
Qed.

Lemma op3_point_z_le :
  forall s : CircularCircuitState,
    ai_persistenceDepth (ccs_attentional s) <= 5 ->
    pt_z (cas_point (snd (op3_crossingI_perceptible s))) <= 7.
Proof.
  intros s Hd.
  unfold op3_crossingI_perceptible, projectPerceptibleState; simpl.
  set (c := mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s)).
  set (z :=
    if EngineCoupling_isGlobalNeutrality c then
      if hss_descendingSuspension (ccs_subjectiveHidden s) then
        ai_persistenceDepth (ccs_attentional s) + 2
      else 0
    else if negb (AttentionalInterface_isEngaged (ccs_attentional s)) then
      if hss_descendingSuspension (ccs_subjectiveHidden s) then
        ai_persistenceDepth (ccs_attentional s) + 2
      else 1
    else
      ai_persistenceDepth (ccs_attentional s) + 2).
  assert (Hz7 : z <= 7).
  { unfold z.
    destruct (EngineCoupling_isGlobalNeutrality c).
    - destruct (hss_descendingSuspension (ccs_subjectiveHidden s)); lia.
    - destruct (negb (AttentionalInterface_isEngaged (ccs_attentional s))).
      + destruct (hss_descendingSuspension (ccs_subjectiveHidden s)); lia.
      + lia. }
  eapply Nat.le_trans; [apply projectPerceptible_z_le | exact Hz7].
Qed.

Lemma runCartograffectPipeline_coherent :
  forall s : PredictiveEngineState,
    isCoherentTerminalState s (runCartograffectPipeline s).
Proof.
  intro s.
  unfold isCoherentTerminalState, runCartograffectPipeline,
    evaluateTaxonomy, evaluateMatrix, evaluateCoreAffect, canonicalMapping; simpl.
  repeat split.
  - apply engine_induces_valid_core_affect.
  - apply antagonistPoint_preserves_validity, engine_induces_valid_core_affect.
  - apply antagonistPoint_preserves_z.
  - apply antagonistPoint_preserves_displacementSum.
  - apply classifyTaxonomicGroup_correct.
  - intros g Hg.
    exact (taxonomy_group_exclusive (projectToCoreAffect s) g
      (classifyTaxonomicGroup (projectToCoreAffect s)) Hg
      (classifyTaxonomicGroup_correct (projectToCoreAffect s))).
  - apply classifyTaxonomicGroup_correct.
Qed.

(** ** 3. Les 10 théorèmes de bout en bout (Strate 0 Hexa-Prouvée) *)

(** [1/10] Pont Circuit prédictif -> Contingences opérantes {R+, R-, P+, P-} *)
Theorem circuit_coupling_operant_bridge :
  forall (c : EngineCoupling) (d piA piC : nat) (susp : bool),
    diagToContingency (projectPerceptible c 2 piA piC susp) = couplingToContingency c /\
    quadrantContingency
      (pt_x (projectPerceptible c (d + 2) piA piC susp))
      (pt_y (projectPerceptible c (d + 2) piA piC susp)) = couplingToContingency c.
Proof.
  intros c d piA piC susp. split.
  - destruct (EngineCoupling_isGlobalNeutrality c) eqn:Hneut.
    + destruct c as [[] []]; simpl in Hneut; try discriminate.
      unfold projectPerceptible; simpl.
      destruct susp; reflexivity.
    + rewrite (projectPerceptible_z2_matches_phiL1 c piA piC susp Hneut).
      destruct c as [[] []]; simpl in Hneut; try discriminate; reflexivity.
  - apply projectPerceptible_quadrant_eq.
Qed.

(** [2/10] Pont Amorçage axial pré-opérant -> Entrée dans l'espace opérant *)
Theorem triggerSecondaryGradient_enters_operant :
  forall (c : EngineCoupling) (newPol : Polarity),
    EngineCoupling_isSingleEngaged c = true ->
    Polarity_isEngaged newPol = true ->
    let c' := triggerSecondaryGradient c newPol in
    let p' := deployCouplingAtDepth c' 0 in
    diagToContingency (deployCouplingAtDepth c 0) = None /\
    exists oc : OperantContingency,
      diagToContingency p' = Some oc /\
      couplingToContingency c' = Some oc /\
      (c = mkEngineCoupling Pol_pos Pol_zero -> oc_effect oc = OE_Reinforcement) /\
      (c = mkEngineCoupling Pol_neg Pol_zero -> oc_effect oc = OE_Punishment) /\
      (c = mkEngineCoupling Pol_zero Pol_pos ->
        oc = mkOperantContingency OE_Reinforcement OO_Addition \/
        oc = mkOperantContingency OE_Punishment OO_Removal) /\
      (c = mkEngineCoupling Pol_zero Pol_neg ->
        oc = mkOperantContingency OE_Reinforcement OO_Removal \/
        oc = mkOperantContingency OE_Punishment OO_Addition).
Proof.
  intros [a ctrl] newPol Hax Hsal.
  destruct a; destruct ctrl; destruct newPol;
    simpl in Hax, Hsal; try discriminate; cbv zeta.
  - split; [reflexivity |].
    exists (mkOperantContingency OE_Punishment OO_Addition).
    repeat split; try intro Heq; try discriminate Heq; reflexivity.
  - split; [reflexivity |].
    exists (mkOperantContingency OE_Punishment OO_Removal).
    repeat split; try intro Heq; try discriminate Heq; reflexivity.
  - split; [reflexivity |].
    exists (mkOperantContingency OE_Punishment OO_Addition).
    repeat split; try intro Heq; try discriminate Heq; try reflexivity; right; reflexivity.
  - split; [reflexivity |].
    exists (mkOperantContingency OE_Reinforcement OO_Removal).
    repeat split; try intro Heq; try discriminate Heq; try reflexivity; left; reflexivity.
  - split; [reflexivity |].
    exists (mkOperantContingency OE_Punishment OO_Removal).
    repeat split; try intro Heq; try discriminate Heq; try reflexivity; right; reflexivity.
  - split; [reflexivity |].
    exists (mkOperantContingency OE_Reinforcement OO_Addition).
    repeat split; try intro Heq; try discriminate Heq; try reflexivity; left; reflexivity.
  - split; [reflexivity |].
    exists (mkOperantContingency OE_Reinforcement OO_Removal).
    repeat split; try intro Heq; try discriminate Heq; reflexivity.
  - split; [reflexivity |].
    exists (mkOperantContingency OE_Reinforcement OO_Addition).
    repeat split; try intro Heq; try discriminate Heq; reflexivity.
Qed.

(** [3/10] Pont Noyau Markovien (P2) -> Bifurcation punitive {P-, P+} *)
Theorem p2_markov_contagion_enters_operant_punishment :
  forall p : CircuitKernelParams,
    (0 < ckp_chi p)%N ->
    (0 < ckp_qPosC p)%N ->
    (ckp_qPosC p < ckp_scale p)%N ->
    (ckp_rho p + ckp_deltaA p < ckp_scale p)%N ->
    (0 < circuitWeight p (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_neg Pol_pos))%N /\
    (0 < circuitWeight p (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_neg Pol_neg))%N /\
    couplingToContingency (mkEngineCoupling Pol_neg Pol_zero) = None /\
    couplingToContingency (mkEngineCoupling Pol_neg Pol_pos) =
      Some (mkOperantContingency OE_Punishment OO_Removal) /\
    couplingToContingency (mkEngineCoupling Pol_neg Pol_neg) =
      Some (mkOperantContingency OE_Punishment OO_Addition).
Proof.
  intros p Hchi Hqpos Hqlt Hstay.
  destruct (axial_peur_bifurcates_p2 p Hchi Hqpos Hqlt Hstay) as [H1 H2].
  repeat split; try assumption; reflexivity.
Qed.

(** [4/10] Relèvement universel de la factorisation opérante sur toutes les strates Z *)
Theorem operant_quadrant_lifting_all_strata :
  forall p : CoreAffectPoint,
    pt_x p <> 0%Z ->
    pt_y p <> 0%Z ->
    (exists oc : OperantContingency,
      quadrantContingency (pt_x p) (pt_y p) = Some oc /\
      (oc_effect oc = OE_Reinforcement <-> (pt_x p > 0)%Z) /\
      (oc_effect oc = OE_Punishment <-> (pt_x p < 0)%Z) /\
      (oc_op oc = OO_Addition <-> (pt_x p * pt_y p > 0)%Z) /\
      (oc_op oc = OO_Removal <-> (pt_x p * pt_y p < 0)%Z) /\
      (computeHedonicPolarity (pt_x p) (pt_y p) = Hed_positive <->
        oc_effect oc = OE_Reinforcement) /\
      (oc_op oc = OO_Addition <->
        computeEnergyRegime (pt_x p) (pt_y p) = ER_positiveSynergy \/
        computeEnergyRegime (pt_x p) (pt_y p) = ER_negativeSynergy) /\
      (oc_op oc = OO_Removal <->
        computeEnergyRegime (pt_x p) (pt_y p) = ER_ergotropicCompensation \/
        computeEnergyRegime (pt_x p) (pt_y p) = ER_trophotropicRelease)) /\
    (forall q : CoreAffectPoint,
      In q z2DiagonalPoints ->
      quadrantContingency (pt_x q) (pt_y q) = diagToContingency q).
Proof.
  intros [x y z] Hx Hy; simpl in *.
  split.
  - destruct (Z_lt_le_dec 0 x) as [Hxp | Hxle];
    destruct (Z_lt_le_dec 0 y) as [Hyp | Hyle].
    + assert (Hxgt : (x > 0)%Z) by lia.
      assert (Hygt : (y > 0)%Z) by lia.
      exists (mkOperantContingency OE_Reinforcement OO_Addition).
      rewrite (quadrant_pos_pos x y Hxgt Hygt).
      rewrite (x_positive_determines_positive_valence x y Hxgt).
      rewrite (energy_pos_pos x y Hxgt Hygt).
      simpl. repeat split; try intro H;
        try reflexivity; try discriminate; try nia;
        try (left; reflexivity);
        try (destruct H as [H | H]; discriminate H).
    + assert (Hxgt : (x > 0)%Z) by lia.
      assert (Hylt : (y < 0)%Z) by lia.
      exists (mkOperantContingency OE_Reinforcement OO_Removal).
      rewrite (quadrant_pos_neg x y Hxgt Hylt).
      rewrite (x_positive_determines_positive_valence x y Hxgt).
      rewrite (energy_pos_neg x y Hxgt Hylt).
      simpl. repeat split; try intro H;
        try reflexivity; try discriminate; try nia;
        try (right; reflexivity);
        try (destruct H as [H | H]; discriminate H).
    + assert (Hxlt : (x < 0)%Z) by lia.
      assert (Hygt : (y > 0)%Z) by lia.
      exists (mkOperantContingency OE_Punishment OO_Removal).
      rewrite (quadrant_neg_pos x y Hxlt Hygt).
      rewrite (x_negative_determines_negative_valence x y Hxlt).
      rewrite (energy_neg_pos x y Hxlt Hygt).
      simpl. repeat split; try intro H;
        try reflexivity; try discriminate; try nia;
        try (left; reflexivity);
        try (destruct H as [H | H]; discriminate H).
    + assert (Hxlt : (x < 0)%Z) by lia.
      assert (Hylt : (y < 0)%Z) by lia.
      exists (mkOperantContingency OE_Punishment OO_Addition).
      rewrite (quadrant_neg_neg x y Hxlt Hylt).
      rewrite (x_negative_determines_negative_valence x y Hxlt).
      rewrite (energy_neg_neg x y Hxlt Hylt).
      simpl. repeat split; try intro H;
        try reflexivity; try discriminate; try nia;
        try (right; reflexivity);
        try (destruct H as [H | H]; discriminate H).
  - intros q Hq.
    destruct Hq as [<- | [<- | [<- | [<- | []]]]]; reflexivity.
Qed.

(** [5/10] Invariance antagoniste opérante sur toutes les strates Z *)
Theorem operant_antagonist_invariance_all_strata :
  forall p : CoreAffectPoint,
    pt_x p <> 0%Z ->
    pt_y p <> 0%Z ->
    exists c1 c2 : OperantContingency,
      quadrantContingency (pt_x p) (pt_y p) = Some c1 /\
      quadrantContingency (pt_x (antagonistPoint p)) (pt_y (antagonistPoint p)) = Some c2 /\
      oc_effect c1 <> oc_effect c2 /\
      oc_op c1 = oc_op c2.
Proof.
  intros p Hx Hy.
  destruct (Z_lt_le_dec 0 (pt_x p)) as [Hxp | Hxle];
  destruct (Z_lt_le_dec 0 (pt_y p)) as [Hyp | Hyle].
  - assert (Hxgt : (pt_x p > 0)%Z) by lia.
    assert (Hygt : (pt_y p > 0)%Z) by lia.
    pose proof (proj2 (antagonist_neg_x_iff p) Hxgt) as Hax.
    pose proof (proj2 (antagonist_neg_y_iff p) Hygt) as Hay.
    exists (mkOperantContingency OE_Reinforcement OO_Addition),
           (mkOperantContingency OE_Punishment OO_Addition).
    split; [apply quadrant_pos_pos; assumption |
      split; [apply quadrant_neg_neg; assumption |
        split; [discriminate | reflexivity]]].
  - assert (Hxgt : (pt_x p > 0)%Z) by lia.
    assert (Hylt : (pt_y p < 0)%Z) by lia.
    pose proof (proj2 (antagonist_neg_x_iff p) Hxgt) as Hax.
    pose proof (proj2 (antagonist_pos_y_iff p) Hylt) as Hay.
    exists (mkOperantContingency OE_Reinforcement OO_Removal),
           (mkOperantContingency OE_Punishment OO_Removal).
    split; [apply quadrant_pos_neg; assumption |
      split; [apply quadrant_neg_pos; assumption |
        split; [discriminate | reflexivity]]].
  - assert (Hxlt : (pt_x p < 0)%Z) by lia.
    assert (Hygt : (pt_y p > 0)%Z) by lia.
    pose proof (proj2 (antagonist_pos_x_iff p) Hxlt) as Hax.
    pose proof (proj2 (antagonist_neg_y_iff p) Hygt) as Hay.
    exists (mkOperantContingency OE_Punishment OO_Removal),
           (mkOperantContingency OE_Reinforcement OO_Removal).
    split; [apply quadrant_neg_pos; assumption |
      split; [apply quadrant_pos_neg; assumption |
        split; [discriminate | reflexivity]]].
  - assert (Hxlt : (pt_x p < 0)%Z) by lia.
    assert (Hylt : (pt_y p < 0)%Z) by lia.
    pose proof (proj2 (antagonist_pos_x_iff p) Hxlt) as Hax.
    pose proof (proj2 (antagonist_pos_y_iff p) Hylt) as Hay.
    exists (mkOperantContingency OE_Punishment OO_Addition),
           (mkOperantContingency OE_Reinforcement OO_Addition).
    split; [apply quadrant_neg_neg; assumption |
      split; [apply quadrant_pos_pos; assumption |
        split; [discriminate | reflexivity]]].
Qed.

(** [6/10] Pont Dynamique inter-strates <-> Opérants (canonicalDepthKernel) *)
Theorem depthKernel_preserves_operant_quadrant :
  (forall p q : CoreAffectPoint,
    pt_x p <> 0%Z ->
    pt_y p <> 0%Z ->
    dtk_weight canonicalDepthKernel p q > 0 ->
    pt_x q <> 0%Z /\
    pt_y q <> 0%Z /\
    quadrantContingency (pt_x q) (pt_y q) = quadrantContingency (pt_x p) (pt_y p)) /\
  (dtk_weight canonicalDepthKernel (mkPoint 2%Z 0%Z 2) (mkPoint 2%Z 2%Z 3) > 0 /\
   dtk_weight canonicalDepthKernel (mkPoint 2%Z 0%Z 2) (mkPoint 2%Z (-2)%Z 3) > 0 /\
   dtk_weight canonicalDepthKernel (mkPoint (-2)%Z 0%Z 2) (mkPoint (-2)%Z 2%Z 3) > 0 /\
   dtk_weight canonicalDepthKernel (mkPoint (-2)%Z 0%Z 2) (mkPoint (-2)%Z (-2)%Z 3) > 0 /\
   dtk_weight canonicalDepthKernel (mkPoint 0%Z 2%Z 2) (mkPoint 2%Z 2%Z 3) > 0 /\
   dtk_weight canonicalDepthKernel (mkPoint 0%Z 2%Z 2) (mkPoint (-2)%Z 2%Z 3) > 0 /\
   dtk_weight canonicalDepthKernel (mkPoint 0%Z (-2)%Z 2) (mkPoint 2%Z (-2)%Z 3) > 0 /\
   dtk_weight canonicalDepthKernel (mkPoint 0%Z (-2)%Z 2) (mkPoint (-2)%Z (-2)%Z 3) > 0).
Proof.
  split.
  - intros p q Hpx Hpy Hw.
    pose proof (dtk_quadrant_preserved canonicalDepthKernel p q ltac:(lia)) as [Hmx Hmy].
    pose proof (weight_pos_qx_nz p q Hpx Hpy Hw) as Hqx_nz.
    pose proof (weight_pos_qy_nz p q Hpx Hpy Hw) as Hqy_nz.
    refine (conj Hqx_nz (conj Hqy_nz _)).
    destruct (Z_lt_le_dec 0 (pt_x p)) as [Hxp | Hxle];
    destruct (Z_lt_le_dec 0 (pt_y p)) as [Hyp | Hyle].
    + assert (Hqx : (pt_x q > 0)%Z) by nia.
      assert (Hqy : (pt_y q > 0)%Z) by nia.
      rewrite (quadrant_pos_pos (pt_x q) (pt_y q) Hqx Hqy),
              (quadrant_pos_pos (pt_x p) (pt_y p) ltac:(lia) ltac:(lia)).
      reflexivity.
    + assert (Hqx : (pt_x q > 0)%Z) by nia.
      assert (Hqy : (pt_y q < 0)%Z) by nia.
      rewrite (quadrant_pos_neg (pt_x q) (pt_y q) Hqx Hqy),
              (quadrant_pos_neg (pt_x p) (pt_y p) ltac:(lia) ltac:(lia)).
      reflexivity.
    + assert (Hqx : (pt_x q < 0)%Z) by nia.
      assert (Hqy : (pt_y q > 0)%Z) by nia.
      rewrite (quadrant_neg_pos (pt_x q) (pt_y q) Hqx Hqy),
              (quadrant_neg_pos (pt_x p) (pt_y p) ltac:(lia) ltac:(lia)).
      reflexivity.
    + assert (Hqx : (pt_x q < 0)%Z) by nia.
      assert (Hqy : (pt_y q < 0)%Z) by nia.
      rewrite (quadrant_neg_neg (pt_x q) (pt_y q) Hqx Hqy),
              (quadrant_neg_neg (pt_x p) (pt_y p) ltac:(lia) ltac:(lia)).
      reflexivity.
  - vm_compute. repeat split; lia.
Qed.

(** [7/10] Lignées opérantes complètes Z = 2 -> Z = 7 (Sentiments transcendantaux) *)
Theorem operant_lineages_reach_z7_transcendentals :
  (* R+ : Désir (1,1,2) -> ... -> Sublimation (6,6,7) *)
  (dtk_weight canonicalDepthKernel (mkPoint 1%Z 1%Z 2) (mkPoint 2%Z 2%Z 3) = 2 /\
   dtk_weight canonicalDepthKernel (mkPoint 2%Z 2%Z 3) (mkPoint 3%Z 3%Z 4) = 2 /\
   dtk_weight canonicalDepthKernel (mkPoint 3%Z 3%Z 4) (mkPoint 4%Z 4%Z 5) = 2 /\
   dtk_weight canonicalDepthKernel (mkPoint 4%Z 4%Z 5) (mkPoint 5%Z 5%Z 6) = 2 /\
   dtk_weight canonicalDepthKernel (mkPoint 5%Z 5%Z 6) (mkPoint 6%Z 6%Z 7) = 2 /\
   classifyOperantRole (mkPoint 6%Z 6%Z 7) =
     OR_pureOperant (mkOperantContingency OE_Reinforcement OO_Addition) /\
   classifyStratum 7 = TS_z7_sentimentsTranscendants /\
   classifyTaxonomicGroup (mkPoint 6%Z 6%Z 7) = TG_groupeDesir /\
   classifySubsector 6%Z 6%Z = FS_diagonalDesire /\
   In (mkLexiconEntry "Sublimation" (mkPoint 6%Z 6%Z 7)) all176Entries) /\
  (* R- : Calme (1,-1,2) -> ... -> Impassibilité (6,-6,7) *)
  (dtk_weight canonicalDepthKernel (mkPoint 1%Z (-1)%Z 2) (mkPoint 2%Z (-2)%Z 3) = 2 /\
   dtk_weight canonicalDepthKernel (mkPoint 2%Z (-2)%Z 3) (mkPoint 3%Z (-3)%Z 4) = 2 /\
   dtk_weight canonicalDepthKernel (mkPoint 3%Z (-3)%Z 4) (mkPoint 4%Z (-4)%Z 5) = 2 /\
   dtk_weight canonicalDepthKernel (mkPoint 4%Z (-4)%Z 5) (mkPoint 5%Z (-5)%Z 6) = 2 /\
   dtk_weight canonicalDepthKernel (mkPoint 5%Z (-5)%Z 6) (mkPoint 6%Z (-6)%Z 7) = 2 /\
   classifyOperantRole (mkPoint 6%Z (-6)%Z 7) =
     OR_pureOperant (mkOperantContingency OE_Reinforcement OO_Removal) /\
   classifyStratum 7 = TS_z7_sentimentsTranscendants /\
   classifyTaxonomicGroup (mkPoint 6%Z (-6)%Z 7) = TG_groupeCalme /\
   classifySubsector 6%Z (-6)%Z = FS_diagonalCalm /\
   In (mkLexiconEntry "Impassibilité" (mkPoint 6%Z (-6)%Z 7)) all176Entries) /\
  (* P+ : Dégoût (-1,-1,2) -> ... -> Dissolution (-6,-6,7) *)
  (dtk_weight canonicalDepthKernel (mkPoint (-1)%Z (-1)%Z 2) (mkPoint (-2)%Z (-2)%Z 3) = 2 /\
   dtk_weight canonicalDepthKernel (mkPoint (-2)%Z (-2)%Z 3) (mkPoint (-3)%Z (-3)%Z 4) = 2 /\
   dtk_weight canonicalDepthKernel (mkPoint (-3)%Z (-3)%Z 4) (mkPoint (-4)%Z (-4)%Z 5) = 2 /\
   dtk_weight canonicalDepthKernel (mkPoint (-4)%Z (-4)%Z 5) (mkPoint (-5)%Z (-5)%Z 6) = 2 /\
   dtk_weight canonicalDepthKernel (mkPoint (-5)%Z (-5)%Z 6) (mkPoint (-6)%Z (-6)%Z 7) = 2 /\
   classifyOperantRole (mkPoint (-6)%Z (-6)%Z 7) =
     OR_pureOperant (mkOperantContingency OE_Punishment OO_Addition) /\
   classifyStratum 7 = TS_z7_sentimentsTranscendants /\
   classifyTaxonomicGroup (mkPoint (-6)%Z (-6)%Z 7) = TG_groupeDegout /\
   classifySubsector (-6)%Z (-6)%Z = FS_diagonalDisgust /\
   In (mkLexiconEntry "Dissolution" (mkPoint (-6)%Z (-6)%Z 7)) all176Entries) /\
  (* P- : Colère (-1,1,2) -> ... -> Rage (-6,6,7) *)
  (dtk_weight canonicalDepthKernel (mkPoint (-1)%Z 1%Z 2) (mkPoint (-2)%Z 2%Z 3) = 2 /\
   dtk_weight canonicalDepthKernel (mkPoint (-2)%Z 2%Z 3) (mkPoint (-3)%Z 3%Z 4) = 2 /\
   dtk_weight canonicalDepthKernel (mkPoint (-3)%Z 3%Z 4) (mkPoint (-4)%Z 4%Z 5) = 2 /\
   dtk_weight canonicalDepthKernel (mkPoint (-4)%Z 4%Z 5) (mkPoint (-5)%Z 5%Z 6) = 2 /\
   dtk_weight canonicalDepthKernel (mkPoint (-5)%Z 5%Z 6) (mkPoint (-6)%Z 6%Z 7) = 2 /\
   classifyOperantRole (mkPoint (-6)%Z 6%Z 7) =
     OR_pureOperant (mkOperantContingency OE_Punishment OO_Removal) /\
   classifyStratum 7 = TS_z7_sentimentsTranscendants /\
   classifyTaxonomicGroup (mkPoint (-6)%Z 6%Z 7) = TG_groupeColere /\
   classifySubsector (-6)%Z 6%Z = FS_diagonalAnger /\
   In (mkLexiconEntry "Rage" (mkPoint (-6)%Z 6%Z 7)) all176Entries).
Proof.
  repeat split;
    first [ vm_compute; reflexivity
          | apply mem_lexicon_of_existsb; vm_compute; reflexivity ].
Qed.

(** [8/10] Cohérence complète de la loi unifiée (R_t, Z_t, pi_A, pi_C) vers la Taxonomie, les opérants et le Lexique 176 *)
Theorem unified_circuit_to_taxonomy_coherence :
  forall (p : UnifiedDynamicsParams) (c : EngineCoupling)
         (z : nat) (rhoHat kappaHat : N) (susp : bool),
    let ts := evaluateUnifiedTaxonomy p c z rhoHat kappaHat susp in
    let cp := cas_point (ams_core (ts_matrix ts)) in
    let ap := cas_point (ams_antagonist (ts_matrix ts)) in
    isValidCoreAffect cp /\
    isValidCoreAffect ap /\
    ts_stratum ts = classifyStratum (pt_z cp) /\
    matchesTaxonomicGroup cp (ts_group ts) /\
    FunctionalSubsector_toTaxonomicGroup (ts_subsector ts) = ts_group ts /\
    FunctionalSubsector_toHedonicPolarity (ts_subsector ts) = ams_valence (ts_matrix ts) /\
    (z >= 2 -> quadrantContingency (pt_x cp) (pt_y cp) = couplingToContingency c) /\
    (z <= 7 -> In cp (map le_point all176Entries) /\ In ap (map le_point all176Entries)).
Proof.
  intros p c z rhoHat kappaHat susp.
  cbv zeta.
  unfold evaluateUnifiedTaxonomy, evaluateTaxonomy, evaluateMatrix, canonicalMapping; simpl.
  pose proof (projectUnifiedState_valid p c z rhoHat kappaHat susp) as Hvc.
  pose proof (antagonistPoint_preserves_validity _ Hvc) as Hva.
  refine (conj Hvc (conj Hva (conj eq_refl (conj (classifyTaxonomicGroup_correct _)
    (conj (classifySubsector_refines_group _)
      (conj (classifySubsector_determines_valence _ _) (conj _ _))))))).
  - intro Hz.
    destruct z as [| [| d]]; [lia | lia |].
    unfold projectUnifiedState, projectPerceptibleState; simpl.
    replace (S (S d)) with (d + 2) by lia.
    apply projectPerceptible_quadrant_eq.
  - intro Hz7.
    assert (Hcz : pt_z (cas_point (projectUnifiedState p c z rhoHat kappaHat susp)) <= 7).
    { unfold projectUnifiedState, projectPerceptibleState; simpl.
      eapply Nat.le_trans; [apply projectPerceptible_z_le | exact Hz7]. }
    assert (Haz : pt_z (antagonistPoint (cas_point (projectUnifiedState p c z rhoHat kappaHat susp))) <= 7).
    { rewrite antagonistPoint_preserves_z. exact Hcz. }
    split.
    + apply all176Entries_spatial_completeness; assumption.
    + apply all176Entries_spatial_completeness; assumption.
Qed.

(** [9/10] Cohérence complète du circuit continu fermé à 6 opérateurs (CircularCircuitState) *)
Theorem circularCycle_to_taxonomy_and_lexicon_coherence :
  forall s : CircularCircuitState,
    let ts := evaluateCircularTaxonomy s in
    let cp := cas_point (ams_core (ts_matrix ts)) in
    let ap := cas_point (ams_antagonist (ts_matrix ts)) in
    let c := mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s) in
    isValidCoreAffect cp /\
    isValidCoreAffect ap /\
    matchesTaxonomicGroup cp (ts_group ts) /\
    FunctionalSubsector_toTaxonomicGroup (ts_subsector ts) = ts_group ts /\
    FunctionalSubsector_toHedonicPolarity (ts_subsector ts) = ams_valence (ts_matrix ts) /\
    (AttentionalInterface_isEngaged (ccs_attentional s) = true ->
      quadrantContingency (pt_x cp) (pt_y cp) = couplingToContingency c) /\
    (ai_persistenceDepth (ccs_attentional s) <= 5 ->
      pt_z cp <= 7 /\
      In cp (map le_point all176Entries) /\
      In ap (map le_point all176Entries)).
Proof.
  intro s. cbv zeta.
  unfold evaluateCircularTaxonomy, evaluateTaxonomy, evaluateMatrix, canonicalMapping; simpl.
  pose proof (cas_valid (snd (op3_crossingI_perceptible s))) as Hvc.
  pose proof (antagonistPoint_preserves_validity _ Hvc) as Hva.
  refine (conj Hvc (conj Hva (conj (classifyTaxonomicGroup_correct _)
    (conj (classifySubsector_refines_group _)
      (conj (classifySubsector_determines_valence _ _)
        (conj (op3_point_engaged_quadrant s) _)))))).
  intro Hd.
  pose proof (op3_point_z_le s Hd) as Hcz.
  assert (Haz : pt_z (antagonistPoint (cas_point (snd (op3_crossingI_perceptible s)))) <= 7).
  { rewrite antagonistPoint_preserves_z. exact Hcz. }
  refine (conj Hcz (conj _ _)).
  - apply all176Entries_spatial_completeness; assumption.
  - apply all176Entries_spatial_completeness; assumption.
Qed.

(** [10/10] THÉORÈME COMPLET DE BOUT EN BOUT (Moteur -> Noyau -> Matrice -> Opérants -> Taxonomie -> Lexique 176) *)
Theorem full_end_to_end_lexicon_resolution :
  forall s : PredictiveEngineState,
    pt_z (projectToCoreAffect s) <= 7 ->
    let ts := runCartograffectPipeline s in
    let cp := cas_point (ams_core (ts_matrix ts)) in
    let ap := cas_point (ams_antagonist (ts_matrix ts)) in
    isCoherentTerminalState s ts /\
    (forall ts' : TaxonomicState, isCoherentTerminalState s ts' -> ts' = ts) /\
    (exists e : LexiconEntry,
      In e all176Entries /\ le_point e = cp /\
      forall e' : LexiconEntry, In e' all176Entries -> le_point e' = cp -> e' = e) /\
    (exists ae : LexiconEntry,
      In ae all176Entries /\ le_point ae = ap /\
      forall ae' : LexiconEntry, In ae' all176Entries -> le_point ae' = ap -> ae' = ae) /\
    (pt_x cp <> 0%Z -> pt_y cp <> 0%Z ->
      exists c1 c2 : OperantContingency,
        quadrantContingency (pt_x cp) (pt_y cp) = Some c1 /\
        quadrantContingency (pt_x ap) (pt_y ap) = Some c2 /\
        oc_effect c1 <> oc_effect c2 /\
        oc_op c1 = oc_op c2).
Proof.
  intros s Hz. cbv zeta.
  destruct (end_to_end_coherence s) as [ts0 [Hcoh0 Huniq0]].
  pose proof (Huniq0 (runCartograffectPipeline s) (runCartograffectPipeline_coherent s)) as Hts_eq.
  subst ts0.
  pose proof Hcoh0 as Hcoh_copy.
  destruct Hcoh_copy as [Hcp_eq [Hvc [Hap_eq [Hva _]]]].
  set (cp := cas_point (ams_core (ts_matrix (runCartograffectPipeline s)))) in *.
  set (ap := cas_point (ams_antagonist (ts_matrix (runCartograffectPipeline s)))) in *.
  assert (Hcp_z : pt_z cp <= 7) by (rewrite Hcp_eq; exact Hz).
  assert (Hap_z : pt_z ap <= 7) by (rewrite Hap_eq, antagonistPoint_preserves_z; exact Hcp_z).
  pose proof (all176Entries_spatial_completeness cp Hcp_z Hvc) as Hmem_cp.
  pose proof (all176Entries_spatial_completeness ap Hap_z Hva) as Hmem_ap.
  apply in_map_iff in Hmem_cp. destruct Hmem_cp as [e [He_pt He_mem]].
  apply in_map_iff in Hmem_ap. destruct Hmem_ap as [ae [Hae_pt Hae_mem]].
  refine (conj Hcoh0 (conj Huniq0 (conj _ (conj _ _)))).
  - exists e. refine (conj He_mem (conj He_pt _)).
    intros e' He' Hpt'.
    apply (nodup_map_inj LexiconEntry CoreAffectPoint le_point all176Entries
             all176Entries_unique_points e' e He' He_mem).
    transitivity cp; [exact Hpt' | symmetry; exact He_pt].
  - exists ae. refine (conj Hae_mem (conj Hae_pt _)).
    intros ae' Hae' Hpt'.
    apply (nodup_map_inj LexiconEntry CoreAffectPoint le_point all176Entries
             all176Entries_unique_points ae' ae Hae' Hae_mem).
    transitivity ap; [exact Hpt' | symmetry; exact Hae_pt].
  - intros Hx Hy.
    rewrite Hap_eq.
    apply operant_antagonist_invariance_all_strata; assumption.
Qed.

(** ** 4. Audit axiomatique (Print Assumptions — 10/10 ponts + all176Entries_unique_labels) *)
Print Assumptions all176Entries_unique_labels.
Print Assumptions circuit_coupling_operant_bridge.
Print Assumptions triggerSecondaryGradient_enters_operant.
Print Assumptions p2_markov_contagion_enters_operant_punishment.
Print Assumptions operant_quadrant_lifting_all_strata.
Print Assumptions operant_antagonist_invariance_all_strata.
Print Assumptions depthKernel_preserves_operant_quadrant.
Print Assumptions operant_lineages_reach_z7_transcendentals.
Print Assumptions unified_circuit_to_taxonomy_coherence.
Print Assumptions circularCycle_to_taxonomy_and_lexicon_coherence.
Print Assumptions full_end_to_end_lexicon_resolution.
