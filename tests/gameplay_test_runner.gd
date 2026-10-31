extends SceneTree

const OrderStateScript = preload("res://scripts/order_state.gd")
const OrderFactoryScript = preload("res://scripts/order_factory.gd")
const OrderDataScript = preload("res://scripts/order_data.gd")
const CustomerStateScript = preload("res://scripts/customer_state.gd")
const CampaignConfigScript = preload("res://scripts/campaign_config.gd")
const CampaignStateScript = preload("res://scripts/campaign_state.gd")
const ShiftManagerScript = preload("res://scripts/shift_manager.gd")
const ProductDataScript = preload("res://scripts/product_data.gd")
const CampaignFixture = preload("res://data/story/summer_campaign.tres")
const StoryProgressionScript = preload("res://scripts/story_progression.gd")
const CounterArtScript = preload("res://scripts/counter_art.gd")
const StorefrontLayoutScript = preload("res://scripts/storefront_layout.gd")
const OrderBubbleIconScript = preload("res://scripts/order_bubble_icon.gd")
const MainScript = preload("res://scripts/main.gd")
const DailyGoalScript = preload("res://scripts/daily_goal.gd")
const DayBriefingScript = preload("res://scripts/day_briefing.gd")
const NotebookScrollScript = preload("res://scripts/notebook_scroll.gd")
const NotebookSummaryScript = preload("res://scripts/notebook_summary.gd")
const ProductAtlas = preload("res://assets/sprites/kwenta_generic_products.png")
const CustomerPortraitAtlas = preload("res://assets/sprites/customer_portraits_v2.png")

var failures: int = 0
var shift_completion_count: int = 0

func _initialize() -> void:
	_test_order_accepts_requested_units_only()
	_test_wrong_product_does_not_advance_order()
	_test_duplicate_units_require_duplicate_deliveries()
	_test_order_factory_respects_configured_unit_range()
	_test_timeout_reduces_only_the_customers_trust_once()
	_test_wrong_and_partial_deliveries_do_not_pay()
	_test_completed_duplicate_order_pays_exactly_once()
	_test_timed_out_delivery_is_lost_and_late_drop_is_rejected()
	_test_closing_emits_once()
	_test_two_customers_keep_separate_orders_and_capacity()
	_test_campaign_unlocks_and_pacing()
	_test_day_by_day_learning_curve()
	_test_daily_goals_are_optional_and_day_specific()
	_test_day_briefing_explains_the_new_idea_and_goal()
	_test_day_briefing_prioritizes_focus_and_configuration_unlocks()
	_test_notebook_scroll_supports_touch_drag()
	_test_notebook_section_headers_use_compact_action_tags()
	_test_notebook_action_button_uses_ibigay_texture()
	_test_shift_counts_served_and_timed_out_customers_for_summary()
	_test_shelf_purchase_costs_cash_once()
	_test_optional_unlock_costs_cash_once()
	_test_seven_day_story_remembers_choices_and_callbacks()
	_test_counter_sprite_atlases_cover_the_campaign_catalog()
	_test_day_one_store_products_use_branded_sprite_icons()
	_test_order_bubble_icons_fit_their_cells()
	_test_storefront_slots_are_visible_unique_and_non_overlapping()
	_test_product_display_sizes_follow_the_reference()
	_test_product_display_style_matches_the_store()
	_test_day_one_products_have_fixed_shelf_slots()
	_test_customer_positions_fit_the_storefront()
	_test_order_icon_entries_show_only_undelivered_units()
	_test_audio_cue_routing_matches_gameplay_results()
	if failures > 0:
		push_error("%d gameplay assertion(s) failed." % failures)
		quit(1)
	else:
		print("All gameplay model assertions passed.")
		quit(0)

func _test_order_accepts_requested_units_only() -> void:
	var order = OrderStateScript.new({"instant_noodles": 1})
	_assert(order.try_deliver("instant_noodles") == OrderStateScript.DeliveryResult.COMPLETED, "last requested product completes order")
	_assert(order.is_complete(), "completed order reports complete")

func _test_wrong_product_does_not_advance_order() -> void:
	var order = OrderStateScript.new({"chips": 1})
	_assert(order.try_deliver("soft_drink") == OrderStateScript.DeliveryResult.WRONG_PRODUCT, "wrong product is rejected")
	_assert(order.remaining_quantity("chips") == 1, "wrong product leaves request unchanged")

func _test_duplicate_units_require_duplicate_deliveries() -> void:
	var order = OrderStateScript.new({"chips": 2})
	_assert(order.try_deliver("chips") == OrderStateScript.DeliveryResult.ACCEPTED, "first duplicate is accepted without completion")
	_assert(not order.is_complete(), "one of two duplicate items is incomplete")
	_assert(order.try_deliver("chips") == OrderStateScript.DeliveryResult.COMPLETED, "second duplicate completes order")

