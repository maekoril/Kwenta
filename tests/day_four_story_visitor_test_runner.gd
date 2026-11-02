extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	main.campaign.day = 4
	main.story_events._visitor_tutorial_seen = true
	assert(not main.story.get_day_intro_beats(4).any(func(beat): return beat.get("speaker") == "Kuya Dodong"))
	main.story_events.begin_shift(4)
	main.shift.is_running = true
	main.story_events._on_game_minutes(1)
	await process_frame
	assert(main.story_events._mode == "visitor" and main.shift.frozen)
	assert(main.story_events._current.event.visitor == "kuya_dodong_soaked")
	main.story_visitor_entrance.kill()
	main.story_events.visitor_entrance_finished.emit()
	await process_frame
	main.story_events.find_child("StoryVisitorButton", true, false).pressed.emit()
	assert(main.shift.reserved_story_ids.has("kuya_dodong"))
	while main.story_events._mode == "beats":
		main.bubble.advanced.emit()
	await create_timer(0.3).timeout
	assert(not main.shift.frozen)
	var waiting := CustomerState.new("waiting", OrderState.new({"biscuits": 1}), 30.0)
	waiting.instance_id = "waiting"
	main.shift.active_customers.append(waiting)
	main.story_events._on_game_minutes(300)
	await process_frame
	assert(main.shift.story_waiting_for_clear and not main.shift.frozen)
	assert(main.shift.active_customers.has(waiting) and not main.story_events.is_active())
	main.shift.active_customers.erase(waiting)
	main.shift.customers_changed.emit()
	await process_frame
	assert(main.story_events._mode == "visitor" and main.shift.frozen)
	assert(main.story_events._current.event.visitor == "jun_jun_tara")
	assert(main.story_visitor_portrait.get_node_or_null("Friend_mikay") != null)
	assert(main.story_visitor_portrait.get_node_or_null("Friend_bogs") != null)
	var button: Button = main.story_events.find_child("StoryVisitorButton", true, false)
	assert(button != null and button.disabled)
	main.story_visitor_entrance.kill()
	main.story_events.visitor_entrance_finished.emit()
	await process_frame
	button.pressed.emit()
	assert(main.shift.reserved_story_ids.has("jun_jun"))
	while main.story_events._mode == "beats":
		main.bubble.advanced.emit()
	assert(main.story_events._mode == "choice")
	main.bubble.choice_made.emit(1)
	while main.story_events._mode == "beats":
		main.bubble.advanced.emit()
	await create_timer(0.3).timeout
	assert(main.story.get_choice("day4_rain") == "stay")
	assert(main.shift.is_running)
	assert(main.shift.reserved_story_ids.has("neighbor_lina"))
	await process_frame
	assert(main.story_events._mode == "customer_visitor")
	var lina: CustomerState = main.shift.active_customers[0]
	assert(lina.customer_id == "neighbor_lina" and lina.story_arrival_pending)
	main.story_events.tap_customer_story(lina.instance_id)
	while main.story_events._mode == "beats":
		main.bubble.advanced.emit()
	await create_timer(0.3).timeout
	assert(not lina.story_arrival_pending and main.shift.active_customers.has(lina))
	var prior_sales: int = main.shift.shift_earnings
	main.shift.deliver_product(lina.instance_id, "biscuits")
	if lina.is_paying():
		main.shift.give_change(lina.instance_id, lina.payment.change_due())
	assert(not main.shift.active_customers.has(lina) and main.shift.shift_earnings > prior_sales)
	for attempt in range(100):
		assert(main.shift._choose_customer_id() not in ["kuya_dodong", "jun_jun", "neighbor_lina"])
	assert(main.story.get_day_choices(4).is_empty())
	assert(main.story.get_day_shift_events(5).any(func(event): return event.get("visitor") == "kuya_dodong"))
	var day4_event: Dictionary = main.story.get_day_shift_events(4).filter(func(event): return event.get("visitor") == "jun_jun_tara")[0]
	var stay_beats: Array = main.story.get_choice_response(day4_event.choice, "stay")
	assert(stay_beats.any(func(beat): return beat.get("speaker") == "Jun-jun"))
	assert(not stay_beats.any(func(beat): return beat.get("speaker") == "Bogs"))
	assert(main.story.get_day_intro_beats(5).any(func(beat): return str(beat.get("text", "")).contains("naglaro sa ulan kahapon")))
	assert(not main.story.get_day_intro_beats(5).any(func(beat): return str(beat.get("text", "")).contains("Hindi man lang inaya")))
	main.story.choices["day4_rain"] = "shelter"
	assert(not main.story.get_day_shift_events(5).any(func(event): return event.get("visitor") == "neighbor_lina"))
	var shelter_event: Dictionary = main.story.get_day_shift_events(4).filter(func(event): return event.get("visitor") == "jun_jun_tara")[0]
	var shelter_beats: Array = main.story.get_choice_response(shelter_event.choice, "shelter")
	assert(shelter_beats.any(func(beat): return str(beat.get("text", "")).contains("Bogs")))
	assert(shelter_beats.any(func(beat): return beat.get("speaker") == "Bogs"))
	assert(shelter_beats.any(func(beat): return str(beat.get("text", "")).contains("isang pack ng Feeta")))
	assert(not shelter_beats.any(func(beat): return str(beat.get("text", "")).contains("utang")))
	assert(not main.story.get_day_intro_beats(5).any(func(beat): return str(beat.get("text", "")).contains("Tatlong biscuit")))
	main.story.choices["day4_rain"] = "join"
	var join_event: Dictionary = main.story.get_day_shift_events(4).filter(func(event): return event.get("visitor") == "jun_jun_tara")[0]
	var join_beats: Array = main.story.get_choice_response(join_event.choice, "join")
	assert(join_beats.any(func(beat): return beat.get("speaker") == "Aling Lina"))
	assert(join_beats.any(func(beat): return beat.get("show_prop") == "alfa_save_corner"))
	assert(not join_beats.any(func(beat): return str(beat.get("text", "")).contains("order ni Aling Nena")))
	assert(main.story.get_day_shift_events(5).any(func(event): return event.get("visitor") == "neighbor_lina"))
	assert(main.story.get_day_haggles(5).all(func(entry): return not str(entry.get("text", "")).contains("Basa lahat")))
	main.campaign.day = 5
	main.story_events.begin_shift(5)
	main.story_events._timed = main.story_events._timed.filter(func(event): return event.get("visitor") != "kuya_dodong")
	main.shift.active_customers.clear()
	main.shift.is_running = true
	main.story_events._on_game_minutes(120)
	await process_frame
	assert(main.story_events._mode == "visitor" and main.shift.frozen)
	assert(main.story_events._current.event.visitor == "neighbor_lina")
	assert(main.story_visitor_portrait.texture == null or main.story_visitor_portrait.texture.atlas == CounterArt.NEIGHBOR_PORTRAITS["neighbor_lina"])
	var cash_before: int = main.campaign.cash
	main.story_visitor_entrance.kill()
	main.story_events.visitor_entrance_finished.emit()
	await process_frame
	main.story_events.find_child("StoryVisitorButton", true, false).pressed.emit()
	while main.story_events._mode == "beats":
		main.bubble.advanced.emit()
	await create_timer(0.3).timeout
	assert(main.campaign.cash == cash_before and not main.shift.frozen)
	main.campaign.day = 4
	main.story_events.begin_shift(4)
	main.story_events._timed = main.story_events._timed.filter(func(event): return event.get("visitor") != "kuya_dodong_soaked")
	main.shift.is_running = true
	main.shift.active_customers.clear()
	main.story_events._on_game_minutes(300)
	await process_frame
	main.story_visitor_entrance.kill()
	main.story_events.visitor_entrance_finished.emit()
	await process_frame
	main.story_events.find_child("StoryVisitorButton", true, false).pressed.emit()
	while main.story_events._mode == "beats":
		main.bubble.advanced.emit()
	var shelter_cash: int = main.campaign.cash
	main.bubble.choice_made.emit(2)
	var shelter_saw_illustration := false
	while main.story_events._mode == "beats":
		if main.story_illustration.visible:
			shelter_saw_illustration = true
			assert(main.story_illustration.texture.resource_path == "res://assets/story/day4_friends_shelter.png")
		main.bubble.advanced.emit()
	await create_timer(0.3).timeout
	assert(main.story.get_choice("day4_rain") == "shelter")
	assert(shelter_saw_illustration and not main.story_illustration.visible)
	assert(not main.shift.active_customers.any(func(customer): return customer.customer_id == "neighbor_lina"))
	assert(not main.story_events._timed.any(func(event): return event.get("follow_after_choice", false)))
	assert(main.campaign.cash == shelter_cash and not main.shift.frozen)
	main.story_events.begin_shift(4)
	main.story_events._timed = main.story_events._timed.filter(func(event): return event.get("visitor") != "kuya_dodong_soaked")
	main.shift.is_running = true
	main.story_events._on_game_minutes(300)
	await process_frame
	main.story_visitor_entrance.kill()
	main.story_events.visitor_entrance_finished.emit()
	await process_frame
	main.story_events.find_child("StoryVisitorButton", true, false).pressed.emit()
	while main.story_events._mode == "beats":
		main.bubble.advanced.emit()
	main.bubble.choice_made.emit(2)
	while main.story_events._mode == "beats" and not main.story_illustration.visible:
		main.bubble.advanced.emit()
	assert(main.story_illustration.visible)
	main.story_events.suppress()
	assert(not main.story_illustration.visible and not main.shift.frozen)
	for cancel in [false, true]:
		main.campaign.day = 4
		main.story_events.begin_shift(4)
		main.story_events._timed = main.story_events._timed.filter(func(event): return event.get("visitor") != "kuya_dodong_soaked")
		main.shift.is_running = true
		main.shift.active_customers.clear()
		main.story_events._on_game_minutes(300)
		await process_frame
		assert(main.story_events._mode == "visitor")
		main.story_visitor_entrance.kill()
		main.story_events.visitor_entrance_finished.emit()
		await process_frame
		main.story_events.find_child("StoryVisitorButton", true, false).pressed.emit()
		while main.story_events._mode == "beats":
			main.bubble.advanced.emit()
		main.bubble.choice_made.emit(0)
		while main.story_events._mode == "beats" and (not main.story_illustration.visible or not main.story_illustration.texture.resource_path.ends_with("day4_lina_alfa_corner.png")):
			main.bubble.advanced.emit()
		assert(main.story_illustration.visible)
		assert(main.story_illustration.texture.resource_path == "res://assets/story/day4_lina_alfa_corner.png")
		if cancel:
			main.story_events.suppress()
		else:
			while main.story_events._mode == "beats":
				main.bubble.advanced.emit()
			await create_timer(0.3).timeout
		assert(not main.story_illustration.visible and not main.shift.frozen)
	main.queue_free()
	await process_frame
	print("Day 4 visitors arrive and require a tap before dialogue and choice")
	quit()

func check_visitor(main: Node, expected: String) -> void:
	assert(main.story_events._mode == "outro_visitor")
	assert(main.story_visitor_portrait != null)
	assert(main.story_visitor_portrait.texture.region == CounterArt.customer_portrait(expected, main.PORTRAIT_ATLAS).region)
	var button: Button = main.story_events.find_child("StoryVisitorButton", true, false)
	assert(button != null and button.disabled)
	main.story_visitor_entrance.kill()
	main.story_events.visitor_entrance_finished.emit()
	await process_frame
	assert(not button.disabled)
	button.pressed.emit()
	await process_frame
	assert(main.story_events._mode != "outro_visitor")
	assert(main.bubble.visible)
