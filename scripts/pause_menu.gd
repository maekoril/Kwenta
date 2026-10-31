class_name PauseMenu extends CanvasLayer

## Pause button + pause overlay for Kwenta.
## Uses get_tree().paused, which freezes _process (so ShiftManager.advance_time stops),
## tweens, and audio players. This node runs with PROCESS_MODE_ALWAYS so it keeps working.

signal pause_toggled(is_paused: bool)
signal settings_requested
signal main_menu_requested

var _available := false
var _button: Button
var _pause_visual: TextureRect
const PAUSE_NORMAL: Texture2D = preload("res://assets/sprites/ui/hud_v5/pause_normal.png")
const PAUSE_HOVER: Texture2D = preload("res://assets/sprites/ui/hud_v5/pause_hover.png")
const SETTINGS_MENU = preload("res://scripts/settings_menu.gd")
var _overlay: Control
var _menu_confirmation: ConfirmationDialog
var _settings_menu

func _ready() -> void:
	layer = 100                                    # above every z_index used in main.gd
	process_mode = Node.PROCESS_MODE_ALWAYS        # must keep running while the tree is paused
	_build_button()
	_build_overlay()
	_settings_menu = SETTINGS_MENU.new()
	add_child(_settings_menu)
	_menu_confirmation = ConfirmationDialog.new()
	_menu_confirmation.title = "Return to main menu?"
	_menu_confirmation.dialog_text = "Your current run will be lost. Return to the main menu?"
	_menu_confirmation.ok_button_text = "MAIN MENU"
	_menu_confirmation.cancel_button_text = "CANCEL"
	_menu_confirmation.confirmed.connect(_confirm_main_menu)
	add_child(_menu_confirmation)
	set_available(false)

## Main calls this: true when a shift starts, false when it ends.
func set_available(value: bool) -> void:
	_available = value
	if not value and get_tree().paused:
		resume()
	_button.visible = value and not get_tree().paused

func toggle() -> void:
	if get_tree().paused:
		resume()
	else:
		pause()

func pause() -> void:
	if not _available:
		return
	get_tree().paused = true
	_overlay.visible = true
	_button.visible = false
	pause_toggled.emit(true)

func resume() -> void:
	get_tree().paused = false
	_overlay.visible = false
	_button.visible = _available
	pause_toggled.emit(false)

func _unhandled_input(event: InputEvent) -> void:
	# Esc (ui_cancel) or P toggles pause.
	if not _available:
		return
	if _settings_menu != null and _settings_menu.overlay.visible:
		return
	var is_p: bool = false
	if event is InputEventKey:
		is_p = event.pressed and not event.echo and event.keycode == KEY_P
	
	if event.is_action_pressed("ui_cancel") or is_p:
		toggle()
		get_viewport().set_input_as_handled()

func _on_settings_pressed() -> void:
	settings_requested.emit()
	_settings_menu.open()

func _on_main_menu_pressed() -> void:
	_menu_confirmation.popup_centered()

func _confirm_main_menu() -> void:
	resume()
	main_menu_requested.emit()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# --- UI -----------------------------------------------------------------------------------

func _build_button() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_button = Button.new()
	_button.flat = true
	_button.focus_mode = Control.FOCUS_NONE
	_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_button.position = Vector2(1820, 10)
	_button.size = Vector2(89, 74)
	_button.text = ""
	# Prevent the default Godot theme from drawing white rectangles.
	for state in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_button.mouse_entered.connect(_update_pause_visual)
	_button.mouse_exited.connect(_update_pause_visual)
	_button.button_down.connect(_update_pause_visual)
	_button.button_up.connect(_update_pause_visual)
	_button.pressed.connect(pause)
	root.add_child(_button)

	_pause_visual = TextureRect.new()
	_pause_visual.name = "PauseIllustration"
	_pause_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_visual.texture = PAUSE_NORMAL
	_pause_visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pause_visual.stretch_mode = TextureRect.STRETCH_SCALE
	_pause_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button.add_child(_pause_visual)

func place_button(pos: Vector2) -> void:
	_button.position = pos

func _update_pause_visual() -> void:
	if _pause_visual != null:
		_pause_visual.texture = PAUSE_HOVER if _button.is_hovered() else PAUSE_NORMAL

func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP   # blocks clicks on the game underneath
	_overlay.visible = false
	add_child(_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)

	var panel := PanelContainer.new()
	# Upgraded from StyleBoxFlat to KwentaStyle.box for shadows and thicker borders
	panel.add_theme_stylebox_override("panel", KwentaStyle.box(KwentaStyle.PAPER, KwentaStyle.INK, 64.0, 48.0, 16, 8, 12))
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	panel.add_child(column)

	var title := KwentaStyle.make_label("PAUSED", KwentaStyle.SIZE_H1, KwentaStyle.INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	
	# Header separator line
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0.0, 4.0)
	rule.color = KwentaStyle.INK
	column.add_child(rule)
	
	# Add spacing after the rule
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0.0, 8.0)
	column.add_child(top_spacer)

	var resume_button := Button.new()
	resume_button.text = "RESUME"
	resume_button.custom_minimum_size = Vector2(360, 80)
	KwentaStyle.style_button(resume_button, KwentaStyle.GOLD, KwentaStyle.SIZE_BUTTON)
	resume_button.pressed.connect(resume)
	column.add_child(resume_button)

	var settings_button := Button.new()
	settings_button.text = "SETTINGS"
	settings_button.custom_minimum_size = Vector2(360, 80)
	KwentaStyle.style_button(settings_button, KwentaStyle.PAPER_DARK, KwentaStyle.SIZE_BUTTON)
	settings_button.pressed.connect(_on_settings_pressed)
	column.add_child(settings_button)

	var menu_button := Button.new()
	menu_button.text = "MAIN MENU"
	menu_button.custom_minimum_size = Vector2(360, 80)
	KwentaStyle.style_button(menu_button, KwentaStyle.PAPER_DARK, KwentaStyle.SIZE_BUTTON)
	menu_button.pressed.connect(_on_main_menu_pressed)
	column.add_child(menu_button)
	
	# Spacer to push the hint text down slightly
	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0.0, 12.0)
	column.add_child(bottom_spacer)
