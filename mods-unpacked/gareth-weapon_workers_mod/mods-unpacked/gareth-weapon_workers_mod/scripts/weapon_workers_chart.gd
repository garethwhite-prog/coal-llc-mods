extends Control

const HEAD_TEX := preload("res://assets/NPCs/Player/playerSheet_Head.png")
const TORSO_TEX := preload("res://assets/NPCs/Player/playerSheet_Torso.png")
const LEGS_TEX := preload("res://assets/NPCs/Player/playerSheet_Legs.png")

const CARD_W: float = 138.0
const CARD_H: float = 166.0
const COL_STEP: float = 152.0
const ROW_STEP: float = 186.0
const PAD_X: float = 28.0
const PAD_Y: float = 34.0

var _registry: Node = null
var _tree_canvas: Control = null
var _tooltip_panel: PanelContainer = null
var _tooltip_label: RichTextLabel = null
var _cards_by_id: Dictionary = {}
var _icon_tex_cache: Dictionary = {}
var _wings_tex: Texture2D = null

# Filter bar controls
var _search_input: LineEdit = null
var _set_dropdown: OptionButton = null
var _chk_affordable: CheckBox = null
var _is_affordable_only: bool = false

# 1-Click Chain Calculator & Pinned Recruit controls
var _selected_target_id: String = "pickaxe_t1"
var _recruit_count_label: Label = null
var _btn_recruit_1: Button = null
var _btn_recruit_5: Button = null
var _calc_target_label: Label = null
var _calc_summary_label: RichTextLabel = null
var _btn_buy_1: Button = null
var _btn_buy_5: Button = null
var _btn_buy_10: Button = null
var _btn_buy_max: Button = null
var _status_msg: String = ""

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
    return null

