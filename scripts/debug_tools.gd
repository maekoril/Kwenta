extends CanvasLayer

const GAME_SCENE := "res://scenes/main.tscn"
const DEBUG_META := "kwenta_debug_launch"
var panel: PanelContainer
var day_select: OptionButton
var previous_select: OptionButton
var money_select: OptionButton
var scene_select: OptionButton
var friends_select: OptionButton
var skip_tutorials: CheckBox
var status: Label
var _paused_before := false
var is_test_session := false

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	var opener := Button.new()
	opener.name = "DebugOpenButton"
	opener.text = "TEST MODE [F9]" if is_test_session else "DEBUG  [F9]"
	opener.position = Vector2(30, 96)
	opener.size = Vector2(210, 56)
	opener.add_theme_font_size_override("font_size", 23)
	opener.pressed.connect(_toggle)
	add_child(opener)
	panel = PanelContainer.new()
	panel.name = "DebugPanel"
	panel.size = Vector2(790, 740)
	panel.position = Vector2(565, 150)
	panel.add_theme_stylebox_override("panel", KwentaStyle.box(KwentaStyle.PAPER, KwentaStyle.INK, 30, 24, 12, 4, 8))
	panel.visible = false
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 13)
	panel.add_child(column)
	var heading := KwentaStyle.make_label("DEBUG · QUICK PLAYTEST", 34, KwentaStyle.INK)
	column.add_child(heading)
	var description := KwentaStyle.make_label("Starts a separate test; leaves the current run. Your save is safe.", 22, KwentaStyle.INK_MUTED)
	column.add_child(description)
	day_select = _add_select(column, "DAY", ["Day 1", "Day 2", "Day 3", "Day 4", "Day 5", "Day 6", "Day 7"])
	day_select.select(2)
	previous_select = _add_select(column, "DAY 1 CHOICE", ["Stayed at store", "Played with friends"])
	money_select = _add_select(column, "DAY 2 · ₱50", ["Set aside to return", "Kept in pocket", "Berting event not seen"])
	day_select.item_selected.connect(_on_day_selected)
	scene_select = _add_select(column, "START AT", [])
	friends_select = _add_select(column, "DAY 3 · LARO", ["Sasama pagkatapos", "Hindi muna sasama", "Event not seen"])
	scene_select.item_selected.connect(_on_scene_selected)
	_on_day_selected(day_select.selected)
	skip_tutorials = CheckBox.new()
	skip_tutorials.text = "Skip tutorials in test"
	skip_tutorials.button_pressed = true
	skip_tutorials.add_theme_font_size_override("font_size", 23)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		skip_tutorials.add_theme_color_override(color_name, KwentaStyle.INK)
	column.add_child(skip_tutorials)
	status = KwentaStyle.make_label("", 20, Color("a83429"))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 18)
	column.add_child(actions)
	var launch := Button.new()
	launch.name = "DebugLaunchButton"
	launch.text = "START TEST"
	launch.custom_minimum_size = Vector2(270, 65)
	KwentaStyle.style_button(launch, KwentaStyle.GOLD, 24)
	launch.pressed.connect(_launch)
	actions.add_child(launch)
	var close := Button.new()
	close.text = "CLOSE"
	close.custom_minimum_size = Vector2(210, 65)
	KwentaStyle.style_button(close, KwentaStyle.PAPER_DARK, 24)
	close.pressed.connect(_toggle)
	actions.add_child(close)

func _add_select(parent: VBoxContainer, caption: String, values: Array[String]) -> OptionButton:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var label := KwentaStyle.make_label(caption, 22, KwentaStyle.INK)
	label.custom_minimum_size.x = 200
	row.add_child(label)
	var select := OptionButton.new()
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select.custom_minimum_size.y = 54
	select.add_theme_font_size_override("font_size", 23)
	for value in values:
		select.add_item(value)
	row.add_child(select)
	return select

func _on_day_selected(index: int) -> void:
	# Only earlier days can have choices when starting a new day.
	previous_select.get_parent().visible = index >= 1
	money_select.get_parent().visible = index >= 2
	var previous_moment := scene_select.get_selected_id() if scene_select.item_count > 0 else 0
	scene_select.clear()
	scene_select.add_item("Day intro", 0)
	scene_select.add_item("Before shift briefing", 1)
	scene_select.add_item("Start of shift", 2)
	if index == 1:
		scene_select.add_item("Day 2 · Berting", 3)
	elif index == 2:
		scene_select.add_item("Day 3 · Berting", 4)
		scene_select.add_item("Day 3 · Jun-jun", 5)
		scene_select.add_item("Day 3 · Bea", 6)
		scene_select.add_item("Day 3 · Paolo", 7)
	scene_select.add_item("End of shift", 8)
	var previous_index := scene_select.get_item_index(previous_moment)
	scene_select.select(previous_index if previous_index >= 0 else 0)
	_on_scene_selected(scene_select.selected)
	if is_instance_valid(status):
		status.text = ""

func _on_scene_selected(_index: int) -> void:
	var moment := scene_select.get_selected_id()
	friends_select.get_parent().visible = day_select.selected == 2 and moment in [6, 7, 8]
	if is_instance_valid(status):
		status.text = ""

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		_toggle()
		get_viewport().set_input_as_handled()

func _toggle() -> void:
	if panel.visible:
		panel.visible = false
		get_tree().paused = _paused_before
	else:
		_paused_before = get_tree().paused
		panel.visible = true
		get_tree().paused = true
	status.text = ""

func _launch() -> void:
	var day := day_select.selected + 1
	var moment := scene_select.get_selected_id()
	if (moment == 3 and day != 2) or (moment >= 4 and moment <= 7 and day != 3):
		status.text = "Choose the matching day for that story event."
		return
	if moment == 4 and money_select.selected == 2:
		status.text = "Choose a ₱50 outcome to preview Berting's Day 3 scene."
		return
	var launch_data := {"day": day, "moment": moment, "skip_tutorials": skip_tutorials.button_pressed}
	if day > 1:
		launch_data["day1"] = "stay" if previous_select.selected == 0 else "play"
	if day > 2:
		launch_data["day2"] = ["return", "keep", "none"][money_select.selected]
	if day == 3 and moment in [6, 7, 8]:
		launch_data["day3_friends"] = ["later", "stay", "none"][friends_select.selected]
	get_tree().set_meta(DEBUG_META, launch_data)
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", GAME_SCENE)
