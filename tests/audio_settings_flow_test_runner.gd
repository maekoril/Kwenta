extends SceneTree
const AudioSettings = preload("res://scripts/audio_settings.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	assert(change_scene_to_file("res://scenes/main_menu.tscn") == OK)
	await process_frame
	await process_frame
	var menu = current_scene
	menu.find_child("SettingsButton", true, false).pressed.emit()
	await create_timer(0.4).timeout
	var settings = menu.settings_menu
	assert(settings.overlay.visible)
	settings.music_slider.value = 35
	settings.sfx_slider.value = 0
	assert(absf(AudioSettings.get_volume("Music") - 0.35) < 0.02)
	assert(AudioSettings.get_volume("SFX") == 0.0)
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")))
	settings.close()
	menu.find_child("StartButton", true, false).pressed.emit()
	await create_timer(1.9).timeout
	await process_frame
	await process_frame
	var main = current_scene
	assert(main.audio.get_node("MusicPlayer").bus == "Music")
	assert(main.audio.get_node("CuePlayer").bus == "SFX")
	assert(main.audio.get_node("DialoguePlayer").bus == "SFX")
	main.pause_menu.pause()
	main.pause_menu._on_settings_pressed()
	assert(paused and main.pause_menu._settings_menu.overlay.visible)
	main.pause_menu._settings_menu.close()
	assert(paused)
	main.pause_menu.resume()
	print("Audio buses and settings menu flow passed")
	quit()
