# Cosmic Collector Drones

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
The **Cosmic Collectors Mod** expands autonomous surface logistics with four ultra-high-tier Collector drones designed for massive late-game production:
* **Vortex Collector (Level 32 - Speed Branch):** Flight Speed 6.0, Inventory 60,000 items (,000,000).
* **Quantum Collector (Level 33 - Speed Branch):** Flight Speed 9.0, Inventory 180,000 items (,250,000,000).
* **Abyssal Collector (Level 34 - Capacity Branch):** Flight Speed 2.6, Inventory 300,000 items (,000,000).
* **Singularity Collector (Level 35 - Capacity Branch):** Flight Speed 3.5, Inventory 2,500,000 items (,500,000,000).

All employee tooltips feature click-through mouse filters to prevent shop interface blocking, while drone state persistence integrates safely with native career save files.

---

## Technical Details (For Modders)
Extends employee_manager.gd hierarchy and patches employee_shop_tooltip.gd to prevent UI mouse blocking. Bypasses Godot typed array limitations via hook chains.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.