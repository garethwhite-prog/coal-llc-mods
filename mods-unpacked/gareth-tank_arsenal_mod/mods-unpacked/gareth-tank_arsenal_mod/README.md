# 45-Tier Tank Arsenal

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
The **Tank Arsenal Mod** significantly broadens the Tanker profession by introducing 45 new purchasable combat tanks into the equipment shop across all 15 material tiers (Shoddy through Onyx). Tanks are interleaved cleanly alongside vanilla models.

The arsenal features three distinct projectile variants:
* **Incendiary Tanks (Tiers 1–15):** High-explosive shells that set every block within their Manhattan blast radius ablaze with 6 burn ticks. Synergizes with Elemental Transmutation for bonus cash bounties.
* **Caustic Tanks (Tiers 1–15):** Chemical mortar rounds that release dense toxic acid clouds, melting through organic and clay deposits.
* **Depleted Uranium Tanks (Tiers 1–15):** Kinetic armor-piercing rounds featuring dynamic tier penetration, punching through +1 solid stone block per material grade (up to 15 solid blocks at Onyx).

Elemental scrolls are also injected into Tanker chest loot tables, with tank fire rates scaling dynamically with passives.

---

## Technical Details (For Modders)
Hooks tanker.gd and management_screen.gd to dynamically inject and tier-sort tank equipment cards into the shop. Modifies bullet collision logic in tank_bullet.gd to implement multi-block piercing.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.