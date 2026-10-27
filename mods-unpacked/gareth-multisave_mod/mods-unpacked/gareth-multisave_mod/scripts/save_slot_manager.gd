extends Node

const BASE_SAVES_DIR := "user://saves"
const VANILLA_SAVE_PATH := "user://v04_savegame.save"
const TOTAL_SLOTS := 6

var current_slot: int = 1
var _last_save_mtime: int = 0

func _ready() -> void:
	_ensure_directories()
	_migrate_vanilla_save_if_needed()
	restore_career_progression()

func _process(_delta: float) -> void:
	if FileAccess.file_exists(VANILLA_SAVE_PATH):
		var mtime := FileAccess.get_modified_time(VANILLA_SAVE_PATH)
		if mtime != _last_save_mtime:
			_last_save_mtime = mtime
			sync_active_slot_from_vanilla()

func _ensure_directories() -> void:
	if not DirAccess.dir_exists_absolute(BASE_SAVES_DIR):
		DirAccess.make_dir_recursive_absolute(BASE_SAVES_DIR)
	for i in range(1, TOTAL_SLOTS + 1):
		var slot_dir := "%s/slot_%d" % [BASE_SAVES_DIR, i]
		if not DirAccess.dir_exists_absolute(slot_dir):
			DirAccess.make_dir_recursive_absolute(slot_dir)

func _migrate_vanilla_save_if_needed() -> void:
	var slot_1_save := "%s/slot_1/v04_savegame.save" % BASE_SAVES_DIR
	if FileAccess.file_exists(VANILLA_SAVE_PATH) and not FileAccess.file_exists(slot_1_save):
		var src := FileAccess.open(VANILLA_SAVE_PATH, FileAccess.READ)
		if src:
			var content := src.get_as_text()
			src.close()
			var dst := FileAccess.open(slot_1_save, FileAccess.WRITE)
			if dst:
				dst.store_string(content)
				dst.close()
			_generate_slot_meta(1)

func restore_career_progression() -> void:
	if not Gvars:
		return
	if "profession_manager" in Gvars and Gvars.profession_manager:
		var pm = Gvars.profession_manager
		for p in pm.all_professions.keys():
			pm.all_professions[p]["is_unlocked"] = true
	if "level_manager" in Gvars and Gvars.level_manager:
		var lm = Gvars.level_manager
		for l in lm.all_levels.keys():
			lm.all_levels[l]["is_unlocked"] = true
	if Gvars.has_method("load_hard_modifier_records"):
		Gvars.load_hard_modifier_records()
	if Gvars.has_method("save_globals"):
		Gvars.save_globals()
	ModLoaderLog.info("Career progression and hard modifier badges verified.", "gareth-multisave_mod")

func get_slot_save_path(slot_id: int) -> String:
	return "%s/slot_%d/v04_savegame.save" % [BASE_SAVES_DIR, slot_id]

func get_slot_meta_path(slot_id: int) -> String:
	return "%s/slot_%d/meta.json" % [BASE_SAVES_DIR, slot_id]

func get_slot_config_path(slot_id: int) -> String:
	return "%s/slot_%d/run_config.json" % [BASE_SAVES_DIR, slot_id]

func has_save(slot_id: int) -> bool:
	return FileAccess.file_exists(get_slot_save_path(slot_id))

func get_slot_meta(slot_id: int) -> Dictionary:
	var path := get_slot_meta_path(slot_id)
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				return parsed
	return {}

func sync_active_slot_from_vanilla() -> void:
	if not FileAccess.file_exists(VANILLA_SAVE_PATH):
		return
	var src := FileAccess.open(VANILLA_SAVE_PATH, FileAccess.READ)
	if not src:
		return
	var content := src.get_as_text()
	src.close()

	var dst := FileAccess.open(get_slot_save_path(current_slot), FileAccess.WRITE)
	if dst:
		dst.store_string(content)
		dst.close()

	_generate_slot_meta(current_slot)

func prepare_vanilla_from_active_slot() -> void:
	var slot_path := get_slot_save_path(current_slot)
	if FileAccess.file_exists(slot_path):
		var src := FileAccess.open(slot_path, FileAccess.READ)
		if src:
			var content := src.get_as_text()
			src.close()
			var dst := FileAccess.open(VANILLA_SAVE_PATH, FileAccess.WRITE)
			if dst:
				dst.store_string(content)
				dst.close()

func delete_slot(slot_id: int) -> void:
	var s_path := get_slot_save_path(slot_id)
	var m_path := get_slot_meta_path(slot_id)
	var c_path := get_slot_config_path(slot_id)
	if FileAccess.file_exists(s_path):
		DirAccess.remove_absolute(s_path)
	if FileAccess.file_exists(m_path):
		DirAccess.remove_absolute(m_path)
	if FileAccess.file_exists(c_path):
		DirAccess.remove_absolute(c_path)
	if slot_id == current_slot and FileAccess.file_exists(VANILLA_SAVE_PATH):
		DirAccess.remove_absolute(VANILLA_SAVE_PATH)

func is_mod_active_for_run(mod_key: String) -> bool:
	var path := get_slot_config_path(current_slot)
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary and parsed.has("mods"):
				return bool(parsed["mods"].get(mod_key, true))
	return true

func _generate_slot_meta(slot_id: int) -> void:
	var prof_name := "Internship"
	if Gvars and ("profession" in Gvars) and Gvars.profession:
		if "profession_name" in Gvars.profession:
			prof_name = str(Gvars.profession.profession_name)

	var day_num: int = int(Gvars.dayCount) if (Gvars and "dayCount" in Gvars) else 1
	var cash_val: float = float(Gvars.CashCount) if (Gvars and "CashCount" in Gvars) else 0.0

	var meta_data := {
		"profession": prof_name,
		"day": day_num,
		"cash": cash_val,
		"timestamp": Time.get_datetime_string_from_system(false, true)
	}

	var file := FileAccess.open(get_slot_meta_path(slot_id), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(meta_data, "\t"))
		file.close()
func set_active_slot_mods(cfg: Dictionary) -> void:
	var slot_id = get_current_slot_id() if has_method("get_current_slot_id") else 1
	var slot_cfg_path = "user://profile_mods_slot_%d.json" % slot_id
	var f = FileAccess.open(slot_cfg_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(cfg, "\t"))
