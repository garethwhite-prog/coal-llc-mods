class_name GrenadeEquipEffect
extends EquipEffect

@export var damage: float = 100.0
@export var radius: float = 4.0
@export var animated_texture: Texture2D

const MULTI_CLICK_DELAY: int = 25
const PLACEMENT_RATE: int = 8

var _using_item: bool = false
var first_click: bool = true
var delay: int = MULTI_CLICK_DELAY

func start(player, item):
	_using_item = false
	player.tool.texture = null
	player.equipped_item_sprite_parent.visible = true
	player.equipped_item_sprite.texture = item.itemTexture

func end(player):
	player.equipped_item_sprite_parent.visible = false
	player.equipped_item_sprite.texture = null

func physics_process(player, delta):
	if Input.is_action_pressed("useItem"):
		_using_item = true
	elif Input.is_action_just_released("useItem"):
		_using_item = false
	elif Input.is_action_just_pressed("toggle_use_item"):
		_using_item = not _using_item

	if _using_item:
		if first_click:
			throw_grenade(player)
			first_click = false
			delay = MULTI_CLICK_DELAY
		elif delay == 0:
			throw_grenade(player)
			delay = PLACEMENT_RATE
		else:
			delay -= 1
	else:
		delay = MULTI_CLICK_DELAY
		first_click = true

func throw_grenade(player):
	var grenade_script = load("res://mods-unpacked/gareth-grenade_mod/scripts/bouncing_grenade.gd")
	var grenade := CharacterBody2D.new()
	grenade.set_script(grenade_script)
	grenade.damage = damage
	grenade.radius = radius
	grenade.bomb_texture = animated_texture
	grenade.global_position = player.global_position

	var mouse_pos: Vector2 = player.get_global_mouse_position()
	var throw_dir: Vector2 = (mouse_pos - player.global_position).normalized()
	grenade.velocity = Vector2(throw_dir.x * 380.0, min(-180.0, throw_dir.y * 380.0 - 140.0))

	player.get_parent().add_child(grenade)

	var inventory: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
	inventory.sellFromInventory(player.item_equipped, 1)
	Bus.inventory_changed.emit()