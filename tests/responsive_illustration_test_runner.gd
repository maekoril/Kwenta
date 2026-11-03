extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var paths := ["res://assets/story/day5_rosa_payment.png", "res://assets/story/day6_fiesta_powerline.png", "res://assets/story/day6_fiesta_fireworks.png"]
	for dimensions in [Vector2i(1920, 1080), Vector2i(2160, 1080), Vector2i(2400, 1080), Vector2i(1080, 1920)]:
		root.size = dimensions
		await process_frame
		for path in paths:
			main._show_gallery_illustration(path, false)
			assert(main.story_illustration.texture != null)
			assert(main.story_illustration.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
			assert(main.story_illustration_previous.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
			assert(main.story_illustration.size.is_equal_approx(main.size))
		var reader = main.pause_menu.diary_reader
		reader.open(main.story)
		reader._select_section(2)
		reader._select_day(6)
		main._show_gallery_illustration(paths[1], false)
		reader.gallery.show_day(main.story, 6)
		reader.gallery.enlarge.pressed.emit()
		await process_frame
		assert(reader.gallery.viewer.size.is_equal_approx(reader.size))
		assert(reader.gallery.large_picture.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		assert(reader.gallery.viewer.get_child(1).size.x >= 72)
		reader.close()
	main.queue_free()
	print("Illustrations and viewer fit landscape and portrait aspect ratios")
	quit()
