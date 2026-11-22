; =============================================================================
; Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
; SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
; Author: Manuel Cabelguen
;
; Module 09 : OperantFactorization (SMT-LIB 2.6 / Z3)
; Equivalence formelle directe avec Cartograffect/OperantFactorization.lean
; =============================================================================
(set-logic ALL)
(set-option :produce-models true)

; -----------------------------------------------------------------------------
; 1. Types fondamentaux (alignes sur 02_CoreAffect & 03_AffectiveMatrix)
; -----------------------------------------------------------------------------
(declare-datatypes ((CoreAffectPoint 0)) (
  ((mkPoint (pt_x Int) (pt_y Int) (pt_z Int)))
))

(declare-datatypes ((EnergyRegime 0)) (
  ((ER_neutralBasal) (ER_axialPure) (ER_positiveSynergy)
   (ER_negativeSynergy) (ER_ergotropicCompensation) (ER_trophotropicRelease))
))

(declare-datatypes ((HedonicPolarity 0)) (
  ((Hed_positive) (Hed_negative) (Hed_neutral))
))

(declare-datatypes ((PrimaryCrownPrototype 0)) (
  ((Proto_joie) (Proto_tristesse) (Proto_peur) (Proto_courage)
   (Proto_desir) (Proto_degout) (Proto_colere) (Proto_calme))
))

(declare-datatypes ((OperantEffect 0)) (
  ((OE_Reinforcement) (OE_Punishment))
))

(declare-datatypes ((OperantOperator 0)) (
  ((OO_Addition) (OO_Removal))
))

(declare-datatypes ((OperantContingency 0)) (
  ((mkOperantContingency (oc_effect OperantEffect) (oc_op OperantOperator)))
))

(declare-datatypes ((OptionContingency 0)) (
  ((OC_none) (OC_some (oc_val OperantContingency)))
))

; -----------------------------------------------------------------------------
; 2. Fonctions fondamentales et projection operante Z = 2
; -----------------------------------------------------------------------------
(define-fun intAbs ((v Int)) Int (ite (>= v 0) v (- v)))

(define-fun CoreAffectPoint_displacementSum ((p CoreAffectPoint)) Int
  (+ (intAbs (pt_x p)) (intAbs (pt_y p))))

(define-fun manhattanDistXY ((p CoreAffectPoint) (q CoreAffectPoint)) Int
  (+ (intAbs (- (pt_x p) (pt_x q))) (intAbs (- (pt_y p) (pt_y q)))))

(define-fun computeEnergyRegime ((x Int) (y Int)) EnergyRegime
  (ite (and (= x 0) (= y 0)) ER_neutralBasal
  (ite (or (= x 0) (= y 0)) ER_axialPure
  (ite (and (> x 0) (> y 0)) ER_positiveSynergy
  (ite (and (< x 0) (< y 0)) ER_negativeSynergy
  (ite (and (< x 0) (> y 0)) ER_ergotropicCompensation
  ER_trophotropicRelease))))))

(define-fun computeHedonicPolarity ((x Int) (y Int)) HedonicPolarity
  (ite (> x 0) Hed_positive
  (ite (< x 0) Hed_negative
  (ite (> y 0) Hed_positive
  (ite (< y 0) Hed_negative
  Hed_neutral)))))

(define-fun antagonistPoint ((p CoreAffectPoint)) CoreAffectPoint
  (let ((x (pt_x p)) (y (pt_y p)) (z (pt_z p)))
    (ite (or (= x 0) (= y 0) (= (intAbs x) (intAbs y)))
      (mkPoint (- x) (- y) z)
      (ite (or (and (> x 0) (< y 0)) (and (< x 0) (> y 0)))
        (mkPoint y x z)
        (mkPoint (- y) (- x) z)))))

