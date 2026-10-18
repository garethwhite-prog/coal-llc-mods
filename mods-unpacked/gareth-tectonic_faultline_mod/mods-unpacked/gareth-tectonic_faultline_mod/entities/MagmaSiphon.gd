class_name MagmaSiphon
extends Node2D

enum ElementType { FIRE, WATER, POISON }

var element_type: ElementType = ElementType.FIRE
var in_range: bool = false
var vented: bool = false
var sprite: Sprite2D
var prompt_label: Label
var tex_active: Texture2D
var tex_vented: Texture2D
var cached_player: Node2D = null

# Animated Shockwave Ring
var fx_radius: float = 0.0
var fx_alpha: float = 0.0
var fx_color: Color = Color(1.0, 0.15, 0.15)

func _ready() -> void:
	z_index = 6
	
	var img_active = Image.load_from_file("res://mods-unpacked/gareth-tectonic_faultline_mod/assets/magma_siphon_active.png")
	if img_active:
		tex_active = ImageTexture.create_from_image(img_active)
	
	var img_vented = Image.load_from_file("res://mods-unpacked/gareth-tectonic_faultline_mod/assets/magma_siphon_vented.png")
	if img_vented:
		tex_vented = ImageTexture.create_from_image(img_vented)
	
	sprite = Sprite2D.new()
	sprite.texture = tex_active
	add_child(sprite)
	
	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(-85, -28)
	prompt_label.add_theme_font_size_override("font_size", 9)
	prompt_label.add_theme_constant_override("outline_size", 3)
	prompt_label.visible = false
	add_child(prompt_label)
	
	_apply_visual_styling()

func set_element(type_str: String) -> void:
	match type_str.to_lower():
		"water":
			element_type = ElementType.WATER
		"poison":
			element_type = ElementType.POISON
		_:
			element_type = ElementType.FIRE
	_apply_visual_styling()

func _apply_visual_styling() -> void:
	if not sprite or not prompt_label:
		return
	match element_type:
		ElementType.WATER:
			# Vivid Electric Blue
			sprite.modulate = Color(0.2, 0.55, 1.4, 1.0)
			fx_color = Color(0.2, 0.6, 1.0)
			prompt_label.text = "[E] VENT GEYSER  |  [CLICK] RUPTURE"
			prompt_label.add_theme_color_override("font_color", Color(0.3, 0.75, 1.0, 1.0))
			prompt_label.add_theme_color_override("font_outline_color", Color(0.0, 0.15, 0.4, 1.0))
		ElementType.POISON:
			# Vivid Toxic Green
			sprite.modulate = Color(0.25, 1.3, 0.25, 1.0)
			fx_color = Color(0.25, 0.95, 0.25)
			prompt_label.text = "[E] VENT ACID  |  [CLICK] DISSOLVE"
			prompt_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.35, 1.0))
			prompt_label.add_theme_color_override("font_outline_color", Color(0.05, 0.3, 0.05, 1.0))
		_:
			# Vivid Crimson Red (Magma)
			sprite.modulate = Color(1.4, 0.2, 0.2, 1.0)
			fx_color = Color(1.0, 0.15, 0.15)
			prompt_label.text = "[E] VENT MAGMA  |  [CLICK] DETONATE"
			prompt_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25, 1.0))
			prompt_label.add_theme_color_override("font_outline_color", Color(0.35, 0.05, 0.05, 1.0))

func _get_player() -> Node2D:
	if cached_player and is_instance_valid(cached_player):
		return cached_player
	if Game and "player" in Game and is_instance_valid(Game.player):
		cached_player = Game.player
		return cached_player
	var tree = get_tree()
	if not tree:
		return null
	var p2 = tree.root.find_child("Player2", true, false)
	if p2 and is_instance_valid(p2) and p2 is Node2D:
		cached_player = p2
		return cached_player
	var p = tree.root.find_child("Player", true, false)
	if p and is_instance_valid(p) and p is Node2D:
		cached_player = p
		return cached_player
	return null

func _get_tile_map_manager() -> Node:
	var n = get_parent()
	while n:
		if n.has_method("burn_tile") and n.has_method("damageTile"):
			return n
		n = n.get_parent()
	var tree = get_tree()
	if tree and tree.root:
		return tree.root.find_child("TileMapManager", true, false)
	return null

func _get_scaling_multiplier() -> float:
	var depth_stratum: float = maxf(1.0, 1.0 + abs(global_position.y) / 160.0)
	var depth_factor: float = pow(depth_stratum, 1.45)
	
	var chest_mult: float = 1.0
	if "chest_bonus" in Gvars:
		chest_mult += float(Gvars.chest_bonus)
	if "passives" in Gvars and "chest_rewards" in Gvars.passives:
		chest_mult += float(Gvars.passives.chest_rewards)
	if "multiplier" in Gvars:
		chest_mult *= maxf(1.0, float(Gvars.multiplier))
	
	return depth_factor * chest_mult

