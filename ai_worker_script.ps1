cls

# ==============================================================================
# Coal LLC - Complete Documentation Suite & Repository Showcase Overhaul
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$rootReadme = "$repo\README.md"
$sessionDoc = "$repo\SESSION_PROMPT.md"
$steamMods  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods"

Set-Location $repo

Write-Host ">>> 1. Creating detailed README.md for gareth-tectonic_faultline_mod..." -ForegroundColor Cyan

$tfReadmeContent = @'
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
'@

$tfOuterReadme = "$repo\mods-unpacked\gareth-tectonic_faultline_mod\README.md"
$tfInnerReadme = "$repo\mods-unpacked\gareth-tectonic_faultline_mod\mods-unpacked\gareth-tectonic_faultline_mod\README.md"

Set-Content -Path $tfOuterReadme -Value $tfReadmeContent -Encoding UTF8
if (Test-Path (Split-Path $tfInnerReadme)) {
    Set-Content -Path $tfInnerReadme -Value $tfReadmeContent -Encoding UTF8
}
Write-Host "Created Tectonic Faultline READMEs successfully." -ForegroundColor Green

Write-Host "`n>>> 2. Overhauling root README.md with all 47 mods, graphics, and technical details..." -ForegroundColor Cyan

$rootReadmeContent = @'
# Coal LLC Modding Suite

