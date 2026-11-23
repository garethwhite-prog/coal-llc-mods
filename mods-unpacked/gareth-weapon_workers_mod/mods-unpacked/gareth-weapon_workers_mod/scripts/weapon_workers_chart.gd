extends Control

const HEAD_TEX := preload("res://assets/NPCs/Player/playerSheet_Head.png")
const TORSO_TEX := preload("res://assets/NPCs/Player/playerSheet_Torso.png")
const LEGS_TEX := preload("res://assets/NPCs/Player/playerSheet_Legs.png")

const COL_WIDTH: float = 112.0
const ROW_HEIGHT: float = 136.0
const CHART_PAD_X: float = 36.0
const CHART_PAD_Y: float = 24.0

var _registry: Node = null
var _tree_canvas: Control = null
var _tooltip_panel: PanelContainer = null
var _tooltip_label: RichTextLabel = null
var _cards_by_id: Dictionary = {}
var _icon_tex_cache: Dictionary = {}
var _wings_tex: Texture2D = null

func _init() -> void:
    name = "Weapon Workers"

func _ready() -> void:
    name = "Weapon Workers"
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    _wings_tex = _resolve_wings_texture()
    _registry = get_node_or_null("/root/WeaponWorkerRegistry")
    _build_ui()
    refresh_chart()

func _resolve_wings_texture() -> Texture2D:
    if ResourceLoader.exists("res://scenes/Interfaces/Management/employee_level_icon_2.tscn"):
        var packed: PackedScene = load("res://scenes/Interfaces/Management/employee_level_icon_2.tscn")
        if packed:
            var inst: Node = packed.instantiate()
            if inst:
                var wings_node: Node = inst.find_child("Wings", true, false)
                var tex: Texture2D = null
                if wings_node and ("texture" in wings_node):
                    tex = wings_node.texture
                inst.free()
                if tex:
                    return tex
    var img := Image.create(32, 16, false, Image.FORMAT_RGBA8)
    var white := Color(0.98, 0.98, 1.0, 0.95)
    var border := Color(0.2, 0.2, 0.25, 1.0)
    for x in range(32):
        for y in range(16):
            if (x < 12 or x > 19) and y >= 3 and y <= 12:
                if x == 0 or x == 11 or x == 20 or x == 31 or y == 3 or y == 12:
                    img.set_pixel(x, y, border)
                else:
                    img.set_pixel(x, y, white)
    return ImageTexture.create_from_image(img)

func _process(_delta: float) -> void:
    if _tooltip_panel and _tooltip_panel.visible:
        var m: Vector2 = get_local_mouse_position()
        var target: Vector2 = m + Vector2(22, 22)
        if target.x + _tooltip_panel.size.x > size.x - 16.0:
            target.x = m.x - _tooltip_panel.size.x - 18.0
        if target.y + _tooltip_panel.size.y > size.y - 16.0:
            target.y = m.y - _tooltip_panel.size.y - 18.0
        _tooltip_panel.position = target

