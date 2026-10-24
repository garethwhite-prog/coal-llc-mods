Clear-Host;

Write-Host "==========================================" -ForegroundColor Cyan;
Write-Host "COAL LLC MOD SUITE - AUTOMATED TEST RUNNER" -ForegroundColor Cyan;
Write-Host "==========================================" -ForegroundColor Cyan;

$repoRoot = "C:\Dev\coal-llc-mods";
$steamMods = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods";
$logDir = [System.IO.Path]::Combine($env:APPDATA, "Godot\app_userdata\Coal LLC\logs");
$godotLog = [System.IO.Path]::Combine($logDir, "godot.log");

Add-Type -AssemblyName System.IO.Compression.FileSystem;

# 1. Package and deploy active mods
$mods = @("gareth-mod_manager_mod", "gareth-knight_class_mod", "gareth-dual_multipliers_mod", "gareth-elemental_transmutation_mod");
for ($m = 0; $m -lt $mods.Length; $m++) {
    $modName = $mods[$m];
    $src = [System.IO.Path]::Combine($repoRoot, "mods-unpacked", $modName);
    $repoZip = [System.IO.Path]::Combine($repoRoot, "mods", "$modName.zip");
    $dstZip = [System.IO.Path]::Combine($steamMods, "$modName.zip");

    if ([System.IO.Directory]::Exists($src)) {
        if ([System.IO.File]::Exists($repoZip)) { [System.IO.File]::Delete($repoZip); };
        $fs = [System.IO.File]::Open($repoZip, [System.IO.FileMode]::Create);
        $zip = [System.IO.Compression.ZipArchive]::new($fs, [System.IO.Compression.ZipArchiveMode]::Create);
        $files = [System.IO.Directory]::GetFiles($src, "*", [System.IO.SearchOption]::AllDirectories);
        for ($f = 0; $f -lt $files.Length; $f++) {
            $fp = $files[$f];
            $rel = $fp.Substring($src.Length + 1).Replace("\", "/");
            $entry = $zip.CreateEntry($rel);
            $es = $entry.Open();
            $fs2 = [System.IO.File]::OpenRead($fp);
            $fs2.CopyTo($es);
            $fs2.Dispose();
            $es.Dispose();
        };
        $zip.Dispose();
        $fs.Dispose();
        [System.IO.File]::Copy($repoZip, $dstZip, $true);
        Write-Host "  -> Deployed $modName" -ForegroundColor Green;
    };
};

Write-Host "`nMods deployed cleanly with forward slashes." -ForegroundColor Green;
Write-Host "Launch Coal LLC to test, or press any key to audit godot.log..." -ForegroundColor Yellow;
$null =$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown");

if ([System.IO.File]::Exists($godotLog)) {
    Write-Host "`nScanning latest $godotLog for errors and telemetry..." -ForegroundColor Cyan;
    $lines = [System.IO.File]::ReadAllLines($godotLog);
    $errors = [System.Collections.Generic.List[string]]::new();
    $telemetry = [System.Collections.Generic.List[string]]::new();

    for ($i = 0; $i -lt $lines.Length; $i++) {
        $l = $lines[$i];
        if ($l.Contains("SCRIPT ERROR") -or $l.Contains("Invalid get index") -or $l.Contains("Invalid call")) {
            if (-not $l.Contains("der_floh-performance_mod")) {
                $errors.Add(("{0,4}: {1}" -f ($i + 1), $l));
            };
        };
        if ($l.Contains("[KnightSword]") -or $l.Contains("Auto choosing") -or $l.Contains("Transmutation")) {
            $telemetry.Add(("{0,4}: {1}" -f ($i + 1), $l));
        };
    };

    if ($errors.Count -gt 0) {
        Write-Host "Runtime Errors Found:" -ForegroundColor Red;
        for ($e = 0; $e -lt $errors.Count; $e++) { Write-Host $errors[$e] -ForegroundColor Red; };
    } else {
        Write-Host "Clean Run: Zero script runtime errors!" -ForegroundColor Green;
    };

    if ($telemetry.Count -gt 0) {
        Write-Host "`nTelemetry Highlights (Last 15):" -ForegroundColor Cyan;
        $start = [Math]::Max(0,$telemetry.Count - 15);
        for ($t = $start; $t -lt $telemetry.Count; $t++) { Write-Host $telemetry[$t] -ForegroundColor White; };
    };
};

./Reduce_Test_Output.ps1 -InputPath $godotLog -OutputPath ([System.IO.Path]::Combine($repoRoot, "tests_concise.txt"));