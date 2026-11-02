extends SceneTree

const SAVE = preload("res://scripts/campaign_save.gd")
const TEST_PATH := "res://tests/diary_save_test_temp.json"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var config: CampaignConfig = load("res://data/story/summer_campaign.tres")
	var story := StoryProgression.new(config)
	var prologue := story.get_prologue_beats()
	assert(prologue.any(func(beat): return str(beat.get("text", "")).contains("presyo ng paninda")))
	assert(prologue.any(func(beat): return str(beat.get("text", "")).contains("nangyari sa araw mo")))
	story.choices["day1_play"] = "play"
	assert(story.write_diary_entry(1).contains("nakapaglaro"))
	story.choices["day1_play"] = "stay"
	assert(story.write_diary_entry(1).contains("Hindi ako nakasama"))
	story.choices["day2_overpayment"] = "return"
	assert(story.write_diary_entry(2).contains("Itinabi ko"))
	story.choices["day3_candy"] = "credit"
	assert(story.write_diary_entry(3).contains("Pinautang"))
	for option in ["join", "stay", "shelter"]:
		story.choices["day4_rain"] = option
		var entry := story.write_diary_entry(4)
		assert(not entry.is_empty())
		assert(entry.contains("Aling Lina") == (option == "join"))
		assert(entry.contains("Feeta") == (option == "shelter"))
	for day in range(1, 8):
		assert(not story.write_diary_entry(day).is_empty())
	SAVE.save_path = TEST_PATH
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	main.campaign.day = 4
	main.story.choices["day4_rain"] = "shelter"
	main.pending_shift_summary_text = "TODAY'S SALES\nTest"
	main.pending_shift_summary_title = "DAY 4 COMPLETE"
	main._finish_story_day()
	assert(main.story_after_action == "diary_complete")
	assert(main.story.choices["diary_day_4"].contains("Feeta"))
	assert(not main.showing_post_shift_summary)
	main.bubble.advanced.emit()
	main.bubble.advanced.emit()
	assert(main.showing_post_shift_summary)
	var saved := SAVE.load_progress()
	assert(saved.choices["diary_day_4"].contains("Feeta"))
	assert(int(saved.campaign.day) == 5)
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("Daily diary follows story choices, appears before summary, and persists")
	quit()
