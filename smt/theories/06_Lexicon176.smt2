; =============================================================================
; Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
; SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
; Author: Manuel Cabelguen
;
; Module 06 : Lexicon176 (SMT-LIB 2.6 / Z3)
; Equivalence formelle directe avec Cartograffect/Lexicon176.lean
; =============================================================================
(set-logic ALL)
(set-option :produce-models true)

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

(define-fun antagonistPoint ((p CoreAffectPoint)) CoreAffectPoint
  (let ((x (pt_x p)) (y (pt_y p)) (z (pt_z p)))
    (ite (or (= x 0) (= y 0) (= (intAbs x) (intAbs y)))
      (mkPoint (- x) (- y) z)
      (ite (or (and (> x 0) (< y 0)) (and (< x 0) (> y 0)))
        (mkPoint y x z)
        (mkPoint (- y) (- x) z)))))

; -----------------------------------------------------------------------------
; Repertoire exhaustif des 176 entrees lexicales (Z = 0..7)
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

(define-fun inLexicon ((p CoreAffectPoint)) Bool
  (or
    (= p (mkPoint 0 0 0))
    (= p (mkPoint 0 0 1))
    (= p (mkPoint 0 0 2))
    (= p (mkPoint 0 2 2))
    (= p (mkPoint 0 -2 2))
    (= p (mkPoint -2 0 2))
    (= p (mkPoint 2 0 2))
    (= p (mkPoint -1 1 2))
    (= p (mkPoint 1 -1 2))
    (= p (mkPoint 1 1 2))
    (= p (mkPoint -1 -1 2))
    (= p (mkPoint 0 0 3))
    (= p (mkPoint 0 4 3))
    (= p (mkPoint 0 -4 3))
    (= p (mkPoint -4 0 3))
    (= p (mkPoint 4 0 3))
    (= p (mkPoint -1 3 3))
    (= p (mkPoint 1 3 3))
    (= p (mkPoint 1 -3 3))
    (= p (mkPoint -1 -3 3))
    (= p (mkPoint -3 1 3))
    (= p (mkPoint -3 -1 3))
    (= p (mkPoint 3 -1 3))
    (= p (mkPoint 3 1 3))
    (= p (mkPoint -2 2 3))
    (= p (mkPoint 2 -2 3))
    (= p (mkPoint 2 2 3))
    (= p (mkPoint -2 -2 3))
    (= p (mkPoint 0 0 4))
    (= p (mkPoint 0 6 4))
    (= p (mkPoint 0 -6 4))
    (= p (mkPoint -6 0 4))
    (= p (mkPoint 6 0 4))
    (= p (mkPoint -2 4 4))
    (= p (mkPoint -1 5 4))
    (= p (mkPoint 1 5 4))
    (= p (mkPoint 2 4 4))
    (= p (mkPoint 2 -4 4))
    (= p (mkPoint 1 -5 4))
    (= p (mkPoint -2 -4 4))
    (= p (mkPoint -1 -5 4))
    (= p (mkPoint -4 2 4))
    (= p (mkPoint -5 1 4))
    (= p (mkPoint -5 -1 4))
    (= p (mkPoint -4 -2 4))
    (= p (mkPoint 4 2 4))
    (= p (mkPoint 5 1 4))
    (= p (mkPoint 5 -1 4))
    (= p (mkPoint 4 -2 4))
    (= p (mkPoint -3 3 4))
    (= p (mkPoint 3 -3 4))
    (= p (mkPoint 3 3 4))
    (= p (mkPoint -3 -3 4))
    (= p (mkPoint 0 0 5))
    (= p (mkPoint 0 8 5))
    (= p (mkPoint 0 -8 5))
    (= p (mkPoint -8 0 5))
    (= p (mkPoint 8 0 5))
    (= p (mkPoint 1 7 5))
    (= p (mkPoint 2 6 5))
    (= p (mkPoint 3 5 5))
    (= p (mkPoint -2 6 5))
    (= p (mkPoint -3 5 5))
    (= p (mkPoint -1 7 5))
    (= p (mkPoint 3 -5 5))
    (= p (mkPoint 2 -6 5))
    (= p (mkPoint 1 -7 5))
    (= p (mkPoint -2 -6 5))
    (= p (mkPoint -3 -5 5))
    (= p (mkPoint -1 -7 5))
    (= p (mkPoint -6 2 5))
    (= p (mkPoint -5 3 5))
    (= p (mkPoint -7 1 5))
    (= p (mkPoint -7 -1 5))
    (= p (mkPoint -6 -2 5))
    (= p (mkPoint -5 -3 5))
    (= p (mkPoint 6 2 5))
    (= p (mkPoint 5 3 5))
    (= p (mkPoint 7 1 5))
    (= p (mkPoint 6 -2 5))
    (= p (mkPoint 5 -3 5))
    (= p (mkPoint 7 -1 5))
    (= p (mkPoint -4 4 5))
    (= p (mkPoint 4 -4 5))
    (= p (mkPoint 4 4 5))
    (= p (mkPoint -4 -4 5))
    (= p (mkPoint 0 0 6))
    (= p (mkPoint 0 10 6))
    (= p (mkPoint 0 -10 6))
    (= p (mkPoint -10 0 6))
    (= p (mkPoint 10 0 6))
    (= p (mkPoint 3 7 6))
    (= p (mkPoint -3 7 6))
    (= p (mkPoint 4 6 6))
    (= p (mkPoint -4 6 6))
    (= p (mkPoint 2 8 6))
    (= p (mkPoint -2 8 6))
    (= p (mkPoint 1 9 6))
    (= p (mkPoint -1 9 6))
    (= p (mkPoint 3 -7 6))
    (= p (mkPoint -3 -7 6))
    (= p (mkPoint 4 -6 6))
    (= p (mkPoint -4 -6 6))
    (= p (mkPoint 2 -8 6))
    (= p (mkPoint -2 -8 6))
    (= p (mkPoint 1 -9 6))
    (= p (mkPoint -1 -9 6))
    (= p (mkPoint -6 4 6))
    (= p (mkPoint -6 -4 6))
    (= p (mkPoint -7 3 6))
    (= p (mkPoint -7 -3 6))
    (= p (mkPoint -8 2 6))
    (= p (mkPoint -8 -2 6))
    (= p (mkPoint -9 1 6))
    (= p (mkPoint -9 -1 6))
    (= p (mkPoint 6 4 6))
    (= p (mkPoint 6 -4 6))
    (= p (mkPoint 7 3 6))
    (= p (mkPoint 7 -3 6))
    (= p (mkPoint 8 2 6))
    (= p (mkPoint 8 -2 6))
    (= p (mkPoint 9 1 6))
    (= p (mkPoint 9 -1 6))
    (= p (mkPoint -5 5 6))
    (= p (mkPoint 5 -5 6))
    (= p (mkPoint 5 5 6))
    (= p (mkPoint -5 -5 6))
    (= p (mkPoint 0 0 7))
    (= p (mkPoint 0 12 7))
    (= p (mkPoint 0 -12 7))
    (= p (mkPoint -12 0 7))
    (= p (mkPoint 12 0 7))
    (= p (mkPoint 2 10 7))
    (= p (mkPoint -2 10 7))
    (= p (mkPoint 4 8 7))
    (= p (mkPoint -4 8 7))
    (= p (mkPoint 1 11 7))
    (= p (mkPoint -1 11 7))
    (= p (mkPoint 3 9 7))
    (= p (mkPoint -3 9 7))
    (= p (mkPoint 5 7 7))
    (= p (mkPoint -5 7 7))
    (= p (mkPoint 2 -10 7))
    (= p (mkPoint -2 -10 7))
    (= p (mkPoint 4 -8 7))
    (= p (mkPoint -4 -8 7))
    (= p (mkPoint 1 -11 7))
    (= p (mkPoint -1 -11 7))
    (= p (mkPoint 3 -9 7))
    (= p (mkPoint -3 -9 7))
    (= p (mkPoint 5 -7 7))
    (= p (mkPoint -5 -7 7))
    (= p (mkPoint -10 2 7))
    (= p (mkPoint -10 -2 7))
    (= p (mkPoint -8 4 7))
    (= p (mkPoint -8 -4 7))
    (= p (mkPoint -11 1 7))
    (= p (mkPoint -11 -1 7))
    (= p (mkPoint -9 3 7))
    (= p (mkPoint -9 -3 7))
    (= p (mkPoint -7 5 7))
    (= p (mkPoint -7 -5 7))
    (= p (mkPoint 10 2 7))
    (= p (mkPoint 10 -2 7))
    (= p (mkPoint 8 4 7))
    (= p (mkPoint 8 -4 7))
    (= p (mkPoint 11 1 7))
    (= p (mkPoint 11 -1 7))
    (= p (mkPoint 9 3 7))
    (= p (mkPoint 9 -3 7))
    (= p (mkPoint 7 5 7))
    (= p (mkPoint 7 -5 7))
    (= p (mkPoint -6 6 7))
    (= p (mkPoint 6 -6 7))
    (= p (mkPoint 6 6 7))
    (= p (mkPoint -6 -6 7))
  )
)

