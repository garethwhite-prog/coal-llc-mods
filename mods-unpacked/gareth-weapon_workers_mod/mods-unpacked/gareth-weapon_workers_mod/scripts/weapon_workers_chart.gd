extends Control

const HEAD_TEX := preload("res://assets/NPCs/Player/playerSheet_Head.png")
const TORSO_TEX := preload("res://assets/NPCs/Player/playerSheet_Torso.png")
const LEGS_TEX := preload("res://assets/NPCs/Player/playerSheet_Legs.png")
const REG_SCRIPT_PATH := "res://mods-unpacked/gareth-weapon_workers_mod/scripts/weapon_worker_registry.gd"

const CARD_W: float = 144.0
const CARD_H: float = 172.0
const COL_W: float = 156.0
const COL_STEP: float = 166.0
const SET_HDR_H: float = 42.0
const CARD_TOP_Y: float = 50.0
const ROW_STEP: float = 184.0
const PAD_X: float = 18.0
const PAD_Y: float = 12.0

var _registry: Node = null
var _tree_canvas: Control = null
var _tooltip_panel: PanelContainer = null
var _tooltip_label: RichTextLabel = null
var _cards_by_id: Dictionary = {}
var _columns: Array[Dictionary] = []
var _icon_tex_cache: Dictionary = {}
var _wings_tex: Texture2D = null

var _search_input: LineEdit = null
var _set_dropdown: OptionButton = null
var _chk_affordable: CheckBox = null
var _is_affordable_only: bool = false

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
    _registry = _get_or_create_registry()
    _build_ui()
    refresh_chart()

func _get_or_create_registry() -> Node:
    if is_instance_valid(_registry) and _registry.has_method("calculate_chain_quote"):
        return _registry
    var tree: SceneTree = get_tree()
    if tree and tree.root:
        var existing: Node = tree.root.get_node_or_null("WeaponWorkerRegistry")
        if is_instance_valid(existing) and existing.has_method("calculate_chain_quote"):
            return existing
        if is_instance_valid(existing):
            existing.name = "OldWeaponWorkerRegistry"
            existing.queue_free()
        var reg_script: GDScript = load(REG_SCRIPT_PATH)
        if reg_script:
            var reg := Node.new()
            reg.name = "WeaponWorkerRegistry"
            reg.set_script(reg_script)
            tree.root.add_child(reg)
            return reg
    return null

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
    if not is_instance_valid(_registry):
        _registry = _get_or_create_registry()
        if is_instance_valid(_registry):
            refresh_chart()
    if _tooltip_panel and _tooltip_panel.visible:
        var m: Vector2 = get_local_mouse_position()
        var target: Vector2 = m + Vector2(22, 22)
        if target.x + _tooltip_panel.size.x > size.x - 16.0:
            target.x = m.x - _tooltip_panel.size.x - 18.0
        if target.y + _tooltip_panel.size.y > size.y - 16.0:
            target.y = m.y - _tooltip_panel.size.y - 18.0
        _tooltip_panel.position = target

func _play_ui_sound(is_cash: bool) -> void:
    var p: Node = get_parent()
    while is_instance_valid(p):
        if is_cash and ("kaching_sound" in p) and is_instance_valid(p.kaching_sound):
            p.kaching_sound.play()
            return
        if (not is_cash) and ("thud_click" in p) and is_instance_valid(p.thud_click):
            p.thud_click.play()
            return
        p = p.get_parent()

