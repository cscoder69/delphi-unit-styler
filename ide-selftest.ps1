# Runs the integration self-test inside a real Delphi IDE, without user input.
# The IDE starts with its own registry profile (bds -r), so the normal IDE
# configuration and its installed packages are not read or changed. Everything
# else is written below build\ide-auto.
param(
    [ValidateSet('11','12','13')][string]$Version = '11',
    [ValidateSet('save','nosave','real','shots')][string]$Mode = 'save',
    # Mode shots: IDE theme used for the pictures of the windows.
    [ValidateSet('Dark','Light')][string]$Theme = 'Dark',
    # Mode shots: language of the windows pictured. Other than pt, only the windows and dialogs are pictured.
    [ValidateSet('pt','en','es','de','fr')][string]$Language = 'pt',
    # Mode real: folder below projetos-reais to copy, and its project file inside it.
    [string]$SourceFolder,
    [string]$ProjectFile,
    # Use the 64-bit IDE (Delphi 12 and 13): bin64\bds.exe and a Win64 package.
    [switch]$Ide64,
    [string]$IdeProfile = 'UnitStylerTest',
    [int]$TimeoutSeconds = 300,
    # Mode real: run in a fresh copy of the user's own IDE profile, so the project
    # finds its third-party components, and build it before and after the batch.
    # The user's profile is only read; the copy is the one that gets changed.
    [switch]$RealEnvironment,
    # Mode real: 'az' sorts everything from A to Z by the whole name; 'first' only
    # by the name before the first dot; 'groups' keeps the usual
    # order Winapi, System, Data, Vcl/FMX, others, sorted inside each group.
    [ValidateSet('az','first','groups','protected')][string]$Rules = 'az'
)
$ErrorActionPreference = 'Stop'
if ($RealEnvironment) {
    if ($Mode -ne 'real') { throw '-RealEnvironment needs -Mode real' }
    $IdeProfile = 'UnitStylerReal'
    if ($TimeoutSeconds -lt 1500) { $TimeoutSeconds = 1500 }
}
$installations = @{
    '11' = @{ Path = 'C:\Programas\Embarcadero\Delphi_11_3'; Bds = '22.0' }
    '12' = @{ Path = 'C:\Programas\Embarcadero\Delphi_12_3'; Bds = '23.0' }
    '13' = @{ Path = 'C:\Programas\Embarcadero\Delphi_13_1_v37'; Bds = '37.0' }
}
$installation = $installations[$Version].Path
if ($Ide64 -and $Version -eq '11') { throw 'Delphi 11 has no 64-bit IDE.' }
$bits = if ($Ide64) { 'x64' } else { 'x86' }
$bds = Join-Path $installation ($(if ($Ide64) { 'bin64' } else { 'bin' }) + '\bds.exe')
$knownPackages = if ($Ide64) { 'Known Packages x64' } else { 'Known Packages' }
$knownIde = if ($Ide64) { 'Known IDE Packages x64' } else { 'Known IDE Packages' }
$profileKey = "HKCU:\Software\Embarcadero\$IdeProfile\$($installations[$Version].Bds)"
$root = Join-Path $PSScriptRoot "build\ide-auto\D$Version"
$packageDirectory = Join-Path $root "pkg-$bits"
$session = Join-Path $root ("$Mode-$bits-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$project = Join-Path $session 'proj'
$originals = Join-Path $session 'orig'
$report = Join-Path $session 'report.txt'
New-Item -ItemType Directory -Force -Path $packageDirectory, $project | Out-Null

# 1. Test package: product units plus the self-test driver.
$sources = @('src\core','src\i18n','src\ui','src\config','src\ide','tests\ide') | ForEach-Object { Join-Path $PSScriptRoot $_ }
$searchPath = ($sources + (Join-Path $installation $(if ($Ide64) { 'lib\win64\release' } else { 'lib\win32\release' }))) -join ';'
# Icon and license texts of the About window; the paths in the .rc are relative to its folder.
Push-Location (Join-Path $PSScriptRoot 'src\ui')
try {
    & (Join-Path $installation 'bin\brcc32.exe') "-fo$(Join-Path $packageDirectory 'CSCoder.Styler.About.res')" 'CSCoder.Styler.About.rc' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'About resource compilation failed' }
} finally { Pop-Location }
Push-Location (Join-Path $PSScriptRoot 'tests\ide\packages')
try {
    & (Join-Path $installation $(if ($Ide64) { 'bin\dcc64.exe' } else { 'bin\dcc32.exe' })) '-B' '-Q' '-W' "-U$searchPath" "-R$packageDirectory" "-E$packageDirectory" "-N0$packageDirectory" "-LE$packageDirectory" "-LN$packageDirectory" 'CSCoder.UnitStyler.Test.dpk'
    if ($LASTEXITCODE -ne 0) { throw 'Test package build failed' }
} finally { Pop-Location }
$bpl = Join-Path $packageDirectory 'CSCoder.UnitStyler.Test.bpl'

