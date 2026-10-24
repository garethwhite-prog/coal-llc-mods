class_name RecordCelebrator
extends Node

static func celebrate_new_record(tree: SceneTree, record_name: String, value: String) -> void:
	var toast = Label.new()
	toast.text = "🎉 NEW LEADERBOARD RECORD! %s: %s" % [record_name, value]
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.offset_left = -280.0
	toast.offset_right = 280.0
	toast.offset_top = 130.0
	toast.offset_bottom = 165.0
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1.0))
	tree.root.add_child(toast)

	var tw = tree.create_tween()
	tw.tween_interval(4.0)
	tw.tween_callback(toast.queue_free)
