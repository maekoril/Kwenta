extends Control

signal product_dropped(customer_id: String, product_id: String)

const PORTRAIT_ATLAS: Texture2D = preload("res://assets/sprites/customer_portraits_v2.png")
const PRODUCT_ATLAS: Texture2D = preload("res://assets/sprites/kwenta_generic_products.png")
const COUNTER_ART = preload("res://scripts/counter_art.gd")
const ORDER_BUBBLE_ICON = preload("res://scripts/order_bubble_icon.gd")
const STOREFRONT_LAYOUT = preload("res://scripts/storefront_layout.gd")
# All pixel values below are the old 640x360 values x3 (1920x1080 viewport).
const ORDER_ICON_CELL_SIZE := 84.0
const ORDER_BUBBLE_PADDING := 8.0
const ORDER_BUBBLE_COLUMNS := 3
const PORTRAIT_POSITION := Vector2(18.0, 160.0)
const PORTRAIT_SIZE := Vector2(144.0, 288.0)
const BUBBLE_RIGHT_OFFSET := 10.0
const BUBBLE_TOP_OFFSET := 105.0
const BUBBLE_FOOTER_HEIGHT := 30.0
const PATIENCE_GREEN := Color("4caa56")
const PATIENCE_YELLOW := Color("e3bd39")
const PATIENCE_RED := Color("d94536")

var customer: CustomerState
var order_bubble: PanelContainer
var order_grid: GridContainer
var bubble_tail: Polygon2D
var patience_bar: ProgressBar
var patience_fill: StyleBoxFlat
var portrait: TextureRect
var portrait_shadow: TextureRect
var name_tag: PanelContainer
var name_label: Label
var _drop_hovered: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(STOREFRONT_LAYOUT.CUSTOMER_WIDTH, STOREFRONT_LAYOUT.CUSTOMER_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	order_bubble = PanelContainer.new()
	order_bubble.name = "OrderBubble"
	order_bubble.add_theme_stylebox_override("panel", _make_box(Color("f2dfb9"), Color("593d2d"), 3, ORDER_BUBBLE_PADDING, 9))
	order_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(order_bubble)
	bubble_tail = Polygon2D.new()
	bubble_tail.name = "OrderBubbleTail"
	bubble_tail.color = Color("f2dfb9")
	add_child(bubble_tail)
	order_grid = GridContainer.new()
	order_grid.columns = ORDER_BUBBLE_COLUMNS
	order_grid.add_theme_constant_override("h_separation", 0)
	order_grid.add_theme_constant_override("v_separation", 0)
	order_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	order_bubble.add_child(order_grid)
	patience_bar = ProgressBar.new()
	patience_bar.name = "PatienceBar"
	patience_bar.custom_minimum_size = Vector2(60, 12)
	patience_bar.show_percentage = false
	patience_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patience_bar.add_theme_stylebox_override("background", _make_box(Color("30261f"), Color("30261f"), 0, 0.0, 3))
	patience_fill = StyleBoxFlat.new()
	patience_fill.set_corner_radius_all(3)
	patience_bar.add_theme_stylebox_override("fill", patience_fill)
	add_child(patience_bar)
	portrait_shadow = TextureRect.new()
	portrait_shadow.name = "PortraitShadow"
	portrait_shadow.position = PORTRAIT_POSITION + Vector2(5.0, 7.0)
	portrait_shadow.size = PORTRAIT_SIZE
	portrait_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait_shadow.modulate = Color(0.02, 0.02, 0.02, 0.52)
	portrait_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_shadow.z_index = -1
	add_child(portrait_shadow)
	portrait = TextureRect.new()
	portrait.name = "Portrait"
	portrait.position = PORTRAIT_POSITION
	portrait.size = PORTRAIT_SIZE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	name_tag = PanelContainer.new()
	name_tag.name = "NameTrustTag"
	# Keep identity information on the visible upper body; the concrete sill
	# occludes everything from viewport y=528 downward.
	name_tag.size = Vector2(100, 22)
	name_tag.add_theme_stylebox_override("panel", _make_box(Color(0.06, 0.07, 0.08, 0.86), Color(0.06, 0.07, 0.08, 0.86), 0, 1.5, 12))
	name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_tag)
	name_label = Label.new()
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	name_label.add_theme_constant_override("shadow_offset_x", 3)
	name_label.add_theme_constant_override("shadow_offset_y", 3)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_tag.add_child(name_label)
	refresh_display()

