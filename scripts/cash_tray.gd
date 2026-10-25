class_name CashTray
extends Control

# The sukli drawer. Slides up over the shelves when the player taps a customer who is
# waiting for change. The window and customers stay visible above it, so patience bars
# keep ticking in view and the other customer can still be served from the rails/counter.
#
#   tray.open_for(customer, show_due)   -> opens for a customer in the PAYING phase
#   tray.change_given(id, amount)       -> emitted when the player taps IBIGAY
#   tray.show_short()                   -> call when the amount was too little (tray stays open)
#   tray.close()
#
# Built in code like the rest of the UI. Same paper-and-ink colors as DialogueBubble.

signal change_given(customer_instance_id: String, amount: int)
signal closed

const PAPER := Color("#f6e7c8")
const PAPER_DARK := Color("#e8d4a8")
const INK := Color("#2b1a10")
const GOLD := Color("#e0a33a")
const RED := Color("#c0392b")
const FONT_PATH := "res://assets/fonts/PixelifySans-Regular.ttf"  # same font as the bubble
const PANEL_POS := Vector2(210.0, 640.0)
const PANEL_SIZE := Vector2(1500.0, 420.0)
const BORDER_W := 6
const CORNER := 14
const DENOM_HEIGHT := 104.0
const PILE_HEIGHT := 64.0
const SLIDE_DISTANCE := 460.0

var customer_id: String = ""

var _pile: Array[int] = []
var _open := false
var _font: Font
var _panel: PanelContainer
var _bayad_icon: MoneyIcon
var _total_label: Label
var _due_label: Label
var _pile_flow: HFlowContainer
var _pile_total_label: Label
var _msg_label: Label
var _give_button: Button
var _slide_tween: Tween
var _msg_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # only the panel itself takes taps
	visible = false
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = PANEL_SIZE
	_panel.size = PANEL_SIZE
	_panel.position = PANEL_POS + Vector2(0.0, SLIDE_DISTANCE)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", _box(PAPER, INK, 24, 16, CORNER))
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_panel.add_child(column)
	column.add_child(_build_top_row())
	column.add_child(_build_pile_row())
	column.add_child(_build_bottom_row())


# ---------------------------------------------------------------- public API

