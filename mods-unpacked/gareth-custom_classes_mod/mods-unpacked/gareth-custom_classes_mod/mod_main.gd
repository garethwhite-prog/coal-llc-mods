extends Node

const CLASSES_DEFINITIONS: Array[Dictionary] = [
	{
		"id": 101,
		"name": "Knight",
		"desc": "Master of chivalric blade combat.\nStarts with a Shoddy Sword.\nSwords cleave wide 180° arcs through rock and ore.",
		"img": "res://assets/Equipment/Sword-Shoddy.png",
		"starter_item": "res://mods-unpacked/gareth-custom_classes_mod/items/KnightSwordShoddy.tres",
		"debt": 0.0
	},
	{
		"id": 102,
		"name": "Jedi",
		"desc": "Wielder of the energetic Force.\nStarts with an Energy Saber and rapid Blaster sidearm.",
		"img": "res://assets/Laserbeam.png",
		"starter_item": "res://mods-unpacked/gareth-laser_beam_mod/items/LaserBeamItem.tres",
		"debt": 0.0
	},
	{
		"id": 103,
		"name": "Bouncing Demolitionist",
		"desc": "Specialist in chaotic kinetic ordnance.\nOrdnance rebounds off subterranean stone before detonating.",
		"img": "res://assets/Equipment/bombs/big_bomb_sheet_blue.png",
		"starter_item": "res://resources/Items/Equipment/Bombs/weak_bomb.tres",
		"debt": 0.0
	},
	{
		"id": 104,
		"name": "Rainbow Sinclairity",
		"desc": "Experimental spectral optics miner.\nMelts rock with continuous high-yield prismatic beam energy.",
		"img": "res://assets/LaserbeamEnd.png",
		"starter_item": "res://mods-unpacked/gareth-laser_beam_mod/items/LaserBeamItem.tres",
		"debt": 0.0
	},
	{
		"id": 105,
		"name": "Void Siphon",
		"desc": "Singularity master who starts with ZERO mining tools.\nCollapses subterranean rock directly inward into mineral shards.",
		"img": "res://assets/Equipment/magic/staffs/15_onyx_staff.png",
		"starter_item": "",
		"debt": 0.0
	},
	{
		"id": 106,
		"name": "Debt Executioner",
		"desc": "High-ranking corporate enforcer with late-game Onyx loadouts.\nStarts with -$50,000,000 corporate debt.\nMeet quotas or corporate Repo Drones hunt you down.",
		"img": "res://assets/Equipment/guns/miniguns/minigun_15_onyx.png",
		"starter_item": "res://resources/Items/Equipment/staffs/staff_15_onyx.tres",
		"debt": -50000000.0
	},
	{
		"id": 107,
		"name": "Chrono-Industrialist",
		"desc": "Temporal excavation engineer.\nEvery 10th strike deploys a Stasis Field, absorbing damage and releasing a 2x shockwave.",
		"img": "res://assets/Equipment/magic/staffs/14_moonstone_staff.png",
		"starter_item": "res://resources/Items/Equipment/Pickaxes/Pickaxe-Shoddy.tres",
		"debt": 0.0
	},
	{
		"id": 108,
		"name": "Gravitational Dreadnought",
		"desc": "Heavy armored fortress.\nExtreme mass; fired projectiles enter a circular orbit around the player.",
		"img": "res://assets/Equipment/guns/shotguns/shotgun_13_uranium.png",
		"starter_item": "res://resources/Items/Equipment/Guns/shotguns/shotgun_01_shoddy.tres",
		"debt": 0.0
	},
	{
		"id": 109,
		"name": "Tectonic Fracker",
		"desc": "Industrial seismic harvester.\nFires acoustic fracture pulses that shatter entire continuous ore seams simultaneously.",
		"img": "res://assets/Equipment/vehicles/tank_turret.png",
		"starter_item": "res://resources/Items/Equipment/Drills/drill_01_shoddy.tres",
		"debt": 0.0
	}
]

func _ready() -> void:
	_register_all_classes()

func _register_all_classes() -> void:
	if not Gvars or not ("profession_manager" in Gvars) or not Gvars.profession_manager:
		return

	var pm = Gvars.profession_manager
	var prof_script = load("res://resources/professions/scripts/profession.gd")

	for c in CLASSES_DEFINITIONS:
		var p_id: int = c["id"]
		var prof_obj = prof_script.new()
		prof_obj.profession_name = c["name"]
		prof_obj.description = c["desc"]
		if ResourceLoader.exists(c["img"]):
			prof_obj.image = load(c["img"])

		pm.all_professions[p_id] = {
			"profession": prof_obj,
			"is_unlocked": true
		}

	ModLoaderLog.info("Registered all 9 Custom Classes into ProfessionManager.", "gareth-custom_classes_mod")