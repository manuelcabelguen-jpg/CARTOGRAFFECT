; =============================================================================
; Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
; SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
; Author: Manuel Cabelguen
;
; Module 04 : AffectiveTaxonomy (SMT-LIB 2.6 / Z3)
; Equivalence formelle directe avec Cartograffect/AffectiveTaxonomy.lean
; =============================================================================
(set-logic ALL)
(set-option :produce-models true)

; -----------------------------------------------------------------------------
; 1. Types fondamentaux
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

(declare-datatypes ((OrientationSector 0)) (
  ((Sec_joie) (Sec_tristesse) (Sec_peur) (Sec_courage))
))

(declare-datatypes ((OptionSector 0)) (
  ((OptNone) (OptSome (opt_val OrientationSector)))
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

(declare-datatypes ((TaxonomicStratum 0)) (
  ((TS_z0_pointDeVeille)
   (TS_z1_saillancePerceptive)
   (TS_z2_affectsPrimaires)
   (TS_z3_emotionsReactives)
   (TS_z4_sentimentsReflexifs)
   (TS_z5_orientationsDurables)
   (TS_z6_identitesAffectives)
   (TS_z7_sentimentsTranscendants)
   (TS_zDeepProlongation (ts_depth Int)))
))

(declare-datatypes ((TaxonomicGroup 0)) (
  ((TG_operateurCentral)
   (TG_groupeJoie) (TG_groupeTristesse) (TG_groupePeur) (TG_groupeCourage)
   (TG_groupeDesir) (TG_groupeDegout) (TG_groupeColere) (TG_groupeCalme))
))

(declare-datatypes ((FunctionalSubsector 0)) (
  ((FS_centralOperator)
   (FS_axialElan) (FS_axialWithdrawal) (FS_axialOpening) (FS_axialThreat)
   (FS_diagonalDesire) (FS_diagonalDisgust) (FS_diagonalAnger) (FS_diagonalCalm)
   (FS_lateralApproachSynergy) (FS_lateralDefensiveUrgency)
   (FS_lateralTrophotropicPeace) (FS_lateralAversiveDistress)
   (FS_lateralEpistemicMastery) (FS_lateralContemplativeOpen)
   (FS_lateralVigilantAlert) (FS_lateralEpistemicClosure))
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

(declare-datatypes ((TaxonomicState 0)) (
  ((mkTaxonomicState
    (ts_matrix AffectiveMatrixState)
    (ts_stratum TaxonomicStratum)
    (ts_geometry GeometryType)
    (ts_group TaxonomicGroup)
    (ts_subsector FunctionalSubsector)
    (ts_antagonistGroup TaxonomicGroup)
    (ts_antagonistSubsector FunctionalSubsector)))
))

; -----------------------------------------------------------------------------
; 2. Predicats de validite et fonctions
; -----------------------------------------------------------------------------
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

(define-fun Polarity_isEngaged ((p Polarity)) Bool (not (= p Pol_zero)))

(define-fun EngineCoupling_isGlobalNeutrality ((c EngineCoupling)) Bool
  (and (not (Polarity_isEngaged (ec_attente c)))
       (not (Polarity_isEngaged (ec_controle c)))))

(define-fun SalientDiscrepancy_isSensorilySalient ((d SalientDiscrepancy)) Bool
  (<= (sd_sensoryThreshold d) (sd_magnitude d)))

(define-fun AttentionalInterface_isEngaged ((att AttentionalInterface)) Bool
  (<= (ai_engagementThreshold att) (ai_allocatedPrecision att)))

(define-fun PredictiveEngineState_currentCoupling ((s PredictiveEngineState)) EngineCoupling
  (mkEngineCoupling
    (si_attenteGradient (pes_subjective s))
    (pi_controleGradient (pes_perceptive s))))

(define-fun intAbs ((v Int)) Int (ite (>= v 0) v (- v)))

(define-fun CoreAffectPoint_displacementSum ((p CoreAffectPoint)) Int
  (+ (intAbs (pt_x p)) (intAbs (pt_y p))))

(define-fun crownRadius ((z Int)) Int
  (ite (< z 2) 0 (- (* 2 z) 2)))

(define-fun isValidCoreAffect ((p CoreAffectPoint)) Bool
  (and (>= (pt_z p) 0)
       (or (and (= (pt_x p) 0) (= (pt_y p) 0))
           (and (>= (pt_z p) 2)
                (= (CoreAffectPoint_displacementSum p) (crownRadius (pt_z p)))))))

(define-fun signedAmplitude ((pol Polarity) (amp Int)) Int
  (ite (= pol Pol_neg) (- amp)
  (ite (= pol Pol_zero) 0 amp)))

(define-fun clampInt ((lo Int) (hi Int) (v Int)) Int
  (ite (< v lo) lo (ite (< hi v) hi v)))

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

(define-fun CoreAffectPoint_classifyGeometry ((p CoreAffectPoint)) GeometryType
  (ite (and (= (pt_x p) 0) (= (pt_y p) 0)) GT_central
  (ite (or (= (pt_x p) 0) (= (pt_y p) 0)) GT_axial
  (ite (= (intAbs (pt_x p)) (intAbs (pt_y p))) GT_diagonal
  GT_lateral))))

(define-fun CoreAffectPoint_dominantSector ((p CoreAffectPoint)) OptionSector
  (ite (> (intAbs (pt_y p)) (intAbs (pt_x p)))
    (ite (> (pt_y p) 0) (OptSome Sec_joie) (OptSome Sec_tristesse))
    (ite (> (intAbs (pt_x p)) (intAbs (pt_y p)))
      (ite (< (pt_x p) 0) (OptSome Sec_peur) (OptSome Sec_courage))
      OptNone)))

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
  (ite (< y 0) Hed_negative Hed_neutral)))))

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

