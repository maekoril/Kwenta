extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var config = load("res://data/story/summer_campaign.tres")
	var state := CampaignState.new(config)
	state.day = 5
	assert(state.is_suki("neighbor_rosa"))
	assert(not state.is_suki("paolo"))
	state.record_completed_sale("paolo")
	state.record_completed_sale("paolo")
	assert(not state.is_suki("paolo"))
	state.record_completed_sale("paolo")
	assert(not state.is_suki("paolo"))
	state.record_completed_sale("paolo")
	assert(not state.is_suki("paolo"))
	state.record_completed_sale("paolo")
	assert(state.is_suki("paolo") and is_equal_approx(state.credit_rate("paolo"), 0.03))
	var restored := CampaignState.new(config)
	restored.from_dict(state.to_dict())
	assert(restored.is_suki("paolo") and restored.purchase_counts["paolo"] == 5)
	var legacy := CampaignState.new(config)
	legacy.from_dict({"paid_purchases": {"paolo": 3}})
	assert(legacy.completed_customers.has("paolo"))
	assert(not legacy.is_suki("paolo") and legacy.purchase_counts["paolo"] == 1)
	config.customer_ids.assign(["aling_nena"])
	var products := {}
	for product in config.product_catalog: products[product.id] = product
	var shift := ShiftManager.new(restored, products, RandomNumberGenerator.new())
	shift.start_shift(false)
	shift._spawn_customer()
	assert(shift.active_customers.size() == 1)
	var customer: CustomerState = shift.active_customers[0]
	assert(customer.customer_id == "aling_nena" and customer.is_suki)
	var goal := DailyGoal.new(5)
	goal.record_customer_served(1, "aling_nena", false)
	assert(goal.current == 0)
	goal.record_customer_served(1, "aling_nena", true)
	goal.record_customer_served(1, "aling_nena", true)
	assert(goal.current == 1)
	goal.record_customer_served(1, "paolo", true)
	goal.record_customer_served(1, "bea", true)
	assert(goal.is_complete())
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.campaign.day = 5
	main.campaign.completed_customers["aling_nena"] = true
	main.shift.start_shift(false)
	main.shift.credit_requested_today = true
	main.shift._spawn_customer()
	await create_timer(1.0).timeout
	assert(main.tutorial_step == main.TutorialStep.DAY5_SUKI and main.shift.frozen)
	var suki_actor = main.customer_actors.values()[0]
	assert(suki_actor.name_label.text == "Aling Nena")
	assert(suki_actor.name_label.get_theme_color("font_color") == Color("ffe17d"))
	main._skip_day_one_tutorial()
	assert(main.tutorial_step == main.TutorialStep.NONE and not main.shift.frozen)
	main.queue_free()
	await process_frame
	print("Suki identification, save migration, spawn priority and distinct goal passed")
	quit()
