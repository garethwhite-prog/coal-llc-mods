extends Node

const MOD_DIR := "gareth-sinclairity_class_mod"

var starter_weapon = null
var all_sinc_items: Array = []

const TIER_DATA := [
	{ "id": "01_shoddy",      "name": "Shoddy Optical Emitter",        "dmg": 55.0,    "width": 6.0,  "price": 0.0 },
	{ "id": "02_copper",      "name": "Copper Optical Emitter",        "dmg": 80.0,    "width": 7.0,  "price": 350.0 },
	{ "id": "03_iron",        "name": "Iron Optical Emitter",          "dmg": 115.0,   "width": 8.0,  "price": 1800.0 },
	{ "id": "04_sapphire",    "name": "Sapphire Optical Emitter",      "dmg": 165.0,   "width": 9.0,  "price": 9500.0 },
	{ "id": "05_emerald",     "name": "Emerald Optical Emitter",       "dmg": 240.0,   "width": 10.0, price": 45000.0 },
	{ "id": "06_silver",      "name": "Silver Optical Emitter",        "dmg": 350.0,   "width": 11.0, price": 200000.0 },
	{ "id": "07_amethyst",    "name": "Amethyst Optical Emitter",      "dmg": 500.0,   "width": 12.0, price": 850000.0 },
	{ "id": "08_gold",        "name": "Gold Optical Emitter",          "dmg": 740.0,   "width": 13.0, price": 4000000.0 },
	{ "id": "09_ruby",        "name": "Ruby Optical Emitter",          "dmg": 1100.0,  "width": 14.0, price": 20000000.0 },
	{ "id": "10_diamond",     "name": "Diamond Optical Emitter",       "dmg": 1650.0,  "width": 15.0, price": 100000000.0 },
	{ "id": "11_pinkdiamond", "name": "Pink Diamond Optical Emitter",  "dmg": 2500.0,  "width": 16.0, price": 600000000.0 },
	{ "id": "12_spinel",      "name": "Spinel Optical Emitter",        "dmg": 3900.0,  "width": 17.0, price": 3500000000.0 },
	{ "id": "13_uranium",     "name": "Uranium Optical Emitter",       "dmg": 6000.0,  "width": 18.0, price": 25000000000.0 },
	{ "id": "14_moonstone",   "name": "Moonstone Optical Emitter",     "dmg": 9600.0,  "width": 20.0, price": 180000000000.0 },
	{ "id": "15_onyx",        "name": "Onyx Optical Emitter",          "dmg": 16000.0, "width": 22.0, price": 1500000000000.0 }
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
	var equip_script = load("res://mods-unpacked/gareth-sinclairity_class_mod/scripts/sinclairity_equip.gd")
	var pickup_sound = load("res://assets/sound/sound effects/SwordThud.wav")

	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")

	for t in TIER_DATA:
		var item = item_script.new()
		item.itemID = "sinclairity_prism_" + t["id"]
		item.itemName = t["name"]
		item.itemDescription = "Continuous spectral prism miner.\nMelts rock layers with high-energy refracted light.\nDamage: %d/s | Beam Width: %.0fpx" % [int(t["dmg"]), float(t["width"])]

		var tex_path := "res://mods-unpacked/gareth-sinclairity_class_mod/textures/prism_%s.png" % t["id"]
		item.itemTexture = _load_image_texture(tex_path)

		var equip = equip_script.new()
		equip.damage = t["dmg"]
		equip.beam_width = t["width"]
		item.itemEquipEffect = equip

		var buy = buy_script.new()
		item.itemBuyEffect = buy
		var pickup = pickup_script.new()
		item.itemPickupEffect = pickup
		item.pickupSound = pickup_sound

		item.itemBuyPrice = t["price"]
		item.itemSellPrice = t["price"] * 0.5
		item.itemUnlocked = true
		item.itemType = "sinclair_prism"

		all_sinc_items.append(item)

		if item_unlocks:
			if not (item in item_unlocks.all_equipment_items):
				item_unlocks.all_equipment_items.append(item)
			if not (item in item_unlocks.all_items):
				item_unlocks.all_items.append(item)

	if all_sinc_items.size() > 0:
		starter_weapon = all_sinc_items[0]

	ModLoaderLog.info("15 Rainbow Sinclairity Optical Emitter tiers registered into equipment shop.", MOD_DIR)

func _register_profession() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://mods-unpacked/gareth-sinclairity_class_mod/scripts/sinclairity_profession.gd")
	var p = prof_script.new()
	p.profession_name = "Rainbow Sinclairity"
	p.description = "Experimental spectral optics miner.\nMelts stone with a continuous prismatic energy beam.\nStarts with the Shoddy Optical Emitter."

	var icon_path := "res://mods-unpacked/gareth-sinclairity_class_mod/textures/sinclairity_icon.png"
	var icon_tex = _load_image_texture(icon_path)
	if icon_tex:
		p.image = icon_tex

	pm.all_professions[104] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Rainbow Sinclairity Class (ID 104) registered cleanly.", MOD_DIR)