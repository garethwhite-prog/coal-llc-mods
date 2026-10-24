Clear-Host

# ==============================================================================
# Coal LLC - Master Repair: NaN Shield, Inventory Clear, HUD Separation, & Sprites
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 400

# ------------------------------------------------------------------------------
# 2. FIX ADDTOINVENTORY.GD (PREVENT NAN CASH & SLOT INFECTION)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Creating AddToInventory.hooks.gd (0g safety guard)..." -ForegroundColor Cyan
$atiHookDir = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\resources\BuyEffects\Scripts"
New-Item -ItemType Directory -Path $atiHookDir -Force | Out-Null

@'
extends Object

func buy_effect(chain: ModLoaderHookChain, shop_item: Item, count: int) -> void:
	if not shop_item:
		chain.execute_next([shop_item, count])
		return

	if Gvars and is_nan(Gvars.CashCount):
		Gvars.CashCount = 0.0

	var price: float = float(shop_item.itemBuyPrice)
	if price <= 0.0:
		var inventory: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
		if inventory:
			inventory.addToInventory(shop_item, count)
			inventory.emit_signal("inventory_changed")
			Bus.inventory_changed.emit()
		return

	chain.execute_next([shop_item, count])

func get_max_count(chain: ModLoaderHookChain, price: float, count: float) -> float:
	if price <= 0.0:
		return count
	if Gvars and is_nan(Gvars.CashCount):
		Gvars.CashCount = 0.0
	return chain.execute_next([price, count])
'@ | Set-Content -Path "$atiHookDir\AddToInventory.hooks.gd" -Encoding UTF8

# ------------------------------------------------------------------------------
# 3. FIX MOD_MANAGER_VIEW.GD & MOD_REGISTRY.GD (TYPED ARRAY ERROR)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Resolving Array[Dictionary] type mismatch in mod_manager_view.gd..." -ForegroundColor Cyan
$mmView = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
if (Test-Path $mmView) {
	$code = Get-Content $mmView -Raw
	$code = $code.Replace("var mods: Array[Dictionary] = registry_script.get_all_installed_mods()", "var mods: Array = registry_script.get_all_installed_mods()")
	Set-Content -Path $mmView -Value $code -Encoding UTF8
}

$regPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scripts\mod_registry.gd"
if (Test-Path $regPath) {
	$regCode = Get-Content $regPath -Raw
	$regCode = $regCode.Replace("static func get_all_mods() -> Array:", "static func get_all_mods() -> Array[Dictionary]:`r`n`tvar list: Array[Dictionary] = []")
	$regCode = $regCode.Replace("static func get_all_installed_mods() -> Array:", "static func get_all_installed_mods() -> Array[Dictionary]:")
	Set-Content -Path $regPath -Value $regCode -Encoding UTF8
}

# ------------------------------------------------------------------------------
# 4. FIX ELEMENTAL AIRSTRIKES MOD_MAIN.GD (EXTENDS NODE MUST BE LINE 1)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Fixing extends Node placement in elemental_airstrikes_mod..." -ForegroundColor Cyan
$eaMain = "$repo\mods-unpacked\gareth-elemental_airstrikes_mod\mods-unpacked\gareth-elemental_airstrikes_mod\mod_main.gd"
@'
extends Node

const MOD_DIR := "gareth-elemental_airstrikes_mod"

func _ready() -> void:
	var mgr_script = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/elemental_airstrike_manager.gd")
	var mgr = Node.new()
	mgr.name = "ElementalAirstrikeManager"
	mgr.set_script(mgr_script)
	get_tree().root.call_deferred("add_child", mgr)

	_register_elemental_items()
	ModLoaderLog.info("Elemental Airstrikes Triad active! (Dragon [7], Water Bomber [8], Agent Orange [9])", MOD_DIR)

