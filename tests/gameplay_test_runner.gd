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
const ProductAtlas = preload("res://assets/sprites/kwenta_generic_products.png")
const CustomerPortraitAtlas = preload("res://assets/sprites/customer_portraits.png")

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
	_test_optional_unlock_costs_cash_once()
	_test_story_endings_consider_money_and_trust()
	_test_counter_sprite_atlases_cover_the_campaign_catalog()
	_test_day_one_store_products_use_branded_sprite_icons()
	_test_order_bubble_icons_fit_their_cells()
	_test_storefront_slots_are_visible_unique_and_non_overlapping()
	_test_product_display_sizes_follow_the_reference()
	_test_product_display_style_matches_the_store()
	_test_day_one_products_have_fixed_shelf_slots()
	_test_customer_positions_fit_the_storefront()
	_test_order_icon_entries_show_only_undelivered_units()
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
	_assert(campaign.get_available_product_ids().size() == 7, "Day 1 starts with seven products")
	_assert(campaign.get_active_customer_limit() == 2, "Day 1 allows two active customers")
	_assert(campaign.get_max_order_units() == 3, "Day 1 orders cap at three units")
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
	for _day in range(7, 10):
		campaign.advance_day()
	_assert(campaign.day == 10, "campaign reaches its final shift")
	campaign.save_customer_trust("regular", 79.0)
	_assert(campaign.count_trusted_regulars() == 0, "trust below configured threshold is not counted as a regular")
	campaign.save_customer_trust("regular", 80.0)
	_assert(campaign.count_trusted_regulars() == 1, "trust at configured threshold counts as a regular")

func _test_optional_unlock_costs_cash_once() -> void:
	var campaign: CampaignState = CampaignStateScript.new(CampaignFixture)
	var shampoo: ProductData = null
	for product_resource in CampaignFixture.product_catalog:
		var product: ProductData = product_resource
		if product.id == "shampoo_sachet":
			shampoo = product
	_assert(shampoo != null, "purchase product exists in catalog")
	if shampoo == null:
		return
	_assert(not campaign.get_available_product_ids().has(shampoo.id), "purchase-only product starts locked")
	_assert(campaign.purchase_unlock(shampoo), "sufficient cash purchases the optional product")
	_assert(campaign.cash == 50, "purchase subtracts current cash")
	_assert(campaign.is_product_available(shampoo), "purchase permanently unlocks the product")
	_assert(campaign.get_order_data_for_day(1).product_ids.has(shampoo.id), "purchased product is eligible to appear in customer orders")
	var purchase_pool: OrderData = OrderDataScript.new()
	purchase_pool.product_ids = [shampoo.id]
	purchase_pool.minimum_units = 1
	purchase_pool.maximum_units = 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 89
	var order := OrderFactoryScript.make_order(purchase_pool, campaign.get_available_product_ids(), rng)
	_assert(order.requested.has(shampoo.id), "customer order factory can request an unlocked purchase-only product")
	_assert(not campaign.purchase_unlock(shampoo), "already unlocked product cannot be purchased twice")
	_assert(campaign.cash == 50, "duplicate purchase does not spend more cash")
	var toothpaste: ProductData = null
	for product_resource in CampaignFixture.product_catalog:
		var product: ProductData = product_resource
		if product.id == "toothpaste_sachet":
			toothpaste = product
	_assert(toothpaste != null, "second purchase product exists in catalog")
	if toothpaste != null:
		_assert(not campaign.purchase_unlock(toothpaste), "insufficient cash rejects an optional purchase")
		_assert(campaign.cash == 50, "insufficient cash never becomes negative")
	campaign.advance_day()
	_assert(campaign.is_product_available(shampoo), "optional product remains unlocked on later days")

func _test_story_endings_consider_money_and_trust() -> void:
	var story: StoryProgression = StoryProgressionScript.new(CampaignFixture)
	_assert(story.get_ending_variant(1500, 3, 1500, 3) == StoryProgressionScript.EndingVariant.BALANCED_SUCCESS, "meeting both goals gives balanced ending")
	_assert(story.get_ending_variant(1500, 1, 1500, 3) == StoryProgressionScript.EndingVariant.MIXED_PROGRESS, "meeting one goal gives mixed ending")
	_assert(story.get_ending_variant(0, 0, 1500, 3) == StoryProgressionScript.EndingVariant.HOPEFUL_SECOND_CHANCE, "missing both goals keeps a hopeful ending")
	_assert(not story.get_intro_text().is_empty(), "story intro is data-driven and present")
	_assert(not story.get_day_transition_text(4).contains("wrong person"), "story does not claim the player caused a rejected wrong-item delivery")
	_assert(not story.get_day_transition_text(4).contains("leaves with only part"), "story doesn't force a timeout after a perfect shift")

