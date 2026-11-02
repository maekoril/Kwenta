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
	print("Main menu, prologue, and pause return passed")
	quit()