func _register_elemental_items() -> void:
	var factory = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/texture_factory.gd")
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks or not ("all_equipment_items" in item_unlocks) or not factory:
		return

	var d_item = Item.new()
	d_item.itemID = "dragon_strike_whistle"
	d_item.itemName = "Dragon Strike Whistle"
	d_item.itemDescription = "Summon an ancient fiery dragon to carpet the mine in incendiary flame bursts."
	d_item.itemType = "equipment"
	d_item.itemBuyPrice = 45000.0
	d_item.itemSellPrice = 22500.0
	d_item.itemTexture = factory.create_dragon_texture()
	item_unlocks.all_equipment_items.append(d_item)

	var w_item = Item.new()
	w_item.itemID = "water_bomber_radio"
	w_item.itemName = "Water Bomber Radio"
	w_item.itemDescription = "Call in an amphibious water plane to drench strata with elemental wet cascades."
	w_item.itemType = "equipment"
	w_item.itemBuyPrice = 35000.0
	w_item.itemSellPrice = 17500.0
	w_item.itemTexture = factory.create_water_bomber_texture()
	item_unlocks.all_equipment_items.append(w_item)

	var p_item = Item.new()
	p_item.itemID = "agent_orange_transceiver"
	p_item.itemName = "Agent Orange Transceiver"
	p_item.itemDescription = "Order a heavy strategic bomber to deploy toxic chemical canisters across the dig site."
	p_item.itemType = "equipment"
	p_item.itemBuyPrice = 55000.0
	p_item.itemSellPrice = 27500.0
	p_item.itemTexture = factory.create_agent_orange_texture()
	item_unlocks.all_equipment_items.append(p_item)
'@ | Set-Content -Path $eaMain -Encoding UTF8

# ------------------------------------------------------------------------------
# 5. FIX AMAZON HUD POSITIONING & ORE INVENTORY WIPING
# ------------------------------------------------------------------------------
Write-Host "`n>>> 5. Updating amazon_delivery_manager.gd (HUD docking & inventory wipe)..." -ForegroundColor Cyan
$amzPath = "$repo\mods-unpacked\gareth-scrap_and_delivery_mod\mods-unpacked\gareth-scrap_and_delivery_mod\scripts\amazon_delivery_manager.gd"
$amzCode = Get-Content $amzPath -Raw

# Separate HUD coords: Amazon docks cleanly above Speed panel
$amzCode = $amzCode.Replace('hud_btn.offset_left = -264.0', 'hud_btn.offset_left = -110.0')
$amzCode = $amzCode.Replace('hud_btn.offset_right = -170.0', 'hud_btn.offset_right = -16.0')
$amzCode = $amzCode.Replace('hud_btn.offset_top = -48.0', 'hud_btn.offset_top = -88.0')
$amzCode = $amzCode.Replace('hud_btn.offset_bottom = -12.0', 'hud_btn.offset_bottom = -54.0')

# Direct inventory wiping and dual signaling
$oldScrapOre = @'
func _quick_scrap_from_shop() -> void:
	var inv: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
	if not inv or not Gvars:
		return
	var total_cash: float = 0.0
	var count_cleared: int = 0
	var empty_res = load("res://resources/Items/Empty.tres")
	for slot_item in inv.items:
		if not is_instance_valid(slot_item) or not is_instance_valid(slot_item.item) or slot_item.count <= 0:
			continue
		var it = slot_item.item
		var type_str = str(it.itemType).to_lower()
		if type_str in ["ore", "resource", "mineral", "material"]:
			var val = it.itemSellPrice * 0.5 if it.itemSellPrice > 0.0 else 5.0
			total_cash += val * slot_item.count
			count_cleared += int(slot_item.count)
			slot_item.count = 0
			if empty_res:
				slot_item.item = empty_res

	if total_cash > 0.0:
		if is_nan(Gvars.CashCount):
			Gvars.CashCount = 0.0
		Gvars.CashCount += total_cash
		Bus.inventory_changed.emit()
		show_toast("♻️ Scrapped %d ores for +$%.2f cash!" % [count_cleared, total_cash / 100.0])
		_render_catalog()
