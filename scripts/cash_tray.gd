class_name CashTray
extends Control

# The sukli drawer stays shallow so the customer window and shelves remain visible.

signal change_given(customer_instance_id: String, amount: int)
signal closed

const PAPER := Color("#f6e7c8")
const PAPER_DARK := Color("#e8d4a8")
const INK := Color("#2b1a10")
const WOOD := Color("#71401d")
const WOOD_DARK := Color("#3a1f12")
const WOOD_SLOT := Color("#24130d")
const GOLD := Color("#e0a33a")
const GREEN := Color("#4caa56")
const RED := Color("#c0392b")
const FONT_PATH := "res://assets/fonts/PixelifySans-Regular.ttf"
const BORDER_W := 6
const CORNER := 12

var customer_id: String = ""
var _pile: Array[int] = []
var _open := false
var _guide_enabled := false
var _change_due := 0
var _font: Font
var _panel: PanelContainer
var _drawer_position := Vector2.ZERO
var _drawer_size := Vector2.ZERO
var _unit := 1.0
var _bayad_label: Label
var _total_label: Label
var _due_label: Label
var _counter_total_label: Label
var _counter_flow: HFlowContainer
var _progress_bar: ProgressBar
var _helper_label: Label
var _msg_label: Label
var _give_button: Button
var _slide_tween: Tween
var _msg_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	_unit = StorefrontLayout.VIEWPORT_SIZE.y / 1080.0
	_drawer_size = Vector2(StorefrontLayout.VIEWPORT_SIZE.x * 0.88, StorefrontLayout.VIEWPORT_SIZE.y * 0.36)
	_drawer_position = Vector2((StorefrontLayout.VIEWPORT_SIZE.x - _drawer_size.x) * 0.5, StorefrontLayout.VIEWPORT_SIZE.y - _drawer_size.y)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = _drawer_size
	_panel.size = _drawer_size
	_panel.position = _drawer_position + Vector2(0.0, _drawer_size.y)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", _box(WOOD, WOOD_DARK, _unit * 12.0, _unit * 12.0, CORNER))
	add_child(_panel)
	_build_drawer()


