extends Object

const STATE_SCRIPT := "res://mods-unpacked/gareth-tank_arsenal_mod/tank_state.gd"

func start(chain: ModLoaderHookChain, player, item) -> void:
	chain.execute_next([player, item])
	var state = load(STATE_SCRIPT)
	var item_id = item.itemID if (item and "itemID" in item) else ""
	state.active_tank_id = item_id

	if player and "equipped_item_sprite" in player and player.equipped_item_sprite:
		player.equipped_item_sprite.modulate = state.get_color_for_id(item_id)

func end(chain: ModLoaderHookChain, player) -> void:
	var state = load(STATE_SCRIPT)
	state.active_tank_id = ""
	if player and "equipped_item_sprite" in player and player.equipped_item_sprite:
		player.equipped_item_sprite.modulate = Color.WHITE
	chain.execute_next([player])