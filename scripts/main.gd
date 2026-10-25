extends Control

const CAMPAIGN_CONFIG: CampaignConfig = preload("res://data/story/summer_campaign.tres")
const PRODUCT_DRAG_ITEM_SCENE: PackedScene = preload("res://scenes/product_drag_item.tscn")
const CUSTOMER_ACTOR_SCENE: PackedScene = preload("res://scenes/customer_slot.tscn")
const PRODUCT_ATLAS: Texture2D = preload("res://assets/sprites/kwenta_generic_products.png")
const PORTRAIT_ATLAS: Texture2D = preload("res://assets/sprites/customer_portraits_v2.png")
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
var upgrade_buttons: Dictionary = {}
var customer_layer: Control
var customer_actors: Dictionary = {}
var summary_panel: PanelContainer
var summary_backdrop: ColorRect
var summary_title: Label
var summary_portrait: TextureRect
var summary_speaker: Label
var summary_text: Label
var summary_unlock_row: HBoxContainer
var story_choice_column: VBoxContainer
var summary_button: Button
var bubble: DialogueBubble
var current_choice_data: Dictionary = {}
var current_choice_ids: Array[String] = []
var ui_refresh_elapsed: float = 0.0
var campaign_started: bool = false
var shift_start_cash: int = 0
var shift_start_trust: Dictionary = {}
var displayed_cash: int = -1
var story_beats: Array[Dictionary] = []
var story_beat_index: int = 0
var story_after_action: String = ""
var pending_story_choices: Array[Dictionary] = []
const DEBUG_SKIP_BONUS_CASH := 1000  # e.g. 500 to have money for the upgrade shop after skipping
var shift_in_progress: bool = false
var debug_skip_button: Button
var pending_choice_index: int = 0
var showing_shift_results: bool = false
var story_complete: bool = false
var cash_tray: CashTray

func _ready() -> void:
	campaign = CampaignState.new(CAMPAIGN_CONFIG)
	story = StoryProgression.new(CAMPAIGN_CONFIG)
	for product_resource in CAMPAIGN_CONFIG.product_catalog:
		var product: ProductData = product_resource
		products_by_id[product.id] = product
	_build_customer_area()
	_build_product_layer()
	_build_hud()
	_build_summary_panel()
	_build_bubble()
	_build_cash_tray() 
	_build_debug_tools() 
	_update_cash(campaign.cash)
	_create_shift_manager()
	_rebuild_product_shelf()
	_present_prologue()

func _process(delta: float) -> void:
	if shift != null:
		shift.advance_time(delta)
	ui_refresh_elapsed += delta
	if ui_refresh_elapsed >= 0.12:
		ui_refresh_elapsed = 0.0
		for child in customer_layer.get_children():
			if child is Control and child.has_method("refresh_patience"):
				child.refresh_patience()

# All pixel values in this file are the old 640x360 values x3 (1920x1080 viewport).
func _build_hud() -> void:
	var hud := PanelContainer.new()
	hud.z_index = 30
	hud.position = Vector2(12, 6)
	hud.size = Vector2(1896, 60)
	hud.add_theme_stylebox_override("panel", _make_box(Color(0.13, 0.08, 0.06, 0.96), Color("e7b779")))
	add_child(hud)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 27)
	row.add_theme_constant_override("margin_left", 15)
	row.add_theme_constant_override("margin_right", 15)
	hud.add_child(row)
	day_label = _label("KWENTA · DAY 1", 24, Color("ffe1a7"))
	day_label.custom_minimum_size.x = 336
	row.add_child(day_label)
	clock_label = _label("8:00 AM", 27, Color("fff0cf"))
	clock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(clock_label)
	cash_label = _label("₱150", 27, Color("d9efaa"))
	cash_label.custom_minimum_size.x = 150
	cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(cash_label)
	goal_label = _label("STORY  1/7", 21, Color("e4bd87"))
	goal_label.custom_minimum_size.x = 282
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(goal_label)

