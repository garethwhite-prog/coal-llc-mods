# Heavy Demolition Bombs

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Restores unused \times32$ animated bomb sheets from the game files, adding an arsenal of heavy demolition explosives:
* **Bunker Buster:** High-mass bomb that punches deep into cavern floors before detonating.
* **Cryo-Cluster Bomb:** Releases a frost shockwave across an expanded radius.
* **Thermobaric Charge:** High-temperature vacuum blast clearing 20 to 36 block radii.

Features extended 3.0s fuses and custom explosion audio.

---

## Technical Details (For Modders)
Registers HeavyBombEntity instances with custom blast_radius (18-36 blocks) and damage scaling tied to Gvars.passives.bomb_damage.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.