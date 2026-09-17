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
$game   = "C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization V"
$dlc    = Join-Path $game "Assets\DLC"
$maps   = Join-Path $game "Assets\Maps"
# Must be OUTSIDE the game's Assets tree: the game finds .Civ5Pkg files anywhere under Assets.
$parked = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\build\parked-dlc"))
$parkedMaps = Join-Path $parked "Maps"

# Lekmap's map scripts are written against Lekmod; without it one errors at every launch
# and the Pangaea Fractal script regenerates forever (game freezes at "initiating map").
# They travel with the pack.
$items = @(
    @{ Name = 'Lekmod DLC pack'; Live = (Get-ChildItem -Path $dlc  -Directory -Filter 'LEKMOD*' -ErrorAction SilentlyContinue); LiveDir = $dlc;  ParkDir = $parked;     Parked = (Get-ChildItem -Path $parked     -Directory -Filter 'LEKMOD*' -ErrorAction SilentlyContinue) },
    @{ Name = 'Lekmap scripts';  Live = (Get-ChildItem -Path $maps -Directory -Filter 'Lekmap*' -ErrorAction SilentlyContinue); LiveDir = $maps; ParkDir = $parkedMaps; Parked = (Get-ChildItem -Path $parkedMaps -Directory -Filter 'Lekmap*' -ErrorAction SilentlyContinue) }
)

if ($Status -or (-not $Park -and -not $Restore)) {
    foreach ($it in $items) {
        foreach ($d in @($it.Live))   { if ($d) { "$($it.Name) ACTIVE:  $($d.FullName)" } }
        foreach ($d in @($it.Parked)) { if ($d) { "$($it.Name) parked:  $($d.FullName)" } }
        if (-not $it.Live -and -not $it.Parked) { "$($it.Name): not found in either location." }
    }
    return
}

if (Get-Process CivilizationV, CivilizationV_DX11 -ErrorAction SilentlyContinue) {
    throw "Civilization V is running. Close it first."
}

foreach ($it in $items) {
    if ($Park) {
        foreach ($d in @($it.Live)) {
            if (-not $d) { continue }
            New-Item -ItemType Directory -Force $it.ParkDir | Out-Null
            Move-Item -Path $d.FullName -Destination (Join-Path $it.ParkDir $d.Name)
            "Parked $($it.Name): $($d.Name) -> $($it.ParkDir)"
        }
    }
    if ($Restore) {
        foreach ($d in @($it.Parked)) {
            if (-not $d) { continue }
            Move-Item -Path $d.FullName -Destination (Join-Path $it.LiveDir $d.Name)
            "Restored $($it.Name): $($d.Name) -> $($it.LiveDir)"
        }
    }
}
if ($Park)    { "The game rebuilds its database on next launch (a few minutes). Pick a standard map type in Set Up Game." }
if ($Restore) { "Disable (1) Community Patch and Wish for the World in the Mods menu before playing Lekmod." }
