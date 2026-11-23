extends Node2D

const HEAD_TEX := preload("res://assets/NPCs/Player/playerSheet_Head.png")
const TORSO_TEX := preload("res://assets/NPCs/Player/playerSheet_Torso.png")
const LEGS_TEX := preload("res://assets/NPCs/Player/playerSheet_Legs.png")

var worker_def: Dictionary = {}
var stacked_count: int = 1
var tilemap: TileMapManager = null

var _velocity: Vector2 = Vector2.ZERO
var _is_on_floor: bool = false
var _attack_timer: float = 0.25
var _move_dir: float = 1.0
var _wander_timer: float = 0.0
var _fx_lines: Array = []
var _wep_sprite: Sprite2D = null

func _ready() -> void:
    z_index = 6
    _move_dir = -1.0 if randf() < 0.5 else 1.0
    _build_visuals()

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

func _build_visuals() -> void:
    var root_spr := Node2D.new()
    root_spr.name = "Visuals"
    add_child(root_spr)

    var rank_idx: int = int(worker_def.get("rank", 0))
    var tint: Color = worker_def.get("color", Color.WHITE)

    if bool(worker_def.get("winged", false)):
        var w_tex: Texture2D = _resolve_wings_texture()
        if w_tex:
            var w := Sprite2D.new()
            w.texture = w_tex
            w.position = Vector2(0, -14)
            w.scale = Vector2(1.1, 1.1)
            root_spr.add_child(w)

    _add_part(root_spr, LEGS_TEX, 0, Color.WHITE)
    _add_part(root_spr, TORSO_TEX, rank_idx % 4, tint)
    _add_part(root_spr, HEAD_TEX, rank_idx % 4, Color.WHITE)

    var tex_path: String = str(worker_def.get("tex", ""))
    var wep_tex: Texture2D = null
    if ResourceLoader.exists(tex_path):
        wep_tex = load(tex_path)
    elif FileAccess.file_exists(tex_path):
        var img: Image = Image.load_from_file(tex_path)
        if img:
            wep_tex = ImageTexture.create_from_image(img)

    if wep_tex:
        _wep_sprite = Sprite2D.new()
        _wep_sprite.texture = wep_tex
        _wep_sprite.position = Vector2(9, -10)
        _wep_sprite.scale = Vector2(0.85, 0.85)
        root_spr.add_child(_wep_sprite)

func _add_part(parent: Node2D, sheet: Texture2D, col: int, tint: Color) -> void:
    var at := AtlasTexture.new()
    at.atlas = sheet
    at.region = Rect2(float(col * 16), 0.0, 16.0, 16.0)
    var s := Sprite2D.new()
    s.texture = at
    s.position = Vector2(0, -8)
    s.modulate = tint
    parent.add_child(s)

func _physics_process(delta: float) -> void:
    var is_winged: bool = bool(worker_def.get("winged", false))
    _wander_timer -= delta
    if _wander_timer <= 0.0:
        _wander_timer = randf_range(1.6, 3.4)
        var player: Node2D = _find_player()
        if is_instance_valid(player) and global_position.distance_to(player.global_position) > 260.0:
            _move_dir = 1.0 if player.global_position.x > global_position.x else -1.0
        else:
            _move_dir = -1.0 if randf() < 0.5 else 1.0

    if is_winged:
        var player: Node2D = _find_player()
        var hover_target := Vector2(global_position.x + _move_dir * 45.0, -48.0)
        if is_instance_valid(player):
            hover_target = player.global_position + Vector2(_move_dir * randf_range(32.0, 110.0), randf_range(-64.0, -24.0))
        global_position = global_position.lerp(hover_target, minf(1.0, delta * 2.2))
    else:
        Bus.is_employee_on_floor.emit(self)
        if not _is_on_floor:
            _velocity.y += 490.0 * delta
        else:
            _velocity.y = 0.0
        _velocity.x = 58.0 * _move_dir
        global_position += _velocity * delta
        if _is_on_floor and randf() < 0.02:
            _velocity.y = -150.0

    var vis: Node = get_node_or_null("Visuals")
    if vis:
        vis.scale.x = _move_dir

    _attack_timer -= delta
    if _attack_timer <= 0.0:
        _attack_timer = maxf(0.14, float(worker_def.get("rate", 0.8)))
        _perform_weapon_strike()

    if not _fx_lines.is_empty():
        for i in range(_fx_lines.size() - 1, -1, -1):
            _fx_lines[i]["ttl"] -= delta
            if _fx_lines[i]["ttl"] <= 0.0:
                _fx_lines.remove_at(i)
        queue_redraw()

func _perform_weapon_strike() -> void:
    var aoe: int = int(worker_def.get("aoe", 2))
    var total_dmg: float = float(worker_def.get("dmg", 25.0)) * float(stacked_count)
    var style: String = str(worker_def.get("style", "melee"))
    var col: Color = worker_def.get("color", Color.WHITE)

    var reach_px: float = 48.0 if style == "melee" else 176.0
    var target_world: Vector2 = global_position + Vector2(_move_dir * randf_range(24.0, reach_px), randf_range(-24.0, 64.0))
    var player: Node2D = _find_player()
    if is_instance_valid(player):
        target_world = player.global_position + Vector2(randf_range(-reach_px, reach_px), randf_range(-16.0, 96.0))

    var center_tile := Vector2i(int(floor(target_world.x / 16.0)), int(floor(target_world.y / 16.0)))
    var r: int = maxi(1, mini(aoe, 6))
    for dx in range(-r, r + 1):
        for dy in range(-r, r + 1):
            if dx * dx + dy * dy <= r * r:
                var tile_world := Vector2(float(center_tile.x + dx) * 16.0 + 8.0, float(center_tile.y + dy) * 16.0 + 8.0)
                Bus.DamageTile.emit(tile_world, total_dmg)

    if _wep_sprite and is_instance_valid(_wep_sprite):
        _wep_sprite.rotation = _move_dir * 0.45

    if style != "melee":
        _fx_lines.append({
            "from": to_local(global_position + Vector2(0, -10)),
            "to": to_local(target_world),
            "color": col,
            "ttl": 0.14
        })
        queue_redraw()

func _draw() -> void:
    for fx in _fx_lines:
        var c: Color = fx["color"]
        c.a = clampf(float(fx["ttl"]) / 0.14, 0.0, 1.0)
        draw_line(fx["from"], fx["to"], c, 2.5)
        draw_circle(fx["to"], 5.0, c)

func _find_player() -> Node2D:
    var tree: SceneTree = get_tree()
    if not tree:
        return null
    var players: Array = tree.get_nodes_in_group("player")
    if players.size() > 0 and is_instance_valid(players[0]):
        return players[0]
    return null
