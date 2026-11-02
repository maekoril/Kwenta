extends CanvasLayer

const GAME_SCENE := "res://scenes/main.tscn"
const DEBUG_META := "kwenta_debug_launch"
const OPTIONS_META := "kwenta_debug_options"
static var options_path := "user://debug_playtest_options.cfg"
var panel: PanelContainer
var day_select: OptionButton
var previous_select: OptionButton
var money_select: OptionButton
var berting_select: OptionButton
var nena_select: OptionButton
var scene_select: OptionButton
var friends_select: OptionButton
var paolo_select: OptionButton
var day4_select: OptionButton
var dodong_select: OptionButton
var debt_select: OptionButton
var help_select: OptionButton
var sukli_select: OptionButton
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
	panel.size = Vector2(790, 920)
	panel.position = Vector2(565, 80)
	panel.add_theme_stylebox_override("panel", KwentaStyle.box(KwentaStyle.PAPER, KwentaStyle.INK, 30, 24, 12, 4, 8))
	panel.visible = false
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 13)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var heading := KwentaStyle.make_label("DEBUG · QUICK PLAYTEST", 34, KwentaStyle.INK)
	column.add_child(heading)
	var description := KwentaStyle.make_label("Starts a separate test; leaves the current run. Your save is safe.", 22, KwentaStyle.INK_MUTED)
	column.add_child(description)
	day_select = _add_select(column, "DAY", ["Day 1", "Day 2", "Day 3", "Day 4", "Day 5", "Day 6", "Day 7"])
	day_select.select(2)
	previous_select = _add_select(column, "DAY 1 CHOICE", ["Stayed at store", "Played with friends"])
	money_select = _add_select(column, "DAY 2 · ₱50", ["Set aside to return", "Kept in pocket", "Berting event not seen"])
	nena_select = _add_select(column, "DAY 2 · ALING NENA", ["Event not seen", "Gave discount", "Kept full price"])
	sukli_select = _add_select(column, "DAY 2 · SUKLI", ["No change given", "All correct", "Had mistakes"])
	berting_select = _add_select(column, "DAY 3 · BERTING", ["Event not seen", "Returned the ₱50", "Denied seeing it"])
	day_select.item_selected.connect(_on_day_selected)
	scene_select = _add_select(column, "START AT", [])
	friends_select = _add_select(column, "DAY 3 · LARO", ["Sasama pagkatapos", "Hindi muna sasama", "Event not seen"])
	paolo_select = _add_select(column, "DAY 3 · PAOLO", ["Pinautang ang ₱3", "Sinagot ang ₱3", "Balik na lang", "Event not seen"])
	paolo_select.select(3)
	day4_select = _add_select(column, "DAY 4 · ULAN", ["Sumama sa laro", "Nagbantay", "Pinasilong ang mga kaibigan", "Event not seen"])
	day4_select.select(3)
	dodong_select = _add_select(column, "DAY 4 · PAYONG", ["Pinahiram si Kuya Dodong", "Event not seen"])
	dodong_select.select(1)
	debt_select = _add_select(column, "DAY 5 · UTANG", ["Lola Rosa paid ₱110", "Payment deferred (legacy)", "Event not seen"])
	debt_select.select(2)
	help_select = _add_select(column, "DAY 6 · FIESTA", ["Asked friends for help", "Worked alone"])
	column.move_child(scene_select.get_parent(), -1)
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
	_restore_options()
	for select in [previous_select, money_select, nena_select, sukli_select, berting_select, friends_select, paolo_select, day4_select, dodong_select, debt_select, help_select]:
		select.item_selected.connect(func(_index): _remember_options())
	money_select.item_selected.connect(func(_index): _on_scene_selected(scene_select.selected))
	day_select.item_selected.connect(func(_index): _remember_options())
	scene_select.item_selected.connect(func(_index): _remember_options())
	skip_tutorials.toggled.connect(func(_pressed): _remember_options())

