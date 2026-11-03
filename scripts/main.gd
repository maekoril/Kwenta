extends Control

signal day_one_closing_tutorial_finished

const CAMPAIGN_CONFIG: CampaignConfig = preload("res://data/story/summer_campaign.tres")
const PRODUCT_DRAG_ITEM_SCENE: PackedScene = preload("res://scenes/product_drag_item.tscn")
const CUSTOMER_ACTOR_SCENE: PackedScene = preload("res://scenes/customer_slot.tscn")
const PRODUCT_ATLAS: Texture2D = preload("res://assets/store/products/kwenta_generic_products.png")
const PORTRAIT_ATLAS: Texture2D = preload("res://assets/characters/shared/customer_portraits_v2.png")
const COUNTER_ART = preload("res://scripts/counter_art.gd")
const STOREFRONT_LAYOUT = preload("res://scripts/storefront_layout.gd")
const STORE_LAYER_RENDERER = preload("res://scripts/store_layer_renderer.gd")
const KWENTA_AUDIO = preload("res://scripts/kwenta_audio.gd")
const AUDIO_SETTINGS = preload("res://scripts/audio_settings.gd")
const INTERACTIVE_TUTORIAL_OVERLAY = preload("res://scripts/interactive_tutorial_overlay.gd")
const STORY_EVENT_MARKER = preload("res://scripts/story_event_marker.gd")
const PAOLO_DEBT_NOTE = preload("res://scripts/paolo_debt_note.gd")
const UTANG_LEDGER = preload("res://scripts/utang_ledger.gd")
const DEBUG_TOOLS = preload("res://scripts/debug_tools.gd")
const HUD_SAFE_MARGIN := 33.0
const HUD_TOP_Y := 11.0
const HUD_RAIL_GAP := 14.0
const PAUSE_BUTTON_SIZE := Vector2(89.0, 74.0)
const SHOP_BUTTON_SIZE := Vector2(74.0, 74.0)
const UTANG_BUTTON_SIZE := Vector2(100.0, 58.0)
const CAMPAIGN_SAVE = preload("res://scripts/campaign_save.gd")
const SUPPLIER_NOTE = preload("res://scripts/supplier_note.gd")
const DAILY_GOAL = preload("res://scripts/daily_goal.gd")
const DAY_BRIEFING = preload("res://scripts/day_briefing.gd")
const BRIEFING_CARD = preload("res://scripts/briefing_card.gd")
const NOTEBOOK_SCROLL = preload("res://scripts/notebook_scroll.gd")
const SUPPLIER_NOTEBOOK_ICON = preload("res://scripts/supplier_notebook_icon.gd")
const NOTEBOOK_ACTION_BUTTON_BACKGROUND_TEXTURE: Texture2D = preload("res://assets/ui/sukli/sized/ibigay_button.png")
const PAUSE_MENU = preload("res://scripts/pause_menu.gd")
const OPTION5_SUKI = preload("res://scripts/option5_suki.gd")
const HUD_ICON = preload("res://scripts/hud_icon.gd")
const SHIFT_STORY_EVENTS = preload("res://scripts/shift_story_events.gd")
const FIESTA_HELPER_ICON = preload("res://scripts/fiesta_helper_icon.gd")
const SUMMARY_PANEL_POS := Vector2(240, 129)
const STORE_ATMOSPHERE = preload("res://scripts/store_atmosphere.gd")
const RAIN_STORE_BACKGROUND_PATH := "res://assets/store/backgrounds/bg_empty_rain.png"
const FIESTA_BACKGROUND_PATH := "res://assets/store/backgrounds/bg_empty_fiesta.png"
const FIESTA_NIGHT_BACKGROUND_PATH := "res://assets/store/backgrounds/bg_empty_fiesta_brownout.png"
const FIESTA_BROWNOUT_BACKGROUND_PATH := "res://assets/store/backgrounds/bg_empty_fiesta_blackout.png"
const EVENING_BACKGROUND_PATH := "res://assets/store/backgrounds/bg_empty_golden_hour.png"
const NIGHT_BACKGROUND_PATH := "res://assets/store/backgrounds/bg_empty_night_lights.png"
const NO_GRADE := Color(0.0, 0.0, 0.0, 0.0)
const GAME_OVER_SCREEN = preload("res://scripts/game_over_screen.gd")
const DAY_FOCUS_HINTS := {
	1: "Drag a product from the shelf to the customer who ordered it.",
	2: "Shop before opening. Today, give the correct sukli after each sale.",
	3: "Practice orders with different products while customers overlap.",
	4: "Rain makes customers less patient. Serve the shortest bar first.",
	5: "Tap UTANG LIST to check balances and due dates.",
	6: "Fiesta rush! Up to three customers can wait at once.",
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
var gameplay_hud: Control
var product_layer: Control
var product_items_by_id: Dictionary = {}
var customer_layer: Control
var store_layer_renderer: StoreLayerRenderer
var shelf_shop: ShelfShopModal
var fiesta_button: Button
var fiesta_friends: Control
var fiesta_icons: Dictionary = {}
var fiesta_selected_helper := ""
var fiesta_target_prompt: Label
var fiesta_preview_step := -1
var shop_button: Button
var utility_toggle: Button
var utility_drawer: PanelContainer
var utility_shop: Button
var utility_utang: Button
var utility_pause: Button
var utility_open := false
var shop_cta_glow: Panel
var shop_cta_tween: Tween
var shop_order_cue: Label
var shop_locked_cue: Control
var customer_actors: Dictionary = {}
var customer_story_button: Button
var customer_story_actor: Control
var story_visitor_portrait: TextureRect
var resumed_campaign := false
var resumed_completed := false
var debug_controls_visible := true
var debug_session := false
var debug_launch_data: Dictionary = {}
var checkpoint_ready := false
var completed_tutorials: Dictionary = {}
var story_visitor_entrance: Tween
var drag_hover_customer: Control
var summary_panel: PanelContainer
var summary_backdrop: ColorRect
var summary_title: NotebookTitle
var summary_portrait: TextureRect
var summary_speaker: NotebookEyebrow
var summary_text: NotebookSummary
var story_choice_column: VBoxContainer
var summary_button: Button
var bubble: DialogueBubble
var prologue_background: TextureRect
var prologue_fade: ColorRect
var day7_time_label: Label
var story_illustration: TextureRect
var story_illustration_previous: TextureRect
var story_illustration_tween: Tween
var paolo_debt_note: Control
var utang_button: Button
var utang_close: Button
var utang_ledger: Control
var supplier_note
var current_choice_data: Dictionary = {}
var current_choice_ids: Array[String] = []
var ui_refresh_elapsed: float = 0.0
var campaign_started: bool = false
var shift_start_credit: Dictionary = {}
var utang_tutorial_customer := ""
var utang_tutorial_message := ""
var shift_start_choices: Dictionary = {}
var shift_start_cash: int = 0
var shift_start_trust: Dictionary = {}
var displayed_cash: int = -1
var story_beats: Array[Dictionary] = []
var story_beat_index: int = 0
var story_transition_active := false
var story_after_action: String = ""
var pending_story_choices: Array[Dictionary] = []
const DEBUG_SKIP_BONUS_CASH := 1000  # e.g. 500 to have money for shelf purchases after skipping
var shift_in_progress: bool = false
var opening_sign_active := false
var store_sign: PanelContainer
var store_sign_header: Label
var store_sign_title: Label
var store_sign_detail: Label
var opening_blocker: ColorRect
var store_sign_tween: Tween
var shop_available: bool = false
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
var angry_customer_ids: Dictionary = {}

var ENVIRONMENT_BY_DAY: Dictionary = {
	1: {"base_path": "", "full_background": false, "evening_path": EVENING_BACKGROUND_PATH, "evening_start_minute": 480, "evening_end_minute": 600, "night_path": NIGHT_BACKGROUND_PATH, "night_start_minute": 600, "night_end_minute": 630, "grade_color": NO_GRADE, "rain_particles": false, "sunbeams": true, "flicker_event": false},
	2: {"base_path": "", "full_background": false, "evening_path": EVENING_BACKGROUND_PATH, "evening_start_minute": 480, "evening_end_minute": 600, "night_path": NIGHT_BACKGROUND_PATH, "night_start_minute": 600, "night_end_minute": 630, "grade_color": NO_GRADE, "rain_particles": false, "sunbeams": true, "flicker_event": false},
	3: {"base_path": "", "full_background": false, "evening_path": EVENING_BACKGROUND_PATH, "evening_start_minute": 480, "evening_end_minute": 600, "night_path": NIGHT_BACKGROUND_PATH, "night_start_minute": 600, "night_end_minute": 630, "grade_color": NO_GRADE, "rain_particles": false, "sunbeams": true, "flicker_event": false},
	4: {"base_path": RAIN_STORE_BACKGROUND_PATH, "full_background": true, "evening_path": "", "grade_color": NO_GRADE, "rain_particles": true, "sunbeams": false, "flicker_event": true},
	5: {"base_path": "", "full_background": false, "evening_path": EVENING_BACKGROUND_PATH, "evening_start_minute": 480, "evening_end_minute": 600, "night_path": NIGHT_BACKGROUND_PATH, "night_start_minute": 600, "night_end_minute": 630, "grade_color": NO_GRADE, "rain_particles": false, "sunbeams": true, "flicker_event": false},
	6: {"base_path": FIESTA_BACKGROUND_PATH, "full_background": true, "evening_path": FIESTA_NIGHT_BACKGROUND_PATH, "evening_start_minute": 480, "evening_end_minute": 600, "brownout_path": FIESTA_BROWNOUT_BACKGROUND_PATH, "brownout_at_game_minute": 630, "grade_color": NO_GRADE, "rain_particles": false, "sunbeams": false, "flicker_event": false},
	7: {"base_path": "", "full_background": false, "evening_path": EVENING_BACKGROUND_PATH, "evening_start_minute": 480, "evening_end_minute": 600, "night_path": NIGHT_BACKGROUND_PATH, "night_start_minute": 600, "night_end_minute": 630, "grade_color": NO_GRADE, "rain_particles": false, "sunbeams": true, "flicker_event": false},
}
var flicker_event_day := -1
var environment_flicker_tween: Tween
var brownout_crossfade_tween: Tween
var environment_day := 1
var environment_game_minute := 0
var environment_settings: Dictionary = {}
var environment_textures: Dictionary = {}
var day_six_brownout_triggered := false
var fiesta_emergency_light: ColorRect
var fiesta_light_props: Control
var fiesta_ignition_tween: Tween
var debug_environment_time_override := -1
var tutorial_hint: Label
var tutorial_hint_tween: Tween
var tutorial_delivery_seen := false
var tutorial_overlay: InteractiveTutorialOverlay
var tutorial_step := TutorialStep.NONE
var day_one_hud_tour_index := 0
var tutorial_product_id := ""
var tutorial_customer_id := ""
var tutorial_change_due := 0
var tutorial_payment_tender := 0
var tutorial_payment_total := 0
var tutorial_sukli_ready := false
var tutorial_sukli_generation := 0
var day_two_sukli_tutorial_complete := false
var sukli_rules_previous_frozen := false
var daily_goal
var daily_goal_day := 0
var showing_pre_shift_briefing := false
var resume_briefing_after_shop := false
var supplier_delivery_was_tutorial := false
var supplier_story_blocked := false
var new_purchase_groups_today: Array[String] = []
var goal_sound_played := false
var shift_completion_sound_played := false

enum TutorialStep { NONE, DAY1_HUD, DAY1_PRODUCT, DAY1_CUSTOMER, DAY1_CLOSING, DAY2_SHOP, DAY2_CUSTOMER, DAY2_MONEY, DAY2_GIVE, DAY2_RULES, DAY2_SHOP_MENU, DAY4_UTANG_MENU, DAY4_UTANG_ROW, DAY5_SUKI }
func _connect_existing_game_buttons(node: Node) -> void:
	_connect_game_button_sound(node)
	for child in node.get_children():
		_connect_existing_game_buttons(child)

func _connect_game_button_sound(node: Node) -> void:
	if node is BaseButton:
		var button := node as BaseButton
		var callback := _play_game_button_sound.bind(button)
		if not button.pressed.is_connected(callback):
			button.pressed.connect(callback)

func _play_game_button_sound(button: BaseButton) -> void:
	if not is_ancestor_of(button) or audio == null:
		return
	var cue := "button_click"
	if is_instance_valid(cash_tray) and cash_tray.is_ancestor_of(button) and (button.name.begins_with("Denomination") or button.name.begins_with("CounterPiece")):
		cue = "coin_pickup"
	audio.play_ui_cue(cue)

func _ready() -> void:
	get_tree().node_added.connect(_connect_game_button_sound)
	_connect_existing_game_buttons(self)
	AUDIO_SETTINGS.initialize()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_recenter_fixed_hud)
	campaign = CampaignState.new(CAMPAIGN_CONFIG)
	story = StoryProgression.new(CAMPAIGN_CONFIG)
	if OS.is_debug_build() and get_tree().has_meta("kwenta_debug_launch"):
		debug_launch_data = get_tree().get_meta("kwenta_debug_launch")
		get_tree().remove_meta("kwenta_debug_launch")
		debug_session = true
		campaign.day = clampi(int(debug_launch_data.get("day", 1)), 1, CAMPAIGN_CONFIG.campaign_day_count)
		campaign.cash = 1500
		if campaign.day > 1:
			story.choices["day1_play"] = str(debug_launch_data.get("day1", "stay"))
		var money_choice := str(debug_launch_data.get("day2", "none")) if campaign.day > 2 else "none"
		var nena_choice := str(debug_launch_data.get("day2_haggle", "none"))
		if nena_choice in ["kind", "full"] and (campaign.day > 2 or (campaign.day == 2 and int(debug_launch_data.get("moment", 0)) in [3, 8])):
			story.choices["day2_haggle"] = nena_choice
		var sukli_choice := str(debug_launch_data.get("day2_sukli_result", ""))
		if sukli_choice in ["none", "perfect", "mistakes"] and campaign.day > 2:
			story.choices["day2_sukli_result"] = sukli_choice
		if money_choice != "none":
			story.choices["day2_berting_money"] = "seen"
			story.choices["day2_overpayment"] = money_choice
			if money_choice == "keep":
				story.choices["day2_money_separate"] = "yes"
		var berting_resolution := str(debug_launch_data.get("day3_berting_resolution", "none"))
		if money_choice == "keep" and berting_resolution in ["returned", "deny"] and (campaign.day > 3 or (campaign.day == 3 and int(debug_launch_data.get("moment", 0)) in [5, 6, 7, 8])):
			story.choices["day3_berting_resolution"] = berting_resolution
		if (campaign.day == 3 and int(debug_launch_data.get("moment", 0)) in [6, 7, 8]) or campaign.day > 3:
			var friends_choice := str(debug_launch_data.get("day3_friends", "none"))
			if friends_choice in ["later", "stay"]:
				story.choices["day3_friends"] = friends_choice
		if (campaign.day == 3 and int(debug_launch_data.get("moment", 0)) == 8) or campaign.day > 3:
			var paolo_choice := str(debug_launch_data.get("day3_candy", "none"))
			if paolo_choice in ["credit", "free", "no"]:
				story.choices["day3_candy"] = paolo_choice
		if (campaign.day == 4 and int(debug_launch_data.get("moment", 0)) in [8, 16]) or campaign.day > 4:
			var rain_choice := str(debug_launch_data.get("day4_rain", "none"))
			if rain_choice in ["join", "stay", "shelter"]:
				story.choices["day4_rain"] = rain_choice
		if bool(debug_launch_data.get("day4_dodong_seen", false)) and (campaign.day > 4 or (campaign.day == 4 and int(debug_launch_data.get("moment", 0)) in [8, 9])):
			story.choices["day4_dodong_seen"] = "seen"
		var debt_choice := str(debug_launch_data.get("day5_debt", "none"))
		if campaign.day > 5 and debt_choice in ["installments", "defer"]:
			story.choices["day5_debt"] = debt_choice
		var help_choice := str(debug_launch_data.get("day6_help", ""))
		if campaign.day >= 6 and help_choice in ["ask", "alone"]:
			story.choices["day6_help"] = help_choice
		# Rebuild persistent story debts as well as the choices that caused them.
		if story.get_choice("day3_candy") == "credit":
			campaign.add_debt("paolo_story", "paolo", 3, 0, 6, {}, true)
			if campaign.day > 4 or (campaign.day == 4 and int(debug_launch_data.get("moment", 0)) not in [0, 27]):
				story.choices["paolo_debt_recorded"] = "yes"
			if campaign.day > 6:
				campaign.repay_debt("paolo_story", 3)
				campaign.cash -= 3 # The debug starting balance already includes prior activity.
		if story.get_choice("day5_debt") == "installments":
			campaign.repay_debt("rosa_old", 110)
			campaign.cash -= 110
		# Quick playtests start with earlier days completed, but never alter the real save.
		# Reconstruct their diary pages from the scenario choices, not invented goal results.
		for completed_day in range(1, campaign.day):
			story.write_diary_entry(completed_day)
		if bool(debug_launch_data.get("skip_tutorials", true)):
			completed_tutorials = {"day1_hud": true, "day1_drag": true, "day2_shop": true, "day2_sukli": true, "story_event": true}
			day_two_sukli_tutorial_complete = true
	elif bool(get_tree().get_meta("kwenta_continue_game", false)):
		var saved := CAMPAIGN_SAVE.load_progress()
		if not saved.is_empty():
			campaign.from_dict(saved["campaign"])
			story.choices = saved["choices"].duplicate(true)
			if not saved["campaign"].has("debts"):
				if story.get_choice("day3_candy") == "credit":
					campaign.add_debt("paolo_story", "paolo", 3, 0, 6, {}, true)
				for debt in campaign.debts:
					if debt.id == "rosa_old" and story.get_choice("day5_debt") == "installments": debt.balance = 210
					if debt.id == "paolo_story" and campaign.day >= 7: debt.balance = 0

			if campaign.day >= 3 and story.get_choice("day2_overpayment") == "keep" and story.get_choice("day2_money_separate").is_empty():
				story.choices["day2_cash_legacy"] = "available" if campaign.cash >= 50 else "spent"
			resumed_campaign = true
			resumed_completed = bool(saved.get("completed", false))
			checkpoint_ready = true
			if saved.get("tutorials") is Dictionary:
				completed_tutorials = saved["tutorials"].duplicate(true)
			elif campaign.day > 1:
				completed_tutorials = {"day1_hud": true, "day1_drag": true, "story_event": true, "day2_shop": campaign.day > 2, "day2_sukli": campaign.day > 2}
			day_two_sukli_tutorial_complete = bool(completed_tutorials.get("day2_sukli", false))
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
	_build_fiesta_emergency_light()
	_build_customer_area()
	_build_product_layer()
	_build_hud()
	_ensure_daily_goal()
	_refresh_daily_goal_hud()  # A useful goal preview even during the intro.
	_build_tutorial_hint()
	_build_store_sign()
	_build_interactive_tutorial_overlay()
	_build_summary_panel()
	_build_briefing_card()
	_build_game_over_screen()
	_build_bubble()
	_build_prologue_background()
	_build_day_two_visuals()
	paolo_debt_note = PAOLO_DEBT_NOTE.new()
	paolo_debt_note.name = "PaoloDebtNote"
	add_child(paolo_debt_note)
	utang_ledger = UTANG_LEDGER.new()
	utang_ledger.name = "UtangLedger"
	add_child(utang_ledger)
	utang_button = Button.new()
	utang_button.text = "UTANG"
	utang_button.position = _utang_button_position()
	utang_button.size = UTANG_BUTTON_SIZE
	utang_button.z_index = 55
	KwentaStyle.style_button(utang_button, KwentaStyle.PAPER_DARK, 22)
	add_child(utang_button)
	utang_close = Button.new()
	utang_close.text = "Isara ang kuwaderno"
	utang_close.position = Vector2(760, 580) + _ui_offset()
	utang_close.size = Vector2(400, 70)
	utang_close.z_index = 56
	KwentaStyle.style_button(utang_close, KwentaStyle.PAPER_DARK, 28)
	utang_close.hide()
	add_child(utang_close)
	utang_button.pressed.connect(func():
		if shift == null or (shift.frozen and utang_tutorial_message.is_empty()) or not shift.is_running: return
		shift.frozen = true
		utang_button.modulate = Color.WHITE
		utility_toggle.modulate = Color.WHITE
		utang_ledger.show_records(campaign, _is_paolo_debt_recorded(), story.get_choice("day5_debt") == "installments")
		utang_close.show()
		if not utang_tutorial_message.is_empty():
			_show_tutorial_hint(utang_tutorial_message, 60.0)
			utang_tutorial_message = "")
	utang_close.pressed.connect(func():
		utang_ledger.hide()
		utang_close.hide()
		if tutorial_hint.visible: tutorial_hint.hide()
		shift.frozen = false)

	supplier_note = SUPPLIER_NOTE.new()
	supplier_note.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(supplier_note)
	_build_cash_tray()
	_build_shop_button()
	_build_fiesta_controls()
	# Skip Day is intentionally hidden; keep the debug helper for developers only.
	pause_menu = PAUSE_MENU.new()
	add_child(pause_menu)
	pause_menu.story_progression = story
	pause_menu.set_button_size(PAUSE_BUTTON_SIZE)
	pause_menu.set_button_icon(_utility_icon(3))
	_build_utility_drawer()
	_recenter_fixed_hud()
	_update_cash(campaign.cash)
	_create_shift_manager()
	_build_story_events()
	if debug_session:
		story_events._visitor_tutorial_seen = bool(completed_tutorials.get("story_event", false))
		day_label.text = "D%d" % campaign.day
		shop_available = campaign.day > 1
		_refresh_shop_button()
	if resumed_campaign:
		story_events._visitor_tutorial_seen = bool(completed_tutorials.get("story_event", false))
		day_label.text = "D%d" % campaign.day
		shop_available = campaign.day > 1
		_refresh_shop_button()
	_rebuild_product_shelf()
	apply_environment(campaign.day)
	if OS.is_debug_build():
		var debug_tools = DEBUG_TOOLS.new()
		debug_tools.controls_visibility_changed.connect(func(shown: bool):
			debug_controls_visible = shown
			if debug_skip_button != null:
				debug_skip_button.visible = shown and shift_in_progress
		)
		debug_tools.is_test_session = debug_session
		add_child(debug_tools)
	if debug_session:
		pause_menu.set_available(true)
		_launch_debug_start.call_deferred()
	elif get_tree().has_meta("kwenta_menu_story_transition"):
		prologue_background.visible = not resumed_campaign
		pause_menu.set_available(false)
	else:
		_present_prologue()
		pause_menu.set_available(true)  # Keep the framed Pause control visible during the intro.

