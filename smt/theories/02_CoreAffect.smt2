; =============================================================================
; Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
; SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
; Author: Manuel Cabelguen
;
; Module 02 : CoreAffect (SMT-LIB 2.6 / Z3)
; Equivalence formelle directe avec Cartograffect/CoreAffect.lean
; =============================================================================
(set-logic ALL)
(set-option :produce-models true)

; -----------------------------------------------------------------------------
; 1. Types importes de PredictiveEngine & types propres a CoreAffect
; -----------------------------------------------------------------------------
(declare-datatypes ((Polarity 0)) (
  ((Pol_neg) (Pol_zero) (Pol_pos))
))

(declare-datatypes ((SalientDiscrepancy 0)) (
  ((mkSalientDiscrepancy
    (sd_magnitude Int)
    (sd_sensoryThreshold Int)
    (sd_resorptionThreshold Int)))
))

(declare-datatypes ((PerceptiveInterface 0)) (
  ((mkPerceptiveInterface (pi_controleGradient Polarity)))
))

(declare-datatypes ((SubjectiveInterface 0)) (
  ((mkSubjectiveInterface
    (si_attenteGradient Polarity)
    (si_descendingSuspension Bool)))
))

(declare-datatypes ((AttentionalInterface 0)) (
  ((mkAttentionalInterface
    (ai_allocatedPrecision Int)
    (ai_engagementThreshold Int)
    (ai_persistenceDepth Int)
    (ai_precisionA Int)
    (ai_precisionC Int)))
))

(declare-datatypes ((EngineCoupling 0)) (
  ((mkEngineCoupling (ec_attente Polarity) (ec_controle Polarity)))
))

(declare-datatypes ((PredictiveEngineState 0)) (
  ((mkPredictiveEngineState
    (pes_discrepancy SalientDiscrepancy)
    (pes_perceptive PerceptiveInterface)
    (pes_subjective SubjectiveInterface)
    (pes_attentional AttentionalInterface)))
))

(declare-datatypes ((CoreAffectPoint 0)) (
  ((mkPoint (pt_x Int) (pt_y Int) (pt_z Int)))
))

(declare-datatypes ((GeometryType 0)) (
  ((GT_central) (GT_axial) (GT_diagonal) (GT_lateral))
))

(declare-datatypes ((ResourceRegime 0)) (
  ((RR_competitive) (RR_cooperative))
))

(define-fun validSalientDiscrepancy ((d SalientDiscrepancy)) Bool
  (and (>= (sd_magnitude d) 0)
       (>= (sd_sensoryThreshold d) 0)
       (>= (sd_resorptionThreshold d) 0)
       (<= (sd_resorptionThreshold d) (sd_sensoryThreshold d))))

(define-fun validAttentional ((a AttentionalInterface)) Bool
  (and (>= (ai_allocatedPrecision a) 0)
       (>= (ai_engagementThreshold a) 0)
       (>= (ai_persistenceDepth a) 0)
       (>= (ai_precisionA a) 0)
       (>= (ai_precisionC a) 0)))

(define-fun validEngineState ((s PredictiveEngineState)) Bool
  (and (validSalientDiscrepancy (pes_discrepancy s))
       (validAttentional (pes_attentional s))))

(define-fun validPointNatZ ((p CoreAffectPoint)) Bool
  (>= (pt_z p) 0))

; -----------------------------------------------------------------------------
; 2. Fonctions auxiliaires de PredictiveEngine et CoreAffect
; -----------------------------------------------------------------------------
(define-fun Polarity_isEngaged ((p Polarity)) Bool (not (= p Pol_zero)))

(define-fun EngineCoupling_isGlobalNeutrality ((c EngineCoupling)) Bool
  (and (not (Polarity_isEngaged (ec_attente c)))
       (not (Polarity_isEngaged (ec_controle c)))))

(define-fun EngineCoupling_isSingleEngaged ((c EngineCoupling)) Bool
  (or (and (Polarity_isEngaged (ec_attente c))
           (not (Polarity_isEngaged (ec_controle c))))
      (and (not (Polarity_isEngaged (ec_attente c)))
           (Polarity_isEngaged (ec_controle c)))))

