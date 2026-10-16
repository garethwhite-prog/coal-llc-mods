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





