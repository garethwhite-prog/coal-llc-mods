extends AspectRatioContainer

signal update_inventory_from_ui()

@export var inventoryItem: InventoryItem:
    set(value):
        inventoryItem = value
        updateInventoryItem()

@export var equipped: bool:
    set(value):
        if equipped != value:
            equipped = value
            if equipped:

                inventoryItem.item.itemEquipEffect.equip_effect(self)
                Bus.itemEquipped.emit(inventoryItem.item)
            else:

                if inventoryItem.item.itemEquipEffect.has_method("stop_effect"):
                    inventoryItem.item.itemEquipEffect.stop_effect()


@onready var frame: TextureRect = $Frame
@onready var item_texture: TextureRect = $MarginContainer / ItemTexture
@onready var item_count: RichTextLabel = $MarginContainer / ItemTexture / ItemCount
@onready var margin_container: MarginContainer = %MarginContainer

var tooltip_instance: Control


const FRAME = preload("res://assets/32x32ItemFrame.png")
const FRAME_LOCKED = preload("res://assets/32x32ItemFrameLocked.png")
const FRAME_SELECTED = preload("res://assets/32x32ItemFrameSelected.png")


@export var unlocked: bool = false:
    set(value):
        unlocked = value
        update_selected()

@export var selected: bool = false:
    set(value):
        selected = value
        update_selected()

var draggable: bool = true

func _ready() -> void :
    updateInventoryItem()


func _physics_process(_delta: float) -> void :
    if equipped == true:
        inventoryItem.item.itemEquipEffect.equip_effect(self)

func update_selected():
    if not is_node_ready():
        await ready
    equipped = selected
    if selected == true:
        frame.texture = FRAME_SELECTED
    elif unlocked == true:
        frame.texture = FRAME
    elif unlocked == false:
        frame.texture = FRAME_LOCKED

func _get_drag_data(_at_position: Vector2) -> Dictionary:
    if (unlocked == true) and (draggable == true):
        set_drag_preview(get_preview())

    return {"item": inventoryItem, "slot": self}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    return data.has("item") and data["item"] is InventoryItem

func _drop_data(_at_position: Vector2, data: Variant) -> void :
    if unlocked == true and data.has("slot") and (draggable == true):
        var source_slot = data["slot"]
        var temp = inventoryItem


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
        margin_container.tooltip_text = inventoryItem.item.itemName


func _on_gui_input(event: InputEvent) -> void :
    pass


func _on_frame_gui_input(event: InputEvent) -> void :

    if event.is_action_pressed("dropItem"):


        var temp = InventoryItem.new()
        temp.item = load("res://resources/Items/Empty.tres")
        temp.count = 0


        var old_inventoryItem: InventoryItem = inventoryItem
        inventoryItem = temp

        Bus.drop_item_from_player.emit(old_inventoryItem)


        update_inventory_from_ui.emit()
