# Excavation Frenzy

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Chains rapid mining strikes into a momentum combo multiplier. Consecutive pickaxe hits accelerate swing speed up to 3x and unleash a shockwave on every 5th strike.

---

## Technical Details (For Modders)
Hooks mine_action in player_2.gd, tracking a 1.2s timeout counter and scaling animation player speed proportionally with combo rank.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.