param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Kcd2ModRoot = "F:\SteamLibrary\steamapps\common\KCD2Mod",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$PrefabRules = @{
    "SBRCandleFullLitv1.xml" = @{
        AnchorClass = "SimpleBedRoll_VisualAnchor"
        ObjectOrder = @(
            "SimpleBedRoll_VisualAnchor",
            "Light",
            "ParticleEffect"
        )
    }
    "SBRCandleFullLitv2.xml" = @{
        AnchorClass = "SimpleBedRoll_VisualAnchor"
        ObjectOrder = @(
            "SimpleBedRoll_VisualAnchor",
            "Light",
            "ParticleEffect"
        )
    }
}

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

function Test-ContentEqualsFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $DestinationPath -PathType Leaf)) {
        return $false
    }

    $destinationContent = [System.IO.File]::ReadAllText($DestinationPath)
    return $Content -eq $destinationContent
}

function ConvertTo-InvariantDouble {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return [double]::Parse(
        $Value.Trim(),
        [System.Globalization.CultureInfo]::InvariantCulture
    )
}

function ConvertTo-InvariantText {
    param(
        [Parameter(Mandatory = $true)]
        [double]$Value
    )

    if ([math]::Abs($Value) -lt 0.0000000001) {
        return "0"
    }

    return $Value.ToString(
        "0.#########",
        [System.Globalization.CultureInfo]::InvariantCulture
    )
}

function Read-PrefabPosition {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PositionText
    )

    $parts = $PositionText.Split(",")
    if ($parts.Count -ne 3) {
        throw "expected three comma-separated position values"
    }

    return [pscustomobject]@{
        X = ConvertTo-InvariantDouble $parts[0]
        Y = ConvertTo-InvariantDouble $parts[1]
        Z = ConvertTo-InvariantDouble $parts[2]
    }
}

function Format-PrefabPosition {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Position
    )

    return (
        (ConvertTo-InvariantText $Position.X),
        (ConvertTo-InvariantText $Position.Y),
        (ConvertTo-InvariantText $Position.Z)
    ) -join ","
}

function Get-ObjectStartTags {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    return [regex]::Matches(
        $Content,
        '<Object\b[^>]*>',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
}

function Get-EntityClassLabel {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Tag
    )

    $entityClass = Get-AttributeValue $Tag "EntityClass"
    if ($entityClass -ne $null -and $entityClass -ne "") {
        return $entityClass
    }

    $type = Get-AttributeValue $Tag "Type"
    if ($type -ne $null -and $type -ne "") {
        return "(none; Type=$type)"
    }

    return "(none)"
}

function Get-PrefabObjectsSection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $match = [regex]::Match(
        $Content,
        '(?s)(?<prefix><Objects>\s*)(?<body>.*?)(?<suffix>\s*</Objects>)'
    )

    if (-not $match.Success) {
        throw "could not find <Objects> section"
    }

    return [pscustomobject]@{
        Match = $match
        Prefix = $match.Groups["prefix"].Value
        Body = $match.Groups["body"].Value
        Suffix = $match.Groups["suffix"].Value
    }
}

function Get-TopLevelObjectBlocks {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ObjectsBody
    )

    $matches = [regex]::Matches(
        $ObjectsBody,
        '(?s)(?<text>\s*<Object\b[^>]*(?:/>|>.*?</Object>))'
    )

    $covered = $ObjectsBody
    $blocks = @()

    foreach ($match in $matches) {
        $text = $match.Groups["text"].Value
        $covered = [regex]::Replace($covered, [regex]::Escape($text), "", 1)
        $startTag = [regex]::Match(
            $text,
            '<Object\b[^>]*>',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        ).Value

        $blocks += [pscustomobject]@{
            Text = $text
            StartTag = $startTag
            EntityClass = Get-AttributeValue $startTag "EntityClass"
            Name = Get-AttributeValue $startTag "Name"
            Type = Get-AttributeValue $startTag "Type"
        }
    }

    if ($covered.Trim() -ne "") {
        throw "unexpected non-object XML in <Objects> section"
    }

    return $blocks
}

