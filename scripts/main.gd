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
const INTERACTIVE_TUTORIAL_OVERLAY = preload("res://scripts/interactive_tutorial_overlay.gd")
const DAILY_GOAL = preload("res://scripts/daily_goal.gd")
const DAY_BRIEFING = preload("res://scripts/day_briefing.gd")
const BRIEFING_CARD = preload("res://scripts/briefing_card.gd")
const NOTEBOOK_SCROLL = preload("res://scripts/notebook_scroll.gd")
const NOTEBOOK_ACTION_BUTTON_BACKGROUND_TEXTURE: Texture2D = preload("res://assets/sprites/ui/sukli/sized/ibigay_button.png")
const PAUSE_MENU = preload("res://scripts/pause_menu.gd")
const OPTION5_SUKI = preload("res://scripts/option5_suki.gd")
const HUD_ICON = preload("res://scripts/hud_icon.gd")
const SHIFT_STORY_EVENTS = preload("res://scripts/shift_story_events.gd")
const SHOP_BUTTON_TEXTURE: Texture2D = preload("res://assets/sprites/ui/sukli/sized/ibigay_button.png")
const SHOP_ICON_TEXTURE: Texture2D = preload("res://assets/sprites/ui/shop/lucide_store.svg")
const SHOP_GRACE_DURATION_SECONDS := 60.0
const SUMMARY_PANEL_POS := Vector2(240, 129)
const STORE_ATMOSPHERE = preload("res://scripts/store_atmosphere.gd")
const RAIN_STORE_BACKGROUND_PATH := "res://assets/store/kwenta_layer_pack/bg_empty_rain.png"
const FIESTA_BACKGROUND_PATH := "res://assets/store/kwenta_layer_pack/bg_empty_fiesta.png"
const FIESTA_BROWNOUT_BACKGROUND_PATH := "res://assets/store/kwenta_layer_pack/bg_empty_fiesta_brownout.png"
const EVENING_BACKGROUND_PATH := "res://assets/store/kwenta_layer_pack/bg_empty_golden_hour.png"
const NO_GRADE := Color(0.0, 0.0, 0.0, 0.0)
const GAME_OVER_SCREEN = preload("res://scripts/game_over_screen.gd")
const DAY_FOCUS_HINTS := {
	1: "Drag a product from the shelf to the customer who ordered it.",
	2: "Shop before opening. Today, give the correct sukli after each sale.",
	3: "Practice multi-item orders. More customers are starting to overlap.",
	4: "Rain makes customers less patient. Serve the shortest bar first.",
	5: "Keep your regulars happy during the Mini-Save rush.",
	6: "Fiesta rush! Up to five customers can wait at once.",
	7: "Final day: take your time. Customers will not lose trust today.",
}

var campaign: CampaignState
var pause_menu: PauseMenu
var briefing_card: BriefingCard
var story_events: ShiftStoryEvents
var choices_before_shift := false
var _blocked_input_nodes: Array[Dictionary] = []
var story: StoryProgression
var shift: ShiftManager
var products_by_id: Dictionary = {}
var clock_label: Label
var cash_label: Label
var day_label: Label
var goal_label: Label
var goal_count_label: Label
var goal_panel: PanelContainer
var goal_progress: ProgressBar
var goal_progress_fill: StyleBoxFlat
var product_layer: Control
var product_items_by_id: Dictionary = {}
var customer_layer: Control
var store_layer_renderer: StoreLayerRenderer
var shelf_shop: ShelfShopModal
var shop_button: Button
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
var shop_available: bool = false
var shop_grace_remaining_seconds := 0.0
var debug_skip_button: Button
var pending_choice_index: int = 0
var showing_shift_results: bool = false
var shift_summary_beat_index := -1
var pending_shift_summary_text := ""
var pending_shift_summary_title := ""
var showing_post_shift_summary := false
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
var tutorial_hint: Label
var tutorial_hint_tween: Tween
var tutorial_delivery_seen := false
var tutorial_overlay: InteractiveTutorialOverlay
var tutorial_step := TutorialStep.NONE
var tutorial_product_id := ""
var tutorial_customer_id := ""
var tutorial_change_due := 0
var tutorial_payment_tender := 0
var tutorial_payment_total := 0
var day_two_sukli_tutorial_complete := false
var daily_goal
var daily_goal_day := 0
var showing_pre_shift_briefing := false

