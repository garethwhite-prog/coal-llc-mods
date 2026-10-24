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
