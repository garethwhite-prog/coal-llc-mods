extends Object

const CUSTOM_DISPLAY_STATS: Array[String] = [
	"ball_blast_damage",
	"ball_blast_radius",
	"ball_fire_rate",
	"employee_miner_range",
	"employee_miner_pickup_speed",
	"collector_range"
]

func refresh(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var panel = chain.reference_object
	if not is_instance_valid(panel) or not Gvars or not Gvars.passives:
		return

	var p = Gvars.passives
	for stat in CUSTOM_DISPLAY_STATS:
		var val: float = 0.0
		if stat in p:
			val = float(p.get(stat))
		elif p.has_meta(stat):
			val = float(p.get_meta(stat))

		if val > 0.0:
			var label := RichTextLabel.new()
			label.text = "Increase " + stat.replace("_", " ").capitalize() + " +" + str(roundi(val * 100.0)) + "%"
			label.fit_content = true
			panel.add_child(label)
