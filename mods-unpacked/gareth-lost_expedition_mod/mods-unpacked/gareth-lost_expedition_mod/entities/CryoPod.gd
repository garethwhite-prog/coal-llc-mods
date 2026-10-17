class_name CryoPod
extends Node2D

var in_range: bool = false
var looted: bool = false
var sprite: Sprite2D
var prompt_label: Label
var tex_closed: Texture2D
var tex_opened: Texture2D
var cached_player: Node2D = null

func _ready() -> void:
	z_index = 5
	
	var img_closed = Image.load_from_file("res://mods-unpacked/gareth-lost_expedition_mod/assets/cryo_pod.png")
	if img_closed:
		tex_closed = ImageTexture.create_from_image(img_closed)
	
	var img_opened = Image.load_from_file("res://mods-unpacked/gareth-lost_expedition_mod/assets/cryo_pod_opened.png")
	if img_opened:
		tex_opened = ImageTexture.create_from_image(img_opened)
	
	sprite = Sprite2D.new()
	sprite.texture = tex_closed
	add_child(sprite)
	
	prompt_label = Label.new()
	prompt_label.text = "[E] RESCUE"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(-36, -26)
	prompt_label.add_theme_font_size_override("font_size", 10)
	prompt_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.9, 1.0))
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
	var p = tree.root.find_child("Player", true, false)
	if p and is_instance_valid(p) and p is Node2D:
		cached_player = p
		return cached_player
	var p2 = tree.root.find_child("Player2", true, false)
	if p2 and is_instance_valid(p2) and p2 is Node2D:
		cached_player = p2
		return cached_player
	for candidate in tree.get_nodes_in_group("player"):
		if is_instance_valid(candidate) and candidate is Node2D:
			cached_player = candidate
			return cached_player
	return null

func _process(_delta: float) -> void:
	if looted:
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
			rescue_worker()
	else:
		if in_range:
			in_range = false
			prompt_label.visible = false
			if Bus and Bus.has_signal("ShowInputIndicator"):
				Bus.ShowInputIndicator.emit("interact", false, self)

func rescue_worker() -> void:
	if looted:
		return
	looted = true
	in_range = false
	prompt_label.visible = false
	
	if Bus and Bus.has_signal("ShowInputIndicator"):
		Bus.ShowInputIndicator.emit("interact", false, self)
	
	# 1. Swap visual to evacuated chamber
	if tex_opened:
		sprite.texture = tex_opened
	else:
		sprite.modulate = Color(0.35, 0.4, 0.45, 0.7)
	
	# 2. Audio feedback
	var sfx_stream = load("res://assets/sound/sound effects/coolDing.wav")
	if sfx_stream:
		var sfx = AudioStreamPlayer2D.new()
		sfx.stream = sfx_stream
		add_child(sfx)
		sfx.play()
	
	# 3. Direct Workforce Ledger Persistence
	var emp_mgr = Gvars.employee_manager
	var rescued_title: String = "Expedition Specialist"
	var chosen_emp: EmployeeLevel = null
	if emp_mgr and emp_mgr.ALL_EMPLOYEES.size() > 0:
		chosen_emp = emp_mgr.ALL_EMPLOYEES[randi() % emp_mgr.ALL_EMPLOYEES.size()]
		var emp_key = chosen_emp.level_name
		
		# Directly credit roster dictionary (bypasses store purchase requirements)
		if not emp_mgr.employees.has(emp_key):
			emp_mgr.employees[emp_key] = 0.0
		emp_mgr.employees[emp_key] += 1.0
		
		# Unlock this tier and predecessor tiers so they are not hidden by more_employees_mod
		var curr = chosen_emp
		while curr:
			if emp_mgr.locked_employees.has(curr.level_name):
				emp_mgr.locked_employees.erase(curr.level_name)
			if "upgrades_from" in curr and curr.upgrades_from != curr.EmployeeLevelNames.NOTHING:
				curr = emp_mgr.get_employee_level_from_enum(curr.upgrades_from)
			else:
				break
		
		if EmployeeLevel.EmployeeLevelNames.keys().size() > chosen_emp.level_name:
			rescued_title = EmployeeLevel.EmployeeLevelNames.keys()[chosen_emp.level_name].capitalize()
		elif chosen_emp.get("level_name") != null:
			rescued_title = str(chosen_emp.level_name)
	
	# 4. Physically instantiate live worker directly inside MineRegion for current shift
	if chosen_emp:
		var mine_region = get_tree().root.find_child("MineRegion", true, false)
		var worker_instance = null
		var is_collector: bool = false
		if "type" in chosen_emp and chosen_emp.type == EmployeeLevel.EmployeeType.COLLECTOR:
			is_collector = true
		
		if is_collector:
			var ufo_scene = load("res://scenes/LootCollectorUFO.tscn")
			if ufo_scene:
				worker_instance = ufo_scene.instantiate()
				worker_instance.employee_level = chosen_emp
				worker_instance.count = 1.0
				worker_instance.global_position = global_position
		else:
			var miner_scene = load("res://scenes/AutoMiners/multi_miner.tscn")
			if miner_scene:
				worker_instance = miner_scene.instantiate()
				worker_instance.employee_level = chosen_emp
				worker_instance.count = 1.0
				var tm = get_tree().root.find_child("TileMapManager", true, false)
				if tm:
					worker_instance.tilemap = tm
				worker_instance.global_position = global_position
		
		if worker_instance:
			if mine_region:
				mine_region.add_child(worker_instance)
			else:
				get_parent().add_child(worker_instance)
	
	Gvars.CashCount += 10000.0
	if Bus and Bus.has_signal("UpdateUI"):
		Bus.UpdateUI.emit()
	
	ModLoaderLog.info("Cryo-Pod breached! Rescued " + rescued_title + " added to Org Chart & active in mine! Salvaged $10,000.", "gareth-lost_expedition_mod")
	
	# 5. Passive selection card bonus
	var depth_mult: float = maxf(2.0, minf(6.0, 2.0 + abs(global_position.y) / 250.0))
	if Bus and Bus.has_signal("choose_passive"):
		Bus.choose_passive.emit(depth_mult)
