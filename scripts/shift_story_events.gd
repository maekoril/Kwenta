class_name ShiftStoryEvents
extends Node

signal fiesta_brownout_finished
signal story_visitor_tapped

# Plays the story moments that happen DURING a shift, driven by the story JSON:
#
#   "shift_events": scripted customers ("customer") and kalaro interruptions ("interruption"),
#                   each with an "at_minute" (0-600, the in-game clock for the shift).
#   "haggle":       customers who ask for a discount when their order is done (once per shift).
#   "hover":        a customer who watches the change (shorter payment patience + a remark).
#   "mixups":       a helper hands over the wrong item; the player decides whether to catch it.
#
# Every entry can be gated with when_choice / when_value(s) like any other story beat.
# While a popup is open the shift clock and customer patience are frozen (shift.frozen).
# Node setup lives in main.gd (_build_story_events); the shift-side hooks live in shift_manager.gd.

signal remark_requested(customer_instance_id: String, text: String)
signal popup_state_changed(active: bool)   # true while a popup is up: main.gd makes the shop inert
signal story_prop_requested(prop_name: String)
signal customer_story_prompt_requested(customer_instance_id: String)
signal customer_story_arrival_finished(customer_instance_id: String)
signal visitor_portrait_requested(visitor: String, button: Button)
signal visitor_portrait_hidden
signal visitor_entrance_finished
signal visitor_tutorial_completed

const COUNTER_ART = preload("res://scripts/counter_art.gd")
const STORY_TUTORIAL_OVERLAY = preload("res://scripts/interactive_tutorial_overlay.gd")
const STORY_EVENT_MARKER = preload("res://scripts/story_event_marker.gd")
const MAX_EVENT_MINUTE := 570   # nothing new starts in the last half hour of the shift

const DEFAULT_GO_BEATS: Array = [
	{"speaker": "Narrator", "portrait": "", "text": "Tumakbo si Tonyo palabas saglit, saka bumalik sa tindahan."},
]

var story: StoryProgression
var shift: ShiftManager
var bubble: DialogueBubble
var portrait_atlas: Texture2D

var _credit_layer: CanvasLayer
var credit_panel: Control

var _day: int = 0
var _in_shift: bool = false
var _suppressed: bool = false
var _active: bool = false
var _mode: String = ""                          # "", "choice" (answers showing) or "beats" (reaction lines)
var _current: Dictionary = {}
var _queue: Array[Dictionary] = []              # popups waiting for their turn
var _beats: Array[Dictionary] = []              # reaction lines waiting to be shown
var _timed: Array[Dictionary] = []              # events waiting for their minute
var _waiting_scene: Dictionary = {}
var _haggle_entries: Dictionary = {}            # customer_id -> merged haggle entry
var _payment_beats_seen: Dictionary = {}
var _hover_text: Dictionary = {}                # customer_id -> remark shown when they start paying
var _mixup_entry: Dictionary = {}
var _visitor_layer: CanvasLayer
var _visitor_tutorial_seen := false
var _scene_choice_done := false
var _paolo_note_visible := false
var _utang_ledger_visible := false
var _scene_illustration_visible := false
var _scene_options: Array[Dictionary] = []


func bind(story_ref: StoryProgression, shift_ref: ShiftManager, bubble_ref: DialogueBubble, atlas: Texture2D) -> void:
	_disconnect_shift()
	story = story_ref
	shift = shift_ref
	portrait_atlas = atlas
	if bubble != bubble_ref:
		bubble = bubble_ref
		bubble.advanced.connect(_on_bubble_advanced)
		bubble.choice_made.connect(_on_bubble_choice)
	shift.credit_requested.connect(_on_credit_requested)
	shift.repayment_requested.connect(_on_repayment_requested)
	shift.game_minutes_changed.connect(_on_game_minutes)
	shift.haggle_requested.connect(_on_haggle_requested)
	shift.mixup_requested.connect(_on_mixup_requested)
	shift.payment_started.connect(_on_payment_started)
	shift.story_customer_arrived.connect(_on_story_customer_arrived)
	shift.story_customer_sale_completed.connect(_on_story_customer_sale_completed)
	shift.customers_changed.connect(_on_customers_changed)


