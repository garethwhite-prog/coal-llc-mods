extends Object


func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next()

	var player := chain.reference_object as Player
	Game.player = player
