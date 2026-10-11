extends Node

const STAFF_PATHS: Array[String] = [
	"res://resources/Items/Equipment/staffs/staff_12_spinel.tres",
	"res://resources/Items/Equipment/staffs/staff_13_uranium.tres",
	"res://resources/Items/Equipment/staffs/staff_14_moonstone.tres",
	"res://resources/Items/Equipment/staffs/staff_15_onyx.tres"
]

const POISON_GUN_PREFIX := "res://resources/Items/Equipment/alternative_guns/poison_guns/poison_gun_"
const POISON_GUN_TIERS: Array[String] = [
	"01_shoddy", "02_copper", "03_iron", "04_sapphire", "05_emerald",
	"06_silver", "07_amethyst", "08_gold", "09_ruby", "10_diamond",
	"11_pinkdiamond", "12_spinel", "13_uranium", "14_moonstone", "15_onyx"
]

func _ready() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks:
		return

	for sp in STAFF_PATHS:
		if ResourceLoader.exists(sp):
			var staff_res = load(sp)
			if staff_res and not (staff_res in item_unlocks.all_equipment_items):
				item_unlocks.all_equipment_items.append(staff_res)
			if staff_res and not (staff_res in item_unlocks.all_items):
				item_unlocks.all_items.append(staff_res)

	for tier in POISON_GUN_TIERS:
		var p_path := "%s%s.tres" % [POISON_GUN_PREFIX, tier]
		if ResourceLoader.exists(p_path):
			var gun_res = load(p_path)
			if gun_res and not (gun_res in item_unlocks.all_equipment_items):
				item_unlocks.all_equipment_items.append(gun_res)
			if gun_res and not (gun_res in item_unlocks.all_items):
				item_unlocks.all_items.append(gun_res)

	ModLoaderLog.info("End-game Magic Staffs (12-15) and Poison Guns (1-15) registered into shop.", "gareth-endgame_arsenal_mod")