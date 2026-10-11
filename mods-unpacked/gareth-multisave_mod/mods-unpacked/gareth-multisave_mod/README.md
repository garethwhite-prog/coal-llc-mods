# Multi-Save Profile Manager

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Introduces 6 independent save profile slots accessible from the Main Menu, each tracking career progress, day count, cash reserves, and active classes.

The manager automatically migrates single-save career files into Slot 1 and validates career badges on boot to protect unlocked classes and achievements.

---

## Technical Details (For Modders)
Passive filesystem listener monitors user://v04_savegame.save timestamps and mirrors to user://saves/slot_X/. Reads and validates user://v04_saveglobals.save on startup.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.