# Coal LLC Mod Suite

A collection of gameplay enhancements, dynamic weapon scaling, excavation mechanics, and environmental hazard mods for **[Coal LLC](https://store.steampowered.com/app/3361510/Coal_LLC/)**, built for the **[Godot ModLoader 7.x](https://godotengine.org/asset-library/asset/4107)** framework.

---

## Included Mods

| Mod | Namespace / ID | Description | Dependencies |
| :--- | :--- | :--- | :--- |
| **Weapon Stacker** | `gareth-weapon_stacker_mod` | Scales weapon stats dynamically based on inventory stack count (minigun fire rate/pellet density, water gun spray radius). | None |
| **Elemental Transmutation** | `gareth-elemental_transmutation_mod` | Destroys burned and corroded tiles for crystallized ore bonuses and slag cash bounties. | None |
| **Excavation Frenzy** | `gareth-excavation_frenzy_mod` | Chains rapid mining strikes into progressive speed and drop multipliers. | `der_floh-pickaxeaoe_mod` |
| **Plasma Raygun** | `gareth-plasma_raygun_mod` | Adds a high-energy directional plasma cutting beam fired via Right-Click. | None |
| **Prospector's Beacon** | `gareth-prospectors_beacon_mod` | Emits periodic acoustic pulses to detect and ping high-value ore veins. | None |
| **Seismic Hazards** | `gareth-seismic_hazards_mod` | Introduces dynamic ceiling cave-ins and falling rubble triggered by heavy excavation. | None |

---

## Installation

### Prerequisites
* **Coal LLC** (Steam / PC version)
* **Godot ModLoader** (v7.0.1+ installed into your game executable directory)

### Quick Install (ZIP Packages)
1. Download the desired `.zip` files from the [Releases](../../releases) tab or the `/mods` directory in this repository.
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

### 1. Weapon Stacker Mod (`gareth-weapon_stacker_mod`)
Dynamically hooks into `gun.gd` and `water_gun.gd` during runtime physics frames, checking the player's active inventory count for the equipped weapon resource:
* **Minigun Stacking:**
  * Multiplies fire rate by shrinking cooldown delays down to 0.01s (up to ~60 bursts/second).
  * Scales projectile counts up to a dense 40-pellet wall of lead per burst.
  * Incorporates forward speed trajectory compensation to prevent high-density volleys from inverting velocity.
* **Water Gun Stacking:**
  * Expands spray radius logarithmically with stack count, enabling single-burst soaking of entire mine shafts to prime blocks for double wet damage.

### 2. Elemental Transmutation Mod (`gareth-elemental_transmutation_mod`)
Hooks block destruction events in `tile_map_chunk.gd`:
* **Burned Blocks:** Breaking tiles currently afflicted by fire triggers a thermal crystallization event, yielding bonus currency payouts directly to cash reserves.
* **Corroded Blocks:** Breaking acid-affected blocks converts them to slag, granting immediate scrap bounty rewards.

### 3. Excavation Frenzy Mod (`gareth-excavation_frenzy_mod`)
* Synergizes with area-of-effect pickaxe hooks.
* Maintaining rapid strike cadence increases your frenzy meter, ramping up swing speeds and drop quantities until mining halts.

### 4. Plasma Raygun Mod (`gareth-plasma_raygun_mod`)
* Equips your miner with a focused thermal cutting beam.
* Hold **Right-Click** while wielding mining gear to punch clean corridors through high-density rock formations.

### 5. Prospector's Beacon Mod (`gareth-prospectors_beacon_mod`)
* Periodically casts sub-surface sonar sweeps centered on the player.
* Detects hidden veins through solid rock and displays acoustic ping coordinates in both the game world and telemetry logs.

### 6. Seismic Hazards Mod (`gareth-seismic_hazards_mod`)
* Simulates ceiling load pressure.
* Aggressive mining in deep shafts without leaving supporting columns risks structural failure, causing unstable ceiling tiles to collapse downward.

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
│   ├── gareth-elemental_transmutation_mod.zip
│   ├── gareth-excavation_frenzy_mod.zip
│   ├── gareth-plasma_raygun_mod.zip
│   ├── gareth-prospectors_beacon_mod.zip
│   ├── gareth-seismic_hazards_mod.zip
│   └── gareth-weapon_stacker_mod.zip
├── mods-unpacked/                       # Raw source GDScript files
│   ├── gareth-elemental_transmutation_mod/
│   ├── gareth-excavation_frenzy_mod/
│   ├── gareth-plasma_raygun_mod/
│   ├── gareth-prospectors_beacon_mod/
│   ├── gareth-seismic_hazards_mod/
│   └── gareth-weapon_stacker_mod/
└── README.md
```

---

## Credits & Acknowledgments
* **[Godot ModLoader Team](https://wiki.godotmodding.com/)** for the modding framework.
* **[Der-Floh](https://github.com/Der-Floh/)** for foundational utility mods and hooks architecture.
* **[nanobotz](https://github.com/NanobotZ)** for the auto-passive chooser implementation.
