<#
.SYNOPSIS
    Script de validation formelle autonome et isolée (The Rocq Prover 9.1.0) pour CARTOGRAFFECT.
.DESCRIPTION
    Compile l'intégralité des 10 modules dans rocq/theories/ avec -w +default,
    vérifie l'absence totale de mots-clés interdits (Admitted, admit, Axiom, etc.),
    contrôle que les 120 théorèmes audités sont « Closed under the global context »,
    valide les évaluations concrètes Compute clés, et exécute le vérificateur
    indépendant du noyau (rocq check -o) sans aucune modification hors de rocq/.
#>

param(
    [string]$RocqBin = $(if ($env:ROCQ_BIN) { $env:ROCQ_BIN } elseif (Test-Path "$env:LOCALAPPDATA\Programs\Rocq\bin") { "$env:LOCALAPPDATA\Programs\Rocq\bin" } else { "C:\Rocq-Platform~9.1~2026.01\bin" })
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

function Remove-RocqCommentsAndStrings {
    param([string]$Text)
    $sb = New-Object System.Text.StringBuilder
    $depth = 0
    $inString = $false
    $i = 0
    $len = $Text.Length
    while ($i -lt $len) {
        $ch = $Text[$i]
        if ($inString) {
            if ($ch -eq '"') {
                if (($i + 1) -lt $len -and $Text[$i + 1] -eq '"') {
                    $i += 2
                    continue
                }
                $inString = $false
            }
            $i++
            continue
        }
        if ($depth -gt 0) {
            if ($ch -eq '(' -and ($i + 1) -lt $len -and $Text[$i + 1] -eq '*') {
                $depth++
                $i += 2
                continue
            }
            if ($ch -eq '*' -and ($i + 1) -lt $len -and $Text[$i + 1] -eq ')') {
                $depth--
                $i += 2
                continue
            }
            $i++
            continue
        }
        if ($ch -eq '(' -and ($i + 1) -lt $len -and $Text[$i + 1] -eq '*') {
            $depth = 1
            $i += 2
            continue
        }
        if ($ch -eq '"') {
            $inString = $true
            [void]$sb.Append(' ')
            $i++
            continue
        }
        [void]$sb.Append($ch)
        $i++
    }
    return $sb.ToString()
}

$RocqRoot = $PSScriptRoot
Push-Location $RocqRoot
try {
    if ((Test-Path $RocqBin) -and ($env:PATH -notlike "*$RocqBin*")) {
        $env:PATH = "$RocqBin;$env:PATH"
    }
    if (-not (Get-Command rocq -ErrorAction SilentlyContinue)) {
        throw "Outil 'rocq' introuvable dans le PATH ni dans '$RocqBin'."
    }

    Write-Host "=== 1. Environnement Rocq ===" -ForegroundColor Cyan
    $verRes = Invoke-Native -Exe "rocq" -Arguments @("--version")
    if ($verRes.ExitCode -ne 0) { throw "Échec de 'rocq --version'." }
    $verRes.Output | ForEach-Object { Write-Host "  $_" }

    Write-Host "`n=== 2. Nettoyage des artefacts rocq/theories ===" -ForegroundColor Cyan
    $cleanPatterns = @("*.vo", "*.vos", "*.vok", "*.glob", "*.aux", ".*.aux", ".lia.cache", ".nia.cache")
    foreach ($pat in $cleanPatterns) {
        Get-ChildItem -Path (Join-Path $RocqRoot "theories") -Filter $pat -File -ErrorAction SilentlyContinue |
            Remove-Item -Force
    }
    Write-Host "  Artéfacts compilés nettoyés dans rocq/theories/."

    $modules = @(
        "theories/PredictiveEngine.v",
        "theories/CoreAffect.v",
        "theories/AffectiveMatrix.v",
        "theories/AffectiveTaxonomy.v",
        "theories/AffectiveDynamics.v",
        "theories/Lexicon176.v",
        "theories/PredictiveCircuit.v",
        "theories/AuditTests.v",
        "theories/OperantFactorization.v",
        "theories/Cartograffect.v"
    )

    Write-Host "`n=== 3. Compilation stricte (-w +default, Stdlib uniquement) ===" -ForegroundColor Cyan
    $totalStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $auditOutput = @()
    foreach ($mod in $modules) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $res = Invoke-Native -Exe "rocq" -Arguments @("compile", "-q", "-w", "+default", "-Q", "theories", "CartograffectRocq", $mod)
        $sw.Stop()
        if ($res.ExitCode -ne 0) {
            $res.Output | ForEach-Object { Write-Host $_ -ForegroundColor Red }
            throw "Échec de compilation pour $mod (ExitCode=$($res.ExitCode))."
        }
        Write-Host ("  [OK] {0,-34} ({1:N2} s)" -f $mod, $sw.Elapsed.TotalSeconds)
        if ($mod -eq "theories/AuditTests.v" -or $mod -eq "theories/OperantFactorization.v") {
            $auditOutput += $res.Output
        }
    }

    Write-Host "`n=== 4. Contrôle statique d'intégrité (0 Admitted / 0 Axioms) ===" -ForegroundColor Cyan
    $forbiddenRegex = '\b(Admitted|admit|Axiom|Axioms|Parameter|Parameters|Conjecture|Variable|Variables|Hypothesis|Hypotheses|Unsafe|vm_cast_no_check|native_cast_no_check)\b|Declare\s+ML\s+Module'
    foreach ($mod in $modules) {
        $raw = Get-Content -Path (Join-Path $RocqRoot $mod) -Raw -Encoding UTF8
        $stripped = Remove-RocqCommentsAndStrings -Text $raw
        $m = [regex]::Match($stripped, $forbiddenRegex)
        if ($m.Success) {
            throw "Mot-clé interdit détecté dans $mod : '$($m.Value)'."
        }
    }
    Write-Host "  [OK] 0 mot-clé interdit sur les 10 fichiers .v."

    Write-Host "`n=== 5. Audit des 120 Print Assumptions et des évaluations Compute ===" -ForegroundColor Cyan
    $closedCount = ($auditOutput | Where-Object { $_ -eq "Closed under the global context" }).Count
    $axiomLines = $auditOutput | Where-Object { $_ -match "^Axioms:" }
    if ($axiomLines.Count -gt 0) {
        $axiomLines | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        throw "Des axiomes ont été détectés par Print Assumptions !"
    }
    if ($closedCount -ne 120) {
        throw "Nombre inattendu de 'Closed under the global context' : $closedCount (attendu : 120)."
    }
    Write-Host "  [OK] Exactement 120 / 120 théorèmes rapportés 'Closed under the global context'."

    $joinedAudit = ($auditOutput -join " ") -replace "\s+", " "
    $expectedComputeSnippets = @(
        "4000000000000%N",
        "(700%N, 1300%N)",
        "(0, 2)",
        "TG_groupeColere",
        "TG_groupeCalme",
        "GT_lateral"
    )
    foreach ($snip in $expectedComputeSnippets) {
        if ($joinedAudit -notlike "*$snip*") {
            throw "Sortie Compute attendue manquante dans AuditTests.v : '$snip'."
        }
    }
    if ($joinedAudit -notmatch "pt_x := -?1.*pt_y := 3.*pt_z := 3") {
        throw "Sortie Compute attendue manquante pour Consternation (-1, 3, 3)."
    }
    Write-Host "  [OK] Évaluations concrètes Compute conformes (Veille, Surprise, Colère/Calme, Consternation, noyau 4e12, R5)."

    Write-Host "`n=== 6. Vérification indépendante du noyau (rocq check -o) ===" -ForegroundColor Cyan
    $chkSw = [System.Diagnostics.Stopwatch]::StartNew()
    $chkRes = Invoke-Native -Exe "rocq" -Arguments @("check", "-silent", "-o", "-Q", "theories", "CartograffectRocq", "CartograffectRocq.Cartograffect")
    $chkSw.Stop()
    if ($chkRes.ExitCode -ne 0) {
        $chkRes.Output | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        throw "Échec de rocq check (ExitCode=$($chkRes.ExitCode))."
    }
    $chkText = $chkRes.Output -join "`n"
    if ($chkText -notmatch "\*\s+Axioms:\s+<none>") {
        Write-Host $chkText -ForegroundColor Red
        throw "rocq check n'a pas rapporté '* Axioms: <none>'."
    }
    Write-Host ("  [OK] rocq check -o : Axioms: <none> ({0:N2} s)" -f $chkSw.Elapsed.TotalSeconds)

    $totalStopwatch.Stop()
    Write-Host "`nVALIDATION ROCQ 9.1 COMPLÈTE RÉUSSIE (120/120 théorèmes constructifs, 0 axiome, durée totale : $([string]::Format('{0:N2} s', $totalStopwatch.Elapsed.TotalSeconds)))" -ForegroundColor Green
}
finally {
    Pop-Location
}
