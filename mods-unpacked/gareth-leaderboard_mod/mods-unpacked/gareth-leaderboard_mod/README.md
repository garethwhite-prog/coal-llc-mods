# Categorized Leaderboards & Hall of Fame

**Namespace:** $namespace  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
A persistent analytics suite accessible from both the Main Menu and Settings screen. It records all-time records across mining speed, damage, automated employee efficiency, and highest cash quotas.

Records persist across runs in user://leaderboard_records.json.

---

## Technical Details (For Modders)
Autoload node samples Gvars.passives, Gvars.bonus_equipment_manager, and cash milestones every 1.0s, updating high-score dictionaries in JSON storage.

---

## Installation
1. Ensure **Coal LLC** has Godot ModLoader 7.0.1 installed.
2. Place the packaged .zip file into your Coal LLC/mods/ directory.
3. Manage or toggle this mod directly via the in-game **Mod Manager**.