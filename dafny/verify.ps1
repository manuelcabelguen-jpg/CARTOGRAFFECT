<#
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Autonomous Dafny 4.11.0 formal verification & parity execution script for Cartograffect.
#>
[CmdletBinding()]
param(
  [string]$DafnyBin = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$dafnyRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$srcDir = Join-Path $dafnyRoot "src"
$cfgPath = Join-Path $dafnyRoot "dfyconfig.toml"

# 1. Discover Dafny.exe cleanly
if (-not $DafnyBin) {
  $candidates = @(
    "$env:LOCALAPPDATA\dafny-4.11.0\dafny\Dafny.exe",
    "$env:USERPROFILE\.local\tools\dafny\Dafny.exe"
  )
  foreach ($c in $candidates) {
    if (Test-Path $c) { $DafnyBin = $c; break }
  }
  if (-not $DafnyBin) {
    $cmd = Get-Command dafny -ErrorAction SilentlyContinue
    if ($cmd) { $DafnyBin = $cmd.Source }
  }
}
if (-not $DafnyBin -or -not (Test-Path $DafnyBin)) {
  Write-Error "Dafny binary not found. Pass -DafnyBin or install Dafny 4.11.0."
  exit 1
}

$ver = (& $DafnyBin --version 2>&1 | Out-String).Trim()
Write-Host "[Dafny] Binary : $DafnyBin"
Write-Host "[Dafny] Version: $ver"

# 2. Static integrity audit (comment & string stripped)
function Strip-DafnyCommentsAndStrings([string]$text) {
  $noBlock = [regex]::Replace($text, '(?s)/\*.*?\*/', ' ')
  $noLine = [regex]::Replace($noBlock, '//.*', ' ')
  $noStr = [regex]::Replace($noLine, '"(?:\\.|[^"\\])*"', '""')
  return $noStr
}

$dfyFiles = Get-ChildItem -Path $srcDir -Filter "*.dfy" | Sort-Object Name
$declaredLemmas = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::Ordinal)
foreach ($f in $dfyFiles) {
  $raw = Get-Content -Path $f.FullName -Raw -Encoding UTF8
  $cleaned = Strip-DafnyCommentsAndStrings $raw
  if ($cleaned -match '\bassume\b') {
    Write-Error "Forbidden 'assume' found in $($f.Name)"
    exit 1
  }
  if ($cleaned -match '\{\s*:axiom\b' -or $cleaned -match '\{\s*:verify\s+false\b' -or $cleaned -match '\{\s*:extern\b') {
    Write-Error "Forbidden pragma (:axiom / :verify false / :extern) found in $($f.Name)"
    exit 1
  }
  $ms = [regex]::Matches($cleaned, '(?m)^\s*lemma\s+(?:\{[^\}]+\}\s+)*([A-Za-z0-9_]+)')
  foreach ($m in $ms) {
    [void]$declaredLemmas.Add($m.Groups[1].Value)
  }
}

