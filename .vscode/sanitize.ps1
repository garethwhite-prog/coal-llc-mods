param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath
)

if (-not (Test-Path -LiteralPath $FilePath)) {
    Write-Error "File not found: $FilePath"
    exit 1
}

# Read file contents as a single string
$text = Get-Content -LiteralPath $FilePath -Raw

# 1. LaTeX pipe symbol artifact
$text = $text -replace '\\vert(\{\})?', '|'

# 2. Glued parameters (-Content$, -Path$)
$text = $text -replace '-Content\$', '-Content $'
$text = $text -replace '-Path\$', '-Path $'
$text = $text -replace '-Item\$', '-Item $'
$text = $text -replace '-Value\$', '-Value $'

# 3. Non-breaking space or missing space before in$
$text = $text -replace '[\u00A0 ]in\$', ' in $'

# 4. Glued assignment operator (=$output -> = $output)
$text = $text -replace '=\$', '= $'

# # 5. Collapsed line breaks (e.g., closing bracket or statement directly glued to $)
# $text = $text -replace '([;}\)\"\w])\$([a-zA-Z_])', "`$1`r`n`$`$2"

# Save the sanitized file
Set-Content -LiteralPath $FilePath -Value $text -NoNewline
Write-Host "Successfully sanitized: $(Split-Path $FilePath -Leaf)" -ForegroundColor Green