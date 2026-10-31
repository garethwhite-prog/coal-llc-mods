# US-EXT-08: Universal In-Game Mod Manager & Mod Store
**Status:** Completed
**Mod:** gareth-mod_manager_mod

**Description:**
As a player, I want an in-game Mod Manager and downloadable Mod & Map Store accessible directly from the Main Menu to browse, install, toggle, and update mods.

**Acceptance Criteria:**
- Main Menu displays custom wooden title board with hanging chain sub-plaque (`✦ ENHANCED BY GARETH WHITE & GEMINI ✦`).
- Dedicated buttons for Mod Manager, Mod & Map Store, and Leaderboards.
- Mod Store features repository switching (Official Suite vs Community Classics), real-time text search, category filtering, and one-click zip download/staging.
- Deletions handle Windows file locks via `.pending_delete` flags processed on subsequent launches.
