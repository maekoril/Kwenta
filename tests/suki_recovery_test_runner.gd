extends SceneTree

func _initialize() -> void:
	var config = load("res://data/story/summer_campaign.tres")
	var state = CampaignState.new(config)
	state.barangay_trust = 75.0
	var products = {"instant_noodles": load("res://data/products/instant_noodles.tres")}
	var manager = ShiftManager.new(state, products, RandomNumberGenerator.new())
	var updates: Array[float] = []
	manager.barangay_trust_changed.connect(func(value): updates.append(value))
	var customer = CustomerState.new("regular", OrderState.new({"instant_noodles": 1}), 20.0)
	customer.instance_id = "regular_1"
	customer.exact_pay = true
	manager.active_customers.append(customer)
	manager.deliver_product(customer.instance_id, "instant_noodles")
	assert(state.barangay_trust == 77.0 and updates == [77.0])
	manager.deliver_product(customer.instance_id, "instant_noodles")
	assert(state.barangay_trust == 77.0)
	state.barangay_trust = 99.0
	var capped = CustomerState.new("regular", OrderState.new({"instant_noodles": 1}), 20.0)
	capped.instance_id = "regular_2"
	capped.exact_pay = true
	manager.active_customers.append(capped)
	manager.deliver_product(capped.instance_id, "instant_noodles")
	assert(state.barangay_trust == 100.0)
	state.barangay_trust = 70.0
	var late = CustomerState.new("late", OrderState.new({}), 20.0)
	late.instance_id = "late_1"
	late.begin_payment(15, 20, 1.0)
	manager.active_customers.append(late)
	late.advance_time(1.0)
	assert(late.patience_expired)
	manager.give_change(late.instance_id, 0)
	assert(late.patience_remaining > 0.0)
	manager.give_change(late.instance_id, 5)
	assert(state.barangay_trust == 70.0)
	var timely = CustomerState.new("timely", OrderState.new({}), 20.0)
	timely.instance_id = "timely_1"
	timely.begin_payment(15, 20, 10.0)
	manager.active_customers.append(timely)
	manager.give_change(timely.instance_id, 5)
	assert(state.barangay_trust == 72.0)
	state.advance_day()
	assert(state.barangay_trust == 72.0)
	print("Suki recovery, cap, and overdue-payment checks passed")
	quit()
