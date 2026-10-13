# Tests the installer that goes in the zip (installer\StylerSetup.ps1), with no interaction.
#
#   .\installer-test.ps1                 the zip in dist\, every check below
#   .\installer-test.ps1 -SkipIde        without opening any Delphi
#
# 1. Sandbox: the zip is extracted outside the project and installed into a made-up
#    registry branch and a temporary folder. Nothing of the real Delphi is touched.
#    Covers: the five targets, a Delphi that is missing, an IDE never opened, update over
#    an older copy keeping the settings, uninstall, uninstall with -RemoveData, and the
#    refusal while a process named bds is running.
# 2. IDE: the same zip is installed into the isolated profile UnitStylerTest and each
#    IDE (11; 12 and 13 in 32 and 64 bits) is started with a small probe package, which
#    reports whether the installed package was loaded and its menu is there. Only the
#    Delphi started here is ended.
param(
    [string]$Zip,
    [switch]$SkipIde,
    [string]$IdeProfile = 'UnitStylerTest',
    [int]$TimeoutSeconds = 150
)
$ErrorActionPreference = 'Stop'
$installations = @{
    '11' = @{ Path = 'C:\Programas\Embarcadero\Delphi_11_3'; Bds = '22.0' }
    '12' = @{ Path = 'C:\Programas\Embarcadero\Delphi_12_3'; Bds = '23.0' }
    '13' = @{ Path = 'C:\Programas\Embarcadero\Delphi_13_1_v37'; Bds = '37.0' }
}
$targets = @(
    @{ V = '11'; P = 'Win32' }, @{ V = '12'; P = 'Win32' }, @{ V = '12'; P = 'Win64' },
    @{ V = '13'; P = 'Win32' }, @{ V = '13'; P = 'Win64' }
)
if (-not $Zip) { $Zip = (Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'dist') -Filter 'CSCoderUnitStyler-*.zip' | Select-Object -First 1).FullName }
if (-not $Zip -or -not (Test-Path -LiteralPath $Zip)) { throw 'No zip in dist\. Run package.ps1 first.' }
$expectedVersion = [System.IO.Path]::GetFileNameWithoutExtension($Zip) -replace '^CSCoderUnitStyler-', ''

$script:failures = 0
function Check([bool]$ok, [string]$name, [string]$detail = '') {
    if ($ok) { Write-Output "PASS | $name" } else { $script:failures++; Write-Output "FAIL | $name | $detail" }
}

