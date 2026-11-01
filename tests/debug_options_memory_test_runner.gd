extends SceneTree
const DEBUG = preload("res://scripts/debug_tools.gd")
const PATH = "res://tests/debug_options_temp.cfg"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	DEBUG.options_path = PATH
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var debug = DEBUG.new()
	root.add_child(debug)
	await process_frame
	debug.day_select.select(3)
	debug._on_day_selected(3)
	debug.day_select.item_selected.emit(3)
	debug.scene_select.select(debug.scene_select.get_item_index(10))
	debug.scene_select.item_selected.emit(debug.scene_select.selected)
	debug.paolo_select.select(0)
	debug.paolo_select.item_selected.emit(0)
	debug.friends_select.select(1)
	debug.friends_select.item_selected.emit(1)
	debug.skip_tutorials.button_pressed = false
	debug.queue_free()
	await process_frame
	debug = DEBUG.new()
	root.add_child(debug)
	await process_frame
	assert(debug.day_select.selected == 3 and debug.scene_select.get_selected_id() == 10)
	assert(debug.paolo_select.selected == 0 and debug.friends_select.selected == 1 and not debug.skip_tutorials.button_pressed)
	debug.queue_free()
	await process_frame
	remove_meta(DEBUG.OPTIONS_META)
	debug = DEBUG.new()
	root.add_child(debug)
	await process_frame
	assert(debug.day_select.selected == 3 and debug.scene_select.get_selected_id() == 10)
	assert(debug.paolo_select.selected == 0 and debug.friends_select.selected == 1 and not debug.skip_tutorials.button_pressed)
	debug.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("Debug options restored across scene changes and from disk")
	quit()
