cls

# ==============================================================================
# Coal LLC - 3x Pod Density & Distinct Element Colors (Red/Blue/Green)
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$modName    = "gareth-tectonic_faultline_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"
$hookZip    = "$steamRoot\mod-hooks.zip"
$helperPath = "$innerDir\helpers\TectonicFaultlineHelper.gd"
$siphonPath = "$innerDir\entities\MagmaSiphon.gd"

Set-Location $repo

Write-Host ">>> 1. Writing enhanced entities/MagmaSiphon.gd with vivid Red, Blue, and Green styling..." -ForegroundColor Cyan
@'
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
'@ | Set-Content -Path $siphonPath -Encoding UTF8
Write-Host "Updated: $siphonPath" -ForegroundColor Green

Write-Host "`n>>> 2. Updating TectonicFaultlineHelper.gd with 3x pod density loop..." -ForegroundColor Cyan
@'
class_name TectonicFaultlineHelper
extends RefCounted

const FAULTLINE_LEVEL_ID: int = 102
const CHUNK_SIZE: int = 16

static func is_faultline_level() -> bool:
	if Gvars:
		if "level" in Gvars and Gvars.level == FAULTLINE_LEVEL_ID:
			return true
		if "chosen_level" in Gvars and Gvars.chosen_level == FAULTLINE_LEVEL_ID:
			return true
		if "current_level" in Gvars and Gvars.current_level == FAULTLINE_LEVEL_ID:
			return true
	return false

func ensure_level_registered() -> void:
	register_faultline_level()

static func register_faultline_level() -> void:
	if not Gvars:
		return
	
	if "level_manager" in Gvars and Gvars.level_manager and ("all_levels" in Gvars.level_manager):
		var lvl_mgr = Gvars.level_manager
		if not lvl_mgr.all_levels.has(FAULTLINE_LEVEL_ID):
			var custom_level = GameLevel.new()
			custom_level.level_name = "Tectonic Faultline"
			custom_level.level = FAULTLINE_LEVEL_ID
			custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
			custom_level.level_description = "Seismic faultline with superheated vents, magma fissures, and elemental chambers.\n\nElemental pods contain explosive fluids and geothermal updrafts."
			custom_level.level_difficulty = GameLevel.Difficulty.HARD
			custom_level.unlock_description = ""
			
			var preview_path = "res://mods-unpacked/gareth-tectonic_faultline_mod/assets/tectonic_preview.png"
			var bytes = FileAccess.get_file_as_bytes(preview_path)
			if bytes and bytes.size() > 0:
				var f_img = Image.new()
				if f_img.load_png_from_buffer(bytes) == OK:
					custom_level.level_image = ImageTexture.create_from_image(f_img)
			
			lvl_mgr.all_levels[FAULTLINE_LEVEL_ID] = {
				"level": custom_level,
				"is_unlocked": true
			}
	
	if "level_info" in Gvars and Gvars.level_info is Dictionary:
		if not Gvars.level_info.has(FAULTLINE_LEVEL_ID):
			Gvars.level_info[FAULTLINE_LEVEL_ID] = {
				"name": "Tectonic Faultline",
				"description": "Seismic faultline with superheated vents, magma fissures, and elemental chambers.",
				"depth": 1400,
				"cost": 0,
				"unlocked": true
			}

static func calculate_faultline_tier(pos: Vector2i) -> int:
	var y_tile: int = pos.y
	# Sky contract: return -2 for sky / surface air
	if y_tile < 0:
		return -2
	elif y_tile < 24:
		return 1
	elif y_tile < 48:
		return 2
	elif y_tile < 80:
		return 3
	elif y_tile < 120:
		return 4
	elif y_tile < 170:
		return 5
	elif y_tile < 230:
		return 6
	elif y_tile < 300:
		return 7
	else:
		return min(12, 8 + int((y_tile - 300) / 80))

