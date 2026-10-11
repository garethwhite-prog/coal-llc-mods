# Prospector's Acoustic Beacon

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Emits periodic sonar sweeps centered on the player, pinging coordinates of high-value ore veins through solid rock.

---

## Technical Details (For Modders)
Runs an acoustic pulse timer in player_2.gd, pinging local tilemap chunks and spawning directional sparkle indicators.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.