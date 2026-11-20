; =============================================================================
; Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
; SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
; Author: Manuel Cabelguen
;
; Module 07 : PredictiveCircuit (SMT-LIB 2.6 / Z3)
; Equivalence formelle directe avec Cartograffect/PredictiveCircuit.lean
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

(declare-datatypes ((CoreAffectPoint 0)) (
  ((mkPoint (pt_x Int) (pt_y Int) (pt_z Int)))
))

(declare-datatypes ((InterfaceSide 0)) (
  ((IS_internal) (IS_external))
))

(declare-datatypes ((CircuitOperation 0)) (
  ((CO_subjectiveOut) (CO_perceptiveOut)
   (CO_attentionalCrossingI) (CO_attentionalCrossingII)
   (CO_subjectiveIn) (CO_perceptiveIn))
))

(declare-datatypes ((ProtoSpatialNode 0)) (
  ((mkProtoSpatialNode (psn_x Int) (psn_y Int)))
))

(declare-datatypes ((IntPair 0)) (
  ((mkPair (pr_fst Int) (pr_snd Int)))
))

(declare-datatypes ((SubjectiveReturnChannel 0)) (
  ((mkSubjectiveReturnChannel (src_regimeA FunctionalRegime) (src_contextC Polarity)))
))

(declare-datatypes ((PerceptiveReturnChannel 0)) (
  ((mkPerceptiveReturnChannel (prc_regimeC FunctionalRegime) (prc_contextA Polarity)))
))

(declare-datatypes ((CircuitKernelParams 0)) (
  ((mkCircuitKernelParams
    (ckp_scale Int) (ckp_rho Int) (ckp_kappa Int)
    (ckp_deltaA Int) (ckp_deltaC Int) (ckp_gammaA Int) (ckp_gammaC Int)
    (ckp_epsilon Int) (ckp_qPosA Int) (ckp_qPosC Int) (ckp_chi Int)))
))

(declare-datatypes ((HiddenSubjectiveState 0)) (
  ((mkHiddenSubjectiveState
    (hss_modelDiscrepancy Int)
    (hss_revisable Bool)
    (hss_descendingSuspension Bool)))
))

(declare-datatypes ((HiddenPerceptiveState 0)) (
  ((mkHiddenPerceptiveState
    (hps_afferentDiscrepancy Int)
    (hps_controllable Bool)))
))

(declare-datatypes ((BodyEnvironmentState 0)) (
  ((mkBodyEnvironmentState (bes_perturbation Int)))
))

(declare-datatypes ((CircularCircuitState 0)) (
  ((mkCircularCircuitState
    (ccs_subjectiveHidden HiddenSubjectiveState)
    (ccs_perceptiveHidden HiddenPerceptiveState)
    (ccs_bodyEnv BodyEnvironmentState)
    (ccs_sensoryThreshold Int)
    (ccs_resorptionThreshold Int)
    (ccs_attentional AttentionalInterface)))
))

(declare-datatypes ((UnifiedDynamicsParams 0)) (
  ((mkUnifiedDynamicsParams
    (udp_halfScale Int)
    (udp_lambdaNum Int)
    (udp_etaScaled Int)
    (udp_betaAtt Int)
    (udp_alphaCharge Int)
    (udp_sigmoidK Int)
    (udp_zMax Int)))
))

; Fonctions de seuils abstraites d'hysteresis R5 (thetaDown z < thetaUp z pour tout z >= 0)
(declare-fun thetaUp (Int) Int)
(declare-fun thetaDown (Int) Int)
(assert (forall ((z Int)) (=> (>= z 0) (and (>= (thetaDown z) 0) (< (thetaDown z) (thetaUp z))))))

; -----------------------------------------------------------------------------
; 2. Predicats de validite et fonctions
; -----------------------------------------------------------------------------
(define-fun validAttentional ((a AttentionalInterface)) Bool
  (and (>= (ai_allocatedPrecision a) 0)
       (>= (ai_engagementThreshold a) 0)
       (>= (ai_persistenceDepth a) 0)
       (>= (ai_precisionA a) 0)
       (>= (ai_precisionC a) 0)))

(define-fun validCircuitKernelParams ((p CircuitKernelParams)) Bool
  (and (> (ckp_scale p) 0)
       (>= (ckp_rho p) 0) (<= (ckp_rho p) (ckp_scale p))
       (>= (ckp_kappa p) 0) (<= (ckp_kappa p) (ckp_scale p))
       (>= (ckp_deltaA p) 0) (<= (ckp_deltaA p) (ckp_scale p))
       (>= (ckp_deltaC p) 0) (<= (ckp_deltaC p) (ckp_scale p))
       (<= (+ (ckp_rho p) (ckp_deltaA p)) (ckp_scale p))
       (<= (+ (ckp_kappa p) (ckp_deltaC p)) (ckp_scale p))
       (>= (ckp_gammaA p) 0) (<= (ckp_gammaA p) (ckp_scale p))
       (>= (ckp_gammaC p) 0) (<= (ckp_gammaC p) (ckp_scale p))
       (>= (ckp_epsilon p) 0) (<= (ckp_epsilon p) (ckp_scale p))
       (>= (ckp_qPosA p) 0) (<= (ckp_qPosA p) (ckp_scale p))
       (>= (ckp_qPosC p) 0) (<= (ckp_qPosC p) (ckp_scale p))
       (>= (ckp_chi p) 0) (<= (ckp_chi p) (ckp_scale p))))

(define-fun validCircularCircuitState ((s CircularCircuitState)) Bool
  (and (>= (hss_modelDiscrepancy (ccs_subjectiveHidden s)) 0)
       (>= (hps_afferentDiscrepancy (ccs_perceptiveHidden s)) 0)
       (>= (bes_perturbation (ccs_bodyEnv s)) 0)
       (>= (ccs_sensoryThreshold s) 0)
       (>= (ccs_resorptionThreshold s) 0)
       (<= (ccs_resorptionThreshold s) (ccs_sensoryThreshold s))
       (validAttentional (ccs_attentional s))))

