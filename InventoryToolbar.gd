extends GridContainer

const TOOLBAR_SLOTS: int = 10
const INVENTORY_SLOT = preload("res://scenes/Interfaces/Inventory/inventory_slot_b.tscn")

const KEYBINDS: Dictionary = {
    "1": 0, 
    "2": 1, 
    "3": 2, 
    "4": 3, 
    "5": 4, 
    "6": 5, 
    "7": 6, 
    "8": 7, 
    "9": 8, 
    "0": 9
}


var inventory: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
var current_equipped_key: String = ""


func _ready() -> void :
    for child in get_children():
        child.queue_free()

    for n in range(TOOLBAR_SLOTS):
        var instance: InventorySlot = INVENTORY_SLOT.instantiate()
        instance.inventoryItem = inventory.items[n]
        if n == 0:
            instance.equipped = true
            instance.selected = true
        instance.location = instance.Location.TOOLBAR
        instance.connect("update_inventory_from_ui", save_inventory)
        add_child(instance)

    inventory.connect("inventory_changed", on_inventory_changed)
    load_inventory()



func _process(_delta: float) -> void :
    for key in KEYBINDS.keys():
        if Input.is_action_just_pressed(key):
            select_slot(key)
            current_equipped_key = key
    if Input.is_action_just_pressed("next_item"):
        current_equipped_key = str(posmod((int(current_equipped_key) + 1), 10))
        select_slot(current_equipped_key)
    elif Input.is_action_just_pressed("previous_item"):
        current_equipped_key = str(posmod((int(current_equipped_key) - 1), 10))
        select_slot(current_equipped_key)


func on_inventory_changed():
    load_inventory()


func select_slot(key: String):
    var slots = get_children()
    for slot in slots:
        slot.selected = false
    slots[KEYBINDS[key]].selected = true




func load_inventory():
    var slots = get_children()
    var n = 0
    for item in inventory.items.slice(0, TOOLBAR_SLOTS, 1):
        slots[n].inventoryItem = item
        n += 1

    if current_equipped_key != "":
        select_slot(current_equipped_key)

func save_inventory():
    var n = 0
    for slot in get_children():
        inventory.items[n] = slot.inventoryItem
        n += 1
    inventory.addToInventory(load("res://resources/Items/Coal.tres"), 0)
    if current_equipped_key != "":
        select_slot(current_equipped_key)
    Bus.inventory_changed.emit()
