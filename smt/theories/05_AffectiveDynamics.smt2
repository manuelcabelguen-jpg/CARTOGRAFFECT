; =============================================================================
; Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
; SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
; Author: Manuel Cabelguen
;
; Module 05 : AffectiveDynamics (SMT-LIB 2.6 / Z3)
; Equivalence formelle directe avec Cartograffect/AffectiveDynamics.lean
; =============================================================================
(set-logic ALL)
(set-option :produce-models true)

; -----------------------------------------------------------------------------
; 1. Types fondamentaux
; -----------------------------------------------------------------------------
(declare-datatypes ((CoreAffectPoint 0)) (
  ((mkPoint (pt_x Int) (pt_y Int) (pt_z Int)))
))

(declare-datatypes ((GeometryType 0)) (
  ((GT_central) (GT_axial) (GT_diagonal) (GT_lateral))
))

(declare-datatypes ((TaxonomicGroup 0)) (
  ((TG_operateurCentral)
   (TG_groupeJoie) (TG_groupeTristesse) (TG_groupePeur) (TG_groupeCourage)
   (TG_groupeDesir) (TG_groupeDegout) (TG_groupeColere) (TG_groupeCalme))
))

; -----------------------------------------------------------------------------
; 2. Fonctions de base (CoreAffect, AffectiveMatrix, AffectiveTaxonomy)
; -----------------------------------------------------------------------------
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
  (and (>= (pt_z p) 0)
       (or (CoreAffectPoint_isCentral p)
           (CoreAffectPoint_isOnCrown p))))

(define-fun CoreAffectPoint_classifyGeometry ((p CoreAffectPoint)) GeometryType
  (ite (and (= (pt_x p) 0) (= (pt_y p) 0)) GT_central
  (ite (or (= (pt_x p) 0) (= (pt_y p) 0)) GT_axial
  (ite (= (intAbs (pt_x p)) (intAbs (pt_y p))) GT_diagonal
  GT_lateral))))

(define-fun antagonistPoint ((p CoreAffectPoint)) CoreAffectPoint
  (let ((x (pt_x p)) (y (pt_y p)) (z (pt_z p)))
    (ite (or (= x 0) (= y 0) (= (intAbs x) (intAbs y)))
      (mkPoint (- x) (- y) z)
      (ite (or (and (> x 0) (< y 0)) (and (< x 0) (> y 0)))
        (mkPoint y x z)
        (mkPoint (- y) (- x) z)))))

(define-fun classifyTaxonomicGroup ((p CoreAffectPoint)) TaxonomicGroup
  (let ((x (pt_x p)) (y (pt_y p)))
    (ite (and (= x 0) (= y 0)) TG_operateurCentral
    (ite (> (intAbs y) (intAbs x)) (ite (> y 0) TG_groupeJoie TG_groupeTristesse)
    (ite (> (intAbs x) (intAbs y)) (ite (< x 0) TG_groupePeur TG_groupeCourage)
    (ite (> x 0) (ite (> y 0) TG_groupeDesir TG_groupeCalme)
    (ite (> y 0) TG_groupeColere TG_groupeDegout)))))))

; -----------------------------------------------------------------------------
; 3. Noyau stochastique inter-strates et attracteurs gradues
; -----------------------------------------------------------------------------
(define-fun canonicalDepthWeight ((p CoreAffectPoint) (q CoreAffectPoint)) Int
  (let ((px (pt_x p)) (py (pt_y p)) (pz (pt_z p))
        (qx (pt_x q)) (qy (pt_y q)) (qz (pt_z q)))
    (ite (and (isValidCoreAffect p)
              (isValidCoreAffect q)
              (= qz (+ pz 1))
              (>= (* px qx) 0)
              (>= (* py qy) 0))
      (ite (and (= qx 0) (= qy 0))
        (ite (and (= px 0) (= py 0)) 1 0)
        (ite (and (= px 0) (= py 0))
          (ite (= pz 1) 1 0)
          (ite (or (= px 0) (= py 0))
            (ite (and (or (= px 0) (not (= qx 0)))
                      (or (= py 0) (not (= qy 0))))
              (ite (or (= qx 0) (= qy 0)) 1
              (ite (= (intAbs qx) (intAbs qy)) 2 0))
              0)
            (ite (and (not (= qx 0)) (not (= qy 0))
                      (>= (intAbs qx) (intAbs px))
                      (>= (intAbs qy) (intAbs py)))
              (ite (and (= (intAbs px) (intAbs py))
                        (= (intAbs qx) (intAbs qy)))
                   2 1)
              0))))
      0)))

