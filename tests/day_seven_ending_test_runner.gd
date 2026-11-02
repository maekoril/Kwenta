extends SceneTree
func _initialize() -> void:
	var config = load("res://data/story/summer_campaign.tres")
	var story = StoryProgression.new(config)
	for rain in ["join", "stay", "shelter", ""]:
		for route in ["ask", "alone", ""]:
			story.choices = {"day4_rain": rain, "day6_help": route}
			var beats: Array = story.get_day_callback_beats(7)
			var lines: Array = beats.map(func(beat): return str(beat.get("text", "")))
			assert(lines.any(func(line): return line.contains("paboritong lugar")))
			var intro := lines.find("Palakpakan natin ang magpe-present ngayon, si Tonyo!")
			var reveal := lines.find("Kaya po, ang pinili kong paboritong lugar sa barangay ay... ang tindahan namin.")
			var art_index := -1
			for index in range(beats.size()):
				if beats[index].get("cutscene", "") == "day7_project": art_index = index
			assert(intro >= 0 and reveal > intro and art_index == reveal + 1)
			assert(lines.back().contains("miniature"))
			assert(lines.any(func(line): return line.contains("nagsalita si Bogs")) == (rain == "shelter"))
			assert(lines.any(func(line): return line.contains("humawak ng tindahan noong fiesta")) == (route == "alone"))
			assert(lines.any(func(line): return line.contains("Tinulungan ka pala")) == (route == "ask"))
			assert(lines.any(func(line): return line.contains("Nabayaran na pala ni Paolo")) == false)
	print("Day 7 rain, fiesta, missing-choice and school callbacks passed")
	quit()

