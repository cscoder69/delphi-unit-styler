# For development: builds the Unit Styler package from the source code and installs it
# in the Delphi IDEs of this machine. It needs the Delphi command-line compilers and the
# folders listed below. The installer people download is another one: installer\Install.bat,
# which goes in the zip assembled by package.ps1 and needs no compiler.
# For each chosen Delphi version it builds the package for every IDE that
# version has (32-bit; also 64-bit in Delphi 12 and 13), copies it to
# %LOCALAPPDATA%\CSCoder\UnitStyler\bin and registers it for the current user.
# Nothing else of the IDE configuration is changed, and settings are kept.
#
#   .\dev-install.ps1                       install in every Delphi found
#   .\dev-install.ps1 -Version 11           only Delphi 11
#   .\dev-install.ps1 -Uninstall            remove from every Delphi
#   .\dev-install.ps1 -DryRun               show what would be done
param(
    [ValidateSet('11','12','13','All')][string[]]$Version = 'All',
    [switch]$Uninstall,
    # Use packages already built under build\Package\D<v>\<platform>\<BuildName>.
    [switch]$NoBuild,
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9_-]*$')][string]$BuildName = 'install',
    [switch]$DryRun,
    # Registry profile of the IDE; BDS is the normal one. Tests use an isolated profile.
    [string]$IdeProfile = 'BDS'
)
$ErrorActionPreference = 'Stop'
$installations = @{
    '11' = @{ Path = 'C:\Programas\Embarcadero\Delphi_11_3'; Bds = '22.0'; Ide64 = $false }
    '12' = @{ Path = 'C:\Programas\Embarcadero\Delphi_12_3'; Bds = '23.0'; Ide64 = $true }
    '13' = @{ Path = 'C:\Programas\Embarcadero\Delphi_13_1_v37'; Bds = '37.0'; Ide64 = $true }
}
$description = 'CS.Coder - Unit Styler (https://www.cscoder.com.br)'
$binRoot = Join-Path $env:LOCALAPPDATA 'CSCoder\UnitStyler\bin'
$versions = if ($Version -contains 'All') { '11','12','13' } else { $Version | Sort-Object -Unique }
$failed = $false

function Test-Locked([string]$file) {
    if (-not (Test-Path -LiteralPath $file)) { return $false }
    try { $stream = [System.IO.File]::Open($file, 'Open', 'ReadWrite', 'None'); $stream.Close(); return $false }
    catch { return $true }
}

foreach ($v in $versions) {
    $delphi = $installations[$v]
    if (-not (Test-Path -LiteralPath (Join-Path $delphi.Path 'bin\bds.exe'))) {
        Write-Output "Delphi $v`: nao encontrado em $($delphi.Path); ignorado."
        continue
    }
    $profileKey = "HKCU:\Software\Embarcadero\$IdeProfile\$($delphi.Bds)"
    if (-not (Test-Path $profileKey)) {
        Write-Output "Delphi $v`: perfil $IdeProfile nunca foi aberto por este usuario; ignorado."
        continue
    }
    $targets = @(@{ Platform = 'Win32'; Key = 'Known Packages' })
    if ($delphi.Ide64) { $targets += @{ Platform = 'Win64'; Key = 'Known Packages x64' } }
    foreach ($target in $targets) {
        $label = "Delphi $v $($target.Platform)"
        $bplName = "CSCoder.UnitStyler.D$v.bpl"
        $destination = Join-Path $binRoot "D$v\$($target.Platform)\$bplName"
        $key = "$profileKey\$($target.Key)"
        # Entries of this tool only, wherever an earlier install pointed them.
        $registered = @()
        if (Test-Path $key) { $registered = @((Get-Item $key).Property | Where-Object { $_ -like '*\CSCoder.UnitStyler.D*.bpl' }) }
        if (Test-Locked $destination) {
            Write-Output "$label`: o pacote esta em uso. Feche o Delphi $v e rode de novo."
            $failed = $true
            continue
        }
        if ($Uninstall) {
            if ($DryRun) { Write-Output "$label`: removeria $($registered.Count) registro(s) e $destination"; continue }
            foreach ($name in $registered) { Remove-ItemProperty -Path $key -Name $name }
            if (Test-Path -LiteralPath $destination) { Remove-Item -LiteralPath $destination -Force }
            Write-Output "$label`: removido."
            continue
        }
        $source = Join-Path $PSScriptRoot "build\Package\D$v\$($target.Platform)\$BuildName\$bplName"
        if ($DryRun) { Write-Output "$label`: instalaria $source em $destination e registraria em $key"; continue }
        if (-not $NoBuild) {
            & (Join-Path $PSScriptRoot 'build.ps1') -Target Package -Version $v -Platform $target.Platform -BuildName $BuildName | Out-Null
        }
        if (-not (Test-Path -LiteralPath $source)) { throw "$label`: pacote nao encontrado em $source" }
        New-Item -ItemType Directory -Force -Path (Split-Path $destination) | Out-Null
        Copy-Item -LiteralPath $source -Destination $destination -Force
        if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
        foreach ($name in $registered) { if ($name -ne $destination) { Remove-ItemProperty -Path $key -Name $name } }
        New-ItemProperty -Path $key -Name $destination -Value $description -PropertyType String -Force | Out-Null
        $same = (Get-FileHash -LiteralPath $source).Hash -eq (Get-FileHash -LiteralPath $destination).Hash
        if (-not $same) { throw "$label`: a copia instalada difere do pacote compilado" }
        Write-Output "$label`: instalado, versao $((Get-Item -LiteralPath $destination).VersionInfo.ProductVersion)."
    }
}
if ($failed) { throw 'Instalacao incompleta: ha Delphi aberto usando o pacote.' }
