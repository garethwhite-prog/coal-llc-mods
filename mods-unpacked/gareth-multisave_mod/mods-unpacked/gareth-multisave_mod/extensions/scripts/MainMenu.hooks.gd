extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var menu = chain.reference_object
	if not menu:
		return

	var ssm = menu.get_node_or_null("/root/SaveSlotManager")
	if ssm and ssm.has_method("restore_career_progression"):
		ssm.restore_career_progression()

	var slot_num: int = ssm.current_slot if ssm else 1

	if "continue_game_button" in menu and menu.continue_game_button:
		menu.continue_game_button.text = "Resume Profile (Slot %d)" % slot_num
		if ssm and ssm.has_save(slot_num):
			menu.continue_game_button.disabled = false

	var btn_grid = menu.get_node_or_null("%MainMenuButtons")
	if btn_grid and not btn_grid.has_node("SaveProfilesButton"):
		var profile_btn := Button.new()
		profile_btn.name = "SaveProfilesButton"
		profile_btn.text = "Save Profiles"
		profile_btn.custom_minimum_size = Vector2(0, 32)
		profile_btn.pressed.connect(func(): _open_profiles_modal(menu))
		btn_grid.add_child(profile_btn)
		btn_grid.move_child(profile_btn, 1)

func _open_profiles_modal(menu: Control) -> void:
	var modal_script = load("res://mods-unpacked/gareth-multisave_mod/scenes/save_slot_modal.gd")
	var modal: Control = Control.new()
	modal.set_script(modal_script)

	modal.slot_chosen_play.connect(func(slot_id: int):
		var ssm = menu.get_node_or_null("/root/SaveSlotManager")
		if ssm:
			ssm.current_slot = slot_id
			ssm.prepare_vanilla_from_active_slot()
		modal.queue_free()
		menu.on_pressed_continuegame()
	)

	modal.slot_chosen_new.connect(func(slot_id: int):
		var ssm = menu.get_node_or_null("/root/SaveSlotManager")
		if ssm:
			ssm.current_slot = slot_id
			ssm.delete_slot(slot_id)
		modal.queue_free()
		menu.on_pressed_newgame()
	)

	menu.add_child(modal)