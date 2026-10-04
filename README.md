# Coal LLC Mod Suite

A collection of gameplay enhancements, dynamic weapon scaling, excavation mechanics, and environmental hazard mods for **[Coal LLC](https://store.steampowered.com/app/3361510/Coal_LLC/)**, built for the **[Godot ModLoader 7.x](https://godotengine.org/asset-library/asset/4107)** framework.

---

## Included Mods

| Mod | Namespace / ID | Type | Description | Dependencies |
| :--- | :--- | :--- | :--- | :--- |
| **Tank Arsenal** | `gareth-tank_arsenal_mod` | Weapons & Shop | Adds 45 tiered Incendiary, Caustic, and Depleted Uranium tanks with tier penetration and dynamic passive scaling. | None |
| **Hydrogen Bomb** | `gareth-hydrogen_bomb_mod` | Explosives | Thermonuclear charge: massive 80-tile radius dealing 999,999 blast damage for broad cavern excavation. | None |
| **Neutron Bomb** | `gareth-neutron_bomb_mod` | Explosives | Subatomic core: compact 16-tile blast dealing 9,999,999,999 kinetic yield to instantly pulverize obsidian and hard bedrock. | None |
| **More Layer Shifts** | `gareth-more_layer_shifts_mod` | Shop / Progression | Adds Shift Rock Layers Tiers 6 to 12 (750B to 750Sx), shifting deep high-tier mineral veins progressively into reachable mining depths. | None |
| **More Inventory Slots** | `gareth-more_inventory_slots_mod` | Shop / Progression | Adds Tiers 4 through 10 of inventory slot expansions (+20 to +250 slots) scaling up to 2.5 Quadrillion. | None |
| **More Inventory Stacks**| `gareth-more_inventory_stacks_mod`| Shop / Progression | Adds Tiers 7 through 16 of inventory stack expansions (+25B to +50Sx items) scaling past 18 Trillion up to 50 Septillion. | None |
| **Buyable Vacuums** | `gareth-buyable_vacuums_mod` | Utility & Quests | Makes Tabbitha's vacuum upgrades directly purchasable in the shop alongside quests, and extends tether reach with Levels 5 to 8 (up to 600 tiles). | None |
| **Mortar Gun Arsenal** | `gareth-more_mortars_mod` | Weapons & Structures| Adds Tiers 6 through 10 of deployable Mortar Guns with damage scaling from 7.5 Million up to 500 Billion. | None |
| **High-Yield Drills** | `gareth-more_drills_mod` | Weapons & Structures| Adds Tiers 5 through 10 of auto-drills with damage scaling from 100,000 up to 50 Billion. | None |
| **InfiniPlatform** | `gareth-infini_platform_mod` | Utility & Structures| Deploys a horizontal bridge left and right across open gaps until colliding with solid walls (maximum 200 blocks). | None |
| **Weapon Stacker** | `gareth-weapon_stacker_mod` | Combat & Scaling | Scales weapon stats dynamically based on inventory stack count (minigun fire rate/pellet density, water gun spray radius). | None |
| **Elemental Transmutation** | `gareth-elemental_transmutation_mod` | Economy | Destroys burned and corroded tiles for crystallized ore bonuses and slag cash bounties. | None |
| **Excavation Frenzy** | `gareth-excavation_frenzy_mod` | Mining | Chains rapid mining strikes into progressive swing speed and drop multipliers. | `der_floh-pickaxeaoe_mod` |
| **Plasma Raygun** | `gareth-plasma_raygun_mod` | Weapons | High-energy directional plasma cutting beam fired via Right-Click. | None |
| **Prospector's Beacon** | `gareth-prospectors_beacon_mod` | Utility | Emits periodic acoustic pulses to detect and ping high-value ore veins through solid rock. | None |
| **Seismic Hazards** | `gareth-seismic_hazards_mod` | World Gameplay | Introduces dynamic ceiling cave-ins and falling rubble triggered by heavy excavation. | None |

---

## Installation

### Prerequisites
* **Coal LLC** (Steam / PC version)
* **Custom Godot ModLoader (NanobotZ Build)**: Coal LLC requires the custom hook-packing build of ModLoader rather than the generic upstream version. Follow the [Installation Setup in Der-Floh's Repo](https://github.com/Der-Floh/coal-llc-mods#installation) to install the patched loader.

### Quick Install (ZIP Packages)
1. Download the desired `.zip` files from the [mods](https://github.com/garethwhite-prog/coal-llc-mods/tree/main/mods) directory in this repository.
2. Navigate to your Coal LLC install directory:
   ```text
   C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\
   ```
3. Copy the downloaded `.zip` file(s) into the `mods/` folder:
   ```text
   Coal LLC/mods/gareth-weapon_stacker_mod.zip
   ```
4. **Important (First run / Updates):** Delete `mod-hooks.zip` from your game root folder if it exists. This forces `ModHookPacker` to re-inject hook chains into decompiled base scripts.
5. Launch the game through Steam.

### Developer / Unpacked Install
If you wish to edit scripts or inspect GDScript code directly:
1. Copy the mod folder from `mods-unpacked/` into:
   ```text
   Coal LLC/mods-unpacked/gareth-<mod_name>/
   ```
2. Verify that `manifest.json` and `mod_main.gd` sit directly inside `Coal LLC/mods-unpacked/gareth-<mod_name>/`.

---

## Mod Overviews & Mechanics[cite: 1]

### 1. Tank Arsenal Mod (`gareth-tank_arsenal_mod`)
Expands the **Tanker** profession and equipment shop with **45 new purchasable weapons** spanning all 15 material tiers (Shoddy to Onyx), neatly interleaved alongside vanilla tanks in the shop catalogue:
* **Incendiary Tanks (Tiers 1–15):** High-explosive shells detonating in an expansive blast that sets all tiles within its Manhattan radius ablaze for 6 burn ticks. Direct impact damage scales with `tank_damage`; burning tick damage scales dynamically with `fire_damage`. Synergizes directly with `gareth-elemental_transmutation_mod` for cash bounty rewards.
* **Caustic Tanks (Tiers 1–15):** Chemical mortar rounds bursting into toxic acid pools that dissolve rock. Direct blast damage scales with `tank_damage`; corrosive tick damage scales dynamically with `poison_damage`.
* **Depleted Uranium Tanks (Tiers 1–15):** Dense kinetic penetrators that drill through rock formations before detonating deep inside mineral pockets. Features **dynamic tier penetration**, piercing through **+1 solid block per tier** (1 block at Shoddy up to **15 solid blocks at Onyx**).
* **Chest Loot Drop Expansion:** Hooks `_profession_effect` in `tanker.gd` to inject `fire_damage` and `poison_damage` into chest rolls during Tanker runs (vanilla hardcoded whitelist normally excludes elemental scrolls).
* **Attack Speed Scaling:** All three archetypes scale attack cooldowns natively via `cooldown_time / (1 + Gvars.passives.tank_firing_rate)`.

### 2. Hydrogen Bomb Mod (`gareth-hydrogen_bomb_mod`)
Cloned from the tactical nuke archetype and engineered specifically for wide-area subterranean excavation:
* **Blast Profile:** Massive **80-tile blast radius** ($2\times$ the Tactical Nuke's radius) delivering **999,999 blast damage**.
* **Excavation Role:** Excavates colossal underground chambers through soil, clay, and standard stone in a single detonation without instantly vaporizing deepest bedrock boundaries.
* **Shop Integration:** Inserted into the equipment shop immediately adjacent to the Tactical Nuke for $3,000,000.

### 3. Neutron Bomb Mod (`gareth-neutron_bomb_mod`)
Engineered for concentrated, high-yield kinetic penetration:
* **Blast Profile:** Tight, focused **16-tile core radius** delivering **9,999,999,999 kinetic damage**.
* **Excavation Role:** Shatters high-density late-game ore formations, dense obsidian clusters, and deep bedrock barriers instantly without tearing open cavern ceilings or disrupting shaft architecture.
* **Shop Integration:** Inserted into the equipment shop directly adjacent to the Hydrogen Bomb for $10,000,000.

### 4. More Layer Shifts Mod (`gareth-more_layer_shifts_mod`)
Expands the rock layer elevation mechanic beyond the vanilla limit of 5:
* **Tiers 6 to 12:** Injects `shift_layers_6.tres` through `shift_layers_12.tres` sequentially into the Bonus Upgrades shop, positioned directly after Shift 5.
* **Native Terrain Integration:** Passes values straight into `tile_map_chunk.gd`'s `adjust_level_bonus()`, progressively shifting high-tier mineral veins, gems, and deep bedrock strata closer to the surface.
* **Cost Progression:** Exponential pricing curve scaling past early progression milestones:
  * Tier 6: $750,000,000,000 (750 Billion)
  * Tier 7: $75,000,000,000,000 (75 Trillion)
  * Tier 8: $7,500,000,000,000,000 (7.5 Quadrillion)
  * Tier 9: $750,000,000,000,000,000 (750 Quadrillion)
  * Tiers 10–12: Progressing through Quintillion and Sextillion thresholds.

### 5. More Inventory Slots Mod (`gareth-more_inventory_slots_mod`)
Extends hotbar and bag inventory slot expansions beyond the vanilla Tier 3 cap:
* **Tiers 4 to 10:** Injected directly after Slot 3 in the Bonus Upgrades shop shelf.
* **Exponential Slot Yield:** Slot bonuses scale progressively rather than remaining flat:
  * Tier 4: +20 Slots ($500,000)
  * Tier 5: +35 Slots ($15,000,000)
  * Tier 6: +50 Slots ($500,000,000)
  * Tier 7: +75 Slots ($25,000,000,000)
  * Tier 8: +100 Slots ($1,000,000,000,000)
  * Tier 9: +150 Slots ($50,000,000,000,000)
  * Tier 10: +250 Slots ($2,500,000,000,000,000)

### 6. More Inventory Stacks Mod (`gareth-more_inventory_stacks_mod`)
Pushes inventory carrying capacity past the vanilla Tier 6 cap ($18\text{ Trillion}$):
* **Tiers 7 to 16:** Injected directly after Stack 6 in the Bonus Upgrades shop shelf.
* **Exponential Stack Scaling:** Capacity expands into high orders of magnitude to support late-game automation runs:
  * Tier 7: +25,000,000,000 items ($75 Trillion)
  * Tier 8: +500,000,000,000 items ($500 Trillion)
  * Tier 9: +10,000,000,000,000 items ($5 Quadrillion)
  * Tier 10: +250,000,000,000,000 items ($75 Quadrillion)
  * Tiers 11–16: Progresses through Quintillion, Sextillion, and Septillion item capacities.

### 7. Buyable Vacuums Mod (`gareth-buyable_vacuums_mod`)
Expands the pneumatic stockpile suction system with shop availability and extended reaches:
* **Dual Acquisition:** Unlocks vanilla Vacuum Cleaners 1 to 4 to be purchased directly from the Bonus Upgrades shelf with cash while keeping them earnable via Tabbitha's questline.
* **Levels 5 to 8 Extensions:** Hooks `equipment_manager.gd` to instantiate high-tensile vacuum tether lines that reach deep mine layers:
  * Level 5 (Uranium): 220 tiles ($150,000,000)
  * Level 6 (Moonstone): 300 tiles ($1,500,000,000)
  * Level 7 (Onyx): 420 tiles ($20,000,000,000)
  * Level 8 (Abyssal): 600 tiles ($300,000,000,000)

### 8. Mortar Gun Arsenal (`gareth-more_mortars_mod`)
Deploys autonomous artillery structures that bombard mine shafts directly beneath them:
* **Tiers 6 to 10:** Injected into the equipment shop immediately after Mortar Gun 5 (`mortar_gun_05`).
* **Damage Progression:** High-frequency 1 shot/second artillery scaling:
  * Tier 6 (Mega): 7,500,000 Damage ($250M)
  * Tier 7 (Colossal): 100,000,000 Damage ($3.5B)
  * Tier 8 (Titan): 1,500,000,000 Damage ($50B)
  * Tier 9 (Planetary): 25,000,000,000 Damage ($1T)
  * Tier 10 (Godly): 500,000,000,000 Damage ($25T)

### 9. High-Yield Drills (`gareth-more_drills_mod`)
Expands deployable continuous boring machinery for deep vertical shaft sinking:
* **Tiers 5 to 10:** Injected into the equipment shop immediately following Drill 4 (`drill_04`).
* **Rapid Mining Output:** Ticks continuous downward excavation damage 10 times per second:
  * Tier 5 (Industrial): 100,000 Damage ($3M)
  * Tier 6 (Excavator): 1,200,000 Damage ($35M)
  * Tier 7 (Bedrock): 15,000,000 Damage ($500M)
  * Tier 8 (Magma): 200,000,000 Damage ($8B)
  * Tier 9 (Mantle): 3,000,000,000 Damage ($150B)
  * Tier 10 (Core): 50,000,000,000 Damage ($3T)

### 10. InfiniPlatform Mod (`gareth-infini_platform_mod`)
The horizontal bridging equivalent of the vertical `InfiniLadder`:
* **Horizontal Bridging:** Placing an InfiniPlatform triggers dual expansion rays that cast left (`-X`) and right (`+X`) along the horizontal plane simultaneously.
* **Collision Detection:** Automatically places `TileMapChunk.Tiles.PLATFORM` until both ends collide with solid walls, reach ungenerated chunks, or hit the built-in safety limit of **200 blocks**.
* **Placement Preview:** Uses the game's native cursor snap placer for accurate alignment across shafts.

### 11. Weapon Stacker Mod (`gareth-weapon_stacker_mod`)[cite: 1]
Dynamically hooks into `gun.gd` and `water_gun.gd` during runtime physics frames, checking the player's active inventory count for the equipped weapon resource:[cite: 1]
* **Minigun Stacking:** Multiplies fire rate by shrinking cooldown delays down to 0.01s (up to ~60 bursts/second), scales projectile counts up to a dense 40-pellet wall of lead per burst, and incorporates forward speed trajectory compensation to prevent high-density volleys from inverting velocity.[cite: 1]
* **Water Gun Stacking:** Expands spray radius logarithmically with stack count, enabling single-burst soaking of entire mine shafts to prime blocks for double wet damage.[cite: 1]

### 12. Elemental Transmutation Mod (`gareth-elemental_transmutation_mod`)[cite: 1]
Hooks block destruction events in `tile_map_chunk.gd`:[cite: 1]
* **Burned Blocks:** Breaking tiles currently afflicted by fire triggers a thermal crystallization event, yielding bonus currency payouts directly to cash reserves.[cite: 1]
* **Corroded Blocks:** Breaking acid-affected blocks converts them to slag, granting immediate scrap bounty rewards.[cite: 1]

### 13. Excavation Frenzy Mod (`gareth-excavation_frenzy_mod`)[cite: 1]
* Synergizes with area-of-effect pickaxe hooks.[cite: 1]
* Maintaining rapid strike cadence increases your frenzy meter, ramping up swing speeds and drop quantities until mining halts.[cite: 1]

### 14. Plasma Raygun Mod (`gareth-plasma_raygun_mod`)[cite: 1]
* Equips your miner with a focused thermal cutting beam.[cite: 1]
* Hold **Right-Click** while wielding mining gear to punch clean corridors through high-density rock formations.[cite: 1]

### 15. Prospector's Beacon Mod (`gareth-prospectors_beacon_mod`)[cite: 1]
* Periodically casts sub-surface sonar sweeps centered on the player.[cite: 1]
* Detects hidden veins through solid rock and displays acoustic ping coordinates in both the game world and telemetry logs.[cite: 1]

### 16. Seismic Hazards Mod (`gareth-seismic_hazards_mod`)[cite: 1]
* Simulates ceiling load pressure.[cite: 1]
* Aggressive mining in deep shafts without leaving supporting columns risks structural failure, causing unstable ceiling tiles to collapse downward.[cite: 1]
---

## Troubleshooting

### Mod Hooks Not Generating / Weapons Behaving Like Vanilla
If you have installed or updated a hook-based mod (such as `gareth-weapon_stacker_mod`) and stats do not scale:
1. Close **Coal LLC**.
2. Delete the stale cache files:
   * `<Game Directory>\mod-hooks.zip`
   * `<Game Directory>\addons\mod_loader\decomp\inject.zip`
3. Relaunch the game. Look for `INFO ModLoader:ModHookPacker: Generating mod hooks .zip` in `modloader.log`.

### Checking Telemetry & Logs
All mods output diagnostic and registration details to:
```text
C:\Users\<YourUser>\AppData\Roaming\Godot\app_userdata\Coal LLC\logs\godot.log
```
and
```text
<Game Directory>\modloader.log
```

---

## Repository Structure

```text
coal-llc-mods/
├── mods/                                # Pre-packaged release ZIP archives
│   ├── gareth-buyable_vacuums_mod.zip
│   ├── gareth-elemental_transmutation_mod.zip
│   ├── gareth-excavation_frenzy_mod.zip
│   ├── gareth-hydrogen_bomb_mod.zip
│   ├── gareth-infini_platform_mod.zip
│   ├── gareth-more_drills_mod.zip
│   ├── gareth-more_layer_shifts_mod.zip
│   ├── gareth-more_inventory_slots_mod.zip
│   ├── gareth-more_inventory_stacks_mod.zip
│   ├── gareth-more_mortars_mod.zip
│   ├── gareth-neutron_bomb_mod.zip
│   ├── gareth-plasma_raygun_mod.zip
│   ├── gareth-prospectors_beacon_mod.zip
│   ├── gareth-seismic_hazards_mod.zip
│   ├── gareth-tank_arsenal_mod.zip
│   └── gareth-weapon_stacker_mod.zip
├── mods-unpacked/                       # Raw source GDScript files
│   ├── gareth-buyable_vacuums_mod/
│   ├── gareth-elemental_transmutation_mod/
│   ├── gareth-excavation_frenzy_mod/
│   ├── gareth-hydrogen_bomb_mod/
│   ├── gareth-infini_platform_mod/
│   ├── gareth-more_drills_mod/
│   ├── gareth-more_layer_shifts_mod/
│   ├── gareth-more_inventory_slots_mod/
│   ├── gareth-more_inventory_stacks_mod/
│   ├── gareth-more_mortars_mod/
│   ├── gareth-neutron_bomb_mod/
│   ├── gareth-plasma_raygun_mod/
│   ├── gareth-prospectors_beacon_mod/
│   ├── gareth-seismic_hazards_mod/
│   ├── gareth-tank_arsenal_mod/
│   └── gareth-weapon_stacker_mod/
└── README.md
```

---

## Credits & Acknowledgments
* **[Godot ModLoader Team](https://wiki.godotmodding.com/)** for the modding framework.
* **[Der-Floh](https://github.com/Der-Floh/)** for foundational utility mods and hooks architecture.
* **[nanobotz](https://github.com/NanobotZ)** for the auto-passive chooser implementation.
