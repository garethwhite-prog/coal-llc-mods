extends Object


func _ready(chain: ModLoaderHookChain) -> void:
	await chain.execute_next()

	var player := chain.reference_object as Player
	Game.player = player

