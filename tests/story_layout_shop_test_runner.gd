extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	for viewport_size in [Vector2i(1920, 1080), Vector2i(2400, 1080), Vector2i(1920, 1200)]:
		root.content_scale_size = viewport_size
		main.size = Vector2(viewport_size)
		await process_frame
		for path in ["res://assets/story/day2_box_fall.png", "res://assets/story/berting_counter_50.png"]:
			main.story_illustration.texture = load(path)
			main._update_story_illustration_fit()
			await process_frame
			assert(main.story_illustration.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED)
			assert(main.story_illustration.size.is_equal_approx(main.size))
	main.story_illustration.texture = load("res://assets/story/day5_tonyo_wakes.png")
	main._update_story_illustration_fit()
	assert(main.story_illustration.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	main.queue_free()
	await process_frame
	print("PASS: responsive story shots across three viewport ratios")
	quit()
