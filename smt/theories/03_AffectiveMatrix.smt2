; =============================================================================
; Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
; SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
; Author: Manuel Cabelguen
;
; Module 03 : AffectiveMatrix (SMT-LIB 2.6 / Z3)
; Equivalence formelle directe avec Cartograffect/AffectiveMatrix.lean
; =============================================================================
(set-logic ALL)
(set-option :produce-models true)

; -----------------------------------------------------------------------------
; 1. Types fondamentaux
; -----------------------------------------------------------------------------
(declare-datatypes ((Polarity 0)) (
  ((Pol_neg) (Pol_zero) (Pol_pos))
))

(declare-datatypes ((EngineCoupling 0)) (
  ((mkEngineCoupling (ec_attente Polarity) (ec_controle Polarity)))
))

(declare-datatypes ((CoreAffectPoint 0)) (
  ((mkPoint (pt_x Int) (pt_y Int) (pt_z Int)))
))

(declare-datatypes ((ResourceRegime 0)) (
  ((RR_competitive) (RR_cooperative))
))

(declare-datatypes ((LivedExpectationPole 0)) (
  ((LEP_epistemicCharge) (LEP_epistemicNeutral) (LEP_epistemicDischarge))
))

(declare-datatypes ((LivedControlPole 0)) (
  ((LCP_pragmaticCharge) (LCP_pragmaticNeutral) (LCP_pragmaticDischarge))
))

(declare-datatypes ((EnergyRegime 0)) (
  ((ER_neutralBasal) (ER_axialPure) (ER_positiveSynergy)
   (ER_negativeSynergy) (ER_ergotropicCompensation) (ER_trophotropicRelease))
))

(declare-datatypes ((HedonicPolarity 0)) (
  ((Hed_positive) (Hed_negative) (Hed_neutral))
))

(declare-datatypes ((PhenomenologicalActivation 0)) (
  ((PA_basalWakefulness) (PA_ascendingRupture) (PA_operatorSuspension)
   (PA_lowInhibition) (PA_epistemicVigilance) (PA_highMobilization))
))

(declare-datatypes ((AffectiveMatrixState 0)) (
  ((mkAffectiveMatrixState
    (ams_core CoreAffectPoint)
    (ams_expectationPole LivedExpectationPole)
    (ams_controlPole LivedControlPole)
    (ams_energyRegime EnergyRegime)
    (ams_valence HedonicPolarity)
    (ams_activation PhenomenologicalActivation)
    (ams_antagonist CoreAffectPoint)))
))

; Deux mappings phenomenologiques arbitraires (fonctions non interpretees — R3)
(declare-fun m1_expectationFn (Int) LivedExpectationPole)
(declare-fun m1_controlFn (Int) LivedControlPole)
(declare-fun m1_valenceFn (Int Int) HedonicPolarity)
(declare-fun m1_activationFn (CoreAffectPoint) PhenomenologicalActivation)

(declare-fun m2_expectationFn (Int) LivedExpectationPole)
(declare-fun m2_controlFn (Int) LivedControlPole)
(declare-fun m2_valenceFn (Int Int) HedonicPolarity)
(declare-fun m2_activationFn (CoreAffectPoint) PhenomenologicalActivation)

; -----------------------------------------------------------------------------
; 2. Fonctions fondamentales
; -----------------------------------------------------------------------------
(define-fun Polarity_invert ((p Polarity)) Polarity
  (ite (= p Pol_neg) Pol_pos
  (ite (= p Pol_zero) Pol_zero Pol_neg)))

(define-fun intAbs ((v Int)) Int (ite (>= v 0) v (- v)))

(define-fun intSign ((v Int)) Int
  (ite (> v 0) 1 (ite (< v 0) (- 1) 0)))

(define-fun CoreAffectPoint_displacementSum ((p CoreAffectPoint)) Int
  (+ (intAbs (pt_x p)) (intAbs (pt_y p))))

(define-fun crownRadius ((z Int)) Int
  (ite (< z 2) 0 (- (* 2 z) 2)))

(define-fun CoreAffectPoint_isCentral ((p CoreAffectPoint)) Bool
  (and (= (pt_x p) 0) (= (pt_y p) 0)))

(define-fun CoreAffectPoint_isOnCrown ((p CoreAffectPoint)) Bool
  (and (>= (pt_z p) 2)
       (= (CoreAffectPoint_displacementSum p) (crownRadius (pt_z p)))))

