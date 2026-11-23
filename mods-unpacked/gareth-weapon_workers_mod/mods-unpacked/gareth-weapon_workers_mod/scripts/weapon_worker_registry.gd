extends Node

const MOD_DIR := "gareth-weapon_workers_mod"

# Branch definitions: each branch promotes from "weapon_intern" through 4 escalating tiers (Rank 4 has Angel Wings)
const BRANCHES: Array[Dictionary] = [
    {
        "id": "pickaxe", "label": "Pickaxe", "style": "melee", "color": Color(0.35, 0.85, 1.0, 1.0),
        "tex": "res://assets/Equipment/Pickaxe-15-onyx.png",
        "tiers": [
            { "name": "Copper Pick Guard",   "cost": 2500.0,       "dmg": 120.0,      "rate": 0.90, "aoe": 1, "winged": false },
            { "name": "Ruby Pick Striker",   "cost": 45000.0,      "dmg": 2800.0,     "rate": 0.65, "aoe": 2, "winged": false },
            { "name": "Onyx Pick Enforcer",  "cost": 1200000.0,    "dmg": 85000.0,    "rate": 0.45, "aoe": 3, "winged": false },
            { "name": "Seraphic Omni-Miner", "cost": 45000000.0,   "dmg": 4200000.0,  "rate": 0.25, "aoe": 4, "winged": true }
        ]
    },
    {
        "id": "axe", "label": "Battleaxe", "style": "melee", "color": Color(0.95, 0.45, 0.25, 1.0),
        "tex": "res://assets/Equipment/battleaxes/battleaxe_15_onyx.png",
        "tiers": [
            { "name": "Iron Cleaver",        "cost": 3200.0,       "dmg": 180.0,      "rate": 1.05, "aoe": 2, "winged": false },
            { "name": "Diamond Executioner", "cost": 60000.0,      "dmg": 4200.0,     "rate": 0.78, "aoe": 3, "winged": false },
            { "name": "Onyx Reaver",         "cost": 1600000.0,    "dmg": 130000.0,   "rate": 0.52, "aoe": 4, "winged": false },
            { "name": "Valkyrie Warlord",    "cost": 60000000.0,   "dmg": 6500000.0,  "rate": 0.30, "aoe": 5, "winged": true }
        ]
    },
    {
        "id": "brawler", "label": "Gloves & Kick", "style": "melee", "color": Color(1.0, 0.78, 0.22, 1.0),
        "tex": "res://assets/Equipment/boxing_gloves/boxing_gloves_15_onyx.png",
        "tiers": [
            { "name": "Emerald Pugilist",    "cost": 2800.0,       "dmg": 145.0,      "rate": 0.75, "aoe": 2, "winged": false },
            { "name": "Uranium Crusher",     "cost": 52000.0,      "dmg": 3400.0,     "rate": 0.55, "aoe": 3, "winged": false },
            { "name": "Onyx Champion",       "cost": 1400000.0,    "dmg": 105000.0,   "rate": 0.36, "aoe": 4, "winged": false },
            { "name": "Ascended Monk",       "cost": 52000000.0,   "dmg": 5100000.0,  "rate": 0.20, "aoe": 5, "winged": true }
        ]
    },
    {
        "id": "pistol", "label": "Pistol & Shotgun", "style": "projectile", "color": Color(0.95, 0.85, 0.35, 1.0),
        "tex": "res://assets/Equipment/guns/shotguns/shotgun_15_onyx.png",
        "tiers": [
            { "name": "Sapphire Gunslinger", "cost": 4000.0,       "dmg": 210.0,      "rate": 0.85, "aoe": 2, "winged": false },
            { "name": "Spinel Breacher",     "cost": 75000.0,      "dmg": 5100.0,     "rate": 0.62, "aoe": 3, "winged": false },
            { "name": "Onyx Deadeye",        "cost": 2000000.0,    "dmg": 165000.0,   "rate": 0.42, "aoe": 4, "winged": false },
            { "name": "Archangel Marksman",  "cost": 75000000.0,   "dmg": 8200000.0,  "rate": 0.24, "aoe": 5, "winged": true }
        ]
    },
    {
        "id": "minigun", "label": "Rifle & Minigun", "style": "beam", "color": Color(1.0, 0.35, 0.35, 1.0),
        "tex": "res://assets/Equipment/guns/miniguns/minigun_15_onyx.png",
        "tiers": [
            { "name": "Gold Rifleman",       "cost": 5500.0,       "dmg": 160.0,      "rate": 0.45, "aoe": 2, "winged": false },
            { "name": "Moonstone Gunner",    "cost": 95000.0,      "dmg": 3900.0,     "rate": 0.32, "aoe": 3, "winged": false },
            { "name": "Onyx Vulcan",         "cost": 2600000.0,    "dmg": 125000.0,   "rate": 0.22, "aoe": 4, "winged": false },
            { "name": "Seraphic Gatling",    "cost": 95000000.0,   "dmg": 6200000.0,  "rate": 0.14, "aoe": 5, "winged": true }
        ]
    },
    {
        "id": "staff", "label": "Magic Staff", "style": "orb", "color": Color(0.75, 0.35, 1.0, 1.0),
        "tex": "res://assets/Equipment/magic/staffs/15_onyx_staff.png",
        "tiers": [
            { "name": "Amethyst Acolyte",    "cost": 6000.0,       "dmg": 260.0,      "rate": 1.10, "aoe": 3, "winged": false },
            { "name": "Uranium Arcanist",    "cost": 110000.0,     "dmg": 6400.0,     "rate": 0.80, "aoe": 4, "winged": false },
            { "name": "Onyx Archmage",       "cost": 3000000.0,    "dmg": 210000.0,   "rate": 0.55, "aoe": 5, "winged": false },
            { "name": "Celestial Sorcerer",  "cost": 110000000.0,  "dmg": 10500000.0, "rate": 0.32, "aoe": 6, "winged": true }
        ]
    },
    {
        "id": "flame", "label": "Flamethrower", "style": "beam", "color": Color(1.0, 0.52, 0.12, 1.0),
        "tex": "res://assets/Equipment/alternative_guns/flamethrowers/flamethrower_15_onyx.png",
        "tiers": [
            { "name": "Ruby Pyromancer",     "cost": 5000.0,       "dmg": 195.0,      "rate": 0.60, "aoe": 3, "winged": false },
            { "name": "Spinel Incinerator",  "cost": 90000.0,      "dmg": 4800.0,     "rate": 0.44, "aoe": 4, "winged": false },
            { "name": "Onyx Hellfire",       "cost": 2400000.0,    "dmg": 155000.0,   "rate": 0.30, "aoe": 5, "winged": false },
            { "name": "Solar Phoenix",       "cost": 90000000.0,   "dmg": 7800000.0,  "rate": 0.18, "aoe": 6, "winged": true }
        ]
    },
    {
        "id": "poison", "label": "Poison & Water", "style": "orb", "color": Color(0.25, 0.95, 0.45, 1.0),
        "tex": "res://assets/Equipment/alternative_guns/poison_guns/poison_gun_15_onyx.png",
        "tiers": [
            { "name": "Emerald Chemist",     "cost": 4800.0,       "dmg": 185.0,      "rate": 0.70, "aoe": 3, "winged": false },
            { "name": "Moonstone Alchemist", "cost": 85000.0,      "dmg": 4500.0,     "rate": 0.50, "aoe": 4, "winged": false },
            { "name": "Onyx Plaguebringer",  "cost": 2200000.0,    "dmg": 145000.0,   "rate": 0.35, "aoe": 5, "winged": false },
            { "name": "Aether Hydra",        "cost": 85000000.0,   "dmg": 7200000.0,  "rate": 0.22, "aoe": 6, "winged": true }
        ]
    },
    {
        "id": "tank", "label": "Heavy Tank & Orb", "style": "explosive", "color": Color(0.55, 0.68, 0.45, 1.0),
        "tex": "res://assets/Equipment/tanks/tank_15_onyx.png",
        "tiers": [
            { "name": "Iron Tank Crew",      "cost": 8500.0,       "dmg": 420.0,      "rate": 1.35, "aoe": 4, "winged": false },
            { "name": "Uranium Siege Tank",  "cost": 160000.0,     "dmg": 10500.0,    "rate": 1.00, "aoe": 5, "winged": false },
            { "name": "Onyx Juggernaut",     "cost": 4500000.0,    "dmg": 340000.0,   "rate": 0.72, "aoe": 6, "winged": false },
            { "name": "Orbital Dread-Tank",  "cost": 160000000.0,  "dmg": 17000000.0, "rate": 0.45, "aoe": 7, "winged": true }
        ]
    },
    {
        "id": "bouncing_ball", "label": "Bouncing Ball", "style": "orb", "color": Color(0.20, 0.90, 1.0, 1.0),
        "tex": "res://mods-unpacked/gareth-bouncing_ball_mod/textures/ball_15_onyx.png",
        "tiers": [
            { "name": "Kinetic Slinger",     "cost": 7000.0,       "dmg": 340.0,      "rate": 1.00, "aoe": 3, "winged": false },
            { "name": "Ricochet Specialist", "cost": 130000.0,     "dmg": 8400.0,     "rate": 0.74, "aoe": 4, "winged": false },
            { "name": "Onyx Pinball Lord",   "cost": 3600000.0,    "dmg": 275000.0,   "rate": 0.50, "aoe": 5, "winged": false },
            { "name": "Singularity Orbiter", "cost": 130000000.0,  "dmg": 13500000.0, "rate": 0.30, "aoe": 6, "winged": true }
        ]
    },
    {
        "id": "laser_plasma", "label": "Laser & Plasma", "style": "beam", "color": Color(0.18, 0.98, 0.88, 1.0),
        "tex": "res://assets/Equipment/orbs/orb_15_onyx.png",
        "tiers": [
            { "name": "Photon Technician",   "cost": 7500.0,       "dmg": 310.0,      "rate": 0.80, "aoe": 3, "winged": false },
            { "name": "Plasma Cutter",       "cost": 140000.0,     "dmg": 7800.0,     "rate": 0.58, "aoe": 4, "winged": false },
            { "name": "Onyx Beam Array",     "cost": 3800000.0,    "dmg": 255000.0,   "rate": 0.40, "aoe": 5, "winged": false },
            { "name": "Hyperion Star-Beam",  "cost": 140000000.0,  "dmg": 12800000.0, "rate": 0.24, "aoe": 6, "winged": true }
        ]
    },
    {
        "id": "chrono", "label": "Chrono Harvester", "style": "beam", "color": Color(0.65, 0.92, 1.0, 1.0),
        "tex": "res://assets/Equipment/electric_pickaxes/electric_pickaxe_15_onyx.png",
        "tiers": [
            { "name": "Temporal Apprentice", "cost": 8000.0,       "dmg": 330.0,      "rate": 0.75, "aoe": 3, "winged": false },
            { "name": "Chrono Weaver",       "cost": 150000.0,     "dmg": 8200.0,     "rate": 0.55, "aoe": 4, "winged": false },
            { "name": "Onyx Timekeeper",     "cost": 4000000.0,    "dmg": 265000.0,   "rate": 0.38, "aoe": 5, "winged": false },
            { "name": "Epoch Sovereign",     "cost": 150000000.0,  "dmg": 13200000.0, "rate": 0.22, "aoe": 6, "winged": true }
        ]
    },
    {
        "id": "blade", "label": "Saber & Broadsword", "style": "melee", "color": Color(0.35, 0.72, 1.0, 1.0),
        "tex": "res://assets/Equipment/Sword-Shoddy.png",
        "tiers": [
            { "name": "Squire & Padawan",    "cost": 6500.0,       "dmg": 290.0,      "rate": 0.70, "aoe": 3, "winged": false },
            { "name": "Aether Duelist",      "cost": 120000.0,     "dmg": 7200.0,     "rate": 0.52, "aoe": 4, "winged": false },
            { "name": "Onyx Paladin",        "cost": 3300000.0,    "dmg": 235000.0,   "rate": 0.35, "aoe": 5, "winged": false },
            { "name": "Seraphic Blade-Master","cost": 120000000.0, "dmg": 11800000.0, "rate": 0.20, "aoe": 6, "winged": true }
        ]
    },
    {
        "id": "void_fracker", "label": "Void & Fracker", "style": "explosive", "color": Color(0.82, 0.25, 1.0, 1.0),
        "tex": "res://assets/Equipment/jets/jet_15_onyx.png",
        "tiers": [
            { "name": "Seismic Siphoner",    "cost": 9000.0,       "dmg": 450.0,      "rate": 1.15, "aoe": 4, "winged": false },
            { "name": "Void Rupturer",       "cost": 175000.0,     "dmg": 11200.0,    "rate": 0.85, "aoe": 5, "winged": false },
            { "name": "Onyx Abyss-Driller",  "cost": 4800000.0,    "dmg": 365000.0,   "rate": 0.60, "aoe": 6, "winged": false },
            { "name": "Omnium Singularity",  "cost": 180000000.0,  "dmg": 18500000.0, "rate": 0.36, "aoe": 7, "winged": true }
        ]
    }
]

