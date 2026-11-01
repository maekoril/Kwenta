extends SceneTree
const SAVE = preload("res://scripts/campaign_save.gd")
const TEST_PATH = "res://tests/diary_reader_save_temp.json"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	SAVE.save_path = TEST_PATH
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var pause = main.pause_menu
	pause.set_available(true)
	pause.pause()
	var reader = pause.diary_reader
	reader.open(main.story)
	assert(paused and reader.visible and reader.days.is_empty())
	main.story.choices["day1_play"] = "play"
	main.story.write_diary_entry(1)
	main.story.choices["diary_goal_day_1"] = "earned"
	main.story.choices["day2_overpayment"] = "return"
	main.story.write_diary_entry(2)
	main.story.choices["diary_goal_day_2"] = "missed"
	reader.open(main.story)
	assert(reader.days == [1, 2] and reader.heading.text.contains("DAY 2"))
	assert(reader.medal.material != null and reader.choice_label.text.contains("Itinabi"))
	reader._flip(-1)
	assert(reader.heading.text.contains("DAY 1") and reader.medal.material == null)
	assert(reader.choice_label.text.contains("Sumama"))
	assert(SAVE.write_checkpoint(main.campaign, main.story, {}))
	var saved = SAVE.load_progress()
	assert(saved.choices["diary_goal_day_1"] == "earned" and saved.choices["diary_goal_day_2"] == "missed")
	reader.close()
	assert(paused)
	pause.resume()
	assert(not paused)
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("Diary reader, navigation, pause and saved goal results passed")
	quit()