(define-fun isValidCoreAffect ((p CoreAffectPoint)) Bool
  (and (>= (pt_z p) 0)
       (or (CoreAffectPoint_isCentral p)
           (CoreAffectPoint_isOnCrown p))))

(define-fun isValidCoreAffectIn ((r ResourceRegime) (p CoreAffectPoint)) Bool
  (ite (= r RR_competitive)
    (isValidCoreAffect p)
    (and (>= (pt_z p) 0)
         (or (CoreAffectPoint_isCentral p)
             (and (>= (pt_z p) 2)
                  (<= (crownRadius (pt_z p)) (CoreAffectPoint_displacementSum p)))))))

(define-fun signedAmplitude ((pol Polarity) (amp Int)) Int
  (ite (= pol Pol_neg) (- amp)
  (ite (= pol Pol_zero) 0 amp)))

(define-fun clampInt ((lo Int) (hi Int) (v Int)) Int
  (ite (< v lo) lo (ite (< hi v) hi v)))

(define-fun deployCouplingAtDepth ((c EngineCoupling) (d Int)) CoreAffectPoint
  (let ((z (+ d 2)) (r (+ (* 2 d) 2)) (k (+ d 1))
        (a (ec_attente c)) (ctrl (ec_controle c)))
    (ite (and (= a Pol_zero) (= ctrl Pol_zero)) (mkPoint 0 0 0)
    (ite (= ctrl Pol_zero) (mkPoint (signedAmplitude a r) 0 z)
    (ite (= a Pol_zero) (mkPoint 0 (signedAmplitude ctrl r) z)
    (mkPoint (signedAmplitude a k) (signedAmplitude ctrl k) z))))))

(define-fun apportionRayX ((d Int) (piA Int) (piC Int)) Int
  (let ((r (+ (* 2 d) 2)))
    (ite (= piA piC)
      (+ d 1)
      (let ((tot (+ piA piC)))
        (ite (< piA piC)
          (clampInt 1 (+ d 1) (div (+ (* 2 r piA) tot) (* 2 tot)))
          (- r (clampInt 1 (+ d 1) (div (+ (* 2 r piC) tot) (* 2 tot)))))))))

(define-fun apportionRayY ((d Int) (piA Int) (piC Int)) Int
  (- (+ (* 2 d) 2) (apportionRayX d piA piC)))

(define-fun deployCouplingWithPrecision ((c EngineCoupling) (d Int) (piA Int) (piC Int)) CoreAffectPoint
  (let ((z (+ d 2)) (r (+ (* 2 d) 2))
        (a (ec_attente c)) (ctrl (ec_controle c)))
    (ite (and (= a Pol_zero) (= ctrl Pol_zero)) (mkPoint 0 0 0)
    (ite (= ctrl Pol_zero) (mkPoint (signedAmplitude a r) 0 z)
    (ite (= a Pol_zero) (mkPoint 0 (signedAmplitude ctrl r) z)
    (mkPoint (signedAmplitude a (apportionRayX d piA piC))
             (signedAmplitude ctrl (apportionRayY d piA piC))
             z))))))

(define-fun computeEnergyRegime ((x Int) (y Int)) EnergyRegime
  (ite (and (= x 0) (= y 0)) ER_neutralBasal
  (ite (or (= x 0) (= y 0)) ER_axialPure
  (ite (and (> x 0) (> y 0)) ER_positiveSynergy
  (ite (and (< x 0) (< y 0)) ER_negativeSynergy
  (ite (and (< x 0) (> y 0)) ER_ergotropicCompensation
  ER_trophotropicRelease))))))

(define-fun HedonicPolarity_invert ((p HedonicPolarity)) HedonicPolarity
  (ite (= p Hed_positive) Hed_negative
  (ite (= p Hed_negative) Hed_positive
  Hed_neutral)))

(define-fun computeHedonicPolarity ((x Int) (y Int)) HedonicPolarity
  (ite (> x 0) Hed_positive
  (ite (< x 0) Hed_negative
  (ite (> y 0) Hed_positive
  (ite (< y 0) Hed_negative
  Hed_neutral)))))

(define-fun transduceExpectation ((x Int)) LivedExpectationPole
  (ite (< x 0) LEP_epistemicCharge
  (ite (> x 0) LEP_epistemicDischarge LEP_epistemicNeutral)))

