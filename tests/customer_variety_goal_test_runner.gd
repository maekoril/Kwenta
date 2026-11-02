extends SceneTree

func _initialize() -> void:
	var config: CampaignConfig = load("res://data/story/summer_campaign.tres")
	var campaign := CampaignState.new(config)
	campaign.day = 3
	var random := RandomNumberGenerator.new()
	random.seed = 42
	var shift := ShiftManager.new(campaign, {}, random)
	var goal := DailyGoal.new(3)
	shift.customer_served.connect(func(_id: String, types: int) -> void: goal.record_customer_served(types))
	_sale(shift, {"instant_noodles": 2})
	assert(goal.current == 0, "Two units of one product must not count")
	_sale(shift, {"instant_noodles": 1, "egg": 1})
	assert(goal.current == 1, "Two different products must count")
	_sale(shift, {"instant_noodles": 2, "egg": 1})
	assert(goal.current == 2, "Different products still count when one has multiple units")
	var neighbors := ["neighbor_lina", "neighbor_rosa", "neighbor_nico", "neighbor_ramon"]
	for id in neighbors:
		assert(config.customer_ids.has(id))
		assert(CounterArt.customer_portrait(id, null) != null)
	shift.reserved_story_ids.append("mang_berting")
	for i in range(100):
		var id := shift._choose_customer_id()
		assert(id != "mang_berting" and not shift.recent_customer_ids.has(id))
		shift.recent_customer_ids.append(id)
		if shift.recent_customer_ids.size() > 2:
			shift.recent_customer_ids.pop_front()
	print("Multi-product goal and customer variety passed")
	quit()

func _sale(shift: ShiftManager, items: Dictionary) -> void:
	var order := OrderState.new(items)
	order.delivered = items.duplicate()
	var customer := CustomerState.new("test", order, 60.0)
	shift.active_customers.append(customer)
	shift._finish_sale(customer, 0)
