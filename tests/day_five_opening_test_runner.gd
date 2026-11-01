extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	main.campaign.day = 5
	for paolo in ["credit", "free", "no"]:
		main.story.choices["day3_candy"] = paolo
		var beats: Array = main.story.get_day_intro_beats(5)
		assert(beats[0].get("cutscene") == "day5_wakes")
		assert(beats.any(func(beat): return beat.get("cutscene") == "day5_phone"))
		assert(beats.any(func(beat): return str(beat.get("text", "")).contains("Alfa-Save")))
		assert(beats.any(func(beat): return beat.get("cutscene") == "day5_to_store"))
		assert(beats.any(func(beat): return str(beat.get("text", "")).contains("bawal utang")))
		assert(beats.any(func(beat): return str(beat.get("text", "")).contains("₱320")))
		assert(beats.any(func(beat): return str(beat.get("text", "")).contains("Kinulang si Paolo")) == (paolo == "credit"))
		var index := 0
		for i in range(beats.size()):
			if beats[i].get("show_prop") == "utang_ledger": index = i; break
		main.story_beats = beats
		main.story_beat_index = index
		main._show_current_story_beat()
		assert(main.utang_ledger.visible)
		main.story_beat_index += 1
		main._show_current_story_beat()
		assert(main.utang_ledger.visible)
		assert(main.utang_ledger.show_paolo == (paolo == "credit"))
		main.story_beat_index += 1
		main._show_current_story_beat()
		assert(not main.utang_ledger.visible)
		main.story_beat_index = 0
		main._show_current_story_beat()
		assert(main.story_illustration.visible and main.story_illustration.texture != null)
		for i in range(beats.size()):
			if beats[i].get("cutscene") == "day5_phone":
				main.story_beat_index = i
				main._show_current_story_beat()
				assert(main.story_illustration.texture.resource_path.ends_with("day5_tonyo_phone_v2.png"))
				break
		for i in range(beats.size()):
			if beats[i].get("cutscene") == "day5_to_store":
				main.story_beat_index = i
				main._show_current_story_beat()
				await create_timer(1.0).timeout
				assert(not main.story_illustration.visible and not main.prologue_fade.visible)
				break
	var day_four: Array = main.story.get_day_outro_beats(4)
	for i in range(day_four.size()):
		if day_four[i].get("cutscene") == "day4_alfa_save":
			main.story_beats = day_four
			main.story_beat_index = i
			main._show_current_story_beat()
			assert(main.story_illustration.visible)
			assert(main.story_illustration.texture.resource_path.ends_with("day4_alfa_save_corner.png"))
			main.story_beat_index = day_four.size() - 1
			main._show_current_story_beat()
			assert(not main.story_illustration.visible)
			break
	main.queue_free()
	await process_frame
	print("Day 5 pre-shift call and notebook branches passed")
	quit()
