class_name PauseMenu extends CanvasLayer

## Pause button + pause overlay for Kwenta.
## Uses get_tree().paused, which freezes _process (so ShiftManager.advance_time stops),
## tweens, and audio players. This node runs with PROCESS_MODE_ALWAYS so it keeps working.

signal pause_toggled(is_paused: bool)
signal settings_requested
signal main_menu_requested

var _available := false
var _button: Button
var _overlay: Control

func _ready() -> void:
	layer = 100                                    # above every z_index used in main.gd
	process_mode = Node.PROCESS_MODE_ALWAYS        # must keep running while the tree is paused
	_build_button()
	_build_overlay()
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
	var is_p: bool = false
	if event is InputEventKey:
		is_p = event.pressed and not event.echo and event.keycode == KEY_P
	
	if event.is_action_pressed("ui_cancel") or is_p:
		toggle()
		get_viewport().set_input_as_handled()

func _on_settings_pressed() -> void:
	# Placeholder for future settings menu logic
	settings_requested.emit()
	print("Settings menu requested (no function yet)")

func _on_main_menu_pressed() -> void:
	# Placeholder for future main menu transition
	main_menu_requested.emit()
	print("Main menu requested (no function yet)")

# --- UI -----------------------------------------------------------------------------------

func _build_button() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Icon-only: just two bars, no background. The button itself draws nothing (flat);
	# the bars are drawn in _draw_pause_icon.
	_button = Button.new()
	_button.flat = true
	_button.focus_mode = Control.FOCUS_NONE
	_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_button.position = Vector2(24, 24)             # top-left, away from the HUD tags
	_button.size = Vector2(56, 56)                 # click area (bigger than the bars, easy to hit)
	_button.draw.connect(_draw_pause_icon)
	_button.mouse_entered.connect(_button.queue_redraw)
	_button.mouse_exited.connect(_button.queue_redraw)
	_button.pressed.connect(pause)
	root.add_child(_button)

func _draw_pause_icon() -> void:
	var color: Color = KwentaStyle.GOLD if _button.is_hovered() else KwentaStyle.PAPER
	var bar := Vector2(12, 38)
	var gap := 12.0
	var origin := (_button.size - Vector2(bar.x * 2.0 + gap, bar.y)) * 0.5

	for i in 2:
		var rect := Rect2(origin + Vector2(i * (bar.x + gap), 0.0), bar)
		_button.draw_rect(rect.grow(4.0), KwentaStyle.INK)   # dark outline so it reads on the wood
		_button.draw_rect(rect, color)

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

	var hint := KwentaStyle.make_label("Esc or P to resume", KwentaStyle.SIZE_CAPTION, KwentaStyle.INK_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