(define-fun validLexIndex ((i Int)) Bool (and (<= 0 i) (< i 176)))

; -----------------------------------------------------------------------------
; Controle de non-vacuite (doit retourner sat)
; -----------------------------------------------------------------------------
(echo "[CONSISTENCY]")
(push)
(declare-const idx Int)
(assert (validLexIndex idx))
(assert (= (lexiconPoint idx) (mkPoint (- 1) 3 3)))
(check-sat)
(pop)

; -----------------------------------------------------------------------------
; Audit des 8 theoremes de Lexicon176 (chaque controle doit retourner unsat)
; -----------------------------------------------------------------------------

; [1/8] all176Entries_length
(echo "[THM] all176Entries_length")
(push)
(assert (not
  (and (= (+ 1 1 9 17 25 33 41 49) 176)
       (forall ((i Int))
         (=> (validLexIndex i)
             (and (<= 0 (pt_z (lexiconPoint i)))
                  (<= (pt_z (lexiconPoint i)) 7)))))))
(check-sat)
(pop)

; [2/8] all176Entries_geometrically_valid
(echo "[THM] all176Entries_geometrically_valid")
(push)
(assert (not
  (and
    (forall ((i Int))
      (=> (validLexIndex i)
          (isValidCoreAffect (lexiconPoint i))))
  (and
    (isValidCoreAffect (mkPoint 0 0 0))
    (isValidCoreAffect (mkPoint 0 0 1))
    (isValidCoreAffect (mkPoint 0 0 2))
    (isValidCoreAffect (mkPoint 0 2 2))
    (isValidCoreAffect (mkPoint 0 -2 2))
    (isValidCoreAffect (mkPoint -2 0 2))
    (isValidCoreAffect (mkPoint 2 0 2))
    (isValidCoreAffect (mkPoint -1 1 2))
    (isValidCoreAffect (mkPoint 1 -1 2))
    (isValidCoreAffect (mkPoint 1 1 2))
    (isValidCoreAffect (mkPoint -1 -1 2))
    (isValidCoreAffect (mkPoint 0 0 3))
    (isValidCoreAffect (mkPoint 0 4 3))
    (isValidCoreAffect (mkPoint 0 -4 3))
    (isValidCoreAffect (mkPoint -4 0 3))
    (isValidCoreAffect (mkPoint 4 0 3))
    (isValidCoreAffect (mkPoint -1 3 3))
    (isValidCoreAffect (mkPoint 1 3 3))
    (isValidCoreAffect (mkPoint 1 -3 3))
    (isValidCoreAffect (mkPoint -1 -3 3))
    (isValidCoreAffect (mkPoint -3 1 3))
    (isValidCoreAffect (mkPoint -3 -1 3))
    (isValidCoreAffect (mkPoint 3 -1 3))
    (isValidCoreAffect (mkPoint 3 1 3))
    (isValidCoreAffect (mkPoint -2 2 3))
    (isValidCoreAffect (mkPoint 2 -2 3))
    (isValidCoreAffect (mkPoint 2 2 3))
    (isValidCoreAffect (mkPoint -2 -2 3))
    (isValidCoreAffect (mkPoint 0 0 4))
    (isValidCoreAffect (mkPoint 0 6 4))
    (isValidCoreAffect (mkPoint 0 -6 4))
    (isValidCoreAffect (mkPoint -6 0 4))
    (isValidCoreAffect (mkPoint 6 0 4))
    (isValidCoreAffect (mkPoint -2 4 4))
    (isValidCoreAffect (mkPoint -1 5 4))
    (isValidCoreAffect (mkPoint 1 5 4))
    (isValidCoreAffect (mkPoint 2 4 4))
    (isValidCoreAffect (mkPoint 2 -4 4))
    (isValidCoreAffect (mkPoint 1 -5 4))
    (isValidCoreAffect (mkPoint -2 -4 4))
    (isValidCoreAffect (mkPoint -1 -5 4))
    (isValidCoreAffect (mkPoint -4 2 4))
    (isValidCoreAffect (mkPoint -5 1 4))
    (isValidCoreAffect (mkPoint -5 -1 4))
    (isValidCoreAffect (mkPoint -4 -2 4))
    (isValidCoreAffect (mkPoint 4 2 4))
    (isValidCoreAffect (mkPoint 5 1 4))
    (isValidCoreAffect (mkPoint 5 -1 4))
    (isValidCoreAffect (mkPoint 4 -2 4))
    (isValidCoreAffect (mkPoint -3 3 4))
    (isValidCoreAffect (mkPoint 3 -3 4))
    (isValidCoreAffect (mkPoint 3 3 4))
    (isValidCoreAffect (mkPoint -3 -3 4))
    (isValidCoreAffect (mkPoint 0 0 5))
    (isValidCoreAffect (mkPoint 0 8 5))
    (isValidCoreAffect (mkPoint 0 -8 5))
    (isValidCoreAffect (mkPoint -8 0 5))
    (isValidCoreAffect (mkPoint 8 0 5))
    (isValidCoreAffect (mkPoint 1 7 5))
    (isValidCoreAffect (mkPoint 2 6 5))
    (isValidCoreAffect (mkPoint 3 5 5))
    (isValidCoreAffect (mkPoint -2 6 5))
    (isValidCoreAffect (mkPoint -3 5 5))
    (isValidCoreAffect (mkPoint -1 7 5))
    (isValidCoreAffect (mkPoint 3 -5 5))
    (isValidCoreAffect (mkPoint 2 -6 5))
    (isValidCoreAffect (mkPoint 1 -7 5))
    (isValidCoreAffect (mkPoint -2 -6 5))
    (isValidCoreAffect (mkPoint -3 -5 5))
    (isValidCoreAffect (mkPoint -1 -7 5))
    (isValidCoreAffect (mkPoint -6 2 5))
    (isValidCoreAffect (mkPoint -5 3 5))
    (isValidCoreAffect (mkPoint -7 1 5))
    (isValidCoreAffect (mkPoint -7 -1 5))
    (isValidCoreAffect (mkPoint -6 -2 5))
    (isValidCoreAffect (mkPoint -5 -3 5))
    (isValidCoreAffect (mkPoint 6 2 5))
    (isValidCoreAffect (mkPoint 5 3 5))
    (isValidCoreAffect (mkPoint 7 1 5))
    (isValidCoreAffect (mkPoint 6 -2 5))
    (isValidCoreAffect (mkPoint 5 -3 5))
    (isValidCoreAffect (mkPoint 7 -1 5))
    (isValidCoreAffect (mkPoint -4 4 5))
    (isValidCoreAffect (mkPoint 4 -4 5))
    (isValidCoreAffect (mkPoint 4 4 5))
    (isValidCoreAffect (mkPoint -4 -4 5))
    (isValidCoreAffect (mkPoint 0 0 6))
    (isValidCoreAffect (mkPoint 0 10 6))
    (isValidCoreAffect (mkPoint 0 -10 6))
    (isValidCoreAffect (mkPoint -10 0 6))
    (isValidCoreAffect (mkPoint 10 0 6))
    (isValidCoreAffect (mkPoint 3 7 6))
    (isValidCoreAffect (mkPoint -3 7 6))
    (isValidCoreAffect (mkPoint 4 6 6))
    (isValidCoreAffect (mkPoint -4 6 6))
    (isValidCoreAffect (mkPoint 2 8 6))
    (isValidCoreAffect (mkPoint -2 8 6))
    (isValidCoreAffect (mkPoint 1 9 6))
    (isValidCoreAffect (mkPoint -1 9 6))
    (isValidCoreAffect (mkPoint 3 -7 6))
    (isValidCoreAffect (mkPoint -3 -7 6))
    (isValidCoreAffect (mkPoint 4 -6 6))
    (isValidCoreAffect (mkPoint -4 -6 6))
    (isValidCoreAffect (mkPoint 2 -8 6))
    (isValidCoreAffect (mkPoint -2 -8 6))
    (isValidCoreAffect (mkPoint 1 -9 6))
    (isValidCoreAffect (mkPoint -1 -9 6))
    (isValidCoreAffect (mkPoint -6 4 6))
    (isValidCoreAffect (mkPoint -6 -4 6))
    (isValidCoreAffect (mkPoint -7 3 6))
    (isValidCoreAffect (mkPoint -7 -3 6))
    (isValidCoreAffect (mkPoint -8 2 6))
    (isValidCoreAffect (mkPoint -8 -2 6))
    (isValidCoreAffect (mkPoint -9 1 6))
    (isValidCoreAffect (mkPoint -9 -1 6))
    (isValidCoreAffect (mkPoint 6 4 6))
    (isValidCoreAffect (mkPoint 6 -4 6))
    (isValidCoreAffect (mkPoint 7 3 6))
    (isValidCoreAffect (mkPoint 7 -3 6))
    (isValidCoreAffect (mkPoint 8 2 6))
    (isValidCoreAffect (mkPoint 8 -2 6))
    (isValidCoreAffect (mkPoint 9 1 6))
    (isValidCoreAffect (mkPoint 9 -1 6))
    (isValidCoreAffect (mkPoint -5 5 6))
    (isValidCoreAffect (mkPoint 5 -5 6))
    (isValidCoreAffect (mkPoint 5 5 6))
    (isValidCoreAffect (mkPoint -5 -5 6))
    (isValidCoreAffect (mkPoint 0 0 7))
    (isValidCoreAffect (mkPoint 0 12 7))
    (isValidCoreAffect (mkPoint 0 -12 7))
    (isValidCoreAffect (mkPoint -12 0 7))
    (isValidCoreAffect (mkPoint 12 0 7))
    (isValidCoreAffect (mkPoint 2 10 7))
    (isValidCoreAffect (mkPoint -2 10 7))
    (isValidCoreAffect (mkPoint 4 8 7))
    (isValidCoreAffect (mkPoint -4 8 7))
    (isValidCoreAffect (mkPoint 1 11 7))
    (isValidCoreAffect (mkPoint -1 11 7))
    (isValidCoreAffect (mkPoint 3 9 7))
    (isValidCoreAffect (mkPoint -3 9 7))
    (isValidCoreAffect (mkPoint 5 7 7))
    (isValidCoreAffect (mkPoint -5 7 7))
    (isValidCoreAffect (mkPoint 2 -10 7))
    (isValidCoreAffect (mkPoint -2 -10 7))
    (isValidCoreAffect (mkPoint 4 -8 7))
    (isValidCoreAffect (mkPoint -4 -8 7))
    (isValidCoreAffect (mkPoint 1 -11 7))
    (isValidCoreAffect (mkPoint -1 -11 7))
    (isValidCoreAffect (mkPoint 3 -9 7))
    (isValidCoreAffect (mkPoint -3 -9 7))
    (isValidCoreAffect (mkPoint 5 -7 7))
    (isValidCoreAffect (mkPoint -5 -7 7))
    (isValidCoreAffect (mkPoint -10 2 7))
    (isValidCoreAffect (mkPoint -10 -2 7))
    (isValidCoreAffect (mkPoint -8 4 7))
    (isValidCoreAffect (mkPoint -8 -4 7))
    (isValidCoreAffect (mkPoint -11 1 7))
    (isValidCoreAffect (mkPoint -11 -1 7))
    (isValidCoreAffect (mkPoint -9 3 7))
    (isValidCoreAffect (mkPoint -9 -3 7))
    (isValidCoreAffect (mkPoint -7 5 7))
    (isValidCoreAffect (mkPoint -7 -5 7))
    (isValidCoreAffect (mkPoint 10 2 7))
    (isValidCoreAffect (mkPoint 10 -2 7))
    (isValidCoreAffect (mkPoint 8 4 7))
    (isValidCoreAffect (mkPoint 8 -4 7))
    (isValidCoreAffect (mkPoint 11 1 7))
    (isValidCoreAffect (mkPoint 11 -1 7))
    (isValidCoreAffect (mkPoint 9 3 7))
    (isValidCoreAffect (mkPoint 9 -3 7))
    (isValidCoreAffect (mkPoint 7 5 7))
    (isValidCoreAffect (mkPoint 7 -5 7))
    (isValidCoreAffect (mkPoint -6 6 7))
    (isValidCoreAffect (mkPoint 6 -6 7))
    (isValidCoreAffect (mkPoint 6 6 7))
    (isValidCoreAffect (mkPoint -6 -6 7))
  )
  )))
