param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Kcd2ModRoot = "F:\SteamLibrary\steamapps\common\KCD2Mod",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$Mappings = @(
    @{
        Name = "Entities"
        Heading = "ENTITIES"
        Source = "Data\Entities"
        Destination = "Data\Entities"
        Filter = "*.ent"
    },
    @{
        Name = "Entity scripts"
        Heading = "ENTITY SCRIPTS"
        Source = "Data\Scripts\Entities"
        Destination = "Data\Scripts\Entities"
        Filter = "*.lua"
    },
    @{
        Name = "SimpleBedRoll prefabs"
        Heading = "PREFABS"
        Source = "Data\Prefabs\simplebedroll"
        Destination = "Data\Prefabs\simplebedroll"
        Filter = "*.xml"
    }
)

function Resolve-FullPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $RelativePath))
}

function Test-FilesEqual {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $DestinationPath -PathType Leaf)) {
        return $false
    }

    $sourceItem = Get-Item -LiteralPath $SourcePath
    $destinationItem = Get-Item -LiteralPath $DestinationPath

    if ($sourceItem.Length -ne $destinationItem.Length) {
        return $false
    }

    $sourceHash = Get-FileHash -Algorithm SHA256 -LiteralPath $SourcePath
    $destinationHash = Get-FileHash -Algorithm SHA256 -LiteralPath $DestinationPath

    return $sourceHash.Hash -eq $destinationHash.Hash
}

function Write-Header {
    Write-Host "SimpleBedRoll Authoring Sync"
    Write-Host "Direction: repo -> KCD2Mod"
    if ($DryRun) {
        Write-Host "Mode: DRY RUN"
    }
    else {
        Write-Host "Mode: COPY"
    }
    Write-Host "Source: $RepoRoot"
    Write-Host "Destination: $Kcd2ModRoot"
}

function Copy-Mapping {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Mapping
    )

    $sourceRoot = Resolve-FullPath $RepoRoot $Mapping.Source
    $destinationRoot = Resolve-FullPath $Kcd2ModRoot $Mapping.Destination

    if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
        Write-Host ""
        Write-Host "=== $($Mapping.Heading) ==="
        Write-Host "[SKIP:missing-source] $($Mapping.Source)"
        return [pscustomobject]@{
            Scanned = 0
            Copied = 0
            Identical = 0
            MissingSource = 1
        }
    }

    if (-not $DryRun -and -not (Test-Path -LiteralPath $destinationRoot)) {
        New-Item -ItemType Directory -Path $destinationRoot | Out-Null
    }

    Write-Host ""
    Write-Host "=== $($Mapping.Heading) ==="

    $scanned = 0
    $copied = 0
    $identical = 0

    Get-ChildItem -LiteralPath $sourceRoot -File -Filter $Mapping.Filter |
        Sort-Object Name |
        ForEach-Object {
            $scanned++
            $destinationPath = Join-Path $destinationRoot $_.Name
            $destinationDirectory = Split-Path -Parent $destinationPath
            $isDifferent = -not (Test-FilesEqual $_.FullName $destinationPath)

            if (-not $isDifferent) {
                $identical++
                Write-Host "[SAME] $($_.Name)"
                return
            }

            $copied++
            if ($DryRun) {
                Write-Host "[DRY RUN][COPY] $($_.Name)"
                return
            }

            if (-not (Test-Path -LiteralPath $destinationDirectory)) {
                New-Item -ItemType Directory -Path $destinationDirectory | Out-Null
            }

            Copy-Item -LiteralPath $_.FullName -Destination $destinationPath -Force
            Write-Host "[COPY] $($_.Name)"
        }

    return [pscustomobject]@{
        Scanned = $scanned
        Copied = $copied
        Identical = $identical
        MissingSource = 0
    }
}

$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
$Kcd2ModRoot = [System.IO.Path]::GetFullPath($Kcd2ModRoot)

if (-not (Test-Path -LiteralPath $RepoRoot -PathType Container)) {
    throw "SimpleBedRoll repo root does not exist: $RepoRoot"
}

if (-not (Test-Path -LiteralPath $Kcd2ModRoot -PathType Container)) {
    throw "KCD2Mod root does not exist: $Kcd2ModRoot"
}

Write-Header

$totalScanned = 0
$totalCopied = 0
$totalIdentical = 0
$missingSources = 0

foreach ($mapping in $Mappings) {
    $result = Copy-Mapping $mapping
    $totalScanned += $result.Scanned
    $totalCopied += $result.Copied
    $totalIdentical += $result.Identical
    $missingSources += $result.MissingSource
}

Write-Host ""
Write-Host "Summary"
Write-Host "-------"
if ($DryRun) {
    Write-Host ("Would copy:        {0}" -f $totalCopied)
}
else {
    Write-Host ("Copied:            {0}" -f $totalCopied)
}
Write-Host ("Identical:         {0}" -f $totalIdentical)
Write-Host ("Missing sources:   {0}" -f $missingSources)
Write-Host ("Errors:            0")

if ($totalCopied -eq 0) {
    Write-Host ""
    Write-Host "No files need syncing."
}
