# Current Active Sprint & Worklist

## 🔴 Open Bugs (Highest Priority)
* **[BUG-03]** Verify isolation between Henry Hoover (Player tool) and Drone Workforce (NPC automated entities).

## 🟡 In Progress / Testing
* **[US-01]** Thomas the Tank Engine: Base class deployed. (Awaiting graphic implementation logic).
* **[US-02]** Reach Expansion: Tune interaction distance to +1 tile (+24px) for stockpile, ore, and NPCs. Inject into Bonus Shop.
* **[US-06]** Deep Layer Bonus Weapons: Create a mod downloadable via Mod Store that spawns bonus weapons in deeper strata.
* **[US-07]** Mod Manager Search/Filter: Replicate the Mod Store's search bar and dropdown filters inside the local Mod Manager UI.

## 🟢 Completed (Pending Verification)
* **[BUG-01]** Quadcopter Workforce: Vanilla Sprites node completely freed to prevent AnimationPlayer override.
* **[BUG-02]** AutoPassiveChooser: Reverted corrupted settings_2.hooks.gd to restore Passive Order tab UI rendering.
* **[BUG-07]** Viewport/Camera Break: Global wait chain.execute_next enforced across all Game.hooks.gd.
* **[US-05]** Mod Store Registry: mod_catalog.json re-architected to mock GitHub Release API schema. Thomas and Drones now indexable.
* **[CORE]** Bouncing Ball Physics: Mount logic migrated to call_deferred to eliminate runtime scene tree locks.
