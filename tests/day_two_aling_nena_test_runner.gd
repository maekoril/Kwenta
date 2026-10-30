extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for prior_choice in ["stay", "play"]:
		for accepted in [false, true]:
			await _check_visit(prior_choice, accepted)
	print("Day 2 Aling Nena order, haggle, payment, and callback checks passed")
	quit()

func _check_visit(prior_choice: String, accepted: bool) -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	main.prologue_background.visible = false
	main.campaign.day = 2
	assert(main.story.record_choice("day1_play", prior_choice))
	main._rebuild_product_shelf()
	main.story_events.begin_shift(2)
	main.shift.start_shift()
	var customer = main.shift.get_active_customers()[0]
	assert(customer.customer_id == "aling_nena")
	assert(customer.order.requested == {"chips": 1})
	assert(main.story_events.is_active() and main.shift.frozen)
	var original_beat_index: int = main.story_beat_index
	while main.story_events._mode == "beats":
		main.bubble.advanced.emit()
		assert(main.story_beat_index == original_beat_index)
	await create_timer(0.3).timeout
	assert(not main.story_events.is_active() and not main.shift.frozen)
	assert(main.products_by_id["chips"].display_name == "Patos" and main.products_by_id["chips"].price == 18)
	customer.exact_pay = true
	var start_cash: int = main.campaign.cash
	var discount: int = main.shift.haggle_asks["aling_nena"]
	assert(discount == (1 if prior_choice == "stay" else 4))
	main.shift.deliver_product(customer.instance_id, "chips")
	assert(customer.parked and main.story_events.is_active())
	main.bubble.choice_made.emit(0 if accepted else 1)
	assert(main.shift.customers_served == 1)
	assert(main.campaign.cash == start_cash + 18 - (discount if accepted else 0))
	assert(main.story.get_choice("day2_haggle") == ("kind" if accepted else "full"))
	assert(main.story.get_day_choices(2).is_empty()) # Berting's choice follows his scene.
	var callbacks = main.story.get_day_callback_beats(6)
	assert(callbacks.any(func(beat): return beat.text.contains("dagdag kang tip")) == accepted)
	main.queue_free()
	await process_frame

