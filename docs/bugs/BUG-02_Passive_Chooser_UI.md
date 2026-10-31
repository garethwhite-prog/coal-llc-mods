# BUG-02: Bouncing Ball Passives Missing from Auto-Chooser Menu
**Status:** Open
**Component:** 
anobotz-autopassivechooser

**Description:**
Despite injecting Bouncing Ball Damage, Bouncing Ball Blast Radius, and Bouncing Ball Fire Rate into settings_2.hooks.gd, they are not appearing in the "Passive Order" UI menu.
**Expected:** The new passives should be configurable with up/down arrows in the in-game settings tab.
**Current Theory:** The 
anobotz-autopassivechooser mod relies on a UI .tscn file (passive_order.tscn) containing pre-defined VBoxContainers for each passive row. Injecting string names via a script hook does not dynamically generate the UI controls if the original mod used hardcoded nodes.