func open_for(customer: CustomerState, guide_enabled: bool) -> void:
	if customer == null or customer.payment == null:
		return
	customer_id = customer.instance_id
	_guide_enabled = guide_enabled
	_change_due = customer.payment.change_due()
	_clear_pile()
	_clear_message()
	_bayad_label.text = "BAYAD  P%d" % customer.payment.tendered
	_total_label.text = "BILI  P%d" % customer.payment.total
	_due_label.text = "SUKLI\nP%d" % _change_due
	_due_label.visible = _guide_enabled
	_progress_bar.visible = _guide_enabled
	_helper_label.visible = _guide_enabled
	_refresh_pile_total()
	visible = true
	if not _open:
		_open = true
		if _slide_tween:
			_slide_tween.kill()
		_panel.position = _drawer_position + Vector2(0.0, _drawer_size.y)
		_slide_tween = create_tween()
		_slide_tween.tween_property(_panel, "position", _drawer_position, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func close() -> void:
	if not _open:
		return
	_open = false
	customer_id = ""
	if _slide_tween:
		_slide_tween.kill()
	_slide_tween = create_tween()
	_slide_tween.tween_property(_panel, "position", _drawer_position + Vector2(0.0, _drawer_size.y), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_slide_tween.tween_callback(_hide_after_close)


func is_open() -> bool:
	return _open


func show_short() -> void:
	_msg_label.text = "KULANG PO YATA..."
	_shake_drawer()


func _build_drawer() -> void:
	var canvas := Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(canvas)
	_build_listahan_note(canvas)
	_build_counter_tray(canvas)
	_build_drawer_slots(canvas)
	_build_actions(canvas)
	_build_close_button(canvas)


func _build_listahan_note(canvas: Control) -> void:
	var note := PanelContainer.new()
	note.position = Vector2(_drawer_size.x * 0.025, _drawer_size.y * 0.06)
	note.size = Vector2(_drawer_size.x * 0.245, _drawer_size.y * 0.84)
	note.rotation_degrees = -1.5
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.add_theme_stylebox_override("panel", _box(PAPER, INK, _unit * 12.0, _unit * 10.0, 4))
	canvas.add_child(note)
	var content := Control.new()
	note.add_child(content)
	var tag := _label("LISTAHAN", int(25.0 * _unit), INK)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.position = Vector2(_unit * 12.0, _unit * 10.0)
	tag.size = Vector2(note.size.x * 0.62, _unit * 38.0)
	tag.add_theme_stylebox_override("normal", _box(GOLD, INK, _unit * 6.0, _unit * 2.0, 3))
	content.add_child(tag)
	_bayad_label = _label("BAYAD  P0", int(24.0 * _unit), INK)
	_bayad_label.position = Vector2(_unit * 16.0, note.size.y * 0.30)
	_bayad_label.size = Vector2(note.size.x - _unit * 32.0, _unit * 36.0)
	content.add_child(_bayad_label)
	_total_label = _label("BILI  P0", int(24.0 * _unit), INK)
	_total_label.position = Vector2(_unit * 16.0, note.size.y * 0.48)
	_total_label.size = Vector2(note.size.x - _unit * 32.0, _unit * 36.0)
	content.add_child(_total_label)
	var rule := HSeparator.new()
	rule.position = Vector2(_unit * 16.0, note.size.y * 0.66)
	rule.size = Vector2(note.size.x - _unit * 32.0, _unit * 4.0)
	rule.add_theme_stylebox_override("separator", _dashed_rule())
	content.add_child(rule)
	_due_label = _label("", int(31.0 * _unit), Color("#7a4a14"))
	_due_label.position = Vector2(_unit * 16.0, note.size.y * 0.69)
	_due_label.size = Vector2(note.size.x - _unit * 32.0, note.size.y * 0.28)
	_due_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(_due_label)


func _build_counter_tray(canvas: Control) -> void:
	var tray := PanelContainer.new()
	tray.position = Vector2(_drawer_size.x * 0.29, _drawer_size.y * 0.05)
	tray.size = Vector2(_drawer_size.x * 0.46, _drawer_size.y * 0.50)
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.add_theme_stylebox_override("panel", _box(PAPER_DARK, INK, _unit * 10.0, _unit * 8.0, 6))
	canvas.add_child(tray)
	var content := Control.new()
	tray.add_child(content)
	var heading := _label("NASA COUNTER", int(23.0 * _unit), INK)
	heading.position = Vector2(_unit * 14.0, _unit * 8.0)
	heading.size = Vector2(tray.size.x * 0.44, _unit * 34.0)
	content.add_child(heading)
	_counter_total_label = _label("P0", int(42.0 * _unit), INK)
	_counter_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_counter_total_label.position = Vector2(tray.size.x * 0.45, _unit * 2.0)
	_counter_total_label.size = Vector2(tray.size.x * 0.50, _unit * 52.0)
	content.add_child(_counter_total_label)
	_progress_bar = ProgressBar.new()
	_progress_bar.show_percentage = false
	_progress_bar.min_value = 0.0
	_progress_bar.position = Vector2(_unit * 14.0, _unit * 55.0)
	_progress_bar.size = Vector2(tray.size.x - _unit * 28.0, _unit * 14.0)
	_progress_bar.add_theme_stylebox_override("background", _box(WOOD_SLOT, INK, 0.0, 0.0, 5))
	content.add_child(_progress_bar)
	_helper_label = _label("", int(20.0 * _unit), INK)
	_helper_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_helper_label.position = Vector2(_unit * 14.0, _unit * 70.0)
	_helper_label.size = Vector2(tray.size.x - _unit * 28.0, _unit * 28.0)
	content.add_child(_helper_label)
	_counter_flow = HFlowContainer.new()
	_counter_flow.position = Vector2(_unit * 12.0, _unit * 102.0)
	_counter_flow.size = Vector2(tray.size.x - _unit * 24.0, tray.size.y - _unit * 114.0)
	_counter_flow.add_theme_constant_override("h_separation", int(_unit * 8.0))
	_counter_flow.add_theme_constant_override("v_separation", int(_unit * 6.0))
	content.add_child(_counter_flow)


func _build_drawer_slots(canvas: Control) -> void:
	var slots := HBoxContainer.new()
	slots.position = Vector2(_drawer_size.x * 0.29, _drawer_size.y * 0.61)
	slots.size = Vector2(_drawer_size.x * 0.46, _drawer_size.y * 0.35)
	slots.add_theme_constant_override("separation", int(_unit * 8.0))
	canvas.add_child(slots)
	for value in SukliRules.DENOMINATIONS:
		var slot := _drawer_slot(value, slots.size.x / float(SukliRules.DENOMINATIONS.size()))
		slot.pressed.connect(_on_denomination_tapped.bind(value))
		slots.add_child(slot)


func _build_actions(canvas: Control) -> void:
	var actions := VBoxContainer.new()
	actions.position = Vector2(_drawer_size.x * 0.77, _drawer_size.y * 0.20)
	actions.size = Vector2(_drawer_size.x * 0.19, _drawer_size.y * 0.70)
	actions.add_theme_constant_override("separation", int(_unit * 12.0))
	canvas.add_child(actions)
	_give_button = _button("IBIGAY", int(34.0 * _unit), GOLD)
	_give_button.custom_minimum_size = Vector2(0.0, _drawer_size.y * 0.38)
	_give_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_give_button.pressed.connect(_on_give_pressed)
	actions.add_child(_give_button)
	var clear_button := _button("LINISIN", int(22.0 * _unit), WOOD)
	clear_button.custom_minimum_size = Vector2(0.0, _drawer_size.y * 0.20)
	clear_button.add_theme_stylebox_override("normal", _box(WOOD, PAPER, _unit * 6.0, _unit * 4.0, CORNER))
	clear_button.add_theme_stylebox_override("hover", _box(WOOD.lightened(0.12), PAPER, _unit * 6.0, _unit * 4.0, CORNER))
	clear_button.add_theme_stylebox_override("pressed", _box(WOOD.darkened(0.12), PAPER, _unit * 6.0, _unit * 4.0, CORNER))
	clear_button.pressed.connect(_clear_pile)
	actions.add_child(clear_button)
	_msg_label = _label("", int(18.0 * _unit), PAPER)
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg_label.custom_minimum_size = Vector2(0.0, _drawer_size.y * 0.13)
	actions.add_child(_msg_label)


func _build_close_button(canvas: Control) -> void:
	var close_button := _button("X", int(25.0 * _unit), WOOD)
	close_button.position = Vector2(_drawer_size.x * 0.905, _drawer_size.y * 0.04)
	close_button.size = Vector2(_drawer_size.x * 0.045, _drawer_size.y * 0.15)
	close_button.add_theme_stylebox_override("normal", _box(WOOD, PAPER, _unit * 4.0, _unit * 2.0, CORNER))
	close_button.pressed.connect(close)
	canvas.add_child(close_button)


func _drawer_slot(value: int, slot_width: float) -> Button:
	var button := _button("", int(16.0 * _unit), WOOD_SLOT)
	button.custom_minimum_size = Vector2(slot_width - _unit * 8.0, _drawer_size.y * 0.35)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", _box(WOOD_SLOT, INK, _unit * 4.0, _unit * 4.0, 5))
	button.add_theme_stylebox_override("hover", _box(WOOD_SLOT.lightened(0.15), GOLD, _unit * 4.0, _unit * 4.0, 5))
	var icon := MoneyIcon.new().setup(value, _drawer_size.y * 0.16, false)
	icon.position = Vector2((button.custom_minimum_size.x - icon.size.x) * 0.5, _drawer_size.y * 0.06)
	button.add_child(icon)
	var caption := _label("P%d" % value, int(17.0 * _unit), PAPER)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.position = Vector2(0.0, _drawer_size.y * 0.27)
	caption.size = Vector2(button.custom_minimum_size.x, _drawer_size.y * 0.07)
	button.add_child(caption)
	return button


func _on_denomination_tapped(value: int) -> void:
	_pile.append(value)
	_refresh_pile_total()


func _remove_one_of(value: int) -> void:
	var index := _pile.find(value)
	if index >= 0:
		_pile.remove_at(index)
	_refresh_pile_total()


func _clear_pile() -> void:
	_pile.clear()
	_refresh_pile_total()


func _refresh_pile_total() -> void:
	if not is_instance_valid(_counter_flow):
		return
	for child in _counter_flow.get_children():
		child.queue_free()
	var total := 0
	for value in _pile:
		total += value
	for value in SukliRules.DENOMINATIONS:
		var count := _pile.count(value)
		if count > 0:
			_counter_flow.add_child(_counter_piece(value, count))
	if _guide_enabled:
		_counter_total_label.text = "P%d / P%d" % [total, _change_due]
		_progress_bar.max_value = maxf(1.0, float(_change_due))
		_progress_bar.value = minf(float(total), float(_change_due))
		if total < _change_due:
			_helper_label.text = "Kulang pa P%d" % (_change_due - total)
			_progress_bar.add_theme_stylebox_override("fill", _box(WOOD, WOOD_DARK, 0.0, 0.0, 5))
		elif total == _change_due:
			_helper_label.text = "Eksakto!"
			_progress_bar.add_theme_stylebox_override("fill", _box(GREEN, INK, 0.0, 0.0, 5))
		else:
			_helper_label.text = "Sobra ng P%d" % (total - _change_due)
			_progress_bar.add_theme_stylebox_override("fill", _box(RED, INK, 0.0, 0.0, 5))
	else:
		_counter_total_label.text = "P%d" % total
	_counter_total_label.pivot_offset = _counter_total_label.size * 0.5
	_counter_total_label.scale = Vector2(1.08, 1.08)
	create_tween().tween_property(_counter_total_label, "scale", Vector2.ONE, 0.12)


func _counter_piece(value: int, count: int) -> Button:
	var piece := _button("", int(16.0 * _unit), PAPER)
	piece.custom_minimum_size = Vector2(_drawer_size.x * 0.095, _drawer_size.y * 0.17)
	piece.add_theme_stylebox_override("normal", _box(PAPER, INK, _unit * 4.0, _unit * 2.0, 4))
	var icon := MoneyIcon.new().setup(value, _drawer_size.y * 0.13, false)
	icon.position = Vector2(_unit * 6.0, _unit * 6.0)
	piece.add_child(icon)
	var badge := _label("x%d" % count, int(20.0 * _unit), INK)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.position = Vector2(piece.custom_minimum_size.x * 0.48, _unit * 8.0)
	badge.size = Vector2(piece.custom_minimum_size.x * 0.45, _unit * 30.0)
	piece.add_child(badge)
	piece.pressed.connect(_remove_one_of.bind(value))
	return piece


func _on_give_pressed() -> void:
	if customer_id.is_empty():
		return
	if _pile.is_empty():
		_msg_label.text = "PUMILI MUNA NG PERA"
		_shake_drawer()
		return
	var total := 0
	for value in _pile:
		total += value
	change_given.emit(customer_id, total)


func _shake_drawer() -> void:
	if _msg_tween:
		_msg_tween.kill()
	_msg_tween = create_tween()
	_msg_tween.tween_property(_panel, "position:x", _drawer_position.x - _unit * 10.0, 0.04)
	_msg_tween.tween_property(_panel, "position:x", _drawer_position.x + _unit * 10.0, 0.08)
	_msg_tween.tween_property(_panel, "position:x", _drawer_position.x, 0.04)
	_msg_tween.tween_interval(1.0)
	_msg_tween.tween_callback(_clear_message)


func _clear_message() -> void:
	if is_instance_valid(_msg_label):
		_msg_label.text = ""


func _hide_after_close() -> void:
	if not _open:
		visible = false
	closed.emit()


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if _font:
		label.add_theme_font_override("font", _font)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text: String, font_size: int, bg: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.add_theme_font_size_override("font_size", font_size)
	if _font:
		button.add_theme_font_override("font", _font)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(color_name, INK)
	button.add_theme_stylebox_override("normal", _box(bg, INK, _unit * 8.0, _unit * 5.0, CORNER))
	button.add_theme_stylebox_override("hover", _box(bg.lightened(0.12), INK, _unit * 8.0, _unit * 5.0, CORNER))
	button.add_theme_stylebox_override("pressed", _box(bg.darkened(0.12), INK, _unit * 8.0, _unit * 5.0, CORNER))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _box(bg: Color, edge: Color, margin_x: float, margin_y: float, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = edge
	box.set_border_width_all(BORDER_W)
	box.set_corner_radius_all(radius)
	box.anti_aliasing = false
	box.content_margin_left = margin_x
	box.content_margin_right = margin_x
	box.content_margin_top = margin_y
	box.content_margin_bottom = margin_y
	return box


func _dashed_rule() -> StyleBoxFlat:
	var rule := StyleBoxFlat.new()
	rule.bg_color = Color(INK, 0.45)
	rule.content_margin_left = _unit * 4.0
	rule.content_margin_right = _unit * 4.0
	return rule
