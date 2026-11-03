extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	set_meta("kwenta_debug_launch", {"day": 7, "moment": 33, "skip_tutorials": true, "day4_rain": "shelter"})
	change_scene_to_file("res://scenes/main.tscn")
	await create_timer(1.2).timeout
	var main = current_scene
	assert(main.prologue_fade.visible and main.day7_time_label.visible)
	assert(main.day7_time_label.text == "Kinabukasan...")
	var title_index: int = main.story_beat_index
	main.bubble.advanced.emit()
	main._on_summary_button_pressed()
	assert(main.story_beat_index == title_index)
	await create_timer(3.0).timeout
	assert(main.prologue_fade.visible and main.prologue_fade.modulate.a > 0.99)
	assert(main.bubble._text.text.contains("Palakpakan"))
	main.bubble.advanced.emit()
	await create_timer(3.4).timeout
	assert(not main.prologue_fade.visible)
	assert(main.story_illustration.texture.resource_path.ends_with("day7_classroom_turn.png"))
	var seen := []
	for i in range(60):
		if main.story_illustration.visible and main.story_illustration.texture != null:
			seen.append(main.story_illustration.texture.resource_path.get_file())
		if main.story_complete: break
		main.bubble.advanced.emit()
		await process_frame
	assert(main.story_complete and main.has_node("EndingTransition"))
	assert(seen.has("day7_classmates_listening.png"))
	assert(seen.has("day7_tonyo_presenting.png"))
	assert(seen.has("day7_tonyo_miniature.png"))
	assert(seen.find("day7_classmates_listening.png") < seen.find("day7_tonyo_presenting.png"))
	assert(seen.find("day7_tonyo_presenting.png") < seen.find("day7_tonyo_miniature.png"))
	print("Day 7 black title, teacher, walk and classroom reveal passed")
	quit()
