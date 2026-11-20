; =============================================================================
; Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
; SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
; Author: Manuel Cabelguen
;
; Module 08 : AuditTests (SMT-LIB 2.6 / Z3)
; Equivalence formelle directe avec Cartograffect/AuditTests.lean
; Couvre le 113e theoreme (all176Entries_antagonist_inverts_hedonic_polarity)
; ainsi que les 11 blocs d'evaluation concrete (#eval <-> Compute).
; =============================================================================
(set-logic ALL)
(set-option :produce-models true)

; -----------------------------------------------------------------------------
; 1. Types
; -----------------------------------------------------------------------------
(declare-datatypes ((Polarity 0)) (((Pol_neg) (Pol_zero) (Pol_pos))))
(declare-datatypes ((FunctionalRegime 0)) (((Reg_charge) (Reg_neutral) (Reg_discharge))))
(declare-datatypes ((SalientDiscrepancy 0))
  (((mkSalientDiscrepancy (sd_magnitude Int) (sd_sensoryThreshold Int) (sd_resorptionThreshold Int)))))
(declare-datatypes ((PerceptiveInterface 0))
  (((mkPerceptiveInterface (pi_controleGradient Polarity)))))
(declare-datatypes ((SubjectiveInterface 0))
  (((mkSubjectiveInterface (si_attenteGradient Polarity) (si_descendingSuspension Bool)))))
(declare-datatypes ((AttentionalInterface 0))
  (((mkAttentionalInterface (ai_allocatedPrecision Int) (ai_engagementThreshold Int)
      (ai_persistenceDepth Int) (ai_precisionA Int) (ai_precisionC Int)))))
(declare-datatypes ((EngineCoupling 0))
  (((mkEngineCoupling (ec_attente Polarity) (ec_controle Polarity)))))
(declare-datatypes ((PredictiveEngineState 0))
  (((mkPredictiveEngineState (pes_discrepancy SalientDiscrepancy) (pes_perceptive PerceptiveInterface)
      (pes_subjective SubjectiveInterface) (pes_attentional AttentionalInterface)))))
(declare-datatypes ((CoreAffectPoint 0))
  (((mkPoint (pt_x Int) (pt_y Int) (pt_z Int)))))
(declare-datatypes ((GeometryType 0))
  (((GT_central) (GT_axial) (GT_diagonal) (GT_lateral))))
(declare-datatypes ((LivedExpectationPole 0))
  (((LEP_epistemicCharge) (LEP_epistemicNeutral) (LEP_epistemicDischarge))))
(declare-datatypes ((LivedControlPole 0))
  (((LCP_pragmaticCharge) (LCP_pragmaticNeutral) (LCP_pragmaticDischarge))))
(declare-datatypes ((EnergyRegime 0))
  (((ER_neutralBasal) (ER_axialPure) (ER_positiveSynergy)
    (ER_negativeSynergy) (ER_ergotropicCompensation) (ER_trophotropicRelease))))
(declare-datatypes ((HedonicPolarity 0))
  (((Hed_positive) (Hed_negative) (Hed_neutral))))
(declare-datatypes ((PhenomenologicalActivation 0))
  (((PA_basalWakefulness) (PA_ascendingRupture) (PA_operatorSuspension)
    (PA_lowInhibition) (PA_epistemicVigilance) (PA_highMobilization))))
(declare-datatypes ((TaxonomicStratum 0))
  (((TS_z0_pointDeVeille) (TS_z1_saillancePerceptive) (TS_z2_affectsPrimaires)
    (TS_z3_emotionsReactives) (TS_z4_sentimentsReflexifs) (TS_z5_orientationsDurables)
    (TS_z6_identitesAffectives) (TS_z7_sentimentsTranscendants) (TS_zDeepProlongation (ts_depth Int)))))
(declare-datatypes ((TaxonomicGroup 0))
  (((TG_operateurCentral) (TG_groupeJoie) (TG_groupeTristesse) (TG_groupePeur)
    (TG_groupeCourage) (TG_groupeDesir) (TG_groupeDegout) (TG_groupeColere) (TG_groupeCalme))))
(declare-datatypes ((FunctionalSubsector 0))
  (((FS_centralOperator) (FS_axialElan) (FS_axialWithdrawal) (FS_axialOpening) (FS_axialThreat)
    (FS_diagonalDesire) (FS_diagonalDisgust) (FS_diagonalAnger) (FS_diagonalCalm)
    (FS_lateralApproachSynergy) (FS_lateralDefensiveUrgency) (FS_lateralTrophotropicPeace)
    (FS_lateralAversiveDistress) (FS_lateralEpistemicMastery) (FS_lateralContemplativeOpen)
    (FS_lateralVigilantAlert) (FS_lateralEpistemicClosure))))
(declare-datatypes ((IntPair 0)) (((mkPair (pr_fst Int) (pr_snd Int)))))
(declare-datatypes ((CircuitKernelParams 0))
  (((mkCircuitKernelParams (ckp_scale Int) (ckp_rho Int) (ckp_kappa Int)
      (ckp_deltaA Int) (ckp_deltaC Int) (ckp_gammaA Int) (ckp_gammaC Int)
      (ckp_epsilon Int) (ckp_qPosA Int) (ckp_qPosC Int) (ckp_chi Int)))))
(declare-datatypes ((UnifiedDynamicsParams 0))
  (((mkUnifiedDynamicsParams (udp_halfScale Int) (udp_lambdaNum Int) (udp_etaScaled Int)
      (udp_betaAtt Int) (udp_alphaCharge Int) (udp_sigmoidK Int) (udp_zMax Int)))))
(declare-datatypes ((HiddenSubjectiveState 0))
  (((mkHiddenSubjectiveState (hss_modelDiscrepancy Int) (hss_revisable Bool) (hss_descendingSuspension Bool)))))
(declare-datatypes ((HiddenPerceptiveState 0))
  (((mkHiddenPerceptiveState (hps_afferentDiscrepancy Int) (hps_controllable Bool)))))
(declare-datatypes ((BodyEnvironmentState 0))
  (((mkBodyEnvironmentState (bes_perturbation Int)))))
(declare-datatypes ((CircularCircuitState 0))
  (((mkCircularCircuitState (ccs_subjectiveHidden HiddenSubjectiveState)
      (ccs_perceptiveHidden HiddenPerceptiveState) (ccs_bodyEnv BodyEnvironmentState)
      (ccs_sensoryThreshold Int) (ccs_resorptionThreshold Int) (ccs_attentional AttentionalInterface)))))

(define-fun thetaUp ((z Int)) Int (+ 600 (* 200 z)))
(define-fun thetaDown ((z Int)) Int (+ 300 (* 200 z)))

; -----------------------------------------------------------------------------
; 2. Fonctions
; -----------------------------------------------------------------------------
(define-fun intAbs ((v Int)) Int (ite (>= v 0) v (- v)))
(define-fun minInt ((a Int) (b Int)) Int (ite (<= a b) a b))
(define-fun clampInt ((lo Int) (hi Int) (v Int)) Int (ite (< v lo) lo (ite (< hi v) hi v)))
(define-fun Polarity_isEngaged ((p Polarity)) Bool (not (= p Pol_zero)))
(define-fun EngineCoupling_isGlobalNeutrality ((c EngineCoupling)) Bool
  (and (not (Polarity_isEngaged (ec_attente c))) (not (Polarity_isEngaged (ec_controle c)))))
