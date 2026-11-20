extends Node

const MOD_DIR := "gareth-emergency_deposit_mod"
const SURVIVAL_RATE: float = 0.25
const COOLDOWN_SEC: float = 8.0
const FEEDBACK_SEC: float = 3.0
const STOCKPILABLE_TYPES: Array[String] = ["coal", "gem", "mineral"]

var _cooldown_left: float = 0.0
var _feedback_left: float = 0.0
var _feedback_text: String = ""
var _feedback_color: Color = Color(0.45, 1.0, 0.55, 0.95)
var _prev_hotkey_down: bool = false
var _status_label: Label = null
var _cached_stockpile: Node = null
var _scene_check_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _ensure_hud_hint()
    ModLoaderLog.info("Emergency Deposit controller ready (F6 or G in mine: 25% ore survival).", MOD_DIR)

func _ensure_hud_hint() -> void:
    var layer := CanvasLayer.new()
    layer.name = "EmergencyDepositLayer"
    layer.layer = 40
    add_child(layer)

    _status_label = Label.new()
    _status_label.name = "EmergencyDepositHint"
    _status_label.position = Vector2(18, 120)
    _status_label.text = "[F6 / G] Emergency Deposit (25% Ore)"
    _status_label.modulate = Color(1.0, 0.72, 0.25, 0.90)
    _status_label.visible = false
    layer.add_child(_status_label)

func _process(delta: float) -> void:
    if _cooldown_left > 0.0:
        _cooldown_left = maxf(0.0, _cooldown_left - delta)
    if _feedback_left > 0.0:
        _feedback_left = maxf(0.0, _feedback_left - delta)

    _scene_check_timer -= delta
    if _scene_check_timer <= 0.0 or not is_instance_valid(_cached_stockpile):
        _scene_check_timer = 0.5
        _cached_stockpile = _find_active_stockpile()

    var in_mine: bool = is_instance_valid(_cached_stockpile)
    if _status_label and is_instance_valid(_status_label):
        _status_label.visible = in_mine
        if in_mine:
            if _feedback_left > 0.0:
                _status_label.text = _feedback_text
                _status_label.modulate = _feedback_color
            elif _cooldown_left > 0.0:
                _status_label.text = "[F6 / G] Beacon Recharging: %.1fs" % _cooldown_left
                _status_label.modulate = Color(0.85, 0.45, 0.45, 0.90)
            else:
                _status_label.text = "[F6 / G] Emergency Deposit (25% Ore)"
                _status_label.modulate = Color(1.0, 0.72, 0.25, 0.90)

    var hotkey_down: bool = Input.is_physical_key_pressed(KEY_F6) or Input.is_physical_key_pressed(KEY_G)
    var just_pressed: bool = hotkey_down and not _prev_hotkey_down
    _prev_hotkey_down = hotkey_down

    if not in_mine or not just_pressed or _is_typing_in_ui():
        return

    if _cooldown_left > 0.0:
        _show_feedback("Beacon recharging (%.1fs)" % _cooldown_left, Color(0.95, 0.55, 0.35, 0.95))
        return

    _trigger_emergency_deposit()

func _is_typing_in_ui() -> bool:
    var vp := get_viewport()
    if not vp:
        return false
    var focus_owner := vp.gui_get_focus_owner()
    return (focus_owner is LineEdit) or (focus_owner is TextEdit)

func _show_feedback(msg: String, col: Color) -> void:
    _feedback_text = msg
    _feedback_color = col
    _feedback_left = FEEDBACK_SEC

func _find_active_stockpile() -> Node:
    var tree := get_tree()
    if not tree or not tree.current_scene:
        return null
    return tree.current_scene.find_child("*Stockpile*", true, false)

func _find_active_player() -> Node:
    var tree := get_tree()
    if not tree:
        return null
    var players := tree.get_nodes_in_group("player")
    if players.size() > 0 and is_instance_valid(players[0]):
        return players[0]
    if tree.current_scene:
        var p_node := tree.current_scene.find_child("Player", true, false)
        if is_instance_valid(p_node):
            return p_node
    return null

func _find_player_inventory() -> Inventory:
    var p := _find_active_player()
    if is_instance_valid(p) and ("inventory" in p) and p.inventory is Inventory:
        return p.inventory
    if Gvars and ("playerInventory" in Gvars) and Gvars.playerInventory is Inventory:
        return Gvars.playerInventory
    var path := "res://resources/Inventories/PlayerInventory.tres"
    if ResourceLoader.exists(path):
        var res = load(path)
        if res is Inventory:
            return res
    return null

