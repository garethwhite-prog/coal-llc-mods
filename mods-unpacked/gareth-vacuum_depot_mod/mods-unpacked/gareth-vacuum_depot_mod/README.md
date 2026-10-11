# Subterranean Vacuum Collector Depot

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Allows Collector UFO drones to offload minerals directly into subterranean vacuum nozzles when closer than the surface, eliminating round-trip flight times.

---

## Technical Details (For Modders)
Hooks LootCollectorUFO.gd _physics_process to route drone pathfinding toward the nearest active vacuum nozzle.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.