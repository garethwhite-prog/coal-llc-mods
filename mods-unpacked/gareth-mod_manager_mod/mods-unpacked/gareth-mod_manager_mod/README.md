# Universal Mod Manager & Mutator Selector

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Adds a unified Mod Manager to the Main Menu, in-game Pause Menu, and Settings. Includes a full-screen pre-run mutator selector that dynamically categorizes installed mods into weapons, progression, and mutators.

---

## Technical Details (For Modders)
Hooks MainMenu.gd, settings_2.gd, and PauseMenu.gd. Scans ModLoaderStore.mod_data at runtime. Replaces choose_passive.gd with a fail-safe generator.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.