func _disconnect_shift() -> void:
	if shift == null or not is_instance_valid(shift):
		return
	if shift.credit_requested.is_connected(_on_credit_requested):
		shift.credit_requested.disconnect(_on_credit_requested)
	if shift.repayment_requested.is_connected(_on_repayment_requested):
		shift.repayment_requested.disconnect(_on_repayment_requested)
	if shift.game_minutes_changed.is_connected(_on_game_minutes):
		shift.game_minutes_changed.disconnect(_on_game_minutes)
	if shift.haggle_requested.is_connected(_on_haggle_requested):
		shift.haggle_requested.disconnect(_on_haggle_requested)
	if shift.mixup_requested.is_connected(_on_mixup_requested):
		shift.mixup_requested.disconnect(_on_mixup_requested)
	if shift.payment_started.is_connected(_on_payment_started):
		shift.payment_started.disconnect(_on_payment_started)
	if shift.story_customer_arrived.is_connected(_on_story_customer_arrived):
		shift.story_customer_arrived.disconnect(_on_story_customer_arrived)
	if shift.story_customer_sale_completed.is_connected(_on_story_customer_sale_completed):
		shift.story_customer_sale_completed.disconnect(_on_story_customer_sale_completed)
	if shift.customers_changed.is_connected(_on_customers_changed):
		shift.customers_changed.disconnect(_on_customers_changed)


# True while a story popup is on screen. main.gd ignores bubble taps while this is true.
func is_active() -> bool:
	return _active


# Call right before shift.start_shift().
func begin_shift(day: int) -> void:
	_hide_credit_panel()
	_day = day
	_in_shift = true
	_suppressed = false
	_active = false
	_mode = ""
	_queue.clear()
	_beats.clear()
	_timed.clear()
	_waiting_scene.clear()
	_haggle_entries.clear()
	_payment_beats_seen.clear()
	_hover_text.clear()
	_mixup_entry = {}
	shift.reset_story_state()
	shift.reserved_story_ids.clear()
	for entry in story.get_day_haggles(day):
		var customer_id := str(entry.get("customer", ""))
		if customer_id.is_empty():
			continue
		var merged: Dictionary = _haggle_entries.get(customer_id, {})
		for key in entry:
			merged[key] = entry[key]
		_haggle_entries[customer_id] = merged
		shift.haggle_asks[customer_id] = int(merged.get("ask", 0))
	for entry in story.get_day_hovers(day):
		var customer_id := str(entry.get("customer", ""))
		if customer_id.is_empty():
			continue
		shift.hover_notes[customer_id] = float(entry.get("payment_patience_mult", 1.0))
		_hover_text[customer_id] = str(entry.get("text", ""))
	var mixups := story.get_day_mixups(day)
	if not mixups.is_empty():
		_mixup_entry = mixups.back()
		shift.mixup_remaining = int(_mixup_entry.get("count", 0))
		shift.mixup_every = int(_mixup_entry.get("every", 3))
	for event in story.get_day_shift_events(day):
		var reserved := str(event.get("reserve_customer", event.get("visitor", "")))
		if not reserved.is_empty() and not shift.reserved_story_ids.has(reserved):
			shift.reserved_story_ids.append(reserved)
		if str(event.get("type", "")) == "customer" and int(event.get("at_minute", 0)) <= 0:
			_run_customer_event(event)   # waiting at the door when the shift starts
		else:
			_timed.append(event)
	_timed.sort_custom(func(a, b): return int(a.get("at_minute", 0)) < int(b.get("at_minute", 0)))
	if OS.is_debug_build():
		print("[story] Day %d shift: %d timed events, haggles for %s, %d mix-ups, %d scripted customers at the door" % [day, _timed.size(), str(_haggle_entries.keys()), shift.mixup_remaining, shift.story_queue.size()])


