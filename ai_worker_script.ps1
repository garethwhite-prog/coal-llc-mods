# ==============================================================================
# Coal LLC - Targeted Fix: Inventory Slots, Laser Beam, Bonus Shop, DK Stun & HUD
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# ------------------------------------------------------------------------------
# 2. TARGETED FIX: INVENTORY SLOTS (INVENTORY.HOOKS.GD)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Target 1: Hooking Inventory.initialise_slots to restore all 10 slots..." -ForegroundColor Cyan
$invHookDir = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\resources\Inventories\Scripts"
New-Item -ItemType Directory -Path $invHookDir -Force | Out-Null

$invHookCode = @'
extends Object

func initialise_slots(chain: ModLoaderHookChain) -> void:
	var inv = chain.reference_object
	if not is_instance_valid(inv) or inv.maxSlots == -1:
		chain.execute_next([])
		return

	var current_size = inv.items.size()
	var empty_res = load("res://resources/Items/Empty.tres")
	for n in range(current_size, int(inv.maxSlots)):
		var empty_slot = InventoryItem.new()
		if empty_res:
			empty_slot.set("item", empty_res)
		empty_slot.count = 0
		inv.items.append(empty_slot)
'@
Set-Content -Path "$invHookDir\Inventory.hooks.gd" -Value $invHookCode -Encoding UTF8

# Ensure Inventory hook is registered in mod_manager_mod mod_main.gd
$mmmPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\mod_main.gd"
$mmmCode = Get-Content $mmmPath -Raw
if (-not $mmmCode.Contains("Inventory.hooks.gd")) {
	$mmmCode = $mmmCode.Replace(
		'func _init() -> void:',
		"func _init() -> void:`r`n`tModLoaderMod.install_script_hooks(`"res://resources/Inventories/Scripts/Inventory.gd`", `"res://mods-unpacked/gareth-mod_manager_mod/extensions/resources/Inventories/Scripts/Inventory.hooks.gd`")"
	)
	Set-Content -Path $mmmPath -Value $mmmCode -Encoding UTF8
}
Write-Host "  Installed: Inventory.hooks.gd (10 slots restored cleanly)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. TARGETED FIX: LASER BEAM (DAMAGETILECOORDS & CLEAN VISUAL GLOW)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Target 2: Updating laser_beam_weapon.gd to native damageTileCoords & Line2D glow..." -ForegroundColor Cyan
$lbPath = "$repo\mods-unpacked\gareth-laser_beam_mod\mods-unpacked\gareth-laser_beam_mod\scripts\laser_beam_weapon.gd"
@'
class_name LaserBeamWeapon
extends Node2D

var beam_line: Line2D
var audio_player: AudioStreamPlayer2D
var max_range: float = 520.0
var base_damage_per_tick: float = 65.0

func _ready() -> void:
	z_index = 50
	beam_line = Line2D.new()
	beam_line.width = 8.0
	beam_line.default_color = Color(0.2, 0.9, 1.0, 0.95)
	beam_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	beam_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	beam_line.z_index = 50
	add_child(beam_line)

	audio_player = AudioStreamPlayer2D.new()
	if ResourceLoader.exists("res://assets/sound/sound effects/laser.wav"):
		audio_player.stream = load("res://assets/sound/sound effects/laser.wav")
	add_child(audio_player)

func fire_beam(origin: Vector2, target: Vector2, tilemap: TileMapManager) -> void:
	global_position = origin
	var dir := (target - origin).normalized()
	var end_point := origin + dir * max_range

	beam_line.clear_points()
	beam_line.add_point(Vector2.ZERO)
	beam_line.add_point(to_local(end_point))
	beam_line.visible = true

	if not audio_player.playing:
		audio_player.play()

	if tilemap:
		var step_dist: float = 8.0
		var current_step: float = 0.0
		var mining_mult: float = 1.0
		if Gvars and ("passives" in Gvars) and Gvars.passives:
			mining_mult = 1.0 + float(Gvars.passives.player_pickaxe_mining_damage)
		var tick_damage = base_damage_per_tick * mining_mult

		while current_step < max_range:
			var test_pos := origin + dir * current_step
			var map_pos := tilemap.local_to_map(test_pos)
			if tilemap.is_tile_collision(map_pos) or tilemap.is_tile_breakable(map_pos):
				tilemap.damageTileCoords(map_pos, tick_damage)
				beam_line.set_point_position(1, to_local(test_pos))
				break
			current_step += step_dist