func set_customer(value: CustomerState, _products: Dictionary) -> void:
	customer = value
	refresh_display()

func set_facing_right(from_right: bool) -> void:
	if is_instance_valid(portrait):
		portrait.flip_h = from_right
		portrait_shadow.flip_h = from_right

func refresh_display() -> void:
	if customer == null or not is_instance_valid(name_label):
		return
	name_label.text = "%s · %d%%" % [_display_name(customer.customer_id), int(customer.trust)]
	portrait.texture = COUNTER_ART.customer_portrait(customer.customer_id, PORTRAIT_ATLAS)
	portrait_shadow.texture = portrait.texture
	for child in order_grid.get_children():
		order_grid.remove_child(child)
		child.queue_free()
	var entries: Array[Dictionary] = STOREFRONT_LAYOUT.get_order_icon_entries(customer.order.requested, customer.order.delivered)
	for entry in entries:
		order_grid.add_child(_make_order_item(entry))
	_layout_order_bubble(entries.size())
	refresh_patience()
	queue_redraw()

func _layout_order_bubble(entry_count: int) -> void:
	var columns: int = 2 if entry_count > 3 else ORDER_BUBBLE_COLUMNS
	var visible_columns: int = mini(columns, maxi(1, entry_count))
	var rows: int = maxi(1, int(ceil(float(entry_count) / float(columns))))
	var bubble_size := Vector2(
		float(visible_columns) * ORDER_ICON_CELL_SIZE + ORDER_BUBBLE_PADDING * 2.0,
		float(rows) * ORDER_ICON_CELL_SIZE + ORDER_BUBBLE_PADDING * 2.0 + BUBBLE_FOOTER_HEIGHT
	)
	order_bubble.size = bubble_size
	order_grid.columns = columns
	var bubble_x := portrait.position.x + portrait.size.x + BUBBLE_RIGHT_OFFSET
	var bubble_y := BUBBLE_TOP_OFFSET
	order_bubble.position = Vector2(bubble_x, bubble_y)
	order_bubble.pivot_offset = bubble_size * 0.5
	bubble_tail.polygon = PackedVector2Array([Vector2(bubble_x, bubble_y + 30), Vector2(bubble_x - 16, bubble_y + 40), Vector2(bubble_x, bubble_y + 50)])
	patience_bar.position = Vector2(bubble_x + bubble_size.x - 10.0, bubble_y + 7.0)
	patience_bar.size = Vector2(6.0, bubble_size.y - 14.0)
	name_tag.position = Vector2(bubble_x + ORDER_BUBBLE_PADDING, bubble_y + bubble_size.y - BUBBLE_FOOTER_HEIGHT + 3.0)
	name_tag.size = Vector2(bubble_size.x - 24.0, 22.0)

func refresh_patience() -> void:
	if customer == null or not is_instance_valid(patience_bar):
		return
	var patience_ratio: float = clampf(customer.patience_remaining / maxf(customer.patience_seconds, 0.001), 0.0, 1.0)
	patience_bar.value = patience_ratio * 100.0
	if patience_ratio >= 0.5:
		patience_fill.bg_color = PATIENCE_GREEN
	elif patience_ratio >= 0.25:
		patience_fill.bg_color = PATIENCE_YELLOW
	else:
		patience_fill.bg_color = PATIENCE_RED

func contains_drop_point(viewport_position: Vector2) -> bool:
	return Rect2(global_position + portrait.position, portrait.size).has_point(viewport_position)

