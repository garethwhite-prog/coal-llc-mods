# Tectonic Faultline Map (`gareth-tectonic_faultline_mod`)

![Tectonic Faultline Preview](assets/tectonic_preview.png)

**Author:** Gareth White  
**Map ID:** `102`  
**Difficulty:** Hard  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
**Tectonic Faultline** plunges your miner into a violent subterranean rift characterized by exposed magma fissures, superheated steam vents, and fortified elemental vaults. The map introduces dynamic vertical chasm sculpting, three color-coded elemental pod variants (Fire, Water, Poison), and tight integration with the game's passive progression and auto-chooser systems.

---

## Key Features & Mechanics

### 1. Volatile Elemental Pods (`MagmaSiphon.gd`)
Subterranean chunks spawn reinforced elemental vaults housing high-pressure geysers and pods. Pods spawn at **triple density (3x)** across subterranean strata, featuring distinct visual and mechanical identities:

* **Magma Siphons (Crimson Red):** Superheated volcanic cores. Vents trigger violent thermal fire cascades setting surrounding rock ablaze, while ruptures detonate a massive kinetic shockwave.
* **Hydro Geysers (Electric Azure):** High-pressure subterranean springs. Vents launch the player high into the air with **-950 updraft velocity** and saturate adjacent rock with wet status for **2x damage vulnerability**.
* **Acid Vents (Toxic Green):** Corrosive chemical chambers. Vents release caustic clouds that seep downward through gravity drips, poisoning rock layers and breaking down dense minerals.

### 2. Dual Interaction System
* **Controlled Venting (`[E]`):** Safely vents geothermal pressure. Catapults the miner skyward, pays out a scaled cash bounty (amplified by mine depth, chest multipliers, and run passives), triggers a multi-wave fluid cascade, and rolls a bonus perk selection (`Bus.choose_passive`).
* **Volatile Rupture (Left-Click):** Deliberately breaches the containment casing. Triggers a wide-radius seismic explosion dealing catastrophic kinetic damage to surrounding rock strata and spawning high-density coal drops.

### 3. Subterranean Vault Generation
* Pods spawn inside fortified 3x3 chambers carved into deep rock layers.
* Chambers are enclosed by reinforced perimeter walls (+2 tiers harder than the surrounding stratum).
* Multi-block chamber coordinates are registered in `generate_chests` to prevent vanilla loot chests from overlapping the rooms.

### 4. Elemental Perks & Auto-Chooser Integration
* **Bonus Chest Card Injection:** On Map 102, **Increase Fire Damage (+5%)**, **Increase Wet Damage (+1%)**, **Increase Poison Damage (+5%)**, and **Increase Elemental Tick Rate (+10%)** are injected directly into vanilla bonus chests and card selections without requiring specific elemental weapons equipped.
* **Elemental Tick Acceleration:** Incorporates a dynamic tick engine that accelerates `burns_loop()` and `poisons_loop()`, causing ignited and poisoned rock to dissolve at high speeds.
* **Nanobotz Auto-Passive Chooser Support:** Fully compatible with `nanobotz-autopassivechooser`. Configurable via **Settings -> Passive Order** with custom priority sorting, stat caps, and auto-pick execution.

---

## Technical Specifications & Engine Contracts

| Architecture Area | Implementation Detail |
| :--- | :--- |
| **Sky Air Contract** | `lvl_from_global_pos(pos)` returns `-2` when `pos.y < 0` to preserve clear skies without solid rock overhead. |
| **GPU Sync Contract** | Vault carving executes `chunk.tiles[idx] = tile` followed by `chunk.build_tile(idx)` to force GPU render updates. |
| **Asset Loading** | Preview cards and entity textures load via raw byte buffers (`FileAccess.get_file_as_bytes()`) to bypass virtual `.zip` path limitations. |
| **Tick Hook** | Injects an accumulator loop inside `tile_map_chunk.hooks.gd:apply_tile_effects` to run extra tick cycles based on `elemental_tick_rate`. |

---

## Installation
1. Ensure the custom hook-packing Godot ModLoader build is installed.
2. Place `gareth-tectonic_faultline_mod.zip` into your `Coal LLC/mods/` directory.
3. Launch the game, navigate to the map selection terminal, and select **Tectonic Faultline**.
