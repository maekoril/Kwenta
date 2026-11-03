extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var board = load("res://scripts/campaign_board.gd").new()
	root.add_child(board)
	await process_frame
	board.saved = {}
	board.debug_preview = false
	assert(not board.is_unlocked(1) and not board.is_unlocked(7))
	board.debug_preview = true
	for day in range(1,8):
		assert(board.is_unlocked(day))
		board._show_chapter(day)
		assert(board.stage.get_node("PlayDayButton").text == "PLAY DAY %d" % day)
	board.debug_preview = false
	board.saved = {"completed":true}
	assert(board.is_unlocked(7))
	assert(not board.is_unlocked(0))
	board.queue_free()
	await process_frame
	print("Level selection, completion lock and debug access: PASS")
	quit()
