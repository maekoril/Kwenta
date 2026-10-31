extends SceneTree

const SAVE = preload("res://scripts/campaign_save.gd")
const TEST_PATH := "res://tests/debug_save_test_temp.json"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	SAVE.save_path = TEST_PATH
	var config = load("res://data/story/summer_campaign.tres")
	var original := CampaignState.new(config)
	original.cash = 321
	assert(SAVE.write_checkpoint(original, StoryProgression.new(config), {}))
	var before := SAVE.load_progress()
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	var debug = current_scene.find_child("DebugOpenButton", true, false).get_parent()
	debug._toggle()
	assert(paused and debug.panel.visible)
	debug.day_select.select(0)
	debug._on_day_selected(0)
	assert(not debug.previous_select.get_parent().visible and not debug.money_select.get_parent().visible)
	assert(_moment_ids(debug.scene_select) == [0, 1, 2, 8])
	debug.day_select.select(1)
	debug._on_day_selected(1)
	assert(debug.previous_select.get_parent().visible and not debug.money_select.get_parent().visible)
	assert(_moment_ids(debug.scene_select) == [0, 1, 2, 3, 8])
	debug.day_select.select(2)
	debug._on_day_selected(2)
	assert(debug.previous_select.get_parent().visible and debug.money_select.get_parent().visible)
	assert(_moment_ids(debug.scene_select) == [0, 1, 2, 4, 5, 6, 7, 8])
	assert(not debug.friends_select.get_parent().visible)
	debug.scene_select.select(debug.scene_select.get_item_index(5))
	debug._on_scene_selected(debug.scene_select.selected)
	assert(not debug.friends_select.get_parent().visible)
	debug.scene_select.select(debug.scene_select.get_item_index(6))
	debug._on_scene_selected(debug.scene_select.selected)
	assert(debug.friends_select.get_parent().visible)
	debug.scene_select.select(debug.scene_select.get_item_index(7))
	debug.day_select.select(3)
	debug._on_day_selected(3)
	assert(_moment_ids(debug.scene_select) == [0, 1, 2, 8])
	assert(debug.scene_select.get_selected_id() == 0)
	debug.day_select.select(2)
	debug._on_day_selected(2)
	debug.money_select.select(1)
	debug.scene_select.select(debug.scene_select.get_item_index(7))
	debug.friends_select.select(0)
	debug._launch()
	await create_timer(1.0).timeout
	var main = current_scene
	assert(main.debug_session and main.campaign.day == 3)
	assert(main.story.get_choice("day2_overpayment") == "keep")
	assert(main.story.get_choice("day2_money_separate") == "yes")
	assert(main.story.get_choice("day3_friends") == "later")
	assert(main.story_events._mode == "visitor")
	assert(main.story_events._current.event.visitor == "paolo")
	assert(main.shift.get_active_customers().is_empty())
	main.story_visitor_entrance.kill()
	main.story_events.visitor_entrance_finished.emit()
	main.story_events.find_child("StoryVisitorButton", true, false).pressed.emit()
	while main.story_events._mode == "beats":
		main.bubble.advanced.emit()
	main.bubble.choice_made.emit(0)
	while main.story_events._mode == "beats":
		main.bubble.advanced.emit()
	main.pending_shift_summary_text = "TODAY'S SALES\nTest"
	main._show_pending_shift_summary()
	assert(SAVE.load_progress() == before)
	# Relaunching from a running debug session also preserves the real checkpoint.
	debug = main.find_child("DebugOpenButton", true, false).get_parent()
	debug._toggle()
	debug.day_select.select(1)
	debug._on_day_selected(1)
	debug.scene_select.select(debug.scene_select.get_item_index(3))
	debug._launch()
	await create_timer(1.0).timeout
	main = current_scene
	assert(main.debug_session and main.campaign.day == 2)
	assert(main.story_events._current.event.visitor == "mang_berting")
	assert(main.story.get_choice("day2_overpayment").is_empty())
	assert(SAVE.load_progress() == before)
	debug = main.find_child("DebugOpenButton", true, false).get_parent()
	debug._toggle()
	debug.day_select.select(2)
	debug._on_day_selected(2)
	debug.scene_select.select(debug.scene_select.get_item_index(6))
	debug.friends_select.select(1)
	debug._launch()
	await create_timer(1.0).timeout
	main = current_scene
	assert(main.story_events._current.event.visitor == "bea")
	assert(main.story.get_choice("day3_friends") == "stay")
	assert(main.story_events._timed.any(func(event): return event.get("visitor") == "paolo"))
	assert(SAVE.load_progress() == before)
	for expected in ["later", "stay", ""]:
		debug = main.find_child("DebugOpenButton", true, false).get_parent()
		debug._toggle()
		debug.day_select.select(2)
		debug._on_day_selected(2)
		debug.scene_select.select(debug.scene_select.get_item_index(8))
		debug._on_scene_selected(debug.scene_select.selected)
		assert(debug.friends_select.get_parent().visible)
		debug.friends_select.select(["later", "stay", ""].find(expected))
		debug._launch()
		await create_timer(1.0).timeout
		main = current_scene
		assert(main.story.get_choice("day3_friends") == expected)
		var outro: Array = main.story.get_day_outro_beats(3)
		assert(outro.any(func(beat): return str(beat.get("text", "")).contains("pangako niyang susunod")) == (expected == "later"))
		assert(outro.any(func(beat): return str(beat.get("text", "")).contains("hindi ako nakasama")) == (expected == "stay"))
		assert(SAVE.load_progress() == before)
	debug = main.find_child("DebugOpenButton", true, false).get_parent()
	debug._toggle()
	debug.day_select.select(0)
	debug._on_day_selected(0)
	debug.scene_select.select(debug.scene_select.get_item_index(0))
	debug._launch()
	await create_timer(1.0).timeout
	main = current_scene
	assert(main.debug_session and main.campaign.day == 1)
	assert(main.story.get_choice("day1_play").is_empty())
	assert(main.story.get_choice("day2_overpayment").is_empty())
	assert(SAVE.load_progress() == before)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("Debug event launches, branches, pause, and save isolation passed")
	quit()

func _moment_ids(select: OptionButton) -> Array:
	var ids := []
	for i in range(select.item_count):
		ids.append(select.get_item_id(i))
	return ids
