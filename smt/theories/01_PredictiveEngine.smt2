; =============================================================================
; Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
; SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
; Author: Manuel Cabelguen
;
; Module 01 : PredictiveEngine (SMT-LIB 2.6 / Z3)
; Equivalence formelle directe avec Cartograffect/PredictiveEngine.lean
; =============================================================================
(set-logic ALL)
(set-option :produce-models true)

; -----------------------------------------------------------------------------
; 1. Types fondamentaux
; -----------------------------------------------------------------------------
(declare-datatypes ((Polarity 0)) (
  ((Pol_neg) (Pol_zero) (Pol_pos))
))

(declare-datatypes ((FunctionalRegime 0)) (
  ((Reg_charge) (Reg_neutral) (Reg_discharge))
))

(declare-datatypes ((InferentialOperation 0)) (
  ((IO_ascendingSensory) (IO_actionImplementation) (IO_contextualGenerative) (IO_integrativeWeighting))
))

(declare-datatypes ((EngineInterface 0)) (
  ((EI_perceptive) (EI_subjective) (EI_attentional))
))

(declare-datatypes ((SalientDiscrepancy 0)) (
  ((mkSalientDiscrepancy
    (sd_magnitude Int)
    (sd_sensoryThreshold Int)
    (sd_resorptionThreshold Int)))
))

(define-fun validSalientDiscrepancy ((d SalientDiscrepancy)) Bool
  (and (>= (sd_magnitude d) 0)
       (>= (sd_sensoryThreshold d) 0)
       (>= (sd_resorptionThreshold d) 0)
       (<= (sd_resorptionThreshold d) (sd_sensoryThreshold d))))

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

(define-fun validAttentional ((a AttentionalInterface)) Bool
  (and (>= (ai_allocatedPrecision a) 0)
       (>= (ai_engagementThreshold a) 0)
       (>= (ai_persistenceDepth a) 0)
       (>= (ai_precisionA a) 0)
       (>= (ai_precisionC a) 0)))

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

(define-fun validEngineState ((s PredictiveEngineState)) Bool
  (and (validSalientDiscrepancy (pes_discrepancy s))
       (validAttentional (pes_attentional s))))

; -----------------------------------------------------------------------------
; 2. Fonctions fondamentales
; -----------------------------------------------------------------------------
(define-fun Polarity_toRegime ((p Polarity)) FunctionalRegime
  (ite (= p Pol_neg) Reg_charge
  (ite (= p Pol_zero) Reg_neutral Reg_discharge)))

(define-fun Polarity_invert ((p Polarity)) Polarity
  (ite (= p Pol_neg) Pol_pos
  (ite (= p Pol_zero) Pol_zero Pol_neg)))

(define-fun Polarity_isEngaged ((p Polarity)) Bool
  (not (= p Pol_zero)))

(define-fun SalientDiscrepancy_isSensorilySalient ((d SalientDiscrepancy)) Bool
  (<= (sd_sensoryThreshold d) (sd_magnitude d)))

(define-fun SalientDiscrepancy_isInRemanenceWindow ((d SalientDiscrepancy)) Bool
  (and (<= (sd_resorptionThreshold d) (sd_magnitude d))
       (< (sd_magnitude d) (sd_sensoryThreshold d))))

(define-fun AttentionalInterface_isEngaged ((att AttentionalInterface)) Bool
  (<= (ai_engagementThreshold att) (ai_allocatedPrecision att)))

(define-fun InferentialOperation_carrierInterface ((op InferentialOperation)) EngineInterface
  (ite (or (= op IO_ascendingSensory) (= op IO_actionImplementation)) EI_perceptive
  (ite (= op IO_contextualGenerative) EI_subjective EI_attentional)))

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

(define-fun PredictiveEngineState_currentCoupling ((s PredictiveEngineState)) EngineCoupling
  (mkEngineCoupling
    (si_attenteGradient (pes_subjective s))
    (pi_controleGradient (pes_perceptive s))))

(define-fun PredictiveEngineState_feedbackUpdate
    ((s PredictiveEngineState) (newA Polarity) (newC Polarity) (newPrecision Int))
    PredictiveEngineState
  (mkPredictiveEngineState
    (pes_discrepancy s)
    (mkPerceptiveInterface newC)
    (mkSubjectiveInterface newA (si_descendingSuspension (pes_subjective s)))
    (mkAttentionalInterface
      newPrecision
      (ai_engagementThreshold (pes_attentional s))
      (ai_persistenceDepth (pes_attentional s))
      (ai_precisionA (pes_attentional s))
      (ai_precisionC (pes_attentional s)))))

(define-fun PredictiveEngineState_feedbackUpdateWeighted
    ((s PredictiveEngineState) (newA Polarity) (newC Polarity)
     (newPrecision Int) (newPrecisionA Int) (newPrecisionC Int))
    PredictiveEngineState
  (mkPredictiveEngineState
    (pes_discrepancy s)
    (mkPerceptiveInterface newC)
    (mkSubjectiveInterface newA (si_descendingSuspension (pes_subjective s)))
    (mkAttentionalInterface
      newPrecision
      (ai_engagementThreshold (pes_attentional s))
      (ai_persistenceDepth (pes_attentional s))
      newPrecisionA
      newPrecisionC)))

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

