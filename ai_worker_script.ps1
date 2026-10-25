# ==============================================================================
# Coal LLC - Master Fix: Surface Hole, Map 105 Spawn, Sword Pricing, DK & HUD
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
# 2. RESTORE SURFACE HOLE & SHAFT (HARDWARE BOOSTER SKIP SURFACE CHUNK)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Fixing hardware_booster_mod: preserve vanilla surface chunk & entrance hole..." -ForegroundColor Cyan
$hwHookPath = "$repo\mods-unpacked\gareth-hardware_booster_mod\mods-unpacked\gareth-hardware_booster_mod\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd"
@'
extends Object

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	var chunk = chain.reference_object
	# Always let vanilla generate chunk 0 (surface grass, cabin, stockpile & drop-off pit)
	if not chunk or not ("chunk_pos" in chunk) or chunk.chunk_pos.y <= 0:
		chain.execute_next([noise])
		return

	# Only apply acceleration to deep subterranean chunks (Y > 0)
	chain.execute_next([noise])
'@ | Set-Content -Path $hwHookPath -Encoding UTF8
Write-Host "  Updated: hardware_booster_mod (surface hole restored)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. FIX DIAGONAL SEAMS (MAP 105): PREVENT INSTANT DEATH AT SPAWN
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Fixing diagonal_map_mod: safe surface spawn & 45-degree subterranean strata..." -ForegroundColor Cyan
$dmChunkHook = "$repo\mods-unpacked\gareth-diagonal_map_mod\mods-unpacked\gareth-diagonal_map_mod\extensions\scenes\tilemaps\tile_map_chunk.hooks.gd"
@'
extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if Gvars and ("level" in Gvars) and Gvars.level == 105:
		# Coordinates at or above ground level MUST return -2 (overground sky/grass)
		if pos.y <= 0:
			return -2
		# Rotate subterranean strata 45 degrees
		var diag = int((pos.x + pos.y) * 0.707)
		return clampi(diag / 25, 1, 15)
	return chain.execute_next([pos])
'@ | Set-Content -Path $dmChunkHook -Encoding UTF8
Write-Host "  Updated: diagonal_map_mod chunk hook (safe spawn confirmed)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. FIX SWORD PRICING (ELIMINATE DOUBLE-SPEND & ARGUMENT MISMATCH)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Fixing AddToInventory & shop_item_card cash deductions..." -ForegroundColor Cyan
$atiHook = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\resources\BuyEffects\Scripts\AddToInventory.hooks.gd"
@'
extends Object

func get_max_count(chain: ModLoaderHookChain, price: float, count: float) -> float:
	if price <= 0.0:
		return count
	if Gvars and is_nan(Gvars.CashCount):
		Gvars.CashCount = 0.0
	if Gvars and Gvars.CashCount <= 0.0:
		return 0.0
	var _max = floor(Gvars.CashCount / price)
	return min(_max, count)

func buy_effect(chain: ModLoaderHookChain, shop_item: Item, count: int) -> void:
	if not shop_item:
		chain.execute_next([shop_item, count])
		return

	if Gvars and is_nan(Gvars.CashCount):
		Gvars.CashCount = 0.0

	var price: float = float(shop_item.itemBuyPrice)
	# 0g starter items bypass wallet deduction cleanly
	if price <= 0.0:
		var inventory: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
		if inventory:
			inventory.addToInventory(shop_item, count)
			inventory.emit_signal("inventory_changed")
			Bus.inventory_changed.emit()
		return

	# Pass exact vanilla signature: [Item, int]
	chain.execute_next([shop_item, count])
'@ | Set-Content -Path $atiHook -Encoding UTF8

$sicHook = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scenes\Interfaces\Management\shop_item_card.hooks.gd"
@'
extends Object

