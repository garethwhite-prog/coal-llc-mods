extends Node

var canvas: CanvasLayer
var hud_btn: Button
var store_window: PanelContainer
var toast_label: Label
var queue_label: Label

var search_box: LineEdit
var item_grid: GridContainer
var cash_label: Label

var pending_orders: Array = []
var all_shop_items: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_catalog()
	_build_ui()

func _load_catalog() -> void:
	all_shop_items = []
	var item_unlocks = load("res://resources/unlockable_items/scripts/item_unlocks.tres")
	if item_unlocks and ("all_equipment_items" in item_unlocks):
		for it in item_unlocks.all_equipment_items:
			if is_instance_valid(it):
				all_shop_items.append(it)

func _build_ui() -> void:
	canvas = CanvasLayer.new()
	canvas.name = "AmazonDeliveryCanvas"
	canvas.layer = 96
	add_child(canvas)

	# 1. Top-Right HUD Button
	hud_btn = Button.new()
	hud_btn.name = "AmazonHUDButton"
	hud_btn.text = "📦 Amazon"
	hud_btn.anchor_left = 1.0
	hud_btn.anchor_right = 1.0
	hud_btn.offset_left = -110.0
	hud_btn.offset_right = -16.0
	hud_btn.anchor_top = 1.0; hud_btn.anchor_bottom = 1.0; hud_btn.offset_top = -94.0
	hud_btn.offset_bottom = -58.0
	hud_btn.modulate = Color(1.0, 0.85, 0.3, 1.0)
	hud_btn.tooltip_text = "Open Amazon Same-Day Emergency Delivery (Hotkey B)"
	hud_btn.pressed.connect(toggle_store)
	canvas.add_child(hud_btn)

	# 2. Toast & Delivery Queue Notification Banner
	queue_label = Label.new()
	queue_label.anchor_left = 0.5
	queue_label.anchor_right = 0.5
	queue_label.offset_left = -250.0
	queue_label.offset_right = 250.0
	queue_label.offset_top = 60.0
	queue_label.offset_bottom = 90.0
	queue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	queue_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	queue_label.visible = false
	canvas.add_child(queue_label)

	toast_label = Label.new()
	toast_label.anchor_left = 0.5
	toast_label.anchor_right = 0.5
	toast_label.offset_left = -250.0
	toast_label.offset_right = 250.0
	toast_label.offset_top = 92.0
	toast_label.offset_bottom = 122.0
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5, 1.0))
	toast_label.visible = false
	canvas.add_child(toast_label)

	# 3. Amazon Store Window
	store_window = PanelContainer.new()
	store_window.name = "AmazonStoreWindow"
	store_window.anchor_left = 0.5
	store_window.anchor_right = 0.5
	store_window.anchor_top = 0.5
	store_window.anchor_bottom = 0.5
	store_window.offset_left = -320.0
	store_window.offset_right = 320.0
	store_window.offset_top = -240.0
	store_window.offset_bottom = 240.0
	store_window.visible = false

	var v_box = VBoxContainer.new()
	v_box.add_theme_constant_override("separation", 8)

	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "📦 AMAZON SAME-DAY EMERGENCY DELIVERY"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	header.add_child(title)

	var btn_close = Button.new()
	btn_close.text = "✖"
	btn_close.pressed.connect(func(): store_window.visible = false)
	header.add_child(btn_close)
	v_box.add_child(header)

	var sub_bar = HBoxContainer.new()
	cash_label = Label.new()
	cash_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_bar.add_child(cash_label)

	var btn_scrap_in_shop = Button.new()
	btn_scrap_in_shop.text = "♻️ Quick-Scrap All Ores (50%)"
	btn_scrap_in_shop.modulate = Color(0.4, 1.0, 0.6, 1.0)
	btn_scrap_in_shop.pressed.connect(_quick_scrap_from_shop)
	sub_bar.add_child(btn_scrap_in_shop)
	v_box.add_child(sub_bar)

	search_box = LineEdit.new()
	search_box.placeholder_text = "Search platforms, ladders, tools, weapons..."
	search_box.clear_button_enabled = true
	search_box.text_changed.connect(func(_new_text): _render_catalog())
	v_box.add_child(search_box)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	item_grid = GridContainer.new()
	item_grid.columns = 2
	item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_grid.add_theme_constant_override("h_separation", 10)
	item_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(item_grid)
	v_box.add_child(scroll)

	store_window.add_child(v_box)
	canvas.add_child(store_window)

