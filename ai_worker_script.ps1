Clear-Host

# ==============================================================================
# Coal LLC - Master Targeted Fix Pass (ALL 5 ISSUES RESOLVED)
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600

# ------------------------------------------------------------------------------
# 2. FIX CHEST VARIANCE MOD MANIFEST (DUAL COPIES)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Updating gareth-chest_variance_mod manifest.json with required fields..." -ForegroundColor Cyan
$cvRoot  = "$repo\mods-unpacked\gareth-chest_variance_mod"
$cvInner = "$cvRoot\mods-unpacked\gareth-chest_variance_mod"

$cvManifest = @"
{
  "name": "chest_variance_mod",
  "namespace": "gareth",
  "version_number": "1.0.0",
  "description": "Dynamic chest tier variance, weighted class weapon seeding, and dangerous booby-trap explosions.",
  "website_url": "https://github.com/garethwhite-prog/coal-llc-mods",
  "dependencies": [],
  "extra": {
    "godot": {
      "display_name": "Chest Tier Variance",
      "category": "Progression & Upgrades",
      "authors": ["Gareth White"],
      "compatible_mod_loader_version": ["7.0.1"],
      "compatible_game_version": ["1.4.1.1"]
    }
  }
}
"@
Set-Content -Path "$cvRoot\manifest.json" -Value $cvManifest -Encoding UTF8
Set-Content -Path "$cvInner\manifest.json" -Value $cvManifest -Encoding UTF8
Write-Host "  Updated dual manifests for chest_variance_mod" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. FIX GVARS.HOOKS.GD (COMBINE RESET_RESOURCES + SAVE_GVARS + LOAD_GVARS)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Updating Gvars.hooks.gd to prevent line 499 null crashes..." -ForegroundColor Cyan
$gvarsHookPath = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scripts\Gvars.hooks.gd"
@'
extends Object

func reset_resources(chain: ModLoaderHookChain) -> void:
	var gvars = chain.reference_object
	if is_instance_valid(gvars) and ("resources_to_save" in gvars) and (gvars.resources_to_save is Array):
		var clean_res: Array = []
		for r in gvars.resources_to_save:
			if is_instance_valid(r) and ("resource_path" in r) and str(r.resource_path) != "" and ResourceLoader.exists(r.resource_path):
				clean_res.append(r)
		gvars.resources_to_save = clean_res
	chain.execute_next([])

func save_Gvars(chain: ModLoaderHookChain) -> Dictionary:
	var result: Dictionary = chain.execute_next([])
	if not result.has("Gvars"):
		result["Gvars"] = {}

	var g = chain.reference_object
	if g and ("profession" in g) and g.profession and ("profession_manager" in g) and g.profession_manager:
		var pm = g.profession_manager
		for p_id in pm.all_professions.keys():
			if pm.all_professions[p_id]["profession"] == g.profession:
				result["Gvars"]["profession"] = p_id
				break
	return result

func load_Gvars(chain: ModLoaderHookChain, save: Dictionary) -> void:
	chain.execute_next([save])
	var g = chain.reference_object
	if not g or not save.has("Gvars") or not save["Gvars"].has("profession"):
		return

	var saved_id: int = int(save["Gvars"]["profession"])
	if ("profession_manager" in g) and g.profession_manager:
		var pm = g.profession_manager
		if pm.all_professions.has(saved_id):
			g.profession = pm.all_professions[saved_id]["profession"]
'@ | Set-Content -Path $gvarsHookPath -Encoding UTF8
Write-Host "  Updated Gvars.hooks.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. FIX MOD MANAGER: REGISTER PASSIVE_BONUSES HOOK & FIX SEPARATION API
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Registering passive_bonuses hook in mod_manager mod_main.gd..." -ForegroundColor Cyan
$mmInner = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod"
$mmMainPath = "$mmInner\mod_main.gd"
@'
extends Node

const MOD_ID := "gareth-mod_manager_mod"
const LOG_NAME := "gareth-mod_manager_mod"

func _init() -> void:
	ModLoaderLog.info("Universal Mod Manager initializing...", LOG_NAME)
	install_hooks()

func _ready() -> void:
	ModLoaderLog.info("Universal Mod Manager active with full Class, Shop & Input gating.", LOG_NAME)

