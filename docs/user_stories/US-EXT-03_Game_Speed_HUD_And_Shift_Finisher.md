# US-EXT-03: Game Speed Controller & Emergency Shift Finisher
**Status:** Completed
**Mod:** gareth-game_speed_mod

**Description:**
As a player, I want an on-screen HUD micro-dock to adjust engine time scale dynamically and end the mining shift early so I can manage pacing and exit completed levels without waiting for timers.

**Acceptance Criteria:**
- Bottom-right micro-dock displays stepped speed controls (0.25x to 5.00x) and active time scale readout.
- Micro-dock automatically hides during Main Menu, Level Select, and Management screens.
- Includes `⏰ End Day` button and `[F8]` hotkey calling `Game.on_EndDay()` or `Game.change_stage(Stages._END_OF_DAY_OVERLAY)`.
- Resets `Engine.time_scale` back to 1.00x whenever leaving active mining shifts.