func _process(_delta: float) -> void:
	if vented:
		return
	
	var player = _get_player()
	if not player:
		return
	
	var dist: float = global_position.distance_to(player.global_position)
	if dist <= 54.0:
		if not in_range:
			in_range = true
			prompt_label.visible = true
			if Bus and Bus.has_signal("ShowInputIndicator"):
				Bus.ShowInputIndicator.emit("interact", true, self)
		
		# 1. Controlled Safe Venting via [E]
		if Input.is_action_just_pressed("interact"):
			vent_controlled(player)
		
		# 2. Volatile Rupture via Left-Click
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var mouse_pos = get_global_mouse_position()
			if global_position.distance_to(mouse_pos) <= 54.0 or dist <= 38.0:
				breach_volatile()
	else:
		if in_range:
			in_range = false
			prompt_label.visible = false
			if Bus and Bus.has_signal("ShowInputIndicator"):
				Bus.ShowInputIndicator.emit("interact", false, self)

func vent_controlled(player: Node2D) -> void:
	if vented:
		return
	vented = true
	in_range = false
	prompt_label.visible = false
	if Bus and Bus.has_signal("ShowInputIndicator"):
		Bus.ShowInputIndicator.emit("interact", false, self)
	
	_trigger_visual_eruption(false)
	
	# Updraft velocity (Water geyser has highest skyward launch)
	if player and ("velocity" in player):
		match element_type:
			ElementType.WATER:
				player.velocity.y = -950.0
			ElementType.POISON:
				player.velocity.y = -700.0
			_:
				player.velocity.y = -800.0
	
	var scale_mult = _get_scaling_multiplier()
	var bounty: float = (20000.0 + (abs(global_position.y) * 14.0)) * maxf(1.0, scale_mult * 0.4)
	Gvars.CashCount += bounty
	if Bus and Bus.has_signal("UpdateUI"):
		Bus.UpdateUI.emit()
	
	_spawn_loot(false)
	
	var core_damage: float = 35000.0 * scale_mult
	_start_fluid_cascade(3.5, core_damage, false)
	
	var depth_mult: float = maxf(2.5, minf(8.0, 2.5 + abs(global_position.y) / 180.0))
	if Bus and Bus.has_signal("choose_passive"):
		Bus.choose_passive.emit(depth_mult)
	
	ModLoaderLog.info("Elemental Pod vented (%s)! Updraft + Scaled Bounty: $%d" % [ElementType.keys()[element_type], int(bounty)], "gareth-tectonic_faultline_mod")

func breach_volatile() -> void:
	if vented:
		return
	vented = true
	in_range = false
	prompt_label.visible = false
	if Bus and Bus.has_signal("ShowInputIndicator"):
		Bus.ShowInputIndicator.emit("interact", false, self)
	
	_trigger_visual_eruption(true)
	
	var scale_mult = _get_scaling_multiplier()
	var bounty: float = (12000.0 + (abs(global_position.y) * 8.0)) * maxf(1.0, scale_mult * 0.35)
	Gvars.CashCount += bounty
	if Bus and Bus.has_signal("UpdateUI"):
		Bus.UpdateUI.emit()
	
	_spawn_loot(true)
	
	var core_damage: float = 120000.0 * scale_mult
	_start_fluid_cascade(5.5, core_damage, true)
	
	var depth_mult: float = maxf(2.0, minf(6.5, 2.0 + abs(global_position.y) / 220.0))
	if Bus and Bus.has_signal("choose_passive"):
		Bus.choose_passive.emit(depth_mult)
	
	ModLoaderLog.info("Elemental Pod breached (%s)! Massive scaled seismic detonation!" % ElementType.keys()[element_type], "gareth-tectonic_faultline_mod")

func _spawn_loot(is_breach: bool) -> void:
	if not Bus or not Bus.has_signal("drop_loot"):
		return
	var item_path = "res://resources/Items/Coal.tres"
	var count = randi_range(24, 45) if is_breach else randi_range(10, 20)
	Bus.drop_loot.emit(global_position + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)), item_path, count)

func _start_fluid_cascade(radius: float, damage: float, is_breach: bool) -> void:
	var tm_mgr = _get_tile_map_manager()
	var scale_mult = _get_scaling_multiplier()
	
	# Wave 1: Immediate explosive core shockwave
	if Bus and Bus.has_signal("BombExplode"):
		Bus.BombExplode.emit(global_position, radius, damage)
	
	var r_int: int = int(ceil(radius))
	for dx in range(-r_int, r_int + 1):
		for dy in range(-r_int, r_int + 1):
			if Vector2(dx, dy).length() <= radius:
				var target_pos = global_position + Vector2(dx * 16.0, dy * 16.0)
				_apply_element_to_tile(tm_mgr, target_pos, damage, scale_mult)
	
	# Wave 2: Lateral splatter spread after 0.14s
	get_tree().create_timer(0.14).timeout.connect(func():
		var lat_radius = radius + 1.5
		for dx in range(-int(lat_radius), int(lat_radius) + 1):
			for dy in range(-1, 2):
				var target_pos = global_position + Vector2(dx * 16.0, dy * 16.0)
				_apply_element_to_tile(tm_mgr, target_pos, damage * 0.6, scale_mult)
	)
	
	# Wave 3: Downward gravitational drip & seep after 0.28s
	get_tree().create_timer(0.28).timeout.connect(func():
		var drip_depth = 6 if is_breach else 4
		for dy in range(1, drip_depth + 1):
			for dx in range(-2, 3):
				var drip_pos = global_position + Vector2(dx * 16.0, dy * 16.0)
				_apply_element_to_tile(tm_mgr, drip_pos, damage * 0.45, scale_mult)
	)