(define-fun validUnifiedDynamicsParams ((p UnifiedDynamicsParams)) Bool
  (and (> (udp_halfScale p) 0)
       (>= (udp_lambdaNum p) 0)
       (< (udp_lambdaNum p) (* 2 (udp_halfScale p)))
       (>= (udp_etaScaled p) 0)
       (>= (udp_betaAtt p) 0)
       (>= (udp_alphaCharge p) 0)
       (> (udp_sigmoidK p) 0)
       (>= (udp_zMax p) 2)))

(define-fun intAbs ((v Int)) Int (ite (>= v 0) v (- v)))
(define-fun minInt ((a Int) (b Int)) Int (ite (<= a b) a b))
(define-fun clampInt ((lo Int) (hi Int) (v Int)) Int (ite (< v lo) lo (ite (< hi v) hi v)))
(define-fun pow5 ((m Int)) Int (* m (* m (* m (* m m)))))
(define-fun pow6 ((m Int)) Int (* m (* m (* m (* m (* m m))))))

(define-fun Polarity_toRegime ((p Polarity)) FunctionalRegime
  (ite (= p Pol_neg) Reg_charge (ite (= p Pol_zero) Reg_neutral Reg_discharge)))

(define-fun Polarity_isEngaged ((p Polarity)) Bool (not (= p Pol_zero)))

(define-fun EngineCoupling_isGlobalNeutrality ((c EngineCoupling)) Bool
  (and (not (Polarity_isEngaged (ec_attente c)))
       (not (Polarity_isEngaged (ec_controle c)))))

(define-fun AttentionalInterface_isEngaged ((att AttentionalInterface)) Bool
  (<= (ai_engagementThreshold att) (ai_allocatedPrecision att)))

(define-fun crownRadius ((z Int)) Int (ite (< z 2) 0 (- (* 2 z) 2)))

(define-fun isValidCoreAffect ((p CoreAffectPoint)) Bool
  (and (>= (pt_z p) 0)
       (or (and (= (pt_x p) 0) (= (pt_y p) 0))
           (and (>= (pt_z p) 2)
                (= (+ (intAbs (pt_x p)) (intAbs (pt_y p))) (crownRadius (pt_z p)))))))

(define-fun signedAmplitude ((pol Polarity) (amp Int)) Int
  (ite (= pol Pol_neg) (- amp) (ite (= pol Pol_zero) 0 amp)))

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

; 6 operations du circuit
(define-fun CircuitOperation_carrierInterface ((op CircuitOperation)) EngineInterface
  (ite (or (= op CO_subjectiveOut) (= op CO_subjectiveIn)) EI_subjective
  (ite (or (= op CO_perceptiveOut) (= op CO_perceptiveIn)) EI_perceptive
  EI_attentional)))

(define-fun CircuitOperation_side ((op CircuitOperation)) InterfaceSide
  (ite (or (= op CO_subjectiveOut) (= op CO_perceptiveOut) (= op CO_attentionalCrossingI))
    IS_internal IS_external))

(define-fun CircuitOperation_toInferentialOperation ((op CircuitOperation)) InferentialOperation
  (ite (or (= op CO_subjectiveOut) (= op CO_subjectiveIn)) IO_contextualGenerative
  (ite (= op CO_perceptiveOut) IO_actionImplementation
  (ite (= op CO_perceptiveIn) IO_ascendingSensory
  IO_integrativeWeighting))))

; Bijection L1 & grilles
(define-fun ProtoSpatialNode_l1Norm ((n ProtoSpatialNode)) Int
  (+ (intAbs (psn_x n)) (intAbs (psn_y n))))

(define-fun isValidProtoSpatial ((n ProtoSpatialNode)) Bool
  (or (and (= (psn_x n) 0) (= (psn_y n) 0))
      (= (ProtoSpatialNode_l1Norm n) 2)))

(define-fun phiL1 ((c EngineCoupling)) ProtoSpatialNode
  (let ((a (ec_attente c)) (ctrl (ec_controle c)))
    (ite (and (= a Pol_zero) (= ctrl Pol_zero)) (mkProtoSpatialNode 0 0)
    (ite (and (= a Pol_pos)  (= ctrl Pol_zero)) (mkProtoSpatialNode 2 0)
    (ite (and (= a Pol_neg)  (= ctrl Pol_zero)) (mkProtoSpatialNode (- 2) 0)
    (ite (and (= a Pol_zero) (= ctrl Pol_pos))  (mkProtoSpatialNode 0 2)
    (ite (and (= a Pol_zero) (= ctrl Pol_neg))  (mkProtoSpatialNode 0 (- 2))
    (ite (and (= a Pol_pos)  (= ctrl Pol_pos))  (mkProtoSpatialNode 1 1)
    (ite (and (= a Pol_pos)  (= ctrl Pol_neg))  (mkProtoSpatialNode 1 (- 1))
    (ite (and (= a Pol_neg)  (= ctrl Pol_pos))  (mkProtoSpatialNode (- 1) 1)
    (mkProtoSpatialNode (- 1) (- 1))))))))))))

(define-fun polarityOfInt ((v Int)) Polarity
  (ite (> v 0) Pol_pos (ite (< v 0) Pol_neg Pol_zero)))

(define-fun phiL1Inv ((n ProtoSpatialNode)) EngineCoupling
  (mkEngineCoupling (polarityOfInt (psn_x n)) (polarityOfInt (psn_y n))))

(define-fun idxAttente ((p Polarity)) Int
  (ite (= p Pol_zero) 0 (ite (= p Pol_neg) 1 2)))

(define-fun idxControle ((p Polarity)) Int
  (ite (= p Pol_pos) 0 (ite (= p Pol_neg) 1 2)))

(define-fun crossingIPos ((c EngineCoupling)) IntPair
  (mkPair (idxAttente (ec_attente c)) (idxControle (ec_controle c))))

