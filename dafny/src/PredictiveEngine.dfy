/*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*/

module PredictiveEngine {

  // =========================================================================
  // 1. Types fondamentaux des gradients et régimes fonctionnels
  // =========================================================================

  datatype Polarity = Neg | Zero | Pos

  function DefaultPolarity(): Polarity {
    Neg
  }

  datatype FunctionalRegime = Charge | Neutral | Discharge

  function DefaultFunctionalRegime(): FunctionalRegime {
    Charge
  }

  function PolarityToRegime(p: Polarity): FunctionalRegime {
    match p
    case Neg  => Charge
    case Zero => Neutral
    case Pos  => Discharge
  }

  function PolarityInvert(p: Polarity): Polarity {
    match p
    case Neg  => Pos
    case Zero => Zero
    case Pos  => Neg
  }

  function PolarityToInt(p: Polarity): int {
    match p
    case Neg  => -1
    case Zero => 0
    case Pos  => 1
  }

  predicate PolarityIsEngaged(p: Polarity) {
    match p
    case Zero => false
    case Neg  => true
    case Pos  => true
  }

  // =========================================================================
  // 2. Signaux d'entrée, Interfaces et Opérations inférentielles
  // =========================================================================

  datatype SalientDiscrepancyRaw = SalientDiscrepancyRaw(
    magnitude: nat,
    sensoryThreshold: nat,
    resorptionThreshold: nat
  )

  type SalientDiscrepancy = d: SalientDiscrepancyRaw |
    d.resorptionThreshold <= d.sensoryThreshold
    witness SalientDiscrepancyRaw(0, 1, 1)

  function DefaultSalientDiscrepancy(): SalientDiscrepancy {
    SalientDiscrepancyRaw(0, 1, 1)
  }

  predicate IsSensorilySalient(d: SalientDiscrepancy) {
    d.sensoryThreshold <= d.magnitude
  }

  predicate IsInRemanenceWindow(d: SalientDiscrepancy) {
    d.resorptionThreshold <= d.magnitude && d.magnitude < d.sensoryThreshold
  }

  datatype PerceptiveInterface = PerceptiveInterface(controleGradient: Polarity)

  function DefaultPerceptiveInterface(): PerceptiveInterface {
    PerceptiveInterface(DefaultPolarity())
  }

  datatype SubjectiveInterface = SubjectiveInterface(
    attenteGradient: Polarity,
    descendingSuspension: bool
  )

  function DefaultSubjectiveInterface(): SubjectiveInterface {
    SubjectiveInterface(DefaultPolarity(), false)
  }

  datatype AttentionalInterface = AttentionalInterface(
    allocatedPrecision: nat,
    engagementThreshold: nat,
    persistenceDepth: nat,
    precisionA: nat,
    precisionC: nat
  )

  function DefaultAttentionalInterface(): AttentionalInterface {
    AttentionalInterface(0, 0, 0, 1, 1)
  }

  predicate AttentionalIsEngaged(att: AttentionalInterface) {
    att.engagementThreshold <= att.allocatedPrecision
  }

  datatype InferentialOperation =
    | AscendingSensory
    | ActionImplementation
    | ContextualGenerative
    | IntegrativeWeighting

  datatype EngineInterface = Perceptive | Subjective | Attentional

  function CarrierInterface(op: InferentialOperation): EngineInterface {
    match op
    case AscendingSensory     => Perceptive
    case ActionImplementation => Perceptive
    case ContextualGenerative => Subjective
    case IntegrativeWeighting => Attentional
  }

  // =========================================================================
  // 3. Espace des couplages (A/C) et État global du Moteur prédictif
  // =========================================================================

  datatype EngineCoupling = EngineCoupling(attente: Polarity, controle: Polarity)

  function DefaultEngineCoupling(): EngineCoupling {
    EngineCoupling(DefaultPolarity(), DefaultPolarity())
  }

  predicate IsGlobalNeutrality(c: EngineCoupling) {
    !PolarityIsEngaged(c.attente) && !PolarityIsEngaged(c.controle)
  }

  predicate IsSingleEngaged(c: EngineCoupling) {
    (PolarityIsEngaged(c.attente) && !PolarityIsEngaged(c.controle)) ||
    (!PolarityIsEngaged(c.attente) && PolarityIsEngaged(c.controle))
  }

  predicate IsDualEngaged(c: EngineCoupling) {
    PolarityIsEngaged(c.attente) && PolarityIsEngaged(c.controle)
  }