(define-fun PrimaryCrownPrototype_toPoint ((proto PrimaryCrownPrototype)) CoreAffectPoint
  (ite (= proto Proto_joie)      (mkPoint 0 2 2)
  (ite (= proto Proto_tristesse) (mkPoint 0 (- 2) 2)
  (ite (= proto Proto_peur)      (mkPoint (- 2) 0 2)
  (ite (= proto Proto_courage)   (mkPoint 2 0 2)
  (ite (= proto Proto_desir)     (mkPoint 1 1 2)
  (ite (= proto Proto_degout)    (mkPoint (- 1) (- 1) 2)
  (ite (= proto Proto_colere)    (mkPoint (- 1) 1 2)
  (mkPoint 1 (- 1) 2)))))))))

(define-fun diagToContingency ((p CoreAffectPoint)) OptionContingency
  (let ((x (pt_x p)) (y (pt_y p)) (z (pt_z p)))
    (ite (not (= z 2)) OC_none
    (ite (and (= x 1) (= y 1))          (OC_some (mkOperantContingency OE_Reinforcement OO_Addition))
    (ite (and (= x 1) (= y (- 1)))     (OC_some (mkOperantContingency OE_Reinforcement OO_Removal))
    (ite (and (= x (- 1)) (= y (- 1))) (OC_some (mkOperantContingency OE_Punishment    OO_Addition))
    (ite (and (= x (- 1)) (= y 1))     (OC_some (mkOperantContingency OE_Punishment    OO_Removal))
    OC_none)))))))

(define-fun prototypeToContingency ((proto PrimaryCrownPrototype)) OptionContingency
  (diagToContingency (PrimaryCrownPrototype_toPoint proto)))

(define-fun isZ2DiagonalPoint ((p CoreAffectPoint)) Bool
  (or (= p (PrimaryCrownPrototype_toPoint Proto_desir))
      (= p (PrimaryCrownPrototype_toPoint Proto_calme))
      (= p (PrimaryCrownPrototype_toPoint Proto_degout))
      (= p (PrimaryCrownPrototype_toPoint Proto_colere))))

(define-fun isZ2AxialPoint ((p CoreAffectPoint)) Bool
  (or (= p (PrimaryCrownPrototype_toPoint Proto_courage))
      (= p (PrimaryCrownPrototype_toPoint Proto_peur))
      (= p (PrimaryCrownPrototype_toPoint Proto_joie))
      (= p (PrimaryCrownPrototype_toPoint Proto_tristesse))))

; -----------------------------------------------------------------------------
; Controle de non-vacuite (doit retourner sat)
; -----------------------------------------------------------------------------
(echo "[CONSISTENCY]")
(push)
(declare-const p_test CoreAffectPoint)
(assert (isZ2DiagonalPoint p_test))
(check-sat)
(pop)

; -----------------------------------------------------------------------------
; 3. Audit des 7 theoremes de OperantFactorization (chaque controle doit retourner unsat)
; -----------------------------------------------------------------------------

; [1/7] manhattanDistXY_origin
(echo "[THM] manhattanDistXY_origin")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (= (manhattanDistXY p (mkPoint 0 0 (pt_z p)))
       (CoreAffectPoint_displacementSum p)))))
(check-sat)
(pop)

; [2/7] operant_factorization_law
(echo "[THM] operant_factorization_law")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (isZ2DiagonalPoint p)
        (let ((res (diagToContingency p)))
          (and
            (not (= res OC_none))
            (let ((c (oc_val res)))
              (and
                (= (= (oc_effect c) OE_Reinforcement) (= (pt_x p) 1))
                (= (= (oc_effect c) OE_Punishment) (= (pt_x p) (- 1)))
                (= (= (oc_op c) OO_Addition) (= (* (pt_x p) (pt_y p)) 1))
                (= (= (oc_op c) OO_Removal) (= (* (pt_x p) (pt_y p)) (- 1)))
                (= (or (= c (mkOperantContingency OE_Reinforcement OO_Addition))
                       (= c (mkOperantContingency OE_Punishment OO_Removal)))
                   (= (pt_y p) 1))
                (= (= (computeHedonicPolarity (pt_x p) (pt_y p)) Hed_positive)
                   (= (oc_effect c) OE_Reinforcement))))))))))
(check-sat)
(pop)

