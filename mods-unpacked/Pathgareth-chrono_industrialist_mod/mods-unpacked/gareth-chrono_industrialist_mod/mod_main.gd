extends Node

func _ready() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://resources/professions/scripts/profession.gd")
	var p = prof_script.new()
	p.profession_name = "Chrono-Industrialist"
	p.description = "Temporal excavation engineer.\nEvery 10th strike deploys a Stasis Field, absorbing damage and releasing a 2x shockwave."
	if ResourceLoader.exists("res://assets/Equipment/magic/staffs/14_moonstone_staff.png"):
		p.image = load("res://assets/Equipment/magic/staffs/14_moonstone_staff.png")

	pm.all_professions[107] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Chrono-Industrialist Class (ID 107) registered.", "gareth-chrono_industrialist_mod")