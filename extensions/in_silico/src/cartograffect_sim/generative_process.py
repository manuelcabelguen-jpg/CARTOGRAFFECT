"""Processus génératif environnemental (tâche de décision séquentielle par blocs).

Implémente un bandit non stationnaire contextuel à contingences variables,
strictement indépendant de la topologie affective de l'agent (`CARTOGRAFFECT`),
manipulant orthogonalement :
    - ``p_ctrl in [0.1, 0.9]`` : contrôlabilité objective de l'issue par l'action ;
    - ``v_rule in [0.05, 0.5]`` et ``cue_clarity`` (I_cue) : volatilité des
      règles latentes et clarté des indices épistémiques ;
    - ``d_obj in {2, 3, 4}`` : niveau d'abstraction de la perturbation
      (2 = sensorimoteur ponctuel, 3 = échec de séquence immédiate,
       4 = rétroaction évaluative sur la performance globale) ;
    - Des blocs de rémission neutre sans perturbation saillante permettant de
      mesurer la cinétique pure de dissipation allostatique.
"""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass, field
from enum import IntEnum
from typing import Any, Iterable, Sequence

import numpy as np


class BanditAction(IntEnum):
    """Actions comportementales discrètes disponibles dans l'environnement."""

    CHOICE_A = 0
    CHOICE_B = 1
    PROBE_CUE = 2


class CueSignal(IntEnum):
    """Signaux d'indices épistémiques émis avant le choix."""

    RULE_A = 0
    RULE_B = 1
    AMBIGUOUS = 2


class OutcomeValence(IntEnum):
    """Valence objective discrète de l'issue environnementale."""

    NEGATIVE = -1
    NEUTRAL = 0
    POSITIVE = 1


class PerturbationAbstractionLevel(IntEnum):
    """Niveau d'abstraction objective ``d_obj`` de la perturbation."""

    SENSORIMOTOR_POINTWISE = 2
    IMMEDIATE_SEQUENCE = 3
    EVALUATIVE_GLOBAL = 4


@dataclass(frozen=True)
class BlockSpec:
    """Spécification d'un bloc expérimental du bandit non stationnaire."""

    block_id: int
    name: str
    num_trials: int
    p_ctrl: float
    v_rule: float
    cue_clarity: float
    d_obj: int
    is_remission: bool = False
    evaluative_interval: int = 5
    sequence_window: int = 3

    def __post_init__(self) -> None:
        if self.num_trials < 1:
            raise ValueError(f"num_trials doit être >= 1 (reçu {self.num_trials})")
        if not (0.1 <= self.p_ctrl <= 0.9):
            raise ValueError(
                f"p_ctrl doit être dans [0.1, 0.9] (reçu {self.p_ctrl})"
            )
        if not (0.05 <= self.v_rule <= 0.5):
            raise ValueError(
                f"v_rule doit être dans [0.05, 0.5] (reçu {self.v_rule})"
            )
        if not (0.0 <= self.cue_clarity <= 1.0):
            raise ValueError(
                f"cue_clarity doit être dans [0.0, 1.0] (reçu {self.cue_clarity})"
            )
        if self.d_obj not in (2, 3, 4):
            raise ValueError(
                f"d_obj doit être dans {{2, 3, 4}} (reçu {self.d_obj})"
            )
        if self.evaluative_interval < 1:
            raise ValueError("evaluative_interval doit être >= 1")
        if self.sequence_window < 1:
            raise ValueError("sequence_window doit être >= 1")


@dataclass(frozen=True)
class TrialObservation:
    """Observation objective exposée à l'agent (sans état affectif ni règle latente)."""

    trial_index: int
    block_id: int
    block_name: str
    trial_in_block: int
    cue: CueSignal
    outcome: OutcomeValence
    reward: float
    perturbation_active: bool
    perturbation_intensity: float
    d_obj: int
    is_remission: bool
    evaluative_score: float | None = None
    sequence_failure_rate: float = 0.0
    block_accuracy: float = 1.0

    def sensory_payload(self) -> dict[str, Any]:
        """Extrait exclusivement les observations sensorielles accessibles à l'agent.

        Exclut toute variable cachée de bloc (``is_remission``, ``d_obj``,
        ``perturbation_active``, ``perturbation_intensity``, ``block_id``, ``block_name``)
        afin de garantir l'orthogonalité stricte entre environnement et agent.
        """
        return {
            "cue": self.cue,
            "outcome": self.outcome,
            "reward": self.reward,
            "evaluative_score": self.evaluative_score,
            "sequence_failure_rate": self.sequence_failure_rate,
        }


