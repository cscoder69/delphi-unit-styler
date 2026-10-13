param(
    [ValidateSet('11','12','13')][string]$Version = '11',
    [ValidateSet('Win32','Win64')][string]$Platform = 'Win32',
    [ValidateSet('Demo','Package')][string]$Target = 'Demo',
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9_-]*$')][string]$BuildName
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
$outputDirectory = Join-Path $PSScriptRoot "build\$Target\D$Version\$Platform"
if ($BuildName) { $outputDirectory = Join-Path $outputDirectory $BuildName }
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$libraryDirectory = Join-Path $installation "lib\$($Platform.ToLowerInvariant())\release"
$sourceDirectories = @('src\core','src\i18n','src\ui','src\config','src\ide') | ForEach-Object { Join-Path $PSScriptRoot $_ }
$searchPath = ($sourceDirectories + $libraryDirectory) -join ';'
$inputDirectory = if ($Target -eq 'Demo') { 'demo' } else { 'packages' }
$inputFile = if ($Target -eq 'Demo') { 'Styler.Demo.dpr' } else { "CSCoder.UnitStyler.D$Version.dpk" }
# Icon and license texts of the About window; the paths in the .rc are relative to its folder.
Push-Location (Join-Path $PSScriptRoot 'src\ui')
try {
    & (Join-Path $installation 'bin\brcc32.exe') "-fo$(Join-Path $outputDirectory 'CSCoder.Styler.About.res')" 'CSCoder.Styler.About.rc' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'About resource compilation failed' }
} finally { Pop-Location }
Push-Location (Join-Path $PSScriptRoot $inputDirectory)
try {
    if ($Target -eq 'Demo') {
        & (Join-Path $installation 'bin\brcc32.exe') "-fo$(Join-Path $outputDirectory 'Styler.Demo.res')" 'Styler.Demo.rc'
        if ($LASTEXITCODE -ne 0) { throw 'Resource compilation failed' }
    }
    if ($Target -eq 'Package') {
        # One source for the version: the constant shown by the About window.
        $about = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'src\ui\CSCoder.Styler.About.pas') -Raw -Encoding UTF8
        if ($about -notmatch "StylerVersion\s*=\s*'([^']+)'") { throw 'StylerVersion not found' }
        $productVersion = $Matches[1]
        $numbers = @($productVersion.Split('.') | ForEach-Object { [int]($_ -replace '\D', '') })
        while ($numbers.Count -lt 4) { $numbers += 0 }
        $fileVersion = ($numbers[0..3] -join '.')
        $rc = @"
1 VERSIONINFO
FILEVERSION $($numbers[0..3] -join ',')
PRODUCTVERSION $($numbers[0..3] -join ',')
FILEOS 0x4
FILETYPE 0x2
BEGIN
  BLOCK "StringFileInfo"
  BEGIN
    BLOCK "041604E4"
    BEGIN
      VALUE "CompanyName", "CS.Coder\0"
      VALUE "FileDescription", "CS.Coder - Unit Styler\0"
      VALUE "FileVersion", "$fileVersion\0"
      VALUE "ProductName", "Unit Styler\0"
      VALUE "ProductVersion", "$productVersion\0"
    END
  END
  BLOCK "VarFileInfo"
  BEGIN
    VALUE "Translation", 0x0416, 1252
  END
END
"@
        $rcFile = Join-Path $outputDirectory 'CSCoder.UnitStyler.version.rc'
        Set-Content -LiteralPath $rcFile -Value $rc -Encoding Ascii
        & (Join-Path $installation 'bin\brcc32.exe') "-fo$(Join-Path $outputDirectory 'CSCoder.UnitStyler.version.res')" $rcFile | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Version resource compilation failed' }
    }
    & $compiler '-B' '-Q' '-W' "-U$searchPath" "-R$outputDirectory" "-E$outputDirectory" "-N0$outputDirectory" "-LE$outputDirectory" "-LN$outputDirectory" $inputFile
    if ($LASTEXITCODE -ne 0) { throw "Build failed: $Target D$Version/$Platform" }
} finally { Pop-Location }
