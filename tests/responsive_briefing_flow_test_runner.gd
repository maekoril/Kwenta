extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	for viewport_size in [Vector2(1920, 1080), Vector2(2340, 1080), Vector2(1440, 1080)]:
		menu.size = viewport_size
		menu._layout_menu()
		var canvas: Control = menu.menu_canvas
		var actual: Vector2 = canvas.size * canvas.scale
		assert(actual.x >= viewport_size.x - 0.1 and actual.y >= viewport_size.y - 0.1)
		assert(canvas.position.x <= 0.1 and canvas.position.y <= 0.1)
		assert(canvas.get_node("StartButton").position.x + canvas.get_node("StartButton").size.x < canvas.size.x)
	menu.queue_free()
	await process_frame
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	for viewport_size in [Vector2(1920, 1080), Vector2(2340, 1080), Vector2(1440, 1080), Vector2(1280, 720), Vector2(720, 405)]:
		main.size = viewport_size
		main._recenter_fixed_hud()
		await process_frame
		var day_chip: Control = main.day_label.get_parent().get_parent()
		var clock_chip: Control = main.clock_label.get_parent().get_parent()
		var cash_chip: Control = main.cash_label.get_parent().get_parent()
		var pause_button: Control = main.pause_menu._button
		var hud_scale: float = main._hud_scale()
		var margin := maxf(20.0, main.HUD_SAFE_MARGIN * hud_scale)
		assert(main.goal_panel.position.x >= margin - 0.1)
		assert(main.goal_panel.position.x + main.goal_panel.size.x * hud_scale < day_chip.position.x)
		assert(absf((day_chip.position.x + cash_chip.position.x + cash_chip.size.x * hud_scale) * 0.5 - viewport_size.x * 0.5) < 0.1)
		assert(cash_chip.position.x + cash_chip.size.x * hud_scale < main.trust_tag.position.x)
		assert(absf(main.utility_toggle.position.x + main.utility_toggle.size.x * hud_scale - (viewport_size.x - margin)) < 0.1)
		assert(main.utility_drawer.position.x >= margin - 0.1)
		assert(main.utility_drawer.position.x + main.utility_drawer.size.x * hud_scale <= viewport_size.x - margin + 0.1)
		assert(main.story_illustration.size.is_equal_approx(viewport_size))
		assert(main.story_illustration.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED)
		for prop in ["berting_counter_closeup", "lina_walking_away", "friends_shelter"]:
			main._show_story_prop(prop)
			assert(main.story_illustration.visible and main.story_illustration.position.is_equal_approx(Vector2.ZERO))
		main._show_story_prop("hide_scene_illustration")
		await main.story_illustration_tween.finished
		assert(not main.get_node("StoryIllustrationBackdrop").visible)
	for day in range(1, 8):
		main.campaign.day = day
		main.supplier_story_blocked = false
		main._refresh_utility_drawer()
		assert(main.utility_shop.visible == (day >= 2))
		assert(main.utility_utang.visible == (day >= 4))
		if day == 2:
			main.supplier_story_blocked = true
			main._refresh_utility_drawer()
			assert(not main.utility_shop.visible)
			main.supplier_story_blocked = false
			main._refresh_utility_drawer()
		assert(main.utility_shop.icon is AtlasTexture)
		main.shift_in_progress = false
		main.shop_available = false
		main._show_pre_shift_briefing()
		assert(not main.shop_button.visible)
		assert(main._is_shop_available() == (day > 1))
		if day > 1:
			main._open_shelf_shop()
			assert(main.shelf_shop.visible)
			main.shelf_shop.close()
		main.briefing_card.hide_briefing()
	main.queue_free()
	await process_frame
	print("Menu and story illustrations fit varied viewports; supplier is available in briefings on Days 2–7")
	quit()
