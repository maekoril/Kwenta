extends Control

const CAMPAIGN_CONFIG: CampaignConfig = preload("res://data/story/summer_campaign.tres")
const PRODUCT_DRAG_ITEM_SCENE: PackedScene = preload("res://scenes/product_drag_item.tscn")
const CUSTOMER_ACTOR_SCENE: PackedScene = preload("res://scenes/customer_slot.tscn")
const PRODUCT_ATLAS: Texture2D = preload("res://assets/sprites/kwenta_generic_products.png")
const PORTRAIT_ATLAS: Texture2D = preload("res://assets/sprites/customer_portraits_v2.png")
const COUNTER_ART = preload("res://scripts/counter_art.gd")
const STOREFRONT_LAYOUT = preload("res://scripts/storefront_layout.gd")
const STORE_LAYER_RENDERER = preload("res://scripts/store_layer_renderer.gd")
const KWENTA_AUDIO = preload("res://scripts/kwenta_audio.gd")
const SUMMARY_PANEL_POS := Vector2(240, 129)
const STORE_ATMOSPHERE = preload("res://scripts/store_atmosphere.gd")
const RAIN_STORE_BACKGROUND_PATH := "res://assets/store/kwenta_layer_pack/bg_empty_rain.png"
const FIESTA_BACKGROUND_PATH := "res://assets/store/kwenta_layer_pack/bg_empty_fiesta.png"
const FIESTA_BROWNOUT_BACKGROUND_PATH := "res://assets/store/kwenta_layer_pack/bg_empty_fiesta_brownout.png"
const EVENING_BACKGROUND_PATH := "res://assets/store/kwenta_layer_pack/bg_empty_golden_hour.png"
const NO_GRADE := Color(0.0, 0.0, 0.0, 0.0)
const PAUSE_MENU = preload("res://scripts/pause_menu.gd")
const GAME_OVER_SCREEN = preload("res://scripts/game_over_screen.gd")

var pause_menu: PauseMenu
var campaign: CampaignState
var story: StoryProgression
var shift: ShiftManager
var products_by_id: Dictionary = {}
var clock_label: Label
var cash_label: Label
var day_label: Label
var product_layer: Control
var product_items_by_id: Dictionary = {}
var customer_layer: Control
var store_layer_renderer: StoreLayerRenderer
var customer_actors: Dictionary = {}
var summary_panel: PanelContainer
var summary_backdrop: ColorRect
var summary_title: NotebookTitle
var summary_portrait: TextureRect
var summary_speaker: NotebookEyebrow
var summary_text: NotebookSummary
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
const DEBUG_SKIP_BONUS_CASH := 1000  # e.g. 500 to have money for shelf purchases after skipping
var shift_in_progress: bool = false
var debug_skip_button: Button
var pending_choice_index: int = 0
var showing_shift_results: bool = false
var story_complete: bool = false
var cash_tray: CashTray
var audio: KwentaAudio
var atmosphere
var trust_tag: TrustTag
var game_over_screen   # GameOverScreen (game_over_screen.gd)

