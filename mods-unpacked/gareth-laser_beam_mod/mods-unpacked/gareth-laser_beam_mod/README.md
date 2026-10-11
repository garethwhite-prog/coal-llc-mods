# High-Energy Laser Beam System

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
The **High-Energy Laser Beam System** restores the game's unused continuous beam shader (shaders/laser.gdshader) and audio assets into an active excavation weapon.

Holding the use action channels a collimated energy beam that melts subterranean strata in real time, accompanied by dynamic particle sparks and looping beam audio.

---

## Technical Details (For Modders)
Instantiates LaserBeamWeapon using Line2D and shaders/laser.gdshader with fractal Brownian motion. Casts linear ray-marches against TileMapManager with per-tick block damage.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.