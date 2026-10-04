class_name CustomVacuumReward
extends QuestReward

var target_vacuum_level: int = 5
var next_quest_id: int = 101

func reward() -> void:
	if Gvars.bonus_equipment_manager:
		Gvars.bonus_equipment_manager.current_vacuum = target_vacuum_level
	if Gvars.equipment_manager:
		Gvars.equipment_manager.generate_vacuum_cleaner()
	if next_quest_id > 0 and Gvars.quest_manager:
		Gvars.quest_manager.change_quest_state(next_quest_id, QuestManager.States.AVAILABLE)