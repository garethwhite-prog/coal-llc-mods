[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$InputPath = "C:\Dev\coal-llc-mods\tests.txt",

    [Parameter(Position = 1)]
    [string]$OutputPath = "C:\Dev\coal-llc-mods\tests_concise.txt"
)

Clear-Host

if (-not (Test-Path -LiteralPath $InputPath)) {
    Write-Error "Input file not found at: $InputPath"
    return
}

$writer = [System.IO.StreamWriter]::new($OutputPath, $false, [System.Text.Encoding]::UTF8)

try {
    $currentKey = $null
    $firstLine  = $null
    $lastLine   = $null
    $count      = 0

    function Write-Run {
        param($key, $first, $last, [int]$cnt)

        if ($cnt -eq 1) {
            $writer.WriteLine($first)
        }
        elseif ($cnt -eq 2) {
            $writer.WriteLine($first)
            $writer.WriteLine($last)
        }
        else {
            $writer.WriteLine("[Repeated $cnt times]")
            $writer.WriteLine("  First: $first")
            $writer.WriteLine("  Last:  $last")
        }
    }

    foreach ($line in [System.IO.File]::ReadLines($InputPath)) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        # Normalize key: strip line numbers (e.g. "20244: "), tags ("[ModLoader] "), and timestamps ("20:09:20   ")
        $key = if ($line -match '^\s*\d+:\s*(?:\[[^\]]+\]\s*)?(?:\d{2}:\d{2}:\d{2}\s+)?(.*)$') {
            $Matches[1].Trim()
        } else {
            $line.Trim()
        }

        if ($null -ne $currentKey -and $key -eq $currentKey) {
            $lastLine = $line
            $count++
        }
        else {
            if ($count -gt 0) {
                Write-Run -key $currentKey -first $firstLine -last $lastLine -cnt $count
            }
            $currentKey = $key
            $firstLine  = $line
            $lastLine   = $line
            $count      = 1
        }
    }

    if ($count -gt 0) {
        Write-Run -key $currentKey -first $firstLine -last $lastLine -cnt $count
    }
}
finally {
    $writer.Dispose()
}

Write-Host "Summarized log written to: $OutputPath" -ForegroundColor Green
