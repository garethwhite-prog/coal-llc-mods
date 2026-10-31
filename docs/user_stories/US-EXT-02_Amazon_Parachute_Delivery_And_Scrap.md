# US-EXT-02: In-Shift Amazon Parachute Delivery & Scrap Engine
**Status:** Completed
**Mod:** gareth-scrap_and_delivery_mod

**Description:**
As a player, I want to press [B] during a mining shift to browse an in-field supply catalog and order equipment delivered via parachute drone, as well as scrap unwanted items for immediate wallet recovery.

**Acceptance Criteria:**
- Hotkey [B] toggles delivery UI during active mining shifts without pausing game physics.
- Delivery crates spawn at z_index = 60 and smoothly descend to the player's position using tweened gravity simulation.
- Items with `itemBuyEffect` (inventory slots, stack sizes) temporarily zero `itemBuyPrice` on delivery to bypass wallet checks and apply capacity increases directly to `PlayerInventory.tres`.
- Physical tools and weapons transfer directly into open inventory slots.
- Quick-scrap button converts highlighted tools back into cash at fair market scrap value.
