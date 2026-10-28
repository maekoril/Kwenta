extends SceneTree

const DIALOGUE_BUBBLE_PATH := "res://scripts/Dialogue_bubble.gd"

var failures := 0

func _initialize() -> void:
	await _test_visible_dialogue_emits_blips_while_typing()
	if failures > 0:
		push_error("%d dialogue-audio assertion(s) failed." % failures)
		quit(1)
	else:
		print("All dialogue-audio assertions passed.")
		quit(0)

func _test_visible_dialogue_emits_blips_while_typing() -> void:
	var dialogue_script := load(DIALOGUE_BUBBLE_PATH)
	_assert(dialogue_script != null, "DialogueBubble exists")
	if dialogue_script == null:
		return
	var bubble: Control = dialogue_script.new()
	root.add_child(bubble)
	bubble.size = Vector2(1920.0, 1080.0)
	await process_frame
	_assert(bubble.has_signal("typing_blip"), "visible dialogue exposes a typing-blip event")
	if not bubble.has_signal("typing_blip"):
		bubble.queue_free()
		return
	var blip_events: Array[int] = []
	bubble.typing_blip.connect(func() -> void: blip_events.append(1))
	bubble.show_beat("Aling Nena", "Kumusta, may kailangan ka ba ngayon?", null, "")
	await create_timer(0.35).timeout
	_assert(blip_events.size() > 0, "visible dialogue emits at least one blip before the line finishes")
	bubble.queue_free()

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % message)
