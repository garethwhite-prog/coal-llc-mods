extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	# Bypassed direct constant mutation to prevent Godot 4 read-only crash
	chain.execute_next([])