(define-fun transduceControl ((y Int)) LivedControlPole
  (ite (< y 0) LCP_pragmaticCharge
  (ite (> y 0) LCP_pragmaticDischarge LCP_pragmaticNeutral)))

(define-fun computeActivation ((p CoreAffectPoint)) PhenomenologicalActivation
  (ite (and (= (pt_x p) 0) (= (pt_y p) 0))
    (ite (= (pt_z p) 0) PA_basalWakefulness
    (ite (= (pt_z p) 1) PA_ascendingRupture PA_operatorSuspension))
  (ite (> (pt_y p) 0) PA_highMobilization
  (ite (< (pt_y p) 0) PA_lowInhibition PA_epistemicVigilance))))

(define-fun antagonistPoint ((p CoreAffectPoint)) CoreAffectPoint
  (let ((x (pt_x p)) (y (pt_y p)) (z (pt_z p)))
    (ite (or (= x 0) (= y 0) (= (intAbs x) (intAbs y)))
      (mkPoint (- x) (- y) z)
      (ite (or (and (> x 0) (< y 0)) (and (< x 0) (> y 0)))
        (mkPoint y x z)
        (mkPoint (- y) (- x) z)))))

(define-fun transferUnitYtoX ((p CoreAffectPoint)) CoreAffectPoint
  (ite (and (>= (pt_x p) 0) (> (pt_y p) 0))
    (mkPoint (+ (pt_x p) 1) (- (pt_y p) 1) (pt_z p))
    p))

(define-fun evaluateMatrixM1 ((p CoreAffectPoint)) AffectiveMatrixState
  (mkAffectiveMatrixState
    p
    (m1_expectationFn (pt_x p))
    (m1_controlFn (pt_y p))
    (computeEnergyRegime (pt_x p) (pt_y p))
    (m1_valenceFn (pt_x p) (pt_y p))
    (m1_activationFn p)
    (antagonistPoint p)))

(define-fun evaluateMatrixM2 ((p CoreAffectPoint)) AffectiveMatrixState
  (mkAffectiveMatrixState
    p
    (m2_expectationFn (pt_x p))
    (m2_controlFn (pt_y p))
    (computeEnergyRegime (pt_x p) (pt_y p))
    (m2_valenceFn (pt_x p) (pt_y p))
    (m2_activationFn p)
    (antagonistPoint p)))

(define-fun evaluateMatrixCanonical ((p CoreAffectPoint)) AffectiveMatrixState
  (mkAffectiveMatrixState
    p
    (transduceExpectation (pt_x p))
    (transduceControl (pt_y p))
    (computeEnergyRegime (pt_x p) (pt_y p))
    (computeHedonicPolarity (pt_x p) (pt_y p))
    (computeActivation p)
    (antagonistPoint p)))

; -----------------------------------------------------------------------------
; Controle de non-vacuite (doit retourner sat)
; -----------------------------------------------------------------------------
(echo "[CONSISTENCY]")
(push)
(declare-const p_test CoreAffectPoint)
(assert (isValidCoreAffect p_test))
(check-sat)
(pop)

; -----------------------------------------------------------------------------
; 3. Audit des 13 theoremes de AffectiveMatrix (chaque controle doit retourner unsat)
; -----------------------------------------------------------------------------

; [1/13] HedonicPolarity_invert_involutive
(echo "[THM] HedonicPolarity_invert_involutive")
(push)
(assert (not
  (forall ((p HedonicPolarity))
    (= (HedonicPolarity_invert (HedonicPolarity_invert p)) p))))
(check-sat)
(pop)

; [2/13] x_positive_determines_positive_valence
(echo "[THM] x_positive_determines_positive_valence")
(push)
(assert (not
  (forall ((x Int) (y Int))
    (=> (> x 0)
        (= (computeHedonicPolarity x y) Hed_positive)))))
(check-sat)
(pop)

; [3/13] x_negative_determines_negative_valence
(echo "[THM] x_negative_determines_negative_valence")
(push)
(assert (not
  (forall ((x Int) (y Int))
    (=> (< x 0)
        (= (computeHedonicPolarity x y) Hed_negative)))))
(check-sat)
(pop)

; [4/13] antagonistPoint_preserves_validity
(echo "[THM] antagonistPoint_preserves_validity")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (isValidCoreAffect p)
        (isValidCoreAffect (antagonistPoint p))))))
