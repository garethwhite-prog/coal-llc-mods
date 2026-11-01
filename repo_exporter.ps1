Clear-Host
# repo_exporter.ps1
# Combines workspace text source code files into a single, structured context output.

$TargetDirectory = Get-Location
$OutputFile = Join-Path $TargetDirectory "packed_source_context.txt"

# Comprehensive list of binary extensions, archives, and asset types to skip
$ExcludedExtensions = @(
    '.zip', '.png', '.jpg', '.jpeg', '.gif', '.ico', '.bmp', 
    '.gdc', '.scn', '.remap', '.tres', '.tscn', '.exe', '.dll', '.pdb'
)

# Root folders to completely bypass
$ExcludedFolders = @('.git', '.vscode', 'extracted_inventory')

# Specific task and pipeline progress files to omit
$ExcludedFiles = @(
    'files.txt', 
    'ai_discovery.ps1', 
    'ai_worker_script.ps1', 
    'output.txt', 
    'tests.txt', 
    'context.txt', 
    'tests_concise.txt',
    'packed_source_context.txt'
)

Write-Host "📦 Starting source packing inside: $TargetDirectory" -ForegroundColor Cyan

# Initialize/clear file
$Header = @"
==================================================
WORKSPACE SOURCE CODE DUMP
Generated on: $(Get-Date)
==================================================

"@
Set-Content -Path $OutputFile -Value $Header

# Gather and filter files up front (resolve full paths safely)
$FilesToLog = Get-ChildItem -Path $TargetDirectory -Recurse -File | Where-Object {
    $item = $_ 
    $relativePath = [System.IO.Path]::GetRelativePath($TargetDirectory.Path, $item.FullName)
    
    # Flag to track validity
    $shouldKeep = $true
    
    # Check folder exclusions
    foreach ($folder in $ExcludedFolders) {
        if ($relativePath -like "$folder*" -or $relativePath -like "*$folder*") { 
            $shouldKeep = $false 
        }
    }
    
    # Check specific file exclusions
    if ($ExcludedFiles -contains $item.Name) { 
        $shouldKeep = $false 
    }
    
    # Check binary/asset extensions
    if ($ExcludedExtensions -contains $item.Extension.ToLower()) { 
        $shouldKeep = $false 
    }
    
    # Exclude the output file itself explicitly
    if ($item.FullName -eq $OutputFile) {
        $shouldKeep = $false
    }
    
    $shouldKeep
}

# 1. Output a Scannable Directory Tree First
Add-Content -Path $OutputFile -Value "### WORKSPACE STRUCTURE"
Add-Content -Path $OutputFile -Value "````"
foreach ($file in $FilesToLog) {$relativePath = [System.IO.Path]::GetRelativePath($TargetDirectory.Path, $file.FullName)
    Add-Content -Path $OutputFile -Value "$relativePath"
}
Add-Content -Path $OutputFile -Value "````"

# 2. Append Contents of Text/Code Files
Write-Host "📄 Processing files..." -ForegroundColor Yellow
$FileCount = 0

foreach ($file in $FilesToLog) {
    # Safely compute relative path without relying on working directory state
    $relativePath = $file.FullName.Substring($TargetDirectory.Path.Length).TrimStart('\', '/')
    
    Add-Content -Path $OutputFile -Value "=================================================="
    Add-Content -Path $OutputFile -Value "FILE: $relativePath"
    Add-Content -Path $OutputFile -Value "=================================================="
    
    try {
        $fileStream = [System.IO.FileStream]::new($file.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $streamReader = [System.IO.StreamReader]::new($fileStream)
        $content = $streamReader.ReadToEnd()
        $streamReader.Close()
        $fileStream.Close()

        if ([string]::IsNullOrWhiteSpace($content)) {
             Add-Content -Path $OutputFile -Value "[Empty File]"
         } else {
        #     Add-Content -Path $OutputFile -Value "````"
             Add-Content -Path $OutputFile -Value "--------"
             Add-Content -Path $OutputFile -Value $content
             Add-Content -Path $OutputFile -Value "--------"
        #     Add-Content -Path $OutputFile -Vaue "````"
        }
        $FileCount++
    }
    catch {
        Add-Content -Path $OutputFile -Value "[Error reading file content]"
        Write-Host "⚠️ Skipped file: $relativePath" -ForegroundColor DarkYellow
    }
}

Write-Host "✅ Done! Packed $FileCount files into: $OutputFile" -ForegroundColor Green