var ENVIRONMENT_BY_DAY: Dictionary = {
	1: {"base_path": "", "full_background": false, "evening_path": EVENING_BACKGROUND_PATH, "evening_start_minute": 480, "evening_end_minute": 600, "grade_color": NO_GRADE, "rain_particles": false, "sunbeams": true, "flicker_event": false},
	2: {"base_path": "", "full_background": false, "evening_path": EVENING_BACKGROUND_PATH, "evening_start_minute": 480, "evening_end_minute": 600, "grade_color": NO_GRADE, "rain_particles": false, "sunbeams": true, "flicker_event": false},
	3: {"base_path": "", "full_background": false, "evening_path": EVENING_BACKGROUND_PATH, "evening_start_minute": 480, "evening_end_minute": 600, "grade_color": NO_GRADE, "rain_particles": false, "sunbeams": true, "flicker_event": false},
	4: {"base_path": RAIN_STORE_BACKGROUND_PATH, "full_background": true, "evening_path": "", "grade_color": NO_GRADE, "rain_particles": true, "sunbeams": false, "flicker_event": true},
	5: {"base_path": "", "full_background": false, "evening_path": EVENING_BACKGROUND_PATH, "evening_start_minute": 480, "evening_end_minute": 600, "grade_color": NO_GRADE, "rain_particles": false, "sunbeams": true, "flicker_event": false},
	6: {"base_path": FIESTA_BACKGROUND_PATH, "full_background": true, "evening_path": "", "brownout_path": FIESTA_BROWNOUT_BACKGROUND_PATH, "brownout_at_game_minute": 360, "grade_color": NO_GRADE, "rain_particles": false, "sunbeams": false, "flicker_event": false},
	7: {"base_path": "", "full_background": false, "evening_path": EVENING_BACKGROUND_PATH, "evening_start_minute": 480, "evening_end_minute": 600, "grade_color": NO_GRADE, "rain_particles": false, "sunbeams": true, "flicker_event": false},
}
var flicker_event_day := -1
var environment_flicker_tween: Tween
var brownout_crossfade_tween: Tween
var environment_day := 1
var environment_game_minute := 0
var environment_settings: Dictionary = {}
var environment_textures: Dictionary = {}
var day_six_brownout_triggered := false
var debug_environment_time_override := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	campaign = CampaignState.new(CAMPAIGN_CONFIG)
	story = StoryProgression.new(CAMPAIGN_CONFIG)
	for product_resource in CAMPAIGN_CONFIG.product_catalog:
		var product: ProductData = product_resource
		products_by_id[product.id] = product
	_build_store_layer_renderer()
	audio = KWENTA_AUDIO.new()
	audio.register_default_cues()
	audio.register_default_music()
	add_child(audio)
	atmosphere = STORE_ATMOSPHERE.new()
	add_child(atmosphere)
	_build_environment_layers()
	_build_customer_area()
	_build_product_layer()
	_build_hud()
	_build_summary_panel()
	_build_game_over_screen()
	_build_bubble()
	_build_cash_tray()
	_build_debug_tools()
	pause_menu = PAUSE_MENU.new()
	add_child(pause_menu)
	_update_cash(campaign.cash)
	_create_shift_manager()
	_rebuild_product_shelf()
	apply_environment(campaign.day)
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

func _build_hud() -> void:
	var hud := Control.new()
	hud.z_index = 30
	hud.position = _ui_offset()
	hud.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	day_label = _label("DAY 1", 32, KwentaStyle.INK)
	clock_label = _label("8:00 AM", 32, KwentaStyle.INK)
	cash_label = _label("₱150", 34, Color("2f6b2f"))

	var tags := [
		[day_label, 230.0, KwentaStyle.PAPER, 1.4, 2.8],
		[clock_label, 230.0, KwentaStyle.PAPER, 1.1, 3.3],
		[cash_label, 230.0, Color("e4efc6"), 1.6, 2.5],
	]
	var gap := 36.0
	var total := -gap
	for spec in tags:
		total += float(spec[1]) + gap
	var x := (STOREFRONT_LAYOUT.VIEWPORT_SIZE.x - total) * 0.5
	for spec in tags:
		var tag := HudTag.new().setup(spec[0], float(spec[1]), spec[2], float(spec[3]), float(spec[4]))
		tag.position = Vector2(x, 0.0)
		hud.add_child(tag)
		x += float(spec[1]) + gap
		
	# Suki Meter: hangs from the roof like the other tags (see trust_tag.gd)
	trust_tag = TrustTag.new().setup(campaign.barangay_trust, 260.0, 1.2, 3.0)
	trust_tag.position = Vector2(1648.0, 0.0)
	hud.add_child(trust_tag)
	
