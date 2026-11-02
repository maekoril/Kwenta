extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for option in ["ask", "alone"]:
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		main.bubble.close()
		await create_timer(0.3).timeout
		main.campaign.day = 6
		var intro: Array = main.story.get_day_intro_beats(6)
		assert(not intro.any(func(beat): return beat.get("speaker") == "Aling Cora"))
		assert(intro.any(func(beat): return str(beat.get("text", "")).contains("Naalala ni Tonyo")))
		main._rebuild_product_shelf()
		main.story_after_action = "start_shift"
		main._complete_story_beats()
		assert(main.choices_before_shift)
		main._select_story_choice(main.current_choice_data, option)
		var response_count: int = main.story_beats.size()
		for i in range(response_count): main.bubble.advanced.emit()
		assert(main.showing_pre_shift_briefing)
		assert(main.story_after_action.is_empty())
		assert(main.current_choice_ids.is_empty())
		# A queued tap during the close animation must not start end-of-day callbacks.
		for i in range(3): main.bubble.advanced.emit()
		await create_timer(0.35).timeout
		assert(not main.bubble.visible)
		assert(main.campaign.day == 6)
		assert(not main.shift.is_running)
		assert(main.briefing_card.visible)
		main._on_briefing_start_pressed()
		# Skip only the cosmetic opening animation, then use the real start handler.
		if main.store_sign_tween != null and main.store_sign_tween.is_valid(): main.store_sign_tween.kill()
		main._after_opening_sign()
		assert(main.shift.is_running)
		assert(main.campaign.day == 6)
		assert(not main.showing_pre_shift_briefing)
		assert(main.shift.active_customers.size() > 0)
		assert(is_equal_approx(main.shift.patience_seconds_override, 25.0))
		assert(main.shift.mixup_remaining == 0)
		# A late dialogue signal must also be harmless after gameplay has begun.
		main.bubble.advanced.emit()
		assert(main.campaign.day == 6 and main.shift.is_running)
		if main.story_events.credit_panel != null:
			main.story_events.credit_panel.approve_button.pressed.emit()
			await create_timer(0.3).timeout
		main.shift.advance_time(0.5)
		assert(main.shift.elapsed_seconds > 0)
		main._refresh_fiesta_controls()
		assert(main.fiesta_button.visible)
		assert(main.fiesta_friends.visible == (option == "ask"))
		if option == "ask":
			var customer: CustomerState = main.shift.active_customers[0]
			customer.begin_payment(15, 50, 14)
			main._on_payment_tapped(customer.instance_id)
			main._refresh_fiesta_controls()
			assert(not main.fiesta_button.disabled)
			main.fiesta_button.pressed.emit()
			assert(not customer.active)
			assert(not main.cash_tray.is_open())
			assert(main.shift.helper_cooldown > 0)
		else:
			assert(main.fiesta_button.disabled)
			assert(main.fiesta_button.text.contains("20%"))

		main.shift.paid_goods_sales = 500
		main.shift.helper_cooldown = 12
		main.campaign.cash += 100
		main._on_game_over()
		main._retry_current_day()
		assert(main.campaign.cash == main.shift_start_cash)
		assert(main.campaign.day == 6)
		# Restarting uses the same start path and cannot carry prior sales/recharge.
		main._begin_shift()
		if main.store_sign_tween != null and main.store_sign_tween.is_valid(): main.store_sign_tween.kill()
		main._after_opening_sign()
		assert(main.shift.paid_goods_sales == 0)
		assert(main.shift.fiesta_bonus == 0)
		assert(main.shift.helper_cooldown == 0)
		main.queue_free()
		await process_frame
	print("PASS: both Fiesta choices reach briefing and active gameplay; late dialogue taps cannot skip Day 6")
	quit()