(define-fun classifyStratum ((z Int)) TaxonomicStratum
  (ite (= z 0) TS_z0_pointDeVeille
  (ite (= z 1) TS_z1_saillancePerceptive
  (ite (= z 2) TS_z2_affectsPrimaires
  (ite (= z 3) TS_z3_emotionsReactives
  (ite (= z 4) TS_z4_sentimentsReflexifs
  (ite (= z 5) TS_z5_orientationsDurables
  (ite (= z 6) TS_z6_identitesAffectives
  (ite (= z 7) TS_z7_sentimentsTranscendants
  (TS_zDeepProlongation z))))))))))

(define-fun matchesTaxonomicGroup ((p CoreAffectPoint) (g TaxonomicGroup)) Bool
  (let ((x (pt_x p)) (y (pt_y p)))
    (ite (= g TG_operateurCentral) (and (= x 0) (= y 0))
    (ite (= g TG_groupeJoie)       (and (> (intAbs y) (intAbs x)) (> y 0))
    (ite (= g TG_groupeTristesse)  (and (> (intAbs y) (intAbs x)) (< y 0))
    (ite (= g TG_groupePeur)       (and (> (intAbs x) (intAbs y)) (< x 0))
    (ite (= g TG_groupeCourage)    (and (> (intAbs x) (intAbs y)) (> x 0))
    (ite (= g TG_groupeDesir)      (and (= (intAbs x) (intAbs y)) (> x 0) (> y 0))
    (ite (= g TG_groupeDegout)     (and (= (intAbs x) (intAbs y)) (< x 0) (< y 0))
    (ite (= g TG_groupeColere)     (and (= (intAbs x) (intAbs y)) (< x 0) (> y 0))
    (and (= (intAbs x) (intAbs y)) (> x 0) (< y 0))))))))))))

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

(define-fun matchesSubsector ((x Int) (y Int) (s FunctionalSubsector)) Bool
  (ite (= s FS_centralOperator)          (and (= x 0) (= y 0))
  (ite (= s FS_axialElan)                (and (= x 0) (> y 0))
  (ite (= s FS_axialWithdrawal)          (and (= x 0) (< y 0))
  (ite (= s FS_axialOpening)             (and (> x 0) (= y 0))
  (ite (= s FS_axialThreat)              (and (< x 0) (= y 0))
  (ite (= s FS_diagonalDesire)           (and (= x y) (> x 0))
  (ite (= s FS_diagonalDisgust)          (and (= x y) (< x 0))
  (ite (= s FS_diagonalAnger)            (and (= x (- y)) (< x 0))
  (ite (= s FS_diagonalCalm)             (and (= x (- y)) (> x 0))
  (ite (= s FS_lateralApproachSynergy)   (and (> y (intAbs x)) (> x 0))
  (ite (= s FS_lateralDefensiveUrgency)  (and (> y (intAbs x)) (< x 0))
  (ite (= s FS_lateralTrophotropicPeace) (and (> (- y) (intAbs x)) (> x 0))
  (ite (= s FS_lateralAversiveDistress)  (and (> (- y) (intAbs x)) (< x 0))
  (ite (= s FS_lateralEpistemicMastery)  (and (> x (intAbs y)) (> y 0))
  (ite (= s FS_lateralContemplativeOpen) (and (> x (intAbs y)) (< y 0))
  (ite (= s FS_lateralVigilantAlert)     (and (> (- x) (intAbs y)) (> y 0))
  (and (> (- x) (intAbs y)) (< y 0)))))))))))))))))))