function Format-OrderList {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Order
    )

    return ($Order | ForEach-Object { "  " + $_ }) -join [Environment]::NewLine
}

function Get-AttributeValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Tag,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $match = [regex]::Match(
        $Tag,
        '\b' + [regex]::Escape($Name) + '="([^"]*)"',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    if ($match.Success) {
        return $match.Groups[1].Value
    }

    return $null
}

function Remove-PosAttributeValues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    return [regex]::Replace(
        $Content,
        '(<Object\b[^>]*?\bPos=")[^"]*(")',
        '$1__POS__$2',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
}

function Test-NormalizedPrefab {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OriginalContent,
        [Parameter(Mandatory = $true)]
        [string]$NormalizedContent,
        [Parameter(Mandatory = $true)]
        [pscustomobject]$AnchorOffset,
        [Parameter(Mandatory = $true)]
        [string]$AnchorEntityClass
    )

    $beforeTags = Get-ObjectStartTags $OriginalContent
    $afterTags = Get-ObjectStartTags $NormalizedContent

    if ($beforeTags.Count -ne $afterTags.Count) {
        return "object count changed before=$($beforeTags.Count) after=$($afterTags.Count)"
    }

    if ((Remove-PosAttributeValues $OriginalContent) -ne
        (Remove-PosAttributeValues $NormalizedContent)) {
        return "non-Pos XML content changed"
    }

    $beforePositions = @()
    $afterPositions = @()
    $anchorAfter = $null

    for ($i = 0; $i -lt $beforeTags.Count; $i++) {
        $beforeTag = $beforeTags[$i].Value
        $afterTag = $afterTags[$i].Value

        foreach ($attribute in @("Id", "Name", "EntityClass", "Parent", "DebugParentName", "Rotate", "Scale")) {
            if ((Get-AttributeValue $beforeTag $attribute) -ne
                (Get-AttributeValue $afterTag $attribute)) {
                return "$attribute changed at object index $i"
            }
        }

        $beforePosText = Get-AttributeValue $beforeTag "Pos"
        $afterPosText = Get-AttributeValue $afterTag "Pos"

        if (($beforePosText -eq $null) -ne ($afterPosText -eq $null)) {
            return "Pos presence changed at object index $i"
        }

        if ($beforePosText -ne $null) {
            $beforePosition = Read-PrefabPosition $beforePosText
            $afterPosition = Read-PrefabPosition $afterPosText
            $beforePositions += $beforePosition
            $afterPositions += $afterPosition

            if ((Get-AttributeValue $afterTag "EntityClass") -eq $AnchorEntityClass) {
                $anchorAfter = $afterPosition
            }
        }
    }

    if (-not $anchorAfter) {
        return "normalized anchor not found"
    }

    $tolerance = 0.000001
    if (([math]::Abs($anchorAfter.X) -gt $tolerance) -or
        ([math]::Abs($anchorAfter.Y) -gt $tolerance) -or
        ([math]::Abs($anchorAfter.Z) -gt $tolerance)) {
        return "anchor result was not 0,0,0"
    }

    for ($i = 0; $i -lt $beforePositions.Count; $i++) {
        $relativeBefore = @{
            X = $beforePositions[$i].X - $AnchorOffset.X
            Y = $beforePositions[$i].Y - $AnchorOffset.Y
            Z = $beforePositions[$i].Z - $AnchorOffset.Z
        }
        $relativeAfter = $afterPositions[$i]

        if (([math]::Abs($relativeBefore.X - $relativeAfter.X) -gt $tolerance) -or
            ([math]::Abs($relativeBefore.Y - $relativeAfter.Y) -gt $tolerance) -or
            ([math]::Abs($relativeBefore.Z - $relativeAfter.Z) -gt $tolerance)) {
            return "relative offset changed at positioned object index $i"
        }
    }

    return $null
}

