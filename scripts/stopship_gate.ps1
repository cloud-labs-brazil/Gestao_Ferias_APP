[CmdletBinding()]
param(
    [string]$RepoRoot = "",
    [string]$TestCommand = "",
    [switch]$SkipTests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
    $RepoRoot = (Resolve-Path (Join-Path $scriptDirectory "..")).Path
} else {
    $RepoRoot = (Resolve-Path $RepoRoot).Path
}

$gateResults = New-Object System.Collections.Generic.List[object]

function Add-GateResult {
    param(
        [string]$GateId,
        [string]$GateName,
        [ValidateSet("PASS", "FAIL")]
        [string]$Status,
        [string]$Evidence,
        [string]$Details
    )

    $entry = [pscustomobject]@{
        GateId   = $GateId
        GateName = $GateName
        Status   = $Status
        Evidence = $Evidence
        Details  = $Details
    }
    $gateResults.Add($entry) | Out-Null

    $color = if ($Status -eq "PASS") { "Green" } else { "Red" }
    Write-Host ("[{0}] {1} - {2}" -f $Status, $GateId, $GateName) -ForegroundColor $color
    if ($Details) {
        Write-Host ("      {0}" -f $Details)
    }
}

function Resolve-TestCommand {
    param(
        [string]$Root,
        [string]$UserCommand
    )

    if ($UserCommand) {
        return $UserCommand
    }

    $packageJsonPath = Join-Path $Root "package.json"
    if (Test-Path -LiteralPath $packageJsonPath) {
        try {
            $pkg = Get-Content -LiteralPath $packageJsonPath -Raw | ConvertFrom-Json
            if ($pkg.scripts -and $pkg.scripts.test) {
                return "npm test"
            }
        } catch {
            return ""
        }
    }

    return ""
}

function Test-EvidenceFile {
    param(
        [string]$GateId,
        [string]$GateName,
        [string]$RelativePath
    )

    $fullPath = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $fullPath)) {
        Add-GateResult -GateId $GateId -GateName $GateName -Status "FAIL" -Evidence $RelativePath -Details "Missing evidence file."
        return
    }

    $content = Get-Content -LiteralPath $fullPath -Raw
    if ([string]::IsNullOrWhiteSpace($content)) {
        Add-GateResult -GateId $GateId -GateName $GateName -Status "FAIL" -Evidence $RelativePath -Details "Evidence file is empty."
        return
    }

    $statusMatch = [regex]::Match($content, "(?im)^Gate-Status\s*:\s*(GREEN|AMBER|RED|N/A)\s*$")
    if (-not $statusMatch.Success) {
        Add-GateResult -GateId $GateId -GateName $GateName -Status "FAIL" -Evidence $RelativePath -Details "Missing required 'Gate-Status: GREEN|AMBER|RED|N/A' marker."
        return
    }

    $gateStatus = $statusMatch.Groups[1].Value.ToUpperInvariant()
    if ($gateStatus -eq "GREEN" -or $gateStatus -eq "N/A") {
        $statusLabel = if ($gateStatus -eq "N/A") { "N/A (not applicable)" } else { "GREEN" }
        Add-GateResult -GateId $GateId -GateName $GateName -Status "PASS" -Evidence $RelativePath -Details ("Evidence file present and marked {0}." -f $statusLabel)
        return
    }

    Add-GateResult -GateId $GateId -GateName $GateName -Status "FAIL" -Evidence $RelativePath -Details ("Evidence status is {0}; GREEN or N/A is required." -f $gateStatus)
}

Write-Host ("RepoRoot: {0}" -f $RepoRoot)
Write-Host "Running stop-ship gates..."

# Local Gate L1: JSON parse validation
$jsonFiles = Get-ChildItem -Path $RepoRoot -Recurse -File -Filter "*.json" | Where-Object {
    $_.FullName -notmatch "\\node_modules\\" -and
    $_.FullName -notmatch "\\.git\\" -and
    $_.Name -ne "package-lock.json"
}

if (-not $jsonFiles) {
    Add-GateResult -GateId "L1" -GateName "Local JSON parse validation" -Status "FAIL" -Evidence "N/A" -Details "No JSON files discovered."
} else {
    $invalidJsonFiles = New-Object System.Collections.Generic.List[string]
    $convertFromJsonHasDepth = (Get-Command ConvertFrom-Json).Parameters.ContainsKey("Depth")
    foreach ($file in $jsonFiles) {
        try {
            $raw = Get-Content -LiteralPath $file.FullName -Raw
            if ($convertFromJsonHasDepth) {
                $null = $raw | ConvertFrom-Json -Depth 100
            } else {
                $null = $raw | ConvertFrom-Json
            }
        } catch {
            $invalidJsonFiles.Add($file.FullName) | Out-Null
        }
    }

    if ($invalidJsonFiles.Count -eq 0) {
        Add-GateResult -GateId "L1" -GateName "Local JSON parse validation" -Status "PASS" -Evidence "Scanned files: $($jsonFiles.Count)" -Details "All JSON files parsed successfully."
    } else {
        $preview = ($invalidJsonFiles | Select-Object -First 5) -join "; "
        Add-GateResult -GateId "L1" -GateName "Local JSON parse validation" -Status "FAIL" -Evidence "Invalid files: $($invalidJsonFiles.Count)" -Details $preview
    }
}

