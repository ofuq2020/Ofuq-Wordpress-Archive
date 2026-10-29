[CmdletBinding()]
param([string]$PhpVersion='7.4.33',[string]$MariaDbVersion='10.11.19',[switch]$Force)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$phpDir=Join-Path $root 'staging\runtime\php'
$dbRoot=Join-Path $root 'staging\runtime\mariadb'
$binDir=Join-Path $dbRoot 'bin'
$cache=Join-Path $root 'downloads'
New-Item -ItemType Directory -Force -Path $phpDir,$dbRoot,$binDir,$cache | Out-Null
function Download-File([string]$Url,[string]$Path) {
  Write-Host "Downloading $Url"
  Invoke-WebRequest -Uri $Url -OutFile $Path -UseBasicParsing
  if (-not (Test-Path $Path) -or (Get-Item $Path).Length -lt 1MB) { throw "Download looks incomplete: $Path" }
}
function Expand-ZipSafely([string]$Zip,[string]$Destination) {
  $tmp=Join-Path $env:TEMP ("acelle-extract-"+[guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $tmp | Out-Null
  try {
    Expand-Archive -LiteralPath $Zip -DestinationPath $tmp -Force
    $entries=@(Get-ChildItem -LiteralPath $tmp -Force)
    if ($entries.Count -eq 1 -and $entries[0].PSIsContainer) {
      foreach ($item in Get-ChildItem -LiteralPath $entries[0].FullName -Force) { Move-Item -LiteralPath $item.FullName -Destination $Destination -Force }
    } else { foreach ($item in $entries) { Move-Item -LiteralPath $item.FullName -Destination $Destination -Force } }
  } finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}
$phpExe=Join-Path $phpDir 'php.exe'
if ($Force -or -not (Test-Path $phpExe)) {
  $phpZip=Join-Path $cache "php-$PhpVersion-nts-Win32-vc15-x64.zip"
  $phpUrl="https://downloads.php.net/~windows/releases/archives/php-$PhpVersion-nts-Win32-vc15-x64.zip"
  Download-File $phpUrl $phpZip
  $expected='14ae3250d4447c8ccfc4c45a70d90adfbcd61e728d85f0be56a7ddf8f9c8aace'
  $actual=(Get-FileHash -LiteralPath $phpZip -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actual -ne $expected) { throw "PHP SHA-256 mismatch: expected $expected got $actual" }
  Get-ChildItem -LiteralPath $phpDir -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
  Expand-ZipSafely $phpZip $phpDir
}
$dbExe=Join-Path $binDir 'mysqld.exe'
if ($Force -or -not (Test-Path $dbExe)) {
  $dbZip=Join-Path $cache "mariadb-$MariaDbVersion-winx64.zip"
  $dbUrl="https://archive.mariadb.org/mariadb-$MariaDbVersion/winx64-packages/mariadb-$MariaDbVersion-winx64.zip"
  Download-File $dbUrl $dbZip
  $sumFile=Join-Path $cache "mariadb-$MariaDbVersion-sha256sums.txt"
  Invoke-WebRequest -Uri "https://archive.mariadb.org/mariadb-$MariaDbVersion/winx64-packages/sha256sums.txt" -OutFile $sumFile -UseBasicParsing
  $sumLine=Get-Content $sumFile | Where-Object { $_ -match [regex]::Escape([IO.Path]::GetFileName($dbZip)) } | Select-Object -First 1
  if (-not $sumLine -or $sumLine -notmatch '^\s*([a-fA-F0-9]{64})\s+\*?(.+)$') { throw 'MariaDB official SHA-256 entry not found.' }
  $expected=$Matches[1].ToLowerInvariant()
  $actual=(Get-FileHash -LiteralPath $dbZip -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actual -ne $expected) { throw "MariaDB SHA-256 mismatch: expected $expected got $actual" }
  $tempDb=Join-Path $env:TEMP ("acelle-mariadb-"+[guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $tempDb | Out-Null
  try {
    Expand-Archive -LiteralPath $dbZip -DestinationPath $tempDb -Force
    $server=Get-ChildItem -LiteralPath $tempDb -Filter 'mysqld.exe' -Recurse -File | Select-Object -First 1
    if (-not $server) { throw 'MariaDB archive does not contain mysqld.exe.' }
    $packageRoot=Split-Path -Parent (Split-Path -Parent $server.FullName)
    Get-ChildItem -LiteralPath $dbRoot -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
    Get-ChildItem -LiteralPath $packageRoot -Force | Copy-Item -Destination $dbRoot -Recurse -Force
  } finally { Remove-Item -LiteralPath $tempDb -Recurse -Force -ErrorAction SilentlyContinue }
}
$serverExe=Get-ChildItem -LiteralPath $dbRoot -Filter 'mysqld.exe' -Recurse -File | Select-Object -First 1
if (-not $serverExe) { throw 'MariaDB server executable missing after extraction.' }
$actualBin=$serverExe.Directory.FullName
if ($actualBin -ne $binDir) {
  New-Item -ItemType Directory -Force -Path $binDir | Out-Null
  Get-ChildItem -LiteralPath $actualBin -Force | Copy-Item -Destination $binDir -Recurse -Force
}
$init=@('mariadb-install-db.exe','mysql_install_db.exe') | Where-Object { Test-Path (Join-Path $binDir $_) } | Select-Object -First 1
if (-not $init) { throw 'MariaDB database initialization tool is missing.' }
if (-not (Test-Path (Join-Path $binDir 'mysql.exe')) -and -not (Test-Path (Join-Path $binDir 'mariadb.exe'))) { throw 'MariaDB client is missing.' }
$extDir=Join-Path $phpDir 'ext'
if (-not (Test-Path (Join-Path $extDir 'php_pdo_mysql.dll'))) { throw 'PHP archive is missing ext/php_pdo_mysql.dll.' }
$phpIni=@"
[PHP]
engine=On
short_open_tag=Off
precision=14
output_buffering=4096
zlib.output_compression=Off
implicit_flush=Off
serialize_precision=-1
expose_php=Off
max_execution_time=120
max_input_time=120
memory_limit=512M
error_reporting=E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors=Off
log_errors=On
error_log=php-error.log
post_max_size=128M
upload_max_filesize=128M
max_file_uploads=50
default_charset="UTF-8"
date.timezone=Asia/Riyadh
extension_dir=ext
extension=curl
extension=fileinfo
extension=gd
extension=mbstring
extension=openssl
extension=pdo_mysql
extension=mysqli
extension=tokenizer
extension=xml
extension=zip
extension=intl
extension=bz2
extension=exif
extension=soap
extension=sockets
extension=sqlite3
extension=pdo_sqlite
[Session]
[openssl]
"@
Set-Content -LiteralPath (Join-Path $phpDir 'php.ini') -Value $phpIni -Encoding ASCII
$version=& $phpExe -c (Join-Path $phpDir 'php.ini') -v 2>&1
if ($LASTEXITCODE -ne 0) { throw "Bundled PHP cannot run: $version" }
$modules=& $phpExe -c (Join-Path $phpDir 'php.ini') -m 2>&1
if ($LASTEXITCODE -ne 0) { throw 'PHP module enumeration failed.' }
foreach ($required in @('curl','fileinfo','gd','mbstring','openssl','PDO','pdo_mysql','tokenizer','xml','zip')) {
  if ($modules -notcontains $required) { throw "Required PHP extension missing: $required" }
}
Write-Host "PHP validated: $($version | Select-Object -First 1)"
Write-Host "MariaDB validated: $serverExe"
Write-Host 'Runtime prepared; application compatibility and clean Windows installation tests remain required.' -ForegroundColor Yellow
