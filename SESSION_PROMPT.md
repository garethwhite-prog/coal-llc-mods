# Coal LLC Modding Ecosystem — Master Engineering Manual & Session State

## 1. Environment & Directory Topology (GROUND TRUTH)
* **Engine:** Godot Engine v4.4.1.stable.official (Vulkan 1.4 Forward+, Windows).
* **Game Version:** Coal LLC v1.4.1.1.
* **Mod Framework:** Godot ModLoader v7.0.1 (`ModLoaderMod`, `ModLoaderHookChain`, `ModLoaderLog`).
* **Repository Root:** `C:\Dev\coal-llc-mods`
* **Active Mod Source Code (`mods-unpacked`):**
  * ALL mod source files live inside `C:\Dev\coal-llc-mods\mods-unpacked\<mod_id>\`.
  * **Double-Nested Structure:** Every mod folder has an outer `manifest.json` at `mods-unpacked\<mod_id>\manifest.json` and an inner folder at `mods-unpacked\<mod_id>\mods-unpacked\<mod_id>\` containing `manifest.json`, `mod_main.gd`, `extensions\`, `scripts\`, `scenes\`, `helpers\`, and `assets\`.
  * **NEVER** search the repository root for `.gd` files; always search inside `mods-unpacked\`.
* **Vanilla Decompiled Game Dump (`_dump`):**
  * Located at `C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\_dump`.
  * Contains the decompiled vanilla `.gd` scripts, `.tscn` scenes, and `.tres` resources. Always inspect `_dump` before hooking any vanilla script.
* **Staging vs. Active Runtime Mod Directories:**
  * **Staging Library (`downloaded_mods`):** `C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\downloaded_mods` — holds unmounted `.zip` archives managed by the Mod & Map Store.
  * **Active Runtime (`mods`):** `C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods` — holds the `.zip` archives actively mounted by ModLoader at game boot.
  * **Hook Cache (`mod-hooks.zip`):** `C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mod-hooks.zip` — MUST be deleted whenever script hooks are added or changed so ModLoader regenerates hooks on launch.

---

## 2. Ways of Working: The `Run-Worker.ps1` Automation Contract (MANDATORY)

### Rule 1: Zero Manual File Edits
* Gareth NEVER manually edits `.gd`, `.json`, or `.tscn` files, and never copies loose GDScript snippets into files.
* Every single response that inspects or modifies the workspace MUST provide **one self-contained PowerShell script block**.
* Gareth pastes your PowerShell block into `ai_worker_script.ps1` and executes `.\Run-Worker.ps1`.
* `.\Run-Worker.ps1` runs your script and automatically captures all console output into `output.txt`, which Gareth uploads back to you.

### Rule 2: Discovery-First Protocol
* Before writing or modifying any mod code for a bug or feature, provide a **read-only Discovery PowerShell script** (zero file writes, zero repacks, zero git commits) to inspect the exact lines in `_dump` and `mods-unpacked`.
* Never guess node names, property names, dictionary structures, or method signatures.

### Rule 3: How Deployment & Gameplay Testing Work
* **NEVER** tell Gareth to manually run `.\Run-ModSuiteTest.ps1` as a standalone command after a script finishes.
* `tests_concise.txt`, `godot.log`, and `modloader.log` are generated when Gareth **plays the game**.
* Every Deployment PowerShell script MUST:
  1. Terminate running `Coal LLC*` and `godot*` processes so Windows file locks are released.
  2. Write updated source files into `mods-unpacked\<mod_id>\...` using `@' ... '@ | Set-Content -Encoding UTF8`.
  3. Delete `$steamRoot\mod-hooks.zip`.
  4. Package each modified mod into `$downMods\<mod_id>.zip` using `System.IO.Compression.ZipArchive` with **forward-slash (`/`) entry paths** (`$entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")`). **NEVER** use `[System.IO.Compression.ZipFile]::CreateFromDirectory()` because Windows backslashes (`\`) break Godot `res://` path resolution.
  5. Sync the repacked `.zip` into `$steamMods\<mod_id>.zip` if it is already installed (or if it is an active core mod) so changes actually take effect in-game!
  6. Stage, commit, and push to GitHub (`git add -A`, `git commit -m "..."`, `git push origin main`).
