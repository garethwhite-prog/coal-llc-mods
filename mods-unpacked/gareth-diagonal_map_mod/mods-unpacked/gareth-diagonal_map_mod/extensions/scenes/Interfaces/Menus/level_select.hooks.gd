extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	var ls = chain.reference_object
	if ls and ("LEVEL_ORDER" in ls):
		if not ls.LEVEL_ORDER.has(105):
			ls.LEVEL_ORDER.append(105)
	chain.execute_next([])
