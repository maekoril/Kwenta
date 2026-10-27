extends SceneTree

const AUDIO_SCRIPT_PATH := "res://scripts/kwenta_audio.gd"

var failures := 0

func _initialize() -> void:
	_test_missing_cue_is_safe()
	_test_registered_one_shot_is_reported()
	_test_new_ambience_replaces_the_previous_cue()
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

func _new_audio() -> Variant:
	var audio_script := load(AUDIO_SCRIPT_PATH)
	_assert(audio_script != null, "KwentaAudio exists")
	return audio_script.new() if audio_script != null else null

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % message)