(define-fun EngineCoupling_isDualEngaged ((c EngineCoupling)) Bool
  (and (Polarity_isEngaged (ec_attente c))
       (Polarity_isEngaged (ec_controle c))))

(define-fun SalientDiscrepancy_isSensorilySalient ((d SalientDiscrepancy)) Bool
  (<= (sd_sensoryThreshold d) (sd_magnitude d)))

(define-fun SalientDiscrepancy_isInRemanenceWindow ((d SalientDiscrepancy)) Bool
  (and (<= (sd_resorptionThreshold d) (sd_magnitude d))
       (< (sd_magnitude d) (sd_sensoryThreshold d))))

(define-fun AttentionalInterface_isEngaged ((att AttentionalInterface)) Bool
  (<= (ai_engagementThreshold att) (ai_allocatedPrecision att)))

(define-fun PredictiveEngineState_currentCoupling ((s PredictiveEngineState)) EngineCoupling
  (mkEngineCoupling
    (si_attenteGradient (pes_subjective s))
    (pi_controleGradient (pes_perceptive s))))

(define-fun engineStep ((s PredictiveEngineState)) PredictiveEngineState
  (let ((c (PredictiveEngineState_currentCoupling s)))
    (ite (not (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s)))
      (ite (SalientDiscrepancy_isInRemanenceWindow (pes_discrepancy s))
        s
        (mkPredictiveEngineState
          (pes_discrepancy s)
          (mkPerceptiveInterface Pol_zero)
          (mkSubjectiveInterface Pol_zero false)
          (mkAttentionalInterface
            0
            (ai_engagementThreshold (pes_attentional s))
            0
            (ai_precisionA (pes_attentional s))
            (ai_precisionC (pes_attentional s)))))
      (ite (EngineCoupling_isGlobalNeutrality c)
        (mkPredictiveEngineState
          (pes_discrepancy s)
          (mkPerceptiveInterface Pol_pos)
          (pes_subjective s)
          (pes_attentional s))
        (ite (and (not (si_descendingSuspension (pes_subjective s)))
                  (not (AttentionalInterface_isEngaged (pes_attentional s))))
          (mkPredictiveEngineState
            (pes_discrepancy s)
            (pes_perceptive s)
            (mkSubjectiveInterface (si_attenteGradient (pes_subjective s)) true)
            (pes_attentional s))
          (ite (not (AttentionalInterface_isEngaged (pes_attentional s)))
            (mkPredictiveEngineState
              (pes_discrepancy s)
              (pes_perceptive s)
              (pes_subjective s)
              (mkAttentionalInterface
                (ai_engagementThreshold (pes_attentional s))
                (ai_engagementThreshold (pes_attentional s))
                (ai_persistenceDepth (pes_attentional s))
                (ai_precisionA (pes_attentional s))
                (ai_precisionC (pes_attentional s))))
            s))))))

(define-fun intAbs ((v Int)) Int (ite (>= v 0) v (- v)))

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
  (and (validPointNatZ p)
       (or (CoreAffectPoint_isCentral p)
           (CoreAffectPoint_isOnCrown p))))

(define-fun isValidCoreAffectIn ((r ResourceRegime) (p CoreAffectPoint)) Bool
  (ite (= r RR_competitive)
    (isValidCoreAffect p)
    (and (validPointNatZ p)
         (or (CoreAffectPoint_isCentral p)
             (and (>= (pt_z p) 2)
                  (<= (crownRadius (pt_z p)) (CoreAffectPoint_displacementSum p)))))))

(define-fun CoreAffectPoint_classifyGeometry ((p CoreAffectPoint)) GeometryType
  (ite (and (= (pt_x p) 0) (= (pt_y p) 0)) GT_central
  (ite (or (= (pt_x p) 0) (= (pt_y p) 0)) GT_axial
  (ite (= (intAbs (pt_x p)) (intAbs (pt_y p))) GT_diagonal
  GT_lateral))))

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

