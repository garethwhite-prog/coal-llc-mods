Clear-Host;

# ==============================================================================
# Coal LLC - Add 4-Row ScrollContainer to gareth-more_inventory_slots_mod
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"

$modName    = "gareth-more_inventory_slots_mod"
$outerDir   = "$repo\mods-unpacked\$modName"
$innerDir   = "$outerDir\mods-unpacked\$modName"
$zipPath    = "$steamMods\$modName.zip"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot processes..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600

Write-Host "`n>>> 2. Creating directory structures..." -ForegroundColor Cyan
$hooksDir  = "$innerDir\extensions\scenes\Interfaces"
$helperDir = "$innerDir\helpers"
if (-not (Test-Path $hooksDir))  { New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null }
if (-not (Test-Path $helperDir)) { New-Item -ItemType Directory -Path $helperDir -Force | Out-Null }

Write-Host "`n>>> 3. Creating InventoryScrollHelper.gd..." -ForegroundColor Cyan
$helperPath = "$helperDir\InventoryScrollHelper.gd"
@'
class_name InventoryScrollHelper
extends RefCounted

static func setup_scroll(window: GridContainer) -> void:
	if not window or not is_instance_valid(window):
		return
	_apply_scroll_wrapper.call_deferred(window)

static func update_scroll(window: GridContainer) -> void:
	if not window or not is_instance_valid(window):
		return
	_adjust_scroll_size.call_deferred(window)

static func _apply_scroll_wrapper(window: GridContainer) -> void:
	if not window or not is_instance_valid(window):
		return

	var parent = window.get_parent()
	if not parent or not is_instance_valid(parent):
		return

	if parent is ScrollContainer or parent.name == "InventoryScrollContainer":
		_adjust_scroll_size(window)
		return

	var idx = window.get_index()
	var orig_owner = window.owner

	var scroll = ScrollContainer.new()
	scroll.name = "InventoryScrollContainer"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	scroll.size_flags_horizontal = window.size_flags_horizontal
	scroll.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var dims = _calculate_dimensions(window)
	scroll.custom_minimum_size = dims

	window.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	window.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	parent.remove_child(window)
	parent.add_child(scroll)
	parent.move_child(scroll, idx)
	scroll.add_child(window)

	if orig_owner:
		scroll.owner = orig_owner
		window.owner = orig_owner

	_wire_slot_mouse_scroll(window, scroll)

static func _adjust_scroll_size(window: GridContainer) -> void:
	if not window or not is_instance_valid(window):
		return
	var scroll = window.get_parent() as ScrollContainer
	if not scroll:
		return
	var dims = _calculate_dimensions(window)
	scroll.custom_minimum_size = dims
	_wire_slot_mouse_scroll(window, scroll)

static func _calculate_dimensions(window: GridContainer) -> Vector2:
	var slots = window.get_children()
	var slot_w: float = 64.0
	var slot_h: float = 64.0
	var h_sep: float = window.get_theme_constant("h_separation")
	var v_sep: float = window.get_theme_constant("v_separation")
	if h_sep <= 0.0: h_sep = 6.0
	if v_sep <= 0.0: v_sep = 6.0

	if slots.size() > 0 and slots[0] is Control:
		var s = slots[0] as Control
		if s.size.x > 10.0: slot_w = s.size.x
		elif s.custom_minimum_size.x > 10.0: slot_w = s.custom_minimum_size.x
		if s.size.y > 10.0: slot_h = s.size.y
		elif s.custom_minimum_size.y > 10.0: slot_h = s.custom_minimum_size.y

	var total_w = (slot_w * 10.0) + (h_sep * 9.0) + 26.0
	var max_h   = (slot_h * 4.0) + (v_sep * 3.0) + 4.0
	return Vector2(total_w, max_h)

static func _wire_slot_mouse_scroll(window: GridContainer, scroll: ScrollContainer) -> void:
	for child in window.get_children():
		if child is Control and not child.has_meta("scroll_wired"):
			child.set_meta("scroll_wired", true)
			child.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.is_pressed():
					var v_bar = scroll.get_v_scroll_bar()
					if not v_bar:
						return
					if event.button_index == MOUSE_BUTTON_WHEEL_UP:
						v_bar.value -= v_bar.page * 0.25
					elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
						v_bar.value += v_bar.page * 0.25
			)