func _build_debug_tools() -> void:
	if not OS.is_debug_build():
		return
	debug_skip_button = Button.new()
	debug_skip_button.text = "SKIP DAY  >>"
	debug_skip_button.z_index = 35
	debug_skip_button.position = Vector2(1648, 116) + _ui_offset()
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
	var guard := 0
	while shift_in_progress and guard < 2000:
		shift.advance_time(5.0)
		guard += 1
	if shift_in_progress:
		push_warning("Skip day: the shift did not complete after fast-forwarding.")

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.ctrl_pressed:
		if event.keycode == KEY_0:
			debug_environment_time_override = -1
			return
		if event.keycode == KEY_4:
			_debug_set_environment_time(480)
			return
		if event.keycode == KEY_5:
			_debug_set_environment_time(540)
			return
		if event.keycode == KEY_6:
			_debug_set_environment_time(600)
			return
	if event.keycode >= KEY_1 and event.keycode <= KEY_7:
		apply_environment(int(event.keycode) - int(KEY_0))
		return
	if event.keycode == KEY_F8:
		trigger_day_six_brownout()
		return
	if event.keycode == KEY_F10:
		_debug_skip_day()

func _build_product_layer() -> void:
	product_layer = Control.new()
	product_layer.z_index = 20
	product_layer.position = Vector2.ZERO
	product_layer.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	product_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(product_layer)

func _build_customer_area() -> void:
	customer_layer = Control.new()
	customer_layer.z_index = 5
	customer_layer.position = Vector2.ZERO
	customer_layer.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	customer_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(customer_layer)

func _build_environment_layers() -> void:
	var grade := ColorRect.new()
	grade.name = "WeatherGrade"
	grade.color = NO_GRADE
	grade.position = Vector2.ZERO
	grade.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	grade.z_index = 28
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grade)
	var flicker := ColorRect.new()
	flicker.name = "RainFlicker"
	flicker.color = Color(0.79, 0.87, 1.0, 0.0)
	flicker.position = Vector2.ZERO
	flicker.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	flicker.z_index = 29
	flicker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flicker)

func apply_environment(day: int) -> void:
	environment_day = day
	environment_game_minute = 0
	day_six_brownout_triggered = false
	if brownout_crossfade_tween != null and brownout_crossfade_tween.is_valid():
		brownout_crossfade_tween.kill()
	environment_settings = ENVIRONMENT_BY_DAY.get(day, ENVIRONMENT_BY_DAY[1])
	if audio != null:
		audio.set_ambience(ambience_for_environment_day(day))
		audio.set_music(music_for_environment_day(day))
	_prepare_environment_textures(environment_settings)
	var settings := _runtime_environment_settings("base_path")
	var grade := get_node_or_null("WeatherGrade") as ColorRect
	if grade != null:
		grade.color = environment_settings.get("grade_color", NO_GRADE)
	store_layer_renderer.apply_environment(settings)
	store_layer_renderer.clear_environment_crossfade()
	if bool(environment_settings.get("flicker_event", false)) and flicker_event_day != day:
		_play_environment_flicker()
		flicker_event_day = day
	_update_environment_for_time()

func set_environment_game_minute(game_minute: int) -> void:
	environment_game_minute = clampi(game_minute, 0, 600)
	_update_environment_for_time()

func _prepare_environment_textures(settings: Dictionary) -> void:
	environment_textures.clear()
	for key in ["base_path", "evening_path", "brownout_path"]:
		var path := str(settings.get(key, ""))
		if not path.is_empty():
			environment_textures[key] = load(path) as Texture2D

func _runtime_environment_settings(texture_key: String) -> Dictionary:
	var runtime_settings := environment_settings.duplicate()
	runtime_settings["base_texture"] = environment_textures.get(texture_key) as Texture2D
	return runtime_settings