func _test_counter_sprite_atlases_cover_the_campaign_catalog() -> void:
	var preview_bounds := Vector2(44.0, 48.0)
	var fitted_preview: Rect2 = CounterArtScript.fit_texture_rect(Vector2(250.0, 285.0), preview_bounds)
	_assert(fitted_preview.size.x <= preview_bounds.x and fitted_preview.size.y <= preview_bounds.y, "drag preview stays within its 44x48 logical-pixel bounds")
	_assert(fitted_preview.position.x >= 0.0 and fitted_preview.position.y >= 0.0, "drag preview remains centered inside its bounds")
	for product_resource in CampaignFixture.product_catalog:
		var product: ProductData = product_resource
		var icon: Texture2D = CounterArtScript.product_icon(product.id, ProductAtlas)
		_assert(icon != null, "counter art exists for %s" % product.id)
		if icon != null:
			if icon is AtlasTexture:
				var atlas_icon := icon as AtlasTexture
				_assert(atlas_icon.region.size.x > 0.0 and atlas_icon.region.size.y > 0.0, "counter art region is non-empty for %s" % product.id)
				_assert(Rect2(Vector2.ZERO, Vector2(atlas_icon.atlas.get_size())).encloses(atlas_icon.region), "counter art region stays within the atlas for %s" % product.id)
			else:
				_assert(icon.get_size() == Vector2(48.0, 48.0), "branded counter art uses the 48x48 icon for %s" % product.id)
	var represented_customers := ["aleng_mila", "jun", "manong_tomas", "ate_liza", "nina", "kuya_ben"]
	for customer_id in represented_customers:
		var portrait: AtlasTexture = CounterArtScript.customer_portrait(customer_id, CustomerPortraitAtlas)
		_assert(portrait != null and portrait.region.size.x > 0.0, "customer portrait exists for %s" % customer_id)

func _test_day_one_store_products_use_branded_sprite_icons() -> void:
	var noodle_icon: Texture2D = CounterArtScript.product_icon("instant_noodles", ProductAtlas)
	_assert(noodle_icon.get_size() == Vector2(48.0, 48.0), "instant noodles use the in-store Nissin product icon")
	var coffee_icon: Texture2D = CounterArtScript.product_icon("coffee_sachet", ProductAtlas)
	_assert(coffee_icon.get_size() == Vector2(48.0, 48.0), "coffee sachets use the in-store Kopiko product icon")

func _test_order_bubble_icons_fit_their_cells() -> void:
	var bubble_bounds := Vector2(17.0, 18.0)
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
		_assert(Rect2(Vector2.ZERO, Vector2(640.0, 360.0)).encloses(slot), "%s product slot stays on the 640x360 player-side scene" % product_id)
		_assert(display_size.x <= slot.size.x and display_size.y <= slot.size.y, "%s art fits within its touch slot" % product_id)
		for other_slot in seen_rects:
			_assert(not slot.intersects(other_slot), "%s does not overlap another product's drag target" % product_id)
		seen_rects.append(slot)
	_assert(StorefrontLayoutScript.get_product_slot("not_a_product").size == Vector2.ZERO, "unknown products have no draggable slot")

func _test_product_display_sizes_follow_the_reference() -> void:
	for product_id in ["coffee_sachet", "juice_sachet", "iced_tea_sachet", "shampoo_sachet", "toothpaste_sachet", "laundry_sachet"]:
		_assert(StorefrontLayoutScript.get_product_slot(product_id).position.y == 24.0, "%s hangs from the upper rail" % product_id)
		var strip: Texture2D = CounterArtScript.product_display_texture(product_id)
		_assert(strip is AtlasTexture and strip.get_size().y > strip.get_size().x * 2.0, "%s is a tightly stacked vertical sachet strip" % product_id)
	_assert(StorefrontLayoutScript.get_storefront_zone("shelf_row_a").encloses(StorefrontLayoutScript.get_product_slot("candy")), "Max Yellow packs sit on the right shelf plank")
	_assert(StorefrontLayoutScript.get_product_slot("soft_drink").position.y >= 260.0, "Coke stock sits inside the cooler")
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
	_assert(one_customer.size() == 1 and is_equal_approx(one_customer[0], 286.0), "one customer stands centered in the window")
	_assert(two_customers.size() == 2 and is_equal_approx(two_customers[0], 218.0) and is_equal_approx(two_customers[1], 354.0), "two customers are evenly spaced inside the window")
	_assert(five_customers.size() == 5 and is_equal_approx(five_customers[0], 150.0) and is_equal_approx(five_customers[4], 422.0), "five customers fit within the 340-pixel window")
	for position in five_customers:
		_assert(position >= 150.0 and position + 68.0 <= 490.0, "customer hit area stays inside the window")

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
	_assert(available_count == 7, "Day 1 exposes exactly seven products in the storefront")

func _test_order_icon_entries_show_only_undelivered_units() -> void:
	var entries: Array[Dictionary] = StorefrontLayoutScript.get_order_icon_entries(
		{"chips": 2, "soft_drink": 1}, {"chips": 1, "soft_drink": 1}
	)
	_assert(entries.size() == 2, "one icon group is shown per requested product")
	_assert(entries[0].product_id == "chips" and entries[0].remaining == 1 and not entries[0].completed, "duplicate requests show the remaining unit count")
	_assert(entries[1].product_id == "soft_drink" and entries[1].remaining == 0 and entries[1].completed, "completed product groups can be ticked or cleared")

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