func _test_order_factory_respects_configured_unit_range() -> void:
	var data = OrderDataScript.new()
	var order_product_ids: Array[String] = ["chips", "soft_drink"]
	data.product_ids = order_product_ids
	data.minimum_units = 3
	data.maximum_units = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var order = OrderFactoryScript.make_order(data, ["chips", "soft_drink"], rng)
	var units := 0
	for quantity in order.requested.values():
		units += int(quantity)
	_assert(units == 3, "factory generates configured number of units")
	for product_id in order.requested:
		_assert(data.product_ids.has(product_id), "factory only chooses products in the configured pool")

func _test_timeout_reduces_only_the_customers_trust_once() -> void:
	var customer = CustomerStateScript.new("regular", OrderStateScript.new({"chips": 2}), 0.1, 100.0)
	_assert(customer.advance_time(0.1), "patience expiry reports the timeout transition")
	_assert(is_equal_approx(customer.trust, 75.0), "timeout lowers this customer's trust by 25")
	_assert(not customer.advance_time(1.0), "later frames do not repeat the timeout")
	_assert(is_equal_approx(customer.trust, 75.0), "trust loss occurs only once")
	_assert(customer.receive_product("chips") == CustomerStateScript.DeliveryResult.INACTIVE, "timed-out customer rejects a late product")
	_assert(is_equal_approx(customer.get_return_weight(), 0.75), "return weight reflects reduced trust")

func _test_wrong_and_partial_deliveries_do_not_pay() -> void:
	var manager := _make_test_shift(2, 10.0)
	manager.start_shift()
	var customer: CustomerState = manager.get_active_customers()[0]
	var cash_before := manager.campaign_state.cash
	var products_before: Array[String] = manager.campaign_state.get_available_product_ids()
	_assert(manager.deliver_product(customer.instance_id, "soft_drink") == OrderStateScript.DeliveryResult.WRONG_PRODUCT, "wrong product is rejected by targeted customer")
	_assert(manager.deliver_product(customer.instance_id, "chips") == OrderStateScript.DeliveryResult.ACCEPTED, "partial correct delivery is accepted")
	_assert(manager.campaign_state.cash == cash_before, "wrong or incomplete order never pays")
	_assert(manager.campaign_state.get_available_product_ids() == products_before, "selling products never consumes shelf stock")

func _test_completed_duplicate_order_pays_exactly_once() -> void:
	var manager := _make_test_shift(2, 10.0)
	manager.start_shift()
	var customer: CustomerState = manager.get_active_customers()[0]
	var cash_before := manager.campaign_state.cash
	manager.deliver_product(customer.instance_id, "chips")
	var result := manager.deliver_product(customer.instance_id, "chips")
	_assert(result == OrderStateScript.DeliveryResult.COMPLETED, "second duplicate completes the order")
	_assert(manager.campaign_state.cash == cash_before + 20, "completed order pays the sum of delivered items")
	_assert(manager.deliver_product(customer.instance_id, "chips") == CustomerStateScript.DeliveryResult.INACTIVE, "completed customer cannot be paid twice")
	_assert(manager.campaign_state.cash == cash_before + 20, "post-completion delivery cannot add extra payment")

func _test_timed_out_delivery_is_lost_and_late_drop_is_rejected() -> void:
	var manager := _make_test_shift(2, 0.1)
	manager.start_shift()
	var customer: CustomerState = manager.get_active_customers()[0]
	manager.deliver_product(customer.instance_id, "chips")
	var cash_before := manager.campaign_state.cash
	manager.advance_time(0.1)
	_assert(not customer.active and customer.order.delivered.get("chips", 0) == 1, "partially delivered item leaves with timed-out customer")
	_assert(manager.deliver_product(customer.instance_id, "chips") == CustomerStateScript.DeliveryResult.INACTIVE, "drop to old customer instance is rejected after timeout")
	_assert(manager.campaign_state.cash == cash_before, "timed-out partial order does not pay")

func _test_closing_emits_once() -> void:
	shift_completion_count = 0
	var manager := _make_test_shift(1, 10.0)
	manager.shift_completed.connect(_on_shift_completed)
	manager.start_shift()
	manager.advance_time(1.0)
	manager.finish_shift()
	_assert(shift_completion_count == 1, "closing emits the completion signal exactly once")
	_assert(manager.get_active_customers().is_empty(), "closing clears customers without creating arrivals after hours")