func _build_ui() -> void:
    var bg := PanelContainer.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.84, 0.90, 0.82, 1.0)
    sb.border_width_left = 3
    sb.border_width_top = 3
    sb.border_width_right = 3
    sb.border_width_bottom = 3
    sb.border_color = Color(0.12, 0.20, 0.14, 1.0)
    bg.add_theme_stylebox_override("panel", sb)
    add_child(bg)

    var outer_vbox := VBoxContainer.new()
    outer_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    outer_vbox.add_theme_constant_override("separation", 6)
    bg.add_child(outer_vbox)

    # 1. Top Search / Monopoly Set Filter / Affordable Only Bar
    var filter_bar := HBoxContainer.new()
    filter_bar.add_theme_constant_override("separation", 10)
    outer_vbox.add_child(filter_bar)

    _search_input = LineEdit.new()
    _search_input.placeholder_text = "Search Monopoly set, UK/USA street name, or weapon type..."
    _search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _search_input.clear_button_enabled = true
    _search_input.text_changed.connect(func(_t: String): refresh_chart())
    filter_bar.add_child(_search_input)

    _set_dropdown = OptionButton.new()
    _set_dropdown.focus_mode = Control.FOCUS_NONE
    _set_dropdown.add_item("All 14 Monopoly Colour Sets", 0)
    var branches: Array = _registry.get("BRANCHES") if _registry else []
    for i in range(branches.size()):
        var b: Dictionary = branches[i]
        var s_name: String = str(b.get("set_name", "Set"))
        var b_lbl: String = str(b.get("label", "Weapon"))
        _set_dropdown.add_item("%s — %s" % [s_name, b_lbl], i + 1)
    _set_dropdown.item_selected.connect(func(_idx: int): refresh_chart())
    filter_bar.add_child(_set_dropdown)

    _chk_affordable = CheckBox.new()
    _chk_affordable.focus_mode = Control.FOCUS_NONE
    _chk_affordable.text = "Affordable Only (Chain)"
    _chk_affordable.tooltip_text = "Show only Monopoly cards whose full promotion chain from Recruit you can afford right now."
    _chk_affordable.add_theme_color_override("font_color", Color(0.08, 0.12, 0.08, 1.0))
    _chk_affordable.toggled.connect(func(pressed: bool):
        _is_affordable_only = pressed
        refresh_chart()
    )
    filter_bar.add_child(_chk_affordable)

    # 2. Pinned Recruit Quick-Hire + 1-Click Chain-Promotion Calculator Bar
    var calc_panel := PanelContainer.new()
    var c_sb := StyleBoxFlat.new()
    c_sb.bg_color = Color(0.13, 0.16, 0.20, 0.97)
    c_sb.border_width_left = 2
    c_sb.border_width_top = 2
    c_sb.border_width_right = 2
    c_sb.border_width_bottom = 2
    c_sb.border_color = Color(0.92, 0.76, 0.24, 1.0)
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
    _btn_recruit_1.focus_mode = Control.FOCUS_NONE
    _btn_recruit_1.text = "+1 Recruit (500g)"
    _btn_recruit_1.pressed.connect(func(): _execute_chain_buy_for("weapon_intern", 1))
    calc_hbox.add_child(_btn_recruit_1)

    _btn_recruit_5 = Button.new()
    _btn_recruit_5.focus_mode = Control.FOCUS_NONE
    _btn_recruit_5.text = "+5"
    _btn_recruit_5.pressed.connect(func(): _execute_chain_buy_for("weapon_intern", 5))
    calc_hbox.add_child(_btn_recruit_5)

    var vsep := VSeparator.new()
    calc_hbox.add_child(vsep)

    _calc_target_label = Label.new()
    _calc_target_label.text = "Selected: Old Kent / Medit. Ave (T1)"
    _calc_target_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42, 1.0))
    calc_hbox.add_child(_calc_target_label)

    _calc_summary_label = RichTextLabel.new()
    _calc_summary_label.bbcode_enabled = true
    _calc_summary_label.fit_content = true
    _calc_summary_label.scroll_active = false
    _calc_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _calc_summary_label.text = "Click $$ on ANY Monopoly Deed Card to auto-buy & promote in 1 transaction."
    calc_hbox.add_child(_calc_summary_label)

    _btn_buy_1 = Button.new()
    _btn_buy_1.focus_mode = Control.FOCUS_NONE
    _btn_buy_1.text = "Chain x1"
    _btn_buy_1.pressed.connect(func(): _execute_chain_buy_for(_selected_target_id, 1))
    calc_hbox.add_child(_btn_buy_1)

    _btn_buy_5 = Button.new()
    _btn_buy_5.focus_mode = Control.FOCUS_NONE
    _btn_buy_5.text = "x5"
    _btn_buy_5.pressed.connect(func(): _execute_chain_buy_for(_selected_target_id, 5))
    calc_hbox.add_child(_btn_buy_5)

    _btn_buy_10 = Button.new()
    _btn_buy_10.focus_mode = Control.FOCUS_NONE
    _btn_buy_10.text = "x10"
    _btn_buy_10.pressed.connect(func(): _execute_chain_buy_for(_selected_target_id, 10))
    calc_hbox.add_child(_btn_buy_10)

    _btn_buy_max = Button.new()
    _btn_buy_max.focus_mode = Control.FOCUS_NONE
    _btn_buy_max.text = "MAX (0)"
    _btn_buy_max.pressed.connect(func():
        var reg: Node = _get_or_create_registry()
        if reg:
            var m: int = int(reg.call("get_max_chain_affordable", _selected_target_id))
            if m > 0:
                _execute_chain_buy_for(_selected_target_id, m)
    )
    calc_hbox.add_child(_btn_buy_max)

    # 3. Scrollable Monopoly Colour Set Board
    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    outer_vbox.add_child(scroll)

    var num_cols: int = branches.size() + 1
    var col_total_h: float = CARD_TOP_Y + 4.0 * ROW_STEP + 6.0
    var canvas_w: float = PAD_X * 2.0 + float(num_cols) * COL_STEP
    var canvas_h: float = PAD_Y * 2.0 + col_total_h + 16.0

    _tree_canvas = Control.new()
    _tree_canvas.name = "TreeCanvas"
    _tree_canvas.custom_minimum_size = Vector2(canvas_w, canvas_h)
    _tree_canvas.draw.connect(_on_tree_canvas_draw)
    scroll.add_child(_tree_canvas)

    _columns.clear()
    _cards_by_id.clear()

    # Column 0: GO! Corner (Base Recruit)
    var intern_def: Dictionary = _registry.call("get_worker_def", "weapon_intern") if _registry else {}
    _build_set_column(
        "recruit",
        str(intern_def.get("set_name", "GO! CORNER")),
        str(intern_def.get("region_sub", "UK & USA • Base Recruit")),
        intern_def.get("set_color", Color(0.16, 0.62, 0.30, 1.0)),
        bool(intern_def.get("text_dark", false)),
        ["weapon_intern"],
        CARD_TOP_Y + ROW_STEP + 6.0
    )

    # Columns 1..14: Each Monopoly Set in its own Set Colour Column
    for branch_idx in range(branches.size()):
        var b: Dictionary = branches[branch_idx]
        var b_id: String = str(b.get("id", ""))
        var card_ids: Array[String] = [
            "%s_t1" % b_id,
            "%s_t2" % b_id,
            "%s_t3" % b_id,
            "%s_t4" % b_id
        ]
        _build_set_column(
            b_id,
            str(b.get("set_name", "MONOPOLY SET")),
            str(b.get("region_sub", b.get("label", ""))),
            b.get("set_color", Color(0.4, 0.4, 0.4, 1.0)),
            bool(b.get("text_dark", false)),
            card_ids,
            col_total_h
        )

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

