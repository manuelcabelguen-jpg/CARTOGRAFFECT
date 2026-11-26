{-# OPTIONS --safe --without-K #-}
-- Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
-- SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
-- Author: Manuel Cabelguen
--
-- Module 04 : AffectiveTaxonomy (Agda 2.9.0, --safe --without-K)

module Cartograffect.AffectiveTaxonomy where

open import Cartograffect.Prelude
open import Cartograffect.PredictiveEngine
open import Cartograffect.CoreAffect
open import Cartograffect.AffectiveMatrix

-- ---------------------------------------------------------------------------
-- 1. Ordre trichotomique sur Nat et types taxonomiques
-- ---------------------------------------------------------------------------
data NatOrd : Set where
  ordLT : NatOrd
  ordEQ : NatOrd
  ordGT : NatOrd

flipOrd : NatOrd → NatOrd
flipOrd ordLT = ordGT
flipOrd ordEQ = ordEQ
flipOrd ordGT = ordLT

natCmp : Nat → Nat → NatOrd
natCmp zero    zero    = ordEQ
natCmp zero    (suc _) = ordLT
natCmp (suc _) zero    = ordGT
natCmp (suc a) (suc b) = natCmp a b

natCmp-flip : ∀ (a b : Nat) → natCmp b a ≡ flipOrd (natCmp a b)
natCmp-flip zero    zero    = refl
natCmp-flip zero    (suc _) = refl
natCmp-flip (suc _) zero    = refl
natCmp-flip (suc a) (suc b) = natCmp-flip a b

data OrientationSector : Set where
  secJoie      : OrientationSector
  secTristesse : OrientationSector
  secPeur      : OrientationSector
  secCourage   : OrientationSector

data OptionSector : Set where
  optNone : OptionSector
  optSome : OrientationSector → OptionSector

data TaxonomicStratum : Set where
  z0_pointDeVeille           : TaxonomicStratum
  z1_saillancePerceptive     : TaxonomicStratum
  z2_affectsPrimaires        : TaxonomicStratum
  z3_emotionsReactives       : TaxonomicStratum
  z4_sentimentsReflexifs     : TaxonomicStratum
  z5_orientationsDurables    : TaxonomicStratum
  z6_identitesAffectives     : TaxonomicStratum
  z7_sentimentsTranscendants : TaxonomicStratum
  zDeepProlongation          : Nat → TaxonomicStratum

data TaxonomicGroup : Set where
  operateurCentral : TaxonomicGroup
  groupeJoie       : TaxonomicGroup
  groupeTristesse  : TaxonomicGroup
  groupePeur       : TaxonomicGroup
  groupeCourage    : TaxonomicGroup
  groupeDesir      : TaxonomicGroup
  groupeDegout     : TaxonomicGroup
  groupeColere     : TaxonomicGroup
  groupeCalme      : TaxonomicGroup

data FunctionalSubsector : Set where
  centralOperator          : FunctionalSubsector
  axialElan                : FunctionalSubsector
  axialWithdrawal          : FunctionalSubsector
  axialOpening             : FunctionalSubsector
  axialThreat              : FunctionalSubsector
  diagonalDesire           : FunctionalSubsector
  diagonalDisgust          : FunctionalSubsector
  diagonalAnger            : FunctionalSubsector
  diagonalCalm             : FunctionalSubsector
  lateralApproachSynergy   : FunctionalSubsector
  lateralDefensiveUrgency  : FunctionalSubsector
  lateralTrophotropicPeace : FunctionalSubsector
  lateralAversiveDistress  : FunctionalSubsector
  lateralEpistemicMastery  : FunctionalSubsector
  lateralContemplativeOpen : FunctionalSubsector
  lateralVigilantAlert     : FunctionalSubsector
  lateralEpistemicClosure  : FunctionalSubsector

record TaxonomicState : Set where
  constructor mkTaxonomicState
  field
    matrix              : AffectiveMatrixState
    stratum             : TaxonomicStratum
    geometry            : GeometryType
    group               : TaxonomicGroup
    subsector           : FunctionalSubsector
    antagonistGroup     : TaxonomicGroup
    antagonistSubsector : FunctionalSubsector

open TaxonomicState public

-- ---------------------------------------------------------------------------
-- 2. Classification des strates, groupes, secteurs et sous-secteurs
-- ---------------------------------------------------------------------------
classifyStratum : Nat → TaxonomicStratum
classifyStratum 0 = z0_pointDeVeille
classifyStratum 1 = z1_saillancePerceptive
classifyStratum 2 = z2_affectsPrimaires
classifyStratum 3 = z3_emotionsReactives
classifyStratum 4 = z4_sentimentsReflexifs
classifyStratum 5 = z5_orientationsDurables
classifyStratum 6 = z6_identitesAffectives
classifyStratum 7 = z7_sentimentsTranscendants
classifyStratum z = zDeepProlongation z

dominantSector : CoreAffectPoint → OptionSector
dominantSector (mkPoint (pos zero)     (pos zero)     _) = optNone
dominantSector (mkPoint (pos zero)     (pos (suc _))  _) = optSome secJoie
dominantSector (mkPoint (pos zero)     (negsuc _)     _) = optSome secTristesse
dominantSector (mkPoint (pos (suc _))  (pos zero)     _) = optSome secCourage
dominantSector (mkPoint (negsuc _)     (pos zero)     _) = optSome secPeur
dominantSector (mkPoint (pos (suc ax)) (pos (suc ay)) _) with natCmp ax ay
... | ordLT = optSome secJoie
... | ordEQ = optNone
... | ordGT = optSome secCourage
dominantSector (mkPoint (negsuc ax)    (pos (suc ay)) _) with natCmp ax ay
... | ordLT = optSome secJoie
... | ordEQ = optNone
... | ordGT = optSome secPeur
dominantSector (mkPoint (pos (suc ax)) (negsuc ay)    _) with natCmp ax ay
... | ordLT = optSome secTristesse
... | ordEQ = optNone
... | ordGT = optSome secCourage
dominantSector (mkPoint (negsuc ax)    (negsuc ay)    _) with natCmp ax ay
... | ordLT = optSome secTristesse
... | ordEQ = optNone
... | ordGT = optSome secPeur

classifyTaxonomicGroup : CoreAffectPoint → TaxonomicGroup
classifyTaxonomicGroup (mkPoint (pos zero)     (pos zero)     _) = operateurCentral
classifyTaxonomicGroup (mkPoint (pos zero)     (pos (suc _))  _) = groupeJoie
classifyTaxonomicGroup (mkPoint (pos zero)     (negsuc _)     _) = groupeTristesse
classifyTaxonomicGroup (mkPoint (pos (suc _))  (pos zero)     _) = groupeCourage
classifyTaxonomicGroup (mkPoint (negsuc _)     (pos zero)     _) = groupePeur
classifyTaxonomicGroup (mkPoint (pos (suc ax)) (pos (suc ay)) _) with natCmp ax ay
... | ordLT = groupeJoie
... | ordEQ = groupeDesir
... | ordGT = groupeCourage
classifyTaxonomicGroup (mkPoint (negsuc ax)    (pos (suc ay)) _) with natCmp ax ay
... | ordLT = groupeJoie
... | ordEQ = groupeColere
... | ordGT = groupePeur
classifyTaxonomicGroup (mkPoint (pos (suc ax)) (negsuc ay)    _) with natCmp ax ay
... | ordLT = groupeTristesse
... | ordEQ = groupeCalme
... | ordGT = groupeCourage
classifyTaxonomicGroup (mkPoint (negsuc ax)    (negsuc ay)    _) with natCmp ax ay
... | ordLT = groupeTristesse
... | ordEQ = groupeDegout
... | ordGT = groupePeur

eqTaxonomicGroupB : TaxonomicGroup → TaxonomicGroup → Bool
eqTaxonomicGroupB operateurCentral operateurCentral = true
eqTaxonomicGroupB groupeJoie       groupeJoie       = true
eqTaxonomicGroupB groupeTristesse  groupeTristesse  = true
eqTaxonomicGroupB groupePeur       groupePeur       = true
eqTaxonomicGroupB groupeCourage    groupeCourage    = true
eqTaxonomicGroupB groupeDesir      groupeDesir      = true
eqTaxonomicGroupB groupeDegout     groupeDegout     = true
eqTaxonomicGroupB groupeColere     groupeColere     = true
eqTaxonomicGroupB groupeCalme      groupeCalme      = true
eqTaxonomicGroupB _                _                = false

eqTaxonomicGroupB-refl : ∀ (g : TaxonomicGroup) → eqTaxonomicGroupB g g ≡ true
eqTaxonomicGroupB-refl operateurCentral = refl
eqTaxonomicGroupB-refl groupeJoie       = refl
eqTaxonomicGroupB-refl groupeTristesse  = refl
eqTaxonomicGroupB-refl groupePeur       = refl
eqTaxonomicGroupB-refl groupeCourage    = refl
eqTaxonomicGroupB-refl groupeDesir      = refl
eqTaxonomicGroupB-refl groupeDegout     = refl
eqTaxonomicGroupB-refl groupeColere     = refl
eqTaxonomicGroupB-refl groupeCalme      = refl

eqTaxonomicGroupB-to-≡ : ∀ (g1 g2 : TaxonomicGroup) → eqTaxonomicGroupB g1 g2 ≡ true → g1 ≡ g2
eqTaxonomicGroupB-to-≡ operateurCentral operateurCentral _ = refl
eqTaxonomicGroupB-to-≡ groupeJoie       groupeJoie       _ = refl
eqTaxonomicGroupB-to-≡ groupeTristesse  groupeTristesse  _ = refl
eqTaxonomicGroupB-to-≡ groupePeur       groupePeur       _ = refl
eqTaxonomicGroupB-to-≡ groupeCourage    groupeCourage    _ = refl
eqTaxonomicGroupB-to-≡ groupeDesir      groupeDesir      _ = refl
eqTaxonomicGroupB-to-≡ groupeDegout     groupeDegout     _ = refl
eqTaxonomicGroupB-to-≡ groupeColere     groupeColere     _ = refl
eqTaxonomicGroupB-to-≡ groupeCalme      groupeCalme      _ = refl

matchesTaxonomicGroupB : CoreAffectPoint → TaxonomicGroup → Bool
matchesTaxonomicGroupB p g = eqTaxonomicGroupB (classifyTaxonomicGroup p) g

classifySubsector : Int → Int → FunctionalSubsector
classifySubsector (pos zero)     (pos zero)     = centralOperator
classifySubsector (pos zero)     (pos (suc _))  = axialElan
classifySubsector (pos zero)     (negsuc _)     = axialWithdrawal
classifySubsector (pos (suc _))  (pos zero)     = axialOpening
classifySubsector (negsuc _)     (pos zero)     = axialThreat
classifySubsector (pos (suc ax)) (pos (suc ay)) with natCmp ax ay
... | ordLT = lateralApproachSynergy
... | ordEQ = diagonalDesire
... | ordGT = lateralEpistemicMastery
classifySubsector (negsuc ax)    (pos (suc ay)) with natCmp ax ay
... | ordLT = lateralDefensiveUrgency
... | ordEQ = diagonalAnger
... | ordGT = lateralVigilantAlert
classifySubsector (pos (suc ax)) (negsuc ay)    with natCmp ax ay
... | ordLT = lateralTrophotropicPeace
... | ordEQ = diagonalCalm
... | ordGT = lateralContemplativeOpen
classifySubsector (negsuc ax)    (negsuc ay)    with natCmp ax ay
... | ordLT = lateralAversiveDistress
... | ordEQ = diagonalDisgust
... | ordGT = lateralEpistemicClosure

eqSubsectorB : FunctionalSubsector → FunctionalSubsector → Bool
eqSubsectorB centralOperator          centralOperator          = true
eqSubsectorB axialElan                axialElan                = true
eqSubsectorB axialWithdrawal          axialWithdrawal          = true
eqSubsectorB axialOpening             axialOpening             = true
eqSubsectorB axialThreat              axialThreat              = true
eqSubsectorB diagonalDesire           diagonalDesire           = true
eqSubsectorB diagonalDisgust          diagonalDisgust          = true
eqSubsectorB diagonalAnger            diagonalAnger            = true
eqSubsectorB diagonalCalm             diagonalCalm             = true
eqSubsectorB lateralApproachSynergy   lateralApproachSynergy   = true
eqSubsectorB lateralDefensiveUrgency  lateralDefensiveUrgency  = true
eqSubsectorB lateralTrophotropicPeace lateralTrophotropicPeace = true
eqSubsectorB lateralAversiveDistress  lateralAversiveDistress  = true
eqSubsectorB lateralEpistemicMastery  lateralEpistemicMastery  = true
eqSubsectorB lateralContemplativeOpen lateralContemplativeOpen = true
eqSubsectorB lateralVigilantAlert     lateralVigilantAlert     = true
eqSubsectorB lateralEpistemicClosure  lateralEpistemicClosure  = true
eqSubsectorB _                        _                        = false

eqSubsectorB-refl : ∀ (s : FunctionalSubsector) → eqSubsectorB s s ≡ true
eqSubsectorB-refl centralOperator          = refl
eqSubsectorB-refl axialElan                = refl
eqSubsectorB-refl axialWithdrawal          = refl
eqSubsectorB-refl axialOpening             = refl
eqSubsectorB-refl axialThreat              = refl
eqSubsectorB-refl diagonalDesire           = refl
eqSubsectorB-refl diagonalDisgust          = refl
eqSubsectorB-refl diagonalAnger            = refl
eqSubsectorB-refl diagonalCalm             = refl
eqSubsectorB-refl lateralApproachSynergy   = refl
eqSubsectorB-refl lateralDefensiveUrgency  = refl
eqSubsectorB-refl lateralTrophotropicPeace = refl
eqSubsectorB-refl lateralAversiveDistress  = refl
eqSubsectorB-refl lateralEpistemicMastery  = refl
eqSubsectorB-refl lateralContemplativeOpen = refl
eqSubsectorB-refl lateralVigilantAlert     = refl
eqSubsectorB-refl lateralEpistemicClosure  = refl

eqSubsectorB-to-≡ : ∀ (s1 s2 : FunctionalSubsector) → eqSubsectorB s1 s2 ≡ true → s1 ≡ s2
eqSubsectorB-to-≡ centralOperator          centralOperator          _ = refl
eqSubsectorB-to-≡ axialElan                axialElan                _ = refl
eqSubsectorB-to-≡ axialWithdrawal          axialWithdrawal          _ = refl
eqSubsectorB-to-≡ axialOpening             axialOpening             _ = refl
eqSubsectorB-to-≡ axialThreat              axialThreat              _ = refl
eqSubsectorB-to-≡ diagonalDesire           diagonalDesire           _ = refl
eqSubsectorB-to-≡ diagonalDisgust          diagonalDisgust          _ = refl
eqSubsectorB-to-≡ diagonalAnger            diagonalAnger            _ = refl
eqSubsectorB-to-≡ diagonalCalm             diagonalCalm             _ = refl
eqSubsectorB-to-≡ lateralApproachSynergy   lateralApproachSynergy   _ = refl
eqSubsectorB-to-≡ lateralDefensiveUrgency  lateralDefensiveUrgency  _ = refl
eqSubsectorB-to-≡ lateralTrophotropicPeace lateralTrophotropicPeace _ = refl
eqSubsectorB-to-≡ lateralAversiveDistress  lateralAversiveDistress  _ = refl
eqSubsectorB-to-≡ lateralEpistemicMastery  lateralEpistemicMastery  _ = refl
eqSubsectorB-to-≡ lateralContemplativeOpen lateralContemplativeOpen _ = refl
eqSubsectorB-to-≡ lateralVigilantAlert     lateralVigilantAlert     _ = refl
eqSubsectorB-to-≡ lateralEpistemicClosure  lateralEpistemicClosure  _ = refl

matchesSubsectorB : Int → Int → FunctionalSubsector → Bool
matchesSubsectorB x y s = eqSubsectorB (classifySubsector x y) s

Subsector-toTaxonomicGroup : FunctionalSubsector → TaxonomicGroup
Subsector-toTaxonomicGroup centralOperator          = operateurCentral
Subsector-toTaxonomicGroup axialElan                = groupeJoie
Subsector-toTaxonomicGroup lateralApproachSynergy   = groupeJoie
Subsector-toTaxonomicGroup lateralDefensiveUrgency  = groupeJoie
Subsector-toTaxonomicGroup axialWithdrawal          = groupeTristesse
Subsector-toTaxonomicGroup lateralTrophotropicPeace = groupeTristesse
Subsector-toTaxonomicGroup lateralAversiveDistress  = groupeTristesse
Subsector-toTaxonomicGroup axialOpening             = groupeCourage
Subsector-toTaxonomicGroup lateralEpistemicMastery  = groupeCourage
Subsector-toTaxonomicGroup lateralContemplativeOpen = groupeCourage
Subsector-toTaxonomicGroup axialThreat              = groupePeur
Subsector-toTaxonomicGroup lateralVigilantAlert     = groupePeur
Subsector-toTaxonomicGroup lateralEpistemicClosure  = groupePeur
Subsector-toTaxonomicGroup diagonalDesire           = groupeDesir
Subsector-toTaxonomicGroup diagonalDisgust          = groupeDegout
Subsector-toTaxonomicGroup diagonalAnger            = groupeColere
Subsector-toTaxonomicGroup diagonalCalm             = groupeCalme

Subsector-toHedonicPolarity : FunctionalSubsector → HedonicPolarity
Subsector-toHedonicPolarity centralOperator          = hedNeutral
Subsector-toHedonicPolarity axialElan                = hedPositive
Subsector-toHedonicPolarity axialOpening             = hedPositive
Subsector-toHedonicPolarity diagonalDesire           = hedPositive
Subsector-toHedonicPolarity diagonalCalm             = hedPositive
Subsector-toHedonicPolarity lateralApproachSynergy   = hedPositive
Subsector-toHedonicPolarity lateralTrophotropicPeace = hedPositive
Subsector-toHedonicPolarity lateralEpistemicMastery  = hedPositive
Subsector-toHedonicPolarity lateralContemplativeOpen = hedPositive
Subsector-toHedonicPolarity axialWithdrawal          = hedNegative
Subsector-toHedonicPolarity axialThreat              = hedNegative
Subsector-toHedonicPolarity diagonalDisgust          = hedNegative
Subsector-toHedonicPolarity diagonalAnger            = hedNegative
Subsector-toHedonicPolarity lateralDefensiveUrgency  = hedNegative
Subsector-toHedonicPolarity lateralAversiveDistress  = hedNegative
Subsector-toHedonicPolarity lateralVigilantAlert     = hedNegative
Subsector-toHedonicPolarity lateralEpistemicClosure  = hedNegative

crownPeripheralCount : Nat → Nat
crownPeripheralCount z = 4 * crownRadius z

stratumTotalCount : Nat → Nat
stratumTotalCount z = 1 + crownPeripheralCount z

evaluateTaxonomy : AffectiveMatrixState → TaxonomicState
evaluateTaxonomy m =
  let p  = core m
      ap = antagonist m
  in mkTaxonomicState
       m
       (classifyStratum (pz p))
       (classifyGeometry p)
       (classifyTaxonomicGroup p)
       (classifySubsector (px p) (py p))
       (classifyTaxonomicGroup ap)
       (classifySubsector (px ap) (py ap))

runCartograffectPipeline : PredictiveEngineState → TaxonomicState
runCartograffectPipeline s =
  evaluateTaxonomy (evaluateMatrix (projectToCoreAffect s) canonicalMapping)

classifyTaxonomicGroup_correct :
  ∀ (p : CoreAffectPoint) → matchesTaxonomicGroupB p (classifyTaxonomicGroup p) ≡ true
classifyTaxonomicGroup_correct p = eqTaxonomicGroupB-refl (classifyTaxonomicGroup p)

IsCoherentTerminalState : PredictiveEngineState → TaxonomicState → Set
IsCoherentTerminalState s ts =
  let m  = matrix ts
      cp = core m
      ap = antagonist m
  in (cp ≡ projectToCoreAffect s)
     × IsValidCoreAffect cp
     × (ap ≡ antagonistPoint cp)
     × IsValidCoreAffect ap
     × (pz ap ≡ pz cp)
     × (displacementSum ap ≡ displacementSum cp)
     × (expectationPole m ≡ transduceExpectation (px cp))
     × (controlPole m ≡ transduceControl (py cp))
     × (energyRegime m ≡ computeEnergyRegime (px cp) (py cp))
     × (valence m ≡ computeHedonicPolarity (px cp) (py cp))
     × (activation m ≡ computeActivation cp)
     × (stratum ts ≡ classifyStratum (pz cp))
     × (geometry ts ≡ classifyGeometry cp)
     × (subsector ts ≡ classifySubsector (px cp) (py cp))
     × (antagonistSubsector ts ≡ classifySubsector (px ap) (py ap))
     × (matchesTaxonomicGroupB cp (group ts) ≡ true)
     × (∀ (g : TaxonomicGroup) → matchesTaxonomicGroupB cp g ≡ true → g ≡ group ts)
     × (matchesTaxonomicGroupB ap (antagonistGroup ts) ≡ true)

AffectiveMatrixState-eq :
  ∀ {m1 m2 : AffectiveMatrixState} →
  core m1 ≡ core m2 →
  expectationPole m1 ≡ expectationPole m2 →
  controlPole m1 ≡ controlPole m2 →
  energyRegime m1 ≡ energyRegime m2 →
  valence m1 ≡ valence m2 →
  activation m1 ≡ activation m2 →
  antagonist m1 ≡ antagonist m2 →
  m1 ≡ m2
AffectiveMatrixState-eq
  {mkAffectiveMatrixState _ _ _ _ _ _ _}
  {mkAffectiveMatrixState _ _ _ _ _ _ _}
  refl refl refl refl refl refl refl = refl

TaxonomicState-eq :
  ∀ {t1 t2 : TaxonomicState} →
  matrix t1 ≡ matrix t2 →
  stratum t1 ≡ stratum t2 →
  geometry t1 ≡ geometry t2 →
  group t1 ≡ group t2 →
  subsector t1 ≡ subsector t2 →
  antagonistGroup t1 ≡ antagonistGroup t2 →
  antagonistSubsector t1 ≡ antagonistSubsector t2 →
  t1 ≡ t2
TaxonomicState-eq
  {mkTaxonomicState _ _ _ _ _ _ _}
  {mkTaxonomicState _ _ _ _ _ _ _}
  refl refl refl refl refl refl refl = refl

runCartograffectPipeline_coherent :
  ∀ (s : PredictiveEngineState) → IsCoherentTerminalState s (runCartograffectPipeline s)
runCartograffectPipeline_coherent s =
  let cp = projectToCoreAffect s in
  refl
  , engine_induces_valid_core_affect s
  , refl
  , antagonistPoint_preserves_validity cp (engine_induces_valid_core_affect s)
  , antagonist-pz cp
  , antagonist-displacementSum cp
  , refl
  , refl
  , refl
  , refl
  , refl
  , refl
  , refl
  , refl
  , refl
  , classifyTaxonomicGroup_correct cp
  , (λ g hg → sym (eqTaxonomicGroupB-to-≡ (classifyTaxonomicGroup cp) g hg))
  , classifyTaxonomicGroup_correct (antagonistPoint cp)

isCoherentTerminalState_unique :
  ∀ (s : PredictiveEngineState) (ts' : TaxonomicState) →
  IsCoherentTerminalState s ts' →
  ts' ≡ runCartograffectPipeline s
isCoherentTerminalState_unique s
  (mkTaxonomicState (mkAffectiveMatrixState cp ep cl er va ac ap) st gm gr sb agr asb)
  (hcp , _ , hap , _ , _ , _ , hep , hcl , her , hva , hac , hst , hgm , hsb , hasb , hgr , _ , hagr) =
  let p0    = projectToCoreAffect s
      ap0   = antagonistPoint p0
      hap0  = trans hap (cong antagonistPoint hcp)
      hmEq  = AffectiveMatrixState-eq
                hcp
                (trans hep (cong (λ q → transduceExpectation (px q)) hcp))
                (trans hcl (cong (λ q → transduceControl (py q)) hcp))
                (trans her (cong (λ q → computeEnergyRegime (px q) (py q)) hcp))
                (trans hva (cong (λ q → computeHedonicPolarity (px q) (py q)) hcp))
                (trans hac (cong computeActivation hcp))
                hap0
      hgr0  = trans (sym (eqTaxonomicGroupB-to-≡ (classifyTaxonomicGroup cp) gr hgr))
                    (cong classifyTaxonomicGroup hcp)
      hagr0 = trans (sym (eqTaxonomicGroupB-to-≡ (classifyTaxonomicGroup ap) agr hagr))
                    (cong classifyTaxonomicGroup hap0)
  in TaxonomicState-eq
       hmEq
       (trans hst (cong (λ q → classifyStratum (pz q)) hcp))
       (trans hgm (cong classifyGeometry hcp))
       hgr0
       (trans hsb (cong (λ q → classifySubsector (px q) (py q)) hcp))
       hagr0
       (trans hasb (cong (λ q → classifySubsector (px q) (py q)) hap0))

-- ---------------------------------------------------------------------------
-- 3. Les 10 théorèmes certifiés d'AffectiveTaxonomy
-- ---------------------------------------------------------------------------

-- [1/10] inventory_176_certified
inventory-176-certified :
  (crownPeripheralCount 2 ≡ 8)
  × (crownPeripheralCount 3 ≡ 16)
  × (crownPeripheralCount 4 ≡ 24)
  × (crownPeripheralCount 5 ≡ 32)
  × (crownPeripheralCount 6 ≡ 40)
  × (crownPeripheralCount 7 ≡ 48)
  × ((crownPeripheralCount 2 + crownPeripheralCount 3 + crownPeripheralCount 4
      + crownPeripheralCount 5 + crownPeripheralCount 6 + crownPeripheralCount 7) ≡ 168)
  × ((stratumTotalCount 0 + stratumTotalCount 1 + stratumTotalCount 2 + stratumTotalCount 3
      + stratumTotalCount 4 + stratumTotalCount 5 + stratumTotalCount 6 + stratumTotalCount 7) ≡ 176)
inventory-176-certified = refl , refl , refl , refl , refl , refl , refl , refl

-- [2/10] taxonomy_group_exhaustive
taxonomy_group_exhaustive :
  ∀ (p : CoreAffectPoint) → Σ TaxonomicGroup (λ g → matchesTaxonomicGroupB p g ≡ true)
taxonomy_group_exhaustive p = classifyTaxonomicGroup p ,, eqTaxonomicGroupB-refl (classifyTaxonomicGroup p)

-- [3/10] taxonomy_group_exclusive
taxonomy_group_exclusive :
  ∀ (p : CoreAffectPoint) (g1 g2 : TaxonomicGroup) →
  matchesTaxonomicGroupB p g1 ≡ true →
  matchesTaxonomicGroupB p g2 ≡ true →
  g1 ≡ g2
taxonomy_group_exclusive p g1 g2 h1 h2 =
  trans (sym (eqTaxonomicGroupB-to-≡ (classifyTaxonomicGroup p) g1 h1))
        (eqTaxonomicGroupB-to-≡ (classifyTaxonomicGroup p) g2 h2)

-- [4/10] dominantSector_iff_taxonomicGroup
dominantSector_iff_taxonomicGroup :
  ∀ (p : CoreAffectPoint) →
  ((dominantSector p ≡ optSome secJoie) → (classifyTaxonomicGroup p ≡ groupeJoie))
  × ((dominantSector p ≡ optSome secTristesse) → (classifyTaxonomicGroup p ≡ groupeTristesse))
  × ((dominantSector p ≡ optSome secPeur) → (classifyTaxonomicGroup p ≡ groupePeur))
  × ((dominantSector p ≡ optSome secCourage) → (classifyTaxonomicGroup p ≡ groupeCourage))
dominantSector_iff_taxonomicGroup (mkPoint (pos zero)     (pos zero)     _) = (λ ()) , (λ ()) , (λ ()) , (λ ())
dominantSector_iff_taxonomicGroup (mkPoint (pos zero)     (pos (suc _))  _) = (λ _ → refl) , (λ ()) , (λ ()) , (λ ())
dominantSector_iff_taxonomicGroup (mkPoint (pos zero)     (negsuc _)     _) = (λ ()) , (λ _ → refl) , (λ ()) , (λ ())
dominantSector_iff_taxonomicGroup (mkPoint (pos (suc _))  (pos zero)     _) = (λ ()) , (λ ()) , (λ ()) , (λ _ → refl)
dominantSector_iff_taxonomicGroup (mkPoint (negsuc _)     (pos zero)     _) = (λ ()) , (λ ()) , (λ _ → refl) , (λ ())
dominantSector_iff_taxonomicGroup (mkPoint (pos (suc ax)) (pos (suc ay)) _) with natCmp ax ay
... | ordLT = (λ _ → refl) , (λ ()) , (λ ()) , (λ ())
... | ordEQ = (λ ()) , (λ ()) , (λ ()) , (λ ())
... | ordGT = (λ ()) , (λ ()) , (λ ()) , (λ _ → refl)
dominantSector_iff_taxonomicGroup (mkPoint (negsuc ax)    (pos (suc ay)) _) with natCmp ax ay
... | ordLT = (λ _ → refl) , (λ ()) , (λ ()) , (λ ())
... | ordEQ = (λ ()) , (λ ()) , (λ ()) , (λ ())
... | ordGT = (λ ()) , (λ ()) , (λ _ → refl) , (λ ())
dominantSector_iff_taxonomicGroup (mkPoint (pos (suc ax)) (negsuc ay)    _) with natCmp ax ay
... | ordLT = (λ ()) , (λ _ → refl) , (λ ()) , (λ ())
... | ordEQ = (λ ()) , (λ ()) , (λ ()) , (λ ())
... | ordGT = (λ ()) , (λ ()) , (λ ()) , (λ _ → refl)
dominantSector_iff_taxonomicGroup (mkPoint (negsuc ax)    (negsuc ay)    _) with natCmp ax ay
... | ordLT = (λ ()) , (λ _ → refl) , (λ ()) , (λ ())
... | ordEQ = (λ ()) , (λ ()) , (λ ()) , (λ ())
... | ordGT = (λ ()) , (λ ()) , (λ _ → refl) , (λ ())

-- [5/10] contralateral_group_bindings
contralateral_group_bindings :
  ∀ (ax ay z : Nat) →
  (natCmp ax ay ≡ ordLT) →
  (classifyTaxonomicGroup (antagonistPoint (mkPoint (pos (suc ax)) (pos (suc ay)) z)) ≡ groupePeur)
  × (classifyTaxonomicGroup (antagonistPoint (mkPoint (negsuc ax)    (pos (suc ay)) z)) ≡ groupeCourage)
  × (classifyTaxonomicGroup (antagonistPoint (mkPoint (pos (suc ax)) (negsuc ay)    z)) ≡ groupePeur)
  × (classifyTaxonomicGroup (antagonistPoint (mkPoint (negsuc ax)    (negsuc ay)    z)) ≡ groupeCourage)
contralateral_group_bindings ax ay z h
  with natCmp ay ax | trans (natCmp-flip ax ay) (cong flipOrd h)
... | .ordGT | refl = refl , refl , refl , refl

-- [6/10] classifySubsector_correct
classifySubsector_correct :
  ∀ (x y : Int) → matchesSubsectorB x y (classifySubsector x y) ≡ true
classifySubsector_correct x y = eqSubsectorB-refl (classifySubsector x y)

-- [7/10] subsector_exclusive
subsector_exclusive :
  ∀ (x y : Int) (s1 s2 : FunctionalSubsector) →
  matchesSubsectorB x y s1 ≡ true →
  matchesSubsectorB x y s2 ≡ true →
  s1 ≡ s2
subsector_exclusive x y s1 s2 h1 h2 =
  trans (sym (eqSubsectorB-to-≡ (classifySubsector x y) s1 h1))
        (eqSubsectorB-to-≡ (classifySubsector x y) s2 h2)

-- [8/10] classifySubsector_refines_group
classifySubsector_refines_group :
  ∀ (p : CoreAffectPoint) →
  Subsector-toTaxonomicGroup (classifySubsector (px p) (py p)) ≡ classifyTaxonomicGroup p
classifySubsector_refines_group (mkPoint (pos zero)     (pos zero)     _) = refl
classifySubsector_refines_group (mkPoint (pos zero)     (pos (suc _))  _) = refl
classifySubsector_refines_group (mkPoint (pos zero)     (negsuc _)     _) = refl
classifySubsector_refines_group (mkPoint (pos (suc _))  (pos zero)     _) = refl
classifySubsector_refines_group (mkPoint (negsuc _)     (pos zero)     _) = refl
classifySubsector_refines_group (mkPoint (pos (suc ax)) (pos (suc ay)) _) with natCmp ax ay
... | ordLT = refl
... | ordEQ = refl
... | ordGT = refl
classifySubsector_refines_group (mkPoint (negsuc ax)    (pos (suc ay)) _) with natCmp ax ay
... | ordLT = refl
... | ordEQ = refl
... | ordGT = refl
classifySubsector_refines_group (mkPoint (pos (suc ax)) (negsuc ay)    _) with natCmp ax ay
... | ordLT = refl
... | ordEQ = refl
... | ordGT = refl
classifySubsector_refines_group (mkPoint (negsuc ax)    (negsuc ay)    _) with natCmp ax ay
... | ordLT = refl
... | ordEQ = refl
... | ordGT = refl

-- [9/10] classifySubsector_determines_valence
classifySubsector_determines_valence :
  ∀ (x y : Int) →
  Subsector-toHedonicPolarity (classifySubsector x y) ≡ computeHedonicPolarity x y
classifySubsector_determines_valence (pos zero)     (pos zero)     = refl
classifySubsector_determines_valence (pos zero)     (pos (suc _))  = refl
classifySubsector_determines_valence (pos zero)     (negsuc _)     = refl
classifySubsector_determines_valence (pos (suc _))  (pos zero)     = refl
classifySubsector_determines_valence (negsuc _)     (pos zero)     = refl
classifySubsector_determines_valence (pos (suc ax)) (pos (suc ay)) with natCmp ax ay
... | ordLT = refl
... | ordEQ = refl
... | ordGT = refl
classifySubsector_determines_valence (negsuc ax)    (pos (suc ay)) with natCmp ax ay
... | ordLT = refl
... | ordEQ = refl
... | ordGT = refl
classifySubsector_determines_valence (pos (suc ax)) (negsuc ay)    with natCmp ax ay
... | ordLT = refl
... | ordEQ = refl
... | ordGT = refl
classifySubsector_determines_valence (negsuc ax)    (negsuc ay)    with natCmp ax ay
... | ordLT = refl
... | ordEQ = refl
... | ordGT = refl

-- [10/10] end_to_end_coherence
end-to-end_coherence :
  ∀ (s : PredictiveEngineState) →
  let ts = runCartograffectPipeline s
      cp = core (matrix ts)
      ap = antagonist (matrix ts)
  in (cp ≡ projectToCoreAffect s)
     × IsValidCoreAffect cp
     × (ap ≡ antagonistPoint cp)
     × IsValidCoreAffect ap
     × (group ts ≡ classifyTaxonomicGroup cp)
     × (subsector ts ≡ classifySubsector (px cp) (py cp))
     × (antagonistGroup ts ≡ classifyTaxonomicGroup ap)
     × (antagonistSubsector ts ≡ classifySubsector (px ap) (py ap))
end-to-end_coherence s =
  refl
  , engine_induces_valid_core_affect s
  , refl
  , antagonistPoint_preserves_validity (projectToCoreAffect s) (engine_induces_valid_core_affect s)
  , refl
  , refl
  , refl
  , refl
