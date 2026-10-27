class_name KwentaAudio
extends Node

var cue_streams: Dictionary = {}
var last_played_cue := ""
var current_ambience := ""

var _cue_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer

const DEFAULT_CUE_PATHS := {
	"pickup": "res://assets/audio/sfx/pickup.mp3",
	"correct": "res://assets/audio/sfx/correct.wav",
	"reject": "res://assets/audio/sfx/reject.mp3",
	"sale": "res://assets/audio/sfx/sale.wav",
	"timeout": "res://assets/audio/sfx/timeout.mp3",
	"rain": "res://assets/audio/ambience/rain.ogg",
	"fiesta": "res://assets/audio/ambience/fiesta.ogg",
}

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
		if stream is AudioStreamOggVorbis and (cue_name == "rain" or cue_name == "fiesta"):
			stream.loop = true
		register_cue(cue_name, stream)

func has_cue(cue_name: String) -> bool:
	return cue_streams.get(cue_name) is AudioStream

func play_cue(cue_name: String) -> bool:
	var stream := cue_streams.get(cue_name) as AudioStream
	if stream == null:
		return false
	last_played_cue = cue_name
	_ensure_players()
	if is_inside_tree():
		_cue_player.stream = stream
		_cue_player.play()
	return true

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
