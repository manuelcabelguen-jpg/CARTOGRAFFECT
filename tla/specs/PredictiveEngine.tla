------------------------- MODULE PredictiveEngine -------------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Module 01 : Moteur inferentiel predictif (TLA+ / TLC)
*)
EXTENDS Integers

Polarities == {"neg", "zero", "pos"}
FunctionalRegimes == {"charge", "neutral", "discharge"}
InferentialOperations == {
  "ascendingSensory",
  "actionImplementation",
  "contextualGenerative",
  "integrativeWeighting"
}
EngineInterfaces == {"perceptive", "subjective", "attentional"}

PolarityToRegime(p) ==
  IF p = "neg" THEN "charge"
  ELSE IF p = "zero" THEN "neutral"
  ELSE "discharge"

PolarityInvert(p) ==
  IF p = "neg" THEN "pos"
  ELSE IF p = "zero" THEN "zero"
  ELSE "neg"

PolarityIsEngaged(p) == p # "zero"

InferentialCarrierInterface(op) ==
  IF op \in {"ascendingSensory", "actionImplementation"} THEN "perceptive"
  ELSE IF op = "contextualGenerative" THEN "subjective"
  ELSE "attentional"

MkDiscrepancy(mag, sThr, rThr) ==
  [magnitude |-> mag, sensoryThreshold |-> sThr, resorptionThreshold |-> rThr]

ValidDiscrepancy(d) ==
  /\ d.magnitude >= 0
  /\ d.sensoryThreshold >= 0
  /\ d.resorptionThreshold >= 0
  /\ d.resorptionThreshold <= d.sensoryThreshold

IsSensorilySalient(d) == d.sensoryThreshold <= d.magnitude

IsInRemanenceWindow(d) ==
  /\ d.resorptionThreshold <= d.magnitude
  /\ d.magnitude < d.sensoryThreshold

MkPerceptive(cGrad) == [controleGradient |-> cGrad]
MkSubjective(aGrad, susp) == [attenteGradient |-> aGrad, descendingSuspension |-> susp]
MkAttentional(alloc, thr, depth, pA, pC) ==
  [allocatedPrecision |-> alloc,
   engagementThreshold |-> thr,
   persistenceDepth |-> depth,
   precisionA |-> pA,
   precisionC |-> pC]

ValidAttentional(a) ==
  /\ a.allocatedPrecision >= 0
  /\ a.engagementThreshold >= 0
  /\ a.persistenceDepth >= 0
  /\ a.precisionA >= 0
  /\ a.precisionC >= 0

AttentionalIsEngaged(a) == a.engagementThreshold <= a.allocatedPrecision

MkCoupling(aPol, cPol) == [attente |-> aPol, controle |-> cPol]
Couplings == {[attente |-> a, controle |-> c] : a \in Polarities, c \in Polarities}

IsGlobalNeutrality(c) ==
  /\ ~PolarityIsEngaged(c.attente)
  /\ ~PolarityIsEngaged(c.controle)

IsSingleEngaged(c) ==
  \/ (PolarityIsEngaged(c.attente) /\ ~PolarityIsEngaged(c.controle))
  \/ (~PolarityIsEngaged(c.attente) /\ PolarityIsEngaged(c.controle))

IsDualEngaged(c) ==
  /\ PolarityIsEngaged(c.attente)
  /\ PolarityIsEngaged(c.controle)

MkEngineState(d, perc, subj, att) ==
  [discrepancy |-> d, perceptive |-> perc, subjective |-> subj, attentional |-> att]

ValidEngineState(s) ==
  /\ ValidDiscrepancy(s.discrepancy)
  /\ s.perceptive.controleGradient \in Polarities
  /\ s.subjective.attenteGradient \in Polarities
  /\ s.subjective.descendingSuspension \in BOOLEAN
  /\ ValidAttentional(s.attentional)

CurrentCoupling(s) ==
  MkCoupling(s.subjective.attenteGradient, s.perceptive.controleGradient)

FeedbackUpdate(s, newA, newC, newPrecision) ==
  MkEngineState(
    s.discrepancy,
    MkPerceptive(newC),
    MkSubjective(newA, s.subjective.descendingSuspension),
    MkAttentional(
      newPrecision,
      s.attentional.engagementThreshold,
      s.attentional.persistenceDepth,
      s.attentional.precisionA,
      s.attentional.precisionC
    )
  )

FeedbackUpdateWeighted(s, newA, newC, newPrecision, newPA, newPC) ==
  MkEngineState(
    s.discrepancy,
    MkPerceptive(newC),
    MkSubjective(newA, s.subjective.descendingSuspension),
    MkAttentional(
      newPrecision,
      s.attentional.engagementThreshold,
      s.attentional.persistenceDepth,
      newPA,
      newPC
    )
  )

