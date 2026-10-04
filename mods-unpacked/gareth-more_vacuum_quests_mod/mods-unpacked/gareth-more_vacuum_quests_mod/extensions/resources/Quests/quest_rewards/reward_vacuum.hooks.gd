extends Object

func reward(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var rw = chain.reference_object
	if not rw or not Gvars.quest_manager:
		return
	if rw.vacuum == BonusEquipmentManager.Vacuums.LEVEL_4:
		if Gvars.quest_manager.quests.has(100):
			if Gvars.quest_manager.quests[100]["state"] == QuestManager.States.UNAVAILABLE_CHAIN:
				Gvars.quest_manager.change_quest_state(100, QuestManager.States.AVAILABLE)