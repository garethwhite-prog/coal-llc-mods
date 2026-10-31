# US-EXT-01: Bouncing Ball Kinetic Stacking Ordnance
**Status:** In Progress
**Mod:** gareth-bouncing_ball_mod

**Description:**
As a player, I want an equipable bouncing kinetic weapon that compounds damage across multiple wall rebounds and momentum impulses so I can clear vertical shafts and dense rock strata efficiently.

**Acceptance Criteria:**
- Projectile inherits CharacterBody2D with procedural CollisionShape2D (CircleShape2D, radius 7.0) and fuse timer (1.4s).
- Implements 3-Tier compounding damage formula: Base Damage x Bounce Multiplier (+65% per rebound) x Velocity Multiplier (clampf to 0.8-3.5x) x Global Passives Multiplier.
- Projectile exposes `damage`, `radius`, `tilemap`, and `ball_texture` to prevent frame 1 instantiation crashes.
- Final detonation spawns an area-of-effect tile clear with explosion particles.
