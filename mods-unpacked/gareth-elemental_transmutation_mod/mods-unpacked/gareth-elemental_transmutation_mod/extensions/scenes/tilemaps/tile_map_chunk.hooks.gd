extends Object

const LOG_NAME := "gareth-elemental_transmutation_mod:Hook"


func destroy_tile(chain: ModLoaderHookChain, idx: int, tile_properties: Dictionary) -> void:
	var chunk := chain.reference_object as TileMapChunk
	var had_poison: bool = chunk.poison_tiles.has(idx)
	var had_burn: bool = chunk.burn_tiles.has(idx)

	chain.execute_next([idx, tile_properties])

	if not had_poison and not had_burn:
		return

	var origin := chunk.array_to_global_pos(idx)
	var world_pos := Vector2(origin.x * 16, origin.y * 16)

	if had_burn:
		ModLoaderLog.info("[Transmutation] Burned tile destroyed at %s! Crystallized: +$35" % str(origin), LOG_NAME)
		if Gvars:
			Gvars.money += 35
			Gvars.total_money_earned += 35
		Bus.BombExplode.emit(world_pos, 2.0, 30.0)

	if had_poison:
		ModLoaderLog.info("[Transmutation] Corroded tile destroyed at %s! Slag payout: +$15" % str(origin), LOG_NAME)
		if Gvars:
			Gvars.money += 15
			Gvars.total_money_earned += 15