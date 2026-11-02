extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	main.campaign.day = 1
	main._show_story_beats(main.story.get_day_outro_beats(1), "DAY 1 COMPLETE", "day_choices")
	assert(main.story_beat_index == 0)
	main.bubble.advanced.emit()
	assert(main.story_beat_index == 1)
	main.bubble.advanced.emit()
	assert(main.story_beat_index == 2)
	assert(main.story_events._mode == "outro_visitor")
	await create_timer(0.7).timeout
	assert(main.story_events.find_child("StoryVisitorTutorial", true, false) != null)
	var visitor = main.story_events.find_child("StoryVisitorButton", true, false)
	assert(visitor != null)
	var spotlight = main.story_events.find_child("StoryVisitorTutorial", true, false)
	assert(spotlight.visible and spotlight.spotlight_rect.has_point(visitor.get_global_rect().get_center()))
	assert(visitor.get_global_rect().get_center().x > 700 and visitor.get_global_rect().get_center().x < 1200)
	assert(visitor.get_global_rect().end.y <= 520)
	visitor.pressed.emit()
	assert(main.story_events._visitor_tutorial_seen)
	assert(main.story_events._mode == "")
	assert(main.story_beat_index == 2 and main.bubble.visible)
	main.bubble.advanced.emit()
	assert(main.story_beat_index == 3)
	print("Day 1 story visitor tutorial and dialogue checks passed")
	quit()
