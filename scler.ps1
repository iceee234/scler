# scler.ps1 - main processing script for global.ini
# Called from SCLER_*.bat
# v1.13

param(
    $file1,
    $file2,
    $ordnancePath,
    $useColorTags,
    $useRpAwardTag,
    $useSppTag,
    $useUserNotes,
    $colorBlue = '',
    $colorGreen = '',
    $colorYellow = '',
    $colorRed = '',
    $titleFormat = '1',
    $useCargoTitles = '1',
    $useUserDict = '0',
    $customOnly = '0'
)

Write-Host "scler.ps1 v1.13"

$useColorTags = $useColorTags -eq '1'
$useRpAwardTag = $useRpAwardTag -eq '1'
$useSppTag = $useSppTag -eq '1'
$useUserNotes = $useUserNotes -eq '1'
$useCargoTitles = $useCargoTitles -eq '1'
$useUserDict = $useUserDict -eq '1'
$customOnly = $customOnly -eq '1'
$titleFormat = $titleFormat.Trim()

$transTablesFile = Join-Path $PSScriptRoot 'scler_tables.ps1'
$rankKeyTable = @{}
$itemTypeKeyTable = @{}
if (Test-Path $transTablesFile) {
    . $transTablesFile
} else {
    Write-Host "Error: scler_tables.ps1 not found. Please reinstall the program."
    exit 1
}

# Map type codes to English names
$typeCodeToNames = @{}
foreach ($k in $itemTypeKeyTable.Keys) {
    if ($k -match '^item_Name_([A-Z]+)_Default$') {
        $typeCodeToNames[$Matches[1]] = $itemTypeKeyTable[$k]
    }
}
# QRDV = QDRV
$typeCodeToNames['QRDV'] = @('Quantum Drive')

function Get-FileEncoding {
    param($filePath)
    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return [System.Text.Encoding]::UTF8
    }
    return [System.Text.Encoding]::GetEncoding(1251)
}

# Read global.ini
$encoding = Get-FileEncoding $file1
$lines = [System.IO.File]::ReadAllLines($file1, $encoding)
$lineCount = $lines.Count

# Save original lines for backup
$originalLines = $lines.Clone()

# Build translation tables from global.ini
$rankTable = @{}
$itemTypeTable = @{}
foreach ($line in $lines) {
    $p = $line -split '=', 2
    if ($p.Count -eq 2) {
        $key = $p[0].Trim() -replace ',.*$', ''
        $rusValue = $p[1]
        if ($rankKeyTable.ContainsKey($key)) {
            $rankTable[$rankKeyTable[$key]] = $rusValue
        }
        if ($itemTypeKeyTable.ContainsKey($key)) {
            foreach ($engVariant in $itemTypeKeyTable[$key]) {
                $itemTypeTable[$engVariant] = $rusValue
            }
        }
    }
}

# Fallback for missing rank translations
if (-not $rankTable.ContainsKey('Neutral')) {
    $rankTable['Neutral'] = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0J3QtdC50YLRgNCw0LvRjNC90YvQuQ=='))
}

# Additional translations
if ($additionalItemTypes) {
    foreach ($k in $additionalItemTypes.Keys) {
        if (-not $itemTypeTable.ContainsKey($k)) {
            $itemTypeTable[$k] = $additionalItemTypes[$k]
        }
    }
}

# Build module class tables from global.ini
$moduleByShort = @{}
$moduleByFull = @{}

foreach ($line in $lines) {
    $p = $line -split '=', 2
    if ($p.Count -ne 2) { continue }
    $key = $p[0].Trim()
    $value = $p[1]
    
    if ($key -notmatch '^item_Name') { continue }
    if ($key -match '_Default$' -or $key -match '_Controller$') { continue }
    
    if ($key -notmatch '^item_Name_?([A-Z]+)_') { continue }
    $typeCode = $Matches[1]
    if ($typeCode -notin $typeCodeToNames.Keys) { continue }
    $engTypeNames = $typeCodeToNames[$typeCode]
    
    if ($value -match '^(.+?)\s*\(([^)]+)\)') {
        $fullName = $Matches[1].Trim()
        $class = $Matches[2]
        $shortName = ($fullName -split '\s+')[0]
        $info = @{ Class = $class; FullName = $fullName; Key = $key; Value = $value }
        
        foreach ($engType in $engTypeNames) {
            $shortKey = "$shortName|$engType"
            if (-not $moduleByShort.ContainsKey($shortKey)) {
                $moduleByShort[$shortKey] = $info
            }
            $fullKey = "$fullName|$engType"
            if (-not $moduleByFull.ContainsKey($fullKey)) {
                $moduleByFull[$fullKey] = $info
            }
        }
    }
}

