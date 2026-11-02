extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var first = "res://assets/story/day4_friends_shelter.png"
	var second = "res://assets/story/day4_lina_alfa_corner.png"
	main._show_gallery_illustration(first)
	assert(main.story_illustration.visible and main.story_illustration.modulate.a < 0.1)
	await create_timer(0.5).timeout
	assert(main.story_illustration.modulate.a > 0.99)
	main._show_gallery_illustration(second)
	assert(main.story_illustration_previous.visible and main.story_illustration.texture.resource_path == second)
	await create_timer(0.5).timeout
	assert(not main.story_illustration_previous.visible and main.story_illustration.modulate.a > 0.99)
	main._hide_gallery_illustration()
	assert(not main.story_illustration.visible and main.story_illustration_previous.visible)
	main._show_gallery_illustration(first)
	assert(main.story_illustration.visible and main.story_illustration_previous.visible)
	await create_timer(0.5).timeout
	assert(main.story_illustration.texture.resource_path == first and not main.story_illustration_previous.visible)
	main._hide_gallery_illustration()
	await create_timer(0.5).timeout
	assert(not main.story_illustration_previous.visible)
	main.queue_free()
	print("Illustration fade, crossfade, hide and interrupted transitions passed")
	quit()
