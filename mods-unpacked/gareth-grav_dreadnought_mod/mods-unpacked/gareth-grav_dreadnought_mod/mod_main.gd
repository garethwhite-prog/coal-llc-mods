extends Node

func _ready() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://resources/professions/scripts/profession.gd")
	var p = prof_script.new()
	p.profession_name = "Gravitational Dreadnought"
	p.description = "Heavy armored fortress.\nExtreme mass; fired projectiles enter a circular orbit around the player."
	if ResourceLoader.exists("res://assets/Equipment/guns/shotguns/shotgun_13_uranium.png"):
		p.image = load("res://assets/Equipment/guns/shotguns/shotgun_13_uranium.png")

	pm.all_professions[108] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Gravitational Dreadnought Class (ID 108) registered.", "gareth-grav_dreadnought_mod")