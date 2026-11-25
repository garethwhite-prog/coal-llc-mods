extends Node

const MOD_DIR := "gareth-weapon_workers_mod"

const BRANCHES: Array[Dictionary] = [
    {
        "id": "pickaxe", "label": "Pickaxe", "set_name": "BROWN SET", "region_sub": "UK & USA • Pickaxe", "style": "melee",
        "set_color": Color(0.55, 0.27, 0.08, 1.0), "text_dark": false, "color": Color(0.76, 0.48, 0.28, 1.0),
        "tex": "res://assets/Equipment/Pickaxe-15-onyx.png",
        "tiers": [
            { "name": "Old Kent / Medit. Ave",   "cost": 2500.0,      "dmg": 120.0,      "rate": 0.90, "aoe": 1, "winged": false },
            { "name": "Whitechapel / Baltic",    "cost": 45000.0,     "dmg": 2800.0,     "rate": 0.65, "aoe": 2, "winged": false },
            { "name": "Borough Pit Enforcer",    "cost": 1200000.0,   "dmg": 85000.0,    "rate": 0.45, "aoe": 3, "winged": false },
            { "name": "Seraphic Brown Lord",     "cost": 45000000.0,  "dmg": 4200000.0,  "rate": 0.25, "aoe": 4, "winged": true }
        ]
    },
    {
        "id": "axe", "label": "Battleaxe", "set_name": "LIGHT BLUE SET", "region_sub": "UK & USA • Battleaxe", "style": "melee",
        "set_color": Color(0.53, 0.81, 0.96, 1.0), "text_dark": true, "color": Color(0.58, 0.86, 0.98, 1.0),
        "tex": "res://assets/Equipment/battleaxes/battleaxe_15_onyx.png",
        "tiers": [
            { "name": "The Angel / Oriental",    "cost": 3200.0,      "dmg": 180.0,      "rate": 1.05, "aoe": 2, "winged": false },
            { "name": "Euston Rd / Vermont",     "cost": 60000.0,     "dmg": 4200.0,     "rate": 0.78, "aoe": 3, "winged": false },
            { "name": "Pentonville / Conn.",     "cost": 1600000.0,   "dmg": 130000.0,   "rate": 0.52, "aoe": 4, "winged": false },
            { "name": "Valkyrie Sky-Cleaver",    "cost": 60000000.0,  "dmg": 6500000.0,  "rate": 0.30, "aoe": 5, "winged": true }
        ]
    },
    {
        "id": "brawler", "label": "Gloves & Kick", "set_name": "PINK SET", "region_sub": "UK & USA • Brawler", "style": "melee",
        "set_color": Color(0.85, 0.11, 0.48, 1.0), "text_dark": false, "color": Color(0.96, 0.52, 0.78, 1.0),
        "tex": "res://assets/Equipment/boxing_gloves/boxing_gloves_15_onyx.png",
        "tiers": [
            { "name": "Pall Mall / St. Charles", "cost": 2800.0,      "dmg": 145.0,      "rate": 0.75, "aoe": 2, "winged": false },
            { "name": "Whitehall / States Ave",  "cost": 52000.0,     "dmg": 3400.0,     "rate": 0.55, "aoe": 3, "winged": false },
            { "name": "Northumb'ld / Virginia",  "cost": 1400000.0,   "dmg": 105000.0,   "rate": 0.36, "aoe": 4, "winged": false },
            { "name": "Ascended Rose Champ",     "cost": 52000000.0,  "dmg": 5100000.0,  "rate": 0.20, "aoe": 5, "winged": true }
        ]
    },
    {
        "id": "pistol", "label": "Pistol & Shotgun", "set_name": "ORANGE SET", "region_sub": "UK & USA • Firearms", "style": "projectile",
        "set_color": Color(0.97, 0.54, 0.08, 1.0), "text_dark": true, "color": Color(1.00, 0.68, 0.32, 1.0),
        "tex": "res://assets/Equipment/guns/shotguns/shotgun_15_onyx.png",
        "tiers": [
            { "name": "Bow St / St. James Pl",   "cost": 4000.0,      "dmg": 210.0,      "rate": 0.85, "aoe": 2, "winged": false },
            { "name": "Marlborough / Tenn.",     "cost": 75000.0,     "dmg": 5100.0,     "rate": 0.62, "aoe": 3, "winged": false },
            { "name": "Vine St / New York Ave",  "cost": 2000000.0,   "dmg": 165000.0,   "rate": 0.42, "aoe": 4, "winged": false },
            { "name": "Sun-Marshal Gunslinger",  "cost": 75000000.0,  "dmg": 8200000.0,  "rate": 0.24, "aoe": 5, "winged": true }
        ]
    },
    {
        "id": "minigun", "label": "Rifle & Minigun", "set_name": "RED SET", "region_sub": "UK & USA • Rotary Gun", "style": "beam",
        "set_color": Color(0.89, 0.14, 0.16, 1.0), "text_dark": false, "color": Color(0.98, 0.36, 0.38, 1.0),
        "tex": "res://assets/Equipment/guns/miniguns/minigun_15_onyx.png",
        "tiers": [
            { "name": "Strand / Kentucky Ave",   "cost": 5500.0,      "dmg": 160.0,      "rate": 0.45, "aoe": 2, "winged": false },
            { "name": "Fleet St / Indiana Ave",  "cost": 95000.0,     "dmg": 3900.0,     "rate": 0.32, "aoe": 3, "winged": false },
            { "name": "Trafalgar / Illinois",    "cost": 2600000.0,   "dmg": 125000.0,   "rate": 0.22, "aoe": 4, "winged": false },
            { "name": "Crimson Gatling Seraph",  "cost": 95000000.0,  "dmg": 6200000.0,  "rate": 0.14, "aoe": 5, "winged": true }
        ]
    },
    {
        "id": "staff", "label": "Magic Staff", "set_name": "YELLOW SET", "region_sub": "UK & USA • Arcane Staff", "style": "orb",
        "set_color": Color(0.99, 0.85, 0.16, 1.0), "text_dark": true, "color": Color(1.00, 0.90, 0.35, 1.0),
        "tex": "res://assets/Equipment/magic/staffs/15_onyx_staff.png",
        "tiers": [
            { "name": "Leicester / Atlantic",    "cost": 6000.0,      "dmg": 260.0,      "rate": 1.10, "aoe": 3, "winged": false },
            { "name": "Coventry / Ventnor Ave",  "cost": 110000.0,    "dmg": 6400.0,     "rate": 0.80, "aoe": 4, "winged": false },
            { "name": "Piccadilly / Marvin",     "cost": 3000000.0,   "dmg": 210000.0,   "rate": 0.55, "aoe": 5, "winged": false },
            { "name": "Solar Gold Archmage",     "cost": 110000000.0, "dmg": 10500000.0, "rate": 0.32, "aoe": 6, "winged": true }
        ]
    },
    {
        "id": "flame", "label": "Flamethrower", "set_name": "GREEN SET", "region_sub": "UK & USA • Thermal", "style": "beam",
        "set_color": Color(0.14, 0.55, 0.24, 1.0), "text_dark": false, "color": Color(0.32, 0.84, 0.48, 1.0),
        "tex": "res://assets/Equipment/alternative_guns/flamethrowers/flamethrower_15_onyx.png",
        "tiers": [
            { "name": "Regent St / Pacific Ave", "cost": 5000.0,      "dmg": 195.0,      "rate": 0.60, "aoe": 3, "winged": false },
            { "name": "Oxford St / N. Carolina", "cost": 90000.0,     "dmg": 4800.0,     "rate": 0.44, "aoe": 4, "winged": false },
            { "name": "Bond St / Pennsylvania",  "cost": 2400000.0,   "dmg": 155000.0,   "rate": 0.30, "aoe": 5, "winged": false },
            { "name": "Emerald Phoenix Seraph",  "cost": 90000000.0,  "dmg": 7800000.0,  "rate": 0.18, "aoe": 6, "winged": true }
        ]
    },
    {
        "id": "poison", "label": "Poison & Water", "set_name": "DARK BLUE SET", "region_sub": "UK & USA • Chemical", "style": "orb",
        "set_color": Color(0.08, 0.24, 0.68, 1.0), "text_dark": false, "color": Color(0.32, 0.52, 0.96, 1.0),
        "tex": "res://assets/Equipment/alternative_guns/poison_guns/poison_gun_15_onyx.png",
        "tiers": [
            { "name": "Park Lane / Park Place",  "cost": 4800.0,      "dmg": 185.0,      "rate": 0.70, "aoe": 3, "winged": false },
            { "name": "Mayfair / Boardwalk",     "cost": 85000.0,     "dmg": 4500.0,     "rate": 0.50, "aoe": 4, "winged": false },
            { "name": "Belgravia / Fifth Ave",   "cost": 2200000.0,   "dmg": 145000.0,   "rate": 0.35, "aoe": 5, "winged": false },
            { "name": "Sapphire Crown Hydra",    "cost": 85000000.0,  "dmg": 7200000.0,  "rate": 0.22, "aoe": 6, "winged": true }
        ]
    },
    {
        "id": "tank", "label": "Heavy Tank & Orb", "set_name": "STATIONS SET", "region_sub": "UK & USA • Railroads", "style": "explosive",
        "set_color": Color(0.14, 0.15, 0.18, 1.0), "text_dark": false, "color": Color(0.55, 0.60, 0.68, 1.0),
        "tex": "res://assets/Equipment/tanks/tank_15_onyx.png",
        "tiers": [
            { "name": "King's Cross / Reading",  "cost": 8500.0,      "dmg": 420.0,      "rate": 1.35, "aoe": 4, "winged": false },
            { "name": "Marylebone / Penn. RR",   "cost": 160000.0,    "dmg": 10500.0,    "rate": 1.00, "aoe": 5, "winged": false },
            { "name": "Fenchurch / B&O RR",      "cost": 4500000.0,   "dmg": 340000.0,   "rate": 0.72, "aoe": 6, "winged": false },
            { "name": "Liverpool / Short Line",  "cost": 160000000.0, "dmg": 17000000.0, "rate": 0.45, "aoe": 7, "winged": true }
        ]
    },
    {
        "id": "bouncing_ball", "label": "Bouncing Ball", "set_name": "UTILITIES SET", "region_sub": "UK & USA • Kinetic Grid", "style": "orb",
        "set_color": Color(0.84, 0.89, 0.92, 1.0), "text_dark": true, "color": Color(0.36, 0.90, 0.94, 1.0),
        "tex": "res://mods-unpacked/gareth-bouncing_ball_mod/textures/ball_15_onyx.png",
        "tiers": [
            { "name": "Electric Co. Slinger",    "cost": 7000.0,      "dmg": 340.0,      "rate": 1.00, "aoe": 3, "winged": false },
            { "name": "Water Works Ricochet",    "cost": 130000.0,    "dmg": 8400.0,     "rate": 0.74, "aoe": 4, "winged": false },
            { "name": "National Grid Dynamo",    "cost": 3600000.0,   "dmg": 275000.0,   "rate": 0.50, "aoe": 5, "winged": false },
            { "name": "Singularity Orbiter",     "cost": 130000000.0, "dmg": 13500000.0, "rate": 0.30, "aoe": 6, "winged": true }
        ]
    },
    {
        "id": "blade", "label": "Saber & Broadsword", "set_name": "LUXURY GOLD SET", "region_sub": "Super Tax • Royal Blade", "style": "melee",
        "set_color": Color(0.85, 0.66, 0.14, 1.0), "text_dark": true, "color": Color(0.98, 0.82, 0.34, 1.0),
        "tex": "res://assets/Equipment/Sword-Shoddy.png",
        "tiers": [
            { "name": "Super Tax / Luxury Guard","cost": 6500.0,      "dmg": 290.0,      "rate": 0.70, "aoe": 3, "winged": false },
            { "name": "Tower / Wall St Duelist", "cost": 120000.0,    "dmg": 7200.0,     "rate": 0.52, "aoe": 4, "winged": false },
            { "name": "Buckingham Paladin",      "cost": 3300000.0,   "dmg": 235000.0,   "rate": 0.35, "aoe": 5, "winged": false },
            { "name": "Seraphic Blade-Master",   "cost": 120000000.0, "dmg": 11800000.0, "rate": 0.20, "aoe": 6, "winged": true }
        ]
    },
    {
        "id": "laser_plasma", "label": "Laser & Plasma", "set_name": "MINT TEAL SET", "region_sub": "Central Bank • Laser", "style": "beam",
        "set_color": Color(0.04, 0.56, 0.50, 1.0), "text_dark": false, "color": Color(0.36, 0.98, 0.88, 1.0),
        "tex": "res://assets/Equipment/orbs/orb_15_onyx.png",
        "tiers": [
            { "name": "Threadneedle Photon",     "cost": 7500.0,      "dmg": 310.0,      "rate": 0.80, "aoe": 3, "winged": false },
            { "name": "Federal Mint Plasma",     "cost": 140000.0,    "dmg": 7800.0,     "rate": 0.58, "aoe": 4, "winged": false },
            { "name": "Fort Knox Treasury Ray",  "cost": 3800000.0,   "dmg": 255000.0,   "rate": 0.40, "aoe": 5, "winged": false },
            { "name": "Hyperion Star-Beam",      "cost": 140000000.0, "dmg": 12800000.0, "rate": 0.24, "aoe": 6, "winged": true }
        ]
    },
    {
        "id": "chrono", "label": "Chrono Harvester", "set_name": "CHEST INDIGO SET", "region_sub": "Community • Chrono", "style": "beam",
        "set_color": Color(0.22, 0.29, 0.68, 1.0), "text_dark": false, "color": Color(0.65, 0.88, 1.0, 1.0),
        "tex": "res://assets/Equipment/electric_pickaxes/electric_pickaxe_15_onyx.png",
        "tiers": [
            { "name": "Greenwich Meridian",      "cost": 8000.0,      "dmg": 330.0,      "rate": 0.75, "aoe": 3, "winged": false },
            { "name": "Times Square Weaver",     "cost": 150000.0,    "dmg": 8200.0,     "rate": 0.55, "aoe": 4, "winged": false },
            { "name": "Big Ben Timekeeper",      "cost": 4000000.0,   "dmg": 265000.0,   "rate": 0.38, "aoe": 5, "winged": false },
            { "name": "Epoch Sovereign",         "cost": 150000000.0, "dmg": 13200000.0, "rate": 0.22, "aoe": 6, "winged": true }
        ]
    },
    {
        "id": "void_fracker", "label": "Void & Fracker", "set_name": "ROYAL PURPLE SET", "region_sub": "Chance • Void Fracker", "style": "explosive",
        "set_color": Color(0.45, 0.11, 0.62, 1.0), "text_dark": false, "color": Color(0.78, 0.42, 0.98, 1.0),
        "tex": "res://assets/Equipment/jets/jet_15_onyx.png",
        "tiers": [
            { "name": "Blackfriars / Area 51",   "cost": 9000.0,      "dmg": 450.0,      "rate": 1.15, "aoe": 4, "winged": false },
            { "name": "Canary Wharf / Mariana",  "cost": 175000.0,    "dmg": 11200.0,    "rate": 0.85, "aoe": 5, "winged": false },
            { "name": "Onyx Vault Driller",      "cost": 4800000.0,   "dmg": 365000.0,   "rate": 0.60, "aoe": 6, "winged": false },
            { "name": "Omnium Void Emperor",     "cost": 180000000.0, "dmg": 18500000.0, "rate": 0.36, "aoe": 7, "winged": true }
        ]
    }
]

