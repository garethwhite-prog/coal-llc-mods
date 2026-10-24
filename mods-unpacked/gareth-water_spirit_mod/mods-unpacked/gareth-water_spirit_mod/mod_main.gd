extends Node

const MOD_DIR := "gareth-water_spirit_mod"

func _load_image_texture(path: String) -> Texture2D:
	if FileAccess.file_exists(path):
		var buffer = FileAccess.get_file_as_bytes(path)
		if buffer.size() > 0:
			var img = Image.new()
			if img.load_png_from_buffer(buffer) == OK:
				return ImageTexture.create_from_image(img)
	return null

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
		var item_path := "res://mods-unpacked/gareth-water_spirit_mod/items/water_spirit_%s.tres" % t
		if ResourceLoader.exists(item_path):
			var item = load(item_path)
			var tex_path := "res://mods-unpacked/gareth-water_spirit_mod/textures/spirit_%s.png" % t
			var custom_tex = _load_image_texture(tex_path)
			if custom_tex and item:
				item.itemTexture = custom_tex
			if item and not (item in item_unlocks.all_equipment_items):
				item_unlocks.all_equipment_items.append(item)
			if item and not (item in item_unlocks.all_items):
				item_unlocks.all_items.append(item)

	ModLoaderLog.info("15 Water Spirit Fairy tiers loaded with custom textures.", MOD_DIR)