(define-fun SalientDiscrepancy_isSensorilySalient ((d SalientDiscrepancy)) Bool
  (<= (sd_sensoryThreshold d) (sd_magnitude d)))
(define-fun SalientDiscrepancy_isInRemanenceWindow ((d SalientDiscrepancy)) Bool
  (and (<= (sd_resorptionThreshold d) (sd_magnitude d)) (< (sd_magnitude d) (sd_sensoryThreshold d))))
(define-fun AttentionalInterface_isEngaged ((att AttentionalInterface)) Bool
  (<= (ai_engagementThreshold att) (ai_allocatedPrecision att)))
(define-fun PredictiveEngineState_currentCoupling ((s PredictiveEngineState)) EngineCoupling
  (mkEngineCoupling (si_attenteGradient (pes_subjective s)) (pi_controleGradient (pes_perceptive s))))

(define-fun engineStep ((s PredictiveEngineState)) PredictiveEngineState
  (let ((c (PredictiveEngineState_currentCoupling s)))
    (ite (not (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s)))
      (ite (SalientDiscrepancy_isInRemanenceWindow (pes_discrepancy s)) s
        (mkPredictiveEngineState (pes_discrepancy s) (mkPerceptiveInterface Pol_zero)
          (mkSubjectiveInterface Pol_zero false)
          (mkAttentionalInterface 0 (ai_engagementThreshold (pes_attentional s)) 0
            (ai_precisionA (pes_attentional s)) (ai_precisionC (pes_attentional s)))))
      (ite (EngineCoupling_isGlobalNeutrality c)
        (mkPredictiveEngineState (pes_discrepancy s) (mkPerceptiveInterface Pol_pos)
          (pes_subjective s) (pes_attentional s))
        (ite (and (not (si_descendingSuspension (pes_subjective s)))
                  (not (AttentionalInterface_isEngaged (pes_attentional s))))
          (mkPredictiveEngineState (pes_discrepancy s) (pes_perceptive s)
            (mkSubjectiveInterface (si_attenteGradient (pes_subjective s)) true) (pes_attentional s))
          (ite (not (AttentionalInterface_isEngaged (pes_attentional s)))
            (mkPredictiveEngineState (pes_discrepancy s) (pes_perceptive s) (pes_subjective s)
              (mkAttentionalInterface (ai_engagementThreshold (pes_attentional s))
                (ai_engagementThreshold (pes_attentional s)) (ai_persistenceDepth (pes_attentional s))
                (ai_precisionA (pes_attentional s)) (ai_precisionC (pes_attentional s))))
            s))))))

(define-fun crownRadius ((z Int)) Int (ite (< z 2) 0 (- (* 2 z) 2)))
(define-fun isValidCoreAffect ((p CoreAffectPoint)) Bool
  (and (>= (pt_z p) 0)
       (or (and (= (pt_x p) 0) (= (pt_y p) 0))
           (and (>= (pt_z p) 2) (= (+ (intAbs (pt_x p)) (intAbs (pt_y p))) (crownRadius (pt_z p)))))))
(define-fun signedAmplitude ((pol Polarity) (amp Int)) Int
  (ite (= pol Pol_neg) (- amp) (ite (= pol Pol_zero) 0 amp)))
(define-fun apportionRayX ((d Int) (piA Int) (piC Int)) Int
  (let ((r (+ (* 2 d) 2)))
    (ite (= piA piC) (+ d 1)
      (let ((tot (+ piA piC)))
        (ite (< piA piC)
          (clampInt 1 (+ d 1) (div (+ (* 2 r piA) tot) (* 2 tot)))
          (- r (clampInt 1 (+ d 1) (div (+ (* 2 r piC) tot) (* 2 tot)))))))))
(define-fun apportionRayY ((d Int) (piA Int) (piC Int)) Int
  (- (+ (* 2 d) 2) (apportionRayX d piA piC)))
(define-fun deployCouplingWithPrecision ((c EngineCoupling) (d Int) (piA Int) (piC Int)) CoreAffectPoint
  (let ((z (+ d 2)) (r (+ (* 2 d) 2)) (a (ec_attente c)) (ctrl (ec_controle c)))
    (ite (and (= a Pol_zero) (= ctrl Pol_zero)) (mkPoint 0 0 0)
    (ite (= ctrl Pol_zero) (mkPoint (signedAmplitude a r) 0 z)
    (ite (= a Pol_zero) (mkPoint 0 (signedAmplitude ctrl r) z)
    (mkPoint (signedAmplitude a (apportionRayX d piA piC))
             (signedAmplitude ctrl (apportionRayY d piA piC)) z))))))
(define-fun projectToCoreAffect ((s PredictiveEngineState)) CoreAffectPoint
  (let ((c (PredictiveEngineState_currentCoupling s)))
    (ite (or (not (SalientDiscrepancy_isSensorilySalient (pes_discrepancy s)))
             (EngineCoupling_isGlobalNeutrality c))
      (ite (si_descendingSuspension (pes_subjective s))
        (mkPoint 0 0 (+ (ai_persistenceDepth (pes_attentional s)) 2)) (mkPoint 0 0 0))
      (ite (not (AttentionalInterface_isEngaged (pes_attentional s)))
        (ite (si_descendingSuspension (pes_subjective s))
          (mkPoint 0 0 (+ (ai_persistenceDepth (pes_attentional s)) 2)) (mkPoint 0 0 1))
        (deployCouplingWithPrecision c (ai_persistenceDepth (pes_attentional s))
          (ai_precisionA (pes_attentional s)) (ai_precisionC (pes_attentional s)))))))

(define-fun dissipationStep ((p CoreAffectPoint)) CoreAffectPoint
  (ite (or (not (= (pt_x p) 0)) (not (= (pt_y p) 0))) (mkPoint 0 0 (pt_z p))
    (ite (<= (pt_z p) 2) (mkPoint 0 0 0) (mkPoint 0 0 (- (pt_z p) 1)))))
(define-fun dissipationPotential ((p CoreAffectPoint)) Int
  (+ (* 2 (pt_z p)) (ite (or (not (= (pt_x p) 0)) (not (= (pt_y p) 0))) 1 0)))

(define-fun HedonicPolarity_invert ((p HedonicPolarity)) HedonicPolarity
  (ite (= p Hed_positive) Hed_negative (ite (= p Hed_negative) Hed_positive Hed_neutral)))
(define-fun computeHedonicPolarity ((x Int) (y Int)) HedonicPolarity
  (ite (> x 0) Hed_positive (ite (< x 0) Hed_negative
  (ite (> y 0) Hed_positive (ite (< y 0) Hed_negative Hed_neutral)))))
(define-fun computeEnergyRegime ((x Int) (y Int)) EnergyRegime
  (ite (and (= x 0) (= y 0)) ER_neutralBasal
  (ite (or (= x 0) (= y 0)) ER_axialPure
  (ite (and (> x 0) (> y 0)) ER_positiveSynergy
  (ite (and (< x 0) (< y 0)) ER_negativeSynergy
  (ite (and (< x 0) (> y 0)) ER_ergotropicCompensation ER_trophotropicRelease))))))