const INTERN_DEF := {
    "id": "weapon_intern",
    "branch_id": "recruit",
    "name": "PASS GO! Recruit",
    "branch_label": "Entry Recruit",
    "set_name": "GO! CORNER",
    "region_sub": "UK & USA • Base Recruit",
    "rank": 0,
    "upgrades_from": "",
    "cost": 500.0,
    "dmg": 25.0,
    "rate": 1.25,
    "aoe": 1,
    "winged": false,
    "style": "melee",
    "set_color": Color(0.16, 0.62, 0.30, 1.0),
    "text_dark": false,
    "color": Color(0.82, 0.92, 0.84, 1.0),
    "tex": "res://assets/Equipment/Pickaxe-Shoddy.png"
}

var _nodes_by_id: Dictionary = {}
var _counts: Dictionary = {}

func _init() -> void:
    _build_catalog()

func _ready() -> void:
    if _nodes_by_id.is_empty():
        _build_catalog()

func _build_catalog() -> void:
    _nodes_by_id.clear()
    _nodes_by_id[str(INTERN_DEF["id"])] = INTERN_DEF.duplicate(true)

    for b in BRANCHES:
        var b_id: String = str(b.get("id", ""))
        var tiers: Array = b.get("tiers", [])
        var prev_id: String = str(INTERN_DEF["id"])
        for i in range(tiers.size()):
            var t: Dictionary = tiers[i]
            var rank_num: int = i + 1
            var node_id: String = "%s_t%d" % [b_id, rank_num]
            _nodes_by_id[node_id] = {
                "id": node_id,
                "branch_id": b_id,
                "branch_label": str(b.get("label", b_id)),
                "set_name": str(b.get("set_name", "MONOPOLY SET")),
                "region_sub": str(b.get("region_sub", "")),
                "name": str(t.get("name", node_id)),
                "rank": rank_num,
                "upgrades_from": prev_id,
                "cost": float(t.get("cost", 1000.0)),
                "dmg": float(t.get("dmg", 50.0)),
                "rate": float(t.get("rate", 1.0)),
                "aoe": int(t.get("aoe", 1)),
                "winged": bool(t.get("winged", false)),
                "style": str(b.get("style", "melee")),
                "set_color": b.get("set_color", Color(0.4, 0.4, 0.4, 1.0)),
                "text_dark": bool(b.get("text_dark", false)),
                "color": b.get("color", Color.WHITE),
                "tex": str(b.get("tex", ""))
            }
            prev_id = node_id