'@ | Set-Content -Path $helperPath -Encoding UTF8
Write-Host "Created: $helperPath" -ForegroundColor Green

Write-Host "`n>>> 4. Creating InventoryWindow.hooks.gd..." -ForegroundColor Cyan
$hookPath = "$hooksDir\InventoryWindow.hooks.gd"
@'
extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next()
	var window = chain.reference_object
	var helper = load("res://mods-unpacked/gareth-more_inventory_slots_mod/helpers/InventoryScrollHelper.gd")
	if helper:
		helper.setup_scroll(window)

func load_inventory(chain: ModLoaderHookChain) -> void:
	chain.execute_next()
	var window = chain.reference_object
	var helper = load("res://mods-unpacked/gareth-more_inventory_slots_mod/helpers/InventoryScrollHelper.gd")
	if helper:
		helper.update_scroll(window)
'@ | Set-Content -Path $hookPath -Encoding UTF8
Write-Host "Created: $hookPath" -ForegroundColor Green

Write-Host "`n>>> 5. Updating mod_main.gd to install script hook..." -ForegroundColor Cyan
$modMainPath = "$innerDir\mod_main.gd"
$modMainContent = @'
extends Node

func _init() -> void:
	ModLoaderMod.install_script_hooks(
		"res://scenes/Interfaces/InventoryWindow.gd",
		"res://mods-unpacked/gareth-more_inventory_slots_mod/extensions/scenes/Interfaces/InventoryWindow.hooks.gd"
	)

func _ready() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks:
		return

	var cleaned: Array[Item] = []
	for it in item_unlocks.all_bonus_items:
		if it and it.itemID.begins_with("AddInventorySlots") and not it.itemID in ["AddInventorySlots1", "AddInventorySlots2", "AddInventorySlots3"]:
			continue
		cleaned.append(it)
	item_unlocks.all_bonus_items = cleaned

	var target_idx = -1
	for i in range(item_unlocks.all_bonus_items.size()):
		if item_unlocks.all_bonus_items[i] and item_unlocks.all_bonus_items[i].itemID == "AddInventorySlots3":
			target_idx = i
			break

	var new_items: Array[Item] = []
	for t in range(4, 11):
		var it = load("res://mods-unpacked/gareth-more_inventory_slots_mod/items/add_inventory_slots_%d.tres" % t)
		if it:
			new_items.append(it)
			if not it in item_unlocks.all_items:
				item_unlocks.all_items.append(it)

	if target_idx != -1:
		for offset in range(new_items.size()):
			item_unlocks.all_bonus_items.insert(target_idx + 1 + offset, new_items[offset])
	else:
		for it in new_items:
			item_unlocks.all_bonus_items.append(it)
'@
Set-Content -Path $modMainPath -Value $modMainContent -Encoding UTF8
Write-Host "Updated: $modMainPath" -ForegroundColor Green

Write-Host "`n>>> 6. Purging mod-hooks.zip to instrument InventoryWindow.gd..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
    Remove-Item -Path $hookZip -Force
    Write-Host "Deleted stale: $hookZip" -ForegroundColor Green
}

Write-Host "`n>>> 7. Repackaging $modName.zip..." -ForegroundColor Cyan
if (Test-Path $zipPath) { Remove-Item -Path $zipPath -Force }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$stream  = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $outerDir -Recurse -File)) {$entryName = $f.FullName.Substring($outerDir.Length + 1).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "Repacked: $zipPath" -ForegroundColor Green

Write-Host "`n>>> 8. Git staging, committing, and pushing..." -ForegroundColor Cyan
git add -A
git commit -m "Constrain inventory slots to 4 visible rows with ScrollContainer and mouse wheel scrolling in more_inventory_slots_mod"
git push origin main

Write-Host "`nDeployment complete! Launch Coal LLC to test inventory scrolling." -ForegroundColor Green