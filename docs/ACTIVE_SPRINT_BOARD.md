# Current Active Sprint & Worklist

## 🔴 Open Bugs (Highest Priority)
* **[BUG-03]** Verify isolation between Henry Hoover (Player tool) and Drone Workforce (NPC automated entities).

## 🟡 In Progress / Testing
* **[US-02]** Reach Expansion: Tune interaction distance to +1 tile (+24px) for stockpile, ore, and NPCs. Inject into Bonus Shop.
* **[US-06]** Deep Layer Bonus Weapons: Create a mod downloadable via Mod Store that spawns bonus weapons in deeper strata.
* **[US-07]** Mod Manager Search/Filter: Replicate the Mod Store's search bar and dropdown filters inside the local Mod Manager UI.

## 🟢 Completed (Pending Verification)
* **[BUG-01]** Quadcopter Workforce: MiningAnimationPlayer disabled and Sprites hidden to stop vanilla overwrite.
* **[BUG-02]** AutoPassiveChooser: Dynamic VBoxContainer templates duplicated and mounted via call_deferred.
* **[BUG-04]** Mod Uninstall Lock: OS.delay_msec(150) injected to drop resource locks before DirAccess.remove.
* **[BUG-05]** Mod Category Tags: mod_manager_view.gd re-routed to parse Gareth White from the Manifest Author array.
* **[US-05]** Mod Store Registry: Verified Store dynamically polls GitHub Releases API rather than a static JSON file.