; [3/7] energyRegime_matches_operant_operator
(echo "[THM] energyRegime_matches_operant_operator")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (isZ2DiagonalPoint p)
        (let ((res (diagToContingency p)))
          (and
            (not (= res OC_none))
            (let ((c (oc_val res)))
              (and
                (= (= (oc_op c) OO_Addition)
                   (or (= (computeEnergyRegime (pt_x p) (pt_y p)) ER_positiveSynergy)
                       (= (computeEnergyRegime (pt_x p) (pt_y p)) ER_negativeSynergy)))
                (= (= (oc_op c) OO_Removal)
                   (or (= (computeEnergyRegime (pt_x p) (pt_y p)) ER_ergotropicCompensation)
                       (= (computeEnergyRegime (pt_x p) (pt_y p)) ER_trophotropicRelease)))))))))))
(check-sat)
(pop)

; [4/7] antagonist_flips_effect_preserves_operator
(echo "[THM] antagonist_flips_effect_preserves_operator")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (isZ2DiagonalPoint p)
        (let ((r1 (diagToContingency p))
              (r2 (diagToContingency (antagonistPoint p))))
          (and
            (not (= r1 OC_none))
            (not (= r2 OC_none))
            (not (= (oc_effect (oc_val r1)) (oc_effect (oc_val r2))))
            (= (oc_op (oc_val r1)) (oc_op (oc_val r2)))))))))
(check-sat)
(pop)

; [5/7] axial_poles_bridge_operant_pairs
(echo "[THM] axial_poles_bridge_operant_pairs")
(push)
(assert (not
  (and
    (= (manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_courage) (PrimaryCrownPrototype_toPoint Proto_desir)) 2)
    (= (manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_courage) (PrimaryCrownPrototype_toPoint Proto_calme)) 2)
    (= (manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_courage) (PrimaryCrownPrototype_toPoint Proto_colere)) 4)
    (= (manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_courage) (PrimaryCrownPrototype_toPoint Proto_degout)) 4)
    (= (manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_peur) (PrimaryCrownPrototype_toPoint Proto_colere)) 2)
    (= (manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_peur) (PrimaryCrownPrototype_toPoint Proto_degout)) 2)
    (= (manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_peur) (PrimaryCrownPrototype_toPoint Proto_desir)) 4)
    (= (manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_peur) (PrimaryCrownPrototype_toPoint Proto_calme)) 4)
    (= (manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_joie) (PrimaryCrownPrototype_toPoint Proto_desir)) 2)
    (= (manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_joie) (PrimaryCrownPrototype_toPoint Proto_colere)) 2)
    (= (manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_joie) (PrimaryCrownPrototype_toPoint Proto_calme)) 4)
    (= (manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_joie) (PrimaryCrownPrototype_toPoint Proto_degout)) 4)
    (= (manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_tristesse) (PrimaryCrownPrototype_toPoint Proto_calme)) 2)
    (= (manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_tristesse) (PrimaryCrownPrototype_toPoint Proto_degout)) 2)
    (= (manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_tristesse) (PrimaryCrownPrototype_toPoint Proto_desir)) 4)
    (= (manhattanDistXY (PrimaryCrownPrototype_toPoint Proto_tristesse) (PrimaryCrownPrototype_toPoint Proto_colere)) 4))))
(check-sat)
(pop)

; [6/7] axial_poles_pre_operant
(echo "[THM] axial_poles_pre_operant")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (isZ2AxialPoint p)
        (= (diagToContingency p) OC_none)))))
(check-sat)
(pop)

; [7/7] operant_bijection_on_z2_diagonals
(echo "[THM] operant_bijection_on_z2_diagonals")
(push)
(assert (not
  (and
    (forall ((c OperantContingency))
      (exists ((p CoreAffectPoint))
        (and (isZ2DiagonalPoint p)
             (= (diagToContingency p) (OC_some c)))))
    (forall ((p1 CoreAffectPoint) (p2 CoreAffectPoint))
      (=> (and (isZ2DiagonalPoint p1)
               (isZ2DiagonalPoint p2)
               (= (diagToContingency p1) (diagToContingency p2)))
          (= p1 p2))))))
(check-sat)
(pop)