'@

$newScrapOre = @'
func _quick_scrap_from_shop() -> void:
	var inv: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
	if not inv or not Gvars:
		return
	var total_cash: float = 0.0
	var count_cleared: int = 0
	var empty_res = load("res://resources/Items/Empty.tres")

	for i in range(inv.items.size()):
		var slot_item = inv.items[i]
		if not is_instance_valid(slot_item) or not is_instance_valid(slot_item.item) or slot_item.count <= 0:
			continue
		var it = slot_item.item
		var type_str = str(it.itemType).to_lower()
		var id_str = str(it.itemID).to_lower()
		var is_ore = type_str in ["ore", "resource", "mineral", "material"] or "coal" in id_str or "copper" in id_str or "iron" in id_str
		if is_ore and type_str != "equipment" and type_str != "weapon":
			var val = it.itemSellPrice * 0.5 if it.itemSellPrice > 0.0 else 5.0
			total_cash += val * slot_item.count
			count_cleared += int(slot_item.count)
			slot_item.count = 0
			if empty_res:
				slot_item.item = empty_res

	if total_cash > 0.0:
		if is_nan(Gvars.CashCount):
			Gvars.CashCount = 0.0
		Gvars.CashCount += total_cash
		if inv.has_signal("inventory_changed"):
			inv.emit_signal("inventory_changed")
		Bus.inventory_changed.emit()
		show_toast("♻️ Scrapped %d ores for +$%.2f cash!" % [count_cleared, total_cash / 100.0])
		_render_catalog()
'@
$amzCode = $amzCode.Replace($oldScrapOre, $newScrapOre)
Set-Content -Path $amzPath -Value $amzCode -Encoding UTF8

# ------------------------------------------------------------------------------
# 6. REPLACE DONKEY KONG BOOT WITH PIXEL-ART GORILLA SPRITE
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Replacing boot placeholder with custom gorilla sprite in donkey_kong_mod..." -ForegroundColor Cyan
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
		gorilla.position.x += 60.0 * delta * gorilla.get_meta("dir", 1.0)
		if abs(gorilla.position.x) > 350.0:
			gorilla.set_meta("dir", -gorilla.get_meta("dir", 1.0))
			gorilla.scale.x = -abs(gorilla.scale.x) if gorilla.get_meta("dir", 1.0) > 0 else abs(gorilla.scale.x)

		barrel_timer += delta
		if barrel_timer >= 6.0:
			barrel_timer = 0.0
			_toss_barrel(tree.current_scene, gorilla.global_position)

func _spawn_gorilla(scene: Node) -> void:
	gorilla = Node2D.new()
	gorilla.name = "DonkeyKongGorilla"
	gorilla.global_position = Vector2(180, -28)
	gorilla.set_meta("dir", -1.0)

	var spr = Sprite2D.new()
	spr.texture = _create_gorilla_texture()
	spr.scale = Vector2(2.5, 2.5)
	gorilla.add_child(spr)
	scene.add_child(gorilla)

func _create_gorilla_texture() -> ImageTexture:
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var fur = Color(0.35, 0.20, 0.10, 1.0)
	var chest = Color(0.65, 0.45, 0.30, 1.0)
	var eye = Color(1.0, 1.0, 1.0, 1.0)
	for x in range(24):
		for y in range(24):
			if (y in range(4, 10) and x in range(7, 17)) or (y in range(10, 20) and x in range(4, 20)):
				img.set_pixel(x, y, fur)
			elif y in range(11, 17) and x in range(8, 16):
				img.set_pixel(x, y, chest)
			elif y in range(6, 8) and (x == 10 or x == 14):
				img.set_pixel(x, y, eye)
	return ImageTexture.create_from_image(img)