  function AllCouplings(): seq<EngineCoupling> {
    [
      EngineCoupling(Zero, Zero),
      EngineCoupling(Pos,  Zero),
      EngineCoupling(Neg,  Zero),
      EngineCoupling(Zero, Pos),
      EngineCoupling(Zero, Neg),
      EngineCoupling(Pos,  Pos),
      EngineCoupling(Pos,  Neg),
      EngineCoupling(Neg,  Pos),
      EngineCoupling(Neg,  Neg)
    ]
  }

  datatype PredictiveEngineState = PredictiveEngineState(
    discrepancy: SalientDiscrepancy,
    perceptive: PerceptiveInterface,
    subjective: SubjectiveInterface,
    attentional: AttentionalInterface
  )

  function DefaultPredictiveEngineState(): PredictiveEngineState {
    PredictiveEngineState(
      DefaultSalientDiscrepancy(),
      DefaultPerceptiveInterface(),
      DefaultSubjectiveInterface(),
      DefaultAttentionalInterface()
    )
  }

  function CurrentCoupling(s: PredictiveEngineState): EngineCoupling {
    EngineCoupling(s.subjective.attenteGradient, s.perceptive.controleGradient)
  }

  function FeedbackUpdate(
    s: PredictiveEngineState,
    newA: Polarity,
    newC: Polarity,
    newPrecision: nat
  ): PredictiveEngineState {
    PredictiveEngineState(
      s.discrepancy,
      PerceptiveInterface(newC),
      SubjectiveInterface(newA, s.subjective.descendingSuspension),
      AttentionalInterface(
        newPrecision,
        s.attentional.engagementThreshold,
        s.attentional.persistenceDepth,
        s.attentional.precisionA,
        s.attentional.precisionC
      )
    )
  }

  function FeedbackUpdateWeighted(
    s: PredictiveEngineState,
    newA: Polarity,
    newC: Polarity,
    newPrecision: nat,
    newPrecisionA: nat,
    newPrecisionC: nat
  ): PredictiveEngineState {
    PredictiveEngineState(
      s.discrepancy,
      PerceptiveInterface(newC),
      SubjectiveInterface(newA, s.subjective.descendingSuspension),
      AttentionalInterface(
        newPrecision,
        s.attentional.engagementThreshold,
        s.attentional.persistenceDepth,
        newPrecisionA,
        newPrecisionC
      )
    )
  }

  function EngineStep(s: PredictiveEngineState): PredictiveEngineState {
    var c := CurrentCoupling(s);
    if !IsSensorilySalient(s.discrepancy) then
      if IsInRemanenceWindow(s.discrepancy) then
        s
      else
        PredictiveEngineState(
          s.discrepancy,
          PerceptiveInterface(Zero),
          SubjectiveInterface(Zero, false),
          AttentionalInterface(
            0,
            s.attentional.engagementThreshold,
            0,
            s.attentional.precisionA,
            s.attentional.precisionC
          )
        )
    else if IsGlobalNeutrality(c) then
      PredictiveEngineState(
        s.discrepancy,
        PerceptiveInterface(Pos),
        s.subjective,
        s.attentional
      )
    else if !s.subjective.descendingSuspension && !AttentionalIsEngaged(s.attentional) then
      PredictiveEngineState(
        s.discrepancy,
        s.perceptive,
        SubjectiveInterface(s.subjective.attenteGradient, true),
        s.attentional
      )
    else if !AttentionalIsEngaged(s.attentional) then
      PredictiveEngineState(
        s.discrepancy,
        s.perceptive,
        s.subjective,
        AttentionalInterface(
          s.attentional.engagementThreshold,
          s.attentional.engagementThreshold,
          s.attentional.persistenceDepth,
          s.attentional.precisionA,
          s.attentional.precisionC
        )
      )
    else
      s
  }

  // =========================================================================
  // 4. Démonstration des invariants fondamentaux du Moteur prédictif
  // =========================================================================

  lemma Polarity_invert_involutive(p: Polarity)
    ensures PolarityInvert(PolarityInvert(p)) == p
  {
    match p
    case Neg  =>
    case Zero =>
    case Pos  =>
  }

  lemma Polarity_toRegime_neutral_iff(p: Polarity)
    ensures PolarityToRegime(p) == Neutral <==> p == Zero
  {
    match p
    case Neg  =>
    case Zero =>
    case Pos  =>
  }

  lemma single_neutral_not_global_neutral()
    ensures exists c: EngineCoupling :: c.attente == Zero && !IsGlobalNeutrality(c)
  {
    var w := EngineCoupling(Zero, Pos);
    assert w.attente == Zero && !IsGlobalNeutrality(w);
  }

  lemma allCouplings_card()
    ensures |AllCouplings()| == 9
  {
  }

