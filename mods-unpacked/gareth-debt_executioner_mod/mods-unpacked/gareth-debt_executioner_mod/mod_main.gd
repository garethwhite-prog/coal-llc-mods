extends Node

const MOD_DIR := "gareth-debt_executioner_mod"

var starter_weapon = null
var all_debt_items: Array = []

const TIER_DATA := [
	{ "id": "01_shoddy",      "name": "Shoddy Enforcer Minigun",        "dmg": 25.0,   "rate": 0.09,  "price": 0.0 },
	{ "id": "02_copper",      "name": "Copper Enforcer Minigun",        "dmg": 36.0,   "rate": 0.085, "price": 350.0 },
	{ "id": "03_iron",        "name": "Iron Enforcer Minigun",          "dmg": 50.0,   "rate": 0.08,  "price": 1800.0 },
	{ "id": "04_sapphire",    "name": "Sapphire Enforcer Minigun",      "dmg": 72.0,   "rate": 0.075, "price": 9500.0 },
	{ "id": "05_emerald",     "name": "Emerald Enforcer Minigun",       "dmg": 105.0,  "rate": 0.07,  "price": 45000.0 },
	{ "id": "06_silver",      "name": "Silver Enforcer Minigun",        "dmg": 150.0,  "rate": 0.065, "price": 200000.0 },
	{ "id": "07_amethyst",    "name": "Amethyst Enforcer Minigun",      "dmg": 220.0,  "rate": 0.06,  "price": 850000.0 },
	{ "id": "08_gold",        "name": "Gold Enforcer Minigun",          "dmg": 320.0,  "rate": 0.055, "price": 4000000.0 },
	{ "id": "09_ruby",        "name": "Ruby Enforcer Minigun",          "dmg": 480.0,  "rate": 0.05,  "price": 20000000.0 },
	{ "id": "10_diamond",     "name": "Diamond Enforcer Minigun",       "dmg": 720.0,  "rate": 0.045, "price": 100000000.0 },
	{ "id": "11_pinkdiamond", "name": "Pink Diamond Enforcer Minigun",  "dmg": 1100.0, "rate": 0.04,  "price": 600000000.0 },
	{ "id": "12_spinel",      "name": "Spinel Enforcer Minigun",        "dmg": 1700.0, "rate": 0.035, "price": 3500000000.0 },
	{ "id": "13_uranium",     "name": "Uranium Enforcer Minigun",       "dmg": 2600.0, "rate": 0.03,  "price": 25000000000.0 },
	{ "id": "14_moonstone",   "name": "Moonstone Enforcer Minigun",     "dmg": 4000.0, "rate": 0.025, "price": 180000000000.0 },
	{ "id": "15_onyx",        "name": "Onyx Enforcer Minigun",          "dmg": 6500.0, "rate": 0.02,  "price": 1500000000000.0 }
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
	var equip_script = load("res://mods-unpacked/gareth-debt_executioner_mod/scripts/debt_executioner_equip.gd")
	var pickup_sound = load("res://assets/sound/sound effects/SwordThud.wav")

	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")

	for t in TIER_DATA:
		var item = item_script.new()
		item.itemID = "debt_executioner_" + t["id"]
		item.itemName = t["name"]
		item.itemDescription = "Corporate enforcement minigun.\nRapid rotary kinetic fire.\nDamage: %d | Cycle Rate: %.3fs" % [int(t["dmg"]), float(t["rate"])]

		var tex_path := "res://mods-unpacked/gareth-debt_executioner_mod/textures/minigun_%s.png" % t["id"]
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
		item.itemType = "debt_executioner"

		all_debt_items.append(item)

		if item_unlocks:
			if not (item in item_unlocks.all_equipment_items):
				item_unlocks.all_equipment_items.append(item)
			if not (item in item_unlocks.all_items):
				item_unlocks.all_items.append(item)

	if all_debt_items.size() > 0:
		starter_weapon = all_debt_items[0]

	ModLoaderLog.info("15 Debt Executioner Minigun tiers registered into equipment shop.", MOD_DIR)

func _register_profession() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://mods-unpacked/gareth-debt_executioner_mod/scripts/debt_executioner_profession.gd")
	var p = prof_script.new()
	p.profession_name = "Debt Executioner"
	p.description = "Corporate enforcer with late-game loadouts.\nStarts with -$50,000,000 debt balance.\nMeet quotas or corporate Repo Drones hunt you down."

	var icon_path := "res://mods-unpacked/gareth-debt_executioner_mod/textures/debt_executioner_icon.png"
	var icon_tex = _load_image_texture(icon_path)
	if icon_tex:
		p.image = icon_tex

	pm.all_professions[106] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Debt Executioner Class (ID 106) registered cleanly.", MOD_DIR)