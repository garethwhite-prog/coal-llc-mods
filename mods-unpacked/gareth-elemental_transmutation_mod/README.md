# Elemental Transmutation

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Destroying tiles afflicted with elemental effects (poison, fire, wet) transfigures neighboring stone into matching mineral clusters.

---

## Technical Details (For Modders)
Hooks destroy_tile in tile_map_chunk.gd, querying tile tick states and converting adjacent dirt coordinates to ore IDs.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.