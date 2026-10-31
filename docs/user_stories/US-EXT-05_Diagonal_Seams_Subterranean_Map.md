# US-EXT-05: Diagonal Seams 45-Degree Strata Map
**Status:** In Progress
**Mod:** gareth-diagonal_map_mod

**Description:**
As a player, I want to play a subterranean map tilted at a 45-degree angle requiring specialized diagonal tunneling and shaft navigation.

**Acceptance Criteria:**
- Registered under map ID 105 in `Gvars.level_manager.all_levels` prior to `level_select.gd:_ready()`.
- Generates procedural 45-degree diagonal rock bands and ore distribution in `tile_map_chunk.hooks.gd`.
- Provides a custom diagonal preview texture assigned to `custom_level.level_image`.
- Intercepts `Game.change_stage` to ensure smooth stage transitions into `MineRegion.tscn`.
