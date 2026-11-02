extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for moment in [25, 26]:
		set_meta("kwenta_debug_launch", {"day": 1, "moment": moment, "skip_tutorials": true})
		change_scene_to_file("res://scenes/main.tscn")
		await create_timer(1.0).timeout
		var main = current_scene
		if main.opening_sign_active:
			if main.store_sign_tween != null: main.store_sign_tween.kill()
			main._after_opening_sign()
		await create_timer(0.8).timeout
		if moment == 25:
			assert(main.story_events._mode == "visitor")
			assert(main.shift.active_customers.is_empty())
			assert(main.story_events.find_child("StoryVisitorTutorial", true, false) != null)
		else:
			assert(main.shift.active_customers.size() == 1)
			assert(main.shift.active_customers[0].customer_id == "aling_nena")
			for i in range(2): main.bubble.advanced.emit()
			await create_timer(0.4).timeout
			assert(main.tutorial_step == main.TutorialStep.DAY1_PRODUCT)
	print("Latest Day 1 debug shortcuts passed")
	quit()
