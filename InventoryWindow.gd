extends GridContainer

@export var in_game: bool = true
@export var totalSlots: int = 40

const INVENTORY_SLOT = preload("res://scenes/Interfaces/Inventory/inventory_slot_b.tscn")
var inventory: Inventory = load("res://resources/Inventories/PlayerInventory.tres")


func _ready() -> void :
    inventory.connect("inventory_changed", on_inventory_changed)
    load_inventory()

func on_inventory_changed():
    load_inventory()

func load_inventory():
    var n = 0
    var slots = get_children()
    for item in inventory.items:
        if n < slots.size():
            slots[n].inventoryItem = item
            slots[n].in_game = in_game
        else:
            var instance = INVENTORY_SLOT.instantiate()
            instance.location = instance.Location.WINDOW
            instance.connect("update_inventory_from_ui", save_inventory)
            add_child(instance)
            instance.inventoryItem = item
            instance.in_game = in_game
        n += 1

func save_inventory():
    var n = 0
    for slot in get_children():
        inventory.items[n] = slot.inventoryItem
        n += 1
    inventory.addToInventory(load("res://resources/Items/Coal.tres"), 0)
    Bus.inventory_changed.emit()
