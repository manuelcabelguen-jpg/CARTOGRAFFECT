(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*)

From Stdlib Require Import Bool Arith PeanoNat ZArith Lia String List.
Import ListNotations.
Require Import CartograffectRocq.PredictiveEngine.
Require Import CartograffectRocq.CoreAffect.
Require Import CartograffectRocq.AffectiveMatrix.
Require Import CartograffectRocq.AffectiveTaxonomy.

Open Scope bool_scope.
Open Scope nat_scope.

(** * Module Lexicon176 — Validation Rocq 9.1.0 *)

Record LexiconEntry : Type := mkLexiconEntry {
  le_label : string;
  le_point : CoreAffectPoint
}.

Definition LexiconEntry_x (e : LexiconEntry) : Z := pt_x (le_point e).
Definition LexiconEntry_y (e : LexiconEntry) : Z := pt_y (le_point e).
Definition LexiconEntry_z (e : LexiconEntry) : nat := pt_z (le_point e).

Definition isValidPointBool (p : CoreAffectPoint) : bool :=
  ((pt_x p =? 0)%Z && (pt_y p =? 0)%Z) ||
  (Nat.leb 2 (pt_z p) && Nat.eqb (CoreAffectPoint_displacementSum p) (crownRadius (pt_z p))).

Definition all176Entries : list LexiconEntry := [
  (* Strate Z = 0 (1 entrée) *)
  mkLexiconEntry "Point de Veille" (mkPoint 0%Z 0%Z 0);

  (* Strate Z = 1 (1 entrée) *)
  mkLexiconEntry "Surprise" (mkPoint 0%Z 0%Z 1);

  (* Strate Z = 2 (9 entrées : 1 centre, 4 axiales, 4 diagonales) *)
  mkLexiconEntry "Anticipation" (mkPoint 0%Z 0%Z 2);
  mkLexiconEntry "Joie" (mkPoint 0%Z 2%Z 2);
  mkLexiconEntry "Tristesse" (mkPoint 0%Z (-2)%Z 2);
  mkLexiconEntry "Peur" (mkPoint (-2)%Z 0%Z 2);
  mkLexiconEntry "Courage" (mkPoint 2%Z 0%Z 2);
  mkLexiconEntry "Colère" (mkPoint (-1)%Z 1%Z 2);
  mkLexiconEntry "Calme" (mkPoint 1%Z (-1)%Z 2);
  mkLexiconEntry "Désir" (mkPoint 1%Z 1%Z 2);
  mkLexiconEntry "Dégoût" (mkPoint (-1)%Z (-1)%Z 2);

  (* Strate Z = 3 (17 entrées : 1 centre, 4 axiales, 8 latérales, 4 diagonales) *)
  mkLexiconEntry "Émoi" (mkPoint 0%Z 0%Z 3);
  mkLexiconEntry "Enthousiasme" (mkPoint 0%Z 4%Z 3);
  mkLexiconEntry "Ennui" (mkPoint 0%Z (-4)%Z 3);
  mkLexiconEntry "Crainte" (mkPoint (-4)%Z 0%Z 3);
  mkLexiconEntry "Curiosité" (mkPoint 4%Z 0%Z 3);
  mkLexiconEntry "Consternation" (mkPoint (-1)%Z 3%Z 3);
  mkLexiconEntry "Euphorie" (mkPoint 1%Z 3%Z 3);
  mkLexiconEntry "Soulagement" (mkPoint 1%Z (-3)%Z 3);
  mkLexiconEntry "Chagrin" (mkPoint (-1)%Z (-3)%Z 3);
  mkLexiconEntry "Panique" (mkPoint (-3)%Z 1%Z 3);
  mkLexiconEntry "Effroi" (mkPoint (-3)%Z (-1)%Z 3);
  mkLexiconEntry "Émerveillement" (mkPoint 3%Z (-1)%Z 3);
  mkLexiconEntry "Aplomb" (mkPoint 3%Z 1%Z 3);
  mkLexiconEntry "Exaspération" (mkPoint (-2)%Z 2%Z 3);
  mkLexiconEntry "Détente" (mkPoint 2%Z (-2)%Z 3);
  mkLexiconEntry "Attrait" (mkPoint 2%Z 2%Z 3);
  mkLexiconEntry "Retrait" (mkPoint (-2)%Z (-2)%Z 3);

  (* Strate Z = 4 (25 entrées : 1 centre, 4 axiales, 16 latérales, 4 diagonales) *)
  mkLexiconEntry "Réserve" (mkPoint 0%Z 0%Z 4);
  mkLexiconEntry "Exaltation" (mkPoint 0%Z 6%Z 4);
  mkLexiconEntry "Langueur" (mkPoint 0%Z (-6)%Z 4);
  mkLexiconEntry "Doute" (mkPoint (-6)%Z 0%Z 4);
  mkLexiconEntry "Assurance" (mkPoint 6%Z 0%Z 4);
  mkLexiconEntry "Envie" (mkPoint (-2)%Z 4%Z 4);
  mkLexiconEntry "Haine" (mkPoint (-1)%Z 5%Z 4);
  mkLexiconEntry "Amour" (mkPoint 1%Z 5%Z 4);
  mkLexiconEntry "Ferveur" (mkPoint 2%Z 4%Z 4);
  mkLexiconEntry "Sérénité" (mkPoint 2%Z (-4)%Z 4);
  mkLexiconEntry "Plénitude" (mkPoint 1%Z (-5)%Z 4);
  mkLexiconEntry "Honte" (mkPoint (-2)%Z (-4)%Z 4);
  mkLexiconEntry "Vide" (mkPoint (-1)%Z (-5)%Z 4);
  mkLexiconEntry "Anxiété" (mkPoint (-4)%Z 2%Z 4);
  mkLexiconEntry "Manque" (mkPoint (-5)%Z 1%Z 4);
  mkLexiconEntry "Mépris" (mkPoint (-5)%Z (-1)%Z 4);
  mkLexiconEntry "Défiance" (mkPoint (-4)%Z (-2)%Z 4);
  mkLexiconEntry "Fierté" (mkPoint 4%Z 2%Z 4);
  mkLexiconEntry "Épanouissement" (mkPoint 5%Z 1%Z 4);
  mkLexiconEntry "Affection" (mkPoint 5%Z (-1)%Z 4);
  mkLexiconEntry "Admiration" (mkPoint 4%Z (-2)%Z 4);
  mkLexiconEntry "Frustration" (mkPoint (-3)%Z 3%Z 4);
  mkLexiconEntry "Acceptation" (mkPoint 3%Z (-3)%Z 4);
  mkLexiconEntry "Estime" (mkPoint 3%Z 3%Z 4);
  mkLexiconEntry "Rejet" (mkPoint (-3)%Z (-3)%Z 4);

  (* Strate Z = 5 (33 entrées : 1 centre, 4 axiales, 24 latérales, 4 diagonales) *)
  mkLexiconEntry "Recul" (mkPoint 0%Z 0%Z 5);
  mkLexiconEntry "Puissance" (mkPoint 0%Z 8%Z 5);
  mkLexiconEntry "Impuissance" (mkPoint 0%Z (-8)%Z 5);
  mkLexiconEntry "Méfiance" (mkPoint (-8)%Z 0%Z 5);
  mkLexiconEntry "Confiance" (mkPoint 8%Z 0%Z 5);
  mkLexiconEntry "Invulnérabilité" (mkPoint 1%Z 7%Z 5);
  mkLexiconEntry "Attachement" (mkPoint 2%Z 6%Z 5);
  mkLexiconEntry "Engagement" (mkPoint 3%Z 5%Z 5);
  mkLexiconEntry "Désenchantement" (mkPoint (-2)%Z 6%Z 5);
  mkLexiconEntry "Intolérance" (mkPoint (-3)%Z 5%Z 5);
  mkLexiconEntry "Injustice" (mkPoint (-1)%Z 7%Z 5);
  mkLexiconEntry "Quiétude" (mkPoint 3%Z (-5)%Z 5);
  mkLexiconEntry "Sécurité" (mkPoint 2%Z (-6)%Z 5);
  mkLexiconEntry "Patience" (mkPoint 1%Z (-7)%Z 5);
  mkLexiconEntry "Pessimisme" (mkPoint (-2)%Z (-6)%Z 5);
  mkLexiconEntry "Fermeture" (mkPoint (-3)%Z (-5)%Z 5);
  mkLexiconEntry "Désespoir" (mkPoint (-1)%Z (-7)%Z 5);
  mkLexiconEntry "Insécurité" (mkPoint (-6)%Z 2%Z 5);
  mkLexiconEntry "Inquiétude" (mkPoint (-5)%Z 3%Z 5);
  mkLexiconEntry "Impatience" (mkPoint (-7)%Z 1%Z 5);
  mkLexiconEntry "Vulnérabilité" (mkPoint (-7)%Z (-1)%Z 5);
  mkLexiconEntry "Détachement" (mkPoint (-6)%Z (-2)%Z 5);
  mkLexiconEntry "Désengagement" (mkPoint (-5)%Z (-3)%Z 5);
  mkLexiconEntry "Optimisme" (mkPoint 6%Z 2%Z 5);
  mkLexiconEntry "Ouverture" (mkPoint 5%Z 3%Z 5);
  mkLexiconEntry "Espoir" (mkPoint 7%Z 1%Z 5);
  mkLexiconEntry "Enchantement" (mkPoint 6%Z (-2)%Z 5);
  mkLexiconEntry "Tolérance" (mkPoint 5%Z (-3)%Z 5);
  mkLexiconEntry "Justice" (mkPoint 7%Z (-1)%Z 5);
  mkLexiconEntry "Insatisfaction" (mkPoint (-4)%Z 4%Z 5);
  mkLexiconEntry "Satisfaction" (mkPoint 4%Z (-4)%Z 5);
  mkLexiconEntry "Intérêt" (mkPoint 4%Z 4%Z 5);
  mkLexiconEntry "Désintérêt" (mkPoint (-4)%Z (-4)%Z 5);

  (* Strate Z = 6 (41 entrées : 1 centre, 4 axiales, 32 latérales, 4 diagonales) *)
  mkLexiconEntry "Saisissement" (mkPoint 0%Z 0%Z 6);
  mkLexiconEntry "Élan" (mkPoint 0%Z 10%Z 6);
  mkLexiconEntry "Inertie" (mkPoint 0%Z (-10)%Z 6);
  mkLexiconEntry "Effacement" (mkPoint (-10)%Z 0%Z 6);
  mkLexiconEntry "Affirmation" (mkPoint 10%Z 0%Z 6);
  mkLexiconEntry "Ardeur" (mkPoint 3%Z 7%Z 6);
  mkLexiconEntry "Angoisse" (mkPoint (-3)%Z 7%Z 6);
  mkLexiconEntry "Allégresse" (mkPoint 4%Z 6%Z 6);
  mkLexiconEntry "Fureur" (mkPoint (-4)%Z 6%Z 6);
  mkLexiconEntry "Fougue" (mkPoint 2%Z 8%Z 6);
  mkLexiconEntry "Frénésie" (mkPoint (-2)%Z 8%Z 6);
  mkLexiconEntry "Jubilation" (mkPoint 1%Z 9%Z 6);
  mkLexiconEntry "Terreur" (mkPoint (-1)%Z 9%Z 6);
  mkLexiconEntry "Béatitude" (mkPoint 3%Z (-7)%Z 6);
  mkLexiconEntry "Accablement" (mkPoint (-3)%Z (-7)%Z 6);
  mkLexiconEntry "Apaisement" (mkPoint 4%Z (-6)%Z 6);
  mkLexiconEntry "Morosité" (mkPoint (-4)%Z (-6)%Z 6);
  mkLexiconEntry "Contemplation" (mkPoint 2%Z (-8)%Z 6);
  mkLexiconEntry "Prostration" (mkPoint (-2)%Z (-8)%Z 6);
  mkLexiconEntry "Félicité" (mkPoint 1%Z (-9)%Z 6);
  mkLexiconEntry "Désolation" (mkPoint (-1)%Z (-9)%Z 6);
  mkLexiconEntry "Rancœur" (mkPoint (-6)%Z 4%Z 6);
  mkLexiconEntry "Amertume" (mkPoint (-6)%Z (-4)%Z 6);
  mkLexiconEntry "Affolement" (mkPoint (-7)%Z 3%Z 6);
  mkLexiconEntry "Écrasement" (mkPoint (-7)%Z (-3)%Z 6);
  mkLexiconEntry "Fébrilité" (mkPoint (-8)%Z 2%Z 6);
  mkLexiconEntry "Anéantissement" (mkPoint (-8)%Z (-2)%Z 6);
  mkLexiconEntry "Désarroi" (mkPoint (-9)%Z 1%Z 6);
  mkLexiconEntry "Lassitude" (mkPoint (-9)%Z (-1)%Z 6);
  mkLexiconEntry "Entrain" (mkPoint 6%Z 4%Z 6);
  mkLexiconEntry "Placidité" (mkPoint 6%Z (-4)%Z 6);
  mkLexiconEntry "Liesse" (mkPoint 7%Z 3%Z 6);
  mkLexiconEntry "Limpidité" (mkPoint 7%Z (-3)%Z 6);
  mkLexiconEntry "Extase" (mkPoint 8%Z 2%Z 6);
  mkLexiconEntry "Équanimité" (mkPoint 8%Z (-2)%Z 6);
  mkLexiconEntry "Exultation" (mkPoint 9%Z 1%Z 6);
  mkLexiconEntry "Harmonie" (mkPoint 9%Z (-1)%Z 6);
  mkLexiconEntry "Tourment" (mkPoint (-5)%Z 5%Z 6);
  mkLexiconEntry "Ataraxie" (mkPoint 5%Z (-5)%Z 6);
  mkLexiconEntry "Triomphe" (mkPoint 5%Z 5%Z 6);
  mkLexiconEntry "Abattement" (mkPoint (-5)%Z (-5)%Z 6);

  (* Strate Z = 7 (49 entrées : 1 centre, 4 axiales, 40 latérales, 4 diagonales) *)
  mkLexiconEntry "Suspension" (mkPoint 0%Z 0%Z 7);
  mkLexiconEntry "Infini" (mkPoint 0%Z 12%Z 7);
  mkLexiconEntry "Néant" (mkPoint 0%Z (-12)%Z 7);
  mkLexiconEntry "Déréliction" (mkPoint (-12)%Z 0%Z 7);
  mkLexiconEntry "Communion" (mkPoint 12%Z 0%Z 7);
  mkLexiconEntry "Transcendance" (mkPoint 2%Z 10%Z 7);
  mkLexiconEntry "Déchirement" (mkPoint (-2)%Z 10%Z 7);
  mkLexiconEntry "Exubérance" (mkPoint 4%Z 8%Z 7);
  mkLexiconEntry "Horreur" (mkPoint (-4)%Z 8%Z 7);
  mkLexiconEntry "Renaissance" (mkPoint 1%Z 11%Z 7);
  mkLexiconEntry "Vertige" (mkPoint (-1)%Z 11%Z 7);
  mkLexiconEntry "Élévation" (mkPoint 3%Z 9%Z 7);
  mkLexiconEntry "Détresse" (mkPoint (-3)%Z 9%Z 7);
  mkLexiconEntry "Enivrement" (mkPoint 5%Z 7%Z 7);
  mkLexiconEntry "Révolte" (mkPoint (-5)%Z 7%Z 7);
  mkLexiconEntry "Nirvana" (mkPoint 2%Z (-10)%Z 7);
  mkLexiconEntry "Perdition" (mkPoint (-2)%Z (-10)%Z 7);
  mkLexiconEntry "Paix" (mkPoint 4%Z (-8)%Z 7);
  mkLexiconEntry "Oppression" (mkPoint (-4)%Z (-8)%Z 7);
  mkLexiconEntry "Pérennité" (mkPoint 1%Z (-11)%Z 7);
  mkLexiconEntry "Abîme" (mkPoint (-1)%Z (-11)%Z 7);
  mkLexiconEntry "Abandon" (mkPoint 3%Z (-9)%Z 7);
  mkLexiconEntry "Damnation" (mkPoint (-3)%Z (-9)%Z 7);
  mkLexiconEntry "Silence" (mkPoint 5%Z (-7)%Z 7);
  mkLexiconEntry "Résignation" (mkPoint (-5)%Z (-7)%Z 7);
  mkLexiconEntry "Hantise" (mkPoint (-10)%Z 2%Z 7);
  mkLexiconEntry "Isolement" (mkPoint (-10)%Z (-2)%Z 7);
  mkLexiconEntry "Affliction" (mkPoint (-8)%Z 4%Z 7);
  mkLexiconEntry "Mélancolie" (mkPoint (-8)%Z (-4)%Z 7);
  mkLexiconEntry "Précarité" (mkPoint (-11)%Z 1%Z 7);
  mkLexiconEntry "Déchéance" (mkPoint (-11)%Z (-1)%Z 7);
  mkLexiconEntry "Sidération" (mkPoint (-9)%Z 3%Z 7);
  mkLexiconEntry "Engloutissement" (mkPoint (-9)%Z (-3)%Z 7);
  mkLexiconEntry "Tumulte" (mkPoint (-7)%Z 5%Z 7);
  mkLexiconEntry "Pétrification" (mkPoint (-7)%Z (-5)%Z 7);
  mkLexiconEntry "Éblouissement" (mkPoint 10%Z 2%Z 7);
  mkLexiconEntry "Recueillement" (mkPoint 10%Z (-2)%Z 7);
  mkLexiconEntry "Rayonnement" (mkPoint 8%Z 4%Z 7);
  mkLexiconEntry "Contentement" (mkPoint 8%Z (-4)%Z 7);
  mkLexiconEntry "Ravissement" (mkPoint 11%Z 1%Z 7);
  mkLexiconEntry "Épiphanie" (mkPoint 11%Z (-1)%Z 7);
  mkLexiconEntry "Louange" (mkPoint 9%Z 3%Z 7);
  mkLexiconEntry "Lucidité" (mkPoint 9%Z (-3)%Z 7);
  mkLexiconEntry "Effusion" (mkPoint 7%Z 5%Z 7);
  mkLexiconEntry "Consentement" (mkPoint 7%Z (-5)%Z 7);
  mkLexiconEntry "Rage" (mkPoint (-6)%Z 6%Z 7);
  mkLexiconEntry "Impassibilité" (mkPoint 6%Z (-6)%Z 7);
  mkLexiconEntry "Sublimation" (mkPoint 6%Z 6%Z 7);
  mkLexiconEntry "Dissolution" (mkPoint (-6)%Z (-6)%Z 7)
].