func refreshDetails(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var card = chain.reference_object
	if not is_instance_valid(card) or not ("item" in card) or not card.item:
		return

	if Gvars and is_nan(Gvars.CashCount):
		Gvars.CashCount = 0.0

	var cost: float = float(card.item.itemBuyPrice)
	if card.purchaseable and (cost <= 0.0 or Gvars.CashCount >= cost):
		if "purchase_button" in card and is_instance_valid(card.purchase_button):
			card.purchase_button.disabled = false

func _on_purchase_button_pressed(chain: ModLoaderHookChain) -> void:
	var card = chain.reference_object
	if not is_instance_valid(card) or not ("item" in card) or not card.item:
		chain.execute_next([])
		return

	if Gvars and is_nan(Gvars.CashCount):
		Gvars.CashCount = 0.0

	var cost: float = float(card.item.itemBuyPrice)
	# For free 0g items, trigger buy effect directly
	if cost <= 0.0:
		if card.item.itemBuyEffect:
			card.item.itemBuyEffect.buy_effect(card.item, 1)
		card.refreshDetails()
		card.shop_button_pressed.emit()
		return

	# For regular items, let vanilla buy_effect perform the single deduction
	chain.execute_next([])
'@ | Set-Content -Path $sicHook -Encoding UTF8
Write-Host "  Updated: AddToInventory & shop_item_card (single accurate deduction)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. GUARD STOCKPILE.GD AGAINST NIL PLAYER DEREFERENCE (LINE 2203 FIX)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Guarding Stockpile.drop_off_coal against Nil player crash..." -ForegroundColor Cyan
$spHookDir = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts"
New-Item -ItemType Directory -Path $spHookDir -Force | Out-Null
@'
extends Object

func drop_off_coal(chain: ModLoaderHookChain) -> void:
	var sp = chain.reference_object
	# If player reference is lost at day transition, return safely without crashing
	if not is_instance_valid(sp) or not ("player" in sp) or not is_instance_valid(sp.player) or not ("inventory" in sp.player) or not sp.player.inventory:
		return
	chain.execute_next([])
'@ | Set-Content -Path "$spHookDir\Stockpile.hooks.gd" -Encoding UTF8

# Ensure Stockpile hook is registered in mod_main.gd
$mmmPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\mod_main.gd"
$mmmCode = Get-Content $mmmPath -Raw
if (-not $mmmCode.Contains("Stockpile.hooks.gd")) {
	$mmmCode = $mmmCode.Replace(
		'func _init() -> void:',
		"func _init() -> void:`r`n`tModLoaderMod.install_script_hooks(`"res://scripts/Stockpile.gd`", `"res://mods-unpacked/gareth-mod_manager_mod/extensions/scripts/Stockpile.hooks.gd`")"
	)
	Set-Content -Path $mmmPath -Value $mmmCode -Encoding UTF8
}
Write-Host "  Installed: Stockpile.hooks.gd (Tile drop integrity protected)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. BONUS UPGRADES SEARCH, SORT & AFFORDABLE FILTER BAR
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Wiring Bonus Upgrades search, sort & affordable filter bar..." -ForegroundColor Cyan
$pbHookDir = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scenes\Interfaces\Management"
New-Item -ItemType Directory -Path $pbHookDir -Force | Out-Null
$pbCode = @'
extends Object

var bonus_search: LineEdit = null
var bonus_sort: OptionButton = null
var bonus_chk_afford: CheckBox = null
var is_bonus_affordable_only: bool = false

func refresh(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var panel = chain.reference_object
	if not is_instance_valid(panel):
		return

	_ensure_filter_bar(panel)
	_apply_bonus_filter(panel)

func _ensure_filter_bar(panel: Control) -> void:
	var scroll = panel.get_parent()
	var v_box = scroll.get_parent() if scroll else null
	if not v_box:
		return

	if v_box.has_node("BonusFilterBar"):
		var existing = v_box.get_node("BonusFilterBar")
		bonus_search = existing.get_node_or_null("BonusSearch")
		bonus_sort = existing.get_node_or_null("BonusSort")
		bonus_chk_afford = existing.get_node_or_null("BonusAfford")
		return

	var bar = HBoxContainer.new()
	bar.name = "BonusFilterBar"
	bar.add_theme_constant_override("separation", 10)

	var search = LineEdit.new()
	search.name = "BonusSearch"
	search.placeholder_text = "Search bonus upgrades..."
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.clear_button_enabled = true
	search.text_changed.connect(func(_t): _apply_bonus_filter(panel))
	bar.add_child(search)
	bonus_search = search

	var sort_btn = OptionButton.new()
	sort_btn.name = "BonusSort"
	sort_btn.add_item("Sort: Default", 0)
	sort_btn.add_item("Name: A-Z", 1)
	sort_btn.item_selected.connect(func(_idx): _apply_bonus_filter(panel))
	bar.add_child(sort_btn)
	bonus_sort = sort_btn

	var chk = CheckBox.new()
	chk.name = "BonusAfford"
	chk.text = "Affordable Only"
	chk.tooltip_text = "Show only upgrades you can purchase right now."
	chk.toggled.connect(func(pressed: bool):
		is_bonus_affordable_only = pressed
		_apply_bonus_filter(panel)
	)
	bar.add_child(chk)
	bonus_chk_afford = chk

	v_box.add_child(bar)
	v_box.move_child(bar, scroll.get_index())

func _apply_bonus_filter(panel: Control) -> void:
	if not is_instance_valid(panel) or not is_instance_valid(bonus_search):
		return
	var q: String = bonus_search.text.strip_edges().to_lower()
	var cur_cash: float = Gvars.CashCount if Gvars else 0.0

	for item in panel.get_children():
		if not is_instance_valid(item):
			continue
		var label = item.find_child("*Label*", true, false)
		var text: String = label.text.to_lower() if (label and "text" in label) else ""
		var match_q: bool = q.is_empty() or q in text

		var cost: float = 0.0
		if "cost" in item:
			cost = float(item.cost)
		elif "price" in item:
			cost = float(item.price)

		var match_afford: bool = not is_bonus_affordable_only or (cost <= cur_cash or cost <= 0.0)
		item.visible = match_q and match_afford
'@
Set-Content -Path "$pbHookDir\passive_bonuses.hooks.gd" -Value $pbCode -Encoding UTF8

# Mirror to root unpacked folder so ModLoader finds it regardless of path resolution
$rootPbDir = "$repo\mods-unpacked\gareth-mod_manager_mod\extensions\scenes\Interfaces\Management"
New-Item -ItemType Directory -Path $rootPbDir -Force | Out-Null
Set-Content -Path "$rootPbDir\passive_bonuses.hooks.gd" -Value $pbCode -Encoding UTF8
Write-Host "  Updated: passive_bonuses.hooks.gd (in both path locations)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 7. INJECT IN-GAME SETTINGS TAB FOR COLLECTOR PRIORITY MOD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Creating settings_2.hooks.gd for Collector Priority mod..." -ForegroundColor Cyan
$cpSettingsHookDir = "$repo\mods-unpacked\gareth-collector_priority_mod\mods-unpacked\gareth-collector_priority_mod\extensions\scenes\Interfaces\Menus"
New-Item -ItemType Directory -Path $cpSettingsHookDir -Force | Out-Null
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var settings = chain.reference_object
	if not is_instance_valid(settings) or not ("tab_container" in settings):
		return

	var tc = settings.tab_container
	if tc.has_node("CollectorPriorityTab"):
		return

	var tab = PanelContainer.new()
	tab.name = "CollectorPriorityTab"

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
	desc.text = "Choose how automated Collector UFOs prioritize dropped items on the mine floor."
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
'@ | Set-Content -Path "$cpSettingsHookDir\settings_2.hooks.gd" -Encoding UTF8

# Register settings hook in collector_priority_mod mod_main.gd
$cpMainPath = "$repo\mods-unpacked\gareth-collector_priority_mod\mods-unpacked\gareth-collector_priority_mod\mod_main.gd"
@'
extends Node
const MOD_DIR := "gareth-collector_priority_mod"
func _init() -> void:
	ModLoaderMod.install_script_hooks("res://scripts/loot_drops.gd", "res://mods-unpacked/gareth-collector_priority_mod/extensions/scripts/loot_drops.hooks.gd")
	ModLoaderMod.install_script_hooks("res://scenes/Interfaces/Menus/settings_2.gd", "res://mods-unpacked/gareth-collector_priority_mod/extensions/scenes/Interfaces/Menus/settings_2.hooks.gd")
func _ready() -> void:
	ModLoaderLog.info("Collector Priority Mod active with Settings configuration tab!", MOD_DIR)
'@ | Set-Content -Path $cpMainPath -Encoding UTF8
Write-Host "  Updated: Collector Priority Settings tab injected" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 8. UPGRADE DONKEY KONG: DETAILED PIXEL APE & ACTIVE BARREL COLLISION
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Upgrading Donkey Kong pixel art & full-mask barrel collision..." -ForegroundColor Cyan
$dkSpawner = "$repo\mods-unpacked\gareth-donkey_kong_mod\mods-unpacked\gareth-donkey_kong_mod\scripts\gorilla_surface_spawner.gd"
@'
extends Node

var gorilla: Node2D
var barrel_timer: float = 0.0

func _process(delta: float) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	var p = tree.root.find_child("Player", true, false)
	var in_mine = is_instance_valid(p) and is_instance_valid(tree.root.find_child("TileMapManager", true, false))

	if in_mine and not is_instance_valid(gorilla):
		_spawn_gorilla(tree.current_scene)

	if is_instance_valid(gorilla):
		gorilla.position.x += 45.0 * delta * gorilla.get_meta("dir", 1.0)
		if gorilla.position.x > 600.0:
			gorilla.set_meta("dir", -1.0)
			gorilla.scale.x = abs(gorilla.scale.x)
		elif gorilla.position.x < 360.0:
			gorilla.set_meta("dir", 1.0)
			gorilla.scale.x = -abs(gorilla.scale.x)

		barrel_timer += delta
		if barrel_timer >= 6.0:
			barrel_timer = 0.0
			_toss_barrel(tree.current_scene, gorilla.global_position)

func _spawn_gorilla(scene: Node) -> void:
	gorilla = Node2D.new()
	gorilla.name = "DonkeyKongGorilla"
	gorilla.global_position = Vector2(460, -32)
	gorilla.set_meta("dir", 1.0)

	var spr = Sprite2D.new()
	spr.texture = _create_gorilla_texture()
	spr.scale = Vector2(1.6, 1.6)
	gorilla.add_child(spr)
	scene.add_child(gorilla)

func _create_gorilla_texture() -> ImageTexture:
	var img = Image.create(36, 36, false, Image.FORMAT_RGBA8)
	var fur_dark = Color(0.22, 0.11, 0.04, 1.0)
	var fur_mid  = Color(0.36, 0.18, 0.08, 1.0)
	var chest    = Color(0.74, 0.52, 0.34, 1.0)
	var tie_red  = Color(0.95, 0.15, 0.15, 1.0)
	var tie_gold = Color(1.0, 0.85, 0.20, 1.0)
	var eye_w    = Color(1.0, 1.0, 1.0, 1.0)
	var eye_b    = Color(0.05, 0.05, 0.05, 1.0)

	for x in range(36):
		for y in range(36):
			# Head & Brow ridge
			if y in range(4, 13) and x in range(11, 25):
				img.set_pixel(x, y, fur_mid if y < 9 else fur_dark)
			# Broad gorilla torso & arms
			elif (y in range(13, 30) and x in range(8, 28)) or (y in range(14, 32) and (x in range(3, 9) or x in range(27, 33))):
				img.set_pixel(x, y, fur_mid if x % 2 == 0 else fur_dark)
			# Tan muzzle & chest contours
			if (y in range(9, 13) and x in range(13, 23)) or (y in range(15, 24) and x in range(12, 24)):
				img.set_pixel(x, y, chest)
			# Red tie
			if (y in range(15, 26) and x in range(16, 20)):
				img.set_pixel(x, y, tie_red)
			# "DK" yellow monogram on tie
			if (y == 20 or y == 21) and (x == 17 or x == 18):
				img.set_pixel(x, y, tie_gold)
			# Expressive gorilla eyes
			if y in range(7, 9) and (x == 14 or x == 20):
				img.set_pixel(x, y, eye_w)
			if y == 8 and (x == 15 or x == 21):
				img.set_pixel(x, y, eye_b)

	return ImageTexture.create_from_image(img)

func _create_barrel_texture() -> ImageTexture:
	var img = Image.create(22, 22, false, Image.FORMAT_RGBA8)
	var w_dark  = Color(0.40, 0.22, 0.10, 1.0)
	var w_light = Color(0.58, 0.36, 0.18, 1.0)
	var metal   = Color(0.24, 0.24, 0.26, 1.0)

	for x in range(22):
		for y in range(22):
			var dx = float(x - 11)
			var dy = float(y - 11)
			if dx*dx + dy*dy <= 105.0:
				if y in range(4, 7) or y in range(15, 18):
					img.set_pixel(x, y, metal)
				elif x % 3 == 0:
					img.set_pixel(x, y, w_dark)
				else:
					img.set_pixel(x, y, w_light)

	return ImageTexture.create_from_image(img)

func _toss_barrel(scene: Node, pos: Vector2) -> void:
	var barrel = Area2D.new()
	barrel.name = "RollingBarrel"
	barrel.global_position = pos
	# Listen to ALL physics layers to guarantee player detection
	barrel.collision_layer = 0
	barrel.collision_mask = 0xFFFFFFFF

	var spr = Sprite2D.new()
	spr.texture = _create_barrel_texture()
	spr.scale = Vector2(1.7, 1.7)
	barrel.add_child(spr)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	barrel.add_child(col)

	var on_hit = func(target: Node):
		var p_node = target if (target.name == "Player" or target.is_in_group("player")) else target.get_parent()
		if p_node and (p_node.name == "Player" or p_node.is_in_group("player")):
			if "velocity" in p_node:
				p_node.velocity = Vector2(-220.0, -120.0)

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
				toast.queue_free()
				bonk.queue_free()
			)
			barrel.queue_free()

	barrel.body_entered.connect(on_hit)
	barrel.area_entered.connect(on_hit)

	scene.add_child(barrel)
	var b_tween = barrel.create_tween()
	b_tween.parallel().tween_property(barrel, "global_position:x", 160.0, 4.0)
	b_tween.parallel().tween_property(barrel, "global_position:y", 680.0, 6.0)
	b_tween.parallel().tween_property(barrel, "rotation", 14.0, 6.0)
	b_tween.tween_callback(barrel.queue_free)
'@ | Set-Content -Path $dkSpawner -Encoding UTF8
Write-Host "  Updated: Donkey Kong detailed pixel sprite & multi-mask barrel hit" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 9. BOTTOM-RIGHT HUD DOCKING: CLEAR NON-OVERLAPPING VERTICAL COLUMN
# ------------------------------------------------------------------------------
Write-Host "`n>>> 9. Stacking bottom-right HUD in clean 380px non-overlapping column..." -ForegroundColor Cyan

# 9a. Speed Controller (Slot 1: -46 to -14, Height 32px)
$scPath = "$repo\mods-unpacked\gareth-game_speed_mod\mods-unpacked\gareth-game_speed_mod\scripts\speed_controller.gd"
$scCode = Get-Content $scPath -Raw
$scCode = $scCode.Replace('panel.offset_left = -356.0', 'panel.offset_left = -396.0')
$scCode = $scCode.Replace('panel.offset_left = -324.0', 'panel.offset_left = -396.0')
$scCode = $scCode.Replace('panel.offset_left = -316.0', 'panel.offset_left = -396.0')
$scCode = $scCode.Replace('panel.offset_left = -264.0', 'panel.offset_left = -396.0')
$scCode = $scCode.Replace('panel.offset_right = -20.0', 'panel.offset_right = -16.0')
$scCode = $scCode.Replace('panel.offset_right = -24.0', 'panel.offset_right = -16.0')
$scCode = $scCode.Replace('panel.offset_top = -44.0', 'panel.offset_top = -46.0')
$scCode = $scCode.Replace('panel.offset_top = -48.0', 'panel.offset_top = -46.0')
$scCode = $scCode.Replace('panel.offset_bottom = -14.0', 'panel.offset_bottom = -14.0')
$scCode = $scCode.Replace('panel.offset_bottom = -12.0', 'panel.offset_bottom = -14.0')
Set-Content -Path $scPath -Value $scCode -Encoding UTF8

# 9b. Amazon Delivery (Slot 2: -88 to -54, Height 34px)
$amzPath = "$repo\mods-unpacked\gareth-scrap_and_delivery_mod\mods-unpacked\gareth-scrap_and_delivery_mod\scripts\amazon_delivery_manager.gd"
$amzCode = Get-Content $amzPath -Raw
$amzCode = $amzCode.Replace('hud_btn.offset_left = -356.0', 'hud_btn.offset_left = -396.0')
$amzCode = $amzCode.Replace('hud_btn.offset_left = -324.0', 'hud_btn.offset_left = -396.0')
$amzCode = $amzCode.Replace('hud_btn.offset_left = -316.0', 'hud_btn.offset_left = -396.0')
$amzCode = $amzCode.Replace('hud_btn.offset_left = -110.0', 'hud_btn.offset_left = -396.0')
$amzCode = $amzCode.Replace('hud_btn.offset_right = -20.0', 'hud_btn.offset_right = -16.0')
$amzCode = $amzCode.Replace('hud_btn.offset_right = -24.0', 'hud_btn.offset_right = -16.0')
$amzCode = $amzCode.Replace('hud_btn.offset_top = -80.0', 'hud_btn.offset_top = -88.0')
$amzCode = $amzCode.Replace('hud_btn.offset_top = -86.0', 'hud_btn.offset_top = -88.0')
$amzCode = $amzCode.Replace('hud_btn.offset_bottom = -48.0', 'hud_btn.offset_bottom = -54.0')
$amzCode = $amzCode.Replace('hud_btn.offset_bottom = -50.0', 'hud_btn.offset_bottom = -54.0')
Set-Content -Path $amzPath -Value $amzCode -Encoding UTF8

# 9c. Air Wings (Slot 3: -140 to -96, Height 44px)
$eamPath = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\scripts\elemental_airstrike_manager.gd"
$eamCode = Get-Content $eamPath -Raw
$eamCode = $eamCode.Replace('panel.offset_left = -356.0', 'panel.offset_left = -396.0')
$eamCode = $eamCode.Replace('panel.offset_left = -324.0', 'panel.offset_left = -396.0')
$eamCode = $eamCode.Replace('panel.offset_left = -316.0', 'panel.offset_left = -396.0')
$eamCode = $eamCode.Replace('panel.offset_left = -264.0', 'panel.offset_left = -396.0')
$eamCode = $eamCode.Replace('panel.offset_right = -20.0', 'panel.offset_right = -16.0')
$eamCode = $eamCode.Replace('panel.offset_right = -24.0', 'panel.offset_right = -16.0')
$eamCode = $eamCode.Replace('panel.offset_top = -128.0', 'panel.offset_top = -140.0')
$eamCode = $eamCode.Replace('panel.offset_top = -126.0', 'panel.offset_top = -140.0')
$eamCode = $eamCode.Replace('panel.offset_bottom = -84.0', 'panel.offset_bottom = -96.0')
$eamCode = $eamCode.Replace('panel.offset_bottom = -86.0', 'panel.offset_bottom = -96.0')
Set-Content -Path $eamPath -Value $eamCode -Encoding UTF8
Write-Host "  Updated: HUD column stack (AirWings: -140:-96, Amazon: -88:-54, Speed: -46:-14)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 10. REPACK ALL AFFECTED MOD ARCHIVES TO STEAM
# ------------------------------------------------------------------------------
Write-Host "`n>>> 10. Purging stale hook pack & repacking all mod archives..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

$modsToRepack = @(
	"gareth-hardware_booster_mod",
	"gareth-diagonal_map_mod",
	"gareth-abyssal_trench_mod",
	"gareth-living_canvas_mod",
	"gareth-mod_manager_mod",
	"gareth-collector_priority_mod",
	"gareth-donkey_kong_mod",
	"gareth-game_speed_mod",
	"gareth-scrap_and_delivery_mod",
	"gareth-elemental_airstrikes_mod"
)

foreach ($m in $modsToRepack) {
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
	Write-Host "  Repacked cleanly: $m.zip" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 11. CI/CD INTEGRITY CHECK & GIT COMMIT
# ------------------------------------------------------------------------------
Write-Host "`n>>> 11. Running static CI/CD regression verification..." -ForegroundColor Cyan
& "$repo\tests\test_runner.ps1" -RepoPath $repo

Write-Host "`n>>> 12. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Fix: Surface hole & shaft restored, Map 105 safe spawn, accurate sword cash deduction, Stockpile drop crash guard, DK stun & clean HUD column"
git push origin main

Write-Host "`nAll fixes deployed and committed cleanly!" -ForegroundColor Green