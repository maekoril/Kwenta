extends SceneTree

const CampaignConfigScript = preload("res://scripts/campaign_config.gd")
const CampaignStateScript = preload("res://scripts/campaign_state.gd")
const CashTrayScript = preload("res://scripts/cash_tray.gd")
const CustomerActorScene = preload("res://scenes/customer_slot.tscn")
const CustomerStateScript = preload("res://scripts/customer_state.gd")
const OrderDataScript = preload("res://scripts/order_data.gd")
const OrderStateScript = preload("res://scripts/order_state.gd")
const ProductDataScript = preload("res://scripts/product_data.gd")
const ProductDragItemScene = preload("res://scenes/product_drag_item.tscn")
const ShiftManagerScript = preload("res://scripts/shift_manager.gd")
const StorefrontLayoutScript = preload("res://scripts/storefront_layout.gd")
const SukliRulesScript = preload("res://scripts/sukli_rules.gd")
const ProductAtlas = preload("res://assets/sprites/kwenta_generic_products.png")
const MainScene = preload("res://scenes/main.tscn")

var failures := 0
var released_product_id := ""
var released_position := Vector2.ZERO
var observed_clock := ""
var customer_change_count := 0

func _initialize() -> void:
	_test_sukli_is_introduced_on_day_two_and_helper_fades_after_day_two()
	await _test_cash_tray_uses_reference_text_hierarchy()
	await _test_cash_tray_matches_the_tall_reference_panel()
	await _test_cash_tray_matches_the_wide_reference_panel()
	await _test_cash_tray_uses_the_money_tray_texture()
	await _test_cash_tray_keeps_counter_chips_inside_the_paper()
	await _test_cash_tray_keeps_large_guided_note_inside_its_paper()
	await _test_cash_tray_uses_one_even_content_box()
	_test_storefront_defines_core_shift_pacing()
	_test_shift_caps_window_customers_and_uses_core_patience()
	_test_timeout_notifies_the_scene_before_replacement_spawn()
	await _test_customer_patience_footer_uses_patience_ratio_and_thresholds()
	await _test_customer_payment_bubble_preserves_sukli_prompt()
	await _test_product_drag_reports_mouse_and_touch_release()
	await _test_only_one_shelf_drag_preview_can_be_active()
	await _test_story_replay_resets_the_campaign()
	await _test_main_routes_bubble_drops_to_immediate_cash()
	if failures > 0:
		push_error("%d core gameplay loop assertion(s) failed." % failures)
		quit(1)
	else:
		print("All core gameplay loop assertions passed.")
		quit(0)

func _test_sukli_is_introduced_on_day_two_and_helper_fades_after_day_two() -> void:
	_assert(not SukliRulesScript.is_enabled(1), "Day 1 teaches serving before sukli")
	_assert(SukliRulesScript.is_enabled(2), "Day 2 introduces sukli")
	_assert(SukliRulesScript.sukli_guide_enabled_for_day(1), "the sukli guide remains available during the Day 1 tutorial")
	_assert(SukliRulesScript.sukli_guide_enabled_for_day(2), "the sukli guide is visible on day 2")
	_assert(not SukliRulesScript.sukli_guide_enabled_for_day(3), "the sukli guide is hidden from day 3")
	_assert(not SukliRulesScript.sukli_guide_enabled_for_day(7), "the sukli guide remains hidden after day 3")


func _test_cash_tray_uses_reference_text_hierarchy() -> void:
	var tray := CashTrayScript.new() as Control
	root.add_child(tray)
	await process_frame
	var customer := CustomerStateScript.new("test", OrderStateScript.new({"chips": 1}), 25.0, 50.0)
	customer.begin_payment(23, 50, 12.0)
	tray.open_for(customer, true)
	await process_frame
	var bayad := tray.find_child("ListahanBayadValue", true, false) as Label
	var bili := tray.find_child("ListahanBiliValue", true, false) as Label
	var sukli := tray.find_child("ListahanSukliValue", true, false) as Label
	var counter := tray.find_child("CounterReadout", true, false) as Label
	_assert(bayad != null and bayad.text == "₱50", "the listahan tender uses the peso sign")
	_assert(bili != null and bili.text == "₱23", "the listahan purchase uses the peso sign")
	_assert(sukli != null and sukli.text == "₱27", "the large listahan change value uses the peso sign")
	_assert(counter != null and counter.text == "₱0 / ₱27", "the counter readout uses the peso sign and target")
	_assert(tray.find_child("BaryaTag", true, false) != null, "the coin compartments have a BARYA tag")
	_assert(tray.find_child("PeraTag", true, false) != null, "the bill compartments have a PERA tag")
	tray.open_for(customer, false)
	await process_frame
	_assert(sukli.visible, "the sukli amount remains visible after the Day 2 helper fades")
	tray.queue_free()