DefaultEngineState ==
  MkEngineState(
    MkDiscrepancy(0, 2, 1),
    MkPerceptive("zero"),
    MkSubjective("zero", FALSE),
    MkAttentional(0, 2, 0, 1, 1)
  )

EngineStep(s) ==
  LET c == CurrentCoupling(s) IN
  IF ~IsSensorilySalient(s.discrepancy) THEN
    IF IsInRemanenceWindow(s.discrepancy) THEN s
    ELSE MkEngineState(
           s.discrepancy,
           MkPerceptive("zero"),
           MkSubjective("zero", FALSE),
           MkAttentional(0, s.attentional.engagementThreshold, 0,
                         s.attentional.precisionA, s.attentional.precisionC)
         )
  ELSE IF IsGlobalNeutrality(c) THEN
    MkEngineState(s.discrepancy, MkPerceptive("pos"), s.subjective, s.attentional)
  ELSE IF ~s.subjective.descendingSuspension /\ ~AttentionalIsEngaged(s.attentional) THEN
    MkEngineState(s.discrepancy, s.perceptive,
                  MkSubjective(s.subjective.attenteGradient, TRUE), s.attentional)
  ELSE IF ~AttentionalIsEngaged(s.attentional) THEN
    MkEngineState(
      s.discrepancy, s.perceptive, s.subjective,
      MkAttentional(s.attentional.engagementThreshold,
                    s.attentional.engagementThreshold,
                    s.attentional.persistenceDepth,
                    s.attentional.precisionA,
                    s.attentional.precisionC)
    )
  ELSE s

-----------------------------------------------------------------------------
(* Finite parameterizable audit predicates for the 7 theorems of Module 01 *)
-----------------------------------------------------------------------------

\* [1/7] polarity_invert_involutive
Thm_polarity_invert_involutive ==
  \A p \in Polarities : PolarityInvert(PolarityInvert(p)) = p

\* [2/7] coupling_regime_partition
Thm_coupling_regime_partition ==
  \A c \in Couplings :
    \/ (IsGlobalNeutrality(c) /\ ~IsSingleEngaged(c) /\ ~IsDualEngaged(c))
    \/ (~IsGlobalNeutrality(c) /\ IsSingleEngaged(c) /\ ~IsDualEngaged(c))
    \/ (~IsGlobalNeutrality(c) /\ ~IsSingleEngaged(c) /\ IsDualEngaged(c))

\* [3/7] feedbackUpdate_couples_gradients
Thm_feedbackUpdate_couples_gradients(StateSet) ==
  \A s \in StateSet, newA \in Polarities, newC \in Polarities, newP \in 0..4 :
    /\ CurrentCoupling(FeedbackUpdate(s, newA, newC, newP)) = MkCoupling(newA, newC)
    /\ (FeedbackUpdate(s, newA, newC, newP)).attentional.allocatedPrecision = newP

\* [4/7] inferential_loop_covers_interfaces
Thm_inferential_loop_covers_interfaces ==
  \A iface \in EngineInterfaces :
    \E op \in InferentialOperations : InferentialCarrierInterface(op) = iface

\* [5/7] feedbackUpdateWeighted_couples_precision
Thm_feedbackUpdateWeighted_couples_precision(StateSet) ==
  \A s \in StateSet, newA \in Polarities, newC \in Polarities, newP \in 0..2, nPA \in 0..2, nPC \in 0..2 :
    LET s1 == FeedbackUpdateWeighted(s, newA, newC, newP, nPA, nPC) IN
    /\ CurrentCoupling(s1) = MkCoupling(newA, newC)
    /\ s1.attentional.allocatedPrecision = newP
    /\ s1.attentional.precisionA = nPA
    /\ s1.attentional.precisionC = nPC

\* [6/7] engineStep_remanence
Thm_engineStep_remanence(StateSet) ==
  \A s \in StateSet :
    (~IsSensorilySalient(s.discrepancy) /\ IsInRemanenceWindow(s.discrepancy)) =>
      EngineStep(s) = s

\* [7/7] engineStep_phase_progression
Thm_engineStep_phase_progression(StateSet) ==
  \A s \in StateSet :
    (IsSensorilySalient(s.discrepancy)
     /\ IsGlobalNeutrality(CurrentCoupling(s))
     /\ ~s.subjective.descendingSuspension
     /\ ~AttentionalIsEngaged(s.attentional)) =>
      LET s1 == EngineStep(s)
          s2 == EngineStep(s1)
          s3 == EngineStep(s2)
      IN  /\ PolarityIsEngaged(CurrentCoupling(s1).controle)
          /\ s2.subjective.descendingSuspension
          /\ AttentionalIsEngaged(s3.attentional)

=============================================================================
