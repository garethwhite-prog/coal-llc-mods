extends Node

func _ready() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://mods-unpacked/gareth-void_siphon_mod/scripts/void_siphon_profession.gd")
	var p = prof_script.new()
	p.profession_name = "Void Siphon"
	p.description = "Singularity master who starts with ZERO mining tools.\nRight-click collapses subterranean rock directly inward into mineral shards."
	if ResourceLoader.exists("res://assets/Equipment/magic/staffs/15_onyx_staff.png"):
		p.image = load("res://assets/Equipment/magic/staffs/15_onyx_staff.png")

	pm.all_professions[105] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Void Siphon Class (ID 105) registered with zero-tool start.", "gareth-void_siphon_mod")