(check-sat)
(pop)

; [3/8] all176Entries_unique_points
(echo "[THM] all176Entries_unique_points")
(push)
(assert (not
  (forall ((i Int) (j Int))
    (=> (and (validLexIndex i) (validLexIndex j) (not (= i j)))
        (not (= (lexiconPoint i) (lexiconPoint j)))))))
(check-sat)
(pop)

; [4/8] all176Entries_closed_under_antagonist
(echo "[THM] all176Entries_closed_under_antagonist")
(push)
(assert (not
  (and
    (forall ((i Int))
      (=> (validLexIndex i)
          (inLexicon (antagonistPoint (lexiconPoint i)))))
  (and
    (inLexicon (antagonistPoint (mkPoint 0 0 0)))
    (inLexicon (antagonistPoint (mkPoint 0 0 1)))
    (inLexicon (antagonistPoint (mkPoint 0 0 2)))
    (inLexicon (antagonistPoint (mkPoint 0 2 2)))
    (inLexicon (antagonistPoint (mkPoint 0 -2 2)))
    (inLexicon (antagonistPoint (mkPoint -2 0 2)))
    (inLexicon (antagonistPoint (mkPoint 2 0 2)))
    (inLexicon (antagonistPoint (mkPoint -1 1 2)))
    (inLexicon (antagonistPoint (mkPoint 1 -1 2)))
    (inLexicon (antagonistPoint (mkPoint 1 1 2)))
    (inLexicon (antagonistPoint (mkPoint -1 -1 2)))
    (inLexicon (antagonistPoint (mkPoint 0 0 3)))
    (inLexicon (antagonistPoint (mkPoint 0 4 3)))
    (inLexicon (antagonistPoint (mkPoint 0 -4 3)))
    (inLexicon (antagonistPoint (mkPoint -4 0 3)))
    (inLexicon (antagonistPoint (mkPoint 4 0 3)))
    (inLexicon (antagonistPoint (mkPoint -1 3 3)))
    (inLexicon (antagonistPoint (mkPoint 1 3 3)))
    (inLexicon (antagonistPoint (mkPoint 1 -3 3)))
    (inLexicon (antagonistPoint (mkPoint -1 -3 3)))
    (inLexicon (antagonistPoint (mkPoint -3 1 3)))
    (inLexicon (antagonistPoint (mkPoint -3 -1 3)))
    (inLexicon (antagonistPoint (mkPoint 3 -1 3)))
    (inLexicon (antagonistPoint (mkPoint 3 1 3)))
    (inLexicon (antagonistPoint (mkPoint -2 2 3)))
    (inLexicon (antagonistPoint (mkPoint 2 -2 3)))
    (inLexicon (antagonistPoint (mkPoint 2 2 3)))
    (inLexicon (antagonistPoint (mkPoint -2 -2 3)))
    (inLexicon (antagonistPoint (mkPoint 0 0 4)))
    (inLexicon (antagonistPoint (mkPoint 0 6 4)))
    (inLexicon (antagonistPoint (mkPoint 0 -6 4)))
    (inLexicon (antagonistPoint (mkPoint -6 0 4)))
    (inLexicon (antagonistPoint (mkPoint 6 0 4)))
    (inLexicon (antagonistPoint (mkPoint -2 4 4)))
    (inLexicon (antagonistPoint (mkPoint -1 5 4)))
    (inLexicon (antagonistPoint (mkPoint 1 5 4)))
    (inLexicon (antagonistPoint (mkPoint 2 4 4)))
    (inLexicon (antagonistPoint (mkPoint 2 -4 4)))
    (inLexicon (antagonistPoint (mkPoint 1 -5 4)))
    (inLexicon (antagonistPoint (mkPoint -2 -4 4)))
    (inLexicon (antagonistPoint (mkPoint -1 -5 4)))
    (inLexicon (antagonistPoint (mkPoint -4 2 4)))
    (inLexicon (antagonistPoint (mkPoint -5 1 4)))
    (inLexicon (antagonistPoint (mkPoint -5 -1 4)))
    (inLexicon (antagonistPoint (mkPoint -4 -2 4)))
    (inLexicon (antagonistPoint (mkPoint 4 2 4)))
    (inLexicon (antagonistPoint (mkPoint 5 1 4)))
    (inLexicon (antagonistPoint (mkPoint 5 -1 4)))
    (inLexicon (antagonistPoint (mkPoint 4 -2 4)))
    (inLexicon (antagonistPoint (mkPoint -3 3 4)))
    (inLexicon (antagonistPoint (mkPoint 3 -3 4)))
    (inLexicon (antagonistPoint (mkPoint 3 3 4)))
    (inLexicon (antagonistPoint (mkPoint -3 -3 4)))
    (inLexicon (antagonistPoint (mkPoint 0 0 5)))
    (inLexicon (antagonistPoint (mkPoint 0 8 5)))
    (inLexicon (antagonistPoint (mkPoint 0 -8 5)))
    (inLexicon (antagonistPoint (mkPoint -8 0 5)))
    (inLexicon (antagonistPoint (mkPoint 8 0 5)))
    (inLexicon (antagonistPoint (mkPoint 1 7 5)))
    (inLexicon (antagonistPoint (mkPoint 2 6 5)))
    (inLexicon (antagonistPoint (mkPoint 3 5 5)))
    (inLexicon (antagonistPoint (mkPoint -2 6 5)))
    (inLexicon (antagonistPoint (mkPoint -3 5 5)))
    (inLexicon (antagonistPoint (mkPoint -1 7 5)))
    (inLexicon (antagonistPoint (mkPoint 3 -5 5)))
    (inLexicon (antagonistPoint (mkPoint 2 -6 5)))
    (inLexicon (antagonistPoint (mkPoint 1 -7 5)))
    (inLexicon (antagonistPoint (mkPoint -2 -6 5)))
    (inLexicon (antagonistPoint (mkPoint -3 -5 5)))
    (inLexicon (antagonistPoint (mkPoint -1 -7 5)))
    (inLexicon (antagonistPoint (mkPoint -6 2 5)))
    (inLexicon (antagonistPoint (mkPoint -5 3 5)))
    (inLexicon (antagonistPoint (mkPoint -7 1 5)))
    (inLexicon (antagonistPoint (mkPoint -7 -1 5)))
    (inLexicon (antagonistPoint (mkPoint -6 -2 5)))
    (inLexicon (antagonistPoint (mkPoint -5 -3 5)))
    (inLexicon (antagonistPoint (mkPoint 6 2 5)))
    (inLexicon (antagonistPoint (mkPoint 5 3 5)))
    (inLexicon (antagonistPoint (mkPoint 7 1 5)))
    (inLexicon (antagonistPoint (mkPoint 6 -2 5)))
    (inLexicon (antagonistPoint (mkPoint 5 -3 5)))
    (inLexicon (antagonistPoint (mkPoint 7 -1 5)))
    (inLexicon (antagonistPoint (mkPoint -4 4 5)))
    (inLexicon (antagonistPoint (mkPoint 4 -4 5)))
    (inLexicon (antagonistPoint (mkPoint 4 4 5)))
    (inLexicon (antagonistPoint (mkPoint -4 -4 5)))
    (inLexicon (antagonistPoint (mkPoint 0 0 6)))
    (inLexicon (antagonistPoint (mkPoint 0 10 6)))
    (inLexicon (antagonistPoint (mkPoint 0 -10 6)))
    (inLexicon (antagonistPoint (mkPoint -10 0 6)))
    (inLexicon (antagonistPoint (mkPoint 10 0 6)))
    (inLexicon (antagonistPoint (mkPoint 3 7 6)))
    (inLexicon (antagonistPoint (mkPoint -3 7 6)))
    (inLexicon (antagonistPoint (mkPoint 4 6 6)))
    (inLexicon (antagonistPoint (mkPoint -4 6 6)))
    (inLexicon (antagonistPoint (mkPoint 2 8 6)))
    (inLexicon (antagonistPoint (mkPoint -2 8 6)))
    (inLexicon (antagonistPoint (mkPoint 1 9 6)))
    (inLexicon (antagonistPoint (mkPoint -1 9 6)))
    (inLexicon (antagonistPoint (mkPoint 3 -7 6)))
    (inLexicon (antagonistPoint (mkPoint -3 -7 6)))
    (inLexicon (antagonistPoint (mkPoint 4 -6 6)))
    (inLexicon (antagonistPoint (mkPoint -4 -6 6)))
    (inLexicon (antagonistPoint (mkPoint 2 -8 6)))
    (inLexicon (antagonistPoint (mkPoint -2 -8 6)))
    (inLexicon (antagonistPoint (mkPoint 1 -9 6)))
    (inLexicon (antagonistPoint (mkPoint -1 -9 6)))
    (inLexicon (antagonistPoint (mkPoint -6 4 6)))
    (inLexicon (antagonistPoint (mkPoint -6 -4 6)))
    (inLexicon (antagonistPoint (mkPoint -7 3 6)))
    (inLexicon (antagonistPoint (mkPoint -7 -3 6)))
    (inLexicon (antagonistPoint (mkPoint -8 2 6)))
    (inLexicon (antagonistPoint (mkPoint -8 -2 6)))
    (inLexicon (antagonistPoint (mkPoint -9 1 6)))
    (inLexicon (antagonistPoint (mkPoint -9 -1 6)))
    (inLexicon (antagonistPoint (mkPoint 6 4 6)))
    (inLexicon (antagonistPoint (mkPoint 6 -4 6)))
    (inLexicon (antagonistPoint (mkPoint 7 3 6)))
    (inLexicon (antagonistPoint (mkPoint 7 -3 6)))
    (inLexicon (antagonistPoint (mkPoint 8 2 6)))
    (inLexicon (antagonistPoint (mkPoint 8 -2 6)))
    (inLexicon (antagonistPoint (mkPoint 9 1 6)))
    (inLexicon (antagonistPoint (mkPoint 9 -1 6)))
    (inLexicon (antagonistPoint (mkPoint -5 5 6)))
    (inLexicon (antagonistPoint (mkPoint 5 -5 6)))
    (inLexicon (antagonistPoint (mkPoint 5 5 6)))
    (inLexicon (antagonistPoint (mkPoint -5 -5 6)))
    (inLexicon (antagonistPoint (mkPoint 0 0 7)))
    (inLexicon (antagonistPoint (mkPoint 0 12 7)))
    (inLexicon (antagonistPoint (mkPoint 0 -12 7)))
    (inLexicon (antagonistPoint (mkPoint -12 0 7)))
    (inLexicon (antagonistPoint (mkPoint 12 0 7)))
    (inLexicon (antagonistPoint (mkPoint 2 10 7)))
    (inLexicon (antagonistPoint (mkPoint -2 10 7)))
    (inLexicon (antagonistPoint (mkPoint 4 8 7)))
    (inLexicon (antagonistPoint (mkPoint -4 8 7)))
    (inLexicon (antagonistPoint (mkPoint 1 11 7)))
    (inLexicon (antagonistPoint (mkPoint -1 11 7)))
    (inLexicon (antagonistPoint (mkPoint 3 9 7)))
    (inLexicon (antagonistPoint (mkPoint -3 9 7)))
    (inLexicon (antagonistPoint (mkPoint 5 7 7)))
    (inLexicon (antagonistPoint (mkPoint -5 7 7)))
    (inLexicon (antagonistPoint (mkPoint 2 -10 7)))
    (inLexicon (antagonistPoint (mkPoint -2 -10 7)))
    (inLexicon (antagonistPoint (mkPoint 4 -8 7)))
    (inLexicon (antagonistPoint (mkPoint -4 -8 7)))
    (inLexicon (antagonistPoint (mkPoint 1 -11 7)))
    (inLexicon (antagonistPoint (mkPoint -1 -11 7)))
    (inLexicon (antagonistPoint (mkPoint 3 -9 7)))
    (inLexicon (antagonistPoint (mkPoint -3 -9 7)))
    (inLexicon (antagonistPoint (mkPoint 5 -7 7)))
    (inLexicon (antagonistPoint (mkPoint -5 -7 7)))
    (inLexicon (antagonistPoint (mkPoint -10 2 7)))
    (inLexicon (antagonistPoint (mkPoint -10 -2 7)))
    (inLexicon (antagonistPoint (mkPoint -8 4 7)))
    (inLexicon (antagonistPoint (mkPoint -8 -4 7)))
    (inLexicon (antagonistPoint (mkPoint -11 1 7)))
    (inLexicon (antagonistPoint (mkPoint -11 -1 7)))
    (inLexicon (antagonistPoint (mkPoint -9 3 7)))
    (inLexicon (antagonistPoint (mkPoint -9 -3 7)))
    (inLexicon (antagonistPoint (mkPoint -7 5 7)))
    (inLexicon (antagonistPoint (mkPoint -7 -5 7)))
    (inLexicon (antagonistPoint (mkPoint 10 2 7)))
    (inLexicon (antagonistPoint (mkPoint 10 -2 7)))
    (inLexicon (antagonistPoint (mkPoint 8 4 7)))
    (inLexicon (antagonistPoint (mkPoint 8 -4 7)))
    (inLexicon (antagonistPoint (mkPoint 11 1 7)))
    (inLexicon (antagonistPoint (mkPoint 11 -1 7)))
    (inLexicon (antagonistPoint (mkPoint 9 3 7)))
    (inLexicon (antagonistPoint (mkPoint 9 -3 7)))
    (inLexicon (antagonistPoint (mkPoint 7 5 7)))
    (inLexicon (antagonistPoint (mkPoint 7 -5 7)))
    (inLexicon (antagonistPoint (mkPoint -6 6 7)))
    (inLexicon (antagonistPoint (mkPoint 6 -6 7)))
    (inLexicon (antagonistPoint (mkPoint 6 6 7)))
    (inLexicon (antagonistPoint (mkPoint -6 -6 7)))
  )
  )))