(define-fun crossingIIPos ((c EngineCoupling)) IntPair
  (mkPair (idxControle (ec_controle c)) (idxAttente (ec_attente c))))

(define-fun routeToSubjective ((c EngineCoupling)) SubjectiveReturnChannel
  (mkSubjectiveReturnChannel (Polarity_toRegime (ec_attente c)) (ec_controle c)))

(define-fun routeToPerceptive ((c EngineCoupling)) PerceptiveReturnChannel
  (mkPerceptiveReturnChannel (Polarity_toRegime (ec_controle c)) (ec_attente c)))

(define-fun projectPerceptible ((c EngineCoupling) (z Int) (piA Int) (piC Int) (susp Bool)) CoreAffectPoint
  (ite (EngineCoupling_isGlobalNeutrality c)
    (ite (and susp (>= z 2)) (mkPoint 0 0 z) (mkPoint 0 0 0))
    (ite (= z 0) (mkPoint 0 0 0)
    (ite (= z 1) (mkPoint 0 0 1)
    (deployCouplingWithPrecision c (- z 2) piA piC)))))

; Poids attentionnels L1 & Lyapunov
(define-fun attentionalWeightX2 ((c EngineCoupling)) Int
  (ite (= (ec_attente c) Pol_zero) 2 (intAbs (psn_x (phiL1 c)))))

(define-fun attentionalWeightY2 ((c EngineCoupling)) Int
  (ite (= (ec_controle c) Pol_zero) 2 (intAbs (psn_y (phiL1 c)))))

(define-fun polarityEnergy ((p Polarity)) Int
  (ite (= p Pol_zero) 0 (ite (= p Pol_pos) 1 2)))

(define-fun lyapunovPotential ((c EngineCoupling)) Int
  (+ (polarityEnergy (ec_attente c)) (polarityEnergy (ec_controle c))))

; Noyau markovien exact (4 * scale^6)
(define-fun isCharged ((p Polarity)) Bool (= p Pol_neg))

(define-fun effectiveEpsScaled ((m Int) (eps Int) (chi Int) (otherCharged Bool)) Int
  (ite otherCharged (+ (* m eps) (* chi (- m eps))) (* m eps)))

(define-fun marginalWeight
    ((m Int) (rate Int) (delta Int) (deseng Int) (eps Int) (qPos Int) (chi Int)
     (otherCharged Bool) (w2 Int) (src Polarity) (dst Polarity)) Int
  (let ((e2 (effectiveEpsScaled m eps chi otherCharged)))
    (ite (= src Pol_zero)
      (ite (= dst Pol_zero) (* 2 m (- (* m m) e2))
      (ite (= dst Pol_neg)  (* 2 e2 (- m qPos))
      (* 2 e2 qPos)))
    (ite (= src Pol_neg)
      (ite (= dst Pol_zero) (* m m (* 2 delta))
      (ite (= dst Pol_neg)  (* m m (- (* 2 m) (* w2 rate) (* 2 delta)))
      (* m m (* w2 rate))))
      (ite (= dst Pol_zero) (* (- (* m m) e2) (* w2 deseng))
      (ite (= dst Pol_neg)  (* 2 m e2)
      (* (- (* m m) e2) (- (* 2 m) (* w2 deseng)))))))))

(define-fun circuitWeight ((p CircuitKernelParams) (src EngineCoupling) (dst EngineCoupling)) Int
  (* (marginalWeight (ckp_scale p) (ckp_rho p) (ckp_deltaA p) (ckp_gammaA p)
                     (ckp_epsilon p) (ckp_qPosA p) (ckp_chi p)
                     (isCharged (ec_controle src)) (attentionalWeightX2 src)
                     (ec_attente src) (ec_attente dst))
     (marginalWeight (ckp_scale p) (ckp_kappa p) (ckp_deltaC p) (ckp_gammaC p)
                     (ckp_epsilon p) (ckp_qPosC p) (ckp_chi p)
                     (isCharged (ec_attente src)) (attentionalWeightY2 src)
                     (ec_controle src) (ec_controle dst))))

(define-fun circuitRowSum ((p CircuitKernelParams) (src EngineCoupling)) Int
  (+ (circuitWeight p src (mkEngineCoupling Pol_zero Pol_zero))
     (circuitWeight p src (mkEngineCoupling Pol_pos  Pol_zero))
     (circuitWeight p src (mkEngineCoupling Pol_neg  Pol_zero))
     (circuitWeight p src (mkEngineCoupling Pol_zero Pol_pos))
     (circuitWeight p src (mkEngineCoupling Pol_zero Pol_neg))
     (circuitWeight p src (mkEngineCoupling Pol_pos  Pol_pos))
     (circuitWeight p src (mkEngineCoupling Pol_pos  Pol_neg))
     (circuitWeight p src (mkEngineCoupling Pol_neg  Pol_pos))
     (circuitWeight p src (mkEngineCoupling Pol_neg  Pol_neg))))

(define-fun weightedDriftSum ((p CircuitKernelParams) (src EngineCoupling)) Int
  (+ (* (circuitWeight p src (mkEngineCoupling Pol_zero Pol_zero)) (- (lyapunovPotential src) (lyapunovPotential (mkEngineCoupling Pol_zero Pol_zero))))
     (* (circuitWeight p src (mkEngineCoupling Pol_pos  Pol_zero)) (- (lyapunovPotential src) (lyapunovPotential (mkEngineCoupling Pol_pos  Pol_zero))))
     (* (circuitWeight p src (mkEngineCoupling Pol_neg  Pol_zero)) (- (lyapunovPotential src) (lyapunovPotential (mkEngineCoupling Pol_neg  Pol_zero))))
     (* (circuitWeight p src (mkEngineCoupling Pol_zero Pol_pos))  (- (lyapunovPotential src) (lyapunovPotential (mkEngineCoupling Pol_zero Pol_pos))))
     (* (circuitWeight p src (mkEngineCoupling Pol_zero Pol_neg))  (- (lyapunovPotential src) (lyapunovPotential (mkEngineCoupling Pol_zero Pol_neg))))
     (* (circuitWeight p src (mkEngineCoupling Pol_pos  Pol_pos))  (- (lyapunovPotential src) (lyapunovPotential (mkEngineCoupling Pol_pos  Pol_pos))))
     (* (circuitWeight p src (mkEngineCoupling Pol_pos  Pol_neg))  (- (lyapunovPotential src) (lyapunovPotential (mkEngineCoupling Pol_pos  Pol_neg))))
     (* (circuitWeight p src (mkEngineCoupling Pol_neg  Pol_pos))  (- (lyapunovPotential src) (lyapunovPotential (mkEngineCoupling Pol_neg  Pol_pos))))
     (* (circuitWeight p src (mkEngineCoupling Pol_neg  Pol_neg))  (- (lyapunovPotential src) (lyapunovPotential (mkEngineCoupling Pol_neg  Pol_neg))))))