func get_worker_def(worker_id: String) -> Dictionary:
    if _nodes_by_id.is_empty():
        _build_catalog()
    return _nodes_by_id.get(worker_id, {})

func get_all_defs() -> Dictionary:
    if _nodes_by_id.is_empty():
        _build_catalog()
    return _nodes_by_id

func get_count(worker_id: String) -> int:
    return int(_counts.get(worker_id, 0))

func get_total_hired() -> int:
    var total: int = 0
    for k in _counts.keys():
        total += int(_counts[k])
    return total

func can_purchase(worker_id: String, amount: int = 1) -> bool:
    if amount <= 0 or not _nodes_by_id.has(worker_id):
        return false
    var def: Dictionary = _nodes_by_id[worker_id]
    var cost: float = float(def.get("cost", 0.0)) * float(amount)
    if not Gvars or float(Gvars.CashCount) < cost:
        return false
    var parent_id: String = str(def.get("upgrades_from", ""))
    if parent_id != "" and get_count(parent_id) < amount:
        return false
    return true

func purchase_worker(worker_id: String, amount: int = 1) -> int:
    if amount <= 0 or not _nodes_by_id.has(worker_id) or not Gvars:
        return 0
    var def: Dictionary = _nodes_by_id[worker_id]
    var unit_cost: float = float(def.get("cost", 1.0))
    var afford: int = int(floor(float(Gvars.CashCount) / maxf(1.0, unit_cost)))
    var parent_id: String = str(def.get("upgrades_from", ""))
    var available_parent: int = amount if parent_id == "" else get_count(parent_id)
    var actual: int = mini(amount, mini(afford, available_parent))
    if actual <= 0:
        return 0

    Gvars.CashCount -= float(actual) * unit_cost
    if parent_id != "":
        _counts[parent_id] = maxi(0, get_count(parent_id) - actual)
    _counts[worker_id] = get_count(worker_id) + actual
    return actual

