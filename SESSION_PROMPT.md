# Coal LLC Modding Session Context & Rules (Updated October 2026)

## Paths & Environment
- Local Git Repo: C:\Dev\coal-llc-mods
- Active Mods: C:\Dev\coal-llc-mods\mods-unpacked\<namespace>-<mod_name>
- Steam Game Directory: C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC
- Steam Mods Directory: C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\mods

## Engine Quirks & Standards
1. Dual-Manifest & Dual-README: Zip root AND internal unpacked directory must contain copies.
2. Forward Slashes: Zip entry paths must use forward slashes (/).
3. Loose PNG Loading: Must use Image.load_from_file() and ImageTexture.create_from_image().
4. TileMapLayer: TileMapManager extends TileMapLayer; coordinate queries take 1 argument (coords: Vector2i).
5. 15-Tier Hierarchy: Shoddy, Copper, Iron, Sapphire, Emerald, Silver, Amethyst, Gold, Ruby, Diamond, Pink Diamond, Spinel, Uranium, Moonstone, Onyx.