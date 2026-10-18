extends Object


func destroy_tile(chain: ModLoaderHookChain, idx: int, tile_properties: Dictionary):
    var chunk := chain.reference_object as TileMapChunk
    #var chunk = chain.reference_object
    var type := chunk.tiles[idx]
    # var type = chunk.tiles[idx]
    var is_hard_tile := type in [
        TileMapChunk.Tiles.HARD_CLAY,
        TileMapChunk.Tiles.HARD_STONE,
        TileMapChunk.Tiles.HARD_ICE,
        TileMapChunk.Tiles.HARD_FIRE,
        TileMapChunk.Tiles.HARD_DARK,
        TileMapChunk.Tiles.HARD_GREEN,
        TileMapChunk.Tiles.HARD_ORANGE,
        TileMapChunk.Tiles.HARD_PURPLE,
        TileMapChunk.Tiles.HARD_DARKGREEN,
        TileMapChunk.Tiles.HARD_YELLOW,
        TileMapChunk.Tiles.HARD_DARKBROWN,
        TileMapChunk.Tiles.HARD_DARKBLUE
    ]
    
    chain.execute_next([idx, tile_properties])
    
    if not is_hard_tile:
        return

    var tile_pos := chunk.array_to_pos(idx)
    for child in chunk.get_children():
        var chest := child as Chest
        if not chest or chest.looted:
            continue
        
        for x in range(-1, 2):
            for y in range(-1, 2):
                if x == 0 and y == 0:
                    continue

                var chest_pos := Vector2i(tile_pos.x + x, tile_pos.y + y)
                var chest_pos_local := chunk.map_to_local(chest_pos)
                if chest.position == chest_pos_local:
                    chest.auto_loot_chest()
                    chest.opened = true
                    chest.looted = true
                    Bus.ShowInputIndicator.emit("interact", false, chest)