func _remember_options() -> void:
	var values := {
		"day": day_select.selected, "moment": scene_select.get_selected_id(),
		"day1": previous_select.selected, "day2": money_select.selected, "nena": nena_select.selected, "sukli": sukli_select.selected, "berting": berting_select.selected,
		"friends": friends_select.selected, "paolo": paolo_select.selected,
		"day4": day4_select.selected, "dodong": dodong_select.selected, "debt": debt_select.selected, "help": help_select.selected, "skip_tutorials": skip_tutorials.button_pressed
	}
	get_tree().set_meta(OPTIONS_META, values)
	var config := ConfigFile.new()
	for key in values:
		config.set_value("playtest", key, values[key])
	config.save(options_path)

func _restore_options() -> void:
	var values: Dictionary = {}
	if get_tree().has_meta(OPTIONS_META):
		var remembered: Variant = get_tree().get_meta(OPTIONS_META)
		if remembered is Dictionary:
			values = remembered
	else:
		var config := ConfigFile.new()
		if config.load(options_path) == OK:
			for key in config.get_section_keys("playtest"):
				values[key] = config.get_value("playtest", key)
	if values.is_empty():
		return
	day_select.select(clampi(int(values.get("day", 2)), 0, day_select.item_count - 1))
	_on_day_selected(day_select.selected)
	var moment_index := scene_select.get_item_index(int(values.get("moment", 0)))
	scene_select.select(moment_index if moment_index >= 0 else 0)
	_on_scene_selected(scene_select.selected)
	for pair in [[previous_select, "day1"], [money_select, "day2"], [nena_select, "nena"], [sukli_select, "sukli"], [berting_select, "berting"], [friends_select, "friends"], [paolo_select, "paolo"], [day4_select, "day4"], [dodong_select, "dodong"], [debt_select, "debt"], [help_select, "help"]]:
		var select: OptionButton = pair[0]
		select.select(clampi(int(values.get(pair[1], select.selected)), 0, select.item_count - 1))
	skip_tutorials.button_pressed = bool(values.get("skip_tutorials", true))
	_on_scene_selected(scene_select.selected)

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
	if index == 0:
		scene_select.add_item("Prologue · Aling Cora", 11)
		scene_select.add_item("Day 1 · Friends at closing", 12)
	elif index == 1:
		scene_select.add_item("Day 2 · Box and supplier note", 13)
		scene_select.add_item("Day 2 · Aling Nena", 14)
		scene_select.add_item("Day 2 · Berting", 3)
	elif index == 2:
		scene_select.add_item("Day 3 · Berting", 4)
		scene_select.add_item("Day 3 · Jun-jun", 5)
		scene_select.add_item("Day 3 · Bea", 6)
		scene_select.add_item("Day 3 · Paolo", 7)
	elif index == 3:
		scene_select.add_item("Day 4 · Dodong", 10)
		scene_select.add_item("Day 4 · Jun-jun", 9)
		scene_select.add_item("Day 4 · Aling Lina", 16)
	elif index == 4:
		scene_select.add_item("Day 5 · Dodong returns umbrella", 17)
		scene_select.add_item("Day 5 · Aling Lina returns", 18)
		scene_select.add_item("Day 5 · Lola Rosa", 15)
	elif index == 5:
		scene_select.add_item("Day 6 · Paolo repays ₱3", 23)
		scene_select.add_item("Day 6 · Paolo classmate 1", 19)
		scene_select.add_item("Day 6 · Paolo classmate 2", 20)
		scene_select.add_item("Day 6 · Paolo classmate 3", 21)
		scene_select.add_item("Day 6 · Paolo returns", 22)
	scene_select.add_item("End of shift", 8)
	var previous_index := scene_select.get_item_index(previous_moment)
	scene_select.select(previous_index if previous_index >= 0 else 0)
	_on_scene_selected(scene_select.selected)
	if is_instance_valid(status):
		status.text = ""

