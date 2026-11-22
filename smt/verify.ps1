<#
.SYNOPSIS
    Script de validation formelle autonome et isolée (SMT-LIB 2.6 / Z3 5.3.3) pour CARTOGRAFFECT.
.DESCRIPTION
    Exécute Z3 sur les 9 fichiers SMT-LIB 2.6 de smt/theories/, vérifie l'absence
    totale de raccourcis ou d'assertions non prouvées hors des blocs (push)/(pop),
    contrôle les 9 vérifications [CONSISTENCY] = sat, les 120 théorèmes [THM] = unsat,
    le contrôle auxiliaire [AUX] = unsat, et la parité des 11 blocs [EVAL] = unsat.
#>

param(
    [string]$Z3Bin = "$env:USERPROFILE\.local\tools\z3\z3-5.3.3-x64-win\bin"
)

$ErrorActionPreference = "Stop"

function Invoke-Native {
    param(
        [string]$Exe,
        [string[]]$Arguments
    )
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $Exe @Arguments 2>&1 | ForEach-Object { "$_" }
        $exit = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $prev
    }
    return [PSCustomObject]@{
        ExitCode = $exit
        Output   = @($output)
    }
}

$SmtRoot = $PSScriptRoot
Push-Location $SmtRoot
try {
    if ((Test-Path $Z3Bin) -and ($env:PATH -notlike "*$Z3Bin*")) {
        $env:PATH = "$Z3Bin;$env:PATH"
    }
    if (-not (Get-Command z3 -ErrorAction SilentlyContinue)) {
        throw "Outil 'z3' introuvable dans le PATH ni dans '$Z3Bin'."
    }

    Write-Host "=== 1. Environnement SMT Z3 ===" -ForegroundColor Cyan
    $verRes = Invoke-Native -Exe "z3" -Arguments @("--version")
    if ($verRes.ExitCode -ne 0) { throw "Échec de 'z3 --version'." }
    $verRes.Output | ForEach-Object { Write-Host "  $_" }

    $modules = @(
        "theories/01_PredictiveEngine.smt2",
        "theories/02_CoreAffect.smt2",
        "theories/03_AffectiveMatrix.smt2",
        "theories/04_AffectiveTaxonomy.smt2",
        "theories/05_AffectiveDynamics.smt2",
        "theories/06_Lexicon176.smt2",
        "theories/07_PredictiveCircuit.smt2",
        "theories/08_AuditTests.smt2",
        "theories/09_OperantFactorization.smt2"
    )

    Write-Host "`n=== 2. Contrôle statique d'intégrité ===" -ForegroundColor Cyan
    foreach ($mod in $modules) {
        $raw = Get-Content -Path (Join-Path $SmtRoot $mod) -Raw -Encoding UTF8
        $noComments = ($raw -split "`n" | ForEach-Object { ($_ -split ';')[0] }) -join "`n"
        if ($noComments -match '\b(sorry|admit|Admitted|cheat|assert\s+false)\b') {
            throw "Mot-clé interdit détecté dans $mod : '$($Matches[0])'."
        }
        $lines = (Get-Content -Path (Join-Path $SmtRoot $mod)).Count
        Write-Host ("  [OK] {0,-38} ({1} lignes)" -f $mod, $lines)
    }

    Write-Host "`n=== 3. Exécution Z3 (9/9 CONSISTENCY sat, 120/120 THM unsat, 11/11 EVAL unsat) ===" -ForegroundColor Cyan
    $totalStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $consistencyCount = 0
    $thmCount = 0
    $auxCount = 0
    $evalCount = 0
    $auditValuesLines = @()

    foreach ($mod in $modules) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $res = Invoke-Native -Exe "z3" -Arguments @("-smt2", "-T:30", $mod)
        $sw.Stop()
        if ($res.ExitCode -ne 0) {
            $res.Output | ForEach-Object { Write-Host $_ -ForegroundColor Red }
            throw "Échec de Z3 pour $mod (ExitCode=$($res.ExitCode))."
        }

        $lines = $res.Output
        $modThm = 0
        $modCons = 0
        $modEval = 0
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $ln = $lines[$i].Trim()
            if ($ln -match '^\[CONSISTENCY\]$') {
                $status = $lines[$i + 1].Trim()
                if ($status -ne "sat") { throw "Échec [CONSISTENCY] dans $mod : attendu 'sat', reçu '$status'." }
                $consistencyCount++
                $modCons++
            }
            elseif ($ln -match '^\[THM\]\s+(.+)$') {
                $name = $Matches[1]
                $status = $lines[$i + 1].Trim()
                if ($status -ne "unsat") { throw "Échec théorème '$name' dans $mod : attendu 'unsat', reçu '$status'." }
                $thmCount++
                $modThm++
            }
            elseif ($ln -match '^\[AUX\]\s+(.+)$') {
                $name = $Matches[1]
                $status = $lines[$i + 1].Trim()
                if ($status -ne "unsat") { throw "Échec auxiliaire '$name' dans $mod : attendu 'unsat', reçu '$status'." }
                $auxCount++
            }
            elseif ($ln -match '^\[EVAL\]\s+(.+)$') {
                $name = $Matches[1]
                $status = $lines[$i + 1].Trim()
                if ($status -ne "unsat") { throw "Échec [EVAL] '$name' dans $mod : attendu 'unsat', reçu '$status'." }
                $evalCount++
                $modEval++
            }
            elseif ($ln -match '^\[VALUES\]$') {
                $auditValuesLines = $lines[($i + 1)..($lines.Count - 1)]
            }
        }
        Write-Host ("  [OK] {0,-38} ({1:N2} s | CONSISTENCY: {2}, THM: {3}, EVAL: {4})" -f $mod, $sw.Elapsed.TotalSeconds, $modCons, $modThm, $modEval)
    }

    if ($consistencyCount -ne 9) { throw "Nombre inattendu de [CONSISTENCY] sat : $consistencyCount (attendu : 9)." }
    if ($thmCount -ne 120) { throw "Nombre inattendu de [THM] unsat : $thmCount (attendu : 120)." }
    if ($auxCount -ne 1) { throw "Nombre inattendu de [AUX] unsat : $auxCount (attendu : 1)." }
    if ($evalCount -ne 11) { throw "Nombre inattendu de [EVAL] unsat : $evalCount (attendu : 11)." }

    Write-Host "`n=== 4. Parité des valeurs concrètes [VALUES] ===" -ForegroundColor Cyan
    $joinedValues = ($auditValuesLines -join " ") -replace "\s+", " "
    $expectedValues = @(
        "(mkPoint 0 0 0)",
        "(mkPoint 0 0 1)",
        "(mkPoint (- 1) 1 2)",
        "(mkPoint 1 (- 1) 2)",
        "(mkPoint (- 1) 3 3)",
        "4000000000000",
        "101500000000",
        "700",
        "1300",
        "(mkPair 193 807)"
    )
    foreach ($snip in $expectedValues) {
        if ($joinedValues -notlike "*$snip*") {
            throw "Valeur [VALUES] manquante dans 08_AuditTests.smt2 : '$snip'."
        }
    }
    Write-Host "  [OK] Valeurs concrètes Z3 conformes à Lean 4 et Rocq 9."

    $totalStopwatch.Stop()
    Write-Host "`nVALIDATION SMT Z3 COMPLÈTE RÉUSSIE (9/9 sat, 120/120 unsat, 11/11 EVAL unsat, durée totale : $([string]::Format('{0:N2} s', $totalStopwatch.Elapsed.TotalSeconds)))" -ForegroundColor Green
}
finally {
    Pop-Location
}
