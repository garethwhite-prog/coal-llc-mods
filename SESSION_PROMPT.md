# Coal LLC Modding Session Context & Rules (Updated October 2026)

## Project Paths & Environment
- Local Git Repository: C:\Dev\coal-llc-mods
- Active Unpacked Mods: C:\Dev\coal-llc-mods\mods-unpacked\<namespace>-<mod_name>
- Steam Game Directory: C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC
- Steam Mods Directory: C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods
- Engine Logs: %APPDATA%\Godot\app_userdata\Coal LLC\logs\godot.log and modloader.log

## Architecture & Packaging Standards
1. Dual-Manifest & Dual-README Requirement:
   Every mod .zip must contain manifest.json and README.md at the root of the archive AND duplicate copies inside mods-unpacked/<namespace>-<mod_name>/.
2. Folder Hierarchy in Git Repo:
   Mods in the git repository are structured with the nested path:
   mods-unpacked/<mod_name>/mods-unpacked/<mod_name>/
   This allows packaging $src = ...\mods-unpacked\<mod_name> directly so both root files and internal relative paths resolve cleanly.
3. Forward Slash Zip Rule:
   Godot's virtual filesystem requires zip entry paths to use forward slashes (/). Windows Compress-Archive injects backslashes (\), causing ModLoader to report missing files. Always compile zip entries using System.IO.Compression.ZipArchive with .Replace("\", "/").

## Godot 4 Engine & Runtime Quirks
1. Loose PNG Texture Loading:
   In exported Godot 4 builds, loose .png files placed in mod zips are not registered as .ctex resources by ResourceLoader. Calling load("res://...png") returns null. Loose images must be loaded dynamically:
   var img = Image.load_from_file(path)
   var tex = ImageTexture.create_from_image(img)
2. TileMapLayer Coordinate Signatures (Godot 4.3+):
   TileMapManager extends TileMapLayer. Methods like get_cell_atlas_coords(coords) take 1 argument (Vector2i), NOT 2 (layer, coords). Calling it with 2 arguments triggers a fatal script error that halts execution.

## Progression, Economy & Class Mechanics
1. 15-Tier Mineral Hierarchy:
   Archetype weapons scale through 15 standardized tiers:
   01_shoddy, 02_copper, 03_iron, 04_sapphire, 05_emerald, 06_silver, 07_amethyst, 08_gold, 09_ruby, 10_diamond, 11_pinkdiamond, 12_spinel, 13_uranium, 14_moonstone, 15_onyx.
2. Programmatic Item Instantiation:
   Creating Item.gd and EquipEffect instances directly in GDScript bypasses .tres deserialization failures caused by unimported runtime textures.
3. Class Custom Passives & Mod Manager Gating:
   Level-up cards on the "Choose a passive effect" screen are managed by gareth-mod_manager_mod/extensions/scenes/Interfaces/in_game/choose_passive.hooks.gd.
   To implement class-branded upgrades:
   - Assign item.itemType = "<custom_type>" on all tier items.
   - Register the item type in local_passive_map["<custom_type>"].
   - Register the stat keys and scaling increments in CUSTOM_PASSIVES.
   - Add the stat keys to unlocked_passives in the profession script.
   - Read stats dynamically in the weapon script via Gvars.passives.get_meta("<stat_name>").

## PowerShell Scripting Directives
- Every script MUST start with cls on line 1.
- All code must use standard ASCII spaces (never non-breaking spaces \u00A0).
- Use explicit single-line statements and direct .NET methods ([System.IO.File], [System.IO.Directory], [System.IO.Path]) to guarantee cross-environment stability.