enum TutorialStep { NONE, DAY1_PRODUCT, DAY1_CUSTOMER, DAY2_SHOP, DAY2_MONEY, DAY2_GIVE }
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
	_ensure_daily_goal()
	_refresh_daily_goal_hud()  # A useful goal preview even during the intro.
	_build_tutorial_hint()
	_build_interactive_tutorial_overlay()
	_build_summary_panel()
	_build_briefing_card()
	_build_game_over_screen()
	_build_bubble()
	_build_cash_tray()
	_build_shop_button()
	# Skip Day is intentionally hidden; keep the debug helper for developers only.
	pause_menu = PAUSE_MENU.new()
	add_child(pause_menu)
	pause_menu.place_button(Vector2(1795.0, 11.0) + _ui_offset())
	# Compact button dimensions for the Option 5 bar.
	pause_menu.get_child(0).get_child(0).size = Vector2(89.0, 74.0)
	_update_cash(campaign.cash)
	_create_shift_manager()
	_build_story_events()
	_rebuild_product_shelf()
	apply_environment(campaign.day)
	_present_prologue()
	pause_menu.set_available(true)  # Keep the framed Pause control visible during the intro.

func _process(delta: float) -> void:
	if shift != null and shift_in_progress:
		shift.advance_time(delta)
		if shop_grace_remaining_seconds > 0.0:
			shop_grace_remaining_seconds = maxf(0.0, shop_grace_remaining_seconds - delta)
			if is_zero_approx(shop_grace_remaining_seconds):
				_refresh_shop_button()
	ui_refresh_elapsed += delta
	if ui_refresh_elapsed >= 0.12:
		ui_refresh_elapsed = 0.0
		for child in customer_layer.get_children():
			if child is Control and child.has_method("refresh_patience"):
				child.refresh_patience()

func _build_hud() -> void:
	# Option 5: a small, intentional top strip, not the oversized Option 2 board.
	# Exact coordinates are authored against the original 1920 x 1080 game canvas.
	var hud := Control.new()
	hud.name = "GameplayHUDOption5"
	hud.z_index = 30
	hud.position = _ui_offset()
	hud.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	const Y := 11.0
	const H := 74.0

	# Left objective chip: icon + LIVE progress + count (no oversized heading).
	goal_panel = PanelContainer.new()
	goal_panel.name = "DailyGoalHud"
	goal_panel.position = Vector2(33.0, Y)
	goal_panel.size = Vector2(399.0, H)
	goal_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	goal_panel.tooltip_text = "Today's objective"
	goal_panel.add_theme_stylebox_override("panel", _option5_frame("dark_capsule.png", 22.0, 12.0))
	hud.add_child(goal_panel)
	var goal_row := HBoxContainer.new()
	goal_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_row.alignment = BoxContainer.ALIGNMENT_CENTER
	goal_row.add_theme_constant_override("separation", 9)
	goal_panel.add_child(goal_row)
	goal_row.add_child(_option5_icon("customers.png", 46.0))

	# Keep the real goal title object so the existing update logic still works;
	# expose its full text in the capsule tooltip instead of crowding the HUD.
	goal_label = _label("", 20, Color("fff0d0"))
	goal_label.name = "DailyGoalTitle"
	goal_label.visible = false
	goal_row.add_child(goal_label)

	goal_progress = ProgressBar.new()
	goal_progress.name = "DailyGoalProgress"
	goal_progress.custom_minimum_size = Vector2(174.0, 22.0)
	goal_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goal_progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	goal_progress.show_percentage = false
	goal_progress.min_value = 0.0
	var goal_track := StyleBoxFlat.new()
	goal_track.bg_color = Color("1b0f0b")
	goal_track.border_color = Color("b4783d")
	goal_track.set_border_width_all(2)
	goal_track.set_corner_radius_all(10)
	goal_progress_fill = StyleBoxFlat.new()
	goal_progress_fill.bg_color = Color("f3c64b")
	goal_progress_fill.set_corner_radius_all(9)
	goal_progress.add_theme_stylebox_override("background", goal_track)
	goal_progress.add_theme_stylebox_override("fill", goal_progress_fill)
	goal_row.add_child(goal_progress)

	goal_count_label = _label("", 26, Color("fff0d0"))
	goal_count_label.name = "DailyGoalCount"
	goal_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	goal_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	goal_count_label.custom_minimum_size = Vector2(64.0, 0.0)
	goal_row.add_child(goal_count_label)

	# Three distinct cream chips — day, time, cash — matching the user's Option 5.
	day_label = _option5_stat(hud, "DayChip", Vector2(672, Y), Vector2(149, H), "calendar.png", "D1", 27, KwentaStyle.INK, 35.0)
	clock_label = _option5_stat(hud, "TimeChip", Vector2(835, Y), Vector2(169, H), "clock.png", "8:00", 27, KwentaStyle.INK, 34.0)
	cash_label = _option5_stat(hud, "CashChip", Vector2(1018, Y), Vector2(178, H), "peso.png", "150", 27, KwentaStyle.MONEY, 35.0)

	# Live suki animation remains controlled by the existing trust update calls.
	trust_tag = OPTION5_SUKI.new().setup(campaign.barangay_trust, 372.0, 0.0, 3.0, false)
	trust_tag.position = Vector2(1401.0, Y)
	hud.add_child(trust_tag)