func _process(_delta: float) -> void:
    if not _registry:
        _registry = get_node_or_null("/root/WeaponWorkerRegistry")
        if _registry:
            refresh_chart()
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
    sb.bg_color = Color(0.86, 0.91, 0.84, 1.0)
    sb.border_width_left = 3
    sb.border_width_top = 3
    sb.border_width_right = 3
    sb.border_width_bottom = 3
    sb.border_color = Color(0.14, 0.22, 0.16, 1.0)
    bg.add_theme_stylebox_override("panel", sb)
    add_child(bg)

    var outer_vbox := VBoxContainer.new()
    outer_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    outer_vbox.add_theme_constant_override("separation", 6)
    bg.add_child(outer_vbox)

    # 1. Top Search / Set Filter / Affordable Only Bar
    var filter_bar := HBoxContainer.new()
    filter_bar.add_theme_constant_override("separation", 10)
    outer_vbox.add_child(filter_bar)

    _search_input = LineEdit.new()
    _search_input.placeholder_text = "Search Monopoly property, weapon type, or rank..."
    _search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _search_input.clear_button_enabled = true
    _search_input.text_changed.connect(func(_t: String): refresh_chart())
    filter_bar.add_child(_search_input)

    _set_dropdown = OptionButton.new()
    _set_dropdown.add_item("All Monopoly Sets & Weapons", 0)
    var branches: Array = _registry.BRANCHES if _registry else []
    for i in range(branches.size()):
        var b: Dictionary = branches[i]
        _set_dropdown.add_item("%s — %s" % [str(b["set_name"]), str(b["label"])], i + 1)
    _set_dropdown.item_selected.connect(func(_idx: int): refresh_chart())
    filter_bar.add_child(_set_dropdown)

    _chk_affordable = CheckBox.new()
    _chk_affordable.text = "Affordable Only (Chain)"
    _chk_affordable.tooltip_text = "Show only cards whose full promotion chain from Recruit you can afford right now."
    _chk_affordable.add_theme_color_override("font_color", Color(0.1, 0.14, 0.1, 1.0))
    _chk_affordable.toggled.connect(func(pressed: bool):
        _is_affordable_only = pressed
        refresh_chart()
    )
    filter_bar.add_child(_chk_affordable)

    # 2. Pinned Recruit Quick-Hire + 1-Click Chain-Promotion Calculator Strip
    var calc_panel := PanelContainer.new()
    var c_sb := StyleBoxFlat.new()
    c_sb.bg_color = Color(0.14, 0.17, 0.21, 0.96)
    c_sb.border_width_left = 2
    c_sb.border_width_top = 2
    c_sb.border_width_right = 2
    c_sb.border_width_bottom = 2
    c_sb.border_color = Color(0.88, 0.72, 0.26, 1.0)
    c_sb.content_margin_left = 10
    c_sb.content_margin_top = 4
    c_sb.content_margin_right = 10
    c_sb.content_margin_bottom = 4
    calc_panel.add_theme_stylebox_override("panel", c_sb)
    outer_vbox.add_child(calc_panel)

    var calc_hbox := HBoxContainer.new()
    calc_hbox.add_theme_constant_override("separation", 8)
    calc_panel.add_child(calc_hbox)

    _recruit_count_label = Label.new()
    _recruit_count_label.text = "Recruits: 0"
    _recruit_count_label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.55, 1.0))
    calc_hbox.add_child(_recruit_count_label)

    _btn_recruit_1 = Button.new()
    _btn_recruit_1.text = "+1 Recruit (500g)"
    _btn_recruit_1.pressed.connect(func(): _execute_chain_buy_for("weapon_intern", 1))
    calc_hbox.add_child(_btn_recruit_1)

    _btn_recruit_5 = Button.new()
    _btn_recruit_5.text = "+5"
    _btn_recruit_5.pressed.connect(func(): _execute_chain_buy_for("weapon_intern", 5))
    calc_hbox.add_child(_btn_recruit_5)

    var vsep := VSeparator.new()
    calc_hbox.add_child(vsep)

    _calc_target_label = Label.new()
    _calc_target_label.text = "Selected: Old Kent / Mediterranean (T1)"
    _calc_target_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42, 1.0))
    calc_hbox.add_child(_calc_target_label)

    _calc_summary_label = RichTextLabel.new()
    _calc_summary_label.bbcode_enabled = true
    _calc_summary_label.fit_content = true
    _calc_summary_label.scroll_active = false
    _calc_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _calc_summary_label.text = "Click $$ on ANY card to auto-buy & promote in 1 transaction."
    calc_hbox.add_child(_calc_summary_label)

    _btn_buy_1 = Button.new()
    _btn_buy_1.text = "Chain x1"
    _btn_buy_1.pressed.connect(func(): _execute_chain_buy_for(_selected_target_id, 1))
    calc_hbox.add_child(_btn_buy_1)

    _btn_buy_5 = Button.new()
    _btn_buy_5.text = "x5"
    _btn_buy_5.pressed.connect(func(): _execute_chain_buy_for(_selected_target_id, 5))
    calc_hbox.add_child(_btn_buy_5)

    _btn_buy_10 = Button.new()
    _btn_buy_10.text = "x10"
    _btn_buy_10.pressed.connect(func(): _execute_chain_buy_for(_selected_target_id, 10))
    calc_hbox.add_child(_btn_buy_10)

    _btn_buy_max = Button.new()
    _btn_buy_max.text = "MAX (0)"
    _btn_buy_max.pressed.connect(func():
        if _registry:
            var m: int = _registry.get_max_chain_affordable(_selected_target_id)
            if m > 0:
                _execute_chain_buy_for(_selected_target_id, m)
    )
    calc_hbox.add_child(_btn_buy_max)

    # 3. Scrollable Monopoly Property x Pokemon Card Board
    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    outer_vbox.add_child(scroll)

    var num_cols: int = maxi(1, branches.size())
    var canvas_w: float = PAD_X * 2.0 + float(num_cols) * COL_STEP
    var canvas_h: float = PAD_Y * 2.0 + 5.0 * ROW_STEP + 30.0

    _tree_canvas = Control.new()
    _tree_canvas.name = "TreeCanvas"
    _tree_canvas.custom_minimum_size = Vector2(canvas_w, canvas_h)
    _tree_canvas.draw.connect(_on_tree_canvas_draw)
    scroll.add_child(_tree_canvas)

    # Place GO! Recruit at bottom-left (PAD_X) so it is immediately reachable when scrolling down
    var intern_pos := Vector2(PAD_X, PAD_Y + 4.0 * ROW_STEP)
    _create_monopoly_pokemon_card("weapon_intern", intern_pos)

    for col_idx in range(num_cols):
        var b: Dictionary = branches[col_idx]
        var b_id: String = str(b["id"])
        var x_pos: float = PAD_X + float(col_idx) * COL_STEP

        var set_banner := Label.new()
        set_banner.text = "%s\n(%s)" % [str(b["set_name"]), str(b["label"])]
        set_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        set_banner.position = Vector2(x_pos - 4.0, 2.0)
        set_banner.custom_minimum_size = Vector2(CARD_W + 8.0, 28.0)
        set_banner.add_theme_color_override("font_color", Color(0.12, 0.16, 0.12, 1.0))
        set_banner.add_theme_font_size_override("font_size", 10)
        _tree_canvas.add_child(set_banner)

        for rank_idx in range(4):
            var rank_num: int = rank_idx + 1
            var node_id: String = "%s_t%d" % [b_id, rank_num]
            var row_y: float = PAD_Y + float(4 - rank_num) * ROW_STEP
            _create_monopoly_pokemon_card(node_id, Vector2(x_pos, row_y))

    # Floating tooltip
    _tooltip_panel = PanelContainer.new()
    _tooltip_panel.visible = false
    _tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _tooltip_panel.z_index = 60
    var t_sb := StyleBoxFlat.new()
    t_sb.bg_color = Color(0.10, 0.11, 0.14, 0.96)
    t_sb.border_width_left = 2
    t_sb.border_width_top = 2
    t_sb.border_width_right = 2
    t_sb.border_width_bottom = 2
    t_sb.border_color = Color(0.95, 0.78, 0.25, 1.0)
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

