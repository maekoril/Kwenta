class_name StoryProgression
extends RefCounted

var config: CampaignConfig
var choices: Dictionary = {}
var story_data: Dictionary = {}

func _init(campaign_config: CampaignConfig) -> void:
	config = campaign_config
	story_data = _load_story_data(config.story_source_path)
	if OS.is_debug_build():
		_lint_story()

func get_campaign_title() -> String:
	return str(story_data.get("title", "Kwenta"))

func get_campaign_day_count() -> int:
	return maxi(1, int(config.campaign_day_count))

func get_prologue_beats() -> Array[Dictionary]:
	return _filtered_beats(story_data.get("prologue", []))

func get_day_title(day: int) -> String:
	var day_data := _get_day(day)
	return str(day_data.get("title", "Day %d" % day))

func get_day_intro_beats(day: int) -> Array[Dictionary]:
	return _filtered_beats(_get_day(day).get("intro", []))

func get_day_outro_beats(day: int) -> Array[Dictionary]:
	return _filtered_beats(_get_day(day).get("outro", []))

func get_day_callback_beats(day: int) -> Array[Dictionary]:
	return _filtered_beats(_get_day(day).get("callbacks", []))

# Choices asked after the shift (the original behavior).
func get_day_choices(day: int) -> Array[Dictionary]:
	return _day_choice_list(day, "choices")

# Choices asked after the day's intro and BEFORE the shift starts, so they can
# change how that shift plays (e.g. Day 6 "Tulong").
func get_day_intro_choices(day: int) -> Array[Dictionary]:
	return _day_choice_list(day, "intro_choices")

