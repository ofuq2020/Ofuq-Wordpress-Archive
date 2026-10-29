# Reassembles the Acelle Mail ZIP from uploaded GitHub-safe chunks.
[CmdletBinding()]
param(
  [string]$PartsDirectory = (Join-Path (Split-Path -Parent $PSScriptRoot) 'payload\parts'),
  [string]$OutputZip = (Join-Path (Split-Path -Parent $PSScriptRoot) 'payload\AcelleMail.zip')
)
$ErrorActionPreference = 'Stop'
$parts = @(Get-ChildItem -LiteralPath $PartsDirectory -File -Filter 'AcelleMail.part*' | Sort-Object Name)
if ($parts.Count -eq 0) {
  throw "No AcelleMail.part* chunks found in: $PartsDirectory"
}
# Require consecutive, two-digit part names to prevent silently skipping a chunk.
$expected = 1
foreach ($part in $parts) {
  $expectedName = 'AcelleMail.part{0:D2}' -f $expected
  if ($part.Name -ne $expectedName) {
    throw "Missing or misnamed chunk. Expected '$expectedName' but found '$($part.Name)'."
  }
  $expected++
}
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputZip) | Out-Null
$tempZip = "$OutputZip.partial"
if (Test-Path -LiteralPath $tempZip) { Remove-Item -LiteralPath $tempZip -Force }
$outStream = [System.IO.File]::Create($tempZip)
try {
  foreach ($part in $parts) {
    $inStream = [System.IO.File]::OpenRead($part.FullName)
    try { $inStream.CopyTo($outStream) } finally { $inStream.Dispose() }
    Write-Host "Added $($part.Name) ($($part.Length) bytes)"
  }
} finally { $outStream.Dispose() }
try {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [System.IO.Compression.ZipFile]::OpenRead($tempZip)
  try {
    if ($zip.Entries.Count -eq 0) { throw 'Reassembled ZIP contains no entries.' }
    $hasArtisan = $false
    foreach ($entry in $zip.Entries) {
      if ($entry.Name -eq 'artisan') { $hasArtisan = $true; break }
    }
    if (-not $hasArtisan) {
      Write-Warning "ZIP archive opens, but no entry named 'artisan' was found at any archive path. Confirm the payload archive is the expected Acelle Mail package."
    }
    Write-Host "ZIP validation passed: $($zip.Entries.Count) entries."
  } finally { $zip.Dispose() }
  Move-Item -LiteralPath $tempZip -Destination $OutputZip -Force
} catch {
  if (Test-Path -LiteralPath $tempZip) { Remove-Item -LiteralPath $tempZip -Force }
  throw "Reassembled payload failed ZIP validation: $($_.Exception.Message)"
}
Write-Host "Reassembled payload: $OutputZip"
