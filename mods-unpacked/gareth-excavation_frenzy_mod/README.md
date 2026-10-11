# Excavation Frenzy

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Consecutive pickaxe swings build a momentum combo multiplier that increases swing animation speed up to 3x and triggers a 5-hit shockwave.

---

## Technical Details (For Modders)
Hooks mine_action in player_2.gd, maintaining a timed swing counter and applying scale multipliers to the animation player.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.