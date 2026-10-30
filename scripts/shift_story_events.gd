class_name ShiftStoryEvents
extends Node

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

const COUNTER_ART = preload("res://scripts/counter_art.gd")
const MAX_EVENT_MINUTE := 570   # nothing new starts in the last half hour of the shift

const DEFAULT_GO_BEATS: Array = [
	{"speaker": "Narrator", "portrait": "", "text": "Tumakbo si Tonyo palabas saglit... at nainip ang mga naghihintay na customer."},
]

var story: StoryProgression
var shift: ShiftManager
var bubble: DialogueBubble
var portrait_atlas: Texture2D

var _day: int = 0
var _in_shift: bool = false
var _suppressed: bool = false
var _active: bool = false
var _mode: String = ""                          # "", "choice" (answers showing) or "beats" (reaction lines)
var _current: Dictionary = {}
var _queue: Array[Dictionary] = []              # popups waiting for their turn
var _beats: Array[Dictionary] = []              # reaction lines waiting to be shown
var _timed: Array[Dictionary] = []              # events waiting for their minute
var _haggle_entries: Dictionary = {}            # customer_id -> merged haggle entry
var _payment_beats_seen: Dictionary = {}
var _hover_text: Dictionary = {}                # customer_id -> remark shown when they start paying
var _mixup_entry: Dictionary = {}


func bind(story_ref: StoryProgression, shift_ref: ShiftManager, bubble_ref: DialogueBubble, atlas: Texture2D) -> void:
	_disconnect_shift()
	story = story_ref
	shift = shift_ref
	portrait_atlas = atlas
	if bubble != bubble_ref:
		bubble = bubble_ref
		bubble.advanced.connect(_on_bubble_advanced)
		bubble.choice_made.connect(_on_bubble_choice)
	shift.game_minutes_changed.connect(_on_game_minutes)
	shift.haggle_requested.connect(_on_haggle_requested)
	shift.mixup_requested.connect(_on_mixup_requested)
	shift.payment_started.connect(_on_payment_started)
	shift.story_customer_arrived.connect(_on_story_customer_arrived)


func _disconnect_shift() -> void:
	if shift == null or not is_instance_valid(shift):
		return
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


# True while a story popup is on screen. main.gd ignores bubble taps while this is true.
func is_active() -> bool:
	return _active


# Call right before shift.start_shift().
func begin_shift(day: int) -> void:
	_day = day
	_in_shift = true
	_suppressed = false
	_active = false
	_mode = ""
	_queue.clear()
	_beats.clear()
	_timed.clear()
	_haggle_entries.clear()
	_payment_beats_seen.clear()
	_hover_text.clear()
	_mixup_entry = {}
	shift.reset_story_state()
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
		if str(event.get("type", "")) == "customer" and int(event.get("at_minute", 0)) <= 0:
			_run_customer_event(event)   # waiting at the door when the shift starts
		else:
			_timed.append(event)
	_timed.sort_custom(func(a, b): return int(a.get("at_minute", 0)) < int(b.get("at_minute", 0)))
	if OS.is_debug_build():
		print("[story] Day %d shift: %d timed events, haggles for %s, %d mix-ups, %d scripted customers at the door" % [day, _timed.size(), str(_haggle_entries.keys()), shift.mixup_remaining, shift.story_queue.size()])


# Call when the shift ends.
func end_shift() -> void:
	_in_shift = false
	_queue.clear()
	_beats.clear()
	_timed.clear()
	_mode = ""


# Debug "skip day": drop everything so a popup can't stall the fast-forward.
func suppress() -> void:
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
		if int(event.get("at_minute", 0)) > minute:
			return
		var kind := str(event.get("type", ""))
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
		elif kind == "scene" and minute <= MAX_EVENT_MINUTE:
			_queue_popup({"kind": "scene", "event": event})


func _run_customer_event(event: Dictionary) -> void:
	var order: Dictionary = event.get("order", {})
	var arrival_beats := story.filter_story_beats(event.get("arrival_beats", []))
	shift.queue_story_customer(str(event.get("customer", "")), order, bool(event.get("exact_pay", false)), arrival_beats, int(event.get("tendered", 0)))


# ------------------------------------------------------------ shift signals

func _on_story_customer_arrived(_customer_instance_id: String, beats: Array) -> void:
	if _in_shift and not _suppressed:
		_queue_popup({"kind": "arrival", "beats": beats})

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
	if _queue.is_empty():
		_finish()
		return
	_current = _queue.pop_front()
	match str(_current.get("kind", "")):
		"arrival":
			_play_beats(_current.get("beats", []))
		"scene":
			var event: Dictionary = _current.get("event", {})
			var flag := str(event.get("seen_flag", ""))
			if not flag.is_empty():
				story.choices[flag] = "seen"
			_play_beats(story.filter_story_beats(event.get("beats", [])))
		"haggle":
			_show_haggle()
		"mixup":
			_show_mixup()
		"interruption":
			_show_interruption()
		_:
			_start_next()


func _finish() -> void:
	_mode = ""
	bubble.close()
	# Cleared one frame later so main.gd's own bubble handlers (which run for the same
	# signal) still see the popup as active and ignore it.
	call_deferred("_release")


func _release() -> void:
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


func _on_bubble_choice(index: int) -> void:
	if not _active or _mode != "choice":
		return
	_mode = ""
	match str(_current.get("kind", "")):
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
	if _beats.is_empty():
		_mode = ""
		_start_next()
		return
	_mode = "beats"
	var beat: Dictionary = _beats.pop_front()
	var portrait_id := str(beat.get("portrait", ""))
	bubble.show_beat(str(beat.get("speaker", "Narrator")), str(beat.get("text", "")), _portrait(portrait_id), portrait_id)


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
		# He runs out to play: customers lose patience faster for a while.
		shift.apply_patience_boost(float(event.get("drain_mult", 2.0)), float(event.get("drain_seconds", 12.0)))
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
