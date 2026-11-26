; =============================================================================
; Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
; SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
; Author: Manuel Cabelguen
;
; Module 10 : EndToEndBridge (SMT-LIB 2.6 / Z3)
; Equivalence formelle directe avec Cartograffect/EndToEndBridge.lean & EndToEndBridge.v
; =============================================================================
(set-logic ALL)
(set-option :produce-models true)

; -----------------------------------------------------------------------------
; 1. Types fondamentaux (alignes sur les modules 01..09)
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
  (((mkAttentionalInterface
      (ai_allocatedPrecision Int) (ai_engagementThreshold Int)
      (ai_persistenceDepth Int) (ai_precisionA Int) (ai_precisionC Int)))))
(declare-datatypes ((EngineCoupling 0))
  (((mkEngineCoupling (ec_attente Polarity) (ec_controle Polarity)))))
(declare-datatypes ((PredictiveEngineState 0))
  (((mkPredictiveEngineState
      (pes_discrepancy SalientDiscrepancy) (pes_perceptive PerceptiveInterface)
      (pes_subjective SubjectiveInterface) (pes_attentional AttentionalInterface)))))
(declare-datatypes ((CoreAffectPoint 0))
  (((mkPoint (pt_x Int) (pt_y Int) (pt_z Int)))))
(declare-datatypes ((GeometryType 0))
  (((GT_central) (GT_axial) (GT_diagonal) (GT_lateral))))
(declare-datatypes ((OrientationSector 0))
  (((Sec_joie) (Sec_tristesse) (Sec_peur) (Sec_courage))))
(declare-datatypes ((OptionSector 0))
  (((OptNone) (OptSome (opt_val OrientationSector)))))
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
  (((TG_operateurCentral)
    (TG_groupeJoie) (TG_groupeTristesse) (TG_groupePeur) (TG_groupeCourage)
    (TG_groupeDesir) (TG_groupeDegout) (TG_groupeColere) (TG_groupeCalme))))
(declare-datatypes ((FunctionalSubsector 0))
  (((FS_centralOperator)
    (FS_axialElan) (FS_axialWithdrawal) (FS_axialOpening) (FS_axialThreat)
    (FS_diagonalDesire) (FS_diagonalDisgust) (FS_diagonalAnger) (FS_diagonalCalm)
    (FS_lateralApproachSynergy) (FS_lateralDefensiveUrgency)
    (FS_lateralTrophotropicPeace) (FS_lateralAversiveDistress)
    (FS_lateralEpistemicMastery) (FS_lateralContemplativeOpen)
    (FS_lateralVigilantAlert) (FS_lateralEpistemicClosure))))
(declare-datatypes ((AffectiveMatrixState 0))
  (((mkAffectiveMatrixState
      (ams_core CoreAffectPoint) (ams_expectationPole LivedExpectationPole)
      (ams_controlPole LivedControlPole) (ams_energyRegime EnergyRegime)
      (ams_valence HedonicPolarity) (ams_activation PhenomenologicalActivation)
      (ams_antagonist CoreAffectPoint)))))
(declare-datatypes ((TaxonomicState 0))
  (((mkTaxonomicState
      (ts_matrix AffectiveMatrixState) (ts_stratum TaxonomicStratum)
      (ts_geometry GeometryType) (ts_group TaxonomicGroup)
      (ts_subsector FunctionalSubsector) (ts_antagonistGroup TaxonomicGroup)
      (ts_antagonistSubsector FunctionalSubsector)))))
(declare-datatypes ((ProtoSpatialNode 0))
  (((mkProtoSpatialNode (psn_x Int) (psn_y Int)))))
(declare-datatypes ((IntPair 0))
  (((mkPair (pr_fst Int) (pr_snd Int)))))
(declare-datatypes ((CircuitKernelParams 0))
  (((mkCircuitKernelParams
      (ckp_scale Int) (ckp_rho Int) (ckp_kappa Int)
      (ckp_deltaA Int) (ckp_deltaC Int) (ckp_gammaA Int) (ckp_gammaC Int)
      (ckp_epsilon Int) (ckp_qPosA Int) (ckp_qPosC Int) (ckp_chi Int)))))
(declare-datatypes ((HiddenSubjectiveState 0))
  (((mkHiddenSubjectiveState
      (hss_modelDiscrepancy Int) (hss_revisable Bool) (hss_descendingSuspension Bool)))))
(declare-datatypes ((HiddenPerceptiveState 0))
  (((mkHiddenPerceptiveState (hps_afferentDiscrepancy Int) (hps_controllable Bool)))))
(declare-datatypes ((BodyEnvironmentState 0))
  (((mkBodyEnvironmentState (bes_perturbation Int)))))
(declare-datatypes ((CircularCircuitState 0))
  (((mkCircularCircuitState
      (ccs_subjectiveHidden HiddenSubjectiveState) (ccs_perceptiveHidden HiddenPerceptiveState)
      (ccs_bodyEnv BodyEnvironmentState) (ccs_sensoryThreshold Int)
      (ccs_resorptionThreshold Int) (ccs_attentional AttentionalInterface)))))
(declare-datatypes ((UnifiedDynamicsParams 0))
  (((mkUnifiedDynamicsParams
      (udp_halfScale Int) (udp_lambdaNum Int) (udp_etaScaled Int)
      (udp_betaAtt Int) (udp_alphaCharge Int) (udp_sigmoidK Int) (udp_zMax Int)))))
(declare-datatypes ((PrimaryCrownPrototype 0))
  (((Proto_joie) (Proto_tristesse) (Proto_peur) (Proto_courage)
    (Proto_desir) (Proto_degout) (Proto_colere) (Proto_calme))))
(declare-datatypes ((OperantEffect 0))
  (((OE_Reinforcement) (OE_Punishment))))
(declare-datatypes ((OperantOperator 0))
  (((OO_Addition) (OO_Removal))))
(declare-datatypes ((OperantContingency 0))
  (((mkOperantContingency (oc_effect OperantEffect) (oc_op OperantOperator)))))
(declare-datatypes ((OptionContingency 0))
  (((OC_none) (OC_some (oc_val OperantContingency)))))
(declare-datatypes ((OperantRole 0))
  (((OR_centralOperator)
    (OR_preOperantAxial (or_ax_sec OrientationSector))
    (OR_pureOperant (or_pure_c OperantContingency))
    (OR_blendedLateral (or_bl_sec OrientationSector) (or_bl_c OperantContingency)))))
(declare-datatypes ((LexiconLabel 0))
  (((Lbl_Point_de_Veille) (Lbl_Surprise) (Lbl_Anticipation) (Lbl_Joie) (Lbl_Tristesse) (Lbl_Peur) (Lbl_Courage) (Lbl_Colere) (Lbl_Calme) (Lbl_Desir) (Lbl_Degout) (Lbl_Emoi) (Lbl_Enthousiasme) (Lbl_Ennui) (Lbl_Crainte) (Lbl_Curiosite) (Lbl_Consternation) (Lbl_Euphorie) (Lbl_Soulagement) (Lbl_Chagrin) (Lbl_Panique) (Lbl_Effroi) (Lbl_Emerveillement) (Lbl_Aplomb) (Lbl_Exasperation) (Lbl_Detente) (Lbl_Attrait) (Lbl_Retrait) (Lbl_Reserve) (Lbl_Exaltation) (Lbl_Langueur) (Lbl_Doute) (Lbl_Assurance) (Lbl_Envie) (Lbl_Haine) (Lbl_Amour) (Lbl_Ferveur) (Lbl_Serenite) (Lbl_Plenitude) (Lbl_Honte) (Lbl_Vide) (Lbl_Anxiete) (Lbl_Manque) (Lbl_Mepris) (Lbl_Defiance) (Lbl_Fierte) (Lbl_Epanouissement) (Lbl_Affection) (Lbl_Admiration) (Lbl_Frustration) (Lbl_Acceptation) (Lbl_Estime) (Lbl_Rejet) (Lbl_Recul) (Lbl_Puissance) (Lbl_Impuissance) (Lbl_Mefiance) (Lbl_Confiance) (Lbl_Invulnerabilite) (Lbl_Attachement) (Lbl_Engagement) (Lbl_Desenchantement) (Lbl_Intolerance) (Lbl_Injustice) (Lbl_Quietude) (Lbl_Securite) (Lbl_Patience) (Lbl_Pessimisme) (Lbl_Fermeture) (Lbl_Desespoir) (Lbl_Insecurite) (Lbl_Inquietude) (Lbl_Impatience) (Lbl_Vulnerabilite) (Lbl_Detachement) (Lbl_Desengagement) (Lbl_Optimisme) (Lbl_Ouverture) (Lbl_Espoir) (Lbl_Enchantement) (Lbl_Tolerance) (Lbl_Justice) (Lbl_Insatisfaction) (Lbl_Satisfaction) (Lbl_Interet) (Lbl_Desinteret) (Lbl_Saisissement) (Lbl_Elan) (Lbl_Inertie) (Lbl_Effacement) (Lbl_Affirmation) (Lbl_Ardeur) (Lbl_Angoisse) (Lbl_Allegresse) (Lbl_Fureur) (Lbl_Fougue) (Lbl_Frenesie) (Lbl_Jubilation) (Lbl_Terreur) (Lbl_Beatitude) (Lbl_Accablement) (Lbl_Apaisement) (Lbl_Morosite) (Lbl_Contemplation) (Lbl_Prostration) (Lbl_Felicite) (Lbl_Desolation) (Lbl_Rancur) (Lbl_Amertume) (Lbl_Affolement) (Lbl_Ecrasement) (Lbl_Febrilite) (Lbl_Aneantissement) (Lbl_Desarroi) (Lbl_Lassitude) (Lbl_Entrain) (Lbl_Placidite) (Lbl_Liesse) (Lbl_Limpidite) (Lbl_Extase) (Lbl_Equanimite) (Lbl_Exultation) (Lbl_Harmonie) (Lbl_Tourment) (Lbl_Ataraxie) (Lbl_Triomphe) (Lbl_Abattement) (Lbl_Suspension) (Lbl_Infini) (Lbl_Neant) (Lbl_Dereliction) (Lbl_Communion) (Lbl_Transcendance) (Lbl_Dechirement) (Lbl_Exuberance) (Lbl_Horreur) (Lbl_Renaissance) (Lbl_Vertige) (Lbl_Elevation) (Lbl_Detresse) (Lbl_Enivrement) (Lbl_Revolte) (Lbl_Nirvana) (Lbl_Perdition) (Lbl_Paix) (Lbl_Oppression) (Lbl_Perennite) (Lbl_Abime) (Lbl_Abandon) (Lbl_Damnation) (Lbl_Silence) (Lbl_Resignation) (Lbl_Hantise) (Lbl_Isolement) (Lbl_Affliction) (Lbl_Melancolie) (Lbl_Precarite) (Lbl_Decheance) (Lbl_Sideration) (Lbl_Engloutissement) (Lbl_Tumulte) (Lbl_Petrification) (Lbl_Eblouissement) (Lbl_Recueillement) (Lbl_Rayonnement) (Lbl_Contentement) (Lbl_Ravissement) (Lbl_Epiphanie) (Lbl_Louange) (Lbl_Lucidite) (Lbl_Effusion) (Lbl_Consentement) (Lbl_Rage) (Lbl_Impassibilite) (Lbl_Sublimation) (Lbl_Dissolution))))
(declare-datatypes ((LexiconEntry 0))
  (((mkLexiconEntry (le_label LexiconLabel) (le_point CoreAffectPoint)))))

