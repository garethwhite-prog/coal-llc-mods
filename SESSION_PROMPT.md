# Coal LLC Modding Architecture & Session Knowledge Base (Updated October 2026)

## 1. Directory Structure & Environment Paths
- Local Git Repository: `C:\Dev\coal-llc-mods`
- Remote Repository: `https://github.com/garethwhite-prog/coal-llc-mods`
- Active Unpacked Mods: `C:\Dev\coal-llc-mods\mods-unpacked\<namespace>-<mod_name>`
- Steam Game Root: `C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC`
- Steam Active Mods (.zip): `C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods`
- Hook Preprocessor Zip: `C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mod-hooks.zip`
- User Data & Logs: `%APPDATA%\Godot\app_userdata\Coal LLC` (`godot.log`, `modloader.log`, `gareth_mods_config.json`, `profile_mods_slot_*.json`)

## 2. Packaging & Git Directives
1. **Dual-Manifest & Dual-README Requirement:**
   Every mod archive MUST contain `manifest.json` and `README.md` at the archive root AND duplicate copies inside `mods-unpacked/<namespace>-<mod_name>/`.
   `manifest.json` strictly requires: `name`, `namespace`, `version_number`, `description`, `website_url`, `dependencies`, and `extra: { godot: { ... } }`.
2. **Forward Slash Zip Rule:**
   Godot's virtual filesystem requires all zip entry paths to use forward slashes (`/`). Windows `Compress-Archive` uses backslashes (`\`), causing silent resource load failures. Always use `System.IO.Compression.ZipArchive` with entry paths normalized via `.Replace("\", "/")`.
3. **Targeted Deployment Only:**
   Only repack archives that have received code or asset updates. Never touch or rebuild unrelated mod packages.
4. **Test Runner Timing:**
   Never run `Run-ModSuiteTest.ps1` at the end of deployment scripts. The test auditor must only run after the developer has launched the game and played a live session to produce fresh telemetry.

## 3. Core Engine Contracts & Invariants
1. **The Sky Code Contract ($Y \le 0$):**
   `lvl_from_global_pos(pos)` must return `-2` whenever `pos.y <= 0`. Returning `>= 0` generates solid subterranean rock throughout the surface, crushing the player on frame 1.
2. **Native Tile Damage Protocol:**
   `tilemap.damageTileCoords(coords: Vector2i, damage: float)` is the sole engine method for damaging strata. Argument 2 must always be cast to `float`.
3. **InputMap Action Integrity:**
   The game registers `useItem`, `rightMouseClick`, and `toggle_use_item`. It does NOT register `"fire"`. Querying `Input.is_action_pressed("fire")` throws an engine error on every physics frame.
4. **Unloaded Chunk Dictionary Guard:**
   `TileMapManager.chunks_created` must be guarded with `.has(chunk_id)` before indexing. Querying coordinates outside active chunks throws fatal dictionary key exceptions.
5. **Chest Loot Null Dereference:**
   When a chest detonates as a booby trap, `chest.loot` is cleared to `null`. Hooks must verify `chest.loot != null` before delegating to vanilla `pickup_item()`.
6. **Ordnance Callback Isolation:**
   Falling ordnance must be instantiated as independent entities (`AirstrikeBomb`) rather than child nodes of moving planes. Freeing the parent plane while tween callbacks are queued causes `Instance is null` errors.
7. **Player Stun Implementation:**
   Freezing the character requires setting `velocity = Vector2.ZERO`, setting `able_to_mine = false`, and pausing the child `$StateMachine` via `set_physics_process(false)`.

## 4. UI Architecture & In-Game Navigation
1. **Main Menu Extensions:**
   `%MainMenuButtons` in `MainMenu.hooks.gd` hosts:
   - Index 1: `SaveProfilesButton` (Career multisave modal)
   - Index 2: `ModManagerButton` (Universal mod manager)
   - Index 3: `ModStoreButton` (Mod & Map Store browser)
   - Index 4: `LeaderboardsButton` (Community records)
2. **Bottom-Right In-Mine Micro-Dock:**
   Widgets are docked in a 150px-wide column with uniform 4px vertical separation:
   - Speed Controls (`◀ 1.00x ▶`): `-42.0` to `-16.0`
   - Amazon Emergency Delivery (`📦 Amazon (B)`): `-72.0` to `-46.0`
   - Air Wings (`🔥 7 | 💧 8 | ☣️ 9 | 💣 0`): `-102.0` to `-76.0`
   All three widgets dynamically query `_is_actively_mining()`, hiding completely during menus, customize screens, and between-day management.
3. **Shop Search & Filters:**
   Injected into the `VBoxContainer` directly above the `ScrollContainer` in both `%EquipmentShop` and `%BonusShop`.