A complete, high-performance ecosystem of gameplay overhauls, custom subterranean maps, unique character classes, industrial workforce hierarchies, high-tier demolition options, and quality-of-life tools for **[Coal LLC](https://store.steampowered.com/app/3361510/Coal_LLC/)**, built on the **[Godot ModLoader 7.x](https://godotengine.org/asset-library/asset/4107)** hook architecture.

![Tectonic Faultline Preview](mods-unpacked/gareth-tectonic_faultline_mod/assets/tectonic_preview.png)

---

## Complete Mod Directory (47 Mods)

### 1. Custom Maps & Subterranean Overhauls
| Mod | ID | Type | Description |
| :--- | :--- | :--- | :--- |
| **Tectonic Faultline** | `gareth-tectonic_faultline_mod` | Map (ID 102) | Seismic rift featuring vertical chasms, active magma fissures, 3x density elemental pods (Fire, Water, Poison), and an elemental tick rate progression engine. |
| **The Lost Expedition** | `gareth-lost_expedition_mod` | Map (ID 101) | Subterranean cryo-abyss featuring ancient buried shelters, unexploded landmines (UXO), and survival extraction mechanics. |
| **Seismic Hazards** | `gareth-seismic_hazards_mod` | World Gameplay | Simulates ceiling load pressure during aggressive deep excavation, triggering dynamic rock falls and cave-ins if structural pillars are removed. |

### 2. Character Classes & Combat Archetypes
| Mod | ID | Type | Description |
| :--- | :--- | :--- | :--- |
| **Expanded Class Suite** | `gareth-custom_classes_mod` | Class Hub | Master bundle aggregating 9 distinct combat and mining classes into a unified selection interface. |
| **The Knight Class** | `gareth-knight_class_mod` | Melee Class | Wields a colossal broadsword with directional whirlwind cleaves, high kinetic impact, and melee swing speed scaling. |
| **Jedi Class** | `gareth-jedi_class_mod` | Melee Class | Deploys an energy lightsaber capable of deflecting debris, extended cleave reach, and kinetic force pushes. |
| **Chrono-Industrialist**| `gareth-chrono_industrialist_mod` | Temporal Class| Warps localized time fields with the Chrono-Drill, creating temporal stasis zones and accelerated mining tick windows. |
| **Void Siphon** | `gareth-void_siphon_mod` | Exotic Class | Collapses gravitational singularities that pull surrounding minerals and rock into destructive event horizons. |
| **Rainbow Sinclairity**| `gareth-sinclairity_class_mod` | Energy Class | Fires a multi-spectrum prismatic laser that melts through multi-tiered stone layers based on light refraction. |
| **Debt Executioner** | `gareth-debt_executioner_mod` | Economic Class | High-risk, high-bounty class converting mined debt quotas into combat damage multipliers and executioner strike bonuses. |
| **Gravitational Dreadnought** | `gareth-grav_dreadnought_mod` | Heavy Class | Fires high-mass kinetic ordnance that creates crushing localized gravity fields. |
| **The Tectonic Fracker** | `gareth-tectonic_fracker_mod` | Seismic Class | Emits directional acoustic pulse waves along rock faultlines, shattering brittle seams across entire strata. |
| **Bouncing Ball Class**| `gareth-bouncing_ball_mod` | Physics Class | Deploys hyper-elastic kinetic spheres that rebound off walls, pulverizing dense deposits through velocity accumulation. |
| **Martial Legends** | `gareth-martial_legends_mod` | Unarmed Class | Replaces tools with rapid-fire martial arts strikes, scaling punch and roundhouse kick velocities into shockwave bursts. |
| **Water Spirit** | `gareth-water_spirit_mod` | Elemental Class | Manipulates high-pressure hydraulic torrents, priming subterranean walls with continuous wet multipliers. |

### 3. Demolition & Heavy Weaponry
| Mod | ID | Type | Description |
| :--- | :--- | :--- | :--- |
| **Tank Arsenal** | `gareth-tank_arsenal_mod` | Weapons & Shop | Adds 45 tiered Incendiary, Caustic, and Depleted Uranium tanks with tier penetration (+1 to +15 solid blocks), burn DoTs, and chest drops. |
| **Hydrogen Bomb** | `gareth-hydrogen_bomb_mod` | Demolition | Wide-area thermonuclear charge: 80-tile blast radius delivering 999,999 damage for wide cavern clearing. |
| **Neutron Bomb** | `gareth-neutron_bomb_mod` | Demolition | Focused subatomic core: compact 16-tile blast delivering 9,999,999,999 kinetic yield to instantly pulverize obsidian and hard bedrock. |
| **Heavy Demolition Bombs** | `gareth-heavy_bombs_mod` | Explosives | Adds high-yield industrial demolition blocks spanning mid-to-endgame material grades. |
| **Bouncing Grenade Arsenal** | `gareth-grenade_mod` | Projectiles | Casts parabolic rebounding explosives across all 15 material grades (Shoddy to Onyx) that bounce off underground geometry before detonating. |
| **Heavy Automated Turrets** | `gareth-heavy_turrets_mod` | Structures | Autonomous emplacements that provide perimeter fire support and automated point defense in deep shafts. |
| **Mortar Gun Arsenal** | `gareth-more_mortars_mod` | Structures | Tiers 6 through 10 of autonomous artillery delivering 7.5 Million up to 500 Billion damage straight down mine shafts. |
| **High-Yield Auto-Drills**| `gareth-more_drills_mod` | Structures | Tiers 5 through 10 of vertical boring bits delivering 100,000 up to 50 Billion damage at 10 ticks per second. |
| **Tactical Nukes Expansion** | `gareth-more_nukes_mod` | Demolition | Additional atomic payload variants bridging the gap between conventional dynamite and thermonuclear charges. |
| **Plasma Raygun** | `gareth-plasma_raygun_mod` | Mining Utility | Directional continuous thermal cutting beam fired on Right-Click to core out horizontal access corridors. |
| **High-Energy Laser Beam**| `gareth-laser_beam_mod` | Directed Energy | Sustained energy lance that melts linearly through dense rock formations. |
| **End-Game Arsenal** | `gareth-endgame_arsenal_mod` | Magic & Ranged | High-tier Gold, Ruby, Diamond, and Pink Diamond staffs and poison guns designed for deep cavern excavation. |

### 4. Logistics, Automation & Workforce
| Mod | ID | Type | Description |
| :--- | :--- | :--- | :--- |
| **Executive Workforce** | `gareth-more_employees_mod` | Workforce | Adds Executive VP, CMO, Managing Director, and Titan Miner tiers. Features 53% tree scaling, dynamic orthogonal red/green connection lines, and cascading profession locks. |
| **Cosmic Collectors** | `gareth-more_collectors_mod` | Logistics | Adds Vortex, Quantum, Abyssal, and Singularity Collector drones carrying payloads up to 2,500,000 items at 9.0 flight speed. |
| **Vacuum Collector Depot** | `gareth-vacuum_depot_mod` | Logistics | Routes autonomous UFO collectors directly to the vacuum nozzle tip if it is closer than the surface, eliminating surface flight times. |
| **Buyable Vacuums** | `gareth-buyable_vacuums_mod` | Equipment | Makes Tabbitha's vacuum upgrades purchasable on the Bonus shelf and adds Levels 5 to 8 (Abyssal extension reaching 600 tiles). |
| **Vacuum Quests Expansion** | `gareth-more_vacuum_quests_mod` | Quests | Injects expanded side objectives and rewards focused on vacuum automation. |

### 5. Progression, Economy & Upgrades
| Mod | ID | Type | Description |
| :--- | :--- | :--- | :--- |
| **Shift Rock Layers (6-12)**| `gareth-more_layer_shifts_mod` | Progression | Extends bedrock shifts past Shift 5, elevating deep mineral veins closer to the surface with costs up to 750 Sextillion. |
| **More Inventory Slots (4-10)**| `gareth-more_inventory_slots_mod`| Progression | Expands carrying capacity up to +250 slots ($2.5 Quadrillion). |
| **More Inventory Stacks (7-16)**| `gareth-more_inventory_stacks_mod`| Progression | Extends item stack limits past 18 Trillion up to +50 Sextillion items. |
| **Elemental Transmutation** | `gareth-elemental_transmutation_mod` | Economy | Destroys burned blocks for crystallized ore cash bonuses and converts acid-corroded rock into scrap slag bounties. |
| **Elemental Tick Upgrades** | `gareth-tick_upgrade_mod` | Mechanics | Foundational engine accelerating poison and burn damage-over-time tick rates on subterranean strata. |
| **Dual Multipliers** | `gareth-dual_multipliers_mod` | Progression | Expands multiplicative stacking logic across simultaneous score, depth, and loot multipliers. |
| **Weapon Stacker** | `gareth-weapon_stacker_mod` | Mechanics | Scales weapon stats dynamically based on inventory count (minigun fires 40-pellet bursts at 0.01s cooldown; water gun spray radius expands logarithmically). |
| **Excavation Frenzy** | `gareth-excavation_frenzy_mod` | Mechanics | Chains rapid pickaxe strikes into an escalating frenzy combo, multiplying swing speed and drop yields. |

### 6. Tools, UI & System Utilities
| Mod | ID | Type | Description |
| :--- | :--- | :--- | :--- |
| **Mod Manager** | `gareth-mod_manager_mod` | Core Framework | Central mod controller handling custom class passives mapping, perk injection, and runtime weapon whitelists. |
| **Mod Settings System** | `gareth-mod_settings_mod` | Settings UI | Adds a unified "Gareth Mods" settings tab with persistent JSON storage (`user://gareth_mods_config.json`) and tuning sliders. |
| **Auto Passive Chooser** | `nanobotz-autopassivechooser` | Automation UI | Adds a "Passive Order" settings tab to prioritize and auto-select chest perks. Enhanced with full elemental and tick rate perk support. |
| **Career Leaderboard** | `gareth-leaderboard_mod` | Analytics | Persistent career analytics tracking all-time mining records, quotas, and depth milestones in `user://leaderboard_records.json`. |
| **Multi-Save Profile Manager**| `gareth-multisave_mod` | Core Utility | Multi-slot profile manager allowing isolated playthroughs without overwriting vanilla progress. |
| **Prospector's Beacon** | `gareth-prospectors_beacon_mod` | Radar Utility | Emits periodic acoustic pulses to detect and ping high-value ore veins through solid rock. |
| **InfiniPlatform** | `gareth-infini_platform_mod` | Building Utility | Places a horizontal bridging scaffold that expands left and right until hitting solid walls (up to 200 blocks). |

---

## Installation Guide

### Prerequisites
* **Coal LLC** (Steam / PC version)
* **Custom Godot ModLoader (NanobotZ Build)**: Coal LLC requires the hook-packing ModLoader build. Follow the [Installation Setup in Der-Floh's Repo](https://github.com/Der-Floh/coal-llc-mods#installation) to install the loader.

### Release ZIP Installation
1. Download desired mod `.zip` archives from the `mods/` folder.
2. Navigate to your Steam install folder:
    C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\
3. Copy the `.zip` files into the `mods/` directory.
4. **Important on first install or update:** Delete `mod-hooks.zip` from your game folder if present. This ensures hook chains are rebuilt cleanly.
5. Launch the game through Steam.

---

## Core Engine Modding Contracts

For developers writing extensions or custom classes, keep these Godot 4 engine contracts in mind:
* **Sky Code Contract:** `lvl_from_global_pos(pos)` must return `-2` whenever `pos.y < 0`. Returning `0` causes vanilla chunk logic to generate solid Level 0 copper stone in the sky.
* **Tile Cache Sync:** `TileMapChunk` does not use standard Godot 4 `set_cell()`. Custom tile changes require updating `chunk.tiles[idx]` followed immediately by `chunk.build_tile(idx)` to update GPU meshes.
* **Subterranean Vaults:** Multi-tile chamber carving belongs in `generate_chests`, reserving coordinates in `current_block_chest_locations` to prevent vanilla chests from generating inside custom structures.
* **Virtual ZIP Assets:** Textures packaged in `.zip` archives should be loaded as raw bytes using `FileAccess.get_file_as_bytes()` into an `Image` before creating an `ImageTexture`.

---

## Credits & Acknowledgments
* **[Godot ModLoader Team](https://wiki.godotmodding.com/)** for the modding framework.
* **[Der-Floh](https://github.com/Der-Floh/)** for foundational utility mods and hooks architecture.
* **[nanobotz](https://github.com/NanobotZ)** for the original auto-passive chooser architecture.
'@

Set-Content -Path $rootReadme -Value $rootReadmeContent -Encoding UTF8
Write-Host "Updated root README.md successfully." -ForegroundColor Green

Write-Host "`n>>> 3. Verifying and updating SESSION_PROMPT.md..." -ForegroundColor Cyan

$tectonicSection = @'

## 10. Tectonic Faultline (Map ID 102) & Elemental Systems Architecture

### Engine Contracts & Core Generation Rules
- Sky Stratum Code (-2): lvl_from_global_pos(pos) must return -2 whenever pos.y < 0 (tile grid coordinates). Returning 0 causes vanilla Coal LLC to classify the sky as Level 0 rock (HARD_ORANGE copper stone) and paint solid blocks across the clouds.
- Tile Coordinate Systems: Coordinates passed into lvl_from_global_pos(pos) are raw tile row indices (y < 0 for sky, y >= 0 for underground), not pixel values.
- Tile Cache & GPU Synchronization (build_tile): TileMapChunk does not update rendered blocks through standard Godot 4 set_cell() calls. Modifying rock layers or carving chambers requires setting chunk.tiles[c_idx] = target_tile followed immediately by chunk.build_tile(c_idx) to update the GPU render mesh and block metadata.
- Subterranean Vault Hooking (generate_chests): Multi-block chambers and pod vaults must be hooked in generate_chests(chain, current_block_chest_locations) rather than generate_chunk. This guarantees strata generation has completed and allows appending vault coordinates to current_block_chest_locations to prevent vanilla chests from spawning inside.
- ModLoader Virtual Zip Asset Loading: Texture files packaged inside .zip archives cannot be reliably loaded using ResourceLoader.load(). Custom card previews and entity sprites must be loaded as raw bytes via FileAccess.get_file_as_bytes() into an Image, then converted via ImageTexture.create_from_image(), or drawn procedurally onto an ImageTexture.

### Elemental Pods (MagmaSiphon.gd)
- Visual Color Modulation:
  - Magma (Fire): Modulated crimson red Color(1.4, 0.2, 0.2) with fiery ember particles and expanding blast rings.
  - Hydro Geyser (Water): Modulated electric azure Color(0.2, 0.55, 1.4) with blue spray droplets.
  - Toxic Acid (Poison): Modulated neon emerald Color(0.25, 1.3, 0.25) with corrosive drip cascades.
- Triple Spawn Density (3x): spawn_magma_siphons() attempts three non-overlapping vault placements per subterranean chunk using a 1-tile clearance check against current_block_chest_locations.
- Interaction Contracts:
  - [E] Vent: Geyser updraft velocity (y = -700 to -950), scaled cash bounty, multi-wave fluid cascade, and Bus.choose_passive trigger.
  - Left-Click Rupture: High-radius core explosion, wider fluid splatter, and massive damage to surrounding strata.

### Passive Chooser & Chest Loot Injection
- Vanilla Inventory Gating: In choose_passive.gd, c1 and c2 cards pull strictly from choice_options (built only from equipped weapon types in PlayerInventory.tres), while c3 is locked to mobility stats. When holding a pickaxe, elemental damage perks are excluded and never roll.
- Map 102 Injection: In gareth-mod_manager_mod/extensions/scenes/Interfaces/in_game/choose_passive.hooks.gd, when Gvars.level == 102, fire_damage, wet_damage, poison_damage, and elemental_tick_rate are injected directly into choice_options so bonus chests present elemental cards without requiring elemental weapons. Standard maps remain untouched.
- Built-in Vanilla Multipliers:
  - fire_damage (+5%): Directly scales burn DPS (tile_map_chunk.gd:2428).
  - poison_damage (+5%): Directly scales poison DPS (tile_map_chunk.gd:2378).
  - wet_damage (+1%): Multiplies all damage to saturated blocks by 2 * (1 + wet_damage) (tile_map_chunk.gd:2246).
- Elemental Tick Rate Acceleration: Vanilla tick intervals are fixed (POISON_TICK_LENGTH = 6, BURN_TICK_LENGTH = 7). In tile_map_chunk.hooks.gd, apply_tile_effects accumulates fractional bonuses from elemental_tick_rate to trigger extra calls to poisons_loop() and burns_loop(), accelerating damage-over-time block melting.

### nanobotz-autopassivechooser Integration
- Settings UI Discovery: passive_order.gd:get_possible_passives_for_professions() queries _profession_effect() per class. Non-elemental classes (like Internship) omit elemental perks from the UI list.
- UI Patch: Appending fire_damage, wet_damage, poison_damage, and elemental_tick_rate to get_possible_passives_for_professions() ensures they appear in Settings -> Passive Order with limit inputs and priority controls for all professions.
- In-Game Auto-Pick Contract: In choose_passive.hooks.gd, the auto-picker checks passive.get("enabled", false) and evaluates stat caps across both Gvars.passives and Gvars.custom_passives to prevent null-reference runtime exceptions.
'@

$sessionContent = Get-Content -Path $sessionDoc -Raw
if ($sessionContent -match "## 10\. Tectonic Faultline") {
    $pattern = "(?s)## 10\. Tectonic Faultline.*?(?=\r?\n## |\Z)"
    $updatedSession = $sessionContent -replace $pattern, $tectonicSection.Trim()
    Set-Content -Path $sessionDoc -Value $updatedSession -Encoding UTF8
    Write-Host "Updated Tectonic Faultline section in SESSION_PROMPT.md" -ForegroundColor Green
} else {
    Add-Content -Path $sessionDoc -Value $tectonicSection -Encoding UTF8
    Write-Host "Appended Tectonic Faultline section to SESSION_PROMPT.md" -ForegroundColor Green
}

Write-Host "`n>>> 4. Repackaging gareth-tectonic_faultline_mod.zip with updated README..." -ForegroundColor Cyan
$tfOuterDir = "$repo\mods-unpacked\gareth-tectonic_faultline_mod"
$tfZipPath  = "$steamMods\gareth-tectonic_faultline_mod.zip"
if (Test-Path $tfZipPath) { Remove-Item -Path $tfZipPath -Force }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$stream  = [System.IO.File]::Open($tfZipPath, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $tfOuterDir -Recurse -File)) {$entryName = $f.FullName.Substring($tfOuterDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "Repacked: $tfZipPath" -ForegroundColor Green

Write-Host "`n>>> 5. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Comprehensive documentation overhaul: 47-mod master README, Tectonic Faultline documentation, and SESSION_PROMPT update"
git push origin main

Write-Host "`nAll documentation and repo files are synchronized and pushed to GitHub!" -ForegroundColor Green