func _test_cash_tray_matches_the_tall_reference_panel() -> void:
	var tray := CashTrayScript.new() as Control
	root.add_child(tray)
	await process_frame
	var expected_height := StorefrontLayoutScript.VIEWPORT_SIZE.y * (280.0 / 720.0)
	_assert(is_equal_approx(tray.get("_drawer_size").y, expected_height), "the cash tray uses the taller compact panel height")
	tray.queue_free()


func _test_cash_tray_matches_the_wide_reference_panel() -> void:
	var tray := CashTrayScript.new() as Control
	root.add_child(tray)
	await process_frame
	var expected_width := StorefrontLayoutScript.VIEWPORT_SIZE.x * (1000.0 / 1280.0)
	_assert(is_equal_approx(tray.get("_drawer_size").x, expected_width), "the cash tray uses the compact reference-panel width")
	tray.queue_free()


func _test_cash_tray_uses_the_money_tray_texture() -> void:
	var tray := CashTrayScript.new() as Control
	root.add_child(tray)
	await process_frame
	var tray_art := tray.find_child("MoneyTrayArt", true, false) as TextureRect
	_assert(tray_art != null, "the cash tray builds a dedicated wooden tray texture node")
	if tray_art != null:
		_assert(tray_art.texture != null, "the wooden tray node has a texture assigned")
	tray.queue_free()


func _test_cash_tray_keeps_counter_chips_inside_the_paper() -> void:
	var tray := CashTrayScript.new() as Control
	root.add_child(tray)
	await process_frame
	var customer := CustomerStateScript.new("counter-test", OrderStateScript.new({"chips": 1}), 25.0, 50.0)
	customer.begin_payment(23, 50, 12.0)
	tray.open_for(customer, true)
	for denomination in [1, 5, 10, 20, 50]:
		tray.call("_on_denomination_tapped", denomination, Button.new())
	await process_frame
	var paper := tray.find_child("CounterPanelArt", true, false) as NinePatchRect
	var note := tray.find_child("ListahanPaper", true, false) as NinePatchRect
	var chips := tray.get("_counter_flow") as HFlowContainer
	_assert(chips != null and chips.get_child_count() == 5, "all five denominations use one counter chip row")
	if chips != null:
		_assert(chips.size.y <= float(tray.get("_unit")) * 36.0, "counter chips stay within the 24px display-height budget")
		for chip in chips.get_children():
			_assert(is_equal_approx((chip as Control).position.y, 0.0), "counter chips do not wrap into a second row")
	_assert(note != null and paper != null and note.size.y > paper.size.y and note.size.y <= paper.size.y + 36.0, "guided Listahan grows only within its permitted 24px display allowance")
	tray.open_for(customer, false)
	await process_frame
	_assert(note != null and paper != null and note.size.y < paper.size.y, "guide-off Listahan compacts without an empty band")
	tray.queue_free()


func _test_cash_tray_keeps_large_guided_note_inside_its_paper() -> void:
	var tray := CashTrayScript.new() as Control
	root.add_child(tray)
	await process_frame
	var customer := CustomerStateScript.new("large-change-test", OrderStateScript.new({"chips": 1}), 25.0, 200.0)
	customer.begin_payment(52, 200, 12.0)
	tray.open_for(customer, true)
	await process_frame
	var note := tray.find_child("ListahanPaper", true, false) as NinePatchRect
	var due := tray.find_child("ListahanSukliValue", true, false) as Label
	var helper_prefix := tray.find_child("CounterHelperPrefix", true, false) as Label
	var helper_amount := tray.find_child("CounterHelperAmount", true, false) as Label
	_assert(due != null and due.text == "₱148", "large guided change retains the peso sign")
	_assert(note != null and due != null and note.get_global_rect().encloses(due.get_global_rect()), "large guided change remains fully inside the Listahan paper")
	_assert(due != null and due.get_theme_font_size("font_size") >= 30, "Listahan change value remains the largest note hierarchy")
	_assert(helper_prefix != null and helper_prefix.text == "Kulang pa", "under-target helper keeps its readable prefix")
	_assert(helper_amount != null and helper_amount.text == "₱148", "under-target helper emphasizes the remaining peso amount")
	_assert(helper_amount != null and helper_amount.get_theme_font_size("font_size") >= 30, "helper amount keeps the 20px display emphasis")
	tray.queue_free()


