extends Object

func load_equipment_shop(chain: ModLoaderHookChain) -> void:
	_sort_equipment_catalog()
	chain.execute_next([])

func _sort_equipment_catalog() -> void:
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if not item_unlocks or not ("all_equipment_items" in item_unlocks) or not (item_unlocks.all_equipment_items is Array):
		return

	var original_list: Array = item_unlocks.all_equipment_items
	if original_list.is_empty():
		return

	var indexed_items: Array = []
	for i in range(original_list.size()):
		var it = original_list[i]
		if is_instance_valid(it):
			var rank: int = _get_tier_rank(it)
			indexed_items.append({ "item": it, "rank": rank, "orig_idx": i })

	indexed_items.sort_custom(func(a, b):
		if a["rank"] != b["rank"]:
			return a["rank"] < b["rank"]
		return a["orig_idx"] < b["orig_idx"]
	)

	var sorted_list: Array[Item] = []
	for entry in indexed_items:
		sorted_list.append(entry["item"])

	item_unlocks.all_equipment_items = sorted_list

func _get_tier_rank(it: Item) -> int:
	var id: String = str(it.itemID).to_lower()
	var nm: String = str(it.itemName).to_lower()
	var s: String = id + " " + nm

	# Material tiers checked in specific priority
	if "shoddy" in s: return 1
	if "copper" in s: return 2
	if "iron" in s: return 3
	if "sapphire" in s: return 4
	if "emerald" in s: return 5
	if "silver" in s: return 6
	if "amethyst" in s: return 7
	if "gold" in s: return 8
	if "ruby" in s: return 9
	if "pinkdiamond" in s or "pink_diamond" in s or "pink diamond" in s: return 11
	if "diamond" in s: return 10
	if "spinel" in s: return 12
	if "moonstone" in s: return 14
	if "onyx" in s: return 15
	if "uranium" in s: return 13

	# Top utilities (Ladders, bombs, mortars, drills, whistles)
	if ("ladder" in s or "platform" in s or "bomb" in s or "dynamite" in s or 
		"mortar" in s or "drill" in s or "teleporter" in s or "whistle" in s or 
		"gravity" in s or "water_staff" in s or "water_gun" in s):
		return 0

	# Bottom uniques and upgrades
	return 16
