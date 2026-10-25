class_name StoryProgression
extends RefCounted

var config: CampaignConfig
var choices: Dictionary = {}
var story_data: Dictionary = {}

func _init(campaign_config: CampaignConfig) -> void:
	config = campaign_config
	story_data = _load_story_data(config.story_source_path)

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

func get_day_choices(day: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for choice_value in _get_day(day).get("choices", []):
		if choice_value is Dictionary:
			result.append(choice_value.duplicate(true))
	return result

func record_choice(choice_id: String, option_id: String) -> bool:
	for day in range(1, get_campaign_day_count() + 1):
		for choice_data in get_day_choices(day):
			if str(choice_data.get("id", "")) != choice_id:
				continue
			for option_value in choice_data.get("options", []):
				if option_value is Dictionary and str(option_value.get("id", "")) == option_id:
					choices[choice_id] = option_id
					return true
	return false

func get_choice_response(choice_data: Dictionary, option_id: String) -> Array[Dictionary]:
	for option_value in choice_data.get("options", []):
		if not option_value is Dictionary or str(option_value.get("id", "")) != option_id:
			continue
		var response: String = str(option_value.get("response", ""))
		if response.is_empty():
			return []
		return [{
			"speaker": str(option_value.get("response_speaker", "Tonyo")),
			"portrait": str(option_value.get("response_portrait", "tonyo")),
			"text": response,
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