(define-fun projectToCoreAffect ((s PredictiveEngineState)) CoreAffectPoint
  (let ((c (PredictiveEngineState_currentCoupling s)))
    (ite (or (not (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s)))
             (EngineCoupling_isGlobalNeutrality c))
      (ite (si_descendingSuspension (pes_subjective s))
        (mkPoint 0 0 (+ (ai_persistenceDepth (pes_attentional s)) 2))
        (mkPoint 0 0 0))
      (ite (not (AttentionalInterface_isEngaged (pes_attentional s)))
        (ite (si_descendingSuspension (pes_subjective s))
          (mkPoint 0 0 (+ (ai_persistenceDepth (pes_attentional s)) 2))
          (mkPoint 0 0 1))
        (deployCouplingWithPrecision
          c
          (ai_persistenceDepth (pes_attentional s))
          (ai_precisionA (pes_attentional s))
          (ai_precisionC (pes_attentional s)))))))

(define-fun triggerSecondaryGradient ((c EngineCoupling) (newPol Polarity)) EngineCoupling
  (let ((a (ec_attente c)) (ctrl (ec_controle c)))
    (ite (and (Polarity_isEngaged a) (= ctrl Pol_zero)) (mkEngineCoupling a newPol)
    (ite (and (= a Pol_zero) (Polarity_isEngaged ctrl)) (mkEngineCoupling newPol ctrl)
    c))))

(define-fun polarityOfInt ((v Int)) Polarity
  (ite (> v 0) Pol_pos (ite (< v 0) Pol_neg Pol_zero)))

(define-fun witnessEngineForPoint ((p CoreAffectPoint)) PredictiveEngineState
  (let ((ax (intAbs (pt_x p))) (ay (intAbs (pt_y p))))
    (ite (and (= (pt_x p) 0) (= (pt_y p) 0))
      (ite (= (pt_z p) 0)
        (mkPredictiveEngineState
          (mkSalientDiscrepancy 0 1 1)
          (mkPerceptiveInterface Pol_zero)
          (mkSubjectiveInterface Pol_zero false)
          (mkAttentionalInterface 0 0 0 1 1))
        (ite (= (pt_z p) 1)
          (mkPredictiveEngineState
            (mkSalientDiscrepancy 2 1 1)
            (mkPerceptiveInterface Pol_zero)
            (mkSubjectiveInterface Pol_pos false)
            (mkAttentionalInterface 0 1 0 1 1))
          (mkPredictiveEngineState
            (mkSalientDiscrepancy 2 1 1)
            (mkPerceptiveInterface Pol_zero)
            (mkSubjectiveInterface Pol_pos true)
            (mkAttentionalInterface 0 1 (- (pt_z p) 2) 1 1))))
      (let ((useSym (or (= ax 0) (= ay 0))))
        (mkPredictiveEngineState
          (mkSalientDiscrepancy 2 1 1)
          (mkPerceptiveInterface (polarityOfInt (pt_y p)))
          (mkSubjectiveInterface (polarityOfInt (pt_x p)) true)
          (mkAttentionalInterface
            1 1 (- (pt_z p) 2)
            (ite useSym 1 ax)
            (ite useSym 1 ay)))))))

(define-fun dissipationStep ((p CoreAffectPoint)) CoreAffectPoint
  (ite (or (not (= (pt_x p) 0)) (not (= (pt_y p) 0)))
    (mkPoint 0 0 (pt_z p))
    (ite (<= (pt_z p) 2)
      (mkPoint 0 0 0)
      (mkPoint 0 0 (- (pt_z p) 1)))))

(define-fun dissipationPotential ((p CoreAffectPoint)) Int
  (+ (* 2 (pt_z p))
     (ite (or (not (= (pt_x p) 0)) (not (= (pt_y p) 0))) 1 0)))

(define-fun allostaticStep ((d SalientDiscrepancy) (p CoreAffectPoint)) CoreAffectPoint
  (ite (< (sd_magnitude d) (sd_resorptionThreshold d))
    (dissipationStep p)
    p))

(define-fun-rec repeatDissipation ((n Int) (p CoreAffectPoint)) CoreAffectPoint
  (ite (<= n 0) p (repeatDissipation (- n 1) (dissipationStep p))))