const INTERN_DEF := {
    "id": "weapon_intern",
    "name": "Weapon Recruit",
    "branch_label": "Entry Recruit",
    "rank": 0,
    "upgrades_from": "",
    "cost": 500.0,
    "dmg": 25.0,
    "rate": 1.25,
    "aoe": 1,
    "winged": false,
    "style": "melee",
    "color": Color(0.82, 0.82, 0.82, 1.0),
    "tex": "res://assets/Equipment/Pickaxe-Shoddy.png"
}

var _nodes_by_id: Dictionary = {}
var _counts: Dictionary = {}

func _ready() -> void:
    _build_catalog()

func _build_catalog() -> void:
    _nodes_by_id.clear()
    _nodes_by_id[INTERN_DEF["id"]] = INTERN_DEF.duplicate(true)

    for b in BRANCHES:
        var b_id: String = str(b["id"])
        var tiers: Array = b["tiers"]
        var prev_id: String = INTERN_DEF["id"]
        for i in range(tiers.size()):
            var t: Dictionary = tiers[i]
            var rank_num: int = i + 1
            var node_id: String = "%s_t%d" % [b_id, rank_num]
            _nodes_by_id[node_id] = {
                "id": node_id,
                "branch_id": b_id,
                "branch_label": str(b["label"]),
                "name": str(t["name"]),
                "rank": rank_num,
                "upgrades_from": prev_id,
                "cost": float(t["cost"]),
                "dmg": float(t["dmg"]),
                "rate": float(t["rate"]),
                "aoe": int(t["aoe"]),
                "winged": bool(t["winged"]),
                "style": str(b["style"]),
                "color": b["color"],
                "tex": str(b["tex"])
            }
            prev_id = node_id

