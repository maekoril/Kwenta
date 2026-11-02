extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for approve in [false, true]:
		set_meta("kwenta_debug_launch", {"day": 4, "moment": 30, "skip_tutorials": true})
		change_scene_to_file("res://scenes/main.tscn")
		await create_timer(0.5).timeout
		var main = current_scene
		assert(main.story_events._mode == "credit_visitor")
		assert(main.story_events.credit_panel == null)
		assert(main.tutorial_overlay.visible and main.tutorial_overlay.title.text == "UTANG EVENT")
		assert(main.customer_story_button != null)
		assert(main.customer_story_button.get_node_or_null("UtangEventMarker") != null)
		var customer = main.shift.active_customers[0]
		main.customer_story_button.pressed.emit()
		assert(not main.tutorial_overlay.visible and main.completed_tutorials.get("utang_event", false))
		assert(main.story_events._mode == "beats" and main.story_events.credit_panel == null)
		var spoken_order: String = main.bubble._text.text
		for id in customer.order.requested:
			var product: ProductData = main.shift.products_by_id[id]
			var quantity: int = customer.order.requested[id]
			assert(spoken_order.contains(("isang" if quantity == 1 else "%d na" % quantity) + " " + product.display_name))
		for i in range(3):
			main.bubble.advanced.emit()
		assert(main.story_events._mode == "credit_choice")
		assert(main.story_events.credit_panel.items.get_child_count() == customer.order.requested.size())
		for id in customer.order.requested:
			var product: ProductData = main.shift.products_by_id[id]
			var found := false
			for tile in main.story_events.credit_panel.items.get_children():
				if tile.get_child(2).text == product.display_name and tile.get_child(1).text == "×%d" % int(customer.order.requested[id]): found = true
			assert(found)
		var expected_items: Dictionary = customer.order.requested.duplicate(true)
		var before: int = main.campaign.cash
		main.story_events.credit_panel._decide(approve)
		await create_timer(0.3).timeout
		if approve:
			assert(customer.tutorial_protected)
			for id in customer.order.requested:
				for quantity in range(int(customer.order.requested[id])):
					main.shift.deliver_product(customer.instance_id, id)
			assert(main.campaign.cash == before)
			assert(main.campaign.debts.back().items == expected_items)
		await process_frame
		await process_frame
		assert(main.shift.frozen and not main.utang_tutorial_message.is_empty())
		main.utility_toggle.pressed.emit()
		main._refresh_utility_drawer()
		assert(not main.utility_utang.disabled)
		main.utility_utang.pressed.emit()
		assert(main.utang_ledger.visible)
		main.utang_close.pressed.emit()
		assert(not main.shift.frozen)
	set_meta("kwenta_debug_launch", {"day": 4, "moment": 2, "skip_tutorials": true})
	change_scene_to_file("res://scenes/main.tscn")
	await create_timer(0.5).timeout
	var opening = current_scene
	if opening.store_sign_tween != null and opening.store_sign_tween.is_valid(): opening.store_sign_tween.kill()
	opening._after_opening_sign()
	assert(opening.tutorial_step == opening.TutorialStep.DAY4_UTANG_MENU)
	assert(not opening.story_events.is_active() and opening.shift.active_customers.is_empty())
	opening.utility_toggle.pressed.emit()
	await create_timer(0.1).timeout
	assert(opening.tutorial_step == opening.TutorialStep.DAY4_UTANG_ROW)
	opening.utility_utang.pressed.emit()
	assert(opening.utang_ledger.visible)
	opening.utang_close.pressed.emit()
	opening.shift.story_queue.clear()
	for attempt in range(20):
		opening.shift.active_customers.clear()
		opening.shift._spawn_customer()
		if opening.shift.credit_requested_today: break
	assert(opening.story_events._mode == "credit_visitor")
	set_meta("kwenta_debug_launch", {"day": 5, "moment": 31, "skip_tutorials": true})
	change_scene_to_file("res://scenes/main.tscn")
	await create_timer(0.5).timeout
	var main = current_scene
	assert(main.story_events._current.kind == "repayment")
	var before: int = main.campaign.cash
	main.bubble.choice_made.emit(0)
	await create_timer(0.3).timeout
	await process_frame
	await process_frame
	assert(main.campaign.cash == before + 107)
	assert(main.shift.frozen and not main.utang_tutorial_message.is_empty())
	main.utility_toggle.pressed.emit()
	main._refresh_utility_drawer()
	assert(not main.utility_utang.disabled)
	main.utility_utang.pressed.emit()
	assert(main.utang_ledger.visible)
	print("UTANG TUTORIAL PASS: debug approve, decline, ledger and repayment")
	quit()
