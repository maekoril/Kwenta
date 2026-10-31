extends Control

const GAME_SCENE := "res://scenes/main.tscn"
const BACKGROUND_PATH := "res://assets/sprites/ui/main_menu/notebook_desk.png"
const HANDWRITING: Font = preload("res://assets/fonts/Caveat.ttf")
const AUDIO_SETTINGS = preload("res://scripts/audio_settings.gd")
const SETTINGS_MENU = preload("res://scripts/settings_menu.gd")
const BRUSH_STROKE = preload("res://scripts/menu_brush_stroke.gd")
const STORY_TRANSITION = preload("res://scripts/menu_story_transition.gd")
const CAMPAIGN_SAVE = preload("res://scripts/campaign_save.gd")
const DEBUG_TOOLS = preload("res://scripts/debug_tools.gd")
const DESIGN_SIZE := Vector2(1920, 1080)
var menu_canvas: Control
var settings_menu
var _selection_in_progress := false

func _ready() -> void:
	AUDIO_SETTINGS.initialize()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_menu()
	if OS.is_debug_build():
		add_child(DEBUG_TOOLS.new())
	settings_menu = SETTINGS_MENU.new()
	add_child(settings_menu)
	resized.connect(_layout_menu)
	_layout_menu()

func _build_menu() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("2d180f")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	menu_canvas = Control.new()
	menu_canvas.name = "NotebookMenuCanvas"
	menu_canvas.size = DESIGN_SIZE
	menu_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(menu_canvas)
	var background := TextureRect.new()
	background.name = "NotebookDesk"
	background.size = DESIGN_SIZE
	background.texture = load(BACKGROUND_PATH) as Texture2D
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_canvas.add_child(background)
	var has_save := not CAMPAIGN_SAVE.load_progress().is_empty()
	var play := _menu_button("StartButton", "NEW GAME", Vector2(725, 450 if has_save else 500))
	play.pressed.connect(func(): _select_menu_item(play, _request_new_game))
	if has_save:
		var resume := _menu_button("ContinueButton", "CONTINUE", Vector2(740, 550))
		resume.pressed.connect(func(): _select_menu_item(resume, _continue_game))
	var settings_button := _menu_button("SettingsButton", "SETTINGS", Vector2(755 if has_save else 748, 650 if has_save else 630))
	settings_button.pressed.connect(func(): _select_menu_item(settings_button, settings_menu.open))
	var quit_button := _menu_button("QuitButton", "QUIT", Vector2(770, 750 if has_save else 760))
	quit_button.pressed.connect(func(): _select_menu_item(quit_button, get_tree().quit))

func _menu_button(node_name: String, caption: String, at: Vector2) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = caption
	button.position = at
	button.size = Vector2(470, 118)
	button.rotation = -0.095
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", HANDWRITING)
	button.add_theme_font_size_override("font_size", 67)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, Color("30180e"))
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.add_theme_color_override("font_focus_color", Color("ad5a1a"))
	var brush := BRUSH_STROKE.new()
	brush.name = "BrushStroke"
	brush.size = button.size
	brush.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brush.show_behind_parent = true
	button.add_child(brush)
	menu_canvas.add_child(button)
	return button

func _select_menu_item(button: Button, action: Callable) -> void:
	if _selection_in_progress:
		return
	_selection_in_progress = true
	var brush = button.get_node("BrushStroke")
	brush.progress = 0.0
	var animation := create_tween()
	animation.tween_property(brush, "progress", 1.0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	animation.tween_interval(0.08)
	await animation.finished
	brush.progress = 0.0
	_selection_in_progress = false
	action.call()

func _layout_menu() -> void:
	if menu_canvas == null:
		return
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	menu_canvas.scale = Vector2.ONE * factor
	menu_canvas.position = (size - DESIGN_SIZE * factor) * 0.5

func _start_game() -> void:
	_begin_game(false)

func _continue_game() -> void:
	if CAMPAIGN_SAVE.load_progress().is_empty():
		return
	_begin_game(true)

func _request_new_game() -> void:
	if CAMPAIGN_SAVE.load_progress().is_empty():
		_start_game()
		return
	var confirm := ConfirmationDialog.new()
	confirm.title = "New Game"
	confirm.dialog_text = "Start a new game? This will replace your existing progress."
	confirm.ok_button_text = "NEW GAME"
	add_child(confirm)
	confirm.confirmed.connect(_start_game)
	confirm.close_requested.connect(confirm.queue_free)
	confirm.popup_centered()

func _begin_game(resume: bool) -> void:
	var transition := STORY_TRANSITION.new()
	transition.name = "MenuStoryTransition"
	get_tree().root.add_child(transition)
	transition.begin(resume)