; Circuit circulaire continu a 6 operateurs
(define-fun defaultCircularCircuitState () CircularCircuitState
  (mkCircularCircuitState
    (mkHiddenSubjectiveState 0 true false)
    (mkHiddenPerceptiveState 0 true)
    (mkBodyEnvironmentState 0)
    1 1
    (mkAttentionalInterface 0 0 0 1 1)))

(define-fun op1_subjectiveOut ((s CircularCircuitState)) Polarity
  (ite (< (hss_modelDiscrepancy (ccs_subjectiveHidden s)) (ccs_resorptionThreshold s)) Pol_zero
  (ite (hss_revisable (ccs_subjectiveHidden s)) Pol_pos Pol_neg)))

(define-fun op2_perceptiveOut ((s CircularCircuitState)) Polarity
  (ite (< (hps_afferentDiscrepancy (ccs_perceptiveHidden s)) (ccs_resorptionThreshold s)) Pol_zero
  (ite (hps_controllable (ccs_perceptiveHidden s)) Pol_pos Pol_neg)))

(define-fun op3_crossingI_point ((s CircularCircuitState)) CoreAffectPoint
  (let ((c (mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s)))
        (att (ccs_attentional s))
        (susp (hss_descendingSuspension (ccs_subjectiveHidden s))))
    (let ((z (ite (EngineCoupling_isGlobalNeutrality c)
               (ite susp (+ (ai_persistenceDepth att) 2) 0)
               (ite (not (AttentionalInterface_isEngaged att))
                 (ite susp (+ (ai_persistenceDepth att) 2) 1)
                 (+ (ai_persistenceDepth att) 2)))))
      (projectPerceptible c z (ai_precisionA att) (ai_precisionC att) susp))))

(define-fun op5_subjectiveIn ((s CircularCircuitState) (ch SubjectiveReturnChannel) (pt CoreAffectPoint)) HiddenSubjectiveState
  (let ((sh (ccs_subjectiveHidden s)))
    (mkHiddenSubjectiveState
      (ite (= (src_regimeA ch) Reg_discharge)
        (ite (> (hss_modelDiscrepancy sh) 0) (- (hss_modelDiscrepancy sh) 1) 0)
        (hss_modelDiscrepancy sh))
      (or (hss_revisable sh)
          (and (= (src_regimeA ch) Reg_charge)
               (= (src_contextC ch) Pol_pos)
               (>= (pt_z pt) 2)))
      (ite (and (= (src_regimeA ch) Reg_neutral) (= (src_contextC ch) Pol_zero))
        false
        (hss_descendingSuspension sh)))))

(define-fun op6_perceptiveIn ((s CircularCircuitState) (ch PerceptiveReturnChannel) (pt CoreAffectPoint)) HiddenPerceptiveState
  (let ((ph (ccs_perceptiveHidden s)))
    (let ((reduced (ite (and (= (prc_regimeC ch) Reg_discharge) (> (pt_y pt) 0))
                     (ite (> (hps_afferentDiscrepancy ph) 0) (- (hps_afferentDiscrepancy ph) 1) 0)
                     (hps_afferentDiscrepancy ph))))
      (mkHiddenPerceptiveState
        (+ reduced (bes_perturbation (ccs_bodyEnv s)))
        (hps_controllable ph)))))

(define-fun circularCycle ((s CircularCircuitState)) CircularCircuitState
  (let ((c (mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s)))
        (pt (op3_crossingI_point s)))
    (mkCircularCircuitState
      (op5_subjectiveIn s (routeToSubjective c) pt)
      (op6_perceptiveIn s (routeToPerceptive c) pt)
      (ccs_bodyEnv s)
      (ccs_sensoryThreshold s)
      (ccs_resorptionThreshold s)
      (ccs_attentional s))))

; Loi unifiee (R_t, Z_t, pi_A, pi_C)
(define-fun defaultUnifiedDynamicsParams () UnifiedDynamicsParams
  (mkUnifiedDynamicsParams 500 800 600 2 50 100 7))

(define-fun activeResolutionCount ((src EngineCoupling) (dst EngineCoupling)) Int
  (+ (ite (and (= (ec_attente src) Pol_neg) (= (ec_attente dst) Pol_pos)) 1 0)
     (ite (and (= (ec_controle src) Pol_neg) (= (ec_controle dst) Pol_pos)) 1 0)))

(define-fun nextChargeAccumulator
    ((p UnifiedDynamicsParams) (r Int) (piAScaled Int) (piCScaled Int)
     (src EngineCoupling) (dst EngineCoupling)) Int
  (let ((s (* 2 (udp_halfScale p)))
        (contribA (ite (= (ec_attente src) Pol_neg) piAScaled 0))
        (contribC (ite (= (ec_controle src) Pol_neg) piCScaled 0))
        (relief (* (udp_etaScaled p) (activeResolutionCount src dst))))
    (let ((raw (- (+ (div (* (udp_lambdaNum p) r) s) contribA contribC) relief)))
      (ite (>= raw 0) raw 0))))

