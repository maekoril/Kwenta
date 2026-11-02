extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const CONVERSATION_STREAM_PATH := "res://assets/audio/pixabay/sfx/convo.mp3"

var failures := 0

func _initialize() -> void:
	await _test_only_spoken_bubbles_play_the_conversation_cue()
	await _test_hud_recenters_after_viewport_resize()
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
	_assert(main.prologue_background.get_anchor(SIDE_LEFT) == 0.0 and main.prologue_background.get_anchor(SIDE_RIGHT) == 1.0, "the opening-scene background fills the available viewport width")
	_assert(main.prologue_background.get_anchor(SIDE_TOP) == 0.0 and main.prologue_background.get_anchor(SIDE_BOTTOM) == 1.0, "the opening-scene background fills the available viewport height")
	_assert(main.opening_blocker.get_anchor(SIDE_LEFT) == 0.0 and main.opening_blocker.get_anchor(SIDE_RIGHT) == 1.0 and main.opening_blocker.get_anchor(SIDE_TOP) == 0.0 and main.opening_blocker.get_anchor(SIDE_BOTTOM) == 1.0, "opening dark overlay fills the complete viewport")
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

func _test_hud_recenters_after_viewport_resize() -> void:
	var main_scene := load(MAIN_SCENE_PATH) as PackedScene
	_assert(main_scene != null, "main scene exists for HUD centering")
	if main_scene == null:
		return
	var viewport_host := Control.new()
	viewport_host.size = Vector2(2400.0, 1080.0)
	root.add_child(viewport_host)
	var main := main_scene.instantiate()
	viewport_host.add_child(main)
	await process_frame
	var hud := main.get_node_or_null("GameplayHUDOption5") as Control
	_assert(hud != null, "gameplay HUD exists for viewport centering")
	if hud == null:
		viewport_host.queue_free()
		return
	viewport_host.size = Vector2(2700.0, 1080.0)
	await process_frame
	var left_margin: float = hud.position.x
	var right_margin: float = main.size.x - (hud.position.x + hud.size.x)
	_assert(is_equal_approx(left_margin, right_margin), "HUD keeps equal left and right margins after a wide viewport resize")
	var pause_button := main.pause_menu.get("_button") as Control
	_assert(pause_button != null and is_equal_approx(pause_button.position.x, 1795.0 + left_margin), "pause control stays aligned with the re-centered HUD instead of overlapping the suki meter")
	main._show_pre_shift_briefing()
	await process_frame
	await process_frame
	await process_frame
	var briefing_card := main.briefing_card.get("_card") as Control
	_assert(briefing_card != null and is_equal_approx(briefing_card.get_global_rect().get_center().x, main.size.x * 0.5), "briefing panel stays centered after a wide viewport resize")
	viewport_host.size = Vector2(945.0, 430.0)
	await process_frame
	await process_frame
	await process_frame
	var phone_bounds := Rect2(Vector2.ZERO, main.size)
	_assert(briefing_card != null and phone_bounds.encloses(briefing_card.get_global_rect()), "briefing panel stays fully visible on a phone-sized viewport")
	viewport_host.queue_free()

func _wait_for_bubble_present() -> void:
	await process_frame
	await process_frame
	await process_frame

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % message)