# Build weapon size table from global.ini
$moduleTypeCodes = @('COOL', 'POWR', 'QDRV', 'QRDV', 'SHLD', 'COMP', 'RADR', 'HTNK', 'INTK', 'QTNK')
$weaponKeywords = @('Cannon', 'Repeater', 'Gatling', 'Scattergun', 'Mass Driver', 'Beam', 'EMP Generator', 'Neutron')
$weaponSizeTable = @{}
foreach ($line in $lines) {
    $p = $line -split '=', 2
    if ($p.Count -ne 2) { continue }
    $key = $p[0].Trim()
    $value = $p[1]
    if ($key -notmatch '^item_Name') { continue }
    if ($key -notmatch '_S(\d)$') { continue }
    $size = 'S' + $Matches[1]
    if ($key -match '^item_Name_?([A-Z]+)_') {
        $typeCode = $Matches[1]
        if ($typeCode -in $moduleTypeCodes) { continue }
    }
    $isWeapon = $false
    foreach ($kw in $weaponKeywords) {
        if ($value -match $kw) {
            $isWeapon = $true
            break
        }
    }
    if (-not $isWeapon) { continue }
    if (-not $weaponSizeTable.ContainsKey($value)) {
        $weaponSizeTable[$value] = $size
    }
}

$frontendLine = $lines -match '^Frontend_PU_Version(?:,P)?=' | Select-Object -First 1
if (-not $frontendLine -or $frontendLine -notmatch '[а-яё]') {
    Write-Host 'Warning: the provided global.ini does not appear to be a Russian version. Some markers may not be translated correctly.'
}

# Load contracts.ini
$allContracts = @{}
if ($file2 -and (Test-Path $file2)) {
    Get-Content $file2 -Encoding UTF8 | ForEach-Object {
        $p = $_ -split '=', 2
        if ($p.Count -eq 2) { $allContracts[$p[0].Trim()] = $p[1] }
    }
}

$modifiedLineIndices = [System.Collections.Generic.HashSet[int]]::new()

function Translate-AwardedFrom {
    param($text, $rankTable, $locAwardedFrom)
    $pattern = '<EM(\d+)>Awarded from (.+) level variants</EM\1>'
    $m = [regex]::Match($text, $pattern)
    if (-not $m.Success) { return $text }
    $color = $m.Groups[1].Value
    $rank = $m.Groups[2].Value
    $rusRank = $rankTable[$rank]
    if (-not $rusRank) { $rusRank = $rank }
    $replacement = '<EM' + $color + '>' + $locAwardedFrom + ' ' + $rusRank + '</EM' + $color + '>'
    return $text -replace [regex]::Escape($m.Value), $replacement
}

function Translate-RegionalVariants {
    param($text)
    $pattern = '<EM(\d+)>\[Regional Variants\] example locations: ([^<]*)</EM\1>'
    if ($text -notmatch $pattern) { return $text }
    $newText = [regex]::Replace($text, $pattern, {
        param($match)
        $script:regionalVariantsAdded++
        '<EM' + $match.Groups[1].Value + '>' + $locRegionalVariants + ' ' + $match.Groups[2].Value + '</EM' + $match.Groups[1].Value + '>'
    })
    return $newText
}

function Translate-ItemTypes {
    param($text, $itemTypeTable, $moduleByShort, $moduleByFull)
    if ($itemTypeTable.Count -eq 0) { return $text }
    
    $pattern = '- (\S+(?:\s+\S+)*?)\s*\(([^)]+)\)'
    $newText = [regex]::Replace($text, $pattern, {
        param($match)
        $modName = $match.Groups[1].Value.Trim()
        $fullBracket = $match.Groups[2].Value.Trim()
        
        $foundType = $null
        foreach ($engType in $itemTypeTable.Keys) {
            if ($fullBracket -match [regex]::Escape($engType)) {
                $foundType = $engType
                break
            }
        }
        if (-not $foundType) { return $match.Value }
        
        $rusType = $itemTypeTable[$foundType]
        if (-not $rusType) { return $match.Value }
        
        $script:itemTypesAdded++
        
        if ($foundType.Length -le 3) {
            $numberPrefix = ''
            if ($fullBracket -match '^(\d+)\s') { $numberPrefix = $Matches[1] + ' ' }
            return '- ' + $modName + ' (' + $numberPrefix + $rusType + ')'
        }
        
        $numberPrefix = ''
        if ($fullBracket -match '^(\d+)\s') {
            $numberPrefix = $Matches[1] + ' '
        }
        
        $fullKey = "$modName|$foundType"
        $info = $moduleByFull[$fullKey]
        if (-not $info) {
            $localShortName = ($modName -split '\s+')[0]
            $shortKey = "$localShortName|$foundType"
            $info = $moduleByShort[$shortKey]
        }
        
        if ($info) {
            $script:moduleClassesAdded++
            return '- ' + $modName + ' (' + $numberPrefix + $rusType + ' ' + $info.Class + ')'
        }
        return '- ' + $modName + ' (' + $numberPrefix + $rusType + ')'
    })
    return $newText
}

# --------------------------------------------------
# Stage 1: Ordnance
# --------------------------------------------------
if (-not $customOnly) {
$ordnanceReplaced = 0
if (Test-Path $ordnancePath) {
    $ordnance = @{}
    Get-Content $ordnancePath -Encoding UTF8 | ForEach-Object {
        $p = $_ -split '=', 2
        if ($p.Count -eq 2) { $ordnance[$p[0].Trim()] = $p[1] }
    }
    if ($ordnance.Count -gt 0) {
        $lineIndex = @{}
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $p = $lines[$i] -split '=', 2
            if ($p.Count -eq 2) {
                $k = $p[0].Trim()
                if (-not $lineIndex.ContainsKey($k)) { $lineIndex[$k] = $i }
            }
        }
        $ordMissing = @()
        foreach ($k in $ordnance.Keys) {
            if ($lineIndex.ContainsKey($k)) {
                $i = $lineIndex[$k]
                $p = $lines[$i] -split '=', 2
                $newValue = $ordnance[$k]
                if ($newValue -ne $p[1]) {
                    $lines[$i] = $k + '=' + $newValue
                    $ordnanceReplaced++
                    $null = $modifiedLineIndices.Add($i)
                }
            } else {
                $ordMissing += $k
            }
        }
        if ($ordMissing.Count -gt 0) {
            Write-Host "Warning: $($ordMissing.Count) ordnance keys not found in global.ini. The localization file may be outdated."
        }
    }
}
}

