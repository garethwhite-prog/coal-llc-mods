extends Object

func roll_loot(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	if Gvars.level == 101:
		var chest = chain.reference_object
		if chest and chest.loot:
			var itype: String = str(chest.loot.itemType).to_lower()
			var iid: String = str(chest.loot.itemID).to_lower()
			# Replace non-pickaxe weapon scrolls with passive upgrades
			if itype == "scroll" and not iid.contains("pickaxe"):
				var pass_res = load("res://resources/Items/power_ups/PassiveUpgrade.tres")
				if pass_res:
					chest.loot = pass_res.duplicate()
					chest.loot_count = 1
			elif itype not in ["gem", "ore", "pickaxe", "passive_upgrade", "scroll"]:
				var pass_res = load("res://resources/Items/power_ups/PassiveUpgrade.tres")
				if pass_res:
					chest.loot = pass_res.duplicate()
					chest.loot_count = 1