$expected113 = @(
  # PredictiveEngine (7)
  "Polarity_invert_involutive", "coupling_regime_partition", "feedbackUpdate_couples_gradients",
  "inferential_loop_covers_interfaces", "feedbackUpdateWeighted_couples_precision",
  "engineStep_remanence", "engineStep_phase_progression",
  # CoreAffect (23)
  "engine_induces_valid_core_affect", "z2_budget_conservation", "axial_to_diagonal_reallocation",
  "dissipationStep_valid", "dissipationStep_fixed_iff", "dissipation_strictly_decreases",
  "remanence_preserves_state", "cooperative_step_leaves_crown", "deployCouplingWithPrecision_valid",
  "neutral_coupling_without_suspension_yields_veille", "neutral_or_subthreshold_with_suspension_yields_central",
  "descending_suspension_yields_central_operator", "central_z_ge2_requires_descending_suspension",
  "deployCouplingWithPrecision_budget_conservation", "dual_engaged_yields_diagonal_z2_precision",
  "symmetric_precision_never_lateral", "projectToCoreAffect_surjective",
  "engineStep_canonical_trajectory", "engineStep_surprise_to_crown",
  "anticipation_short_circuits_to_veille", "dissipation_from_ge2_never_visits_surprise",
  "dissipationPotential_short_circuit_jump", "dissipation_reaches_veille",
  # AffectiveMatrix (13)
  "HedonicPolarity_invert_involutive", "x_positive_determines_positive_valence",
  "x_negative_determines_negative_valence", "antagonistPoint_preserves_validity",
  "antagonistPoint_involutive", "contralateral_swaps_amplitudes",
  "antagonist_commutes_with_invert", "antagonistPoint_unified",
  "antagonist_preserves_validity_in", "transferUnitYtoX_preserves_sum",
  "antagonist_commutes_with_invert_precision", "evaluateMatrix_core_antagonist_independent",
  "mapping_independent_antagonist_invariants",
  # AffectiveTaxonomy (10)
  "inventory_176_certified", "taxonomy_group_exhaustive", "taxonomy_group_exclusive",
  "dominantSector_iff_taxonomicGroup", "contralateral_group_bindings",
  "classifySubsector_correct", "subsector_exclusive", "classifySubsector_refines_group",
  "classifySubsector_determines_valence", "end_to_end_coherence",
  # AffectiveDynamics (10)
  "canonicalDepthKernel_reaches_crown", "canonicalDepthKernel_reaches_lateral",
  "lateral_reachable", "lateral_reachable_from_surprise", "canonicalDepthKernel_colere_bifurcates",
  "canonicalDepthKernel_axial_instability_p2", "canonicalDepthKernel_outgoingWeight_pos",
  "classifyTaxonomicGroup_unique_maximizer", "classifyTaxonomicGroup_maximizes_membership",
  "lateral_has_overlapping_attractors",
  # Lexicon176 (8)
  "all176Entries_length", "all176Entries_geometrically_valid", "all176Entries_z_bounds",
  "all176Entries_unique_points", "all176Entries_complete",
  "all176Entries_deterministically_reachable", "all176Entries_reachable_by_engine",
  "all176Entries_witness_check",
  # PredictiveCircuit (41)
  "circuit_covers_interfaces_both_sides", "circuit_refines_inferential_ops", "phiL1_left_inv",
  "phiL1_right_inv", "phiL1_agrees_with_deployZ2", "crossingII_is_transpose_of_crossingI",
  "routeToSubjective_injective", "routeToPerceptive_injective", "projectPerceptible_valid",
  "projectPerceptible_z2_matches_phiL1", "projectPerceptible_neutral_elevates_to_central",
  "attentional_bottleneck_sum_active", "circuitRowSum_exact", "veille_absorbing_free",
  "lyapunov_monotone_free", "lyapunov_strict_descent_witness", "lyapunov_expected_drift_constant",
  "axial_peur_bifurcates_p2", "veille_reaches_all_one_step", "all_reach_veille_two_steps",
  "veille_unreachable_when_eps_max", "circularCycle_veille_fixed_point",
  "circularCycle_reduces_total_discrepancy", "lyapunov_drift_charge_with_passive_extinction",
  "p1_without_p2_eps_independent", "epistemic_rigidity_traps_charge_slice",
  "pragmatic_helplessness_traps_charge_slice", "perseveration_traps_discharge_free",
  "passive_extinction_zero_relief", "active_resolution_beats_passive_extinction",
  "charge_accumulator_bounded", "nextStratumR5_le_zMax", "nextStratumR5_short_circuits_z2_to_veille",
  "nextStratumR5_from_ge2_never_visits_surprise", "symmetricSigmoid_sum", "symmetricSigmoid_pos",
  "symmetricSigmoid_neg", "precisionShare_double_charge_cancels_alpha", "projectUnifiedState_valid",
  "projectUnifiedState_crown_budget", "projectUnifiedState_reaches_lateral_consternation",
  # AuditTests (1)
  "all176Entries_antagonist_inverts_hedonic_polarity",
  # Derived Module: OperantFactorization (7)
  "manhattanDistXY_origin", "operant_factorization_law",
  "energyRegime_matches_operant_operator", "antagonist_flips_effect_preserves_operator",
  "axial_poles_bridge_operant_pairs", "axial_poles_pre_operant",
  "operant_bijection_on_z2_diagonals"
)

if ($expected113.Count -ne 120) { throw "Internal count mismatch" }
$missing = @()
foreach ($thm in $expected113) {
  if (-not $declaredLemmas.Contains($thm)) {
    $missing += $thm
  }
}
if ($missing.Count -gt 0) {
  Write-Error "Missing Dafny lemmas: $($missing -join ', ')"
  exit 1
}
Write-Host "[AUDIT] Static check OK: 0 assume/axiom/verify-false/extern, 120/120 lemmas declared."

