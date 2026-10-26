class_name StoreLayerRenderer
extends Control

const BASE := Vector2(1672.0, 941.0)
const CONFIG := preload("res://scripts/store_config.gd")
const EMPTY_BACKGROUND := preload("res://assets/store/kwenta_layer_pack/bg_empty.png")
const WINDOW_RAIN := preload("res://scripts/window_rain.gd")
const SUNBEAMS := preload("res://assets/store/kwenta_layer_pack/sunbeams_overlay.png")
const FULL_BACKGROUND_SILL_RECT := Rect2(0.0, 377.0, 1672.0, 68.0)
const WINDOW_RAIN_BOUNDS := Rect2(294.0, 90.0, 1072.0, 292.0)
var slots := {}
var stock := []
var debug_slots := false
var current_day := 1
var current_cash := 0
var purchased_groups: Array = []
var store_config: Dictionary = {}
var sunbeam_tween: Tween
var environment_crossfade_tween: Tween
var environment_crossfade_sill_source: Texture2D
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
	var full_background := bool(settings.get("full_background", false))
	if empty_background != null:
		empty_background.texture = base_texture if base_texture != null else EMPTY_BACKGROUND
	_apply_full_background_sill(full_background, base_texture if base_texture != null else EMPTY_BACKGROUND)
	var rain := get_node_or_null("WindowRain") as Control
	if rain != null:
		rain.visible = bool(settings.get("rain_particles", false))
	_apply_foreground_mode(full_background)
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
	var fade_background := TextureRect.new()
	fade_background.name = "EnvironmentFadeBackground"
	fade_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade_background.stretch_mode = TextureRect.STRETCH_SCALE
	fade_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_background.z_index = 0
	fade_background.visible = false
	fade_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_background)
	var rainy_sill := TextureRect.new()
	rainy_sill.name = "RainForegroundSill"
	rainy_sill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rainy_sill.stretch_mode = TextureRect.STRETCH_SCALE
	rainy_sill.z_index = 10
	rainy_sill.visible = false
	rainy_sill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rainy_sill)
	var fade_sill := TextureRect.new()
	fade_sill.name = "EnvironmentFadeSill"
	fade_sill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade_sill.stretch_mode = TextureRect.STRETCH_SCALE
	fade_sill.z_index = 10
	fade_sill.visible = false
	fade_sill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_sill)
	_layout_weather_layers()

func _layout_weather_layers() -> void:
	if size == Vector2.ZERO:
		return
	var scale := size / BASE
	var rain := get_node_or_null("WindowRain") as Control
	if rain != null:
		rain.position = WINDOW_RAIN_BOUNDS.position * scale
		rain.size = WINDOW_RAIN_BOUNDS.size * scale
	var sunbeams := get_node_or_null("SunbeamOverlay") as Sprite2D
	if sunbeams != null:
		sunbeams.scale = scale
	var rainy_sill := get_node_or_null("RainForegroundSill") as TextureRect
	if rainy_sill != null:
		rainy_sill.position = FULL_BACKGROUND_SILL_RECT.position * scale
		rainy_sill.size = FULL_BACKGROUND_SILL_RECT.size * scale
	var fade_sill := get_node_or_null("EnvironmentFadeSill") as TextureRect
	if fade_sill != null:
		fade_sill.position = FULL_BACKGROUND_SILL_RECT.position * scale
		fade_sill.size = FULL_BACKGROUND_SILL_RECT.size * scale

func set_environment_crossfade(texture: Texture2D, alpha: float) -> void:
	var fade_background := get_node_or_null("EnvironmentFadeBackground") as TextureRect
	var fade_sill := get_node_or_null("EnvironmentFadeSill") as TextureRect
	if fade_background == null or fade_sill == null or texture == null:
		return
	if fade_background.texture != texture:
		fade_background.texture = texture
	if environment_crossfade_sill_source != texture:
		var sill_texture := AtlasTexture.new()
		sill_texture.atlas = texture
		sill_texture.region = FULL_BACKGROUND_SILL_RECT
		fade_sill.texture = sill_texture
		environment_crossfade_sill_source = texture
	var clamped_alpha := clampf(alpha, 0.0, 1.0)
	fade_background.visible = clamped_alpha > 0.0
	fade_sill.visible = clamped_alpha > 0.0
	fade_background.modulate.a = clamped_alpha
	fade_sill.modulate.a = clamped_alpha

func start_environment_crossfade(texture: Texture2D, duration: float) -> void:
	set_environment_crossfade(texture, 0.0)
	var fade_background := get_node_or_null("EnvironmentFadeBackground") as TextureRect
	var fade_sill := get_node_or_null("EnvironmentFadeSill") as TextureRect
	if fade_background == null or fade_sill == null:
		return
	fade_background.visible = true
	fade_sill.visible = true
	if environment_crossfade_tween != null and environment_crossfade_tween.is_valid():
		environment_crossfade_tween.kill()
	environment_crossfade_tween = create_tween()
	environment_crossfade_tween.tween_property(fade_background, "modulate:a", 1.0, duration)
	environment_crossfade_tween.parallel().tween_property(fade_sill, "modulate:a", 1.0, duration)

func clear_environment_crossfade() -> void:
	if environment_crossfade_tween != null and environment_crossfade_tween.is_valid():
		environment_crossfade_tween.kill()
	var fade_background := get_node_or_null("EnvironmentFadeBackground") as TextureRect
	var fade_sill := get_node_or_null("EnvironmentFadeSill") as TextureRect
	if fade_background != null:
		fade_background.visible = false
		fade_background.texture = null
	if fade_sill != null:
		fade_sill.visible = false
		fade_sill.texture = null
	environment_crossfade_sill_source = null

func set_front_background_alpha(alpha: float) -> void:
	var foreground := get_node_or_null("FrontBackground") as TextureRect
	if foreground == null:
		return
	foreground.modulate.a = clampf(alpha, 0.0, 1.0)
	foreground.visible = foreground.modulate.a > 0.0

func _apply_full_background_sill(show: bool, background_texture: Texture2D) -> void:
	var rainy_sill := get_node_or_null("RainForegroundSill") as TextureRect
	if rainy_sill == null:
		return
	rainy_sill.visible = show
	if not show:
		return
	var sill_texture := AtlasTexture.new()
	sill_texture.atlas = background_texture
	sill_texture.region = FULL_BACKGROUND_SILL_RECT
	rainy_sill.texture = sill_texture

func _apply_foreground_mode(full_background: bool) -> void:
	var foreground := get_node_or_null("FrontBackground") as TextureRect
	if foreground == null:
		return
	if full_background:
		foreground.material = null
		foreground.visible = false
		return
	foreground.visible = true
	foreground.modulate.a = 1.0
	foreground.material = null

func _fade_sunbeams(show: bool) -> void:
	var sunbeams := get_node_or_null("SunbeamOverlay") as Sprite2D
	if sunbeams == null:
		return
	var target_alpha := 0.65 if show else 0.0
	if show:
		sunbeams.visible = true
	if is_equal_approx(sunbeams.modulate.a, target_alpha):
		sunbeams.visible = show
		return
	if sunbeam_tween != null and sunbeam_tween.is_valid():
		sunbeam_tween.kill()
	sunbeam_tween = create_tween()
	sunbeam_tween.tween_property(sunbeams, "modulate:a", target_alpha, 0.5)
	if not show:
		sunbeam_tween.tween_callback(sunbeams.hide)

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
