extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func sale(shift: ShiftManager, id: String, bill: int, received: int, credit: bool = false) -> void:
	var customer := CustomerState.new(id, OrderState.new({"biscuits": 1}), 25)
	customer.order.delivered = {"biscuits": 1}
	customer.bill_total = bill
	customer.credit_approved = credit
	shift.active_customers.append(customer)
	shift._finish_sale(customer, received)

func run() -> void:
	var config = load("res://data/story/summer_campaign.tres")
	var state := CampaignState.new(config)
	state.day = 6
	var products := {}
	for product in config.product_catalog: products[product.id] = product
	var shift := ShiftManager.new(state, products, RandomNumberGenerator.new())
	shift.fiesta_route = "alone"
	shift.start_shift()
	shift.active_customers.clear()
	sale(shift, "cash", 100, 105) # tip excluded from bonus basis
	sale(shift, "discount", 80, 80)
	sale(shift, "credit", 120, 0, true)
	state.add_debt("test_due", "borrower", 100, 2, 6)
	state.repay_debt("test_due", 102)
	assert(shift.paid_goods_sales == 180)
	var before := state.cash
	shift.finish_shift()
	assert(shift.fiesta_bonus == 36 and state.cash == before + 36)
	shift.finish_shift()
	assert(state.cash == before + 36)
	shift.fiesta_route = "ask"
	shift.start_shift()
	assert(shift.paid_goods_sales == 0 and shift.fiesta_bonus == 0)
	assert(shift.helper_cooldown == 0)
	shift.active_customers.clear()
	var first := CustomerState.new("first", OrderState.new({"biscuits": 1}), 25)
	first.instance_id = "first"
	first.begin_payment(15, 50, 14)
	var selected := CustomerState.new("selected", OrderState.new({"biscuits": 1}), 25)
	selected.instance_id = "selected"
	selected.bill_total = 15
	selected.begin_payment(15, 20, 14)
	shift.active_customers.append_array([first, selected])
	assert(not shift.use_helper_change("missing"))
	assert(shift.helper_cooldown == 0)
	assert(shift.use_helper_change("selected"))
	assert(first.active and not selected.active)
	assert(shift.total_tips_earned == 0)
	assert(shift.helper_cooldown == 20)
	assert(not shift.use_helper_change("first"))
	shift.frozen = true
	shift.advance_time(5)
	assert(shift.helper_cooldown == 20)
	shift.frozen = false
	shift.active_customers.clear()
	shift.advance_time(20)
	assert(shift.helper_cooldown == 0)
	shift.active_customers.append(first)
	assert(shift.use_helper_change("first"))
	before = state.cash
	shift.finish_shift()
	assert(shift.fiesta_bonus == 0 and state.cash == before)
	shift.fiesta_route = "alone"
	shift.start_shift()
	assert(not shift.use_helper_change("first"))
	var story := StoryProgression.new(config)
	for route in ["ask", "alone"]:
		story.choices["day6_help"] = route
		assert(story.get_day_mixups(6).is_empty())
		assert(story.get_day_modifiers(6).patience_mult == 1.0)
	print("PASS: Fiesta bonus excludes tips, credit and repayments; pays once; helper targets one customer, pauses cooldown, recharges and resets")
	quit()
