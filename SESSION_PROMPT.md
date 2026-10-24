# Coal LLC Modding Architecture & Session Knowledge Base (Updated October 2026)

## 1. Directory Structure & Environment Paths
- Local Git Repository: C:\Dev\coal-llc-mods
- Remote Repository: https://github.com/garethwhite-prog/coal-llc-mods
- Active Unpacked Mods: C:\Dev\coal-llc-mods\mods-unpacked\<namespace>-<mod_name>
- Steam Game Root: C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC
- Steam Active Mods (.zip): C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods
- Hook Preprocessor Zip: C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mod-hooks.zip
- User Data & Logs: %APPDATA%\Godot\app_userdata\Coal LLC (godot.log, modloader.log, gareth_mods_config.json)

## 2. Packaging & Git Directives
1. Dual-Manifest & Dual-README Requirement:
   Every mod archive MUST contain manifest.json and README.md at the archive root AND duplicate copies inside mods-unpacked/<namespace>-<mod_name>/.
   manifest.json strictly requires: 'name', 'namespace', 'version_number', 'description', 'website_url', 'dependencies', and 'extra': { 'godot': { ... } }. Omitting website_url triggers a fatal ModManifest validation rejection.
   Every mod archive MUST contain manifest.json and README.md at the archive root AND duplicate copies inside mods-unpacked/<namespace>-<mod_name>/.
2. Forward Slash Zip Rule:
   Godot's virtual filesystem requires all zip entry paths to use forward slashes (/). Windows Compress-Archive uses backslashes (\), causing files to fail loading silently. Always use System.IO.Compression.ZipArchive with .Replace("\", "/").
3. Repo Hierarchy:
   Keep source files structured as:
   mods-unpacked/<mod_name>/mods-unpacked/<mod_name>/...
   This allows packaging the outer mod folder directly so root and relative paths align cleanly.
4. Git Staging:
   Never leave generated textures or scripts unstaged. Always run `git add -A` after build steps so TortoiseGit, Git Extensions, and CLI commits include all new assets.
5. In-Place Updates:
   Never delete top-level mod directories recursively if doing so destroys git-tracked documentation READMEs. Update scripts and textures in-place.

## 3. Godot 4 & ModLoader Engine Quirks
1. Runtime Loose PNG Loading:
   In exported Godot 4 builds, loose .png files placed in mod directories are not imported as .ctex resources. Calling ResourceLoader.load() or load() on loose images returns null. Always use runtime image decoding:
     var img = Image.load_from_file(path)
     if img:
         item.itemTexture = ImageTexture.create_from_image(img)
2. AtlasTexture Overrides:
   Pre-existing .tres item resources with baked AtlasTextures (such as Tactical Nukes and Neutron Bombs) will continue displaying default yellow sprites unless item.itemTexture is explicitly overwritten with an ImageTexture at runtime.
3. Coordinate Transforms (Godot 4.3+):
   TileMapManager extends TileMapLayer. Coordinate inspection methods (e.g. get_cell_atlas_coords, is_tile_breakable) take 1 argument (Vector2i), NOT 2. When raycasting from world coordinates, always transform to map space using:
     var local_pos: Vector2 = tilemap.to_local(world_pos)
     var cell: Vector2i = tilemap.local_to_map(local_pos)
4. Visual Tile Damage vs Silent Damage:
   `tilemap.damageTileCoords(cell, dmg)` applies damage silently to internal block health data without audio, cracks, or debris. For full feedback (breaking sounds, fracture overlays, particle bursts), use:
     tilemap.damageTile(world_pos, dmg)
