extends Node

const MOD_DIR := "gareth-grenade_mod"

func _ready() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks:
		return

	var tiers = [
		"01_shoddy", "02_copper", "03_iron", "04_sapphire", "05_emerald",
		"06_silver", "07_amethyst", "08_gold", "09_ruby", "10_diamond",
		"11_pinkdiamond", "12_spinel", "13_uranium", "14_moonstone", "15_onyx"
	]

	for t in tiers:
		var item_path := "res://mods-unpacked/gareth-grenade_mod/items/grenade_%s.tres" % t
		if ResourceLoader.exists(item_path):
			var item = load(item_path)
			var tex_path := "res://mods-unpacked/gareth-grenade_mod/textures/grenade_%s.png" % t
			if FileAccess.file_exists(tex_path):
				var img = Image.load_from_file(tex_path)
				if img:
					item.itemTexture = ImageTexture.create_from_image(img)
			if item and not (item in item_unlocks.all_equipment_items):
				item_unlocks.all_equipment_items.append(item)
			if item and not (item in item_unlocks.all_items):
				item_unlocks.all_items.append(item)

	ModLoaderLog.info("15 Bouncing Grenades registered with color-coded textures.", MOD_DIR)