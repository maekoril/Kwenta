class_name StoreLayerRenderer
extends Control

const BASE := Vector2(1672.0, 941.0)
const CONFIG := preload("res://scripts/store_config.gd")

var slots := {}
var stock := []
var debug_slots := false
var current_day := 1
var current_cash := 0
var purchased_groups: Array = []
var store_config: Dictionary = {}
signal purchase_requested(group_id: String)
signal purchase_denied(group_id: String)

func _ready() -> void:
	name = "LayeredStore"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)
	_load_slots()
	_build_backgrounds()

func configure(day: int, cash: int, bought_groups: Array = []) -> void:
	current_day = day
	current_cash = cash
	purchased_groups = bought_groups
	store_config = CONFIG.load_config("res://data/store_config.json")
	_load_slots()
	stock = CONFIG.get_stocked_ids(store_config, day, bought_groups)
	var old_slots := get_node_or_null("Slots")
	if old_slots != null:
		remove_child(old_slots)
		old_slots.queue_free()
	var root := Control.new()
	root.name = "Slots"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	for entry in slots.values(): _make_slot(root, entry)

func get_slot_rect(id: String) -> Rect2:
	return slots.get(id, {}).get("rect", Rect2())

func get_product_display_rect(id: String) -> Rect2:
	var data: Dictionary = slots.get(id, {})
	if data.is_empty():
		return Rect2()
	var raw: Dictionary = data.get("raw", {})
	var scale: Vector2 = data.get("scale", Vector2.ONE)
	return Rect2(Vector2(raw.get("x", 0), raw.get("y", 0)) * scale, Vector2(raw.get("w", 0), raw.get("h", 0)) * scale)

func _load_slots() -> void:
	slots.clear()
	var f := FileAccess.open("res://assets/store/kwenta_layer_pack/slots.json", FileAccess.READ)
	if f == null: return
	var j := JSON.new(); if j.parse(f.get_as_text()) != OK: return
	var s := size / BASE
	for raw in j.data.get("layers", []):
		var r: Array = raw.slot_rect
		slots[raw.id] = {"id":raw.id, "rect":Rect2(Vector2(r[0],r[1])*s, Vector2(r[2],r[3])*s), "raw":raw, "scale":s}

func _on_resized() -> void:
	if store_config.is_empty():
		return
	configure(current_day, current_cash, purchased_groups)

func _build_backgrounds() -> void:
	for pair in [["EmptyBackground","res://assets/store/kwenta_layer_pack/bg_empty.png",0],["FrontBackground","res://assets/store/kwenta_layer_pack/bg_front.png",10]]:
		var rect := TextureRect.new(); rect.name=pair[0]; rect.texture=load(pair[1]); rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; rect.stretch_mode=TextureRect.STRETCH_SCALE; rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); rect.z_index=pair[2]; rect.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(rect)

func _make_slot(root: Control, data: Dictionary) -> void:
	var entry: Dictionary = store_config.get("products", {}).get(data.id, {})
	var area := Area2D.new()
	area.name = data.id
	area.position = data.rect.position
	area.input_pickable = true
	root.add_child(area)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = data.rect.size
	shape.shape = box
	shape.position = data.rect.size * 0.5
	area.add_child(shape)
	if stock.has(data.id):
		var raw: Dictionary = data.raw
		var sprite := Sprite2D.new()
		sprite.name = "%s_product" % data.id
		sprite.texture = load(str(entry.get("texture_path", "")))
		sprite.position = (Vector2(raw.x + raw.w * 0.5, raw.y + raw.h * 0.5)) * data.scale
		sprite.scale = Vector2(data.scale.x, data.scale.y)
		sprite.z_index = 20
		root.add_child(sprite)
	elif entry.get("unlock_type") == "buyable" and _is_lock_leader(data.id, entry):
		_add_lock(root, data.id, entry)
	area.input_event.connect(_slot_input.bind(data.id))

func _is_lock_leader(product_id: String, entry: Dictionary) -> bool:
	var group_id := str(entry.get("purchase_group", product_id))
	for candidate_id in store_config.get("products", {}):
		var candidate: Dictionary = store_config.products[candidate_id]
		if str(candidate.get("purchase_group", candidate_id)) == group_id:
			return candidate_id == product_id
	return false

func _add_lock(root: Control, product_id: String, entry: Dictionary) -> void:
	var group_id := str(entry.get("purchase_group", product_id))
	var lock_rect := _get_group_rect(group_id)
	var lock := Control.new()
	lock.name = "%s_lock" % group_id
	lock.position = lock_rect.get_center() - Vector2(48, 40)
	lock.size = Vector2(96, 80)
	lock.z_index = 25
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if current_day < int(entry.get("unlock_day", 1)):
		lock.modulate = Color(0.55, 0.55, 0.55, 1.0)
	root.add_child(lock)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/sprites/ui/icon_padlock_48x48.png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(24, 0)
	icon.size = Vector2(48, 48)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock.add_child(icon)
	var label := Label.new()
	label.name = "LockLabel"
	label.text = "DAY %d" % int(entry.get("unlock_day", 1)) if current_day < int(entry.get("unlock_day", 1)) else "₱%d" % int(entry.get("price", 0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0, 48)
	label.size = Vector2(96, 28)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock.add_child(label)

func _get_group_rect(group_id: String) -> Rect2:
	var has_rect := false
	var group_rect := Rect2()
	for product_id in store_config.get("products", {}):
		var entry: Dictionary = store_config.products[product_id]
		if str(entry.get("purchase_group", product_id)) != group_id:
			continue
		var slot: Dictionary = slots.get(str(entry.get("slot_id", product_id)), {})
		var rect: Rect2 = slot.get("rect", Rect2())
		group_rect = rect if not has_rect else group_rect.merge(rect)
		has_rect = true
	return group_rect

func _slot_input(_viewport: Node, event: InputEvent, _shape: int, id: String) -> void:
	if not (event is InputEventMouseButton and event.pressed) and not (event is InputEventScreenTouch and event.pressed): return
	if stock.has(id): return
	var entry: Dictionary = store_config.get("products", {}).get(id, {})
	if entry.get("unlock_type") == "buyable" and current_day >= int(entry.get("unlock_day", 1)):
		var group_id := str(entry.get("purchase_group", id))
		if current_cash < int(entry.get("price", 0)): purchase_denied.emit(group_id)
		else: purchase_requested.emit(group_id)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_F1:
		debug_slots=!debug_slots; queue_redraw()

func _draw() -> void:
	if debug_slots:
		for data in slots.values(): draw_rect(data.rect, Color(1,0,1,0.8), false, 2.0)
