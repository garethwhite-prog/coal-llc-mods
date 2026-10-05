extends "res://resources/passive_effects/passives.gd"

@export var drill_speed: float = 0.0
@export var axe_speed: float = 0.0
@export var gun_rate: float = 0.0

func apply_effect(property_name: String, amount: float) -> void:
	if property_name == "drill_speed":
		drill_speed += amount
		return
	elif property_name == "axe_speed":
		axe_speed += amount
		return
	elif property_name == "gun_rate":
		gun_rate += amount
		return
	super.apply_effect(property_name, amount)

func save() -> Dictionary:
	var res: Dictionary = super.save()
	if res.has("passives"):
		res["passives"]["drill_speed"] = drill_speed
		res["passives"]["axe_speed"] = axe_speed
		res["passives"]["gun_rate"] = gun_rate
	return res

func load_save(save_dict: Dictionary) -> void:
	super.load_save(save_dict)
	drill_speed = 0.0
	axe_speed = 0.0
	gun_rate = 0.0
	if save_dict.has("passives"):
		var p: Dictionary = save_dict["passives"]
		if p.has("drill_speed"):
			drill_speed = float(p["drill_speed"])
		if p.has("axe_speed"):
			axe_speed = float(p["axe_speed"])
		if p.has("gun_rate"):
			gun_rate = float(p["gun_rate"])

func reset() -> void:
	super.reset()
	drill_speed = 0.0
	axe_speed = 0.0
	gun_rate = 0.0