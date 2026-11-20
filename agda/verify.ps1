# Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
# SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
# Author: Manuel Cabelguen
#
# Autonomous verification script for the Agda 2.9.0 formalization of CARTOGRAFFECT.
# Checks:
#   1. Presence of agda binary (--safe --without-K).
#   2. Every .agda file begins with {-# OPTIONS --safe --without-K #-}.
#   3. Zero forbidden constructs (postulate, trustMe, primTrustMe, TRUSTME, holes {!,
#      --type-in-type, --unsafe, --rewriting, --allow-unsolved-metas, --sized-types, --guardedness).
#   4. All 113 audited theorem declarations and 11 concrete evaluation blocks exist.
#   5. Clean build from scratch (deleting all *.agdai) of all 10 modules in topological order.

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SrcDir    = Join-Path $ScriptDir "src"

function Find-Agda {
    if ($env:AGDA_BIN -and (Test-Path $env:AGDA_BIN)) { return $env:AGDA_BIN }
    $localAgda = "$env:USERPROFILE\.local\tools\agda\agda.exe"
    if (Test-Path $localAgda) { return $localAgda }
    $cmd = Get-Command "agda" -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "Agda binary not found. Set AGDA_BIN or install Agda 2.9.0."
}

$AgdaExe = Find-Agda
$AgdaVer = (& $AgdaExe --version | Select-Object -First 1).Trim()

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " CARTOGRAFFECT - Agda Formal Verification Suite (--safe --without-K)"    -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "Toolchain : $AgdaVer"
Write-Host "Binary    : $AgdaExe"
Write-Host "Source    : $SrcDir"
Write-Host ""

$Modules = @(
    "Cartograffect\Prelude.agda",
    "Cartograffect\PredictiveEngine.agda",
    "Cartograffect\CoreAffect.agda",
    "Cartograffect\AffectiveMatrix.agda",
    "Cartograffect\AffectiveTaxonomy.agda",
    "Cartograffect\AffectiveDynamics.agda",
    "Cartograffect\Lexicon176.agda",
    "Cartograffect\PredictiveCircuit.agda",
    "Cartograffect\AuditTests.agda",
    "Cartograffect.agda"
)

# 1. Static audit: --safe --without-K header + zero forbidden tokens
Write-Host "[1/3] Static Safety Audit (--safe --without-K, 0 postulates/holes)..." -ForegroundColor Yellow

$ForbiddenPatterns = @(
    @{ Name = "postulate";             Regex = '(?m)^\s*postulate\b' },
    @{ Name = "trustMe";               Regex = '\btrustMe\b' },
    @{ Name = "primTrustMe";           Regex = '\bprimTrustMe\b' },
    @{ Name = "TRUSTME";               Regex = 'BUILTIN\s+TRUSTME' },
    @{ Name = "hole {! ... !}";        Regex = '\{!' },
    @{ Name = "--type-in-type";        Regex = '--type-in-type' },
    @{ Name = "--unsafe";              Regex = '--unsafe' },
    @{ Name = "--rewriting";           Regex = '--rewriting' },
    @{ Name = "--allow-unsolved-metas";Regex = '--allow-unsolved-metas' },
    @{ Name = "--sized-types";         Regex = '--sized-types' },
    @{ Name = "--guardedness";         Regex = '--guardedness' }
)

$TotalLines = 0
foreach ($rel in $Modules) {
    $full = Join-Path $SrcDir $rel
    if (-not (Test-Path $full)) {
        throw "Missing Agda module: $full"
    }
    $lines = [System.IO.File]::ReadAllLines($full, [System.Text.Encoding]::UTF8)
    $TotalLines += $lines.Count
    $firstLine = $lines[0].Trim()
    if ($firstLine -ne "{-# OPTIONS --safe --without-K #-}") {
        throw "File $rel does not start with '{-# OPTIONS --safe --without-K #-}' (found: '$firstLine')"
    }
    # Strip comments before scanning for forbidden tokens
    $codeLines = $lines | Where-Object { $_ -notmatch '^\s*--' }
    $codeText  = ($codeLines -join "`n")
    foreach ($fp in $ForbiddenPatterns) {
        if ($codeText -match $fp.Regex) {
            throw "Forbidden construct '$($fp.Name)' found in $rel"
        }
    }
}
Write-Host "  OK: 10/10 modules enforce {-# OPTIONS --safe --without-K #-} ($TotalLines lines total, 0 postulates/holes)." -ForegroundColor Green

