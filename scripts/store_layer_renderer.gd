class_name StoreLayerRenderer
extends Control

const BASE := Vector2(1672.0, 941.0)
const CONFIG := preload("res://scripts/store_config.gd")
const EMPTY_BACKGROUND := preload("res://assets/store/kwenta_layer_pack/bg_empty.png")
const WINDOW_RAIN := preload("res://scripts/window_rain.gd")
const SUNBEAMS := preload("res://assets/store/kwenta_layer_pack/sunbeams_overlay.png")
const WINDOW_APERTURE := Rect2(368.0, 94.0, 920.0, 284.0)
# Source-art coordinates. The side rectangles overlap their wood posts by 2 px
# and the central rectangle overlaps the roof/sill by 2 px to prevent seams.
const WEATHER_MASK_LEFT_RECT := Rect2(296.0, 92.0, 74.0, 288.0)
const WEATHER_MASK_CENTER_RECT := Rect2(368.0, 92.0, 920.0, 288.0)
const WEATHER_MASK_RIGHT_RECT := Rect2(1286.0, 92.0, 78.0, 288.0)
const WEATHER_MASK_RECTS := [WEATHER_MASK_LEFT_RECT, WEATHER_MASK_CENTER_RECT, WEATHER_MASK_RIGHT_RECT]
const WEATHER_STREET_BOUNDS := Rect2(294.0, 90.0, 1072.0, 292.0)
const WEATHER_COUNTER_SHEEN_RECT := Rect2(280.0, 378.0, 1110.0, 68.0)
const WEATHER_FLOOR_LEFT_RECT := Rect2(0.0, 872.0, 360.0, 69.0)
const WEATHER_FLOOR_RIGHT_RECT := Rect2(1285.0, 872.0, 387.0, 69.0)
const WEATHER_LEFT_PILLAR_LIGHT_RECT := Rect2(76.0, 474.0, 190.0, 282.0)
const WEATHER_RIGHT_PILLAR_LIGHT_RECT := Rect2(1406.0, 474.0, 190.0, 282.0)
const WEATHER_LIGHT_RECTS := [WEATHER_COUNTER_SHEEN_RECT, WEATHER_FLOOR_LEFT_RECT, WEATHER_FLOOR_RIGHT_RECT, WEATHER_LEFT_PILLAR_LIGHT_RECT, WEATHER_RIGHT_PILLAR_LIGHT_RECT]
const WEATHER_SHADER := """
shader_type canvas_item;

uniform float weather_strength = 0.0;
uniform vec2 source_size = vec2(1672.0, 941.0);
uniform vec4 mask_left;
uniform vec4 mask_center;
uniform vec4 mask_right;
uniform vec4 light_counter;
uniform vec4 light_floor_left;
uniform vec4 light_floor_right;
uniform vec4 light_pillar_left;
uniform vec4 light_pillar_right;

bool in_rect(vec2 source_uv, vec4 rect) {
	return source_uv.x >= rect.x && source_uv.x <= rect.x + rect.z && source_uv.y >= rect.y && source_uv.y <= rect.y + rect.w;
}

float rect_weight(vec2 source_uv, vec4 rect) {
	return in_rect(source_uv, rect) ? 1.0 : 0.0;
}

void fragment() {
	vec4 art = texture(TEXTURE, UV);
	vec2 source_uv = UV * source_size;
	if (in_rect(source_uv, mask_left) || in_rect(source_uv, mask_center) || in_rect(source_uv, mask_right)) {
		art.a = 0.0;
	} else {
		float light = max(max(rect_weight(source_uv, light_counter), rect_weight(source_uv, light_floor_left)), max(max(rect_weight(source_uv, light_floor_right), rect_weight(source_uv, light_pillar_left)), rect_weight(source_uv, light_pillar_right)));
		float amount = light * weather_strength;
		vec3 cool_gray_blue = vec3(0.45, 0.52, 0.63);
		art.rgb = mix(art.rgb, cool_gray_blue, amount * 0.34);
		art.rgb *= 1.0 - amount * 0.18;
	}
	COLOR = art;
}
"""
var slots := {}
var stock := []
var debug_slots := false
var current_day := 1
var current_cash := 0
var purchased_groups: Array = []
var store_config: Dictionary = {}
var sunbeam_tween: Tween
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