; Temoin constructif d'antecedent en Z-1 pour toute position de couronne q (Z >= 3)
; (isomorphe a AffectiveDynamics.lean L456-557)
(define-fun predForCrown ((q CoreAffectPoint)) CoreAffectPoint
  (let ((qx (pt_x q)) (qy (pt_y q)) (qz (pt_z q)))
    (let ((rPrev (crownRadius (- qz 1))))
      (ite (= qx 0)
        (mkPoint 0 (ite (> qy 0) rPrev (- rPrev)) (- qz 1))
      (ite (= qy 0)
        (mkPoint (ite (> qx 0) rPrev (- rPrev)) 0 (- qz 1))
        (let ((ax (ite (>= (intAbs qx) 2)
                    (ite (>= (intAbs qy) 2) (- (intAbs qx) 1) (- (intAbs qx) 2))
                    1)))
          (let ((ay (- rPrev ax)))
            (mkPoint (ite (> qx 0) ax (- ax))
                     (ite (> qy 0) ay (- ay))
                     (- qz 1)))))))))

; Temoin constructif de successeur valide en Z+1 pour tout p valide
; (isomorphe a AffectiveDynamics.lean L815-890)
(define-fun witnessSuccForPoint ((p CoreAffectPoint)) CoreAffectPoint
  (let ((px (pt_x p)) (py (pt_y p)) (pz (pt_z p)))
    (let ((zn (+ pz 1)))
      (let ((rn (crownRadius zn)))
        (ite (and (= px 0) (= py 0))
          (mkPoint 0 0 zn)
        (ite (= px 0)
          (mkPoint 0 (ite (> py 0) rn (- rn)) zn)
        (ite (= py 0)
          (mkPoint (ite (> px 0) rn (- rn)) 0 zn)
          (mkPoint (ite (> px 0) (+ px 1) (- px 1))
                   (ite (> py 0) (+ py 1) (- py 1))
                   zn))))))))

; Somme exacte des poids sortants de p vers tous les points valides de la strate znext
(define-fun sumCrownRowAtAx ((p CoreAffectPoint) (znext Int) (ax Int) (ay Int)) Int
  (ite (= ax 0)
    (+ (canonicalDepthWeight p (mkPoint 0 ay znext))
       (canonicalDepthWeight p (mkPoint 0 (- ay) znext)))
    (ite (= ay 0)
      (+ (canonicalDepthWeight p (mkPoint ax 0 znext))
         (canonicalDepthWeight p (mkPoint (- ax) 0 znext)))
      (+ (canonicalDepthWeight p (mkPoint ax ay znext))
         (canonicalDepthWeight p (mkPoint ax (- ay) znext))
         (canonicalDepthWeight p (mkPoint (- ax) ay znext))
         (canonicalDepthWeight p (mkPoint (- ax) (- ay) znext))))))

(define-fun-rec sumCrownWeightsRec ((p CoreAffectPoint) (znext Int) (r Int) (ax Int)) Int
  (ite (< ax 0) 0
    (+ (sumCrownRowAtAx p znext ax (- r ax))
       (sumCrownWeightsRec p znext r (- ax 1)))))

(define-fun outgoingWeight ((p CoreAffectPoint)) Int
  (let ((zn (+ (pt_z p) 1)))
    (+ (canonicalDepthWeight p (mkPoint 0 0 zn))
       (ite (< zn 2) 0
         (sumCrownWeightsRec p zn (crownRadius zn) (crownRadius zn))))))

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