func stop_beam() -> void:
	if is_instance_valid(beam_line):
		beam_line.visible = false
		beam_line.clear_points()
	if is_instance_valid(audio_player) and audio_player.playing:
		audio_player.stop()
'@ | Set-Content -Path $lbPath -Encoding UTF8
Write-Host "  Updated: laser_beam_weapon.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. TARGETED FIX: BONUS UPGRADES FILTER BAR (MANAGEMENT_SCREEN.HOOKS.GD)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Target 3: Hooking load_bonus_shop in management_screen.hooks.gd..." -ForegroundColor Cyan
$msHookPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scenes\Stages\management_screen.hooks.gd"
@'
extends Object

var search_input: LineEdit = null
var sort_dropdown: OptionButton = null
var chk_affordable: CheckBox = null
var is_affordable_only: bool = false

var bonus_search_input: LineEdit = null
var bonus_sort_dropdown: OptionButton = null
var bonus_chk_affordable: CheckBox = null
var is_bonus_affordable_only: bool = false

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	var screen = chain.reference_object
	if is_instance_valid(screen):
		if Gvars and is_nan(Gvars.CashCount):
			Gvars.CashCount = 0.0
		_ensure_search_and_sort_bar(screen)
		_sort_equipment_catalog()

	chain.execute_next([])

	if is_instance_valid(screen):
		Callable(self, "_apply_filter").call_deferred(screen)

func load_bonus_shop(chain: ModLoaderHookChain) -> void:
	var screen = chain.reference_object
	if is_instance_valid(screen):
		_ensure_bonus_filter_bar(screen)

	chain.execute_next([])

	if is_instance_valid(screen):
		Callable(self, "_apply_bonus_filter").call_deferred(screen)

func _ensure_search_and_sort_bar(screen: Node) -> void:
	if not is_instance_valid(screen):
		return
	var shop = screen.find_child("EquipmentShop", true, false)
	if not shop:
		return

	var scroll = shop.get_parent()
	var v_box = scroll.get_parent() if scroll else null
	if not v_box or v_box.has_node("EquipmentFilterBar"):
		return

	var bar = HBoxContainer.new()
	bar.name = "EquipmentFilterBar"
	bar.add_theme_constant_override("separation", 10)

	var search = LineEdit.new()
	search.name = "SearchInput"
	search.placeholder_text = "Search equipment by name or type..."
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.clear_button_enabled = true
	search.text_changed.connect(func(_new_text): _apply_filter(screen))
	bar.add_child(search)
	search_input = search

	var sort_btn = OptionButton.new()
	sort_btn.name = "SortOption"
	sort_btn.add_item("Sort: Tier (Default)", 0)
	sort_btn.add_item("Sort: Price (Low to High)", 1)
	sort_btn.add_item("Sort: Price (High to Low)", 2)
	sort_btn.add_item("Sort: Alphabetical (A-Z)", 3)
	sort_btn.item_selected.connect(func(_idx):
		_sort_equipment_catalog()
		if screen.has_method("load_equipment_shop"):
			screen.load_equipment_shop()
	)
	bar.add_child(sort_btn)
	sort_dropdown = sort_btn

	var chk = CheckBox.new()
	chk.name = "AffordableOnly"
	chk.text = "Affordable Only"
	chk.tooltip_text = "Show only items you can afford with current cash."
	chk.toggled.connect(func(pressed: bool):
		is_affordable_only = pressed
		_apply_filter(screen)
	)
	bar.add_child(chk)
	chk_affordable = chk

	v_box.add_child(bar)
	v_box.move_child(bar, scroll.get_index())