func _toss_barrel(scene: Node, pos: Vector2) -> void:
	var barrel = Area2D.new()
	barrel.name = "RollingBarrel"
	barrel.global_position = pos

	var spr = Sprite2D.new()
	spr.texture = load("res://assets/Equipment/bombs/big_bomb_sheet_red.png")
	spr.hframes = 4
	spr.scale = Vector2(1.8, 1.8)
	barrel.add_child(spr)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	barrel.add_child(col)

	barrel.body_entered.connect(func(body):
		if body.is_in_group("player") or body.name == "Player":
			if "velocity" in body:
				body.velocity = Vector2.ZERO
			body.set_physics_process(false)
			var tw = body.create_tween()
			tw.tween_interval(5.0)
			tw.tween_callback(func(): body.set_physics_process(true))
			barrel.queue_free()
	)

	scene.add_child(barrel)
	var b_tween = barrel.create_tween()
	b_tween.tween_property(barrel, "global_position:y", 600.0, 7.0)
	b_tween.tween_callback(barrel.queue_free)
'@ | Set-Content -Path $dkSpawner -Encoding UTF8

# ------------------------------------------------------------------------------
# 7. FIX MISSING SWORD AUDIO ASSET (SWORDHIT.WAV -> SWORDTHUD.WAV)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Pointing SwordHit.wav to SwordThud.wav in knight_class_mod..." -ForegroundColor Cyan
$kFiles = Get-ChildItem -Path "$repo\mods-unpacked\gareth-knight_class_mod" -Recurse -Include "*.gd", "*.tres"
foreach ($kf in $kFiles) {
	$txt = Get-Content $kf.FullName -Raw
	if ($txt.Contains("SwordHit.wav")) {
		$txt = $txt.Replace("SwordHit.wav", "SwordThud.wav")
		Set-Content -Path $kf.FullName -Value $txt -Encoding UTF8
		Write-Host "  Patched audio reference in: $($kf.Name)" -ForegroundColor Green
	}
}

# ------------------------------------------------------------------------------
# 8. REGISTER ALL NEW HOOKS IN MOD_MAIN.GD OF GARETH-MOD_MANAGER_MOD
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Ensuring hook installations in mod_manager_mod mod_main.gd..." -ForegroundColor Cyan
$mmmPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\mod_main.gd"
$mmmCode = Get-Content $mmmPath -Raw

if (-not $mmmCode.Contains("AddToInventory.hooks.gd")) {
	$mmmCode = $mmmCode.Replace(
		'func _init() -> void:',
		"func _init() -> void:`r`n`tModLoaderMod.install_script_hooks(`"res://resources/BuyEffects/Scripts/AddToInventory.gd`", `"res://mods-unpacked/gareth-mod_manager_mod/extensions/resources/BuyEffects/Scripts/AddToInventory.hooks.gd`")"
	)
	Set-Content -Path $mmmPath -Value $mmmCode -Encoding UTF8
}

# ------------------------------------------------------------------------------
# 9. RUN TESTS, REPACK & COMMIT
# ------------------------------------------------------------------------------
Write-Host "`n>>> 9. Running CI/CD validation..." -ForegroundColor Cyan
& "$repo\tests\test_runner.ps1" -RepoPath $repo
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host "`n>>> 10. Purging hook cache and repacking mod archives..." -ForegroundColor Cyan
if (Test-Path $hookZip) { Remove-Item -Path $hookZip -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem

$modsToRepack = @(
	"gareth-mod_manager_mod",
	"gareth-scrap_and_delivery_mod",
	"gareth-elemental_airstrikes_mod",
	"gareth-donkey_kong_mod",
	"gareth-knight_class_mod"
)

foreach ($m in $modsToRepack) {
	$src = "$repo\mods-unpacked\$m"
	$zip = "$steamMods\$m.zip"
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

Write-Host "`n>>> 11. Staging, committing and pushing to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Fix: Resolve AddToInventory NaN division, Mod Manager Array[Dictionary] type mismatch, elemental airstrikes compilation, Amazon HUD offset collision, and gorilla sprite"
git push origin main

Write-Host "`nAll fixes deployed and committed cleanly!" -ForegroundColor Green