func _build_ui() -> void:
    var bg := PanelContainer.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.93, 0.88, 0.77, 1.0)
    sb.border_width_left = 3
    sb.border_width_top = 3
    sb.border_width_right = 3
    sb.border_width_bottom = 3
    sb.border_color = Color(0.22, 0.18, 0.14, 1.0)
    bg.add_theme_stylebox_override("panel", sb)
    add_child(bg)

    var outer_vbox := VBoxContainer.new()
    outer_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    outer_vbox.add_theme_constant_override("separation", 4)
    bg.add_child(outer_vbox)

    var title_lbl := RichTextLabel.new()
    title_lbl.bbcode_enabled = true
    title_lbl.fit_content = true
    title_lbl.scroll_active = false
    title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    title_lbl.text = "[center][color=#1a1410][font_size=24][b]Organisation Chart — Weapon Workers[/b][/font_size]\n[i][font_size=14]Higher ranking employees must be promoted from lower ranks. Only recruits can be purchased outright. (Right-click $$ for x5 | Click xN to fire)[/font_size][/i][/color][/center]"
    outer_vbox.add_child(title_lbl)

    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    outer_vbox.add_child(scroll)

    var branches: Array = _registry.BRANCHES if _registry else []
    var num_cols: int = maxi(1, branches.size())
    var canvas_w: float = CHART_PAD_X * 2.0 + float(num_cols) * COL_WIDTH
    var canvas_h: float = CHART_PAD_Y * 2.0 + 5.0 * ROW_HEIGHT + 40.0

    _tree_canvas = Control.new()
    _tree_canvas.name = "TreeCanvas"
    _tree_canvas.custom_minimum_size = Vector2(canvas_w, canvas_h)
    _tree_canvas.draw.connect(_on_tree_canvas_draw)
    scroll.add_child(_tree_canvas)

    var center_x: float = CHART_PAD_X + (float(num_cols - 1) * COL_WIDTH) * 0.5
    var intern_pos := Vector2(center_x, CHART_PAD_Y + 4.0 * ROW_HEIGHT)
    _create_worker_card("weapon_intern", intern_pos, "Recruit")

    for col_idx in range(num_cols):
        var b: Dictionary = branches[col_idx]
        var b_id: String = str(b["id"])
        var b_lbl: String = str(b["label"])
        var x_pos: float = CHART_PAD_X + float(col_idx) * COL_WIDTH

        var col_hdr := Label.new()
        col_hdr.text = b_lbl
        col_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        col_hdr.position = Vector2(x_pos - 8.0, 2.0)
        col_hdr.custom_minimum_size = Vector2(104.0, 20.0)
        col_hdr.add_theme_color_override("font_color", Color(0.18, 0.14, 0.10, 1.0))
        col_hdr.add_theme_font_size_override("font_size", 11)
        _tree_canvas.add_child(col_hdr)

        for rank_idx in range(4):
            var rank_num: int = rank_idx + 1
            var node_id: String = "%s_t%d" % [b_id, rank_num]
            var row_y: float = CHART_PAD_Y + float(4 - rank_num) * ROW_HEIGHT
            _create_worker_card(node_id, Vector2(x_pos, row_y), b_lbl)

    _tooltip_panel = PanelContainer.new()
    _tooltip_panel.visible = false
    _tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _tooltip_panel.z_index = 50
    var t_sb := StyleBoxFlat.new()
    t_sb.bg_color = Color(0.12, 0.10, 0.09, 0.95)
    t_sb.border_width_left = 2
    t_sb.border_width_top = 2
    t_sb.border_width_right = 2
    t_sb.border_width_bottom = 2
    t_sb.border_color = Color(0.85, 0.72, 0.35, 1.0)
    t_sb.content_margin_left = 10
    t_sb.content_margin_top = 8
    t_sb.content_margin_right = 10
    t_sb.content_margin_bottom = 8
    _tooltip_panel.add_theme_stylebox_override("panel", t_sb)
    add_child(_tooltip_panel)

    _tooltip_label = RichTextLabel.new()
    _tooltip_label.bbcode_enabled = true
    _tooltip_label.fit_content = true
    _tooltip_label.autowrap_mode = TextServer.AUTOWRAP_OFF
    _tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _tooltip_panel.add_child(_tooltip_label)

