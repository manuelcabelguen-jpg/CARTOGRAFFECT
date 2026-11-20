(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*)

From Stdlib Require Import Bool Arith PeanoNat NArith ZArith Lia List.
Import ListNotations.
Require Import CartograffectRocq.PredictiveEngine.
Require Import CartograffectRocq.CoreAffect.
Require Import CartograffectRocq.AffectiveMatrix.

Open Scope bool_scope.
Open Scope nat_scope.

(** * Module PredictiveCircuit — Validation Rocq 9.1.0 *)

(** ** 1. Les deux boucles à trois circuits et les six opérations de frontière *)

Inductive CircuitLoop : Type :=
  | CL_expectationLoop : CircuitLoop
  | CL_controlLoop     : CircuitLoop.

Inductive InterfaceSide : Type :=
  | IS_internal : InterfaceSide
  | IS_external : InterfaceSide.

Inductive CircuitOperation : Type :=
  | CO_subjectiveOut         : CircuitOperation
  | CO_perceptiveOut         : CircuitOperation
  | CO_attentionalCrossingI  : CircuitOperation
  | CO_attentionalCrossingII : CircuitOperation
  | CO_subjectiveIn          : CircuitOperation
  | CO_perceptiveIn          : CircuitOperation.

Definition allCircuitOperations : list CircuitOperation := [
  CO_subjectiveOut;
  CO_perceptiveOut;
  CO_attentionalCrossingI;
  CO_attentionalCrossingII;
  CO_subjectiveIn;
  CO_perceptiveIn
].

Definition CircuitOperation_carrierInterface (op : CircuitOperation) : EngineInterface :=
  match op with
  | CO_subjectiveOut         => EI_subjective
  | CO_subjectiveIn          => EI_subjective
  | CO_perceptiveOut         => EI_perceptive
  | CO_perceptiveIn          => EI_perceptive
  | CO_attentionalCrossingI  => EI_attentional
  | CO_attentionalCrossingII => EI_attentional
  end.

Definition CircuitOperation_side (op : CircuitOperation) : InterfaceSide :=
  match op with
  | CO_subjectiveOut         => IS_internal
  | CO_perceptiveOut         => IS_internal
  | CO_attentionalCrossingI  => IS_internal
  | CO_attentionalCrossingII => IS_external
  | CO_subjectiveIn          => IS_external
  | CO_perceptiveIn          => IS_external
  end.

Definition CircuitOperation_isAgentPerceptible (op : CircuitOperation) : bool :=
  match op with
  | CO_attentionalCrossingI => true
  | _                       => false
  end.

Definition CircuitOperation_toInferentialOperation (op : CircuitOperation) : InferentialOperation :=
  match op with
  | CO_subjectiveOut         => IO_contextualGenerative
  | CO_subjectiveIn          => IO_contextualGenerative
  | CO_perceptiveOut         => IO_actionImplementation
  | CO_perceptiveIn          => IO_ascendingSensory
  | CO_attentionalCrossingI  => IO_integrativeWeighting
  | CO_attentionalCrossingII => IO_integrativeWeighting
  end.

Theorem allCircuitOperations_card : length allCircuitOperations = 6.
Proof. reflexivity. Qed.

Theorem mem_allCircuitOperations :
  forall op : CircuitOperation, In op allCircuitOperations.
Proof.
  intros []; unfold allCircuitOperations; simpl; tauto.
Qed.

Theorem circuit_covers_interfaces_both_sides :
  forall (iface : EngineInterface) (s : InterfaceSide),
    exists op : CircuitOperation,
      CircuitOperation_carrierInterface op = iface /\
      CircuitOperation_side op = s /\
      forall op',
        CircuitOperation_carrierInterface op' = iface ->
        CircuitOperation_side op' = s ->
        op' = op.
Proof.
  intros [] [];
    [exists CO_perceptiveOut | exists CO_perceptiveIn |
     exists CO_subjectiveOut | exists CO_subjectiveIn |
     exists CO_attentionalCrossingI | exists CO_attentionalCrossingII];
    repeat split; try reflexivity;
    intros [] H1 H2; try reflexivity; discriminate.
Qed.

Theorem circuit_refines_inferential_ops :
  forall iop : InferentialOperation,
    exists op : CircuitOperation, CircuitOperation_toInferentialOperation op = iop.
Proof.
  intros [].
  - exists CO_perceptiveIn; reflexivity.
  - exists CO_perceptiveOut; reflexivity.
  - exists CO_subjectiveOut; reflexivity.
  - exists CO_attentionalCrossingI; reflexivity.
Qed.

Theorem circuit_preserves_carrier :
  forall op : CircuitOperation,
    InferentialOperation_carrierInterface (CircuitOperation_toInferentialOperation op) =
    CircuitOperation_carrierInterface op.
Proof.
  intros []; reflexivity.
Qed.

Theorem unique_agent_perceptible_crossing :
  forall op : CircuitOperation,
    CircuitOperation_isAgentPerceptible op = true <-> op = CO_attentionalCrossingI.
Proof.
  intros []; simpl; split; intro H; try reflexivity; try discriminate.
Qed.

(** ** 2. Bijection L1 Phi : Omega_II <-> Omega_I, transposition I <-> II et 9 canaux *)

Record ProtoSpatialNode : Type := mkProtoSpatialNode {
  psn_x : Z;
  psn_y : Z
}.

Definition defaultProtoSpatialNode : ProtoSpatialNode := mkProtoSpatialNode 0%Z 0%Z.

Definition ProtoSpatialNode_l1Norm (n : ProtoSpatialNode) : nat :=
  Z.abs_nat (psn_x n) + Z.abs_nat (psn_y n).

Definition isValidProtoSpatial (n : ProtoSpatialNode) : Prop :=
  (psn_x n = 0%Z /\ psn_y n = 0%Z) \/ ProtoSpatialNode_l1Norm n = 2.

Definition phiL1 (c : EngineCoupling) : ProtoSpatialNode :=
  match ec_attente c, ec_controle c with
  | Pol_zero, Pol_zero => mkProtoSpatialNode 0%Z 0%Z
  | Pol_pos,  Pol_zero => mkProtoSpatialNode 2%Z 0%Z
  | Pol_neg,  Pol_zero => mkProtoSpatialNode (-2)%Z 0%Z
  | Pol_zero, Pol_pos  => mkProtoSpatialNode 0%Z 2%Z
  | Pol_zero, Pol_neg  => mkProtoSpatialNode 0%Z (-2)%Z
  | Pol_pos,  Pol_pos  => mkProtoSpatialNode 1%Z 1%Z
  | Pol_pos,  Pol_neg  => mkProtoSpatialNode 1%Z (-1)%Z
  | Pol_neg,  Pol_pos  => mkProtoSpatialNode (-1)%Z 1%Z
  | Pol_neg,  Pol_neg  => mkProtoSpatialNode (-1)%Z (-1)%Z
  end.

Definition polarityOfInt (v : Z) : Polarity :=
  if (0 <? v)%Z then Pol_pos else if (v <? 0)%Z then Pol_neg else Pol_zero.

Definition phiL1Inv (n : ProtoSpatialNode) : EngineCoupling :=
  mkEngineCoupling (polarityOfInt (psn_x n)) (polarityOfInt (psn_y n)).

Definition idxAttente (p : Polarity) : nat :=
  match p with
  | Pol_zero => 0
  | Pol_neg  => 1
  | Pol_pos  => 2
  end.

Definition idxControle (p : Polarity) : nat :=
  match p with
  | Pol_pos  => 0
  | Pol_neg  => 1
  | Pol_zero => 2
  end.

Definition crossingIPos (c : EngineCoupling) : nat * nat :=
  (idxAttente (ec_attente c), idxControle (ec_controle c)).

Definition crossingIIPos (c : EngineCoupling) : nat * nat :=
  (idxControle (ec_controle c), idxAttente (ec_attente c)).

Record SubjectiveReturnChannel : Type := mkSubjectiveReturnChannel {
  src_regimeA  : FunctionalRegime;
  src_contextC : Polarity
}.

Record PerceptiveReturnChannel : Type := mkPerceptiveReturnChannel {
  prc_regimeC  : FunctionalRegime;
  prc_contextA : Polarity
}.

Definition routeToSubjective (c : EngineCoupling) : SubjectiveReturnChannel :=
  mkSubjectiveReturnChannel (Polarity_toRegime (ec_attente c)) (ec_controle c).

Definition routeToPerceptive (c : EngineCoupling) : PerceptiveReturnChannel :=
  mkPerceptiveReturnChannel (Polarity_toRegime (ec_controle c)) (ec_attente c).

Theorem phiL1_valid :
  forall c : EngineCoupling, isValidProtoSpatial (phiL1 c).
Proof.
  intros [[] []]; unfold isValidProtoSpatial, ProtoSpatialNode_l1Norm, phiL1; simpl;
    first [left; split; reflexivity | right; reflexivity].
Qed.

Theorem phiL1_l1Norm_active :
  forall c : EngineCoupling,
    EngineCoupling_isGlobalNeutrality c = false ->
    ProtoSpatialNode_l1Norm (phiL1 c) = 2.
Proof.
  intros [[] []] H; try discriminate; reflexivity.
Qed.

Theorem phiL1_left_inv :
  forall c : EngineCoupling, phiL1Inv (phiL1 c) = c.
Proof.
  intros [[] []]; reflexivity.
Qed.

Theorem phiL1_right_inv :
  forall n : ProtoSpatialNode, isValidProtoSpatial n -> phiL1 (phiL1Inv n) = n.
Proof.
  intros [x y] [[Hx Hy] | Hl]; unfold ProtoSpatialNode_l1Norm in *; simpl in *.
  - subst x y. reflexivity.
  - assert (Hx_cases : x = (-2)%Z \/ x = (-1)%Z \/ x = 0%Z \/ x = 1%Z \/ x = 2%Z) by lia.
    assert (Hy_cases : y = (-2)%Z \/ y = (-1)%Z \/ y = 0%Z \/ y = 1%Z \/ y = 2%Z) by lia.
    destruct Hx_cases as [-> | [-> | [-> | [-> | ->]]]];
    destruct Hy_cases as [-> | [-> | [-> | [-> | ->]]]];
      simpl in Hl; try lia; reflexivity.
