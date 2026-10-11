# Multi-Save Profile Manager

**Namespace:** gareth  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Adds 6 independent career profile slots to the main menu with stats tracking (day, cash, class) and automatic profile migration from single-save career files.

---

## Technical Details (For Modders)
Passive filesystem listener monitors user://v04_savegame.save modification timestamps and syncs to user://saves/slot_X/. Reads and validates user://v04_saveglobals.save on boot to protect all unlocked classes and badges.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.