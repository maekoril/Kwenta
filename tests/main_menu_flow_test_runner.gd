extends SceneTree
const SAVE = preload("res://scripts/campaign_save.gd")
const TEST_PATH := "res://tests/main_menu_flow_save_temp.json"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	SAVE.save_path = TEST_PATH
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	assert(change_scene_to_file("res://scenes/main_menu.tscn") == OK)
	await process_frame
	await process_frame
	var menu = current_scene
	assert(menu != null and menu.find_child("NotebookDesk", true, false).texture != null)
	assert(menu.menu_audio.current_music == "main_menu")
	var music_player := menu.menu_audio.get_node_or_null("MusicPlayer") as AudioStreamPlayer
	assert(music_player != null and music_player.stream.resource_path == "res://assets/audio/pixabay/music/calm_nature_ambience.mp3")
	assert(music_player != null and is_equal_approx(music_player.volume_db, -10.0))
	assert(music_player != null and music_player.playing)
	assert(menu.menu_audio.has_cue("menu_start"))
	var play = menu.find_child("StartButton", true, false)
	assert(play != null and play.text == "NEW GAME")
	play.pressed.emit()
	assert(menu._selection_in_progress and menu == current_scene)
	assert(play.get_node("BrushStroke") != null)
	await create_timer(1.9).timeout
	await process_frame
	await process_frame
	var main = current_scene
	assert(main != null and main.get_script().resource_path == "res://scripts/main.gd")
	var game_music := main.audio.get_node_or_null("MusicPlayer") as AudioStreamPlayer
	assert(game_music != null and game_music.playing)
	assert(main.audio.current_ambience.is_empty(), "normal-day ambience stays silent during the prologue")
	main._start_opening_ambience()
	assert(main.audio.current_ambience == "normal_day", "normal-day ambience starts only when the store opens")
	var opening_normal_ambience := main.audio.get_node_or_null("AmbiencePlayer") as AudioStreamPlayer
	assert(opening_normal_ambience != null and opening_normal_ambience.stream is AudioStreamOggVorbis and opening_normal_ambience.stream.loop, "normal-day ambience loops after the store opens")
	main.apply_environment(4)
	await process_frame
	var rain_ambience := main.audio.get_node_or_null("AmbiencePlayer") as AudioStreamPlayer
	assert(rain_ambience != null and rain_ambience.playing)
	main.campaign.day = 4
	main._start_opening_ambience()
	assert(main.audio.current_ambience == "rain" and rain_ambience.playing, "Day 4 opening/tutorial flow keeps the rain ambience looping")
	main.campaign.day = 1
	main.apply_environment(1)
	main._start_opening_ambience()
	await process_frame
	var normal_ambience := main.audio.get_node_or_null("AmbiencePlayer") as AudioStreamPlayer
	assert(normal_ambience != null and normal_ambience.playing and normal_ambience.stream is AudioStreamOggVorbis and normal_ambience.stream.loop)
	assert(main.prologue_background.visible)
	assert(main.bubble.visible and main.story_after_action == "prologue_end")
	var pause = main.pause_menu
	pause.pause()
	assert(paused)
	pause._on_main_menu_pressed()
	assert(pause._menu_confirmation.visible)
	pause._menu_confirmation.canceled.emit()
	assert(paused and current_scene == main)
	pause._confirm_main_menu()
	await process_frame
	await process_frame
	assert(not paused and current_scene.get_script().resource_path == "res://scripts/main_menu.gd")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	current_scene.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("Main menu, prologue, and pause return passed")
	quit()