Definition mem_point_list (q : CoreAffectPoint) (l : list CoreAffectPoint) : bool :=
  existsb (CoreAffectPoint_eqb q) l.

Lemma mem_point_list_iff :
  forall (q : CoreAffectPoint) (l : list CoreAffectPoint),
    mem_point_list q l = true <-> In q l.
Proof.
  intros q l. unfold mem_point_list.
  rewrite existsb_exists. split.
  - intros [x [Hx Heq]]. apply (proj1 (CoreAffectPoint_eqb_eq _ _)) in Heq. subst; exact Hx.
  - intro H. exists q. split; [exact H | apply (proj2 (CoreAffectPoint_eqb_eq _ _)); reflexivity].
Qed.

Fixpoint nodupb (l : list CoreAffectPoint) : bool :=
  match l with
  | [] => true
  | h :: t => negb (mem_point_list h t) && nodupb t
  end.

Lemma nodupb_NoDup :
  forall l : list CoreAffectPoint, nodupb l = true -> NoDup l.
Proof.
  induction l as [| h t IH]; intro H; simpl in *.
  - constructor.
  - rewrite andb_true_iff in H. destruct H as [Hnin Hrest].
    constructor.
    + intro Hin. apply (proj2 (mem_point_list_iff h t)) in Hin.
      rewrite Hin in Hnin. discriminate.
    + exact (IH Hrest).
