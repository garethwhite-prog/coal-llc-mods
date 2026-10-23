extends Object

const CUSTOM_PASSIVE_DEFAULTS: Dictionary = {
	"ball_blast_damage": 0.05, "ball_blast_radius": 0.05, "ball_fire_rate": 0.05,
	"chrono_tick_rate": 0.05, "chrono_shockwave_damage": 0.05, "chrono_stasis_duration": 0.05,
	"exec_damage": 0.05, "exec_fire_rate": 0.05, "exec_bounty": 0.05,
	"drill_speed": 0.05, "axe_speed": 0.05, "gun_rate": 0.05,
	"dread_shell_damage": 0.05, "dread_fire_rate": 0.05, "dread_impact_radius": 0.05,
	"jedi_saber_damage": 0.05, "jedi_swing_rate": 0.05, "jedi_cleave_reach": 0.05,
	"sword_damage": 0.05, "sword_speed": 0.05, "sword_range": 0.05,
	"sinclair_melt_damage": 0.05, "sinclair_beam_width": 0.05, "sinclair_spectrum_ticks": 0.05,
	"fracker_pulse_damage": 0.05, "fracker_seam_resonance": 0.05, "fracker_fire_rate": 0.05,
	"void_implosion_damage": 0.05, "void_pull_radius": 0.05, "void_event_horizon": 0.05
}

func set_up_buttons(chain: ModLoaderHookChain) -> void:
	var screen = chain.reference_object
	if not is_instance_valid(screen) or not ("choose_between" in screen):
		chain.execute_next([])
		return

	var buttons = [screen.button, screen.button_2, screen.button_3]
	for i in range(0, min(3, screen.choose_between.size())):
		var stat_name: String = str(screen.choose_between[i])
		var base_val: float = 0.05
		if screen.ALL_PASSIVES.has(stat_name):
			base_val = screen.ALL_PASSIVES[stat_name]
		elif CUSTOM_PASSIVE_DEFAULTS.has(stat_name):
			base_val = CUSTOM_PASSIVE_DEFAULTS[stat_name]

		var pct_str: String = str(screen.multiplier * (base_val * 100.0))
		buttons[i].text = "Increase " + stat_name.replace("_", " ").capitalize() + " +" + pct_str + "%"

func _on_button_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_click(chain, 0)

func _on_button_2_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_click(chain, 1)

func _on_button_3_pressed(chain: ModLoaderHookChain) -> void:
	_handle_button_click(chain, 2)

func _handle_button_click(chain: ModLoaderHookChain, button_idx: int) -> void:
	var screen = chain.reference_object
	if not is_instance_valid(screen) or not screen.live or not ("choose_between" in screen):
		chain.execute_next([])
		return

	if button_idx >= screen.choose_between.size():
		chain.execute_next([])
		return

	var stat_name: String = str(screen.choose_between[button_idx])
	if screen.ALL_PASSIVES.has(stat_name):
		chain.execute_next([])
		return

	# Handle custom class passive
	screen.live = false
	var base_val: float = CUSTOM_PASSIVE_DEFAULTS.get(stat_name, 0.05)
	var add_amount: float = screen.multiplier * base_val

	if Gvars and ("passives" in Gvars) and Gvars.passives:
		var p: Resource = Gvars.passives
		var cur_meta: float = 0.0
		if p.has_meta(stat_name):
			cur_meta = float(p.get_meta(stat_name))
		p.set_meta(stat_name, cur_meta + add_amount)

	if Gvars:
		if not ("custom_passives" in Gvars) or Gvars.custom_passives == null:
			Gvars.set("custom_passives", {})
		var cp = Gvars.get("custom_passives")
		if cp is Dictionary:
			cp[stat_name] = cp.get(stat_name, 0.0) + add_amount

	screen.get_tree().paused = false
	screen.queue_free()