* At the end of every deployment response, explicitly tell Gareth **what to test in-game** during his next play session.

---

## 3. Hard Godot 4.4.1 & ModLoader 7.0.1 Engine Contracts

### A. Manifest V3 Schema Validation (CRITICAL)
Every `manifest.json` (both outer and inner) MUST contain `compatible_mod_loader_version` and `compatible_game_version` inside `extra.godot`:
~~~json
{
  "name": "example_mod",
  "namespace": "gareth",
  "version_number": "1.1.0",
  "description": "Mod description.",
  "website_url": "[https://github.com/garethwhite-prog/coal-llc-mods](https://github.com/garethwhite-prog/coal-llc-mods)",
  "dependencies": ["gareth-mod_manager_mod"],
  "extra": {
    "godot": {
      "authors": ["Gareth White"],
      "display_name": "Example Mod",
      "tags": ["qol"],
      "compatible_mod_loader_version": ["7.0.1"],
      "compatible_game_version": ["1.4.1.1"]
    }
  }
}
~~~
Omitting `compatible_mod_loader_version` causes ModLoader to reject the `.zip` at boot (`Manifest validation failed`) and cascade-disable every mod that lists it in `dependencies`.

### B. GDScript `Object.get()` vs. `Dictionary.get()`
* In Godot 4, `Dictionary.get(key, default)` accepts 2 arguments, and `Object.get_meta(name, default)` accepts 2 arguments.
* However, `Object.get(property)` accepts **strictly 1 argument**.
* Calling `Gvars.bonus_equipment_manager.get("vacuum_level", 1)` throws a fatal compile-time parse error:
  `Parse Error: Too many arguments for "get()" call. Expected at most 1 but received 2.`
* **Always use:**
~~~gdscript
var lvl: int = 1
if Gvars and ("bonus_equipment_manager" in Gvars) and Gvars.bonus_equipment_manager:
    if "vacuum_level" in Gvars.bonus_equipment_manager:
        lvl = int(Gvars.bonus_equipment_manager.vacuum_level)
~~~

### C. ModLoader Hook Targets Must Exist in Vanilla Script
* `ModLoaderMod.install_script_hooks(vanilla_script_path, hook_script_path)` only hooks functions that explicitly exist in the vanilla `.gd` file.
* Example: `res://scenes/equipment/vacuum_cleaner.gd` has `func _physics_process(_delta: float)` and `func _draw()`, but **does NOT have `func _ready()`**. Hooking `_ready` in `vacuum_cleaner.hooks.gd` is silently ignored by ModLoader! Always hook `_physics_process` and use a metadata guard (`vac.get_meta(...)`) for one-time initialization.
* Any extra helper function placed inside a `.hooks.gd` file will cause ModLoader to log `Skipped adding hook "_helper" (not found in vanilla script)`. Put helpers in separate classes/scripts when possible.

### D. Zipped Image & Audio Loading (`load_png_from_buffer`)
* Calling `load("res://mods-unpacked/.../image.png")` or `.wav` inside a zipped mod fails with `ERROR: No loader found for resource` because Godot 4 requires compiled `.import` files for `ResourceLoader.load()`.
* **Always load custom PNGs via raw byte buffer:**
~~~gdscript
var bytes = FileAccess.get_file_as_bytes("res://mods-unpacked/mod_id/assets/icon.png")
if bytes and bytes.size() > 0:
    var img = Image.new()
    if img.load_png_from_buffer(bytes) == OK:
        var tex = ImageTexture.create_from_image(img)
~~~

### E. Scene Tree Safety (`call_deferred` & Tween Guards)
* Adding nodes while a parent is initializing throws `ERROR: Parent node is busy setting up children, add_child() failed`. Use `call_deferred("add_child", node)` when injecting UI or entities during `_ready`.
* Calling `create_tween()` without adding at least one `tween_property` or `tween_callback` throws `ERROR: <Tween>: started with no Tweeners`. Only create a tween inside the `if is_instance_valid(target):` block.

---

## 4. Subsystem Architecture & Current Backlog (Immediate Tasks)

