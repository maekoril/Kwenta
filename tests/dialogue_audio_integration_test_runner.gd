extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"

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
	var player := main.audio.get_node_or_null("DialoguePlayer") as AudioStreamPlayer
	_assert(main.audio.current_dialogue == "conversation", "a live dialogue bubble starts the conversation stream")
	_assert(player != null and player.stream != null, "the dialogue player receives the audible conversation stream")
	main.queue_free()

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % message)
