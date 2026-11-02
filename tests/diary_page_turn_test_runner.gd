extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.story.write_diary_entry(1)
	main.story.write_diary_entry(2)
	main.pause_menu.set_available(true)
	main.pause_menu.pause()
	var reader = main.pause_menu.diary_reader
	reader.open(main.story)
	reader._flip(-1)
	assert(reader.page_turn.visible and reader.page_turn.direction == -1)
	await create_timer(0.18).timeout
	assert(reader.page_turn.progress > 0.0 and reader.page_turn.progress < 1.0)
	reader._flip(1)
	assert(reader.page_turn.direction == 1 and reader.page_index == 1)
	await create_timer(0.7).timeout
	assert(not reader.page_turn.visible and reader.heading.text.contains("DAY 2"))
	reader._flip(1)
	assert(not reader.page_turn.visible)
	reader._flip(-1)
	reader.close()
	assert(not reader.page_turn.visible)
	main.pause_menu.resume()
	main.queue_free()
	print("Notebook page turns animate while paused, handle rapid reversal, bounds and close")
	quit()