func fire_worker(worker_id: String, amount: int = 1) -> int:
    if amount <= 0 or not _nodes_by_id.has(worker_id) or not Gvars:
        return 0
    var have: int = get_count(worker_id)
    var actual: int = mini(amount, have)
    if actual <= 0:
        return 0
    var def: Dictionary = _nodes_by_id[worker_id]
    var refund: float = float(actual) * (float(def.get("cost", 0.0)) * 0.5)
    _counts[worker_id] = have - actual
    Gvars.CashCount += refund
    return actual

func get_promotion_chain(worker_id: String) -> Array[String]:
    if _nodes_by_id.is_empty():
        _build_catalog()
    var chain: Array[String] = []
    var cur: String = worker_id
    var guard: int = 0
    while cur != "" and _nodes_by_id.has(cur) and guard < 16:
        chain.push_front(cur)
        cur = str(_nodes_by_id[cur].get("upgrades_from", ""))
        guard += 1
    return chain

func calculate_chain_quote(worker_id: String, amount: int) -> Dictionary:
    var chain: Array[String] = get_promotion_chain(worker_id)
    if chain.is_empty() or amount <= 0:
        return { "valid": false, "total_cost": 0.0, "recruits_needed": 0, "steps": [] }

    var needed: int = amount
    var total_cost: float = 0.0
    var recruits_needed: int = 0
    var steps: Array[Dictionary] = []

    for idx in range(chain.size() - 1, -1, -1):
        var node_id: String = chain[idx]
        var def: Dictionary = _nodes_by_id[node_id]
        var unit_cost: float = float(def.get("cost", 0.0))

        if idx == chain.size() - 1:
            total_cost += float(needed) * unit_cost
            steps.push_front({ "id": node_id, "name": str(def.get("name", node_id)), "promote_qty": needed, "used_existing": 0, "cost": float(needed) * unit_cost })
            if idx == 0:
                recruits_needed = needed
        else:
            var have: int = get_count(node_id)
            var use_existing: int = mini(have, needed)
            var shortfall: int = needed - use_existing
            if shortfall > 0:
                total_cost += float(shortfall) * unit_cost
            steps.push_front({ "id": node_id, "name": str(def.get("name", node_id)), "promote_qty": shortfall, "used_existing": use_existing, "cost": float(shortfall) * unit_cost })
            needed = shortfall
            if idx == 0:
                recruits_needed = shortfall

    return {
        "valid": true,
        "target_id": worker_id,
        "amount": amount,
        "total_cost": total_cost,
        "recruits_needed": recruits_needed,
        "steps": steps
    }

