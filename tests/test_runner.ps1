param (
	[string]$RepoPath = "C:\Dev\coal-llc-mods"
)

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ">>> COAL LLC CI/CD: Automated Static Analysis & Sanity Tests" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$allGd = Get-ChildItem -Path "$RepoPath\mods-unpacked" -Recurse -Filter "*.gd"
$allManifests = Get-ChildItem -Path "$RepoPath\mods-unpacked" -Recurse -Filter "manifest.json"

$errors = 0
$warnings = 0

# Test 1: Manifest Schema Integrity
Write-Host ">>> TEST 1: Validating $($allManifests.Count) mod manifests..." -ForegroundColor Yellow
foreach ($m in $allManifests) {
	try {
		$json = Get-Content $m.FullName -Raw | ConvertFrom-Json
		if (-not $json.name -or -not $json.version_number) {
			Write-Host "  [FAIL] Missing name/version: $($m.FullName)" -ForegroundColor Red
			$errors++
		}
	} catch {
		Write-Host "  [CRITICAL] Invalid JSON: $($m.FullName) - $_" -ForegroundColor Red
		$errors++
	}
}

# Test 2: Hook Method Signatures & Zero Division Checks
Write-Host ">>> TEST 2: Inspecting $($allGd.Count) GDScript files for syntax pitfalls..." -ForegroundColor Yellow
foreach ($gd in $allGd) {
	$content = Get-Content $gd.FullName
	for ($i = 0; $i -lt $content.Count; $i++) {
		$line = $content[$i]
		# Check for unguarded division
		if ($line -match '/\s*itemBuyPrice' -and -not ($content[$i-1] -match 'cost <= 0' -or $line -match 'max\(1')) {
			Write-Host "  [WARN] Potential zero-division at $($gd.Name):$($i+1)" -ForegroundColor Yellow
			$warnings++
		}
		# Check hook signature
		if ($line -match 'func\s+[a-zA-Z0-9_]+\s*\(\s*chain\s*:\s*ModLoaderHookChain' -and -not ($line -match '->\s*void')) {
			Write-Host "  [NOTICE] Hook function missing explicit -> void at $($gd.Name):$($i+1)" -ForegroundColor DarkGray
		}
	}
}

Write-Host "=================================================================" -ForegroundColor Cyan
if ($errors -eq 0) {
	Write-Host ">>> ALL CI/CD SANITY CHECKS PASSED (Warnings: $warnings, Errors: 0)" -ForegroundColor Green
	exit 0
} else {
	Write-Host ">>> CI/CD PIPELINE FAILED (Errors: $errors)" -ForegroundColor Red
	exit 1
}