Qed.

Theorem phiL1_agrees_with_deployZ2 :
  forall c : EngineCoupling,
    psn_x (phiL1 c) = pt_x (deployCouplingAtDepth c 0) /\
    psn_y (phiL1 c) = pt_y (deployCouplingAtDepth c 0).
Proof.
  intros [[] []]; split; reflexivity.
Qed.

Theorem crossingII_is_transpose_of_crossingI :
  forall c : EngineCoupling,
    crossingIIPos c = (snd (crossingIPos c), fst (crossingIPos c)).
Proof.
  intro c; reflexivity.
Qed.

Theorem routeToSubjective_injective :
  forall c1 c2 : EngineCoupling, routeToSubjective c1 = routeToSubjective c2 -> c1 = c2.
Proof.
  intros [[] []] [[] []] H; inversion H; reflexivity.
Qed.

Theorem routeToPerceptive_injective :
  forall c1 c2 : EngineCoupling, routeToPerceptive c1 = routeToPerceptive c2 -> c1 = c2.
Proof.
  intros [[] []] [[] []] H; inversion H; reflexivity.
Qed.

(** ** 3. Projection perceptible Pi_Z certifiée dans CoreAffectState *)

Definition projectPerceptible (c : EngineCoupling) (z piA piC : nat) (descendingSusp : bool)
    : CoreAffectPoint :=
  if EngineCoupling_isGlobalNeutrality c then
    if descendingSusp && Nat.leb 2 z then mkPoint 0%Z 0%Z z else mkPoint 0%Z 0%Z 0
  else
    match z with
    | 0          => mkPoint 0%Z 0%Z 0
    | 1          => mkPoint 0%Z 0%Z 1
    | S (S d)    => deployCouplingWithPrecision c d piA piC
    end.

Theorem projectPerceptible_valid :
  forall (c : EngineCoupling) (z piA piC : nat) (susp : bool),
    isValidCoreAffect (projectPerceptible c z piA piC susp).
Proof.
  intros c z piA piC susp.
  unfold projectPerceptible.
  destruct (EngineCoupling_isGlobalNeutrality c).
  - destruct (susp && Nat.leb 2 z); left; split; reflexivity.
  - destruct z as [| [| d]].
    + left; split; reflexivity.
    + left; split; reflexivity.
    + apply deployCouplingWithPrecision_valid.
Qed.

Definition projectPerceptibleState (c : EngineCoupling) (z piA piC : nat) (descendingSusp : bool)
    : CoreAffectState :=
  mkCoreAffectState (projectPerceptible c z piA piC descendingSusp)
    (projectPerceptible_valid c z piA piC descendingSusp).

Theorem projectPerceptible_z2_matches_phiL1 :
  forall (c : EngineCoupling) (piA piC : nat) (susp : bool),
    EngineCoupling_isGlobalNeutrality c = false ->
    projectPerceptible c 2 piA piC susp = mkPoint (psn_x (phiL1 c)) (psn_y (phiL1 c)) 2.
Proof.
  intros [a ctrl] piA piC susp H.
  destruct a; destruct ctrl;
    try (simpl in H; discriminate);
    unfold projectPerceptible, deployCouplingWithPrecision, phiL1, signedAmplitude; simpl;
    try rewrite apportionRay_z2; reflexivity.
Qed.

Theorem projectPerceptible_neutral_elevates_to_central :
  forall (z piA piC : nat),
    z >= 2 ->
    projectPerceptible (mkEngineCoupling Pol_zero Pol_zero) z piA piC true = mkPoint 0%Z 0%Z z.
Proof.
  intros z piA piC Hz.
  unfold projectPerceptible. cbn [EngineCoupling_isGlobalNeutrality Polarity_isEngaged ec_attente ec_controle andb negb].
  destruct (Nat.leb_spec0 2 z); [reflexivity | lia].
Qed.

(** ** 4. Goulot attentionnel L1, potentiel de Lyapunov V et cohérence interne/externe *)

Definition attentionalWeightX2 (c : EngineCoupling) : nat :=
  if Polarity_eqb (ec_attente c) Pol_zero then 2 else Z.abs_nat (psn_x (phiL1 c)).

Definition attentionalWeightY2 (c : EngineCoupling) : nat :=
  if Polarity_eqb (ec_controle c) Pol_zero then 2 else Z.abs_nat (psn_y (phiL1 c)).

Definition polarityEnergy (p : Polarity) : nat :=
  match p with
  | Pol_zero => 0
  | Pol_pos  => 1
  | Pol_neg  => 2
  end.

Definition lyapunovPotential (c : EngineCoupling) : nat :=
  polarityEnergy (ec_attente c) + polarityEnergy (ec_controle c).

Inductive InternalExternalCoherence : Type :=
  | IEC_homeostaticEquilibrium : InternalExternalCoherence
  | IEC_axialUnilateral        : InternalExternalCoherence
  | IEC_congruentDischarge     : InternalExternalCoherence
  | IEC_compensatoryTension    : InternalExternalCoherence
  | IEC_doubleChargeImpasse    : InternalExternalCoherence.

Definition classifyCoherence (c : EngineCoupling) : InternalExternalCoherence :=
  match ec_attente c, ec_controle c with
  | Pol_zero, Pol_zero => IEC_homeostaticEquilibrium
  | Pol_zero, _        => IEC_axialUnilateral
  | _,        Pol_zero => IEC_axialUnilateral
  | Pol_pos,  Pol_pos  => IEC_congruentDischarge
  | Pol_neg,  Pol_neg  => IEC_doubleChargeImpasse
  | _,        _        => IEC_compensatoryTension
  end.

Theorem attentional_bottleneck_sum_active :
  forall c : EngineCoupling,
    EngineCoupling_isGlobalNeutrality c = false ->
    (if Polarity_isEngaged (ec_attente c) then attentionalWeightX2 c else 0) +
    (if Polarity_isEngaged (ec_controle c) then attentionalWeightY2 c else 0) = 2.
Proof.
  intros [[] []] H; try discriminate; reflexivity.
Qed.

Theorem lyapunovPotential_zero_iff :
  forall c : EngineCoupling,
    lyapunovPotential c = 0 <-> c = mkEngineCoupling Pol_zero Pol_zero.
Proof.
  intros [[] []]; simpl; split; intro H; try reflexivity; try discriminate; inversion H.
Qed.

Theorem lyapunovPotential_le_four :
  forall c : EngineCoupling, lyapunovPotential c <= 4.
Proof.
  intros [[] []]; compute; lia.
Qed.

Theorem lyapunovPotential_max_iff :
  forall c : EngineCoupling,
    lyapunovPotential c = 4 <-> c = mkEngineCoupling Pol_neg Pol_neg.
Proof.
  intros [[] []]; simpl; split; intro H; try reflexivity; try discriminate; inversion H.
Qed.

(** ** 5. Noyau markovien couplé exact du circuit continu (entiers binaires N) *)

Definition attentionalWeightX2_N (c : EngineCoupling) : N :=
  N.of_nat (attentionalWeightX2 c).

Definition attentionalWeightY2_N (c : EngineCoupling) : N :=
  N.of_nat (attentionalWeightY2 c).

Definition lyapunovPotential_N (c : EngineCoupling) : N :=
  N.of_nat (lyapunovPotential c).

Definition isCharged (p : Polarity) : bool :=
  match p with
  | Pol_neg => true
  | _       => false
  end.

Record CircuitKernelParams : Type := mkCircuitKernelParams {
  ckp_scale     : N;
  ckp_rho       : N;
  ckp_kappa     : N;
  ckp_deltaA    : N;
  ckp_deltaC    : N;
  ckp_gammaA    : N;
  ckp_gammaC    : N;
  ckp_epsilon   : N;
  ckp_qPosA     : N;
  ckp_qPosC     : N;
  ckp_chi       : N;
  ckp_scale_pos : (0 < ckp_scale)%N;
  ckp_rho_le    : (ckp_rho <= ckp_scale)%N;
  ckp_kap_le    : (ckp_kappa <= ckp_scale)%N;
  ckp_da_le     : (ckp_deltaA <= ckp_scale)%N;
  ckp_dc_le     : (ckp_deltaC <= ckp_scale)%N;
  ckp_rho_da_le : (ckp_rho + ckp_deltaA <= ckp_scale)%N;
  ckp_kap_dc_le : (ckp_kappa + ckp_deltaC <= ckp_scale)%N;
  ckp_ga_le     : (ckp_gammaA <= ckp_scale)%N;
  ckp_gc_le     : (ckp_gammaC <= ckp_scale)%N;
  ckp_eps_le    : (ckp_epsilon <= ckp_scale)%N;
  ckp_qa_le     : (ckp_qPosA <= ckp_scale)%N;
  ckp_qc_le     : (ckp_qPosC <= ckp_scale)%N;
  ckp_chi_le    : (ckp_chi <= ckp_scale)%N
}.

Definition defaultCircuitKernelParams : CircuitKernelParams.
Proof.
  refine {|
    ckp_scale   := 100%N;
    ckp_rho     := 80%N;
    ckp_kappa   := 80%N;
    ckp_deltaA  := 0%N;
    ckp_deltaC  := 0%N;
    ckp_gammaA  := 70%N;
    ckp_gammaC  := 70%N;
    ckp_epsilon := 15%N;
    ckp_qPosA   := 35%N;
    ckp_qPosC   := 35%N;
    ckp_chi     := 25%N
  |}; lia.
Defined.

Definition effectiveEpsScaled (M eps chi : N) (otherCharged : bool) : N :=
  if otherCharged then (M * eps + chi * (M - eps))%N else (M * eps)%N.

Lemma effectiveEpsScaled_le :
  forall (M eps chi : N) (otherCharged : bool),
    (eps <= M)%N -> (chi <= M)%N ->
    (effectiveEpsScaled M eps chi otherCharged <= M * M)%N.
Proof.
  intros M eps chi [] Heps Hchi; unfold effectiveEpsScaled; nia.
Qed.