Qed.

Theorem all176Entries_length : List.length all176Entries = 176.
Proof. reflexivity. Qed.

Theorem all176Entries_geometrically_valid :
  forallb (fun e => isValidPointBool (le_point e)) all176Entries = true.
Proof.
  vm_compute. reflexivity.
Qed.

Theorem all176Entries_unique_points :
  NoDup (map le_point all176Entries).
Proof.
  apply nodupb_NoDup. vm_compute. reflexivity.
Qed.

Theorem all176Entries_closed_under_antagonist :
  forallb (fun e => mem_point_list (antagonistPoint (le_point e)) (map le_point all176Entries))
    all176Entries = true.
Proof.
  vm_compute. reflexivity.
Qed.

Definition signVariants (ax ay z : nat) : list CoreAffectPoint :=
  let x := Z.of_nat ax in
  let y := Z.of_nat ay in
  [mkPoint x y z; mkPoint x (- y)%Z z; mkPoint (- x)%Z y z; mkPoint (- x)%Z (- y)%Z z].

Lemma mem_signVariants :
  forall p : CoreAffectPoint,
    In p (signVariants (Z.abs_nat (pt_x p)) (Z.abs_nat (pt_y p)) (pt_z p)).
Proof.
  intros [x y z]; unfold signVariants; simpl.
  assert (Hx : x = Z.of_nat (Z.abs_nat x) \/ x = (- Z.of_nat (Z.abs_nat x))%Z) by lia.
  assert (Hy : y = Z.of_nat (Z.abs_nat y) \/ y = (- Z.of_nat (Z.abs_nat y))%Z) by lia.
  destruct Hx as [Hx | Hx]; destruct Hy as [Hy | Hy];
    rewrite <- Hx, <- Hy; simpl; tauto.
