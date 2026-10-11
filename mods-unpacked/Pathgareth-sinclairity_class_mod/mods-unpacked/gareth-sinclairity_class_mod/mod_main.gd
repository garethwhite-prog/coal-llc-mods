extends Node

func _ready() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://resources/professions/scripts/profession.gd")
	var p = prof_script.new()
	p.profession_name = "Rainbow Sinclairity"
	p.description = "Experimental spectral optics miner.\nMelts stone with a continuous prismatic energy beam."
	if ResourceLoader.exists("res://assets/LaserbeamEnd.png"):
		p.image = load("res://assets/LaserbeamEnd.png")

	pm.all_professions[104] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Rainbow Sinclairity Class (ID 104) registered.", "gareth-sinclairity_class_mod")