func _create_worker_card(worker_id: String, pos: Vector2, branch_short: String) -> void:
    if not _registry:
        return
    var def: Dictionary = _registry.get_worker_def(worker_id)
    if def.is_empty():
        return

    var card := Control.new()
    card.name = "Card_" + worker_id
    card.position = pos
    card.custom_minimum_size = Vector2(96, 114)
    card.size = Vector2(96, 114)
    card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _tree_canvas.add_child(card)

    var frame := Panel.new()
    frame.position = Vector2(20, 4)
    frame.size = Vector2(64, 64)
    frame.mouse_filter = Control.MOUSE_FILTER_PASS
    var f_sb := StyleBoxFlat.new()
    f_sb.bg_color = Color(0.98, 0.95, 0.88, 1.0)
    f_sb.border_width_left = 3
    f_sb.border_width_top = 3
    f_sb.border_width_right = 3
    f_sb.border_width_bottom = 3
    f_sb.border_color = Color(0.1, 0.1, 0.1, 1.0)
    frame.add_theme_stylebox_override("panel", f_sb)
    card.add_child(frame)

    if bool(def["winged"]) and _wings_tex:
        var wings_rect := TextureRect.new()
        wings_rect.texture = _wings_tex
        wings_rect.position = Vector2(-18, -4)
        wings_rect.size = Vector2(100, 64)
        wings_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        wings_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        wings_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        frame.add_child(wings_rect)

    var rank_idx: int = int(def["rank"])
    _add_atlas_part(frame, LEGS_TEX, 0, Vector2(14, 14), Vector2(36, 36), Color.WHITE)
    _add_atlas_part(frame, TORSO_TEX, rank_idx % 4, Vector2(14, 14), Vector2(36, 36), def["color"])
    _add_atlas_part(frame, HEAD_TEX, rank_idx % 4, Vector2(14, 14), Vector2(36, 36), Color.WHITE)

    var wep_tex: Texture2D = _load_weapon_tex(str(def["tex"]))
    if wep_tex:
        var wep_rect := TextureRect.new()
        wep_rect.texture = wep_tex
        wep_rect.position = Vector2(34, 14)
        wep_rect.size = Vector2(28, 28)
        wep_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        wep_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        wep_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        frame.add_child(wep_rect)

    var buy_btn := Button.new()
    buy_btn.text = "$$"
    buy_btn.position = Vector2(2, 0)
    buy_btn.size = Vector2(28, 24)
    buy_btn.add_theme_font_size_override("font_size", 11)
    var b_sb := StyleBoxFlat.new()
    b_sb.bg_color = Color(0.32, 0.78, 0.28, 1.0)
    b_sb.border_width_left = 2
    b_sb.border_width_top = 2
    b_sb.border_width_right = 2
    b_sb.border_width_bottom = 2
    b_sb.border_color = Color(0.08, 0.14, 0.08, 1.0)
    buy_btn.add_theme_stylebox_override("normal", b_sb)
    buy_btn.gui_input.connect(_on_buy_gui_input.bind(worker_id))
    card.add_child(buy_btn)

    var count_btn := Button.new()
    count_btn.text = "x0"
    count_btn.position = Vector2(2, 46)
    count_btn.size = Vector2(34, 24)
    count_btn.add_theme_font_size_override("font_size", 11)
    var c_sb := StyleBoxFlat.new()
    c_sb.bg_color = Color(0.95, 0.92, 0.84, 1.0)
    c_sb.border_width_left = 2
    c_sb.border_width_top = 2
    c_sb.border_width_right = 2
    c_sb.border_width_bottom = 2
    c_sb.border_color = Color(0.1, 0.1, 0.1, 1.0)
    count_btn.add_theme_stylebox_override("normal", c_sb)
    count_btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
    count_btn.gui_input.connect(_on_sell_gui_input.bind(worker_id))
    card.add_child(count_btn)

    var tag_lbl := Label.new()
    tag_lbl.text = "T%d %s" % [rank_idx, branch_short] if rank_idx > 0 else "Recruit"
    tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tag_lbl.position = Vector2(4, 70)
    tag_lbl.custom_minimum_size = Vector2(92, 18)
    tag_lbl.add_theme_color_override("font_color", Color(0.18, 0.14, 0.10, 1.0))
    tag_lbl.add_theme_font_size_override("font_size", 10)
    tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(tag_lbl)

    frame.mouse_entered.connect(_show_worker_tooltip.bind(worker_id, false))
    frame.mouse_exited.connect(_hide_tooltip)
    buy_btn.mouse_entered.connect(_show_worker_tooltip.bind(worker_id, false))
    buy_btn.mouse_exited.connect(_hide_tooltip)
    count_btn.mouse_entered.connect(_show_worker_tooltip.bind(worker_id, true))
    count_btn.mouse_exited.connect(_hide_tooltip)

    _cards_by_id[worker_id] = {
        "card": card,
        "frame": frame,
        "buy_btn": buy_btn,
        "count_btn": count_btn,
        "buy_style": b_sb,
        "center": pos + Vector2(52, 36)
    }

func _add_atlas_part(parent: Control, sheet: Texture2D, frame_col: int, pos: Vector2, sz: Vector2, tint: Color) -> void:
    var at := AtlasTexture.new()
    at.atlas = sheet
    at.region = Rect2(float(frame_col * 16), 0.0, 16.0, 16.0)
    var tr := TextureRect.new()
    tr.texture = at
    tr.position = pos
    tr.size = sz
    tr.modulate = tint
    tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(tr)

func _load_weapon_tex(path: String) -> Texture2D:
    if _icon_tex_cache.has(path):
        return _icon_tex_cache[path]
    var tex: Texture2D = null
    if ResourceLoader.exists(path):
        tex = load(path)
    elif FileAccess.file_exists(path):
        var img: Image = Image.load_from_file(path)
        if img:
            tex = ImageTexture.create_from_image(img)
    _icon_tex_cache[path] = tex
    return tex

func _on_buy_gui_input(event: InputEvent, worker_id: String) -> void:
    if not _registry:
        return
    if event is InputEventMouseButton and event.pressed:
        var amt: int = 1
        if event.button_index == MOUSE_BUTTON_RIGHT:
            amt = 5
        elif event.button_index != MOUSE_BUTTON_LEFT:
            return
        var hired: int = _registry.purchase_worker(worker_id, amt)
        if hired > 0:
            refresh_chart()
            _show_worker_tooltip(worker_id, false)

