extends SceneTree

func _initialize() -> void:
	var config: CampaignConfig = load("res://data/story/summer_campaign.tres")
	var state := CampaignState.new(config)
	var shift := ShiftManager.new(state, {}, RandomNumberGenerator.new())
	var names := ["Ate Tess", "Kuya Joel", "Lola Pilar", "Rafi", "Ate Celia", "Mang Nestor"]
	var slot = load("res://scripts/customer_slot.gd").new()
	for i in range(CounterArt.NEW_NEIGHBORS.size()):
		var id: String = CounterArt.NEW_NEIGHBORS[i]
		assert(config.customer_ids.has(id))
		assert(slot._display_name(id) == names[i])
		var portrait := CounterArt.customer_portrait(id, null)
		assert(portrait != null and portrait.region.size == Vector2(512, 512))
		assert(portrait.region.position == Vector2(i % 3, i / 3) * 512)
		# Every new customer is eligible throughout the campaign, including fiesta.
		var roster := config.customer_ids.duplicate()
		config.customer_ids.assign([id])
		for day in range(1, 8):
			state.day = day
			assert(shift._choose_customer_id() == id)
		config.customer_ids.assign(roster)
	# Five product types and multiple units in a visit still count as one purchase.
	for visit in range(5):
		var order := OrderState.new({"egg": 5, "chips": 2, "candy": 3, "biscuits": 1, "soft_drink": 1})
		order.delivered = order.requested.duplicate()
		var customer := CustomerState.new("ate_tess", order, 60.0)
		shift.active_customers.append(customer)
		shift._finish_sale(customer, 0)
		assert(state.purchase_counts["ate_tess"] == visit + 1)
		assert(state.is_suki("ate_tess") == (visit == 4))
		# An accidental second completion callback is still the same visit.
		shift._finish_sale(customer, 0)
		assert(state.purchase_counts["ate_tess"] == visit + 1)
	var restored := CampaignState.new(config)
	restored.from_dict(state.to_dict())
	assert(restored.is_suki("ate_tess") and restored.purchase_counts["ate_tess"] == 5)
	slot.free()
	print("New NPC names, portraits, availability every day and five separate purchase visits passed")
	quit()