# --------------------------------------------------
# Stage 2: Color tags
# --------------------------------------------------
if (-not $customOnly) {
$colorTagsAdded = 0
if ($useColorTags) {
    $commodityIndices = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $key = ($lines[$i] -split '=', 2)[0].Trim()
        if ($key -match '^items_commodities_' -and $key -notlike '*_desc' -and $key -notlike '*_des') {
            $commodityIndices += $i
        }
    }
    if ($commodityIndices.Count -gt 0) {
        $colorMap = @{ '1' = $colorBlue; '2' = $colorGreen; '3' = $colorYellow; '4' = $colorRed }
        foreach ($color in $colorMap.Keys) {
            $wordList = $colorMap[$color]
            if (-not $wordList) { continue }
            $words = $wordList -split ';' | Where-Object { $_ -ne '' } | ForEach-Object { $_.Trim() }
            foreach ($i in $commodityIndices) {
                $line = $lines[$i]
                $p = $line -split '=', 2
                $value = $p[1]
                $value = $value -replace '^</?EM\d+>', ''
                $modified = $false
                foreach ($word in $words) {
                    if ($value.Contains("($word)")) {
                        $value = $value.Replace("($word)", "(<EM${color}>${word}</EM${color}>)")
                        $modified = $true
                    }
                }
                if ($modified) {
                    $lines[$i] = $p[0].Trim() + '=' + $value
                    $colorTagsAdded++
                    $null = $modifiedLineIndices.Add($i)
                }
            }
        }
    }
}
}

$bpPattern = '<EM(\d+)>([^<]*)\[BP\](\*?)([^<]*)</EM\1>'
$potentialPattern = '<EM(\d)>Potential Blueprints(?:\s*\(([^)]*)\))?\s*</EM\1>'
$mbpPattern = '<EM(\d)>Multiple Blueprint Pools(?:\s*\(([^)]*)\))?\s*</EM\1>'
$rpPatternBasic = '<EM(\d)>Reputation Awarded:\s*</EM\1>\s*([\d, /]+)'
$rpPatternDifficulty = '<EM(\d)>Reputation Awarded \(by difficulty\):\s*</EM\1>\s*([\d, /]+)'
$sppPattern = '<EM(\d)>Scenario Progress Points\s*([\d,]+)\s*(?:\(Split\))?\s*(?:\s*\|\s*Scenario Progress Points\s*([\d,]+)\s*)*</EM\1>'

$stage3Dict = @{}
$stage4Dict = @{}
$stage5Dict = @{}
$stageRPDict = @{}
$stageSPPDict = @{}

foreach ($k in $allContracts.Keys) {
    $v = $allContracts[$k]
    if ($v -match $bpPattern) {
        $stage3Dict[$k] = @{ Color = $Matches[1]; Type = if ($Matches[3] -eq '*') { 'star' } else { 'plain' } }
    }
    if ($v -match $potentialPattern) {
        $stage4Dict[$k] = @{ Color = $Matches[1]; SuffixRaw = if ($Matches[2]) { $Matches[2] } else { '' }; OrigValue = $v }
    }
    if ($v -match $mbpPattern) {
        $stage5Dict[$k] = @{ Color = $Matches[1]; SuffixRaw = if ($Matches[2]) { $Matches[2] } else { '' }; OrigValue = $v }
    }
    if ($v -match $rpPatternBasic) {
        $stageRPDict[$k] = @{ Color = $Matches[1]; Type = 'basic'; Numbers = ($Matches[2].Trim() -replace ',', ' '); OrigValue = $v }
    }
    if ($v -match $rpPatternDifficulty) {
        $stageRPDict[$k] = @{ Color = $Matches[1]; Type = 'difficulty'; Numbers = ($Matches[2].Trim() -replace ',', ' '); OrigValue = $v }
    }
    if ($v -match $sppPattern) {
        $points = $Matches[2]
        if ($Matches[3]) { $points += ' | ' + $Matches[3] }
        if ($v -match '\(Split\)') { $points += ' (Split)' }
        $stageSPPDict[$k] = @{ Color = $Matches[1]; Points = $points; OrigValue = $v }
    }
}

$allProcessedKeys = @{}
foreach ($k in $stage3Dict.Keys) { $allProcessedKeys[$k] = $true }
foreach ($k in $stage4Dict.Keys) { $allProcessedKeys[$k] = $true }
foreach ($k in $stage5Dict.Keys) { $allProcessedKeys[$k] = $true }
foreach ($k in $stageRPDict.Keys) { $allProcessedKeys[$k] = $true }
foreach ($k in $stageSPPDict.Keys) { $allProcessedKeys[$k] = $true }

