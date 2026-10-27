extends Node

const MOD_DIR := "gareth-henry_the_hoover_mod"

func _init() -> void:
	ModLoaderMod.install_script_hooks(
		"res://scenes/equipment/vacuum_cleaner.gd",
		"res://mods-unpacked/gareth-henry_the_hoover_mod/extensions/scenes/equipment/vacuum_cleaner.hooks.gd"
	)
	ModLoaderLog.info("Henry the Hoover Vacuum Visuals online!", MOD_DIR)