func _finish_menu_transition() -> void:
	if resumed_campaign:
		campaign_started = true
		if resumed_completed:
			_advance_story_day()
		else:
			_present_day_intro()
	else:
		checkpoint_ready = CAMPAIGN_SAVE.write_checkpoint(campaign, story, completed_tutorials)
		if not checkpoint_ready:
			_show_save_warning()
		_present_prologue()
	pause_menu.set_available(true)

func _launch_debug_start() -> void:
	if not debug_session or not OS.is_debug_build():
		return
	var moment := int(debug_launch_data.get("moment", 0))
	if moment == 11 and campaign.day == 1:
		_present_prologue()
		return
	if moment == 13 and campaign.day == 2:
		var intro := story.get_day_intro_beats(2)
		var box_index := 0
		for index in range(intro.size()):
			if str(intro[index].get("cutscene", "")) == "box_fall":
				box_index = index
				break
		_show_story_beats(intro.slice(box_index), "DAY 2", "start_shift")
		return
	if moment == 34 and campaign.day == 7:
		var reunion := story.get_day_outro_beats(7)
		for index in range(reunion.size()):
			if str(reunion[index].get("text", "")).contains("Kumalansing ang shutter"):
				_show_story_beats(reunion.slice(index), "DAY 7", "day_choices")
				return
	if moment == 35 and campaign.day == 7:
		_show_story_beats(story.get_day_callback_beats(7), "DAY 7", "finish_day")
		return
	if moment == 33 and campaign.day == 7:
		var ending := story.get_day_callback_beats(7)
		for index in range(ending.size()):
			if str(ending[index].get("cutscene", "")) == "day7_time_card":
				_show_story_beats(ending.slice(index), "DAY 7", "finish_day")
				return
	if moment in [0, 27, 28]:
		_present_day_intro()
		return
	if moment == 1:
		_show_pre_shift_briefing()
		return
	if moment in [25, 26]:
		if moment == 25:
			completed_tutorials.erase("story_event")
			story_events._visitor_tutorial_seen = false
		else:
			completed_tutorials.erase("day1_drag")
		completed_tutorials["day1_hud"] = true
		_begin_shift()
		return
	if moment in [2, 14]:
		_begin_shift()
		return
	if moment in [31, 32]:
		campaign.add_debt("debug_credit", "neighbor_lina", 100, 7, campaign.day)
		completed_tutorials.erase("utang_repayment")
		completed_tutorials.erase("utang_repayment_marker")
	if moment == 30:
		completed_tutorials.erase("utang_first")
		completed_tutorials.erase("utang_event")
	# Direct scene previews start a real shift, but skip its opening and customers.
	_begin_shift()
	_clear_tutorial_spotlight()
	if store_sign_tween != null and store_sign_tween.is_valid():
		store_sign_tween.kill()
	opening_sign_active = false
	opening_blocker.visible = false
	store_sign.visible = false
	story_events.begin_shift(campaign.day)
	shift.story_queue.clear()
	shift.start_shift(false)
	shift.active_customers.clear()
	shift.customers_changed.emit()
	if moment == 30:
		shift.credit_requested_today = false
		for attempt in range(20):
			shift.active_customers.clear()
			shift._spawn_customer()
			if shift.credit_requested_today: break
		return
	if moment in [31, 32]:
		return
	if moment in [8, 12]:
		story_events.suppress()
		shift.finish_shift()
		return
	var visitor := {3: "mang_berting", 4: "mang_berting", 5: "jun_jun_tara", 6: "bea", 7: "paolo", 9: "jun_jun_tara", 10: "kuya_dodong_soaked", 15: "neighbor_rosa", 16: "neighbor_lina", 17: "kuya_dodong", 18: "neighbor_lina", 19: "classmate_1", 20: "classmate_2", 21: "classmate_3", 22: "paolo", 23: "paolo_repayment", 24: "fiesta_brownout", 29: "fiesta_brownout"}.get(moment, "") as String
	var matching: Array[Dictionary] = []
	for event in story_events._timed:
		if str(event.get("visitor", event.get("customer", ""))) == visitor:
			matching.append(event)
	if matching.is_empty():
		push_warning("Debug event is not available with those choices.")
		return
	# The Day 4 Lina event normally follows the friends choice immediately.
	# A direct preview has already seeded that choice, so schedule it normally.
	if moment == 16:
		matching[0].erase("follow_after_choice")
	var minute := int(matching[0].get("at_minute", 0))
	var remaining: Array[Dictionary] = []
	for event in story_events._timed:
		if int(event.get("at_minute", 0)) >= minute:
			remaining.append(event)
	story_events._timed = remaining
	shift.elapsed_seconds = shift.shift_duration_seconds * float(minute) / float(shift.shift_close_minutes)
	shift._update_clock()

func _remember_story_event_tutorial() -> void:
	_remember_tutorial("story_event")

func _remember_tutorial(tutorial_id: String) -> void:
	if bool(completed_tutorials.get(tutorial_id, false)):
		return
	completed_tutorials[tutorial_id] = true
	if checkpoint_ready and not CAMPAIGN_SAVE.remember_tutorial(tutorial_id):
		_show_save_warning()

func _show_save_warning() -> void:
	var warning := AcceptDialog.new()
	warning.title = "Save unavailable"
	warning.dialog_text = "Hindi na-save ang progress. Please check your device storage before closing the game."
	add_child(warning)
	warning.confirmed.connect(warning.queue_free)
	warning.popup_centered()

func _process(delta: float) -> void:
	_refresh_fiesta_controls()
	if is_instance_valid(utang_button):
		utang_button.visible = false
	if is_instance_valid(utility_drawer):
		_refresh_utility_drawer()
	if is_instance_valid(customer_story_button) and is_instance_valid(customer_story_actor):
		customer_story_button.position = customer_story_actor.global_position - global_position
		customer_story_button.modulate.a = customer_story_actor.modulate.a
		if tutorial_overlay.visible and tutorial_overlay.title.text == "UTANG EVENT":
			tutorial_overlay.spotlight_rect = _tutorial_rect_for(customer_story_button).grow(18.0)
			tutorial_overlay._position_coachmark()
			tutorial_overlay.queue_redraw()
	if tutorial_step == TutorialStep.DAY2_CUSTOMER and tutorial_overlay != null and tutorial_overlay.visible:
		_update_day_two_customer_sukli_target()
	if shift != null and shift_in_progress and not opening_sign_active and fiesta_preview_step < 0 and tutorial_step not in [TutorialStep.DAY1_HUD, TutorialStep.DAY1_PRODUCT, TutorialStep.DAY1_CUSTOMER, TutorialStep.DAY1_CLOSING, TutorialStep.DAY2_CUSTOMER, TutorialStep.DAY2_MONEY, TutorialStep.DAY2_GIVE]:
		shift.advance_time(delta)
	ui_refresh_elapsed += delta
	if ui_refresh_elapsed >= 0.12:
		ui_refresh_elapsed = 0.0
		for child in customer_layer.get_children():
			if child is Control and child.has_method("refresh_patience"):
				child.refresh_patience()

func _build_hud() -> void:
	# Option 5: a compact top strip that keeps the centre stats together while
	# the objective and trust controls follow the actual viewport edges.
	var hud := Control.new()
	gameplay_hud = hud
	hud.name = "GameplayHUDOption5"
	hud.z_index = 30
	hud.position = Vector2.ZERO
	hud.size = size
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	const Y := HUD_TOP_Y
	const H := 74.0

	# Left objective chip: icon + LIVE progress + count (no oversized heading).
	goal_panel = PanelContainer.new()
	goal_panel.name = "DailyGoalHud"
	goal_panel.position = Vector2(HUD_SAFE_MARGIN, Y)
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
	day_label = _option5_stat(hud, "DayChip", Vector2.ZERO, Vector2(149, H), "calendar.png", "D1", 27, KwentaStyle.INK, 35.0)
	clock_label = _option5_stat(hud, "TimeChip", Vector2.ZERO, Vector2(169, H), "clock.png", "8:00", 27, KwentaStyle.INK, 34.0)
	cash_label = _option5_stat(hud, "CashChip", Vector2.ZERO, Vector2(178, H), "peso.png", "150", 27, KwentaStyle.MONEY, 35.0)

	# Live suki animation remains controlled by the existing trust update calls.
	trust_tag = OPTION5_SUKI.new().setup(campaign.barangay_trust, 372.0, 0.0, 3.0, false)
	trust_tag.position = Vector2.ZERO
	hud.add_child(trust_tag)
	_layout_gameplay_hud()

func _recenter_fixed_hud() -> void:
	_layout_fiesta_blackout()
	if is_instance_valid(tutorial_hint):
		tutorial_hint.position = Vector2(360.0, 1004.0) + _ui_offset()
	_layout_gameplay_hud()
	_layout_right_hud_rail()
	if is_instance_valid(briefing_card) and briefing_card.visible:
		briefing_card.call_deferred("_settle", size, false)
	for child in get_children():
		if child.name.begins_with("DailyGoalAchievementNotice") and child is Control:
			child.position = Vector2(33, 100) + _ui_offset()

func _layout_right_hud_rail() -> void:
	var scale := _hud_scale()
	if is_instance_valid(pause_menu):
		pause_menu.set_button_scale(scale)
		pause_menu.place_button(_pause_button_position() - Vector2((PAUSE_BUTTON_SIZE.x + HUD_RAIL_GAP) * scale, 0))
	if is_instance_valid(shop_button):
		shop_button.scale = Vector2.ONE * scale
		shop_button.position = _shop_button_position()
		_refresh_shop_cta_layout()
	if is_instance_valid(utang_button):
		utang_button.scale = Vector2.ONE * scale
		utang_button.position = _utang_button_position()
	if is_instance_valid(utility_toggle):
		utility_toggle.scale = Vector2.ONE * scale
		utility_toggle.position = _pause_button_position()
		utility_drawer.scale = Vector2.ONE * scale
		utility_drawer.position = Vector2(size.x - maxf(20.0, HUD_SAFE_MARGIN * scale) - utility_drawer.size.x * scale, HUD_TOP_Y + (PAUSE_BUTTON_SIZE.y + HUD_RAIL_GAP) * scale)

func _build_utility_drawer() -> void:
	utility_toggle = Button.new()
	utility_toggle.name = "UtilityMenuButton"
	utility_toggle.text = ""
	utility_toggle.size = PAUSE_BUTTON_SIZE
	utility_toggle.z_index = 57
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		utility_toggle.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	utility_toggle.icon = _utility_icon(4)
	utility_toggle.expand_icon = true
	add_child(utility_toggle)
	utility_toggle.pressed.connect(func():
		utility_open = not utility_open
		_layout_gameplay_hud()
		_refresh_utility_drawer()
		if utility_open and tutorial_step == TutorialStep.DAY2_SHOP_MENU:
			_show_supplier_row_tutorial.call_deferred()
		elif not utility_open and tutorial_step == TutorialStep.DAY2_SHOP:
			tutorial_overlay.z_index = 52
			_show_tutorial_spotlight(TutorialStep.DAY2_SHOP_MENU, "Tap the menu to find Inay's supplier list.", utility_toggle, "SUPPLIER LIST")
		elif utility_open and tutorial_step == TutorialStep.DAY4_UTANG_MENU:
			_show_utang_row_tutorial.call_deferred()
		elif not utility_open and tutorial_step == TutorialStep.DAY4_UTANG_ROW:
			tutorial_overlay.z_index = 52
			_show_tutorial_spotlight(TutorialStep.DAY4_UTANG_MENU, "Tap the menu to find the utang notebook.", utility_toggle, "UTANG NOTEBOOK"))
	utility_drawer = PanelContainer.new()
	utility_drawer.name = "UtilityDrawer"
	utility_drawer.size = Vector2(330, 385)
	utility_drawer.z_index = 57
	var panel_texture := load("res://assets/ui/utility_menu/wood_panel.png") as Texture2D
	if panel_texture != null:
		var panel_style := StyleBoxTexture.new()
		panel_style.texture = panel_texture
		panel_style.content_margin_left = 45
		panel_style.content_margin_right = 45
		panel_style.content_margin_top = 48
		panel_style.content_margin_bottom = 48
		utility_drawer.add_theme_stylebox_override("panel", panel_style)
	add_child(utility_drawer)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	utility_drawer.add_child(column)
	utility_shop = _utility_row(column, "ORDER")
	utility_utang = _utility_row(column, "UTANG LIST")
	var diary := _utility_row(column, "DIARY")
	for entry in [[utility_shop, 0], [utility_utang, 1], [diary, 2]]:
		entry[0].icon = _utility_icon(entry[1])
		entry[0].expand_icon = true
		entry[0].alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry[0].add_theme_constant_override("icon_max_width", 58)
	utility_shop.pressed.connect(func():
		utility_open = false
		_refresh_utility_drawer()
		_open_shelf_shop())
	utility_utang.pressed.connect(func():
		utility_open = false
		_refresh_utility_drawer()
		if tutorial_step == TutorialStep.DAY4_UTANG_ROW:
			_remember_tutorial("day4_utang")
			_clear_tutorial_spotlight()
			tutorial_overlay.z_index = 52
			utang_ledger.show_records(campaign, _is_paolo_debt_recorded(), story.get_choice("day5_debt") == "installments")
			utang_close.show()
		else:
			utang_button.pressed.emit())
	diary.pressed.connect(func():
		utility_open = false
		_refresh_utility_drawer()
		if shift != null and shift.is_running and not shift.frozen:
			pause_menu.pause()
		pause_menu.diary_reader.open(story))
	_refresh_utility_drawer()

