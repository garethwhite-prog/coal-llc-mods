extends Object

const LOG_NAME := "gareth-plasma_raygun_mod:Hook"

static var fire_cooldown: float = 0.0
const FIRE_RATE: float = 0.09          # 11 pulses per second
const BEAM_MAX_RANGE: float = 240.0    # 15 tiles deep


func _physics_process(chain: ModLoaderHookChain, delta: float) -> void:
	chain.execute_next([delta])

	var player := chain.reference_object as Player
	if not player or not player.is_inside_tree():
		return

	fire_cooldown += delta

	# Real-time mouse aiming via Godot viewport
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and fire_cooldown >= FIRE_RATE:
		fire_cooldown = 0.0
		_fire_plasma_beam(player)


func _fire_plasma_beam(player: Player) -> void:
	var start_pos: Vector2 = player.global_position
	# Engine-level mouse position in world space
	var mouse_world_pos: Vector2 = player.get_global_mouse_position()
	var dir: Vector2 = (mouse_world_pos - start_pos).normalized()

	if dir.length_squared() == 0.0:
		dir = Vector2.DOWN

	var end_pos: Vector2 = start_pos + (dir * BEAM_MAX_RANGE)

	# Calculate damage scaled to equipped weapon tier & player passives
	var weapon_base: float = player.pickaxe_strength * player.strength_buff
	var passive_damage_mult: float = 1.0
	if Gvars and Gvars.get("passives") and Gvars.passives.get("player_pickaxe_mining_damage"):
		passive_damage_mult += Gvars.passives.player_pickaxe_mining_damage

	# Tick damage scales at 35% of full swing strength (~3.8x pickaxe DPS)
	var tick_damage: float = max(15.0, weapon_base * passive_damage_mult * 0.35)

	# 1. Penetrate through tiles along the aim vector
	var steps: int = int(BEAM_MAX_RANGE / 16.0)
	for i in range(1, steps + 1):
		var step_pos: Vector2 = start_pos + (dir * (i * 16.0))
		Bus.DamageTile.emit(step_pos, tick_damage)

		if player.tilemap and player.tilemap.sparks_manager and randf() < 0.35:
			player.tilemap.sparks_manager.add_spark(step_pos)

	# 2. Terminal explosion scaled to weapon tier
	var explosion_dmg: float = tick_damage * 1.5
	Bus.BombExplode.emit(end_pos, 1.6, explosion_dmg)

	# 3. Dynamic laser graphic (beam thickness scales with weapon power)
	if player.get_parent():
		var beam := Line2D.new()
		beam.width = clamp(weapon_base * 0.3, 3.0, 9.0)
		beam.default_color = Color(0.15, 0.9, 1.0, 0.95)
		beam.points = PackedVector2Array([start_pos, end_pos])
		player.get_parent().add_child(beam)

		var tween := player.create_tween()
		tween.tween_property(beam, "width", 0.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_callback(beam.queue_free)

	# 4. Audio feedback
	if player.pickaxe_strike:
		player.pickaxe_strike.pitch_scale = randf_range(1.7, 2.1)
		player.pickaxe_strike.play()