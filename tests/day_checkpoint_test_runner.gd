extends SceneTree

const SAVE = preload("res://scripts/campaign_save.gd")
const TEST_PATH = "res://tests/day_checkpoint_test_temp.json"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	SAVE.save_path = TEST_PATH
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	current_scene.find_child("StartButton", true, false).pressed.emit()
	await create_timer(2.0).timeout
	var main = current_scene
	assert(main.checkpoint_ready and SAVE.load_progress().campaign.day == 1)
	var starting_cash: int = main.campaign.cash
	main.campaign.cash += 100
	main.campaign.barangay_trust = 42.0
	main._remember_tutorial("day1_hud")
	main._remember_tutorial("day1_drag")
	var checkpoint := SAVE.load_progress()
	assert(checkpoint.campaign.cash == starting_cash and checkpoint.campaign.barangay_trust == 100.0)
	assert(checkpoint.tutorials.day1_hud and checkpoint.tutorials.day1_drag and not checkpoint.tutorials.has("story_event"))
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	current_scene.find_child("ContinueButton", true, false).pressed.emit()
	await create_timer(2.0).timeout
	main = current_scene
	assert(main.resumed_campaign and main.campaign.day == 1 and main.campaign.cash == starting_cash)
	assert(main.completed_tutorials.day1_hud and main.completed_tutorials.day1_drag)
	assert(not main.story_events._visitor_tutorial_seen)
	main._begin_shift()
	assert(main.opening_sign_active and main.tutorial_step != main.TutorialStep.DAY1_HUD)
	assert(main.tutorial_delivery_seen)
	# A completed supplier tutorial is skipped, while the optional shop remains accessible.
	main.store_sign_tween.kill()
	main.shift_in_progress = false
	main.campaign.day = 2
	main.shop_available = true
	main.completed_tutorials["day2_shop"] = true
	main.story_after_action = "start_shift"
	main._complete_story_beats()
	assert(main.resume_briefing_after_shop and main.shelf_shop.visible)
	main._on_shelf_shop_closed()
	assert(not main.resume_briefing_after_shop and main.showing_pre_shift_briefing)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("Day checkpoint, tutorial persistence, and restart passed")
	quit()
