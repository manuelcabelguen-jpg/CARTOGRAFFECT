(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*)

From Stdlib Require Import Bool Arith PeanoNat ZArith Lia.
Require Import CartograffectRocq.PredictiveEngine.
Require Import CartograffectRocq.CoreAffect.
Require Import CartograffectRocq.AffectiveMatrix.

Open Scope bool_scope.
Open Scope nat_scope.

(** * Module AffectiveTaxonomy — Validation Rocq 9.1.0 *)

(** ** 1. Catégories de strates (Profondeur Z) et Groupes taxonomiques d'orientation *)

Inductive TaxonomicStratum : Type :=
  | TS_z0_pointDeVeille           : TaxonomicStratum
  | TS_z1_saillancePerceptive     : TaxonomicStratum
  | TS_z2_affectsPrimaires        : TaxonomicStratum
  | TS_z3_emotionsReactives       : TaxonomicStratum
  | TS_z4_sentimentsReflexifs     : TaxonomicStratum
  | TS_z5_orientationsDurables    : TaxonomicStratum
  | TS_z6_identitesAffectives     : TaxonomicStratum
  | TS_z7_sentimentsTranscendants : TaxonomicStratum
  | TS_zDeepProlongation          : nat -> TaxonomicStratum.

Definition classifyStratum (z : nat) : TaxonomicStratum :=
  match z with
  | 0 => TS_z0_pointDeVeille
  | 1 => TS_z1_saillancePerceptive
  | 2 => TS_z2_affectsPrimaires
  | 3 => TS_z3_emotionsReactives
  | 4 => TS_z4_sentimentsReflexifs
  | 5 => TS_z5_orientationsDurables
  | 6 => TS_z6_identitesAffectives
  | 7 => TS_z7_sentimentsTranscendants
  | n => TS_zDeepProlongation n
  end.

Inductive TaxonomicGroup : Type :=
  | TG_operateurCentral : TaxonomicGroup
  | TG_groupeJoie       : TaxonomicGroup
  | TG_groupeTristesse  : TaxonomicGroup
  | TG_groupePeur       : TaxonomicGroup
  | TG_groupeCourage    : TaxonomicGroup
  | TG_groupeDesir      : TaxonomicGroup
  | TG_groupeDegout     : TaxonomicGroup
  | TG_groupeColere     : TaxonomicGroup
  | TG_groupeCalme      : TaxonomicGroup.

Definition TaxonomicGroup_eqb (a b : TaxonomicGroup) : bool :=
  match a, b with
  | TG_operateurCentral, TG_operateurCentral => true
  | TG_groupeJoie, TG_groupeJoie             => true
  | TG_groupeTristesse, TG_groupeTristesse   => true
  | TG_groupePeur, TG_groupePeur             => true
  | TG_groupeCourage, TG_groupeCourage       => true
  | TG_groupeDesir, TG_groupeDesir           => true
  | TG_groupeDegout, TG_groupeDegout         => true
  | TG_groupeColere, TG_groupeColere         => true
  | TG_groupeCalme, TG_groupeCalme           => true
  | _, _                                     => false
  end.

Lemma TaxonomicGroup_eqb_eq :
  forall a b : TaxonomicGroup, TaxonomicGroup_eqb a b = true <-> a = b.
Proof.
  intros [] []; simpl; split; intro H; try reflexivity; try discriminate.
Qed.

Lemma TaxonomicGroup_eq_dec :
  forall a b : TaxonomicGroup, {a = b} + {a <> b}.
Proof. decide equality. Defined.

Definition matchesTaxonomicGroup (p : CoreAffectPoint) (g : TaxonomicGroup) : Prop :=
  match g with
  | TG_operateurCentral => pt_x p = 0%Z /\ pt_y p = 0%Z
  | TG_groupeJoie       => Z.abs_nat (pt_y p) > Z.abs_nat (pt_x p) /\ (pt_y p > 0)%Z
  | TG_groupeTristesse  => Z.abs_nat (pt_y p) > Z.abs_nat (pt_x p) /\ (pt_y p < 0)%Z
  | TG_groupePeur       => Z.abs_nat (pt_x p) > Z.abs_nat (pt_y p) /\ (pt_x p < 0)%Z
  | TG_groupeCourage    => Z.abs_nat (pt_x p) > Z.abs_nat (pt_y p) /\ (pt_x p > 0)%Z
  | TG_groupeDesir      => Z.abs_nat (pt_x p) = Z.abs_nat (pt_y p) /\ (pt_x p > 0)%Z /\ (pt_y p > 0)%Z
  | TG_groupeDegout     => Z.abs_nat (pt_x p) = Z.abs_nat (pt_y p) /\ (pt_x p < 0)%Z /\ (pt_y p < 0)%Z
  | TG_groupeColere     => Z.abs_nat (pt_x p) = Z.abs_nat (pt_y p) /\ (pt_x p < 0)%Z /\ (pt_y p > 0)%Z
  | TG_groupeCalme      => Z.abs_nat (pt_x p) = Z.abs_nat (pt_y p) /\ (pt_x p > 0)%Z /\ (pt_y p < 0)%Z
  end.

Definition classifyTaxonomicGroup (p : CoreAffectPoint) : TaxonomicGroup :=
  if (pt_x p =? 0)%Z && (pt_y p =? 0)%Z then
    TG_operateurCentral
  else if Nat.ltb (Z.abs_nat (pt_x p)) (Z.abs_nat (pt_y p)) then
    if (0 <? pt_y p)%Z then TG_groupeJoie else TG_groupeTristesse
  else if Nat.ltb (Z.abs_nat (pt_y p)) (Z.abs_nat (pt_x p)) then
    if (pt_x p <? 0)%Z then TG_groupePeur else TG_groupeCourage
  else if (0 <? pt_x p)%Z then
    if (0 <? pt_y p)%Z then TG_groupeDesir else TG_groupeCalme
  else
    if (0 <? pt_y p)%Z then TG_groupeColere else TG_groupeDegout.

Inductive FunctionalSubsector : Type :=
  | FS_centralOperator
  | FS_axialElan
  | FS_axialWithdrawal
  | FS_axialOpening
  | FS_axialThreat
  | FS_diagonalDesire
  | FS_diagonalDisgust
  | FS_diagonalAnger
  | FS_diagonalCalm
  | FS_lateralApproachSynergy
  | FS_lateralDefensiveUrgency
  | FS_lateralTrophotropicPeace
  | FS_lateralAversiveDistress
  | FS_lateralEpistemicMastery
  | FS_lateralContemplativeOpen
  | FS_lateralVigilantAlert
  | FS_lateralEpistemicClosure.

Definition classifySubsector (x y : Z) : FunctionalSubsector :=
  if (x =? 0)%Z && (y =? 0)%Z then FS_centralOperator
  else if (x =? 0)%Z && (0 <? y)%Z then FS_axialElan
  else if (x =? 0)%Z && (y <? 0)%Z then FS_axialWithdrawal
  else if (0 <? x)%Z && (y =? 0)%Z then FS_axialOpening
  else if (x <? 0)%Z && (y =? 0)%Z then FS_axialThreat
  else if (x =? y)%Z && (0 <? x)%Z then FS_diagonalDesire
  else if (x =? y)%Z && (x <? 0)%Z then FS_diagonalDisgust
  else if (x =? - y)%Z && (x <? 0)%Z then FS_diagonalAnger
  else if (x =? - y)%Z && (0 <? x)%Z then FS_diagonalCalm
  else if (Z.of_nat (Z.abs_nat x) <? y)%Z && (0 <? x)%Z then FS_lateralApproachSynergy
  else if (Z.of_nat (Z.abs_nat x) <? y)%Z && (x <? 0)%Z then FS_lateralDefensiveUrgency
  else if (Z.of_nat (Z.abs_nat x) <? - y)%Z && (0 <? x)%Z then FS_lateralTrophotropicPeace
  else if (Z.of_nat (Z.abs_nat x) <? - y)%Z && (x <? 0)%Z then FS_lateralAversiveDistress
  else if (Z.of_nat (Z.abs_nat y) <? x)%Z && (0 <? y)%Z then FS_lateralEpistemicMastery
  else if (Z.of_nat (Z.abs_nat y) <? x)%Z && (y <? 0)%Z then FS_lateralContemplativeOpen
  else if (Z.of_nat (Z.abs_nat y) <? - x)%Z && (0 <? y)%Z then FS_lateralVigilantAlert
  else FS_lateralEpistemicClosure.

Definition FunctionalSubsector_toTaxonomicGroup (s : FunctionalSubsector) : TaxonomicGroup :=
  match s with
  | FS_centralOperator          => TG_operateurCentral
  | FS_axialElan                => TG_groupeJoie
  | FS_lateralApproachSynergy   => TG_groupeJoie
  | FS_lateralDefensiveUrgency  => TG_groupeJoie
  | FS_axialWithdrawal          => TG_groupeTristesse
  | FS_lateralTrophotropicPeace => TG_groupeTristesse
  | FS_lateralAversiveDistress  => TG_groupeTristesse
  | FS_axialOpening             => TG_groupeCourage
  | FS_lateralEpistemicMastery  => TG_groupeCourage
  | FS_lateralContemplativeOpen => TG_groupeCourage
  | FS_axialThreat              => TG_groupePeur
  | FS_lateralVigilantAlert     => TG_groupePeur
  | FS_lateralEpistemicClosure  => TG_groupePeur
  | FS_diagonalDesire           => TG_groupeDesir
  | FS_diagonalDisgust          => TG_groupeDegout
  | FS_diagonalAnger            => TG_groupeColere
  | FS_diagonalCalm             => TG_groupeCalme
  end.

Definition FunctionalSubsector_toHedonicPolarity (s : FunctionalSubsector) : HedonicPolarity :=
  match s with
  | FS_centralOperator          => Hed_neutral
  | FS_axialElan                => Hed_positive
  | FS_axialOpening             => Hed_positive
  | FS_diagonalDesire           => Hed_positive
  | FS_diagonalCalm             => Hed_positive
  | FS_lateralApproachSynergy   => Hed_positive
  | FS_lateralTrophotropicPeace => Hed_positive
  | FS_lateralEpistemicMastery  => Hed_positive
  | FS_lateralContemplativeOpen => Hed_positive
  | FS_axialWithdrawal          => Hed_negative
  | FS_axialThreat              => Hed_negative
  | FS_diagonalDisgust          => Hed_negative
  | FS_diagonalAnger            => Hed_negative
  | FS_lateralDefensiveUrgency  => Hed_negative
  | FS_lateralAversiveDistress  => Hed_negative
  | FS_lateralVigilantAlert     => Hed_negative
  | FS_lateralEpistemicClosure  => Hed_negative
  end.

(** ** 2. Certification de la loi des effectifs et des 176 entrées (Z = 0 à Z = 7) *)

Definition crownPeripheralCount (z : nat) : nat := 4 * crownRadius z.

Definition stratumTotalCount (z : nat) : nat := 1 + crownPeripheralCount z.

Theorem inventory_176_certified :
  crownPeripheralCount 2 = 8 /\
  crownPeripheralCount 3 = 16 /\
  crownPeripheralCount 4 = 24 /\
  crownPeripheralCount 5 = 32 /\
  crownPeripheralCount 6 = 40 /\
  crownPeripheralCount 7 = 48 /\
  crownPeripheralCount 2 + crownPeripheralCount 3 + crownPeripheralCount 4 +
  crownPeripheralCount 5 + crownPeripheralCount 6 + crownPeripheralCount 7 = 168 /\
  stratumTotalCount 0 + stratumTotalCount 1 + stratumTotalCount 2 +
  stratumTotalCount 3 + stratumTotalCount 4 + stratumTotalCount 5 +
  stratumTotalCount 6 + stratumTotalCount 7 = 176.
Proof.
  repeat split; reflexivity.
Qed.

(** ** 3. Preuves de cohérence terminale : Exhaustivité et Exclusivité mutuelle *)

Theorem classifyTaxonomicGroup_correct :
  forall p : CoreAffectPoint, matchesTaxonomicGroup p (classifyTaxonomicGroup p).
Proof.
  intros [x y z].
  unfold classifyTaxonomicGroup, matchesTaxonomicGroup; simpl.
  destruct (Z.eqb_spec x 0) as [Hx0 | Hx0];
  destruct (Z.eqb_spec y 0) as [Hy0 | Hy0]; simpl;
    [split; lia | ..].
  all: destruct (Nat.ltb_spec0 (Z.abs_nat x) (Z.abs_nat y));
    [destruct (Z.ltb_spec0 0 y); simpl; (split; lia) |].
  all: destruct (Nat.ltb_spec0 (Z.abs_nat y) (Z.abs_nat x));
    [destruct (Z.ltb_spec0 x 0); simpl; (split; lia) |].
  all: destruct (Z.ltb_spec0 0 x); destruct (Z.ltb_spec0 0 y); simpl;
    repeat split; lia.
Qed.

Theorem taxonomy_group_exhaustive :
  forall p : CoreAffectPoint, exists g : TaxonomicGroup, matchesTaxonomicGroup p g.
Proof.
  intro p. exists (classifyTaxonomicGroup p). apply classifyTaxonomicGroup_correct.
Qed.

Theorem taxonomy_group_exclusive :
  forall (p : CoreAffectPoint) (g1 g2 : TaxonomicGroup),
    matchesTaxonomicGroup p g1 -> matchesTaxonomicGroup p g2 -> g1 = g2.
Proof.
  intros [x y z] [] [] H1 H2;
    unfold matchesTaxonomicGroup in H1, H2; simpl in H1, H2;
    try reflexivity; exfalso; lia.
Qed.

Theorem matchesTaxonomicGroup_iff :
  forall (p : CoreAffectPoint) (g : TaxonomicGroup),
    matchesTaxonomicGroup p g <-> g = classifyTaxonomicGroup p.
Proof.
  intros p g. split.
  - intro H.
    exact (taxonomy_group_exclusive p g (classifyTaxonomicGroup p) H (classifyTaxonomicGroup_correct p)).
  - intro H. subst g. apply classifyTaxonomicGroup_correct.
Qed.

Theorem dominantSector_iff_taxonomicGroup :
  forall p : CoreAffectPoint,
    (CoreAffectPoint_dominantSector p = Some Sec_joie <-> matchesTaxonomicGroup p TG_groupeJoie) /\
    (CoreAffectPoint_dominantSector p = Some Sec_tristesse <-> matchesTaxonomicGroup p TG_groupeTristesse) /\
    (CoreAffectPoint_dominantSector p = Some Sec_peur <-> matchesTaxonomicGroup p TG_groupePeur) /\
    (CoreAffectPoint_dominantSector p = Some Sec_courage <-> matchesTaxonomicGroup p TG_groupeCourage).
Proof.
  intros [x y z].
  unfold CoreAffectPoint_dominantSector, matchesTaxonomicGroup; simpl.
  split; [| split; [| split]]; split; intro H.
  - destruct (Nat.ltb_spec0 (Z.abs_nat x) (Z.abs_nat y));
      [destruct (Z.ltb_spec0 0 y); [split; lia | discriminate] |].
    destruct (Nat.ltb_spec0 (Z.abs_nat y) (Z.abs_nat x));
      [destruct (Z.ltb_spec0 x 0); discriminate | discriminate].
  - destruct H as [Hlt Hy].
    destruct (Nat.ltb_spec0 (Z.abs_nat x) (Z.abs_nat y)); [| lia].
    destruct (Z.ltb_spec0 0 y); [reflexivity | lia].
  - destruct (Nat.ltb_spec0 (Z.abs_nat x) (Z.abs_nat y));
      [destruct (Z.ltb_spec0 0 y); [discriminate | split; lia] |].
    destruct (Nat.ltb_spec0 (Z.abs_nat y) (Z.abs_nat x));
      [destruct (Z.ltb_spec0 x 0); discriminate | discriminate].
  - destruct H as [Hlt Hy].
    destruct (Nat.ltb_spec0 (Z.abs_nat x) (Z.abs_nat y)); [| lia].
    destruct (Z.ltb_spec0 0 y); [lia | reflexivity].
  - destruct (Nat.ltb_spec0 (Z.abs_nat x) (Z.abs_nat y));
      [destruct (Z.ltb_spec0 0 y); discriminate |].
    destruct (Nat.ltb_spec0 (Z.abs_nat y) (Z.abs_nat x));
      [destruct (Z.ltb_spec0 x 0); [split; lia | discriminate] | discriminate].
  - destruct H as [Hlt Hx].
    destruct (Nat.ltb_spec0 (Z.abs_nat x) (Z.abs_nat y)); [lia |].
    destruct (Nat.ltb_spec0 (Z.abs_nat y) (Z.abs_nat x)); [| lia].
    destruct (Z.ltb_spec0 x 0); [reflexivity | lia].
  - destruct (Nat.ltb_spec0 (Z.abs_nat x) (Z.abs_nat y));
      [destruct (Z.ltb_spec0 0 y); discriminate |].
    destruct (Nat.ltb_spec0 (Z.abs_nat y) (Z.abs_nat x));
      [destruct (Z.ltb_spec0 x 0); [discriminate | split; lia] | discriminate].
  - destruct H as [Hlt Hx].
    destruct (Nat.ltb_spec0 (Z.abs_nat x) (Z.abs_nat y)); [lia |].
    destruct (Nat.ltb_spec0 (Z.abs_nat y) (Z.abs_nat x)); [| lia].
    destruct (Z.ltb_spec0 x 0); [lia | reflexivity].
Qed.

Theorem contralateral_group_bindings :
  forall p : CoreAffectPoint,
    (matchesTaxonomicGroup p TG_groupeJoie /\ (pt_x p > 0)%Z ->
      matchesTaxonomicGroup (antagonistPoint p) TG_groupePeur /\ (pt_y (antagonistPoint p) < 0)%Z) /\
    (matchesTaxonomicGroup p TG_groupeJoie /\ (pt_x p < 0)%Z ->
      matchesTaxonomicGroup (antagonistPoint p) TG_groupeCourage /\ (pt_y (antagonistPoint p) < 0)%Z) /\
    (matchesTaxonomicGroup p TG_groupeTristesse /\ (pt_x p > 0)%Z ->
      matchesTaxonomicGroup (antagonistPoint p) TG_groupePeur /\ (pt_y (antagonistPoint p) > 0)%Z) /\
    (matchesTaxonomicGroup p TG_groupeTristesse /\ (pt_x p < 0)%Z ->
      matchesTaxonomicGroup (antagonistPoint p) TG_groupeCourage /\ (pt_y (antagonistPoint p) > 0)%Z).
Proof.
  intros [x y z].
  unfold matchesTaxonomicGroup, antagonistPoint; simpl.
  split; [| split; [| split]]; intros [[Hdom Hsign] Hsec];
    destruct (Z.eqb_spec x 0); try lia;
    destruct (Z.eqb_spec y 0); try lia;
    destruct (Nat.eqb_spec (Z.abs_nat x) (Z.abs_nat y)); try lia;
    simpl;
    try (destruct (Z.ltb_spec0 0 x); try lia);
    try (destruct (Z.ltb_spec0 x 0); try lia);
    try (destruct (Z.ltb_spec0 0 y); try lia);
    try (destruct (Z.ltb_spec0 y 0); try lia);
    simpl; repeat split; lia.
Qed.

Definition matchesSubsector (x y : Z) (s : FunctionalSubsector) : Prop :=
  match s with
  | FS_centralOperator          => x = 0%Z /\ y = 0%Z
  | FS_axialElan                => x = 0%Z /\ (y > 0)%Z
  | FS_axialWithdrawal          => x = 0%Z /\ (y < 0)%Z
  | FS_axialOpening             => (x > 0)%Z /\ y = 0%Z
  | FS_axialThreat              => (x < 0)%Z /\ y = 0%Z
  | FS_diagonalDesire           => x = y /\ (x > 0)%Z
  | FS_diagonalDisgust          => x = y /\ (x < 0)%Z
  | FS_diagonalAnger            => x = (- y)%Z /\ (x < 0)%Z
  | FS_diagonalCalm             => x = (- y)%Z /\ (x > 0)%Z
  | FS_lateralApproachSynergy   => (y > Z.of_nat (Z.abs_nat x))%Z /\ (x > 0)%Z
  | FS_lateralDefensiveUrgency  => (y > Z.of_nat (Z.abs_nat x))%Z /\ (x < 0)%Z
  | FS_lateralTrophotropicPeace => (- y > Z.of_nat (Z.abs_nat x))%Z /\ (x > 0)%Z
  | FS_lateralAversiveDistress  => (- y > Z.of_nat (Z.abs_nat x))%Z /\ (x < 0)%Z
  | FS_lateralEpistemicMastery  => (x > Z.of_nat (Z.abs_nat y))%Z /\ (y > 0)%Z
  | FS_lateralContemplativeOpen => (x > Z.of_nat (Z.abs_nat y))%Z /\ (y < 0)%Z
  | FS_lateralVigilantAlert     => (- x > Z.of_nat (Z.abs_nat y))%Z /\ (y > 0)%Z
  | FS_lateralEpistemicClosure  => (- x > Z.of_nat (Z.abs_nat y))%Z /\ (y < 0)%Z
  end.

Theorem classifySubsector_correct :
  forall x y : Z, matchesSubsector x y (classifySubsector x y).
Proof.
  intros x y.
  unfold classifySubsector, matchesSubsector.
  destruct (Z.eqb_spec x 0); destruct (Z.eqb_spec y 0);
  try (destruct (Z.ltb_spec0 0 x)); try (destruct (Z.ltb_spec0 x 0));
  try (destruct (Z.ltb_spec0 0 y)); try (destruct (Z.ltb_spec0 y 0));
  try (exfalso; lia);
  simpl; try (split; lia);
  repeat (
    match goal with
    | |- context [ (?a =? ?b)%Z ] => destruct (Z.eqb_spec a b)
    | |- context [ (?a <? ?b)%Z ] => destruct (Z.ltb_spec0 a b)
    end;
    simpl;
    try (exfalso; lia);
    try (split; lia)
  ).
Qed.

Theorem subsector_exclusive :
  forall (x y : Z) (s1 s2 : FunctionalSubsector),
    matchesSubsector x y s1 -> matchesSubsector x y s2 -> s1 = s2.
Proof.
  intros x y [] [] H1 H2;
    unfold matchesSubsector in H1, H2;
    try reflexivity; exfalso; lia.
Qed.

Theorem matchesSubsector_iff :
  forall (x y : Z) (s : FunctionalSubsector),
    matchesSubsector x y s <-> s = classifySubsector x y.
Proof.
  intros x y s. split.
  - intro H.
    exact (subsector_exclusive x y s (classifySubsector x y) H (classifySubsector_correct x y)).
  - intro H. subst s. apply classifySubsector_correct.
Qed.

Theorem matchesSubsector_toTaxonomicGroup :
  forall (p : CoreAffectPoint) (s : FunctionalSubsector),
    matchesSubsector (pt_x p) (pt_y p) s ->
    matchesTaxonomicGroup p (FunctionalSubsector_toTaxonomicGroup s).
Proof.
  intros [x y z] [] H;
    unfold matchesSubsector, FunctionalSubsector_toTaxonomicGroup, matchesTaxonomicGroup in *;
    simpl in *; repeat split; lia.
Qed.

Theorem classifySubsector_refines_group :
  forall p : CoreAffectPoint,
    FunctionalSubsector_toTaxonomicGroup (classifySubsector (pt_x p) (pt_y p)) =
    classifyTaxonomicGroup p.
Proof.
  intro p.
  apply (proj1 (matchesTaxonomicGroup_iff p _)).
  apply matchesSubsector_toTaxonomicGroup.
  apply classifySubsector_correct.
Qed.

Theorem matchesSubsector_toHedonicPolarity :
  forall (x y : Z) (s : FunctionalSubsector),
    matchesSubsector x y s ->
    FunctionalSubsector_toHedonicPolarity s = computeHedonicPolarity x y.
Proof.
  intros x y [] H;
    unfold matchesSubsector, FunctionalSubsector_toHedonicPolarity, computeHedonicPolarity in *;
    try (destruct (Z.ltb_spec0 0 x); try lia);
    try (destruct (Z.ltb_spec0 x 0); try lia);
    try (destruct (Z.ltb_spec0 0 y); try lia);
    try (destruct (Z.ltb_spec0 y 0); try lia);
    reflexivity.
Qed.

Theorem classifySubsector_determines_valence :
  forall x y : Z,
    FunctionalSubsector_toHedonicPolarity (classifySubsector x y) = computeHedonicPolarity x y.
Proof.
  intros x y.
  apply matchesSubsector_toHedonicPolarity.
  apply classifySubsector_correct.
Qed.

(** ** 4. Structure finale TaxonomicState et Théorème Maître (end_to_end_coherence) *)

Record TaxonomicState : Type := mkTaxonomicState {
  ts_matrix              : AffectiveMatrixState;
  ts_stratum             : TaxonomicStratum;
  ts_geometry            : GeometryType;
  ts_group               : TaxonomicGroup;
  ts_subsector           : FunctionalSubsector;
  ts_antagonistGroup     : TaxonomicGroup;
  ts_antagonistSubsector : FunctionalSubsector
}.

Definition evaluateTaxonomy (ms : AffectiveMatrixState) : TaxonomicState :=
  let p := cas_point (ams_core ms) in
  let ap := cas_point (ams_antagonist ms) in
  {|
    ts_matrix              := ms;
    ts_stratum             := classifyStratum (pt_z p);
    ts_geometry            := CoreAffectPoint_classifyGeometry p;
    ts_group               := classifyTaxonomicGroup p;
    ts_subsector           := classifySubsector (pt_x p) (pt_y p);
    ts_antagonistGroup     := classifyTaxonomicGroup ap;
    ts_antagonistSubsector := classifySubsector (pt_x ap) (pt_y ap)
  |}.

Definition defaultTaxonomicState : TaxonomicState :=
  evaluateTaxonomy defaultAffectiveMatrixState.

Definition runCartograffectPipeline (s : PredictiveEngineState) : TaxonomicState :=
  evaluateTaxonomy (evaluateMatrix (evaluateCoreAffect s) canonicalMapping).

Definition isCoherentTerminalState (s : PredictiveEngineState) (ts : TaxonomicState) : Prop :=
  let cp := cas_point (ams_core (ts_matrix ts)) in
  let ap := cas_point (ams_antagonist (ts_matrix ts)) in
  cp = projectToCoreAffect s /\
  isValidCoreAffect cp /\
  ap = antagonistPoint cp /\
  isValidCoreAffect ap /\
  pt_z ap = pt_z cp /\
  CoreAffectPoint_displacementSum ap = CoreAffectPoint_displacementSum cp /\
  ams_expectationPole (ts_matrix ts) = transduceExpectation (pt_x cp) /\
  ams_controlPole (ts_matrix ts) = transduceControl (pt_y cp) /\
  ams_energyRegime (ts_matrix ts) = computeEnergyRegime (pt_x cp) (pt_y cp) /\
  ams_valence (ts_matrix ts) = computeHedonicPolarity (pt_x cp) (pt_y cp) /\
  ams_activation (ts_matrix ts) = computeActivation cp /\
  ts_stratum ts = classifyStratum (pt_z cp) /\
  ts_geometry ts = CoreAffectPoint_classifyGeometry cp /\
  ts_subsector ts = classifySubsector (pt_x cp) (pt_y cp) /\
  ts_antagonistSubsector ts = classifySubsector (pt_x ap) (pt_y ap) /\
  matchesTaxonomicGroup cp (ts_group ts) /\
  (forall g : TaxonomicGroup, matchesTaxonomicGroup cp g -> g = ts_group ts) /\
  matchesTaxonomicGroup ap (ts_antagonistGroup ts).

Theorem end_to_end_coherence :
  forall s : PredictiveEngineState,
    exists ts : TaxonomicState,
      isCoherentTerminalState s ts /\
      forall ts' : TaxonomicState, isCoherentTerminalState s ts' -> ts' = ts.
Proof.
  intro s.
  exists (runCartograffectPipeline s).
  split.
  - unfold isCoherentTerminalState, runCartograffectPipeline,
      evaluateTaxonomy, evaluateMatrix, evaluateCoreAffect, canonicalMapping; simpl.
    repeat split.
    + apply engine_induces_valid_core_affect.
    + apply antagonistPoint_preserves_validity, engine_induces_valid_core_affect.
    + apply antagonistPoint_preserves_z.
    + apply antagonistPoint_preserves_displacementSum.
    + apply classifyTaxonomicGroup_correct.
    + intros g Hg.
      exact (taxonomy_group_exclusive (projectToCoreAffect s) g
        (classifyTaxonomicGroup (projectToCoreAffect s)) Hg
        (classifyTaxonomicGroup_correct (projectToCoreAffect s))).
    + apply classifyTaxonomicGroup_correct.
  - intros ts' Hts'.
    destruct ts' as [[core ep ctrlp ereg val act ant] strat geom grp sub agrp asub].
    destruct Hts' as [Hcp [_ [Hap [_ [_ [_ [Hep [Hctrl [Hereg [Hval [Hact
      [Hstrat [Hgeom [Hsub [Hasub [Hgrp [_ Hagrp]]]]]]]]]]]]]]]]].
    simpl in *.
    unfold runCartograffectPipeline, evaluateTaxonomy, evaluateMatrix,
      evaluateCoreAffect, canonicalMapping; simpl.
    assert (Hcore_eq : core = mkCoreAffectState (projectToCoreAffect s) (engine_induces_valid_core_affect s))
      by (apply CoreAffectState_eq; exact Hcp).
    assert (Hant_eq : ant = {|
      cas_point := antagonistPoint (projectToCoreAffect s);
      cas_valid := antagonistPoint_preserves_validity (projectToCoreAffect s)
                     (engine_induces_valid_core_affect s)
    |}) by (apply CoreAffectState_eq; simpl; rewrite Hap, Hcp; reflexivity).
    assert (Hgrp_eq : grp = classifyTaxonomicGroup (projectToCoreAffect s)).
    { apply (proj1 (matchesTaxonomicGroup_iff (projectToCoreAffect s) grp)).
      rewrite <- Hcp. exact Hgrp. }
    assert (Hagrp_eq : agrp = classifyTaxonomicGroup (antagonistPoint (projectToCoreAffect s))).
    { apply (proj1 (matchesTaxonomicGroup_iff (antagonistPoint (projectToCoreAffect s)) agrp)).
      rewrite <- Hcp, <- Hap. exact Hagrp. }
    subst.
    reflexivity.
Qed.