func _build_set_column(branch_id: String, set_title: String, sub_title: String, set_col: Color, text_dark: bool, worker_ids: Array[String], col_h: float) -> void:
    var col_panel := Panel.new()
    col_panel.name = "SetCol_" + branch_id
    col_panel.size = Vector2(COL_W, col_h)
    col_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var lane_sb := StyleBoxFlat.new()
    var board_cream := Color(0.91, 0.94, 0.89, 1.0)
    lane_sb.bg_color = board_cream.lerp(set_col, 0.22)
    lane_sb.border_width_left = 3
    lane_sb.border_width_top = 3
    lane_sb.border_width_right = 3
    lane_sb.border_width_bottom = 3
    lane_sb.border_color = set_col.darkened(0.28)
    lane_sb.corner_radius_top_left = 8
    lane_sb.corner_radius_top_right = 8
    lane_sb.corner_radius_bottom_left = 8
    lane_sb.corner_radius_bottom_right = 8
    col_panel.add_theme_stylebox_override("panel", lane_sb)
    _tree_canvas.add_child(col_panel)

    # Monopoly Set Header Banner inside top of column
    var banner := Panel.new()
    banner.position = Vector2(4, 4)
    banner.size = Vector2(COL_W - 8.0, SET_HDR_H)
    banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var ban_sb := StyleBoxFlat.new()
    ban_sb.bg_color = set_col
    ban_sb.border_width_left = 2
    ban_sb.border_width_top = 2
    ban_sb.border_width_right = 2
    ban_sb.border_width_bottom = 2
    ban_sb.border_color = Color(0.08, 0.08, 0.10, 1.0)
    ban_sb.corner_radius_top_left = 5
    ban_sb.corner_radius_top_right = 5
    banner.add_theme_stylebox_override("panel", ban_sb)
    col_panel.add_child(banner)

    var ink: Color = Color(0.07, 0.07, 0.09, 1.0) if text_dark else Color(1.0, 1.0, 1.0, 1.0)

    var title_lbl := Label.new()
    title_lbl.text = set_title
    title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_lbl.position = Vector2(2, 3)
    title_lbl.custom_minimum_size = Vector2(COL_W - 12.0, 18.0)
    title_lbl.add_theme_font_size_override("font_size", 11)
    title_lbl.add_theme_color_override("font_color", ink)
    title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    banner.add_child(title_lbl)

    var sub_lbl := Label.new()
    sub_lbl.text = sub_title
    sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub_lbl.position = Vector2(2, 21)
    sub_lbl.custom_minimum_size = Vector2(COL_W - 12.0, 16.0)
    sub_lbl.add_theme_font_size_override("font_size", 9)
    sub_lbl.add_theme_color_override("font_color", ink)
    sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    banner.add_child(sub_lbl)

    for idx in range(worker_ids.size()):
        var wid: String = worker_ids[idx]
        var local_pos := Vector2(6.0, CARD_TOP_Y + float(idx) * ROW_STEP)
        _create_monopoly_pokemon_card(col_panel, wid, local_pos)

    _columns.append({
        "branch_id": branch_id,
        "panel": col_panel,
        "worker_ids": worker_ids,
        "height": col_h
    })