@dataclass(frozen=True)
class TrialGroundTruth:
    """Vérité terrain objective de l'environnement pour évaluation et audit."""

    trial_index: int
    block_id: int
    latent_rule: int
    rule_switched: bool
    action_taken: BanditAction
    optimal_action: BanditAction
    matched_rule: bool
    p_ctrl: float
    v_rule: float
    cue_clarity: float
    d_obj: int
    is_remission: bool


@dataclass(frozen=True)
class EnvStepResult:
    """Paire (observation agent, vérité terrain) produite à chaque pas de la tâche."""

    observation: TrialObservation
    ground_truth: TrialGroundTruth


def default_400_trial_schedule() -> tuple[BlockSpec, ...]:
    """Retourne un protocole standard de 400 essais (10 blocs × 40 essais).

    Manipule orthogonalement :
        - contrôlabilité ``p_ctrl`` faible (0.15) vs élevée (0.85) ;
        - volatilité ``v_rule`` faible (0.05) vs élevée (0.40-0.45) et clarté
          ``cue_clarity`` élevée (0.90) vs faible (0.20-0.30) ;
        - niveau d'abstraction ``d_obj`` in {2, 3, 4} ;
        - 3 blocs de rémission neutre sans perturbation saillante.
    """
    return (
        BlockSpec(
            block_id=0,
            name="high_ctrl_low_vol_d2",
            num_trials=40,
            p_ctrl=0.85,
            v_rule=0.05,
            cue_clarity=0.90,
            d_obj=2,
        ),
        BlockSpec(
            block_id=1,
            name="remission_1",
            num_trials=40,
            p_ctrl=0.50,
            v_rule=0.05,
            cue_clarity=0.90,
            d_obj=2,
            is_remission=True,
        ),
        BlockSpec(
            block_id=2,
            name="low_ctrl_low_vol_d2",
            num_trials=40,
            p_ctrl=0.15,
            v_rule=0.05,
            cue_clarity=0.90,
            d_obj=2,
        ),
        BlockSpec(
            block_id=3,
            name="high_ctrl_high_vol_ambiguous_d2",
            num_trials=40,
            p_ctrl=0.85,
            v_rule=0.40,
            cue_clarity=0.30,
            d_obj=2,
        ),
        BlockSpec(
            block_id=4,
            name="remission_2",
            num_trials=40,
            p_ctrl=0.50,
            v_rule=0.05,
            cue_clarity=0.90,
            d_obj=2,
            is_remission=True,
        ),
        BlockSpec(
            block_id=5,
            name="low_ctrl_low_vol_sequence_d3",
            num_trials=40,
            p_ctrl=0.25,
            v_rule=0.10,
            cue_clarity=0.80,
            d_obj=3,
        ),
        BlockSpec(
            block_id=6,
            name="high_ctrl_high_vol_sequence_d3",
            num_trials=40,
            p_ctrl=0.75,
            v_rule=0.35,
            cue_clarity=0.25,
            d_obj=3,
        ),
        BlockSpec(
            block_id=7,
            name="low_ctrl_mod_vol_evaluative_d4",
            num_trials=40,
            p_ctrl=0.15,
            v_rule=0.20,
            cue_clarity=0.60,
            d_obj=4,
        ),
        BlockSpec(
            block_id=8,
            name="high_ctrl_high_vol_evaluative_d4",
            num_trials=40,
            p_ctrl=0.85,
            v_rule=0.45,
            cue_clarity=0.20,
            d_obj=4,
        ),
        BlockSpec(
            block_id=9,
            name="remission_3",
            num_trials=40,
            p_ctrl=0.60,
            v_rule=0.05,
            cue_clarity=0.95,
            d_obj=2,
            is_remission=True,
        ),
    )


