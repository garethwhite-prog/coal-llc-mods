extends Object

const FAULTLINE_LEVEL_ID: int = 102

func _ready(chain: ModLoaderHookChain) -> void:
	var helper_script = load("res://mods-unpacked/gareth-tectonic_faultline_mod/helpers/TectonicFaultlineHelper.gd")
	if helper_script:
		var helper = helper_script.new()
		if helper.has_method("ensure_level_registered"):
			helper.ensure_level_registered()
	
	var ls = chain.reference_object
	if ls:
		# 1. Register entry 102 into all_levels dictionary so line 56 never crashes
		if "all_levels" in ls and ls.all_levels is Dictionary:
			if not ls.all_levels.has(FAULTLINE_LEVEL_ID):
				var sample_level = null
				for k in ls.all_levels.keys():
					if ls.all_levels[k] is Dictionary and ls.all_levels[k].has("level"):
						if ls.all_levels[k]["level"] != null:
							sample_level = ls.all_levels[k]["level"]
							break
				
				var new_lvl = sample_level.duplicate() if sample_level else null
				if new_lvl:
					if "level_name" in new_lvl:
						new_lvl.level_name = "Tectonic Faultline"
					if "level_description" in new_lvl:
						new_lvl.level_description = "Seismic faultline with superheated vents, magma fissures, and elemental chambers.\n\nElemental pods contain explosive fluids and geothermal updrafts."
					if "depth" in new_lvl:
						new_lvl.depth = 1400
					var preview_path = "res://mods-unpacked/gareth-tectonic_faultline_mod/assets/magma_siphon_active.png"
					if ResourceLoader.exists(preview_path) and ("level_image" in new_lvl):
						new_lvl.level_image = load(preview_path)
				
				ls.all_levels[FAULTLINE_LEVEL_ID] = {
					"level": new_lvl,
					"is_unlocked": true
				}
		
		# 2. Append 102 to LEVEL_ORDER sequence
		if "LEVEL_ORDER" in ls and ls.LEVEL_ORDER is Array:
			if not ls.LEVEL_ORDER.has(FAULTLINE_LEVEL_ID):
				ls.LEVEL_ORDER.append(FAULTLINE_LEVEL_ID)
	
	chain.execute_next([])