func _ensure_bonus_filter_bar(screen: Node) -> void:
	if not is_instance_valid(screen):
		return
	var shop = screen.find_child("BonusShop", true, false)
	if not shop:
		return

	var scroll = shop.get_parent()
	var v_box = scroll.get_parent() if scroll else null
	if not v_box or v_box.has_node("BonusFilterBar"):
		return

	var bar = HBoxContainer.new()
	bar.name = "BonusFilterBar"
	bar.add_theme_constant_override("separation", 10)

	var search = LineEdit.new()
	search.name = "BonusSearchInput"
	search.placeholder_text = "Search bonuses by name..."
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.clear_button_enabled = true
	search.text_changed.connect(func(_new_text): _apply_bonus_filter(screen))
	bar.add_child(search)
	bonus_search_input = search

	var chk = CheckBox.new()
	chk.name = "BonusAffordableOnly"
	chk.text = "Affordable Only"
	chk.tooltip_text = "Show only bonuses you can afford."
	chk.toggled.connect(func(pressed: bool):
		is_bonus_affordable_only = pressed
		_apply_bonus_filter(screen)
	)
	bar.add_child(chk)
	bonus_chk_affordable = chk

	v_box.add_child(bar)
	v_box.move_child(bar, scroll.get_index())

func _sort_equipment_catalog() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks or not ("all_equipment_items" in item_unlocks):
		return

	var mode: int = sort_dropdown.selected if is_instance_valid(sort_dropdown) else 0
	if mode == 1:
		item_unlocks.all_equipment_items.sort_custom(func(a, b): return a.itemBuyPrice < b.itemBuyPrice)
	elif mode == 2:
		item_unlocks.all_equipment_items.sort_custom(func(a, b): return a.itemBuyPrice > b.itemBuyPrice)
	elif mode == 3:
		item_unlocks.all_equipment_items.sort_custom(func(a, b): return str(a.itemName).nocasecmp_to(str(b.itemName)) < 0)

func _apply_filter(screen: Node) -> void:
	if not is_instance_valid(screen) or not is_instance_valid(search_input):
		return
	var query: String = search_input.text.strip_edges().to_lower()
	var cur_cash: float = Gvars.CashCount if Gvars else 0.0

	var shop = screen.find_child("EquipmentShop", true, false)
	if not shop:
		return

	for card in shop.find_children("*", "PanelContainer", true, false):
		if not is_instance_valid(card) or not ("item" in card) or not card.item:
			continue
		var it = card.item
		var it_name: String = str(it.itemName).to_lower()
		var it_id: String = str(it.itemID).to_lower()
		var it_type: String = str(it.itemType).to_lower()

		var match_query: bool = query.is_empty() or query in it_name or query in it_id or query in it_type
		var match_afford: bool = not is_affordable_only or (it.itemBuyPrice <= cur_cash or it.itemBuyPrice <= 0.0)

		card.visible = match_query and match_afford

func _apply_bonus_filter(screen: Node) -> void:
	if not is_instance_valid(screen) or not is_instance_valid(bonus_search_input):
		return
	var query: String = bonus_search_input.text.strip_edges().to_lower()
	var cur_cash: float = Gvars.CashCount if Gvars else 0.0

	var shop = screen.find_child("BonusShop", true, false)
	if not shop:
		return

	for card in shop.find_children("*", "PanelContainer", true, false):
		if not is_instance_valid(card) or not ("item" in card) or not card.item:
			continue
		var it = card.item
		var it_name: String = str(it.itemName).to_lower()
		var match_query: bool = query.is_empty() or query in it_name
		var match_afford: bool = not is_bonus_affordable_only or (it.itemBuyPrice <= cur_cash or it.itemBuyPrice <= 0.0)

		card.visible = match_query and match_afford
