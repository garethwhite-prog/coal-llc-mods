extends Node

const MOD_DIR := "gareth-grav_dreadnought_mod"

var starter_weapon = null
var all_dread_items: Array = []

const TIER_DATA := [
	{ "id": "01_shoddy",      "name": "Shoddy Dreadnought Cannon",        "dmg": 110.0,   "rate": 0.55,  "price": 0.0 },
	{ "id": "02_copper",      "name": "Copper Dreadnought Cannon",        "dmg": 160.0,   "rate": 0.52,  "price": 350.0 },
	{ "id": "03_iron",        "name": "Iron Dreadnought Cannon",          "dmg": 230.0,   "rate": 0.49,  "price": 1800.0 },
	{ "id": "04_sapphire",    "name": "Sapphire Dreadnought Cannon",      "dmg": 330.0,   "rate": 0.46,  "price": 9500.0 },
	{ "id": "05_emerald",     "name": "Emerald Dreadnought Cannon",       "dmg": 480.0,   "rate": 0.43,  "price": 45000.0 },
	{ "id": "06_silver",      "name": "Silver Dreadnought Cannon",        "dmg": 700.0,   "rate": 0.40,  "price": 200000.0 },
	{ "id": "07_amethyst",    "name": "Amethyst Dreadnought Cannon",      "dmg": 1000.0,  "rate": 0.37,  "price": 850000.0 },
	{ "id": "08_gold",        "name": "Gold Dreadnought Cannon",          "dmg": 1500.0,  "rate": 0.34,  "price": 4000000.0 },
	{ "id": "09_ruby",        "name": "Ruby Dreadnought Cannon",          "dmg": 2200.0,  "rate": 0.31,  "price": 20000000.0 },
	{ "id": "10_diamond",     "name": "Diamond Dreadnought Cannon",       "dmg": 3300.0,  "rate": 0.28,  "price": 100000000.0 },
	{ "id": "11_pinkdiamond", "name": "Pink Diamond Dreadnought Cannon",  "dmg": 5000.0,  "rate": 0.25,  "price": 600000000.0 },
	{ "id": "12_spinel",      "name": "Spinel Dreadnought Cannon",        "dmg": 7700.0,  "rate": 0.22,  "price": 3500000000.0 },
	{ "id": "13_uranium",     "name": "Uranium Dreadnought Cannon",       "dmg": 12000.0, "rate": 0.19,  "price": 25000000000.0 },
	{ "id": "14_moonstone",   "name": "Moonstone Dreadnought Cannon",     "dmg": 19000.0, "rate": 0.16,  "price": 180000000000.0 },
	{ "id": "15_onyx",        "name": "Onyx Dreadnought Cannon",          "dmg": 32000.0, "rate": 0.13,  "price": 1500000000000.0 }
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
	var equip_script = load("res://mods-unpacked/gareth-grav_dreadnought_mod/scripts/grav_dreadnought_equip.gd")
	var pickup_sound = load("res://assets/sound/sound effects/SwordThud.wav")

	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")

	for t in TIER_DATA:
		var item = item_script.new()
		item.itemID = "dread_cannon_" + t["id"]
		item.itemName = t["name"]
		item.itemDescription = "Heavy mass orbital cannon.\nShatters subterranean rock with high-density kinetic ordnance.\nDamage: %d | Cycle: %.2fs" % [int(t["dmg"]), float(t["rate"])]

		var tex_path := "res://mods-unpacked/gareth-grav_dreadnought_mod/textures/dread_cannon_%s.png" % t["id"]
		item.itemTexture = _load_image_texture(tex_path)

		var equip = equip_script.new()
		equip.damage = t["dmg"]
		equip.fire_rate = t["rate"]
		item.itemEquipEffect = equip

		var buy = buy_script.new()
		item.itemBuyEffect = buy
		var pickup = pickup_script.new()
		item.itemPickupEffect = pickup
		item.pickupSound = pickup_sound

		item.itemBuyPrice = t["price"]
		item.itemSellPrice = t["price"] * 0.5
		item.itemUnlocked = true
		item.itemType = "dread_cannon"

		all_dread_items.append(item)

		if item_unlocks:
			if not (item in item_unlocks.all_equipment_items):
				item_unlocks.all_equipment_items.append(item)
			if not (item in item_unlocks.all_items):
				item_unlocks.all_items.append(item)

	if all_dread_items.size() > 0:
		starter_weapon = all_dread_items[0]

	ModLoaderLog.info("15 Gravitational Dreadnought Cannon tiers registered into equipment shop.", MOD_DIR)

func _register_profession() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://mods-unpacked/gareth-grav_dreadnought_mod/scripts/grav_dreadnought_profession.gd")
	var p = prof_script.new()
	p.profession_name = "Gravitational Dreadnought"
	p.description = "Heavy armored fortress.\nExtreme mass; shatters rock with heavy orbital cannons.\nStarts with the Shoddy Dreadnought Cannon."

	var icon_path := "res://mods-unpacked/gareth-grav_dreadnought_mod/textures/grav_dreadnought_icon.png"
	var icon_tex = _load_image_texture(icon_path)
	if icon_tex:
		p.image = icon_tex

	pm.all_professions[108] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Gravitational Dreadnought Class (ID 108) registered cleanly.", MOD_DIR)