func _create_monopoly_pokemon_card(parent_col: Control, worker_id: String, local_pos: Vector2) -> void:
    var reg: Node = _get_or_create_registry()
    if not reg:
        return
    var def: Dictionary = reg.call("get_worker_def", worker_id)
    if def.is_empty():
        return

    var set_col: Color = def.get("set_color", Color(0.4, 0.4, 0.4, 1.0))
    var text_dark: bool = bool(def.get("text_dark", false))
    var header_ink: Color = Color(0.07, 0.07, 0.09, 1.0) if text_dark else Color(1.0, 1.0, 1.0, 1.0)

    var card := Panel.new()
    card.name = "Card_" + worker_id
    card.position = local_pos
    card.custom_minimum_size = Vector2(CARD_W, CARD_H)
    card.size = Vector2(CARD_W, CARD_H)
    card.mouse_filter = Control.MOUSE_FILTER_PASS

    var card_sb := StyleBoxFlat.new()
    card_sb.bg_color = Color(0.99, 0.98, 0.94, 1.0)
    card_sb.border_width_left = 3
    card_sb.border_width_top = 3
    card_sb.border_width_right = 3
    card_sb.border_width_bottom = 3
    card_sb.border_color = set_col.darkened(0.35)
    card_sb.corner_radius_top_left = 6
    card_sb.corner_radius_top_right = 6
    card_sb.corner_radius_bottom_left = 6
    card_sb.corner_radius_bottom_right = 6
    card.add_theme_stylebox_override("panel", card_sb)
    parent_col.add_child(card)

    # 1. Classic Monopoly Title Deed Colour Header Block
    var header := Panel.new()
    header.position = Vector2(5, 5)
    header.size = Vector2(CARD_W - 10.0, 38.0)
    header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var h_sb := StyleBoxFlat.new()
    h_sb.bg_color = set_col
    h_sb.border_width_left = 2
    h_sb.border_width_top = 2
    h_sb.border_width_right = 2
    h_sb.border_width_bottom = 2
    h_sb.border_color = Color(0.08, 0.08, 0.10, 1.0)
    header.add_theme_stylebox_override("panel", h_sb)
    card.add_child(header)

    var rank_idx: int = int(def.get("rank", 0))
    var deed_lbl := Label.new()
    deed_lbl.text = ("TITLE DEED • RANK T%d" % rank_idx) if rank_idx > 0 else "PASS GO! • BASE RECRUIT"
    deed_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    deed_lbl.position = Vector2(2, 2)
    deed_lbl.custom_minimum_size = Vector2(CARD_W - 14.0, 13.0)
    deed_lbl.add_theme_font_size_override("font_size", 8)
    deed_lbl.add_theme_color_override("font_color", header_ink)
    deed_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header.add_child(deed_lbl)

    var prop_lbl := Label.new()
    prop_lbl.text = str(def.get("name", worker_id))
    prop_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prop_lbl.clip_text = true
    prop_lbl.position = Vector2(3, 16)
    prop_lbl.custom_minimum_size = Vector2(CARD_W - 16.0, 18.0)
    prop_lbl.add_theme_font_size_override("font_size", 10)
    prop_lbl.add_theme_color_override("font_color", header_ink)
    prop_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header.add_child(prop_lbl)

    # 2. Pokemon Card Artwork Window (Set-Coloured Stage + Worker + Integrated Weapon + Wings)
    var art_box := Panel.new()
    art_box.position = Vector2(8, 47)
    art_box.size = Vector2(CARD_W - 16.0, 66.0)
    art_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var a_sb := StyleBoxFlat.new()
    a_sb.bg_color = set_col.darkened(0.38)
    a_sb.border_width_left = 2
    a_sb.border_width_top = 2
    a_sb.border_width_right = 2
    a_sb.border_width_bottom = 2
    a_sb.border_color = Color(0.84, 0.68, 0.22, 1.0)
    art_box.add_theme_stylebox_override("panel", a_sb)
    card.add_child(art_box)

    var stage_floor := ColorRect.new()
    stage_floor.color = set_col.darkened(0.15)
    stage_floor.position = Vector2(2, 44)
    stage_floor.size = Vector2(CARD_W - 20.0, 20.0)
    stage_floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
    art_box.add_child(stage_floor)

    if bool(def.get("winged", false)) and _wings_tex:
        var wings_rect := TextureRect.new()
        wings_rect.texture = _wings_tex
        wings_rect.position = Vector2(8, 2)
        wings_rect.size = Vector2(112, 60)
        wings_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        wings_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        wings_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        art_box.add_child(wings_rect)

    var torso_tint: Color = def.get("color", Color.WHITE)
    _add_atlas_part(art_box, LEGS_TEX, 0, Vector2(22, 10), Vector2(42, 42), Color.WHITE)
    _add_atlas_part(art_box, TORSO_TEX, rank_idx % 4, Vector2(22, 10), Vector2(42, 42), torso_tint)
    _add_atlas_part(art_box, HEAD_TEX, rank_idx % 4, Vector2(22, 10), Vector2(42, 42), Color.WHITE)

    var wep_tex: Texture2D = _load_weapon_tex(str(def.get("tex", "")))
    if wep_tex:
        var wep_rect := TextureRect.new()
        wep_rect.texture = wep_tex
        wep_rect.position = Vector2(64, 10)
        wep_rect.size = Vector2(42, 42)
        wep_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        wep_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        wep_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        art_box.add_child(wep_rect)

    var type_badge := Label.new()
    type_badge.text = str(def.get("branch_label", "")).to_upper()
    type_badge.position = Vector2(5, 50)
    type_badge.add_theme_font_size_override("font_size", 8)
    type_badge.add_theme_color_override("font_color", Color(1.0, 0.97, 0.84, 1.0))
    type_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
    art_box.add_child(type_badge)

    # 3. Monopoly Rent / Strike Stat Line
    var stat_lbl := Label.new()
    stat_lbl.text = "PWR %s • %.2fs • %dT" % [_format_short(float(def.get("dmg", 0.0))), float(def.get("rate", 1.0)), int(def.get("aoe", 1))]
    stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stat_lbl.position = Vector2(4, 116)
    stat_lbl.custom_minimum_size = Vector2(CARD_W - 8.0, 16.0)
    stat_lbl.add_theme_font_size_override("font_size", 9)
    stat_lbl.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
    stat_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(stat_lbl)

    # 4. Bottom Action Row: 1-Click Chain Buy Button + xN Count/Fire Button
    var buy_btn := Button.new()
    buy_btn.focus_mode = Control.FOCUS_NONE
    buy_btn.text = "$$ %s" % _format_short(float(def.get("cost", 0.0)))
    buy_btn.position = Vector2(6, 136)
    buy_btn.size = Vector2(82, 28)
    buy_btn.add_theme_font_size_override("font_size", 10)
    var b_sb := StyleBoxFlat.new()
    b_sb.bg_color = Color(0.20, 0.68, 0.24, 1.0)
    b_sb.border_width_left = 2
    b_sb.border_width_top = 2
    b_sb.border_width_right = 2
    b_sb.border_width_bottom = 2
    b_sb.border_color = Color(0.08, 0.14, 0.08, 1.0)
    b_sb.corner_radius_top_left = 4
    b_sb.corner_radius_top_right = 4
    b_sb.corner_radius_bottom_left = 4
    b_sb.corner_radius_bottom_right = 4
    buy_btn.add_theme_stylebox_override("normal", b_sb)
    buy_btn.add_theme_stylebox_override("hover", b_sb)
    buy_btn.add_theme_stylebox_override("pressed", b_sb)
    buy_btn.pressed.connect(func():
        _selected_target_id = worker_id
        _execute_chain_buy_for(worker_id, 1)
        _show_worker_tooltip(worker_id, false)
    )
    buy_btn.gui_input.connect(_on_buy_right_click.bind(worker_id))
    card.add_child(buy_btn)

    var count_btn := Button.new()
    count_btn.focus_mode = Control.FOCUS_NONE
    count_btn.text = "x0"
    count_btn.position = Vector2(92, 136)
    count_btn.size = Vector2(46, 28)
    count_btn.add_theme_font_size_override("font_size", 10)
    var c_sb := StyleBoxFlat.new()
    c_sb.bg_color = Color(0.92, 0.89, 0.80, 1.0)
    c_sb.border_width_left = 2
    c_sb.border_width_top = 2
    c_sb.border_width_right = 2
    c_sb.border_width_bottom = 2
    c_sb.border_color = Color(0.12, 0.12, 0.14, 1.0)
    c_sb.corner_radius_top_left = 4
    c_sb.corner_radius_top_right = 4
    c_sb.corner_radius_bottom_left = 4
    c_sb.corner_radius_bottom_right = 4
    count_btn.add_theme_stylebox_override("normal", c_sb)
    count_btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
    count_btn.pressed.connect(func():
        _selected_target_id = worker_id
        _fire_worker_qty(worker_id, 1)
    )
    count_btn.gui_input.connect(_on_sell_right_click.bind(worker_id))
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
        "parent_col": parent_col,
        "local_pos": local_pos,
        "set_color": set_col,
        "card_style": card_sb,
        "buy_btn": buy_btn,
        "count_btn": count_btn,
        "buy_style": b_sb,
        "center": Vector2.ZERO
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
    if path == "":
        return null
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

