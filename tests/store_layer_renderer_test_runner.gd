extends SceneTree
const Renderer = preload("res://scripts/store_layer_renderer.gd")
const MainScene = preload("res://scenes/main.tscn")
const RAIN_STORE_BACKGROUND = preload("res://assets/store/kwenta_layer_pack/bg_empty_rain.png")
const SUNBEAMS = preload("res://assets/store/kwenta_layer_pack/sunbeams_overlay.png")
var failures := 0
func _initialize() -> void:
	var renderer := Renderer.new()
	renderer.size = Renderer.BASE
	root.add_child(renderer)
	await process_frame
	renderer.configure(1, 150)
	_assert(renderer.get_node_or_null("EmptyBackground") != null and renderer.get_node_or_null("FrontBackground") != null, "renderer creates both background layers")
	_assert(renderer.get_node("EmptyBackground").z_index < renderer.get_node("FrontBackground").z_index, "front art draws over customer layer")
	var rain_street := renderer.get_node_or_null("RainStreet") as TextureRect
	_assert(rain_street != null, "renderer owns a street layer behind the window frame")
	_assert(rain_street != null and rain_street.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED and rain_street.clip_contents, "rain street cover-fits and crops inside the complete window opening")
	var scaled_aperture := Rect2(Renderer.WINDOW_APERTURE.position * (renderer.size / Renderer.BASE), Renderer.WINDOW_APERTURE.size * (renderer.size / Renderer.BASE))
	_assert(rain_street != null and Rect2(rain_street.position, rain_street.size).encloses(scaled_aperture), "rain street covers the full aperture and side gaps behind the posts")
	_assert(rain_street != null and rain_street.z_index > renderer.get_node("EmptyBackground").z_index and rain_street.z_index < renderer.get_node("FrontBackground").z_index, "rain street stays between the base store art and front frame")
	_assert(Renderer.WEATHER_MASK_RECTS.size() == 3 and Renderer.WEATHER_MASK_RECTS[0] == Rect2(296.0, 92.0, 74.0, 288.0) and Renderer.WEATHER_MASK_RECTS[1] == Rect2(368.0, 92.0, 920.0, 288.0) and Renderer.WEATHER_MASK_RECTS[2] == Rect2(1286.0, 92.0, 78.0, 288.0), "weather mask source rectangles cover both opaque sunny side strips with a feathered overlap")
	_assert(Renderer.WEATHER_STREET_BOUNDS.encloses(Renderer.WEATHER_MASK_LEFT_RECT) and Renderer.WEATHER_STREET_BOUNDS.encloses(Renderer.WEATHER_MASK_CENTER_RECT) and Renderer.WEATHER_STREET_BOUNDS.encloses(Renderer.WEATHER_MASK_RIGHT_RECT), "cover-fit street bounds include every masked source-art pixel")
	_assert(Renderer.WEATHER_LIGHT_RECTS.size() == 5 and Renderer.WEATHER_LEFT_PILLAR_LIGHT_RECT == Rect2(76.0, 474.0, 190.0, 282.0) and Renderer.WEATHER_RIGHT_PILLAR_LIGHT_RECT == Rect2(1406.0, 474.0, 190.0, 282.0), "weather light correction source rectangles keep pillar correction separate from shelf wood")
	_assert(renderer.get_node("FrontBackground").material == null, "sunny foreground uses no weather shader material")
	_assert(renderer.get_node_or_null("WindowRain") != null, "renderer adds sparse rain only over the window")
	var sunbeams := renderer.get_node_or_null("SunbeamOverlay") as Sprite2D
	_assert(sunbeams != null and sunbeams.texture == SUNBEAMS, "renderer adds the named sunbeam overlay asset")
	_assert(sunbeams != null and not sunbeams.centered and sunbeams.position == Vector2.ZERO and sunbeams.z_index > renderer.get_node("EmptyBackground").z_index and sunbeams.z_index < renderer.get_node("FrontBackground").z_index, "sunbeam sprite aligns to the base and stays behind the frame")
	var sunbeam_material := sunbeams.material as CanvasItemMaterial if sunbeams != null else null
	_assert(sunbeam_material != null and sunbeam_material.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD, "sunbeams use additive blending")
	_assert(renderer.get_slot_rect("feeta").size.x > 0.0, "slot data exposes scaled tap bounds")
	_assert(renderer.get_node_or_null("Slots/feeta") != null, "stocked sticker has a tap target")
	_assert(renderer.get_node_or_null("Slots/feeta_product") != null, "stocked Day 1 product is rendered")
	_assert(renderer.get_node_or_null("Slots/zesty_product") == null, "locked story products stay empty instead of showing a product")
	_assert(renderer.get_node_or_null("Slots/zesty_lock") == null, "locked story products stay empty instead of showing a lock")
	_assert(renderer.get_node_or_null("Slots/bato_spring_water_lock") != null, "buyable stock shows one named lock")
	_assert(renderer.get_node_or_null("Slots/condiments_lock") != null, "condiment trio shares one lock")
	_assert(renderer.get_node_or_null("Slots/pating_lock") == null and renderer.get_node_or_null("Slots/real_suka_lock") == null, "condiment group does not duplicate locks")
	var water_lock := renderer.get_node_or_null("Slots/bato_spring_water_lock")
	_assert(water_lock != null and water_lock.get_node("LockLabel").text == "DAY 2", "future buyable lock states show its day")
	renderer.configure(2, 300)
	water_lock = renderer.get_node_or_null("Slots/bato_spring_water_lock")
	_assert(water_lock != null and water_lock.get_node("LockLabel").text == "₱250", "available buyable lock states show its price")
	renderer.queue_free()
	var main := MainScene.instantiate() as Control
	root.add_child(main)
	await process_frame
	var weather_grade := main.get_node_or_null("WeatherGrade") as ColorRect
	var environment_table = main.get("ENVIRONMENT_BY_DAY")
	_assert(environment_table is Dictionary and environment_table.size() == 6, "one environment table defines every configured story day")
	_assert(environment_table is Dictionary and environment_table.get(1, {}).get("base_texture") == null and environment_table.get(4, {}).get("base_texture") == RAIN_STORE_BACKGROUND and environment_table.get(4, {}).get("street_texture") == null, "environment table swaps the full rainy base instead of layering a second street")
	_assert(weather_grade != null and weather_grade.z_index < 30 and is_zero_approx(weather_grade.color.a), "Day 1 starts with an inactive grade below the HUD")
	_assert(main.get_node_or_null("RainCanvasTint") == null, "the environment does not use a global CanvasModulate")
	_assert(main.get_node_or_null("RainFlicker") != null, "main scene owns the one-time rain flicker")
	var main_renderer := main.get("store_layer_renderer") as Control
	var day_one_street := main_renderer.get_node_or_null("RainStreet") as TextureRect
	var day_one_rain := main_renderer.get_node_or_null("WindowRain") as Control
	var day_one_sunbeams := main_renderer.get_node_or_null("SunbeamOverlay") as Sprite2D
	await create_timer(0.55).timeout
	_assert(day_one_street != null and not day_one_street.visible and day_one_rain != null and not day_one_rain.visible and day_one_sunbeams != null and day_one_sunbeams.visible and is_equal_approx(day_one_sunbeams.modulate.a, 0.65), "Day 1 applies the sunny environment")
	var supports_environment_apply := main.has_method("apply_environment")
	_assert(supports_environment_apply, "main scene exposes one environment application function")
	if supports_environment_apply:
		main.call("apply_environment", 4)
		await create_timer(0.55).timeout
		_assert(not day_one_street.visible and day_one_rain.visible and main_renderer.get_node("EmptyBackground").texture == RAIN_STORE_BACKGROUND and not day_one_sunbeams.visible and is_zero_approx(day_one_sunbeams.modulate.a), "Day 4 swaps the entire rainy base, keeps window rain particles, and hides sunbeams")
		_assert(weather_grade.color.a > 0.0 and weather_grade.z_index < 30, "Day 4 applies a subtle grade without dimming the HUD")
		_assert(main_renderer.get_node("FrontBackground").material != null, "Day 4 applies the localized weather shader to the foreground art")
		var debug_day := InputEventKey.new()
		debug_day.keycode = KEY_5
		debug_day.pressed = true
		main.call("_unhandled_input", debug_day)
		await create_timer(0.55).timeout
		_assert(int(main.get("campaign").day) == 1 and not day_one_street.visible and not day_one_rain.visible and main_renderer.get_node("EmptyBackground").texture == RAIN_STORE_BACKGROUND and is_zero_approx(day_one_sunbeams.modulate.a) and main_renderer.get_node("FrontBackground").material != null, "debug day shortcut previews Day 5 without changing story progress")
		main.call("apply_environment", 7)
		_assert(main_renderer.get_node("FrontBackground").material == null and main_renderer.get_node("EmptyBackground").texture != RAIN_STORE_BACKGROUND, "sunny Day 7 clears the weather shader and restores the sunny base")
	main.queue_free()
	if failures > 0: quit(1)
	quit(0)
func _assert(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