Lemma effectiveEpsScaled_sub_pos :
  forall (M eps chi : N) (otherCharged : bool),
    (eps < M)%N -> (chi < M)%N ->
    (0 < M * M - effectiveEpsScaled M eps chi otherCharged)%N.
Proof.
  intros M eps chi [] Heps Hchi; unfold effectiveEpsScaled; nia.
Qed.

Definition marginalWeight (M rate delta deseng eps qPos chi : N)
    (otherCharged : bool) (w2 : N) (src dst : Polarity) : N :=
  let e2 := effectiveEpsScaled M eps chi otherCharged in
  match src, dst with
  | Pol_zero, Pol_zero => (2 * M * (M * M - e2))%N
  | Pol_zero, Pol_neg  => (2 * e2 * (M - qPos))%N
  | Pol_zero, Pol_pos  => (2 * e2 * qPos)%N
  | Pol_neg,  Pol_zero => (M * M * (2 * delta))%N
  | Pol_neg,  Pol_neg  => (M * M * (2 * M - w2 * rate - 2 * delta))%N
  | Pol_neg,  Pol_pos  => (M * M * (w2 * rate))%N
  | Pol_pos,  Pol_zero => ((M * M - e2) * (w2 * deseng))%N
  | Pol_pos,  Pol_neg  => (2 * M * e2)%N
  | Pol_pos,  Pol_pos  => ((M * M - e2) * (2 * M - w2 * deseng))%N
  end.

Definition circuitWeight (p : CircuitKernelParams) (src dst : EngineCoupling) : N :=
  let mwA := marginalWeight (ckp_scale p) (ckp_rho p) (ckp_deltaA p) (ckp_gammaA p)
               (ckp_epsilon p) (ckp_qPosA p) (ckp_chi p)
               (isCharged (ec_controle src)) (attentionalWeightX2_N src)
               (ec_attente src) (ec_attente dst) in
  let mwC := marginalWeight (ckp_scale p) (ckp_kappa p) (ckp_deltaC p) (ckp_gammaC p)
               (ckp_epsilon p) (ckp_qPosC p) (ckp_chi p)
               (isCharged (ec_attente src)) (attentionalWeightY2_N src)
               (ec_controle src) (ec_controle dst) in
  (mwA * mwC)%N.

Definition circuitRowSum (p : CircuitKernelParams) (src : EngineCoupling) : N :=
  fold_left N.add (map (circuitWeight p src) allCouplings) 0%N.

Lemma attentionalWeightX2_N_le_two :
  forall c : EngineCoupling, (attentionalWeightX2_N c <= 2)%N.
Proof.
  intros [[] []]; unfold attentionalWeightX2_N, attentionalWeightX2; simpl; lia.
Qed.

Lemma attentionalWeightY2_N_le_two :
  forall c : EngineCoupling, (attentionalWeightY2_N c <= 2)%N.
Proof.
  intros [[] []]; unfold attentionalWeightY2_N, attentionalWeightY2; simpl; lia.
Qed.

Lemma attentionalWeightX2_N_pos :
  forall c : EngineCoupling, (0 < attentionalWeightX2_N c)%N.
Proof.
  intros [[] []]; unfold attentionalWeightX2_N, attentionalWeightX2; simpl; lia.
Qed.

Lemma attentionalWeightY2_N_pos :
  forall c : EngineCoupling, (0 < attentionalWeightY2_N c)%N.
Proof.
  intros [[] []]; unfold attentionalWeightY2_N, attentionalWeightY2; simpl; lia.
Qed.

Lemma N_pow_5 : forall m : N, (m ^ 5 = m * m * m * m * m)%N.
Proof.
  intro m. change 5%N with (1 + (1 + (1 + (1 + 1))))%N.
  rewrite !N.pow_add_r, N.pow_1_r. lia.
Qed.

Lemma N_pow_6 : forall m : N, (m ^ 6 = m * m * m * m * m * m)%N.
Proof.
  intro m. change 6%N with (1 + (1 + (1 + (1 + (1 + 1)))))%N.
  rewrite !N.pow_add_r, N.pow_1_r. lia.
Qed.

Lemma marginalWeight_sum :
  forall (M rate delta deseng eps qPos chi : N) (otherCharged : bool) (w2 : N) (src : Polarity),
    (rate + delta <= M)%N -> (deseng <= M)%N ->
    (eps <= M)%N -> (qPos <= M)%N -> (chi <= M)%N -> (w2 <= 2)%N ->
    (marginalWeight M rate delta deseng eps qPos chi otherCharged w2 src Pol_zero +
     marginalWeight M rate delta deseng eps qPos chi otherCharged w2 src Pol_neg +
     marginalWeight M rate delta deseng eps qPos chi otherCharged w2 src Pol_pos =
     2 * M * M * M)%N.
Proof.
  intros M rate delta deseng eps qPos chi otherCharged w2 src Hrd Hdes Heps Hq Hchi Hw2.
  pose proof (effectiveEpsScaled_le M eps chi otherCharged Heps Hchi) as He2.
  assert (Hw2r : (w2 * rate + 2 * delta <= 2 * M)%N) by nia.
  assert (Hw2d : (w2 * deseng <= 2 * M)%N) by nia.
  destruct src; unfold marginalWeight; cbv zeta;
    generalize (effectiveEpsScaled M eps chi otherCharged) He2; intros e2 He2'; nia.
Qed.

Theorem circuitRowSum_exact :
  forall (p : CircuitKernelParams) (src : EngineCoupling),
    circuitRowSum p src = (4 * ckp_scale p ^ 6)%N.
Proof.
  intros p src.
  unfold circuitRowSum, allCouplings, circuitWeight; cbv zeta;
    cbn [fold_left map ec_attente ec_controle].
  set (fA := marginalWeight (ckp_scale p) (ckp_rho p) (ckp_deltaA p) (ckp_gammaA p)
               (ckp_epsilon p) (ckp_qPosA p) (ckp_chi p)
               (isCharged (ec_controle src)) (attentionalWeightX2_N src) (ec_attente src)).
  set (fC := marginalWeight (ckp_scale p) (ckp_kappa p) (ckp_deltaC p) (ckp_gammaC p)
               (ckp_epsilon p) (ckp_qPosC p) (ckp_chi p)
               (isCharged (ec_attente src)) (attentionalWeightY2_N src) (ec_controle src)).
  assert (Hfact :
    (((((((((0 + fA Pol_zero * fC Pol_zero) + fA Pol_pos * fC Pol_zero) + fA Pol_neg * fC Pol_zero) +
        fA Pol_zero * fC Pol_pos) + fA Pol_zero * fC Pol_neg) + fA Pol_pos * fC Pol_pos) +
        fA Pol_pos * fC Pol_neg) + fA Pol_neg * fC Pol_pos) + fA Pol_neg * fC Pol_neg)%N =
     ((fA Pol_zero + fA Pol_neg + fA Pol_pos) * (fC Pol_zero + fC Pol_neg + fC Pol_pos))%N)
    by nia.
  rewrite Hfact.
  unfold fA, fC.
  rewrite (marginalWeight_sum _ _ _ _ _ _ _ _ _ _
    (ckp_rho_da_le p) (ckp_ga_le p) (ckp_eps_le p) (ckp_qa_le p) (ckp_chi_le p) (attentionalWeightX2_N_le_two src)).
  rewrite (marginalWeight_sum _ _ _ _ _ _ _ _ _ _
    (ckp_kap_dc_le p) (ckp_gc_le p) (ckp_eps_le p) (ckp_qc_le p) (ckp_chi_le p) (attentionalWeightY2_N_le_two src)).
  rewrite N_pow_6.
  nia.
Qed.

Theorem veille_absorbing_free :
  forall (p : CircuitKernelParams),
    ckp_epsilon p = 0%N ->
    forall dst : EngineCoupling,
      circuitWeight p (mkEngineCoupling Pol_zero Pol_zero) dst =
      if EngineCoupling_eqb dst (mkEngineCoupling Pol_zero Pol_zero) then (4 * ckp_scale p ^ 6)%N else 0%N.
Proof.
  intros p Heps [da dc].
  rewrite N_pow_6.
  destruct da; destruct dc;
    unfold circuitWeight, marginalWeight, effectiveEpsScaled, isCharged,
      EngineCoupling_eqb, Polarity_eqb;
    cbn [ec_attente ec_controle isCharged EngineCoupling_eqb Polarity_eqb andb];
    cbv zeta iota;
    rewrite Heps; repeat (rewrite N.mul_0_r || rewrite N.mul_0_l || rewrite N.sub_0_r);
    nia.
Qed.

Lemma marginal_lyapunov_monotone :
  forall (M rate delta deseng qPos : N) (otherCharged : bool) (w2 : N) (src dst : Polarity),
    (0 < marginalWeight M rate delta deseng 0%N qPos 0%N otherCharged w2 src dst)%N ->
    polarityEnergy dst <= polarityEnergy src.
Proof.
  intros M rate delta deseng qPos otherCharged w2 src dst Hw.
  assert (He2 : effectiveEpsScaled M 0%N 0%N otherCharged = 0%N)
    by (destruct otherCharged; unfold effectiveEpsScaled; lia).
  destruct src; destruct dst;
    unfold marginalWeight in Hw; cbv zeta in Hw; rewrite ?He2 in Hw; simpl in Hw; simpl; lia.
Qed.

Theorem lyapunov_monotone_free :
  forall (p : CircuitKernelParams),
    ckp_epsilon p = 0%N -> ckp_chi p = 0%N ->
    forall src dst : EngineCoupling,
      (0 < circuitWeight p src dst)%N ->
      lyapunovPotential dst <= lyapunovPotential src.
Proof.
  intros p Heps Hchi src dst Hw.
  unfold circuitWeight in Hw; cbv zeta in Hw.
  rewrite Heps, Hchi in Hw.
  assert (Ha : (0 < marginalWeight (ckp_scale p) (ckp_rho p) (ckp_deltaA p) (ckp_gammaA p)
                    0%N (ckp_qPosA p) 0%N (isCharged (ec_controle src)) (attentionalWeightX2_N src)
                    (ec_attente src) (ec_attente dst))%N) by nia.
  assert (Hc : (0 < marginalWeight (ckp_scale p) (ckp_kappa p) (ckp_deltaC p) (ckp_gammaC p)
                    0%N (ckp_qPosC p) 0%N (isCharged (ec_attente src)) (attentionalWeightY2_N src)
                    (ec_controle src) (ec_controle dst))%N) by nia.
  pose proof (marginal_lyapunov_monotone _ _ _ _ _ _ _ _ _ Ha) as H1.
  pose proof (marginal_lyapunov_monotone _ _ _ _ _ _ _ _ _ Hc) as H2.
  unfold lyapunovPotential. lia.
