extends RefCounted

const META := "kwenta_level_replay"
const RETURN_META := "kwenta_replay_return"
const BOARD_SCENE := "res://scenes/campaign_board.tscn"
const CONFIG = preload("res://data/story/summer_campaign.tres")
const SAVE = preload("res://scripts/campaign_save.gd")

static func checkpoint_for(day: int, saved: Dictionary) -> Dictionary:
	day = clampi(day, 1, CONFIG.campaign_day_count)
	var checkpoints: Dictionary = saved.get("replay_checkpoints", {})
	var existing: Variant = checkpoints.get(str(day), {})
	if existing is Dictionary and existing.get("campaign") is Dictionary and existing.get("choices") is Dictionary and int(existing.campaign.get("day", 0)) == day:
		return existing.duplicate(true)
	# Older saves do not contain day-start history. Build a reproducible level
	# baseline rather than carrying a completed campaign's cash into every day.
	var campaign := CampaignState.new(CONFIG)
	while campaign.day < day:
		campaign.advance_day()
	campaign.cash = CONFIG.initial_cash + 150 * (day - 1)
	var story := StoryProgression.new(CONFIG)
	var original: Dictionary = saved.get("choices", {})
	var defaults := {"day1_play": "stay", "day2_overpayment": "return", "day2_haggle": "full", "day3_friends": "stay", "day3_candy": "no", "day4_rain": "shelter", "day5_debt": "installments", "day6_help": "ask"}
	for earlier in range(1, day):
		for key in defaults:
			if str(key).begins_with("day%d_" % earlier):
				story.choices[key] = defaults[key]
		for key in original:
			if str(key).begins_with("day%d_" % earlier):
				story.choices[key] = original[key]
		story.write_diary_entry(earlier)
	if day > 2 and not story.get_choice("day2_overpayment").is_empty():
		story.choices["day2_berting_money"] = "seen"
	if day > 3 and story.get_choice("day3_candy") == "credit":
		campaign.add_debt("paolo_story", "paolo", 3, 0, 6, {}, true)
		if day > 4:
			story.choices["paolo_debt_recorded"] = "yes"
		if day > 6:
			campaign.repay_debt("paolo_story", 3)
			campaign.cash -= 3
	if day > 5 and story.get_choice("day5_debt") == "installments":
		campaign.repay_debt("rosa_old", 110)
		campaign.cash -= 110
	var tutorials := {"day1_hud": day > 1, "day1_drag": day > 1, "story_event": day > 1, "day2_shop": day > 2, "day2_sukli": day > 2, "supplier_first_delivery": day > 2}
	return {"campaign": campaign.to_dict(), "choices": story.choices.duplicate(true), "tutorials": tutorials}

static func launch(tree: SceneTree, day: int, debug_preview: bool) -> void:
	var saved := SAVE.load_progress()
	if not bool(saved.get("completed", false)) and not (debug_preview and OS.is_debug_build()):
		return
	tree.set_meta(META, {"checkpoint": checkpoint_for(day, saved), "debug_access": debug_preview and OS.is_debug_build()})
	for key in ["kwenta_debug_launch", "kwenta_continue_game", "kwenta_menu_story_transition"]:
		if tree.has_meta(key):
			tree.remove_meta(key)
	tree.paused = false
	tree.change_scene_to_file.call_deferred("res://scenes/main.tscn")
