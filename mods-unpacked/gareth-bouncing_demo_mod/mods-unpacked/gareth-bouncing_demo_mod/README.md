# Bouncing Demolitionist Class

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Explosives specialist equipped with kinetic bouncing bombs that rebound off solid walls multiple times before detonating.

---

## Technical Details (For Modders)
Hooks RigidBody2D physics integration to calculate angle of incidence reflection on tilemap collisions, triggering Bus.BombExplode on the third rebound.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.