func _test_campaign_unlocks_and_pacing() -> void:
	var campaign: CampaignState = CampaignStateScript.new(CampaignFixture)
	_assert(not campaign.get_available_product_ids().is_empty(), "Day 1 starts with configured products")
	_assert(campaign.get_active_customer_limit() == 1, "Day 1 starts with one low-pressure customer")
	_assert(campaign.get_max_order_units() == 2, "Day 1 introduces multiple-item orders without overload")
	campaign.advance_day()
	campaign.advance_day()
	campaign.advance_day()
	_assert(campaign.day == 4, "campaign advances into Day 4")
	_assert(campaign.get_active_customer_limit() == 3, "customer cap increases on Day 4")
	_assert(campaign.get_available_product_ids().has("canned_sardines"), "Day 4 scheduled product unlocks")
	_assert(campaign.get_available_product_ids().has("juice_sachet"), "Tang Orange joins the hanging rail on Day 4")
	campaign.advance_day()
	campaign.advance_day()
	campaign.advance_day()
	_assert(campaign.day == 7, "campaign advances into Day 7")
	_assert(campaign.get_available_product_ids().has("laundry_sachet"), "Day 7 scheduled product unlocks")
	_assert(campaign.get_available_product_ids().has("iced_tea_sachet"), "Nestea Lemon joins the hanging rail on Day 7")
	campaign.advance_day()
	_assert(campaign.day == 7, "campaign stops at its seventh and final shift")
	campaign.save_customer_trust("regular", 79.0)
	_assert(campaign.count_trusted_regulars() == 0, "trust below configured threshold is not counted as a regular")
	campaign.save_customer_trust("regular", 80.0)
	_assert(campaign.count_trusted_regulars() == 1, "trust at configured threshold counts as a regular")

func _test_day_by_day_learning_curve() -> void:
	var campaign: CampaignState = CampaignStateScript.new(CampaignFixture)
	var expected_close_minutes: Array[int] = [240, 540, 600, 600, 720, 720, 720]
	var expected_durations: Array[float] = [160.0, 360.0, 400.0, 400.0, 480.0, 480.0, 480.0]
	var expected_caps: Array[int] = [1, 2, 2, 3, 4, 5, 4]
	for index in expected_close_minutes.size():
		campaign.day = index + 1
		_assert(campaign.get_shift_close_minutes() == expected_close_minutes[index], "Day %d closes at the planned in-game time" % campaign.day)
		_assert(is_equal_approx(campaign.get_shift_length_seconds(), expected_durations[index]), "Day %d has the planned real-time duration" % campaign.day)
		_assert(campaign.get_active_customer_limit() == expected_caps[index], "Day %d uses the planned simultaneous-customer cap" % campaign.day)
	_assert(campaign.get_customer_patience_seconds() >= 999999.0, "Day 7 remains a low-punishment finale")
	_assert(CampaignFixture.get_customer_patience_seconds_for_day(4) < CampaignFixture.get_customer_patience_seconds_for_day(3), "rain day requires faster decisions than Day 3")
	_assert(CampaignFixture.get_customer_spawn_interval_for_day(6) < CampaignFixture.get_customer_spawn_interval_for_day(5), "Fiesta Day 6 has the fastest customer arrivals")

func _test_daily_goals_are_optional_and_day_specific() -> void:
	var day_one := DailyGoalScript.new(1)
	_assert(day_one.title == "Serve 3 customers" and not day_one.is_complete(), "Day 1 has an optional serving goal")
	day_one.record_customer_served(1)
	day_one.record_customer_served(2)
	day_one.record_customer_served(1)
	_assert(day_one.is_complete(), "customer-serving goal completes without changing campaign state")
	var rain_day := DailyGoalScript.new(4)
	rain_day.record_timeout()
	rain_day.finalize(0)
	_assert(not rain_day.is_complete(), "rain-day no-timeout goal fails without a gameplay penalty")
	var finale := DailyGoalScript.new(7)
	finale.finalize(3)
	_assert(finale.is_complete(), "Day 7 regular goal completes from trusted regulars")

func _test_day_briefing_explains_the_new_idea_and_goal() -> void:
	var rain_briefing = DayBriefingScript.new(4, DailyGoalScript.new(4))
	_assert(rain_briefing.heading == "DAY 4", "briefing names the current story day")
	_assert(rain_briefing.change_lines.has("Rain makes customers less patient"), "rain briefing names the day's new pressure")
	_assert(rain_briefing.change_lines.has("Shift ends at 6:00 PM"), "briefing names the day's closing time")
	_assert(rain_briefing.goal_title == "Let no customer leave", "briefing carries the optional daily goal")
	_assert(rain_briefing.goal_reward == "Tag-ulan medal", "briefing carries the daily-goal reward")

