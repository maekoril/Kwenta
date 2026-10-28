class_name KwentaAudio
extends Node

var cue_streams: Dictionary = {}
var music_streams: Dictionary = {}
var last_played_cue := ""
var current_ambience := ""
var current_music := ""
var current_dialogue := ""
var _last_conversation_semitones := 999

var _cue_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _dialogue_player: AudioStreamPlayer

const DEFAULT_CUE_PATHS := {
	"pickup": "res://assets/audio/pixabay/sfx/pick_up.mp3",
	"correct": "res://assets/audio/pixabay/sfx/correct_item.wav",
	"reject": "res://assets/audio/pixabay/sfx/wrong_item.mp3",
	"sale": "res://assets/audio/pixabay/sfx/cash_register_sale.wav",
	"timeout": "res://assets/audio/pixabay/sfx/patience_warning.mp3",
	"conversation": "res://assets/audio/pixabay/sfx/convo.mp3",
	"fiesta": "res://assets/audio/pixabay/ambience/fiesta_day_bg.mp3",
}

const DEFAULT_MUSIC_PATHS := {
	"normal": "res://assets/audio/pixabay/music/normal_store_days.mp3",
	"rain": "res://assets/audio/pixabay/music/rainy_day.mp3",
	"fiesta": "res://assets/audio/pixabay/music/fiesta_day.mp3",
	"intense": "res://assets/audio/pixabay/music/intense_music.mp3",
}

const CONVERSATION_PENTATONIC := [-8, -5, -3, 0, 2, 4, 7]

func _ready() -> void:
	_ensure_players()

func register_cue(cue_name: String, stream: AudioStream) -> void:
	if cue_name.is_empty() or stream == null:
		return
	cue_streams[cue_name] = stream

func register_default_cues() -> void:
	for cue_name in DEFAULT_CUE_PATHS:
		var stream := load(str(DEFAULT_CUE_PATHS[cue_name])) as AudioStream
		if stream == null:
			continue
		if stream is AudioStreamMP3 and cue_name == "fiesta":
			stream.loop = true
		register_cue(cue_name, stream)

func register_music(track_name: String, stream: AudioStream) -> void:
	if track_name.is_empty() or stream == null:
		return
	if stream is AudioStreamMP3:
		stream.loop = true
	music_streams[track_name] = stream

func register_default_music() -> void:
	for track_name in DEFAULT_MUSIC_PATHS:
		var stream := load(str(DEFAULT_MUSIC_PATHS[track_name])) as AudioStream
		if stream != null:
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
		return true
	current_ambience = cue_name
	_ensure_players()
	if is_inside_tree():
		_ambience_player.stream = stream
		_ambience_player.play()
	return true

func _stop_ambience() -> void:
	current_ambience = ""
	if _ambience_player != null:
		_ambience_player.stop()

func set_music(track_name: String) -> bool:
	if track_name.is_empty():
		_stop_music()
		return true
	var stream := music_streams.get(track_name) as AudioStream
	if stream == null:
		_stop_music()
		return false
	if current_music == track_name:
		return true
	current_music = track_name
	_ensure_players()
	if is_inside_tree():
		_music_player.stream = stream
		_music_player.play()
	return true

func _stop_music() -> void:
	current_music = ""
	if _music_player != null:
		_music_player.stop()

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

func _stop_dialogue() -> void:
	current_dialogue = ""
	if _dialogue_player != null:
		_dialogue_player.stop()

func _ensure_players() -> void:
	if _cue_player == null:
		_cue_player = AudioStreamPlayer.new()
		_cue_player.name = "CuePlayer"
		_cue_player.volume_db = -7.0
		add_child(_cue_player)
	if _ambience_player == null:
		_ambience_player = AudioStreamPlayer.new()
		_ambience_player.name = "AmbiencePlayer"
		_ambience_player.volume_db = -20.0
		add_child(_ambience_player)
	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "MusicPlayer"
		_music_player.volume_db = -16.0
		add_child(_music_player)
	if _dialogue_player == null:
		_dialogue_player = AudioStreamPlayer.new()
		_dialogue_player.name = "DialoguePlayer"
		_dialogue_player.volume_db = -2.0
		add_child(_dialogue_player)