# --------------------------------------------------
# Stage 3: BP markers
# --------------------------------------------------
if (-not $customOnly) {
$bpChanged = 0
$missingBp = @()
$rusBpPattern = '<EM(\d+)>([^<]*)\[' + [regex]::Escape($locBP) + '\](\*?)([^<]*)</EM\1>'
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $p = $line -split '=', 2
    if ($p.Count -ne 2) { continue }
    $key = $p[0].Trim() -replace ',.*$', ''
    if (-not $stage3Dict.ContainsKey($key)) { continue }
    $value = $p[1]
    $entry = $stage3Dict[$key]
    if ($value -match $rusBpPattern) { $null = $stage3Dict.Remove($key); continue }
    $emMatch = [regex]::Match($value, '<EM(\d+)>([^<]*)\[BP\](\*?)([^<]*)</EM\1>')
    $star = if ($entry.Type -eq 'star') { '*' } else { '' }
    $replaceWith = '<EM' + $entry.Color + '>[' + $locBP + ']' + $star + '</EM' + $entry.Color + '>'
    if ($emMatch.Success) {
        $newValue = $value -replace [regex]::Escape($emMatch.Value), $replaceWith
    } else {
        $trimmed = $value -replace '\\n$', ''
        $newValue = $trimmed + '\n ' + $replaceWith
    }
    if ($newValue -ne $value) {
        $lines[$i] = $p[0].Trim() + '=' + $newValue
        $bpChanged++
        $null = $modifiedLineIndices.Add($i)
    }
    $null = $stage3Dict.Remove($key)
}
$missingBp = $stage3Dict.Keys
}