Qed.

Definition stepDownPol (pol : Polarity) : Polarity :=
  match pol with
  | Pol_zero => Pol_zero
  | Pol_neg  => Pol_pos
  | Pol_pos  => Pol_zero
  end.

Theorem lyapunov_strict_descent_witness :
  forall (p : CircuitKernelParams),
    ckp_epsilon p = 0%N -> ckp_chi p = 0%N ->
    (0 < ckp_rho p)%N -> (0 < ckp_kappa p)%N -> (0 < ckp_gammaA p)%N -> (0 < ckp_gammaC p)%N ->
    forall src : EngineCoupling,
      EngineCoupling_isGlobalNeutrality src = false ->
      exists dst : EngineCoupling,
        (0 < circuitWeight p src dst)%N /\
        lyapunovPotential dst < lyapunovPotential src.
Proof.
  intros p Heps Hchi Hrho Hkap Hga Hgc [sa sc] Hact.
  set (dst := mkEngineCoupling (stepDownPol sa) (stepDownPol sc)).
  exists dst.
  pose proof (ckp_scale_pos p) as HM.
  pose proof (attentionalWeightX2_N_pos (mkEngineCoupling sa sc)) as Hwx.
  pose proof (attentionalWeightY2_N_pos (mkEngineCoupling sa sc)) as Hwy.
  assert (He2 : forall b, effectiveEpsScaled (ckp_scale p) 0%N 0%N b = 0%N)
    by (intro b; destruct b; unfold effectiveEpsScaled; lia).
  split.
  - unfold circuitWeight, dst; cbn [ec_attente ec_controle]; cbv zeta.
    rewrite Heps, Hchi.
    assert (HmwA : (0 < marginalWeight (ckp_scale p) (ckp_rho p) (ckp_deltaA p) (ckp_gammaA p)
                      0%N (ckp_qPosA p) 0%N (isCharged sc) (attentionalWeightX2_N (mkEngineCoupling sa sc))
                      sa (stepDownPol sa))%N).
    { destruct sa; unfold marginalWeight, stepDownPol; cbv zeta iota; rewrite ?He2, ?N.sub_0_r; nia. }
    assert (HmwC : (0 < marginalWeight (ckp_scale p) (ckp_kappa p) (ckp_deltaC p) (ckp_gammaC p)
                      0%N (ckp_qPosC p) 0%N (isCharged sa) (attentionalWeightY2_N (mkEngineCoupling sa sc))
                      sc (stepDownPol sc))%N).
    { destruct sc; unfold marginalWeight, stepDownPol; cbv zeta iota; rewrite ?He2, ?N.sub_0_r; nia. }
    nia.
  - destruct sa; destruct sc; try (simpl in Hact; discriminate);
      unfold dst, lyapunovPotential, polarityEnergy, stepDownPol; simpl; lia.
Qed.

Lemma effectiveEpsScaled_zero :
  forall (M : N) (b : bool), effectiveEpsScaled M 0%N 0%N b = 0%N.
Proof.
  intros M []; unfold effectiveEpsScaled; lia.
Qed.

Ltac eval_ground_circuit_consts :=
  repeat match goal with
  | |- context [attentionalWeightX2_N ?c] =>
      let v := eval vm_compute in (attentionalWeightX2_N c) in
      change (attentionalWeightX2_N c) with v
  | |- context [attentionalWeightY2_N ?c] =>
      let v := eval vm_compute in (attentionalWeightY2_N c) in
      change (attentionalWeightY2_N c) with v
  | |- context [N.of_nat (lyapunovPotential ?a - lyapunovPotential ?b)] =>
      let v := eval vm_compute in (N.of_nat (lyapunovPotential a - lyapunovPotential b)) in
      change (N.of_nat (lyapunovPotential a - lyapunovPotential b)) with v
  | |- context [isCharged Pol_pos] => change (isCharged Pol_pos) with false
  | |- context [isCharged Pol_neg] => change (isCharged Pol_neg) with true
  | |- context [isCharged Pol_zero] => change (isCharged Pol_zero) with false
  end.

Theorem lyapunov_expected_drift_constant :
  forall (p : CircuitKernelParams) (r : N),
    ckp_epsilon p = 0%N -> ckp_chi p = 0%N ->
    ckp_deltaA p = 0%N -> ckp_deltaC p = 0%N ->
    ckp_rho p = r -> ckp_kappa p = r -> ckp_gammaA p = r -> ckp_gammaC p = r ->
    forall src : EngineCoupling,
      EngineCoupling_isGlobalNeutrality src = false ->
      fold_left N.add
        (map (fun dst => (circuitWeight p src dst * N.of_nat (lyapunovPotential src - lyapunovPotential dst))%N)
             allCouplings) 0%N =
      (4 * ckp_scale p ^ 5 * r)%N.
Proof.
  intros p r Heps Hchi Hda Hdc Hrho Hkap Hga Hgc [sa sc] Hact.
  pose proof (ckp_scale_pos p) as HM.
  assert (Hr_le : (r <= ckp_scale p)%N) by (rewrite <- Hrho; exact (ckp_rho_le p)).
  rewrite N_pow_5.
  destruct sa; destruct sc;
    try (simpl in Hact; discriminate);
    unfold allCouplings, circuitWeight, marginalWeight;
    cbn [fold_left map ec_attente ec_controle];
    cbv zeta iota;
    eval_ground_circuit_consts; cbv iota;
    rewrite ?Heps, ?Hchi; repeat rewrite effectiveEpsScaled_zero;
    rewrite ?Hda, ?Hdc, ?Hrho, ?Hkap, ?Hga, ?Hgc;
    repeat (rewrite N.mul_0_r || rewrite N.mul_0_l || rewrite N.add_0_r || rewrite N.add_0_l || rewrite N.sub_0_r);
    apply N2Z.inj;
    repeat (rewrite N2Z.inj_add || rewrite N2Z.inj_mul || (rewrite N2Z.inj_sub; [| lia]));
    ring.
Qed.

Theorem lyapunov_drift_charge_with_passive_extinction :
  forall p : CircuitKernelParams,
    ckp_epsilon p = 0%N -> ckp_chi p = 0%N ->
    fold_left N.add
      (map (fun dst =>
              (circuitWeight p (mkEngineCoupling Pol_neg Pol_zero) dst *
               N.of_nat (lyapunovPotential (mkEngineCoupling Pol_neg Pol_zero) - lyapunovPotential dst))%N)
           allCouplings) 0%N =
    (4 * ckp_scale p ^ 5 * (ckp_rho p + 2 * ckp_deltaA p))%N.
Proof.
  intros p Heps Hchi.
  rewrite N_pow_5.
  unfold allCouplings, circuitWeight, marginalWeight;
  cbn [fold_left map ec_attente ec_controle];
  cbv zeta iota;
  eval_ground_circuit_consts; cbv iota;
  rewrite Heps, Hchi; repeat rewrite effectiveEpsScaled_zero;
  repeat (rewrite N.mul_0_r || rewrite N.mul_0_l || rewrite N.add_0_r || rewrite N.add_0_l || rewrite N.sub_0_r);
  apply N2Z.inj;
  repeat (rewrite N2Z.inj_add || rewrite N2Z.inj_mul || (rewrite N2Z.inj_sub; [| lia]));
  ring.
Qed.

Theorem p1_without_p2_eps_independent :
  forall (M eps : N) (otherCharged : bool),
    effectiveEpsScaled M eps 0%N otherCharged = (M * eps)%N.
Proof.
  intros M eps []; unfold effectiveEpsScaled; lia.
Qed.

Theorem axial_peur_bifurcates_p2 :
  forall p : CircuitKernelParams,
    (0 < ckp_chi p)%N -> (0 < ckp_qPosC p)%N -> (ckp_qPosC p < ckp_scale p)%N ->
    (ckp_rho p + ckp_deltaA p < ckp_scale p)%N ->
    (0 < circuitWeight p (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_neg Pol_pos))%N /\
    (0 < circuitWeight p (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_neg Pol_neg))%N.
Proof.
  intros p Hchi Hqpos Hqlt Hstay.
  pose proof (ckp_scale_pos p) as HM.
  pose proof (ckp_eps_le p) as Heps.
  assert (He2 : (0 < effectiveEpsScaled (ckp_scale p) (ckp_epsilon p) (ckp_chi p) true)%N)
    by (unfold effectiveEpsScaled; nia).
  assert (Hstay2 : (0 < 2 * ckp_scale p - 2 * ckp_rho p - 2 * ckp_deltaA p)%N) by lia.
  assert (Hqsub : (0 < ckp_scale p - ckp_qPosC p)%N) by lia.
  unfold circuitWeight, marginalWeight;
  cbn [ec_attente ec_controle]; cbv zeta iota;
  eval_ground_circuit_consts; cbv iota;
  assert (Hma : (0 < ckp_scale p * ckp_scale p *
                     (2 * ckp_scale p - 2 * ckp_rho p - 2 * ckp_deltaA p))%N) by nia;
  split; nia.
Qed.

Theorem veille_self_loop_ergodic :
  forall p : CircuitKernelParams,
    (ckp_epsilon p < ckp_scale p)%N ->
    (0 < circuitWeight p (mkEngineCoupling Pol_zero Pol_zero) (mkEngineCoupling Pol_zero Pol_zero))%N.
Proof.
  intros p Hlt.
  pose proof (ckp_scale_pos p) as HM.
  unfold circuitWeight, marginalWeight, effectiveEpsScaled;
  cbn [ec_attente ec_controle isCharged]; cbv zeta iota;
  nia.
Qed.

