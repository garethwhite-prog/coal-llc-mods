extends Node

const SAVE_PATH := "user://leaderboard_records.json"

var records: Dictionary = {
	"pickaxe_speed": 0.0,
	"pickaxe_damage": 0.0,
	"player_sprint_speed": 0.0,
	"player_jump_velocity": 0.0,
	"vacuum_level": 0.0,
	"bomb_damage": 0.0,
	"bomb_radius": 0.0,
	"punch_speed": 0.0,
	"punch_damage": 0.0,
	"kick_speed": 0.0,
	"kick_damage": 0.0,
	"highest_cash": 0.0
}

func _ready() -> void:
	load_records()

func sample_stats() -> void:
	if Gvars and ("passives" in Gvars) and Gvars.passives:
		var p = Gvars.passives
		_update_val("pickaxe_speed", _get_val(p, "pickaxe_speed"))
		_update_val("pickaxe_damage", _get_val(p, "pickaxe_damage"))
		_update_val("player_sprint_speed", _get_val(p, "player_sprint_speed"))
		_update_val("player_jump_velocity", _get_val(p, "player_jump_velocity"))
		_update_val("bomb_damage", _get_val(p, "bomb_damage"))
		_update_val("bomb_radius", _get_val(p, "bomb_radius"))
		_update_val("punch_speed", _get_val(p, "punch_speed"))
		_update_val("punch_damage", _get_val(p, "punch_damage"))
		_update_val("kick_speed", _get_val(p, "kick_speed"))
		_update_val("kick_damage", _get_val(p, "kick_damage"))

	if Gvars and ("bonus_equipment_manager" in Gvars) and Gvars.bonus_equipment_manager:
		if "current_vacuum" in Gvars.bonus_equipment_manager:
			_update_val("vacuum_level", float(Gvars.bonus_equipment_manager.current_vacuum))

	if Gvars and ("cash" in Gvars) and Gvars.cash != null:
		_update_val("highest_cash", float(Gvars.cash))

	save_records()

func _get_val(obj: Object, prop: String) -> float:
	if obj and prop in obj:
		var v = obj.get(prop)
		if v != null:
			return float(v)
	return 0.0

func _update_val(key: String, current: float) -> void:
	if current > records.get(key, 0.0):
		records[key] = current

func load_records() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_text := file.get_as_text()
			var parsed = JSON.parse_string(json_text)
			if parsed is Dictionary:
				for k in parsed.keys():
					records[k] = float(parsed[k])

func save_records() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(records, "\t"))