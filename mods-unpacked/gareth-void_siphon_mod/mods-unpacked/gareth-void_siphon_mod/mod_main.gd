extends Node

const MOD_DIR := "gareth-void_siphon_mod"

var starter_weapon = null
var all_void_items: Array = []

const TIER_DATA := [
	{ "id": "01_shoddy",      "name": "Shoddy Void Core",        "dmg": 120.0,   "rad": 3.5,  "price": 0.0 },
	{ "id": "02_copper",      "name": "Copper Void Core",        "dmg": 175.0,   "rad": 3.8,  "price": 350.0 },
	{ "id": "03_iron",        "name": "Iron Void Core",          "dmg": 250.0,   "rad": 4.2,  "price": 1800.0 },
	{ "id": "04_sapphire",    "name": "Sapphire Void Core",      "dmg": 360.0,   "rad": 4.6,  "price": 9500.0 },
	{ "id": "05_emerald",     "name": "Emerald Void Core",       "dmg": 520.0,   "rad": 5.0,  "price": 45000.0 },
	{ "id": "06_silver",      "name": "Silver Void Core",        "dmg": 750.0,   "rad": 5.5,  "price": 200000.0 },
	{ "id": "07_amethyst",    "name": "Amethyst Void Core",      "dmg": 1100.0,  "rad": 6.0,  "price": 850000.0 },
	{ "id": "08_gold",        "name": "Gold Void Core",          "dmg": 1600.0,  "rad": 6.6,  "price": 4000000.0 },
	{ "id": "09_ruby",        "name": "Ruby Void Core",          "dmg": 2400.0,  "rad": 7.3,  "price": 20000000.0 },
	{ "id": "10_diamond",     "name": "Diamond Void Core",       "dmg": 3600.0,  "rad": 8.1,  "price": 100000000.0 },
	{ "id": "11_pinkdiamond", "name": "Pink Diamond Void Core",  "dmg": 5500.0,  "rad": 9.0,  "price": 600000000.0 },
	{ "id": "12_spinel",      "name": "Spinel Void Core",        "dmg": 8500.0,  "rad": 10.0, price": 3500000000.0 },
	{ "id": "13_uranium",     "name": "Uranium Void Core",       "dmg": 13500.0, "rad": 11.2, price": 25000000000.0 },
	{ "id": "14_moonstone",   "name": "Moonstone Void Core",     "dmg": 21000.0, "rad": 12.6, price": 180000000000.0 },
	{ "id": "15_onyx",        "name": "Onyx Void Core",          "dmg": 35000.0, "rad": 14.5, price": 1500000000000.0 }
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
	var equip_script = load("res://mods-unpacked/gareth-void_siphon_mod/scripts/void_siphon_equip.gd")
	var pickup_sound = load("res://assets/sound/sound effects/SwordThud.wav")

	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")

	for t in TIER_DATA:
		var item = item_script.new()
		item.itemID = "void_core_" + t["id"]
		item.itemName = t["name"]
		item.itemDescription = "Gravitational singularity harvester.\nTriggers localized implosions and vacuums nearby ore.\nDamage: %d | Implosion Radius: %.1f tiles" % [int(t["dmg"]), float(t["rad"])]

		var tex_path := "res://mods-unpacked/gareth-void_siphon_mod/textures/void_core_%s.png" % t["id"]
		item.itemTexture = _load_image_texture(tex_path)

		var equip = equip_script.new()
		equip.damage = t["dmg"]
		equip.radius = t["rad"]
		item.itemEquipEffect = equip

		var buy = buy_script.new()
		item.itemBuyEffect = buy
		var pickup = pickup_script.new()
		item.itemPickupEffect = pickup
		item.pickupSound = pickup_sound

		item.itemBuyPrice = t["price"]
		item.itemSellPrice = t["price"] * 0.5
		item.itemUnlocked = true
		item.itemType = "void_core"

		all_void_items.append(item)

		if item_unlocks:
			if not (item in item_unlocks.all_equipment_items):
				item_unlocks.all_equipment_items.append(item)
			if not (item in item_unlocks.all_items):
				item_unlocks.all_items.append(item)

	if all_void_items.size() > 0:
		starter_weapon = all_void_items[0]

	ModLoaderLog.info("15 Void Siphon Core tiers registered into equipment shop.", MOD_DIR)

func _register_profession() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://mods-unpacked/gareth-void_siphon_mod/scripts/void_siphon_profession.gd")
	var p = prof_script.new()
	p.profession_name = "Void Siphon"
	p.description = "Wielder of cosmic singularities.\nTriggers gravitational implosions that crush stone and vacuum ore.\nStarts with the Shoddy Void Core."

	var icon_path := "res://mods-unpacked/gareth-void_siphon_mod/textures/void_siphon_icon.png"
	var icon_tex = _load_image_texture(icon_path)
	if icon_tex:
		p.image = icon_tex

	pm.all_professions[105] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Void Siphon Class (ID 105) registered cleanly.", MOD_DIR)