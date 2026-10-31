$repoRoot = "C:\Dev\coal-llc-mods"
Set-Location -Path $repoRoot

Write-Output "--- 1. Generating Knowledge Base & Agile Tracker Directories ---"
$wikiDir = Join-Path $repoRoot "docs\wiki"
$storiesDir = Join-Path $repoRoot "docs\user_stories"
if (-not (Test-Path $wikiDir)) { New-Item -Path $wikiDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $storiesDir)) { New-Item -Path $storiesDir -ItemType Directory -Force | Out-Null }

Write-Output "--- 2. Updating SESSION_PROMPT.md ---"
$sessionPromptPath = Join-Path $repoRoot "SESSION_PROMPT.md"
$sessionContent = @"
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
  4. Package each modified mod into `$downMods\<mod_id>.zip` using `System.IO.Compression.ZipArchive` with **forward-slash (`/`) entry paths** (`$entryName = `$f.FullName.Substring(`$src.Length + 1).Replace("\", "/")`). **NEVER** use `[System.IO.Compression.ZipFile]::CreateFromDirectory()` because Windows backslashes (`\`) break Godot `res://` path resolution.
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

### F. Asynchronous Coroutines (await chain.execute_next)
* When hooking a vanilla Godot coroutine (such as `Game.gd`'s `change_stage`), the hook function MUST use `await chain.execute_next(...)`. Failing to `await` causes a `SCRIPT ERROR: Trying to call an async function without "await"` and breaks the stage transition, leaving the player outside the viewport.

---

## 4. Subsystem Architecture & Current Backlog

### 1. Custom Maps (101–105) & Level Select Carousel
* **Map Registry IDs:**
  * `101`: Lost Expedition (`gareth-lost_expedition_mod`)
  * `102`: Tectonic Faultline (`gareth-tectonic_faultline_mod`)
  * `103`: The Living Canvas (`gareth-living_canvas_mod` — default image: "Your Mum" beach mosaic)
  * `104`: The Abyssal Trench (`gareth-abyssal_trench_mod`)
  * `105`: Diagonal Seams (`gareth-diagonal_map_mod` — 45-degree rotated strata)
* **Registration Contract:**
  * `LevelManager` is NOT at `/root/LevelManager`; it lives at `Gvars.level_manager`.
  * Every custom map helper MUST register into `Gvars.level_manager.all_levels[ID]` BEFORE `level_select.gd:_ready()` iterates `LEVEL_ORDER`.
* **Recent Fixes:**
  * Diagonal Seams (105) preview generation restored.
  * Living Canvas (103) UI button restored using `call_deferred("add_child", btn)` to prevent tree lock crash.
  * `Game.hooks.gd` across all maps updated to properly `await chain.execute_next` for safe `change_stage` coroutine routing.

### 2. Bouncing Ball Mod (`gareth-bouncing_ball_mod`)
* **The Contract:** `bouncing_ball_equip.gd` instantiates `var proj := CharacterBody2D.new()`, attaches `bouncing_ball_projectile.gd`, and sets `proj.damage`, `proj.radius`, `proj.tilemap`, and `proj.ball_texture`.
* **Recent Fixes:** Restored `CollisionShape2D` instantiation in `_ready()` with a 7.0px radius so Godot physics detects wall collisions, and restored the `_spawn_blast_shockwave` particle ring on detonation.

### 3. Henry the Hoover (`gareth-henry_the_hoover_mod`) & Teletubbies (`gareth-teletubbies_mod`)
* **Outstanding Task:** Replace the simplified procedural face with high-fidelity pixel art based on the Numatic Henry 200 reference photo (glossy domed bowler hat, white arched eyes, nose hose coupling, and curved smile). Add the rate-limited (1.0s cooldown) gobble audio/squash effect on item pickup.

### 4. Employee Miner & Collector Upgrades (`gareth-employee_passives_mod`)
* **Outstanding Task:** Ensure these 3 stacking multipliers (`employee_miner_range`, `employee_miner_pickup_speed`, `collector_range`) are properly registered into the in-game passive selection pool (`choose_passive.gd`) and/or between-day Bonus Shop (`management_screen.gd` / `passive_bonuses.gd`) so the player can see and pick them.

### 5. Player Clip / Reach Expansion Mod (`gareth-reach_expansion_mod`)
* **Outstanding Task:** Expands player ore pickup clip area, stockpile deposit distance (`Stockpile.gd`), and NPC quest interaction range (`QuestPoint` / Tabatha the Mermaid) by 1 tile (+24px). Tune the interaction distance and inject it as a rare, high-cost, non-scaling perk in the between-day Bonus Shop.

### 6. Quadcopter Drone Workforce (`gareth-drone_workforce_mod`)
* **Outstanding Task:** Test the replacement of humanoid pickaxe miners with hovering laser quadcopters, and the replacement of UFO collectors with cargo drones equipped with magnetic winches and navigation strobes.

### 7. Thomas the Tank Engine Class & Bottom Rail (`gareth-thomas_tank_engine_mod`)
* **Outstanding Task:** Expose the three distinct upgrade branches in the shop/management interface: Locomotive Upgrade, Wagon Count, and Hopper Capacity. Register the railway engine as a selectable class on the Sky Mine stage.

### 8. Universal Mod Manager & Mod Store (`gareth-mod_manager_mod`)
* Main Menu features the custom hanging wooden sub-board (`✦ ENHANCED BY GARETH WHITE & GEMINI ✦`) and buttons (`Mod Manager`, `Mod & Map Store`, `Leaderboards`).

### 9. Amazon Delivery (`gareth-scrap_and_delivery_mod`) & Game Speed (`gareth-game_speed_mod`)
* **Working & Verified:** Amazon (`[B]`) drops parachute crates at `z_index = 60`. `itemBuyPrice` is guarded against null crash using exact string replacement (preserving tabs).
* **Working & Verified:** Game Speed micro-dock (`◀ 1.00x ▶` + `⏰ End Day` `[F8]`) is docked cleanly at the bottom-right during active mining shifts.
"@
$sessionContent | Set-Content -Path $sessionPromptPath -Encoding UTF8

Write-Output "--- 3. Creating Agile User Stories ---"
$story1 = @"
# US-01: Thomas the Tank Engine Upgrade Branches
**Status:** To Do
**Mod:** `gareth-thomas_tank_engine_mod`

**Description:**
As a player, I want to upgrade my Thomas the Tank Engine class in the shop so I can haul more ore faster.

**Acceptance Criteria:**
- Expose Locomotive Upgrade branch (Thomas -> Edward -> Henry -> Gordon) scaling speed and pulling capacity.
- Expose Wagon Count branch (1 through 6 rolling freight wagons).
- Expose Hopper Capacity branch (50 -> 150 -> 500 -> 2000).
- Register the railway engine as a selectable class on the Sky Mine stage.
"@
$story1 | Set-Content -Path (Join-Path $storiesDir "US-01_Thomas_Upgrades.md") -Encoding UTF8

$story2 = @"
# US-02: Reach Expansion Bonus Shop Integration
**Status:** To Do
**Mod:** `gareth-reach_expansion_mod`

**Description:**
As a player, I want to purchase the Reach Expansion perk in the Bonus Shop so I can interact with stockpiles, ores, and NPCs from further away.

**Acceptance Criteria:**
- Tune the interaction distance to +1 tile (+24px) for ore magnetic aura, stockpile deposit, and NPC dialogues.
- Inject the perk as a rare, high-cost, non-scaling item in the between-day Bonus Shop (`management_screen.gd`).
"@
$story2 | Set-Content -Path (Join-Path $storiesDir "US-02_Reach_Expansion.md") -Encoding UTF8

$story3 = @"
# US-03: Quadcopter Drone Workforce Evaluation
**Status:** In Progress (Discovery)
**Mod:** `gareth-drone_workforce_mod`

**Description:**
As a player, I want my automated workforce to be visualised as quadcopters and cargo drones rather than humanoid miners and UFOs.

**Acceptance Criteria:**
- Replace humanoid pickaxe miners with hovering laser quadcopters.
- Replace UFO collectors with cargo drones featuring magnetic winches and navigation strobes.
"@
$story3 | Set-Content -Path (Join-Path $storiesDir "US-03_Quadcopter_Workforce.md") -Encoding UTF8

$story4 = @"
# US-04: Henry the Hoover Visuals & Audio Rate Limit
**Status:** To Do
**Mod:** `gareth-henry_the_hoover_mod`

**Description:**
As a player, I want the vacuum cleaner to look like an authentic Numatic Henry 200 and not spam audio when gobbling ore.

**Acceptance Criteria:**
- Replace procedural face with high-fidelity pixel art (glossy domed bowler hat, white arched eyes, nose hose coupling, curved smile).
- Add a 1.0s cooldown rate-limit to the gobble audio/squash effect on item pickup.
"@
$story4 | Set-Content -Path (Join-Path $storiesDir "US-04_Henry_Hoover.md") -Encoding UTF8

Write-Output "--- 4. Concurrently Discovering Thomas, Drones, Reach, and Henry Files ---"
# $discoveryScript = @"
# `$repoRoot = "C:\Dev\coal-llc-mods"

# Write-Output "--- DISCOVERY: US-01 Thomas the Tank ---"
# `$thomasDir = Join-Path `$repoRoot "mods-unpacked\gareth-thomas_tank_engine_mod\mods-unpacked\gareth-thomas_tank_engine_mod"
# if (Test-Path `$thomasDir) { Get-ChildItem `$thomasDir -Recurse -Filter "*.gd" | ForEach-Object { Write-Output "FILE: `$_"; Get-Content `$_ -TotalCount 25 } } else { Write-Output "Thomas dir not found" }

# Write-Output "`n--- DISCOVERY: US-02 Reach Expansion ---"
# `$reachDir = Join-Path `$repoRoot "mods-unpacked\gareth-reach_expansion_mod\mods-unpacked\gareth-reach_expansion_mod"
# if (Test-Path `$reachDir) { Get-ChildItem `$reachDir -Recurse -Filter "*.gd" | ForEach-Object { Write-Output "FILE: `$_"; Get-Content `$_ -TotalCount 25 } } else { Write-Output "Reach dir not found" }

# Write-Output "`n--- DISCOVERY: US-03 Quadcopter Drones ---"
# `$droneDir = Join-Path `$repoRoot "mods-unpacked\gareth-drone_workforce_mod\mods-unpacked\gareth-drone_workforce_mod"
# if (Test-Path `$droneDir) { Get-ChildItem `$droneDir -Recurse -Filter "*.gd" | ForEach-Object { Write-Output "FILE: `$_"; Get-Content `$_ -TotalCount 25 } } else { Write-Output "Drone dir not found" }

# Write-Output "`n--- DISCOVERY: US-04 Henry Hoover ---"
# `$henryDir = Join-Path `$repoRoot "mods-unpacked\gareth-henry_the_hoover_mod\mods-unpacked\gareth-henry_the_hoover_mod"
# if (Test-Path `$henryDir) { Get-ChildItem `$henryDir -Recurse -Filter "*.gd" | ForEach-Object { Write-Output "FILE: `$_"; Get-Content `$_ -TotalCount 25 } } else { Write-Output "Henry dir not found" }
# "@
# $discoveryScript | Set-Content -Path (Join-Path $repoRoot "ai_discovery.ps1") -Encoding UTF8
Write-Output "Executing Discovery Script..."
#Join-Path $repoRoot "ai_discovery.ps1"
# & powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "ai_discovery.ps1")
./ai_discovery.ps1

Write-Output "--- Committing Repo Architecture Updates ---"
git add SESSION_PROMPT.md docs/
git commit -m "Docs: Initialize agile User Stories, Wiki architecture, and sync SESSION_PROMPT.md with latest engine contracts and backlog state."
git push origin main
Write-Output "Complete!"