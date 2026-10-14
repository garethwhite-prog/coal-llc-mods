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
2. Forward Slash Zip Rule:
   Godot's virtual filesystem requires all zip entry paths to use forward slashes (/). Windows Compress-Archive uses backslashes (\), causing files to fail loading silently. Always use System.IO.Compression.ZipArchive with .Replace("\", "/").
3. Repo Hierarchy:
   Keep source files structured as:
   mods-unpacked/<mod_name>/mods-unpacked/<mod_name>/...
   This allows packaging the outer mod folder directly so root and relative paths align cleanly.
4. Git Staging:
   Never leave generated textures or scripts unstaged. Always run `git add -A` after build steps so TortoiseGit and CLI commits include all new assets.
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
5. ModLoader Hook Limitations:
   Hook scripts (*.hooks.gd) must ONLY contain method names that exist directly on the vanilla target script. Any custom helper functions defined at script root will be skipped with warnings or trigger parse errors. Embed helper logic directly inside hooked methods.

## 4. Economy, Cash & Save State
1. Cash Variable:
   Vanilla Coal LLC stores cash in `Gvars.CashCount` (float), NOT `Gvars.cash`.
2. UI Label Binding:
   The management screen binds cash to `%CurrentCash` (RichTextLabel) via `refresh_cash()`.
3. Reset Overwrites:
   `Gvars.reset_resources()` resets CashCount to 0 when starting Day 1. To enforce debt balances (such as -$50,000,000 for Debt Executioner), hook `_ready` and `refresh_cash` on `management_screen.gd`.

## 5. Custom Archetype Registry (IDs 101-109)
- 101: Knight (gareth-knight_class_mod) - Broadsword cleave progression.
- 102: Jedi (gareth-jedi_class_mod) - 7-ray forward arc plasma energy sabers.
- 103: Bouncing Ball (gareth-bouncing_ball_mod) - 16x16 ricocheting kinetic spheres with shockwave detonation.
- 104: Rainbow Sinclairity (gareth-sinclairity_class_mod) - Continuous refracting spectral prism melt laser.
- 105: Void Siphon (gareth-void_siphon_mod) - Singularity core with gravitational implosions and ore vacuum.
- 106: Debt Executioner (gareth-debt_executioner_mod) - Rotary minigun starting at -$50M debt.
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