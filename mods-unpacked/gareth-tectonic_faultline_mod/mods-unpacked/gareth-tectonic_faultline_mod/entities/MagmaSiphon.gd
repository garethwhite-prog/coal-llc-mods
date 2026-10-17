class_name MagmaSiphon
extends Node2D

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
	prompt_label.text = "[E] VENT (FLY)  |  [CLICK] BLAST"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(-75, -28)
	prompt_label.add_theme_font_size_override("font_size", 9)
	prompt_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.1, 1.0))
	prompt_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	prompt_label.add_theme_constant_override("outline_size", 3)
	prompt_label.visible = false
	add_child(prompt_label)

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

func _process(_delta: float) -> void:
	if vented:
		return
	
	var player = _get_player()
	if not player:
		return
	
	var dist: float = global_position.distance_to(player.global_position)
	if dist <= 46.0:
		if not in_range:
			in_range = true
			prompt_label.visible = true
			if Bus and Bus.has_signal("ShowInputIndicator"):
				Bus.ShowInputIndicator.emit("interact", true, self)
		
		# 1. Controlled Safe Venting via [E]
		if Input.is_action_just_pressed("interact"):
			vent_controlled(player)
		
		# 2. Volatile Breach via Left-Click Strike on Siphon
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var mouse_pos = get_global_mouse_position()
			if global_position.distance_to(mouse_pos) <= 24.0:
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
	
	# High-Velocity Geothermal Steam Updraft: Launches miner upward toward surface
	if player and ("velocity" in player):
		player.velocity.y = -750.0
	
	# Full energy bounty + coal loot
	var bounty: float = 18000.0 + (abs(global_position.y) * 12.0)
	Gvars.CashCount += bounty
	if Bus and Bus.has_signal("UpdateUI"):
		Bus.UpdateUI.emit()
	
	if Bus and Bus.has_signal("drop_loot"):
		Bus.drop_loot.emit(global_position + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0)), "res://resources/Items/Coal.tres", randi_range(8, 16))
	
	# Clear out surrounding chamber rock (3x3 tiles) with high demolition damage
	_pulverize_rock(2, 6000)
	
	# Passive perk card offer
	var depth_mult: float = maxf(2.5, minf(7.0, 2.5 + abs(global_position.y) / 200.0))
	if Bus and Bus.has_signal("choose_passive"):
		Bus.choose_passive.emit(depth_mult)
	
	ModLoaderLog.info("Magma Siphon vented! Updraft engaged + Bounty: $" + str(int(bounty)), "gareth-tectonic_faultline_mod")

func breach_volatile() -> void:
	if vented:
		return
	vented = true
	in_range = false
	prompt_label.visible = false
	if Bus and Bus.has_signal("ShowInputIndicator"):
		Bus.ShowInputIndicator.emit("interact", false, self)
	
	_trigger_visual_eruption(true)
	
	# Violent high-yield cavern blast (Carves a massive 7x7 cavern)
	_pulverize_rock(3, 15000)
	
	# Partial cash bounty + huge ore eruption
	var bounty: float = 10000.0 + (abs(global_position.y) * 6.0)
	Gvars.CashCount += bounty
	if Bus and Bus.has_signal("UpdateUI"):
		Bus.UpdateUI.emit()
	
	if Bus and Bus.has_signal("drop_loot"):
		Bus.drop_loot.emit(global_position + Vector2(randf_range(-16.0, 16.0), randf_range(-16.0, 16.0)), "res://resources/Items/Coal.tres", randi_range(20, 36))
	
	# Passive card offer
	var depth_mult: float = maxf(2.0, minf(5.5, 2.0 + abs(global_position.y) / 250.0))
	if Bus and Bus.has_signal("choose_passive"):
		Bus.choose_passive.emit(depth_mult)
	
	ModLoaderLog.info("Magma Siphon breached! Massive 7x7 seismic demolition blast!", "gareth-tectonic_faultline_mod")