func _process(delta: float) -> void:
	var tree = get_tree()
	var in_game := false
	var player_node: Node2D = null
	if tree and tree.root:
		player_node = tree.root.find_child("Player", true, false)
		in_game = is_instance_valid(player_node) and (Game and Gconsts and ("Stages" in Gconsts) and Game.stage == Gconsts.Stages._IN_GAME)

	if hud_btn:
		hud_btn.visible = in_game

	if not in_game and store_window and store_window.visible:
		store_window.visible = false

	if is_instance_valid(cash_label) and Gvars:
		cash_label.text = "Wallet: $%.2f" % (Gvars.CashCount / 100.0)

	_update_orders(delta, player_node)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			var tree = get_tree()
			if tree and tree.root and tree.root.find_child("Player", true, false):
				toggle_store()

func toggle_store() -> void:
	if not store_window:
		return
	store_window.visible = not store_window.visible
	if store_window.visible:
		if all_shop_items.is_empty():
			_load_catalog()
		_render_catalog()

func open_store() -> void:
	if store_window:
		store_window.visible = true
		if all_shop_items.is_empty():
			_load_catalog()
		_render_catalog()

func _render_catalog() -> void:
	if not item_grid:
		return
	for c in item_grid.get_children():
		c.queue_free()

	var q: String = search_box.text.strip_edges().to_lower()

	for it in all_shop_items:
		if not is_instance_valid(it):
			continue
		var nm: String = str(it.itemName)
		var id_str: String = str(it.itemID).to_lower()
		var desc: String = str(it.itemDescription).to_lower()
		if not q.is_empty() and (not q in nm.to_lower() and not q in id_str and not q in desc):
			continue

		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(290, 68)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var tex = TextureRect.new()
		tex.texture = it.itemTexture
		tex.custom_minimum_size = Vector2(40, 40)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(tex)

		var info_box = VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl = Label.new()
		name_lbl.text = nm
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_box.add_child(name_lbl)

		var price_val: float = it.itemBuyPrice
		var price_lbl = Label.new()
		price_lbl.text = "$%.2f" % (price_val / 100.0)
		price_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
		info_box.add_child(price_lbl)

		hbox.add_child(info_box)

		var btn_order = Button.new()
		btn_order.text = "Order\n(10s)"
		btn_order.custom_minimum_size = Vector2(64, 44)
		var can_afford = (Gvars and Gvars.CashCount >= price_val)
		btn_order.disabled = not can_afford
		btn_order.pressed.connect(func(): _place_order(it))
		hbox.add_child(btn_order)

		card.add_child(hbox)
		item_grid.add_child(card)

func _place_order(it: Item) -> void:
	if not Gvars or Gvars.CashCount < it.itemBuyPrice:
		show_toast("❌ Insufficient funds in wallet!")
		return

	Gvars.CashCount -= it.itemBuyPrice
	pending_orders.append({
		"item": it,
		"time_left": 10.0
	})
	show_toast("📦 Order placed for %s! Parachute delivery in 10s." % it.itemName)
	_render_catalog()

