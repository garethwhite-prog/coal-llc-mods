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

# Use a StreamWriter for high-speed streaming on large log files
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
            # For exactly 2, showing both lines avoids unnecessary summary overhead
            $writer.WriteLine($first)
            $writer.WriteLine($last)
        }
        else {
            $writer.WriteLine("[Repeated $cnt times]")
            $writer.WriteLine("  First: $first")
            $writer.WriteLine("  Last:  $last")
        }
    }

    # Stream line by line to keep memory footprint minimal
    foreach ($line in [System.IO.File]::ReadLines($InputPath)) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        # Normalize the message key by stripping leading numbers followed by a colon
        # (e.g. "20244: SCRIPT ERROR: ..." -> "SCRIPT ERROR: ...")
        $key = if ($line -match '^\s*\d+:\s*(.*)$') { $Matches[1].Trim() } else { $line.Trim() }

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

    # Flush final run
    if ($count -gt 0) {
        Write-Run -key $currentKey -first $firstLine -last $lastLine -cnt $count
    }
}
finally {
    $writer.Dispose()
}

Write-Host "Summarized log written to: $OutputPath" -ForegroundColor Green