# Executive Workforce Hierarchy

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
The **Executive Workforce Hierarchy** expands the autonomous Miner workforce line past Senior VP Miner with four high-yield corporate tiers:
* **Executive VP Miner (Level 24):** Mining Speed 2.4, Ruby Pickaxe (,500,000).
* **Chief Mining Officer (Level 25):** Mining Speed 3.5, Pink Diamond Pickaxe (,000,000).
* **Managing Director Miner (Level 26):** Mining Speed 5.0, Moonstone Pickaxe (,000,000).
* **Titan Miner (Level 27):** Mining Speed 7.5, Onyx Pickaxe (,000,000,000).

The mod applies a 53% uncoupled scale to the organisation board ( = 350, Y = 80$), keeping all employee ranks clearly interactable above the grass line. Locked or disallowed parent branches automatically cascade their restrictions upward, preventing orphaned icons across the board.

Dynamic orthogonal connection lines are rendered using a custom _draw() hook, displaying clean red and green routing across all workforce branches.

---

## Technical Details (For Modders)
Hooks organisation_chart_2.gd _ready, refresh_all_icons, and _draw to inject custom rows and connection vectors. Patches employee_manager.gd to register levels 24-27.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.