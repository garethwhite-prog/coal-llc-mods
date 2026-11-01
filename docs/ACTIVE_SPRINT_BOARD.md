# Current Active Sprint & Worklist

## 🔴 Open Bugs (Highest Priority)
* **[BUG-03]** Verify isolation between Henry Hoover (Player tool) and Drone Workforce (NPC automated entities).
* **[BUG-01]** Quadcopter Visuals: Await validation.

## 🟡 In Progress / Testing
* **[US-05]** Mod Store Central Registry: mod_catalog.json re-architected to mock GitHub Release API schema. Thomas and Drones now indexable. (Awaiting User Validation).
* **[BUG-02]** Passives UI: Bouncing Ball passives physically injected into passive_order.tscn node tree to bypass dynamic duplication limits. (Awaiting User Validation).
* **[US-01]** Thomas the Tank Engine: Base class deployed. (Awaiting graphic implementation logic).
* **[US-02]** Reach Expansion: Tune interaction distance to +1 tile (+24px) for stockpile, ore, and NPCs. Inject into Bonus Shop.

## 🟢 Completed (Pending Verification)
* **[US-06]** Deep Layer Bonus Weapons: Mod scaffolded and hooked to Chest.gd to drop plasma rayguns past depth 50.
* **[US-07]** Mod Manager Search: LineEdit search bar dynamically injected via call_deferred.
* **[BUG-04]** Mod Uninstall: Store UI now correctly changes to "Restart Required" to reflect OS file locks.
* **[BUG-07]** Viewport/Camera Break: Global wait chain.execute_next enforced across ALL .hooks.gd files.