func _on_buy_right_click(event: InputEvent, worker_id: String) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
        _selected_target_id = worker_id
        _execute_chain_buy_for(worker_id, 5)
        _show_worker_tooltip(worker_id, false)

func _on_sell_right_click(event: InputEvent, worker_id: String) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
        _selected_target_id = worker_id
        _fire_worker_qty(worker_id, 5)

func _fire_worker_qty(worker_id: String, amt: int) -> void:
    var reg: Node = _get_or_create_registry()
    if not reg:
        return
    var fired: int = int(reg.call("fire_worker", worker_id, amt))
    if fired > 0:
        var def: Dictionary = reg.call("get_worker_def", worker_id)
        _status_msg = "Fired %dx %s." % [fired, str(def.get("name", worker_id))]
        _play_ui_sound(false)
        refresh_chart()
        _show_worker_tooltip(worker_id, true)

func _execute_chain_buy_for(worker_id: String, amount: int) -> void:
    var reg: Node = _get_or_create_registry()
    if not reg or amount <= 0:
        return
    var def: Dictionary = reg.call("get_worker_def", worker_id)
    var q: Dictionary = reg.call("calculate_chain_quote", worker_id, amount)
    var cost: float = float(q.get("total_cost", 0.0))
    var cash: float = float(Gvars.CashCount) if Gvars else 0.0
    if cash < cost:
        _status_msg = "[color=#ff7777]Need %sg (Have %sg)[/color]" % [
            Gconsts.add_comma_to_int(int(cost)), Gconsts.add_comma_to_int(int(cash))
        ]
        _play_ui_sound(false)
        refresh_chart()
        return

    var res: Dictionary = reg.call("execute_chain_purchase", worker_id, amount)
    if bool(res.get("success", false)):
        _status_msg = "[color=#66ff88]Hired %dx %s (-%sg)![/color]" % [
            amount, str(def.get("name", worker_id)), Gconsts.add_comma_to_int(int(cost))
        ]
        _play_ui_sound(true)
        refresh_chart()

