# US-05: Mod Store Registration & Passive Routing
**Status:** In Progress
**Mod:** gareth-mod_manager_mod

**Description:**
As a player, I want all newly developed mods (Quadcopters, Henry Hoover, Thomas the Tank) to appear in the Mod Manager and Mod Store so I can enable/disable them. I also want the Bouncing Ball upgrades to be configurable in the Passive Order menu.

**Acceptance Criteria:**
- Append gareth-drone_workforce_mod to mod_registry.gd.
- Append gareth-thomas_tank_engine_mod to mod_registry.gd.
- Append gareth-reach_expansion_mod to mod_registry.gd.
- Inject all_blast_damage, all_blast_radius, and all_fire_rate into the Passive Order array.
