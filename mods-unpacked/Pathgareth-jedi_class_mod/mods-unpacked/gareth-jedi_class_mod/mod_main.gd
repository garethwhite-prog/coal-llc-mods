extends Node

func _ready() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://resources/professions/scripts/profession.gd")
	var p = prof_script.new()
	p.profession_name = "Jedi"
	p.description = "Wielder of the energetic Force.\nStarts with an Energy Saber and rapid Blaster sidearm."
	if ResourceLoader.exists("res://assets/Laserbeam.png"):
		p.image = load("res://assets/Laserbeam.png")

	pm.all_professions[102] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Jedi Class (ID 102) registered successfully.", "gareth-jedi_class_mod")