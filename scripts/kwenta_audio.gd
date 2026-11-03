class_name KwentaAudio
extends Node

var cue_streams: Dictionary = {}
var music_streams: Dictionary = {}
var last_played_cue := ""
var current_ambience := ""
var current_music := ""
var current_dialogue := ""
var current_random_ambience := ""
var random_ambience_cooldown_seconds := 0.0
var _last_conversation_semitones := 999
var _random_ambience_has_played := false

var _cue_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _dialogue_player: AudioStreamPlayer
var _alert_player: AudioStreamPlayer
var _ambient_cue_player: AudioStreamPlayer
var _random_ambience_timer: Timer
var _alert_wanted := false

const DEFAULT_CUE_PATHS := {
	"pickup": "res://assets/audio/pixabay/sfx/pick_up.mp3",
	"correct": "res://assets/audio/pixabay/sfx/correct_item.wav",
	"reject": "res://assets/audio/pixabay/sfx/wrong_item.mp3",
	"sale": "res://assets/audio/pixabay/sfx/cash_register_sale.wav",
	"timeout": "res://assets/audio/pixabay/sfx/patience_warning.mp3",
	"conversation": "res://assets/audio/pixabay/sfx/convo.mp3",
	"menu_start": "res://assets/audio/pixabay/sfx/continue_or_start_game.wav",
	"rain": "res://assets/audio/pixabay/ambience/rain.ogg",
	"normal_day": "res://assets/audio/pixabay/ambience/normal_day.ogg",
	"angry": "res://assets/audio/pixabay/sfx/patience_warning.mp3", 
}

const DEFAULT_MUSIC_PATHS := {
	"normal": "res://assets/audio/pixabay/music/normal_store_days.mp3",
	"rain": "res://assets/audio/pixabay/music/rainy_day.mp3",
	"intense": "res://assets/audio/pixabay/music/intense_music.mp3",
	"main_menu": "res://assets/audio/pixabay/music/calm_nature_ambience.mp3",
}

const MUSIC_VOLUME_DB := {
	"main_menu": -10.0,
}

const CONVERSATION_PENTATONIC := [-8, -5, -3, 0, 2, 4, 7]

func _ready() -> void:
	_ensure_players()

func _exit_tree() -> void:
	# Release active playback when the owning scene leaves, including at shutdown.
	for player in [_cue_player, _ambience_player, _music_player, _dialogue_player, _alert_player, _ambient_cue_player]:
		if is_instance_valid(player):
			player.stop()

func register_cue(cue_name: String, stream: AudioStream) -> void:
	if cue_name.is_empty() or stream == null:
		return
	cue_streams[cue_name] = stream

func register_default_cues() -> void:
	for cue_name in DEFAULT_CUE_PATHS:
		var resource_path := str(DEFAULT_CUE_PATHS[cue_name])
		var stream := load(resource_path) as AudioStream
		if stream == null:
			push_error("KwentaAudio: could not load cue '%s' at %s as an AudioStream." % [cue_name, resource_path])
			continue
		register_cue(cue_name, stream)

func register_music(track_name: String, stream: AudioStream) -> void:
	if track_name.is_empty() or stream == null:
		return
	_set_stream_looping(stream, true)
	music_streams[track_name] = stream

func register_default_music() -> void:
	for track_name in DEFAULT_MUSIC_PATHS:
		var resource_path := str(DEFAULT_MUSIC_PATHS[track_name])
		var stream := load(resource_path) as AudioStream
		if stream == null:
			push_error("KwentaAudio: could not load music '%s' at %s as an AudioStream." % [track_name, resource_path])
			continue
		register_music(track_name, stream)

func has_cue(cue_name: String) -> bool:
	return cue_streams.get(cue_name) is AudioStream

func has_music(track_name: String) -> bool:
	return music_streams.get(track_name) is AudioStream

func play_cue(cue_name: String) -> bool:
	var stream := cue_streams.get(cue_name) as AudioStream
	if stream == null:
		return false
	last_played_cue = cue_name
	_ensure_players()
	if is_inside_tree():
		_cue_player.stream = stream
		_cue_player.pitch_scale = _conversation_pitch_scale() if cue_name == "conversation" else 1.0
		_cue_player.play()
	return true