function Get-NormalizedPrefabContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [hashtable]$Rule
    )

    $content = [System.IO.File]::ReadAllText($SourcePath)
    $anchorClass = [string]$Rule.AnchorClass
    $objectTags = Get-ObjectStartTags $content
    $anchorTags = @()

    foreach ($tag in $objectTags) {
        if ((Get-AttributeValue $tag.Value "EntityClass") -eq $anchorClass) {
            $anchorTags += $tag
        }
    }

    if ($anchorTags.Count -ne 1) {
        return [pscustomobject]@{
            Ok = $false
            Error = "expected exactly one $anchorClass object, found $($anchorTags.Count)"
            Content = $content
        }
    }

    $anchorName = Get-AttributeValue $anchorTags[0].Value "Name"
    $anchorPosText = Get-AttributeValue $anchorTags[0].Value "Pos"

    if ($anchorPosText -eq $null) {
        return [pscustomobject]@{
            Ok = $false
            Error = "anchor has no Pos attribute"
            Content = $content
        }
    }

    try {
        $anchorOffset = Read-PrefabPosition $anchorPosText
        $script:__sbrAdjustedPrefabPositions = 0
        $script:__sbrNormalizedPrefabPositions = @()
        $adjusted = 0
        $normalized = [regex]::Replace(
            $content,
            '(<Object\b[^>]*?\bPos=")([^"]*)(")',
            {
                param($match)

                $position = Read-PrefabPosition $match.Groups[2].Value
                $startPrefix = $match.Groups[1].Value
                $newPosition = [pscustomobject]@{
                    X = $position.X - $anchorOffset.X
                    Y = $position.Y - $anchorOffset.Y
                    Z = $position.Z - $anchorOffset.Z
                }
                $script:__sbrNormalizedPrefabPositions += [pscustomobject]@{
                    Name = Get-AttributeValue $startPrefix "Name"
                    EntityClass = Get-AttributeValue $startPrefix "EntityClass"
                    Before = Format-PrefabPosition $position
                    After = Format-PrefabPosition $newPosition
                }
                $script:__sbrAdjustedPrefabPositions++
                return $match.Groups[1].Value +
                    (Format-PrefabPosition $newPosition) +
                    $match.Groups[3].Value
            },
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
        $adjusted = $script:__sbrAdjustedPrefabPositions
        $positions = $script:__sbrNormalizedPrefabPositions
        $script:__sbrAdjustedPrefabPositions = 0
        $script:__sbrNormalizedPrefabPositions = @()
    }
    catch {
        $script:__sbrAdjustedPrefabPositions = 0
        $script:__sbrNormalizedPrefabPositions = @()
        return [pscustomobject]@{
            Ok = $false
            Error = "could not parse Pos safely: $($_.Exception.Message)"
            Content = $content
        }
    }

    $validationError = Test-NormalizedPrefab `
        $content `
        $normalized `
        $anchorOffset `
        $anchorClass

    if ($validationError) {
        return [pscustomobject]@{
            Ok = $false
            Error = "validation failed: $validationError"
            Content = $content
        }
    }

    return [pscustomobject]@{
        Ok = $true
        Content = $normalized
        Changed = $content -ne $normalized
        AnchorName = $anchorName
        Offset = Format-PrefabPosition $anchorOffset
        Adjusted = $adjusted
        Positions = $positions
    }
}