static func pick_faultline_block(chunk: Node, global_cell: Vector2i, noise: FastNoiseLite) -> int:
	if global_cell.y <= 0:
		return chunk.Tiles.EMPTY
	
	var tier: int = calculate_faultline_tier(global_cell)
	if tier < 0:
		return chunk.Tiles.EMPTY
	
	var rift_noise: float = abs(noise.get_noise_2d(float(global_cell.x) * 4.5, float(global_cell.y) * 1.2))
	if rift_noise < 0.09 and global_cell.y > 10:
		return chunk.Tiles.EMPTY
	
	var fissure_noise: float = noise.get_noise_2d(float(global_cell.x) * 2.8 + 50.0, float(global_cell.y) * 2.8)
	if fissure_noise > 0.42 and global_cell.y > 18:
		return chunk.Tiles.HARD_FIRE
	
	var base_tile: int = chunk.chest_block_from_level(tier)
	if base_tile == chunk.Tiles.EMPTY:
		base_tile = chunk.Tiles.HARD_FIRE
	return base_tile

static func generate_faultline_strata(chunk: Node, noise: FastNoiseLite) -> void:
	if not ("tiles" in chunk) or not ("chunk_size" in chunk):
		return
	
	for x in range(chunk.chunk_size):
		for y in range(chunk.chunk_size):
			var local_pos = Vector2i(x, y)
			var global_posi: Vector2i = Vector2i(chunk.to_global(chunk.map_to_local(local_pos)) / 16.0)
			
			if global_posi.y > 3:
				var idx: int = chunk.pos_to_array(local_pos) if chunk.has_method("pos_to_array") else (x + y * chunk.chunk_size)
				if idx >= 0 and idx < chunk.tiles.size():
					if chunk.tiles[idx] != chunk.Tiles.EMPTY:
						var new_block = pick_faultline_block(chunk, global_posi, noise)
						chunk.tiles[idx] = new_block
						chunk.build_tile(idx)

static func spawn_magma_siphons(chunk: Node, current_locs: Array[Vector2i]) -> Array[Vector2i]:
	if "chunk_pos" in chunk and chunk.chunk_pos.y < 1:
		return current_locs
	
	# Tripled pod generation: attempt 3 vaults per subterranean chunk
	var pods_to_spawn: int = 3
	var elements: Array[String] = ["fire", "water", "poison"]
	elements.shuffle()
	
	var width: int = 3
	var height: int = 3
	
	for p_idx in range(pods_to_spawn):
		var found_spot: bool = false
		var start_tile: Vector2i = Vector2i.ZERO
		
		# Attempt 12 random non-overlapping coordinates inside chunk
		for attempt in range(12):
			var candidate = Vector2i(
				randi_range(1, chunk.chunk_size - width - 1),
				randi_range(1, chunk.chunk_size - height - 1)
			)
			
			var overlaps: bool = false
			for ox in range(candidate.x - 1, candidate.x + width + 1):
				for oy in range(candidate.y - 1, candidate.y + height + 1):
					if Vector2i(ox, oy) in current_locs:
						overlaps = true
						break
				if overlaps:
					break
			
			if not overlaps:
				start_tile = candidate
				found_spot = true
				break
		
		if not found_spot:
			continue
		
		var local_start: Vector2 = chunk.map_to_local(start_tile)
		var world_start: Vector2 = chunk.to_global(local_start)
		var global_cell: Vector2i = Vector2i(world_start / 16.0)
		if global_cell.y < 10:
			continue
		
		# Vault perimeter walls (+2 tier harder rock)
		var pod_tier: int = calculate_faultline_tier(global_cell)
		var wall_tier: int = min(max(1, pod_tier + 2), 12)
		var wall_tile: int = chunk.chest_block_from_level(wall_tier)
		if wall_tile == chunk.Tiles.EMPTY:
			wall_tile = chunk.Tiles.HARD_DARK if global_cell.y > 40 else chunk.Tiles.HARD_FIRE
		
		# Reserve room footprint so chests and subsequent pods do not overlap
		for x in range(start_tile.x - 1, start_tile.x + width + 1):
			for y in range(start_tile.y - 1, start_tile.y + height + 1):
				current_locs.append(Vector2i(x, y))
		
		# Carve vault into tiles array and sync to GPU render cache via build_tile
		for x in range(start_tile.x, start_tile.x + width):
			for y in range(start_tile.y, start_tile.y + height):
				var local_coord = Vector2i(x, y)
				var c_idx: int = chunk.pos_to_array(local_coord)
				var is_wall = (x == start_tile.x or x == start_tile.x + width - 1 or y == start_tile.y or y == start_tile.y + height - 1)
				
				if is_wall:
					chunk.tiles[c_idx] = wall_tile
					chunk.build_tile(c_idx)
				else:
					chunk.tiles[c_idx] = chunk.Tiles.EMPTY
					chunk.build_tile(c_idx)
		
		# Spawn elemental pod entity inside hollowed vault center
		var SiphonScene = load("res://mods-unpacked/gareth-tectonic_faultline_mod/entities/MagmaSiphon.gd")
		if SiphonScene:
			var siphon = SiphonScene.new()
			var center_tile = Vector2i(start_tile.x + 1, start_tile.y + 1)
			siphon.position = chunk.map_to_local(center_tile)
			siphon.set_element(elements[p_idx % elements.size()])
			chunk.add_child(siphon)
	
	return current_locs
