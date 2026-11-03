extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func _check_buttons(board) -> void:
	for child in board.stage.get_children():
		if child is Button:
			assert(child.position.x >= 0 and child.position.y >= 0)
			assert(child.position.x + child.size.x <= board.canvas.size.x + 1)
			assert(child.position.y + child.size.y <= board.canvas.size.y + 1)

func run() -> void:
	var save = load("res://scripts/campaign_save.gd")
	var before := FileAccess.get_file_as_string(save.save_path) if FileAccess.file_exists(save.save_path) else ""
	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var board = load("res://scripts/campaign_board.gd").new()
	board.debug_preview = true
	viewport.add_child(board)
	await process_frame
	for dimensions in [Vector2i(1920, 1080), Vector2i(2400, 1080), Vector2i(1440, 1080), Vector2i(1080, 1920)]:
		viewport.size = dimensions
		await process_frame
		await process_frame
		board._show_board()
		assert(board.is_unlocked(7))
		assert(board.portrait_layout == (dimensions.x < dimensions.y))
		assert(board.board_scroll.size.y > 0)
		_check_buttons(board)
		if DisplayServer.get_name() != "headless" and dimensions.x == 1080:
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png("res://output/campaign-board-phone.png")
		board._show_chapter(7)
		_check_buttons(board)
		if DisplayServer.get_name() != "headless" and dimensions.x == 1080:
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png("res://output/play-day-phone.png")
	viewport.queue_free()
	await process_frame
	if DisplayServer.get_name() != "headless":
		var credit_viewport := SubViewport.new()
		credit_viewport.size = Vector2i(1920, 1080)
		credit_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(credit_viewport)
		var credits = load("res://scripts/credits.gd").new()
		credit_viewport.add_child(credits)
		credits.page = 1
		credits._show_page()
		await create_timer(2.0).timeout
		await RenderingServer.frame_post_draw
		credit_viewport.get_texture().get_image().save_png("res://output/audio-credits-preview.png")
		credit_viewport.queue_free()
		await process_frame
	var debug_script = load("res://scripts/debug_tools.gd")
	debug_script.options_path = "res://tmp/board-debug-test.cfg"
	var debug = debug_script.new()
	root.add_child(debug)
	await process_frame
	debug._toggle()
	assert(paused)
	debug._open_campaign_board()
	assert(debug.has_node("CampaignBoard"))
	assert(debug.get_node("CampaignBoard").is_unlocked(7))
	debug.get_node("CampaignBoard").queue_free()
	await process_frame
	assert(debug.panel.visible)
	assert(paused)
	debug._toggle()
	assert(not paused)
	debug.queue_free()
	await process_frame
	var after := FileAccess.get_file_as_string(save.save_path) if FileAccess.file_exists(save.save_path) else ""
	assert(before == after)
	print("Responsive level cards, play confirmation, debug access and save isolation: PASS")
	quit()
