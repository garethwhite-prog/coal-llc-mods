# Known Regressions, Mistakes & Safeguards

This dossier tracks identified defects, the underlying engine root-cause, and regression assertions enforced by automated test runners.

## 1. ModRegistry Interface Contract
- **Symptom**: 5,000+ physics errors (`Nonexistent function 'is_mod_active_for_run' in base 'GDScript'`), Knight class vanishing, blank Mod Manager.
- **Root Cause**: Omitting `static func is_mod_active_for_run(mod_key: String) -> bool` from `mod_registry.gd`.
- **Safeguard**: Static AST check in `tests/test_runner.ps1` enforcing `is_mod_active_for_run` existence.

## 2. Block Hit / Damage Desync
- **Symptom**: Blocks appear to take damage and instantly "heal" on the subsequent hit.
- **Root Cause**: Physics frame termination due to unhandled GDScript exceptions in player or chunk hooks.
- **Safeguard**: Zero-error runtime log validation and ensuring all chunk hooks call `chain.execute_next([idx, damage])`.

## 3. In-Game Stage Gating
- **Symptom**: HUD widgets (Speed, Amazon) either permanently invisible or overlapping Main Menu / Class Select.
- **Root Cause**: Assuming `Gconsts.Stages._IN_GAME` exists (vanilla enum uses `_MINE_REGION` = 2).
- **Safeguard**: Dual detection via `Player` and `TileMapManager` existence, guarded against `PauseMenu`.

## 4. 0g Shop Item Division by Zero
- **Symptom**: Free starter items lock purchase buttons and crash spinbox calculations ($0 / 0 \to \text{NaN}$).
- **Root Cause**: `custom_amount.max_value = Gvars.CashCount / item.itemBuyPrice` unguarded.
- **Safeguard**: Explicit `cost <= 0.0` guard ensuring instant zero-cost purchaseability.
## 5. GDScript Object.get() Argument Arity
- **Symptom**: Engine crashes at boot with `SCRIPT ERROR: Parse Error: Too many arguments for "get()" call. Expected at most 1 but received 2`.
- **Root Cause**: In Godot 4, `Dictionary.get(key, default)` accepts two arguments, but `Object.get(property)` on an instantiated Object/Ref接ounted class accepts strictly one argument.
- **Safeguard**: Always use property existence checks: `if "prop" in obj: val = obj.prop` or `obj.get_meta("prop", default)`.

## 6. Engine Autoload vs Global Variable Topology
- **Symptom**: Subsystem helper scripts return null when attempting to resolve game managers via `/root/<ManagerName>`.
- **Root Cause**: `LevelManager` and `BonusEquipmentManager` are not engine autoloads registered in `project.godot`; they are instantiated and held as runtime fields on `Gvars` (`Gvars.level_manager`, `Gvars.bonus_equipment_manager`).
- **Safeguard**: Resolve managers exclusively through `Gvars.level_manager` and check instance validity.

## 7. Custom Map Carousel Dictionary Key Integrity
- **Symptom**: Custom maps disappear from the Level Select screen, and logs report `SCRIPT ERROR: Invalid access to property or key '105' on a base object of type 'Dictionary'`.
- **Root Cause**: `level_select.gd` iterates `LEVEL_ORDER: Array` and immediately accesses `all_levels[level_key]["level"]`. If a mod appends an ID to `LEVEL_ORDER` before registering the corresponding dictionary entry into `Gvars.level_manager.all_levels`, the carousel generation loop crashes on frame 1.
- **Safeguard**: Every custom map must register `all_levels[ID] = { "level": custom_level, "is_unlocked": true }` before `level_select.gd:_ready()` executes, and must set `custom_level.level_image` (not `level_icon`).