func refresh_chart() -> void:
    var reg: Node = _get_or_create_registry()
    if not reg:
        return

    var query: String = _search_input.text.strip_edges().to_lower() if is_instance_valid(_search_input) else ""
    var selected_branch_idx: int = _set_dropdown.selected if is_instance_valid(_set_dropdown) else 0
    var branches: Array = reg.get("BRANCHES")
    var selected_branch_id: String = ""
    if selected_branch_idx > 0 and selected_branch_idx <= branches.size():
        var sel_b: Dictionary = branches[selected_branch_idx - 1]
        selected_branch_id = str(sel_b.get("id", ""))

    var cash: float = float(Gvars.CashCount) if Gvars else 0.0
    var defs: Dictionary = reg.call("get_all_defs")

    for worker_id in _cards_by_id.keys():
        var entry: Dictionary = _cards_by_id[worker_id]
        var def: Dictionary = defs.get(worker_id, {})
        var cnt: int = int(reg.call("get_count", worker_id))
        var can_buy_direct: bool = bool(reg.call("can_purchase", worker_id, 1))
        var chain_q: Dictionary = reg.call("calculate_chain_quote", worker_id, 1)
        var chain_cost: float = float(chain_q.get("total_cost", 0.0))
        var can_chain_afford: bool = bool(chain_q.get("valid", false)) and chain_cost <= cash

        var count_btn: Button = entry["count_btn"]
        count_btn.text = "x%d" % cnt

        var buy_btn: Button = entry["buy_btn"]
        buy_btn.text = "$$ %s" % _format_short(chain_cost)

        var b_sb: StyleBoxFlat = entry["buy_style"]
        if can_buy_direct:
            b_sb.bg_color = Color(0.20, 0.72, 0.24, 1.0)
        elif can_chain_afford:
            b_sb.bg_color = Color(0.16, 0.62, 0.38, 1.0)
        else:
            b_sb.bg_color = Color(0.62, 0.20, 0.20, 1.0)

        var card_sb: StyleBoxFlat = entry["card_style"]
        var base_set_col: Color = entry["set_color"]
        if worker_id == _selected_target_id:
            card_sb.border_color = Color(1.0, 0.82, 0.10, 1.0)
        else:
            card_sb.border_color = base_set_col.darkened(0.35)

        var hay: String = ("%s %s %s %s %s" % [
            str(def.get("name", "")),
            str(def.get("branch_label", "")),
            str(def.get("set_name", "")),
            str(def.get("region_sub", "")),
            worker_id
        ]).to_lower()
        var match_q: bool = query.is_empty() or (query in hay)
        var match_set: bool = selected_branch_id == "" or worker_id == "weapon_intern" or str(def.get("branch_id", "")) == selected_branch_id
        var match_aff: bool = (not _is_affordable_only) or can_chain_afford

        var card: Control = entry["card"]
        card.visible = match_q and match_set and match_aff

    # Dynamically pack visible Monopoly Set Columns from left to right
    var x_cursor: float = PAD_X
    for col_info in _columns:
        var col_panel: Control = col_info["panel"]
        var w_ids: Array = col_info["worker_ids"]
        var any_vis: bool = false
        for wid in w_ids:
            if _cards_by_id.has(wid):
                var c_ctrl: Control = _cards_by_id[wid]["card"]
                if c_ctrl.visible:
                    any_vis = true
                    break
        col_panel.visible = any_vis
        if any_vis:
            col_panel.position = Vector2(x_cursor, PAD_Y)
            for wid in w_ids:
                if _cards_by_id.has(wid):
                    var lpos: Vector2 = _cards_by_id[wid]["local_pos"]
                    _cards_by_id[wid]["center"] = col_panel.position + lpos + Vector2(CARD_W * 0.5, CARD_H * 0.5)
            x_cursor += COL_STEP

    if is_instance_valid(_tree_canvas):
        var min_h: float = PAD_Y * 2.0 + CARD_TOP_Y + 4.0 * ROW_STEP + 24.0
        _tree_canvas.custom_minimum_size = Vector2(maxf(1120.0, x_cursor + PAD_X), min_h)
        _tree_canvas.queue_redraw()

    _refresh_calculator_bar()

