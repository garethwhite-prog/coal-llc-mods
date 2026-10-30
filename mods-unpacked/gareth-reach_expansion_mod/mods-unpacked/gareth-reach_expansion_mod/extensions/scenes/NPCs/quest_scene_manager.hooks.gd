extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var qm = chain.reference_object
	if not is_instance_valid(qm): return

	var extra_reach = 0.0
	if Gvars and ("passives" in Gvars) and Gvars.passives and ("player_reach_bonus" in Gvars.passives):
		extra_reach = float(Gvars.passives.player_reach_bonus) * 24.0

	if extra_reach > 0.0:
		for qp in qm.find_children("*", "Area2D", true, false):
			var col = qp.find_child("CollisionShape2D", true, false)
			if is_instance_valid(col) and col.shape and ("radius" in col.shape):
				col.shape.radius += extra_reach