; -----------------------------------------------------------------------------
; Controle de non-vacuite (doit retourner sat)
; -----------------------------------------------------------------------------
(echo "[CONSISTENCY]")
(push)
(declare-const s_test PredictiveEngineState)
(declare-const p_test CoreAffectPoint)
(assert (validEngineState s_test))
(assert (isValidCoreAffect p_test))
(check-sat)
(pop)

; -----------------------------------------------------------------------------
; 3. Audit des 23 theoremes de CoreAffect (chaque controle doit retourner unsat)
; -----------------------------------------------------------------------------

; [1/23] engine_induces_valid_core_affect
(echo "[THM] engine_induces_valid_core_affect")
(push)
(assert (not
  (forall ((s PredictiveEngineState))
    (=> (validEngineState s)
        (isValidCoreAffect (projectToCoreAffect s))))))
(check-sat)
(pop)

; [2/23] z2_budget_conservation
(echo "[THM] z2_budget_conservation")
(push)
(assert (not
  (forall ((c EngineCoupling))
    (=> (not (EngineCoupling_isGlobalNeutrality c))
        (= (CoreAffectPoint_displacementSum (deployCouplingAtDepth c 0)) 2)))))
(check-sat)
(pop)

; [3/23] axial_to_diagonal_reallocation
(echo "[THM] axial_to_diagonal_reallocation")
(push)
(assert (not
  (forall ((c EngineCoupling) (newPol Polarity))
    (=> (and (EngineCoupling_isSingleEngaged c)
             (Polarity_isEngaged newPol))
        (let ((c1 (triggerSecondaryGradient c newPol)))
          (and (= (CoreAffectPoint_classifyGeometry (deployCouplingAtDepth c1 0)) GT_diagonal)
               (= (CoreAffectPoint_displacementSum (deployCouplingAtDepth c1 0)) 2)))))))
(check-sat)
(pop)

; [4/23] dissipationStep_valid
(echo "[THM] dissipationStep_valid")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (validPointNatZ p)
        (isValidCoreAffect (dissipationStep p))))))
(check-sat)
(pop)

; [5/23] dissipationStep_fixed_iff
(echo "[THM] dissipationStep_fixed_iff")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (validPointNatZ p)
        (= (= (dissipationStep p) p)
           (= p (mkPoint 0 0 0)))))))
(check-sat)
(pop)

; [6/23] dissipation_strictly_decreases
(echo "[THM] dissipation_strictly_decreases")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (and (validPointNatZ p) (not (= p (mkPoint 0 0 0))))
        (< (dissipationPotential (dissipationStep p))
           (dissipationPotential p))))))
(check-sat)
(pop)

; [7/23] remanence_preserves_state
(echo "[THM] remanence_preserves_state")
(push)
(assert (not
  (forall ((d SalientDiscrepancy) (p CoreAffectPoint))
    (=> (and (validSalientDiscrepancy d)
             (SalientDiscrepancy_isInRemanenceWindow d))
        (= (allostaticStep d p) p)))))
(check-sat)
(pop)

; [8/23] cooperative_step_leaves_crown
(echo "[THM] cooperative_step_leaves_crown")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (and (validPointNatZ p)
             (CoreAffectPoint_isOnCrown p)
             (>= (pt_x p) 0)
             (>= (pt_y p) 0))
        (not (CoreAffectPoint_isOnCrown
               (mkPoint (+ (pt_x p) 1) (+ (pt_y p) 1) (pt_z p))))))))
(check-sat)
(pop)

; [9/23] deployCouplingWithPrecision_valid
(echo "[THM] deployCouplingWithPrecision_valid")
(push)
(assert (not
  (forall ((c EngineCoupling) (d Int) (piA Int) (piC Int))
    (=> (and (>= d 0) (>= piA 0) (>= piC 0))
        (isValidCoreAffect (deployCouplingWithPrecision c d piA piC))))))
(check-sat)
(pop)

