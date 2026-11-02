extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# A delivery ordered from a debug briefing must accept actual dialogue advances.
	set_meta("kwenta_debug_launch", {"day": 4, "moment": 1, "skip_tutorials": true, "day3_candy": "credit"})
	change_scene_to_file("res://scenes/main.tscn")
	await create_timer(0.5).timeout
	var main = current_scene
	assert(main.showing_pre_shift_briefing and main._is_paolo_debt_recorded())
	assert(main.campaign.has_debt("paolo"))
	main._open_shelf_shop()
	assert(main.shelf_shop.visible)
	main._on_shelf_shop_purchase_requested("water_shelf", 200)
	assert(main.story_after_action == "supplier_delivery_done")
	var beat_count: int = main.story_beats.size()
	for i in range(beat_count):
		assert(main.story_beat_index == i)
		main.bubble.advanced.emit()
	assert(main.shelf_shop.visible)
	main._on_shelf_shop_closed()
	assert(main.showing_pre_shift_briefing and main.briefing_card.visible)
	main._on_briefing_start_pressed()
	assert(main.shift_in_progress)

	# Selected past choices reconstruct balances without changing debug starting cash.
	for day in [5, 6, 7]:
		set_meta("kwenta_debug_launch", {"day": day, "moment": 1, "skip_tutorials": true, "day3_candy": "credit", "day5_debt": "installments"})
		change_scene_to_file("res://scenes/main.tscn")
		await create_timer(0.5).timeout
		main = current_scene
		assert(main.campaign.cash == 1500)
		assert(main._is_paolo_debt_recorded())
		assert(main.campaign.has_debt("paolo") == (day <= 6))
		for debt in main.campaign.debts:
			if debt.id == "rosa_old":
				assert(int(debt.balance) == (210 if day > 5 else 320))
	set_meta("kwenta_debug_launch", {"day": 6, "moment": 23, "day3_candy": "credit", "day2": "keep", "day2_haggle": "kind", "day3_berting_resolution": "deny"})
	change_scene_to_file("res://scenes/main.tscn")
	await create_timer(0.5).timeout
	main = current_scene
	assert(main.story.get_choice("day3_berting_resolution") == "deny")
	assert(main.story.get_choice("day2_haggle") == "kind")
	assert(main.story.get_day_callback_beats(6).any(func(beat): return str(beat.get("text", "")).contains("dagdag kang tip")))
	assert(main.story_beats.size() == 4 and main.campaign.has_debt("paolo"))
	main.bubble.advanced.emit()
	main.bubble.advanced.emit()
	assert(not main.campaign.has_debt("paolo") and main.campaign.cash == 1503)
	main._show_current_story_beat()
	assert(main.campaign.cash == 1503)
	print("Debug briefing delivery and past debt reconstruction passed")
	quit()