func _update_environment_for_time() -> void:
	if environment_settings.is_empty():
		return
	var evening_path := str(environment_settings.get("evening_path", ""))
	if not evening_path.is_empty():
		var start := int(environment_settings.get("evening_start_minute", 480))
		var finish := int(environment_settings.get("evening_end_minute", 600))
		var progress := clampf(float(environment_game_minute - start) / float(maxi(1, finish - start)), 0.0, 1.0)
		store_layer_renderer.set_environment_crossfade(environment_textures.get("evening_path") as Texture2D, progress)
		store_layer_renderer.set_front_background_alpha(1.0 - progress)
	else:
		store_layer_renderer.clear_environment_crossfade()
	if environment_day == 6 and not day_six_brownout_triggered and environment_game_minute >= int(environment_settings.get("brownout_at_game_minute", 9999)):
		trigger_day_six_brownout()

func trigger_day_six_brownout() -> void:
	if environment_day != 6 or day_six_brownout_triggered:
		return
	var brownout_texture := environment_textures.get("brownout_path") as Texture2D
	if brownout_texture == null:
		return
	day_six_brownout_triggered = true
	_play_brownout_flicker()
	store_layer_renderer.start_environment_crossfade(brownout_texture, 1.5)
	brownout_crossfade_tween = create_tween()
	brownout_crossfade_tween.tween_interval(1.5)
	brownout_crossfade_tween.tween_callback(_finish_day_six_brownout)

func _finish_day_six_brownout() -> void:
	store_layer_renderer.apply_environment(_runtime_environment_settings("brownout_path"))
	store_layer_renderer.clear_environment_crossfade()

func _debug_set_environment_time(game_minute: int) -> void:
	debug_environment_time_override = clampi(game_minute, 0, 600)
	set_environment_game_minute(debug_environment_time_override)
	_update_clock(_format_game_clock(debug_environment_time_override))

func _play_environment_flicker() -> void:
	var flicker := get_node_or_null("RainFlicker") as ColorRect
	if flicker == null:
		return
	if environment_flicker_tween != null and environment_flicker_tween.is_valid():
		environment_flicker_tween.kill()
	flicker.color.a = 0.0
	environment_flicker_tween = create_tween()
	environment_flicker_tween.tween_interval(0.35)
	environment_flicker_tween.tween_property(flicker, "color:a", 0.24, 0.05)
	environment_flicker_tween.tween_property(flicker, "color:a", 0.06, 0.08)
	environment_flicker_tween.tween_property(flicker, "color:a", 0.0, 0.20)

func _play_brownout_flicker() -> void:
	var flicker := get_node_or_null("RainFlicker") as ColorRect
	if flicker == null:
		return
	if environment_flicker_tween != null and environment_flicker_tween.is_valid():
		environment_flicker_tween.kill()
	flicker.color = Color(0.04, 0.03, 0.07, 0.0)
	environment_flicker_tween = create_tween()
	environment_flicker_tween.tween_property(flicker, "color:a", 0.42, 0.10)
	environment_flicker_tween.tween_property(flicker, "color:a", 0.04, 0.10)
	environment_flicker_tween.tween_property(flicker, "color:a", 0.34, 0.12)
	environment_flicker_tween.tween_property(flicker, "color:a", 0.05, 0.10)
	environment_flicker_tween.tween_property(flicker, "color:a", 0.28, 0.12)
	environment_flicker_tween.tween_property(flicker, "color:a", 0.0, 0.22)