# 2. Theorem & Evaluation Block Census
Write-Host "[2/3] Auditing 113 Theorem Symbols & 11 Evaluation Blocks..." -ForegroundColor Yellow

$ExpectedTheorems = @(
    # Module 01: PredictiveEngine (7)
    "Polarity_invert_involutive",
    "coupling_regime_partition",
    "feedbackUpdate_couples_gradients",
    "inferential_loop_covers_interfaces",
    "feedbackUpdateWeighted_couples_precision",
    "engineStep_remanence",
    "engineStep_phase_progression",
    # Module 02: CoreAffect (23)
    "engine_induces_valid_core_affect",
    "z2_budget_conservation",
    "axial-to-diagonal_reallocation",
    "dissipationStep_valid",
    "dissipationStep_fixed_iff",
    "dissipation_strictly_decreases",
    "remanence_preserves_state",
    "cooperative_step_leaves_crown",
    "deployCouplingWithPrecision_valid",
    "neutral_coupling_without_suspension_yields_veille",
    "neutral_or_subthreshold-with-suspension_yields_central",
    "descending_suspension_yields_central_operator",
    "central_z_ge2_requires_descending_suspension",
    "deployCouplingWithPrecision_budget_conservation",
    "dual_engaged_yields_diagonal_z2_precision",
    "symmetric_precision_never_lateral",
    "projectToCoreAffect_surjective",
    "engineStep_canonical_trajectory",
    "engineStep_surprise_to_crown",
    "anticipation_short_circuits_to_veille",
    "dissipation_from_ge2_never_visits_surprise",
    "dissipationPotential_short_circuit_jump",
    "dissipation_reaches_veille",
    # Module 03: AffectiveMatrix (13)
    "HedonicPolarity_invert_involutive",
    "x_positive_determines_positive_valence",
    "x_negative_determines_negative_valence",
    "antagonistPoint_preserves_validity",
    "antagonistPoint_involutive",
    "contralateral_swaps_amplitudes",
    "antagonist_commutes-with-invert",
    "antagonistPoint_unified",
    "antagonist_preserves_validity-in",
    "transferUnitYtoX_preserves_sum",
    "antagonist_commutes-with-invert_precision",
    "evaluateMatrix_core_antagonist_independent",
    "mapping_independent_antagonist_invariants",
    # Module 04: AffectiveTaxonomy (10)
    "inventory-176-certified",
    "taxonomy_group_exhaustive",
    "taxonomy_group_exclusive",
    "dominantSector_iff_taxonomicGroup",
    "contralateral_group_bindings",
    "classifySubsector_correct",
    "subsector_exclusive",
    "classifySubsector_refines_group",
    "classifySubsector_determines_valence",
    "end-to-end_coherence",
    # Module 05: AffectiveDynamics (10)
    "canonicalDepthKernel_reaches_crown",
    "canonicalDepthKernel_reaches_lateral",
    "lateral_reachable",
    "lateral_reachable_from_surprise",
    "canonicalDepthKernel_colere_bifurcates",
    "canonicalDepthKernel_axial_instability_p2",
    "canonicalDepthKernel_outgoingWeight_pos",
    "classifyTaxonomicGroup_unique_maximizer",
    "classifyTaxonomicGroup_maximizes_membership",
    "lateral_has_overlapping_attractors",
    # Module 06: Lexicon176 (8)
    "all176Entries_length",
    "all176Entries_geometrically_valid",
    "all176Entries_z_bounds",
    "all176Entries_unique_points",
    "all176Entries_complete",
    "all176Entries_deterministically_reachable",
    "all176Entries_reachable_by_engine",
    "all176Entries_witness_check",
    # Module 07: PredictiveCircuit (41)
    "circuit_covers_interfaces_both_sides",
    "circuit_refines_inferential_ops",
    "phiL1_left_inv",
    "phiL1_right_inv",
    "phiL1_agrees-with-deployZ2",
    "crossingII_is_transpose_of_crossingI",
    "routeToSubjective_injective",
    "routeToPerceptive_injective",
    "projectPerceptible_valid",
    "projectPerceptible_z2_matches_phiL1",
    "projectPerceptible_neutral_elevates-to-central",
    "attentional_bottleneck_sum_active",
    "circuitRowSum_exact",
    "veille_absorbing_free",
    "lyapunov_monotone_free",
    "lyapunov_strict_descent_witness",
    "lyapunov_expected_drift_constant",
    "axial_peur_bifurcates_p2",
    "veille_reaches_all_one_step",
    "all_reach_veille_two_steps",
    "veille_unreachable_when_eps_max",
    "circularCycle_veille_fixed_point",
    "circularCycle_reduces_total_discrepancy",
    "lyapunov_drift_charge-with-passive_extinction",
    "p1_without_p2_eps_independent",
    "epistemic_rigidity_traps_charge_slice",
    "pragmatic_helplessness_traps_charge_slice",
    "perseveration_traps_discharge_free",
    "passive_extinction_zero_relief",
    "active_resolution_beats_passive_extinction",
    "charge_accumulator_bounded",
    "nextStratumR5_le_zMax",
    "nextStratumR5_short_circuits_z2-to-veille",
    "nextStratumR5_from_ge2_never_visits_surprise",
    "symmetricSigmoid_sum",
    "symmetricSigmoid_pos",
    "symmetricSigmoid_neg",
    "precisionShare_double_charge_cancels_alpha",
    "projectUnifiedState_valid",
    "projectUnifiedState_crown_budget",
    "projectUnifiedState_reaches_lateral_consternation",
    # Module 08: AuditTests (1)
    "all176Entries_antagonist_inverts_hedonic_polarity"
)