Theorem veille_reaches_all_one_step :
  forall p : CircuitKernelParams,
    (0 < ckp_epsilon p)%N -> (ckp_epsilon p < ckp_scale p)%N ->
    (0 < ckp_qPosA p)%N -> (ckp_qPosA p < ckp_scale p)%N ->
    (0 < ckp_qPosC p)%N -> (ckp_qPosC p < ckp_scale p)%N ->
    forall dst : EngineCoupling,
      (0 < circuitWeight p (mkEngineCoupling Pol_zero Pol_zero) dst)%N.
Proof.
  intros p Heps_pos Heps_lt Hqa_pos Hqa_lt Hqc_pos Hqc_lt [da dc].
  pose proof (ckp_scale_pos p) as HM.
  assert (He2_pos : (0 < effectiveEpsScaled (ckp_scale p) (ckp_epsilon p) (ckp_chi p) false)%N)
    by (unfold effectiveEpsScaled; nia).
  assert (He2_sub : (0 < ckp_scale p * ckp_scale p -
                        effectiveEpsScaled (ckp_scale p) (ckp_epsilon p) (ckp_chi p) false)%N)
    by (unfold effectiveEpsScaled; nia).
  unfold circuitWeight;
  cbn [ec_attente ec_controle isCharged]; cbv zeta;
  eval_ground_circuit_consts;
  assert (Ha : (0 < marginalWeight (ckp_scale p) (ckp_rho p) (ckp_deltaA p) (ckp_gammaA p)
                    (ckp_epsilon p) (ckp_qPosA p) (ckp_chi p) false 2%N Pol_zero da)%N)
    by (destruct da; unfold marginalWeight; cbv zeta iota; nia).
  assert (Hc : (0 < marginalWeight (ckp_scale p) (ckp_kappa p) (ckp_deltaC p) (ckp_gammaC p)
                    (ckp_epsilon p) (ckp_qPosC p) (ckp_chi p) false 2%N Pol_zero dc)%N)
    by (destruct dc; unfold marginalWeight; cbv zeta iota; nia).
  nia.
Qed.

Theorem all_reach_veille_two_steps :
  forall p : CircuitKernelParams,
    (ckp_epsilon p < ckp_scale p)%N -> (ckp_chi p < ckp_scale p)%N ->
    (0 < ckp_rho p)%N -> (0 < ckp_kappa p)%N -> (0 < ckp_gammaA p)%N -> (0 < ckp_gammaC p)%N ->
    forall src : EngineCoupling,
      exists mid : EngineCoupling,
        (0 < circuitWeight p src mid)%N /\
        (0 < circuitWeight p mid (mkEngineCoupling Pol_zero Pol_zero))%N.
Proof.
  intros p Heps_lt Hchi_lt Hrho Hkap Hga Hgc [sa sc].
  set (stepPol := fun pol => match pol with Pol_neg => Pol_pos | _ => Pol_zero end).
  exists (mkEngineCoupling (stepPol sa) (stepPol sc)).
  pose proof (ckp_scale_pos p) as HM.
  assert (HM2 : (0 < ckp_scale p * ckp_scale p)%N) by nia.
  assert (Heff : forall b, (0 < ckp_scale p * ckp_scale p -
                                effectiveEpsScaled (ckp_scale p) (ckp_epsilon p) (ckp_chi p) b)%N)
    by (intro b; apply effectiveEpsScaled_sub_pos; assumption).
  pose proof (attentionalWeightX2_N_pos (mkEngineCoupling sa sc)) as Hwx1.
  pose proof (attentionalWeightY2_N_pos (mkEngineCoupling sa sc)) as Hwy1.
  pose proof (attentionalWeightX2_N_pos (mkEngineCoupling (stepPol sa) (stepPol sc))) as Hwx2.
  pose proof (attentionalWeightY2_N_pos (mkEngineCoupling (stepPol sa) (stepPol sc))) as Hwy2.
  assert (Hmul_pos : forall a b : N, (0 < a -> 0 < b -> 0 < a * b)%N) by (intros a b Ha Hb; nia).
  split; unfold circuitWeight; cbn [ec_attente ec_controle].
  - assert (HA : (0 < marginalWeight (ckp_scale p) (ckp_rho p) (ckp_deltaA p) (ckp_gammaA p)
                    (ckp_epsilon p) (ckp_qPosA p) (ckp_chi p) (isCharged sc)
                    (attentionalWeightX2_N (mkEngineCoupling sa sc)) sa (stepPol sa))%N).
    { destruct sa; unfold marginalWeight, stepPol; cbv zeta iota;
        repeat apply Hmul_pos; try assumption; apply Heff. }
    assert (HC : (0 < marginalWeight (ckp_scale p) (ckp_kappa p) (ckp_deltaC p) (ckp_gammaC p)
                    (ckp_epsilon p) (ckp_qPosC p) (ckp_chi p) (isCharged sa)
                    (attentionalWeightY2_N (mkEngineCoupling sa sc)) sc (stepPol sc))%N).
    { destruct sc; unfold marginalWeight, stepPol; cbv zeta iota;
        repeat apply Hmul_pos; try assumption; apply Heff. }
    exact (Hmul_pos _ _ HA HC).
  - assert (HA2 : (0 < marginalWeight (ckp_scale p) (ckp_rho p) (ckp_deltaA p) (ckp_gammaA p)
                     (ckp_epsilon p) (ckp_qPosA p) (ckp_chi p) (isCharged (stepPol sc))
                     (attentionalWeightX2_N (mkEngineCoupling (stepPol sa) (stepPol sc))) (stepPol sa) Pol_zero)%N).
    { destruct sa; unfold stepPol, marginalWeight; cbv zeta iota;
        repeat apply Hmul_pos; try assumption; apply Heff. }
    assert (HC2 : (0 < marginalWeight (ckp_scale p) (ckp_kappa p) (ckp_deltaC p) (ckp_gammaC p)
                     (ckp_epsilon p) (ckp_qPosC p) (ckp_chi p) (isCharged (stepPol sa))
                     (attentionalWeightY2_N (mkEngineCoupling (stepPol sa) (stepPol sc))) (stepPol sc) Pol_zero)%N).
    { destruct sc; unfold stepPol, marginalWeight; cbv zeta iota;
        repeat apply Hmul_pos; try assumption; apply Heff. }
    exact (Hmul_pos _ _ HA2 HC2).
Qed.

Theorem veille_unreachable_when_eps_max :
  forall p : CircuitKernelParams,
    ckp_epsilon p = ckp_scale p -> ckp_deltaA p = 0%N ->
    forall src : EngineCoupling,
      circuitWeight p src (mkEngineCoupling Pol_zero Pol_zero) = 0%N.
Proof.
  intros p Heps Hda [sa sc].
  assert (He2 : forall b, effectiveEpsScaled (ckp_scale p) (ckp_epsilon p) (ckp_chi p) b =
                          (ckp_scale p * ckp_scale p)%N)
    by (intro b; destruct b; unfold effectiveEpsScaled; rewrite Heps; lia).
  unfold circuitWeight; cbn [ec_attente ec_controle].
  assert (HA0 : marginalWeight (ckp_scale p) (ckp_rho p) (ckp_deltaA p) (ckp_gammaA p)
                  (ckp_epsilon p) (ckp_qPosA p) (ckp_chi p) (isCharged sc)
                  (attentionalWeightX2_N (mkEngineCoupling sa sc)) sa Pol_zero = 0%N).
  { destruct sa; unfold marginalWeight; cbv zeta iota; rewrite ?He2, ?Hda; lia. }
  rewrite HA0. lia.
Qed.

Theorem epistemic_rigidity_traps_charge_slice :
  forall p : CircuitKernelParams,
    ckp_rho p = 0%N -> ckp_deltaA p = 0%N ->
    forall src dst : EngineCoupling,
      ec_attente src = Pol_neg -> ec_attente dst <> Pol_neg ->
      circuitWeight p src dst = 0%N.
Proof.
  intros p Hrho Hda [sa sc] [da dc] Hsrc Hdst; simpl in *.
  unfold circuitWeight; cbn [ec_attente ec_controle].
  assert (HA : marginalWeight (ckp_scale p) (ckp_rho p) (ckp_deltaA p) (ckp_gammaA p)
                 (ckp_epsilon p) (ckp_qPosA p) (ckp_chi p) (isCharged sc)
                 (attentionalWeightX2_N (mkEngineCoupling sa sc)) sa da = 0%N).
  { subst sa. destruct da; unfold marginalWeight; cbv zeta iota; try contradiction; rewrite ?Hrho, ?Hda; nia. }
  rewrite HA. nia.
Qed.

Theorem pragmatic_helplessness_traps_charge_slice :
  forall p : CircuitKernelParams,
    ckp_kappa p = 0%N -> ckp_deltaC p = 0%N ->
    forall src dst : EngineCoupling,
      ec_controle src = Pol_neg -> ec_controle dst <> Pol_neg ->
      circuitWeight p src dst = 0%N.
Proof.
  intros p Hkap Hdc [sa sc] [da dc] Hsrc Hdst; simpl in *.
  unfold circuitWeight; cbn [ec_attente ec_controle].
  assert (HC : marginalWeight (ckp_scale p) (ckp_kappa p) (ckp_deltaC p) (ckp_gammaC p)
                 (ckp_epsilon p) (ckp_qPosC p) (ckp_chi p) (isCharged sa)
                 (attentionalWeightY2_N (mkEngineCoupling sa sc)) sc dc = 0%N).
  { subst sc. destruct dc; unfold marginalWeight; cbv zeta iota; try contradiction; rewrite ?Hkap, ?Hdc; nia. }
  rewrite HC. nia.
Qed.

Theorem perseveration_traps_discharge_free :
  forall p : CircuitKernelParams,
    ckp_epsilon p = 0%N -> ckp_gammaA p = 0%N -> ckp_gammaC p = 0%N ->
    forall src dst : EngineCoupling,
      ec_attente src <> Pol_neg -> ec_controle src <> Pol_neg ->
      circuitWeight p src dst =
      if EngineCoupling_eqb dst src then (4 * ckp_scale p ^ 6)%N else 0%N.