# --------------------------------------------------
# Stage 4: Description processing (PB, MBP, RP, SPP)
# --------------------------------------------------
if (-not $customOnly) {
$blueprintsAdded = 0
$blueprintsRepeatOnly = 0
$mbpAdded = 0
$rpAwardedAdded = 0
$sppAdded = 0
$regionalVariantsAdded = 0
$itemTypesAdded = 0
$moduleClassesAdded = 0

$rusPotentialMarker = '<EM\d>' + [regex]::Escape($locPotential)
$rusMbpMarker = [regex]::Escape($locMbp)
$rusRpBasicMarker = [regex]::Escape($locRpBasic)
$rusRpDiffMarker = [regex]::Escape($locRpDiff)
$rusSppMarker = [regex]::Escape($locSpp)

# Save processed keys for Stage 5
$stage4ProcessedKeys = @{}
foreach ($k in $stage4Dict.Keys) { $stage4ProcessedKeys[$k] = $true }
$stage5ProcessedKeys = @{}
foreach ($k in $stage5Dict.Keys) { $stage5ProcessedKeys[$k] = $true }

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $p = $line -split '=', 2
    if ($p.Count -ne 2) { continue }
    $origKey = $p[0].Trim()
    $key = $origKey -replace ',.*$', ''
    $value = $p[1]
    $newValue = $value
    $modified = $false

    # --- PB ---
    if ($stage4Dict.ContainsKey($key)) {
        $entry = $stage4Dict[$key]
        if ($newValue -notmatch $rusPotentialMarker) {
            $rusSuffix = ''
            if ($entry.SuffixRaw) {
                if ($entry.SuffixRaw -eq 'Only') { $rusSuffix = ' (' + $locOnly + ')' }
                elseif ($entry.SuffixRaw -eq 'Repeat Only') { $rusSuffix = ' (' + $locRepeatOnly + ')'; $blueprintsRepeatOnly++ }
                else { $rusSuffix = ' (' + $locOnly + ' ' + $entry.SuffixRaw + ')' }
            }
            $rusMarker = '<EM' + $entry.Color + '>' + $locPotential + $rusSuffix + '</EM' + $entry.Color + '>'
            $m = [regex]::Match($entry.OrigValue, $potentialPattern)
            $trailer = if ($m.Success) { $entry.OrigValue.Substring($m.Index) } else { $entry.OrigValue }
            $rusBlock = $trailer -replace $potentialPattern, $rusMarker
            $rusBlock = Translate-AwardedFrom $rusBlock $rankTable $locAwardedFrom
            $rusBlock = Translate-RegionalVariants $rusBlock
            if ($itemTypeTable.Count -gt 0) { 
                $rusLines = $rusBlock -split '\\n'
                $rusLines = $rusLines | ForEach-Object { Translate-ItemTypes $_ $itemTypeTable $moduleByShort $moduleByFull }
                $rusBlock = $rusLines -join '\n'
            }
            $engPbPattern = '<EM\d+>Potential Blueprints.*$'
            if ($newValue -match $engPbPattern) {
                $newValue = $newValue -replace $engPbPattern, $rusBlock
            } else {
                $newValue = $newValue + '\n\n' + $rusBlock
            }
            $blueprintsAdded++
            $modified = $true
        }
        $null = $stage4Dict.Remove($key)
    }

    # --- MBP ---
    if ($stage5Dict.ContainsKey($key)) {
        $entry = $stage5Dict[$key]
        if ($newValue -notmatch $rusMbpMarker) {
            $rusSuffix = ''
            if ($entry.SuffixRaw) {
                if ($entry.SuffixRaw -eq 'Only') { $rusSuffix = ' (' + $locOnly + ')' }
                else {
                    $cleanSuffix = $entry.SuffixRaw -replace '\s*Only$', ''
                    $rusSuffix = ' (' + $locOnly + ' ' + $cleanSuffix + ')'
                }
            }
            $rusMarker = '<EM' + $entry.Color + '>' + $locMbp + $rusSuffix + '</EM' + $entry.Color + '>'
            $m = [regex]::Match($entry.OrigValue, $mbpPattern)
            $trailer = if ($m.Success) { $entry.OrigValue.Substring($m.Index) } else { $entry.OrigValue }
            $rusBlock = $trailer -replace $mbpPattern, $rusMarker
            $rusBlock = $rusBlock -replace '<EM(\d+)>Pool (\d+)</EM\1>', ('<EM$1>' + $locPool + ' $2</EM$1>')
            $rusBlock = Translate-AwardedFrom $rusBlock $rankTable $locAwardedFrom
            $rusBlock = Translate-RegionalVariants $rusBlock
            if ($itemTypeTable.Count -gt 0) { 
                $rusLines = $rusBlock -split '\\n'
                $rusLines = $rusLines | ForEach-Object { Translate-ItemTypes $_ $itemTypeTable $moduleByShort $moduleByFull }
                $rusBlock = $rusLines -join '\n'
            }
            $engMbpPattern = '<EM\d+>Multiple Blueprint Pools.*$'
            if ($newValue -match $engMbpPattern) {
                $newValue = $newValue -replace $engMbpPattern, $rusBlock
            } else {
                $newValue = $newValue + '\n\n' + $rusBlock
            }
            $mbpAdded++
            $modified = $true
        }
        $null = $stage5Dict.Remove($key)
    }


    # --- RP ---
    if ($useRpAwardTag -and $stageRPDict.ContainsKey($key)) {
        $entry = $stageRPDict[$key]
        if ($newValue -notmatch $rusRpBasicMarker -and $newValue -notmatch $rusRpDiffMarker) {
            $label = if ($entry.Type -eq 'basic') { $locRpBasic } else { $locRpDiff }
            $rusBlock = '<EM' + $entry.Color + '>' + $label + '</EM' + $entry.Color + '> ' + $entry.Numbers
            $engRpPattern = if ($entry.Type -eq 'basic') { '<EM\d+>Reputation Awarded:\s*</EM\d+>\s*[\d, /]+' } else { '<EM\d+>Reputation Awarded \(by difficulty\):\s*</EM\d+>\s*[\d, /]+' }
            if ($newValue -match $engRpPattern) {
                $newValue = $newValue -replace $engRpPattern, $rusBlock
            } else {
                $newValue = $newValue + '\n\n' + $rusBlock
            }
            $rpAwardedAdded++
            $modified = $true
        }
        $null = $stageRPDict.Remove($key)
    }

    # --- SPP ---
    if ($useSppTag -and $stageSPPDict.ContainsKey($key)) {
        $entry = $stageSPPDict[$key]
        if ($newValue -notmatch $rusSppMarker) {
            $rusPoints = $entry.Points -replace '\(Split\)', '(Split)'
            $rusPoints = $rusPoints -replace '\|', ('| ' + $locSpp + ' ')
            $rusBlock = '<EM' + $entry.Color + '>' + $locSpp + ' ' + $rusPoints + '</EM' + $entry.Color + '>'
            $engSppPattern = '<EM\d+>Scenario Progress Points[\s\d,|()A-Za-z]*</EM\d+>'
            if ($newValue -match $engSppPattern) {
                $newValue = $newValue -replace $engSppPattern, $rusBlock
            } else {
                $newValue = $newValue + '\n\n' + $rusBlock
            }
            $sppAdded++
            $modified = $true
        }
        $null = $stageSPPDict.Remove($key)
    }

    if ($modified) {
        $lines[$i] = $origKey + '=' + $newValue
        $null = $modifiedLineIndices.Add($i)
    }
}
}

# --------------------------------------------------
# Stage 5: Weapon sizes
# --------------------------------------------------
if (-not $customOnly) {
$weaponSizesAdded = 0
if ($weaponSizeTable.Count -gt 0) {
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $p = $line -split '=', 2
        if ($p.Count -ne 2) { continue }
        $key = $p[0].Trim()
        $value = $p[1]
        
        $keyBase = $key -replace ',.*$', ''
        if (-not ($stage4ProcessedKeys.ContainsKey($keyBase) -or $stage5ProcessedKeys.ContainsKey($keyBase))) { continue }
        
        $newValue = $value
        $modified = $false
        
        $valueLines = $value -split '\\n'
        for ($j = 0; $j -lt $valueLines.Count; $j++) {
            $vline = $valueLines[$j]
            if ($vline -match '^- ([^\(]+)$') {
                $weaponName = $Matches[1].Trim()
                if ($weaponSizeTable.ContainsKey($weaponName)) {
                    $size = $weaponSizeTable[$weaponName]
                    $valueLines[$j] = '- ' + $weaponName + ' (' + $size + ')'
                    $modified = $true
                    $weaponSizesAdded++
                }
            }
        }
        
        if ($modified) {
            $newValue = $valueLines -join '\n'
            $lines[$i] = $key + '=' + $newValue
            $null = $modifiedLineIndices.Add($i)
        }
    }
}
}

