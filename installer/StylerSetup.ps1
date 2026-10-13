# CS.Coder - Unit Styler: install / uninstall for every Delphi found on this PC.
# Run through Install.bat or Uninstall.bat. Works per Windows user, no administrator needed.
#
#   -Action install     copies the packages and registers them in each Delphi (11, 12, 13)
#   -Action uninstall   unregisters and removes them; add -RemoveData to delete the settings too
#
# The remaining parameters exist for automated tests.
param(
  [Parameter(Mandatory = $true)][ValidateSet('install', 'uninstall')][string]$Action,
  [switch]$RemoveData,
  [string]$RegistryRoot = 'Software\Embarcadero\BDS',
  [string]$InstallDir = '',
  [string]$SourceDir = '',
  [switch]$SkipProcessCheck
)

$ErrorActionPreference = 'Stop'
# Resolved here, not as parameter defaults: Windows PowerShell 5.1 does not
# always have $PSScriptRoot available while binding parameters.
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($InstallDir -eq '') { $InstallDir = Join-Path $env:LOCALAPPDATA 'CSCoder\UnitStyler\bin' }
if ($SourceDir -eq '') { $SourceDir = Join-Path $Here 'bin' }
$Description = 'CS.Coder - Unit Styler'
$Versions = @(
  @{ Key = '22.0'; Tag = 'D11'; Name = 'Delphi 11' },
  @{ Key = '23.0'; Tag = 'D12'; Name = 'Delphi 12' },
  @{ Key = '37.0'; Tag = 'D13'; Name = 'Delphi 13' }
)
# The file name this package is registered under, in any folder.
$OurPackage = '(?i)\\CSCoder\.UnitStyler\.D\d+\.bpl$'
$Portuguese = (Get-UICulture).TwoLetterISOLanguageName -eq 'pt'

function T([string]$En, [string]$Pt) { if ($Portuguese) { $Pt } else { $En } }
function Say([string]$Text) { Write-Host $Text }