## 8. Bare CharacterBody2D Instantiation Lacking CollisionShape2D
- **Symptom**: Projectiles launch at excessive speed, travel infinitely through solid terrain, and fail to bounce, collide, or explode.
- **Root Cause**: Weapon thrower scripts instantiating `CharacterBody2D.new()` in code attach a script but do not load a `.tscn`. If the attached projectile script omits instantiating `CollisionShape2D` with a concrete `Shape2D` in `_ready()`, Godot's physics engine has no collision boundary to evaluate during `move_and_collide()`.
- **Safeguard**: Procedural projectiles must create a `CollisionShape2D` with `CircleShape2D` inside `_ready()`, enforce a physical fuse timer, and bound launch velocities.

## 9. Property Renaming Breaking Equip Hook Contracts
- **Symptom**: Weapons fail to throw, logging `SCRIPT ERROR: Invalid assignment of property or key 'damage' with value of type 'float' on a base object of type 'CharacterBody2D'`.
- **Root Cause**: Refactoring an internal projectile variable (e.g., renaming `damage` to `base_damage`) breaks external equip effects that assign to `.damage`, `.radius`, `.tilemap`, or `.ball_texture`.
- **Safeguard**: Maintain explicit getter/setter aliases or property declarations on projectile classes for all properties assigned by the equip effect.

## 10. ModLoader Hook Targets Must Exist in Vanilla Script
- **Symptom**: ModLoader logs `Skipped adding hook "_ready" (not found in vanilla script)`, and visual/audio skins fail to apply.
- **Root Cause**: ModLoader 7.x cannot attach hooks to methods that do not exist in the decompiled vanilla `.gd` file (e.g., `vacuum_cleaner.gd` declares `_physics_process` but lacks `_ready`).
- **Safeguard**: Inspect `_dump` to verify vanilla method signatures. If `_ready()` is absent, hook `_physics_process(delta)` and use a metadata guard (`vac.has_meta(...)`) for one-time initialization.

## 11. Asynchronous Shop Delivery Double-Charging & Hotbar Pollution
- **Symptom**: Wallet is charged on order, but upon parachute crate landing, capacity upgrades (extra stack size, extra slots) fail to apply, or passive cards get dumped into hotbar tool slots.
- **Root Cause**: Vanilla `increase_stack_size.gd` checks `if ((Gvars.CashCount - shop_item.itemBuyPrice) >= 0)`. Because the cash was already deducted at order time, the second check inside `buy_effect()` fails. Furthermore, unconditional `addToInventory()` calls place non-physical items into the hotbar.
- **Safeguard**: Zero `itemBuyPrice = 0.0` inside the delivery callback before executing `buy_effect()`, directly apply `maxStack` and `inventorySize` expansions to `PlayerInventory.tres`, and only route physical tools into inventory slots.

## 12. Viewport Root UI Attachment vs Card Container Scoping
- **Symptom**: UI buttons (such as file browsers) float over ground terrain and grass, remaining visible across all level carousel tabs.
- **Root Cause**: Adding UI nodes directly to the root menu scene with screen-relative anchors rather than parenting them inside the specific card container (`MarginContainer/VBoxContainer` in `level_info.tscn`).
- **Safeguard**: Inspect the card container hierarchy and dock level-specific controls directly into matching card instances (`card.game_level.level == TARGET_ID`).

## 13. Zipped Binary Texture & Sound Loading
- **Symptom**: Runtime errors reporting `ERROR: No loader found for resource: res://...png (expected type: )`.
- **Root Cause**: Calling `load("res://mods-unpacked/.../image.png")` inside mounted mod archives fails because Godot 4 requires compiled `.import` files for resource loader paths.
- **Safeguard**: Read raw bytes via `FileAccess.get_file_as_bytes()` and decode textures using `Image.load_png_from_buffer(bytes)` -> `ImageTexture.create_from_image(img)`.

## 14. Windows Backslash vs Forward Slash Archive Paths in ModLoader
- **Symptom**: ModLoader mounts a `.zip` file but fails to load internal scripts or extensions, reporting missing paths.
- **Root Cause**: `ZipFile::CreateFromDirectory` uses OS-native Windows backslashes (`\`) for archive entries. Godot's internal virtual filesystem requires POSIX forward slashes (`/`).
- **Safeguard**: Package mod zip archives using `System.IO.Compression.ZipArchive` and normalize entry names via `.Replace("\", "/")`.