(check-sat)
(pop)

; [5/8] all176Entries_spatial_completeness
(echo "[THM] all176Entries_spatial_completeness")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (and (>= (pt_z p) 0) (<= (pt_z p) 7) (isValidCoreAffect p))
        (inLexicon p)))))
(check-sat)
(pop)

; [6/8] all176Entries_deterministically_reachable
(echo "[THM] all176Entries_deterministically_reachable")
(push)
(assert (not
  (forall ((i Int))
    (=> (validLexIndex i)
        (let ((s (witnessEngineForPoint (lexiconPoint i))))
          (and (validEngineState s)
               (= (projectToCoreAffect s) (lexiconPoint i))))))))
(check-sat)
(pop)

; [7/8] all176Entries_reachable_by_engine
(echo "[THM] all176Entries_reachable_by_engine")
(push)
(assert (not
  (forall ((i Int))
    (=> (validLexIndex i)
        (let ((s (witnessEngineForPoint (lexiconPoint i))))
          (and (validEngineState s)
               (= (projectToCoreAffect s) (lexiconPoint i))))))))
(check-sat)
(pop)

; [8/8] all176Entries_witness_check
(echo "[THM] all176Entries_witness_check")
(push)
(assert (not
  (forall ((i Int))
    (=> (validLexIndex i)
        (= (projectToCoreAffect (witnessEngineForPoint (lexiconPoint i)))
           (lexiconPoint i))))))
(check-sat)
(pop)