### 1. Custom Maps (101–105) & Level Select Carousel
* **Map Registry IDs:**
  * `101`: Lost Expedition (`gareth-lost_expedition_mod`)
  * `102`: Tectonic Faultline (`gareth-tectonic_faultline_mod`)
  * `103`: The Living Canvas (`gareth-living_canvas_mod` — default image: "Your Mum" beach mosaic)
  * `104`: The Abyssal Trench (`gareth-abyssal_trench_mod`)
  * `105`: Diagonal Seams (`gareth-diagonal_map_mod` — 45-degree rotated strata)
* **Registration Contract:**
  * `LevelManager` is NOT at `/root/LevelManager`; it lives at `Gvars.level_manager`.
  * Every custom map helper MUST register into `Gvars.level_manager.all_levels[ID]` BEFORE `level_select.gd:_ready()` iterates `LEVEL_ORDER`:
~~~gdscript
var lvl_mgr = Gvars.level_manager
if lvl_mgr and ("all_levels" in lvl_mgr) and not lvl_mgr.all_levels.has(MAP_ID):
    var custom_level = GameLevel.new()
    custom_level.level_name = "Map Name"
    custom_level.level = MAP_ID
    custom_level.mining_scene_path = "res://scenes/Stages/MineRegion.tscn"
    custom_level.level_description = "..."
    custom_level.level_image = preview_texture # MUST be level_image (Texture2D)
    lvl_mgr.all_levels[MAP_ID] = {
        "level": custom_level,
        "is_unlocked": true
    }
~~~
* **TWO OPEN BUGS TO FIX ON LEVEL SELECT:**
  1. **Diagonal Seams (105) Missing Icon:** `DiagonalMapHelper.gd` created `GameLevel.new()` without setting `custom_level.level_image`. Generate a crisp 45-degree diagonal strata `ImageTexture` (or load from buffer) and assign it to `custom_level.level_image`.
  2. **Living Canvas (103) Missing Browse Button:** In `_dump\scenes\Interfaces\Menus\level_info.tscn`, each card in `%Levels` is a `Button` (`LevelInfo`) with child `MarginContainer/VBoxContainer` containing `RichTextLabel` nodes (`%LevelTitle`, `%Description`, `%BestStats`), and stores its `GameLevel` resource in `card.game_level`. Our previous hook searched for `Label` instead of checking `card.game_level.level == 103`, so the button never attached! Attach `CanvasImagePickerBtn` into `card.get_node("MarginContainer/VBoxContainer")` when `card.game_level and card.game_level.level == 103`.

### 2. Bouncing Ball Mod (`gareth-bouncing_ball_mod`)
* **The Contract:** `bouncing_ball_equip.gd` instantiates `var proj := CharacterBody2D.new()`, attaches `bouncing_ball_projectile.gd`, and sets `proj.damage`, `proj.radius`, `proj.tilemap`, and `proj.ball_texture`.
* **OPEN BUG TO FIX (Too Much Velocity & Not Exploding):**
  * Because `bouncing_ball_equip.gd` creates a bare `CharacterBody2D.new()` in code rather than instantiating a `.tscn`, `bouncing_ball_projectile.gd` MUST create its own `CollisionShape2D` (`CircleShape2D.new()`, `shape.radius = 7.0`) and `_fuse_timer: float = 1.4` inside `_ready()` (as seen in original commit `a19e505b`)!
  * In our recent 3-tier damage patch, creating the `CollisionShape2D` and `_fuse_timer` was accidentally omitted, leaving the projectile with zero collision shape so `move_and_collide()` never triggered!
  * Restore `CollisionShape2D` creation in `_ready()`, restore `_fuse_timer = 1.4` countdown to `_explode()`, reduce throw velocity in `bouncing_ball_equip.gd` from `460.0` to a controlled arc (`300.0`), set `BOUNCE_DAMPING = 0.76`, and spawn visual explosion particles/shockwave on `_detonate_final()`.
  * Keep the 3-Tier Damage Stacking multipliers (Bounce count stack, Velocity impulse, and Global passives).

