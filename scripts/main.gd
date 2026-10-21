extends Control

const STORE_BACKGROUND: Texture2D = preload("res://assets/backgrounds/kwenta_store_interior_clean.png")
const COOLER_TEXTURE: Texture2D = preload("res://assets/sprites/fixtures/cooler_empty.png")
const CAMPAIGN_CONFIG: CampaignConfig = preload("res://data/story/summer_campaign.tres")
const PRODUCT_DRAG_ITEM_SCENE: PackedScene = preload("res://scenes/product_drag_item.tscn")
const CUSTOMER_ACTOR_SCENE: PackedScene = preload("res://scenes/customer_slot.tscn")
const PRODUCT_ATLAS: Texture2D = preload("res://assets/sprites/kwenta_generic_products.png")
const COUNTER_ART = preload("res://scripts/counter_art.gd")
const STOREFRONT_LAYOUT = preload("res://scripts/storefront_layout.gd")

var campaign: CampaignState
var story: StoryProgression
var shift: ShiftManager
var products_by_id: Dictionary = {}
var clock_label: Label
var cash_label: Label
var day_label: Label
var goal_label: Label
var product_layer: Control
var product_items_by_id: Dictionary = {}
var cooler_fixture: Control
var cooler_front: Control
var upgrade_buttons: Dictionary = {}
var customer_layer: Control
var customer_actors: Dictionary = {}
var summary_panel: PanelContainer
var summary_backdrop: ColorRect
var summary_title: Label
var summary_text: Label
var summary_unlock_row: HBoxContainer
var summary_button: Button
var ui_refresh_elapsed: float = 0.0
var campaign_started: bool = false
var shift_start_cash: int = 0
var shift_start_trust: Dictionary = {}

func _ready() -> void:
	campaign = CampaignState.new(CAMPAIGN_CONFIG)
	story = StoryProgression.new(CAMPAIGN_CONFIG)
	for product_resource in CAMPAIGN_CONFIG.product_catalog:
		var product: ProductData = product_resource
		products_by_id[product.id] = product
	_build_background()
	_build_cooler_fixture()
	_build_customer_area()
	_build_product_layer()
	_build_cooler_front()
	_build_hud()
	_build_summary_panel()
	_update_cash(campaign.cash)
	_create_shift_manager()
	_rebuild_product_shelf()
	summary_backdrop.visible = true
	summary_panel.visible = true
	summary_title.text = "SUMMER BREAK"
	summary_text.text = story.get_intro_text()
	summary_button.text = "OPEN THE STORE"

func _process(delta: float) -> void:
	if shift != null:
		shift.advance_time(delta)
	ui_refresh_elapsed += delta
	if ui_refresh_elapsed >= 0.12:
		ui_refresh_elapsed = 0.0
		for child in customer_layer.get_children():
			if child is Control and child.has_method("refresh_patience"):
				child.refresh_patience()

func _build_background() -> void:
	var background := TextureRect.new()
	background.texture = STORE_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

func _build_cooler_fixture() -> void:
	var cooler := _fixture_texture_rect(COOLER_TEXTURE, Rect2(0.0, 260.0, 195.0, 100.0))
	cooler.name = "CoolerFixture"
	add_child(cooler)
	cooler_fixture = cooler

func _build_cooler_front() -> void:
	# The front of the cooler covers the lower edge of the Coke stock.
	var front_texture := AtlasTexture.new()
	front_texture.atlas = COOLER_TEXTURE
	front_texture.region = Rect2(0.0, 400.0, 1536.0, 624.0)
	var front := _fixture_texture_rect(front_texture, Rect2(0.0, 299.0, 195.0, 61.0))
	front.name = "CoolerFront"
	add_child(front)
	cooler_front = front

func _fixture_texture_rect(texture: Texture2D, bounds: Rect2) -> TextureRect:
	var fixture := TextureRect.new()
	fixture.texture = texture
	fixture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fixture.stretch_mode = TextureRect.STRETCH_SCALE
	fixture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fixture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fixture.position = bounds.position
	fixture.size = bounds.size
	return fixture

