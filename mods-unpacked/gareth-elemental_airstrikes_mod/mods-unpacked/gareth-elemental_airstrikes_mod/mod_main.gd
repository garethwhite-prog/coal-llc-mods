extends Node

const MOD_DIR := "gareth-elemental_airstrikes_mod"

func _ready() -> void:
	var mgr_script = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/elemental_airstrike_manager.gd")
	var mgr = Node.new()
	mgr.name = "ElementalAirstrikeManager"
	mgr.set_script(mgr_script)
	get_tree().root.call_deferred("add_child", mgr)

	_register_elemental_items()
	ModLoaderLog.info("Elemental Airstrikes Triad + B-52 Bomber active!", MOD_DIR)

func _register_elemental_items() -> void:
	var factory = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/texture_factory.gd")
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks or not ("all_equipment_items" in item_unlocks) or not factory:
		return

	var buy_fx = load("res://resources/BuyEffects/Scripts/AddToInventory.gd").new()
	var equip_effect_script = load("res://mods-unpacked/gareth-elemental_airstrikes_mod/scripts/airstrike_equip_effect.gd")

	var items_data = [
		{
			"id": "dragon_strike_whistle",
			"name": "Dragon Strike Whistle",
			"desc": "Single-use tactical flare. Calls an ancient dragon to carpet the mine in incendiary fire.",
			"price": 250.0,
			"type": "dragon",
			"tex": factory.create_dragon_texture()
		},
		{
			"id": "water_bomber_radio",
			"name": "Water Bomber Radio",
			"desc": "Single-use emergency radio. Calls a water-bomber plane to deluge cavern fires and soften clay.",
			"price": 150.0,
			"type": "water",
			"tex": factory.create_water_bomber_texture()
		},
		{
			"id": "agent_orange_transceiver",
			"name": "Agent Orange Transceiver",
			"desc": "Single-use chemical beacon. Disperses concentrated defoliant across the active strata.",
			"price": 350.0,
			"type": "poison",
			"tex": factory.create_agent_orange_texture()
		},
		{
			"id": "b52_carpet_bomber",
			"name": "B-52 Carpet Bomber",
			"desc": "Single-use heavy airstrike. Drops 10 high-explosive ordnance bombs, devastating stone strata.",
			"price": 850.0,
			"type": "b52",
			"tex": factory.create_b52_texture()
		}
	]

	for data in items_data:
		var it = Item.new()
		it.itemID = data["id"]
		it.itemName = data["name"]
		it.itemDescription = data["desc"]
		it.itemBuyPrice = data["price"]
		it.itemSellPrice = data["price"] * 0.5
		it.itemType = "equipment"
		it.itemTexture = data["tex"]
		it.itemUnlocked = true
		it.itemBuyEffect = buy_fx

		var eq = equip_effect_script.new()
		eq.strike_type = data["type"]
		it.itemEquipEffect = eq

		var exists := false
		for existing in item_unlocks.all_equipment_items:
			if existing and existing.itemID == it.itemID:
				exists = true
				break
		if not exists:
			item_unlocks.all_equipment_items.append(it)
			if "all_items" in item_unlocks:
				item_unlocks.all_items.append(it)
