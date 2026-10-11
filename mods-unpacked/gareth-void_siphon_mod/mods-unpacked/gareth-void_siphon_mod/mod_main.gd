extends Node

func _ready() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if item_unlocks:
		for id_str in ["01_singularity", "02_event_horizon", "03_null_pulsar"]:
			var path := "res://mods-unpacked/gareth-void_siphon_mod/items/VoidCore_%s.tres" % id_str
			if ResourceLoader.exists(path):
				var res = load(path)
				if res and not (res in item_unlocks.all_equipment_items):
					item_unlocks.all_equipment_items.append(res)
				if res and not (res in item_unlocks.all_items):
					item_unlocks.all_items.append(res)

	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return

	var pm = Gvars.profession_manager
	var prof_script = load("res://resources/professions/scripts/profession.gd")
	var p = prof_script.new()
	p.profession_name = "Void Siphon"
	p.description = "Singularity master starting with ZERO tools.\nRight-click collapses stone inward. Upgradable Void Cores purchasable in shop."
	if ResourceLoader.exists("res://assets/Equipment/magic/staffs/15_onyx_staff.png"):
		p.image = load("res://assets/Equipment/magic/staffs/15_onyx_staff.png")

	pm.all_professions[105] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Void Siphon Class (ID 105) registered with Void Cores.", "gareth-void_siphon_mod")