func _test_day_briefing_prioritizes_focus_and_configuration_unlocks() -> void:
	var starter_product: ProductData = ProductDataScript.new()
	starter_product.display_name = "Noodz"
	starter_product.unlock_day = 1
	var day_two_product: ProductData = ProductDataScript.new()
	day_two_product.display_name = "Fizzy Pop"
	day_two_product.unlock_day = 2
	var day_one_briefing = DayBriefingScript.new(1, DailyGoalScript.new(1), [starter_product, day_two_product])
	_assert(day_one_briefing.eyebrow == "WELCOME TO KWENTA", "Day 1 uses a welcome label instead of what changed")
	_assert(day_one_briefing.title == "DAY 1", "Day 1 uses the day number as its title")
	_assert(day_one_briefing.focus == "Drag products to serve each order.", "briefing puts the day's core mechanic first")
	_assert(day_one_briefing.product_section_title == "STARTING SHELF", "Day 1 identifies its starting products")
	_assert(day_one_briefing.unlocked_product_names == ["Noodz"], "briefing reads Day 1 products from configuration")
	var day_two_briefing = DayBriefingScript.new(2, DailyGoalScript.new(2), [starter_product, day_two_product])
	_assert(day_two_briefing.product_section_title == "NEW ON THE SHELF", "later days label their new product unlocks")
	_assert(day_two_briefing.unlocked_product_names == ["Fizzy Pop"], "briefing reads later unlocks from configuration")
	_assert(day_two_briefing.panel_text().contains("NEW ON THE SHELF"), "briefing renders the product-unlock section")
	var store_config := StoreConfig.load_config("res://data/store_config.json")
	var actual_day_one = DayBriefingScript.new(1, DailyGoalScript.new(1), CampaignFixture.product_catalog, store_config)
	var expected_starters := ["Noodz", "Feeta", "Thang", "Cola-Coca", "Egg Large"]
	_assert(actual_day_one.unlocked_product_names.size() == expected_starters.size(), "Day 1 briefing has exactly the five stocked starters")
	for product_name in expected_starters:
		_assert(actual_day_one.unlocked_product_names.has(product_name), "Day 1 briefing includes %s" % product_name)
	var actual_day_two = DayBriefingScript.new(2, DailyGoalScript.new(2), CampaignFixture.product_catalog, store_config)
	_assert(actual_day_two.unlocked_product_names.size() == 3, "Day 2 briefing matches the three story unlocks in the store")

func _test_notebook_scroll_supports_touch_drag() -> void:
	var scroll = NotebookScrollScript.new()
	_assert(scroll.supports_touch_drag(), "notebook body explicitly supports finger-drag scrolling")
	scroll.free()

func _test_notebook_section_headers_use_compact_action_tags() -> void:
	var summary = NotebookSummaryScript.new()
	summary.text = "TODAY'S SALES\nBenta ngayong araw: ₱76"
	var tag: Control = summary.get_child(0)
	_assert(tag.name == "ActionSectionTag", "section headers use a named action-color tag")
	_assert(tag.size_flags_horizontal == Control.SIZE_SHRINK_BEGIN, "action tags shrink to their label instead of spanning the panel")
	var tag_style: StyleBoxTexture = tag.get_theme_stylebox("panel")
	_assert(tag_style is StyleBoxTexture and tag_style.texture.resource_path.ends_with("wooden_tag.png"), "action tags use the wooden tag texture")
	summary.free()

func _test_notebook_action_button_uses_ibigay_texture() -> void:
	var main = MainScript.new()
	var button := Button.new()
	main.apply_notebook_action_button_style(button)
	var button_style: StyleBoxTexture = button.get_theme_stylebox("normal")
	_assert(button_style is StyleBoxTexture and button_style.texture.resource_path.ends_with("ibigay_button.png"), "notebook action button uses the ibigay texture")
	button.free()
	main.free()

func _test_shift_counts_served_and_timed_out_customers_for_summary() -> void:
	var served_manager := _make_test_shift(2, 10.0)
	served_manager.start_shift()
	var served_customer: CustomerState = served_manager.get_active_customers()[0]
	served_manager.deliver_product(served_customer.instance_id, "chips")
	served_manager.deliver_product(served_customer.instance_id, "chips")
	_assert(served_manager.customers_served == 1, "summary counts each completed sale once")
	_assert(served_manager.customers_timed_out == 0, "summary keeps timeouts separate from completed sales")
	var timeout_manager := _make_test_shift(1, 0.1)
	timeout_manager.patience_seconds_override = 0.1
	timeout_manager.start_shift()
	timeout_manager.shift_duration_seconds = 10.0
	timeout_manager.advance_time(0.11)
	_assert(timeout_manager.customers_timed_out == 1, "summary counts a customer who leaves")

