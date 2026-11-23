extends Object

const UNIT_SCRIPT_PATH := "res://mods-unpacked/gareth-weapon_workers_mod/scripts/weapon_worker_unit.gd"
const MAX_ACTIVE_WEAPON_ENTITIES: int = 36

func load_employees(chain: ModLoaderHookChain) -> void:
    chain.execute_next([])
    var spawner = chain.reference_object
    if not is_instance_valid(spawner):
        return

    var tree: SceneTree = spawner.get_tree()
    if not tree or not tree.root:
        return
    var reg: Node = tree.root.get_node_or_null("WeaponWorkerRegistry")
    if not reg or not reg.has_method("get_all_defs"):
        return

    var unit_script: GDScript = load(UNIT_SCRIPT_PATH)
    if not unit_script:
        return

    var defs: Dictionary = reg.call("get_all_defs")
    var hired_types: Array = []
    for worker_id in defs.keys():
        var cnt: int = int(reg.call("get_count", worker_id))
        if cnt > 0:
            hired_types.append({ "def": defs[worker_id], "count": cnt })

    if hired_types.is_empty():
        return

    var per_type_cap: int = maxi(1, int(floor(float(MAX_ACTIVE_WEAPON_ENTITIES) / float(hired_types.size()))))
    for entry in hired_types:
        var def: Dictionary = entry["def"]
        var total_cnt: int = int(entry["count"])
        var visual_entities: int = mini(total_cnt, per_type_cap)
        var stack_per_unit: int = maxi(1, int(ceil(float(total_cnt) / float(visual_entities))))

        for i in range(visual_entities):
            var unit := Node2D.new()
            unit.set_script(unit_script)
            unit.worker_def = def
            unit.stacked_count = stack_per_unit
            if "tile_map_manager" in spawner:
                unit.tilemap = spawner.tile_map_manager
            unit.global_position = spawner.global_position + Vector2(randf_range(-40.0, 40.0), 20.0)
            if "employee_instances" in spawner:
                spawner.employee_instances.append(unit)
            else:
                spawner.call_deferred("add_sibling", unit)