(define-fun computeActivation ((p CoreAffectPoint)) PhenomenologicalActivation
  (ite (and (= (pt_x p) 0) (= (pt_y p) 0))
    (ite (= (pt_z p) 0) PA_basalWakefulness (ite (= (pt_z p) 1) PA_ascendingRupture PA_operatorSuspension))
  (ite (> (pt_y p) 0) PA_highMobilization (ite (< (pt_y p) 0) PA_lowInhibition PA_epistemicVigilance))))
(define-fun antagonistPoint ((p CoreAffectPoint)) CoreAffectPoint
  (let ((x (pt_x p)) (y (pt_y p)) (z (pt_z p)))
    (ite (or (= x 0) (= y 0) (= (intAbs x) (intAbs y))) (mkPoint (- x) (- y) z)
      (ite (or (and (> x 0) (< y 0)) (and (< x 0) (> y 0))) (mkPoint y x z) (mkPoint (- y) (- x) z)))))

(define-fun CoreAffectPoint_classifyGeometry ((p CoreAffectPoint)) GeometryType
  (ite (and (= (pt_x p) 0) (= (pt_y p) 0)) GT_central
  (ite (or (= (pt_x p) 0) (= (pt_y p) 0)) GT_axial
  (ite (= (intAbs (pt_x p)) (intAbs (pt_y p))) GT_diagonal GT_lateral))))
(define-fun classifyStratum ((z Int)) TaxonomicStratum
  (ite (= z 0) TS_z0_pointDeVeille (ite (= z 1) TS_z1_saillancePerceptive
  (ite (= z 2) TS_z2_affectsPrimaires (ite (= z 3) TS_z3_emotionsReactives
  (ite (= z 4) TS_z4_sentimentsReflexifs (ite (= z 5) TS_z5_orientationsDurables
  (ite (= z 6) TS_z6_identitesAffectives (ite (= z 7) TS_z7_sentimentsTranscendants
  (TS_zDeepProlongation z))))))))))
(define-fun classifyTaxonomicGroup ((p CoreAffectPoint)) TaxonomicGroup
  (let ((x (pt_x p)) (y (pt_y p)))
    (ite (and (= x 0) (= y 0)) TG_operateurCentral
    (ite (> (intAbs y) (intAbs x)) (ite (> y 0) TG_groupeJoie TG_groupeTristesse)
    (ite (> (intAbs x) (intAbs y)) (ite (< x 0) TG_groupePeur TG_groupeCourage)
    (ite (> x 0) (ite (> y 0) TG_groupeDesir TG_groupeCalme)
    (ite (> y 0) TG_groupeColere TG_groupeDegout)))))))
(define-fun classifySubsector ((x Int) (y Int)) FunctionalSubsector
  (ite (and (= x 0) (= y 0)) FS_centralOperator
  (ite (and (= x 0) (> y 0)) FS_axialElan
  (ite (and (= x 0) (< y 0)) FS_axialWithdrawal
  (ite (and (> x 0) (= y 0)) FS_axialOpening
  (ite (and (< x 0) (= y 0)) FS_axialThreat
  (ite (and (= x y) (> x 0)) FS_diagonalDesire
  (ite (and (= x y) (< x 0)) FS_diagonalDisgust
  (ite (and (= x (- y)) (< x 0)) FS_diagonalAnger
  (ite (and (= x (- y)) (> x 0)) FS_diagonalCalm
  (ite (and (> y (intAbs x)) (> x 0)) FS_lateralApproachSynergy
  (ite (and (> y (intAbs x)) (< x 0)) FS_lateralDefensiveUrgency
  (ite (and (> (- y) (intAbs x)) (> x 0)) FS_lateralTrophotropicPeace
  (ite (and (> (- y) (intAbs x)) (< x 0)) FS_lateralAversiveDistress
  (ite (and (> x (intAbs y)) (> y 0)) FS_lateralEpistemicMastery
  (ite (and (> x (intAbs y)) (< y 0)) FS_lateralContemplativeOpen
  (ite (and (> (- x) (intAbs y)) (> y 0)) FS_lateralVigilantAlert
  FS_lateralEpistemicClosure)))))))))))))))))

(define-fun canonicalDepthWeight ((p CoreAffectPoint) (q CoreAffectPoint)) Int
  (let ((px (pt_x p)) (py (pt_y p)) (pz (pt_z p)) (qx (pt_x q)) (qy (pt_y q)) (qz (pt_z q)))
    (ite (and (isValidCoreAffect p) (isValidCoreAffect q) (= qz (+ pz 1)) (>= (* px qx) 0) (>= (* py qy) 0))
      (ite (and (= qx 0) (= qy 0)) (ite (and (= px 0) (= py 0)) 1 0)
        (ite (and (= px 0) (= py 0)) (ite (= pz 1) 1 0)
          (ite (or (= px 0) (= py 0))
            (ite (and (or (= px 0) (not (= qx 0))) (or (= py 0) (not (= qy 0))))
              (ite (or (= qx 0) (= qy 0)) 1 (ite (= (intAbs qx) (intAbs qy)) 2 0)) 0)
            (ite (and (not (= qx 0)) (not (= qy 0)) (>= (intAbs qx) (intAbs px)) (>= (intAbs qy) (intAbs py)))
              (ite (and (= (intAbs px) (intAbs py)) (= (intAbs qx) (intAbs qy))) 2 1) 0)))) 0)))

(define-fun sumCrownRowAtAx ((p CoreAffectPoint) (znext Int) (ax Int) (ay Int)) Int
  (ite (= ax 0) (+ (canonicalDepthWeight p (mkPoint 0 ay znext)) (canonicalDepthWeight p (mkPoint 0 (- ay) znext)))
    (ite (= ay 0) (+ (canonicalDepthWeight p (mkPoint ax 0 znext)) (canonicalDepthWeight p (mkPoint (- ax) 0 znext)))
      (+ (canonicalDepthWeight p (mkPoint ax ay znext)) (canonicalDepthWeight p (mkPoint ax (- ay) znext))
         (canonicalDepthWeight p (mkPoint (- ax) ay znext)) (canonicalDepthWeight p (mkPoint (- ax) (- ay) znext))))))
(define-fun-rec sumCrownWeightsRec ((p CoreAffectPoint) (znext Int) (r Int) (ax Int)) Int
  (ite (< ax 0) 0 (+ (sumCrownRowAtAx p znext ax (- r ax)) (sumCrownWeightsRec p znext r (- ax 1)))))
(define-fun outgoingWeight ((p CoreAffectPoint)) Int
  (let ((zn (+ (pt_z p) 1)))
    (+ (canonicalDepthWeight p (mkPoint 0 0 zn))
       (ite (< zn 2) 0 (sumCrownWeightsRec p zn (crownRadius zn) (crownRadius zn))))))

