$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. FIXING MOD STORE HTTP REQUESTS (US-05) ---"
$storeClientPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_store_client.gd"
if (Test-Path $storeClientPath) {
    git checkout 807de20 -- "$storeClientPath"
    $scContent = Get-Content $storeClientPath -Raw
    
    $httpFix = @"
extends Node

signal repo_fetch_completed(repo_name: String, releases: Array)
signal mod_download_completed(mod_id: String, success: bool, msg: String)

var _http: HTTPRequest
var _request_queue: Array = []
var _is_requesting: bool = false

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(Callable(self, "_on_request_completed"))

func fetch_all_available_mods() -> void:
	var url = "https://raw.githubusercontent.com/garethwhite-prog/coal-llc-mods/main/mod_catalog.json?v=" + str(Time.get_unix_time_from_system())
	_queue_request(url, Callable(self, "_on_catalog_response"))

func _queue_request(url: String, callback: Callable) -> void:
	_request_queue.append({"url": url, "callback": callback})
	_process_queue()

func _process_queue() -> void:
	if _is_requesting or _request_queue.is_empty(): return
	_is_requesting = true
	var req = _request_queue.pop_front()
	_http.set_meta("current_callback", req.callback)
	_http.request(req.url)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	_is_requesting = false
	var cb = _http.get_meta("current_callback")
	if cb and cb.is_valid():
		cb.call(result, response_code, headers, body)
	_process_queue()

func _on_catalog_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json = JSON.new()
		var err = json.parse(body.get_string_from_utf8())
		if err == OK:
			var data = json.get_data()
			if typeof(data) == TYPE_ARRAY:
				repo_fetch_completed.emit("Coal LLC Mods", data)
				return
	repo_fetch_completed.emit("Coal LLC Mods", [])

func download_mod(mod_id: String) -> void:
	var url = "https://raw.githubusercontent.com/garethwhite-prog/coal-llc-mods/main/downloaded_mods/%s.zip" % mod_id
	var save_path = OS.get_executable_path().get_base_dir().path_join("mods").path_join(mod_id + ".zip")
	_http.download_file = save_path
	_queue_request(url, Callable(self, "_on_download_completed").bind(mod_id))

func _on_download_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, mod_id: String) -> void:
	_http.download_file = ""
	if response_code == 200:
		mod_download_completed.emit(mod_id, true, "Installed successfully.")
	else:
		mod_download_completed.emit(mod_id, false, "Download failed.")
"@
    $httpFix | Set-Content -Path $storeClientPath -Encoding UTF8
    Write-Output "Patched Mod Store Client to use a sequential HTTP queue."
}

Write-Output "--- 2. FIXING MOD STORE VIEW (US-05) ---"
$storeViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_store_view.gd"
if (Test-Path $storeViewPath) {
    git checkout 807de20 -- "$storeViewPath"
    $svContent = @"
extends Control

var container: GridContainer
var status_lbl: Label
var all_packages: Array = []

func _ready() -> void:
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)

	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(header)

	status_lbl = Label.new()
	status_lbl.text = "Loading Mod & Map Catalog..."
	status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(status_lbl)

	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(100, 40)
	close_btn.pressed.connect(Callable(self, "_on_close_pressed"))
	header.add_child(close_btn)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	container = GridContainer.new()
	container.columns = 3
	container.add_theme_constant_override("h_separation", 20)
	container.add_theme_constant_override("v_separation", 20)
	scroll.add_child(container)

	var client_script = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_store_client.gd")
	if client_script:
		var c = client_script.new()
		add_child(c)
		c.repo_fetch_completed.connect(Callable(self, "_on_catalog_loaded"))
		c.fetch_all_available_mods()

func _on_catalog_loaded(repo: String, releases: Array) -> void:
	all_packages.clear()
	for r in releases:
		if typeof(r) != TYPE_DICTIONARY: continue
		var p_name = str(r.get("name", "Unknown Mod"))
		var p_id = str(r.get("id", ""))
		var tag = str(r.get("version", "1.0.0"))
		if p_id == "": continue

		all_packages.append({
			"id": p_id,
			"name": p_name,
			"tag": tag,
			"desc": str(r.get("description", "No description available.")),
			"cat": "Official Suite",
			"author": str(r.get("author", "Gareth White"))
		})
	if status_lbl:
		status_lbl.text = "Gareth White (Official Suite): %d active packages loaded from catalog." % all_packages.size()
		status_lbl.modulate = Color(0.4, 0.85, 1.0)
	_render_cards()

