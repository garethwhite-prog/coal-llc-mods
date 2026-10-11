# The Knight Class

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
The **Knight Class** introduces a dedicated melee combat archetype to *Coal LLC*. Eschewing traditional pickaxes, the Knight begins their subterranean career wielding a heavy Shoddy Broadsword designed to cleave through stone, clay, and mineral veins in a single sweeping arc.

Attacking with the sword executes a 180-degree frontal sweep that delivers high kinetic impact across all blocks within reach. Damage scales with player passive upgrades and progresses through 11 material grades from Copper up to Pink Diamond.

In the management equipment shop, the Knight is strictly restricted to blade weaponry and basic traversal utilities (such as ladders and ore filters), keeping the class focused on melee combat.

---

## Technical Details (For Modders)
Instantiates KnightSwordEquipEffect hooked into player.pointer_global_pos. Dispatches rotational raycasts through player.tilemap with native SwordThud.wav audio. Injects 11 tiered sword resources into item_unlocks.tres.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.