(define-fun attractorMembership ((p CoreAffectPoint) (g TaxonomicGroup)) Int
  (let ((px (pt_x p)) (py (pt_y p)))
    (let ((ax (intAbs px)) (ay (intAbs py)))
      (let ((r (+ ax ay)) (m (ite (<= ax ay) ax ay)))
        (ite (= g TG_operateurCentral) (ite (and (= px 0) (= py 0)) 1 0)
        (ite (= g TG_groupeJoie)       (ite (> py 0) (ite (> ay ax) r ay) 0)
        (ite (= g TG_groupeTristesse)  (ite (< py 0) (ite (> ay ax) r ay) 0)
        (ite (= g TG_groupeCourage)    (ite (> px 0) (ite (> ax ay) r ax) 0)
        (ite (= g TG_groupePeur)       (ite (< px 0) (ite (> ax ay) r ax) 0)
        (ite (= g TG_groupeDesir)      (ite (and (> px 0) (> py 0)) (* 2 m) 0)
        (ite (= g TG_groupeDegout)     (ite (and (< px 0) (< py 0)) (* 2 m) 0)
        (ite (= g TG_groupeColere)     (ite (and (< px 0) (> py 0)) (* 2 m) 0)
        (ite (and (> px 0) (< py 0)) (* 2 m) 0)))))))))))))

(define-fun phiL1 ((c EngineCoupling)) IntPair
  (let ((a (ec_attente c)) (ctrl (ec_controle c)))
    (ite (and (= a Pol_zero) (= ctrl Pol_zero)) (mkPair 0 0)
    (ite (and (= a Pol_pos)  (= ctrl Pol_zero)) (mkPair 2 0)
    (ite (and (= a Pol_neg)  (= ctrl Pol_zero)) (mkPair (- 2) 0)
    (ite (and (= a Pol_zero) (= ctrl Pol_pos))  (mkPair 0 2)
    (ite (and (= a Pol_zero) (= ctrl Pol_neg))  (mkPair 0 (- 2))
    (ite (and (= a Pol_pos)  (= ctrl Pol_pos))  (mkPair 1 1)
    (ite (and (= a Pol_pos)  (= ctrl Pol_neg))  (mkPair 1 (- 1))
    (ite (and (= a Pol_neg)  (= ctrl Pol_pos))  (mkPair (- 1) 1)
    (mkPair (- 1) (- 1))))))))))))
(define-fun idxAttente ((p Polarity)) Int (ite (= p Pol_zero) 0 (ite (= p Pol_neg) 1 2)))
(define-fun idxControle ((p Polarity)) Int (ite (= p Pol_pos) 0 (ite (= p Pol_neg) 1 2)))
(define-fun crossingIPos ((c EngineCoupling)) IntPair (mkPair (idxAttente (ec_attente c)) (idxControle (ec_controle c))))
(define-fun crossingIIPos ((c EngineCoupling)) IntPair (mkPair (idxControle (ec_controle c)) (idxAttente (ec_attente c))))
(define-fun projectPerceptible ((c EngineCoupling) (z Int) (piA Int) (piC Int) (susp Bool)) CoreAffectPoint
  (ite (EngineCoupling_isGlobalNeutrality c)
    (ite (and susp (>= z 2)) (mkPoint 0 0 z) (mkPoint 0 0 0))
    (ite (= z 0) (mkPoint 0 0 0) (ite (= z 1) (mkPoint 0 0 1)
      (deployCouplingWithPrecision c (- z 2) piA piC)))))
(define-fun attentionalWeightX2 ((c EngineCoupling)) Int (ite (= (ec_attente c) Pol_zero) 2 (intAbs (pr_fst (phiL1 c)))))
(define-fun attentionalWeightY2 ((c EngineCoupling)) Int (ite (= (ec_controle c) Pol_zero) 2 (intAbs (pr_snd (phiL1 c)))))
(define-fun isCharged ((p Polarity)) Bool (= p Pol_neg))
(define-fun effectiveEpsScaled ((m Int) (eps Int) (chi Int) (otherCharged Bool)) Int
  (ite otherCharged (+ (* m eps) (* chi (- m eps))) (* m eps)))
(define-fun marginalWeight ((m Int) (rate Int) (delta Int) (deseng Int) (eps Int) (qPos Int) (chi Int)
    (otherCharged Bool) (w2 Int) (src Polarity) (dst Polarity)) Int
  (let ((e2 (effectiveEpsScaled m eps chi otherCharged)))
    (ite (= src Pol_zero)
      (ite (= dst Pol_zero) (* 2 m (- (* m m) e2)) (ite (= dst Pol_neg) (* 2 e2 (- m qPos)) (* 2 e2 qPos)))
    (ite (= src Pol_neg)
      (ite (= dst Pol_zero) (* m m (* 2 delta)) (ite (= dst Pol_neg) (* m m (- (* 2 m) (* w2 rate) (* 2 delta))) (* m m (* w2 rate))))
      (ite (= dst Pol_zero) (* (- (* m m) e2) (* w2 deseng)) (ite (= dst Pol_neg) (* 2 m e2) (* (- (* m m) e2) (- (* 2 m) (* w2 deseng)))))))))
(define-fun circuitWeight ((p CircuitKernelParams) (src EngineCoupling) (dst EngineCoupling)) Int
  (* (marginalWeight (ckp_scale p) (ckp_rho p) (ckp_deltaA p) (ckp_gammaA p) (ckp_epsilon p) (ckp_qPosA p) (ckp_chi p)
                     (isCharged (ec_controle src)) (attentionalWeightX2 src) (ec_attente src) (ec_attente dst))
     (marginalWeight (ckp_scale p) (ckp_kappa p) (ckp_deltaC p) (ckp_gammaC p) (ckp_epsilon p) (ckp_qPosC p) (ckp_chi p)
                     (isCharged (ec_attente src)) (attentionalWeightY2 src) (ec_controle src) (ec_controle dst))))
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
(define-fun defaultCircuitKernelParams () CircuitKernelParams
  (mkCircuitKernelParams 100 80 80 0 0 70 70 15 35 35 25))
(define-fun defaultCircularCircuitState () CircularCircuitState
  (mkCircularCircuitState (mkHiddenSubjectiveState 0 true false) (mkHiddenPerceptiveState 0 true)
    (mkBodyEnvironmentState 0) 1 1 (mkAttentionalInterface 0 0 0 1 1)))
(define-fun op1_subjectiveOut ((s CircularCircuitState)) Polarity
  (ite (< (hss_modelDiscrepancy (ccs_subjectiveHidden s)) (ccs_resorptionThreshold s)) Pol_zero
  (ite (hss_revisable (ccs_subjectiveHidden s)) Pol_pos Pol_neg)))
(define-fun op2_perceptiveOut ((s CircularCircuitState)) Polarity
  (ite (< (hps_afferentDiscrepancy (ccs_perceptiveHidden s)) (ccs_resorptionThreshold s)) Pol_zero
  (ite (hps_controllable (ccs_perceptiveHidden s)) Pol_pos Pol_neg)))
(define-fun op3_crossingI_point ((s CircularCircuitState)) CoreAffectPoint
  (let ((c (mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s)))
        (att (ccs_attentional s)) (susp (hss_descendingSuspension (ccs_subjectiveHidden s))))
    (let ((z (ite (EngineCoupling_isGlobalNeutrality c) (ite susp (+ (ai_persistenceDepth att) 2) 0)
               (ite (not (AttentionalInterface_isEngaged att)) (ite susp (+ (ai_persistenceDepth att) 2) 1)
                 (+ (ai_persistenceDepth att) 2)))))
      (projectPerceptible c z (ai_precisionA att) (ai_precisionC att) susp))))
