class_name InventorySlot
extends PanelContainer


signal update_inventory_from_ui()

enum Location{
    TOOLBAR, 
    WINDOW, 
}

const DISABLED_STRETCHED = preload("res://resources_UI/disabled_stretched.tres")
const NORMAL_STRETCHED = preload("res://resources_UI/normal_stretched.tres")
const SELECTED_STRETCHED = preload("res://resources_UI/selected_stretched.tres")


@export var inventoryItem: InventoryItem:
    set(value):
        var old = inventoryItem
        inventoryItem = value
        if equipped:
            if old.item.itemEquipEffect.has_method("stop_effect"):

                    old.item.itemEquipEffect.stop_effect()
            Bus.itemEquipped.emit(old.item)
        updateInventoryItem()

@export var equipped: bool:
    set(value):
        if equipped != value:
            equipped = value
            if equipped:
                Bus.itemEquipped.emit(inventoryItem.item)

@export var in_game: bool = true
@export var location: Location

@onready var item_texture: TextureRect = %ItemTexture
@onready var effect_texture: TextureRect = %EffectTexture
@onready var item_count: RichTextLabel = %ItemCount


@export var selected: bool = false:
    set(value):
        selected = value
        update_selected()

var draggable: bool = true
var is_power_up_on: bool = false:
    set(value):
        is_power_up_on = value
        if is_power_up_on == false:
            if equipped:
                Bus.itemEquipped.emit(inventoryItem.item)

func _ready() -> void :
    updateInventoryItem()
    update_selected()


func update_selected():
    if not is_node_ready():
        await ready
    equipped = selected
    if selected == true:

        add_theme_stylebox_override("panel", SELECTED_STRETCHED)
    else:
        add_theme_stylebox_override("panel", NORMAL_STRETCHED)


func _get_drag_data(_at_position: Vector2) -> Dictionary:
    if (draggable == true):
        set_drag_preview(get_preview())

    return {"item": inventoryItem, "slot": self, "location": location}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    return data.has("item") and (data["item"] is InventoryItem) and data.has("location") and (data["location"] == location)


func _drop_data(_at_position: Vector2, data: Variant) -> void :
    if data.has("slot") and (draggable == true):
        var source_slot = data["slot"]
        var temp = inventoryItem


        if inventoryItem.item.itemID == data["item"].item.itemID:
            var inventory: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
            var added = max(min(inventory.maxStack, inventoryItem.count + data["item"].count) - inventoryItem.count, 0)
            inventoryItem.count += added
            source_slot.inventoryItem.count -= added
            if source_slot.inventoryItem.count <= 0:
                source_slot.inventoryItem.item = load("res://resources/Items/Empty.tres")
        else:
            inventoryItem = data["item"]
            source_slot.inventoryItem = temp


        update_inventory_from_ui.emit()


func get_preview():
    var preview_texture = TextureRect.new()

    preview_texture.texture = inventoryItem.item.itemTexture
    preview_texture.expand_mode = 1
    preview_texture.size = Vector2(100, 100)

    var preview = Control.new()
    preview.add_child(preview_texture)

    return preview


func updateInventoryItem():
    if not is_node_ready():
        await ready

    if inventoryItem != null:
        if not inventoryItem.is_connected("count_changed", updateInventoryItem):
            inventoryItem.connect("count_changed", updateInventoryItem)
        item_texture.texture = inventoryItem.item.itemTexture
        if inventoryItem.item.itemID == "Empty":
            item_count.text = ""
            item_count.visible = false
        else:
            item_count.text = Gconsts.add_comma_to_float_no_dp(inventoryItem.count)
            item_count.visible = true
        self.tooltip_text = inventoryItem.item.itemName
        if inventoryItem.item.effectTexture != null:
            effect_texture.texture = inventoryItem.item.effectTexture
            effect_texture.visible = true
        else:
            effect_texture.visible = false




func _on_gui_input(event: InputEvent) -> void :
    if event.is_action_pressed("dropItem") and in_game:
        var temp = InventoryItem.new()
        temp.item = load("res://resources/Items/Empty.tres")
        temp.count = 0


        var old_inventoryItem: InventoryItem = inventoryItem
        inventoryItem = temp

        Bus.drop_item_from_player.emit(old_inventoryItem)


        update_inventory_from_ui.emit()