func _option5_frame(sprite_name: String, content_x: float = 13.0, content_y: float = 8.0) -> StyleBoxTexture:
	var frame := StyleBoxTexture.new()
	frame.texture = load("res://assets/sprites/ui/hud_v5/" + sprite_name) as Texture2D
	frame.texture_margin_left = 30.0
	frame.texture_margin_right = 30.0
	frame.texture_margin_top = 22.0
	frame.texture_margin_bottom = 22.0
	frame.content_margin_left = content_x
	frame.content_margin_right = content_x
	frame.content_margin_top = content_y
	frame.content_margin_bottom = content_y
	return frame

func _option5_icon(sprite_name: String, icon_size: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = "Icon_" + sprite_name.get_basename()
	icon.texture = load("res://assets/sprites/ui/hud_v5/" + sprite_name) as Texture2D
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _option5_stat(parent: Control, node_name: String, pos: Vector2, dims: Vector2, sprite: String, starting_text: String, font_size: int, text_color: Color, icon_size: float) -> Label:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.position = pos
	panel.size = dims
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override(
		"panel",
		_option5_frame("cream_capsule.png", 20.0, 12.0)
	)
	parent.add_child(panel)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var icon := _option5_icon(sprite, icon_size)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var label := _label(starting_text, font_size, text_color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.clip_text = false
	row.add_child(label)

	return label


func _hud_divider() -> ColorRect:
	var divider := ColorRect.new()
	divider.color = Color("bb8f65")
	divider.custom_minimum_size = Vector2(3.0, 48.0)
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return divider

func _refresh_daily_goal_hud() -> void:
	if goal_label == null or goal_count_label == null or daily_goal == null:
		return
	goal_label.text = daily_goal.title.to_upper()
	goal_panel.tooltip_text = daily_goal.title + ' - ' + daily_goal.progress_text()
	goal_count_label.text = daily_goal.progress_text()
	goal_progress.max_value = maxf(1.0, float(daily_goal.target))
	if daily_goal.is_no_timeout_goal():
		goal_progress.value = 0.0 if daily_goal.timed_out else float(daily_goal.target)
		goal_progress_fill.bg_color = Color("d94536") if daily_goal.timed_out else Color("f5b83d")
	else:
		goal_progress.value = float(daily_goal.current)
		goal_progress_fill.bg_color = Color("4caa56") if daily_goal.is_complete() else Color("f5b83d")
	goal_progress.queue_redraw()

func _build_tutorial_hint() -> void:
	tutorial_hint = _label("", 28, Color("fff1b8"))
	tutorial_hint.name = "TutorialHint"
	tutorial_hint.z_index = 46
	tutorial_hint.position = Vector2(360.0, 140.0) + _ui_offset()
	tutorial_hint.size = Vector2(1170.0, 80.0)
	var hint_box := StyleBoxFlat.new()          # dark-wood pill so the tip reads on any background
	hint_box.bg_color = Color("3a2116", 0.94)
	hint_box.border_color = Color("dca842")
	hint_box.set_border_width_all(3)
	hint_box.set_corner_radius_all(10)
	hint_box.content_margin_left = 22.0
	hint_box.content_margin_right = 22.0
	hint_box.content_margin_top = 6.0
	hint_box.content_margin_bottom = 6.0
	tutorial_hint.add_theme_stylebox_override("normal", hint_box)
	tutorial_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_hint.add_theme_color_override("font_outline_color", Color("2b1a10"))
	tutorial_hint.add_theme_constant_override("outline_size", 7)
	tutorial_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_hint.visible = false
	add_child(tutorial_hint)

func _build_interactive_tutorial_overlay() -> void:
	tutorial_overlay = INTERACTIVE_TUTORIAL_OVERLAY.new()
	tutorial_overlay.name = "InteractiveTutorialOverlay"
	tutorial_overlay.position = _ui_offset()
	tutorial_overlay.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	add_child(tutorial_overlay)

func _tutorial_rect_for(target: Control) -> Rect2:
	if not is_instance_valid(target) or tutorial_overlay == null:
		return Rect2()
	var rect := target.get_global_rect()
	rect.position -= tutorial_overlay.global_position
	return rect

func _show_tutorial_spotlight(step: int, message: String, target: Control, step_title: String = "GUIDE") -> void:
	if tutorial_overlay == null or not is_instance_valid(target):
		return
	tutorial_step = step
	tutorial_overlay.show_step(message, _tutorial_rect_for(target), step_title)

func _clear_tutorial_spotlight() -> void:
	tutorial_step = TutorialStep.NONE
	tutorial_product_id = ""
	tutorial_customer_id = ""
	tutorial_change_due = 0
	tutorial_payment_tender = 0
	tutorial_payment_total = 0
	if tutorial_overlay != null:
		tutorial_overlay.clear_step()

func _show_tutorial_hint(message: String, seconds: float = 5.0) -> void:
	if tutorial_hint == null or message.is_empty():
		return
	if tutorial_hint_tween != null and tutorial_hint_tween.is_valid():
		tutorial_hint_tween.kill()
	tutorial_hint.text = message
	tutorial_hint.modulate.a = 1.0
	tutorial_hint.visible = true
	tutorial_hint_tween = create_tween()
	tutorial_hint_tween.tween_interval(seconds)
	tutorial_hint_tween.tween_property(tutorial_hint, "modulate:a", 0.0, 0.35)
	tutorial_hint_tween.tween_callback(tutorial_hint.hide)

func _build_shop_button() -> void:
	shop_button = Button.new()
	shop_button.name = "ShopIconButton"
	shop_button.position = Vector2(1820, 132) + _ui_offset()   # below the taller top HUD, no pause overlap
	shop_button.size = Vector2(72, 72)
	shop_button.z_index = 55
	shop_button.z_as_relative = false
	shop_button.add_theme_stylebox_override("normal", _button_texture_box(SHOP_BUTTON_TEXTURE))
	shop_button.add_theme_stylebox_override("hover", _button_texture_box(SHOP_BUTTON_TEXTURE))
	shop_button.add_theme_stylebox_override("pressed", _button_texture_box(SHOP_BUTTON_TEXTURE))
	shop_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	shop_button.focus_mode = Control.FOCUS_NONE
	shop_button.tooltip_text = "Open shop before the shift"
	shop_button.visible = false
	var shop_icon := TextureRect.new()
	shop_icon.name = "ShopIcon"
	shop_icon.texture = SHOP_ICON_TEXTURE
	shop_icon.position = Vector2(16, 16)
	shop_icon.size = Vector2(40, 40)
	shop_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shop_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shop_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_button.add_child(shop_icon)
	shop_icon.set_anchors_preset(Control.PRESET_TOP_LEFT)
	shop_icon.offset_left = 16.0
	shop_icon.offset_top = 16.0
	shop_icon.offset_right = 56.0
	shop_icon.offset_bottom = 56.0
	shop_button.pressed.connect(_open_shelf_shop)
	add_child(shop_button)

func _build_debug_tools() -> void:
	if not OS.is_debug_build():
		return
	debug_skip_button = Button.new()
	debug_skip_button.text = "SKIP DAY  >>"
	debug_skip_button.z_index = 35
	debug_skip_button.position = Vector2(1552, 116) + _ui_offset()
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
	var body_scroll = NOTEBOOK_SCROLL.new()
	body_scroll.name = "NotebookBodyScroll"
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.custom_minimum_size = Vector2(0.0, 360.0)
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	story_row.add_child(body_scroll)
	var dialogue_column := VBoxContainer.new()
	dialogue_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_column.add_theme_constant_override("separation", 12)
	body_scroll.add_child(dialogue_column)
	summary_text = NotebookSummary.new()
	summary_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_column.add_child(summary_text)
	story_choice_column = VBoxContainer.new()
	story_choice_column.add_theme_constant_override("separation", 9)
	story_choice_column.visible = false
	dialogue_column.add_child(story_choice_column)

	summary_button = Button.new()
	summary_button.text = "NEXT SHIFT"
	summary_button.custom_minimum_size.y = 112
	summary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_notebook_action_button_style(summary_button)
	summary_button.pressed.connect(_on_summary_button_pressed)
	column.add_child(summary_button)

func apply_notebook_action_button_style(button: Button) -> void:
	KwentaStyle.style_button(button, KwentaStyle.GOLD, KwentaStyle.SIZE_BUTTON)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var action_button_style := StyleBoxTexture.new()
	action_button_style.texture = NOTEBOOK_ACTION_BUTTON_BACKGROUND_TEXTURE
	action_button_style.content_margin_left = 26.0
	action_button_style.content_margin_right = 26.0
	action_button_style.content_margin_top = 16.0
	action_button_style.content_margin_bottom = 16.0
	button.add_theme_stylebox_override("normal", action_button_style)
	button.add_theme_stylebox_override("hover", action_button_style)
	button.add_theme_stylebox_override("pressed", action_button_style)

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
	# Campaign data controls the customer ramp. The storefront supports up to five.
	shift.active_customer_limit_override = 0
	shift.spawn_delay_min_seconds = 0.0
	shift.spawn_delay_max_seconds = 0.0
	shift.patience_seconds_override = 0.0
	shift.customers_changed.connect(_on_customers_changed)
	shift.customer_timed_out.connect(_on_customer_timed_out)
	shift.customer_served.connect(_on_customer_served)
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
	if daily_goal != null:
		daily_goal.record_timeout()
		_refresh_daily_goal_hud()
	_play_audio_cues(["timeout"])
	var actor: Control = customer_actors.get(customer_instance_id)
	if is_instance_valid(actor):
		actor.call("play_annoyed")

func _on_customer_served(_customer_id: String, order_units: int) -> void:
	if daily_goal == null:
		return
	var was_complete: bool = daily_goal.is_complete()
	daily_goal.record_customer_served(order_units)
	_refresh_daily_goal_hud()
	if not was_complete and daily_goal.is_complete():
		_float_text(Vector2(760.0, 270.0), "GOAL COMPLETE!", Color("d9efaa"))

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
	if campaign.day != 1 or tutorial_step != TutorialStep.DAY1_PRODUCT or _product_id != tutorial_product_id:
		return
	var actor: Control = customer_actors.get(tutorial_customer_id)
	if is_instance_valid(actor):
		_show_tutorial_spotlight(TutorialStep.DAY1_CUSTOMER, "Now drop it on the highlighted customer.", actor)

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
	if campaign.day == 1 and tutorial_step == TutorialStep.DAY1_CUSTOMER and customer_id == tutorial_customer_id and product_id == tutorial_product_id:
		tutorial_delivery_seen = true
		_clear_tutorial_spotlight()
		_show_tutorial_hint("Good! Serve every icon in the bubble before patience runs out.")
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
	# Short clock reading, like the requested Option 5.
	clock_label.text = value.trim_suffix(' AM').trim_suffix(' PM')

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
	cash_label.text = "%d" % value
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
	if story_events != null:
		story_events.end_shift()
	if pause_menu != null:
		pause_menu.set_available(false)
	if debug_skip_button != null:
		debug_skip_button.visible = false
	showing_shift_results = false
	if daily_goal != null:
		daily_goal.finalize(campaign.count_trusted_regulars())
		_refresh_daily_goal_hud()
	var summary_text_value := "TODAY'S SALES\nBenta ngayong araw: ₱%d\nKabuuang pera: ₱%d\nCustomers served: %d\nCustomers left: %d" % [shift.shift_earnings, campaign.cash, shift.customers_served, shift.customers_timed_out]
	if daily_goal != null:
		var goal_status := "COMPLETED · %s" % daily_goal.reward if daily_goal.is_complete() else "Not completed — no penalty"
		summary_text_value += "\n\nDAILY GOAL\n%s: %s" % [daily_goal.title, goal_status]
	if shift.change_total > 0:
		summary_text_value += "\n\nSUKLI\nTamang sukli: %d / %d\nPinakamahabang tuloy-tuloy na tama: %d" % [shift.change_correct, shift.change_total, shift.best_change_streak]
	if shift.change_total > 0:
		var avg_satisfaction := int(shift.total_satisfaction_score / shift.change_total)
		summary_text_value += "\nCustomer Satisfaction: %d%%" % avg_satisfaction
		if shift.total_tips_earned > 0:
			summary_text_value += "\nTips sa mabilis na sukli: ₱%d" % shift.total_tips_earned
	pending_shift_summary_text = summary_text_value
	pending_shift_summary_title = "DAY %d COMPLETE · %s" % [campaign.day, story.get_day_title(campaign.day)]
	_show_story_beats(story.get_day_outro_beats(campaign.day), pending_shift_summary_title, "day_choices")

func _on_summary_button_pressed() -> void:
	if story_complete:
		_restart_story()
		return
	if showing_pre_shift_briefing:
		showing_pre_shift_briefing = false
		summary_backdrop.visible = false
		summary_panel.visible = false
		if campaign.day == 2 and shop_available:
			_begin_day_two_shop_tutorial()
		else:
			_begin_shift()
		return
	if showing_post_shift_summary:
		showing_post_shift_summary = false
		summary_backdrop.visible = false
		summary_panel.visible = false
		_advance_story_day()
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


	# A beat can carry "cash" (e.g. a tip) that is paid out when the beat appears.
	var bonus := int(beat.get("cash", 0))
	if bonus != 0:
		campaign.cash += bonus
		_update_cash(campaign.cash)

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
			var intro_choices := story.get_day_intro_choices(campaign.day)
			if not intro_choices.is_empty():
				choices_before_shift = true
				pending_story_choices = intro_choices
				pending_choice_index = 0
				_show_next_story_choice()
				return
			_show_pre_shift_briefing()
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
		if choices_before_shift:
			choices_before_shift = false
			_show_pre_shift_briefing()
			return
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
	var cash_delta := story.get_choice_cash_delta(choice_data, option_id)
	if cash_delta != 0:
		campaign.cash += cash_delta
		_update_cash(campaign.cash)
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
	if not pending_shift_summary_text.is_empty():
		_show_pending_shift_summary()
		return
	_advance_story_day()

func _show_pending_shift_summary() -> void:
	bubble.close()
	showing_post_shift_summary = true
	summary_title.text = pending_shift_summary_title
	summary_speaker.text = "KUWADERNO"
	summary_text.text = pending_shift_summary_text
	summary_button.text = "CONTINUE"
	summary_button.visible = true
	summary_button.disabled = false
	summary_portrait.visible = false
	summary_backdrop.visible = true
	summary_panel.visible = true
	pending_shift_summary_text = ""
	pending_shift_summary_title = ""

func _advance_story_day() -> void:
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
	shop_available = campaign.day > 1
	_refresh_shop_button()
	day_label.text = "D%d" % campaign.day
	_ensure_daily_goal()
	_refresh_daily_goal_hud()
	_update_cash(campaign.cash)
	_rebuild_product_shelf()
	apply_environment(campaign.day)
	_present_day_intro()
	if pause_menu != null:
		pause_menu.set_available(true)

func _restart_story() -> void:
	for actor in customer_actors.values():
		if is_instance_valid(actor):
			actor.queue_free()
	customer_actors.clear()
	cash_tray.close()
	campaign = CampaignState.new(CAMPAIGN_CONFIG)
	story = StoryProgression.new(CAMPAIGN_CONFIG)
	story_complete = false
	choices_before_shift = false
	day_two_sukli_tutorial_complete = false
	daily_goal = null
	daily_goal_day = 0
	showing_pre_shift_briefing = false
	if briefing_card != null:
		briefing_card.hide_briefing()
	showing_post_shift_summary = false
	pending_shift_summary_text = ""
	pending_shift_summary_title = ""
	_clear_tutorial_spotlight()
	campaign_started = false
	shop_available = false
	_refresh_shop_button()
	displayed_cash = -1
	_ensure_daily_goal()
	_refresh_daily_goal_hud()
	_create_shift_manager()
	_build_story_events()
	_rebuild_product_shelf()
	apply_environment(campaign.day)
	day_label.text = "D1"
	_update_cash(campaign.cash)
	_present_prologue()
	if pause_menu != null:
		pause_menu.set_available(true)

func _ensure_daily_goal() -> void:
	if daily_goal == null or daily_goal_day != campaign.day:
		daily_goal = DAILY_GOAL.new(campaign.day)
		daily_goal_day = campaign.day

func _build_briefing_card() -> void:
	briefing_card = BRIEFING_CARD.new()
	briefing_card.position = _ui_offset()
	briefing_card.start_pressed.connect(_on_briefing_start_pressed)
	add_child(briefing_card)

func _on_briefing_start_pressed() -> void:
	briefing_card.hide_briefing()
	_on_summary_button_pressed()

func _show_pre_shift_briefing() -> void:
	_ensure_daily_goal()
	var briefing = DAY_BRIEFING.new(campaign.day, daily_goal, CAMPAIGN_CONFIG.product_catalog)
	showing_pre_shift_briefing = true
	summary_panel.visible = false
	summary_backdrop.visible = true
	briefing_card.show_briefing(briefing, STOREFRONT_LAYOUT.VIEWPORT_SIZE)

func _begin_shift() -> void:
	shop_available = false
	shop_grace_remaining_seconds = SHOP_GRACE_DURATION_SECONDS
	shift_in_progress = true
	_refresh_shop_button()
	if pause_menu != null:
		pause_menu.set_available(true)
	if debug_skip_button != null:
		debug_skip_button.visible = true
	shift_start_cash = campaign.cash
	shift_start_trust = campaign.customer_trust.duplicate(true)
	_ensure_daily_goal()
	_refresh_daily_goal_hud()
	tutorial_delivery_seen = false
	# Keep the campaign's day-by-day patience curve, then layer story-choice
	# consequences on top of it.
	var modifiers := story.get_day_modifiers(campaign.day)
	var patience := campaign.get_customer_patience_seconds() * float(modifiers.get("patience_mult", 1.0))
	shift.patience_seconds_override = 999999.0 if campaign.day == CAMPAIGN_CONFIG.campaign_day_count else patience
	if story_events != null:
		story_events.begin_shift(campaign.day)
	shift.start_shift()
	if campaign.day == 1:
		_begin_day_one_drag_tutorial()
	elif campaign.day >= 3:
		_show_tutorial_hint(str(DAY_FOCUS_HINTS.get(campaign.day, "")))

func _begin_day_one_drag_tutorial() -> void:
	var active := shift.get_active_customers()
	if active.is_empty():
		return
	var customer: CustomerState = active[0]
	for product_id in customer.order.requested:
		var product: Control = product_items_by_id.get(str(product_id))
		if is_instance_valid(product):
			tutorial_product_id = str(product_id)
			tutorial_customer_id = customer.instance_id
			_show_tutorial_spotlight(TutorialStep.DAY1_PRODUCT, "Drag the highlighted product to the customer.", product)
			return

func _begin_day_two_shop_tutorial() -> void:
	if not is_instance_valid(shop_button):
		_begin_shift()
		return
	_show_tutorial_spotlight(TutorialStep.DAY2_SHOP, "Tap the shop. You can browse upgrades before opening.", shop_button)

func _on_shelf_shop_closed() -> void:
	if tutorial_step != TutorialStep.DAY2_SHOP:
		return
	_clear_tutorial_spotlight()
	_begin_shift()

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _build_story_events() -> void:
	if story_events == null:
		story_events = SHIFT_STORY_EVENTS.new()
		add_child(story_events)
		story_events.remark_requested.connect(_show_customer_remark)
		story_events.popup_state_changed.connect(_set_shop_input_blocked)
	story_events.bind(story, shift, bubble, PORTRAIT_ATLAS)
	move_child(bubble, get_child_count() - 1)

func _set_shop_input_blocked(blocked: bool) -> void:
	if blocked:
		if not _blocked_input_nodes.is_empty():
			return
		get_viewport().gui_cancel_drag()
		for layer in [customer_layer, product_layer, cash_tray, store_layer_renderer]:
			if layer != null:
				_block_input_in(layer, true)
		return
	for entry in _blocked_input_nodes:
		var node_ref = entry["node"]
		if not is_instance_valid(node_ref):
			continue
		var node: Node = node_ref
		node.set_process_input(bool(entry["input"]))
		node.set_process_unhandled_input(bool(entry["unhandled"]))
		node.set_process_unhandled_key_input(bool(entry["key"]))
		if entry.has("mouse"):
			(node as Control).mouse_behavior_recursive = int(entry["mouse"]) as Control.MouseBehaviorRecursive
	_blocked_input_nodes.clear()

func _block_input_in(node: Node, is_root: bool) -> void:
	var entry := {
		"node": node,
		"input": node.is_processing_input(),
		"unhandled": node.is_processing_unhandled_input(),
		"key": node.is_processing_unhandled_key_input(),
	}
	if is_root and node is Control:
		entry["mouse"] = int((node as Control).mouse_behavior_recursive)
		(node as Control).mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	_blocked_input_nodes.append(entry)
	node.set_process_input(false)
	node.set_process_unhandled_input(false)
	node.set_process_unhandled_key_input(false)
	for child in node.get_children():
		_block_input_in(child, false)

func _show_customer_remark(customer_instance_id: String, text: String) -> void:
	var actor: Control = customer_actors.get(customer_instance_id)
	var at := Vector2(840.0, 200.0)
	if is_instance_valid(actor):
		at = actor.global_position - global_position + Vector2(actor.size.x * 0.5 - 90.0, 20.0)
	_float_text(at, text, Color("f6d95e"))

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

func _button_texture_box(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.set_texture_margin_all(12)
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4
	return style

func _build_cash_tray() -> void:
	cash_tray = CashTray.new()
	cash_tray.z_index = 36          # above the HUD (30), below story panels (40+) and the bubble (50)
	cash_tray.position = _ui_offset()
	cash_tray.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	add_child(cash_tray)
	cash_tray.change_given.connect(_on_change_given)
	cash_tray.denomination_selected.connect(_on_tutorial_denomination_selected)
	cash_tray.change_amount_changed.connect(_on_tutorial_change_amount_changed)

func _on_payment_tapped(customer_id: String) -> void:
	if shift == null:
		return
	for customer in shift.get_active_customers():
		if customer.instance_id == customer_id and customer.is_paying():
			cash_tray.open_for(customer, SukliRules.sukli_guide_enabled_for_day(campaign.day))
			if campaign.day == 2 and not day_two_sukli_tutorial_complete:
				_begin_day_two_sukli_tutorial(customer)
			return

func _begin_day_two_sukli_tutorial(customer: CustomerState) -> void:
	if customer == null or customer.payment == null:
		return
	tutorial_change_due = customer.payment.change_due()
	tutorial_payment_tender = customer.payment.tendered
	tutorial_payment_total = customer.payment.total
	_refresh_day_two_sukli_spotlight(cash_tray.get_selected_total())

func _on_tutorial_denomination_selected(_value: int, total: int) -> void:
	_on_tutorial_change_amount_changed(total)

func _on_tutorial_change_amount_changed(total: int) -> void:
	if campaign.day != 2 or day_two_sukli_tutorial_complete or tutorial_change_due <= 0:
		return
	_refresh_day_two_sukli_spotlight(total)

func _refresh_day_two_sukli_spotlight(total: int) -> void:
	var remaining := tutorial_change_due - total
	var equation := "₱%d − ₱%d = ₱%d" % [tutorial_payment_tender, tutorial_payment_total, tutorial_change_due]
	if remaining == 0:
		var give_button := cash_tray.find_child("GiveChangeButton", true, false) as Control
		if is_instance_valid(give_button):
			_show_tutorial_spotlight(TutorialStep.DAY2_GIVE, "%s\nExact change! Tap IBIGAY." % equation, give_button, "SUKLI · READY")
		return
	if remaining < 0:
		var clear_button := cash_tray.find_child("ClearChangeButton", true, false) as Control
		if is_instance_valid(clear_button):
			_show_tutorial_spotlight(TutorialStep.DAY2_MONEY, "%s\nYou gave too much. Tap LINISIN and try again." % equation, clear_button, "SUKLI · TRY AGAIN")
		return
	var next_value := _largest_change_denomination_at_most(remaining)
	var coin := cash_tray.find_child("Denomination%d" % next_value, true, false) as Control
	if is_instance_valid(coin):
		_show_tutorial_spotlight(TutorialStep.DAY2_MONEY, "%s\nYou still need ₱%d. Tap ₱%d next." % [equation, remaining, next_value], coin, "SUKLI · STEP")

func _largest_change_denomination_at_most(value: int) -> int:
	for denomination in [50, 20, 10, 5, 1]:
		if denomination <= value:
			return denomination
	return 1

func _on_change_given(customer_id: String, amount: int) -> void:
	if shift == null:
		return
	var actor: Control = customer_actors.get(customer_id)
	var outcome: Dictionary = shift.give_change(customer_id, amount)
	var result: int = int(outcome.get("result", PaymentState.Result.NO_PAYMENT))
	var diff: int = int(outcome.get("diff", 0))
	if campaign.day == 2 and tutorial_change_due > 0:
		if result == PaymentState.Result.EXACT:
			day_two_sukli_tutorial_complete = true
			_clear_tutorial_spotlight()
		else:
			_refresh_day_two_sukli_spotlight(cash_tray.get_selected_total())
	if result == PaymentState.Result.EXACT and daily_goal != null:
		var was_goal_complete: bool = daily_goal.is_complete()
		daily_goal.record_exact_change()
		_refresh_daily_goal_hud()
		if not was_goal_complete and daily_goal.is_complete():
			_float_text(Vector2(760.0, 270.0), "GOAL COMPLETE!", Color("d9efaa"))
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
	return customer != null and (customer.is_paying() or customer.parked)

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
	store_layer_renderer.configure(campaign.day, campaign.cash, campaign.purchased_store_groups)
	store_layer_renderer.purchase_requested.connect(_on_store_purchase_requested)
	store_layer_renderer.purchase_denied.connect(_on_store_purchase_denied)
	shelf_shop = ShelfShopModal.new()
	add_child(shelf_shop)
	shelf_shop.purchase_requested.connect(_on_shelf_shop_purchase_requested)
	shelf_shop.closed.connect(_on_shelf_shop_closed)

func _open_shelf_shop() -> void:
	if shelf_shop == null or not _is_shop_available():
		return
	shelf_shop.configure(StoreConfig.load_config("res://data/store_config.json"), campaign.purchased_store_groups, campaign.cash)
	move_child(shelf_shop, get_child_count() - 1)
	shelf_shop.open()
	if tutorial_step == TutorialStep.DAY2_SHOP and tutorial_overlay != null:
		tutorial_overlay.visible = false

func _is_shop_available() -> bool:
	if campaign == null or campaign.day <= 1:
		return false
	# The pre-shift shop stays open normally. Once the shift starts, players get
	# one real minute to make a final shelf purchase before the rush locks it.
	return shop_available or (shift_in_progress and shop_grace_remaining_seconds > 0.0)

func _refresh_shop_button() -> void:
	if shop_button != null:
		shop_button.visible = _is_shop_available()
		# ShiftStoryEvents moves the full-screen dialogue bubble to the top of the
		# tree. Keep this tap target after it, otherwise the bubble consumes taps.
		if shop_button.visible:
			move_child(shop_button, get_child_count() - 1)

func _on_shelf_shop_purchase_requested(group_id: String, price: int) -> void:
	if not campaign.purchase_store_group(group_id, price): return
	_update_cash(campaign.cash)
	# Refresh both the authored storefront art and the transparent drag targets
	# from the same purchased-group state in this frame.
	store_layer_renderer.configure(campaign.day, campaign.cash, campaign.purchased_store_groups)
	_rebuild_product_shelf()
	shelf_shop.configure(StoreConfig.load_config("res://data/store_config.json"), campaign.purchased_store_groups, campaign.cash)

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

# The store art stretches to fill wide screens, but the tags, notebook and dialogue are
# laid out for 1920x1080, so they get centered in the extra width.

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
	if pause_menu != null:
		pause_menu.set_available(false)
	bubble.close()
	cash_tray.close()
	if briefing_card != null:
		briefing_card.hide_briefing()
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