func _test_cash_tray_uses_one_even_content_box() -> void:
	var tray := CashTrayScript.new() as Control
	root.add_child(tray)
	await process_frame
	var customer := CustomerStateScript.new("padding-test", OrderStateScript.new({"chips": 1}), 25.0, 50.0)
	customer.begin_payment(23, 50, 12.0)
	tray.open_for(customer, true)
	await process_frame
	var drawer_size := tray.get("_drawer_size") as Vector2
	var content_origin := Vector2(42.0, 42.0)
	var content_size := drawer_size - Vector2(84.0, 84.0)
	var note := tray.find_child("ListahanPaper", true, false) as NinePatchRect
	var counter := tray.find_child("CounterPanelArt", true, false) as NinePatchRect
	var actions := tray.find_child("SukliActions", true, false) as VBoxContainer
	var money_tray := tray.find_child("MoneyTrayArt", true, false) as TextureRect
	_assert(note != null and is_equal_approx(note.position.x, content_origin.x), "Listahan begins at the shared content-box left edge")
	_assert(counter != null and is_equal_approx(counter.position.y, content_origin.y), "counter paper begins at the shared content-box top edge")
	_assert(actions != null and is_equal_approx(actions.position.x + actions.size.x, content_origin.x + content_size.x), "buttons end at the shared content-box right edge")
	_assert(money_tray != null and is_equal_approx(money_tray.position.y + money_tray.size.y, content_origin.y + content_size.y), "money tray ends at the shared content-box bottom edge")
	if money_tray != null:
		_assert(money_tray.size.x * 0.1419 >= 120.0, "the narrowest money-tray tap area stays at least 80px wide at 1280x720")
		_assert(money_tray.size.y >= 84.0, "money-tray tap areas stay at least 56px tall at 1280x720")
	tray.queue_free()

func _test_storefront_defines_core_shift_pacing() -> void:
	var constants := _layout_constants()
	_assert(int(constants.get("MAX_CUSTOMERS", -1)) == 5, "the storefront can present the five-customer Fiesta peak")

func _test_shift_caps_window_customers_and_uses_core_patience() -> void:
	var constants := _layout_constants()
	if not constants.has("MAX_ACTIVE_WINDOW_CUSTOMERS"):
		return
	var manager := _make_test_shift()
	manager.set("active_customer_limit_override", int(constants["MAX_ACTIVE_WINDOW_CUSTOMERS"]))
	manager.set("spawn_delay_min_seconds", float(constants["CUSTOMER_SPAWN_DELAY_MIN_SECONDS"]))
	manager.set("spawn_delay_max_seconds", float(constants["CUSTOMER_SPAWN_DELAY_MAX_SECONDS"]))
	manager.set("patience_seconds_override", float(constants["CUSTOMER_PATIENCE_SECONDS"]))
	observed_clock = ""
	manager.clock_changed.connect(_on_clock_changed)
	manager.start_shift()
	var first_customer: CustomerState = manager.get_active_customers()[0]
	_assert(is_equal_approx(first_customer.patience_seconds, 25.0), "new customer inherits the core patience duration")
	manager.advance_time(4.99)
	_assert(manager.get_active_customers().size() == 1, "a second customer cannot arrive before the minimum delay")
	manager.advance_time(7.02)
	_assert(manager.get_active_customers().size() == 2, "a second customer arrives by the maximum delay")
	manager.advance_time(18.0)
	_assert(manager.get_active_customers().size() <= 2, "replacement arrivals never exceed the two-customer window cap")
	var clock_manager := _make_test_shift()
	clock_manager.campaign_state.config.shift_length_seconds = 1.0
	clock_manager.clock_changed.connect(_on_clock_changed)
	clock_manager.start_shift()
	clock_manager.advance_time(1.0)
	_assert(observed_clock == "12:00 PM", "the Day 1 tutorial shift closes at noon (got %s)" % observed_clock)