func _on_sell_gui_input(event: InputEvent, worker_id: String) -> void:
    if not _registry:
        return
    if event is InputEventMouseButton and event.pressed:
        var amt: int = 1
        if event.button_index == MOUSE_BUTTON_RIGHT:
            amt = 5
        elif event.button_index != MOUSE_BUTTON_LEFT:
            return
        var fired: int = _registry.fire_worker(worker_id, amt)
        if fired > 0:
            refresh_chart()
            _show_worker_tooltip(worker_id, true)

func refresh_chart() -> void:
    if not _registry:
        return
    for worker_id in _cards_by_id.keys():
        var entry: Dictionary = _cards_by_id[worker_id]
        var cnt: int = _registry.get_count(worker_id)
        var can_buy: bool = _registry.can_purchase(worker_id, 1)

        var count_btn: Button = entry["count_btn"]
        count_btn.text = "x%d" % cnt

        var b_sb: StyleBoxFlat = entry["buy_style"]
        if can_buy:
            b_sb.bg_color = Color(0.32, 0.80, 0.28, 1.0)
        else:
            b_sb.bg_color = Color(0.65, 0.25, 0.25, 1.0)

    if _tree_canvas and is_instance_valid(_tree_canvas):
        _tree_canvas.queue_redraw()

func _on_tree_canvas_draw() -> void:
    if not _registry:
        return
    var locked_pts := PackedVector2Array()
    var unlocked_pts := PackedVector2Array()
    var defs: Dictionary = _registry.get_all_defs()

    for worker_id in _cards_by_id.keys():
        var def: Dictionary = defs.get(worker_id, {})
        var parent_id: String = str(def.get("upgrades_from", ""))
        if parent_id == "" or not _cards_by_id.has(parent_id):
            continue

        var p_child: Vector2 = _cards_by_id[worker_id]["center"]
        var p_parent: Vector2 = _cards_by_id[parent_id]["center"]
        var mid_y: float = (p_parent.y + p_child.y) * 0.5
        var target_arr: PackedVector2Array = unlocked_pts if _registry.can_purchase(worker_id, 1) else locked_pts

        target_arr.append(p_parent)
        target_arr.append(Vector2(p_parent.x, mid_y))
        target_arr.append(Vector2(p_parent.x, mid_y))
        target_arr.append(Vector2(p_child.x, mid_y))
        target_arr.append(Vector2(p_child.x, mid_y))
        target_arr.append(p_child)

    if not locked_pts.is_empty():
        _tree_canvas.draw_multiline(locked_pts, Color(0.62, 0.08, 0.08, 0.85), 4.0)
    if not unlocked_pts.is_empty():
        _tree_canvas.draw_multiline(unlocked_pts, Color(0.05, 0.58, 0.08, 0.95), 7.0)

func _show_worker_tooltip(worker_id: String, is_sell: bool) -> void:
    if not _registry or not _tooltip_panel or not _tooltip_label:
        return
    var def: Dictionary = _registry.get_worker_def(worker_id)
    if def.is_empty():
        return
    var cost: float = float(def["cost"])
    var cnt: int = _registry.get_count(worker_id)

    if is_sell:
        var refund: int = int(cost * 0.5)
        _tooltip_label.text = "[b]%s (Hired: %d)[/b]\n[i]Left-click[/i]: Fire 1 (+%sg)\n[i]Right-click[/i]: Fire 5 (+%sg)" % [
            str(def["name"]), cnt, Gconsts.add_comma_to_int(refund), Gconsts.add_comma_to_int(refund * 5)
        ]
    else:
        var req_text := "Purchased outright"
        var parent_id := str(def["upgrades_from"])
        if parent_id != "":
            var p_def: Dictionary = _registry.get_worker_def(parent_id)
            req_text = "Promotes from: %s (Have: %d)" % [str(p_def.get("name", parent_id)), _registry.get_count(parent_id)]
        _tooltip_label.text = "[b]%s[/b] — [color=#ffe066]%sg[/color]\nBranch: %s (Rank %d)\n%s\nStrike Power: %s | Interval: %.2fs | AOE: %d tiles\n[i]Left-click $$: Hire/Promote 1 | Right-click $$: x5[/i]" % [
            str(def["name"]),
            Gconsts.add_comma_to_int(int(cost)),
            str(def["branch_label"]),
            int(def["rank"]),
            req_text,
            Gconsts.add_comma_to_int(int(def["dmg"])),
            float(def["rate"]),
            int(def["aoe"])
        ]
    _tooltip_panel.visible = true

func _hide_tooltip() -> void:
    if _tooltip_panel:
        _tooltip_panel.visible = false