func _pulverize_rock(tile_radius: int, dmg: int) -> void:
	var tm_mgr = get_tree().root.find_child("TileMapManager", true, false)
	if not tm_mgr:
		var parent = get_parent()
		if parent and parent.get_parent():
			tm_mgr = parent.get_parent()
	
	if not tm_mgr:
		return
	
	# Carve through surrounding tiles by checking all possible vanilla damage method signatures
	for dx in range(-tile_radius, tile_radius + 1):
		for dy in range(-tile_radius, tile_radius + 1):
			var target_pos = global_position + Vector2(dx * 16.0, dy * 16.0)
			if tm_mgr.has_method("damage_tile"):
				tm_mgr.damage_tile(target_pos, dmg)
			elif tm_mgr.has_method("damage_tiles"):
				tm_mgr.damage_tiles([target_pos], dmg)
			elif tm_mgr.has_method("damageTile"):
				tm_mgr.damageTile(target_pos, dmg)
			elif tm_mgr.has_method("destroy_tile_at"):
				tm_mgr.destroy_tile_at(target_pos)

func _trigger_visual_eruption(is_explosion: bool) -> void:
	# 1. Texture swap to dark vented obsidian
	if tex_vented:
		sprite.texture = tex_vented
	else:
		sprite.modulate = Color(0.2, 0.2, 0.25, 0.8)
	
	# 2. Audio playback
	var sfx_stream = load("res://assets/sound/sound effects/chestOpen.wav")
	if sfx_stream:
		var sfx = AudioStreamPlayer2D.new()
		sfx.stream = sfx_stream
		sfx.pitch_scale = 0.6 if is_explosion else 1.2
		add_child(sfx)
		sfx.play()
	
	# 3. Dense Magma Particle Burst
	var p_magma = CPUParticles2D.new()
	p_magma.emitting = true
	p_magma.one_shot = true
	p_magma.explosiveness = 0.95
	p_magma.amount = 60 if is_explosion else 30
	p_magma.lifetime = 0.85
	p_magma.direction = Vector2(0, -1)
	p_magma.spread = 180.0 if is_explosion else 60.0
	p_magma.gravity = Vector2(0, 400)
	p_magma.initial_velocity_min = 200.0 if is_explosion else 260.0
	p_magma.initial_velocity_max = 380.0 if is_explosion else 450.0
	p_magma.color = Color(1.0, 0.5, 0.05, 1.0)
	p_magma.scale_amount_min = 4.0
	p_magma.scale_amount_max = 9.0
	add_child(p_magma)
	
	# 4. Superheated Steam Column
	var p_steam = CPUParticles2D.new()
	p_steam.emitting = true
	p_steam.one_shot = true
	p_steam.explosiveness = 0.85
	p_steam.amount = 40
	p_steam.lifetime = 1.1
	p_steam.direction = Vector2(0, -1)
	p_steam.spread = 40.0
	p_steam.gravity = Vector2(0, -120)
	p_steam.initial_velocity_min = 240.0
	p_steam.initial_velocity_max = 420.0
	p_steam.color = Color(1.0, 0.92, 0.82, 0.7)
	p_steam.scale_amount_min = 5.0
	p_steam.scale_amount_max = 11.0
	add_child(p_steam)
	
	# 5. Expanding Thermal Shockwave Ring
	var tw = create_tween()
	fx_radius = 8.0
	fx_alpha = 1.0
	var target_radius = 110.0 if is_explosion else 70.0
	tw.tween_property(self, "fx_radius", target_radius, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "fx_alpha", 0.0, 0.5)
	tw.tween_callback(func(): queue_redraw())

func _draw() -> void:
	if fx_alpha > 0.01:
		draw_arc(Vector2.ZERO, fx_radius, 0.0, TAU, 48, Color(1.0, 0.6, 0.1, fx_alpha), 5.5)
		draw_arc(Vector2.ZERO, fx_radius * 0.7, 0.0, TAU, 48, Color(1.0, 0.95, 0.4, fx_alpha), 3.0)
		queue_redraw()
