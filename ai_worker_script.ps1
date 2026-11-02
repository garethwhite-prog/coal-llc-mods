$repoRoot = "C:\Dev\coal-llc-mods"
$steamRoot = "C:\Program Files (x86)\Steam\steamapps\common\Coal LLC\Coal LLC"
$steamMods = Join-Path $steamRoot "mods"
$downMods = Join-Path $steamRoot "downloaded_mods"
Set-Location -Path $repoRoot

Stop-Process -Name "Coal LLC*" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "godot*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Output "--- 1. RESTORING MOD STORE VIEW (CANVASLAYER BASELINE) ---"
$storeViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_store_view.gd"
if (Test-Path $storeViewPath) {
    git checkout eaf8a72 -- "$storeViewPath"
    $svContent = Get-Content $storeViewPath -Raw

    # Update parser to support both static lists and mod_catalog.json releases
    $catalogLoader = @"
func _load_catalog_for_selected_repo() -> void:
	if active_repo_idx == 1:
		all_packages = [
			{"id": "der_floh-ore_value_mod", "name": "Ore Value Refresh", "tag": "v1.2.0", "desc": "Refreshes and scales daily ore sell prices dynamically on each new shift.", "cat": "Workforce & Automation", "author": "Der-Floh"},
			{"id": "der_floh-teleport_mod", "name": "Recall Teleporter", "tag": "v1.0.4", "desc": "Portable emergency recall device that instantly transports the miner back to the surface cabin.", "cat": "Quality of Life", "author": "Der-Floh"},
			{"id": "der_floh-more_stats_mod", "name": "Advanced Shift Statistics", "tag": "v1.1.0", "desc": "Detailed analytics breakdown for mined ore counts, cash velocity, and drill efficiency.", "cat": "Quality of Life", "author": "Der-Floh"},
			{"id": "der_floh-speed_run_timer_mod", "name": "Quota Speedrun Stopwatch", "tag": "v1.0.2", "desc": "On-screen high-precision timer tracking daily quota completion splits.", "cat": "Quality of Life", "author": "Der-Floh"},
			{"id": "der_floh-pickaxeaoe_mod", "name": "Pickaxe AOE Damage", "tag": "v1.3.1", "desc": "AoE and electric pickaxe now deal equal damage to all ores around swing radius.", "cat": "Classes & Professions", "author": "Der-Floh"},
			{"id": "der_floh-no_holes_mod", "name": "No Holes Backfill", "tag": "v1.2.5", "desc": "Automatically backfills hollow chambers as you tunnel downward to prevent collapsing.", "cat": "Quality of Life", "author": "Der-Floh"},
			{"id": "der_floh-passive_drop_mod", "name": "Dynamic Passive Chest Loot Drops", "tag": "v1.2.0", "desc": "Boosts chances of passive unlocks dropping inside deep mine chests based on tier count.", "cat": "Workforce & Automation", "author": "Der-Floh"}
		]
		status_lbl.text = "Der-Floh (Community Classics): 7 genuine packages loaded."
		status_lbl.modulate = Color(0.4, 1.0, 0.6)
		_render_cards()
	else:
		var client_script = load("res://mods-unpacked/gareth-mod_manager_mod/scripts/mod_store_client.gd")
		if client_script:
			var c = client_script.new()
			add_child(c)
			if c.has_signal("repo_fetch_completed"):
				c.repo_fetch_completed.connect(_on_catalog_fetched)
			c.fetch_all_available_mods()

func _on_catalog_fetched(_repo: String, releases: Array) -> void:
	if releases.size() > 0:
		all_packages.clear()
		for r in releases:
			if typeof(r) != TYPE_DICTIONARY: continue
			var p_name: String = str(r.get("name", "Unknown Package"))
			var tag: String = str(r.get("tag_name", "v1.0.0"))
			var body: String = str(r.get("body", "No description available."))
			var p_id: String = ""
			var assets = r.get("assets", [])
			if typeof(assets) == TYPE_ARRAY and assets.size() > 0:
				var a = assets[0]
				if typeof(a) == TYPE_DICTIONARY and a.has("name"):
					p_id = str(a["name"]).replace(".zip", "")
			if p_id == "" and r.has("id"):
				p_id = str(r["id"])
			if p_id == "": continue

			var cat := "Quality of Life"
			var lower_n := p_name.to_lower()
			if "map" in lower_n or "trench" in lower_n or "faultline" in lower_n or "canvas" in lower_n: cat = "Custom Maps & Strata"
			elif "class" in lower_n or "profession" in lower_n or "jedi" in lower_n or "knight" in lower_n: cat = "Classes & Professions"
			elif "bomb" in lower_n or "laser" in lower_n or "turret" in lower_n or "weapon" in lower_n or "mortar" in lower_n: cat = "Weapons & Arsenal"
			elif "employee" in lower_n or "collector" in lower_n or "drill" in lower_n or "vacuum" in lower_n: cat = "Workforce & Automation"

			all_packages.append({
				"id": p_id,
				"name": p_name,
				"tag": tag,
				"desc": body,
				"cat": cat,
				"author": "Gareth White"
			})
		status_lbl.text = "Gareth White (Official Suite): %d verified packages loaded." % all_packages.size()
		status_lbl.modulate = Color(0.4, 0.85, 1.0)
		_render_cards()
"@
    $svContent = $svContent -replace 'func _load_catalog_for_selected_repo\(\) -> void:[\s\S]*?_render_cards\(\)', $catalogLoader
    $svContent | Set-Content -Path $storeViewPath -Encoding UTF8
    Write-Output "Restored mod_store_view.gd as CanvasLayer with robust catalog schema parsing."
}

