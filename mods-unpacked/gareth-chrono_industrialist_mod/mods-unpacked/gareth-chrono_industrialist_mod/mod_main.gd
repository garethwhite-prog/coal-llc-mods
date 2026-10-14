extends Node

const MOD_DIR := "gareth-chrono_industrialist_mod"

var starter_weapon = null
var all_chrono_items: Array = []

const TIER_DATA := [
	{ "id": "01_shoddy",      "name": "Shoddy Chrono Harvester",        "dmg": 70.0,    "rate": 0.20,  "price": 0.0 },
	{ "id": "02_copper",      "name": "Copper Chrono Harvester",        "dmg": 100.0,   "rate": 0.19,  "price": 350.0 },
	{ "id": "03_iron",        "name": "Iron Chrono Harvester",          "dmg": 140.0,   "rate": 0.18,  "price": 1800.0 },
	{ "id": "04_sapphire",    "name": "Sapphire Chrono Harvester",      "dmg": 200.0,   "rate": 0.17,  "price": 9500.0 },
	{ "id": "05_emerald",     "name": "Emerald Chrono Harvester",       "dmg": 290.0,   "rate": 0.16,  "price": 45000.0 },
	{ "id": "06_silver",      "name": "Silver Chrono Harvester",        "dmg": 420.0,   "rate": 0.15,  "price": 200000.0 },
	{ "id": "07_amethyst",    "name": "Amethyst Chrono Harvester",      "dmg": 600.0,   "rate": 0.14,  "price": 850000.0 },
	{ "id": "08_gold",        "name": "Gold Chrono Harvester",          "dmg": 880.0,   "rate": 0.13,  "price": 4000000.0 },
	{ "id": "09_ruby",        "name": "Ruby Chrono Harvester",          "dmg": 1300.0,  "rate": 0.12,  "price": 20000000.0 },
	{ "id": "10_diamond",     "name": "Diamond Chrono Harvester",       "dmg": 1950.0,  "rate": 0.11,  "price": 100000000.0 },
	{ "id": "11_pinkdiamond", "name": "Pink Diamond Chrono Harvester",  "dmg": 3000.0,  "rate": 0.10,  "price": 600000000.0 },
	{ "id": "12_spinel",      "name": "Spinel Chrono Harvester",        "dmg": 4700.0,  "rate": 0.09,  "price": 3500000000.0 },
	{ "id": "13_uranium",     "name": "Uranium Chrono Harvester",       "dmg": 7400.0,  "rate": 0.08,  "price": 25000000000.0 },
	{ "id": "14_moonstone",   "name": "Moonstone Chrono Harvester",     "dmg": 11800.0, "rate": 0.07,  "price": 180000000000.0 },
	{ "id": "15_onyx",        "name": "Onyx Chrono Harvester",          "dmg": 19000.0, "rate": 0.06,  "price": 1500000000000.0 }
]

func _load_image_texture(path: String) -> ImageTexture:
	if not FileAccess.file_exists(path):
		return null
	var img = Image.load_from_file(path)
	if not img:
		return null
	return ImageTexture.create_from_image(img)

func _ready() -> void:
	_register_weapon_tiers()
	_register_profession()

func _register_weapon_tiers() -> void:
	var item_script = load("res://resources/Items/Scripts/Item.gd")
	var buy_script = load("res://resources/BuyEffects/Scripts/AddToInventory.gd")
	var pickup_script = load("res://resources/PickupEffects/Scripts/PickupToInventory.gd")
	var equip_script = load("res://mods-unpacked/gareth-chrono_industrialist_mod/scripts/chrono_industrialist_equip.gd")
	var pickup_sound = load("res://assets/sound/sound effects/SwordThud.wav")

	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")

	for t in TIER_DATA:
		var item = item_script.new()
		item.itemID = "chrono_drill_" + t["id"]
		item.itemName = t["name"]
		item.itemDescription = "Temporal excavation harvester.\nHigh-speed chronometric strikes trigger Stasis Shockwaves every 10th hit.\nDamage: %d | Strike Cycle: %.2fs" % [int(t["dmg"]), float(t["rate"])]

		var tex_path := "res://mods-unpacked/gareth-chrono_industrialist_mod/textures/chrono_drill_%s.png" % t["id"]
		item.itemTexture = _load_image_texture(tex_path)

		var equip = equip_script.new()
		equip.damage = t["dmg"]
		equip.strike_rate = t["rate"]
		item.itemEquipEffect = equip

		var buy = buy_script.new()
		item.itemBuyEffect = buy
		var pickup = pickup_script.new()
		item.itemPickupEffect = pickup
		item.pickupSound = pickup_sound

		item.itemBuyPrice = t["price"]
		item.itemSellPrice = t["price"] * 0.5
		item.itemUnlocked = true
		item.itemType = "chrono_drill"

		all_chrono_items.append(item)

		if item_unlocks:
			if not (item in item_unlocks.all_equipment_items):
				item_unlocks.all_equipment_items.append(item)
			if not (item in item_unlocks.all_items):
				item_unlocks.all_items.append(item)

	if all_chrono_items.size() > 0:
		starter_weapon = all_chrono_items[0]

	ModLoaderLog.info("15 Chrono-Industrialist Harvester tiers registered into equipment shop.", MOD_DIR)

func _register_profession() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://mods-unpacked/gareth-chrono_industrialist_mod/scripts/chrono_industrialist_profession.gd")
	var p = prof_script.new()
	p.profession_name = "Chrono-Industrialist"
	p.description = "Temporal excavation engineer.\nHigh-speed chronometric strikes trigger Stasis Shockwaves every 10th hit.\nStarts with the Shoddy Chrono Harvester."

	var icon_path := "res://mods-unpacked/gareth-chrono_industrialist_mod/textures/chrono_industrialist_icon.png"
	var icon_tex = _load_image_texture(icon_path)
	if icon_tex:
		p.image = icon_tex

	pm.all_professions[107] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Chrono-Industrialist Class (ID 107) registered cleanly.", MOD_DIR)