Qed.

Definition stratumValidGrid (z : nat) : list CoreAffectPoint :=
  mkPoint 0%Z 0%Z z ::
  flat_map (fun ax => signVariants ax (crownRadius z - ax) z) (seq 0 (crownRadius z + 1)).

Lemma mem_stratumValidGrid :
  forall p : CoreAffectPoint, isValidCoreAffect p -> In p (stratumValidGrid (pt_z p)).
Proof.
  intros [x y z] [[Hx Hy] | [Hz Hsum]].
  - unfold CoreAffectPoint_isCentral in Hx, Hy; simpl in Hx, Hy.
    subst x y. left. reflexivity.
  - unfold CoreAffectPoint_isOnCrown, CoreAffectPoint_displacementSum in Hz, Hsum; simpl in *.
    right. apply in_flat_map.
    exists (Z.abs_nat x). split.
    + apply in_seq. lia.
    + replace (crownRadius z - Z.abs_nat x) with (Z.abs_nat y) by lia.
      apply (mem_signVariants (mkPoint x y z)).
Qed.

Theorem stratumValidGrid_sub_all176 :
  forall z : nat, z <= 7 ->
    forall q : CoreAffectPoint,
      In q (stratumValidGrid z) -> In q (map le_point all176Entries).
Proof.
  intros z Hz q Hq.
  apply (proj1 (mem_point_list_iff q (map le_point all176Entries))).
  assert (Hall : forallb (fun p => mem_point_list p (map le_point all176Entries)) (stratumValidGrid z) = true).
  { destruct z as [| [| [| [| [| [| [| [| k]]]]]]]]; try lia; vm_compute; reflexivity. }
  exact (proj1 (forallb_forall _ (stratumValidGrid z)) Hall q Hq).