func apply_environment(settings: Dictionary) -> void:
	var empty_background := get_node_or_null("EmptyBackground") as TextureRect
	var base_texture := settings.get("base_texture") as Texture2D
	if empty_background != null:
		empty_background.texture = base_texture if base_texture != null else EMPTY_BACKGROUND
	var street := get_node_or_null("RainStreet") as TextureRect
	var street_texture := settings.get("street_texture") as Texture2D
	if street != null:
		street.texture = street_texture
		street.visible = street_texture != null
	var rain := get_node_or_null("WindowRain") as Control
	if rain != null:
		rain.visible = bool(settings.get("rain_particles", false))
	_apply_foreground_weather(float(settings.get("weather_strength", 0.0)))
	_fade_sunbeams(bool(settings.get("sunbeams", false)))

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
	_layout_weather_layers()
	if store_config.is_empty():
		return
	configure(current_day, current_cash, purchased_groups)

func _build_backgrounds() -> void:
	for pair in [["EmptyBackground","res://assets/store/kwenta_layer_pack/bg_empty.png",0],["FrontBackground","res://assets/store/kwenta_layer_pack/bg_front.png",10]]:
		var rect := TextureRect.new(); rect.name=pair[0]; rect.texture=load(pair[1]); rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; rect.stretch_mode=TextureRect.STRETCH_SCALE; rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); rect.z_index=pair[2]; rect.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(rect)
	var street := TextureRect.new()
	street.name = "RainStreet"
	street.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	street.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	street.clip_contents = true
	street.z_index = 1
	street.visible = false
	street.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(street)
	var rain := WINDOW_RAIN.new()
	rain.name = "WindowRain"
	rain.z_index = 2
	rain.visible = false
	add_child(rain)
	var sunbeams := Sprite2D.new()
	sunbeams.name = "SunbeamOverlay"
	sunbeams.texture = SUNBEAMS
	sunbeams.centered = false
	sunbeams.position = Vector2.ZERO
	sunbeams.z_index = 3
	sunbeams.modulate.a = 0.0
	var sunbeam_material := CanvasItemMaterial.new()
	sunbeam_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sunbeams.material = sunbeam_material
	add_child(sunbeams)
	_layout_weather_layers()

func _layout_weather_layers() -> void:
	if size == Vector2.ZERO:
		return
	var scale := size / BASE
	var window_rect := Rect2(WEATHER_STREET_BOUNDS.position * scale, WEATHER_STREET_BOUNDS.size * scale)
	var street := get_node_or_null("RainStreet") as TextureRect
	if street != null:
		street.position = window_rect.position
		street.size = window_rect.size
	var rain := get_node_or_null("WindowRain") as Control
	if rain != null:
		rain.position = window_rect.position
		rain.size = window_rect.size
	var sunbeams := get_node_or_null("SunbeamOverlay") as Sprite2D
	if sunbeams != null:
		sunbeams.scale = scale

func _apply_foreground_weather(weather_strength: float) -> void:
	var foreground := get_node_or_null("FrontBackground") as TextureRect
	if foreground == null:
		return
	if is_zero_approx(weather_strength):
		foreground.material = null
		return
	var shader := Shader.new()
	shader.code = WEATHER_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("weather_strength", weather_strength)
	material.set_shader_parameter("source_size", BASE)
	_set_weather_shader_rect(material, "mask_left", WEATHER_MASK_LEFT_RECT)
	_set_weather_shader_rect(material, "mask_center", WEATHER_MASK_CENTER_RECT)
	_set_weather_shader_rect(material, "mask_right", WEATHER_MASK_RIGHT_RECT)
	_set_weather_shader_rect(material, "light_counter", WEATHER_COUNTER_SHEEN_RECT)
	_set_weather_shader_rect(material, "light_floor_left", WEATHER_FLOOR_LEFT_RECT)
	_set_weather_shader_rect(material, "light_floor_right", WEATHER_FLOOR_RIGHT_RECT)
	_set_weather_shader_rect(material, "light_pillar_left", WEATHER_LEFT_PILLAR_LIGHT_RECT)
	_set_weather_shader_rect(material, "light_pillar_right", WEATHER_RIGHT_PILLAR_LIGHT_RECT)
	foreground.material = material

func _set_weather_shader_rect(material: ShaderMaterial, parameter: String, rect: Rect2) -> void:
	material.set_shader_parameter(parameter, Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))

func _fade_sunbeams(show: bool) -> void:
	var sunbeams := get_node_or_null("SunbeamOverlay") as Sprite2D
	if sunbeams == null:
		return
	var target_alpha := 0.65 if show else 0.0
	if is_equal_approx(sunbeams.modulate.a, target_alpha):
		return
	if sunbeam_tween != null and sunbeam_tween.is_valid():
		sunbeam_tween.kill()
	sunbeam_tween = create_tween()
	sunbeam_tween.tween_property(sunbeams, "modulate:a", target_alpha, 0.5)

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