; -----------------------------------------------------------------------------
; Controle de non-vacuite (doit retourner sat)
; -----------------------------------------------------------------------------
(echo "[CONSISTENCY]")
(push)
(declare-const p_test CoreAffectPoint)
(assert (isValidCoreAffect p_test))
(assert (= (CoreAffectPoint_classifyGeometry p_test) GT_lateral))
(check-sat)
(pop)

; -----------------------------------------------------------------------------
; 4. Audit des 4 lois de DepthTransitionKernel + 10 theoremes de AffectiveDynamics
; -----------------------------------------------------------------------------

; Controle auxiliaire des 4 lois structurelles de DepthTransitionKernel
(echo "[AUX] canonicalDepthKernel_laws")
(push)
(assert (not
  (forall ((p CoreAffectPoint) (q CoreAffectPoint))
    (and
      (=> (not (= (canonicalDepthWeight p q) 0))
          (and (isValidCoreAffect q)
               (= (pt_z q) (+ (pt_z p) 1))
               (>= (* (pt_x p) (pt_x q)) 0)
               (>= (* (pt_y p) (pt_y q)) 0)))
      (= (canonicalDepthWeight (antagonistPoint p) (antagonistPoint q))
         (canonicalDepthWeight p q))))))
(check-sat)
(pop)

; [1/10] canonicalDepthKernel_reaches_crown (temoin constructif predForCrown)
(echo "[THM] canonicalDepthKernel_reaches_crown")
(push)
(assert (not
  (forall ((q CoreAffectPoint))
    (=> (and (isValidCoreAffect q)
             (>= (pt_z q) 3)
             (not (CoreAffectPoint_isCentral q)))
        (let ((p (predForCrown q)))
          (and (isValidCoreAffect p)
               (= (+ (pt_z p) 1) (pt_z q))
               (not (= (canonicalDepthWeight p q) 0))))))))
(check-sat)
(pop)

; [2/10] canonicalDepthKernel_reaches_lateral (temoin constructif predForCrown)
(echo "[THM] canonicalDepthKernel_reaches_lateral")
(push)
(assert (not
  (forall ((q CoreAffectPoint))
    (=> (and (isValidCoreAffect q)
             (= (CoreAffectPoint_classifyGeometry q) GT_lateral))
        (let ((p (predForCrown q)))
          (and (isValidCoreAffect p)
               (= (+ (pt_z p) 1) (pt_z q))
               (not (= (canonicalDepthWeight p q) 0))))))))
(check-sat)
(pop)

; [3/10] lateral_reachable
(echo "[THM] lateral_reachable")
(push)
(assert (not
  (forall ((q CoreAffectPoint))
    (=> (and (isValidCoreAffect q)
             (= (CoreAffectPoint_classifyGeometry q) GT_lateral))
        (let ((p (predForCrown q)))
          (and (isValidCoreAffect p)
               (= (+ (pt_z p) 1) (pt_z q))
               (not (= (canonicalDepthWeight p q) 0))))))))
(check-sat)
(pop)

; [4/10] lateral_reachable_from_surprise (induction complete Z=2 + pas Z>=3 via predForCrown)
(echo "[THM] lateral_reachable_from_surprise")
(push)
(assert (not
  (and
    ; Base d = 0 (Z = 2) : depuis Surprise (0,0,1), toute position de couronne Z=2 est atteinte en 1 pas
    (forall ((q CoreAffectPoint))
      (=> (and (isValidCoreAffect q) (= (pt_z q) 2) (not (CoreAffectPoint_isCentral q)))
          (not (= (canonicalDepthWeight (mkPoint 0 0 1) q) 0))))
    ; Pas inductif : toute position de couronne Z >= 3 possede l'antecedent non-central predForCrown(q) en Z-1
    (forall ((q CoreAffectPoint))
      (=> (and (isValidCoreAffect q) (>= (pt_z q) 3) (not (CoreAffectPoint_isCentral q)))
          (let ((p (predForCrown q)))
            (and (isValidCoreAffect p)
                 (not (CoreAffectPoint_isCentral p))
                 (= (+ (pt_z p) 1) (pt_z q))
                 (not (= (canonicalDepthWeight p q) 0))))))
    ; Toute position laterale a Z >= 3
    (forall ((q CoreAffectPoint))
      (=> (and (isValidCoreAffect q) (= (CoreAffectPoint_classifyGeometry q) GT_lateral))
          (and (>= (pt_z q) 3) (not (CoreAffectPoint_isCentral q))))))))