; Seuils abstraits d'hysteresis R5 (thetaDown z < thetaUp z pour tout z >= 0)
(declare-fun thetaUp (Int) Int)
(declare-fun thetaDown (Int) Int)
(assert (forall ((z Int)) (=> (>= z 0) (and (>= (thetaDown z) 0) (< (thetaDown z) (thetaUp z))))))

; -----------------------------------------------------------------------------
; 2. Predicats de validite et fonctions canoniques (Couches 0..4 + Lexicon176)
; -----------------------------------------------------------------------------
(define-fun validSalientDiscrepancy ((d SalientDiscrepancy)) Bool
  (and (>= (sd_magnitude d) 0) (>= (sd_sensoryThreshold d) 0)
       (>= (sd_resorptionThreshold d) 0) (<= (sd_resorptionThreshold d) (sd_sensoryThreshold d))))

(define-fun validAttentional ((a AttentionalInterface)) Bool
  (and (>= (ai_allocatedPrecision a) 0) (>= (ai_engagementThreshold a) 0)
       (>= (ai_persistenceDepth a) 0) (>= (ai_precisionA a) 0) (>= (ai_precisionC a) 0)))

(define-fun validEngineState ((s PredictiveEngineState)) Bool
  (and (validSalientDiscrepancy (pes_discrepancy s))
       (validAttentional (pes_attentional s))))

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
       (>= (udp_lambdaNum p) 0) (< (udp_lambdaNum p) (* 2 (udp_halfScale p)))
       (>= (udp_etaScaled p) 0) (>= (udp_betaAtt p) 0)
       (>= (udp_alphaCharge p) 0) (> (udp_sigmoidK p) 0) (>= (udp_zMax p) 2)))

(define-fun intAbs ((v Int)) Int (ite (>= v 0) v (- v)))
(define-fun clampInt ((lo Int) (hi Int) (v Int)) Int (ite (< v lo) lo (ite (< hi v) hi v)))

(define-fun Polarity_isEngaged ((p Polarity)) Bool (not (= p Pol_zero)))

(define-fun EngineCoupling_isGlobalNeutrality ((c EngineCoupling)) Bool
  (and (not (Polarity_isEngaged (ec_attente c)))
       (not (Polarity_isEngaged (ec_controle c)))))

(define-fun EngineCoupling_isSingleEngaged ((c EngineCoupling)) Bool
  (or (and (Polarity_isEngaged (ec_attente c)) (not (Polarity_isEngaged (ec_controle c))))
      (and (not (Polarity_isEngaged (ec_attente c))) (Polarity_isEngaged (ec_controle c)))))

(define-fun SalientDiscrepancy_isSensorilySalient ((d SalientDiscrepancy)) Bool
  (<= (sd_sensoryThreshold d) (sd_magnitude d)))

(define-fun AttentionalInterface_isEngaged ((att AttentionalInterface)) Bool
  (<= (ai_engagementThreshold att) (ai_allocatedPrecision att)))

(define-fun PredictiveEngineState_currentCoupling ((s PredictiveEngineState)) EngineCoupling
  (mkEngineCoupling
    (si_attenteGradient (pes_subjective s))
    (pi_controleGradient (pes_perceptive s))))

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
          c (ai_persistenceDepth (pes_attentional s))
          (ai_precisionA (pes_attentional s)) (ai_precisionC (pes_attentional s)))))))

(define-fun triggerSecondaryGradient ((c EngineCoupling) (newPol Polarity)) EngineCoupling
  (let ((a (ec_attente c)) (ctrl (ec_controle c)))
    (ite (and (Polarity_isEngaged a) (= ctrl Pol_zero)) (mkEngineCoupling a newPol)
    (ite (and (= a Pol_zero) (Polarity_isEngaged ctrl)) (mkEngineCoupling newPol ctrl)
    c))))

(define-fun CoreAffectPoint_classifyGeometry ((p CoreAffectPoint)) GeometryType
  (ite (and (= (pt_x p) 0) (= (pt_y p) 0)) GT_central
  (ite (or (= (pt_x p) 0) (= (pt_y p) 0)) GT_axial
  (ite (= (intAbs (pt_x p)) (intAbs (pt_y p))) GT_diagonal GT_lateral))))

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
  (ite (and (< x 0) (> y 0)) ER_ergotropicCompensation ER_trophotropicRelease))))))

(define-fun computeHedonicPolarity ((x Int) (y Int)) HedonicPolarity
  (ite (> x 0) Hed_positive
  (ite (< x 0) Hed_negative
  (ite (> y 0) Hed_positive
  (ite (< y 0) Hed_negative Hed_neutral)))))

(define-fun transduceExpectation ((x Int)) LivedExpectationPole
  (ite (< x 0) LEP_epistemicCharge (ite (> x 0) LEP_epistemicDischarge LEP_epistemicNeutral)))

(define-fun transduceControl ((y Int)) LivedControlPole
  (ite (< y 0) LCP_pragmaticCharge (ite (> y 0) LCP_pragmaticDischarge LCP_pragmaticNeutral)))

(define-fun computeActivation ((p CoreAffectPoint)) PhenomenologicalActivation
  (ite (and (= (pt_x p) 0) (= (pt_y p) 0))
    (ite (= (pt_z p) 0) PA_basalWakefulness
    (ite (= (pt_z p) 1) PA_ascendingRupture PA_operatorSuspension))
  (ite (> (pt_y p) 0) PA_highMobilization (ite (< (pt_y p) 0) PA_lowInhibition PA_epistemicVigilance))))

(define-fun antagonistPoint ((p CoreAffectPoint)) CoreAffectPoint
  (let ((x (pt_x p)) (y (pt_y p)) (z (pt_z p)))
    (ite (or (= x 0) (= y 0) (= (intAbs x) (intAbs y)))
      (mkPoint (- x) (- y) z)
      (ite (or (and (> x 0) (< y 0)) (and (< x 0) (> y 0)))
        (mkPoint y x z) (mkPoint (- y) (- x) z)))))

