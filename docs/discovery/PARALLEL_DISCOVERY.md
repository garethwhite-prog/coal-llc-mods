# Global Architecture Ledger

- **Total Active Mods**: 64 modules identified.
- **UI Canvas Intercepts**: MainMenu, level_select, settings_2.
- **Core Loop Intercepts**: TileMapManager, Game.gd, Player2.gd.
- **Outstanding Sync Points**:
  - Drones must hide the container Sprites inside mployee_miner_2.
  - Passives menu routes dynamically via Gvars.profession_manager.all_professions[id].
  - manifest.json must be strictly validated to categorize Official vs Community mods in the UI.
