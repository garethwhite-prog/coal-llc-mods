param (
	[string]$RepoPath = "C:\Dev\coal-llc-mods"
)

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ">>> COAL LLC CI/CD: Automated Regression & Sanity Verification" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$errors = 0
$warnings = 0

# Test 1: ModRegistry Contract
$regFile = "$RepoPath\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_registry.gd"
if (Test-Path $regFile) {
	$regText = Get-Content $regFile -Raw
	if (-not $regText.Contains("func is_mod_active_for_run")) {
		Write-Host "  [CRITICAL FAIL] mod_registry.gd is missing is_mod_active_for_run!" -ForegroundColor Red
		$errors++
	} else {
		Write-Host "  [PASS] mod_registry.gd satisfies is_mod_active_for_run interface" -ForegroundColor Green
	}
}

# Test 2: Manifest Schemas
$manifests = Get-ChildItem -Path "$RepoPath\mods-unpacked" -Recurse -Filter "manifest.json"
foreach ($m in $manifests) {
	try {
		$j = Get-Content $m.FullName -Raw | ConvertFrom-Json
		if (-not $j.name -or -not $j.version_number) {
			Write-Host "  [FAIL] Incomplete manifest at $($m.FullName)" -ForegroundColor Red
			$errors++
		}
	} catch {
		Write-Host "  [FAIL] JSON parse error: $($m.FullName)" -ForegroundColor Red
		$errors++
	}
}

# Test 3: Hook Signatures & Execute Next
$hookScripts = Get-ChildItem -Path "$RepoPath\mods-unpacked" -Recurse -Filter "*.hooks.gd"
foreach ($h in $hookScripts) {
	$ht = Get-Content $h.FullName -Raw
	if ($ht.Contains("chain: ModLoaderHookChain") -and -not $ht.Contains("chain.execute_next")) {
		Write-Host "  [WARN] $($h.Name) has hook chain without chain.execute_next" -ForegroundColor Yellow
		$warnings++
	}
}

Write-Host "=================================================================" -ForegroundColor Cyan
if ($errors -eq 0) {
	Write-Host ">>> ALL REGRESSION CHECKS PASSED (Warnings: $warnings, Errors: 0)" -ForegroundColor Green
	exit 0
} else {
	Write-Host ">>> CI/CD VERIFICATION FAILED (Errors: $errors)" -ForegroundColor Red
	exit 1
}