func _render_cards() -> void:
	if not container: return
	for c in container.get_children():
		c.queue_free()
	
	for pkg in all_packages:
		var pkg_id = str(pkg["id"])
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(280, 200)
		var vb = VBoxContainer.new()
		card.add_child(vb)
		
		var title = Label.new()
		title.text = str(pkg["name"])
		title.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(title)
		
		var author = Label.new()
		author.text = str(pkg["author"]) + " | " + str(pkg["tag"])
		vb.add_child(author)
		
		var spacer = Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vb.add_child(spacer)
		
		var btn_action = Button.new()
		btn_action.custom_minimum_size = Vector2(0, 40)
		if _is_installed(pkg_id):
			btn_action.text = "Uninstall"
			btn_action.modulate = Color(0.9, 0.4, 0.4)
			btn_action.pressed.connect(Callable(self, "_on_uninstall_pressed").bind(pkg_id, btn_action))
		else:
			btn_action.text = "Install"
			btn_action.modulate = Color(0.4, 0.9, 0.4)
			btn_action.pressed.connect(Callable(self, "_on_install_pressed").bind(pkg_id, btn_action))
		vb.add_child(btn_action)
		
		container.add_child(card)

func _is_installed(mod_id: String) -> bool:
	var expected_path = OS.get_executable_path().get_base_dir().path_join("mods").path_join(mod_id + ".zip")
	return FileAccess.file_exists(expected_path)

func _on_install_pressed(mod_id: String, btn: Button) -> void:
	btn.text = "Installing..."
	btn.disabled = true
	var c = find_child("ModStoreClient", true, false)
	if c: c.download_mod(mod_id)

func _on_uninstall_pressed(mod_id: String, btn: Button) -> void:
	var path = OS.get_executable_path().get_base_dir().path_join("mods").path_join(mod_id + ".zip")
	var file = FileAccess.open(path + ".pending_delete", FileAccess.WRITE)
	if file:
		file.store_string("DELETE_ON_BOOT")
		file.close()
	btn.text = "Restart Required"
	btn.disabled = true

func _on_close_pressed() -> void:
	queue_free()
"@
    $svContent | Set-Content -Path $storeViewPath -Encoding UTF8
    Write-Output "Patched mod_store_view.gd to execute completely dynamic UI."
}

Write-Output "--- 3. FIXING MOD MANAGER VIEW (BUG-05) ---"
$mgrViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
if (Test-Path $mgrViewPath) {
    git checkout 807de20 -- "$mgrViewPath"
    $mvContent = @"
extends Control

var container: GridContainer

func _ready() -> void:
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)

	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(header)
	
	var search = LineEdit.new()
	search.placeholder_text = "Search active mods..."
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.text_changed.connect(Callable(self, "_on_search_filter"))
	header.add_child(search)

	var close_btn = Button.new()
	close_btn.text = "Save & Close"
	close_btn.custom_minimum_size = Vector2(120, 40)
	close_btn.pressed.connect(Callable(self, "_on_close_pressed"))
	header.add_child(close_btn)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	container = GridContainer.new()
	container.columns = 3
	container.add_theme_constant_override("h_separation", 20)
	container.add_theme_constant_override("v_separation", 20)
	scroll.add_child(container)
	
	_render_cards()

func _render_cards() -> void:
	if not container: return
	for c in container.get_children(): c.queue_free()
	
	for mod_id in ModLoader.mod_data:
		var manifest = ModLoader.mod_data[mod_id].manifest
		var card = PanelContainer.new()
		card.name = mod_id
		card.custom_minimum_size = Vector2(280, 150)
		var vb = VBoxContainer.new()
		card.add_child(vb)
		
		var title = Label.new()
		title.text = manifest.name
		vb.add_child(title)
		
		var auth = Label.new()
		auth.text = _get_mod_category(manifest)
		vb.add_child(auth)
		
		container.add_child(card)

func _get_mod_category(manifest: Dictionary) -> String:
	if manifest and manifest.has("extra") and typeof(manifest["extra"]) == TYPE_DICTIONARY:
		if manifest["extra"].has("godot") and typeof(manifest["extra"]["godot"]) == TYPE_DICTIONARY:
			if manifest["extra"]["godot"].has("authors") and typeof(manifest["extra"]["godot"]["authors"]) == TYPE_ARRAY:
				var authors = manifest["extra"]["godot"]["authors"]
				if authors.size() > 0 and typeof(authors[0]) == TYPE_STRING and "Gareth White" in authors[0]:
					return "Gareth White (Official Suite)"
	return "Community Add-Ons"

func _on_search_filter(query: String) -> void:
	var q = query.to_lower()
	if is_instance_valid(container):
		for card in container.get_children():
			if q.is_empty():
				card.visible = true
			else:
				card.visible = q in card.name.to_lower()

func _on_close_pressed() -> void:
	queue_free()
"@
    $mvContent | Set-Content -Path $mgrViewPath -Encoding UTF8
    Write-Output "Patched mod_manager_view.gd with fully dynamic UI and search."
}

Write-Output "--- 4. REPACKING MOD MANAGER ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force -ErrorAction SilentlyContinue }

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

Write-Output "--- Committing to Git ---"
git add -A
git commit -m "Fix: Hardened Mod Store and Mod Manager UI to dynamically instantiate containers and sequentialized HTTP downloads."
git push origin main
Write-Output "Process Complete."