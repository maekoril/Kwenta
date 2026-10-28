extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const CONVERSATION_STREAM_PATH := "res://assets/audio/pixabay/sfx/convo.mp3"

var failures := 0

func _initialize() -> void:
	await _test_only_spoken_bubbles_play_the_conversation_cue()
	if failures > 0:
		push_error("%d dialogue integration assertion(s) failed." % failures)
		quit(1)
	else:
		print("All dialogue integration assertions passed.")
		quit(0)

func _test_only_spoken_bubbles_play_the_conversation_cue() -> void:
	var main_scene := load(MAIN_SCENE_PATH) as PackedScene
	_assert(main_scene != null, "main scene exists")
	if main_scene == null:
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	_assert(main.bubble.has_signal("speech_started"), "the bubble identifies each spoken line")
	if not main.bubble.has_signal("speech_started"):
		main.queue_free()
		return
	var spoken_bubble_events: Array[int] = []
	main.bubble.speech_started.connect(func() -> void: spoken_bubble_events.append(1))
	main.bubble.show_beat("Narrator", "Tahimik ang tindahan.", null, "")
	await _wait_for_bubble_present()
	var player := main.audio.get_node_or_null("CuePlayer") as AudioStreamPlayer
	var expected_stream := load(CONVERSATION_STREAM_PATH) as AudioStream
	_assert(main.audio.current_dialogue.is_empty(), "a live dialogue bubble does not start the looping dialogue channel")
	_assert(spoken_bubble_events.size() == 0, "a narrator caption is not counted as speech")
	_assert(player != null and player.stream != expected_stream, "a narrator caption does not play convo.mp3")
	main.bubble.show_beat("Aling Cora", "May kailangan ka ba ngayon?", null, "")
	await _wait_for_bubble_present()
	_assert(spoken_bubble_events.size() == 1, "the first spoken bubble is counted")
	_assert(player != null and player.stream == expected_stream, "a spoken bubble plays convo.mp3 once")
	main.bubble.show_beat("Tonyo", "Opo, Aling Cora.", null, "")
	await _wait_for_bubble_present()
	_assert(spoken_bubble_events.size() == 2, "each later spoken bubble is counted")
	main.queue_free()

func _wait_for_bubble_present() -> void:
	await process_frame
	await process_frame
	await process_frame

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % message)
