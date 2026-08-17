param(
  [string]$ProjectRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path (Join-Path $ProjectRoot "pubspec.yaml"))) {
  throw "Run this script from the moneytrackerpro project root."
}

Write-Host "MoneyTracker Pro - SQLite complete rollback" -ForegroundColor Cyan
Write-Host "Project: $ProjectRoot"

Push-Location $ProjectRoot
try {
  $paths = @(
    "lib\core\database\app_database.dart",
    "lib\core\database\app_database.g.dart",
    "lib\core\database\database_schema.dart",
    "lib\core\database\moneytracker_tables.dart",
    "lib\features\transactions\data\repositories\sqlite_transaction_repository.dart",
    "scripts\setup_database_dependencies.ps1",
    "scripts\generate_database.ps1",
    "scripts\setup_drift_web.ps1",
    "DATABASE_MIGRATION.md",
    "web\sqlite3.wasm",
    "web\drift_worker.dart.js"
  )

  foreach ($relative in $paths) {
    $target = Join-Path $ProjectRoot $relative
    if (Test-Path $target) {
      Remove-Item -Force $target
      Write-Host "[removed] $relative" -ForegroundColor DarkGray
    }
  }

  $databaseDir = Join-Path $ProjectRoot "lib\core\database"
  if ((Test-Path $databaseDir) -and
      ((Get-ChildItem -Force $databaseDir | Measure-Object).Count -eq 0)) {
    Remove-Item -Force $databaseDir
    Write-Host "[removed] lib\core\database" -ForegroundColor DarkGray
  }

  Write-Host "[dependencies] Removing Drift / SQLite packages..." -ForegroundColor Yellow
  flutter pub remove drift drift_flutter
  flutter pub remove drift_dev build_runner

  Write-Host "[dependencies] Resolving project..." -ForegroundColor Yellow
  flutter pub get

  Write-Host ""
  Write-Host "SQLite rollback complete." -ForegroundColor Green
  Write-Host "Transactions now use LocalTransactionRepository / SharedPreferences again."
  Write-Host ""
  Write-Host "Recommended next commands:"
  Write-Host "  dart format lib\app\home_shell.dart"
  Write-Host "  flutter analyze"
  Write-Host "  flutter run -d chrome --web-port=5000"
}
finally {
  Pop-Location
}
