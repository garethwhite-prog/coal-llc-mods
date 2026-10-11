# Multiplicative Weapon Stacker

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Purchasing duplicate weapons in the shop multiplicatively scales their stats. Miniguns reduce cooldowns down to 0.01s while firing walls of lead; water guns expand spray radii logarithmically to soak entire shafts in a single blast.

---

## Technical Details (For Modders)
Hooks gun.gd and water_gun.gd in physics_process, querying inventory item counts and multiplying projectile quantities and cooldowns accordingly.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.