function Open-Key([string]$SubPath, [bool]$Writable) {
  [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($SubPath, $Writable)
}

# Removes our entries from one key. Returns how many were removed.
function Remove-OurValues([string]$SubPath) {
  $key = Open-Key $SubPath $true
  if (-not $key) { return 0 }
  try {
    $names = @($key.GetValueNames() | Where-Object { $_ -match $OurPackage })
    foreach ($n in $names) { $key.DeleteValue($n, $false) }
    return $names.Count
  } finally { $key.Close() }
}

function Remove-OurSubKeys([string]$SubPath) {
  $key = Open-Key $SubPath $true
  if (-not $key) { return }
  try {
    foreach ($n in @($key.GetSubKeyNames() | Where-Object { ('\' + $_) -match $OurPackage })) {
      $key.DeleteSubKeyTree($n, $false)
    }
  } finally { $key.Close() }
}

function Unregister-Version($v) {
  $base = "$RegistryRoot\$($v.Key)"
  $n = 0
  foreach ($k in 'Known Packages', 'Known Packages x64', 'Disabled Packages', 'Disabled Packages x64') {
    $n += Remove-OurValues "$base\$k"
  }
  foreach ($k in 'Package Cache', 'Package Cache x64') { Remove-OurSubKeys "$base\$k" }
  return $n
}

function Register-Package($v, [string]$Platform, [string]$KeyName) {
  $file = "CSCoder.UnitStyler.$($v.Tag).bpl"
  $source = Join-Path $SourceDir "$($v.Tag)\$Platform\$file"
  if (-not (Test-Path -LiteralPath $source)) { return $false }
  # The list exists once that IDE has been opened by this user.
  $key = Open-Key "$RegistryRoot\$($v.Key)\$KeyName" $true
  if (-not $key) { return $false }
  try {
    $targetDir = Join-Path $InstallDir "$($v.Tag)\$Platform"
    New-Item -ItemType Directory -Force $targetDir | Out-Null
    $target = Join-Path $targetDir $file
    Copy-Item -LiteralPath $source -Destination $target -Force
    $key.SetValue($target, $Description, [Microsoft.Win32.RegistryValueKind]::String)
    return $true
  } finally { $key.Close() }
}

function Find-Versions {
  $found = @()
  foreach ($v in $Versions) {
    $key = Open-Key "$RegistryRoot\$($v.Key)" $false
    if (-not $key) { continue }
    try {
      # A leftover key without RootDir is a Delphi that is no longer installed.
      if ([string]$key.GetValue('RootDir', '') -ne '') { $found += $v }
    } finally { $key.Close() }
  }
  return $found
}

# ---------------------------------------------------------------------------

Say ''
Say "$Description - $(if ($Action -eq 'install') { T 'install' 'instalar' } else { T 'uninstall' 'desinstalar' })"
Say ''
if ($Action -eq 'install') {
  Say (T 'BETA VERSION: still being tested, it may have defects. Report problems at' `
         'VERSÃO BETA: ainda em teste, pode ter defeitos. Avise de problemas em')
  Say '  https://github.com/cscoder69/delphi-unit-styler/issues'
  Say ''
}

# Delphi rewrites its package list when it closes, which would undo our changes.
# Checked before anything is touched, so nothing is ever left half done.
if (-not $SkipProcessCheck -and (Get-Process -Name 'bds' -ErrorAction SilentlyContinue)) {
  Say (T 'Delphi is running. Close every Delphi window and run this again.' `
         'O Delphi está aberto. Feche todas as janelas do Delphi e execute de novo.')
  exit 2
}

$found = @(Find-Versions)

if ($Action -eq 'install') {
  if ($found.Count -eq 0) {
    Say (T 'No supported Delphi (11, 12 or 13) was found for this Windows user.' `
           'Nenhum Delphi compatível (11, 12 ou 13) foi encontrado para este usuário do Windows.')
    exit 3
  }
  if (-not (Test-Path -LiteralPath $SourceDir)) {
    Say (T 'The bin folder that comes with Install.bat is missing. Extract the whole zip and run it again.' `
           'Falta a pasta bin que acompanha o Install.bat. Extraia o zip inteiro e execute de novo.')
    exit 4
  }
  $done = 0
  foreach ($v in $found) {
    [void](Unregister-Version $v)   # also clears older copies registered from other folders
    $w32 = Register-Package $v 'Win32' 'Known Packages'
    $w64 = Register-Package $v 'Win64' 'Known Packages x64'
    if ($w32 -or $w64) {
      $done++
      $bits = @(); if ($w32) { $bits += '32-bit' }; if ($w64) { $bits += '64-bit' }
      Say ("  [OK] $($v.Name) (" + ($bits -join ', ') + ')')
    } else {
      Say ("  [--] $($v.Name): " + (T 'not installed here. Open this Delphi once, close it and run Install.bat again' `
                                      'não instalado aqui. Abra este Delphi uma vez, feche e execute Install.bat de novo'))
    }
  }
  Say ''
  if ($done -eq 0) {
    Say (T 'Nothing was installed.' 'Nada foi instalado.')
    exit 4
  }
  Say (T 'Done. Open Delphi: the commands are in the menu CS.Coder > Unit Styler.' `
         'Pronto. Abra o Delphi: os comandos estão no menu CS.Coder > Unit Styler.')
  Say ((T 'Installed in: ' 'Instalado em: ') + $InstallDir)
  exit 0
}

# uninstall
$removed = 0
foreach ($v in $Versions) { $removed += (Unregister-Version $v) }   # every version, installed or not
if (Test-Path -LiteralPath $InstallDir) { Remove-Item -LiteralPath $InstallDir -Recurse -Force }
Say ("  " + (T 'Package registrations removed: ' 'Registros de pacote removidos: ') + $removed)

$dataDir = Split-Path $InstallDir -Parent
if ($RemoveData) {
  Say ("  " + (T '/data: the rules of every Delphi version and the settings of every project are deleted too.' `
                 '/data: as regras de cada versão do Delphi e as configurações de cada projeto também são apagadas.'))
  # Only the files the tool itself writes, never a whole folder blindly:
  #   D<version>\settings.json            rules, one file per Delphi version
  #   projects\<name>.<id>.json           settings of each project
  # each with the .bak copy and the .tmp file a save may leave behind.
  $ours = '(?i)\.json(\.bak|\.[^\\]*\.tmp)?$'
  $folders = @()
  if (Test-Path -LiteralPath $dataDir) {
    $folders += @(Get-ChildItem -LiteralPath $dataDir -Directory | Where-Object { $_.Name -match '^D\d+$' } | ForEach-Object { $_.FullName })
    $folders += @($folders | ForEach-Object { Join-Path $_ 'projects' })
    $folders += (Join-Path $dataDir 'projects')
  }
  foreach ($folder in $folders) {
    if (-not (Test-Path -LiteralPath $folder)) { continue }
    $isRules = (Split-Path $folder -Leaf) -match '^D\d+$'
    Get-ChildItem -LiteralPath $folder -File | Where-Object {
      if ($isRules) { $_.Name -match '(?i)^settings\.json(\.bak|\.[^\\]*\.tmp)?$' } else { $_.Name -match $ours }
    } | Remove-Item -Force
  }
  foreach ($folder in (@($folders) + $dataDir | Sort-Object Length -Descending)) {
    if ((Test-Path -LiteralPath $folder) -and -not (Get-ChildItem -LiteralPath $folder -Force)) { Remove-Item -LiteralPath $folder -Force }
  }
  Say ("  " + (T 'Settings removed.' 'Configurações removidas.'))
} else {
  Say ("  " + (T 'Your settings were kept in: ' 'Suas configurações foram mantidas em: ') + $dataDir)
  Say ("  " + (T 'To delete them too, run: Uninstall.bat /data' 'Para apagar também, execute: Uninstall.bat /data'))
}
Say ''
Say (T 'Done.' 'Pronto.')
exit 0
