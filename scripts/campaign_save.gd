extends RefCounted

const VERSION := 1
static var save_path := "user://campaign_save.json"

static func load_progress() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	if not value is Dictionary or int(value.get("version", 0)) != VERSION:
		return {}
	var campaign: Variant = value.get("campaign")
	var choices: Variant = value.get("choices")
	if not campaign is Dictionary or not choices is Dictionary:
		return {}
	if int(campaign.get("day", 0)) < 1 or int(campaign.get("day", 0)) > 7:
		return {}
	for key in ["customer_trust", "product_price_bonuses"]:
		if campaign.has(key) and not campaign[key] is Dictionary:
			return {}
	for key in ["unlocked_product_ids", "purchased_upgrade_ids", "purchased_store_groups"]:
		if campaign.has(key) and not campaign[key] is Array:
			return {}
	return value

static func write_progress(campaign: CampaignState, story: StoryProgression, tutorials: Dictionary = {}) -> bool:
	var next := CampaignState.new(campaign.config)
	next.from_dict(campaign.to_dict())
	var completed := next.day >= campaign.config.campaign_day_count
	if not completed:
		next.advance_day()
	var data := {"version": VERSION, "campaign": next.to_dict(), "choices": story.choices.duplicate(true), "completed": completed, "tutorials": tutorials.duplicate(true)}
	return _write_data(data)

static func write_checkpoint(campaign: CampaignState, story: StoryProgression, tutorials: Dictionary) -> bool:
	return _write_data({"version": VERSION, "campaign": campaign.to_dict(), "choices": story.choices.duplicate(true), "completed": false, "tutorials": tutorials.duplicate(true)})

static func remember_tutorial(tutorial_id: String) -> bool:
	var data := load_progress()
	if data.is_empty():
		return false
	var tutorials: Dictionary = data.get("tutorials", {})
	tutorials[tutorial_id] = true
	data["tutorials"] = tutorials
	return _write_data(data)

static func _write_data(data: Dictionary) -> bool:
	var temporary := save_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save campaign progress: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		push_warning("Could not write campaign progress: %s" % error_string(error))
		return false
	error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(save_path))
	if error != OK:
		push_warning("Could not replace campaign save: %s" % error_string(error))
		return false
	return true