(check-sat)
(pop)

; [5/10] canonicalDepthKernel_colere_bifurcates
(echo "[THM] canonicalDepthKernel_colere_bifurcates")
(push)
(assert (not
  (and (= (canonicalDepthWeight (mkPoint (- 1) 1 2) (mkPoint (- 2) 2 3)) 2)
       (= (canonicalDepthWeight (mkPoint (- 1) 1 2) (mkPoint (- 1) 3 3)) 1)
       (= (canonicalDepthWeight (mkPoint (- 1) 1 2) (mkPoint (- 3) 1 3)) 1))))
(check-sat)
(pop)

; [6/10] canonicalDepthKernel_axial_instability_p2
(echo "[THM] canonicalDepthKernel_axial_instability_p2")
(push)
(assert (not
  (and (> (canonicalDepthWeight (mkPoint 0 2 2) (mkPoint 2 2 3))
          (canonicalDepthWeight (mkPoint 0 2 2) (mkPoint 0 4 3)))
       (> (canonicalDepthWeight (mkPoint 0 2 2) (mkPoint (- 2) 2 3))
          (canonicalDepthWeight (mkPoint 0 2 2) (mkPoint 0 4 3))))))
(check-sat)
(pop)

; [7/10] canonicalDepthKernel_outgoingWeight_pos (temoin universel witnessSuccForPoint + non-negativite)
(echo "[THM] canonicalDepthKernel_outgoingWeight_pos")
(push)
(assert (not
  (and
    (forall ((p CoreAffectPoint))
      (=> (isValidCoreAffect p)
          (let ((q (witnessSuccForPoint p)))
            (and (isValidCoreAffect q)
                 (= (pt_z q) (+ (pt_z p) 1))
                 (> (canonicalDepthWeight p q) 0)))))
    (forall ((p CoreAffectPoint) (q CoreAffectPoint))
      (>= (canonicalDepthWeight p q) 0)))))
(check-sat)
(pop)

; [8/10] classifyTaxonomicGroup_unique_maximizer
(echo "[THM] classifyTaxonomicGroup_unique_maximizer")
(push)
(assert (not
  (forall ((p CoreAffectPoint) (g TaxonomicGroup))
    (=> (not (= g (classifyTaxonomicGroup p)))
        (< (attractorMembership p g)
           (attractorMembership p (classifyTaxonomicGroup p)))))))
(check-sat)
(pop)

; [9/10] classifyTaxonomicGroup_maximizes_membership
(echo "[THM] classifyTaxonomicGroup_maximizes_membership")
(push)
(assert (not
  (forall ((p CoreAffectPoint) (g TaxonomicGroup))
    (<= (attractorMembership p g)
        (attractorMembership p (classifyTaxonomicGroup p))))))
(check-sat)
(pop)

; [10/10] lateral_has_overlapping_attractors
(echo "[THM] lateral_has_overlapping_attractors")
(push)
(assert (not
  (forall ((p CoreAffectPoint))
    (=> (= (CoreAffectPoint_classifyGeometry p) GT_lateral)
        (let ((g1 (ite (> (pt_y p) 0) TG_groupeJoie TG_groupeTristesse))
              (g2 (ite (> (pt_x p) 0)
                    (ite (> (pt_y p) 0) TG_groupeDesir TG_groupeCalme)
                    (ite (> (pt_y p) 0) TG_groupeColere TG_groupeDegout))))
          (and (not (= g1 g2))
               (> (attractorMembership p g1) 0)
               (> (attractorMembership p g2) 0)))))))
(check-sat)
(pop)
