extends Control

signal product_dropped(customer_id: String, product_id: String)

const PORTRAIT_ATLAS: Texture2D = preload("res://assets/sprites/customer_portraits.png")
const PRODUCT_ATLAS: Texture2D = preload("res://assets/sprites/kwenta_generic_products.png")
const COUNTER_ART = preload("res://scripts/counter_art.gd")
const ORDER_BUBBLE_ICON = preload("res://scripts/order_bubble_icon.gd")
const STOREFRONT_LAYOUT = preload("res://scripts/storefront_layout.gd")

var customer: CustomerState
var order_bubble: PanelContainer
var order_grid: GridContainer
var patience_bar: ProgressBar
var patience_fill: StyleBoxFlat
var portrait: TextureRect
var name_label: Label
var _drop_hovered: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(STOREFRONT_LAYOUT.CUSTOMER_WIDTH, STOREFRONT_LAYOUT.CUSTOMER_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	order_bubble = PanelContainer.new()
	order_bubble.position = Vector2.ZERO
	order_bubble.size = Vector2(68, 47)
	order_bubble.pivot_offset = order_bubble.size * 0.5
	order_bubble.add_theme_stylebox_override("panel", _make_box(Color("f2dfb9"), Color("593d2d"), 1))
	order_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(order_bubble)
	var bubble_content := VBoxContainer.new()
	bubble_content.add_theme_constant_override("separation", 0)
	order_bubble.add_child(bubble_content)
	order_grid = GridContainer.new()
	order_grid.columns = 3
	order_grid.add_theme_constant_override("h_separation", 0)
	order_grid.add_theme_constant_override("v_separation", 0)
	order_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble_content.add_child(order_grid)
	patience_bar = ProgressBar.new()
	patience_bar.custom_minimum_size = Vector2(60, 4)
	patience_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	patience_bar.show_percentage = false
	patience_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patience_bar.add_theme_stylebox_override("background", _make_box(Color("76594a"), Color("76594a"), 0))
	patience_fill = StyleBoxFlat.new()
	patience_bar.add_theme_stylebox_override("fill", patience_fill)
	bubble_content.add_child(patience_bar)
	portrait = TextureRect.new()
	portrait.position = Vector2(7, 49)
	portrait.size = Vector2(54, 76)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	name_label = Label.new()
	name_label.position = Vector2(0, 125)
	name_label.size = Vector2(68, 14)
	name_label.add_theme_font_size_override("font_size", 6)
	name_label.add_theme_color_override("font_color", Color("fff0cf"))
	name_label.add_theme_color_override("font_shadow_color", Color(0.08, 0.05, 0.04, 0.9))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_label)
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
	refresh_patience()
	queue_redraw()

func refresh_patience() -> void:
	if customer == null or not is_instance_valid(patience_bar):
		return
	var patience_ratio: float = clampf(customer.patience_remaining / maxf(customer.patience_seconds, 0.001), 0.0, 1.0)
	patience_bar.value = patience_ratio * 100.0
	var warning_mix: float = clampf((0.70 - patience_ratio) / 0.70, 0.0, 1.0)
	patience_fill.bg_color = Color("4caa56").lerp(Color("e3bd39"), minf(warning_mix * 2.0, 1.0)).lerp(Color("d94536"), maxf(warning_mix * 2.0 - 1.0, 0.0))

func _make_order_item(entry: Dictionary) -> Control:
	var item := Control.new()
	item.custom_minimum_size = Vector2(20, 18)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var product_id: String = str(entry.product_id)
	var icon: Control = ORDER_BUBBLE_ICON.new()
	icon.set("icon_texture", COUNTER_ART.product_icon(product_id, PRODUCT_ATLAS))
	icon.position = Vector2(1, 0)
	icon.size = Vector2(17, 18)
	icon.modulate = Color("a4a4a4") if entry.completed else Color.WHITE
	item.add_child(icon)
	var quantity := Label.new()
	quantity.text = "✓" if entry.completed else ("×%d" % int(entry.remaining) if int(entry.requested) > 1 else "")
	quantity.add_theme_font_size_override("font_size", 5)
	quantity.add_theme_color_override("font_color", Color("478c45") if entry.completed else Color("493326"))
	quantity.position = Vector2(9, 9)
	quantity.size = Vector2(10, 9)
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

func _draw() -> void:
	if _drop_hovered:
		draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), Color("ffd77b"), false, 1.5)

func _display_name(customer_id: String) -> String:
	var names := {
		"aleng_mila": "Mila", "kuya_ben": "Ben", "ate_liza": "Liza",
		"jun": "Jun", "manong_tomas": "Tomas", "nina": "Nina"
	}
	return str(names.get(customer_id, customer_id.capitalize()))

func _make_box(fill_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill_color
	box.border_color = border_color
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(2)
	box.content_margin_left = 2.0
	box.content_margin_top = 1.0
	box.content_margin_right = 2.0
	box.content_margin_bottom = 1.0
	return box
