extends Node

const MOD_DIR := "gareth-emergency_deposit_mod"
const SURVIVAL_RATE: float = 0.25
const COOLDOWN_SEC: float = 8.0

var _cooldown_left: float = 0.0
var _status_label: Label = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_ensure_hud_hint()
	ModLoaderLog.info("Emergency Deposit active (Hotkey E or F6: 25% ore survival).", MOD_DIR)

func _ensure_hud_hint() -> void:
	var layer := CanvasLayer.new()
	layer.name = "EmergencyDepositLayer"
	layer.layer = 40
	add_child(layer)

	_status_label = Label.new()
	_status_label.name = "EmergencyDepositHint"
	_status_label.position = Vector2(18, 120)
	_status_label.text = "[F6] Emergency Deposit (25% Ore)"
	_status_label.modulate = Color(1.0, 0.72, 0.25, 0.85)
	layer.add_child(_status_label)

func _process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(0.0, _cooldown_left - delta)

	if _status_label and is_instance_valid(_status_label):
		if _cooldown_left > 0.0:
			_status_label.text = "[F6] Beacon Recharging: %.1fs" % _cooldown_left
			_status_label.modulate = Color(0.75, 0.45, 0.45, 0.85)
		else:
			_status_label.text = "[F6] Emergency Deposit (25% Ore)"
			_status_label.modulate = Color(1.0, 0.72, 0.25, 0.85)

func _unhandled_input(event: InputEvent) -> void:
	if _cooldown_left > 0.0:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F6:
			_trigger_emergency_deposit()

func _trigger_emergency_deposit() -> void:
	var inv := _find_player_inventory()
	if not inv or not ("items" in inv):
		ModLoaderLog.warning("Emergency Deposit: Could not locate active player inventory.", MOD_DIR)
		return

	var total_surviving: int = 0
	var total_lost: int = 0

	for slot in inv.items:
		if not slot:
			continue
		var count: int = 0
		if "count" in slot:
			count = int(slot.count)
		elif "amount" in slot:
			count = int(slot.amount)
		elif "stack_count" in slot:
			count = int(slot.stack_count)

		if count <= 0:
			continue

		# Only 25% of ore survives teleportation (minimum 1 if at least 4, or floor/round)
		var survived: int = int(floor(float(count) * SURVIVAL_RATE))
		var lost: int = count - survived
		total_surviving += survived
		total_lost += lost

		if "count" in slot:
			slot.count = 0
		elif "amount" in slot:
			slot.amount = 0
		elif "stack_count" in slot:
			slot.stack_count = 0

	if total_surviving <= 0 and total_lost <= 0:
		ModLoaderLog.info("Emergency Deposit: No ore stacks in inventory to teleport.", MOD_DIR)
		return

	_credit_stockpile(total_surviving)
	_cooldown_left = COOLDOWN_SEC
	ModLoaderLog.info(
		"Emergency Deposit complete: Banked %d ore (25%% survived), %d ore lost in transit." % [total_surviving, total_lost],
		MOD_DIR
	)

func _find_player_inventory():
	if Gvars:
		for prop in ["player_inventory", "inventory", "PlayerInventory"]:
			if prop in Gvars and Gvars.get(prop):
				return Gvars.get(prop)
	var res_path := "res://resources/Inventories/PlayerInventory.tres"
	if ResourceLoader.exists(res_path):
		return load(res_path)
	return null

func _credit_stockpile(amount: int) -> void:
	if amount <= 0:
		return
	if Gvars:
		for prop in ["coal_count", "CoalCount", "ore_count", "stockpile_count"]:
			if prop in Gvars:
				Gvars.set(prop, Gvars.get(prop) + amount)
				return
	var tree := get_tree()
	if tree and tree.root:
		var stockpile := tree.root.find_child("*Stockpile*", true, false)
		if stockpile and stockpile.has_method("add_ore"):
			stockpile.call("add_ore", amount)
