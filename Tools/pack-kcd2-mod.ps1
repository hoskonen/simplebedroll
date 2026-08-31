param(
    [ValidateSet("PackData", "PackLocalization", "PackAll", "Release")]
    [string]$Mode = "PackAll",

    [string]$ModRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ReleaseRoot = ".release",
    [System.IO.Compression.CompressionLevel]$CompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Resolve-FullPath {
    param([string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $ModRoot $Path))
}

function Read-ModInfo {
    param([string]$Root)

    $manifestPath = Join-Path $Root "mod.manifest"
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Cannot find mod.manifest at $manifestPath"
    }

    [xml]$manifest = Get-Content -LiteralPath $manifestPath -Raw
    $modId = [string]$manifest.kcd_mod.info.modid
    $version = [string]$manifest.kcd_mod.info.version

    if ([string]::IsNullOrWhiteSpace($modId)) {
        $modId = Split-Path -Leaf $Root
    }

    if ([string]::IsNullOrWhiteSpace($version)) {
        $version = "0.0.0"
    }

    return [pscustomobject]@{
        ModId = $modId.Trim()
        Version = $version.Trim()
    }
}

function New-ZipFromFolder {
    param(
        [string]$SourceDir,
        [string]$Destination,
        [scriptblock]$IncludeFile
    )

    if (-not (Test-Path -LiteralPath $SourceDir -PathType Container)) {
        Write-Host "Skipping missing folder: $SourceDir"
        return
    }

    $destinationDir = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir | Out-Null
    }

    $destinationFull = [System.IO.Path]::GetFullPath($Destination)
    $temp = "$Destination.tmp"
    $tempFull = [System.IO.Path]::GetFullPath($temp)
    if (Test-Path -LiteralPath $temp) {
        Remove-Item -LiteralPath $temp -Force
    }

    $sourceFull = [System.IO.Path]::GetFullPath($SourceDir).TrimEnd('\', '/')
    $zip = [System.IO.Compression.ZipFile]::Open($temp, [System.IO.Compression.ZipArchiveMode]::Create)

    try {
        Get-ChildItem -LiteralPath $sourceFull -Recurse -File -Force |
            Where-Object {
                $fileFull = [System.IO.Path]::GetFullPath($_.FullName)
                $fileFull -ine $destinationFull -and $fileFull -ine $tempFull -and (& $IncludeFile $_)
            } |
            Sort-Object FullName |
            ForEach-Object {
                $relative = $_.FullName.Substring($sourceFull.Length).TrimStart('\', '/')
                $entryName = $relative -replace '\\', '/'
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $entryName, $CompressionLevel) | Out-Null
                Write-Host "[+] $entryName"
            }
    }
    finally {
        $zip.Dispose()
    }

    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    $replaced = $false
    for ($attempt = 1; $attempt -le 8 -and -not $replaced; $attempt++) {
        try {
            if (Test-Path -LiteralPath $Destination) {
                Remove-Item -LiteralPath $Destination -Force
            }

            Move-Item -LiteralPath $temp -Destination $Destination
            $replaced = $true
        }
        catch {
            if ($attempt -eq 8) {
                throw
            }

            Start-Sleep -Milliseconds 250
        }
    }
    Write-Host "Wrote $Destination"
}

function Invoke-PackData {
    param($Info)

    $dataDir = Join-Path $ModRoot "Data"
    $pakPath = Join-Path $dataDir "$($Info.ModId).pak"

    New-ZipFromFolder -SourceDir $dataDir -Destination $pakPath -IncludeFile {
        param($File)
        return $File.Extension -ine ".pak"
    }
}

function Invoke-PackLocalization {
    $locDir = Join-Path $ModRoot "Localization"
    $pakPath = Join-Path $locDir "English_xml.pak"

    New-ZipFromFolder -SourceDir $locDir -Destination $pakPath -IncludeFile {
        param($File)
        return $File.Extension -ine ".pak"
    }
}

function Copy-CleanModToStage {
    param($Info)

    $releaseFull = Resolve-FullPath $ReleaseRoot
    $stageRoot = Join-Path $releaseFull "staging"
    $stageMod = Join-Path $stageRoot $Info.ModId

    if (Test-Path -LiteralPath $stageMod) {
        Remove-Item -LiteralPath $stageMod -Recurse -Force
    }

    New-Item -ItemType Directory -Path $stageMod | Out-Null

    $excludedRootNames = @(".git", ".vscode", ".gitignore", ".release", "Tools")
    Get-ChildItem -LiteralPath $ModRoot -Force |
        Where-Object { $excludedRootNames -notcontains $_.Name } |
        ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $stageMod -Recurse -Force
        }

    $stageData = Join-Path $stageMod "Data"
    if (Test-Path -LiteralPath $stageData) {
        Get-ChildItem -LiteralPath $stageData -Directory -Force |
            ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force }
        Get-ChildItem -LiteralPath $stageData -File -Force |
            Where-Object { $_.Extension -ine ".pak" } |
            ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
    }

    $stageLoc = Join-Path $stageMod "Localization"
    if (Test-Path -LiteralPath $stageLoc) {
        Get-ChildItem -LiteralPath $stageLoc -File -Force |
            Where-Object { $_.Extension -ine ".pak" } |
            ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
    }

    return [pscustomobject]@{
        ReleaseRoot = $releaseFull
        StageRoot = $stageRoot
        StageMod = $stageMod
    }
}

function Invoke-Release {
    param($Info)

    Invoke-PackData $Info
    Invoke-PackLocalization

    $stage = Copy-CleanModToStage $Info
    $zipPath = Join-Path $stage.ReleaseRoot "$($Info.ModId)-$($Info.Version).zip"

    New-ZipFromFolder -SourceDir $stage.StageRoot -Destination $zipPath -IncludeFile {
        param($File)
        return $true
    }

    Write-Host "Release package ready: $zipPath"
}

$ModRoot = [System.IO.Path]::GetFullPath($ModRoot)
$info = Read-ModInfo $ModRoot

switch ($Mode) {
    "PackData" { Invoke-PackData $info }
    "PackLocalization" { Invoke-PackLocalization }
    "PackAll" {
        Invoke-PackData $info
        Invoke-PackLocalization
    }
    "Release" { Invoke-Release $info }
}