$projectPath = Join-Path $project 'AutoTeste.dpr'
if ($Mode -eq 'real') {
    # A copy is opened; the folder given is only read, as the reference for every comparison.
    $originals = (Resolve-Path -LiteralPath $SourceFolder).Path
    Copy-Item -Path (Join-Path $originals '*') -Destination $project -Recurse -Force
    Get-ChildItem -LiteralPath $project -Recurse -File | Where-Object IsReadOnly | ForEach-Object { $_.IsReadOnly = $false }
    $projectPath = Join-Path $project $ProjectFile
    if (-not (Test-Path -LiteralPath $projectPath)) { throw "Project file not found in the copy: $ProjectFile" }
    if ($RealEnvironment) {
        # The copy must never build over the user's real binaries, nor run his build events.
        $dproj = [System.IO.Path]::ChangeExtension($projectPath, '.dproj')
        if (Test-Path -LiteralPath $dproj) {
            $xml = [System.IO.File]::ReadAllText($dproj)
            foreach ($tag in 'DCC_ExeOutput','DCC_BplOutput','DCC_DcpOutput','DCC_HppOutput','DCC_ObjOutput','BRCC_OutputDir') {
                $xml = [regex]::Replace($xml, "<$tag>[^<]*</$tag>", "<$tag>.\_selftest_out</$tag>")
            }
            foreach ($tag in 'PreBuildEvent','PostBuildEvent','PreLinkEvent') {
                $xml = [regex]::Replace($xml, "<$tag>[^<]*</$tag>", "<$tag></$tag>")
            }
            [System.IO.File]::WriteAllText($dproj, $xml, (New-Object System.Text.UTF8Encoding($true)))
        }
    }
} else {
# 2. Fixture project with known bytes. Non-ASCII text is built from code points
#    so this script stays plain ASCII.
$acao = 'a' + [char]0xE7 + [char]0xE3 + 'o'
$emoji = [char]::ConvertFromUtf32(0x1F600)
$ansi = [Text.Encoding]::GetEncoding(1252)
$utf8Bom = New-Object Text.UTF8Encoding($true)
$utf8 = New-Object Text.UTF8Encoding($false)
function Save([string]$relative, [string]$text, $encoding, [string]$newline = "`r`n") {
    $path = Join-Path $project $relative
    New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
    $text = ($text -replace "`r?`n", $newline)
    [IO.File]::WriteAllBytes($path, [byte[]]($encoding.GetPreamble() + $encoding.GetBytes($text)))
}
function UnitText([string]$name, [string]$interfaceUses, [string]$afterUses, [string]$implementation) {
@"
unit $name;

interface

$interfaceUses

$afterUses

function ${name}_Value: Integer;

implementation

$implementation

function ${name}_Value: Integer;
begin
  Result := 1;
end;

end.
"@
}
$plain = "uses`n  System.SysUtils, System.Classes;"
$impl = 'uses System.Types, System.Math;'
Save 'U_Open1.pas' (UnitText 'U_Open1' $plain "// $acao $emoji CursorAqui" $impl) $utf8Bom
Save 'U_Open2.pas' (UnitText 'U_Open2' $plain "// $acao" $impl) $ansi
Save 'U_ClosedAnsi.pas' (UnitText 'U_ClosedAnsi' "uses`n  System.SysUtils, // $acao da SysUtils`n  System.Classes;" "// $acao fechada" $impl) $ansi
Save 'U_ClosedUtf8Bom.pas' (UnitText 'U_ClosedUtf8Bom' $plain "// $acao $emoji" $impl) $utf8Bom
Save 'U_ClosedLf.pas' (UnitText 'U_ClosedLf' $plain '// lf only' $impl) $utf8 "`n"
Save 'U_ClosedDirective.pas' (UnitText 'U_ClosedDirective' "uses`n  System.SysUtils,`n  {`$IFDEF DEBUG}`n  System.Diagnostics,`n  {`$ENDIF}`n  System.StrUtils,`n  System.Classes;" "// $acao" $impl) $ansi
Save 'U_Comment.pas' (UnitText 'U_Comment' "uses`n  System.SysUtils,`n  // precisa vir antes`n  System.Classes;" '// comentario no meio do uses' '') $ansi
Save 'U_ReadOnly.pas' (UnitText 'U_ReadOnly' $plain '// somente leitura' $impl) $ansi
Save 'Terceiros\U_Third.pas' (UnitText 'U_Third' $plain '// terceiros' $impl) $ansi
Save 'ForaDoProjeto.pas' (UnitText 'ForaDoProjeto' $plain '// nao esta no projeto' $impl) $ansi
Save 'Forms\U_Form.pas' @"
unit U_Form;

interface

uses
  Vcl.Forms, System.SysUtils, System.Classes, Vcl.Controls;

type
  // formul$([char]0xE1)rio
  TFormAuto = class(TForm)
  end;

var
  FormAuto: TFormAuto;

implementation

{`$R *.dfm}

uses System.Types, System.Math;

end.
"@ $ansi
Save 'Forms\U_Form.dfm' "object FormAuto: TFormAuto`n  Caption = 'Auto'`n  ClientHeight = 100`n  ClientWidth = 200`nend`n" $ansi
Save 'AutoTeste.dpr' @"
program AutoTeste;

{`$APPTYPE CONSOLE}

uses
  U_Open1 in 'U_Open1.pas',
  U_Open2 in 'U_Open2.pas',
  U_ClosedAnsi in 'U_ClosedAnsi.pas',
  U_ClosedUtf8Bom in 'U_ClosedUtf8Bom.pas',
  U_ClosedLf in 'U_ClosedLf.pas',
  U_ClosedDirective in 'U_ClosedDirective.pas',
  U_Comment in 'U_Comment.pas',
  U_ReadOnly in 'U_ReadOnly.pas',
  U_Third in 'Terceiros\U_Third.pas',
  U_Form in 'Forms\U_Form.pas' {FormAuto};

begin
  Writeln(U_Open1_Value);
end.
"@ $ansi
Copy-Item -LiteralPath $project -Destination $originals -Recurse
(Get-Item (Join-Path $project 'U_ReadOnly.pas')).IsReadOnly = $true
}

function Stop-Ide($process) {
    if ($process.HasExited) { return }
    # Only the instance started here is ended, and without asking it to close:
    # a polite close makes the IDE show save prompts that nobody is there to answer.
    Stop-Process -Id $process.Id -Force
    $process.WaitForExit(10000) | Out-Null
}

if ($RealEnvironment) {
    # A fresh copy of the user's profile: registry and application data.
    $bdsVersion = $installations[$Version].Bds
    $cloneKey = "HKCU\Software\Embarcadero\$IdeProfile"
    if (Test-Path "HKCU:\Software\Embarcadero\$IdeProfile") { Remove-Item -Path "HKCU:\Software\Embarcadero\$IdeProfile" -Recurse -Force }
    & reg.exe copy "HKCU\Software\Embarcadero\BDS\$bdsVersion" "$cloneKey\$bdsVersion" /s /f | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Could not copy the IDE profile' }
    $cloneData = Join-Path $env:APPDATA "Embarcadero\$IdeProfile"
    if (Test-Path -LiteralPath $cloneData) { Remove-Item -LiteralPath $cloneData -Recurse -Force }
    $realData = Join-Path $env:APPDATA "Embarcadero\BDS\$bdsVersion"
    if (Test-Path -LiteralPath $realData) {
        New-Item -ItemType Directory -Force -Path $cloneData | Out-Null
        Copy-Item -LiteralPath $realData -Destination (Join-Path $cloneData $bdsVersion) -Recurse -Force
    }
    # CS.Coder tools are left out of the copy: only the test package is loaded.
    foreach ($packages in 'Known Packages','Known Packages x64') {
        if (Test-Path "$profileKey\$packages") {
            (Get-Item "$profileKey\$packages").Property | Where-Object { $_ -like '*\CSCoder.*' } | ForEach-Object { Remove-ItemProperty -Path "$profileKey\$packages" -Name $_ }
        }
    }
    $env:CSCODER_STYLER_SELFTEST_BUILD = '1'
}

# 3. First start creates the isolated profile from the installation defaults.
if (-not (Test-Path "$profileKey\$knownIde")) {
    Write-Output "Creating IDE profile $IdeProfile..."
    $first = Start-Process -FilePath $bds -ArgumentList '-r', $IdeProfile, '-ns', '-np' -PassThru
    $deadline = (Get-Date).AddSeconds(180)
    while (-not (Test-Path "$profileKey\$knownIde") -and (Get-Date) -lt $deadline -and -not $first.HasExited) { Start-Sleep -Seconds 2 }
    Start-Sleep -Seconds 20
    Stop-Ide $first
    if (-not (Test-Path "$profileKey\$knownIde")) { throw 'IDE profile was not created' }
}

# 4. Only the test package is registered, and only in the isolated profile.
if (-not (Test-Path "$profileKey\$knownPackages")) { New-Item -Path "$profileKey\$knownPackages" -Force | Out-Null }
(Get-Item "$profileKey\$knownPackages").Property | Where-Object { $_ -like '*CSCoder.UnitStyler*' } | ForEach-Object { Remove-ItemProperty -Path "$profileKey\$knownPackages" -Name $_ }
New-ItemProperty -Path "$profileKey\$knownPackages" -Name $bpl -Value 'CS.Coder Unit Styler (self-test)' -PropertyType String -Force | Out-Null

# A failed compilation must not leave a progress dialog waiting for someone to click OK.
if (-not (Test-Path "$profileKey\Compiling")) { New-Item -Path "$profileKey\Compiling" -Force | Out-Null }
Set-ItemProperty -Path "$profileKey\Compiling" -Name 'Show Compiler Progress' -Value 'False'

if ($Mode -eq 'shots') {
    # Theme of the isolated profile only.
    Set-ItemProperty -Path "$profileKey\Theme" -Name 'Theme' -Value $Theme
    New-Item -ItemType Directory -Force -Path (Join-Path $session 'shots') | Out-Null
    $env:CSCODER_STYLER_SELFTEST_SHOTS = Join-Path $session 'shots'
}
# The test IDE keeps the rules of the tool where the user's own Delphi keeps them.
# What is there now is put back after the run, and whatever the run creates is removed.
$dataRoot = Join-Path $env:LOCALAPPDATA 'CSCoder\UnitStyler'
$dataBefore = @{}
if (Test-Path -LiteralPath $dataRoot) {
    Get-ChildItem -LiteralPath $dataRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $dataRoot 'bin\*') } |
        ForEach-Object { $dataBefore[$_.FullName] = [System.IO.File]::ReadAllBytes($_.FullName) }
}
function Restore-StylerData {
    if (-not (Test-Path -LiteralPath $dataRoot)) { return }
    Get-ChildItem -LiteralPath $dataRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $dataRoot 'bin\*') } |
        Where-Object { -not $dataBefore.ContainsKey($_.FullName) } | Remove-Item -Force
    foreach ($name in $dataBefore.Keys) {
        $now = if (Test-Path -LiteralPath $name) { [System.IO.File]::ReadAllBytes($name) } else { $null }
        if ($null -eq $now -or [Convert]::ToBase64String($now) -ne [Convert]::ToBase64String($dataBefore[$name])) {
            New-Item -ItemType Directory -Force -Path (Split-Path $name) | Out-Null
            [System.IO.File]::WriteAllBytes($name, $dataBefore[$name])
        }
    }
    Get-ChildItem -LiteralPath $dataRoot -Recurse -Directory | Sort-Object { $_.FullName.Length } -Descending |
        Where-Object { $_.FullName -notlike (Join-Path $dataRoot 'bin*') -and -not (Get-ChildItem -LiteralPath $_.FullName -Force) } | Remove-Item -Force
}
# 5. Run: the package finds the report path in the environment and drives itself.
$env:CSCODER_STYLER_SELFTEST = $report
$env:CSCODER_STYLER_SELFTEST_MODE = $Mode
$env:CSCODER_STYLER_SELFTEST_LANG = $Language
$env:CSCODER_STYLER_SELFTEST_RULES = $Rules
$env:CSCODER_STYLER_SELFTEST_PROJECT = $projectPath
$env:CSCODER_STYLER_SELFTEST_ROOT = $project
$env:CSCODER_STYLER_SELFTEST_ORIG = $originals
try {
    $ide = Start-Process -FilePath $bds -ArgumentList '-r', $IdeProfile, '-ns', '-np', ('"' + $projectPath + '"') -PassThru
} finally {
    Remove-Item Env:\CSCODER_STYLER_SELFTEST_BUILD, Env:\CSCODER_STYLER_SELFTEST_RULES, Env:\CSCODER_STYLER_SELFTEST_LANG -ErrorAction SilentlyContinue
    Remove-Item Env:\CSCODER_STYLER_SELFTEST, Env:\CSCODER_STYLER_SELFTEST_MODE, Env:\CSCODER_STYLER_SELFTEST_PROJECT, Env:\CSCODER_STYLER_SELFTEST_ROOT, Env:\CSCODER_STYLER_SELFTEST_ORIG, Env:\CSCODER_STYLER_SELFTEST_SHOTS -ErrorAction SilentlyContinue
}
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$done = $false
while ((Get-Date) -lt $deadline -and -not $ide.HasExited) {
    if ((Test-Path $report) -and (Select-String -LiteralPath $report -Pattern '^DONE \|' -Quiet)) { $done = $true; break }
    Start-Sleep -Seconds 2
}
Stop-Ide $ide
Restore-StylerData
Write-Output "Session: $session"
if (Test-Path $report) { Get-Content -LiteralPath $report -Encoding UTF8 } else { Write-Output 'No report was written.' }
if (-not $done) { throw 'Self-test did not finish (IDE blocked, closed or timed out).' }
if (Select-String -LiteralPath $report -Pattern '^FAIL \|' -Quiet) { throw 'Self-test reported failures.' }
Write-Output 'IDE self-test passed.'
