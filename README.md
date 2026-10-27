# Coal LLC Modding Suite

A complete, high-performance ecosystem of gameplay overhauls, custom subterranean maps, unique character classes, industrial workforce hierarchies, high-tier demolition options, and quality-of-life tools for **[Coal LLC](https://store.steampowered.com/app/3361510/Coal_LLC/)**, built on the **[Godot ModLoader 7.x](https://godotengine.org/asset-library/asset/4107)** hook architecture.

![Tectonic Faultline Preview](mods-unpacked/gareth-tectonic_faultline_mod/assets/tectonic_preview.png)

---

## Complete Mod Directory (51 mods)

### 1. Custom Maps & Subterranean Overhauls (Maps 101–105)
| Mod | ID | Type | Description |
| :--- | :--- | :--- | :--- |
| **The Lost Expedition** | `gareth-lost_expedition_mod` | Map (ID 101) | Subterranean cryo-abyss featuring ancient buried shelters, unexploded landmines (UXO), and survival extraction mechanics. |
| **Tectonic Faultline** | `gareth-tectonic_faultline_mod` | Map (ID 102) | Seismic rift featuring vertical chasms, active magma fissures, 3x density elemental pods (Fire, Water, Poison), and an elemental tick rate progression engine. |
| **The Living Canvas** | `gareth-living_canvas_mod` | Map (ID 103) | Image-to-strata mosaic quarry supporting custom PNG imports converted into mineable subterranean strata. |
| **The Abyssal Trench** | `gareth-abyssal_trench_mod` | Map (ID 104) | Subterranean ocean trench featuring hydrothermal black smoker geysers, twilight sapphire strata, and abyssal basalt. |
| **Diagonal Seams** | `gareth-diagonal_map_mod` | Map (ID 105) | 45-degree rotated diagonal subterranean strata layers requiring specialized diagonal tunneling and stepped excavation. |

### 2. Character Classes & Combat Archetypes
| Mod | ID | Description |
| :--- | :--- | :--- |
| **Knight Class** | `gareth-knight_class_mod` | Master of chivalric blade combat. Starts with a Shoddy Sword that sweeps in a 180° frontal arc clearing rock and ore. |
| **Jedi Class** | `gareth-jedi_class_mod` | Wielder of plasma energy sabers across 15 mineral tiers with rapid deflect swings and rock vaporisation. |
| **Bouncing Demolitionist**| `gareth-custom_classes_mod` | Master of ricochet excavation using bouncy rubber demolition spheres. |
| **Rainbow Sinclairity** | `gareth-sinclairity_class_mod` | Experimental spectral optics miner with continuous prismatic beam across 15 tiers. |
| **Void Siphon** | `gareth-void_siphon_mod` | Gravitational vacuum imploder that collapses distant ore veins directly into personal inventory. |
| **Debt Executioner** | `gareth-debt_executioner_mod` | High-risk financial class converting unpaid daily quotas into raw pickaxe excavation damage. |
| **Chrono-Industrialist** | `gareth-chrono_industrialist_mod` | Temporal manipulation specialist that warps excavation speed and slows physics timers. |
| **Gravitational Dreadnought** | `gareth-grav_dreadnought_mod` | Heavy exo-suit miner that crushes stone beneath accelerated downward terminal velocity. |
| **Tectonic Fracker** | `gareth-tectonic_fracker_mod` | High-pressure hydraulic injection specialist that shatters surrounding strata veins. |

### 3. Weapons, Demolition & Surface Hazards
| Mod | ID | Description |
| :--- | :--- | :--- |
| **Elemental Airstrikes & B-52** | `gareth-elemental_airstrikes_mod` | Consumable tactical radios: Dragon Firebomber, Water Deluge, Agent Orange Defoliant, and **B-52 Carpet Bomber** (10 heavy ordnance bombs). |
| **High-Energy Laser Beam** | `gareth-laser_beam_mod` | Continuous collimated beam that melts stone and ore in real time via scaled mining damage. |
| **Donkey Kong Surface Hazard** | `gareth-donkey_kong_mod` | Surface plateau ape that rolls heavy wooden barrels into the shaft, stunning and immobilizing miners for 2.5 seconds. |
| **Heavy Turrets** | `gareth-heavy_turrets_mod` | Deployable perimeter auto-turrets targeting subterranean stone clusters within a 14-tile radius. |
| **Bouncing Grenades** | `gareth-grenade_mod` | 15 tiers of timed demolition grenades that rebound off solid walls before exploding. |
| **Tank Arsenal** | `gareth-tank_arsenal_mod` | Heavy artillery tank shells with shockwave piercing and multi-block blast radiuses. |

### 4. Workforce, Automation & Progression
| Mod | ID | Description |
| :--- | :--- | :--- |
| **Workforce Chart** | `gareth-more_employees_mod` | Complete 5-tier employee hierarchy: Interns, Junior Miners, Engineers, Directors, and Executives. |
| **Collector UFO Priority** | `gareth-collector_priority_mod` | Configurable in-game settings tab: Closest First, Most Valuable Gems First, or Quota Priority. |
| **Auto-Ladder Builder** | `gareth-auto_ladder_mod` | Automatically drops scaffolding ladders under the miner when descending vertical shafts. |
| **Scrap & Parachute Delivery**| `gareth-scrap_and_delivery_mod` | Mid-mine ore recycling for 50% cash and instant parachute deliveries via Amazon drone. |
| **Bonus Upgrades Search & Filter** | `gareth-mod_manager_mod` | Search bar, A-Z sorting, and "Affordable Only" checkbox on both Equipment and Bonus Upgrades shop tabs. |
| **Multisave Career Profiles** | `gareth-multisave_mod` | 6 isolated career save slots with independent JSON mod configurations and badge persistence. |
| **In-Game Mod & Map Store** | `gareth-mod_manager_mod` | Title-screen community repository browser with category filtering and version checking. |

---

## Core Engine Modding Contracts

1. **Sky Code Contract:** `lvl_from_global_pos(pos)` must return `-2` whenever `pos.y <= 0`. Returning positive rock tiers at or above ground level fills the sky and spawn point with solid bedrock, crushing the player on spawn.
2. **Tile Damage Signature:** In *Coal LLC*, tile damage is processed via `tilemap.damageTileCoords(coords: Vector2i, damage: float)`. Passing non-primitive objects into argument 2 triggers an unhandled conversion abort.
3. **InputMap Restrictions:** Never query unmapped input action names (e.g., `"fire"`). Vanilla only registers `useItem`, `rightMouseClick`, and `toggle_use_item`. Querying unregistered strings logs errors on every physics tick.
4. **Chunk Bounds Protection:** `TileMapManager.chunks_created` must be guarded with `.has(chunk_id)` before indexing. Querying unloaded chunk IDs throws an unhandled dictionary exception.
5. **Ordnance & Tween Lifecycles:** Decouple falling projectiles from their parent launchers into standalone entities (`AirstrikeBomb`) to prevent `Instance is null` errors when parent nodes are freed while tween callbacks are pending.
