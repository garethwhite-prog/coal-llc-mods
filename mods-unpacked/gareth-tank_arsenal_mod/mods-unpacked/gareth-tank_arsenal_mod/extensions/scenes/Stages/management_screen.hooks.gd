extends Object

const STATE_SCRIPT := "res://mods-unpacked/gareth-tank_arsenal_mod/tank_state.gd"

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	var state = load(STATE_SCRIPT)
	state.ensure_catalog_registered()
	chain.execute_next([])