function Set-PrefabObjectOrder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [hashtable]$Rule
    )

    try {
        $section = Get-PrefabObjectsSection $Content
        $blocks = Get-TopLevelObjectBlocks $section.Body
    }
    catch {
        return [pscustomobject]@{
            Ok = $false
            Error = $_.Exception.Message
        }
    }

    $requiredOrder = @($Rule.ObjectOrder)
    $sourceOrder = @()
    $byClass = @{}
    $unexpected = @()

    foreach ($block in $blocks) {
        $className = $block.EntityClass
        if ($className -eq $null -or $className -eq "") {
            $unexpected += "EntityClass=(none) Name=$($block.Name) Type=$($block.Type)"
            continue
        }

        $sourceOrder += $className

        if ($requiredOrder -notcontains $className) {
            $unexpected += "EntityClass=$className Name=$($block.Name)"
            continue
        }

        if (-not $byClass.ContainsKey($className)) {
            $byClass[$className] = @()
        }
        $byClass[$className] += $block
    }

    if ($unexpected.Count -gt 0) {
        return [pscustomobject]@{
            Ok = $false
            Error = "Unexpected top-level object: " + ($unexpected -join "; ")
            SourceOrder = $sourceOrder
            RuntimeOrder = $requiredOrder
        }
    }

    foreach ($className in $requiredOrder) {
        $count = 0
        if ($byClass.ContainsKey($className)) {
            $count = $byClass[$className].Count
        }

        if ($count -ne 1) {
            return [pscustomobject]@{
                Ok = $false
                Error = "Expected exactly one top-level $className object, found $count"
                SourceOrder = $sourceOrder
                RuntimeOrder = $requiredOrder
            }
        }
    }

    if ($blocks.Count -ne $requiredOrder.Count) {
        return [pscustomobject]@{
            Ok = $false
            Error = "Unexpected top-level object count: found $($blocks.Count), expected $($requiredOrder.Count)"
            SourceOrder = $sourceOrder
            RuntimeOrder = $requiredOrder
        }
    }

    $orderedBlocks = @()
    foreach ($className in $requiredOrder) {
        $orderedBlocks += $byClass[$className][0].Text
    }

    $newBody = $orderedBlocks -join ""
    $newContent =
        $Content.Substring(0, $section.Match.Index) +
        $section.Prefix +
        $newBody +
        $section.Suffix +
        $Content.Substring($section.Match.Index + $section.Match.Length)

    return [pscustomobject]@{
        Ok = $true
        Content = $newContent
        Changed = $Content -ne $newContent
        SourceOrder = $sourceOrder
        RuntimeOrder = $requiredOrder
    }
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

