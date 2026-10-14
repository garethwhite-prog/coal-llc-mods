extends Node

const MOD_DIR := "gareth-bouncing_ball_mod"

var starter_weapon = null
var all_ball_items: Array = []

const TIER_DATA := [
	{ "id": "01_shoddy",      "name": "Shoddy Bouncing Ball",        "dmg": 95.0,    "rad": 3.2,  "price": 0.0 },
	{ "id": "02_copper",      "name": "Copper Bouncing Ball",        "dmg": 135.0,   "rad": 3.6,  "price": 350.0 },
	{ "id": "03_iron",        "name": "Iron Bouncing Ball",          "dmg": 190.0,   "rad": 4.0,  "price": 1800.0 },
	{ "id": "04_sapphire",    "name": "Sapphire Bouncing Ball",      "dmg": 270.0,   "rad": 4.5,  "price": 9500.0 },
	{ "id": "05_emerald",     "name": "Emerald Bouncing Ball",       "dmg": 390.0,   "rad": 5.0,  "price": 45000.0 },
	{ "id": "06_silver",      "name": "Silver Bouncing Ball",        "dmg": 560.0,   "rad": 5.6,  "price": 200000.0 },
	{ "id": "07_amethyst",    "name": "Amethyst Bouncing Ball",      "dmg": 800.0,   "rad": 6.2,  "price": 850000.0 },
	{ "id": "08_gold",        "name": "Gold Bouncing Ball",          "dmg": 1200.0,  "rad": 7.0,  "price": 4000000.0 },
	{ "id": "09_ruby",        "name": "Ruby Bouncing Ball",          "dmg": 1800.0,  "rad": 7.8,  "price": 20000000.0 },
	{ "id": "10_diamond",     "name": "Diamond Bouncing Ball",       "dmg": 2700.0,  "rad": 8.8,  "price": 100000000.0 },
	{ "id": "11_pinkdiamond", "name": "Pink Diamond Bouncing Ball",  "dmg": 4100.0,  "rad": 10.0, "price": 600000000.0 },
	{ "id": "12_spinel",      "name": "Spinel Bouncing Ball",        "dmg": 6300.0,  "rad": 11.2, "price": 3500000000.0 },
	{ "id": "13_uranium",     "name": "Uranium Bouncing Ball",       "dmg": 9900.0,  "rad": 12.8, "price": 25000000000.0 },
	{ "id": "14_moonstone",   "name": "Moonstone Bouncing Ball",     "dmg": 15800.0, "rad": 14.5, "price": 180000000000.0 },
	{ "id": "15_onyx",        "name": "Onyx Bouncing Ball",          "dmg": 26000.0, "rad": 17.0, "price": 1500000000000.0 }
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
	var equip_script = load("res://mods-unpacked/gareth-bouncing_ball_mod/scripts/bouncing_ball_equip.gd")
	var pickup_sound = load("res://assets/sound/sound effects/SwordThud.wav")

	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")

	for t in TIER_DATA:
		var item = item_script.new()
		item.itemID = "bouncing_ball_" + t["id"]
		item.itemName = t["name"]
		item.itemDescription = "Chaotic kinetic sphere ordnance.\nRebounds off cavern walls before detonating.\nDamage: %d | Blast Radius: %.1f tiles" % [int(t["dmg"]), float(t["rad"])]

		var tex_path := "res://mods-unpacked/gareth-bouncing_ball_mod/textures/ball_%s.png" % t["id"]
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
		item.itemType = "bouncing_ball"

		all_ball_items.append(item)

		if item_unlocks:
			if not (item in item_unlocks.all_equipment_items):
				item_unlocks.all_equipment_items.append(item)
			if not (item in item_unlocks.all_items):
				item_unlocks.all_items.append(item)

	if all_ball_items.size() > 0:
		starter_weapon = all_ball_items[0]

	ModLoaderLog.info("15 Bouncing Ball tiers registered into equipment shop.", MOD_DIR)

func _register_profession() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://mods-unpacked/gareth-bouncing_ball_mod/scripts/bouncing_ball_profession.gd")
	var p = prof_script.new()
	p.profession_name = "Bouncing Ball"
	p.description = "Specialist in chaotic kinetic sphere ordnance.\nBouncy balls rebound off solid cavern walls before detonating.\nStarts with the Shoddy Bouncing Ball."

	var icon_path := "res://mods-unpacked/gareth-bouncing_ball_mod/textures/bouncing_ball_icon.png"
	var icon_tex = _load_image_texture(icon_path)
	if icon_tex:
		p.image = icon_tex

	pm.all_professions[103] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Bouncing Ball Class (ID 103) registered cleanly.", MOD_DIR)