# Acelle Mail Local launcher — requires packaged PHP 7.4 x64 NTS and MariaDB.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root 'app'
$php = Join-Path $root 'runtime\php\php.exe'
$ini = Join-Path $root 'runtime\php\php.ini'
$dbRoot = Join-Path $root 'runtime\mariadb'
$mysqld = Join-Path $dbRoot 'bin\mysqld.exe'
$mysql = Join-Path $dbRoot 'bin\mysql.exe'
$dbInit = Join-Path $dbRoot 'bin\mariadb-install-db.exe'
if (-not (Test-Path $dbInit)) { $dbInit = Join-Path $dbRoot 'bin\mysql_install_db.exe' }
$baseData = Join-Path $env:LOCALAPPDATA 'OFUQ\AcelleMail'
$data = Join-Path $baseData 'data'
$logs = Join-Path $baseData 'logs'
$dbConfig = Join-Path $baseData 'my.ini'
$envFile = Join-Path $app '.env'
# Ensure bundled PHP/MariaDB DLL dependencies can be resolved without modifying system PATH.
$env:PATH = "$(Split-Path -Parent $php);$(Join-Path (Split-Path -Parent $php) 'ext');$(Join-Path $dbRoot 'bin');$env:PATH"
New-Item -ItemType Directory -Force -Path $baseData,$data,$logs | Out-Null
$log = Join-Path $logs 'launcher.log'
function Log([string]$s) { Add-Content -LiteralPath $log -Value "$(Get-Date -Format s) $s" }
function Wait-Port([int]$port,[int]$seconds) {
  $until=(Get-Date).AddSeconds($seconds)
  do {
    $c=$null
    try { $c=[Net.Sockets.TcpClient]::new(); $ar=$c.BeginConnect('127.0.0.1',$port,$null,$null); if($ar.AsyncWaitHandle.WaitOne(500) -and $c.Connected){$c.Close();return $true} } catch {} finally { if($c){$c.Close()} }
    Start-Sleep -Milliseconds 500
  } while((Get-Date) -lt $until)
  return $false
}
try {
  foreach ($p in @((Join-Path $app 'artisan'),$php,$mysqld,$mysql,$ini,$dbInit)) { if (-not (Test-Path $p)) { throw "Required runtime file missing: $p" } }
  if (-not (Test-Path $dbConfig)) {
    $cfg = @"
[mysqld]
basedir=$($dbRoot -replace '\\','/')
datadir=$($data -replace '\\','/')
port=3306
bind-address=127.0.0.1
skip-name-resolve
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
max_allowed_packet=64M
[client]
port=3306
host=127.0.0.1
"@
    Set-Content -LiteralPath $dbConfig -Value $cfg -Encoding ASCII
  }
  # The Windows mariadb-install-db.exe has a different CLI from the Unix script:
  # it accepts --datadir/--password, but NOT --basedir.
  $systemTables = Join-Path $data 'mysql'
  if (-not (Test-Path $systemTables)) {
    $existing = @(Get-ChildItem -LiteralPath $data -Force -ErrorAction SilentlyContinue)
    if ($existing.Count -gt 0) {
      # Preserve an incomplete prior initialization rather than silently treating it as valid.
      $quarantine = "$data.incomplete-$(Get-Date -Format yyyyMMddHHmmss)"
      Move-Item -LiteralPath $data -Destination $quarantine
      New-Item -ItemType Directory -Force -Path $data | Out-Null
      Log "Moved incomplete MariaDB data directory to $quarantine."
    }
    Log 'Initializing first-run MariaDB data directory with Windows installer syntax.'
    $initOutput = & $dbInit "--datadir=$data" '--password=' 2>&1
    $initExitCode = $LASTEXITCODE
    foreach ($line in $initOutput) { Log ([string]$line) }
    if ($initExitCode -ne 0 -or -not (Test-Path $systemTables)) {
      throw "MariaDB initialization failed (exit $initExitCode). See launcher.log and MariaDB data-directory error log."
    }
    Log 'MariaDB system tables initialized successfully.'
  }
  $dbProc = Get-Process mysqld -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $mysqld } | Select-Object -First 1
  if (-not $dbProc) {
    Log 'Starting local MariaDB.'
    Start-Process -FilePath $mysqld -ArgumentList @("--defaults-file=$dbConfig",'--console') -WindowStyle Hidden -RedirectStandardOutput (Join-Path $logs 'mariadb.out.log') -RedirectStandardError (Join-Path $logs 'mariadb.err.log') | Out-Null
  }
  if (-not (Wait-Port 3306 45)) { throw 'Local database did not start on 127.0.0.1:3306. See MariaDB logs.' }
  if (-not (Test-Path $envFile)) { throw 'Application first-run database credential setup requires a verified Acelle installer flow; refusing to continue without a validated .env file.' }
  Log 'Starting Acelle Mail web server on 127.0.0.1:8080.'
  $server = Start-Process -FilePath $php -ArgumentList @('-c',$ini,'artisan','serve','--host=127.0.0.1','--port=8080') -WorkingDirectory $app -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $logs 'php-server.out.log') -RedirectStandardError (Join-Path $logs 'php-server.err.log')
  if (-not (Wait-Port 8080 30)) { throw 'Acelle Mail web server did not start. See PHP server logs.' }
  Start-Process 'http://127.0.0.1:8080/install'
  Log "Started web process $($server.Id)."
} catch {
  Log "ERROR: $($_.Exception.Message)"
  Write-Error "Acelle Mail failed to start. Review log: $log"
  exit 1
}