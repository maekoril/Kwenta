extends SceneTree
const DEBUG = preload("res://scripts/debug_tools.gd")
const SETTINGS = preload("res://scripts/settings_menu.gd")
const TEST_PATH := "res://tmp/debug-settings-test.cfg"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DEBUG.options_path = TEST_PATH
	if has_meta(DEBUG.OPTIONS_META): remove_meta(DEBUG.OPTIONS_META)
	# A legacy automatically-saved true must not defeat the new default.
	var legacy := ConfigFile.new()
	legacy.set_value("playtest", "controls_visible", true)
	assert(legacy.save(TEST_PATH) == OK)
	var debug = DEBUG.new()
	root.add_child(debug)
	await process_frame
	assert(not debug.controls_visible and not debug.opener.visible and not debug.panel.visible)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(945, 430)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	preload("res://scripts/audio_settings.gd").initialize()
	var settings = SETTINGS.new()
	viewport.add_child(settings)
	settings.open()
	await process_frame
	await process_frame
	assert(settings.debug_tool_checkbox.text == "Debug tool")
	assert(not settings.debug_tool_checkbox.button_pressed)
	settings.debug_tool_checkbox.button_pressed = true
	assert(debug.controls_visible and debug.opener.visible)
	assert(not debug.panel.visible)
	var f3 := InputEventKey.new()
	f3.pressed = true
	f3.keycode = KEY_F3
	debug._input(f3)
	assert(not debug.controls_visible and not settings.debug_tool_checkbox.button_pressed)
	debug._input(f3)
	assert(debug.controls_visible and settings.debug_tool_checkbox.button_pressed)
	debug._toggle()
	assert(paused and debug.panel.visible)
	settings.debug_tool_checkbox.button_pressed = false
	assert(not debug.panel.visible and not paused and not debug.opener.visible)
	settings.debug_tool_checkbox.button_pressed = true
	debug.queue_free()
	await process_frame
	debug = DEBUG.new()
	root.add_child(debug)
	await process_frame
	assert(debug.controls_visible and debug.opener.visible)
	settings.open()
	assert(settings.debug_tool_checkbox.button_pressed)
	settings.debug_tool_checkbox.button_pressed = false
	await process_frame
	await process_frame
	var visible_size: Vector2 = settings.settings_panel.size * settings.settings_panel.scale
	assert(visible_size.x <= 945 and visible_size.y <= 430)
	var panel_rect: Rect2 = settings.settings_panel.get_global_rect()
	assert(panel_rect.position.x >= 0 and panel_rect.position.y >= 0)
	assert(panel_rect.end.x <= 945 and panel_rect.end.y <= 430)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://output/settings-debug-phone.png")
	viewport.queue_free()
	debug.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("Hidden default, legacy migration, Settings/F3 sync, pause restoration, persistence and phone fit: PASS")
	quit()
