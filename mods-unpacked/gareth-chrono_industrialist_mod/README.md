# Chrono-Industrialist Class

**Namespace:** gareth  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Temporal excavator whose pickaxe deploys localized Stasis Fields every 10th swing, absorbing damage and releasing an amplified shockwave.

---

## Technical Details (For Modders)
Tracks swing counters on player mine_action hooks, spawning a temporal buffer node that defers tile destruction until releasing a 2x kinetic burst.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.