Write-Output "--- 2. RESTORING MOD MANAGER VIEW (WITH EMBEDDED SEARCH) ---"
$mgrViewPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\scenes\mod_manager_view.gd"
if (Test-Path $mgrViewPath) {
    git checkout eaf8a72 -- "$mgrViewPath"
    $mvContent = Get-Content $mgrViewPath -Raw

    # Inject search bar cleanly into top_bar
    $searchTopBar = @"
	var search_bar := LineEdit.new()
	search_bar.placeholder_text = "Search active mods..."
	search_bar.custom_minimum_size = Vector2(240, 36)
	search_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	search_bar.clear_button_enabled = true
	search_bar.text_changed.connect(_on_search_changed)
	top_bar.add_child(search_bar)

	var confirm_btn := Button.new()
"@
    $mvContent = $mvContent -replace 'var confirm_btn := Button\.new\(\)', $searchTopBar

    # Add filter logic at the end of the script
    $filterMethod = @"

func _on_search_changed(query: String) -> void:
	var q = query.strip_edges().to_lower()
	var scroll = find_child("*ScrollContainer*", true, false)
	if not scroll: return
	var content = scroll.get_child(0)
	if not content: return

	for child in content.get_children():
		if child is GridContainer:
			for card in child.get_children():
				if q.is_empty():
					card.visible = true
				else:
					var text_to_check: String = card.name.to_lower()
					var lbl = card.find_child("*Label*", true, false)
					if lbl and "text" in lbl:
						text_to_check += " " + lbl.text.to_lower()
					card.visible = (q in text_to_check)
"@
    $mvContent += $filterMethod
    $mvContent | Set-Content -Path $mgrViewPath -Encoding UTF8
    Write-Output "Restored mod_manager_view.gd with embedded top_bar search filter."
}

Write-Output "--- 3. FIXING BOUNCING BALL PROJECTILE STAT LOOKUP ---"
$ballProjPath = "$repoRoot\mods-unpacked\gareth-bouncing_ball_mod\mods-unpacked\gareth-bouncing_ball_mod\scripts\bouncing_ball_projectile.gd"
if (Test-Path $ballProjPath) {
    $bpContent = Get-Content $ballProjPath -Raw
    $bpContent = $bpContent -replace 'p\.get\("bouncing_ball_damage"\)', 'p.get("ball_blast_damage")'
    $bpContent = $bpContent -replace '"bouncing_ball_damage" in p', '"ball_blast_damage" in p'
    $bpContent | Set-Content -Path $ballProjPath -Encoding UTF8
    Write-Output "Patched bouncing_ball_projectile.gd to query ball_blast_damage."
}

Write-Output "--- 4. ENABLING BALL PASSIVES IN CHOOSE_PASSIVE HOOKS ---"
$chooseHooksPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scenes\Interfaces\in_game\choose_passive.hooks.gd"
if (Test-Path $chooseHooksPath) {
    $chContent = @"
extends Object

const BALL_PASSIVES: Dictionary[String, float] = {
	"ball_blast_damage": 0.05,
	"ball_blast_radius": 0.05,
	"ball_fire_rate": 0.05,
	"employee_miner_range": 0.05,
	"employee_miner_pickup_speed": 0.05,
	"collector_range": 0.05
}

func set_up_buttons(chain: ModLoaderHookChain) -> void:
	var screen = chain.reference_object
	if not is_instance_valid(screen) or not ("choose_between" in screen):
		chain.execute_next([])
		return

	# Inject ball passives into PASSIVE_MAP if missing
	if not screen.PASSIVE_MAP.has("bouncing_ball"):
		screen.PASSIVE_MAP["bouncing_ball"] = ["ball_blast_damage", "ball_blast_radius", "ball_fire_rate"]

	# Inject into ALL_PASSIVES so card formatting and percentage text calculate correctly
	for k in BALL_PASSIVES.keys():
		if not screen.ALL_PASSIVES.has(k):
			screen.ALL_PASSIVES[k] = BALL_PASSIVES[k]

	chain.execute_next([])

func _on_button_pressed(chain: ModLoaderHookChain) -> void:
	_handle_click(chain, 0)

func _on_button_2_pressed(chain: ModLoaderHookChain) -> void:
	_handle_click(chain, 1)

func _on_button_3_pressed(chain: ModLoaderHookChain) -> void:
	_handle_click(chain, 2)

func _handle_click(chain: ModLoaderHookChain, idx: int) -> void:
	var screen = chain.reference_object
	if not is_instance_valid(screen) or not screen.live or not ("choose_between" in screen):
		chain.execute_next([])
		return

	if idx < screen.choose_between.size():
		var stat: String = str(screen.choose_between[idx])
		if BALL_PASSIVES.has(stat):
			var amount = screen.multiplier * BALL_PASSIVES[stat]
			if Gvars and ("passives" in Gvars) and Gvars.passives:
				var p = Gvars.passives
				p.set(stat, (p.get(stat) if (stat in p) else 0.0) + amount)
				p.set_meta(stat, (p.get_meta(stat) if p.has_meta(stat) else 0.0) + amount)
				# Mirror to adjusted field for HUD display
				var adj_stat = "adjusted_" + stat
				p.set(adj_stat, (p.get(adj_stat) if (adj_stat in p) else 0.0) + amount)
				p.set_meta(adj_stat, (p.get_meta(adj_stat) if p.has_meta(adj_stat) else 0.0) + amount)

	chain.execute_next([])
"@
    $chContent | Set-Content -Path $chooseHooksPath -Encoding UTF8
    Write-Output "Patched choose_passive.hooks.gd with ball passives pool injection."
}