(define-fun FunctionalSubsector_toTaxonomicGroup ((s FunctionalSubsector)) TaxonomicGroup
  (ite (= s FS_centralOperator)          TG_operateurCentral
  (ite (or (= s FS_axialElan) (= s FS_lateralApproachSynergy) (= s FS_lateralDefensiveUrgency))
       TG_groupeJoie
  (ite (or (= s FS_axialWithdrawal) (= s FS_lateralTrophotropicPeace) (= s FS_lateralAversiveDistress))
       TG_groupeTristesse
  (ite (or (= s FS_axialOpening) (= s FS_lateralEpistemicMastery) (= s FS_lateralContemplativeOpen))
       TG_groupeCourage
  (ite (or (= s FS_axialThreat) (= s FS_lateralVigilantAlert) (= s FS_lateralEpistemicClosure))
       TG_groupePeur
  (ite (= s FS_diagonalDesire)  TG_groupeDesir
  (ite (= s FS_diagonalDisgust) TG_groupeDegout
  (ite (= s FS_diagonalAnger)   TG_groupeColere
  TG_groupeCalme)))))))))

(define-fun FunctionalSubsector_toHedonicPolarity ((s FunctionalSubsector)) HedonicPolarity
  (ite (= s FS_centralOperator) Hed_neutral
  (ite (or (= s FS_axialElan) (= s FS_axialOpening) (= s FS_diagonalDesire) (= s FS_diagonalCalm)
           (= s FS_lateralApproachSynergy) (= s FS_lateralTrophotropicPeace)
           (= s FS_lateralEpistemicMastery) (= s FS_lateralContemplativeOpen))
       Hed_positive
  Hed_negative)))

(define-fun crownPeripheralCount ((z Int)) Int (* 4 (crownRadius z)))
(define-fun stratumTotalCount ((z Int)) Int (+ 1 (crownPeripheralCount z)))

(define-fun runCartograffectPipeline ((s PredictiveEngineState)) TaxonomicState
  (let ((p (projectToCoreAffect s)))
    (let ((ap (antagonistPoint p)))
      (mkTaxonomicState
        (mkAffectiveMatrixState
          p
          (transduceExpectation (pt_x p))
          (transduceControl (pt_y p))
          (computeEnergyRegime (pt_x p) (pt_y p))
          (computeHedonicPolarity (pt_x p) (pt_y p))
          (computeActivation p)
          ap)
        (classifyStratum (pt_z p))
        (CoreAffectPoint_classifyGeometry p)
        (classifyTaxonomicGroup p)
        (classifySubsector (pt_x p) (pt_y p))
        (classifyTaxonomicGroup ap)
        (classifySubsector (pt_x ap) (pt_y ap))))))

(define-fun isCoherentTerminalState ((s PredictiveEngineState) (ts TaxonomicState)) Bool
  (let ((m (ts_matrix ts)))
    (let ((cp (ams_core m)) (ap (ams_antagonist m)))
      (and
        (= cp (projectToCoreAffect s))
        (isValidCoreAffect cp)
        (= ap (antagonistPoint cp))
        (isValidCoreAffect ap)
        (= (pt_z ap) (pt_z cp))
        (= (CoreAffectPoint_displacementSum ap) (CoreAffectPoint_displacementSum cp))
        (= (ams_expectationPole m) (transduceExpectation (pt_x cp)))
        (= (ams_controlPole m) (transduceControl (pt_y cp)))
        (= (ams_energyRegime m) (computeEnergyRegime (pt_x cp) (pt_y cp)))
        (= (ams_valence m) (computeHedonicPolarity (pt_x cp) (pt_y cp)))
        (= (ams_activation m) (computeActivation cp))
        (= (ts_stratum ts) (classifyStratum (pt_z cp)))
        (= (ts_geometry ts) (CoreAffectPoint_classifyGeometry cp))
        (= (ts_subsector ts) (classifySubsector (pt_x cp) (pt_y cp)))
        (= (ts_antagonistSubsector ts) (classifySubsector (pt_x ap) (pt_y ap)))
        (matchesTaxonomicGroup cp (ts_group ts))
        (forall ((g TaxonomicGroup))
          (=> (matchesTaxonomicGroup cp g) (= g (ts_group ts))))
        (matchesTaxonomicGroup ap (ts_antagonistGroup ts))))))

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
; 3. Audit des 10 theoremes de AffectiveTaxonomy (chaque controle doit retourner unsat)
; -----------------------------------------------------------------------------

; [1/10] inventory_176_certified
(echo "[THM] inventory_176_certified")
(push)
(assert (not
  (and (= (crownPeripheralCount 2) 8)
       (= (crownPeripheralCount 3) 16)
       (= (crownPeripheralCount 4) 24)
       (= (crownPeripheralCount 5) 32)
       (= (crownPeripheralCount 6) 40)
       (= (crownPeripheralCount 7) 48)
       (= (+ (crownPeripheralCount 2) (crownPeripheralCount 3) (crownPeripheralCount 4)
             (crownPeripheralCount 5) (crownPeripheralCount 6) (crownPeripheralCount 7)) 168)
       (= (+ (stratumTotalCount 0) (stratumTotalCount 1) (stratumTotalCount 2) (stratumTotalCount 3)
             (stratumTotalCount 4) (stratumTotalCount 5) (stratumTotalCount 6) (stratumTotalCount 7)) 176))))