func _day_choice_list(day: int, key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for choice_value in _filtered_beats(_get_day(day).get(key, [])):
		if choice_value is Dictionary:
			result.append(choice_value.duplicate(true))
	return result

func record_choice(choice_id: String, option_id: String) -> bool:
	for day in range(1, get_campaign_day_count() + 1):
		var day_choices: Array[Dictionary] = get_day_intro_choices(day)
		day_choices.append_array(get_day_choices(day))
		for choice_data in day_choices:
			if str(choice_data.get("id", "")) != choice_id:
				continue
			for option_value in choice_data.get("options", []):
				if option_value is Dictionary and str(option_value.get("id", "")) == option_id:
					choices[choice_id] = option_id
					return true
	return false

func record_haggle_choice(choice_id: String, accepted: bool) -> bool:
	for day in range(1, get_campaign_day_count() + 1):
		for entry in get_day_haggles(day):
			if str(entry.get("choice_id", "")) != choice_id:
				continue
			var key := "accept_choice_id" if accepted else "refuse_choice_id"
			var value := str(entry.get(key, ""))
			if value.is_empty():
				return false
			choices[choice_id] = value
			return true
	return false

# ---- In-shift story data (played by shift_story_events.gd) ----
# Every entry can be gated with when_choice / when_value(s), like any beat. Later entries
# for the same customer override earlier ones.
#   "shift_events": scripted customers and kalaro interruptions, each with "at_minute"
#   "haggle":       customers who ask for a discount ("customer", "ask", lines...)
#   "hover":        a customer who watches the change ("customer", "text", "payment_patience_mult")
#   "mixups":       helper mix-ups ("count", "every", lines...)
func get_day_shift_events(day: int) -> Array[Dictionary]:
	return _filtered_beats(_get_day(day).get("shift_events", []))

func filter_story_beats(beats: Variant) -> Array[Dictionary]:
	return _filtered_beats(beats)

func get_day_haggles(day: int) -> Array[Dictionary]:
	return _filtered_beats(_get_day(day).get("haggle", []))

func get_day_hovers(day: int) -> Array[Dictionary]:
	return _filtered_beats(_get_day(day).get("hover", []))

func get_day_mixups(day: int) -> Array[Dictionary]:
	return _filtered_beats(_get_day(day).get("mixups", []))

# An option may carry "cash_delta" (e.g. +50 for keeping Mang Berting's overpayment).
func get_choice_cash_delta(choice_data: Dictionary, option_id: String) -> int:
	for option_value in choice_data.get("options", []):
		if option_value is Dictionary and str(option_value.get("id", "")) == option_id:
			return int(option_value.get("cash_delta", 0))
	return 0

# A day can list "modifiers" in the story JSON, each gated like any other beat
# (when_choice / when_value / when_values):
#   {"when_choice": "day6_help", "when_value": "ask", "patience_mult": 1.25}
# Every matching entry applies; patience multipliers multiply together.
func get_day_modifiers(day: int) -> Dictionary:
	var result := {"patience_mult": 1.0}
	for entry in _filtered_beats(_get_day(day).get("modifiers", [])):
		result["patience_mult"] = float(result["patience_mult"]) * float(entry.get("patience_mult", 1.0))
	return result

# An option's "response" can be either:
#   - a plain string (one beat, spoken by "response_speaker" / "response_portrait", as before), or
#   - a list of beats, so speech and narration can be separate lines:
#       "response": [
#         {"speaker": "Tonyo", "portrait": "tonyo", "text": "Pasensya na, kulang pa."},
#         {"speaker": "Narrator", "portrait": "paolo_sad", "text": "Umuwi si Paolo na malungkot."}
#       ]
#     A beat in the list may leave out "speaker" / "portrait"; it then falls back to the
#     option's "response_speaker" / "response_portrait" (a Narrator beat falls back to no portrait).
#     Beats in the list also support "when_choice" / "when_value(s)" like any other beat.
func get_choice_response(choice_data: Dictionary, option_id: String) -> Array[Dictionary]:
	for option_value in choice_data.get("options", []):
		if not option_value is Dictionary or str(option_value.get("id", "")) != option_id:
			continue
		var default_speaker: String = str(option_value.get("response_speaker", "Tonyo"))
		var default_portrait: String = str(option_value.get("response_portrait", "tonyo"))
		var response: Variant = option_value.get("response", "")
		if response is Array:
			return _response_beats(response, default_speaker, default_portrait)
		var text: String = str(response)
		if text.is_empty():
			return []
		return [{
			"speaker": default_speaker,
			"portrait": default_portrait,
			"text": text,
		}]
	return []

func get_choice(choice_id: String) -> String:
	return str(choices.get(choice_id, ""))

func reset() -> void:
	choices.clear()

func _get_day(day: int) -> Dictionary:
	for day_value in story_data.get("days", []):
		if day_value is Dictionary and int(day_value.get("day", 0)) == day:
			return day_value
	return {}

func _response_beats(raw_beats: Array, default_speaker: String, default_portrait: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for beat in _filtered_beats(raw_beats):
		if str(beat.get("text", "")).is_empty():
			continue
		if not beat.has("speaker"):
			beat["speaker"] = default_speaker
		if not beat.has("portrait"):
			beat["portrait"] = "" if _is_narrator(str(beat["speaker"])) else default_portrait
		result.append(beat)
	return result

func _filtered_beats(raw_beats: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not raw_beats is Array:
		return result
	for beat_value in raw_beats:
		if not beat_value is Dictionary:
			continue
		var choice_id: String = str(beat_value.get("when_choice", ""))
		if not choice_id.is_empty():
			var selected: String = get_choice(choice_id)
			var allowed_values: Array = beat_value.get("when_values", [])
			if allowed_values.is_empty():
				allowed_values = [str(beat_value.get("when_value", ""))]
			if not allowed_values.has(selected):
				continue
		var beat: Dictionary = beat_value.duplicate(true)
		beat.erase("when_choice")
		beat.erase("when_value")
		beat.erase("when_values")
		result.append(beat)
	return result

func _is_narrator(speaker_name: String) -> bool:
	return speaker_name.strip_edges() == "" or speaker_name.strip_edges().to_lower() == "narrator"

func _load_story_data(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		push_error("Story source not found: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open story source: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	push_error("Story source is not valid JSON: %s" % path)
	return {}

# ---- Debug-only story check -------------------------------------------------
# Runs when the story loads in a debug build and prints warnings in Godot's output
# for lines that look mislabeled. It never changes anything. Once the story data is
# clean, it prints nothing.

func _lint_story() -> void:
	_lint_beats(story_data.get("prologue", []), "prologue")
	for day_value in story_data.get("days", []):
		if not day_value is Dictionary:
			continue
		var day: int = int(day_value.get("day", 0))
		for section in ["intro", "outro", "callbacks"]:
			_lint_beats(day_value.get(section, []), "day %d %s" % [day, section])
		for choice_key in ["choices", "intro_choices"]:
			for choice_value in day_value.get(choice_key, []):
				if not choice_value is Dictionary:
					continue
				for option_value in choice_value.get("options", []):
					if not option_value is Dictionary:
						continue
					var where := "day %d choice %s/%s" % [day, str(choice_value.get("id", "?")), str(option_value.get("id", "?"))]
					var response: Variant = option_value.get("response", "")
					if response is Array:
						_lint_beats(response, where)
					else:
						_lint_beat(str(option_value.get("response_speaker", "Tonyo")), str(response), where)

func _lint_beats(raw_beats: Variant, where: String) -> void:
	if not raw_beats is Array:
		return
	var index := 0
	for beat_value in raw_beats:
		index += 1
		if beat_value is Dictionary:
			_lint_beat(str(beat_value.get("speaker", "Narrator")), str(beat_value.get("text", "")), "%s #%d" % [where, index])

func _lint_beat(speaker_name: String, text: String, where: String) -> void:
	if text.strip_edges().is_empty():
		push_warning("Story: empty text at %s" % where)
		return
	if _is_narrator(speaker_name):
		return
	# A character rarely says their own name while talking; this is almost always
	# a narration line ("Tahimik na kumaway si Bogs...") filed under the character.
	if text.contains(speaker_name):
		push_warning("Story: [%s] has a line that mentions themself, probably narration -> \"%s\" (%s)" % [speaker_name, text, where])
