# BUG-03: Henry the Hoover Interaction with Drone Mod
**Status:** Open
**Component:** gareth-henry_the_hoover_mod vs gareth-drone_workforce_mod

**Description:**
Need to verify the interaction between the Henry Hoover mod (which edits the vacuum cleaner) and the Drone Workforce mod (which replaces miners/collectors).
**Expected:** The Player can equip the Henry Hoover vacuum while the independent NPC automated workforce operates as Quadcopters.
**Current Theory:** These mods should not conflict as Henry hooks acuum_cleaner.gd (the player's tool) while Drones hook mployee_miner_2.gd and LootCollectorUFO.gd (the automated NPCs).