func _refresh_calculator_bar() -> void:
    var reg: Node = _get_or_create_registry()
    if not reg or not is_instance_valid(_calc_target_label):
        return
    var cash: float = float(Gvars.CashCount) if Gvars else 0.0
    var rec_cnt: int = int(reg.call("get_count", "weapon_intern"))
    if is_instance_valid(_recruit_count_label):
        _recruit_count_label.text = "Recruits: %d" % rec_cnt
    if is_instance_valid(_btn_recruit_1):
        _btn_recruit_1.disabled = (cash < 500.0)
    if is_instance_valid(_btn_recruit_5):
        _btn_recruit_5.disabled = (cash < 2500.0)

    var def: Dictionary = reg.call("get_worker_def", _selected_target_id)
    if def.is_empty():
        return
    var q1: Dictionary = reg.call("calculate_chain_quote", _selected_target_id, 1)
    var max_aff: int = int(reg.call("get_max_chain_affordable", _selected_target_id))
    var cost1: float = float(q1.get("total_cost", 0.0))
    var recruits1: int = int(q1.get("recruits_needed", 0))

    _calc_target_label.text = "%s (T%d)" % [str(def.get("name", _selected_target_id)), int(def.get("rank", 0))]
    var suffix: String = ("  |  " + _status_msg) if _status_msg != "" else ""
    _calc_summary_label.text = "1-Click Chain: [b][color=#66ff88]%sg[/color][/b] (Recruits: %d) | Max: [b]%d[/b]%s" % [
        Gconsts.add_comma_to_int(int(cost1)), recruits1, max_aff, suffix
    ]

    _btn_buy_1.disabled = (cash < cost1)
    _btn_buy_5.disabled = (max_aff < 5)
    _btn_buy_10.disabled = (max_aff < 10)
    _btn_buy_max.text = "MAX (%d)" % max_aff
    _btn_buy_max.disabled = (max_aff <= 0)

