class_name MagmaSiphon
extends Node2D

var in_range: bool = false
var vented: bool = false
var sprite: Sprite2D
var prompt_label: Label
var tex_active: Texture2D
var tex_vented: Texture2D
var cached_player: Node2D = null

func _ready() -> void:
	z_index = 5
	
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
	prompt_label.text = "[E] VENT SIPHON"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(-46, -26)
	prompt_label.add_theme_font_size_override("font_size", 10)
	prompt_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1, 1.0))
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
	if dist <= 38.0:
		if not in_range:
			in_range = true
			prompt_label.visible = true
			if Bus and Bus.has_signal("ShowInputIndicator"):
				Bus.ShowInputIndicator.emit("interact", true, self)
		
		if Input.is_action_just_pressed("interact"):
			vent_pressure()
	else:
		if in_range:
			in_range = false
			prompt_label.visible = false
			if Bus and Bus.has_signal("ShowInputIndicator"):
				Bus.ShowInputIndicator.emit("interact", false, self)

func vent_pressure() -> void:
	if vented:
		return
	vented = true
	in_range = false
	prompt_label.visible = false
	
	if Bus and Bus.has_signal("ShowInputIndicator"):
		Bus.ShowInputIndicator.emit("interact", false, self)
	
	# Visual state change to cooled obsidian
	if tex_vented:
		sprite.texture = tex_vented
	else:
		sprite.modulate = Color(0.2, 0.2, 0.25, 0.8)
	
	# Acoustic feedback
	var sfx_stream = load("res://assets/sound/sound effects/chestOpen.wav")
	if sfx_stream:
		var sfx = AudioStreamPlayer2D.new()
		sfx.stream = sfx_stream
		add_child(sfx)
		sfx.play()
	
	# Dispense superheated pyritic loot
	if Bus and Bus.has_signal("drop_loot"):
		Bus.drop_loot.emit(global_position + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0)), "res://resources/Items/Coal.tres", randi_range(6, 12))
	
	# Geothermal energy bounty
	var bounty: float = 12500.0 + (abs(global_position.y) * 8.0)
	Gvars.CashCount += bounty
	if Bus and Bus.has_signal("UpdateUI"):
		Bus.UpdateUI.emit()
	
	# Thermal shockwave fracture on surrounding rock
	var parent_chunk = get_parent()
	if parent_chunk and parent_chunk.get_parent() and parent_chunk.get_parent().has_method("damageTile"):
		var mgr = parent_chunk.get_parent()
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				mgr.damageTile(global_position + Vector2(dx * 16.0, dy * 16.0), 300)
	
	# High-tier thermal passive card selection
	var depth_mult: float = maxf(2.5, minf(7.0, 2.5 + abs(global_position.y) / 200.0))
	if Bus and Bus.has_signal("choose_passive"):
		Bus.choose_passive.emit(depth_mult)
	
	ModLoaderLog.info("Magma Siphon vented! Energy bounty: $" + str(int(bounty)) + " + Thermal cards offered.", "gareth-tectonic_faultline_mod")