class NonStationaryBanditEnv:
    """Environnement expérimental de bandit non stationnaire orthogonal à l'agent."""

    def __init__(
        self,
        schedule: Sequence[BlockSpec] | None = None,
        seed: int | None = 42,
    ) -> None:
        blocks = tuple(schedule) if schedule is not None else default_400_trial_schedule()
        if not blocks:
            raise ValueError("Le protocole de blocs ne peut pas être vide")
        self.schedule: tuple[BlockSpec, ...] = blocks
        self.seed = seed
        self._rng = np.random.default_rng(seed)

        # Compteurs et état latent courant
        self._block_idx: int = 0
        self._trial_in_block: int = 0
        self._global_trial: int = 0
        self._latent_rule: int = 0
        self._last_rule_switched: bool = False
        self._current_cue: CueSignal = CueSignal.RULE_A
        self._recent_failures: deque[int] = deque(maxlen=3)
        self._block_correct_count: int = 0
        self._block_choice_count: int = 0
        self._history: list[EnvStepResult] = []
        self.reset(seed=seed)

    @property
    def total_trials(self) -> int:
        return sum(b.num_trials for b in self.schedule)

    @property
    def is_done(self) -> bool:
        return self._global_trial >= self.total_trials

    @property
    def current_block(self) -> BlockSpec:
        if self._block_idx >= len(self.schedule):
            return self.schedule[-1]
        return self.schedule[self._block_idx]

    @property
    def history(self) -> tuple[EnvStepResult, ...]:
        return tuple(self._history)

    def reset(self, seed: int | None = None) -> TrialObservation:
        """Réinitialise la session expérimentale et retourne la sonde d'indice t=0."""
        if seed is not None:
            self.seed = seed
        self._rng = np.random.default_rng(self.seed)
        self._block_idx = 0
        self._trial_in_block = 0
        self._global_trial = 0
        self._latent_rule = int(self._rng.integers(0, 2))
        self._last_rule_switched = False
        self._recent_failures = deque(
            maxlen=self.schedule[0].sequence_window
        )
        self._block_correct_count = 0
        self._block_choice_count = 0
        self._history = []
        self._current_cue = self._sample_cue(self.current_block)
        return self._build_initial_observation()

    def current_observation(self) -> TrialObservation:
        """Retourne l'observation préparatoire du pas courant avant choix."""
        blk = self.current_block
        seq_err = (
            float(np.mean(self._recent_failures)) if self._recent_failures else 0.0
        )
        blk_acc = (
            self._block_correct_count / self._block_choice_count
            if self._block_choice_count > 0
            else 1.0
        )
        return TrialObservation(
            trial_index=self._global_trial,
            block_id=blk.block_id,
            block_name=blk.name,
            trial_in_block=self._trial_in_block,
            cue=self._current_cue,
            outcome=OutcomeValence.NEUTRAL,
            reward=0.0,
            perturbation_active=False,
            perturbation_intensity=0.0,
            d_obj=blk.d_obj,
            is_remission=blk.is_remission,
            evaluative_score=None,
            sequence_failure_rate=seq_err,
            block_accuracy=blk_acc,
        )

    def _build_initial_observation(self) -> TrialObservation:
        return self.current_observation()

    def _sample_cue(self, blk: BlockSpec) -> CueSignal:
        if blk.is_remission:
            return CueSignal(self._latent_rule)
        u = float(self._rng.random())
        if u < blk.cue_clarity:
            return CueSignal(self._latent_rule)
        if u < blk.cue_clarity + 0.7 * (1.0 - blk.cue_clarity):
            return CueSignal.AMBIGUOUS
        return CueSignal(1 - self._latent_rule)

    def step(self, action: int | BanditAction) -> EnvStepResult:
        """Exécute un essai comportemental et avance vers l'essai suivant."""
        if self.is_done:
            raise RuntimeError("La session expérimentale est déjà terminée")

        act = BanditAction(int(action))
        blk = self.current_block
        rule_before_step = self._latent_rule
        optimal = BanditAction(rule_before_step)
        matched_rule = act == optimal

        # 1. Émission de l'issue et de la perturbation selon le bloc et d_obj
        evaluative_score: float | None = None
        if blk.is_remission:
            # Rémission neutre : aucune perturbation saillante afin d'isoler
            # la cinétique pure de dissipation allostatique.
            outcome = OutcomeValence.NEUTRAL
            reward = 0.0
            perturbation_active = False
            perturbation_intensity = 0.0
            self._recent_failures.append(0)
            if act != BanditAction.PROBE_CUE:
                self._block_choice_count += 1
                self._block_correct_count += int(matched_rule)
        else:
            if act == BanditAction.PROBE_CUE:
                # L'action épistémique interroge la règle latente sans gain pragmatique
                outcome = OutcomeValence.NEUTRAL
                reward = 0.0
                perturbation_active = False
                perturbation_intensity = 0.0
                # Renvoie un indice épistémique clarifié pour le pas suivant
            else:
                self._block_choice_count += 1
                self._block_correct_count += int(matched_rule)
                # Contingence ΔP = p_ctrl exactement :
                # P(succès | bon bras)  = 0.5 + 0.5 * p_ctrl
                # P(succès | mauvais)   = 0.5 - 0.5 * p_ctrl
                p_success = 0.5 + (0.5 * blk.p_ctrl if matched_rule else -0.5 * blk.p_ctrl)
                succeeded = bool(self._rng.random() < p_success)
                self._recent_failures.append(0 if succeeded else 1)

                seq_err = float(np.mean(self._recent_failures))
                blk_acc = self._block_correct_count / max(1, self._block_choice_count)

                if blk.d_obj == PerturbationAbstractionLevel.SENSORIMOTOR_POINTWISE:
                    if succeeded:
                        outcome = OutcomeValence.POSITIVE
                        reward = 1.0
                        perturbation_active = False
                        perturbation_intensity = 0.0
                    else:
                        outcome = OutcomeValence.NEGATIVE
                        reward = -1.0
                        perturbation_active = True
                        perturbation_intensity = float(1.0 - 0.5 * blk.p_ctrl)
                elif blk.d_obj == PerturbationAbstractionLevel.IMMEDIATE_SEQUENCE:
                    sequence_failed = (not succeeded) or (seq_err >= 2.0 / 3.0)
                    if sequence_failed and not succeeded:
                        outcome = OutcomeValence.NEGATIVE
                        reward = -1.0
                        perturbation_active = True
                        perturbation_intensity = float(min(1.0, 0.5 + 0.5 * seq_err))
                    elif succeeded and seq_err <= 0.34:
                        outcome = OutcomeValence.POSITIVE
                        reward = 1.0
                        perturbation_active = False
                        perturbation_intensity = 0.0
                    else:
                        outcome = OutcomeValence.NEUTRAL
                        reward = 0.0
                        perturbation_active = bool(seq_err >= 0.6)
                        perturbation_intensity = float(seq_err) if perturbation_active else 0.0
                else:
                    # d_obj == 4 : rétroaction évaluative périodique sur la performance globale
                    is_eval_tick = (self._trial_in_block + 1) % blk.evaluative_interval == 0
                    evaluative_score = blk_acc if is_eval_tick else None
                    if is_eval_tick:
                        if blk_acc < 0.65:
                            outcome = OutcomeValence.NEGATIVE
                            reward = -1.0
                            perturbation_active = True
                            perturbation_intensity = float(np.clip(1.0 - blk_acc, 0.25, 1.0))
                        else:
                            outcome = OutcomeValence.POSITIVE
                            reward = 1.0
                            perturbation_active = False
                            perturbation_intensity = 0.0
                    else:
                        if succeeded:
                            outcome = OutcomeValence.POSITIVE
                            reward = 0.5
                            perturbation_active = False
                            perturbation_intensity = 0.0
                        else:
                            outcome = OutcomeValence.NEUTRAL if blk_acc >= 0.65 else OutcomeValence.NEGATIVE
                            reward = -0.5 if outcome == OutcomeValence.NEGATIVE else 0.0
                            perturbation_active = outcome == OutcomeValence.NEGATIVE
                            perturbation_intensity = (
                                float(np.clip(0.8 - 0.5 * blk_acc, 0.15, 0.9))
                                if perturbation_active
                                else 0.0
                            )

        seq_err_now = (
            float(np.mean(self._recent_failures)) if self._recent_failures else 0.0
        )
        blk_acc_now = (
            self._block_correct_count / self._block_choice_count
            if self._block_choice_count > 0
            else 1.0
        )

        # Préparer le prochain pas et gérer la volatilité v_rule de la règle latente
        cue_for_record = self._current_cue
        obs = TrialObservation(
            trial_index=self._global_trial,
            block_id=blk.block_id,
            block_name=blk.name,
            trial_in_block=self._trial_in_block,
            cue=cue_for_record,
            outcome=outcome,
            reward=reward,
            perturbation_active=perturbation_active,
            perturbation_intensity=perturbation_intensity,
            d_obj=blk.d_obj,
            is_remission=blk.is_remission,
            evaluative_score=evaluative_score,
            sequence_failure_rate=seq_err_now,
            block_accuracy=blk_acc_now,
        )
        gt = TrialGroundTruth(
            trial_index=self._global_trial,
            block_id=blk.block_id,
            latent_rule=rule_before_step,
            rule_switched=self._last_rule_switched,
            action_taken=act,
            optimal_action=optimal,
            matched_rule=matched_rule,
            p_ctrl=blk.p_ctrl,
            v_rule=blk.v_rule,
            cue_clarity=blk.cue_clarity,
            d_obj=blk.d_obj,
            is_remission=blk.is_remission,
        )
        result = EnvStepResult(observation=obs, ground_truth=gt)
        self._history.append(result)

        # Avancement temporel et transition éventuelle de règle / bloc
        self._global_trial += 1
        self._trial_in_block += 1

        if not self.is_done:
            if self._trial_in_block >= blk.num_trials:
                self._block_idx += 1
                self._trial_in_block = 0
                next_blk = self.current_block
                self._recent_failures = deque(maxlen=next_blk.sequence_window)
                self._block_correct_count = 0
                self._block_choice_count = 0
            else:
                next_blk = blk

            # Inversion stochastique de règle gouvernée par v_rule
            if not next_blk.is_remission and self._rng.random() < next_blk.v_rule:
                self._latent_rule = 1 - self._latent_rule
                self._last_rule_switched = True
            else:
                self._last_rule_switched = False

            if act == BanditAction.PROBE_CUE and not next_blk.is_remission:
                # L'action épistémique révèle un indice fortement informatif
                clarity = max(next_blk.cue_clarity, 0.90)
                self._current_cue = (
                    CueSignal(self._latent_rule)
                    if self._rng.random() < clarity
                    else CueSignal.AMBIGUOUS
                )
            else:
                self._current_cue = self._sample_cue(next_blk)

        return result

    def summarize(self) -> dict[str, float | int]:
        """Retourne un résumé quantitatif objectif de la session exécutée."""
        if not self._history:
            return {
                "num_trials": 0,
                "mean_reward": 0.0,
                "accuracy": 0.0,
                "accuracy_non_remission": 0.0,
                "probe_rate_non_remission": 0.0,
            }
        rewards = [h.observation.reward for h in self._history]
        non_rem = [h for h in self._history if not h.ground_truth.is_remission]
        non_rem_choices = [
            h for h in non_rem if h.ground_truth.action_taken != BanditAction.PROBE_CUE
        ]
        acc = (
            float(np.mean([h.ground_truth.matched_rule for h in non_rem_choices]))
            if non_rem_choices
            else 1.0
        )
        probe_rate = (
            float(np.mean([h.ground_truth.action_taken == BanditAction.PROBE_CUE for h in non_rem]))
            if non_rem
            else 0.0
        )
        return {
            "num_trials": len(self._history),
            "mean_reward": float(np.mean(rewards)),
            "total_reward": float(np.sum(rewards)),
            "accuracy_non_remission": acc,
            "probe_rate_non_remission": probe_rate,
            "rule_switches": sum(1 for h in self._history if h.ground_truth.rule_switched),
        }


__all__ = [
    "BanditAction",
    "BlockSpec",
    "CueSignal",
    "EnvStepResult",
    "NonStationaryBanditEnv",
    "OutcomeValence",
    "PerturbationAbstractionLevel",
    "TrialGroundTruth",
    "TrialObservation",
    "default_400_trial_schedule",
]