func _on_tree_canvas_draw() -> void:
    var reg: Node = _get_or_create_registry()
    if not reg:
        return
    var locked_pts := PackedVector2Array()
    var unlocked_pts := PackedVector2Array()
    var defs: Dictionary = reg.call("get_all_defs")
    var cash: float = float(Gvars.CashCount) if Gvars else 0.0

    for worker_id in _cards_by_id.keys():
        var child_card: Control = _cards_by_id[worker_id]["card"]
        if not child_card.visible:
            continue
        var def: Dictionary = defs.get(worker_id, {})
        var parent_id: String = str(def.get("upgrades_from", ""))
        if parent_id == "" or parent_id == "weapon_intern" or not _cards_by_id.has(parent_id):
            continue
        var parent_card: Control = _cards_by_id[parent_id]["card"]
        if not parent_card.visible:
            continue

        var p_child: Vector2 = _cards_by_id[worker_id]["center"]
        var p_parent: Vector2 = _cards_by_id[parent_id]["center"]
        var q1: Dictionary = reg.call("calculate_chain_quote", worker_id, 1)
        var target_arr: PackedVector2Array = unlocked_pts if (bool(q1.get("valid", false)) and float(q1.get("total_cost", 0.0)) <= cash) else locked_pts

        target_arr.append(p_parent)
        target_arr.append(p_child)

    if not locked_pts.is_empty():
        _tree_canvas.draw_multiline(locked_pts, Color(0.62, 0.14, 0.14, 0.70), 4.0)
    if not unlocked_pts.is_empty():
        _tree_canvas.draw_multiline(unlocked_pts, Color(0.08, 0.62, 0.16, 0.92), 5.5)

func _show_worker_tooltip(worker_id: String, is_sell: bool) -> void:
    var reg: Node = _get_or_create_registry()
    if not reg or not _tooltip_panel or not _tooltip_label:
        return
    var def: Dictionary = reg.call("get_worker_def", worker_id)
    if def.is_empty():
        return
    var cost: float = float(def.get("cost", 0.0))
    var cnt: int = int(reg.call("get_count", worker_id))

    if is_sell:
        var refund: int = int(cost * 0.5)
        _tooltip_label.text = "[b]%s (Hired: %d)[/b]\n[i]Left-click[/i]: Fire 1 (+%sg)\n[i]Right-click[/i]: Fire 5 (+%sg)" % [
            str(def.get("name", worker_id)), cnt, Gconsts.add_comma_to_int(refund), Gconsts.add_comma_to_int(refund * 5)
        ]
    else:
        var q1: Dictionary = reg.call("calculate_chain_quote", worker_id, 1)
        var max_aff: int = int(reg.call("get_max_chain_affordable", worker_id))
        _tooltip_label.text = "[b]%s[/b] — Step: [color=#ffe066]%sg[/color]\n%s (%s) • Rank %d\n1-Click Full Chain Cost: [color=#66ff88]%sg[/color] (Max Affordable: %d)\nStrike Power: %s | Cycle: %.2fs | AOE: %d tiles\n[i]Left-click $$: 1-Click Chain Buy x1 | Right-click $$: x5[/i]" % [
            str(def.get("name", worker_id)),
            Gconsts.add_comma_to_int(int(cost)),
            str(def.get("set_name", "")),
            str(def.get("branch_label", "")),
            int(def.get("rank", 0)),
            Gconsts.add_comma_to_int(int(q1.get("total_cost", 0.0))),
            max_aff,
            Gconsts.add_comma_to_int(int(def.get("dmg", 0.0))),
            float(def.get("rate", 1.0)),
            int(def.get("aoe", 1))
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