function Write-PrefabRuleDiagnostics {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,
        [AllowNull()]
        [hashtable]$Rule,
        [Parameter(Mandatory = $true)]
        [string]$WriteMode
    )

    Write-Host "[PREFAB RULE] $FileName"
    Write-Host "Source: $SourcePath"
    Write-Host "Destination: $DestinationPath"
    if ($Rule) {
        Write-Host "Rule matched: yes"
        Write-Host "Anchor class: $($Rule.AnchorClass)"
        Write-Host "Normalize: yes"
        Write-Host "Reorder: yes"
    }
    else {
        Write-Host "Rule matched: no"
    }
    Write-Host "Write mode: $WriteMode"
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
            Normalized = 0
            Errors = 0
        }
    }

    Write-Host ""
    Write-Host "=== $($Mapping.Heading) ==="

    $scanned = 0
    $proposed = 0
    $copied = 0
    $identical = 0
    $rejected = 0
    $normalizedCount = 0
    $errors = 0

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

            $candidateContent = $null
            $normalization = $null
            $ordering = $null
            $prefabRule = $null

            if ($Mapping.AllowSimpleBedRollPrefabNames) {
                $prefabRule = $PrefabRules[$_.Name]
                if ($prefabRule) {
                    $normalization = Get-NormalizedPrefabContent `
                        $_.FullName `
                        $prefabRule

                    if (-not $normalization.Ok) {
                        $errors++
                        Write-Host "[ERROR][NORMALIZE] $relativePath - $($normalization.Error)"
                        Write-Host "Destination left unchanged."
                        return
                    }

                    $ordering = Set-PrefabObjectOrder `
                        $normalization.Content `
                        $prefabRule

                    if (-not $ordering.Ok) {
                        $errors++
                        Write-Host "[ERROR][ORDER] $relativePath"
                        Write-Host $ordering.Error
                        if ($ordering.SourceOrder) {
                            Write-Host "Source order:"
                            Write-Host (Format-OrderList $ordering.SourceOrder)
                        }
                        Write-Host "Runtime order:"
                        Write-Host (Format-OrderList @($prefabRule.ObjectOrder))
                        Write-Host "Destination left unchanged."
                        return
                    }

                    $candidateContent = $ordering.Content
                }

                $writeMode = if ($candidateContent -ne $null) { "transformed" } else { "raw" }
                Write-PrefabRuleDiagnostics `
                    $_.Name `
                    $_.FullName `
                    $destinationPath `
                    $prefabRule `
                    $writeMode
            }

            if ($candidateContent -ne $null) {
                $isDifferent = -not (Test-ContentEqualsFile $candidateContent $destinationPath)
            }
            else {
                $isDifferent = -not (Test-FilesEqual $_.FullName $destinationPath)
            }

            if (-not $isDifferent) {
                $identical++
                Write-Host "[SAME] $relativePath"
                return
            }

            $proposed++
            $destinationExists = Test-Path -LiteralPath $destinationPath -PathType Leaf
            $action = if ($destinationExists) { "OVERWRITE" } else { "COPY" }

            if ($normalization) {
                if ($DryRun) {
                    Write-Host "[DRY RUN][PREFAB] $relativePath"
                }
                else {
                    Write-Host "[PREFAB] $relativePath"
                }
                Write-Host "Anchor: $($normalization.AnchorName)"
                Write-Host "Origin offset: $($normalization.Offset)"
                Write-Host "Positioned objects adjusted: $($normalization.Adjusted)"
                Write-Host "Normalization validation: ok"
                Write-Host "Normalized positions:"
                foreach ($position in $normalization.Positions) {
                    $label = $position.EntityClass
                    if ($label -eq $null -or $label -eq "") {
                        $label = $position.Name
                    }
                    Write-Host (
                        "  {0}: {1} -> {2}" -f
                        $label,
                        $position.Before,
                        $position.After
                    )
                }
                Write-Host ""
                Write-Host "Source order:"
                Write-Host (Format-OrderList $ordering.SourceOrder)
                Write-Host ""
                Write-Host "Runtime order:"
                Write-Host (Format-OrderList $ordering.RuntimeOrder)
                Write-Host ""
                Write-Host "Order validation: ok"
            }

            if ($normalization -and $normalization.Changed) {
                $normalizedCount++
            }

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

            if ($candidateContent -ne $null) {
                [System.IO.File]::WriteAllText(
                    $destinationPath,
                    $candidateContent,
                    [System.Text.Encoding]::ASCII
                )
            }
            else {
                Copy-Item -LiteralPath $_.FullName -Destination $destinationPath -Force
            }
            $copied++
        }

    return [pscustomobject]@{
        Scanned = $scanned
        Proposed = $proposed
        Copied = $copied
        Identical = $identical
        Rejected = $rejected
        MissingSource = 0
        Normalized = $normalizedCount
        Errors = $errors
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
$totalNormalized = 0
$totalErrors = 0

foreach ($mapping in $Mappings) {
    $result = Copy-Mapping $mapping
    $totalScanned += $result.Scanned
    $totalProposed += $result.Proposed
    $totalCopied += $result.Copied
    $totalIdentical += $result.Identical
    $totalRejected += $result.Rejected
    $missingSources += $result.MissingSource
    $totalNormalized += $result.Normalized
    $totalErrors += $result.Errors
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
if ($DryRun) {
    Write-Host ("Would normalize:   {0}" -f $totalNormalized)
}
else {
    Write-Host ("Normalized:        {0}" -f $totalNormalized)
}
Write-Host ("Errors:            {0}" -f $totalErrors)

if ($totalProposed -eq 0) {
    Write-Host ""
    Write-Host "No files need syncing."
}
