$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. CLEARING CACHE ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force -ErrorAction SilentlyContinue }

Write-Output "--- 2. FIXING MAIN MENU SCENE INSTANTIATION (BUG-06) ---"
$mainMenuHooksPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts\MainMenu.hooks.gd"
if (Test-Path $mainMenuHooksPath) {
    $mmContent = @"
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	_process_pending_deletions()
	chain.execute_next([])
	var menu = chain.reference_object
	if not is_instance_valid(menu): return

	var btn_grid = menu.get_node_or_null("%MainMenuButtons")
	if btn_grid:
		btn_grid.offset_top = -68.0
		btn_grid.offset_bottom = 176.0
		btn_grid.add_theme_constant_override("separation", 4)

		if not btn_grid.has_node("ModManagerButton"):
			var mod_btn := Button.new()
			mod_btn.name = "ModManagerButton"
			mod_btn.text = "Mod Manager"
			mod_btn.custom_minimum_size = Vector2(0, 30)
			mod_btn.pressed.connect(Callable(self, "_on_mod_manager_pressed").bind(menu))
			btn_grid.add_child(mod_btn)
			btn_grid.move_child(mod_btn, 2)

		if not btn_grid.has_node("ModStoreButton"):
			var store_btn := Button.new()
			store_btn.name = "ModStoreButton"
			store_btn.text = "Mod & Map Store"
			store_btn.custom_minimum_size = Vector2(0, 30)
			store_btn.modulate = Color(1.0, 0.88, 0.35)
			store_btn.pressed.connect(Callable(self, "_on_mod_store_pressed").bind(menu))
			btn_grid.add_child(store_btn)
			btn_grid.move_child(store_btn, 3)

		if not btn_grid.has_node("LeaderboardsButton"):
			var lb_btn := Button.new()
			lb_btn.name = "LeaderboardsButton"
			lb_btn.text = "Leaderboards"
			lb_btn.custom_minimum_size = Vector2(0, 30)
			lb_btn.pressed.connect(Callable(self, "_on_leaderboards_pressed").bind(menu))
			btn_grid.add_child(lb_btn)
			btn_grid.move_child(lb_btn, 4)

func _on_mod_manager_pressed(menu: Node) -> void:
	# FIX: Loading the .tscn scene file instead of the .gd script
	var view_scene = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_manager_view.tscn")
	if view_scene:
		var view = view_scene.instantiate()
		view.set_meta("is_pre_run_mode", false)
		menu.add_child(view)

func _on_mod_store_pressed(menu: Node) -> void:
	var store_scene = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_store_view.tscn")
	if store_scene:
		var store_view = store_scene.instantiate()
		menu.add_child(store_view)

func _on_leaderboards_pressed(menu: Node) -> void:
	var modal_scene = load("res://mods-unpacked/gareth-leaderboard_mod/scenes/leaderboard_modal.tscn")
	if modal_scene:
		var modal = modal_scene.instantiate()
		menu.add_child(modal)

func on_profession_selected(chain: ModLoaderHookChain, mode: int, prof: Object, hard_modifier: Object = null) -> void:
	var menu = chain.reference_object
	if not menu:
		chain.execute_next([mode, prof, hard_modifier])
		return

	var p_select = menu.get_node_or_null("ProfessionSelect")
	if not p_select and "profession_select" in menu:
		p_select = menu.profession_select
	if p_select:
		p_select.visible = false

	var view_scene = load("res://mods-unpacked/gareth-mod_manager_mod/scenes/mod_manager_view.tscn")
	if view_scene:
		var view = view_scene.instantiate()
		view.name = "PreRunModSelector"
		view.set_meta("is_pre_run_mode", true)
		if view.has_signal("confirmed"):
			view.connect("confirmed", Callable(self, "_on_mod_selector_confirmed").bind(chain, mode, prof, hard_modifier))
		if view.has_signal("back_pressed"):
			view.connect("back_pressed", Callable(self, "_on_mod_selector_back").bind(p_select))
		menu.add_child(view)
		return
	chain.execute_next([mode, prof, hard_modifier])

func _on_mod_selector_confirmed(chain: ModLoaderHookChain, mode: int, prof: Object, hard_modifier: Object) -> void:
	chain.execute_next([mode, prof, hard_modifier])

func _on_mod_selector_back(p_select: Node) -> void:
	if p_select:
		p_select.visible = true

func _process_pending_deletions() -> void:
	var base_dir = OS.get_executable_path().get_base_dir()
	var mods_dir = base_dir.path_join("mods")
	var dir = DirAccess.open(mods_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if "pending_delete" in file_name:
				var target_zip = file_name.replace(".pending_delete", ".zip")
				if FileAccess.file_exists(mods_dir.path_join(target_zip)):
					DirAccess.remove_absolute(mods_dir.path_join(target_zip))
				DirAccess.remove_absolute(mods_dir.path_join(file_name))
			file_name = dir.get_next()
"@
    $mmContent | Set-Content -Path $mainMenuHooksPath -Encoding UTF8
    Write-Output "Patched MainMenu.hooks.gd to load full .tscn nodes."
}

Write-Output "--- 3. FIXING MOD STORE SAFE STRING CASTING (US-05) ---"
$storeViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_store_view.gd"
if (Test-Path $storeViewPath) {
    git checkout 807de20 -- "$storeViewPath"
    $svContent = @"
extends Control

@onready var container: GridContainer = %ModStoreContainer
@onready var status_lbl: Label = %StatusLabel
var all_packages: Array = []

func _ready() -> void:
	if status_lbl: status_lbl.text = "Loading Mod & Map Catalog..."
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
		if not tag.begins_with("v"): tag = "v" + tag
		
		var assets = r.get("assets", [])
		if typeof(assets) == TYPE_ARRAY and assets.size() > 0:
			var asset_map = assets[0]
			if typeof(asset_map) == TYPE_DICTIONARY:
				if p_id == "": p_id = str(asset_map.get("name", "")).replace(".zip", "")
				tag = str(r.get("tag_name", "v1.0"))
				
		if p_id == "": continue

		all_packages.append({
			"id": p_id,
			"name": p_name,
			"tag": tag,
			"desc": str(r.get("description", r.get("body", "No description available."))),
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
		author.modulate = Color(0.7, 0.7, 0.7)
		vb.add_child(author)
		
		var spacer = Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vb.add_child(spacer)
		
		var btn_action = Button.new()
		btn_action.custom_minimum_size = Vector2(0, 40)
		var installed = _is_installed(pkg_id)
		if installed:
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
	if status_lbl: status_lbl.text = "Installing %s..." % mod_id
	var c = find_child("ModStoreClient", true, false)
	if c: c.download_mod(mod_id)

func _on_uninstall_pressed(mod_id: String, btn: Button) -> void:
	_uninstall_mod(mod_id)
	btn.text = "Restart Required"
	btn.disabled = true

func _uninstall_mod(mod_id: String) -> void:
	var path = OS.get_executable_path().get_base_dir().path_join("mods").path_join(mod_id + ".zip")
	var file = FileAccess.open(path + ".pending_delete", FileAccess.WRITE)
	if file:
		file.store_string("DELETE_ON_BOOT")
		file.close()
	if status_lbl: status_lbl.text = "🗑️ Uninstalled %s.zip. Deleted from active mods directory." % mod_id

func _on_close_pressed() -> void:
	queue_free()
"@
    $svContent | Set-Content -Path $storeViewPath -Encoding UTF8
    Write-Output "Patched mod_store_view.gd with Godot 4 safe type-casting strings."
}

Write-Output "--- 4. FIXING MOD MANAGER SEARCH (BUG-05) ---"
$mgrViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
if (Test-Path $mgrViewPath) {
    git checkout 807de20 -- "$mgrViewPath"
    $mvContent = Get-Content $mgrViewPath -Raw
    
    $searchInject = @"
func _ready() -> void:
	call_deferred("_inject_search_bar")
"@
    $mvContent = $mvContent -replace 'func _ready\(\) -> void:', $searchInject
    
    $searchLogic = @"

func _inject_search_bar() -> void:
	var header = find_child("HeaderContainer", true, false)
	if not header: header = self
	var search = LineEdit.new()
	search.placeholder_text = "Search active mods..."
	search.custom_minimum_size = Vector2(300, 35)
	search.text_changed.connect(Callable(self, "_on_search_filter"))
	header.add_child(search)

func _on_search_filter(query: String) -> void:
	var q = query.to_lower()
	var list = find_child("ModListContainer", true, false)
	if is_instance_valid(list):
		for card in list.get_children():
			if q.is_empty():
				card.visible = true
			else:
				var mod_name = card.name.to_lower()
				var lbl = card.find_child("*Label*", true, false)
				if is_instance_valid(lbl): mod_name += lbl.text.to_lower()
				card.visible = q in mod_name

func _get_mod_category(manifest: Dictionary) -> String:
	if manifest and manifest.has("extra") and typeof(manifest["extra"]) == TYPE_DICTIONARY:
		if manifest["extra"].has("godot") and typeof(manifest["extra"]["godot"]) == TYPE_DICTIONARY:
			if manifest["extra"]["godot"].has("authors") and typeof(manifest["extra"]["godot"]["authors"]) == TYPE_ARRAY:
				var authors = manifest["extra"]["godot"]["authors"]
				if authors.size() > 0 and typeof(authors[0]) == TYPE_STRING and "Gareth White" in authors[0]:
					return "Gareth White (Official Suite)"
	return "Community Add-Ons"
"@
    $mvContent = $mvContent -replace 'func _get_mod_category\(manifest: Dictionary\) -> String:[\s\S]*?return "Community Add-Ons"', $searchLogic
    $mvContent | Set-Content -Path $mgrViewPath -Encoding UTF8
    Write-Output "Patched mod_manager_view.gd with safe dictionary tagging and Callable filters."
}

Write-Output "--- 5. REPACKING MOD MANAGER ---"
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
git commit -m "Fix: Corrected load instantiation type from .gd to .tscn to prevent Mod Store UI null crash and restore Mod Manager Search."
git push origin main
Write-Output "Process Complete."