class_name BouncingBallEquipEffect
extends EquipEffect

@export var damage: float = 95.0
@export var radius: float = 3.2

var weapon_visual: Sprite2D = null
var throw_cooldown: float = 0.0
var _is_using: bool = false
var _auto_throw_toggle: bool = false
var held_item = null

func start(player, item):
	held_item = item
	if "tool" in player and player.tool:
		player.tool.visible = false

	weapon_visual = Sprite2D.new()
	weapon_visual.texture = item.itemTexture
	weapon_visual.offset = Vector2(0, -6)
	weapon_visual.position = Vector2(6, 2)
	weapon_visual.visible = true
	player.add_child(weapon_visual)
	_is_using = false
	_auto_throw_toggle = false

func end(player):
	if "tool" in player and player.tool:
		player.tool.visible = true
	if weapon_visual and is_instance_valid(weapon_visual):
		weapon_visual.queue_free()
	_is_using = false
	_auto_throw_toggle = false

func physics_process(player, delta):
	if throw_cooldown > 0.0:
		throw_cooldown -= delta

	if weapon_visual and is_instance_valid(weapon_visual):
		var p_pos: Vector2 = player.global_position
		var pointer_pos: Vector2 = player.pointer_global_pos
		var angle: float = (pointer_pos - p_pos).angle()
		weapon_visual.rotation = angle
		weapon_visual.flip_v = (pointer_pos.x < p_pos.x)

	if Input.is_action_pressed("useItem") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_is_using = true
	elif Input.is_action_just_released("useItem") or (not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not _auto_throw_toggle):
		_is_using = false

	if Input.is_action_just_pressed("toggle_use_item") or Input.is_action_just_pressed("rightMouseClick"):
		_auto_throw_toggle = not _auto_throw_toggle
		_is_using = _auto_throw_toggle

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_is_using = true

	if _is_using and throw_cooldown <= 0.0:
		_throw_bouncing_ball(player)

func _get_passive_stat(stat_name: String) -> float:
	if not Gvars or not ("passives" in Gvars) or not Gvars.passives:
		return 0.0
	var p = Gvars.passives
	if p.has_meta(stat_name):
		return float(p.get_meta(stat_name))
	if stat_name in p:
		return float(p.get(stat_name))
	return 0.0

func _throw_bouncing_ball(player) -> void:
	var fire_rate_mult: float = 1.0 + _get_passive_stat("ball_fire_rate")
	throw_cooldown = max(0.12, 0.48 / fire_rate_mult)

	var p_pos: Vector2 = player.global_position
	var pointer_pos: Vector2 = player.pointer_global_pos
	var dir: Vector2 = (pointer_pos - p_pos).normalized()

	if weapon_visual and is_instance_valid(weapon_visual):
		var orig_pos = weapon_visual.position
		weapon_visual.position -= dir * 4.0
		var tween = player.create_tween()
		tween.tween_property(weapon_visual, "position", orig_pos, 0.09)

	var proj_script = load("res://mods-unpacked/gareth-bouncing_ball_mod/scripts/bouncing_ball_projectile.gd")
	var proj := CharacterBody2D.new()
	proj.set_script(proj_script)

	var dmg_mult: float = 1.0 + _get_passive_stat("ball_blast_damage")
	proj.damage = damage * dmg_mult

	var rad_mult: float = 1.0 + _get_passive_stat("ball_blast_radius")
	proj.radius = radius * rad_mult

	if held_item and "itemTexture" in held_item:
		proj.ball_texture = held_item.itemTexture

	proj.global_position = p_pos + (dir * 18.0)
	proj.velocity = Vector2(dir.x * 440.0, min(-140.0, dir.y * 440.0 - 100.0))

	var parent = player.get_parent()
	if parent:
		parent.add_child(proj)
	else:
		player.add_child(proj)