func _test_timeout_notifies_the_scene_before_replacement_spawn() -> void:
	var manager := _make_test_shift()
	manager.set("active_customer_limit_override", 2)
	manager.set("spawn_delay_min_seconds", 12.0)
	manager.set("spawn_delay_max_seconds", 12.0)
	manager.set("patience_seconds_override", 0.1)
	customer_change_count = 0
	manager.customers_changed.connect(_on_customers_changed)
	manager.start_shift()
	customer_change_count = 0
	manager.advance_time(0.1)
	_assert(manager.get_active_customers().is_empty(), "an expired customer is removed from shift state")
	_assert(customer_change_count == 1, "an expired customer immediately notifies Main to animate its departure")

func _test_customer_patience_footer_uses_patience_ratio_and_thresholds() -> void:
	var actor := CustomerActorScene.instantiate() as Control
	actor.size = Vector2(StorefrontLayoutScript.CUSTOMER_WIDTH, StorefrontLayoutScript.CUSTOMER_HEIGHT)
	root.add_child(actor)
	await process_frame
	var customer := CustomerStateScript.new("jun", OrderStateScript.new({"chips": 1}), 25.0, 42.0)
	actor.call("set_customer", customer, {})
	await process_frame
	var bubble := actor.get_node("OrderBubble") as Control
	var bubble_content := bubble.get_node_or_null("BubbleContent") as VBoxContainer
	_assert(bubble_content != null, "the bubble owns a vertical layout for icons, name, and patience")
	if bubble_content == null:
		actor.queue_free()
		return
	var name_label := bubble_content.get_node("NameTag/NameLabel") as Label
	var patience_bar := bubble_content.get_node("PatienceBar") as ProgressBar
	var fill := patience_bar.get_theme_stylebox("fill") as StyleBoxFlat
	_assert(name_label.text == "Jun", "the name tag contains the customer name only")
	_assert(bubble.size == Vector2(152.0, 134.0), "one-item bubbles use the minimum readable name width and three layout rows")
	_assert(is_equal_approx(patience_bar.size.x, bubble.size.x - 16.0) and is_equal_approx(patience_bar.size.y, 10.0), "patience uses a ten-pixel horizontal footer row")
	customer.patience_remaining = 15.25
	actor.call("refresh_patience")
	_assert(fill.bg_color == Color("4caa56"), "patience remains green above sixty percent")
	customer.patience_remaining = 15.0
	actor.call("refresh_patience")
	_assert(fill.bg_color == Color("e3bd39"), "patience turns yellow at sixty percent")
	customer.patience_remaining = 7.25
	actor.call("refresh_patience")
	_assert(fill.bg_color == Color("d94536"), "patience turns red below thirty percent")
	var one_item_long_name_customer := CustomerStateScript.new("kuya_dodong", OrderStateScript.new({"chips": 1}), 25.0)
	actor.call("set_customer", one_item_long_name_customer, {})
	await process_frame
	_assert(bubble.size.x >= 152.0 and name_label.text == "Kuya Dodong", "a one-item bubble keeps a long customer name readable")
	var three_item_customer := CustomerStateScript.new("aling_nena", OrderStateScript.new({"chips": 1, "bread": 1, "eggs": 1}), 25.0)
	actor.call("set_customer", three_item_customer, {})
	await process_frame
	_assert(bubble.size == Vector2(268.0, 134.0), "three-item bubbles retain one icon row above the footer rows")
	_assert(name_label.text == "Aling Nena", "long names remain readable without a percentage suffix")
	var five_item_customer := CustomerStateScript.new("kuya_dodong", OrderStateScript.new({"chips": 1, "bread": 1, "eggs": 1, "rice": 1, "soft_drink": 1}), 25.0)
	actor.call("set_customer", five_item_customer, {})
	await process_frame
	_assert(bubble.size == Vector2(184.0, 218.0), "five-item bubbles use two icon rows above the footer rows")
	_assert(name_label.text == "Kuya Dodong" and int(name_label.get_theme_font_size("font_size")) >= 10, "long names remain visible at or above the minimum font size")
	actor.queue_free()

