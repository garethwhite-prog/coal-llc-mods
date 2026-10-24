Clear-Host

# ==============================================================================
# Coal LLC - Commit 3: Multi-Repo Mod Store & Dual-Folder Architecture
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$steamRepo  = "$steamRoot\mods_repository"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

# ------------------------------------------------------------------------------
# 2. WRITE MOD STORE CLIENT SCRIPT (MULTI-REPO GITHUB API)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Writing mod_store_client.gd..." -ForegroundColor Cyan
$storeScript = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_store_client.gd"
@'
class_name ModStoreClient
extends Node

signal repo_fetch_completed(repo_name: String, releases: Array)
signal mod_download_completed(mod_id: String, success: bool)

const DEFAULT_REPOS := [
	"garethwhite-prog/coal-llc-mods",
	"Der-Floh/coal-llc-mods"
]

var http_client: HTTPRequest

func _ready() -> void:
	http_client = HTTPRequest.new()
	add_child(http_client)

func fetch_all_available_mods() -> void:
	var repos = _load_repo_list()
	for r in repos:
		_fetch_repo_releases(r)

func _load_repo_list() -> Array:
	var list := DEFAULT_REPOS.duplicate()
	var path := "user://mod_store_repos.json"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f:
			var data = JSON.parse_string(f.get_as_text())
			if data is Array:
				for custom_r in data:
					if not custom_r in list:
						list.append(custom_r)
	return list

func _fetch_repo_releases(repo: String) -> void:
	var url := "https://api.github.com/repos/%s/releases" % repo
	var headers := ["User-Agent: Coal-LLC-Mod-Store/1.0"]
	http_client.request(url, headers)
	var result = await http_client.request_completed
	if result[1] == 200:
		var json = JSON.parse_string(result[3].get_string_from_utf8())
		if json is Array:
			repo_fetch_completed.emit(repo, json)

func download_mod_zip(download_url: String, target_filename: String) -> void:
	var dl_http = HTTPRequest.new()
	add_child(dl_http)
	var local_repo_dir := OS.get_executable_path().get_base_dir().path_join("mods_repository")
	var dest_path := local_repo_dir.path_join(target_filename)
	dl_http.download_file = dest_path
	dl_http.request(download_url, ["User-Agent: Coal-LLC-Mod-Store/1.0"])
	var res = await dl_http.request_completed
	dl_http.queue_free()
	mod_download_completed.emit(target_filename, res[1] == 200)
'@ | Set-Content -Path $storeScript -Encoding UTF8

# ------------------------------------------------------------------------------
# 3. IMPLEMENT SAVE-SLOT DUAL-FOLDER SYNCHRONIZER
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Writing save_profile_sync.gd (mods_repository <-> mods)..." -ForegroundColor Cyan
$syncScript = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\save_profile_sync.gd"
@'
class_name SaveProfileSync
extends RefCounted

static func sync_slot_mods_to_runtime(slot_id: int) -> void:
	var exe_dir := OS.get_executable_path().get_base_dir()
	var repo_dir := exe_dir.path_join("mods_repository")
	var active_dir := exe_dir.path_join("mods")

	var slot_config_path := "user://slot_%d_active_mods.json" % slot_id
	if not FileAccess.file_exists(slot_config_path):
		return

	var f := FileAccess.open(slot_config_path, FileAccess.READ)
	if not f:
		return
	var active_map = JSON.parse_string(f.get_as_text())
	if not (active_map is Dictionary):
		return

	# Copy enabled zips from master mods_repository into active mods/
	var dir := DirAccess.open(repo_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".zip"):
				var mod_key = file_name.replace(".zip", "")
				var is_active = bool(active_map.get(mod_key, true))
				var src = repo_dir.path_join(file_name)
				var dst = active_dir.path_join(file_name)
				if is_active:
					dir.copy(src, dst)
				else:
					if FileAccess.file_exists(dst):
						DirAccess.remove_absolute(dst)
			file_name = dir.get_next()
'@ | Set-Content -Path $syncScript -Encoding UTF8

# ------------------------------------------------------------------------------
# 4. REPACK & COMMIT
# ------------------------------------------------------------------------------
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$src = "$repo\mods-unpacked\gareth-mod_manager_mod"
$zip = "$steamMods\gareth-mod_manager_mod.zip"
if (Test-Path $zip) { Remove-Item -Path $zip -Force }

$stream  = [System.IO.File]::Open($zip, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $src -Recurse -File)) {
	$entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")
	[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "  Repacked: gareth-mod_manager_mod.zip" -ForegroundColor Green

git add -A
git commit -m "Commit 3: Mod Store multi-repo aggregation (garethwhite-prog + Der-Floh), dual-folder staging (mods_repository), and per-save mod profile isolation"
git push origin main
Write-Host "`nCommit 3 complete!" -ForegroundColor Green