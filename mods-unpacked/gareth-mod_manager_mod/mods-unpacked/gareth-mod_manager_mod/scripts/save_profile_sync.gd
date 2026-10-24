class_name SaveProfileSync
extends RefCounted

static func sync_slot_mods_to_runtime(slot_id: int) -> void:
	var exe_dir := OS.get_executable_path().get_base_dir()
	var repo_dir := exe_dir.path_join("mods_repository")
	var active_dir := exe_dir.path_join("mods")

	var slot_config_path := "user://slot_%d_active_mods.json" % slot_id
	if not FileAccess.file_exists(slot_config_path):
		return

	var f := FileAccess.open(slot_config_path, FileAccess.READ)
	if not f:
		return
	var active_map = JSON.parse_string(f.get_as_text())
	if not (active_map is Dictionary):
		return

	# Copy enabled zips from master mods_repository into active mods/
	var dir := DirAccess.open(repo_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".zip"):
				var mod_key = file_name.replace(".zip", "")
				var is_active = bool(active_map.get(mod_key, true))
				var src = repo_dir.path_join(file_name)
				var dst = active_dir.path_join(file_name)
				if is_active:
					dir.copy(src, dst)
				else:
					if FileAccess.file_exists(dst):
						DirAccess.remove_absolute(dst)
			file_name = dir.get_next()