5. ModLoader Hook Rules:
   - Hook scripts (*.hooks.gd) MUST begin with `extends Object` on line 1. Omitting this triggers a fatal assertion ("Scripts holding mod hooks should always extend Object").
   - Access the hooked vanilla instance via `chain.reference_object` (NEVER `chain.reference`, which calls RefCounted.reference() and evaluates to a Callable).
   - Hook scripts must ONLY contain method names that exist directly on the vanilla target script. Any custom helper functions defined at script root will trigger parse errors. Delegate custom logic to RefCounted helper classes.
   - Register hook scripts via `ModLoaderMod.install_script_hooks(vanilla_script_path: String, hook_script_path: String)`. Both arguments are strictly required.
   - When adding a hook for a vanilla script not previously hooked, delete `mod-hooks.zip` from the Steam game directory to force ModHookPacker to re-instrument the target script on startup.## 4. Economy, Cash & Save State
1. Cash Variable:
   Vanilla Coal LLC stores cash in `Gvars.CashCount` (float), NOT `Gvars.cash`.
2. UI Label Binding:
   The management screen binds cash to `%CurrentCash` (RichTextLabel) via `refresh_cash()`.
3. Reset Overwrites:
   `Gvars.reset_resources()` resets CashCount to 0 when starting Day 1. To enforce debt balances (such as - $50,000,000 for Debt Executioner), hook `_ready` and `refresh_cash` on `management_screen.gd`.

## 5. Custom Archetype Registry (IDs 101-109)
- 101: Knight (gareth-knight_class_mod) - Broadsword cleave progression.
- 102: Jedi (gareth-jedi_class_mod) - 7-ray forward arc plasma energy sabers.
- 103: Bouncing Ball (gareth-bouncing_ball_mod) - 16x16 ricocheting kinetic spheres with shockwave detonation.
- 104: Rainbow Sinclairity (gareth-sinclairity_class_mod) - Continuous refracting spectral prism melt laser.
- 105: Void Siphon (gareth-void_siphon_mod) - Singularity core with gravitational implosions and ore vacuum.
- 106: Debt Executioner (gareth-debt_executioner_mod) - Rotary minigun starting at - $50M debt.
- 107: Chrono-Industrialist (gareth-chrono_industrialist_mod) - High-speed temporal strike harvester with 10th-hit Stasis Shockwave.
- 108: Gravitational Dreadnought (gareth-grav_dreadnought_mod) - Heavy orbital mass dreadnought cannon.
- 109: Tectonic Fracker (gareth-tectonic_fracker_mod) - Acoustic fracture pulse with BFS ore seam propagation.

## 6. Standard 15-Tier Mineral Progression
Archetype weapons and explosives scale across 15 standard mineral tiers:
1. 01_shoddy
2. 02_copper
3. 03_iron
4. 04_sapphire
5. 05_emerald
6. 06_silver
7. 07_amethyst
8. 08_gold
9. 09_ruby
10. 10_diamond
11. 11_pinkdiamond
12. 12_spinel
13. 13_uranium
14. 14_moonstone
15. 15_onyx

## 7. Universal Shop Gating & Card Display
1. Mod Manager Shop Purity:
   In `management_screen.hooks.gd`, `load_equipment_shop()` iterates all shop items and hides weapons belonging to other classes, ensuring each archetype only sees its dedicated 15 tiers alongside universal utility items (ladders, platforms, whistles, teleporters).
2. Non-Destructive Card Display:
   Cards on `profession_select.gd` must never be deleted with queue_free() during selection. They remain visible and scrollable via horizontal mouse-wheel navigation.

## 8. Diagnostic Workflow
- Use `.\Dump-Context.ps1` in PowerShell to automatically gather git status, latest commits, and the last 50 lines of `godot.log` directly into the Windows clipboard for immediate status sharing.

## 9. Custom Map Architecture & Mechanics (IDs 101+)
1. Level Registry & Resources:
   - Maps are defined as `GameLevel` resources (`res://resources/levels/scripts/game_level.gd`) exporting: `level_name`, `level` (int/enum), `mining_scene_path` ("res://scenes/Stages/MineRegion.tscn"), `level_image` (Texture2D), `level_description` (String), `level_difficulty` (GameLevel.Difficulty), and `unlock_description` (String).
   - The central registry is `Gvars.level_manager.all_levels` (Dictionary), holding `{ "level": GameLevel, "is_unlocked": bool }`.
   - Vanilla enum is `Gconsts.Level` (IDs 0-7). Custom maps use integer IDs starting at 101+.
