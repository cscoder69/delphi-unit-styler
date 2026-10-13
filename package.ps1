# Builds the package for the five targets and assembles what gets distributed:
#
#   dist\CSCoderUnitStyler-<version>.zip   Install.bat / Uninstall.bat, the .bpl of every
#                                          Delphi version and IDE, the license and the readme
#
# The version comes from StylerVersion (src\ui\CSCoder.Styler.About.pas), the same
# constant build.ps1 puts in the version resource of each package.
#
#   .\package.ps1              build everything, then assemble the zip
#   .\package.ps1 -SkipBuild   reuse the packages already in build\Package\...\dist
param([switch]$SkipBuild)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$BuildName = 'dist'
$Targets = @(
  @{ Version = '11'; Platform = 'Win32' },
  @{ Version = '12'; Platform = 'Win32' }, @{ Version = '12'; Platform = 'Win64' },
  @{ Version = '13'; Platform = 'Win32' }, @{ Version = '13'; Platform = 'Win64' }
)

$about = Get-Content -LiteralPath (Join-Path $Root 'src\ui\CSCoder.Styler.About.pas') -Raw -Encoding UTF8
if ($about -notmatch "StylerVersion\s*=\s*'([^']+)'") { throw 'StylerVersion not found' }
$Version = $Matches[1]

$Dist = Join-Path $Root 'dist'
New-Item -ItemType Directory -Force $Dist | Out-Null
$Stage = Join-Path $Dist "CSCoderUnitStyler-$Version"
if (Test-Path -LiteralPath $Stage) { Remove-Item -LiteralPath $Stage -Recurse -Force }
New-Item -ItemType Directory -Force $Stage | Out-Null

foreach ($t in $Targets) {
  $file = "CSCoder.UnitStyler.D$($t.Version).bpl"
  if (-not $SkipBuild) {
    $log = & (Join-Path $Root 'build.ps1') -Target Package -Version $t.Version -Platform $t.Platform -BuildName $BuildName 2>&1 | Out-String
    # The same sources must build clean everywhere: a warning stops the package.
    if ($log -match '(?im)\b(warning|hint)\b') { throw "Delphi $($t.Version) $($t.Platform): the build has warnings`n$log" }
  }
  $source = Join-Path $Root "build\Package\D$($t.Version)\$($t.Platform)\$BuildName\$file"
  if (-not (Test-Path -LiteralPath $source)) { throw "Package not found: $source" }
  $built = (Get-Item -LiteralPath $source).VersionInfo.ProductVersion
  if ($built -ne $Version) { throw "$source is version $built, expected $Version" }
  $target = Join-Path $Stage "bin\D$($t.Version)\$($t.Platform)"
  New-Item -ItemType Directory -Force $target | Out-Null
  Copy-Item -LiteralPath $source -Destination (Join-Path $target $file)
}
Copy-Item (Join-Path $Root 'installer\*') $Stage
Copy-Item (Join-Path $Root 'LICENSE.txt'), (Join-Path $Root 'LICENCA.txt') $Stage
Copy-Item (Join-Path $Root 'installer-readme\README.txt'), (Join-Path $Root 'installer-readme\LEIAME.txt') $Stage

# One zip in dist\: the one of this version.
Get-ChildItem -LiteralPath $Dist -Filter 'CSCoderUnitStyler-*.zip' | Remove-Item -Force
Add-Type -AssemblyName System.IO.Compression.FileSystem
$Zip = "$Stage.zip"
[System.IO.Compression.ZipFile]::CreateFromDirectory($Stage, $Zip)
Remove-Item -LiteralPath $Stage -Recurse -Force

Write-Output "dist ready: $Zip ($((Get-Item -LiteralPath $Zip).Length) bytes)"
$archive = [System.IO.Compression.ZipFile]::OpenRead($Zip)
try { $archive.Entries | ForEach-Object { '  ' + $_.FullName + '  (' + $_.Length + ' bytes)' } } finally { $archive.Dispose() }
