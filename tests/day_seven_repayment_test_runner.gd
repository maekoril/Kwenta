extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	set_meta("kwenta_debug_launch", {"day": 7, "moment": 32, "skip_tutorials": true})
	change_scene_to_file("res://scenes/main.tscn")
	await create_timer(1.2).timeout
	var main = current_scene
	assert(main.story_events._mode == "repayment_visitor")
	var balance: int = main.campaign.cash
	var customer = main.story_events._visitor_layer.find_child("StoryVisitorButton", true, false)
	assert(customer != null and not customer.disabled)
	assert(customer.find_child("RepaymentEventMarker", true, false) != null)
	assert(main.story_events._visitor_layer.find_child("RepaymentVisitorTutorial", true, false) == null)
	assert(main.shift.active_customers.is_empty())
	assert(main.campaign.has_debt("neighbor_lina"))
	customer.pressed.emit()
	assert(main.campaign.cash == balance and main.story_events._mode == "choice")
	main.bubble.choice_made.emit(0)
	assert(main.campaign.cash == balance + 107 and not main.campaign.has_debt("neighbor_lina"))
	main.bubble.choice_made.emit(0)
	assert(main.campaign.cash == balance + 107)
	await create_timer(0.3).timeout
	await process_frame
	assert(main.utang_tutorial_message.is_empty() and not main.shift.frozen)
	assert(not main.completed_tutorials.get("utang_repayment", false))
	main._on_utang_tutorial_partial_repayment()
	await process_frame
	assert(main.utang_tutorial_message.is_empty() and not main.shift.frozen)
	# A normal shift may already have a buyer when a real due debtor visits.
	main.campaign.add_debt("day6_purchase", "neighbor_nico", 100, 5, 7)
	main.story_events.begin_shift(7)
	main.shift.start_shift(true)
	assert(main.shift.active_customers.size() == 1)
	assert(main.story_events._mode == "repayment_visitor")
	assert(main.story_events._current.debt.id == "day6_purchase")
	await create_timer(0.7).timeout
	assert(main.story_events._visitor_layer.find_child("RepaymentVisitorTutorial", true, false) == null)
	var buyer: Control = main.customer_actors[main.shift.active_customers[0].instance_id]
	assert(absf(main.story_visitor_portrait.position.x - buyer.position.x) > 144.0)
	print("Day 7 repayment visitor works without a repayment tutorial")
	quit()