2. Carousel UI Card Injection:
   - `level_select.gd` manages the map selection screen and reads `LEVEL_ORDER: Array`.
   - In `level_select.hooks.gd`, hook `_ready(chain)` and append custom level IDs to `LEVEL_ORDER` before calling `chain.execute_next()`. Vanilla will automatically instantiate `LEVEL_INFO` cards, wire `level_clicked`, format stats, and build gamepad/keyboard focus navigation without destructive `queue_free()` calls.
3. Subterranean Generation Pipeline (`tile_map_chunk.gd`):
   - `lvl_from_global_pos(pos: Vector2i) -> int`: Governs ore tier scaling (Tiers 0-14, -2 for sky). Hook to implement custom depth curves, sine wave fault lines, or localized cluster logic for custom level IDs.
   - `generate_chunk(noise: Noise)`: Populates rock tiles. Use chunk metadata `chunk.set_meta(...)` to store cell coordinates for custom hazards, gas pockets, or unexploded ordnance.
   - `generate_chests(locations: Array[Vector2i]) -> Array[Vector2i]`: Intercept after `chain.execute_next()` to carve 3x3 vault chambers and spawn custom interactive Node2D/Area2D scenes via `chunk.add_child.call_deferred(entity)`.
   - `destroy_tile(idx: int, tile_properties: Dictionary)`: Hook to intercept block destruction. To trigger explosive detonations, resolve world positions and invoke `tilemap.damageTile(world_pos, dmg)` on the parent manager to ensure full cracking decals, breaking sounds, and particle bursts.
4. Active Workforce Rescue:
   - Employee types are stored in `Gvars.employee_manager.ALL_EMPLOYEES`.
   - Call `Gvars.employee_manager.purchase_employee_level(chosen_emp)` to grant active workforce levels directly during subterranean operations.
5. Custom Map Registry:
   - 101: Lost Expedition (`gareth-lost_expedition_mod`) - Subterranean demo ground featuring undulating mineral strata, unexploded ordnance (UXO) chain detonations, and survivor Cryo-Pod recovery vaults.







## 10. Tectonic Faultline (Map ID 102) & Elemental Systems Architecture

### Engine Contracts & Core Generation Rules
- Sky Stratum Code (-2): lvl_from_global_pos(pos) must return -2 whenever pos.y < 0 (tile grid coordinates). Returning 0 causes vanilla Coal LLC to classify the sky as Level 0 rock (HARD_ORANGE copper stone) and paint solid blocks across the clouds.
- Tile Coordinate Systems: Coordinates passed into lvl_from_global_pos(pos) are raw tile row indices (y < 0 for sky, y >= 0 for underground), not pixel values.
- Tile Cache & GPU Synchronization (build_tile): TileMapChunk does not update rendered blocks through standard Godot 4 set_cell() calls. Modifying rock layers or carving chambers requires setting chunk.tiles[c_idx] = target_tile followed immediately by chunk.build_tile(c_idx) to update the GPU render mesh and block metadata.
- Subterranean Vault Hooking (generate_chests): Multi-block chambers and pod vaults must be hooked in generate_chests(chain, current_block_chest_locations) rather than generate_chunk. This guarantees strata generation has completed and allows appending vault coordinates to current_block_chest_locations to prevent vanilla chests from spawning inside.
- ModLoader Virtual Zip Asset Loading: Texture files packaged inside .zip archives cannot be reliably loaded using ResourceLoader.load(). Custom card previews and entity sprites must be loaded as raw bytes via FileAccess.get_file_as_bytes() into an Image, then converted via ImageTexture.create_from_image(), or drawn procedurally onto an ImageTexture.