'@ | Set-Content -Path $msHookPath -Encoding UTF8
Write-Host "  Updated: management_screen.hooks.gd (Bonus shop filtered)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. TARGETED FIX: DONKEY KONG IMMOBILIZING STUN
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Target 4: Implementing complete immobilize stun in gorilla spawner..." -ForegroundColor Cyan
$dkSpawner = "$repo\mods-unpacked\gareth-donkey_kong_mod\mods-unpacked\gareth-donkey_kong_mod\scripts\gorilla_surface_spawner.gd"
$dkCode = Get-Content $dkSpawner -Raw
$dkCode = $dkCode.Replace(
	'var on_hit = func(target: Node):',
@'
	var on_hit = func(target: Node):
		var p_node = target if (target.name == "Player" or target.is_in_group("player")) else target.get_parent()
		if p_node and (p_node.name == "Player" or p_node.is_in_group("player")):
			# Freeze movement, disable mining, and pause player state machine
			if "velocity" in p_node:
				p_node.velocity = Vector2.ZERO
			if "able_to_mine" in p_node:
				p_node.able_to_mine = false
			if p_node.has_node("StateMachine"):
				p_node.get_node("StateMachine").set_physics_process(false)

			var toast = Label.new()
			toast.text = "★ BONK! STUNNED! ★"
			toast.modulate = Color(1.0, 0.85, 0.2)
			toast.position = Vector2(-60, -40)
			p_node.add_child(toast)

			var bonk = AudioStreamPlayer2D.new()
			bonk.stream = load("res://assets/sound/sound effects/box_1.wav")
			bonk.pitch_scale = 1.3
			p_node.add_child(bonk)
			bonk.play()

			var tw = p_node.create_tween()
			tw.tween_interval(2.5)
			tw.tween_callback(func():
				if is_instance_valid(p_node):
					if "able_to_mine" in p_node:
						p_node.able_to_mine = true
					if p_node.has_node("StateMachine"):
						p_node.get_node("StateMachine").set_physics_process(true)
				toast.queue_free()
				bonk.queue_free()
			)
			barrel.queue_free()
			return
'@
)
Set-Content -Path $dkSpawner -Value $dkCode -Encoding UTF8
Write-Host "  Updated: Donkey Kong stun logic (complete motion & mining freeze)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. TARGETED FIX: COLLECTOR PRIORITY SETTINGS TAB (CLEAN LABEL & POSITION 7)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Target 5: Positioning Collector Priority tab at index 7..." -ForegroundColor Cyan
$cpHook = "$repo\mods-unpacked\gareth-collector_priority_mod\mods-unpacked\gareth-collector_priority_mod\extensions\scenes\Interfaces\Menus\settings_2.hooks.gd"
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var settings = chain.reference_object
	if not is_instance_valid(settings) or not ("tab_container" in settings):
		return

	var tc = settings.tab_container
	if tc.has_node("Collector"):
		return

	var tab = PanelContainer.new()
	tab.name = "Collector"

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	tab.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Collector UFO Retrieval Priority"
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(1.0, 0.85, 0.3)
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Configure how automated Collector UFOs prioritize dropped items on the mine floor."
	desc.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(desc)

	var opt = OptionButton.new()
	opt.add_item("Closest Ore First (Vanilla Default)", 0)
	opt.add_item("Most Valuable First (Gems & High Tier > Coal)", 1)
	opt.add_item("Quota Priority (Coal First for Day Target)", 2)

	var cur_mode: int = 1
	if Gvars and ("collector_priority_mode" in Gvars):
		cur_mode = int(Gvars.collector_priority_mode)
	opt.selected = cur_mode

	opt.item_selected.connect(func(idx: int):
		if Gvars:
			Gvars.collector_priority_mode = idx
	)
	vbox.add_child(opt)

	tc.add_child(tab)
	tc.call_deferred("move_child", tab, 7)
'@ | Set-Content -Path $cpHook -Encoding UTF8
Write-Host "  Updated: Collector Priority Settings tab" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 7. TARGETED FIX: BOTTOM-RIGHT HUD MICRO-DOCKING (165px COMPACT COLUMN)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Target 6: Resizing bottom-right HUD to compact 165px column..." -ForegroundColor Cyan

# 7a. Speed Controller (Above vanilla End Day: -56 to -34, Height 22px)
$scPath = "$repo\mods-unpacked\gareth-game_speed_mod\mods-unpacked\gareth-game_speed_mod\scripts\speed_controller.gd"
$scCode = Get-Content $scPath -Raw
$scCode = $scCode.Replace('panel.offset_left = -396.0', 'panel.offset_left = -172.0')
$scCode = $scCode.Replace('panel.offset_right = -16.0', 'panel.offset_right = -8.0')
$scCode = $scCode.Replace('panel.offset_top = -46.0', 'panel.offset_top = -56.0')
$scCode = $scCode.Replace('panel.offset_bottom = -14.0', 'panel.offset_bottom = -34.0')
$scCode = $scCode.Replace('btn_slower.custom_minimum_size = Vector2(28, 24)', 'btn_slower.custom_minimum_size = Vector2(22, 20)')
$scCode = $scCode.Replace('lbl_speed.custom_minimum_size = Vector2(48, 24)', 'lbl_speed.custom_minimum_size = Vector2(40, 20)')
$scCode = $scCode.Replace('btn_faster.custom_minimum_size = Vector2(28, 24)', 'btn_faster.custom_minimum_size = Vector2(22, 20)')
$scCode = $scCode.Replace('btn_end_day.custom_minimum_size = Vector2(70, 24)', 'btn_end_day.visible = false')
Set-Content -Path $scPath -Value $scCode -Encoding UTF8