func _test_optional_unlock_costs_cash_once() -> void:
	var campaign: CampaignState = CampaignStateScript.new(CampaignFixture)
	var optional_product: ProductData = null
	for product_resource in CampaignFixture.product_catalog:
		var product: ProductData = product_resource
		if product.unlock_day == 0 and product.unlock_cost > 0:
			optional_product = product
			break
	if optional_product == null:
		_assert(true, "campaign has no optional product purchase configured")
		return
	var cash_before := campaign.cash
	_assert(not campaign.get_available_product_ids().has(optional_product.id), "purchase-only product starts locked")
	_assert(campaign.purchase_unlock(optional_product), "sufficient cash purchases the optional product")
	_assert(campaign.cash == cash_before - optional_product.unlock_cost, "purchase subtracts its configured cost")
	_assert(campaign.is_product_available(optional_product), "purchase permanently unlocks the product")
	var purchase_pool: OrderData = OrderDataScript.new()
	purchase_pool.product_ids = [optional_product.id]
	purchase_pool.minimum_units = 1
	purchase_pool.maximum_units = 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 89
	var order := OrderFactoryScript.make_order(purchase_pool, campaign.get_available_product_ids(), rng)
	_assert(order.requested.has(optional_product.id), "customer order factory can request an unlocked purchase-only product")
	_assert(not campaign.purchase_unlock(optional_product), "already unlocked product cannot be purchased twice")
	_assert(campaign.cash == cash_before - optional_product.unlock_cost, "duplicate purchase does not spend more cash")
	campaign.advance_day()
	_assert(campaign.is_product_available(optional_product), "optional product remains unlocked on later days")

func _test_shelf_purchase_costs_cash_once() -> void:
	var campaign: CampaignState = CampaignStateScript.new(CampaignFixture)
	_assert(campaign.purchase_store_group("water_shelf", 120), "sufficient Day 1 cash buys the water shelf")
	_assert(campaign.cash == 30 and campaign.purchased_store_groups.has("water_shelf"), "water shelf purchase records ownership and deducts its configured cost")
	_assert(not campaign.purchase_store_group("water_shelf", 120), "an owned shelf cannot be purchased twice")
	_assert(campaign.cash == 30, "duplicate shelf purchase does not spend cash")

func _test_seven_day_story_remembers_choices_and_callbacks() -> void:
	var story: StoryProgression = StoryProgressionScript.new(CampaignFixture)
	_assert(story.get_campaign_day_count() == 7, "the approved story has seven days")
	_assert(not story.get_prologue_beats().is_empty(), "the Ang Susi prologue is data-driven and present")
	_assert(story.get_day_title(1) == "Ayoko Nito" and story.get_day_title(7) == "Kwenta", "the first and final approved day titles are present")
	_assert(story.get_day_choices(2).size() == 2, "Day 2 includes the haggling beat and the overpayment choice")
	_assert(story.record_choice("day2_overpayment", "return"), "a valid story choice is remembered")
	_assert(story.get_choice("day2_overpayment") == "return", "the selected choice flag can be read later")
	var day_three_intro := story.get_day_intro_beats(3)
	var returned_money_callback := false
	for beat in day_three_intro:
		returned_money_callback = returned_money_callback or str(beat.get("text", "")).contains("sobra po")
	_assert(returned_money_callback, "returning the ₱50 produces the Day 3 Mang Berting callback")
	_assert(not story.record_choice("day2_overpayment", "missing"), "an unknown option cannot overwrite a story flag")
	story.record_choice("day1_play", "stay")
	story.record_choice("day3_candy", "credit")
	story.record_choice("day4_rain", "shelter")
	story.record_choice("day5_debt", "installments")
	story.record_choice("day6_help", "ask")
	_assert(story.get_day_callback_beats(7).size() >= 10, "the finale includes choice-specific notebook reactions and the epilogue")
	story.reset()
	_assert(story.get_choice("day1_play").is_empty(), "replay clears remembered choices")

