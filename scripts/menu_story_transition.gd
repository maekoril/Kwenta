extends CanvasLayer

const GAME_SCENE := "res://scenes/main.tscn"
const TRANSITION_META := "kwenta_menu_story_transition"

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS

func begin() -> void:
	var curtain := ColorRect.new()
	curtain.name = "TransitionCurtain"
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain.color = Color("21130c")
	curtain.modulate.a = 0.0
	curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(curtain)
	var fade_out := create_tween()
	fade_out.tween_property(curtain, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	await fade_out.finished
	get_tree().set_meta(TRANSITION_META, true)
	var error := get_tree().change_scene_to_file(GAME_SCENE)
	if error != OK:
		get_tree().remove_meta(TRANSITION_META)
		push_error("Unable to start the game: %s" % error_string(error))
		var recover := create_tween()
		recover.tween_property(curtain, "modulate:a", 0.0, 0.25)
		await recover.finished
		queue_free()
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var fade_in := create_tween()
	fade_in.tween_interval(0.15)
	fade_in.tween_property(curtain, "modulate:a", 0.0, 0.65).set_trans(Tween.TRANS_SINE)
	await fade_in.finished
	get_tree().remove_meta(TRANSITION_META)
	var game := get_tree().current_scene
	if is_instance_valid(game) and game.has_method("_finish_menu_transition"):
		game._finish_menu_transition()
	queue_free()
