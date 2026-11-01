# BUG-05: Mod Manager displays 'By Community' for Official Mods
**Status:** Open
**Component:** gareth-mod_manager_mod (mod_manager_view.gd)
**Description:** Manifests have 'Gareth White' as the author, but the UI defaults to 'By Community'.
**Theory:** The GDScript parsing the manifest likely has a hardcoded check (e.g. if author != "Der-Floh").
