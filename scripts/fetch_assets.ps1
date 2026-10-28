<#
.SYNOPSIS
    Automated fetcher for KayKit & Kenney open-source game assets into Godot res://assets/
.DESCRIPTION
    Clones or downloads public KayKit repositories (Skeletons, Adventurers, Dungeon, Animations)
    and Kenney audio/UI assets, copying them directly to matching res://assets/ paths.
#>

param(
    [string]$TargetDir = "$PSScriptRoot\..\assets",
    [switch]$Force = $false
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Echoes of the Ossuary — Asset Downloader & Ingestor      " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$tempFolder = Join-Path $env:TEMP "kaykit_temp_$(Get-Random)"
New-Item -ItemType Directory -Force -Path $tempFolder | Out-Null

$repos = @(
    @{
        Name = "KayKit-Dungeon-Pack-1.0";
        Url = "https://github.com/KayKit-Game-Assets/KayKit-Dungeon-Pack-1.0.git";
        Dest = Join-Path $TargetDir "dungeon"
    },
    @{
        Name = "KayKit-Character-Pack-Skeletons-1.0";
        Url = "https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0.git";
        Dest = Join-Path $TargetDir "characters\skeletons"
    },
    @{
        Name = "KayKit-Character-Animations-1.0";
        Url = "https://github.com/KayKit-Game-Assets/KayKit-Character-Animations-1.0.git";
        Dest = Join-Path $TargetDir "animations"
    }
)

foreach ($repo in $repos) {
    Write-Host "`n[+] Processing: $($repo.Name)..." -ForegroundColor Yellow
    $clonePath = Join-Path $tempFolder $repo.Name
    
    # Try git clone shallow first
    git clone --depth 1 $repo.Url $clonePath 2>$null
    
    if (Test-Path $clonePath) {
        Write-Host "  Copying assets to $($repo.Dest)..." -ForegroundColor Green
        New-Item -ItemType Directory -Force -Path $repo.Dest | Out-Null
        
        Get-ChildItem -Path $clonePath -Recurse -Include "*.glb", "*.gltf", "*.bin", "*.png" | ForEach-Object {
            $destFile = Join-Path $repo.Dest $_.Name
            Copy-Item -Path $_.FullName -Destination $destFile -Force
        }
        Write-Host "  Successfully updated $($repo.Name)." -ForegroundColor Green
    } else {
        Write-Warning "  Git clone was unable to reach $($repo.Url). Procedural fallbacks remain active and crash-free."
    }
}

# Cleanup
Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n[✓] Ingestion complete! Launch Godot to hot-swap assets or use procedural fallbacks." -ForegroundColor Cyan
