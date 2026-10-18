extends Object


var NanobotzAutoPassiveChooserMod = load("res://mods-unpacked/nanobotz-autopassivechooser/mod_main.gd")


func pickup_item(chain: ModLoaderHookChain):
	var chest := chain.reference_object as Chest

	var config = NanobotzAutoPassiveChooserMod.get_or_create_config()
	if config.data.skip_weapon_pickups and chest.loot.itemType not in ["gem", "passive_upgrade"]:
		var effect_text: Node = load("res://mods-unpacked/nanobotz-autopassivechooser/scenes/effect_gain.tscn").instantiate()
		var player: Player = Game.player
		player.add_child(effect_text)
		effect_text.set_text("Skipped " + chest.loot.itemName)
		return

	chain.execute_next()

