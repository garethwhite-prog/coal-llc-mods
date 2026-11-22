extends Node

const MOD_DIR := "gareth-beyond_onyx_mod"

const SKIP_ITEM_TYPES: Array[String] = [
    "coal", "gem", "mineral", "ladder", "platform", "whistle", "teleporter", "bonus"
]

const BEYOND_TIERS: Array[Dictionary] = [
    { "tier": 16, "id": "16_obsidian",     "name": "Obsidian",     "dmg_mult": 4.0,       "price_mult": 6.0,         "color": Color(0.45, 0.22, 0.72, 1.0) },
    { "tier": 17, "id": "17_cobalt_nova",  "name": "Cobalt Nova",  "dmg_mult": 16.0,      "price_mult": 36.0,        "color": Color(0.15, 0.62, 1.00, 1.0) },
    { "tier": 18, "id": "18_solarite",     "name": "Solarite",     "dmg_mult": 64.0,      "price_mult": 220.0,       "color": Color(1.00, 0.68, 0.12, 1.0) },
    { "tier": 19, "id": "19_crimson_flux", "name": "Crimson Flux", "dmg_mult": 250.0,     "price_mult": 1400.0,      "color": Color(0.98, 0.18, 0.32, 1.0) },
    { "tier": 20, "id": "20_aetherium",    "name": "Aetherium",    "dmg_mult": 1000.0,    "price_mult": 9000.0,      "color": Color(0.18, 0.96, 0.80, 1.0) },
    { "tier": 21, "id": "21_voidsteel",    "name": "Voidsteel",    "dmg_mult": 4200.0,    "price_mult": 60000.0,     "color": Color(0.75, 0.20, 0.98, 1.0) },
    { "tier": 22, "id": "22_chronium",     "name": "Chronium",     "dmg_mult": 18000.0,   "price_mult": 400000.0,    "color": Color(0.68, 0.94, 1.00, 1.0) },
    { "tier": 23, "id": "23_celestial",    "name": "Celestial",    "dmg_mult": 80000.0,   "price_mult": 2800000.0,   "color": Color(1.00, 0.94, 0.58, 1.0) },
    { "tier": 24, "id": "24_singularity",  "name": "Singularity",  "dmg_mult": 360000.0,  "price_mult": 20000000.0,  "color": Color(0.42, 0.28, 1.00, 1.0) },
    { "tier": 25, "id": "25_omnium",       "name": "Omnium",       "dmg_mult": 1600000.0, "price_mult": 150000000.0, "color": Color(1.00, 0.86, 0.98, 1.0) }
]

var _registered: bool = false

func _ready() -> void:
    # Defer one frame so every vanilla and custom weapon mod registers its Tier 15 Onyx items first
    call_deferred("_register_beyond_onyx_tiers")

func _register_beyond_onyx_tiers() -> void:
    if _registered:
        return
    _registered = true

    var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
    if not item_unlocks or not ("all_equipment_items" in item_unlocks):
        ModLoaderLog.warning("Beyond Onyx: item_unlocks.tres unavailable.", MOD_DIR)
        return

    var existing_ids: Dictionary = {}
    var onyx_bases: Array = []

    for it in item_unlocks.all_equipment_items:
        if not is_instance_valid(it):
            continue
        var iid: String = str(it.itemID) if ("itemID" in it) else ""
        if iid != "":
            existing_ids[iid] = true
        if _is_onyx_weapon_base(it):
            onyx_bases.append(it)

    var created_count: int = 0
    for base_item in onyx_bases:
        for tier_def in BEYOND_TIERS:
            var new_item = _build_tiered_weapon(base_item, tier_def, existing_ids)
            if new_item:
                existing_ids[str(new_item.itemID)] = true
                item_unlocks.all_equipment_items.append(new_item)
                created_count += 1

    ModLoaderLog.info(
        "Beyond Onyx active: Extended %d Onyx weapon families to Tier 25 (%d new weapons registered)." % [onyx_bases.size(), created_count],
        MOD_DIR
    )