(define-fun classifyStratum ((z Int)) TaxonomicStratum
  (ite (= z 0) TS_z0_pointDeVeille (ite (= z 1) TS_z1_saillancePerceptive
  (ite (= z 2) TS_z2_affectsPrimaires (ite (= z 3) TS_z3_emotionsReactives
  (ite (= z 4) TS_z4_sentimentsReflexifs (ite (= z 5) TS_z5_orientationsDurables
  (ite (= z 6) TS_z6_identitesAffectives (ite (= z 7) TS_z7_sentimentsTranscendants
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
       Hed_positive Hed_negative)))

(define-fun evaluateTaxonomyOfPoint ((p CoreAffectPoint)) TaxonomicState
  (let ((ap (antagonistPoint p)))
    (mkTaxonomicState
      (mkAffectiveMatrixState
        p (transduceExpectation (pt_x p)) (transduceControl (pt_y p))
        (computeEnergyRegime (pt_x p) (pt_y p)) (computeHedonicPolarity (pt_x p) (pt_y p))
        (computeActivation p) ap)
      (classifyStratum (pt_z p)) (CoreAffectPoint_classifyGeometry p)
      (classifyTaxonomicGroup p) (classifySubsector (pt_x p) (pt_y p))
      (classifyTaxonomicGroup ap) (classifySubsector (pt_x ap) (pt_y ap)))))

(define-fun runCartograffectPipeline ((s PredictiveEngineState)) TaxonomicState
  (evaluateTaxonomyOfPoint (projectToCoreAffect s)))

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

(define-fun canonicalDepthWeight ((p CoreAffectPoint) (q CoreAffectPoint)) Int
  (let ((px (pt_x p)) (py (pt_y p)) (pz (pt_z p))
        (qx (pt_x q)) (qy (pt_y q)) (qz (pt_z q)))
    (ite (and (isValidCoreAffect p) (isValidCoreAffect q) (= qz (+ pz 1)) (>= (* px qx) 0) (>= (* py qy) 0))
      (ite (and (= qx 0) (= qy 0))
        (ite (and (= px 0) (= py 0)) 1 0)
        (ite (and (= px 0) (= py 0))
          (ite (= pz 1) 1 0)
          (ite (or (= px 0) (= py 0))
            (ite (and (or (= px 0) (not (= qx 0))) (or (= py 0) (not (= qy 0))))
              (ite (or (= qx 0) (= qy 0)) 1 (ite (= (intAbs qx) (intAbs qy)) 2 0)) 0)
            (ite (and (not (= qx 0)) (not (= qy 0))
                      (>= (intAbs qx) (intAbs px)) (>= (intAbs qy) (intAbs py)))
              (ite (and (= (intAbs px) (intAbs py)) (= (intAbs qx) (intAbs qy))) 2 1) 0))))
      0)))

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

(define-fun projectPerceptible ((c EngineCoupling) (z Int) (piA Int) (piC Int) (susp Bool)) CoreAffectPoint
  (ite (EngineCoupling_isGlobalNeutrality c)
    (ite (and susp (>= z 2)) (mkPoint 0 0 z) (mkPoint 0 0 0))
    (ite (= z 0) (mkPoint 0 0 0)
    (ite (= z 1) (mkPoint 0 0 1)
    (deployCouplingWithPrecision c (- z 2) piA piC)))))

(define-fun attentionalWeightX2 ((c EngineCoupling)) Int
  (ite (= (ec_attente c) Pol_zero) 2 (intAbs (psn_x (phiL1 c)))))

(define-fun attentionalWeightY2 ((c EngineCoupling)) Int
  (ite (= (ec_controle c) Pol_zero) 2 (intAbs (psn_y (phiL1 c)))))

(define-fun isCharged ((p Polarity)) Bool (= p Pol_neg))

(define-fun effectiveEpsScaled ((m Int) (eps Int) (chi Int) (otherCharged Bool)) Int
  (ite otherCharged (+ (* m eps) (* chi (- m eps))) (* m eps)))

(define-fun marginalWeight
    ((m Int) (rate Int) (delta Int) (deseng Int) (eps Int) (qPos Int) (chi Int)
     (otherCharged Bool) (w2 Int) (src Polarity) (dst Polarity)) Int
  (let ((e2 (effectiveEpsScaled m eps chi otherCharged)))
    (ite (= src Pol_zero)
      (ite (= dst Pol_zero) (* 2 m (- (* m m) e2))
      (ite (= dst Pol_neg)  (* 2 e2 (- m qPos)) (* 2 e2 qPos)))
    (ite (= src Pol_neg)
      (ite (= dst Pol_zero) (* m m (* 2 delta))
      (ite (= dst Pol_neg)  (* m m (- (* 2 m) (* w2 rate) (* 2 delta))) (* m m (* w2 rate))))
      (ite (= dst Pol_zero) (* (- (* m m) e2) (* w2 deseng))
      (ite (= dst Pol_neg)  (* 2 m e2) (* (- (* m m) e2) (- (* 2 m) (* w2 deseng)))))))))

(define-fun circuitWeight ((p CircuitKernelParams) (src EngineCoupling) (dst EngineCoupling)) Int
  (* (marginalWeight (ckp_scale p) (ckp_rho p) (ckp_deltaA p) (ckp_gammaA p)
                     (ckp_epsilon p) (ckp_qPosA p) (ckp_chi p)
                     (isCharged (ec_controle src)) (attentionalWeightX2 src)
                     (ec_attente src) (ec_attente dst))
     (marginalWeight (ckp_scale p) (ckp_kappa p) (ckp_deltaC p) (ckp_gammaC p)
                     (ckp_epsilon p) (ckp_qPosC p) (ckp_chi p)
                     (isCharged (ec_attente src)) (attentionalWeightY2 src)
                     (ec_controle src) (ec_controle dst))))

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

(define-fun symmetricSigmoid ((halfScale Int) (k Int) (u Int)) IntPair
  (let ((shift (div (* halfScale (intAbs u)) (+ (intAbs u) k))))
    (ite (>= u 0)
      (mkPair (+ halfScale shift) (- halfScale shift))
      (mkPair (- halfScale shift) (+ halfScale shift)))))

(define-fun chargeIndicatorInt ((pol Polarity)) Int (ite (= pol Pol_neg) 1 0))

(define-fun precisionScore ((p UnifiedDynamicsParams) (rhoHat Int) (kappaHat Int) (c EngineCoupling)) Int
  (* (udp_betaAtt p)
     (+ (- rhoHat kappaHat)
        (* (udp_alphaCharge p)
           (- (chargeIndicatorInt (ec_attente c))
              (chargeIndicatorInt (ec_controle c)))))))

(define-fun precisionShares ((p UnifiedDynamicsParams) (rhoHat Int) (kappaHat Int) (c EngineCoupling)) IntPair
  (symmetricSigmoid (udp_halfScale p) (udp_sigmoidK p) (precisionScore p rhoHat kappaHat c)))

(define-fun projectUnifiedState
    ((p UnifiedDynamicsParams) (c EngineCoupling) (z Int) (rhoHat Int) (kappaHat Int) (susp Bool))
    CoreAffectPoint
  (let ((sh (precisionShares p rhoHat kappaHat c)))
    (projectPerceptible c z (pr_fst sh) (pr_snd sh) susp)))

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

(define-fun isZ2DiagonalPoint ((p CoreAffectPoint)) Bool
  (or (= p (PrimaryCrownPrototype_toPoint Proto_desir))
      (= p (PrimaryCrownPrototype_toPoint Proto_calme))
      (= p (PrimaryCrownPrototype_toPoint Proto_degout))
      (= p (PrimaryCrownPrototype_toPoint Proto_colere))))

; Lexicon176 (arbres binaires equilibres + inverse exact)
(define-fun validLexIndex ((i Int)) Bool (and (<= 0 i) (< i 176)))

(define-fun lexiconLabel ((i Int)) LexiconLabel
  (ite (< i 88) (ite (< i 44) (ite (< i 22) (ite (< i 11) (ite (< i 5) (ite (< i 2) (ite (< i 1) Lbl_Point_de_Veille Lbl_Surprise) (ite (< i 3) Lbl_Anticipation (ite (< i 4) Lbl_Joie Lbl_Tristesse))) (ite (< i 8) (ite (< i 6) Lbl_Peur (ite (< i 7) Lbl_Courage Lbl_Colere)) (ite (< i 9) Lbl_Calme (ite (< i 10) Lbl_Desir Lbl_Degout)))) (ite (< i 16) (ite (< i 13) (ite (< i 12) Lbl_Emoi Lbl_Enthousiasme) (ite (< i 14) Lbl_Ennui (ite (< i 15) Lbl_Crainte Lbl_Curiosite))) (ite (< i 19) (ite (< i 17) Lbl_Consternation (ite (< i 18) Lbl_Euphorie Lbl_Soulagement)) (ite (< i 20) Lbl_Chagrin (ite (< i 21) Lbl_Panique Lbl_Effroi))))) (ite (< i 33) (ite (< i 27) (ite (< i 24) (ite (< i 23) Lbl_Emerveillement Lbl_Aplomb) (ite (< i 25) Lbl_Exasperation (ite (< i 26) Lbl_Detente Lbl_Attrait))) (ite (< i 30) (ite (< i 28) Lbl_Retrait (ite (< i 29) Lbl_Reserve Lbl_Exaltation)) (ite (< i 31) Lbl_Langueur (ite (< i 32) Lbl_Doute Lbl_Assurance)))) (ite (< i 38) (ite (< i 35) (ite (< i 34) Lbl_Envie Lbl_Haine) (ite (< i 36) Lbl_Amour (ite (< i 37) Lbl_Ferveur Lbl_Serenite))) (ite (< i 41) (ite (< i 39) Lbl_Plenitude (ite (< i 40) Lbl_Honte Lbl_Vide)) (ite (< i 42) Lbl_Anxiete (ite (< i 43) Lbl_Manque Lbl_Mepris)))))) (ite (< i 66) (ite (< i 55) (ite (< i 49) (ite (< i 46) (ite (< i 45) Lbl_Defiance Lbl_Fierte) (ite (< i 47) Lbl_Epanouissement (ite (< i 48) Lbl_Affection Lbl_Admiration))) (ite (< i 52) (ite (< i 50) Lbl_Frustration (ite (< i 51) Lbl_Acceptation Lbl_Estime)) (ite (< i 53) Lbl_Rejet (ite (< i 54) Lbl_Recul Lbl_Puissance)))) (ite (< i 60) (ite (< i 57) (ite (< i 56) Lbl_Impuissance Lbl_Mefiance) (ite (< i 58) Lbl_Confiance (ite (< i 59) Lbl_Invulnerabilite Lbl_Attachement))) (ite (< i 63) (ite (< i 61) Lbl_Engagement (ite (< i 62) Lbl_Desenchantement Lbl_Intolerance)) (ite (< i 64) Lbl_Injustice (ite (< i 65) Lbl_Quietude Lbl_Securite))))) (ite (< i 77) (ite (< i 71) (ite (< i 68) (ite (< i 67) Lbl_Patience Lbl_Pessimisme) (ite (< i 69) Lbl_Fermeture (ite (< i 70) Lbl_Desespoir Lbl_Insecurite))) (ite (< i 74) (ite (< i 72) Lbl_Inquietude (ite (< i 73) Lbl_Impatience Lbl_Vulnerabilite)) (ite (< i 75) Lbl_Detachement (ite (< i 76) Lbl_Desengagement Lbl_Optimisme)))) (ite (< i 82) (ite (< i 79) (ite (< i 78) Lbl_Ouverture Lbl_Espoir) (ite (< i 80) Lbl_Enchantement (ite (< i 81) Lbl_Tolerance Lbl_Justice))) (ite (< i 85) (ite (< i 83) Lbl_Insatisfaction (ite (< i 84) Lbl_Satisfaction Lbl_Interet)) (ite (< i 86) Lbl_Desinteret (ite (< i 87) Lbl_Saisissement Lbl_Elan))))))) (ite (< i 132) (ite (< i 110) (ite (< i 99) (ite (< i 93) (ite (< i 90) (ite (< i 89) Lbl_Inertie Lbl_Effacement) (ite (< i 91) Lbl_Affirmation (ite (< i 92) Lbl_Ardeur Lbl_Angoisse))) (ite (< i 96) (ite (< i 94) Lbl_Allegresse (ite (< i 95) Lbl_Fureur Lbl_Fougue)) (ite (< i 97) Lbl_Frenesie (ite (< i 98) Lbl_Jubilation Lbl_Terreur)))) (ite (< i 104) (ite (< i 101) (ite (< i 100) Lbl_Beatitude Lbl_Accablement) (ite (< i 102) Lbl_Apaisement (ite (< i 103) Lbl_Morosite Lbl_Contemplation))) (ite (< i 107) (ite (< i 105) Lbl_Prostration (ite (< i 106) Lbl_Felicite Lbl_Desolation)) (ite (< i 108) Lbl_Rancur (ite (< i 109) Lbl_Amertume Lbl_Affolement))))) (ite (< i 121) (ite (< i 115) (ite (< i 112) (ite (< i 111) Lbl_Ecrasement Lbl_Febrilite) (ite (< i 113) Lbl_Aneantissement (ite (< i 114) Lbl_Desarroi Lbl_Lassitude))) (ite (< i 118) (ite (< i 116) Lbl_Entrain (ite (< i 117) Lbl_Placidite Lbl_Liesse)) (ite (< i 119) Lbl_Limpidite (ite (< i 120) Lbl_Extase Lbl_Equanimite)))) (ite (< i 126) (ite (< i 123) (ite (< i 122) Lbl_Exultation Lbl_Harmonie) (ite (< i 124) Lbl_Tourment (ite (< i 125) Lbl_Ataraxie Lbl_Triomphe))) (ite (< i 129) (ite (< i 127) Lbl_Abattement (ite (< i 128) Lbl_Suspension Lbl_Infini)) (ite (< i 130) Lbl_Neant (ite (< i 131) Lbl_Dereliction Lbl_Communion)))))) (ite (< i 154) (ite (< i 143) (ite (< i 137) (ite (< i 134) (ite (< i 133) Lbl_Transcendance Lbl_Dechirement) (ite (< i 135) Lbl_Exuberance (ite (< i 136) Lbl_Horreur Lbl_Renaissance))) (ite (< i 140) (ite (< i 138) Lbl_Vertige (ite (< i 139) Lbl_Elevation Lbl_Detresse)) (ite (< i 141) Lbl_Enivrement (ite (< i 142) Lbl_Revolte Lbl_Nirvana)))) (ite (< i 148) (ite (< i 145) (ite (< i 144) Lbl_Perdition Lbl_Paix) (ite (< i 146) Lbl_Oppression (ite (< i 147) Lbl_Perennite Lbl_Abime))) (ite (< i 151) (ite (< i 149) Lbl_Abandon (ite (< i 150) Lbl_Damnation Lbl_Silence)) (ite (< i 152) Lbl_Resignation (ite (< i 153) Lbl_Hantise Lbl_Isolement))))) (ite (< i 165) (ite (< i 159) (ite (< i 156) (ite (< i 155) Lbl_Affliction Lbl_Melancolie) (ite (< i 157) Lbl_Precarite (ite (< i 158) Lbl_Decheance Lbl_Sideration))) (ite (< i 162) (ite (< i 160) Lbl_Engloutissement (ite (< i 161) Lbl_Tumulte Lbl_Petrification)) (ite (< i 163) Lbl_Eblouissement (ite (< i 164) Lbl_Recueillement Lbl_Rayonnement)))) (ite (< i 170) (ite (< i 167) (ite (< i 166) Lbl_Contentement Lbl_Ravissement) (ite (< i 168) Lbl_Epiphanie (ite (< i 169) Lbl_Louange Lbl_Lucidite))) (ite (< i 173) (ite (< i 171) Lbl_Effusion (ite (< i 172) Lbl_Consentement Lbl_Rage)) (ite (< i 174) Lbl_Impassibilite (ite (< i 175) Lbl_Sublimation Lbl_Dissolution)))))))))

(define-fun lexiconPoint ((i Int)) CoreAffectPoint
  (ite (< i 88) (ite (< i 44) (ite (< i 22) (ite (< i 11) (ite (< i 5) (ite (< i 2) (ite (< i 1) (mkPoint 0 0 0) (mkPoint 0 0 1)) (ite (< i 3) (mkPoint 0 0 2) (ite (< i 4) (mkPoint 0 2 2) (mkPoint 0 (- 2) 2)))) (ite (< i 8) (ite (< i 6) (mkPoint (- 2) 0 2) (ite (< i 7) (mkPoint 2 0 2) (mkPoint (- 1) 1 2))) (ite (< i 9) (mkPoint 1 (- 1) 2) (ite (< i 10) (mkPoint 1 1 2) (mkPoint (- 1) (- 1) 2))))) (ite (< i 16) (ite (< i 13) (ite (< i 12) (mkPoint 0 0 3) (mkPoint 0 4 3)) (ite (< i 14) (mkPoint 0 (- 4) 3) (ite (< i 15) (mkPoint (- 4) 0 3) (mkPoint 4 0 3)))) (ite (< i 19) (ite (< i 17) (mkPoint (- 1) 3 3) (ite (< i 18) (mkPoint 1 3 3) (mkPoint 1 (- 3) 3))) (ite (< i 20) (mkPoint (- 1) (- 3) 3) (ite (< i 21) (mkPoint (- 3) 1 3) (mkPoint (- 3) (- 1) 3)))))) (ite (< i 33) (ite (< i 27) (ite (< i 24) (ite (< i 23) (mkPoint 3 (- 1) 3) (mkPoint 3 1 3)) (ite (< i 25) (mkPoint (- 2) 2 3) (ite (< i 26) (mkPoint 2 (- 2) 3) (mkPoint 2 2 3)))) (ite (< i 30) (ite (< i 28) (mkPoint (- 2) (- 2) 3) (ite (< i 29) (mkPoint 0 0 4) (mkPoint 0 6 4))) (ite (< i 31) (mkPoint 0 (- 6) 4) (ite (< i 32) (mkPoint (- 6) 0 4) (mkPoint 6 0 4))))) (ite (< i 38) (ite (< i 35) (ite (< i 34) (mkPoint (- 2) 4 4) (mkPoint (- 1) 5 4)) (ite (< i 36) (mkPoint 1 5 4) (ite (< i 37) (mkPoint 2 4 4) (mkPoint 2 (- 4) 4)))) (ite (< i 41) (ite (< i 39) (mkPoint 1 (- 5) 4) (ite (< i 40) (mkPoint (- 2) (- 4) 4) (mkPoint (- 1) (- 5) 4))) (ite (< i 42) (mkPoint (- 4) 2 4) (ite (< i 43) (mkPoint (- 5) 1 4) (mkPoint (- 5) (- 1) 4))))))) (ite (< i 66) (ite (< i 55) (ite (< i 49) (ite (< i 46) (ite (< i 45) (mkPoint (- 4) (- 2) 4) (mkPoint 4 2 4)) (ite (< i 47) (mkPoint 5 1 4) (ite (< i 48) (mkPoint 5 (- 1) 4) (mkPoint 4 (- 2) 4)))) (ite (< i 52) (ite (< i 50) (mkPoint (- 3) 3 4) (ite (< i 51) (mkPoint 3 (- 3) 4) (mkPoint 3 3 4))) (ite (< i 53) (mkPoint (- 3) (- 3) 4) (ite (< i 54) (mkPoint 0 0 5) (mkPoint 0 8 5))))) (ite (< i 60) (ite (< i 57) (ite (< i 56) (mkPoint 0 (- 8) 5) (mkPoint (- 8) 0 5)) (ite (< i 58) (mkPoint 8 0 5) (ite (< i 59) (mkPoint 1 7 5) (mkPoint 2 6 5)))) (ite (< i 63) (ite (< i 61) (mkPoint 3 5 5) (ite (< i 62) (mkPoint (- 2) 6 5) (mkPoint (- 3) 5 5))) (ite (< i 64) (mkPoint (- 1) 7 5) (ite (< i 65) (mkPoint 3 (- 5) 5) (mkPoint 2 (- 6) 5)))))) (ite (< i 77) (ite (< i 71) (ite (< i 68) (ite (< i 67) (mkPoint 1 (- 7) 5) (mkPoint (- 2) (- 6) 5)) (ite (< i 69) (mkPoint (- 3) (- 5) 5) (ite (< i 70) (mkPoint (- 1) (- 7) 5) (mkPoint (- 6) 2 5)))) (ite (< i 74) (ite (< i 72) (mkPoint (- 5) 3 5) (ite (< i 73) (mkPoint (- 7) 1 5) (mkPoint (- 7) (- 1) 5))) (ite (< i 75) (mkPoint (- 6) (- 2) 5) (ite (< i 76) (mkPoint (- 5) (- 3) 5) (mkPoint 6 2 5))))) (ite (< i 82) (ite (< i 79) (ite (< i 78) (mkPoint 5 3 5) (mkPoint 7 1 5)) (ite (< i 80) (mkPoint 6 (- 2) 5) (ite (< i 81) (mkPoint 5 (- 3) 5) (mkPoint 7 (- 1) 5)))) (ite (< i 85) (ite (< i 83) (mkPoint (- 4) 4 5) (ite (< i 84) (mkPoint 4 (- 4) 5) (mkPoint 4 4 5))) (ite (< i 86) (mkPoint (- 4) (- 4) 5) (ite (< i 87) (mkPoint 0 0 6) (mkPoint 0 10 6)))))))) (ite (< i 132) (ite (< i 110) (ite (< i 99) (ite (< i 93) (ite (< i 90) (ite (< i 89) (mkPoint 0 (- 10) 6) (mkPoint (- 10) 0 6)) (ite (< i 91) (mkPoint 10 0 6) (ite (< i 92) (mkPoint 3 7 6) (mkPoint (- 3) 7 6)))) (ite (< i 96) (ite (< i 94) (mkPoint 4 6 6) (ite (< i 95) (mkPoint (- 4) 6 6) (mkPoint 2 8 6))) (ite (< i 97) (mkPoint (- 2) 8 6) (ite (< i 98) (mkPoint 1 9 6) (mkPoint (- 1) 9 6))))) (ite (< i 104) (ite (< i 101) (ite (< i 100) (mkPoint 3 (- 7) 6) (mkPoint (- 3) (- 7) 6)) (ite (< i 102) (mkPoint 4 (- 6) 6) (ite (< i 103) (mkPoint (- 4) (- 6) 6) (mkPoint 2 (- 8) 6)))) (ite (< i 107) (ite (< i 105) (mkPoint (- 2) (- 8) 6) (ite (< i 106) (mkPoint 1 (- 9) 6) (mkPoint (- 1) (- 9) 6))) (ite (< i 108) (mkPoint (- 6) 4 6) (ite (< i 109) (mkPoint (- 6) (- 4) 6) (mkPoint (- 7) 3 6)))))) (ite (< i 121) (ite (< i 115) (ite (< i 112) (ite (< i 111) (mkPoint (- 7) (- 3) 6) (mkPoint (- 8) 2 6)) (ite (< i 113) (mkPoint (- 8) (- 2) 6) (ite (< i 114) (mkPoint (- 9) 1 6) (mkPoint (- 9) (- 1) 6)))) (ite (< i 118) (ite (< i 116) (mkPoint 6 4 6) (ite (< i 117) (mkPoint 6 (- 4) 6) (mkPoint 7 3 6))) (ite (< i 119) (mkPoint 7 (- 3) 6) (ite (< i 120) (mkPoint 8 2 6) (mkPoint 8 (- 2) 6))))) (ite (< i 126) (ite (< i 123) (ite (< i 122) (mkPoint 9 1 6) (mkPoint 9 (- 1) 6)) (ite (< i 124) (mkPoint (- 5) 5 6) (ite (< i 125) (mkPoint 5 (- 5) 6) (mkPoint 5 5 6)))) (ite (< i 129) (ite (< i 127) (mkPoint (- 5) (- 5) 6) (ite (< i 128) (mkPoint 0 0 7) (mkPoint 0 12 7))) (ite (< i 130) (mkPoint 0 (- 12) 7) (ite (< i 131) (mkPoint (- 12) 0 7) (mkPoint 12 0 7))))))) (ite (< i 154) (ite (< i 143) (ite (< i 137) (ite (< i 134) (ite (< i 133) (mkPoint 2 10 7) (mkPoint (- 2) 10 7)) (ite (< i 135) (mkPoint 4 8 7) (ite (< i 136) (mkPoint (- 4) 8 7) (mkPoint 1 11 7)))) (ite (< i 140) (ite (< i 138) (mkPoint (- 1) 11 7) (ite (< i 139) (mkPoint 3 9 7) (mkPoint (- 3) 9 7))) (ite (< i 141) (mkPoint 5 7 7) (ite (< i 142) (mkPoint (- 5) 7 7) (mkPoint 2 (- 10) 7))))) (ite (< i 148) (ite (< i 145) (ite (< i 144) (mkPoint (- 2) (- 10) 7) (mkPoint 4 (- 8) 7)) (ite (< i 146) (mkPoint (- 4) (- 8) 7) (ite (< i 147) (mkPoint 1 (- 11) 7) (mkPoint (- 1) (- 11) 7)))) (ite (< i 151) (ite (< i 149) (mkPoint 3 (- 9) 7) (ite (< i 150) (mkPoint (- 3) (- 9) 7) (mkPoint 5 (- 7) 7))) (ite (< i 152) (mkPoint (- 5) (- 7) 7) (ite (< i 153) (mkPoint (- 10) 2 7) (mkPoint (- 10) (- 2) 7)))))) (ite (< i 165) (ite (< i 159) (ite (< i 156) (ite (< i 155) (mkPoint (- 8) 4 7) (mkPoint (- 8) (- 4) 7)) (ite (< i 157) (mkPoint (- 11) 1 7) (ite (< i 158) (mkPoint (- 11) (- 1) 7) (mkPoint (- 9) 3 7)))) (ite (< i 162) (ite (< i 160) (mkPoint (- 9) (- 3) 7) (ite (< i 161) (mkPoint (- 7) 5 7) (mkPoint (- 7) (- 5) 7))) (ite (< i 163) (mkPoint 10 2 7) (ite (< i 164) (mkPoint 10 (- 2) 7) (mkPoint 8 4 7))))) (ite (< i 170) (ite (< i 167) (ite (< i 166) (mkPoint 8 (- 4) 7) (mkPoint 11 1 7)) (ite (< i 168) (mkPoint 11 (- 1) 7) (ite (< i 169) (mkPoint 9 3 7) (mkPoint 9 (- 3) 7)))) (ite (< i 173) (ite (< i 171) (mkPoint 7 5 7) (ite (< i 172) (mkPoint 7 (- 5) 7) (mkPoint (- 6) 6 7))) (ite (< i 174) (mkPoint 6 (- 6) 7) (ite (< i 175) (mkPoint 6 6 7) (mkPoint (- 6) (- 6) 7))))))))))

(define-fun lexiconIndexOfPoint ((p CoreAffectPoint)) Int
  (let ((x (pt_x p)) (y (pt_y p)) (z (pt_z p)))
    (ite (= z 0) (ite (and (= x 0) (= y 0)) 0 (- 1)) (ite (= z 1) (ite (and (= x 0) (= y 0)) 1 (- 1)) (ite (= z 2) (ite (or (< x 0) (and (= x 0) (< y 0))) (ite (or (< x (- 1)) (and (= x (- 1)) (< y 1))) (ite (or (< x (- 1)) (and (= x (- 1)) (< y (- 1)))) (ite (and (= x (- 2)) (= y 0)) 5 (- 1)) (ite (and (= x (- 1)) (= y (- 1))) 10 (- 1))) (ite (or (< x 0) (and (= x 0) (< y (- 2)))) (ite (and (= x (- 1)) (= y 1)) 7 (- 1)) (ite (and (= x 0) (= y (- 2))) 4 (- 1)))) (ite (or (< x 1) (and (= x 1) (< y (- 1)))) (ite (or (< x 0) (and (= x 0) (< y 2))) (ite (and (= x 0) (= y 0)) 2 (- 1)) (ite (and (= x 0) (= y 2)) 3 (- 1))) (ite (or (< x 1) (and (= x 1) (< y 1))) (ite (and (= x 1) (= y (- 1))) 8 (- 1)) (ite (or (< x 2) (and (= x 2) (< y 0))) (ite (and (= x 1) (= y 1)) 9 (- 1)) (ite (and (= x 2) (= y 0)) 6 (- 1)))))) (ite (= z 3) (ite (or (< x 0) (and (= x 0) (< y 0))) (ite (or (< x (- 2)) (and (= x (- 2)) (< y 2))) (ite (or (< x (- 3)) (and (= x (- 3)) (< y 1))) (ite (or (< x (- 3)) (and (= x (- 3)) (< y (- 1)))) (ite (and (= x (- 4)) (= y 0)) 14 (- 1)) (ite (and (= x (- 3)) (= y (- 1))) 21 (- 1))) (ite (or (< x (- 2)) (and (= x (- 2)) (< y (- 2)))) (ite (and (= x (- 3)) (= y 1)) 20 (- 1)) (ite (and (= x (- 2)) (= y (- 2))) 27 (- 1)))) (ite (or (< x (- 1)) (and (= x (- 1)) (< y 3))) (ite (or (< x (- 1)) (and (= x (- 1)) (< y (- 3)))) (ite (and (= x (- 2)) (= y 2)) 24 (- 1)) (ite (and (= x (- 1)) (= y (- 3))) 19 (- 1))) (ite (or (< x 0) (and (= x 0) (< y (- 4)))) (ite (and (= x (- 1)) (= y 3)) 16 (- 1)) (ite (and (= x 0) (= y (- 4))) 13 (- 1))))) (ite (or (< x 2) (and (= x 2) (< y (- 2)))) (ite (or (< x 1) (and (= x 1) (< y (- 3)))) (ite (or (< x 0) (and (= x 0) (< y 4))) (ite (and (= x 0) (= y 0)) 11 (- 1)) (ite (and (= x 0) (= y 4)) 12 (- 1))) (ite (or (< x 1) (and (= x 1) (< y 3))) (ite (and (= x 1) (= y (- 3))) 18 (- 1)) (ite (and (= x 1) (= y 3)) 17 (- 1)))) (ite (or (< x 3) (and (= x 3) (< y (- 1)))) (ite (or (< x 2) (and (= x 2) (< y 2))) (ite (and (= x 2) (= y (- 2))) 25 (- 1)) (ite (and (= x 2) (= y 2)) 26 (- 1))) (ite (or (< x 3) (and (= x 3) (< y 1))) (ite (and (= x 3) (= y (- 1))) 22 (- 1)) (ite (or (< x 4) (and (= x 4) (< y 0))) (ite (and (= x 3) (= y 1)) 23 (- 1)) (ite (and (= x 4) (= y 0)) 15 (- 1))))))) (ite (= z 4) (ite (or (< x 0) (and (= x 0) (< y 0))) (ite (or (< x (- 3)) (and (= x (- 3)) (< y 3))) (ite (or (< x (- 4)) (and (= x (- 4)) (< y (- 2)))) (ite (or (< x (- 5)) (and (= x (- 5)) (< y (- 1)))) (ite (and (= x (- 6)) (= y 0)) 31 (- 1)) (ite (or (< x (- 5)) (and (= x (- 5)) (< y 1))) (ite (and (= x (- 5)) (= y (- 1))) 43 (- 1)) (ite (and (= x (- 5)) (= y 1)) 42 (- 1)))) (ite (or (< x (- 4)) (and (= x (- 4)) (< y 2))) (ite (and (= x (- 4)) (= y (- 2))) 44 (- 1)) (ite (or (< x (- 3)) (and (= x (- 3)) (< y (- 3)))) (ite (and (= x (- 4)) (= y 2)) 41 (- 1)) (ite (and (= x (- 3)) (= y (- 3))) 52 (- 1))))) (ite (or (< x (- 1)) (and (= x (- 1)) (< y (- 5)))) (ite (or (< x (- 2)) (and (= x (- 2)) (< y (- 4)))) (ite (and (= x (- 3)) (= y 3)) 49 (- 1)) (ite (or (< x (- 2)) (and (= x (- 2)) (< y 4))) (ite (and (= x (- 2)) (= y (- 4))) 39 (- 1)) (ite (and (= x (- 2)) (= y 4)) 33 (- 1)))) (ite (or (< x (- 1)) (and (= x (- 1)) (< y 5))) (ite (and (= x (- 1)) (= y (- 5))) 40 (- 1)) (ite (or (< x 0) (and (= x 0) (< y (- 6)))) (ite (and (= x (- 1)) (= y 5)) 34 (- 1)) (ite (and (= x 0) (= y (- 6))) 30 (- 1)))))) (ite (or (< x 3) (and (= x 3) (< y (- 3)))) (ite (or (< x 1) (and (= x 1) (< y 5))) (ite (or (< x 0) (and (= x 0) (< y 6))) (ite (and (= x 0) (= y 0)) 28 (- 1)) (ite (or (< x 1) (and (= x 1) (< y (- 5)))) (ite (and (= x 0) (= y 6)) 29 (- 1)) (ite (and (= x 1) (= y (- 5))) 38 (- 1)))) (ite (or (< x 2) (and (= x 2) (< y (- 4)))) (ite (and (= x 1) (= y 5)) 35 (- 1)) (ite (or (< x 2) (and (= x 2) (< y 4))) (ite (and (= x 2) (= y (- 4))) 37 (- 1)) (ite (and (= x 2) (= y 4)) 36 (- 1))))) (ite (or (< x 4) (and (= x 4) (< y 2))) (ite (or (< x 3) (and (= x 3) (< y 3))) (ite (and (= x 3) (= y (- 3))) 50 (- 1)) (ite (or (< x 4) (and (= x 4) (< y (- 2)))) (ite (and (= x 3) (= y 3)) 51 (- 1)) (ite (and (= x 4) (= y (- 2))) 48 (- 1)))) (ite (or (< x 5) (and (= x 5) (< y 1))) (ite (or (< x 5) (and (= x 5) (< y (- 1)))) (ite (and (= x 4) (= y 2)) 45 (- 1)) (ite (and (= x 5) (= y (- 1))) 47 (- 1))) (ite (or (< x 6) (and (= x 6) (< y 0))) (ite (and (= x 5) (= y 1)) 46 (- 1)) (ite (and (= x 6) (= y 0)) 32 (- 1))))))) (ite (= z 5) (ite (or (< x 0) (and (= x 0) (< y 0))) (ite (or (< x (- 4)) (and (= x (- 4)) (< y 4))) (ite (or (< x (- 6)) (and (= x (- 6)) (< y 2))) (ite (or (< x (- 7)) (and (= x (- 7)) (< y 1))) (ite (or (< x (- 7)) (and (= x (- 7)) (< y (- 1)))) (ite (and (= x (- 8)) (= y 0)) 56 (- 1)) (ite (and (= x (- 7)) (= y (- 1))) 73 (- 1))) (ite (or (< x (- 6)) (and (= x (- 6)) (< y (- 2)))) (ite (and (= x (- 7)) (= y 1)) 72 (- 1)) (ite (and (= x (- 6)) (= y (- 2))) 74 (- 1)))) (ite (or (< x (- 5)) (and (= x (- 5)) (< y 3))) (ite (or (< x (- 5)) (and (= x (- 5)) (< y (- 3)))) (ite (and (= x (- 6)) (= y 2)) 70 (- 1)) (ite (and (= x (- 5)) (= y (- 3))) 75 (- 1))) (ite (or (< x (- 4)) (and (= x (- 4)) (< y (- 4)))) (ite (and (= x (- 5)) (= y 3)) 71 (- 1)) (ite (and (= x (- 4)) (= y (- 4))) 85 (- 1))))) (ite (or (< x (- 2)) (and (= x (- 2)) (< y 6))) (ite (or (< x (- 3)) (and (= x (- 3)) (< y 5))) (ite (or (< x (- 3)) (and (= x (- 3)) (< y (- 5)))) (ite (and (= x (- 4)) (= y 4)) 82 (- 1)) (ite (and (= x (- 3)) (= y (- 5))) 68 (- 1))) (ite (or (< x (- 2)) (and (= x (- 2)) (< y (- 6)))) (ite (and (= x (- 3)) (= y 5)) 62 (- 1)) (ite (and (= x (- 2)) (= y (- 6))) 67 (- 1)))) (ite (or (< x (- 1)) (and (= x (- 1)) (< y 7))) (ite (or (< x (- 1)) (and (= x (- 1)) (< y (- 7)))) (ite (and (= x (- 2)) (= y 6)) 61 (- 1)) (ite (and (= x (- 1)) (= y (- 7))) 69 (- 1))) (ite (or (< x 0) (and (= x 0) (< y (- 8)))) (ite (and (= x (- 1)) (= y 7)) 63 (- 1)) (ite (and (= x 0) (= y (- 8))) 55 (- 1)))))) (ite (or (< x 4) (and (= x 4) (< y (- 4)))) (ite (or (< x 2) (and (= x 2) (< y (- 6)))) (ite (or (< x 1) (and (= x 1) (< y (- 7)))) (ite (or (< x 0) (and (= x 0) (< y 8))) (ite (and (= x 0) (= y 0)) 53 (- 1)) (ite (and (= x 0) (= y 8)) 54 (- 1))) (ite (or (< x 1) (and (= x 1) (< y 7))) (ite (and (= x 1) (= y (- 7))) 66 (- 1)) (ite (and (= x 1) (= y 7)) 58 (- 1)))) (ite (or (< x 3) (and (= x 3) (< y (- 5)))) (ite (or (< x 2) (and (= x 2) (< y 6))) (ite (and (= x 2) (= y (- 6))) 65 (- 1)) (ite (and (= x 2) (= y 6)) 59 (- 1))) (ite (or (< x 3) (and (= x 3) (< y 5))) (ite (and (= x 3) (= y (- 5))) 64 (- 1)) (ite (and (= x 3) (= y 5)) 60 (- 1))))) (ite (or (< x 6) (and (= x 6) (< y (- 2)))) (ite (or (< x 5) (and (= x 5) (< y (- 3)))) (ite (or (< x 4) (and (= x 4) (< y 4))) (ite (and (= x 4) (= y (- 4))) 83 (- 1)) (ite (and (= x 4) (= y 4)) 84 (- 1))) (ite (or (< x 5) (and (= x 5) (< y 3))) (ite (and (= x 5) (= y (- 3))) 80 (- 1)) (ite (and (= x 5) (= y 3)) 77 (- 1)))) (ite (or (< x 7) (and (= x 7) (< y (- 1)))) (ite (or (< x 6) (and (= x 6) (< y 2))) (ite (and (= x 6) (= y (- 2))) 79 (- 1)) (ite (and (= x 6) (= y 2)) 76 (- 1))) (ite (or (< x 7) (and (= x 7) (< y 1))) (ite (and (= x 7) (= y (- 1))) 81 (- 1)) (ite (or (< x 8) (and (= x 8) (< y 0))) (ite (and (= x 7) (= y 1)) 78 (- 1)) (ite (and (= x 8) (= y 0)) 57 (- 1)))))))) (ite (= z 6) (ite (or (< x 0) (and (= x 0) (< y 0))) (ite (or (< x (- 5)) (and (= x (- 5)) (< y 5))) (ite (or (< x (- 7)) (and (= x (- 7)) (< y (- 3)))) (ite (or (< x (- 9)) (and (= x (- 9)) (< y 1))) (ite (or (< x (- 9)) (and (= x (- 9)) (< y (- 1)))) (ite (and (= x (- 10)) (= y 0)) 89 (- 1)) (ite (and (= x (- 9)) (= y (- 1))) 114 (- 1))) (ite (or (< x (- 8)) (and (= x (- 8)) (< y (- 2)))) (ite (and (= x (- 9)) (= y 1)) 113 (- 1)) (ite (or (< x (- 8)) (and (= x (- 8)) (< y 2))) (ite (and (= x (- 8)) (= y (- 2))) 112 (- 1)) (ite (and (= x (- 8)) (= y 2)) 111 (- 1))))) (ite (or (< x (- 6)) (and (= x (- 6)) (< y (- 4)))) (ite (or (< x (- 7)) (and (= x (- 7)) (< y 3))) (ite (and (= x (- 7)) (= y (- 3))) 110 (- 1)) (ite (and (= x (- 7)) (= y 3)) 109 (- 1))) (ite (or (< x (- 6)) (and (= x (- 6)) (< y 4))) (ite (and (= x (- 6)) (= y (- 4))) 108 (- 1)) (ite (or (< x (- 5)) (and (= x (- 5)) (< y (- 5)))) (ite (and (= x (- 6)) (= y 4)) 107 (- 1)) (ite (and (= x (- 5)) (= y (- 5))) 126 (- 1)))))) (ite (or (< x (- 2)) (and (= x (- 2)) (< y (- 8)))) (ite (or (< x (- 4)) (and (= x (- 4)) (< y 6))) (ite (or (< x (- 4)) (and (= x (- 4)) (< y (- 6)))) (ite (and (= x (- 5)) (= y 5)) 123 (- 1)) (ite (and (= x (- 4)) (= y (- 6))) 102 (- 1))) (ite (or (< x (- 3)) (and (= x (- 3)) (< y (- 7)))) (ite (and (= x (- 4)) (= y 6)) 94 (- 1)) (ite (or (< x (- 3)) (and (= x (- 3)) (< y 7))) (ite (and (= x (- 3)) (= y (- 7))) 100 (- 1)) (ite (and (= x (- 3)) (= y 7)) 92 (- 1))))) (ite (or (< x (- 1)) (and (= x (- 1)) (< y (- 9)))) (ite (or (< x (- 2)) (and (= x (- 2)) (< y 8))) (ite (and (= x (- 2)) (= y (- 8))) 104 (- 1)) (ite (and (= x (- 2)) (= y 8)) 96 (- 1))) (ite (or (< x (- 1)) (and (= x (- 1)) (< y 9))) (ite (and (= x (- 1)) (= y (- 9))) 106 (- 1)) (ite (or (< x 0) (and (= x 0) (< y (- 10)))) (ite (and (= x (- 1)) (= y 9)) 98 (- 1)) (ite (and (= x 0) (= y (- 10))) 88 (- 1))))))) (ite (or (< x 5) (and (= x 5) (< y (- 5)))) (ite (or (< x 2) (and (= x 2) (< y 8))) (ite (or (< x 1) (and (= x 1) (< y (- 9)))) (ite (or (< x 0) (and (= x 0) (< y 10))) (ite (and (= x 0) (= y 0)) 86 (- 1)) (ite (and (= x 0) (= y 10)) 87 (- 1))) (ite (or (< x 1) (and (= x 1) (< y 9))) (ite (and (= x 1) (= y (- 9))) 105 (- 1)) (ite (or (< x 2) (and (= x 2) (< y (- 8)))) (ite (and (= x 1) (= y 9)) 97 (- 1)) (ite (and (= x 2) (= y (- 8))) 103 (- 1))))) (ite (or (< x 3) (and (= x 3) (< y 7))) (ite (or (< x 3) (and (= x 3) (< y (- 7)))) (ite (and (= x 2) (= y 8)) 95 (- 1)) (ite (and (= x 3) (= y (- 7))) 99 (- 1))) (ite (or (< x 4) (and (= x 4) (< y (- 6)))) (ite (and (= x 3) (= y 7)) 91 (- 1)) (ite (or (< x 4) (and (= x 4) (< y 6))) (ite (and (= x 4) (= y (- 6))) 101 (- 1)) (ite (and (= x 4) (= y 6)) 93 (- 1)))))) (ite (or (< x 7) (and (= x 7) (< y 3))) (ite (or (< x 6) (and (= x 6) (< y (- 4)))) (ite (or (< x 5) (and (= x 5) (< y 5))) (ite (and (= x 5) (= y (- 5))) 124 (- 1)) (ite (and (= x 5) (= y 5)) 125 (- 1))) (ite (or (< x 6) (and (= x 6) (< y 4))) (ite (and (= x 6) (= y (- 4))) 116 (- 1)) (ite (or (< x 7) (and (= x 7) (< y (- 3)))) (ite (and (= x 6) (= y 4)) 115 (- 1)) (ite (and (= x 7) (= y (- 3))) 118 (- 1))))) (ite (or (< x 9) (and (= x 9) (< y (- 1)))) (ite (or (< x 8) (and (= x 8) (< y (- 2)))) (ite (and (= x 7) (= y 3)) 117 (- 1)) (ite (or (< x 8) (and (= x 8) (< y 2))) (ite (and (= x 8) (= y (- 2))) 120 (- 1)) (ite (and (= x 8) (= y 2)) 119 (- 1)))) (ite (or (< x 9) (and (= x 9) (< y 1))) (ite (and (= x 9) (= y (- 1))) 122 (- 1)) (ite (or (< x 10) (and (= x 10) (< y 0))) (ite (and (= x 9) (= y 1)) 121 (- 1)) (ite (and (= x 10) (= y 0)) 90 (- 1)))))))) (ite (= z 7) (ite (or (< x 0) (and (= x 0) (< y 0))) (ite (or (< x (- 6)) (and (= x (- 6)) (< y 6))) (ite (or (< x (- 9)) (and (= x (- 9)) (< y 3))) (ite (or (< x (- 10)) (and (= x (- 10)) (< y (- 2)))) (ite (or (< x (- 11)) (and (= x (- 11)) (< y (- 1)))) (ite (and (= x (- 12)) (= y 0)) 130 (- 1)) (ite (or (< x (- 11)) (and (= x (- 11)) (< y 1))) (ite (and (= x (- 11)) (= y (- 1))) 157 (- 1)) (ite (and (= x (- 11)) (= y 1)) 156 (- 1)))) (ite (or (< x (- 10)) (and (= x (- 10)) (< y 2))) (ite (and (= x (- 10)) (= y (- 2))) 153 (- 1)) (ite (or (< x (- 9)) (and (= x (- 9)) (< y (- 3)))) (ite (and (= x (- 10)) (= y 2)) 152 (- 1)) (ite (and (= x (- 9)) (= y (- 3))) 159 (- 1))))) (ite (or (< x (- 7)) (and (= x (- 7)) (< y (- 5)))) (ite (or (< x (- 8)) (and (= x (- 8)) (< y (- 4)))) (ite (and (= x (- 9)) (= y 3)) 158 (- 1)) (ite (or (< x (- 8)) (and (= x (- 8)) (< y 4))) (ite (and (= x (- 8)) (= y (- 4))) 155 (- 1)) (ite (and (= x (- 8)) (= y 4)) 154 (- 1)))) (ite (or (< x (- 7)) (and (= x (- 7)) (< y 5))) (ite (and (= x (- 7)) (= y (- 5))) 161 (- 1)) (ite (or (< x (- 6)) (and (= x (- 6)) (< y (- 6)))) (ite (and (= x (- 7)) (= y 5)) 160 (- 1)) (ite (and (= x (- 6)) (= y (- 6))) 175 (- 1)))))) (ite (or (< x (- 3)) (and (= x (- 3)) (< y 9))) (ite (or (< x (- 4)) (and (= x (- 4)) (< y (- 8)))) (ite (or (< x (- 5)) (and (= x (- 5)) (< y (- 7)))) (ite (and (= x (- 6)) (= y 6)) 172 (- 1)) (ite (or (< x (- 5)) (and (= x (- 5)) (< y 7))) (ite (and (= x (- 5)) (= y (- 7))) 151 (- 1)) (ite (and (= x (- 5)) (= y 7)) 141 (- 1)))) (ite (or (< x (- 4)) (and (= x (- 4)) (< y 8))) (ite (and (= x (- 4)) (= y (- 8))) 145 (- 1)) (ite (or (< x (- 3)) (and (= x (- 3)) (< y (- 9)))) (ite (and (= x (- 4)) (= y 8)) 135 (- 1)) (ite (and (= x (- 3)) (= y (- 9))) 149 (- 1))))) (ite (or (< x (- 1)) (and (= x (- 1)) (< y (- 11)))) (ite (or (< x (- 2)) (and (= x (- 2)) (< y (- 10)))) (ite (and (= x (- 3)) (= y 9)) 139 (- 1)) (ite (or (< x (- 2)) (and (= x (- 2)) (< y 10))) (ite (and (= x (- 2)) (= y (- 10))) 143 (- 1)) (ite (and (= x (- 2)) (= y 10)) 133 (- 1)))) (ite (or (< x (- 1)) (and (= x (- 1)) (< y 11))) (ite (and (= x (- 1)) (= y (- 11))) 147 (- 1)) (ite (or (< x 0) (and (= x 0) (< y (- 12)))) (ite (and (= x (- 1)) (= y 11)) 137 (- 1)) (ite (and (= x 0) (= y (- 12))) 129 (- 1))))))) (ite (or (< x 6) (and (= x 6) (< y (- 6)))) (ite (or (< x 3) (and (= x 3) (< y (- 9)))) (ite (or (< x 1) (and (= x 1) (< y 11))) (ite (or (< x 0) (and (= x 0) (< y 12))) (ite (and (= x 0) (= y 0)) 127 (- 1)) (ite (or (< x 1) (and (= x 1) (< y (- 11)))) (ite (and (= x 0) (= y 12)) 128 (- 1)) (ite (and (= x 1) (= y (- 11))) 146 (- 1)))) (ite (or (< x 2) (and (= x 2) (< y (- 10)))) (ite (and (= x 1) (= y 11)) 136 (- 1)) (ite (or (< x 2) (and (= x 2) (< y 10))) (ite (and (= x 2) (= y (- 10))) 142 (- 1)) (ite (and (= x 2) (= y 10)) 132 (- 1))))) (ite (or (< x 4) (and (= x 4) (< y 8))) (ite (or (< x 3) (and (= x 3) (< y 9))) (ite (and (= x 3) (= y (- 9))) 148 (- 1)) (ite (or (< x 4) (and (= x 4) (< y (- 8)))) (ite (and (= x 3) (= y 9)) 138 (- 1)) (ite (and (= x 4) (= y (- 8))) 144 (- 1)))) (ite (or (< x 5) (and (= x 5) (< y (- 7)))) (ite (and (= x 4) (= y 8)) 134 (- 1)) (ite (or (< x 5) (and (= x 5) (< y 7))) (ite (and (= x 5) (= y (- 7))) 150 (- 1)) (ite (and (= x 5) (= y 7)) 140 (- 1)))))) (ite (or (< x 9) (and (= x 9) (< y (- 3)))) (ite (or (< x 7) (and (= x 7) (< y 5))) (ite (or (< x 6) (and (= x 6) (< y 6))) (ite (and (= x 6) (= y (- 6))) 173 (- 1)) (ite (or (< x 7) (and (= x 7) (< y (- 5)))) (ite (and (= x 6) (= y 6)) 174 (- 1)) (ite (and (= x 7) (= y (- 5))) 171 (- 1)))) (ite (or (< x 8) (and (= x 8) (< y (- 4)))) (ite (and (= x 7) (= y 5)) 170 (- 1)) (ite (or (< x 8) (and (= x 8) (< y 4))) (ite (and (= x 8) (= y (- 4))) 165 (- 1)) (ite (and (= x 8) (= y 4)) 164 (- 1))))) (ite (or (< x 10) (and (= x 10) (< y 2))) (ite (or (< x 9) (and (= x 9) (< y 3))) (ite (and (= x 9) (= y (- 3))) 169 (- 1)) (ite (or (< x 10) (and (= x 10) (< y (- 2)))) (ite (and (= x 9) (= y 3)) 168 (- 1)) (ite (and (= x 10) (= y (- 2))) 163 (- 1)))) (ite (or (< x 11) (and (= x 11) (< y 1))) (ite (or (< x 11) (and (= x 11) (< y (- 1)))) (ite (and (= x 10) (= y 2)) 162 (- 1)) (ite (and (= x 11) (= y (- 1))) 167 (- 1))) (ite (or (< x 12) (and (= x 12) (< y 0))) (ite (and (= x 11) (= y 1)) 166 (- 1)) (ite (and (= x 12) (= y 0)) 131 (- 1)))))))) (- 1)))))))))))

(define-fun lexiconEntry ((i Int)) LexiconEntry
  (mkLexiconEntry (lexiconLabel i) (lexiconPoint i)))

; -----------------------------------------------------------------------------
; 3. Definitions canoniques de EndToEndBridge
; -----------------------------------------------------------------------------
(define-fun couplingToContingency ((c EngineCoupling)) OptionContingency
  (let ((a (ec_attente c)) (ctrl (ec_controle c)))
    (ite (and (= a Pol_pos) (= ctrl Pol_pos)) (OC_some (mkOperantContingency OE_Reinforcement OO_Addition))
    (ite (and (= a Pol_pos) (= ctrl Pol_neg)) (OC_some (mkOperantContingency OE_Reinforcement OO_Removal))
    (ite (and (= a Pol_neg) (= ctrl Pol_neg)) (OC_some (mkOperantContingency OE_Punishment    OO_Addition))
    (ite (and (= a Pol_neg) (= ctrl Pol_pos)) (OC_some (mkOperantContingency OE_Punishment    OO_Removal))
    OC_none))))))

(define-fun quadrantContingency ((x Int) (y Int)) OptionContingency
  (ite (and (> x 0) (> y 0)) (OC_some (mkOperantContingency OE_Reinforcement OO_Addition))
  (ite (and (> x 0) (< y 0)) (OC_some (mkOperantContingency OE_Reinforcement OO_Removal))
  (ite (and (< x 0) (< y 0)) (OC_some (mkOperantContingency OE_Punishment    OO_Addition))
  (ite (and (< x 0) (> y 0)) (OC_some (mkOperantContingency OE_Punishment    OO_Removal))
  OC_none)))))

(define-fun classifyOperantRole ((p CoreAffectPoint)) OperantRole
  (let ((qc (quadrantContingency (pt_x p) (pt_y p)))
        (sec (CoreAffectPoint_dominantSector p)))
    (ite (and (not (= qc OC_none)) (not (= sec OptNone)))
      (OR_blendedLateral (opt_val sec) (oc_val qc))
    (ite (not (= qc OC_none))
      (OR_pureOperant (oc_val qc))
    (ite (not (= sec OptNone))
      (OR_preOperantAxial (opt_val sec))
      OR_centralOperator)))))

(define-fun evaluateUnifiedTaxonomy
    ((p UnifiedDynamicsParams) (c EngineCoupling) (z Int) (rhoHat Int) (kappaHat Int) (susp Bool))
    TaxonomicState
  (evaluateTaxonomyOfPoint (projectUnifiedState p c z rhoHat kappaHat susp)))

(define-fun evaluateCircularTaxonomy ((s CircularCircuitState)) TaxonomicState
  (evaluateTaxonomyOfPoint (op3_crossingI_point s)))

; -----------------------------------------------------------------------------
; 4. Controle de non-vacuite (doit retourner sat)
; -----------------------------------------------------------------------------
(echo "[CONSISTENCY]")
(push)
(declare-const kp CircuitKernelParams)
(declare-const up UnifiedDynamicsParams)
(declare-const s_test PredictiveEngineState)
(declare-const cs_test CircularCircuitState)
(declare-const idx_test Int)
(assert (validCircuitKernelParams kp))
(assert (> (ckp_chi kp) 0))
(assert (> (ckp_qPosC kp) 0))
(assert (< (ckp_qPosC kp) (ckp_scale kp)))
(assert (< (+ (ckp_rho kp) (ckp_deltaA kp)) (ckp_scale kp)))
(assert (validUnifiedDynamicsParams up))
(assert (validEngineState s_test))
(assert (<= (pt_z (projectToCoreAffect s_test)) 7))
(assert (validCircularCircuitState cs_test))
(assert (<= (ai_persistenceDepth (ccs_attentional cs_test)) 5))
(assert (validLexIndex idx_test))
(assert (= (lexiconEntry idx_test) (mkLexiconEntry Lbl_Sublimation (mkPoint 6 6 7))))
(check-sat)
(pop)

; -----------------------------------------------------------------------------
; 5. Lemme auxiliaire d'audit : unicite nominale des 176 etiquettes
; -----------------------------------------------------------------------------
(echo "[AUX] all176Entries_unique_labels")
(push)
(assert (not
  (forall ((i Int) (j Int))
    (=> (and (validLexIndex i) (validLexIndex j) (not (= i j)))
        (not (= (lexiconLabel i) (lexiconLabel j)))))))
(check-sat)
(pop)

; -----------------------------------------------------------------------------
; 6. Audit des 10 theoremes de bout en bout (chaque controle doit retourner unsat)
; -----------------------------------------------------------------------------

; [1/10] circuit_coupling_operant_bridge
(echo "[THM] circuit_coupling_operant_bridge")
(push)
(assert (not
  (forall ((c EngineCoupling) (d Int) (piA Int) (piC Int) (susp Bool))
    (=> (and (>= d 0) (>= piA 0) (>= piC 0))
        (and
          (= (diagToContingency (projectPerceptible c 2 piA piC susp))
             (couplingToContingency c))
          (= (let ((pt (projectPerceptible c (+ d 2) piA piC susp)))
               (quadrantContingency (pt_x pt) (pt_y pt)))
             (couplingToContingency c)))))))
(check-sat)
(pop)

; [2/10] triggerSecondaryGradient_enters_operant
(echo "[THM] triggerSecondaryGradient_enters_operant")
(push)
(assert (not
  (forall ((c EngineCoupling) (newPol Polarity))
    (=> (and (EngineCoupling_isSingleEngaged c) (Polarity_isEngaged newPol))
        (let ((c2 (triggerSecondaryGradient c newPol)))
          (let ((p2 (deployCouplingAtDepth c2 0)))
            (and
              (= (diagToContingency (deployCouplingAtDepth c 0)) OC_none)
              (exists ((oc OperantContingency))
                (and
                  (= (diagToContingency p2) (OC_some oc))
                  (= (couplingToContingency c2) (OC_some oc))
                  (=> (= c (mkEngineCoupling Pol_pos Pol_zero)) (= (oc_effect oc) OE_Reinforcement))
                  (=> (= c (mkEngineCoupling Pol_neg Pol_zero)) (= (oc_effect oc) OE_Punishment))
                  (=> (= c (mkEngineCoupling Pol_zero Pol_pos))
                      (or (= oc (mkOperantContingency OE_Reinforcement OO_Addition))
                          (= oc (mkOperantContingency OE_Punishment OO_Removal))))
                  (=> (= c (mkEngineCoupling Pol_zero Pol_neg))
                      (or (= oc (mkOperantContingency OE_Reinforcement OO_Removal))
                          (= oc (mkOperantContingency OE_Punishment OO_Addition)))))))))))))
(check-sat)
(pop)

; [3/10] p2_markov_contagion_enters_operant_punishment
(echo "[THM] p2_markov_contagion_enters_operant_punishment")
(push)
(assert (not
  (forall ((p CircuitKernelParams))
    (=> (and (validCircuitKernelParams p)
             (> (ckp_chi p) 0)
             (> (ckp_qPosC p) 0) (< (ckp_qPosC p) (ckp_scale p))
             (< (+ (ckp_rho p) (ckp_deltaA p)) (ckp_scale p)))
        (and
          (> (circuitWeight p (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_neg Pol_pos)) 0)
          (> (circuitWeight p (mkEngineCoupling Pol_neg Pol_zero) (mkEngineCoupling Pol_neg Pol_neg)) 0)
          (= (couplingToContingency (mkEngineCoupling Pol_neg Pol_zero)) OC_none)
          (= (couplingToContingency (mkEngineCoupling Pol_neg Pol_pos))
             (OC_some (mkOperantContingency OE_Punishment OO_Removal)))
          (= (couplingToContingency (mkEngineCoupling Pol_neg Pol_neg))
             (OC_some (mkOperantContingency OE_Punishment OO_Addition))))))))
(check-sat)
(pop)

; [4/10] operant_quadrant_lifting_all_strata
(echo "[THM] operant_quadrant_lifting_all_strata")
(push)
(assert (not
  (and
    (forall ((p CoreAffectPoint))
      (=> (and (not (= (pt_x p) 0)) (not (= (pt_y p) 0)))
          (exists ((oc OperantContingency))
            (and
              (= (quadrantContingency (pt_x p) (pt_y p)) (OC_some oc))
              (= (= (oc_effect oc) OE_Reinforcement) (> (pt_x p) 0))
              (= (= (oc_effect oc) OE_Punishment) (< (pt_x p) 0))
              (= (= (oc_op oc) OO_Addition) (> (* (pt_x p) (pt_y p)) 0))
              (= (= (oc_op oc) OO_Removal) (< (* (pt_x p) (pt_y p)) 0))
              (= (= (computeHedonicPolarity (pt_x p) (pt_y p)) Hed_positive)
                 (= (oc_effect oc) OE_Reinforcement))
              (= (= (oc_op oc) OO_Addition)
                 (or (= (computeEnergyRegime (pt_x p) (pt_y p)) ER_positiveSynergy)
                     (= (computeEnergyRegime (pt_x p) (pt_y p)) ER_negativeSynergy)))
              (= (= (oc_op oc) OO_Removal)
                 (or (= (computeEnergyRegime (pt_x p) (pt_y p)) ER_ergotropicCompensation)
                     (= (computeEnergyRegime (pt_x p) (pt_y p)) ER_trophotropicRelease)))))))
    (forall ((q CoreAffectPoint))
      (=> (isZ2DiagonalPoint q)
          (= (quadrantContingency (pt_x q) (pt_y q)) (diagToContingency q)))))))
(check-sat)
(pop)

; [5/10] operant_antagonist_invariance_all_strata
(echo "[THM] operant_antagonist_invariance_all_strata")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (and (not (= (pt_x p) 0)) (not (= (pt_y p) 0)))
        (exists ((c1 OperantContingency) (c2 OperantContingency))
          (and
            (= (quadrantContingency (pt_x p) (pt_y p)) (OC_some c1))
            (= (quadrantContingency (pt_x (antagonistPoint p)) (pt_y (antagonistPoint p)))
               (OC_some c2))
            (not (= (oc_effect c1) (oc_effect c2)))
            (= (oc_op c1) (oc_op c2))))))))
(check-sat)
(pop)

; [6/10] depthKernel_preserves_operant_quadrant
(echo "[THM] depthKernel_preserves_operant_quadrant")
(push)
(assert (not
  (and
    (forall ((p CoreAffectPoint) (q CoreAffectPoint))
      (=> (and (not (= (pt_x p) 0)) (not (= (pt_y p) 0)) (> (canonicalDepthWeight p q) 0))
          (and (not (= (pt_x q) 0))
               (not (= (pt_y q) 0))
               (= (quadrantContingency (pt_x q) (pt_y q))
                  (quadrantContingency (pt_x p) (pt_y p))))))
    (> (canonicalDepthWeight (mkPoint 2 0 2) (mkPoint 2 2 3)) 0)
    (> (canonicalDepthWeight (mkPoint 2 0 2) (mkPoint 2 (- 2) 3)) 0)
    (> (canonicalDepthWeight (mkPoint (- 2) 0 2) (mkPoint (- 2) 2 3)) 0)
    (> (canonicalDepthWeight (mkPoint (- 2) 0 2) (mkPoint (- 2) (- 2) 3)) 0)
    (> (canonicalDepthWeight (mkPoint 0 2 2) (mkPoint 2 2 3)) 0)
    (> (canonicalDepthWeight (mkPoint 0 2 2) (mkPoint (- 2) 2 3)) 0)
    (> (canonicalDepthWeight (mkPoint 0 (- 2) 2) (mkPoint 2 (- 2) 3)) 0)
    (> (canonicalDepthWeight (mkPoint 0 (- 2) 2) (mkPoint (- 2) (- 2) 3)) 0))))
(check-sat)
(pop)

; [7/10] operant_lineages_reach_z7_transcendentals
(echo "[THM] operant_lineages_reach_z7_transcendentals")
(push)
(assert (not
  (and
    ; R+ : Desir (1,1,2) -> ... -> Sublimation (6,6,7)
    (= (canonicalDepthWeight (mkPoint 1 1 2) (mkPoint 2 2 3)) 2)
    (= (canonicalDepthWeight (mkPoint 2 2 3) (mkPoint 3 3 4)) 2)
    (= (canonicalDepthWeight (mkPoint 3 3 4) (mkPoint 4 4 5)) 2)
    (= (canonicalDepthWeight (mkPoint 4 4 5) (mkPoint 5 5 6)) 2)
    (= (canonicalDepthWeight (mkPoint 5 5 6) (mkPoint 6 6 7)) 2)
    (= (classifyOperantRole (mkPoint 6 6 7))
       (OR_pureOperant (mkOperantContingency OE_Reinforcement OO_Addition)))
    (= (classifyStratum 7) TS_z7_sentimentsTranscendants)
    (= (classifyTaxonomicGroup (mkPoint 6 6 7)) TG_groupeDesir)
    (= (classifySubsector 6 6) FS_diagonalDesire)
    (= (lexiconEntry 174) (mkLexiconEntry Lbl_Sublimation (mkPoint 6 6 7)))
    ; R- : Calme (1,-1,2) -> ... -> Impassibilite (6,-6,7)
    (= (canonicalDepthWeight (mkPoint 1 (- 1) 2) (mkPoint 2 (- 2) 3)) 2)
    (= (canonicalDepthWeight (mkPoint 2 (- 2) 3) (mkPoint 3 (- 3) 4)) 2)
    (= (canonicalDepthWeight (mkPoint 3 (- 3) 4) (mkPoint 4 (- 4) 5)) 2)
    (= (canonicalDepthWeight (mkPoint 4 (- 4) 5) (mkPoint 5 (- 5) 6)) 2)
    (= (canonicalDepthWeight (mkPoint 5 (- 5) 6) (mkPoint 6 (- 6) 7)) 2)
    (= (classifyOperantRole (mkPoint 6 (- 6) 7))
       (OR_pureOperant (mkOperantContingency OE_Reinforcement OO_Removal)))
    (= (classifyStratum 7) TS_z7_sentimentsTranscendants)
    (= (classifyTaxonomicGroup (mkPoint 6 (- 6) 7)) TG_groupeCalme)
    (= (classifySubsector 6 (- 6)) FS_diagonalCalm)
    (= (lexiconEntry 173) (mkLexiconEntry Lbl_Impassibilite (mkPoint 6 (- 6) 7)))
    ; P+ : Degout (-1,-1,2) -> ... -> Dissolution (-6,-6,7)
    (= (canonicalDepthWeight (mkPoint (- 1) (- 1) 2) (mkPoint (- 2) (- 2) 3)) 2)
    (= (canonicalDepthWeight (mkPoint (- 2) (- 2) 3) (mkPoint (- 3) (- 3) 4)) 2)
    (= (canonicalDepthWeight (mkPoint (- 3) (- 3) 4) (mkPoint (- 4) (- 4) 5)) 2)
    (= (canonicalDepthWeight (mkPoint (- 4) (- 4) 5) (mkPoint (- 5) (- 5) 6)) 2)
    (= (canonicalDepthWeight (mkPoint (- 5) (- 5) 6) (mkPoint (- 6) (- 6) 7)) 2)
    (= (classifyOperantRole (mkPoint (- 6) (- 6) 7))
       (OR_pureOperant (mkOperantContingency OE_Punishment OO_Addition)))
    (= (classifyStratum 7) TS_z7_sentimentsTranscendants)
    (= (classifyTaxonomicGroup (mkPoint (- 6) (- 6) 7)) TG_groupeDegout)
    (= (classifySubsector (- 6) (- 6)) FS_diagonalDisgust)
    (= (lexiconEntry 175) (mkLexiconEntry Lbl_Dissolution (mkPoint (- 6) (- 6) 7)))
    ; P- : Colere (-1,1,2) -> ... -> Rage (-6,6,7)
    (= (canonicalDepthWeight (mkPoint (- 1) 1 2) (mkPoint (- 2) 2 3)) 2)
    (= (canonicalDepthWeight (mkPoint (- 2) 2 3) (mkPoint (- 3) 3 4)) 2)
    (= (canonicalDepthWeight (mkPoint (- 3) 3 4) (mkPoint (- 4) 4 5)) 2)
    (= (canonicalDepthWeight (mkPoint (- 4) 4 5) (mkPoint (- 5) 5 6)) 2)
    (= (canonicalDepthWeight (mkPoint (- 5) 5 6) (mkPoint (- 6) 6 7)) 2)
    (= (classifyOperantRole (mkPoint (- 6) 6 7))
       (OR_pureOperant (mkOperantContingency OE_Punishment OO_Removal)))
    (= (classifyStratum 7) TS_z7_sentimentsTranscendants)
    (= (classifyTaxonomicGroup (mkPoint (- 6) 6 7)) TG_groupeColere)
    (= (classifySubsector (- 6) 6) FS_diagonalAnger)
    (= (lexiconEntry 172) (mkLexiconEntry Lbl_Rage (mkPoint (- 6) 6 7))))))
(check-sat)
(pop)

; [8/10] unified_circuit_to_taxonomy_coherence
(echo "[THM] unified_circuit_to_taxonomy_coherence")
(push)
(assert (not
  (forall ((p UnifiedDynamicsParams) (c EngineCoupling)
           (z Int) (rhoHat Int) (kappaHat Int) (susp Bool))
    (=> (and (validUnifiedDynamicsParams p) (>= z 0) (>= rhoHat 0) (>= kappaHat 0))
        (let ((ts (evaluateUnifiedTaxonomy p c z rhoHat kappaHat susp)))
          (let ((cp (ams_core (ts_matrix ts)))
                (ap (ams_antagonist (ts_matrix ts))))
            (and
              (isValidCoreAffect cp)
              (isValidCoreAffect ap)
              (= (ts_stratum ts) (classifyStratum (pt_z cp)))
              (matchesTaxonomicGroup cp (ts_group ts))
              (= (FunctionalSubsector_toTaxonomicGroup (ts_subsector ts)) (ts_group ts))
              (= (FunctionalSubsector_toHedonicPolarity (ts_subsector ts)) (ams_valence (ts_matrix ts)))
              (=> (>= z 2) (= (quadrantContingency (pt_x cp) (pt_y cp)) (couplingToContingency c)))
              (=> (<= z 7)
                  (and (<= (pt_z cp) 7) (<= (pt_z ap) 7)
                       (validLexIndex (lexiconIndexOfPoint cp))
                       (= (lexiconPoint (lexiconIndexOfPoint cp)) cp)
                       (validLexIndex (lexiconIndexOfPoint ap))
                       (= (lexiconPoint (lexiconIndexOfPoint ap)) ap))))))))))
(check-sat)
(pop)

; [9/10] circularCycle_to_taxonomy_and_lexicon_coherence
(echo "[THM] circularCycle_to_taxonomy_and_lexicon_coherence")
(push)
(assert (not
  (forall ((s CircularCircuitState))
    (=> (validCircularCircuitState s)
        (let ((ts (evaluateCircularTaxonomy s))
              (c (mkEngineCoupling (op1_subjectiveOut s) (op2_perceptiveOut s))))
          (let ((cp (ams_core (ts_matrix ts)))
                (ap (ams_antagonist (ts_matrix ts))))
            (and
              (isValidCoreAffect cp)
              (isValidCoreAffect ap)
              (matchesTaxonomicGroup cp (ts_group ts))
              (= (FunctionalSubsector_toTaxonomicGroup (ts_subsector ts)) (ts_group ts))
              (= (FunctionalSubsector_toHedonicPolarity (ts_subsector ts)) (ams_valence (ts_matrix ts)))
              (=> (AttentionalInterface_isEngaged (ccs_attentional s))
                  (= (quadrantContingency (pt_x cp) (pt_y cp)) (couplingToContingency c)))
              (=> (<= (ai_persistenceDepth (ccs_attentional s)) 5)
                  (and (<= (pt_z cp) 7)
                       (validLexIndex (lexiconIndexOfPoint cp))
                       (= (lexiconPoint (lexiconIndexOfPoint cp)) cp)
                       (validLexIndex (lexiconIndexOfPoint ap))
                       (= (lexiconPoint (lexiconIndexOfPoint ap)) ap))))))))))
(check-sat)
(pop)

; [10/10] full_end_to_end_lexicon_resolution
(echo "[THM] full_end_to_end_lexicon_resolution")
(push)
(assert (not
  (and
    (forall ((pt CoreAffectPoint))
      (=> (and (isValidCoreAffect pt) (<= (pt_z pt) 7))
          (let ((idx (lexiconIndexOfPoint pt)))
            (and (validLexIndex idx)
                 (= (le_point (lexiconEntry idx)) pt)
                 (forall ((j Int))
                   (=> (and (validLexIndex j) (= (le_point (lexiconEntry j)) pt))
                       (= j idx)))))))
    (forall ((s PredictiveEngineState))
      (=> (and (validEngineState s) (<= (pt_z (projectToCoreAffect s)) 7))
          (let ((ts (runCartograffectPipeline s)))
            (let ((cp (ams_core (ts_matrix ts)))
                  (ap (ams_antagonist (ts_matrix ts))))
              (and
                (isCoherentTerminalState s ts)
                (forall ((ts2 TaxonomicState))
                  (=> (isCoherentTerminalState s ts2) (= ts2 ts)))
                (isValidCoreAffect cp) (<= (pt_z cp) 7)
                (isValidCoreAffect ap) (<= (pt_z ap) 7)
                (validLexIndex (lexiconIndexOfPoint cp))
                (= (le_point (lexiconEntry (lexiconIndexOfPoint cp))) cp)
                (validLexIndex (lexiconIndexOfPoint ap))
                (= (le_point (lexiconEntry (lexiconIndexOfPoint ap))) ap)
                (=> (and (not (= (pt_x cp) 0)) (not (= (pt_y cp) 0)))
                    (exists ((c1 OperantContingency) (c2 OperantContingency))
                      (and
                        (= (quadrantContingency (pt_x cp) (pt_y cp)) (OC_some c1))
                        (= (quadrantContingency (pt_x ap) (pt_y ap)) (OC_some c2))
                        (not (= (oc_effect c1) (oc_effect c2)))
                        (= (oc_op c1) (oc_op c2)))))))))))))
(check-sat)
(pop)