Qed.

Theorem all176Entries_spatial_completeness :
  forall p : CoreAffectPoint,
    pt_z p <= 7 ->
    isValidCoreAffect p ->
    In p (map le_point all176Entries).
Proof.
  intros p Hz Hv.
  apply (stratumValidGrid_sub_all176 (pt_z p) Hz p).
  apply mem_stratumValidGrid. exact Hv.
Qed.

Lemma isValidCoreAffect_of_bool :
  forall p : CoreAffectPoint, isValidPointBool p = true -> isValidCoreAffect p.
Proof.
  intros [x y z] H.
  unfold isValidPointBool, isValidCoreAffect,
    CoreAffectPoint_isCentral, CoreAffectPoint_isOnCrown in *; cbn [pt_x pt_y pt_z] in *.
  rewrite orb_true_iff, !andb_true_iff, !Z.eqb_eq, Nat.leb_le, Nat.eqb_eq in H.
  destruct H as [[Hx Hy] | [Hz Hsum]]; [left; split; assumption | right; split; [lia | exact Hsum]].
Qed.

Theorem all176Entries_deterministically_reachable :
  forall e : LexiconEntry,
    In e all176Entries ->
    exists s : PredictiveEngineState,
      cas_point (ams_core (ts_matrix (runCartograffectPipeline s))) = le_point e.
Proof.
  intros e He.
  assert (Hbool : isValidPointBool (le_point e) = true).
  { exact (proj1 (forallb_forall _ all176Entries) all176Entries_geometrically_valid e He). }
  pose proof (isValidCoreAffect_of_bool (le_point e) Hbool) as Hvalid.
  exists (witnessEngineForPoint (le_point e)).
  apply projectToCoreAffect_surjective. exact Hvalid.
Qed.

Theorem all176Entries_reachable_by_engine :
  forall e : LexiconEntry,
    In e all176Entries ->
    exists s : PredictiveEngineState,
      cas_point (ams_core (ts_matrix (runCartograffectPipeline s))) = le_point e.
Proof.
  exact all176Entries_deterministically_reachable.
Qed.

Theorem all176Entries_witness_check :
  forallb (fun e => CoreAffectPoint_eqb (projectToCoreAffect (witnessEngineForPoint (le_point e))) (le_point e))
    all176Entries = true.
Proof.
  vm_compute. reflexivity.
Qed.
