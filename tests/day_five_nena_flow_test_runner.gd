extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("kwenta_debug_launch", {"day": 5, "moment": 15, "skip_tutorials": true})
	change_scene_to_file("res://scenes/main.tscn")
	await create_timer(1.6).timeout
	var main = current_scene
	assert(main.story_events._mode == "customer_visitor")
	var rosa: CustomerState = main.shift.active_customers[0]
	assert(rosa.customer_id == "neighbor_rosa" and rosa.story_arrival_pending)
	var initial_cash: int = main.campaign.cash
	main.story_events.tap_customer_story(rosa.instance_id)
	while main.story_events._mode == "beats": main.bubble.advanced.emit()
	await create_timer(0.3).timeout
	assert(not rosa.story_arrival_pending and not main.shift.frozen)
	assert(main.story.get_choice("day5_debt") == "installments")
	assert(main.shift.debt_payments_received == 110 and main.shift.shift_earnings == 0)
	assert(main.campaign.cash == initial_cash + 110)
	main.shift.deliver_product(rosa.instance_id, "biscuits")
	if rosa.is_paying(): main.shift.give_change(rosa.instance_id, rosa.payment.change_due())
	await create_timer(0.3).timeout
	assert(not main.shift.active_customers.has(rosa))
	assert(main.campaign.cash == initial_cash + 110 + main.shift.shift_earnings)
	var outro: Array = main.story.get_day_outro_beats(5)
	assert(outro.any(func(beat): return str(beat.get("text", "")).contains("₱210")))
	assert(not outro.any(func(beat): return str(beat.get("text", "")).contains("bawal utang")))
	print("Day 5 Rosa payment before order and accounting passed")
	quit()
