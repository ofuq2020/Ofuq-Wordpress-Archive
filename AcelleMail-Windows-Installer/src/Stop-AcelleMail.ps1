# Stop only processes whose executable/command line belongs to this installed copy.
$ErrorActionPreference = 'SilentlyContinue'
$root = Split-Path -Parent $PSScriptRoot
$php = Join-Path $root 'runtime\php\php.exe'
$db = Join-Path $root 'runtime\mariadb\bin\mysqld.exe'
$procs = Get-CimInstance Win32_Process
foreach ($p in $procs) {
  if ($p.ExecutablePath -and ($p.ExecutablePath -ieq $php) -and $p.CommandLine -match 'artisan\s+serve.*127\.0\.0\.1.*8080') {
    Stop-Process -Id $p.ProcessId -Force
  }
}
foreach ($p in $procs) {
  if ($p.ExecutablePath -and ($p.ExecutablePath -ieq $db)) {
    Stop-Process -Id $p.ProcessId -Force
  }
}
