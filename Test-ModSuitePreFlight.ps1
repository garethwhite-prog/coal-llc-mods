param(
    [string[]]$TargetMods = @()
)

$ErrorActionPreference = "Stop"
$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-Issue([string]$modName, [string]$msg) {
    if ($TargetMods.Count -eq 0 -or ($TargetMods -contains $modName)) {
        $failures.Add("[$modName] $msg")
    } else {
        $warnings.Add("[$modName] $msg")
    }
}

if (Test-Path (Join-Path $steamRoot "override.cfg")) {
    $failures.Add("[SteamRoot] Unstable override.cfg detected in $steamRoot")
}

$modDirs = Get-ChildItem -Path (Join-Path $repoRoot "mods-unpacked") -Directory
foreach ($dir in $modDirs) {
    $modName = $dir.Name
    if ($TargetMods.Count -gt 0 -and -not ($TargetMods -contains $modName)) {
        continue
    }

    # Check manifest.json validity
    $manifests = Get-ChildItem -Path $dir.FullName -Recurse -Filter "manifest.json"
    if ($manifests.Count -eq 0) {
        Add-Issue $modName "No manifest.json found."
    }
    foreach ($mf in $manifests) {
        try {
            $null = (Get-Content -Path $mf.FullName -Raw) | ConvertFrom-Json
        } catch {
            Add-Issue $modName "Invalid JSON in $($mf.FullName): $($_.Exception.Message)"
        }
    }

    # Check every .gd file for parse/indentation/encoding hazards
    $gdFiles = Get-ChildItem -Path $dir.FullName -Recurse -Filter "*.gd"
    foreach ($gd in $gdFiles) {
        $rel = $gd.FullName.Substring($repoRoot.Length + 1)
        $bytes = [System.IO.File]::ReadAllBytes($gd.FullName)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            Add-Issue $modName "UTF-8 BOM detected in $rel (must be UTF-8 without BOM)."
        }

        $lines = Get-Content -Path $gd.FullName
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            $lineNum = $i + 1

            # Mixed tabs and spaces in leading whitespace
            if ($line -match '^(\t+ +| +\t+)') {
                Add-Issue $modName "Mixed tabs/spaces indentation at ${rel}:${lineNum}"
            }

            # Unexpanded PowerShell placeholder artifacts
            if ($line -match '\$\{T\}|\$\{Q\}') {
                Add-Issue $modName "Unexpanded template token at ${rel}:${lineNum}"
            }

            # Top-level func declaration must be followed by an indented body line
            if ($line -match '^func\s+[A-Za-z0-9_]+\s*\(.*\)\s*(->\s*[^:]+)?\s*:\s*$') {
                $foundBody = $false
                for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                    $next = $lines[$j]
                    if ($next -match '^\s*$' -or $next -match '^\s*#') {
                        continue
                    }
                    if ($next -match '^[\t ]+\S') {
                        $foundBody = $true
                    }
                    break
                }
                if (-not $foundBody) {
                    Add-Issue $modName "Expected indented block after function declaration at ${rel}:${lineNum}"
                }
            }
        }
    }
}

Write-Output "Pre-Flight Check Complete | Failures: $($failures.Count) | Warnings: $($warnings.Count)"
foreach ($w in $warnings) { Write-Output "WARN: $w" }
foreach ($f in $failures) { Write-Output "FAIL: $f" }

if ($failures.Count -gt 0) {
    exit 1
}
exit 0
