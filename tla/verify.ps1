<#
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Autonomous TLA+ / TLC verification script for Cartograffect (120 theorems + 11 evals + 6 temporal/factorization models).
#>
[CmdletBinding()]
param(
  [string]$JavaBin = "",
  [string]$TlaJar = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$tlaRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$specsDir = Join-Path $tlaRoot "specs"

# 1. Tool discovery (external toolchain)
if (-not $JavaBin) {
  $candidates = @(
    "$env:USERPROFILE\.local\tools\jre21\jdk-21.0.13+9-jre\bin\java.exe"
  )
  foreach ($c in $candidates) {
    if (Test-Path $c) { $JavaBin = $c; break }
  }
  if (-not $JavaBin) {
    $cmd = Get-Command java -ErrorAction SilentlyContinue
    if ($cmd) { $JavaBin = $cmd.Source }
  }
}
if (-not $JavaBin -or -not (Test-Path $JavaBin)) {
  Write-Error "Java runtime not found. Pass -JavaBin or install Temurin JRE 21."
  exit 1
}

if (-not $TlaJar) {
  $jarCandidates = @(
    "$env:USERPROFILE\.local\tools\tla\tla2tools.jar"
  )
  foreach ($c in $jarCandidates) {
    if (Test-Path $c) { $TlaJar = $c; break }
  }
}
if (-not $TlaJar -or -not (Test-Path $TlaJar)) {
  Write-Error "tla2tools.jar not found. Pass -TlaJar or install TLA+ Tools v1.7.4+."
  exit 1
}

Write-Host "[TLA+] Java: $JavaBin"
Write-Host "[TLA+] JAR : $TlaJar"

# 2. Static integrity check: zero AXIOM, all 120 Thm_* and 11 EvalBlock* present
function Strip-TlaCommentsAndStrings([string]$text) {
  $noBlock = [regex]::Replace($text, '(?s)\(\*.*?\*\)', ' ')
  $noLine = [regex]::Replace($noBlock, '\\\*.*', ' ')
  $noStr = [regex]::Replace($noLine, '"(?:\\.|[^"\\])*"', '""')
  return $noStr
}

$tlaFiles = Get-ChildItem -Path $specsDir -Filter "*.tla" | Sort-Object Name
$allSpecText = ""
foreach ($f in $tlaFiles) {
  $raw = Get-Content -Path $f.FullName -Raw -Encoding UTF8
  $cleaned = Strip-TlaCommentsAndStrings $raw
  if ($cleaned -match '\bAXIOM\b') {
    Write-Error "Forbidden AXIOM found in $($f.Name)"
    exit 1
  }
  $allSpecText += "`n" + $raw
}

$expected113 = @(
  # PredictiveEngine (7)
  "polarity_invert_involutive", "coupling_regime_partition", "feedbackUpdate_couples_gradients",
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
  "hedonicPolarity_invert_involutive", "x_positive_determines_positive_valence",
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
  if ($allSpecText -notmatch ("Thm_" + [regex]::Escape($thm) + "\b")) {
    $missing += $thm
  }
}
if ($missing.Count -gt 0) {
  Write-Error "Missing Thm_* predicates: $($missing -join ', ')"
  exit 1
}
for ($b = 1; $b -le 11; $b++) {
  $bn = "EvalBlock{0:D2}" -f $b
  if ($allSpecText -notmatch ("\b" + $bn + "\b")) {
    Write-Error "Missing $bn"
    exit 1
  }
}
Write-Host "[AUDIT] Static check OK: 0 AXIOMs, 120/120 Thm_* predicates, 11/11 EvalBlocks."

# 3. SANY syntax & semantic parsing across all .tla specs
$totalSw = [System.Diagnostics.Stopwatch]::StartNew()
Push-Location $specsDir
try {
  $orderedSpecs = @(
    "PredictiveEngine.tla", "CoreAffect.tla", "AffectiveMatrix.tla",
    "AffectiveTaxonomy.tla", "AffectiveDynamics.tla", "Lexicon176.tla",
    "PredictiveCircuit.tla", "AuditTests.tla", "OperantFactorization.tla", "Cartograffect.tla",
    "Model_Dissipation.tla", "Model_Engine.tla", "Model_DepthKernel.tla",
    "Model_Circuit.tla", "Model_Unified.tla", "Model_OperantFactorization.tla"
  )
  Write-Host "`n=== SANY Parsing Check ($($orderedSpecs.Count) modules) ==="
  foreach ($sp in $orderedSpecs) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $out = & $JavaBin -cp $TlaJar tla2sany.SANY $sp 2>&1
    $code = $LASTEXITCODE
    $sw.Stop()
    if ($code -ne 0) {
      $out | ForEach-Object { Write-Host $_ }
      Write-Error "SANY failed on $sp (exit $code)"
      exit 1
    }
    Write-Host ("  [SANY OK] {0,-26} ({1:F2} s)" -f $sp, $sw.Elapsed.TotalSeconds)
  }

  # 4. TLC Model Checking (AuditTests + 5 temporal models)
  $tlcRuns = @(
    @{ Spec = "AuditTests.tla";        Cfg = "AuditTests.cfg" },
    @{ Spec = "Model_Dissipation.tla"; Cfg = "Model_Dissipation.cfg" },
    @{ Spec = "Model_Engine.tla";      Cfg = "Model_Engine.cfg" },
    @{ Spec = "Model_DepthKernel.tla"; Cfg = "Model_DepthKernel.cfg" },
    @{ Spec = "Model_Circuit.tla";            Cfg = "Model_Circuit.cfg" },
    @{ Spec = "Model_Unified.tla";            Cfg = "Model_Unified.cfg" },
    @{ Spec = "Model_OperantFactorization.tla"; Cfg = "Model_OperantFactorization.cfg" }
  )
  Write-Host "`n=== TLC Model Checking ($($tlcRuns.Count) models) ==="
  foreach ($run in $tlcRuns) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $out = & $JavaBin "-XX:+UseParallelGC" -cp $TlaJar tlc2.TLC -workers auto -cleanup -config $run.Cfg $run.Spec 2>&1
    $code = $LASTEXITCODE
    $sw.Stop()
    $textOut = ($out | Out-String)
    if ($code -ne 0 -or $textOut -match "Error:") {
      Write-Host $textOut
      Write-Error "TLC failed on $($run.Spec) (exit $code)"
      exit 1
    }
    $states = "?"
    $distinct = "?"
    if ($textOut -match '(\d+) states generated,\s+(\d+) distinct states found') {
      $states = $Matches[1]
      $distinct = $Matches[2]
    }
    Write-Host ("  [TLC OK] {0,-24} states={1,-8} distinct={2,-8} ({3:F2} s)" -f $run.Spec, $states, $distinct, $sw.Elapsed.TotalSeconds)
  }
}
finally {
  # Cleanup any leftover states directory
  Get-ChildItem -Path $specsDir -Directory -Filter "states*" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
  Pop-Location
}

$totalSw.Stop()
Write-Host ("`n[PASS] TLA+ / TLC suite verified cleanly in {0:F2} s." -f $totalSw.Elapsed.TotalSeconds)
exit 0
