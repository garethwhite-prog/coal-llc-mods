# Parallel Discovery & Architectural Analysis

## 1. Workspace Topology & Staging Protocol
- **Repository Root:** `C:\Dev\coal-llc-mods`
- **Source Code Container:** All 64 mod projects reside inside `mods-unpacked\<mod_id>\mods-unpacked\<mod_id>\`. The outer directory contains package metadata; the inner directory houses runtime GDScript, scenes, resources, and assets.
- **Decompiled Game Baseline:** `C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\_dump` provides the authoritative vanilla AST and scene hierarchy.
- **Staging vs Runtime:**
  - `downloaded_mods/`: Storage repository for downloaded `.zip` packages managed by the Mod Store.
  - `mods/`: Active directory mounted by Godot ModLoader 7.x at boot.
  - Mod packaging scripts must always write to `downloaded_mods/` AND sync active mods into `mods/`, followed by deleting `mod-hooks.zip`.

## 2. Hook Registration Engine
- ModLoader 7.x hooks require strict target method existence.
- Vanilla hook chains pass parameters through `chain.execute_next([args])`.
- Custom classes and entities must avoid calling `Object.get(prop, default)` (1 argument max in Godot 4).
- Dynamic asset loading from zipped archives must bypass `ResourceLoader.load()` for raw PNG/WAV files and utilize `FileAccess.get_file_as_bytes()` with `Image.load_png_from_buffer()`.

## 3. Map Subsystem Discovery
- `LevelManager` is stored globally on `Gvars.level_manager`.
- The Level Select carousel builds cards by iterating `LEVEL_ORDER`.
- Every custom map must register as `{ "level": custom_level_resource, "is_unlocked": true }` inside `Gvars.level_manager.all_levels`.
- Card image textures must be assigned to `custom_level.level_image` (Texture2D).
- Map Card hierarchy in `level_info.tscn`: Root node is `Button` (`LevelInfo`), hosting `MarginContainer/VBoxContainer` with `%LevelTitle`, `%Description`, and `%BestStats`. Custom controls (such as Map 103's image browser) must dock inside this `VBoxContainer`.

## 4. Ordnance & Physics Subsystem Discovery
- `bouncing_ball_equip.gd` creates `CharacterBody2D.new()` in code.
- `bouncing_ball_projectile.gd` must construct its own `CollisionShape2D` (CircleShape2D, radius 7.0) and initialize `_fuse_timer = 1.4` in `_ready()` to allow physical collision resolution.
- Compounding damage integrates consecutive bounce counters, physics velocity impulse, and player pickaxe passives.

## 5. Economy & In-Shift Delivery Discovery
- Amazon delivery orders deduct wallet cash upon placement.
- Passive capacity upgrades (stack size, slot count) implement `itemBuyEffect`.
- Delivery callbacks must zero `itemBuyPrice` before calling `buy_effect(item, 1)` to prevent double-charge check failures, and must apply expansions directly to `PlayerInventory.tres` without dropping cards into active hotbars.

## 6. Current Open Work Items for Consolidation
1. **Map 105 (Diagonal Seams):** Generate and assign custom `level_image` texture in `DiagonalMapHelper.gd`.
2. **Map 103 (Living Canvas):** Re-dock the `📁 Browse Custom Image` button inside `MarginContainer/VBoxContainer` matching `card.game_level.level == 103`.
3. **Bouncing Ball:** Restore procedural `CollisionShape2D` and `_fuse_timer` in `_ready()`, tune throw velocity to 300px/s, and add visual explosion particles.
4. **Workforce Tier 3:** Register `employee_miner_range`, `employee_miner_pickup_speed`, and `collector_range` upgrades into the Bonus Shop.
5. **Henry Hoover:** Upgrade pixel art to match the Numatic Henry 200 reference photo and add the 1.0s rate-limited suction gobble sound effect.