# 7b. Amazon Button (Middle: -82 to -60, Height 22px)
$amzPath = "$repo\mods-unpacked\gareth-scrap_and_delivery_mod\mods-unpacked\gareth-scrap_and_delivery_mod\scripts\amazon_delivery_manager.gd"
$amzCode = Get-Content $amzPath -Raw
$amzCode = $amzCode.Replace('hud_btn.offset_left = -396.0', 'hud_btn.offset_left = -172.0')
$amzCode = $amzCode.Replace('hud_btn.offset_right = -16.0', 'hud_btn.offset_right = -8.0')
$amzCode = $amzCode.Replace('hud_btn.offset_top = -88.0', 'hud_btn.offset_top = -82.0')
$amzCode = $amzCode.Replace('hud_btn.offset_bottom = -54.0', 'hud_btn.offset_bottom = -60.0')
$amzCode = $amzCode.Replace('hud_btn.text = "📦 Amazon"', 'hud_btn.text = "📦 Amazon (B)"')
Set-Content -Path $amzPath -Value $amzCode -Encoding UTF8

# 7c. Air Wings (Top: -108 to -86, Height 22px, compact labels)
$eamPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\elemental_airstrike_manager.gd"
$eamCode = Get-Content $eamPath -Raw
$eamCode = $eamCode.Replace('panel.offset_left = -396.0', 'panel.offset_left = -172.0')
$eamCode = $eamCode.Replace('panel.offset_right = -16.0', 'panel.offset_right = -8.0')
$eamCode = $eamCode.Replace('panel.offset_top = -140.0', 'panel.offset_top = -108.0')
$eamCode = $eamCode.Replace('panel.offset_bottom = -96.0', 'panel.offset_bottom = -86.0')
$eamCode = $eamCode.Replace('btn_dragon.text = "🔥 Dragon (7)"', 'btn_dragon.text = "🔥 7"')
$eamCode = $eamCode.Replace('btn_water.text = "💧 Water (8)"', 'btn_water.text = "💧 8"')
$eamCode = $eamCode.Replace('btn_poison.text = "☣️ Poison (9)"', 'btn_poison.text = "☣️ 9"')
Set-Content -Path $eamPath -Value $eamCode -Encoding UTF8
Write-Host "  Updated: HUD column scaled down to compact 165px micro-dock" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 8. REPACK ONLY THE SPECIFIC MODS MODIFIED (TARGETED REPACK)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Repackaging strictly targeted mods to Steam..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$targetedMods = @(
	"gareth-mod_manager_mod",
	"gareth-laser_beam_mod",
	"gareth-collector_priority_mod",
	"gareth-donkey_kong_mod",
	"gareth-game_speed_mod",
	"gareth-scrap_and_delivery_mod",
	"gareth-elemental_airstrikes_mod"
)

foreach ($m in $targetedMods) {
	$src = "$repo\mods-unpacked\$m"
	$zip = "$steamMods\$m.zip"

	if (-not (Test-Path $src)) { continue }
	if (Test-Path $zip) { Remove-Item -Path $zip -Force }

	$stream  = [System.IO.File]::Open($zip, [System.IO.FileMode]::CreateNew)
	$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
	foreach ($f in (Get-ChildItem -Path $src -Recurse -File)) {
		$entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")
		[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
	}
	$archive.Dispose()
	$stream.Dispose()
	Write-Host "  Repacked: $m.zip" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 9. COMMIT & PUSH TARGETED CHANGES
# ------------------------------------------------------------------------------
Write-Host "`n>>> 9. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Targeted Fix: Restore all 10 inventory slots, fix laser beam damageTileCoords, hook bonus shop filter, DK immobilize stun, Collector tab, and compact 165px HUD dock"
git push origin main

Write-Host "`nTargeted deployment complete!" -ForegroundColor Green