extends Object

const DEFAULT_BASE := Vector2(50.0, -55.0)

func check_inventory_count(chain: ModLoaderHookChain) -> void:
	var ufo = chain.reference_object
	if not is_instance_valid(ufo) or not ("inventory" in ufo) or not ("maxInventoryCount" in ufo):
		chain.execute_next([])
		return

	if "StateLabel" in ufo and is_instance_valid(ufo.StateLabel):
		ufo.StateLabel.text = Gconsts.add_comma_to_float_no_dp(ufo.maxInventoryCount)

	var capacity_mult: float = 1.0
	if Gvars and ("passives" in Gvars) and Gvars.passives:
		capacity_mult += Gvars.passives.employee_collector_capacity

	var max_cap: float = float(ufo.maxInventoryCount) * capacity_mult
	if float(ufo.inventory.inventoryCount) >= max_cap:
		ufo.set_deferred("monitorable", false)
		if "States" in ufo and ("RETURNING_TO_BASE" in ufo.States):
			ufo.state = ufo.States.RETURNING_TO_BASE
		if "baseCoords" in ufo and "models" in ufo and is_instance_valid(ufo.models):
			if ufo.baseCoords.x < ufo.global_position.x:
				ufo.models.scale.x = -1
			else:
				ufo.models.scale.x = 1

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	var ufo = chain.reference_object
	if not is_instance_valid(ufo):
		chain.execute_next([delta])
		return

	# State 2: States.RETURNING_TO_BASE
	if ufo.state == 2:
		var tree = ufo.get_tree()
		if tree:
			var target_dest := DEFAULT_BASE
			var vacs = tree.get_nodes_in_group("vacuum_cleaner")
			if vacs.size() > 0:
				var vac = vacs[0]
				if is_instance_valid(vac) and ("suck_end_physics_body" in vac) and vac.suck_end_physics_body:
					var nozzle_pos: Vector2 = vac.suck_end_physics_body.global_position
					var dist_to_base: float = ufo.global_position.distance_squared_to(DEFAULT_BASE)
					var dist_to_vac: float = ufo.global_position.distance_squared_to(nozzle_pos)
					if dist_to_vac < dist_to_base:
						target_dest = nozzle_pos

			if target_dest != DEFAULT_BASE:
				ufo.baseCoords = target_dest
				if ufo.global_position.distance_to(target_dest) <= 24.0:
					ufo.drop_off_in_stockpile()
					ufo.global_position = target_dest
					if "timer" in ufo and ufo.timer:
						ufo.timer.start(0.066)
					ufo.state = 3 # States.IDLE
					return
				else:
					var spd: float = ufo.moveSpeed * min(8.0, (1.0 + Gvars.passives.employee_collector_speed))
					ufo.movement_vector = (target_dest - ufo.global_position).normalized() * spd
					ufo.pass_point_positive = (target_dest.x - ufo.global_position.x) > 0
					ufo.y_pass_point_positive = (target_dest.y - ufo.global_position.y) > 0
					if "models" in ufo and is_instance_valid(ufo.models):
						if target_dest.x < ufo.global_position.x:
							ufo.models.scale.x = -1
						else:
							ufo.models.scale.x = 1
			else:
				ufo.baseCoords = DEFAULT_BASE
	elif ufo.state != 2 and ufo.baseCoords != DEFAULT_BASE:
		ufo.baseCoords = DEFAULT_BASE

	chain.execute_next([delta])