; [10/23] neutral_coupling_without_suspension_yields_veille
(echo "[THM] neutral_coupling_without_suspension_yields_veille")
(push)
(assert (not
  (forall ((s PredictiveEngineState))
    (=> (and (validEngineState s)
             (EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s))
             (= (si_descendingSuspension (pes_subjective s)) false))
        (= (projectToCoreAffect s) (mkPoint 0 0 0))))))
(check-sat)
(pop)

; [11/23] neutral_or_subthreshold_with_suspension_yields_central
(echo "[THM] neutral_or_subthreshold_with_suspension_yields_central")
(push)
(assert (not
  (forall ((s PredictiveEngineState))
    (=> (and (validEngineState s)
             (or (not (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s)))
                 (EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s)))
             (= (si_descendingSuspension (pes_subjective s)) true))
        (= (projectToCoreAffect s)
           (mkPoint 0 0 (+ (ai_persistenceDepth (pes_attentional s)) 2)))))))
(check-sat)
(pop)

; [12/23] descending_suspension_yields_central_operator
(echo "[THM] descending_suspension_yields_central_operator")
(push)
(assert (not
  (forall ((s PredictiveEngineState))
    (=> (and (validEngineState s)
             (= (si_descendingSuspension (pes_subjective s)) true)
             (or (not (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s)))
                 (EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s))
                 (not (AttentionalInterface_isEngaged (pes_attentional s)))))
        (= (projectToCoreAffect s)
           (mkPoint 0 0 (+ (ai_persistenceDepth (pes_attentional s)) 2)))))))
(check-sat)
(pop)

; [13/23] central_z_ge2_requires_descending_suspension
(echo "[THM] central_z_ge2_requires_descending_suspension")
(push)
(assert (not
  (forall ((s PredictiveEngineState) (d Int))
    (=> (and (validEngineState s)
             (>= d 0)
             (= (projectToCoreAffect s) (mkPoint 0 0 (+ d 2))))
        (and (= (si_descendingSuspension (pes_subjective s)) true)
             (= (ai_persistenceDepth (pes_attentional s)) d)
             (or (not (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s)))
                 (EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s))
                 (not (AttentionalInterface_isEngaged (pes_attentional s)))))))))
(check-sat)
(pop)

; [14/23] deployCouplingWithPrecision_budget_conservation
(echo "[THM] deployCouplingWithPrecision_budget_conservation")
(push)
(assert (not
  (forall ((c EngineCoupling) (d Int) (piA Int) (piC Int))
    (=> (and (>= d 0) (>= piA 0) (>= piC 0)
             (not (EngineCoupling_isGlobalNeutrality c)))
        (= (CoreAffectPoint_displacementSum (deployCouplingWithPrecision c d piA piC))
           (+ (* 2 d) 2))))))
(check-sat)
(pop)

; [15/23] dual_engaged_yields_diagonal_z2_precision
(echo "[THM] dual_engaged_yields_diagonal_z2_precision")
(push)
(assert (not
  (forall ((c EngineCoupling) (piA Int) (piC Int))
    (=> (and (>= piA 0) (>= piC 0)
             (EngineCoupling_isDualEngaged c))
        (= (CoreAffectPoint_classifyGeometry (deployCouplingWithPrecision c 0 piA piC))
           GT_diagonal)))))
(check-sat)
(pop)

; [16/23] symmetric_precision_never_lateral
(echo "[THM] symmetric_precision_never_lateral")
(push)
(assert (not
  (forall ((s PredictiveEngineState))
    (=> (and (validEngineState s)
             (= (ai_precisionA (pes_attentional s))
                (ai_precisionC (pes_attentional s))))
        (not (= (CoreAffectPoint_classifyGeometry (projectToCoreAffect s)) GT_lateral))))))
(check-sat)
(pop)

; [17/23] projectToCoreAffect_surjective
(echo "[THM] projectToCoreAffect_surjective")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (isValidCoreAffect p)
        (= (projectToCoreAffect (witnessEngineForPoint p)) p)))))
(check-sat)
(pop)

