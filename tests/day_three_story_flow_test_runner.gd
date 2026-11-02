extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check_money_intro_branches()
	await check_day_two_money_stays_separate()
	for setup in [
		{"day2": "return", "legacy": "", "option": -1, "cash": 150, "expected": "returned_direct"},
		{"day2": "keep", "legacy": "", "option": 0, "cash": 150, "expected": "returned"},
		{"day2": "keep", "legacy": "", "option": 1, "cash": 150, "expected": "deny"},
		{"day2": "keep", "legacy": "available", "option": 0, "cash": 150, "expected": "returned"},
		{"day2": "keep", "legacy": "available", "option": 0, "cash": 30, "expected": "owe"}
	]:
		await check_day(setup)
	await check_events_at_closing()
	print("Day 3 timed scenes, customer clearing, choices, and legacy cash checks passed")
	quit()

func check_money_intro_branches() -> void:
	var story := StoryProgression.new(load("res://data/story/summer_campaign.tres"))
	var intro := story.get_day_intro_beats(3)
	assert(not intro.any(func(beat): return str(beat.text).contains("₱50")))
	story.choices["day2_overpayment"] = "return"
	intro = story.get_day_intro_beats(3)
	assert(intro.any(func(beat): return str(beat.text).contains("sobre")))
	assert(not intro.any(func(beat): return str(beat.text).contains("lukot")))
	story.choices["day2_overpayment"] = "keep"
	story.choices["day2_money_separate"] = "yes"
	intro = story.get_day_intro_beats(3)
	assert(intro.any(func(beat): return str(beat.text).contains("lukot")))
	assert(not intro.any(func(beat): return str(beat.text).contains("naisama")))
	story.choices.erase("day2_money_separate")
	story.choices["day2_cash_legacy"] = "spent"
	intro = story.get_day_intro_beats(3)
	assert(intro.any(func(beat): return str(beat.text).contains("naisama")))
	assert(not intro.any(func(beat): return str(beat.text).contains("lukot")))

func check_day_two_money_stays_separate() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	main.campaign.day = 2
	main.story.choices["day2_berting_money"] = "seen"
	var choice: Dictionary = main.story.get_day_choices(2)[0]
	var before: int = main.campaign.cash
	main._select_story_choice(choice, "keep")
	assert(main.campaign.cash == before)
	assert(main.story.get_choice("day2_money_separate") == "yes")
	main.queue_free()
	await process_frame

func check_day(setup: Dictionary) -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	main.campaign.day = 3
	main.campaign.cash = setup.cash
	main.story.choices["day1_play"] = "stay"
	main.story.choices["day2_overpayment"] = setup.day2
	if setup.day2 == "keep" and setup.legacy.is_empty():
		main.story.choices["day2_money_separate"] = "yes"
	elif not setup.legacy.is_empty():
		main.story.choices["day2_cash_legacy"] = setup.legacy
	main._rebuild_product_shelf()
	main.story_events.begin_shift(3)
	main.shift.is_running = true
	var customer := CustomerState.new("waiting", OrderState.new({"biscuits": 1}), 30.0)
	customer.instance_id = "waiting"
	main.shift.active_customers.append(customer)
	main.story_events._on_game_minutes(75)
	await process_frame
	assert(main.shift.story_waiting_for_clear and not main.story_events.is_active())
	main.shift.active_customers.clear()
	main.shift.customers_changed.emit()
	await process_frame
	await tap_visitor(main)
	if int(setup.option) >= 0:
		assert(main.story_events._mode == "choice")
		main.bubble.choice_made.emit(setup.option)
		while main.story_events._mode == "beats":
			main.bubble.advanced.emit()
	assert(main.story.get_choice("day3_berting_resolution") == setup.expected)
	var expected_cash: int = int(setup.cash) - (50 if setup.legacy == "available" and setup.cash >= 50 else 0)
	assert(main.campaign.cash == expected_cash)
	await create_timer(0.3).timeout
	for event in [[180, "jun_jun_tara"], [330, "bea"], [450, "paolo"]]:
		main.story_events._on_game_minutes(event[0])
		await process_frame
		assert(main.story_events._mode == "visitor")
		assert(main.story_events._current.event.visitor == event[1])
		await tap_visitor(main)
		if main.story_events._mode == "choice":
			main.bubble.choice_made.emit(0)
			while main.story_events._mode == "beats":
				main.bubble.advanced.emit()
		await create_timer(0.3).timeout
	assert(main.story.get_choice("day3_friends") == "later")
	assert(main.story.get_choice("day3_candy") == "credit")
	assert(main.campaign.cash == expected_cash + 12 and main.shift.shift_earnings == 12)
	assert(not main.story_events.is_active())
	main.queue_free()
	await process_frame

func tap_visitor(main: Node) -> void:
	assert(main.story_events._mode == "visitor")
	main.story_visitor_entrance.kill()
	main.story_events.visitor_entrance_finished.emit()
	main.story_events.find_child("StoryVisitorButton", true, false).pressed.emit()
	while main.story_events._mode == "beats":
		main.bubble.advanced.emit()

func check_events_at_closing() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	main.campaign.day = 3
	main.story_events.begin_shift(3)
	main.shift.is_running = true
	main.shift.shift_duration_seconds = 1.0
	main.shift.shift_close_minutes = 600
	main.shift.advance_time(1.0)
	assert(main.shift.is_closing and main.shift.is_running and main.shift.story_waiting_for_clear)
	await process_frame
	for visitor in ["jun_jun_tara", "bea", "paolo"]:
		assert(main.story_events._current.event.visitor == visitor)
		await tap_visitor(main)
		if main.story_events._mode == "choice":
			main.bubble.choice_made.emit(0)
			while main.story_events._mode == "beats":
				main.bubble.advanced.emit()
		await create_timer(0.3).timeout
		if visitor != "paolo":
			assert(main.shift.is_running)
	main.shift.advance_time(0.1)
	assert(not main.shift.is_running)
	main.queue_free()
	await process_frame
