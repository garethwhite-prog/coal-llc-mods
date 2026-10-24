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
			if not (item in item_unlocks.all_items):
				item_unlocks.all_items.append(item)

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
