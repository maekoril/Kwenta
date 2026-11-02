extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var config = load("res://data/story/summer_campaign.tres")
	var state := CampaignState.new(config)
	state.day = 4
	var products := {}
	for product in config.product_catalog: products[product.id] = product
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var shift := ShiftManager.new(state, products, rng)
	state.record_purchase("neighbor_lina", 150)
	assert(is_equal_approx(state.credit_rate("neighbor_lina"), 0.015))
	assert(is_equal_approx(state.credit_rate("new"), 0.07))
	var customer := CustomerState.new("neighbor_lina", OrderState.new(), 100)
	customer.instance_id = "test"
	shift._prepare_credit(customer)
	assert(customer.credit_offer.principal >= 100 and customer.credit_offer.principal <= 150)
	shift.active_customers.append(customer)
	shift.resolve_credit("test", true)
	var before := state.cash
	for id in customer.order.requested:
		for unit in range(customer.order.requested[id]): shift.deliver_product("test", id)
	assert(state.cash == before)
	assert(state.has_debt("neighbor_lina"))
	assert(state.paid_purchases.neighbor_lina == 150)
	assert(shift.shift_earnings == 0)
	var debt: Dictionary = state.debts.back()
	assert(debt.due_day == 5)
	var restored := CampaignState.new(config)
	restored.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert(restored.has_debt("neighbor_lina"))
	assert(restored.paid_purchases.neighbor_lina == 150)
	assert(restored.repay_debt(debt.id, 999) == debt.principal + debt.interest)
	assert(restored.repay_debt(debt.id, 999) == 0)
	assert(not restored.has_debt("neighbor_lina"))
	assert(restored.paid_purchases.neighbor_lina == 150 + debt.principal)
	var paid_customer := CustomerState.new("cash_buyer", OrderState.new({"biscuits": 1}), 100)
	paid_customer.instance_id = "paid"
	paid_customer.exact_pay = true
	shift.active_customers.append(paid_customer)
	shift.deliver_product("paid", "biscuits")
	assert(state.paid_purchases.cash_buyer == state.get_product_price(products.biscuits))
	for day in [3, 7]:
		state.day = day
		shift.credit_requested_today = false
		for attempt in range(100):
			shift.active_customers.clear()
			shift._spawn_customer()
			assert(shift.active_customers[0].credit_offer.is_empty())
	state.day = 4
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	main.campaign.from_dict(state.to_dict())
	main.campaign.day = 5
	main.story_events.begin_shift(5)
	main.shift.start_shift()
	assert(main.story_events._current.kind == "repayment")
	main.bubble.choice_made.emit(0)
	assert(not main.campaign.has_debt("neighbor_lina"))
	assert(main.shift.debt_payments_received == debt.principal + debt.interest)
	assert(main.shift.shift_earnings == 0)
	await create_timer(0.3).timeout
	main.story_events.suppress()
	var borrower := CustomerState.new("neighbor_nico", OrderState.new(), 100)
	borrower.instance_id = "offer_test"
	main.shift._prepare_credit(borrower)
	main.shift.active_customers.append(borrower)
	main.story_events._on_credit_requested("offer_test")
	assert(main.story_events._mode == "credit_choice")
	var offer_panel = main.story_events.credit_panel
	assert(offer_panel.items.get_child_count() == borrower.order.requested.size())
	assert(not offer_panel.details.visible)
	offer_panel.details_button.pressed.emit()
	assert(offer_panel.details.visible)
	await process_frame
	for viewport_size in [Vector2i(1920, 1080), Vector2i(2400, 1080), Vector2i(1280, 720)]:
		offer_panel.size = Vector2(viewport_size)
		offer_panel._layout()
		await process_frame
		assert(Rect2(Vector2.ZERO, offer_panel.size).encloses(Rect2(offer_panel.card.position, offer_panel.card.size * offer_panel.card.scale)))
	for tile in offer_panel.items.get_children():
		assert(tile.get_child(0).texture != null)

	var trust: float = borrower.trust
	offer_panel.decline_button.pressed.emit()
	assert(not main.shift.active_customers.has(borrower))
	assert(borrower.trust == trust)
	await create_timer(0.3).timeout
	main.shift.active_customers.append(borrower)
	borrower.active = true
	borrower.story_arrival_pending = true
	main.story_events._on_credit_requested("offer_test")
	var approved_panel = main.story_events.credit_panel
	approved_panel.approve_button.pressed.emit()
	assert(borrower.credit_approved)
	assert(not borrower.story_arrival_pending)
	assert(main.story_events.credit_panel == null)
	approved_panel._decide(false)
	assert(borrower.credit_approved)

	main.utang_ledger.show_records(main.campaign, false, false)
	assert(main.utang_ledger.records.size() >= 4)
	main.campaign.day = 4
	main.utang_ledger.show_records(main.campaign, false, false)
	assert(not main.utang_ledger.records.any(func(row): return row[1] == "Lola Rosa"))
	main.queue_free()
	await process_frame
	print("UTANG PASS: terms, delayed income, persistence, idempotent repayment, scheduled visit, decline and ledger")
	quit()