  lemma mem_allCouplings(c: EngineCoupling)
    ensures c in AllCouplings()
  {
    var all := AllCouplings();
    match (c.attente, c.controle)
    case (Zero, Zero) => assert c == all[0];
    case (Pos,  Zero) => assert c == all[1];
    case (Neg,  Zero) => assert c == all[2];
    case (Zero, Pos)  => assert c == all[3];
    case (Zero, Neg)  => assert c == all[4];
    case (Pos,  Pos)  => assert c == all[5];
    case (Pos,  Neg)  => assert c == all[6];
    case (Neg,  Pos)  => assert c == all[7];
    case (Neg,  Neg)  => assert c == all[8];
  }

  lemma coupling_regime_partition(c: EngineCoupling)
    ensures
      (IsGlobalNeutrality(c) && !IsSingleEngaged(c) && !IsDualEngaged(c)) ||
      (!IsGlobalNeutrality(c) && IsSingleEngaged(c) && !IsDualEngaged(c)) ||
      (!IsGlobalNeutrality(c) && !IsSingleEngaged(c) && IsDualEngaged(c))
  {
    match c.attente
    case Neg  =>
    case Zero =>
    case Pos  =>
  }

  lemma feedbackUpdate_couples_gradients(
    s: PredictiveEngineState,
    newA: Polarity,
    newC: Polarity,
    newPrecision: nat
  )
    ensures CurrentCoupling(FeedbackUpdate(s, newA, newC, newPrecision)) == EngineCoupling(newA, newC)
    ensures FeedbackUpdate(s, newA, newC, newPrecision).attentional.allocatedPrecision == newPrecision
    ensures FeedbackUpdate(s, newA, newC, newPrecision).discrepancy == s.discrepancy
  {
  }

  lemma feedbackUpdateWeighted_couples_precision(
    s: PredictiveEngineState,
    newA: Polarity,
    newC: Polarity,
    newPrecision: nat,
    newPrecisionA: nat,
    newPrecisionC: nat
  )
    ensures CurrentCoupling(FeedbackUpdateWeighted(s, newA, newC, newPrecision, newPrecisionA, newPrecisionC)) == EngineCoupling(newA, newC)
    ensures FeedbackUpdateWeighted(s, newA, newC, newPrecision, newPrecisionA, newPrecisionC).attentional.allocatedPrecision == newPrecision
    ensures FeedbackUpdateWeighted(s, newA, newC, newPrecision, newPrecisionA, newPrecisionC).attentional.precisionA == newPrecisionA
    ensures FeedbackUpdateWeighted(s, newA, newC, newPrecision, newPrecisionA, newPrecisionC).attentional.precisionC == newPrecisionC
    ensures FeedbackUpdateWeighted(s, newA, newC, newPrecision, newPrecisionA, newPrecisionC).discrepancy == s.discrepancy
  {
  }

  lemma inferential_loop_covers_interfaces(iface: EngineInterface)
    ensures exists op: InferentialOperation :: CarrierInterface(op) == iface
  {
    match iface
    case Perceptive  => assert CarrierInterface(AscendingSensory) == Perceptive;
    case Subjective  => assert CarrierInterface(ContextualGenerative) == Subjective;
    case Attentional => assert CarrierInterface(IntegrativeWeighting) == Attentional;
  }

  lemma engineStep_remanence(s: PredictiveEngineState)
    requires IsInRemanenceWindow(s.discrepancy)
    ensures EngineStep(s) == s
  {
  }

  lemma engineStep_phase_progression(s0: PredictiveEngineState)
    requires IsSensorilySalient(s0.discrepancy)
    requires IsGlobalNeutrality(CurrentCoupling(s0))
    requires !s0.subjective.descendingSuspension
    requires !AttentionalIsEngaged(s0.attentional)
    ensures
      var s1 := EngineStep(s0);
      var s2 := EngineStep(s1);
      var s3 := EngineStep(s2);
      (IsSensorilySalient(s1.discrepancy) && !IsGlobalNeutrality(CurrentCoupling(s1)) &&
       !s1.subjective.descendingSuspension && !AttentionalIsEngaged(s1.attentional)) &&
      (IsSensorilySalient(s2.discrepancy) && !IsGlobalNeutrality(CurrentCoupling(s2)) &&
       s2.subjective.descendingSuspension && !AttentionalIsEngaged(s2.attentional)) &&
      (IsSensorilySalient(s3.discrepancy) && !IsGlobalNeutrality(CurrentCoupling(s3)) &&
       s3.subjective.descendingSuspension && AttentionalIsEngaged(s3.attentional))
  {
    var s1 := EngineStep(s0);
    var s2 := EngineStep(s1);
    var s3 := EngineStep(s2);
    assert !IsGlobalNeutrality(CurrentCoupling(s1));
    assert s2.subjective.descendingSuspension;
    assert AttentionalIsEngaged(s3.attentional);
  }

}
