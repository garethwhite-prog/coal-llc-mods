# The Knight Class

**Namespace:** gareth  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Playable melee class starting with a heavy broadsword that sweeps through rock and ore in a wide 180° frontal cleave arc.

---

## Technical Details (For Modders)
Instantiates KnightSwordEquipEffect hooked into player.pointer_global_pos. Dispatches rotational raycasts through player.tilemap damaging colliding tiles using native SwordThud.wav audio.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.