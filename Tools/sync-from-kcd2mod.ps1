param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Kcd2ModRoot = "F:\SteamLibrary\steamapps\common\KCD2Mod",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$Mappings = @(
    @{
        Name = "SimpleBedRoll prefabs"
        Heading = "PREFABS"
        Source = "Data\Prefabs"
        Destination = "Data\Prefabs\simplebedroll"
        Filter = "*.xml"
        AllowAllUnderSource = $false
        AllowSimpleBedRollPrefabNames = $true
        DestinationFileNameOnly = $true
    },
    @{
        Name = "Entities"
        Heading = "ENTITIES"
        Source = "Data\Entities"
        Destination = "Data\Entities"
        Filter = "*.ent"
        AllowAllUnderSource = $false
    },
    @{
        Name = "Entity scripts"
        Heading = "ENTITY SCRIPTS"
        Source = "Data\Scripts\Entities"
        Destination = "Data\Scripts\Entities"
        Filter = "*.lua"
        AllowAllUnderSource = $false
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

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        [Parameter(Mandatory = $true)]
        [string]$FullPath
    )

    $baseUri = [System.Uri]::new(([System.IO.Path]::GetFullPath($BasePath).TrimEnd('\') + '\'))
    $fullUri = [System.Uri]::new([System.IO.Path]::GetFullPath($FullPath))

    return [System.Uri]::UnescapeDataString(
        $baseUri.MakeRelativeUri($fullUri).ToString()
    ) -replace '/', '\'
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

function Test-OwnedFile {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Mapping,
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    if ($Mapping.AllowAllUnderSource) {
        return [pscustomobject]@{
            Allowed = $true
            Reason = "owned-prefab-folder"
        }
    }

    if (Test-Path -LiteralPath $DestinationPath -PathType Leaf) {
        return [pscustomobject]@{
            Allowed = $true
            Reason = "repo-file-exists"
        }
    }

    $fileName = [System.IO.Path]::GetFileName($DestinationPath)

    if ($Mapping.AllowSimpleBedRollPrefabNames) {
        if (($RelativePath -like "simplebedroll\*") -or
            ($fileName -like "SimpleBedRoll_*.xml") -or
            ($fileName -like "simplebedroll*.xml") -or
            ($fileName -like "sbr_*.xml") -or
            ($fileName -like "lit_candle_*.xml")) {
            return [pscustomobject]@{
                Allowed = $true
                Reason = "simplebedroll-prefab-name"
            }
        }
    }

    if ($fileName -like "SimpleBedRoll_*") {
        return [pscustomobject]@{
            Allowed = $true
            Reason = "simplebedroll-prefix"
        }
    }

    return [pscustomobject]@{
        Allowed = $false
        Reason = "not-owned"
    }
}

function Write-Header {
    Write-Host "SimpleBedRoll Authoring Sync"
    Write-Host "Direction: KCD2Mod -> repo"
    if ($DryRun) {
        Write-Host "Mode: DRY RUN"
    }
    else {
        Write-Host "Mode: COPY"
    }
    Write-Host "Source: $Kcd2ModRoot"
    Write-Host "Destination: $RepoRoot"
}

function Copy-Mapping {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Mapping
    )

    $sourceRoot = Resolve-FullPath $Kcd2ModRoot $Mapping.Source
    $destinationRoot = Resolve-FullPath $RepoRoot $Mapping.Destination

    if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
        Write-Host ""
        Write-Host "=== $($Mapping.Heading) ==="
        Write-Host "[SKIP:missing-source] $($Mapping.Source)"
        return [pscustomobject]@{
            Scanned = 0
            Proposed = 0
            Copied = 0
            Identical = 0
            Rejected = 0
            MissingSource = 1
        }
    }

    Write-Host ""
    Write-Host "=== $($Mapping.Heading) ==="

    $scanned = 0
    $proposed = 0
    $copied = 0
    $identical = 0
    $rejected = 0

    Get-ChildItem -LiteralPath $sourceRoot -File -Filter $Mapping.Filter -Recurse |
        Sort-Object FullName |
        ForEach-Object {
            $scanned++
            $relativePath = Get-RelativePath $sourceRoot $_.FullName
            if ($Mapping.DestinationFileNameOnly) {
                $destinationPath = Join-Path $destinationRoot $_.Name
            }
            else {
                $destinationPath = Join-Path $destinationRoot $relativePath
            }
            $ownership = Test-OwnedFile $Mapping $destinationPath $relativePath

            if (-not $ownership.Allowed) {
                $rejected++
                Write-Host "[SKIP:not-owned] $relativePath"
                return
            }

            $isDifferent = -not (Test-FilesEqual $_.FullName $destinationPath)

            if (-not $isDifferent) {
                $identical++
                Write-Host "[SAME] $relativePath"
                return
            }

            $proposed++
            $destinationExists = Test-Path -LiteralPath $destinationPath -PathType Leaf
            $action = if ($destinationExists) { "OVERWRITE" } else { "COPY" }

            if ($DryRun) {
                Write-Host "[DRY RUN][$action] $relativePath"
            }
            else {
                Write-Host "[$action] $relativePath"
            }

            if ($DryRun) {
                return
            }

            $destinationDirectory = Split-Path -Parent $destinationPath
            if (-not (Test-Path -LiteralPath $destinationDirectory)) {
                New-Item -ItemType Directory -Path $destinationDirectory | Out-Null
            }

            Copy-Item -LiteralPath $_.FullName -Destination $destinationPath -Force
            $copied++
        }

    return [pscustomobject]@{
        Scanned = $scanned
        Proposed = $proposed
        Copied = $copied
        Identical = $identical
        Rejected = $rejected
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
$totalProposed = 0
$totalCopied = 0
$totalIdentical = 0
$totalRejected = 0
$missingSources = 0

foreach ($mapping in $Mappings) {
    $result = Copy-Mapping $mapping
    $totalScanned += $result.Scanned
    $totalProposed += $result.Proposed
    $totalCopied += $result.Copied
    $totalIdentical += $result.Identical
    $totalRejected += $result.Rejected
    $missingSources += $result.MissingSource
}

Write-Host ""
Write-Host "Summary"
Write-Host "-------"
if ($DryRun) {
    Write-Host ("Would copy:        {0}" -f $totalProposed)
}
else {
    Write-Host ("Copied:            {0}" -f $totalCopied)
}
Write-Host ("Identical:         {0}" -f $totalIdentical)
Write-Host ("Skipped not-owned: {0}" -f $totalRejected)
Write-Host ("Missing sources:   {0}" -f $missingSources)
Write-Host ("Errors:            0")

if ($totalProposed -eq 0) {
    Write-Host ""
    Write-Host "No files need syncing."
}
