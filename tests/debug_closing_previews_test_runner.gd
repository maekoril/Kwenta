extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for day in range(1, 8):
		set_meta("kwenta_debug_launch", {"day": day, "moment": 8, "skip_tutorials": true})
		change_scene_to_file("res://scenes/main.tscn")
		await create_timer(3.5).timeout
		var main = current_scene
		assert(main.debug_session and main.campaign.day == day)
		assert(main.story_after_action == "day_choices")
		assert(main.bubble.visible)
	for moment in [34, 35]:
		set_meta("kwenta_debug_launch", {"day": 7, "moment": moment, "skip_tutorials": true, "day4_rain": "shelter"})
		change_scene_to_file("res://scenes/main.tscn")
		await create_timer(0.6).timeout
		var main = current_scene
		assert(main.bubble.visible)
		if moment == 34:
			assert(main.story_after_action == "day_choices")
			assert(main.bubble._text.text.contains("Kumalansing"))
		else:
			assert(main.story_after_action == "finish_day")
			assert(main.story_beats.any(func(beat): return str(beat.get("text", "")).contains("Pinasilong")))
	print("All seven end-of-shift launches and Day 7 reunion/notebook previews passed")
	quit()

