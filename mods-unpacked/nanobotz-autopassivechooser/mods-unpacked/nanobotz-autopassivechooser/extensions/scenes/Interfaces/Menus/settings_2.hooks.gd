extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	await chain.execute_next([])
	var menu = chain.reference_object
	if not is_instance_valid(menu): return
	
	var passive_list = menu.find_child("passive_list", true, false)
	if not is_instance_valid(passive_list):
		passive_list = menu.find_child("VBoxContainer", true, false)
		
	if is_instance_valid(passive_list) and not passive_list.has_node("BouncingBallDamage"):
		# Safely grab the very first passive row to use as a clone template
		var template = null
		if passive_list.get_child_count() > 0:
			template = passive_list.get_child(0)
					
		if is_instance_valid(template):
			var keys = ["Bouncing Ball Damage", "Bouncing Ball Radius", "Bouncing Ball Fire Rate"]
			var internal_keys = ["ball_blast_damage", "ball_blast_radius", "ball_fire_rate"]
			
			for i in range(keys.size()):
				var row = template.duplicate()
				row.name = keys[i].replace(" ", "")
				row.visible = true
				
				# Reset text and keys for the cloned row
				var lbl = row.find_child("*Label*", true, false)
				if is_instance_valid(lbl): lbl.text = keys[i]
				row.set_meta("passive_key", internal_keys[i])
				
				passive_list.call_deferred("add_child", row)
