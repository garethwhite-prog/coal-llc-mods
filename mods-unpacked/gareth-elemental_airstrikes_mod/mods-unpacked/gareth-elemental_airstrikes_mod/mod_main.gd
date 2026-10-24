extends Node

const MOD_DIR := "gareth-elemental_airstrikes_mod"

func _ready() -> void:
	var mgr_script = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/elemental_airstrike_manager.gd")
	var mgr = Node.new()
	mgr.name = "ElementalAirstrikeManager"
	mgr.set_script(mgr_script)
	get_tree().root.call_deferred("add_child", mgr)

	_register_elemental_items()
	ModLoaderLog.info("Elemental Airstrikes Triad active! (Dragon [7], Water Bomber [8], Agent Orange [9])", MOD_DIR)

func _register_elemental_items() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks or not ("all_equipment_items" in item_unlocks):
		return

	var d_item = Item.new()
	d_item.itemID = "dragon_strike_whistle"
	d_item.itemName = "Dragon Strike Whistle"
	d_item.itemDescription = "Summon an ancient fiery dragon to carpet the mine in incendiary flame bursts."
	d_item.itemType = "equipment"
	d_item.itemBuyPrice = 45000.0
	d_item.itemSellPrice = 22500.0
	d_item.itemTexture = ElementalAirstrikeTextures.create_dragon_texture()
	item_unlocks.all_equipment_items.append(d_item)

	var w_item = Item.new()
	w_item.itemID = "water_bomber_radio"
	w_item.itemName = "Water Bomber Radio"
	w_item.itemDescription = "Call in an amphibious water plane to drench strata with elemental wet cascades."
	w_item.itemType = "equipment"
	w_item.itemBuyPrice = 35000.0
	w_item.itemSellPrice = 17500.0
	w_item.itemTexture = ElementalAirstrikeTextures.create_water_bomber_texture()
	item_unlocks.all_equipment_items.append(w_item)

	var p_item = Item.new()
	p_item.itemID = "agent_orange_transceiver"
	p_item.itemName = "Agent Orange Transceiver"
	p_item.itemDescription = "Order a heavy strategic bomber to deploy toxic chemical canisters across the dig site."
	p_item.itemType = "equipment"
	p_item.itemBuyPrice = 55000.0
	p_item.itemSellPrice = 27500.0
	p_item.itemTexture = ElementalAirstrikeTextures.create_agent_orange_texture()
	item_unlocks.all_equipment_items.append(p_item)