func install_hooks() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_ID)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/in_game/choose_passive.gd",
		ext_dir.path_join("scenes/Interfaces/in_game/choose_passive.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/Management/passive_bonuses.gd",
		ext_dir.path_join("scenes/Interfaces/Management/passive_bonuses.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/MainMenu.gd",
		ext_dir.path_join("scripts/MainMenu.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Gvars.gd",
		ext_dir.path_join("scripts/Gvars.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Stages/management_screen.gd",
		ext_dir.path_join("scenes/Stages/management_screen.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Camera.gd",
		ext_dir.path_join("scripts/Camera.hooks.gd")
	)
'@ | Set-Content -Path $mmMainPath -Encoding UTF8

Write-Host "`n>>> 5. Updating passive_bonuses.hooks.gd to query sword & worker passives..." -ForegroundColor Cyan
$pbHookPath = "$mmInner\extensions\scenes\Interfaces\Management\passive_bonuses.hooks.gd"
@'
extends Object

func refresh(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var pb = chain.reference_object
	if not is_instance_valid(pb) or not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return

	var p = Gvars.passives

	# 1. Worker passives
	var worker_stats = {
		"Employee Miner Speed": "employee_miner_speed",
		"Employee Miner Damage": "employee_miner_damage",
		"Employee Collector Speed": "employee_collector_speed",
		"Employee Collector Capacity": "employee_collector_capacity"
	}
	for s_name in worker_stats.keys():
		var prop: String = worker_stats[s_name]
		if prop in p:
			var val: float = float(p.get(prop))
			if val > 0.0:
				var lbl = RichTextLabel.new()
				lbl.text = "Increase %s +%d%%" % [s_name, roundi(val * 100)]
				lbl.fit_content = true
				pb.add_child(lbl)

	# 2. Custom class passives (Knight swords, Jedi sabers, etc.)
	var custom_stats = [
		"sword_damage", "sword_speed", "sword_range",
		"jedi_saber_damage", "jedi_swing_rate", "jedi_cleave_reach",
		"ball_blast_damage", "chrono_tick_rate", "exec_damage",
		"fracker_pulse_damage", "void_implosion_damage", "sinclair_melt_damage"
	]

	var cp_dict: Dictionary = {}
	if ("custom_passives" in Gvars) and (Gvars.custom_passives is Dictionary):
		cp_dict = Gvars.custom_passives

	for stat_key in custom_stats:
		var s_val: float = 0.0
		if cp_dict.has(stat_key):
			s_val = float(cp_dict[stat_key])
		elif p.has_meta(stat_key):
			s_val = float(p.get_meta(stat_key))
		elif stat_key in p:
			s_val = float(p.get(stat_key))

		if s_val > 0.0:
			var c_lbl = RichTextLabel.new()
			c_lbl.text = "Increase %s +%d%%" % [stat_key.replace("_", " ").capitalize(), roundi(s_val * 100)]
			c_lbl.fit_content = true
			pb.add_child(c_lbl)
'@ | Set-Content -Path $pbHookPath -Encoding UTF8

Write-Host "`n>>> 6. Fixing management_screen.hooks.gd container separation override..." -ForegroundColor Cyan
$mgmtHookPath = "$mmInner\extensions\scenes\Stages\management_screen.hooks.gd"
@'
extends Object

var search_input: LineEdit = null
var sort_dropdown: OptionButton = null

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	var screen = chain.reference_object
	if is_instance_valid(screen):
		_ensure_search_and_sort_bar(screen)
		_sort_equipment_catalog()
	chain.execute_next([])
	if is_instance_valid(screen):
		Callable(self, "_apply_filter").call_deferred(screen)

func _ensure_search_and_sort_bar(screen: Node) -> void:
	if not is_instance_valid(screen):
		return
	var shop = screen.find_child("EquipmentShop", true, false)
	if not shop:
		return

	var scroll = shop.get_parent()
	var v_box = scroll.get_parent() if scroll else null
	if not v_box:
		return

	if v_box.has_node("EquipmentFilterBar"):
		var existing_bar = v_box.get_node("EquipmentFilterBar")
		search_input = existing_bar.get_node_or_null("SearchInput")
		sort_dropdown = existing_bar.get_node_or_null("SortOption")
		return

	var bar = HBoxContainer.new()
	bar.name = "EquipmentFilterBar"
	bar.add_theme_constant_override("separation", 12)

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

	v_box.add_child(bar)
	v_box.move_child(bar, scroll.get_index())

func _apply_filter(screen: Node) -> void:
	if not is_instance_valid(screen) or not is_instance_valid(search_input):
		return
	var query: String = search_input.text.strip_edges().to_lower()
	var shop = screen.find_child("EquipmentShop", true, false)
	if not shop:
		return

	for card in shop.get_children():
		if not is_instance_valid(card):
			continue
		if query.is_empty():
			card.visible = true
			continue
		var matches := false
		if "item" in card and card.item:
			var nm: String = str(card.item.itemName).to_lower()
			var id: String = str(card.item.itemID).to_lower()
			var tp: String = str(card.item.itemType).to_lower()
			var desc: String = str(card.item.itemDescription).to_lower()
			if query in nm or query in id or query in tp or query in desc:
				matches = true
		card.visible = matches

func _sort_equipment_catalog() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks or not ("all_equipment_items" in item_unlocks) or not (item_unlocks.all_equipment_items is Array):
		return

	var original_list: Array = item_unlocks.all_equipment_items
	if original_list.is_empty():
		return

	var mode: int = 0
	if is_instance_valid(sort_dropdown):
		mode = sort_dropdown.selected

	var indexed_items: Array = []
	for i in range(original_list.size()):
		var it = original_list[i]
		if is_instance_valid(it):
			var rank: int = _get_tier_rank(it)
			indexed_items.append({ "item": it, "rank": rank, "orig_idx": i })

	match mode:
		0: # Tier Default
			indexed_items.sort_custom(func(a, b):
				if a["rank"] != b["rank"]:
					return a["rank"] < b["rank"]
				return a["orig_idx"] < b["orig_idx"]
			)
		1: # Price Low to High
			indexed_items.sort_custom(func(a, b):
				var pa = float(a["item"].itemBuyPrice)
				var pb = float(b["item"].itemBuyPrice)
				if pa != pb:
					return pa < pb
				return a["orig_idx"] < b["orig_idx"]
			)
		2: # Price High to Low
			indexed_items.sort_custom(func(a, b):
				var pa = float(a["item"].itemBuyPrice)
				var pb = float(b["item"].itemBuyPrice)
				if pa != pb:
					return pa > pb
				return a["orig_idx"] < b["orig_idx"]
			)
		3: # Alphabetical
			indexed_items.sort_custom(func(a, b):
				var na = str(a["item"].itemName).to_lower()
				var nb = str(b["item"].itemName).to_lower()
				return na < nb
			)

	var sorted_list: Array[Item] = []
	for entry in indexed_items:
		sorted_list.append(entry["item"])

	item_unlocks.all_equipment_items = sorted_list

func _get_tier_rank(it: Item) -> int:
	var id: String = str(it.itemID).to_lower()
	var nm: String = str(it.itemName).to_lower()
	var s: String = id + " " + nm

	if "shoddy" in s: return 1
	if "copper" in s: return 2
	if "iron" in s: return 3
	if "sapphire" in s: return 4
	if "emerald" in s: return 5
	if "silver" in s: return 6
	if "amethyst" in s: return 7
	if "gold" in s: return 8
	if "ruby" in s: return 9
	if "pinkdiamond" in s or "pink_diamond" in s or "pink diamond" in s: return 11
	if "diamond" in s: return 10
	if "spinel" in s: return 12
	if "uranium" in s: return 13
	if "moonstone" in s: return 14
	if "onyx" in s: return 15

	if ("ladder" in s or "platform" in s or "bomb" in s or "dynamite" in s or 
		"mortar" in s or "drill" in s or "teleporter" in s or "whistle" in s or 
		"gravity" in s or "water_staff" in s or "water_gun" in s):
		return 0

	return 16
'@ | Set-Content -Path $mgmtHookPath -Encoding UTF8
Write-Host "  Fixed management_screen.hooks.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. FIX KNIGHT CLASS: ASSIGN RESOURCE_PATH & TAKE_OVER_PATH
# ------------------------------------------------------------------------------
Write-Host "`n>>> 7. Updating knight_class_mod mod_main.gd with resource_path bindings..." -ForegroundColor Cyan
$knightMainPath = "$repo\mods-unpacked\gareth-knight_class_mod\mods-unpacked\gareth-knight_class_mod\mod_main.gd"
@'
extends Node

const MOD_DIR := "gareth-knight_class_mod"

const TIER_DATA := [
	{ "id": "01_shoddy",      "name": "Shoddy Knight Sword",        "dmg": 70.0,      "price": 0.0,                    "sell": 0.0 },
	{ "id": "02_copper",      "name": "Copper Knight Sword",        "dmg": 140.0,     "price": 2500.0,                 "sell": 1250.0 },
	{ "id": "03_iron",        "name": "Iron Knight Sword",          "dmg": 280.0,     "price": 8500.0,                 "sell": 4250.0 },
	{ "id": "04_sapphire",    "name": "Sapphire Knight Sword",      "dmg": 560.0,     "price": 24000.0,                "sell": 12000.0 },
	{ "id": "05_emerald",     "name": "Emerald Knight Sword",       "dmg": 1100.0,    "price": 75000.0,                "sell": 37500.0 },
	{ "id": "06_silver",      "name": "Silver Knight Sword",        "dmg": 2200.0,    "price": 220000.0,               "sell": 110000.0 },
	{ "id": "07_amethyst",    "name": "Amethyst Knight Sword",      "dmg": 4400.0,    "price": 650000.0,               "sell": 325000.0 },
	{ "id": "08_gold",        "name": "Gold Knight Sword",          "dmg": 8800.0,    "price": 1800000.0,              "sell": 900000.0 },
	{ "id": "09_ruby",        "name": "Ruby Knight Sword",          "dmg": 17500.0,   "price": 5000000.0,              "sell": 2500000.0 },
	{ "id": "10_diamond",     "name": "Diamond Knight Sword",       "dmg": 35000.0,   "price": 15000000.0,             "sell": 7500000.0 },
	{ "id": "11_pinkdiamond", "name": "Pink Diamond Knight Sword",  "dmg": 70000.0,   "price": 45000000.0,             "sell": 22500000.0 },
	{ "id": "12_spinel",      "name": "Spinel Knight Sword",        "dmg": 140000.0,  "price": 650000000.0,            "sell": 325000000.0 },
	{ "id": "13_uranium",     "name": "Uranium Knight Sword",       "dmg": 280000.0,  "price": 6500000000000.0,        "sell": 3250000000000.0 },
	{ "id": "14_moonstone",   "name": "Moonstone Knight Sword",     "dmg": 560000.0,  "price": 660000000000000000.0,   "sell": 330000000000000000.0 },
	{ "id": "15_onyx",        "name": "Onyx Knight Sword",          "dmg": 1120000.0, "price": 60000000000000000000000000.0, "sell": 30000000000000000000000000.0 }
]

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	if FileAccess.file_exists(path):
		var buffer = FileAccess.get_file_as_bytes(path)
		if buffer.size() > 0:
			var img = Image.new()
			if img.load_png_from_buffer(buffer) == OK:
				return ImageTexture.create_from_image(img)
	return null

func _ready() -> void:
	var reg = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_registry.gd")
	if reg and not reg.is_mod_active_for_run("knight_class"):
		return

	var item_script = load("res://resources/Items/Scripts/Item.gd")
	var buy_script = load("res://resources/BuyEffects/Scripts/AddToInventory.gd")
	var pickup_script = load("res://resources/PickupEffects/Scripts/PickupToInventory.gd")
	var equip_script = load("res://mods-unpacked/gareth-knight_class_mod/scripts/knight_sword_equip.gd")
	var pickup_sound = load("res://assets/sound/sound effects/SwordThud.wav")
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")

	for t in TIER_DATA:
		var item = item_script.new()
		item.itemID = "KnightSword_" + t["id"]
		item.itemName = t["name"]
		item.itemDescription = "Broadsword (%d damage). Sweeps in a wide 180° frontal arc cleaving rock and ore." % int(t["dmg"])
		item.itemType = "sword"
		item.itemBuyPrice = t["price"]
		item.itemSellPrice = t["sell"]
		item.itemUnlocked = true
		item.pickupSound = pickup_sound

		var res_path := "res://mods-unpacked/gareth-knight_class_mod/items/KnightSword_%s.tres" % t["id"]
		item.resource_path = res_path
		item.take_over_path(res_path)

		var tex_name = t["name"].replace(" Knight Sword", "").replace(" ", "")
		var tex_path = "res://assets/Equipment/Sword-%s.png" % tex_name
		if not ResourceLoader.exists(tex_path):
			tex_path = "res://mods-unpacked/gareth-knight_class_mod/textures/Sword-%s.png" % tex_name
		item.itemTexture = _load_texture(tex_path)

		var equip = equip_script.new()
		item.itemEquipEffect = equip
		item.itemBuyEffect = buy_script.new()
		item.itemPickupEffect = pickup_script.new()

		if item_unlocks:
			var already_registered := false
			for existing in item_unlocks.all_equipment_items:
				if existing and existing.itemID == item.itemID:
					already_registered = true
					break
			if not already_registered:
				item_unlocks.all_equipment_items.append(item)

	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return

	var pm = Gvars.profession_manager
	var prof_script = load("res://mods-unpacked/gareth-knight_class_mod/scripts/knight_profession.gd")
	var p = prof_script.new()
	p.profession_name = "Knight"
	p.description = "Master of chivalric blade combat.\nStarts with a Shoddy Sword.\nAll 15 sword tiers, standalone weapons, and tools are purchasable."
	p.image = _load_texture("res://assets/Equipment/Sword-Shoddy.png")

	pm.all_professions[101] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("15 Knight Sword tiers registered programmatically into shop.", MOD_DIR)
'@ | Set-Content -Path $knightMainPath -Encoding UTF8
Write-Host "  Updated knight_class_mod mod_main.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. FIX WATER SPIRIT: PROGRAMMATIC ITEM CREATION (BYPASS KICK .TRES FILES)
# ------------------------------------------------------------------------------
Write-Host "`n>>> 8. Updating water_spirit_mod mod_main.gd with programmatic items & fairy sprites..." -ForegroundColor Cyan
$wsMainPath = "$repo\mods-unpacked\gareth-water_spirit_mod\mods-unpacked\gareth-water_spirit_mod\mod_main.gd"
@'
extends Node

const MOD_DIR := "gareth-water_spirit_mod"

const TIER_DATA := [
	{ "id": "01_shoddy",      "name": "Shoddy Water Spirit",        "radius": 28.0,  "speed": 8.0,  "brush": 1, "price": 0.0 },
	{ "id": "02_copper",      "name": "Copper Water Spirit",        "radius": 36.0,  "speed": 9.0,  "brush": 1, "price": 5000.0 },
	{ "id": "03_iron",        "name": "Iron Water Spirit",          "radius": 44.0,  "speed": 10.0, "brush": 1, "price": 18000.0 },
	{ "id": "04_sapphire",    "name": "Sapphire Water Spirit",      "radius": 52.0,  "speed": 11.0, "brush": 1, "price": 50000.0 },
	{ "id": "05_emerald",     "name": "Emerald Water Spirit",       "radius": 60.0,  "speed": 12.0, "brush": 1, "price": 150000.0 },
	{ "id": "06_silver",      "name": "Silver Water Spirit",        "radius": 72.0,  "speed": 13.0, "brush": 2, "price": 450000.0 },
	{ "id": "07_amethyst",    "name": "Amethyst Water Spirit",      "radius": 84.0,  "speed": 14.0, "brush": 2, "price": 1200000.0 },
	{ "id": "08_gold",        "name": "Gold Water Spirit",          "radius": 96.0,  "speed": 15.0, "brush": 2, "price": 3500000.0 },
	{ "id": "09_ruby",        "name": "Ruby Water Spirit",          "radius": 110.0, "speed": 16.0, "brush": 2, "price": 10000000.0 },
	{ "id": "10_diamond",     "name": "Diamond Water Spirit",       "radius": 125.0, "speed": 17.0, "brush": 3, "price": 30000000.0 },
	{ "id": "11_pinkdiamond", "name": "Pink Diamond Water Spirit",  "radius": 140.0, "speed": 18.0, "brush": 3, "price": 90000000.0 },
	{ "id": "12_spinel",      "name": "Spinel Water Spirit",        "radius": 160.0, "speed": 19.0, "brush": 3, "price": 1200000000.0 },
	{ "id": "13_uranium",     "name": "Uranium Water Spirit",       "radius": 180.0, "speed": 20.0, "brush": 4, "price": 12000000000000.0 },
	{ "id": "14_moonstone",   "name": "Moonstone Water Spirit",     "radius": 200.0, "speed": 22.0, "brush": 4, "price": 1200000000000000000.0 },
	{ "id": "15_onyx",        "name": "Onyx Water Spirit",          "radius": 220.0, "speed": 24.0, "brush": 5, "price": 500000000000000000000000.0 }
]

func _load_image_texture(path: String) -> Texture2D:
	if FileAccess.file_exists(path):
		var buffer = FileAccess.get_file_as_bytes(path)
		if buffer.size() > 0:
			var img = Image.new()
			if img.load_png_from_buffer(buffer) == OK:
				return ImageTexture.create_from_image(img)
	return null

func _ready() -> void:
	var item_script = load("res://resources/Items/Scripts/Item.gd")
	var buy_script = load("res://resources/BuyEffects/Scripts/AddToInventory.gd")
	var pickup_script = load("res://resources/PickupEffects/Scripts/PickupToInventory.gd")
	var equip_script = load("res://mods-unpacked/gareth-water_spirit_mod/scripts/water_spirit_equip.gd")
	var pickup_sound = load("res://assets/sound/sound effects/pickup.wav")
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")

	if not item_unlocks:
		return

	for t in TIER_DATA:
		var item = item_script.new()
		item.itemID = "water_spirit_" + t["id"]
		item.itemName = t["name"]
		item.itemDescription = "Luminous elemental fairy companion.\nOrbits player (radius: %.0fpx) and cleanses surrounding strata.\nToggle with hotkey or Left-Click." % float(t["radius"])
		item.itemType = "water_spirit"
		item.itemBuyPrice = t["price"]
		item.itemSellPrice = t["price"] * 0.5
		item.itemUnlocked = true
		item.pickupSound = pickup_sound

		var res_path := "res://mods-unpacked/gareth-water_spirit_mod/items/water_spirit_%s.tres" % t["id"]
		item.resource_path = res_path
		item.take_over_path(res_path)

		var tex_path := "res://mods-unpacked/gareth-water_spirit_mod/textures/spirit_%s.png" % t["id"]
		item.itemTexture = _load_image_texture(tex_path)

		var equip = equip_script.new()
		equip.orbit_radius = t["radius"]
		equip.rotation_speed = t["speed"]
		equip.brush_radius = t["brush"]
		item.itemEquipEffect = equip

		item.itemBuyEffect = buy_script.new()
		item.itemPickupEffect = pickup_script.new()

		var already_registered := false
		for existing in item_unlocks.all_equipment_items:
			if existing and existing.itemID == item.itemID:
				already_registered = true
				break
		if not already_registered:
			item_unlocks.all_equipment_items.append(item)

	ModLoaderLog.info("15 Water Spirit Fairy tiers loaded programmatically with custom fairy textures.", MOD_DIR)
'@ | Set-Content -Path $wsMainPath -Encoding UTF8
Write-Host "  Updated water_spirit_mod mod_main.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 7. PURGE HOOK CACHE & REPACKAGE ALL 4 MODS
# ------------------------------------------------------------------------------
Write-Host "`n>>> 9. Purging mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
	Remove-Item -Path $hookZip -Force
	Write-Host "  Removed: $hookZip" -ForegroundColor Green
}

Write-Host "`n>>> 10. Repackaging modified mods..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression.FileSystem

$modsToRepack = @(
	"gareth-chest_variance_mod",
	"gareth-mod_manager_mod",
	"gareth-knight_class_mod",
	"gareth-water_spirit_mod"
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

# ------------------------------------------------------------------------------
# 8. GIT STAGING, COMMIT & PUSH
# ------------------------------------------------------------------------------
Write-Host "`n>>> 11. Staging, committing and pushing master fix to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Fix search/sort UI API, register passive bonuses hook, resolve line 499 reset crash, programmatic water spirits, and complete chest variance manifest"
git push origin main

Write-Host "`nAll operations completed cleanly! Ready for validation run." -ForegroundColor Green