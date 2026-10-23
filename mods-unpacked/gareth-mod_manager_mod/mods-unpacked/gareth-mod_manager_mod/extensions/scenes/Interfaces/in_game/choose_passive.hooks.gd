extends Object

const ALL_CUSTOM_PASSIVES: Array[String] = [
	"jedi_saber_damage",
	"jedi_swing_rate",
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
	"chrono_drill_haste",
	"sprint_speed"
]

func _process(chain: ModLoaderHookChain, delta: float) -> void:
	_ensure_passives(chain.reference_object)
	chain.execute_next([delta])

func _ready(chain: ModLoaderHookChain) -> void:
	_ensure_passives(chain.reference_object)
	chain.execute_next([])

func _on_button_pressed(chain: ModLoaderHookChain) -> void:
	_ensure_passives(chain.reference_object)
	chain.execute_next([])

func _on_button_2_pressed(chain: ModLoaderHookChain) -> void:
	_ensure_passives(chain.reference_object)
	chain.execute_next([])

func _on_button_3_pressed(chain: ModLoaderHookChain) -> void:
	_ensure_passives(chain.reference_object)
	chain.execute_next([])

func _ensure_passives(screen: Node) -> void:
	if not Gvars or not ("passives" in Gvars) or not (Gvars.passives is Dictionary):
		return

	for key in ALL_CUSTOM_PASSIVES:
		if not Gvars.passives.has(key):
			Gvars.passives[key] = 0.0

	if is_instance_valid(screen) and ("options" in screen) and screen.options is Array:
		for opt in screen.options:
			if opt and ("stat_name" in opt) and opt.stat_name != "":
				var sname: String = str(opt.stat_name)
				if not Gvars.passives.has(sname):
					Gvars.passives[sname] = 0.0
