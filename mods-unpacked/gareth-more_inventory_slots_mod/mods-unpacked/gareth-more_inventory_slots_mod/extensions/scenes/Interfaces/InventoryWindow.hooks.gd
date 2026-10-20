extends Object

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next()
	var window = chain.reference_object
	var helper = load("res://mods-unpacked/gareth-more_inventory_slots_mod/helpers/InventoryScrollHelper.gd")
	if helper:
		helper.setup_scroll(window)

func load_inventory(chain: ModLoaderHookChain) -> void:
	chain.execute_next()
	var window = chain.reference_object
	var helper = load("res://mods-unpacked/gareth-more_inventory_slots_mod/helpers/InventoryScrollHelper.gd")
	if helper:
		helper.update_scroll(window)
