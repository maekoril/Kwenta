class_name AudioSettings
extends RefCounted

const FILE_PATH := "user://audio_settings.cfg"
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

static func initialize() -> void:
	for bus_name in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	var config := ConfigFile.new()
	if config.load(FILE_PATH) == OK:
		set_volume(MUSIC_BUS, float(config.get_value("audio", "music", 1.0)))
		set_volume(SFX_BUS, float(config.get_value("audio", "sfx", 1.0)))

static func set_volume(bus_name: String, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var volume := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(index, volume <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))

static func get_volume(bus_name: String) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0 or AudioServer.is_bus_mute(index):
		return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(index)), 0.0, 1.0)

static func save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", get_volume(MUSIC_BUS))
	config.set_value("audio", "sfx", get_volume(SFX_BUS))
	var error := config.save(FILE_PATH)
	if error != OK:
		push_warning("Could not save audio settings: %s" % error_string(error))