func _conversation_pitch_scale() -> float:
	var available_semitones := CONVERSATION_PENTATONIC.duplicate()
	available_semitones.erase(_last_conversation_semitones)
	var semitones := int(available_semitones.pick_random())
	_last_conversation_semitones = semitones
	return pow(2.0, semitones / 12.0)

func set_ambience(cue_name: String) -> bool:
	if cue_name.is_empty():
		_stop_ambience()
		return true
	var stream := cue_streams.get(cue_name) as AudioStream
	if stream == null:
		_stop_ambience()
		return false
	if current_ambience == cue_name:
		_queue_ambience_playback(cue_name)
		return true
	current_ambience = cue_name
	_set_stream_looping(stream, true)
	_ensure_players()
	_ambience_player.stream = stream
	_queue_ambience_playback(cue_name)
	return true

func _queue_ambience_playback(cue_name: String) -> void:
	if is_inside_tree():
		call_deferred("_play_selected_ambience", cue_name)

func _play_selected_ambience(cue_name: String) -> void:
	# A queued request may outlive the scene that scheduled it.
	if not is_inside_tree() or is_queued_for_deletion() or not is_instance_valid(_ambience_player) or not _ambience_player.is_inside_tree() or _ambience_player.is_queued_for_deletion():
		return
	if current_ambience == cue_name and _ambience_player != null:
		_ambience_player.play()

func _stop_ambience() -> void:
	current_ambience = ""
	if _ambience_player != null:
		_ambience_player.stop()

func set_random_ambience(cue_name: String, cooldown_seconds: float = 40.0) -> bool:
	if cue_name.is_empty():
		_stop_random_ambience()
		return true
	var stream := cue_streams.get(cue_name) as AudioStream
	if stream == null:
		_stop_random_ambience()
		return false
	current_random_ambience = cue_name
	random_ambience_cooldown_seconds = maxf(cooldown_seconds, 0.0)
	_random_ambience_has_played = false
	_set_stream_looping(stream, false)
	_ensure_players()
	_schedule_random_ambience()
	return true

func _stop_random_ambience() -> void:
	current_random_ambience = ""
	random_ambience_cooldown_seconds = 0.0
	_random_ambience_has_played = false
	if _random_ambience_timer != null:
		_random_ambience_timer.stop()
	if _ambient_cue_player != null:
		_ambient_cue_player.stop()

func _schedule_random_ambience() -> void:
	if current_random_ambience.is_empty() or _random_ambience_timer == null or not is_inside_tree():
		return
	# Let players hear the first normal-day cue during a short shift. Every later
	# cue uses the requested 40–80 second cooldown after the previous one ends.
	if _random_ambience_has_played:
		_random_ambience_timer.wait_time = maxf(0.1, random_ambience_cooldown_seconds + randf() * random_ambience_cooldown_seconds)
	else:
		_random_ambience_timer.wait_time = randf_range(2.0, 8.0)
	_random_ambience_timer.start()

func _on_random_ambience_timeout() -> void:
	var stream := cue_streams.get(current_random_ambience) as AudioStream
	if stream == null or _ambient_cue_player == null:
		_schedule_random_ambience()
		return
	_ambient_cue_player.stream = stream
	_random_ambience_has_played = true
	_ambient_cue_player.play()

func _on_random_ambience_finished() -> void:
	_schedule_random_ambience()

func set_music(track_name: String) -> bool:
	if track_name.is_empty():
		_stop_music()
		return true
	var stream := music_streams.get(track_name) as AudioStream
	if stream == null:
		_stop_music()
		return false
	if current_music == track_name:
		_queue_music_playback(track_name)
		return true
	current_music = track_name
	_ensure_players()
	_music_player.volume_db = float(MUSIC_VOLUME_DB.get(track_name, 0.0))
	_music_player.stream = stream
	_queue_music_playback(track_name)
	return true

func _queue_music_playback(track_name: String) -> void:
	if is_inside_tree():
		call_deferred("_play_selected_music", track_name)

func _play_selected_music(track_name: String) -> void:
	# A queued request may outlive the scene that scheduled it.
	if not is_inside_tree() or is_queued_for_deletion() or not is_instance_valid(_music_player) or not _music_player.is_inside_tree() or _music_player.is_queued_for_deletion():
		return
	if current_music == track_name and _music_player != null:
		_music_player.play()