(define-fun defaultUnifiedDynamicsParams () UnifiedDynamicsParams
  (mkUnifiedDynamicsParams 500 800 600 2 50 100 7))
(define-fun activeResolutionCount ((src EngineCoupling) (dst EngineCoupling)) Int
  (+ (ite (and (= (ec_attente src) Pol_neg) (= (ec_attente dst) Pol_pos)) 1 0)
     (ite (and (= (ec_controle src) Pol_neg) (= (ec_controle dst) Pol_pos)) 1 0)))
(define-fun nextChargeAccumulator ((p UnifiedDynamicsParams) (r Int) (piA Int) (piC Int)
    (src EngineCoupling) (dst EngineCoupling)) Int
  (let ((s (* 2 (udp_halfScale p)))
        (ca (ite (= (ec_attente src) Pol_neg) piA 0)) (cc (ite (= (ec_controle src) Pol_neg) piC 0))
        (rel (* (udp_etaScaled p) (activeResolutionCount src dst))))
    (let ((raw (- (+ (div (* (udp_lambdaNum p) r) s) ca cc) rel)))
      (ite (>= raw 0) raw 0))))
(define-fun nextStratumR5 ((p UnifiedDynamicsParams) (z Int) (rNext Int)) Int
  (ite (> rNext (thetaUp z)) (minInt (udp_zMax p) (+ z 1))
    (ite (< rNext (thetaDown z)) (ite (<= z 2) 0 (minInt (udp_zMax p) (- z 1)))
      (minInt (udp_zMax p) z))))
(define-fun symmetricSigmoid ((halfScale Int) (k Int) (u Int)) IntPair
  (let ((shift (div (* halfScale (intAbs u)) (+ (intAbs u) k))))
    (ite (>= u 0) (mkPair (+ halfScale shift) (- halfScale shift)) (mkPair (- halfScale shift) (+ halfScale shift)))))
(define-fun chargeIndicatorInt ((pol Polarity)) Int (ite (= pol Pol_neg) 1 0))
(define-fun precisionScore ((p UnifiedDynamicsParams) (rhoHat Int) (kappaHat Int) (c EngineCoupling)) Int
  (* (udp_betaAtt p) (+ (- rhoHat kappaHat)
     (* (udp_alphaCharge p) (- (chargeIndicatorInt (ec_attente c)) (chargeIndicatorInt (ec_controle c)))))))
(define-fun precisionShares ((p UnifiedDynamicsParams) (rhoHat Int) (kappaHat Int) (c EngineCoupling)) IntPair
  (symmetricSigmoid (udp_halfScale p) (udp_sigmoidK p) (precisionScore p rhoHat kappaHat c)))
(define-fun projectUnifiedState ((p UnifiedDynamicsParams) (c EngineCoupling) (z Int)
    (rhoHat Int) (kappaHat Int) (susp Bool)) CoreAffectPoint
  (let ((sh (precisionShares p rhoHat kappaHat c)))
    (projectPerceptible c z (pr_fst sh) (pr_snd sh) susp)))