func _test_customer_payment_bubble_preserves_sukli_prompt() -> void:
	var actor := CustomerActorScene.instantiate() as Control
	actor.size = Vector2(StorefrontLayoutScript.CUSTOMER_WIDTH, StorefrontLayoutScript.CUSTOMER_HEIGHT)
	root.add_child(actor)
	await process_frame
	var customer := CustomerStateScript.new("jun", OrderStateScript.new({"chips": 1}), 25.0)
	customer.begin_payment(10, 20, 12.0)
	actor.call("set_customer", customer, {})
	await process_frame
	var bubble := actor.get_node("OrderBubble") as Control
	var content := bubble.get_node("BubbleContent") as VBoxContainer
	var name_tag := content.get_node("NameTag") as PanelContainer
	var patience_bar := content.get_node("PatienceBar") as ProgressBar
	var grid := content.get_node("OrderGrid") as GridContainer
	_assert(actor.has_signal("payment_tapped"), "a paying customer can open the Sukli tray")
	_assert(bubble.size == Vector2(168.0, 120.0), "a paying customer uses the fixed Sukli prompt size")
	_assert(not name_tag.visible and not patience_bar.visible, "the order footer hides while the Sukli prompt is displayed")
	_assert(grid.get_child_count() == 1, "the Sukli prompt replaces the order icon grid during payment")
	actor.queue_free()

func _test_product_drag_reports_mouse_and_touch_release() -> void:
	var item := ProductDragItemScene.instantiate() as Control
	var product := ProductDataScript.new()
	product.id = "chips"
	item.call("configure", product, ProductAtlas, true, Vector2(24.0, 24.0), false)
	item.position = Vector2(100.0, 100.0)
	item.size = Vector2(40.0, 40.0)
	root.add_child(item)
	await process_frame
	_assert(item.has_signal("product_released"), "a source item exposes a release event for drag resolution")
	_assert(item.has_method("finish_drag"), "a source item can return or consume its own drag preview")
	if not item.has_signal("product_released") or not item.has_method("finish_drag"):
		item.queue_free()
		return
	item.connect("product_released", _on_product_released)
	_simulate_mouse_drag(item, Vector2(110.0, 110.0), Vector2(180.0, 120.0))
	_assert(released_product_id == "chips" and released_position == Vector2(180.0, 120.0), "mouse release reports the selected product and viewport position")
	item.call("finish_drag", true)
	released_product_id = ""
	_simulate_touch_drag(item, Vector2(110.0, 110.0), Vector2(160.0, 145.0))
	_assert(released_product_id == "chips" and released_position == Vector2(160.0, 145.0), "touch release reports the selected product and viewport position")
	item.call("finish_drag", false)
	await create_timer(0.4).timeout
	_assert(not item.call("is_drag_active"), "returned previews are freed after their bounce animation")
	item.queue_free()

func _test_only_one_shelf_drag_preview_can_be_active() -> void:
	var first := _make_drag_item("chips", Vector2(60.0, 100.0))
	var second := _make_drag_item("soft_drink", Vector2(120.0, 100.0))
	root.add_child(first)
	root.add_child(second)
	await process_frame
	var first_press := InputEventScreenTouch.new()
	first_press.index = 0
	first_press.pressed = true
	first_press.position = Vector2(70.0, 110.0)
	first.call("_gui_input", first_press)
	var second_press := InputEventScreenTouch.new()
	second_press.index = 1
	second_press.pressed = true
	second_press.position = Vector2(130.0, 110.0)
	second.call("_gui_input", second_press)
	_assert(bool(first.call("is_drag_active")), "the first touch owns a drag preview")
	_assert(not bool(second.call("is_drag_active")), "a second touch cannot create a concurrent drag preview")
	first.call("finish_drag", true)
	second.call("_gui_input", second_press)
	_assert(bool(second.call("is_drag_active")), "a new drag can begin after the first preview resolves")
	second.call("finish_drag", false)
	await create_timer(0.4).timeout
	first.queue_free()
	second.queue_free()