# --------------------------------------------------
# Stage 6: Cargo titles enrichment
# --------------------------------------------------
if (-not $customOnly) {
if ($useCargoTitles) {
    $cargoTitlesEnriched = 0

    $partRank = "~mission(ReputationRank)"
    $partDirection = "~mission(Location|name) > ~mission(Destination|name)"
    $partDirectionFrom = "$locCargoFrom ~mission(Location|name)"
    $partDirectionTo = "$locCargoTo ~mission(Destination|name)"

    $cargoPatterns = @(
        @{ Pattern = '_HaulCargo_.*_Rehire_';      Haul = "$locCargoHaul ~mission(CargoGradeToken)";      Direction = $partDirection },
        @{ Pattern = '_HaulCargo_AToB_';           Haul = "$locCargoHaul ~mission(CargoGradeToken)";      Direction = $partDirection },
        @{ Pattern = '_HaulCargo_SingleToMulti_';  Haul = "$locCargoHaul ~mission(CargoGradeToken)";      Direction = $partDirectionFrom },
        @{ Pattern = '_HaulCargo_MultiToSingle_';  Haul = "$locCargoHaul ~mission(CargoGradeToken)";      Direction = $partDirectionTo },
        @{ Pattern = '_HaulCargo_LinearChain_';    Haul = "$locCargoChain ~mission(CargoGradeToken)";     Direction = '' },
        @{ Pattern = '_HaulCargo_RoundDelivery_';  Haul = "$locCargoRound ~mission(CargoGradeToken)";     Direction = '' }
    )

    $formatMap = @{
        '1' = @('Direction','Rank','Haul')
        '2' = @('Direction','Haul','Rank')
        '3' = @('Rank','Haul','Direction')
        '4' = @('Rank','Direction','Haul')
        '5' = @('Haul','Rank','Direction')
        '6' = @('Haul','Direction','Rank')
    }
    $formatNames = @('Direction | Rank | Haul', 'Direction | Haul | Rank', 'Rank | Haul | Direction', 'Rank | Direction | Haul', 'Haul | Rank | Direction', 'Haul | Direction | Rank')
    $partOrder = $formatMap[$titleFormat]
    Write-Host "Using cargo titles format: $($formatNames[[int]$titleFormat - 1])"

    $cargoAppendSuffix = " | ~mission(Location|name) > ~mission(Destination|name)"

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $p = $line -split '=', 2
        if ($p.Count -ne 2) { continue }
        $key = $p[0].Trim()
        $keyBase = $key -replace ',.*$', ''
        $value = $p[1]
        
        # RegionLink: append markers
        if ($keyBase -match '_RegionLink_' -and $keyBase -match 'HaulCargo' -and $keyBase -match '_title') {
            if ($value -notmatch [regex]::Escape($cargoAppendSuffix)) {
                $bpSuffix = ''
                if ($value -match '\\n (<EM\d+>\[Чертежи\]\*?</EM\d+>)$') {
                    $bpSuffix = '\n ' + $Matches[1]
                    $value = $value -replace '\\n <EM\d+>\[Чертежи\]\*?</EM\d+>$', ''
                }
                $newValue = $value + $cargoAppendSuffix + $bpSuffix
                if ($newValue -ne ($value + $bpSuffix)) {
                    $lines[$i] = $key + '=' + $newValue
                    $cargoTitlesEnriched++
                    $null = $modifiedLineIndices.Add($i)
                }
            }
            continue
        }
        
        # Template-based categories
        foreach ($cp in $cargoPatterns) {
            if ($keyBase -match $cp.Pattern -and $keyBase -match '_title') {
                $parts = @{}
                $parts['Rank'] = $partRank
                $parts['Haul'] = $cp.Haul
                if ($cp.Direction) { $parts['Direction'] = $cp.Direction }
                
                $ordered = @()
                foreach ($k in $partOrder) {
                    if ($parts.ContainsKey($k)) { $ordered += $parts[$k] }
                }
                $newValue = $ordered -join ' | '
                if ($value -match '\\n (<EM\d+>\[Чертежи\]\*?</EM\d+>)$') {
                    $newValue += '\n ' + $Matches[1]
                }
                
                if ($newValue -ne $value) {
                    $lines[$i] = $key + '=' + $newValue
                    $cargoTitlesEnriched++
                    $null = $modifiedLineIndices.Add($i)
                }
                break
            }
        }
    }
}
}

