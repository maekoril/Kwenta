extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for previous in ["stay", "play"]:
		for accept in [false, true]:
			await check_flow(previous, accept)
	print("Day 2 prearrival, haggle and sukli guide passed for both branches")
	quit()
func check_flow(previous: String, accept: bool) -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	main.prologue_background.visible = false
	main.campaign.day = 2
	main.story.record_choice("day1_play", previous)
	main._rebuild_product_shelf()
	main._begin_shift()
	main.store_sign_tween.kill()
	main._after_opening_sign()
	assert(main.shift.is_running and main.shift.frozen)
	var customer = main.shift.get_active_customers()[0]
	assert(customer.customer_id == "aling_nena" and customer.order.requested == {"chips": 1})
	var actor = main.customer_actors[customer.instance_id]
	assert(customer.story_arrival_pending and not actor.order_bubble.visible)
	assert(main.story_events._mode == "customer_visitor" and is_instance_valid(main.customer_story_button))
	assert(customer.receive_product("chips") == CustomerState.DeliveryResult.INACTIVE)
	main.customer_story_button.pressed.emit()
	assert(main.story_events._mode == "beats")
	assert(main.bubble._text.text.contains("sipag") if previous == "stay" else main.bubble._text.text.contains("tumatakbo"))
	while main.story_events._mode == "beats":
		main.bubble.advanced.emit()
	await create_timer(0.35).timeout
	assert(not main.story_events.is_active() and not customer.story_arrival_pending)
	assert(main.customer_actors[customer.instance_id] == actor and actor.order_bubble.visible)
	var patience_before: float = customer.patience_remaining
	assert(customer.tutorial_protected and not customer.advance_time(1000.0))
	assert(customer.patience_remaining == patience_before)
	main._resolve_product_delivery(customer.instance_id, "chips")
	assert(main.story_events.is_active() and customer.parked)
	main.bubble.choice_made.emit(0 if accept else 1)
	assert(customer.is_paying() and customer.payment.tendered == 20)
	var payment_lines: Array[String] = []
	while main.story_events._mode == "beats":
		payment_lines.append(main.bubble._text.text)
		await process_frame
		assert(not main.tutorial_overlay.visible and main.shift.frozen)
		main.bubble.advanced.emit()
	assert(payment_lines.size() == 5) # Haggle reaction, then four payment beats.
	assert(payment_lines[1].contains("bente") and payment_lines[2].contains("sobra"))
	assert(payment_lines[3].contains("sukli") and payment_lines[4].contains("Bilangin"))
	await create_timer(0.35).timeout
	assert(not main.story_events.is_active())
	var before: float = customer.patience_remaining
	assert(main.tutorial_step == main.TutorialStep.DAY2_CUSTOMER)
	assert(main.tutorial_overlay.visible)
	assert(main.tutorial_customer_id == customer.instance_id)
	main._update_day_two_customer_sukli_target()
	var expected_target = main._tutorial_rect_for(actor).merge(main._tutorial_rect_for(actor.order_bubble)).grow(18.0).intersection(Rect2(Vector2.ZERO, main.tutorial_overlay.size))
	assert(main.tutorial_overlay.spotlight_rect.is_equal_approx(expected_target))
	main._process(5.0)
	assert(customer.patience_remaining == before)
	actor.payment_tapped.emit(customer.instance_id)
	assert(main.tutorial_step == main.TutorialStep.DAY2_MONEY)
	main._process(5.0)
	assert(customer.patience_remaining == before)
	await create_timer(0.5).timeout
	assert(main.tutorial_overlay.visible and main.tutorial_sukli_ready)
	main.cash_tray.close()
	await create_timer(0.35).timeout
	assert(main.tutorial_step == main.TutorialStep.DAY2_CUSTOMER and main.tutorial_overlay.visible)
	actor.payment_tapped.emit(customer.instance_id)
	await create_timer(0.5).timeout
	assert(main.tutorial_step == main.TutorialStep.DAY2_MONEY and main.tutorial_overlay.visible)
	while main.cash_tray.get_selected_total() < customer.payment.change_due():
		var remaining = customer.payment.change_due() - main.cash_tray.get_selected_total()
		var denom = main._largest_change_denomination_at_most(remaining)
		var button: Button = main.cash_tray.find_child("Denomination%d" % denom, true, false)
		assert(button != null)
		var expected = main._tutorial_rect_for(button).grow(18.0).intersection(Rect2(Vector2.ZERO, main.tutorial_overlay.size))
		assert(main.tutorial_overlay.spotlight_rect.is_equal_approx(expected))
		main.cash_tray._on_denomination_tapped(denom, button)
	assert(main.tutorial_step == main.TutorialStep.DAY2_GIVE)
	main.cash_tray._on_give_pressed()
	assert(main.day_two_sukli_tutorial_complete and main.tutorial_step == main.TutorialStep.NONE)
	assert(main.story.get_day_choices(2).is_empty())
	main.story_events._on_game_minutes(120)
	await process_frame
	assert(main.story_events.is_active() and main.shift.frozen)
	assert(main.story_events._mode == "visitor" and main.story.get_choice("day2_berting_money") == "")
	await create_timer(0.7).timeout
	var visitor_button = main.story_events.find_child("StoryVisitorButton", true, false)
	var visitor_mark = visitor_button.find_child("StoryEventMarker", true, false)
	assert(visitor_mark != null and is_instance_valid(main.story_visitor_portrait))
	assert(visitor_button.get_global_rect().position.is_equal_approx(main.story_visitor_portrait.global_position))
	assert(main.story_events.find_child("StoryVisitorTutorial", true, false) == null)
	visitor_button.pressed.emit()
	assert(main.story.get_choice("day2_berting_money") == "seen")
	assert(main.story.get_day_choices(2).size() == 1)
	var saw_money := false
	while main.story_events._mode == "beats":
		saw_money = saw_money or (main.story_illustration.visible and main.story_illustration.texture != null and main.story_illustration.texture.resource_path.ends_with("berting_counter_50.png"))
		main.bubble.advanced.emit()
	assert(saw_money and not main.story_illustration.visible)
	await create_timer(0.35).timeout
	assert(not main.story_events.is_active() and not main.shift.frozen)
	main.queue_free()
	await process_frame
