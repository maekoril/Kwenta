extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var credits = load("res://scripts/credits.gd").new()
	root.add_child(credits)
	await process_frame
	assert(credits.content.team.size() == 3)
	for dimensions in [Vector2i(1920, 1080), Vector2i(2400, 1080), Vector2i(1080, 1920)]:
		root.size = dimensions
		await process_frame
		assert(credits.canvas.position.x >= -1 and credits.canvas.position.y >= -1)
		assert(credits.canvas.size.x * credits.canvas.scale.x <= credits.size.x + 1)
		for page in range(3):
			credits.page = page
			credits._show_page()
			await process_frame
	credits.queue_free()
	await process_frame
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.campaign.day = 7
	main.debug_session = true
	main.pending_shift_summary_text = "Final day results"
	main._finish_story_day()
	assert(main.story_complete)
	assert(main.has_node("EndingTransition"))
	assert(not main.has_node("Credits"))
	main._advance_story_day()
	await main.get_node("EndingTransition").tree_exited
	assert(main.has_node("Credits"))
	assert(not main.briefing_card.visible)
	main.get_node("Credits").campaign_board_requested.emit()
	assert(main.has_node("CampaignBoard"))
	assert(main.get_node("CampaignBoard").is_unlocked(7))
	main.queue_free()
	await process_frame
	print("Credits pages, responsive layout, and campaign ending: PASS")
	quit()