(define-fun chargeAccumulatorBound ((p UnifiedDynamicsParams)) Int
  (let ((s (* 2 (udp_halfScale p))))
    (div (* s s) (- s (udp_lambdaNum p)))))

(define-fun nextStratumR5 ((p UnifiedDynamicsParams) (z Int) (rNext Int)) Int
  (ite (> rNext (thetaUp z))
    (minInt (udp_zMax p) (+ z 1))
    (ite (< rNext (thetaDown z))
      (ite (<= z 2) 0 (minInt (udp_zMax p) (- z 1)))
      (minInt (udp_zMax p) z))))

(define-fun symmetricSigmoid ((halfScale Int) (k Int) (u Int)) IntPair
  (let ((shift (div (* halfScale (intAbs u)) (+ (intAbs u) k))))
    (ite (>= u 0)
      (mkPair (+ halfScale shift) (- halfScale shift))
      (mkPair (- halfScale shift) (+ halfScale shift)))))

(define-fun chargeIndicatorInt ((pol Polarity)) Int
  (ite (= pol Pol_neg) 1 0))

(define-fun precisionScore ((p UnifiedDynamicsParams) (rhoHat Int) (kappaHat Int) (c EngineCoupling)) Int
  (* (udp_betaAtt p)
     (+ (- rhoHat kappaHat)
        (* (udp_alphaCharge p)
           (- (chargeIndicatorInt (ec_attente c))
              (chargeIndicatorInt (ec_controle c)))))))

(define-fun precisionShares ((p UnifiedDynamicsParams) (rhoHat Int) (kappaHat Int) (c EngineCoupling)) IntPair
  (symmetricSigmoid (udp_halfScale p) (udp_sigmoidK p) (precisionScore p rhoHat kappaHat c)))

(define-fun spatialBudget ((z Int)) Int
  (ite (< z 2) 0 (- (* 2 z) 2)))

(define-fun projectUnifiedState
    ((p UnifiedDynamicsParams) (c EngineCoupling) (z Int) (rhoHat Int) (kappaHat Int) (susp Bool))
    CoreAffectPoint
  (let ((sh (precisionShares p rhoHat kappaHat c)))
    (projectPerceptible c z (pr_fst sh) (pr_snd sh) susp)))

; -----------------------------------------------------------------------------
; Controle de non-vacuite (doit retourner sat)
; -----------------------------------------------------------------------------
(echo "[CONSISTENCY]")
(push)
(declare-const kp CircuitKernelParams)
(declare-const up UnifiedDynamicsParams)
(assert (validCircuitKernelParams kp))
(assert (validUnifiedDynamicsParams up))
(check-sat)
(pop)

; -----------------------------------------------------------------------------
; 3. Audit des 41 theoremes de PredictiveCircuit (chaque controle doit retourner unsat)
; -----------------------------------------------------------------------------

; [1/41] circuit_covers_interfaces_both_sides
(echo "[THM] circuit_covers_interfaces_both_sides")
(push)
(assert (not
  (forall ((iface EngineInterface) (s InterfaceSide))
    (exists ((op CircuitOperation))
      (and (= (CircuitOperation_carrierInterface op) iface)
           (= (CircuitOperation_side op) s)
           (forall ((op2 CircuitOperation))
             (=> (and (= (CircuitOperation_carrierInterface op2) iface)
                      (= (CircuitOperation_side op2) s))
                 (= op2 op))))))))
(check-sat)
(pop)

; [2/41] circuit_refines_inferential_ops
(echo "[THM] circuit_refines_inferential_ops")
(push)
(assert (not
  (forall ((iop InferentialOperation))
    (exists ((op CircuitOperation))
      (= (CircuitOperation_toInferentialOperation op) iop)))))
(check-sat)
(pop)

; [3/41] phiL1_left_inv
(echo "[THM] phiL1_left_inv")
(push)
(assert (not
  (forall ((c EngineCoupling))
    (= (phiL1Inv (phiL1 c)) c))))
(check-sat)
(pop)

; [4/41] phiL1_right_inv
(echo "[THM] phiL1_right_inv")
(push)
(assert (not
  (forall ((n ProtoSpatialNode))
    (=> (isValidProtoSpatial n)
        (= (phiL1 (phiL1Inv n)) n)))))
(check-sat)
(pop)

; [5/41] phiL1_agrees_with_deployZ2
(echo "[THM] phiL1_agrees_with_deployZ2")
(push)
(assert (not
  (forall ((c EngineCoupling))
    (and (= (psn_x (phiL1 c)) (pt_x (deployCouplingAtDepth c 0)))
         (= (psn_y (phiL1 c)) (pt_y (deployCouplingAtDepth c 0)))))))
(check-sat)
(pop)

; [6/41] crossingII_is_transpose_of_crossingI
(echo "[THM] crossingII_is_transpose_of_crossingI")
(push)
(assert (not
  (forall ((c EngineCoupling))
    (= (crossingIIPos c)
       (mkPair (pr_snd (crossingIPos c)) (pr_fst (crossingIPos c)))))))
(check-sat)
(pop)

; [7/41] routeToSubjective_injective
(echo "[THM] routeToSubjective_injective")
(push)
(assert (not
  (forall ((c1 EngineCoupling) (c2 EngineCoupling))
    (=> (= (routeToSubjective c1) (routeToSubjective c2))
        (= c1 c2)))))
(check-sat)
(pop)

; [8/41] routeToPerceptive_injective
(echo "[THM] routeToPerceptive_injective")
(push)
(assert (not
  (forall ((c1 EngineCoupling) (c2 EngineCoupling))
    (=> (= (routeToPerceptive c1) (routeToPerceptive c2))
        (= c1 c2)))))
(check-sat)
(pop)

; [9/41] projectPerceptible_valid
(echo "[THM] projectPerceptible_valid")
(push)
(assert (not
  (forall ((c EngineCoupling) (z Int) (piA Int) (piC Int) (susp Bool))
    (=> (and (>= z 0) (>= piA 0) (>= piC 0))
        (isValidCoreAffect (projectPerceptible c z piA piC susp))))))
