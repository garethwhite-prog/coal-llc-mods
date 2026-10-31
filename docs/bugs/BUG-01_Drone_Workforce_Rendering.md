# BUG-01: Quadcopter / Drone Overrides Failing to Render
**Status:** Open
**Component:** gareth-drone_workforce_mod

**Description:**
The active miners have not visually transformed into quadcopters during a shift. The UFO collectors have also not transformed.
**Expected:** The original humanoid/UFO sprites should be set to isible = false and replaced by the procedural MinerDroneSprite and CargoDroneSprite injected via call_deferred.
**Current Theory:** The hooks in mployee_miner_2.hooks.gd and LootCollectorUFO.hooks.gd might not be targeting the correct child node names (e.g., "Models", "Head", "Torso") in the vanilla v1.4.1.1 scene tree, or _ready() is overriding our deferred texture load.