if ($ExpectedTheorems.Count -ne 113) {
    throw "Internal error: ExpectedTheorems count is $($ExpectedTheorems.Count), expected 113."
}

$AllCombined = ""
foreach ($rel in $Modules) {
    $AllCombined += "`n" + [System.IO.File]::ReadAllText((Join-Path $SrcDir $rel), [System.Text.Encoding]::UTF8)
}

foreach ($thm in $ExpectedTheorems) {
    $escaped = [Regex]::Escape($thm)
    if ($AllCombined -notmatch "(?m)^$escaped\s*:") {
        throw "Missing theorem signature for '$thm'"
    }
}

for ($b = 1; $b -le 11; $b++) {
    $bName = ("eval_block-{0:D2}" -f $b)
    $escaped = [Regex]::Escape($bName)
    if ($AllCombined -notmatch "(?m)^$escaped\s*:") {
        throw "Missing evaluation block '$bName'"
    }
}
Write-Host "  OK: 113/113 theorem signatures and 11/11 evaluation blocks verified." -ForegroundColor Green

# 3. Clean-room Agda typechecking
Write-Host "[3/3] Clean-Room Typechecking (10 modules in topological order)..." -ForegroundColor Yellow

Get-ChildItem -Path $SrcDir -Recurse -Filter "*.agdai" -ErrorAction SilentlyContinue | Remove-Item -Force

$TotalSw = [System.Diagnostics.Stopwatch]::StartNew()
foreach ($rel in $Modules) {
    $full = Join-Path $SrcDir $rel
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $out = & cmd /c "chcp 65001 >nul && `"$AgdaExe`" -i `"$SrcDir`" `"$full`" 2>&1"
    $exitCode = $LASTEXITCODE
    $sw.Stop()
    if ($exitCode -ne 0) {
        Write-Host ($out -join "`n") -ForegroundColor Red
        throw "Agda typechecking failed on $rel (exit code $exitCode)"
    }
    $sec = "{0:N2}" -f $sw.Elapsed.TotalSeconds
    Write-Host ("  [PASS] {0,-38} ({1} s)" -f $rel, $sec) -ForegroundColor Green
}
$TotalSw.Stop()
$TotalSec = "{0:N2}" -f $TotalSw.Elapsed.TotalSeconds

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " ALL 10 AGDA MODULES (113 THEOREMS + 11 EVAL BLOCKS) VERIFIED IN $TotalSec s" -ForegroundColor Green
Write-Host "========================================================================" -ForegroundColor Cyan
exit 0