func _utility_icon(index: int) -> Texture2D:
	var sheet := load("res://assets/ui/utility_menu/icons.png") as Texture2D
	if sheet == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(1300 if index == 3 else 1704, 180, 355, 355) if index >= 3 else Rect2(index * 420, 130, 420, 440)
	return atlas

func _utility_row(parent: VBoxContainer, caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(240, 68)
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	KwentaStyle.style_button(button, KwentaStyle.PAPER_DARK, 24)
	parent.add_child(button)
	return button

func _refresh_utility_drawer() -> void:
	if not is_instance_valid(utility_drawer):
		return
	utility_drawer.visible = utility_open
	utility_shop.visible = campaign != null and campaign.day >= 2 and (campaign.day > 2 or not supplier_story_blocked)
	utility_shop.disabled = campaign == null or campaign.day <= 1 or supplier_story_blocked
	utility_shop.text = "ORDER"
	utility_shop.icon = _utility_icon(0)
	utility_shop.tooltip_text = "Order before opening the store." if not _is_shop_available() else "Order supplies"
	utility_shop.modulate = Color.WHITE if _is_shop_available() else Color(0.72, 0.72, 0.72)
	utility_utang.visible = campaign != null and campaign.day >= 4
	utility_utang.disabled = campaign == null or campaign.day < 4 or shift == null or not shift.is_running or (shift.frozen and tutorial_step != TutorialStep.DAY4_UTANG_ROW and utang_tutorial_message.is_empty())
	if is_instance_valid(pause_menu) and is_instance_valid(pause_menu._button):
		pause_menu._button.visible = utility_open and pause_menu._available and not get_tree().paused

func _layout_gameplay_hud() -> void:
	if not is_instance_valid(gameplay_hud):
		return
	gameplay_hud.position = Vector2.ZERO
	gameplay_hud.size = size
	var scale := _hud_scale()
	var margin := maxf(20.0, HUD_SAFE_MARGIN * scale)
	var center_gap := 14.0
	var day_panel: Control = null
	var clock_panel: Control = null
	var cash_panel: Control = null
	if is_instance_valid(day_label):
		day_panel = day_label.get_parent().get_parent() as Control
	if is_instance_valid(clock_label):
		clock_panel = clock_label.get_parent().get_parent() as Control
	if is_instance_valid(cash_label):
		cash_panel = cash_label.get_parent().get_parent() as Control
	if day_panel != null and clock_panel != null and cash_panel != null:
		day_panel.scale = Vector2.ONE * scale
		clock_panel.scale = Vector2.ONE * scale
		cash_panel.scale = Vector2.ONE * scale
		var stats_width := (day_panel.size.x + clock_panel.size.x + cash_panel.size.x + center_gap * 2.0) * scale
		var stats_x := (size.x - stats_width) * 0.5
		day_panel.position = Vector2(stats_x, HUD_TOP_Y)
		clock_panel.position = Vector2(day_panel.position.x + (day_panel.size.x + center_gap) * scale, HUD_TOP_Y)
		cash_panel.position = Vector2(clock_panel.position.x + (clock_panel.size.x + center_gap) * scale, HUD_TOP_Y)
	if is_instance_valid(goal_panel):
		goal_panel.scale = Vector2.ONE * scale
		goal_panel.position = Vector2(margin, HUD_TOP_Y)
	if is_instance_valid(trust_tag):
		trust_tag.scale = Vector2.ONE * scale
		var rail_width := PAUSE_BUTTON_SIZE.x * (2.0 if utility_open else 1.0) + HUD_RAIL_GAP * (2.0 if utility_open else 1.0)
		trust_tag.position = Vector2(size.x - margin - (rail_width + trust_tag.size.x) * scale, HUD_TOP_Y)

func _hud_scale() -> float:
	# The full Option 5 composition fits at 1800px wide and reduces uniformly
	# below that, preserving padding and avoiding overlap on smaller devices.
	return clampf(size.x / 1800.0, 0.4, 1.0)

func _option5_frame(sprite_name: String, content_x: float = 13.0, content_y: float = 8.0) -> StyleBoxTexture:
	var frame := StyleBoxTexture.new()
	frame.texture = load("res://assets/ui/hud_v5/" + sprite_name) as Texture2D
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
	icon.texture = load("res://assets/ui/hud_v5/" + sprite_name) as Texture2D
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
	if daily_goal.type == DAILY_GOAL.Type.BARANGAY_TRUST:
		goal_count_label.text = "%d / 60" % floori(campaign.barangay_trust)
		goal_progress.value = minf(campaign.barangay_trust, 60.0)
		goal_progress_fill.bg_color = Color("4caa56") if campaign.barangay_trust >= 60.0 else Color("d94536")
	elif daily_goal.is_no_timeout_goal():
		goal_progress.value = 0.0 if daily_goal.timed_out else float(daily_goal.target)
		goal_progress_fill.bg_color = Color("d94536") if daily_goal.timed_out else Color("f5b83d")
	else:
		goal_progress.value = float(daily_goal.current)
		goal_progress_fill.bg_color = Color("4caa56") if daily_goal.is_complete() else Color("f5b83d")
	goal_progress.queue_redraw()

func _build_store_sign() -> void:
	opening_blocker = ColorRect.new()
	opening_blocker.z_index = 54
	opening_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	opening_blocker.color = Color(0.08, 0.04, 0.02, 0.38)
	opening_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	opening_blocker.visible = false
	add_child(opening_blocker)
	store_sign = PanelContainer.new()
	store_sign.z_index = 55
	store_sign.size = Vector2(520.0, 110.0)
	store_sign.position = Vector2(700.0, 105.0) + _ui_offset()
	store_sign.pivot_offset = Vector2(260.0, 55.0)
	store_sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	store_sign.add_theme_stylebox_override("panel", KwentaStyle.box(Color("fffefa"), Color("282323"), 24.0, 12.0, 6, 5, 8))
	store_sign.visible = false
	add_child(store_sign)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	store_sign.add_child(column)
	store_sign_header = KwentaStyle.make_label("", 20, Color("282323"))
	store_sign_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(store_sign_header)
	store_sign_title = KwentaStyle.make_label("", 38, Color.WHITE)
	store_sign_title.add_theme_stylebox_override("normal", KwentaStyle.box(Color("b82025"), Color("b82025"), 0.0, 0.0, 2, 0, 0))
	store_sign_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(store_sign_title)
	store_sign_detail = KwentaStyle.make_label("", 24, Color("282323"))
	store_sign_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(store_sign_detail)

func _configure_store_sign(opening: bool) -> void:
	var sign_size := Vector2(920.0, 340.0) if opening else Vector2(300.0, 90.0)
	store_sign_header.add_theme_font_size_override("font_size", 30 if opening else 18)
	store_sign_title.add_theme_font_size_override("font_size", 118 if opening else 38)
	store_sign_detail.add_theme_font_size_override("font_size", 34 if opening else 20)
	store_sign_header.visible = opening
	store_sign_detail.visible = opening
	store_sign.reset_size()
	store_sign.size = sign_size
	store_sign.position = ((STOREFRONT_LAYOUT.VIEWPORT_SIZE - sign_size) * 0.5 if opening else Vector2(402.0, 3.0)) + _ui_offset()
	store_sign.pivot_offset = sign_size * 0.5

func _set_store_sign_face(is_open: bool, opening: bool) -> void:
	store_sign_title.text = "OPEN" if is_open else "CLOSED"
	store_sign_header.text = "TINDAHAN NI ALING CORA" if opening else "FINISH REMAINING ORDERS"
	if opening:
		store_sign_detail.text = "BAWAL UTANG... PWEDE NGUMITI!" if is_open else "SANDALI LANG, MAGBUBUKAS NA!"
	else:
		store_sign_detail.text = ""

func _show_opening_sign() -> void:
	_hide_store_sign()
	opening_sign_active = true
	opening_blocker.visible = true
	_configure_store_sign(true)
	_set_store_sign_face(false, true)
	store_sign.visible = true
	store_sign.scale = Vector2(0.8, 0.8)
	store_sign.rotation_degrees = -3.0
	store_sign.modulate.a = 0.0
	store_sign_tween = create_tween()
	store_sign_tween.set_parallel(true)
	store_sign_tween.tween_property(store_sign, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	store_sign_tween.tween_property(store_sign, "modulate:a", 1.0, 0.2)
	store_sign_tween.tween_property(store_sign, "rotation_degrees", 0.0, 0.3)
	store_sign_tween.chain().tween_interval(0.20)
	store_sign_tween.chain().tween_property(store_sign, "scale:x", 0.02, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	store_sign_tween.chain().tween_callback(_set_store_sign_face.bind(true, true))
	store_sign_tween.chain().tween_property(store_sign, "scale:x", 1.0, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	store_sign_tween.parallel().tween_property(store_sign, "rotation_degrees", 2.0, 0.13).set_trans(Tween.TRANS_SINE)
	store_sign_tween.chain().tween_property(store_sign, "rotation_degrees", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	store_sign_tween.chain().tween_interval(1.2)
	store_sign_tween.chain().tween_property(store_sign, "modulate:a", 0.0, 0.2)
	store_sign_tween.chain().tween_callback(_after_opening_sign)

func _on_shift_closing() -> void:
	_hide_store_sign()
	if campaign.day == 1:
		return
	_configure_store_sign(false)
	_set_store_sign_face(true, false)
	# Lay out the compact sign invisibly before revealing the flip.
	store_sign.modulate.a = 0.0
	store_sign.visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	if not shift_in_progress or not shift.is_closing:
		return
	store_sign.reset_size()
	store_sign.size = Vector2(300.0, 90.0)
	store_sign.scale = Vector2(0.72, 0.72)
	store_sign.rotation_degrees = 0.0
	store_sign.modulate.a = 1.0
	store_sign.visible = true
	store_sign_tween = create_tween()
	store_sign_tween.tween_property(store_sign, "scale:x", 0.02, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	store_sign_tween.tween_callback(_set_closing_badge_face)
	store_sign_tween.tween_property(store_sign, "scale:x", 0.72, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _set_closing_badge_face() -> void:
	store_sign_title.add_theme_font_size_override("font_size", 27 if campaign.day == 1 else 38)
	store_sign_title.text = "LAST ORDERS" if campaign.day == 1 else "CLOSED"

func _set_final_closed_face() -> void:
	store_sign_title.text = "CLOSED"
	store_sign_header.text = "TINDAHAN NI ALING CORA"
	store_sign_detail.text = "SALAMAT, MGA SUKI!"

func _play_final_closing_sign() -> void:
	_hide_store_sign()
	opening_blocker.visible = true
	_configure_store_sign(true)
	_set_store_sign_face(true, true)
	store_sign.visible = true
	store_sign.modulate.a = 0.0
	store_sign.scale = Vector2(0.9, 0.9)
	store_sign.rotation_degrees = 0.0
	store_sign_tween = create_tween()
	store_sign_tween.set_parallel(true)
	store_sign_tween.tween_property(store_sign, "modulate:a", 1.0, 0.2)
	store_sign_tween.tween_property(store_sign, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	store_sign_tween.chain().tween_interval(0.25)
	store_sign_tween.chain().tween_property(store_sign, "scale:x", 0.02, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	store_sign_tween.chain().tween_callback(_set_final_closed_face)
	store_sign_tween.chain().tween_property(store_sign, "scale:x", 1.0, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	store_sign_tween.chain().tween_interval(1.1)
	store_sign_tween.chain().tween_property(store_sign, "modulate:a", 0.0, 0.2)
	await store_sign_tween.finished
	_hide_store_sign()

func _hide_store_sign() -> void:
	opening_sign_active = false
	if store_sign_tween != null and store_sign_tween.is_valid():
		store_sign_tween.kill()
	if is_instance_valid(opening_blocker):
		opening_blocker.visible = false
	if is_instance_valid(store_sign):
		store_sign.visible = false

func _build_tutorial_hint() -> void:
	tutorial_hint = _label("", 28, Color("fff1b8"))
	tutorial_hint.name = "TutorialHint"
	tutorial_hint.z_index = 46
	tutorial_hint.position = Vector2(360.0, 1004.0) + _ui_offset()
	tutorial_hint.size = Vector2(1170.0, 64.0)
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
	tutorial_overlay.next_pressed.connect(_advance_day_one_hud_tour)
	tutorial_overlay.skip_pressed.connect(_skip_day_one_tutorial)

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
	tutorial_sukli_generation += 1
	tutorial_sukli_ready = false
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
	shop_cta_glow = Panel.new()
	shop_cta_glow.name = "ShopCtaGlow"
	shop_cta_glow.size = SHOP_BUTTON_SIZE + Vector2(18.0, 18.0)
	shop_cta_glow.z_index = 54
	shop_cta_glow.z_as_relative = false
	shop_cta_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_cta_glow.add_theme_stylebox_override("panel", KwentaStyle.box(Color(1.0, 0.72, 0.16, 0.20), Color("ffd45b"), 14, 4, 4, 3, 12))
	shop_cta_glow.hide()
	add_child(shop_cta_glow)
	shop_button = Button.new()
	shop_button.name = "ShopIconButton"
	shop_button.position = _shop_button_position()
	shop_button.size = SHOP_BUTTON_SIZE
	shop_button.z_index = 55
	shop_button.z_as_relative = false
	KwentaStyle.style_button(shop_button, KwentaStyle.PAPER_DARK, 28)
	var grayscale_shader := Shader.new()
	grayscale_shader.code = "shader_type canvas_item; uniform bool grayscale = false; void fragment() { if (grayscale) { float gray = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114)); COLOR.rgb = vec3(gray); } }"
	var button_material := ShaderMaterial.new()
	button_material.shader = grayscale_shader
	shop_button.material = button_material
	var notebook_icon := SUPPLIER_NOTEBOOK_ICON.new()
	notebook_icon.name = "SupplierNotebookIcon"
	notebook_icon.position = Vector2(16, 12)
	notebook_icon.size = Vector2(42, 50)
	notebook_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notebook_icon.use_parent_material = true
	shop_button.add_child(notebook_icon)
	shop_order_cue = Label.new()
	shop_order_cue.name = "ShopOrderCue"
	shop_order_cue.text = "ORDER"
	shop_order_cue.position = Vector2(4.0, -16.0)
	shop_order_cue.size = Vector2(66.0, 15.0)
	shop_order_cue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_order_cue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shop_order_cue.add_theme_font_size_override("font_size", 11)
	shop_order_cue.add_theme_color_override("font_color", Color("ffd45b"))
	shop_order_cue.add_theme_color_override("font_outline_color", Color("2b1a10"))
	shop_order_cue.add_theme_constant_override("outline_size", 4)
	shop_order_cue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_button.add_child(shop_order_cue)
	shop_locked_cue = HUD_ICON.new().setup(HUD_ICON.Kind.CLOCK, 19.0, Color("2b1a10"), Color("f2dfb9"))
	shop_locked_cue.name = "ShopLockedCue"
	shop_locked_cue.position = Vector2(50.0, 49.0)
	shop_locked_cue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_locked_cue.hide()
	shop_button.add_child(shop_locked_cue)
	shop_button.tooltip_text = "Open Inay's supplier list"
	shop_button.visible = false
	shop_button.pressed.connect(_open_shelf_shop)
	add_child(shop_button)

func _shop_button_position() -> Vector2:
	# Keep the notebook centered under Pause in the shared right-side rail.
	var scale := _hud_scale()
	var rail_center_x := _right_hud_rail_center_x()
	return Vector2(rail_center_x - SHOP_BUTTON_SIZE.x * scale * 0.5, HUD_TOP_Y + (PAUSE_BUTTON_SIZE.y + HUD_RAIL_GAP) * scale)

func _utang_button_position() -> Vector2:
	var scale := _hud_scale()
	var rail_center_x := _right_hud_rail_center_x()
	return Vector2(rail_center_x - UTANG_BUTTON_SIZE.x * scale * 0.5, HUD_TOP_Y + (PAUSE_BUTTON_SIZE.y + HUD_RAIL_GAP + SHOP_BUTTON_SIZE.y + HUD_RAIL_GAP) * scale)

func _pause_button_position() -> Vector2:
	var scale := _hud_scale()
	var margin := maxf(20.0, HUD_SAFE_MARGIN * scale)
	return Vector2(size.x - margin - PAUSE_BUTTON_SIZE.x * scale, HUD_TOP_Y)

func _right_hud_rail_center_x() -> float:
	var scale := _hud_scale()
	var margin := maxf(20.0, HUD_SAFE_MARGIN * scale)
	return size.x - margin - PAUSE_BUTTON_SIZE.x * scale * 0.5

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
	if event.ctrl_pressed and event.alt_pressed and event.shift_pressed and event.keycode == KEY_B:
		trigger_day_six_brownout()
		return
	if event.ctrl_pressed and event.alt_pressed and event.shift_pressed and event.keycode == KEY_K:
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

func _build_fiesta_emergency_light() -> void:
	fiesta_emergency_light = ColorRect.new()
	fiesta_emergency_light.name = "FiestaEmergencyLight"
	fiesta_emergency_light.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fiesta_emergency_light.z_index = 21
	fiesta_emergency_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	# One lamp illuminates the storefront, products and customers together.
	# Share its source with the prop so illumination stays anchored to the flame.
	shader.code = """
shader_type canvas_item;
uniform bool lights_arrived = false;
uniform float ignition : hint_range(0.0, 1.0) = 0.0;
uniform vec2 lamp_source;
uniform vec2 viewport_size = vec2(1920.0, 1080.0);
void fragment() {
	vec2 p = UV * viewport_size;
	vec2 delta = p - lamp_source;
	float distance_from_lamp = length(delta / vec2(880.0, 600.0));
	float falloff = exp(-distance_from_lamp * 1.35);
	float core = exp(-dot(delta / vec2(210.0, 230.0), delta / vec2(210.0, 230.0)) * 1.5);
	float flicker = 1.0 + sin(TIME * 2.1) * 0.012 + sin(TIME * 5.3) * 0.006;
	float light = lights_arrived ? (falloff * 0.72 + core * 0.16) * flicker * ignition : 0.0;
	vec3 shadow = mix(vec3(0.018, 0.025, 0.05), vec3(0.24, 0.115, 0.025), light);
	COLOR = vec4(shadow, 0.76 - light * 0.78);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	fiesta_emergency_light.material = material
	material.set_shader_parameter("lamp_source", preload("res://scripts/fiesta_light_props.gd").FLAME_POSITION)
	fiesta_emergency_light.hide()
	add_child(fiesta_emergency_light)
	fiesta_light_props = preload("res://scripts/fiesta_light_props.gd").new()
	fiesta_light_props.name = "FiestaLightProps"
	fiesta_light_props.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	fiesta_light_props.z_index = 22
	fiesta_light_props.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fiesta_light_props.hide()
	add_child(fiesta_light_props)
	_layout_fiesta_blackout()

func _layout_fiesta_blackout() -> void:
	if is_instance_valid(fiesta_emergency_light):
		var material := fiesta_emergency_light.material as ShaderMaterial
		if material != null:
			material.set_shader_parameter("viewport_size", size)
			material.set_shader_parameter("lamp_source", preload("res://scripts/fiesta_light_props.gd").FLAME_POSITION + _ui_offset())
	if is_instance_valid(fiesta_light_props):
		fiesta_light_props.position = _ui_offset()

func _on_fiesta_brownout_story_finished() -> void:
	if environment_day != 6 or not day_six_brownout_triggered:
		return
	shift.start_fiesta_brownout_rush()

func _reveal_fiesta_lampara() -> void:
	if environment_day != 6 or not day_six_brownout_triggered or fiesta_light_props.visible:
		return
	_layout_fiesta_blackout()
	var material := fiesta_emergency_light.material as ShaderMaterial
	material.set_shader_parameter("lights_arrived", true)
	fiesta_light_props.show()
	fiesta_ignition_tween = create_tween()
	fiesta_ignition_tween.tween_property(material, "shader_parameter/ignition", 1.0, 0.85).set_trans(Tween.TRANS_SINE)

func apply_environment(day: int) -> void:
	if fiesta_ignition_tween != null and fiesta_ignition_tween.is_valid():
		fiesta_ignition_tween.kill()
	store_layer_renderer.set_blackout(false)
	atmosphere.set_blackout(false)
	if is_instance_valid(fiesta_emergency_light):
		fiesta_emergency_light.hide()
		(fiesta_emergency_light.material as ShaderMaterial).set_shader_parameter("lights_arrived", false)
		(fiesta_emergency_light.material as ShaderMaterial).set_shader_parameter("ignition", 0.0)
	if is_instance_valid(fiesta_light_props):
		fiesta_light_props.hide()
	environment_day = day
	environment_game_minute = 0
	day_six_brownout_triggered = false
	if brownout_crossfade_tween != null and brownout_crossfade_tween.is_valid():
		brownout_crossfade_tween.kill()
	environment_settings = ENVIRONMENT_BY_DAY.get(day, ENVIRONMENT_BY_DAY[1])
	if audio != null:
		audio.set_ambience(ambience_for_environment_day(day))
		# Normal-day ambience begins only once the store is open, not during the
		# prologue, briefing, or opening-sign animation.
		audio.set_random_ambience("")
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
	environment_game_minute = clampi(game_minute, 0, 720)
	_update_environment_for_time()

func _prepare_environment_textures(settings: Dictionary) -> void:
	environment_textures.clear()
	for key in ["base_path", "evening_path", "night_path", "brownout_path"]:
		var path := str(settings.get(key, ""))
		if not path.is_empty():
			environment_textures[key] = load(path) as Texture2D

func _runtime_environment_settings(texture_key: String) -> Dictionary:
	var runtime_settings := environment_settings.duplicate()
	runtime_settings["base_texture"] = environment_textures.get(texture_key) as Texture2D
	return runtime_settings

func _update_environment_for_time() -> void:
	if environment_day == 6 and day_six_brownout_triggered:
		return
	if environment_settings.is_empty():
		return
	var evening_path := str(environment_settings.get("evening_path", ""))
	if not evening_path.is_empty():
		var start := int(environment_settings.get("evening_start_minute", 480))
		var finish := int(environment_settings.get("evening_end_minute", 600))
		var progress := clampf(float(environment_game_minute - start) / float(maxi(1, finish - start)), 0.0, 1.0)
		var night_texture := environment_textures.get("night_path") as Texture2D
		var night_start := int(environment_settings.get("night_start_minute", 540))
		if night_texture != null and environment_game_minute >= night_start:
			var night_end := int(environment_settings.get("night_end_minute", 600))
			var night_progress := clampf(float(environment_game_minute - night_start) / float(maxi(1, night_end - night_start)), 0.0, 1.0)
			store_layer_renderer.set_time_blend_base(environment_textures.get("evening_path") as Texture2D)
			store_layer_renderer.set_front_background_alpha(0.0)
			store_layer_renderer.set_environment_crossfade(night_texture, night_progress)
		else:
			if night_texture != null:
				store_layer_renderer.set_time_blend_base(null)
			store_layer_renderer.set_environment_crossfade(environment_textures.get("evening_path") as Texture2D, progress)
			store_layer_renderer.set_front_background_alpha(1.0 - progress)
		if night_texture != null:
			store_layer_renderer.set_time_sunbeam_alpha(0.65 * (1.0 - progress))
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
	if audio != null:
		audio.play_persistent_cue("explosion")
	store_layer_renderer.set_blackout(true)
	atmosphere.set_blackout(true)
	_play_brownout_flicker()
	_layout_fiesta_blackout()
	fiesta_emergency_light.modulate.a = 0.0
	fiesta_emergency_light.show()
	store_layer_renderer.start_environment_crossfade(brownout_texture, 1.5)
	brownout_crossfade_tween = create_tween()
	brownout_crossfade_tween.tween_property(fiesta_emergency_light, "modulate:a", 1.0, 1.5)
	brownout_crossfade_tween.tween_callback(_finish_day_six_brownout)

func _finish_day_six_brownout() -> void:
	store_layer_renderer.apply_environment(_runtime_environment_settings("brownout_path"))
	store_layer_renderer.clear_environment_crossfade()

func _debug_set_environment_time(game_minute: int) -> void:
	debug_environment_time_override = clampi(game_minute, 0, 720)
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
	bubble.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bubble)
	bubble.advanced.connect(_on_bubble_advanced)
	bubble.choice_made.connect(_on_bubble_choice)
	bubble.conversation_finished.connect(_on_bubble_conversation_finished)
	bubble.speech_started.connect(_on_bubble_speech_started)

func _on_bubble_choice(index: int) -> void:
	if story_events != null and story_events.is_active():
		return
	if index < 0 or index >= current_choice_ids.size():
		return
	_select_story_choice(current_choice_data, current_choice_ids[index])

func _on_bubble_advanced() -> void:
	if story_transition_active:
		return
	if (showing_pre_shift_briefing and story_after_action != "supplier_delivery_done") or story_after_action.is_empty():
		return
	if story_events != null and story_events.is_active():
		return
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
	shift.cash_sale_completed.connect(_on_cash_sale_completed)
	shift.payment_started.connect(_on_sukli_payment_started)
	shift.cash_changed.connect(_update_cash)
	shift.clock_changed.connect(_update_clock)
	shift.game_minutes_changed.connect(_on_game_minutes_changed)
	shift.closing_started.connect(_on_shift_closing)
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
		drag_item.connect("product_drag_moved", _on_product_drag_moved)
		drag_item.connect("product_drag_ended", _clear_drag_hover)
		drag_item.connect("product_released", _on_product_drag_released)
		product_items_by_id[game_id] = drag_item
		shadow_rects.append(display_rect)
	campaign.set_stocked_product_ids(stocked_game_ids)
	if atmosphere != null:
		atmosphere.set_product_shadows(shadow_rects)

func _sync_product_pickup_rects() -> void:
	if not is_instance_valid(store_layer_renderer): return
	var config := StoreConfig.load_config("res://data/store_config.json")
	var shadow_rects: Array[Rect2] = []
	for entry in StoreConfig.get_stocked_entries(config, campaign.day, campaign.purchased_store_groups):
		var item: Control = product_items_by_id.get(str(entry.get("game_product_id", "")))
		if not is_instance_valid(item): continue
		var store_id := str(entry.get("id", ""))
		var slot := store_layer_renderer.get_slot_rect(store_id)
		var display_rect := store_layer_renderer.get_product_display_rect(store_id)
		item.position = slot.position
		item.size = slot.size
		item.set("_drag_preview_size", display_rect.size)
		shadow_rects.append(display_rect)
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

func _on_customer_served(_customer_id: String, product_types: int) -> void:
	# A completed sale is the authoritative end of the first drag lesson. This
	# signal survives the customer actor being removed before the drag callback
	# finishes, so the overlay cannot follow a customer who has already left.
	if campaign.day == 1 and not tutorial_delivery_seen:
		tutorial_delivery_seen = true
		_remember_tutorial("day1_drag")
		_clear_tutorial_spotlight()
		_show_tutorial_hint("Good! Serve every icon in the bubble before patience runs out.")
	if daily_goal == null:
		return
	var was_complete: bool = daily_goal.is_complete()
	var is_suki := false
	for customer in shift.active_customers:
		if customer.customer_id == _customer_id and customer.is_suki:
			is_suki = true
			break
	daily_goal.record_customer_served(product_types, _customer_id, is_suki)
	_refresh_daily_goal_hud()
	if not was_complete and daily_goal.is_complete():
		_show_daily_goal_achievement()

func _on_cash_sale_completed(customer_instance_id: String, goods_total: int) -> void:
	if goods_total <= 0:
		return
	var actor: Control = customer_actors.get(customer_instance_id)
	if not is_instance_valid(actor):
		return
	var at := actor.global_position - global_position + Vector2(actor.size.x - 36.0, 165.0)
	_float_text(at, "+₱%d" % goods_total, Color("d9efaa"), "SalePriceFeedback")

func _show_daily_goal_achievement() -> void:
	if daily_goal == null or campaign == null:
		return
	_play_goal_sound_once()
	var notice := PanelContainer.new()
	notice.name = "DailyGoalAchievementNotice"
	notice.z_index = 38
	notice.position = Vector2(33, 100) + _ui_offset()
	notice.custom_minimum_size = Vector2(480, 110)
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.add_theme_stylebox_override("panel", KwentaStyle.box(Color("f8e8c6"), Color("80532c"), 16, 10, 10, 4, 5))
	add_child(notice)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.add_child(row)
	var medal := TextureRect.new()
	medal.name = "AchievementMedal"
	medal.texture = load("res://assets/ui/daily_medals/day_%d.png" % campaign.day) as Texture2D
	medal.custom_minimum_size = Vector2(84, 84)
	medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(medal)
	var text_column := VBoxContainer.new()
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_column)
	text_column.add_child(KwentaStyle.make_label("DAILY GOAL COMPLETE!", 25, Color("82511f")))
	var goal_text := KwentaStyle.make_label(daily_goal.title, 24, KwentaStyle.INK)
	goal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_text.custom_minimum_size.x = 330
	text_column.add_child(goal_text)
	notice.modulate.a = 0.0
	var animation := create_tween()
	animation.tween_property(notice, "modulate:a", 1.0, 0.18)
	animation.tween_interval(2.6)
	animation.tween_property(notice, "modulate:a", 0.0, 0.35)
	animation.tween_callback(notice.queue_free)

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
		if leaving == drag_hover_customer:
			_clear_drag_hover()
		customer_actors.erase(instance_id)
		_clear_angry_customer(instance_id)
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
			actor.connect("product_dropped", _on_product_dropped)
			actor.connect("payment_tapped", _on_payment_tapped)
			actor.connect("became_impatient", _on_customer_became_impatient)
			actor.connect("calmed_down", _on_customer_calmed_down)
			actor.call("set_customer", customer, products_by_id)
			var from_right := randf() < 0.5
			actor.position = Vector2(1980.0 if from_right else -270.0, STOREFRONT_LAYOUT.CUSTOMER_Y)
			actor.modulate.a = 0.0
			customer_layer.add_child(actor)
			actor.call("set_facing_right", from_right)
			customer_actors[customer.instance_id] = actor
			if campaign.day == 5 and customer.is_suki and not bool(completed_tutorials.get("day5_suki", false)):
				_show_suki_intro.call_deferred(customer.instance_id)
			var entrance := create_tween()
			entrance.set_parallel(true)
			entrance.tween_property(actor, "position:x", target_x, 0.58).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			entrance.tween_property(actor, "modulate:a", 1.0, 0.20)
		else:
			actor.call("set_customer", customer, products_by_id)
			if not is_equal_approx(actor.position.x, target_x):
				create_tween().tween_property(actor, "position:x", target_x, 0.22)

func _show_suki_intro(instance_id: String) -> void:
	await get_tree().create_timer(0.7).timeout
	var actor: Control = customer_actors.get(instance_id)
	while is_instance_valid(actor) and shift.is_running and not bool(completed_tutorials.get("day5_suki", false)) and (shift.frozen or tutorial_step != TutorialStep.NONE or story_events.is_active()):
		await get_tree().create_timer(0.5).timeout
		actor = customer_actors.get(instance_id)
	if not is_instance_valid(actor) or not shift.is_running or bool(completed_tutorials.get("day5_suki", false)): return
	var name_tag: Control = actor.get("name_tag")
	if not is_instance_valid(name_tag): return
	_remember_tutorial("day5_suki")
	shift.frozen = true
	tutorial_step = TutorialStep.DAY5_SUKI
	tutorial_overlay.show_info_step("Ginto ang pangalan ng mga suki.", _tutorial_rect_for(name_tag), "SUKI", true)

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
		_show_tutorial_spotlight(TutorialStep.DAY1_CUSTOMER, "Keep holding, then drag the product to the highlighted customer and release.", actor, "SERVE THE CUSTOMER")
		tutorial_overlay.show_skip()
		var product: Control = product_items_by_id.get(tutorial_product_id)
		if is_instance_valid(product):
			tutorial_overlay.show_drag_arrow(_tutorial_product_rect(tutorial_product_id, product), _tutorial_rect_for(actor))

func _on_product_drag_moved(viewport_position: Vector2) -> void:
	var hovered := _customer_actor_at(viewport_position)
	if hovered == drag_hover_customer:
		return
	_clear_drag_hover()
	drag_hover_customer = hovered
	if is_instance_valid(drag_hover_customer):
		drag_hover_customer.call("set_drag_hovered", true)

func _clear_drag_hover() -> void:
	if is_instance_valid(drag_hover_customer):
		drag_hover_customer.call("set_drag_hovered", false)
	drag_hover_customer = null

func _on_product_drag_released(product_id: String, viewport_position: Vector2, source: Control) -> void:
	var actor := _customer_actor_at(viewport_position)
	var accepted := false
	if actor != null:
		var customer: CustomerState = actor.get("customer")
		accepted = customer != null and _resolve_product_delivery(customer.instance_id, product_id)
	source.call("finish_drag", accepted)
	# A missed or rejected drop leaves the customer step active. Return to the
	# product step so the player can pick it up and try again.
	if campaign.day == 1 and tutorial_step == TutorialStep.DAY1_CUSTOMER:
		_show_day_one_product_step()

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
			if result == OrderState.DeliveryResult.WRONG_PRODUCT:
				_float_text(actor.global_position - global_position + Vector2(15, 110), "HINDI 'YAN!", Color("ffb0a2"))
		return false
	if is_instance_valid(actor):
		actor.call("refresh_display")
		actor.call("play_correct_drop")
		if result == OrderState.DeliveryResult.COMPLETED and not _is_waiting_for_change(actor):
			actor.call("play_happy")
	if campaign.day == 1 and tutorial_step in [TutorialStep.DAY1_PRODUCT, TutorialStep.DAY1_CUSTOMER] and product_id == tutorial_product_id:
		tutorial_delivery_seen = true
		_remember_tutorial("day1_drag")
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
	return "rain" if day == 4 else ""

func random_ambience_for_environment_day(day: int) -> String:
	return "normal_day" if day in [1, 2, 3, 5, 7] else ""

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
	_clear_all_angry_customers()
	if is_instance_valid(story_illustration):
		story_illustration.visible = false
	_hide_store_sign()
	shift_in_progress = false
	_refresh_shop_button()
	if story_events != null:
		story_events.end_shift()
	if pause_menu != null:
		pause_menu.set_available(false)
	if debug_skip_button != null:
		debug_skip_button.visible = false
	showing_shift_results = false
	if daily_goal != null:
		var goal_was_complete: bool = daily_goal.is_complete()
		daily_goal.finalize(campaign.count_trusted_regulars(), campaign.barangay_trust)
		if not goal_was_complete and daily_goal.is_complete():
			_play_goal_sound_once()
		_refresh_daily_goal_hud()
	var summary_text_value := "TODAY'S SALES\nBenta ngayon: ₱%d\nPera sa kaha: ₱%d\nCustomers served: %d\nCustomers na umalis: %d" % [shift.shift_earnings, campaign.cash, shift.customers_served, shift.customers_timed_out]
	if campaign.day == 6 and shift.fiesta_route == "alone":
		summary_text_value += "\nDagdag ni Inay — 20%%: ₱%d\nBatayan: ₱%d na bayad na paninda (walang tips o singil sa utang)" % [shift.fiesta_bonus, shift.paid_goods_sales]
	if shift.debt_payments_received > 0:
		summary_text_value += "\nBayad sa utang: ₱%d" % shift.debt_payments_received
	if daily_goal != null:
		var goal_heading := "DAILY GOAL COMPLETE!" if daily_goal.is_complete() else "DAILY GOAL"
		var goal_result: String = str(daily_goal.title) if daily_goal.is_complete() else "%s: Not completed — no penalty" % daily_goal.title
		summary_text_value += "\n\n%s\n%s" % [goal_heading, goal_result]
	if shift.change_total > 0:
		summary_text_value += "\n\nSUKLI\nTamang sukli: %d / %d\nPinakamahabang streak: %d" % [shift.change_correct, shift.change_total, shift.best_change_streak]
	if shift.change_total > 0:
		var avg_satisfaction := int(shift.total_satisfaction_score / shift.change_total)
		summary_text_value += "\nAverage satisfaction sa sukli: %d%%" % avg_satisfaction
		if shift.total_tips_earned > 0:
			summary_text_value += "\nTips na nakuha: ₱%d" % shift.total_tips_earned
	pending_shift_summary_text = summary_text_value
	pending_shift_summary_title = "DAY %d COMPLETE" % campaign.day
	if campaign.day == 2:
		var sukli_result := "none"
		if shift.change_total > 0:
			sukli_result = "perfect" if shift.change_correct == shift.change_total else "mistakes"
		story.choices["day2_sukli_result"] = sukli_result
	if tutorial_step == TutorialStep.DAY1_CLOSING:
		await day_one_closing_tutorial_finished
	if campaign.day != 1:
		await _play_final_closing_sign()
	if campaign.day == 7:
		story.write_diary_entry(7)
	_show_story_beats(story.get_day_outro_beats(campaign.day), pending_shift_summary_title, "day_choices")

func _on_summary_button_pressed() -> void:
	if story_transition_active:
		return
	if story_complete:
		_restart_story()
		return
	if showing_pre_shift_briefing:
		showing_pre_shift_briefing = false
		summary_backdrop.visible = false
		summary_panel.visible = false
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

func _build_prologue_background() -> void:
	var prologue_backdrop := ColorRect.new()
	prologue_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prologue_backdrop.color = Color("21150f")
	prologue_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prologue_backdrop.z_index = 38
	prologue_backdrop.visible = false
	add_child(prologue_backdrop)
	prologue_background = TextureRect.new()
	prologue_background.texture = load("res://assets/story/tonyo_bedroom.png") as Texture2D
	prologue_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# Fill every viewport without distortion; crop only outer edges on non-16:9 displays.
	prologue_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	prologue_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prologue_background.z_index = 38
	prologue_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prologue_background.visible = false
	add_child(prologue_background)
	prologue_background.visibility_changed.connect(func(): prologue_backdrop.visible = prologue_background.visible)
	prologue_fade = ColorRect.new()
	prologue_fade.color = Color.BLACK
	prologue_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prologue_fade.z_index = 49
	prologue_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	prologue_fade.visible = false
	add_child(prologue_fade)
	day7_time_label = Label.new()
	day7_time_label.name = "DaySevenTimeCard"
	day7_time_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	day7_time_label.text = "Kinabukasan..."
	day7_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day7_time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	day7_time_label.add_theme_font_size_override("font_size", 48)
	day7_time_label.add_theme_color_override("font_color", Color.WHITE)
	day7_time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	day7_time_label.z_index = 50
	day7_time_label.visible = false
	add_child(day7_time_label)

func _build_day_two_visuals() -> void:
	var illustration_backdrop := ColorRect.new()
	illustration_backdrop.name = "StoryIllustrationBackdrop"
	illustration_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	illustration_backdrop.color = Color("21150f")
	illustration_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	illustration_backdrop.z_index = 39
	illustration_backdrop.visible = false
	add_child(illustration_backdrop)
	story_illustration_previous = TextureRect.new()
	story_illustration_previous.name = "PreviousStoryIllustration"
	story_illustration_previous.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	story_illustration_previous.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	story_illustration_previous.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	story_illustration_previous.z_index = 39
	story_illustration_previous.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story_illustration_previous.hide()
	add_child(story_illustration_previous)
	story_illustration = TextureRect.new()
	story_illustration.name = "DayTwoStoryIllustration"
	story_illustration.texture = load("res://assets/story/day2_box_fall.png") as Texture2D
	_update_story_illustration_fit()
	story_illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	story_illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	story_illustration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	story_illustration.z_index = 39
	story_illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story_illustration.visible = false
	add_child(story_illustration)
	var update_backdrop := func(): illustration_backdrop.visible = story_illustration.visible or story_illustration_previous.visible
	story_illustration.visibility_changed.connect(update_backdrop)
	story_illustration_previous.visibility_changed.connect(update_backdrop)
	_update_story_illustration_fit()
func _update_story_illustration_fit() -> void:
	if story_illustration.texture == null:
		return
	# Fill every viewport without distortion; crop only outer edges on non-16:9 displays.
	story_illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	story_illustration_previous.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

func _is_paolo_debt_recorded() -> bool:
	# Later-day saves and debug starts have already passed the Day 4 lesson.
	return story.get_choice("day3_candy") == "credit" and (campaign.day > 4 or story.get_choice("paolo_debt_recorded") == "yes")

func _show_story_prop(prop_name: String) -> void:
	if prop_name == "fiesta_lampara":
		_reveal_fiesta_lampara()
		return
	if prop_name == "utang_ledger":
		utang_ledger.show_records(campaign, _is_paolo_debt_recorded(), story.get_choice("day5_debt") == "installments")
		return
	if prop_name == "hide_utang_ledger":
		utang_ledger.visible = false
		return
	if prop_name == "paolo_debt_note":
		paolo_debt_note.show_note()
		return
	if prop_name == "hide_paolo_debt_note":
		paolo_debt_note.visible = false
		return
	if not is_instance_valid(story_illustration):
		return
	if prop_name == "berting_counter_closeup":
		_show_gallery_illustration("res://assets/story/berting_counter_50.png")
	elif prop_name == "umbrella_handoff":
		_show_gallery_illustration("res://assets/story/day4_tonyo_lends_umbrella_stocked_tonyo.png")
	elif prop_name == "fiesta_powerline":
		_show_gallery_illustration("res://assets/story/day6_fiesta_powerline.png")
	elif prop_name == "rosa_payment":
		_show_gallery_illustration("res://assets/story/day5_rosa_payment.png")
	elif prop_name == "paolo_coins":
		_show_gallery_illustration("res://assets/story/day3_paolo_coins_casual.png")
	elif prop_name == "lina_walking_away":
		_show_gallery_illustration("res://assets/story/day4_lina_alfa_corner.png")
	elif prop_name == "friends_shelter":
		_show_gallery_illustration("res://assets/story/day4_friends_shelter.png")
	elif prop_name == "alfa_save_corner":
		_show_gallery_illustration("res://assets/story/day4_alfa_save_corner.png")
	elif prop_name in ["hide_lina_walking_away", "hide_scene_illustration", "hide_berting_closeup"]:
		_hide_gallery_illustration()

func _stop_illustration_transition() -> void:
	if story_illustration_tween != null and story_illustration_tween.is_valid():
		story_illustration_tween.kill()
	if is_instance_valid(story_illustration_previous):
		story_illustration_previous.hide()
		story_illustration_previous.modulate.a = 1.0

func _show_gallery_illustration(path: String, smooth: bool = true) -> void:
	if path != "res://assets/story/day6_fiesta_fireworks.png" and audio != null:
		audio.stop_fireworks()
	var next_texture := load(path) as Texture2D
	if next_texture == null: return
	if story_illustration.visible and story_illustration.texture == next_texture:
		preload("res://scripts/illustration_catalog.gd").record_seen(story, path)
		return
	var old_texture := story_illustration.texture if story_illustration.visible else (story_illustration_previous.texture if story_illustration_previous.visible else null)
	_stop_illustration_transition()
	if smooth and old_texture != null and old_texture != next_texture:
		story_illustration_previous.texture = old_texture
		story_illustration_previous.show()
	story_illustration.texture = next_texture
	_update_story_illustration_fit()
	story_illustration.modulate.a = 0.0 if smooth else 1.0
	story_illustration.visible = true
	if smooth:
		story_illustration_tween = create_tween().set_parallel(true)
		story_illustration_tween.tween_property(story_illustration, "modulate:a", 1.0, 0.38).set_trans(Tween.TRANS_SINE)
		if story_illustration_previous.visible:
			story_illustration_tween.tween_property(story_illustration_previous, "modulate:a", 0.0, 0.38).set_trans(Tween.TRANS_SINE)
			story_illustration_tween.chain().tween_callback(story_illustration_previous.hide)
	preload("res://scripts/illustration_catalog.gd").record_seen(story, path)

func _hide_gallery_illustration() -> void:
	if audio != null:
		audio.stop_fireworks()
	if not is_instance_valid(story_illustration) or not story_illustration.visible: return
	var old_texture := story_illustration.texture
	_stop_illustration_transition()
	story_illustration_previous.texture = old_texture
	story_illustration_previous.modulate.a = story_illustration.modulate.a
	story_illustration_previous.show()
	story_illustration.hide()
	story_illustration.modulate.a = 1.0
	story_illustration_tween = create_tween()
	story_illustration_tween.tween_property(story_illustration_previous, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_SINE)
	story_illustration_tween.tween_callback(story_illustration_previous.hide)

func _present_prologue() -> void:
	preload("res://scripts/illustration_catalog.gd").record_seen(story, "res://assets/story/tonyo_bedroom.png")
	prologue_background.visible = true
	prologue_fade.visible = false
	_show_story_beats(story.get_prologue_beats(), "PROLOGUE", "prologue_end")

func _transition_prologue_to_day_one() -> void:
	bubble.close()
	prologue_fade.modulate.a = 0.0
	prologue_fade.visible = true
	var fade_out := create_tween()
	fade_out.tween_property(prologue_fade, "modulate:a", 1.0, 0.45)
	await fade_out.finished
	prologue_background.visible = false
	await bubble.title_card("DAY 1")
	var fade_in := create_tween()
	fade_in.tween_property(prologue_fade, "modulate:a", 0.0, 0.45)
	await fade_in.finished
	prologue_fade.visible = false
	_show_story_beats(story.get_day_intro_beats(1), "DAY 1", "day1_intro")

func _present_day_intro() -> void:
	# The previous day’s illustration stays visible through its final dialogue.
	story_illustration.visible = false
	_show_story_beats(story.get_day_intro_beats(campaign.day), "DAY %d" % campaign.day, "start_shift")

func _show_story_beats(beats: Array[Dictionary], title: String, after_action: String) -> void:
	if after_action in ["start_shift", "day1_intro"]:
		supplier_story_blocked = true
		_refresh_shop_button()
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
	if is_instance_valid(utang_ledger):
		utang_ledger.visible = false
	if story_beat_index >= story_beats.size():
		_complete_story_beats()
		return
	var beat: Dictionary = story_beats[story_beat_index]
	if bool(beat.get("record_paolo_debt", false)):
		story.choices["paolo_debt_recorded"] = "yes"
	if str(beat.get("show_prop", "")) == "utang_ledger":
		utang_ledger.show_records(campaign, _is_paolo_debt_recorded(), story.get_choice("day5_debt") == "installments")
	if beat.has("story_visitor") and story_events != null:
		bubble.close()
		story_events.present_outro_visitor(str(beat["story_visitor"]))
		await story_events.story_visitor_tapped
	if str(beat.get("cutscene", "")) == "day7_time_card":
		story_transition_active = true
		_set_shop_input_blocked(true)
		pause_menu.set_available(false)
		bubble.close()
		prologue_fade.modulate.a = 0.0
		prologue_fade.visible = true
		var blackout := create_tween()
		blackout.tween_property(prologue_fade, "modulate:a", 1.0, 0.6)
		await blackout.finished
		day7_time_label.visible = true
		day7_time_label.modulate.a = 0.0
		var title_fade := create_tween()
		title_fade.tween_property(day7_time_label, "modulate:a", 1.0, 0.8)
		title_fade.tween_interval(1.4)
		title_fade.tween_property(day7_time_label, "modulate:a", 0.0, 0.6)
		await title_fade.finished
		day7_time_label.visible = false
		story_transition_active = false
		story_beat_index += 1
		_show_current_story_beat()
		return
	if str(beat.get("cutscene", "")) == "day7_walk":
		story_transition_active = true
		# The silent montage hides the dialogue's input shield. Disable the
		# underlying shop through the ending, including any drag already held.
		_set_shop_input_blocked(true)
		pause_menu.set_available(false)
		bubble.close()
		_show_gallery_illustration("res://assets/story/day7_classroom_seated.png", false)
		var classroom_fade := create_tween()
		classroom_fade.tween_property(prologue_fade, "modulate:a", 0.0, 0.5)
		await classroom_fade.finished
		prologue_fade.visible = false
		await get_tree().create_timer(0.65).timeout
		_show_gallery_illustration("res://assets/story/day7_classroom_stand.png", false)
		await get_tree().create_timer(0.65).timeout
		_show_gallery_illustration("res://assets/story/day7_classroom_front_back.png", false)
		await get_tree().create_timer(0.65).timeout
		_show_gallery_illustration("res://assets/story/day7_classroom_turn.png", false)
		await get_tree().create_timer(0.65).timeout
		story_transition_active = false
	elif str(beat.get("cutscene", "")) == "day7_classmates":
		_show_gallery_illustration("res://assets/story/day7_classmates_listening.png")
	elif str(beat.get("cutscene", "")) == "day7_tonyo_face":
		_show_gallery_illustration("res://assets/story/day7_tonyo_presenting.png")
	elif str(beat.get("cutscene", "")) == "box_fall":
		_show_gallery_illustration("res://assets/story/day2_box_fall.png")
	elif str(beat.get("cutscene", "")) == "day3_project":
		_show_gallery_illustration("res://assets/story/day3_project_box.png")
	elif str(beat.get("cutscene", "")) == "day7_project":
		_show_gallery_illustration("res://assets/story/day7_tonyo_miniature.png")
	elif str(beat.get("cutscene", "")) == "day4_alfa_save":
		_show_gallery_illustration("res://assets/story/day4_alfa_save_corner.png")
	elif str(beat.get("cutscene", "")) == "day6_fireworks":
		if audio != null:
			audio.play_fireworks()
		_show_gallery_illustration("res://assets/story/day6_fiesta_fireworks.png")
	elif str(beat.get("cutscene", "")) == "day5_wakes":
		_show_gallery_illustration("res://assets/story/day5_tonyo_wakes.png")
	elif str(beat.get("cutscene", "")) == "day5_phone":
		_show_gallery_illustration("res://assets/story/day5_tonyo_phone_v2.png")
	elif str(beat.get("cutscene", "")) == "day5_to_store":
		bubble.close()
		prologue_fade.modulate.a = 0.0
		prologue_fade.visible = true
		var fade_out := create_tween()
		fade_out.tween_property(prologue_fade, "modulate:a", 1.0, 0.4)
		await fade_out.finished
		story_illustration.visible = false
		var fade_in := create_tween()
		fade_in.tween_property(prologue_fade, "modulate:a", 0.0, 0.4)
		await fade_in.finished
		prologue_fade.visible = false
	elif str(beat.get("cutscene", "")) == "end":
		_hide_gallery_illustration()
	var speaker: String = str(beat.get("speaker", "Narrator"))
	var portrait_id: String = str(beat.get("portrait", ""))
	var text: String = str(beat.get("text", ""))
	if bool(beat.get("phone_ring", false)):
		var ring := AudioStreamPlayer.new()
		ring.stream = load("res://assets/audio/pixabay/sfx/supplier_phone_ring.wav") as AudioStream
		add_child(ring)
		ring.finished.connect(ring.queue_free)
		ring.play()
	if bool(beat.get("supplier_note", false)):
		bubble.close()
		supplier_note.present()
		await supplier_note.closed
	if bool(beat.get("close_store", false)):
		bubble.close()
		await _play_final_closing_sign()
	if str(beat.get("environment", "")) == "afternoon":
		var afternoon_texture := environment_textures.get("evening_path") as Texture2D
		if afternoon_texture != null:
			store_layer_renderer.start_environment_crossfade(afternoon_texture, 1.2)
	if bool(beat.get("light_flicker", false)):
		_play_brownout_flicker()


	# A beat can carry "cash" (e.g. a tip) that is paid out when the beat appears.
	var bonus := int(beat.get("cash", 0))
	if str(beat.get("debt_payment", "")) == "paolo_story":
		campaign.add_debt("paolo_story", "paolo", 3, 0, 6, {}, true)
		shift.debt_payments_received += campaign.repay_debt("paolo_story", 3)
		_update_cash(campaign.cash)
	if bonus != 0:
		campaign.cash += bonus
		_update_cash(campaign.cash)

	summary_backdrop.visible = false
	summary_panel.visible = false
	var portrait_tex: Texture2D = null
	if not portrait_id.is_empty():
		portrait_tex = load("res://assets/characters/supplier_ben/supplier_delivery.png") as Texture2D if portrait_id == "supplier_ben" else COUNTER_ART.customer_portrait(portrait_id, PORTRAIT_ATLAS)
	bubble.show_beat(speaker, text, portrait_tex, portrait_id)

func _complete_story_beats() -> void:
	if audio != null:
		audio.stop_fireworks()
	match story_after_action:
		"supplier_delivery_done":
			bubble.close()
			# Purchases roll back to the day checkpoint on restart, so this flag must
			# be saved with campaign progress rather than independently of the order.
			completed_tutorials["supplier_first_delivery"] = true
			shelf_shop.open()
			if supplier_delivery_was_tutorial:
				supplier_delivery_was_tutorial = false
				shelf_shop.show_tutorial_close_hint()
		"prologue_end":
			_transition_prologue_to_day_one()
		"day2_first_customer":
			bubble.close()
			shift.start_shift()
		"start_shift", "day1_intro":
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
			supplier_story_blocked = false
			_refresh_shop_button()
			if campaign.day == 2 and shop_available:
				if bool(completed_tutorials.get("day2_shop", false)):
					resume_briefing_after_shop = true
					_open_shelf_shop()
				else:
					_begin_day_two_shop_tutorial()
			else:
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
		"diary_complete":
			_show_pending_shift_summary()

func _show_next_story_choice() -> void:
	if pending_choice_index >= pending_story_choices.size():
		if choices_before_shift:
			choices_before_shift = false
			supplier_story_blocked = false
			_refresh_shop_button()
			_show_pre_shift_briefing()
			return
		var callbacks := story.get_day_callback_beats(campaign.day)
		_show_story_beats(callbacks, "DAY %d" % campaign.day, "finish_day")
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
	if choice_id == "day2_overpayment" and option_id == "keep":
		story.choices["day2_money_separate"] = "yes"
	var cash_delta := story.get_choice_cash_delta(choice_data, option_id)
	if cash_delta != 0:
		var previous_cash := campaign.cash
		campaign.cash += cash_delta
		_update_cash(campaign.cash)
		if not pending_shift_summary_text.is_empty():
			pending_shift_summary_text = pending_shift_summary_text.replace("Pera sa kaha: ₱%d" % previous_cash, "Pera sa kaha: ₱%d" % campaign.cash)
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
		pending_shift_summary_text = ""
		pending_shift_summary_title = ""
		_advance_story_day()
		return
	if not pending_shift_summary_text.is_empty():
		var entry := story.write_diary_entry(campaign.day)
		_show_story_beats([
			{"speaker": "Narrator", "portrait": "", "text": "Binuksan ni Tonyo ang kuwaderno at isinulat ang nangyari sa araw niya."},
			{"speaker": "Narrator", "portrait": "", "text": "Sa kuwaderno: “%s”" % entry}
		], "DAY %d" % campaign.day, "diary_complete")
		return
	_advance_story_day()

func _show_pending_shift_summary() -> void:
	bubble.close()
	if daily_goal != null:
		story.choices["diary_goal_day_%d" % campaign.day] = "earned" if daily_goal.is_complete() else "missed"
	if not debug_session:
		checkpoint_ready = CAMPAIGN_SAVE.write_progress(campaign, story, completed_tutorials)
		if not checkpoint_ready:
			_show_save_warning()
	showing_post_shift_summary = true
	summary_panel.visible = false
	summary_backdrop.visible = true
	var reward_day := campaign.day if daily_goal != null else 0
	var reward_earned: bool = daily_goal != null and daily_goal.is_complete()
	briefing_card.show_summary(pending_shift_summary_title, pending_shift_summary_text, size, reward_day, reward_earned)
	if audio != null and not shift_completion_sound_played:
		shift_completion_sound_played = true
		audio.play_persistent_cue("level_complete")
	pending_shift_summary_text = ""
	pending_shift_summary_title = ""

func _advance_story_day() -> void:
	if campaign.day >= CAMPAIGN_CONFIG.campaign_day_count:
		if story_complete:
			return
		story_complete = true
		if not debug_session:
			checkpoint_ready = CAMPAIGN_SAVE.write_progress(campaign, story, completed_tutorials)
			if not checkpoint_ready:
				_show_save_warning()
		bubble.close()
		summary_backdrop.visible = false
		summary_panel.visible = false
		briefing_card.hide_briefing()
		if pause_menu != null:
			pause_menu.set_available(false)
		if audio != null:
			audio.set_dialogue("")
			audio.set_ambience("")
			audio.stop_alert()
		var ending := preload("res://scripts/ending_transition.gd").new()
		ending.credits_requested.connect(func():
			var credits := preload("res://scripts/credits.gd").new()
			credits.closed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
			credits.campaign_board_requested.connect(_open_completed_campaign_board)
			add_child(credits)
		)
		add_child(ending)
		return
	campaign.advance_day()
	new_purchase_groups_today.clear()
	_update_clock("8:00 AM")
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

func _open_completed_campaign_board() -> void:
	if has_node("CampaignBoard"):
		return
	if audio != null:
		audio.set_music("")
	var board := preload("res://scripts/campaign_board.gd").new()
	board.debug_preview = debug_session
	board.tree_exited.connect(func():
		if not is_queued_for_deletion() and is_inside_tree():
			get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
	)
	add_child(board)

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
	completed_tutorials.clear()
	if not debug_session:
		checkpoint_ready = CAMPAIGN_SAVE.write_checkpoint(campaign, story, completed_tutorials)
		if not checkpoint_ready:
			_show_save_warning()
	daily_goal = null
	daily_goal_day = 0
	showing_pre_shift_briefing = false
	resume_briefing_after_shop = false
	new_purchase_groups_today.clear()
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
	story_events._visitor_tutorial_seen = false
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
		goal_sound_played = false
		shift_completion_sound_played = false

func _play_goal_sound_once() -> void:
	if not goal_sound_played and audio != null:
		goal_sound_played = true
		audio.play_persistent_cue("achievement_unlocked")

func _build_briefing_card() -> void:
	briefing_card = BRIEFING_CARD.new()
	briefing_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	briefing_card.start_pressed.connect(_on_briefing_start_pressed)
	briefing_card.diary_requested.connect(func(): pause_menu.diary_reader.open(story))
	add_child(briefing_card)

func _on_briefing_start_pressed() -> void:
	briefing_card.hide_briefing()
	_on_summary_button_pressed()

func _show_pre_shift_briefing() -> void:
	# Retire the intro/choice dialogue before handing input to the briefing.
	showing_pre_shift_briefing = true
	story_after_action = ""
	story_beats.clear()
	story_beat_index = 0
	current_choice_ids.clear()
	current_choice_data.clear()
	bubble.close()
	_ensure_daily_goal()
	shop_available = campaign.day > 1
	_refresh_shop_button()
	var briefing = DAY_BRIEFING.new(campaign.day, daily_goal, CAMPAIGN_CONFIG.product_catalog, StoreConfig.load_config("res://data/store_config.json"), new_purchase_groups_today)
	briefing.shift_detail = "Magsasara ng %s" % _format_game_clock(campaign.get_shift_close_minutes())
	if campaign.day == 6:
		briefing.focus = "Piliin si Mikay o Jun-jun at ang customer. Si Bogs, pindutin lang. May sariling pahinga ang bawat isa." if story.get_choice("day6_help") == "ask" else "Mag-isa: +20% ng bayad na paninda kapag natapos ang shift."
	showing_pre_shift_briefing = true
	summary_panel.visible = false
	summary_backdrop.visible = true
	briefing_card.show_briefing(briefing, size)

func _begin_shift() -> void:
	shift.wait_for_clear_before_first_credit = not bool(completed_tutorials.get("utang_event", false))
	story_events._repayment_marker_tutorial_seen = bool(completed_tutorials.get("utang_repayment_marker", false))
	shift.prioritize_repayment_tutorial = not story_events._repayment_marker_tutorial_seen
	shop_available = false
	shift_in_progress = true
	_refresh_shop_button()
	if pause_menu != null:
		pause_menu.set_available(true)
	if debug_skip_button != null:
		debug_skip_button.visible = debug_controls_visible
	shift_start_credit = {"debts": campaign.debts.duplicate(true), "paid": campaign.paid_purchases.duplicate(true), "completed_customers": campaign.completed_customers.duplicate(true), "purchase_counts": campaign.purchase_counts.duplicate(true)}
	shift_start_choices = story.choices.duplicate(true)
	shift_start_cash = campaign.cash
	shift_start_trust = campaign.customer_trust.duplicate(true)
	_ensure_daily_goal()
	_refresh_daily_goal_hud()
	tutorial_delivery_seen = bool(completed_tutorials.get("day1_drag", false))
	# Keep the campaign's day-by-day patience curve, then layer story-choice
	# consequences on top of it.
	shift.fiesta_route = story.get_choice("day6_help") if campaign.day == 6 else ""
	var modifiers := story.get_day_modifiers(campaign.day)
	var patience := campaign.get_customer_patience_seconds() * float(modifiers.get("patience_mult", 1.0))
	shift.patience_seconds_override = 999999.0 if campaign.day == CAMPAIGN_CONFIG.campaign_day_count else patience
	if campaign.day == 1 and not bool(completed_tutorials.get("day1_hud", false)):
		_begin_day_one_hud_tour()
	else:
		_show_opening_sign()

func _after_opening_sign() -> void:
	if not shift_in_progress:
		return
	opening_sign_active = false
	opening_blocker.visible = false
	store_sign.visible = false
	if story_events != null:
		story_events.begin_shift(campaign.day)
	# Day 1 introduces a clickable visitor before any buying customer enters.
	shift.start_shift(campaign.day != 1 and not (campaign.day == 4 and not bool(completed_tutorials.get("day4_utang", false))))
	_start_opening_ambience()
	if campaign.day == 1 and story_events != null:
		if debug_session and int(debug_launch_data.get("moment", 0)) == 26:
			story_events._waiting_scene.clear()
			shift.story_waiting_for_clear = false
		else:
			story_events._try_start_waiting_scene()
		while story_events.is_active():
			await story_events.popup_state_changed
		if not shift_in_progress or not shift.is_running:
			return
		shift._spawn_customer()
		# Nena's arrival line must finish before the product coachmark appears.
		while story_events.is_active():
			await story_events.popup_state_changed
		if not shift_in_progress or not shift.is_running:
			return
	if campaign.day == 1 and not tutorial_delivery_seen:
		_begin_day_one_drag_tutorial()
	elif campaign.day == 4 and not bool(completed_tutorials.get("day4_utang", false)):
		_remember_tutorial("day4_utang")
		_show_tutorial_hint("Puwedeng buksan ang UTANG LIST sa menu para tingnan ang mga utang.", 8.0)
	elif campaign.day >= 3 and campaign.day != 5:
		_show_tutorial_hint(str(DAY_FOCUS_HINTS.get(campaign.day, "")))

func _start_opening_ambience() -> void:
	if audio == null:
		return
	var cue_name := random_ambience_for_environment_day(campaign.day)
	if not cue_name.is_empty():
		audio.set_ambience(cue_name)

func _begin_day_one_hud_tour() -> void:
	day_one_hud_tour_index = 0
	tutorial_step = TutorialStep.DAY1_HUD
	_show_day_one_hud_tour_step()

func _show_day_one_hud_tour_step() -> void:
	var targets: Array[Control] = [goal_panel, day_label.get_parent().get_parent(), clock_label.get_parent().get_parent(), cash_label.get_parent().get_parent(), trust_tag]
	var titles := ["DAILY GOAL  1 / 5", "DAY  2 / 5", "CLOCK  3 / 5", "CASH  4 / 5", "TIWALA NG BARANGAY  5 / 5"]
	var messages := [
		"This tracks your optional daily goal. Today, serve 3 customers for a reward.",
		"The calendar shows which day of the story you are playing.",
		"This is the in-game time. Today's shift ends at 12:00 PM.",
		"This is your available money. Sales add to it, and shop purchases use it.",
		"Tumataas ang tiwala kapag naasikaso ang customer. Bumababa ito kapag may umalis o nahuli ang sukli."
	]
	var target := targets[day_one_hud_tour_index]
	tutorial_overlay.show_info_step(messages[day_one_hud_tour_index], _tutorial_rect_for(target), titles[day_one_hud_tour_index], day_one_hud_tour_index == targets.size() - 1)

func _advance_day_one_hud_tour() -> void:
	if tutorial_step == TutorialStep.DAY5_SUKI:
		_clear_tutorial_spotlight()
		shift.frozen = false
		return
	if fiesta_preview_step >= 0:
		fiesta_preview_step += 1
		if fiesta_preview_step >= 3:
			_finish_fiesta_preview()
		else:
			_show_fiesta_preview()
		return
	if tutorial_step == TutorialStep.DAY2_RULES:
		_finish_sukli_rules_intro()
		return
	if tutorial_step == TutorialStep.DAY1_CLOSING:
		_clear_tutorial_spotlight()
		shift.frozen = false
		day_one_closing_tutorial_finished.emit()
		return
	if tutorial_step != TutorialStep.DAY1_HUD:
		return
	day_one_hud_tour_index += 1
	if day_one_hud_tour_index < 5:
		_show_day_one_hud_tour_step()
	else:
		_remember_tutorial("day1_hud")
		_clear_tutorial_spotlight()
		_show_opening_sign()

func _skip_day_one_tutorial() -> void:
	if tutorial_step == TutorialStep.DAY5_SUKI:
		_clear_tutorial_spotlight()
		shift.frozen = false
		return
	if fiesta_preview_step >= 0:
		_finish_fiesta_preview()
		return
	if tutorial_step == TutorialStep.DAY2_RULES:
		_finish_sukli_rules_intro()
		return
	if tutorial_step in [TutorialStep.DAY1_HUD, TutorialStep.DAY1_PRODUCT, TutorialStep.DAY1_CUSTOMER]:
		var skipped_hud := tutorial_step == TutorialStep.DAY1_HUD
		tutorial_delivery_seen = true
		_remember_tutorial("day1_drag")
		if skipped_hud:
			_remember_tutorial("day1_hud")
		_clear_tutorial_spotlight()
		if skipped_hud:
			_show_opening_sign()

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
			_show_day_one_product_step()
			return

func _show_day_one_product_step() -> void:
	var target_is_active := false
	for customer in shift.get_active_customers():
		if customer.instance_id == tutorial_customer_id:
			target_is_active = true
			break
	if not target_is_active:
		tutorial_delivery_seen = true
		_clear_tutorial_spotlight()
		return
	var product: Control = product_items_by_id.get(tutorial_product_id)
	if not is_instance_valid(product):
		_clear_tutorial_spotlight()
		return
	tutorial_step = TutorialStep.DAY1_PRODUCT
	var product_rect := _tutorial_product_rect(tutorial_product_id, product)
	tutorial_overlay.show_step("Tap and hold the highlighted product to pick it up.", product_rect, "PICK UP THE PRODUCT")
	tutorial_overlay.show_skip()

func _tutorial_product_rect(product_id: String, fallback: Control) -> Rect2:
	var config := StoreConfig.load_config("res://data/store_config.json")
	for store_id in config.get("products", {}):
		var entry: Dictionary = config.products[store_id]
		if str(entry.get("game_product_id", "")) == product_id:
			var display_rect := store_layer_renderer.get_product_display_rect(str(store_id))
			if display_rect.size != Vector2.ZERO:
				display_rect.position += product_layer.global_position - tutorial_overlay.global_position
				return display_rect
	return _tutorial_rect_for(fallback)

func _begin_day_two_shop_tutorial() -> void:
	if not is_instance_valid(utility_toggle):
		_show_pre_shift_briefing()
		return
	shop_button.hide()
	_refresh_shop_cta(false)
	utility_open = false
	_refresh_utility_drawer()
	_show_tutorial_spotlight(TutorialStep.DAY2_SHOP_MENU, "Tap the menu to find Inay's supplier list.", utility_toggle, "SUPPLIER LIST")

func _show_supplier_row_tutorial() -> void:
	await get_tree().process_frame
	if utility_open and tutorial_step == TutorialStep.DAY2_SHOP_MENU:
		_show_tutorial_spotlight(TutorialStep.DAY2_SHOP, "Order before you open the store. Buying is optional.", utility_shop, "SUPPLIER LIST")
		tutorial_overlay.z_index = 58
		var drawer_left := utility_drawer.global_position.x - tutorial_overlay.global_position.x
		var card := tutorial_overlay.coachmark
		card.position.x = maxf(30.0, drawer_left - card.size.x - 30.0)
		card.position.y = clampf(tutorial_overlay.spotlight_rect.position.y, 30.0, tutorial_overlay.size.y - card.size.y - 30.0)

func _show_utang_row_tutorial() -> void:
	await get_tree().process_frame
	if utility_open and tutorial_step == TutorialStep.DAY4_UTANG_MENU:
		_show_tutorial_spotlight(TutorialStep.DAY4_UTANG_ROW, "Tap UTANG LIST to check who owes money and see their balances.", utility_utang, "UTANG NOTEBOOK")
		_refresh_utility_drawer()
		tutorial_overlay.z_index = 58
		var drawer_left := utility_drawer.global_position.x - tutorial_overlay.global_position.x
		var card := tutorial_overlay.coachmark
		card.position.x = maxf(30.0, drawer_left - card.size.x - 30.0)
		card.position.y = clampf(tutorial_overlay.spotlight_rect.position.y, 30.0, tutorial_overlay.size.y - card.size.y - 30.0)

func _on_shelf_shop_closed() -> void:
	if resume_briefing_after_shop:
		resume_briefing_after_shop = false
		_show_pre_shift_briefing()
		return
	if showing_pre_shift_briefing:
		_show_pre_shift_briefing()
		return
	if tutorial_step != TutorialStep.DAY2_SHOP:
		return
	_remember_tutorial("day2_shop")
	tutorial_overlay.z_index = 52
	_clear_tutorial_spotlight()
	_refresh_shop_button()
	_show_pre_shift_briefing()

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
		story_events.fiesta_brownout_finished.connect(_on_fiesta_brownout_story_finished)
		story_events.remark_requested.connect(_show_customer_remark)
		story_events.popup_state_changed.connect(_set_shop_input_blocked)
		story_events.story_prop_requested.connect(_show_story_prop)
		story_events.customer_story_prompt_requested.connect(_show_customer_story_prompt)
		story_events.customer_story_arrival_finished.connect(_finish_customer_story_arrival)
		story_events.visitor_portrait_requested.connect(_show_story_visitor_portrait)
		story_events.visitor_portrait_hidden.connect(_hide_story_visitor_portrait)
		story_events.visitor_tutorial_completed.connect(_remember_story_event_tutorial)
		story_events.repayment_marker_tutorial_completed.connect(func():
			_remember_tutorial("utang_repayment_marker")
			shift.prioritize_repayment_tutorial = false)
		story_events.credit_decided.connect(_on_utang_tutorial_decision)
		story_events.repayment_completed.connect(_on_utang_tutorial_repayment)
		story_events.partial_repayment_completed.connect(_on_utang_tutorial_partial_repayment)
	story_events.bind(story, shift, bubble, PORTRAIT_ATLAS)
	if not shift.credit_recorded.is_connected(_on_utang_tutorial_recorded):
		shift.credit_recorded.connect(_on_utang_tutorial_recorded)
	move_child(bubble, get_child_count() - 1)

func _on_utang_tutorial_decision(approved: bool, customer_id: String) -> void:
	if campaign.day != 4 or bool(completed_tutorials.get("utang_first", false)): return
	if approved:
		utang_tutorial_customer = customer_id
		for customer in shift.active_customers:
			if customer.instance_id == customer_id: customer.tutorial_protected = true
		_show_tutorial_hint("Serve the items. The debt is recorded when the order is complete.", 12.0)
	else:
		_remember_tutorial("utang_first")
		_show_utang_tutorial_ledger.call_deferred("You declined. Lola Rosa’s existing debt is ₱320.")

func _on_utang_tutorial_recorded(customer_id: String) -> void:
	if customer_id != utang_tutorial_customer or bool(completed_tutorials.get("utang_first", false)): return
	utang_tutorial_customer = ""
	_remember_tutorial("utang_first")
	_show_utang_tutorial_ledger.call_deferred("The debt is recorded. You receive cash when the customer pays.")

func _on_utang_tutorial_repayment() -> void:
	if campaign.day != 5 or bool(completed_tutorials.get("utang_repayment", false)): return
	_remember_tutorial("utang_repayment")

func _on_utang_tutorial_partial_repayment() -> void:
	if campaign.day != 5 or bool(completed_tutorials.get("utang_repayment", false)): return
	_remember_tutorial("utang_repayment")

func _show_utang_tutorial_ledger(_message: String) -> void:
	if not shift_in_progress or not shift.is_running: return
	while story_events.is_active():
		await story_events.popup_state_changed
	if shift_in_progress and shift.is_running:
		_show_tutorial_hint("Puwedeng tingnan ang mga utang sa UTANG LIST.", 8.0)

func _show_story_visitor_portrait(visitor: String, button: Button) -> void:
	_hide_story_visitor_portrait()
	story_visitor_portrait = TextureRect.new()
	story_visitor_portrait.name = "StoryVisitorPortrait"
	story_visitor_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	story_visitor_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	story_visitor_portrait.texture = COUNTER_ART.customer_portrait(visitor, PORTRAIT_ATLAS)
	var visitor_x := STOREFRONT_LAYOUT.get_customer_x_positions(1)[0]
	var occupied := STOREFRONT_LAYOUT.get_customer_x_positions(shift.get_active_customers().size())
	if not occupied.is_empty():
		var best_distance := -1.0
		for candidate in [520.0, 740.0, 980.0, 1200.0]:
			var closest := INF
			for customer_x in occupied:
				closest = minf(closest, absf(candidate - customer_x))
			if closest > best_distance:
				best_distance = closest
				visitor_x = candidate
	story_visitor_portrait.position = Vector2(visitor_x + 18.0, STOREFRONT_LAYOUT.CUSTOMER_Y + 160.0)
	story_visitor_portrait.size = Vector2(144.0, 288.0)
	story_visitor_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	story_visitor_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	customer_layer.add_child(story_visitor_portrait)
	# The friends arrive together; the story marker stays on Jun-jun.
	if visitor == "jun_jun_tara" and campaign.day in [1, 3, 4]:
		for companion in [["mikay", -125.0], ["bogs", 125.0]]:
			var friend := TextureRect.new()
			friend.name = "Friend_" + str(companion[0])
			friend.texture = COUNTER_ART.customer_portrait(str(companion[0]), PORTRAIT_ATLAS)
			friend.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			friend.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			friend.position = Vector2(float(companion[1]), 0)
			friend.size = story_visitor_portrait.size
			friend.mouse_filter = Control.MOUSE_FILTER_IGNORE
			story_visitor_portrait.add_child(friend)
	var target := story_visitor_portrait.position
	var start_x := -270.0 if visitor_x < 960.0 else 1980.0
	story_visitor_portrait.position.x = start_x
	story_visitor_portrait.modulate.a = 0.0
	button.position = story_visitor_portrait.global_position
	button.modulate.a = 0.0
	story_visitor_entrance = create_tween().set_parallel(true)
	story_visitor_entrance.tween_property(story_visitor_portrait, "position:x", target.x, 0.58).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	story_visitor_entrance.tween_property(story_visitor_portrait, "modulate:a", 1.0, 0.20)
	story_visitor_entrance.tween_property(button, "position:x", target.x + customer_layer.global_position.x, 0.58).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	story_visitor_entrance.tween_property(button, "modulate:a", 1.0, 0.20)
	story_visitor_entrance.chain().tween_callback(func(): story_events.visitor_entrance_finished.emit())

func _hide_story_visitor_portrait() -> void:
	if story_visitor_entrance != null and story_visitor_entrance.is_valid():
		story_visitor_entrance.kill()
	story_visitor_entrance = null
	if is_instance_valid(story_visitor_portrait):
		story_visitor_portrait.queue_free()
		story_visitor_portrait = null

func _show_customer_story_prompt(instance_id: String) -> void:
	var actor: Control = customer_actors.get(instance_id)
	if not is_instance_valid(actor):
		return
	customer_story_actor = actor
	actor.order_bubble.visible = false
	actor.bubble_tail.visible = false
	customer_story_button = Button.new()
	customer_story_button.name = "CustomerStoryButton"
	customer_story_button.flat = true
	customer_story_button.size = actor.size
	customer_story_button.position = actor.global_position - global_position
	customer_story_button.modulate.a = actor.modulate.a
	customer_story_button.z_index = 90
	customer_story_button.tooltip_text = "Tap to begin the story event"
	add_child(customer_story_button)
	var mark: Control
	if story_events._mode == "credit_visitor":
		mark = preload("res://scripts/utang_event_marker.gd").new()
		mark.name = "UtangEventMarker"
		customer_story_button.tooltip_text = "Pindutin para kausapin ang gustong umutang"
		_show_tutorial_hint("A customer wants credit. Tap the notebook icon to talk to them.", 60.0)
	else:
		mark = STORY_EVENT_MARKER.create_marker()
	# The customer actor includes empty space above and beside the portrait.
	# Place the marker over the portrait itself, not over the actor's bounds.
	mark.position = Vector2(68.0, 80.0)
	customer_story_button.add_child(mark)
	if story_events._mode == "credit_visitor" and not bool(completed_tutorials.get("utang_event", false)):
		tutorial_hint.hide()
		tutorial_overlay.show_step("This customer wants credit. Tap them to talk and decide. Time and patience are paused.", _tutorial_rect_for(customer_story_button), "UTANG EVENT")
	customer_story_button.pressed.connect(func():
		if story_events._mode == "credit_visitor":
			tutorial_hint.hide()
			_remember_tutorial("utang_event")
			if tutorial_overlay.title.text == "UTANG EVENT": tutorial_overlay.clear_step()
		customer_story_button.queue_free()
		customer_story_button = null
		story_events.tap_customer_story(instance_id)
	)

func _finish_customer_story_arrival(instance_id: String) -> void:
	var actor: Control = customer_actors.get(instance_id)
	if is_instance_valid(actor):
		actor.order_bubble.visible = true
		actor.bubble_tail.visible = true
	customer_story_actor = null

func _set_shop_input_blocked(blocked: bool) -> void:
	if blocked:
		if not _blocked_input_nodes.is_empty():
			return
		get_viewport().gui_cancel_drag()
		for item in product_items_by_id.values():
			if is_instance_valid(item): item.call("cancel_drag")
		for layer in [customer_layer, product_layer, cash_tray, store_layer_renderer]:
			if layer != null:
				_block_input_in(layer, true)
		return
	if is_instance_valid(customer_story_button):
		customer_story_button.queue_free()
		customer_story_button = null
	if tutorial_overlay != null and tutorial_overlay.visible and tutorial_overlay.title.text in ["STORY EVENT", "UTANG EVENT"]:
		tutorial_overlay.clear_step()
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
	if tutorial_step == TutorialStep.DAY2_CUSTOMER:
		_show_day_two_customer_sukli_step.call_deferred()

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
	cash_tray.closed.connect(_on_sukli_tray_closed)
	cash_tray.denomination_selected.connect(_on_tutorial_denomination_selected)
	cash_tray.change_amount_changed.connect(_on_tutorial_change_amount_changed)

func _on_sukli_tray_closed() -> void:
	if tutorial_step == TutorialStep.DAY2_RULES:
		shift.frozen = sukli_rules_previous_frozen
		_clear_tutorial_spotlight()
	if not cash_tray.is_open() and tutorial_step in [TutorialStep.DAY2_MONEY, TutorialStep.DAY2_GIVE]:
		var customer_id := tutorial_customer_id
		_clear_tutorial_spotlight()
		_on_sukli_payment_started(customer_id)

func _on_sukli_payment_started(customer_id: String) -> void:
	if campaign.day != 2 or day_two_sukli_tutorial_complete or customer_id.is_empty():
		return
	# Keep the first customer targeted until the guided lesson is complete.
	if tutorial_step in [TutorialStep.DAY2_CUSTOMER, TutorialStep.DAY2_RULES, TutorialStep.DAY2_MONEY, TutorialStep.DAY2_GIVE]:
		return
	tutorial_customer_id = customer_id
	tutorial_step = TutorialStep.DAY2_CUSTOMER
	_show_day_two_customer_sukli_step.call_deferred()

func _show_day_two_customer_sukli_step() -> void:
	if tutorial_step != TutorialStep.DAY2_CUSTOMER:
		return
	if story_events != null and story_events.is_active():
		return
	var actor: Control = customer_actors.get(tutorial_customer_id)
	if not is_instance_valid(actor):
		_clear_tutorial_spotlight()
		return
	var customer: CustomerState = actor.get("customer")
	if customer == null or not customer.is_paying():
		_clear_tutorial_spotlight()
		return
	var target := _tutorial_rect_for(actor)
	var payment_bubble: Control = actor.get("order_bubble")
	if is_instance_valid(payment_bubble):
		target = target.merge(_tutorial_rect_for(payment_bubble))
	tutorial_overlay.show_step("Tap the customer asking for sukli to open the cash tray.", target, "SUKLI · CUSTOMER")

func _update_day_two_customer_sukli_target() -> void:
	var actor: Control = customer_actors.get(tutorial_customer_id)
	if not is_instance_valid(actor):
		return
	var target := _tutorial_rect_for(actor)
	var payment_bubble: Control = actor.get("order_bubble")
	if is_instance_valid(payment_bubble):
		target = target.merge(_tutorial_rect_for(payment_bubble))
	var rect := target.grow(18.0).intersection(Rect2(Vector2.ZERO, tutorial_overlay.size))
	if not tutorial_overlay.spotlight_rect.is_equal_approx(rect):
		tutorial_overlay.spotlight_rect = rect
		tutorial_overlay._position_coachmark()
		tutorial_overlay.queue_redraw()

func _on_payment_tapped(customer_id: String) -> void:
	if shift == null:
		return
	if not fiesta_selected_helper.is_empty():
		_apply_fiesta_helper(customer_id)
		return
	if tutorial_step == TutorialStep.DAY2_CUSTOMER and customer_id != tutorial_customer_id:
		return
	for customer in shift.get_active_customers():
		if customer.instance_id == customer_id and customer.is_paying():
			if tutorial_step == TutorialStep.DAY2_CUSTOMER:
				tutorial_overlay.clear_step()
			cash_tray.open_for(customer, SukliRules.sukli_guide_enabled_for_day(campaign.day))
			if campaign.day == 2 and not day_two_sukli_tutorial_complete:
				_begin_day_two_sukli_tutorial(customer)
			return

func _begin_day_two_sukli_tutorial(customer: CustomerState) -> void:
	if customer == null or customer.payment == null:
		return
	tutorial_customer_id = customer.instance_id
	tutorial_change_due = customer.payment.change_due()
	tutorial_payment_tender = customer.payment.tendered
	tutorial_payment_total = customer.payment.total
	tutorial_step = TutorialStep.DAY2_RULES
	tutorial_sukli_ready = false
	tutorial_sukli_generation += 1
	sukli_rules_previous_frozen = shift.frozen
	shift.frozen = true
	# Controls receive mouse input in scene-tree order, independently of z_index.
	move_child(tutorial_overlay, get_child_count() - 1)
	tutorial_overlay.show_sukli_examples(tutorial_payment_tender, tutorial_payment_total, _tutorial_rect_for(cash_tray))

func _finish_sukli_rules_intro() -> void:
	shift.frozen = sukli_rules_previous_frozen
	if not cash_tray.is_open():
		_clear_tutorial_spotlight()
		return
	tutorial_sukli_ready = true
	_refresh_day_two_sukli_spotlight(cash_tray.get_selected_total())

func _on_tutorial_denomination_selected(_value: int, total: int) -> void:
	_on_tutorial_change_amount_changed(total)

func _on_tutorial_change_amount_changed(total: int) -> void:
	if campaign.day != 2 or day_two_sukli_tutorial_complete or tutorial_change_due <= 0 or not tutorial_sukli_ready:
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
			_show_tutorial_spotlight(TutorialStep.DAY2_MONEY, "%s\nYou gave too much. Tap ULITIN and try again." % equation, clear_button, "SUKLI · TRY AGAIN")
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
			_remember_tutorial("day2_sukli")
			_clear_tutorial_spotlight()
		else:
			_refresh_day_two_sukli_spotlight(cash_tray.get_selected_total())
	if result == PaymentState.Result.EXACT and daily_goal != null:
		var was_goal_complete: bool = daily_goal.is_complete()
		daily_goal.record_exact_change()
		_refresh_daily_goal_hud()
		if not was_goal_complete and daily_goal.is_complete():
			_show_daily_goal_achievement()
	var at := Vector2(840.0, 200.0)
	if is_instance_valid(actor):
		at = actor.global_position - global_position + Vector2(actor.size.x * 0.5 - 90.0, 110.0)
	match result:
		PaymentState.Result.SHORT:
			_play_audio_cues(audio_cues_for_payment(result))
			cash_tray.show_short()
			if is_instance_valid(actor):
				actor.call("play_wrong_drop")
			_float_text(at, "KULANG! -4s PATIENCE", Color("ff8a7a"))
		PaymentState.Result.EXACT:
			_play_audio_cues(audio_cues_for_payment(result))
			cash_tray.close()
			_float_text(at, "TAMA!", Color("d9efaa"))
			if is_instance_valid(actor):
				actor.call("play_happy")
		PaymentState.Result.OVER:
			_play_audio_cues(audio_cues_for_payment(result))
			cash_tray.close()
			_float_text(at, "SOBRA! -₱%d KITA" % diff, Color("f6d95e"))
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

func _float_text(at: Vector2, text: String, color: Color, node_name: String = "GameplayFeedback") -> void:
	var label := _label(text, 42, color)
	label.name = node_name
	label.z_index = 45
	label.add_theme_color_override("font_outline_color", Color("2b1a10"))
	label.add_theme_constant_override("outline_size", 8)
	label.position = at
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position:y", at.y - 70.0, 1.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(1.0)
	tween.tween_callback(label.queue_free)

func _build_store_layer_renderer() -> void:
	store_layer_renderer = STORE_LAYER_RENDERER.new()
	store_layer_renderer.z_index = 0
	add_child(store_layer_renderer)
	# The renderer rescales its slots on resize; update the invisible pickup
	# controls afterwards without rebuilding them or interrupting active drags.
	store_layer_renderer.resized.connect(func(): _sync_product_pickup_rects.call_deferred())
	store_layer_renderer.configure(campaign.day, campaign.cash, campaign.purchased_store_groups)
	store_layer_renderer.purchase_requested.connect(_on_store_purchase_requested)
	store_layer_renderer.purchase_denied.connect(_on_store_purchase_denied)
	shelf_shop = ShelfShopModal.new()
	add_child(shelf_shop)
	shelf_shop.purchase_requested.connect(_on_shelf_shop_purchase_requested)
	shelf_shop.closed.connect(_on_shelf_shop_closed)

func _open_shelf_shop() -> void:
	if not _is_shop_available():
		if shift_in_progress and campaign != null and campaign.day > 1:
			_show_shop_unavailable_notice()
		return
	if shelf_shop == null:
		return
	shelf_shop.configure(StoreConfig.load_config("res://data/store_config.json"), campaign.purchased_store_groups, campaign.cash)
	move_child(shelf_shop, get_child_count() - 1)
	shelf_shop.open()
	if tutorial_step == TutorialStep.DAY2_SHOP and tutorial_overlay != null:
		tutorial_overlay.visible = false
		tutorial_overlay.z_index = 52
		shelf_shop.show_order_tutorial()

func _is_shop_available() -> bool:
	if campaign == null or campaign.day <= 1:
		return false
	return shop_available and not shift_in_progress and not supplier_story_blocked

func _refresh_shop_button() -> void:
	if shop_button != null:
		var available := _is_shop_available()
		shop_button.visible = campaign != null and campaign.day > 1 and not supplier_story_blocked and (available or shift_in_progress) and (not is_instance_valid(utility_drawer) or tutorial_step == TutorialStep.DAY2_SHOP)
		# Keep the button tappable so it can explain why the shop is locked.
		shop_button.disabled = false
		(shop_button.material as ShaderMaterial).set_shader_parameter("grayscale", not available)
		_refresh_shop_cta(available)
		# ShiftStoryEvents moves the full-screen dialogue bubble to the top of the
		# tree. Keep this tap target after it, otherwise the bubble consumes taps.
		if shop_button.visible:
			move_child(shop_button, get_child_count() - 1)

func _refresh_shop_cta(available: bool) -> void:
	if not is_instance_valid(shop_button):
		return
	var cta_visible := available and shop_button.visible
	if is_instance_valid(shop_order_cue):
		shop_order_cue.visible = cta_visible
	if is_instance_valid(shop_locked_cue):
		shop_locked_cue.visible = shop_button.visible and shift_in_progress and not available
	shop_button.tooltip_text = "Order supplies before opening" if cta_visible else "Supplier ordering is available before opening"
	if not is_instance_valid(shop_cta_glow):
		return
	shop_cta_glow.visible = cta_visible
	_refresh_shop_cta_layout()
	if cta_visible:
		if shop_cta_tween == null or not shop_cta_tween.is_valid():
			shop_cta_glow.modulate.a = 0.55
			shop_cta_tween = create_tween().set_loops()
			shop_cta_tween.tween_property(shop_cta_glow, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			shop_cta_tween.tween_property(shop_cta_glow, "modulate:a", 0.55, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	elif shop_cta_tween != null and shop_cta_tween.is_valid():
		shop_cta_tween.kill()
		shop_cta_tween = null

func _refresh_shop_cta_layout() -> void:
	if not is_instance_valid(shop_cta_glow) or not is_instance_valid(shop_button):
		return
	var scale := _hud_scale()
	shop_cta_glow.scale = Vector2.ONE * scale
	shop_cta_glow.position = shop_button.position - Vector2(9.0, 9.0) * scale

func _show_shop_unavailable_notice() -> void:
	var previous := get_node_or_null("ShopUnavailableNotice")
	if previous != null:
		previous.free()
	var notice := PanelContainer.new()
	notice.name = "ShopUnavailableNotice"
	notice.z_index = 56
	notice.z_as_relative = false
	notice.position = utility_toggle.position + Vector2(-480, 85) * _hud_scale()
	notice.custom_minimum_size = Vector2(465, 74)
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.add_theme_stylebox_override("panel", KwentaStyle.box(Color("f8e8c6"), Color("80532c"), 12, 10, 10, 4, 5))
	add_child(notice)
	var message := KwentaStyle.make_label("Available ulit ang supplier bago magbukas bukas.", 21, KwentaStyle.INK)
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.add_child(message)
	var animation := notice.create_tween()
	animation.tween_interval(2.5)
	animation.tween_property(notice, "modulate:a", 0.0, 0.3)
	animation.tween_callback(notice.queue_free)

func _on_shelf_shop_purchase_requested(group_id: String, price: int) -> void:
	var first_delivery := campaign.purchased_store_groups.is_empty() and not bool(completed_tutorials.get("supplier_first_delivery", false))
	if not campaign.purchase_store_group(group_id, price): return
	new_purchase_groups_today.append(group_id)
	_update_cash(campaign.cash)
	# Refresh both the authored storefront art and the transparent drag targets
	# from the same purchased-group state in this frame.
	store_layer_renderer.configure(campaign.day, campaign.cash, campaign.purchased_store_groups)
	_rebuild_product_shelf()
	var config := StoreConfig.load_config("res://data/store_config.json")
	shelf_shop.configure(config, campaign.purchased_store_groups, campaign.cash)
	var names: Array[String] = []
	for entry_value in config.get("products", {}).values():
		var entry: Dictionary = entry_value
		if str(entry.get("purchase_group", "")) == group_id:
			var product: ProductData = products_by_id.get(str(entry.get("game_product_id", "")))
			if product != null:
				names.append(product.display_name)
	if not shelf_shop.visible:
		return
	supplier_delivery_was_tutorial = tutorial_step == TutorialStep.DAY2_SHOP
	shelf_shop.hide_order_tutorial()
	shelf_shop.visible = false
	var delivery_beats: Array[Dictionary] = []
	if first_delivery:
		delivery_beats = [
			{"speaker": "Kuya Ben", "portrait": "supplier_ben", "text": "Tao po!"},
			{"speaker": "Tonyo", "portrait": "tonyo", "text": "Sino po sila?"},
			{"speaker": "Kuya Ben", "portrait": "supplier_ben", "text": "Hello, Tonyo! Ako si Ben. Heto na ang order mo: %s." % ", ".join(names)},
			{"speaker": "Tonyo", "portrait": "tonyo_flustered", "text": "Hala, magic nga?!"},
			{"speaker": "Kuya Ben", "portrait": "supplier_ben", "text": "Hahaha! Nasa malapit lang ako. Salamat sa order!"},
		]
	else:
		delivery_beats = [{"speaker": "Kuya Ben", "portrait": "supplier_ben", "text": "Delivered na, Tonyo! Heto ang order mo: %s. Salamat!" % ", ".join(names)}]
	_show_story_beats(delivery_beats, "DELIVERY", "supplier_delivery_done")

func _on_store_purchase_requested(group_id: String) -> void:
	var config := StoreConfig.load_config("res://data/store_config.json")
	for product_id in config.get("products", {}):
		var entry: Dictionary = config.products[product_id]
		if str(entry.get("purchase_group", product_id)) != group_id:
			continue
		if campaign.purchase_store_group(group_id, int(entry.get("price", 0))):
			new_purchase_groups_today.append(group_id)
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
	if daily_goal != null and daily_goal.type == DAILY_GOAL.Type.BARANGAY_TRUST:
		_refresh_daily_goal_hud()

func _build_game_over_screen() -> void:
	game_over_screen = GAME_OVER_SCREEN.new()
	game_over_screen.z_index = 60      # above the HUD, summary panel and dialogue bubble
	game_over_screen.position = _ui_offset()
	game_over_screen.retry_pressed.connect(_retry_current_day)
	add_child(game_over_screen)

func _on_game_over() -> void:
	_hide_store_sign()
	if game_over_screen.visible:
		return      # already showing (two customers can trigger it in the same frame)
	if audio != null:
		audio.play_persistent_cue("game_over")
	_clear_all_angry_customers()
	shift_in_progress = false
	_refresh_shop_button()
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

func _on_customer_became_impatient(customer_instance_id: String) -> void:
	angry_customer_ids[customer_instance_id] = true
	if audio != null:
		audio.start_alert()

func _on_customer_calmed_down(customer_instance_id: String) -> void:
	_clear_angry_customer(customer_instance_id)

func _clear_angry_customer(customer_instance_id: String) -> void:
	angry_customer_ids.erase(customer_instance_id)
	if angry_customer_ids.is_empty() and audio != null:
		audio.stop_alert()

func _clear_all_angry_customers() -> void:
	angry_customer_ids.clear()
	if audio != null:
		audio.stop_alert()

func _retry_current_day() -> void:
	game_over_screen.dismiss()
	
	for actor in customer_actors.values():
		if is_instance_valid(actor): actor.queue_free()
	customer_actors.clear()
	cash_tray.close()
	
	campaign.debts = shift_start_credit.get("debts", []).duplicate(true)
	campaign.paid_purchases = shift_start_credit.get("paid", {}).duplicate(true)
	campaign.completed_customers = shift_start_credit.get("completed_customers", {}).duplicate(true)
	campaign.purchase_counts = shift_start_credit.get("purchase_counts", {}).duplicate(true)
	story.choices = shift_start_choices.duplicate(true)
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

func _build_fiesta_controls() -> void:
	# The solo route keeps its running bonus; helpers use their portraits instead.
	fiesta_button = Button.new()
	fiesta_button.name = "FiestaAbilityButton"
	fiesta_button.z_index = 56
	fiesta_button.custom_minimum_size = Vector2(430, 76)
	KwentaStyle.style_button(fiesta_button, KwentaStyle.GOLD, 26)
	fiesta_button.add_theme_color_override("font_disabled_color", KwentaStyle.INK)
	fiesta_button.hide()
	add_child(fiesta_button)
	fiesta_friends = Control.new()
	fiesta_friends.name = "FiestaFriends"
	fiesta_friends.z_index = 56
	fiesta_friends.size = Vector2(210, 465)
	fiesta_friends.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fiesta_friends.hide()
	add_child(fiesta_friends)
	var helper_index := 0
	for role in [["mikay", "mikay", "Mikay", "Sukli"], ["jun_jun", "jun_jun", "Jun-jun", "Paninda"], ["bogs", "bogs", "Bogs", "Rescue"]]:
		var icon = FIESTA_HELPER_ICON.new()
		icon.name = "Helper_%s" % str(role[0])
		icon.position = Vector2(0, helper_index * 155)
		icon.size = Vector2(210, 155)
		helper_index += 1
		icon.setup(str(role[1]), str(role[2]), str(role[3]), PORTRAIT_ATLAS)
		fiesta_friends.add_child(icon)
		fiesta_icons[str(role[0])] = icon
	for helper in ["mikay", "jun_jun", "bogs"]:
		fiesta_icons[helper].pressed.connect(_select_fiesta_helper.bind(helper))
	fiesta_target_prompt = Label.new()
	fiesta_target_prompt.name = "FiestaTargetPrompt"
	fiesta_target_prompt.z_index = 56
	fiesta_target_prompt.position = Vector2(610, 1020) + _ui_offset()
	fiesta_target_prompt.size = Vector2(1050, 42)
	fiesta_target_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fiesta_target_prompt.add_theme_font_size_override("font_size", 26)
	fiesta_target_prompt.add_theme_color_override("font_color", Color("fff2ce"))
	fiesta_target_prompt.add_theme_color_override("font_outline_color", Color("291808"))
	fiesta_target_prompt.add_theme_constant_override("outline_size", 6)
	fiesta_target_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fiesta_target_prompt.hide()
	add_child(fiesta_target_prompt)

func _show_fiesta_preview() -> void:
	var helpers := ["mikay", "jun_jun", "bogs"]
	var titles := ["MIKAY · SUKLI", "JUN-JUN · ORDER", "BOGS · FIESTA RESCUE"]
	var messages := [
		"Mikay gives exact change. Tap her, then a customer waiting for change. She rests for 20 seconds.",
		"Jun-jun serves one customer’s remaining order. Tap him, then a customer. He rests for 60 seconds.",
		"Tap Bogs to complete all current orders. Change is separate. He rests for 120 seconds."
	]
	tutorial_overlay.show_fiesta_example(helpers[fiesta_preview_step], messages[fiesta_preview_step], titles[fiesta_preview_step], fiesta_preview_step == 2)

func _finish_fiesta_preview() -> void:
	fiesta_preview_step = -1
	tutorial_overlay.clear_step()
	_remember_tutorial("fiesta_skill_visuals")

func _select_fiesta_helper(helper: String) -> void:
	if fiesta_preview_step >= 0:
		return
	if helper == "bogs":
		fiesta_selected_helper = ""
		if cash_tray.is_open(): cash_tray.close()
		if shift.use_helper_rescue():
			_play_audio_cues(["correct"])
		else:
			shift.feedback_changed.emit("Wala pang order na puwedeng tulungan ni Bogs.")
		_refresh_fiesta_controls()
		return
	if fiesta_selected_helper == helper:
		fiesta_selected_helper = ""
	else:
		if cash_tray.is_open(): cash_tray.close()
		fiesta_selected_helper = helper
	_refresh_fiesta_controls()

func _apply_fiesta_helper(customer_id: String) -> void:
	var helper := fiesta_selected_helper
	var success := false
	match helper:
		"mikay": success = shift.use_helper_change(customer_id)
		"jun_jun": success = shift.use_helper_item(customer_id)
	if success:
		fiesta_selected_helper = ""
		if helper == "mikay": _play_audio_cues(["sale"])
		elif helper == "jun_jun": _play_audio_cues(["correct"])
	else:
		shift.feedback_changed.emit("Pumili ng customer na %s." % ("naghihintay ng sukli" if helper == "mikay" else "puwedeng tulungan"))
	_refresh_fiesta_controls()

func _refresh_fiesta_controls() -> void:
	if not is_instance_valid(fiesta_button): return
	var active := campaign != null and campaign.day == 6 and shift != null and shift.is_running and not shift.frozen and not opening_sign_active
	fiesta_button.visible = active and shift.fiesta_route == "alone"
	fiesta_friends.visible = active and shift.fiesta_route == "ask"
	fiesta_friends.position = Vector2(maxf(0.0, size.x - fiesta_friends.size.x), maxf(0.0, size.y - fiesta_friends.size.y - 5.0))
	if fiesta_friends.visible and fiesta_preview_step < 0 and not bool(completed_tutorials.get("fiesta_skill_visuals", false)) and tutorial_step == TutorialStep.NONE and not tutorial_overlay.visible:
		fiesta_preview_step = 0
		_show_fiesta_preview()
	fiesta_button.position = Vector2(35, 930) + _ui_offset()
	fiesta_target_prompt.position = Vector2(610, 1020) + _ui_offset()
	if not active or shift.fiesta_route != "ask": fiesta_selected_helper = ""
	fiesta_target_prompt.visible = active and not fiesta_selected_helper.is_empty()
	if fiesta_target_prompt.visible:
		# Keep helper targeting instructions unobstructed by transient hints.
		if is_instance_valid(tutorial_hint) and tutorial_hint.visible:
			tutorial_hint.hide()
		var helper_name: String = {"mikay": "Mikay", "jun_jun": "Jun-jun", "bogs": "Bogs"}.get(fiesta_selected_helper, "")
		var instruction: String = {"mikay": "naghihintay ng sukli", "jun_jun": "may kulang na order", "bogs": "naghihintay"}.get(fiesta_selected_helper, "")
		fiesta_target_prompt.text = "%s: Pindutin ang customer na %s · ulitin para kanselahin" % [helper_name, instruction]
	if not active: return
	if shift.fiesta_route == "alone":
		fiesta_button.disabled = true
		fiesta_button.text = "Dagdag ni Inay: ₱%d (20%%)" % roundi(shift.paid_goods_sales * 0.2)
		fiesta_button.tooltip_text = "Sa pagsasara: 20% ng bayad na paninda. Hindi kasama ang tips at singil sa utang."
		return
	var mikay = fiesta_icons["mikay"]
	mikay.set_cooldown(shift.helper_cooldown)
	mikay.disabled = shift.helper_cooldown > 0.0
	mikay.set_selected(fiesta_selected_helper == "mikay")
	mikay.tooltip_text = "Mikay · Nagbibigay ng tamang sukli. Pahinga: 20 segundo."
	var junjun = fiesta_icons["jun_jun"]
	junjun.set_cooldown(shift.helper_item_cooldown)
	junjun.disabled = shift.helper_item_cooldown > 0.0
	junjun.set_selected(fiesta_selected_helper == "jun_jun")
	junjun.tooltip_text = "Jun-jun · Kinukumpleto ang natitirang order. Pahinga: 60 segundo."
	var bogs = fiesta_icons["bogs"]
	bogs.set_cooldown(shift.helper_patience_cooldown)
	bogs.disabled = shift.helper_patience_cooldown > 0.0
	bogs.set_selected(fiesta_selected_helper == "bogs")
	bogs.tooltip_text = "Bogs · Kinukumpleto ang lahat ng kasalukuyang order. Pahinga: 120 segundo."