func _is_onyx_weapon_base(it: Resource) -> bool:
    if not ("itemID" in it) or not ("itemName" in it):
        return false
    if ("itemType" in it) and (str(it.itemType).to_lower() in SKIP_ITEM_TYPES):
        return false
    if not ("itemEquipEffect" in it) or it.itemEquipEffect == null:
        return false

    var id_low: String = str(it.itemID).to_lower()
    var name_low: String = str(it.itemName).to_lower()
    if id_low.begins_with("beyond_onyx_"):
        return false
    return ("onyx" in id_low) or ("onyx" in name_low)

func _build_tiered_weapon(base_item: Resource, tier_def: Dictionary, existing_ids: Dictionary) -> Resource:
    var tier_num: int = int(tier_def["tier"])
    var step: int = tier_num - 15
    var tier_id: String = str(tier_def["id"])
    var tier_name: String = str(tier_def["name"])
    var dmg_mult: float = float(tier_def["dmg_mult"])
    var price_mult: float = float(tier_def["price_mult"])
    var tier_color: Color = tier_def["color"]

    var base_id: String = str(base_item.itemID)
    var new_id: String = base_id.replacen("15_onyx", tier_id).replacen("onyx", tier_id)
    if new_id == base_id:
        new_id = "%s_%s" % [base_id, tier_id]
    new_id = "beyond_onyx_%s" % new_id
    if existing_ids.has(new_id):
        return null

    var clone = base_item.duplicate(false)
    if not clone:
        return null

    clone.itemID = new_id

    var base_name: String = str(base_item.itemName)
    var new_name: String = base_name.replacen("Onyx", tier_name)
    if new_name == base_name:
        new_name = "%s %s" % [tier_name, base_name]
    clone.itemName = new_name

    # Price scaling (safe fallback if a custom Onyx item had price 0)
    var base_price: float = float(base_item.itemBuyPrice)
    if base_price <= 0.0:
        base_price = 1500000000000.0
    clone.itemBuyPrice = base_price * price_mult
    clone.itemSellPrice = clone.itemBuyPrice * 0.5
    clone.itemUnlocked = true

    # Pickaxe subclass Strength & Colour fields
    if "Strength" in clone:
        clone.Strength = float(base_item.Strength) * dmg_mult
    if "Colour" in clone:
        clone.Colour = tier_color

    # Deep-copy and scale EquipEffect safely
    var scaled_dmg_preview: float = 0.0
    if "Strength" in clone:
        scaled_dmg_preview = float(clone.Strength)

    if base_item.itemEquipEffect != null:
        var eq = base_item.itemEquipEffect.duplicate(true)
        if eq:
            scaled_dmg_preview = _scale_equip_effect(eq, step, dmg_mult, tier_color, scaled_dmg_preview)
            clone.itemEquipEffect = eq

    # Procedurally tint icon texture
    if base_item.itemTexture != null:
        clone.itemTexture = _tint_texture(base_item.itemTexture, tier_color)

    # Clear, accurate tier description
    var dmg_str: String = _format_big(scaled_dmg_preview) if scaled_dmg_preview > 0.0 else "Scaled x%s" % _format_big(dmg_mult)
    clone.itemDescription = "Tier %d (%s) Weapon.\nPower: %s (x%s vs Onyx)\nForged beyond the Onyx frontier." % [
        tier_num, tier_name, dmg_str, _format_big(dmg_mult)
    ]

    return clone

