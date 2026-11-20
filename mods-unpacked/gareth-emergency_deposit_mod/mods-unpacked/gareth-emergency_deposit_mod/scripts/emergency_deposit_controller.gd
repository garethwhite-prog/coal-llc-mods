extends Node

const MOD_DIR := "gareth-emergency_deposit_mod"
const SURVIVAL_RATE: float = 0.25
const COOLDOWN_SEC: float = 8.0
const STOCKPILABLE_TYPES: Array[String] = ["coal", "gem", "mineral"]
const ACTION_NAME := "wcm_emergency_deposit"

var _cooldown_left: float = 0.0
var _status_label: Label = null

func _ready() -> void:
process_mode = Node.PROCESS_MODE_ALWAYS
_register_input_actions()
_ensure_hud_hint()
ModLoaderLog.info("Emergency Deposit controller ready (F6 or G to bank 25% ore).", MOD_DIR)

func _register_input_actions() -> void:
if not InputMap.has_action(ACTION_NAME):
InputMap.add_action(ACTION_NAME)
var f6_ev := InputEventKey.new()
f6_ev.keycode = KEY_F6
f6_ev.physical_keycode = KEY_F6
if not InputMap.action_has_event(ACTION_NAME, f6_ev):
InputMap.action_add_event(ACTION_NAME, f6_ev)

var g_ev := InputEventKey.new()
g_ev.keycode = KEY_G
g_ev.physical_keycode = KEY_G
if not InputMap.action_has_event(ACTION_NAME, g_ev):
InputMap.action_add_event(ACTION_NAME, g_ev)

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
layer.add_child(_status_label)

func _process(delta: float) -> void:
if _cooldown_left > 0.0:
_cooldown_left = maxf(0.0, _cooldown_left - delta)

if _status_label and is_instance_valid(_status_label):
if _cooldown_left > 0.0:
_status_label.text = "[F6 / G] Beacon Recharging: %.1fs" % _cooldown_left
_status_label.modulate = Color(0.75, 0.45, 0.45, 0.90)
else:
_status_label.text = "[F6 / G] Emergency Deposit (25% Ore)"
_status_label.modulate = Color(1.0, 0.72, 0.25, 0.90)

if _cooldown_left <= 0.0 and Input.is_action_just_pressed(ACTION_NAME):
_trigger_emergency_deposit()

func _trigger_emergency_deposit() -> void:
var player_inv: Inventory = _find_player_inventory()
var stock_inv: Inventory = _find_stockpile_inventory()

if not player_inv or not ("items" in player_inv):
ModLoaderLog.warning("Emergency Deposit: PlayerInventory not found.", MOD_DIR)
return
if not stock_inv or not stock_inv.has_method("addToInventory"):
ModLoaderLog.warning("Emergency Deposit: Stockpile inventory not found.", MOD_DIR)
return

var total_surviving: float = 0.0
var total_lost: float = 0.0
var banked_entries: Array = []

for inv_item in player_inv.items:
if not inv_item or not inv_item.item:
continue
if not (inv_item.item.itemType in STOCKPILABLE_TYPES):
continue
var count: float = float(inv_item.count)
if count <= 0.0:
continue

var survived: float = floor(count * SURVIVAL_RATE)
var lost: float = count - survived
total_surviving += survived
total_lost += lost

if player_inv.has_method("removeFromInventory"):
player_inv.removeFromInventory(inv_item.item, count)
else:
inv_item.count = 0.0

if survived > 0.0:
stock_inv.addToInventory(inv_item.item, survived)
banked_entries.append({"item": inv_item.item, "count": int(survived)})

if total_surviving <= 0.0 and total_lost <= 0.0:
ModLoaderLog.info("Emergency Deposit: Pressed hotkey, but no stockpilable ore in inventory.", MOD_DIR)
return

_sync_coal_count(stock_inv)
_spawn_stockpile_fx(banked_entries)
_cooldown_left = COOLDOWN_SEC
ModLoaderLog.info(
"Emergency Deposit complete: Banked %.0f ore (25%% survived), %.0f ore lost in transit." % [total_surviving, total_lost],
MOD_DIR
)

func _find_player_inventory() -> Inventory:
if Gvars and ("playerInventory" in Gvars) and Gvars.playerInventory is Inventory:
return Gvars.playerInventory
var path := "res://resources/Inventories/PlayerInventory.tres"
if ResourceLoader.exists(path):
var res = load(path)
if res is Inventory:
return res
return null

func _find_stockpile_inventory() -> Inventory:
if Gvars and ("stockpileInventory" in Gvars) and Gvars.stockpileInventory is Inventory:
return Gvars.stockpileInventory
var path := "res://resources/Inventories/Stockpile.tres"
if ResourceLoader.exists(path):
var res = load(path)
if res is Inventory:
return res
return null

func _sync_coal_count(stock_inv: Inventory) -> void:
if not Gvars or not ("coalCount" in Gvars):
return
var coal_total: float = 0.0
for slot in stock_inv.items:
if slot and slot.item and slot.item.itemID == "Coal":
coal_total += float(slot.count)
Gvars.coalCount = coal_total

func _spawn_stockpile_fx(banked_entries: Array) -> void:
var tree := get_tree()
if not tree or not tree.root:
return
var stockpile := tree.root.find_child("*Stockpile*", true, false)
if not stockpile or not stockpile.has_method("sendItemToInventory"):
return
var tween := tree.create_tween()
for entry in banked_entries:
stockpile.call("sendItemToInventory", entry["item"], int(entry["count"]), tween)