Proof.
  intros p Heps Hga Hgc [sa sc] [da dc] Hsa Hsc; simpl in Hsa, Hsc.
  rewrite N_pow_6.
  destruct sa; destruct sc; try contradiction;
    destruct da; destruct dc;
    unfold circuitWeight, marginalWeight, effectiveEpsScaled, isCharged,
      EngineCoupling_eqb, Polarity_eqb;
    cbn [ec_attente ec_controle isCharged EngineCoupling_eqb Polarity_eqb andb];
    cbv zeta iota;
    rewrite Heps, ?Hga, ?Hgc;
    repeat (rewrite N.mul_0_r || rewrite N.mul_0_l || rewrite N.sub_0_r);
    nia.
Qed.

(** ** 6. Circuit continu fermé à 6 opérateurs avec états cachés (CircularCircuitState) *)

Record HiddenSubjectiveState : Type := mkHiddenSubjectiveState {
  hss_modelDiscrepancy     : nat;
  hss_revisable            : bool;
  hss_descendingSuspension : bool
}.

Record HiddenPerceptiveState : Type := mkHiddenPerceptiveState {
  hps_afferentDiscrepancy : nat;
  hps_controllable        : bool
}.

Record BodyEnvironmentState : Type := mkBodyEnvironmentState {
  bes_perturbation : nat
}.

Record CircularCircuitState : Type := mkCircularCircuitState {
  ccs_subjectiveHidden    : HiddenSubjectiveState;
  ccs_perceptiveHidden    : HiddenPerceptiveState;
  ccs_bodyEnv             : BodyEnvironmentState;
  ccs_sensoryThreshold    : nat;
  ccs_resorptionThreshold : nat;
  ccs_hysteresis          : ccs_resorptionThreshold <= ccs_sensoryThreshold;
  ccs_attentional         : AttentionalInterface
}.

Definition defaultCircularCircuitState : CircularCircuitState := {|
  ccs_subjectiveHidden    := {| hss_modelDiscrepancy := 0; hss_revisable := true; hss_descendingSuspension := false |};
  ccs_perceptiveHidden    := {| hps_afferentDiscrepancy := 0; hps_controllable := true |};
  ccs_bodyEnv             := {| bes_perturbation := 0 |};
  ccs_sensoryThreshold    := 1;
  ccs_resorptionThreshold := 1;
  ccs_hysteresis          := le_n 1;
  ccs_attentional         := defaultAttentionalInterface
|}.

Definition op1_subjectiveOut (s : CircularCircuitState) : Polarity :=
  if Nat.ltb (hss_modelDiscrepancy (ccs_subjectiveHidden s)) (ccs_resorptionThreshold s) then
    Pol_zero
  else if hss_revisable (ccs_subjectiveHidden s) then
    Pol_pos
  else
    Pol_neg.

Definition op2_perceptiveOut (s : CircularCircuitState) : Polarity :=
  if Nat.ltb (hps_afferentDiscrepancy (ccs_perceptiveHidden s)) (ccs_resorptionThreshold s) then
    Pol_zero
  else if hps_controllable (ccs_perceptiveHidden s) then
    Pol_pos
  else
    Pol_neg.

Definition op3_crossingI_perceptible (s : CircularCircuitState)
    : ProtoSpatialNode * CoreAffectState :=
  let c := mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s) in
  let proto := phiL1 c in
  let z :=
    if EngineCoupling_isGlobalNeutrality c then
      if hss_descendingSuspension (ccs_subjectiveHidden s) then
        ai_persistenceDepth (ccs_attentional s) + 2
      else 0
    else if negb (AttentionalInterface_isEngaged (ccs_attentional s)) then
      if hss_descendingSuspension (ccs_subjectiveHidden s) then
        ai_persistenceDepth (ccs_attentional s) + 2
      else 1
    else
      ai_persistenceDepth (ccs_attentional s) + 2 in
  (proto, projectPerceptibleState c z
            (ai_precisionA (ccs_attentional s))
            (ai_precisionC (ccs_attentional s))
            (hss_descendingSuspension (ccs_subjectiveHidden s))).

Definition op4_crossingII_retroactive (s : CircularCircuitState)
    : SubjectiveReturnChannel * PerceptiveReturnChannel :=
  let c := mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s) in
  (routeToSubjective c, routeToPerceptive c).

Definition op5_subjectiveIn (s : CircularCircuitState) (ch : SubjectiveReturnChannel)
    (perceptible : CoreAffectState) : HiddenSubjectiveState :=
  let nextDiscrepancy :=
    if FunctionalRegime_eqb (src_regimeA ch) Reg_discharge then
      hss_modelDiscrepancy (ccs_subjectiveHidden s) - 1
    else
      hss_modelDiscrepancy (ccs_subjectiveHidden s) in
  let nextRevisable :=
    hss_revisable (ccs_subjectiveHidden s) ||
    (FunctionalRegime_eqb (src_regimeA ch) Reg_charge &&
     Polarity_eqb (src_contextC ch) Pol_pos &&
     Nat.leb 2 (pt_z (cas_point perceptible))) in
  let nextSuspension :=
    if FunctionalRegime_eqb (src_regimeA ch) Reg_neutral &&
       Polarity_eqb (src_contextC ch) Pol_zero then false
    else hss_descendingSuspension (ccs_subjectiveHidden s) in
  {|
    hss_modelDiscrepancy     := nextDiscrepancy;
    hss_revisable            := nextRevisable;
    hss_descendingSuspension := nextSuspension
  |}.

Definition op6_perceptiveIn (s : CircularCircuitState) (ch : PerceptiveReturnChannel)
    (perceptible : CoreAffectState) : HiddenPerceptiveState * BodyEnvironmentState :=
  let reduced :=
    if FunctionalRegime_eqb (prc_regimeC ch) Reg_discharge &&
       (0 <? pt_y (cas_point perceptible))%Z then
      hps_afferentDiscrepancy (ccs_perceptiveHidden s) - 1
    else
      hps_afferentDiscrepancy (ccs_perceptiveHidden s) in
  let nextAfferent := reduced + bes_perturbation (ccs_bodyEnv s) in
  ({| hps_afferentDiscrepancy := nextAfferent;
      hps_controllable        := hps_controllable (ccs_perceptiveHidden s) |},
   ccs_bodyEnv s).

Definition circularCycle (s : CircularCircuitState) : CircularCircuitState :=
  let '(_, perceptible) := op3_crossingI_perceptible s in
  let '(chSubj, chPerc) := op4_crossingII_retroactive s in
  let nextSubj := op5_subjectiveIn s chSubj perceptible in
  let '(nextPerc, nextEnv) := op6_perceptiveIn s chPerc perceptible in
  {|
    ccs_subjectiveHidden    := nextSubj;
    ccs_perceptiveHidden    := nextPerc;
    ccs_bodyEnv             := nextEnv;
    ccs_sensoryThreshold    := ccs_sensoryThreshold s;
    ccs_resorptionThreshold := ccs_resorptionThreshold s;
    ccs_hysteresis          := ccs_hysteresis s;
    ccs_attentional         := ccs_attentional s
  |}.

Theorem circularCycle_emits_valid_core_affect :
  forall s : CircularCircuitState,
    isValidCoreAffect (cas_point (snd (op3_crossingI_perceptible s))).
Proof.
  intro s. exact (cas_valid (snd (op3_crossingI_perceptible s))).
Qed.

Theorem circularCycle_veille_fixed_point :
  circularCycle defaultCircularCircuitState = defaultCircularCircuitState /\
  cas_point (snd (op3_crossingI_perceptible defaultCircularCircuitState)) = mkPoint 0%Z 0%Z 0.
Proof.
  split; reflexivity.
Qed.

Lemma op5_modelDiscrepancy_of_discharge :
  forall (s : CircularCircuitState) (ch : SubjectiveReturnChannel) (p : CoreAffectState),
    src_regimeA ch = Reg_discharge ->
    hss_modelDiscrepancy (op5_subjectiveIn s ch p) = hss_modelDiscrepancy (ccs_subjectiveHidden s) - 1.
Proof.
  intros s ch p H. unfold op5_subjectiveIn. rewrite H. reflexivity.
Qed.

Lemma op5_modelDiscrepancy_le :
  forall (s : CircularCircuitState) (ch : SubjectiveReturnChannel) (p : CoreAffectState),
    hss_modelDiscrepancy (op5_subjectiveIn s ch p) <= hss_modelDiscrepancy (ccs_subjectiveHidden s).
Proof.
  intros s ch p. unfold op5_subjectiveIn; simpl.
  destruct (FunctionalRegime_eqb (src_regimeA ch) Reg_discharge); lia.
Qed.

Lemma op6_afferentDiscrepancy_le :
  forall (s : CircularCircuitState) (ch : PerceptiveReturnChannel) (p : CoreAffectState),
    bes_perturbation (ccs_bodyEnv s) = 0 ->
    hps_afferentDiscrepancy (fst (op6_perceptiveIn s ch p)) <= hps_afferentDiscrepancy (ccs_perceptiveHidden s).
Proof.
  intros s ch p Hpert. unfold op6_perceptiveIn; simpl.
  rewrite Hpert.
  destruct (FunctionalRegime_eqb (prc_regimeC ch) Reg_discharge && (0 <? pt_y (cas_point p))%Z); lia.
Qed.

Lemma op6_afferentDiscrepancy_of_discharge_pos :
  forall (s : CircularCircuitState) (ch : PerceptiveReturnChannel) (p : CoreAffectState),
    bes_perturbation (ccs_bodyEnv s) = 0 ->
    prc_regimeC ch = Reg_discharge ->
    (pt_y (cas_point p) > 0)%Z ->
    hps_afferentDiscrepancy (fst (op6_perceptiveIn s ch p)) =
    hps_afferentDiscrepancy (ccs_perceptiveHidden s) - 1.
Proof.
  intros s ch p Hpert Hc Hy. unfold op6_perceptiveIn; simpl.
  rewrite Hpert, Hc; simpl.
  destruct (Z.ltb_spec0 0 (pt_y (cas_point p))); [lia | lia].
Qed.

