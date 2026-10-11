extends Node

func _ready() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return
	var pm = Gvars.profession_manager
	var prof_script = load("res://resources/professions/scripts/profession.gd")
	var p = prof_script.new()
	p.profession_name = "Debt Executioner"
	p.description = "Corporate enforcer with late-game Onyx loadouts.\nStarts with -$50,000,000 debt.\nMeet quotas or corporate Repo Drones hunt you down."
	if ResourceLoader.exists("res://assets/Equipment/guns/miniguns/minigun_15_onyx.png"):
		p.image = load("res://assets/Equipment/guns/miniguns/minigun_15_onyx.png")

	pm.all_professions[106] = { "profession": p, "is_unlocked": true }
	ModLoaderLog.info("Debt Executioner Class (ID 106) registered.", "gareth-debt_executioner_mod")