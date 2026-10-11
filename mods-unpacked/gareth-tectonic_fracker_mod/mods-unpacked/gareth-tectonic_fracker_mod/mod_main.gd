extends Node

func _ready() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://resources/professions/scripts/profession.gd")
	var p = prof_script.new()
	p.profession_name = "Tectonic Fracker"
	p.description = "Industrial seismic harvester.\nFires acoustic fracture pulses that shatter entire continuous ore seams simultaneously."
	if ResourceLoader.exists("res://assets/Equipment/vehicles/tank_turret.png"):
		p.image = load("res://assets/Equipment/vehicles/tank_turret.png")

	pm.all_professions[109] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Tectonic Fracker Class (ID 109) registered.", "gareth-tectonic_fracker_mod")