func _scale_equip_effect(eq: Resource, step: int, dmg_mult: float, tier_color: Color, fallback_dmg: float) -> float:
    var preview_dmg: float = fallback_dmg

    if "damage" in eq and float(eq.damage) > 0.0:
        eq.damage = float(eq.damage) * dmg_mult
        preview_dmg = maxf(preview_dmg, float(eq.damage))
    if "bullet_damage" in eq and float(eq.bullet_damage) > 0.0:
        eq.bullet_damage = float(eq.bullet_damage) * dmg_mult
        preview_dmg = maxf(preview_dmg, float(eq.bullet_damage))
    if "missile_damage" in eq and float(eq.missile_damage) > 0.0:
        eq.missile_damage = float(eq.missile_damage) * dmg_mult
        preview_dmg = maxf(preview_dmg, float(eq.missile_damage))

    # Capped area/count scaling to preserve framerate
    if "radius" in eq:
        if typeof(eq.radius) == TYPE_INT:
            eq.radius = mini(20, int(eq.radius) + int(ceil(float(step) * 0.5)))
        else:
            eq.radius = minf(20.0, float(eq.radius) + float(step) * 0.5)
    if "blast_radius" in eq:
        eq.blast_radius = minf(20.0, float(eq.blast_radius) + float(step) * 0.5)
    if "reach" in eq:
        eq.reach = minf(96.0, float(eq.reach) * (1.0 + float(step) * 0.08))
    if "beam_width" in eq:
        eq.beam_width = minf(24.0, float(eq.beam_width) + float(step) * 1.0)
    if "seam_limit" in eq:
        eq.seam_limit = mini(45, int(eq.seam_limit) + step * 2)
    if "ticks" in eq:
        eq.ticks = mini(20, int(eq.ticks) + int(step / 2))
    if "missile_count" in eq:
        eq.missile_count = mini(50, int(eq.missile_count) + step * 2)
    if "bullet_count" in eq:
        eq.bullet_count = mini(16, int(eq.bullet_count) + int(step / 3))

    # Floored fire-rate/cooldown improvements
    var rate_decay: float = pow(0.94, float(step))
    if "cooldown_time" in eq and float(eq.cooldown_time) > 0.0:
        eq.cooldown_time = maxf(0.03, float(eq.cooldown_time) * rate_decay)
    if "cooldown_secs" in eq and float(eq.cooldown_secs) > 0.0:
        eq.cooldown_secs = maxf(0.15, float(eq.cooldown_secs) * rate_decay)
    if "fire_rate" in eq and float(eq.fire_rate) > 0.0:
        eq.fire_rate = maxf(0.015, float(eq.fire_rate) * rate_decay)
    if "strike_rate" in eq and float(eq.strike_rate) > 0.0:
        eq.strike_rate = maxf(0.03, float(eq.strike_rate) * rate_decay)
    if "swing_speed" in eq and float(eq.swing_speed) > 0.0:
        eq.swing_speed = maxf(0.06, float(eq.swing_speed) * rate_decay)

    # Visual accent colors on magic staffs/projectiles
    if "color_one" in eq:
        eq.color_one = tier_color
    if "color_two" in eq:
        eq.color_two = tier_color.lightened(0.35)

    return preview_dmg

func _tint_texture(tex: Texture2D, tint: Color) -> Texture2D:
    if not tex:
        return null
    var img: Image = tex.get_image()
    if img == null:
        return tex
    if img.get_width() > 256 or img.get_height() > 256:
        return tex

    img = img.duplicate()
    if img.is_compressed():
        img.decompress()
    if img.get_format() != Image.FORMAT_RGBA8:
        img.convert(Image.FORMAT_RGBA8)

    var w: int = img.get_width()
    var h: int = img.get_height()
    for y in range(h):
        for x in range(w):
            var p: Color = img.get_pixel(x, y)
            if p.a <= 0.05:
                continue
            var lum: float = p.r * 0.299 + p.g * 0.587 + p.b * 0.114
            if lum < 0.05:
                # Keep crisp dark pixel outlines
                continue
            var lifted: float = clampf(lum * 1.65 + 0.32, 0.28, 1.15)
            var recolored := Color(
                clampf(tint.r * lifted, 0.0, 1.0),
                clampf(tint.g * lifted, 0.0, 1.0),
                clampf(tint.b * lifted, 0.0, 1.0),
                p.a
            )
            img.set_pixel(x, y, p.lerp(recolored, 0.82))

    return ImageTexture.create_from_image(img)

func _format_big(val: float) -> String:
    if val >= 1000000.0:
        return "%.2e" % val
    return "%.0f" % val
