extends SceneTree

const DIALOGUE_BUBBLE_PATH := "res://scripts/Dialogue_bubble.gd"

var failures := 0

func _initialize() -> void:
	await _test_visible_dialogue_emits_blips_while_typing()
	await _test_scene_exit_finishes_active_conversation()
	await _test_title_card_interrupts_active_conversation()
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
	_assert(bubble.has_signal("conversation_started"), "visible dialogue exposes a conversation-start event")
	_assert(bubble.has_signal("conversation_finished"), "visible dialogue exposes a conversation-finished event")
	if not bubble.has_signal("typing_blip"):
		bubble.queue_free()
		return
	var blip_events: Array[int] = []
	var conversation_started_events: Array[int] = []
	var conversation_finished_events: Array[int] = []
	bubble.typing_blip.connect(func() -> void: blip_events.append(1))
	if bubble.has_signal("conversation_started"):
		bubble.conversation_started.connect(func() -> void: conversation_started_events.append(1))
	if bubble.has_signal("conversation_finished"):
		bubble.conversation_finished.connect(func() -> void: conversation_finished_events.append(1))
	bubble.show_beat("Aling Nena", "Kumusta, may kailangan ka ba ngayon?", null, "")
	await create_timer(0.35).timeout
	_assert(blip_events.size() > 0, "visible dialogue emits at least one blip before the line finishes")
	_assert(conversation_started_events.size() == 1, "visible dialogue starts one loop for the conversation")
	bubble.close()
	_assert(conversation_finished_events.size() == 1, "closing dialogue stops its loop immediately")
	bubble.queue_free()

func _test_scene_exit_finishes_active_conversation() -> void:
	var dialogue_script := load(DIALOGUE_BUBBLE_PATH)
	_assert(dialogue_script != null, "DialogueBubble exists for scene-exit cleanup")
	if dialogue_script == null:
		return
	var bubble: Control = dialogue_script.new()
	root.add_child(bubble)
	bubble.size = Vector2(1920.0, 1080.0)
	await process_frame
	if not bubble.has_signal("conversation_finished"):
		_assert(false, "dialogue exposes a finish event for scene-exit cleanup")
		bubble.queue_free()
		return
	var finished_events: Array[int] = []
	bubble.conversation_finished.connect(func() -> void: finished_events.append(1))
	bubble.show_beat("Aling Cora", "Sandali lang, may sasabihin ako.", null, "")
	bubble.queue_free()
	await process_frame
	_assert(finished_events.size() == 1, "removing active dialogue stops its conversation loop")

func _test_title_card_interrupts_active_conversation() -> void:
	var dialogue_script := load(DIALOGUE_BUBBLE_PATH)
	_assert(dialogue_script != null, "DialogueBubble exists for title-card interruption")
	if dialogue_script == null:
		return
	var bubble: Control = dialogue_script.new()
	root.add_child(bubble)
	bubble.size = Vector2(1920.0, 1080.0)
	await process_frame
	if not bubble.has_signal("conversation_finished"):
		_assert(false, "dialogue exposes a finish event for title-card interruption")
		bubble.queue_free()
		return
	var finished_events: Array[int] = []
	bubble.conversation_finished.connect(func() -> void: finished_events.append(1))
	bubble.show_beat("Aling Cora", "Sandali lang, may sasabihin ako.", null, "")
	bubble.title_card("DAY 2")
	_assert(finished_events.size() == 1, "title cards stop an interrupted conversation loop")
	bubble.queue_free()

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % message)
