extends Node

const MOD_ID := "gareth-mod_manager_mod"
const LOG_NAME := "gareth-mod_manager_mod"

func _init() -> void:
	ModLoaderLog.info("Universal Mod Manager initializing...", LOG_NAME)
	install_hooks()

func _ready() -> void:
	ModLoaderLog.info("Universal Mod Manager active with full Class, Shop & Input gating.", LOG_NAME)

func install_hooks() -> void:
	var unpacked_dir = ModLoaderMod.get_unpacked_dir().path_join(MOD_ID)
	var ext_dir = unpacked_dir.path_join("extensions")

	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/in_game/choose_passive.gd",
		ext_dir.path_join("scenes/Interfaces/in_game/choose_passive.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/MainMenu.gd",
		ext_dir.path_join("scripts/MainMenu.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scripts/Gvars.gd",
		ext_dir.path_join("scripts/Gvars.hooks.gd")
	)
	ModLoaderMod.install_script_hooks(
		"res://scenes/Stages/management_screen.gd",
		ext_dir.path_join("scenes/Stages/management_screen.hooks.gd")
	)

# === GLOBAL CAMERA ZOOM INTERCEPTOR ===
func _input(event: InputEvent) -> void:
if not Gvars or not ("settings" in Gvars) or not Gvars.settings:
return

var handled = false
if event is InputEventMouseButton and event.is_pressed():
# MOUSE_BUTTON_WHEEL_DOWN = 5 (Zoom OUT -> see more of mine)
if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
Gvars.settings.zoom_level = clamp(Gvars.settings.zoom_level - 0.2, 0.25, 4.0)
handled = true
# MOUSE_BUTTON_WHEEL_UP = 4 (Zoom IN -> see player closer)
elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
Gvars.settings.zoom_level = clamp(Gvars.settings.zoom_level + 0.2, 0.25, 4.0)
handled = true

elif event is InputEventKey and event.is_pressed() and not event.is_echo():
# Hotkeys: '-' or '[' to zoom out; '=' or ']' to zoom in; '0' or 'Z' to reset to 1.0
if event.keycode == KEY_MINUS or event.keycode == KEY_BRACKETLEFT:
Gvars.settings.zoom_level = clamp(Gvars.settings.zoom_level - 0.25, 0.25, 4.0)
handled = true
elif event.keycode == KEY_EQUAL or event.keycode == KEY_BRACKETRIGHT:
Gvars.settings.zoom_level = clamp(Gvars.settings.zoom_level + 0.25, 0.25, 4.0)
handled = true
elif event.keycode == KEY_0:
Gvars.settings.zoom_level = 1.0
handled = true

if handled:
var cam = get_viewport().get_camera_2d()
if is_instance_valid(cam):
cam.zoom = Vector2(Gvars.settings.zoom_level, Gvars.settings.zoom_level)
# === END GLOBAL CAMERA ZOOM ===