func _find_stockpile_inventory() -> Inventory:
    if is_instance_valid(_cached_stockpile) and ("inventory" in _cached_stockpile) and _cached_stockpile.inventory is Inventory:
        return _cached_stockpile.inventory
    if Gvars and ("stockpileInventory" in Gvars) and Gvars.stockpileInventory is Inventory:
        return Gvars.stockpileInventory
    var path := "res://resources/Inventories/Stockpile.tres"
    if ResourceLoader.exists(path):
        var res = load(path)
        if res is Inventory:
            return res
    return null

func _trigger_emergency_deposit() -> void:
    var player_inv: Inventory = _find_player_inventory()
    var stock_inv: Inventory = _find_stockpile_inventory()
    if not player_inv or not ("items" in player_inv):
        ModLoaderLog.warning("Emergency Deposit: PlayerInventory not found.", MOD_DIR)
        _show_feedback("Emergency Deposit error: No PlayerInventory", Color(1.0, 0.35, 0.35, 0.95))
        return
    if not stock_inv or not stock_inv.has_method("addToInventory"):
        ModLoaderLog.warning("Emergency Deposit: Stockpile inventory not found.", MOD_DIR)
        _show_feedback("Emergency Deposit error: No Stockpile", Color(1.0, 0.35, 0.35, 0.95))
        return

    var transfers: Array = []
    for inv_item in player_inv.items:
        if not inv_item or not inv_item.item:
            continue
        if not (inv_item.item.itemType in STOCKPILABLE_TYPES):
            continue
        var count: float = float(inv_item.count)
        if count <= 0.0:
            continue
        transfers.append({
            "item": inv_item.item,
            "count": count
        })

    if transfers.is_empty():
        _show_feedback("Emergency Deposit: No ore in bag", Color(0.95, 0.85, 0.45, 0.95))
        ModLoaderLog.info("Emergency Deposit: Hotkey pressed with no stockpilable ore in bag.", MOD_DIR)
        return

    var total_surviving: float = 0.0
    var total_lost: float = 0.0
    var banked_entries: Array = []

    for entry in transfers:
        var ore_item: Item = entry["item"]
        var count: float = float(entry["count"])
        var survived: float = floor(count * SURVIVAL_RATE)

        var actually_added: float = 0.0
        if survived > 0.0:
            actually_added = float(stock_inv.addToInventory(ore_item, survived))
            if actually_added > 0.0:
                banked_entries.append({
                    "item": ore_item,
                    "count": int(actually_added)
                })

        if player_inv.has_method("removeFromInventory"):
            player_inv.removeFromInventory(ore_item, count)

        total_surviving += actually_added
        total_lost += (count - actually_added)

    _sync_coal_count(stock_inv)
    _spawn_stockpile_fx(banked_entries)
    _cooldown_left = COOLDOWN_SEC

    var summary := "Emergency Deposit: %.0f banked, %.0f lost!" % [total_surviving, total_lost]
    _show_feedback(summary, Color(0.45, 1.0, 0.55, 0.95))
    ModLoaderLog.info(summary, MOD_DIR)

func _sync_coal_count(stock_inv: Inventory) -> void:
    if not Gvars or not ("coalCount" in Gvars):
        return
    var coal_total: float = 0.0
    for slot in stock_inv.items:
        if slot and slot.item and slot.item.itemID == "Coal":
            coal_total += float(slot.count)
    Gvars.coalCount = coal_total

func _spawn_stockpile_fx(banked_entries: Array) -> void:
    if banked_entries.is_empty():
        return
    var stockpile := _cached_stockpile
    if not is_instance_valid(stockpile) or not stockpile.has_method("sendItemToInventory"):
        return
    if ("player" in stockpile) and not is_instance_valid(stockpile.player):
        var p := _find_active_player()
        if is_instance_valid(p):
            stockpile.player = p
    if not ("player" in stockpile) or not is_instance_valid(stockpile.player):
        return
    var tween := stockpile.create_tween()
    for entry in banked_entries:
        stockpile.call("sendItemToInventory", entry["item"], int(entry["count"]), tween)
