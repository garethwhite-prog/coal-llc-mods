# BUG-04: Cannot Uninstall Mod via Mod Store
**Status:** Open
**Component:** gareth-mod_manager_mod (mod_store_client.gd / mod_store_view.gd)
**Description:** User was able to install Teletubbies but clicking remove/uninstall on Henry the Hoover failed.
**Theory:** The zip file might be locked by Godot's resource loader, or the deletion script is targeting the wrong directory (mods/ vs downloaded_mods/).