# Outside the project, as someone who downloaded it would have it.
$work = Join-Path ([System.IO.Path]::GetTempPath()) ('CSCoderUnitStylerInstallTest-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
$extracted = Join-Path $work 'CSCoderUnitStyler'
New-Item -ItemType Directory -Force -Path $work | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($Zip, $extracted)
$setup = Join-Path $extracted 'StylerSetup.ps1'
Write-Output "Zip: $Zip ($((Get-Item -LiteralPath $Zip).Length) bytes), version $expectedVersion"
Write-Output "Extracted to: $extracted"
foreach ($f in 'Install.bat', 'Uninstall.bat', 'StylerSetup.ps1', 'README.txt', 'LEIAME.txt', 'LICENSE.txt', 'LICENCA.txt') {
    Check (Test-Path -LiteralPath (Join-Path $extracted $f)) "Zip has $f"
}

function Bpl([string]$root, $t) { Join-Path $root "D$($t.V)\$($t.P)\CSCoder.UnitStyler.D$($t.V).bpl" }
function KeyName($t) { if ($t.P -eq 'Win64') { 'Known Packages x64' } else { 'Known Packages' } }
function Registered([string]$registryRoot, $t) {
    $path = "HKCU:\$registryRoot\$($installations[$t.V].Bds)\$(KeyName $t)"
    if (-not (Test-Path $path)) { return @() }
    @((Get-Item $path).Property | Where-Object { $_ -like '*\CSCoder.UnitStyler.D*.bpl' })
}
# The installer in a process of its own, as the .bat starts it; returns its output and exit code.
function Run-Setup([string[]]$arguments) {
    $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setup @arguments 2>&1 | Out-String
    [pscustomobject]@{ Text = $out; Code = $LASTEXITCODE }
}
function New-Sandbox([string]$name, [string[]]$versions, [string[]]$neverOpened = @()) {
    $root = "Software\CSCoderUnitStylerInstallTest\$name"
    if (Test-Path "HKCU:\$root") { Remove-Item "HKCU:\$root" -Recurse -Force }
    foreach ($v in $versions) {
        $key = "HKCU:\$root\$($installations[$v].Bds)"
        New-Item -Path $key -Force | Out-Null
        New-ItemProperty -Path $key -Name 'RootDir' -Value "C:\Fake\Delphi$v\" -PropertyType String -Force | Out-Null
        if ($neverOpened -contains $v) { continue }
        New-Item -Path "$key\Known Packages" -Force | Out-Null
        if ($v -ne '11') { New-Item -Path "$key\Known Packages x64" -Force | Out-Null }
    }
    $root
}

try {
    # ---- 1. Sandbox ---------------------------------------------------------
    Write-Output ''
    Write-Output '== Sandbox: five targets'
    $reg = New-Sandbox 'all' @('11', '12', '13')
    $inst = Join-Path $work 'all\bin'
    $data = Split-Path $inst -Parent
    $r = Run-Setup @('-Action', 'install', '-RegistryRoot', $reg, '-InstallDir', $inst, '-SkipProcessCheck')
    Write-Output $r.Text.Trim()
    Check ($r.Code -eq 0) 'Install: exit code 0' "$($r.Code)"
    Check ($r.Text -match '\[OK\] Delphi 11 \(32-bit\)' -and $r.Text -match '\[OK\] Delphi 12 \(32-bit, 64-bit\)' -and $r.Text -match '\[OK\] Delphi 13 \(32-bit, 64-bit\)') 'Install: one line per Delphi, with the IDEs'
    foreach ($t in $targets) {
        $label = "D$($t.V) $($t.P)"
        $file = Bpl $inst $t; $packed = Bpl (Join-Path $extracted 'bin') $t
        $names = @(Registered $reg $t)
        Check ((Test-Path -LiteralPath $file) -and ((Get-FileHash -LiteralPath $file).Hash -eq (Get-FileHash -LiteralPath $packed).Hash)) "$label`: installed file equals the one in the zip"
        Check ((Get-Item -LiteralPath $file).VersionInfo.ProductVersion -eq $expectedVersion) "$label`: version $expectedVersion" (Get-Item -LiteralPath $file).VersionInfo.ProductVersion
        Check (($names.Count -eq 1) -and ($names[0] -eq $file)) "$label`: registered once, pointing to the installed file" ($names -join ' ; ')
    }
    Check (@(Registered $reg @{ V = '11'; P = 'Win64' }).Count -eq 0) 'D11: nothing registered for a 64-bit IDE'

    Write-Output ''
    Write-Output '== Sandbox: update over an older copy, settings kept'
    $settings = @{
        (Join-Path $data 'D12\settings.json') = '{"language":"de","shortcut":49237}'
        (Join-Path $data 'projects\Vendas.0123456789abcdef.json') = '{"excludedUnits":["A"]}'
    }
    foreach ($name in $settings.Keys) { New-Item -ItemType Directory -Force -Path (Split-Path $name) | Out-Null; [System.IO.File]::WriteAllText($name, $settings[$name]) }
    # An older copy registered from another folder, and a different file where the new one goes.
    $oldCopy = 'C:\Old\Place\CSCoder.UnitStyler.D12.bpl'
    New-ItemProperty -Path "HKCU:\$reg\23.0\Known Packages" -Name $oldCopy -Value 'old' -PropertyType String -Force | Out-Null
    New-Item -Path "HKCU:\$reg\23.0\Disabled Packages" -Force | Out-Null
    New-ItemProperty -Path "HKCU:\$reg\23.0\Disabled Packages" -Name $oldCopy -Value 'old' -PropertyType String -Force | Out-Null
    New-ItemProperty -Path "HKCU:\$reg\23.0\Known Packages" -Name 'C:\Other\Vendor.bpl' -Value 'someone else' -PropertyType String -Force | Out-Null
    [System.IO.File]::WriteAllText((Bpl $inst @{ V = '12'; P = 'Win32' }), 'older build')
    $r = Run-Setup @('-Action', 'install', '-RegistryRoot', $reg, '-InstallDir', $inst, '-SkipProcessCheck')
    Check ($r.Code -eq 0) 'Update: exit code 0' "$($r.Code)"
    $t12 = @{ V = '12'; P = 'Win32' }
    Check ((Get-FileHash -LiteralPath (Bpl $inst $t12)).Hash -eq (Get-FileHash -LiteralPath (Bpl (Join-Path $extracted 'bin') $t12)).Hash) 'Update: the older file was replaced'
    $names = @(Registered $reg $t12)
    Check (($names.Count -eq 1) -and ($names[0] -eq (Bpl $inst $t12))) 'Update: the older registration is gone, one left' ($names -join ' ; ')
    Check (@((Get-Item "HKCU:\$reg\23.0\Disabled Packages").Property).Count -eq 0) 'Update: no longer listed as disabled'
    Check ((Get-ItemProperty "HKCU:\$reg\23.0\Known Packages").'C:\Other\Vendor.bpl' -eq 'someone else') 'Update: packages of others untouched'
    $kept = $true; foreach ($name in $settings.Keys) { if (-not (Test-Path -LiteralPath $name) -or ([System.IO.File]::ReadAllText($name) -ne $settings[$name])) { $kept = $false } }
    Check $kept 'Update: settings kept, byte for byte'

    Write-Output ''
    Write-Output '== Sandbox: a process named bds is running'
    $fake = Join-Path $work 'fake\bds.exe'
    New-Item -ItemType Directory -Force -Path (Split-Path $fake) | Out-Null
    Copy-Item -LiteralPath (Join-Path $env:SystemRoot 'System32\ping.exe') -Destination $fake
    $before = (Get-FileHash -LiteralPath (Bpl $inst $t12)).Hash
    [System.IO.File]::WriteAllText((Bpl $inst @{ V = '13'; P = 'Win32' }), 'marker')
    $ping = Start-Process -FilePath $fake -ArgumentList '-n', '60', '127.0.0.1' -WindowStyle Hidden -PassThru
    try {
        Start-Sleep -Seconds 1
        $r = Run-Setup @('-Action', 'install', '-RegistryRoot', $reg, '-InstallDir', $inst)
        Write-Output $r.Text.Trim()
        Check ($r.Code -eq 2 -and $r.Text -match 'Delphi (is running|est. aberto)') 'Delphi open: install refuses with a message' "$($r.Code)"
        Check (([System.IO.File]::ReadAllText((Bpl $inst @{ V = '13'; P = 'Win32' })) -eq 'marker') -and ((Get-FileHash -LiteralPath (Bpl $inst $t12)).Hash -eq $before)) 'Delphi open: no file was touched'
        $r = Run-Setup @('-Action', 'uninstall', '-RegistryRoot', $reg, '-InstallDir', $inst)
        Check ($r.Code -eq 2 -and (Test-Path -LiteralPath (Bpl $inst $t12)) -and (@(Registered $reg $t12).Count -eq 1)) 'Delphi open: uninstall refuses and removes nothing' "$($r.Code)"
    } finally { if (-not $ping.HasExited) { Stop-Process -Id $ping.Id -Force } }

    Write-Output ''
    Write-Output '== Sandbox: uninstall'
    $r = Run-Setup @('-Action', 'uninstall', '-RegistryRoot', $reg, '-InstallDir', $inst, '-SkipProcessCheck')
    Write-Output $r.Text.Trim()
    Check ($r.Code -eq 0) 'Uninstall: exit code 0' "$($r.Code)"
    $left = 0; foreach ($t in $targets) { $left += @(Registered $reg $t).Count }
    Check ($left -eq 0) 'Uninstall: no registration left' "$left"
    Check (-not (Test-Path -LiteralPath $inst)) 'Uninstall: packages removed'
    $kept = $true; foreach ($name in $settings.Keys) { if (-not (Test-Path -LiteralPath $name)) { $kept = $false } }
    Check $kept 'Uninstall: settings kept'
    Check ((Get-ItemProperty "HKCU:\$reg\23.0\Known Packages").'C:\Other\Vendor.bpl' -eq 'someone else') 'Uninstall: packages of others untouched'

    Write-Output ''
    Write-Output '== Sandbox: uninstall with -RemoveData'
    [void](Run-Setup @('-Action', 'install', '-RegistryRoot', $reg, '-InstallDir', $inst, '-SkipProcessCheck'))
    [System.IO.File]::WriteAllText((Join-Path $data 'D12\settings.json.bak'), 'x')
    [System.IO.File]::WriteAllText((Join-Path $data 'D12\settings.json.{0A1B}.tmp'), 'x')
    $mine = Join-Path $data 'D12\my-notes.txt'; [System.IO.File]::WriteAllText($mine, 'belongs to the user')
    $r = Run-Setup @('-Action', 'uninstall', '-RemoveData', '-RegistryRoot', $reg, '-InstallDir', $inst, '-SkipProcessCheck')
    Write-Output $r.Text.Trim()
    Check ($r.Code -eq 0 -and $r.Text -match '/data') 'Remove data: exit code 0 and the notice is printed' "$($r.Code)"
    $gone = $true; foreach ($name in $settings.Keys) { if (Test-Path -LiteralPath $name) { $gone = $false } }
    Check ($gone -and -not (Test-Path -LiteralPath (Join-Path $data 'D12\settings.json.bak')) -and -not (Test-Path -LiteralPath (Join-Path $data 'projects'))) 'Remove data: rules, project settings and their copies deleted'
    Check ((Test-Path -LiteralPath $mine) -and -not (Test-Path -LiteralPath $inst)) 'Remove data: a file that is not of the tool stays'

    Write-Output ''
    Write-Output '== Sandbox: only Delphi 12 on the machine; Delphi 13 never opened; Delphi 11 key left behind'
    $reg2 = New-Sandbox 'some' @('12', '13') @('13')
    New-Item -Path "HKCU:\$reg2\22.0" -Force | Out-Null   # no RootDir: a Delphi that was removed
    $inst2 = Join-Path $work 'some\bin'
    $r = Run-Setup @('-Action', 'install', '-RegistryRoot', $reg2, '-InstallDir', $inst2, '-SkipProcessCheck')
    Write-Output $r.Text.Trim()
    Check ($r.Code -eq 0 -and $r.Text -match '\[OK\] Delphi 12' -and $r.Text -notmatch 'Delphi 11' -and $r.Text -match '\[--\] Delphi 13') 'Missing versions: skipped, the rest is installed' "$($r.Code)"
    Check ((Test-Path -LiteralPath (Bpl $inst2 @{ V = '12'; P = 'Win64' })) -and -not (Test-Path -LiteralPath (Join-Path $inst2 'D11')) -and -not (Test-Path -LiteralPath (Join-Path $inst2 'D13'))) 'Missing versions: only the files of Delphi 12 were copied'
    $reg3 = New-Sandbox 'none' @()
    $r = Run-Setup @('-Action', 'install', '-RegistryRoot', $reg3, '-InstallDir', (Join-Path $work 'none\bin'), '-SkipProcessCheck')
    Write-Output $r.Text.Trim()
    Check ($r.Code -eq 3 -and -not (Test-Path -LiteralPath (Join-Path $work 'none\bin'))) 'No Delphi at all: message, nothing copied' "$($r.Code)"

    # ---- 2. Inside each IDE ---------------------------------------------------
    if (-not $SkipIde) {
        Write-Output ''
        Write-Output "== IDE: the zip installed into the isolated profile $IdeProfile"
        $ideRoot = "Software\Embarcadero\$IdeProfile"
        $ideInst = Join-Path $work 'ide\bin'
        # The self-test package holds the same units: it cannot be loaded beside the product.
        foreach ($t in $targets) {
            $path = "HKCU:\$ideRoot\$($installations[$t.V].Bds)\$(KeyName $t)"
            if (Test-Path $path) { (Get-Item $path).Property | Where-Object { $_ -like '*CSCoder.UnitStyler*' } | ForEach-Object { Remove-ItemProperty -Path $path -Name $_ } }
        }
        $r = Run-Setup @('-Action', 'install', '-RegistryRoot', $ideRoot, '-InstallDir', $ideInst, '-SkipProcessCheck')
        Write-Output $r.Text.Trim()
        Check ($r.Code -eq 0) 'IDE profile: install exit code 0' "$($r.Code)"
        try {
            foreach ($t in $targets) {
                $label = "D$($t.V) $($t.P)"
                $installation = $installations[$t.V].Path
                $ide64 = $t.P -eq 'Win64'
                $bds = Join-Path $installation ($(if ($ide64) { 'bin64' } else { 'bin' }) + '\bds.exe')
                $key = "HKCU:\$ideRoot\$($installations[$t.V].Bds)\$(KeyName $t)"
                $installed = Bpl $ideInst $t
                if (-not (Test-Path -LiteralPath $installed)) { Check $false "$label`: installed into the profile" 'profile never opened; run ide-selftest.ps1 once for this IDE'; continue }
                $probeDir = Join-Path $PSScriptRoot "build\installer-test\D$($t.V)-$($t.P)"
                New-Item -ItemType Directory -Force -Path $probeDir | Out-Null
                Push-Location (Join-Path $PSScriptRoot 'tests\ide\packages')
                try {
                    $lib = Join-Path $installation $(if ($ide64) { 'lib\win64\release' } else { 'lib\win32\release' })
                    & (Join-Path $installation $(if ($ide64) { 'bin\dcc64.exe' } else { 'bin\dcc32.exe' })) '-B' '-Q' '-W' "-U$lib" "-E$probeDir" "-N0$probeDir" "-LE$probeDir" "-LN$probeDir" 'CSCoder.UnitStyler.MenuProbe.dpk' | Out-Null
                    if ($LASTEXITCODE -ne 0) { throw "Probe package build failed: $label" }
                } finally { Pop-Location }
                $probe = Join-Path $probeDir 'CSCoder.UnitStyler.MenuProbe.bpl'
                $report = Join-Path $probeDir 'report.txt'
                if (Test-Path -LiteralPath $report) { Remove-Item -LiteralPath $report -Force }
                New-ItemProperty -Path $key -Name $probe -Value 'CS.Coder Unit Styler (installer test)' -PropertyType String -Force | Out-Null
                $env:CSCODER_STYLER_MENUPROBE = $report
                try { $ide = Start-Process -FilePath $bds -ArgumentList '-r', $IdeProfile, '-ns', '-np' -PassThru }
                finally { Remove-Item Env:\CSCODER_STYLER_MENUPROBE -ErrorAction SilentlyContinue }
                $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
                $done = $false
                while ((Get-Date) -lt $deadline -and -not $ide.HasExited) {
                    if ((Test-Path -LiteralPath $report) -and (Select-String -LiteralPath $report -Pattern '^DONE' -Quiet)) { $done = $true; break }
                    Start-Sleep -Seconds 2
                }
                # Only the instance started here is ended.
                if (-not $ide.HasExited) { Stop-Process -Id $ide.Id -Force; $ide.WaitForExit(10000) | Out-Null }
                Remove-ItemProperty -Path $key -Name $probe -ErrorAction SilentlyContinue
                if (-not $done) { Check $false "$label`: the IDE started and the probe reported" 'no report (IDE blocked, closed or timed out)'; continue }
                $lines = Get-Content -LiteralPath $report -Encoding UTF8
                $module = ($lines | Where-Object { $_ -like 'MODULE=*' }) -replace '^MODULE=', ''
                $items = ($lines | Where-Object { $_ -like 'ITEMS=*' }) -replace '^ITEMS=', ''
                Check ($module -eq $installed) "$label`: the IDE loaded the installed package" "$module"
                Check (($lines -contains 'ROOT=True') -and ($lines -contains 'BRANCH=True') -and (@($items.Split('|') | Where-Object { $_ }).Count -eq 3)) "$label`: menu CS.Coder > Unit Styler with its three commands" $items
                Write-Output "INFO | $label menu: $items"
            }
        } finally {
            $r = Run-Setup @('-Action', 'uninstall', '-RegistryRoot', $ideRoot, '-InstallDir', $ideInst, '-SkipProcessCheck')
            $left = 0; foreach ($t in $targets) { $left += @(Registered $ideRoot $t).Count }
            Check ($r.Code -eq 0 -and $left -eq 0) 'IDE profile: left as it was, nothing of the product registered' "$left"
        }
    }
} finally {
    if (Test-Path 'HKCU:\Software\CSCoderUnitStylerInstallTest') { Remove-Item 'HKCU:\Software\CSCoderUnitStylerInstallTest' -Recurse -Force }
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
Write-Output ''
if ($script:failures -gt 0) { throw "Installer test: $($script:failures) failure(s)." }
Write-Output 'Installer test passed.'