(check-sat)
(pop)

; [10/41] projectPerceptible_z2_matches_phiL1
(echo "[THM] projectPerceptible_z2_matches_phiL1")
(push)
(assert (not
  (forall ((c EngineCoupling) (piA Int) (piC Int) (susp Bool))
    (=> (and (>= piA 0) (>= piC 0) (not (EngineCoupling_isGlobalNeutrality c)))
        (= (projectPerceptible c 2 piA piC susp)
           (mkPoint (psn_x (phiL1 c)) (psn_y (phiL1 c)) 2))))))
(check-sat)
(pop)

; [11/41] projectPerceptible_neutral_elevates_to_central
(echo "[THM] projectPerceptible_neutral_elevates_to_central")
(push)
(assert (not
  (forall ((z Int) (piA Int) (piC Int))
    (=> (and (>= z 2) (>= piA 0) (>= piC 0))
        (= (projectPerceptible (mkEngineCoupling Pol_zero Pol_zero) z piA piC true)
           (mkPoint 0 0 z))))))
(check-sat)
(pop)

; [12/41] attentional_bottleneck_sum_active
(echo "[THM] attentional_bottleneck_sum_active")
(push)
(assert (not
  (forall ((c EngineCoupling))
    (=> (not (EngineCoupling_isGlobalNeutrality c))
        (= (+ (ite (Polarity_isEngaged (ec_attente c)) (attentionalWeightX2 c) 0)
              (ite (Polarity_isEngaged (ec_controle c)) (attentionalWeightY2 c) 0))
           2)))))
(check-sat)
(pop)

; [13/41] circuitRowSum_exact
(echo "[THM] circuitRowSum_exact")
(push)
(assert (not
  (forall ((p CircuitKernelParams) (src EngineCoupling))
    (=> (validCircuitKernelParams p)
        (= (circuitRowSum p src) (* 4 (pow6 (ckp_scale p))))))))
(check-sat)
(pop)

; [14/41] veille_absorbing_free
(echo "[THM] veille_absorbing_free")
(push)
(assert (not
  (forall ((p CircuitKernelParams) (dst EngineCoupling))
    (=> (and (validCircuitKernelParams p) (= (ckp_epsilon p) 0))
        (= (circuitWeight p (mkEngineCoupling Pol_zero Pol_zero) dst)
           (ite (= dst (mkEngineCoupling Pol_zero Pol_zero)) (* 4 (pow6 (ckp_scale p))) 0))))))
(check-sat)
(pop)

; [15/41] lyapunov_monotone_free
(echo "[THM] lyapunov_monotone_free")
(push)
(assert (not
  (forall ((p CircuitKernelParams) (src EngineCoupling) (dst EngineCoupling))
    (=> (and (validCircuitKernelParams p)
             (= (ckp_epsilon p) 0)
             (= (ckp_chi p) 0)
             (> (circuitWeight p src dst) 0))
        (<= (lyapunovPotential dst) (lyapunovPotential src))))))
(check-sat)
(pop)

; [16/41] lyapunov_strict_descent_witness
(echo "[THM] lyapunov_strict_descent_witness")
(push)
(assert (not
  (forall ((p CircuitKernelParams) (src EngineCoupling))
    (=> (and (validCircuitKernelParams p)
             (= (ckp_epsilon p) 0) (= (ckp_chi p) 0)
             (> (ckp_rho p) 0) (> (ckp_kappa p) 0)
             (> (ckp_gammaA p) 0) (> (ckp_gammaC p) 0)
             (not (EngineCoupling_isGlobalNeutrality src)))
        (exists ((dst EngineCoupling))
          (and (> (circuitWeight p src dst) 0)
               (< (lyapunovPotential dst) (lyapunovPotential src))))))))
(check-sat)
(pop)

; [17/41] lyapunov_expected_drift_constant
(echo "[THM] lyapunov_expected_drift_constant")
(push)
(assert (not
  (forall ((p CircuitKernelParams) (r Int) (src EngineCoupling))
    (=> (and (validCircuitKernelParams p)
             (>= r 0)
             (= (ckp_epsilon p) 0) (= (ckp_chi p) 0)
             (= (ckp_deltaA p) 0) (= (ckp_deltaC p) 0)
             (= (ckp_rho p) r) (= (ckp_kappa p) r)
             (= (ckp_gammaA p) r) (= (ckp_gammaC p) r)
             (not (EngineCoupling_isGlobalNeutrality src)))
        (= (weightedDriftSum p src)
           (* 4 (pow5 (ckp_scale p)) r))))))
(check-sat)
(pop)

; [18/41] axial_peur_bifurcates_p2
(echo "[THM] axial_peur_bifurcates_p2")
(push)
(assert (not
  (forall ((p CircuitKernelParams))
    (=> (and (validCircuitKernelParams p)
             (> (ckp_chi p) 0)
             (> (ckp_qPosC p) 0) (< (ckp_qPosC p) (ckp_scale p))
             (< (+ (ckp_rho p) (ckp_deltaA p)) (ckp_scale p)))
        (and (> (circuitWeight p (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_neg Pol_pos)) 0)
             (> (circuitWeight p (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_neg Pol_neg)) 0))))))
(check-sat)
(pop)

; [19/41] veille_reaches_all_one_step
(echo "[THM] veille_reaches_all_one_step")
(push)
(assert (not
  (forall ((p CircuitKernelParams) (dst EngineCoupling))
    (=> (and (validCircuitKernelParams p)
             (> (ckp_epsilon p) 0) (< (ckp_epsilon p) (ckp_scale p))
             (> (ckp_qPosA p) 0) (< (ckp_qPosA p) (ckp_scale p))
             (> (ckp_qPosC p) 0) (< (ckp_qPosC p) (ckp_scale p)))
        (> (circuitWeight p (mkEngineCoupling Pol_zero Pol_zero) dst) 0)))))
(check-sat)
(pop)