func open_for(customer: CustomerState, show_due: bool) -> void:
	if customer == null or customer.payment == null:
		return
	customer_id = customer.instance_id
	_clear_pile()
	_clear_message()
	var payment: PaymentState = customer.payment
	_bayad_icon.setup(payment.tendered, 64.0, false)
	_total_label.text = "₱%d" % payment.total
	_due_label.text = ("SUKLI  ₱%d" % payment.change_due()) if show_due else ""
	_due_label.visible = show_due
	visible = true
	if not _open:
		_open = true
		if _slide_tween:
			_slide_tween.kill()
		_panel.position = PANEL_POS + Vector2(0.0, SLIDE_DISTANCE)
		_slide_tween = create_tween()
		_slide_tween.tween_property(_panel, "position", PANEL_POS, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func close() -> void:
	if not _open:
		return
	_open = false
	customer_id = ""
	if _slide_tween:
		_slide_tween.kill()
	_slide_tween = create_tween()
	_slide_tween.tween_property(_panel, "position", PANEL_POS + Vector2(0.0, SLIDE_DISTANCE), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_slide_tween.tween_callback(_hide_after_close)


func is_open() -> bool:
	return _open


# The amount was too little: the customer says so, and the pile stays so the player can add more.
func show_short() -> void:
	_msg_label.text = "KULANG PA!"
	if _msg_tween:
		_msg_tween.kill()
	_msg_tween = create_tween()
	_msg_tween.tween_property(_panel, "position:x", PANEL_POS.x - 10.0, 0.04)
	_msg_tween.tween_property(_panel, "position:x", PANEL_POS.x + 10.0, 0.08)
	_msg_tween.tween_property(_panel, "position:x", PANEL_POS.x, 0.04)
	_msg_tween.tween_interval(1.0)
	_msg_tween.tween_callback(_clear_message)


# ---------------------------------------------------------------- building the UI

func _build_top_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.custom_minimum_size.y = 76.0
	row.add_child(_label("BAYAD", 28, INK))
	_bayad_icon = MoneyIcon.new()
	_bayad_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_bayad_icon)
	row.add_child(_label("KABUUAN", 28, INK))
	_total_label = _label("₱0", 44, INK)
	row.add_child(_total_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	_due_label = _label("", 36, Color("#7a4a14"))
	row.add_child(_due_label)
	var close_button := _button("X", 36, PAPER)
	close_button.custom_minimum_size = Vector2(76.0, 76.0)
	close_button.pressed.connect(close)
	row.add_child(close_button)
	return row


func _build_pile_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 250.0
	left.add_child(_label("IBINIBIGAY", 28, INK))
	_pile_total_label = _label("₱0", 56, INK)
	left.add_child(_pile_total_label)
	_msg_label = _label("", 30, RED)
	left.add_child(_msg_label)
	row.add_child(left)
	# Where the coins and bills you've chosen pile up. Tap one to take it back out.
	var pile_panel := PanelContainer.new()
	pile_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pile_panel.custom_minimum_size = Vector2(0.0, 112.0)
	pile_panel.add_theme_stylebox_override("panel", _box(PAPER_DARK, INK, 12, 10, 4))
	_pile_flow = HFlowContainer.new()
	_pile_flow.add_theme_constant_override("h_separation", 8)
	_pile_flow.add_theme_constant_override("v_separation", 6)
	pile_panel.add_child(_pile_flow)
	row.add_child(pile_panel)
	return row


func _build_bottom_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	for value in SukliRules.DENOMINATIONS:
		var icon := MoneyIcon.new().setup(value, DENOM_HEIGHT, true)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.tapped.connect(_on_denomination_tapped.bind(value, icon))
		row.add_child(icon)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	var clear_button := _button("LINISIN", 30, PAPER)
	clear_button.custom_minimum_size = Vector2(200.0, DENOM_HEIGHT)
	clear_button.pressed.connect(_clear_pile)
	row.add_child(clear_button)
	_give_button = _button("IBIGAY", 40, GOLD)
	_give_button.custom_minimum_size = Vector2(300.0, DENOM_HEIGHT)
	_give_button.disabled = true
	_give_button.pressed.connect(_on_give_pressed)
	row.add_child(_give_button)
	return row


# ---------------------------------------------------------------- behavior

func _on_denomination_tapped(value: int, icon: MoneyIcon) -> void:
	icon.pop()
	_pile.append(value)
	var piece := MoneyIcon.new().setup(value, PILE_HEIGHT, true)
	piece.tapped.connect(_remove_piece.bind(piece))
	_pile_flow.add_child(piece)
	piece.pop()
	_refresh_pile_total()


func _remove_piece(piece: MoneyIcon) -> void:
	var index := piece.get_index()
	if index >= 0 and index < _pile.size():
		_pile.remove_at(index)
	_pile_flow.remove_child(piece)
	piece.queue_free()
	_refresh_pile_total()


func _clear_pile() -> void:
	for child in _pile_flow.get_children():
		_pile_flow.remove_child(child)
		child.queue_free()
	_pile.clear()
	_refresh_pile_total()


func _refresh_pile_total() -> void:
	var total := 0
	for value in _pile:
		total += value
	_pile_total_label.text = "₱%d" % total
	_give_button.disabled = _pile.is_empty()
	_pile_total_label.pivot_offset = _pile_total_label.size * 0.5
	_pile_total_label.scale = Vector2(1.12, 1.12)
	create_tween().tween_property(_pile_total_label, "scale", Vector2.ONE, 0.12)


func _on_give_pressed() -> void:
	if _pile.is_empty() or customer_id.is_empty():
		return
	var total := 0
	for value in _pile:
		total += value
	change_given.emit(customer_id, total)


func _clear_message() -> void:
	if is_instance_valid(_msg_label):
		_msg_label.text = ""


func _hide_after_close() -> void:
	if not _open:
		visible = false
	closed.emit()


# ---------------------------------------------------------------- small helpers

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if _font:
		label.add_theme_font_override("font", _font)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text: String, font_size: int, bg: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS   # fires on touch-down
	button.add_theme_font_size_override("font_size", font_size)
	if _font:
		button.add_theme_font_override("font", _font)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(color_name, INK)
	button.add_theme_color_override("font_disabled_color", Color(INK, 0.4))
	button.add_theme_stylebox_override("normal", _box(bg, INK, 12, 8, CORNER))
	button.add_theme_stylebox_override("hover", _box(bg.lightened(0.12), INK, 12, 8, CORNER))
	button.add_theme_stylebox_override("pressed", _box(bg.darkened(0.12), INK, 12, 8, CORNER))
	button.add_theme_stylebox_override("disabled", _box(PAPER_DARK, Color(INK, 0.4), 12, 8, CORNER))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _box(bg: Color, edge: Color, margin_x: int, margin_y: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = edge
	box.set_border_width_all(BORDER_W if radius >= CORNER else 4)
	box.set_corner_radius_all(radius)
	box.anti_aliasing = false
	box.content_margin_left = margin_x
	box.content_margin_right = margin_x
	box.content_margin_top = margin_y
	box.content_margin_bottom = margin_y
	return box