; [18/23] engineStep_canonical_trajectory
(echo "[THM] engineStep_canonical_trajectory")
(push)
(assert (not
  (forall ((s0 PredictiveEngineState))
    (=> (and (validEngineState s0)
             (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s0))
             (EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s0))
             (= (si_descendingSuspension (pes_subjective s0)) false)
             (= (AttentionalInterface_isEngaged (pes_attentional s0)) false)
             (= (ai_persistenceDepth (pes_attentional s0)) 0))
        (and (= (projectToCoreAffect s0) (mkPoint 0 0 0))
             (= (projectToCoreAffect (engineStep s0)) (mkPoint 0 0 1))
             (= (projectToCoreAffect (engineStep (engineStep s0))) (mkPoint 0 0 2))
             (= (projectToCoreAffect (engineStep (engineStep (engineStep s0)))) (mkPoint 0 2 2)))))))
(check-sat)
(pop)

; [19/23] engineStep_surprise_to_crown
(echo "[THM] engineStep_surprise_to_crown")
(push)
(assert (not
  (forall ((s1 PredictiveEngineState))
    (=> (and (validEngineState s1)
             (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s1))
             (not (EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s1)))
             (= (si_descendingSuspension (pes_subjective s1)) false)
             (= (AttentionalInterface_isEngaged (pes_attentional s1)) false)
             (= (ai_persistenceDepth (pes_attentional s1)) 0))
        (let ((p_crown (projectToCoreAffect (engineStep (engineStep s1)))))
          (and (= (projectToCoreAffect s1) (mkPoint 0 0 1))
               (= (projectToCoreAffect (engineStep s1)) (mkPoint 0 0 2))
               (= p_crown
                  (deployCouplingWithPrecision
                    (PredictiveEngineState_currentCoupling s1)
                    0
                    (ai_precisionA (pes_attentional s1))
                    (ai_precisionC (pes_attentional s1))))
               (= (pt_z p_crown) 2)
               (CoreAffectPoint_isOnCrown p_crown)))))))
(check-sat)
(pop)

; [20/23] anticipation_short_circuits_to_veille
(echo "[THM] anticipation_short_circuits_to_veille")
(push)
(assert (not
  (= (dissipationStep (mkPoint 0 0 2)) (mkPoint 0 0 0))))
(check-sat)
(pop)

; [21/23] dissipation_from_ge2_never_visits_surprise
(echo "[THM] dissipation_from_ge2_never_visits_surprise")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (and (validPointNatZ p) (>= (pt_z p) 2))
        (not (= (dissipationStep p) (mkPoint 0 0 1)))))))
(check-sat)
(pop)

; [22/23] dissipationPotential_short_circuit_jump
(echo "[THM] dissipationPotential_short_circuit_jump")
(push)
(assert (not
  (= (- (dissipationPotential (mkPoint 0 0 2))
        (dissipationPotential (dissipationStep (mkPoint 0 0 2))))
     4)))
(check-sat)
(pop)

; [23/23] dissipation_reaches_veille (induction structurelle sur Z + bornage Z <= 7)
(echo "[THM] dissipation_reaches_veille")
(push)
(assert (not
  (and
    ; Base et reduction peripherique -> centre pour tout p
    (forall ((p CoreAffectPoint))
      (=> (validPointNatZ p)
          (and
            (=> (or (not (= (pt_x p) 0)) (not (= (pt_y p) 0)))
                (= (dissipationStep p) (mkPoint 0 0 (pt_z p))))
            (= (dissipationStep (mkPoint 0 0 0)) (mkPoint 0 0 0))
            (= (dissipationStep (mkPoint 0 0 1)) (mkPoint 0 0 0))
            (= (dissipationStep (mkPoint 0 0 2)) (mkPoint 0 0 0))
            (=> (>= (pt_z p) 3)
                (= (dissipationStep (mkPoint 0 0 (pt_z p))) (mkPoint 0 0 (- (pt_z p) 1)))))))
    ; Convergence complete en <= z + 1 pas pour toutes strates Z = 0..7 et tout (x, y)
    (forall ((p CoreAffectPoint))
      (=> (and (>= (pt_z p) 0) (<= (pt_z p) 7))
          (= (repeatDissipation (+ (pt_z p) 1) p) (mkPoint 0 0 0)))))))
(check-sat)
(pop)