# Call when the shift ends.
func end_shift() -> void:
	_hide_credit_panel()
	_hide_story_visitor()
	_hide_scene_illustration()
	_waiting_scene.clear()
	shift.story_waiting_for_clear = false
	shift.reserved_story_ids.clear()
	_in_shift = false
	_queue.clear()
	_beats.clear()
	_timed.clear()
	_mode = ""


# Debug "skip day": drop everything so a popup can't stall the fast-forward.
func suppress() -> void:
	_hide_credit_panel()
	if str(_current.get("kind", "")) == "post_sale" and shift != null:
		shift.finish_story_customer(str(_current.get("id", "")))
	_hide_story_visitor()
	_hide_scene_illustration()
	_waiting_scene.clear()
	shift.story_waiting_for_clear = false
	shift.reserved_story_ids.clear()
	if OS.is_debug_build():
		print("[story] SKIP DAY pressed: this shift's story events are cancelled")
	_suppressed = true
	_queue.clear()
	_beats.clear()
	_timed.clear()
	_mode = ""
	if _active:
		_active = false
		if bubble != null:
			bubble.close()
		popup_state_changed.emit(false)
	if shift != null:
		shift.frozen = false


# ------------------------------------------------------------ timed events

func _on_game_minutes(minute: int) -> void:
	if not _in_shift or _suppressed:
		return
	while not _timed.is_empty():
		var event: Dictionary = _timed[0]
		# These events are scheduled when their preceding choice finishes.
		if bool(event.get("follow_after_choice", false)):
			return
		if int(event.get("at_minute", 0)) > minute:
			return
		var kind := str(event.get("type", ""))
		# Some encounters depend on a decision made during this same shift.
		# Evaluate them now, rather than when the day first starts.
		var required_choice := str(event.get("requires_choice", ""))
		if not required_choice.is_empty() and story.get_choice(required_choice) != str(event.get("requires_value", "")):
			_timed.pop_front()
			continue
		if shift.is_closing and not (kind in ["scene", "customer"] and bool(event.get("wait_for_clear", false))):
			_timed.pop_front()
			continue
		if kind in ["scene", "customer"] and bool(event.get("wait_for_clear", false)):
			if not _waiting_scene.is_empty():
				return
			_timed.pop_front()
			_waiting_scene = event
			shift.story_waiting_for_clear = true
			_try_start_waiting_scene.call_deferred()
			return
		if kind == "interruption":
			if minute > MAX_EVENT_MINUTE:
				_timed.pop_front()      # too late in the shift: skip it
				continue
			if _active:
				return                  # busy: try again on a later tick
			_timed.pop_front()
			_queue_popup({"kind": "interruption", "event": event})
			return                      # one popup at a time
		_timed.pop_front()
		if kind == "customer":
			_run_customer_event(event)
		elif kind == "narrative" and (minute <= MAX_EVENT_MINUTE or str(event.get("visitor", "")) == "fiesta_brownout"):
			_queue_popup({"kind": "narrative", "event": event})
			return
		elif kind == "scene" and minute <= MAX_EVENT_MINUTE:
			_queue_popup({"kind": "scene", "event": event})

func _on_customers_changed() -> void:
	if not _waiting_scene.is_empty():
		_try_start_waiting_scene.call_deferred()

func _try_start_waiting_scene() -> void:
	if _waiting_scene.is_empty() or not _in_shift or _suppressed or _active or not shift.is_running:
		return
	if not shift.get_active_customers().is_empty():
		return
	var event := _waiting_scene
	_waiting_scene = {}
	# Older saves may already have added Berting's money to the register.
	# Check affordability at the encounter, after any pre-shift purchases.
	if str(event.get("visitor", "")) == "mang_berting" and not story.get_choice("day2_cash_legacy").is_empty():
		story.choices["day2_cash_legacy"] = "available" if shift.campaign_state.cash >= 50 else "spent"
	shift.story_waiting_for_clear = false
	if str(event.get("type", "")) == "customer":
		var queued_before := shift.story_queue.size()
		_run_customer_event(event)
		if shift.story_queue.size() > queued_before:
			# The waiting visitor must enter first, even if other story customers are queued.
			var waiting_customer: Dictionary = shift.story_queue.pop_back()
			shift.story_queue.push_front(waiting_customer)
			shift._spawn_customer()
	else:
		_queue_popup({"kind": "scene", "event": event})


