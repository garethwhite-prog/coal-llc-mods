# Coal LLC Modding Ecosystem — Master Context, Architecture & Lessons Learned

## 1. Environment & Path Topology (CRITICAL)
* **Engine:** Godot Engine v4.4.1.stable.official (Vulkan 1.4 Forward+, Windows).
* **Game Version:** Coal LLC v1.4.1.1.
* **Source Repository Root:** `C:\Dev\coal-llc-mods`
* **MOD SOURCE CODE LOCATION (READ THIS):** All mod development happens inside `C:\Dev\coal-llc-mods\mods-unpacked\`. 
  * Due to ModLoader architecture, mods are double-nested. Example: `mods-unpacked\gareth-reach_expansion_mod\mods-unpacked\gareth-reach_expansion_mod\`. 
  * **DO NOT** look for mod source code in the repository root.
* **Decompiled Vanilla Game Dump:** `C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\_dump`
* **Physical Staging Folder:** `C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\downloaded_mods`
* **Active Runtime Mods Folder:** `C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods`
* **Telemetry Output:** `tests_concise.txt` (summarized error ledger).

---

## 2. Non-Negotiable Engineering Rules & Syntax Contracts

### A. GDScript `Object.get()` vs `Dictionary.get()`
* In Godot 4, `Dictionary.get(key, default)` accepts 2 arguments, but `Object.get(property)` accepts **strictly 1 argument**.
* Passing 2 arguments to `Object.get()` produces a fatal compile-time parse error and kills the mod. Use: `if "prop" in obj: val = obj.prop`.

### B. ModLoader Hook Targets Must Exist in Vanilla Source
* `ModLoaderMod.install_script_hooks` checks vanilla method signatures during boot.
* If a vanilla script does not define `func _ready():`, hooking `_ready` in an extension script fails silently or aborts. Always check `_dump` for the exact vanilla method signatures.

### C. Zipped Texture & Binary Resource Loading
* Loose `.png` files inside mounted `.zip` mod packages cannot be resolved via `load("res://...png")`.
* **Standard Pattern:** Read bytes via `FileAccess.get_file_as_bytes()`, decode via `img.load_png_from_buffer(bytes)`, and create via `ImageTexture.create_from_image(img)`.

### D. Manifest V3 Schema Compliance
* ModLoader 7.x strictly validates `manifest.json`. Every mod manifest must contain `"compatible_mod_loader_version": ["7.0.1"]` and `"compatible_game_version": ["1.4.1.1"]`. Omitting these causes immediate rejection on boot.

---

## 3. Subsystem Architectural Blueprints

### A. Level Registration & Level Select Carousel
* `LevelManager` is **not an engine autoload** at `/root/LevelManager`. It is stored globally on `Gvars.level_manager`.
* Custom maps MUST register as `lvl_mgr.all_levels[MAP_ID] = { "level": custom_level_resource, "is_unlocked": true }`.
* If a map ID (101-105) is missing from `all_levels`, `level_select.gd` throws an unhandled dictionary error on frame 1, wiping the entire carousel.

### B. Amazon Delivery System (`gareth-scrap_and_delivery_mod`)
* When purchasing passive upgrades (extra stack size, extra slots), the item is paid for upon ordering. To prevent double-charging on delivery, zero the price (`item.itemBuyPrice = 0.0`) during the parachute callback before executing `buy_effect`.
* Apply passives directly to `PlayerInventory.tres` capacities. Do not drop passive item cards into hotbar slots.
* Crate spawning: Must set `crate.z_index = 60` and attach to `player.get_parent()` so it renders above subterranean rock.

### C. Bouncing Ball Weapon (`gareth-bouncing_ball_mod`)
* `BouncingBallEquipEffect` assigns `.damage`, `.radius`, `.tilemap`, and `.ball_texture` to the projectile. All four MUST exist on the `BouncingBallProjectile` class to prevent frame 1 crashes.

---

## 4. Historical Failures & Lessons Learned (DO NOT REPEAT)
1. **The Object.get() Crash:** Assuming Godot 4 `Object.get()` worked like `Dictionary.get(key, default)`.
2. **The LevelManager Autoload Assumption:** Assuming `LevelManager` was at `/root/LevelManager`. It was actually on `Gvars.level_manager`.
3. **The Root Directory Hallucination:** Assuming mod source code was in the root repository folder instead of `mods-unpacked/`.
4. **The Missing Z-Index:** Spawning items at default `z_index = 0` attached to the root viewport, causing them to render permanently behind the mining terrain.

---

## 5. Session Bootstrap Mandate
Before writing any code or proposing solutions, the AI MUST run a discovery script to:
1. Read the `git log -p SESSION_PROMPT.md` to understand how these rules evolved.
2. List all directories in `C:\Dev\coal-llc-mods\mods-unpacked\` to prove it knows where the source code lives.
3. Review the current state of `gareth-thomas_tank_engine_mod`, `gareth-reach_expansion_mod`, and `gareth-employee_passives_mod`.