func get_max_chain_affordable(worker_id: String) -> int:
    if not Gvars or not _nodes_by_id.has(worker_id):
        return 0
    var cash: float = float(Gvars.CashCount)
    if cash <= 0.0:
        return 0
    var low: int = 0
    var high: int = 1
    while high <= 1000000:
        var q: Dictionary = calculate_chain_quote(worker_id, high)
        if not bool(q.get("valid", false)) or float(q.get("total_cost", 0.0)) > cash:
            break
        low = high
        high *= 2
    while low + 1 < high:
        var mid: int = int((low + high) / 2)
        var qm: Dictionary = calculate_chain_quote(worker_id, mid)
        if bool(qm.get("valid", false)) and float(qm.get("total_cost", 0.0)) <= cash:
            low = mid
        else:
            high = mid
    return low

func execute_chain_purchase(worker_id: String, amount: int) -> Dictionary:
    var quote: Dictionary = calculate_chain_quote(worker_id, amount)
    if not bool(quote.get("valid", false)) or not Gvars:
        return { "success": false, "hired": 0, "spent": 0.0 }
    var total_cost: float = float(quote.get("total_cost", 0.0))
    if float(Gvars.CashCount) < total_cost:
        return { "success": false, "hired": 0, "spent": 0.0 }

    Gvars.CashCount -= total_cost
    var steps: Array = quote.get("steps", [])
    for i in range(steps.size() - 1):
        var st: Dictionary = steps[i]
        var nid: String = str(st.get("id", ""))
        var used: int = int(st.get("used_existing", 0))
        if used > 0:
            _counts[nid] = maxi(0, get_count(nid) - used)

    _counts[worker_id] = get_count(worker_id) + amount
    return { "success": true, "hired": amount, "spent": total_cost }

func export_save() -> Dictionary:
    return _counts.duplicate(true)

func import_save(data: Dictionary) -> void:
    _counts.clear()
    if typeof(data) != TYPE_DICTIONARY:
        return
    if _nodes_by_id.is_empty():
        _build_catalog()
    for k in data.keys():
        var key_str: String = str(k)
        if _nodes_by_id.has(key_str):
            var val: int = int(data[k])
            if val > 0:
                _counts[key_str] = val

func reset_counts() -> void:
    _counts.clear()
