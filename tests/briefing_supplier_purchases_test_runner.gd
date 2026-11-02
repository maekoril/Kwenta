extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	main.campaign.day = 2
	main.campaign.cash = 1000
	# This shelf was bought on a previous day, so it is already owned, not new.
	main.campaign.purchased_store_groups.append("water_shelf")
	main.shop_available = true
	main._on_shelf_shop_purchase_requested("hanging_strip", 150)
	main._on_shelf_shop_purchase_requested("hanging_strip", 150)
	assert(main.new_purchase_groups_today == ["hanging_strip"])
	var config := StoreConfig.load_config("res://data/store_config.json")
	var briefing := DayBriefing.new(2, DailyGoal.new(2), main.CAMPAIGN_CONFIG.product_catalog, config, main.new_purchase_groups_today)
	for name in ["Patos", "Zesty", "Kapeko Blanca", "Champ Powder", "Clean", "Rizz-Up Toothpaste"]:
		assert(briefing.unlocked_product_names.has(name))
	assert(not briefing.unlocked_product_names.has("Bato Spring Water"))
	assert(briefing.unlocked_product_names.size() == 6)
	main._show_pre_shift_briefing()
	assert(main.briefing_card._chips.get_child_count() == 6)
	# A second purchase after the briefing opens is reflected when the shop closes.
	main._on_shelf_shop_purchase_requested("oil_shelf", 200)
	main._on_shelf_shop_closed()
	assert(main.briefing_card._chips.get_child_count() == 7)
	main._advance_story_day()
	assert(main.new_purchase_groups_today.is_empty())
	var next_day := DayBriefing.new(3, DailyGoal.new(3), main.CAMPAIGN_CONFIG.product_catalog, config, main.new_purchase_groups_today)
	assert(not next_day.unlocked_product_names.has("Champ Powder"))
	assert(not next_day.unlocked_product_names.has("Golden State Warriors Oil"))
	print("Briefing includes today's purchases, omits older ones, and refreshes after shopping")
	quit()
