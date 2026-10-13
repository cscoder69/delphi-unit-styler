param(
    [ValidateSet('11', '12', '13')][string]$Version = '11',
    [ValidateSet('Win32', 'Win64')][string]$Platform = 'Win32'
)
$ErrorActionPreference = 'Stop'
$installations = @{
    '11' = 'C:\Programas\Embarcadero\Delphi_11_3'
    '12' = 'C:\Programas\Embarcadero\Delphi_12_3'
    '13' = 'C:\Programas\Embarcadero\Delphi_13_1_v37'
}
$installation = $installations[$Version]
$compilerName = if ($Platform -eq 'Win32') { 'dcc32.exe' } else { 'dcc64.exe' }
$compiler = Join-Path $installation "bin\$compilerName"
if (-not (Test-Path -LiteralPath $compiler)) { throw "Compiler unavailable: $compiler" }
$outputDirectory = Join-Path $PSScriptRoot "build\tests\D$Version\$Platform"
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$libraryDirectory = Join-Path $installation "lib\$($Platform.ToLowerInvariant())\release"
Push-Location (Join-Path $PSScriptRoot 'tests')
try {
    & $compiler '-B' '-Q' '-W' "-U$libraryDirectory" "-E$outputDirectory" "-N0$outputDirectory" 'Styler.Core.Tests.dpr'
    if ($LASTEXITCODE -ne 0) { throw "Compilation failed: D$Version/$Platform" }
    & (Join-Path $outputDirectory 'Styler.Core.Tests.exe')
    if ($LASTEXITCODE -ne 0) { throw "Tests failed: D$Version/$Platform" }
    & $compiler '-B' '-Q' '-W' "-U$libraryDirectory" "-E$outputDirectory" "-N0$outputDirectory" 'Styler.Settings.Tests.dpr'
    if ($LASTEXITCODE -ne 0) { throw "Settings compilation failed: D$Version/$Platform" }
    & (Join-Path $outputDirectory 'Styler.Settings.Tests.exe')
    if ($LASTEXITCODE -ne 0) { throw "Settings tests failed: D$Version/$Platform" }
    & $compiler '-B' '-Q' '-W' "-U$libraryDirectory" "-E$outputDirectory" "-N0$outputDirectory" 'Styler.Batch.Tests.dpr'
    if ($LASTEXITCODE -ne 0) { throw "Batch compilation failed: D$Version/$Platform" }
    & (Join-Path $outputDirectory 'Styler.Batch.Tests.exe')
    if ($LASTEXITCODE -ne 0) { throw "Batch tests failed: D$Version/$Platform" }
    # Temporary folders created by the settings and batch tests.
    Get-ChildItem -LiteralPath $outputDirectory -Directory | Where-Object { $_.Name -like 'settings-*' -or $_.Name -like 'batch-*' } | Remove-Item -Recurse -Force
} finally {
    Pop-Location
}
