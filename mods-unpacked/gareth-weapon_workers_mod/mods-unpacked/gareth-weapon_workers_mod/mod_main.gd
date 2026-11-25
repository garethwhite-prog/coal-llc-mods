extends Node

const MOD_DIR := "gareth-weapon_workers_mod"
const REG_SCRIPT_PATH := "res://mods-unpacked/gareth-weapon_workers_mod/scripts/weapon_worker_registry.gd"

func _init() -> void:
    var mod_dir_path: String = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
    ModLoaderMod.install_script_hooks(
        "res://scenes/Stages/management_screen.gd",
        mod_dir_path.path_join("extensions/scenes/Stages/management_screen.hooks.gd")
    )
    ModLoaderMod.install_script_hooks(
        "res://scripts/Gvars.gd",
        mod_dir_path.path_join("extensions/scripts/Gvars.hooks.gd")
    )
    ModLoaderMod.install_script_hooks(
        "res://scripts/employee_spawner.gd",
        mod_dir_path.path_join("extensions/scripts/employee_spawner.hooks.gd")
    )

func _ready() -> void:
    var tree: SceneTree = get_tree()
    if tree and tree.root and not tree.root.get_node_or_null("WeaponWorkerRegistry"):
        var reg_script: GDScript = load(REG_SCRIPT_PATH)
        if reg_script:
            var reg := Node.new()
            reg.name = "WeaponWorkerRegistry"
            reg.set_script(reg_script)
            tree.root.call_deferred("add_child", reg)
    ModLoaderLog.info("Weapon Workers Mod v1.2.0 initialized (14 Monopoly Colour Sets + Chain Calculator).", MOD_DIR)
