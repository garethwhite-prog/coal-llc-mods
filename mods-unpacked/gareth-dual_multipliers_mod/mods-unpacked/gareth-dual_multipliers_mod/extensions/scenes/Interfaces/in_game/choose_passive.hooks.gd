extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var cp = chain.reference_object
	if cp:
		if not cp.ALL_PASSIVES.has("drill_speed"):
			cp.ALL_PASSIVES["drill_speed"] = 0.05
		if not "drill_speed" in cp.PASSIVE_MAP.get("drill", []):
			cp.PASSIVE_MAP["drill"].append("drill_speed")

		if not cp.ALL_PASSIVES.has("axe_speed"):
			cp.ALL_PASSIVES["axe_speed"] = 0.05
		if not "axe_speed" in cp.PASSIVE_MAP.get("axe", []):
			cp.PASSIVE_MAP["axe"].append("axe_speed")
		if not "axe_speed" in cp.PASSIVE_MAP.get("battleaxe", []):
			cp.PASSIVE_MAP["battleaxe"].append("axe_speed")

		if not cp.ALL_PASSIVES.has("gun_rate"):
			cp.ALL_PASSIVES["gun_rate"] = 0.05
		for g in ["pistol", "rifle", "minigun", "shotgun"]:
			if not "gun_rate" in cp.PASSIVE_MAP.get(g, []):
				cp.PASSIVE_MAP[g].append("gun_rate")

	chain.execute_next([])