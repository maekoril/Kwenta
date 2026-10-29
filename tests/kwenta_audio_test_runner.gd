extends SceneTree

const AUDIO_SCRIPT_PATH := "res://scripts/kwenta_audio.gd"

var failures := 0

func _initialize() -> void:
	_test_missing_cue_is_safe()
	_test_registered_one_shot_is_reported()
	await _test_conversation_cue_uses_pentatonic_pitch_variation()
	_test_new_ambience_replaces_the_previous_cue()
	_test_missing_ambience_stops_the_previous_loop()
	_test_new_music_replaces_the_previous_track()
	_test_dialogue_loop_stops_explicitly()
	_test_dialogue_loop_asset_has_audible_phrase_length()
	_test_sale_clip_is_short_and_immediate()
	_test_default_cues_resolve()
	if failures > 0:
		push_error("%d audio assertion(s) failed." % failures)
		quit(1)
	else:
		print("All audio assertions passed.")
		quit(0)

func _test_missing_cue_is_safe() -> void:
	var audio: Variant = _new_audio()
	if audio == null:
		return
	_assert(not audio.play_cue("missing"), "an unregistered cue does nothing safely")
	audio.free()

func _test_registered_one_shot_is_reported() -> void:
	var audio: Variant = _new_audio()
	if audio == null:
		return
	audio.register_cue("correct", AudioStreamWAV.new())
	_assert(audio.play_cue("correct"), "a registered one-shot cue is accepted")
	_assert(audio.last_played_cue == "correct", "playing a cue records the semantic cue name")
	audio.free()

func _test_conversation_cue_uses_pentatonic_pitch_variation() -> void:
	var audio: Variant = _new_audio()
	if audio == null:
		return
	root.add_child(audio)
	await process_frame
	audio.register_cue("conversation", AudioStreamWAV.new())
	var allowed_pitch_scales := [0.6299605, 0.7491535, 0.8408964, 1.0, 1.1224620, 1.2599210, 1.4983071]
	var observed_pitch_scales: Array[float] = []
	for _index in 64:
		audio.play_cue("conversation")
		var player := audio.get_node_or_null("CuePlayer") as AudioStreamPlayer
		if player != null:
			observed_pitch_scales.append(player.pitch_scale)
	_assert(not observed_pitch_scales.is_empty(), "conversation playback exposes its cue player")
	for pitch_scale in observed_pitch_scales:
		_assert(_is_allowed_pitch(float(pitch_scale), allowed_pitch_scales), "conversation pitch stays on the pentatonic scale")
	_assert(_has_multiple_values(observed_pitch_scales), "conversation pitch varies between spoken bubbles")
	_assert(not _has_repeated_neighbors(observed_pitch_scales), "conversation pitch never repeats on consecutive spoken bubbles")
	audio.queue_free()
	await process_frame

func _is_allowed_pitch(pitch_scale: float, allowed_pitch_scales: Array) -> bool:
	for allowed_scale in allowed_pitch_scales:
		if is_equal_approx(pitch_scale, float(allowed_scale)):
			return true
	return false

func _has_multiple_values(values: Array[float]) -> bool:
	if values.is_empty():
		return false
	var first_value := values[0]
	for value in values:
		if not is_equal_approx(value, first_value):
			return true
	return false

func _has_repeated_neighbors(values: Array[float]) -> bool:
	for index in range(1, values.size()):
		if is_equal_approx(values[index], values[index - 1]):
			return true
	return false

func _test_new_ambience_replaces_the_previous_cue() -> void:
	var audio: Variant = _new_audio()
	if audio == null:
		return
	audio.register_cue("rain", AudioStreamWAV.new())
	audio.register_cue("fiesta", AudioStreamWAV.new())
	_assert(audio.set_ambience("rain"), "registered rain ambience is accepted")
	_assert(audio.current_ambience == "rain", "rain becomes the active ambience")
	_assert(audio.set_ambience("fiesta"), "registered fiesta ambience is accepted")
	_assert(audio.current_ambience == "fiesta", "fiesta replaces rain as the single active ambience")
	audio.free()

func _test_missing_ambience_stops_the_previous_loop() -> void:
	var audio: Variant = _new_audio()
	if audio == null:
		return
	audio.register_cue("rain", AudioStreamWAV.new())
	_assert(audio.set_ambience("rain"), "registered ambience starts")
	_assert(not audio.set_ambience("missing"), "missing ambience is rejected")
	_assert(audio.current_ambience.is_empty(), "missing ambience clears the previous loop safely")
	audio.free()

func _test_new_music_replaces_the_previous_track() -> void:
	var audio: Variant = _new_audio()
	if audio == null:
		return
	_assert(audio.has_method("register_music"), "KwentaAudio can register background music")
	_assert(audio.has_method("set_music"), "KwentaAudio can select one background track")
	if not audio.has_method("register_music") or not audio.has_method("set_music"):
		audio.free()
		return
	audio.register_music("normal", AudioStreamWAV.new())
	audio.register_music("rain", AudioStreamWAV.new())
	_assert(audio.set_music("normal"), "normal background music is accepted")
	_assert(audio.current_music == "normal", "normal music becomes active")
	_assert(audio.set_music("rain"), "rain background music is accepted")
	_assert(audio.current_music == "rain", "rain music replaces the normal track")
	audio.free()

func _test_dialogue_loop_stops_explicitly() -> void:
	var audio: Variant = _new_audio()
	if audio == null:
		return
	_assert(audio.has_method("set_dialogue"), "KwentaAudio can start a dialogue loop")
	if not audio.has_method("set_dialogue"):
		audio.free()
		return
	audio.register_cue("conversation", AudioStreamWAV.new())
	_assert(audio.set_dialogue("conversation"), "a registered dialogue cue starts looping")
	_assert(audio.current_dialogue == "conversation", "dialogue stays active after text typing ends")
	_assert(audio.set_dialogue(""), "empty dialogue cue stops the loop")
	_assert(audio.current_dialogue.is_empty(), "dialogue clears only when explicitly stopped")
	audio.free()

func _test_dialogue_loop_asset_has_audible_phrase_length() -> void:
	var stream := load("res://assets/audio/pixabay/sfx/muffled_dialogue_blip.wav") as AudioStream
	_assert(stream != null, "dialogue loop asset is available")
	if stream != null:
		_assert(stream.get_length() >= 1.5, "dialogue loop has a recognizable talking phrase instead of a single tiny blip")

func _test_sale_clip_is_short_and_immediate() -> void:
	var stream := load("res://assets/audio/pixabay/sfx/cash_register_sale.wav") as AudioStream
	_assert(stream != null, "trimmed sale clip is available")
	if stream != null:
		_assert(stream.get_length() <= 1.0, "trimmed sale clip does not retain the long delayed source")

func _test_default_cues_resolve() -> void:
	var audio: Variant = _new_audio()
	if audio == null:
		return
	_assert(audio.has_method("register_default_cues"), "KwentaAudio can register the shipped cue set")
	if not audio.has_method("register_default_cues"):
		audio.free()
		return
	audio.register_default_cues()
	for cue_name in ["pickup", "correct", "reject", "sale", "timeout", "conversation"]:
		_assert(audio.has_cue(cue_name), "default cue resolves: %s" % cue_name)
	audio.register_default_music()
	for track_name in ["normal", "rain", "intense"]:
		_assert(audio.has_music(track_name), "default music resolves: %s" % track_name)
	audio.free()

func _new_audio() -> Variant:
	var audio_script := load(AUDIO_SCRIPT_PATH)
	_assert(audio_script != null, "KwentaAudio exists")
	return audio_script.new() if audio_script != null else null

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % message)
