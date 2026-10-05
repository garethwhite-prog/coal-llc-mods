# Coal LLC Mod Suite

A high-performance collection of gameplay overhauls, workforce hierarchy expansions, in-game configuration systems, dynamic weapon scaling, excavation utilities, and high-tier progression additions for **[Coal LLC](https://store.steampowered.com/app/3361510/Coal_LLC/)**, built on the **[Godot ModLoader 7.x](https://godotengine.org/asset-library/asset/4107)** framework.

---

## Included Mods (20 Mods)

| Mod | Namespace / ID | Type | Description | Dependencies |
| :--- | :--- | :--- | :--- | :--- |
| **Mod Settings System** | `gareth-mod_settings_mod` | UI & Config | Adds a unified "Gareth Mods" settings tab in-game with toggle switches and tuning sliders backed by persistent JSON storage. | None |
| **Executive Employees** | `gareth-more_employees_mod` | Workforce | Adds 4 executive Miner tiers (up to Titan Miner) with pickaxe scaling, dynamic promotion lines, and cascading profession locks. | `gareth-mod_settings_mod` |
| **Cosmic Collectors** | `gareth-more_collectors_mod` | Workforce | Adds 4 high-tier Collector drones (Vortex, Quantum, Abyssal, Singularity) scaling flight speed and carrying payload up to 2.5M items. | `gareth-mod_settings_mod` |
| **Tank Arsenal** | `gareth-tank_arsenal_mod` | Weapons & Shop | Adds 45 tiered Incendiary, Caustic, and Depleted Uranium tanks with tier penetration, dynamic passives, and chest drops. | None |
| **Hydrogen Bomb** | `gareth-hydrogen_bomb_mod` | Explosives | Thermonuclear charge: massive 80-tile radius dealing 999,999 blast damage for broad cavern excavation. | None |
| **Neutron Bomb** | `gareth-neutron_bomb_mod` | Explosives | Subatomic core: compact 16-tile blast dealing 9,999,999,999 kinetic yield to instantly pulverize obsidian and hard bedrock. | None |
| **More Layer Shifts** | `gareth-more_layer_shifts_mod` | Shop / Progression | Adds Shift Rock Layers Tiers 6 to 12 (750B to 750Sx), elevating deep high-tier mineral veins directly into reachable mining depths. | None |
| **More Inventory Slots** | `gareth-more_inventory_slots_mod` | Shop / Progression | Adds Tiers 4 through 10 of inventory expansions (+20 to +250 slots) scaling costs from 500k up to 2.5 Quadrillion. | None |
| **More Inventory Stacks**| `gareth-more_inventory_stacks_mod`| Shop / Progression | Adds Tiers 7 through 16 of stack upgrades (+25B to +50Sx items) scaling past 18 Trillion up to 50 Septillion. | None |
| **Buyable Vacuums** | `gareth-buyable_vacuums_mod` | Utility & Quests | Makes Tabbitha's vacuum upgrades directly purchasable on the Bonus shelf while keeping them quest-earnable, plus adds Levels 5 to 8 (up to 600 tiles). | None |
| **Mortar Gun Arsenal** | `gareth-more_mortars_mod` | Weapons & Structures| Adds Tiers 6 through 10 of deployable Mortar Guns with damage scaling from 7.5 Million up to 500 Billion. | None |
| **High-Yield Drills** | `gareth-more_drills_mod` | Weapons & Structures| Adds Tiers 5 through 10 of auto-drills with damage scaling from 100,000 up to 50 Billion. | None |
| **InfiniPlatform** | `gareth-infini_platform_mod` | Utility & Structures| Deploys a horizontal platform bridge left and right across open gaps until colliding with solid walls (maximum 200 blocks). | None |
| **Weapon Stacker** | `gareth-weapon_stacker_mod` | Combat & Scaling | Dynamically scales weapon stats based on active inventory stack count (minigun fire rate/pellet density, water gun spray radius). | None |
| **Elemental Transmutation** | `gareth-elemental_transmutation_mod` | Economy | Destroys burned and corroded tiles for crystallized ore bonuses and slag cash bounties. | None |
| **Excavation Frenzy** | `gareth-excavation_frenzy_mod` | Mining | Chains rapid mining strikes into progressive swing speed and drop multipliers. | `der_floh-pickaxeaoe_mod` |
| **Plasma Raygun** | `gareth-plasma_raygun_mod` | Weapons | High-energy directional plasma cutting beam fired via Right-Click. | None |
| **Prospector's Beacon** | `gareth-prospectors_beacon_mod` | Utility | Emits periodic acoustic pulses to detect and ping high-value ore veins through solid rock. | None |
| **Seismic Hazards** | `gareth-seismic_hazards_mod` | World Gameplay | Introduces dynamic ceiling cave-ins and falling rubble triggered by heavy excavation. | None |
| **Vacuum Collector Depot** | `gareth-vacuum_depot_mod` | World Gameplay | If the vacuum nozzle is closer than the surface, collectors route directly to the nozzle tip to offload. | None |
| **Bouncing Grenade Arsenal** | `gareth-grenade_mod` | World Gameplay | Introduces an explosive projectile delivery system spanning all 15 material grades (Shoddy through Onyx). | None |
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

## Mod Overviews & Mechanics

### 1. Mod Settings System (`gareth-mod_settings_mod`)
* **Unified UI Hook:** Injects a dedicated **"Gareth Mods"** tab into the native `settings_2.gd` menu using vanilla `setting_bool.tscn` and `setting_slider.tscn` controls.
* **Persistent Configuration:** Automatically saves and loads toggles and numerical multipliers to `user://gareth_mods_config.json`.
* **Central Control:** Enables or disables entire mod systems on the fly and provides tuning sliders for explosive blast radii, InfiniPlatform tile limits, and weapon scaling factors.

### 2. Executive Workforce Hierarchy (`gareth-more_employees_mod`)
Expands the Miner workforce line past Senior VP Miner with four executive tiers:
* **Executive VP Miner (Level 24):** Mining Speed 2.4, equips Ruby Pickaxe. Costs $1,500,000 (promotes from Senior VP).
* **Chief Mining Officer (Level 25):** Mining Speed 3.5, equips Pink Diamond Pickaxe. Costs $25,000,000 (promotes from Executive VP).
* **Managing Director Miner (Level 26):** Mining Speed 5.0, equips Moonstone Pickaxe. Costs $350,000,000 (promotes from CMO).
* **Titan Miner (Level 27):** Mining Speed 7.5, equips Onyx Pickaxe. Costs $5,000,000,000 (promotes from Managing Director).
* **Tree Scaling & Centering:** Uncouples the chart from container constraints, applying 53% scaling (~68px icons) positioned cleanly on the yellow board ($X = 350, Y = 80$). Interns remain clearly visible and interactable above the grass line.
* **Cascading Profession Locks:** Automatically respects profession restrictions (such as *Lone Ranger* and *Combined Arms*). Locked or disallowed parent branches cascade their locks upward, preventing orphaned icons or stray lines across the board.
* **Dynamic Connection Lines:** Uses a custom `_draw()` hook with midpoint routing to render clean red (locked) and green (affordable/promotable) orthogonal branch lines.

### 3. Cosmic Collector Drones (`gareth-more_collectors_mod`)
Extends autonomous loot collection with four specialized high-tier drones:
* **Vortex Collector (Level 32 - Speed Branch):** Flight Speed 6.0, Inventory 60,000 items. Costs $75,000,000 (promotes from Lightning Collector).
* **Quantum Collector (Level 33 - Speed Branch):** Flight Speed 9.0, Inventory 180,000 items. Costs $1,250,000,000 (promotes from Vortex Collector).
* **Abyssal Collector (Level 34 - Capacity Branch):** Flight Speed 2.6, Inventory 300,000 items. Costs $350,000,000 (promotes from Mighty Collector).
* **Singularity Collector (Level 35 - Capacity Branch):** Flight Speed 3.5, Inventory 2,500,000 items. Costs $7,500,000,000 (promotes from Abyssal Collector).
* **Safeguards:** Integrates into `employee_manager.gd` via hook chains to bypass Godot's frozen typed array constraints while preserving native save/load states.

### 4. Tank Arsenal Mod (`gareth-tank_arsenal_mod`)
Expands the **Tanker** profession and equipment shop with **45 new purchasable weapons** spanning all 15 material tiers (Shoddy to Onyx), neatly interleaved alongside vanilla tanks in the shop catalogue:
* **Incendiary Tanks (Tiers 1–15):** High-explosive shells setting all tiles in their Manhattan radius ablaze with 6 burn ticks. Direct impact scales with `tank_damage`; burn ticks scale with `fire_damage`. Synergizes with `gareth-elemental_transmutation_mod` for cash bounty payouts.
* **Caustic Tanks (Tiers 1–15):** Chemical mortar rounds releasing toxic acid clouds. Direct damage scales with `tank_damage`; corrosive tick damage scales with `poison_damage`.
* **Depleted Uranium Tanks (Tiers 1–15):** Dense kinetic penetrators with **dynamic tier penetration**, piercing through **+1 solid block per tier** (1 block at Shoddy up to **15 solid blocks at Onyx**).
* **Chest Drops & Fire Rates:** Injects elemental scrolls into Tanker chest loot tables and scales cooldowns natively via `cooldown_time / (1 + Gvars.passives.tank_firing_rate)`.

### 5. High-Yield Demolition (`gareth-hydrogen_bomb_mod` & `gareth-neutron_bomb_mod`)
* **Hydrogen Bomb:** Engineered for wide cavern excavation, expanding the blast radius to **80 tiles** (double the Tactical Nuke) while delivering **999,999 blast damage** ($3,000,000 in shop, placed adjacent to the Tactical Nuke).
* **Neutron Bomb:** Built for deep bedrock penetration, condensing blast radius to a tight **16-tile core** while packing **9,999,999,999 kinetic damage** to shatter obsidian and bedrock instantly ($10,000,000 in shop, placed adjacent to the Hydrogen Bomb).

### 6. Shop Progression & Adjacent Ordering
All progression upgrades use indexed `.insert()` logic to place new tiers directly adjacent to their predecessors on the Bonus Upgrades shelf:
* **Shift Rock Layers (Tiers 6–12):** Inserted directly after Shift 5. Elevates deep mineral depths closer to the surface with exponential costs scaling from 750 Billion (`Shift 6`) up to 750 Sextillion (`Shift 12`).
* **Inventory Slots (Tiers 4–10):** Inserted directly after Slot 3. Expands inventory carrying capacity with scaling bonuses from +20 slots ($500k) up to +250 slots ($2.5 Quadrillion).
* **Inventory Stacks (Tiers 7–16):** Inserted directly after Stack 6. Scales item stack capacity from +25 Billion ($75 Trillion) up to +50 Sextillion items ($50 Septillion).

### 7. Buyable Vacuums & Strata Extensions (`gareth-buyable_vacuums_mod`)
* **Dual Unlocking:** Unlocks vanilla Vacuum Cleaners 1 to 4 so they can be bought directly from the Bonus shelf with cash in addition to being earned via Tabbitha's questline.
* **Levels 5 to 8:** Hooks `equipment_manager.gd` to extend vacuum suction hose lengths into the deepest mine strata:
  * **Level 5 (Uranium):** 220 tiles ($150M)
  * **Level 6 (Moonstone):** 300 tiles ($1.5B)
  * **Level 7 (Onyx):** 420 tiles ($20B)
  * **Level 8 (Abyssal):** 600 tiles ($300B)

### 8. Heavy Machinery (`gareth-more_mortars_mod` & `gareth-more_drills_mod`)
* **Mortar Guns (Tiers 6–10):** Autonomous artillery structures that bombard mine shafts directly beneath them at 1 shot/second. Damage scales from 7.5 Million (`Tier 6`) up to 500 Billion (`Tier 10`), inserted directly after Mortar Gun 5.
* **Drills (Tiers 5–10):** Autonomous continuous vertical boring bits ticking 10 times per second. Damage scales from 100,000 (`Tier 5`) up to 50 Billion (`Tier 10`), inserted directly after Drill 4.

### 9. InfiniPlatform Mod (`gareth-infini_platform_mod`)
* The horizontal bridging equivalent of the vertical `InfiniLadder`.
* Placing an InfiniPlatform triggers simultaneous left (`-X`) and right (`+X`) expansion rays, laying down platforms until colliding with solid terrain or reaching the configurable safety cap (**default: 200 blocks**).

### 10. Weapon Stacker Mod (`gareth-weapon_stacker_mod`)
Dynamically hooks into `gun.gd` and `water_gun.gd` during runtime physics frames, checking the player's active inventory count for the equipped weapon:
* **Minigun Stacking:** Shrinks cooldown delays down to 0.01s (up to ~60 bursts/second) and scales projectile counts up to a 40-pellet wall of lead per burst with forward speed trajectory compensation.
* **Water Gun Stacking:** Expands spray radius logarithmically with stack count, enabling single-burst soaking of entire mine shafts to prime blocks for double wet damage.

### 11. Elemental Transmutation Mod (`gareth-elemental_transmutation_mod`)
Hooks block destruction events in `tile_map_chunk.gd`:
* **Burned Blocks:** Breaking tiles currently afflicted by fire triggers a thermal crystallization event, yielding bonus currency payouts directly to cash reserves.
* **Corroded Blocks:** Breaking acid-affected blocks converts them to slag, granting immediate scrap bounty rewards.

### 12. Excavation Frenzy Mod (`gareth-excavation_frenzy_mod`)
* Synergizes with area-of-effect pickaxe hooks.
* Maintaining rapid strike cadence increases your frenzy meter, ramping up swing speeds and drop quantities until mining halts.

### 13. Plasma Raygun Mod (`gareth-plasma_raygun_mod`)
* Equips your miner with a focused thermal cutting beam.
* Hold **Right-Click** while wielding mining gear to punch clean corridors through high-density rock formations.

### 14. Prospector's Beacon Mod (`gareth-prospectors_beacon_mod`)
* Periodically casts sub-surface sonar sweeps centered on the player.
* Detects hidden veins through solid rock and displays acoustic ping coordinates in both the game world and telemetry logs.

### 15. Seismic Hazards Mod (`gareth-seismic_hazards_mod`)
* Simulates ceiling load pressure.
* Aggressive mining in deep shafts without leaving supporting columns risks structural failure, causing unstable ceiling tiles to collapse downward.

### 16. Subterranean Vacuum Collector Depot (`gareth-vacuum_depot_mod`)
Solves the late-game logistical bottleneck where automated UFO Collectors spend the majority of their flight time ferrying cargo back to the surface dock.

UFO Collectors calculate distance vectors in real time between their home surface dock (Vector2(50, -55)) and the active nozzle of the Vacuum Cleaner (%SuckEndPhysicsBody).

Subterranean Offloading: If the vacuum nozzle is closer than the surface, collectors route directly to the nozzle tip and offload carried cargo into the shared Stockpile inventory upon arrival (within 24px).

Local Search Reloop: After depositing into the vacuum hose, collectors immediately resume searching for nearby ore drops at current mine depth, eliminating surface flight times.

### 17. Bouncing Grenade Arsenal (`gareth-grenade_mod`)
The Bouncing Grenade Arsenal introduces an explosive projectile delivery system spanning all 15 material grades (Shoddy through Onyx). Unlike stationary placement charges, grenades are cast actively along a parabolic trajectory and rebound off subterranean geometry before detonation.

### 18. Quest Rewards & Career Leaderboard (`gareth-leaderboard_mod`)
A persistent analytics and career tracker accessible directly from the in-game Settings menu (settings_2.gd). The leaderboard maintains a persistent JSON database (user://leaderboard_records.json) recording all-time peaks across every run alongside live metrics.


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
│   ├── gareth-mod_settings_mod.zip
│   ├── gareth-more_collectors_mod.zip
│   ├── gareth-more_drills_mod.zip
│   ├── gareth-more_employees_mod.zip
│   ├── gareth-more_inventory_slots_mod.zip
│   ├── gareth-more_inventory_stacks_mod.zip
│   ├── gareth-more_layer_shifts_mod.zip
│   ├── gareth-more_mortars_mod.zip
│   ├── gareth-more_vacuum_quests_mod.zip
│   ├── gareth-neutron_bomb_mod.zip
│   ├── gareth-plasma_raygun_mod.zip
│   ├── gareth-prospectors_beacon_mod.zip
│   ├── gareth-seismic_hazards_mod.zip
│   ├── gareth-tank_arsenal_mod.zip
│   ├── gareth-weapon_stacker_mod.zip
│   ├── gareth-grenade_mod.zip
│   ├── gareth-leaderboard_mod.zip
│   └── gareth-vacuum_depot_mod.zip
├── mods-unpacked/                       # Raw source GDScript files
│   ├── gareth-buyable_vacuums_mod/
│   ├── gareth-elemental_transmutation_mod/
│   ├── gareth-excavation_frenzy_mod/
│   ├── gareth-hydrogen_bomb_mod/
│   ├── gareth-infini_platform_mod/
│   ├── gareth-mod_settings_mod/
│   ├── gareth-more_collectors_mod/
│   ├── gareth-more_drills_mod/
│   ├── gareth-more_employees_mod/
│   ├── gareth-more_inventory_slots_mod/
│   ├── gareth-more_inventory_stacks_mod/
│   ├── gareth-more_layer_shifts_mod/
│   ├── gareth-more_mortars_mod/
│   ├── gareth-more_vacuum_quests_mod/
│   ├── gareth-neutron_bomb_mod/
│   ├── gareth-plasma_raygun_mod/
│   ├── gareth-prospectors_beacon_mod/
│   ├── gareth-seismic_hazards_mod/
│   ├── gareth-tank_arsenal_mod/
│   └── gareth-weapon_stacker_mod/
│   └── gareth-grenade_mod/
│   └── gareth-leaderboard_mod/
│   └── gareth-vacuum_depot_mod/
└── README.md
```

---

## Credits & Acknowledgments
* **[Godot ModLoader Team](https://wiki.godotmodding.com/)** for the modding framework.
* **[Der-Floh](https://github.com/Der-Floh/)** for foundational utility mods and hooks architecture.
* **[nanobotz](https://github.com/NanobotZ)** for the auto-passive chooser implementation.
