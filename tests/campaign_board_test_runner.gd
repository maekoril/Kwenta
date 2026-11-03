extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var save = load("res://scripts/campaign_save.gd")
	var before := FileAccess.get_file_as_string(save.save_path) if FileAccess.file_exists(save.save_path) else ""
	var board = load("res://scripts/campaign_board.gd").new()
	root.add_child(board)
	await process_frame
	board.saved = {}
	board.progress.choices = {}
	assert(board.is_unlocked(0))
	assert(not board.is_unlocked(1))
	board.saved = {"campaign": {"day": 4}}
	assert(board.is_unlocked(3))
	assert(not board.is_unlocked(4))
	board.saved = {"completed": true}
	for day in range(1, 8):
		assert(board.is_unlocked(day))
		board._show_chapter(day)
		for beats in [board.progress.get_day_intro_beats(day), board.progress.get_day_outro_beats(day), board.progress.get_day_callback_beats(day)]:
			if beats.is_empty():
				continue
			board._start_replay(beats)
			for index in range(beats.size()):
				board.index = index
				board._refresh_beat()
				assert(board.image.texture != null or board.images[index].is_empty())
	board._show_chapter(0)
	assert(board.beats.size() > 0)
	board._show_board()
	await create_timer(0.5).timeout
	if not DisplayServer.get_name() == "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/campaign-board-preview.png")
	var after := FileAccess.get_file_as_string(save.save_path) if FileAccess.file_exists(save.save_path) else ""
	assert(before == after)
	board.queue_free()
	await process_frame
	print("Campaign board unlocks, all chapter replays, and save isolation: PASS")
	quit()
