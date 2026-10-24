Clear-Host

# ==============================================================================
# Coal LLC - Part 3: Equipment Shop Search/Sort & Passive Effects Expansion
# ==============================================================================

$repo       = "C:\Dev\coal-llc-mods"
$steamRoot  = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods  = "$steamRoot\mods"
$hookZip    = "$steamRoot\mod-hooks.zip"
$mmInner    = "$repo\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod"

Set-Location $repo

Write-Host ">>> 1. Terminating running Coal LLC / Godot instances..." -ForegroundColor Cyan
Get-Process -Name "Coal LLC*", "godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600

# ------------------------------------------------------------------------------
# 2. INSTALL PASSIVE EFFECTS EXPANSION HOOK
# ------------------------------------------------------------------------------
Write-Host "`n>>> 2. Installing PassiveBonuses expansion hook..." -ForegroundColor Cyan
$pbHookDir = "$mmInner\extensions\scenes\Interfaces\Management"
if (-not (Test-Path $pbHookDir)) { New-Item -ItemType Directory -Path $pbHookDir -Force | Out-Null }
$pbHookPath = "$pbHookDir\passive_bonuses.hooks.gd"

@'
extends Object

func refresh(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var pb = chain.reference_object
	if not is_instance_valid(pb) or not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return

	var p = Gvars.passives

	# Worker passives
	var worker_stats = {
		"Employee Miner Speed": p.employee_miner_speed,
		"Employee Miner Damage": p.employee_miner_damage,
		"Employee Collector Speed": p.employee_collector_speed,
		"Employee Collector Capacity": p.employee_collector_capacity
	}
	for s_name in worker_stats.keys():
		var val: float = float(worker_stats[s_name])
		if val > 0.0:
			var lbl = RichTextLabel.new()
			lbl.text = "%s +%d%%" % [s_name, roundi(val * 100)]
			lbl.fit_content = true
			pb.add_child(lbl)

	# Custom class weapon passives
	for stat_key in ["sword_damage", "sword_speed", "sword_range", "jedi_saber_damage", "jedi_saber_speed"]:
		var s_val: float = 0.0
		if p.has_meta(stat_key):
			s_val = float(p.get_meta(stat_key))
		elif stat_key in p:
			s_val = float(p.get(stat_key))

		if s_val > 0.0:
			var c_lbl = RichTextLabel.new()
			c_lbl.text = "Increase %s +%d%%" % [stat_key.replace("_", " ").capitalize(), roundi(s_val * 100)]
			c_lbl.fit_content = true
			pb.add_child(c_lbl)
'@ | Set-Content -Path $pbHookPath -Encoding UTF8
Write-Host "  Created: passive_bonuses.hooks.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. INSTALL SEARCH BAR & REVERSIBLE SORTER IN MANAGEMENT SCREEN
# ------------------------------------------------------------------------------
Write-Host "`n>>> 3. Updating management_screen.hooks.gd with Search and Sort..." -ForegroundColor Cyan
$mgmtHookDir = "$mmInner\extensions\scenes\Stages"
if (-not (Test-Path $mgmtHookDir)) { New-Item -ItemType Directory -Path $mgmtHookDir -Force | Out-Null }
$mgmtHookPath = "$mgmtHookDir\management_screen.hooks.gd"

@'
extends Object

var search_input: LineEdit = null
var sort_dropdown: OptionButton = null

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	var screen = chain.reference_object
	if is_instance_valid(screen):
		_ensure_search_and_sort_bar(screen)
		_sort_equipment_catalog()
	chain.execute_next([])
	if is_instance_valid(screen):
		Callable(self, "_apply_filter").call_deferred(screen)

func _ensure_search_and_sort_bar(screen: Node) -> void:
	if not is_instance_valid(screen):
		return
	var shop = screen.find_child("EquipmentShop", true, false)
	if not shop:
		return

	var scroll = shop.get_parent()
	var v_box = scroll.get_parent() if scroll else null
	if not v_box:
		return

	if v_box.has_node("EquipmentFilterBar"):
		var existing_bar = v_box.get_node("EquipmentFilterBar")
		search_input = existing_bar.get_node_or_null("SearchInput")
		sort_dropdown = existing_bar.get_node_or_null("SortOption")
		return

	var bar = HBoxContainer.new()
	bar.name = "EquipmentFilterBar"
	bar.theme_override_constants.set("separation", 12)

	var search = LineEdit.new()
	search.name = "SearchInput"
	search.placeholder_text = "Search equipment by name or type..."
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.clear_button_enabled = true
	search.text_changed.connect(func(_new_text): _apply_filter(screen))
	bar.add_child(search)
	search_input = search

	var sort_btn = OptionButton.new()
	sort_btn.name = "SortOption"
	sort_btn.add_item("Sort: Tier (Default)", 0)
	sort_btn.add_item("Sort: Price (Low to High)", 1)
	sort_btn.add_item("Sort: Price (High to Low)", 2)
	sort_btn.add_item("Sort: Alphabetical (A-Z)", 3)
	sort_btn.item_selected.connect(func(_idx):
		_sort_equipment_catalog()
		if screen.has_method("load_equipment_shop"):
			screen.load_equipment_shop()
	)
	bar.add_child(sort_btn)
	sort_dropdown = sort_btn

	v_box.add_child(bar)
	v_box.move_child(bar, scroll.get_index())

func _apply_filter(screen: Node) -> void:
	if not is_instance_valid(screen) or not is_instance_valid(search_input):
		return
	var query: String = search_input.text.strip_edges().to_lower()
	var shop = screen.find_child("EquipmentShop", true, false)
	if not shop:
		return

	for card in shop.get_children():
		if not is_instance_valid(card):
			continue
		if query.is_empty():
			card.visible = true
			continue
		var matches := false
		if "item" in card and card.item:
			var nm: String = str(card.item.itemName).to_lower()
			var id: String = str(card.item.itemID).to_lower()
			var tp: String = str(card.item.itemType).to_lower()
			var desc: String = str(card.item.itemDescription).to_lower()
			if query in nm or query in id or query in tp or query in desc:
				matches = true
		card.visible = matches

func _sort_equipment_catalog() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks or not ("all_equipment_items" in item_unlocks) or not (item_unlocks.all_equipment_items is Array):
		return

	var original_list: Array = item_unlocks.all_equipment_items
	if original_list.is_empty():
		return

	var mode: int = 0
	if is_instance_valid(sort_dropdown):
		mode = sort_dropdown.selected

	var indexed_items: Array = []
	for i in range(original_list.size()):
		var it = original_list[i]
		if is_instance_valid(it):
			var rank: int = _get_tier_rank(it)
			indexed_items.append({ "item": it, "rank": rank, "orig_idx": i })

	match mode:
		0: # Tier Default
			indexed_items.sort_custom(func(a, b):
				if a["rank"] != b["rank"]:
					return a["rank"] < b["rank"]
				return a["orig_idx"] < b["orig_idx"]
			)
		1: # Price Low to High
			indexed_items.sort_custom(func(a, b):
				var pa = float(a["item"].itemBuyPrice)
				var pb = float(b["item"].itemBuyPrice)
				if pa != pb:
					return pa < pb
				return a["orig_idx"] < b["orig_idx"]
			)
		2: # Price High to Low
			indexed_items.sort_custom(func(a, b):
				var pa = float(a["item"].itemBuyPrice)
				var pb = float(b["item"].itemBuyPrice)
				if pa != pb:
					return pa > pb
				return a["orig_idx"] < b["orig_idx"]
			)
		3: # Alphabetical
			indexed_items.sort_custom(func(a, b):
				var na = str(a["item"].itemName).to_lower()
				var nb = str(b["item"].itemName).to_lower()
				return na < nb
			)

	var sorted_list: Array[Item] = []
	for entry in indexed_items:
		sorted_list.append(entry["item"])

	item_unlocks.all_equipment_items = sorted_list

func _get_tier_rank(it: Item) -> int:
	var id: String = str(it.itemID).to_lower()
	var nm: String = str(it.itemName).to_lower()
	var s: String = id + " " + nm

	if "shoddy" in s: return 1
	if "copper" in s: return 2
	if "iron" in s: return 3
	if "sapphire" in s: return 4
	if "emerald" in s: return 5
	if "silver" in s: return 6
	if "amethyst" in s: return 7
	if "gold" in s: return 8
	if "ruby" in s: return 9
	if "pinkdiamond" in s or "pink_diamond" in s or "pink diamond" in s: return 11
	if "diamond" in s: return 10
	if "spinel" in s: return 12
	if "uranium" in s: return 13
	if "moonstone" in s: return 14
	if "onyx" in s: return 15

	if ("ladder" in s or "platform" in s or "bomb" in s or "dynamite" in s or 
		"mortar" in s or "drill" in s or "teleporter" in s or "whistle" in s or 
		"gravity" in s or "water_staff" in s or "water_gun" in s):
		return 0

	return 16
'@ | Set-Content -Path $mgmtHookPath -Encoding UTF8
Write-Host "  Updated: management_screen.hooks.gd" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. PURGE HOOK CACHE & REPACK MOD MANAGER
# ------------------------------------------------------------------------------
Write-Host "`n>>> 4. Purging mod-hooks.zip..." -ForegroundColor Cyan
if (Test-Path $hookZip) {
	Remove-Item -Path $hookZip -Force
	Write-Host "  Removed: $hookZip" -ForegroundColor Green
}

Write-Host "`n>>> 5. Repackaging gareth-mod_manager_mod..." -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression.FileSystem

$src = "$repo\mods-unpacked\gareth-mod_manager_mod"
$zip = "$steamMods\gareth-mod_manager_mod.zip"
if (Test-Path $zip) { Remove-Item -Path $zip -Force }

$stream  = [System.IO.File]::Open($zip, [System.IO.FileMode]::CreateNew)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in (Get-ChildItem -Path $src -Recurse -File)) {
	$entryName = $f.FullName.Substring($src.Length + 1).Replace("\", "/")
	[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $f.FullName, $entryName) | Out-Null
}
$archive.Dispose()
$stream.Dispose()
Write-Host "  Repacked: gareth-mod_manager_mod.zip" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 5. GIT STAGING, COMMIT & PUSH
# ------------------------------------------------------------------------------
Write-Host "`n>>> 6. Staging, committing and pushing Part 3 to GitHub..." -ForegroundColor Cyan
git add -A
git commit -m "Part 3: Add equipment shop search/sort filter bar and expand passive effects panel for worker & weapon stats"
git push origin main

Write-Host "`nPart 3 deployment complete!" -ForegroundColor Green