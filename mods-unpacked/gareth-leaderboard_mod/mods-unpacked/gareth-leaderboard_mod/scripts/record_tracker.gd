extends Node

const SAVE_PATH := "user://leaderboard_records.json"

var records: Dictionary = {}
var _poll_timer: float = 0.0

func _ready() -> void:
	load_records()

func _process(delta: float) -> void:
	_poll_timer += delta
	if _poll_timer >= 1.0:
		_poll_timer = 0.0
		sample_stats()

func sample_stats() -> void:
	if Gvars and ("passives" in Gvars) and Gvars.passives:
		var p = Gvars.passives
		for prop in p.get_property_list():
			var n: String = prop.name
			if n != "script" and not n.begins_with("resource_") and not n.begins_with("metadata/"):
				if n in p:
					var val = p.get(n)
					if (val is float or val is int) and val != null:
						_update_val(n, float(val))

	if Gvars and ("bonus_equipment_manager" in Gvars) and Gvars.bonus_equipment_manager:
		var bem = Gvars.bonus_equipment_manager
		if "current_vacuum" in bem and bem.current_vacuum != null:
			_update_val("vacuum_level", float(bem.current_vacuum))

	if Gvars and ("cash" in Gvars) and Gvars.cash != null:
		_update_val("highest_cash", float(Gvars.cash))

	if Gvars and ("quota" in Gvars) and Gvars.quota != null:
		_update_val("highest_quota", float(Gvars.quota))

	save_records()

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