extends SceneTree
const Renderer = preload("res://scripts/store_layer_renderer.gd")
const MainScene = preload("res://scenes/main.tscn")
const RAIN_STORE_BACKGROUND = preload("res://assets/store/kwenta_layer_pack/bg_empty_rain.png")
const FIESTA_BACKGROUND = preload("res://assets/store/kwenta_layer_pack/bg_empty_fiesta.png")
const FIESTA_BROWNOUT_BACKGROUND = preload("res://assets/store/kwenta_layer_pack/bg_empty_fiesta_brownout.png")
const EVENING_BACKGROUND = preload("res://assets/store/kwenta_layer_pack/bg_empty_golden_hour.png")
const NIGHT_BACKGROUND = preload("res://assets/store/kwenta_layer_pack/bg_empty_night_lights.png")
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
	_assert(renderer.get_node_or_null("RainStreet") == null, "renderer no longer keeps an unused window-only rain street layer")
	_assert(renderer.get_node("FrontBackground").material == null, "sunny foreground uses no weather shader material")
	_assert(renderer.get_node_or_null("WindowRain") != null, "renderer adds sparse rain only over the window")
	var fade_background := renderer.get_node_or_null("EnvironmentFadeBackground") as TextureRect
	var fade_sill := renderer.get_node_or_null("EnvironmentFadeSill") as TextureRect
	_assert(fade_background != null and fade_background.z_index == 0 and fade_sill != null and fade_sill.z_index == 10, "renderer owns reusable base and sill crossfade layers")
	var occlusion_sill := renderer.get_node_or_null("EnvironmentOcclusionSill") as TextureRect
	_assert(occlusion_sill != null and occlusion_sill.z_index > fade_sill.z_index, "renderer owns an opaque sill compositor above the fading sill layers")
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
	_assert(renderer.get_node_or_null("Slots/bato_spring_water_lock") == null and renderer.get_node_or_null("Slots/condiments_lock") == null, "buyable shelves show no floating locks; purchases happen only in the shop")
	renderer.configure(1, 300)
	_assert(renderer.get_node_or_null("Slots/bato_spring_water_lock") == null, "reconfigured shelves remain free of lock badges")
	renderer.queue_free()
	var main := MainScene.instantiate() as Control
	root.add_child(main)
	await process_frame
	var weather_grade := main.get_node_or_null("WeatherGrade") as ColorRect
	var environment_table = main.get("ENVIRONMENT_BY_DAY")
	_assert(environment_table is Dictionary and environment_table.size() == 7, "one environment table defines every story day")
	_assert(environment_table is Dictionary and environment_table.get(4, {}).get("base_path") == RAIN_STORE_BACKGROUND.resource_path and environment_table.get(4, {}).get("full_background", false), "environment table uses the rainy asset as the complete wet-day background")
	_assert(environment_table.get(5, {}).get("base_path") == "" and environment_table.get(5, {}).get("sunbeams", false), "Day 5 returns to the standard sunny environment")
	_assert(environment_table.get(6, {}).get("base_path") == FIESTA_BACKGROUND.resource_path and environment_table.get(6, {}).get("brownout_path") == FIESTA_BROWNOUT_BACKGROUND.resource_path and environment_table.get(6, {}).get("brownout_at_game_minute") == 360, "Day 6 keeps fiesta and brownout assets plus its tunable 2 PM trigger in the environment table")
	_assert(environment_table.get(1, {}).get("evening_path") == EVENING_BACKGROUND.resource_path and environment_table.get(4, {}).get("evening_path") == "" and environment_table.get(6, {}).get("evening_path") == "", "only sunny days configure the evening asset")
	_assert(weather_grade != null and weather_grade.z_index < 30 and is_zero_approx(weather_grade.color.a), "Day 1 starts with an inactive grade below the HUD")
	_assert(main.get_node_or_null("RainCanvasTint") == null, "the environment does not use a global CanvasModulate")
	_assert(main.get_node_or_null("RainFlicker") != null, "main scene owns the one-time rain flicker")
	var main_renderer := main.get("store_layer_renderer") as Control
	var day_one_rain := main_renderer.get_node_or_null("WindowRain") as Control
	var day_one_sunbeams := main_renderer.get_node_or_null("SunbeamOverlay") as Sprite2D
	await create_timer(0.55).timeout
	_assert(day_one_rain != null and not day_one_rain.visible and day_one_sunbeams != null and day_one_sunbeams.visible and is_equal_approx(day_one_sunbeams.modulate.a, 0.65), "Day 1 applies the sunny environment")
	var supports_environment_apply := main.has_method("apply_environment")
	_assert(supports_environment_apply, "main scene exposes one environment application function")
	if supports_environment_apply:
		main.call("apply_environment", 4)
		await create_timer(0.55).timeout
		_assert(day_one_rain.visible and main_renderer.get_node("EmptyBackground").texture == RAIN_STORE_BACKGROUND and not day_one_sunbeams.visible and is_zero_approx(day_one_sunbeams.modulate.a), "Day 4 swaps the entire rainy base, keeps window rain particles, and hides sunbeams")
		_assert(is_zero_approx(weather_grade.color.a) and weather_grade.z_index < 30, "Day 4 uses the authored rainy background without an extra global grade")
		_assert(not main_renderer.get_node("FrontBackground").visible and main_renderer.get_node("FrontBackground").material == null, "Day 4 hides the old sunny foreground because the rainy base already includes the sill")
		var rainy_sill := main_renderer.get_node_or_null("RainForegroundSill") as TextureRect
		_assert(rainy_sill != null and rainy_sill.visible and rainy_sill.z_index > main.get("customer_layer").z_index and rainy_sill.z_index < main.get("product_layer").z_index, "Day 4 draws the rainy-image sill above customers and below products")
		var debug_day := InputEventKey.new()
		debug_day.keycode = KEY_5
		debug_day.pressed = true
		main.call("_unhandled_input", debug_day)
		await create_timer(0.55).timeout
		_assert(int(main.get("campaign").day) == 1 and not day_one_rain.visible and day_one_sunbeams.visible and main_renderer.get_node("FrontBackground").visible, "debug day shortcut previews sunny Day 5 without changing story progress")
		var shift_elapsed_before_debug_time := float(main.get("shift").elapsed_seconds)
		var debug_time := InputEventKey.new()
		debug_time.ctrl_pressed = true
		debug_time.keycode = KEY_5
		debug_time.pressed = true
		main.call("_unhandled_input", debug_time)
		_assert(int(main.get("environment_game_minute")) == 540 and is_equal_approx(float(main.get("shift").elapsed_seconds), shift_elapsed_before_debug_time), "Ctrl+5 previews 5 PM without advancing shift or story progress")
		main.call("apply_environment", 1)
		_assert(main.has_method("set_environment_game_minute"), "main exposes a time-based environment update hook")
		if main.has_method("set_environment_game_minute"):
			main.call("set_environment_game_minute", 540)
			var evening_fade := main_renderer.get_node_or_null("EnvironmentFadeBackground") as TextureRect
			_assert(evening_fade != null and evening_fade.texture == EVENING_BACKGROUND and is_equal_approx(evening_fade.modulate.a, 0.5), "5 PM crossfades a sunny day to the evening image")
			main.call("apply_environment", 3)
			var stocked_before: Array = main_renderer.stock.duplicate()
			main.call("set_environment_game_minute", 510)
			_assert(evening_fade.texture == EVENING_BACKGROUND and is_equal_approx(evening_fade.modulate.a, 0.5), "Day 3 reaches half golden hour at 4:30")
			main.call("set_environment_game_minute", 570)
			_assert(main_renderer.get_node("EmptyBackground").texture == EVENING_BACKGROUND and evening_fade.texture == NIGHT_BACKGROUND and is_equal_approx(evening_fade.modulate.a, 0.5), "Day 3 crossfades golden hour to lit night at 5:30")
			_assert(not day_one_sunbeams.visible and main_renderer.stock == stocked_before and main_renderer.get_node_or_null("Slots/feeta_product") != null, "night hides sunbeams and preserves products")
			main.call("set_environment_game_minute", 600)
			_assert(is_equal_approx(evening_fade.modulate.a, 1.0), "Day 3 shows full night at 6 PM")
			main.call("set_environment_game_minute", 480)
			_assert(main_renderer.get_node("EmptyBackground").texture == Renderer.EMPTY_BACKGROUND and evening_fade.texture == EVENING_BACKGROUND and is_zero_approx(evening_fade.modulate.a), "rewinding the preview restores daytime")
		main.call("apply_environment", 6)
		_assert(main.has_method("trigger_day_six_brownout"), "main exposes a Day 6 brownout trigger")
		main.call("apply_environment", 7)
		_assert(main_renderer.get_node("FrontBackground").visible and main_renderer.get_node("FrontBackground").material == null and rainy_sill != null and not rainy_sill.visible and main_renderer.get_node("EmptyBackground").texture != RAIN_STORE_BACKGROUND, "sunny Day 7 restores the sunny foreground and base")
	main.queue_free()
	if failures > 0: quit(1)
	quit(0)
func _assert(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