func _test_counter_sprite_atlases_cover_the_campaign_catalog() -> void:
	var preview_bounds := Vector2(44.0, 48.0)
	var fitted_preview: Rect2 = CounterArtScript.fit_texture_rect(Vector2(250.0, 285.0), preview_bounds)
	_assert(fitted_preview.size.x <= preview_bounds.x + 0.01 and fitted_preview.size.y <= preview_bounds.y + 0.01, "drag preview stays within its logical-pixel bounds")
	_assert(fitted_preview.position.x >= -0.01 and fitted_preview.position.y >= -0.01, "drag preview remains centered inside its bounds")
	for product_resource in CampaignFixture.product_catalog:
		var product: ProductData = product_resource
		var icon: Texture2D = CounterArtScript.product_icon(product.id, ProductAtlas)
		_assert(icon != null, "counter art exists for %s" % product.id)
		if icon != null:
			_assert(icon.resource_path.begins_with("res://assets/products/"), "counter art uses the authored PNG pipeline for %s" % product.id)
		var display: Texture2D = CounterArtScript.product_display_texture(product.id)
		_assert(display != null and display.resource_path.begins_with("res://assets/products/"), "stacked storefront art exists for %s" % product.id)
	var represented_customers := ["aling_nena", "mang_berting", "bea", "paolo", "kuya_dodong", "jun_jun"]
	for customer_id in represented_customers:
		var portrait: AtlasTexture = CounterArtScript.customer_portrait(customer_id, CustomerPortraitAtlas)
		_assert(portrait != null and portrait.region.size.x > 0.0, "customer portrait exists for %s" % customer_id)
	var story_portraits := ["tonyo_bored", "tonyo_flustered", "tonyo_determined", "tonyo_smiling_tired", "aling_cora", "aling_cora_smiling", "aling_cora_reading", "jun_jun_tara", "mikay_smug", "bogs_small_smile", "aling_nena_haggling", "aling_nena_happy", "aling_nena_impatient", "aling_nena_embarrassed", "mang_berting_happy", "mang_berting_impatient", "bea_happy", "bea_sad", "paolo_happy", "paolo_sad", "kuya_dodong_thoughtful", "kuya_dodong_soaked"]
	for portrait_id in story_portraits:
		var story_portrait: AtlasTexture = CounterArtScript.customer_portrait(portrait_id, CustomerPortraitAtlas)
		_assert(story_portrait != null and story_portrait.region.size == Vector2(512.0, 512.0), "story portrait exists for %s" % portrait_id)
	_assert(CounterArtScript.customer_portrait("jun_jun", CustomerPortraitAtlas).region != CounterArtScript.customer_portrait("bogs", CustomerPortraitAtlas).region, "Jun-jun and Bogs use distinct portrait cells")
	_assert(CounterArtScript.customer_portrait("bogs", CustomerPortraitAtlas).region != CounterArtScript.customer_portrait("paolo", CustomerPortraitAtlas).region, "Bogs and Paolo use distinct portrait cells")

func _test_day_one_store_products_use_branded_sprite_icons() -> void:
	var noodle_icon: Texture2D = CounterArtScript.product_icon("instant_noodles", ProductAtlas)
	_assert(noodle_icon != null and noodle_icon.resource_path.ends_with("noodz_single.png"), "instant noodles use the authored Noodz single-unit PNG")
	var coffee_icon: Texture2D = CounterArtScript.product_icon("coffee_sachet", ProductAtlas)
	_assert(coffee_icon != null and coffee_icon.resource_path.ends_with("kapeko_blanca_single.png"), "coffee sachets use the authored Kapeko single-unit PNG")

func _test_order_bubble_icons_fit_their_cells() -> void:
	var bubble_bounds := Vector2(60.0, 60.0)
	for product_id in ["soft_drink", "candy", "bottled_water"]:
		var icon_texture: Texture2D = CounterArtScript.product_icon(product_id, ProductAtlas)
		var fitted: Rect2 = OrderBubbleIconScript.get_fitted_rect(Vector2(icon_texture.get_size()), bubble_bounds)
		_assert(fitted.size.x <= bubble_bounds.x and fitted.size.y <= bubble_bounds.y, "%s order icon stays inside its 17x18 bubble cell" % product_id)
		_assert(Rect2(Vector2.ZERO, bubble_bounds).encloses(fitted), "%s order icon is fully enclosed by its bubble cell" % product_id)

func _test_storefront_slots_are_visible_unique_and_non_overlapping() -> void:
	var product_ids := [
		"instant_noodles", "soft_drink", "chips", "biscuits", "bottled_water", "candy",
		"coffee_sachet", "juice_sachet", "iced_tea_sachet", "canned_sardines", "laundry_sachet", "shampoo_sachet", "toothpaste_sachet"
	]
	var seen_rects: Array[Rect2] = []
	for product_id in product_ids:
		var slot: Rect2 = StorefrontLayoutScript.get_product_slot(product_id)
		var display_size: Vector2 = StorefrontLayoutScript.get_product_display_size(product_id)
		_assert(slot.size.x >= 28.0 and slot.size.y >= 22.0, "%s has a touch-sized fixed product slot" % product_id)
		_assert(Rect2(Vector2.ZERO, StorefrontLayoutScript.VIEWPORT_SIZE).encloses(slot), "%s product slot stays on the 1920x1080 player-side scene" % product_id)
		_assert(display_size.x <= slot.size.x and display_size.y <= slot.size.y, "%s art fits within its touch slot" % product_id)
		for other_slot in seen_rects:
			_assert(not slot.intersects(other_slot), "%s does not overlap another product's drag target" % product_id)
		seen_rects.append(slot)
	_assert(StorefrontLayoutScript.get_product_slot("not_a_product").size == Vector2.ZERO, "unknown products have no draggable slot")

