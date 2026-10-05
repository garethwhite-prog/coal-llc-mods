extends Node

const MOD_DIR := "gareth-dual_multipliers_mod"

func _init() -> void:
	var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)

	# 1. Install Script Extension for passives.gd
	ModLoaderMod.install_script_extension(
		mod_dir_path.path_join("extensions/resources/passive_effects/ext_passives.gd")
	)

	# 2. Install Script Hooks
	ModLoaderMod.install_script_hooks(
		"res://scenes/Machinery/drill_bit_2.gd",
		mod_dir_path.path_join("extensions/scenes/Machinery/drill_bit_2.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/equipment/axe.gd",
		mod_dir_path.path_join("extensions/scenes/equipment/axe.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/equipment/battleaxe.gd",
		mod_dir_path.path_join("extensions/scenes/equipment/battleaxe.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/StateMachine/Player2/player_2.gd",
		mod_dir_path.path_join("extensions/scripts/StateMachine/Player2/player_2.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/in_game/choose_passive.gd",
		mod_dir_path.path_join("extensions/scenes/Interfaces/in_game/choose_passive.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://resources/professions/scripts/profession.gd",
		mod_dir_path.path_join("extensions/resources/professions/scripts/profession.hooks.gd")
	)

func _ready() -> void:
	# Inject static references immediately into ChoosePassive class
	var cp_script = load("res://scenes/Interfaces/in_game/choose_passive.gd")
	if cp_script:
		if not cp_script.ALL_PASSIVES.has("drill_speed"):
			cp_script.ALL_PASSIVES["drill_speed"] = 0.05
		if not "drill_speed" in cp_script.PASSIVE_MAP.get("drill", []):
			cp_script.PASSIVE_MAP["drill"].append("drill_speed")

		if not cp_script.ALL_PASSIVES.has("axe_speed"):
			cp_script.ALL_PASSIVES["axe_speed"] = 0.05
		if not "axe_speed" in cp_script.PASSIVE_MAP.get("axe", []):
			cp_script.PASSIVE_MAP["axe"].append("axe_speed")
		if not "axe_speed" in cp_script.PASSIVE_MAP.get("battleaxe", []):
			cp_script.PASSIVE_MAP["battleaxe"].append("axe_speed")

		if not cp_script.ALL_PASSIVES.has("gun_rate"):
			cp_script.ALL_PASSIVES["gun_rate"] = 0.05
		for g in ["pistol", "rifle", "minigun", "shotgun"]:
			if not "gun_rate" in cp_script.PASSIVE_MAP.get(g, []):
				cp_script.PASSIVE_MAP[g].append("gun_rate")

	ModLoaderLog.info("Dual-Multiplier Scaling Expansion initialized.", MOD_DIR)