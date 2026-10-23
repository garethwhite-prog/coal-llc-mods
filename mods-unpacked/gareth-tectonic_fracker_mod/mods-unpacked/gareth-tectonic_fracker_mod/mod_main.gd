extends Node

const MOD_DIR := "gareth-tectonic_fracker_mod"

var starter_weapon = null
var all_fracker_items: Array = []

const TIER_DATA := [
	{ "id": "01_shoddy",      "name": "Shoddy Tectonic Fracker",        "dmg": 80.0,    "seam": 18,  "price": 0.0 },
	{ "id": "02_copper",      "name": "Copper Tectonic Fracker",        "dmg": 115.0,   "seam": 24,  "price": 350.0 },
	{ "id": "03_iron",        "name": "Iron Tectonic Fracker",          "dmg": 160.0,   "seam": 32,  "price": 1800.0 },
	{ "id": "04_sapphire",    "name": "Sapphire Tectonic Fracker",      "dmg": 230.0,   "seam": 42,  "price": 9500.0 },
	{ "id": "05_emerald",     "name": "Emerald Tectonic Fracker",       "dmg": 330.0,   "seam": 54,  "price": 45000.0 },
	{ "id": "06_silver",      "name": "Silver Tectonic Fracker",        "dmg": 480.0,   "seam": 68,  "price": 200000.0 },
	{ "id": "07_amethyst",    "name": "Amethyst Tectonic Fracker",      "dmg": 700.0,   "seam": 85,  "price": 850000.0 },
	{ "id": "08_gold",        "name": "Gold Tectonic Fracker",          "dmg": 1000.0,  "seam": 110, "price": 4000000.0 },
	{ "id": "09_ruby",        "name": "Ruby Tectonic Fracker",          "dmg": 1500.0,  "seam": 145, "price": 20000000.0 },
	{ "id": "10_diamond",     "name": "Diamond Tectonic Fracker",       "dmg": 2300.0,  "seam": 190, "price": 100000000.0 },
	{ "id": "11_pinkdiamond", "name": "Pink Diamond Tectonic Fracker",  "dmg": 3500.0,  "seam": 250, "price": 600000000.0 },
	{ "id": "12_spinel",      "name": "Spinel Tectonic Fracker",        "dmg": 5500.0,  "seam": 330, "price": 3500000000.0 },
	{ "id": "13_uranium",     "name": "Uranium Tectonic Fracker",       "dmg": 8500.0,  "seam": 440, "price": 25000000000.0 },
	{ "id": "14_moonstone",   "name": "Moonstone Tectonic Fracker",     "dmg": 13500.0, "seam": 600, "price": 180000000000.0 },
	{ "id": "15_onyx",        "name": "Onyx Tectonic Fracker",          "dmg": 22000.0, "seam": 850, "price": 1500000000000.0 }
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
	var equip_script = load("res://mods-unpacked/gareth-tectonic_fracker_mod/scripts/tectonic_fracker_equip.gd")
	var pickup_sound = load("res://assets/sound/sound effects/SwordThud.wav")

	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")

	for t in TIER_DATA:
		var item = item_script.new()
		item.itemID = "tectonic_fracker_" + t["id"]
		item.itemName = t["name"]
		item.itemDescription = "Industrial seismic harvester.\nFires acoustic fracture pulses that shatter continuous ore seams.\nDamage: %d | Max Seam: %d\nScales with Fracker upgrades." % [int(t["dmg"]), int(t["seam"])]

		var tex_path := "res://mods-unpacked/gareth-tectonic_fracker_mod/textures/fracker_%s.png" % t["id"]
		item.itemTexture = _load_image_texture(tex_path)

		var equip = equip_script.new()
		equip.damage = t["dmg"]
		equip.seam_limit = t["seam"]
		item.itemEquipEffect = equip

		var buy = buy_script.new()
		item.itemBuyEffect = buy
		var pickup = pickup_script.new()
		item.itemPickupEffect = pickup
		item.pickupSound = pickup_sound

		item.itemBuyPrice = t["price"]
		item.itemSellPrice = t["price"] * 0.5
		item.itemUnlocked = true
		item.itemType = "fracker"

		all_fracker_items.append(item)

		if item_unlocks:
			if not (item in item_unlocks.all_equipment_items):
				item_unlocks.all_equipment_items.append(item)

	if all_fracker_items.size() > 0:
		starter_weapon = all_fracker_items[0]

	ModLoaderLog.info("15 Tectonic Fracker tiers registered into equipment shop.", MOD_DIR)

func _register_profession() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://mods-unpacked/gareth-tectonic_fracker_mod/scripts/tectonic_fracker_profession.gd")
	var p = prof_script.new()
	p.profession_name = "Tectonic Fracker"
	p.description = "Industrial seismic harvester.\nFires acoustic fracture pulses that shatter entire continuous ore seams simultaneously.\nScales with bespoke Fracker upgrades."

	var icon_path := "res://mods-unpacked/gareth-tectonic_fracker_mod/textures/tectonic_fracker_icon.png"
	var icon_tex = _load_image_texture(icon_path)
	if icon_tex:
		p.image = icon_tex

	pm.all_professions[109] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Tectonic Fracker Class (ID 109) registered cleanly.", MOD_DIR)