func _test_main_routes_bubble_drops_to_immediate_cash() -> void:
	var main := MainScene.instantiate() as Control
	root.add_child(main)
	await process_frame
	main.call("_begin_shift")
	await process_frame
	var manager: ShiftManager = main.get("shift")
	var active: Array[CustomerState] = manager.get_active_customers()
	_assert(active.size() == 1, "opening a shift creates the first customer")
	if active.is_empty():
		main.queue_free()
		return
	var customer: CustomerState = active[0]
	var actors: Dictionary = main.get("customer_actors")
	var actor: Control = actors.get(customer.instance_id)
	var bubble := actor.get_node("OrderBubble") as Control
	var bubble_point := bubble.global_position + Vector2(2.0, 2.0)
	_assert(bool(actor.call("contains_drop_point", bubble_point)), "a customer bubble is inside the actor drop target")
	var cash_before: int = manager.campaign_state.cash
	var product_items: Dictionary = main.get("product_items_by_id")
	var requested_product_id: String = str(customer.order.requested.keys()[0])
	var requested_source: Control = product_items.get(requested_product_id)
	main.call("_on_product_drag_released", requested_product_id, Vector2.ZERO, requested_source)
	_assert(customer.order.delivered.is_empty() and manager.campaign_state.cash == cash_before, "a release outside every customer returns without fulfilling or paying")
	for product_id in product_items:
		if not customer.order.requested.has(product_id):
			main.call("_on_product_drag_released", str(product_id), bubble_point, product_items[product_id])
			break
	_assert(customer.order.delivered.is_empty() and manager.campaign_state.cash == cash_before, "a wrong product over a bubble returns without fulfilling or paying")
	for product_id in customer.order.requested:
		for _unit in range(int(customer.order.requested[product_id])):
			var source: Control = product_items.get(product_id)
			main.call("_on_product_drag_released", str(product_id), bubble_point, source)
	_assert(manager.campaign_state.cash > cash_before, "a completed bubble drop pays the global cash balance immediately")
	var cash_label := main.get("cash_label") as Label
	_assert(cash_label.text == "₱%d" % manager.campaign_state.cash, "the cash HUD updates in the same delivery transaction")
	main.queue_free()

func _test_story_replay_resets_the_campaign() -> void:
	var main := MainScene.instantiate() as Control
	root.add_child(main)
	await process_frame
	var old_story: StoryProgression = main.get("story")
	old_story.record_choice("day1_play", "stay")
	var old_campaign: CampaignState = main.get("campaign")
	old_campaign.day = old_campaign.config.campaign_day_count
	main.set("story_complete", true)
	main.call("_restart_story")
	var replay_campaign: CampaignState = main.get("campaign")
	var replay_story: StoryProgression = main.get("story")
	_assert(replay_campaign.day == 1, "replay returns the campaign to Day 1")
	_assert(replay_story.get_choice("day1_play").is_empty(), "replay starts with fresh choice flags")
	main.queue_free()

func _simulate_mouse_drag(item: Control, start: Vector2, finish: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = start
	item.call("_gui_input", press)
	var motion := InputEventMouseMotion.new()
	motion.position = finish
	item.call("_input", motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = finish
	item.call("_input", release)

func _simulate_touch_drag(item: Control, start: Vector2, finish: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = start
	item.call("_gui_input", press)
	var motion := InputEventScreenDrag.new()
	motion.index = 0
	motion.position = finish
	item.call("_input", motion)
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.position = finish
	item.call("_input", release)

func _make_test_shift() -> ShiftManager:
	var product := ProductDataScript.new()
	product.id = "chips"
	product.price = 10
	var order_data := OrderDataScript.new()
	order_data.product_ids = ["chips"]
	order_data.minimum_units = 1
	order_data.maximum_units = 1
	var config := CampaignConfigScript.new()
	config.product_catalog.append(product)
	config.day_order_pools.append(order_data)
	config.order_pool_start_days = [1]
	config.customer_ids = ["jun", "mila", "ben"]
	config.shift_length_seconds = 60.0
	config.customer_spawn_interval = 60.0
	config.customer_patience_seconds = 90.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	return ShiftManagerScript.new(CampaignStateScript.new(config), {"chips": product}, rng)

func _make_drag_item(product_id: String, item_position: Vector2) -> Control:
	var item := ProductDragItemScene.instantiate() as Control
	var product := ProductDataScript.new()
	product.id = product_id
	item.call("configure", product, ProductAtlas, true, Vector2(24.0, 24.0), false)
	item.position = item_position
	item.size = Vector2(40.0, 40.0)
	return item

func _on_product_released(product_id: String, viewport_position: Vector2, _source: Control) -> void:
	released_product_id = product_id
	released_position = viewport_position

func _on_clock_changed(value: String) -> void:
	observed_clock = value

func _on_customers_changed() -> void:
	customer_change_count += 1

func _layout_constants() -> Dictionary:
	var layout := StorefrontLayoutScript.new()
	return layout.get_script().get_script_constant_map()

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	failures += 1
	push_error("FAIL: " + description)
