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
