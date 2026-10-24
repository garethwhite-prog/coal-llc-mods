# Coal LLC Modding Discovery Archive & Technical Dossier

This archive preserves all empirical findings, AST discoveries, engine hooks, and memory layout investigations.

## Discovery Phase Index
- **Phase 01–15**: ModLoader 7.x lifecycle, manifest schemas, custom class registration.
- **Phase 16–25**: Subterranean strata, tilemap elemental loops (fire, water, poison).
- **Phase 26–30**: ModHookPacker compilation, script extensions vs hook chains.
- **Phase 31–35**: Viewport tracking, native end-of-day sequence, employee miner/collector routines.
- **Phase 36–40**: Elemental airstrike flight paths, inventory slot data structures, loot drop valuation.
- **Phase 41–43**: Division-by-zero 0g shop card bug, pre-run UI category decoupling, turret targeting.

## Key Engine Conventions
1. **Database / Stored Procedure Philosophy**: Zero inline mutations on core registries; use ModLoader Hook Chains exclusively.
2. **Tilemap Status**:
   - Wetness: \	ilemap.wet_tile_coords(cell)\ and \	ilemap.wetness.add_wet_tile(cell)\
   - Combustion: \	ilemap.burn_tile(pos, dmg, ticks)\ and \	ilemap.fires.add_fire_tile(cell, dmg, ticks)\
   - Poison: \	ilemap.poison_tile_coords(cell, dmg, ticks)\ and \	ilemap.poisons.add_poison_tile(cell, dmg, ticks)\
3. **Player Node Discovery**: Target \	ree.root.find_child("Player", true, false)\ rather than group lookups.