Theorem circularCycle_reduces_total_discrepancy :
  forall s : CircularCircuitState,
    bes_perturbation (ccs_bodyEnv s) = 0 ->
    hss_revisable (ccs_subjectiveHidden s) = true ->
    hps_controllable (ccs_perceptiveHidden s) = true ->
    AttentionalInterface_isEngaged (ccs_attentional s) = true ->
    ccs_resorptionThreshold s = 1 ->
    hss_modelDiscrepancy (ccs_subjectiveHidden s) + hps_afferentDiscrepancy (ccs_perceptiveHidden s) > 0 ->
    hss_modelDiscrepancy (ccs_subjectiveHidden (circularCycle s)) +
      hps_afferentDiscrepancy (ccs_perceptiveHidden (circularCycle s)) <
    hss_modelDiscrepancy (ccs_subjectiveHidden s) + hps_afferentDiscrepancy (ccs_perceptiveHidden s).
Proof.
  intros s Hpert Hrev Hctrl Heng Hthr Hpos.
  unfold circularCycle.
  destruct (op3_crossingI_perceptible s) as [proto perceptible] eqn:Hop3.
  destruct (op4_crossingII_retroactive s) as [chSubj chPerc] eqn:Hop4.
  destruct (op6_perceptiveIn s chPerc perceptible) as [nextPerc nextEnv] eqn:Hop6.
  cbn [ccs_subjectiveHidden ccs_perceptiveHidden].
  assert (Hperc_eq : perceptible = snd (op3_crossingI_perceptible s))
    by (rewrite Hop3; reflexivity).
  assert (HchS_eq : chSubj = fst (op4_crossingII_retroactive s))
    by (rewrite Hop4; reflexivity).
  assert (HchP_eq : chPerc = snd (op4_crossingII_retroactive s))
    by (rewrite Hop4; reflexivity).
  assert (Hnp_eq : nextPerc = fst (op6_perceptiveIn s chPerc perceptible))
    by (rewrite Hop6; reflexivity).
  destruct (hss_modelDiscrepancy (ccs_subjectiveHidden s)) as [| m'] eqn:Hm.
  - destruct (hps_afferentDiscrepancy (ccs_perceptiveHidden s)) as [| a'] eqn:Ha; [lia |].
    assert (Hop1 : op1_subjectiveOut s = Pol_zero).
    { unfold op1_subjectiveOut. rewrite Hthr, Hm. reflexivity. }
    assert (Hop2 : op2_perceptiveOut s = Pol_pos).
    { unfold op2_perceptiveOut. rewrite Hthr, Hctrl, Ha. reflexivity. }
    assert (HregC : prc_regimeC chPerc = Reg_discharge).
    { rewrite HchP_eq. unfold op4_crossingII_retroactive, routeToPerceptive; simpl.
      rewrite Hop2. reflexivity. }
    assert (Hy : (pt_y (cas_point perceptible) > 0)%Z).
    { rewrite Hperc_eq. unfold op3_crossingI_perceptible, projectPerceptibleState; simpl.
      rewrite Hop1, Hop2, Heng.
      replace (ai_persistenceDepth (ccs_attentional s) + 2)
        with (S (S (ai_persistenceDepth (ccs_attentional s)))) by lia.
      unfold projectPerceptible, deployCouplingWithPrecision, signedAmplitude; simpl. lia. }
    pose proof (op5_modelDiscrepancy_le s chSubj perceptible) as H5.
    pose proof (op6_afferentDiscrepancy_of_discharge_pos s chPerc perceptible Hpert HregC Hy) as H6.
    rewrite Hnp_eq, H6, Ha. lia.
  - assert (Hop1 : op1_subjectiveOut s = Pol_pos).
    { unfold op1_subjectiveOut. rewrite Hthr, Hrev, Hm. reflexivity. }
    assert (HregA : src_regimeA chSubj = Reg_discharge).
    { rewrite HchS_eq. unfold op4_crossingII_retroactive, routeToSubjective; simpl.
      rewrite Hop1. reflexivity. }
    pose proof (op5_modelDiscrepancy_of_discharge s chSubj perceptible HregA) as H5.
    pose proof (op6_afferentDiscrepancy_le s chPerc perceptible Hpert) as H6.
    rewrite H5, Hnp_eq, Hm. lia.
Qed.

(** ** 7. Loi unifiée (Axe iv) : récurrence R_t, strate Z_t (R5) et partage (pi_A, pi_C) *)

Record UnifiedDynamicsParams : Type := mkUnifiedDynamicsParams {
  udp_halfScale   : N;
  udp_lambdaNum   : N;
  udp_etaScaled   : N;
  udp_betaAtt     : N;
  udp_alphaCharge : N;
  udp_sigmoidK    : N;
  udp_zMax        : nat;
  udp_thetaUp     : nat -> N;
  udp_thetaDown   : nat -> N;
  udp_half_pos    : (0 < udp_halfScale)%N;
  udp_lambda_lt   : (udp_lambdaNum < 2 * udp_halfScale)%N;
  udp_k_pos       : (0 < udp_sigmoidK)%N;
  udp_zmax_ge2    : udp_zMax >= 2;
  udp_hyst        : forall z : nat, (udp_thetaDown z < udp_thetaUp z)%N
}.

Definition defaultUnifiedDynamicsParams : UnifiedDynamicsParams.
Proof.
  refine {|
    udp_halfScale   := 500%N;
    udp_lambdaNum   := 800%N;
    udp_etaScaled   := 600%N;
    udp_betaAtt     := 2%N;
    udp_alphaCharge := 50%N;
    udp_sigmoidK    := 100%N;
    udp_zMax        := 7;
    udp_thetaUp     := fun z => (600 + 200 * N.of_nat z)%N;
    udp_thetaDown   := fun z => (300 + 200 * N.of_nat z)%N
  |}; try (intro z; lia); lia.
Defined.

Definition activeResolutionCount (src dst : EngineCoupling) : N :=
  ((if Polarity_eqb (ec_attente src) Pol_neg && Polarity_eqb (ec_attente dst) Pol_pos then 1 else 0) +
   (if Polarity_eqb (ec_controle src) Pol_neg && Polarity_eqb (ec_controle dst) Pol_pos then 1 else 0))%N.

Definition nextChargeAccumulator (p : UnifiedDynamicsParams) (r piAScaled piCScaled : N)
    (src dst : EngineCoupling) : N :=
  let s := (2 * udp_halfScale p)%N in
  let contribA := if Polarity_eqb (ec_attente src) Pol_neg then piAScaled else 0%N in
  let contribC := if Polarity_eqb (ec_controle src) Pol_neg then piCScaled else 0%N in
  let relief := (udp_etaScaled p * activeResolutionCount src dst)%N in
  ((udp_lambdaNum p * r) / s + contribA + contribC - relief)%N.

Definition chargeAccumulatorBound (p : UnifiedDynamicsParams) : N :=
  let s := (2 * udp_halfScale p)%N in
  ((s * s) / (s - udp_lambdaNum p))%N.

Theorem passive_extinction_zero_relief :
  activeResolutionCount (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_zero Pol_zero) = 0%N.
Proof. reflexivity. Qed.

Theorem active_resolution_beats_passive_extinction :
  forall (p : UnifiedDynamicsParams) (r piAScaled piCScaled : N),
    (0 < udp_etaScaled p)%N ->
    (0 < (udp_lambdaNum p * r) / (2 * udp_halfScale p) + piAScaled)%N ->
    (nextChargeAccumulator p r piAScaled piCScaled
       (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_pos Pol_zero) <
     nextChargeAccumulator p r piAScaled piCScaled
       (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_zero Pol_zero))%N.
Proof.
  intros p r piAScaled piCScaled Heta Hpos.
  unfold nextChargeAccumulator, activeResolutionCount;
  cbn [ec_attente ec_controle Polarity_eqb andb]; cbv zeta iota;
  rewrite ?N.add_0_r, ?N.add_0_l, ?N.mul_1_r, ?N.mul_0_r, ?N.sub_0_r;
  lia.
Qed.

Theorem charge_accumulator_bounded :
  forall (p : UnifiedDynamicsParams) (r piAScaled piCScaled : N) (src dst : EngineCoupling),
    (piAScaled + piCScaled = 2 * udp_halfScale p)%N ->
    (r <= chargeAccumulatorBound p)%N ->
    (nextChargeAccumulator p r piAScaled piCScaled src dst <= chargeAccumulatorBound p)%N.
Proof.
  intros p r piAScaled piCScaled src dst Hbudget Hle.
  set (s := (2 * udp_halfScale p)%N).
  set (l := udp_lambdaNum p).
  set (rMax := ((s * s) / (s - l))%N).
  pose proof (udp_half_pos p) as Hhalf.
  pose proof (udp_lambda_lt p) as Hllt.
  assert (Hs_pos : (0 < s)%N) by (unfold s; lia).
  assert (Hd_pos : (0 < s - l)%N) by (unfold s, l; lia).
  assert (HrMax_ge_s : (s <= rMax)%N).
  { unfold rMax.
    replace s with ((s * (s - l)) / (s - l))%N at 1
      by (apply N.div_mul; lia).
    apply N.Div0.div_le_mono. apply N.mul_le_mono_l. unfold s, l; lia. }
  assert (Hdiv_eq : (s * s = (s - l) * rMax + (s * s) mod (s - l))%N)
    by (unfold rMax; exact (N.Div0.div_mod (s * s) (s - l))).
  assert (Hmod_lt : ((s * s) mod (s - l) < s - l)%N)
    by (apply N.mod_lt; lia).
  assert (Hsl : ((s - l) * rMax + l * rMax = s * rMax)%N).
  { apply N2Z.inj.
    repeat (rewrite N2Z.inj_add || rewrite N2Z.inj_mul || (rewrite N2Z.inj_sub; [| unfold s, l; lia])).
    ring. }
  assert (Hs_rmax : (s * (rMax - s + 1) + s * s = s * rMax + s)%N).
  { apply N2Z.inj.
    repeat (rewrite N2Z.inj_add || rewrite N2Z.inj_mul || (rewrite N2Z.inj_sub; [| exact HrMax_ge_s])).
    ring. }
  assert (Hsl_le : (s - l <= s)%N) by (unfold s, l; lia).
  assert (Hlt_s : (l * rMax < s * (rMax - s + 1))%N) by lia.
  assert (Hdiv_lt : ((l * rMax) / s < rMax - s + 1)%N)
    by (apply N.Div0.div_lt_upper_bound; exact Hlt_s).
  assert (Hlr_le : ((l * r) / s <= (l * rMax) / s)%N)
    by (apply N.Div0.div_le_mono; apply N.mul_le_mono_l; exact Hle).
  assert (Hcontrib :
    ((if Polarity_eqb (ec_attente src) Pol_neg then piAScaled else 0%N) +
     (if Polarity_eqb (ec_controle src) Pol_neg then piCScaled else 0%N) <= s)%N).
  { destruct (ec_attente src); destruct (ec_controle src); simpl; unfold s in *; lia. }
  unfold nextChargeAccumulator, chargeAccumulatorBound.
  change (2 * udp_halfScale p)%N with s.
  change (udp_lambdaNum p) with l.
  change ((s * s) / (s - l))%N with rMax.
  lia.
Qed.

Definition nextStratumR5 (p : UnifiedDynamicsParams) (z : nat) (rNext : N) : nat :=
  if N.ltb (udp_thetaUp p z) rNext then
    Nat.min (udp_zMax p) (z + 1)
  else if N.ltb rNext (udp_thetaDown p z) then
    match z with
    | 0          => 0
    | 1          => 0
    | 2          => 0
    | S (S (S k)) => Nat.min (udp_zMax p) (k + 2)
    end
  else
    Nat.min (udp_zMax p) z.

Theorem nextStratumR5_le_zMax :
  forall (p : UnifiedDynamicsParams) (z : nat) (rNext : N),
    nextStratumR5 p z rNext <= udp_zMax p.
Proof.
  intros p z rNext. unfold nextStratumR5.
  destruct (N.ltb_spec0 (udp_thetaUp p z) rNext); [apply Nat.le_min_l |].
  destruct (N.ltb_spec0 rNext (udp_thetaDown p z));
    [destruct z as [| [| [| k]]]; [lia | lia | lia | apply Nat.le_min_l] |
     apply Nat.le_min_l].
Qed.

Theorem nextStratumR5_short_circuits_z2_to_veille :
  forall (p : UnifiedDynamicsParams) (rNext : N),
    (rNext < udp_thetaDown p 2)%N ->
    nextStratumR5 p 2 rNext = 0.
Proof.
  intros p rNext Hdown.
  pose proof (udp_hyst p 2) as Hh.
  unfold nextStratumR5.
  destruct (N.ltb_spec0 (udp_thetaUp p 2) rNext); [lia |].
  destruct (N.ltb_spec0 rNext (udp_thetaDown p 2)); [reflexivity | lia].
Qed.

Theorem nextStratumR5_from_ge2_never_visits_surprise :
  forall (p : UnifiedDynamicsParams) (z : nat) (rNext : N),
    z >= 2 -> nextStratumR5 p z rNext <> 1.
Proof.
  intros p z rNext Hz.
  pose proof (udp_zmax_ge2 p) as Hzmax.
  unfold nextStratumR5.
  destruct (N.ltb_spec0 (udp_thetaUp p z) rNext); [lia |].
  destruct (N.ltb_spec0 rNext (udp_thetaDown p z)).
  - destruct z as [| [| [| k]]]; lia.
  - lia.
Qed.

Definition symmetricSigmoid (halfScale K : N) (u : Z) : N * N :=
  let ua := Z.abs_N u in
  let shift := ((halfScale * ua) / (ua + K))%N in
  if (0 <=? u)%Z then
    ((halfScale + shift)%N, (halfScale - shift)%N)
  else
    ((halfScale - shift)%N, (halfScale + shift)%N).

Lemma symmetricSigmoid_shift_lt :
  forall (halfScale K : N) (u : Z),
    (0 < halfScale)%N -> (0 < K)%N ->
    ((halfScale * Z.abs_N u) / (Z.abs_N u + K) < halfScale)%N.
Proof.
  intros halfScale K u Hpos Hk.
  apply N.Div0.div_lt_upper_bound. nia.
Qed.

Theorem symmetricSigmoid_sum :
  forall (halfScale K : N) (u : Z),
    (0 < K)%N ->
    (fst (symmetricSigmoid halfScale K u) + snd (symmetricSigmoid halfScale K u) = 2 * halfScale)%N.
Proof.
  intros halfScale K u Hk.
  assert (Hle : ((halfScale * Z.abs_N u) / (Z.abs_N u + K) <= halfScale)%N)
    by (apply N.Div0.div_le_upper_bound; nia).
  unfold symmetricSigmoid; cbv zeta.
  generalize ((halfScale * Z.abs_N u) / (Z.abs_N u + K))%N Hle.
  intros sh Hsh.
  destruct (Z.leb_spec0 0 u); cbn [fst snd]; lia.
Qed.

Theorem symmetricSigmoid_pos :
  forall (halfScale K : N) (u : Z),
    (0 < halfScale)%N -> (0 < K)%N ->
    (0 < fst (symmetricSigmoid halfScale K u))%N /\
    (0 < snd (symmetricSigmoid halfScale K u))%N.
Proof.
  intros halfScale K u Hpos Hk.
  pose proof (symmetricSigmoid_shift_lt halfScale K u Hpos Hk) as Hlt.
  unfold symmetricSigmoid; cbv zeta.
  generalize ((halfScale * Z.abs_N u) / (Z.abs_N u + K))%N Hlt.
  intros sh Hsh.
  destruct (Z.leb_spec0 0 u); cbn [fst snd]; lia.
Qed.

Theorem symmetricSigmoid_neg :
  forall (halfScale K : N) (u : Z),
    symmetricSigmoid halfScale K (- u)%Z =
    (snd (symmetricSigmoid halfScale K u), fst (symmetricSigmoid halfScale K u)).
Proof.
  intros halfScale K u.
  unfold symmetricSigmoid.
  replace (Z.abs_N (- u)) with (Z.abs_N u) by (destruct u; reflexivity).
  destruct (Z.eq_dec u 0) as [-> | Hnz].
  - simpl.
    assert (Hshift : ((halfScale * 0) / K = 0)%N)
      by (rewrite N.mul_0_r; destruct K; reflexivity).
    rewrite Hshift, N.add_0_r, N.sub_0_r. reflexivity.
  - destruct (Z.leb_spec0 0 (- u)); destruct (Z.leb_spec0 0 u); try lia; reflexivity.
Qed.

Definition chargeIndicatorInt (pol : Polarity) : Z :=
  if Polarity_eqb pol Pol_neg then 1%Z else 0%Z.

Definition precisionScore (p : UnifiedDynamicsParams) (rhoHat kappaHat : N) (c : EngineCoupling) : Z :=
  (Z.of_N (udp_betaAtt p) *
    ((Z.of_N rhoHat - Z.of_N kappaHat) +
     Z.of_N (udp_alphaCharge p) * (chargeIndicatorInt (ec_attente c) - chargeIndicatorInt (ec_controle c))))%Z.

Definition precisionShares (p : UnifiedDynamicsParams) (rhoHat kappaHat : N)
    (c : EngineCoupling) : N * N :=
  symmetricSigmoid (udp_halfScale p) (udp_sigmoidK p) (precisionScore p rhoHat kappaHat c).

Definition spatialBudget (z : nat) : nat :=
  if Nat.ltb z 2 then 0 else 2 * z - 2.

Definition projectUnifiedState (p : UnifiedDynamicsParams) (c : EngineCoupling)
    (z : nat) (rhoHat kappaHat : N) (susp : bool) : CoreAffectState :=
  let shares := precisionShares p rhoHat kappaHat c in
  projectPerceptibleState c z (N.to_nat (fst shares)) (N.to_nat (snd shares)) susp.

Theorem precisionShare_double_charge_cancels_alpha :
  forall (p : UnifiedDynamicsParams) (rhoHat kappaHat : N),
    precisionScore p rhoHat kappaHat (mkEngineCoupling Pol_neg Pol_neg) =
    (Z.of_N (udp_betaAtt p) * (Z.of_N rhoHat - Z.of_N kappaHat))%Z.
Proof.
  intros p rhoHat kappaHat.
  unfold precisionScore, chargeIndicatorInt; simpl. lia.
Qed.

Theorem projectUnifiedState_valid :
  forall (p : UnifiedDynamicsParams) (c : EngineCoupling) (z : nat) (rhoHat kappaHat : N) (susp : bool),
    isValidCoreAffect (cas_point (projectUnifiedState p c z rhoHat kappaHat susp)).
Proof.
  intros p c z rhoHat kappaHat susp.
  exact (cas_valid (projectUnifiedState p c z rhoHat kappaHat susp)).
Qed.

Theorem projectUnifiedState_crown_budget :
  forall (p : UnifiedDynamicsParams) (c : EngineCoupling) (z : nat) (rhoHat kappaHat : N) (susp : bool),
    EngineCoupling_isGlobalNeutrality c = false ->
    z >= 2 ->
    let pt := cas_point (projectUnifiedState p c z rhoHat kappaHat susp) in
    Z.abs_nat (pt_x pt) + Z.abs_nat (pt_y pt) = spatialBudget z.
Proof.
  intros p c z rhoHat kappaHat susp Hact Hz pt.
  assert (Hsb : spatialBudget z = 2 * z - 2)
    by (unfold spatialBudget; destruct (Nat.ltb_spec0 z 2); lia).
  rewrite Hsb.
  unfold pt, projectUnifiedState, projectPerceptibleState, projectPerceptible; simpl.
  rewrite Hact.
  destruct z as [| [| d]]; [lia | lia |].
  pose proof (deployCouplingWithPrecision_budget_conservation c d
    (N.to_nat (fst (precisionShares p rhoHat kappaHat c)))
    (N.to_nat (snd (precisionShares p rhoHat kappaHat c))) Hact) as Hv.
  unfold CoreAffectPoint_displacementSum in Hv. lia.
Qed.

Theorem projectUnifiedState_reaches_lateral_consternation :
  cas_point (projectUnifiedState defaultUnifiedDynamicsParams
    (mkEngineCoupling Pol_neg Pol_pos) 3 10%N 90%N true) =
  mkPoint (-1)%Z 3%Z 3.
Proof.
  vm_compute. reflexivity.
Qed.