; [20/41] all_reach_veille_two_steps
(echo "[THM] all_reach_veille_two_steps")
(push)
(assert (not
  (forall ((p CircuitKernelParams) (src EngineCoupling))
    (=> (and (validCircuitKernelParams p)
             (< (ckp_epsilon p) (ckp_scale p))
             (< (ckp_chi p) (ckp_scale p))
             (> (ckp_rho p) 0) (> (ckp_kappa p) 0)
             (> (ckp_gammaA p) 0) (> (ckp_gammaC p) 0))
        (exists ((mid EngineCoupling))
          (and (> (circuitWeight p src mid) 0)
               (> (circuitWeight p mid (mkEngineCoupling Pol_zero Pol_zero)) 0)))))))
(check-sat)
(pop)

; [21/41] veille_unreachable_when_eps_max
(echo "[THM] veille_unreachable_when_eps_max")
(push)
(assert (not
  (forall ((p CircuitKernelParams) (src EngineCoupling))
    (=> (and (validCircuitKernelParams p)
             (= (ckp_epsilon p) (ckp_scale p))
             (= (ckp_deltaA p) 0))
        (= (circuitWeight p src (mkEngineCoupling Pol_zero Pol_zero)) 0)))))
(check-sat)
(pop)

; [22/41] circularCycle_veille_fixed_point
(echo "[THM] circularCycle_veille_fixed_point")
(push)
(assert (not
  (and (= (circularCycle defaultCircularCircuitState) defaultCircularCircuitState)
       (= (op3_crossingI_point defaultCircularCircuitState) (mkPoint 0 0 0)))))
(check-sat)
(pop)

; [23/41] circularCycle_reduces_total_discrepancy
(echo "[THM] circularCycle_reduces_total_discrepancy")
(push)
(assert (not
  (forall ((s CircularCircuitState))
    (=> (and (validCircularCircuitState s)
             (= (bes_perturbation (ccs_bodyEnv s)) 0)
             (= (hss_revisable (ccs_subjectiveHidden s)) true)
             (= (hps_controllable (ccs_perceptiveHidden s)) true)
             (AttentionalInterface_isEngaged (ccs_attentional s))
             (= (ccs_resorptionThreshold s) 1)
             (> (+ (hss_modelDiscrepancy (ccs_subjectiveHidden s))
                   (hps_afferentDiscrepancy (ccs_perceptiveHidden s)))
                0))
        (< (+ (hss_modelDiscrepancy (ccs_subjectiveHidden (circularCycle s)))
              (hps_afferentDiscrepancy (ccs_perceptiveHidden (circularCycle s))))
           (+ (hss_modelDiscrepancy (ccs_subjectiveHidden s))
              (hps_afferentDiscrepancy (ccs_perceptiveHidden s))))))))
(check-sat)
(pop)

; [24/41] lyapunov_drift_charge_with_passive_extinction
(echo "[THM] lyapunov_drift_charge_with_passive_extinction")
(push)
(assert (not
  (forall ((p CircuitKernelParams))
    (=> (and (validCircuitKernelParams p)
             (= (ckp_epsilon p) 0) (= (ckp_chi p) 0))
        (= (weightedDriftSum p (mkEngineCoupling Pol_neg Pol_zero))
           (* 4 (pow5 (ckp_scale p)) (+ (ckp_rho p) (* 2 (ckp_deltaA p)))))))))
(check-sat)
(pop)

; [25/41] p1_without_p2_eps_independent
(echo "[THM] p1_without_p2_eps_independent")
(push)
(assert (not
  (forall ((m Int) (eps Int) (otherCharged Bool))
    (= (effectiveEpsScaled m eps 0 otherCharged) (* m eps)))))
(check-sat)
(pop)

; [26/41] epistemic_rigidity_traps_charge_slice
(echo "[THM] epistemic_rigidity_traps_charge_slice")
(push)
(assert (not
  (forall ((p CircuitKernelParams) (src EngineCoupling) (dst EngineCoupling))
    (=> (and (validCircuitKernelParams p)
             (= (ckp_rho p) 0) (= (ckp_deltaA p) 0)
             (= (ec_attente src) Pol_neg) (not (= (ec_attente dst) Pol_neg)))
        (= (circuitWeight p src dst) 0)))))
(check-sat)
(pop)

; [27/41] pragmatic_helplessness_traps_charge_slice
(echo "[THM] pragmatic_helplessness_traps_charge_slice")
(push)
(assert (not
  (forall ((p CircuitKernelParams) (src EngineCoupling) (dst EngineCoupling))
    (=> (and (validCircuitKernelParams p)
             (= (ckp_kappa p) 0) (= (ckp_deltaC p) 0)
             (= (ec_controle src) Pol_neg) (not (= (ec_controle dst) Pol_neg)))
        (= (circuitWeight p src dst) 0)))))
(check-sat)
(pop)

; [28/41] perseveration_traps_discharge_free
(echo "[THM] perseveration_traps_discharge_free")
(push)
(assert (not
  (forall ((p CircuitKernelParams) (src EngineCoupling) (dst EngineCoupling))
    (=> (and (validCircuitKernelParams p)
             (= (ckp_epsilon p) 0) (= (ckp_gammaA p) 0) (= (ckp_gammaC p) 0)
             (not (= (ec_attente src) Pol_neg))
             (not (= (ec_controle src) Pol_neg)))
        (= (circuitWeight p src dst)
           (ite (= dst src) (* 4 (pow6 (ckp_scale p))) 0))))))
(check-sat)
(pop)

; [29/41] passive_extinction_zero_relief
(echo "[THM] passive_extinction_zero_relief")
(push)
(assert (not
  (= (activeResolutionCount (mkEngineCoupling Pol_neg Pol_zero)
                            (mkEngineCoupling Pol_zero Pol_zero))
     0)))
(check-sat)
(pop)

