# Current Active Sprint & Worklist

## 🔴 Open Bugs (Highest Priority)
* **[BUG-01]** Quadcopter / Drone Overrides Failing: Miners and UFOs are not transforming. (Likely caused by vanilla AnimationPlayers forcing visibility back on, or incorrect node targeting).   
* **[BUG-02]** Bouncing Ball Passives Missing: The AutoPassiveChooser UI is not displaying the new passives. (Requires finding the exact array in the nanobotz mod where passives are hardcoded).   
* **[BUG-03]** Henry Hoover Visuals Failing: Vacuum retains the default pink sprite. (Requires dumping vacuum_cleaner.tscn to find the exact sprite node name).   
* **[BUG-04]** Henry Hoover Uninstall Bug: Mod Store allows installing Teletubbies but fails to remove Henry. (Requires inspecting mod_store_client.gd file lock/deletion logic).
* **[BUG-05]** Mod Manager "By Community" Tagging: Local mods by Gareth/Gemini incorrectly display as Community. (Requires inspecting mod_manager_view.gd author parsing)

## 🟡 IN PROGRESS / TO DO (User Stories)
* **[US-05]** Mod Store Central Registry: We need to locate the JSON file the Mod Store downloads (e.g., packages.json) and update it in our GitHub repo so the new mods actually appear when searching.   
* **[US-01]** Thomas the Tank Engine: Base class loaded. Needs shop integration for Locomotive speed, Wagon count, and Hopper capacity.
* **[US-02]** Reach Expansion: Tune interaction distance (+24px). Inject as a Bonus Shop perk.
* **[US-06]** (NEW) Deep Layer Bonus Weapons: Create a mod downloadable via Mod Store that spawns bonus weapons in deeper strata.
* **[US-07]** (NEW) Mod Manager Search/Filter: Replicate the Mod Store's search bar and dropdown filters inside the local Mod Manager UI.

## 🟢 COMPLETED & VERIFIED
* **[CORE]** ModLoader Manifest V3 Schema fixed globally.
* **[CORE]** Asynchronous change_stage coroutines patched across all map mods.
* **[US-EXT]** Diagonal Seams (105) & Living Canvas (103) UI buttons mounted via call_deferred.
* **[US-EXT]** Bouncing Ball physics, bounce damping, and blast shockwave restored.
* **[US-EXT]** Amazon Delivery parachute crash fixed (null guard on itemBuyPrice).