extends Node

const MOD_DIR := "gareth-water_spirit_mod"

const ORDERED_TIERS := [
	"01_shoddy", "02_copper", "03_iron", "04_sapphire", "05_emerald",
	"06_silver", "07_amethyst", "08_gold", "09_ruby", "10_diamond",
	"11_pinkdiamond", "12_spinel", "13_uranium", "14_moonstone", "15_onyx"
]

func _ready() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks:
		return
	for tier in ORDERED_TIERS:
		var path := "res://mods-unpacked/gareth-water_spirit_mod/items/water_spirit_%s.tres" % tier
		if ResourceLoader.exists(path):
			var item = load(path)
			if item:
				if not item in item_unlocks.all_equipment_items:
					item_unlocks.all_equipment_items.append(item)
				if not item in item_unlocks.all_items:
					item_unlocks.all_items.append(item)
	ModLoaderLog.info("15 Water Spirit tiers registered into equipment shop.", MOD_DIR)