func _update_orders(delta: float, player_node: Node2D) -> void:
	if pending_orders.is_empty():
		if queue_label and queue_label.visible:
			queue_label.visible = false
		return

	queue_label.visible = true
	var min_time: float = 999.0
	var current_item_name: String = ""

	var i = pending_orders.size() - 1
	while i >= 0:
		var order = pending_orders[i]
		order["time_left"] -= delta
		if order["time_left"] < min_time:
			min_time = order["time_left"]
			current_item_name = order["item"].itemName

		if order["time_left"] <= 0.0:
			_spawn_parachute_crate(order["item"], player_node)
			pending_orders.remove_at(i)
		i -= 1

	if is_instance_valid(queue_label):
		queue_label.text = "📦 Amazon Drone en route: [%s] arriving in %.1fs" % [current_item_name, max(0.0, min_time)]

func _spawn_parachute_crate(item: Item, player_node: Node2D) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	var crate = Node2D.new()
	crate.name = "AmazonDeliveryCrate"

	var spawn_x: float = player_node.global_position.x if is_instance_valid(player_node) else 0.0
	var spawn_y: float = -60.0
	crate.global_position = Vector2(spawn_x, spawn_y)

	var spr = Sprite2D.new()
	spr.texture = item.itemTexture if is_instance_valid(item.itemTexture) else load("res://assets/Equipment/kicks/kick_04_sapphire.png")
	spr.scale = Vector2(1.6, 1.6)
	crate.add_child(spr)

	tree.current_scene.add_child(crate)

	var target_y = player_node.global_position.y if is_instance_valid(player_node) else 0.0
	var tween = tree.create_tween()
	var fall_time = 1.2
	tween.tween_property(crate, "global_position:y", target_y, fall_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		var inv: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
		if inv:
			inv.addToInventory(item, 1)
			Bus.inventory_changed.emit()
		show_toast("📦 DELIVERED! [%s] placed in inventory." % item.itemName)

		var boom_audio = AudioStreamPlayer2D.new()
		boom_audio.stream = load("res://assets/sound/sound effects/pickup.wav")
		boom_audio.global_position = crate.global_position
		tree.current_scene.add_child(boom_audio)
		boom_audio.play()
		boom_audio.finished.connect(boom_audio.queue_free)

		crate.queue_free()
	)

func _quick_scrap_from_shop() -> void:
	var inv: Inventory = load("res://resources/Inventories/PlayerInventory.tres")
	if not inv or not Gvars:
		return

	var total_cash: float = 0.0
	var count_cleared: int = 0
	var empty_res = load("res://resources/Items/Empty.tres")

	for slot_item in inv.items:
		if not is_instance_valid(slot_item) or not is_instance_valid(slot_item.item) or slot_item.count <= 0:
			continue
		var it = slot_item.item
		var id_str = str(it.itemID).to_lower()
		var type_str = str(it.itemType).to_lower()

		var is_ore = (type_str in ["ore", "resource", "mineral", "material"] or 
			"coal" in id_str or "copper" in id_str or "iron" in id_str or "sapphire" in id_str or 
			"emerald" in id_str or "silver" in id_str or "amethyst" in id_str or "gold" in id_str or 
			"ruby" in id_str or "diamond" in id_str or "spinel" in id_str or "uranium" in id_str)

		if is_ore and type_str != "equipment" and type_str != "weapon":
			var val = it.itemSellPrice * 0.5 if it.itemSellPrice > 0.0 else 5.0
			total_cash += val * slot_item.count
			count_cleared += int(slot_item.count)
			slot_item.count = 0
			if empty_res:
				slot_item.item = empty_res

	if total_cash > 0.0:
		Gvars.CashCount += total_cash
		Bus.inventory_changed.emit()
		show_toast("♻️ Scrapped %d ores for +$%.2f cash!" % [count_cleared, total_cash / 100.0])
		_render_catalog()

func show_toast(msg: String) -> void:
	if is_instance_valid(toast_label):
		toast_label.text = msg
		toast_label.visible = true
		var tree = get_tree()
		if tree:
			var tw = tree.create_tween()
			tw.tween_interval(3.0)
			tw.tween_callback(func():
				if is_instance_valid(toast_label):
					toast_label.visible = false
			)

