# Elemental Transmutation

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Destroying tiles afflicted with elemental effects triggers economic bounties: burning tiles trigger thermal crystallization for cash bonuses, while corroded acid tiles yield scrap bounties.

---

## Technical Details (For Modders)
Hooks destroy_tile in tile_map_chunk.gd to check active fire and poison ticks, granting currency bonuses directly to player reserves.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.