func _run_customer_event(event: Dictionary) -> void:
	var order: Dictionary = event.get("order", {})
	var arrival_beats := story.filter_story_beats(event.get("arrival_beats", []))
	if bool(event.get("skip_haggle", false)):
		shift.haggled_ids[str(event.get("customer", ""))] = true
	shift.queue_story_customer(str(event.get("customer", "")), order, bool(event.get("exact_pay", false)), arrival_beats, int(event.get("tendered", 0)), bool(event.get("story_visitor", false)), event.get("after_sale", {}), event.get("before_sale", {}))

func _on_story_customer_sale_completed(instance_id: String, event: Dictionary) -> void:
	if _in_shift and not _suppressed:
		_queue_popup({"kind": "post_sale", "id": instance_id, "event": event})
	else:
		shift.finish_story_customer.call_deferred(instance_id)


# ------------------------------------------------------------ shift signals

func _on_story_customer_arrived(customer_instance_id: String, beats: Array) -> void:
	if _in_shift and not _suppressed:
		var customer := _find_story_customer(customer_instance_id)
		var kind := "customer_visitor" if customer != null and customer.story_arrival_pending else "arrival"
		_queue_popup({"kind": kind, "id": customer_instance_id, "beats": beats, "event": customer.story_before_sale if customer != null else {}})

func _find_story_customer(instance_id: String) -> CustomerState:
	for customer in shift.get_active_customers():
		if customer.instance_id == instance_id:
			return customer
	return null

func tap_customer_story(instance_id: String) -> void:
	if _mode != "customer_visitor" or str(_current.get("id", "")) != instance_id:
		return
	_mark_visitor_tutorial_seen()
	_play_beats(_current.get("beats", []))

func _on_haggle_requested(customer_instance_id: String, ask: int) -> void:
	if not _in_shift or _suppressed:
		shift.resolve_haggle(customer_instance_id, false)
		return
	_queue_popup({"kind": "haggle", "id": customer_instance_id, "ask": ask})


func _on_mixup_requested(customer_instance_id: String, product_id: String) -> void:
	if not _in_shift or _suppressed:
		shift.resolve_mixup(customer_instance_id, product_id, false)
		return
	_queue_popup({"kind": "mixup", "id": customer_instance_id, "product": product_id})


func _on_payment_started(customer_instance_id: String) -> void:
	for customer in shift.get_active_customers():
		if customer.instance_id != customer_instance_id:
			continue
		var entry: Dictionary = _haggle_entries.get(customer.customer_id, {})
		var payment_beats: Array = entry.get("payment_beats", [])
		if _in_shift and not _suppressed and not payment_beats.is_empty() and not _payment_beats_seen.has(customer.customer_id):
			_payment_beats_seen[customer.customer_id] = true
			_queue_popup({"kind": "arrival", "beats": story.filter_story_beats(payment_beats)})
		if _hover_text.has(customer.customer_id):
			var text := str(_hover_text[customer.customer_id])
			if not text.is_empty():
				remark_requested.emit(customer_instance_id, text)
		return


# ------------------------------------------------------------ popups

func _queue_popup(popup: Dictionary) -> void:
	if OS.is_debug_build():
		print("[story] popup: %s" % str(popup.get("kind", "")))
	_queue.append(popup)
	if _active:
		return
	_active = true
	shift.frozen = true
	popup_state_changed.emit(true)
	_start_next()


