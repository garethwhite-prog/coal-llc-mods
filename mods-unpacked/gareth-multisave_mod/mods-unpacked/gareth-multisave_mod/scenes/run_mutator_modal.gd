class_name RunMutatorModal
extends PanelContainer

signal confirmed()

var active_toggles: Dictionary = {}

const MUTATORS: Array[Dictionary] = [
	{"key": "dual_multipliers", "label": "Dual-Multiplier Quadratic Scaling", "desc": "Gives Drills, Axes & Firearms secondary scaling stats.", "default": true},
	{"key": "bouncing_grenades", "label": "Bouncing Grenade Arsenal", "desc": "15-tier parabolic rebounding explosives.", "default": true},
	{"key": "water_spirit", "label": "Orbital Water Spirit Familiar", "desc": "Saturates strata within an expanding orbit.", "default": true},
	{"key": "vacuum_depot", "label": "Subterranean Vacuum Depot Offload", "desc": "UFOs offload cargo into deep vacuum nozzles.", "default": true},
	{"key": "seismic_hazards", "label": "[Hardcore] Seismic Hazards & Cave-Ins", "desc": "Mining deep rock triggers rockfalls from above.", "default": false},
	{"key": "uranium_gas", "label": "[Hardcore] Pressurized Uranium Gas Pockets", "desc": "Exposing uranium leaks explosive radioactive gas.", "default": false},
	{"key": "liquefaction", "label": "[Hardcore] Liquefaction Fluid Strata", "desc": "Explosions cause rock to flow downward like liquid sand.", "default": false},
	{"key": "debt_executioner", "[Hardcore] Corporate Debt Executioner", "desc": "Start with -$50M debt; Repo Drones hunt you if quotas fail.", "default": false}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(760, 480)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.text = "[b][font_size=20]Select Active Mods & Mutators for this Run[/font_size][/b]\n[color=gray]Customize your active expansions and difficulty modifiers for this save profile.[/color]"
	title.fit_content = true
	title.custom_minimum_size = Vector2(0, 48)
	vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	for mut in MUTATORS:
		var cb := CheckBox.new()
		cb.text = mut["label"] + "  —  " + mut["desc"]
		cb.button_pressed = mut["default"]
		active_toggles[mut["key"]] = mut["default"]
		var k: String = mut["key"]
		cb.toggled.connect(func(val: bool): active_toggles[k] = val)
		list.add_child(cb)

	var confirm_btn := Button.new()
	confirm_btn.text = "Confirm & Proceed to Level Select"
	confirm_btn.custom_minimum_size = Vector2(0, 38)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	vbox.add_child(confirm_btn)

func _on_confirm_pressed() -> void:
	var ssm = get_node_or_null("/root/SaveSlotManager")
	if ssm:
		var cfg := {"mods": active_toggles}
		var file := FileAccess.open(ssm.get_slot_config_path(ssm.current_slot), FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(cfg, "\t"))
			file.close()
	confirmed.emit()
	queue_free()