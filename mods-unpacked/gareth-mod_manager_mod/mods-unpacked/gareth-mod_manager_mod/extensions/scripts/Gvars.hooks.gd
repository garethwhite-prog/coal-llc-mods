extends Object

const CUSTOM_PASSIVE_KEYS: Array[String] = [
	"jedi_saber_damage",
	"jedi_cleave_reach",
	"jedi_reflection_chance",
	"knight_shield_block",
	"knight_armor_plating",
	"sinclairity_beam_width",
	"sinclairity_refraction",
	"tank_cannon_damage",
	"tank_blast_radius",
	"tectonic_quake_reach",
	"void_siphon_potency",
	"chrono_drill_haste"
]

func reset_resources(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	_ensure_custom_passives()

func _ensure_custom_passives() -> void:
	if not Gvars or not ("passives" in Gvars) or not (Gvars.passives is Dictionary):
		return
	for key in CUSTOM_PASSIVE_KEYS:
		if not Gvars.passives.has(key):
			Gvars.passives[key] = 0.0