func _create_monopoly_pokemon_card(worker_id: String, pos: Vector2) -> void:
    if not _registry:
        return
    var def: Dictionary = _registry.get_worker_def(worker_id)
    if def.is_empty():
        return

    var card := Panel.new()
    card.name = "Card_" + worker_id
    card.position = pos
    card.custom_minimum_size = Vector2(CARD_W, CARD_H)
    card.size = Vector2(CARD_W, CARD_H)
    card.mouse_filter = Control.MOUSE_FILTER_PASS

    var card_sb := StyleBoxFlat.new()
    card_sb.bg_color = Color(0.98, 0.96, 0.90, 1.0)
    card_sb.border_width_left = 3
    card_sb.border_width_top = 3
    card_sb.border_width_right = 3
    card_sb.border_width_bottom = 3
    card_sb.border_color = Color(0.12, 0.12, 0.14, 1.0)
    card_sb.corner_radius_top_left = 6
    card_sb.corner_radius_top_right = 6
    card_sb.corner_radius_bottom_left = 6
    card_sb.corner_radius_bottom_right = 6
    card.add_theme_stylebox_override("panel", card_sb)
    _tree_canvas.add_child(card)

    # 1. Monopoly Title Deed Colored Header Band
    var header := Panel.new()
    header.position = Vector2(4, 4)
    header.size = Vector2(CARD_W - 8.0, 34.0)
    header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var h_sb := StyleBoxFlat.new()
    h_sb.bg_color = def["set_color"]
    h_sb.border_width_left = 2
    h_sb.border_width_top = 2
    h_sb.border_width_right = 2
    h_sb.border_width_bottom = 2
    h_sb.border_color = Color(0.08, 0.08, 0.08, 1.0)
    header.add_theme_stylebox_override("panel", h_sb)
    card.add_child(header)

    var deed_lbl := Label.new()
    deed_lbl.text = "TITLE DEED • T%d" % int(def["rank"])
    deed_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    deed_lbl.position = Vector2(2, 1)
    deed_lbl.custom_minimum_size = Vector2(CARD_W - 12.0, 12.0)
    deed_lbl.add_theme_font_size_override("font_size", 8)
    deed_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
    deed_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header.add_child(deed_lbl)

    var prop_lbl := Label.new()
    prop_lbl.text = str(def["name"])
    prop_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prop_lbl.clip_text = true
    prop_lbl.position = Vector2(3, 13)
    prop_lbl.custom_minimum_size = Vector2(CARD_W - 14.0, 18.0)
    prop_lbl.add_theme_font_size_override("font_size", 10)
    prop_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
    prop_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header.add_child(prop_lbl)

    # 2. Pokemon-style Framed Artwork Box (Worker + Integrated Weapon + Wings)
    var art_box := Panel.new()
    art_box.position = Vector2(8, 42)
    art_box.size = Vector2(CARD_W - 16.0, 68.0)
    art_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var a_sb := StyleBoxFlat.new()
    var base_col: Color = def["color"]
    a_sb.bg_color = base_col.darkened(0.55)
    a_sb.border_width_left = 2
    a_sb.border_width_top = 2
    a_sb.border_width_right = 2
    a_sb.border_width_bottom = 2
    a_sb.border_color = Color(0.82, 0.68, 0.24, 1.0)
    art_box.add_theme_stylebox_override("panel", a_sb)
    card.add_child(art_box)

    var stage_floor := ColorRect.new()
    stage_floor.color = base_col.darkened(0.25)
    stage_floor.position = Vector2(2, 46)
    stage_floor.size = Vector2(CARD_W - 20.0, 20.0)
    stage_floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
    art_box.add_child(stage_floor)

    if bool(def["winged"]) and _wings_tex:
        var wings_rect := TextureRect.new()
        wings_rect.texture = _wings_tex
        wings_rect.position = Vector2(6, 2)
        wings_rect.size = Vector2(108, 62)
        wings_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        wings_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        wings_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        art_box.add_child(wings_rect)

    var rank_idx: int = int(def["rank"])
    _add_atlas_part(art_box, LEGS_TEX, 0, Vector2(26, 12), Vector2(42, 42), Color.WHITE)
    _add_atlas_part(art_box, TORSO_TEX, rank_idx % 4, Vector2(26, 12), Vector2(42, 42), def["color"])
    _add_atlas_part(art_box, HEAD_TEX, rank_idx % 4, Vector2(26, 12), Vector2(42, 42), Color.WHITE)

    var wep_tex: Texture2D = _load_weapon_tex(str(def["tex"]))
    if wep_tex:
        var wep_rect := TextureRect.new()
        wep_rect.texture = wep_tex
        wep_rect.position = Vector2(62, 12)
        wep_rect.size = Vector2(38, 38)
        wep_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        wep_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        wep_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        art_box.add_child(wep_rect)

    var type_badge := Label.new()
    type_badge.text = str(def["branch_label"]).to_upper()
    type_badge.position = Vector2(4, 52)
    type_badge.add_theme_font_size_override("font_size", 8)
    type_badge.add_theme_color_override("font_color", Color(1.0, 0.96, 0.78, 1.0))
    type_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
    art_box.add_child(type_badge)

    # 3. Pokemon Move / Stat Line
    var stat_lbl := Label.new()
    stat_lbl.text = "PWR %s | %.2fs | %dT" % [_format_short(float(def["dmg"])), float(def["rate"]), int(def["aoe"])]
    stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stat_lbl.position = Vector2(4, 113)
    stat_lbl.custom_minimum_size = Vector2(CARD_W - 8.0, 16.0)
    stat_lbl.add_theme_font_size_override("font_size", 9)
    stat_lbl.add_theme_color_override("font_color", Color(0.14, 0.14, 0.16, 1.0))
    stat_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(stat_lbl)

    # 4. Bottom Action Row: 1-Click Chain Buy/Promote Button + xN Owned/Fire Button
    var buy_btn := Button.new()
    buy_btn.text = "$$ %s" % _format_short(float(def["cost"]))
    buy_btn.position = Vector2(6, 132)
    buy_btn.size = Vector2(78, 26)
    buy_btn.add_theme_font_size_override("font_size", 10)
    var b_sb := StyleBoxFlat.new()
    b_sb.bg_color = Color(0.24, 0.72, 0.24, 1.0)
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
    count_btn.position = Vector2(88, 132)
    count_btn.size = Vector2(44, 26)
    count_btn.add_theme_font_size_override("font_size", 10)
    var c_sb := StyleBoxFlat.new()
    c_sb.bg_color = Color(0.92, 0.88, 0.78, 1.0)
    c_sb.border_width_left = 2
    c_sb.border_width_top = 2
    c_sb.border_width_right = 2
    c_sb.border_width_bottom = 2
    c_sb.border_color = Color(0.12, 0.12, 0.12, 1.0)
    count_btn.add_theme_stylebox_override("normal", c_sb)
    count_btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
    count_btn.gui_input.connect(_on_sell_gui_input.bind(worker_id))
    card.add_child(count_btn)

    card.gui_input.connect(_on_card_gui_input.bind(worker_id))
    card.mouse_entered.connect(_show_worker_tooltip.bind(worker_id, false))
    card.mouse_exited.connect(_hide_tooltip)
    buy_btn.mouse_entered.connect(_show_worker_tooltip.bind(worker_id, false))
    buy_btn.mouse_exited.connect(_hide_tooltip)
    count_btn.mouse_entered.connect(_show_worker_tooltip.bind(worker_id, true))
    count_btn.mouse_exited.connect(_hide_tooltip)

    _cards_by_id[worker_id] = {
        "card": card,
        "card_style": card_sb,
        "buy_btn": buy_btn,
        "count_btn": count_btn,
        "buy_style": b_sb,
        "center": pos + Vector2(CARD_W * 0.5, CARD_H * 0.5)
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

func _on_card_gui_input(event: InputEvent, worker_id: String) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _selected_target_id = worker_id
        _status_msg = ""
        refresh_chart()

func _on_buy_gui_input(event: InputEvent, worker_id: String) -> void:
    if not _registry:
        return
    if event is InputEventMouseButton and event.pressed:
        _selected_target_id = worker_id
        var amt: int = 1
        if event.button_index == MOUSE_BUTTON_RIGHT:
            amt = 5
        elif event.button_index != MOUSE_BUTTON_LEFT:
            return
        _execute_chain_buy_for(worker_id, amt)
        _show_worker_tooltip(worker_id, false)

func _on_sell_gui_input(event: InputEvent, worker_id: String) -> void:
    if not _registry:
        return
    if event is InputEventMouseButton and event.pressed:
        _selected_target_id = worker_id
        var amt: int = 1
        if event.button_index == MOUSE_BUTTON_RIGHT:
            amt = 5
        elif event.button_index != MOUSE_BUTTON_LEFT:
            return
        var fired: int = _registry.fire_worker(worker_id, amt)
        if fired > 0:
            var def: Dictionary = _registry.get_worker_def(worker_id)
            _status_msg = "Fired %dx %s." % [fired, str(def.get("name", worker_id))]
            refresh_chart()
            _show_worker_tooltip(worker_id, true)

func _execute_chain_buy_for(worker_id: String, amount: int) -> void:
    if not _registry or amount <= 0:
        return
    var def: Dictionary = _registry.get_worker_def(worker_id)
    var q: Dictionary = _registry.calculate_chain_quote(worker_id, amount)
    var cost: float = float(q.get("total_cost", 0.0))
    var cash: float = float(Gvars.CashCount) if Gvars else 0.0
    if cash < cost:
        _status_msg = "[color=#ff7777]Need %sg (Have %sg)[/color]" % [
            Gconsts.add_comma_to_int(int(cost)), Gconsts.add_comma_to_int(int(cash))
        ]
        refresh_chart()
        return

    var res: Dictionary = _registry.execute_chain_purchase(worker_id, amount)
    if bool(res.get("success", false)):
        _status_msg = "[color=#66ff88]Hired %dx %s (-%sg)![/color]" % [
            amount, str(def.get("name", worker_id)), Gconsts.add_comma_to_int(int(cost))
        ]
        refresh_chart()

func refresh_chart() -> void:
    if not _registry:
        return

    var query: String = _search_input.text.strip_edges().to_lower() if is_instance_valid(_search_input) else ""
    var selected_branch_idx: int = _set_dropdown.selected if is_instance_valid(_set_dropdown) else 0
    var selected_branch_id: String = ""
    if selected_branch_idx > 0 and selected_branch_idx <= _registry.BRANCHES.size():
        selected_branch_id = str(_registry.BRANCHES[selected_branch_idx - 1]["id"])

    var cash: float = float(Gvars.CashCount) if Gvars else 0.0
    var defs: Dictionary = _registry.get_all_defs()

    for worker_id in _cards_by_id.keys():
        var entry: Dictionary = _cards_by_id[worker_id]
        var def: Dictionary = defs.get(worker_id, {})
        var cnt: int = _registry.get_count(worker_id)
        var can_buy_direct: bool = _registry.can_purchase(worker_id, 1)
        var chain_q: Dictionary = _registry.calculate_chain_quote(worker_id, 1)
        var chain_cost: float = float(chain_q["total_cost"])
        var can_chain_afford: bool = bool(chain_q["valid"]) and chain_cost <= cash

        var count_btn: Button = entry["count_btn"]
        count_btn.text = "x%d" % cnt

        var buy_btn: Button = entry["buy_btn"]
        buy_btn.text = "$$ %s" % _format_short(chain_cost)

        var b_sb: StyleBoxFlat = entry["buy_style"]
        if can_buy_direct:
            b_sb.bg_color = Color(0.24, 0.74, 0.24, 1.0)
        elif can_chain_afford:
            b_sb.bg_color = Color(0.18, 0.66, 0.42, 1.0)
        else:
            b_sb.bg_color = Color(0.65, 0.22, 0.22, 1.0)

        var card_sb: StyleBoxFlat = entry["card_style"]
        if worker_id == _selected_target_id:
            card_sb.border_color = Color(0.98, 0.78, 0.12, 1.0)
        else:
            card_sb.border_color = Color(0.12, 0.12, 0.14, 1.0)

        var hay: String = ("%s %s %s %s" % [
            str(def.get("name", "")),
            str(def.get("branch_label", "")),
            str(def.get("set_name", "")),
            worker_id
        ]).to_lower()
        var match_q: bool = query.is_empty() or (query in hay)
        var match_set: bool = selected_branch_id == "" or worker_id == "weapon_intern" or str(def.get("branch_id", "")) == selected_branch_id
        var match_aff: bool = (not _is_affordable_only) or can_chain_afford

        var card: Control = entry["card"]
        card.visible = match_q and match_set and match_aff

    _refresh_calculator_bar()
    if _tree_canvas and is_instance_valid(_tree_canvas):
        _tree_canvas.queue_redraw()

func _refresh_calculator_bar() -> void:
    if not _registry or not is_instance_valid(_calc_target_label):
        return
    var cash: float = float(Gvars.CashCount) if Gvars else 0.0
    var rec_cnt: int = _registry.get_count("weapon_intern")
    if is_instance_valid(_recruit_count_label):
        _recruit_count_label.text = "Recruits: %d" % rec_cnt
    if is_instance_valid(_btn_recruit_1):
        _btn_recruit_1.disabled = (cash < 500.0)
    if is_instance_valid(_btn_recruit_5):
        _btn_recruit_5.disabled = (cash < 2500.0)

    var def: Dictionary = _registry.get_worker_def(_selected_target_id)
    if def.is_empty():
        return
    var q1: Dictionary = _registry.calculate_chain_quote(_selected_target_id, 1)
    var max_aff: int = _registry.get_max_chain_affordable(_selected_target_id)
    var cost1: float = float(q1["total_cost"])
    var recruits1: int = int(q1["recruits_needed"])

    _calc_target_label.text = "Selected: %s (T%d)" % [str(def["name"]), int(def["rank"])]
    var suffix: String = ("  |  " + _status_msg) if _status_msg != "" else ""
    _calc_summary_label.text = "1-Click Chain Cost: [b][color=#66ff88]%sg[/color][/b] (New Recruits: %d) | Max: [b]%d[/b]%s" % [
        Gconsts.add_comma_to_int(int(cost1)), recruits1, max_aff, suffix
    ]

    _btn_buy_1.disabled = (cash < cost1)
    _btn_buy_5.disabled = (max_aff < 5)
    _btn_buy_10.disabled = (max_aff < 10)
    _btn_buy_max.text = "MAX (%d)" % max_aff
    _btn_buy_max.disabled = (max_aff <= 0)

func _on_tree_canvas_draw() -> void:
    if not _registry:
        return
    var locked_pts := PackedVector2Array()
    var unlocked_pts := PackedVector2Array()
    var defs: Dictionary = _registry.get_all_defs()
    var cash: float = float(Gvars.CashCount) if Gvars else 0.0

    for worker_id in _cards_by_id.keys():
        var child_card: Control = _cards_by_id[worker_id]["card"]
        if not child_card.visible:
            continue
        var def: Dictionary = defs.get(worker_id, {})
        var parent_id: String = str(def.get("upgrades_from", ""))
        if parent_id == "" or not _cards_by_id.has(parent_id):
            continue
        var parent_card: Control = _cards_by_id[parent_id]["card"]
        if not parent_card.visible:
            continue

        var p_child: Vector2 = _cards_by_id[worker_id]["center"]
        var p_parent: Vector2 = _cards_by_id[parent_id]["center"]
        var mid_y: float = (p_parent.y + p_child.y) * 0.5
        var q1: Dictionary = _registry.calculate_chain_quote(worker_id, 1)
        var target_arr: PackedVector2Array = unlocked_pts if (bool(q1["valid"]) and float(q1["total_cost"]) <= cash) else locked_pts

        target_arr.append(p_parent)
        target_arr.append(Vector2(p_parent.x, mid_y))
        target_arr.append(Vector2(p_parent.x, mid_y))
        target_arr.append(Vector2(p_child.x, mid_y))
        target_arr.append(Vector2(p_child.x, mid_y))
        target_arr.append(p_child)

    if not locked_pts.is_empty():
        _tree_canvas.draw_multiline(locked_pts, Color(0.62, 0.12, 0.12, 0.75), 3.5)
    if not unlocked_pts.is_empty():
        _tree_canvas.draw_multiline(unlocked_pts, Color(0.08, 0.56, 0.12, 0.95), 6.0)

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
        var q1: Dictionary = _registry.calculate_chain_quote(worker_id, 1)
        var max_aff: int = _registry.get_max_chain_affordable(worker_id)
        _tooltip_label.text = "[b]%s[/b] — Step: [color=#ffe066]%sg[/color]\n%s | %s (Rank %d)\n1-Click Full Chain Cost: [color=#66ff88]%sg[/color] (Max Affordable: %d)\nStrike Power: %s | Rate: %.2fs | AOE: %d tiles\n[i]Left-click $$: 1-Click Chain Buy x1 | Right-click $$: x5[/i]" % [
            str(def["name"]),
            Gconsts.add_comma_to_int(int(cost)),
            str(def["set_name"]),
            str(def["branch_label"]),
            int(def["rank"]),
            Gconsts.add_comma_to_int(int(q1["total_cost"])),
            max_aff,
            Gconsts.add_comma_to_int(int(def["dmg"])),
            float(def["rate"]),
            int(def["aoe"])
        ]
    _tooltip_panel.visible = true

func _hide_tooltip() -> void:
    if _tooltip_panel:
        _tooltip_panel.visible = false

func _format_short(val: float) -> String:
    if val >= 1e9:
        return "%.1fB" % (val / 1e9)
    if val >= 1e6:
        return "%.1fM" % (val / 1e6)
    if val >= 1e3:
        return "%.1fK" % (val / 1e3)
    return "%.0f" % val
