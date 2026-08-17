param(
  [string]$ProjectRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path (Join-Path $ProjectRoot "pubspec.yaml"))) {
  throw "Run this script from the moneytrackerpro project root."
}

Push-Location $ProjectRoot
try {
  Write-Host "MoneyTracker Pro - Increment 074 Release Cleanup" -ForegroundColor Cyan
  Write-Host "Project: $ProjectRoot"
  Write-Host ""

  # Protect the user's current working tree before automated source edits.
  $backupDir = Join-Path $ProjectRoot ".release_cleanup_backup"
  New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"

  if (Get-Command git -ErrorAction SilentlyContinue) {
    $diffPath = Join-Path $backupDir "before_increment_074_$stamp.diff"
    git diff | Out-File -FilePath $diffPath -Encoding utf8
    Write-Host "[backup] Current git diff: $diffPath" -ForegroundColor DarkGray
  }

  Write-Host "[1/5] Previewing Dart automated fixes..." -ForegroundColor Yellow
  $preview = (& dart fix --dry-run 2>&1 | Out-String)
  Write-Host $preview

  if ($LASTEXITCODE -ne 0) {
    throw "dart fix --dry-run failed. No source files were changed."
  }

  # The project should currently only have the curly-braces analyzer infos.
  # Refuse an unexpected broad migration instead of silently changing APIs.
  $knownSafeCodes = @(
    "curly_braces_in_flow_control_structures"
  )

  $diagnosticCodes = @()
  foreach ($line in ($preview -split "`r?`n")) {
    if ($line -match "\s([a-z][a-z0-9_]+)\s+.+\bfix(?:es)?\b") {
      $diagnosticCodes += $Matches[1]
    }
    elseif ($line -match "^\s+([a-z][a-z0-9_]+)\s+[•-]") {
      $diagnosticCodes += $Matches[1]
    }
  }
  $diagnosticCodes = $diagnosticCodes | Sort-Object -Unique

  $unexpected = @(
    $diagnosticCodes | Where-Object { $_ -notin $knownSafeCodes }
  )

  if ($unexpected.Count -gt 0) {
    Write-Host ""
    Write-Host "Stopped before applying fixes." -ForegroundColor Red
    Write-Host "Unexpected Dart fix diagnostics:" -ForegroundColor Red
    $unexpected | ForEach-Object { Write-Host " - $_" }
    Write-Host ""
    Write-Host "Send the dry-run output to ChatGPT before continuing."
    exit 2
  }

  Write-Host "[2/5] Applying analyzer fixes..." -ForegroundColor Yellow
  dart fix --apply
  if ($LASTEXITCODE -ne 0) {
    throw "dart fix --apply failed."
  }

  Write-Host "[3/5] Formatting Dart source..." -ForegroundColor Yellow
  dart format lib test
  if ($LASTEXITCODE -ne 0) {
    throw "dart format failed."
  }

  Write-Host "[4/5] Running flutter analyze..." -ForegroundColor Yellow
  flutter analyze
  if ($LASTEXITCODE -ne 0) {
    throw "flutter analyze still reports issues."
  }

  Write-Host "[5/5] Running tests..." -ForegroundColor Yellow
  flutter test
  if ($LASTEXITCODE -ne 0) {
    throw "flutter test failed."
  }

  Write-Host ""
  Write-Host "Increment 074 PASS" -ForegroundColor Green
  Write-Host "Analyzer and tests are clean."
  Write-Host ""
  Write-Host "Run the app with:"
  Write-Host "  flutter run -d chrome --web-port=5000"
}
finally {
  Pop-Location
}