func _start_next() -> void:
	_hide_credit_panel()
	if _queue.is_empty():
		_finish()
		return
	_current = _queue.pop_front()
	_scene_choice_done = false
	match str(_current.get("kind", "")):
		"credit":
			_show_credit()
		"repayment":
			_mode = "choice"
			var debt: Dictionary = _current.debt
			bubble.ask(str(debt.customer).capitalize(), "Heto ang bayad kong ₱%d. Salamat sa pautang kahapon!" % int(debt.balance), ["Tanggapin ang bayad"], _portrait(str(debt.customer)), str(debt.customer))
		"arrival":
			_play_beats(_current.get("beats", []))
		"customer_visitor":
			_mode = "customer_visitor"
			customer_story_prompt_requested.emit(str(_current.get("id", "")))
		"post_sale":
			_play_beats(story.filter_story_beats(_current.get("event", {}).get("beats", [])))
		"narrative":
			_play_beats(story.filter_story_beats(_current.get("event", {}).get("beats", [])))
		"scene":
			_present_story_visitor()
		"haggle":
			_show_haggle()
		"mixup":
			_show_mixup()
		"interruption":
			_present_story_visitor()
		_:
			_start_next()

func _present_story_visitor() -> void:
	_mode = "visitor"
	var event: Dictionary = _current.get("event", {})
	var visitor := str(event.get("visitor", event.get("portrait", "jun_jun_tara")))
	_show_story_visitor(visitor)

func present_outro_visitor(visitor: String) -> void:
	_mode = "outro_visitor"
	_show_story_visitor(visitor)