func get_worker_def(worker_id: String) -> Dictionary:
    return _nodes_by_id.get(worker_id, {})

func get_all_defs() -> Dictionary:
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
    var cost: float = float(def["cost"]) * float(amount)
    if not Gvars or float(Gvars.CashCount) < cost:
        return false
    var parent_id: String = str(def["upgrades_from"])
    if parent_id != "" and get_count(parent_id) < amount:
        return false
    return true

func purchase_worker(worker_id: String, amount: int = 1) -> int:
    if amount <= 0 or not _nodes_by_id.has(worker_id) or not Gvars:
        return 0
    var def: Dictionary = _nodes_by_id[worker_id]
    var unit_cost: float = float(def["cost"])
    var afford: int = int(floor(float(Gvars.CashCount) / maxf(1.0, unit_cost)))
    var parent_id: String = str(def["upgrades_from"])
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
    var refund: float = float(actual) * (float(def["cost"]) * 0.5)
    _counts[worker_id] = have - actual
    Gvars.CashCount += refund
    return actual

func export_save() -> Dictionary:
    return _counts.duplicate(true)

func import_save(data: Dictionary) -> void:
    _counts.clear()
    if typeof(data) != TYPE_DICTIONARY:
        return
    for k in data.keys():
        var key_str := str(k)
        if _nodes_by_id.has(key_str):
            var val: int = int(data[k])
            if val > 0:
                _counts[key_str] = val

func reset_counts() -> void:
    _counts.clear()