func _build_hud() -> void:
	var hud := PanelContainer.new()
	hud.position = Vector2(4, 2)
	hud.size = Vector2(632, 20)
	hud.add_theme_stylebox_override("panel", _make_box(Color(0.13, 0.08, 0.06, 0.96), Color("e7b779")))
	add_child(hud)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	row.add_theme_constant_override("margin_left", 5)
	row.add_theme_constant_override("margin_right", 5)
	hud.add_child(row)
	day_label = _label("SUMMER · DAY 1", 8, Color("ffe1a7"))
	day_label.custom_minimum_size.x = 112
	row.add_child(day_label)
	clock_label = _label("8:00 AM", 9, Color("fff0cf"))
	clock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(clock_label)
	cash_label = _label("₱150", 9, Color("d9efaa"))
	cash_label.custom_minimum_size.x = 50
	cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(cash_label)
	goal_label = _label("SHELVES  150/1500", 7, Color("e4bd87"))
	goal_label.custom_minimum_size.x = 94
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(goal_label)

func _build_product_layer() -> void:
	product_layer = Control.new()
	product_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	product_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(product_layer)

func _build_customer_area() -> void:
	# Customers occupy the actual storefront lane in front of the shelves.
	# Their drop zones move with their character sprites; there are no empty cards.
	customer_layer = Control.new()
	customer_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	customer_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(customer_layer)

