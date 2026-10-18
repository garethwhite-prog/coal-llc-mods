class_name PassiveOrder
extends Control

var NanobotzAutoPassiveChooserMod = load("res://mods-unpacked/nanobotz-autopassivechooser/mod_main.gd")

@onready var profession_option: OptionButton = %ProfessionOption
@onready var skip_weapons_check: CheckBox = %SkipWeaponsCheck
@onready var reroll_check: CheckBox = %RerollCheck
@onready var grid: GridContainer = %Grid
@onready var template: Control = %Template

var player_profession: String
var template_children_count: int


func _ready() -> void:
	prepare_profession()
	prepare_grid_and_reroll()


func prepare_profession() -> void:
	player_profession = NanobotzAutoPassiveChooserMod.get_current_profession_or_default()

	if player_profession:
		var profession_index: int = 0
		for profession_idx in Gvars.get("profession_manager").get("all_professions"):
			var profession = Gvars.get("profession_manager").get("all_professions")[profession_idx]
			var profession_name = profession.profession.profession_name
			profession_option.add_item(profession_name)
			if profession_name.to_lower() == player_profession:
				profession_index = profession_option.item_count - 1
		
		profession_option.select(profession_index)
		profession_option.item_selected.connect(_on_profession_changed.bind())


func _on_profession_changed(idx) -> void:
	player_profession = profession_option.get_item_text(idx).to_lower()
	clear_grid()
	prepare_grid_and_reroll()


func clear_grid() -> void:
	for child in grid.get_children():
		grid.remove_child(child)


func get_possible_passives_for_professions(profession_name: String) -> Array:
	var passives: Array = []
	for profession_idx in Gvars.get("profession_manager").get("all_professions"):
		var profession = Gvars.get("profession_manager").get("all_professions")[profession_idx]
		if profession_name.to_lower() == profession.profession.profession_name.to_lower():
			var data = {"unlocked_passives": []}
			data = profession.profession._profession_effect(data)
			passives = data["unlocked_passives"].duplicate()
			break

	if passives.is_empty():
		passives = ChoosePassive.ALL_PASSIVES.keys().duplicate()

	# Ensure elemental & tick rate bonuses are always configurable
	var extras: Array = ["fire_damage", "wet_damage", "poison_damage", "elemental_tick_rate"]
	for ep in extras:
		if not passives.has(ep):
			passives.append(ep)

	return passives


func prepare_grid_and_reroll() -> void:
	template_children_count = grid.columns

	var config = NanobotzAutoPassiveChooserMod.get_or_create_config(player_profession)

	# Skip weapon pickups
	skip_weapons_check.button_pressed = config.data.skip_weapon_pickups

	# Reroll
	reroll_check.button_pressed = config.data.reroll_if_no_matches

	# Order
	var passive_order = config.data.passive_order
	var possible_passives := get_possible_passives_for_professions(player_profession)

	var order_index := {}
	for i in passive_order.size():
		order_index[passive_order[i].effect] = i

	possible_passives.sort_custom(func(a, b):
		var a_in := order_index.has(a)
		var b_in := order_index.has(b)

		if a_in and b_in:
			return order_index[a] < order_index[b]
		elif a_in:
			return true
		elif b_in:
			return false
		else:
			return a < b
	)

	for effect_name in possible_passives:
		var passive_settings := {}
		for passive in passive_order:
			if passive.effect == effect_name:
				passive_settings = passive

		var passive_enabled = passive_settings.enabled if passive_settings else false
		var passive_up_to = passive_settings.upTo if passive_settings else 0

		var template_controls := template.get_children()
		for control in template_controls:
			var new_control := control.duplicate()

			if new_control.name == "Enabled":
				new_control.button_pressed = passive_enabled
			elif new_control.name == "EffectName":
				new_control.text = effect_name.replace("_", " ").capitalize()
			elif new_control.name == "UpTo":
				if passive_up_to > 0:
					new_control.text = str(int(passive_up_to))
				new_control.text_changed.connect(_on_up_to_text_changed.bind(new_control))
			elif new_control.name == "ButtonUp":
				new_control.pressed.connect(_on_button_up_pressed.bind(effect_name))
			elif new_control.name == "ButtonDown":
				new_control.pressed.connect(_on_button_down_pressed.bind(effect_name))

			new_control.name += "$" + effect_name
			grid.add_child(new_control)


func _on_button_up_pressed(effect_name: String) -> void:
	move_controls(effect_name, true)


func _on_button_down_pressed(effect_name: String) -> void:
	move_controls(effect_name, false)


func move_controls(effect_name: String, up: bool) -> void:
	var child_offset := -template_children_count if up else template_children_count * 2
	var control_offset := 0 if up else -1
	var found_first := false

	var control_idx: int = 0
	for control in grid.get_children():
		if control.name.split("$")[1] == effect_name:
			found_first = true

			var new_pos := control_idx + child_offset + control_offset
			if new_pos < 0:
				continue

			grid.move_child(control, new_pos)
			if not up:
				control_idx -= 1
		elif found_first:
			break
			
		control_idx += 1


# Removes non-digits
func _on_up_to_text_changed(text: String, control: Control) -> void:
	if control is not LineEdit:
		return

	var te := control as LineEdit
	var old_text := text
	var caret := te.caret_column

	var new_text := ""
	var removed_before := 0

	for i in old_text.length():
		if old_text[i].is_valid_int():
			new_text += old_text[i]
		elif i < caret:
			removed_before += 1

	if new_text != old_text:
		te.text = new_text
		te.caret_column = max(caret - removed_before, 0)


func _on_confirm_pressed() -> void:
	var config = NanobotzAutoPassiveChooserMod.get_or_create_config(player_profession)

	# Skip weapon pickups
	config.data.skip_weapon_pickups = skip_weapons_check.button_pressed

	# Reroll
	config.data.reroll_if_no_matches = reroll_check.button_pressed

	# Order
	var passive_order = config.data.passive_order

	passive_order.clear()
	var prev_effect := ""
	var passive := {}
	for control in grid.get_children():
		var splits = control.name.split("$")

		if splits[1] != prev_effect:
			if not prev_effect.is_empty():
				if passive.enabled:
					passive_order.append(passive)
				passive = {}

			passive.effect = splits[1]
			prev_effect = splits[1]
				
		if splits[0] == "Enabled":
			passive.enabled = control.button_pressed
		if splits[0] == "UpTo":
			passive.upTo = int(control.text) if control.text else 0

	if passive.enabled:
		passive_order.append(passive)

	ModLoaderConfig.update_config(config)

	# reload
	clear_grid()
	prepare_grid_and_reroll()

	# queue_free()


func _on_cancel_pressed() -> void:
	# queue_free()
	pass