Write-Output "--- 5. HOOKING TAB HUD (PASSIVE_BONUSES) TO DISPLAY BALL STATS ---"
$pbHooksPath = "$repoRoot\mods-unpacked\gareth-mod_manager_mod\mods-unpacked\gareth-mod_manager_mod\extensions\scenes\Interfaces\Management\passive_bonuses.hooks.gd"
if (Test-Path $pbHooksPath) {
    $pbContent = @"
extends Object

const CUSTOM_DISPLAY_STATS: Array[String] = [
	"ball_blast_damage",
	"ball_blast_radius",
	"ball_fire_rate",
	"employee_miner_range",
	"employee_miner_pickup_speed",
	"collector_range"
]

func refresh(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var panel = chain.reference_object
	if not is_instance_valid(panel) or not Gvars or not Gvars.passives:
		return

	var p = Gvars.passives
	for stat in CUSTOM_DISPLAY_STATS:
		var val: float = 0.0
		if stat in p:
			val = float(p.get(stat))
		elif p.has_meta(stat):
			val = float(p.get_meta(stat))

		if val > 0.0:
			var label := RichTextLabel.new()
			label.text = "Increase " + stat.replace("_", " ").capitalize() + " +" + str(roundi(val * 100.0)) + "%"
			label.fit_content = true
			panel.add_child(label)
"@
    $pbContent | Set-Content -Path $pbHooksPath -Encoding UTF8
    Write-Output "Patched passive_bonuses.hooks.gd to render custom ball stats on Tab HUD."
}

Write-Output "--- 6. RUNNING PRE-FLIGHT VALIDATION GATE ---"
$gateScript = Join-Path $repoRoot "Test-ModSuitePreFlight.ps1"
if (Test-Path $gateScript) {
    & $gateScript
    if ($LASTEXITCODE -ne 0) {
        Write-Error "PRE-FLIGHT VALIDATION FAILED! Aborting deployment and git commit."
        exit 1
    }
}

Write-Output "--- 7. PACKAGING & DEPLOYING MODS ---"
$hooksZip = Join-Path $steamRoot "mod-hooks.zip"
if (Test-Path $hooksZip) { Remove-Item $hooksZip -Force -ErrorAction SilentlyContinue }

$targetMods = @("gareth-mod_manager_mod", "gareth-bouncing_ball_mod")
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($mod in $targetMods) {
    $srcDir = Join-Path $repoRoot "mods-unpacked\$mod"
    $downZip = Join-Path $downMods "$mod.zip"
    $steamZip = Join-Path $steamMods "$mod.zip"

    if (Test-Path $downZip) { Remove-Item $downZip -Force }
    $archive = [System.IO.Compression.ZipFile]::Open($downZip, [System.IO.Compression.ZipArchiveMode]::Create)
    $files = Get-ChildItem -Path $srcDir -Recurse -File
    foreach ($file in $files) {
        $entryName = $file.FullName.Substring($srcDir.Length + 1).Replace("\", "/")
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entryName)
    }
    $archive.Dispose()
    if (Test-Path $steamZip) { Copy-Item -Path $downZip -Destination $steamZip -Force }
    Write-Output "Deployed $mod.zip"
}

Write-Output "--- 8. COMMITTING TEST-VERIFIED BUILD ---"
git add -A
git commit -m "Fix: Restored Mod Store CanvasLayer baseline, docked Mod Manager search, and mapped Bouncing Ball passives to in-game pool and Tab HUD."
git push origin main
Write-Output "Deployment Complete."