[CmdletBinding()]
param(
  [string]$InnoSetupCompiler = "$env:ProgramFiles(x86)\Inno Setup 6\ISCC.exe",
  [switch]$ExtractPayload,
  [switch]$PrepareRuntime
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
  if ($PrepareRuntime) { & (Join-Path $root 'scripts\Prepare-WindowsRuntime.ps1') }
  $payloadZip = Join-Path $root 'payload\AcelleMail.zip'
  $partsDir = Join-Path $root 'payload\parts'
  $payloadRoot = Join-Path $root 'payload'
  $assembler = Join-Path $root 'scripts\Assemble-AcelleMailPayload.ps1'
  if (-not (Test-Path $payloadZip) -and (Test-Path $assembler)) {
    if ((Test-Path $partsDir) -and (Get-ChildItem -LiteralPath $partsDir -File -Filter 'AcelleMail.part*' -ErrorAction SilentlyContinue)) {
      & $assembler -PartsDirectory $partsDir
    } elseif (Get-ChildItem -LiteralPath $payloadRoot -File -Filter 'AcelleMail.part*' -ErrorAction SilentlyContinue) {
      & $assembler -PartsDirectory $payloadRoot
    }
  }
  $appDir = Join-Path $root 'staging\app'
  $php = Join-Path $root 'staging\runtime\php\php.exe'
  $db = Join-Path $root 'staging\runtime\mariadb\bin\mysqld.exe'
  $dbInit = Join-Path $root 'staging\runtime\mariadb\bin\mariadb-install-db.exe'
  if (-not (Test-Path $dbInit)) { $dbInit = Join-Path $root 'staging\runtime\mariadb\bin\mysql_install_db.exe' }
  $launcher = Join-Path $root 'src\AcelleMailLauncher.ps1'
  $iss = Join-Path $root 'AcelleMail-Setup.iss'
  if (-not (Test-Path $payloadZip)) { throw "Missing application payload: $payloadZip" }
  if ($ExtractPayload) {
    if ((Get-ChildItem $appDir -Force -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0) {
      throw 'staging\app is not empty; move existing files aside before extracting.'
    }
    New-Item -ItemType Directory -Force $appDir | Out-Null
    Expand-Archive -LiteralPath $payloadZip -DestinationPath $appDir
  }
  $missing = @()
  foreach ($p in @($php,$db,$dbInit,$launcher,$iss)) { if (-not (Test-Path $p)) { $missing += $p } }
  if (-not (Test-Path (Join-Path $appDir 'artisan'))) { $missing += 'staging\app\artisan (extract payload first)' }
  if ($missing.Count) {
    Write-Host 'BUILD BLOCKED: required files are missing:' -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host " - $_" }
    throw 'Installer build prerequisites are incomplete. See docs\BUILD_REQUIREMENTS_AR.md.'
  }
  if (-not (Test-Path $InnoSetupCompiler)) { throw "Inno Setup Compiler not found: $InnoSetupCompiler" }
  $phpVersion = & $php -v 2>&1 | Select-Object -First 1
  if ($LASTEXITCODE -ne 0) { throw "Bundled PHP failed: $phpVersion" }
  & $InnoSetupCompiler $iss
  if ($LASTEXITCODE -ne 0) { throw "Inno Setup compilation failed: $LASTEXITCODE" }
  $exe = Join-Path $root 'output\AcelleMail-Setup-x64.exe'
  if (-not (Test-Path $exe)) { throw 'Compiler returned success but EXE output was not found.' }
  Write-Host "Built installer: $exe" -ForegroundColor Green
} finally { Pop-Location }