func _make_order_item(entry: Dictionary) -> Control:
	var item := Control.new()
	item.custom_minimum_size = Vector2(ORDER_ICON_CELL_SIZE, ORDER_ICON_CELL_SIZE)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var product_id: String = str(entry.product_id)
	var icon: Control = ORDER_BUBBLE_ICON.new()
	icon.set("icon_texture", COUNTER_ART.product_icon(product_id, PRODUCT_ATLAS))
	icon.size = Vector2(ORDER_ICON_CELL_SIZE, ORDER_ICON_CELL_SIZE)
	icon.modulate = Color("a4a4a4") if entry.completed else Color.WHITE
	item.add_child(icon)
	var quantity := Label.new()
	quantity.text = "✓" if entry.completed else ("×%d" % int(entry.remaining) if int(entry.requested) > 1 else "")
	quantity.add_theme_font_size_override("font_size", 18)
	quantity.add_theme_color_override("font_color", Color("478c45") if entry.completed else Color("493326"))
	quantity.position = Vector2(27, 27)
	quantity.size = Vector2(30, 30)
	quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	quantity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(quantity)
	return item

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var can_accept: bool = customer != null and customer.active and data is Dictionary and data.has("product_id")
	if _drop_hovered != can_accept:
		_drop_hovered = can_accept
		queue_redraw()
	return can_accept

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	product_dropped.emit(customer.instance_id, str(data["product_id"]))

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _drop_hovered:
		_drop_hovered = false
		queue_redraw()

func play_wrong_drop() -> void:
	var original_x: float = position.x
	var tween := create_tween()
	tween.tween_property(self, "position:x", original_x - 9.0, 0.035)
	tween.tween_property(self, "position:x", original_x + 9.0, 0.07)
	tween.tween_property(self, "position:x", original_x, 0.035)

func play_correct_drop() -> void:
	if not is_instance_valid(portrait) or not is_instance_valid(order_bubble):
		return
	var tween := create_tween()
	tween.tween_property(portrait, "scale", Vector2(1.04, 1.04), 0.07)
	tween.tween_property(portrait, "scale", Vector2.ONE, 0.10)
	var bubble_tween := create_tween()
	bubble_tween.tween_property(order_bubble, "scale", Vector2(1.07, 1.07), 0.07)
	bubble_tween.tween_property(order_bubble, "scale", Vector2.ONE, 0.10)

func play_happy() -> void:
	var coin := Label.new()
	coin.text = "₱"
	coin.position = Vector2(93, 342)
	coin.add_theme_font_size_override("font_size", 33)
	coin.add_theme_color_override("font_color", Color("f6d95e"))
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(coin)
	var tween := create_tween()
	tween.tween_property(coin, "position:y", 255.0, 0.45)
	tween.parallel().tween_property(coin, "modulate:a", 0.0, 0.45)
	tween.tween_callback(coin.queue_free)

func play_annoyed() -> void:
	if not is_instance_valid(portrait):
		return
	var tween := create_tween()
	tween.tween_property(portrait, "position:x", PORTRAIT_POSITION.x - 6.0, 0.05)
	tween.tween_property(portrait, "position:x", PORTRAIT_POSITION.x + 6.0, 0.10)
	tween.tween_property(portrait, "position:x", PORTRAIT_POSITION.x, 0.05)
	var bubble_tween := create_tween()
	bubble_tween.tween_property(order_bubble, "modulate", Color("e7aaa0"), 0.08)
	bubble_tween.tween_property(order_bubble, "modulate", Color.WHITE, 0.16)

func _draw() -> void:
	if _drop_hovered:
		draw_rect(Rect2(3, 3, size.x - 6, size.y - 6), Color("ffd77b"), false, 4.5)

func _display_name(customer_id: String) -> String:
	var names := {
		"aleng_mila": "Mila", "kuya_ben": "Ben", "ate_liza": "Liza",
		"jun": "Jun", "manong_tomas": "Tomas", "nina": "Nina",
		"aling_nena": "Aling Nena", "mang_berting": "Mang Berting",
		"bea": "Bea", "paolo": "Paolo", "kuya_dodong": "Kuya Dodong", "jun_jun": "Jun-jun"
	}
	return str(names.get(customer_id, customer_id.capitalize()))

func _make_box(fill_color: Color, border_color: Color, border_width: int, padding: float = 6.0, corner_radius: int = 6) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill_color
	box.border_color = border_color
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(corner_radius)
	box.content_margin_left = padding
	box.content_margin_top = padding
	box.content_margin_right = padding
	box.content_margin_bottom = padding
	return box