func _build_summary_panel() -> void:
	summary_backdrop = ColorRect.new()
	summary_backdrop.color = Color(0.04, 0.025, 0.02, 0.62)
	summary_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	summary_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	summary_backdrop.visible = false
	add_child(summary_backdrop)
	summary_panel = PanelContainer.new()
	summary_panel.position = Vector2(80, 43)
	summary_panel.size = Vector2(480, 274)
	summary_panel.add_theme_stylebox_override("panel", _make_box(Color(0.16, 0.09, 0.07, 0.98), Color("f0c17b")))
	summary_panel.visible = false
	add_child(summary_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	summary_panel.add_child(column)
	summary_title = _label("SHIFT COMPLETE", 14, Color("ffe1a7"))
	summary_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(summary_title)
	summary_text = _label("", 10, Color("fff0cf"))
	summary_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(summary_text)
	summary_unlock_row = HBoxContainer.new()
	summary_unlock_row.add_theme_constant_override("separation", 6)
	column.add_child(summary_unlock_row)
	for upgrade_resource in CAMPAIGN_CONFIG.store_upgrades:
		var upgrade: StoreUpgradeData = upgrade_resource
		var unlock_button := Button.new()
		unlock_button.custom_minimum_size.y = 24
		unlock_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		unlock_button.add_theme_font_size_override("font_size", 7)
		unlock_button.pressed.connect(_purchase_upgrade.bind(upgrade))
		summary_unlock_row.add_child(unlock_button)
		upgrade_buttons[upgrade.id] = unlock_button
	summary_button = Button.new()
	summary_button.text = "NEXT SHIFT"
	summary_button.custom_minimum_size.y = 26
	summary_button.add_theme_font_size_override("font_size", 10)
	summary_button.pressed.connect(_on_summary_button_pressed)
	column.add_child(summary_button)
	_update_unlock_buttons()

func _create_shift_manager() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	shift = ShiftManager.new(campaign, products_by_id, rng)
	shift.customers_changed.connect(_rebuild_customer_slots)
	shift.cash_changed.connect(_update_cash)
	shift.clock_changed.connect(_update_clock)
	shift.shift_completed.connect(_show_shift_summary)

func _rebuild_product_shelf() -> void:
	for child in product_layer.get_children():
		child.queue_free()
	product_items_by_id.clear()
	for product_resource in CAMPAIGN_CONFIG.product_catalog:
		var product: ProductData = product_resource
		if not campaign.is_product_available(product):
			continue
		var slot: Rect2 = STOREFRONT_LAYOUT.get_product_slot(product.id)
		var display_size: Vector2 = STOREFRONT_LAYOUT.get_product_display_size(product.id)
		if slot.size == Vector2.ZERO or display_size == Vector2.ZERO:
			continue
		var drag_item := PRODUCT_DRAG_ITEM_SCENE.instantiate() as Control
		var item_texture: Texture2D = COUNTER_ART.product_single_texture(product.id)
		if item_texture == null:
			item_texture = COUNTER_ART.product_icon(product.id, PRODUCT_ATLAS)
		var display_texture: Texture2D = COUNTER_ART.product_display_texture(product.id)
		if display_texture == null:
			display_texture = item_texture
		drag_item.call("configure", product, item_texture, true, display_size, STOREFRONT_LAYOUT.is_product_rotated(product.id), display_texture, STOREFRONT_LAYOUT.get_stock_count(product.id), product.display_scale)
		drag_item.position = slot.position
		drag_item.size = slot.size
		product_layer.add_child(drag_item)
		product_items_by_id[product.id] = drag_item
	if cooler_fixture != null:
		var show_empty_cooler: bool = not product_items_by_id.has("soft_drink")
		cooler_fixture.visible = show_empty_cooler
		if cooler_front != null:
			cooler_front.visible = show_empty_cooler

func _rebuild_customer_slots() -> void:
	if customer_layer == null or shift == null:
		return
	var active: Array[CustomerState] = shift.get_active_customers()
	var active_ids: Dictionary = {}
	for customer in active:
		active_ids[customer.instance_id] = true
	for instance_id in customer_actors.keys():
		if active_ids.has(instance_id):
			continue
		var leaving: Control = customer_actors[instance_id]
		customer_actors.erase(instance_id)
		var moving_right := leaving.position.x < 320.0
		var exit_tween := create_tween()
		exit_tween.tween_property(leaving, "position:x", 660.0 if moving_right else -140.0, 0.32)
		exit_tween.parallel().tween_property(leaving, "modulate:a", 0.0, 0.32)
		exit_tween.tween_callback(leaving.queue_free)
	var count: int = mini(active.size(), STOREFRONT_LAYOUT.MAX_CUSTOMERS)
	var positions: Array[float] = STOREFRONT_LAYOUT.get_customer_x_positions(count)
	for index in range(count):
		var customer: CustomerState = active[index]
		var target_x: float = positions[index]
		var actor: Control = customer_actors.get(customer.instance_id)
		if actor == null:
			actor = CUSTOMER_ACTOR_SCENE.instantiate() as Control
			actor.size = Vector2(STOREFRONT_LAYOUT.CUSTOMER_WIDTH, STOREFRONT_LAYOUT.CUSTOMER_HEIGHT)
			actor.call("set_customer", customer, products_by_id)
			actor.connect("product_dropped", _on_product_dropped)
			var from_right := randf() < 0.5
			actor.position = Vector2(660.0 if from_right else -90.0, STOREFRONT_LAYOUT.CUSTOMER_Y)
			actor.modulate.a = 0.0
			customer_layer.add_child(actor)
			actor.call("set_facing_right", from_right)
			customer_actors[customer.instance_id] = actor
			var entrance := create_tween()
			entrance.set_parallel(true)
			entrance.tween_property(actor, "position:x", target_x, 0.58).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			entrance.tween_property(actor, "modulate:a", 1.0, 0.20)
		else:
			actor.call("set_customer", customer, products_by_id)
			if not is_equal_approx(actor.position.x, target_x):
				create_tween().tween_property(actor, "position:x", target_x, 0.22)

func _purchase_upgrade(upgrade: StoreUpgradeData) -> void:
	if campaign.purchase_upgrade(upgrade):
		_update_cash(campaign.cash)
		_rebuild_product_shelf()
		_update_unlock_buttons()

func _on_product_dropped(customer_id: String, product_id: String) -> void:
	var source: Control = product_items_by_id.get(product_id)
	var actor: Control = customer_actors.get(customer_id)
	var result := shift.deliver_product(customer_id, product_id)
	if result == OrderState.DeliveryResult.WRONG_PRODUCT or result == CustomerState.DeliveryResult.INACTIVE:
		if is_instance_valid(source):
			source.call("play_reject")
		if is_instance_valid(actor):
			actor.call("play_wrong_drop")
		return
	if is_instance_valid(actor):
		actor.call("refresh_display")
		actor.call("play_correct_drop")
		if result == OrderState.DeliveryResult.COMPLETED:
			actor.call("play_happy")

func _update_clock(value: String) -> void:
	clock_label.text = value

func _update_cash(value: int) -> void:
	cash_label.text = "₱%d" % value
	goal_label.text = "SHELVES  %d/%d" % [mini(campaign.get_shelf_goal_progress(), CAMPAIGN_CONFIG.shelf_replacement_goal), CAMPAIGN_CONFIG.shelf_replacement_goal]
	_update_unlock_buttons()

func _update_unlock_buttons() -> void:
	if summary_unlock_row == null:
		return
	var can_offer_unlocks: bool = campaign_started and campaign != null and campaign.day < 10
	summary_unlock_row.visible = can_offer_unlocks
	for upgrade_resource in CAMPAIGN_CONFIG.store_upgrades:
		var upgrade: StoreUpgradeData = upgrade_resource
		if not upgrade_buttons.has(upgrade.id):
			continue
		var button: Button = upgrade_buttons[upgrade.id]
		var purchased: bool = campaign.purchased_upgrade_ids.has(upgrade.id)
		button.visible = can_offer_unlocks and campaign.day >= upgrade.offer_after_day and not purchased
		button.text = "%s  ·  ₱%d" % [upgrade.display_name, upgrade.purchase_cost]
		button.disabled = purchased or campaign.cash < upgrade.purchase_cost

func _show_shift_summary() -> void:
	summary_backdrop.visible = true
	summary_panel.visible = true
	_update_unlock_buttons()
	if campaign.day < 10:
		summary_title.text = "DAY %d COMPLETE" % campaign.day
		var trust_lost := 0.0
		for customer_id in campaign.customer_trust:
			var starting_trust := float(shift_start_trust.get(customer_id, 100.0))
			trust_lost += maxf(0.0, starting_trust - campaign.get_customer_trust(customer_id))
		var trust_line := "Regulars kept their trust today." if trust_lost <= 0.0 else "Regulars' trust lost: %d points." % int(trust_lost)
		summary_text.text = "%s\n\nSales today: ₱%d\nShelf progress: ₱%d / ₱%d\n%s" % [story.get_day_transition_text(campaign.day), shift.shift_earnings, campaign.get_shelf_goal_progress(), CAMPAIGN_CONFIG.shelf_replacement_goal, trust_line]
		summary_button.text = "START DAY %d" % (campaign.day + 1)
	else:
		summary_title.text = "SUMMER'S END"
		var ending_variant := story.get_ending_variant(campaign.get_shelf_goal_progress(), campaign.count_trusted_regulars(), CAMPAIGN_CONFIG.shelf_replacement_goal, CAMPAIGN_CONFIG.trusted_regular_goal)
		summary_text.text = story.get_ending_text(ending_variant)
		summary_button.text = "SUMMER COMPLETE"
		summary_button.disabled = true

func _on_summary_button_pressed() -> void:
	if not campaign_started:
		campaign_started = true
		summary_backdrop.visible = false
		summary_panel.visible = false
		_begin_shift()
		return
	if campaign.day >= 10:
		return
	summary_unlock_row.visible = false
	campaign.advance_day()
	summary_backdrop.visible = false
	summary_panel.visible = false
	day_label.text = "SUMMER · DAY %d" % campaign.day
	_update_cash(campaign.cash)
	_rebuild_product_shelf()
	_begin_shift()

func _begin_shift() -> void:
	shift_start_cash = campaign.cash
	shift_start_trust = campaign.customer_trust.duplicate(true)
	shift.start_shift()

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _make_box(fill_color: Color, border_color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill_color
	box.border_color = border_color
	box.set_border_width_all(2)
	box.set_corner_radius_all(3)
	box.content_margin_left = 6.0
	box.content_margin_top = 4.0
	box.content_margin_right = 6.0
	box.content_margin_bottom = 4.0
	return box