func _test_product_display_sizes_follow_the_reference() -> void:
	for product_id in ["coffee_sachet", "juice_sachet", "iced_tea_sachet", "shampoo_sachet", "toothpaste_sachet", "laundry_sachet"]:
		var rail: Rect2 = StorefrontLayoutScript.get_storefront_zone(StorefrontLayoutScript.get_product_layout_zone(product_id))
		_assert(rail.encloses(StorefrontLayoutScript.get_product_slot(product_id)), "%s hangs inside its assigned rail" % product_id)
		var strip: Texture2D = CounterArtScript.product_display_texture(product_id)
		_assert(strip != null and strip.get_size().y > strip.get_size().x * 2.0, "%s is a tightly stacked vertical sachet strip" % product_id)
	_assert(StorefrontLayoutScript.get_storefront_zone("shelf_row_a").encloses(StorefrontLayoutScript.get_product_slot("candy")), "Max Yellow packs sit on the right shelf plank")
	_assert(StorefrontLayoutScript.get_storefront_zone("shelf_row_b").encloses(StorefrontLayoutScript.get_product_slot("soft_drink")), "Cola-Coca stock sits inside the lower shelf zone")
	for product_id in ["biscuits", "canned_sardines", "bottled_water"]:
		_assert(StorefrontLayoutScript.get_stock_count(product_id) == 1, "%s renders once as a composite group sprite" % product_id)
	_assert(StorefrontLayoutScript.get_stock_count("soft_drink") == 3, "Coke keeps its configured stock count")

func _test_product_display_style_matches_the_store() -> void:
	var shadow: PackedVector2Array = CounterArtScript.get_display_shadow_polygon(Rect2(10.0, 20.0, 40.0, 30.0))
	_assert(shadow.size() == 8, "product shelf shadows use a compact pixel-style polygon")
	_assert(shadow[0].x > 10.0 and shadow[4].x < 50.0, "product shelf shadow stays within the item's footprint")
	_assert(shadow[2].y > 50.0 and shadow[6].y < 50.0, "product shelf shadow sits against the shelf-facing base")
	var tint: Color = CounterArtScript.get_product_display_tint()
	_assert(tint.r >= tint.g and tint.g >= tint.b, "product display tint warms the art to match the wooden shop")

func _test_customer_positions_fit_the_storefront() -> void:
	var one_customer: Array[float] = StorefrontLayoutScript.get_customer_x_positions(1)
	var two_customers: Array[float] = StorefrontLayoutScript.get_customer_x_positions(2)
	var five_customers: Array[float] = StorefrontLayoutScript.get_customer_x_positions(5)
	var window: Rect2 = StorefrontLayoutScript.WINDOW_RECT
	_assert(one_customer.size() == 1 and is_equal_approx(one_customer[0], window.position.x + (window.size.x - StorefrontLayoutScript.CUSTOMER_WIDTH) * 0.5), "one customer stands centered in the window")
	var first_center := two_customers[0] + StorefrontLayoutScript.CUSTOMER_WIDTH * 0.5 if two_customers.size() == 2 else 0.0
	var second_center := two_customers[1] + StorefrontLayoutScript.CUSTOMER_WIDTH * 0.5 if two_customers.size() == 2 else 0.0
	_assert(two_customers.size() == 2 and is_equal_approx((first_center + second_center) * 0.5, window.get_center().x), "two customers are symmetrically spaced inside the window")
	_assert(five_customers.size() == StorefrontLayoutScript.MAX_CUSTOMERS, "customer positions honor the configured capacity")
	for position in five_customers:
		_assert(position >= window.position.x and position + StorefrontLayoutScript.CUSTOMER_WIDTH <= window.end.x, "customer hit area stays inside the window")

func _test_day_one_products_have_fixed_shelf_slots() -> void:
	var campaign: CampaignState = CampaignStateScript.new(CampaignFixture)
	var available_count: int = 0
	for product_resource in CampaignFixture.product_catalog:
		var product: ProductData = product_resource
		var slot: Rect2 = StorefrontLayoutScript.get_product_slot(product.id)
		if campaign.is_product_available(product):
			available_count += 1
			_assert(slot.size.x >= 28.0 and slot.size.y >= 22.0, "available Day 1 product %s has a draggable fixed slot" % product.id)
		if product.unlock_day > 1:
			_assert(not campaign.is_product_available(product), "scheduled product %s stays hidden before its unlock day" % product.id)
	_assert(available_count == campaign.get_available_product_ids().size() and available_count > 0, "Day 1 exposes every currently available product in the storefront")

func _test_order_icon_entries_show_only_undelivered_units() -> void:
	var entries: Array[Dictionary] = StorefrontLayoutScript.get_order_icon_entries(
		{"chips": 2, "soft_drink": 1}, {"chips": 1, "soft_drink": 1}
	)
	_assert(entries.size() == 2, "one icon group is shown per requested product")
	_assert(entries[0].product_id == "chips" and entries[0].remaining == 1 and not entries[0].completed, "duplicate requests show the remaining unit count")
	_assert(entries[1].product_id == "soft_drink" and entries[1].remaining == 0 and entries[1].completed, "completed product groups can be ticked or cleared")