; [30/41] active_resolution_beats_passive_extinction
(echo "[THM] active_resolution_beats_passive_extinction")
(push)
(assert (not
  (forall ((p UnifiedDynamicsParams) (r Int) (piA Int) (piC Int))
    (=> (and (validUnifiedDynamicsParams p)
             (>= r 0) (>= piA 0) (>= piC 0)
             (> (udp_etaScaled p) 0)
             (> (+ (div (* (udp_lambdaNum p) r) (* 2 (udp_halfScale p))) piA) 0))
        (< (nextChargeAccumulator p r piA piC
             (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_pos Pol_zero))
           (nextChargeAccumulator p r piA piC
             (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_zero Pol_zero)))))))
(check-sat)
(pop)

; [31/41] charge_accumulator_bounded
(echo "[THM] charge_accumulator_bounded")
(push)
(assert (not
  (forall ((p UnifiedDynamicsParams) (r Int) (piA Int) (piC Int)
           (src EngineCoupling) (dst EngineCoupling))
    (=> (and (validUnifiedDynamicsParams p)
             (>= r 0) (>= piA 0) (>= piC 0)
             (= (+ piA piC) (* 2 (udp_halfScale p)))
             (<= r (chargeAccumulatorBound p)))
        (<= (nextChargeAccumulator p r piA piC src dst)
            (chargeAccumulatorBound p))))))
(check-sat)
(pop)

; [32/41] nextStratumR5_le_zMax
(echo "[THM] nextStratumR5_le_zMax")
(push)
(assert (not
  (forall ((p UnifiedDynamicsParams) (z Int) (rNext Int))
    (=> (and (validUnifiedDynamicsParams p) (>= z 0) (>= rNext 0))
        (<= (nextStratumR5 p z rNext) (udp_zMax p))))))
(check-sat)
(pop)

; [33/41] nextStratumR5_short_circuits_z2_to_veille
(echo "[THM] nextStratumR5_short_circuits_z2_to_veille")
(push)
(assert (not
  (forall ((p UnifiedDynamicsParams) (rNext Int))
    (=> (and (validUnifiedDynamicsParams p) (>= rNext 0) (< rNext (thetaDown 2)))
        (= (nextStratumR5 p 2 rNext) 0)))))
(check-sat)
(pop)

; [34/41] nextStratumR5_from_ge2_never_visits_surprise
(echo "[THM] nextStratumR5_from_ge2_never_visits_surprise")
(push)
(assert (not
  (forall ((p UnifiedDynamicsParams) (z Int) (rNext Int))
    (=> (and (validUnifiedDynamicsParams p) (>= z 2) (>= rNext 0))
        (not (= (nextStratumR5 p z rNext) 1))))))
(check-sat)
(pop)

; [35/41] symmetricSigmoid_sum
(echo "[THM] symmetricSigmoid_sum")
(push)
(assert (not
  (forall ((halfScale Int) (k Int) (u Int))
    (=> (and (>= halfScale 0) (> k 0))
        (= (+ (pr_fst (symmetricSigmoid halfScale k u))
              (pr_snd (symmetricSigmoid halfScale k u)))
           (* 2 halfScale))))))
(check-sat)
(pop)

; [36/41] symmetricSigmoid_pos
(echo "[THM] symmetricSigmoid_pos")
(push)
(assert (not
  (forall ((halfScale Int) (k Int) (u Int))
    (=> (and (> halfScale 0) (> k 0))
        (and (> (pr_fst (symmetricSigmoid halfScale k u)) 0)
             (> (pr_snd (symmetricSigmoid halfScale k u)) 0))))))
(check-sat)
(pop)

; [37/41] symmetricSigmoid_neg
(echo "[THM] symmetricSigmoid_neg")
(push)
(assert (not
  (forall ((halfScale Int) (k Int) (u Int))
    (=> (and (>= halfScale 0) (> k 0))
        (= (symmetricSigmoid halfScale k (- u))
           (mkPair (pr_snd (symmetricSigmoid halfScale k u))
                   (pr_fst (symmetricSigmoid halfScale k u))))))))
(check-sat)
(pop)

; [38/41] precisionShare_double_charge_cancels_alpha
(echo "[THM] precisionShare_double_charge_cancels_alpha")
(push)
(assert (not
  (forall ((p UnifiedDynamicsParams) (rhoHat Int) (kappaHat Int))
    (= (precisionScore p rhoHat kappaHat (mkEngineCoupling Pol_neg Pol_neg))
       (* (udp_betaAtt p) (- rhoHat kappaHat))))))
(check-sat)
(pop)

; [39/41] projectUnifiedState_valid
(echo "[THM] projectUnifiedState_valid")
(push)
(assert (not
  (forall ((p UnifiedDynamicsParams) (c EngineCoupling) (z Int) (rhoHat Int) (kappaHat Int) (susp Bool))
    (=> (and (validUnifiedDynamicsParams p) (>= z 0) (>= rhoHat 0) (>= kappaHat 0))
        (isValidCoreAffect (projectUnifiedState p c z rhoHat kappaHat susp))))))
(check-sat)
(pop)

; [40/41] projectUnifiedState_crown_budget
(echo "[THM] projectUnifiedState_crown_budget")
(push)
(assert (not
  (forall ((p UnifiedDynamicsParams) (c EngineCoupling) (z Int) (rhoHat Int) (kappaHat Int) (susp Bool))
    (=> (and (validUnifiedDynamicsParams p)
             (>= z 2) (>= rhoHat 0) (>= kappaHat 0)
             (not (EngineCoupling_isGlobalNeutrality c)))
        (let ((pt (projectUnifiedState p c z rhoHat kappaHat susp)))
          (= (+ (intAbs (pt_x pt)) (intAbs (pt_y pt)))
             (spatialBudget z)))))))
(check-sat)
(pop)

; [41/41] projectUnifiedState_reaches_lateral_consternation
(echo "[THM] projectUnifiedState_reaches_lateral_consternation")
(push)
(assert (not
  (= (projectUnifiedState defaultUnifiedDynamicsParams (mkEngineCoupling Pol_neg Pol_pos) 3 10 90 true)
     (mkPoint (- 1) 3 3))))
(check-sat)
(pop)