func _stop_music() -> void:
	current_music = ""
	if _music_player != null:
		_music_player.stop()

func _set_stream_looping(stream: AudioStream, should_loop: bool) -> void:
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if should_loop else AudioStreamWAV.LOOP_DISABLED
	elif stream is AudioStreamMP3:
		stream.loop = should_loop
	elif stream is AudioStreamOggVorbis:
		stream.loop = should_loop

func play_persistent_cue(cue_name: String) -> bool:
	var stream := cue_streams.get(cue_name) as AudioStream
	if stream == null or get_tree() == null:
		return false
	last_played_cue = cue_name
	var player := AudioStreamPlayer.new()
	player.name = "PersistentCuePlayer"
	player.stream = stream
	player.bus = "SFX"
	player.volume_db = -7.0
	get_tree().root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return true

func set_dialogue(cue_name: String) -> bool:
	if cue_name.is_empty():
		_stop_dialogue()
		return true
	var stream := cue_streams.get(cue_name) as AudioStream
	if stream == null:
		_stop_dialogue()
		return false
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamMP3:
		stream.loop = true
	_ensure_players()
	current_dialogue = cue_name
	if is_inside_tree():
		if _dialogue_player.stream != stream:
			_dialogue_player.stream = stream
		if not _dialogue_player.playing:
			_dialogue_player.play()
	return true


func start_alert(cue_name: String = "angry") -> void:
	var stream := cue_streams.get(cue_name) as AudioStream
	if stream == null:
		return
	_ensure_players()
	_alert_wanted = true
	if is_inside_tree() and not _alert_player.playing:
		_alert_player.stream = stream
		_alert_player.play()

func stop_alert() -> void:
	_alert_wanted = false
	if _alert_player != null:
		_alert_player.stop()

func _on_alert_finished() -> void:
	if _alert_wanted:
		_alert_player.play()



func _stop_dialogue() -> void:
	current_dialogue = ""
	if _dialogue_player != null:
		_dialogue_player.stop()

func _ensure_players() -> void:
	if _cue_player == null:
		_cue_player = AudioStreamPlayer.new()
		_cue_player.name = "CuePlayer"
		_cue_player.bus = "SFX"
		_cue_player.volume_db = -7.0
		add_child(_cue_player)
	if _ambience_player == null:
		_ambience_player = AudioStreamPlayer.new()
		_ambience_player.name = "AmbiencePlayer"
		_ambience_player.bus = "Ambience"
		_ambience_player.volume_db = -20.0
		_ambience_player.process_mode = Node.PROCESS_MODE_ALWAYS # <-- IDAGDAG ITO
		add_child(_ambience_player)
	if _ambient_cue_player == null:
		_ambient_cue_player = AudioStreamPlayer.new()
		_ambient_cue_player.name = "AmbientCuePlayer"
		_ambient_cue_player.bus = "Ambience"
		_ambient_cue_player.volume_db = -20.0
		_ambient_cue_player.process_mode = Node.PROCESS_MODE_ALWAYS
		_ambient_cue_player.finished.connect(_on_random_ambience_finished)
		add_child(_ambient_cue_player)
	if _random_ambience_timer == null:
		_random_ambience_timer = Timer.new()
		_random_ambience_timer.name = "RandomAmbienceTimer"
		_random_ambience_timer.one_shot = true
		_random_ambience_timer.process_mode = Node.PROCESS_MODE_ALWAYS
		_random_ambience_timer.timeout.connect(_on_random_ambience_timeout)
		add_child(_random_ambience_timer)
	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "MusicPlayer"
		_music_player.bus = "Music"
		_music_player.volume_db = 0.0
		_music_player.process_mode = Node.PROCESS_MODE_ALWAYS # <-- IDAGDAG ITO
		add_child(_music_player)
	if _dialogue_player == null:
		_dialogue_player = AudioStreamPlayer.new()
		_dialogue_player.name = "DialoguePlayer"
		_dialogue_player.bus = "SFX"
		_dialogue_player.volume_db = -2.0
		add_child(_dialogue_player)
	if _alert_player == null:
		_alert_player = AudioStreamPlayer.new()
		_alert_player.name = "AlertPlayer"
		_alert_player.bus = "SFX"
		_alert_player.volume_db = -7.0
		_alert_player.finished.connect(_on_alert_finished)
		add_child(_alert_player)