func _test_audio_cue_routing_matches_gameplay_results() -> void:
	var main: Control = MainScript.new()
	_assert(main.has_method("audio_cues_for_delivery"), "main maps delivery results to semantic audio cues")
	_assert(main.has_method("audio_cues_for_payment"), "main maps completed payment results to semantic audio cues")
	_assert(main.has_method("ambience_for_environment_day"), "main maps story days to one ambience cue")
	_assert(main.has_method("music_for_environment_day"), "main maps story days to one background track")
	if not main.has_method("audio_cues_for_delivery") or not main.has_method("audio_cues_for_payment") or not main.has_method("ambience_for_environment_day") or not main.has_method("music_for_environment_day"):
		main.free()
		return
	_assert(main.call("audio_cues_for_delivery", OrderStateScript.DeliveryResult.WRONG_PRODUCT, false) == ["reject"], "wrong delivery routes to rejection audio")
	_assert(main.call("audio_cues_for_delivery", OrderStateScript.DeliveryResult.ACCEPTED, false) == ["correct"], "accepted delivery routes to confirmation audio")
	_assert(main.call("audio_cues_for_delivery", OrderStateScript.DeliveryResult.COMPLETED, true) == ["correct", "sale"], "immediate completed sales route to confirmation then sale audio")
	_assert(main.call("audio_cues_for_delivery", OrderStateScript.DeliveryResult.COMPLETED, false) == ["correct"], "completed orders awaiting change do not play the sale cue yet")
	_assert(main.call("audio_cues_for_payment", PaymentState.Result.EXACT) == ["sale"], "exact change routes to the completed-sale audio")
	_assert(main.call("audio_cues_for_payment", PaymentState.Result.SHORT) == ["reject"], "short change routes to rejection audio")
	_assert(str(main.call("ambience_for_environment_day", 4)).is_empty(), "rain day keeps ambience clear because its rain track is music")
	_assert(str(main.call("ambience_for_environment_day", 6)).is_empty(), "Day 6 leaves ambience clear so it does not overlap its music")
	_assert(str(main.call("ambience_for_environment_day", 1)).is_empty(), "ordinary days do not start an ambience loop")
	_assert(main.call("music_for_environment_day", 1) == "normal", "ordinary days use the normal store music")
	_assert(main.call("music_for_environment_day", 4) == "rain", "rain day uses rain music")
	_assert(main.call("music_for_environment_day", 6) == "intense", "Day 6 starts the intense track before the brownout")
	_assert(not main.has_method("music_for_brownout"), "the brownout has no separate background-music route")
	main.free()

func _test_two_customers_keep_separate_orders_and_capacity() -> void:
	var manager := _make_test_shift(2, 100.0, ["regular", "neighbor"])
	manager.campaign_state.config.shift_length_seconds = 100.0
	manager.start_shift()
	manager.advance_time(10.01)
	var customers := manager.get_active_customers()
	_assert(customers.size() == 2, "second customer fills an available slot")
	if customers.size() != 2:
		return
	_assert(customers[0].instance_id != customers[1].instance_id, "simultaneous customers have distinct drop targets")
	manager.deliver_product(customers[0].instance_id, "chips")
	_assert(customers[0].order.delivered.get("chips", 0) == 1, "drop updates the selected customer's order")
	_assert(customers[1].order.delivered.get("chips", 0) == 0, "drop does not leak to the other customer's order")
	manager.deliver_product(customers[0].instance_id, "chips")
	manager.advance_time(18.0)
	_assert(manager.get_active_customers().size() <= 2, "replacement customer respects the active-customer cap")
	_assert(manager.get_active_customers().size() == 2, "replacement arrives when an active slot opens")

func _make_test_shift(units: int, patience: float, test_customer_ids: Array[String] = []) -> ShiftManager:
	var product: ProductData = ProductDataScript.new()
	product.id = "chips"
	product.display_name = "Chips"
	product.price = 10
	var order_data: OrderData = OrderDataScript.new()
	var order_product_ids: Array[String] = ["chips"]
	order_data.product_ids = order_product_ids
	order_data.minimum_units = units
	order_data.maximum_units = units
	var config: CampaignConfig = CampaignConfigScript.new()
	config.product_catalog.append(product)
	config.day_order_pools.append(order_data)
	var pool_start_days: Array[int] = [1]
	config.order_pool_start_days = pool_start_days
	var customer_ids: Array[String] = test_customer_ids
	if customer_ids.is_empty():
		customer_ids = ["regular"]
	config.customer_ids = customer_ids
	config.initial_cash = 50
	config.shift_length_seconds = 1.0
	config.customer_spawn_interval = 10.0
	config.customer_patience_seconds = patience
	var campaign: CampaignState = CampaignStateScript.new(config)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	return ShiftManagerScript.new(campaign, {"chips": product}, rng)

func _on_shift_completed() -> void:
	shift_completion_count += 1

func _assert(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