'@ | Set-Content -Path $helperPath -Encoding UTF8
Write-Host "Updated: $helperPath" -ForegroundColor Green

Write-Host "`n>>> 3. Writing tile_map_chunk.hooks.gd (routing generate_chests for vault placement)..." -ForegroundColor Cyan
@'
extends Object

func lvl_from_global_pos(chain: ModLoaderHookChain, pos: Vector2i) -> int:
	if Gvars.level == 102:
		var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
		if helper_script:
			return helper_script.calculate_faultline_tier(pos)
	return chain.execute_next([pos])

func generate_chunk(chain: ModLoaderHookChain, noise: Noise) -> void:
	chain.execute_next([noise])
	if Gvars.level == 102:
		var chunk = chain.reference_object
		if chunk and "chunk_pos" in chunk and chunk.chunk_pos.y >= 0:
			var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
			if helper_script:
				var fnl = FastNoiseLite.new()
				fnl.seed = Gvars.map_seed if ("map_seed" in Gvars) else 1337
				fnl.frequency = 0.035
				helper_script.generate_faultline_strata(chunk, fnl)

func generate_chests(chain: ModLoaderHookChain, current_block_chest_locations: Array[Vector2i]) -> Array[Vector2i]:
	var locs: Array[Vector2i] = chain.execute_next([current_block_chest_locations])
	if Gvars.level == 102:
		var chunk = chain.reference_object
		if chunk:
			var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
			if helper_script:
				locs = helper_script.spawn_magma_siphons(chunk, locs)
	return locs

func destroy_tile(chain: ModLoaderHookChain, idx: int, tile_properties: Dictionary) -> void:
	chain.execute_next([idx, tile_properties])
'@ | Set-Content -Path $chunkHook -Encoding UTF8
Write-Host "Updated: $chunkHook" -ForegroundColor Green

Write-Host "`n>>> 4. Flushing mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
}

Write-Host ">>> 5. Repackaging mod archive for Steam..." -ForegroundColor Cyan
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zipStream = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::CreateNew)
$archive   = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)
$allFiles  = Get-ChildItem -Path $outerDir -Recurse -File

foreach ($f in $allFiles) {
    $entryName = $f.FullName.Substring($outerDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$zipStream.Dispose()
Write-Host "Packed archive at: $zipPath" -ForegroundColor Green

Write-Host ">>> 6. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Implement 3x pod density, color-coded pods (Red/Blue/Green), -2 sky air return, and chunk.build_tile sync"
git push origin main

Write-Host "`nDeploy complete! Launch Coal LLC to test." -ForegroundColor Green