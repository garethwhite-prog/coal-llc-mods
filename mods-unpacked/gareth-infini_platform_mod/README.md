# Infini-Platform Dual Cross-Bridge

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
The horizontal and vertical bridging equivalent of the InfiniLadder. Deploying an InfiniPlatform triggers simultaneous 4-way expansion rays:
* **Horizontal:** Lays platforms wall-to-wall across open caverns.
* **Vertical:** Extends ladders floor-to-ceiling.
* **Intersection:** Installs a climbable platform-ladder at the origin.

---

## Technical Details (For Modders)
Spawns InfiniPlatformSpawner, which runs 4-way incremental tile generation across local_to_map coordinates until striking solid collision boundaries.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.