func _build_summary_panel() -> void:
	summary_backdrop = ColorRect.new()
	summary_backdrop.z_index = 40
	summary_backdrop.color = Color(0.04, 0.025, 0.02, 0.5)
	summary_backdrop.position = Vector2(-1000.0, -600.0)
	summary_backdrop.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE + Vector2(2000.0, 1200.0)
	summary_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	summary_backdrop.visible = false
	summary_backdrop.visibility_changed.connect(_on_summary_backdrop_visibility_changed)
	add_child(summary_backdrop)
	summary_panel = PanelContainer.new()
	summary_panel.z_index = 41
	summary_panel.position = SUMMARY_PANEL_POS + _ui_offset()
	summary_panel.size = Vector2(1440, 822)
	var page := KwentaStyle.box(KwentaStyle.PAPER, KwentaStyle.INK, 56.0, 36.0, 12, 6, 12)
	page.content_margin_left = 100.0
	summary_panel.add_theme_stylebox_override("panel", page)
	summary_panel.visible = false
	summary_panel.visibility_changed.connect(_on_summary_panel_visibility_changed)
	add_child(summary_panel)
	var paper := NotebookPaper.new()
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary_panel.add_child(paper)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	summary_panel.add_child(column)

	summary_speaker = NotebookEyebrow.new()
	column.add_child(summary_speaker)
	summary_title = NotebookTitle.new()
	summary_title.text = "SHIFT COMPLETE"
	column.add_child(summary_title)
	var header_rule := ColorRect.new()
	header_rule.color = KwentaStyle.INK
	header_rule.custom_minimum_size = Vector2(0.0, 4.0)
	header_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(header_rule)

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
	summary_text = NotebookSummary.new()
	summary_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_column.add_child(summary_text)
	story_choice_column = VBoxContainer.new()
	story_choice_column.add_theme_constant_override("separation", 9)
	story_choice_column.visible = false
	dialogue_column.add_child(story_choice_column)

	summary_button = Button.new()
	summary_button.text = "NEXT SHIFT"
	summary_button.custom_minimum_size.y = 112
	KwentaStyle.style_button(summary_button, KwentaStyle.GOLD, KwentaStyle.SIZE_BUTTON)
	summary_button.pressed.connect(_on_summary_button_pressed)
	column.add_child(summary_button)