func _build_debug_tools() -> void:
	if not OS.is_debug_build():
		return
	debug_skip_button = Button.new()
	debug_skip_button.text = "SKIP DAY  >>"
	debug_skip_button.z_index = 35        # above the HUD (30), below the bubble (50)
	debug_skip_button.position = Vector2(1648, 78)
	debug_skip_button.size = Vector2(260, 56)
	debug_skip_button.focus_mode = Control.FOCUS_NONE
	debug_skip_button.add_theme_font_size_override("font_size", 24)
	for state in ["normal", "hover", "pressed"]:
		debug_skip_button.add_theme_stylebox_override(state, _make_box(Color(0.35, 0.09, 0.09, 0.92), Color("ff8a7a")))
	debug_skip_button.visible = false
	debug_skip_button.pressed.connect(_debug_skip_day)
	add_child(debug_skip_button)

func _debug_skip_day() -> void:
	if shift == null or not shift_in_progress:
		return
	if DEBUG_SKIP_BONUS_CASH > 0:
		campaign.cash += DEBUG_SKIP_BONUS_CASH
		_update_cash(campaign.cash)
	# Run the shift's own clock forward in 5-second steps. When it finishes it emits
	# shift_completed, which calls _show_shift_summary and clears shift_in_progress.
	var guard := 0
	while shift_in_progress and guard < 2000:
		shift.advance_time(5.0)
		guard += 1
	if shift_in_progress:
		push_warning("Skip day: the shift did not complete after fast-forwarding. Check ShiftManager's end condition.")

func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		_debug_skip_day()

func _build_product_layer() -> void:
	product_layer = Control.new()
	product_layer.z_index = 20
	product_layer.position = Vector2.ZERO
	product_layer.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	product_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(product_layer)

func _build_customer_area() -> void:
	# Customers sit in the street window. The scene-owned sill sits above this
	# layer so their lower edge reads as being outside the shop.
	customer_layer = Control.new()
	customer_layer.z_index = 5
	customer_layer.position = Vector2.ZERO
	customer_layer.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	customer_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(customer_layer)

