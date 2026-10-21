extends Control

const DEFAULT_STORE_DISPLAY_SCALE: float = 1.6

var product_id: String = ""
var drag_enabled: bool = true
var _item_icon: Texture2D
var _display_texture: Texture2D
var _display_size: Vector2 = Vector2.ZERO
var _rotated: bool = false
var _stock_count: int = 1
var _display_scale: float = DEFAULT_STORE_DISPLAY_SCALE

func configure(product: ProductData, icon_texture: Texture2D, can_drag: bool, display_size: Vector2, rotated: bool, display_texture: Texture2D = null, stock_count: int = 1, display_scale: float = DEFAULT_STORE_DISPLAY_SCALE) -> void:
	product_id = product.id
	_item_icon = icon_texture
	_display_texture = display_texture if display_texture != null else icon_texture
	drag_enabled = can_drag
	_display_size = display_size
	_rotated = rotated
	_stock_count = maxi(1, stock_count)
	_display_scale = display_scale
	modulate = Color.WHITE if can_drag else Color(0.46, 0.46, 0.46, 0.76)
	queue_redraw()

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Drag this product to the customer who ordered it."

func _draw() -> void:
	var display_texture := _display_texture if _display_texture != null else _item_icon
	if product_id == "candy":
		_draw_combined_display("candy")
		return
	if product_id == "soft_drink":
		_draw_combined_display("soft_drink")
		return
	if display_texture == null or _display_size == Vector2.ZERO:
		return
	var store_display_size: Vector2 = _get_store_display_size()
	var min_item_gap: float = minf(3.0, size.x * 0.03)
	var max_item_width: float = (size.x - min_item_gap * float(_stock_count + 1)) / float(_stock_count)
	store_display_size.x = minf(store_display_size.x, max_item_width)
	store_display_size.y = minf(store_display_size.y, size.y)
	var horizontal_gap: float = (size.x - store_display_size.x * float(_stock_count)) / float(_stock_count + 1)
	var y: float = 0.0 if product_id.ends_with("_sachet") or product_id == "soft_drink" else size.y - store_display_size.y
	for index in range(_stock_count):
		var x: float = horizontal_gap + float(index) * (store_display_size.x + horizontal_gap)
		var bounds := Rect2(Vector2(x, y), store_display_size)
		var fit_bounds: Vector2 = Vector2(bounds.size.y, bounds.size.x) if _rotated else bounds.size
		var fitted := CounterArt.fit_texture_rect(Vector2(display_texture.get_size()), fit_bounds)
		var sprite_size: Vector2 = Vector2(fitted.size.y, fitted.size.x) if _rotated else fitted.size
		var sprite_rect := Rect2(bounds.position + (bounds.size - sprite_size) * 0.5, sprite_size)
		draw_colored_polygon(CounterArt.get_display_shadow_polygon(sprite_rect), CounterArt.get_display_shadow_color())
		if _rotated:
			draw_set_transform(bounds.position + bounds.size * 0.5, PI * 0.5)
			draw_texture_rect(display_texture, Rect2(-fitted.size * 0.5, fitted.size), false, CounterArt.get_product_display_tint())
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_texture_rect(display_texture, sprite_rect, false, CounterArt.get_product_display_tint())

func _draw_combined_display(combined_product_id: String) -> void:
	var combined_texture: Texture2D = CounterArt.product_fixture_texture(combined_product_id)
	if combined_texture == null:
		return
	var fitted := CounterArt.fit_texture_rect(Vector2(combined_texture.get_size()), size)
	var sprite_rect := Rect2(fitted.position, fitted.size)
	draw_colored_polygon(CounterArt.get_display_shadow_polygon(sprite_rect), CounterArt.get_display_shadow_color())
	draw_texture_rect(combined_texture, sprite_rect, false, CounterArt.get_product_display_tint())

func _get_drag_data(_at_position: Vector2) -> Variant:
	if product_id.is_empty() or not drag_enabled:
		return null
	var preview := ProductDragPreview.new()
	preview.preview_texture = _item_icon
	preview.preview_size = _get_drag_preview_size()
	preview.rotated = _rotated
	preview.size = preview.preview_size + Vector2(8.0, 8.0)
	set_drag_preview(preview)
	return {"product_id": product_id}

func _get_store_display_size() -> Vector2:
	return _display_size * _display_scale

func _get_drag_preview_size() -> Vector2:
	return _display_size * 1.2

func play_reject() -> void:
	var origin_x: float = position.x
	var reject_tween := create_tween()
	reject_tween.tween_property(self, "position:x", origin_x - 3.0, 0.035)
	reject_tween.tween_property(self, "position:x", origin_x + 3.0, 0.07)
	reject_tween.tween_property(self, "position:x", origin_x, 0.035)

class ProductDragPreview extends Control:
	var preview_texture: Texture2D
	var preview_size: Vector2 = Vector2.ZERO
	var rotated: bool = false

	func _draw() -> void:
		if preview_texture == null:
			return
		var origin := Vector2(4.0, 4.0)
		draw_rect(Rect2(origin + Vector2(3.0, 4.0), preview_size), Color(0.0, 0.0, 0.0, 0.25), true)
		var fit_bounds: Vector2 = Vector2(preview_size.y, preview_size.x) if rotated else preview_size
		var fitted := CounterArt.fit_texture_rect(Vector2(preview_texture.get_size()), fit_bounds)
		if rotated:
			draw_set_transform(origin + preview_size * 0.5, PI * 0.5)
			draw_texture_rect(preview_texture, Rect2(-fitted.size * 0.5, fitted.size), false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_texture_rect(preview_texture, Rect2(origin + fitted.position, fitted.size), false)
