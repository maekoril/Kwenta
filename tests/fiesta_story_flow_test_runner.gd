extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for route in ["ask", "alone"]:
		set_meta("kwenta_debug_launch", {"day": 6, "moment": 24, "skip_tutorials": true, "day6_help": route})
		change_scene_to_file("res://scenes/main.tscn")
		await create_timer(0.7).timeout
		var main = current_scene
		assert(main.day_six_brownout_triggered)
		assert(main.story_events._current.get("kind") == "narrative")
		assert(main.shift.frozen and main.shift.is_running)
		var beats: Array = main.story.filter_story_beats(main.story_events._current.event.beats)
		assert(beats.any(func(beat): return str(beat.get("text", "")).contains("lampara")))
		assert(not beats.any(func(beat): return str(beat.get("text", "")).contains("flashlight")))
		assert(not beats.any(func(beat): return beat.get("speaker") == "Aling Nena"))
		assert(beats.any(func(beat): return str(beat.get("text", "")).contains("Ako na muna sa mga order")) == (route == "alone"))
		assert(beats.any(func(beat): return str(beat.get("text", "")).contains("kwarto ko")))
		assert(beats.any(func(beat): return beat.get("speaker") == "Mikay" and str(beat.get("text", "")).contains("posporo")))
		var reveal_index := -1
		for i in range(beats.size()):
			if beats[i].get("show_prop", "") == "fiesta_lampara": reveal_index = i
		assert(reveal_index > 0 and beats[reveal_index - 1].get("speaker") == "Bogs")
		for i in range(beats.size()):
			assert(main.fiesta_light_props.visible == (i >= reveal_index))
			assert(bool((main.fiesta_emergency_light.material as ShaderMaterial).get_shader_parameter("lights_arrived")) == (i >= reveal_index))
			assert(not main.shift.fiesta_brownout_rush)
			main.bubble.advanced.emit()
		await create_timer(0.3).timeout
		assert(not main.story_events.is_active() and not main.shift.frozen and main.shift.is_running)
		assert(main.fiesta_emergency_light.visible and main.shift.fiesta_brownout_rush)
		assert(main.fiesta_light_props.visible)
		assert((main.fiesta_emergency_light.material as ShaderMaterial).get_shader_parameter("lights_arrived"))
		assert(is_equal_approx(main.shift._next_spawn_delay(), 5.0))
		assert(is_equal_approx(main.shift.current_spawn_delay, 5.0))
		assert(main.shift._active_customer_limit() == 3)
		assert(main.shift.fiesta_route == route)
		var visits: Array = main.story.get_day_shift_events(6).filter(func(event): return event.get("customer") == "neighbor_ramon")
		assert(visits.size() == 1 and int(visits[0].at_minute) > 630)
		var ramon: Dictionary = visits[0]
		assert(ramon.get("story_visitor") and ramon.get("wait_for_clear") and ramon.order.has("instant_noodles"))
		var arrival: Array = main.story.filter_story_beats(ramon.arrival_beats)
		assert(arrival.any(func(beat): return str(beat.get("text", "")).contains("Alfa-Save")))
		assert(arrival.any(func(beat): return str(beat.get("text", "")).contains("kaibigan")))
		main.apply_environment(1)
		assert(not main.fiesta_light_props.visible and not main.fiesta_emergency_light.visible)
		var day7: Array = main.story.get_day_callback_beats(7)
		assert(day7.any(func(beat): return str(beat.get("text", "")).contains("Ikaw pala ang humawak")) == (route == "alone"))
	var story = current_scene.story
	for choice in ["credit", "free", "no"]:
		story.choices["day3_candy"] = choice
		var events: Array = story.get_day_shift_events(6)
		assert(events.any(func(event): return event.get("visitor") == "paolo_repayment") == (choice == "credit"))
		assert(events.any(func(event): return event.get("customer") == "classmate_1") == (choice == "free"))
		var paolo: Array = events.filter(func(event): return event.get("customer") == "paolo")
		assert(paolo.size() == (1 if choice == "no" else 0))
		if not paolo.is_empty(): assert(paolo[0].order.has("soft_drink"))
	# The event pauses existing customers rather than making them abandon the queue.
	set_meta("kwenta_debug_launch", {"day": 6, "moment": 1, "skip_tutorials": true, "day6_help": "alone"})
	change_scene_to_file("res://scenes/main.tscn")
	await create_timer(0.5).timeout
	var main = current_scene
	# A full counter holds arrivals, but does not discard the time already waited.
	var pacing := ShiftManager.new(main.campaign, main.products_by_id, RandomNumberGenerator.new())
	pacing.start_shift(false)
	pacing.credit_requested_today = true
	pacing.start_fiesta_brownout_rush()
	for i in range(3):
		var waiting := CustomerState.new("pacing_%d" % i, OrderState.new({"instant_noodles": 1}), 100.0)
		waiting.instance_id = "pacing_%d" % i
		waiting.exact_pay = true
		pacing.active_customers.append(waiting)
	pacing.advance_time(3.0)
	assert(pacing.active_customers.size() == 3 and is_equal_approx(pacing.spawn_elapsed, 3.0))
	pacing.deliver_product("pacing_0", "instant_noodles")
	assert(is_equal_approx(pacing.spawn_elapsed, 3.0))
	pacing.advance_time(2.0)
	assert(pacing.active_customers.size() == 3)
	pacing.advance_time(5.0)
	assert(pacing.active_customers.size() == 3 and is_equal_approx(pacing.spawn_elapsed, 5.0))
	pacing.deliver_product("pacing_1", "instant_noodles")
	pacing.advance_time(0.01)
	assert(pacing.active_customers.size() == 3)
	main.shift.fiesta_route = "alone"
	main.story_events.begin_shift(6)
	main.shift.start_shift(false)
	var customer := CustomerState.new("test", OrderState.new({"candy": 1}), 25.0)
	main.shift.active_customers.append(customer)
	var brownouts: Array = main.story.get_day_shift_events(6).filter(func(event): return event.get("visitor") == "fiesta_brownout")
	assert(brownouts.size() == 1 and int(brownouts[0].get("at_minute")) == 630)
	main.story_events._on_game_minutes(630)
	assert(main.story_events._current.get("kind") == "narrative" and main.shift.frozen)
	var patience := customer.patience_remaining
	main.shift.advance_time(10.0)
	assert(customer.patience_remaining == patience and main.shift.active_customers.has(customer))
	while main.story_events._mode == "beats": main.bubble.advanced.emit()
	await create_timer(0.3).timeout
	assert(not main.shift.frozen and main.shift.active_customers.has(customer))
	main.story_events._on_game_minutes(631)
	assert(main.shift.story_waiting_for_clear and not main.story_events._waiting_scene.is_empty())
	main.story_events._try_start_waiting_scene()
	assert(main.shift.active_customers.has(customer) and main.shift.story_queue.is_empty())
	main.shift.active_customers.clear()
	main.story_events._try_start_waiting_scene()
	assert(not main.shift.story_waiting_for_clear)
	assert(main.shift.active_customers.size() == 1 and main.shift.active_customers[0].customer_id == "neighbor_ramon")
	assert(main.shift.frozen and main.story_events._current.get("kind") == "customer_visitor")
	print("Fiesta brownout routes, resumption and Paolo branches passed")
	quit()