func _apply_element_to_tile(tm_mgr: Node, pos: Vector2, dmg: float, scale_mult: float) -> void:
	if Bus and Bus.has_signal("DamageTile"):
		Bus.DamageTile.emit(pos, dmg)
	
	if not tm_mgr:
		return
	
	match element_type:
		ElementType.FIRE:
			var burn_dps: float = 250.0 * scale_mult
			var burn_ticks: int = 6
			if tm_mgr.has_method("burn_tile"):
				tm_mgr.burn_tile(pos, burn_dps, burn_ticks)
		ElementType.WATER:
			if tm_mgr.has_method("wet_tile"):
				tm_mgr.wet_tile(pos)
			if Bus and Bus.has_signal("DamageTile"):
				Bus.DamageTile.emit(pos, dmg * 0.5)
		ElementType.POISON:
			var poison_dps: float = 320.0 * scale_mult
			var poison_ticks: int = 8
			if tm_mgr.has_method("poison_tile"):
				tm_mgr.poison_tile(pos, poison_dps, poison_ticks)

func _trigger_visual_eruption(is_explosion: bool) -> void:
	if tex_vented:
		sprite.texture = tex_vented
	sprite.modulate = Color(0.25, 0.25, 0.3, 0.85)
	
	var sfx_stream = load("res://assets/sound/sound effects/chestOpen.wav")
	if sfx_stream:
		var sfx = AudioStreamPlayer2D.new()
		sfx.stream = sfx_stream
		sfx.pitch_scale = 0.65 if is_explosion else 1.25
		add_child(sfx)
		sfx.play()
	
	# Primary Elemental Particle Burst
	var p_elem = CPUParticles2D.new()
	p_elem.emitting = true
	p_elem.one_shot = true
	p_elem.explosiveness = 0.95
	p_elem.amount = 65 if is_explosion else 35
	p_elem.lifetime = 0.9
	p_elem.direction = Vector2(0, -1)
	p_elem.spread = 180.0 if is_explosion else 55.0
	p_elem.gravity = Vector2(0, 420)
	p_elem.initial_velocity_min = 220.0 if is_explosion else 270.0
	p_elem.initial_velocity_max = 420.0 if is_explosion else 480.0
	p_elem.scale_amount_min = 4.0
	p_elem.scale_amount_max = 9.5
	
	match element_type:
		ElementType.WATER:
			p_elem.color = Color(0.2, 0.6, 1.0, 0.95)
		ElementType.POISON:
			p_elem.color = Color(0.25, 0.95, 0.25, 0.95)
		_:
			p_elem.color = Color(1.0, 0.15, 0.15, 1.0)
	add_child(p_elem)
	
	# Gravity Drip / Droplet Particles
	var p_drip = CPUParticles2D.new()
	p_drip.emitting = true
	p_drip.one_shot = true
	p_drip.explosiveness = 0.8
	p_drip.amount = 40
	p_drip.lifetime = 1.3
	p_drip.direction = Vector2(0, 1)
	p_drip.spread = 60.0
	p_drip.gravity = Vector2(0, 500)
	p_drip.initial_velocity_min = 80.0
	p_drip.initial_velocity_max = 180.0
	p_drip.scale_amount_min = 3.0
	p_drip.scale_amount_max = 6.5
	p_drip.color = p_elem.color
	add_child(p_drip)
	
	# Expanding Shockwave Ring
	var tw = create_tween()
	fx_radius = 8.0
	fx_alpha = 1.0
	var target_radius = 120.0 if is_explosion else 75.0
	tw.tween_property(self, "fx_radius", target_radius, 0.52).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "fx_alpha", 0.0, 0.52)
	tw.tween_callback(func(): queue_redraw())

func _draw() -> void:
	if fx_alpha > 0.01:
		draw_arc(Vector2.ZERO, fx_radius, 0.0, TAU, 48, Color(fx_color.r, fx_color.g, fx_color.b, fx_alpha), 5.5)
		draw_arc(Vector2.ZERO, fx_radius * 0.7, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, fx_alpha * 0.8), 2.8)
		queue_redraw()
