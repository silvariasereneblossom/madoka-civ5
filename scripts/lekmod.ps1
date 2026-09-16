<#
.SYNOPSIS
  Park or restore the Lekmod DLC pack. Lekmod and the Community Patch cannot be
  loaded together: Lekmod is a DLC-folder modpack whose Override files replace
  the base database, so CP's schema changes collide with it and the CP DLL
  asserts/crashes on load. Park Lekmod to test CP + Wish for the World; restore
  it to play Lekmod multiplayer.

.EXAMPLE
  .\scripts\lekmod.ps1 -Park
  .\scripts\lekmod.ps1 -Restore
  .\scripts\lekmod.ps1 -Status
#>
param(
    [switch]$Park,
    [switch]$Restore,
    [switch]$Status
)

$ErrorActionPreference = 'Stop'
$dlc    = "C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization V\Assets\DLC"
# Must be OUTSIDE the game's Assets tree: the game finds .Civ5Pkg files anywhere under Assets.
$parked = Join-Path $PSScriptRoot "..\build\parked-dlc"
$parked = [System.IO.Path]::GetFullPath($parked)

$inDlc    = Get-ChildItem -Path $dlc -Directory -Filter 'LEKMOD*' -ErrorAction SilentlyContinue
$inParked = Get-ChildItem -Path $parked -Directory -Filter 'LEKMOD*' -ErrorAction SilentlyContinue

if ($Status -or (-not $Park -and -not $Restore)) {
    if ($inDlc)    { "Lekmod ACTIVE:  $($inDlc.FullName)" }
    if ($inParked) { "Lekmod parked:  $($inParked.FullName)" }
    if (-not $inDlc -and -not $inParked) { "Lekmod not found in either location." }
    return
}

if (Get-Process CivilizationV, CivilizationV_DX11 -ErrorAction SilentlyContinue) {
    throw "Civilization V is running. Close it first."
}

if ($Park) {
    if (-not $inDlc) { "Nothing to park (already parked or not installed)."; return }
    New-Item -ItemType Directory -Force $parked | Out-Null
    Move-Item -Path $inDlc.FullName -Destination (Join-Path $parked $inDlc.Name)
    "Parked $($inDlc.Name) -> $parked. The game rebuilds its database on next launch (a few minutes)."
}

if ($Restore) {
    if (-not $inParked) { "Nothing to restore."; return }
    Move-Item -Path $inParked.FullName -Destination (Join-Path $dlc $inParked.Name)
    "Restored $($inParked.Name) -> $dlc. Disable (1) Community Patch and Wish for the World in the Mods menu before playing Lekmod."
}