### Elemental Pods (MagmaSiphon.gd)
- Visual Color Modulation:
  - Magma (Fire): Modulated crimson red Color(1.4, 0.2, 0.2) with fiery ember particles and expanding blast rings.
  - Hydro Geyser (Water): Modulated electric azure Color(0.2, 0.55, 1.4) with blue spray droplets.
  - Toxic Acid (Poison): Modulated neon emerald Color(0.25, 1.3, 0.25) with corrosive drip cascades.
- Triple Spawn Density (3x): spawn_magma_siphons() attempts three non-overlapping vault placements per subterranean chunk using a 1-tile clearance check against current_block_chest_locations.
- Interaction Contracts:
  - [E] Vent: Geyser updraft velocity (y = -700 to -950), scaled cash bounty, multi-wave fluid cascade, and Bus.choose_passive trigger.
  - Left-Click Rupture: High-radius core explosion, wider fluid splatter, and massive damage to surrounding strata.

### Passive Chooser & Chest Loot Injection
- Vanilla Inventory Gating: In choose_passive.gd, c1 and c2 cards pull strictly from choice_options (built only from equipped weapon types in PlayerInventory.tres), while c3 is locked to mobility stats. When holding a pickaxe, elemental damage perks are excluded and never roll.
- Map 102 Injection: In gareth-mod_manager_mod/extensions/scenes/Interfaces/in_game/choose_passive.hooks.gd, when Gvars.level == 102, fire_damage, wet_damage, poison_damage, and elemental_tick_rate are injected directly into choice_options so bonus chests present elemental cards without requiring elemental weapons. Standard maps remain untouched.
- Built-in Vanilla Multipliers:
  - fire_damage (+5%): Directly scales burn DPS (tile_map_chunk.gd:2428).
  - poison_damage (+5%): Directly scales poison DPS (tile_map_chunk.gd:2378).
  - wet_damage (+1%): Multiplies all damage to saturated blocks by 2 * (1 + wet_damage) (tile_map_chunk.gd:2246).
- Elemental Tick Rate Acceleration: Vanilla tick intervals are fixed (POISON_TICK_LENGTH = 6, BURN_TICK_LENGTH = 7). In tile_map_chunk.hooks.gd, apply_tile_effects accumulates fractional bonuses from elemental_tick_rate to trigger extra calls to poisons_loop() and burns_loop(), accelerating damage-over-time block melting.

### nanobotz-autopassivechooser Integration
- Settings UI Discovery: passive_order.gd:get_possible_passives_for_professions() queries _profession_effect() per class. Non-elemental classes (like Internship) omit elemental perks from the UI list.
- UI Patch: Appending fire_damage, wet_damage, poison_damage, and elemental_tick_rate to get_possible_passives_for_professions() ensures they appear in Settings -> Passive Order with limit inputs and priority controls for all professions.
- In-Game Auto-Pick Contract: In choose_passive.hooks.gd, the auto-picker checks passive.get("enabled", false) and evaluates stat caps across both Gvars.passives and Gvars.custom_passives to prevent null-reference runtime exceptions.


### Map 103 - The Living Canvas (`gareth-living_canvas_mod`)
* **Level ID**: `103` (Registered in `level_manager.all_levels` and `Gvars.level_info`).
* **Stage Routing**: Hook `Game.gd:change_stage` on `target == 2` and `Gvars.level == 103` to load `res://scenes/Stages/MineRegion.tscn`.
* **Subterranean Generation Hook**: Hook `tile_map_chunk.gd:generate_chunk`. Maintain `pos.y < 0` returning `-2` (sky stratum) in `lvl_from_global_pos`.
* **Strata Mapping**: Map RGB pixels to valid breakable base blocks (`STRATA_BASES`) using Euclidean distance. Infuse 45% coal (`base + 1`), 25% ores (`base + 2..11`), and 30% base stone.
* **Layout Geometry**: Keep rows 0�12 as vanilla surface buffer; generate 8-block-wide breakable side quarries at `abs(x) >= 48` before terminating with outer bedrock walls at `abs(x) >= 56`.
* **Asset Loading**: Read image bytes via `FileAccess.get_file_as_bytes()` to bypass virtual zip boundaries; bundled default is `res://mods-unpacked/gareth-living_canvas_mod/assets/default_canvas.png`.