$totalSw = [System.Diagnostics.Stopwatch]::StartNew()
Push-Location $dafnyRoot
try {
  # 3. Timed per-module verification
  $modules = @(
    "PredictiveEngine", "CoreAffect", "AffectiveMatrix", "AffectiveTaxonomy",
    "AffectiveDynamics", "Lexicon176", "PredictiveCircuit", "AuditTests", "OperantFactorization", "Cartograffect"
  )
  Write-Host "`n=== Per-Module Dafny Verification ==="
  foreach ($mod in $modules) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $out = (& $DafnyBin verify --verification-time-limit 60 "dfyconfig.toml" "--filter-symbol=$mod" 2>&1 | Out-String)
    $code = $LASTEXITCODE
    $sw.Stop()
    if ($code -ne 0 -or $out -match "time out") {
      Write-Host $out
      Write-Error "Dafny failed on module $mod (exit $code)"
      exit 1
    }
    $summary = ($out -split "`r?`n" | Where-Object { $_ -match "Dafny program verifier finished" } | Select-Object -Last 1)
    Write-Host ("  [OK] {0,-20} {1,-45} ({2:F2} s)" -f $mod, $summary.Trim(), $sw.Elapsed.TotalSeconds)
  }

  # 4. Full project verification (0 errors, 0 timeouts)
  Write-Host "`n=== Full Project Verification ==="
  $swFull = [System.Diagnostics.Stopwatch]::StartNew()
  $fullOut = (& $DafnyBin verify --verification-time-limit 60 "dfyconfig.toml" 2>&1 | Out-String)
  $fullCode = $LASTEXITCODE
  $swFull.Stop()
  Write-Host $fullOut.Trim()
  if ($fullCode -ne 0 -or $fullOut -notmatch '(\d+) verified,\s+0 errors' -or $fullOut -match "time out") {
    Write-Error "Full Dafny verification failed (exit $fullCode)"
    exit 1
  }
  Write-Host ("  [FULL VERIFY OK] ({0:F2} s)" -f $swFull.Elapsed.TotalSeconds)

  # 5. Runtime parity execution (--target:py)
  Write-Host "`n=== Runtime Execution Parity (--target:py) ==="
  $swRun = [System.Diagnostics.Stopwatch]::StartNew()
  $runOut = (& $DafnyBin run --target:py --no-verify "src/AuditTests.dfy" 2>&1 | Out-String)
  $runCode = $LASTEXITCODE
  $swRun.Stop()
  if ($runCode -ne 0) {
    Write-Host $runOut
    Write-Error "Dafny runtime execution failed (exit $runCode)"
    exit 1
  }
  $runLines = $runOut -split "`r?`n" | Where-Object { $_ -match '^B\d+:' }
  $runLines | ForEach-Object { Write-Host "  $_" }

  $expectedPatterns = @(
    '^B1:.*\(0, 0, 0\).*Z0_pointDeVeille.*OperateurCentral',
    '^B2:.*\(0, 0, 1\).*Z1_saillancePerceptive.*AscendingRupture',
    '^B3:.*\(-1, 1, 2\).*\(1, -1, 2\).*GroupeColere.*DiagonalAnger.*GroupeCalme.*DiagonalCalm.*ErgotropicCompensation.*HedNegative',
    '^B4:.*\(0, 0, 0\)->.*\(0, 0, 1\)->.*\(0, 0, 2\)->.*\(0, 2, 2\)',
    '^B5:.*\(0, 0, 0\) jump=4 .*\(0, 0, 3\)->.*\(0, 0, 2\)->.*\(0, 0, 0\)',
    '^B6:.*\(-1, 3, 3\).*Lateral.*GroupeJoie.*LateralDefensiveUrgency.*HedNegative.*\(3, -1, 3\)',
    '^B7:2,1,1 out=4 ant=1',
    '^B8:C=\(4,2,1,.*GroupeJoie\) E=\(6,4,2,.*GroupeJoie\)',
    '^B9:.*\(-1, 1, 2\).*\(1, -1, 2\).*HedNegative->.*HedPositive',
    '^B10:\(0, 2\) \(2, 0\) .*\(-1, 3, 3\) sum=4000000000000 w=101500000000 op3=.*\(0, 0, 0\)',
    '^B11:acc=\(700,1300\) r5=\(0,2\) pt=.*\(-1, 3, 3\) sh=\(193, 807\)'
  )
  for ($k = 0; $k -lt 11; $k++) {
    $pat = $expectedPatterns[$k]
    if (-not ($runOut -split "`r?`n" | Where-Object { $_ -match $pat })) {
      Write-Error "Block $($k+1) parity mismatch against pattern: $pat"
      exit 1
    }
  }
  Write-Host ("  [RUNTIME PARITY OK] 11/11 blocks exact match ({0:F2} s)" -f $swRun.Elapsed.TotalSeconds)
}
finally {
  Get-ChildItem -Path $srcDir -Directory -Filter "*-py" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
  Pop-Location
}

$totalSw.Stop()
Write-Host ("`n[PASS] Dafny suite verified cleanly in {0:F2} s." -f $totalSw.Elapsed.TotalSeconds)
exit 0
