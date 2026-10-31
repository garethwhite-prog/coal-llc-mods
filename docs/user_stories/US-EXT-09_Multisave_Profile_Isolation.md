# US-EXT-09: MultiSave Architecture & Profile Isolation
**Status:** Completed
**Mod:** gareth-multisave_mod

**Description:**
As a player, I want multiple isolated save slots so I can run distinct careers, test mod combinations, and track high scores without cross-slot data contamination.

**Acceptance Criteria:**
- Provides isolated slot folders with per-slot `Gvars` and mod configuration state.
- Automatically syncs required mod packages between `downloaded_mods/` and `mods/` upon slot selection.
- Validates hard modifier badges and career milestones during slot transitions.
