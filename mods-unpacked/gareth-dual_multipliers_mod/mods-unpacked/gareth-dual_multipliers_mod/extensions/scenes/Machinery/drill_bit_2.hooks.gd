extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var drill = chain.reference_object
	if drill:
		_apply_drill_speed(drill)

func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	var drill = chain.reference_object
	if drill:
		_apply_drill_speed(drill)
	chain.execute_next([delta])

func mine_ores(chain: ModLoaderHookChain) -> void:
	var drill = chain.reference_object
	if not drill or not drill.tilemap or not drill.drill:
		chain.execute_next([])
		return

	var spd: float = 0.0
	var dmg: float = 0.0
	if Gvars and ("passives" in Gvars) and Gvars.passives:
		var p = Gvars.passives
		if "drill_speed" in p:
			spd = float(p.drill_speed)
		if "drill_damage" in p:
			dmg = float(p.drill_damage)

	var pos: Vector2i = drill.tilemap.local_to_map(drill.drill.global_position + Vector2(0, -1))
	var eff_speed: float = max(1.0, 1.0 + spd)
	var anim_speed: float = clamp(eff_speed, 1.0, 16.0)
	var speed_overflow: float = eff_speed / anim_speed
	var total_damage: float = drill.damage * (1.0 + dmg) * speed_overflow

	drill.tilemap.damageTileCoords(pos + Vector2i(0, 1), total_damage)

func _apply_drill_speed(drill: Node2D) -> void:
	if Gvars and ("passives" in Gvars) and Gvars.passives:
		var p = Gvars.passives
		var spd: float = float(p.drill_speed) if ("drill_speed" in p) else 0.0
		var anim_speed: float = clamp(1.0 + spd, 1.0, 16.0)
		if "animation_player" in drill and drill.animation_player:
			drill.animation_player.speed_scale = anim_speed
		if "animation_player_2" in drill and drill.animation_player_2:
			drill.animation_player_2.speed_scale = anim_speed