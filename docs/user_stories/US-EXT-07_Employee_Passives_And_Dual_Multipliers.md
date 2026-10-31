# US-EXT-07: Workforce Scaling & Cross-Passive Multipliers
**Status:** In Progress
**Mod:** gareth-employee_passives_mod, gareth-dual_multipliers_mod

**Description:**
As a player, I want automated employee miners and UFO collectors to benefit from compounding range, pickup speed, and magnetic attraction upgrades so automated mining scales into late-game depths.

**Acceptance Criteria:**
- Hook `employee_miner_2.gd` to scale search range (`10 x (1 + stat)`), pickaxe reach (`3 x (1 + stat)`), and vacuum aura (52px radius).
- Hook `LootCollectorUFO.gd` to inject magnetic ore pull radius (64px base x multiplier) at 350px/s.
- Hook `dual_multipliers_mod` to compound weapon fire rates and employee mining damage quadratically.
- Expose the 3rd set of workforce passive upgrades in the between-day Bonus Shop.
