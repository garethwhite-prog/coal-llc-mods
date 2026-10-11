# Thermonuclear Hydrogen Bomb Arsenal

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
Engineered specifically for broad subterranean excavation, the **Hydrogen Bomb** delivers massive wide-area clearing power. With a detonation blast radius of **80 tiles** (double the Tactical Nuke), a single charge clears enormous cavern sections.

The warhead delivers **999,999 blast damage**, vaporizing dirt, clay, and hard stone deposits instantly. It appears on the equipment shelf adjacent to the Tactical Nuke for ,000,000.

---

## Technical Details (For Modders)
Registers HydrogenBombItem into item_unlocks.tres and hooks Bus.BombExplode with an 80.0 tile blast radius and custom damage scaling.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.