func _on_scene_selected(_index: int) -> void:
	var moment := scene_select.get_selected_id()
	nena_select.get_parent().visible = day_select.selected >= 2 or (day_select.selected == 1 and moment in [3, 8])
	sukli_select.get_parent().visible = day_select.selected >= 2
	berting_select.get_parent().visible = money_select.selected == 1 and (day_select.selected >= 3 or (day_select.selected == 2 and moment in [5, 6, 7, 8]))
	friends_select.get_parent().visible = (day_select.selected == 2 and moment in [6, 7, 8]) or day_select.selected >= 3
	paolo_select.get_parent().visible = (day_select.selected == 2 and moment == 8) or day_select.selected >= 3
	day4_select.get_parent().visible = (day_select.selected == 3 and moment in [8, 16]) or day_select.selected >= 4
	dodong_select.get_parent().visible = (day_select.selected == 3 and moment in [8, 9]) or day_select.selected >= 4
	debt_select.get_parent().visible = day_select.selected >= 5
	help_select.get_parent().visible = (day_select.selected == 5 and moment != 0) or day_select.selected >= 6
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
	if (moment in [11, 12] and day != 1) or (moment in [3, 13, 14] and day != 2) or (moment >= 4 and moment <= 7 and day != 3) or (moment in [9, 10] and day != 4) or (moment in [15, 17, 18] and day != 5) or (moment == 16 and day != 4) or (moment in [19, 20, 21, 22, 23] and day != 6):
		status.text = "Choose the matching day for that story event."
		return
	if moment == 4 and money_select.selected == 2:
		status.text = "Choose a ₱50 outcome to preview Berting's Day 3 scene."
		return
	if moment == 16 and day4_select.selected != 1:
		status.text = "Choose Nagbantay for Aling Lina’s Day 4 visit."
		return
	if moment == 17 and dodong_select.selected != 0:
		status.text = "Choose the umbrella loan for Dodong’s return."
		return
	if moment == 18 and day4_select.selected != 0:
		status.text = "Choose Sumama sa laro for Aling Lina’s return."
		return
	if (moment in [19, 20, 21] and paolo_select.selected != 1) or (moment == 22 and paolo_select.selected != 2):
		status.text = "Choose the matching Day 3 Paolo outcome for this event."
		return
	if moment == 23 and paolo_select.selected != 0:
		status.text = "Choose Pinautang ang ₱3 to preview Paolo's repayment."
		return
	_remember_options()
	var launch_data := {"day": day, "moment": moment, "skip_tutorials": skip_tutorials.button_pressed}
	if day > 1:
		launch_data["day1"] = "stay" if previous_select.selected == 0 else "play"
	if day > 2:
		launch_data["day2"] = ["return", "keep", "none"][money_select.selected]
	if day > 2 or (day == 2 and moment in [3, 8]):
		launch_data["day2_haggle"] = ["none", "kind", "full"][nena_select.selected]
	if day > 2:
		launch_data["day2_sukli_result"] = ["none", "perfect", "mistakes"][sukli_select.selected]
	if money_select.selected == 1 and (day > 3 or (day == 3 and moment in [5, 6, 7, 8])):
		launch_data["day3_berting_resolution"] = ["none", "returned", "deny"][berting_select.selected]
	if (day == 3 and moment in [6, 7, 8]) or day > 3:
		launch_data["day3_friends"] = ["later", "stay", "none"][friends_select.selected]
	if (day == 3 and moment == 8) or day > 3:
		launch_data["day3_candy"] = ["credit", "free", "no", "none"][paolo_select.selected]
	if (day == 4 and moment in [8, 16]) or day > 4:
		launch_data["day4_rain"] = ["join", "stay", "shelter", "none"][day4_select.selected]
	if (day == 4 and moment in [8, 9]) or day > 4:
		launch_data["day4_dodong_seen"] = dodong_select.selected == 0
	if day > 5:
		launch_data["day5_debt"] = ["installments", "defer", "none"][debt_select.selected]
	if (day == 6 and moment != 0) or day > 6:
		launch_data["day6_help"] = ["ask", "alone"][help_select.selected]
	get_tree().set_meta(DEBUG_META, launch_data)
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", GAME_SCENE)