func _build_summary_panel() -> void:
	summary_backdrop = ColorRect.new()
	summary_backdrop.z_index = 40
	summary_backdrop.color = Color(0.04, 0.025, 0.02, 0.62)
	summary_backdrop.position = Vector2.ZERO
	summary_backdrop.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	summary_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	summary_backdrop.visible = false
	add_child(summary_backdrop)
	summary_panel = PanelContainer.new()
	summary_panel.z_index = 41
	summary_panel.position = Vector2(240, 129)
	summary_panel.size = Vector2(1440, 822)
	summary_panel.add_theme_stylebox_override("panel", _make_box(Color(0.16, 0.09, 0.07, 0.98), Color("f0c17b")))
	summary_panel.visible = false
	add_child(summary_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	summary_panel.add_child(column)
	summary_title = _label("SHIFT COMPLETE", 42, Color("ffe1a7"))
	summary_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(summary_title)
	var story_row := HBoxContainer.new()
	story_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_row.add_theme_constant_override("separation", 27)
	column.add_child(story_row)
	summary_portrait = TextureRect.new()
	summary_portrait.custom_minimum_size = Vector2(300, 450)
	summary_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	summary_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	summary_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	summary_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story_row.add_child(summary_portrait)
	var dialogue_column := VBoxContainer.new()
	dialogue_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_column.add_theme_constant_override("separation", 12)
	story_row.add_child(dialogue_column)
	summary_speaker = _label("", 30, Color("f0c17b"))
	dialogue_column.add_child(summary_speaker)
	summary_text = _label("", 30, Color("fff0cf"))
	summary_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_column.add_child(summary_text)
	story_choice_column = VBoxContainer.new()
	story_choice_column.add_theme_constant_override("separation", 9)
	story_choice_column.visible = false
	dialogue_column.add_child(story_choice_column)
	summary_unlock_row = HBoxContainer.new()
	summary_unlock_row.add_theme_constant_override("separation", 18)
	column.add_child(summary_unlock_row)
	for upgrade_resource in CAMPAIGN_CONFIG.store_upgrades:
		var upgrade: StoreUpgradeData = upgrade_resource
		var unlock_button := Button.new()
		unlock_button.custom_minimum_size.y = 72
		unlock_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		unlock_button.add_theme_font_size_override("font_size", 21)
		unlock_button.pressed.connect(_purchase_upgrade.bind(upgrade))
		summary_unlock_row.add_child(unlock_button)
		upgrade_buttons[upgrade.id] = unlock_button
	summary_button = Button.new()
	summary_button.text = "NEXT SHIFT"
	summary_button.custom_minimum_size.y = 78
	summary_button.add_theme_font_size_override("font_size", 30)
	summary_button.pressed.connect(_on_summary_button_pressed)
	column.add_child(summary_button)
	_update_unlock_buttons()

func _build_bubble() -> void:
	bubble = DialogueBubble.new()
	bubble.z_index = 50      # above HUD (30) and the summary panel (40/41)
	bubble.position = Vector2.ZERO
	bubble.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	add_child(bubble)
	bubble.advanced.connect(_on_bubble_advanced)
	bubble.choice_made.connect(_on_bubble_choice) 

func _on_bubble_choice(index: int) -> void:
	if index < 0 or index >= current_choice_ids.size():
		return
	_select_story_choice(current_choice_data, current_choice_ids[index])
	
func _on_bubble_advanced() -> void:
	story_beat_index += 1
	_show_current_story_beat()

func _create_shift_manager() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	shift = ShiftManager.new(campaign, products_by_id, rng)
	shift.active_customer_limit_override = STOREFRONT_LAYOUT.MAX_ACTIVE_WINDOW_CUSTOMERS
	shift.spawn_delay_min_seconds = STOREFRONT_LAYOUT.CUSTOMER_SPAWN_DELAY_MIN_SECONDS
	shift.spawn_delay_max_seconds = STOREFRONT_LAYOUT.CUSTOMER_SPAWN_DELAY_MAX_SECONDS
	shift.patience_seconds_override = STOREFRONT_LAYOUT.CUSTOMER_PATIENCE_SECONDS
	shift.customers_changed.connect(_on_customers_changed)
	shift.customer_timed_out.connect(_on_customer_timed_out)
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
		var item_texture: Texture2D = product.single_unit_texture
		var display_texture: Texture2D = product.stacked_texture
		if item_texture == null or display_texture == null:
			push_error("Product %s is missing its assigned PNG textures." % product.id)
			continue
		drag_item.call("configure", product, item_texture, true, display_size, STOREFRONT_LAYOUT.is_product_rotated(product.id), display_texture, STOREFRONT_LAYOUT.get_stock_count(product.id), product.display_scale)
		drag_item.position = slot.position
		drag_item.size = slot.size
		product_layer.add_child(drag_item)
		drag_item.connect("product_released", _on_product_drag_released)
		product_items_by_id[product.id] = drag_item

func _on_customers_changed() -> void:
	_rebuild_customer_slots()
	_sync_cash_tray()
	
func _on_customer_timed_out(customer_instance_id: String) -> void:
	var actor: Control = customer_actors.get(customer_instance_id)
	if is_instance_valid(actor):
		actor.call("play_annoyed")
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
		var moving_right := leaving.position.x < 960.0
		var exit_tween := create_tween()
		exit_tween.tween_property(leaving, "position:x", 1980.0 if moving_right else -420.0, 0.32)
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
			actor.connect("payment_tapped", _on_payment_tapped)  
			var from_right := randf() < 0.5
			actor.position = Vector2(1980.0 if from_right else -270.0, STOREFRONT_LAYOUT.CUSTOMER_Y)
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
	if not _resolve_product_delivery(customer_id, product_id):
		if is_instance_valid(source):
			source.call("play_reject")

func _on_product_drag_released(product_id: String, viewport_position: Vector2, source: Control) -> void:
	var actor := _customer_actor_at(viewport_position)
	if actor == null:
		source.call("finish_drag", false)
		return
	var customer: CustomerState = actor.get("customer")
	source.call("finish_drag", customer != null and _resolve_product_delivery(customer.instance_id, product_id))

func _customer_actor_at(viewport_position: Vector2) -> Control:
	for instance_id in customer_actors:
		var actor: Control = customer_actors[instance_id]
		if is_instance_valid(actor) and bool(actor.call("contains_drop_point", viewport_position)):
			return actor
	return null

func _resolve_product_delivery(customer_id: String, product_id: String) -> bool:
	if shift == null:
		return false
	var actor: Control = customer_actors.get(customer_id)
	var result := shift.deliver_product(customer_id, product_id)
	if result == OrderState.DeliveryResult.WRONG_PRODUCT or result == CustomerState.DeliveryResult.INACTIVE:
		if is_instance_valid(actor):
			actor.call("play_wrong_drop")
		return false
	if is_instance_valid(actor):
		actor.call("refresh_display")
		actor.call("play_correct_drop")
		if result == OrderState.DeliveryResult.COMPLETED and not _is_waiting_for_change(actor):
			actor.call("play_happy")
	return true

func _update_clock(value: String) -> void:
	clock_label.text = value

func _update_cash(value: int) -> void:
	cash_label.text = "₱%d" % value
	if displayed_cash >= 0 and value > displayed_cash:
		cash_label.pivot_offset = cash_label.size * 0.5
		var pop_tween := create_tween()
		pop_tween.tween_property(cash_label, "scale", Vector2(1.18, 1.18), 0.10)
		pop_tween.tween_property(cash_label, "scale", Vector2.ONE, 0.16)
	displayed_cash = value
	goal_label.text = "STORY  %d/%d" % [campaign.day, CAMPAIGN_CONFIG.campaign_day_count]
	_update_unlock_buttons()

func _update_unlock_buttons() -> void:
	if summary_unlock_row == null:
		return
	var can_offer_unlocks: bool = campaign_started and campaign != null and campaign.day < CAMPAIGN_CONFIG.campaign_day_count
	summary_unlock_row.visible = can_offer_unlocks and showing_shift_results and story_beat_index == 0
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
	shift_in_progress = false                 
	if debug_skip_button != null:             
		debug_skip_button.visible = false     
	showing_shift_results = true
	var summary_text_value := "Tapos ang Day %d.\n\nBenta ngayong araw: ₱%d\nKabuuang pera: ₱%d" % [campaign.day, shift.shift_earnings, campaign.cash]
	if shift.change_total > 0:
		summary_text_value += "\n\nTamang sukli: %d / %d\nPinakamahabang tuloy-tuloy na tama: %d" % [shift.change_correct, shift.change_total, shift.best_change_streak]
	var beats: Array[Dictionary] = [{
		"speaker": "Kuwaderno",
		"portrait": "",
		"text": summary_text_value,
	}]
	beats.append_array(story.get_day_outro_beats(campaign.day))
	_show_story_beats(beats, "DAY %d COMPLETE · %s" % [campaign.day, story.get_day_title(campaign.day)], "day_choices")

func _on_summary_button_pressed() -> void:
	if story_complete:
		_restart_story()
		return
	if not story_choice_column.visible:
		story_beat_index += 1
		_show_current_story_beat()

func _present_prologue() -> void:
	var beats := story.get_prologue_beats()
	beats.append_array(story.get_day_intro_beats(1))
	_show_story_beats(beats, "PROLOGUE · ANG SUSI", "start_shift")

func _present_day_intro() -> void:
	_show_story_beats(story.get_day_intro_beats(campaign.day), "DAY %d · %s" % [campaign.day, story.get_day_title(campaign.day)], "start_shift")

func _show_story_beats(beats: Array[Dictionary], title: String, after_action: String) -> void:
	story_beats = beats
	story_beat_index = 0
	story_after_action = after_action
	summary_title.text = title
	summary_button.visible = true
	summary_button.disabled = false
	story_choice_column.visible = false
	_clear_story_choice_buttons()
	if after_action == "start_shift":
		# Prologue and day intros get the title card ("PROLOGUE · ANG SUSI").
		summary_backdrop.visible = false
		summary_panel.visible = false
		await bubble.title_card(title)
	_show_current_story_beat()

func _show_current_story_beat() -> void:
	if story_beat_index >= story_beats.size():
		_complete_story_beats()
		return
	var beat: Dictionary = story_beats[story_beat_index]
	var speaker: String = str(beat.get("speaker", "Narrator"))
	var portrait_id: String = str(beat.get("portrait", ""))
	var text: String = str(beat.get("text", ""))

	# The first beat after a shift is the earnings notebook + upgrade shop.
	# That stays on the panel for now; everything else is a bubble.
	if showing_shift_results and story_beat_index == 0:
		bubble.close()
		summary_backdrop.visible = true
		summary_panel.visible = true
		summary_speaker.text = speaker
		summary_text.text = text
		summary_button.text = "CONTINUE"
		summary_portrait.visible = false
		_update_unlock_buttons()
		return

	summary_backdrop.visible = false
	summary_panel.visible = false
	var portrait_tex: Texture2D = null
	if not portrait_id.is_empty():
		portrait_tex = COUNTER_ART.customer_portrait(portrait_id, PORTRAIT_ATLAS)
	bubble.show_beat(speaker, text, portrait_tex, portrait_id)
	_update_unlock_buttons()

func _complete_story_beats() -> void:
	match story_after_action:
		"start_shift":
			bubble.close()   
			campaign_started = true
			showing_shift_results = false
			summary_backdrop.visible = false
			summary_panel.visible = false
			_begin_shift()
		"day_choices":
			showing_shift_results = false
			pending_story_choices = story.get_day_choices(campaign.day)
			pending_choice_index = 0
			_show_next_story_choice()
		"next_choice":
			pending_choice_index += 1
			_show_next_story_choice()
		"finish_day":
			_finish_story_day()

func _show_next_story_choice() -> void:
	if pending_choice_index >= pending_story_choices.size():
		var callbacks := story.get_day_callback_beats(campaign.day)
		_show_story_beats(callbacks, "DAY %d · %s" % [campaign.day, story.get_day_title(campaign.day)], "finish_day")
		return
	var choice_data: Dictionary = pending_story_choices[pending_choice_index]
	var labels: Array = []
	var ids: Array[String] = []
	for option_value in choice_data.get("options", []):
		if not option_value is Dictionary:
			continue
		var option: Dictionary = option_value
		labels.append(str(option.get("label", option.get("id", "Choice"))))
		ids.append(str(option.get("id", "")))
	if labels.is_empty():
		pending_choice_index += 1
		_show_next_story_choice()
		return
	summary_backdrop.visible = false
	summary_panel.visible = false
	current_choice_data = choice_data
	current_choice_ids = ids
	var portrait_tex: Texture2D = COUNTER_ART.customer_portrait("tonyo", PORTRAIT_ATLAS)
	bubble.ask("Narrator", str(choice_data.get("prompt", "Ano ang gagawin?")), labels, portrait_tex, "tonyo")

func _select_story_choice(choice_data: Dictionary, option_id: String) -> void:
	var choice_id: String = str(choice_data.get("id", ""))
	if not story.record_choice(choice_id, option_id):
		return
	story_choice_column.visible = false
	_clear_story_choice_buttons()
	var response := story.get_choice_response(choice_data, option_id)
	if response.is_empty():
		pending_choice_index += 1
		_show_next_story_choice()
		return
	_show_story_beats(response, "PILIIN · DAY %d" % campaign.day, "next_choice")

func _clear_story_choice_buttons() -> void:
	if story_choice_column == null:
		return
	for child in story_choice_column.get_children():
		story_choice_column.remove_child(child)
		child.queue_free()

func _finish_story_day() -> void:
	if campaign.day >= CAMPAIGN_CONFIG.campaign_day_count:
		story_complete = true
		bubble.close()                         
		summary_backdrop.visible = true        
		summary_panel.visible = true
		summary_title.text = "KWENTA · WAKAS"
		summary_speaker.text = ""
		summary_text.text = "Kumpleto na ang pitong araw ni Tonyo. Maaari mong ulitin ang kuwento at pumili ng ibang mga sagot."
		summary_portrait.visible = false
		summary_button.visible = true
		summary_button.text = "REPLAY STORY"
		summary_unlock_row.visible = false
		return
	campaign.advance_day()
	day_label.text = "KWENTA · DAY %d" % campaign.day
	_update_cash(campaign.cash)
	_rebuild_product_shelf()
	_present_day_intro()

func _restart_story() -> void:
	for actor in customer_actors.values():
		if is_instance_valid(actor):
			actor.queue_free()
	customer_actors.clear()
	cash_tray.close()
	campaign = CampaignState.new(CAMPAIGN_CONFIG)
	story = StoryProgression.new(CAMPAIGN_CONFIG)
	story_complete = false
	campaign_started = false
	displayed_cash = -1
	_create_shift_manager()
	_rebuild_product_shelf()
	day_label.text = "KWENTA · DAY 1"
	_update_cash(campaign.cash)
	_present_prologue()

func _begin_shift() -> void:
	shift_in_progress = true                  
	if debug_skip_button != null:             
		debug_skip_button.visible = true  
	shift_start_cash = campaign.cash
	shift_start_trust = campaign.customer_trust.duplicate(true)
	shift.patience_seconds_override = 999999.0 if campaign.day == CAMPAIGN_CONFIG.campaign_day_count else STOREFRONT_LAYOUT.CUSTOMER_PATIENCE_SECONDS
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
	box.set_border_width_all(6)
	box.set_corner_radius_all(9)
	box.content_margin_left = 18.0
	box.content_margin_top = 12.0
	box.content_margin_right = 18.0
	box.content_margin_bottom = 12.0
	return box

func _build_cash_tray() -> void:
	cash_tray = CashTray.new()
	cash_tray.z_index = 36          # above the HUD (30), below story panels (40+) and the bubble (50)
	cash_tray.position = Vector2.ZERO
	cash_tray.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	add_child(cash_tray)
	cash_tray.change_given.connect(_on_change_given)

func _on_payment_tapped(customer_id: String) -> void:
	if shift == null:
		return
	for customer in shift.get_active_customers():
		if customer.instance_id == customer_id and customer.is_paying():
			cash_tray.open_for(customer, SukliRules.shows_change_due(campaign.day))
			return

func _on_change_given(customer_id: String, amount: int) -> void:
	if shift == null:
		return
	var actor: Control = customer_actors.get(customer_id)
	var outcome: Dictionary = shift.give_change(customer_id, amount)
	var result: int = int(outcome.get("result", PaymentState.Result.NO_PAYMENT))
	var diff: int = int(outcome.get("diff", 0))
	var at := Vector2(840.0, 200.0)
	if is_instance_valid(actor):
		at = actor.global_position + Vector2(actor.size.x * 0.5 - 90.0, 110.0)
	match result:
		PaymentState.Result.SHORT:
			cash_tray.show_short()
			if is_instance_valid(actor):
				actor.call("play_wrong_drop")
			_float_text(at, "KULANG!", Color("ff8a7a"))
		PaymentState.Result.EXACT:
			cash_tray.close()
			_float_text(at, "TAMA!", Color("d9efaa"))
			if is_instance_valid(actor):
				actor.call("play_happy")
		PaymentState.Result.OVER:
			cash_tray.close()
			_float_text(at, "SOBRA  -₱%d" % diff, Color("f6d95e"))
		_:
			cash_tray.close()

# Closes the tray if the customer it was open for has left or timed out.
func _sync_cash_tray() -> void:
	if cash_tray == null or not cash_tray.is_open() or shift == null:
		return
	for customer in shift.get_active_customers():
		if customer.instance_id == cash_tray.customer_id and customer.is_paying():
			return
	cash_tray.close()

func _is_waiting_for_change(actor: Control) -> bool:
	var customer: CustomerState = actor.get("customer")
	return customer != null and customer.is_paying()

func _float_text(at: Vector2, text: String, color: Color) -> void:
	var label := _label(text, 42, color)
	label.z_index = 45
	label.add_theme_color_override("font_outline_color", Color("2b1a10"))
	label.add_theme_constant_override("outline_size", 8)
	label.position = at
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position:y", at.y - 70.0, 0.9)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.tween_callback(label.queue_free)
