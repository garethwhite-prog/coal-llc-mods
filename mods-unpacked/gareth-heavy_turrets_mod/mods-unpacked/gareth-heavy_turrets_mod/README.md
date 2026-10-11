# Heavy Automated Turrets

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Utilizes the unused tank turret graphic (ssets/Equipment/vehicles/tank_turret.png) to introduce deployable automated defense and mining turrets.

When deployed onto the cavern floor, the turret actively tracks nearby stone and ore veins within radar range, automatically firing kinetic pulses every 0.35 seconds to drill surrounding blocks.

---

## Technical Details (For Modders)
Instantiates HeavyTurretEntity on the tilemap, executing radial collision sweeps and rotating the turret sprite toward target coordinates.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.