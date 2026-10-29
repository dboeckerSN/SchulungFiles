#Requires -Version 5.1
<#
.SYNOPSIS
    Richtet WSL2 mit Ubuntu 24.04 (sn-ubuntu) ein. Als Administrator ausführen.
.PARAMETER DistroName
    Name der WSL-Distribution (Default: sn-ubuntu).
.PARAMETER UnregisterOld
    Optional: Name einer alten Distribution, die (nach Rückfrage) gelöscht wird.
    ACHTUNG: Alle Daten der Distribution gehen verloren.
#>
[CmdletBinding()]
param(
    [string]$DistroName = 'sn-ubuntu',
    [string]$UnregisterOld
)

$ErrorActionPreference = 'Stop'

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

# wsl.exe gibt UTF-16 aus; Nullbytes entfernen, damit -contains funktioniert.
function Get-WslDistros {
    (& wsl.exe --list --quiet) -replace "`0", '' | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() }
}

if (-not (Test-Admin)) {
    throw 'Bitte PowerShell als Administrator starten.'
}

$build = [Environment]::OSVersion.Version.Build
if ($build -lt 19041) {
    throw "Windows-Build $build zu alt. WSL2 braucht Windows 10 2004 (19041) oder neuer."
}

if ($UnregisterOld) {
    if ((Get-WslDistros) -contains $UnregisterOld) {
        $answer = Read-Host "Distribution '$UnregisterOld' UNWIDERRUFLICH löschen? (ja/N)"
        if ($answer -eq 'ja') {
            wsl.exe --unregister $UnregisterOld
            Write-Host "'$UnregisterOld' gelöscht. Ggf. ist ein Neustart nötig."
        } else {
            Write-Host 'Abgebrochen, nichts gelöscht.'
        }
    } else {
        Write-Warning "Distribution '$UnregisterOld' nicht gefunden."
    }
}

if ((Get-WslDistros) -contains $DistroName) {
    Write-Host "Distribution '$DistroName' existiert bereits - Installation übersprungen."
} else {
    Write-Host "Installiere Ubuntu-24.04 als '$DistroName' ..."
    Write-Host 'Beim ersten Start Benutzername und Passwort vergeben, danach mit "exit" die Ubuntu-Shell verlassen.'
    wsl.exe --install -d Ubuntu-24.04 --name $DistroName
    if ($LASTEXITCODE -ne 0) { throw "wsl --install fehlgeschlagen (Exitcode $LASTEXITCODE)." }
    Read-Host 'Falls Windows einen Neustart verlangt: jetzt neu starten und das Skript erneut ausführen. Sonst Enter'
}

if ((Get-WslDistros) -contains $DistroName) {
    wsl.exe --set-default $DistroName
    Write-Host "'$DistroName' ist jetzt Standard."
}

wsl.exe --version
Write-Host "`nFertig. Weiter in der WSL: bash 02-wsl-docker-git.sh"
