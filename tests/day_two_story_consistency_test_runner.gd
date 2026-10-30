extends SceneTree
func _initialize() -> void:
	var story = StoryProgression.new(load("res://data/story/summer_campaign.tres"))
	var intro = story.get_day_intro_beats(2)
	assert(intro[0].speaker == "Narrator" and intro[1].text.contains("dali"))
	assert(intro[2].text.contains("bayad") and intro[3].text.contains("kahon"))
	assert(story.get_day_choices(2).is_empty())
	assert(not story.record_choice("day2_overpayment", "keep"))
	var events = story.get_day_shift_events(2)
	assert(events.size() == 2 and events[1].type == "scene")
	assert(events[1].beats.size() >= 3)
	story.choices["day2_berting_money"] = "seen"
	assert(story.get_day_choices(2).size() == 1)
	assert(story.record_choice("day2_overpayment", "keep"))
	assert(story.get_choice_cash_delta(story.get_day_choices(2)[0], "keep") == 50)
	for result in ["perfect", "mistakes", "none"]:
		story.choices["day2_sukli_result"] = result
		var beats = story.get_day_outro_beats(2)
		assert(beats.size() == 3)
		assert(not str(beats[1].text).contains("Nena"))
	print("Day 2 story choice gating and sukli reflections passed")
	quit()