(check-sat)
(pop)

; [5/13] antagonistPoint_involutive
(echo "[THM] antagonistPoint_involutive")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (= (antagonistPoint (antagonistPoint p)) p))))
(check-sat)
(pop)

; [6/13] contralateral_swaps_amplitudes
(echo "[THM] contralateral_swaps_amplitudes")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (not (or (= (pt_x p) 0)
                 (= (pt_y p) 0)
                 (= (intAbs (pt_x p)) (intAbs (pt_y p)))))
        (and (= (intAbs (pt_x (antagonistPoint p))) (intAbs (pt_y p)))
             (= (intAbs (pt_y (antagonistPoint p))) (intAbs (pt_x p))))))))
(check-sat)
(pop)

; [7/13] antagonist_commutes_with_invert
(echo "[THM] antagonist_commutes_with_invert")
(push)
(assert (not
  (forall ((c EngineCoupling) (d Int))
    (=> (>= d 0)
        (= (antagonistPoint (deployCouplingAtDepth c d))
           (deployCouplingAtDepth
             (mkEngineCoupling (Polarity_invert (ec_attente c))
                               (Polarity_invert (ec_controle c)))
             d))))))
(check-sat)
(pop)

; [8/13] antagonistPoint_unified
(echo "[THM] antagonistPoint_unified")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (and (not (= (pt_x p) 0)) (not (= (pt_y p) 0)))
        (= (antagonistPoint p)
           (mkPoint (* (- (intSign (pt_x p))) (intAbs (pt_y p)))
                    (* (- (intSign (pt_y p))) (intAbs (pt_x p)))
                    (pt_z p)))))))
(check-sat)
(pop)

; [9/13] antagonist_preserves_validity_in
(echo "[THM] antagonist_preserves_validity_in")
(push)
(assert (not
  (forall ((r ResourceRegime) (p CoreAffectPoint))
    (=> (isValidCoreAffectIn r p)
        (isValidCoreAffectIn r (antagonistPoint p))))))
(check-sat)
(pop)

; [10/13] transferUnitYtoX_preserves_sum
(echo "[THM] transferUnitYtoX_preserves_sum")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (= (CoreAffectPoint_displacementSum (transferUnitYtoX p))
       (CoreAffectPoint_displacementSum p)))))
(check-sat)
(pop)

; [11/13] antagonist_commutes_with_invert_precision
(echo "[THM] antagonist_commutes_with_invert_precision")
(push)
(assert (not
  (forall ((c EngineCoupling) (d Int) (piA Int) (piC Int))
    (=> (and (>= d 0) (>= piA 0) (>= piC 0))
        (= (antagonistPoint (deployCouplingWithPrecision c d piA piC))
           (deployCouplingWithPrecision
             (mkEngineCoupling (Polarity_invert (ec_attente c))
                               (Polarity_invert (ec_controle c)))
             d piC piA))))))
(check-sat)
(pop)

; [12/13] evaluateMatrix_core_antagonist_independent
(echo "[THM] evaluateMatrix_core_antagonist_independent")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (isValidCoreAffect p)
        (let ((r1 (evaluateMatrixM1 p)) (r2 (evaluateMatrixM2 p)))
          (and (= (ams_core r1) (ams_core r2))
               (= (ams_energyRegime r1) (ams_energyRegime r2))
               (= (ams_antagonist r1) (ams_antagonist r2))))))))
(check-sat)
(pop)

; [13/13] mapping_independent_antagonist_invariants
(echo "[THM] mapping_independent_antagonist_invariants")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (isValidCoreAffect p)
        (let ((r1 (evaluateMatrixM1 p)) (rc (evaluateMatrixCanonical p)))
          (and (isValidCoreAffect (ams_antagonist r1))
               (= (ams_antagonist (evaluateMatrixM1 (ams_antagonist r1))) p)
               (=> (and (not (= (pt_x p) 0)) (not (= (pt_y p) 0)))
                   (= (ams_antagonist r1)
                      (mkPoint (* (- (intSign (pt_x p))) (intAbs (pt_y p)))
                               (* (- (intSign (pt_y p))) (intAbs (pt_x p)))
                               (pt_z p))))
               (= (ams_antagonist r1) (ams_antagonist rc))))))))
(check-sat)
(pop)
