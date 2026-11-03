extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var board = load("res://scripts/campaign_board.gd").new()
	board.debug_preview = true
	root.add_child(board)
	await process_frame
	board.day = 7
	var beats: Array[Dictionary] = [
		{"cutscene": "day7_project", "speaker": "Tonyo", "text": "Project"},
		{"cutscene": "day7_time_card", "text": "Kinabukasan..."},
		{"speaker": "Teacher", "text": "Palakpakan natin si Tonyo!"},
		{"cutscene": "day7_walk", "text": "Tumayo si Tonyo."}
	]
	board._start_replay(beats)
	board._advance()
	assert(board.time_card.visible)
	assert(board.time_title.text == "Kinabukasan...")
	board._advance()
	assert(board.index == 1)
	await create_timer(1.6).timeout
	assert(board.time_card.modulate.a > 0.99)
	assert(board.time_title.modulate.a > 0.99)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/kinabukasan-replay.png")
	await create_timer(2.0).timeout
	assert(board.index == 2)
	assert(not board.time_card.visible)
	assert(board.image.texture == null and board.replay_background.visible)
	board._advance()
	assert(board.image.texture.resource_path.ends_with("day7_classroom_turn.png"))
	assert(not board.time_card.visible and not board.replay_background.visible)
	board.queue_free()
	await process_frame
	print("Replay black title fade, input lock, teacher and classroom reveal: PASS")
	quit()