(check-sat)
(pop)

; [2/10] taxonomy_group_exhaustive
(echo "[THM] taxonomy_group_exhaustive")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (exists ((g TaxonomicGroup))
      (matchesTaxonomicGroup p g)))))
(check-sat)
(pop)

; [3/10] taxonomy_group_exclusive
(echo "[THM] taxonomy_group_exclusive")
(push)
(assert (not
  (forall ((p CoreAffectPoint) (g1 TaxonomicGroup) (g2 TaxonomicGroup))
    (=> (and (matchesTaxonomicGroup p g1) (matchesTaxonomicGroup p g2))
        (= g1 g2)))))
(check-sat)
(pop)

; [4/10] dominantSector_iff_taxonomicGroup
(echo "[THM] dominantSector_iff_taxonomicGroup")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (and (= (= (CoreAffectPoint_dominantSector p) (OptSome Sec_joie))
            (matchesTaxonomicGroup p TG_groupeJoie))
         (= (= (CoreAffectPoint_dominantSector p) (OptSome Sec_tristesse))
            (matchesTaxonomicGroup p TG_groupeTristesse))
         (= (= (CoreAffectPoint_dominantSector p) (OptSome Sec_peur))
            (matchesTaxonomicGroup p TG_groupePeur))
         (= (= (CoreAffectPoint_dominantSector p) (OptSome Sec_courage))
            (matchesTaxonomicGroup p TG_groupeCourage))))))
(check-sat)
(pop)

; [5/10] contralateral_group_bindings
(echo "[THM] contralateral_group_bindings")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (and
      (=> (and (matchesTaxonomicGroup p TG_groupeJoie) (> (pt_x p) 0))
          (and (matchesTaxonomicGroup (antagonistPoint p) TG_groupePeur)
               (< (pt_y (antagonistPoint p)) 0)))
      (=> (and (matchesTaxonomicGroup p TG_groupeJoie) (< (pt_x p) 0))
          (and (matchesTaxonomicGroup (antagonistPoint p) TG_groupeCourage)
               (< (pt_y (antagonistPoint p)) 0)))
      (=> (and (matchesTaxonomicGroup p TG_groupeTristesse) (> (pt_x p) 0))
          (and (matchesTaxonomicGroup (antagonistPoint p) TG_groupePeur)
               (> (pt_y (antagonistPoint p)) 0)))
      (=> (and (matchesTaxonomicGroup p TG_groupeTristesse) (< (pt_x p) 0))
          (and (matchesTaxonomicGroup (antagonistPoint p) TG_groupeCourage)
               (> (pt_y (antagonistPoint p)) 0)))))))
(check-sat)
(pop)

; [6/10] classifySubsector_correct
(echo "[THM] classifySubsector_correct")
(push)
(assert (not
  (forall ((x Int) (y Int))
    (matchesSubsector x y (classifySubsector x y)))))
(check-sat)
(pop)

; [7/10] subsector_exclusive
(echo "[THM] subsector_exclusive")
(push)
(assert (not
  (forall ((x Int) (y Int) (s1 FunctionalSubsector) (s2 FunctionalSubsector))
    (=> (and (matchesSubsector x y s1) (matchesSubsector x y s2))
        (= s1 s2)))))
(check-sat)
(pop)

; [8/10] classifySubsector_refines_group
(echo "[THM] classifySubsector_refines_group")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (= (FunctionalSubsector_toTaxonomicGroup (classifySubsector (pt_x p) (pt_y p)))
       (classifyTaxonomicGroup p)))))
(check-sat)
(pop)

; [9/10] classifySubsector_determines_valence
(echo "[THM] classifySubsector_determines_valence")
(push)
(assert (not
  (forall ((x Int) (y Int))
    (= (FunctionalSubsector_toHedonicPolarity (classifySubsector x y))
       (computeHedonicPolarity x y)))))
(check-sat)
(pop)

; [10/10] end_to_end_coherence
(echo "[THM] end_to_end_coherence")
(push)
(assert (not
  (forall ((s PredictiveEngineState))
    (=> (validEngineState s)
        (let ((ts (runCartograffectPipeline s)))
          (and (isCoherentTerminalState s ts)
               (forall ((ts2 TaxonomicState))
                 (=> (isCoherentTerminalState s ts2)
                     (= ts2 ts)))))))))
(check-sat)
(pop)
