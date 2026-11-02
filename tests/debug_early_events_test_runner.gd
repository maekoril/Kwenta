extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func launch(day: int, moment: int) -> void:
	set_meta("kwenta_debug_launch", {"day": day, "moment": moment, "skip_tutorials": true, "day1": "play", "day2": "return"})
	change_scene_to_file("res://scenes/main.tscn")
	await create_timer(1.3).timeout
func run() -> void:
	await launch(1, 11)
	assert(current_scene.story_after_action == "prologue_end" and current_scene.prologue_background.visible)
	await launch(1, 12)
	var main = current_scene
	assert(main.story_after_action == "day_choices")
	assert(main.story_beats.any(func(beat): return beat.get("story_visitor") == "jun_jun_tara"))
	await launch(2, 13)
	main = current_scene
	assert(main.story_after_action == "start_shift")
	assert(main.story_beats[0].get("cutscene") == "box_fall")
	assert(main.story_beats.any(func(beat): return bool(beat.get("supplier_note", false))))
	await launch(2, 14)
	main = current_scene
	assert(main.shift_in_progress)
	print("Day 1 prologue and friends; Day 2 box, note and first customer shortcuts passed")
	quit()
