extends Node

func _ready() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://resources/professions/scripts/profession.gd")
	var p = prof_script.new()
	p.profession_name = "Bouncing Demolitionist"
	p.description = "Specialist in chaotic kinetic ordnance.\nHeavy ordnance rebounds off solid cavern walls before detonating."
	if ResourceLoader.exists("res://assets/Equipment/bombs/big_bomb_sheet_blue.png"):
		p.image = load("res://assets/Equipment/bombs/big_bomb_sheet_blue.png")

	pm.all_professions[103] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Bouncing Demolitionist Class (ID 103) registered.", "gareth-bouncing_demo_mod")