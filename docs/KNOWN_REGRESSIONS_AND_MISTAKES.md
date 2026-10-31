# Known Regressions, Mistakes & Safeguards

This dossier tracks identified defects, the underlying engine root-cause, and regression assertions enforced by automated test runners.

## 1. ModRegistry Interface Contract
- **Symptom**: 5,000+ physics errors (Nonexistent function 'is_mod_active_for_run' in base 'GDScript').
- **Root Cause**: Omitting static func is_mod_active_for_run(mod_key: String) -> bool from mod_registry.gd.

## 2. Block Hit / Damage Desync
- **Symptom**: Blocks appear to take damage and instantly "heal" on the subsequent hit.
- **Root Cause**: Physics frame termination due to unhandled GDScript exceptions in player or chunk hooks.

## 3. In-Game Stage Gating
- **Symptom**: HUD widgets (Speed, Amazon) either permanently invisible or overlapping Main Menu.
- **Root Cause**: Assuming Gconsts.Stages._IN_GAME exists (vanilla enum uses _MINE_REGION = 2).

## 4. 0g Shop Item Division by Zero
- **Symptom**: Crash on purchase.
- **Root Cause**: Unhandled 0 item prices. Guarded by itemBuyPrice = max(1.0, val).

## 5. Engine Arity Limits (Object.get)
- **Symptom**: Fatal parse error Expected at most 1 but received 2 for get().
- **Root Cause**: Passing a default value to Object.get(). Dictionary.get() takes 2, Object.get() strictly takes 1.

## 6. Scene Tree Locks (add_child)
- **Symptom**: Parent node is busy setting up children, add_child() failed.
- **Root Cause**: Using dd_child() directly inside a _ready() hook while the node is still mounting. 
- **Safeguard**: Always use call_deferred("add_child", node) in setup phases.

## 7. Asynchronous Coroutines (change_stage)
- **Symptom**: Camera zooms out infinitely, player dumped out of viewport.
- **Root Cause**: Calling chain.execute_next() without wait on a vanilla function that uses coroutines.
- **Safeguard**: Any hook modifying Game.gd:change_stage must use wait chain.execute_next(...).

## 8. ModLoader File Locks
- **Symptom**: ModLoader aborts zip generation, silently disabling ALL mods.
- **Root Cause**: Godot background processes locking mod-hooks.zip or syntax parse errors blocking compilation.