### Map 104 - The Abyssal Trench (`gareth-abyssal_trench_mod`)
* **Level ID**: `104` (Registered in `level_manager.all_levels` and `Gvars.level_info`).
* **Stage Routing**: Hook `Game.gd:change_stage` on `target == 2` and `Gvars.level == 104` to load `res://scenes/Stages/MineRegion.tscn`.
* **Subterranean Generation Hook**: Hook `tile_map_chunk.gd:generate_chunk`. Maintain `pos.y < 0` returning `-2` in `lvl_from_global_pos`.
* **Strata Mapping**:
  * Rows 0�12: Vanilla soft clay/coal starter buffer.
  * Rows 13�60 (Twilight Zone): `BASIC_DARKBLUE` (211), `COAL_DARKBLUE` (212), `SAPPHIRE_DARKBLUE` (215), `MOONSTONE_DARKBLUE` (225).
  * Rows 61+ (Hadal Trench): `BASIC_DARK` (92), `COAL_DARK` (93), `ONYX_DARK` (107), `DIAMOND_ICE` (68).
* **Entities**: `HydrothermalVent.gd` spawns in carved cavern floors; emits bubbling CPUParticles2D and launches miner upward (`velocity.y = -680.0`).
* **Tool Balancing**: Upper trench blocks ($13 \le y \le 40$) receive $2.8\times$ damage in `damage_tile_idx`.

## 4. Custom Profession Persistence & Serialization
- Gvars `save_Gvars()` hardcodes an iteration over `profession_manager.Professions.values()`, which only contains base game enum IDs (0 to 11).
- Custom classes with IDs >= 100 (e.g. Knight = 101, Jedi = 102) fail to serialize, falling back to Barbarian or leaving `Gvars.profession` null on reload.
- Always use a `save_Gvars` and `load_Gvars` post-hook in `gareth-mod_manager_mod` to map custom IDs directly against `Gvars.profession_manager.all_professions`.

## 5. Virtual Filesystem Image Loading in Godot 4 Zips
- Loose PNG textures packed inside `.zip` archives fail `ResourceLoader.load()` because Godot lacks pre-compiled `.png.import` files.
- `Image.load_from_file()` also fails inside virtual mounts (`res://`).
- Always decode PNGs via memory buffers:
```
var buffer = FileAccess.get_file_as_bytes(path)
var img = Image.new()
if img.load_png_from_buffer(buffer) == OK:
    return ImageTexture.create_from_image(img)
```

## 6. Equipment Shop Search, Sorter & Passive Panel
- Shop items are rendered in `%EquipmentShop` as instances of `ShopItemCard`.
- Filters and sorters must be injected into the `VBoxContainer` directly above the `ScrollContainer`.
- `PassiveBonuses.gd` only iterates `ChoosePassive.ALL_PASSIVES`. Worker and custom class weapon stats in `Gvars.passives` must be appended in a post-hook on `PassiveBonuses:refresh()`.

## 7. Subterranean Chest Variance & Loot Seeding
- `Chest.gd` rolls loot via `roll_loot()`.
- Modifying `chest.loot_level` before executing `chain.execute_next()` shifts the rolled stratum tier (+/- 1 or +/- 2).
- Custom class weapons and tanks can be seeded into `chest.loot` by overriding `chest.loot` when `chest.loot.itemType == "scroll"`.