func _on_summary_panel_visibility_changed() -> void:
	if not summary_panel.visible:
		return
	var rest_position := SUMMARY_PANEL_POS + _ui_offset()
	summary_panel.pivot_offset = summary_panel.size * 0.5
	summary_panel.scale = Vector2(0.92, 0.92)
	summary_panel.rotation_degrees = -2.5
	summary_panel.modulate.a = 0.0
	summary_panel.position = rest_position + Vector2(0.0, 50.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(summary_panel, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(summary_panel, "rotation_degrees", 0.0, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(summary_panel, "position", rest_position, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(summary_panel, "modulate:a", 1.0, 0.15)

func _on_summary_backdrop_visibility_changed() -> void:
	if not summary_backdrop.visible:
		return
	summary_backdrop.modulate.a = 0.0
	create_tween().tween_property(summary_backdrop, "modulate:a", 1.0, 0.2)

func _build_bubble() -> void:
	bubble = DialogueBubble.new()
	bubble.z_index = 50
	bubble.position = _ui_offset()
	bubble.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	add_child(bubble)
	bubble.advanced.connect(_on_bubble_advanced)
	bubble.choice_made.connect(_on_bubble_choice)
	bubble.conversation_finished.connect(_on_bubble_conversation_finished)
	bubble.speech_started.connect(_on_bubble_speech_started)

func _on_bubble_choice(index: int) -> void:
	if index < 0 or index >= current_choice_ids.size():
		return
	_select_story_choice(current_choice_data, current_choice_ids[index])

func _on_bubble_advanced() -> void:
	story_beat_index += 1
	_show_current_story_beat()

func _on_bubble_speech_started() -> void:
	if audio != null:
		audio.play_cue("conversation")

func _on_bubble_conversation_finished() -> void:
	if audio != null:
		audio.set_dialogue("")

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
	shift.game_minutes_changed.connect(_on_game_minutes_changed)
	shift.shift_completed.connect(_show_shift_summary)
	shift.barangay_trust_changed.connect(_on_barangay_trust_changed)
	shift.game_over_triggered.connect(_on_game_over)

func _rebuild_product_shelf() -> void:
	if store_layer_renderer != null:
		store_layer_renderer.configure(campaign.day, campaign.cash, campaign.purchased_store_groups)
	for child in product_layer.get_children():
		child.queue_free()
	product_items_by_id.clear()
	var config := StoreConfig.load_config("res://data/store_config.json")
	var stocked_entries := StoreConfig.get_stocked_entries(config, campaign.day, campaign.purchased_store_groups)
	var stocked_game_ids: Array[String] = []
	var shadow_rects: Array[Rect2] = []
	for entry in stocked_entries:
		var store_id := str(entry.get("id", ""))
		var game_id := str(entry.get("game_product_id", ""))
		if game_id.is_empty():
			push_warning("Store product %s has no gameplay product mapping." % store_id)
			continue
		var product: ProductData = products_by_id.get(game_id)
		if product == null:
			push_warning("Store product %s maps to missing gameplay product %s." % [store_id, game_id])
			continue
		stocked_game_ids.append(game_id)
		var slot: Rect2 = store_layer_renderer.get_slot_rect(store_id)
		var display_rect: Rect2 = store_layer_renderer.get_product_display_rect(store_id)
		var drag_item := PRODUCT_DRAG_ITEM_SCENE.instantiate() as Control
		drag_item.call("configure", product, product.single_unit_texture, true, slot.size, false, product.single_unit_texture, 1, 1.0, display_rect.size)
		drag_item.position = slot.position
		drag_item.size = slot.size
		drag_item.modulate.a = 0.0
		product_layer.add_child(drag_item)
		drag_item.connect("product_drag_started", _on_product_drag_started)
		drag_item.connect("product_released", _on_product_drag_released)
		product_items_by_id[game_id] = drag_item
		shadow_rects.append(display_rect)
	campaign.set_stocked_product_ids(stocked_game_ids)
	if atmosphere != null:
		atmosphere.set_product_shadows(shadow_rects)

func _on_customers_changed() -> void:
	_rebuild_customer_slots()
	_sync_cash_tray()

func _on_customer_timed_out(customer_instance_id: String) -> void:
	_play_audio_cues(["timeout"])
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

func _on_product_dropped(customer_id: String, product_id: String) -> void:
	var source: Control = product_items_by_id.get(product_id)
	if not _resolve_product_delivery(customer_id, product_id):
		if is_instance_valid(source):
			source.call("play_reject")

func _on_product_drag_started(_product_id: String) -> void:
	_play_audio_cues(["pickup"])

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
	var sale_completed := result == OrderState.DeliveryResult.COMPLETED and (not is_instance_valid(actor) or not _is_waiting_for_change(actor))
	_play_audio_cues(audio_cues_for_delivery(result, sale_completed))
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

func audio_cues_for_delivery(result: int, sale_completed: bool) -> Array[String]:
	if result == OrderState.DeliveryResult.WRONG_PRODUCT or result == CustomerState.DeliveryResult.INACTIVE:
		return ["reject"]
	var cues: Array[String] = ["correct"]
	if result == OrderState.DeliveryResult.COMPLETED and sale_completed:
		cues.append("sale")
	return cues

func audio_cues_for_payment(result: int) -> Array[String]:
	if result == PaymentState.Result.SHORT:
		return ["reject"]
	if result == PaymentState.Result.EXACT or result == PaymentState.Result.OVER:
		return ["sale"]
	return []

func ambience_for_environment_day(day: int) -> String:
	return ""

func music_for_environment_day(day: int) -> String:
	if day == 4:
		return "rain"
	if day == 6:
		return "intense"
	return "normal"

func _play_audio_cues(cue_names: Array[String]) -> void:
	if audio == null:
		return
	for cue_name in cue_names:
		audio.play_cue(cue_name)

func _update_clock(value: String) -> void:
	clock_label.text = value

func _on_game_minutes_changed(game_minutes: int) -> void:
	if debug_environment_time_override >= 0:
		return
	set_environment_game_minute(game_minutes)

func _format_game_clock(game_minutes: int) -> String:
	var hour := 8 + floori(float(game_minutes) / 60.0)
	var minute := game_minutes % 60
	var display_hour := hour if hour <= 12 else hour - 12
	return "%d:%02d %s" % [display_hour, minute, "AM" if hour < 12 else "PM"]

func _update_cash(value: int) -> void:
	cash_label.text = "₱%d" % value
	if displayed_cash >= 0 and value > displayed_cash:
		cash_label.pivot_offset = cash_label.size * 0.5
		var pop_tween := create_tween()
		pop_tween.tween_property(cash_label, "scale", Vector2(1.18, 1.18), 0.10)
		pop_tween.tween_property(cash_label, "scale", Vector2.ONE, 0.16)
	displayed_cash = value
	if store_layer_renderer != null:
		store_layer_renderer.current_cash = value

func _show_shift_summary() -> void:
	shift_in_progress = false
	pause_menu.set_available(false)
	if debug_skip_button != null:
		debug_skip_button.visible = false

	showing_shift_results = true

	var summary_text_value := "Benta ngayong araw:  %d\nKabuuang pera:  %d" % [shift.shift_earnings, campaign.cash]

	if shift.change_total > 0:
		var avg_satisfaction := int(shift.total_satisfaction_score / shift.change_total)
		summary_text_value += "\n\nCustomer Satisfaction: %d%%" % avg_satisfaction
		if shift.total_tips_earned > 0:
			summary_text_value += "\nTips sa mabilis na sukli:  %d" % shift.total_tips_earned
			
		summary_text_value += "\n\nTamang sukli: %d / %d\nPinakamahabang tuloy-tuloy na tama: %d" % [shift.change_correct, shift.change_total, shift.best_change_streak]

	var beats: Array[Dictionary] = [{
		"speaker": "Kuwaderno",
		"portrait": "",
		"text": summary_text_value,
	}]
	beats.append_array(story.get_day_outro_beats(campaign.day))
	_show_story_beats(beats, "DAY %d COMPLETE   %s" % [campaign.day, story.get_day_title(campaign.day)], "day_choices")

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

	if showing_shift_results and story_beat_index == 0:
		bubble.close()
		summary_backdrop.visible = true
		summary_panel.visible = true
		summary_speaker.text = speaker
		summary_text.text = text
		summary_button.text = "CONTINUE"
		summary_portrait.visible = false
		return

	summary_backdrop.visible = false
	summary_panel.visible = false
	var portrait_tex: Texture2D = null
	if not portrait_id.is_empty():
		portrait_tex = COUNTER_ART.customer_portrait(portrait_id, PORTRAIT_ATLAS)
	bubble.show_beat(speaker, text, portrait_tex, portrait_id)

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
		return
	campaign.advance_day()
	day_label.text = "DAY %d" % campaign.day
	_update_cash(campaign.cash)
	_rebuild_product_shelf()
	apply_environment(campaign.day)
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
	apply_environment(campaign.day)
	day_label.text = "DAY 1"
	_update_cash(campaign.cash)
	_present_prologue()

func _begin_shift() -> void:
	shift_in_progress = true
	pause_menu.set_available(true)
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
	cash_tray.z_index = 36
	cash_tray.position = _ui_offset()
	cash_tray.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	add_child(cash_tray)
	cash_tray.change_given.connect(_on_change_given)

func _on_payment_tapped(customer_id: String) -> void:
	if shift == null:
		return
	for customer in shift.get_active_customers():
		if customer.instance_id == customer_id and customer.is_paying():
			cash_tray.open_for(customer, SukliRules.sukli_guide_enabled_for_day(campaign.day))
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
		at = actor.global_position - global_position + Vector2(actor.size.x * 0.5 - 90.0, 110.0)
	match result:
		PaymentState.Result.SHORT:
			_play_audio_cues(audio_cues_for_payment(result))
			cash_tray.show_short()
			if is_instance_valid(actor):
				actor.call("play_wrong_drop")
			_float_text(at, "KULANG!", Color("ff8a7a"))
		PaymentState.Result.EXACT:
			_play_audio_cues(audio_cues_for_payment(result))
			cash_tray.close()
			_float_text(at, "TAMA!", Color("d9efaa"))
			if is_instance_valid(actor):
				actor.call("play_happy")
		PaymentState.Result.OVER:
			_play_audio_cues(audio_cues_for_payment(result))
			cash_tray.close()
			_float_text(at, "SOBRA  -₱%d" % diff if SukliRules.sukli_guide_enabled_for_day(campaign.day) else "SOBRA!", Color("f6d95e"))
			if is_instance_valid(actor):
				actor.call("play_wrong_drop")
		_:
			cash_tray.close()

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

func _build_store_layer_renderer() -> void:
	store_layer_renderer = STORE_LAYER_RENDERER.new()
	store_layer_renderer.z_index = 0
	add_child(store_layer_renderer)
	store_layer_renderer.purchase_requested.connect(_on_store_purchase_requested)
	store_layer_renderer.purchase_denied.connect(_on_store_purchase_denied)
	store_layer_renderer.configure(campaign.day, campaign.cash, campaign.purchased_store_groups)

func _on_store_purchase_requested(group_id: String) -> void:
	var config := StoreConfig.load_config("res://data/store_config.json")
	for product_id in config.get("products", {}):
		var entry: Dictionary = config.products[product_id]
		if str(entry.get("purchase_group", product_id)) != group_id:
			continue
		if campaign.purchase_store_group(group_id, int(entry.get("price", 0))):
			_update_cash(campaign.cash)
			store_layer_renderer.configure(campaign.day, campaign.cash, campaign.purchased_store_groups)
			_rebuild_product_shelf()
		return

func _on_store_purchase_denied(_group_id: String) -> void:
	var notice := _label("NOT ENOUGH MONEY", 20, Color("ff9d8f"))
	notice.z_index = 45
	notice.position = Vector2(780, 78) + _ui_offset()
	add_child(notice)
	var tween := create_tween()
	tween.tween_property(notice, "position:x", notice.position.x - 10.0, 0.06)
	tween.tween_property(notice, "position:x", notice.position.x + 10.0, 0.12)
	tween.tween_property(notice, "position:x", notice.position.x, 0.06)
	tween.tween_interval(0.8)
	tween.tween_callback(notice.queue_free)

func _ui_offset() -> Vector2:
	return Vector2(maxf(0.0, size.x - STOREFRONT_LAYOUT.VIEWPORT_SIZE.x) * 0.5, 0.0)

func _on_barangay_trust_changed(new_value: float) -> void:
	if is_instance_valid(trust_tag):
		trust_tag.set_trust(new_value)

func _build_game_over_screen() -> void:
	game_over_screen = GAME_OVER_SCREEN.new()
	game_over_screen.z_index = 60      # above the HUD, summary panel and dialogue bubble
	game_over_screen.position = _ui_offset()
	game_over_screen.retry_pressed.connect(_retry_current_day)
	add_child(game_over_screen)

func _on_game_over() -> void:
	if game_over_screen.visible:
		return      # already showing (two customers can trigger it in the same frame)
	shift_in_progress = false
	shift.is_running = false
	bubble.close()
	cash_tray.close()
	summary_backdrop.visible = false
	summary_panel.visible = false
	if debug_skip_button != null:
		debug_skip_button.visible = false
	_play_audio_cues(["timeout"])
	var cora_portrait: Texture2D = COUNTER_ART.customer_portrait("aling_cora", PORTRAIT_ATLAS)
	game_over_screen.present(cora_portrait, campaign.day)

func _retry_current_day() -> void:
	game_over_screen.dismiss()
	
	for actor in customer_actors.values():
		if is_instance_valid(actor): actor.queue_free()
	customer_actors.clear()
	cash_tray.close()
	
	campaign.cash = shift_start_cash
	campaign.customer_trust = shift_start_trust.duplicate(true)
	campaign.barangay_trust = 100.0
	_on_barangay_trust_changed(100.0)
	
	campaign_started = false
	showing_shift_results = false
	summary_backdrop.visible = false
	summary_panel.visible = false
	
	_update_cash(campaign.cash)
	_rebuild_product_shelf()
	apply_environment(campaign.day)
	
	_present_day_intro()
