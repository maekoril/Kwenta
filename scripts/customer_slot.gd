extends Control

signal product_dropped(customer_id: String, product_id: String)

const PORTRAIT_ATLAS: Texture2D = preload("res://assets/sprites/customer_portraits.png")
const PRODUCT_ATLAS: Texture2D = preload("res://assets/sprites/kwenta_generic_products.png")
const COUNTER_ART = preload("res://scripts/counter_art.gd")
const ORDER_BUBBLE_ICON = preload("res://scripts/order_bubble_icon.gd")
const STOREFRONT_LAYOUT = preload("res://scripts/storefront_layout.gd")
const ORDER_ICON_CELL_SIZE := 20.0
const ORDER_BUBBLE_PADDING := 2.0
const ORDER_BUBBLE_COLUMNS := 3
const PORTRAIT_POSITION := Vector2(7.0, 63.0)
const PORTRAIT_SIZE := Vector2(54.0, 112.0)
const BUBBLE_HEAD_GAP := 15.0
const PATIENCE_GREEN := Color("4caa56")
const PATIENCE_YELLOW := Color("e3bd39")
const PATIENCE_RED := Color("d94536")

var customer: CustomerState
var order_bubble: PanelContainer
var order_grid: GridContainer
var patience_bar: ProgressBar
var patience_fill: StyleBoxFlat
var portrait: TextureRect
var name_tag: PanelContainer
var name_label: Label
var _drop_hovered: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(STOREFRONT_LAYOUT.CUSTOMER_WIDTH, STOREFRONT_LAYOUT.CUSTOMER_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	order_bubble = PanelContainer.new()
	order_bubble.name = "OrderBubble"
	order_bubble.add_theme_stylebox_override("panel", _make_box(Color("f2dfb9"), Color("593d2d"), 1, ORDER_BUBBLE_PADDING, 3))
	order_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(order_bubble)
	order_grid = GridContainer.new()
	order_grid.columns = ORDER_BUBBLE_COLUMNS
	order_grid.add_theme_constant_override("h_separation", 0)
	order_grid.add_theme_constant_override("v_separation", 0)
	order_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	order_bubble.add_child(order_grid)
	patience_bar = ProgressBar.new()
	patience_bar.name = "PatienceBar"
	patience_bar.custom_minimum_size = Vector2(20, 4)
	patience_bar.show_percentage = false
	patience_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patience_bar.add_theme_stylebox_override("background", _make_box(Color("30261f"), Color("30261f"), 0, 0.0, 1))
	patience_fill = StyleBoxFlat.new()
	patience_fill.set_corner_radius_all(1)
	patience_bar.add_theme_stylebox_override("fill", patience_fill)
	add_child(patience_bar)
	portrait = TextureRect.new()
	portrait.name = "Portrait"
	portrait.position = PORTRAIT_POSITION
	portrait.size = PORTRAIT_SIZE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	name_tag = PanelContainer.new()
	name_tag.name = "NameTrustTag"
	# Keep identity information on the visible upper body; the concrete sill
	# occludes everything from viewport y=176 downward.
	name_tag.position = Vector2(3, 53)
	name_tag.size = Vector2(62, 10)
	name_tag.add_theme_stylebox_override("panel", _make_box(Color(0.06, 0.07, 0.08, 0.86), Color(0.06, 0.07, 0.08, 0.86), 0, 0.5, 4))
	name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_tag)
	name_label = Label.new()
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 6)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
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

func refresh_display() -> void:
	if customer == null or not is_instance_valid(name_label):
		return
	name_label.text = "%s · %d%%" % [_display_name(customer.customer_id), int(customer.trust)]
	portrait.texture = COUNTER_ART.customer_portrait(customer.customer_id, PORTRAIT_ATLAS)
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
	var visible_columns: int = mini(ORDER_BUBBLE_COLUMNS, maxi(1, entry_count))
	var rows: int = maxi(1, int(ceil(float(entry_count) / float(ORDER_BUBBLE_COLUMNS))))
	var bubble_size := Vector2(
		float(visible_columns) * ORDER_ICON_CELL_SIZE + ORDER_BUBBLE_PADDING * 2.0,
		float(rows) * ORDER_ICON_CELL_SIZE + ORDER_BUBBLE_PADDING * 2.0
	)
	order_bubble.size = bubble_size
	var bubble_y := maxf(0.0, portrait.position.y - bubble_size.y - BUBBLE_HEAD_GAP)
	order_bubble.position = Vector2(roundf((size.x - bubble_size.x) * 0.5), bubble_y)
	order_bubble.pivot_offset = bubble_size * 0.5
	patience_bar.position = Vector2(order_bubble.position.x + ORDER_BUBBLE_PADDING, bubble_y + bubble_size.y + 1.0)
	patience_bar.size = Vector2(maxf(20.0, bubble_size.x - ORDER_BUBBLE_PADDING * 2.0), 4.0)
	name_tag.position = Vector2(3.0, patience_bar.position.y + patience_bar.size.y)

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
	return get_global_rect().has_point(viewport_position)

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
	quantity.add_theme_font_size_override("font_size", 6)
	quantity.add_theme_color_override("font_color", Color("478c45") if entry.completed else Color("493326"))
	quantity.position = Vector2(9, 9)
	quantity.size = Vector2(10, 10)
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
	tween.tween_property(self, "position:x", original_x - 3.0, 0.035)
	tween.tween_property(self, "position:x", original_x + 3.0, 0.07)
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
	coin.position = Vector2(31, 114)
	coin.add_theme_font_size_override("font_size", 11)
	coin.add_theme_color_override("font_color", Color("f6d95e"))
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(coin)
	var tween := create_tween()
	tween.tween_property(coin, "position:y", 85.0, 0.45)
	tween.parallel().tween_property(coin, "modulate:a", 0.0, 0.45)
	tween.tween_callback(coin.queue_free)

func play_annoyed() -> void:
	if not is_instance_valid(portrait):
		return
	var tween := create_tween()
	tween.tween_property(portrait, "position:x", PORTRAIT_POSITION.x - 2.0, 0.05)
	tween.tween_property(portrait, "position:x", PORTRAIT_POSITION.x + 2.0, 0.10)
	tween.tween_property(portrait, "position:x", PORTRAIT_POSITION.x, 0.05)
	var bubble_tween := create_tween()
	bubble_tween.tween_property(order_bubble, "modulate", Color("e7aaa0"), 0.08)
	bubble_tween.tween_property(order_bubble, "modulate", Color.WHITE, 0.16)

func _draw() -> void:
	if _drop_hovered:
		draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), Color("ffd77b"), false, 1.5)

func _display_name(customer_id: String) -> String:
	var names := {
		"aleng_mila": "Mila", "kuya_ben": "Ben", "ate_liza": "Liza",
		"jun": "Jun", "manong_tomas": "Tomas", "nina": "Nina"
	}
	return str(names.get(customer_id, customer_id.capitalize()))

func _make_box(fill_color: Color, border_color: Color, border_width: int, padding: float = 2.0, corner_radius: int = 2) -> StyleBoxFlat:
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
