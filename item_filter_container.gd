extends ScrollContainer


func _ready() -> void :
    if Gvars.bonus_equipment_manager.item_filter:
        visible = true
    else:
        visible = false
