extends Object

var NanobotzAutoPassiveChooserMod = load("res://mods-unpacked/nanobotz-autopassivechooser/mod_main.gd")


func _process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])

	var config = NanobotzAutoPassiveChooserMod.get_or_create_config()
	var passive_order = config.data.get("passive_order", []) if (config and "data" in config and config.data is Dictionary) else []
	var reroll_if_no_matches = config.data.reroll_if_no_matches

	var find_passive_idx := func (choose_between: Array) -> int:
		for passive in passive_order:
			# Respect the checkbox: never auto-pick disabled passives
			if not passive.get("enabled", false):
				continue

			for i in range(0, 3):
				var eff: String = choose_between[i]
				if eff == passive.effect:
					# Safe lookup across vanilla passives and mod custom_passives
					var cur_val: float = 0.0
					if Gvars and ("passives" in Gvars) and Gvars.passives and (eff in Gvars.passives):
						cur_val = float(Gvars.passives.get(eff)) * 100.0
					elif Gvars and ("custom_passives" in Gvars) and (Gvars.custom_passives is Dictionary) and Gvars.custom_passives.has(eff):
						cur_val = float(Gvars.custom_passives[eff]) * 100.0

					var cap: float = float(passive.get("upTo", 0.0))
					if cap <= 0.0 or cur_val < cap:
						return i
		return -1

	var orig := chain.reference_object as ChoosePassive
	if orig.live and len(orig.choose_between) > 0:
		var idx: int = find_passive_idx.call(orig.choose_between)
		var button_text: String = ""
		match idx:
			0:
				orig._on_button_pressed.call()
				button_text = orig.button.text
			1:
				orig._on_button_2_pressed.call()
				button_text = orig.button_2.text
			2:
				orig._on_button_3_pressed.call()
				button_text = orig.button_3.text
			_:
				if reroll_if_no_matches:
					orig._on_reroll_pressed.call()
					button_text = "Cash"

		if button_text != "":
			var effect_scene = load("res://mods-unpacked/nanobotz-autopassivechooser/scenes/effect_gain.tscn")
			if effect_scene:
				var effect_text: Node = effect_scene.instantiate()
				var player: Player = Game.player
				if player:
					player.add_child(effect_text)
					effect_text.set_text(button_text)

			ModLoaderLog.info("Auto choosing option " + str(idx) + ": " + button_text, NanobotzAutoPassiveChooserMod.MOD_ID)