func _show_story_visitor(visitor: String) -> void:
	_visitor_layer = CanvasLayer.new()
	_visitor_layer.name = "StoryVisitorLayer"
	_visitor_layer.layer = 45
	add_child(_visitor_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visitor_layer.add_child(root)
	var button := Button.new()
	button.name = "StoryVisitorButton"
	# Match a customer's position in the service window, above the counter.
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.offset_left = 758
	button.offset_top = 200
	button.offset_right = 902
	button.offset_bottom = 488
	button.flat = true
	button.disabled = true
	button.tooltip_text = "Tap to begin the story event"
	root.add_child(button)
	visitor_portrait_requested.emit(visitor, button)
	var mark := STORY_EVENT_MARKER.create_marker()
	mark.position = Vector2(50, -80)
	button.add_child(mark)
	button.pressed.connect(_on_story_visitor_tapped)
	await visitor_entrance_finished
	if not is_instance_valid(button) or _mode not in ["visitor", "outro_visitor"]:
		return
	button.disabled = false
	if not _visitor_tutorial_seen:
		var overlay := STORY_TUTORIAL_OVERLAY.new()
		overlay.name = "StoryVisitorTutorial"
		root.add_child(overlay)
		overlay.show_step("Tap the visitor with ! to start a story event. Time and customer patience are paused.", button.get_global_rect().merge(mark.get_global_rect()), "STORY EVENT")

func _on_story_visitor_tapped() -> void:
	if _mode != "visitor" and _mode != "outro_visitor":
		return
	_mark_visitor_tutorial_seen()
	if _mode == "outro_visitor":
		_mode = ""
		_hide_story_visitor()
		story_visitor_tapped.emit()
		return
	var event: Dictionary = _current.get("event", {})
	if not bool(event.get("reserve_until_shift_end", false)):
		shift.reserved_story_ids.erase(str(event.get("reserve_customer", event.get("visitor", ""))))
	_hide_story_visitor()
	if str(_current.get("kind", "")) == "interruption":
		_show_interruption()
	else:
		var flag := str(event.get("seen_flag", ""))
		if not flag.is_empty():
			story.choices[flag] = "seen"
		for key in event.get("set_choices", {}):
			story.choices[str(key)] = str(event["set_choices"][key])
		_play_beats(story.filter_story_beats(event.get("beats", [])))

func _mark_visitor_tutorial_seen() -> void:
	if not _visitor_tutorial_seen:
		_visitor_tutorial_seen = true
		visitor_tutorial_completed.emit()

func _hide_story_visitor() -> void:
	visitor_portrait_hidden.emit()
	if is_instance_valid(_visitor_layer):
		_visitor_layer.queue_free()
		_visitor_layer = null
	_hide_paolo_note()

func _hide_paolo_note() -> void:
	if _paolo_note_visible:
		_paolo_note_visible = false
		story_prop_requested.emit("hide_paolo_debt_note")

func _hide_scene_illustration() -> void:
	if _utang_ledger_visible:
		_utang_ledger_visible = false
		story_prop_requested.emit("hide_utang_ledger")
	if _scene_illustration_visible:
		_scene_illustration_visible = false
		story_prop_requested.emit("hide_scene_illustration")


func _finish() -> void:
	_mode = ""
	_hide_scene_illustration()
	bubble.close()
	# Cleared one frame later so main.gd's own bubble handlers (which run for the same
	# signal) still see the popup as active and ignore it.
	call_deferred("_release")


func _release() -> void:
	if not is_inside_tree():
		return
	if not _queue.is_empty():
		_start_next()
		return
	# Give the last tap a moment to finish so it can't also land on the shop underneath.
	await get_tree().create_timer(0.2).timeout
	if not _active:
		return                # suppress() already ended the session
	if not _queue.is_empty():
		_start_next()
		return
	_active = false
	if shift != null:
		shift.frozen = false
	popup_state_changed.emit(false)
	if shift != null and shift.is_closing:
		_on_game_minutes(shift.shift_close_minutes)
		if shift.get_active_customers().is_empty() and not shift.story_waiting_for_clear:
			shift.finish_shift()
	_try_start_waiting_scene.call_deferred()


func _on_bubble_choice(index: int) -> void:
	if not _active or _mode != "choice":
		return
	_mode = ""
	match str(_current.get("kind", "")):
		"repayment":
			var debt: Dictionary = _current.debt
			shift.debt_payments_received += shift.campaign_state.repay_debt(str(debt.id), int(debt.balance))
			shift.cash_changed.emit(shift.campaign_state.cash)
			_start_next()
		"scene", "post_sale", "customer_visitor":
			_resolve_scene_choice(index)
		"haggle":
			_resolve_haggle(index == 0)
		"mixup":
			_resolve_mixup(index == 0)
		"interruption":
			_resolve_interruption(index)


func _on_bubble_advanced() -> void:
	if _active and _mode == "beats":
		_next_beat()


func _play_beats(raw_beats: Variant) -> void:
	_beats.clear()
	if raw_beats is Array:
		for beat in raw_beats:
			if beat is Dictionary:
				_beats.append(beat)
	_next_beat()


func _next_beat() -> void:
	_hide_paolo_note()
	if _utang_ledger_visible:
		_utang_ledger_visible = false
		story_prop_requested.emit("hide_utang_ledger")
	if _beats.is_empty():
		if str(_current.get("kind", "")) in ["scene", "post_sale", "customer_visitor"] and not _scene_choice_done:
			var event: Dictionary = _current.get("event", {})
			var choice: Dictionary = event.get("choice", {})
			if not choice.is_empty():
				if bool(event.get("automatic_choice", false)):
					_scene_options = story.filter_story_beats(choice.get("options", []))
					if _scene_options.size() == 1:
						_resolve_scene_choice(0)
						return
				_show_scene_choice(choice)
				return
		if str(_current.get("kind", "")) == "scene" and _scene_choice_done:
			var finished_choice := str(_current.get("event", {}).get("choice", {}).get("id", ""))
			for followup in _timed.duplicate():
				if not bool(followup.get("follow_after_choice", false)) or str(followup.get("requires_choice", "")) != finished_choice:
					continue
				_timed.erase(followup)
				if story.get_choice(finished_choice) == str(followup.get("requires_value", "")):
					_waiting_scene = followup
					shift.story_waiting_for_clear = true
		if str(_current.get("kind", "")) == "narrative" and str(_current.get("event", {}).get("visitor", "")) == "fiesta_brownout":
			fiesta_brownout_finished.emit()
		if str(_current.get("kind", "")) == "customer_visitor":
			var instance_id := str(_current.get("id", ""))
			var customer := _find_story_customer(instance_id)
			if customer != null:
				customer.story_arrival_pending = false
			customer_story_arrival_finished.emit(instance_id)
		if str(_current.get("kind", "")) == "post_sale":
			shift.finish_story_customer(str(_current.get("id", "")))
		_mode = ""
		_start_next()
		return
	_mode = "beats"
	var beat: Dictionary = _beats.pop_front()
	if str(beat.get("debt_payment", "")) == "paolo_story":
		shift.campaign_state.add_debt("paolo_story", "paolo", 3, 0, 6, {}, true)
		shift.debt_payments_received += shift.campaign_state.repay_debt("paolo_story", 3)
		shift.cash_changed.emit(shift.campaign_state.cash)
	if beat.has("show_prop"):
		_utang_ledger_visible = str(beat["show_prop"]) == "utang_ledger"
		_paolo_note_visible = str(beat["show_prop"]) == "paolo_debt_note"
		if str(beat["show_prop"]) in ["lina_walking_away", "friends_shelter", "alfa_save_corner", "paolo_coins"]:
			_scene_illustration_visible = true
		elif str(beat["show_prop"]) == "hide_scene_illustration":
			_scene_illustration_visible = false
		story_prop_requested.emit(str(beat["show_prop"]))
	var portrait_id := str(beat.get("portrait", ""))
	bubble.show_beat(str(beat.get("speaker", "Narrator")), str(beat.get("text", "")), _portrait(portrait_id), portrait_id)

func _show_scene_choice(choice: Dictionary) -> void:
	var labels: Array[String] = []
	_scene_options = story.filter_story_beats(choice.get("options", []))
	for option in _scene_options:
		labels.append(str(option.get("label", "")))
	_mode = "choice"
	bubble.ask("Narrator", str(choice.get("prompt", "Ano ang gagawin?")), labels, _portrait("tonyo"), "tonyo")

func _resolve_scene_choice(index: int) -> void:
	var event: Dictionary = _current.get("event", {})
	var choice: Dictionary = event.get("choice", {})
	var options: Array = _scene_options
	if index < 0 or index >= options.size():
		_show_scene_choice(choice)
		return
	var option: Dictionary = options[index]
	var choice_id := str(choice.get("id", ""))
	var option_id := str(option.get("id", ""))
	if not story.record_choice(choice_id, option_id):
		push_warning("Could not record story choice %s / %s" % [choice_id, option_id])
		return
	if choice_id == "day3_candy" and option_id == "credit":
		shift.campaign_state.add_debt("paolo_story", "paolo", 3, 0, 6, {}, true)
	var amount := int(option.get("cash_delta", 0))
	if story.get_choice("day2_cash_legacy") == "available":
		amount += int(option.get("cash_delta_legacy", 0))
	if amount != 0:
		if bool(choice.get("record_debt_payment", false)):
			shift.campaign_state.add_debt("rosa_old", "neighbor_rosa", 320, 0, 0, {}, true)
			amount = shift.campaign_state.repay_debt("rosa_old", amount)
		else:
			shift.campaign_state.cash += amount
		if bool(choice.get("record_debt_payment", false)):
			shift.debt_payments_received += amount
		if bool(choice.get("record_sale", false)):
			shift.campaign_state.record_purchase(str(event.get("visitor", "")), amount)
			shift.shift_earnings += amount
			shift.customers_served += 1
			shift.customer_served.emit(str(event.get("visitor", "")), 1)
		shift.cash_changed.emit(shift.campaign_state.cash)
	_scene_choice_done = true
	_play_beats(story.get_choice_response(choice, option_id))


func _portrait(portrait_id: String) -> Texture2D:
	if portrait_id.is_empty() or portrait_atlas == null:
		return null
	return COUNTER_ART.customer_portrait(portrait_id, portrait_atlas)


func _customer_id_of(instance_id: String) -> String:
	for customer in shift.get_active_customers():
		if customer.instance_id == instance_id:
			return customer.customer_id
	return ""


# ---- haggle ----

func _show_haggle() -> void:
	var customer_id := _customer_id_of(str(_current.get("id", "")))
	var entry: Dictionary = _haggle_entries.get(customer_id, {})
	var ask := int(_current.get("ask", 0))
	var speaker := str(entry.get("speaker", customer_id.capitalize()))
	var portrait_id := str(entry.get("portrait", customer_id))
	var text := str(entry.get("text", "Bawasan mo naman ng ₱{ask}.")).replace("{ask}", str(ask))
	var accept := str(entry.get("accept", "Sige po, bawas ₱{ask}")).replace("{ask}", str(ask))
	var refuse := str(entry.get("refuse", "Hindi po talaga"))
	_mode = "choice"
	bubble.ask(speaker, text, [accept, refuse], _portrait(portrait_id), portrait_id)


func _resolve_haggle(accepted: bool) -> void:
	var instance_id := str(_current.get("id", ""))
	var customer_id := _customer_id_of(instance_id)
	var entry: Dictionary = _haggle_entries.get(customer_id, {})
	var choice_id := str(entry.get("choice_id", ""))
	if not choice_id.is_empty():
		story.record_haggle_choice(choice_id, accepted)
	shift.resolve_haggle(instance_id, accepted)
	_play_beats(entry.get("accepted" if accepted else "refused", []))


# ---- kalaro interruption ----

func _show_interruption() -> void:
	var event: Dictionary = _current.get("event", {})
	var portrait_id := str(event.get("portrait", "jun_jun_tara"))
	var options: Array = event.get("options", ["Mamaya na!", "Sandali lang!"])
	_mode = "choice"
	bubble.ask(str(event.get("speaker", "Jun-jun")), str(event.get("text", "Tonyo! Tara na!")), options, _portrait(portrait_id), portrait_id)


func _resolve_interruption(index: int) -> void:
	var event: Dictionary = _current.get("event", {})
	if index == 1:
		_play_beats(event.get("go_beats", DEFAULT_GO_BEATS))
	else:
		_play_beats(event.get("stay_beats", []))


# ---- helper hands over the wrong item ----

func _show_mixup() -> void:
	var product_id := str(_current.get("product", ""))
	var product_name := product_id
	var product := shift.products_by_id.get(product_id) as ProductData
	if product != null and not product.display_name.is_empty():
		product_name = product.display_name
	var prompt := str(_mixup_entry.get("prompt", "Mali ang {product} na inabot ng kalaro!")).replace("{product}", product_name)
	var options: Array = []
	for label in _mixup_entry.get("options", ["Palitan ang {product}", "Hayaan na"]):
		options.append(str(label).replace("{product}", product_name))
	_mode = "choice"
	bubble.ask("Narrator", prompt, options, _portrait("tonyo"), "tonyo")


func _resolve_mixup(caught: bool) -> void:
	var instance_id := str(_current.get("id", ""))
	var product_id := str(_current.get("product", ""))
	shift.resolve_mixup(instance_id, product_id, caught)
	if caught:
		var variants: Array = _mixup_entry.get("caught_variants", [])
		if variants.is_empty():
			_play_beats([])
		else:
			_play_beats(variants[maxi(0, shift.mixup_seen - 1) % variants.size()])
	else:
		_play_beats(_mixup_entry.get("missed", []))

func _on_credit_requested(instance_id: String) -> void:
	_queue_popup({"kind": "credit", "id": instance_id})

func _on_repayment_requested(debt: Dictionary) -> void:
	_queue_popup({"kind": "repayment", "debt": debt})

func _show_credit() -> void:
	var customer := _find_story_customer(str(_current.id))
	if customer == null:
		_start_next()
		return
	bubble.close()
	_credit_layer = CanvasLayer.new()
	_credit_layer.layer = 46
	add_child(_credit_layer)
	credit_panel = preload("res://scripts/utang_offer_panel.gd").new()
	_credit_layer.add_child(credit_panel)
	credit_panel.present(customer, shift.campaign_state, shift.products_by_id, _portrait(customer.customer_id))
	_mode = "credit_choice"
	credit_panel.decided.connect(func(approved: bool):
		if not _active or _mode != "credit_choice": return
		_mode = ""
		shift.resolve_credit(str(_current.id), approved)
		_start_next())

func _hide_credit_panel() -> void:
	if is_instance_valid(_credit_layer):
		if is_instance_valid(credit_panel): credit_panel.hide()
		_credit_layer.queue_free()
	_credit_layer = null
	credit_panel = null