# --------------------------------------------------
# Stage 98: User notes
# --------------------------------------------------
$userNotesAdded = 0
if ($useUserNotes) {
    $userNotesFile = Join-Path $PSScriptRoot 'user_notes.ini'
    if (Test-Path $userNotesFile) {
        $userNotes = @{}
        Get-Content $userNotesFile -Encoding Default | ForEach-Object {
            $line = $_.Trim()
            if ($line -eq '' -or $line.StartsWith('#')) { return }
            $p = $line -split '=', 2
            if ($p.Count -eq 2) {
                $k = $p[0].Trim()
                $v = $p[1].Trim()
                if ($k -and $v) { $userNotes[$k] = $v }
            }
        }
        $notesMarker = '<EM4>' + $locNotesMarker + '</EM4>'
        $maxNoteLength = 256
        
        if ($userNotes.Count -gt 0) {
            $truncatedNotes = @()
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                $p = $line -split '=', 2
                if ($p.Count -ne 2) { continue }
                $key = $p[0].Trim() -replace ',.*$', ''
                if ($userNotes.ContainsKey($key)) {
                    $note = $userNotes[$key]
                    $note = $note -replace '[^A-Za-zа-яё0-9 .,!?;:()\-_+=\[\]{}|/\\@#$%^&*~`"''<>]', ' '
                    $note = $note -replace ' +', ' '
                    if ($note.Length -gt $maxNoteLength) {
                        $note = $note.Substring(0, $maxNoteLength)
                        $truncatedNotes += $key
                    }
                    $value = ($lines[$i] -split '=', 2)[1]
                    if ($value -match [regex]::Escape($notesMarker)) {
                        $value = $value -replace '\n\n' + [regex]::Escape($notesMarker) + '\n.*$', ''
                        $value = $value -replace '\n\n' + [regex]::Escape($notesMarker) + '$', ''
                    }
                    $newValue = $value + '\n\n' + $notesMarker + '\n' + $note
                    $lines[$i] = $p[0].Trim() + '=' + $newValue
                    $userNotesAdded++
                    $null = $modifiedLineIndices.Add($i)
                }
            }
            if ($truncatedNotes.Count -gt 0) {
                $joined = ($truncatedNotes | Select-Object -First 5) -join ', '
                if ($truncatedNotes.Count -gt 5) { $joined += "... and $($truncatedNotes.Count - 5) more" }
                Write-Host "Warning: $($truncatedNotes.Count) user notes truncated to 256 characters: $joined"
            }
        }
    }
}

# --------------------------------------------------
# Stage 99: User dictionary
# --------------------------------------------------
$userDictApplied = 0
if ($useUserDict) {
    $userDictFile = Join-Path $PSScriptRoot 'user_dict.ini'
    if (Test-Path $userDictFile) {
        $userDict = @{}
        Get-Content $userDictFile -Encoding Default | ForEach-Object {
            $dictLine = $_.Trim()
            if ($dictLine -eq '' -or $dictLine.StartsWith('#')) { return }
            $dp = $dictLine -split '=', 2
            if ($dp.Count -eq 2) {
                $dk = $dp[0].Trim()
                $dv = $dp[1]
                if ($dk -and $dv) { $userDict[$dk] = $dv }
            }
        }
        
        if ($userDict.Count -gt 0) {
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                $p = $line -split '=', 2
                if ($p.Count -ne 2) { continue }
                $keyFull = $p[0].Trim()
                $keyBase = $keyFull -replace ',.*$', ''
                
                $newValue = $null
                if ($userDict.ContainsKey($keyFull)) {
                    $newValue = $userDict[$keyFull]
                } elseif ($userDict.ContainsKey($keyBase)) {
                    $newValue = $userDict[$keyBase]
                }
                
                if ($newValue -and $p[1] -ne $newValue) {
                    $lines[$i] = $keyFull + '=' + $newValue
                    $userDictApplied++
                    $null = $modifiedLineIndices.Add($i)
                }
            }
        }
    }
}

# --------------------------------------------------
# Find unprocessed contracts
# --------------------------------------------------
$unprocessedCount = 0
$unprocessedData = @()
foreach ($k in $allContracts.Keys | Sort-Object) {
    if (-not $allProcessedKeys.ContainsKey($k)) {
        if ($k -match '_Desc(?:,P)?$') {
            $unprocessedData += "$k=$($allContracts[$k])"
            $unprocessedCount++
        }
    }
}
if ($unprocessedCount -gt 0) {
    $unprocessedFile = Join-Path (Split-Path $file1 -Parent) 'unprocessed_contracts.log'
    $unprocessedData | Out-File $unprocessedFile -Encoding UTF8
}

