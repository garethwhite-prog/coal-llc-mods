# Seismic Hazards & Cave-Ins

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Hardcore mutator where extensive deep mining causes tectonic instability, triggering ceiling collapses and falling rock hazards.

---

## Technical Details (For Modders)
Hooks destroy_tile in tile_map_chunk.gd, tracking consecutive break events to spawn falling rock physics entities from above.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.