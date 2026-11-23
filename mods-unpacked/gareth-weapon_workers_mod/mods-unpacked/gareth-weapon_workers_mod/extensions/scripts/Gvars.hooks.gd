extends Object

func save_Gvars(chain: ModLoaderHookChain) -> Dictionary:
    var result: Dictionary = chain.execute_next([])
    var reg := _get_registry()
    if reg and reg.has_method("export_save"):
        result["gareth_weapon_workers"] = reg.call("export_save")
    return result

func load_Gvars(chain: ModLoaderHookChain, save: Dictionary) -> void:
    chain.execute_next([save])
    var reg := _get_registry()
    if not reg:
        return
    if save.has("gareth_weapon_workers") and reg.has_method("import_save"):
        reg.call("import_save", save["gareth_weapon_workers"])
    elif reg.has_method("reset_counts"):
        reg.call("reset_counts")

func reset_resources(chain: ModLoaderHookChain) -> void:
    chain.execute_next([])
    var reg := _get_registry()
    if reg and reg.has_method("reset_counts"):
        reg.call("reset_counts")

func _get_registry() -> Node:
    var ml := Engine.get_main_loop()
    if ml is SceneTree and ml.root:
        return ml.root.get_node_or_null("WeaponWorkerRegistry")
    return null
