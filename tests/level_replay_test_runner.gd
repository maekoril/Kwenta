extends SceneTree
const SAVE = preload("res://scripts/campaign_save.gd")
const REPLAY = preload("res://scripts/level_replay.gd")
const CONFIG = preload("res://data/story/summer_campaign.tres")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	SAVE.save_path = "res://tmp/level_replay_test_save.json"
	preload("res://scripts/debug_tools.gd").options_path = "res://tmp/level_replay_debug.cfg"
	var campaign := CampaignState.new(CONFIG)
	var story := StoryProgression.new(CONFIG)
	assert(SAVE.write_checkpoint(campaign, story, {}))
	campaign.cash = 777
	campaign.purchased_store_groups.append("water_shelf")
	story.choices["day1_play"] = "stay"
	assert(SAVE.write_progress(campaign, story, {"day1_hud": true}))
	var saved := SAVE.load_progress()
	assert(saved.replay_checkpoints["1"].campaign.day == 1)
	assert(saved.replay_checkpoints["2"].campaign.cash == 777)
	assert(saved.replay_checkpoints["2"].campaign.purchased_store_groups.has("water_shelf"))
	var snapshot := REPLAY.checkpoint_for(2, saved)
	snapshot.campaign.cash = 1
	assert(saved.replay_checkpoints["2"].campaign.cash == 777)
	campaign.day = 7
	assert(SAVE.write_progress(campaign, story, {}))
	var before := FileAccess.get_file_as_string(SAVE.save_path)
	for day in range(1, 8):
		REPLAY.launch(self, day, false)
		await process_frame
		await process_frame
		await process_frame
		var main = current_scene
		assert(main.replay_session and not main.debug_session)
		assert(main.campaign.day == day)
		assert(main.pause_menu.return_scene == REPLAY.BOARD_SCENE)
		assert(not main.product_items_by_id.is_empty())
		if day == 2:
			assert(main.campaign.cash == 777)
			assert(main.campaign.purchased_store_groups.has("water_shelf"))
		assert(main.daily_goal_day == day)
		# Exercise the actual shift/customer systems, not a dialogue-only player.
		main.completed_tutorials["day1_hud"] = true
		main._begin_shift()
		main.shift.start_shift()
		assert(main.shift_in_progress and main.shift.is_running)
		assert(not main.shift.active_customers.is_empty())
		main.campaign.cash += 123
		if day == 3:
			var shift_cash: int = main.shift_start_cash
			main._retry_current_day()
			assert(main.campaign.day == 3 and main.campaign.cash == shift_cash)
			assert(main.game_over_screen.has_node("ReplayReturnToBoardButton"))
		main._remember_tutorial("replay_test")
		main.shift_in_progress = false
		main.shift.is_running = false
		if day < 7:
			main.pending_shift_summary_text = "Replay results"
			main.pending_shift_summary_title = "DAY %d COMPLETE" % day
			main._show_pending_shift_summary()
			assert(main.briefing_card.visible)
			assert(main.briefing_card._button.text == "CAMPAIGN BOARD")
			main._on_summary_button_pressed()
		else:
			main.pending_shift_summary_text = ""
			main._finish_story_day()
			assert(main.story_complete)
			await main.get_node("EndingTransition").tree_exited
			main.get_node("Credits").campaign_board_requested.emit()
		await process_frame
		await process_frame
		assert(current_scene.name == "CampaignBoard")
		assert(FileAccess.get_file_as_string(SAVE.save_path) == before)
	# Pause exit is another path that must return to the board safely.
	REPLAY.launch(self, 3, false)
	await process_frame
	await process_frame
	await process_frame
	current_scene.pause_menu._confirm_main_menu()
	await process_frame
	await process_frame
	assert(current_scene.name == "CampaignBoard")
	assert(not paused)
	assert(FileAccess.get_file_as_string(SAVE.save_path) == before)
	REPLAY.launch(self, 4, false)
	await process_frame
	await process_frame
	await process_frame
	current_scene.game_over_screen.get_node("ReplayReturnToBoardButton").pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene.name == "CampaignBoard")
	assert(FileAccess.get_file_as_string(SAVE.save_path) == before)
	# Debug selection must also launch real levels without changing an unfinished save.
	campaign = CampaignState.new(CONFIG)
	story = StoryProgression.new(CONFIG)
	assert(SAVE.write_checkpoint(campaign, story, {}))
	var debug_before := FileAccess.get_file_as_string(SAVE.save_path)
	var tools = preload("res://scripts/debug_tools.gd").new()
	current_scene.add_child(tools)
	tools._toggle()
	tools._open_campaign_board()
	var debug_board = tools.get_node("CampaignBoard")
	debug_board._show_chapter(4)
	debug_board.stage.get_node("PlayDayButton").pressed.emit()
	await process_frame
	await process_frame
	await process_frame
	assert(current_scene.replay_session and current_scene.replay_debug_access)
	assert(current_scene.campaign.day == 4 and not paused)
	current_scene._return_to_campaign_board()
	await process_frame
	await process_frame
	assert(current_scene.debug_preview and current_scene.is_unlocked(7))
	assert(FileAccess.get_file_as_string(SAVE.save_path) == debug_before)
	print("All seven playable days, day-start restoration, retry/summary/credits/pause returns, debug launch and save isolation: PASS")
	quit()