# Local Gate L2: automated tests
if ($SkipTests) {
    Add-GateResult -GateId "L2" -GateName "Local automated tests" -Status "FAIL" -Evidence "Skipped by flag" -Details "Tests are mandatory for stop-ship gating."
} else {
    $resolvedTestCommand = Resolve-TestCommand -Root $RepoRoot -UserCommand $TestCommand
    if (-not $resolvedTestCommand) {
        Add-GateResult -GateId "L2" -GateName "Local automated tests" -Status "FAIL" -Evidence "No command" -Details "Provide -TestCommand (example: `"pwsh -File .\\tests\\run.ps1`")."
    } else {
        $logPath = Join-Path $RepoRoot ".planning\stopship\last_test_output.log"
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $logPath) | Out-Null

        # Ensure invariant tests run against the patched definition
        $patchedDef = Join-Path $RepoRoot "flows\VacationApproval_Definition.json"
        if (Test-Path -LiteralPath $patchedDef) {
            $env:FLOW_DEFINITION_PATH = $patchedDef
        }

        Push-Location $RepoRoot
        try {
            $global:LASTEXITCODE = 0
            $testOutput = Invoke-Expression $resolvedTestCommand 2>&1
            $commandOk = $?
            $exitCode = if ($LASTEXITCODE -is [int]) { $LASTEXITCODE } else { if ($commandOk) { 0 } else { 1 } }
            $testOutput | Out-File -LiteralPath $logPath -Encoding utf8
        } catch {
            $exitCode = 1
            $_ | Out-File -LiteralPath $logPath -Encoding utf8
        } finally {
            Pop-Location
        }

        if ($exitCode -eq 0) {
            Add-GateResult -GateId "L2" -GateName "Local automated tests" -Status "PASS" -Evidence ".planning/stopship/last_test_output.log" -Details ("Command succeeded: {0}" -f $resolvedTestCommand)
        } else {
            Add-GateResult -GateId "L2" -GateName "Local automated tests" -Status "FAIL" -Evidence ".planning/stopship/last_test_output.log" -Details ("Command failed (exit {0}): {1}" -f $exitCode, $resolvedTestCommand)
        }
    }
}

# Mandatory release evidence gates (G1-G7 from checklist)
$evidenceGateMap = @(
    @{ Id = "G1"; Name = "Critical issues reproduced/fixed/proven"; Path = ".planning/stopship/evidence/g1_critical_issues.md" },
    @{ Id = "G2"; Name = "All tests green in CI"; Path = ".planning/stopship/evidence/g2_ci_green.md" },
    @{ Id = "G3"; Name = "Zero high/critical security findings"; Path = ".planning/stopship/evidence/g3_security.md" },
    @{ Id = "G4"; Name = "Performance non-regression evidence"; Path = ".planning/stopship/evidence/g4_performance.md" },
    @{ Id = "G5"; Name = "Backward compatibility validation"; Path = ".planning/stopship/evidence/g5_backward_compat.md" },
    @{ Id = "G6"; Name = "Rollback plan documented and tested"; Path = ".planning/stopship/evidence/g6_rollback.md" },
    @{ Id = "G7"; Name = "RCA package completed"; Path = ".planning/stopship/evidence/g7_rca.md" }
)

foreach ($gate in $evidenceGateMap) {
    Test-EvidenceFile -GateId $gate.Id -GateName $gate.Name -RelativePath $gate.Path
}

Write-Host ""
Write-Host "Gate Summary:"
$gateResults | Format-Table GateId, Status, GateName, Evidence -AutoSize

$failedGates = @($gateResults | Where-Object { $_.Status -eq "FAIL" })
if ($failedGates.Count -gt 0) {
    $failedList = ($failedGates | Select-Object -ExpandProperty GateId) -join ", "
    Write-Host ""
    Write-Host ("RELEASE DECISION: NO-SHIP (blocking gates: {0})" -f $failedList) -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "RELEASE DECISION: SHIP (all gates PASS)" -ForegroundColor Green
exit 0
