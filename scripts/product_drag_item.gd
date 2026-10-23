extends Control

const DEFAULT_STORE_DISPLAY_SCALE: float = 1.6
const STOREFRONT_LAYOUT = preload("res://scripts/storefront_layout.gd")

signal product_released(product_id: String, viewport_position: Vector2, source: Control)

static var _active_drag_owner: Control

var product_id: String = ""
var drag_enabled: bool = true
var _item_icon: Texture2D
var _display_texture: Texture2D
var _display_size: Vector2 = Vector2.ZERO
var _rotated: bool = false
var _stock_count: int = 1
var _display_scale: float = DEFAULT_STORE_DISPLAY_SCALE
var _drag_preview: Control
var _drag_active: bool = false
var _drag_touch_index: int = -1

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
	set_process_input(false)

func _draw() -> void:
	var display_texture := _display_texture if _display_texture != null else _item_icon
	if STOREFRONT_LAYOUT.is_hanging_rail_product(product_id):
		_draw_hanging_sachet_strip()
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

func _draw_hanging_sachet_strip() -> void:
	# Rails use the authored connected strip; the isolated packet is reserved for
	# drag previews and order bubbles. This keeps the shelf state visually distinct.
	var strip_texture := _display_texture if _display_texture != null else _item_icon
	if strip_texture == null:
		return
	var fitted := CounterArt.fit_texture_rect(Vector2(strip_texture.get_size()), size)
	var sprite_rect := Rect2(fitted.position, fitted.size)
	draw_colored_polygon(CounterArt.get_display_shadow_polygon(sprite_rect), CounterArt.get_display_shadow_color())
	draw_texture_rect(strip_texture, sprite_rect, false, CounterArt.get_product_display_tint())

func _draw_combined_display(combined_product_id: String) -> void:
	var combined_texture: Texture2D = CounterArt.product_fixture_texture(combined_product_id)
	if combined_texture == null:
		return
	var fitted := CounterArt.fit_texture_rect(Vector2(combined_texture.get_size()), size)
	var sprite_rect := Rect2(fitted.position, fitted.size)
	draw_colored_polygon(CounterArt.get_display_shadow_polygon(sprite_rect), CounterArt.get_display_shadow_color())
	draw_texture_rect(combined_texture, sprite_rect, false, CounterArt.get_product_display_tint())

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_begin_drag(mouse_event.position, -1)
			accept_event()
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_begin_drag(touch_event.position, touch_event.index)
			accept_event()

func _input(event: InputEvent) -> void:
	if not _drag_active:
		return
	if event is InputEventMouseMotion and _drag_touch_index == -1:
		_move_drag_preview((event as InputEventMouseMotion).position)
	elif event is InputEventScreenDrag and (event as InputEventScreenDrag).index == _drag_touch_index:
		_move_drag_preview((event as InputEventScreenDrag).position)
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if _drag_touch_index == -1 and mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			_release_drag(mouse_event.position)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.index == _drag_touch_index and not touch_event.pressed:
			_release_drag(touch_event.position)

func _begin_drag(viewport_position: Vector2, touch_index: int) -> void:
	if _drag_active or _another_drag_is_active() or product_id.is_empty() or not drag_enabled:
		return
	_drag_active = true
	_drag_touch_index = touch_index
	_active_drag_owner = self
	var preview := ProductDragPreview.new()
	preview.preview_texture = _item_icon
	preview.preview_size = _get_drag_preview_size()
	preview.rotated = _rotated
	preview.size = preview.preview_size + Vector2(8.0, 8.0)
	preview.scale = Vector2.ONE * 1.15
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.z_index = 100
	var preview_parent: Node = get_tree().current_scene
	if preview_parent == null:
		preview_parent = get_tree().root
	preview_parent.add_child(preview)
	_drag_preview = preview
	_move_drag_preview(viewport_position)
	set_process_input(true)

func _move_drag_preview(viewport_position: Vector2) -> void:
	if is_instance_valid(_drag_preview):
		_drag_preview.global_position = viewport_position - _drag_preview.size * 0.5

func _release_drag(viewport_position: Vector2) -> void:
	if not _drag_active:
		return
	_drag_active = false
	_drag_touch_index = -1
	set_process_input(false)
	product_released.emit(product_id, viewport_position, self)

func finish_drag(accepted: bool) -> void:
	if not is_instance_valid(_drag_preview):
		_drag_active = false
		_clear_active_drag_owner()
		return
	var preview := _drag_preview
	_drag_preview = null
	_drag_active = false
	_drag_touch_index = -1
	set_process_input(false)
	if accepted:
		preview.queue_free()
		_clear_active_drag_owner()
		return
	play_reject()
	var return_tween := preview.create_tween()
	return_tween.set_trans(Tween.TRANS_SPRING)
	return_tween.set_ease(Tween.EASE_OUT)
	return_tween.tween_property(preview, "global_position", get_global_rect().get_center() - preview.size * 0.5, 0.28)
	return_tween.tween_callback(_finish_returned_preview.bind(preview))

func is_drag_active() -> bool:
	return _drag_active or is_instance_valid(_drag_preview)

func get_drag_preview_texture() -> Texture2D:
	return _item_icon

func _another_drag_is_active() -> bool:
	return is_instance_valid(_active_drag_owner) and _active_drag_owner != self

func _clear_active_drag_owner() -> void:
	if _active_drag_owner == self:
		_active_drag_owner = null

func _finish_returned_preview(preview: Control) -> void:
	if is_instance_valid(preview):
		preview.queue_free()
	_clear_active_drag_owner()

func _exit_tree() -> void:
	if is_instance_valid(_drag_preview):
		_drag_preview.queue_free()
	_clear_active_drag_owner()

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
