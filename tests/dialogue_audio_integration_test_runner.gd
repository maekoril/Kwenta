extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const CONVERSATION_STREAM_PATH := "res://assets/audio/pixabay/sfx/convo.mp3"

var failures := 0

func _initialize() -> void:
	await _test_live_bubble_routes_to_the_dialogue_player()
	if failures > 0:
		push_error("%d dialogue integration assertion(s) failed." % failures)
		quit(1)
	else:
		print("All dialogue integration assertions passed.")
		quit(0)

func _test_live_bubble_routes_to_the_dialogue_player() -> void:
	var main_scene := load(MAIN_SCENE_PATH) as PackedScene
	_assert(main_scene != null, "main scene exists")
	if main_scene == null:
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.show_beat("Aling Cora", "May kailangan ka ba ngayon?", null, "")
	await process_frame
	var player := main.audio.get_node_or_null("CuePlayer") as AudioStreamPlayer
	var expected_stream := load(CONVERSATION_STREAM_PATH) as AudioStream
	_assert(main.audio.current_dialogue.is_empty(), "a live dialogue bubble does not start the looping dialogue channel")
	_assert(player != null and player.stream != null, "the cue player receives the conversation stream")
	_assert(player != null and player.stream == expected_stream, "a live dialogue bubble plays convo.mp3 once")
	main.queue_free()

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % message)