; -----------------------------------------------------------------------------
; Controle de non-vacuite (doit retourner sat)
; -----------------------------------------------------------------------------
(echo "[CONSISTENCY]")
(push)
(declare-const s_test PredictiveEngineState)
(assert (validEngineState s_test))
(check-sat)
(pop)

; -----------------------------------------------------------------------------
; 3. Audit des 7 theoremes de PredictiveEngine (chaque controle doit retourner unsat)
; -----------------------------------------------------------------------------

; [1/7] Polarity_invert_involutive
(echo "[THM] Polarity_invert_involutive")
(push)
(assert (not
  (forall ((p Polarity))
    (= (Polarity_invert (Polarity_invert p)) p))))
(check-sat)
(pop)

; [2/7] coupling_regime_partition
(echo "[THM] coupling_regime_partition")
(push)
(assert (not
  (forall ((c EngineCoupling))
    (or
      (and (= (EngineCoupling_isGlobalNeutrality c) true)
           (= (EngineCoupling_isSingleEngaged c) false)
           (= (EngineCoupling_isDualEngaged c) false))
      (and (= (EngineCoupling_isGlobalNeutrality c) false)
           (= (EngineCoupling_isSingleEngaged c) true)
           (= (EngineCoupling_isDualEngaged c) false))
      (and (= (EngineCoupling_isGlobalNeutrality c) false)
           (= (EngineCoupling_isSingleEngaged c) false)
           (= (EngineCoupling_isDualEngaged c) true))))))
(check-sat)
(pop)

; [3/7] feedbackUpdate_couples_gradients
(echo "[THM] feedbackUpdate_couples_gradients")
(push)
(assert (not
  (forall ((s PredictiveEngineState) (newA Polarity) (newC Polarity) (newPrecision Int))
    (=> (and (validEngineState s) (>= newPrecision 0))
        (let ((s1 (PredictiveEngineState_feedbackUpdate s newA newC newPrecision)))
          (and (= (PredictiveEngineState_currentCoupling s1) (mkEngineCoupling newA newC))
               (= (ai_allocatedPrecision (pes_attentional s1)) newPrecision)
               (= (pes_discrepancy s1) (pes_discrepancy s))))))))
(check-sat)
(pop)

; [4/7] inferential_loop_covers_interfaces
(echo "[THM] inferential_loop_covers_interfaces")
(push)
(assert (not
  (forall ((iface EngineInterface))
    (exists ((op InferentialOperation))
      (= (InferentialOperation_carrierInterface op) iface)))))
(check-sat)
(pop)

; [5/7] feedbackUpdateWeighted_couples_precision
(echo "[THM] feedbackUpdateWeighted_couples_precision")
(push)
(assert (not
  (forall ((s PredictiveEngineState) (newA Polarity) (newC Polarity)
           (newPrecision Int) (newPA Int) (newPC Int))
    (=> (and (validEngineState s) (>= newPrecision 0) (>= newPA 0) (>= newPC 0))
        (let ((s1 (PredictiveEngineState_feedbackUpdateWeighted s newA newC newPrecision newPA newPC)))
          (and (= (PredictiveEngineState_currentCoupling s1) (mkEngineCoupling newA newC))
               (= (ai_allocatedPrecision (pes_attentional s1)) newPrecision)
               (= (ai_precisionA (pes_attentional s1)) newPA)
               (= (ai_precisionC (pes_attentional s1)) newPC)
               (= (pes_discrepancy s1) (pes_discrepancy s))))))))
(check-sat)
(pop)

; [6/7] engineStep_remanence
(echo "[THM] engineStep_remanence")
(push)
(assert (not
  (forall ((s PredictiveEngineState))
    (=> (and (validEngineState s)
             (SalientDiscrepancy_isInRemanenceWindow (pes_discrepancy s)))
        (= (engineStep s) s)))))
(check-sat)
(pop)

; [7/7] engineStep_phase_progression
(echo "[THM] engineStep_phase_progression")
(push)
(assert (not
  (forall ((s0 PredictiveEngineState))
    (=> (and (validEngineState s0)
             (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s0))
             (EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s0))
             (= (si_descendingSuspension (pes_subjective s0)) false)
             (= (AttentionalInterface_isEngaged (pes_attentional s0)) false))
        (let ((s1 (engineStep s0)))
          (let ((s2 (engineStep s1)))
            (let ((s3 (engineStep s2)))
              (and (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s1))
                   (not (EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s1)))
                   (= (si_descendingSuspension (pes_subjective s1)) false)
                   (= (AttentionalInterface_isEngaged (pes_attentional s1)) false)
                   (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s2))
                   (not (EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s2)))
                   (= (si_descendingSuspension (pes_subjective s2)) true)
                   (= (AttentionalInterface_isEngaged (pes_attentional s2)) false)
                   (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s3))
                   (not (EngineCoupling_isGlobalNeutrality (PredictiveEngineState_currentCoupling s3)))
                   (= (si_descendingSuspension (pes_subjective s3)) true)
                   (= (AttentionalInterface_isEngaged (pes_attentional s3)) true)))))))))
(check-sat)
(pop)
