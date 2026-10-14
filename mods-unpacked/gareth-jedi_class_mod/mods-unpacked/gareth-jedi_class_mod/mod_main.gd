extends Node

const MOD_DIR := "gareth-jedi_class_mod"

var starter_weapon = null
var all_saber_items: Array = []

const TIER_DATA := [
	{ "id": "01_shoddy",      "name": "Shoddy Energy Saber",        "dmg": 75.0,    "reach": 28.0, "rate": 0.28, "price": 0.0 },
	{ "id": "02_copper",      "name": "Copper Energy Saber",        "dmg": 105.0,   "reach": 30.0, "rate": 0.26, "price": 350.0 },
	{ "id": "03_iron",        "name": "Iron Energy Saber",          "dmg": 150.0,   "reach": 32.0, "rate": 0.25, "price": 1800.0 },
	{ "id": "04_sapphire",    "name": "Sapphire Energy Saber",      "dmg": 215.0,   "reach": 34.0, "rate": 0.24, "price": 9500.0 },
	{ "id": "05_emerald",     "name": "Emerald Energy Saber",       "dmg": 310.0,   "reach": 36.0, "rate": 0.23, "price": 45000.0 },
	{ "id": "06_silver",      "name": "Silver Energy Saber",        "dmg": 450.0,   "reach": 38.0, "rate": 0.22, "price": 200000.0 },
	{ "id": "07_amethyst",    "name": "Amethyst Energy Saber",      "dmg": 650.0,   "reach": 40.0, "rate": 0.21, "price": 850000.0 },
	{ "id": "08_gold",        "name": "Gold Energy Saber",          "dmg": 950.0,   "reach": 43.0, "rate": 0.20, "price": 4000000.0 },
	{ "id": "09_ruby",        "name": "Ruby Energy Saber",          "dmg": 1400.0,  "reach": 46.0, "rate": 0.19, "price": 20000000.0 },
	{ "id": "10_diamond",     "name": "Diamond Energy Saber",       "dmg": 2100.0,  "reach": 50.0, "rate": 0.18, "price": 100000000.0 },
	{ "id": "11_pinkdiamond", "name": "Pink Diamond Energy Saber",  "dmg": 3200.0,  "reach": 54.0, "rate": 0.17, "price": 600000000.0 },
	{ "id": "12_spinel",      "name": "Spinel Energy Saber",        "dmg": 5000.0,  "reach": 58.0, "rate": 0.16, "price": 3500000000.0 },
	{ "id": "13_uranium",     "name": "Uranium Energy Saber",       "dmg": 7800.0,  "reach": 63.0, "rate": 0.15, "price": 25000000000.0 },
	{ "id": "14_moonstone",   "name": "Moonstone Energy Saber",     "dmg": 12500.0, "reach": 68.0, "rate": 0.14, "price": 180000000000.0 },
	{ "id": "15_onyx",        "name": "Onyx Energy Saber",          "dmg": 20000.0, "reach": 75.0, "rate": 0.13, "price": 1500000000000.0 }
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
	var equip_script = load("res://mods-unpacked/gareth-jedi_class_mod/scripts/jedi_saber_equip.gd")
	var pickup_sound = load("res://assets/sound/sound effects/SwordHit.wav")

	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")

	for t in TIER_DATA:
		var item = item_script.new()
		item.itemID = "jedi_saber_" + t["id"]
		item.itemName = t["name"]
		item.itemDescription = "Plasma energy saber.\nCleaves surrounding rock in a high-speed forward arc.\nDamage: %d | Cleave Radius: %.1fpx" % [int(t["dmg"]), float(t["reach"])]

		var tex_path := "res://mods-unpacked/gareth-jedi_class_mod/textures/saber_%s.png" % t["id"]
		item.itemTexture = _load_image_texture(tex_path)

		var equip = equip_script.new()
		equip.damage = t["dmg"]
		equip.reach = t["reach"]
		equip.swing_speed = t["rate"]
		item.itemEquipEffect = equip

		var buy = buy_script.new()
		item.itemBuyEffect = buy
		var pickup = pickup_script.new()
		item.itemPickupEffect = pickup
		item.pickupSound = pickup_sound

		item.itemBuyPrice = t["price"]
		item.itemSellPrice = t["price"] * 0.5
		item.itemUnlocked = true
		item.itemType = "jedi_saber"

		all_saber_items.append(item)

		if item_unlocks:
			if not (item in item_unlocks.all_equipment_items):
				item_unlocks.all_equipment_items.append(item)
			if not (item in item_unlocks.all_items):
				item_unlocks.all_items.append(item)

	if all_saber_items.size() > 0:
		starter_weapon = all_saber_items[0]

	ModLoaderLog.info("15 Energy Saber tiers registered into equipment shop.", MOD_DIR)

func _register_profession() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://mods-unpacked/gareth-jedi_class_mod/scripts/jedi_profession.gd")
	var p = prof_script.new()
	p.profession_name = "Jedi"
	p.description = "Wielder of plasma energy and kinetic resonance.\nEnergy sabers cleave surrounding stone and ore in high-speed sweeps.\nStarts with the Shoddy Energy Saber."

	var icon_path := "res://mods-unpacked/gareth-jedi_class_mod/textures/jedi_icon.png"
	var icon_tex = _load_image_texture(icon_path)
	if icon_tex:
		p.image = icon_tex

	pm.all_professions[102] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Jedi Class (ID 102) registered cleanly.", MOD_DIR)