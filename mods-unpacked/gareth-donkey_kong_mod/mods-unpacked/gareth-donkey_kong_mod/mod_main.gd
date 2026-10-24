extends Node
const MOD_DIR := "gareth-donkey_kong_mod"
func _ready() -> void:
	var spawner_scr = load("res://mods-unpacked/gareth-donkey_kong_mod/scripts/gorilla_surface_spawner.gd")
	var spawner = Node.new()
	spawner.name = "GorillaSurfaceSpawner"
	spawner.set_script(spawner_scr)
	get_tree().root.call_deferred("add_child", spawner)
	ModLoaderLog.info("Donkey Kong Surface Hazard Mod online!", MOD_DIR)
