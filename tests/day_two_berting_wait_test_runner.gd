extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	main.prologue_background.visible = false
	main.campaign.day = 2
	main._rebuild_product_shelf()
	main._begin_shift()
	main.store_sign_tween.kill()
	main._after_opening_sign()
	main.customer_story_button.pressed.emit()
	while main.story_events._mode == "beats":
		main.bubble.advanced.emit()
	await create_timer(0.3).timeout
	var customer: CustomerState = main.shift.get_active_customers()[0]
	customer.tutorial_protected = false
	customer.begin_payment(18, 20, 60.0)
	main.day_two_sukli_tutorial_complete = true
	main._on_payment_tapped(customer.instance_id)
	assert(main.cash_tray.is_open())
	main.story_events._on_game_minutes(120)
	await process_frame
	assert(main.shift.story_waiting_for_clear and not main.shift.frozen)
	assert(not main.story_events.is_active() and main.cash_tray.is_open())
	var before: float = main.shift.elapsed_seconds
	var patience: float = customer.patience_remaining
	main.shift.advance_time(1.0)
	assert(main.shift.elapsed_seconds > before and customer.patience_remaining < patience)
	assert(main.shift.get_active_customers().size() == 1)
	main._on_change_given(customer.instance_id, 2)
	await process_frame
	assert(not main.cash_tray.is_open() and main.story_events.is_active())
	assert(main.story_events._mode == "visitor" and main.shift.frozen)
	await create_timer(0.7).timeout
	# Starting a scene never clears an unrelated customer from the manager.
	var remaining := CustomerState.new("test_customer", OrderState.new({"chips": 1}), 60.0)
	remaining.instance_id = "test_customer"
	main.shift.active_customers.append(remaining)
	main.story_events.find_child("StoryVisitorButton", true, false).pressed.emit()
	assert(main.shift.get_active_customers().has(remaining))
	assert(main.story_events._mode == "beats")
	print("Berting waits for customers and sukli; story tap preserves customers")
	quit()
