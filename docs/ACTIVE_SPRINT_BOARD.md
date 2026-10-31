# Current Active Sprint & Worklist

## 🔴 Open Bugs (Highest Priority)
* **[BUG-01]** Quadcopters/Drones failing to render over active miners. (Needs dump inspection of mployee_miner_2.tscn tree).
* **[BUG-02]** Bouncing Ball passives missing from AutoPassiveChooser UI. (Needs inspection of passive_order.gd and .tscn).
* **[BUG-03]** Verify isolation between Henry Hoover (Player tool) and Drone Workforce (NPC automated entities).

## 🟡 In Progress / Testing
* **[US-05]** Mod Store Registration: Quadcopters, Henry, and Thomas mapped to mod_registry.gd. (User verifying visibility).
* **[US-04]** Henry the Hoover Visuals: High-fidelity Numatic pixel art and 1.0s audio gobble cooldown applied. (User testing in-game).
* **[US-01]** Thomas the Tank Engine: Base class loaded, exports exposed to inspector. (Awaiting graphical asset switching logic).

## 🟢 Completed (Pending Verification)
* **[CRITICAL]** Asynchronous change_stage coroutine restored across all mods (wait chain.execute_next).
* **[CRITICAL]** Amazon Delivery lambda crash patched via is_instance_valid(crate).
* **[CRITICAL]** Bouncing Ball collision layer and mask restored for cavern wall ricochets.
* **[CRITICAL]** Living Canvas and Diagonal Seams UI components safely mounted via call_deferred.
