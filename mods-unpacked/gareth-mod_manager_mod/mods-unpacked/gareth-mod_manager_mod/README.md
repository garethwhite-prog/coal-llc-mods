# Universal Mod Manager & Mutator Selector

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
The **Universal Mod Manager** provides seamless runtime control over every installed modification for *Coal LLC*. It dynamically hooks the Main Menu, in-game Pause Menu, and the native Settings screen, offering both an executive-level overview of installed mods and a full-screen pre-run mutator selector that categorizes add-ons into Weapons, Progression, Automation, Hardcore Mutators, and Performance utilities.

The mod automatically scans ModLoaderStore.mod_data on engine boot, discovering present and future .zip packages without hardcoded registry lists. When starting a career run, the pre-run modal captures your custom toggle presets and writes them into user://saves/slot_X/run_config.json, preserving independent mod loadouts across different save profiles.

Additionally, this framework includes an active shop filtering layer that intercepts management_screen.gd. It removes disabled weapons from the store shelves and enforces class-specific weapon whitelists, ensuring classes only encounter equipment matching their chosen archetype.

---

## Technical Details (For Modders)
Hooks MainMenu.gd, settings_2.gd, PauseMenu.gd, choose_passive.gd, and management_screen.gd. Intercepts load_equipment_shop() to filter shop cards by run_config.json toggles and class whitelists.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.