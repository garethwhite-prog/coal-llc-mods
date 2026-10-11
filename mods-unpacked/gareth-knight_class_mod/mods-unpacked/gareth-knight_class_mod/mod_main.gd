extends Node

func _ready() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://resources/professions/scripts/profession.gd")
	var p = prof_script.new()
	p.profession_name = "Knight"
	p.description = "Master of chivalric blade combat.\nStarts with a Shoddy Sword.\nSwords cleave wide 180° arcs through rock and ore."
	if ResourceLoader.exists("res://assets/Equipment/Sword-Shoddy.png"):
		p.image = load("res://assets/Equipment/Sword-Shoddy.png")

	pm.all_professions[101] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Knight Class (ID 101) registered successfully.", "gareth-knight_class_mod")