### 3. Henry the Hoover (`gareth-henry_the_hoover_mod`) & Teletubbies (`gareth-teletubbies_mod`)
* **Henry Artwork & Hose:** Upgrade `henry_texture_factory.gd` and `vacuum_cleaner.hooks.gd` so Henry looks like the real Numatic Henry 200 (glossy black domed bowler hat with white "Henry 200" badge, big white oval eyes, black nose port connected to the vacuum hose line, cheerful smile, and tier-dependent body color: Level 1 Red Henry, Level 2 Pink Hetty, Level 3 Blue Harry, Level 4 Green George, Level 5 Yellow Charles).
* **Rate-Limited Gobble:** When Henry sucks up ore or drops off coal, play a gobble audio/visual effect rate-limited to **at most once per 1.0 second** (`_gobble_timer = 1.0`) so late-game collection does not spam sound.
* **Teletubbies Overhaul:** Noo-Noo vacuum cleaner (tier-colored), laughing Baby Sun in the sky that descends and yawns when the shift timer approaches expiration, and workforce reskins turning miners/collectors into Tinky Winky, Dipsy, Laa-Laa, and Po.

### 4. Employee Miner & Collector 3rd Set of Upgrades (`gareth-employee_passives_mod`)
* Backend hooks in `employee_miner_2.hooks.gd`, `LootCollectorUFO.hooks.gd`, and `loot_drops.hooks.gd` read `employee_miner_range`, `employee_miner_pickup_speed`, and `collector_range`.
* **OPEN TASK:** Ensure these 3 stacking multipliers are properly registered into the in-game passive selection pool (`choose_passive.gd`) and/or between-day Bonus Shop (`management_screen.gd` / `passive_bonuses.gd`) so the player can see and pick them!

### 5. Player Clip / Reach Expansion Mod (`gareth-reach_expansion_mod`)
* Expands player ore pickup clip area, stockpile deposit distance (`Stockpile.gd`), and NPC quest interaction range (`QuestPoint` / Tabatha the Mermaid) by 1 tile (+24px).
* Must be wired into the Bonus Shop (`management_screen.gd`) as a rare, high-value, non-scaling upgrade.

### 6. Quadcopter Drone Workforce (`gareth-drone_workforce_mod`)
* Visual & thematic overhaul replacing walking employee miners and UFO collectors with hovering quadcopter drones.

### 7. Thomas the Tank Engine Class & Bottom Rail (`gareth-thomas_tank_engine_mod`)
* Playable class based on Sky Mine (`Gconsts.Level.SKY_MINE`) with a fixed cavern width bounded by left and right physical buffer stops at the bottom rail.
* Thomas runs back and forth along the bottom rail collecting dropped ore and returning it to the base stockpile.
* **3 Upgrade Tracks to Wire into Shop/UI:**
  1. **Locomotive Upgrades:** Thomas -> Edward -> Henry -> Charles -> Gordon (increasing power, speed, and pulling capacity).
  2. **Wagon Count:** Upgrading the number of coupled wagons.
  3. **Wagon Capacity:** Upgrading ore storage per wagon.

### 8. Universal Mod Manager, Mod Store (`gareth-mod_manager_mod`) & Multisave (`gareth-multisave_mod`)
* Main Menu features the custom hanging wooden sub-board (`✦ ENHANCED BY GARETH WHITE & GEMINI ✦`) and buttons (`Mod Manager`, `Mod & Map Store`, `Leaderboards`).
* Mod Store supports live search, Category filter, Status filter, repository switching (`Gareth White (Official Suite)` and `Der-Floh (Community Classics)`), and downloading/removing packages in `downloaded_mods/`.
* Save slot loading / new game start syncs required mods between `downloaded_mods/` and `mods/`.

### 9. Amazon Delivery (`gareth-scrap_and_delivery_mod`) & Game Speed (`gareth-game_speed_mod`)
* **Working & Verified:** Amazon (`[B]`) drops parachute crates at `z_index = 60` and zeroes `itemBuyPrice` during delivery callbacks so stack-size and slot upgrades expand `PlayerInventory.tres` directly without double-charging or cluttering hotbar slots.
* **Working & Verified:** Game Speed micro-dock (`◀ 1.00x ▶` + `⏰ End Day` `[F8]`) is docked cleanly at the bottom-right during active mining shifts.
