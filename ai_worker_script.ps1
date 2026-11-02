$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. FIXING MAIN MENU SCENE INSTANTIATION (BUG-06) ---"
$mainMenuHooksPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts\MainMenu.hooks.gd"
if (Test-Path $mainMenuHooksPath) {
    $mmContent = Get-Content $mainMenuHooksPath -Raw
    # Revert the incorrect .tscn assumption back to reality (.gd and .new())
    $mmContent = $mmContent -replace '\.tscn"', '.gd"'
    $mmContent = $mmContent -replace '\.instantiate\(\)', '.new()'
    $mmContent | Set-Content -Path $mainMenuHooksPath -Encoding UTF8
    Write-Output "Reverted MainMenu.hooks.gd to load .gd scripts natively."
}

Write-Output "--- 2. FIXING MOD MANAGER SEARCH UI (BUG-05) ---"
$mgrViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
if (Test-Path $mgrViewPath) {
    git checkout 807de20 -- "$mgrViewPath"
    $mvContent = Get-Content $mgrViewPath -Raw
    
    $searchLogic = @"

func _inject_search_bar() -> void:
	var header = find_child("HeaderContainer", true, false)
	if not header:
		header = HBoxContainer.new()
		add_child(header)
		move_child(header, 0)
	
	var search = LineEdit.new()
	search.placeholder_text = "Search active mods..."
	search.custom_minimum_size = Vector2(300, 35)
	search.text_changed.connect(Callable(self, "_on_search_filter"))
	header.add_child(search)

func _on_search_filter(query: String) -> void:
	var q = query.to_lower()
	var list = find_child("ModListContainer", true, false)
	if list == null: list = find_child("*Grid*", true, false)
	
	if is_instance_valid(list):
		for card in list.get_children():
			if q.is_empty():
				card.visible = true
			else:
				var mod_name = card.name.to_lower()
				var lbl = card.find_child("*Label*", true, false)
				if is_instance_valid(lbl): mod_name += lbl.text.to_lower()
				card.visible = q in mod_name
"@
    
    $mvContent = $mvContent -replace 'func _ready\(\) -> void:', "func _ready() -> void:`n`tcall_deferred(`"_inject_search_bar`")"
    $mvContent += $searchLogic
    
    $mvContent | Set-Content -Path $mgrViewPath -Encoding UTF8
    Write-Output "Injected robust search bar generation into mod_manager_view.gd."
}

Write-Output "--- 3. REPACKING MOD MANAGER ---"
$targetMods = @("gareth-mod_manager_mod")
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($mod in $targetMods) {
    $srcDir = Join-Path $repoRoot "mods-unpacked\$mod"
    $downZip = Join-Path $downMods "$mod.zip"
    $steamZip = Join-Path $steamMods "$mod.zip"
    
    if (Test-Path $downZip) { Remove-Item $downZip -Force }
    $archive = [System.IO.Compression.ZipFile]::Open($downZip, [System.IO.Compression.ZipArchiveMode]::Create)
    $files = Get-ChildItem -Path $srcDir -Recurse -File
    foreach ($file in $files) {
        $entryName = $file.FullName.Substring($srcDir.Length + 1).Replace("\", "/")
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entryName)
    }
    $archive.Dispose()
    if (Test-Path $steamZip) { Copy-Item -Path $downZip -Destination $steamZip -Force }
    Write-Output "Deployed $mod.zip"
}

Write-Output "--- 4. CLEANING CACHE & COMMITTING ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force -ErrorAction SilentlyContinue }

git add -A
git commit -m "Fix: Reverted MainMenu.hooks.gd to load .gd scripts instead of non-existent .tscn files, and cleanly injected Mod Manager search bar."
git push origin main
Write-Output "Process Complete."