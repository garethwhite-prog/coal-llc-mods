# Coal LLC Mods

Collection of mods for the game [Coal LLC](https://store.steampowered.com/app/3361510/Coal_LLC/).


# Installation
All mods require Godot Mod Loader (GML) by NanobotZ to be installed first:
👉 https://github.com/NanobotZ/godot-mod-loader

Download the mod loader here (choose the version for your operating system): https://github.com/NanobotZ/godot-mod-loader/releases/latest

Extract the mod loader and copy the addons folder into both of these locations: 
* C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\ 
* C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC\

In Steam, open Coal LLC's properties and add this into launch options: 
--script "addons/mod_loader/mod_loader_setup.gd"

Once GML is set up, drop the mod .zip file(s) into the mods/ folder inside your Coal LLC game directory and launch the game (do not extract the zip).

IMPORTANT: For now it's a good idea to delete "mod-hooks.zip" file from the game folder each time the game updates!

Warning: When launching the game with new mods, you may see a popup saying "New mods will be applied after a restart.", and the buttons might not work. If that happens, Alt+F4 out of the game and launch the game again.
