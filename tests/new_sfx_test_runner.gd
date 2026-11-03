extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var audio = preload("res://scripts/kwenta_audio.gd").new()
	root.add_child(audio)
	audio.register_default_cues()
	for cue in ["explosion", "fireworks", "coin_pickup", "achievement_unlocked", "level_complete", "game_over", "button_click"]:
		assert(audio.has_cue(cue), "Missing cue: " + cue)
	assert(audio.cue_streams["explosion"] is AudioStreamWAV)
	audio.register_default_music()
	assert(audio.set_music("intense"))
	assert(is_equal_approx(audio._music_player.volume_db, -8.0))
	assert(audio.play_persistent_cue("explosion"))
	var explosion_player := root.get_node("PersistentCuePlayer") as AudioStreamPlayer
	assert(explosion_player.bus == "SFX" and is_equal_approx(explosion_player.volume_db, 0.0))
	explosion_player.queue_free()
	audio.play_fireworks()
	var player = audio._fireworks_player
	if player.stream.loop_end <= player.stream.loop_begin:
		push_error("Fireworks loop range is empty")
		quit(1)
		return
	assert(player.playing and player.bus == "SFX")
	assert(is_equal_approx(audio._fireworks_timer.wait_time, 10.0))
	audio.play_fireworks()
	assert(audio._fireworks_player == player)
	audio.stop_fireworks()
	assert(not player.playing)
	audio.play_ui_cue("coin_pickup")
	var ui_player = audio._ui_cue_player
	audio.play_ui_cue("coin_pickup")
	assert(audio._ui_cue_player == ui_player and ui_player.bus == "SFX")
	audio.queue_free()
	print("New SFX assets, fireworks lifecycle, and repeated UI cues passed")
	quit()
