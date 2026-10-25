class_name AirstrikeEquipEffect
extends EquipEffect

@export var strike_type: String = "dragon"

func physics_process(player, _delta: float) -> void:
	if Input.is_action_just_pressed("useItem") or Input.is_mouse_button_just_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_just_pressed(MOUSE_BUTTON_RIGHT):
		var tree = player.get_tree()
		if not tree or not tree.current_scene:
			return

		var script_map = {
			"dragon": "res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/dragon_strike.gd",
			"water": "res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/water_bomber_strike.gd",
			"poison": "res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/dragon_strike.gd",
			"b52": "res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/b52_carpet_strike.gd"
		}

		if script_map.has(strike_type):
			var sc = load(script_map[strike_type])
			if sc:
				var strike = Node2D.new()
				strike.set_script(sc)
				if strike_type == "poison":
					strike.modulate = Color(0.2, 1.0, 0.4)
				tree.current_scene.add_child(strike)

		# Consume 1 charge from player inventory
		var inv: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
		if inv and is_instance_valid(player) and ("item_equipped" in player) and player.item_equipped:
			inv.sellFromInventory(player.item_equipped, 1)
			Bus.inventory_changed.emit()
