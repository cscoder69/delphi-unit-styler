param(
    [ValidateSet('11','12','13')][string]$Version = '11',
    [ValidateSet('Win32','Win64')][string]$Platform = 'Win32',
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9_-]*$')][string]$SessionName = 'baseline'
)
$ErrorActionPreference = 'Stop'
if ($Version -eq '11' -and $Platform -eq 'Win64') {
    throw 'Delphi 11: only Win32 is part of the approved matrix.'
}
$installations = @{
    '11' = 'C:\Programas\Embarcadero\Delphi_11_3'
    '12' = 'C:\Programas\Embarcadero\Delphi_12_3'
    '13' = 'C:\Programas\Embarcadero\Delphi_13_1_v37'
}
$installation = $installations[$Version]
$compilerName = if ($Platform -eq 'Win32') { 'dcc32.exe' } else { 'dcc64.exe' }
$compiler = Join-Path $installation "bin\$compilerName"
if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
    throw "Compiler unavailable: $compiler"
}
$sessionDirectory = Join-Path $PSScriptRoot "build\ide-tests\D$Version\$Platform\$SessionName"
if (Test-Path -LiteralPath $sessionDirectory) {
    throw 'Test session already exists. Use a new -SessionName to preserve previous work.'
}
$outputDirectory = Join-Path $sessionDirectory 'output'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$fixtureDirectory = Join-Path $PSScriptRoot 'tests\ide\fixtures'
Get-ChildItem -LiteralPath $fixtureDirectory -File | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $sessionDirectory
}
$libraryDirectory = Join-Path $installation "lib\$($Platform.ToLowerInvariant())\release"
Push-Location $sessionDirectory
try {
    & $compiler '-B' '-Q' '-W' "-U$libraryDirectory" "-E$outputDirectory" "-N0$outputDirectory" 'Styler.IDE.Sample.dpr'
    if ($LASTEXITCODE -ne 0) { throw 'IDE fixture compilation failed.' }
    & (Join-Path $outputDirectory 'Styler.IDE.Sample.exe')
    if ($LASTEXITCODE -ne 0) { throw 'IDE fixture execution failed.' }
} finally { Pop-Location }
Write-Output "Prepared: $(Join-Path $sessionDirectory 'Styler.IDE.Sample.dpr')"
Write-Output 'Only the standalone fixture ran. Package loading and editor validation remain pending.'