# --------------------------------------------------
# Save changes, create backup, display statistics
# --------------------------------------------------
$totalReplaced = $blueprintsAdded + $bpChanged + $ordnanceReplaced + $colorTagsAdded + $mbpAdded + $rpAwardedAdded + $sppAdded + $regionalVariantsAdded + $itemTypesAdded + $userNotesAdded + $weaponSizesAdded + $cargoTitlesEnriched + $userDictApplied
$changedCount = $modifiedLineIndices.Count
if ($changedCount -eq 0) {
    Write-Host "`nNo modifications were necessary or possible. File global.ini kept unchanged."
} else {
    $alreadyProcessed = ($frontendLine -and $frontendLine -match [regex]::Escape($extraFrontend))
    
    if (-not $alreadyProcessed -and -not $customOnly) {
        $backupFile = $file1 + '.noblueprints.bak'
        if ((Test-Path $backupFile) -and ((Get-Item $backupFile).Attributes -band [System.IO.FileAttributes]::ReadOnly)) {
            $backupFile = $file1 + '.noblueprints1.bak'
        }
        
        $needBackup = $true
        if (Test-Path $backupFile) {
            $backupEncodingName = if ($encoding -eq [System.Text.Encoding]::UTF8) { 'UTF8' } else { 'Default' }
            $backupFrontend = (Select-String -Path $backupFile -Pattern '^Frontend_PU_Version(?:,P)?=' -Encoding $backupEncodingName | Select-Object -First 1).Line
            if ($backupFrontend -and $frontendLine -and $backupFrontend -eq $frontendLine) {
                $needBackup = $false
            }
        }
        
        if ($needBackup) {
            try {
                $markerLine = 'SCLER_backup_created=' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
                $linesWithMarker = @($markerLine) + $originalLines
                $tmpMarkerFile = $file1 + '.marker.tmp'
                [System.IO.File]::WriteAllLines($tmpMarkerFile, $linesWithMarker, $encoding)
                Move-Item -Path $tmpMarkerFile -Destination $file1 -Force
                Copy-Item -Path $file1 -Destination $backupFile -Force -ErrorAction Stop
            } catch {
                Write-Host "`nError: Failed to create backup. " + $_.Exception.Message -ForegroundColor Red
                exit 1
            }
        }
        
        try {
            $tmpFile = $file1 + '.tmp'
            [System.IO.File]::WriteAllLines($tmpFile, $lines, $encoding)
            Move-Item -Path $tmpFile -Destination $file1 -Force
        } catch {
            Write-Host "`nError: Failed to write file. " + $_.Exception.Message -ForegroundColor Red
            exit 1
        }
        
        if ($changedCount -gt 0) {
            $extraFrontendText = '\n' + $extraFrontend
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match '^Frontend_PU_Version(?:,P)?=') {
                    if ($lines[$i] -notmatch [regex]::Escape($extraFrontend)) {
                        $lines[$i] = $lines[$i] + $extraFrontendText
                    }
                    if (($userNotesAdded -gt 0 -or $userDictApplied -gt 0) -and $lines[$i] -notmatch [regex]::Escape($locModifiedByPlayer)) {
                        $lines[$i] = $lines[$i] + ' (' + $locModifiedByPlayer + ')'
                    }
                    break
                }
            }
            [System.IO.File]::WriteAllLines($file1, $lines, $encoding)
        }
        
        if ($needBackup) {
            Write-Host "`nBackup: $backupFile"
        }
    } else {
        try {
            $tmpFile = $file1 + '.tmp'
            [System.IO.File]::WriteAllLines($tmpFile, $lines, $encoding)
            Move-Item -Path $tmpFile -Destination $file1 -Force
        } catch {
            Write-Host "`nError: Failed to write file. " + $_.Exception.Message -ForegroundColor Red
            exit 1
        }
        
        if ($changedCount -gt 0) {
            if ($userNotesAdded -gt 0 -or $userDictApplied -gt 0) {
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    if ($lines[$i] -match '^Frontend_PU_Version(?:,P)?=') {
                        if ($lines[$i] -notmatch [regex]::Escape($locModifiedByPlayer)) {
                            $lines[$i] = $lines[$i] + ' (' + $locModifiedByPlayer + ')'
                        }
                        break
                    }
                }
            }
            [System.IO.File]::WriteAllLines($file1, $lines, $encoding)
        }
    }
    
    Write-Host ""
    
    if ($customOnly) {
        $userDetails = @()
        if ($useUserNotes) { $userDetails += "$userNotesAdded notes" }
        if ($useUserDict) { $userDetails += "$userDictApplied dict" }
        if ($userDetails.Count -gt 0) {
            Write-Host "User data added:       $($userDetails -join ', ')"
        }
        Write-Host "Total processed:       $lineCount lines, $totalReplaced replacements, $changedCount modified lines"
    } else {
        Write-Host "Ordnance replaced:     $ordnanceReplaced"
        if ($useColorTags) { Write-Host "Color Tags added:      $colorTagsAdded" }
        Write-Host "BP Markers added:      $bpChanged"
        $descDetails = "$blueprintsAdded BP"
        if ($blueprintsRepeatOnly -gt 0) { $descDetails += " ($blueprintsRepeatOnly Repeat Only)" }
        $descDetails += ", $mbpAdded MBP"
        if ($useRpAwardTag) { $descDetails += ", $rpAwardedAdded reputation" }
        if ($useSppTag) { $descDetails += ", $sppAdded SPP" }
        $descDetails += ", $regionalVariantsAdded regional variants, $itemTypesAdded item types, $moduleClassesAdded module classes, $weaponSizesAdded weapon sizes"
        if ($useCargoTitles) { $descDetails += ", $cargoTitlesEnriched cargo titles" }
        Write-Host "Descriptions added:    $descDetails"
        $userDetails = @()
        if ($useUserNotes) { $userDetails += "$userNotesAdded notes" }
        if ($useUserDict) { $userDetails += "$userDictApplied dict" }
        if ($userDetails.Count -gt 0) {
            Write-Host "User data added:       $($userDetails -join ', ')"
        }
        Write-Host "Total processed:       $lineCount lines, $totalReplaced replacements, $changedCount modified lines"
    }
    
    if ($unprocessedCount -gt 0) {
        Write-Host "`nUnprocessed contracts: $unprocessedCount (saved to $unprocessedFile)"
    }
}

$totalMissing = $missingBp.Count
if ($totalMissing -gt 0) {
    Write-Host "`nWarning: $totalMissing BP entries not found in global.ini. The localization file may be outdated."
}