; -----------------------------------------------------------------------------
; Repertoire des 176 points + Etats tests
; -----------------------------------------------------------------------------
(define-fun lexiconPoint ((i Int)) CoreAffectPoint
  (ite (= i 0) (mkPoint 0 0 0) ; Point de Veille
  (ite (= i 1) (mkPoint 0 0 1) ; Surprise
  (ite (= i 2) (mkPoint 0 0 2) ; Anticipation
  (ite (= i 3) (mkPoint 0 2 2) ; Joie
  (ite (= i 4) (mkPoint 0 -2 2) ; Tristesse
  (ite (= i 5) (mkPoint -2 0 2) ; Peur
  (ite (= i 6) (mkPoint 2 0 2) ; Courage
  (ite (= i 7) (mkPoint -1 1 2) ; Colère
  (ite (= i 8) (mkPoint 1 -1 2) ; Calme
  (ite (= i 9) (mkPoint 1 1 2) ; Désir
  (ite (= i 10) (mkPoint -1 -1 2) ; Dégoût
  (ite (= i 11) (mkPoint 0 0 3) ; Émoi
  (ite (= i 12) (mkPoint 0 4 3) ; Enthousiasme
  (ite (= i 13) (mkPoint 0 -4 3) ; Ennui
  (ite (= i 14) (mkPoint -4 0 3) ; Crainte
  (ite (= i 15) (mkPoint 4 0 3) ; Curiosité
  (ite (= i 16) (mkPoint -1 3 3) ; Consternation
  (ite (= i 17) (mkPoint 1 3 3) ; Euphorie
  (ite (= i 18) (mkPoint 1 -3 3) ; Soulagement
  (ite (= i 19) (mkPoint -1 -3 3) ; Chagrin
  (ite (= i 20) (mkPoint -3 1 3) ; Panique
  (ite (= i 21) (mkPoint -3 -1 3) ; Effroi
  (ite (= i 22) (mkPoint 3 -1 3) ; Émerveillement
  (ite (= i 23) (mkPoint 3 1 3) ; Aplomb
  (ite (= i 24) (mkPoint -2 2 3) ; Exaspération
  (ite (= i 25) (mkPoint 2 -2 3) ; Détente
  (ite (= i 26) (mkPoint 2 2 3) ; Attrait
  (ite (= i 27) (mkPoint -2 -2 3) ; Retrait
  (ite (= i 28) (mkPoint 0 0 4) ; Réserve
  (ite (= i 29) (mkPoint 0 6 4) ; Exaltation
  (ite (= i 30) (mkPoint 0 -6 4) ; Langueur
  (ite (= i 31) (mkPoint -6 0 4) ; Doute
  (ite (= i 32) (mkPoint 6 0 4) ; Assurance
  (ite (= i 33) (mkPoint -2 4 4) ; Envie
  (ite (= i 34) (mkPoint -1 5 4) ; Haine
  (ite (= i 35) (mkPoint 1 5 4) ; Amour
  (ite (= i 36) (mkPoint 2 4 4) ; Ferveur
  (ite (= i 37) (mkPoint 2 -4 4) ; Sérénité
  (ite (= i 38) (mkPoint 1 -5 4) ; Plénitude
  (ite (= i 39) (mkPoint -2 -4 4) ; Honte
  (ite (= i 40) (mkPoint -1 -5 4) ; Vide
  (ite (= i 41) (mkPoint -4 2 4) ; Anxiété
  (ite (= i 42) (mkPoint -5 1 4) ; Manque
  (ite (= i 43) (mkPoint -5 -1 4) ; Mépris
  (ite (= i 44) (mkPoint -4 -2 4) ; Défiance
  (ite (= i 45) (mkPoint 4 2 4) ; Fierté
  (ite (= i 46) (mkPoint 5 1 4) ; Épanouissement
  (ite (= i 47) (mkPoint 5 -1 4) ; Affection
  (ite (= i 48) (mkPoint 4 -2 4) ; Admiration
  (ite (= i 49) (mkPoint -3 3 4) ; Frustration
  (ite (= i 50) (mkPoint 3 -3 4) ; Acceptation
  (ite (= i 51) (mkPoint 3 3 4) ; Estime
  (ite (= i 52) (mkPoint -3 -3 4) ; Rejet
  (ite (= i 53) (mkPoint 0 0 5) ; Recul
  (ite (= i 54) (mkPoint 0 8 5) ; Puissance
  (ite (= i 55) (mkPoint 0 -8 5) ; Impuissance
  (ite (= i 56) (mkPoint -8 0 5) ; Méfiance
  (ite (= i 57) (mkPoint 8 0 5) ; Confiance
  (ite (= i 58) (mkPoint 1 7 5) ; Invulnérabilité
  (ite (= i 59) (mkPoint 2 6 5) ; Attachement
  (ite (= i 60) (mkPoint 3 5 5) ; Engagement
  (ite (= i 61) (mkPoint -2 6 5) ; Désenchantement
  (ite (= i 62) (mkPoint -3 5 5) ; Intolérance
  (ite (= i 63) (mkPoint -1 7 5) ; Injustice
  (ite (= i 64) (mkPoint 3 -5 5) ; Quiétude
  (ite (= i 65) (mkPoint 2 -6 5) ; Sécurité
  (ite (= i 66) (mkPoint 1 -7 5) ; Patience
  (ite (= i 67) (mkPoint -2 -6 5) ; Pessimisme
  (ite (= i 68) (mkPoint -3 -5 5) ; Fermeture
  (ite (= i 69) (mkPoint -1 -7 5) ; Désespoir
  (ite (= i 70) (mkPoint -6 2 5) ; Insécurité
  (ite (= i 71) (mkPoint -5 3 5) ; Inquiétude
  (ite (= i 72) (mkPoint -7 1 5) ; Impatience
  (ite (= i 73) (mkPoint -7 -1 5) ; Vulnérabilité
  (ite (= i 74) (mkPoint -6 -2 5) ; Détachement
  (ite (= i 75) (mkPoint -5 -3 5) ; Désengagement
  (ite (= i 76) (mkPoint 6 2 5) ; Optimisme
  (ite (= i 77) (mkPoint 5 3 5) ; Ouverture
  (ite (= i 78) (mkPoint 7 1 5) ; Espoir
  (ite (= i 79) (mkPoint 6 -2 5) ; Enchantement
  (ite (= i 80) (mkPoint 5 -3 5) ; Tolérance
  (ite (= i 81) (mkPoint 7 -1 5) ; Justice
  (ite (= i 82) (mkPoint -4 4 5) ; Insatisfaction
  (ite (= i 83) (mkPoint 4 -4 5) ; Satisfaction
  (ite (= i 84) (mkPoint 4 4 5) ; Intérêt
  (ite (= i 85) (mkPoint -4 -4 5) ; Désintérêt
  (ite (= i 86) (mkPoint 0 0 6) ; Saisissement
  (ite (= i 87) (mkPoint 0 10 6) ; Élan
  (ite (= i 88) (mkPoint 0 -10 6) ; Inertie
  (ite (= i 89) (mkPoint -10 0 6) ; Effacement
  (ite (= i 90) (mkPoint 10 0 6) ; Affirmation
  (ite (= i 91) (mkPoint 3 7 6) ; Ardeur
  (ite (= i 92) (mkPoint -3 7 6) ; Angoisse
  (ite (= i 93) (mkPoint 4 6 6) ; Allégresse
  (ite (= i 94) (mkPoint -4 6 6) ; Fureur
  (ite (= i 95) (mkPoint 2 8 6) ; Fougue
  (ite (= i 96) (mkPoint -2 8 6) ; Frénésie
  (ite (= i 97) (mkPoint 1 9 6) ; Jubilation
  (ite (= i 98) (mkPoint -1 9 6) ; Terreur
  (ite (= i 99) (mkPoint 3 -7 6) ; Béatitude
  (ite (= i 100) (mkPoint -3 -7 6) ; Accablement
  (ite (= i 101) (mkPoint 4 -6 6) ; Apaisement
  (ite (= i 102) (mkPoint -4 -6 6) ; Morosité
  (ite (= i 103) (mkPoint 2 -8 6) ; Contemplation
  (ite (= i 104) (mkPoint -2 -8 6) ; Prostration
  (ite (= i 105) (mkPoint 1 -9 6) ; Félicité
  (ite (= i 106) (mkPoint -1 -9 6) ; Désolation
  (ite (= i 107) (mkPoint -6 4 6) ; Rancœur
  (ite (= i 108) (mkPoint -6 -4 6) ; Amertume
  (ite (= i 109) (mkPoint -7 3 6) ; Affolement
  (ite (= i 110) (mkPoint -7 -3 6) ; Écrasement
  (ite (= i 111) (mkPoint -8 2 6) ; Fébrilité
  (ite (= i 112) (mkPoint -8 -2 6) ; Anéantissement
  (ite (= i 113) (mkPoint -9 1 6) ; Désarroi
  (ite (= i 114) (mkPoint -9 -1 6) ; Lassitude
  (ite (= i 115) (mkPoint 6 4 6) ; Entrain
  (ite (= i 116) (mkPoint 6 -4 6) ; Placidité
  (ite (= i 117) (mkPoint 7 3 6) ; Liesse
  (ite (= i 118) (mkPoint 7 -3 6) ; Limpidité
  (ite (= i 119) (mkPoint 8 2 6) ; Extase
  (ite (= i 120) (mkPoint 8 -2 6) ; Équanimité
  (ite (= i 121) (mkPoint 9 1 6) ; Exultation
  (ite (= i 122) (mkPoint 9 -1 6) ; Harmonie
  (ite (= i 123) (mkPoint -5 5 6) ; Tourment
  (ite (= i 124) (mkPoint 5 -5 6) ; Ataraxie
  (ite (= i 125) (mkPoint 5 5 6) ; Triomphe
  (ite (= i 126) (mkPoint -5 -5 6) ; Abattement
  (ite (= i 127) (mkPoint 0 0 7) ; Suspension
  (ite (= i 128) (mkPoint 0 12 7) ; Infini
  (ite (= i 129) (mkPoint 0 -12 7) ; Néant
  (ite (= i 130) (mkPoint -12 0 7) ; Déréliction
  (ite (= i 131) (mkPoint 12 0 7) ; Communion
  (ite (= i 132) (mkPoint 2 10 7) ; Transcendance
  (ite (= i 133) (mkPoint -2 10 7) ; Déchirement
  (ite (= i 134) (mkPoint 4 8 7) ; Exubérance
  (ite (= i 135) (mkPoint -4 8 7) ; Horreur
  (ite (= i 136) (mkPoint 1 11 7) ; Renaissance
  (ite (= i 137) (mkPoint -1 11 7) ; Vertige
  (ite (= i 138) (mkPoint 3 9 7) ; Élévation
  (ite (= i 139) (mkPoint -3 9 7) ; Détresse
  (ite (= i 140) (mkPoint 5 7 7) ; Enivrement
  (ite (= i 141) (mkPoint -5 7 7) ; Révolte
  (ite (= i 142) (mkPoint 2 -10 7) ; Nirvana
  (ite (= i 143) (mkPoint -2 -10 7) ; Perdition
  (ite (= i 144) (mkPoint 4 -8 7) ; Paix
  (ite (= i 145) (mkPoint -4 -8 7) ; Oppression
  (ite (= i 146) (mkPoint 1 -11 7) ; Pérennité
  (ite (= i 147) (mkPoint -1 -11 7) ; Abîme
  (ite (= i 148) (mkPoint 3 -9 7) ; Abandon
  (ite (= i 149) (mkPoint -3 -9 7) ; Damnation
  (ite (= i 150) (mkPoint 5 -7 7) ; Silence
  (ite (= i 151) (mkPoint -5 -7 7) ; Résignation
  (ite (= i 152) (mkPoint -10 2 7) ; Hantise
  (ite (= i 153) (mkPoint -10 -2 7) ; Isolement
  (ite (= i 154) (mkPoint -8 4 7) ; Affliction
  (ite (= i 155) (mkPoint -8 -4 7) ; Mélancolie
  (ite (= i 156) (mkPoint -11 1 7) ; Précarité
  (ite (= i 157) (mkPoint -11 -1 7) ; Déchéance
  (ite (= i 158) (mkPoint -9 3 7) ; Sidération
  (ite (= i 159) (mkPoint -9 -3 7) ; Engloutissement
  (ite (= i 160) (mkPoint -7 5 7) ; Tumulte
  (ite (= i 161) (mkPoint -7 -5 7) ; Pétrification
  (ite (= i 162) (mkPoint 10 2 7) ; Éblouissement
  (ite (= i 163) (mkPoint 10 -2 7) ; Recueillement
  (ite (= i 164) (mkPoint 8 4 7) ; Rayonnement
  (ite (= i 165) (mkPoint 8 -4 7) ; Contentement
  (ite (= i 166) (mkPoint 11 1 7) ; Ravissement
  (ite (= i 167) (mkPoint 11 -1 7) ; Épiphanie
  (ite (= i 168) (mkPoint 9 3 7) ; Louange
  (ite (= i 169) (mkPoint 9 -3 7) ; Lucidité
  (ite (= i 170) (mkPoint 7 5 7) ; Effusion
  (ite (= i 171) (mkPoint 7 -5 7) ; Consentement
  (ite (= i 172) (mkPoint -6 6 7) ; Rage
  (ite (= i 173) (mkPoint 6 -6 7) ; Impassibilité
  (ite (= i 174) (mkPoint 6 6 7) ; Sublimation
  (mkPoint -6 -6 7) ; Dissolution
  )))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))
)
(define-fun validLexIndex ((i Int)) Bool (and (<= 0 i) (< i 176)))

(define-fun defaultEngine () PredictiveEngineState
  (mkPredictiveEngineState (mkSalientDiscrepancy 0 1 1) (mkPerceptiveInterface Pol_neg)
    (mkSubjectiveInterface Pol_neg false) (mkAttentionalInterface 0 0 0 1 1)))
(define-fun sampleSurpriseEngine () PredictiveEngineState
  (mkPredictiveEngineState (mkSalientDiscrepancy 5 2 1) (mkPerceptiveInterface Pol_pos)
    (mkSubjectiveInterface Pol_neg false) (mkAttentionalInterface 1 3 0 1 1)))
(define-fun sampleColereEngine () PredictiveEngineState
  (mkPredictiveEngineState (mkSalientDiscrepancy 5 2 1) (mkPerceptiveInterface Pol_pos)
    (mkSubjectiveInterface Pol_neg true) (mkAttentionalInterface 5 3 0 1 1)))
(define-fun sampleNeutralSuspendedEngine () PredictiveEngineState
  (mkPredictiveEngineState (mkSalientDiscrepancy 5 2 1) (mkPerceptiveInterface Pol_zero)
    (mkSubjectiveInterface Pol_zero true) (mkAttentionalInterface 5 3 0 1 1)))
(define-fun sampleSubthresholdSuspendedEngine () PredictiveEngineState
  (mkPredictiveEngineState (mkSalientDiscrepancy 0 2 1) (mkPerceptiveInterface Pol_pos)
    (mkSubjectiveInterface Pol_neg true) (mkAttentionalInterface 5 3 0 1 1)))
(define-fun sampleVeilleStepStart () PredictiveEngineState
  (mkPredictiveEngineState (mkSalientDiscrepancy 5 2 1) (mkPerceptiveInterface Pol_zero)
    (mkSubjectiveInterface Pol_zero false) (mkAttentionalInterface 0 2 0 1 1)))
(define-fun sampleConsternationEngine () PredictiveEngineState
  (mkPredictiveEngineState (mkSalientDiscrepancy 6 2 1) (mkPerceptiveInterface Pol_pos)
    (mkSubjectiveInterface Pol_neg true) (mkAttentionalInterface 5 3 1 1 3)))

; -----------------------------------------------------------------------------
; Controle de non-vacuite (doit retourner sat)
; -----------------------------------------------------------------------------
(echo "[CONSISTENCY]")
(push)
(declare-const dummy Int)
(assert (= dummy 0))
(check-sat)
(pop)

; -----------------------------------------------------------------------------
; 113e theoreme : all176Entries_antagonist_inverts_hedonic_polarity
; -----------------------------------------------------------------------------
(echo "[THM] all176Entries_antagonist_inverts_hedonic_polarity")
(push)
(assert (not
  (forall ((i Int))
    (=> (validLexIndex i)
        (let ((pt (lexiconPoint i)))
          (let ((ant (antagonistPoint pt)))
            (= (computeHedonicPolarity (pt_x ant) (pt_y ant))
               (HedonicPolarity_invert (computeHedonicPolarity (pt_x pt) (pt_y pt))))))))))
(check-sat)
(pop)

; -----------------------------------------------------------------------------
; Parite des 11 blocs d'evaluation concrete (#eval <-> Compute)
; -----------------------------------------------------------------------------
(echo "[EVAL] block_01_basal_veille")
(push)
(assert (not
  (let ((pt (projectToCoreAffect defaultEngine)))
    (and (= pt (mkPoint 0 0 0))
         (= (classifyStratum (pt_z pt)) TS_z0_pointDeVeille)
         (= (classifyTaxonomicGroup pt) TG_operateurCentral)))))
(check-sat)
(pop)

(echo "[EVAL] block_02_surprise")
(push)
(assert (not
  (let ((pt (projectToCoreAffect sampleSurpriseEngine)))
    (and (= pt (mkPoint 0 0 1))
         (= (classifyStratum (pt_z pt)) TS_z1_saillancePerceptive)
         (= (computeActivation pt) PA_ascendingRupture)))))
(check-sat)
(pop)

(echo "[EVAL] block_03_colere_calme")
(push)
(assert (not
  (let ((pt (projectToCoreAffect sampleColereEngine)))
    (let ((ant (antagonistPoint pt)))
      (and (= pt (mkPoint (- 1) 1 2))
           (= ant (mkPoint 1 (- 1) 2))
           (= (classifyTaxonomicGroup pt) TG_groupeColere)
           (= (classifySubsector (pt_x pt) (pt_y pt)) FS_diagonalAnger)
           (= (classifyTaxonomicGroup ant) TG_groupeCalme)
           (= (classifySubsector (pt_x ant) (pt_y ant)) FS_diagonalCalm)
           (= (computeEnergyRegime (pt_x pt) (pt_y pt)) ER_ergotropicCompensation)
           (= (computeHedonicPolarity (pt_x pt) (pt_y pt)) Hed_negative))))))
(check-sat)
(pop)

(echo "[EVAL] block_04_suspension_r5_trajectory")
(push)
(assert (not
  (let ((s0 sampleVeilleStepStart))
    (let ((s1 (engineStep s0))
          (s2 (engineStep (engineStep s0)))
          (s3 (engineStep (engineStep (engineStep s0)))))
      (and (= (projectToCoreAffect sampleNeutralSuspendedEngine) (mkPoint 0 0 2))
           (= (projectToCoreAffect sampleSubthresholdSuspendedEngine) (mkPoint 0 0 2))
           (= (projectToCoreAffect s0) (mkPoint 0 0 0))
           (= (projectToCoreAffect s1) (mkPoint 0 0 1))
           (= (projectToCoreAffect s2) (mkPoint 0 0 2))
           (= (projectToCoreAffect s3) (mkPoint 0 2 2)))))))
(check-sat)
(pop)

(echo "[EVAL] block_05_dissipation_short_circuit")
(push)
(assert (not
  (let ((p2 (mkPoint 0 0 2)) (pcol (mkPoint (- 1) 1 2)) (pcon (mkPoint (- 1) 3 3)))
    (and (= (dissipationStep p2) (mkPoint 0 0 0))
         (= (- (dissipationPotential p2) (dissipationPotential (dissipationStep p2))) 4)
         (= (dissipationStep pcol) (mkPoint 0 0 2))
         (= (dissipationStep (dissipationStep pcol)) (mkPoint 0 0 0))
         (= (dissipationStep pcon) (mkPoint 0 0 3))
         (= (dissipationStep (dissipationStep pcon)) (mkPoint 0 0 2))
         (= (dissipationStep (dissipationStep (dissipationStep pcon))) (mkPoint 0 0 0))))))
(check-sat)
(pop)

(echo "[EVAL] block_06_consternation_r8")
(push)
(assert (not
  (let ((pt (projectToCoreAffect sampleConsternationEngine)))
    (let ((ant (antagonistPoint pt)))
      (and (= pt (mkPoint (- 1) 3 3))
           (= (CoreAffectPoint_classifyGeometry pt) GT_lateral)
           (= (classifyTaxonomicGroup pt) TG_groupeJoie)
           (= (classifySubsector (pt_x pt) (pt_y pt)) FS_lateralDefensiveUrgency)
           (= (computeHedonicPolarity (pt_x pt) (pt_y pt)) Hed_negative)
           (= ant (mkPoint 3 (- 1) 3)))))))
(check-sat)
(pop)

(echo "[EVAL] block_07_canonical_depth_kernel")
(push)
(assert (not
  (let ((src (mkPoint (- 1) 1 2)))
    (and (= (canonicalDepthWeight src (mkPoint (- 2) 2 3)) 2)
         (= (canonicalDepthWeight src (mkPoint (- 1) 3 3)) 1)
         (= (canonicalDepthWeight src (mkPoint (- 3) 1 3)) 1)
         (= (outgoingWeight src) 4)
         (= (canonicalDepthWeight (antagonistPoint src) (antagonistPoint (mkPoint (- 1) 3 3))) 1)))))
(check-sat)
(pop)

(echo "[EVAL] block_08_attractor_membership_r1")
(push)
(assert (not
  (let ((c (mkPoint (- 1) 3 3)) (e (mkPoint (- 2) 4 4)))
    (and (= (attractorMembership c TG_groupeJoie) 4)
         (= (attractorMembership c TG_groupeColere) 2)
         (= (attractorMembership c TG_groupePeur) 1)
         (= (classifyTaxonomicGroup c) TG_groupeJoie)
         (= (attractorMembership e TG_groupeJoie) 6)
         (= (attractorMembership e TG_groupeColere) 4)
         (= (attractorMembership e TG_groupePeur) 2)
         (= (classifyTaxonomicGroup e) TG_groupeJoie)))))
(check-sat)
(pop)

(echo "[EVAL] block_09_inverted_mapping_r3")
(push)
(assert (not
  (let ((pt (projectToCoreAffect sampleColereEngine)))
    (let ((ant (antagonistPoint pt)))
      (and (= pt (mkPoint (- 1) 1 2))
           (= ant (mkPoint 1 (- 1) 2))
           (= (computeHedonicPolarity (pt_x pt) (pt_y pt)) Hed_negative)
           (= (HedonicPolarity_invert (computeHedonicPolarity (pt_x pt) (pt_y pt))) Hed_positive))))))
(check-sat)
(pop)

(echo "[EVAL] block_10_predictive_circuit_6_ops")
(push)
(assert (not
  (and (= (crossingIPos (mkEngineCoupling Pol_zero Pol_zero)) (mkPair 0 2))
       (= (crossingIIPos (mkEngineCoupling Pol_zero Pol_zero)) (mkPair 2 0))
       (= (projectPerceptible (mkEngineCoupling Pol_neg Pol_pos) 3 1 3 true) (mkPoint (- 1) 3 3))
       (= (circuitRowSum defaultCircuitKernelParams (mkEngineCoupling Pol_neg Pol_zero)) 4000000000000)
       (= (circuitWeight defaultCircuitKernelParams (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_neg Pol_pos)) 101500000000)
       (= (op3_crossingI_point defaultCircularCircuitState) (mkPoint 0 0 0)))))
(check-sat)
(pop)

(echo "[EVAL] block_11_unified_dynamics")
(push)
(assert (not
  (and (= (nextChargeAccumulator defaultUnifiedDynamicsParams 1000 500 500
             (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_pos Pol_zero)) 700)
       (= (nextChargeAccumulator defaultUnifiedDynamicsParams 1000 500 500
             (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_zero Pol_zero)) 1300)
       (= (nextStratumR5 defaultUnifiedDynamicsParams 2 100) 0)
       (= (nextStratumR5 defaultUnifiedDynamicsParams 3 100) 2)
       (= (projectUnifiedState defaultUnifiedDynamicsParams (mkEngineCoupling Pol_neg Pol_pos) 3 10 90 true)
          (mkPoint (- 1) 3 3))
       (= (precisionShares defaultUnifiedDynamicsParams 10 90 (mkEngineCoupling Pol_neg Pol_neg))
          (mkPair 193 807)))))
(check-sat)
(pop)

; Sortie explicite des valeurs evaluees pour comparaison de parite
(echo "[VALUES]")
(push)
(check-sat)
(eval (projectToCoreAffect defaultEngine))
(eval (projectToCoreAffect sampleSurpriseEngine))
(eval (projectToCoreAffect sampleColereEngine))
(eval (antagonistPoint (projectToCoreAffect sampleColereEngine)))
(eval (projectToCoreAffect sampleConsternationEngine))
(eval (outgoingWeight (mkPoint (- 1) 1 2)))
(eval (circuitRowSum defaultCircuitKernelParams (mkEngineCoupling Pol_neg Pol_zero)))
(eval (circuitWeight defaultCircuitKernelParams (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_neg Pol_pos)))
(eval (nextChargeAccumulator defaultUnifiedDynamicsParams 1000 500 500 (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_pos Pol_zero)))
(eval (nextChargeAccumulator defaultUnifiedDynamicsParams 1000 500 500 (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_zero Pol_zero)))
(eval (precisionShares defaultUnifiedDynamicsParams 10 90 (mkEngineCoupling Pol_neg Pol_neg)))
(pop)
